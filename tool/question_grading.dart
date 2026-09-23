import 'dart:convert';
import 'dart:math' as math;

import 'package:setpad/exercises.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/record_query.dart' show exerciseKey;

/// 평가 기준일. 정답의 "지난달" 도, 모델의 "지난달" 도 이 날로 푼다.
final evalToday = DateTime(2026, 9, 9);

// ── 문법(contract 3) ─────────────────────────────────────────────────────
// 설계(search-v3-design.md §3)의 닫힌 어휘와 불변식을 grammar_check.py 처럼
// 옮기고, 검토(search-v3-critique.json)가 필수로 더한 것을 넣었다:
// series 키 handoff·nth·memoAll, plan 키 against, per: month, 측정
// balance·sessionsSinceBest, 운동·부위 축의 trainingDays 비중 금지.
//
// 앱 디코더에 기대지 않는다 — 이 파일은 정답의 뜻을 스스로 정한다. 그래서
// 정답과 모델 답이 같은 풀이(기간 → 날짜, 이름 → 운동, 펼치기)를 지나고,
// 뜻이 같은 두 모양(지난달 ↔ 8/1–8/31)은 같다고 본다.

const planMeasures = [
  'best',
  'meanWeight',
  'e1rm',
  'volume',
  'weightChange',
  'changePct',
  'daysSinceBest',
  'sessionsSinceBest',
  'maxReps',
  'meanReps',
  'distance',
  'duration',
  'setCount',
  'repCount',
  'trainingDays',
  'latest',
  'first',
  'daysSince',
  'longestStreak',
  'longestGap',
  'meanGap',
  'intake',
  'burned',
  'balance',
];
const _additive = {
  'setCount',
  'repCount',
  'volume',
  'distance',
  'duration',
  'intake',
  'burned',
  'balance',
  'trainingDays',
};
const _noTimeGroup = {
  'latest',
  'first',
  'daysSince',
  'weightChange',
  'changePct',
  'daysSinceBest',
  'sessionsSinceBest',
  'longestStreak',
  'longestGap',
  'meanGap',
};
const _energy = {'intake', 'burned', 'balance'};
const _parts = {
  'chest',
  'back',
  'legs',
  'shoulders',
  'arms',
  'core',
  'cardio',
  'upper',
  'lower',
};
const _periodKeys = {'period', 'days', 'since', 'until'};
const _seriesKeys = {
  ..._periodKeys,
  'exercises',
  'part',
  'shift',
  'sessions',
  'nth',
  'weight',
  'reps',
  'weekdays',
  'hours',
  'set',
  'memo',
  'noMemo',
  'memoAll',
  'together',
  'routine',
  'timer',
  'trained',
  'handoff',
  'measures',
};
const _hoisted = {
  'by',
  'order',
  'limit',
  'total',
  'per',
  'relate',
  'exclude',
  'notComputable',
  'against',
};
const _planKeys = {..._seriesKeys, ..._hoisted, 'kind', 'series'};
const _defaultMeasures = ['best', 'trainingDays', 'latest'];

Never _bad(String why) => throw FormatException(why);

List<String> _strings(Object? v, int max) {
  if (v is! List || v.isEmpty || v.length > max) _bad('bad list $v');
  return [
    for (final s in v)
      if (s is String && s.trim().isNotEmpty && s.trim().length <= 40)
        s.trim()
      else
        _bad('bad string $s'),
  ];
}

int _int(Object? v, int min, int max) =>
    v is int && v >= min && v <= max ? v : _bad('bad number $v');

bool _bool(Object? v) => v is bool ? v : _bad('bad flag $v');

String _pick(Object? v, Iterable<String> options) =>
    v is String && options.contains(v) ? v : _bad('bad option $v');

/// 조건 하나 또는 둘(범위). 단위를 안 적은 무게는 사용자 단위(kg)다.
List<Map<String, Object?>> _bounds(Object? raw, {required bool weight}) {
  final list = raw is List ? raw : [raw];
  if (list.isEmpty || list.length > 2) _bad('bad range');
  final out = <Map<String, Object?>>[];
  for (final b in list) {
    if (b is! Map) _bad('bad bound');
    for (final k in b.keys) {
      if (!{'op', 'value', if (weight) 'unit'}.contains(k)) _bad('bad bound');
    }
    final value = b['value'];
    if (value is! num || !value.isFinite || value < 0 || value > 100000) {
      _bad('bad value');
    }
    if (!weight && value != value.roundToDouble()) _bad('bad reps');
    out.add({
      'op': _pick(b['op'], const ['>=', '>', '<=', '<', '=']),
      'value': value.toDouble(),
      if (weight) 'unit': _pick(b['unit'] ?? 'kg', const ['kg', 'lb']),
    });
  }
  return out..sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));
}

