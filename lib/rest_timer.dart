import 'dart:async';

import 'package:flutter/widgets.dart';

import 'timing_audio.dart';
import 'workout_timing.dart' show TimerHaptic, phraseVoice, platformHaptic;

/// Puts the end of a rest on the lock screen while the app is away.
abstract class RestNotifier {
  Future<void> schedule(DateTime at, String title, String body);
  Future<void> cancel();

  /// The rest ended while away and the app is alive to see it: the notice
  /// belongs to now, not to a scheduled time that may still be ahead.
  Future<void> endedAway(String title, String body);
}

/// The rest between sets on the set stage (spec focus-stage-1.8 §5).
///
/// A monotonic clock with the wall clock putting back time the device slept
/// (the [WorkoutTimer] rule: gaps under 1 s add up, over an hour are dropped).
/// It does not stop in the background. Its sound goes through its own port
/// of the shared audio ([TimingAudioMux]).
class RestTimer extends ChangeNotifier with WidgetsBindingObserver {
  /// [muted]: another timer is sounding (the workout timer runs) — no cues
  /// and no haptics then, only the active state. [now] replaces the monotonic
  /// clock and [wallNow] the wall clock (tests); with [now] and no [wallNow]
  /// the wall-clock correction is off.
  RestTimer({
    required this.audio,
    this.muted,
    Duration Function()? now,
    DateTime Function()? wallNow,
    void Function(TimerHaptic)? haptic,
    this.notifier,
  }) : _now = now,
       _wallNow = wallNow ?? (now == null ? DateTime.now : null),
       _haptic = haptic ?? platformHaptic {
    _watch.start();
    WidgetsBinding.instance.addObserver(this);
  }

  static const minLeft = Duration(seconds: 5),
      maxLength = Duration(minutes: 10);

  /// This timer's port of the shared audio; disposed with the timer.
  final TimingAudio audio;
  final bool Function()? muted;
  final Duration Function()? _now;
  final DateTime Function()? _wallNow;
  final void Function(TimerHaptic) _haptic;
  final RestNotifier? notifier;
  final _watch = Stopwatch();
  Duration get _time => _now?.call() ?? _watch.elapsed;

  /// The lock-screen notice when the app goes away mid-rest: title and body
  /// (focusRestOverTitle, focusNextUp(next set)). Null: no notice.
  ({String title, String body}) Function()? notice;

  /// The block that started the rest. Kept after the rest ends.
  Object? owner;

  bool haptics = true;

  /// The recorded voice ('m'/'w') and whether it speaks: "Go!" after the end
  /// sound, "Ten seconds!" with 10 s left of a rest of 30 s or more
  /// (NotesStore.voice, voiceCues). Muted, it says nothing either.
  String voice = 'm';
  bool voiceCues = true;

  /// Natural end (0 s) or [skip]; not [stop].
  VoidCallback? onDone;

  bool get running => _running;
  bool _running = false, _away = false, _disposed = false;

  Duration get length => _length;
  Duration _length = Duration.zero;

  /// Clock time already counted (sleep gaps) plus since [_started].
  Duration _counted = Duration.zero, _started = Duration.zero;
  Duration get _elapsed =>
      _counted + (_running ? _time - _started : Duration.zero);

  Duration get remaining {
    final left = _length - _elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// 1 at the start, 0 at the end (the stage's water).
  double get level => !_running || _length <= Duration.zero
      ? 0
      : (remaining.inMicroseconds / _length.inMicroseconds).clamp(0.0, 1.0);

  int get _left => (remaining.inMilliseconds / 1000).ceil();
  int _lastLeft = 0;
  Timer? _ticker;

  bool get _quiet => muted?.call() ?? false;

  /// A new rest of [length] for [owner]; one already running is replaced.
  void start(Object owner, Duration length) {
    this.owner = owner;
    _length = length > maxLength ? maxLength : length;
    _counted = Duration.zero;
    _started = _time;
    _markClocks();
    _running = true;
    _lastLeft = _left;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => tick());
    _sound(active: true);
    _renotify();
    notifyListeners();
  }

