import 'package:flutter/cupertino.dart';

import 'l10n/generated/app_localizations.dart';
import 'metrics.dart';
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
                  height: minTap,
                ),
              ),
            ),
            // 두 열이 한 높이(숫자 키 네 줄)를 나눠 쓴다. 키는 글자 크기로 자라지
            // 않고 글자가 키에 맞춰 줄어든다([_Key]) — 키 높이를 글자로 재던 때는
            // 글자를 키운 폰에서 오른쪽 열(−/+ 의 두 줄 글자)이 숫자 격자보다 길어져
            // 두 열 바닥이 어긋났다. iOS 키보드도 글자 크기로 자라지 않는다.
            SizedBox(
              height: 4 * (_keyHeight + 2 * _gap),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _row(context, const ['1', '2', '3']),
                        _row(context, const ['4', '5', '6']),
                        _row(context, const ['7', '8', '9']),
                        // Strong 과 같은 자리에 지우기를 둔다. 숫자를 치다가
                        // 틀렸을 때 손이 가장 가까운 곳이 여기다.
                        _row(context, const ['.', '0', '⌫']),
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
                              // 글자판으로 넘기는 것은 곧 이 세트에 메모를 단다는 뜻이다.
                              semanticLabel: L.of(context).noteHint,
                              onTap: onText,
                              tone: _Tone.dim,
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
                            ),
                          ),
                        ),
                        Expanded(
                          child: _pad(
                            _Key(
                              label: submitLabel,
                              onTap: onSubmit,
                              tone: _Tone.primary,
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

  Widget _row(BuildContext context, List<String> keys) => Expanded(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final k in keys)
          Expanded(
            child: _pad(
              k == '⌫'
                  // 지우기는 글자가 아니라 동작이다. 숫자 키 사이에 있지만
                  // 아이콘으로 내야 무엇인지 바로 보인다.
                  ? _Key(
                      icon: CupertinoIcons.delete_left,
                      semanticLabel: L.of(context).delete,
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
    ),
  );

  Widget _pad(Widget child) =>
      Padding(padding: const EdgeInsets.all(_gap), child: child);
}

/// 숫자 키 높이와 키 사이 반 간격.
const _keyHeight = 46.0, _gap = 3.0;

enum _Tone { plain, dim, primary, accent }

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    this.sub,
    this.icon,
    this.semanticLabel,
    required this.onTap,
    required this.tone,
    this.onLongPress,
    this.height,
    this.compact = false,
  });

  final String? label;

  /// 길게 눌렀을 때. 없으면 길게 눌러도 아무 일도 없다.
  final VoidCallback? onLongPress;

  /// 버튼 아래 작게 붙는 설명. −/+ 가 얼마씩 미는지 여기 적는다.
  final String? sub;
  final IconData? icon;

  /// 아이콘 키를 VoiceOver 가 읽을 말. 글자 키는 글자 그대로 읽힌다.
  final String? semanticLabel;
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

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: SizedBox(
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
                    // 한 줄로 두고 키에 맞춰 줄인다 — 감기면 '2.5kg' 이 '2.5k/g',
                    // '세트 추가' 가 '세트 추/가' 처럼 낱말 가운데서 끊겼다.
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
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
          ),
        ),
      ),
    );
  }
}
