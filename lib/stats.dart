/// Compute quantities from completed records within an explicitly chosen scope.
/// Missing contributing measurements never become zero or partial totals.
library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'daily.dart';
import 'l10n/generated/app_localizations.dart';
import 'parser.dart';
import 'editor.dart';
import 'notes.dart';
import 'quantities.dart';
import 'units.dart';

/// 무엇을 물었는가.
///
/// [best] 는 운동마다 뜻이 다르다 — [resolveBest] 가 [max]·[longest]·
/// [maxReps] 중 하나로 바꾼다. [longest] 는 그 갈래에서만 쓴다.
enum Metric {
  max,
  trend,
  last,
  sessions,
  volume,
  reps,
  sets,
  average,
  best,
  e1rm,
  maxReps,
  distance,
  duration,
  first,
  daysSince,
  longest,

  /// 첫날 최고 → 마지막 날 최고의 변화율(%). 속도(%/주)는 [Answer.rate].
  changePct,

  /// 최고에 마지막으로 닿은 날부터 오늘까지.
  daysSinceBest,

  /// 최고에 마지막으로 닿은 뒤 한 운동일 수 — 그만둔 운동이 '정체' 로 오르지 않는다.
  sessionsSinceBest,

  /// 세트당 반복.
  meanReps,

  /// 날 모음 측정 — [dayAnswer].
  longestStreak,
  longestGap,
  meanGap,

  /// 끼니·워치 측정 — [energyAnswer].
  intake,
  burned,
  balance,
}

/// 운동한 날들로만 세는 측정.
const dayMetrics = {Metric.longestStreak, Metric.longestGap, Metric.meanGap};

/// 끼니와 워치 kcal 로 세는 측정.
const energyMetrics = {Metric.intake, Metric.burned, Metric.balance};

/// 한 운동의 하루치. 그날 가장 무겁게 든 세트를 그날의 값으로 삼는다.
class DayPoint {
  const DayPoint(this.day, this.value, this.reps, this.unit);
  final DateTime day;
  final double value;
  final int reps;
  final String unit;
}

/// 답 하나. 숫자는 이미 다 세어져 있고 화면은 그리기만 한다.
class Answer {
  const Answer({
    required this.metric,
    required this.exercise,
    required this.points,
    this.headline,
    this.numericValue,
    this.lines = const [],
    this.unit,
    this.rate,
  });

  final Metric metric;
  final String exercise;

  /// 시간순. [Metric.trend] 는 이것을 점으로 그리고, 나머지도 있으면 함께 그린다.
  final List<DayPoint> points;

  /// 한 줄 답. 없으면 화면이 점만 보여준다.
  final String? headline;
  final double? numericValue;

  /// 번호를 붙여 아래에 까는 짧은 사실들.
  final List<String> lines;

  /// [numericValue] 의 단위(kg, 회, 세트, 일, km, kcal …). 점이 없는 답(0 으로
  /// 채운 칸, 날 모음)도 단위를 안다 — 차이·합계가 점에서 단위를 읽으면 빈 칸에서 죽는다.
  final String? unit;

  /// 성장의 속도: 주당 변화(추이는 단위/주, 변화율은 %/주). 순위와 차이는 폭이 다른
  /// 운동끼리 총 변화가 아니라 이것으로 견준다.
  final double? rate;

  Answer copyWith({
    String? exercise,
    String? headline,
    double? numericValue,
    List<String>? lines,
    String? unit,
    List<DayPoint>? points,
  }) => Answer(
    metric: metric,
    exercise: exercise ?? this.exercise,
    points: points ?? this.points,
    headline: headline ?? this.headline,
    numericValue: numericValue ?? this.numericValue,
    lines: lines ?? this.lines,
    unit: unit ?? this.unit,
    rate: rate,
  );

  bool get isEmpty => points.isEmpty && headline == null;
}

