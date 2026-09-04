import 'package:flutter/material.dart';

const _seal = Color(0xFFC3372A);

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
    required this.onSubmit,
    required this.onText,
    required this.onAdjust,
    required this.stepLabel,
    this.repeatLabel,
    this.onRepeat,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;

  /// 메모처럼 글자가 필요할 때 시스템 키보드로 넘긴다.
  final VoidCallback onText;

  /// 치고 있는 마지막 숫자를 한 단계 민다. 숫자를 지우고 다시 치는 것보다
  /// 이쪽이 훨씬 잦다.
  final ValueChanged<int> onAdjust;

  /// 지금 밀면 얼마가 움직이는지. 누르기 전에 보여야 한다.
  final String stepLabel;

  /// 직전 세트를 그대로 한 번 더 — 운동 기록에서 가장 흔한 동작이다.
  final String? repeatLabel;
  final VoidCallback? onRepeat;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (repeatLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: _Key(
                    label: '이전과 같이  $repeatLabel',
                    onTap: onRepeat!,
                    tone: _Tone.accent,
                    height: 38,
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _row(const ['1', '2', '3']),
                      _row(const ['4', '5', '6']),
                      _row(const ['7', '8', '9']),
                      // 공백은 뺄 수 없다 — 칸이 나뉘어 있지 않아서
                      // 무게와 횟수를 가르는 유일한 구분자다.
                      _row(const ['.', '0', '␣']),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    children: [
                      _pad(_Key(
                        icon: Icons.backspace_outlined,
                        onTap: onBackspace,
                        tone: _Tone.dim,
                      )),
                      _pad(_Key(
                        icon: Icons.keyboard_alt_outlined,
                        onTap: onText,
                        tone: _Tone.dim,
                      )),
                      Row(
                        children: [
                          Expanded(
                            child: _pad(_Key(
                              label: '−',
                              sub: stepLabel,
                              onTap: () => onAdjust(-1),
                              tone: _Tone.dim,
                            )),
                          ),
                          Expanded(
                            child: _pad(_Key(
                              label: '+',
                              sub: stepLabel,
                              onTap: () => onAdjust(1),
                              tone: _Tone.dim,
                            )),
                          ),
                        ],
                      ),
                      _pad(_Key(
                        label: '세트 추가',
                        onTap: onSubmit,
                        tone: _Tone.primary,
                        height: 46,
                      )),
                    ],
                  ),
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
                label: k,
                onTap: () => onKey(k == '␣' ? ' ' : k),
                tone: _Tone.plain,
              )),
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
    this.height = 46,
  });

  final String? label;

  /// 버튼 아래 작게 붙는 설명. −/+ 가 얼마씩 미는지 여기 적는다.
  final String? sub;
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
      _Tone.accent => (const Color(0xFFF7E9E6), _seal),
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
                ? Icon(icon, size: 19, color: fg)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: switch (tone) {
                            _Tone.primary => 14.0,
                            _Tone.accent => 13.5,
                            _Tone.dim => 18.0,
                            _Tone.plain => 20.0,
                          },
                          fontWeight: FontWeight.w700,
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
    );
  }
}
