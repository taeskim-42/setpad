// 운동·식단 기록 UX 의 회귀 사례.
//
// "사용자의 입력이 원본이다" — 이름을 바꾸지 않고, 저장된 세트를 몰래 지우거나
// 늘리지 않고, 모르는 열량을 0 으로 꾸미지 않는다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/meal.dart';
import 'package:setpad/meal_amount_sheet.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/record_ai.dart';

final input = find.byType(CupertinoTextField);
String typed(WidgetTester tester) => tester
    .widget<CupertinoTextField>(input)
    .controller!
    .text
    .replaceAll(String.fromCharCode(0x200B), '');

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

Future<void> pumpEditor(
  WidgetTester tester,
  RoutineEditorController c, {
  EditorDraft? draft,
}) => pumpPage(
  tester,
  CupertinoPageScaffold(
    resizeToAvoidBottomInset: false,
    child: SafeArea(
      child: RoutineEditor(controller: c, initialDraft: draft),
    ),
  ),
);

Future<void> submit(WidgetTester tester, String text) async {
  await tester.enterText(input, text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

Finder padKey(String label) => find.descendant(
  of: find.byType(SetKeypad),
  matching: find.byWidgetPredicate(
    (w) => w is Text && w.data == label && (w.style?.fontSize ?? 0) >= 14,
  ),
);

Future<void> keys(WidgetTester tester, String text) async {
  pad(tester).onKey(text);
  await tester.pump();
}

SetKeypad pad(WidgetTester tester) =>
    tester.widget<SetKeypad>(find.byType(SetKeypad));

Future<void> flush(WidgetTester tester, NotesStore store) async {
  var done = false;
  store.flush().then((_) => done = true);
  for (var i = 0; i < 400 && !done; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(done, isTrue);
}

/// 화면 글꼴 자리에 진짜 글꼴을 끼운다. 테스트 글꼴은 글자가 전부 정사각형이라
/// 숫자가 실제보다 두 배 넓고, 그 폭으로는 "한 화면에 들어가는가" 를 잴 수 없다.
/// Roboto 는 SF 보다 조금 넓다 — 여기서 들어가면 기기에서도 들어간다.
Future<void> loadRealFont() async {
  final root = Platform.environment['FLUTTER_ROOT']!;
  final bytes = File(
    '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  ).readAsBytesSync();
  for (final family in ['CupertinoSystemText', 'CupertinoSystemDisplay']) {
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. 사용자가 만든 운동 이름', () {
    test('이름에 든 숫자는 모델이 이름에 넣고, 모델이 바꾼 이름은 친 글로 되돌린다', () async {
      // 수가 든 글은 모델로 간다 — 2 가 이름인지는 모델이 이름에 넣어 답한다.
      expect(hasSetupIntent('민수식 로우 2'), isTrue);
      expect(hasSetupIntent('민수식 로우'), isFalse);
      expect(hasSetupIntent('내 방식 벤치 변형 30kg 12회'), isTrue);
      expect(typedName('내 방식 벤치 변형 30kg 12회', '벤치프레스'), '내 방식 벤치 변형');
      expect(typedName('민수식 로우 2 30kg 12회', '민수식 로우 2'), '민수식 로우 2');
      expect(typedName('벤치 팔십 키로로 백 개', '벤치프레스'), '벤치');
      expect(typedName('30kg 12회', '벤치프레스'), isNull, reason: '가를 수 없다');

      // 모델이 사전 이름으로 바꿔 답해도 저장되는 이름은 친 글이다.
      final ai = RecordAi(
        respond: (_, _) async => {
          'exercises': [
            {
              'name': '벤치프레스',
              'weight': 30,
              'unit': 'kg',
              'totalReps': null,
              'repsPerSet': 12,
              'totalSets': null,
              'repsOnly': false,
            },
          ],
        },
      );
      final setup = (await ai.interpret('내 방식 벤치 변형 30kg 12회', 'ko', [
        '벤치프레스',
      ])).exercises.single.setup;
      expect(setup.name, '내 방식 벤치 변형');
      expect(setup.weight, 30);
      expect(setup.repsPerSet, 12);
      // X9: 이름을 가를 수 없어도 던지지 않는다. 확인 창이 그 이름을 보여 준다.
      final bare = await ai.interpret('30kg 12회', 'ko', ['벤치프레스']);
      expect(bare.exercises.single.setup.name, '벤치프레스');
      expect(bare.exercises.single.setup.weight, 30);
    });

    testWidgets('Enter 는 친 이름을 넣고, 후보는 눌렀을 때만 들어가며, 다시 열어도 그대로다', (
      tester,
    ) async {
      final dir = Directory.systemTemp.createTempSync('setpad_names_');
      final store = NotesStore(directory: dir)..rememberExercise('벤치프레스');
      addTearDown(() {
        store.dispose();
        dir.deleteSync(recursive: true);
      });
      final note = store.create();
      await pumpPage(tester, EditorPage(store: store, note: note));
      const names = ['내 방식 벤치', '벽 짚고 반쯤 스쿼트', '민수식 로우 2'];
      for (final name in names) {
        await tester.enterText(input.last, name);
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        // 세트 없이 다음 운동으로 — 빈 줄에서 운동 완료.
        pad(tester).onSubmit();
        await tester.pumpAndSettle();
      }
      // 후보가 떠 있어도("벤" → 벤치프레스) Enter 는 친 글이다.
      await tester.enterText(input.last, '벤');
      await tester.pump();
      expect(find.widgetWithText(SuggestionChip, '벤치프레스'), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      pad(tester).onSubmit();
      await tester.pumpAndSettle();
      // 후보를 직접 누르면 그 이름이다.
      await tester.enterText(input.last, '벤');
      await tester.pump();
      await tester.tap(find.widgetWithText(SuggestionChip, '벤치프레스'));
      await tester.pumpAndSettle();
      expect(note.blocks.map((b) => b.name), [...names, '벤', '벤치프레스']);
      expect(
        note.blocks.map((b) => b.exercise).toSet(),
        hasLength(5),
        reason: '비슷한 표준 운동과 합쳐지지 않는다',
      );

      await tester.pumpWidget(const SizedBox());
      await flush(tester, store);
      final reopened = NotesStore(directory: dir);
      addTearDown(reopened.dispose);
      await tester.runAsync(reopened.load);
      expect(reopened.notes.single.blocks.map((b) => b.name), [
        ...names,
        '벤',
        '벤치프레스',
      ]);
      // 익히는 것은 운동 이름이다. 모델 없이(테스트는 오프라인) 만든 '민수식 로우 2'
      // 는 수 낱말을 뺀 이름으로 익힌다 — 제목 문장을 이름으로 익히지 않는다(X8).
      expect(
        reopened.exerciseHistory,
        containsAll(['내 방식 벤치', '벽 짚고 반쯤 스쿼트', '민수식 로우']),
      );
      expect(reopened.exerciseHistory, isNot(contains('민수식 로우 2')));
    });
  });

  group('2. 저장된 세트를 눌렀을 때 완료와 세트 추가', () {
    testWidgets('완료는 세트 수를 지키고, 세트 추가는 새 값을 확정해야 하나 늘린다', (tester) async {
      // 앞쪽 운동에서 한다 — 마지막 운동에서만 되는 동작이면 안 된다.
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 10')
        ..addSet('80 8')
        ..addExercise('스쿼트')
        ..addSet('100 5')
        ..closeBlock();
      await pumpEditor(tester, c);
      final bench = c.blocks.first;

      await tester.tap(find.text('1 80×10'));
      await tester.pumpAndSettle();
      expect(padKey('세트 추가'), findsOneWidget);
      expect(padKey('완료'), findsOneWidget, reason: '두 버튼의 이름이 다르다');
      await keys(tester, '82.5 9');
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      expect(bench.sets, hasLength(2));
      expect(bench.sets.first.value, 82.5);
      expect(c.naming, isTrue, reason: '완료는 있던 자리로 돌아간다');

      await tester.tap(find.text('2 80×8'));
      await tester.pumpAndSettle();
      await keys(tester, '80 7');
      await tester.tap(padKey('세트 추가'));
      await tester.pumpAndSettle();
      expect(bench.sets, hasLength(2), reason: '새 세트는 확정 전에는 없다');
      expect(bench.sets.last.reps, 7, reason: '고친 값은 저장됐다');
      expect(c.activeIndex, 0);
      expect(typed(tester), isEmpty);
      await keys(tester, '85 5');
      await tester.tap(padKey('세트 추가'));
      await tester.pumpAndSettle();
      expect(bench.sets.map((s) => (s.value, s.reps)), [
        (82.5, 9),
        (80.0, 7),
        (85.0, 5),
      ]);
      expect(c.blocks.last.sets, hasLength(1), reason: '다른 운동은 그대로다');
    });

    testWidgets('세트 추가로 넘어가도 치다 만 운동 이름은 사라지지 않고, 앱이 죽어도 남는다', (tester) async {
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 10')
        ..closeBlock();
      EditorDraft? saved;
      Future<void> pump(EditorDraft? draft) => pumpPage(
        tester,
        CupertinoPageScaffold(
          resizeToAvoidBottomInset: false,
          child: SafeArea(
            child: RoutineEditor(
              controller: c,
              initialDraft: draft,
              onDraftChanged: (d) => saved = d,
            ),
          ),
        ),
      );
      await pump(null);
      await tester.enterText(input, '데드리');
      await tester.pump();
      await tester.tap(find.text('1 80×10'));
      await tester.pumpAndSettle();
      await keys(tester, '82.5 10');
      await tester.tap(padKey('세트 추가'));
      await tester.pumpAndSettle();
      expect(typed(tester), isEmpty, reason: '새 세트 줄은 비어 있다');
      expect(saved!.resume!.text, '데드리', reason: '초안에 같이 저장된다');

      // 여기서 앱이 죽었다 치고 저장된 초안으로 다시 연다.
      final restored = EditorDraft.fromJson(saved!.toJson())!;
      await tester.pumpWidget(const SizedBox());
      await pump(restored);
      expect(c.activeIndex, 0);
      await keys(tester, '85 8');
      await tester.tap(padKey('세트 추가'));
      await tester.pumpAndSettle();
      expect(c.blocks.single.sets, hasLength(2));
      await tester.tap(padKey('운동 완료'));
      await tester.pumpAndSettle();
      expect(c.naming, isTrue);
      expect(typed(tester), '데드리', reason: '치다 만 이름이 제자리로 돌아온다');
      expect(c.blocks, hasLength(1), reason: '초안이 운동으로 확정되지는 않는다');
    });

    testWidgets('잘못된 입력은 편집 내용을 지키고 그 자리에 알린다', (tester) async {
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 10');
      await pumpEditor(tester, c);
      await tester.tap(find.text('1 80×10'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 8; i++) {
        pad(tester).onBackspace();
      }
      await tester.pump();
      pad(tester).onSubmit();
      await tester.pumpAndSettle();
      expect(find.textContaining('세트를 먼저 입력'), findsOneWidget);
      expect(c.blocks.single.sets.single.value, 80);
      expect(c.blocks.single.sets.single.reps, 10);
    });
  });

  group('세트 줄에 친 것은 버리지 않는다', () {
    testWidgets('저장된 세트를 고치며 친 메모와 반복 수를 버리지 않는다', (tester) async {
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 10 첫 세트')
        ..addSet('70 8');
      await pumpEditor(tester, c);
      final sets = c.blocks.single.sets;

      await tester.tap(find.text('1 80×10'));
      await tester.pumpAndSettle();
      await keys(tester, '80 10 무릎 아픔');
      expect(sets.first.notes, ['첫 세트'], reason: '치는 동안 글자마다 쌓이지 않는다');
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      expect(sets.first.notes, ['첫 세트', '무릎 아픔']);

      await tester.tap(find.text('2 70×8'));
      await tester.pumpAndSettle();
      await keys(tester, '72.5 8 x3');
      expect(sets, hasLength(2), reason: '치는 동안(x → x3)에는 늘리지 않는다');
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      expect(sets.map((s) => (s.value, s.reps)), [
        (80.0, 10),
        (72.5, 8),
        (72.5, 8),
        (72.5, 8),
      ]);
      expect(sets.first.notes, ['첫 세트', '무릎 아픔'], reason: '다른 세트는 그대로다');
    });

    testWidgets('x3 을 친 채 같은 운동의 뒤 세트를 누르면 누른 그 세트를 고친다', (tester) async {
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 10')
        ..addSet('70 8');
      await pumpEditor(tester, c);
      final sets = c.blocks.single.sets;
      await tester.tap(find.text('1 80×10'));
      await tester.pumpAndSettle();
      await keys(tester, '80 10 x3');
      await tester.tap(find.text('2 70×8'));
      await tester.pumpAndSettle();
      expect(typed(tester), '70kg 8', reason: '누른 세트가 열린다 — 방금 생긴 사본이 아니다');
      await keys(tester, '75 8');
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      // 사본은 addSet 처럼 끝에 붙는다 — 같이 고치는 문서(서버·상대 화면)와 순서가 같다.
      expect(sets.map((s) => (s.value, s.reps)), [
        (80.0, 10),
        (75.0, 8),
        (80.0, 10),
        (80.0, 10),
      ]);
    });

    test('사본은 끝에 붙고 적은 사람을 물려받는다 — 상대 세트가 내 세트로 바뀌지 않는다', () {
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('60 10')
        ..addSet('50 12');
      c.blocks.single.sets.first.author = '민수';
      c.extendSet(0, 0, note: '좋았음', count: 3);
      expect(
        c.blocks.single.sets.map((s) => (s.value, s.author, s.notes.join(','))),
        [
          (60.0, '민수', '좋았음'),
          (50.0, null, ''),
          (60.0, '민수', '좋았음'),
          (60.0, '민수', '좋았음'),
        ],
      );
    });

    testWidgets('고치는 중에 다른 운동을 지워도 줄에 친 메모·xN 은 적용된다', (tester) async {
      final c = RoutineEditorController()
        ..addExercise('스쿼트')
        ..addSet('100 5')
        ..addExercise('벤치프레스')
        ..addSet('80 10');
      await pumpEditor(tester, c);
      await tester.tap(find.text('1 80×10'));
      await tester.pumpAndSettle();
      await keys(tester, '80 10 x2 좋았음');
      await tester.tap(find.byIcon(CupertinoIcons.trash).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CupertinoDialogAction, '삭제'));
      await tester.pumpAndSettle();
      expect(c.blocks.map((b) => b.name), ['벤치프레스']);
      expect(
        c.blocks.single.sets.map((s) => (s.value, s.reps, s.notes.join(','))),
        [(80.0, 10, '좋았음'), (80.0, 10, '좋았음')],
      );
    });

    testWidgets('고치는 중에 다른 운동을 지울 때 못 읽는 글은 입력칸에 남는다', (tester) async {
      final c = RoutineEditorController()
        ..addExercise('스쿼트')
        ..addSet('100 5')
        ..addExercise('벤치프레스')
        ..addSet('80 10');
      await pumpEditor(tester, c);
      await tester.tap(find.text('1 80×10'));
      await tester.pumpAndSettle();
      await keys(tester, '80 10 x30');
      await tester.tap(find.byIcon(CupertinoIcons.trash).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CupertinoDialogAction, '삭제'));
      await tester.pumpAndSettle();
      expect(c.blocks.map((b) => b.name), ['벤치프레스']);
      expect(typed(tester), '80 10 x30');
      expect(find.text('한 번에 20세트까지예요. 줄을 나눠 적어 주세요.'), findsOneWidget);
    });

    testWidgets('고치던 세트를 × 로 지워도 줄에 친 xN 은 버리지 않는다 — 사본이 남는다', (tester) async {
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 10')
        ..addSet('70 8');
      await pumpEditor(tester, c);
      await tester.tap(find.text('2 70×8'));
      await tester.pumpAndSettle();
      await keys(tester, '70 8 x3 무릎');
      await tester.tap(find.byIcon(CupertinoIcons.xmark));
      await tester.pumpAndSettle();
      expect(
        c.blocks.single.sets.map((s) => (s.value, s.reps, s.notes.join(','))),
        [(80.0, 10, ''), (70.0, 8, '무릎'), (70.0, 8, '무릎')],
      );
    });

    testWidgets('X16 한 줄에 20세트를 넘기면 자르지 않고, 글을 두고 이유를 말한다', (tester) async {
      final c = RoutineEditorController()..addExercise('푸시업');
      await pumpEditor(tester, c);
      await keys(tester, '10 x30');
      pad(tester).onSubmit();
      await tester.pumpAndSettle();
      expect(c.blocks.single.sets, isEmpty);
      expect(find.text('한 번에 20세트까지예요. 줄을 나눠 적어 주세요.'), findsOneWidget);
      expect(find.textContaining('세트를 먼저 입력'), findsNothing);
      expect(typed(tester), '10 x30');

      // 고치는 세트에서도 같다 — 원래 세트는 그대로다.
      c.addSet('50 10 x20');
      await tester.pumpAndSettle();
      expect(c.blocks.single.sets, hasLength(20));
      await tester.tap(find.text('1 50×10'));
      await tester.pumpAndSettle();
      await keys(tester, '50 12 x21');
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      expect(find.text('한 번에 20세트까지예요. 줄을 나눠 적어 주세요.'), findsOneWidget);
      expect(c.blocks.single.sets, hasLength(20));
      expect(c.blocks.single.sets.first.reps, 10);
    });
  });

  group('3·4. 완료 후 지우기는 직전 세트로 돌아간다', () {
    testWidgets('키패드: 세트를 지우지 않고 값과 커서를 되돌리며, 고치면 그 세트만 바뀐다', (tester) async {
      final c = RoutineEditorController()..addExercise('벤치프레스');
      await pumpEditor(tester, c);
      await keys(tester, '80 10');
      await tester.tap(padKey('세트 추가'));
      await tester.pumpAndSettle();
      await keys(tester, '82.5 8');
      await tester.tap(padKey('세트 추가'));
      await tester.pumpAndSettle();

      pad(tester).onBackspace(); // 빈 새 세트 줄에서
      await tester.pumpAndSettle();
      final sets = c.blocks.single.sets;
      expect(sets.map((s) => (s.value, s.reps)), [(80.0, 10), (82.5, 8)]);
      final field = tester.widget<CupertinoTextField>(input).controller!;
      expect(field.text, '82.5kg 8');
      expect(field.selection, const TextSelection.collapsed(offset: 8));

      pad(tester).onBackspace(); // 이제는 글자를 지운다
      await keys(tester, '6');
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      expect(sets.map((s) => (s.value, s.reps)), [(80.0, 10), (82.5, 6)]);
    });

    testWidgets('화면 키보드: 운동을 끝낸 빈 칸에서 지우면 방금 끝낸 앞쪽 운동으로 간다', (tester) async {
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 10')
        ..addSet('85 6')
        ..addExercise('스쿼트')
        ..addSet('100 5')
        ..closeBlock();
      await pumpEditor(tester, c);
      // 앞쪽 운동을 다시 열었다가 끝낸다.
      await tester.tap(
        find.descendant(
          of: find.byType(SliverReorderableList),
          matching: find.text('벤치프레스'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(c.naming, isTrue);
      expect(c.lastClosed, same(c.blocks.first));

      // 화면 키보드는 빈 칸의 지우기를 알리지 않는다. 심어 둔 글자가 지워지는
      // 것으로 안다 — 기기에서 일어나는 일 그대로다.
      expect(
        tester.widget<CupertinoTextField>(input).controller!.text,
        String.fromCharCode(0x200B),
      );
      expect(find.text('운동 이름'), findsOneWidget, reason: '안내문은 그대로 보인다');
      await tester.enterText(input, '');
      await tester.pumpAndSettle();

      expect(c.activeIndex, 0, reason: '문서의 마지막 운동이 아니다');
      expect(typed(tester), '85kg 6');
      expect(c.blocks.first.sets.map((s) => s.reps), [10, 6]);
      expect(c.blocks.last.sets, hasLength(1));

      pad(tester).onBackspace();
      await keys(tester, '5');
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      expect(c.blocks.first.sets.map((s) => s.reps), [10, 5]);
      expect(c.naming, isTrue);
    });

    testWidgets('물리 키보드도 같고, 세트 없는 운동·빈 문서에서는 아무것도 잃지 않는다', (tester) async {
      final c = RoutineEditorController();
      await pumpEditor(tester, c);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace); // 빈 문서
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      c
        ..addExercise('풀업')
        ..addSet('8')
        ..closeBlock();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();
      expect(typed(tester), '8');
      expect(c.blocks.single.sets.single.reps, 8);
    });
  });

  group('5·6·7. 식단', () {
    test('글을 확인되는 만큼만 구조로 읽고, 열량은 적었을 때만 있다', () {
      final lunch = parseMealText('점심 김밥 한 줄, 라면 반 개');
      expect(lunch.kcal, isNull, reason: '모르는 열량은 0 이 아니다');
      expect(lunch.foods.map((f) => (f.name, f.amount, f.unit)), [
        ('점심 김밥', 1.0, '줄'),
        ('라면', 0.5, '개'),
      ]);
      final snack = parseMealText('바나나 2개, 우유 200ml');
      expect(snack.foods.map((f) => (f.name, f.amount, f.unit)), [
        ('바나나', 2.0, '개'),
        ('우유', 200.0, 'ml'),
      ]);
      final vague = parseMealText('집에서 만든 볶음밥 조금');
      expect(vague.foods.single.name, '집에서 만든 볶음밥 조금');
      expect(vague.foods.single.amount, isNull);
      final known = parseMealText('닭가슴살 150g 165kcal');
      expect(known.kcal, 165);
      expect(known.foods.single.amount, 150);
    });

    test('먹은 양으로 계산하고, 근거 없는 값은 미상이다', () {
      const per100g = MealBasis(kcal: 250, amount: 100, unit: 'g');
      expect(per100g.kcalFor(150), 375);
      const each = MealBasis(kcal: 120, amount: 1, unit: '개');
      expect(each.kcalFor(2.5), 300);
      const bag = MealBasis(kcal: 300, amount: 1, unit: MealBasis.package);
      expect(bag.kcalFor(0.5), 150);
      // 반올림은 마지막에 한 번 — 33.3 × 3 은 100 이다.
      const third = MealBasis(kcal: 33.3, amount: 1, unit: '개');
      expect(third.kcalFor(3), 100);
      expect(per100g.kcalFor(-1), isNull);
      expect(
        const MealBasis(kcal: 250, amount: 0, unit: 'g').kcalFor(100),
        isNull,
        reason: '분모 0',
      );
      expect(
        MealBasis.tryFromJson({'kcal': -5, 'amount': 1, 'unit': 'g'}),
        isNull,
      );

      // 성분표: 인쇄된 단위가 먼저, 회분은 늘, 포장은 총 회분이 1 이어도.
      final bases = basesOf(
        const NutritionLabel(
          perServingKcal: 300,
          servingSize: '1봉지 (80g)',
          servingsPerPackage: 1,
        ),
      );
      expect(bases.map((b) => b.unit), [
        '봉지',
        MealBasis.serving,
        MealBasis.package,
      ]);
      expect(bases.last.kcalFor(0.5), 150);
      // g 과 ml 을 서로 바꿔 주지 않는다 — 인쇄된 단위 하나만 낸다.
      expect(
        basesOf(
          const NutritionLabel(perServingKcal: 250, servingSize: '100g'),
        ).map((b) => b.unit),
        ['g', MealBasis.serving],
      );
    });

    test('예전 기록을 그대로 읽고, 미상 열량은 합계에 총합인 척 섞이지 않는다', () {
      final old = MealEntry.tryFromJson({
        'at': '2026-09-01T12:00:00.000',
        'kcal': 650,
        'items': ['김치찌개'],
      })!;
      expect(old.kcal, 650);
      expect(old.items, ['김치찌개']);
      expect(old.text, isNull);
      expect(old.approximate, isTrue, reason: '예전 것은 사진 어림이다');
      expect(MealEntry.tryFromJson({'at': '2026-09-01T12:00:00.000'}), isNull);

      final note = Note(
        id: 'n',
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
      );
      note.meals
        ..add(old)
        ..add(MealEntry(at: DateTime(2026, 9, 21, 13), kcal: null, text: '볶음밥'))
        ..add(
          MealEntry(
            at: DateTime(2026, 9, 21, 19),
            kcal: 375,
            source: MealEntry.label,
            basis: const MealBasis(kcal: 250, amount: 100, unit: 'g'),
            eaten: 150,
          ),
        );
      final back = Note.fromJson(
        jsonDecode(jsonEncode(note.toJson())) as Map<String, dynamic>,
      );
      expect(back.meals, hasLength(3));
      expect(back.intake, 1025);
      expect(back.unknownMeals, 1);
      expect(back.meals[1].kcal, isNull);
      expect(back.meals[1].text, '볶음밥');
      expect(back.meals[2].basis!.kcalFor(back.meals[2].eaten!), 375);
      expect(back.meals[2].approximate, isFalse);
    });

    testWidgets('글로 적은 식단은 그물 없이 저장되고, 다시 열어 고쳐도 하나다', (tester) async {
      final dir = Directory.systemTemp.createTempSync('setpad_meal_');
      final store = NotesStore(directory: dir);
      addTearDown(() {
        store.dispose();
        dir.deleteSync(recursive: true);
      });
      final note = store.create();
      // 서버를 못 쓰는 상태 — 기본 RecordAi 는 기기 id 가 없어 지원되지 않는다.
      await pumpPage(tester, EditorPage(store: store, note: note));
      // 식단 적기는 입력 줄 위 막대에 있다 — 화면 맨 위의 버튼은 뺐다.
      await tester.tap(find.byKey(const ValueKey('meal-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('meal-text-toggle')));
      await tester.pumpAndSettle();
      await submit(tester, '점심 김밥 한 줄, 라면 반 개');
      expect(note.meals.single.text, '점심 김밥 한 줄, 라면 반 개');
      expect(note.meals.single.kcal, isNull);
      expect(note.blocks, isEmpty, reason: '식단이 운동 이름이 되면 안 된다');
      expect(find.textContaining('열량 미상'), findsWidgets);

      // 그 줄을 눌러 고친다 — 새 끼니가 생기지 않는다.
      await tester.tap(find.byKey(const ValueKey('meal-0')));
      await tester.pumpAndSettle();
      expect(typed(tester), '점심 김밥 한 줄, 라면 반 개');
      await submit(tester, '점심 김밥 한 줄 450kcal');
      expect(note.meals.single.kcal, 450);
      expect(note.meals.single.source, MealEntry.typed);

      await tester.pumpWidget(const SizedBox());
      await flush(tester, store);
      final reopened = NotesStore(directory: dir);
      addTearDown(reopened.dispose);
      await tester.runAsync(reopened.load);
      final meal = reopened.notes.single.meals.single;
      expect(meal.text, '점심 김밥 한 줄 450kcal');
      expect(meal.kcal, 450);
      expect(meal.foods.single.unit, '줄');
    });

    testWidgets('운동 이름을 적는 줄에 음식을 쳤으면 포크·나이프를 한 번 눌러 끼니로 남긴다 — 알아서 바꾸지는 않는다', (
      tester,
    ) async {
      final dir = Directory.systemTemp.createTempSync('setpad_meal_chip_');
      final store = NotesStore(directory: dir);
      addTearDown(() {
        store.dispose();
        dir.deleteSync(recursive: true);
      });
      final note = store.create();
      await pumpPage(tester, EditorPage(store: store, note: note));

      // 따로 누를 칩은 없다 — 포크·나이프가 친 글을 끼니로 보낸다.
      await tester.enterText(input, '김치찌개');
      await tester.pump();
      expect(find.text('식단으로 기록'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('meal-button')));
      await tester.pumpAndSettle();
      expect(note.meals.single.text, '김치찌개');
      expect(note.blocks, isEmpty, reason: '운동 칸이 생기면 안 된다');
      expect(typed(tester), isEmpty, reason: '입력 줄은 비워져 다음 것을 칠 수 있다');

      // 누르지 않고 그냥 넣으면 예전 그대로 운동 이름이다 — 앱이 음식이라고 넘겨짚지 않는다.
      await submit(tester, '케이블 크런치');
      expect(note.blocks.single.name, '케이블 크런치');
      expect(note.meals, hasLength(1));

      await tester.pumpWidget(const SizedBox());
      await flush(tester, store);
    });

    testWidgets('먹은 양을 직접 받아 계산하고, 취소하면 아무것도 돌려주지 않는다', (tester) async {
      ({MealBasis basis, double eaten})? picked;
      late BuildContext context;
      await pumpPage(
        tester,
        CupertinoPageScaffold(
          child: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      Future<void> open() async {
        askMealAmount(
          context,
          bases: basesOf(
            const NutritionLabel(perServingKcal: 250, servingSize: '100g'),
          ),
        ).then((v) => picked = v);
        await tester.pumpAndSettle();
      }

      await open();
      await tester.enterText(find.byKey(const ValueKey('meal-eaten')), '150');
      await tester.pump();
      expect(find.text('375kcal'), findsOneWidget);
      // 읽은 값이 틀렸으면 근거도 고친다.
      await tester.enterText(
        find.byKey(const ValueKey('meal-basis-kcal')),
        '260',
      );
      await tester.pump();
      expect(find.text('390kcal'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('meal-eaten')), '-3');
      await tester.pump();
      expect(find.text('390kcal'), findsNothing, reason: '음수는 받지 않는다');
      await tester.enterText(find.byKey(const ValueKey('meal-eaten')), '150');
      await tester.pump();
      await tester.tap(find.text('완료'));
      await tester.pumpAndSettle();
      expect(picked!.basis.kcalFor(picked!.eaten), 390);

      picked = null;
      await open();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(picked, isNull);
    });
  });

  group('8. 오늘 한 세트 전부', () {
    testWidgets('390×844 에서 8종목 40세트가 스크롤 없이 다 보이고, 칸을 누르면 그 세트를 고친다', (
      tester,
    ) async {
      await tester.runAsync(loadRealFont);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.reset);

      const names = [
        '벤치프레스',
        '벽 짚고 반쯤 스쿼트',
        '내 방식 벤치 변형',
        '풀업',
        '인클라인 덤벨 프레스',
        '민수식 로우 2',
        '레그프레스',
        '플랭크',
      ];
      final dir = Directory.systemTemp.createTempSync('setpad_forty_');
      final store = NotesStore(directory: dir);
      addTearDown(() {
        store.dispose();
        dir.deleteSync(recursive: true);
      });
      final blocks = [
        for (final (i, name) in names.indexed)
          ExerciseBlock(name, [
            for (var s = 0; s < 5; s++)
              name == '풀업'
                  ? LoggedSet(reps: 12 - s)
                  : name == '플랭크'
                  ? LoggedSet(value: 60.0 - s * 5, unit: 's')
                  : LoggedSet(
                      // 두 자리 무게. 세 자리 값이 다섯 개 꽉 찬 줄에는 늘 남겨 두는 빈 칸
                      // (다음 세트 자리)이 다음 줄로 내려가 그 종목만 한 줄 더 쓴다.
                      value: 40 + i * 7 + s * 2.5,
                      unit: i == 6 ? 'lb' : 'kg',
                      reps: 12 - s - (i % 3),
                    ),
          ]),
      ];
      final note = store.create(blocks: blocks);
      await pumpPage(tester, EditorPage(store: store, note: note));
      // 키보드를 닫는다 — 빈 곳(날짜 줄)을 누른다.
      await tester.tapAt(const Offset(195, 110));
      await tester.pumpAndSettle();

      final scroll = tester
          .widget<CustomScrollView>(
            find.descendant(
              of: find.byType(RoutineEditor),
              matching: find.byType(CustomScrollView),
            ),
          )
          .controller!;
      expect(scroll.offset, 0);
      const screen = Rect.fromLTRB(0, 47, 390, 844 - 34);
      var cells = 0;
      for (final block in blocks) {
        final title = find.descendant(
          of: find.byType(SliverReorderableList),
          matching: find.text(block.name),
        );
        expect(title, findsOneWidget);
        final titleRect = tester.getRect(title);
        expect(
          screen.contains(titleRect.topLeft) &&
              screen.contains(titleRect.bottomRight),
          isTrue,
          reason: '${block.name} 이 화면 안에 있어야 한다',
        );
        expect(
          tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
          isFalse,
        );
      }
      for (final cell
          in find
              .byWidgetPredicate(
                (w) => w.key is ValueKey && '${w.key}'.contains('set-cell-'),
              )
              .evaluate()) {
        final box = cell.renderObject! as RenderBox;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        expect(
          screen.contains(rect.topLeft) && screen.contains(rect.bottomRight),
          isTrue,
          reason: '세트 칸 $rect 이 화면 밖이다',
        );
        cells++;
      }
      expect(cells, 40, reason: '세트마다 한 칸 — 합치지도 접지도 않는다');
      // 값이 서로 다른 세트가 제 값으로 적혀 있다. 단위가 다른 운동은 제목 줄에.
      expect(find.text('1 40×12'), findsOneWidget);
      expect(find.text('5 50×8'), findsOneWidget);
      expect(find.text('1 12회'), findsOneWidget);
      expect(find.text('5 40초'), findsOneWidget);
      expect(find.text('lb'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 칸을 누르면 바로 그 세트를 고친다. 앞쪽 운동의 가운데 세트로 본다.
      await tester.tap(find.text('3 45×10'));
      await tester.pumpAndSettle();
      expect(typed(tester), '45kg 10');
      await keys(tester, '47.5 10');
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      expect(blocks.first.sets[2].value, 47.5);
      expect(blocks.first.sets, hasLength(5));
      expect(find.text('3 47.5×10'), findsOneWidget);
    });

    testWidgets('하루에 기록은 한 곳이고, 아래에는 지난주 같은 요일 운동이 접혀 보인다', (tester) async {
      final dir = Directory.systemTemp.createTempSync('setpad_lastweek_');
      final store = NotesStore(directory: dir);
      addTearDown(() {
        store.dispose();
        dir.deleteSync(recursive: true);
      });
      final now = DateTime.now();
      final lastWeek = store.create(
        at: now.subtract(const Duration(days: 7)),
        blocks: [
          ExerciseBlock('아침 달리기', [LoggedSet(value: 5, unit: 'km')]),
        ],
      );
      final today = store.today()
        ..blocks.add(ExerciseBlock('벤치프레스', [LoggedSet(value: 80, reps: 10)]));
      expect(
        identical(store.today(), today),
        isTrue,
        reason: '오늘 기록이 있으면 새로 만들지 않는다',
      );
      await pumpPage(tester, EditorPage(store: store, note: today));
      expect(find.textContaining(RegExp(r'^지난주 .+ 운동')), findsOneWidget);
      // 기본은 접힌 한 줄 — 누르면 세트까지 펼친다.
      expect(find.textContaining('아침 달리기'), findsOneWidget);
      expect(find.text('1 5km'), findsNothing);
      await tester.tap(find.byKey(ValueKey('past-${lastWeek.id}')));
      await tester.pumpAndSettle();
      expect(find.text('1 5km'), findsOneWidget);
    });
  });
}
