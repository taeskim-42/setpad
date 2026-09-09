import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/answer_card.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/palette.dart';

class _Records extends NotesStore {
  _Records(this.records);
  final List<Note> records;
  @override
  List<Note> get notes => records;
}

/// 운동 이름이 잡히면 칩이 뜨고, 칩을 누르면 답이 뜨고, 잡힌 글자는 색이 든다.
///
/// 이 셋은 해석 없이 **고르는** 경로다. 모델을 부르지 않으므로 여기서는
/// 모델을 흉내 낼 것도 없다.
void main() {
  setUpAll(() => initializeDateFormatting());
  final day = DateTime(2026, 8, 1);
  Note record(int days, String exercise, List<LoggedSet> sets) => Note(
    id: '$days-$exercise',
    createdAt: day.add(Duration(days: days)),
    updatedAt: day.add(Duration(days: days)),
    blocks: [ExerciseBlock(exercise, sets)],
  );
  final notes = [
    record(0, '벤치프레스', [LoggedSet(value: 60, reps: 12)]),
    record(7, '벤치프레스', [LoggedSet(value: 70, reps: 8)]),
    record(3, '스쿼트', [LoggedSet(value: 100, reps: 5)]),
  ];

  Future<_Records> pump(WidgetTester tester) async {
    final store = _Records(notes);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: NotesListPage(store: store, onOpen: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('운동 이름이 잡히면 칩 다섯 개가 뜬다', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(CupertinoSearchTextField), '벤치');
    await tester.pumpAndSettle();

    for (final label in ['최고', '추이', '마지막', '운동한 날', '볼륨']) {
      expect(find.widgetWithText(SuggestionChip, label), findsOneWidget);
    }
    expect(find.byType(AnswerCard), findsNothing, reason: '고르기 전엔 답이 없다');
  });

  testWidgets('칩을 누르면 답이 뜨고, 다시 누르면 접힌다', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(CupertinoSearchTextField), '벤치');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SuggestionChip, '최고'));
    await tester.pumpAndSettle();
    expect(find.byType(AnswerCard), findsOneWidget);
    expect(find.textContaining('70kg'), findsWidgets, reason: '숫자는 코드가 센다');

    await tester.tap(find.widgetWithText(SuggestionChip, '최고'));
    await tester.pumpAndSettle();
    expect(find.byType(AnswerCard), findsNothing);
  });

  testWidgets('검색어를 바꾸면 고른 것이 풀린다', (tester) async {
    await pump(tester);
    final search = find.byType(CupertinoSearchTextField);
    await tester.enterText(search, '벤치');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SuggestionChip, '추이'));
    await tester.pumpAndSettle();
    expect(find.byType(AnswerCard), findsOneWidget);

    await tester.enterText(search, '스쿼');
    await tester.pumpAndSettle();
    expect(find.byType(AnswerCard), findsNothing);
    expect(find.text('스쿼트'), findsWidgets);
  });

  test('글자 그대로 들어 있으면 그 글자만 칠한다', () {
    const hit = TextStyle(color: seal);
    final spans = highlightMatch('벤치프레스 · 스쿼트', '스쿼', hit: hit);
    final texts = spans.map((s) => (s as TextSpan)).toList();
    expect(texts.map((t) => t.text).join(), '벤치프레스 · 스쿼트');
    expect(texts.where((t) => t.style == hit).map((t) => t.text), ['스쿼']);
  });

  test('오타로 잡힌 것은 운동 이름 전체를 칠한다', () {
    const hit = TextStyle(color: seal);
    final spans = highlightMatch('벤치프레스 · 스쿼트', '밴치', hit: hit)
        .cast<TextSpan>();
    expect(spans.where((t) => t.style == hit).map((t) => t.text), ['벤치프레스']);
    expect(spans.where((t) => t.text == '스쿼트').single.style, isNull);
  });

  test('검색어가 없으면 아무것도 안 칠한다', () {
    final spans = highlightMatch('벤치프레스', '', hit: const TextStyle());
    expect(spans.single.style, isNull);
  });
}
