import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_route.dart';

import 'editor.dart';
import 'meal.dart';
import 'notes.dart';
import 'partner.dart';
import 'record_ai.dart';

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

  /// 다니는 체육관. **못 물어본 것은 null 이다** — 빈 목록과 다르다. 빈 목록으로
  /// 돌려주면 신호가 약하거나 토큰이 거절된 순간 다니는 곳이 없는 사람처럼 보인다.
  Future<List<Gym>?> gyms() async {
    if (!supported) return const [];
    return withClient((web) async {
      try {
        final response = await web
            .get(Uri.parse('$endpoint/api/gyms'), headers: headers)
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) return null;
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
        return switch (response.statusCode) {
          200 => SendOutcome.sent,
          // 401 은 토큰이 죽은 것, 408·429 는 나중에 하라는 것 — 기록 탓이 아니다.
          401 || 408 || 429 => SendOutcome.retry,
          >= 400 && < 500 => SendOutcome.rejected,
          _ => SendOutcome.retry,
        };
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
        return switch (response.statusCode) {
          200 || 404 => SendOutcome.sent,
          // 405 는 이 길을 아직 모르는 서버다. 버리지 않고 다음에 다시 보낸다.
          401 || 405 || 408 || 429 => SendOutcome.retry,
          >= 400 && < 500 => SendOutcome.rejected,
          _ => SendOutcome.retry,
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
  'lb' => set.value == null ? null : (set.value! * 0.45359237 * 100).round() / 100,
  _ => null,
};

/// 서버가 받는 기록의 한도(isWorkoutResult). 하나라도 넘으면 서버는 기록 전체를
/// 400 으로 거절하고 앱은 그 기록을 다시 보내 봐야 소용이 없으므로, 보내기 전에
/// 한도 안으로 맞춘다 — 오타 하나가 그날의 출석까지 잃게 하지 않는다.
const _maxKg = 9999;
const _maxReps = 10000;
const _maxSets = 100;
const _maxExercises = 100;
const _maxNameLength = 200;

/// 앱의 기록을 웹이 읽는 모양으로 바꾼다. 계획과 같은 모양에 done 이 붙는다.
List<Map<String, Object?>> loggedItems(List<ExerciseBlock> blocks) => [
  for (final block
      in blocks.where((b) => b.exercise.trim().isNotEmpty).take(_maxExercises))
    {
      'name': block.exercise.length > _maxNameLength
          ? block.exercise.substring(0, _maxNameLength)
          : block.exercise,
      'sets': [
        for (final set in block.sets.take(_maxSets))
          {
            'kg': ?kgOf(set)?.clamp(0, _maxKg),
            if (set.reps != null) 'reps': set.reps!.clamp(0, _maxReps),
            'done': set.done,
          },
      ],
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
      if (needsSend(note) && note.ownedBy(link.userId)) note,
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
      startedAt: note.createdAt,
      // 같이 고친 기록에는 옆 사람의 세트도 있다. 트레이너에게는 내 것만.
      blocks: visitOnly ? const [] : mineOnly(note.blocks),
    );
    // 그물이 막혔으면 나머지도 막힌다. 다음 기회에.
    if (outcome == SendOutcome.retry) break;
    // 서버가 이 하나를 거절한 것이면 뒤의 것들은 상관없다. 건너뛰고 계속 간다 —
    // 이것 하나 때문에 그 뒤 몇 주치가 영영 안 올라가던 일이 있었다.
    if (outcome == SendOutcome.rejected) continue;
    note.sentAt = at;
    // 이 계정으로 올라갔다. 다른 계정으로 바꾼 뒤 고친 것이 그 계정 앞으로 가지 않게.
    note.owner ??= link.userId;
    changed = true;
  }
  if (changed) onSent();
}

/// 확정한 끼니를 서버의 **같은 줄**에 맞춘다.
///
/// 추정 요청은 아무것도 저장하지 않는다. 사람이 먹은 양까지 정한 끼니만 여기로
/// 올라가고, 끼니의 id 가 열쇠라서 다시 보내도 한 줄, 고치면 그 줄이 바뀌고,
/// 지우면 그 줄이 없어진다. 로그인한 도장 회원의 기록(gymId)만 대상이다.
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
        return switch (response.statusCode) {
          200 => SendOutcome.sent,
          401 || 408 || 429 => SendOutcome.retry,
          >= 400 && < 500 => SendOutcome.rejected,
          _ => SendOutcome.retry,
        };
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
      // 코치가 읽는 줄은 서버가 한국어로 짓는다. 단위 이름도 거기에 맞춘다.
      if (basis != null && eaten != null)
        'amount': switch (basis.unit) {
          MealBasis.serving => '${amountText(eaten)}회분',
          MealBasis.package => '포장 전체 × ${amountText(eaten)}',
          MealBasis.photo => '사진 속 음식 × ${amountText(eaten)}',
          _ => '${amountText(eaten)}${basis.unit}',
        },
    });
  }

  Future<SendOutcome> deleteMeal(String id) => _mealRequest('DELETE', id);
}

