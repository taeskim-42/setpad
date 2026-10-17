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

/// 한 줄. [onTap] 이 있으면 누를 수 있고 ›가 붙는다. [detail] 은 오른쪽의 현재 값,
/// [note] 는 라벨 아래 한 줄 더(로그인 실패처럼 잘리면 뜻이 사라지는 말).
///
/// CupertinoListTile 은 제목을 한 줄로 자르고 오른쪽 값(additionalInfo)은 폭 제한 없이
/// 놓는다 — 긴 이용권 설명이 잘리고, 긴 닉네임은 줄을 넘쳐 라벨을 0폭으로 만들었다.
/// 그래서 라벨·값·설명을 제목 자리 안에 직접 놓는다: 라벨은 감기고, 값은 화면 폭의
/// 40% 안에서 감긴다.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.detail,
    this.note,
    this.accent = false,
    this.onTap,
  });
  final String label;
  final String? detail;
  final String? note;
  final bool accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    return CupertinoListTile(
      onTap: onTap,
      padding: _padding,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: _wrap,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: accent ? FontWeight.w600 : FontWeight.w400,
                    color: accent
                        ? seal.resolveFrom(context)
                        : CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
              if (detail case final d?) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                  ),
                  child: Text(
                    d,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 16, color: muted),
                  ),
                ),
              ],
            ],
          ),
          if (note case final n?)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                n,
                maxLines: _wrap,
                style: TextStyle(fontSize: 13, height: 1.3, color: muted),
              ),
            ),
        ],
      ),
      trailing: onTap == null ? null : const CupertinoListTileChevron(),
    );
  }
}

/// 라벨이 감길 수 있는 줄 수. CupertinoListTile 의 한 줄 제한을 덮는다 — Text 에 직접
/// 준 maxLines 는 위의 DefaultTextStyle 보다 앞선다.
const _wrap = 6;

/// CupertinoListTile 의 기본 여백에 위아래 4 를 더한다 — 한 줄이면 여전히 44, 감긴
/// 줄은 가장자리에 붙지 않는다.
const _padding = EdgeInsetsDirectional.fromSTEB(20, 4, 14, 4);

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

  // One node: what the switch turns on, and whether it is on.
  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: CupertinoListTile(
      padding: _padding,
      title: Text(
        label,
        maxLines: _wrap,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: CupertinoSwitch(value: value, onChanged: onChanged),
    ),
  );
}
