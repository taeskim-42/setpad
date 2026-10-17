import 'package:flutter/services.dart';
import 'timing_audio_contract.dart';

/// The platform audio: one for the app, since the native side has one
/// channel and one handler. Share it through `TimingAudioMux.shared`.
TimingAudio createTimingAudio() => _NativeAudio._one;

class _NativeAudio extends TimingAudio {
  static const _channel = MethodChannel('setpad/timing');
  static final _one = _NativeAudio._();
  _NativeAudio._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'interrupted') onInterrupted?.call();
      if (call.method == 'resumed') onResumed?.call();
    });
  }

  @override
  Future<void> warmUp() async {
    try {
      await _channel.invokeMethod<void>('warmUp');
    } on MissingPluginException {
      /* Older native side or widget tests: nothing to warm up. */
    }
  }

  @override
  Future<void> configure({
    required bool active,
    int? bpm,
    String? cue,
    double? phase,
  }) => _channel.invokeMethod<void>('configure', {
    'active': active,
    'bpm': bpm,
    'cue': cue,
    'phase': phase,
  });

  @override
  Future<void> playVoice(String asset, {bool onBeat = false}) =>
      _channel.invokeMethod<void>('voice', {'asset': asset, 'onBeat': onBeat});

  /// Goes quiet. The handler stays: this is the app's only instance, and a
  /// newer owner may already listen through it.
  @override
  Future<void> dispose() async {
    try {
      await configure(active: false);
    } on PlatformException {
      /* Already stopped. */
    } on MissingPluginException {
      /* No native audio in widget tests. */
    }
  }
}
