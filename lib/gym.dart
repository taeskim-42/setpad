import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import 'api_route.dart';

import 'editor.dart';
import 'l10n/generated/app_localizations.dart';
import 'live_doc.dart';
import 'meal.dart' show amountText;
import 'notes.dart';
import 'partner.dart';
import 'record_ai.dart';
import 'units.dart';

/// 내가 다니는 체육관 하나와, 도장이 내게 알리는 것(GET /api/gyms, 계약 C5) — 공지,
/// 이용권, 락커, 앞으로의 PT. **앱만 쓰는 회원에게는 이것이 도장 소식의 전부다** —
/// 스티커 주소는 앱이 가로채므로 웹의 회원 화면에 닿지 못한다.
class Gym {
  const Gym({
    required this.id,
    required this.name,
    this.trainer,
    this.trainerId,
    this.notices = const [],
    this.membership,
    this.pt,
    this.locker,
    this.bookings = const [],
  });

  /// 못 읽은 공지·예약 한 줄은 버린다 — 그 한 줄 때문에 도장을 잃지 않게.
  factory Gym.fromJson(Map m) {
    final access = m['access'] is Map ? m['access'] as Map : const {};
    GymPass? pass(Object? p) => p is Map
        ? tryRead(
            () => (
              name: '${p['name'] ?? ''}',
              endsOn: DateTime.tryParse('${p['endsOn']}'),
              paused: p['paused'] == true,
              remaining: p['remaining'] as int?,
            ),
          )
        : null;
    final locker = m['locker'];
    return Gym(
      id: m['id'] as String,
      name: m['name'] as String,
      trainer: m['trainer'] as String?,
      trainerId: m['trainerId'] as String?,
      notices: eachRow(
        m['notices'],
        (n) => (
          id: n['id'] as String,
          title: n['title'] as String,
          body: n['body'] as String? ?? '',
          pinned: n['pinned'] == true,
          createdAt: DateTime.parse(n['createdAt'] as String).toLocal(),
        ),
      ),
      membership: pass(access['membership']),
      pt: pass(access['pt']),
      locker: locker is Map && locker['label'] is String
          ? (
              label: locker['label'] as String,
              endsOn: DateTime.tryParse('${locker['endsOn']}'),
            )
          : null,
      bookings: eachRow(
        m['bookings'],
        (b) => (
          id: b['id'] as String,
          startsAt: DateTime.parse(b['startsAt'] as String).toLocal(),
          trainer: b['trainer'] as String? ?? '',
          trainerId: b['trainerId'] as String?,
          status: b['status'] as String,
        ),
      ),
    );
  }

  final String id, name;
  final String? trainer, trainerId;

  /// 최근 공지 다섯, 고정한 것이 먼저.
  final List<GymNotice> notices;

  /// 지금 쓰거나 곧 쓸 회원권·PT 이용권(정지한 것도). 없으면 null.
  final GymPass? membership, pt;
  final ({String label, DateTime? endsOn})? locker;

  /// 앞으로의 PT, 시각 순. 트레이너가 거절·취소한 것도 온다 — 원격 푸시가 없어서
  /// 앱이 지난번 본 것과 견줘 무엇이 바뀌었는지 말한다([gymNews]).
  final List<GymBooking> bookings;
}

typedef GymNotice = ({
  String id,
  String title,
  String body,
  bool pinned,
  DateTime createdAt,
});

/// 이용권 하나. [remaining] 은 PT 의 남은 횟수이고 null 이면 무제한이다(회원권은 늘 null).
typedef GymPass = ({
  String name,
  DateTime? endsOn,
  bool paused,
  int? remaining,
});

/// 앞으로의 PT 하나. `status` 는 pending·booked·rejected·cancelled. [trainerId] 는 맡은
/// 트레이너 — 닉네임은 바뀌므로 담당 변경은 이것으로 견준다. 옛 서버는 주지 않는다.
typedef GymBooking = ({
  String id,
  DateTime startsAt,
  String trainer,
  String? trainerId,
  String status,
});

/// 도장이 보낸 초대. **회원이 받아야 회원이 된다** — 닉네임만 알면 아무나 회원으로
/// 넣고 루틴을 밀어 넣을 수 있던 길을 서버가 초대로 바꿨다. [verified] 가 false 면 아직
/// 확인하지 않은 도장이다 — 누구나 도장을 만들 수 있으니 받기 전에 그렇다고 보인다.
typedef GymInvite = ({
  String gymId,
  String gymName,
  String? invitedBy,
  bool verified,
});

/// 도장에 등록하기 전에 보여 주는 안내의 판(번역 키 gymConsentNotice). 서버의
/// GYM_CONSENT_VERSION 과 같아야 하고, 문구나 처리방침이 바뀌면 함께 올린다 — 신청과
/// 초대 수락이 이 판을 동의로 남긴다.
const gymConsentVersion = '2026-10-13';

/// 목록의 줄마다 읽고, 못 읽은 줄은 버린다 — 한 줄 때문에 전체가 안 보이는 것보다 낫다.
List<T> eachRow<T>(Object? list, T? Function(Map m) read) => [
  for (final m in list is List ? list : const [])
    if (m is Map) ?tryRead(() => read(m)),
];

T? tryRead<T>(T? Function() read) {
  try {
    return read();
  } catch (_) {
    return null;
  }
}

/// 회원이 본 도장 소식 — 열쇠마다 그때의 모양: 공지는 본 적이 있는지, 예약은 상태·시각·
/// 맡은 트레이너(id), 담당 트레이너는 누구인지(id).
///
/// **원격 푸시가 없다.** 트레이너가 PT 를 거절·취소하거나 시간을 옮겨도 앱만 쓰는 회원의
/// 폰에는 아무것도 뜨지 않았다. 그래서 앱을 열 때 지난번 본 것과 견준다([gymNews]).
Map<String, String> gymSeenOf(Gym gym) => {
  for (final n in gym.notices) 'n:${n.id}': '',
  for (final b in gym.bookings)
    'b:${b.id}': bookingSeen(b.status, b.startsAt, b.trainerId),
  't:${gym.id}': ?gym.trainerId,
};

