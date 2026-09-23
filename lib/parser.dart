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
/// ('템포 스쿼트'). **낱말 전체**가 그 말일 때만이다: '템포런' 은 이름이다.
final _conditionWords = RegExp(
  r'^(?:피라미드|드[랍롭](?:세트|셋)?|슈퍼세트|자이언트세트|실패까지|원알엠|템포|1rm|rpe|rir|'
  r'pyramid|drop-?sets?|supersets?|failure|tempo)$',
  caseSensitive: false,
);

/// 문장부호·조사를 떼어도 낱말 전체가 조건 말인가('템포로', '(RPE').
bool _isCondition(String word) {
  final bare = word.replaceAll(RegExp(r'[^\p{L}\p{N}-]', unicode: true), '');
  return _conditionWords.hasMatch(bare) ||
      _conditionWords.hasMatch(stripParticle(bare));
}

/// 타이머 토큰(60bpm, bpm 60, 30/15, x8, 10라운드). 글의 수가 모두 여기 쓰였으면
/// 그 글은 타이머 이름이라 묻지 않고 바로 만든다.
final timerTokens = RegExp(
  r'\d+(?:[.,]\d+)?\s*bpm(?![a-z])|(?<![a-z])bpm\s*[:=]?\s*\d+(?:[.,]\d+)?|'
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
      !_isCondition(w[0]!) &&
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

/// 친 줄에 **운동이라는 근거**가 있는가. 입력 줄 하나로 운동과 끼니를 가를 때
/// 맨 먼저 본다 — '케이블 크런치' 를 과자로 읽으면 기록이 바뀐다.
///
/// - 운동 단위: 수 뒤의 kg·lb·회·세트·rep, AxB, 그리고 bpm·타바타·라운드. 이름이 흔한 음식
///   낱말 하나면([foodWords]) 아니다 — '치킨 1세트'.
/// - 수를 뺀 이름이 사전 이름(여덟 언어·별칭·초성)이다. 이름 전체가 사전 이름의
///   앞부분이어도('벤치', '데드') — 로마자는 네 글자부터('ham' 은 햄이지 해머컬이 아니다).
/// - 수를 뺀 이름 **전체**가 익힌 이름([learned])이다. 낱말 묶음으로는 보지 않고, 음식에만
///   쓰는 양([foodUnits])이 있으면 보지 않는다 — 표에 없는 음식이 한 번 운동 칸이 되어
///   익혀졌어도 '삶은 계란 2개'·'커피 1잔' 까지 운동이 되지 않게.
/// - 이름 속 낱말 묶음이 사전 이름이다('아침 러닝'), 또는 종목·유산소 낱말이 있다
///   ('저녁 요가', '트레드밀 300kcal' — 저녁은 때이고 kcal 은 소모 열량이다).
bool exerciseEvidence(String text, Iterable<String> learned) {
  final name = learnableName(text);
  final whole = searchKey(name ?? '');
  if (_exerciseUnits.hasMatch(text) && !foodWords.contains(whole)) return true;
  if (name == null) return false;
  if (_exerciseKeys.contains(whole) ||
      _aliasWords.contains(whole) ||
      (!foodUnits.hasMatch(text) &&
          learned.any((n) => searchKey(n) == whole))) {
    return true;
  }
  final latin = RegExp(r'^[a-z]+$').hasMatch(whole);
  if (whole.length >= (latin ? 4 : 2) &&
      _exerciseKeys.any((k) => k.startsWith(whole))) {
    return true;
  }
  final raw = [
    for (final w in name.split(RegExp(r'\s+')))
      if (searchKey(w) case final k when k.isNotEmpty) k,
  ];
  // 조사를 뗀 것과 안 뗀 것 둘 다 본다 — '핫요가' 의 '가' 는 조사가 아니다.
  final words = raw.map(stripParticle).toList();
  if ([...raw, ...words].any(
    (w) => _exerciseWords.contains(w) || _exerciseEndings.any(w.endsWith),
  )) {
    return true;
  }
  for (var i = 0; i < words.length; i++) {
    for (var j = i + 1; j <= words.length; j++) {
      if (_exerciseKeys.contains(words.sublist(i, j).join())) return true;
    }
  }
  return false;
}

final _exerciseUnits = RegExp(
  r'\d\s*(?:kg|lbs?|키로|킬로|파운드|회|세트|셋트|sets?|reps?|セット|回|组|組)(?![a-z])|'
  r'\d\s*[x×]\s*\d|bpm|타바타|tabata|라운드|\brounds?\b',
  caseSensitive: false,
);

/// 음식에만 쓰는 양(공기·그릇·인분·조각·잔·봉지·캔·병·접시·스푼·g·ml·cup…, 곱빼기).
/// 끼니 근거이고([mealEvidence] 가 본다), 익힌 이름보다 먼저다.
final foodUnits = RegExp(
  r'곱빼기|'
  r'(?:\d+(?:[.,]\d+)?|반|한|두|세|네)\s*'
  r'(?:공기|그릇|인분|조각|잔|봉지|캔|병|접시|스푼|숟가락|숟갈|g|ml|㎖)(?![a-z])|'
  r'\d\s*(?:cups?|bowls?|slices?|servings?|cans?|bottles?|glass(?:es)?|tbsp|tsp)\b',
  caseSensitive: false,
);

/// 흔한 음식 낱말. 낱말 **전체**일 때만이다 — '치킨윙'(머신)은 치킨이 아니다. 음식 표가
/// 대표 이름으로 못 찾는 것(계란·밥·커피·beer — 표에는 달걀·쌀밥·'Coffee, brewed')과
/// 그물 없이도 알아야 할 것. 끼니 근거이고([mealEvidence] 가 본다), 운동 근거가 먼저라
/// '굿모닝'·'케이블 크런치' 는 여기 오지 않는다. 다만 이름이 이 낱말 하나면 운동 단위도
/// 근거가 아니다('치킨 1세트', 'steak 1 lb').
const foodWords = {
  '밥', '쌀밥', '흰밥', '공기밥', '공깃밥', '계란', '달걀', '계란후라이', '계란말이', '삶은계란', '커피', //
  '라떼', '카페라떼', '아메리카노', '우유', '두유', '주스', '콜라', '사이다', '맥주', '소주', '와인', //
  '막걸리', '하이볼', '위스키', '떡', '회', '초밥', '과자', '컵라면', '라면', '빵', '식빵', '빅맥', //
  '와퍼', '햄버거', '버거', '피자', '치킨', '양념치킨', '후라이드', '오뎅', '어묵', '김밥', '샐러드', //
  '샌드위치', '토스트', '포케', '서브웨이', '도시락', '프로틴', '쉐이크', '셰이크', '프로틴쉐이크', //
  '단백질쉐이크', '게토레이', '파워에이드', '레드불', '귤', '포도', '참외', '사과', '바나나', '고구마', //
  '닭가슴살', '요거트', '요구르트', '아이스크림', '초콜릿', '케이크', '쿠키', '도넛', '떡볶이', '만두', //
  'coffee', 'latte', 'espresso', 'milk', 'beer', 'wine', 'soda', 'coke', //
  'juice', 'smoothie', 'burger', 'hamburger', 'cheeseburger', 'fries', //
  'pizza', 'salad', 'sandwich', 'sushi', 'ramen', 'steak', 'taco', 'tacos', //
  'burrito', 'nachos', 'donut', 'doughnut', 'bagel', 'toast', 'egg', 'eggs', //
  'rice', 'noodles', 'pasta', 'chips', 'candy', 'chocolate', 'cookie', //
  'cookies', 'cake', 'brownie', 'granola', 'oatmeal', 'cereal', 'yogurt', //
  'almonds', 'banana', 'apple', 'protein', 'shake',
};

/// 운동을 가리키는 낱말('아침 루틴 A', '하체 운동', 'leg day workout'). 낱말 전체일
/// 때만이다 — '닭가슴살' 의 가슴은 아니다.
const _exerciseWords = {
  '루틴', '운동', '서킷', '스트레칭', '유산소', '무산소', '근력', '하체', '상체', //
  '복근', '코어', '와드', '웜업', '쿨다운', '쿨링', '인터벌', '트레이닝', //
  'routine', 'workout', 'circuit', 'stretch', 'stretching', 'cardio', 'wod', //
  'hiit', 'warmup', 'cooldown', 'interval', 'training',
  // 종목·유산소·수업. 사전에 없어도 운동이다 — '저녁 요가' 의 저녁은 끼니가 아니라 때다.
  // 클린은 음식 표에 같은 이름의 제품이 있다. 사전 별칭으로 두면 기록 검색에서
  // '클린' 이 파워클린으로 바뀐다.
  '요가', '필라테스', '수영', '조깅', '달리기', '러닝', '런닝', '걷기', '산책', //
  '등산', '하이킹', '트레킹', '줄넘기', '자전거', '사이클', '싸이클', '스핀', //
  '스피닝', '트레드밀', '런닝머신', '스텝밀', '스테퍼', '일립티컬', '계단', //
  '인라인', '마라톤', '테니스', '배드민턴', '탁구', '스쿼시', '골프', '축구', //
  '풋살', '농구', '야구', '배구', '볼링', '클라이밍', '볼더링', '복싱', '주짓수', //
  '유도', '태권도', '무에타이', '크로스핏', '줌바', '에어로빅', '발레', '스키', //
  '스케이트', '서핑', '헬스', '웨이트', '피티', 'pt', '클린', //
  'yoga', 'pilates', 'swim', 'swimming', 'run', 'running', 'jog', 'jogging', //
  'walk', 'walking', 'hike', 'hiking', 'bike', 'biking', 'cycling', 'spin', //
  'spinning', 'treadmill', 'elliptical', 'stairmaster', 'rowing', 'tennis', //
  'badminton', 'golf', 'soccer', 'basketball', 'climbing', 'bouldering', //
  'boxing', 'kickboxing', 'crossfit', 'zumba', 'aerobics', 'gym', 'clean',
};

/// 이 말로 끝나는 낱말도 운동이다('하체운동', '핫요가', '파워워킹', '실내자전거', '킥복싱').
const _exerciseEndings = [
  '운동', '요가', '걷기', '워킹', '자전거', '바이크', '사이클', '싸이클', '복싱', '댄스', //
];

/// 사전 이름 전부(여덟 언어·별칭 통째·초성)의 검색 키.
final _exerciseKeys = {
  for (final e in exercises)
    for (final k in e.keys) searchKey(k),
};

/// 별칭 낱말 하나하나('dl dead lift' 의 dead). 이름 **전체**가 이것일 때만 운동이다 —
/// 'side salad' 의 side 는 사이드 레터럴 레이즈가 아니다.
final _aliasWords = {
  for (final e in exercises)
    for (final w in e.alias.split(' '))
      if (w.length >= 2) searchKey(w),
};

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

/// 세트 수와 횟수를 뜻하는 말. 무게·거리·시간 단위는 units.dart 가 쥔다.
const _counters =
    '세트|set|sets|セット|组|組|serie|series|hiệp|เซ็ต|'
    '회|개|rep|reps|回|次|lần|ครั้ง|veces';
final _setWord = RegExp(
  r'^(세트|set|sets|セット|组|組|serie|series|hiệp|เซ็ต)$',
  caseSensitive: false,
);

final _units = '$unitPattern|$_counters';

/// 수. 쉼표는 [_readWords] 가 먼저 가른다 — 여기 오는 쉼표는 천 단위("1,000")
/// 거나 소수("22,5")다.
const _num = r'\d{1,3}(?:,\d{3})+|\d+(?:[.,]\d+)?';

/// 수+단위 뒤에 붙는 조사·접미사. 떼고 읽는다 — "80kg에", "10회씩", "20kg짜리".
const _tail = '(?:에|씩|으로|로|짜리)?';

final _unit = RegExp('^($_num)\\s*($_units)$_tail\$', caseSensitive: false);

/// 숫자와 단위를 띄어 쓰는 언어가 있다 — "10 lần", "100 kg". 붙여 놓고
/// 시작해야 한 토큰으로 읽힌다.
final _spacedUnit = RegExp(
  '(\\d)\\s+($_units)(?=$_tail(?:\\s|\$))',
  caseSensitive: false,
);
final _repeat = RegExp(r'^[x×*](\d+)$', caseSensitive: false);

/// 맨숫자.
final _bare = RegExp(r'^(?:\d{1,3}(?:,\d{3})+|\d+(?:[.,]\d+)?)$');

/// 쉼표가 든 수와 그 뒤("80,10회" → "80,10" + "회").
final _commaNumber = RegExp(r'^(\d+(?:,\d+)+)(.*)$');

/// 친 글의 낱말. 띄어 쓴 수와 단위("60 초")는 한 낱말이다.
final _word = RegExp(
  '\\S*\\d\\s+(?:$_units)$_tail(?=\\s|\$)|\\S+',
  caseSensitive: false,
);

double _number(String s) => double.parse(
  RegExp(r'^\d{1,3}(?:,\d{3})+$').hasMatch(s)
      ? s.replaceAll(',', '')
      : s.replaceAll(',', '.'),
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
/// 하나이고 친 순서대로 간다(test/parser_test.dart 의 표가 main 과 나란히 보인다):
///
/// 1. **쉼표.** "A,B" 에서 B 가 정확히 세 자리면 천 단위("1,000"). B 가 한두
///    자리면 소수 — 무게·거리·시간 단위가 붙었거나("22,5kg"), 맨숫자인데 줄에
///    횟수를 맡을 수가 따로 있을 때("22,5 10" = 22.5×10). 그 밖은 두 수다 —
///    혼자 친 "80,10" 은 80×10, "80,10회" 는 80 과 10회 — 횟수·세트 단위 앞의
///    쉼표는 소수가 아니다.
/// 2. **맨숫자의 몫.** 줄에 횟수 단위("10회")가 있으면 맨숫자는 무게다. 없으면
///    맨숫자 하나는 횟수(맨몸 운동이 그렇게 적힌다), 둘 이상이면 빈 자리를
///    무게, 횟수 순으로 채운다.
/// 3. **친 순서대로 자리를 채운다.** 무게 자리(맨 무게, 수+단위 kg·lb·시간·
///    거리), 횟수 자리(맨 횟수, "10회"), 세트 자리("3세트", "x3")는 먼저 온
///    것이 갖는다. 이미 찬 자리의 낱말은 **덮어쓰지도 버리지도 않고** 메모에 친
///    그대로 남는다 — "80 10회 5분에" 는 80×10 에 메모 "5분에", "1분 30초" 는
///    1분에 메모 "30초".
ParsedSet? parseSetLine(String line) {
  final parsed = _readSetLine(line);
  return parsed == null || parsed.count > maxSetsPerLine ? null : parsed;
}

/// 세트 줄로 읽히지만 반복 수가 [maxSetsPerLine] 을 넘는다.
bool tooManySets(String line) =>
    (_readSetLine(line)?.count ?? 0) > maxSetsPerLine;

typedef _Word = ({String t, int start, int end});

bool _isReps(String t) => switch (_unit.firstMatch(t)) {
  final m? => unitOf(m[2]!) == null && !_setWord.hasMatch(m[2]!),
  null => false,
};

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
    ));
    at += g.length + 1;
  }
  return words;
}

