import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/keypad.dart';

import 'widget_test.dart'
    show pumpApp, settle, padField, padKey, tapKeys, addSetButton;

RoutineEditorController controller(WidgetTester tester) =>
    tester.widget<RoutineEditor>(find.byType(RoutineEditor)).controller;

Future<void> startExercise(WidgetTester tester) async {
  await pumpApp(tester);
  await tester.enterText(padField, '벤치프레스');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await settle(tester);
}

Future<void> openMemo(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(SetKeypad),
      matching: find.byIcon(CupertinoIcons.keyboard),
    ),
  );
  await settle(tester);
}

void main() {
  testWidgets('본문에서 입력하고 키패드에는 세트 추가와 다음 키만 둔다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await startExercise(tester);
    expect(
      find.descendant(
        of: find.byType(SetKeypad),
        matching: find.byType(CupertinoTextField),
      ),
      findsNothing,
    );
    final add = tester.getRect(addSetButton);
    final finish = tester.getRect(padKey('운동 완료'));
    expect(add.bottom, lessThan(finish.top));
    expect(tester.widget<CupertinoTextField>(padField).showCursor, isFalse);
    await tester.tap(addSetButton);
    await settle(tester);
    expect(controller(tester).inBlock, isTrue);
    expect(controller(tester).lastSet, isNull);
    for (var i = 0; i < 12; i++) {
      await tapKeys(tester, '60 12');
      await tester.tap(addSetButton);
      await settle(tester);
      final viewport = tester.getRect(
        find.descendant(
          of: find.byType(RoutineEditor),
          matching: find.byType(CustomScrollView),
        ),
      );
      expect(
        tester.getRect(padField).bottom,
        lessThanOrEqualTo(viewport.bottom + 1),
      );
      expect(tester.getRect(addSetButton), add);
      expect(tester.getRect(padKey('운동 완료')), finish);
    }
    expect(controller(tester).blocks.single.sets, hasLength(12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('다음은 횟수 입력과 세트 저장을 이어가고 빈 칸에서만 운동을 완료한다', (tester) async {
    await startExercise(tester);
    final c = controller(tester);
    expect(padKey('다음'), findsNothing);
    await tapKeys(tester, '60');
    expect(padKey('운동 완료'), findsNothing);
    await tester.tap(padKey('다음'));
    await settle(tester);
    expect(tester.widget<CupertinoTextField>(padField).controller!.text, '60 ');
    expect(c.lastSet, isNull);
    await tapKeys(tester, '12');
    await tester.tap(padKey('다음'));
    await settle(tester);
    expect(c.inBlock, isTrue);
    expect(c.blocks.single.sets.single.value, 60);
    expect(c.blocks.single.sets.single.reps, 12);
    expect(padKey('다음'), findsNothing);
    await tester.tap(padKey('운동 완료'));
    await settle(tester);
    expect(c.naming, isTrue);
  });

  testWidgets('여러 줄 메모는 넓게 입력하고 키패드로 돌아올 때 저장한다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await startExercise(tester);
    final c = controller(tester)..addSet('60 12');
    await settle(tester);
    await openMemo(tester);
    final field = tester.widget<CupertinoTextField>(padField);
    expect(field.maxLines, isNull);
    expect(field.textInputAction, TextInputAction.done);
    expect(tester.getRect(padField).left, 30); // 메모 글과 같은 자리
    const memo = '어깨가 조금 불편함\n다음에는 무게를 낮추기';
    await tester.enterText(padField, memo);
    // Dismissing the native keyboard must not reinterpret this as a set draft.
    field.focusNode!.unfocus();
    await settle(tester);
    expect(find.text('메모 저장'), findsNothing);
    expect(find.text('숫자 키패드'), findsOneWidget);
    await tester.tap(find.text('숫자 키패드'));
    await settle(tester);
    expect(c.blocks, hasLength(1));
    expect(c.lastSet!.notes, [memo]);
    expect(find.byType(SetKeypad), findsOneWidget);
    expect(find.text(memo), findsOneWidget);
  });

  testWidgets('메모 저장은 입력하던 숫자를 보존한다', (tester) async {
    await startExercise(tester);
    final c = controller(tester)..addSet('60 12');
    await settle(tester);
    await tapKeys(tester, '65 10');
    await openMemo(tester);
    expect(
      tester.widget<CupertinoTextField>(padField).controller!.text,
      isEmpty,
    );
    await tester.enterText(padField, '다음 세트는 증량');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(c.lastSet!.notes, ['다음 세트는 증량']);
    expect(
      tester.widget<CupertinoTextField>(padField).controller!.text,
      '65 10',
    );
  });

  testWidgets('빈 운동의 자유 텍스트는 새 운동으로 바뀌거나 사라지지 않는다', (tester) async {
    await startExercise(tester);
    await openMemo(tester);
    await tester.enterText(padField, '오늘은 무슨 운동을 할까?');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(controller(tester).blocks, hasLength(1));
    expect(controller(tester).lastSet, isNull);
    expect(find.text('세트를 먼저 입력해 주세요. 예: 60 12'), findsOneWidget);
    expect(
      tester.widget<CupertinoTextField>(padField).controller!.text,
      '오늘은 무슨 운동을 할까?',
    );
  });

  testWidgets('이전 운동의 메모를 고쳐도 해당 세트만 바뀐다', (tester) async {
    await startExercise(tester);
    final c = controller(tester)
      ..addSet('60 12 어깨 불편')
      ..closeBlock()
      ..addExercise('스쿼트')
      ..addSet('80 10');
    await settle(tester);
    await tester.tap(find.text('어깨 불편'));
    await settle(tester);
    await tester.enterText(padField, '무게를 낮추니 괜찮음\n자세 유지');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(c.blocks.first.sets.single.notes, ['무게를 낮추니 괜찮음\n자세 유지']);
    expect(c.blocks.last.sets.single.notes, isEmpty);
    expect(c.activeIndex, 0);
  });

  test('반복 세트의 메모와 완료 상태는 서로 독립적이다', () {
    final c = RoutineEditorController()
      ..addExercise('벤치프레스')
      ..addSet('60 12 x2');
    c.noteLastSet('마지막 세트');
    c.toggleDone(0, 1);
    expect(c.blocks.single.sets.first.notes, isEmpty);
    expect(c.blocks.single.sets.first.done, isTrue);
    c.repeatLastSet();
    c.noteLastSet('반복한 세트');
    expect(c.blocks.single.sets[1].notes, ['마지막 세트']);
    expect(c.lastSet!.notes, ['마지막 세트', '반복한 세트']);
    expect(c.lastSet!.done, isTrue);
  });
}
