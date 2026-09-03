import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/main.dart';

void main() {
  group('세트 입력', () {
    test('운동을 넣으면 첫 세트의 무게 칸에 커서가 선다', () {
      final c = RoutineEditorController();
      expect(c.naming, isTrue);
      c.addExercise('벤치프레스');
      expect(c.naming, isFalse);
      expect(c.cursor, (block: 0, set: 0, field: Field.kg));
      expect(c.blocks.single.sets.length, 1);
    });

    test('숫자를 눌러 무게가 들어간다', () {
      final c = RoutineEditorController()..addExercise('벤치프레스');
      for (final d in ['1', '0', '0']) {
        c.press(d);
      }
      expect(c.blocks.single.sets.first.kg, 100);
    });

    test('소수점은 한 번만, 앞이 비면 0을 세워 준다', () {
      final c = RoutineEditorController()..addExercise('덤벨컬');
      c.press('.');
      expect(c.buffer, '0.');
      c.press('5');
      c.press('.'); // 두 번째 점은 무시
      expect(c.blocks.single.sets.first.kg, 0.5);
    });

    test('다음 버튼이 무게 → 횟수 → 다음 세트로 민다', () {
      final c = RoutineEditorController()..addExercise('스쿼트');
      c.press('9');
      c.press('0');
      c.next();
      expect(c.cursor?.field, Field.reps);
      c.press('5');
      c.next();
      // 세트가 확정되고 다음 줄이 생긴다
      expect(c.blocks.single.sets.length, 2);
      expect(c.cursor, (block: 0, set: 1, field: Field.kg));
    });

    test('새 세트에는 직전 값이 미리 들어간다', () {
      final c = RoutineEditorController()..addExercise('스쿼트');
      c.press('9');
      c.press('0');
      c.next();
      c.press('5');
      c.next();
      final second = c.blocks.single.sets[1];
      expect(second.kg, 90);
      expect(second.reps, 5);
    });

    test('빈 세트는 완료되지 않는다', () {
      final c = RoutineEditorController()..addExercise('스쿼트');
      c.completeSet();
      expect(c.blocks.single.sets.length, 1);
    });

    test('지우기는 마지막 숫자부터', () {
      final c = RoutineEditorController()..addExercise('스쿼트');
      c.press('1');
      c.press('0');
      c.press('5');
      c.backspace();
      expect(c.blocks.single.sets.first.kg, 10);
      c.backspace();
      c.backspace();
      expect(c.blocks.single.sets.first.kg, isNull);
    });

    test('칸을 눌러 커서를 옮기면 그 값이 이어서 고쳐진다', () {
      final c = RoutineEditorController()..addExercise('스쿼트');
      c.press('9');
      c.press('0');
      c.next();
      c.press('5');
      c.tap(0, 0, Field.kg);
      expect(c.buffer, '90');
      c.press('5'); // 90 → 905
      expect(c.blocks.single.sets.first.kg, 905);
    });
  });

  group('운동 닫기', () {
    test('채우다 만 세트는 남지 않는다', () {
      final c = RoutineEditorController()..addExercise('스쿼트');
      c.press('9');
      c.press('0');
      c.next();
      c.press('5');
      c.next(); // 2세트가 미리 채워진 채로 생긴다
      c.closeBlock();
      // 미리 채워진 2세트도 값이 있으므로 남는다
      expect(c.blocks.single.sets.length, 2);
      expect(c.naming, isTrue);
    });

    test('아무것도 안 채우고 닫으면 그 운동은 사라진다', () {
      final c = RoutineEditorController()..addExercise('스쿼트');
      c.closeBlock();
      expect(c.blocks, isEmpty);
      expect(c.naming, isTrue);
    });

    test('세트는 지울 수 있지만 마지막 하나는 남는다', () {
      final c = RoutineEditorController()..addExercise('스쿼트');
      c.press('9');
      c.next();
      c.press('5');
      c.next();
      expect(c.blocks.single.sets.length, 2);
      c.removeSet(0, 1);
      expect(c.blocks.single.sets.length, 1);
      c.removeSet(0, 0);
      expect(c.blocks.single.sets.length, 1);
    });
  });

  group('내보내기', () {
    test('값이 있는 세트만 담는다', () {
      final c = RoutineEditorController()..addExercise('벤치프레스');
      c.press('1');
      c.press('0');
      c.press('0');
      c.next();
      c.press('8');
      c.completeSet();
      c.closeBlock();
      expect(c.asText(), '벤치프레스\n1세트 100kg · 8회\n2세트 100kg · 8회');
    });

    test('친 이름이 씨앗 목록보다 먼저 제안된다', () {
      final c = RoutineEditorController()..addExercise('벤치 살짝 기울여서');
      expect(c.vocabulary.first, '벤치 살짝 기울여서');
    });
  });

  group('화면', () {
    testWidgets('처음에는 이름 칸만, 운동을 넣으면 키패드가 뜬다', (tester) async {
      await tester.pumpWidget(const SetpadApp());
      expect(find.byType(NumberPad), findsNothing);

      await tester.enterText(find.byType(TextField), '벤치프레스');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('벤치프레스'), findsOneWidget);
      expect(find.byType(NumberPad), findsOneWidget);
      // 이름을 받았으면 시스템 키보드가 필요 없다
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('키패드만으로 한 세트가 완성된다', (tester) async {
      await tester.pumpWidget(const SetpadApp());
      await tester.enterText(find.byType(TextField), '스쿼트');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      Finder key(String label) => find.descendant(
            of: find.byType(NumberPad),
            matching: find.text(label),
          );
      for (final k in ['1', '0', '0']) {
        await tester.tap(key(k));
        await tester.pump();
      }
      await tester.tap(key('횟수 →'));
      await tester.pump();
      await tester.tap(key('8'));
      await tester.pump();
      await tester.tap(key('세트 완료'));
      await tester.pumpAndSettle();

      // 1세트가 확정되고, 같은 값이 채워진 2세트가 기다린다
      expect(find.text('100'), findsWidgets);
      expect(find.text('8'), findsWidgets);
    });

    testWidgets('"벤"을 치면 후보가 뜨고 눌러서 고를 수 있다', (tester) async {
      await tester.pumpWidget(const SetpadApp());
      await tester.enterText(find.byType(TextField), '벤');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, '벤치프레스'), findsOneWidget);

      await tester.tap(find.widgetWithText(ActionChip, '벤치프레스'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, '벤치프레스'), findsNothing);
      expect(find.text('벤치프레스'), findsOneWidget);
    });
  });

  plusMinusTests();
}

