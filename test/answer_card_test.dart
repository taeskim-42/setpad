import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/answer_card.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/palette.dart';
import 'package:setpad/stats.dart';

class _Records extends NotesStore {
  _Records(this.records);
  final List<Note> records;
  @override
  List<Note> get notes => records;
}

void main() {
  setUpAll(() => initializeDateFormatting());
  final day = DateTime(2026, 8, 1);
  Note record(int days, String exercise, List<LoggedSet> sets) => Note(
    id: '$days-$exercise',
    createdAt: day.add(Duration(days: days)),
    updatedAt: day,
    blocks: [ExerciseBlock(exercise, sets)],
  );
  final notes = [
    record(0, '벤치프레스', [
      LoggedSet(value: 60, reps: 12),
      LoggedSet(value: 65, reps: 10),
    ]),
    record(7, '벤치프레스', [LoggedSet(value: 75, reps: 8)]),
    record(21, '벤치프레스', [LoggedSet(value: 80, reps: 5)]),
    record(1, '스쿼트', [LoggedSet(value: 100, reps: 5)]),
  ];
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('ko'),
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      CupertinoApp(
        locale: locale,
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: CupertinoThemeData(brightness: brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: CupertinoPageScaffold(child: SingleChildScrollView(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('questions require an explicit metric and unambiguous exercise', () {
    const names = ['벤치프레스', '스쿼트'];
    expect(recordQuestion('벤치 최고', names), (
      metric: Metric.max,
      exercise: '벤치프레스',
    ));
    expect(recordQuestion('스쿼트 추이', names)?.metric, Metric.trend);
    for (final text in ['', '벤치', '최고', '없는 운동 최고', '벤치 최고 머신']) {
      expect(recordQuestion(text, names), isNull);
    }
    expect(recordQuestion('벤치 최고', ['벤치프레스', '인클라인 벤치프레스']), isNull);
    expect(recordQuestion('최고 머신', ['최고 머신']), isNull);
    expect(recordQuestion('bench best', ['Bench press'])?.metric, Metric.max);
  });

  test('weight units are comparable without mutating saved records', () {
    final mixed = [
      record(0, '벤치프레스', [
        LoggedSet(value: 100, unit: 'lb', reps: 8),
        LoggedSet(value: 60, reps: 8),
      ]),
    ];
    expect(dailyBest(mixed, '벤치프레스').single.value, 60);
    expect(
      dailyBest(mixed, '벤치프레스', unit: 'lb').single.value,
      closeTo(132.277, 0.001),
    );
    expect(mixed.single.blocks.single.sets.first.value, 100);
    expect(
      dailyBest([
        ...notes,
        record(4, '인클라인 벤치프레스', [LoggedSet(value: 200, reps: 1)]),
      ], '벤치프레스').length,
      3,
    );
  });

  test('missing repetitions are never presented as measured zeroes', () {
    final incomplete = [
      record(0, '벤치프레스', [LoggedSet(value: 80)]),
    ];
    expect(answer(incomplete, Metric.max, '벤치프레스').headline, '80kg');
    expect(answer(incomplete, Metric.last, '벤치프레스').headline, '80kg');
    expect(answer(incomplete, Metric.volume, '벤치프레스').isEmpty, isTrue);
  });

  testWidgets(
    'actual dots equal recorded days, never sets; horizontal spacing follows time',
    (tester) async {
      final data = answer(notes, Metric.trend, '벤치프레스');
      await pump(tester, AnswerCard(answer: data));
      final paint = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<DotChartPainter>()
          .single;
      final positions = paint.recordPositions(const Size(220, 156));
      expect(positions.length, 3);
      expect(
        positions[2].dx - positions[1].dx,
        closeTo(2 * (positions[1].dx - positions[0].dx), 0.001),
      );
      expect(positions.every((p) => p.dx.isFinite && p.dy.isFinite), isTrue);
    },
  );

  testWidgets('empty and plan-only records produce no card', (tester) async {
    await pump(
      tester,
      AnswerCard(answer: answer([record(0, '스쿼트', [])], Metric.max, '스쿼트')),
    );
    expect(find.byType(GrainWash), findsNothing);
    expect(find.byType(DotChart), findsNothing);
  });

  testWidgets(
    'ink and paper swap in dark mode without absolute black or white',
    (tester) async {
      late Color ink, paper, darkInk, darkPaper;
      Widget probe(bool dark) => Builder(
        builder: (context) {
          if (dark) {
            darkInk = answerInk.resolveFrom(context);
            darkPaper = answerPaper.resolveFrom(context);
          } else {
            ink = answerInk.resolveFrom(context);
            paper = answerPaper.resolveFrom(context);
          }
          return const SizedBox();
        },
      );
      await pump(tester, probe(false));
      await pump(tester, probe(true), brightness: Brightness.dark);
      expect(darkInk.toARGB32(), paper.toARGB32());
      expect(darkPaper.toARGB32(), ink.toARGB32());
      expect(ink, isNot(CupertinoColors.black));
      expect(paper, isNot(CupertinoColors.white));
      expect(ink.computeLuminance(), lessThan(paper.computeLuminance()));
    },
  );

  testWidgets(
    'search places an answer above matching records and clears it for ordinary searches',
    (tester) async {
      final store = _Records(notes);
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: NotesListPage(store: store, onOpen: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      final search = find.byType(CupertinoSearchTextField);
      for (final text in ['벤치 최고', '스쿼트 추이']) {
        await tester.enterText(search, text);
        await tester.pumpAndSettle();
        expect(find.byType(AnswerCard), findsOneWidget);
        expect(find.text('검색 결과가 없습니다'), findsNothing);
      }
      for (final text in ['벤치', '', '데드리프트 최고']) {
        await tester.enterText(search, text);
        await tester.pumpAndSettle();
        expect(find.byType(AnswerCard), findsNothing);
      }
      store.dispose();
    },
  );

  testWidgets(
    'all locales, long names and a single constant point lay out without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final locale in L.supportedLocales) {
        final l = lookupL(locale);
        final data = answer(
          [
            record(0, 'Long exercise name / 운동 이름이 아주 긴 경우', [
              LoggedSet(value: 80, reps: 10),
            ]),
          ],
          Metric.trend,
          'Long exercise name / 운동 이름이 아주 긴 경우',
          labels: l,
        );
        await pump(
          tester,
          AnswerCard(answer: data),
          locale: locale,
          scale: 1.5,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