/// 한 덩이(윗단 또는 series 항목)의 모양만 본다. 뜻은 펼친 뒤에 본다.
void _checkSeries(Map<String, Object?> s, Set<String> allowed) {
  for (final k in s.keys) {
    if (!allowed.contains(k)) _bad('unknown key $k');
  }
  if (s.containsKey('exercises')) _strings(s['exercises'], 8);
  if (s.containsKey('part')) _pick(s['part'], _parts);
  if (s.containsKey('period')) {
    _pick(s['period'], const [
      'all',
      'today',
      'yesterday',
      'thisWeek',
      'lastWeek',
      'thisMonth',
      'lastMonth',
      'thisYear',
      'lastYear',
      'recent',
      'custom',
    ]);
  }
  if (s.containsKey('days')) _int(s['days'], 1, 3660);
  if (s['shift'] case final shift?) {
    if (shift is! Map || shift.length != 1) _bad('bad shift');
    final MapEntry(:key, :value) = shift.entries.single;
    final max = const {'days': 3660, 'weeks': 520, 'months': 120, 'years': 10};
    _int(value, 1, max[key] ?? _bad('bad shift unit'));
  }
  if (s.containsKey('sessions')) _int(s['sessions'], 1, 100);
  if (s.containsKey('nth')) _int(s['nth'], 1, 100);
  if (s.containsKey('sessions') && s.containsKey('nth')) _bad('sessions+nth');
  if (s.containsKey('weight')) _bounds(s['weight'], weight: true);
  if (s.containsKey('reps')) _bounds(s['reps'], weight: false);
  if (s['weekdays'] case final days?) {
    if (days is! List || days.isEmpty || days.toSet().length != days.length) {
      _bad('bad weekdays');
    }
    for (final d in days) {
      _int(d, 1, 7);
    }
  }
  if (s['hours'] case final h?) {
    if (h is! Map || h.length != 2) _bad('bad hours');
    final from = _int(h['from'], 0, 24), to = _int(h['to'], 0, 24);
    if (from == to) _bad('empty hours');
  }
  if (s.containsKey('set')) _pick(s['set'], const ['first', 'last']);
  for (final k in const ['memo', 'noMemo', 'memoAll']) {
    if (s.containsKey(k)) _strings(s[k], 8);
  }
  for (final k in const ['together', 'routine', 'trained', 'handoff']) {
    if (s.containsKey(k)) _bool(s[k]);
  }
  if (s.containsKey('timer')) {
    _pick(s['timer'], const ['tabata', 'bpm', 'none']);
  }
  if (s['measures'] case final m?) {
    if (m is! List ||
        m.isEmpty ||
        m.length > 3 ||
        m.toSet().length != m.length) {
      _bad('bad measures $m');
    }
    for (final x in m) {
      _pick(x, planMeasures);
    }
  }
}

/// 앱의 모양 고치기(v2 `_repaired`)와 같다: json_object 껍데기 벗기기,
/// type → kind, series 항목마다 똑같이 적은 plan 키는 위로.
Map<String, Object?> _repaired(Map<String, Object?> m) {
  if (m['type'] == 'json_object' && m.length == 2) {
    final inner = m.entries.firstWhere((e) => e.key != 'type').value;
    if (inner is Map) {
      return _repaired({for (final e in inner.entries) '${e.key}': e.value});
    }
  }
  final type = m['type'];
  if (const {'plan', 'find', 'unrelated', 'clarify'}.contains(type) &&
      (m['kind'] ?? type) == type) {
    m['kind'] = m.remove('type');
  }
  final items = m['series'];
  if (items is List && items.isNotEmpty && items.every((i) => i is Map)) {
    final copies = [
      for (final i in items)
        {for (final e in (i as Map).entries) '${e.key}': e.value},
    ];
    for (final k in _hoisted) {
      if (!copies.every((c) => c.containsKey(k))) continue;
      final value = jsonEncode(copies.first[k]);
      if (copies.any((c) => jsonEncode(c[k]) != value) ||
          (m.containsKey(k) && jsonEncode(m[k]) != value)) {
        continue;
      }
      m[k] = copies.first[k];
      for (final c in copies) {
        c.remove(k);
      }
    }
    m['series'] = copies;
  }
  return m;
}

DateTime? _date(Object? v) {
  if (v == null) return null;
  if (v is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
    _bad('bad date');
  }
  final d = DateTime.parse(v);
  if (_iso(d) != v || d.year < 1900 || d.year > 2100) _bad('bad date $v');
  return d;
}

String? _iso(DateTime? d) => d?.toIso8601String().substring(0, 10);

