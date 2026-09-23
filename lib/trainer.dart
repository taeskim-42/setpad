import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'account.dart';
import 'agent_alarm.dart';
import 'gym.dart';
import 'l10n/generated/app_localizations.dart';
import 'palette.dart';
import 'trainer_settings.dart';

/// 트레이너 모드 — 에이전트가 정리한 보고서와 한 번 누르기 처리.
///
/// 모양은 서버의 lib/agent-types.ts 가 정한다. 거기에 무엇이 더해져도 여기가
/// 깨지지 않게, 모르는 항목·깨진 항목은 조용히 건너뛴다.

typedef MemberRef = ({String id, String nickname});

MemberRef _member(Object? m) =>
    (id: (m as Map)['id'] as String, nickname: m['nickname'] as String);
DateTime _at(Object? iso) => DateTime.parse(iso as String).toLocal();

/// 목록의 한 줄씩을 읽고, 못 읽은 줄은 버린다 — 한 줄 때문에 보고서 전체가
/// 안 보이는 것보다 낫다.
List<T> _each<T>(Object? list, T? Function(Map m) read) => [
  for (final m in list is List ? list : const [])
    if (m is Map) ?_tryRead(() => read(m)),
];
T? _tryRead<T>(T? Function() read) {
  try {
    return read();
  } catch (_) {
    return null;
  }
}

/// 내 에이전트. 시각은 한국 자정부터 분, 요일은 0 = 일요일(서버 값 그대로).
class AgentSettings {
  AgentSettings.fromJson(Map m)
    : enabled = m['enabled'] != false,
      runMinutes = [
        for (final v
            in m['run_minutes'] is List ? m['run_minutes'] as List : [])
          if (v is int) v,
      ]..sort(),
      weekdays = {
        for (final v in m['weekdays'] is List ? m['weekdays'] as List : [])
          if (v is int) v,
      },
      modes = {
        for (final e in (m['modes'] is Map ? m['modes'] as Map : {}).entries)
          '${e.key}': '${e.value}',
      },
      autoConfirm = m['auto_confirm'] == true;

  final bool enabled;
  final List<int> runMinutes;
  final Set<int> weekdays;
  final Map<String, String> modes;
  final bool autoConfirm;
}

/// GET /api/agent 한 번에 오는 것.
class AgentState {
  AgentState.fromJson(Map m)
    : settings = AgentSettings.fromJson(m['settings'] as Map),
      policy = Map<String, Object?>.from(m['policy'] as Map),
      owner = m['role'] == 'owner',
      runs = _each(m['runs'], AgentRun.fromJson);

  AgentSettings settings;

  /// 도장 방침. 관장만 바꾸고, 화면은 숫자 넷과 문구 하나를 그대로 보여 준다.
  Map<String, Object?> policy;
  final bool owner;
  final List<AgentRun> runs;

  /// 가장 최근에 끝난 보고서. 서버는 그 하나에만 본문을 싣는다.
  AgentRun? get latest => runs.where((r) => r.report != null).firstOrNull;
  bool get unread => latest != null && !latest!.read;
}

class AgentRun {
  AgentRun.fromJson(Map m)
    : id = m['id'] as String,
      at = _at(m['finished_at'] ?? m['started_at']),
      read = m['read_at'] != null,
      handled = {
        for (final k in m['handled'] is List ? m['handled'] as List : [])
          if (k is String) k,
      },
      report = m['report'] is Map
          ? AgentReport.fromJson(m['report'] as Map)
          : null;

  final String id;
  final DateTime at;
  final bool read;

  /// 이미 끝낸 항목의 key — 앱에서든 웹에서든. 보고서는 만들 때의 사진이라
  /// 끝낸 항목이 그대로 들어 있어서, 이것으로 가린다.
  final Set<String> handled;
  final AgentReport? report;
}

class AgentReport {
  AgentReport.fromJson(Map m)
    : supported = m['version'] == 1,
      gymName = _tryRead(() => (m['gym'] as Map)['name'] as String) ?? '',
      summary = m['summary'] is String ? m['summary'] as String : '',
      today = _each(
        m['today'],
        (t) => (
          at: _at(t['at']),
          member: t['member'] == null ? null : _member(t['member']).nickname,
          title: t['title'] as String,
        ),
      )..sort((a, b) => a.at.compareTo(b.at)),
      done = _each(
        m['done'],
        (d) => (
          member: _member(d['member']).nickname,
          detail: d['detail'] as String,
        ),
      ),
      items = _each(m['items'], AgentItem.parse);

