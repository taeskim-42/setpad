import 'package:flutter/cupertino.dart';

import 'l10n/generated/app_localizations.dart';
import 'meal.dart';
import 'palette.dart';
import 'share.dart';

String mealUnitLabel(L l, String unit) => switch (unit) {
  MealBasis.serving => l.mealUnitServing,
  MealBasis.package => l.mealUnitPackage,
  MealBasis.photo => l.mealUnitPhoto,
  _ => unit,
};

/// "150g", "2.5개", "1.5회분", "포장 전체 × 0.5".
String mealEatenText(L l, MealBasis basis, double eaten) =>
    switch (basis.unit) {
      MealBasis.serving => l.mealServingsOption(amountText(eaten)),
      MealBasis.package || MealBasis.photo =>
        eaten == 1
            ? mealUnitLabel(l, basis.unit)
            : '${mealUnitLabel(l, basis.unit)} × ${amountText(eaten)}',
      _ => '${amountText(eaten)}${basis.unit}',
    };

/// 얼마나 먹었나 — 회분 환산이 아니라 **먹은 양**을 받는다.
///
/// 근거(몇 kcal / 얼마)도 고칠 수 있다. 성분표를 읽은 값도 어림한 값도 틀릴 수
/// 있고, 틀린 근거에 정확한 양을 곱해 봐야 틀린 값이다. 취소하면 null 이고
/// 부르는 쪽은 아무것도 저장하지 않는다.
/// 열량을 계산한 표의 줄들. 누르면 기기 브라우저로 원본 표의 그 이름을 연다 —
/// 거기서 같은 줄의 값을 앱에 적힌 값과 맞춰 볼 수 있다.
Future<void> showMealSources(
  BuildContext context,
  List<MealSource> sources,
) => showCupertinoModalPopup<void>(
  context: context,
  builder: (context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    return CupertinoActionSheet(
      title: Text(l.mealSourcesTitle),
      message: Text(l.mealSourcesNote),
      actions: [
        for (final source in sources)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              openUrl(source.url);
            },
            child: Column(
              children: [
                Text(
                  source.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${l.mealSourcePer(source.per, amountText(source.kcalPer100))}'
                  ' · ${source.usda ? l.mealSourceUsda : l.mealSourceMfds}',
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              ],
            ),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: Text(l.cancel),
      ),
    );
  },
);

Future<({MealBasis basis, double eaten})?> askMealAmount(
  BuildContext context, {
  required List<MealBasis> bases,
  String? title,
  String? note,
  MealBasis? initialBasis,
  double? initialEaten,
}) => showCupertinoModalPopup<({MealBasis basis, double eaten})>(
  context: context,
  builder: (context) => _MealAmountSheet(
    bases: bases,
    title: title,
    note: note,
    initialBasis: initialBasis,
    initialEaten: initialEaten,
  ),
);

class _MealAmountSheet extends StatefulWidget {
  const _MealAmountSheet({
    required this.bases,
    this.title,
    this.note,
    this.initialBasis,
    this.initialEaten,
  });
  final List<MealBasis> bases;
  final String? title, note;
  final MealBasis? initialBasis;
  final double? initialEaten;

  @override
  State<_MealAmountSheet> createState() => _MealAmountSheetState();
}

class _MealAmountSheetState extends State<_MealAmountSheet> {
  late int _pick;
  final _kcal = TextEditingController();
  final _amount = TextEditingController();
  final _eaten = TextEditingController();

  String get _unit => widget.bases[_pick].unit;

  bool get _portion => _unit == MealBasis.package || _unit == MealBasis.photo;

  /// 인쇄된 단위(g·개…)만 기준량이 있다. 회분·포장·사진은 늘 "1" 이다.
  bool get _measured =>
      _unit != MealBasis.serving &&
      _unit != MealBasis.package &&
      _unit != MealBasis.photo;

  @override
  void initState() {
    super.initState();
    final at = widget.bases.indexWhere(
      (b) => b.unit == widget.initialBasis?.unit,
    );
    _pick = at < 0 ? 0 : at;
    _load(widget.initialBasis ?? widget.bases[_pick], widget.initialEaten);
  }

  void _load(MealBasis basis, [double? eaten]) {
    _kcal.text = amountText(basis.kcal);
    _amount.text = amountText(basis.amount);
    // 기본은 한 번 제공량만큼 — 고치기 가장 가까운 출발점이다.
    _eaten.text = amountText(eaten ?? (_measured ? basis.amount : 1));
  }

  static double? _number(String text) {
    final n = double.tryParse(text.trim().replaceAll(',', '.'));
    return n != null && n.isFinite && n >= 0 ? n : null;
  }

  MealBasis? get _basis {
    final kcal = _number(_kcal.text);
    final amount = _measured ? _number(_amount.text) : 1.0;
    if (kcal == null || amount == null || amount <= 0) return null;
    return MealBasis(kcal: kcal, amount: amount, unit: _unit);
  }

  @override
  void dispose() {
    _kcal.dispose();
    _amount.dispose();
    _eaten.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController c, String key, {double width = 76}) =>
      SizedBox(
        width: width,
        child: CupertinoTextField(
          key: ValueKey(key),
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.end,
          onChanged: (_) => setState(() {}),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final basis = _basis;
    final eaten = _number(_eaten.text);
    final kcal = basis == null || eaten == null ? null : basis.kcalFor(eaten);
    final unit = mealUnitLabel(l, _unit);
    final base = _measured ? (_number(_amount.text) ?? 1) : 1.0;
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
                widget.title ?? l.mealAmountAsk,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.note!,
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ),
              if (widget.bases.length > 1) ...[
                const SizedBox(height: 12),
                CupertinoSlidingSegmentedControl<int>(
                  groupValue: _pick,
                  children: {
                    for (final (i, b) in widget.bases.indexed)
                      i: Text(
                        mealUnitLabel(l, b.unit),
                        style: const TextStyle(fontSize: 13),
                      ),
                  },
                  onValueChanged: (i) => setState(() {
                    _pick = i ?? 0;
                    _load(widget.bases[_pick]);
                  }),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text(l.mealBasis)),
                  _field(_kcal, 'meal-basis-kcal'),
                  const Text(' kcal / '),
                  if (_measured)
                    _field(_amount, 'meal-basis-amount', width: 64),
                  Text(_measured ? ' $unit' : '1 $unit'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(l.mealEaten)),
                  _field(_eaten, 'meal-eaten'),
                  Text(' $unit'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // 포장과 사진은 "그중 얼마" 라서 전체·절반이고, 나머지는 배수다.
                  for (final (label, n) in [
                    (_portion ? l.mealHalf : '½×', base / 2),
                    (_portion ? l.mealWhole : '1×', base),
                    if (!_portion) ('2×', base * 2),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(44, 32),
                        color: CupertinoColors.tertiarySystemFill.resolveFrom(
                          context,
                        ),
                        onPressed: () =>
                            setState(() => _eaten.text = amountText(n)),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                kcal == null ? l.mealAmountInvalid : l.kcal(kcal),
                key: const ValueKey('meal-amount-kcal'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: kcal == null ? 13 : 28,
                  fontWeight: FontWeight.w600,
                  color: kcal == null ? seal.resolveFrom(context) : null,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l.cancel),
                    ),
                  ),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: kcal == null
                          ? null
                          : () => Navigator.pop(context, (
                              basis: basis!,
                              eaten: eaten!,
                            )),
                      child: Text(l.doneEditing),
                    ),
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
