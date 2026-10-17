import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/boundary_notify.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/timing_audio.dart';
import 'package:setpad/workout_timing.dart';

import 'workout_timing_test.dart' show FakeAudio;

/// What the engine handed over, and what a schedule answers.
class FakeNotifier implements BoundaryNotifier {
  bool sounds = true;
  final scheduled = <List<Boundary>>[];
  final froms = <Duration>[];
  final prepared = <String>{};
  int cancels = 0;

  @override
  Future<void> prepare(Iterable<String> voices) async => prepared.addAll(voices);

  @override
  Future<bool> schedule(
    TimingSpec spec,
    List<Boundary> boundaries, {
    required Duration from,
    required DateTime now,
  }) async {
    scheduled.add(boundaries);
    froms.add(from);
    return sounds;
  }

  @override
  Future<void> cancel() async => cancels++;
}

/// The plugin calls of [LocalBoundaryNotifier], recorded.
class Recording extends LocalBoundaryNotifier {
  Recording() : super(title: (spec, b) => '${b.phase.name} ${b.round}');
  ({bool enabled, bool sound})? allowed = (enabled: true, sound: true);
  final added = <({int id, String title, DateTime at, String? sound})>[];
  final removed = <int>[];

  @override
  Future<({bool enabled, bool sound})?> permission() async => allowed;

  @override
  Future<void> add(int id, String title, DateTime at, String? sound) async =>
      added.add((id: id, title: title, at: at, sound: sound));

  @override
  Future<void> remove(int id) async => removed.add(id);

  @override
  Future<void> prepareSounds(Iterable<String> voices) async {}
}

