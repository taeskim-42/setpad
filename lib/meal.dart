/// 식단 한 끼의 모양과 계산. 화면 없이 테스트할 수 있게 떼어 둔다 —
/// 열량은 곱셈 한 번이지만 틀리면 하루 합계가 통째로 틀린다.
library;

import 'parser.dart';
import 'record_ai.dart';
import 'units.dart';

/// 열량의 근거. "얼마를 먹으면 몇 kcal" — 100g 에 250kcal, 1개에 120kcal,
/// 한 봉지에 300kcal, 사진 한 장에 어림 650kcal.
///
/// 먹은 양은 **같은 단위로만** 받는다. g 을 ml 로, 개를 g 으로 바꿔 주지
/// 않는다 — 그 환산에는 근거가 없다.
class MealBasis {
  const MealBasis({
    required this.kcal,
    required this.amount,
    required this.unit,
  });

  /// [amount] 만큼 먹었을 때의 열량. 반올림하지 않은 값이다.
  final double kcal;
  final double amount;

  /// 'g'·'ml'·'개' 처럼 표에 인쇄된 단위, 또는 [serving]·[package]·[photo].
  final String unit;

  static const serving = 'serving', package = 'package', photo = 'photo';

  /// 먹은 양의 열량. 반올림은 여기서 한 번만 한다. 계산할 수 없으면 null —
  /// 0 이 아니다. 0kcal 은 "먹었는데 열량이 없다" 는 다른 말이다.
  int? kcalFor(double eaten) {
    final v = kcal * eaten / amount;
    if (!kcal.isFinite ||
        !amount.isFinite ||
        !eaten.isFinite ||
        !(kcal >= 0 && kcal <= 100000 && amount > 0 && eaten >= 0) ||
        !v.isFinite ||
        v > 100000) {
      return null;
    }
    return v.round();
  }

  Map<String, Object?> toJson() => {
    'kcal': kcal,
    'amount': amount,
    'unit': unit,
  };

  static MealBasis? tryFromJson(Object? j) {
    if (j is! Map) return null;
    final kcal = j['kcal'], amount = j['amount'], unit = j['unit'];
    if (kcal is! num || amount is! num || unit is! String) return null;
    final basis = MealBasis(
      kcal: kcal.toDouble(),
      amount: amount.toDouble(),
      unit: unit,
    );
    return basis.kcalFor(0) == null ? null : basis;
  }
}

/// 성분표에서 고를 수 있는 근거들. 앞의 것이 기본이다.
///
/// 제공량에 "30g"·"1개" 같은 양이 인쇄돼 있으면 그 단위로 먹은 양을 받는다 —
/// 사람은 회분이 아니라 그램과 개수로 기억한다. 회분은 늘 고를 수 있고,
/// 총 회분이 적혀 있으면 포장 전체도 된다(한 봉지가 1회분이어도).
List<MealBasis> basesOf(NutritionLabel label) {
  final per = label.perServingKcal.toDouble();
  final printed = _printedServing(label.servingSize);
  final whole = label.servingsPerPackage;
  return [
    if (printed != null)
      MealBasis(kcal: per, amount: printed.amount, unit: printed.unit),
    MealBasis(kcal: per, amount: 1, unit: MealBasis.serving),
    if (whole != null &&
        whole.isFinite &&
        whole > 0 &&
        whole <= 10000 &&
        per * whole <= 100000)
      MealBasis(kcal: per * whole, amount: 1, unit: MealBasis.package),
  ];
}

/// Reads a whole number token, never a valid suffix of a malformed number.
double? parseMealAmount(String text) {
  var token = text.trim();
  if (RegExp(r'^[1-9]\d{0,2}(?:,\d{3})+(?:\.\d+)?$').hasMatch(token)) {
    token = token.replaceAll(',', '');
  } else if (RegExp(r'^\d+,\d{1,2}$|^0,\d+$').hasMatch(token)) {
    token = token.replaceAll(',', '.');
  } else if (!RegExp(r'^(?:\d+(?:\.\d+)?|\.\d+)$').hasMatch(token)) {
    return null;
  }
  final n = double.tryParse(token);
  return n != null && n.isFinite && n >= 0 ? n : null;
}

const _quantityNumber =
    r'(?:\d[\d.,]*(?:\s*/\s*\d[\d.,]*)?|\.\d+|½|¼|¾|반|한|두|세|네)';
