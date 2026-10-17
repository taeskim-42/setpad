import 'dart:async';

import 'timing_audio.dart';

/// One real [TimingAudio] shared by the workout timer, the set rest and the
/// set stage (spec focus-stage-1.8 §4) — of every editor open: [shared].
///
/// The native side has one `active`: keep the screen on, the keep-alive loop
/// and the audio session all follow it, so two owners sending their own would
/// switch each other off. Each owner gets a [port]; a port's configure only
/// changes that port's state and the mux sends the merge, in call order, on
/// one chain: active = any port active; bpm/phase = the leading active
/// workout port's; cue = the call's own; keepAlive = any port but the stage
/// active (the stage alone sounds nothing). Recorded words go on the same chain.
class TimingAudioMux {
  TimingAudioMux(this.audio) {
    audio.onInterrupted = () {
      // The native side stopped on its own: what was sent no longer holds,
      // and nothing turns it back on until the interruption is over.
      _sent = null;
      _kept = null;
      _interrupted = true;
      for (final p in _workouts) {
        p.onInterrupted?.call();
      }
    };
    audio.onResumed = () {
      _interrupted = false;
      for (final p in _workouts) {
        p.onResumed?.call();
      }
      // An interruption stopped the keep-alive natively; whoever is still
      // active (a rest, the stage) gets it back.
      if (_ports.values.any((p) => p._active)) _send(null);
    };
  }

  /// The app's one mux over the platform audio. Every editor takes its own
  /// ports from it, so two editors (a record over another, the proxy editor)
  /// never take the native channel from each other. Never disposed: the
  /// ports are.
  static final shared = TimingAudioMux(createTimingAudio());

  /// The real audio. The mux owner disposes it with [dispose], last.
  final TimingAudio audio;
  final _ports = <String, _Port>{};
  Future<void> _chain = Future.value();
  ({bool active, int? bpm})? _sent;

  /// The last keepAlive sent; null when unknown (sends again).
  bool? _kept;
  bool _disposed = false;

  /// A call or an interruption began: the native side stays off until it
  /// ends or someone turns a port on (or plays a cue).
  bool _interrupted = false;

  /// The workout port whose beat sounds while two are active.
  _Port? _lead;

  /// The port named [name]: its kind ('workout', 'rest', 'stage'), then
  /// optionally '#' and the owner (`workout#2`) when several owners share
  /// the mux. The same one until it is disposed.
  TimingAudio port(String name) =>
      _ports.putIfAbsent(name, () => _Port(this, name));

  Iterable<_Port> get _workouts => [..._ports.values.where((p) => p._workout)];

  Future<void> _send(String? cue, {_Port? from, bool turnedOn = false}) {
    if (_disposed) return Future.value();
    if (_interrupted) {
      // Only someone starting again, or a cue, ends it before the system
      // does: a pause during a call must not switch the session back on.
      if (cue == null && !turnedOn) return Future.value();
      _interrupted = false;
    }
    if (from != null && from._workout && from._active) _lead = from;
    final active = _ports.values.any((p) => p._active);
    final lead = _lead;
    final workout = lead != null && lead._active && !lead._closed
        ? lead
        : _workouts.where((p) => p._active).firstOrNull;
    final bpm = workout?._bpm;
    final state = (active: active, bpm: bpm);
    // Another owner's call that changes nothing would only cut the workout's
    // speech or a cue still sounding (native: inactive without a cue stops
    // both). The workout's own calls always go through as before.
    final keep = _ports.values.any((p) => p._active && !p._stage);
    if (cue == null && from?._workout != true && state == _sent) {
      // A rest ending quietly under the open stage: same state, but the
      // keep-alive goes.
      _keepAlive(keep, linger: false);
      return Future.value();
    }
    _sent = state;
    final call = _chain.then(
      (_) => audio.configure(
        active: active,
        bpm: bpm,
        cue: cue,
        phase: workout?._phase,
      ),
    );
    // A failed call stopped the native sound (iOS: stop(); Android keeps its
    // workout service): the next call sends the merge again instead of
    // taking it as already there.
    _chain = call.catchError((Object _) {
      _sent = null;
      _kept = null;
    });
    _keepAlive(keep, linger: cue != null);
    return call;
  }

  void _keepAlive(bool on, {required bool linger}) {
    if (on == _kept) return;
    _kept = on;
    _chain = _chain
        .then((_) => audio.keepAlive(on, linger: linger))
        .catchError((Object _) => _kept = null);
  }

  /// Closes the real audio after everything already sent.
  Future<void> dispose() {
    if (_disposed) return _chain;
    _disposed = true;
    audio.onInterrupted = null;
    audio.onResumed = null;
    return _chain = _chain.then((_) => audio.dispose());
  }
}

class _Port extends TimingAudio {
  _Port(this._mux, this.name)
    : _workout = name.split('#').first == 'workout',
      _stage = name.split('#').first == 'stage';
  final TimingAudioMux _mux;
  final String name;

  /// Interruptions reach it and its beat is the one sent.
  final bool _workout;

  /// Keeps the screen on only: no keep-alive for it alone.
  final bool _stage;
  bool _active = false, _closed = false;
  int? _bpm;
  double? _phase;

  @override
  Future<void> warmUp() => _mux.audio.warmUp();

  @override
  Future<void> configure({
    required bool active,
    int? bpm,
    String? cue,
    double? phase,
  }) {
    if (_closed) return Future.value();
    final turnedOn = active && !_active;
    _active = active;
    _bpm = bpm;
    _phase = phase;
    return _mux._send(cue, from: this, turnedOn: turnedOn);
  }

  /// After everything already sent: the word comes after the cue the same
  /// owner just asked for (a rest's end sound, then "Go!").
  @override
  Future<void> playVoice(String asset, {bool onBeat = false}) {
    if (_closed || _mux._disposed) return Future.value();
    final call = _mux._chain.then(
      (_) => _mux.audio.playVoice(asset, onBeat: onBeat),
    );
    _mux._chain = call.catchError((Object _) {});
    return call;
  }

  /// Inactive and gone; the real audio stays open. Later calls do nothing.
  @override
  Future<void> dispose() {
    if (_closed) return Future.value();
    _closed = true;
    _active = false;
    if (identical(_mux._ports[name], this)) _mux._ports.remove(name);
    return _mux._send(null, from: this);
  }
}
