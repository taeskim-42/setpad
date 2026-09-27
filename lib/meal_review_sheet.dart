import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import 'l10n/generated/app_localizations.dart';
import 'meal.dart';
import 'meal_amount_sheet.dart';
import 'record_ai.dart';
import 'units.dart';

Future<({double kcal, String? text})?> reviewMealEstimate(
  BuildContext context,
  MealEstimate estimate, {
  Uint8List? photo,
}) async {
  if (estimate.components.isEmpty) {
    final picked = await askMealAmount(
      context,
      title: estimate.items.join(', '),
      note: L.of(context).mealReviewNote,
      photo: photo,
      bases: [
        MealBasis(
          kcal: estimate.kcal.toDouble(),
          amount: 1,
          unit: photo == null ? MealBasis.serving : MealBasis.photo,
        ),
      ],
    );
    if (picked == null) return null;
    return (
      kcal: picked.basis.kcal * picked.eaten / picked.basis.amount,
      text: null,
    );
  }
  return showCupertinoModalPopup<({double kcal, String? text})>(
    context: context,
    builder: (_) => _MealReviewSheet(estimate: estimate, photo: photo),
  );
}

class _MealReviewSheet extends StatefulWidget {
  const _MealReviewSheet({required this.estimate, this.photo});
  final MealEstimate estimate;
  final Uint8List? photo;

  @override
  State<_MealReviewSheet> createState() => _MealReviewSheetState();
}

class _MealReviewSheetState extends State<_MealReviewSheet> {
  late final _amounts = [
    for (final c in widget.estimate.components)
      TextEditingController(
        text: c.amount == null ? '' : formatNumber(c.amount!),
      ),
  ];

  double? _calories(int i) {
    final c = widget.estimate.components[i];
    if (c.amount == null) return c.kcal;
    final amount = parseMealAmount(_amounts[i].text);
    if (amount == null || amount > 100000) return null;
    final kcal = c.kcalPer100! * amount / 100;
    return kcal.isFinite && kcal <= 100000 ? kcal : null;
  }

  @override
  void dispose() {
    for (final amount in _amounts) {
      amount.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final values = [for (var i = 0; i < _amounts.length; i++) _calories(i)];
    final sum = values.whereType<double>().fold(0.0, (a, b) => a + b);
    final total = values.contains(null) || sum > 100000 ? null : sum.round();
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    return CupertinoPopupSurface(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              12 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.mealReviewTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.mealReviewNote,
                  style: TextStyle(fontSize: 13, color: muted),
                ),
                if (widget.photo != null) ...[
                  const SizedBox(height: 12),
                  mealReviewPhoto(widget.photo!),
                ],
                for (final (i, c) in widget.estimate.components.indexed) ...[
                  const SizedBox(height: 16),
                  Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (c.maker?.isNotEmpty == true)
                    Text(
                      c.maker!,
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                  Text(
                    c.evidence,
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                  if (c.amount != null) ...[
                    Text(
                      l.mealSourcePer(c.unit!, formatNumber(c.kcalPer100!)),
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                    if (c.estimatedAmount)
                      Text(
                        l.mealEstimatedAmount,
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: Text(l.mealEaten)),
                        SizedBox(
                          width: 100,
                          child: CupertinoTextField(
                            key: ValueKey('meal-review-amount-$i'),
                            controller: _amounts[i],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.end,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        Text(' ${c.unit}'),
                      ],
                    ),
                  ],
                  Text(
                    values[i] == null
                        ? l.mealAmountInvalid
                        : l.kcal(values[i]!.round()),
                    textAlign: TextAlign.end,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  total == null ? l.mealAmountInvalid : l.kcal(total),
                  key: const ValueKey('meal-review-total'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        key: const ValueKey('meal-review-cancel'),
                        onPressed: () => Navigator.pop(context),
                        child: Text(l.cancel),
                      ),
                    ),
                    Expanded(
                      child: CupertinoButton.filled(
                        key: const ValueKey('meal-review-confirm'),
                        onPressed: total == null
                            ? null
                            : () => Navigator.pop(context, (
                                kcal: sum,
                                text: [
                                  for (final (i, c)
                                      in widget.estimate.components.indexed)
                                    c.amount == null
                                        ? c.evidence
                                        : '${c.name} ${formatNumber(parseMealAmount(_amounts[i].text)!)}${c.unit}',
                                ].join(', '),
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
      ),
    );
  }
}
