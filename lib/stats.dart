/// 기록에서 답을 뽑는 곳. **숫자는 전부 여기서 나온다.**
///
/// 화면도 모델도 이 숫자를 만들지 않는다. 물어본 것을 해석하는 일(키패드
/// 옆의 검색창이든 기기 안 AI든)과 답을 세는 일을 갈라 두면, 해석이 틀려도
/// 숫자는 안 틀린다 — 틀린 숫자는 사람이 검산할 방법이 없어서 앱을 통째로
/// 못 믿게 만든다.
library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'l10n/generated/app_localizations.dart';
import 'parser.dart';
import 'editor.dart';
import 'notes.dart';

/// 무엇을 물었는가.
enum Metric { max, trend, last, sessions, volume }

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
    this.lines = const [],
  });

  final Metric metric;
  final String exercise;

  /// 시간순. [Metric.trend] 는 이것을 점으로 그리고, 나머지도 있으면 함께 그린다.
  final List<DayPoint> points;

  /// 한 줄 답. 없으면 화면이 점만 보여준다.
  final String? headline;

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
      if (searchKey(block.name) != searchKey(want)) continue;
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
  final l = labels ?? lookupL(const Locale('ko'));
  String date(DateTime d) => DateFormat.MMMd(l.localeName).format(d);
  final today = now ?? DateTime.now();
  var points = dailyBest(notes, exercise, unit: unit);
  if (since != null) {
    points = points.where((p) => !p.day.isBefore(_day(since))).toList();
  }
  if (points.isEmpty) {
    return Answer(metric: metric, exercise: exercise, points: const []);
  }

  String fmt(double v) => NumberFormat('0.##', l.localeName).format(v);

  switch (metric) {
    case Metric.max:
      final top = points.reduce((a, b) => b.value > a.value ? b : a);
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        headline: top.reps == 0
            ? '${fmt(top.value)}${top.unit}'
            : l.answerWeightReps(
                '${fmt(top.value)}${top.unit}',
                l.repsCount(top.reps),
              ),
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
        headline: '${gap >= 0 ? '+' : ''}${fmt(gap)}${last.unit}',
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
      final day = points.last.day;
      final that = [
        for (final (at, s) in _sets(notes, exercise))
          if (_day(at) == day) s,
      ];
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        headline: that
            .map(
              (s) => s.reps == null
                  ? '${fmt(_weight(s, unit))}$unit'
                  : l.answerWeightReps(
                      '${fmt(_weight(s, unit))}$unit',
                      l.repsCount(s.reps!),
                    ),
            )
            .join('  '),
        lines: [
          date(day),
          l.answerSets(that.length),
          l.answerAgo(today.difference(day).inDays.clamp(0, 99999)),
        ],
      );

    case Metric.sessions:
      return Answer(
        metric: metric,
        exercise: exercise,
        points: points,
        headline: l.answerDays(points.length),
        lines: [
          l.answerSince(date(points.first.day)),
          l.answerFrequency(
            NumberFormat(
              '0.0',
              l.localeName,
            ).format(points.length / _weeks(points.first.day, points.last.day)),
          ),
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

/// A question must name one unambiguous exercise and an explicit metric.
/// This is query routing, not generated advice or AI-authored statistics.
({Metric metric, String exercise})? recordQuestion(
  String query,
  Iterable<String> names,
) {
  final all = names.toSet().toList();
  final text = query
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[?？]$'), '')
      .trim();
  if (text.isEmpty || all.any((n) => searchKey(n) == searchKey(text))) {
    return null;
  }
  const terms = {
    Metric.max: [
      '최고 기록',
      '최고',
      '최대',
      'personal best',
      'best',
      'max',
      '最高',
      '最大',
      'máximo',
      'mejor',
      'สูงสุด',
      'cao nhất',
    ],
    Metric.trend: [
      '추이',
      '변화',
      'trend',
      'progress',
      '推移',
      '趋势',
      '趨勢',
      'tendencia',
      'แนวโน้ม',
      'xu hướng',
    ],
    Metric.last: [
      '마지막',
      '최근 기록',
      'last',
      'latest',
      '前回',
      '最近记录',
      '最近紀錄',
      'último',
      'ล่าสุด',
      'gần nhất',
    ],
    Metric.sessions: [
      '빈도',
      '몇 번',
      'frequency',
      'sessions',
      '頻度',
      '频率',
      '頻率',
      'frecuencia',
      'ความถี่',
      'tần suất',
    ],
    Metric.volume: [
      '볼륨',
      '총중량',
      'volume',
      '総重量',
      '总重量',
      '總重量',
      'volumen',
      'ปริมาณ',
      'khối lượng',
    ],
  };
  for (final entry in terms.entries) {
    for (final term in entry.value) {
      String? exercise;
      if (text.endsWith(' $term')) {
        exercise = text.substring(0, text.length - term.length).trim();
      }
      if (text.startsWith('$term ')) {
        exercise = text.substring(term.length).trim();
      }
      if (exercise == null || exercise.isEmpty) continue;
      final exact = all
          .where((n) => searchKey(n) == searchKey(exercise!))
          .toList();
      final matches = exact.isNotEmpty ? exact : suggest(exercise, all);
      if (matches.length == 1) {
        return (metric: entry.key, exercise: matches.single);
      }
    }
  }
  return null;
}
