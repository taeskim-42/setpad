import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/stats.dart' show Answer;

import 'package:setpad/local_ai.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';

// Arithmetic tests operate on scopes already accepted by a user.
List<Answer> executeConfirmedPlan(
  RecordQueryPlan plan,
  List<Note> notes,
  L l,
  String unit,
) => executeRecordPlan(plan, notes, l, unit, confirmed: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting());
  const names = ['스쿼트', '벤치프레스', '푸시업'];
  Map<String, Object?> row(
    String exercise,
    String metric, {
    String since = '',
    String until = '',
  }) => {
    'exercise': exercise,
    'metric': metric,
    'since': since,
    'until': until,
  };
  Map<String, Object?> response(List<Object> queries, {bool compare = false}) =>
      {
        'kind': 'answer',
        'queries': queries,
        'searchNames': [],
        'compare': compare,
      };
  Note note(int month, int day, String name, List<LoggedSet> sets) => Note(
    id: '$month-$day-$name',
    createdAt: DateTime(2026, month, day),
    updatedAt: DateTime(2026, month, day),
    blocks: [ExerciseBlock(name, sets)],
  );
  final notes = [
    note(8, 2, '스쿼트', [LoggedSet(value: 100, reps: 5)]),
    note(9, 2, '스쿼트', [
      LoggedSet(value: 110, reps: 5),
      LoggedSet(value: 200, reps: 1, done: false),
    ]),
    note(8, 3, '푸시업', [LoggedSet(reps: 20), LoggedSet(reps: 15)]),
    note(9, 3, '벤치프레스', [
      LoggedSet(value: 80, reps: 8),
      LoggedSet(value: 75, reps: 10),
    ]),
  ];
  final l = lookupL(const Locale('ko'));
  test(
    'planner output rejects invented exercises, malformed dates and filters',
    () {
      for (final request in [
        row('없는 운동', 'max'),
        row('스쿼트', 'sql'),
        row('스쿼트', 'max', since: '2026-02-30'),
        {...row('스쿼트', 'max'), 'minWeight': 90, 'maxWeight': 80},
        row('*', 'max'),
      ]) {
        expect(
          () => RecordQueryPlan.decode(response([request]), names),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'period comparison and completed-only maxima use records, not generated answers',
    () {
      final plan = RecordQueryPlan.decode(
        response([
          row('스쿼트', 'max', since: '2026-08-01', until: '2026-08-31'),
          row('스쿼트', 'max', since: '2026-09-01', until: '2026-09-30'),
        ], compare: true),
        names,
      );
      final a = executeConfirmedPlan(plan, notes, l, 'kg').single;
      expect(a.headline, '+10kg');
      expect(a.points.length, 2);
    },
  );
  test(
    'bodyweight totals and weight-filtered set counts include meaningful data',
    () {
      final reps = RecordQueryPlan.decode(
        response([
          row('푸시업', 'reps', since: '2026-08-01', until: '2026-08-31'),
        ]),
        names,
      );
      expect(
        executeConfirmedPlan(reps, notes, l, 'kg').single.numericValue,
        35,
      );
      final sets = RecordQueryPlan.decode(
        response([
          {...row('벤치프레스', 'sets'), 'minWeight': 80},
        ]),
        names,
      );
      expect(executeConfirmedPlan(sets, notes, l, 'kg').single.numericValue, 1);
      final days = RecordQueryPlan.decode(
        response([row('*', 'sessions')]),
        names,
      );
      expect(executeConfirmedPlan(days, notes, l, 'kg').single.numericValue, 4);
    },
  );
  test('weight filters are converted by code, not by the language model', () {
    final plan = RecordQueryPlan.decode(
      response([
        {...row('벤치프레스', 'sets'), 'minWeight': 80, 'weightUnit': 'kg'},
      ]),
      names,
      defaultUnit: 'lb',
    );
    expect(executeConfirmedPlan(plan, notes, l, 'lb').single.numericValue, 1);
  });

  test('the most recent bodyweight session is answerable without weights', () {
    final plan = RecordQueryPlan.decode(response([row('푸시업', 'last')]), names);
    expect(
      executeConfirmedPlan(plan, notes, l, 'kg').single.headline,
      '20회  15회',
    );
  });

  test(
    'every natural-language request reaches the model with bounded name context',
    () async {
      const channel = MethodChannel('test/query_interpretation');
      final received = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final prompt =
                jsonDecode((call.arguments as Map)['prompt'] as String) as Map;
            received.add(prompt['question'] as String);
            expect(prompt['referenceYear'], 2026);
            expect(prompt.containsKey('today'), isFalse);
            expect(prompt.containsKey('records'), isFalse);
            return response([row('스쿼트', 'max')]);
          });
      const ai = LocalAi(channel: channel, nativeSupported: true);
      for (final question in [
        '스쿼트 최대 무게',
        '스쿼트 제일 무겁게 든 게 얼마야',
        '내 스쿼트 기록 중 가장 무거웠던 날 알려줘',
      ]) {
        final plan = await ai.queryRecords(
          question,
          'ko',
          names,
          unit: 'kg',
          today: DateTime(2026, 9, 8),
        );
        expect(
          executeConfirmedPlan(plan, notes, l, 'kg').single.numericValue,
          110,
        );
      }
      expect(received.length, 3);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );
  test(
    'ranking counts completed days rather than sets or uncompleted plans',
    () {
      final plan = RecordQueryPlan.decode({
        ...response([row('*', 'sessions')]),
        'rank': true,
        'limit': 2,
      }, names);
      final ranked = executeConfirmedPlan(plan, notes, l, 'kg');
      expect(ranked.first.exercise, '스쿼트');
      expect(ranked.first.numericValue, 2);
      expect(ranked.length, 2);
    },
  );

  test(
    'open record questions retrieve notes and plans without a fixed metric',
    () {
      final plan = RecordQueryPlan.decode({
        ...response([row('*', 'sets', since: '2026-09-01')]),
        'kind': 'insight',
        'terms': ['무릎'],
      }, names);
      final evidence = recordEvidence([
        ...notes,
        note(9, 4, '푸시업', [
          LoggedSet(reps: 10, notes: ['무릎 불편'], done: false),
        ]),
      ], plan);
      final facts = evidence['facts'] as List;
      expect((facts.first as Map)['completedSets'], 3);
      expect(evidence['matchingNoteBlocks'], 1);
      expect(jsonEncode(evidence), contains('무릎 불편'));
      expect(jsonEncode(evidence), contains('"done":false'));
      expect(jsonEncode(evidence), isNot(contains('2026-08-02')));
      expect(executeConfirmedPlan(plan, notes, l, 'kg'), isEmpty);
    },
  );

  test('record replies reject fabricated source IDs and missing evidence', () {
    final evidence = {
      'facts': [
        {'id': 'scope'},
      ],
    };
    for (final bad in [
      {
        'text': 'claim',
        'hasEvidence': true,
        'sources': ['invented'],
      },
      {'text': 'claim', 'hasEvidence': true, 'sources': []},
    ]) {
      expect(() => RecordReply.decode(bad, evidence), throwsFormatException);
    }
    expect(
      RecordReply.decode({
        'text': 'No recorded measurements',
        'hasEvidence': false,
        'sources': [],
      }, evidence).hasEvidence,
      isFalse,
    );
  });

  test(
    'open requests stop at source retrieval and never generate numerical prose',
    () async {
      const channel = MethodChannel('test/query_open');
      final methods = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'status') return 'available';
            if (call.method == 'cancel' || call.method == 'warmQuery') {
              return null;
            }
            methods.add(call.method);
            if (call.method == 'query') {
              return {
                ...response([row('*', 'sets')]),
                'kind': 'insight',
              };
            }
            final prompt =
                jsonDecode((call.arguments as Map)['prompt'] as String) as Map;
            expect(prompt['question'], '내 기록을 보고 어떤 특징이 있는지 알려줘');
            expect((prompt['evidence'] as Map)['facts'], isNotEmpty);
            return {
              'text': '스쿼트를 기록한 날이 가장 많습니다.',
              'hasEvidence': true,
              'sources': ['exercise1'],
            };
          });
      final search = RecordSearch(
        const LocalAi(channel: channel, nativeSupported: true),
      );
      await search.refresh('ko');
      search.search(
        '내 기록을 보고 어떤 특징이 있는지 알려줘',
        'ko',
        names,
        'kg',
        immediately: true,
        notes: notes,
      );
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(methods, ['query']);
      expect(search.plan?.requiresConfirmation, isTrue);
      expect(search.plan?.kind, 'insight');
      expect(search.failed, isFalse);
      search.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );

  test(
    'open requests cache only intent and never synthesize answers after record edits',
    () async {
      const channel = MethodChannel('test/query_reply_cache');
      var queries = 0, answers = 0, warms = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'status') return 'available';
            if (call.method == 'cancel') return null;
            if (call.method == 'warmQuery') {
              warms++;
              return null;
            }
            if (call.method == 'query') {
              queries++;
              return {
                ...response([row('*', 'sets')]),
                'kind': 'insight',
              };
            }
            answers++;
            return {
              'text': '기록에 남긴 메모입니다.',
              'hasEvidence': true,
              'sources': ['scope'],
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final search = RecordSearch(
        const LocalAi(channel: channel, nativeSupported: true),
      );
      addTearDown(search.dispose);
      await search.refresh('ko');
      void ask(List<Note> records) => search.search(
        '내 메모 읽어줘',
        'ko',
        names,
        'kg',
        notes: records,
        immediately: true,
      );
      ask(notes);
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect((queries, answers, warms), (1, 0, 1));
      search.search('', 'ko', names, 'kg');
      ask(notes);
      expect(search.busy, isFalse);
      expect(search.plan?.kind, 'insight');
      expect((queries, answers), (1, 0));
      final updated = [
        ...notes,
        Note(
          id: 'new-cache-record',
          createdAt: DateTime(2026, 9, 9),
          updatedAt: DateTime(2026, 9, 9),
          blocks: [
            ExerciseBlock('스쿼트', [LoggedSet(value: 90, reps: 5)]),
          ],
        ),
      ];
      ask(updated);
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect((queries, answers), (1, 0));
    },
  );

  testWidgets('typing waits 300ms and submit skips the wait', (tester) async {
    const channel = MethodChannel('test/query_debounce');
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'query') {
            calls++;
            return response([row('스쿼트', 'max')]);
          }
          return null;
        });
    final search = RecordSearch(
      const LocalAi(channel: channel, nativeSupported: true),
    )..status = LocalAiStatus.available;
    search.search('스쿼트 최고', 'ko', names, 'kg');
    await tester.pump(const Duration(milliseconds: 299));
    expect(calls, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, 1);
    search.search('스쿼트 최대 기록', 'ko', names, 'kg', immediately: true);
    await tester.pump();
    expect(calls, 2);
    search.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'matching notes omit unrelated detail while retaining scope aggregates',
    () {
      final plan = RecordQueryPlan.decode({
        ...response([row('*', 'sets')]),
        'kind': 'insight',
        'terms': ['무릎'],
      }, names);
      final records = [
        for (var i = 0; i < 30; i++)
          Note(
            id: 'focus-$i',
            createdAt: DateTime(2026, 8, i + 1),
            updatedAt: DateTime(2026, 8, i + 1),
            blocks: [
              ExerciseBlock('스쿼트', [
                LoggedSet(
                  value: 80,
                  reps: 5,
                  notes: [i == 0 ? '무릎이 불편' : '관련 없는 메모'],
                ),
              ]),
            ],
          ),
      ];
      final evidence = recordEvidence(records, plan);
      final facts = evidence['facts'] as List;
      expect(evidence['matchingNoteBlocks'], 1);
      expect((facts.first as Map)['completedDays'], 30);
      expect(jsonEncode(facts), contains('무릎이 불편'));
      expect(jsonEncode(facts), isNot(contains('관련 없는 메모')));
      expect(evidence['omittedFacts'] as int, greaterThan(0));
      expect(jsonEncode(evidence).length, lessThan(2000));
    },
  );

  test('large evidence is bounded and discloses omitted detail', () {
    final plan = RecordQueryPlan.decode({
      ...response([row('*', 'sets')]),
      'kind': 'insight',
      'terms': ['특별메모'],
    }, names);
    final many = [
      for (var i = 1; i <= 28; i++)
        note(8, i, '스쿼트', [
          LoggedSet(value: 80, reps: 10, notes: [i == 1 ? '특별메모' : '메모' * 200]),
        ]),
    ];
    final evidence = recordEvidence(many, plan);
    expect(jsonEncode(evidence).length, lessThan(7300));
    expect(evidence['omittedFacts'] as int, greaterThan(0));
    expect(jsonEncode(evidence), contains('특별메모'));
    expect(((evidence['facts'] as List).first as Map)['completedDays'], 28);
  });

  test('relative periods are computed by code, including leap years', () {
    final plan = RecordQueryPlan.decode(
      {
        'kind': 'comparison',
        'queries': [
          {...row('스쿼트', 'max'), 'period': 'lastMonth'},
          {...row('스쿼트', 'max'), 'period': 'thisMonth'},
        ],
      },
      names,
      today: DateTime(2024, 3, 8),
    );
    expect(plan.requests.first.since, DateTime(2024, 2, 1));
    expect(plan.requests.first.until, DateTime(2024, 2, 29));
    expect(plan.requests.last.since, DateTime(2024, 3, 1));
    expect(plan.requests.last.until, DateTime(2024, 3, 8));
  });

  test(
    'latest duration records retain their unit instead of plotting zero reps',
    () {
      final data = [
        note(9, 2, '플랭크', [LoggedSet(value: 60, unit: 's')]),
      ];
      final plan = RecordQueryPlan.decode(response([row('플랭크', 'last')]), [
        '플랭크',
      ]);
      final a = executeConfirmedPlan(plan, data, l, 'kg').single;
      expect(a.points.single.value, 60);
      expect(a.points.single.unit, 's');
    },
  );

  test('sparse natural model JSON and ranking kinds keep their intent', () {
    final plan = RecordQueryPlan.decode({
      'kind': 'ranking',
      'queries': [row('*', 'sessions')],
    }, names);
    expect(plan.rank, isTrue);
    expect(executeConfirmedPlan(plan, notes, l, 'kg').single.exercise, '스쿼트');
    final unrelated = RecordQueryPlan.decode({
      'kind': 'unsupported',
      'reason': 'unrelated',
    }, names);
    expect(unrelated.requests, isEmpty);
  });

  test(
    'submitting an in-flight question does not restart its model call',
    () async {
      const channel = MethodChannel('test/query_same_inflight');
      final result = Completer<Object?>();
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            if (call.method == 'status') return 'available';
            if (call.method == 'cancel' || call.method == 'warmQuery') {
              return null;
            }
            return result.future;
          });
      final search = RecordSearch(
        const LocalAi(channel: channel, nativeSupported: true),
      );
      await search.refresh('ko');
      search.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
      await Future<void>.delayed(Duration.zero);
      search.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
      expect(calls.where((c) => c == 'query').length, 1);
      expect(calls, isNot(contains('cancel')));
      result.complete(response([row('스쿼트', 'max')]));
      await Future<void>.delayed(Duration.zero);
      expect(search.plan?.requests.single.exercise, '스쿼트');
      search.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );

  test(
    'cached intents recompute current records and expire with date or index',
    () async {
      const channel = MethodChannel('test/query_cached');
      var calls = 0;
      var now = DateTime(2026, 9, 9);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'status') return 'available';
            if (call.method == 'cancel' || call.method == 'warmQuery') {
              return null;
            }
            calls++;
            return response([row('스쿼트', 'max')]);
          });
      final search = RecordSearch(
        const LocalAi(channel: channel, nativeSupported: true),
        now: () => now,
      );
      await search.refresh('ko');
      search.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
      await Future<void>.delayed(Duration.zero);
      expect(
        executeConfirmedPlan(search.plan!, notes, l, 'kg').single.numericValue,
        110,
      );
      search.search('', 'ko', names, 'kg');
      final updated = [
        ...notes,
        note(9, 9, '스쿼트', [LoggedSet(value: 120, reps: 3)]),
      ];
      search.search('스쿼트 최고', 'ko', names, 'kg', notes: updated);
      expect(search.busy, isFalse);
      expect(calls, 1);
      expect(
        executeConfirmedPlan(
          search.plan!,
          updated,
          l,
          'kg',
        ).single.numericValue,
        120,
      );
      now = DateTime(2026, 9, 10);
      search.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);
      search.search('스쿼트 최고', 'ko', [...names, '덤벨컬'], 'kg', immediately: true);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 3);
      search.search('스쿼트 최고', 'ko', [...names, '덤벨컬'], 'lb', immediately: true);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 4);
      search.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );

  test(
    'compact intents retain counts, ranking, periods and filter direction',
    () {
      final plan = RecordQueryPlan.decode({
        'action': 'setCount',
        'exercises': ['스쿼트'],
        'periods': ['all'],
        'weight': {'relation': 'atMost', 'value': 60, 'unit': 'kg'},
      }, names);
      expect(plan.requests.single.minWeight, isNull);
      expect(plan.requests.single.maxWeight, 60);
      expect(plan.requests.single.since, isNull);
      expect(recordRequestScope(plan.requests.single, l), contains('≤ 60kg'));
      expect(
        recordRequestScope(plan.requests.single, l),
        contains(l.queryAllTime),
      );
      final reps = RecordQueryPlan.decode(
        {
          'action': 'repCount',
          'exercises': ['푸시업'],
          'periods': ['recent'],
          'days': 14,
        },
        names,
        today: DateTime(2026, 9, 9),
      );
      expect(reps.requests.single.metric.name, 'reps');
      expect(reps.requests.single.since, DateTime(2026, 8, 27));
      final rank = RecordQueryPlan.decode({
        'action': 'trainingDays',
        'exercises': [],
        'periods': ['all'],
        'top': 3,
      }, names);
      expect(rank.rank, isTrue);
      expect(rank.limit, 3);
      final comparison = RecordQueryPlan.decode(
        {
          'action': 'heaviest',
          'exercises': ['스쿼트'],
          'periods': ['lastMonth', 'thisMonth'],
        },
        names,
        today: DateTime(2026, 9, 9),
      );
      expect(comparison.compare, isTrue);
      expect(comparison.requests.first.until, DateTime(2026, 8, 31));
    },
  );

  test('ranking is a distinct operation from counting workout days', () {
    final total = RecordQueryPlan.decode(
      {
        'action': 'trainingDays',
        'exercises': [],
        'periods': ['thisYear'],
      },
      names,
      today: DateTime(2026, 9, 9),
    );
    final ranked = RecordQueryPlan.decode(
      {
        'action': 'rankExercises',
        'metric': 'trainingDays',
        'limit': 2,
        'exercises': [],
        'periods': ['thisYear'],
      },
      names,
      today: DateTime(2026, 9, 9),
    );
    expect(total.rank, isFalse);
    expect(total.requests.single.exercise, '*');
    expect(ranked.rank, isTrue);
    expect(ranked.limit, 2);
    expect(total.requests.single.since, ranked.requests.single.since);
    expect(
      () => RecordQueryPlan.decode({
        'action': 'rankExercises',
        'metric': 'readRecords',
        'exercises': [],
      }, names),
      throwsFormatException,
    );
  });

  test('mathematical filter operators preserve bounds and units', () {
    for (final unit in ['kg', 'lb']) {
      for (final op in ['>=', '<=', '=']) {
        final r = RecordQueryPlan.decode({
          'action': 'setCount',
          'exercises': ['스쿼트'],
          'periods': ['all'],
          'weight': {'operator': op, 'value': 100, 'unit': unit},
        }, names).requests.single;
        expect(r.minWeight, op == '<=' ? null : 100);
        expect(r.maxWeight, op == '>=' ? null : 100);
        expect(r.weightUnit, unit);
      }
    }
    for (final filter in [
      {'operator': '>=', 'relation': 'atMost', 'value': 100},
      {'operator': 'approximately', 'value': 100},
    ]) {
      expect(
        () => RecordQueryPlan.decode({
          'action': 'setCount',
          'exercises': ['스쿼트'],
          'weight': filter,
        }, names),
        throwsFormatException,
      );
    }
  });

  test('compact intents cannot invent names, operators or filter values', () {
    for (final change in [
      {
        'exercises': ['invented'],
      },
      {
        'weight': {'relation': 'roughly', 'value': 60},
      },
      {
        'weight': {'relation': 'atLeast', 'value': -20},
      },
      {
        'periods': ['future'],
      },
      {'top': 100},
    ]) {
      expect(
        () => RecordQueryPlan.decode({
          'action': 'heaviest',
          'exercises': ['스쿼트'],
          'periods': ['all'],
          ...change,
        }, names),
        throwsFormatException,
      );
    }
    final unrelated = RecordQueryPlan.decode({'action': 'unrelated'}, names);
    expect(unrelated.reason, 'unrelated');
    final notesPlan = RecordQueryPlan.decode({
      'action': 'readRecords',
      'exercises': [],
      'periods': ['all'],
      'terms': ['무릎'],
    }, names);
    expect(notesPlan.kind, 'insight');
  });

  test('late model results cannot replace a newer question', () async {
    const channel = MethodChannel('test/query_race');
    final first = Completer<Object?>();
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'status') return 'available';
          if (call.method == 'cancel' || call.method == 'warmQuery') {
            return null;
          }
          calls++;
          return calls == 1 ? first.future : response([row('푸시업', 'reps')]);
        });
    final search = RecordSearch(
      const LocalAi(channel: channel, nativeSupported: true),
    );
    await search.refresh('ko');
    search.search('스쿼트 얼마', 'ko', names, 'kg', immediately: true);
    await Future<void>.delayed(Duration.zero);
    search.search('푸시업 몇 개', 'ko', names, 'kg', immediately: true);
    first.complete(response([row('스쿼트', 'max')]));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(search.plan!.requests.single.exercise, '푸시업');
    search.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
