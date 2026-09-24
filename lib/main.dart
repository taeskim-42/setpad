import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

import 'editor.dart';
import 'l10n/generated/app_localizations.dart';
import 'health.dart';
import 'health_page.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

import 'account.dart';
import 'agent_alarm.dart';
import 'daily.dart';
import 'gym.dart';
import 'gym_sheets.dart';
import 'handoff.dart';
import 'meal.dart';
import 'meal_amount_sheet.dart';
import 'anatomy_page.dart' show registerArtworkLicense;
import 'notes.dart';
import 'palette.dart';
import 'partner.dart';
import 'nearby.dart';
import 'notes_list.dart';
import 'record_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'set_grid.dart';
import 'settings.dart';
import 'share.dart';
import 'trainer.dart';

void main() {
  registerArtworkLicense();
  runApp(const SetpadApp());
  // 트레이너 보고 알림. 알림을 눌러 켜졌으면 그 탭을 여기서 받아 두었다가
  // AgentAlarm.taps 로 넘긴다. 테스트는 main 을 부르지 않으니 채널도 안 깬다.
  unawaited(AgentAlarm.init());
}

/// 보고 알림 탭. AgentAlarm.taps 는 한 번만 들을 수 있는 스트림이라 여기서 한 번
/// 붙이고 나눠 듣는다 — 홈이 다시 만들어져도(테스트가 앱을 여러 번 띄운다)
/// 두 번 붙다가 깨지지 않는다. 처음 붙을 때 쌓여 있던 콜드 스타트 탭이 온다.
final _reportTaps = AgentAlarm.taps.asBroadcastStream();

class SetpadApp extends StatelessWidget {
  /// [store] 는 테스트가 임시 폴더를 물릴 자리다. 비워 두면 앱 문서 디렉터리를
  /// 쓰는 것을 스스로 만든다 — 그건 플랫폼 채널이라 테스트에서는 못 쓴다.
  const SetpadApp({super.key, this.store, this.tags});

  final NotesStore? store;

  /// 스티커가 가리킨 주소가 오는 자리. **테스트는 비워 둔다** — 그 자리에는
  /// 읽을 태그가 없고, 네이티브 채널을 깨우면 없는 플러그인을 부른다.
  final Stream<Uri>? tags;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Setpad',
      debugShowCheckedModeBanner: false,
      // 지원 언어를 하나 더하거나 뺄 때 여기를 같이 고칠 일이 없도록
      // 생성된 목록을 그대로 쓴다. arb 파일이 곧 지원 언어 목록이다.
      supportedLocales: L.supportedLocales,
      localizationsDelegates: L.localizationsDelegates,
      // 기기는 zh-TW / zh-HK 처럼 **문자 체계 없이** 보낸다. 그대로 두면
      // 번체에 못 붙고 기본 zh(간체)로 떨어져 대만 사용자가 간체를 본다.
      // 나라 코드를 보고 문자 체계를 채운 뒤 평소 규칙에 넘긴다.
      localeListResolutionCallback: (locales, supported) =>
          basicLocaleListResolution([
            for (final l in locales ?? const <Locale>[])
              if (l.languageCode == 'zh' && l.scriptCode == null)
                Locale.fromSubtags(
                  languageCode: 'zh',
                  scriptCode: const ['TW', 'HK', 'MO'].contains(l.countryCode)
                      ? 'Hant'
                      : 'Hans',
                  countryCode: l.countryCode,
                )
              else
                l,
          ], supported),
      // 기본 서체를 monospace 로 못 박지 않는다. 숫자가 줄 서는 자리에만
      // 붙이면 되고, 화면 전체를 고정폭으로 두면 한글이 성기게 벌어져 iOS
      // 앱처럼 안 보인다. 나머지는 시스템 서체(SF Pro / Apple SD Gothic Neo)를
      // 그대로 쓴다.
      theme: const CupertinoThemeData(
        primaryColor: seal,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      home: _Home(store: store, tags: tags),
      // 헬스 커넥트가 "권한을 왜 쓰는가" 를 물으면 Android 가 이 이름으로 연다
      // (MainActivity.getInitialRoute, onNewIntent).
      onGenerateRoute: (settings) => settings.name == HealthDataPage.route
          ? CupertinoPageRoute<void>(
              settings: settings,
              builder: (_) => const HealthDataPage(),
            )
          : null,
    );
  }
}

/// 앱이 켜지는 자리.
///
/// **목록이 아니라 패드로 연다.** 헬스장에서 앱을 여는 이유는 세트를 하나
/// 적으려는 것이지 지난 기록을 넘겨보려는 것이 아니다. 그래서 오늘 것이 있으면
/// 그것을, 없으면 새 기록을 곧바로 펴고, 목록은 뒤로가기 한 번 뒤에 둔다.
class _Home extends StatefulWidget {
  const _Home({this.store, this.tags});
  final Stream<Uri>? tags;

  final NotesStore? store;

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> with WidgetsBindingObserver {
  late final NotesStore _store = widget.store ?? NotesStore();
  final _health = HealthLink();

  /// 서버에 묻는 쪽. 로그인했으면 계정으로, 아니면 이 기기로 묻는다.
  RecordAi get _ai => _account.ai;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _watchTags();
    _alarmTaps = _reportTaps.listen(_openReport);
    // 심박이 올 때마다 남긴다. HealthKit 이 실제로 얼마나 자주 깨워 주는지를
    // 재는 것이 지금 목적이다 — 그 값에 따라 휴식 타이머가 성립하는지가
    // 갈린다. 문서로 확인하지 못한 빈도 제한을 실측으로 대신한다.
    _health.onBeat(({required bpm, required lag, sinceLastWake}) {
      debugPrint(
        '[심박] ${bpm}bpm · 지연 ${lag.inSeconds}초'
        '${sinceLastWake == null ? ' · 첫 신호' : ' · 직전 신호와 ${sinceLastWake.inSeconds}초 간격'}',
      );
    });
    _boot();
  }

  Future<void> _boot() async {
    await _store.load();
    if (!mounted) return;
    // 세트를 끝낼 때마다 저장소가 알린다. 오늘 문턱을 넘은 첫 순간에 원판을 받는다.
    _store.addListener(_claimDaily);
    setState(() => _ready = true);
    // 첫 프레임이 그려진 뒤에 밀어 넣어야 목록이 뒤에 남는다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _open(_todayOrNew()));
  }

