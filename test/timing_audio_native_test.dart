import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/timing_audio.dart';
import 'package:setpad/timing_audio_mux.dart';
import 'package:setpad/workout_timing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('setpad/timing');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  test('one platform audio for the app', () {
    expect(identical(createTimingAudio(), createTimingAudio()), isTrue);
  });

  test('a second editor coming and going leaves the first one\'s timer '
      'sounding and hearing interruptions', () async {
    final calls = <Map<Object?, Object?>>[];
    messenger.setMockMethodCallHandler(channel, (c) async {
      if (c.method == 'configure') calls.add(c.arguments as Map);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final mux = TimingAudioMux.shared;
    var now = Duration.zero;
    final a = WorkoutTimer(
      audio: mux.port('workout#a'),
      now: () => now,
      haptic: (_) {},
    );
    a.toggle(#a, const TimingSpec(bpm: 60));
    now = const Duration(seconds: 5);
    a.tick();
    await pumpEventQueue();

    // Another record's editor over this one: its ports, then gone.
    final b = WorkoutTimer(
      audio: mux.port('workout#b'),
      now: () => now,
      haptic: (_) {},
    );
    await mux.port('rest#b').dispose();
    b.dispose();
    await pumpEventQueue();
    expect(calls.last['active'], isTrue, reason: 'A still runs');

    await messenger.handlePlatformMessage(
      'setpad/timing',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('interrupted'),
      ),
      (_) {},
    );
    expect(a.running, isFalse, reason: 'a call pauses A');
    await messenger.handlePlatformMessage(
      'setpad/timing',
      const StandardMethodCodec().encodeMethodCall(const MethodCall('resumed')),
      (_) {},
    );
    expect(a.running, isTrue, reason: 'and the end of it resumes A');
    await pumpEventQueue();
    expect(calls.last['active'], isTrue);
    a.dispose();
    await pumpEventQueue();
    expect(calls.last['active'], isFalse);
  });
}
