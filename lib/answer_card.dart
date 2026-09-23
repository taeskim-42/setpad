import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import 'l10n/generated/app_localizations.dart';
import 'palette.dart';
import 'record_query.dart';
import 'stats.dart';
import 'quantities.dart';

/// A cached, tiled texture over quiet clouds made from the existing palette.
class GrainWash extends StatelessWidget {
  const GrainWash({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final paper = answerPaper.resolveFrom(context);
    final clouds = [
      (const Alignment(-0.8, -0.5), keypadBackground.color),
      (const Alignment(0.8, -0.1), sealTint.color),
      (const Alignment(0.0, 0.9), keyDim.color),
    ];
    return RepaintBoundary(
      child: ColoredBox(
        color: paper,
        child: Stack(
          children: [
            for (final (center, tint) in clouds)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: center,
                      radius: 0.85,
                      colors: [
                        Color.lerp(paper, tint, dark ? 0.025 : 0.4)!,
                        paper.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: dark ? 0.025 : 0.065,
                  child: Image.asset(
                    'assets/grain.png',
                    repeat: ImageRepeat.repeat,
                    scale: 2,
                    excludeFromSemantics: true,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// One actual dot per recorded day; elapsed time determines horizontal spacing.
class DotChart extends StatelessWidget {
  const DotChart({super.key, required this.points, required this.exercise});
  final List<DayPoint> points;
  final String exercise;

  @override
  Widget build(BuildContext context) {
    if (this.points.isEmpty) return const SizedBox.shrink();
    final l = L.of(context);
    final ink = answerInk.resolveFrom(context);
    // 화면에 찍는 점만 솎는다. 아래 라벨의 일수는 솎기 전 그대로다.
    final points = thinPoints(this.points);
    final values = points.map((p) => p.value);
    final min = values.reduce(math.min), max = values.reduce(math.max);
    final labelStyle = TextStyle(
      fontSize: 11,
      color: ink.withValues(alpha: 0.6),
    );
    return Semantics(
      label: l.answerChart(exercise, this.points.length),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: SizedBox(
              height: 156,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatRoundedQuantity(max, l.localeName)}${points.first.unit}',
                    style: labelStyle,
                  ),
                  const Spacer(),
                  if (min != max)
                    Text(
                      formatRoundedQuantity(min, l.localeName),
                      style: labelStyle,
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 156),
                  painter: DotChartPainter(
                    points: points,
                    ink: ink,
                    trail: ink.withValues(alpha: 0.18),
                  ),
                ),
                const SizedBox(height: 10),
                _DateAxis(points: points, style: labelStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Keep date labels aligned to actual days and drop the middle when crowded.
class _DateAxis extends StatelessWidget {
  const _DateAxis({required this.points, required this.style});
  final List<DayPoint> points;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final locale = L.of(context).localeName;
    final format = points.first.day.year == points.last.day.year
        ? DateFormat.Md(locale)
        : DateFormat.yMd(locale);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final span = points.last.day.difference(points.first.day).inDays;
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        final candidates = [points.first];
        if (points.length > 2) {
          candidates.add(
            points
                .sublist(1, points.length - 1)
                .reduce(
                  (a, b) =>
                      (a.day.difference(points.first.day).inDays - span / 2)
                              .abs() <=
                          (b.day.difference(points.first.day).inDays - span / 2)
                              .abs()
                      ? a
                      : b,
                ),
          );
        }
        if (span > 0) candidates.add(points.last);
        final labels = candidates.map((point) {
          final text = format.format(point.day);
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: direction,
            textScaler: scaler,
          )..layout(maxWidth: width);
          final x = span == 0
              ? width / 2
              : 5 +
                    point.day.difference(points.first.day).inDays /
                        span *
                        math.max(0, width - 10);
          final left = (x - painter.width / 2).clamp(
            0.0,
            width - painter.width,
          );
          final label = (
            day: point.day,
            text: text,
            rect: Rect.fromLTWH(left, 0, painter.width, painter.height),
          );
          painter.dispose();
          return label;
        }).toList();
        final height = labels
            .map((label) => label.rect.height)
            .reduce(math.max);
        final crowded =
            labels.length > 1 &&
            labels.first.rect.right + 8 > labels.last.rect.left;
        return SizedBox(
          height: crowded ? height * 2 + 4 : height,
          child: Stack(
            children: [
              for (var i = 0; i < labels.length; i++)
                if (i == 0 ||
                    i == labels.length - 1 ||
                    (!crowded &&
                        labels[i].rect.left >= labels.first.rect.right + 8 &&
                        labels[i].rect.right + 8 <= labels.last.rect.left))
                  Positioned(
                    left: labels[i].rect.left,
                    top: crowded && i == labels.length - 1 ? height + 4 : 0,
                    width: labels[i].rect.width,
                    child: Text(
                      labels[i].text,
                      key: ValueKey(
                        'chart-date-${labels[i].day.toIso8601String()}',
                      ),
                      semanticsLabel: DateFormat.yMMMd(
                        locale,
                      ).format(labels[i].day),
                      style: style,
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// Public geometry allows tests to verify actual marks without golden pixels.
class DotChartPainter extends CustomPainter {
  DotChartPainter({
    required this.points,
    required this.ink,
    required this.trail,
  });
  final List<DayPoint> points;
  final Color ink, trail;

  List<Offset> recordPositions(Size size) {
    if (points.isEmpty) return const [];
    final min = points.map((p) => p.value).reduce(math.min);
    final max = points.map((p) => p.value).reduce(math.max);
    final first = points.first.day;
    final span = points.last.day.difference(first).inDays;
    final width = math.max(0.0, size.width - 10);
    final height = math.max(0.0, size.height - 10);
    return [
      for (final p in points)
        Offset(
          5 +
              (span == 0
                  ? width / 2
                  : p.day.difference(first).inDays / span * width),
          5 +
              (max == min
                  ? height / 2
                  : (1 - (p.value - min) / (max - min)) * height),
        ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final actual = Paint()..color = ink;
    final past = Paint()..color = trail;
    for (final p in recordPositions(size)) {
      for (double y = size.height - 5; y > p.dy + 9; y -= 14) {
        canvas.drawCircle(Offset(p.dx, y), 1.5, past);
      }
      canvas.drawCircle(p, 3.5, actual);
    }
  }

  @override
  bool shouldRepaint(DotChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.ink != ink ||
      oldDelegate.trail != trail;
}

/// 값이 없거나 0 으로 채운 칸의 까닭 — 적은 적 없음, 이 범위엔 없음, 아직 안 온
/// 기간. 값이 빠진 세트·대상 아님은 각주가 말한다(null).
String? cellReason(L l, String? reason) => switch (reason) {
  'never' => l.queryNeverMark,
  'none' => l.queryNoneCell,
  'future' => l.queryFutureCell,
  _ => null,
};

class AnswerCard extends StatelessWidget {
  const AnswerCard({super.key, required this.answer});
  final Answer answer;

  @override
  Widget build(BuildContext context) {
    // 점이 없는 수(0 으로 채운 칸, 연속·간격·섭취)도 답이다.
    if (answer.isEmpty) return const SizedBox.shrink();
    final ink = answerInk.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GrainWash(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: DefaultTextStyle(
                  style: TextStyle(color: ink, fontFamily: '.SF Pro Text'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          answer.exercise,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.4,
                            height: 1.08,
                          ),
                        ),
                      ),
                      if (answer.headline != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          answer.headline!,
                          style: const TextStyle(
                            fontSize: 22,
                            letterSpacing: -0.6,
                            height: 1.25,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      if (answer.points.isNotEmpty) ...[
                        DotChart(
                          points: answer.points,
                          exercise: answer.exercise,
                        ),
                        const SizedBox(height: 28),
                      ],
                      for (final (i, line) in answer.lines.take(3).indexed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 34,
                                child: Text(
                                  NumberFormat(
                                    '00',
                                    L.of(context).localeName,
                                  ).format(i + 1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.7,
                                    color: ink.withValues(alpha: 0.55),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  line,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.4,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 여럿을 나란히 본 답. 겉은 [AnswerCard] 와 같은 종이다.
///
/// [runPlan] 의 결과는 늘 한 방향이다: 줄 = series 또는 묶음, 칸 = 측정 또는
/// series(+ 차이·배수·비중). 줄이 셋 이하이고 순위가 아니며 묶음이 운동·부위뿐이면
/// **대조형**이다 — 대상(줄)을 칸으로 세우고 측정을 줄로 편다. "벤치 vs 로우" 가
/// 이 모양이다. 그 밖은 **목록형**이다 — 대상에 번호를 달고, 칸은 측정이다.
/// 숫자는 실행기가 이미 셌다.
class TableCard extends StatelessWidget {
  const TableCard({super.key, required this.query, required this.result});
  final RecordQuery query;
  final RecordResult result;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final ink = answerInk.resolveFrom(context);
    final faint = ink.withValues(alpha: 0.55);
    final r = result;
    final targets = [for (final row in r.rows) row.label];
    final measures = r.columns;
    if (targets.isEmpty || measures.isEmpty) return const SizedBox.shrink();
    Cell at(int t, int m) => r.rows[t].cells[m];
    // 줄마다 까닭(적은 적 없음 …)은 처음 한 칸에서만 말한다.
    int? said(int t) {
      for (var m = 0; m < measures.length; m++) {
        if (cellReason(l, at(t, m).reason) != null) return m;
      }
      return null;
    }

    final totals = r.total;
    final word = query.total == 'mean' ? l.queryTotalMean : l.queryTotalSum;
    final headline = totals != null
        ? [
            for (final (m, c) in totals.indexed)
              if (c.reason != 'notAsked')
                [
                  // 부분 합계면 무엇을 뺐는지 이름에 있다("합계 (데드리프트 제외)").
                  c.answer?.exercise ?? word,
                  if (totals.length > 1) measures[m],
                  c.answer?.headline ?? '—',
                ].join(' '),
          ].join(' · ')
        // 차이 줄은 "측정 · 차이 (뒤 − 앞): 값" 이다. 헤드라인에는 값만 올리고
        // 무엇에서 무엇을 뺐는지는 아래 줄이 그대로 말한다.
        : measures.length == 1 && targets.length == 2 && r.lines.length == 1
        ? r.lines.single.split(': ').last
        : null;
    // series 가 여럿이면 줄 이름이 서로 다른 조각을 말한다. 모두에 같은 조각(기간 …)은
    // 여기 한 줄이다.
    final scopes = [
      for (final s in query.series) describeScope(s.scope, l).split(' · '),
    ];
    final common = scopes.first
        .where((p) => scopes.every((s) => s.contains(p)))
        .join(' · ');
    final notes = [if (common.isNotEmpty) common, ...r.footnotes];
    final contrast =
        targets.length <= 3 &&
        query.order == null &&
        (query.by == null || query.by == 'exercise' || query.by == 'part');

    const gap = EdgeInsets.fromLTRB(12, 7, 0, 7);
    final line = BoxDecoration(
      border: Border(
        top: BorderSide(color: ink.withValues(alpha: 0.12), width: 0.5),
      ),
    );
    Widget head(String text) => Padding(
      padding: gap,
      child: Text(
        text,
        textAlign: TextAlign.end,
        style: TextStyle(fontSize: 12, height: 1.35, color: faint),
      ),
    );
    Widget label(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, height: 1.3, letterSpacing: -0.3),
      ),
    );
    // 값 한 칸. 모르거나 없으면 "—", 개수형은 0. 마지막·처음은 날짜가 본문이고
    // 그날 세트가 보조 줄이다. 묻지 않은 칸(series 마다 측정이 다를 때)은 빈칸이다.
    // [say] 면 까닭을 보조 줄에 적는다.
    Widget value(Cell c, {bool say = false}) {
      if (c.reason == 'notAsked') return const SizedBox.shrink();
      final a = c.answer;
      final why = cellReason(l, c.reason);
      final dated =
          a != null &&
          why == null &&
          (a.metric == Metric.last || a.metric == Metric.first);
      final body = a == null
          ? '—'
          : dated
          ? a.lines.first
          : a.headline ?? '—';
      final sub = why != null
          ? (say ? why : null)
          : a == null
          ? null
          : dated
          ? a.headline
          : a.lines.firstOrNull;
      return Padding(
        padding: gap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              body,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 15,
                height: 1.3,
                letterSpacing: -0.3,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (sub != null)
              Text(
                sub,
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, height: 1.35, color: faint),
              ),
          ],
        ),
      );
    }

    Widget table(List<TableRow> rows) => Table(
      // 좁으면 값이 줄을 바꾸고, 이름은 제 폭을 지킨다(카드의 절반 가까이
      // 까지). 남는 폭은 값 칸이 나눠 갖는다 — 오른쪽 정렬이라 숫자가 끝에
      // 붙는다.
      columnWidths: const {
        0: MinColumnWidth(IntrinsicColumnWidth(), FractionColumnWidth(0.45)),
      },
      defaultColumnWidth: const MaxColumnWidth(
        IntrinsicColumnWidth(),
        FlexColumnWidth(),
      ),
      children: rows,
    );

    final Widget grid;
    if (contrast) {
      grid = table([
        TableRow(
          children: [const SizedBox.shrink(), for (final t in targets) head(t)],
        ),
        for (var m = 0; m < measures.length; m++)
          TableRow(
            decoration: line,
            children: [
              label(measures[m]),
              for (var t = 0; t < targets.length; t++)
                value(at(t, m), say: said(t) == m),
            ],
          ),
      ]);
    } else {
      // 셋 이상이면 첫 측정의 크기를 이름 아래 막대로 긋는다.
      final firsts = [
        for (var t = 0; t < targets.length; t++)
          at(t, 0).answer?.numericValue ?? 0,
      ];
      final top = firsts.fold<double>(0, math.max);
      final bars = targets.length >= 3 && top > 0;
      Widget name(int t, EdgeInsets padding) => Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${NumberFormat('00', l.localeName).format(t + 1)}  ',
                    style: TextStyle(
                      fontSize: 12,
                      color: faint,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  TextSpan(text: targets[t]),
                ],
              ),
              style: const TextStyle(
                fontSize: 15,
                height: 1.3,
                letterSpacing: -0.3,
              ),
            ),
            if (bars) ...[
              const SizedBox(height: 5),
              // 0 이면 긋지 않는다. 폭 0 의 FractionallySizedBox 는 고유 폭을
              // 셀 때 0 으로 나눈다.
              if (firsts[t] > 0)
                FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: math.min(firsts[t] / top, 1),
                  child: Container(
                    height: 3,
                    color: ink.withValues(alpha: 0.25),
                  ),
                )
              else
                const SizedBox(height: 3),
            ],
          ],
        ),
      );
      grid = measures.length == 1
          ? table([
              TableRow(children: [const SizedBox.shrink(), head(measures[0])]),
              for (var t = 0; t < targets.length; t++)
                TableRow(
                  decoration: line,
                  children: [
                    name(t, const EdgeInsets.symmetric(vertical: 7)),
                    value(at(t, 0), say: said(t) == 0),
                  ],
                ),
            ])
          // 측정이 여럿이면 이름을 제 줄에 두고 값은 그 아래 같은 폭으로 편다.
          // 이름 옆에 값 셋을 세우면 폰 폭에서 글자 단위로 부서진다.
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (final m in measures) Expanded(child: head(m)),
                  ],
                ),
                for (var t = 0; t < targets.length; t++)
                  DecoratedBox(
                    decoration: line,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        name(t, const EdgeInsets.only(top: 7)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var m = 0; m < measures.length; m++)
                              Expanded(
                                child: value(at(t, m), say: said(t) == m),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GrainWash(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: DefaultTextStyle(
                  style: TextStyle(color: ink, fontFamily: '.SF Pro Text'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          r.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.9,
                            height: 1.12,
                          ),
                        ),
                      ),
                      if (headline != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          headline,
                          style: const TextStyle(
                            fontSize: 22,
                            letterSpacing: -0.6,
                            height: 1.25,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      grid,
                      for (final d in r.lines)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      for (final n in notes)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            n,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: faint,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
