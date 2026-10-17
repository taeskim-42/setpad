import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/rest_timer.dart';
import 'package:setpad/timing_audio.dart';
import 'package:setpad/workout_timing.dart';

class FakeAudio extends TimingAudio {
  final calls = <String>[];
  int disposed = 0;
  @override
  Future<void> configure({
    required bool active,
    int? bpm,
    String? cue,
    double? phase,
  }) async =>
      calls.add('${active ? 'on' : 'off'}${cue == null ? '' : ' $cue'}');

  /// Recorded words asked for, each with the configure calls made before it.
  final voices = <({String asset, bool onBeat, int after})>[];
  @override
  Future<void> playVoice(String asset, {bool onBeat = false}) async =>
      voices.add((asset: asset, onBeat: onBeat, after: calls.length));

  @override
  Future<void> dispose() async => disposed++;
}

class FakeNotifier implements RestNotifier {
  final log = <String>[];
  @override
  Future<void> schedule(DateTime at, String title, String body) async =>
      log.add('schedule ${at.toIso8601String()} $title / $body');

  @override
  Future<void> cancel() async => log.add('cancel');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAudio audio;
  late FakeNotifier notifier;
  late List<TimerHaptic> buzz;
  var clock = Duration.zero;
  DateTime? wall;
  var muted = false;
  late RestTimer rest;

  RestTimer make() => RestTimer(
    audio: audio,
    now: () => clock,
    wallNow: wall == null ? null : () => wall!,
    haptic: buzz.add,
    muted: () => muted,
    notifier: notifier,
  );

  void at(int ms) {
    clock = Duration(milliseconds: ms);
    rest.tick();
  }

  setUp(() {
    audio = FakeAudio();
    notifier = FakeNotifier();
    buzz = [];
    clock = Duration.zero;
    wall = null;
    muted = false;
    rest = make();
  });
  tearDown(() => rest.dispose());

  test('3·2·1 ready cues, then active:false + complete in one call', () async {
    var done = 0;
    rest.onDone = () => done++;
    final owner = Object();
    rest.start(owner, const Duration(seconds: 10));
    expect(rest.running, isTrue);
    expect(rest.owner, same(owner));
    expect(rest.level, 1);
    at(5000);
    expect(rest.remaining, const Duration(seconds: 5));
    expect(rest.level, 0.5);
    for (final ms in [6500, 7000, 7100, 8000, 9000]) {
      at(ms);
    }
    expect(audio.calls, ['on', 'on ready', 'on ready', 'on ready']);
    expect(buzz, [TimerHaptic.tick, TimerHaptic.tick, TimerHaptic.tick]);
    at(10000);
    await pumpEventQueue();
    expect(audio.calls.last, 'off complete');
    expect(audio.calls, hasLength(5));
    expect(buzz.last, TimerHaptic.success); // heavy twice, 150 ms
    expect(rest.running, isFalse);
    expect(rest.remaining, Duration.zero);
    expect(rest.level, 0);
    expect(done, 1);
    at(11000);
    expect(done, 1);
  });

  test('muted: active only, no cue and no haptics', () async {
    muted = true;
    rest.start(Object(), const Duration(seconds: 4));
    for (final ms in [1000, 2000, 3000, 4000]) {
      at(ms);
    }
    await pumpEventQueue();
    expect(audio.calls, ['on', 'off']);
    expect(buzz, isEmpty);
    rest.haptics = false;
    muted = false;
    rest.start(Object(), const Duration(seconds: 2));
    at(5000);
    expect(audio.calls.last, 'on ready');
    expect(buzz, isEmpty);
  });

