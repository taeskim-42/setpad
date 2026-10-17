// 카드 띠·편집기 연결 — 대기·도는 중(접힘)·완료 세 상태, 같이 ▾, 다른 칸 시작 확인,
// 권한 시점, 무대 열기, 라운드 세트 적기, 후보 막대·⋯ 칩 진입, 심박 폴링 수명주기.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/rest_recovery.dart';
import 'package:setpad/run_link.dart';
import 'package:setpad/run_page.dart';
import 'package:setpad/setup_chips.dart';
import 'package:setpad/timer_sheet.dart';
import 'package:setpad/timer_strip.dart';
import 'package:setpad/workout_timing.dart';

import 'rest_recovery_test.dart' show FakeHealth;
import 'routine_fixture.dart' show methodPlan;
import 'workout_timing_test.dart' show FakeAudio;

Widget app(
  Widget child, {
  Locale locale = const Locale('ko'),
  double scale = 1,
}) => CupertinoApp(
  locale: locale,
  supportedLocales: L.supportedLocales,
  localizationsDelegates: L.localizationsDelegates,
  builder: (context, inner) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: inner!,
  ),
  home: CupertinoPageScaffold(
    resizeToAvoidBottomInset: false,
    child: SafeArea(child: child),
  ),
);

String stripNumber(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('timer-strip-number'))).data!;

/// The stage's link, while the stage is open.
RunLink stageLink(WidgetTester tester) =>
    tester.widget<RunPage>(find.byType(RunPage)).link;

Future<void> fold(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(RunPage))).pop();
  await tester.pumpAndSettle();
}

