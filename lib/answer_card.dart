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
      child: SizedBox(
        height: 156,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 14, top: 1, bottom: 1),
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
            Expanded(
              child: CustomPaint(
                size: const Size(double.infinity, 156),
                painter: DotChartPainter(
                  points: points,
                  ink: ink,
                  trail: ink.withValues(alpha: 0.18),
                ),
              ),
            ),
          ],
        ),
      ),
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
