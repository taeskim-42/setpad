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
  if (words.length > 1 &&
      words.every((word) => bare.contains(searchKey(word)))) {
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

/// 모델에 물을 글인가. 수(아라비아 숫자든 글로 쓴 수든)나 수량어가 **없는** 글은
/// 운동 이름이다 — 물을 것이 없다. 수가 하나라도 있으면 묻는다: "민수식 로우 2" 의
/// 2 가 이름인지는 모델이 이름에 넣어 답하고, "벤치 5x5" 처럼 설정으로 쓸 수 있는
/// 글이 이름으로 빠지지 않는다. 이 함수는 길만 고른다 — 뜻은 모델이 읽는다.
bool hasSetupIntent(String text) =>
    statedNumbers(text).isNotEmpty || _quantityWords.hasMatch(text);

final _quantityWords = RegExp(
  r'채우|총\s|키로|킬로|파운드|\b(?:kg|lb|reps?|sets?|total|reach)\b|'
  r'公斤|千克|磅|总共|總共|回|キロ|セット|repeticiones|series|lần|hiệp|ครั้ง|เซ็ต',
  caseSensitive: false,
);

/// 세트를 어떻게 하는지 말하는 낱말(피라미드·드롭세트·실패까지·템포·RPE…). 모델이
/// 못 옮긴 말에 넣지 않아도 이름에 섞지 않는다 — 모델 이름에 들었으면 그대로다
/// ('템포 스쿼트').
final _conditionWords = RegExp(
  r'피라미드|드랍|드롭|슈퍼세트|자이언트세트|실패까지|원알엠|템포|^(?:1rm|rpe|rir)$|'
  r'pyramid|dropset|drop-set|superset|failure|tempo',
  caseSensitive: false,
);

/// 템포 표기("60bpm", "30 bpm", "bpm 60", "bpm:60") — 수는 1·2번 묶음이다.
/// bpm 옆에 있어도 다른 것을 세는 수는 템포가 아니다: "3x10 bpm" 의 10(횟수),
/// "bpm 3세트"·"bpm 3 sets"·"bpm 3셋" 의 3(세트 수), "bpm 20x5"·"bpm 20 x 5" 의
/// 20, "bpm 100개"·"bpm 3번" 의 수, "bpm 1칸"·"bpm 8 라운드" 의 수. "bpm 30 x3"
/// 은 템포 30 에 3세트다(계획 글이 그렇게 적는다). "bpm N" 의 N 은 두 자리
/// 이상이다 — 템포는 10 부터다(TimingSpec.minBpm). 타이머([TimingSpec]), 계획
/// 줄, 입력 줄의 길 나누기가 이 한 정규식을 쓴다.
final tempoPattern =
    '(?<![\\d.,]|(?<![a-z])[x×*]\\s*)([+-]?\\d+(?:[.,]\\d+)?)\\s*bpm(?![a-z])|'
    '(?<![a-z])bpm\\s*[:=]?\\s*(?=[+-]?\\d\\d)([+-]?\\d+(?:[.,]\\d+)?)(?![\\d.,])'
    '(?!\\s*(?:$_units|칸|박|라운드|rounds?|ラウンド)(?![a-z])|[x×*]\\d|\\s*[x×*]\\s+\\d)';

/// 타이머 토큰(60bpm, bpm 60, 30/15, x8, 10라운드). 글의 수가 모두 여기 쓰였으면
/// 그 글은 타이머 이름이라 묻지 않고 바로 만든다.
final timerTokens = RegExp(
  '$tempoPattern|'
  r'\d+\s*(?:초|s|sec)?\s*[/／]\s*\d+\s*(?:초|s|sec)?|[x×]\s*\d+|'
  r'\d+\s*(?:라운드|rounds?|ラウンド)',
  caseSensitive: false,
);

/// 친 글에 적힌 수들 — 자리와 값. 부호는 읽지 않는다: '8-12' 는 8 과 12 다.
/// 쉼표로 늘어놓은 수('10,12,15회')도 하나씩이다. 쉼표 뒤가 정확히 세 자리면
/// 천 단위('1,000'), 쉼표나 점이 하나뿐이면 소수('22,5').
///
/// 글로 쓴 수도 읽는다(백, 이백, 스무 개, 열 세트, hundred, fifty, 百, 二十).
/// 한국어는 낱말이 **수 + 세는 말(개·회·세트·분…) + 조사·꼬리(씩·만·정도·쯤·하고…)**
/// 로만 이루어질 때 수다 — '삼세트', '오분', '열개씩만', '백개쯤' 은 수고, 꼬리가
/// 목록 밖이면('일회용', '삼분할', '육개장') 낱말이다. '번' 은 한 자리 한자어 수와
/// 쓰면 차례다('이번', '일번' — 횟수는 '두 번'). 꼴은 같아도 굳은 낱말('구분',
/// '사회')은 수가 아니다. 한국어 수의 자리는 꼬리까지다('스무 개').
List<({num value, int start, int end})> statedNumbers(String text) {
  final found = <({num value, int start, int end})>[];
  void add(num? value, int start, int end) {
    if (value != null) found.add((value: value, start: start, end: end));
  }

  for (final m in RegExp(r'\d+(?:[.,]\d+)*').allMatches(text)) {
    final raw = m[0]!;
    if (RegExp(r'^\d{1,3}(?:,\d{3})+$').hasMatch(raw)) {
      add(num.parse(raw.replaceAll(',', '')), m.start, m.end);
    } else if (RegExp(r'^\d+[.,]\d+$').hasMatch(raw)) {
      add(num.parse(raw.replaceAll(',', '.')), m.start, m.end);
    } else {
      for (final d in RegExp(r'\d+').allMatches(raw)) {
        add(num.parse(d[0]!), m.start + d.start, m.start + d.end);
      }
    }
  }
  for (final m in RegExp(
    r'(?<![가-힣])([가-힣]+?)(\s*)(개|회|번|세트|셋트|키로|킬로|파운드|라운드|바퀴|칸|박|분|초|시간|미터|kg|lb|reps?|sets?)'
    r'(?:씩|만|정도|쯤|가량|이상|이하|내외|하고|이랑|랑|와|과|만큼|에서|에|을|를|은|는|이|가|도|으로|로|째|간|짜리|부터|까지|의|요)*(?![가-힣])',
    caseSensitive: false,
  ).allMatches(text)) {
    final sino = RegExp(r'^[일이삼사오육칠팔구]$').hasMatch(m[1]!);
    if (sino && m[3] == '번') continue;
    if (m[2]!.isEmpty && const {'구분', '사회'}.contains('${m[1]}${m[3]}')) {
      continue;
    }
    add(_koreanNumber(m[1]!), m.start, m.end);
  }
  const words =
      'zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|'
      'twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|'
      'twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand';
  for (final m in RegExp(
    '\\b(?:$words)(?:(?:\\s+|-)(?:and\\s+)?(?:$words))*\\b',
    caseSensitive: false,
  ).allMatches(text)) {
    add(_englishNumber(m[0]!.toLowerCase()), m.start, m.end);
  }
  for (final m in RegExp(r'[零〇一二两兩三四五六七八九十百千万萬]+').allMatches(text)) {
    add(_hanNumber(m[0]!), m.start, m.end);
  }
  return found;
}

int? _koreanNumber(String s) {
  const digit = {
    '일': 1,
    '이': 2,
    '삼': 3,
    '사': 4,
    '오': 5,
    '육': 6,
    '칠': 7,
    '팔': 8,
    '구': 9,
  };
  var rest = s, total = 0;
  for (final (unit, size) in [('천', 1000), ('백', 100), ('십', 10)]) {
    final m = RegExp('^([이삼사오육칠팔구]?)$unit').firstMatch(rest);
    if (m == null) continue;
    total += (digit[m[1]] ?? 1) * size;
    rest = rest.substring(m.end);
  }
  if (rest.isEmpty) return total == 0 ? null : total;
  if (digit[rest] case final d?) return total + d;
  // 백 자리 아래는 고유어로 센다(백하나, 이백서른일곱). 십 뒤에는 오지 않는다.
  final native = RegExp(
    r'^(열|스물|스무|서른|마흔|쉰|예순|일흔|여든|아흔)?(하나|한|둘|두|셋|세|넷|네|다섯|여섯|일곱|여덟|아홉)?$',
  ).firstMatch(rest);
  if (native == null || total % 100 != 0) return null;
  const tens = {
    '열': 10,
    '스물': 20,
    '스무': 20,
    '서른': 30,
    '마흔': 40,
    '쉰': 50,
    '예순': 60,
    '일흔': 70,
    '여든': 80,
    '아흔': 90,
  };
  const ones = {
    '하나': 1,
    '한': 1,
    '둘': 2,
    '두': 2,
    '셋': 3,
    '세': 3,
    '넷': 4,
    '네': 4,
    '다섯': 5,
    '여섯': 6,
    '일곱': 7,
    '여덟': 8,
    '아홉': 9,
  };
  return total + (tens[native[1]] ?? 0) + (ones[native[2]] ?? 0);
}

int _englishNumber(String s) {
  const small = [
    'zero',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'eleven',
    'twelve',
    'thirteen',
    'fourteen',
    'fifteen',
    'sixteen',
    'seventeen',
    'eighteen',
    'nineteen',
  ];
  const tens = [
    '',
    '',
    'twenty',
    'thirty',
    'forty',
    'fifty',
    'sixty',
    'seventy',
    'eighty',
    'ninety',
  ];
  var total = 0, current = 0;
  for (final w in s.split(RegExp(r'[\s-]+'))) {
    if (small.contains(w)) current += small.indexOf(w);
    if (tens.contains(w) && w.isNotEmpty) current += tens.indexOf(w) * 10;
    if (w == 'hundred') current = (current == 0 ? 1 : current) * 100;
    if (w == 'thousand') {
      total += (current == 0 ? 1 : current) * 1000;
      current = 0;
    }
  }
  return total + current;
}

int _hanNumber(String s) {
  const digit = {
    '零': 0,
    '〇': 0,
    '一': 1,
    '二': 2,
    '两': 2,
    '兩': 2,
    '三': 3,
    '四': 4,
    '五': 5,
    '六': 6,
    '七': 7,
    '八': 8,
    '九': 9,
  };
  const unit = {'十': 10, '百': 100, '千': 1000};
  var total = 0, section = 0, current = 0;
  for (final c in s.split('')) {
    if (digit[c] case final d?) {
      current = d;
    } else if (unit[c] case final u?) {
      section += (current == 0 ? 1 : current) * u;
      current = 0;
    } else {
      total += (section + current) * 10000;
      section = current = 0;
    }
  }
  return total + section + current;
}

/// 모델이 낸 이름을 **친 글**에 맞춘다. 이름은 친 낱말이다 — 수가 든 낱말,
/// 수량어('총', '채우기'), 못 옮긴 말([unparsed]: '원알엠 70프로', '드롭세트')은
/// 이름에 섞지 않는다.
///
/// 1. 모델 이름을 담은 가장 짧은 낱말 묶음, 친 모양 그대로('로잉' → 로잉머신,
///    'Push Up' → push-ups).
/// 2. 이름에 수가 든 것('MTS100 로우', '민수식 로우 2')은 친 글의 그 자리.
/// 3. 모델이 사전 이름으로 바꿨으면 첫 수 앞의 낱말들 → 모델 이름에 든 낱말들 →
///    수 아닌 낱말 전부 순으로.
///
/// 그래도 없으면 null. [proposed] 가 비어 있으면 3 만 — 수를 뺀 이름이다.
String? typedName(
  String text,
  String proposed, [
  List<String> unparsed = const [],
]) {
  final want = searchKey(proposed);
  final numbers = statedNumbers(text);
  final words = RegExp(r'\S+').allMatches(text).toList();
  bool numbered(Match w) =>
      numbers.any((n) => n.start < w.end && n.end > w.start);
  bool plain(Match w) =>
      !numbered(w) &&
      searchKey(w[0]!).isNotEmpty &&
      !_quantityWords.hasMatch('${w[0]} ') &&
      !_conditionWords.hasMatch(w[0]!) &&
      !unparsed.any((u) => u.contains(w[0]!));
  if (want.isNotEmpty) {
    for (var size = 1; size <= words.length; size++) {
      for (var i = 0; i + size <= words.length; i++) {
        final run = words.sublist(i, i + size);
        if (run.every(plain) &&
            searchKey(run.map((w) => w[0]).join()).contains(want)) {
          return text.substring(run.first.start, run.last.end);
        }
      }
    }
    if (keyRange(text, want) case final r?) {
      return text.substring(r.start, r.end);
    }
  }
  // 첫 수 앞의 낱말이 이름이다 — 사람이 지은 이름('내 방식 벤치 변형')도 그대로.
  // 수가 앞에 왔으면 모델 이름에 든 낱말('80kg 벤치 5x5' → 벤치), 그것도 없으면
  // 수 아닌 낱말 전부('100개 푸시업' → 푸시업).
  final at = words.indexWhere(numbered);
  final name = [
    [
      for (final w in words.take(at < 0 ? words.length : at))
        if (plain(w)) w[0]!,
    ],
    [
      for (final w in words)
        if (plain(w) && want.contains(searchKey(w[0]!))) w[0]!,
    ],
    [
      for (final w in words)
        if (plain(w)) w[0]!,
    ],
  ].firstWhere((n) => n.isNotEmpty, orElse: () => const []);
  return name.isEmpty ? null : name.join(' ');
}

/// 칸 제목에서 익힐 운동 이름. 수가 없는 제목과 타이머 이름('버피 타바타 30/15
/// 10라운드')은 그대로, 설정을 적은 글은 수 낱말을 뺀 이름만('100개 푸시업' →
/// 푸시업). 이름이 안 남으면 null — 익히지 않는다.
String? learnableName(String title) =>
    hasSetupIntent(title.replaceAll(timerTokens, ' '))
    ? typedName(title, '')
    : title.trim();

/// [text] 에서 [key]([searchKey] 모양)가 걸친 자리 — 띄어쓰기·대소문자가 달라도
/// 친 글의 자리로 돌려준다.
({int start, int end})? keyRange(String text, String key) {
  if (key.isEmpty) return null;
  final chars = StringBuffer();
  final at = <int>[];
  for (var i = 0; i < text.length; i++) {
    final c = searchKey(text[i]);
    chars.write(c);
    at.addAll(List.filled(c.length, i));
  }
  final found = chars.toString().indexOf(key);
  if (found < 0) return null;
  return (start: at[found], end: at[found + key.length - 1] + 1);
}

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
  for (final raw in input.split(RegExp(r'\s+'))) {
    final word = stripParticle(raw);
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

/// 세트 수를 뜻하는 말. 무게·거리·시간 단위는 units.dart 가 쥔다.
const _setWords = '세트|셋|set|sets|セット|组|組|serie|series|hiệp|เซ็ต|เซต';

/// 세트 수와 횟수를 뜻하는 말.
const _counters =
    '$_setWords|회|개|번|렙|rep|reps|回|次|个|下|レップ|lần|ครั้ง|veces|'
    'repeticiones|repetición|repeticion';
final _setWord = RegExp('^(?:$_setWords)\$', caseSensitive: false);

/// 단위와 세는 말 전부, 긴 것부터 — 끝을 묶지 않은 자리에서도 "reps" 가 "rep" 에
/// 잘리지 않는다.
final _units = ([
  ...unitPattern.split('|'),
  ..._counters.split('|'),
]..sort((a, b) => b.length.compareTo(a.length))).join('|');

/// 수. 쉼표는 [_readWords] 가 먼저 가른다 — 여기 오는 쉼표는 천 단위("1,000")
/// 거나 소수("22,5")다.
const _num = r'\d{1,3}(?:,\d{3})+|\d+(?:[.,]\d+)?';

/// 수+단위 뒤에 붙는 조사·접미사. 떼고 읽는다 — "80kg에", "10회씩만", "20kg짜리",
/// "60초간", "80kg을".
const _tail = '(?:에서|에|씩|으로|로|짜리|을|를|이랑|랑|까지|만|간|동안|정도|쯤)*';

/// 낱말 끝의 구두점 — 낱말의 몫이다("80kg,", "10회.", "(3세트)").
const _end = '[,.!~)]*';

final _unit = RegExp('^($_num)\\s*($_units)$_tail\$', caseSensitive: false);

/// 숫자와 단위를 띄어 쓰는 언어가 있다 — "10 lần", "100 kg". 붙여 놓고
/// 시작해야 한 토큰으로 읽힌다.
final _spacedUnit = RegExp(
  '(\\d)\\s+($_units)(?=$_tail(?:\\s|\$))',
  caseSensitive: false,
);

/// 세트 수 "x3", "x3 sets".
final _repeat = RegExp('^[x×*](\\d+)($_setWords)?\$', caseSensitive: false);

/// 맨숫자.
final _bare = RegExp(r'^(?:\d{1,3}(?:,\d{3})+|\d+(?:[.,]\d+)?)$');

/// 쉼표가 든 수와 그 뒤("80,10회" → "80,10" + "회").
final _commaNumber = RegExp(r'^(\d+(?:,\d+)+)(.*)$');

/// 낱말 안의 쉼표는 수 사이에만 있다("1,000", "80,10") — 그 밖의 쉼표는 앞
/// 낱말의 끝이다("80kg,10회" → "80kg,", "10회").
const _chars = r'(?:[^\s,]|(?<=\d),(?=\d))';

/// 친 글의 낱말. 띄어 쓴 수와 단위("60 초", "100 kg,")는 한 낱말이다.
final _word = RegExp(
  '$_chars*\\d\\s+(?:$_units)$_tail$_end(?=\\s|\$)|$_chars+,*',
  caseSensitive: false,
);

/// 'AxB'("3x10", "5x5@80kg") 로 시작하는 낱말.
final _byReps = RegExp(r'^\d+(?:[.,]\d+)?[x×*]\d', caseSensitive: false);

/// 한 낱말에 붙여 친 표기의 조각 — 수+단위, 'xN', 가름표(x × * @), 수.
final _piece = RegExp(
  '[x×*]\\d+(?![\\d.,])(?!$_units)|'
  '(?:$_num)(?:$_units)$_tail(?=[\\dx×*@]|\$)|[x×*@]|$_num',
  caseSensitive: false,
);

/// 한 낱말에 붙여 친 표기를 가른다 — "80kg10회", "80kg×10", "3セット×10回",
/// "10reps@80kg", "1분30초". 조각이 모두 수+단위·'xN'·가름표·수이고 수+단위가
/// 하나 이상일 때만이다("3x10", "MTS100", "80/10" 은 그대로).
List<String> markPieces(String word) {
  if (_byReps.hasMatch(word) || _repeat.hasMatch(word)) return [word];
  final pieces = [for (final m in _piece.allMatches(word)) m[0]!];
  return pieces.length > 1 &&
          pieces.join() == word &&
          pieces.any(_unit.hasMatch)
      ? pieces
      : [word];
}

/// "1:30" — 분:초.
final _clock = RegExp(r'^(\d+):([0-5]\d)$');

/// 줄 앞의 "2세트" — 뒤에 무게와 횟수가 다 오면 세트 번호다.
final _ordinal = RegExp(r'^\d+(?:세트|셋)$');

double _number(String s) => double.parse(
  RegExp(r'^\d{1,3}(?:,\d{3})+$').hasMatch(s)
      ? s.replaceAll(',', '')
      : s.replaceAll(',', '.'),
);

bool _whole(String bare) {
  final n = _number(bare);
  return n == n.roundToDouble();
}

/// 전각 글자("８０ｋｇ")는 반각으로. 길이가 같아 친 글의 자리는 그대로다.
String _halfWidth(String s) => s.replaceAllMapped(
  RegExp('[\uFF01-\uFF5E]'),
  (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0xFEE0),
);

/// 띄어 쓴 수와 단위를 붙인다. "5 sets" → "5sets".
String joinSpacedUnits(String text) =>
    text.replaceAllMapped(_spacedUnit, (m) => '${m[1]}${m[2]}');

/// 한 줄로 반복할 수 있는 세트 수. 넘으면 자르지 않고 거절한다 — 입력칸에
/// 글이 남고 [tooManySets] 가 이유를 말한다.
const maxSetsPerLine = 20;

/// 세트 한 줄을 읽는다. "100kg 20회 마지막 힘들었음", "20회", "100 20 x3".
///
/// 단위는 선택이다 — 운동 중에 단위를 꼬박꼬박 붙이는 사람은 없다. 규칙은
/// 하나이고 친 순서대로 간다(test/set_line_table_test.dart 의 표가 main 과
/// 나란히 보인다). 자리는 셋 — 값(무게·거리·시간), 횟수, 세트 수.
///
/// 0. **낱말.** 전각 글자는 반각으로 읽는다. 수+단위에 붙은 조사("80kg을",
///    "10회씩만")와 끝의 구두점·괄호("80kg,", "10회.", "(3세트)")는 떼고 읽고,
///    앞의 '+'("+10kg")는 메모에 남는다. 붙여 친 표기("80kg10회", "80kg×10",
///    "80公斤10次3组")는 조각으로 가른다. "1:30"·"1분 30초" 는 시간 하나(초)다.
///    'AxB'("5x5", "3x10")가 든 줄은 거절한다 — 세트×횟수인지 무게×횟수인지
///    모른다. 줄 앞의 "2세트" 뒤에 무게와 횟수가 다 오면 세트 번호라 메모다.
/// 1. **쉼표.** "A,B" 에서 B 가 정확히 세 자리면 천 단위("1,000"). 무게·거리·
///    시간 단위가 붙었으면 소수("22,5kg", "80,10kg"). 맨숫자는 B 가 **한 자리**
///    이고 줄의 다른 곳(앞이든 뒤든)에 횟수를 맡을 수(온수 맨숫자, 'xN', 횟수
///    단위)가 따로 있을 때만 소수("22,5 10", "10 22,5" = 22.5×10). 그 밖은 두
///    수다 — "80,10", "80,10 3", "80,10회", "3,5세트" 의 쉼표는 수를 가른다.
///    쉼표로 늘어놓은 수가 셋 이상("12,10,8", "10, 8, 6")이면 목록이라 메모다.
/// 2. **맨숫자의 몫.** 줄에 무게 단위 값("100kg")이 있으면 맨숫자는 무게가
///    아니다 — 횟수 단위가 없을 때만 횟수("5 5 100kg" = 100kg×5, 메모 5). 무게
///    없이 횟수 단위("10회")가 있으면 맨숫자는 값이다. 둘 다 없으면 첫 단위 값
///    (시간·거리) **앞에** 맨숫자가 둘 이상일 때 그 짝이 값·횟수("80 10 60초
///    휴식")이고 — 짝에 소수가 있으면 소수가 값("10 22.5" = 22.5×10) — 아니면
///    맨숫자는 횟수다("12", "3 60초 2").
/// 3. **친 순서대로 빈 자리만 채운다.** 단위 값은 값 자리, 횟수 단위는 횟수
///    자리, "x3"·"3세트" 는 세트 자리를 먼저 온 것이 갖는다. 무게 바로 뒤의
///    "xN" 은 줄에 횟수 단위가 없으면 횟수가 먼저다("80kg x10" = 80kg×10). 횟수는
///    온수, 세트 수는 1 이상의 온수만 받는다 — 소수("10.5회", "2.5세트")를
///    반올림해 지어내지 않는다. 자리를 못 얻은 낱말은 **덮어쓰지도 버리지도 않고**
///    메모에 친 그대로 남는다 — "80 10회 5분" 은 80×10 에 메모 "5분", "x0" 도
///    메모다. 맨 소수는 횟수가 될 수 없어 값 자리로 간다("12.5" = 12.5).
///
/// 값도 횟수도 없으면 세트가 아니다(null — 입력칸에 글이 남는다). 세트 수가
/// [maxSetsPerLine] 을 넘어도 null 이고 [tooManySets] 가 까닭을 말한다.
ParsedSet? parseSetLine(String line) {
  final parsed = _readSetLine(line);
  return parsed == null || parsed.count > maxSetsPerLine ? null : parsed;
}

/// 세트 줄로 읽히지만 반복 수가 [maxSetsPerLine] 을 넘는다.
bool tooManySets(String line) =>
    (_readSetLine(line)?.count ?? 0) > maxSetsPerLine;

/// 낱말: 읽을 글([t]), 친 글 위의 자리, 뒤에 쉼표가 붙었는가.
typedef _Word = ({String t, int start, int end, bool comma});

bool _isReps(String t) => switch (_unit.firstMatch(t)) {
  final m? => unitOf(m[2]!) == null && !_setWord.hasMatch(m[2]!),
  null => false,
};

bool _isValue(String t) => unitOf(_unit.firstMatch(t)?[2] ?? '') != null;

bool _isWeight(String t) =>
    unitById[unitOf(_unit.firstMatch(t)?[2] ?? '')]?.kind == UnitKind.weight;

/// 시간 낱말의 온수 — [unit] 이 'min' 이나 's' 일 때.
int? _wholeTime(String t, String unit) {
  final m = _unit.firstMatch(t);
  if (m == null || unitOf(m[2]!) != unit) return null;
  final n = _number(m[1]!);
  return n == n.roundToDouble() ? n.toInt() : null;
}

/// 쉼표마다 한 낱말로 가른다. 쉼표는 앞 수의 몫이고(메모에 떠돌지 않게) 단위는
/// 끝 수에 남는다 — "80,10회" → "80", "10회".
List<_Word> _splitCommas(_Word w, String digits) {
  final groups = digits.split(',');
  final words = <_Word>[];
  var at = 0;
  for (final (k, g) in groups.indexed) {
    final last = k == groups.length - 1;
    words.add((
      t: last ? w.t.substring(at) : g,
      start: w.start + at,
      end: last ? w.end : w.start + at + g.length + 1,
      comma: last ? w.comma : true,
    ));
    at += g.length + 1;
  }
  return words;
}

/// 규칙 0·1 — 낱말을 원문 위의 자리와 함께 읽고, 쉼표 수를 가른다.
List<_Word> _readWords(String text) {
  final words = <_Word>[];
  // 맨 "A,B"(B 한 자리) — 소수인지는 줄을 다 봐야 안다.
  final open = <int>{};
  for (final m in _word.allMatches(text)) {
    final raw = m[0]!;
    final start = m.start + (raw.startsWith('+') ? 1 : 0);
    final t = raw
        .substring(start - m.start)
        .replaceAll(RegExp(r'\s+'), '')
        .replaceFirst(RegExp(r'^\('), '')
        .replaceFirst(RegExp(r'[,.!~)]+$'), '');
    final comma = RegExp(r',[,.!~)]*$').hasMatch(raw);
    final pieces = markPieces(t);
    if (pieces.length > 1) {
      // 조각의 자리 — 떼어 낸 것은 공백·괄호뿐이라 친 글에서 차례로 찾는다.
      var at = start;
      for (final (k, p) in pieces.indexed) {
        final from = at;
        for (final ch in p.split('')) {
          at = text.indexOf(ch, at) + 1;
        }
        final last = k == pieces.length - 1;
        words.add((
          t: p,
          start: from,
          end: last ? m.end : at,
          comma: last && comma,
        ));
      }
      continue;
    }
    final w = (t: t, start: start, end: m.end, comma: comma);
    final c = _commaNumber.firstMatch(t);
    if (c == null ||
        RegExp(r'^\d{1,3}(?:,\d{3})+$').hasMatch(c[1]!) ||
        (_isValue(t) && RegExp(r'^\d+,\d\d?$').hasMatch(c[1]!))) {
      words.add(w);
    } else if (c[2]!.isEmpty && RegExp(r'^\d+,\d$').hasMatch(c[1]!)) {
      open.add(words.length);
      words.add(w);
    } else {
      words.addAll(_splitCommas(w, c[1]!));
    }
  }
  bool counts(_Word w) =>
      RegExp(r'^\d+$').hasMatch(w.t) || _repeat.hasMatch(w.t) || _isReps(w.t);
  final read = [
    for (final (i, w) in words.indexed)
      if (!open.contains(i) ||
          words.indexed.any((o) => o.$1 != i && counts(o.$2)))
        w
      else
        ..._splitCommas(w, w.t),
  ];
  // 쉼표로 늘어놓은 수 셋 이상은 목록이다 — 값·횟수로 읽지 않고 메모에 둔다.
  for (var i = 0; i < read.length;) {
    var j = i;
    while (j < read.length && read[j].comma && _bare.hasMatch(read[j].t)) {
      j++;
    }
    final end =
        j < read.length && (_bare.hasMatch(read[j].t) || _isReps(read[j].t))
        ? j + 1
        : j;
    if (end - i >= 3) {
      for (var k = i; k < end; k++) {
        read[k] = (t: '', start: read[k].start, end: read[k].end, comma: true);
      }
    }
    i = end > i ? end : i + 1;
  }
  // "1:30", "1분 30초" — 시간 하나(초).
  final out = <_Word>[];
  for (final w in read) {
    final clock = _clock.firstMatch(w.t);
    final t = clock == null
        ? w.t
        : '${int.parse(clock[1]!) * 60 + int.parse(clock[2]!)}s';
    final minutes = out.isEmpty ? null : _wholeTime(out.last.t, 'min');
    final seconds = _wholeTime(t, 's');
    if (minutes != null && seconds != null && seconds < 60) {
      out.last = (
        t: '${minutes * 60 + seconds}s',
        start: out.last.start,
        end: w.end,
        comma: w.comma,
      );
    } else {
      out.add((t: t, start: w.start, end: w.end, comma: w.comma));
    }
  }
  return out;
}

ParsedSet? _readSetLine(String line) {
  final typed = line.trim();
  final text = _halfWidth(typed);
  final words = _readWords(text);
  if (words.any((w) => _byReps.hasMatch(w.t))) return null;
  // 줄 앞의 "2세트" 뒤에 무게와 횟수가 다 오면 세트 번호다 — 메모에 둔다.
  if (words.isNotEmpty && _ordinal.hasMatch(words.first.t)) {
    final rest = _readSetLine(typed.substring(words.first.end));
    if (rest?.value != null && rest?.reps != null) {
      words[0] = (
        t: '',
        start: words[0].start,
        end: words[0].end,
        comma: false,
      );
    }
  }
  // 규칙 2 — 맨숫자가 맡는 자리(앞의 것이 먼저).
  final weight = words.any((w) => _isWeight(w.t));
  final repsWord = words.any((w) => _isReps(w.t));
  final firstValue = words.indexWhere((w) => _isValue(w.t));
  final lead = words
      .take(firstValue < 0 ? words.length : firstValue)
      .where((w) => _bare.hasMatch(w.t));
  final bareSlots = weight
      ? repsWord
            ? const <String>[]
            : const ['reps']
      : repsWord
      ? const ['value']
      : lead.length > 1 && lead.every((w) => _whole(w.t))
      ? const ['value', 'reps']
      : const ['reps', 'value'];
  double? value;
  String? unit;
  int? reps, count;
  // 규칙 3 — 친 순서대로, 빈 자리만. 자리에 들어간 낱말 말고는 메모다.
  final used = <int>{};
  for (final (i, word) in words.indexed) {
    final m = _unit.firstMatch(word.t);
    final repeat = _repeat.firstMatch(word.t);
    final n = repeat != null
        ? double.parse(repeat[1]!)
        : m != null
        ? _number(m[1]!)
        : _bare.hasMatch(word.t)
        ? _number(word.t)
        : null;
    if (n == null) continue;
    final whole = n == n.roundToDouble();
    final known = m == null ? null : unitOf(m[2]!);
    bool take(String slot) {
      switch (slot) {
        case 'count' when count == null && whole && n >= 1:
          count = n.toInt();
        case 'value' when value == null:
          (value, unit) = (n, known);
        case 'reps' when reps == null && whole:
          reps = n.toInt();
        default:
          return false;
      }
      return true;
    }

    final slots = repeat != null
        // 무게 바로 뒤의 "x10" 은 횟수다("80kg x10") — 줄에 횟수 단위가 없을 때.
        ? repeat[2] == null && !repsWord && i > 0 && _isWeight(words[i - 1].t)
              ? const ['reps', 'count']
              : const ['count']
        : m != null && _setWord.hasMatch(m[2]!)
        ? const ['count']
        : known != null
        ? const ['value']
        : m != null
        ? const ['reps']
        : bareSlots;
    if (slots.any(take)) used.add(i);
  }

  if (value == null && reps == null) return null;
  final rest = <String>[];
  var from = 0;
  for (final (i, word) in words.indexed) {
    if (!used.contains(i)) continue;
    rest.add(typed.substring(from, word.start).trim());
    from = word.end;
  }
  rest.add(typed.substring(from).trim());
  final note = rest.where((s) => s.isNotEmpty).join(' ');
  return ParsedSet(
    value: value,
    unit: unit,
    reps: reps,
    note: note.isEmpty ? null : note,
    count: count ?? 1,
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
    r'(kg|킬로|키로|파운드|lb)\s*$',
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

/// 낱말 끝의 조사를 뗀다. "벤치프레스는" → "벤치프레스". 남는 것이 두 글자
/// 아래면 떼지 않는다 — "데드" 의 "드" 를 조사로 보면 안 된다.
String stripParticle(String word) {
  final m = RegExp(
    r'(이랑|에서|한테|보다|으로|까지|부터|은|는|이|가|을|를|의|도|랑|하고|로|에|만)$',
  ).firstMatch(word);
  if (m == null) return word;
  final base = word.substring(0, m.start);
  return base.length >= 2 ? base : word;
}

/// 수사 한글 → 수. "팔십" → 80, "백이십" → 120, "오" → 5. 1~999. 아니면 null.
int? koreanNumber(String text) {
  const digit = {
    '일': 1,
    '이': 2,
    '삼': 3,
    '사': 4,
    '오': 5,
    '육': 6,
    '칠': 7,
    '팔': 8,
    '구': 9,
  };
  if (text.isEmpty || !RegExp(r'^[일이삼사오육칠팔구십백]+$').hasMatch(text)) return null;
  var total = 0, current = 0;
  for (final ch in text.split('')) {
    if (ch == '백') {
      total += (current == 0 ? 1 : current) * 100;
      current = 0;
    } else if (ch == '십') {
      total += (current == 0 ? 1 : current) * 10;
      current = 0;
    } else {
      current = digit[ch]!;
    }
  }
  total += current;
  return total == 0 ? null : total;
}

/// 글이 **지목한** 운동. 넓게 긁는 [retrieveExercises] 와 다르다 — 그쪽은
/// 모델에게 후보를 많이 주려는 것이고, 이쪽은 "정확히 무엇을 말했나" 다.
///
/// 1. 사전 키(정식·다른 언어·별칭)를 **긴 것부터** 글자 그대로 찾는다.
///    찾은 자리는 지운다 — "오버헤드 프레스" 안의 "프레스" 가 벤치프레스로
///    또 잡히면 안 된다. 띄어쓰기는 무시한다("벤치 프레스" = "벤치프레스").
/// 2. 하나도 없으면 낱말마다 [suggest] 를 쓰되, 그 낱말이 **한 운동에만**
///    닿을 때만 인정한다. "프레스" 처럼 여럿에 닿는 낱말은 지목이 아니다.
///
/// 두 단계를 합친다. 결과가 둘 이상이면 둘 이상을 돌려준다 — 부르는 쪽이
/// "하나만" 을 요구한다. 순서는 글에 적힌 순서다 — 표의 열과 차이의 방향이
/// 이것을 따른다.
List<String> namedExercises(String text, List<String> pool) {
  var compact = searchKey(text);
  if (compact.isEmpty) return const [];
  // 이름 → 글(검색 키)에서 처음 나온 자리.
  final found = <String, int>{};
  void hit(String name, int at) =>
      found.update(name, (was) => was < at ? was : at, ifAbsent: () => at);
  final keyed = <(String key, String name)>[];
  for (final name in pool.toSet()) {
    final keys =
        exerciseByName[name.toLowerCase()]?.keys ?? [name.toLowerCase()];
    for (final key in keys) {
      final k = searchKey(key);
      if (k.length >= 2 && !RegExp(r'^[ㄱ-ㅎ]+$').hasMatch(k)) {
        keyed.add((k, name));
      }
    }
    for (final word
        in (exerciseByName[name.toLowerCase()]?.alias ?? '')
            .toLowerCase()
            .split(' ')) {
      if (word.length >= 2) keyed.add((searchKey(word), name));
    }
  }
  keyed.sort((a, b) => b.$1.length.compareTo(a.$1.length));
  for (final (key, name) in keyed) {
    final at = compact.indexOf(key);
    if (at < 0) continue;
    hit(name, at);
    compact = compact.replaceRange(at, at + key.length, ' ' * key.length);
  }
  // 키로 찾은 것과 낱말로 찾은 것을 합친다. "스쿼트 벤치 요즘 어때" 는 키로
  // 스쿼트, 낱말(접두)로 벤치프레스 — 둘 다 지목이다. 키 단계에서 멈추면
  // 벤치를 놓치고 스쿼트 하나로 읽는다.
  for (final raw in RegExp(r'\S+').allMatches(text)) {
    final word = stripParticle(raw[0]!);
    if (word.length < 2 || word.contains(RegExp(r'\d'))) continue;
    // 두 글자 로마자("PR", "vs")는 이름 속에 흔히 들어 있어("bench press")
    // 퍼지로 지목이 된다. 별칭("bp")은 위의 키 단계가 이미 잡았다.
    if (RegExp(r'^[a-zA-Z]{2}$').hasMatch(word)) continue;
    final hits = suggest(word, pool, limit: 2);
    if (hits.length == 1) {
      hit(hits.single, searchKey(text.substring(0, raw.start)).length);
    }
  }
  return found.keys.toList()..sort((a, b) => found[a]!.compareTo(found[b]!));
}
