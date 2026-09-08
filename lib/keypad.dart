import 'package:flutter/cupertino.dart';

import 'l10n/generated/app_localizations.dart';
import 'palette.dart';

/// 세트를 칠 때만 뜨는 키패드.
///
/// Strong 의 배치를 따랐다 — 숫자 세 열, 오른쪽 한 열에 기능키. 앞선 판에는
/// kg·회·× 키가 있었는데 전부 걷어냈다:
///
///  - kg·회: 파서가 단위 없이도 읽는다. "100 20" 이면 100kg 20회다.
///    운동 중에 단위를 꼬박꼬박 붙이는 사람은 없으니 칠 이유도 없다.
///  - ×: "세트 반복"이라는 뜻이었는데 기호만 보고 알 방법이 없었다.
///    같은 세트를 한 번 더는 "이전과 같이" 가 대신한다.
class SetKeypad extends StatelessWidget {
  const SetKeypad({
    super.key,
    required this.onKey,
    required this.onBackspace,
    required this.onAddSet,
    required this.onSubmit,
    required this.submitLabel,
    required this.onText,
    required this.onAdjust,
    required this.stepLabel,
    required this.onStepPick,
    this.addLabel,
    this.repeatLabel,
    this.onRepeat,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback? onAddSet;
  final VoidCallback onSubmit;
  final String submitLabel;
  final String? addLabel;

  /// 메모처럼 글자가 필요할 때 시스템 키보드로 넘긴다.
  final VoidCallback onText;

  /// 치고 있는 마지막 숫자를 한 단계 민다. 숫자를 지우고 다시 치는 것보다
  /// 이쪽이 훨씬 잦다.
  final ValueChanged<int> onAdjust;

  /// 지금 밀면 얼마가 움직이는지. 누르기 전에 보여야 한다.
  final String stepLabel;

  /// +/- 를 길게 눌렀을 때. 미는 폭을 고르게 한다.
  final VoidCallback onStepPick;

  /// 직전 세트를 그대로 한 번 더 — 운동 기록에서 가장 흔한 동작이다.
  final String? repeatLabel;
  final VoidCallback? onRepeat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: keypadBackground.resolveFrom(context),
        // iOS 의 구분선은 0.5pt.
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        // Keep the home-indicator space while the system keyboard is closing.
        maintainBottomViewPadding: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(
                width: double.infinity,
                child: _Key(
                  label: [
                    L.of(context).repeatPrevious,
                    ?repeatLabel,
                  ].join('  '),
                  onTap: repeatLabel == null ? null : onRepeat,
                  tone: _Tone.accent,
                  height: 38,
                ),
              ),
            ),
            // 오른쪽 열이 왼쪽 격자와 같은 높이를 갖게 한다. 그래야 그 안에서
            // Expanded 로 나눌 수 있다 — 바깥 Column 이 높이를 정하지
            // 않으므로(MainAxisSize.min) 이것 없이는 설 자리가 없다.
            //
            // ponytail: IntrinsicHeight 는 자식을 한 번 더 재므로 공짜가
            // 아니다. 여기는 키 열몇 개짜리 트리라 값이 안 느껴진다. 키패드가
            // 더 복잡해지면 왼쪽 격자 높이를 직접 계산해 넘기는 쪽으로.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _row(const ['1', '2', '3']),
                        _row(const ['4', '5', '6']),
                        _row(const ['7', '8', '9']),
                        // Strong 과 같은 자리에 지우기를 둔다. 숫자를 치다가
                        // 틀렸을 때 손이 가장 가까운 곳이 여기다.
                        _row(const ['.', '0', '⌫']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    // Keep the two actions in separate, fixed rows.
                    child: Column(
                      children: [
                        Expanded(
                          child: _pad(
                            _Key(
                              icon: CupertinoIcons.keyboard,
                              onTap: onText,
                              tone: _Tone.dim,
                              height: null,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _pad(
                                  _Key(
                                    label: '−',
                                    sub: stepLabel,
                                    onTap: () => onAdjust(-1),
                                    onLongPress: onStepPick,
                                    tone: _Tone.dim,
                                    height: null,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _pad(
                                  _Key(
                                    label: '+',
                                    sub: stepLabel,
                                    onTap: () => onAdjust(1),
                                    onLongPress: onStepPick,
                                    tone: _Tone.dim,
                                    height: null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _pad(
                            _Key(
                              label: addLabel ?? L.of(context).addSet,
                              onTap: onAddSet,
                              tone: _Tone.primary,
                              height: null,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _pad(
                            _Key(
                              label: submitLabel,
                              onTap: onSubmit,
                              tone: _Tone.primary,
                              height: null,
                              compact: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<String> keys) => Row(
    children: [
      for (final k in keys)
        Expanded(
          child: _pad(
            k == '⌫'
                // 지우기는 글자가 아니라 동작이다. 숫자 키 사이에 있지만
                // 아이콘으로 내야 무엇인지 바로 보인다.
                ? _Key(
                    icon: CupertinoIcons.delete_left,
                    onTap: onBackspace,
                    tone: _Tone.plain,
                  )
                : _Key(
                    label: k,
                    onTap: () => onKey(k == '␣' ? ' ' : k),
                    tone: _Tone.plain,
                  ),
          ),
        ),
    ],
  );

  Widget _pad(Widget child) =>
      Padding(padding: const EdgeInsets.all(3), child: child);
}

enum _Tone { plain, dim, primary, accent }

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    this.sub,
    this.icon,
    required this.onTap,
    required this.tone,
    this.onLongPress,
    this.height = 46,
    this.compact = false,
  });

  final String? label;

  /// 길게 눌렀을 때. 없으면 길게 눌러도 아무 일도 없다.
  final VoidCallback? onLongPress;

  /// 버튼 아래 작게 붙는 설명. −/+ 가 얼마씩 미는지 여기 적는다.
  final String? sub;
  final IconData? icon;
  final VoidCallback? onTap;
  final _Tone tone;
  final bool compact;

  /// null 이면 부모가 준 높이를 그대로 쓴다(Expanded 안에 있을 때).
  final double? height;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      // iOS 숫자 키패드의 색 얼개 — 숫자는 흰 키, 기능키는 한 단계 어둡게.
      _Tone.plain => (
        keyFace.resolveFrom(context),
        CupertinoColors.label.resolveFrom(context),
      ),
      _Tone.dim => (
        keyDim.resolveFrom(context),
        CupertinoColors.label.resolveFrom(context),
      ),
      _Tone.primary => (
        sealTint.resolveFrom(context),
        seal.resolveFrom(context),
      ),
      _Tone.accent => (
        sealTint.resolveFrom(context),
        seal.resolveFrom(context),
      ),
    };

    return SizedBox(
      height: height,
      // iOS 는 눌림을 리플이 아니라 잠깐 흐려지는 것으로 알린다.
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              // iOS 키패드의 키는 모서리 5 에 아주 옅은 그림자 하나다.
              borderRadius: BorderRadius.circular(9),
              boxShadow: tone == _Tone.dim
                  ? null
                  : [
                      BoxShadow(
                        color: keyShadow.resolveFrom(context),
                        blurRadius: 0,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 19, color: fg)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact
                                ? 14
                                : switch (tone) {
                                    _Tone.primary => 14.0,
                                    _Tone.accent => 13.5,
                                    _Tone.dim => 18.0,
                                    _Tone.plain => 24.0,
                                  },
                            fontWeight: tone == _Tone.plain
                                ? FontWeight.w400
                                : FontWeight.w600,
                            color: fg,
                          ),
                        ),
                        if (sub != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              sub!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: fg.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