/// 달·해를 밀면 날을 그달 끝으로 당긴다(3/31 − 1달 = 2/28).
DateTime _monthBack(DateTime x, int months) {
  final first = DateTime(x.year, x.month - months);
  final last = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, math.min(x.day, last));
}

/// 펼친 series 하나의 창 → 날짜. 기간 이름을 풀고, shift 로 민 뒤, 오늘 뒤의
/// 끝은 오늘로 센다(앱이 그렇게 센다 — 뜻이 같은 모양을 같게).
({String? since, String? until}) _window(
  Map<String, Object?> s,
  DateTime today,
) {
  final dated = s.containsKey('since') || s.containsKey('until');
  final period =
      s['period'] ??
      (dated ? 'custom' : (s.containsKey('days') ? 'recent' : 'all'));
  if (s.containsKey('days') && period != 'recent') _bad('days needs recent');
  if (dated && period != 'custom') _bad('dates need custom');
  final d = DateTime(today.year, today.month, today.day);
  DateTime add(int n) => DateTime(d.year, d.month, d.day + n);
  var (from, to) = switch (period) {
    'all' => (null, null),
    'today' => (d, d),
    'yesterday' => (add(-1), add(-1)),
    'thisWeek' => (add(1 - d.weekday), d),
    'lastWeek' => (add(-6 - d.weekday), add(-d.weekday)),
    'thisMonth' => (DateTime(d.year, d.month), d),
    'lastMonth' => (
      DateTime(d.year, d.month - 1),
      DateTime(d.year, d.month, 0),
    ),
    'thisYear' => (DateTime(d.year), d),
    'lastYear' => (DateTime(d.year - 1), DateTime(d.year, 1, 0)),
    'recent' => (add(1 - _int(s['days'] ?? 28, 1, 3660)), d),
    'custom' => (_date(s['since']), _date(s['until'])),
    _ => _bad('bad period'),
  };
  if (period == 'custom' && from == null && to == null) _bad('empty custom');
  if (from != null && to != null && from.isAfter(to)) _bad('reversed dates');
  if (s['shift'] case final Map shift) {
    if (from == null && to == null) _bad('shift needs a window');
    final MapEntry(key: unit, value: n as int) = shift.entries.single;
    DateTime back(DateTime x) => switch (unit) {
      'days' => DateTime(x.year, x.month, x.day - n),
      'weeks' => DateTime(x.year, x.month, x.day - 7 * n),
      'months' => _monthBack(x, n),
      _ => _monthBack(x, 12 * n),
    };
    from = from == null ? null : back(from);
    to = to == null ? null : back(to);
  }
  if (from == null || !from.isAfter(d)) {
    if (to == null || to.isAfter(d)) to = d;
  }
  return (since: _iso(from), until: _iso(to));
}

// ── 이름 ─────────────────────────────────────────────────────────────────

/// 사전의 모든 키(8개 언어 이름·별칭 낱말·초성), 띄어쓰기·대소문자 무시.
final Map<String, Exercise> _dictKeys = () {
  final keys = <String, Exercise>{};
  for (final e in exercises) {
    for (final k in [
      ...e.keys,
      ...e.alias.toLowerCase().split(' ').where((w) => w.length >= 2),
    ]) {
      keys.putIfAbsent(searchKey(k), () => e);
    }
  }
  return keys;
}();

Exercise? _dictionary(String name) => _dictKeys[searchKey(name)];

/// 운동의 정체: 사전 운동이면 그 한국어 이름, 아니면 친 글의 [searchKey].
/// 언어가 달라도 같은 운동이면 같다('Bench Press' = '벤치프레스').
String exerciseIdentity(String name) =>
    _dictionary(name)?.ko ?? searchKey(name);

int _edits(String a, String b) {
  var prev = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final row = [i, ...List<int>.filled(b.length, 0)];
    for (var j = 1; j <= b.length; j++) {
      row[j] = math.min(
        math.min(prev[j] + 1, row[j - 1] + 1),
        prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
      );
    }
    prev = row;
  }
  return prev[b.length];
}

/// 사전 쪽 퍼지의 짧은 이름 규칙(검토 gap 4): 자모 6개 이하(한글 두 음절쯤)는
/// 사전 키와 자모 1개까지만 달라도 된다 — '클린' 이 '크런치' 가 되지 않는다.
bool _near(String raw, Exercise e) {
  final q = jamoOf(searchKey(raw));
  if (q.length > 6) return true;
  return e.keys.any((k) => _edits(q, jamoOf(searchKey(k))) <= 1);
}

