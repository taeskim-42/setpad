import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/workout_timing.dart';
import 'package:setpad/timing_audio.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';

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
      now = const Duration(seconds: 243);
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
    // 쉬는 구간에 들어갈 때 한 번씩, 마지막 라운드까지. 박자 세기와 무관하다.
    expect(audio.spoken, ['1라운드 종료', '2라운드 종료']);
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
        'rest',
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
      timer.didChangeAppLifecycleState(AppLifecycleState.inactive);
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
  testWidgets(
    'controls appear from the title without creating sets and collapse while dragging',
    (tester) async {
      final c = RoutineEditorController()
        ..addExercise('버피 타바타')
        ..closeBlock();
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          supportedLocales: L.supportedLocales,
          localizationsDelegates: L.localizationsDelegates,
          home: CupertinoPageScaffold(child: RoutineEditor(controller: c)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutTimingControls), findsOneWidget);
      expect(find.text('시작'), findsOneWidget);
      expect(c.blocks.single.sets, isEmpty);
      c.renameBlock(0, '버피');
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutTimingControls), findsNothing);
    },
  );
  _adjustable();
  _counting();
  _aloud();
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

    test('눈금은 10 이다', () {
      expect(TimingSpec.bpmStep, 10);
      expect(TimingSpec.minBpm, 10);
      expect(TimingSpec.maxBpm, 120);
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