/// 이름이 [query] 인 운동의 세트를 날짜와 함께 모은다.
///
/// **해낸 세트만 센다.** 취소한 세트는 기록이 아니다. 같이 고친 기록의 옆
/// 사람 세트도 내 기록이 아니다([LoggedSet.mine]).
Iterable<(DateTime, LoggedSet)> _sets(List<Note> notes, String query) sync* {
  final want = query.trim().toLowerCase();
  for (final note in notes) {
    for (final block in note.blocks) {
      if (searchKey(block.exercise) != searchKey(want)) continue;
      for (final set in block.sets) {
        if (set.mine &&
            set.value != null &&
            set.value!.isFinite &&
            set.value! >= 0 &&
            (set.unit == 'kg' || set.unit == 'lb')) {
          yield (note.createdAt, set);
        }
      }
    }
  }
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// 달력으로 센 날 수. 서머타임으로 23시간인 날도 하루다.
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// 이름이 정확히 [exercise] 인 블록의 해낸 세트를 그날과 함께. [since] 전의
/// 날은 뺀다.
List<(DateTime, LoggedSet)> _done(
  List<Note> notes,
  String exercise,
  DateTime? since,
) => [
  for (final note in notes)
    if (since == null || !_day(note.createdAt).isBefore(_day(since)))
      for (final block in note.blocks)
        if (block.exercise == exercise)
          for (final set in block.sets)
            if (set.mine) (_day(note.createdAt), set),
];

/// 세트에 적힌 숫자의 종류. 숫자가 없으면 null 이다.
UnitKind? _kind(LoggedSet set) =>
    set.value != null && set.value!.isFinite ? unitById[set.unit]?.kind : null;

// 거리는 m, 시간은 초로 바꾸는 배수.
const _base = {
  'km': 1000.0,
  'm': 1.0,
  'mi': 1609.344,
  's': 1.0,
  'min': 60.0,
  'h': 3600.0,
};

/// 이 운동에서 "최고" 가 무엇인가. 무게를 적었으면 무게, 아니면 시간 →
/// 거리 → 한 세트 반복 순이다. 기록 값을 보고 기기에서 정한다.
Metric resolveBest(List<Note> notes, String exercise, {DateTime? since}) {
  final kinds = {for (final (_, s) in _done(notes, exercise, since)) _kind(s)};
  if (kinds.contains(UnitKind.weight)) return Metric.max;
  if (kinds.contains(UnitKind.duration) || kinds.contains(UnitKind.distance)) {
    return Metric.longest;
  }
  return Metric.maxReps;
}

/// 하루에 하나씩, 그날 가장 무거웠던 세트.
List<DayPoint> dailyBest(
  List<Note> notes,
  String exercise, {
  String unit = 'kg',
}) {
  final best = <DateTime, DayPoint>{};
  for (final (at, set) in _sets(notes, exercise)) {
    final day = _day(at);
    final now = DayPoint(day, _weight(set, unit), set.reps ?? 0, unit);
    final prev = best[day];
    if (prev == null || now.value > prev.value) best[day] = now;
  }
  final out = best.values.toList()..sort((a, b) => a.day.compareTo(b.day));
  return out;
}

/// 물어본 것에 답한다. 맞는 기록이 없으면 [Answer.isEmpty] 다.
Answer answer(
  List<Note> notes,
  Metric metric,
  String exercise, {
  DateTime? since,
  DateTime? now,
  L? labels,
  String unit = 'kg',
}) {
  if (metric == Metric.best) {
    return answer(
      notes,
      resolveBest(notes, exercise, since: since),
      exercise,
      since: since,
      now: now,
      labels: labels,
      unit: unit,
    );
  }
  final l = labels ?? lookupL(const Locale('ko'));
  String date(DateTime d) => DateFormat.MMMd(l.localeName).format(d);
  final today = now ?? DateTime.now();
  final empty = Answer(metric: metric, exercise: exercise, points: const []);
  final picked = _done(notes, exercise, since);
  if (dayMetrics.contains(metric)) {
    return dayAnswer(
      {for (final (d, _) in picked) d}.toList(),
      metric,
      end: today,
      labels: l,
      exercise: exercise,
    );
  }
  // 끼니·워치는 운동 칸이 아니라 날에 붙는다 — [energyAnswer] 가 센다.
  if (energyMetrics.contains(metric)) return empty;
  // 이 측정이 모든 세트에 요구하는 숫자의 종류. 최장은 시간을 적었으면 시간이다.
  final needs = switch (metric) {
    Metric.max ||
    Metric.average ||
    Metric.volume ||
    Metric.trend ||
    Metric.changePct ||
    Metric.daysSinceBest ||
    Metric.sessionsSinceBest ||
    Metric.e1rm => UnitKind.weight,
    Metric.distance => UnitKind.distance,
    Metric.duration => UnitKind.duration,
    Metric.longest =>
      picked.any((e) => _kind(e.$2) == UnitKind.duration)
          ? UnitKind.duration
          : UnitKind.distance,
    _ => null,
  };
  final needsReps = const [
    Metric.reps,
    Metric.volume,
    Metric.e1rm,
    Metric.maxReps,
    Metric.meanReps,
  ].contains(metric);
  // Unknown contributing measurements cannot be omitted from a total or best.
  if (picked.any(
    (e) =>
        (needsReps && e.$2.reps == null) ||
        (needs != null && _kind(e.$2) != needs),
  )) {
    return empty;
  }
  String label(LoggedSet set) {
    final weight = set.value == null
        ? null
        : ['kg', 'lb'].contains(set.unit) && set.unit != unit
        ? '${formatRoundedQuantity(_weight(set, unit), l.localeName)}$unit'
        : '${formatNumber(set.value!)}${set.unit}';
    if (weight == null) return l.repsCount(set.reps!);
    return set.reps == null
        ? weight
        : l.answerWeightReps(weight, l.repsCount(set.reps!));
  }

  if ([Metric.reps, Metric.sets, Metric.sessions].contains(metric)) {
    final byDay = <DateTime, List<LoggedSet>>{};
    for (final note in notes) {
      final d = _day(note.createdAt);
      if (since != null && d.isBefore(_day(since))) continue;
      for (final block in note.blocks) {
        if (block.exercise != exercise) continue;
        for (final set in block.sets.where((s) => s.mine)) {
          if (metric == Metric.reps && set.reps == null) continue;
          byDay.putIfAbsent(d, () => []).add(set);
        }
      }
    }
    final unitLabel = metric == Metric.reps
        ? l.queryRepUnit
        : metric == Metric.sets
        ? l.querySetUnit
        : l.queryDayUnit;
    final points = [
      for (final entry in byDay.entries)
        DayPoint(
          entry.key,
          metric == Metric.reps
              ? entry.value.fold<double>(0, (n, s) => n + s.reps!)
              : metric == Metric.sets
              ? entry.value.length.toDouble()
              : 1,
          0,
          unitLabel,
        ),
    ]..sort((a, b) => a.day.compareTo(b.day));
    if (points.isEmpty) {
      return Answer(metric: metric, exercise: exercise, points: const []);
    }
    final total = points.fold<double>(0, (n, p) => n + p.value);
    return Answer(
      metric: metric,
      exercise: exercise,
      points: points,
      numericValue: total,
      unit: unitLabel,
      headline: metric == Metric.reps
          ? l.repsCount(total.toInt())
          : metric == Metric.sets
          ? l.answerSets(total.toInt())
          : l.answerDays(total.toInt()),
      lines: [
        l.answerSince(date(points.first.day)),
        l.answerDays(points.length),
      ],
    );
  }
  if (const [Metric.last, Metric.first, Metric.daysSince].contains(metric)) {
    final byDay = <DateTime, List<LoggedSet>>{};
    for (final note in notes) {
      final day = _day(note.createdAt);
      if (since != null && day.isBefore(_day(since))) continue;
      for (final block in note.blocks.where((b) => b.exercise == exercise)) {
        for (final set in block.sets.where(
          (s) => s.mine && (s.value != null || s.reps != null),
        )) {
          byDay.putIfAbsent(day, () => []).add(set);
        }
      }
    }
    if (byDay.isEmpty) {
      return Answer(metric: metric, exercise: exercise, points: const []);
    }
    final days = byDay.keys.toList()..sort();
    final allSets = byDay.values.expand((s) => s).toList();
    final allWeighted = allSets.every(
      (s) => s.value != null && ['kg', 'lb'].contains(s.unit),
    );
    final sameUnit =
        allSets.map((s) => s.unit).toSet().length == 1 &&
        allSets.every((s) => s.value != null);
    final allReps = allSets.every((s) => s.reps != null);
    final points = allWeighted
        ? dailyBest(
            notes,
            exercise,
            unit: unit,
          ).where((p) => byDay.containsKey(p.day)).toList()
        : [
            for (final day in days)
              DayPoint(
                day,
                sameUnit
                    ? byDay[day]!
                          .map((s) => s.value!)
                          .reduce((a, b) => a > b ? a : b)
                    : allReps
                    ? byDay[day]!.fold<double>(0, (n, s) => n + s.reps!)
                    : byDay[day]!.length.toDouble(),
                0,
                sameUnit
                    ? allSets.first.unit
                    : allReps
                    ? l.queryRepUnit
                    : l.querySetUnit,
              ),
          ];
    final day = metric == Metric.first ? days.first : days.last;
    final sets = byDay[day]!;
    final ago = _daysBetween(day, today).clamp(0, 99999);
    if (metric == Metric.daysSince) {
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        numericValue: ago.toDouble(),
        unit: l.queryDayUnit,
        headline: l.answerAgo(ago),
        lines: [date(day), l.answerSets(sets.length)],
      );
    }
    return Answer(
      metric: metric,
      exercise: exercise,
      points: points,
      headline: sets.map(label).join('  '),
      lines: [date(day), l.answerSets(sets.length), l.answerAgo(ago)],
    );
  }
  if (metric == Metric.meanReps) {
    final reps = [for (final (_, s) in picked) s.reps!];
    if (reps.isEmpty) return empty;
    final mean = reps.fold<int>(0, (n, r) => n + r) / reps.length;
    final byDay = <DateTime, List<int>>{};
    for (final (d, s) in picked) {
      byDay.putIfAbsent(d, () => []).add(s.reps!);
    }
    return Answer(
      metric: metric,
      exercise: exercise,
      points: [
        for (final d in byDay.keys.toList()..sort())
          DayPoint(
            d,
            byDay[d]!.fold<int>(0, (n, r) => n + r) / byDay[d]!.length,
            0,
            l.queryRepUnit,
          ),
      ],
      numericValue: mean,
      unit: l.queryRepUnit,
      headline: '${formatRoundedQuantity(mean, l.localeName)}${l.queryRepUnit}',
      lines: [l.answerSets(reps.length), l.answerDays(byDay.length)],
    );
  }
  // 세트마다 값 하나를 내고 날마다 모은다: 합이면 총 거리·시간, 아니면 그날의
  // 최고(추정 1RM·최다 반복·최장).
  if (const [
    Metric.e1rm,
    Metric.maxReps,
    Metric.longest,
    Metric.distance,
    Metric.duration,
  ].contains(metric)) {
    final units = {for (final (_, s) in picked) s.unit};
    // 거리·시간은 단위가 하나면 그대로, 섞이면 km·분으로 바꾼다.
    final target = units.length == 1
        ? units.single
        : needs == UnitKind.distance
        ? 'km'
        : 'min';
    double? value(LoggedSet s) => switch (metric) {
      Metric.maxReps => s.reps!.toDouble(),
      // Epley. 1회는 든 무게 그대로이고, 1–10회 세트만 쓴다.
      Metric.e1rm =>
        s.reps! < 1 || s.reps! > 10
            ? null
            : _weight(s, unit) * (s.reps == 1 ? 1 : 1 + s.reps! / 30),
      _ =>
        units.length == 1
            ? s.value!
            : s.value! * _base[s.unit]! / _base[target]!,
    };
    final suffix = switch (metric) {
      Metric.maxReps => l.queryRepUnit,
      Metric.e1rm => unit,
      _ => unitById[target]!.label,
    };
    final sum = metric == Metric.distance || metric == Metric.duration;
    final byDay = <DateTime, double>{};
    var count = 0;
    for (final (day, s) in picked) {
      final v = value(s);
      if (v == null) continue;
      count++;
      final prev = byDay[day];
      byDay[day] = prev == null
          ? v
          : sum
          ? prev + v
          : (v > prev ? v : prev);
    }
    if (byDay.isEmpty) return empty;
    final points = [
      for (final day in byDay.keys.toList()..sort())
        DayPoint(day, byDay[day]!, 0, suffix),
    ];
    String fmt(double v) => formatRoundedQuantity(v, l.localeName);
    if (sum) {
      final total = points.fold<double>(0, (n, p) => n + p.value);
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        numericValue: total,
        unit: suffix,
        headline: '${fmt(total)}$suffix',
        lines: [l.answerSets(count), l.answerDays(points.length)],
      );
    }
    final top = points.reduce((a, b) => b.value > a.value ? b : a);
    return Answer(
      metric: metric,
      exercise: exercise,
      points: points,
      numericValue: top.value,
      unit: suffix,
      headline: metric == Metric.maxReps
          ? l.repsCount(top.value.toInt())
          : metric == Metric.longest && units.length == 1
          ? '${formatNumber(top.value)}$suffix'
          : '${fmt(top.value)}$suffix',
      lines: [
        date(top.day),
        // 추정의 근거가 된 세트.
        if (metric == Metric.e1rm)
          label(
            picked
                .firstWhere((e) => e.$1 == top.day && value(e.$2) == top.value)
                .$2,
          ),
        l.answerDays(points.length),
      ],
    );
  }
  var points = dailyBest(notes, exercise, unit: unit);
  if (since != null) {
    points = points.where((p) => !p.day.isBefore(_day(since))).toList();
  }
  if (points.isEmpty) {
    return Answer(metric: metric, exercise: exercise, points: const []);
  }

  String fmt(double v) => formatRoundedQuantity(v, l.localeName);

  switch (metric) {
    case Metric.max:
      final top = points.reduce((a, b) => b.value > a.value ? b : a);
      final converted = _sets(
        notes,
        exercise,
      ).any((entry) => entry.$2.unit != unit);
      final weight = converted ? fmt(top.value) : formatNumber(top.value);
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        numericValue: top.value,
        unit: top.unit,
        headline: top.reps == 0
            ? '$weight${top.unit}'
            : l.answerWeightReps('$weight${top.unit}', l.repsCount(top.reps)),
        lines: [
          date(top.day),
          l.answerDays(points.length),
          if (points.length > 1) _delta(points, fmt, l),
        ],
      );

    case Metric.trend:
      final first = points.first, last = points.last;
      final gap = last.value - first.value;
      final weeks = _weeks(first.day, last.day);
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        numericValue: gap,
        unit: last.unit,
        rate: points.length < 2 ? null : gap / weeks,
        headline:
            '${formatRoundedQuantity(gap, l.localeName, signed: true)}${last.unit}',
        lines: [
          l.answerChange(
            l.answerWeeks(weeks),
            '${fmt(first.value)} → ${fmt(last.value)}${last.unit}',
          ),
          if (points.length > 1)
            ..._speed(gap, first.day, last.day, last.unit, l),
          _plateau(points, l) ??
              l.answerPeak(
                '${fmt(points.map((p) => p.value).reduce((a, b) => a > b ? a : b))}${last.unit}',
              ),
          l.answerFrequency(
            NumberFormat(
              '0.0',
              l.localeName,
            ).format(points.length / _weeks(first.day, last.day)),
          ),
        ],
      );

    case Metric.changePct:
      final first = points.first, last = points.last;
      if (points.length < 2) {
        return _insufficient(metric, exercise, points, l.answerNeedsTwoDays);
      }
      if (first.value <= 0) {
        return _insufficient(metric, exercise, points, l.answerNoBase);
      }
      final pct = (last.value - first.value) / first.value * 100;
      final weeks = _weeks(first.day, last.day);
      String signed(double v) =>
          '${formatRoundedQuantity(v, l.localeName, signed: true)}%';
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        numericValue: pct,
        unit: '%',
        rate: pct / weeks,
        headline: signed(pct),
        lines: [
          l.answerChange(
            l.answerWeeks(weeks),
            '${fmt(first.value)} → ${fmt(last.value)}${last.unit}',
          ),
          l.queryPeriod(date(first.day), date(last.day)),
          l.answerPerWeek(signed(pct / weeks)),
          if (weeks > 8) l.answerPerMonth(signed(pct / weeks * 52 / 12)),
        ],
      );

    case Metric.daysSinceBest:
    case Metric.sessionsSinceBest:
      final top = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
      final hit = points.lastWhere((p) => p.value >= top);
      final ago = _daysBetween(hit.day, today).clamp(0, 99999);
      final after = points.where((p) => p.day.isAfter(hit.day)).length;
      final peak = l.answerPeak('${fmt(top)}${hit.unit}');
      if (metric == Metric.daysSinceBest) {
        return Answer(
          metric: metric,
          exercise: exercise,
          points: points,
          numericValue: ago.toDouble(),
          unit: l.queryDayUnit,
          headline: l.answerAgo(ago),
          lines: ['$peak · ${date(hit.day)}', l.answerTimesAfter(after)],
        );
      }
      final lastAgo = _daysBetween(points.last.day, today).clamp(0, 99999);
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        numericValue: after.toDouble(),
        unit: l.answerTimesUnit,
        headline: l.answerTimes(after),
        lines: ['$peak · ${date(hit.day)}', l.answerAgo(lastAgo)],
      );

    case Metric.last:
    case Metric.reps:
    case Metric.sets:
    case Metric.sessions:
    case Metric.best:
    case Metric.e1rm:
    case Metric.maxReps:
    case Metric.distance:
    case Metric.duration:
    case Metric.first:
    case Metric.daysSince:
    case Metric.longest:
    case Metric.meanReps:
    case Metric.longestStreak:
    case Metric.longestGap:
    case Metric.meanGap:
    case Metric.intake:
    case Metric.burned:
    case Metric.balance:
      throw StateError('Handled before the daily-best metrics');
    case Metric.average:
      final values = [
        for (final (at, s) in _sets(notes, exercise))
          if (since == null || !_day(at).isBefore(_day(since)))
            _weight(s, unit),
      ];
      final mean = values.reduce((a, b) => a + b) / values.length;
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        numericValue: mean,
        unit: unit,
        headline: '${fmt(mean)}$unit',
        lines: [
          l.queryAverage,
          l.answerSets(values.length),
          l.answerDays(points.length),
        ],
      );

    case Metric.volume:
      var total = 0.0;
      var count = 0;
      for (final (at, s) in _sets(notes, exercise)) {
        if (since != null && _day(at).isBefore(_day(since))) continue;
        // A total cannot be known when a contributing set has no rep count.
        if (s.reps == null) {
          return Answer(metric: metric, exercise: exercise, points: const []);
        }
        total += _weight(s, unit) * s.reps!;
        count++;
      }
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        numericValue: total,
        unit: points.last.unit,
        headline: '${fmt(total)}${points.last.unit}',
        lines: [
          l.answerSets(count),
          l.answerDays(points.length),
          l.answerPerSet('${fmt(total / count)}${points.last.unit}'),
        ],
      );
  }
}

