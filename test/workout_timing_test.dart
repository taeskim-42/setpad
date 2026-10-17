import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/workout_timing.dart';
import 'package:setpad/timing_audio.dart';
import 'package:setpad/notes.dart';

class FakeAudio extends TimingAudio {
  final events = <String>[];
  final calls = <({bool active, int? bpm, String? cue})>[];
  final phases = <double?>[];
  @override
  Future<void> configure({
    required bool active,
    int? bpm,
    String? cue,
    double? phase,
  }) async {
    events.add(active ? "configure" : "stop");
    calls.add((active: active, bpm: bpm, cue: cue));
    phases.add(phase);
  }

  final spoken = <String>[];
  @override
  Future<void> speak(String text, String locale, {double rate = 1.15}) async {
    events.add('speak');
    spoken.add(text);
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('timing names accept tempo, default Tabata and explicit intervals', () {
    for (final name in ['푸시업 120bpm', '푸시업 BPM 120', '120 BPM']) {
      expect(TimingSpec.parse(name)!.bpm, 120);
    }
    expect(TimingSpec.parse('메트로놈 bpm')!.bpm, 120);
    expect(TimingSpec.parse('버피 타바타'), const TimingSpec(tabata: true));
    expect(
      TimingSpec.parse('tabata 30/15 x6 100bpm'),
      const TimingSpec(tabata: true, bpm: 100, work: 30, rest: 15, rounds: 6),
    );
    expect(TimingSpec.parse('타바타 30초/15초 6라운드')!.rounds, 6);
    expect(TimingSpec.parse('벤치프레스 80kg'), isNull);
    expect(TimingSpec.parse('abpmachine'), isNull);
    for (final name in [
      '500bpm',
      '0bpm',
      '-20bpm',
      '120.5bpm',
      '타바타 0/10',
      '타바타 20/10 x0',
    ]) {
      expect(TimingSpec.parse(name)!.valid, isFalse, reason: name);
    }
  });
  test(
    'monotonic time drives work, rest, all rounds and completion without drift',
    () async {
      var now = Duration.zero;
      final audio = FakeAudio(), owner = Object();
      final timer = WorkoutTimer(audio: audio, now: () => now);
      timer.toggle(owner, const TimingSpec(tabata: true, bpm: 120));
      expect(timer.phase, TimingPhase.ready);
      expect(timer.remaining, 3);
      now = const Duration(seconds: 3);
      timer.tick();
      expect(timer.phase, TimingPhase.work);
      expect(timer.remaining, 20);
      now = const Duration(seconds: 23);
      timer.tick();
      expect(timer.phase, TimingPhase.rest);
      expect(timer.remaining, 10);
      now = const Duration(seconds: 93);
      timer.tick();
      expect(timer.round, 4);
      expect(timer.phase, TimingPhase.work);
      // 3 + 20×8 + 10×7: the last round has no rest.
      now = const Duration(milliseconds: 232900);
      timer.tick();
      expect(timer.phase, TimingPhase.work);
      expect(timer.round, 8);
      now = const Duration(seconds: 233);
      timer.tick();
      expect(timer.phase, TimingPhase.complete);
      expect(timer.running, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(audio.calls.any((c) => c.bpm == 120 && c.active), isTrue);
      expect(audio.calls.any((c) => c.cue == 'rest' && c.bpm == null), isTrue);
      expect(audio.calls.last, (active: false, bpm: null, cue: 'complete'));
      timer.dispose();
    },
  );
  test('운동 구간이 끝나면 몇 라운드를 마쳤는지 말한다', () async {
    var now = Duration.zero;
    final audio = FakeAudio(), owner = Object();
    final timer = WorkoutTimer(audio: audio, now: () => now)
      ..announceRound = ((n) => '$n라운드 종료');
    timer.toggle(
      owner,
      const TimingSpec(tabata: true, work: 5, rest: 4, rounds: 2),
    );
    for (var ms = 0; ms <= 21500; ms += 50) {
      now = Duration(milliseconds: ms);
      timer.tick();
      // 실제와 같이 매 눈금마다 소리 명령이 흘러가게 둔다. 몰아서 흘리면
      // 완료가 앞선 말까지 취소해 버려 이 검사가 무엇도 못 본다.
      await Future<void>.delayed(Duration.zero);
    }
    // 쉬는 구간에 들어갈 때 한 번씩. 마지막 라운드는 쉬지 않고 끝나므로 완료
    // 소리와 겹치지 않게 말하지 않는다.
    expect(audio.spoken, ['1라운드 종료']);
    timer.dispose();
  });

  test(
    'every interval counts down its last three seconds, then a long cue',
    () async {
      var now = Duration.zero;
      final audio = FakeAudio(), owner = Object();
      final timer = WorkoutTimer(audio: audio, now: () => now);
      timer.toggle(
        owner,
        const TimingSpec(tabata: true, work: 5, rest: 4, rounds: 2),
      );
      for (var ms = 0; ms <= 21500; ms += 100) {
        now = Duration(milliseconds: ms);
        timer.tick();
      }
      await Future<void>.delayed(Duration.zero);
      const tick = ['ready', 'ready', 'ready'];
      expect(audio.calls.map((c) => c.cue).whereType<String>().toList(), [
        ...tick,
        'work',
        ...tick,
        'rest',
        ...tick,
        'work',
        ...tick,
        'complete',
      ]);
      timer.dispose();
    },
  );
  test(
    'pause, interruptions and reset stop sound and preserve elapsed work',
    () async {
      var now = Duration.zero;
      final audio = FakeAudio(), owner = Object();
      final timer = WorkoutTimer(audio: audio, now: () => now);
      timer.toggle(owner, const TimingSpec(tabata: true));
      now = const Duration(seconds: 8);
      timer.pause();
      now = const Duration(seconds: 108);
      expect(timer.remaining, 15);
      timer.toggle(owner, const TimingSpec(tabata: true));
      now = const Duration(seconds: 110);
      timer.tick();
      expect(timer.remaining, 13);
      // 제어 센터·알림 센터는 inactive 만 거친다 — 타바타는 계속 돈다.
      timer.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(timer.running, isTrue);
      // 화면 꺼짐·홈 버튼에도 계속 돈다 — 소리는 백그라운드에서 난다.
      timer.didChangeAppLifecycleState(AppLifecycleState.hidden);
      timer.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(timer.running, isTrue);
      timer.didChangeAppLifecycleState(AppLifecycleState.detached);
      expect(timer.running, isFalse);
      timer.toggle(owner, const TimingSpec(bpm: 90));
      audio.onInterrupted!();
      expect(timer.running, isFalse);
      timer.reset();
      expect(timer.elapsed, Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(audio.calls.last.active, isFalse);
      timer.dispose();
    },
  );
  _adjustable();
  _counting();
  _aloud();
  _engine();
}

void _aloud() {
  group('소리내어 세기', () {
    // 이 파일의 다른 테스트와 같은 얼개다 — 시계를 손으로 밀고, 끝에서 직접
    // 치운다. addTearDown 은 남은 타이머 검사보다 늦게 돌아 통과하지 못한다.
    Future<List<String>> run(
      WidgetTester tester, {
      required bool aloud,
      required String locale,
      required int ticks,
    }) async {
      var now = Duration.zero;
      final audio = FakeAudio();
      final timer = WorkoutTimer(audio: audio, now: () => now)
        ..countAloud = aloud
        ..voiceLocale = locale;
      timer.toggle(Object(), const TimingSpec(bpm: 60)); // 1초에 한 박
      await tester.idle();
      // 앞 3초는 준비 카운트다운이라 박자가 없다.
      for (var i = 1; i <= ticks + 3; i++) {
        now = Duration(seconds: i);
        timer.tick();
        await tester.idle();
      }
      expect(audio.events.first, 'configure');
      timer.pause();
      await tester.idle(); // 소리 명령이 차례로 흘러가게 둔다
      timer.dispose();
      return audio.spoken;
    }

    testWidgets('켜면 박자마다 세는 말을 읽는다', (tester) async {
      expect(await run(tester, aloud: true, locale: 'ko', ticks: 3), [
        '하나',
        '둘',
        '셋',
        '넷',
      ]);
    });

    testWidgets('메트로놈도 준비 3초를 세고 나서 클릭을 시작한다', (tester) async {
      var now = Duration.zero;
      final audio = FakeAudio();
      final timer = WorkoutTimer(audio: audio, now: () => now);
      timer.toggle(Object(), const TimingSpec(bpm: 60));
      for (var ms = 100; ms <= 3200; ms += 100) {
        now = Duration(milliseconds: ms);
        timer.tick();
      }
      await tester.idle();
      expect(audio.calls.map((c) => c.cue).whereType<String>().toList(), [
        'ready',
        'ready',
        'ready',
        'work',
      ]);
      // 준비 동안은 클릭이 없다가, 시작 소리와 함께 박자가 돈다.
      expect(audio.calls.where((c) => c.bpm != null).first.cue, 'work');
      expect(timer.beat, 1);
      timer.pause();
      await tester.idle();
      timer.dispose();
    });

    testWidgets('pause cancels queued counts before audio commands finish', (
      tester,
    ) async {
      final audio = FakeAudio();
      final timer = WorkoutTimer(audio: audio)..countAloud = true;
      timer.toggle(Object(), const TimingSpec(bpm: 60));
      timer.pause();
      await tester.idle();
      expect(audio.spoken, isEmpty);
      expect(audio.events.last, 'stop');
      timer.dispose();
    });

    Future<List<String>> counts(
      WidgetTester tester,
      int bpm,
      int beats, {
      bool jitter = false,
    }) async {
      var now = Duration.zero;
      final audio = FakeAudio();
      final timer = WorkoutTimer(audio: audio, now: () => now)
        ..countAloud = true
        ..voiceLocale = 'ko';
      timer.toggle(Object(), TimingSpec(bpm: bpm));
      // 50ms 마다 본다 — 실제 타이머와 같은 간격. [jitter] 면 틱이 세 번에 한 번
      // 40ms 늦게 돈다(프레임 빌드·GC). 박자를 알아채는 때가 들쭉날쭉해진다.
      final end = 3000 + beats * 60000 ~/ bpm;
      for (var k = 1; k * 50 <= end; k++) {
        now = Duration(milliseconds: k * 50 + (jitter && k % 3 == 0 ? 40 : 0));
        timer.tick();
      }
      await tester.idle();
      timer.pause();
      await tester.idle();
      timer.dispose();
      return audio.spoken;
    }

    testWidgets('100bpm 에서 스물일곱도 빠지지 않는다 — 빨리 읽어 한 박에 넣는다', (tester) async {
      final said = await counts(tester, 100, 40);
      expect(said, [
        for (var n = 1; n <= said.length; n++) spokenCount(n, 'ko'),
      ]);
      expect(said.length, greaterThanOrEqualTo(40));
      expect(countPace('스물일곱', 'ko', 100).rate, lessThanOrEqualTo(2.0));
      expect(
        countPace('스물일곱', 'ko', 100).seconds,
        lessThanOrEqualTo(0.6),
        reason: '다음 박자 전에 끝난다',
      );
    });

    testWidgets('가장 빠른 120bpm — 아흔아홉까지는 다 읽고, 세 자리는 앞 말이 끝난 뒤 첫 박자에서 읽는다', (
      tester,
    ) async {
      final first = await counts(tester, TimingSpec.maxBpm, 135);
      final second = await counts(tester, TimingSpec.maxBpm, 135);
      expect(first, second, reason: '빠지는 박자를 운에 맡기지 않는다');
      expect(first.take(99), [
        for (var n = 1; n <= 99; n++) spokenCount(n, 'ko'),
      ]);
      final numbers = [
        for (final t in first)
          List.generate(
            999,
            (i) => i + 1,
          ).firstWhere((n) => spokenCount(n, 'ko') == t),
      ];
      expect(numbers.last, greaterThan(100));
      expect(numbers.length, lessThan(numbers.last), reason: '세 자리는 건너뛰며 읽는다');
      // 어림값으로 보면 읽는 말끼리 겹치지 않는다.
      for (var i = 1; i < numbers.length; i++) {
        final gap = (numbers[i] - numbers[i - 1]) * 60 / TimingSpec.maxBpm;
        expect(
          countPace(first[i - 1], 'ko', TimingSpec.maxBpm).seconds,
          lessThanOrEqualTo(gap + 0.001),
        );
      }
    });

    testWidgets('틱이 들쭉날쭉 늦어도 120bpm 에서 아흔아홉까지 하나도 안 빠진다', (tester) async {
      final said = await counts(tester, TimingSpec.maxBpm, 99, jitter: true);
      expect(said.take(99), [
        for (var n = 1; n <= 99; n++) spokenCount(n, 'ko'),
      ]);
    });

    testWidgets('박 중간에서 다시 켜면 클릭을 그 자리에서 잇고, 읽을 때가 지난 숫자는 다시 읽지 않는다', (
      tester,
    ) async {
      var now = Duration.zero;
      final audio = FakeAudio();
      final timer = WorkoutTimer(audio: audio, now: () => now)
        ..countAloud = true
        ..voiceLocale = 'ko';
      final spec = const TimingSpec(bpm: 60); // 한 박 1초
      timer.toggle(Object(), spec);
      for (var ms = 50; ms <= 5000; ms += 50) {
        now = Duration(milliseconds: ms);
        timer.tick();
      }
      await tester.idle();
      // 박자 3 에 0.7초 들어섰을 때 멈췄다가 다시 켠다.
      now = const Duration(milliseconds: 5700);
      timer.tick();
      timer.toggle(timer.owner!, spec);
      await tester.idle();
      final before = audio.spoken.length;
      now = const Duration(milliseconds: 5800);
      timer.toggle(timer.owner!, spec);
      await tester.idle();
      expect(
        audio.phases.last,
        closeTo(0.7, 0.01),
        reason: '클릭이 박 안의 그 자리에서 시작한다',
      );
      expect(audio.spoken.length, before, reason: '반 박이 지나 셋은 다시 읽지 않는다');
      for (var ms = 5850; ms <= 6900; ms += 50) {
        now = Duration(milliseconds: ms);
        timer.tick();
      }
      await tester.idle();
      expect(audio.spoken.last, '넷');
      timer.pause();
      await tester.idle();
      timer.dispose();
    });

    testWidgets('꺼져 있으면 아무 말도 안 한다', (tester) async {
      expect(await run(tester, aloud: false, locale: 'ko', ticks: 2), isEmpty);
    });

    testWidgets('언어를 따라 말이 바뀐다', (tester) async {
      // 일본어는 숫자를 읽는 말이 곧 세는 말이라 숫자를 그대로 넘긴다.
      expect(await run(tester, aloud: true, locale: 'ja', ticks: 1), [
        '1',
        '2',
      ]);
    });
  });
}

void _counting() {
  group('세는 말', () {
    test('한국어는 하나·둘·셋으로 센다', () {
      expect(spokenCount(1, 'ko'), '하나');
      expect(spokenCount(3, 'ko'), '셋');
      expect(spokenCount(10, 'ko'), '열');
      expect(spokenCount(11, 'ko'), '열하나');
      expect(spokenCount(20, 'ko'), '스물');
      expect(spokenCount(37, 'ko'), '서른일곱');
      expect(spokenCount(99, 'ko'), '아흔아홉');
    });

    test('백 자리는 한자말, 그 아래는 고유어다', () {
      // "벤치 80kg 100개 채우기" 가 이 앱의 대표 예시다. 100 을 넘는 것은
      // 예외가 아니라 기본이다.
      expect(spokenCount(100, 'ko'), '백');
      expect(spokenCount(101, 'ko'), '백하나');
      expect(spokenCount(110, 'ko'), '백열');
      expect(spokenCount(137, 'ko'), '백서른일곱');
      expect(spokenCount(200, 'ko'), '이백');
      expect(spokenCount(250, 'ko'), '이백쉰');
      expect(spokenCount(999, 'ko'), '구백아흔아홉');
    });

    test('천을 넘으면 숫자로 돌아간다', () {
      expect(spokenCount(1000, 'ko'), '1000');
      expect(spokenCount(0, 'ko'), '0');
    });

    test('다른 언어는 숫자를 그대로 둔다', () {
      expect(spokenCount(3, 'en'), '3');
      expect(spokenCount(3, 'ja'), '3');
      expect(spokenCount(3, 'zh'), '3');
    });
  });
}

void _adjustable() {
  group('버튼으로 고치기', () {
    test('BPM 은 10~120 이다', () {
      expect(const TimingSpec(bpm: 10).valid, isTrue);
      expect(const TimingSpec(bpm: 120).valid, isTrue);
      expect(const TimingSpec(bpm: 9).valid, isFalse);
      expect(const TimingSpec(bpm: 121).valid, isFalse);
    });

    test('범위는 10~120 이고 새 박자는 60 이다', () {
      expect(TimingSpec.minBpm, 10);
      expect(TimingSpec.maxBpm, 120);
      expect(TimingSpec.newBpm, 60);
    });

    test('제목에 적힌 숫자를 고쳐 쓴다', () {
      final spec = TimingSpec.parse('푸시업 100bpm')!;
      expect(spec.copyWith(bpm: 90).applyTo('푸시업 100bpm'), '푸시업 90bpm');
    });

    test('숫자 없이 bpm 만 있으면 숫자를 넣는다', () {
      final spec = TimingSpec.parse('푸시업 bpm')!;
      expect(spec.bpm, 120);
      expect(spec.copyWith(bpm: 60).applyTo('푸시업 bpm'), '푸시업 60bpm');
    });

    test('타바타에 박자를 처음 붙이면 뒤에 적는다', () {
      final spec = TimingSpec.parse('버피 타바타')!;
      expect(spec.copyWith(bpm: 60).applyTo('버피 타바타'), '버피 타바타 60bpm');
    });

    test('운동·휴식 시간을 고쳐 쓴다', () {
      final spec = TimingSpec.parse('버피 타바타 30/15')!;
      expect(spec.work, 30);
      expect(spec.rest, 15);
      final next = spec.copyWith(work: 40, rest: 20);
      expect(next.applyTo('버피 타바타 30/15'), '버피 타바타 40/20');
    });

    test('간격이 안 적혀 있으면 뒤에 적는다', () {
      final spec = TimingSpec.parse('버피 타바타')!;
      expect(spec.copyWith(work: 25).applyTo('버피 타바타'), '버피 타바타 25/10');
    });

    test('라운드도 고쳐 쓴다', () {
      final spec = TimingSpec.parse('버피 타바타 20/10 x6')!;
      expect(spec.rounds, 6);
      expect(
        spec.copyWith(rounds: 10).applyTo('버피 타바타 20/10 x6'),
        '버피 타바타 20/10 x10',
      );
    });

    test('고쳐 쓴 제목은 같은 설정으로 다시 읽힌다', () {
      final spec = TimingSpec.parse('버피 타바타 30/15 x6 100bpm')!;
      final next = spec.copyWith(bpm: 75, work: 45, rest: 25, rounds: 4);
      expect(TimingSpec.parse(next.applyTo('버피 타바타 30/15 x6 100bpm')), next);
    });
  });
}

void _engine() {
  group('엔진', () {
    // A hand-driven clock and a list of what the timer buzzed.
    ({
      WorkoutTimer timer,
      FakeAudio audio,
      List<TimerHaptic> buzzes,
      void Function(Duration) at,
    })
    make({DateTime Function()? wall}) {
      var now = Duration.zero;
      final audio = FakeAudio(), buzzes = <TimerHaptic>[];
      final timer = WorkoutTimer(
        audio: audio,
        now: () => now,
        wallNow: wall,
        haptic: buzzes.add,
      );
      return (
        timer: timer,
        audio: audio,
        buzzes: buzzes,
        at: (Duration d) {
          now = d;
          timer.tick();
        },
      );
    }

    void walk(void Function(Duration) at, int fromMs, int toMs) {
      for (var ms = fromMs; ms <= toMs; ms += 50) {
        at(Duration(milliseconds: ms));
      }
    }

    test('타바타 8×20/10 은 233초에 끝난다 — 마지막 라운드는 쉬지 않는다; tail 이면 243초', () {
      expect(const TimingSpec(tabata: true).duration, 233);
      expect(const TimingSpec(tabata: true, tail: true).duration, 243);
      final t = make();
      t.timer.toggle(Object(), const TimingSpec(tabata: true, tail: true));
      t.at(const Duration(milliseconds: 233500));
      expect(t.timer.phase, TimingPhase.rest);
      expect(t.timer.round, 8);
      t.at(const Duration(seconds: 243));
      expect(t.timer.phase, TimingPhase.complete);
      expect(t.timer.total, const Duration(seconds: 243));
      t.timer.dispose();
    });

    test('tail 이면 마지막 라운드 종료도 말한다', () async {
      final t = make();
      t.timer.announceRound = (n) => '$n';
      t.timer.toggle(
        Object(),
        const TimingSpec(tabata: true, work: 5, rest: 4, rounds: 2, tail: true),
      );
      for (var ms = 0; ms <= 21500; ms += 50) {
        t.at(Duration(milliseconds: ms));
        await Future<void>.delayed(Duration.zero);
      }
      expect(t.audio.spoken, ['1', '2']);
      t.timer.dispose();
    });

    test('박자 목표 30 @60bpm: 30번째 숫자를 읽은 뒤 32.55초에 끝나고 30을 지킨다', () {
      final t = make();
      var completed = 0;
      t.timer.onComplete = () => completed++;
      t.timer.toggle(Object(), const TimingSpec(bpm: 60), target: 30);
      expect(t.timer.total, const Duration(milliseconds: 32550));
      expect(t.timer.level, 1);
      t.at(const Duration(seconds: 18)); // 15 counts in
      expect(t.timer.count, 16);
      expect(t.timer.level, closeTo(1 - 16 / 30, 1e-9));
      t.at(const Duration(milliseconds: 32540));
      expect(t.timer.phase, TimingPhase.work);
      expect(t.timer.count, 30);
      t.at(const Duration(milliseconds: 32550));
      expect(t.timer.phase, TimingPhase.complete);
      expect(t.timer.running, isFalse);
      expect(t.timer.count, 30);
      expect(t.timer.level, 0);
      expect(completed, 1);
      expect(t.buzzes.last, TimerHaptic.success);
      t.timer.dispose();
    });

    test('박자는 멈춰도 센 수를 지키고, 목표가 없으면 끝나지 않는다', () {
      final t = make();
      t.timer.toggle(Object(), const TimingSpec(bpm: 60));
      t.at(const Duration(milliseconds: 9500));
      expect(t.timer.count, 7);
      t.timer.pause();
      expect(t.timer.beat, 0, reason: '소리용 박자는 멈추면 0');
      expect(t.timer.count, 7);
      expect(t.timer.total, isNull);
      t.timer.resume();
      t.at(const Duration(hours: 5));
      expect(t.timer.phase, TimingPhase.work);
      expect(t.timer.level, 1);
      t.timer.dispose();
    });

    test('수위: 준비는 3초에 걸쳐, 타바타는 구간 남은 비율로 줄어든다', () {
      final t = make();
      t.timer.toggle(Object(), const TimingSpec(tabata: true));
      expect(t.timer.level, 1);
      t.at(const Duration(milliseconds: 1500));
      expect(t.timer.level, closeTo(0.5, 1e-9));
      t.at(const Duration(seconds: 8)); // 5 s into 20 s of work
      expect(t.timer.level, closeTo(0.75, 1e-9));
      expect(t.timer.phaseElapsed, const Duration(seconds: 5));
      t.at(const Duration(seconds: 25)); // 2 s into 10 s of rest
      expect(t.timer.level, closeTo(0.8, 1e-9));
      expect(t.timer.phaseElapsed, const Duration(seconds: 2));
      t.timer.dispose();
    });

    test('skip: 준비→운동→휴식→다음 운동, 마지막 운동은 완료', () {
      final t = make();
      var completed = 0;
      t.timer.onComplete = () => completed++;
      const spec = TimingSpec(tabata: true, rounds: 2);
      t.timer.toggle(Object(), spec);
      expect(t.timer.canSkip, isTrue);
      t.timer.skip();
      expect(t.timer.phase, TimingPhase.work);
      expect(t.timer.remaining, 20);
      t.timer.skip();
      expect(t.timer.phase, TimingPhase.rest);
      t.timer.skip();
      expect((t.timer.phase, t.timer.round), (TimingPhase.work, 2));
      t.timer.skip();
      expect(t.timer.phase, TimingPhase.complete);
      expect(completed, 1);
      expect(t.timer.canSkip, isFalse);
      t.timer.dispose();
    });

    test('back: 2초가 지났으면 구간 처음, 아니면 앞 구간 처음; 멈춘 채로도 된다', () {
      final t = make();
      t.timer.toggle(Object(), const TimingSpec(tabata: true));
      t.at(const Duration(seconds: 10)); // 7 s into work 1
      t.timer.back();
      expect(t.timer.elapsed, const Duration(seconds: 3));
      t.timer.back(); // under 2 s into work 1 → ready
      expect(t.timer.elapsed, Duration.zero);
      t.timer.back(); // ready stays at 0
      expect(t.timer.elapsed, Duration.zero);
      // The clock moved by 10 s of seeks: 44 s on it is 34 s into the run.
      t.at(const Duration(seconds: 44)); // 1 s into work 2
      expect(t.timer.elapsed, const Duration(seconds: 34));
      t.timer.pause();
      expect(t.timer.canSkip, isTrue);
      t.timer.back(); // → rest 1
      expect(t.timer.elapsed, const Duration(seconds: 23));
      expect(t.timer.phase, TimingPhase.rest);
      t.timer.back(); // under 2 s into rest 1 → work 1
      expect(t.timer.elapsed, const Duration(seconds: 3));
      expect(t.timer.running, isFalse);
      t.timer.dispose();
    });

    test('skip·back 은 같이 하는 중에는 아무 일도 안 한다', () {
      final t = make();
      t.timer.follow(
        Object(),
        const TimingSpec(tabata: true),
        const Duration(seconds: 10),
      );
      expect(t.timer.canSkip, isFalse);
      final before = t.timer.elapsed;
      t.timer.skip();
      t.timer.back();
      t.at(const Duration(seconds: 15)); // 25 s in: rest
      t.timer.skipRest();
      expect(t.timer.phase, TimingPhase.rest);
      expect(t.timer.elapsed - before, const Duration(seconds: 15));
      t.timer.dispose();
    });

    test('back 뒤에는 묵음이 아니다: 말 대기가 풀리고 클릭이 새 자리에 다시 놓인다', () async {
      final t = make();
      t.timer
        ..countAloud = true
        ..voiceLocale = 'ko';
      const spec = TimingSpec(tabata: true, bpm: 60, work: 40);
      t.timer.toggle(Object(), spec);
      walk(t.at, 50, 30000); // 27 counts into work 1
      await Future<void>.delayed(Duration.zero);
      expect(t.audio.spoken.last, '스물여덟');
      final calls = t.audio.calls.length, said = t.audio.spoken.length;
      t.timer.back(); // → start of work 1 (3 s)
      await Future<void>.delayed(Duration.zero);
      // The same interval: no cue, but the loop is re-placed on the new grid.
      expect(t.audio.calls.length, calls + 1);
      expect(t.audio.calls.last, (active: true, bpm: 60, cue: null));
      expect(t.audio.phases.last, closeTo(0, 0.001));
      walk(t.at, 30050, 32100);
      await Future<void>.delayed(Duration.zero);
      expect(t.audio.spoken.sublist(said), ['하나', '둘', '셋']);
      t.timer.dispose();
    });

    test('skip 으로 운동 구간 처음에 오면 저절로 들어올 때처럼 첫 박부터 읽는다', () async {
      // From ready into work 1, and from rest 1 (23..33 s) into work 2.
      for (final from in [1000, 25000]) {
        final t = make();
        t.timer
          ..countAloud = true
          ..voiceLocale = 'ko';
        t.timer.toggle(Object(), const TimingSpec(tabata: true, bpm: 60));
        walk(t.at, 50, from);
        await Future<void>.delayed(Duration.zero);
        final said = t.audio.spoken.length;
        t.timer.skip();
        expect(t.timer.phase, TimingPhase.work);
        walk(t.at, from + 50, from + 2100);
        await Future<void>.delayed(Duration.zero);
        expect(t.audio.spoken.sublist(said), ['하나', '둘', '셋'], reason: '$from');
        t.timer.dispose();
      }
    });

    test('멈춘 채 0초로 돌아와도 멈춤이다 — skip·back 이 듣고, 다시 켜면 이어 간다', () {
      final t = make();
      final block = Object();
      const spec = TimingSpec(tabata: true);
      t.timer.toggle(block, spec);
      t.timer.pause(); // before the clock moved
      expect(t.timer.canSkip, isTrue);
      t.timer.toggle(block, spec);
      t.at(const Duration(seconds: 4)); // 1 s into work 1
      t.timer.pause();
      t.timer.back(); // under 2 s into work 1 → ready, 0 s
      expect(
        (t.timer.elapsed, t.timer.phase, t.timer.running),
        (Duration.zero, TimingPhase.ready, false),
      );
      expect(t.timer.canSkip, isTrue);
      t.timer.skip();
      expect(t.timer.elapsed, const Duration(seconds: 3));
      t.timer.back();
      t.buzzes.clear();
      t.timer.toggle(block, spec);
      expect(t.timer.running, isTrue);
      expect(t.buzzes, [TimerHaptic.medium], reason: '새 시작이 아니라 이어 가기');
      t.timer.reset();
      expect(t.timer.canSkip, isFalse);
      t.timer.dispose();
    });

    test(
      'end: 10초 미만은 처음으로, 넘으면 endedEarly 와 onComplete 한 번, 완료 소리 없이',
      () async {
        final t = make();
        var completed = 0;
        t.timer.onComplete = () => completed++;
        const spec = TimingSpec(tabata: true);
        t.timer.toggle(Object(), spec);
        t.at(const Duration(seconds: 9));
        t.timer.end();
        expect(t.timer.elapsed, Duration.zero);
        expect(t.timer.running, isFalse);
        expect(t.timer.endedEarly, isFalse);
        expect(completed, 0);
        t.timer.toggle(t.timer.owner!, spec);
        t.at(const Duration(seconds: 59)); // 9+50: 2 rounds done, in work 3
        t.timer.end();
        t.timer.end();
        expect(t.timer.endedEarly, isTrue);
        expect(t.timer.running, isFalse);
        expect(t.timer.round, 2);
        expect(completed, 1);
        await Future<void>.delayed(Duration.zero);
        expect(t.audio.calls.map((c) => c.cue), isNot(contains('complete')));
        t.timer.resume();
        expect(t.timer.running, isFalse, reason: '끝난 run 은 이어 가지 않는다');
        t.timer.restart();
        expect(t.timer.running, isTrue);
        expect(t.timer.elapsed, Duration.zero);
        expect(t.timer.endedEarly, isFalse);
        t.timer.dispose();
      },
    );

    test('박자 목표가 센 수 아래로 내려오면 그 자리에서 끝난다 — 센 박과 시간을 지키고 onComplete 는 한 번', () {
      const spec = TimingSpec(bpm: 60);
      final block = Object();
      // toggle while running, toggle while paused, follow while running.
      for (final how in ['running', 'paused', 'follow']) {
        final t = make();
        var completed = 0;
        t.timer.onComplete = () => completed++;
        if (how == 'follow') {
          t.timer.follow(block, spec, Duration.zero, target: 30);
        } else {
          t.timer.toggle(block, spec, target: 30);
        }
        t.at(const Duration(seconds: 23));
        expect(t.timer.count, 21);
        if (how == 'paused') t.timer.toggle(block, spec, target: 30);
        if (how == 'follow') {
          t.timer.follow(block, spec, const Duration(seconds: 23), target: 10);
        } else {
          t.timer.toggle(block, spec, target: 10);
        }
        t.at(const Duration(milliseconds: 23050));
        expect(
          (t.timer.phase, t.timer.running, t.timer.count, t.timer.level),
          (TimingPhase.complete, false, 21, 0.0),
          reason: how,
        );
        expect(t.timer.elapsed, const Duration(seconds: 23), reason: how);
        expect(completed, 1, reason: how);
        expect(t.buzzes.last, TimerHaptic.success, reason: how);
        t.timer.resume();
        t.timer.end();
        expect((t.timer.running, t.timer.endedEarly), (false, false));
        expect(completed, 1, reason: how);
        t.timer.dispose();
      }
    });

    test('끝난 뒤 첫 tick 전에 멈추거나 끝내도 그 run 은 완료다', () {
      for (final stop in [
        (WorkoutTimer t) => t.pause(),
        (WorkoutTimer t) => t.end(),
      ]) {
        var now = Duration.zero, completed = 0;
        final timer = WorkoutTimer(
          audio: FakeAudio(),
          now: () => now,
          haptic: (_) {},
        )..onComplete = () => completed++;
        timer.toggle(Object(), const TimingSpec(bpm: 60), target: 5);
        now = const Duration(milliseconds: 7500);
        timer.tick();
        now = const Duration(milliseconds: 7560); // over at 7.55 s, not ticked
        stop(timer);
        expect(
          (timer.phase, timer.count, timer.endedEarly, completed),
          (TimingPhase.complete, 5, false, 1),
        );
        timer.dispose();
      }
    });

    test('end 는 박자 수를 그 순간 값으로 굳힌다', () {
      final t = make();
      t.timer.toggle(Object(), const TimingSpec(bpm: 60), target: 30);
      t.at(const Duration(milliseconds: 15500));
      t.timer.end();
      t.at(const Duration(seconds: 40));
      expect(t.timer.count, 13);
      expect(t.timer.phase, TimingPhase.work);
      t.timer.dispose();
    });

    test('같이 하는 박자가 목표에서 끝나면 follow 가 다시 켜지 않는다', () {
      final t = make();
      final block = Object();
      const spec = TimingSpec(bpm: 60);
      var completed = 0;
      t.timer.onComplete = () => completed++;
      t.timer.follow(block, spec, Duration.zero, target: 5);
      t.at(const Duration(seconds: 8));
      expect(t.timer.phase, TimingPhase.complete);
      expect(t.timer.count, 5);
      t.timer.follow(block, spec, const Duration(seconds: 9), target: 5);
      t.timer.follow(block, spec, const Duration(seconds: 20), target: 5);
      expect(t.timer.running, isFalse);
      expect(t.timer.count, 5);
      expect(completed, 1);
      // A reset lets the same run be followed again.
      t.timer.reset();
      t.timer.follow(block, spec, const Duration(seconds: 1), target: 5);
      expect(t.timer.running, isTrue);
      t.timer.dispose();
    });

    test('수명주기: 인터럽션은 멈추고 끝나면 다시 켠다', () {
      final t = make();
      const spec = TimingSpec(tabata: true);
      t.timer.toggle(Object(), spec);
      t.at(const Duration(seconds: 5));
      t.audio.onInterrupted!();
      expect(t.timer.running, isFalse);
      t.at(const Duration(seconds: 30));
      t.audio.onResumed!();
      expect(t.timer.running, isTrue);
      expect(t.timer.elapsed, const Duration(seconds: 5));

      // Resumed by hand before the system said so: the late resumed is ignored.
      t.audio.onInterrupted!();
      t.timer.toggle(t.timer.owner!, spec);
      t.at(const Duration(seconds: 32));
      t.audio.onResumed!();
      expect(t.timer.elapsed, const Duration(seconds: 7));

      // Reset during the interruption: nothing comes back.
      t.audio.onInterrupted!();
      t.timer.reset();
      t.audio.onResumed!();
      expect(t.timer.running, isFalse);
      t.timer.dispose();
    });

    test('기기가 잠들어 단조 시계가 멈춘 만큼 벽시계로 채운다 — 놓친 신호는 울리지 않는다', () async {
      var wall = DateTime(2026, 10, 17, 9);
      final t = make(wall: () => wall);
      t.timer.toggle(Object(), const TimingSpec(tabata: true));
      wall = wall.add(const Duration(seconds: 1));
      t.at(const Duration(seconds: 1));
      expect(t.timer.elapsed, const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      final cues = t.audio.calls.length;
      // The device slept: 2 s on the monotonic clock, 62 s on the wall.
      wall = wall.add(const Duration(seconds: 62));
      t.at(const Duration(seconds: 3));
      expect(t.timer.elapsed, const Duration(seconds: 63));
      t.timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(t.timer.elapsed, const Duration(seconds: 63));
      expect((t.timer.phase, t.timer.round), (TimingPhase.work, 3));
      await Future<void>.delayed(Duration.zero);
      // One cue for where it is now, none for the intervals it slept through.
      expect(t.audio.calls.skip(cues).map((c) => c.cue).whereType<String>(), [
        'work',
      ]);
      t.timer.dispose();
    });

    test('1초가 안 되는 잠도 버리지 않고 모아서 채운다', () {
      var wall = DateTime(2026, 10, 17, 9);
      final t = make(wall: () => wall);
      t.timer.toggle(Object(), const TimingSpec(tabata: true));
      // Ten 0.8 s sleeps: 50 ms on the monotonic clock, 850 ms on the wall.
      for (var i = 1; i <= 10; i++) {
        wall = wall.add(const Duration(milliseconds: 850));
        t.at(Duration(milliseconds: 50 * i));
      }
      expect(t.timer.elapsed, const Duration(milliseconds: 8500));
      t.timer.dispose();
    });

    test('햅틱은 소리와 같은 자리에서, 꺼 두면 없다', () {
      final t = make();
      t.timer.toggle(
        Object(),
        const TimingSpec(tabata: true, work: 5, rest: 4, rounds: 1),
      );
      walk(t.at, 50, 8000);
      t.timer.toggle(Object(), const TimingSpec(tabata: true));
      t.timer.pause();
      t.timer.resume();
      t.timer.skip();
      expect(t.buzzes, [
        ...List.filled(3, TimerHaptic.tick), // ready
        TimerHaptic.heavy, // work
        ...List.filled(3, TimerHaptic.tick), // last three seconds
        TimerHaptic.success,
        TimerHaptic.tick, // a new run's ready
        TimerHaptic.medium, // pause
        TimerHaptic.medium, // resume
        TimerHaptic.tick, // skip
        TimerHaptic.heavy, // into work
      ]);
      t.buzzes.clear();
      t.timer.haptics = false;
      t.timer.skip();
      t.timer.pause();
      expect(t.buzzes, isEmpty);
      t.timer.dispose();
    });

    test('박자마다 한 번 알린다', () {
      final t = make();
      var notes = 0;
      t.timer.toggle(Object(), const TimingSpec(bpm: 120));
      t.at(const Duration(seconds: 3));
      t.timer.addListener(() => notes++);
      walk(t.at, 3050, 5000); // 2 s at 120 bpm: 4 beats
      expect(notes, 4);
      t.timer.dispose();
    });

    test('타이머 진동은 기본 켜짐이고, 끈 것은 다시 열어도 꺼져 있다', () async {
      final dir = Directory.systemTemp.createTempSync('setpad_haptics_');
      final store = NotesStore(directory: dir);
      addTearDown(() {
        store.dispose();
        dir.deleteSync(recursive: true);
      });
      expect(store.hapticsOn, isTrue);
      store.create();
      store.setHapticsOn(false);
      await store.flush();
      final reopened = NotesStore(directory: dir);
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.hapticsOn, isFalse);
    });

    test('중국어 화면 언어는 음성 엔진이 아는 지역 태그로', () {
      final t = make();
      for (final (tag, want) in [
        ('zh', 'zh-CN'),
        ('zh-Hans', 'zh-CN'),
        ('zh-Hans-CN', 'zh-CN'),
        ('zh-Hant', 'zh-TW'),
        ('zh-Hant-TW', 'zh-TW'),
        ('ko', 'ko'),
        ('en-US', 'en-US'),
      ]) {
        t.timer.voiceLocale = tag;
        expect(t.timer.voiceLocale, want, reason: tag);
      }
      t.timer.dispose();
    });
  });
}
