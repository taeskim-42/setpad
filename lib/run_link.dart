import 'package:flutter/foundation.dart';

import 'rest_recovery.dart';
import 'workout_timing.dart';

/// What the run stage needs from the editor. The editor (lane C) fills it and
/// recomputes [together] on every rebuild; the stage (lane S) only reads it and
/// calls back. Sets are logged by the editor through the callbacks — the
/// engine knows nothing about sets.
class RunLink extends ChangeNotifier {
  RunLink(this.timer);
  final WorkoutTimer timer;

  /// Exercise name (small text at the top of the stage).
  String title = '';

  /// Set weight such as "16kg", shown on the stage and summary when present.
  String? weightLabel;

  /// Only while doing it together.
  TogetherTiming? together;

  /// Heart rate; null without one.
  RestRecovery? recovery;

  /// Together, heart rate never cuts the rest short.
  bool heartShared = false;

  /// Reps logged per round in this run (index 0 = round 1); null = not logged.
  final List<int?> roundReps = [];

  /// Write or fix one round's set (the editor keeps it as roundSets).
  void Function(int round, int? reps)? onLogRound;

  /// Metronome: one set of this many reps.
  void Function(int reps)? onLogCount;

  /// Together: leave and rejoin (the editor's _leaveShared and friends).
  VoidCallback? onLeave, onRejoin;

  /// The summary has logged everything (the stage closes).
  VoidCallback? onLogged;

  /// This run was logged as sets.
  bool logged = false;

  void changed() => notifyListeners();
}