  test('±15: at least 5 s left, at most 10 min in all; minus never adds', () {
    rest.start(Object(), const Duration(seconds: 30));
    at(10000);
    rest.add(const Duration(seconds: 15));
    expect(rest.length, const Duration(seconds: 45));
    expect(rest.remaining, const Duration(seconds: 35));
    rest.add(const Duration(seconds: -15));
    rest.add(const Duration(seconds: -15));
    rest.add(const Duration(seconds: -15));
    expect(rest.remaining, RestTimer.minLeft);
    at(13000);
    rest.add(const Duration(seconds: -15));
    expect(rest.remaining, const Duration(seconds: 2)); // not back up to 5
    rest.start(Object(), const Duration(minutes: 9, seconds: 50));
    rest.add(const Duration(seconds: 15));
    expect(rest.length, RestTimer.maxLength);
    rest.start(Object(), const Duration(minutes: 30));
    expect(rest.length, RestTimer.maxLength);
    rest.stop();
    rest.add(const Duration(seconds: 15));
    expect(rest.length, RestTimer.maxLength);
  });

  test('a plus after the countdown began counts down again from 3', () {
    rest.start(Object(), const Duration(seconds: 10));
    at(7500); // 3 left
    rest.add(const Duration(seconds: 15));
    at(8000);
    expect(audio.calls.where((c) => c == 'on ready'), hasLength(1));
    at(22000); // 3 left again
    expect(audio.calls.where((c) => c == 'on ready'), hasLength(2));
  });

  test('skip: onDone, no sound; stop: neither', () async {
    var done = 0;
    rest.onDone = () => done++;
    rest.start(Object(), const Duration(seconds: 60));
    rest.skip();
    expect(done, 1);
    expect(rest.running, isFalse);
    rest.start(Object(), const Duration(seconds: 60));
    rest.stop();
    rest.stop();
    rest.skip();
    expect(done, 1);
    await pumpEventQueue();
    expect(audio.calls, ['on', 'off', 'on', 'off']);
    expect(buzz, isEmpty);
  });

  test('the wall clock puts back the time the device slept', () {
    wall = DateTime(2026, 10, 17, 9);
    rest.dispose();
    rest = make();
    rest.start(Object(), const Duration(seconds: 90));
    // Asleep 40 s: the monotonic clock moved 1 s.
    clock = const Duration(seconds: 1);
    wall = wall!.add(const Duration(seconds: 41));
    rest.tick();
    expect(rest.remaining, const Duration(seconds: 49));
    // Gaps under a second add up instead of being dropped one by one.
    for (var i = 0; i < 4; i++) {
      clock += const Duration(milliseconds: 100);
      wall = wall!.add(const Duration(milliseconds: 400));
      rest.tick();
    }
    expect(rest.remaining, const Duration(milliseconds: 47400));
    // Over an hour is not sleep (the clock was set): dropped.
    clock += const Duration(seconds: 1);
    wall = wall!.add(const Duration(hours: 2));
    rest.tick();
    expect(rest.remaining, const Duration(milliseconds: 46400));
    expect(rest.running, isTrue);
  });

