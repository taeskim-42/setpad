import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/account.dart' show dailyPlateSets;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/answer_card.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/palette.dart';
import 'package:setpad/record_query.dart';

class _Records extends NotesStore {
  _Records(this.records, {this.unit = "kg"});
  final String unit;
  @override
  String get weightUnit => unit;
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

  Future<_Records> pump(
    WidgetTester tester, {
    String unit = "kg",
    Locale locale = const Locale("ko"),
    RecordAi ai = const RecordAi(),
    List<Note>? records,
  }) async {
    final store = _Records(records ?? notes, unit: unit);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        locale: locale,
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: NotesListPage(store: store, onOpen: (_) {}, ai: ai),
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

  testWidgets(
    'confirmation shows both periods, years and every numeric bound',
    (tester) async {
      tester.view.physicalSize = const Size(640, 1100);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<Object?> reply(String instructions, String input) async {
        return {
          'exercises': ['벤치프레스'],
          'measures': ['setCount'],
          'weight': [
            {'op': '>=', 'value': 60.125, 'unit': 'lb'},
            {'op': '<=', 'value': 80.375, 'unit': 'lb'},
          ],
          'reps': [
            {'op': '>=', 'value': 5},
            {'op': '<=', 'value': 10},
          ],
          'compare': [
            for (final year in [2025, 2026])
              {
                'period': 'custom',
                'since': '$year-08-01',
                'until': '$year-08-31',
              },
          ],
        };
      }

      await pump(tester, ai: RecordAi(respond: reply));
      await tester.enterText(
        find.byType(CupertinoSearchTextField),
        '작년과 올해 벤치 세트 비교',
      );
      await tester.pumpAndSettle();
      for (final text in [
        '2025-08-01',
        '2025-08-31',
        '2026-08-01',
        '2026-08-31',
        '≥ 60.125lb',
        '≤ 80.375lb',
        '≥ 5회',
        '≤ 10회',
        '차이 (2 − 1)',
      ]) {
        expect(find.textContaining(text), findsOneWidget, reason: text);
      }
      expect(find.byType(AnswerCard), findsNothing);
      expect(find.text(lookupL(const Locale('ko')).queryNoData), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bare aliases skip generation but complete questions still use the model',
    (tester) async {
      var queries = 0;
      Future<Object?> reply(String instructions, String input) async {
        queries++;
        return {
          'exercises': ['벤치프레스'],
          'measures': ['best'],
        };
      }

      await pump(tester, ai: RecordAi(respond: reply));
      final input = find.byType(CupertinoSearchTextField);
      await tester.enterText(input, '벤치');
      await tester.pumpAndSettle();
      expect(queries, 0);
      await tester.enterText(input, '벤치 최고');
      await tester.pumpAndSettle();
      expect(queries, 1);
      expect(find.byType(AnswerCard), findsNothing);
      expect(find.textContaining('전체 기간'), findsWidgets);
      await tester.tap(find.widgetWithText(SuggestionChip, '맞아요'));
      await tester.pumpAndSettle();
      expect(find.byType(AnswerCard), findsOneWidget);
      await tester.enterText(input, '스쿼트');
      await tester.pumpAndSettle();
      await tester.enterText(input, '벤치 최고');
      await tester.pumpAndSettle();
      expect(queries, 1, reason: 'Only the interpretation is cached');
      expect(find.byType(AnswerCard), findsNothing);
      expect(find.widgetWithText(SuggestionChip, '맞아요'), findsOneWidget);
    },
  );

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

  testWidgets('metric picks respect the app language and weight unit', (
    tester,
  ) async {
    await pump(tester, unit: 'lb', locale: const Locale('en'));
    await tester.enterText(find.byType(CupertinoSearchTextField), '벤치프레스');
    await tester.pumpAndSettle();
    final l = lookupL(const Locale('en'));
    await tester.tap(find.widgetWithText(SuggestionChip, l.metricMax));
    await tester.pumpAndSettle();
    final result = tester.widget<AnswerCard>(find.byType(AnswerCard)).answer;
    expect(result.points.every((p) => p.unit == 'lb'), isTrue);
    expect(result.headline, contains('lb'));
    expect(result.lines.join(), isNot(matches(RegExp(r'[가-힣]'))));
  });

  testWidgets('문장 속의 운동도 칩을 띄운다 — 스쾃 PR 얼마?', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(CupertinoSearchTextField), '스쾃 PR 얼마?');
    await tester.pumpAndSettle();
    expect(find.text('스쿼트'), findsWidgets);
    expect(find.widgetWithText(SuggestionChip, '최고'), findsOneWidget);
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
    final spans = highlightMatch(
      '벤치프레스 · 스쿼트',
      '밴치',
      hit: hit,
    ).cast<TextSpan>();
    expect(spans.where((t) => t.style == hit).map((t) => t.text), ['벤치프레스']);
    expect(spans.where((t) => t.text == '스쿼트').single.style, isNull);
  });

  test('검색어가 없으면 아무것도 안 칠한다', () {
    final spans = highlightMatch('벤치프레스', '', hit: const TextStyle());
    expect(spans.single.style, isNull);
  });

  testWidgets('의심스러운 해석은 묻고, 맞아요를 눌러야 답한다', (tester) async {
    Future<Object?> reply(String instructions, String input) async {
      // 글에 시간 말이 없는데 모델이 "최근 400일" 을 지어냈다 → 의심.
      // (400 인 이유: 픽스처 기록이 8월 4일이라 그 안에 들어야 답이 있다.)
      return {
        'exercises': ['스쿼트'],
        'period': 'recent',
        'days': 400,
        'measures': ['weightChange'],
      };
    }

    await pump(tester, ai: RecordAi(respond: reply));
    await tester.enterText(find.byType(CupertinoSearchTextField), '스쿼트 추이 알려줘');
    await tester.pumpAndSettle();

    expect(find.byType(AnswerCard), findsNothing, reason: '의심스러우면 바로 답하지 않는다');
    expect(find.textContaining('이렇게 읽었어요'), findsOneWidget);
    expect(find.textContaining('추이'), findsWidgets);

    await tester.tap(find.widgetWithText(SuggestionChip, '맞아요'));
    await tester.pumpAndSettle();
    expect(find.byType(AnswerCard), findsOneWidget, reason: '확인하면 답한다');
    expect(find.textContaining('이렇게 읽었어요'), findsNothing);
  });

  group('이름이 둘 — 벤치프레스 vs 바벨로우 기록 비교', () {
    const question = '벤치프레스 vs 바벨로우 기록 비교';
    final l = lookupL(const Locale('ko'));
    LoggedSet set(double kg, int reps) => LoggedSet(value: kg, reps: reps);
    Note on(String id, int month, int day, List<ExerciseBlock> blocks) {
      final at = DateTime(2026, month, day, 19);
      return Note(id: id, createdAt: at, updatedAt: at, blocks: blocks);
    }

    // 스펙 3.11-A 의 벤치·로우 날들에 스쿼트만 한 날 하나.
    final pair = [
      on('N1', 8, 4, [
        ExerciseBlock('벤치프레스', [set(80, 5), set(85, 3)]),
        ExerciseBlock('바벨로우', [set(60, 8), set(60, 8)]),
      ]),
      on('N2', 8, 18, [
        ExerciseBlock('벤치프레스', [set(82.5, 5), set(82.5, 5)]),
      ]),
      on('N3', 9, 7, [
        ExerciseBlock('벤치프레스', [set(85, 5)]),
        ExerciseBlock('바벨로우', [set(70, 6)]),
      ]),
      on('N4', 9, 14, [
        ExerciseBlock('스쿼트', [set(100, 5)]),
      ]),
      on('N5', 9, 21, [
        ExerciseBlock('벤치프레스', [set(87.5, 2)]),
      ]),
    ];
    final table = find.byType(TableCard);

    /// 표가 길어 개수 줄이 화면 밖이면 아직 안 지어졌다. 굴려서 찾는다.
    Future<void> expectCount(WidgetTester tester, int n) async {
      await tester.scrollUntilVisible(
        find.text(l.noteCount(n)),
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text(l.noteCount(n)), findsOneWidget);
    }

    Finder inTable(String text) =>
        find.descendant(of: table, matching: find.text(text));

    /// 대조형 표: 머리줄 + 측정 셋, 칸은 이름 + 두 운동.
    void expectContrast(WidgetTester tester) {
      expect(table, findsOneWidget);
      final rows = tester
          .widget<Table>(
            find.descendant(of: table, matching: find.byType(Table)),
          )
          .children;
      expect(rows, hasLength(4));
      expect(rows.every((r) => r.children.length == 3), isTrue);
      for (final text in [
        '벤치프레스',
        '바벨로우',
        '최고',
        '운동한 날',
        '마지막',
        '87.5kg × 2회',
        '70kg × 6회',
        '4일 기록',
        '2일 기록',
        '9월 21일',
        '9월 7일',
      ]) {
        expect(inTable(text), findsWidgets, reason: text);
      }
      expect(
        find.descendant(
          of: table,
          matching: find.textContaining('-17.5kg (-20%)'),
        ),
        findsOneWidget,
      );
    }

    testWidgets('기다리는 동안 목록이 남고, 비교 칩은 모델 없이 표를 띄운다', (tester) async {
      final pending = Completer<Object?>();
      var asked = 0;
      await pump(
        tester,
        records: pair,
        ai: RecordAi(
          respond: (_, _) {
            asked++;
            return pending.future;
          },
        ),
      );
      await tester.enterText(find.byType(CupertinoSearchTextField), question);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(l.queryWorking), findsOneWidget);
      expect(asked, 1);
      expect(
        find.text(l.noteCount(4)),
        findsOneWidget,
        reason: '해석을 기다리는 동안에도 두 운동이 든 기록은 보인다',
      );
      // 목록의 제목(Text.rich)도 같은 글이라 이름 줄은 평글로 찾는다.
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == '벤치프레스 · 바벨로우'),
        findsOneWidget,
      );
      for (final label in ['비교', '최고', '운동한 날', '볼륨']) {
        expect(find.widgetWithText(SuggestionChip, label), findsOneWidget);
      }

      await tester.tap(find.widgetWithText(SuggestionChip, '비교'));
      await tester.pumpAndSettle();
      expectContrast(tester);
      expect(find.text(l.queryWorking), findsNothing, reason: '모델 결과를 비웠다');
      expect(find.textContaining(l.readAsConfirm), findsNothing);
      expect(asked, 1, reason: '칩은 모델을 부르지 않는다');
      await expectCount(tester, 4);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 2000));
      await tester.pumpAndSettle();

