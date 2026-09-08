import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'l10n/generated/app_localizations.dart';
import 'timing_audio.dart';

/// Timing is derived from the saved title, so old records need no migration.
class TimingSpec {
  const TimingSpec({
    this.bpm,
    this.tabata = false,
    this.work = 20,
    this.rest = 10,
    this.rounds = 8,
  });
  final int? bpm;
  final bool tabata;
  final int work, rest, rounds;
  bool get valid =>
      (bpm == null || (bpm! >= 20 && bpm! <= 300)) &&
      work >= 1 &&
      work <= 600 &&
      rest >= 1 &&
      rest <= 600 &&
      rounds >= 1 &&
      rounds <= 99;
  int get duration => 3 + (work + rest) * rounds;

  static TimingSpec? parse(String name) {
    final bpmWord = RegExp(r'(?<![a-z])bpm(?![a-z])', caseSensitive: false);
    final hasBpm = bpmWord.hasMatch(name);
    final tabata = RegExp(
      r'타바타|タバタ|(?<![a-z])tabata(?![a-z])',
      caseSensitive: false,
    ).hasMatch(name);
    if (!hasBpm && !tabata) return null;
    final tempo = RegExp(
      r'([+-]?\d+(?:[.,]\d+)?)\s*bpm(?![a-z])|(?<![a-z])bpm\s*[:=]?\s*([+-]?\d+(?:[.,]\d+)?)',
      caseSensitive: false,
    ).firstMatch(name);
    final bpm = hasBpm
        ? (tempo == null ? 120 : int.tryParse(tempo[1] ?? tempo[2]!) ?? 0)
        : null;
    final interval = RegExp(
      r'(\d+)\s*(?:초|s|sec)?\s*[/／]\s*(\d+)\s*(?:초|s|sec)?',
      caseSensitive: false,
    ).firstMatch(name);
    final repetitions = RegExp(
      r'[x×]\s*(\d+)|(\d+)\s*(?:라운드|rounds?|ラウンド)',
      caseSensitive: false,
    ).firstMatch(name);
    return TimingSpec(
      bpm: bpm,
      tabata: tabata,
      work: interval == null ? 20 : int.parse(interval[1]!),
      rest: interval == null ? 10 : int.parse(interval[2]!),
      rounds: repetitions == null
          ? 8
          : int.parse(repetitions[1] ?? repetitions[2]!),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TimingSpec &&
      bpm == other.bpm &&
      tabata == other.tabata &&
      work == other.work &&
      rest == other.rest &&
      rounds == other.rounds;
  @override
  int get hashCode => Object.hash(bpm, tabata, work, rest, rounds);
}

enum TimingPhase { ready, work, rest, complete }

/// A monotonic clock determines phases; delayed frames never lengthen a round.
class WorkoutTimer extends ChangeNotifier with WidgetsBindingObserver {
  WorkoutTimer({TimingAudio? audio, Duration Function()? now})
    : _audio = audio ?? createTimingAudio() {
    _now = now;
    _watch.start();
    _audio.onInterrupted = pause;
    WidgetsBinding.instance.addObserver(this);
  }
  final TimingAudio _audio;
  late final Duration Function()? _now;
  final _watch = Stopwatch();
  Duration get _time => _now?.call() ?? _watch.elapsed;
  Timer? _ticker;
  Object? owner;
  TimingSpec? spec;
  bool running = false, soundFailed = false, _disposed = false;
  Duration _elapsed = Duration.zero, _started = Duration.zero;
  Future<void> _commands = Future.value();
  Duration get elapsed =>
      _elapsed + (running ? _time - _started : Duration.zero);
  TimingPhase get phase {
    if (spec?.tabata != true) return TimingPhase.work;
    final seconds = elapsed.inMilliseconds / 1000;
    if (seconds < 3) return TimingPhase.ready;
    if (seconds >= spec!.duration) return TimingPhase.complete;
    return (seconds - 3) % (spec!.work + spec!.rest) < spec!.work
        ? TimingPhase.work
        : TimingPhase.rest;
  }

  int get round => spec?.tabata != true
      ? 1
      : ((elapsed.inMilliseconds / 1000 - 3) / (spec!.work + spec!.rest))
                .floor()
                .clamp(0, spec!.rounds - 1) +
            1;
  int get remaining {
    if (spec?.tabata != true) return elapsed.inSeconds;
    final seconds = elapsed.inMilliseconds / 1000;
    if (phase == TimingPhase.ready) return (3 - seconds).ceil();
    if (phase == TimingPhase.complete) return 0;
    final within = (seconds - 3) % (spec!.work + spec!.rest);
    return ((phase == TimingPhase.work ? spec!.work : spec!.work + spec!.rest) -
            within)
        .ceil();
  }

  void toggle(Object block, TimingSpec value) {
    if (!value.valid) return;
    if (!identical(owner, block) || spec != value) {
      pause();
      owner = block;
      spec = value;
      _elapsed = Duration.zero;
    }
    if (running) {
      pause();
      return;
    }
    if (phase == TimingPhase.complete) _elapsed = Duration.zero;
    soundFailed = false;
    _started = _time;
    running = true;
    _lastPhase = phase;
    _lastRound = round;
    _lastRemaining = remaining;
    _sound(
      cue: spec!.tabata
          ? (phase == TimingPhase.ready ? 'ready' : 'work')
          : null,
    );
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => tick());
    notifyListeners();
  }

  TimingPhase? _lastPhase;
  int? _lastRound, _lastRemaining;
  void tick() {
    if (!running) return;
    final next = phase;
    if (next == TimingPhase.complete) {
      _elapsed = Duration(seconds: spec!.duration);
      running = false;
      _ticker?.cancel();
      _sound(cue: 'complete');
      notifyListeners();
      return;
    }
    if (next != _lastPhase || round != _lastRound) {
      _sound(cue: next == TimingPhase.work ? 'work' : 'rest');
    } else if (next == TimingPhase.ready && remaining != _lastRemaining) {
      _sound(cue: 'ready');
    }
    if (next != _lastPhase ||
        remaining != _lastRemaining ||
        round != _lastRound) {
      _lastPhase = next;
      _lastRound = round;
      _lastRemaining = remaining;
      notifyListeners();
    }
  }

  void _sound({String? cue}) {
    final active = running;
    final bpm = active && phase == TimingPhase.work ? spec?.bpm : null;
    _commands = _commands.then((_) async {
      if (_disposed) return;
      try {
        await _audio.configure(active: active, bpm: bpm, cue: cue);
      } catch (_) {
        if (!_disposed) {
          soundFailed = true;
          notifyListeners();
        }
      }
    });
  }

  void pause() {
    if (!running) return;
    _elapsed = elapsed;
    running = false;
    _ticker?.cancel();
    _sound();
    notifyListeners();
  }

  void reset() {
    pause();
    _elapsed = Duration.zero;
    notifyListeners();
  }

  void clear() {
    reset();
    owner = null;
    spec = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) pause();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _watch.stop();
    WidgetsBinding.instance.removeObserver(this);
    _audio.onInterrupted = null;
    unawaited(_commands.then((_) => _audio.dispose()));
    super.dispose();
  }
}