int _weeks(DateTime a, DateTime b) =>
    (b.difference(a).inDays / 7).ceil().clamp(1, 9999);

/// 추이의 속도 줄: 주당, 8주를 넘으면 달당도.
List<String> _speed(
  double change,
  DateTime from,
  DateTime to,
  String unit,
  L l,
) {
  final weeks = _weeks(from, to);
  String signed(double v) =>
      '${formatRoundedQuantity(v, l.localeName, signed: true)}$unit';
  return [
    l.answerPerWeek(signed(change / weeks)),
    if (weeks > 8) l.answerPerMonth(signed(change / weeks * 52 / 12)),
  ];
}

/// 셀 기록은 있는데 이 측정으로는 값이 안 나온다(날이 하나뿐, 기준이 0). 0 이 아니라
/// '—' 와 까닭이다.
Answer _insufficient(
  Metric metric,
  String exercise,
  List<DayPoint> points,
  String why,
) => Answer(
  metric: metric,
  exercise: exercise,
  points: points,
  headline: '—',
  lines: [why],
);

/// 운동한 날들로 세는 측정: 최장 연속, 최장 공백, 운동 간격. [days] 는 그 범위에서
/// 세트가 하나라도 남은 날이다. [end] 는 창의 끝(오늘을 넘지 않는다) — 마지막
/// 운동일 뒤로 쉬고 있는 날도 공백이다.
Answer dayAnswer(
  List<DateTime> days,
  Metric metric, {
  required DateTime end,
  L? labels,
  String exercise = '*',
}) {
  final l = labels ?? lookupL(const Locale('ko'));
  String date(DateTime d) => DateFormat.MMMd(l.localeName).format(d);
  final sorted = {for (final d in days) _day(d)}.toList()..sort();
  if (sorted.isEmpty) {
    return Answer(metric: metric, exercise: exercise, points: const []);
  }
  final points = [for (final d in sorted) DayPoint(d, 1, 0, l.queryDayUnit)];
  final unit = l.queryDayUnit;
  switch (metric) {
    case Metric.longestStreak:
      var best = (from: sorted.first, to: sorted.first, n: 1);
      var run = (from: sorted.first, n: 1);
      for (var i = 1; i < sorted.length; i++) {
        run = _daysBetween(sorted[i - 1], sorted[i]) == 1
            ? (from: run.from, n: run.n + 1)
            : (from: sorted[i], n: 1);
        if (run.n > best.n) best = (from: run.from, to: sorted[i], n: run.n);
      }
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        numericValue: best.n.toDouble(),
        unit: unit,
        headline: l.answerStreak(best.n),
        lines: [l.queryPeriod(date(best.from), date(best.to))],
      );
    case Metric.longestGap:
      final last = _day(end).isBefore(sorted.last) ? sorted.last : _day(end);
      var best = (
        from: sorted.last,
        to: last,
        n: _daysBetween(sorted.last, last),
      );
      var open = best.n > 0;
      for (var i = 1; i < sorted.length; i++) {
        final n = _daysBetween(sorted[i - 1], sorted[i]) - 1;
        if (n > best.n) {
          best = (from: sorted[i - 1], to: sorted[i], n: n);
          open = false;
        }
      }
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        numericValue: best.n.toDouble(),
        unit: unit,
        headline: l.answerRestDays(best.n),
        lines: [
          if (best.n > 0)
            l.queryPeriod(
              date(best.from.add(const Duration(days: 1))),
              open
                  ? l.answerUntilToday
                  : date(best.to.subtract(const Duration(days: 1))),
            ),
          l.answerDays(sorted.length),
        ],
      );
    default:
      // 운동 간격: 헤드라인은 중앙값이다 — 한 번의 긴 휴가가 '보통' 을 부풀리지 않는다.
      if (sorted.length < 2) {
        return _insufficient(metric, exercise, points, l.answerNeedsTwoDays);
      }
      final gaps = [
        for (var i = 1; i < sorted.length; i++)
          _daysBetween(sorted[i - 1], sorted[i]),
      ];
      final ordered = [...gaps]..sort();
      final mid = ordered.length ~/ 2;
      final median = ordered.length.isOdd
          ? ordered[mid].toDouble()
          : (ordered[mid - 1] + ordered[mid]) / 2;
      final mean = gaps.fold<int>(0, (a, b) => a + b) / gaps.length;
      final span = _daysBetween(sorted.first, sorted.last);
      int count(bool Function(int rest) test) =>
          gaps.where((g) => test(g - 1)).length;
      final longest = ordered.last;
      String n(double v) => formatRoundedQuantity(v, l.localeName);
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        numericValue: median,
        unit: unit,
        headline: l.answerEveryDays(n(median)),
        lines: [
          l.answerMeanEvery(n(mean)),
          l.answerGapSpread(
            count((r) => r == 0),
            count((r) => r == 1),
            count((r) => r == 2),
            count((r) => r >= 3),
          ),
          if (gaps.length > 2 && longest * 3 >= span)
            l.answerLongestIncluded(longest - 1),
        ],
      );
  }
}

