// 타이머 시트 — [완료] 가 제목을 다시 쓰고(제목이 곧 설정), 박자 목표는 칸의 설정에,
// 값 시트는 범위 안에서만, 돌고 있는 칸은 읽기 전용, 설정 화면의 진동 토글.
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/run_page.dart';
import 'package:setpad/settings_page.dart';
import 'package:setpad/timer_sheet.dart';
import 'package:setpad/workout_timing.dart';

import 'timer_strip_test.dart' show app;
import 'workout_timing_test.dart' show FakeAudio;

void main() {
  group('timerSheetName', () {
    const tabata = TimingSpec(tabata: true);
    test('안 바꿨으면 친 그대로', () {
      expect(
        timerSheetName('버피 타바타 20/10 x8', tabata, tabataWord: '타바타'),
        '버피 타바타 20/10 x8',
      );
    });
    test('값만 바꾸면 제자리에서', () {
      expect(
        timerSheetName(
          '버피 타바타 30/15 x6',
          const TimingSpec(tabata: true, work: 40, rest: 15, rounds: 6),
        ),
        '버피 타바타 40/15 x6',
      );
    });
    test('끈 쪽은 떼고 켠 쪽만', () {
      expect(
        timerSheetName(
          '버피 타바타 30/15 60bpm',
          const TimingSpec(tabata: true, work: 30, rest: 15),
          tabataWord: '타바타',
        ),
        '버피 타바타 30/15',
      );
      expect(
        timerSheetName('푸시업 타바타 100bpm', const TimingSpec(bpm: 100)),
        '푸시업 100bpm',
      );
      expect(timerSheetName('푸시업 3x10 60bpm', null), '푸시업 3x10');
    });
    test('켜면 locale 낱말, 이름이 비면 낱말만, 둘 다 끄고 비면 null', () {
      expect(timerSheetName('푸시업', tabata, tabataWord: '타바타'), '푸시업 타바타');
      expect(timerSheetName('Burpee', tabata), 'Burpee Tabata');
      expect(timerSheetName('타바타', const TimingSpec(bpm: 60)), '60bpm');
      expect(timerSheetName('타바타', null), isNull);
    });
    test('결과는 같은 설정으로 다시 읽히고 세트 표기(3x10)는 그대로', () {
      for (final name in ['푸시업 3x10', '버피 타바타 x6', '스쿼트 60bpm 3 x 10']) {
        for (final spec in const [
          TimingSpec(tabata: true, work: 45, rest: 15, rounds: 6),
          TimingSpec(bpm: 75),
          TimingSpec(tabata: true, bpm: 90, rounds: 10),
        ]) {
          final out = timerSheetName(name, spec, tabataWord: '타바타')!;
          expect(TimingSpec.parse(out), spec, reason: out);
          if (name.contains('3x10')) expect(out, contains('3x10'));
          if (name.contains('3 x 10')) expect(out, contains('3 x 10'));
        }
      }
    });
  });

  late WorkoutTimer timer;
  setUp(
    () => timer = WorkoutTimer(
      audio: FakeAudio(),
      now: () => Duration.zero,
      haptic: (_) {},
    ),
  );
  tearDown(() => timer.dispose());

  Future<void> openSheet(WidgetTester tester, RoutineEditorController c) async {
    await tester.tap(
      find.byKey(ValueKey('exercise-settings-${c.blocks.single.id}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('setup-timer')));
    await tester.pumpAndSettle();
  }

  testWidgets('값 시트: −/+ 는 범위 끝에서 멈추고 알리며, 프리셋·휠이 같은 값을 쓴다', (tester) async {
    final c = RoutineEditorController()
      ..addExercise('버피 타바타')
      ..closeBlock();
    await tester.pumpWidget(app(RoutineEditor(controller: c, timer: timer)));
    await tester.pumpAndSettle();
    await openSheet(tester, c);
    await tester.tap(find.byKey(const ValueKey('timer-rounds')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byKey(const ValueKey('value-less')));
      await tester.pump();
    }
    expect(find.text('1'), findsWidgets);
    expect(find.text('최솟값이에요'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('value-preset-12')));
    await tester.pumpAndSettle();
    expect(find.text('최솟값이에요'), findsNothing);
    String number() =>
        tester.widget<Text>(find.byKey(const ValueKey('value-number'))).data!;
    // Held: one step after 300 ms, then every 100 ms; letting go adds none.
    final hold = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('value-more'))),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(number(), '12');
    await tester.pump(const Duration(milliseconds: 60));
    expect(number(), '13');
    await tester.pump(const Duration(milliseconds: 210));
    expect(number(), '15');
    await hold.up();
    await tester.pump();
    expect(number(), '15');
    await tester.tap(find.byKey(const ValueKey('value-less')));
    await tester.tap(find.byKey(const ValueKey('value-less')));
    await tester.tap(find.byKey(const ValueKey('value-less')));
    await tester.pump();
    expect(number(), '12');
    await tester.tap(find.byKey(const ValueKey('value-done')));
    await tester.pumpAndSettle();
    expect(find.text('12라운드'), findsOneWidget);

    // Work: 600 is the end of the wheel.
    await tester.tap(find.byKey(const ValueKey('timer-work')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('value-preset-60')));
    await tester.pump();
    for (var i = 0; i < 110; i++) {
      await tester.tap(find.byKey(const ValueKey('value-more')));
    }
    await tester.pump();
    expect(find.text('최댓값이에요'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('value-number'))).data,
      '600초',
    );
    await tester.tap(find.byKey(const ValueKey('value-done')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('timer-sheet-done')));
    await tester.pumpAndSettle();
    expect(c.blocks.single.name, '버피 타바타 600/10 x12');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('박자 목표는 칸의 설정(세트당 횟수)에 쓰이고, 센 수가 한 세트가 된다', (tester) async {
    final c = RoutineEditorController()
      ..addExercise('푸시업 60bpm')
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
    await tester.pumpAndSettle();
    await openSheet(tester, c);
    expect(find.text('목표 없음'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('timer-target')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('value-preset-30')));
    await tester.tap(find.byKey(const ValueKey('value-done')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('timer-sheet-done')));
    await tester.pumpAndSettle();
    expect(c.blocks.single.name, '푸시업 60bpm');
    expect(c.blocks.single.setup?.repsPerSet, 30);
    expect(find.text('60 BPM · 목표 30회'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    expect(timer.target, 30);
    final link = tester.widget<RunPage>(find.byType(RunPage)).link;
    link.onLogCount!(30);
    expect(c.blocks.single.sets.single.reps, 30);
    expect(link.logged, isTrue);
    Navigator.of(tester.element(find.byType(RunPage))).pop();
    await tester.pumpAndSettle();

    // While it runs the sheet only reads.
    await openSheet(tester, c);
    expect(find.text('멈춘 뒤 바꿀 수 있어요'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoSwitch>(find.byKey(const ValueKey('timer-beat')))
          .onChanged,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
    timer.reset();
  });

  testWidgets('둘 다 끄면 이름이 남을 때만 [완료], 타이머만이던 이름은 먼저 적게 한다', (tester) async {
    final c = RoutineEditorController()
      ..addExercise('타바타')
      ..closeBlock();
    await tester.pumpWidget(app(RoutineEditor(controller: c, timer: timer)));
    await tester.pumpAndSettle();
    await openSheet(tester, c);
    await tester.tap(find.byKey(const ValueKey('timer-tabata')));
    await tester.pump();
    expect(find.text('이름을 먼저 적어요'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('timer-sheet-done')));
    await tester.pumpAndSettle();
    expect(find.byType(TimerSheet), findsOneWidget, reason: 'disabled');
    await tester.tap(find.byKey(const ValueKey('timer-beat')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('timer-sheet-done')));
    await tester.pumpAndSettle();
    expect(c.blocks.single.name, '60bpm');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('시트의 소리·진동은 앱 설정을 바꾸고 엔진에 곧 실린다', (tester) async {
    final aloud = <bool>[], buzz = <bool>[];
    final c = RoutineEditorController()
      ..addExercise('버피 타바타')
      ..closeBlock();
    await tester.pumpWidget(
      app(
        RoutineEditor(
          controller: c,
          timer: timer,
          onCountAloud: aloud.add,
          onHaptics: buzz.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(timer.haptics, isTrue);
    await openSheet(tester, c);
    await tester.tap(find.byKey(const ValueKey('timer-haptics')));
    await tester.tap(find.byKey(const ValueKey('timer-aloud')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('timer-sheet-done')));
    await tester.pumpAndSettle();
    expect(buzz, [false]);
    expect(aloud, [true]);
    expect(timer.haptics, isFalse);
    expect(timer.countAloud, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('설정 화면: 박자 소리내어 세기 아래 타이머 진동 토글', (tester) async {
    final store = NotesStore();
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: L.localizationsDelegates,
        home: SettingsPage(store: store),
      ),
    );
    final toggle = find.byKey(const ValueKey('settings-haptics'));
    expect(find.text('타이머 진동'), findsOneWidget);
    expect(
      tester.getTopLeft(toggle).dy,
      greaterThan(tester.getTopLeft(find.text('박자를 소리내어 세기')).dy),
    );
    expect(store.hapticsOn, isTrue);
    await tester.tap(
      find.descendant(of: toggle, matching: find.byType(CupertinoSwitch)),
    );
    await tester.pump();
    expect(store.hapticsOn, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2)); // the debounced save
  });
}
