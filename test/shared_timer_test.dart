// 같이 하는 타이머 — 두 폰이 같은 순간에 같은 구간에 있는가.
//
// 시계는 전부 손으로 민다. 서버 시계 하나, 폰마다 출발점이 다른 단조 시계 하나씩.
// 서버의 규칙은 partner_test.dart 의 가짜가 흉내 내고, 진짜 규칙은 gymdojo 의
// partner-sessions.test.ts 가 실제 Postgres 로 지킨다.
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';
import 'package:setpad/shared_timer.dart';
import 'package:setpad/workout_timing.dart';

import 'partner_test.dart' show FakeServer;
import 'workout_timing_test.dart' show FakeAudio;

const tabata = TimingSpec(tabata: true);

/// 온 세상의 시간(ms). 서버도 폰도 이것에서 나온다.
var world = 0;

class Device {
  Device(FakeServer server, this.user, {required int bootedAt}) {
    Duration mono() => Duration(milliseconds: world + bootedAt);
    note = Note(
      id: 'note-$user',
      createdAt: DateTime(2026, 9, 21, 18),
      updatedAt: DateTime(2026, 9, 21, 19),
    );
    sync = PartnerSync(
      note: note,
      clock: ServerClock(monotonic: mono),
      link: () => GymLink(
        endpoint: 'https://x',
        token: user,
        client: server.clientFor(user),
      ),
      onChanged: () {},
    );
    timer = WorkoutTimer(audio: audio, now: mono);
  }
  final String user;
  late final Note note;
  late final PartnerSync sync;
  late final WorkoutTimer timer;
  final audio = FakeAudio();

  SharedTimer? get shared => note.partner?.timer;

  /// 에디터가 하는 일 그대로: 상대 소식을 받고, 내 타이머를 그 자리에 둔다.
  Future<void> poll(Object block) async {
    await sync.refresh();
    final t = shared;
    final at = t?.elapsedAt(sync.clock.now);
    if (t != null && at != null && t.myLeft == null) {
      timer.follow(block, t.personal, at);
    }
    timer.tick();
  }
}

