import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/keypad.dart';
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

    test('세트를 넣어도 그 운동 안에 머문다 — 세트를 더 칠 수 있어야 한다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 20회');
      expect(c.blocks.single.sets.length, 1);
      expect(c.inBlock, isTrue);
      c.commit('100kg 18회');
      expect(c.blocks.single.sets.length, 2);
    });

    test('빈 줄에서 Enter면 그 운동을 닫고 나온다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 20회');
      c.commit('');
      expect(c.naming, isTrue);
      c.commit('스쿼트');
      expect(c.blocks.length, 2);
    });

    test('세트를 하나도 안 적고 닫으면 그 운동은 남지 않는다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('');
      expect(c.blocks, isEmpty);
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
      expect(c.inBlock, isTrue);
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
      // 비어 있어도 터지지 않는다
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
    testWidgets('이름을 치면 화면에 뜨고, 세트 칸으로 넘어간다', (tester) async {
      await tester.pumpWidget(const SetpadApp());

      await tester.enterText(find.byType(TextField), '벤치프레스');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('벤치프레스'), findsOneWidget);

      // 세트 칸은 터치 기기에서 읽기 전용이다 — 시스템 키보드를 부르지 않고
      // 키패드가 글자를 넣는다. 실제 사용 경로가 그쪽이므로 여기서도 그렇게 친다.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.readOnly, isTrue);
      expect(find.byType(SetKeypad), findsOneWidget);
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
      expect(find.textContaining('운동 이름을 치고 Enter'), findsOneWidget);
    });
  });

  keypadTests();
}

void keypadTests() {
  group('키패드', () {
    test('직전 세트를 그대로 한 번 더 넣는다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 20회 어깨 뻐근');
      c.repeatLastSet();
      expect(c.blocks.single.sets.length, 2);
      final last = c.blocks.single.sets.last;
      expect(last.kg, 100);
      expect(last.reps, 20);
      expect(last.note, '어깨 뻐근');
    });

    test('세트가 없으면 반복할 것도 없다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      expect(c.lastSet, isNull);
      c.repeatLastSet();
      expect(c.blocks.single.sets, isEmpty);
    });

    test('운동 이름을 받는 중에는 반복 대상이 없다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 20회');
      c.commit(''); // 운동 닫기
      expect(c.lastSet, isNull);
    });
  });

  group('키패드 화면', () {
    testWidgets('세트를 받는 중에만 키패드가 뜬다', (tester) async {
      await tester.pumpWidget(const SetpadApp());
      // 처음엔 운동 이름을 받으므로 키패드가 없다
      expect(find.byType(SetKeypad), findsNothing);

      await tester.enterText(find.byType(TextField), '벤치프레스');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(SetKeypad), findsOneWidget);
    });

    testWidgets('키패드만으로 세트 한 줄이 완성된다', (tester) async {
      await tester.pumpWidget(const SetpadApp());
      await tester.enterText(find.byType(TextField), '스쿼트');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // 키패드 안에서만 찾는다 — 화면에도 같은 숫자가 떠 있을 수 있다.
      Finder key(String label) => find.descendant(
            of: find.byType(SetKeypad),
            matching: find.text(label),
          );
      for (final k in ['1', '0', '0', 'kg', '2', '0', '회']) {
        await tester.tap(key(k));
        await tester.pump();
      }
      await tester.tap(key('세트 추가'));
      await tester.pumpAndSettle();

      expect(find.text('100kg · 20회'), findsOneWidget);
    });
  });
}