const _quantityUnit =
    r'(?:kg|㎏|g|ml|㎖|l|ℓ|개|줄|컵|잔|공기|그릇|조각|봉지|인분|장|캔|병|알|접시|스푼|숟갈)';
final _mealQuantity = RegExp(
  '($_quantityNumber)\\s*($_quantityUnit)(?![A-Za-z])',
  caseSensitive: false,
);

double? _quantityValue(String text) {
  final token = text.trim();
  final word = {..._counts, '½': 0.5, '¼': 0.25, '¾': 0.75}[token];
  if (word != null) return word;
  final parts = token.split('/');
  final n = parseMealAmount(parts.first);
  if (parts.length == 1) return n;
  final d = parts.length == 2 ? parseMealAmount(parts.last) : null;
  return n != null && d != null && d > 0 ? n / d : null;
}

({double amount, String unit})? _readQuantity(Match match) {
  if (RegExp(
    r'[\d.,/+\-]\s*$',
  ).hasMatch(match.input.substring(0, match.start))) {
    return null;
  }
  final n = _quantityValue(match[1]!);
  if (n == null) return null;
  final quantity = switch (match[2]!.toLowerCase()) {
    'kg' || '㎏' => (amount: n * 1000, unit: 'g'),
    'l' || 'ℓ' => (amount: n * 1000, unit: 'ml'),
    '㎖' => (amount: n, unit: 'ml'),
    final unit => (amount: n, unit: unit),
  };
  return quantity.amount.isFinite ? quantity : null;
}

({double amount, String unit})? _printedServing(String text) {
  // Parentheses can give an equivalent weight; the leading printed unit wins.
  final main = text.replaceAll(RegExp(r'\([^()]*\)|（[^（）]*）'), '').trim();
  final matches = _mealQuantity.allMatches(main).toList();
  if (matches.length != 1) return null;
  final match = matches.single;
  final rest = main
      .replaceRange(match.start, match.end, '')
      .replaceAll(
        RegExp(
          r'\b(?:1\s*serving|per\s*serving|serving\s*size)\b|1\s*회\s*제공량|제공량|총\s*내용량|내용량|중량|용량|당|[\s:：]',
          caseSensitive: false,
        ),
        '',
      );
  if (rest.isNotEmpty) return null;
  final printed = _readQuantity(match);
  return printed != null && printed.amount > 0 ? printed : null;
}

/// 열량을 계산한 표의 한 줄. 숫자를 믿을 수 있게 **값과 링크를 같이** 둔다 —
/// 누르면 식약처 식품영양성분 DB(또는 USDA)에서 같은 이름의 줄을 본다.
class MealSource {
  const MealSource({
    required this.name,
    required this.kcalPer100,
    required this.per,
    required this.url,
    this.kind = '',
  });
  final String name;
  final double kcalPer100;

  /// 'g' 또는 'ml' — [kcalPer100] 의 100 이 무엇의 100 인가.
  final String per;
  final String url;

  /// 'usda' 면 미국 농무부 표, 'off' 면 Open Food Facts, 아니면 식약처 표다.
  final String kind;

  bool get usda => kind == 'usda';
  bool get off => kind == 'off';

  Map<String, Object?> toJson() => {
    'name': name,
    'kcalPer100': kcalPer100,
    'per': per,
    'url': url,
    'kind': kind,
  };

  /// 서버 답과 저장본이 같은 모양이다. https 가 아닌 링크는 받지 않는다 —
  /// 기기 브라우저로 여는 주소다.
  static MealSource? tryFromJson(Object? j) {
    if (j is! Map) return null;
    final name = j['name'], kcal = j['kcalPer100'], per = j['per'];
    final url = j['url'], kind = j['kind'];
    if (name is! String || kcal is! num || per is! String || url is! String) {
      return null;
    }
    if (Uri.tryParse(url)?.scheme != 'https') return null;
    return MealSource(
      name: name,
      kcalPer100: kcal.toDouble(),
      per: per,
      url: url,
      kind: kind is String ? kind : '',
    );
  }

  static List<MealSource> listFrom(Object? j) => [
    for (final s in (j is List ? j : const [])) ?tryFromJson(s),
  ];
}

/// 글에서 알아본 음식 하나. 양을 못 알아봤으면 이름만 있다.
class MealFood {
  const MealFood(this.name, [this.amount, this.unit]);
  final String name;
  final double? amount;
  final String? unit;

