/// iOS 설정 앱 모양의 묶음 목록 — 설정과 도장 화면이 같이 쓴다.
///
/// 바탕은 시스템의 grouped 회색, 행은 그 위에 얹힌 둥근 흰 상자(inset grouped).
/// 예전에는 행마다 전폭 구분선만 있어서 iOS 어느 양식도 아니었다.
library;

import 'package:flutter/cupertino.dart';

import 'metrics.dart';
import 'palette.dart';

/// 제목(선택)과 행 묶음 하나, 그리고 묶음 아래 한 줄 설명(선택).
///
/// 행이 하나도 없으면 상자는 그리지 않고 제목과 설명만 놓는다 — 빈 상자는 아무것도
/// 아닌 것으로 보인다.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    this.title,
    this.footer,
    this.children = const [],
  });
  final String? title;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final header = title == null
        ? null
        : Text(
            title!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          );
    final note = footer == null
        ? null
        : Text(
            footer!,
            style: TextStyle(fontSize: 13, height: 1.35, color: muted),
          );
    if (children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(gutter + 4, 16, gutter + 4, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ?header,
            if (header != null && note != null) const SizedBox(height: 6),
            ?note,
          ],
        ),
      );
    }
    return CupertinoListSection.insetGrouped(
      header: header,
      footer: note,
      hasLeading: false,
      margin: const EdgeInsetsDirectional.fromSTEB(gutter, 0, gutter, 10),
      children: children,
    );
  }
}

/// 한 줄. [onTap] 이 있으면 누를 수 있고 ›가 붙는다. [detail] 은 오른쪽의 현재 값.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.detail,
    this.accent = false,
    this.onTap,
  });
  final String label;
  final String? detail;
  final bool accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => CupertinoListTile(
    onTap: onTap,
    title: Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: accent ? FontWeight.w600 : FontWeight.w400,
        color: accent
            ? seal.resolveFrom(context)
            : CupertinoColors.label.resolveFrom(context),
      ),
    ),
    additionalInfo: detail == null ? null : Text(detail!),
    trailing: onTap == null ? null : const CupertinoListTileChevron(),
  );
}

/// 켜고 끄는 한 줄.
class SettingsToggle extends StatelessWidget {
  const SettingsToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => CupertinoListTile(
    title: Text(label, style: const TextStyle(fontSize: 16)),
    trailing: CupertinoSwitch(value: value, onChanged: onChanged),
  );
}