String key(Boundary b) =>
    '${b.at.inMilliseconds} ${b.phase.name} ${b.round} '
    '${b.voice?.split('/').last.split('.').first}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const tabata = TimingSpec(tabata: true, work: 20, rest: 10, rounds: 3);

  group('runBoundaries', () {
    test('tabata: each work and rest start, the last round, the end', () {
      expect(runBoundaries(tabata).map(key), [
        '3000 work 1 round_1',
        '23000 rest 1 rest',
        '33000 work 2 round_2',
        '53000 rest 2 rest',
        '63000 work 3 last_round',
        '83000 complete 3 done',
      ]);
      // tail keeps the last rest; one round says "Go!".
      expect(
        runBoundaries(tabata.copyWith(tail: true)).map(key).skip(5),
        ['83000 rest 3 rest', '93000 complete 3 done'],
      );
      expect(runBoundaries(tabata.copyWith(rounds: 1)).map(key), [
        '3000 work 1 start',
        '23000 complete 1 done',
      ]);
    });

    test('counting aloud with a tempo: no work phrase, the boundary stays; '
        'voice cues off: no phrase at all', () {
      final bpm = tabata.copyWith(bpm: 60);
      expect(runBoundaries(bpm, countAloud: true).map(key).take(3), [
        '3000 work 1 null',
        '23000 rest 1 rest',
        '33000 work 2 null',
      ]);
      // Without a tempo there are no counts: the round is said.
      expect(runBoundaries(tabata, countAloud: true).first.voice, isNotNull);
      expect(
        runBoundaries(tabata, voiceCues: false).map((b) => b.voice).toSet(),
        {null},
      );
      expect(runBoundaries(tabata, sex: 'w').first.voice,
          'assets/voice/en/w/round_1.m4a');
    });

    test('metronome: the start; the end only with a goal', () {
      const metronome = TimingSpec(bpm: 60);
      expect(runBoundaries(metronome).map(key), ['3000 work 1 start']);
      expect(runBoundaries(metronome, from: const Duration(seconds: 5)),
          isEmpty);
      // 10 counts at 60 bpm: 3 + 9 + 0.5 + 0.05 s, as the engine's total.
      expect(runBoundaries(metronome, target: 10).map(key), [
        '3000 work 1 start',
        '12550 complete 1 done',
      ]);
      expect(runLength(metronome, 10), const Duration(milliseconds: 12550));
    });

    test('from where the run is (wall-clock catch-up included): a boundary '
        'under a second away is left to the engine', () {
      expect(
        runBoundaries(tabata, from: const Duration(seconds: 50)).map(key),
        [
          '53000 rest 2 rest',
          '63000 work 3 last_round',
          '83000 complete 3 done',
        ],
      );
      expect(
        runBoundaries(tabata, from: const Duration(milliseconds: 52500))
            .first
            .at,
        const Duration(seconds: 63),
      );
    });

    test('at most $maxBoundaryNotices, the earliest first', () {
      const long = TimingSpec(tabata: true, work: 5, rest: 5, rounds: 99);
      expect(runBoundaries(long).length, 99 + 98 + 1);
      final capped = runBoundaries(long, limit: maxBoundaryNotices);
      expect(capped.length, 40);
      expect(capped.first.at, const Duration(seconds: 3));
      expect(capped.last.at, const Duration(seconds: 3 + 19 * 10 + 5));
      // Round 31 on is said "Go!" (no recording), titled with its number.
      final l = lookupL(const Locale('ko'));
      final r31 = runBoundaries(long).firstWhere((b) => b.round == 31);
      expect(r31.voice, 'assets/voice/en/m/start.m4a');
      expect(boundaryTitle(l, long, r31), '라운드 31');
    });

    test('titles', () {
      final l = lookupL(const Locale('ko'));
      final titles = [
        for (final b in runBoundaries(tabata)) boundaryTitle(l, tabata, b),
      ];
      expect(titles, ['라운드 1', '휴식', '라운드 2', '휴식', '마지막 라운드', '운동 끝']);
      expect(
        boundaryTitle(l, const TimingSpec(bpm: 60),
            runBoundaries(const TimingSpec(bpm: 60)).single),
        '시작',
      );
    });
  });

  group('engine and notifications', () {
    ({WorkoutTimer timer, FakeAudio audio, FakeNotifier notifier,
        void Function(Duration) at}) make() {
      var now = Duration.zero;
      final audio = FakeAudio(), notifier = FakeNotifier();
      final timer = WorkoutTimer(audio: audio, now: () => now)
        ..notifier = notifier;
      return (
        timer: timer,
        audio: audio,
        notifier: notifier,
        at: (d) {
          now = d;
          timer.tick();
        },
      );
    }

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('a run starting prepares its phrases; away schedules once, back '
        'cancels before anything sounds', () async {
      final t = make();
      t.timer.toggle(Object(), tabata);
      expect(t.notifier.prepared, {
        for (final k in ['round_1', 'round_2', 'last_round', 'rest', 'done'])
          'assets/voice/en/m/$k.m4a',
      });
      t.at(const Duration(seconds: 10));
      // inactive alone (Control Center) is not away.
      t.timer.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(t.notifier.scheduled, isEmpty);
      t.timer.didChangeAppLifecycleState(AppLifecycleState.hidden);
      t.timer.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(t.notifier.scheduled.length, 1);
      expect(t.notifier.froms.single, const Duration(seconds: 10));
      expect(t.notifier.scheduled.single.first.at, const Duration(seconds: 23));
      await settle();
      // Awake past rest 1 into round 2 (the cue may sound, the covered
      // phrases do not), then back in front.
      final sent = t.audio.log.length;
      t.at(const Duration(seconds: 40));
      t.timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(t.notifier.cancels, 1);
      await settle();
      expect(t.timer.round, 2);
      expect(t.audio.log.skip(sent).where((e) => e.startsWith('voice:')),
          isEmpty);
      t.timer.dispose();
    });

    test('back in front after boundaries passed: nothing is played late, '
        'the run lands where the clock is', () async {
      var wall = DateTime(2026, 10, 17, 9);
      final audio = FakeAudio(), notifier = FakeNotifier();
      var now = Duration.zero;
      final timer = WorkoutTimer(
        audio: audio,
        now: () => now,
        wallNow: () => wall,
      )..notifier = notifier;
      timer.toggle(Object(), tabata);
      now = const Duration(seconds: 5);
      wall = wall.add(now);
      timer.tick();
      timer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await settle();
      final sent = audio.log.length;
      // Suspended 60 s: the monotonic clock did not move, the wall did.
      wall = wall.add(const Duration(seconds: 60));
      timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle();
      expect((timer.phase, timer.round), (TimingPhase.work, 3));
      expect(audio.log.skip(sent), isEmpty);
      // Ends while away: no end sound on the way back, onComplete still.
      var completed = 0;
      timer.onComplete = () => completed++;
      timer.didChangeAppLifecycleState(AppLifecycleState.paused);
      wall = wall.add(const Duration(seconds: 60));
      timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle();
      expect(timer.phase, TimingPhase.complete);
      expect(completed, 1);
      expect(audio.log.skip(sent), isEmpty);
      expect(audio.calls.last.active, isFalse);
      timer.dispose();
    });

    test('awake in the background: cues sound, the covered phrases do not',
        () async {
      final t = make();
      t.timer.toggle(Object(), tabata);
      t.at(const Duration(seconds: 10));
      t.timer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await settle();
      final sent = t.audio.log.length;
      for (var ms = 10000; ms <= 84000; ms += 50) {
        t.at(Duration(milliseconds: ms));
      }
      await settle();
      final heard = t.audio.log.skip(sent).toList();
      expect(heard.where((e) => e.startsWith('voice:')), isEmpty);
      expect(heard, containsAll(['rest', 'work', 'complete']));
      // The end's own notification is due as it ends: not cancelled.
      expect(t.notifier.cancels, 0);
      t.timer.dispose();
    });

    test('not allowed (or no sound): the engine says its phrases as before',
        () async {
      final t = make();
      t.notifier.sounds = false;
      t.timer.toggle(Object(), tabata);
      t.at(const Duration(seconds: 10));
      t.timer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await settle();
      for (var ms = 10000; ms <= 34000; ms += 50) {
        t.at(Duration(milliseconds: ms));
      }
      await settle();
      expect(t.audio.phrases, ['round_1', 'rest', 'round_2']);
      t.timer.dispose();
    });

    test('pause, reset and a new run cancel; paused or finished away '
        'schedules nothing', () async {
      final t = make();
      t.timer.toggle(Object(), tabata);
      t.at(const Duration(seconds: 10));
      t.timer.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(t.notifier.scheduled.length, 1);
      // An interruption (a call) pauses it while away.
      t.audio.onInterrupted!();
      expect(t.notifier.cancels, 1);
      // The call ends: it runs on, and is covered again.
      t.audio.onResumed!();
      expect(t.notifier.scheduled.length, 2);
      t.timer.reset();
      expect(t.notifier.cancels, 2);
      t.timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      t.timer.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(t.notifier.scheduled.length, 2);
      t.timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      // In front nothing is scheduled; a pause there cancels nothing.
      t.timer.toggle(Object(), tabata);
      t.timer.pause();
      expect(t.notifier.cancels, 2);
      t.timer.dispose();
    });

    test('a shared run put back in place while away is covered again',
        () async {
      final t = make();
      final owner = Object();
      t.timer.follow(owner, tabata, const Duration(seconds: 10));
      t.timer.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(t.notifier.froms, [const Duration(seconds: 10)]);
      t.timer.follow(owner, tabata, const Duration(seconds: 12));
      expect(t.notifier.cancels, 1);
      expect(t.notifier.froms.last, const Duration(seconds: 12));
      t.timer.dispose();
    });
  });

  group('LocalBoundaryNotifier', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);
    final now = DateTime.utc(2026, 10, 17, 9);
    final list = runBoundaries(tabata, from: const Duration(seconds: 10));

    test('Android and web: nothing (the foreground service sounds)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final n = Recording();
      expect(
        await n.schedule(tabata, list,
            from: const Duration(seconds: 10), now: now),
        isFalse,
      );
      await n.cancel();
      expect(n.added, isEmpty);
      expect(n.removed, isEmpty);
    });

    test('iOS: one per boundary at its wall time, default sound until its '
        'recording is ready; cancel drops the whole range', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final n = Recording();
      const channel = MethodChannel('setpad/timing');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'notificationSounds');
        return {'assets/voice/en/m/rest.m4a': 'setpad-101-rest.caf'};
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));
      await NotificationSounds.prepare(['assets/voice/en/m/rest.m4a']);
      final sounds = await n.schedule(tabata, list,
          from: const Duration(seconds: 10), now: now);
      expect(sounds, isTrue);
      expect(n.added.map((a) => (a.id, a.at, a.sound)), [
        (LocalBoundaryNotifier.firstId, now.add(const Duration(seconds: 13)),
            'setpad-101-rest.caf'),
        (LocalBoundaryNotifier.firstId + 1,
            now.add(const Duration(seconds: 23)), null),
        (LocalBoundaryNotifier.firstId + 2,
            now.add(const Duration(seconds: 43)), 'setpad-101-rest.caf'),
        (LocalBoundaryNotifier.firstId + 3,
            now.add(const Duration(seconds: 53)), null),
        (LocalBoundaryNotifier.firstId + 4,
            now.add(const Duration(seconds: 73)), null),
      ]);
      expect(n.added.first.title, 'rest 1');
      await n.cancel();
      expect(n.removed, [
        for (var i = 0; i < maxBoundaryNotices; i++)
          LocalBoundaryNotifier.firstId + i,
      ]);
      // Clear of the set rest's id and inside a 32-bit int.
      expect(LocalBoundaryNotifier.firstId + maxBoundaryNotices,
          lessThan(2147480000));
    });

    test('iOS not allowed: nothing; allowed without sound: shown, but the '
        'app keeps its phrases', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final n = Recording()..allowed = (enabled: false, sound: false);
      expect(
        await n.schedule(tabata, list,
            from: const Duration(seconds: 10), now: now),
        isFalse,
      );
      expect(n.added, isEmpty);
      n.allowed = null; // plugin not started
      expect(
        await n.schedule(tabata, list,
            from: const Duration(seconds: 10), now: now),
        isFalse,
      );
      n.allowed = (enabled: true, sound: false);
      expect(
        await n.schedule(tabata, list,
            from: const Duration(seconds: 10), now: now),
        isFalse,
      );
      expect(n.added.length, list.length);
    });
  });

  group('native keepAlive', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      test('sent on ${platform.name}', () async {
        debugDefaultTargetPlatformOverride = platform;
        final calls = <MethodCall>[];
        const channel = MethodChannel('setpad/timing');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
        addTearDown(() => TestDefaultBinaryMessengerBinding
            .instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null));
        await createTimingAudio().keepAlive(true, linger: true);
        expect(calls.map((c) => c.method), ['keepAlive']);
        expect(calls.single.arguments, {'on': true, 'linger': true});
      });
    }
  });
}