/// 예약 하나의 모양. 예약 화면(/api/bookings)과 도장 목록(/api/gyms)이 같은 줄을 만든다.
/// 맡은 트레이너는 닉네임이 아니라 id 다 — 이름만 바꾼 것은 담당 변경이 아니다.
String bookingSeen(String status, DateTime startsAt, String? trainerId) =>
    '$status|${startsAt.toUtc().toIso8601String()}|${trainerId ?? ''}';

/// 도장에서 생긴 일. 앞의 것일수록 회원이 먼저 알아야 한다.
enum GymChange { rejected, cancelled, moved, trainer, booked, assigned, notice }

typedef GymNews = ({
  String key,
  GymChange change,
  GymNotice? notice,
  GymBooking? booking,
});

/// [seen] 에 견줘 이 도장에서 새로 생긴 일, 무거운 것부터.
///
/// 처음 보는 예약은 확정·거절만 소식이다 — 승인 대기는 회원이 낸 신청이고, 취소는 대개
/// 회원이 한 것이다. 앱에서 한 신청·취소는 예약 화면이 본 것으로 적는다.
List<GymNews> gymNews(Gym gym, Map<String, String> seen) {
  final all = <GymNews>[
    for (final n in gym.notices)
      if (!seen.containsKey('n:${n.id}'))
        (key: 'n:${n.id}', change: GymChange.notice, notice: n, booking: null),
    for (final b in gym.bookings)
      if (_bookingChange(seen['b:${b.id}'], b) case final change?)
        (key: 'b:${b.id}', change: change, notice: null, booking: b),
    if ((seen['t:${gym.id}'], gym.trainerId) case (
      final was?,
      final now?,
    ) when was != now)
      (
        key: 't:${gym.id}',
        change: GymChange.assigned,
        notice: null,
        booking: null,
      ),
  ];
  return [
    for (final kind in GymChange.values) ...all.where((n) => n.change == kind),
  ];
}

GymChange? _bookingChange(String? seen, GymBooking b) {
  if (seen == bookingSeen(b.status, b.startsAt, b.trainerId)) return null;
  final status = switch (b.status) {
    'booked' => GymChange.booked,
    'rejected' => GymChange.rejected,
    'cancelled' => GymChange.cancelled,
    _ => null,
  };
  final was = seen?.split('|');
  if (was == null || was.length < 2) {
    return status == GymChange.cancelled ? null : status;
  }
  if (was[0] != b.status) return status;
  if (was[1] != b.startsAt.toUtc().toIso8601String()) return GymChange.moved;
  // 맡은 트레이너(대강)는 앞뒤 id 를 다 알 때만 견준다 — 옛 서버의 예약이나 담당이 탈퇴한
  // 예약은 소식이 아니다.
  final before = was.length > 2 ? was[2] : '', now = b.trainerId;
  return before.isNotEmpty && now != null && before != now
      ? GymChange.trainer
      : null;
}

/// 트레이너가 내려준 루틴 하나.
///
/// **날짜가 없다.** 다음에 나오는 날이 그날이고, 내려준 순서가 곧 차례다 —
/// 트레이너가 웹에서 쓰는 규칙 그대로다.
typedef Routine = ({
  String id,
  String gymId,
  String gym,
  String title,
  List<ExerciseBlock> blocks,
});

/// 체육관에서 온 것들. 로그인하지 않았거나 어디에도 안 다니면 전부 비어 있다.
class GymLink {
  const GymLink({
    required this.endpoint,
    this.token,
    this.userId,
    this.client,
    this.onUnauthorized,
  });
  final String endpoint;
  final String? token;

  /// 토큰의 주인(서버의 user id). 밀린 것을 보낼 때 남의 기록을 이 토큰으로
  /// 보내지 않으려고 든다([Note.owner]). 아직 모르면 null.
  final String? userId;
  final http.Client? client;

  /// 서버가 이 토큰을 거절했다(401). 한 곳(Account)이 정말 죽었는지 확인한다 — 길마다
  /// 따로 다루면 어떤 길은 로그아웃하고 어떤 길은 '다니는 곳 없음' 으로 보이며
  /// 2초마다 계속 묻는다.
  final void Function()? onUnauthorized;

  bool get supported => token != null;

  /// 그물을 빌려 쓴다(앱이 함께 쓰는 것이라 닫지 않는다). 확장도 같은 것을 쓴다.
  Future<T> withClient<T>(Future<T> Function(http.Client web) run) {
    final web = client ?? apiClient;
    final watch = onUnauthorized;
    return run(watch == null ? web : _Unauthorized(web, watch));
  }

  Map<String, String> get headers => {'authorization': 'Bearer $token'};