/// 규칙 1 — 낱말을 원문 위의 자리와 함께 읽고, 쉼표 수를 가른다.
List<_Word> _readWords(String text) {
  final words = <_Word>[];
  // 맨 "A,B"(B 한두 자리) — 소수인지는 줄을 다 봐야 안다.
  final open = <int>{};
  for (final m in _word.allMatches(text)) {
    var t = m[0]!.replaceAll(RegExp(r'\s+'), '');
    // "80, 10" 의 쉼표는 가름표다.
    if (RegExp(r'^\d+,$').hasMatch(t)) t = t.substring(0, t.length - 1);
    final w = (t: t, start: m.start, end: m.end);
    final c = _commaNumber.firstMatch(t), unit = _unit.firstMatch(t);
    final decimal = c != null && RegExp(r'^\d+,\d\d?$').hasMatch(c[1]!);
    if (c == null ||
        RegExp(r'^\d{1,3}(?:,\d{3})+$').hasMatch(c[1]!) ||
        (decimal && unit != null && unitOf(unit[2]!) != null)) {
      words.add(w);
    } else if (decimal && c[2]!.isEmpty) {
      open.add(words.length);
      words.add(w);
    } else {
      words.addAll(_splitCommas(w, c[1]!));
    }
  }
  if (open.isEmpty) return words;
  // 맨 "A,B" 는 횟수를 맡을 수(횟수 단위, 뒤의 맨숫자)가 따로 있을 때만 소수다.
  final reps = words.any((w) => _isReps(w.t));
  return [
    for (final (i, w) in words.indexed)
      if (!open.contains(i) ||
          reps ||
          words.skip(i + 1).any((l) => _bare.hasMatch(l.t)))
        w
      else
        ..._splitCommas(w, w.t),
  ];
}

