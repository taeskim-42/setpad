import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/health.dart';
import 'package:setpad/rest_recovery.dart';
import 'package:setpad/timing_audio.dart';
import 'package:setpad/workout_timing.dart';

/// 심박을 우리가 밀어 넣는 건강 앱.
class FakeHealth extends HealthLink {
  FakeHealth() : super(platform: TargetPlatform.android);
  final _beats = StreamController<HeartBeat>.broadcast();
  @override
  Stream<HeartBeat> beats({Duration poll = const Duration(seconds: 10)}) =>
      _beats.stream;
  void push(int bpm, DateTime at) =>
      _beats.add((bpm: bpm, at: at, lag: Duration.zero));
}

class SilentAudio extends TimingAudio {
  @override
  Future<void> configure({required bool active, int? bpm, String? cue}) async {}
  @override
  Future<void> speak(String text, String locale) async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHealth health;
  late RestRecovery recovery;
  late DateTime clock;

  setUp(() {
    // 벽시계로 신선도를 보므로 지금을 기준으로 민다.
    clock = DateTime.now();
    health = FakeHealth();
    recovery = RestRecovery(
      health: health,
      drop: 25,
      minimumRest: Duration.zero,
    )..listen();
  });

  tearDown(() => recovery.dispose());

  Future<void> push(int bpm) async {
    clock = clock.add(const Duration(seconds: 1));
    health.push(bpm, clock);
    await Future<void>.delayed(Duration.zero);
  }

  test('최고에서 충분히 내려오면 회복이다', () async {
    recovery.beginRound();
    await push(150);
    recovery.beginRest();
    await push(140);
    expect(recovery.recovered, isFalse, reason: '10 만 내려왔다');
    await push(125);
    expect(recovery.recovered, isTrue, reason: '150-25=125 에 닿았다');
    expect(recovery.peak, 150);
    expect(recovery.target, 125);
  });

  test('휴식이 시작되기 전에는 회복이 아니다', () async {
    recovery.beginRound();
    await push(150);
    await push(100);
    expect(recovery.recovered, isFalse, reason: '아직 세트 중이다');
  });

  test('세트 직후에 더 오른 심박도 기준선이 된다', () async {
    recovery.beginRound();
    await push(150);
    recovery.beginRest();
    await push(160);
    expect(recovery.peak, 160);
    await push(135);
    expect(recovery.recovered, isTrue, reason: '160-25=135');
  });

  test('낡은 값으로는 휴식을 끊지 않는다', () async {
    final old = RestRecovery(
      health: health,
      drop: 25,
      stale: const Duration(seconds: 1),
      minimumRest: Duration.zero,
    )..listen();
    addTearDown(old.dispose);
    old.beginRound();
    health.push(150, DateTime.now().subtract(const Duration(minutes: 10)));
    await Future<void>.delayed(Duration.zero);
    old.beginRest();
    health.push(100, DateTime.now().subtract(const Duration(minutes: 9)));
    await Future<void>.delayed(Duration.zero);
    expect(old.fresh, isFalse);
    expect(old.recovered, isFalse);
  });

  test('심박이 없으면 아무 일도 일어나지 않는다', () {
    recovery.beginRound();
    recovery.beginRest();
    expect(recovery.recovered, isFalse);
    expect(recovery.bpm, isNull);
    expect(recovery.target, isNull);
  });

  test('휴식을 건너뛰면 다음 라운드의 운동으로 간다', () {
    var now = Duration.zero;
    final timer = WorkoutTimer(audio: SilentAudio(), now: () => now);
    addTearDown(timer.dispose);
    const spec = TimingSpec(tabata: true, work: 20, rest: 10, rounds: 8);
    timer.toggle(#block, spec);

    now = const Duration(seconds: 25); // 3 준비 + 20 운동 + 2 휴식
    timer.tick();
    expect(timer.phase, TimingPhase.rest);
    expect(timer.round, 1);

    timer.skipRest();
    expect(timer.phase, TimingPhase.work);
    expect(timer.round, 2);
    expect(timer.remaining, 20, reason: '다음 운동을 처음부터 준다');
  });

  test('운동 중에는 건너뛰지 않는다', () {
    var now = Duration.zero;
    final timer = WorkoutTimer(audio: SilentAudio(), now: () => now);
    addTearDown(timer.dispose);
    timer.toggle(#block, const TimingSpec(tabata: true));
    now = const Duration(seconds: 10);
    timer.tick();
    expect(timer.phase, TimingPhase.work);
    final before = timer.elapsed;
    timer.skipRest();
    expect(timer.elapsed, before, reason: '시계를 건드리지 않는다');
  });
}
