// 빈 식단 줄에서 지우기 — 식단 적기를 접고 마지막 세트로 돌아가는가.
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('빈 식단 줄에서 Backspace 는 식단 적기를 접고 마지막 세트를 연다', (tester) async {
    final c = RoutineEditorController()
      ..addExercise('데드리프트')
      ..addSet('80 10')
      ..addSet('90 46')
      ..closeBlock();
    final meal = ValueNotifier<({String text, int? index})?>(null);
    final saved = <String>[];
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: CupertinoPageScaffold(
          resizeToAvoidBottomInset: false,
          child: SafeArea(
            child: RoutineEditor(
              controller: c,
              mealText: meal,
              onMealText: (text, _) => saved.add(text),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    String typed() => tester
        .widget<CupertinoTextField>(find.byType(CupertinoTextField).first)
        .controller!
        .text
        .replaceAll(String.fromCharCode(0x200B), '');

    await tester.tap(find.byKey(const ValueKey('meal-text-toggle')));
    await tester.pumpAndSettle();
    expect(meal.value, isNotNull, reason: '식단 적기 중');
    expect(typed(), isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    expect(meal.value, isNull, reason: '식단 적기를 접는다');
    expect(typed(), contains('90'), reason: '마지막 세트(90×46)가 입력 줄에 올라온다');
    expect(saved, isEmpty, reason: '빈 끼니를 저장하지 않는다');
    expect(c.blocks.single.sets, hasLength(2));
  });
}
