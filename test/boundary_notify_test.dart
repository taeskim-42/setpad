import 'dart:math' as math;

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

  /// How many the system takes (its limit); null: all.
  int? room;
  final scheduled = <List<Boundary>>[];
  final froms = <Duration>[];
  final prepared = <String>{};
  int cancels = 0;

  @override
  Future<void> prepare(Iterable<String> voices) async => prepared.addAll(voices);

  @override
  Future<int> schedule(
    TimingSpec spec,
    List<Boundary> boundaries, {
    required Duration from,
    required DateTime now,
  }) async {
    scheduled.add(boundaries);
    froms.add(from);
    return sounds ? math.min(boundaries.length, room ?? boundaries.length) : 0;
  }

  @override
  Future<void> cancel() async => cancels++;
}

/// The plugin calls of [LocalBoundaryNotifier], recorded.
class Recording extends LocalBoundaryNotifier {
  Recording() : super(title: (spec, b) => '${b.phase.name} ${b.round}');
  ({bool enabled, bool sound})? allowed = (enabled: true, sound: true);

  /// Requests the system holds already (trainer reports, ...).
  int others = 0;
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
  Future<int> held() async => others + added.length - removed.length;

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
      // Back in front: what was delivered comes off the lock screen, as
      // after a suspension.
      t.timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(t.notifier.cancels, 1);
      t.timer.dispose();
    });

    test('the system takes only some: the engine says the phrases past them',
        () async {
      final t = make();
      t.notifier.room = 1;
      t.timer.toggle(Object(), tabata);
      t.at(const Duration(seconds: 10));
      t.timer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await settle();
      final sent = t.audio.log.length;
      for (var ms = 10000; ms <= 40000; ms += 50) {
        t.at(Duration(milliseconds: ms));
      }
      await settle();
      final said = t.audio.log.skip(sent).where((e) => e.startsWith('voice:'));
      // Rest 1 (23 s) is the notice's; round 2 (33 s) is the app's.
      expect(said.where((e) => e == 'voice:rest'), isEmpty);
      expect(said.where((e) => e == 'voice:round_2'), hasLength(1));
      t.timer.dispose();
    });

    for (final c in [
      (
        'tabata with a tempo: let go in a rest, back in a work',
        const TimingSpec(tabata: true, work: 20, rest: 10, rounds: 3, bpm: 60),
        25,
      ),
      ('metronome: let go in the count-in, back in the work',
          const TimingSpec(bpm: 60), 1),
    ]) {
      test('${c.$1}: the clicks go on', () async {
        var wall = DateTime(2026, 10, 17, 9);
        var now = Duration.zero;
        final audio = FakeAudio();
        final timer = WorkoutTimer(
          audio: audio,
          now: () => now,
          wallNow: () => wall,
        )..notifier = FakeNotifier();
        timer.toggle(Object(), c.$2);
        for (var ms = 0; ms <= c.$3 * 1000; ms += 50) {
          now = Duration(milliseconds: ms);
          wall = DateTime(2026, 10, 17, 9).add(now);
          timer.tick();
        }
        timer.didChangeAppLifecycleState(AppLifecycleState.paused);
        await settle();
        expect(audio.calls.last.bpm, isNull);
        // Suspended 10 s: the wall moved, the monotonic clock did not.
        wall = wall.add(const Duration(seconds: 10));
        timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
        for (var ms = 50; ms <= 2000; ms += 50) {
          now = Duration(milliseconds: c.$3 * 1000 + ms);
          wall = wall.add(const Duration(milliseconds: 50));
          timer.tick();
        }
        await settle();
        expect(timer.phase, TimingPhase.work);
        expect(audio.calls.last.bpm, 60);
        expect(audio.calls.last.cue, isNull);
        timer.dispose();
      });
    }

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
        0,
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
      expect(sounds, 5);
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
      expect(n.removed, [for (final a in n.added) a.id]);
      // Clear of the set rest's id and inside a 32-bit int.
      expect(LocalBoundaryNotifier.firstId + LocalBoundaryNotifier.idCount,
          lessThan(2147480000));
    });

    test('iOS not allowed: nothing; allowed without sound: shown, but the '
        'app keeps its phrases', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final n = Recording()..allowed = (enabled: false, sound: false);
      expect(
        await n.schedule(tabata, list,
            from: const Duration(seconds: 10), now: now),
        0,
      );
      expect(n.added, isEmpty);
      n.allowed = null; // plugin not started
      expect(
        await n.schedule(tabata, list,
            from: const Duration(seconds: 10), now: now),
        0,
      );
      n.allowed = (enabled: true, sound: false);
      expect(
        await n.schedule(tabata, list,
            from: const Duration(seconds: 10), now: now),
        0,
      );
      expect(n.added.length, list.length);
      await n.cancel();
    });

    test('iOS: under the 64 the system holds, one left for the set rest',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      const long = TimingSpec(tabata: true, work: 5, rest: 5, rounds: 99);
      final many = runBoundaries(long, limit: maxBoundaryNotices);
      final n = Recording()..others = 30;
      expect(await n.schedule(long, many, from: Duration.zero, now: now), 33);
      expect(n.added.length, 33);
      await n.cancel();
      n.others = 63;
      expect(await n.schedule(long, many, from: Duration.zero, now: now), 0);
      expect(n.added.length, 33);
    });

    test('iOS: two runs away at once hold their own ids; a cancel drops '
        'only its own; launch clears the whole range', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final a = Recording(), b = Recording();
      await a.schedule(tabata, list,
          from: const Duration(seconds: 10), now: now);
      await b.schedule(tabata, list,
          from: const Duration(seconds: 10), now: now);
      final ids = {...a.added.map((x) => x.id), ...b.added.map((x) => x.id)};
      expect(ids.length, list.length * 2);
      await a.cancel();
      expect(a.removed, [for (final x in a.added) x.id]);
      // a's ids are free again; b keeps its own.
      await a.schedule(tabata, list,
          from: const Duration(seconds: 10), now: now);
      expect(a.added.skip(list.length).map((x) => x.id),
          a.added.take(list.length).map((x) => x.id));
      await a.cancel();
      await b.cancel();
      final fresh = Recording();
      await fresh.clearRange();
      expect(fresh.removed, [
        for (var i = 0; i < LocalBoundaryNotifier.idCount; i++)
          LocalBoundaryNotifier.firstId + i,
      ]);
    });

    test('iOS: a fraction of a second rounds up (the trigger keeps whole '
        'seconds): never early', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final n = Recording();
      await n.schedule(tabata, list,
          from: const Duration(seconds: 10, milliseconds: 400), now: now);
      // Rest 1 at 23 s is 12.6 s away: 13 s, not 12.
      expect(n.added.first.at, now.add(const Duration(seconds: 13)));
      await n.cancel();
      expect(wholeSecondUp(now), now);
      expect(wholeSecondUp(now.add(const Duration(microseconds: 1))),
          now.add(const Duration(seconds: 1)));
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
