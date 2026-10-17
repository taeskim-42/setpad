import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'focus_link.dart';
import 'run_page.dart';
import 'stage_palette.dart';
import 'units.dart';

// Stub of the set stage (spec focus-stage-1.8 §7): the block on screen and
// its next set. Lane U replaces this file whole; the contract is the class,
// its constructor and [FocusPage.open].

class FocusPage extends StatefulWidget {
  const FocusPage({super.key, required this.link});
  final FocusLink link;

  /// Pushes the stage as a full-screen dialog (no iOS edge swipe).
  static Future<void> open(BuildContext context, FocusLink link) =>
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => FocusPage(link: link),
        ),
      );

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  @override
  void initState() {
    super.initState();
    StagePortrait.enter();
  }

  @override
  void dispose() {
    StagePortrait.leave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      systemNavigationBarColor: StagePalette.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: ColoredBox(
      color: StagePalette.bg,
      child: SafeArea(
        child: DefaultTextStyle(
          style: const TextStyle(color: StagePalette.text, fontSize: 20),
          child: ListenableBuilder(
            listenable: widget.link,
            builder: (context, _) {
              final link = widget.link;
              final block = link.blocks
                  .where((b) => b.id == link.currentId)
                  .firstOrNull;
              final next = block == null ? null : link.suggest?.call(block);
              final v = next?.values;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StageCollapseButton(
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    block?.name ?? '',
                    key: const ValueKey('focus-name'),
                    textAlign: TextAlign.center,
                  ),
                  if (v != null)
                    Text(
                      [
                        if (v.value != null) formatValue(v.value!, v.unit),
                        if (v.reps != null) '× ${v.reps}',
                      ].join(' '),
                      key: const ValueKey('focus-next'),
                      textAlign: TextAlign.center,
                    ),
                  const Spacer(),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