Future<(FakeServer, Device, Device)> pair() async {
  world = 0;
  final server = FakeServer()..now = () => 1700000000000 + world;
  // 두 폰은 켜진 지 서로 다른 만큼 지났다. 단조 시계의 값 자체는 아무 뜻이 없다.
  final mina = Device(server, '미나', bootedAt: 5000);
  final jun = Device(server, '준', bootedAt: 98765432);
  await mina.sync.invite();
  await jun.sync.joinWithCode(mina.note.partner!.code!);
  await mina.sync.refresh();
  return (server, mina, jun);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('서버 시계는 왕복이 짧았던 표본을 믿고, 오래된 표본은 놓아준다', () {
    var mono = Duration.zero;
    final clock = ServerClock(monotonic: () => mono);
    expect(clock.now, isNull, reason: '못 쟀으면 짐작하지 않는다');

    // 보낸 때 1000, 받은 때 1200 — 서버 시각은 그 한가운데(1100)에 찍혔다고 본다.
    clock.sample(
      const Duration(milliseconds: 1000),
      const Duration(milliseconds: 1200),
      501100,
    );
    mono = const Duration(milliseconds: 1500);
    expect(clock.now, 501500);

    // 왕복이 더 긴 표본은 버린다 — 오차가 더 크다.
    clock.sample(
      const Duration(milliseconds: 2000),
      const Duration(milliseconds: 2900),
      999999,
    );
    expect(clock.now, 501500);

    // 더 짧은 표본은 받는다.
    clock.sample(
      const Duration(milliseconds: 3000),
      const Duration(milliseconds: 3040),
      503030,
    );
    mono = const Duration(milliseconds: 4000);
    expect(clock.now, 504010);

    // 10분 지난 표본은 왕복 100ms 만큼 못 미더워져서, 90ms 짜리 새 표본이 이긴다.
    clock.sample(
      const Duration(milliseconds: 603000),
      const Duration(milliseconds: 603090),
      1103050,
    );
    mono = const Duration(milliseconds: 603045);
    expect(clock.now, 1103050);
  });

  test('서버가 준 것이 모양이 틀리면 타이머로 치지 않는다', () {
    Map<String, Object?> json([Map<String, Object?> spec = const {}]) => {
      'seq': 1,
      'title': '버피 타바타',
      'alternate': false,
      'mine': true,
      'startAt': null,
      'spec': {
        'bpm': null,
        'tabata': true,
        'work': 20,
        'rest': 10,
        'rounds': 8,
        ...spec,
      },
    };
    expect(SharedTimer.tryFromJson(json())!.spec, tabata);
    expect(SharedTimer.tryFromJson(json({'work': 0})), isNull);
    expect(SharedTimer.tryFromJson(json({'tabata': false})), isNull);
    expect(SharedTimer.tryFromJson(json({'rounds': '8'})), isNull);
    expect(
      SharedTimer.tryFromJson({...json(), 'startAt': 'soon'})!.started,
      isFalse,
    );
    expect(SharedTimer.tryFromJson(null), isNull);
    // 교대로 늘어난 휴식이 앱이 돌릴 수 없는 길이면 받지 않는다.
    expect(
      SharedTimer.tryFromJson({
        ...json({'work': 300, 'rest': 200}),
        'alternate': true,
      }),
      isNull,
    );
  });

  test('받아들이기 전에는 아무것도 돌지 않고, 받아들이면 두 폰이 같은 자리에 선다', () async {
    final (_, mina, jun) = await pair();
    final a = Object(), b = Object();

    await mina.sync.proposeTimer('버피 타바타', tabata);
    await jun.poll(b);
    expect([mina.shared!.mine, jun.shared!.mine], [true, false]);
    expect([mina.shared!.started, jun.shared!.started], [false, false]);
    expect(jun.timer.running, isFalse, reason: '남이 누른 버튼으로 내 폰이 울리지 않는다');
    expect(jun.shared!.title, '버피 타바타');

    // 제안한 사람이 스스로 받아들일 수는 없다.
    await mina.sync.acceptTimer();
    expect(mina.shared!.started, isFalse);

    await jun.sync.acceptTimer();
    await jun.poll(b);
    // 미나의 폰은 1.7초 뒤의 폴링에서야 안다.
    world += 1700;
    await mina.poll(a);
    await jun.poll(b);
    expect(mina.shared!.startAt, jun.shared!.startAt);
    expect(mina.timer.elapsed, jun.timer.elapsed);
    expect(mina.timer.elapsed, const Duration(milliseconds: -800));
    expect(
      [mina.timer.phase, jun.timer.phase],
      [TimingPhase.ready, TimingPhase.ready],
    );
    expect([mina.timer.remaining, jun.timer.remaining], [4, 4]);

    // 운동 12초째.
    world += 800 + 3000 + 12000;
    await mina.poll(a);
    await jun.poll(b);
    for (final d in [mina, jun]) {
      expect(
        [d.timer.phase, d.timer.round, d.timer.remaining],
        [TimingPhase.work, 1, 8],
      );
    }

    // 3라운드 휴식 중.
    world += 8000 + 10000 + 30000 + 20000 + 4000;
    await mina.poll(a);
    await jun.poll(b);
    for (final d in [mina, jun]) {
      expect(
        [d.timer.phase, d.timer.round, d.timer.remaining],
        [TimingPhase.rest, 3, 6],
      );
    }
    // 같이 하는 동안 나만 휴식을 건너뛸 수는 없다(심박 회복도 마찬가지다).
    jun.timer.skipRest();
    expect(jun.timer.elapsed, mina.timer.elapsed);

    mina.timer.dispose();
    jun.timer.dispose();
  });

  test('늦게 들어온 폰과 앱을 내렸다 올린 폰은 제자리로 돌아오고, 제자리에 있으면 건드리지 않는다', () async {
    final (_, mina, jun) = await pair();
    final a = Object(), b = Object();
    await mina.sync.proposeTimer('버피 타바타', tabata);
    await jun.poll(b);
    await jun.sync.acceptTimer();
    await jun.poll(b);

    // 미나는 화면을 안 보고 있다가 2라운드 운동 5초째에 들어온다.
    world += 2500 + 3000 + 30000 + 5000;
    await mina.poll(a);
    await jun.poll(b);
    expect(
      [mina.timer.phase, mina.timer.round, mina.timer.remaining],
      [TimingPhase.work, 2, 15],
    );
    expect(mina.timer.elapsed, jun.timer.elapsed);

    // 준이 앱을 내렸다(타이머가 멈춘다). 7초 뒤에 돌아온다.
    jun.timer.pause();
    world += 7000;
    expect(jun.timer.elapsed, isNot(mina.timer.elapsed));
    await jun.poll(b);
    expect(jun.timer.running, isTrue);
    expect(jun.timer.elapsed, mina.timer.elapsed);

    // 쉬는 도중에 들어오면 시작 신호를 내지 않는다.
    jun.timer.pause();
    // 소리 명령은 줄을 서서 나간다. 앞의 것이 다 나간 뒤부터 센다.
    await Future<void>.delayed(Duration.zero);
    jun.audio.calls.clear();
    world += 9000; // 2라운드 휴식 1초째
    await jun.poll(b);
    await Future<void>.delayed(Duration.zero);
    expect(jun.timer.phase, TimingPhase.rest);
    expect(jun.audio.calls.where((c) => c.cue == 'work'), isEmpty);

    // 제자리에 있는 타이머는 다시 시작하지 않는다 — 다시 시작하면 소리가 끊긴다.
    final before = jun.audio.calls.length;
    for (var i = 0; i < 5; i++) {
      world += 40;
      await jun.poll(b);
    }
    await Future<void>.delayed(Duration.zero);
    expect(jun.audio.calls.length, before);

    mina.timer.dispose();
    jun.timer.dispose();
  });

  test('교대: 제안한 사람이 먼저 하고, 두 사람의 운동 구간은 겹치지 않는다', () async {
    final (_, mina, jun) = await pair();
    final a = Object(), b = Object();
    await mina.sync.proposeTimer('버피 타바타', tabata, alternate: true);
    await jun.poll(b);
    expect(jun.shared!.alternate, isTrue);
    await jun.sync.acceptTimer();
    await mina.poll(a);
    await jun.poll(b);

    // 내 휴식 = 상대 운동 20 + 자리바꿈 10 × 2.
    expect(mina.shared!.personal.rest, 40);
    world += 2500;
    final working = <String>[];
    for (var second = 0; second < 3 + 60 * 8; second++) {
      await mina.poll(a);
      await jun.poll(b);
      final m = mina.timer.phase == TimingPhase.work;
      final j = jun.timer.phase == TimingPhase.work;
      expect(m && j, isFalse, reason: '$second초에 둘이 같이 운동한다');
      working.add(
        m
            ? 'M'
            : j
            ? 'J'
            : '.',
      );
      world += 1000;
    }
    final line = working.join();
    // 준비 3초, 미나 20초, 바꿈 10초, 준 20초, 바꿈 10초, 다시 미나.
    expect(
      line.substring(0, 70),
      '...${'M' * 20}${'.' * 10}${'J' * 20}${'.' * 10}${'M' * 7}',
    );
    expect('M'.allMatches(line).length, 160);
    // 준의 마지막 라운드는 미나가 끝난 뒤에도 이어진다.
    expect(mina.timer.phase, TimingPhase.complete);
    expect('J'.allMatches(line).length, greaterThan(140));
    // 미나의 첫 운동 동안 준은 "내 차례까지" 를 센다.
    mina.timer.dispose();
    jun.timer.dispose();
  });

  test('그만두는 것은 각자다: 상대는 어디서 멈췄는지 보고, 늦게 온 옛 답이 멈춘 타이머를 되살리지 않는다', () async {
    final (server, mina, jun) = await pair();
    final a = Object(), b = Object();
    const metronome = TimingSpec(bpm: 60);
    await mina.sync.proposeTimer('스쿼트 60bpm', metronome);
    await jun.poll(b);
    await jun.sync.acceptTimer();
    world += 2500 + 3000 + 46500;
    await mina.poll(a);
    await jun.poll(b);
    expect([mina.timer.beat, jun.timer.beat], [47, 47]);

    // 준이 그만둔다. 서버가 느려서 답이 늦는다 — 그 사이 폰은 이미 멈춰 있어야 한다.
    server.delay = const Duration(milliseconds: 50);
    final at = jun.timer.elapsed, beat = jun.timer.beat;
    jun.timer.pause();
    final leaving = jun.sync.leaveTimer(at, beat);
    expect(jun.shared!.myLeft, (ms: 49500, beat: 47));
    await leaving;
    server.delay = Duration.zero;

    world += 2000;
    await jun.poll(b);
    expect(jun.timer.running, isFalse, reason: '그만둔 사람을 다시 끌고 가지 않는다');
    await mina.poll(a);
    expect(mina.shared!.partnerLeft, (ms: 49500, beat: 47));
    expect(mina.timer.running, isTrue, reason: '상대의 타이머는 계속 간다');
    expect(mina.shared!.overAt(mina.sync.clock.now), isFalse);

    // 잘못 눌렀다 — 다시 들어가면 그 자리다.
    await jun.sync.rejoinTimer();
    await jun.poll(b);
    expect(jun.timer.running, isTrue);
    expect(jun.timer.elapsed, mina.timer.elapsed);

    // 둘 다 그만두면 끝난 것이다.
    await jun.sync.leaveTimer(jun.timer.elapsed, jun.timer.beat);
    await mina.sync.leaveTimer(mina.timer.elapsed, mina.timer.beat);
    await jun.sync.refresh();
    expect(jun.shared!.overAt(jun.sync.clock.now), isTrue);

    // 새 제안은 앞의 것을 갈아 치운다. 어느 쪽이든 치울 수 있다.
    await jun.sync.proposeTimer('버피 타바타', tabata);
    await mina.sync.refresh();
    expect(
      [mina.shared!.seq, mina.shared!.mine, mina.shared!.started],
      [2, false, false],
    );
    await mina.sync.clearTimer();
    await jun.sync.refresh();
    expect(jun.shared, isNull);

    mina.timer.dispose();
    jun.timer.dispose();
  });

  group('타이머 칸', () {
    Future<void> mount(
      WidgetTester tester,
      WorkoutTimer timer,
      Object owner,
      TimingSpec spec,
      TogetherTiming? together,
    ) => tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: L.localizationsDelegates,
        home: CupertinoPageScaffold(
          child: SafeArea(
            child: WorkoutTimingControls(
              owner: owner,
              spec: spec,
              timer: timer,
              onStart: () {},
              onChanged: (_) {},
              together: together,
            ),
          ),
        ),
      ),
    );

    testWidgets('같이 운동 중이 아니면 예전 그대로다', (tester) async {
      final timer = WorkoutTimer(audio: FakeAudio());
      await mount(tester, timer, Object(), tabata, null);
      expect(find.text('같이 시작'), findsNothing);
      expect(find.text('시작'), findsOneWidget);
      timer.dispose();
    });

    testWidgets('제안 → 기다림 → 같이 하는 중의 버튼과 말', (tester) async {
      final timer = WorkoutTimer(audio: FakeAudio());
      final owner = Object();
      final proposed = <bool>[];
      var cancelled = 0;
      TogetherTiming duo({bool waiting = false}) => TogetherTiming(
        partner: '미나',
        waiting: waiting,
        onPropose: proposed.add,
        onToggle: () => false,
        onCancel: () => cancelled++,
        onLog: (_) {},
      );

      await mount(tester, timer, owner, tabata, duo());
      await tester.tap(find.text('같이 시작'));
      await tester.tap(find.text('교대로'));
      expect(proposed, [false, true]);

      // 박자만 있는 운동에는 번갈아 할 구간이 없다.
      await mount(tester, timer, owner, const TimingSpec(bpm: 60), duo());
      expect(find.text('같이 시작'), findsOneWidget);
      expect(find.text('교대로'), findsNothing);

      await mount(tester, timer, owner, tabata, duo(waiting: true));
      expect(find.text('미나 님을 기다리는 중…'), findsOneWidget);
      expect(find.text('같이 시작'), findsNothing);
      await tester.tap(find.text('취소'));
      expect(cancelled, 1);
      timer.dispose();
    });

    testWidgets('쉬는 동안 방금 라운드를 한 번에 적고, 나와 상대의 횟수가 나란히 보인다', (tester) async {
      var now = Duration.zero;
      final timer = WorkoutTimer(audio: FakeAudio(), now: () => now);
      final owner = Object();
      final logged = <int>[];
      var toggles = 0;
      TogetherTiming duo({
        List<int?> mine = const [],
        bool left = false,
        String? gone,
      }) => TogetherTiming(
        partner: '미나',
        live: true,
        left: left,
        partnerLeft: gone,
        mine: mine,
        theirs: const [14, null, 9],
        onPropose: (_) {},
        onToggle: () {
          toggles++;
          return true;
        },
        onCancel: () {},
        onLog: logged.add,
      );

      // 1라운드 운동 중: 적을 것이 아직 없다.
      timer.follow(owner, tabata, const Duration(seconds: 10));
      await mount(tester, timer, owner, tabata, duo());
      expect(find.byKey(const ValueKey('together-log')), findsNothing);
      expect(find.text('그만'), findsOneWidget);
      // 표에 상대 이름이 이미 있으면 "같이" 를 또 적지 않는다.
      expect(find.text('미나 님과 같이'), findsNothing);
      expect(find.text('–  –  –'), findsOneWidget, reason: '내 줄은 아직 비어 있다');

      // 1라운드 휴식: 상대의 마지막 숫자(9)에서 시작해 한 번 올리고 적는다.
      now = const Duration(seconds: 15);
      timer.tick();
      await tester.pump();
      expect(find.byKey(const ValueKey('together-count')), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      await tester.tap(find.byIcon(CupertinoIcons.plus_circle));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('together-log')));
      expect(logged, [10]);

      // 적고 나면 칸이 사라지고, 안 적은 세트는 0 이 아니라 – 다.
      await mount(tester, timer, owner, tabata, duo(mine: [10]));
      expect(find.byKey(const ValueKey('together-log')), findsNothing);
      expect(find.text('10  –  –'), findsOneWidget);
      expect(find.text('14  –  9'), findsOneWidget);

      // 같이 하는 동안 시작·정지는 그만두기다 — 타이머를 혼자 멈추거나 되감지 않는다.
      await tester.tap(find.text('그만'));
      expect(toggles, 1);
      expect(timer.running, isTrue);

      await mount(
        tester,
        timer,
        owner,
        tabata,
        duo(left: true, gone: '미나 님은 3라운드에서 멈춤'),
      );
      expect(find.text('다시 들어가기'), findsOneWidget);
      expect(find.text('미나 님은 3라운드에서 멈춤'), findsOneWidget);
      timer.dispose();
    });
  });

  group('에디터', () {
    Future<void> mountEditor(
      WidgetTester tester,
      Device device,
      RoutineEditorController c,
    ) async {
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          supportedLocales: L.supportedLocales,
          localizationsDelegates: L.localizationsDelegates,
          home: CupertinoPageScaffold(
            resizeToAvoidBottomInset: false,
            child: SafeArea(
              child: RoutineEditor(
                controller: c,
                partner: device.sync,
                timer: device.timer,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    String typed(WidgetTester tester) => tester
        .widget<CupertinoTextField>(find.byType(CupertinoTextField).first)
        .controller!
        .text
        .replaceAll(String.fromCharCode(0x200B), '');

    testWidgets('상대의 제안을 받아도 치던 것은 그대로고, 받으면 내 칸이 생겨 같은 자리에서 돈다', (
      tester,
    ) async {
      final (_, mina, jun) = await pair();
      final c = RoutineEditorController()..addExercise('벤치프레스');
      await mountEditor(tester, jun, c);
      tester.widget<SetKeypad>(find.byType(SetKeypad)).onKey('62.5');
      await tester.pump();
      expect(typed(tester), '62.5');

      await mina.sync.proposeTimer('버피 타바타 20/10 x8', tabata);
      await jun.sync.refresh();
      await tester.pump();
      expect(find.byKey(const ValueKey('together-invite')), findsOneWidget);
      expect(find.text('미나 님이 같이 하자고 합니다'), findsOneWidget);
      expect(jun.timer.running, isFalse);
      expect(c.blocks.length, 1, reason: '받기 전에는 내 기록에 아무것도 생기지 않는다');

      await tester.tap(find.byKey(const ValueKey('together-accept')));
      await tester.pump();
      await jun.sync.refresh();
      await tester.pump();
      expect(c.blocks.map((b) => b.name), ['벤치프레스', '버피 타바타 20/10 x8']);
      expect(c.activeIndex, 0, reason: '커서는 치던 칸에 그대로다');
      expect(typed(tester), '62.5', reason: '치던 글이 사라지면 안 된다');
      expect(find.byKey(const ValueKey('together-invite')), findsNothing);
      expect(jun.timer.running && jun.timer.shared, isTrue);
      expect(identical(jun.timer.owner, c.blocks[1]), isTrue);

      // 미나의 폰도 같은 자리다.
      world += 2500 + 3000 + 4000;
      await mina.poll(Object());
      await jun.sync.refresh();
      await tester.pump();
      expect(jun.timer.elapsed, mina.timer.elapsed);
      expect(jun.timer.phase, TimingPhase.work);

      // 쉬는 구간에 한 번 눌러 적으면 내 기록에 세트로 남는다.
      world += 17000;
      jun.timer.tick();
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('together-log')));
      await tester.tap(find.byKey(const ValueKey('together-log')));
      await tester.pump();
      expect(c.blocks[1].sets.single.reps, 10);
      expect(c.blocks[0].sets, isEmpty);
      expect(typed(tester), '62.5');

      // 상대가 치우면 내 타이머도 선다.
      await mina.sync.clearTimer();
      await jun.sync.refresh();
      await tester.pump();
      expect(jun.timer.running, isFalse);
      expect(c.blocks[1].sets.single.reps, 10, reason: '기록은 남는다');

      await tester.pumpWidget(const SizedBox());
      mina.timer.dispose();
      jun.timer.dispose();
    });

    testWidgets('내가 제안하고, 그만두면 상대가 알고, 같이 돌리던 칸을 지워도 말없이 사라지지 않는다', (
      tester,
    ) async {
      final (_, mina, jun) = await pair();
      final c = RoutineEditorController()
        ..addExercise('스쿼트 60bpm')
        ..closeBlock();
      await mountEditor(tester, mina, c);

      await tester.tap(find.byKey(const ValueKey('together-start')));
      await tester.pump();
      await mina.sync.refresh();
      await tester.pump();
      expect(find.text('준 님을 기다리는 중…'), findsOneWidget);
      expect(mina.timer.running, isFalse, reason: '상대가 받기 전에는 돌지 않는다');

      await jun.sync.refresh();
      expect(jun.shared!.title, '스쿼트 60bpm');
      await jun.sync.acceptTimer();
      world += 2500 + 3000 + 46500;
      await mina.sync.refresh();
      await tester.pump();
      expect(mina.timer.running && mina.timer.shared, isTrue);
      expect(mina.timer.beat, 47);
      expect(find.text('준 님과 같이'), findsOneWidget);

      await tester.tap(find.text('그만'));
      await tester.pump();
      expect(mina.timer.running, isFalse);
      await jun.sync.refresh();
      expect(jun.shared!.partnerLeft, (ms: 49500, beat: 47));
      // 다음 소식이 와도 그만둔 사람을 다시 끌고 가지 않는다.
      await mina.sync.refresh();
      await tester.pump();
      expect(mina.timer.running, isFalse);
      expect(find.text('다시 들어가기'), findsOneWidget);

      world += 5000;
      await tester.tap(find.text('다시 들어가기'));
      await tester.pump();
      await mina.sync.refresh();
      await tester.pump();
      expect(mina.timer.running, isTrue);
      expect(mina.timer.beat, 52);

      // 같이 돌리던 칸을 지운다 — 상대에게는 빠졌다고 알린다.
      c.removeBlock(0);
      await tester.pump();
      await jun.sync.refresh();
      expect(jun.shared!.partnerLeft, isNotNull);
      expect(mina.timer.running, isFalse);

      await tester.pumpWidget(const SizedBox());
      mina.timer.dispose();
      jun.timer.dispose();
    });
  });
}
