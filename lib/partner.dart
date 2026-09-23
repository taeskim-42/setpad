/// 같이 하기 — 두 사람이 그날 운동 하나씩을 잇는다.
///
/// **연결 수단과 세션은 다른 것이다.** 코드를 치든 NFC·근접 통신으로 토큰을
/// 받든 그것은 초대를 건네받은 것뿐이고, "같이 운동 중" 은 서버가 참여를
/// 확정해 [PartnerState.active] 를 돌려준 뒤다. 화면은 서버가 말한 상태만 믿는다.
///
/// **각자의 기록은 각자의 것이다.** 내 기록은 내가 쓰고 상대는 읽는다. 상대의
/// 기록은 [PartnerSession.partnerBlocks] 에만 있고 내 운동 칸에 섞이지 않는다.
///
/// **내 기록은 먼저 이 기기에 저장된다.** 그물이 끊겨도 기록은 계속되고, 밀린
/// 것은 다음 기회에 올라간다. 서버·세션이 없어져도 내 운동은 그대로 남는다.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_route.dart';
import 'editor.dart';
import 'live_doc.dart';
import 'gym.dart';
import 'notes.dart';
import 'shared_timer.dart';
import 'workout_timing.dart';

enum PartnerState { waiting, active, ended, expired }

/// 왜 안 됐는가. 화면이 이유마다 다른 말과 다른 다음 행동을 낸다 — 전부
/// "코드가 틀렸다" 로 뭉개지 않는다.
enum PartnerError {
  signInRequired,
  invalidFormat,
  invalidCode,
  expired,
  ended,
  ownInvite,
  tooManyTries,
  network,
  server,
}