  /// 다른 판이면 읽지 않는다. 틀리게 그리느니 업데이트해 달라고 한다.
  final bool supported;
  final String gymName;
  final String summary;
  final List<({DateTime at, String? member, String title})> today;
  final List<({String member, String detail})> done;
  final List<AgentItem> items;
}

/// 트레이너가 한 번 눌러 끝낼 일. [key] 는 같은 사실이면 같다.
sealed class AgentItem {
  const AgentItem(this.key);
  final String key;

  static AgentItem? parse(Map m) {
    final key = m['key'] as String;
    return switch (m['kind']) {
      'attendance' => AgentAttendance(key, [
        for (final b in m['bookings'] as List)
          (
            id: b['id'] as String,
            member: _member(b['member']).nickname,
            startsAt: _at(b['starts_at']),
            visitedAt: _at(b['visited_at']),
          ),
      ]),
      'request' => AgentRequest(key, _member(m['member']).nickname),
      'pt_schedule' => AgentPtSchedule(
        key,
        _member(m['member']),
        _at(m['starts_at']),
        m['basis'] as String,
      ),
      'renewal' || 'contact' => AgentFollowup(
        key,
        member: _member(m['member']),
        reason: m['reason'] as String,
        label: m['reason_label'] as String,
        episode: m['episode'] as String,
        message: m['message'] as String? ?? '',
        product: m['product'] is Map
            ? (
                id: m['product']['id'] as String,
                name: m['product']['name'] as String,
                price: m['product']['price'] as int,
              )
            : null,
        // 결제 기록에 그대로 돌려보낸다. 상품이 있으면 늘 같이 온다.
        startsOn: m['product'] is Map ? m['starts_on'] as String : null,
      ),
      'routine' => AgentRoutine(
        key,
        _member(m['member']),
        m['title'] as String,
        m['items'] as List,
        m['basis'] as String,
      ),
      // 앞으로 더해질 종류. 이 판은 모르므로 건너뛴다.
      _ => null,
    };
  }
}

class AgentAttendance extends AgentItem {
  const AgentAttendance(super.key, this.bookings);
  final List<
    ({String id, String member, DateTime startsAt, DateTime visitedAt})
  >
  bookings;
}

/// 등록 요청. 앱에서는 안내만 한다 — 확인은 웹 CRM 이 한다.
class AgentRequest extends AgentItem {
  const AgentRequest(super.key, this.member);
  final String member;
}

class AgentPtSchedule extends AgentItem {
  const AgentPtSchedule(super.key, this.member, this.startsAt, this.basis);
  final MemberRef member;
  final DateTime startsAt;
  final String basis;
}

/// 재등록(renewal)과 미방문 연락(contact). 둘 다 문구·연락함·나중에가 있고,
/// 재등록에 상품이 있으면 '결제 받음'이 붙는다.
class AgentFollowup extends AgentItem {
  const AgentFollowup(
    super.key, {
    required this.member,
    required this.reason,
    required this.label,
    required this.episode,
    required this.message,
    this.product,
    this.startsOn,
  });
  final MemberRef member;
  final String reason, label, episode, message;
  final ({String id, String name, int price})? product;
  final String? startsOn;
}

class AgentRoutine extends AgentItem {
  const AgentRoutine(
    super.key,
    this.member,
    this.title,
    this.items,
    this.basis,
  );
  final MemberRef member;
  final String title, basis;

  /// 서버가 준 그대로 되돌려 보낸다. 앱이 고쳐 쓸 까닭이 없다.
  final List items;
  List<String> get names => [
    for (final e in items)
      if (e is Map && e['name'] is String) e['name'] as String,
  ];
}

/// 서버 답: 200 이면 [body], 아니면 서버의 [message](한국어, 그대로 보여도
/// 된다)와 [status]. 셋 다 null 이면 답을 못 받은 것이다 — 요청이 안 갔을
/// 수도, 서버는 처리했는데 답만 잃었을 수도 있다.
typedef AgentReply = ({
  Map<String, Object?>? body,
  String? message,
  int? status,
});

