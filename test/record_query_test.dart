import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/local_ai.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';

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
      final a = executeRecordPlan(plan, notes, l, 'kg').single;
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
      expect(executeRecordPlan(reps, notes, l, 'kg').single.numericValue, 35);
      final sets = RecordQueryPlan.decode(
        response([
          {...row('벤치프레스', 'sets'), 'minWeight': 80},
        ]),
        names,
      );
      expect(executeRecordPlan(sets, notes, l, 'kg').single.numericValue, 1);
      final days = RecordQueryPlan.decode(
        response([row('*', 'sessions')]),
        names,
      );
      expect(executeRecordPlan(days, notes, l, 'kg').single.numericValue, 4);
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
    expect(executeRecordPlan(plan, notes, l, 'lb').single.numericValue, 1);
  });

  test('the most recent bodyweight session is answerable without weights', () {
    final plan = RecordQueryPlan.decode(response([row('푸시업', 'last')]), names);
    expect(executeRecordPlan(plan, notes, l, 'kg').single.headline, '20회  15회');
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
            expect(prompt['today'], '2026-09-08');
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
          executeRecordPlan(plan, notes, l, 'kg').single.numericValue,
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
      final ranked = executeRecordPlan(plan, notes, l, 'kg');
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
      expect(executeRecordPlan(plan, notes, l, 'kg'), isEmpty);
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
    'arbitrary relevant requests go through evidence-based generation',
    () async {
      const channel = MethodChannel('test/query_open');
      final methods = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'status') return 'available';
            if (call.method == 'cancel') return null;
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
      expect(methods, ['query', 'answerRecords']);
      expect(search.reply?.hasEvidence, isTrue);
      expect(search.failed, isFalse);
      search.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
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
      final a = executeRecordPlan(plan, data, l, 'kg').single;
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
    expect(executeRecordPlan(plan, notes, l, 'kg').single.exercise, '스쿼트');
    final unrelated = RecordQueryPlan.decode({
      'kind': 'unsupported',
      'reason': 'unrelated',
    }, names);
    expect(unrelated.requests, isEmpty);
  });

  test('late model results cannot replace a newer question', () async {
    const channel = MethodChannel('test/query_race');
    final first = Completer<Object?>();
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'status') return 'available';
          if (call.method == 'cancel') return null;
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
