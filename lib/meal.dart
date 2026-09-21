/// 식단 한 끼의 모양과 계산. 화면 없이 테스트할 수 있게 떼어 둔다 —
/// 열량은 곱셈 한 번이지만 틀리면 하루 합계가 통째로 틀린다.
library;

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
    if (!(kcal >= 0 && amount > 0 && eaten >= 0) || !v.isFinite || v > 100000) {
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
  final printed = RegExp(
    r'(\d+(?:\.\d+)?)\s*(g|ml|㎖|개|조각|장|알|봉지|캔|병|컵)',
    caseSensitive: false,
  ).firstMatch(label.servingSize);
  final amount = printed == null ? null : double.parse(printed[1]!);
  final whole = label.servingsPerPackage;
  return [
    if (amount != null && amount > 0)
      MealBasis(
        kcal: per,
        amount: amount,
        unit: printed![2]!.toLowerCase().replaceAll('㎖', 'ml'),
      ),
    MealBasis(kcal: per, amount: 1, unit: MealBasis.serving),
    if (whole != null && whole > 0)
      MealBasis(kcal: per * whole, amount: 1, unit: MealBasis.package),
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

/// 친 식단 글을 **확인되는 만큼만** 구조로 읽는다. 원문은 부르는 쪽이 그대로
/// 저장한다 — 여기서 못 읽었다고 기록이 거부되지 않는다.
///
/// 쉼표로 음식을 가르고, 각 음식 끝의 "150g"·"2개"·"한 줄"·"반 개" 를 양으로
/// 읽는다. "450kcal" 은 사람이 직접 적은 열량이다. 음식 사전을 찾지 않는다.
({List<MealFood> foods, int? kcal}) parseMealText(String text) {
  final energy = RegExp(
    r'(\d+(?:\.\d+)?)\s*(?:kcal|칼로리|㎉)',
    caseSensitive: false,
  );
  final typed = energy.allMatches(text).map((m) => double.parse(m[1]!));
  final quantity = RegExp(
    r'\s*(\d+(?:\.\d+)?|반|한|두|세|네)\s*'
    r'(kg|g|ml|l|개|줄|컵|공기|그릇|조각|봉지|인분|장|캔|병|알|접시|스푼|숟갈)$',
    caseSensitive: false,
  );
  final foods = <MealFood>[];
  for (final raw in text.replaceAll(energy, ' ').split(RegExp(r'[,，、\n]'))) {
    final part = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (part.isEmpty) continue;
    final m = quantity.firstMatch(part);
    final name = m == null ? part : part.substring(0, m.start).trim();
    foods.add(
      m == null || name.isEmpty
          ? MealFood(part)
          : MealFood(
              name,
              _counts[m[1]] ?? double.parse(m[1]!),
              m[2]!.toLowerCase(),
            ),
    );
  }
  final total = typed.fold<double>(0, (n, v) => n + v);
  return (
    foods: foods,
    kcal: typed.isEmpty || total > 100000 ? null : total.round(),
  );
}

/// 먹은 양을 글로. "150g", "2.5개", "1.5회분" 은 화면 언어가 붙인다.
String amountText(double n) => formatNumber((n * 100).round() / 100);
