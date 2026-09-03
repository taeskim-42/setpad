import 'package:flutter/material.dart';

const _seal = Color(0xFFC3372A);

/// 숫자만 있는 키패드.
///
/// 앞선 판에는 kg·회·× 키가 있었다. 칸이 단위를 알고 있으면 그 셋이 전부
/// 필요 없어진다 — 특히 ×는 "세트 반복"이라는 뜻이었는데, 기호만 보고
/// 알아낼 방법이 없었다. 세트는 이제 줄을 늘려서 만든다.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onNext,
    required this.onDone,
    required this.onAdjust,
    required this.nextLabel,
    required this.stepLabel,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// 무게 → 횟수 → 다음 세트. 한 버튼이 한 방향으로만 밀어준다.
  final VoidCallback onNext;

  /// 이 운동 끝.
  final VoidCallback onDone;

  /// 지금 칸의 값을 한 단계 올리거나 내린다. 무게는 원판 단위(2.5kg),
  /// 횟수는 하나 — 숫자를 다시 치는 것보다 이쪽이 훨씬 잦다.
  final ValueChanged<int> onAdjust;

  final String nextLabel;
  final String stepLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD8D9DE),
        border:
            Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.12))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _row(['1', '2', '3']),
                  _row(['4', '5', '6']),
                  _row(['7', '8', '9']),
                  _row(['.', '0', '⌫']),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                children: [
                  // 원판 단위로 미는 두 키. 실제로 가장 많이 눌린다.
                  Row(
                    children: [
                      Expanded(
                        child: _pad(_Key(
                          label: '−$stepLabel',
                          onTap: () => onAdjust(-1),
                          tone: _Tone.dim,
                        )),
                      ),
                      Expanded(
                        child: _pad(_Key(
                          label: '+$stepLabel',
                          onTap: () => onAdjust(1),
                          tone: _Tone.dim,
                        )),
                      ),
                    ],
                  ),
                  _pad(_Key(
                    label: nextLabel,
                    onTap: onNext,
                    tone: _Tone.primary,
                    height: 52,
                  )),
                  _pad(_Key(
                    label: '운동 완료',
                    onTap: onDone,
                    tone: _Tone.plain,
                    height: 46,
                  )),
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
              child: _pad(k == '⌫'
                  ? _Key(icon: Icons.backspace_outlined, onTap: onBackspace,
                      tone: _Tone.dim)
                  : _Key(label: k, onTap: () => onDigit(k), tone: _Tone.plain)),
            ),
        ],
      );

  Widget _pad(Widget child) =>
      Padding(padding: const EdgeInsets.all(3), child: child);
}

enum _Tone { plain, dim, primary }

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    this.icon,
    required this.onTap,
    required this.tone,
    this.height = 46,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final _Tone tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      _Tone.plain => (Colors.white, Colors.black.withValues(alpha: 0.85)),
      _Tone.dim =>
        (const Color(0xFFBEC0C7), Colors.black.withValues(alpha: 0.8)),
      _Tone.primary => (_seal, Colors.white),
    };

    return SizedBox(
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        elevation: tone == _Tone.dim ? 0 : 0.5,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 20, color: fg)
                : Text(
                    label!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: switch (tone) {
                        _Tone.primary => 14.0,
                        _Tone.dim => 15.0,
                        _Tone.plain => 20.0,
                      },
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
