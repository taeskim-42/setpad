/// 운동 기록 텍스트를 읽는 부분. 화면과 분리해 둔 이유는 여기가 이 앱에서
/// 유일하게 틀릴 수 있는 곳이고, 화면 없이 테스트할 수 있어야 해서다.
library;

import 'exercises.dart';
import 'units.dart';

/// 친 글자에 맞는 후보를 순위대로.
///
/// 앞글자 일치가 먼저다 — "벤"을 친 사람이 원하는 건 벤치프레스지
/// 이름 안쪽에 '벤'이 든 무언가가 아니다. 그래도 안쪽 일치를 버리지는 않아서
/// "덤벨"로 "인클라인 덤벨 프레스"를 찾을 수 있다.
///
/// 화면 언어와 상관없이 여덟 언어와 초성을 전부 받는다 — 사전에 있는 운동은
/// 어느 이름으로 쳐도 찾히고, 나오는 건 화면 언어의 이름이다.
List<String> suggest(
  String query,
  List<String> pool, {
  int limit = 6,
  List<String> preferred = const [],
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final scored = <({String name, int rank})>[];
  for (final name in pool.toSet()) {
    // 한글 이름과 영어 검색 키 중 더 좋은 쪽을 그 운동의 점수로 삼는다.
    int? rank;
    for (final key
        in exerciseByName[name.toLowerCase()]?.keys ??
            [name.toLowerCase(), chosungOf(name.toLowerCase())]) {
      final r = _rank(key, q);
      if (r != null && (rank == null || r < rank)) rank = r;
    }
    if (rank != null) scored.add((name: name, rank: rank));
  }

  scored.sort((a, b) {
    final byRank = a.rank.compareTo(b.rank);
    if (byRank != 0) return byRank;
    final ai = preferred.indexOf(a.name), bi = preferred.indexOf(b.name);
    final recent = (ai < 0 ? preferred.length : ai).compareTo(
      bi < 0 ? preferred.length : bi,
    );
    return recent != 0 ? recent : a.name.length.compareTo(b.name.length);
  });
  return scored.take(limit).map((e) => e.name).toList();
}

int? _rank(String key, String q) {
  if (key == q) return 0;
  if (key.startsWith(q)) return 1;
  if (key.split(RegExp(r'\s+')).any((w) => w.startsWith(q))) return 2;
  if (key.contains(q)) return 3;

  // 여기부터는 **덜 정확해도 보여주는** 단계다. 위 네 줄에 걸리는 것이 있으면
  // 늘 먼저 오므로, 잘 되던 검색의 순서는 그대로다.

  // 공백만 다른 경우. "benchpress" 처럼 붙여 치는 사람이 많고, 한글 이름도
  // "벤치 프레스" 와 "벤치프레스" 가 섞인다.
  final bare = searchKey(key), compactQuery = searchKey(q);
  if (bare == compactQuery) return 0;
  if (bare.startsWith(compactQuery)) return 4;
  if (bare.contains(compactQuery)) return 5;
  final words = q
      .split(RegExp(r'[\s\-_]+'))
      .where((s) => s.isNotEmpty)
      .toList();
  if (words.length > 1 && words.every((word) => bare.contains(searchKey(word)))) {
    return 5;
  }

  // 오타. 자모로 풀어 **비율**로 잰다 — 몇 글자가 아니라 얼마나 틀렸는지다.
  //
  // 길이도 자모로 잰다. String.length 는 UTF-16 낱개를 세므로 한글에서
  // 뜻대로 안 움직인다 — '스퀏' 이 2 로 나와 짧은 질의로 걸러졌었다.
  final jq = jamoOf(compactQuery);
  if (jq.length < 4) return null;
  final budget = (jq.length * _typoRatio).floor();
  if (budget == 0) return null;
  final d = _typoDistance(jamoOf(bare), jq, budget);
  return d == null ? null : 6 + d;
}

String searchKey(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[\s\-_·]+'), '');

/// Retrieve a bounded name reference for local generation, including personal names.
List<String> retrieveExercises(
  String input,
  List<String> pool, {
  int limit = 8,
}) {
  final found = <String>{...suggest(input, pool, limit: limit)};
  final compact = searchKey(input);
  for (final name in pool) {
    final keys = exerciseByName[name.toLowerCase()]?.keys ?? [name];
    if (keys.any(
      (key) => searchKey(key).length >= 2 && compact.contains(searchKey(key)),
    )) {
      found.add(name);
    }
  }
  for (final word in input.split(RegExp(r'\s+'))) {
    if (word.length >= 2 && !RegExp(r'\d').hasMatch(word)) {
      found.addAll(suggest(word, pool, limit: 3));
    }
  }
  return found.take(limit).toList();
}

/// 친 자모의 몇 할까지 틀려도 후보로 올릴 것인가. 3분의 1을 넘으면 그건
/// 오타가 아니라 다른 말이다 — 재보니 이 값에서 '스퀏→스쿼트'는 잡히고
/// 'ㅋㅋ' 같은 잡음은 걸러진다.
const _typoRatio = 0.34;

/// 친 글자가 [key]의 **어느 앞부분**과 몇 글자 다른가. [max]를 넘으면 null.
///
/// 앞부분과 견주는 이유는 사람이 이름을 끝까지 치지 않아서다 — "bech" 는
/// "benchpress" 전체가 아니라 "bench" 를 겨눈 것이고, 그 사이가 한 글자다.
/// 자리바꿈(bnech→bench)을 한 번으로 세는 것도 그게 가장 흔한 오타라서다.
int? _typoDistance(String key, String q, int max) {
  if (key.length + max < q.length) return null;
  // row[j] = q 를 다 쓰고 key 를 j 까지 썼을 때의 거리.
  var prev2 = <int>[];
  var prev = List<int>.generate(key.length + 1, (j) => j);
  for (var i = 1; i <= q.length; i++) {
    final row = List<int>.filled(key.length + 1, 0);
    row[0] = i;
    var best = i;
    for (var j = 1; j <= key.length; j++) {
      final cost = q.codeUnitAt(i - 1) == key.codeUnitAt(j - 1) ? 0 : 1;
      var v = prev[j] + 1;
      if (row[j - 1] + 1 < v) v = row[j - 1] + 1;
      if (prev[j - 1] + cost < v) v = prev[j - 1] + cost;
      // 자리바꿈 한 번.
      if (i > 1 &&
          j > 1 &&
          q.codeUnitAt(i - 1) == key.codeUnitAt(j - 2) &&
          q.codeUnitAt(i - 2) == key.codeUnitAt(j - 1) &&
          prev2[j - 2] + 1 < v) {
        v = prev2[j - 2] + 1;
      }
      row[j] = v;
      if (v < best) best = v;
    }
    // 이 줄이 통째로 한도를 넘었으면 더 가도 줄지 않는다.
    if (best > max) return null;
    prev2 = prev;
    prev = row;
  }
  // key 를 어디까지 쓰든 상관없다 — 이름을 끝까지 치지 않은 것뿐이다.
  final best = prev.reduce((a, b) => a < b ? a : b);
  return best <= max ? best : null;
}

class ParsedSet {
  const ParsedSet({
    this.value,
    this.unit,
    this.reps,
    this.note,
    this.count = 1,
  });

  /// 무게든 거리든 시간이든, 친 숫자 그대로. 단위는 [unit] 이 들고 있다.
  final double? value;

  /// 친 단위. 안 쳤으면 null 이고, 쓰는 쪽이 기본값을 정한다.
  final String? unit;
  final int? reps;

  /// 숫자를 다 먹고 남은 것. 외울 구분자가 없다는 게 요점이다.
  final String? note;

  /// 같은 세트를 몇 번 반복하는지. "x5", "5세트".
  final int count;

  @override
  String toString() =>
      'ParsedSet(value: $value, unit: $unit, reps: $reps, note: $note, count: $count)';

  @override
  bool operator ==(Object other) =>
      other is ParsedSet &&
      other.value == value &&
      other.unit == unit &&
      other.reps == reps &&
      other.note == note &&
      other.count == count;

  @override
  int get hashCode => Object.hash(value, unit, reps, note, count);
}

/// 세트 수와 횟수를 뜻하는 말. 무게·거리·시간 단위는 units.dart 가 쥔다.
const _counters =
    '세트|set|sets|セット|组|組|serie|series|hiệp|เซ็ต|'
    '회|개|rep|reps|回|次|lần|ครั้ง|veces';

final _units = '$unitPattern|$_counters';

final _unit = RegExp(
  '^(\\d+(?:\\.\\d+)?)\\s*($_units)\$',
  caseSensitive: false,
);

/// 숫자와 단위를 띄어 쓰는 언어가 있다 — "10 lần", "100 kg". 붙여 놓고
/// 시작해야 한 토큰으로 읽힌다.
final _spacedUnit = RegExp(
  '(\\d)\\s+($_units)(?=\\s|\$)',
  caseSensitive: false,
);
final _repeat = RegExp(r'^[x×*](\d+)$', caseSensitive: false);
final _bare = RegExp(r'^\d+(?:\.\d+)?$');

/// 세트 한 줄을 읽는다. "100kg 20회 마지막 힘들었음", "20회", "100 20 x3".
///
/// 단위는 선택이다 — 운동 중에 단위를 꼬박꼬박 붙이는 사람은 없다. 단위가
/// 없으면 첫 숫자가 무게, 둘째가 횟수다. 다만 숫자가 하나뿐이면 항상 횟수로
/// 읽는다. 맨몸 운동이 그렇게 적히기 때문이다.
ParsedSet? parseSetLine(String line) {
  final text = line.trim().replaceAllMapped(
    _spacedUnit,
    (m) => '${m[1]}${m[2]}',
  );
  if (text.isEmpty) return null;

  double? value;
  String? unit;
  int? reps;
  var count = 1;
  final bare = <double>[];
  final rest = <String>[];

  for (final token in text.split(RegExp(r'\s+'))) {
    final m = _unit.firstMatch(token);
    if (m != null) {
      final n = double.parse(m.group(1)!);
      final word = m.group(2)!.toLowerCase();
      final known = unitOf(word);
      if (known != null) {
        // 친 단위를 그대로 남긴다. 예전에는 lb 를 kg 로 바꿔 저장해서
        // 파운드로 하는 사람의 숫자가 사라졌다.
        value = n;
        unit = known;
      } else if (RegExp(
        '^($_counters)\$',
        caseSensitive: false,
      ).hasMatch(word)) {
        if (RegExp(
          r'^(세트|set|sets|セット|组|組|serie|series|hiệp|เซ็ต)$',
          caseSensitive: false,
        ).hasMatch(word)) {
          count = n.round();
        } else {
          reps = n.round();
        }
      }
      continue;
    }
    final repeat = _repeat.firstMatch(token);
    if (repeat != null) {
      count = int.parse(repeat.group(1)!);
      continue;
    }
    if (_bare.hasMatch(token)) {
      bare.add(double.parse(token));
      continue;
    }
    rest.add(token);
  }

  for (final n in bare) {
    if (value == null && reps == null && bare.length > 1) {
      value = n;
    } else if (reps == null) {
      reps = n.round();
    } else {
      value ??= n;
    }
  }

  if (value == null && reps == null) return null;
  count = count.clamp(1, 20);

  return ParsedSet(
    value: value,
    unit: unit,
    reps: reps,
    note: rest.isEmpty ? null : rest.join(' '),
    count: count,
  );
}

/// "100kg · 20회" / "100kg · 20 reps"
///
/// 횟수 단위는 화면 언어를 타므로 밖에서 넣는다(L.repsCount). 기본값은
/// 한국어 — 파서만 떼어 테스트할 때 화면을 세우지 않아도 되게.
String _koReps(int n) => '$n회';

String setLabel({
  double? value,
  String? unit,
  int? reps,
  String Function(int n) formatReps = _koReps,
}) => [
  if (value != null) formatValue(value, unit ?? defaultUnit),
  if (reps != null) formatReps(reps),
].join(' · ');

/// 치고 있는 줄의 **마지막 숫자**를 한 단계 민다.
///
/// 칸이 나뉘어 있지 않으니 어느 숫자를 밀지 정해야 한다. 지금 치고 있는 것,
/// 곧 맨 뒤의 숫자다. 단위는 그 앞을 보고 안다 — "100kg 20" 의 20 은 횟수라
/// 1씩, "100" 은 무게라 원판 단위인 2.5씩 움직인다.
///
/// 숫자가 아예 없으면 무게 한 단계를 세워 준다.
String bumpLastNumber(String line, int direction) {
  final match = RegExp(r'(\d+(?:\.\d+)?)(\s*)$').firstMatch(line);
  if (match == null) {
    final seed = direction > 0 ? 2.5 : 0.0;
    return seed == 0
        ? line
        : '${line.trimRight()}${line.isEmpty ? '' : ' '}2.5';
  }

  final before = line.substring(0, match.start);
  // 이 숫자 앞에 무게 단위가 이미 나왔으면, 이건 횟수 자리다.
  final isReps = RegExp(
    r'(kg|킬로|파운드|lb)\s*$',
    caseSensitive: false,
  ).hasMatch(before.trimRight().isEmpty ? '' : before);
  final step = isReps ? 1.0 : 2.5;

  final current = double.parse(match.group(1)!);
  final next = (current + direction * step).clamp(0, 9999);
  if (next == 0) {
    return before.trimRight() + (before.trimRight().isEmpty ? '' : ' ');
  }

  final text = next == next.roundToDouble()
      ? next.round().toString()
      : next.toStringAsFixed(1);
  return '$before$text${match.group(2)}';
}
