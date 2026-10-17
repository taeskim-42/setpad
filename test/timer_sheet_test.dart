// 타이머 시트 — [완료] 가 제목을 다시 쓰고(제목이 곧 설정), 박자 목표는 칸의 설정에,
// 값 시트는 범위 안에서만, 돌고 있는 칸은 읽기 전용, 설정 화면의 진동 토글.
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_ai.dart' show WorkoutSetup;
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

  testWidgets('시트 바탕은 홈 인디케이터 밑까지 깔리고, 총 시간은 준비 3초를 뺀다', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: L.localizationsDelegates,
        home: const Align(
          alignment: Alignment.bottomCenter,
          child: TimerSheet(name: '버피 타바타 20/10 x8', target: 0),
        ),
      ),
    );
    expect(find.text('총 3:50'), findsOneWidget);
    // The ground reaches the screen's bottom; the content stays above the
    // home indicator.
    final ground = find.byKey(const ValueKey('timer-sheet-ground'));
    expect(tester.getRect(ground).bottom, 852);
    final content = find.descendant(
      of: find.descendant(of: ground, matching: find.byType(SafeArea)),
      matching: find.byType(Column),
    );
    expect(tester.getRect(content.first).bottom, lessThanOrEqualTo(852 - 34));
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
    // The ⋯ chip row stays open after the sheet; open it only when shut.
    if (find.byKey(const ValueKey('setup-timer')).evaluate().isEmpty) {
      await tester.tap(
        find.byKey(ValueKey('exercise-settings-${c.blocks.single.id}')),
      );
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('setup-timer')));
    await tester.pumpAndSettle();
  }

  Finder stripText(String text) => find.descendant(
    of: find.byKey(const ValueKey('timer-summary')),
    matching: find.text(text),
  );

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
    expect(stripText('60 BPM · 목표 30회'), findsOneWidget);

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

  testWidgets('카드가 보이는 목표(총 개수에서 남은 수)를 시트도 보이고, 없음을 고르면 엔진 목표도 꺼진다', (
    tester,
  ) async {
    final c = RoutineEditorController()
      ..addExercise(
        '푸시업 60bpm',
        setup: const WorkoutSetup(name: '푸시업 60bpm', totalReps: 100),
      )
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
    expect(stripText('60 BPM · 목표 100회'), findsOneWidget);
    await openSheet(tester, c);
    expect(find.text('목표 100회'), findsOneWidget);
    // Untouched: the setup stays as typed (no reps per set made up).
    await tester.tap(find.byKey(const ValueKey('timer-sheet-done')));
    await tester.pumpAndSettle();
    expect(c.blocks.single.setup?.repsPerSet, isNull);
    await openSheet(tester, c);
    await tester.tap(find.byKey(const ValueKey('timer-target')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CupertinoPicker), const Offset(0, 6000));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('value-number'))).data,
      '목표 없음',
    );
    await tester.tap(find.byKey(const ValueKey('value-done')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('timer-sheet-done')));
    await tester.pumpAndSettle();
    expect(c.blocks.single.setup?.totalReps, 100, reason: 'the total stays');
    expect(stripText('60 BPM'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    expect(timer.target, isNull, reason: 'counts on, no goal');
    Navigator.of(tester.element(find.byType(RunPage))).pop();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    timer.reset();
  });

  testWidgets(
    '320×568·글자 2.0·9개 언어: 시트·값 시트가 넘치지 않고, 프리셋에 닿으며, 한계 안내가 잘리지 않는다',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final locale in L.supportedLocales) {
        final l = await L.delegate.load(locale);
        await tester.pumpWidget(
          app(
            Builder(
              builder: (context) => CupertinoButton(
                key: const ValueKey('go'),
                onPressed: () => showTimerSheet(
                  context,
                  name: '버피 타바타 45/15 x8 100bpm',
                  target: 30,
                  onCountAloud: (_) {},
                  onHaptics: (_) {},
                ),
                child: const Text('go'),
              ),
            ),
            locale: locale,
            scale: 2.0,
          ),
        );
        await tester.tap(find.byKey(const ValueKey('go')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$locale sheet');
        await tester.ensureVisible(find.byKey(const ValueKey('timer-rounds')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('timer-rounds')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$locale value sheet');
        for (var i = 0; i < 8; i++) {
          await tester.tap(find.byKey(const ValueKey('value-less')));
          await tester.pump();
        }
        final hint = tester.renderObject<RenderParagraph>(
          find.text(l.timerMinValue),
        );
        expect(
          hint.size.height,
          greaterThanOrEqualTo(hint.getMaxIntrinsicHeight(hint.size.width)),
          reason: '$locale hint clipped',
        );
        expect(tester.takeException(), isNull, reason: '$locale hint');
        await tester.ensureVisible(
          find.byKey(const ValueKey('value-preset-12')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('value-preset-12')));
        await tester.pump();
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('value-number'))).data,
          '12',
          reason: '$locale presets in reach',
        );
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets('스위치는 무엇을 켜는지 읽힌다(시트 넷, 설정 화면의 토글)', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        TimerSheet(
          name: '버피 타바타 45/15 x8 100bpm',
          target: 30,
          onCountAloud: (_) {},
          onHaptics: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final (k, label) in [
      ('timer-tabata', '타바타'),
      ('timer-beat', '박자'),
      ('timer-aloud', '박자를 소리내어 세기'),
      ('timer-haptics', '진동'),
    ]) {
      expect(
        tester.getSemantics(find.byKey(ValueKey(k))).label,
        label,
        reason: k,
      );
    }
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: L.localizationsDelegates,
        home: SettingsPage(store: NotesStore()),
      ),
    );
    expect(
      tester
          .getSemantics(
            find.descendant(
              of: find.byKey(const ValueKey('settings-haptics')),
              matching: find.byType(CupertinoSwitch),
            ),
          )
          .label,
      '타이머 진동',
    );
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
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