const AgentReply _noReply = (body: null, message: null, status: null);

extension TrainerLink on GymLink {
  Future<AgentReply> _agent(
    String method,
    String path, [
    Map<String, Object?>? body,
    Duration wait = const Duration(seconds: 20),
  ]) async {
    if (!supported) return _noReply;
    return withClient((web) async {
      try {
        final request = http.Request(method, Uri.parse('$endpoint$path'))
          ..headers.addAll({...headers, 'content-type': 'application/json'});
        if (body != null) request.body = jsonEncode(body);
        final response = await web
            .send(request)
            .then(http.Response.fromStream)
            .timeout(wait);
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final map = decoded is Map ? Map<String, Object?>.from(decoded) : null;
        if (response.statusCode == 200 && map != null) {
          return (body: map, message: null, status: 200);
        }
        final message = map?['message'];
        return (
          body: null,
          message: message is String ? message : null,
          status: response.statusCode,
        );
      } catch (_) {
        return _noReply;
      }
    });
  }

  /// 설정·방침·최근 보고서. 못 받았으면 [state] 가 null 이고, 서버가 거절했으면
  /// [reply] 에 그 말이 있다(401 '로그인해 주세요.', 403 '이 도장의 관리 권한이
  /// 없습니다.').
  ///
  /// 403 이면 이제 이 도장 직원이 아니다. 그 도장 보고 알림은 여기서 지운다 —
  /// 목록의 점을 셀 때든 알림을 눌러 열 때든 이 길을 지난다.
  Future<({AgentState? state, AgentReply reply})> agentState(
    String gymId,
  ) async {
    final reply = await _agent(
      'GET',
      '/api/agent?gymId=${Uri.encodeQueryComponent(gymId)}',
      null,
      const Duration(seconds: 15),
    );
    if (reply.status == 403) {
      await AgentAlarm.sync(
        gymId: gymId,
        gymName: '',
        enabled: false,
        runMinutes: const [],
        weekdays: const [],
      );
    }
    final body = reply.body;
    return (
      state: body == null ? null : _tryRead(() => AgentState.fromJson(body)),
      reply: reply,
    );
  }

  /// 지금 정리하기. 서버가 모델로 문장을 쓰므로 다른 요청보다 오래 기다린다.
  Future<AgentReply> runAgentNow(String gymId) => _agent('POST', '/api/agent', {
    'gymId': gymId,
  }, const Duration(seconds: 60));

  /// 바꾼 것만 보낸다. 서버는 빠진 필드를 그대로 둔다.
  Future<AgentReply> saveAgentSettings(
    String gymId,
    Map<String, Object?> change,
  ) => _agent('PUT', '/api/agent/settings', {'gymId': gymId, ...change});

  Future<AgentReply> saveGymPolicy(String gymId, Map<String, Object?> change) =>
      _agent('PUT', '/api/agent/policy', {'gymId': gymId, ...change});

  /// [runId]·[itemKey] 를 주면 서버가 그 보고서에서 항목을 끝낸 것으로 적는다 —
  /// 웹 보고서에서도, 다음에 앱을 켜도 가려진다.
  Future<AgentReply> act(
    String gymId,
    Map<String, Object?> action, {
    String? runId,
    String? itemKey,
  }) => _agent('POST', '/api/agent/act', {
    'gymId': gymId,
    'action': action,
    'runId': ?runId,
    'itemKey': ?itemKey,
  });

  Future<void> markRead(String gymId, String runId) =>
      _agent('POST', '/api/agent/read', {'gymId': gymId, 'runId': runId});
}

/// 보고 알림을 설정과 맞춘다. 설정을 받거나 저장할 때마다 부른다.
Future<void> syncAgentAlarm(
  String gymId,
  String gymName,
  AgentSettings settings,
) => AgentAlarm.sync(
  gymId: gymId,
  gymName: gymName,
  enabled: settings.enabled,
  runMinutes: settings.runMinutes,
  weekdays: settings.weekdays.toList(),
);