class WorkoutTimingControls extends StatelessWidget {
  const WorkoutTimingControls({
    super.key,
    required this.owner,
    required this.spec,
    required this.timer,
    required this.onStart,
  });
  final Object owner;
  final TimingSpec spec;
  final WorkoutTimer timer;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: timer,
    builder: (context, _) {
      final l = L.of(context);
      final selected = identical(timer.owner, owner);
      final running = selected && timer.running;
      final phase = selected ? timer.phase : TimingPhase.ready;
      final seconds = selected ? timer.remaining : 3;
      final clock =
          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
      final description = [
        if (spec.bpm != null) l.timingBpm(spec.bpm!),
        if (spec.tabata) l.timingProtocol(spec.work, spec.rest, spec.rounds),
      ].join(' · ');
      final phaseLabel = switch (phase) {
        TimingPhase.ready => l.timingReady,
        TimingPhase.work => l.timingWork,
        TimingPhase.rest => l.timingRest,
        TimingPhase.complete => l.timingComplete,
      };
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            if (!spec.valid)
              Text(
                l.timingInvalid,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      spec.tabata
                          ? '$phaseLabel  $clock  ·  ${l.timingRound(selected ? timer.round : 1, spec.rounds)}'
                          : l.timingMetronome,
                      style: const TextStyle(
                        fontSize: 15,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    onPressed: () {
                      if (!running) onStart();
                      timer.toggle(owner, spec);
                    },
                    child: Text(running ? l.timingPause : l.timingStart),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: selected ? timer.reset : null,
                    child: Icon(
                      CupertinoIcons.arrow_counterclockwise,
                      size: 18,
                      semanticLabel: l.timingReset,
                    ),
                  ),
                ],
              ),
            if (selected && timer.soundFailed)
              Text(
                l.timingSoundFailed,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
          ],
        ),
      );
    },
  );
}