  /// 오늘 고친 메모가 있으면 이어 쓴다. 하루에 앱을 여러 번 여는 흐름에서
  /// 열 때마다 새 기록이 쌓이면 목록이 못 쓰게 된다.
  Note _todayOrNew() {
    final now = DateTime.now();
    for (final n in _store.notes) {
      final d = n.updatedAt;
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        return n;
      }
    }
    return _store.create();
  }

  Future<void> _open(Note note) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => EditorPage(
          store: _store,
          note: note,
          account: _account,
          // 빠지면 기본값(기기 id 없음)이 쓰여, 열량 없는 끼니의 추정이 조용히 멈췄다.
          ai: _ai,
          onTakeHandoff: _takeHandoff,
        ),
      ),
    );
    // 아무것도 안 치고 나온 새 기록은 남기지 않는다.
    _store.discardIfEmpty(note);
    unawaited(_syncHealth(note));
  }

  /// 편집을 마치고 나올 때 건강 앱과 맞춘다.
  ///
  /// 기다리지 않는다 — 권한 창이 뜨든 안 뜨든 목록은 이미 보여야 한다.
  /// 실패해도 조용하다. 연동은 덤이지 기록의 전제가 아니다.
  Future<void> _syncHealth(Note note) async {
    final sets = note.blocks.expand((b) => b.sets).where((s) => s.mine);
    if (sets.isEmpty) return;
    // 시작과 끝. 세트마다 시각을 남기지 않으므로 노트가 만들어진 때와 마지막에
    // 고친 때로 잡는다. 실제로 그 사이에 운동을 한 것이 맞다.
    // 다른 문서가 이미 잰 구간은 빼고, 나중에 고친 시각까지 늘어나지 않게 자른다
    // — 같은 활동 에너지를 두 번 더하거나 하루치를 운동 칼로리라 부르지 않으려고.
    final start = sessionStart(note, _store.notes);
    final end = sessionEnd(note);
    if (!end.isAfter(start)) return;

    if (!await _health.authorize()) return;
    // 관찰은 한 번만 걸면 계속 산다.
    unawaited(_health.watchHeartRate());

    // 심박이 얼마나 늦게 도착하는지 남긴다. 심박으로 휴식을 끊어 주는 기능을
    // 만들지 말지가 이 값에 달려 있다 — 몇 초면 되고 몇 분이면 못 한다.
    final hr = await _health.latestHeartRate();
    debugPrint(
      hr == null
          ? '[심박] 최근 30분에 잰 것이 없다'
          : '[심박] ${hr.bpm}bpm · 잰 시각 ${hr.at} · 지연 ${hr.lag.inSeconds}초',
    );

    final kcal = await _health.activeEnergy(start, end);
    await _health.writeWorkout(
      start: start,
      end: end,
      title: note.title,
      energyBurned: kcal,
    );
    if (kcal != null && mounted) {
      note.calories = kcal;
      _store.touch();
    }
  }

  /// 로그인과 결제. **없어도 앱은 그대로 돈다** — 켜지 않은 사람은 그냥 쓴다.
  /// 기기 id 는 store 가 처음 켤 때 만들므로 부를 때 읽는다.
  late final _account =
      Account(deviceId: () => _store.deviceId, aiEnabled: () => _store.aiOn)
        // 시작이 실패해도 알림 탭이 영영 기다리지 않게 늘 끝낸다.
        ..start()
            .whenComplete(_accountStarted.complete)
            .then((_) => _sendPendingWorkouts());

  void _claimDaily() => unawaited(_account.claimDaily(_store));

  /// 남겨 둔 로그인이 되살아났는가. 알림을 눌러 켜진 앱은 이것을 기다려야
  /// 보고서를 읽을 토큰이 있다.
  final _accountStarted = Completer<void>();
  StreamSubscription<String>? _alarmTaps;

  /// 보고 알림을 눌렀다. 그 도장의 트레이너 화면을 열고, 닫으면 목록의 점을
  /// 다시 센다. 이제 그 도장 직원이 아니면 화면이 서버의 말(403)을 보여 주고
  /// 그 도장 알림을 지운다.
  Future<void> _openReport(String gymId) async {
    await _accountStarted.future;
    if (!mounted || !_account.signedIn) return;
    await pushTrainer(context, _account, gymId);
  }

  /// 스티커를 댔을 때. 앱이 닫혀 있었어도 열리면서 여기로 온다.
  StreamSubscription<Uri>? _tags;

  /// 태그가 가리킨 체육관의 오늘 루틴을 받아 바로 연다.
  ///
  /// **스티커에 댄 사람은 지금 그 헬스장에 서 있다.** 목록으로 보내 한 번 더
  /// 누르게 하지 않는다 — 손에 폰을 들고 기구 앞에 있는 참이다.
  /// 지금 처리 중인 태그. **한 번 댄 것을 두 번 처리하지 않는다** —
  /// app_links 는 앱을 연 주소를 스트림으로도 주고 getInitialLink 로도 줘서
  /// 같은 태그가 두 번 들어온다. 안내창이 두 개 겹쳐 뜨던 이유다.
  String? _handling;

  String? _lastHandoff;

  /// 남이 대신 적어 건네준 기록을 받는다. **받아야 내 것이 된다** — 새 운동 문서로
  /// 들어오고, 그 운동을 한 시각에 놓인다. 같은 링크를 다시 열면 같은 문서가 열리고,
  /// 보낸 사람이 그사이 더 적었으면 그 내용으로 맞춘다. 다만 내가 이미 고친 문서는
  /// 덮지 않는다 — 그때는 새 문서로 따로 들어온다.
  // ponytail: 받는 쪽도 로그인이 필요하다. 서버는 기기 토큰으로도 읽게 해 두었으니,
  // 계정 없는 사람이 받아야 하면 RecordAi 의 기기 토큰을 여기에 빌려주면 된다.
  Future<void> _takeHandoff(String token) async {
    final l = L.of(context);
    if (!_account.signedIn) {
      final go = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          content: Text(l.handoffSignIn, style: const TextStyle(fontSize: 15)),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.partnerSignInAction),
            ),
          ],
        ),
      );
      if (go != true) return;
      await _account.signIn();
      if (!mounted || !_account.signedIn) return;
    }
    final reply = await _account.link.readHandoff(token);
    if (!mounted) return;
    final had = _store.notes.where((n) => n.handoffToken == token).toList();
    final h = reply.handoff;
    if (h == null) {
      // 못 받았어도 전에 받아 둔 것이 있으면 그것을 연다.
      if (had.isNotEmpty) return _open(had.first);
      return _tellTag(l.handoffFailed);
    }
    final note = placeHandoff(_store, token, h);
    _store.touch();
    await _open(note);
  }

  Future<void> _openTag(Uri uri) async {
    final handoff = handoffTokenFromLink(uri);
    if (handoff != null) {
      // 같은 링크가 두 번 전달되는 일이 있다(처음 링크 + 스트림).
      if (handoff == _lastHandoff) return;
      _lastHandoff = handoff;
      await _takeHandoff(handoff);
      _lastHandoff = null;
      return;
    }
    final gymId = gymFromTag(uri);
    if (gymId == null) return;
    if (_handling == gymId) return;
    _handling = gymId;
    try {
      await _handleTag(uri, gymId);
    } finally {
      _handling = null;
    }
  }

  Future<void> _handleTag(Uri uri, String gymId) async {
    // **여기서 로그인까지 끝낸다.** 안내만 하고 웹으로 보내면 거기서 또
    // 로그인 수단을 고르게 되고, 웹의 카카오와 앱의 Apple 은 서로 다른
    // 사람이 된다. 기기가 쓰는 수단 하나로 여기서 들어오고 이어서 진행한다.
    if (!_account.signedIn) {
      final l = L.of(context);
      final go = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l.tagSignInNeeded,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.tagSignIn),
            ),
          ],
        ),
      );
      if (go != true) return;
      final ok = await _account.signIn();
      if (!mounted) return;
      if (!ok) {
        // 사람이 스스로 닫은 것은 말할 것이 없다. 서버가 막은 것만 말한다.
        if (_account.signInRefused) await _tellTag(L.of(context).signInFailed);
        return;
      }
      // 로그인했으니 댄 것을 그대로 이어서 처리한다. 다시 대라고 하지 않는다.
      await _handleTag(uri, gymId);
      return;
    }

    final routines = await _account.link.routines();
    if (!mounted) return;
    final mine = routines.where((r) => r.gymId == gymId).firstOrNull;
    if (mine == null) {
      // 그 체육관에 다니지 않는 것과, 다니는데 오늘 받은 것이 없는 것은
      // 해야 할 일이 다르다. 둘 다 **안내가 아니라 행동으로 끝난다** — 말만
      // 하고 멈추면 회원이 될 길도, 출석이 남을 길도 앱 안에 없다.
      final member = _account.gyms.any((g) => g.id == gymId);
      await (member ? _attendOnly(gymId) : _askJoin(gymId));
      return;
    }
    _open(
      _store.create(blocks: mine.blocks, gymId: mine.gymId, routineId: mine.id),
    );
  }

  /// 회원이 아닌 사람. **댄 것이 곧 신청이다** — 한 번 더 누르게 하지 않는다.
  /// 트레이너 화면에 바로 뜨고, 확인하면 회원이 된다.
  Future<void> _askJoin(String gymId) async {
    final state = await _account.link.requestJoin(gymId);
    if (!mounted) return;
    if (state == JoinState.member) {
      // 방금 트레이너가 확인해 준 참이다. 안내 대신 하러 온 일을 시작한다.
      await _account.refreshGyms();
      if (mounted) await _attendOnly(gymId);
      return;
    }
    await _tellTag(switch (state) {
      JoinState.requested => L.of(context).tagJoinSent,
      JoinState.waiting => L.of(context).tagJoinWaiting,
      _ => L.of(context).tagJoinFailed,
    });
  }

  /// 루틴이 없는 날. **온 것은 온 것이다** — 빈 기록 하나가 곧 출석이고,
  /// 이것이 없으면 트레이너의 오늘 화면에 이 사람이 영영 안 뜬다.
  ///
  /// 같은 날 두 번 대도 한 번이다. 웹이 세 시간 안의 기록을 다시 여는 것과
  /// 같은 규칙을 쓴다 — 폰이 잠겼다 돌아온 것을 두 번째 방문으로 세지 않는다.
  Future<void> _attendOnly(String gymId) async {
    final since = DateTime.now().subtract(const Duration(hours: 3));
    final open = _store.notes
        .where((n) => n.gymId == gymId && n.createdAt.isAfter(since))
        .firstOrNull;
    final note = open ?? _store.create(gymId: gymId);
    if (open == null) unawaited(_sendPendingWorkouts());
    if (mounted) _open(note);
  }

  Future<void> _tellTag(String message) => showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message, style: const TextStyle(fontSize: 15)),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(L.of(ctx).ok),
        ),
      ],
    ),
  );

  /// 체육관에서 시작한 기록 중 아직 못 보낸 것을 보낸다.
  /// 헬스장은 신호가 나빠 한 번에 못 갈 때가 있다.
  /// 밀린 끼니 변경(확정·수정·삭제)도 같은 기회에 같이 간다.
  Future<void> _sendPendingWorkouts() async {
    await sendPending(_account.link, _store.notes, onSent: _store.touch);
    await syncMeals(_account.link, _store.notes, onSynced: _store.touch);
  }

  /// 앱이 닫혀 있다 열린 경우와, 떠 있는데 댄 경우를 한 줄기로 받는다.
  void _watchTags() {
    final given = widget.tags;
    if (given != null) {
      _tags = given.listen(_openTag);
      return;
    }
    // 웹에는 스티커를 읽을 것이 없다. 채널을 깨우지 않는다.
    if (kIsWeb) return;
    final links = AppLinks();
    _tags = links.uriLinkStream.listen(_openTag, onError: (Object _) {});
    unawaited(
      links
          .getInitialLink()
          .then((uri) {
            if (uri != null) _openTag(uri);
          })
          .catchError((Object _) {}),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 내려갈 때는 디바운스를 기다리지 않는다.
    if (state != AppLifecycleState.resumed) {
      _store.flush();
    } else {
      // 돌아왔다. 그동안 신호가 잡혔을 수 있다.
      unawaited(_sendPendingWorkouts());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tags?.cancel();
    _store.removeListener(_claimDaily);
    _alarmTaps?.cancel();
    _account.dispose();
    _store.flush();
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const CupertinoPageScaffold(child: SizedBox.shrink());
    }
    return NotesListPage(
      store: _store,
      onOpen: _open,
      account: _account,
      ai: _ai,
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({
    super.key,
    required this.store,
    required this.note,
    this.account,
    this.ai = const RecordAi(),
    this.onTakeHandoff,
  });

  final NotesStore store;
  final Note note;

  /// 상대가 대신 적어 준 내 기록을 받는다. 받은 것은 새 운동 문서로 열린다.
  final void Function(String token)? onTakeHandoff;

  /// 문장 해석과 식단 사진이 같은 문을 쓴다.
  final RecordAi ai;

  /// 설정에서 로그인·결제를 띄우려고 넘어온다.
  final Account? account;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> with WidgetsBindingObserver {
  /// 같이 하기. 로그인·결제 계정이 있을 때만 있다.
  late final PartnerSync? _partner = widget.account == null
      ? null
      : PartnerSync(
          note: widget.note,
          link: () => widget.account!.link,
          onChanged: widget.store.touch,
        );

  StreamSubscription<({String kind, String token})>? _nearbyInvites;

  /// 화면이 보이는 동안만 상대의 변경을 확인한다. 백그라운드에서는 멈추고,
  /// 돌아오면 바로 최신 상태를 다시 묻는다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _partner?.start();
    } else {
      _partner?.stop();
    }
  }

  final _documentHeaderKey = GlobalKey<_DocumentHeaderState>();

  /// 어림을 기다리는 끼니. 그 줄은 '다시 어림' 대신 어림 중이라고 말한다.
  /// 고친 끼니는 새 객체라서, 옛 끼니의 늦은 답이 새 줄의 표시를 지우지 않는다.
  final _estimatingMeals = <MealEntry>{};
  late final _editor = RoutineEditorController(
    history: widget.store.exerciseHistory,
    weightUnit: widget.store.weightUnit,
    savedSetup: widget.store.setupOf,
  );
  String? _lastLearned;
  final _mealText = ValueNotifier<({String text, int? index})?>(null);

  // ── 대신 적기 ────────────────────────────────────────────────────
  // 같이 운동하는 사람의 세트를 내 폰에서 적는다. 같은 편집기를 쓰되 **다른
  // 칸**(note.proxy)에 적힌다 — 내 기록·내 통계·같이 하기 공유와 섞이지 않는다.
  bool _writingFor = false;
  RoutineEditorController? _proxyEditor;
  Timer? _proxySend;
  HandoffError? _proxyError;

  Future<void> _writeFor() async {
    final note = widget.note;
    final people = note.partner?.state == PartnerState.active
        ? note.partner!.others
        : const <PartnerPerson>[];
    if (note.proxy == null && people.length > 1) {
      // 셋 이상이 같이 한다. 누구의 것인지 알아야 그 사람 화면에만 받기가 뜬다.
      final who = await showCupertinoModalPopup<PartnerPerson>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(L.of(ctx).proxyWhose),
          actions: [
            for (final p in people)
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(ctx, p),
                child: Text(p.name),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(L.of(ctx).cancel),
          ),
        ),
      );
      if (who == null || !mounted) return;
      note.proxy = ProxyRecord(name: who.name, forKey: who.key);
    }
    final proxy = note.proxy ??= ProxyRecord(
      name: people.firstOrNull?.name ?? note.partner?.partnerName ?? '',
      forKey: people.firstOrNull?.key,
    );
    // 이름은 같이 하는 상대를 따라간다. 혼자 적기 시작했다가 나중에 연결해도 맞는다.
    if (proxy.name.isEmpty) proxy.name = note.partner?.partnerName ?? '';
    _proxyEditor ??=
        RoutineEditorController(
            history: widget.store.exerciseHistory,
            weightUnit: widget.store.weightUnit,
            savedSetup: widget.store.setupOf,
          )
          ..restore(proxy.blocks)
          ..addListener(_persistProxy);
    setState(() => _writingFor = true);
  }

  void _persistProxy() {
    final proxy = widget.note.proxy;
    if (proxy == null) return;
    proxy
      ..blocks = _proxyEditor!.blocks
      ..revision += 1;
    // 먼저 이 기기에 남긴다. 올리는 것은 그다음이고, 그물이 없으면 밀려 있다가 간다.
    widget.store.touch();
    _proxySend?.cancel();
    _proxySend = Timer(const Duration(seconds: 1), _sendProxy);
  }

  Future<HandoffError?> _sendProxy() async {
    final link = widget.account?.link;
    if (link == null) return HandoffError.signInRequired;
    final session = widget.note.partner;
    final error = await link.sendProxy(
      widget.note,
      sessionId: session?.state == PartnerState.active ? session!.id : null,
    );
    widget.store.touch();
    if (mounted) setState(() => _proxyError = error);
    return error;
  }

  /// 건넨다 — 올린 것을 확인하고 링크를 공유한다. 같이 하는 중이면 상대 화면에는
  /// 이미 "받기" 가 떠 있다. 링크는 폰이 곁에 없는 사람에게 보내는 길이다.
  Future<void> _handOver() async {
    _proxySend?.cancel();
    final error = await _sendProxy();
    final token = widget.note.proxy?.token;
    final link = widget.account?.link;
    if (!mounted || error != null || token == null || link == null) return;
    await shareText(L.of(context).proxyShareText(link.handoffUrl(token)));
  }

  /// 상대가 적어 준 내 기록이 와 있고, 아직 받지 않았다.
  ({String token, int revision, String from})? get _offered {
    final offer = widget.note.partner?.handoff;
    if (offer == null || widget.onTakeHandoff == null) return null;
    final taken = widget.store.notes.any(
      (n) =>
          n.handoffToken == offer.token &&
          (n.handoffRevision ?? 0) >= offer.revision,
    );
    return taken ? null : offer;
  }

  /// 같은 날 만든 다른 기록들. 하루에 문서가 여럿일 수 있다 — 오전에 한 장,
  /// 저녁에 한 장. 합치거나 베끼지 않고 이 문서 아래에 읽기 전용으로 보여 준다.
  List<Note> get _sameDay {
    final at = widget.note.createdAt;
    return [
      for (final n in widget.store.notes)
        if (n != widget.note &&
            n.blocks.isNotEmpty &&
            n.createdAt.year == at.year &&
            n.createdAt.month == at.month &&
            n.createdAt.day == at.day)
          n,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// 글로 적은 한 끼를 저장한다. 묻지 않는다 — 모르는 음식도, 양이 없는 글도
  /// 친 그대로 남고, 열량은 사람이 적었을 때만 있다. 일부만 적었으면 적은 합을
  /// 먼저 넣어 둔다 — 어림이 막혀도 적은 수는 합계에서 빠지지 않는다. 고치다
  /// 다 지우면 그 끼니가 없어진다.
  ///
  /// 새로 남긴 끼니면 그것을 지우는 함수를 돌려준다 — 운동 줄에서 알아서 끼니로
  /// 남긴 것을 '운동으로 바꾸기' 로 되돌린다. 그사이 어림이 붙어 바뀌었어도 같은
  /// 끼니(id)를 지운다.
  VoidCallback? _saveMealText(String text, int? index) {
    final meals = widget.note.meals;
    final old = index != null && index < meals.length ? meals[index] : null;
    VoidCallback? undo;
    if (text.isEmpty) {
      if (old != null) widget.note.removeMeal(old);
    } else {
      final parsed = parseMealText(text);
      final kcal = parsed.kcal ?? parsed.typed;
      final entry = MealEntry(
        id: old?.id, // 고친 끼니는 서버의 같은 줄이다.
        at: old?.at ?? DateTime.now(),
        kcal: kcal,
        text: text,
        source: kcal == null ? null : MealEntry.typed,
        foods: parsed.foods,
      );
      old == null ? meals.add(entry) : meals[index!] = entry;
      if (parsed.kcal == null) _estimateMealText(entry);
      if (old == null) {
        undo = () {
          final now = widget.note.meals.where((m) => m.id == entry.id);
          if (now.isEmpty) return;
          widget.note.removeMeal(now.first);
          _mealsChanged();
        };
      }
    }
    _mealsChanged();
    return undo;
  }

  /// 끼니가 바뀌었다. 먼저 이 기기에 쓰고, 그다음 서버의 같은 줄에 맞춘다 —
  /// 그물이 없으면 밀려 있다가 다음에 간다.
  void _mealsChanged() {
    widget.store.touch();
    final link = widget.account?.link;
    if (link == null || widget.note.gymId == null) return;
    syncMeals(link, [widget.note], onSynced: widget.store.touch);
  }

  /// 원문은 이미 저장됐다. 열량을 안 적은 끼니에 어림값을 붙여 볼 뿐이고,
  /// 못 붙이면 미상으로 남는다. 그사이 사람이 고쳤거나 지웠으면 손대지 않고
  /// 말도 하지 않는다 — 그 끼니의 일이 아니다.
  ///
  /// 못 붙였으면 **왜인지 한 번 말한다** — 모르는 음식인지, 연결이 안 된 것인지.
  /// 조용히 '열량 미상' 만 두면 무엇을 고쳐야 하는지 알 길이 없다. 그 끼니 줄에
  /// '다시 어림' 이 뜨고, 줄을 눌러 고친 뒤 Enter 를 눌러도 다시 어림한다.
  ///
  /// 글에 적힌 열량은 버리지 않는다. 어림이 적은 합보다 작으면 받지 않는다 —
  /// 적은 음식 값만으로도 그보다 크다. 그때와 어림이 막혔을 때는 적은 합이
  /// 남아 있고([_saveMealText]), 그렇다고 말한다.
  Future<void> _estimateMealText(MealEntry entry) async {
    final l = L.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final typed = parseMealText(entry.text!).typed;
    MealEstimate? estimate;
    String? failure;
    // 서버는 500자까지 받는다. 보내 봐야 거절이니 먼저 말한다.
    if (entry.text!.length > 500) {
      failure = l.mealTextTooLong;
    } else if (!widget.ai.supported) {
      failure = l.mealTextOffline;
    } else {
      _estimatingMeals.add(entry);
      try {
        estimate = await widget.ai.estimateMealText(
          entry.text!,
          locale: locale,
        );
      } on RecordAiException catch (e) {
        failure = switch ((e.status, e.code)) {
          (RecordAiStatus.aiOff, _) => l.aiOff,
          (RecordAiStatus.quotaExceeded, _) => l.inputQuotaSpent,
          (_, 'unknownFood' || 'notFood') => l.mealTextUnknown,
          // 서버도 적은 합보다 작은 어림을 내보내지 않는다 — 아래의 같은 까닭이다.
          (_, 'belowTyped') when typed != null => null,
          _ => l.mealTextOffline,
        };
      } catch (_) {
        failure = l.mealTextOffline;
      } finally {
        _estimatingMeals.remove(entry);
      }
    }
    if (!mounted) return;
    final at = widget.note.meals.indexOf(entry);
    if (at < 0) return;
    void tell(String? message) =>
        _documentHeaderKey.currentState?.tell(message, entry);
    if (estimate == null || (typed != null && estimate.kcal < typed)) {
      return tell(
        [
          failure ?? l.mealTextBelowTyped(typed!),
          if (failure != null && typed != null) l.mealTextPartial(typed),
        ].join('\n'),
      );
    }
    // 다시 어림해 붙었다. 이 끼니가 앞서 말한 실패는 이제 틀린 말이다.
    tell(null);
    widget.note.meals[at] = MealEntry(
      id: entry.id,
      at: entry.at,
      kcal: estimate.kcal,
      items: estimate.items,
      text: entry.text,
      source: MealEntry.estimate,
      foods: entry.foods,
      sources: estimate.sources,
    );
    _mealsChanged();
  }

  /// 이 화면을 연 때의 기록.
  late final String _openedJson = jsonEncode(blocksToJson(widget.note.blocks));

  @override
  void initState() {
    super.initState();
    _openedJson;
    _editor.restore(widget.note.blocks);
    _lastLearned = _editor.recentExercises.firstOrNull;
    _editor.addListener(_persist);
    WidgetsBinding.instance.addObserver(this);
    _partner?.addListener(_partnerChanged);
    // 가까이 댄 상대가 건넨 같이 하기 초대. 코드를 친 것과 같은 길로 참여한다 —
    // 같은 토큰이 여러 번 와도 참여는 한 번이다(PartnerSync.joinWithToken).
    _nearbyInvites = Nearby.instance.received
        .where((invite) => invite.kind == 'session')
        .listen((invite) => _partner?.joinWithToken(invite.token));
    // 다시 들어왔을 때 서버에 상태를 물어 복구한다(열린 세션이 있을 때만 돈다).
    if (widget.note.partner?.open ?? false) _partner?.start();
  }

  /// 오늘 한 장 — 그날 한 세트 전부, 먹은 것, 섭취−운동을 한 화면에.
  void _showDaySheet() {
    final l = L.of(context);
    final at = widget.note.createdAt;
    final day = dayLogs(widget.store.notes, from: at, to: at).firstOrNull;
    showFitAll(
      context,
      [
        (
          caption: DateFormat.jm(l.localeName).format(widget.note.createdAt),
          blocks: _editor.blocks,
        ),
        for (final n in _sameDay)
          (
            caption: DateFormat.jm(l.localeName).format(n.createdAt),
            blocks: n.blocks,
          ),
      ],
      energy: day == null ? null : dayEnergyText(l, day),
      meals: [
        for (final m in day?.meals ?? const <MealEntry>[])
          (
            text: m.text ?? m.items.join(', '),
            kcal: m.kcal == null
                ? l.mealKcalUnknown
                : m.partial
                ? l.kcalAtLeast(m.kcal!)
                : m.approximate
                ? l.kcalApprox(m.kcal!)
                : l.kcal(m.kcal!),
          ),
      ],
    );
  }

  /// 이 기록으로 할 수 있는 일들. 머리 줄에 흩어 두었을 때는 어느 것이 식단이고
  /// 어느 것이 운동의 것인지 헷갈렸다 — 한 곳에 모은다.
  void _showMenu() {
    final l = L.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          if (_editor.blocks.isNotEmpty)
            CupertinoActionSheetAction(
              key: const ValueKey('menu-day-sheet'),
              onPressed: () {
                Navigator.pop(ctx);
                _showDaySheet();
              },
              child: Text(l.fitAll),
            ),
          // 같이 하기. 로그인하지 않았으면 창 안에서 로그인으로 이어진다.
          if (_partner != null)
            CupertinoActionSheetAction(
              key: const ValueKey('menu-partner'),
              onPressed: () {
                Navigator.pop(ctx);
                showPartnerSheet(
                  context,
                  widget.account!,
                  _partner,
                  onWriteFor: _writeFor,
                );
              },
              child: Text(l.partnerInvite),
            ),
          CupertinoActionSheetAction(
            key: const ValueKey('menu-settings'),
            onPressed: () async {
              Navigator.pop(ctx);
              await showWeightSettings(
                context,
                widget.store,
                account: widget.account,
              );
              if (mounted) {
                setState(() => _editor.weightUnit = widget.store.weightUnit);
              }
            },
            child: Text(l.settingsTitle),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
      ),
    );
  }

  void _partnerChanged() {
    if (!mounted) return;
    // 세션이 열리면 돌고, 끝나면 멈춘다.
    (widget.note.partner?.open ?? false) ? _partner!.start() : _partner!.stop();
    // 같이 고치는 문서가 새로 왔다. 편집기를 그것으로 — 내 커서는 그 운동을 따라간다.
    final doc = _partner.takeDoc();
    if (doc != null) {
      final lost = _editor.replaceBlocks(doc);
      if (lost != null) {
        unawaited(
          showCupertinoDialog<void>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              content: Text(
                L.of(ctx).liveExerciseRemoved(lost.name),
                style: const TextStyle(fontSize: 15),
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(L.of(ctx).ok),
                ),
              ],
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  void _persist() {
    // 편집기가 초안을 되살리며 첫 그리기 도중에 부를 수 있다. 그때 저장소가 알리면
    // 그리는 중에 다시 그리라는 것이 되어 예외가 난다 — 한 프레임 미룬다.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _persist();
      });
      return;
    }
    final recent = _editor.recentExercises.firstOrNull;
    if (recent != _lastLearned && recent != null) {
      widget.store.rememberExercise(recent);
    }
    _lastLearned = recent;
    final note = widget.note;
    // 연 때의 기록과 견준다. note.blocks 는 첫 저장 뒤로 편집기의 목록 그 자체라
    // 서로 견주면 늘 같았다 — 건네받은 기록을 고쳐도 다시 받기가 덮었다.
    // 같이 고치는 사람에게서 온 변경은 내가 고친 것이 아니다.
    if (note.handoffToken != null &&
        !note.handoffTouched &&
        !_editor.remote &&
        jsonEncode(blocksToJson(_editor.blocks)) != _openedJson) {
      // 건네받은 기록을 내가 고쳤다. 이제 내 것이다 — 보낸 사람이 더 적어 보내도
      // 이 문서를 덮지 않는다.
      note.handoffTouched = true;
    }
    widget.store.update(widget.note, _editor.blocks);
    // 내 기록은 방금 이 기기에 저장됐다. 그다음에 상대에게 보낸다.
    _partner?.recordChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nearbyInvites?.cancel();
    _partner?.removeListener(_partnerChanged);
    _partner?.dispose();
    _proxySend?.cancel();
    _proxyEditor
      ?..removeListener(_persistProxy)
      ..dispose();
    _editor.removeListener(_persist);
    widget.store.flush();
    _editor.dispose();
    _mealText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return CupertinoPageScaffold(
      // One shared keyboard area is managed by the editor.
      resizeToAvoidBottomInset: false,
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        border: null,
        previousPageTitle: l.allNotes,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 위 막대에는 … 와 완료뿐이다. 나머지는 전부 메뉴 안에 — 버튼이 넷씩
            // 늘어서 있으면 어느 것도 눈에 안 들어온다.
            CupertinoButton(
              key: const ValueKey('record-menu'),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              onPressed: _showMenu,
              child: Icon(
                CupertinoIcons.ellipsis_circle,
                size: 21,
                semanticLabel: l.recordMenu,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l.doneEditing,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        // The keypad owns the bottom safe area, including during IME transitions.
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // 같이 운동 중이면 상대 이름과 상태를 작게. 누르면 상대 기록이 나온다.
                if (widget.note.partner?.state == PartnerState.active)
                  GestureDetector(
                    key: const ValueKey('partner-banner'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => showPartnerSheet(
                      context,
                      widget.account!,
                      _partner,
                      onWriteFor: _writeFor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.person_2_fill,
                            size: 14,
                            color: seal.resolveFrom(context),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _partner!.reachable
                                  ? l.partnerWith(
                                      widget.note.partner!.partnerName ?? '',
                                    )
                                  : l.partnerReconnecting,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                          if (!_writingFor)
                            CupertinoButton(
                              key: const ValueKey('write-for'),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(44, 28),
                              onPressed: _writeFor,
                              child: Text(
                                l.proxyWrite,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (_offered != null && !_writingFor)
                  _Strip(
                    key: const ValueKey('handoff-offer'),
                    text: l.handoffOffer(_offered!.from),
                    action: l.handoffTake,
                    onAction: () => widget.onTakeHandoff!(_offered!.token),
                  ),
                if (_writingFor)
                  _Strip(
                    key: const ValueKey('proxy-bar'),
                    strong: true,
                    text: [
                      l.proxyWriting(
                        widget.note.proxy!.name.isEmpty
                            ? l.proxyDefaultName
                            : widget.note.proxy!.name,
                      ),
                      if (_proxyError == HandoffError.network)
                        l.partnerReconnecting
                      else if (_proxyError == HandoffError.signInRequired)
                        l.partnerSignIn,
                    ].join(' · '),
                    action: l.proxyHand,
                    onAction: widget.note.proxy!.blocks.isEmpty
                        ? null
                        : _handOver,
                    second: l.proxyBack,
                    onSecond: () => setState(() => _writingFor = false),
                  ),
                if (_writingFor)
                  Expanded(
                    child: RoutineEditor(
                      // 다른 칸을 적는 다른 편집기다. 내 기록의 타이머·식단·공유가
                      // 여기로 새지 않게 아무것도 넘기지 않는다.
                      key: const ValueKey('proxy-editor'),
                      countAloud: widget.store.countAloud,
                      controller: _proxyEditor!,
                      ai: widget.ai,
                    ),
                  )
                else
                  Expanded(
                    child: RoutineEditor(
                      key: const ValueKey('own-editor'),
                      countAloud: widget.store.countAloud,
                      controller: _editor,
                      partner: _partner,
                      // 같이 고치는 사람들이 지금 만지는 자리와, 내가 만지는 자리.
                      presence:
                          widget.note.partner?.state == PartnerState.active
                          ? widget.note.partner!.presence
                          : const [],
                      onPresence: _partner == null
                          ? null
                          : (block, set, text) => _partner.presence(
                              block: block,
                              set: set,
                              text: text,
                            ),
                      ai: widget.ai,
                      header: _DocumentHeader(
                        key: _documentHeaderKey,
                        note: widget.note,
                        store: widget.store,
                        ai: widget.ai,
                        mealText: _mealText,
                        onMealsChanged: _mealsChanged,
                        estimating: _estimatingMeals,
                        onRetryMeal: _estimateMealText,
                      ),
                      footer: _sameDay.isEmpty
                          ? null
                          : _SameDay(notes: _sameDay),
                      mealText: _mealText,
                      onMealText: _saveMealText,
                      recentMeals: <String>{
                        for (final n in widget.store.notes)
                          for (final m in n.meals.reversed) ?m.text,
                      }.take(24).toList(),
                      initialDraft: widget.note.draft,
                      onDraftChanged: (draft) =>
                          widget.store.updateDraft(widget.note, draft),
                      onForgetExercise: widget.store.forgetExercise,
                      onMealPhoto: () =>
                          _documentHeaderKey.currentState?._pick(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentHeader extends StatefulWidget {
  const _DocumentHeader({
    super.key,
    required this.note,
    required this.store,
    required this.ai,
    this.mealText,
    this.onMealsChanged,
    this.estimating = const {},
    this.onRetryMeal,
  });
  final Note note;
  final NotesStore store;
  final RecordAi ai;

  /// 어림을 기다리는 끼니와, 열량을 모르는 글 끼니를 다시 어림하는 길.
  final Set<MealEntry> estimating;
  final Future<void> Function(MealEntry)? onRetryMeal;

  /// 식단 글은 아래 입력 줄에서 친다. 여기서는 그 모드를 켜기만 한다.
  final ValueNotifier<({String text, int? index})?>? mealText;

  /// 끼니를 더하거나 고치거나 지웠다. 저장과 서버 맞춤은 문서 쪽이 한다.
  final VoidCallback? onMealsChanged;

  @override
  State<_DocumentHeader> createState() => _DocumentHeaderState();
}

/// 메모 앱의 머리다 — 날짜 한 줄이 가운데에 작게 놓이고 끝이다.
///
/// 예전에는 그 아래에 "오늘 운동" 을 크게 적었다. 날짜 바로 밑에 같은 말을
/// 한 번 더 쓴 셈이고, 제목은 어차피 첫 운동 이름이 된다(목록이 그것을
/// 쓴다). 칼로리는 숫자가 있을 때만 나온다 — "기록 없음" 은 정보가 아니다.
///
/// 식단은 사진 한 장으로 어림한다. 운동으로 쓴 것과 먹은 것을 같은 줄에
/// 두면 "오늘 얼마나 남았나" 가 한눈에 읽힌다. 숫자는 어림이라고 적는다.
class _DocumentHeaderState extends State<_DocumentHeader> {
  bool _estimating = false;

  /// 머리의 알림 한 줄과, 그것이 어느 끼니의 어림 실패인가(사진 쪽 말이면 null).
  /// 끼니는 그 객체다 — 고치면 새 객체라, 고치거나 지운 끼니의 말은 보이지 않는다.
  ({String text, MealEntry? meal})? _error;

  /// 보일 알림. 그 끼니가 이 문서에 그대로 있을 때만 — 사람이 열량을 적어
  /// 고쳤거나 지웠으면 '어림하지 못했어요' 는 이제 틀린 말이다.
  String? get _notice {
    final e = _error;
    return e == null || e.meal == null || note.meals.contains(e.meal)
        ? e?.text
        : null;
  }

  Note get note => widget.note;

  // 식단은 아래 입력 줄에서도 저장된다. 저장소가 바뀌면 다시 그린다.
  void _onStore() => setState(() {});

  /// 식단 글 끼니 [meal] 의 어림이 막힌 이유를 사진 쪽과 같은 자리에 적는다.
  /// null 이면 지우되, **그 끼니가 남긴 말만** 지운다 — 다른 끼니의 어림이
  /// 붙었다고 앞 끼니의 '모르는 음식' 을 덮지 않는다.
  void tell(String? message, MealEntry meal) {
    if (message == null && _error?.meal != meal) return;
    setState(
      () => _error = message == null ? null : (text: message, meal: meal),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    super.dispose();
  }

  Future<void> _addMeal(ImageSource source) async {
    final l = L.of(context);
    // 사진을 고르기 전에 본다 — 고른 뒤에 막히면 헛걸음이다. 꺼 두었으면
    // 글로 적는 길을 말한다(적은 kcal 은 그대로 들어간다).
    if (!widget.ai.allowed) {
      setState(() => _error = (text: l.aiOffPhoto, meal: null));
      return;
    }
    final XFile? file;
    try {
      // 1024px 이면 접시가 충분히 보이고, 보내는 양은 수백 KB 다.
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
    } catch (_) {
      if (mounted) setState(() => _error = (text: l.mealFailed, meal: null));
      return;
    }
    if (file == null || !mounted) return;
    final locale = Localizations.localeOf(context).toLanguageTag();
    setState(() {
      _estimating = true;
      _error = null;
    });
    try {
      final bytes = await file.readAsBytes();
      final hour = DateTime.now().hour;
      final estimate = await widget.ai.estimateMeal(
        bytes,
        mime: file.mimeType ?? 'image/jpeg',
        locale: locale,
        gymId: note.gymId,
        kind: hour < 10
            ? 'breakfast'
            : hour < 15
            ? 'lunch'
            : hour < 21
            ? 'dinner'
            : 'snack',
      );
      final label = estimate.label;
      if (label != null) {
        // 성분표는 인쇄된 숫자다. 얼마나 먹었는지만 받아 계산한다. 취소하면
        // 아무것도 남기지 않는다 — 다시 찍어도 끼니가 둘이 되지 않는다.
        if (!mounted) return;
        setState(() => _estimating = false);
        final picked = await askMealAmount(
          context,
          bases: basesOf(label),
          title: label.product,
        );
        if (picked == null || !mounted) return;
        note.meals.add(_measured(picked, MealEntry.label, label.product));
      } else {
        // 사진 어림은 **보이는 음식 전체**의 값이다. 묻지 않고 전체로 남기고,
        // 덜 먹었으면 그 줄을 눌러 고친다 — 매번 창을 띄우지 않는다.
        note.meals.add(
          MealEntry(
            at: DateTime.now(),
            kcal: estimate.kcal,
            items: estimate.items,
            source: MealEntry.estimate,
            sources: estimate.sources,
            basis: MealBasis(
              kcal: estimate.kcal.toDouble(),
              amount: 1,
              unit: MealBasis.photo,
            ),
            eaten: 1,
          ),
        );
      }
      _changed();
    } on RecordAiException catch (e) {
      _error = (
        text: switch (e.status) {
          RecordAiStatus.quotaExceeded => l.inputQuotaSpent,
          RecordAiStatus.aiOff => l.aiOffPhoto,
          _ => l.mealFailed,
        },
        meal: null,
      );
    } catch (_) {
      _error = (text: l.mealFailed, meal: null);
    }
    if (mounted) setState(() => _estimating = false);
  }

  /// 근거와 먹은 양으로 한 끼를 만든다. 열량은 여기서 한 번만 반올림된다.
  void _changed() => (widget.onMealsChanged ?? widget.store.touch)();

  MealEntry _measured(
    ({MealBasis basis, double eaten}) picked,
    String source,
    String? name, {
    MealEntry? old,
  }) => MealEntry(
    id: old?.id, // 양을 고친 끼니는 서버의 같은 줄이다.
    at: old?.at ?? DateTime.now(),
    kcal: picked.basis.kcalFor(picked.eaten),
    items: old != null && old.basis?.unit == MealBasis.photo
        ? old.items
        : [?name],
    source: source,
    basis: picked.basis,
    eaten: picked.eaten,
    // 양만 고쳤다. 100g 당 값은 그대로라 근거도 그대로다.
    sources: old?.sources ?? const [],
  );

  /// 끼니 한 줄을 눌렀다. 글로 적은 것은 입력 줄로 불러 고치고, 근거가 있는
  /// 것은 먹은 양을 다시 받는다. 저장된 열량에 또 곱하지 않는다 — 근거에서
  /// 다시 계산해 **그 자리를** 바꾼다.
  Future<void> _editMeal(int index) async {
    final meal = note.meals[index];
    if (meal.text != null) {
      widget.mealText?.value = (text: meal.text!, index: index);
      return;
    }
    final basis = meal.basis;
    if (basis == null) return; // 예전 기록 — 다시 계산할 근거가 없다.
    final photo = basis.unit == MealBasis.photo;
    final picked = await askMealAmount(
      context,
      bases: [basis],
      title: meal.items.isEmpty ? null : meal.items.join(', '),
      note: photo ? L.of(context).mealPhotoWholeNote : null,
      initialBasis: basis,
      initialEaten: meal.eaten,
    );
    if (picked == null || !mounted || index >= note.meals.length) return;
    note.meals[index] = _measured(
      picked,
      meal.source ?? MealEntry.estimate,
      meal.items.firstOrNull,
      old: meal,
    );
    _changed();
    setState(() {});
  }

  void _pick() {
    final l = L.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l.mealPhoto),
        message: Text(l.mealEstimateNote),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _addMeal(ImageSource.camera);
            },
            child: Text(l.mealCamera),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _addMeal(ImageSource.gallery);
            },
            child: Text(l.mealGallery),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final at = note.createdAt;
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    // 하루치다 — 이 문서 하나가 아니라 그날의 문서와 끼니 전부.
    final log = dayLogs(widget.store.notes, from: at, to: at).firstOrNull;
    final energy = log == null ? null : dayEnergyText(l, log);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l.dayLabel(at)} · ${l.weekdayLabel(at)}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: muted),
          ),
          // 섭취 · 운동 · 차이를 작은 한 줄로.
          if (energy != null)
            Padding(
              key: const ValueKey('day-summary'),
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                energy,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
          if (note.meals.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final (i, meal) in note.meals.indexed)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      key: ValueKey('meal-$i'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _editMeal(i),
                      child: Text(
                        [
                          widget.estimating.contains(meal)
                              ? l.mealEstimating
                              : meal.kcal == null
                              ? l.mealKcalUnknown
                              : meal.partial
                              ? l.kcalAtLeast(meal.kcal!)
                              : meal.approximate
                              ? l.kcalApprox(meal.kcal!)
                              : l.kcal(meal.kcal!),
                          meal.text ?? meal.items.join(', '),
                          if (meal.basis != null &&
                              meal.eaten != null &&
                              !(meal.basis!.unit == MealBasis.photo &&
                                  meal.eaten == 1))
                            mealEatenText(l, meal.basis!, meal.eaten!),
                        ].where((t) => t.isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                    ),
                  ),
                  // 글은 있는데 열량을 (다) 모른다 — 그 자리에서 다시 어림한다.
                  // 어림을 기다리는 동안은 줄이 그렇다고 말하니 단추를 두지 않는다.
                  if (widget.onRetryMeal != null &&
                      meal.text != null &&
                      (meal.kcal == null || meal.partial) &&
                      !widget.estimating.contains(meal))
                    CupertinoButton(
                      key: ValueKey('meal-retry-$i'),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(32, 32),
                      onPressed: () {
                        widget.onRetryMeal!(meal);
                        setState(() {});
                      },
                      child: Text(
                        l.mealRetry,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  // 표에서 찾은 값으로 셈했으면 그 표를 보여 준다 — 숫자만으로는 믿을 까닭이 없다.
                  if (meal.sources.isNotEmpty)
                    CupertinoButton(
                      key: ValueKey('meal-sources-$i'),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(32, 32),
                      onPressed: () => showMealSources(context, meal.sources),
                      child: Text(
                        l.mealSources,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  CupertinoButton(
                    key: ValueKey('meal-delete-$i'),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(32, 32),
                    onPressed: () {
                      note.removeMeal(meal);
                      _changed();
                      setState(() {});
                    },
                    child: Icon(CupertinoIcons.xmark, size: 14, color: muted),
                  ),
                ],
              ),
          ],
          if (_notice case final notice?)
            Text(
              notice,
              style: TextStyle(fontSize: 13, color: seal.resolveFrom(context)),
            ),
          // 식단 사진·글 버튼은 여기 없다. 입력 줄 위의 막대에 같은 것이 늘 있어서
          // 화면 맨 위에 또 둘 이유가 없었다. 사진을 읽는 동안이라는 것만 알린다.
          if (_estimating)
            Text(
              l.mealEstimating,
              style: TextStyle(fontSize: 13, color: muted),
            ),
          // 여기까지가 하루·식단, 아래부터가 운동이다. 줄 하나가 두 동네를 가른다 —
          // 버튼을 여기 두었을 때는 어느 쪽 것인지 헷갈렸다.
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              key: const ValueKey('section-divider'),
              height: 0.5,
              color: CupertinoColors.separator.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// 같은 날의 다른 기록 — 읽기 전용이다. 원본은 제 문서에 그대로 있고 여기서는
/// 보여 주기만 한다. 고치려면 그 문서를 연다.
class _SameDay extends StatelessWidget {
  const _SameDay({required this.notes});
  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final n in notes) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${l.sameDayOther} · ${DateFormat.jm(l.localeName).format(n.createdAt)}',
                style: TextStyle(fontSize: 13, color: muted),
              ),
            ),
            for (final b in n.blocks) BlockSummary(block: b),
          ],
        ],
      ),
    );
  }
}

/// 기록 화면 위의 한 줄 — 무슨 일이 벌어지고 있는지와, 누를 것 하나둘.
class _Strip extends StatelessWidget {
  const _Strip({
    super.key,
    required this.text,
    required this.action,
    required this.onAction,
    this.second,
    this.onSecond,
    this.strong = false,
  });
  final String text, action;
  final VoidCallback? onAction;
  final String? second;
  final VoidCallback? onSecond;

  /// 내 기록이 아닌 것을 적는 중이다. 헷갈리면 안 되는 상태라 색을 입힌다.
  final bool strong;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
    padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
    decoration: BoxDecoration(
      color: strong
          ? seal.resolveFrom(context).withValues(alpha: 0.12)
          : CupertinoColors.secondarySystemBackground.resolveFrom(context),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        if (second != null)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(44, 36),
            onPressed: onSecond,
            child: Text(second!, style: const TextStyle(fontSize: 13)),
          ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(44, 36),
          onPressed: onAction,
          child: Text(
            action,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