/// 밀린 끼니 변경을 보낸다. 운동 기록과 같은 규칙이다 — 그물이 막혔으면 다음
/// 기회에, 서버가 거절했으면 그 하나만 포기하고 계속 간다.
Future<void> syncMeals(
  GymLink link,
  List<Note> notes, {
  required void Function() onSynced,
}) async {
  if (!link.supported) return;
  var changed = false;
  for (final note in notes) {
    final gymId = note.gymId;
    // 다른 계정의 끼니는 그 사람이 다시 로그인할 때까지 밀어 둔다.
    if (gymId == null || !note.ownedBy(link.userId)) continue;
    for (final id in [...note.deletedMeals]) {
      final outcome = await link.deleteMeal(id);
      if (outcome == SendOutcome.retry) {
        if (changed) onSynced();
        return;
      }
      note.deletedMeals.remove(id);
      changed = true;
    }
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
  if (!link.supported) return;
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

/// 서버가 거절하며 적은 까닭(한국어, 그대로 보여도 된다). 답을 못 받았거나 까닭이
/// 없으면 ''.
String _reason(Map<String, Object?>? body) =>
    body?['message'] is String ? body!['message'] as String : '';

extension _Posting on GymLink {
  /// 서버의 답. 닿지 못했으면 null.
  Future<({int status, Map<String, Object?>? body})?> _post(
    String path,
    Map<String, Object?> body,
  ) => withClient((web) async {
    try {
      final response = await web
          .post(
            Uri.parse('$endpoint$path'),
            headers: {...headers, 'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return (status: response.statusCode, body: _bodyOf(response));
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
  /// 계정을 지운다. 서버가 지웠다고 하면 true.
  ///
  /// **관장·트레이너는 지울 수 없다**(서버가 409 로 막는다). 도장에 회원과
  /// 예약이 매달려 있어서, 넘기거나 접는 것이 먼저다.
  Future<({bool ok, String? reason})> deleteAccount() async {
    if (!supported) return (ok: false, reason: null);
    return withClient((web) async {
      try {
        final response = await web
            .delete(Uri.parse('$endpoint/api/me'), headers: headers)
            .timeout(const Duration(seconds: 20));
        if (response.statusCode == 200) return (ok: true, reason: null);
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return (
          ok: false,
          reason: body is Map ? body['message'] as String? : null,
        );
      } catch (_) {
        return (ok: false, reason: null);
      }
    });
  }

  Future<JoinState> requestJoin(String gymId) async {
    if (!supported) return JoinState.failed;
    final answer = await _post('/api/members', {'gymId': gymId});
    final body = answer?.status == 200 ? answer?.body : null;
    return switch (body?['state']) {
      'requested' => JoinState.requested,
      'waiting' => JoinState.waiting,
      'member' => JoinState.member,
      _ => JoinState.failed,
    };
  }
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
          loaded: true,
        );
      } catch (_) {
        return Availability.empty;
      }
    });
  }

  /// 빈 자리를 잡는다. 잡았으면 null, 못 잡았으면 서버가 적은 까닭이다 — 그 사이 남이
  /// 가져갔다, 이용권이 끝났다, 담당이 바뀌었다. 서버에 못 닿았거나 까닭이 없으면 ''.
  /// 까닭을 버리면 회원은 무엇이든 '빈 시간이 없다' 로 읽고 다른 날을 계속 누른다.
  Future<String?> book(DateTime startsAt, {String? gymId}) async {
    if (!supported) return '';
    final answer = await _post('/api/bookings', {
      'startsAt': startsAt.toUtc().toIso8601String(),
      'gymId': ?gymId,
    });
    if (answer?.status == 200 && answer!.body?['id'] is String) return null;
    return _reason(answer?.body);
  }

  /// 예약을 취소한다. 결과는 [book] 과 같다 — 시작 시각이 지났으면 서버가 거절한다.
  Future<String?> cancelBooking(String id) async {
    if (!supported) return '';
    return withClient((web) async {
      try {
        final response = await web
            .delete(
              Uri.parse('$endpoint/api/bookings?id=$id'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));
        return response.statusCode == 200 ? null : _reason(_bodyOf(response));
      } catch (_) {
        return '';
      }
    });
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
