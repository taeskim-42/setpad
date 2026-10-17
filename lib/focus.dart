import 'dart:math' as math;

import 'editor.dart';
import 'notes.dart';
import 'record_query.dart' show exerciseKey;
import 'units.dart';

// The set stage's arithmetic (spec focus-stage-1.8 §3): what the next set is,
// when a block's plan is over, how the steppers move and the summary numbers.
// Pure: no widgets, no clocks. Numbers come only from the plan, last time,
// today's last set or the title's setup — never made up.

/// Where a suggested set came from (the stage's label).
enum FocusSource { planned, lastTime, lastSet, setup, none }

/// What a set measures: no value is reps only (bodyweight).
enum FocusKind { reps, weight, duration, distance }

class FocusSuggestion {
  FocusSuggestion({
    required this.values,
    required this.source,
    this.plannedId,
    this.lastTimeSame,
  });

  /// The numbers to show and log (a fresh set, not one of the block's).
  final LoggedSet values;
  final FocusSource source;

  /// The planned (○) set these values fill; null for a new set.
  final String? plannedId;

  /// Last time's set at today's position ("last time here"), whatever the
  /// source.
  final LoggedSet? lastTimeSame;
}

/// The latest earlier note with my done sets of [key]: its time and those
/// sets in document order. [earlier] is my records other than this one.
({DateTime at, List<LoggedSet> sets})? lastTimeOf(
  Iterable<Note> earlier,
  String key,
) {
  ({DateTime at, List<LoggedSet> sets})? best;
  for (final n in earlier) {
    if (best != null && !n.createdAt.isAfter(best.at)) continue;
    final sets = [
      for (final b in n.blocks)
        if (exerciseKey(b.exercise) == key)
          for (final s in b.sets)
            if (s.mine) s,
    ];
    if (sets.isNotEmpty) best = (at: n.createdAt, sets: sets);
  }
  return best;
}

/// The next set to do in [block] (§3): planned → last time (k-th) → today's
/// last set → the title's setup → none. Other people's sets are never a
/// source. [key] is `exerciseKey(block.exercise)`.
FocusSuggestion nextSet(
  ExerciseBlock block,
  Iterable<Note> earlier, {
  required String key,
  String weightUnit = 'kg',
}) {
  final done = block.sets.where((s) => !s.theirs && s.done).toList();
  final last = lastTimeOf(earlier, key)?.sets;
  final same = last == null
      ? null
      : _copy(last[math.min(done.length, last.length - 1)]);
  FocusSuggestion of(LoggedSet v, FocusSource source, [String? id]) =>
      FocusSuggestion(
        values: v,
        source: source,
        plannedId: id,
        lastTimeSame: same,
      );

  final planned = block.sets.where((s) => !s.theirs && !s.done).firstOrNull;
  if (planned != null) {
    return of(_copy(planned), FocusSource.planned, planned.id);
  }
  if (same != null) return of(same, FocusSource.lastTime);
  if (done.lastOrNull case final s?) return of(_copy(s), FocusSource.lastSet);
  final setup = block.setup;
  if (setup != null && (setup.weight != null || setup.repsPerSet != null)) {
    return of(
      _copy(
        LoggedSet(
          value: setup.weight,
          unit: setup.unit,
          reps: setup.repsPerSet,
        ),
      ),
      FocusSource.setup,
    );
  }
  return of(LoggedSet(unit: weightUnit), FocusSource.none);
}

/// A fresh set with [s]'s numbers; a weight of 0 is bodyweight (null).
LoggedSet _copy(LoggedSet s) => LoggedSet(
  value: s.value == 0 && _kindOfUnit(s.unit) == FocusKind.weight
      ? null
      : s.value,
  unit: s.unit,
  reps: s.reps,
);

FocusKind _kindOfUnit(String unit) =>
    switch (unitById[unit]?.kind ?? UnitKind.weight) {
      UnitKind.weight => FocusKind.weight,
      UnitKind.duration => FocusKind.duration,
      UnitKind.distance => FocusKind.distance,
    };

FocusKind kindOf(LoggedSet s) =>
    s.value == null ? FocusKind.reps : _kindOfUnit(s.unit);

/// The block's plan is over: none of my ○ left and — when [hadPlan] (the
/// block had ○ sets when the stage first saw it) — that is all; otherwise the
/// setup's total sets, or its total reps, are reached. Else false.
bool planDone(ExerciseBlock block, {bool hadPlan = false}) {
  if (block.sets.any((s) => !s.theirs && !s.done)) return false;
  if (hadPlan) return true;
  final setup = block.setup;
  if (setup?.totalSets case final n?) {
    return block.sets.where((s) => s.mine).length >= n;
  }
  if (setup?.totalReps case final n?) return block.completedReps >= n;
  return false;
}

