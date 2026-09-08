import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/collapsing_drag.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/local_ai.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/parser.dart';

final input = find.byType(CupertinoTextField);

Future<void> pumpPage(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    CupertinoApp(
      locale: const Locale('ko'),
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> flush(WidgetTester tester, NotesStore store) async {
  var done = false;
  store.flush().then((_) => done = true);
  for (var i = 0; i < 100 && !done; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(done, isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'moving a block preserves its sets, notes, completion and active input',
    () {
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 20')
        ..noteLastSet('천천히')
        ..toggleDone(0, 0)
        ..addExercise('스쿼트')
        ..addExercise('계획');
      c.openBlock(0);
      final block = c.blocks.first;
      c.moveBlock(0, 2);
      expect(c.blocks.last, same(block));
      expect(c.activeIndex, 2);
      expect(block.sets.single.notes.single, '천천히');
      expect(block.sets.single.done, isFalse);
      c.addSet('80 15');
      expect(block.sets, hasLength(2));
      c.closeBlock();
      expect(c.blocks.map((b) => b.name), ['스쿼트', '계획', '벤치프레스']);
    },
  );

  test(
    'search handles spaces, word order, personal initials and recent ties',
    () {
      expect(suggest('벤치 프레스', ['벤치프레스']).single, '벤치프레스');
      expect(
        suggest('프레스 인클라인', ['벤치프레스', '인클라인 덤벨 프레스']).single,
        '인클라인 덤벨 프레스',
      );
      expect(suggest('ㅎㅁㄹㅇ', ['해머 로우']).single, '해머 로우');
      expect(
        suggest('프레스', ['덤벨 프레스', '체스트 프레스'], preferred: ['체스트 프레스']).first,
        '체스트 프레스',
      );
      expect(suggest('밴치', ['벤치프레스']).single, '벤치프레스');
      final pool = [...List.generate(100, (i) => '운동 $i'), '우리센터 등머신'];
      expect(
        retrieveExercises('우리센터 등머신 40kg 100개 채우기', pool),
        contains('우리센터 등머신'),
      );
    },
  );

  test('machine names never invoke generation or invent targets', () async {
    const channel = MethodChannel('test/machine_names');
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          calls++;
          throw const FormatException('Must not generate a plan from a name');
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    const ai = LocalAi(channel: channel, nativeSupported: true);
    for (final name in ['체스트 프레스 머신', '해머스트렝스 로우', 'MTS100 로우']) {
      final setup = await ai.interpret(name, 'ko', [name]);
      expect(setup.name, name);
      expect(setup.hasPlan, isFalse);
      expect(setup.repsOnly, isFalse);
    }
    expect(calls, 0);
    expect(hasSetupIntent('벤치 팔십 키로로 백 개 채울래'), isTrue);
  });

  test(
    'weight preference and personal history survive deleting a note and restarting',
    () async {
      final dir = Directory.systemTemp.createTempSync('setpad_preferences_');
      final store = NotesStore(directory: dir);
      addTearDown(() {
        store.dispose();
        dir.deleteSync(recursive: true);
      });
      final note = store.create();
      store.rememberExercise('우리센터 등머신');
      store.setWeightUnit('lb');
      store.delete(note);
      await store.flush();
      final reopened = NotesStore(directory: dir);
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.weightUnit, 'lb');
      expect(reopened.exerciseHistory.first, '우리센터 등머신');
      final c =
          RoutineEditorController(
              history: reopened.exerciseHistory,
              weightUnit: reopened.weightUnit,
            )
            ..addExercise('벤치프레스')
            ..addSet('80 10');
      expect(c.lastSet!.unit, 'lb');
      c.weightUnit = 'kg';
      expect(c.lastSet!.unit, 'lb');
      c.addExercise('스쿼트');
      c.addSet('60 10');
      expect(c.lastSet!.unit, 'kg');
    },
  );

  testWidgets(
    'an unsubmitted name is saved while focused and restored without creating a set',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('setpad_draft_');
      final store = NotesStore(directory: dir);
      addTearDown(() {
        store.dispose();
        dir.deleteSync(recursive: true);
      });
      final note = store.create();
      await pumpPage(tester, EditorPage(store: store, note: note));
      await tester.enterText(input, '내일 하체 운동');
      await tester.pump();
      expect(
        tester.widget<CupertinoTextField>(input).focusNode!.hasFocus,
        isTrue,
      );
      await flush(tester, store);
      final reopened = NotesStore(directory: dir);
      addTearDown(reopened.dispose);
      await tester.runAsync(reopened.load);
      expect(reopened.notes.single.draft!.text, '내일 하체 운동');
      expect(reopened.notes.single.blocks, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await flush(tester, store);
      await pumpPage(
        tester,
        EditorPage(store: reopened, note: reopened.notes.single),
      );
      expect(
        tester.widget<CupertinoTextField>(input).controller!.text,
        '내일 하체 운동',
      );
      expect(reopened.notes.single.blocks, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await flush(tester, reopened);
    },
  );

  testWidgets(
    'memo drafts retain their set and numeric draft across reopening',
    (tester) async {
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 10');
      EditorDraft? saved;
      await pumpPage(
        tester,
        CupertinoPageScaffold(
          child: SafeArea(
            child: RoutineEditor(
              controller: c,
              initialDraft: const EditorDraft(
                text: '어깨 조심',
                block: 0,
                memo: true,
                setText: '80 12',
              ),
              onDraftChanged: (draft) => saved = draft,
            ),
          ),
        ),
      );
      expect(
        tester.widget<CupertinoTextField>(input).controller!.text,
        '어깨 조심',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(c.blocks.single.sets.single.notes, ['어깨 조심']);
      expect(
        tester.widget<CupertinoTextField>(input).controller!.text,
        '80 12',
      );
      expect(saved!.text, '80 12');
      expect(saved!.memo, isFalse);
      expect(saved!.setText, isNull);
    },
  );

  testWidgets(
    'blocks can be dragged as a whole and unchecked sets stay readable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = RoutineEditorController()
        ..addExercise('첫 운동')
        ..addSet('80 10')
        ..toggleDone(0, 0)
        ..addExercise('둘째 운동')
        ..addSet('40 15')
        ..noteLastSet('둘째 운동 메모')
        ..addExercise('셋째 운동')
        ..closeBlock();
      await pumpPage(
        tester,
        CupertinoPageScaffold(
          child: SafeArea(child: RoutineEditor(controller: c)),
        ),
      );
      expect(
        tester.widget<Text>(find.text('80kg · 10회')).style!.decoration,
        isNot(TextDecoration.lineThrough),
      );
      final handles = find.byWidgetPredicate(
        (w) => w is ReorderableDragStartListener,
      );
      final destination = tester.getCenter(handles.last) + const Offset(0, 150);
      final gesture = await tester.startGesture(
        tester.getCenter(handles.first),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 25));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.text('80kg · 10회'), findsNothing);
      expect(find.text('40kg · 15회'), findsNothing);
      expect(find.text('둘째 운동 메모'), findsNothing);
      expect(
        tester.getSize(find.byType(ReorderProxy)).height,
        lessThanOrEqualTo(80),
      );
      await gesture.moveTo(destination);
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(c.blocks.map((b) => b.name), ['둘째 운동', '셋째 운동', '첫 운동']);
      expect(c.blocks.last.sets.single.value, 80);
      expect(c.blocks.last.sets.single.done, isFalse);
      expect(find.text('둘째 운동 메모'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'canceling a compact drag restores all records and the active draft',
    (tester) async {
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 10')
        ..noteLastSet('그대로 보존')
        ..addExercise('스쿼트')
        ..addSet('60 12');
      await pumpPage(
        tester,
        CupertinoPageScaffold(
          child: SafeArea(
            child: RoutineEditor(
              controller: c,
              initialDraft: const EditorDraft(text: '70 8', block: 1),
            ),
          ),
        ),
      );
      final handles = find.byWidgetPredicate(
        (w) => w is ReorderableDragStartListener,
      );
      final gesture = await tester.startGesture(
        tester.getCenter(handles.first),
      );
      await gesture.moveBy(const Offset(0, 25));
      await tester.pump();
      await tester.pump();
      expect(find.text('그대로 보존'), findsNothing);
      expect(find.text('60kg · 12회'), findsNothing);
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(find.text('그대로 보존'), findsOneWidget);
      expect(c.blocks.map((b) => b.name), ['벤치프레스', '스쿼트']);
      expect(c.activeIndex, 1);
      expect(tester.widget<CupertinoTextField>(input).controller!.text, '70 8');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'titles and sets can be edited without losing goals, notes or drafts',
    (tester) async {
      final c = RoutineEditorController()
        ..addExercise(
          '벤치프레스',
          setup: const WorkoutSetup(name: '벤치프레스', weight: 80, totalReps: 100),
        )
        ..addSet('80 10')
        ..noteLastSet('어깨 조심')
        ..toggleDone(0, 0)
        ..addSet('80 12');
      await pumpPage(
        tester,
        CupertinoPageScaffold(
          child: SafeArea(
            child: RoutineEditor(
              controller: c,
              initialDraft: const EditorDraft(text: '80 8', block: 0),
            ),
          ),
        ),
      );
      await tester.tap(find.text('벤치프레스'));
      await tester.pumpAndSettle();
      final fields = find.byType(CupertinoTextField);
      expect(find.byType(CupertinoTextFormFieldRow), findsNothing);
      await tester.enterText(fields, '인클라인 벤치프레스');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(c.blocks.single.name, '인클라인 벤치프레스');
      expect(c.blocks.single.setup!.name, '인클라인 벤치프레스');
      expect(c.blocks.single.setup!.totalReps, 100);
      await tester.tap(find.text('80kg · 10회'));
      await tester.pumpAndSettle();
      tester.widget<SetKeypad>(find.byType(SetKeypad)).onKey('75 9');
      expect(c.blocks.single.sets.first.value, 75);
      tester.widget<SetKeypad>(find.byType(SetKeypad)).onSubmit();
      await tester.pumpAndSettle();
      final set = c.blocks.single.sets.first;
      expect(set.value, 75);
      expect(set.reps, 9);
      expect(set.done, isFalse);
      expect(set.notes, ['어깨 조심']);
      expect(c.blocks.single.sets.last.reps, 12);
      expect(tester.widget<CupertinoTextField>(input).controller!.text, '80 8');
      await tester.tap(find.text('75kg · 9회'));
      await tester.pumpAndSettle();
      tester.widget<SetKeypad>(find.byType(SetKeypad)).onKey('75 999');
      tester.widget<SetKeypad>(find.byType(SetKeypad)).onSubmit();
      await tester.pumpAndSettle();
      expect(c.blocks.single.sets.first.reps, 999);
    },
  );

  testWidgets(
    'inline edits restore their target and pending set after reopening',
    (tester) async {
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 10')
        ..noteLastSet('천천히');
      EditorDraft? saved;
      await pumpPage(
        tester,
        CupertinoPageScaffold(
          child: RoutineEditor(
            controller: c,
            initialDraft: const EditorDraft(text: '70 8', block: 0),
            onDraftChanged: (draft) => saved = draft,
          ),
        ),
      );
      await tester.tap(find.text('80kg · 10회'));
      await tester.pumpAndSettle();
      tester.widget<SetKeypad>(find.byType(SetKeypad)).onKey('75 9');
      await tester.pump();
      final restored = EditorDraft.fromJson(saved!.toJson())!;
      expect(restored.editingSet, 0);
      expect(restored.resume!.text, '70 8');
      expect(c.blocks.single.sets.single.value, 75);
      await tester.pumpWidget(const SizedBox());
      await pumpPage(
        tester,
        CupertinoPageScaffold(
          child: RoutineEditor(controller: c, initialDraft: restored),
        ),
      );
      expect(tester.widget<CupertinoTextField>(input).controller!.text, '75 9');
      tester.widget<SetKeypad>(find.byType(SetKeypad)).onSubmit();
      await tester.pumpAndSettle();
      expect(tester.widget<CupertinoTextField>(input).controller!.text, '70 8');
      expect(c.blocks.single.sets.single.notes, ['천천히']);
    },
  );

  testWidgets('deleting an edited set cannot overwrite the following set', (
    tester,
  ) async {
    final c = RoutineEditorController()
      ..addExercise('벤치프레스')
      ..addSet('80 10')
      ..addSet('60 12');
    await pumpPage(
      tester,
      CupertinoPageScaffold(child: RoutineEditor(controller: c)),
    );
    await tester.tap(find.text('80kg · 10회'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CupertinoIcons.xmark).first);
    await tester.pumpAndSettle();
    expect(c.blocks.single.sets.single.value, 60);
    expect(c.blocks.single.sets.single.reps, 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'early cancellation and an unchanged drop both expand the records',
    (tester) async {
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 10')
        ..closeBlock();
      await pumpPage(
        tester,
        CupertinoPageScaffold(
          child: SafeArea(child: RoutineEditor(controller: c)),
        ),
      );
      for (final cancelBeforeLayout in [true, false]) {
        final handle = find.byWidgetPredicate(
          (w) => w is ReorderableDragStartListener,
        );
        final gesture = await tester.startGesture(tester.getCenter(handle));
        await gesture.moveBy(const Offset(0, 25));
        if (cancelBeforeLayout) {
          await gesture.cancel();
        } else {
          await tester.pump();
          await tester.pump();
          expect(find.text('80kg · 10회'), findsNothing);
          await gesture.up();
        }
        await tester.pumpAndSettle();
        expect(find.text('80kg · 10회'), findsOneWidget);
        expect(c.blocks.single.sets.single.reps, 10);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