  Map<String, Object?> toJson() => {
    'name': name,
    'amount': ?amount,
    'unit': ?unit,
  };

  static MealFood? tryFromJson(Object? j) {
    if (j is! Map || j['name'] is! String) return null;
    final amount = j['amount'], unit = j['unit'];
    return MealFood(
      j['name'] as String,
      amount is num ? amount.toDouble() : null,
      unit is String ? unit : null,
    );
  }

  @override
  String toString() => 'MealFood($name, $amount, $unit)';
}

const _counts = {'반': 0.5, '한': 1.0, '두': 2.0, '세': 3.0, '네': 4.0};

/// Only unambiguous consumed calories are returned in [typed].
/// Ambiguous labels, ranges and conflicting totals must not become AI lower bounds.
({List<MealFood> foods, int? kcal, int? typed, bool needsReview}) parseMealText(
  String text,
) {
  final plain = text.replaceAllMapped(RegExp(r'\d[\d.,]*'), (m) {
    final token = m[0]!;
    return token.contains(',') && parseMealAmount(token) != null
        ? parseMealAmount(token).toString()
        : token;
  });
  final quantity = RegExp(
    '\\s*($_quantityNumber)\\s*($_quantityUnit)\$',
    caseSensitive: false,
  );
  final names = <String>[];
  final clauses = <String>[];
  for (final raw in plain.split(RegExp(r'[,，、\n]'))) {
    if (clauses.isNotEmpty &&
        (_aside(raw.trim()) || raw.replaceAll(_energy, '').trim().isEmpty)) {
      clauses.last += ' $raw';
    } else if (raw.trim().isNotEmpty) {
      clauses.add(raw);
    }
    for (final p in raw.split(_energy)) {
      final part = p.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (part.isEmpty) continue;
      if (names.isNotEmpty && _aside(part)) {
        names.last = '${names.last} $part';
      } else {
        names.add(part);
      }
    }
  }
  final foods = [
    for (final part in names)
      if (quantity.firstMatch(part) case final m?
          when part.substring(0, m.start).trim().isNotEmpty &&
              _quantityValue(m[1]!) != null)
        MealFood(
          part.substring(0, m.start).trim(),
          _quantityValue(m[1]!),
          m[2]!.toLowerCase(),
        )
      else
        MealFood(part),
  ];
  final reading = _readCalories(plain, clauses, names.length);
  return (
    foods: foods,
    kcal: reading.kcal,
    typed: reading.typed,
    needsReview: reading.needsReview,
  );
}

final _energy = RegExp(
  r'(?<![A-Za-z\d.,/+\-])([+-]?(?:\d[\d.,]*(?:\s*/\s*\d[\d.,]*)?|\.\d+))\s*'
  r'(?:kcal|칼로리|㎉)(?:\s*(?:정도|쯤|가량|짜리|씩))?',
  caseSensitive: false,
);
const _totalWords = r'(?:총\s*칼로리|총열량|총(?:합계|합|계|량)?|합계|전체|합쳐서|합해서|합산|도합|total)';
final _totalPrefix = RegExp(
  '(?:^|\\s)$_totalWords(?:은|는|이|가)?(?:\\s*[:=]\\s*|\\s*)\$',
  caseSensitive: false,
);
final _portionModifier = RegExp(
  r'반\s*의?\s*반|반\s*만|(?:^|\s)반(?=\s*(?:먹|섭취|마))|절반|남[겼김]|나눠|조금|일부|'
  r'\d+(?:\.\d+)?\s*%|먹지\s*않|마시지\s*않|(?:안|못)\s*(?:먹|마)|\bhalf\b',
  caseSensitive: false,
);