/// 끼니와 워치 kcal 로 세는 측정. [logs] 는 이미 고른 날들이다([dayLogs]).
/// 없는 것은 0 이 아니다: 끼니를 안 적은 날은 섭취 셈 밖이고, 워치로 안 잰
/// 운동은 소모 셈 밖이다. 차이는 둘 다 있는 날만 뺀다([DayLog.difference]).
Answer energyAnswer(List<DayLog> logs, Metric metric, {L? labels}) {
  final l = labels ?? lookupL(const Locale('ko'));
  String fmt(double v, {bool signed = false}) =>
      formatRoundedQuantity(v, l.localeName, signed: signed);
  const kcal = 'kcal';
  Answer total(
    List<(DateTime, double)> values,
    String none,
    String Function(String) head,
    List<String> lines, {
    bool signed = false,
  }) {
    if (values.isEmpty) {
      return _insufficient(metric, '*', const [], none);
    }
    final sum = values.fold<double>(0, (n, v) => n + v.$2);
    return Answer(
      metric: metric,
      exercise: '*',
      points: [for (final (d, v) in values) DayPoint(d, v, 0, kcal)],
      numericValue: sum,
      unit: kcal,
      headline: head('${fmt(sum, signed: signed)}$kcal'),
      lines: lines,
    );
  }

  switch (metric) {
    case Metric.intake:
      final eaten = [
        for (final d in logs)
          if (d.intake case final v?) (d.day, v.toDouble()),
      ];
      final unknown = logs.fold<int>(0, (n, d) => n + d.unknownMeals);
      final about = logs.any((d) => d.intakeEstimated);
      return total(
        eaten,
        l.answerNoMeals,
        (v) => about ? l.answerAbout(v) : v,
        [
          l.answerMealDays(eaten.length),
          if (unknown > 0) l.queryUnknownMeals(unknown),
        ],
      );
    case Metric.burned:
      final used = [
        for (final d in logs)
          if (d.burned case final v?) (d.day, v),
      ];
      return total(used, l.answerNoWatch, (v) => v, [
        l.answerWatchDays(used.length),
      ]);
    default:
      final both = [
        for (final d in logs)
          if (d.difference case final v?) (d.day, v.toDouble()),
      ];
      final eatenOnly = logs
          .where((d) => d.intake != null && d.burned == null)
          .length;
      return total(both, l.answerNoBoth, (v) => v, [
        l.answerBothDays(both.length),
        if (eatenOnly > 0) l.answerIntakeOnlyDays(eatenOnly),
      ], signed: true);
  }
}

