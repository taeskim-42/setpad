import 'dart:js_interop';
import 'timing_audio_contract.dart';

@JS('setpadTiming.configure')
external JSPromise<JSAny?> _configure(
  JSBoolean active,
  JSNumber bpm,
  JSString cue,
);

@JS('setpadTiming.speak')
external void _speak(JSString text, JSString locale);

TimingAudio createTimingAudio() => _WebAudio();

class _WebAudio extends TimingAudio {
  @override
  Future<void> configure({required bool active, int? bpm, String? cue}) async {
    await _configure(active.toJS, (bpm ?? 0).toJS, (cue ?? '').toJS).toDart;
  }

  @override
  Future<void> speak(String text, String locale, {double rate = 1.15}) async {
    try {
      _speak(text.toJS, locale.toJS);
    } catch (_) {
      /* 브라우저가 음성 합성을 막아 두었다. 박자는 계속 간다. */
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
