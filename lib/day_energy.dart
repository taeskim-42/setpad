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
    // 세 칸은 같은 키다 — 설명 줄이 있는 칸만 길쭉하면 들쭉날쭉해 보였다.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          // 차이는 뜻을 모르면 읽을 수 없다 — 셈을 늘 적고, 누르면 무엇이 빠졌는지까지.
          _Tile(
            label: l.energyDifference,
            value: diff == null ? null : signed(diff),
            note: l.energyDiffFormula,
            estimate: diff != null && day.intakeEstimated,
            onTap: () => showCupertinoDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (ctx) => CupertinoAlertDialog(
                title: Text(l.energyDifference),
                content: Text(l.energyDiffExplain),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l.ok),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    this.note,
    this.estimate = false,
    this.onTap,
  });
  final String label;
  final String? value;
  final String? note;
  final bool estimate;

  /// 누르면 뜻을 알려 주는 칸. 머리에 ⓘ 가 붙는다.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemBackground.resolveFrom(
              context,
            ),
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
                  if (onTap != null) ...[
                    const SizedBox(width: 3),
                    Icon(CupertinoIcons.info_circle, size: 13, color: muted),
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
