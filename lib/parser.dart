/// 운동 기록 텍스트를 읽는 부분. 화면과 분리해 둔 이유는 여기가 이 앱에서
/// 유일하게 틀릴 수 있는 곳이고, 화면 없이 테스트할 수 있어야 해서다.
library;

/// 새 헬스장이 첫날부터 이름을 다 타이핑하지 않도록 하는 씨앗 목록.
/// 마스터 테이블이 아니다 — 실제 어휘는 사용자가 친 이름에서 자란다.
const seedExercises = <String>[
  // 가슴
  '벤치프레스', '인클라인 벤치프레스', '디클라인 벤치프레스', '덤벨 프레스',
  '인클라인 덤벨 프레스', '체스트 프레스', '펙덱 플라이', '케이블 크로스오버', '푸시업',
  // 등
  '데드리프트', '루마니안 데드리프트', '랫풀다운', '풀업', '턱걸이', '친업',
  '바벨로우', '덤벨로우', '시티드 로우', '케이블 로우', '티바로우',
  // 하체
  '스쿼트', '프론트 스쿼트', '핵스쿼트', '레그프레스', '레그익스텐션', '레그컬',
  '런지', '불가리안 스플릿 스쿼트', '힙쓰러스트', '카프레이즈', '레그레이즈',
  // 어깨
  '오버헤드프레스', '숄더프레스', '덤벨 숄더프레스', '사이드 레터럴 레이즈',
  '프론트 레이즈', '벤트오버 레터럴 레이즈', '업라이트 로우', '슈러그',
  // 팔
  '바벨컬', '덤벨컬', '해머컬', '프리처컬', '케이블컬',
  '트라이셉스 익스텐션', '케이블 푸시다운', '딥스', '킥백',
  // 코어·유산소
  '플랭크', '사이드 플랭크', '크런치', '싯업', '행잉 레그레이즈', '러시안 트위스트',
  '러닝', '사이클', '로잉', '버피', '점핑잭',
];

/// 친 글자에 맞는 후보를 순위대로.
///
/// 앞글자 일치가 먼저다 — "벤"을 친 사람이 원하는 건 벤치프레스지
/// 이름 안쪽에 '벤'이 든 무언가가 아니다. 그래도 안쪽 일치를 버리지는 않아서
/// "덤벨"로 "인클라인 덤벨 프레스"를 찾을 수 있다.
List<String> suggest(String query, List<String> pool, {int limit = 6}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final scored = <({String name, int rank})>[];
  for (final name in pool) {
    final lower = name.toLowerCase();
    int? rank;
    if (lower == q) {
      rank = 0;
    } else if (lower.startsWith(q)) {
      rank = 1;
    } else if (lower.split(RegExp(r'\s+')).any((w) => w.startsWith(q))) {
      rank = 2;
    } else if (lower.contains(q)) {
      rank = 3;
    }
    if (rank != null) scored.add((name: name, rank: rank));
  }

  scored.sort((a, b) {
    final byRank = a.rank.compareTo(b.rank);
    return byRank != 0 ? byRank : a.name.length.compareTo(b.name.length);
  });
  return scored.take(limit).map((e) => e.name).toList();
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

final _unit = RegExp(
  r'^(\d+(?:\.\d+)?)\s*(kg|킬로|파운드|lb|회|개|rep|reps|세트|set|sets)$',
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
  final text = line.trim();
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
        case 'kg':
        case '킬로':
          kg = value;
        case 'lb':
        case '파운드':
          kg = (value * 0.4536 * 10).round() / 10;
        case '세트':
        case 'set':
        case 'sets':
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

/// "100kg · 20회"
String setLabel({double? kg, int? reps}) => [
      if (kg != null) formatKg(kg),
      if (reps != null) '$reps회',
    ].join(' · ');
