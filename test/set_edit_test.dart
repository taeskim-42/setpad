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

  group('1-b. iOS — 빈 줄 표지는 공백, 커서는 그 뒤', () {
    RoutineEditorController done() => RoutineEditorController()
      ..addExercise('벤치프레스')
      ..addSet('80 5')
      ..closeBlock();

    Future<void> ios(WidgetTester tester, RoutineEditorController c) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await pumpEditor(tester, c);
    }

    List<String> pushed(WidgetTester tester) => [
      for (final call in tester.testTextInput.log)
        if (call.method == 'TextInput.setEditingState')
          '${(call.arguments as Map)['text']}',
    ];

    /// iOS 한글 자판이 하는 대로: marked text 없이, 바뀌는 음절을 하나씩 지우고(지울
    /// 때마다 값을 보낸다) 새 글을 넣는다. 사이마다 화면이 그려진다. [states] 는 사람이
    /// 본 글(표지 뒤).
    Future<void> iosType(WidgetTester tester, List<String> states) async {
      var old = '';
      for (final next in states) {
        var common = 0;
        while (common < old.length &&
            common < next.length &&
            old[common] == next[common]) {
          common++;
        }
        for (var n = old.length - 1; n >= common; n--) {
          final t = ' ${old.substring(0, n)}';
          tester.testTextInput.updateEditingValue(
            TextEditingValue(
              text: t,
              selection: TextSelection.collapsed(offset: t.length),
            ),
          );
          await tester.pump();
          expect(field(tester).text, t);
        }
        final t = ' $next';
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: t,
            selection: TextSelection.collapsed(offset: t.length),
          ),
        );
        await tester.pump();
        expect(field(tester).text, t);
        old = next;
      }
    }

    testWidgets('운동 완료 뒤 빈 줄은 공백 표지 뒤에 커서가 있고, 누르기가 그 자리를 흔들지 않는다', (
      tester,
    ) async {
      final c = done();
      await ios(tester, c);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(field(tester).text, ' ');
      expect(field(tester).selection, const TextSelection.collapsed(offset: 1));
      expect(find.byKey(const ValueKey('sentinel-caret')), findsOneWidget);
      final textField = tester.widget<CupertinoTextField>(input.first);
      // 입력 연결의 설정은 표지에 따라 바뀌지 않는다 — 끄면 iOS 엔진이 자판의 선택
      // 이동을 치는 내내 버린다(1.5.1 회귀). 핸들·메뉴는 화면 쪽 것으로만 감춘다.
      expect(textField.enableInteractiveSelection, isTrue);
      expect(textField.contextMenuBuilder, isNull);
      expect(textField.showCursor, isFalse, reason: '안내문 앞의 커서를 대신 그린다');
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .selectionControls,
        same(emptyTextSelectionControls),
      );
      tester.testTextInput.log.clear();
      await tester.tap(input.first);
      await tester.pumpAndSettle();
      await tester.longPress(input.first);
      await tester.pumpAndSettle();
      expect(textField.focusNode!.hasFocus, isTrue);
      expect(field(tester).selection, const TextSelection.collapsed(offset: 1));
      expect(pushed(tester), isEmpty, reason: '누르기가 자판 쪽 선택을 바꾸지 않는다');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('한글 자판의 지우고-넣기를 그대로 받는다 — 아이스 아메리카노, 표지는 지워지지 않는다', (
      tester,
    ) async {
      final c = done();
      await ios(tester, c);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.testTextInput.log.clear();
      await iosType(tester, [
        'ㅇ', '아', '앙', '아이', '아잇', '아이스', '아이스 ', //
        '아이스 ㅇ', '아이스 아', '아이스 암', '아이스 아메', '아이스 아멜', //
        '아이스 아메리', '아이스 아메릭', '아이스 아메리카', '아이스 아메리칸', //
        '아이스 아메리카노',
      ]);
      expect(pushed(tester), isEmpty, reason: '치는 동안 앱은 자판으로 아무것도 밀지 않는다');
      await tester.pump(const Duration(milliseconds: 200));
      expect(field(tester).text, ' 아이스 아메리카노');
      expect(pushed(tester), isEmpty);
      expect(tester.widget<CupertinoTextField>(input.first).showCursor, isTrue);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .selectionControls,
        isNot(same(emptyTextSelectionControls)),
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(c.blocks.last.name, '아이스 아메리카노');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('커서가 표지 앞으로 가도 앱은 되돌리지 않는다 — 자판으로 밀지 않는다', (tester) async {
      final c = done();
      await ios(tester, c);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.testTextInput.log.clear();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: ' ',
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(field(tester).selection, const TextSelection.collapsed(offset: 0));
      expect(pushed(tester), isEmpty);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('빈 자리에서 지우기(표지를 지움)는 기다리지 않고 앞 세트로 간다', (tester) async {
      final c = done();
      await ios(tester, c);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(selection: TextSelection.collapsed(offset: 0)),
      );
      await tester.pump();
      expect(c.activeIndex, 0);
      await tester.pumpAndSettle();
      expect(field(tester).text, '80kg 5');
      expect(find.byType(SetKeypad), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('자판이 지우기 전에 표지를 먼저 골라도 빈 자리 지우기로 앞 세트로 간다', (tester) async {
      final c = done();
      await ios(tester, c);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.testTextInput.log.clear();
      // UIKit 자판: 앞 글자를 고르고(선택만 바뀐 값), 지운다.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: ' ',
          selection: TextSelection(baseOffset: 0, extentOffset: 1),
        ),
      );
      await tester.pump();
      expect(pushed(tester), isEmpty, reason: '고른 선택을 되돌리며 밀지 않는다');
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(selection: TextSelection.collapsed(offset: 0)),
      );
      await tester.pumpAndSettle();
      expect(c.activeIndex, 0);
      expect(field(tester).text, '80kg 5');
      expect(pushed(tester), isNot(contains(' ')));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('친 글을 지우기로 다 지워도 표지는 남고, 그다음 지우기는 앞 세트로 간다', (tester) async {
      final c = done();
      await ios(tester, c);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.testTextInput.log.clear();
      await iosType(tester, ['ㅅ', '스', '']);
      expect(field(tester).text, ' ');
      expect(pushed(tester), isEmpty, reason: '표지가 남아 있어 다시 심을 일이 없다');
      expect(c.naming, isTrue);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(selection: TextSelection.collapsed(offset: 0)),
      );
      await tester.pumpAndSettle();
      expect(field(tester).text, '80kg 5');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('지우기를 꾹 눌러 친 글과 표지를 잇달아 지우면 앞 세트로 가고, 세트는 그대로다', (
      tester,
    ) async {
      final c = done();
      await ios(tester, c);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await iosType(tester, ['ㅅ', '스']);
      // 자동 반복: 100ms 마다 한 글자씩. 표지까지 지우면 키패드가 되어 입력 연결이
      // 닫히므로 남은 반복은 세트에 닿지 않는다.
      for (final t in [' ', '']) {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: t,
            selection: TextSelection.collapsed(offset: t.length),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(find.byType(SetKeypad), findsOneWidget);
      expect(field(tester).text, '80kg 5');
      expect(sets(c), [(80.0, 5)]);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('빈 줄에서 백스페이스로 세트를 열고 숫자를 지워도 커서가 보인다', (tester) async {
      final c = done();
      await ios(tester, c);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(selection: TextSelection.collapsed(offset: 0)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(field(tester).text, '80kg 5');
      expect(field(tester).selection, const TextSelection.collapsed(offset: 6));

      pad(tester).onBackspace();
      await tester.pump();
      expect(field(tester).text, '80kg ');
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
      expect(editable.showCursor, isTrue);
      final state = tester.state<EditableTextState>(find.byType(EditableText));
      var visible = state.cursorCurrentlyVisible;
      for (var i = 0; i < 12 && !visible; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        visible = state.cursorCurrentlyVisible;
      }
      expect(visible, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('표지 뒤에서 조합하는 한글도 음절과 공백을 보존한다', (tester) async {
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

    testWidgets('자판이 표지까지 통째로 바꿔 넣어도(임시 빈 값 포함) 앱은 끼어들지 않는다', (tester) async {
      final c = done();
      await ios(tester, c);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.testTextInput.log.clear();
      for (final t in ['ㅎ', '', '해', '', '해머']) {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: t,
            selection: TextSelection.collapsed(offset: t.length),
          ),
        );
        await tester.pump();
        expect(field(tester).text, t);
      }
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(field(tester).text, '해머');
      expect(pushed(tester), isEmpty);
      expect(c.naming, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('영어도 표지 뒤에 친다', (tester) async {
      final c = done();
      await ios(tester, c);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: ' c',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pumpAndSettle();
      expect(field(tester).text, ' c');
      expect(find.byKey(const ValueKey('sentinel-caret')), findsNothing);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(c.blocks.last.name, 'c');
      debugDefaultTargetPlatformOverride = null;
    });
  });

  /// 2026-10-06 사용자 보고(1.5.1): "아이스 아메리카노" 를 치면 "아아아이이이스스스".
  /// 앱이 치는 도중에 자판 쪽 상태를 바꾸지 않는다 — 입력 연결의 설정도, 입력칸의 값도.
  group('1-c. 치는 동안 자판이 보는 것은 앱이 바꾸지 않는다', () {
    Map<String, Object?> lastConfig(WidgetTester tester) {
      Map<String, Object?>? config;
      for (final call in tester.testTextInput.log) {
        if (call.method == 'TextInput.setClient') {
          config = ((call.arguments as List)[1] as Map).cast<String, Object?>();
        } else if (call.method == 'TextInput.updateConfig') {
          config = (call.arguments as Map).cast<String, Object?>();
        }
      }
      return config!;
    }

    List<String> pushed(WidgetTester tester) => [
      for (final call in tester.testTextInput.log)
        if (call.method == 'TextInput.setEditingState')
          '${(call.arguments as Map)['text']}',
    ];

    Future<RoutineEditorController> finishExercise(WidgetTester tester) async {
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 5');
      await pumpEditor(tester, c);
      // 키패드의 완료로 운동을 끝낸다 — 시스템 자판 연결이 이때 새로 맺어진다.
      pad(tester).onSubmit();
      await tester.pumpAndSettle();
      expect(c.naming, isTrue);
      return c;
    }

    testWidgets(
      '실제 iOS 한글 자판의 순서(고르기 → 지우기 → 넣기)를 그대로 재생해도 앱은 자판으로 아무것도 보내지 않는다',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final c = await finishExercise(tester);
        tester.testTextInput.log.clear();
        for (final (text, base, extent) in _iosKoreanTyping) {
          final value = TextEditingValue(
            text: ' $text',
            selection: TextSelection(
              baseOffset: base + 1,
              extentOffset: extent + 1,
            ),
          );
          tester.testTextInput.updateEditingValue(value);
          await tester.pump();
          expect(field(tester).value, value, reason: '자판이 보낸 값 그대로');
          expect(c.naming, isTrue, reason: '치는 동안 앞 세트로 가지 않는다');
        }
        await tester.pumpAndSettle();
        expect(
          tester.testTextInput.log.where(
            (call) => const {
              'TextInput.setEditingState',
              'TextInput.setClient',
              'TextInput.updateConfig',
            }.contains(call.method),
          ),
          isEmpty,
          reason: '치는 동안 자판 쪽 상태(값·연결·설정)를 앱이 바꾸면 음절이 겹치거나 지워진다',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(c.blocks.last.name, '아이스 아메리카노');
        debugDefaultTargetPlatformOverride = null;
      },
    );

    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      testWidgets(
        '${platform.name}: 운동을 끝낸 빈 이름 줄의 연결도 선택 이동을 받고, 제안을 끄지 않는다',
        (tester) async {
          debugDefaultTargetPlatformOverride = platform;
          await finishExercise(tester);
          expect(
            field(tester).text,
            platform == TargetPlatform.iOS ? ' ' : '​',
          );
          final config = lastConfig(tester);
          // false 면 iOS 엔진이 자판의 setSelectedTextRange 를 모두 버린다.
          expect(config['enableInteractiveSelection'], isTrue);
          // false 면 Android 가 칸을 VISIBLE_PASSWORD 로 만들어 Gboard 가 한글을 끈다.
          expect(config['enableSuggestions'], isTrue);
          expect(config['autocorrect'], isFalse);
          tester.testTextInput.log.clear();
          for (final t in ['ㅅ', '스', '스쿼', '스쿼트']) {
            tester.testTextInput.updateEditingValue(
              TextEditingValue(
                text: t,
                selection: TextSelection.collapsed(offset: t.length),
                composing: TextRange(start: t.length - 1, end: t.length),
              ),
            );
            await tester.pump();
          }
          expect(
            tester.testTextInput.log.where(
              (c) =>
                  c.method == 'TextInput.updateConfig' ||
                  c.method == 'TextInput.setClient',
            ),
            isEmpty,
            reason: '치는 동안 연결 설정을 다시 보내지 않는다',
          );
          await tester.pumpAndSettle();
          debugDefaultTargetPlatformOverride = null;
        },
      );
    }

    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      testWidgets(
        '${platform.name}: 표지만 있는 줄을 누르고·길게 누르고·두 번 눌러도 선택과 자판은 그대로다',
        (tester) async {
          debugDefaultTargetPlatformOverride = platform;
          addTearDown(() => debugDefaultTargetPlatformOverride = null);
          await finishExercise(tester);
          final before = field(tester).value;
          tester.testTextInput.log.clear();
          await tester.tap(input.first);
          await tester.pump(const Duration(milliseconds: 50));
          await tester.tap(input.first);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.longPress(input.first);
          await tester.pump(const Duration(milliseconds: 400));
          expect(field(tester).value, before);
          expect(pushed(tester), isEmpty);
          expect(
            tester.widget<CupertinoTextField>(input.first).focusNode!.hasFocus,
            isTrue,
          );
          await tester.pumpAndSettle();
          debugDefaultTargetPlatformOverride = null;
        },
      );

      testWidgets(
        '${platform.name}: 이름을 넣고 다음 운동을 끝낼 때까지 맺는 연결이 모두 선택 이동을 받고 제안을 끄지 않는다',
        (tester) async {
          debugDefaultTargetPlatformOverride = platform;
          addTearDown(() => debugDefaultTargetPlatformOverride = null);
          await finishExercise(tester);
          final prefix = platform == TargetPlatform.iOS ? ' ' : '\u200B';
          tester.testTextInput.updateEditingValue(
            TextEditingValue(
              text: '$prefix스쿼트',
              selection: TextSelection.collapsed(offset: prefix.length + 3),
            ),
          );
          await tester.pump();
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          pad(tester).onKey('8');
          pad(tester).onKey('0');
          await tester.pump();
          pad(tester).onSubmit();
          await tester.pump();
          pad(tester).onKey('5');
          await tester.pump();
          pad(tester).onSubmit();
          await tester.pumpAndSettle();
          pad(tester).onSubmit();
          await tester.pumpAndSettle();
          final configs = [
            for (final call in tester.testTextInput.log)
              if (call.method == 'TextInput.setClient')
                ((call.arguments as List)[1] as Map).cast<String, Object?>(),
          ];
          expect(configs, isNotEmpty);
          for (final config in configs) {
            if (config['inputType'] case {'name': 'TextInputType.none'}) {
              continue;
            }
            expect(config['enableInteractiveSelection'], isTrue);
            expect(config['enableSuggestions'], isTrue);
          }
          debugDefaultTargetPlatformOverride = null;
        },
      );
    }

    testWidgets('iOS 한글 자판의 지우고-넣기 사이에 화면이 그려져도 앱은 자판으로 값을 되밀지 않는다', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await finishExercise(tester);
      tester.testTextInput.log.clear();
      // ㅇ ㅏ ㅇ ㅣ ㅅ ㅡ — 음절을 바꿀 때마다 지우고 넣는다. 표지 뒤라 지운 값은 ' '
      // 이다. 사이마다 프레임.
      for (final t in [
        ' ㅇ',
        ' ',
        ' 아',
        ' ',
        ' 앙',
        ' ',
        ' 아이',
        ' 아',
        ' 아잇',
        ' 아',
        ' 아이스',
      ]) {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: t,
            selection: TextSelection.collapsed(offset: t.length),
          ),
        );
        await tester.pump();
        expect(field(tester).text, t, reason: '자판이 보낸 값 그대로');
      }
      expect(pushed(tester), isEmpty, reason: '치는 도중 표지를 되밀면 자판의 조합이 흔들린다');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(field(tester).text, ' 아이스');
      expect(pushed(tester), isEmpty);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('이름 줄의 첫 표지는 연결을 맺을 때 이미 들어 있고, 그 뒤로는 되밀지 않는다', (tester) async {
      await finishExercise(tester);
      final log = tester.testTextInput.log;
      final client = log.lastIndexWhere(
        (c) => c.method == 'TextInput.setClient',
      );
      expect(client, greaterThanOrEqualTo(0));
      final first = log
          .skip(client)
          .firstWhere((c) => c.method == 'TextInput.setEditingState');
      expect((first.arguments as Map)['text'], '​');
      expect(pushed(tester).where((t) => t == '​'), hasLength(1));
    });

    testWidgets('Android: 자판이 조합 영역을 쥔 채 쉬어도 앱은 값을 되밀지 않는다', (tester) async {
      await finishExercise(tester);
      tester.testTextInput.log.clear();
      for (final value in [
        const TextEditingValue(
          text: '​아',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 1, end: 2),
        ),
        const TextEditingValue(
          text: '​Bench',
          selection: TextSelection.collapsed(offset: 6),
          composing: TextRange(start: 1, end: 6),
        ),
      ]) {
        tester.testTextInput.updateEditingValue(value);
        await tester.pump(const Duration(seconds: 1));
        expect(field(tester).value, value);
      }
      expect(pushed(tester), isEmpty);
    });

    testWidgets('iOS: 자판이 표지까지 덮어쓴 글을 다 지워도 앱은 다시 심지 않고, 다음 전환에서 심는다', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await finishExercise(tester);
      tester.testTextInput.log.clear();
      for (final value in [
        const TextEditingValue(
          text: '아',
          selection: TextSelection.collapsed(offset: 1),
        ),
        const TextEditingValue(selection: TextSelection.collapsed(offset: 0)),
      ]) {
        tester.testTextInput.updateEditingValue(value);
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(field(tester).text, isEmpty);
      expect(pushed(tester), isEmpty, reason: '자판이 보낸 값에 답해 쓰지 않는다');
      // 다음 운동을 넣고 끝내면(앱이 만든 전환) 빈 이름 줄에 다시 심는다.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '스쿼트',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      pad(tester).onSubmit();
      await tester.pumpAndSettle();
      expect(field(tester).text, ' ');
      expect(field(tester).selection, const TextSelection.collapsed(offset: 1));
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

/// 시뮬레이터 화면 자판(iOS 26.5, 두벌식)으로 "아이스 아메리카노" 를 칠 때 엔진이
/// 프레임워크로 보낸 값 그대로다(tool/ime_check 로 잡았다, 2026-10-07). marked text
/// 없이 키 하나마다 바꿀 음절을 고르고(선택만 바뀐 값) → 지우고 → 다시 넣는다.
/// 둘째 낱말에서는 자판이 제가 친 공백까지 골라 다시 넣는다. (글, 선택 시작, 선택 끝)
const _iosKoreanTyping = [
  ('', 0, 0),
  ('ㅇ', 1, 1),
  ('ㅇ', 0, 1),
  ('', 0, 0),
  ('아', 1, 1),
  ('아', 0, 1),
  ('', 0, 0),
  ('앙', 1, 1),
  ('앙', 0, 1),
  ('', 0, 0),
  ('아이', 2, 2),
  ('아이', 0, 2),
  ('', 0, 0),
  ('아', 1, 1),
  ('아잇', 2, 2),
  ('아잇', 0, 2),
  ('', 0, 0),
  ('아', 1, 1),
  ('아이스', 3, 3),
  ('아이스 ', 4, 4),
  ('아이스 ㅇ', 5, 5),
  ('아이스 ㅇ', 3, 5),
  ('아이스', 3, 3),
  ('아이스 ', 4, 4),
  ('아이스 아', 5, 5),
  ('아이스 아', 3, 5),
  ('아이스', 3, 3),
  ('아이스 ', 4, 4),
  ('아이스 암', 5, 5),
  ('아이스 암', 3, 5),
  ('아이스', 3, 3),
  ('아이스 ', 4, 4),
  ('아이스 아메', 6, 6),
  ('아이스 아메', 4, 6),
  ('아이스 ', 4, 4),
  ('아이스 아', 5, 5),
  ('아이스 아멜', 6, 6),
  ('아이스 아멜', 4, 6),
  ('아이스 ', 4, 4),
  ('아이스 아', 5, 5),
  ('아이스 아메리', 7, 7),
  ('아이스 아메리', 5, 7),
  ('아이스 아', 5, 5),
  ('아이스 아메', 6, 6),
  ('아이스 아메맄', 7, 7),
  ('아이스 아메맄', 5, 7),
  ('아이스 아', 5, 5),
  ('아이스 아메', 6, 6),
  ('아이스 아메리카', 8, 8),
  ('아이스 아메리카', 6, 8),
  ('아이스 아메', 6, 6),
  ('아이스 아메리', 7, 7),
  ('아이스 아메리칸', 8, 8),
  ('아이스 아메리칸', 6, 8),
  ('아이스 아메', 6, 6),
  ('아이스 아메리', 7, 7),
  ('아이스 아메리카노', 9, 9),
];
