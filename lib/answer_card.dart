import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import 'l10n/generated/app_localizations.dart';
import 'palette.dart';
import 'stats.dart';

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
    if (points.isEmpty) return const SizedBox.shrink();
    final l = L.of(context);
    final ink = answerInk.resolveFrom(context);
    final numbers = NumberFormat('0.##', l.localeName);
    final values = points.map((p) => p.value);
    final min = values.reduce(math.min), max = values.reduce(math.max);
    final labelStyle = TextStyle(
      fontSize: 11,
      color: ink.withValues(alpha: 0.6),
    );
    return Semantics(
      label: l.answerChart(exercise, points.length),
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
                    '${numbers.format(max)}${points.first.unit}',
                    style: labelStyle,
                  ),
                  const Spacer(),
                  if (min != max) Text(numbers.format(min), style: labelStyle),
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

class AnswerCard extends StatelessWidget {
  const AnswerCard({super.key, required this.answer});
  final Answer answer;

  @override
  Widget build(BuildContext context) {
    if (answer.points.isEmpty) return const SizedBox.shrink();
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
                      DotChart(
                        points: answer.points,
                        exercise: answer.exercise,
                      ),
                      const SizedBox(height: 28),
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
