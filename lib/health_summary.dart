import 'package:flutter/cupertino.dart';

import 'l10n/generated/app_localizations.dart';
import 'palette.dart';

/// Health measurements stay distinct from the sets entered in the journal.
class HealthSummary extends StatelessWidget {
  const HealthSummary({
    super.key,
    required this.calories,
    this.showSource = false,
  });

  final double? calories;
  final bool showSource;

  @override
  Widget build(BuildContext context) {
    // 숫자가 없으면 아무것도 그리지 않는다. "기록 없음" 은 화면을 차지할
    // 뿐 읽을 것이 없고, 건강 앱이 값을 주는 순간 저절로 나타난다.
    if (calories == null) return const SizedBox.shrink();
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(
              CupertinoIcons.flame,
              size: 15,
              color: calories == null ? muted : seal.resolveFrom(context),
            ),
            Text(l.activeEnergy, style: TextStyle(fontSize: 13, color: muted)),
            Text(
              calories == null
                  ? l.energyUnavailable
                  : l.kcal(calories!.round()),
              style: TextStyle(
                fontSize: 13,
                fontWeight: calories == null
                    ? FontWeight.w400
                    : FontWeight.w600,
                color: calories == null
                    ? muted
                    : CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ],
        ),
        if (showSource && calories != null) ...[
          const SizedBox(height: 4),
          Text(l.energySource, style: TextStyle(fontSize: 12, color: muted)),
        ],
      ],
    );
  }
}