/// 코드에 쓰는 글자. 서버와 같다 — 0·O, 1·I 가 없다.
final _codeShape = RegExp(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$');

/// 사람이 친 코드를 서버와 같은 규칙으로 다듬는다. 모양이 틀리면 null 이고,
/// 그때는 서버에 묻지 않는다.
String? normalizePartnerCode(String raw) {
  final code = raw.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  return _codeShape.hasMatch(code) ? code : null;
}

/// 같이 하는 사람 한 명. [key] 는 서버가 지어 준 이 세션 안의 이름표다 — 계정이 아니다.
class PartnerPerson {
  const PartnerPerson({
    required this.key,
    required this.name,
    this.blocks = const [],
    this.updatedAt,
  });
  final String key, name;

  /// 그 사람의 기록 — 읽기 전용이다.
  final List<ExerciseBlock> blocks;
  final DateTime? updatedAt;
}

/// 지금 누가 어디를 만지는가. 상대 화면의 "커서" 다.
class PartnerPresence {
  const PartnerPresence({
    required this.key,
    required this.name,
    this.block,
    this.set,
    this.text = '',
  });
  final String key, name;

  /// 운동 id 와 세트 id. 세트가 '+' 면 그 운동의 다음 세트를 치는 중이다.
  /// 운동이 null 이면 새 운동 이름을 치는 중이다.
  final String? block, set;
  final String text;
}

class PartnerSession {
  PartnerSession({
    required this.id,
    required this.host,
    required this.state,
    this.code,
    this.token,
    this.expiresAt,
    this.partnerName,
    this.endedByMe,
    this.revision = 0,
    this.pushed = 0,
    List<ExerciseBlock>? partnerBlocks,
    this.partnerUpdatedAt,
    this.partnerLoaded = false,
  }) : partnerBlocks = partnerBlocks ?? [];

  final String id;
  final bool host;
  PartnerState state;

  /// 기다리는 동안 호스트만 가진다. 코드는 사람이 불러 주고, 토큰은 무선으로 건넨다.
  String? code, token;
  DateTime? expiresAt;
  String? partnerName;
  bool? endedByMe;

  /// 내 기록의 번호와, 서버가 받았다고 한 번호. 다르면 올릴 것이 밀려 있다.
  int revision, pushed;

  /// 상대의 기록 — 읽기 전용이다. 아직 한 번도 못 받았으면 [partnerLoaded] 가
  /// false 다: 빈 목록을 "기록 없음" 으로 보여 주면 데이터가 사라진 것처럼 보인다.
  List<ExerciseBlock> partnerBlocks;
  DateTime? partnerUpdatedAt;
  bool partnerLoaded;

  /// 같이 하는 사람 전부(나 빼고). 둘이 할 때는 한 명이고, [partnerName]·
  /// [partnerBlocks] 가 곧 그 사람이다. 셋 이상이면 [partnerName] 은 이름을 이어 붙인
  /// 것이고 [partnerBlocks] 는 첫 사람의 것이다.
  // ponytail: 저장하지 않는다. 앱을 껐다 켠 직후 그물이 없으면 첫 사람만 보인다 —
  // 다음 폴링에 돌아온다. 오프라인에서도 전원을 봐야 하면 toJson 에 넣는다.
  List<PartnerPerson> others = const [];

  /// 더 들어올 수 있는 자리. 호스트가 "한 명 더" 를 낼지 정하는 데 쓴다.
  int room = 0;

  /// 같이 하는 타이머. 저장하지 않는다 — 서버가 매번 다시 말해 준다.
  SharedTimer? timer;

  /// 같이 고치는 한 문서(서버가 준 그대로)와 그 버전, 누가 어디를 만지는지,
  /// 이 세션에서 나를 가리키는 키. 모두 저장하지 않는다.
  List<Json>? doc;
  int docVersion = 0;

  /// 이 기기가 마지막으로 받은 서버 문서와 그 버전. **저장한다** — 화면을 다시
  /// 열거나 앱을 다시 켰을 때 이것과 내 기록의 차이가 곧 아직 못 올린 내 수정이다.
  /// 없으면 처음 참여하는 것이다.
  List<Json>? docBase;
  int docBaseVersion = 0;
  List<PartnerPresence> presence = const [];
  String? me;

  /// 상대가 내 세트를 대신 적어 주고 있다. 받기 전에는 내 기록이 아니다.
  ({String token, int revision, String from})? handoff;

  bool get open =>
      state == PartnerState.waiting || state == PartnerState.active;

  Map<String, Object?> toJson() => {
    'id': id,
    'host': host,
    'state': state.name,
    'code': ?code,
    'token': ?token,
    'expiresAt': ?expiresAt?.toIso8601String(),
    'partnerName': ?partnerName,
    'endedByMe': ?endedByMe,
    'revision': revision,
    'pushed': pushed,
    if (partnerLoaded) 'partnerBlocks': blocksToJson(partnerBlocks),
    'partnerUpdatedAt': ?partnerUpdatedAt?.toIso8601String(),
    'docBase': ?docBase,
    'docBaseVersion': docBaseVersion,
  };

  static PartnerSession? tryFromJson(Object? j) {
    if (j is! Map || j['id'] is! String) return null;
    final expires = j['expiresAt'], updated = j['partnerUpdatedAt'];
    return PartnerSession(
      id: j['id'] as String,
      host: j['host'] == true,
      state: PartnerState.values.asNameMap()[j['state']] ?? PartnerState.ended,
      code: j['code'] is String ? j['code'] as String : null,
      token: j['token'] is String ? j['token'] as String : null,
      expiresAt: expires is String ? DateTime.tryParse(expires) : null,
      partnerName: j['partnerName'] is String
          ? j['partnerName'] as String
          : null,
      endedByMe: j['endedByMe'] is bool ? j['endedByMe'] as bool : null,
      revision: j['revision'] is int ? j['revision'] as int : 0,
      pushed: j['pushed'] is int ? j['pushed'] as int : 0,
      partnerBlocks: blocksFromJson(j['partnerBlocks']),
      partnerUpdatedAt: updated is String ? DateTime.tryParse(updated) : null,
      partnerLoaded: j['partnerBlocks'] is List,
    )
      ..docBase = j['docBase'] is List
          ? [
              for (final b in j['docBase'] as List)
                if (b is Map) b.cast<String, Object?>(),
            ]
          : null
      ..docBaseVersion = j['docBaseVersion'] is int
          ? j['docBaseVersion'] as int
          : 0;
  }
}

typedef PartnerReply = ({Map<String, Object?>? body, PartnerError? error});

extension PartnerLink on GymLink {
  Future<PartnerReply> _partner(
    String method,
    String path, [
    Map<String, Object?>? body,
  ]) async {
    if (!supported) return (body: null, error: PartnerError.signInRequired);
    return withClient((web) async {
      try {
        final request = http.Request(method, Uri.parse('$endpoint$path'))
          ..headers.addAll({...headers, 'content-type': 'application/json'});
        if (body != null) request.body = jsonEncode(body);
        final response = await http.Response.fromStream(
          await web.send(request).timeout(const Duration(seconds: 10)),
        );
        Object? decoded;
        try {
          decoded = jsonDecode(utf8.decode(response.bodyBytes));
        } catch (_) {}
        final map = decoded is Map ? decoded.cast<String, Object?>() : null;
        if (response.statusCode == 200 && map != null) {
          return (body: map, error: null);
        }
        return (
          body: map,
          error: switch ((response.statusCode, map?['error'])) {
            (401, _) => PartnerError.signInRequired,
            (_, 'invalidCode') => PartnerError.invalidCode,
            (_, 'expired') => PartnerError.expired,
            (_, 'ended') || (_, 'notFound') => PartnerError.ended,
            (_, 'ownInvite') => PartnerError.ownInvite,
            (429, _) => PartnerError.tooManyTries,
            (400, _) => PartnerError.invalidFormat,
            _ => PartnerError.server,
          },
        );
      } catch (_) {
        // 시간 초과와 끊긴 그물. 코드 탓이 아니다.
        return (body: null, error: PartnerError.network);
      }
    });
  }

  Future<PartnerReply> openPartnerSession(
    String localId, {
    bool renew = false,
  }) => _partner('POST', '/api/partner-sessions', {
    'localId': localId,
    if (renew) 'renew': true,
  });

  Future<PartnerReply> joinPartnerSession(
    String localId, {
    String? code,
    String? token,
  }) => _partner('POST', '/api/partner-sessions/join', {
    'localId': localId,
    'code': ?code,
    'token': ?token,
  });

  Future<PartnerReply> partnerSessionState(String id) =>
      _partner('GET', '/api/partner-sessions/$id');

  Future<PartnerReply> savePartnerRecord(
    String id,
    int revision,
    List<ExerciseBlock> blocks, {
    required int base,
    bool force = false,
  }) => _partner('PUT', '/api/partner-sessions/$id/record', {
    'revision': revision,
    'base': base,
    if (force) 'force': true,
    'result': blocksToJson(blocks),
  });

  Future<PartnerReply> partnerTimer(String id, Map<String, Object?> action) =>
      _partner('PUT', '/api/partner-sessions/$id/timer', action);

  Future<PartnerReply> partnerDoc(String id, Map<String, Object?> action) =>
      _partner('PUT', '/api/partner-sessions/$id/doc', action);

  Future<PartnerReply> partnerPresence(String id, Map<String, Object?> where) =>
      _partner('PUT', '/api/partner-sessions/$id/presence', where);

  /// 서버가 밀어 주는 세션 상태(SSE). 한 줄이 한 상태다. 끊기면 스트림이 끝난다 —
  /// 다시 여는 것은 부르는 쪽이 한다.
  Stream<Map<String, Object?>> partnerEvents(String id) async* {
    if (!supported) return;
    final web = client ?? newApiClient();
    try {
      final request = http.Request(
        'GET',
        Uri.parse('$endpoint/api/partner-sessions/$id/events'),
      )..headers.addAll({...headers, 'accept': 'text/event-stream'});
      final response = await web
          .send(request)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;
      var buffer = '';
      // 서버는 15초마다 빈 줄을 보낸다. 40초 동안 아무것도 없으면 연결이 죽은
      // 것이다(반쯤 열린 소켓) — 끊고 다시 연다.
      await for (final chunk
          in response.stream
              .timeout(const Duration(seconds: 40))
              .transform(utf8.decoder)) {
        buffer += chunk;
        while (true) {
          final cut = buffer.indexOf('\n\n');
          if (cut < 0) break;
          final event = buffer.substring(0, cut);
          buffer = buffer.substring(cut + 2);
          for (final line in event.split('\n')) {
            if (!line.startsWith('data:')) continue;
            final decoded = jsonDecode(line.substring(5).trim());
            if (decoded is Map) yield decoded.cast<String, Object?>();
          }
        }
      }
    } catch (_) {
      // 끊긴 것이다. 부르는 쪽이 다시 연다.
    } finally {
      if (client == null) web.close();
    }
  }

  Future<PartnerReply> endPartnerSession(String id) =>
      _partner('POST', '/api/partner-sessions/$id/end');
}

/// 한 운동 문서의 같이 하기. 화면은 이것을 듣고 그리기만 한다.
class PartnerSync extends ChangeNotifier {
  PartnerSync({
    required this.note,
    required this.link,
    required this.onChanged,
    // 모으는 0.4초 + 이 간격 + 왕복이 3초 안에 들어오게 잡았다.
    this.interval = const Duration(seconds: 2),
    ServerClock? clock,
  }) : clock = clock ?? ServerClock();

  final Note note;

  /// 부를 때마다 지금의 토큰으로 만든 문. 로그인이 바뀌어도 따라간다.
  final GymLink Function() link;

  /// 세션 상태나 상대 기록이 바뀌어 저장해야 할 때.
  final VoidCallback onChanged;
  final Duration interval;

  PartnerSession? get session => note.partner;
  bool busy = false;
  PartnerError? error;

  /// 마지막 요청이 서버에 닿았는가. 닿지 않으면 "연결 복구 중" 이다 — 세션이
  /// 끝난 것이 아니고, 내 기록은 계속 이 기기에 저장된다.
  bool reachable = true;

  /// 서버 시계. 같이 하는 타이머가 두 폰에서 같은 순간을 가리키려면 필요하다.
  final ServerClock clock;

  /// 내가 방금 그만뒀거나 다시 들어갔는데 서버의 답이 아직 옛것일 수 있다.
  /// 그 사이에 옛 상태를 믿으면 멈춘 타이머가 다시 울린다. 서버가 같은 말을
  /// 할 때까지 내 쪽 사실을 덮어 쓴다.
  ({int seq, ({int ms, int beat})? left})? _myTimerMove;

  Timer? _poll, _debounce;
  int _generation = 0;
  bool _disposed = false;
  bool _pushing = false;

  void _apply(Map<String, Object?> body) {
    final old = session;
    final state =
        PartnerState.values.asNameMap()[body['state']] ?? PartnerState.ended;
    final record = body['partnerRecord'];
    final next = PartnerSession(
      id: body['id'] as String,
      host: body['role'] == 'host',
      state: state,
      code: body['code'] as String?,
      token: body['token'] as String?,
      expiresAt: DateTime.tryParse('${body['expiresAt']}'),
      partnerName: body['partner'] as String? ?? old?.partnerName,
      endedByMe: body['endedByMe'] as bool?,
      // 내 번호는 이 기기가 센다. 서버가 더 크면(다른 기기에서 올렸다) 따라간다.
      revision: [
        old?.id == body['id'] ? old!.revision : 0,
        (body['myRevision'] as num?)?.toInt() ?? 0,
      ].reduce((a, b) => a > b ? a : b),
      // 밀린 것이 없으면 서버의 번호가 곧 내 기준이다(다른 기기가 올렸을 수 있다).
      pushed: old?.id == body['id'] && old!.revision > old.pushed
          ? old.pushed
          : (body['myRevision'] as num?)?.toInt() ?? 0,
      partnerBlocks: old?.partnerBlocks,
      partnerUpdatedAt: old?.partnerUpdatedAt,
      partnerLoaded: old?.id == body['id'] && old!.partnerLoaded,
    );
    if (record is Map) {
      next
        ..partnerBlocks = blocksFromJson(record['result'])
        ..partnerUpdatedAt = DateTime.tryParse('${record['updatedAt']}')
        ..partnerLoaded = true;
    } else if (state == PartnerState.active &&
        body.containsKey('partnerRecord')) {
      // 상대가 아직 아무것도 올리지 않았다 — "없음" 이 확인된 것이다.
      next.partnerLoaded = true;
    }
    var timer = SharedTimer.tryFromJson(body['timer']);
    final move = _myTimerMove;
    if (move != null) {
      if (timer == null ||
          timer.seq != move.seq ||
          (timer.myLeft == null) == (move.left == null)) {
        _myTimerMove = null;
      } else {
        timer = timer.copyWith(myLeft: move.left);
      }
    }
    next.timer = timer;
    if (old?.id == next.id) {
      next
        ..docBase = old!.docBase
        ..docBaseVersion = old.docBaseVersion;
    }
    final docJson = body['doc'];
    if (docJson is Map &&
        docJson['version'] is int &&
        docJson['blocks'] is List) {
      next.doc = [
        for (final b in docJson['blocks'] as List)
          if (b is Map) b.cast<String, Object?>(),
      ];
      next.docVersion = docJson['version'] as int;
    } else {
      next.doc = null;
    }
    next.me = body['me'] is String ? body['me'] as String : null;
    next.presence = [
      for (final p in (body['presence'] as List? ?? const []))
        if (p is Map && p['key'] is String && p['name'] is String)
          PartnerPresence(
            key: p['key'] as String,
            name: p['name'] as String,
            block: p['block'] is String ? p['block'] as String : null,
            set: p['set'] is String ? p['set'] as String : null,
            text: p['text'] is String ? p['text'] as String : '',
          ),
    ];
    final members = body['members'];
    if (members is List) {
      next
        ..others = [
          for (final m in members)
            if (m is Map && m['key'] is String && m['name'] is String)
              PartnerPerson(
                key: m['key'] as String,
                name: m['name'] as String,
                blocks: blocksFromJson((m['record'] as Map?)?['result']),
                updatedAt: DateTime.tryParse(
                  '${(m['record'] as Map?)?['updatedAt']}',
                ),
              ),
        ]
        ..room = (body['room'] as num?)?.toInt() ?? 0;
      // 화면의 "○○ 님과 함께" 는 모두의 이름이다.
      if (next.others.length > 1) {
        next.partnerName = next.others.map((p) => p.name).join(', ');
      }
    }
    final offered = body['handoff'];
    if (offered is Map && offered['token'] is String) {
      next.handoff = (
        token: offered['token'] as String,
        revision: (offered['revision'] as num?)?.toInt() ?? 1,
        from: offered['from'] as String? ?? next.partnerName ?? '',
      );
    }
    if (!next.open) {
      // 끝난 뒤에는 상대 기록을 들고 있지 않는다. 내 운동은 문서에 그대로다.
      next
        ..partnerBlocks = []
        ..partnerLoaded = false;
    }
    note.partner = next;
    _receiveDoc(next);
  }

  /// [undo]: 취소된 뒤에 늦게 온 성공을 되돌릴 것인가. 초대·참여에만 켠다 —
  /// 조용히 도는 상태 확인이 취소에 걸렸다고 멀쩡한 세션을 끝내면 안 된다.
  Future<PartnerError?> _run(
    Future<PartnerReply> Function(GymLink) call, {
    bool quiet = false,
    bool undo = false,
  }) async {
    final generation = _generation;
    if (!quiet) {
      busy = true;
      error = null;
      notifyListeners();
    }
    final sent = clock.monotonic;
    final reply = await call(link());
    final serverNow = reply.body?['now'];
    if (serverNow is num) {
      clock.sample(sent, clock.monotonic, serverNow.toInt());
    }
    if (_disposed) return reply.error;
    if (generation != _generation) {
      // 그사이 **사람이 취소했다**(창을 닫은 것은 취소가 아니다). 늦게 온 성공으로
      // 다시 연결되면 안 된다. 다만 되돌리는 것은 **이 요청이 만든 것**뿐이다 —
      // 서버가 created/claimed 로 알려 준다. 다른 요청이 이미 확정한 참여나
      // 원래 있던 세션은 건드리지 않는다.
      final id = reply.body?['id'];
      final mine =
          reply.body?['claimed'] == true || reply.body?['created'] == true;
      if (undo && reply.error == null && id is String && mine) {
        unawaited(link().endPartnerSession(id));
      }
      return reply.error;
    }
    reachable = reply.error != PartnerError.network;
    if (reply.error == null) {
      _apply(reply.body!);
      onChanged();
    } else if (reply.error == PartnerError.ended && session != null && quiet) {
      // 세션이 서버에서 사라졌거나 권한이 풀렸다.
      session!
        ..state = PartnerState.ended
        ..partnerBlocks = []
        ..partnerLoaded = false;
      onChanged();
    }
    if (!quiet) {
      busy = false;
      error = reply.error;
    }
    notifyListeners();
    return reply.error;
  }

  /// 초대를 연다. 서버에 없는 로컬 운동이어도 된다 — 세션은 문서의 id 로 맺는다.
  Future<PartnerError?> invite({bool renew = false}) =>
      _run((l) => l.openPartnerSession(note.id, renew: renew), undo: true);

  /// 코드로 참여한다. 모양이 틀리면 서버에 묻지 않는다.
  Future<PartnerError?> joinWithCode(String typed) {
    final code = normalizePartnerCode(typed);
    if (code == null) {
      error = PartnerError.invalidFormat;
      notifyListeners();
      return Future.value(error);
    }
    return _run((l) => l.joinPartnerSession(note.id, code: code), undo: true);
  }

  String? _lastToken;

  /// NFC·근접 통신으로 받은 토큰. 같은 토큰이 여러 번 들어와도(두 번 댔다,
  /// 콜백이 겹쳤다) 요청은 한 번이다.
  Future<PartnerError?> joinWithToken(String token) {
    if (token == _lastToken && (busy || (session?.open ?? false))) {
      return Future.value(null);
    }
    _lastToken = token;
    return _run((l) => l.joinPartnerSession(note.id, token: token), undo: true);
  }

  /// 진행 중인 초대·참여를 **그만둔다**. 늦게 오는 답은 무시되고, 그 요청이 만든
  /// 것이 있으면 되돌린다. 창을 닫는 것과는 다르다 — 창은 닫혀도 요청은 끝까지
  /// 가고 결과는 문서 위의 상태 줄에 나타난다.
  void cancel() {
    _generation++;
    busy = false;
    error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    final id = session?.id;
    if (id == null || !session!.open) return;
    await _run((l) => l.partnerSessionState(id), quiet: true);
    if (session?.state == PartnerState.active) await _push();
  }

  /// 내 기록이 바뀌었다. 번호를 올려 **먼저 저장**하고, 조금 모아서 보낸다.
  void recordChanged() {
    final s = session;
    if (s == null || !s.open) return;
    pushDoc();
    s.revision++;
    onChanged();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _push);
  }

  Future<void> _push() async {
    final s = session;
    if (s == null ||
        s.state != PartnerState.active ||
        s.pushed >= s.revision ||
        conflict != null ||
        _pushing ||
        _disposed) {
      return;
    }
    _pushing = true;
    final sending = s.revision;
    final reply = await link().savePartnerRecord(
      s.id,
      sending,
      mineOnly(note.blocks),
      base: s.pushed,
    );
    _pushing = false;
    if (_disposed || session?.id != s.id) return;
    reachable = reply.error != PartnerError.network;
    if (reply.error == null) {
      s.pushed = sending;
      conflict = null;
      onChanged();
    } else if (reply.body?['error'] == 'conflict') {
      // 같은 계정의 다른 기기가 그사이 더 새 기록을 공유했다. 이 기기가 오프라인
      // 이었다고 그것을 덮으면 안 된다. 내 문서는 그대로 두고(지우지도 바꾸지도
      // 않는다) 공유만 멈춘 채 사람에게 묻는다.
      conflict = (
        revision: (reply.body!['revision'] as num?)?.toInt() ?? 0,
        blocks: blocksFromJson(reply.body!['result']),
      );
    }
    notifyListeners();
  }

  /// 다른 기기가 공유한 더 새 기록. 있으면 이 기기의 변경은 올라가지 않고 있다.
  ({int revision, List<ExerciseBlock> blocks})? conflict;

  /// 이 기기의 기록으로 공유를 덮는다 — 사람이 골랐을 때만.
  Future<void> shareThisDevice() async {
    final s = session, c = conflict;
    if (s == null || c == null) return;
    s.revision = (s.revision > c.revision ? s.revision : c.revision) + 1;
    final reply = await link().savePartnerRecord(
      s.id,
      s.revision,
      mineOnly(note.blocks),
      base: c.revision,
      force: true,
    );
    if (reply.error == null) {
      s.pushed = s.revision;
      conflict = null;
      onChanged();
    }
    notifyListeners();
  }

  Future<void> _timerAction(Map<String, Object?> action) async {
    final s = session;
    if (s == null || s.state != PartnerState.active) return;
    await _run((l) => l.partnerTimer(s.id, action), quiet: true);
  }

  /// 같이 하자고 제안한다. 상대가 받아들여야 시작한다.
  Future<void> proposeTimer(
    String title,
    TimingSpec spec, {
    bool alternate = false,
  }) => _timerAction({
    'action': 'propose',
    'title': title,
    'alternate': alternate,
    'spec': {
      'bpm': spec.bpm,
      'tabata': spec.tabata,
      'work': spec.work,
      'rest': spec.rest,
      'rounds': spec.rounds,
    },
  });

  Future<void> acceptTimer() =>
      _timerAction({'action': 'accept', 'seq': session?.timer?.seq});

  /// 제안을 거두거나, 돌아가는 것을 둘 다에게서 치운다.
  Future<void> clearTimer() =>
      _timerAction({'action': 'clear', 'seq': session?.timer?.seq});

  /// 나만 그만둔다. 상대의 타이머는 계속 간다.
  Future<void> leaveTimer(Duration at, int beat) => _moveInTimer((
    ms: at.inMilliseconds < 0 ? 0 : at.inMilliseconds,
    beat: beat,
  ));

  /// 아직 돌고 있는 타이머에 다시 들어간다.
  Future<void> rejoinTimer() => _moveInTimer(null);

  Future<void> _moveInTimer(({int ms, int beat})? left) {
    final t = session?.timer;
    if (t == null) return Future.value();
    // 내 폰은 서버의 답을 기다리지 않는다 — 누른 순간 멈추고, 누른 순간 돌아온다.
    _myTimerMove = (seq: t.seq, left: left);
    session!.timer = t.copyWith(myLeft: left);
    notifyListeners();
    return _timerAction({
      'action': left == null ? 'rejoin' : 'leave',
      'seq': t.seq,
      'ms': ?left?.ms,
      'beat': ?left?.beat,
    });
  }

  // ── 같이 고치기 ─────────────────────────────────────────────────

  /// 내가 믿는 문서 = 서버가 마지막으로 준 문서([PartnerSession.docBase]) 위에
  /// 아직 닿지 않은 내 수정. 편집기는 늘 이것을 보여 준다.
  List<Json>? _shadow;
  final _pendingDoc = <List<Json>>[];
  int _ackedDoc = 0;
  bool _sendingDoc = false, _docFresh = false, _initing = false;
  DateTime? _initFailedAt;

  /// 서버 문서가 새로 왔으면 편집기에 놓을 운동들. 한 번만 내준다.
  List<ExerciseBlock>? takeDoc() {
    final s = session;
    if (!_docFresh || s == null || _shadow == null) return null;
    _docFresh = false;
    return blocksOfDoc(_shadow!, s.me);
  }

  void _receiveDoc(PartnerSession s) {
    if (s.state != PartnerState.active) {
      _shadow = null;
      _pendingDoc.clear();
      _ackedDoc = 0;
      if (s.state != PartnerState.waiting) s.docBase = null;
      return;
    }
    // 화면을 다시 열었거나 앱을 다시 켰다. 마지막으로 받은 문서와 내 기록의 차이가
    // 곧 아직 못 올린 내 수정이다(오프라인에서 적은 세트 포함) — 그것을 다시 싣는다.
    // "처음 참여" 로 합치면 그사이 남이 지운 운동이 되살아난다.
    if (_shadow == null && s.docBase != null) {
      _shadow = s.docBase;
      _queueDoc(docOf(note.blocks));
    }
    final doc = s.doc;
    if (doc == null) {
      // 아직 안 심었다. 심는 것은 호스트다 — 둘이 동시에 심으면 누구 목록이
      // 앞에 올지 운에 맡기게 된다. 들어온 사람의 운동은 받은 뒤에 합쳐진다.
      if (_shadow == null && s.host) unawaited(_initDoc());
      return;
    }
    // 이미 본 것, 그리고 내 수정이 들어간 버전보다 옛 소식은 버린다.
    if (s.docVersion <= s.docBaseVersion || s.docVersion < _ackedDoc) {
      if (_shadow != null) return;
    }
    final first = _shadow == null;
    s
      ..docBase = doc
      ..docBaseVersion = s.docVersion;
    _shadow = _pendingDoc.fold<List<Json>>(doc, applyDoc);
    if (first) _queueDoc(_joined(doc, docOf(note.blocks)));
    _docFresh = true;
    onChanged();
  }

  /// 처음 참여할 때: 서버 문서에 이 기기의 기록을 합친 것. 같은 운동이면 내 수정이
  /// 이기고(세트는 둘 다 남는다), 문서에 없는 운동은 뒤에 붙는다. 지운 것은 싣지
  /// 않는다 — 남이 더한 것을 지우게 될 수 있다.
  static List<Json> _joined(List<Json> doc, List<Json> local) {
    final mine = {for (final b in local) b['id']: b};
    List<Object?> sets(Json b) => b['sets'] as List;
    return [
      for (final b in doc)
        if (mine[b['id']] case final m?)
          {
            ...m,
            'sets': [
              for (final s in sets(b))
                sets(m).firstWhere(
                      (x) => (x as Map)['id'] == (s as Map)['id'],
                      orElse: () => null,
                    ) ??
                    s,
              for (final x in sets(m))
                if (!sets(b).any((s) => (s as Map)['id'] == (x as Map)['id']))
                  x,
            ],
          }
        else
          b,
      for (final m in local)
        if (!doc.any((b) => b['id'] == m['id'])) m,
    ];
  }

  Future<void> _initDoc() async {
    final s = session;
    final failed = _initFailedAt;
    if (s == null || s.state != PartnerState.active || _initing) return;
    // 실패했으면 소식마다(초당 몇 번) 전체 기록을 다시 보내지 않는다.
    if (failed != null && DateTime.now().difference(failed).inSeconds < 10) {
      return;
    }
    _initing = true;
    final snapshot = docOf(note.blocks);
    final reply = await link().partnerDoc(s.id, {
      'action': 'init',
      'blocks': snapshot,
    });
    _initing = false;
    if (reply.error != null) {
      _initFailedAt = DateTime.now();
      return;
    }
    // 심은 것이 곧 내가 믿는 문서다. 첫 문서가 오기 전에 적은 세트도 이제 올라간다.
    if (_shadow == null && session?.id == s.id) {
      _shadow = snapshot;
      s.docBase = snapshot;
      _queueDoc(docOf(note.blocks));
    }
  }

  /// 편집기의 문서가 바뀌었다. 내가 믿는 문서와의 차이만 보낸다.
  void pushDoc() {
    if (_shadow == null || session?.state != PartnerState.active) return;
    _queueDoc(docOf(note.blocks));
  }

  void _queueDoc(List<Json> next) {
    final batches = diffDoc(_shadow!, next);
    if (batches.isEmpty) return;
    for (final ops in batches) {
      _shadow = applyDoc(_shadow!, ops);
      _pendingDoc.add(ops);
    }
    unawaited(_flushDoc());
  }

  /// 차례대로 보낸다. 닿지 못했거나 서버가 잠시 못 받으면 멈췄다가 다음 폴링에서
  /// 잇는다 — 같은 수정을 두 번 얹어도 결과가 같아서 다시 보내도 안전하다.
  /// 모양이 틀렸거나 너무 크다는 것만 버린다(다시 보내도 안 받는다). 버리면 내가
  /// 믿는 문서를 서버 문서에서 다시 세워 편집기가 그것을 따르게 한다.
  Future<void> _flushDoc() async {
    final s = session;
    if (_sendingDoc || s == null) return;
    _sendingDoc = true;
    while (_pendingDoc.isNotEmpty && !_disposed && session?.id == s.id) {
      final batch = _pendingDoc.first;
      final reply = await link().partnerDoc(s.id, {
        'action': 'edit',
        'ops': batch,
      });
      final refused = const {
        'invalidInput',
        'tooBig',
      }.contains(reply.body?['error']);
      if (reply.error != null && !refused) break;
      reachable = true;
      final v = reply.body?['version'];
      if (v is int && v > _ackedDoc) _ackedDoc = v;
      _pendingDoc.remove(batch);
      final base = s.docBase;
      if (refused && base != null) {
        _shadow = _pendingDoc.fold<List<Json>>(base, applyDoc);
        _docFresh = true;
        notifyListeners();
      }
    }
    _sendingDoc = false;
  }

  Timer? _presenceTimer;
  Map<String, Object?>? _presencePending, _presenceSent;
  DateTime _presenceAt = DateTime(0);

  /// 내가 어디를 만지는지. 자주 부르니 모아서, 같은 것은 다시 보내지 않는다.
  /// 가만히 있어도 [_heartbeat] 가 몇 초마다 다시 알린다 — 서버는 20초 지난
  /// 자리를 지운다(앱을 내린 사람의 커서가 남지 않게).
  void presence({String? block, String? set, String text = ''}) {
    final s = session;
    if (s == null || s.state != PartnerState.active) return;
    _presencePending = {'block': block, 'set': set, 'text': text};
    _presenceTimer ??= Timer(const Duration(milliseconds: 150), () {
      _presenceTimer = null;
      final where = _presencePending;
      if (where == null || mapEquals(where, _presenceSent)) return;
      _sendPresence(where);
    });
  }

  void _sendPresence(Map<String, Object?> where) {
    final s = session;
    if (s == null || s.state != PartnerState.active) return;
    _presenceSent = where;
    _presenceAt = DateTime.now();
    unawaited(link().partnerPresence(s.id, where));
  }

  void _heartbeat() {
    final where = _presenceSent;
    if (where != null &&
        where['block'] != null &&
        DateTime.now().difference(_presenceAt).inSeconds >= 8) {
      _sendPresence(where);
    }
  }

  StreamSubscription<Map<String, Object?>>? _events;
  Timer? _reconnect;

  /// 스트림이 실제로 소식을 주고 있는가.
  bool _streaming = false;

  /// 서버가 밀어 주는 상태를 듣는다. 끊기면 1초 뒤 다시 연다. 폴링은 남겨 두되
  /// 듣는 동안은 드물게 한다 — 스트림이 놓친 것을 줍는 보험이다.
  void _listen() {
    final s = session;
    if (_events != null || _disposed || s == null || !s.open) return;
    final id = s.id;
    _events = link().partnerEvents(id).listen((body) {
      if (_disposed || session?.id != id) return;
      _streaming = true;
      reachable = true;
      _apply(body);
      onChanged();
      notifyListeners();
    }, onDone: _reopen);
  }

  /// 끊겼다. 잘 흐르던 것이면 곧 다시, 처음부터 안 흐르던 것(옛 서버, 막힌
  /// 그물)이면 느긋하게 — 그동안은 폴링이 제 속도로 돈다.
  void _reopen() {
    final was = _streaming;
    _events = null;
    _streaming = false;
    if (_disposed || _poll == null) return;
    _reconnect?.cancel();
    _reconnect = Timer(Duration(seconds: was ? 1 : 15), _listen);
  }

  /// 같이 하기를 끝낸다. 내 운동은 남는다. 그물이 없어도 이 기기에서는 끝난
  /// 것으로 하고 공유를 멈춘다 — 서버에는 다음에 닿을 때 끝났다고 알린다.
  Future<void> end() async {
    final s = session;
    if (s == null) return;
    _generation++;
    final error = await _run((l) => l.endPartnerSession(s.id));
    if (error != null && session != null) {
      session!
        ..state = PartnerState.ended
        ..endedByMe = true
        ..partnerBlocks = []
        ..partnerLoaded = false;
      _pendingEnd = s.id;
      onChanged();
      notifyListeners();
    }
  }

  String? _pendingEnd;

  /// 화면이 보이는 동안만 돈다. 백그라운드에서 연결을 유지한다고 하지 않는다.
  void start() {
    if (_disposed) return;
    // 이미 돌고 있어도 스트림은 연다 — 세션이 없을 때 시작했다가 초대·참여한
    // 경우다(그때는 열 세션이 없어 듣지 못했다).
    if (_poll != null) return _listen();
    unawaited(refresh());
    _listen();
    var ticks = 0;
    _poll = Timer.periodic(interval, (_) async {
      final pending = _pendingEnd;
      if (pending != null) {
        final reply = await link().endPartnerSession(pending);
        if (reply.error != PartnerError.network) _pendingEnd = null;
      }
      if (_pendingDoc.isNotEmpty) unawaited(_flushDoc());
      _heartbeat();
      // 스트림이 살아 있으면 폴링은 열 번에 한 번만.
      if (!_streaming || ++ticks % 10 == 0) await refresh();
    });
  }

  void stop() {
    // 화면을 떠나거나 앱을 내렸다. 내 커서를 거둔다 — 남아 있으면 20초 동안 남의
    // 손을 막는다.
    if (_presenceSent?['block'] != null) {
      _sendPresence(const {'block': null, 'set': null, 'text': ''});
    }
    _poll?.cancel();
    _poll = null;
    _events?.cancel();
    _events = null;
    _streaming = false;
    _reconnect?.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    _debounce?.cancel();
    _presenceTimer?.cancel();
    super.dispose();
  }
}