  /// ±15 s on this rest: at least [minLeft] stays (a minus never lengthens
  /// it), and the whole rest is at most [maxLength] (a plus never shortens).
  void add(Duration delta) {
    if (!_running) return;
    var next = _length + delta;
    if (delta.isNegative) {
      final floor = _elapsed + minLeft;
      if (next < floor) next = floor < _length ? floor : _length;
    } else if (next > maxLength) {
      next = _length > maxLength ? _length : maxLength;
    }
    _length = next;
    _lastLeft = _left;
    _renotify();
    notifyListeners();
  }

  /// Ends now: [onDone], no sound.
  void skip() {
    if (!_running) return;
    _halt();
    _sound(active: false);
    unawaited(notifier?.cancel());
    notifyListeners();
    onDone?.call();
  }

  /// Ends quietly: no [onDone], no sound.
  void stop() {
    if (!_running) return;
    _halt();
    _sound(active: false);
    unawaited(notifier?.cancel());
    notifyListeners();
  }

  void tick() {
    if (!_running) return;
    _correctClock();
    final left = _left;
    if (left == _lastLeft) return;
    _lastLeft = left;
    if (left <= 0) {
      _halt();
      _counted = _length;
      // One call: stopping without a cue would cut the end sound.
      _cue(active: false, cue: 'complete', haptic: TimerHaptic.success);
      _say('start');
      final n = notifier, text = _away ? notice?.call() : null;
      if (n != null && text != null) {
        unawaited(n.endedAway(text.title, text.body));
      }
      notifyListeners();
      onDone?.call();
      return;
    }
    if (left == 10 && _length >= const Duration(seconds: 30)) _say('ten_left');
    if (left <= 3) _cue(active: true, cue: 'ready', haptic: TimerHaptic.tick);
    notifyListeners();
  }

  void _halt() {
    _counted = _elapsed;
    _running = false;
    _ticker?.cancel();
    _ticker = null;
  }

  void _cue({
    required bool active,
    required String cue,
    required TimerHaptic haptic,
  }) {
    final quiet = _quiet;
    // Muted the port still says whether it is active; a cue-less "still
    // active" changes nothing, so it is not sent.
    if (quiet && active) return;
    _sound(active: active, cue: quiet ? null : cue);
    if (haptics && !quiet) _haptic(haptic);
  }

  /// After the cue sent just before it (the port keeps the order).
  void _say(String key) {
    if (_disposed || !voiceCues || _quiet) return;
    unawaited(
      audio.playVoice(phraseVoice(voice, key)).catchError((Object _) {}),
    );
  }

  void _sound({required bool active, String? cue}) {
    if (_disposed) return;
    // Sound is an extra, never the clock's premise.
    unawaited(
      audio.configure(active: active, cue: cue).catchError((Object _) {}),
    );
  }

  DateTime? _wallMark;
  Duration _monoMark = Duration.zero;

  void _markClocks() {
    _wallMark = _wallNow?.call();
    _monoMark = _time;
  }

  void _correctClock() {
    final wall = _wallNow?.call(), mark = _wallMark;
    if (wall != null && mark != null) {
      final gap = wall.difference(mark) - (_time - _monoMark);
      if (gap >= Duration.zero && gap < const Duration(seconds: 1)) return;
      if (gap >= const Duration(seconds: 1) && gap < const Duration(hours: 1)) {
        _counted += gap;
      }
    }
    _markClocks();
  }

  /// Drops the notice and, while away, sets it for the new end.
  void _renotify() {
    final n = notifier;
    if (n == null) return;
    unawaited(n.cancel());
    if (_away && _running) _schedule(n);
  }

  void _schedule(RestNotifier n) {
    final text = notice?.call();
    if (text == null) return;
    final at = (_wallNow ?? DateTime.now)().add(remaining);
    unawaited(n.schedule(at, text.title, text.body));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        if (_away) return;
        _away = true;
        if (_running && notifier != null) _schedule(notifier!);
      case AppLifecycleState.resumed:
        final was = _away;
        _away = false;
        if (was) {
          unawaited(notifier?.cancel());
          _correctClock();
          // It ended while the app was away (suspended): the notice said so.
          // The end sound and "Go!" are not played late.
          if (_running && _left <= 0) {
            _halt();
            _counted = _length;
            _sound(active: false);
            notifyListeners();
            onDone?.call();
            return;
          }
        }
        tick();
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    if (_running) unawaited(notifier?.cancel());
    _ticker?.cancel();
    _running = false;
    _watch.stop();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(audio.dispose().catchError((Object _) {}));
    _disposed = true;
    super.dispose();
  }
}
