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

import 'editor.dart';
import 'gym.dart';
import 'notes.dart';

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
    );
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
  });

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
    if (!next.open) {
      // 끝난 뒤에는 상대 기록을 들고 있지 않는다. 내 운동은 문서에 그대로다.
      next
        ..partnerBlocks = []
        ..partnerLoaded = false;
    }
    note.partner = next;
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
    final reply = await call(link());
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
      note.blocks,
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
      note.blocks,
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
    if (_poll != null || _disposed) return;
    unawaited(refresh());
    _poll = Timer.periodic(interval, (_) async {
      final pending = _pendingEnd;
      if (pending != null) {
        final reply = await link().endPartnerSession(pending);
        if (reply.error != PartnerError.network) _pendingEnd = null;
      }
      await refresh();
    });
  }

  void stop() {
    _poll?.cancel();
    _poll = null;
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    _debounce?.cancel();
    super.dispose();
  }
}
