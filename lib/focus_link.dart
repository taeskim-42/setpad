import 'package:flutter/foundation.dart';

import 'editor.dart';
import 'focus.dart';
import 'rest_recovery.dart';
import 'rest_timer.dart';

/// What the set stage reads and calls (spec focus-stage-1.8 §6). The editor
/// fills it; the stage only reads. [changed] redraws the chips, the block
/// list and the strips — it never overwrites the values the person set.
class FocusLink extends ChangeNotifier {
  FocusLink({required this.rest});
  final RestTimer rest;

  /// In document order, timer blocks included.
  List<ExerciseBlock> blocks = const [];

  /// The block on screen. Gone: the nearest one; none left: the stage closes.
  String? currentId;
  String weightUnit = 'kg';
  RestRecovery? recovery;

  /// A shared timer runs (the strip at the top).
  bool sharedTimerRunning = false;

  /// Read when entering a block, after [Done], after undo and when the rest
  /// ends — not on [changed].
  FocusSuggestion Function(ExerciseBlock b)? suggest;

  /// Last time's sets of this exercise, for the summary.
  ({DateTime at, List<LoggedSet> sets})? Function(ExerciseBlock b)? lastTime;

  Duration Function(ExerciseBlock b)? restFor;
  void Function(ExerciseBlock b, Duration d)? onRestChanged;

  /// Finds the set again by [plannedId] at the moment of writing. Missing,
  /// already done or someone else's: a new set. Returns the id written, null
  /// when nothing was written.
  String? Function(ExerciseBlock b, String? plannedId, LoggedSet values)? onLog;

  /// Takes back what was just written: a new set is removed, a planned one
  /// gets its old values and ○ again.
  void Function(ExerciseBlock b, String setId)? onUndo;

  /// A timer block: open the timer stage.
  void Function(ExerciseBlock b)? onStartTimer;
  VoidCallback? onOpenSharedTimer;

  /// The stage entered LIFT on [b] (heart rate: beginRound).
  void Function(ExerciseBlock b)? onLift;

  /// A rest started on [b] after [Done] (heart rate: beginRest).
  void Function(ExerciseBlock b)? onRested;

  void changed() => notifyListeners();
}
