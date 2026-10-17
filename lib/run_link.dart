import 'package:flutter/foundation.dart';

import 'rest_recovery.dart';
import 'workout_timing.dart';

/// What the run stage needs from the editor. The editor (lane C) fills it and
/// recomputes [together] on every rebuild; the stage (lane S) only reads it and
/// calls back. Sets are logged by the editor through the callbacks — the
/// engine knows nothing about sets.
class RunLink extends ChangeNotifier {
  RunLink(this.timer) : _run = timer.runId {
    timer.addListener(_follow);
  }
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

  /// Reps of the block's last set before this run: where the stage's rest
  /// log starts when this run has logged nothing yet.
  int? lastReps;

  /// Reps logged per round in this run (index 0 = round 1); null = not logged.
  /// The only record of what this run logged — together too.
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

  /// Clears the set of a logged round (the summary's "clear").
  void Function(int round)? onClearRound;

  /// Reps picked on the summary for rounds not logged yet (1-based).
  final drafts = <int, int?>{};

  /// The summary's flash has played for this run.
  bool flashed = false;

  void changed() => notifyListeners();

  /// What this run logged ends with the run ([WorkoutTimer.runId]).
  int _run;
  void _follow() {
    if (timer.runId == _run) return;
    _run = timer.runId;
    roundReps.clear();
    drafts.clear();
    logged = false;
    flashed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    timer.removeListener(_follow);
    super.dispose();
  }
}
