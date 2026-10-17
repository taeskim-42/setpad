import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/count_voice_lengths.dart';
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
    if (cue != null) log.add(cue);
  }

  /// Cues and words in the order they were sent: 'work', 'voice:round_1'.
  final log = <String>[];

  /// Recorded words asked for, as asset paths; [onBeat] alongside.
  final voices = <String>[];
  final onBeat = <bool>[];
  @override
  Future<void> playVoice(String asset, {bool onBeat = false}) async {
    events.add('voice');
    voices.add(asset);
    this.onBeat.add(onBeat);
    log.add('voice:${asset.split('/').last.split('.').first}');
  }

  /// The counts read, as numbers.
  List<int> get counts => [
    for (final v in voices)
      if (v.contains('/count/')) int.parse(v.split('/').last.split('.').first),
  ];

  /// The phrases said ('round_1', 'rest', 'done').
  List<String> get phrases => [
    for (final v in voices)
      if (!v.contains('/count/')) v.split('/').last.split('.').first,
  ];

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
  test('구간이 바뀔 때 녹음으로 말한다 — 라운드, 휴식, 마지막 라운드, 완료', () async {
    var now = Duration.zero;
    final audio = FakeAudio(), owner = Object();
    final timer = WorkoutTimer(audio: audio, now: () => now);
    timer.toggle(
      owner,
      const TimingSpec(tabata: true, work: 5, rest: 4, rounds: 2),
    );
    for (var ms = 0; ms <= 21500; ms += 50) {
      now = Duration(milliseconds: ms);
      timer.tick();
      // 실제와 같이 매 눈금마다 소리 명령이 흘러가게 둔다.
      await Future<void>.delayed(Duration.zero);
    }
    expect(audio.voices, [
      'assets/voice/en/m/round_1.m4a',
      'assets/voice/en/m/rest.m4a',
      'assets/voice/en/m/last_round.m4a',
      'assets/voice/en/m/done.m4a',
    ]);
    // Each right after the cue of its boundary, to sound once that is over.
    expect(audio.onBeat, everyElement(isFalse));
    expect(audio.log.where((e) => e != 'ready'), [
      'work',
      'voice:round_1',
      'rest',
      'voice:rest',
      'work',
      'voice:last_round',
      'complete',
      'voice:done',
    ]);
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
  _voices();
  _countPlan();
}

void _voices() {
  group('녹음 음성', () {
    ({WorkoutTimer timer, FakeAudio audio, void Function(int) to}) make() {
      var now = Duration.zero;
      final audio = FakeAudio();
      final timer = WorkoutTimer(audio: audio, now: () => now, haptic: (_) {});
      return (
        timer: timer,
        audio: audio,
        to: (int ms) {
          // Every 50 ms, as the real ticker, so no boundary is missed.
          for (var t = now.inMilliseconds + 50; t <= ms; t += 50) {
            now = Duration(milliseconds: t);
            timer.tick();
          }
        },
      );
    }

    final pubspec = File('pubspec.yaml').readAsStringSync();

    /// Every word is a recording that ships: no system speech is left.
    void allRecorded(FakeAudio audio) {
      expect(
        audio.events.toSet().difference({'configure', 'stop', 'voice'}),
        isEmpty,
      );
      for (final v in audio.voices.toSet()) {
        expect(File(v).existsSync(), isTrue, reason: v);
        expect(pubspec, contains('- ${File(v).parent.path}/'), reason: v);
      }
    }

    test('타바타 8라운드 — 라운드·휴식·마지막·완료가 녹음이고, 시스템 음성은 한 마디도 없다', () async {
      final t = make();
      t.timer.toggle(Object(), const TimingSpec(tabata: true));
      t.to(233000);
      await pumpEventQueue();
      expect(t.timer.phase, TimingPhase.complete);
      expect(t.audio.phrases, [
        for (var n = 1; n <= 7; n++) ...['round_$n', 'rest'],
        'last_round',
        'done',
      ]);
      allRecorded(t.audio);
      t.timer.dispose();
    });

    test('박자 세기를 켜면 운동 시작의 말 대신 첫 숫자가 시작을 알린다 — 타바타 박자도, 메트로놈 30회도', () async {
      final t = make();
      t.timer
        ..countAloud = true
        ..toggle(
          Object(),
          const TimingSpec(tabata: true, bpm: 60, work: 5, rest: 4, rounds: 2),
        );
      t.to(21500);
      await pumpEventQueue();
      expect(t.audio.log.where((e) => e.startsWith('voice:')), [
        for (var n = 1; n <= 5; n++) 'voice:$n',
        'voice:rest',
        for (var n = 1; n <= 5; n++) 'voice:$n',
        'voice:done',
      ]);
      expect(t.audio.onBeat, [
        ...List.filled(5, true),
        false,
        ...List.filled(5, true),
        false,
      ]);
      allRecorded(t.audio);
      t.timer.dispose();

      final m = make();
      m.timer
        ..countAloud = true
        ..toggle(Object(), const TimingSpec(bpm: 60), target: 30);
      m.to(33000);
      await pumpEventQueue();
      expect(m.timer.phase, TimingPhase.complete);
      expect(m.audio.counts, [for (var n = 1; n <= 30; n++) n]);
      expect(m.audio.phrases, ['done']);
      allRecorded(m.audio);
      m.timer.dispose();
    });

    test('세지 않는 메트로놈은 "Go!" 로 시작한다', () async {
      final t = make();
      t.timer.toggle(Object(), const TimingSpec(bpm: 60), target: 3);
      t.to(6000);
      await pumpEventQueue();
      expect(t.audio.phrases, ['start', 'done']);
      expect(t.audio.counts, isEmpty);
      t.timer.dispose();
    });

    test(
      '라운드는 30 까지 번호로, 그 위는 "Go!", 마지막은 last_round; 한 라운드짜리는 "Go!"',
      () async {
        final t = make();
        t.timer.toggle(Object(), const TimingSpec(tabata: true, rounds: 32));
        while (t.timer.phase != TimingPhase.complete) {
          t.timer.skip();
          // A tap at a time: a skip drops the words still queued before it.
          await pumpEventQueue();
        }
        await pumpEventQueue();
        final works = [
          for (final p in t.audio.phrases)
            if (p != 'rest' && p != 'done') p,
        ];
        expect(works, [
          for (var n = 1; n <= 30; n++) 'round_$n',
          'start',
          'last_round',
        ]);
        t.timer.dispose();

        final one = make();
        one.timer.toggle(Object(), const TimingSpec(tabata: true, rounds: 1));
        one.to(24000);
        await pumpEventQueue();
        expect(one.audio.phrases, ['start', 'done']);
        one.timer.dispose();
      },
    );

    test('같이 하기가 자리를 다시 맞춰도 같은 말을 두 번 하지 않는다 — 경계를 거꾸로 넘어도', () async {
      final t = make();
      final block = Object();
      const spec = TimingSpec(tabata: true);
      t.timer.follow(block, spec, const Duration(seconds: 2));
      t.to(1500); // 3.5 s into the run: work 1
      await pumpEventQueue();
      t.timer.follow(block, spec, const Duration(seconds: 4)); // jump ahead
      t.to(20000); // 22.5 s: still work 1
      t.to(21000); // 23.5 s: rest 1
      await pumpEventQueue();
      expect(t.audio.phrases, ['round_1', 'rest']);
      // Put back 1.5 s, into work 1, then over the same boundary again.
      t.timer.follow(block, spec, const Duration(seconds: 22));
      t.to(23500);
      await pumpEventQueue();
      expect(t.audio.phrases, ['round_1', 'rest'], reason: '두 번 말하지 않는다');
      t.timer.dispose();
    });

    test('운동 음성 안내를 끄면 구간 말은 없고 세는 말은 그대로; 여자 목소리는 w 녹음', () async {
      final t = make();
      t.timer
        ..voiceCues = false
        ..countAloud = true
        ..toggle(Object(), const TimingSpec(bpm: 60), target: 3);
      t.to(6000);
      await pumpEventQueue();
      expect(t.audio.phrases, isEmpty);
      expect(t.audio.counts, [1, 2, 3]);
      t.timer.dispose();

      final w = make();
      w.timer
        ..voice = 'w'
        ..toggle(Object(), const TimingSpec(tabata: true, rounds: 2));
      w.to(4000);
      await pumpEventQueue();
      expect(w.audio.voices, ['assets/voice/en/w/round_1.m4a']);
      w.timer.dispose();
    });

    test('멈추면 줄 서 있던 말은 버리고, 다시 켜도 그 구간의 말을 되풀이하지 않는다', () async {
      final t = make();
      t.timer.toggle(Object(), const TimingSpec(tabata: true));
      t.to(3000);
      t.timer.pause(); // before the queued "Round 1" went out
      await pumpEventQueue();
      expect(t.audio.voices, isEmpty);
      t.timer.resume();
      t.to(4000);
      await pumpEventQueue();
      expect(t.audio.voices, isEmpty, reason: '이어 가기는 새 시작이 아니다');
      t.timer.dispose();
    });
  });
}

void _aloud() {
  group('소리내어 세기', () {
    // 이 파일의 다른 테스트와 같은 얼개다 — 시계를 손으로 밀고, 끝에서 직접
    // 치운다. addTearDown 은 남은 타이머 검사보다 늦게 돌아 통과하지 못한다.
    Future<List<String>> run(
      WidgetTester tester, {
      required bool aloud,
      required int ticks,
      String voice = 'm',
    }) async {
      var now = Duration.zero;
      final audio = FakeAudio();
      final timer = WorkoutTimer(audio: audio, now: () => now)
        ..countAloud = aloud
        ..voice = voice;
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
      return [
        for (final v in audio.voices)
          if (v.contains('/count/')) v,
      ];
    }

    testWidgets('켜면 박자마다 녹음한 세는 말을 박에 맞춰 낸다', (tester) async {
      expect(await run(tester, aloud: true, ticks: 3), [
        for (var n = 1; n <= 4; n++) 'assets/voice/count/en/m/$n.m4a',
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
      expect(audio.voices, isEmpty);
      expect(audio.events.last, 'stop');
      timer.dispose();
    });

    Future<List<int>> counts(
      WidgetTester tester,
      int bpm,
      int beats, {
      bool jitter = false,
    }) async {
      var now = Duration.zero;
      final audio = FakeAudio();
      final timer = WorkoutTimer(audio: audio, now: () => now)
        ..countAloud = true;
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
      return audio.counts;
    }

    // At 120 bpm "Two" would hold up "Three": every 2nd from Two to Thirty,
    // every 5th from Thirty-five ("Thirty-two" would hold up "Thirty-four").
    final fast = [
      1,
      for (var n = 2; n <= 30; n += 2) n,
      for (var n = 35; n <= 100; n += 5) n,
    ];

    testWidgets(
      '120bpm 은 빠질 숫자 앞에서 둘마다·다섯마다로 넓혀 백까지 내고, 101 부터는 읽지 않는다 — 클릭만 간다',
      (tester) async {
        final said = await counts(tester, TimingSpec.maxBpm, 105);
        expect(said, fast);
      },
    );

    testWidgets('틱이 들쭉날쭉 늦어도 120bpm 에서 백까지 정한 숫자가 하나도 안 빠진다', (tester) async {
      final said = await counts(tester, TimingSpec.maxBpm, 100, jitter: true);
      expect(said, fast);
    });

    testWidgets('박 중간에서 다시 켜면 클릭을 그 자리에서 잇고, 읽을 때가 지난 숫자는 다시 읽지 않는다', (
      tester,
    ) async {
      var now = Duration.zero;
      final audio = FakeAudio();
      final timer = WorkoutTimer(audio: audio, now: () => now)
        ..countAloud = true;
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
      final before = audio.counts.length;
      now = const Duration(milliseconds: 5800);
      timer.toggle(timer.owner!, spec);
      await tester.idle();
      expect(
        audio.phases.last,
        closeTo(0.7, 0.01),
        reason: '클릭이 박 안의 그 자리에서 시작한다',
      );
      expect(audio.counts.length, before, reason: '반 박이 지나 셋은 다시 읽지 않는다');
      for (var ms = 5850; ms <= 6900; ms += 50) {
        now = Duration(milliseconds: ms);
        timer.tick();
      }
      await tester.idle();
      expect(audio.counts.last, 4);
      timer.pause();
      await tester.idle();
      timer.dispose();
    });

    testWidgets('꺼져 있으면 세지 않는다', (tester) async {
      expect(await run(tester, aloud: false, ticks: 2), isEmpty);
    });

    testWidgets('여자 목소리를 고르면 그 녹음으로 센다 — 앱 언어와 상관없이 영어', (tester) async {
      expect(await run(tester, aloud: true, ticks: 1, voice: 'w'), [
        'assets/voice/count/en/w/1.m4a',
        'assets/voice/count/en/w/2.m4a',
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

    test('tail 이면 마지막 라운드 뒤 휴식도 말한다', () async {
      final t = make();
      t.timer.toggle(
        Object(),
        const TimingSpec(tabata: true, work: 5, rest: 4, rounds: 2, tail: true),
      );
      for (var ms = 0; ms <= 21500; ms += 50) {
        t.at(Duration(milliseconds: ms));
        await Future<void>.delayed(Duration.zero);
      }
      expect(t.audio.phrases, [
        'round_1',
        'rest',
        'last_round',
        'rest',
        'done',
      ]);
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

    test('runId: 처음부터 시작·restart·reset·clear·다른 같이 run 만 새 run 이다', () {
      final t = make();
      final card = Object(), other = Object();
      const spec = TimingSpec(tabata: true);
      final ids = <int>[];
      void mark() => ids.add(t.timer.runId);
      t.timer.toggle(card, spec);
      mark(); // new
      t.at(const Duration(seconds: 24));
      t.timer.pause();
      t.timer.resume();
      t.timer.skip();
      t.timer.back();
      t.timer.back();
      t.timer.back(); // to the ready: still this run
      t.timer.toggle(card, spec); // pause
      t.timer.toggle(card, spec); // resume
      mark();
      t.timer.restart();
      mark();
      t.timer.reset();
      mark();
      t.timer.follow(card, spec, const Duration(seconds: 10));
      mark(); // a shared run
      t.timer.follow(card, spec, const Duration(seconds: 12)); // re-sync
      t.timer.pause(); // left
      t.timer.follow(card, spec, const Duration(seconds: 14)); // rejoined
      mark();
      t.timer.follow(other, spec, const Duration(seconds: 1));
      mark();
      t.timer.toggle(other, spec); // solo after shared
      mark();
      t.at(const Duration(seconds: 40));
      t.timer.end(); // the summary is this run
      mark();
      t.timer.toggle(other, spec); // from the top after the end
      mark();
      t.timer.clear();
      mark();
      final first = ids.first;
      expect(ids.map((id) => id - first), [0, 0, 1, 2, 3, 3, 4, 5, 5, 6, 7]);
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
      t.timer.countAloud = true;
      const spec = TimingSpec(tabata: true, bpm: 60, work: 40);
      t.timer.toggle(Object(), spec);
      walk(t.at, 50, 30000); // 27 counts into work 1
      await Future<void>.delayed(Duration.zero);
      expect(t.audio.counts.last, 28);
      final calls = t.audio.calls.length, said = t.audio.counts.length;
      t.timer.back(); // → start of work 1 (3 s)
      await Future<void>.delayed(Duration.zero);
      // The same interval: no cue, but the loop is re-placed on the new grid.
      expect(t.audio.calls.length, calls + 1);
      expect(t.audio.calls.last, (active: true, bpm: 60, cue: null));
      expect(t.audio.phases.last, closeTo(0, 0.001));
      walk(t.at, 30050, 32100);
      await Future<void>.delayed(Duration.zero);
      expect(t.audio.counts.sublist(said), [1, 2, 3]);
      t.timer.dispose();
    });

    test('skip 으로 운동 구간 처음에 오면 저절로 들어올 때처럼 첫 박부터 읽는다', () async {
      // From ready into work 1, and from rest 1 (23..33 s) into work 2.
      for (final from in [1000, 25000]) {
        final t = make();
        t.timer.countAloud = true;
        t.timer.toggle(Object(), const TimingSpec(tabata: true, bpm: 60));
        walk(t.at, 50, from);
        await Future<void>.delayed(Duration.zero);
        final said = t.audio.counts.length;
        t.timer.skip();
        expect(t.timer.phase, TimingPhase.work);
        walk(t.at, from + 50, from + 2100);
        await Future<void>.delayed(Duration.zero);
        expect(t.audio.counts.sublist(said), [1, 2, 3], reason: '$from');
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
  });
}

void _countPlan() {
  group('세는 말 고르기', () {
    // Each platform's own rule, apart from the plan (TimingBridge playVoice):
    // a count is first tried 5 ms after its moment (half a beat after its
    // click) and again every 20 ms while the word before sounds; a try at or
    // past the give-up time drops it — a quarter beat after the moment on
    // Android, after the first try on iOS. A word sounds from its start for
    // its audible length on iOS (AVAudioPlayer.duration) and for the file's
    // length on Android (MediaMetadataRetriever, encoder priming included).
    // Returns the counts dropped and the latest start, in ms past a moment.
    ({List<int> dropped, double late}) device(
      String platform,
      String voice,
      int bpm,
      Iterable<int> said,
    ) {
      final period = 60000 / bpm, half = math.min(period / 2, 1000);
      final length = platform == 'ios' ? countVoicePlayMs : countVoiceMs;
      var end = double.negativeInfinity, late = 0.0;
      final dropped = <int>[];
      for (final n in said) {
        final at = (n - 1) * period + half;
        final giveUp = at + period / 4 + (platform == 'ios' ? 5 : 0);
        var tried = at + 5;
        while (tried < end && tried < giveUp) {
          tried += 20;
        }
        if (tried < end) {
          dropped.add(n);
          continue;
        }
        late = math.max(late, tried - at);
        end = tried + length[voice]![n - 1];
      }
      return (dropped: dropped, late: late);
    }

    List<int> plan(String voice, int bpm, int last) =>
        countsSaid(voice, bpm, last).toList()..sort();
    List<int> run(int from, int to, [int step = 1]) => [
      for (var n = from; n <= to; n += step) n,
    ];

    test('고른 숫자는 iOS 도 Android 도 하나도 버리지 않는다 — 모든 템포·목소리·목표', () {
      for (final platform in ['ios', 'android']) {
        for (final voice in ['m', 'w']) {
          for (var bpm = TimingSpec.minBpm; bpm <= TimingSpec.maxBpm; bpm++) {
            for (var last = 1; last <= maxSpokenCount; last++) {
              final said = plan(voice, bpm, last);
              final why = '$platform $voice $bpm bpm to $last';
              expect(said.first, 1, reason: '$why: "One" marks the start');
              expect(said.last, lessThanOrEqualTo(last), reason: why);
              expect(
                device(platform, voice, bpm, said).dropped,
                isEmpty,
                reason: why,
              );
            }
          }
        }
      }
    });

    test('예전처럼 모든 숫자를 보내도 두 기기가 제때(1/4박 − 40ms 안에) 다 읽던 곳은 그대로 박마다 센다', () {
      for (final voice in ['m', 'w']) {
        for (var bpm = TimingSpec.minBpm; bpm <= TimingSpec.maxBpm; bpm++) {
          for (final last in [5, 10, 20, 30, 50, 100]) {
            final every = run(1, last);
            final ok = ['ios', 'android'].every((p) {
              final d = device(p, voice, bpm, every);
              return d.dropped.isEmpty &&
                  d.late <= 60000 / bpm / 4 - countGapMs;
            });
            if (ok) {
              expect(
                plan(voice, bpm, last),
                every,
                reason: '$voice $bpm bpm to $last',
              );
            }
          }
        }
      }
    });

    test('간격은 1 → 2 → 5 → 10 으로 넓어지기만 하고, 넓힌 뒤의 숫자는 그 간격의 배수다', () {
      for (final voice in ['m', 'w']) {
        for (var bpm = TimingSpec.minBpm; bpm <= TimingSpec.maxBpm; bpm++) {
          for (final last in [20, 30, 50, 100]) {
            final said = plan(voice, bpm, last);
            var stride = 1;
            for (var i = 1; i < said.length; i++) {
              final n = said[i], why = '$voice $bpm bpm to $last at $n';
              if (n - said[i - 1] == 1) {
                expect(stride, 1, reason: '$why: back to every beat');
                continue;
              }
              // The narrowest grid at least as wide as before that n is on.
              final grid = [2, 5, 10].where((w) => w >= stride && n % w == 0);
              expect(grid, isNotEmpty, reason: '$why: off the grid');
              stride = grid.first;
            }
          }
        }
      }
    });

    test('자주 쓰는 템포에서 고르는 숫자', () {
      for (final voice in ['m', 'w']) {
        expect(plan(voice, 60, 30), run(1, 30), reason: voice);
        expect(plan(voice, 60, 100), [...run(1, 46), ...run(48, 100, 2)]);
      }
      expect(plan('m', 80, 100), [...run(1, 16), ...run(18, 100, 2)]);
      expect(plan('m', 80, 20), [...run(1, 16), 18, 20]);
      expect(plan('w', 90, 100), [...run(1, 6), ...run(8, 100, 2)]);
      expect(plan('m', 100, 100), [
        ...run(1, 4),
        ...run(6, 74, 2),
        ...run(80, 100, 5),
      ]);
      expect(plan('w', 120, 20), [1, ...run(4, 20, 2)]);
      expect(plan('m', 120, 3), [1, 2]);
    });

    ({WorkoutTimer timer, FakeAudio audio, void Function(int) to}) make({
      String voice = 'm',
    }) {
      var now = Duration.zero;
      final audio = FakeAudio();
      final timer = WorkoutTimer(audio: audio, now: () => now, haptic: (_) {})
        ..countAloud = true
        ..voice = voice;
      return (
        timer: timer,
        audio: audio,
        to: (int ms) {
          for (var t = now.inMilliseconds + 50; t <= ms; t += 50) {
            now = Duration(milliseconds: t);
            timer.tick();
          }
        },
      );
    }

    test('run 하나가 보내는 숫자는 그 run 의 목표까지의 계획 그대로이고, 세는 동안 "Go!" 는 없다', () async {
      // 90 bpm, goal 13: "Thirteen" is the last, so nothing after it to hold
      // up — said, though counting to 100 it is not.
      expect(plan('m', 90, 13), run(1, 13));
      expect(plan('m', 90, 100).take(13), [...run(1, 12), 14]);
      for (final (voice, bpm, goal) in [
        ('m', 90, 13),
        ('m', 80, null),
        ('w', 60, 30),
        ('m', 120, 20),
        ('w', 100, null),
      ]) {
        final t = make(voice: voice);
        t.timer.toggle(Object(), TimingSpec(bpm: bpm), target: goal);
        final beats = goal ?? 105;
        t.to(3000 + (beats + 1) * 60000 ~/ bpm);
        await pumpEventQueue();
        expect(
          t.audio.counts,
          plan(voice, bpm, goal ?? maxSpokenCount),
          reason: '$voice $bpm $goal',
        );
        expect(t.audio.phrases.contains('start'), isFalse);
        t.timer.dispose();
      }
    });

    test('120bpm 에서 박 7 초입에 멈췄다 켜도 7 을 읽지 않고, 박 10 초입이면 10 을 다시 읽는다', () async {
      final t = make();
      const spec = TimingSpec(bpm: 120);
      final block = Object();
      t.timer.toggle(block, spec);
      // Beat 7 starts at 3 s + 6 × 0.5 s; 50 ms in, its count is not due yet.
      t.to(6050);
      await pumpEventQueue();
      t.timer.toggle(block, spec); // pause
      t.timer.toggle(block, spec); // resume: beat 7 is unread, and not said
      await pumpEventQueue();
      expect(t.audio.counts, [1, 2, 4, 6]);
      // Beat 8's count goes out; then 50 ms into beat 10 the pause drops its
      // queued count, and the resume says it again.
      t.to(7450);
      await pumpEventQueue();
      t.to(7550);
      t.timer.toggle(block, spec);
      t.timer.toggle(block, spec);
      t.to(9000);
      await pumpEventQueue();
      expect(t.audio.counts, [1, 2, 4, 6, 8, 10, 12]);
      t.timer.dispose();
    });

    test('박자 타바타는 라운드마다 운동 박자 수까지의 계획으로 다시 센다', () async {
      // 70 bpm, 16 s work: 19 beats, and "Nineteen" ends the work, so it is
      // said, though counting to 100 it is not.
      expect(plan('m', 70, 19), run(1, 19));
      expect(plan('m', 70, 100).contains(19), isFalse);
      final t = make();
      const spec = TimingSpec(tabata: true, bpm: 70, work: 16, rounds: 2);
      t.timer.toggle(Object(), spec);
      t.to(3000 + spec.shownSeconds * 1000 + 500);
      await pumpEventQueue();
      expect(t.audio.log.where((e) => e.startsWith('voice:')), [
        for (final n in run(1, 19)) 'voice:$n',
        'voice:rest',
        for (final n in run(1, 19)) 'voice:$n',
        'voice:done',
      ]);
      t.timer.dispose();
    });
  });
}
