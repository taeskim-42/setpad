import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/rendering.dart' show RenderEditable, RenderParagraph;
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/set_grid.dart';

/// 2026-09-27 사용자 보고 셋:
/// 1. 운동 완료 뒤 글자를 치면 한 글자 이상 안 들어간다.
/// 2. 해낸 세트를 눌러 고치면 무게·횟수를 따로 못 고치고 횟수로 바뀐다.
/// 3. 세트 자리를 끌어서 바꾸고 싶다.
void main() {
  final l = lookupL(const Locale('ko'));
  final input = find.byType(CupertinoTextField);

  Future<void> pumpEditor(
    WidgetTester tester,
    RoutineEditorController c,
  ) async {
    addTearDown(c.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: CupertinoPageScaffold(
          resizeToAvoidBottomInset: false,
          child: SafeArea(child: RoutineEditor(controller: c)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  SetKeypad pad(WidgetTester tester) =>
      tester.widget<SetKeypad>(find.byType(SetKeypad));
  Finder padKey(String label) => find.descendant(
    of: find.byType(SetKeypad),
    matching: find.byWidgetPredicate(
      (w) => w is Text && w.data == label && (w.style?.fontSize ?? 0) >= 14,
    ),
  );
  TextEditingController field(WidgetTester tester) =>
      tester.widget<CupertinoTextField>(input.first).controller!;
  String selected(WidgetTester tester) {
    final v = field(tester).value;
    return v.selection.textInside(v.text);
  }

  /// 키패드를 한 키씩 누른다(실제 기기에서처럼 한 글자씩).
  Future<void> press(WidgetTester tester, String keys) async {
    for (final k in keys.split('')) {
      pad(tester).onKey(k);
      await tester.pump();
    }
  }

  List<(double?, int?)> sets(RoutineEditorController c, [int block = 0]) => [
    for (final s in c.blocks[block].sets) (s.value, s.reps),
  ];

  group('2. 해낸 세트 고치기 — 칸 하나씩', () {
    RoutineEditorController bench() => RoutineEditorController()
      ..addExercise('벤치프레스')
      ..addSet('80 9')
      ..addSet('80 8')
      ..closeBlock();

    testWidgets('누르면 무게 칸만 골라지고, 새 무게를 치면 횟수는 남는다', (tester) async {
      final c = bench();
      await pumpEditor(tester, c);
      await tester.tap(find.byKey(const ValueKey('set-cell-0')));
      await tester.pumpAndSettle();
      expect(field(tester).text, '80kg 9');
      expect(selected(tester), '80', reason: '줄 전체가 아니라 무게 칸');
      expect(padKey('다음'), findsOneWidget, reason: '무게 칸의 큰 키는 횟수로 넘기기');

      await press(tester, '85');
      expect(field(tester).text, '85kg 9');
      expect(sets(c).first, (85.0, 9), reason: '예전에는 "85" 한 줄 = 무게 없는 85회');
      await tester.tap(padKey('다음'));
      await tester.pump();
      expect(selected(tester), '9');
      expect(padKey('완료'), findsOneWidget);
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      expect(sets(c), [(85.0, 9), (80.0, 8)]);
    });

    testWidgets('다음으로 횟수 칸만 고쳐도 무게는 그대로다', (tester) async {
      final c = bench();
      await pumpEditor(tester, c);
      await tester.tap(find.byKey(const ValueKey('set-cell-1')));
      await tester.pumpAndSettle();
      await tester.tap(padKey('다음'));
      await tester.pump();
      await press(tester, '6');
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      expect(sets(c), [(80.0, 9), (80.0, 6)]);
    });

    testWidgets('칸의 횟수 글자를 누르면 횟수 칸, 칸 가운데를 누르면 무게 칸', (tester) async {
      final c = bench();
      await pumpEditor(tester, c);
      final cell = find.byKey(const ValueKey('set-cell-0'));
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: cell, matching: find.byType(RichText)),
      );
      final text = paragraph.text.toPlainText();
      final nine = text.lastIndexOf('9');
      final glyph = paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: nine, extentOffset: nine + 1),
          )
          .first
          .toRect();
      await tester.tapAt(paragraph.localToGlobal(glyph.center));
      await tester.pumpAndSettle();
      expect(selected(tester), '9');
      expect(padKey('완료'), findsOneWidget);
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      // 칸 가운데(글자 뒤 여백일 수 있다)는 무게 — 늘 같은 자리에서 시작한다.
      await tester.tap(cell);
      await tester.pumpAndSettle();
      expect(selected(tester), '80');
    });

    testWidgets('입력 줄을 누르면 누른 자리의 칸을 고르고, 복사 메뉴는 뜨지 않는다', (tester) async {
      final c = bench();
      await pumpEditor(tester, c);
      await tester.tap(find.byKey(const ValueKey('set-cell-0')));
      await tester.pumpAndSettle();
      final line = tester.getRect(input.first);
      // "80kg 9" 의 끝(횟수) 쪽을 누른다.
      final editable = tester.allRenderObjects
          .whereType<RenderEditable>()
          .first;
      final nine = editable.getLocalRectForCaret(const TextPosition(offset: 5));
      await tester.tapAt(
        editable.localToGlobal(nine.center) + const Offset(3, 0),
      );
      await tester.pumpAndSettle();
      expect(selected(tester), '9');
      // 앞(무게) 쪽을 누르면 다시 무게. 두 번 누르기로 읽히지 않게 조금 뒤에.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tapAt(Offset(line.left + 6, line.center.dy));
      await tester.pumpAndSettle();
      expect(selected(tester), '80');
      expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
      expect(find.byType(SystemContextMenu), findsNothing);
    });

    testWidgets('± 는 고른 칸만, 키에 적힌 폭으로 민다', (tester) async {
      final c = bench();
      await pumpEditor(tester, c);
      await tester.tap(find.byKey(const ValueKey('set-cell-0')));
      await tester.pumpAndSettle();
      pad(tester).onAdjust(1);
      await tester.pump();
      expect(field(tester).text, '82.5kg 9');
      expect(selected(tester), '82.5', reason: '민 칸이 그대로 골라져 있다');
      expect(pad(tester).stepLabel, '2.5kg');
      await tester.tap(padKey('다음'));
      await tester.pump();
      expect(pad(tester).stepLabel, '1');
      pad(tester).onAdjust(1);
      await tester.pump();
      expect(field(tester).text, '82.5kg 10');
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      expect(sets(c).first, (82.5, 10));
    });

    testWidgets('지우기는 고른 칸만 지우고 단위를 지우지 않으며, 그 사이 세트를 비우지 않는다', (tester) async {
      final c = bench();
      await pumpEditor(tester, c);
      await tester.tap(find.byKey(const ValueKey('set-cell-0')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        pad(tester).onBackspace();
        await tester.pump();
      }
      expect(field(tester).text, 'kg 9');
      expect(sets(c).first, (80.0, 9), reason: '치는 도중에는 무게 없는 세트로 쓰지 않는다');
      await press(tester, '90');
      expect(sets(c).first, (90.0, 9));
      // 소수점까지만 친 사이도 세트를 비우지 않는다.
      await press(tester, '.');
      expect(field(tester).text, '90.kg 9');
      expect(sets(c).first, (90.0, 9));
      await press(tester, '5');
      expect(sets(c).first, (90.5, 9));
    });

    testWidgets('무게를 지운 뒤 완료하거나 다시 열어도 횟수 전용으로 바뀌지 않는다', (tester) async {
      final c = bench();
      await pumpEditor(tester, c);
      await tester.tap(find.byKey(const ValueKey('set-cell-0')));
      await tester.pumpAndSettle();
      pad(tester).onBackspace();
      await tester.pump();
      expect(field(tester).text, 'kg 9');
      await tester.tap(padKey('다음'));
      await tester.pump();
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      expect(sets(c).first, (80.0, 9));
      await tester.tap(find.byKey(const ValueKey('set-cell-0')));
      await tester.pumpAndSettle();
      expect(sets(c).first, (80.0, 9));
      final rect = tester.getRect(input.first);
      await tester.tapAt(Offset(rect.left + 2, rect.center.dy));
      await tester.pump();
      await press(tester, '85');
      expect(sets(c).first, (85.0, 9));
    });

    testWidgets('시간 세트는 횟수 칸이 없어 큰 키가 바로 완료다', (tester) async {
      final c = RoutineEditorController()
        ..addExercise('플랭크')
        ..addSet('60초')
        ..closeBlock();
      await pumpEditor(tester, c);
      await tester.tap(find.byKey(const ValueKey('set-cell-0')));
      await tester.pumpAndSettle();
      expect(selected(tester), '60');
      expect(padKey('완료'), findsOneWidget);
      await press(tester, '90');
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      expect(c.blocks.single.sets.single.value, 90);
      expect(c.blocks.single.sets.single.unit, 's');
    });
  });

  group('± 새 세트 줄', () {
    testWidgets('"80 9" 의 + 는 횟수를 1 올린다 — 11.5 가 아니다', (tester) async {
      final c = RoutineEditorController()..addExercise('벤치프레스');
      await pumpEditor(tester, c);
      await press(tester, '80');
      pad(tester).onAdjust(1);
      await tester.pump();
      expect(field(tester).text, '82.5');
      await tester.tap(padKey('다음'));
      await tester.pump();
      await press(tester, '9');
      pad(tester).onAdjust(1);
      await tester.pump();
      expect(field(tester).text, '82.5 10');
    });

    test('칸 찾기와 칸 밀기', () {
      expect(setLineFields('80kg 9').value, (start: 0, end: 2));
      expect(setLineFields('80kg 9').reps, (start: 5, end: 6));
      expect(setLineFields('kg 9').value, (start: 0, end: 0));
      expect(setLineFields('9').value, isNull);
      expect(setLineFields('9').reps, (start: 0, end: 1));
      expect(setLineFields('80kg x10').reps, isNull, reason: 'x10 은 세트 수');
      expect(
        bumpField('80kg 1', (start: 5, end: 6), 1, -1, reps: true),
        '80kg 1',
      );
      expect(bumpField('1.25kg 9', (start: 0, end: 4), 1.25, 1), '2.5kg 9');
    });
  });

  group('1. 운동 완료 뒤 입력', () {
    RoutineEditorController done() => RoutineEditorController()
      ..addExercise('벤치프레스')
      ..addSet('80 5')
      ..closeBlock();

    testWidgets('자판이 심어 둔 글자를 지우고 곧바로 글자를 넣어도 이어서 친다 — 앞 세트로 튀지 않는다', (
      tester,
    ) async {
      final c = done();
      await pumpEditor(tester, c);
      expect(field(tester).text, '\u200B');
      // 조합하는 자판이 한 번에 보내는 두 단계: 지우기, 그리고 새 글자.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(selection: TextSelection.collapsed(offset: 0)),
      );
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'ㅅ',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SetKeypad), findsNothing, reason: '앞 세트 고치기로 가지 않는다');
      expect(c.naming, isTrue);
      for (final step in ['스', '스쿼', '스쿼트']) {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: step,
            selection: TextSelection.collapsed(offset: step.length),
            composing: TextRange(start: step.length - 1, end: step.length),
          ),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(field(tester).text, '스쿼트');
    });

    testWidgets('빈 자리에서 지우기만 누르면 여전히 앞 세트로 돌아간다', (tester) async {
      final c = done();
      await pumpEditor(tester, c);
      await tester.enterText(input.first, '');
      await tester.pumpAndSettle();
      expect(c.activeIndex, 0);
      expect(field(tester).text, '80kg 5');
    });

    testWidgets('첫 글자를 쳐도 입력칸의 짜임이 바뀌지 않는다 — 조합 중인 글자를 흔들지 않는다', (
      tester,
    ) async {
      final c = done();
      await pumpEditor(tester, c);
      final editable = find.descendant(
        of: input.first,
        matching: find.byType(EditableText),
      );
      int depth() {
        var n = 0;
        tester.element(editable).visitAncestorElements((_) {
          n++;
          return true;
        });
        return n;
      }

      final before = depth();
      final state = tester.state(editable);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '\u200Bㅅ',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 1, end: 2),
        ),
      );
      await tester.pump();
      expect(depth(), before);
      expect(identical(tester.state(editable), state), isTrue);
      // 친 뒤에는 안내문이 보이지 않는다(입력칸의 것은 숨은 채 자리만 지킨다).
      for (final e in find.text('운동 이름').evaluate()) {
        expect(e.findAncestorWidgetOfExactType<Visibility>()?.visible, isFalse);
      }
    });
  });

  group('1-b. iOS — 빈 줄 표지는 골라 둔다', () {
    RoutineEditorController done() => RoutineEditorController()
      ..addExercise('벤치프레스')
      ..addSet('80 5')
      ..closeBlock();

    Future<void> ios(WidgetTester tester, RoutineEditorController c) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await pumpEditor(tester, c);
    }

    /// iOS 엔진이 하는 대로: 표시 없는 글이 없으면 고른 범위를, 있으면 표시 범위를
    /// 바꾼다(FlutterTextInputView setMarkedText). 음절이 넘어가면 앞 음절을 확정한다.
    Future<void> compose(WidgetTester tester, List<String> steps) async {
      for (final s in steps) {
        final committed = s.length > 1 ? s.substring(0, s.length - 1) : '';
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: s,
            selection: TextSelection.collapsed(offset: s.length),
            composing: TextRange(start: committed.length, end: s.length),
          ),
        );
        await tester.pump();
      }
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: steps.last,
          selection: TextSelection.collapsed(offset: steps.last.length),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('운동 완료 뒤 빈 줄은 표지가 골라져 있고, 한글 첫 글자가 표지를 덮어쓴다', (tester) async {
      final c = done();
      await ios(tester, c);
      expect(field(tester).text, ' ');
      expect(
        field(tester).selection,
        const TextSelection(baseOffset: 0, extentOffset: 1),
        reason: '커서가 표지 뒤에 있으면 iOS 한글 조합이 앞 음절을 지웠다',
      );
      expect(find.byKey(const ValueKey('sentinel-caret')), findsOneWidget);
      // ㅎ → 해 → 햄 → 해머(해 확정, 머 조합): 첫 글자가 골라 둔 표지를 바꾼다.
      await compose(tester, ['ㅎ', '해', '햄', '해머']);
      expect(field(tester).text, '해머');
      expect(c.naming, isTrue);
      expect(find.byType(SetKeypad), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('누르거나 화살표로 커서가 움직여도 표지를 다시 골라 둔다', (tester) async {
      final c = done();
      await ios(tester, c);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: ' ',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        field(tester).selection,
        const TextSelection(baseOffset: 0, extentOffset: 1),
      );
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('빈 자리에서 지우기(골라 둔 표지를 지움)는 여전히 앞 세트로 간다', (tester) async {
      final c = done();
      await ios(tester, c);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(selection: TextSelection.collapsed(offset: 0)),
      );
      await tester.pumpAndSettle();
      expect(c.activeIndex, 0);
      expect(field(tester).text, '80kg 5');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('표지 뒤에서 시작한 한글 조합도 음절과 공백을 보존한다', (tester) async {
      final c = done();
      await ios(tester, c);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      for (final text in [' ㅎ', ' 해', ' 해머', ' 해머스', ' 해머스트랭스 하이로우']) {
        final value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
          composing: TextRange(start: text.length - 1, end: text.length),
        );
        tester.testTextInput.updateEditingValue(value);
        await tester.pump();
        expect(field(tester).value, value);
        expect(c.naming, isTrue);
      }
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(c.blocks.last.name, '해머스트랭스 하이로우');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('한글 조합 중간의 임시 삭제 때 표지를 다시 넣지 않는다', (tester) async {
      final c = done();
      await ios(tester, c);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'ㅎ',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump();
      expect(field(tester).text, 'ㅎ');

      tester.testTextInput.updateEditingValue(const TextEditingValue());
      expect(field(tester).text, isEmpty);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '해',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump();
      expect(field(tester).text, '해');

      tester.testTextInput.updateEditingValue(const TextEditingValue());
      expect(field(tester).text, isEmpty);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '해머',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pumpAndSettle();
      expect(field(tester).text, '해머');
      expect(c.naming, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('영어도 첫 글자가 표지를 바꾼다', (tester) async {
      final c = done();
      await ios(tester, c);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'c',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pumpAndSettle();
      expect(field(tester).text, 'c');
      expect(find.byKey(const ValueKey('sentinel-caret')), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('3. 세트 끌어 옮기기', () {
    RoutineEditorController three() => RoutineEditorController()
      ..addExercise('스쿼트')
      ..addSet('60 10')
      ..addSet('80 8')
      ..addSet('100 5')
      ..closeBlock();

    testWidgets('길게 눌러 끌어다 놓으면 그 자리로 간다', (tester) async {
      final c = three();
      await pumpEditor(tester, c);
      final from = tester.getCenter(find.byKey(const ValueKey('set-cell-2')));
      final to = tester.getCenter(find.byKey(const ValueKey('set-cell-0')));
      final gesture = await tester.startGesture(from);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await gesture.moveTo(to);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(sets(c), [(100.0, 5), (60.0, 10), (80.0, 8)]);
      expect(find.byType(SetKeypad), findsNothing, reason: '끌기는 고치기를 열지 않는다');
    });

    testWidgets('빈 칸에 놓으면 맨 끝으로, 짧게 누르면 여전히 고친다', (tester) async {
      final c = three();
      await pumpEditor(tester, c);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('set-cell-0'))),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey('add-set-cell'))),
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(sets(c), [(80.0, 8), (100.0, 5), (60.0, 10)]);
      await tester.tap(find.byKey(const ValueKey('set-cell-0')));
      await tester.pumpAndSettle();
      expect(field(tester).text, '80kg 8');
    });

    testWidgets('고치던 세트는 옮긴 자리를 따라간다', (tester) async {
      final c = three();
      await pumpEditor(tester, c);
      await tester.tap(find.byKey(const ValueKey('set-cell-0')));
      await tester.pumpAndSettle();
      c.moveSet(0, 0, 2);
      await tester.pumpAndSettle();
      await press(tester, '65');
      await tester.tap(padKey('다음'));
      await tester.pump();
      await tester.tap(padKey('완료'));
      await tester.pumpAndSettle();
      expect(sets(c), [(80.0, 8), (100.0, 5), (65.0, 10)]);
    });

    testWidgets('읽어 주기에서도 앞으로·뒤로 옮긴다', (tester) async {
      final c = three();
      await pumpEditor(tester, c);
      // 칸에 가장 가까운 것 — 운동 목록도 제 옮기기 동작을 단다.
      Semantics cell(int i) => tester
          .widgetList<Semantics>(
            find.ancestor(
              of: find.byKey(ValueKey('set-cell-$i')),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Semantics &&
                    w.properties.customSemanticsActions != null,
              ),
            ),
          )
          .first;
      final actions = cell(1).properties.customSemanticsActions!;
      expect(actions.keys.map((a) => a.label), [
        l.moveSetEarlier,
        l.moveSetLater,
      ]);
      actions[const CustomSemanticsAction(label: '뒤로 옮기기')]!();
      await tester.pumpAndSettle();
      expect(sets(c), [(60.0, 10), (100.0, 5), (80.0, 8)]);
      expect(
        cell(0).properties.customSemanticsActions!.keys.map((a) => a.label),
        [l.moveSetLater],
        reason: '맨 앞은 앞으로 옮길 수 없다',
      );
    });

    testWidgets('옮길 수 없는 자리(같이 고치는 기록)에서는 끌리지 않는다', (tester) async {
      final block = ExerciseBlock('스쿼트', [
        LoggedSet(value: 60, reps: 10),
        LoggedSet(value: 80, reps: 8),
      ]);
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: CupertinoPageScaffold(
            child: SetGrid(block: block, onTapSet: (_, _) {}),
          ),
        ),
      );
      expect(find.byType(LongPressDraggable<int>), findsNothing);
    });
  });
}