({int? kcal, int? typed, bool needsReview}) _readCalories(
  String text,
  List<String> clauses,
  int foodCount,
) {
  const unknown = (kcal: null, typed: null, needsReview: true);
  final matches = _energy.allMatches(text).toList();
  if (matches.isEmpty) {
    return (kcal: null, typed: null, needsReview: _kcal.hasMatch(text));
  }
  if (RegExp(
    r'[~〜～‐‑‒–—―−﹣－]|\d\s*-\s*\d|kcal\s*-|\d[eE]\d|이상|이하|미만|초과|또는|대신|제외|빼고|빼서|뺌|뺀|비교|보다|안\s*먹|못\s*먹|먹지\s*않|\b(?:or|minus|less|between)\b|'
    r'(?:kcal|칼로리|㎉)\s*(?:짜리\s*)?(?:에서|중|가운데|to\b)',
    caseSensitive: false,
  ).hasMatch(text)) {
    return unknown;
  }
  if (matches.any((m) => parseMealAmount(m[1]!) == null)) return unknown;
  final totals = <double>[];
  final values = <double>[];
  var count = 0;
  for (final clause in clauses) {
    final calories = _energy.allMatches(clause).toList();
    final modifier = _portionModifier.hasMatch(clause);
    if (modifier &&
        (calories.isNotEmpty ||
            _aside(clause.replaceAll(_portionModifier, '')))) {
      return unknown;
    }
    final ordinary = <RegExpMatch>[];
    for (final m in calories) {
      final n = parseMealAmount(m[1]!);
      if (n == null || n > 100000) return unknown;
      if (_totalPrefix.hasMatch(clause.substring(0, m.start))) {
        totals.add(n);
      } else {
        ordinary.add(m);
      }
    }
    final quantities = _mealQuantity.allMatches(clause).toList();
    final perUnit = RegExp(
      '($_quantityUnit)\\s*당',
      caseSensitive: false,
    ).firstMatch(clause)?[1]?.toLowerCase();
    final each = RegExp(
      r'(?:kcal|칼로리|㎉)\s*(?:짜리|씩)',
      caseSensitive: false,
    ).hasMatch(clause);
    final basisMarker =
        perUnit != null ||
        each ||
        quantities.any(
          (q) => clause.substring(q.end).trimLeft().startsWith('당'),
        ) ||
        RegExp(r'기준|\bper\b|kcal\s*/', caseSensitive: false).hasMatch(clause);
    if (quantities.any((q) => _readQuantity(q) == null)) return unknown;
    final fractionalTail =
        calories.isNotEmpty &&
        quantities.any(
          (q) => q.start >= calories.last.end && _readQuantity(q)!.amount < 1,
        );
    if (ordinary.isEmpty) {
      if (calories.isNotEmpty &&
          (basisMarker || quantities.length > 1 || fractionalTail)) {
        return unknown;
      }
      continue;
    }
    for (var i = 1; i < ordinary.length; i++) {
      if (_aside(clause.substring(ordinary[i - 1].end, ordinary[i].start))) {
        return unknown;
      }
    }
    if (ordinary.length == 1 &&
        quantities.length == 1 &&
        quantities.single.start >= ordinary.single.end &&
        (perUnit != null || each)) {
      final eaten = _readQuantity(quantities.single)!;
      if (!_aside(clause.substring(quantities.single.end)) ||
          (perUnit != null && perUnit != eaten.unit) ||
          (perUnit == null && const ['g', 'ml'].contains(eaten.unit))) {
        return unknown;
      }
      values.add(parseMealAmount(ordinary.single[1]!)! * eaten.amount);
      count++;
    } else if (ordinary.length == 1 &&
        quantities.length == 2 &&
        quantities.first.end <= ordinary.single.start &&
        quantities.last.start >= ordinary.single.end) {
      final basis = _readQuantity(quantities.first);
      final eaten = _readQuantity(quantities.last);
      // No density conversion or guessing how much of a package was eaten.
      if (basis == null ||
          eaten == null ||
          basis.amount <= 0 ||
          basis.unit != eaten.unit) {
        return unknown;
      }
      final between = clause.substring(
        ordinary.single.end,
        quantities.last.start,
      );
      final tail = clause.substring(quantities.last.end);
      if (!_aside('$between $tail')) return unknown;
      values.add(
        parseMealAmount(ordinary.single[1]!)! * eaten.amount / basis.amount,
      );
      count++;
    } else {
      if (basisMarker ||
          (ordinary.length == 1 && quantities.length > 1) ||
          fractionalTail) {
        return unknown;
      }
      values.addAll(ordinary.map((m) => parseMealAmount(m[1]!)!));
      count += ordinary.length;
    }
  }
  final sum = values.fold<double>(0, (a, b) => a + b);
  if (!sum.isFinite || sum > 100000) return unknown;
  if (count > 1 && count > foodCount) return unknown;
  if (totals.isNotEmpty) {
    final total = totals.first;
    if (totals.any((n) => n != total) ||
        sum.round() > total.round() ||
        (values.isNotEmpty &&
            foodCount <= count &&
            sum.round() != total.round())) {
      return unknown;
    }
    return (kcal: total.round(), typed: total.round(), needsReview: false);
  }
  final typed = values.isEmpty ? null : sum.round();
  return (
    kcal: foodCount > count ? null : typed,
    typed: typed,
    needsReview: false,
  );
}