  /// 다니는 체육관과 아직 답하지 않은 도장 초대. **못 물어본 것은 null 이다** — 빈
  /// 목록과 다르다. 빈 목록으로 돌려주면 신호가 약하거나 토큰이 거절된 순간 다니는
  /// 곳이 없는 사람처럼 보인다.
  Future<({List<Gym> gyms, List<GymInvite> invites})?> gyms() async {
    if (!supported) return (gyms: const <Gym>[], invites: const <GymInvite>[]);
    return withClient((web) async {
      try {
        final response = await web
            .get(Uri.parse('$endpoint/api/gyms'), headers: headers)
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) return null;
        final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
        return (
          gyms: eachRow(body['gyms'], Gym.fromJson),
          invites: eachRow(
            body['invites'],
            (i) => (
              gymId: i['gymId'] as String,
              gymName: i['gymName'] as String,
              invitedBy: i['invitedBy'] as String?,
              // A server without the key predates the check — say nothing rather than alarm.
              verified: i['verified'] != false,
            ),
          ),
        );
      } catch (_) {
        return null;
      }
    });
  }

  /// 받은 루틴. **못 물어본 것은 null 이다** — 빈 목록과 다르다. 빈 목록으로
  /// 돌려주면 스티커를 댄 사람이 신호가 약한 날 '루틴 없음'으로 빈 출석이 되고,
  /// 목록 화면은 있던 루틴을 지운다.
  ///
  /// [gymId] 를 주면 그 체육관 것만 묻는다. 서버 목록은 모든 체육관을 합쳐 앞에서
  /// 자르므로, 안 주면 다른 체육관 루틴에 밀려 스티커를 댄 곳의 루틴이 빠질 수
  /// 있다. 옛 서버는 이 조건을 모르고 전부 준다 — 고르는 일은 부르는 쪽이 계속 한다.
  Future<List<Routine>?> routines({String? gymId}) async {
    if (!supported) return const [];
    return withClient((web) async {
      try {
        final url = Uri.parse('$endpoint/api/routines');
        final response = await web
            .get(
              gymId == null
                  ? url
                  : url.replace(queryParameters: {'gymId': gymId}),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) return null;
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return [
          for (final row in (body as Map)['routines'] as List? ?? const [])
            (
              id: row['id'] as String,
              gymId: row['gym_id'] as String,
              gym: row['gym'] as String,
              title: row['title'] as String,
              blocks: plannedBlocks(row['items']),
            ),
        ];
      } catch (_) {
        return null;
      }
    });
  }

  /// 끝낸 운동 하나를 올린다. 성공 여부만 돌려준다 — 실패해도 기록은 기기에 있다.
  Future<bool> sendWorkout({
    required String gymId,
    required String localId,
    String? routineId,
    required DateTime startedAt,
    required List<ExerciseBlock> blocks,
    String? note,
  }) async =>
      await sendWorkoutOutcome(
        gymId: gymId,
        localId: localId,
        routineId: routineId,
        startedAt: startedAt,
        blocks: blocks,
        note: note,
      ) ==
      SendOutcome.sent;

  /// 올리되, 못 올렸으면 **왜** 못 올렸는지 가른다.
  ///
  /// 그물이 없거나 서버가 넘어졌으면 다음에 다시 보내면 되지만(retry), 서버가
  /// 이 기록 자체를 거절했으면(rejected) 백 번 다시 보내도 똑같다. 둘을 같이
  /// 취급하면 거절당한 기록 하나가 뒤의 모든 기록을 영영 막는다.
  Future<SendOutcome> sendWorkoutOutcome({
    required String gymId,
    required String localId,
    String? routineId,
    required DateTime startedAt,
    required List<ExerciseBlock> blocks,
    String? note,
  }) async {
    if (!supported) return SendOutcome.retry;
    return withClient((web) async {
      try {
        final response = await web
            .post(
              Uri.parse('$endpoint/api/workouts'),
              headers: {...headers, 'content-type': 'application/json'},
              body: jsonEncode({
                'gymId': gymId,
                'localId': localId,
                'routineId': ?routineId,
                // 오프셋 없는 로컬 시각은 서버가 한국 시각으로 읽는다 — UTC(Z)로 보내 폰의 시간대와 무관하게 한다.
                'startedAt': startedAt.toUtc().toIso8601String(),
                'result': loggedItems(blocks),
                'note': ?note,
              }),
            )
            .timeout(const Duration(seconds: 20));
        _heed(response);
        return outcomeOf(response.statusCode);
      } catch (_) {
        return SendOutcome.retry;
      }
    });
  }

  /// 사람이 지운 기록의 운동·출석 줄을 서버에서도 지운다. 올린 것과 같은 열쇠
  /// (기록 id)다. 없는 줄(404)은 지운 것과 같다.
  Future<SendOutcome> deleteWorkout(String localId) async {
    if (!supported) return SendOutcome.retry;
    return withClient((web) async {
      try {
        final response = await web
            .delete(
              Uri.parse(
                '$endpoint/api/workouts',
              ).replace(queryParameters: {'clientId': localId}),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));
        _heed(response);
        return switch (response.statusCode) {
          200 || 404 => SendOutcome.sent,
          // 405 는 이 길을 아직 모르는 서버다. 버리지 않고 다음에 다시 보낸다.
          405 => SendOutcome.retry,
          final s => outcomeOf(s),
        };
      } catch (_) {
        return SendOutcome.retry;
      }
    });
  }
}

/// 401 이면 알린다. 답은 그대로 부르는 쪽에 간다 — 기록 올리기는 401 이어도
/// 기록을 버리지 않고 다음에 다시 보낸다.
class _Unauthorized extends http.BaseClient {
  _Unauthorized(this._inner, this._onUnauthorized);
  final http.Client _inner;
  final void Function() _onUnauthorized;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (response.statusCode == 401) _onUnauthorized();
    return response;
  }
}

/// 올리기의 결과. 보냈거나, 다음에 다시 보내거나, 서버가 이 기록을 거절했거나.
enum SendOutcome { sent, retry, rejected }

/// 401: the token died. 408·429: later. 426: this build is cut off — the record is fine and the
/// updated app sends it. Only a 4xx about the record itself is final.
SendOutcome outcomeOf(int status) => switch (status) {
  200 => SendOutcome.sent,
  401 || 408 || 426 || 429 => SendOutcome.retry,
  >= 400 && < 500 => SendOutcome.rejected,
  _ => SendOutcome.retry,
};

/// The server asked uploads to wait (429·5xx Retry-After). Everything here is retried on the
/// next chance anyway, so until then we do not knock. Capped: a bad header must not stop
/// uploads for a day.
DateTime? _uploadsQuietUntil;
bool get _uploadsQuiet => _uploadsQuietUntil?.isAfter(DateTime.now()) ?? false;

void _heed(http.BaseResponse r) {
  final wait = r.statusCode == 429 || r.statusCode >= 500
      ? retryAfter(r)
      : null;
  if (wait == null) return;
  const most = Duration(minutes: 10);
  _uploadsQuietUntil = DateTime.now().add(wait > most ? most : wait);
}

@visibleForTesting
void forgetUploadPause() => _uploadsQuietUntil = null;

/// 트레이너가 적은 계획을 앱의 운동 칸으로 바꾼다.
///
/// 웹의 모양은 `[{name, sets:[{kg, reps}]}]` 이고 앱의 모양과 거의 같다.
/// 계획은 아직 해낸 것이 아니므로 세트는 전부 안 한 것으로 들어온다.
List<ExerciseBlock> plannedBlocks(Object? items) => [
  for (final item in items is List ? items : const [])
    if (item is Map && item['name'] is String)
      ExerciseBlock(item['name'] as String, [
        for (final set
            in item['sets'] is List ? item['sets'] as List : const [])
          if (set is Map)
            LoggedSet(
              value: (set['kg'] as num?)?.toDouble(),
              reps: (set['reps'] as num?)?.toInt(),
              done: false,
            ),
      ], WorkoutSetup.tryFromJson(item['setup'])),
];

