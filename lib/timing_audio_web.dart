import 'dart:js_interop';
import 'timing_audio_contract.dart';

@JS('setpadTiming.configure')
external JSPromise<JSAny?> _configure(
  JSBoolean active,
  JSNumber bpm,
  JSString cue,
  JSNumber? phase,
);

@JS('setpadTiming.voice')
external void _voice(JSString asset, JSBoolean onBeat);

TimingAudio createTimingAudio() => _WebAudio();

class _WebAudio extends TimingAudio {
  @override
  Future<void> configure({
    required bool active,
    int? bpm,
    String? cue,
    double? phase,
  }) async {
    await _configure(
      active.toJS,
      (bpm ?? 0).toJS,
      (cue ?? '').toJS,
      phase?.toJS,
    ).toDart;
  }

  @override
  Future<void> playVoice(String asset, {bool onBeat = false}) async {
    try {
      _voice(asset.toJS, onBeat.toJS);
    } catch (_) {
      /* 브라우저가 소리를 막아 두었다. 박자는 계속 간다. */
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await configure(active: false);
    } catch (_) {
      /* Already stopped. */
    }
  }
}