/// 음식이 아니라 앞 음식에 붙는 말뿐인 토막인가: 양("한 잔", "2개", "(100g)",
/// "2 cups"), 먹었다는 말("먹음", "먹었어요"), 어림 말("정도", "총"). 이것들을
/// 지우고 남는 글자가 없어야 한다 — '총각김치' 는 '각김치' 가 남아 음식이다.
bool _aside(String part) => part
    .replaceAll(RegExp(r'[(\[（][^)\]）]*[)\]）]'), ' ')
    .replaceAll(
      RegExp(
        '$_quantityNumber\\s*'
        r'(?:kg|g|ml|l|개|줄|컵|잔|공기|그릇|조각|봉지|인분|장|캔|병|알|접시|스푼|숟갈|'
        r'cups?|glass(?:es)?|pieces?|slices?|bowls?|servings?)(?![A-Za-z])',
        caseSensitive: false,
      ),
      ' ',
    )
    .replaceAll(
      RegExp(
        r'먹(?:음|었[가-힣]*|은\s*듯|고)|마심|마셨[가-힣]*|섭취(?:함|했[가-힣]*)?|'
        '정도|쯤|가량|대략|약|$_totalWords(?:은|는|이|가)?|'
        r'\b(?:ate|had|eaten|drank|about|around|approx|total)\b',
        caseSensitive: false,
      ),
      ' ',
    )
    .replaceAll(RegExp(r'[\s().~!?·:=\[\]（）：-]'), '')
    .isEmpty;

/// 친 줄에 **끼니라는 근거**가 있는가 — 판정자(Solar·음식 표)가 답하지 못했을 때만
/// 쓴다(연결 없음, 시간 초과). 열량(kcal·칼로리), 음식에만 쓰는 양([foodUnits]), 끼니
/// 낱말(아침·점심·저녁·간식·야식)에 다른 말이 붙은 글, 흔한 음식 낱말(밥·계란·커피·
/// 맥주·salad…).
bool mealEvidence(String text) {
  if (_kcal.hasMatch(text) || clearMealEvidence(text)) return true;
  final bare = [
    for (final w in text.trim().split(RegExp(r'\s+')))
      w.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '').toLowerCase(),
  ]..removeWhere((w) => w.isEmpty);
  final words = bare.map(stripParticle).toList();
  return (words.length > 1 && words.any(_mealWords.contains)) ||
      [...bare, ...words].any(foodWords.contains);
}

/// 끼니라는 근거가 **분명한가** — 음식에만 쓰는 양(g·ml·공기·인분·잔…). 운동에는 이
/// 단위가 없어 뜻이 하나뿐이라 판정자에게 묻지 않는다. 열량(kcal)은 소모 열량일 수도
/// 있어 여기 넣지 않는다('트레드밀 300kcal').
bool clearMealEvidence(String text) => foodUnits.hasMatch(text);

final _kcal = RegExp(r'kcal|칼로리|㎉', caseSensitive: false);

const _mealWords = {
  '아침', '점심', '저녁', '간식', '야식', '아점', '브런치', //
  'breakfast', 'lunch', 'dinner', 'supper', 'snack', 'brunch',
};

/// 먹은 양을 글로. "150g", "2.5개", "1.5회분" 은 화면 언어가 붙인다.
String amountText(double n) => formatNumber((n * 100).round() / 100);

/// 먹은 양의 탄단지(g). 표에 값이 없는 음식이 하나라도 있으면 끼니 전체를 모른다(null) — 일부만 더한
/// 수는 한 끼 전체처럼 읽힌다.
typedef MealMacros = ({double carbs, double protein, double fat});

MealMacros? mealMacrosFromJson(Object? j) {
  if (j is! Map) return null;
  double? g(Object? v) =>
      v is num && v.isFinite && v >= 0 && v <= 10000 ? v.toDouble() : null;
  final carbs = g(j['carbs']), protein = g(j['protein']), fat = g(j['fat']);
  return carbs == null || protein == null || fat == null
      ? null
      : (carbs: carbs, protein: protein, fat: fat);
}

Map<String, Object?> mealMacrosToJson(MealMacros m) => {
  'carbs': m.carbs,
  'protein': m.protein,
  'fat': m.fat,
};
