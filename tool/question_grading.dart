import 'dart:convert';

import 'package:setpad/record_query.dart';

/// 채점할 모양. 날짜는 풀린 것, 조건은 글자로 — 뜻 전체를 견준다.
Map<String, Object?> queryShape(RecordQuery q) => {
  'kind': q.kind,
  if (q.kind == 'query') ...{
    'exercises': q.scope.exercises,
    'exclude': q.exclude,
    'measures': [for (final m in q.measures) m.name],
    'since': q.scope.since?.toIso8601String().substring(0, 10),
    'until': q.scope.until?.toIso8601String().substring(0, 10),
    'weight': [for (final b in q.scope.weight) '$b'],
    'reps': [for (final b in q.scope.reps) '$b'],
    'weekdays': q.scope.weekdays,
    'memo': q.scope.memo,
    'sessions': q.scope.sessions,
    'compare': q.compare.length,
    'by': q.by,
    'order': q.order,
    'limit': q.limit,
    'total': q.total,
  },
};

/// v1 정답(운동 하나·측정 하나·기간·이상/이하 조건)을 v2 모양으로. 순위와
/// 비교 정답은 아직 옮기지 않았다 — null 은 채점하지 않는다는 뜻이다.
Map<String, Object?>? v2Expected(Map<String, Object?> expected) {
  if (expected.containsKey('note') ||
      expected.containsKey('requests') ||
      expected['rank'] == true ||
      (expected.containsKey('exercise') && expected['exercise'] == null)) {
    return null;
  }
  if (expected['kind'] == 'unsupported') return {'kind': 'unsupported'};
  final unit = (expected['unit'] ?? 'kg') as String;
  List<String> bounds(String min, String max, String? u) => [
    if (expected[min] case final num v) '${Bound('>=', v.toDouble(), u)}',
    if (expected[max] case final num v) '${Bound('<=', v.toDouble(), u)}',
  ];
  return queryShape(const RecordQuery())..addAll({
    'exercises': expected['exercise'] == '*' ? [] : [expected['exercise']],
    // v1 의 max 는 v2 에서 운동마다 뜻을 고르는 best 다. 나머지는 이름이 같다.
    'measures': [
      if (expected['metric'] == 'max') 'best' else expected['metric'],
    ],
    'since': expected['since'],
    'until': expected['until'],
    'weight': bounds('minWeight', 'maxWeight', unit),
    'reps': bounds('minReps', 'maxReps', null),
  });
}

/// 질의 뜻 전체를 채점한다. 빠진 조건·덧붙은 조건·다른 묶음 모두 틀림이다.
/// 확인 탭은 따로 센다 — 묻는 것은 맞게 읽은 것이 아니다. null 은 채점 밖.
List<String>? gradeRecordQuery(RecordQuery q, Map<String, Object?> expected) {
  final want = v2Expected(expected);
  if (want == null) return null;
  final got = queryShape(q);
  return [
    for (final key in {...want.keys, ...got.keys})
      if (jsonEncode(got[key]) != jsonEncode(want[key])) key,
  ];
}