// Convert only for this comparison; saved entries retain their original units.
double _weight(LoggedSet set, String unit) {
  if (set.unit == unit) return set.value!;
  return unit == 'lb' ? set.value! / 0.45359237 : set.value! * 0.45359237;
}

String _delta(List<DayPoint> p, String Function(double) fmt, L l) {
  final gap = p.last.value - p.first.value;
  return l.answerChange(
    l.answerWeeks(_weeks(p.first.day, p.last.day)),
    '${gap >= 0 ? '+' : ''}${fmt(gap)}${p.last.unit}',
  );
}

/// 최근 값이 최고를 못 넘고 있으면 그 기간을 돌려준다. 아니면 null.
String? _plateau(List<DayPoint> p, L l) {
  final best = p.map((e) => e.value).reduce((a, b) => a > b ? a : b);
  final lastBest = p.lastIndexWhere((e) => e.value >= best);
  if (lastBest >= p.length - 2) return null; // 아직 갱신 중이다
  return l.answerNoPeak(_weeks(p[lastBest].day, p.last.day));
}

/// 점이 많으면 구간별 최고만 남긴다.
///
/// 1년치 101일을 다 찍으면 회색 꼬리점이 격자처럼 깔려 벽지가 된다. 그리는
/// 점은 [max] 개 아래로 두되, **날짜는 지어내지 않는다** — 각 구간에서 가장
/// 무거웠던 실제 그날을 그대로 쓴다. 집계(최고·일수)는 솎기 전 목록으로 센다.
List<DayPoint> thinPoints(List<DayPoint> points, {int max = 26}) {
  if (points.length <= max) return points;
  final first = points.first.day;
  final span = points.last.day.difference(first).inDays + 1;
  final bucket = (span / max).ceil();
  final best = <int, DayPoint>{};
  for (final p in points) {
    final key = p.day.difference(first).inDays ~/ bucket;
    final prev = best[key];
    if (prev == null || p.value > prev.value) best[key] = p;
  }
  return best.values.toList()..sort((a, b) => a.day.compareTo(b.day));
}
