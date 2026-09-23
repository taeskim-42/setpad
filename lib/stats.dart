/// Compute quantities from completed records within an explicitly chosen scope.
/// Missing contributing measurements never become zero or partial totals.
library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

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
}

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

  bool get isEmpty => points.isEmpty && headline == null;
}

/// 이름이 [query] 인 운동의 세트를 날짜와 함께 모은다.
///
/// **해낸 세트만 센다.** 취소한 세트는 기록이 아니다.
Iterable<(DateTime, LoggedSet)> _sets(List<Note> notes, String query) sync* {
  final want = query.trim().toLowerCase();
  for (final note in notes) {
    for (final block in note.blocks) {
      if (searchKey(block.exercise) != searchKey(want)) continue;
      for (final set in block.sets) {
        if (set.done &&
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
            if (set.done) (_day(note.createdAt), set),
];

/// 세트에 적힌 숫자의 종류. 숫자가 없으면 null 이다.
UnitKind? _kind(LoggedSet set) =>
    set.value != null && set.value!.isFinite ? unitById[set.unit]?.kind : null;

// 거리는 m, 시간은 초로 바꾸는 배수.
const _base = {'km': 1000.0, 'm': 1.0, 'mi': 1609.344, 's': 1.0, 'min': 60.0};

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
  // 이 측정이 모든 세트에 요구하는 숫자의 종류. 최장은 시간을 적었으면 시간이다.
  final needs = switch (metric) {
    Metric.max ||
    Metric.average ||
    Metric.volume ||
    Metric.trend ||
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
        for (final set in block.sets.where((s) => s.done)) {
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
          (s) => s.done && (s.value != null || s.reps != null),
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
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        numericValue: gap,
        headline:
            '${formatRoundedQuantity(gap, l.localeName, signed: true)}${last.unit}',
        lines: [
          l.answerChange(
            l.answerWeeks(_weeks(first.day, last.day)),
            '${fmt(first.value)} → ${fmt(last.value)}${last.unit}',
          ),
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