void plusMinusTests() {
  group('증감', () {
    test('무게는 원판 단위로 오르내린다', () {
      final c = RoutineEditorController()..addExercise('스쿼트');
      c.press('6');
      c.press('0');
      c.adjust(1);
      expect(c.blocks.single.sets.first.kg, 62.5);
      c.adjust(-1);
      c.adjust(-1);
      expect(c.blocks.single.sets.first.kg, 57.5);
    });

    test('횟수는 하나씩', () {
      final c = RoutineEditorController()..addExercise('스쿼트');
      c.next(); // 횟수 칸으로
      c.adjust(1);
      expect(c.blocks.single.sets.first.reps, 1);
      c.adjust(1);
      expect(c.blocks.single.sets.first.reps, 2);
    });

    test('0 아래로는 내려가지 않고, 빈 값이 된다', () {
      final c = RoutineEditorController()..addExercise('스쿼트');
      c.adjust(-1);
      expect(c.blocks.single.sets.first.kg, isNull);
    });

    test('증감한 값에 이어서 숫자를 칠 수 있다', () {
      final c = RoutineEditorController()..addExercise('스쿼트');
      c.adjust(1); // 2.5
      c.press('0'); // 2.50
      expect(c.blocks.single.sets.first.kg, 2.5);
    });
  });

  group('완료 표시', () {
    test('손으로 켜고 끌 수 있다', () {
      final c = RoutineEditorController()..addExercise('스쿼트');
      c.press('6');
      c.press('0');
      c.toggleDone(0, 0);
      expect(c.blocks.single.sets.first.done, isTrue);
      c.toggleDone(0, 0);
      expect(c.blocks.single.sets.first.done, isFalse);
    });

    test('빈 세트는 완료로 표시되지 않는다', () {
      final c = RoutineEditorController()..addExercise('스쿼트');
      c.toggleDone(0, 0);
      expect(c.blocks.single.sets.first.done, isFalse);
    });
  });
}
