import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/timing_audio.dart';
import 'package:setpad/timing_audio_mux.dart';
import 'package:setpad/workout_timing.dart';

/// Records what reaches the native side. [gate] holds each configure until
/// released, to see that calls still go out one after another.
class RealAudio extends TimingAudio {
  final calls = <String>[];
  int disposed = 0;
  Completer<void>? gate;

  @override
  Future<void> configure({
    required bool active,
    int? bpm,
    String? cue,
    double? phase,
  }) async {
    calls.add('${active ? 'on' : 'off'} bpm=$bpm cue=$cue');
    final g = gate;
    if (g != null) await g.future;
  }

  @override
  Future<void> speak(String text, String locale, {double rate = 1.15}) async =>
      calls.add('speak $text');

  @override
  Future<void> dispose() async => disposed++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RealAudio real;
  late TimingAudioMux mux;
  setUp(() {
    real = RealAudio();
    mux = TimingAudioMux(real);
  });

  test('one port going inactive does not switch off another', () async {
    final workout = mux.port('workout'), rest = mux.port('rest');
    await rest.configure(active: true);
    await workout.configure(active: true, bpm: 100, phase: 0.1);
    await workout.configure(active: false);
    expect(real.calls, [
      'on bpm=null cue=null',
      'on bpm=100 cue=null',
      'on bpm=null cue=null',
    ]);
    await workout.configure(active: true, bpm: 100);
    await rest.configure(active: false);
    // Nothing changed for the native side: not sent at all.
    expect(real.calls.last, 'on bpm=100 cue=null');
    expect(real.calls, hasLength(4));
    await workout.configure(active: false);
    expect(real.calls.last, 'off bpm=null cue=null');
  });

  test(
    'bpm and phase are the workout port\'s; the cue is the caller\'s',
    () async {
      final workout = mux.port('workout'), rest = mux.port('rest');
      await rest.configure(active: true, bpm: 180, cue: 'ready');
      expect(real.calls.last, 'on bpm=null cue=ready');
      await workout.configure(active: true, bpm: 90);
      await rest.configure(active: false, cue: 'complete');
      expect(real.calls.last, 'on bpm=90 cue=complete');
      await workout.configure(active: false, cue: 'complete');
      expect(real.calls.last, 'off bpm=null cue=complete');
    },
  );

  test(
    'the same port again until disposed; the stage keeps the screen on',
    () async {
      expect(identical(mux.port('stage'), mux.port('stage')), isTrue);
      await mux.port('stage').configure(active: true);
      await mux.port('rest').configure(active: false, cue: 'complete');
      expect(real.calls.last, 'on bpm=null cue=complete');
    },
  );

  test(
    'interruptions reach the workout port only; resume brings the keep-alive back',
    () async {
      final workout = mux.port('workout'), rest = mux.port('rest');
      final heard = <String>[];
      workout.onInterrupted = () => heard.add('workout interrupted');
      workout.onResumed = () => heard.add('workout resumed');
      rest.onInterrupted = () => heard.add('rest interrupted');
      rest.onResumed = () => heard.add('rest resumed');
      await rest.configure(active: true);
      real.onInterrupted!();
      real.onResumed!();
      await pumpEventQueue();
      expect(heard, ['workout interrupted', 'workout resumed']);
      expect(real.calls, ['on bpm=null cue=null', 'on bpm=null cue=null']);
      // Nobody active: resume sends nothing.
      await rest.configure(active: false);
      real.calls.clear();
      real.onResumed!();
      await pumpEventQueue();
      expect(real.calls, isEmpty);
    },
  );

  test(
    'a port\'s dispose goes inactive but leaves the real audio open',
    () async {
      final rest = mux.port('rest'), stage = mux.port('stage');
      await rest.configure(active: true);
      await stage.configure(active: true);
      await rest.dispose();
      expect(real.disposed, 0);
      await stage.dispose();
      expect(real.calls.last, 'off bpm=null cue=null');
      // A disposed port is silent; asking again gives a fresh one.
      real.calls.clear();
      await rest.configure(active: true);
      expect(real.calls, isEmpty);
      expect(identical(mux.port('rest'), rest), isFalse);
      await mux.port('rest').configure(active: true);
      expect(real.calls, ['on bpm=null cue=null']);
      await mux.dispose();
      expect(real.disposed, 1);
      expect(real.onInterrupted, isNull);
    },
  );

  test(
    'calls go out one at a time, in call order; speak and warmUp pass',
    () async {
      final workout = mux.port('workout'), rest = mux.port('rest');
      real.gate = Completer();
      final a = rest.configure(active: true, cue: 'ready');
      final b = workout.configure(active: true, bpm: 120);
      final c = rest.configure(active: false, cue: 'complete');
      await pumpEventQueue();
      expect(real.calls, ['on bpm=null cue=ready']);
      real.gate!.complete();
      await Future.wait([a, b, c]);
      expect(real.calls, [
        'on bpm=null cue=ready',
        'on bpm=120 cue=null',
        'on bpm=120 cue=complete',
      ]);
      await workout.speak('하나', 'ko');
      await workout.warmUp();
      expect(real.calls.last, 'speak 하나');
    },
  );

  test(
    'WorkoutTimer on a port: runs as before, its pause leaves the rest active',
    () async {
      var clock = Duration.zero;
      final timer = WorkoutTimer(
        audio: mux.port('workout'),
        now: () => clock,
        haptic: (_) {},
      );
      final rest = mux.port('rest');
      await rest.configure(active: true);
      timer.toggle(
        Object(),
        const TimingSpec(tabata: true, work: 20, rest: 10, rounds: 2),
      );
      expect(timer.running, isTrue);
      clock = const Duration(seconds: 3, milliseconds: 100);
      timer.tick();
      expect(timer.phase, TimingPhase.work);
      timer.pause();
      await pumpEventQueue();
      expect(real.calls.where((c) => c.startsWith('off')), isEmpty);
      expect(real.calls.where((c) => c.contains('cue=work')), hasLength(1));
      timer.resume();
      clock = const Duration(seconds: 63, milliseconds: 100);
      timer.tick();
      expect(timer.phase, TimingPhase.complete);
      await pumpEventQueue();
      // Its complete cue plays, the rest keeps the session on.
      expect(real.calls.last, 'on bpm=null cue=complete');
      timer.dispose();
      await pumpEventQueue();
      expect(real.disposed, 0);
      await rest.configure(active: false);
      expect(real.calls.last, 'off bpm=null cue=null');
    },
  );
}