/// 목록 입구의 점 — 내 도장 중 아직 안 연 보고서가 있는가. [checkReports] 가
/// 맞춘다. 트레이너 화면을 어디서 열었든(목록·설정·알림) 닫을 때 다시 센다.
final reportUnread = ValueNotifier<bool>(false);

/// [reportUnread] 를 서버와 맞춘다. 어차피 도장마다 설정을 받으므로 알림도
/// 여기서 맞춘다.
// ponytail: 직원 도장 여럿 중 하나에서만 빠지면 그 도장은 staff 에 없어 여기서
// 묻지 않는다. 그 알림은 한 번 울리고, 누르면 403 이라 agentState 가 지운다.
Future<void> checkReports(Account account) async {
  if (account.staff.isEmpty) {
    // 로그아웃했거나 이제 어디의 직원도 아니다.
    await AgentAlarm.clearAll();
    reportUnread.value = false;
    return;
  }
  var unread = false;
  for (final gym in account.staff) {
    final (:state, reply: _) = await account.link.agentState(gym.gymId);
    if (state == null) continue;
    await syncAgentAlarm(gym.gymId, gym.gym, state.settings);
    unread = unread || state.unread;
  }
  reportUnread.value = unread;
}

/// 트레이너 화면으로 보낸다. 직원으로 있는 도장이 둘 이상이면 먼저 묻는다.
Future<void> openTrainer(BuildContext context, Account account) async {
  final gyms = account.staff;
  if (gyms.isEmpty) return;
  var gymId = gyms.first.gymId;
  if (gyms.length > 1) {
    final picked = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(L.of(ctx).trainerWhichGym),
        actions: [
          for (final gym in gyms)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, gym.gymId),
              child: Text(gym.gym),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(L.of(ctx).trainerBack),
        ),
      ),
    );
    if (picked == null) return;
    gymId = picked;
  }
  if (!context.mounted) return;
  await pushTrainer(context, account, gymId);
}

/// 그 도장의 트레이너 화면을 열고, 닫으면 점을 다시 센다 — 방금 읽었을 것이다.
/// 알림을 눌러 열 때(main)도 이것을 쓴다.
Future<void> pushTrainer(
  BuildContext context,
  Account account,
  String gymId,
) async {
  await Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => TrainerPage(account: account, gymId: gymId),
    ),
  );
  // staff 가 비었으면 켤 때 /api/me 를 못 받은 것일 수 있다. 그때 checkReports 는
  // 모든 도장 알림을 지운다. 정말 직원이 아니게 된 것은 목록 화면이, 로그아웃은
  // signOut 이 이미 지운다.
  if (account.staff.isNotEmpty) await checkReports(account);
}

/// 거절·실패는 대화상자로 알린다. 목록 맨 위 배너는 아래 항목을 누를 때 화면
/// 밖이라, 항목이 그대로 남으면 아무 일도 없었던 것처럼 보인다.
Future<void> tellAgent(BuildContext context, String message) =>
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text(L.of(ctx).ok),
          ),
        ],
      ),
    );

/// 항목마다 한 번 만든 요청 열쇠. 답을 못 받고 다시 눌러도 같은 요청이라
/// 결제·루틴이 두 번 기록되지 않는다(같은 열쇠 = 'already').
final _requestKeys = <String, String>{};

