import 'package:flutter/services.dart';
import 'timing_audio_contract.dart';

TimingAudio createTimingAudio() => _NativeAudio();

class _NativeAudio extends TimingAudio {
  static const _channel = MethodChannel('setpad/timing');
  _NativeAudio() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'interrupted') onInterrupted?.call();
    });
  }
  @override
  Future<void> configure({required bool active, int? bpm, String? cue}) =>
      _channel.invokeMethod<void>('configure', {
        'active': active,
        'bpm': bpm,
        'cue': cue,
      });

  @override
  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    try {
      await configure(active: false);
    } on PlatformException {
      /* Already stopped. */
    } on MissingPluginException {
      /* No native audio in widget tests. */
    }
  }
}
