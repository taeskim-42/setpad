import 'package:flutter/cupertino.dart';

import 'run_link.dart';

/// Full-screen run stage. Stub until lane S replaces it: one number.
class RunPage extends StatefulWidget {
  const RunPage({super.key, required this.link});
  final RunLink link;

  @override
  State<RunPage> createState() => _RunPageState();
}

class _RunPageState extends State<RunPage> {
  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    child: Center(
      child: ListenableBuilder(
        listenable: widget.link.timer,
        builder: (context, _) => Text(
          '${widget.link.timer.remaining}',
          style: const TextStyle(fontSize: 96, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}
