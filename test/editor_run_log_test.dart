// What a timer run writes into the card: planned sets first, and the run's
// round ledger kept in step with × and undo on the card.
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/focus_page.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/run_page.dart';
import 'package:setpad/workout_timing.dart';

import 'workout_timing_test.dart' show FakeAudio;

Widget app(Widget child) => CupertinoApp(
  locale: const Locale('ko'),
  supportedLocales: L.supportedLocales,
  localizationsDelegates: L.localizationsDelegates,
  home: CupertinoPageScaffold(
    resizeToAvoidBottomInset: false,
    child: SafeArea(child: child),
  ),
);

void main() {
  late Duration now;
  late FakeAudio audio;
  late WorkoutTimer timer;
  setUp(() {
    now = Duration.zero;
    audio = FakeAudio();
    timer = WorkoutTimer(audio: audio, now: () => now, haptic: (_) {});
  });
  tearDown(() => timer.dispose());

  Future<void> advance(WidgetTester tester, Duration to) async {
    now = to;
    timer.tick();
    await tester.pump();
  }

  Future<RoutineEditorController> start(
    WidgetTester tester,
    List<ExerciseBlock> blocks,
  ) async {
    final c = RoutineEditorController()..restore(blocks);
    await tester.pumpWidget(
      app(
        RoutineEditor(
          controller: c,
          timer: timer,
          // My record's editor (not the proxy one): it guards leaving.
          history: () => const [],
          askTimerPermissions: () async {},
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    return c;
  }

  test('logReps fills my first planned set (value and unit kept) and '
      'returns it; with none left it adds one', () {
    final planned = LoggedSet(value: 16, unit: 'kg', reps: 12, done: false);
    final theirs = LoggedSet(reps: 9, done: false, author: '준');
    final b = ExerciseBlock('버피 타바타 20/10 x8', [theirs, planned]);
    final c = RoutineEditorController()..restore([b]);
    final first = c.logReps(b, 10)!;
    expect(first.id, planned.id);
    expect(
      [first.value, first.unit, first.reps, first.done],
      [16, 'kg', 10, true],
    );
    expect(b.sets, hasLength(2));
    expect(identical(b.sets[0], theirs), isTrue, reason: 'not someone else');
    final second = c.logReps(b, null)!;
    expect(b.sets.last.id, second.id);
    expect(b.sets, hasLength(3));
  });

  testWidgets('a routine\'s planned tabata card: the summary fills the ○, '
      'it does not add as many sets after them', (tester) async {
    final c = await start(tester, [
      ExerciseBlock('버피 타바타 5/5 x2', [
        LoggedSet(reps: 12, done: false),
        LoggedSet(reps: 12, done: false),
      ]),
    ]);
    // RestLog's default is my last done set, not the plan's 12.
    final link = tester.widget<RunPage>(find.byType(RunPage)).link;
    expect(link.lastReps, isNull);
    await advance(tester, const Duration(seconds: 23));
    expect(timer.phase, TimingPhase.complete);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('run-log')));
    await tester.pumpAndSettle();
    final sets = c.blocks.single.sets;
    expect(sets, hasLength(2));
    expect(sets.every((s) => s.done), isTrue);
    await tester.pumpWidget(const SizedBox());
    timer.reset();
  });

  Future<RoutineEditorController> logRoundOneThenRemoveIt(
    WidgetTester tester,
  ) async {
    final c = await start(tester, [ExerciseBlock('버피 타바타 5/5 x2')]);
    await advance(tester, const Duration(seconds: 10)); // round 1 rest
    await tester.tap(find.byKey(const ValueKey('together-log')));
    await tester.pump();
    expect(c.blocks.single.sets, hasLength(1));
    Navigator.of(tester.element(find.byType(RunPage))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('set-cell-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CupertinoIcons.xmark).first);
    await tester.pumpAndSettle();
    expect(c.blocks.single.sets, isEmpty);
    return c;
  }

  testWidgets('a round set removed with × is unlogged again: the summary '
      'offers both rounds', (tester) async {
    final c = await logRoundOneThenRemoveIt(tester);
    await advance(tester, const Duration(seconds: 23));
    expect(timer.phase, TimingPhase.complete);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('timer-log-now')));
    await tester.pumpAndSettle();
    expect(find.text('1R 10'), findsNothing);
    expect(find.text('2세트 적기'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('run-log')));
    await tester.pumpAndSettle();
    expect(c.blocks.single.sets, hasLength(2));
    await tester.pumpWidget(const SizedBox());
    timer.reset();
  });

  testWidgets('undo brings the round back; once the round was logged again '
      'there is nothing to bring back', (tester) async {
    var c = await logRoundOneThenRemoveIt(tester);
    await tester.tap(find.byKey(const ValueKey('set-undo')));
    await tester.pumpAndSettle();
    expect(c.blocks.single.sets.map((s) => s.reps), [10]);
    await tester.tap(find.byKey(const ValueKey('timer-strip-open')));
    await tester.pumpAndSettle();
    var link = tester.widget<RunPage>(find.byType(RunPage)).link;
    expect(link.roundReps, [10]);
    // Fixing round 1 changes that set, not a new one.
    link.onLogRound!(1, 12);
    expect(c.blocks.single.sets.map((s) => s.reps), [12]);
    await tester.pumpWidget(const SizedBox());
    timer.reset();

    now = Duration.zero;
    c = await logRoundOneThenRemoveIt(tester);
    await tester.tap(find.byKey(const ValueKey('timer-strip-open')));
    await tester.pumpAndSettle();
    link = tester.widget<RunPage>(find.byType(RunPage)).link;
    link.onLogRound!(1, 11);
    Navigator.of(tester.element(find.byType(RunPage))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('set-undo')), findsNothing);
    expect(c.blocks.single.sets.map((s) => s.reps), [11]);
    expect(link.roundReps, [11]);
    await tester.pumpWidget(const SizedBox());
    timer.reset();
  });

  testWidgets('leaving with a finished run owing rounds asks: log first '
      'opens the summary, discard and leave lets the record go', (
    tester,
  ) async {
    final c = await start(tester, [ExerciseBlock('버피 타바타 5/5 x2')]);
    expect(c.holdsRun.value, isTrue, reason: 'running');
    await advance(tester, const Duration(seconds: 23));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(RunPage))).pop();
    await tester.pumpAndSettle();
    expect(c.holdsRun.value, isTrue, reason: 'owes 2 rounds');

    var leave = c.okToLeave!();
    await tester.pumpAndSettle();
    expect(find.text('적지 않은 2라운드가 있어요'), findsOneWidget);
    await tester.tap(find.text('먼저 적기'));
    await tester.pumpAndSettle();
    expect(await leave, isFalse);
    expect(find.byType(RunPage), findsOneWidget, reason: 'the summary');
    Navigator.of(tester.element(find.byType(RunPage))).pop();
    await tester.pumpAndSettle();

    leave = c.okToLeave!();
    await tester.pumpAndSettle();
    await tester.tap(find.text('버리고 나가기'));
    await tester.pumpAndSettle();
    expect(await leave, isTrue);

    // Logged: nothing to ask.
    await tester.tap(find.byKey(const ValueKey('timer-log-now')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('run-log')));
    await tester.pumpAndSettle();
    expect(c.holdsRun.value, isFalse);
    expect(await c.okToLeave!(), isTrue);
    await tester.pumpWidget(const SizedBox());
    timer.reset();
  });

  testWidgets('round ends are not read by a system voice: a whole run plays '
      'only the recorded English cues', (tester) async {
    // Built inside the test body: the timer's command chain must live in the
    // test's fake-async zone (one made in setUp never runs its sounds here).
    final voiced = FakeAudio();
    final own = WorkoutTimer(audio: voiced, now: () => now, haptic: (_) {});
    addTearDown(own.dispose);
    final c = RoutineEditorController()
      ..restore([ExerciseBlock('버피 타바타 5/5 x2')]);
    await tester.pumpWidget(
      app(
        RoutineEditor(
          controller: c,
          timer: own,
          history: () => const [],
          askTimerPermissions: () async {},
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    for (var s = 1; s <= 23; s++) {
      now = Duration(seconds: s);
      own.tick();
      await tester.pump();
    }
    expect(own.phase, TimingPhase.complete);
    // There is no TTS path any more; every spoken word is a bundled
    // recording ("Rest!" where "N라운드 종료" used to be read).
    expect(voiced.phrases, ['round_1', 'rest', 'last_round', 'done']);
    expect(
      voiced.voices.every((a) => a.startsWith('assets/voice/')),
      isTrue,
      reason: '${voiced.voices}',
    );
    await tester.pumpWidget(const SizedBox());
    own.reset();
  });

  testWidgets('a run or the set stage takes the keyboard down with its '
      'candidate bar; tapping the line brings both back', (tester) async {
    final c = RoutineEditorController()
      ..restore([ExerciseBlock('버피 타바타 5/5 x2')]);
    await tester.pumpWidget(
      app(
        RoutineEditor(
          controller: c,
          timer: timer,
          history: () => const [],
          askTimerPermissions: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bar = find.byKey(const ValueKey('exercise-suggestions'));
    expect(bar, findsOneWidget, reason: 'the empty name line, typing');
    Future<void> backToTheLine() async {
      await tester.tap(find.byType(CupertinoTextField));
      await tester.pumpAndSettle();
      expect(bar, findsOneWidget);
      expect(tester.testTextInput.isVisible, isTrue);
    }

    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(RunPage))).pop();
    await tester.pumpAndSettle();
    expect(bar, findsNothing, reason: 'no keyboard under it');
    await backToTheLine();

    c.openFocus!();
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(FocusPage))).pop();
    await tester.pumpAndSettle();
    expect(bar, findsNothing);
    await backToTheLine();
    await tester.pumpWidget(const SizedBox());
    timer.reset();
  });

  testWidgets('[start timer] on the set stage, on the card whose finished '
      'run still owes rounds, asks before the new run drops them', (
    tester,
  ) async {
    final c = await start(tester, [ExerciseBlock('버피 타바타 5/5 x2')]);
    await advance(tester, const Duration(seconds: 23));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(RunPage))).pop();
    await tester.pumpAndSettle();
    c.openFocus!();
    await tester.pumpAndSettle();
    Future<void> startHere() async {
      await tester.tap(find.byKey(const ValueKey('focus-start-timer')));
      await tester.pumpAndSettle();
      expect(find.text('적지 않은 2라운드가 있어요'), findsOneWidget);
    }

    // Cancel: the finished run and its rounds stay.
    await startHere();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect([timer.phase, timer.running], [TimingPhase.complete, false]);
    expect(find.byType(RunPage), findsNothing);

    // Log first: its summary, still owing both rounds.
    await startHere();
    await tester.tap(find.text('먼저 적기'));
    await tester.pumpAndSettle();
    expect(timer.phase, TimingPhase.complete);
    expect(find.text('2세트 적기'), findsOneWidget);
    Navigator.of(tester.element(find.byType(RunPage))).pop();
    await tester.pumpAndSettle();

    // Discard and start: a new run from the top.
    await startHere();
    await tester.tap(find.text('버리고 시작'));
    await tester.pumpAndSettle();
    expect(timer.running, isTrue);
    expect(timer.phase, TimingPhase.ready);
    expect(c.blocks.single.sets, isEmpty);
    await tester.pumpWidget(const SizedBox());
    timer.reset();
  });
}