/// 새 의존성 없이 만드는 UUID v4. 서버가 형식을 검사한다.
String uuid4() {
  final random = Random.secure();
  final b = List<int>.generate(16, (_) => random.nextInt(256));
  b[6] = b[6] & 0x0f | 0x40;
  b[8] = b[8] & 0x3f | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

class TrainerPage extends StatefulWidget {
  const TrainerPage({super.key, required this.account, required this.gymId});
  final Account account;
  final String gymId;

  @override
  State<TrainerPage> createState() => _TrainerPageState();
}

class _TrainerPageState extends State<TrainerPage> {
  AgentState? _state;
  bool _loaded = false;
  bool _busy = false;

  /// 보고서를 못 읽은 까닭. 머리의 요약 자리에 쓴다.
  String? _problem;

  /// 서버가 거절했다(401·403). 다시 눌러도 같으니 정리 버튼을 치운다.
  bool _refused = false;

  /// 잠깐 떴다 사라지는 결과(복사·처리·정리). 목록 맨 위 배너는 아래 항목을
  /// 누를 때 화면 밖이라, 화면 아래에 떠 있게 둔다.
  String? _toast;
  Timer? _toastTimer;

  /// 펼친 문구.
  final _expanded = <String>{};

  String get _gymName =>
      widget.account.staff
          .where((g) => g.gymId == widget.gymId)
          .firstOrNull
          ?.gym ??
      _state?.latest?.report?.gymName ??
      '';

  @override
  void initState() {
    super.initState();
    // 알림은 트레이너에게만 필요하다. 그래서 켤 때가 아니라 여기서 묻는다.
    unawaited(AgentAlarm.ensurePermission());
    _load();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _say(String message) {
    _toastTimer?.cancel();
    setState(() => _toast = message);
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _load() async {
    final (:state, :reply) = await widget.account.link.agentState(widget.gymId);
    if (!mounted) return;
    final refused = reply.status == 401 || reply.status == 403;
    setState(() {
      _loaded = true;
      _refused = refused;
      // 거절이면 들고 있던 보고서도 더는 볼 수 없는 것이다.
      _state = refused ? null : state ?? _state;
      // 서버가 답했으면 그 말이 '서버에 닿지 못했어요'보다 맞다.
      _problem = _state == null
          ? reply.message ?? L.of(context).trainerFailed
          : null;
    });
    if (state == null) return;
    unawaited(syncAgentAlarm(widget.gymId, _gymName, state.settings));
    final latest = state.latest;
    if (latest != null && !latest.read) {
      unawaited(widget.account.link.markRead(widget.gymId, latest.id));
    }
  }

  Future<void> _runNow() async {
    setState(() => _busy = true);
    final reply = await widget.account.link.runAgentNow(widget.gymId);
    // 답을 못 받았어도 정리는 끝났을 수 있다. 있는 것을 다시 읽는다.
    await _load();
    if (!mounted) return;
    setState(() => _busy = false);
    if (reply.body == null) _say(reply.message ?? L.of(context).trainerFailed);
  }

  Future<void> _act(AgentItem item, Map<String, Object?> action) async {
    final run = _state?.latest;
    if (run == null) return;
    setState(() => _busy = true);
    final reply = await widget.account.link.act(
      widget.gymId,
      action,
      runId: run.id,
      itemKey: item.key,
    );
    // 답만 잃었으면 서버는 처리했을 수 있다. 다시 읽으면 서버가 적은 handled 로
    // 가려진다 — 그대로 두면 결제 수단을 바꿔 다시 누르다 거절되고, 웹에서 한 번
    // 더 등록하게 된다.
    if (reply.body == null && reply.message == null) await _load();
    if (!mounted) return;
    final detail = reply.body?['detail'];
    setState(() {
      _busy = false;
      if (reply.body != null) {
        // 서버도 적어 두지만, 다시 받기 전까지는 여기서 가린다. 도는 사이 당겨서
        // 새로 받았으면 보이는 것은 새 객체다 — 같은 보고서면 그쪽에 적는다.
        final shown = _state?.latest;
        if (shown?.id == run.id) shown!.handled.add(item.key);
      }
    });
    if (detail is String && detail.isNotEmpty) _say(detail);
    final done = _state?.latest?.handled.contains(item.key) ?? false;
    if (reply.body == null && !done) {
      await tellAgent(
        context,
        reply.message ?? L.of(context).trainerActUnknown,
      );
    }
  }

  String _key(AgentItem item) =>
      _requestKeys.putIfAbsent('${_state?.latest?.id}/${item.key}', uuid4);

  Future<void> _finishAttendance(AgentAttendance item) async {
    final l = L.of(context);
    final go = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            l.trainerFinishAsk(item.bookings.length),
            style: const TextStyle(fontSize: 15),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.trainerBack),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.trainerFinish),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    await _act(item, {
      'kind': 'attendance',
      'bookingIds': [for (final b in item.bookings) b.id],
    });
  }

  /// 결제 받음. 무엇을 얼마에 언제부터인지 보여 주고 결제 수단을 고르면 기록한다.
  Future<void> _sell(AgentFollowup item) async {
    final l = L.of(context);
    final product = item.product!;
    final method = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l.trainerPaid),
        message: Text(
          '${item.member.nickname} · ${product.name} · '
          '${l.trainerPrice(product.price)} · '
          '${l.trainerStarts(_day(l, DateTime.parse(item.startsOn!)))}\n'
          // 문구에는 관장의 재등록 혜택이 들어가지만 여기는 정가만 기록한다.
          '${l.trainerPaidListPrice}\n${l.trainerPayHow}',
        ),
        actions: [
          for (final (value, label) in [
            ('card', l.payCard),
            ('cash', l.payCash),
            ('transfer', l.payTransfer),
            ('other', l.payOther),
          ])
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, value),
              child: Text(label),
            ),
        ],
        // '취소'는 결제를 취소하는 것처럼 읽힌다.
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.trainerBack),
        ),
      ),
    );
    if (method == null || !mounted) return;
    await _act(item, {
      'kind': 'renewal_sell',
      'memberId': item.member.id,
      'productId': product.id,
      'startsOn': item.startsOn,
      'paid': product.price,
      'method': method,
      'saleKey': _key(item),
    });
  }

  Map<String, Object?> _followup(AgentFollowup item, String action) => {
    'kind': 'followup',
    'memberId': item.member.id,
    'reason': item.reason,
    'episode': item.episode,
    'action': action,
  };

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _say(L.of(context).trainerCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final state = _state;
    final run = state?.latest;
    final report = run?.report;
    final items = [
      for (final item in report?.items ?? const <AgentItem>[])
        if (!run!.handled.contains(item.key)) item,
    ];
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l.trainerReport),
        trailing: state == null
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => TrainerSettingsPage(
                      account: widget.account,
                      gymId: widget.gymId,
                      gymName: _gymName,
                      state: state,
                    ),
                  ),
                ),
                child: Icon(
                  CupertinoIcons.gear,
                  size: 21,
                  semanticLabel: l.agentSettings,
                ),
              ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              // 당겨서 새로고침은 튕기는 스크롤에서만 된다. 안드로이드도 같게.
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverRefreshControl(onRefresh: _load),
                SliverList.list(
                  children: [
                    _header(l, run),
                    if (report != null && report.supported) ...[
                      if (report.done.isNotEmpty) ...[
                        _section(l.trainerDone),
                        for (final d in report.done)
                          _line('${d.member} · ${d.detail}'),
                      ],
                      if (report.today.isNotEmpty) ...[
                        _section(l.trainerToday),
                        for (final t in report.today)
                          _line(
                            [_time(l, t.at), ?t.member, t.title].join(' · '),
                          ),
                      ],
                      _section(l.trainerTodo),
                      if (items.isEmpty)
                        _line(l.trainerAllClear)
                      else
                        for (final item in items) _item(l, item),
                    ],
                    const SizedBox(height: 72),
                  ],
                ),
              ],
            ),
            if (_toast != null)
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: _toastView(_toast!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(L l, AgentRun? run) {
    final report = run?.report;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _gymName,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          if (run != null)
            Text(
              l.trainerRanAt(_when(l, run.at)),
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          const SizedBox(height: 6),
          if (!_loaded)
            const CupertinoActivityIndicator()
          else if (report != null)
            Text(
              report.supported ? report.summary : l.trainerOutdated,
              style: const TextStyle(fontSize: 15, height: 1.4),
            )
          else if (_state != null)
            Text(l.trainerNoReport, style: const TextStyle(fontSize: 15))
          else if (_problem != null)
            Text(_problem!, style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 10),
          // 지금 정리하기는 1분까지 걸린다. 눌린 줄 모르면 또 누른다.
          if (!_refused)
            Row(
              children: [
                _pill(l.trainerRunNow, _runNow),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: CupertinoActivityIndicator(),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _item(L l, AgentItem item) => switch (item) {
    AgentAttendance a => _block(
      [
        _title(l.trainerAttendance),
        for (final b in a.bookings)
          _sub(
            '${b.member} · ${_when(l, b.startsAt)} · '
            '${l.trainerVisited(_time(l, b.visitedAt))}',
          ),
      ],
      [
        _pill(
          l.trainerFinishAll(a.bookings.length),
          () => _finishAttendance(a),
        ),
      ],
    ),
    AgentRequest(:final member) => _block([
      _title(member),
      _sub(l.trainerJoinRequest),
    ], const []),
    AgentPtSchedule(:final member, :final startsAt, :final basis) => _block(
      [_title(member.nickname), _sub('${_when(l, startsAt)} · $basis')],
      [
        _pill(
          l.trainerBook,
          () => _act(item, {
            'kind': 'pt_schedule',
            'memberId': member.id,
            'startsAt': startsAt.toUtc().toIso8601String(),
          }),
        ),
      ],
    ),
    AgentFollowup f => _followupBlock(l, f),
    AgentRoutine r => _block(
      [
        _title('${r.member.nickname} · ${r.title}'),
        _sub(r.names.join(' · ')),
        _sub(r.basis),
      ],
      [
        _pill(
          l.trainerSend,
          () => _act(r, {
            'kind': 'routine',
            'memberId': r.member.id,
            'title': r.title,
            'items': r.items,
            'requestKey': _key(r),
          }),
        ),
      ],
    ),
  };

  Widget _followupBlock(L l, AgentFollowup item) {
    final AgentFollowup(:member, :label, :message, :product) = item;
    return _block(
      [
        _title('${member.nickname} · $label'),
        if (product != null)
          _sub(
            '${product.name} · ${l.trainerPrice(product.price)} · '
            '${l.trainerStarts(_day(l, DateTime.parse(item.startsOn!)))}',
          ),
        if (message.isNotEmpty)
          // 문구는 길다. 두 줄만 보이고 누르면 펼친다.
          GestureDetector(
            onTap: () => setState(() {
              if (!_expanded.remove(item.key)) _expanded.add(item.key);
            }),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                message,
                maxLines: _expanded.contains(item.key) ? null : 2,
                overflow: _expanded.contains(item.key)
                    ? null
                    : TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ),
      ],
      [
        if (message.isNotEmpty) _pill(l.trainerCopy, () => _copy(message)),
        if (product != null) _pill(l.trainerPaid, () => _sell(item)),
        _pill(l.trainerContacted, () => _act(item, _followup(item, 'done'))),
        _pill(l.trainerLater, () => _act(item, _followup(item, 'snooze'))),
      ],
    );
  }

  /// 웹 CRM 과 같은 꼴: 한국어는 '9/28(월)', '9/28(월) 07:00'. 다른 말은 그
  /// 말의 날짜 꼴을 따른다(9/28 을 28 일 9 월로 읽는 곳이 있다).
  String _day(L l, DateTime at) => l.localeName == 'ko'
      ? DateFormat('M/d(E)', 'ko').format(at)
      : DateFormat.MEd(l.localeName).format(at);
  String _when(L l, DateTime at) => '${_day(l, at)} ${_time(l, at)}';
  String _time(L l, DateTime at) => DateFormat('HH:mm').format(at);

  Widget _block(List<Widget> lines, List<Widget> actions) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...lines,
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(spacing: 8, runSpacing: 8, children: actions),
          ),
      ],
    ),
  );

  Widget _title(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: CupertinoColors.label.resolveFrom(context),
    ),
  );

  Widget _sub(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    ),
  );

  Widget _line(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 3, 20, 3),
    child: Text(text, style: const TextStyle(fontSize: 14)),
  );

  /// 테두리 알약 버튼 — 예약 화면의 시각 버튼과 같은 모양. 처리 중엔 막고
  /// 흐리게 한다(색을 직접 줘서 CupertinoButton 이 알아서 흐리게 하지 못한다).
  /// 보이는 알약은 34pt 지만 누르는 곳은 44pt — 결제 받음과 연락함이 붙어 있다.
  Widget _pill(String label, VoidCallback onTap) {
    final color = (_busy ? CupertinoColors.tertiaryLabel : seal).resolveFrom(
      context,
    );
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: _busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  /// 화면 아래 떠 있는 결과. 밑의 버튼을 가리더라도 누르는 것은 막지 않는다.
  Widget _toastView(String message) => IgnorePointer(
    child: Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.label.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            color: CupertinoColors.systemBackground.resolveFrom(context),
          ),
        ),
      ),
    ),
  );

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    ),
  );
}