/// 문항의 기록: 이름 → 정체. 기록 이름은 앱처럼 운동 열쇠([exerciseKey])로
/// 사전에 잇는다 — 사람이 친 '벤치'·'DL'·'푸시업 60bpm' 은 벤치프레스·
/// 데드리프트·푸시업의 기록이다.
class _Log {
  _Log(this.names, this.lang, [this.app])
    : ids = {for (final n in names) n: exerciseIdentity(exerciseKey(n))};
  final List<String> names;
  final String lang;
  final String Function(String name)? app;
  final Map<String, String> ids;
  late final Set<String> recorded = ids.values.toSet();

  /// 앱의 이름 풀기(설계 §4 + 검토 gap 2·4)를 따른다: 기록 그대로 → 사전 정확
  /// (그 운동을 적었으면 기록으로) → 퍼지(기록과 사전을 함께 겨룸; 기록이
  /// 이기면 그 기록, 사전이 이기면 짧은 이름 규칙을 지날 때만) → 친 그대로.
  /// 정답은 퍼지를 쓰지 않는다 — 정답의 이름은 뜻 그대로다.
  String resolve(String raw, {required bool fuzzy}) {
    final name = raw.trim();
    if (fuzzy && app != null) return exerciseIdentity(app!(name));
    if (ids[name] case final id?) return id;
    if (_dictionary(name) case final e?) return e.ko;
    if (fuzzy) {
      final hit = suggest(name, [...names, ...seedNames(lang)], limit: 1);
      if (hit.isNotEmpty) {
        if (ids[hit.first] case final id?) return id;
        final e = _dictionary(hit.first);
        if (e != null && _near(name, e)) return e.ko;
      }
    }
    return searchKey(name);
  }
}

// ── 모양 ─────────────────────────────────────────────────────────────────

