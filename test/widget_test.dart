import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/main.dart';

void main() {
  group('에디터 상태', () {
    test('처음에는 이름을 받고, 이름을 넣으면 세트를 받는다', () {
      final c = RoutineEditorController();
      expect(c.naming, isTrue);
      c.commit('벤치프레스');
      expect(c.naming, isFalse);
      expect(c.blocks.single.name, '벤치프레스');
    });

    test('세트를 넣으면 다시 이름을 받는 상태가 된다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 20회');
      expect(c.blocks.single.sets.length, 1);
      expect(c.naming, isTrue);
    });

    test('반복 세트는 그 수만큼 쌓인다', () {
      final c = RoutineEditorController()..commit('스쿼트');
      c.commit('100kg 5회 x5');
      expect(c.blocks.single.sets.length, 5);
      expect(c.totalSets, 5);
    });

    test('세트를 받는 중에 숫자 없는 줄이 오면 다음 운동이다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 10회');
      c.commit('스쿼트');
      expect(c.blocks.length, 2);
      expect(c.blocks.last.name, '스쿼트');
    });

    test('지우기는 세트부터, 세트가 없으면 운동을 뗀다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 10회 x2');
      c.backspace();
      expect(c.blocks.single.sets.length, 1);
      c.backspace();
      expect(c.blocks.single.sets, isEmpty);
      c.backspace();
      expect(c.blocks, isEmpty);
      c.backspace(); // 비어 있어도 터지지 않는다
      expect(c.blocks, isEmpty);
    });

    test('친 이름이 씨앗 목록보다 먼저 제안된다', () {
      final c = RoutineEditorController()..commit('벤치 살짝 기울여서');
      expect(c.vocabulary.first, '벤치 살짝 기울여서');
    });

    test('복사용 텍스트는 세트가 있는 운동만 담는다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 10회 x2');
      c.commit('스쿼트'); // 세트 없이 남겨둔다
      expect(c.asText(), '벤치프레스\n1세트 100kg · 10회\n2세트 100kg · 10회');
    });
  });

  group('화면', () {
    testWidgets('이름을 치고 넣으면 화면에 뜬다', (tester) async {
      await tester.pumpWidget(const SetpadApp());

      await tester.enterText(find.byType(TextField), '벤치프레스');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('벤치프레스'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '100kg 20회');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('100kg · 20회'), findsOneWidget);
      expect(find.text('1세트'), findsOneWidget);
    });

    testWidgets('"벤"을 치면 후보가 뜨고 눌러서 고를 수 있다', (tester) async {
      await tester.pumpWidget(const SetpadApp());

      await tester.enterText(find.byType(TextField), '벤');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, '벤치프레스'), findsOneWidget);

      await tester.tap(find.widgetWithText(ActionChip, '벤치프레스'));
      await tester.pumpAndSettle();
      // 후보는 사라지고 운동 블록이 생긴다
      expect(find.widgetWithText(ActionChip, '벤치프레스'), findsNothing);
      expect(find.text('벤치프레스'), findsOneWidget);
    });

    testWidgets('빈 화면에는 쓰는 법이 적혀 있다', (tester) async {
      await tester.pumpWidget(const SetpadApp());
      expect(find.text('운동 이름부터'), findsOneWidget);
    });
  });
}
