import 'package:flutter/cupertino.dart';

/// 접고 펴는 자리. 높이가 부드럽게 늘고 줄며 내용은 번지듯 나타난다 — 툭 튀어나오면
/// 무엇이 열렸는지 눈이 못 따라갔다.
class Unfold extends StatelessWidget {
  const Unfold({super.key, required this.open, required this.child});
  final bool open;
  final Widget child;

  static const duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: duration,
    curve: Curves.easeInOut,
    alignment: Alignment.topCenter,
    child: AnimatedSwitcher(
      duration: duration,
      child: open
          ? KeyedSubtree(key: const ValueKey(true), child: child)
          : const SizedBox(key: ValueKey(false), width: double.infinity),
    ),
  );
}

/// 펴면 위를 보는 화살표 — 돌아간다.
class UnfoldChevron extends StatelessWidget {
  const UnfoldChevron({
    super.key,
    required this.open,
    this.size = 13,
    this.color,
  });
  final bool open;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => AnimatedRotation(
    turns: open ? 0.5 : 0,
    duration: Unfold.duration,
    curve: Curves.easeInOut,
    child: Icon(CupertinoIcons.chevron_down, size: size, color: color),
  );
}