/// 채점할 모양. 정답과 모델 답이 같은 풀이를 지난다:
/// - 모르는 키·목록 밖 값·불변식 위반은 [FormatException](= 무효).
/// - kind: plan | find | unrelated | clarify | nothing(notComputable 만).
/// - 윗단은 series 의 기본값, 기간 네 키는 한 덩이(설계 §3.3). 윗단 이름 여럿은
///   한 줄씩, 이름 × series 는 by exercise(§3.4).
/// - 기간은 [today] 기준 날짜로, 이름은 운동 정체로, 조건은 정규화한 값으로.
/// - notComputable 은 있음/없음만(글은 자유다). never = 기록에 없는 운동.
/// - series 순서는 relate: ratio 일 때만 뜻이다(기준 ÷). 나머지는 정렬한다.
///
/// [names] 는 그 문항의 기록 이름(모델에 간 목록), [question] 은 against 의
/// 수가 글에 있는지 볼 때 쓴다. 정답에는 [fuzzy] 를 끈다. [resolve] 가 있으면
/// 모델 답의 이름은 그것(앱의 이름 풀기)으로 풀어 운동 정체로 견준다.
Map<String, Object?> planShape(
  Object? raw, {
  required List<String> names,
  required String lang,
  String question = '',
  bool fuzzy = true,
  DateTime? today,
  String Function(String name)? resolve,
}) {
  if (raw is! Map) _bad('not an object');
  if (jsonEncode(raw).length > 2000) _bad('too long');
  final log = _Log(names, lang, resolve);
  final m = _repaired({for (final e in raw.entries) '${e.key}': e.value});
  final kind = m['kind'] ?? 'plan';
  switch (kind) {
    case 'unrelated' || 'clarify':
      return {'kind': kind};
    case 'find':
      return {
        'kind': 'find',
        'exercises': [
          for (final n in _strings(m['exercises'], 8))
            log.resolve(n, fuzzy: fuzzy),
        ]..sort(),
      };
    case 'plan':
      break;
    default:
      _bad('bad kind $kind');
  }
  _checkSeries(m, _planKeys);
  if (m.containsKey('notComputable')) _strings(m['notComputable'], 4);
  if (m.keys.every((k) => k == 'kind' || k == 'notComputable') &&
      m.containsKey('notComputable')) {
    return {'kind': 'nothing'};
  }
  final items = switch (m['series']) {
    null => null,
    final List list when list.isNotEmpty && list.length <= 6 => [
      for (final i in list)
        if (i is Map)
          {for (final e in i.entries) '${e.key}': e.value}
        else
          _bad('bad item'),
    ],
    _ => _bad('bad series'),
  };
  for (final i in items ?? const <Map<String, Object?>>[]) {
    _checkSeries(i, _seriesKeys);
  }
  var by = m.containsKey('by')
      ? _pick(m['by'], const [
          'exercise',
          'part',
          'day',
          'week',
          'month',
          'weekday',
        ])
      : null;
  var order = m.containsKey('order')
      ? _pick(m['order'], const ['desc', 'asc'])
      : null;
  var limit = m.containsKey('limit') ? _int(m['limit'], 1, 20) : null;
  final total = m.containsKey('total')
      ? _pick(m['total'], const ['sum', 'mean'])
      : null;
  final per = m.containsKey('per')
      ? _pick(m['per'], const ['day', 'week', 'month'])
      : null;
  final relate = m.containsKey('relate')
      ? _pick(m['relate'], const ['ratio', 'share'])
      : null;
  final exclude = m.containsKey('exclude')
      ? _strings(m['exclude'], 8)
      : const <String>[];

  // 상속: 항목이 기간 키를 하나라도 적으면 윗단의 기간 덩이를 버린다.
  final top = {
    for (final k in _seriesKeys)
      if (m.containsKey(k)) k: m[k],
  };
  var merged = [
    for (final item in items ?? [<String, Object?>{}])
      {
        for (final e in top.entries)
          if (!(item.keys.any(_periodKeys.contains) &&
              _periodKeys.contains(e.key)))
            e.key: e.value,
        ...item,
      },
  ];
  final topNames = top.containsKey('exercises')
      ? _strings(top['exercises'], 8)
      : const [];
  if (items == null && topNames.length >= 2 && by != 'part') {
    merged = [
      for (final n in topNames)
        {
          ...merged.first,
          'exercises': [n],
        },
    ];
    if (by == 'exercise') by = null;
  }
  if (items != null &&
      topNames.length >= 2 &&
      by == null &&
      !items.any((i) => i.containsKey('exercises'))) {
    by = 'exercise';
  }
  final rows = merged.length > 1 || by != null;
  if ((order != null || limit != null || total != null || relate != null) &&
      !rows) {
    _bad('needs rows');
  }
  final grouped = by != null && merged.length > 1;
  List<String> measuresOf(Map<String, Object?> s) => s.containsKey('measures')
      ? [for (final x in s['measures'] as List) x as String]
      : (grouped ? const ['best'] : _defaultMeasures);
  final measures = [for (final s in merged) ...measuresOf(s)];
  final union = measures.toSet();
  if (grouped && merged.any((s) => measuresOf(s).length != 1)) {
    _bad('grouped series need one measure each');
  }
  if (const {'day', 'week', 'month', 'weekday'}.contains(by) &&
      (union.length != 1 || _noTimeGroup.contains(union.single))) {
    _bad('bad time-grouped measure');
  }
  if (per != null &&
      !union.every(
        (x) => _additive.contains(x) && (x != 'trainingDays' || per != 'day'),
      )) {
    _bad('per needs additive');
  }
  if (relate == 'share' && !union.every(_additive.contains)) {
    _bad('share needs additive');
  }
  // 검토 gap 12: 하루에 여러 운동을 하면 운동·부위별 운동일수의 합은 운동한 날보다
  // 크다 — 그 축의 비중은 없다(합계는 서로 다른 날 수로 센다).
  final nameAxis =
      const {'exercise', 'part'}.contains(by) ||
      (by == null &&
          {
                for (final s in merged) jsonEncode([s['exercises'], s['part']]),
              }.length >
              1);
  if (relate == 'share' && union.contains('trainingDays') && nameAxis) {
    _bad('trainingDays share on an exercise axis');
  }
  if (total != null && union.any((x) => x == 'latest' || x == 'first')) {
    _bad('dates cannot be totalled');
  }
  if (union.length > 4) _bad('too many columns');
  for (final s in merged) {
    final ms = measuresOf(s).toSet();
    if (ms.any(_energy.contains) &&
        (const {'exercise', 'part'}.contains(by) || s.containsKey('hours'))) {
      _bad('energy measures: no exercise/part groups, no hours');
    }
    if (s.containsKey('trained') && !ms.every(_energy.contains)) {
      _bad('trained is for intake/burned/balance only');
    }
  }
  Map<String, Object?>? against;
  if (m['against'] case final a?) {
    if (a is! Map || a.keys.any((k) => k != 'value' && k != 'unit')) {
      _bad('bad against');
    }
    final value = a['value'];
    if (value is! num || value <= 0 || value > 100000) {
      _bad('bad against value');
    }
    // 사용자가 준 수와만 견준다 — 글에 없는 수는 지어낸 것이다(검토 gap 16).
    if (question.isNotEmpty &&
        !RegExp(r'\d+(?:[.,]\d+)?')
            .allMatches(question)
            .any((x) => double.parse(x[0]!.replaceAll(',', '.')) == value)) {
      _bad('against value not in the question');
    }
    if (!union.every(const {'best', 'e1rm', 'meanWeight'}.contains) &&
        total != 'sum') {
      _bad('against needs a weight measure or a sum');
    }
    against = {
      'value': value.toDouble(),
      'unit': _pick(a['unit'] ?? 'kg', const ['kg', 'lb']),
    };
  }

  // 풀기.
  Map<String, Object?> shapeOf(Map<String, Object?> s) {
    final w = _window(s, today ?? evalToday);
    final hours = s['hours'] as Map?;
    final nth = s['nth'] as int?;
    return {
      if (s.containsKey('exercises'))
        'exercises': [
          for (final n in _strings(s['exercises'], 8))
            log.resolve(n, fuzzy: fuzzy),
        ]..sort(),
      'part': s['part'],
      'since': w.since,
      'until': w.until,
      // 끝에서 1번째 운동일 = 마지막 1일.
      'sessions': s['sessions'] ?? (nth == 1 ? 1 : null),
      'nth': nth == 1 ? null : nth,
      if (s.containsKey('weight')) 'weight': _bounds(s['weight'], weight: true),
      if (s.containsKey('reps')) 'reps': _bounds(s['reps'], weight: false),
      if (s['weekdays'] case final List days) 'weekdays': [...days]..sort(),
      if (hours != null)
        'hours': {
          'from': hours['from'],
          // [22, 0) 은 [22, 24) 다.
          'to': hours['to'] == 0 && (hours['from'] as int) > 0
              ? 24
              : hours['to'],
        },
      for (final k in const [
        'set',
        'memo',
        'noMemo',
        'memoAll',
        'together',
        'routine',
        'timer',
        'trained',
        'handoff',
      ])
        k: s[k],
      'measures': measuresOf(s),
    }..removeWhere((_, v) => v == null);
  }

  final series = [for (final s in merged) shapeOf(s)];
  final encoded = [for (final s in series) jsonEncode(s)];
  if (encoded.toSet().length != encoded.length) _bad('two series are the same');
  if (relate != 'ratio') {
    series.sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));
  }
  // 지목하지 않은 운동 줄은 첫 칸으로 내림차순, 10줄이다(앱 기본값). limit 만
  // 적었으면 desc 다.
  if (limit != null) order ??= 'desc';
  if (by == 'exercise' && !merged.any((s) => s.containsKey('exercises'))) {
    order ??= 'desc';
    limit ??= 10;
  }
  final ids = {
    for (final s in series) ...?(s['exercises'] as List?)?.cast<String>(),
  };
  return {
    'kind': 'plan',
    'series': series,
    'by': by,
    'order': order,
    'limit': limit,
    'total': total,
    'per': per,
    'relate': relate,
    'exclude': [for (final n in exclude) log.resolve(n, fuzzy: fuzzy)]..sort(),
    'against': against,
    'notComputable': m.containsKey('notComputable'),
    'never': [
      for (final id in ids)
        if (!log.recorded.contains(id)) id,
    ]..sort(),
  };
}

