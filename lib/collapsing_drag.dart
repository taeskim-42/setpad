import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Let the compact layout settle before Flutter captures the dragged item's size.
class CollapsingDragStartListener extends ReorderableDragStartListener {
  const CollapsingDragStartListener({
    super.key,
    required super.child,
    required super.index,
    required this.prepare,
    required this.onCanceled,
  });
  final Future<Offset?> Function(Offset) prepare;
  final VoidCallback onCanceled;

  @override
  MultiDragGestureRecognizer createRecognizer() =>
      _CompactRecognizer(prepare, onCanceled);
}

class _CompactRecognizer extends ImmediateMultiDragGestureRecognizer {
  _CompactRecognizer(this.prepare, this.onCanceled);
  final Future<Offset?> Function(Offset) prepare;
  final VoidCallback onCanceled;

  @override
  set onStart(GestureMultiDragStartCallback? callback) {
    super.onStart = callback == null
        ? null
        : (position) => _PendingDrag(position, callback, prepare, onCanceled);
  }
}

class _PendingDrag extends Drag {
  _PendingDrag(
    this.position,
    GestureMultiDragStartCallback start,
    Future<Offset?> Function(Offset) prepare,
    this.onCanceled,
  ) {
    _start(start, prepare);
  }
  Offset position;
  final VoidCallback onCanceled;
  Drag? delegate;
  bool finished = false;

  Future<void> _start(
    GestureMultiDragStartCallback start,
    Future<Offset?> Function(Offset) prepare,
  ) async {
    final anchor = await prepare(position);
    if (finished) return;
    if (anchor == null) {
      cancel();
      return;
    }
    delegate = start(anchor);
    if (delegate == null) {
      cancel();
      return;
    }
    // Keep the feedback under the pointer after earlier blocks have collapsed.
    delegate!.update(
      DragUpdateDetails(delta: position - anchor, globalPosition: position),
    );
  }

  @override
  void update(DragUpdateDetails details) {
    position += details.delta;
    delegate?.update(details);
  }

  @override
  void end(DragEndDetails details) {
    finished = true;
    if (delegate == null) {
      onCanceled();
    } else {
      delegate!.end(details);
    }
  }

  @override
  void cancel() {
    finished = true;
    if (delegate == null) {
      onCanceled();
    } else {
      delegate!.cancel();
    }
  }
}

/// A canceled drag and an unchanged drop also dispose their overlay proxy.
class ReorderProxy extends StatefulWidget {
  const ReorderProxy({super.key, required this.child, required this.onRemoved});
  final Widget child;
  final VoidCallback onRemoved;
  @override
  State<ReorderProxy> createState() => _ReorderProxyState();
}

class _ReorderProxyState extends State<ReorderProxy> {
  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onRemoved());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
