/// 하루 단위 집계 — 먹은 것, 운동으로 쓴 것, 실제로 잰 몸.
///
/// **화면마다 따로 세지 않는다.** 오늘 문서의 한 줄도, 기간 그래프도, 요약도
/// 전부 여기의 [dayLogs] 와 [summarize] 를 쓴다. 고치거나 지우면 다음 집계에
/// 그대로 반영된다 — 들고 있는 합계가 없기 때문이다.
///
/// 규칙은 셋이다.
///  1. **없는 것은 0 이 아니다.** 안 적은 식단, 안 잰 운동 소모량, 열량을 모르는
///     음식은 null 이거나 따로 센다. 0 으로 채우면 평균이 거짓이 된다.
///  2. **차이는 섭취 − 운동이다.** 기록된 섭취량에서 운동 소모량을 뺀 값이고,
///     휴식과 일상생활에서 쓰는 에너지는 들어 있지 않다. 몸의 변화를 이 값으로
///     환산하거나 예측하지 않는다 — 몸은 실제로 잰 값으로만 말한다.
///  3. **날짜는 기기의 현지 날짜다.** 끼니는 먹은 시각, 운동은 문서를 만든 시각
///     (문서 머리의 날짜와 같다), 체중은 잰 시각이 속한 날에 들어간다.
library;

import 'notes.dart';
import 'units.dart';

const _kgPerLb = 0.45359237;

/// 실제로 잰 체중 하나. 친 숫자와 단위를 그대로 들고 있다.
class WeightEntry {
  WeightEntry({
    required this.at,
    required this.value,
    this.unit = defaultUnit,
    this.source = manual,
    String? id,
  }) : id = id ?? 'w${at.microsecondsSinceEpoch.toRadixString(36)}';

  /// 직접 입력은 시각으로 지은 이름, 건강 앱에서 온 것은 그쪽의 고유 id 다 —
  /// 같은 측정을 두 번 가져와도 하나로 남는다.
  final String id;
  final DateTime at;
  final double value;
  final String unit;
  final String source;
  static const manual = 'manual', health = 'health';

  double get kg => unit == 'lb' ? value * _kgPerLb : value;

  /// 보여 줄 단위로. 저장된 값은 바뀌지 않는다.
  double inUnit(String to) => to == 'lb' ? kg / _kgPerLb : kg;

  static bool valid(double value, String unit) {
    final kg = unit == 'lb' ? value * _kgPerLb : value;
    return kg.isFinite && kg >= 20 && kg <= 400;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'at': at.toIso8601String(),
    'value': value,
    'unit': unit,
    'source': source,
  };

  static WeightEntry? tryFromJson(Object? j) {
    if (j is! Map) return null;
    final at = j['at'], value = j['value'], unit = j['unit'];
    final when = at is String ? DateTime.tryParse(at) : null;
    if (when == null || value is! num) return null;
    final u = unit == 'lb' ? 'lb' : 'kg';
    if (!valid(value.toDouble(), u)) return null;
    return WeightEntry(
      id: j['id'] is String ? j['id'] as String : null,
      at: when,
      value: value.toDouble(),
      unit: u,
      source: j['source'] == health ? health : manual,
    );
  }
}

/// "72.4kg". 소수 한 자리 — 체중계가 그만큼만 말한다.
String formatWeight(WeightEntry w, String unit) =>
    '${formatNumber((w.inUnit(unit) * 10).round() / 10)}${unitById[unit]?.label ?? unit}';

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// 하루치. 값이 null 이면 **기록이 없다**는 뜻이지 0 이 아니다.
class DayLog {
  DayLog(this.day);
  final DateTime day;

  /// 그날 끼니들(문서가 여럿이어도 id 로 한 번씩만).
  final List<MealEntry> meals = [];

  /// 그날 만든 운동 문서들.
  final List<Note> notes = [];

  /// 그날 잰 체중 전부, 시간순. 원본을 버리지 않는다.
  final List<WeightEntry> weights = [];

  /// 열량을 아는 끼니의 합. 끼니를 하나도 안 적었으면 null.
  int? get intake =>
      meals.isEmpty ? null : meals.fold<int>(0, (n, m) => n + (m.kcal ?? 0));
  int get unknownMeals => meals.where((m) => m.kcal == null).length;

  /// 어림값이 섞였는가. 섞였으면 결과에도 "약" 이 붙는다.
  bool get intakeEstimated => meals.any((m) => m.approximate);

  /// 워치가 잰 운동 중 활동 에너지의 합. 잰 문서가 하나도 없으면 null.
  double? get burned {
    final measured = notes.where((n) => n.calories != null);
    return measured.isEmpty
        ? null
        : measured.fold<double>(0, (n, note) => n + note.calories!);
  }

  /// 섭취 − 운동. 둘 다 있고 열량 미상이 없을 때만 있다.
  int? get difference {
    final eaten = intake, used = burned;
    if (eaten == null || used == null || unknownMeals > 0) return null;
    return eaten - used.round();
  }

  /// 그날의 대표 체중 — **그날 처음 잰 값.** 아침 공복에 재는 것이 서로
  /// 견주기 좋고, 규칙이 하나여야 날마다 같은 뜻이 된다.
  WeightEntry? get weight => weights.firstOrNull;

  bool get isEmpty => meals.isEmpty && notes.isEmpty && weights.isEmpty;
}