  test('the background does not stop it', () {
    rest.start(Object(), const Duration(seconds: 10));
    for (final s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
    ]) {
      rest.didChangeAppLifecycleState(s);
    }
    at(4000);
    expect(rest.running, isTrue);
    expect(rest.remaining, const Duration(seconds: 6));
  });

  test(
    'notice: scheduled when the app goes away, cancelled on the way back',
    () {
      wall = DateTime.utc(2026, 10, 17, 9);
      rest.dispose();
      rest = make();
      rest.notice = () => (title: '휴식 끝', body: '다음 · 4세트');
      // Away with no rest: nothing is scheduled.
      rest.didChangeAppLifecycleState(AppLifecycleState.paused);
      rest.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(notifier.log.where((e) => e.startsWith('schedule')), isEmpty);
      notifier.log.clear();

      rest.start(Object(), const Duration(seconds: 90));
      expect(notifier.log, ['cancel']); // start drops an old one
      notifier.log.clear();
      // hidden then paused (iOS sends both): one notice at the end time.
      rest.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(notifier.log, isEmpty);
      rest.didChangeAppLifecycleState(AppLifecycleState.hidden);
      rest.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(notifier.log, [
        'schedule 2026-10-17T09:01:30.000Z 휴식 끝 / 다음 · 4세트',
      ]);
      // ±15 while away (another device action): moved to the new end.
      rest.add(const Duration(seconds: 15));
      expect(notifier.log.skip(1), [
        'cancel',
        'schedule 2026-10-17T09:01:45.000Z 휴식 끝 / 다음 · 4세트',
      ]);
      notifier.log.clear();
      rest.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(notifier.log, ['cancel']);
      // In front: ±15 and a new start only cancel.
      notifier.log.clear();
      rest.add(const Duration(seconds: 15));
      rest.start(Object(), const Duration(seconds: 60));
      expect(notifier.log, ['cancel', 'cancel']);
      notifier.log.clear();
      rest.skip();
      expect(notifier.log, ['cancel']);
      notifier.log.clear();
      rest.start(Object(), const Duration(seconds: 60));
      rest.stop();
      expect(notifier.log, ['cancel', 'cancel']);
    },
  );

  test(
    'natural end while away leaves the notice to ring; no text, no notice',
    () {
      wall = DateTime.utc(2026, 10, 17, 9);
      rest.dispose();
      rest = make();
      rest.start(Object(), const Duration(seconds: 5));
      rest.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(notifier.log, ['cancel']); // no notice text set
      rest.notice = () => (title: 't', body: 'b');
      rest.didChangeAppLifecycleState(AppLifecycleState.resumed);
      rest.didChangeAppLifecycleState(AppLifecycleState.paused);
      notifier.log.clear();
      clock = const Duration(seconds: 5);
      wall = wall!.add(const Duration(seconds: 5));
      rest.tick();
      expect(rest.running, isFalse);
      expect(notifier.log, isEmpty);
    },
  );

  group('recorded words', () {
    String m(String key) => 'assets/voice/en/m/$key.m4a';

    test('"Ten seconds!" with 10 s left of a 30 s rest, "Go!" after the end '
        'sound; no system speech', () async {
      rest.start(Object(), const Duration(seconds: 30));
      for (var ms = 50; ms <= 30000; ms += 50) {
        at(ms);
      }
      await pumpEventQueue();
      expect(audio.voices, [
        (asset: m('ten_left'), onBeat: false, after: 1),
        (asset: m('start'), onBeat: false, after: 5),
      ]);
      expect(
        audio.calls[4],
        'off complete',
        reason: '"Go!" after the end sound',
      );
      for (final v in audio.voices) {
        expect(File(v.asset).existsSync(), isTrue, reason: v.asset);
      }
    });

    test(
      'a rest under 30 s has no "Ten seconds!"; skip and stop say nothing',
      () async {
        rest.start(Object(), const Duration(seconds: 29));
        at(19000);
        rest.skip();
        rest.start(Object(), const Duration(seconds: 60));
        rest.stop();
        await pumpEventQueue();
        expect(audio.voices, isEmpty);
      },
    );

    test('muted (the workout timer runs) or cues off: no words; the voice '
        'is the setting\'s', () async {
      muted = true;
      rest.start(Object(), const Duration(seconds: 30));
      at(20000);
      at(30000);
      muted = false;
      rest.voiceCues = false;
      rest.start(Object(), const Duration(seconds: 30));
      at(50000);
      at(60000);
      await pumpEventQueue();
      expect(audio.voices, isEmpty);
      rest
        ..voiceCues = true
        ..voice = 'w'
        ..start(Object(), const Duration(seconds: 2));
      at(62000);
      await pumpEventQueue();
      expect(audio.voices.single.asset, 'assets/voice/en/w/start.m4a');
    });
  });

  test('dispose cancels a running rest and lets go of its port', () async {
    final other = make();
    other.start(Object(), const Duration(seconds: 30));
    notifier.log.clear();
    other.dispose();
    await pumpEventQueue();
    expect(notifier.log, ['cancel']);
    expect(audio.disposed, 1);
  });
}
