import 'dart:js_interop';
import 'timing_audio_contract.dart';

@JS('setpadTiming.configure')
external JSPromise<JSAny?> _configure(
  JSBoolean active,
  JSNumber bpm,
  JSString cue,
);

TimingAudio createTimingAudio() => _WebAudio();

class _WebAudio extends TimingAudio {
  @override
  Future<void> configure({required bool active, int? bpm, String? cue}) async {
    await _configure(active.toJS, (bpm ?? 0).toJS, (cue ?? '').toJS).toDart;
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
