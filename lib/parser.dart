/// 운동 기록 텍스트를 읽는 부분. 화면과 분리해 둔 이유는 여기가 이 앱에서
/// 유일하게 틀릴 수 있는 곳이고, 화면 없이 테스트할 수 있어야 해서다.
library;

import 'exercises.dart';

/// 친 글자에 맞는 후보를 순위대로.
///
/// 앞글자 일치가 먼저다 — "벤"을 친 사람이 원하는 건 벤치프레스지
/// 이름 안쪽에 '벤'이 든 무언가가 아니다. 그래도 안쪽 일치를 버리지는 않아서
/// "덤벨"로 "인클라인 덤벨 프레스"를 찾을 수 있다.
///
/// 화면 언어와 상관없이 여덟 언어와 초성을 전부 받는다 — 사전에 있는 운동은
/// 어느 이름으로 쳐도 찾히고, 나오는 건 화면 언어의 이름이다.
List<String> suggest(String query, List<String> pool, {int limit = 6}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final scored = <({String name, int rank})>[];
  for (final name in pool) {
    // 한글 이름과 영어 검색 키 중 더 좋은 쪽을 그 운동의 점수로 삼는다.
    int? rank;
    for (final key in exerciseByName[name.toLowerCase()]?.keys ??
        [name.toLowerCase()]) {
      final r = _rank(key, q);
      if (r != null && (rank == null || r < rank)) rank = r;
    }
    if (rank != null) scored.add((name: name, rank: rank));
  }

  scored.sort((a, b) {
    final byRank = a.rank.compareTo(b.rank);
    return byRank != 0 ? byRank : a.name.length.compareTo(b.name.length);
  });
  return scored.take(limit).map((e) => e.name).toList();
}

int? _rank(String key, String q) {
  if (key == q) return 0;
  if (key.startsWith(q)) return 1;
  if (key.split(RegExp(r'\s+')).any((w) => w.startsWith(q))) return 2;
  if (key.contains(q)) return 3;
  return null;
}

class ParsedSet {
  const ParsedSet({this.kg, this.reps, this.note, this.count = 1});

  final double? kg;
  final int? reps;

  /// 숫자를 다 먹고 남은 것. 외울 구분자가 없다는 게 요점이다.
  final String? note;

  /// 같은 세트를 몇 번 반복하는지. "x5", "5세트".
  final int count;

  @override
  String toString() => 'ParsedSet(kg: $kg, reps: $reps, note: $note, count: $count)';

  @override
  bool operator ==(Object other) =>
      other is ParsedSet &&
      other.kg == kg &&
      other.reps == reps &&
      other.note == note &&
      other.count == count;

  @override
  int get hashCode => Object.hash(kg, reps, note, count);
}

/// 여덟 언어의 단위어. 어느 언어로 치든 같은 뜻으로 읽는다.
const _units = 'kg|킬로|kilo|kilos|lb|lbs|파운드|'
    '세트|set|sets|セット|组|組|serie|series|hiệp|เซ็ต|'
    '회|개|rep|reps|回|次|lần|ครั้ง|veces';

final _unit = RegExp('^(\\d+(?:\\.\\d+)?)\\s*($_units)\$',
    caseSensitive: false);

/// 숫자와 단위를 띄어 쓰는 언어가 있다 — "10 lần", "100 kg". 붙여 놓고
/// 시작해야 한 토큰으로 읽힌다.
final _spacedUnit =
    RegExp('(\\d)\\s+($_units)(?=\\s|\$)', caseSensitive: false);
final _repeat = RegExp(r'^[x×*](\d+)$', caseSensitive: false);
final _bare = RegExp(r'^\d+(?:\.\d+)?$');

/// 세트 한 줄을 읽는다. "100kg 20회 마지막 힘들었음", "20회", "100 20 x3".
///
/// 단위는 선택이다 — 운동 중에 단위를 꼬박꼬박 붙이는 사람은 없다. 단위가
/// 없으면 첫 숫자가 무게, 둘째가 횟수다. 다만 숫자가 하나뿐이면 항상 횟수로
/// 읽는다. 맨몸 운동이 그렇게 적히기 때문이다.
ParsedSet? parseSetLine(String line) {
  final text = line
      .trim()
      .replaceAllMapped(_spacedUnit, (m) => '${m[1]}${m[2]}');
  if (text.isEmpty) return null;

  double? kg;
  int? reps;
  var count = 1;
  final bare = <double>[];
  final rest = <String>[];

  for (final token in text.split(RegExp(r'\s+'))) {
    final unit = _unit.firstMatch(token);
    if (unit != null) {
      final value = double.parse(unit.group(1)!);
      switch (unit.group(2)!.toLowerCase()) {
        case 'kg' || '킬로' || 'kilo' || 'kilos':
          kg = value;
        case 'lb' || 'lbs' || '파운드':
          kg = (value * 0.4536 * 10).round() / 10;
        case '세트' || 'set' || 'sets' || 'セット' || '组' || '組' ||
              'serie' || 'series' || 'hiệp' || 'เซ็ต':
          count = value.round();
        default:
          reps = value.round();
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

  for (final value in bare) {
    if (kg == null && reps == null && bare.length > 1) {
      kg = value;
    } else if (reps == null) {
      reps = value.round();
    } else {
      kg ??= value;
    }
  }

  if (kg == null && reps == null) return null;
  count = count.clamp(1, 20);

  return ParsedSet(
    kg: kg,
    reps: reps,
    note: rest.isEmpty ? null : rest.join(' '),
    count: count,
  );
}

/// 소수점이 필요 없으면 떼고 보여준다. 100.0kg은 아무도 그렇게 안 읽는다.
String formatKg(double kg) =>
    kg == kg.roundToDouble() ? '${kg.round()}kg' : '${kg}kg';

/// "100kg · 20회" / "100kg · 20 reps"
///
/// 횟수 단위는 화면 언어를 타므로 밖에서 넣는다(L.repsCount). 기본값은
/// 한국어 — 파서만 떼어 테스트할 때 화면을 세우지 않아도 되게.
String _koReps(int n) => '$n회';

String setLabel({
  double? kg,
  int? reps,
  String Function(int n) formatReps = _koReps,
}) =>
    [
      if (kg != null) formatKg(kg),
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
    return seed == 0 ? line : '${line.trimRight()}${line.isEmpty ? '' : ' '}2.5';
  }

  final before = line.substring(0, match.start);
  // 이 숫자 앞에 무게 단위가 이미 나왔으면, 이건 횟수 자리다.
  final isReps = RegExp(r'(kg|킬로|파운드|lb)\s*$', caseSensitive: false)
      .hasMatch(before.trimRight().isEmpty ? '' : before);
  final step = isReps ? 1.0 : 2.5;

  final current = double.parse(match.group(1)!);
  final next = (current + direction * step).clamp(0, 9999);
  if (next == 0) return before.trimRight() + (before.trimRight().isEmpty ? '' : ' ');

  final text = next == next.roundToDouble()
      ? next.round().toString()
      : next.toStringAsFixed(1);
  return '$before$text${match.group(2)}';
}