void main() {
  late Duration now;
  late WorkoutTimer timer;
  setUp(() {
    now = Duration.zero;
    timer = WorkoutTimer(audio: FakeAudio(), now: () => now, haptic: (_) {});
  });
  tearDown(() => timer.dispose());

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    timer.reset(); // cancels the ticker before the pending-timer check
  }

  Future<void> advance(WidgetTester tester, Duration to) async {
    now = to;
    timer.tick();
    await tester.pump();
  }

  testWidgets('대기: 의미 없는 "준비 · 1/8" 대신 설정 요약과 시작 알약, 카드는 예전보다 낮다; '
      '시작하면 권한을 무대 전에 한 번 묻고, 접으면 라이브 숫자', (tester) async {
    final c = RoutineEditorController()
      ..addExercise('버피 타바타')
      ..closeBlock();
    final asked = <bool>[];
    await tester.pumpWidget(
      app(
        RoutineEditor(
          controller: c,
          timer: timer,
          askTimerPermissions: () async =>
              asked.add(find.byType(RunPage).evaluate().isNotEmpty),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('운동 20초 · 휴식 10초 × 8 · 3:50'), findsOneWidget);
    expect(find.textContaining('준비'), findsNothing);
    // The old row was 4 + 44 + 6.
    expect(
      tester.getSize(find.byType(TimerStrip)).height,
      lessThanOrEqualTo(54),
    );

    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    expect(asked, [false], reason: 'asked once, before the stage opened');
    expect(timer.running, isTrue);
    expect(find.byType(RunPage), findsOneWidget);
    expect(stageLink(tester).title, '버피');

    await fold(tester);
    expect(timer.running, isTrue, reason: 'folding keeps it going');
    expect(stripNumber(tester), '3');
    expect(find.text('준비 · R 1/8'), findsOneWidget);
    await advance(tester, const Duration(seconds: 3));
    expect(stripNumber(tester), '20');
    expect(find.text('운동 · R 1/8'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('timer-strip-pause')));
    await tester.pump();
    expect(timer.running, isFalse);
    expect(find.text('일시정지 · R 1/8'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('timer-strip-open')));
    await tester.pumpAndSettle();
    expect(find.byType(RunPage), findsOneWidget);
    await fold(tester);

    // From the top again: no second permission prompt.
    timer.reset();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    expect(asked, hasLength(1));
    await fold(tester);

    // Renaming away the timer clears the running one.
    c.renameBlock(0, '버피');
    await tester.pump();
    expect(find.byType(TimerStrip), findsNothing);
    expect(timer.running, isFalse);
    expect(timer.spec, isNull);
    await finish(tester);
  });

  testWidgets(
    'Android: 첫 run 전에 알림 권한을 한 번 묻는다(run 화면이 뜨기 전, 편집기 안에서), iOS 는 여기서 묻지 않는다',
    (tester) async {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = platform;
        final c = RoutineEditorController()
          ..addExercise('버피 타바타')
          ..closeBlock();
        final asked = <bool>[];
        await tester.pumpWidget(
          app(
            RoutineEditor(
              key: ValueKey(platform),
              controller: c,
              timer: timer,
              askTimerPermissions: () async {},
              askRestNotify: () async =>
                  asked.add(find.byType(RunPage).evaluate().isNotEmpty),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('timer-start')));
        await tester.pumpAndSettle();
        expect(timer.running, isTrue);
        await fold(tester);
        timer.reset();
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('timer-start')));
        await tester.pumpAndSettle();
        await fold(tester);
        expect(
          asked,
          platform == TargetPlatform.android ? [false] : isEmpty,
          reason: '$platform: once, in the editor before RunPage opened',
        );
        timer.reset();
        await tester.pumpWidget(const SizedBox());
        debugDefaultTargetPlatformOverride = null;
      }
      await finish(tester);
    },
  );

  testWidgets('라운드 세트는 같은 세트를 고치고, 비우면 지우고, 박자는 센 수로 한 세트; 다른 run 이면 새로', (
    tester,
  ) async {
    final c = RoutineEditorController()
      ..addExercise('버피 타바타')
      ..closeBlock();
    await tester.pumpWidget(
      app(
        RoutineEditor(
          controller: c,
          timer: timer,
          askTimerPermissions: () async {},
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    final link = stageLink(tester);
    final block = c.blocks.single;
    await advance(tester, const Duration(seconds: 24));
    link.onLogRound!(1, 12);
    expect(block.sets.single.reps, 12);
    final id = block.sets.single.id;
    link.onLogRound!(1, 13);
    expect(block.sets.single.reps, 13);
    expect(block.sets.single.id, id, reason: 'fixed in place');
    link.onLogRound!(3, 9);
    expect(link.roundReps, [13, null, 9]);
    link.onClearRound!(3);
    expect(block.sets.map((s) => s.reps), [13]);
    expect(link.roundReps, [13, null, null]);

    // Restart: a new run's round 1 is a new set.
    timer.restart();
    await tester.pump();
    expect(link.roundReps, isEmpty);
    await advance(tester, const Duration(seconds: 48));
    link.onLogRound!(1, 10);
    expect(block.sets.map((s) => s.reps), [13, 10]);
    await fold(tester);
    await finish(tester);
  });

  testWidgets('요약 [N세트 적기] 는 고르지 않은 라운드도 reps:null 세트로 남기고(N = 생긴 세트), '
      '비우기는 이미 적은 라운드의 세트를 지운다', (tester) async {
    final c = RoutineEditorController()
      ..addExercise('버피 타바타 5/5 x2')
      ..closeBlock();
    await tester.pumpWidget(
      app(
        RoutineEditor(
          controller: c,
          timer: timer,
          askTimerPermissions: () async {},
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    final block = c.blocks.single;
    await advance(tester, const Duration(seconds: 10)); // round 1 rest
    await tester.tap(find.byKey(const ValueKey('together-log')));
    await tester.pump();
    expect(block.sets.map((s) => s.reps), [10]);
    await advance(tester, const Duration(seconds: 18));
    expect(timer.phase, TimingPhase.complete);
    await tester.pumpAndSettle();
    expect(find.text('1R 10'), findsOneWidget);
    expect(find.text('1세트 적기'), findsOneWidget);
    // Clear the logged round: its set goes, the round is owed again.
    await tester.tap(find.byKey(const ValueKey('run-round-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('count-sheet-clear')));
    await tester.pumpAndSettle();
    expect(block.sets, isEmpty);
    expect(find.text('1R –'), findsOneWidget);
    expect(find.text('2세트 적기'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('run-log')));
    await tester.pumpAndSettle();
    expect(find.byType(RunPage), findsNothing);
    expect(block.sets.map((s) => s.reps), [null, null], reason: '2 = 2');
    expect(find.byKey(const ValueKey('timer-log-now')), findsNothing);
    await finish(tester);
  });

  testWidgets('« 로 준비 구간까지 되감아도 같은 run 이다 — 적은 라운드를 다시 적게 하지 않는다', (
    tester,
  ) async {
    final c = RoutineEditorController()
      ..addExercise('버피 타바타')
      ..closeBlock();
    await tester.pumpWidget(
      app(
        RoutineEditor(
          controller: c,
          timer: timer,
          askTimerPermissions: () async {},
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    final link = stageLink(tester);
    await advance(tester, const Duration(seconds: 24)); // round 1 rest
    await tester.tap(find.byKey(const ValueKey('together-log')));
    await tester.pump();
    timer.back(); // rest -> round 1 work
    timer.back(); // round 1 work -> ready
    await tester.pump();
    expect(timer.phase, TimingPhase.ready);
    expect(link.roundReps, [10], reason: 'the same run');
    await advance(tester, const Duration(seconds: 48)); // round 1 rest again
    expect(timer.phase, TimingPhase.rest);
    expect(find.byKey(const ValueKey('together-log')), findsNothing);
    expect(find.text('10회 적었어요'), findsNWidgets(2));
    link.onLogRound!(1, 11);
    expect(c.blocks.single.sets.map((s) => s.reps), [11], reason: 'fixed');
    await fold(tester);
    await finish(tester);
  });

  testWidgets('완료하면 카드에 "완료 · 8라운드 · 3:50 [적기 ▸][↺]", 적기는 무대 요약, ↺ 는 대기', (
    tester,
  ) async {
    final c = RoutineEditorController()
      ..addExercise('버피 타바타')
      ..closeBlock();
    await tester.pumpWidget(
      app(
        RoutineEditor(
          controller: c,
          timer: timer,
          askTimerPermissions: () async {},
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    await fold(tester);
    await advance(tester, const Duration(seconds: 233));
    expect(timer.phase, TimingPhase.complete);
    expect(find.text('완료 · 8라운드 · 3:50'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('timer-log-now')));
    await tester.pumpAndSettle();
    expect(find.byType(RunPage), findsOneWidget);
    // The summary logged everything: the strip stops asking.
    final link = stageLink(tester);
    for (var r = 1; r <= 8; r++) {
      link.onLogRound!(r, 10);
    }
    link.onLogged!();
    await tester.pumpAndSettle();
    expect(find.byType(RunPage), findsNothing);
    expect(c.blocks.single.sets, hasLength(8));
    expect(find.byKey(const ValueKey('timer-log-now')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('timer-reset')));
    await tester.pump();
    expect(find.byKey(const ValueKey('timer-start')), findsOneWidget);
    await finish(tester);
  });

  testWidgets('다른 칸의 시작: 도는 타이머는 묻고 멈추며, 적지 않은 라운드는 먼저 적게 한다', (tester) async {
    final c = RoutineEditorController()
      ..addExercise('버피 타바타')
      ..closeBlock()
      ..addExercise('스쿼트 타바타')
      ..closeBlock();
    await tester.pumpWidget(
      app(
        RoutineEditor(
          controller: c,
          timer: timer,
          askTimerPermissions: () async {},
        ),
      ),
    );
    final starts = find.byKey(const ValueKey('timer-start'));
    await tester.tap(starts.first);
    await tester.pumpAndSettle();
    await fold(tester);
    expect(identical(timer.owner, c.blocks[0]), isTrue);

    await tester.tap(starts.last);
    await tester.pumpAndSettle();
    expect(find.text('도는 타이머를 멈추고 이것을 시작할까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(identical(timer.owner, c.blocks[0]), isTrue);
    expect(timer.running, isTrue);
    await tester.tap(starts.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('멈추고 시작'));
    await tester.pumpAndSettle();
    expect(identical(timer.owner, c.blocks[1]), isTrue);
    expect(timer.running, isTrue);
    await fold(tester);

    // Finish the second one without logging, then start the first.
    await advance(tester, const Duration(seconds: 233));
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    expect(find.text('적지 않은 8라운드가 있어요'), findsOneWidget);
    await tester.tap(find.text('먼저 적기'));
    await tester.pumpAndSettle();
    expect(find.byType(RunPage), findsOneWidget);
    expect(identical(timer.owner, c.blocks[1]), isTrue);
    await fold(tester);
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('버리고 시작'));
    await tester.pumpAndSettle();
    expect(identical(timer.owner, c.blocks[0]), isTrue);
    expect(timer.running, isTrue);
    await fold(tester);
    await finish(tester);
  });

  testWidgets('적지 않은 박자도 다른 칸 ▶ 에서 묻는다(카드 [적기] 와 같은 규칙) — "적지 않은 18회"', (
    tester,
  ) async {
    final c = RoutineEditorController()
      ..addExercise('푸시업 60bpm')
      ..closeBlock()
      ..addExercise('버피 타바타')
      ..closeBlock();
    await tester.pumpWidget(
      app(
        RoutineEditor(
          controller: c,
          timer: timer,
          askTimerPermissions: () async {},
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('timer-start')).first);
    await tester.pumpAndSettle();
    now = const Duration(seconds: 20);
    timer.tick();
    timer.end();
    await tester.pumpAndSettle();
    await fold(tester);
    expect(timer.count, 18);
    expect(find.byKey(const ValueKey('timer-log-now')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    expect(find.text('적지 않은 18회가 있어요'), findsOneWidget);
    await tester.tap(find.text('먼저 적기'));
    await tester.pumpAndSettle();
    expect(find.byType(RunPage), findsOneWidget);
    expect(identical(timer.owner, c.blocks[0]), isTrue);
    await tester.tap(find.byKey(const ValueKey('run-log')));
    await tester.pumpAndSettle();
    expect(c.blocks[0].sets.single.reps, 18);
    // Logged: nothing left to ask about.
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoActionSheet), findsNothing);
    expect(identical(timer.owner, c.blocks[1]), isTrue);
    await fold(tester);
    await finish(tester);
  });

  testWidgets('권한을 묻는 동안 ▶ 을 또 눌러도 한 번만 시작한다(일시정지로 뒤집히지 않음)', (tester) async {
    final gate = Completer<void>();
    final c = RoutineEditorController()
      ..addExercise('버피 타바타')
      ..closeBlock();
    await tester.pumpWidget(
      app(
        RoutineEditor(
          controller: c,
          timer: timer,
          askTimerPermissions: () => gate.future,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();
    expect(timer.running, isTrue);
    expect(find.byType(RunPage), findsOneWidget);
    await fold(tester);
    await finish(tester);
  });

  for (final paused in [true, false]) {
    testWidgets(
      '${paused ? '멈춘' : '적지 않고 끝난'} run 이 있는 칸의 시트는 읽기 전용이고 까닭을 말한다',
      (tester) async {
        final c = RoutineEditorController()
          ..addExercise('버피 타바타')
          ..closeBlock();
        await tester.pumpWidget(
          app(
            RoutineEditor(
              controller: c,
              timer: timer,
              askTimerPermissions: () async {},
            ),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('timer-start')));
        await tester.pumpAndSettle();
        await fold(tester);
        await advance(tester, Duration(seconds: paused ? 100 : 233));
        if (paused) {
          timer.pause();
          await tester.pump();
        }
        Future<TimerSheet> openSheet() async {
          if (find.byKey(const ValueKey('setup-timer')).evaluate().isEmpty) {
            await tester.tap(
              find.byKey(ValueKey('exercise-settings-${c.blocks.single.id}')),
            );
            await tester.pumpAndSettle();
          }
          await tester.tap(find.byKey(const ValueKey('setup-timer')));
          await tester.pumpAndSettle();
          return tester.widget<TimerSheet>(find.byType(TimerSheet));
        }

        expect((await openSheet()).readOnly, isTrue);
        expect(
          find.text(paused ? '멈춘 뒤 바꿀 수 있어요' : '적지 않은 8라운드가 있어요'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('timer-beat')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('timer-sheet-done')));
        await tester.pumpAndSettle();
        expect(c.blocks.single.name, '버피 타바타');
        expect(identical(timer.owner, c.blocks.single), isTrue);
        if (paused) {
          expect(timer.elapsed, greaterThan(Duration.zero));
        } else {
          expect(find.text('완료 · 8라운드 · 3:50'), findsOneWidget);
          // Logged: nothing is lost any more, the sheet may change it.
          await tester.tap(find.byKey(const ValueKey('timer-log-now')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('run-log')));
          await tester.pumpAndSettle();
          expect(c.blocks.single.sets, hasLength(8));
          expect((await openSheet()).readOnly, isFalse);
          await tester.tap(find.byKey(const ValueKey('timer-sheet-done')));
          await tester.pumpAndSettle();
        }
        await finish(tester);
      },
    );
  }

  group('같이 하기', () {
    Future<void> mount(
      WidgetTester tester,
      TimingSpec spec,
      TogetherTiming? together, {
      VoidCallback? onStart,
    }) => tester.pumpWidget(
      app(
        TimerStrip(
          owner: 'card',
          spec: spec,
          timer: timer,
          link: RunLink(timer),
          together: together,
          onStart: onStart ?? () {},
          onOpen: () {},
          onEdit: () {},
        ),
      ),
    );

    testWidgets('같이 운동 중이 아니면 시작 하나다', (tester) async {
      var started = 0;
      await mount(tester, tabata, null, onStart: () => started++);
      expect(find.text('같이'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('timer-start')));
      expect(started, 1);
    });

    testWidgets('세션 중: 혼자 시작과 같이 ▾ — 액션시트, 박자만이면 바로, 기다림·취소, busy', (
      tester,
    ) async {
      final proposed = <bool>[];
      var cancelled = 0, started = 0;
      TogetherTiming duo({bool waiting = false, bool busy = false}) =>
          TogetherTiming(
            partner: '미나',
            waiting: waiting,
            busy: busy,
            onPropose: proposed.add,
            onCancel: () => cancelled++,
          );

      await mount(tester, tabata, duo(), onStart: () => started++);
      expect(find.byKey(const ValueKey('timer-start')), findsOneWidget);
      expect(find.text('같이'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('together-start')));
      await tester.pumpAndSettle();
      expect(proposed, isEmpty);
      await tester.tap(find.byKey(const ValueKey('together-simultaneous')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('together-start')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('together-alternate')));
      await tester.pumpAndSettle();
      expect(proposed, [false, true]);
      expect(timer.running, isFalse, reason: 'proposing never starts alone');
      await tester.tap(find.byKey(const ValueKey('timer-start')));
      expect(started, 1, reason: 'starting alone always works');

      // A metronome has no turns to alternate.
      await mount(tester, const TimingSpec(bpm: 60), duo());
      await tester.tap(find.byKey(const ValueKey('together-start')));
      await tester.pump();
      expect(proposed, [false, true, false]);
      expect(find.byType(CupertinoActionSheet), findsNothing);

      await mount(tester, tabata, duo(waiting: true));
      expect(find.text('미나 님을 기다리는 중…'), findsOneWidget);
      expect(find.byKey(const ValueKey('timer-start')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('together-cancel')));
      expect(cancelled, 1);

      // Together on another card: no new proposal here.
      await mount(tester, tabata, duo(busy: true));
      expect(find.byKey(const ValueKey('together-start')), findsNothing);
      expect(find.byKey(const ValueKey('timer-start')), findsOneWidget);
    });
  });

  testWidgets('세 상태가 320pt × 글자 1.0/2.0 × ko·en·es·th·vi 에서 넘치지 않는다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const spec = TimingSpec(tabata: true, bpm: 100, work: 45, rest: 15);
    final duo = TogetherTiming(
      partner: 'Mina',
      onPropose: (_) {},
      onCancel: () {},
    );
    for (final lang in ['ko', 'en', 'es', 'th', 'vi']) {
      for (final scale in [1.0, 2.0]) {
        Future<void> show() async {
          final state = timer.phase.name;
          await tester.pumpWidget(
            app(
              TimerStrip(
                owner: 'card',
                spec: spec,
                timer: timer,
                link: RunLink(timer),
                target: 30,
                together: duo,
                onStart: () {},
                onOpen: () {},
                onEdit: () {},
              ),
              locale: Locale(lang),
              scale: scale,
            ),
          );
          expect(tester.takeException(), isNull, reason: '$lang $scale $state');
        }

        timer.reset();
        now = Duration.zero;
        await show();
        timer.toggle('card', spec);
        await advance(tester, const Duration(seconds: 70));
        await show();
        await advance(tester, Duration(seconds: spec.duration));
        expect(timer.phase, TimingPhase.complete);
        await show();
      }
    }
    await finish(tester);
  });

  testWidgets('빈 입력 줄의 [타바타]·[박자] 칩은 locale 이름의 칸을 만들고 시트를 연다', (tester) async {
    for (final (lang, word) in [
      ('ko', '타바타'),
      ('ja', 'タバタ'),
      ('en', 'Tabata'),
    ]) {
      final c = RoutineEditorController();
      await tester.pumpWidget(
        app(
          RoutineEditor(key: UniqueKey(), controller: c, timer: timer),
          locale: Locale(lang),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('candidate-tabata')));
      await tester.pumpAndSettle();
      expect(c.blocks.single.name, word);
      expect(find.byType(TimerSheet), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('timer-sheet-done')));
      await tester.pumpAndSettle();
      expect(c.blocks.single.name, word);
      expect(c.recentExercises, isEmpty, reason: 'a placeholder, not a name');
    }
    final c = RoutineEditorController();
    await tester.pumpWidget(
      app(RoutineEditor(key: UniqueKey(), controller: c, timer: timer)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('candidate-beat')));
    await tester.pumpAndSettle();
    expect(c.blocks.single.name, '60bpm');
    expect(TimingSpec.parse(c.blocks.single.name)!.bpm, 60);
    await tester.tap(find.byKey(const ValueKey('timer-sheet-done')));
    await tester.pumpAndSettle();
    expect(c.recentExercises, isEmpty);
    expect(find.byType(SetKeypad), findsOneWidget, reason: 'sets go in next');
    // Typed text hides the chips (the name line is not empty any more).
    await finish(tester);
  });

  testWidgets('⋯ 설정 칩 줄의 [+ 타이머] 칩 → 시트 → 박자를 켜면 제목에 붙고 띠가 생긴다', (
    tester,
  ) async {
    final c = RoutineEditorController()
      ..addExercise('푸시업')
      ..closeBlock();
    await tester.pumpWidget(app(RoutineEditor(controller: c, timer: timer)));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('exercise-settings-${c.blocks.single.id}')),
    );
    await tester.pumpAndSettle();
    expect(find.text('+ 타이머'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('setup-timer')));
    await tester.pumpAndSettle();
    expect(find.byType(TimerSheet), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('timer-beat')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('timer-sheet-done')));
    await tester.pumpAndSettle();
    expect(c.blocks.single.name, '푸시업 60bpm');
    expect(find.byType(TimerStrip), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('timer-summary')),
        matching: find.text('60 BPM'),
      ),
      findsOneWidget,
    );
    await finish(tester);
  });

  testWidgets('⋯ 칩 줄에서 연 타이머 시트를 닫으면(완료든 취소든) 칩 줄과 키패드가 그대로다', (tester) async {
    final c = RoutineEditorController()..addExercise('푸시업');
    await tester.pumpWidget(app(RoutineEditor(controller: c, timer: timer)));
    await tester.pumpAndSettle();
    expect(find.byType(SetKeypad), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey('exercise-settings-${c.blocks.single.id}')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SetupChips), findsOneWidget);
    for (final close in ['timer-sheet-done', null]) {
      await tester.tap(find.byKey(const ValueKey('setup-timer')));
      await tester.pumpAndSettle();
      expect(find.byType(TimerSheet), findsOneWidget);
      if (close == null) {
        await tester.tapAt(const Offset(10, 10)); // the barrier
      } else {
        await tester.tap(find.byKey(ValueKey(close)));
      }
      await tester.pumpAndSettle();
      expect(find.byType(TimerSheet), findsNothing);
      expect(find.byType(SetupChips), findsOneWidget, reason: '$close');
      expect(find.byType(SetKeypad), findsOneWidget, reason: '$close');
    }
    await finish(tester);
  });

  testWidgets('Android: 심박 폴링은 앱이 앞에 있을 때만 돈다', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final health = FakeHealth();
    final recovery = RestRecovery(health: health);
    final c = RoutineEditorController()
      ..addExercise('버피 타바타')
      ..closeBlock();
    await tester.pumpWidget(
      app(
        RoutineEditor(
          controller: c,
          timer: timer,
          recovery: recovery,
          askTimerPermissions: () async {},
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    await advance(tester, const Duration(seconds: 4));
    expect(recovery.listening, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(recovery.listening, isFalse);
    expect(timer.running, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(recovery.listening, isTrue);
    await finish(tester);
    recovery.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  test('루틴이 만든 타바타 제목은 타이머로 읽힌다', () {
    final titles = [
      for (final plan in methodPlan.values)
        for (final b in plan())
          if (b.name.contains('타바타')) b.name,
    ];
    expect(titles, isNotEmpty);
    for (final t in titles) {
      expect(TimingSpec.parse(t)?.tabata, isTrue, reason: t);
    }
  });

  testWidgets('미니 띠는 8pt 로 보이고, 큰 글자에선 띠·요약이 한 줄·알약은 그 아래 왼쪽, '
      '완료 [적기 ▸] 는 ↺ 바로 옆 오른쪽 끝', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget strip(double scale) => app(
      TimerStrip(
        owner: 'card',
        spec: tabata,
        timer: timer,
        link: RunLink(timer),
        onStart: () {},
        onOpen: () {},
        onEdit: () {},
      ),
      scale: scale,
    );
    await tester.pumpWidget(strip(1));
    final segments = find.descendant(
      of: find.byType(TimerMiniBar),
      matching: find.byType(ColoredBox),
    );
    expect(segments, findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      expect(tester.getSize(segments.at(i)).height, 8);
    }

    await tester.pumpWidget(strip(1.5));
    final bar = tester.getRect(find.byType(TimerMiniBar));
    final summary = tester.getRect(find.byKey(const ValueKey('timer-summary')));
    final start = tester.getRect(find.byKey(const ValueKey('timer-start')));
    expect(bar.center.dy, inInclusiveRange(summary.top, summary.bottom));
    expect(start.top, greaterThanOrEqualTo(summary.bottom));
    expect(start.left, moreOrLessEquals(bar.left, epsilon: 1));

    timer.toggle('card', tabata);
    await advance(tester, Duration(seconds: tabata.duration));
    expect(timer.phase, TimingPhase.complete);
    await tester.pumpWidget(strip(1));
    expect(find.text('완료 · 8라운드 · 3:50'), findsOneWidget);
    final log = tester.getRect(find.byKey(const ValueKey('timer-log-now')));
    final reset = tester.getRect(find.byKey(const ValueKey('timer-reset')));
    expect(log.right, moreOrLessEquals(reset.left, epsilon: 1));
    await finish(tester);
  });

  test('summary: 타바타·박자·목표, 둘 다면 " · "', () async {
    final l = await L.delegate.load(const Locale('ko'));
    expect(
      const TimingSpec(tabata: true).summary(l),
      '운동 20초 · 휴식 10초 × 8 · 3:50',
    );
    expect(const TimingSpec(bpm: 60).summary(l, target: 30), '60 BPM · 목표 30회');
    expect(const TimingSpec(bpm: 60).summary(l), '60 BPM');
    expect(
      const TimingSpec(tabata: true, bpm: 100, rounds: 2).summary(l),
      '운동 20초 · 휴식 10초 × 2 · 0:50 · 100 BPM',
    );
  });
}

const tabata = TimingSpec(tabata: true);
