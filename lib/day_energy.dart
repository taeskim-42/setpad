import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import 'daily.dart';
import 'l10n/generated/app_localizations.dart';
import 'palette.dart';

/// 그날의 에너지 — 먹은 것 · 운동 · 차이를 세 칸으로.
///
/// 글 한 줄("섭취 약 +1,170 · 운동 −512 = 약 +658kcal")이었을 때는 '약' 이
/// 약(藥)으로 읽혔고, 셈이 한눈에 들어오지 않았다. 없는 값은 0 이 아니라 '—' 와
/// 그 까닭(미기록·미측정)이다. 어림이 섞였으면 칸 머리에 [EstimateTag].
class DayEnergy extends StatelessWidget {
  const DayEnergy(this.day, {super.key});
  final DayLog day;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final n = NumberFormat.decimalPattern(l.localeName);
    final intake = day.intake, burned = day.burned, diff = day.difference;
    final unknown = day.unknownMeals;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Tile(
          label: l.mealsTitle,
          value: intake == null ? null : n.format(intake),
          note: intake == null
              ? l.energyNotLogged
              : unknown > 0
              ? l.dayUnknownMeals(unknown)
              : null,
          estimate: day.intakeEstimated,
        ),
        const SizedBox(width: 8),
        _Tile(
          label: l.energyBurned,
          value: burned == null ? null : signed(-burned.round()),
          note: burned == null ? l.energyNotMeasured : null,
        ),
        const SizedBox(width: 8),
        _Tile(
          label: l.energyDifference,
          value: diff == null ? null : signed(diff),
          estimate: diff != null && day.intakeEstimated,
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    this.note,
    this.estimate = false,
  });
  final String label;
  final String? value;
  final String? note;
  final bool estimate;

  @override
  Widget build(BuildContext context) {
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ),
                if (estimate) ...[
                  const SizedBox(width: 4),
                  const EstimateTag(),
                ],
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value ?? '—',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: value == null
                            ? muted
                            : CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    if (value != null)
                      TextSpan(
                        text: ' kcal',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                  ],
                ),
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (note != null)
              Text(
                note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: muted),
              ),
          ],
        ),
      ),
    );
  }
}

/// 어림한 값이라는 작은 표시. 숫자 앞의 '약' 대신 쓴다.
class EstimateTag extends StatelessWidget {
  const EstimateTag({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: sealTint.resolveFrom(context),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      L.of(context).estimateTag,
      style: TextStyle(fontSize: 10, color: seal.resolveFrom(context)),
    ),
  );
}