/// [from] 부터 [to] 까지(양 끝 날짜 포함) 기록이 있는 날들, 날짜순.
/// 기록이 없는 날은 만들지 않는다.
List<DayLog> dayLogs(
  List<Note> notes,
  List<WeightEntry> weights, {
  required DateTime from,
  required DateTime to,
}) {
  final first = dayOf(from), last = dayOf(to);
  bool within(DateTime t) {
    final d = dayOf(t);
    return !d.isBefore(first) && !d.isAfter(last);
  }

  final days = <DateTime, DayLog>{};
  DayLog at(DateTime t) => days.putIfAbsent(dayOf(t), () => DayLog(dayOf(t)));
  final seenMeals = <String>{};
  for (final note in notes) {
    // 세트도 칼로리도 없는 빈 문서는 운동한 날로 치지 않는다.
    final worked =
        note.calories != null ||
        note.blocks.any((b) => b.sets.any((s) => s.done));
    if (worked && within(note.createdAt)) at(note.createdAt).notes.add(note);
    for (final meal in note.meals) {
      if (!within(meal.at) || !seenMeals.add(meal.id)) continue;
      at(meal.at).meals.add(meal);
    }
  }
  final seenWeights = <String>{};
  for (final w in weights) {
    if (within(w.at) && seenWeights.add(w.id)) at(w.at).weights.add(w);
  }
  for (final d in days.values) {
    d.weights.sort((a, b) => a.at.compareTo(b.at));
    d.meals.sort((a, b) => a.at.compareTo(b.at));
  }
  return days.values.toList()..sort((a, b) => a.day.compareTo(b.day));
}

/// 기간 요약. 평균마다 **제 분모**를 들고 다닌다 — 섭취를 적은 날과 운동을 잰
/// 날은 다른 날들이라서, 두 평균을 빼면 아무 뜻도 없는 숫자가 된다. 차이의
/// 평균은 둘 다 있는 날들만으로 따로 낸다.
class PeriodSummary {
  const PeriodSummary({
    required this.intakeDays,
    required this.intakeAverage,
    required this.burnedDays,
    required this.burnedAverage,
    required this.differenceDays,
    required this.differenceAverage,
    required this.incompleteDays,
    required this.estimated,
    required this.firstWeight,
    required this.lastWeight,
  });

  /// 열량 미상 없이 섭취를 적은 날 수와 그 평균.
  final int intakeDays;
  final int? intakeAverage;
  final int burnedDays;
  final int? burnedAverage;
  final int differenceDays;
  final int? differenceAverage;

  /// 끼니는 적었는데 열량 미상이 섞인 날 수. 평균에서 빠진 날들이다.
  final int incompleteDays;
  final bool estimated;

  /// 기간 안에서 실제로 잰 첫 값과 마지막 값. 하루뿐이면 둘이 같다.
  final WeightEntry? firstWeight, lastWeight;

  /// 체중 변화(kg). 서로 다른 날에 잰 값이 둘 이상일 때만 있다.
  double? get weightChangeKg =>
      firstWeight == null ||
          lastWeight == null ||
          dayOf(firstWeight!.at) == dayOf(lastWeight!.at)
      ? null
      : lastWeight!.kg - firstWeight!.kg;
}

PeriodSummary summarize(List<DayLog> days) {
  int? mean(Iterable<num> values) => values.isEmpty
      ? null
      : (values.fold<num>(0, (a, b) => a + b) / values.length).round();
  final eaten = days.where((d) => d.intake != null && d.unknownMeals == 0);
  final used = days.where((d) => d.burned != null);
  final both = days.where((d) => d.difference != null);
  final weighed = days.where((d) => d.weight != null).toList();
  return PeriodSummary(
    intakeDays: eaten.length,
    intakeAverage: mean(eaten.map((d) => d.intake!)),
    burnedDays: used.length,
    burnedAverage: mean(used.map((d) => d.burned!)),
    differenceDays: both.length,
    differenceAverage: mean(both.map((d) => d.difference!)),
    incompleteDays: days.where((d) => d.unknownMeals > 0).length,
    estimated: eaten.any((d) => d.intakeEstimated),
    firstWeight: weighed.firstOrNull?.weight,
    lastWeight: weighed.lastOrNull?.weight,
  );
}

/// 이 문서의 운동 시간대에서 **다른 문서가 이미 잰 구간을 뺀** 시작 시각.
///
/// 활동 에너지는 문서가 열려 있던 시간으로 잰다. 같은 날 문서가 둘이고 시간이
/// 겹치면 겹친 구간이 두 번 더해진다. 먼저 만든 문서들의 끝 시각 뒤에서만 잰다.
///
/// 끝은 [sessionEnd] 가 자른다 — 저녁에 문서를 다시 열어 고쳤다고 그사이 하루
/// 치 활동 에너지가 "운동 칼로리" 가 되면 안 된다.
/// ponytail: 4시간보다 긴 운동은 잘린다. 세트마다 시각을 남기게 되면 마지막
/// 세트 시각으로 바꾼다.
const maxSession = Duration(hours: 4);

DateTime sessionEnd(Note note) {
  final cap = note.createdAt.add(maxSession);
  return note.updatedAt.isBefore(cap) ? note.updatedAt : cap;
}

DateTime sessionStart(Note note, List<Note> all) {
  var start = note.createdAt;
  for (final other in all) {
    if (identical(other, note) || other.calories == null) continue;
    if (other.createdAt.isAfter(note.createdAt)) continue;
    final end = sessionEnd(other);
    if (end.isAfter(start)) start = end;
  }
  return start;
}