// ── 채점 ─────────────────────────────────────────────────────────────────

/// 메모는 자유 글이다: 정답의 어간마다 모델의 어간 하나가 그것을 담거나 그것에
/// 담기면 맞다('컨디션' ↔ '컨디션 안 좋'). 모델이 어간을 더 적어도 된다(v2).
bool _memoSame(Object? want, Object? got) =>
    want is List &&
    got is List &&
    want.every(
      (w) => got.any((g) => '$g'.contains('$w') || '$w'.contains('$g')),
    );

/// 시간대 경계는 한 시간까지 같은 뜻이다(아침 5–11 ↔ 6–11).
bool _hoursSame(Object? want, Object? got) =>
    want is Map &&
    got is Map &&
    ((want['from'] as int) - (got['from'] as int)).abs() <= 1 &&
    ((want['to'] as int) - (got['to'] as int)).abs() <= 1;

bool _fieldSame(
  String key,
  Object? want,
  Object? got, {
  required bool ordered,
}) {
  if (want == null || got == null) return want == got;
  return switch (key) {
    'memo' || 'noMemo' || 'memoAll' => _memoSame(want, got),
    'hours' => _hoursSame(want, got),
    // 순위가 있으면 첫 측정이 정렬 열쇠라 순서가 뜻이다. 없으면 칸 순서일 뿐.
    'measures' when !ordered =>
      jsonEncode(([...want as List]..sort())) ==
          jsonEncode(([...got as List]..sort())),
    _ => jsonEncode(want) == jsonEncode(got),
  };
}

Iterable<List<int>> _permutations(int n) sync* {
  if (n == 0) {
    yield const [];
    return;
  }
  for (final p in _permutations(n - 1)) {
    for (var i = 0; i <= p.length; i++) {
      yield [...p.sublist(0, i), n - 1, ...p.sublist(i)];
    }
  }
}