      // 한 측정 칩은 차이를 헤드라인으로 올린다.
      await tester.tap(find.widgetWithText(SuggestionChip, '운동한 날'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: table, matching: find.text('-2일 (-50%)')),
        findsOneWidget,
        reason: '헤드라인은 값만',
      );
      expect(
        find.descendant(
          of: table,
          matching: find.text('운동한 날 · 차이 (바벨로우 − 벤치프레스): -2일 (-50%)'),
        ),
        findsOneWidget,
        reason: '무엇에서 무엇을 뺐는지는 아래 줄이 말한다',
      );
      await tester.tap(find.widgetWithText(SuggestionChip, '운동한 날'));
      await tester.pumpAndSettle();
      expect(table, findsNothing, reason: '다시 누르면 접힌다');
    });

    testWidgets('모델이 v2 질의를 주면 확인 줄을 띄우고, 맞아요 뒤에 표를 띄운다', (tester) async {
      String? instructions;
      await pump(
        tester,
        records: pair,
        ai: RecordAi(
          respond: (i, _) async {
            instructions = i;
            return {
              'exercises': ['벤치프레스', '바벨로우'],
            };
          },
        ),
      );
      await tester.enterText(find.byType(CupertinoSearchTextField), question);
      await tester.pumpAndSettle();
      expect(instructions, contains('"벤치프레스 vs 바벨로우 기록 비교" =>'));

      expect(table, findsNothing, reason: '확인 전에는 답이 없다');
      expect(
        find.textContaining(
          '${l.readAsConfirm} · 벤치프레스 · 바벨로우 · 최고 · 운동한 날 · 마지막 · kg',
        ),
        findsOneWidget,
      );
      expect(find.text(l.noteCount(4)), findsOneWidget);

      await tester.tap(find.widgetWithText(SuggestionChip, l.confirmYes));
      await tester.pumpAndSettle();
      expectContrast(tester);
      expect(find.textContaining(l.readAsConfirm), findsNothing);
      await expectCount(tester, 4); // 답에 쓰인 기록
    });

    testWidgets('이름도 기간도 없는 질문은 기다리는 동안과 확인 전에 목록을 다 보인다', (tester) async {
      final reply = Completer<Object?>();
      await pump(
        tester,
        records: pair,
        ai: RecordAi(respond: (_, _) => reply.future),
      );
      await tester.enterText(
        find.byType(CupertinoSearchTextField),
        '가장 많이 한 운동 3개',
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(l.queryWorking), findsOneWidget);
      expect(find.text(l.noteCount(pair.length)), findsOneWidget);
      reply.complete({
        'by': 'exercise',
        'measures': ['trainingDays'],
        'order': 'desc',
        'limit': 3,
      });
      await tester.pumpAndSettle();
      expect(find.textContaining(l.readAsConfirm), findsOneWidget);
      expect(find.text(l.noteCount(pair.length)), findsOneWidget);
      expect(find.text(l.noSearchResults), findsNothing);
    });

    testWidgets('원판이 모자라면 그렇다고 말하고, 칩과 목록은 그대로다', (tester) async {
      await pump(
        tester,
        records: pair,
        ai: RecordAi(
          respond: (_, _) async =>
              throw const RecordAiException(RecordAiStatus.noPlates),
        ),
      );
      await tester.enterText(find.byType(CupertinoSearchTextField), question);
      await tester.pumpAndSettle();
      expect(find.text(l.noPlates(dailyPlateSets)), findsOneWidget);
      expect(find.text(l.queryFailed), findsNothing);
      expect(find.text(l.noteCount(4)), findsOneWidget);
      await tester.tap(find.widgetWithText(SuggestionChip, '비교'));
      await tester.pumpAndSettle();
      expectContrast(tester);
    });

    for (final size in [const Size(390, 844), const Size(320, 568)]) {
      testWidgets('${size.width.toInt()}×${size.height.toInt()} 에서 넘치지 않는다', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pump(
          tester,
          records: pair,
          ai: RecordAi(
            respond: (_, _) async => {
              'exercises': ['벤치프레스', '바벨로우'],
            },
          ),
        );
        await tester.enterText(find.byType(CupertinoSearchTextField), question);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.widgetWithText(SuggestionChip, l.confirmYes));
        await tester.pumpAndSettle();
        // 확인한 모델 답, 그리고 칩으로 고른 답 — 둘 다 끝까지 굴려 본다.
        Future<void> scrollThrough() async {
          await tester.ensureVisible(table);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final card = tester.getRect(table);
          expect(card.left, greaterThanOrEqualTo(0));
          expect(card.right, lessThanOrEqualTo(size.width));
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -400),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, 2000),
          );
          await tester.pumpAndSettle();
        }

        await scrollThrough();
        await tester.tap(find.widgetWithText(SuggestionChip, '비교'));
        await tester.pumpAndSettle();
        expect(find.textContaining(l.readAsConfirm), findsNothing);
        await scrollThrough();
      });
    }

    testWidgets('순위는 목록형 표 — 번호와 막대, 좁은 화면에서도', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> show(List<String> measures) async {
        final q = RecordQuery.decode(
          {'by': 'exercise', 'measures': measures, 'order': 'desc', 'limit': 3},
          ['벤치프레스', '바벨로우', '스쿼트'],
          today: DateTime(2026, 9, 23),
        );
        final r = runQuery(q, pair, l: l, unit: 'kg', confirmed: true)!;
        await tester.pumpWidget(
          CupertinoApp(
            locale: const Locale('ko'),
            localizationsDelegates: L.localizationsDelegates,
            supportedLocales: L.supportedLocales,
            home: CupertinoPageScaffold(
              child: SingleChildScrollView(
                child: TableCard(query: q, result: r),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('운동한 날 · 상위 3개 · 내림차순'), findsOneWidget);
        for (final label in ['01  벤치프레스', '02  바벨로우', '03  스쿼트']) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
        final bars = tester
            .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .map((b) => b.widthFactor);
        expect(bars, [1.0, 0.5, 0.25], reason: '운동한 날 4 · 2 · 1');
      }

      // 측정 하나: 이름 | 값 표.
      await show(['trainingDays']);
      final rows = tester.widget<Table>(find.byType(Table)).children;
      expect(rows, hasLength(4), reason: '머리줄 + 운동 셋');
      expect(rows.every((r) => r.children.length == 2), isTrue);

      // 측정 셋: 이름은 제 줄, 값은 그 아래에 같은 폭으로.
      await show(['trainingDays', 'best', 'latest']);
      expect(find.byType(Table), findsNothing);
      // 최고의 본문과, 마지막 날짜 아래의 그날 세트.
      expect(find.text('87.5kg × 2회'), findsNWidgets(2));
    });

    testWidgets('범위 안에 기록이 없는 운동은 칸마다 — 이고, 기록 없음이라 적는다', (tester) async {
      final q = RecordQuery(
        scope: QueryScope(
          exercises: const ['벤치프레스', '바벨로우'],
          since: DateTime(2026, 9, 10),
        ),
        by: 'exercise',
      );
      final r = runQuery(q, pair, l: l, unit: 'kg')!;
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: CupertinoPageScaffold(
            child: SingleChildScrollView(
              child: TableCard(query: q, result: r),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('87.5kg × 2회'), findsNWidgets(2));
      expect(find.text('—'), findsNWidgets(3), reason: '로우의 세 칸');
      expect(find.text(l.queryNoRecord), findsOneWidget);
      expect(find.textContaining('차이'), findsNothing, reason: '한쪽이 비면 차이가 없다');
    });
  });
}
