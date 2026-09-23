import 'dart:convert';

import 'package:setpad/record_query.dart';

/// 평가 기준일. 정답의 "지난달" 도, 모델의 "지난달" 도 이 날로 푼다.
final evalToday = DateTime(2026, 9, 9);

String? _iso(DateTime? d) => d?.toIso8601String().substring(0, 10);

/// 적은 순서가 뜻이 아닌 목록 — 운동별 줄, 범위 조건 둘, 요일.
List<String> _set(Iterable<Object> values) =>
    [for (final v in values) '$v']..sort();

Map<String, Object?> _scopeShape(QueryScope v) => {
  'exercises': _set(v.exercises),
  'since': _iso(v.since),
  'until': _iso(v.until),
  'sessions': v.sessions,
  'weight': _set(v.weight),
  'reps': _set(v.reps),
  'weekdays': _set(v.weekdays),
  'memo': v.memo,
};

/// 채점할 모양. 날짜는 풀린 것, 조건은 글자로 — 뜻 전체를 견준다.
Map<String, Object?> queryShape(RecordQuery q) => {
  'kind': q.kind,
  if (q.kind == 'unsupported') 'reason': q.reason,
  if (q.kind == 'find') 'exercises': _set(q.scope.exercises),
  if (q.kind == 'query') ...{
    // 비교면 범위는 항목들이 다 말한다. 공통 키를 위에 적었는지 항목마다
    // 적었는지는 뜻이 아니다. 항목의 순서는 뜻이다 — 앞이 기준이다.
    if (q.compare.isEmpty) ..._scopeShape(q.scope),
    'compare': [for (final v in q.compare) _scopeShape(v)],
    'exclude': _set(q.exclude),
    'measures': [for (final m in q.measures) m.name],
    'by': q.by,
    'order': q.order,
    'limit': q.limit,
    'total': q.total,
  },
};

/// 메모는 정답 어간을 모두 담았으면 맞다 — 모델이 "통증" 을 더 적어도 된다.
bool _same(String key, Object? got, Object? want) =>
    key == 'memo' && got is List && want is List
    ? want.every(got.contains)
    : jsonEncode(got) == jsonEncode(want);

/// 정답 대안들과 견줘 가장 가까운 대안에서 틀린 키를 돌려준다. 빈 목록이면
/// 맞음이다. 대안은 모델이 쓸 날것의 질의(contract 2)이고, 같은 디코더를
/// 기준일로 지나 모양이 된다 — 날짜를 풀고 기본값을 채운 뒤에 견준다.
/// [ignore] 의 키는 보지 않는다("limit 무관").
List<String> gradeQuery(
  RecordQuery q,
  List<Object?> gold,
  List<String> names, {
  Iterable<Object?> ignore = const [],
}) {
  final got = queryShape(q);
  List<String>? closest;
  for (final g in gold) {
    final want = queryShape(RecordQuery.decode(g, names, today: evalToday));
    final errors = [
      for (final key in {...want.keys, ...got.keys})
        if (!ignore.contains(key) && !_same(key, got[key], want[key])) key,
    ];
    if (closest == null || errors.length < closest.length) closest = errors;
  }
  return closest ?? const ['gold'];
}

/// v1 측정 이름 → 모델이 쓰는 v2 이름.
const _v1Measures = {
  'max': 'best',
  'trend': 'weightChange',
  'last': 'latest',
  'sessions': 'trainingDays',
  'volume': 'volume',
  'sets': 'setCount',
  'reps': 'repCount',
  'average': 'meanWeight',
};

/// v1 정답(운동 하나·측정 하나·기간·이상/이하 조건)을 v2 정답 대안으로.
/// `gold` 가 적힌 문장(두 운동, 초과)은 그것을 쓴다. null 은 채점하지
/// 않는다는 뜻이다(초성 두 글자처럼 관찰만 하는 문장).
List<Object?>? v2Expected(Map<String, Object?> expected) {
  if (expected['gold'] case final List gold) return gold;
  if (expected['kind'] == 'unsupported') {
    return const [
      {'kind': 'unrelated'},
    ];
  }
  final exercise = expected['exercise'];
  final metric = _v1Measures[expected['metric']];
  if (exercise is! String || metric == null) return null;
  final unit = expected['unit'] ?? 'kg';
  List<Map<String, Object?>> bounds(String min, String max, Object? u) => [
    if (expected[min] case final num v) {'op': '>=', 'value': v, 'unit': ?u},
    if (expected[max] case final num v) {'op': '<=', 'value': v, 'unit': ?u},
  ];
  final weight = bounds('minWeight', 'maxWeight', unit);
  final reps = bounds('minReps', 'maxReps', null);
  final since = expected['since'], until = expected['until'];
  final gold = {
    if (exercise != '*') 'exercises': [exercise],
    'measures': [metric],
    if (since != null || until != null) ...{
      'period': 'custom',
      'since': ?since,
      'until': ?until,
    },
    if (weight.isNotEmpty) 'weight': weight,
    if (reps.isNotEmpty) 'reps': reps,
  };
  return [
    gold,
    // "요즘 어때" 는 v2 지시문에서 최근 28일이다. 규칙 층은 이 낱말을
    // 기간으로 읽지 않으니 둘 다 맞다.
    if (expected['orRecent'] == true) {...gold, 'period': 'recent', 'days': 28},
  ];
}

/// v1 모음(dev·heldout)을 채점한다. null 은 채점 밖.
List<String>? gradeRecordQuery(
  RecordQuery q,
  Map<String, Object?> expected,
  List<String> names,
) {
  final gold = v2Expected(expected);
  return gold == null ? null : gradeQuery(q, gold, names);
}
