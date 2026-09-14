import 'dart:convert';

import 'package:http/http.dart' as http;

import 'editor.dart';

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

  Future<T> _with<T>(Future<T> Function(http.Client web) run) async {
    final web = client ?? http.Client();
    try {
      return await run(web);
    } finally {
      if (client == null) web.close();
    }
  }

  Map<String, String> get _headers => {'authorization': 'Bearer $token'};

  Future<List<Gym>> gyms() async {
    if (!supported) return const [];
    return _with((web) async {
      try {
        final response = await web
            .get(Uri.parse('$endpoint/api/gyms'), headers: _headers)
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
    return _with((web) async {
      try {
        final response = await web
            .get(Uri.parse('$endpoint/api/routines'), headers: _headers)
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
    return _with((web) async {
      try {
        final response = await web
            .post(
              Uri.parse('$endpoint/api/workouts'),
              headers: {..._headers, 'content-type': 'application/json'},
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