ParsedSet? _readSetLine(String line) {
  final text = line.trim();
  final words = _readWords(text);
  // 규칙 2 — 맨숫자의 몫.
  final repsUnit = words.any((w) => _isReps(w.t));
  final bareCount = words.where((w) => _bare.hasMatch(w.t)).length;
  double? value;
  String? unit;
  int? reps, count;
  // 자리에 들어간 낱말. 나머지는 친 그대로 메모가 된다.
  final used = <int>{};
  // 규칙 3 — 친 순서대로, 빈 자리만.
  for (final (i, word) in words.indexed) {
    final m = _unit.firstMatch(word.t);
    final repeat = _repeat.firstMatch(word.t);
    final known = m == null ? null : unitOf(m[2]!);
    final n = m != null
        ? _number(m[1]!)
        : _bare.hasMatch(word.t)
        ? _number(word.t)
        : null;
    final bool took;
    if (repeat != null) {
      took = count == null;
      count ??= int.parse(repeat[1]!);
    } else if (n == null) {
      took = false;
    } else if (m != null && _setWord.hasMatch(m[2]!)) {
      took = count == null;
      count ??= n.round();
    } else if (known != null ||
        (m == null && (repsUnit || (bareCount > 1 && value == null)))) {
      // 친 단위를 그대로 남긴다. 예전에는 lb 를 kg 로 바꿔 저장해서 파운드로
      // 하는 사람의 숫자가 사라졌다.
      took = value == null;
      if (took) (value, unit) = (n, known);
    } else {
      took = reps == null;
      reps ??= n.round();
    }
    if (took) used.add(i);
  }

  if (value == null && reps == null) return null;
  final rest = <String>[];
  var from = 0;
  for (final (i, word) in words.indexed) {
    if (!used.contains(i)) continue;
    rest.add(text.substring(from, word.start).trim());
    from = word.end;
  }
  rest.add(text.substring(from).trim());
  final note = rest.where((s) => s.isNotEmpty).join(' ');
  return ParsedSet(
    value: value,
    unit: unit,
    reps: reps,
    note: note.isEmpty ? null : note,
    count: count == null || count < 1 ? 1 : count,
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
