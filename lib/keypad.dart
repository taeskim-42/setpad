import 'package:flutter/material.dart';

const _seal = Color(0xFFC3372A);

/// 세트를 칠 때만 뜨는 전용 키패드.
///
/// 시스템 키보드로 "100kg 20회"를 치려면 한글 자판과 숫자 자판을 오가야 하고
/// kg·회는 한글이다. 세트마다 그 짓을 하는 건 운동 중에 할 동작이 아니다.
/// 여기 있는 것만으로 세트 한 줄이 완성된다.
///
/// 운동 **이름**은 여전히 시스템 키보드로 친다 — 어휘가 무한하고 자동완성이
/// 대신 받아주기 때문에, 전용 키패드로 덮을 이유가 없다.
class SetKeypad extends StatelessWidget {
  const SetKeypad({
    super.key,
    required this.onKey,
    required this.onBackspace,
    required this.onSubmit,
    required this.onText,
    this.repeatLabel,
    this.onRepeat,
  });

  /// 글자 하나를 커서 자리에 넣는다.
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;

  /// 메모처럼 글자가 필요할 때 시스템 키보드로 넘긴다.
  final VoidCallback onText;

  /// 직전 세트를 그대로 한 번 더 — 운동 기록에서 가장 흔한 동작이다.
  final String? repeatLabel;
  final VoidCallback? onRepeat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD8D9DE),
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.12))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (repeatLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: _Key(
                    label: '이전과 같이  $repeatLabel',
                    onTap: onRepeat!,
                    tone: _Tone.accent,
                    height: 40,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _row(['1', '2', '3']),
                      _row(['4', '5', '6']),
                      _row(['7', '8', '9']),
                      _row(['.', '0', ' ']),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    children: [
                      _pad(_Key(label: 'kg', onTap: () => onKey('kg '), tone: _Tone.unit)),
                      _pad(_Key(label: '회', onTap: () => onKey('회 '), tone: _Tone.unit)),
                      _pad(_Key(label: '×', onTap: () => onKey('x'), tone: _Tone.unit)),
                      _pad(_Key(icon: Icons.backspace_outlined, onTap: onBackspace,
                          tone: _Tone.unit)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _pad(_Key(
                    label: '메모',
                    icon: Icons.keyboard_alt_outlined,
                    onTap: onText,
                    tone: _Tone.plain,
                  )),
                ),
                Expanded(
                  flex: 2,
                  child: _pad(_Key(
                    label: '세트 추가',
                    onTap: onSubmit,
                    tone: _Tone.primary,
                  )),
                ),
              ],
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
              child: _pad(_Key(
                label: k == ' ' ? '␣' : k,
                onTap: () => onKey(k),
                tone: _Tone.plain,
              )),
            ),
        ],
      );

  Widget _pad(Widget child) => Padding(padding: const EdgeInsets.all(3), child: child);
}

enum _Tone { plain, unit, primary, accent }

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, required this.onTap, required this.tone, this.height = 46});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final _Tone tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      _Tone.plain => (Colors.white, Colors.black.withValues(alpha: 0.85)),
      _Tone.unit => (const Color(0xFFBEC0C7), Colors.black.withValues(alpha: 0.8)),
      _Tone.primary => (_seal, Colors.white),
      _Tone.accent => (const Color(0xFFF7E9E6), _seal),
    };

    return SizedBox(
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        elevation: tone == _Tone.unit ? 0 : 0.5,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon, size: 18, color: fg),
                if (icon != null && label != null) const SizedBox(width: 6),
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: tone == _Tone.primary ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