/// 두 모양의 틀린 키. series 안의 키는 'series.measures' 처럼 적는다. series
/// 순서만 틀렸으면(relate: ratio) 'seriesOrder' 하나다.
List<String> shapeErrors(
  Map<String, Object?> want,
  Map<String, Object?> got, {
  Iterable<Object?> ignore = const [],
}) {
  bool skip(String k) => ignore.contains(k);
  if (want['kind'] != got['kind']) return const ['kind'];
  final errors = <String>[
    for (final k in const [
      'exercises',
      'by',
      'order',
      'limit',
      'total',
      'per',
      'relate',
      'exclude',
      'against',
      'notComputable',
    ])
      if (!skip(k) && jsonEncode(want[k]) != jsonEncode(got[k])) k,
  ];
  if (want['kind'] != 'plan') return errors;
  final ws = (want['series'] as List).cast<Map<String, Object?>>();
  final gs = (got['series'] as List).cast<Map<String, Object?>>();
  if (ws.length != gs.length) return [...errors, 'series'];
  final ordered = want['order'] != null;
  List<String> diff(List<int> p) => {
    for (var i = 0; i < ws.length; i++)
      for (final k in {...ws[i].keys, ...gs[p[i]].keys})
        if (!skip(k) && !_fieldSame(k, ws[i][k], gs[p[i]][k], ordered: ordered))
          'series.$k',
  }.toList();
  List<String>? best;
  for (final p in _permutations(ws.length)) {
    final d = diff(p);
    if (best == null || d.length < best.length) best = d;
    if (d.isEmpty) break;
  }
  final inOrder = diff([for (var i = 0; i < ws.length; i++) i]);
  if (want['relate'] == 'ratio' &&
      got['relate'] == 'ratio' &&
      inOrder.isNotEmpty) {
    return [
      ...errors,
      ...(best!.isEmpty ? const ['seriesOrder'] : inOrder),
    ];
  }
  return [...errors, ...best!];
}

/// 채점 결과. [want] 는 가장 가까운 정답 대안의 모양이다.
typedef Grade = ({
  List<String> errors,
  Map<String, Object?> got,
  Map<String, Object?> want,
  bool goldCountable,
});

/// 모델 답 하나를 정답 대안들과 견준다. 모델 답이 무효면 [FormatException].
/// 정답 대안이 무효면 [StateError] — 정답을 고쳐야 한다.
Grade gradePlan(
  Object? plan,
  List<Object?> gold, {
  required List<String> names,
  required String lang,
  String question = '',
  Iterable<Object?> ignore = const [],
  String Function(String name)? resolve,
}) {
  final got = planShape(
    plan,
    names: names,
    lang: lang,
    question: question,
    resolve: resolve,
  );
  final wants = [
    for (final g in gold)
      () {
        try {
          return planShape(
            g,
            names: names,
            lang: lang,
            question: question,
            fuzzy: false,
          );
        } on FormatException catch (e) {
          throw StateError('invalid gold $g: ${e.message}');
        }
      }(),
  ];
  if (wants.isEmpty) throw StateError('no gold');
  ({List<String> errors, Map<String, Object?> want})? closest;
  for (final w in wants) {
    final e = shapeErrors(w, got, ignore: ignore);
    if (closest == null || e.length < closest.errors.length) {
      closest = (errors: e, want: w);
    }
  }
  return (
    errors: closest!.errors,
    got: got,
    want: closest.want,
    goldCountable: wants.every((w) => w['kind'] == 'plan'),
  );
}

/// 정답 대안이 모두 셀 plan 인가 — 그런 질문에 답이 없으면 막다른 길이다.
bool goldCountable(
  List<Object?> gold, {
  required List<String> names,
  required String lang,
  String question = '',
}) => gold.every(
  (g) =>
      planShape(
        g,
        names: names,
        lang: lang,
        question: question,
        fuzzy: false,
      )['kind'] ==
      'plan',
);

/// 규칙 층의 바꿔치기: 앱이 센 plan([Grade.got])에 모델 답([raw])도, 가장 가까운
/// 정답도 말하지 않은 **기록한** 운동이 들어왔다. 모델의 {"by":"exercise"} 가
/// 글의 낱말 퍼지로 한 운동이 되는 것('chung' → 런지)이 이것이다.
bool ruleSwapped(
  Object? raw,
  Grade grade, {
  required List<String> names,
  required String lang,
  String question = '',
  String Function(String name)? resolve,
}) {
  final Map<String, Object?> model;
  try {
    model = planShape(
      raw,
      names: names,
      lang: lang,
      question: question,
      resolve: resolve,
    );
  } on FormatException {
    return false;
  }
  final never = {...?(grade.got['never'] as List?)?.cast<String>()};
  return _ids(grade.got)
      .difference(never)
      .difference(_ids(model))
      .difference(_ids(grade.want))
      .isNotEmpty;
}

