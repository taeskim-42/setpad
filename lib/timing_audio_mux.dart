import 'dart:async';

import 'timing_audio.dart';

/// One real [TimingAudio] shared by the workout timer, the set rest and the
/// set stage (spec focus-stage-1.8 §4).
///
/// The native side has one `active`: keep the screen on, the keep-alive loop
/// and the audio session all follow it, so two owners sending their own would
/// switch each other off. Each owner gets a [port]; a port's configure only
/// changes that port's state and the mux sends the merge, in call order, on
/// one chain: active = any port active; bpm/phase = the 'workout' port's
/// while it is active; cue = the call's own.
class TimingAudioMux {
  TimingAudioMux(this.audio) {
    audio.onInterrupted = () {
      // The native side stopped on its own: what was sent no longer holds.
      _sent = null;
      _ports['workout']?.onInterrupted?.call();
    };
    audio.onResumed = () {
      _ports['workout']?.onResumed?.call();
      // An interruption stopped the keep-alive natively; whoever is still
      // active (a rest, the stage) gets it back.
      if (_ports.values.any((p) => p._active)) _send(null);
    };
  }

  /// The real audio. The mux owner disposes it with [dispose], last.
  final TimingAudio audio;
  final _ports = <String, _Port>{};
  Future<void> _chain = Future.value();
  ({bool active, int? bpm})? _sent;
  bool _disposed = false;

  /// The port named [name] ('workout', 'rest', 'stage'); the same one until
  /// it is disposed.
  TimingAudio port(String name) =>
      _ports.putIfAbsent(name, () => _Port(this, name));

  Future<void> _send(String? cue, {_Port? from}) {
    if (_disposed) return Future.value();
    final active = _ports.values.any((p) => p._active);
    final workout = _ports['workout'];
    final beat = workout != null && workout._active;
    final bpm = beat ? workout._bpm : null;
    final state = (active: active, bpm: bpm);
    // Another owner's call that changes nothing would only cut the workout's
    // speech or a cue still sounding (native: inactive without a cue stops
    // both). The workout's own calls always go through as before.
    if (cue == null && from?.name != 'workout' && state == _sent) {
      return Future.value();
    }
    _sent = state;
    final call = _chain.then(
      (_) => audio.configure(
        active: active,
        bpm: bpm,
        cue: cue,
        phase: beat ? workout._phase : null,
      ),
    );
    _chain = call.catchError((Object _) {});
    return call;
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
  _Port(this._mux, this.name);
  final TimingAudioMux _mux;
  final String name;
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
    _active = active;
    _bpm = bpm;
    _phase = phase;
    return _mux._send(cue, from: this);
  }

  @override
  Future<void> speak(String text, String locale, {double rate = 1.15}) =>
      _mux.audio.speak(text, locale, rate: rate);

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
