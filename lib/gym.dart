import 'dart:convert';

import 'package:http/http.dart' as http;

import 'editor.dart';
import 'notes.dart';

/// 내가 다니는 체육관 하나.
typedef Gym = ({String id, String name, String? trainer});

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
  const GymLink({required this.endpoint, this.token, this.client});
  final String endpoint;
  final String? token;
  final http.Client? client;

  bool get supported => token != null;

  /// 그물을 빌려 쓰고 반드시 닫는다. 확장도 같은 것을 쓴다.
  Future<T> withClient<T>(Future<T> Function(http.Client web) run) async {
    final web = client ?? http.Client();
    try {
      return await run(web);
    } finally {
      if (client == null) web.close();
    }
  }

  Map<String, String> get headers => {'authorization': 'Bearer $token'};

  Future<List<Gym>> gyms() async {
    if (!supported) return const [];
    return withClient((web) async {
      try {
        final response = await web
            .get(Uri.parse('$endpoint/api/gyms'), headers: headers)
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) return const [];
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return [
          for (final row in (body as Map)['gyms'] as List? ?? const [])
            (
              id: row['id'] as String,
              name: row['name'] as String,
              trainer: row['trainer'] as String?,
            ),
        ];
      } catch (_) {
        // 그물이 없으면 체육관이 없는 것처럼 군다. 기록하는 일은 그대로 된다.
        return const [];
      }
    });
  }

  Future<List<Routine>> routines() async {
    if (!supported) return const [];
    return withClient((web) async {
      try {
        final response = await web
            .get(Uri.parse('$endpoint/api/routines'), headers: headers)
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) return const [];
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
        return const [];
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
  }) async {
    if (!supported) return false;
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
                'startedAt': startedAt.toIso8601String(),
                'result': loggedItems(blocks),
                'note': ?note,
              }),
            )
            .timeout(const Duration(seconds: 20));
        return response.statusCode == 200;
      } catch (_) {
        return false;
      }
    });
  }
}

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
      ]),
];

/// 앱의 기록을 웹이 읽는 모양으로 바꾼다. 계획과 같은 모양에 done 이 붙는다.
List<Map<String, Object?>> loggedItems(List<ExerciseBlock> blocks) => [
  for (final block in blocks)
    {
      'name': block.exercise,
      'sets': [
        for (final set in block.sets)
          {
            if (set.value != null) 'kg': set.value,
            if (set.reps != null) 'reps': set.reps,
            'done': set.done,
          },
      ],
    },
];