Set<String> _ids(Map<String, Object?> shape) => {
  ...?(shape['exercises'] as List?)?.cast<String>(),
  for (final s in (shape['series'] as List?) ?? const [])
    ...?((s as Map)['exercises'] as List?)?.cast<String>(),
};

/// 문항 하나의 판정. 지표 정의(설계 §12.3 + 검토 gap 4):
/// - exact: 가장 가까운 대안과 모양이 같다.
/// - refused: 거절(unrelated·clarify·notComputable 만).
/// - deadEnd: 정답 대안이 모두 셀 series 를 가졌는데 거절했다(문턱 0).
/// - confidentlyWrong: 틀렸는데 숫자를 보일 답(plan·find)이다.
/// - swapped: 정답의 never 운동이 빠지고 기록의 다른 운동이 들어왔다(문턱 0).
/// - falseNever: 정답의 기록 운동이 빠지고 never 이름이 들어왔다.
/// - dictSwap: 정답의 never 운동이 빠지고 다른 never 이름이 들어왔다.
/// - ncMissed / ncFalse: 못 보는 것 한 줄을 빠뜨림 / 정답에 없는데 냄.
Set<String> verdicts(Grade g) {
  final want = g.want, got = g.got;
  final refused = const {
    'unrelated',
    'clarify',
    'nothing',
  }.contains(got['kind']);
  final wantIds = _ids(want), gotIds = _ids(got);
  final wantNever = {...?(want['never'] as List?)?.cast<String>()};
  final gotNever = {...?(got['never'] as List?)?.cast<String>()};
  final lostNever = wantNever.difference(gotIds);
  final lostRecorded = wantIds.difference(wantNever).difference(gotIds);
  final newRecorded = gotIds.difference(gotNever).difference(wantIds);
  final newNever = gotNever.difference(wantNever);
  final wantNc = want['notComputable'] == true,
      gotNc = got['notComputable'] == true;
  return {
    if (g.errors.isEmpty) 'exact',
    if (refused) 'refused',
    if (refused && g.goldCountable) 'deadEnd',
    if (g.errors.isNotEmpty && !refused) 'confidentlyWrong',
    if (lostNever.isNotEmpty && newRecorded.isNotEmpty) 'swapped',
    if (lostRecorded.isNotEmpty && newNever.isNotEmpty) 'falseNever',
    if (lostNever.isNotEmpty && newNever.isNotEmpty) 'dictSwap',
    if (wantNc && !gotNc) 'ncMissed',
    if (!wantNc && gotNc) 'ncFalse',
  };
}

// ── 옛 모음의 정답 ─────────────────────────────────────────────────────────

/// v2 정답(contract 2) → v3 대안들(설계 §12.3). compare 는 series 가 된다.
/// 날·주·달 묶음의 평균(total: mean)은 per 로도 받는다(설계 §5.5 — 같은 수).
/// 기계로 옮길 수 없는 문항(kind missing, 부위 clarify, OR 조건 clarify)은
/// v2.json 이 그 문항에 "v3" 로 적은 정답을 쓴다.
List<Object?> v3Gold(Map<String, Object?> c) =>
    (c['v3'] as List?) ?? v3Alternatives(c['gold'] as List);

List<Object?> v3Alternatives(List<Object?> gold) => [
  for (final g in gold.cast<Map>())
    ...() {
      final plan = {
        for (final e in g.entries)
          (e.key == 'compare' ? 'series' : '${e.key}'): e.value,
      };
      final by = plan['by'], measures = plan['measures'];
      final perPlan =
          plan['total'] == 'mean' &&
              const {'day', 'week', 'month'}.contains(by) &&
              !plan.containsKey('order') &&
              !plan.containsKey('limit') &&
              measures is List &&
              measures.length == 1 &&
              _additive.contains(measures.single) &&
              !(measures.single == 'trainingDays' && by == 'day')
          ? {
              for (final e in plan.entries)
                if (e.key != 'by' && e.key != 'total') e.key: e.value,
              'per': by,
            }
          : null;
      return [plan, ?perPlan];
    }(),
];

/// v1 측정 이름 → 모델이 쓰는 이름.
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

/// v1 정답(운동 하나·측정 하나·기간·이상/이하 조건)을 정답 대안으로.
/// `gold` 가 적힌 문장(두 운동, 초과)은 그것을 쓴다. null 은 채점하지
/// 않는다는 뜻이다(초성 두 글자처럼 관찰만 하는 문장). v3 에서도 그대로
/// 맞는 모양이다(compare 가 없다).
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
    // "요즘 어때" 는 지시문에서 최근 28일이다. 규칙 층은 이 낱말을
    // 기간으로 읽지 않으니 둘 다 맞다.
    if (expected['orRecent'] == true) {...gold, 'period': 'recent', 'days': 28},
  ];
}
