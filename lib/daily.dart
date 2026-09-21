/// 하루 단위 집계 — 먹은 것과 운동으로 쓴 것.
///
/// **들고 있는 합계가 없다.** 문서 머리의 한 줄은 볼 때마다 [dayLogs] 로 다시
/// 센다. 고치거나 지우면 다음 집계에 그대로 반영된다.
///
/// 규칙은 셋이다.
///  1. **없는 것은 0 이 아니다.** 안 적은 식단, 안 잰 운동 소모량, 열량을 모르는
///     음식은 null 이거나 따로 센다. 0 으로 채우면 평균이 거짓이 된다.
///  2. **차이는 섭취 − 운동이다.** 기록된 섭취량에서 운동 소모량을 뺀 값이고,
///     휴식과 일상생활에서 쓰는 에너지는 들어 있지 않다. 몸의 변화를 이 값으로
///     환산하거나 예측하지 않는다.
///  3. **날짜는 기기의 현지 날짜다.** 끼니는 먹은 시각, 운동은 문서를 만든 시각
///     (문서 머리의 날짜와 같다)이 속한 날에 들어간다.
library;

import 'l10n/generated/app_localizations.dart';
import 'notes.dart';

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// 하루치. 값이 null 이면 **기록이 없다**는 뜻이지 0 이 아니다.
class DayLog {
  DayLog(this.day);
  final DateTime day;

  /// 그날 끼니들(문서가 여럿이어도 id 로 한 번씩만).
  final List<MealEntry> meals = [];

  /// 그날 만든 운동 문서들.
  final List<Note> notes = [];

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
}

/// [from] 부터 [to] 까지(양 끝 날짜 포함) 기록이 있는 날들, 날짜순.
/// 기록이 없는 날은 만들지 않는다.
List<DayLog> dayLogs(
  List<Note> notes, {
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
  for (final d in days.values) {
    d.meals.sort((a, b) => a.at.compareTo(b.at));
  }
  return days.values.toList()..sort((a, b) => a.day.compareTo(b.day));
}

/// 하루의 에너지 한 줄. 없는 것은 없다고 쓴다 — 0 으로 채우지 않는다.
String? dayEnergyText(L l, DayLog day) {
  final intake = day.intake, burned = day.burned;
  if (intake == null && burned == null) return null;
  if (intake == null) return l.dayBurnedOnly(burned!.round());
  if (day.unknownMeals > 0) {
    return l.mealIntakePartial(intake, day.unknownMeals);
  }
  if (burned == null) {
    final eaten = day.intakeEstimated ? l.kcalApprox(intake) : l.kcal(intake);
    return '${l.intakeLabel} $eaten · ${l.dayBurnedMissing}';
  }
  return (day.intakeEstimated ? l.dayEnergyApprox : l.dayEnergyFull)(
    intake,
    burned.round(),
    day.difference!,
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