/// 서버가 아는 무게는 kg 뿐이다. lb 는 바꾸고, 시간·거리는 무게가 아니므로 비운다 —
/// 틀린 kg(플랭크 60초가 60kg)보다 빈 칸이 낫다.
double? kgOf(LoggedSet set) => switch (set.unit) {
  'kg' => set.value,
  'lb' =>
    set.value == null ? null : (set.value! * 0.45359237 * 100).round() / 100,
  _ => null,
};

/// 시간·거리 세트의 값. 서버는 초(`s`)와 미터(`m`)로 받는다 — 무게는 [kgOf] 다.
/// 러닝 5km·플랭크 60초가 트레이너 화면에 빈 세트로 보이지 않게 한다.
({double value, String unit})? measureOf(LoggedSet set) {
  final value = set.value, factor = baseFactor[set.unit];
  if (value == null || !value.isFinite || factor == null) return null;
  return (
    value: ((value * factor * 100).round() / 100)
        .clamp(0, _maxValue)
        .toDouble(),
    unit: unitById[set.unit]?.kind == UnitKind.duration ? 's' : 'm',
  );
}

/// 세트에 남긴 메모를 운동 하나의 메모로 — 서버는 운동마다 메모 하나를 받는다.
/// 트레이너 화면의 세트 번호를 붙인다.
String? _noteOf(ExerciseBlock block) {
  final lines = [
    for (final (i, set) in block.sets.take(_maxSets).indexed)
      if (set.notes.map((n) => n.trim()).where((n) => n.isNotEmpty).toList()
          case final notes when notes.isNotEmpty)
        '#${i + 1}: ${notes.join(' · ')}',
  ];
  if (lines.isEmpty) return null;
  return cutUnits(lines.join('\n'), _maxNoteLength);
}

/// 서버가 받는 기록의 한도(isWorkoutResult). 하나라도 넘으면 서버는 기록 전체를
/// 400 으로 거절하고 앱은 그 기록을 다시 보내 봐야 소용이 없으므로, 보내기 전에
/// 한도 안으로 맞춘다 — 오타 하나가 그날의 출석까지 잃게 하지 않는다.
const _maxKg = 9999;
const _maxReps = 10000;
const _maxSets = 100;
const _maxExercises = 100;
const _maxNameLength = 200;
const _maxValue = 1000000;
const _maxNoteLength = 500;

/// 앱의 기록을 웹이 읽는 모양으로 바꾼다. 계획과 같은 모양에 done 이 붙는다.
List<Map<String, Object?>> loggedItems(List<ExerciseBlock> blocks) => [
  for (final block
      in blocks.where((b) => b.exercise.trim().isNotEmpty).take(_maxExercises))
    {
      'name': cutUnits(block.exercise, _maxNameLength),
      'sets': [
        for (final set in block.sets.take(_maxSets))
          {
            'kg': ?kgOf(set)?.clamp(0, _maxKg),
            if (set.reps != null) 'reps': set.reps!.clamp(0, _maxReps),
            if (measureOf(set) case (:final value, :final unit)) ...{
              'value': value,
              'unit': unit,
            },
            'done': set.done,
          },
      ],
      'note': ?_noteOf(block),
    },
];

/// 보낼 것인가. 아직 안 보냈거나, 보낸 뒤에 고쳤으면 보낸다. **루틴을 열어만 본
/// 것은 아니다** — 고친 적이 없는 루틴 기록이 올라가면 서버가 그 루틴을 '완료'로
/// 닫고 트레이너는 0/15세트를 본다.
bool needsSend(Note note) {
  if (note.gymId == null) return false;
  if (_lookedOnly(note) && !note.checkedIn) return false;
  final sent = note.sentAt;
  return sent == null || note.updatedAt.isAfter(sent);
}

/// 받은 루틴을 열어만 봤다(아무 세트도 안 적었다).
bool _lookedOnly(Note note) =>
    note.routineId != null && !note.updatedAt.isAfter(note.createdAt);

