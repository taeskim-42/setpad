import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/palette.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/routine.dart';
import 'package:setpad/routine_card.dart';

import 'routine_fixture.dart';

class _Records extends NotesStore {
  _Records(this.records);
  final List<Note> records;
  @override
  List<Note> get notes => records;
}

/// 오늘 루틴 카드의 생김새 — 숫자가 아니라 성질을 지킨다.
void main() {
  setUpAll(() => initializeDateFormatting());
  final l = lookupL(const Locale('ko'));

  /// [text] 를 치고 Enter. 루틴 지시문에는 [exercises] 를 답한다.
  Future<List<String>> ask(
    WidgetTester tester,
    String text,
    List<String> exercises, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final store = _Records(defaultLog());
    addTearDown(store.dispose);
    final calls = <String>[];
    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(primaryColor: seal),
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: NotesListPage(
          store: store,
          onOpen: (_) {},
          ai: RecordAi(
            respond: (instructions, _) async {
              if (instructions != routineInstructions) {
                return {'kind': 'unrelated'};
              }
              calls.add(text);
              return {'exercises': exercises};
            },
          ),
          now: () => routineToday,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoSearchTextField), text);
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(RoutineCard), findsOneWidget);
    return calls;
  }

  Finder readAs() => find.descendant(
    of: find.byType(RoutineCard),
    matching: find.textContaining(l.routineReadAs('')),
  );

  testWidgets('사람이 친 운동만 읽었으면 "이렇게 읽었어요" 가 목록을 되풀이하지 않는다', (
    tester,
  ) async {
    final calls = await ask(tester, '벤치프레스랑 랫풀다운으로 짜줘', [
      '벤치프레스',
      '랫풀다운',
    ]);
    expect(calls, hasLength(1), reason: '모델이 읽은 카드여야 한다');
    expect(find.text('벤치프레스'), findsOneWidget);
    expect(find.text('랫풀다운'), findsOneWidget);
    expect(readAs(), findsNothing);
  });

  testWidgets('모델이 고른 운동은 "이렇게 읽었어요" 에 남는다 — 모델의 선택임을 말한다', (
    tester,
  ) async {
    await ask(tester, '나는 대원근을 키우고 싶음.', ['랫풀다운', '풀업']);
    expect(find.text('랫풀다운'), findsOneWidget);
    expect(find.text(l.routineReadAs('랫풀다운·풀업')), findsOneWidget);
    // 되비추는 말이라 목록 글자보다 옅다.
    final caption = tester.widget<Text>(readAs());
    final title = tester.widget<Text>(find.text('랫풀다운'));
    expect(caption.style!.fontSize, lessThan(title.style!.fontSize!));
  });

  for (final b in Brightness.values) {
    testWidgets('[시작] 글자가 바탕과 대비된다 ($b)', (tester) async {
      await ask(tester, '나는 대원근을 키우고 싶음.', [
        '랫풀다운',
        '풀업',
      ], brightness: b);
      final label = tester.renderObject<RenderParagraph>(
        find.text(l.routineStart),
      );
      final ink = label.text.style!.color!;
      final fill = b == Brightness.dark ? seal.darkColor : seal.color;
      final ratio =
          (ink.computeLuminance() + 0.05) / (fill.computeLuminance() + 0.05);
      final contrast = ratio >= 1 ? ratio : 1 / ratio;
      expect(contrast, greaterThanOrEqualTo(4.5));
    });
  }
}
