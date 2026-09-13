import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/record_query.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/quantities.dart';
import '../tool/question_grading.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  final today = DateTime(2026, 9, 9);
  final l = lookupL(const Locale('ko'));

  test(
    'original measured precision is preserved and rounded output is labeled',
    () {
      final notes = [
        Note(
          id: 'precise',
          createdAt: today,
          updatedAt: today,
          blocks: [
            ExerciseBlock('스쿼트', [LoggedSet(value: 82.125, reps: 5)]),
          ],
        ),
      ];
      for (final action in ['heaviest', 'latest']) {
        final plan = RecordQueryPlan.decode(
          {
            'action': action,
            'exercises': ['스쿼트'],
            'periods': ['all'],
          },
          ['스쿼트'],
        );
        expect(
          executeRecordPlan(
            plan,
            notes,
            l,
            'kg',
            confirmed: true,
          ).single.headline,
          contains('82.125kg'),
        );
      }
      expect(formatRoundedQuantity(82.125, 'ko'), startsWith('≈'));
      expect(formatRoundedQuantity(80, 'ko'), '80');
      expect(formatRoundedQuantity(1 / 3, 'ko', signed: true), '≈+0.33');
    },
  );

  test(
    'missing measurements cannot produce partial totals or filtered counts',
    () {
      final notes = [
        Note(
          id: 'incomplete',
          createdAt: today,
          updatedAt: today,
          blocks: [
            ExerciseBlock('스쿼트', [
              LoggedSet(value: 80, reps: 5),
              LoggedSet(value: 80),
              LoggedSet(reps: 5),
            ]),
          ],
        ),
      ];
      for (final action in ['repCount', 'volume', 'heaviest', 'meanWeight']) {
        final plan = RecordQueryPlan.decode(
          {
            'action': action,
            'exercises': ['스쿼트'],
            'periods': ['all'],
          },
          ['스쿼트'],
        );
        expect(
          executeRecordPlan(plan, notes, l, 'kg', confirmed: true),
          isEmpty,
          reason: action,
        );
      }
      final filtered = RecordQueryPlan.decode(
        {
          'action': 'setCount',
          'exercises': ['스쿼트'],
          'periods': ['all'],
          'weight': {'operator': '>=', 'value': 80, 'unit': 'kg'},
        },
        ['스쿼트'],
      );
      expect(
        executeRecordPlan(filtered, notes, l, 'kg', confirmed: true),
        isEmpty,
      );
    },
  );

  test('a model proposal cannot execute before explicit confirmation', () {
    final plan = RecordQueryPlan.decode(
      {
        'action': 'setCount',
        'exercises': ['스쿼트'],
        'periods': ['all'],
      },
      ['스쿼트'],
      question: '스쿼트 몇 세트?',
      today: today,
    );
    final notes = [
      Note(
        id: 'one',
        createdAt: today,
        updatedAt: today,
        blocks: [
          ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
        ],
      ),
    ];
    expect(plan.doubts, isEmpty);
    expect(plan.requiresConfirmation, isTrue);
    expect(executeRecordPlan(plan, notes, l, 'kg'), isEmpty);
    expect(
      executeRecordPlan(
        plan,
        notes,
        l,
        'kg',
        confirmed: true,
      ).single.numericValue,
      1,
    );
  });

  test('sentence titles do not lose completed repetitions, sets or days', () {
    final notes = [
      for (var i = 0; i < 2; i++)
        Note(
          id: '$i',
          createdAt: today,
          updatedAt: today,
          blocks: [
            ExerciseBlock(
              '벤치 80kg 100개 채우기',
              [
                LoggedSet(value: 80, reps: 10),
                LoggedSet(value: 100, reps: 99, done: false),
              ],
              const WorkoutSetup(name: '벤치프레스', weight: 80, totalReps: 100),
            ),
          ],
        ),
    ];
    for (final (action, count) in [
      ('repCount', 20),
      ('setCount', 2),
      ('trainingDays', 1),
    ]) {
      final plan = RecordQueryPlan.decode(
        {
          'action': action,
          'exercises': ['벤치프레스'],
          'periods': ['all'],
        },
        ['벤치프레스'],
      );
      expect(
        executeRecordPlan(
          plan,
          notes,
          l,
          'kg',
          confirmed: true,
        ).single.numericValue,
        count,
        reason: action,
      );
    }
  });

  test('kg/lb equality includes the exact boundary without tolerance', () {
    final notes = [
      Note(
        id: 'units',
        createdAt: today,
        updatedAt: today,
        blocks: [
          ExerciseBlock('벤치프레스', [
            LoggedSet(value: 100, unit: 'lb', reps: 5),
            LoggedSet(value: 45.359237, unit: 'kg', reps: 5),
            LoggedSet(value: 45.359237001, unit: 'kg', reps: 5),
            LoggedSet(value: 45.359236999, unit: 'kg', reps: 5),
          ]),
        ],
      ),
    ];
    final plan = RecordQueryPlan.decode(
      {
        'action': 'setCount',
        'exercises': ['벤치프레스'],
        'periods': ['all'],
        'weight': {'operator': '=', 'value': 45.359237, 'unit': 'kg'},
      },
      ['벤치프레스'],
    );
    expect(
      executeRecordPlan(
        plan,
        notes,
        l,
        'kg',
        confirmed: true,
      ).single.numericValue,
      2,
    );
    expect(compareWeights(0.1, 'lb', 0.045359237, 'kg'), 0);
    expect(compareWeights(1e-7, 'lb', 4.5359237e-8, 'kg'), 0);
    expect(compareWeights(45.359237001, 'kg', 100, 'lb'), greaterThan(0));
    expect(compareWeights(45.359236999, 'kg', 100, 'lb'), lessThan(0));
  });

  test('calendar boundaries include leap days and remain at midnight', () {
    for (final (clock, period, days, since, until) in [
      (
        DateTime(2028, 3, 1),
        'lastMonth',
        null,
        DateTime(2028, 2, 1),
        DateTime(2028, 2, 29),
      ),
      (
        DateTime(2027, 1, 1),
        'lastWeek',
        null,
        DateTime(2026, 12, 21),
        DateTime(2026, 12, 27),
      ),
      (
        DateTime(2026, 11, 2),
        'recent',
        2,
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 2),
      ),
    ]) {
      final plan = RecordQueryPlan.decode(
        {
          'action': 'setCount',
          'exercises': ['스쿼트'],
          'periods': [period],
          'days': ?days,
        },
        ['스쿼트'],
        today: clock,
      );
      expect(plan.requests.single.since, since);
      expect(plan.requests.single.until, until);
      expect(plan.requests.single.since!.hour, 0);
    }
  });

  test(
    'the grader rejects wrong dates, extra filters, operations and requests',
    () {
      final target = <String, Object?>{
        'exercise': '스쿼트',
        'metric': 'sets',
        'since': '2026-08-31',
        'until': '2026-09-06',
      };
      final request = {...target, 'unit': 'kg'};
      Map<String, Object?> out(Map<String, Object?> row) => {
        'kind': 'answer',
        'rank': false,
        'compare': false,
        'requests': [row],
      };
      expect(gradeRecordQuestion(out(request), target), isEmpty);
      for (final patch in [
        {'since': '2026-08-13'},
        {'until': '2026-09-09'},
        {'minWeight': 5},
        {'maxReps': 8},
        {'unit': 'lb'},
      ]) {
        expect(
          gradeRecordQuestion(out({...request, ...patch}), target),
          isNotEmpty,
        );
      }
      for (final patch in [
        {'rank': true},
        {'compare': true},
        {
          'requests': [request, request],
        },
      ]) {
        expect(
          gradeRecordQuestion({...out(request), ...patch}, target),
          isNotEmpty,
        );
      }
    },
  );

  test('explicit calendar periods override a conflicting model period', () {
    for (final (text, since, until) in [
      ('지난주', DateTime(2026, 8, 31), DateTime(2026, 9, 6)),
      ('이번 주', DateTime(2026, 9, 7), today),
      ('지난달', DateTime(2026, 8, 1), DateTime(2026, 8, 31)),
      ('최근 2주', DateTime(2026, 8, 27), today),
    ]) {
      final plan = RecordQueryPlan.decode(
        {
          'action': 'volume',
          'exercises': ['랫풀다운'],
          'periods': ['recent'],
          'days': 28,
        },
        ['랫풀다운'],
        question: '$text 랫풀다운 볼륨?',
        today: today,
      );
      expect(plan.requests.single.since, since, reason: text);
      expect(plan.requests.single.until, until, reason: text);
    }
  });

  test('a repetitions-only threshold cannot acquire a weight threshold', () {
    final plan = RecordQueryPlan.decode(
      {
        'action': 'setCount',
        'exercises': ['데드리프트'],
        'periods': ['today'],
        'weight': {'operator': '>=', 'value': 5, 'unit': 'kg'},
        'repetitions': {'operator': '>=', 'value': 5},
      },
      ['데드리프트'],
      question: '오늘 데드리프트 세트 몇 개 했어 5회 이상?',
      today: today,
    );
    final request = plan.requests.single;
    expect(request.minWeight, isNull);
    expect(request.maxWeight, isNull);
    expect(request.minReps, 5);
    expect(request.maxReps, isNull);
  });

  test(
    'a separate unitless threshold is preserved for explicit confirmation',
    () {
      final plan = RecordQueryPlan.decode(
        {
          'action': 'setCount',
          'exercises': ['스쿼트'],
          'periods': ['all'],
          'weight': {'operator': '>=', 'value': 80, 'unit': 'kg'},
          'repetitions': {'operator': '>=', 'value': 5},
        },
        ['스쿼트'],
        question: '스쿼트 80 이상 5회 이상 세트',
      );
      expect(plan.requests.single.minWeight, 80);
      expect(plan.requests.single.minReps, 5);
      expect(plan.requiresConfirmation, isTrue);
    },
  );
}