/// 아직 못 보낸 기록을 보낸다. 보낸 뒤에 고친 것도 다시 간다.
///
/// **헬스장은 신호가 나쁘다.** 한 번에 못 보내는 것이 정상이라서, 앱을 켤
/// 때마다 밀린 것을 다시 시도한다. 같은 것을 두 번 보내도 서버가 한 줄로
/// 합치므로(local_id) 겹쳐도 해가 없다. 그래서 고친 기록도 같은 줄을 덮는다 —
/// 세트 사이에 폰이 잠겨 반만 올라간 기록이 그대로 굳지 않는다.
///
/// [later] 가 참인 기록은 이번에 건너뛴다(편집 중이고 방금 올린 것 — 홈 복귀마다 다시
/// 올리지 않는다). 뒤의 기록은 계속 간다.
Future<void> sendPending(
  GymLink link,
  List<Note> notes, {
  required void Function() onSent,
  bool Function(Note note)? later,
}) async {
  if (!link.supported || _uploadsQuiet) return;
  var changed = false;
  // 오래된 것부터. 트레이너가 보는 차례가 실제 순서와 같아야 한다.
  final waiting = [
    for (final note in notes)
      // 빈 것도 보낸다 — 루틴 없이 그냥 나온 날의 출석이 그렇게 생긴다.
      if (needsSend(note) &&
          note.ownedBy(link.userId) &&
          !(later?.call(note) ?? false))
        note,
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  for (final note in waiting) {
    // 보내는 동안 고친 것은 다음에 또 가야 한다. 시각은 보내기 전에 찍는다.
    final at = DateTime.now();
    // 스티커로 열고 아직 안 적었다 — 방문만 보낸다. 루틴을 붙이면 서버가 그 루틴을
    // '완료' 로 닫는다. 적기 시작하면 같은 줄에 루틴과 세트가 붙는다(서버가 허용).
    final visitOnly = _lookedOnly(note);
    final outcome = await link.sendWorkoutOutcome(
      gymId: note.gymId!,
      localId: note.id,
      routineId: visitOnly ? null : note.routineId,
      // 스티커 전에 적던 오늘 기록이 방문이 됐으면 댄 때가 온 때다.
      startedAt: note.cameAt,
      // 같이 고친 기록에는 옆 사람의 세트도 있다. 트레이너에게는 내 것만.
      blocks: visitOnly ? const [] : mineOnly(note.blocks),
    );
    // 그물이 막혔으면 나머지도 막힌다. 다음 기회에.
    if (outcome == SendOutcome.retry) break;
    // 서버가 이 하나를 거절했다(도장이 없어졌다, 루틴이 엇갈렸다). 뒤의 것들은 상관없이
    // 계속 간다 — 이것 하나 때문에 그 뒤 몇 주치가 영영 안 올라가던 일이 있었다. 같은
    // 것을 다시 보내도 같은 답이라 보낸 것으로 치고, 기록 화면이 못 올렸다고 말한다.
    // 고치면 다시 간다(needsSend).
    note.uploadRejected = outcome == SendOutcome.rejected;
    note.sentAt = at;
    changed = true;
    if (note.uploadRejected) continue;
    // 이 계정으로 올라갔다. 다른 계정으로 바꾼 뒤 고친 것이 그 계정 앞으로 가지 않게.
    note.owner ??= link.userId;
  }
  if (changed) onSent();
}

/// 확정한 끼니를 서버의 **같은 줄**에 맞춘다.
///
/// 추정 요청은 아무것도 저장하지 않는다. 사람이 먹은 양까지 정한 끼니만 여기로
/// 올라가고, 끼니의 id 가 열쇠라서 다시 보내도 한 줄, 고치면 그 줄이 바뀌고,
/// 지우면 그 줄이 없어진다. 로그인한 도장 회원의 기록만 대상이다([Note.mealGym]).
extension MealLink on GymLink {
  Future<SendOutcome> _mealRequest(
    String method,
    String id, [
    Map<String, Object?>? body,
  ]) async {
    if (!supported) return SendOutcome.retry;
    return withClient((web) async {
      try {
        final request = http.Request(
          method,
          Uri.parse('$endpoint/api/meals/$id'),
        )..headers.addAll({...headers, 'content-type': 'application/json'});
        if (body != null) request.body = jsonEncode(body);
        final response = await web
            .send(request)
            .timeout(const Duration(seconds: 15));
        await response.stream.drain<void>();
        _heed(response);
        return outcomeOf(response.statusCode);
      } catch (_) {
        return SendOutcome.retry;
      }
    });
  }

  Future<SendOutcome> saveMeal(String gymId, MealEntry meal) {
    final hour = meal.at.hour;
    final basis = meal.basis, eaten = meal.eaten;
    String two(int n) => n.toString().padLeft(2, '0');
    return _mealRequest('PUT', meal.id, {
      'gymId': gymId,
      'kind': hour < 10
          ? 'breakfast'
          : hour < 15
          ? 'lunch'
          : hour < 21
          ? 'dinner'
          : 'snack',
      'eatenOn': '${meal.at.year}-${two(meal.at.month)}-${two(meal.at.day)}',
      'kcal': meal.kcal,
      'source': ?meal.source,
      'text': ?meal.currentText,
      'items': meal.items,
      // The amount goes as a value and its unit ('serving'·'package'·'photo' or a printed unit);
      // the server writes the coach's line in the coach's language.
      if (basis != null && eaten != null) ...{
        'amountValue': eaten,
        'amountUnit': basis.unit,
        // The server keeps a unit of at most 12 characters; a longer printed unit
        // (the sheet allows 20) still reaches the coach as the old phrase.
        if (basis.unit.trim().length > 12)
          'amount': '${amountText(eaten)}${basis.unit}',
      },
    });
  }

  Future<SendOutcome> deleteMeal(String id) => _mealRequest('DELETE', id);
}

/// 밀린 끼니 변경을 보낸다. 운동 기록과 같은 규칙이다 — 그물이 막혔으면 다음
/// 기회에, 서버가 거절했으면 그 하나만 포기하고 계속 간다.
///
/// 스티커·받은 루틴으로 연 기록의 끼니는 언제나 간다. 식단 공유로 도장에 묶인
/// 기록([Note.mealGymId])은 그 도장과 나누는 동안([shareMealsGym], NotesStore 의 것)만
/// 새로 적거나 고친 것이 가고, 지운 것은 꺼져 있어도 지운다 — 코치 목록에서 내리는 것은
/// 늘 회원의 뜻이다.
Future<void> syncMeals(
  GymLink link,
  List<Note> notes, {
  String? shareMealsGym,
  required void Function() onSynced,
}) async {
  if (!link.supported || _uploadsQuiet) return;
  var changed = false;
  for (final note in notes) {
    // 다른 계정의 끼니는 그 사람이 다시 로그인할 때까지 밀어 둔다.
    if (note.mealGym == null || !note.ownedBy(link.userId)) continue;
    final gymId =
        note.gymId ?? (note.mealGymId == shareMealsGym ? shareMealsGym : null);
    for (final id in [...note.deletedMeals]) {
      final outcome = await link.deleteMeal(id);
      if (outcome == SendOutcome.retry) {
        if (changed) onSynced();
        return;
      }
      note.deletedMeals.remove(id);
      changed = true;
    }
    if (gymId == null) continue;
    for (final meal in [...note.meals]) {
      if (!meal.dirty) continue;
      final outcome = await link.saveMeal(gymId, meal);
      if (outcome == SendOutcome.retry) {
        if (changed) onSynced();
        return;
      }
      meal.dirty = false;
      changed = true;
    }
  }
  if (changed) onSynced();
}

/// 사람이 지운 기록이 서버에 남긴 것을 보낸다([NotesStore.delete]). 밀린 끼니와 같은
/// 규칙이다 — 그물이 막혔으면 다음 기회에, 서버가 거절했으면 그 하나만 버린다. 다른
/// 계정의 것은 그 사람이 다시 로그인할 때까지 둔다.
Future<void> sendDeletes(
  GymLink link,
  List<ServerDelete> queue, {
  required void Function() onSent,
}) async {
  if (!link.supported || _uploadsQuiet) return;
  var changed = false;
  // 운동 줄은 맨 뒤에 — 그 길을 모르는 서버(405)가 끼니 지우기까지 막지 않게.
  for (final d in [
    ...queue.where((d) => d.kind != 'workout'),
    ...queue.where((d) => d.kind == 'workout'),
  ]) {
    if (d.owner != null && d.owner != link.userId) continue;
    final outcome = switch (d.kind) {
      'meal' => await link.deleteMeal(d.id),
      'workout' => await link.deleteWorkout(d.id),
      'session' => switch ((await link.endPartnerSession(d.id)).error) {
        PartnerError.network ||
        PartnerError.server ||
        PartnerError.tooManyTries ||
        PartnerError.signInRequired => SendOutcome.retry,
        _ => SendOutcome.sent,
      },
      _ => SendOutcome.rejected,
    };
    if (outcome == SendOutcome.retry) break;
    queue.remove(d);
    changed = true;
  }
  if (changed) onSent();
}

/// 답의 JSON 몸. 못 읽으면 null.
Map<String, Object?>? _bodyOf(http.Response response) {
  try {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return decoded is Map ? decoded.cast<String, Object?>() : null;
  } catch (_) {
    return null;
  }
}

/// 서버가 거절한 까닭 — 기계가 읽는 [code](`error`)와 사람이 읽는 [message](요청의 언어,
/// [appLanguage]. 옛 서버는 늘 한국어). 서버에 닿지 못했으면 둘 다 ''. 화면은
/// [refusalMessage] 로 보일 말을 고른다.
typedef Refusal = ({String code, String message});

const Refusal _unreached = (code: '', message: '');

Refusal _refusal(Map<String, Object?>? body) => (
  code: body?['error'] is String ? body!['error'] as String : '',
  message: body?['message'] is String ? body!['message'] as String : '',
);

/// 예약·수업·탈퇴를 서버가 거절했을 때 보일 말. 앱이 아는 코드는 앱의 말(아홉 언어)로,
/// 모르는 코드는 서버가 적은 말로, 서버에 닿지 못했거나 아무 말이 없으면 [fallback].
///
/// **한국어 화면은 서버의 문장을 그대로 보인다.** 서버는 처음부터 한국어로 쓰고, 한 코드를
/// 상황마다 다른 문장으로 가른다 — slotTaken 하나가 '그룹 수업과 겹친다'·'이미 PT 가 있다'·
/// '담당이 바뀌었다' 다. 코드 하나에 한 문장인 앱의 말보다 자세하고, 한국어 사용자가 보던
/// 글이 그대로다. 다른 언어는 서버가 영어로만(옛 서버는 한국어로만) 답하고 앱은 아홉
/// 언어라, 아는 코드면 앱의 말이 낫다. 'conflict' 는 수업 예약의 그 밖의 모든 까닭을
/// 담는 코드라 모르는 코드로 친다.
String refusalMessage(L l, Refusal refusal, {required String fallback}) {
  final (:code, :message) = refusal;
  if (l.localeName == 'ko' && message.isNotEmpty) return message;
  return switch (code) {
        'signInRequired' => l.refusedSignIn,
        'notFound' => l.refusedGone,
        // PT 예약(POST·DELETE·PATCH /api/bookings, pt-bookings.ts BookingError)
        'invalidInput' => l.refusedBookingTime,
        'forbidden' => l.refusedBookingForbidden,
        'noTrainer' => l.refusedNoTrainer,
        'invalidTransition' => l.refusedBookingChanged,
        'slotTaken' => l.refusedSlotTaken,
        'noPass' => l.refusedNoPass,
        'tooLate' => l.refusedTooLate,
        // 그룹 수업(/api/classes/{id}/booking, class-bookings.ts ClassError)
        'full' => l.refusedClassFull,
        'noAccess' => l.refusedClassNoAccess,
        'cancelled' => l.refusedClassCancelled,
        // 탈퇴(DELETE /api/me) — 도장의 관장·트레이너다
        'blocked' => l.refusedAccountBlocked,
        _ => null,
      } ??
      (message.isEmpty ? fallback : message);
}

extension _Posting on GymLink {
  /// 서버의 답. 닿지 못했으면 null.
  Future<({int status, Map<String, Object?>? body})?> _call(
    String method,
    String path, [
    Map<String, Object?>? body,
  ]) => withClient((web) async {
    try {
      final request = http.Request(method, Uri.parse('$endpoint$path'))
        ..headers.addAll(headers);
      if (body != null) {
        request
          ..headers['content-type'] = 'application/json'
          ..body = jsonEncode(body);
      }
      final response = await web
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
      return (status: response.statusCode, body: _bodyOf(response));
    } catch (_) {
      return null;
    }
  });

  Future<({int status, Map<String, Object?>? body})?> _post(
    String path,
    Map<String, Object?> body,
  ) => _call('POST', path, body);
}

/// 잡았으면(200) null, 못 잡았으면 서버가 거절한 까닭(못 닿았으면 [_unreached]).
Refusal? _done(({int status, Map<String, Object?>? body})? answer) =>
    answer?.status == 200 ? null : _refusal(answer?.body);

/// 회원 등록 신청의 결과. 서버가 돌려주는 말 그대로다. [ageRequired] 는 '만 14세
/// 이상' 확인이 없는 계정이다(그 칸이 생기기 전에 만든 계정) — 한 번 묻고 다시 신청한다.
enum JoinState { requested, waiting, member, ageRequired, failed }

/// 도장 초대에 답한 결과. [gone] 은 도장이 초대를 거둔 것이다. [unreached] 는 서버에
/// 닿지 못한 것, [failed] 는 서버가 다른 까닭으로 받지 않은 것이다.
enum InviteAnswer { done, gone, ageRequired, unreached, failed }

/// What to say when a call did not get what it asked for: no answer → the connection; 401 → sign
/// in again; any other answer → the server's trouble. An answer is never "no connection".
String failedCall(L l, int? status) => switch (status) {
  null => l.partnerErrNetwork,
  401 => l.refusedSignIn,
  _ => l.partnerErrServer,
};

extension MemberLink on GymLink {
  /// 계정을 지운다. 서버가 지웠으면 null, 아니면 거절한 까닭(못 닿았으면 [_unreached]).
  ///
  /// **관장·트레이너는 지울 수 없다**(서버가 409 blocked 로 막는다). 도장에 회원과
  /// 예약이 매달려 있어서, 넘기거나 접는 것이 먼저다.
  Future<Refusal?> deleteAccount() async {
    if (!supported) return _unreached;
    return withClient((web) async {
      // The server gives a large account up to 2 minutes (gymdojo delete-account.ts statement_timeout)
      // and finishes it even if we hang up — wait that long rather than call a deletion that went through a failure.
      const wait = Duration(seconds: 130);
      final cut = Completer<void>();
      final timer = Timer(wait, cut.complete);
      try {
        final request = http.AbortableRequest(
          'DELETE',
          Uri.parse('$endpoint/api/me'),
          abortTrigger: cut.future,
        )..headers.addAll(headers);
        final response = await web
            .send(request)
            .then(http.Response.fromStream)
            .timeout(wait);
        return response.statusCode == 200 ? null : _refusal(_bodyOf(response));
      } catch (_) {
        return _unreached;
      } finally {
        timer.cancel();
      }
    });
  }

  /// 이 체육관에 등록을 신청한다.
  ///
  /// **스티커 주소는 앱이 가로챈다.** 그래서 웹의 등록 요청 화면에 닿을 수가
  /// 없고, 신청할 길이 앱 안에 있어야 한다. 앞에서 보여 준 안내의 판을 같이
  /// 보낸다 — 신청이 곧 동의라 서버가 그것을 남긴다.
  Future<JoinState> requestJoin(String gymId) async {
    if (!supported) return JoinState.failed;
    final answer = await _post('/api/members', {
      'gymId': gymId,
      'consentVersion': gymConsentVersion,
    });
    if (answer?.body?['error'] == 'ageConfirmationRequired') {
      return JoinState.ageRequired;
    }
    final body = answer?.status == 200 ? answer?.body : null;
    return switch (body?['state']) {
      'requested' => JoinState.requested,
      'waiting' => JoinState.waiting,
      'member' => JoinState.member,
      _ => JoinState.failed,
    };
  }

  /// '만 14세 이상입니다' 를 계정에 남긴다(POST /api/me/age). 남겼으면 true.
  Future<bool> confirmAge() async {
    if (!supported) return false;
    return (await _post('/api/me/age', const {}))?.status == 200;
  }

  /// 이 사람의 토큰을 모두 끊고(모든 기기에서 로그아웃) 이 폰에 줄 새 토큰을 받는다.
  /// 못 끊었으면 null.
  Future<String?> revokeSessions() async {
    if (!supported) return null;
    final answer = await _post('/api/me/sessions/revoke', const {});
    final body = answer?.status == 200 ? answer?.body : null;
    final fresh = body?['token'];
    return fresh is String && fresh.isNotEmpty ? fresh : null;
  }

  /// 도장 초대에 답한다. 받을 때는 앞에서 보여 준 안내의 판을 같이 보내 동의로 남긴다.
  Future<InviteAnswer> answerInvite(
    String gymId, {
    required bool accept,
  }) async {
    if (!supported) return InviteAnswer.unreached;
    final answer = await _post('/api/gyms/$gymId/invite', {
      'accept': accept,
      if (accept) 'consentVersion': gymConsentVersion,
    });
    return switch ((answer?.status, answer?.body?['error'])) {
      (200, _) => InviteAnswer.done,
      (404, _) => InviteAnswer.gone,
      (403, 'ageConfirmationRequired') => InviteAnswer.ageRequired,
      (null, _) => InviteAnswer.unreached,
      _ => InviteAnswer.failed,
    };
  }

  /// 이 도장에서 나간다. 끊기는 것은 연결뿐이고 지난 기록과 결제 장부는 도장에 남는다
  /// (앞으로의 PT·수업 예약은 서버가 취소한다). 서버의 답(200 = 나갔다), 못 닿았으면 null.
  Future<int?> leaveGym(String gymId) async {
    if (!supported) return null;
    return (await _call('DELETE', '/api/gyms/$gymId/membership'))?.status;
  }

  /// 닉네임을 바꾼다. 로그인하면 제공자의 이름(대개 실명)이 그대로 닉네임이 된다.
  /// 바꿨으면 null, 서버가 거절했으면 그 까닭(invalidNickname·nicknameTaken), 못
  /// 닿았으면 ''.
  Future<String?> changeNickname(String nickname) async {
    if (!supported) return '';
    final answer = await _post('/api/me/nickname', {'nickname': nickname});
    if (answer == null || answer.status >= 500) return '';
    return answer.status == 200 ? null : '${answer.body?['error'] ?? ''}';
  }
}

/// 그룹 수업 하나(GET /api/classes). 휴강한 것도 온다 — 회원이 수업이 없어진 줄 안다.
/// `status` 는 open·full·cancelled, [mine] 은 내가 잡은 수업이다.
typedef GymClass = ({
  String id,
  String title,
  DateTime startsAt,
  DateTime endsAt,
  String? trainer,
  int capacity,
  int booked,
  bool mine,
  String status,
});

/// 그룹 수업 예약. **웹 회원 화면에만 있던 길이다** — 스티커 주소를 앱이 가로채서 앱만
/// 쓰는 회원은 GX 를 잡을 곳이 없었다.
extension ClassLink on GymLink {
  /// 앞으로 2주의 수업. 못 받았으면 classes 가 null 이고, status 는 서버의 답(못 닿았으면 null)이다.
  Future<({List<GymClass>? classes, int? status})> classes(String gymId) async {
    if (!supported) return (classes: null, status: null);
    final answer = await _call(
      'GET',
      '/api/classes?gym=${Uri.encodeQueryComponent(gymId)}',
    );
    if (answer?.status != 200) return (classes: null, status: answer?.status);
    final found = eachRow(
      answer!.body?['classes'],
      (c) => (
        id: c['id'] as String,
        title: c['title'] as String,
        startsAt: DateTime.parse(c['startsAt'] as String).toLocal(),
        endsAt: DateTime.parse(c['endsAt'] as String).toLocal(),
        trainer: c['trainer'] as String?,
        capacity: c['capacity'] as int,
        booked: c['booked'] as int,
        mine: c['mine'] == true,
        status: c['status'] as String,
      ),
    );
    return (classes: found, status: 200);
  }

  /// 수업을 잡는다. 잡았으면 null, 못 잡았으면 서버가 거절한 까닭(자리가 찼다, 이용권이
  /// 없다, 다른 예약과 겹친다), 못 닿았으면 [_unreached].
  Future<Refusal?> bookClass(String id) async => supported
      ? _done(await _call('POST', '/api/classes/$id/booking'))
      : _unreached;

  /// 수업 예약을 취소한다. 결과는 [bookClass] 와 같다.
  Future<Refusal?> cancelClass(String id) async => supported
      ? _done(await _call('DELETE', '/api/classes/$id/booking'))
      : _unreached;
}

/// 예약 화면이 그려지는 데 필요한 전부.
///
/// **하루치 빈 시간만으로는 화면을 못 그린다.** 트레이너가 받는 요일과 남은
/// 횟수를 모르면 앱은 이레를 다 열어 놓고 하나씩 눌러 보게 한다.
class Availability {
  const Availability({
    this.bookings = const [],
    this.slots = const [],
    this.weekdays = const {},
    this.trainer,
    this.durationMin = 50,
    this.hasPass = false,
    this.remaining,
    this.paused = false,
    this.loaded = false,
  });

  static const empty = Availability();

  final List<Booking> bookings;
  final List<DateTime> slots;

  /// 이 트레이너가 받는 요일. 일요일이 0 이다.
  final Set<int> weekdays;
  final String? trainer;
  final int durationMin;

  /// 쓸 수 있는 PT 이용권이 있는가. 없으면 신청해도 서버가 막는다.
  final bool hasPass;

  /// 남은 횟수. null 은 무제한이거나 이용권이 없다는 뜻이다.
  final int? remaining;

  /// 쓸 PT 이용권이 없는 까닭이 정지다 — '이용권 없음' 이라고 하면 회원은 끝난 줄 안다.
  final bool paused;

  /// 서버에서 한 번이라도 받아 왔는가. 안 받아 온 것과 빈 것은 다르다.
  final bool loaded;

  bool get receivesBookings => weekdays.isNotEmpty;
  bool opensOn(DateTime day) => weekdays.contains(day.weekday % 7);
}

/// 내 PT 예약 하나.
///
/// `status` 를 함께 들고 온다 — 신청(pending)과 확정(booked)은 회원이 오늘
/// 나갈지 말지를 가르는 차이라 같은 줄로 보이면 안 된다.
typedef Booking = ({
  String id,
  String gym,
  String trainer,
  String? trainerId,
  DateTime startsAt,
  String status,
});

extension BookingLink on GymLink {
  /// 다가오는 예약과, 고른 날에 잡을 수 있는 시각.
  Future<Availability> bookings({DateTime? day, String? gymId}) async {
    if (!supported) return Availability.empty;
    return withClient((web) async {
      try {
        // 서버는 소속 체육관이 하나일 때만 생략을 봐 준다. 둘이면 거절한다.
        final query = [
          if (gymId != null) 'gymId=$gymId',
          if (day != null) 'day=${day.toIso8601String().substring(0, 10)}',
        ];
        final at = query.isEmpty ? '' : '?${query.join('&')}';
        final response = await web
            .get(Uri.parse('$endpoint/api/bookings$at'), headers: headers)
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) return Availability.empty;
        final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
        final pass = body['pass'];
        return Availability(
          bookings: [
            for (final row in body['bookings'] as List? ?? const [])
              (
                id: row['id'] as String,
                gym: row['gym'] as String,
                trainer: row['trainer'] as String,
                trainerId: row['trainer_id'] as String?,
                startsAt: DateTime.parse(row['starts_at'] as String).toLocal(),
                status: row['status'] as String? ?? 'booked',
              ),
          ],
          slots: [
            for (final at in body['slots'] as List? ?? const [])
              DateTime.parse(at as String).toLocal(),
          ],
          weekdays: {
            for (final w in body['weekdays'] as List? ?? const []) w as int,
          },
          trainer: body['trainer'] as String?,
          durationMin: body['duration_min'] as int? ?? 50,
          hasPass: pass is Map,
          remaining: pass is Map ? pass['remaining'] as int? : null,
          paused: body['paused'] == true,
          loaded: true,
        );
      } catch (_) {
        return Availability.empty;
      }
    });
  }

  /// 빈 자리를 잡는다. 잡았으면 null, 못 잡았으면 서버가 거절한 까닭이다 — 그 사이 남이
  /// 가져갔다, 이용권이 끝났다, 담당이 바뀌었다. 서버에 못 닿았으면 [_unreached].
  /// 까닭을 버리면 회원은 무엇이든 '빈 시간이 없다' 로 읽고 다른 날을 계속 누른다.
  Future<Refusal?> book(DateTime startsAt, {String? gymId}) async {
    if (!supported) return _unreached;
    final answer = await _post('/api/bookings', {
      'startsAt': startsAt.toUtc().toIso8601String(),
      'gymId': ?gymId,
    });
    if (answer?.status == 200 && answer!.body?['id'] is String) return null;
    return _refusal(answer?.body);
  }

  /// 예약을 취소한다. 결과는 [book] 과 같다 — 시작 시각이 지났으면 서버가 거절한다.
  Future<Refusal?> cancelBooking(String id) async {
    if (!supported) return _unreached;
    return _done(await _call('DELETE', '/api/bookings?id=$id'));
  }
}

