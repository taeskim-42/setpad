import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:setpad/record_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
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

  testWidgets('date labels follow recorded days below the plot', (
    tester,
  ) async {
    final data = answer(notes, Metric.trend, '벤치프레스');
    await pump(tester, AnswerCard(answer: data));
    final plot = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is DotChartPainter,
    );
    for (final point in data.points) {
      final label = find.byKey(
        ValueKey('chart-date-${point.day.toIso8601String()}'),
      );
      expect(label, findsOneWidget);
      expect(
        tester.widget<Text>(label).data,
        DateFormat.Md('ko').format(point.day),
      );
      expect(
        tester.getRect(label).top,
        greaterThan(tester.getRect(plot).bottom),
      );
    }
  });

  testWidgets('single record has one centered date', (tester) async {
    final points = [DayPoint(day, 80, 5, 'kg')];
    await pump(tester, DotChart(points: points, exercise: '벤치프레스'));
    final label = find.byKey(ValueKey('chart-date-${day.toIso8601String()}'));
    final plot = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is DotChartPainter,
    );
    expect(label, findsOneWidget);
    expect(
      tester.getCenter(label).dx,
      closeTo(tester.getCenter(plot).dx, 0.01),
    );
  });

  testWidgets(
    'crowded dates never overlap and cross-year dates include years',
    (tester) async {
      final points = [
        DayPoint(DateTime(2025, 12, 20), 60, 5, 'kg'),
        DayPoint(DateTime(2026, 1, 1), 70, 5, 'kg'),
        DayPoint(DateTime(2026, 1, 20), 80, 5, 'kg'),
      ];
      await pump(
        tester,
        Center(
          child: SizedBox(
            width: 220,
            child: DotChart(points: points, exercise: '벤치프레스'),
          ),
        ),
        scale: 2,
      );
      final first = find.byKey(
        ValueKey('chart-date-${points.first.day.toIso8601String()}'),
      );
      final last = find.byKey(
        ValueKey('chart-date-${points.last.day.toIso8601String()}'),
      );
      expect(tester.widget<Text>(first).data, contains('2025'));
      expect(tester.widget<Text>(last).data, contains('2026'));
      expect(tester.getRect(first).overlaps(tester.getRect(last)), isFalse);
      expect(
        find.byKey(ValueKey('chart-date-${points[1].day.toIso8601String()}')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
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

  testWidgets('G8 점이 없어도 헤드라인이 있는 답(0 으로 채운 칸, 연속·간격)은 카드가 된다', (tester) async {
    await pump(
      tester,
      const AnswerCard(
        answer: Answer(
          metric: Metric.sessions,
          exercise: '바벨로우',
          points: [],
          numericValue: 0,
          unit: '일',
          headline: '0일 기록',
          lines: ['적은 적 없음'],
        ),
      ),
    );
    expect(find.byType(GrainWash), findsOneWidget);
    expect(find.byType(DotChart), findsNothing);
    expect(find.text('0일 기록'), findsOneWidget);
    expect(find.text('적은 적 없음'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    'search requires confirmation before placing an answer above matching records',
    (tester) async {
      Future<Object?> reply(String instructions, String input) async {
        final question = jsonDecode(input)['question'] as String;
        if (!question.contains('최고') && !question.contains('추이')) {
          return {'kind': 'clarify'};
        }
        if (question.contains('데드리프트')) return {'kind': 'missing'};
        return {
          'exercises': [question.contains('스쿼트') ? '스쿼트' : '벤치프레스'],
          'measures': ['best'],
        };
      }

      final store = _Records(notes);
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: NotesListPage(
            store: store,
            onOpen: (_) {},
            ai: RecordAi(respond: reply),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final search = find.byType(CupertinoSearchTextField);
      for (final text in ['벤치 최고', '스쿼트 추이']) {
        await tester.enterText(search, text);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(find.byType(AnswerCard), findsNothing);
        await tester.tap(find.widgetWithText(SuggestionChip, '맞아요'));
        await tester.pumpAndSettle();
        expect(find.byType(AnswerCard), findsOneWidget);
        expect(find.text('검색 결과가 없습니다'), findsNothing);
      }
      for (final text in ['벤치', '', '데드리프트 최고']) {
        await tester.enterText(search, text);
        await tester.pump(const Duration(seconds: 1));
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
