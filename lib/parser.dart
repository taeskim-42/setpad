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

/// 영어로 치는 사람도 많다. 표시 이름은 한글 그대로 두고 **검색 키만** 늘린다
/// — "bench" 로 찾아도 카드에는 벤치프레스라고 적힌다. 씨앗에만 붙는다.
/// 사용자가 직접 만든 이름은 친 그대로가 곧 검색 키다.
const _english = <String, String>{
  '벤치프레스': 'bench press bp',
  '인클라인 벤치프레스': 'incline bench press',
  '디클라인 벤치프레스': 'decline bench press',
  '덤벨 프레스': 'dumbbell press db press',
  '인클라인 덤벨 프레스': 'incline dumbbell press',
  '체스트 프레스': 'chest press',
  '펙덱 플라이': 'pec deck fly',
  '케이블 크로스오버': 'cable crossover',
  '푸시업': 'push up pushup',
  '데드리프트': 'deadlift dead lift dl',
  '루마니안 데드리프트': 'romanian deadlift rdl',
  '랫풀다운': 'lat pulldown pull down',
  '풀업': 'pull up pullup',
  '턱걸이': 'pull up pullup',
  '친업': 'chin up chinup',
  '바벨로우': 'barbell row',
  '덤벨로우': 'dumbbell row db row',
  '시티드 로우': 'seated row',
  '케이블 로우': 'cable row',
  '티바로우': 't bar row tbar',
  '스쿼트': 'squat',
  '프론트 스쿼트': 'front squat',
  '핵스쿼트': 'hack squat',
  '레그프레스': 'leg press',
  '레그익스텐션': 'leg extension',
  '레그컬': 'leg curl',
  '런지': 'lunge',
  '불가리안 스플릿 스쿼트': 'bulgarian split squat',
  '힙쓰러스트': 'hip thrust',
  '카프레이즈': 'calf raise',
  '레그레이즈': 'leg raise',
  '오버헤드프레스': 'overhead press ohp',
  '숄더프레스': 'shoulder press',
  '덤벨 숄더프레스': 'dumbbell shoulder press',
  '사이드 레터럴 레이즈': 'side lateral raise',
  '프론트 레이즈': 'front raise',
  '벤트오버 레터럴 레이즈': 'bent over lateral raise rear delt',
  '업라이트 로우': 'upright row',
  '슈러그': 'shrug',
  '바벨컬': 'barbell curl',
  '덤벨컬': 'dumbbell curl db curl',
  '해머컬': 'hammer curl',
  '프리처컬': 'preacher curl',
  '케이블컬': 'cable curl',
  '트라이셉스 익스텐션': 'triceps extension tricep',
  '케이블 푸시다운': 'cable pushdown push down',
  '딥스': 'dips dip',
  '킥백': 'kickback kick back',
  '플랭크': 'plank',
  '사이드 플랭크': 'side plank',
  '크런치': 'crunch',
  '싯업': 'sit up situp',
  '행잉 레그레이즈': 'hanging leg raise',
  '러시안 트위스트': 'russian twist',
  '러닝': 'running run treadmill',
  '사이클': 'cycling bike',
  '로잉': 'rowing row machine',
  '버피': 'burpee',
  '점핑잭': 'jumping jack',
};

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
    // 한글 이름과 영어 검색 키 중 더 좋은 쪽을 그 운동의 점수로 삼는다.
    int? rank;
    for (final key in [name.toLowerCase(), ?_english[name]]) {
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