/// 스티커에 댔을 때 열리는 주소에서 체육관을 꺼낸다.
///
/// 태그에는 `https://<서버>/c/<체육관 id>` 하나만 들어 있다. 로직도 배터리도
/// 없고, 앱이 없는 사람은 그 주소가 웹으로 열린다 — 같은 스티커가 둘 다 된다.
///
/// **그 아래 주소는 스티커가 아니다.** `/c/<id>/classes`·`bookings`·`meals` 는 웹
/// 화면이고, 앱 링크 설정(/c/ 아래 전부)이 그것까지 앱으로 넘긴다. 스티커로 읽으면
/// 단톡방의 수업 링크를 누른 회원이 집에서 출석하거나 가입 신청이 나갔다.
String? gymFromTag(Uri uri) {
  final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
  if (parts.length == 2 && parts.first == 'c') return parts[1];
  // `setpad://c/<체육관 id>` — 웹 화면의 "앱에서 열기"가 이것으로 부른다.
  // 커스텀 스킴에서는 'c' 가 경로가 아니라 host 로 잡힌다.
  if (uri.host == 'c' && parts.length == 1) return parts.first;
  return null;
}

/// 스티커 주소 아래의 수업·PT 예약 링크(`/c/<id>/classes`·`/c/<id>/bookings`) — 트레이너가
/// 단톡방에 올리는 그 링크다. 앱 링크 설정이 그것까지 앱으로 넘기므로 앱의 같은 화면을 연다.
({String gymId, String page})? gymScreenFromLink(Uri uri) {
  final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
  return parts.length == 3 &&
          parts.first == 'c' &&
          const {'classes', 'bookings'}.contains(parts.last)
      ? (gymId: parts[1], page: parts.last)
      : null;
}