/// One stepper press on the value: the unit's step (kg 2.5, lb 5, s 10,
/// min 1, km 0.5, m 50, mi 0.5).
double valueStep(String unit) => unitById[unit]?.step ?? 2.5;

/// The value one step up (+1) or down (−1). Never below 0; a weight that
/// reaches 0 is bodyweight (null), and bodyweight steps up from 0.
LoggedSet stepValue(LoggedSet s, int direction) {
  final kind = _kindOfUnit(s.unit);
  final next = math.max(0.0, (s.value ?? 0) + direction * valueStep(s.unit));
  final rounded = (next * 100).round() / 100;
  return LoggedSet(
    value: rounded == 0 && kind == FocusKind.weight ? null : rounded,
    unit: s.unit,
    reps: s.reps,
  );
}

/// Reps one up or down; 0 is no reps (null).
LoggedSet stepReps(LoggedSet s, int direction) {
  final next = math.max(0, (s.reps ?? 0) + direction);
  return LoggedSet(value: s.value, unit: s.unit, reps: next == 0 ? null : next);
}

/// [Done] is on: weight and bodyweight need a rep; time and distance a value.
bool canLog(LoggedSet s) => switch (kindOf(s)) {
  FocusKind.reps || FocusKind.weight => (s.reps ?? 0) >= 1,
  FocusKind.duration || FocusKind.distance => (s.value ?? 0) > 0,
};

/// kg per lb.
const _lbPerKg = 2.20462;

/// The summary of [sets] (only mine and done count).
///
/// [kind] weight when any set has a weight: [total] is the volume Σ(weight ×
/// reps) in [unit] (the first weight set's unit; others converted), bodyweight
/// sets add 0 to it and their reps to [reps]. Duration/distance: [total] is
/// Σ value in the first set's unit. Bodyweight only: [total] = Σ reps.
/// [best]: heaviest (then most reps); bodyweight most reps; time/distance the
/// longest.
typedef FocusStats = ({
  int sets,
  FocusKind kind,
  double total,
  String unit,
  int reps,
  LoggedSet? best,
});

FocusStats stats(Iterable<LoggedSet> sets) {
  final mine = sets.where((s) => s.mine).toList();
  final reps = mine.fold(0, (n, s) => n + (s.reps ?? 0));
  final weighted = mine.where((s) => kindOf(s) == FocusKind.weight);
  final measured = mine.where((s) => s.value != null);
  final kind = weighted.isNotEmpty
      ? FocusKind.weight
      : measured.isNotEmpty
      ? kindOf(measured.first)
      : FocusKind.reps;
  switch (kind) {
    case FocusKind.reps:
      return (
        sets: mine.length,
        kind: kind,
        total: reps.toDouble(),
        unit: '',
        reps: reps,
        best: _max(mine, (s) => (s.reps ?? 0).toDouble()),
      );
    case FocusKind.weight:
      final unit = weighted.first.unit;
      double w(LoggedSet s) => s.unit == unit
          ? s.value!
          : unit == 'lb'
          ? s.value! * _lbPerKg
          : s.value! / _lbPerKg;
      return (
        sets: mine.length,
        kind: kind,
        total: weighted.fold(0.0, (t, s) => t + w(s) * (s.reps ?? 0)),
        unit: unit,
        reps: reps,
        best: _max(weighted, w, then: (s) => (s.reps ?? 0).toDouble()),
      );
    case FocusKind.duration || FocusKind.distance:
      final same = measured.where((s) => kindOf(s) == kind);
      final unit = same.first.unit;
      double v(LoggedSet s) =>
          s.value! * (baseFactor[s.unit] ?? 1) / (baseFactor[unit] ?? 1);
      return (
        sets: mine.length,
        kind: kind,
        total: same.fold(0.0, (t, s) => t + v(s)),
        unit: unit,
        reps: reps,
        best: _max(same, v),
      );
  }
}

/// The first set with the most [by], ties broken by [then].
LoggedSet? _max(
  Iterable<LoggedSet> sets,
  double Function(LoggedSet) by, {
  double Function(LoggedSet)? then,
}) => sets.isEmpty
    ? null
    : sets.reduce((a, b) {
        final c = by(b).compareTo(by(a));
        return c > 0 || (c == 0 && then != null && then(b) > then(a)) ? b : a;
      });
