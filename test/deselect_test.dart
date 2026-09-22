// 고치던 세트가 있을 때 빈 곳을 누르면 선택이 풀리는가 — 고친 값은 남고, 틀린 값이면 남는다.
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('세트를 눌러 고치다가 빈 곳을 누르면 선택이 풀리고 값은 남는다', (tester) async {
    final c = RoutineEditorController()
      ..addExercise('데드리프트')
      ..addSet('80 10')
      ..addSet('50 20');
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
    await tester.pump(const Duration(milliseconds: 300));
    String typed() => tester
        .widget<CupertinoTextField>(find.byType(CupertinoTextField).first)
        .controller!
        .text
        .replaceAll(String.fromCharCode(0x200B), '');

    await tester.tap(find.byKey(const ValueKey('set-cell-0')));
    await tester.pumpAndSettle();
    expect(typed(), contains('80'), reason: '그 세트가 입력 줄에 올라온다');
    expect(find.text('4세트'), findsNothing);
    // 값을 고친다.
    final pad = tester.widget<SetKeypad>(find.byType(SetKeypad));
    pad.onBackspace();
    pad.onBackspace();
    pad.onKey('12');
    await tester.pump();
    // 빈 곳을 누른다 — 선택이 풀리고 고친 값이 남는다.
    final list = tester.getRect(find.byType(CustomScrollView));
    await tester.tapAt(Offset(list.center.dx, list.bottom - 20));
    await tester.pumpAndSettle();
    expect(c.blocks.single.sets.first.reps, 12);
    expect(c.blocks.single.sets, hasLength(2));
    expect(typed(), isEmpty, reason: '입력 줄은 비어 다음 세트를 받는다');
  });
}
