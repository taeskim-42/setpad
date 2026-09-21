import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'daily.dart';
import 'health.dart';
import 'l10n/generated/app_localizations.dart';
import 'notes.dart';
import 'palette.dart';
import 'units.dart';

/// 하루치 열량을 한 줄로. 오늘 문서의 머리말과 기간 화면의 그날 상세가 **같은
/// 문장**을 쓴다. 숫자를 낼 수 없으면 왜 못 내는지를 그 자리에 적는다.
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

/// 체중 하나를 적거나 고친다. 저장하면 entry, 지우면 [deleted], 취소면 null.
const deleted = Object();

Future<Object?> showWeightSheet(
  BuildContext context, {
  required String unit,
  WeightEntry? editing,
}) => showCupertinoModalPopup<Object>(
  context: context,
  builder: (_) => _WeightSheet(unit: editing?.unit ?? unit, editing: editing),
);

class _WeightSheet extends StatefulWidget {
  const _WeightSheet({required this.unit, this.editing});
  final String unit;
  final WeightEntry? editing;
  @override
  State<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends State<_WeightSheet> {
  late final _value = TextEditingController(
    text: widget.editing == null ? '' : formatNumber(widget.editing!.value),
  );
  late DateTime _at = widget.editing?.at ?? DateTime.now();

  double? get _number {
    final n = double.tryParse(_value.text.trim().replaceAll(',', '.'));
    return n != null && WeightEntry.valid(n, widget.unit) ? n : null;
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final number = _number;
    return CupertinoPopupSurface(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            12 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.weightAdd,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      key: const ValueKey('weight-value'),
                      controller: _value,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 22),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(unitById[widget.unit]?.label ?? widget.unit),
                  ),
                ],
              ),
              if (_value.text.trim().isNotEmpty && number == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l.weightInvalid,
                    style: TextStyle(
                      fontSize: 13,
                      color: seal.resolveFrom(context),
                    ),
                  ),
                ),
              // 실제로 잰 날짜와 시각. 지난 측정을 나중에 적을 수도 있다.
              SizedBox(
                height: 120,
                child: CupertinoDatePicker(
                  initialDateTime: _at,
                  maximumDate: DateTime.now().add(const Duration(minutes: 1)),
                  use24hFormat: true,
                  onDateTimeChanged: (t) => _at = t,
                ),
              ),
              Text(l.weightRule, style: TextStyle(fontSize: 12, color: muted)),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.editing != null)
                    CupertinoButton(
                      onPressed: () => Navigator.pop(context, deleted),
                      child: Text(
                        l.delete,
                        style: const TextStyle(
                          color: CupertinoColors.destructiveRed,
                        ),
                      ),
                    ),
                  const Spacer(),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.cancel),
                  ),
                  CupertinoButton.filled(
                    onPressed: number == null
                        ? null
                        : () => Navigator.pop(
                            context,
                            WeightEntry(
                              id: widget.editing?.id,
                              at: _at,
                              value: number,
                              unit: widget.unit,
                              source:
                                  widget.editing?.source ?? WeightEntry.manual,
                            ),
                          ),
                    child: Text(l.doneEditing),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 체중을 적는 흐름 하나. 머리말과 기간 화면이 같이 쓴다.
Future<void> editWeight(
  BuildContext context,
  NotesStore store, {
  WeightEntry? editing,
}) async {
  final result = await showWeightSheet(
    context,
    unit: store.weightUnit,
    editing: editing,
  );
  if (result is WeightEntry) store.saveWeight(result);
  if (identical(result, deleted) && editing != null) {
    store.deleteWeight(editing);
  }
}

/// 기록과 몸의 변화 — 먹은 것, 운동으로 쓴 것, 실제로 잰 몸을 **같은 날짜 축**
/// 위에 위아래로 놓는다. 칼로리와 kg 는 한 축에 섞지 않는다.
///
/// 여기서 하는 말은 관찰뿐이다: 며칠을 기록했고, 잰 체중이 언제 얼마에서 언제
/// 얼마가 됐는지. 섭취 − 운동 값으로 몸을 환산하거나 예측하지 않는다.
class TrendsPage extends StatefulWidget {
  const TrendsPage({
    super.key,
    required this.store,
    this.health,
    this.onOpenNote,
    this.today,
  });
  final NotesStore store;
  final HealthLink? health;
  final void Function(Note note)? onOpenNote;

  /// 테스트와 화면 확인이 날짜를 못 박는 자리.
  final DateTime? today;

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  int _span = 30;
  DateTime? _picked;

  DateTime get _to => dayOf(widget.today ?? DateTime.now());
  DateTime get _from => _to.subtract(Duration(days: _span - 1));

  void _changed() => setState(() {});

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_changed);
  }

  @override
  void dispose() {
    widget.store.removeListener(_changed);
    super.dispose();
  }

  Future<void> _import() async {
    final health = widget.health;
    if (health == null || !await health.authorizeWeight()) return;
    final found = await health.weights(
      _to.subtract(const Duration(days: 90)),
      _to.add(const Duration(days: 1)),
    );
    widget.store.importWeights([
      for (final w in found)
        if (WeightEntry.valid(w.kg, 'kg'))
          WeightEntry(
            id: w.id,
            at: w.at,
            value: w.kg,
            source: WeightEntry.health,
          ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final store = widget.store;
    final unit = store.weightUnit;
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final small = TextStyle(fontSize: 13, height: 1.4, color: muted);
    final days = dayLogs(store.notes, store.weights, from: _from, to: _to);
    final summary = summarize(days);
    final date = DateFormat.MMMd(l.localeName);
    final picked = days.where((d) => d.day == _picked).firstOrNull;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(l.trendsTitle),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            CupertinoSlidingSegmentedControl<int>(
              groupValue: _span,
              children: {
                for (final n in const [7, 30, 90]) n: Text(l.trendDays(n)),
              },
              onValueChanged: (n) => setState(() {
                _span = n ?? 30;
                _picked = null;
              }),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                _Legend(color: seal.resolveFrom(context), label: l.intakeLabel),
                _Legend(color: muted, label: l.burnedLabel),
                _Legend(
                  color: CupertinoColors.label.resolveFrom(context),
                  label: l.diffLabel,
                  dot: true,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 같은 가로축을 쓰는 두 그래프. 누르면 그날을 고른다.
            GestureDetector(
              key: const ValueKey('trend-charts'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (tap) {
                final box = context.size!.width - 32;
                final at = (tap.localPosition.dx / box * _span).floor().clamp(
                  0,
                  _span - 1,
                );
                setState(() => _picked = _from.add(Duration(days: at)));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 150,
                    child: CustomPaint(
                      painter: _EnergyPainter(
                        days: days,
                        from: _from,
                        span: _span,
                        picked: _picked,
                        intake: seal.resolveFrom(context),
                        burned: muted,
                        diff: CupertinoColors.label.resolveFrom(context),
                        grid: CupertinoColors.separator.resolveFrom(context),
                        label: small.copyWith(fontSize: 11),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 2),
                    child: Text(l.weightMeasured, style: small),
                  ),
                  SizedBox(
                    height: 110,
                    child: CustomPaint(
                      painter: _WeightPainter(
                        days: days,
                        from: _from,
                        span: _span,
                        picked: _picked,
                        unit: unit,
                        color: CupertinoColors.label.resolveFrom(context),
                        grid: CupertinoColors.separator.resolveFrom(context),
                        text: small,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(date.format(_from), style: small),
                      Text(date.format(_to), style: small),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (picked != null)
              _DayDetail(picked, this)
            else ...[
              if (days.isEmpty) Text(l.trendNoData, style: small),
              if (summary.intakeAverage != null)
                Text(
                  l.trendIntakeAvg(summary.intakeAverage!, summary.intakeDays),
                  style: small,
                ),
              if (summary.burnedAverage != null)
                Text(
                  l.trendBurnedAvg(summary.burnedAverage!, summary.burnedDays),
                  style: small,
                ),
              if (summary.differenceAverage != null)
                Text(
                  l.trendDiffAvg(
                    summary.differenceAverage!,
                    summary.differenceDays,
                  ),
                  style: small.copyWith(
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              if (summary.incompleteDays > 0)
                Text(l.trendIncomplete(summary.incompleteDays), style: small),
              const SizedBox(height: 8),
              Text(
                summary.firstWeight == null
                    ? l.trendWeightNone
                    : summary.weightChangeKg == null
                    ? l.trendWeightOne
                    : l.trendWeightChange(
                        date.format(summary.firstWeight!.at),
                        formatWeight(summary.firstWeight!, unit),
                        date.format(summary.lastWeight!.at),
                        formatWeight(summary.lastWeight!, unit),
                      ),
                style: small.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(l.energyExplain, style: small),
            Text('${l.burnedLabel}: ${l.burnedSource}', style: small),
            Text(l.weightRule, style: small),
            const SizedBox(height: 8),
            Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => editWeight(context, store),
                  child: Text(
                    l.weightAdd,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 20),
                if (widget.health?.supported ?? false)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _import,
                    child: Text(
                      l.weightFromHealth,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 고른 날의 음식·운동·체중. 여기서 그날 문서로 가거나 체중을 고친다.
class _DayDetail extends StatelessWidget {
  const _DayDetail(this.day, this.page);
  final DayLog day;
  final _TrendsPageState page;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final store = page.widget.store;
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final small = TextStyle(fontSize: 13, height: 1.5, color: muted);
    final time = DateFormat.Hm(l.localeName);
    final energy = dayEnergyText(l, day);
    return Column(
      key: const ValueKey('trend-day'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat.MMMEd(l.localeName).format(day.day),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        if (energy != null)
          Text(
            energy,
            style: small.copyWith(
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        for (final meal in day.meals)
          Text(
            '${time.format(meal.at)}  ${meal.kcal == null
                ? l.mealKcalUnknown
                : meal.approximate
                ? l.kcalApprox(meal.kcal!)
                : l.kcal(meal.kcal!)} · ${meal.text ?? meal.items.join(', ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: small,
          ),
        for (final note in day.notes)
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 30),
            onPressed: page.widget.onOpenNote == null
                ? null
                : () => page.widget.onOpenNote!(note),
            child: Text(
              '${time.format(note.createdAt)}  ${note.title ?? ''}'
              '${note.calories == null ? '' : ' · ${l.kcal(note.calories!.round())}'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        for (final w in day.weights)
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 30),
            onPressed: () => editWeight(context, store, editing: w),
            child: Text(
              '${time.format(w.at)}  ${l.weightLabel(formatWeight(w, store.weightUnit))} · '
              '${w.source == WeightEntry.health ? l.sourceHealth : l.sourceManual}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.dot = false});
  final Color color;
  final String label;
  final bool dot;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: dot ? 7 : 9,
        height: dot ? 7 : 9,
        decoration: BoxDecoration(
          color: color,
          shape: dot ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    ],
  );
}

/// 날마다 섭취 막대와 운동 막대, 둘 다 있는 날에만 차이 점. 기록이 없는 날은
/// 비어 있고, 열량 미상이 섞인 날의 섭취 막대는 속이 빈 테두리다 — 그 높이가
/// 그날의 전부가 아니라는 뜻이다. 좋고 나쁨을 색으로 말하지 않는다.
class _EnergyPainter extends CustomPainter {
  _EnergyPainter({
    required this.days,
    required this.from,
    required this.span,
    required this.picked,
    required this.intake,
    required this.burned,
    required this.diff,
    required this.grid,
    required this.label,
  });
  final List<DayLog> days;
  final DateTime from;
  final int span;
  final DateTime? picked;
  final Color intake, burned, diff, grid;
  final TextStyle label;

  @override
  void paint(Canvas canvas, Size size) {
    final values = <num>[
      0,
      for (final d in days) ...[?d.intake, ?d.burned, ?d.difference],
    ];
    final top = values.reduce(math.max).toDouble().clamp(1.0, double.infinity);
    final bottom = values.reduce(math.min).toDouble();
    double y(num v) => size.height * (1 - (v - bottom) / (top - bottom));
    final slot = size.width / span;
    // 세로축의 크기를 알 수 있게 가장 큰 값을 적어 둔다.
    final scale = TextPainter(
      text: TextSpan(text: '${top.round()}kcal', style: label),
      textDirection: TextDirection.ltr,
    )..layout();
    scale.paint(canvas, Offset(size.width - scale.width, 0));
    scale.dispose();
    canvas.drawLine(
      Offset(0, y(0)),
      Offset(size.width, y(0)),
      Paint()
        ..color = grid
        ..strokeWidth = 0.5,
    );
    for (final d in days) {
      final x = d.day.difference(from).inDays * slot;
      if (d.day == picked) {
        canvas.drawRect(
          Rect.fromLTWH(x, 0, slot, size.height),
          Paint()..color = grid.withValues(alpha: 0.35),
        );
      }
      final w = math.max(1.5, slot * 0.34);
      if (d.intake != null) {
        final rect = Rect.fromLTRB(
          x + slot * 0.12,
          y(d.intake!),
          x + slot * 0.12 + w,
          y(0),
        );
        canvas.drawRect(
          rect,
          Paint()
            ..color = intake
            ..style = d.unknownMeals > 0
                ? PaintingStyle.stroke
                : PaintingStyle.fill
            ..strokeWidth = 1,
        );
      }
      if (d.burned != null) {
        canvas.drawRect(
          Rect.fromLTRB(
            x + slot * 0.54,
            y(d.burned!),
            x + slot * 0.54 + w,
            y(0),
          ),
          Paint()..color = burned,
        );
      }
      if (d.difference != null) {
        canvas.drawCircle(
          Offset(x + slot / 2, y(d.difference!)),
          math.min(3, math.max(1.5, slot * 0.2)),
          Paint()..color = diff,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_EnergyPainter old) => true;
}

/// 실제로 잰 날에만 점. 잰 날끼리는 가는 선으로 잇지만 그 사이의 값을 말하는
/// 것은 아니다 — 재지 않은 날에는 점이 없다.
class _WeightPainter extends CustomPainter {
  _WeightPainter({
    required this.days,
    required this.from,
    required this.span,
    required this.picked,
    required this.unit,
    required this.color,
    required this.grid,
    required this.text,
  });
  final List<DayLog> days;
  final DateTime from;
  final int span;
  final DateTime? picked;
  final String unit;
  final Color color, grid;
  final TextStyle text;

  @override
  void paint(Canvas canvas, Size size) {
    final weighed = [
      for (final d in days)
        if (d.weight != null) d,
    ];
    final slot = size.width / span;
    if (picked != null) {
      canvas.drawRect(
        Rect.fromLTWH(
          picked!.difference(from).inDays * slot,
          0,
          slot,
          size.height,
        ),
        Paint()..color = grid.withValues(alpha: 0.35),
      );
    }
    if (weighed.isEmpty) return;
    final values = [for (final d in weighed) d.weight!.inUnit(unit)];
    final low = values.reduce(math.min) - 0.5,
        high = values.reduce(math.max) + 0.5;
    Offset at(int i) => Offset(
      (weighed[i].day.difference(from).inDays + 0.5) * slot,
      14 + (size.height - 28) * (1 - (values[i] - low) / (high - low)),
    );
    final line = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 1; i < weighed.length; i++) {
      canvas.drawLine(at(i - 1), at(i), line);
    }
    for (var i = 0; i < weighed.length; i++) {
      canvas.drawCircle(at(i), 3, Paint()..color = color);
    }
    // 처음과 마지막 값은 숫자로도 적는다 — 요약 문장이 말하는 그 두 값이다.
    for (final i in {0, weighed.length - 1}) {
      final painter = TextPainter(
        text: TextSpan(
          text: formatWeight(weighed[i].weight!, unit),
          style: text.copyWith(fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = at(i);
      painter.paint(
        canvas,
        Offset(
          (p.dx - painter.width / 2).clamp(0, size.width - painter.width),
          p.dy - 16,
        ),
      );
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(_WeightPainter old) => true;
}