/// 아직 못 보낸 기록을 보낸다.
///
/// **헬스장은 신호가 나쁘다.** 한 번에 못 보내는 것이 정상이라서, 앱을 켤
/// 때마다 밀린 것을 다시 시도한다. 같은 것을 두 번 보내도 서버가 한 줄로
/// 합치므로(local_id) 겹쳐도 해가 없다.
Future<void> sendPending(
  GymLink link,
  List<Note> notes, {
  required void Function() onSent,
}) async {
  if (!link.supported) return;
  var changed = false;
  // 오래된 것부터. 트레이너가 보는 차례가 실제 순서와 같아야 한다.
  final waiting = [
    for (final note in notes)
      // 빈 것도 보낸다 — 루틴 없이 그냥 나온 날의 출석이 그렇게 생긴다.
      if (note.gymId != null && note.sentAt == null)
        note,
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  for (final note in waiting) {
    final ok = await link.sendWorkout(
      gymId: note.gymId!,
      localId: note.id,
      routineId: note.routineId,
      startedAt: note.createdAt,
      blocks: note.blocks,
    );
    if (!ok) break; // 하나가 막히면 나머지도 막힌다. 다음 기회에.
    note.sentAt = DateTime.now();
    changed = true;
  }
  if (changed) onSent();
}

/// 같이 하는 사람. 그날 운동 하나에만 붙는다.
typedef Partnership = ({String workoutId, String? partner});

extension PartnerLink on GymLink {
  /// 같이 하자고 코드를 띄운다. 상대가 10분 안에 치면 짝이 된다.
  Future<String?> invite(String workoutId) async {
    if (!supported) return null;
    final answer = await _post('/api/partners', {'workoutId': workoutId});
    return answer?['code'] as String?;
  }

  /// 상대가 띄운 코드를 친다. 내 운동도 같이 넘겨 서로의 짝이 되게 한다.
  Future<Partnership?> join(String code, {String? myWorkoutId}) async {
    if (!supported) return null;
    final answer = await _post('/api/partners', {
      'code': code,
      'workoutId': ?myWorkoutId,
    });
    final id = answer?['workoutId'];
    return id is String
        ? (workoutId: id, partner: answer?['partner'] as String?)
        : null;
  }

  /// 짝이 같이 보는 운동을 읽는다. 상대가 방금 적은 것이 여기로 온다.
  Future<List<ExerciseBlock>?> readShared(String workoutId) async {
    if (!supported) return null;
    return withClient((web) async {
      try {
        final response = await web
            .get(
              Uri.parse('$endpoint/api/workouts/$workoutId'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) return null;
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return plannedBlocks((body as Map)['result']);
      } catch (_) {
        return null;
      }
    });
  }

  /// 내가 적은 것을 올린다. 상대 폰이 몇 초 안에 받는다.
  Future<bool> writeShared(String workoutId, List<ExerciseBlock> blocks) async {
    if (!supported) return false;
    return withClient((web) async {
      try {
        final response = await web
            .put(
              Uri.parse('$endpoint/api/workouts/$workoutId'),
              headers: {...headers, 'content-type': 'application/json'},
              body: jsonEncode({'result': loggedItems(blocks)}),
            )
            .timeout(const Duration(seconds: 10));
        return response.statusCode == 200;
      } catch (_) {
        return false;
      }
    });
  }

  Future<Map<String, Object?>?> _post(String path, Map<String, Object?> body) =>
      withClient((web) async {
        try {
          final response = await web
              .post(
                Uri.parse('$endpoint$path'),
                headers: {...headers, 'content-type': 'application/json'},
                body: jsonEncode(body),
              )
              .timeout(const Duration(seconds: 15));
          if (response.statusCode != 200) return null;
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          return decoded is Map ? decoded.cast<String, Object?>() : null;
        } catch (_) {
          return null;
        }
      });
}

/// 회원 등록 신청의 결과. 서버가 돌려주는 말 그대로다.
enum JoinState { requested, waiting, member, failed }

extension MemberLink on GymLink {
  /// 이 체육관에 등록을 신청한다.
  ///
  /// **스티커 주소는 앱이 가로챈다.** 그래서 웹의 등록 요청 화면에 닿을 수가
  /// 없고, 신청할 길이 앱 안에 있어야 한다.
  Future<JoinState> requestJoin(String gymId) async {
    if (!supported) return JoinState.failed;
    final answer = await _post('/api/members', {'gymId': gymId});
    return switch (answer?['state']) {
      'requested' => JoinState.requested,
      'waiting' => JoinState.waiting,
      'member' => JoinState.member,
      _ => JoinState.failed,
    };
  }
}

/// 내 PT 예약 하나.
///
/// `status` 를 함께 들고 온다 — 신청(pending)과 확정(booked)은 회원이 오늘
/// 나갈지 말지를 가르는 차이라 같은 줄로 보이면 안 된다.
typedef Booking = ({
  String id,
  String gym,
  String trainer,
  DateTime startsAt,
  String status,
});

extension BookingLink on GymLink {
  /// 다가오는 예약과, 고른 날에 잡을 수 있는 시각.
  Future<({List<Booking> bookings, List<DateTime> slots})> bookings({
    DateTime? day,
    String? gymId,
  }) async {
    if (!supported) return (bookings: <Booking>[], slots: <DateTime>[]);
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
        if (response.statusCode != 200) {
          return (bookings: <Booking>[], slots: <DateTime>[]);
        }
        final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
        return (
          bookings: <Booking>[
            for (final row in body['bookings'] as List? ?? const [])
              (
                id: row['id'] as String,
                gym: row['gym'] as String,
                trainer: row['trainer'] as String,
                startsAt: DateTime.parse(row['starts_at'] as String).toLocal(),
                status: row['status'] as String? ?? 'booked',
              ),
          ],
          slots: <DateTime>[
            for (final at in body['slots'] as List? ?? const [])
              DateTime.parse(at as String).toLocal(),
          ],
        );
      } catch (_) {
        return (bookings: <Booking>[], slots: <DateTime>[]);
      }
    });
  }

  /// 빈 자리를 잡는다. 그 사이 남이 가져갔으면 실패한다 — 서버가 다시 센다.
  Future<bool> book(DateTime startsAt, {String? gymId}) async {
    if (!supported) return false;
    final answer = await _post('/api/bookings', {
      'startsAt': startsAt.toUtc().toIso8601String(),
      'gymId': ?gymId,
    });
    return answer?['id'] is String;
  }

  Future<bool> cancelBooking(String id) async {
    if (!supported) return false;
    return withClient((web) async {
      try {
        final response = await web
            .delete(
              Uri.parse('$endpoint/api/bookings?id=$id'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));
        return response.statusCode == 200;
      } catch (_) {
        return false;
      }
    });
  }
}

/// 스티커에 댔을 때 열리는 주소에서 체육관을 꺼낸다.
///
/// 태그에는 `https://<서버>/c/<체육관 id>` 하나만 들어 있다. 로직도 배터리도
/// 없고, 앱이 없는 사람은 그 주소가 웹으로 열린다 — 같은 스티커가 둘 다 된다.
String? gymFromTag(Uri uri) {
  final parts = uri.pathSegments;
  return parts.length >= 2 && parts.first == 'c' && parts[1].isNotEmpty
      ? parts[1]
      : null;
}
