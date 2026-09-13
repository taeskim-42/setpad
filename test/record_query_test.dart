import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/query_cache.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/stats.dart' show Answer;

import 'package:setpad/record_ai.dart';
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
      final received = <String>[];
      Future<Object?> reply(String instructions, String input) async {
        final prompt = jsonDecode(input) as Map;
        received.add(prompt['question'] as String);
        expect(prompt['referenceYear'], 2026);
        expect(prompt.containsKey('today'), isFalse);
        expect(prompt.containsKey('records'), isFalse);
        return response([row('스쿼트', 'max')]);
      }

      final ai = RecordAi(respond: reply);
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
      final result = Completer<Object?>();
      final calls = <String>[];
      Future<Object?> reply(String instructions, String input) async {
        calls.add('query');
        return result.future;
      }

      final search = RecordSearch(RecordAi(respond: reply));
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
    },
  );

  test('해석은 기기에 남고, 날짜는 꺼낼 때 다시 푼다', () async {
    var calls = 0;
    var now = DateTime(2026, 9, 9);
    Future<Object?> reply(String instructions, String input) async {
      calls++;
      return {
        ...response([row('스쿼트', 'max')]),
        'queries': [
          {...row('스쿼트', 'max'), 'period': 'lastWeek'},
        ],
      };
    }

    final dir = Directory.systemTemp.createTempSync('setpad_cache');
    addTearDown(() => dir.deleteSync(recursive: true));
    final search = RecordSearch(
      RecordAi(respond: reply),
      now: () => now,
      cache: QueryCache(directory: dir),
    );
    await search.refresh('ko');
    search.search('지난주 스쿼트 최고', 'ko', names, 'kg', immediately: true);
    await Future<void>.delayed(Duration.zero);
    final first = search.plan!.requests.single.since;

    // 같은 질문을 다음 주에 다시 묻는다. 모델은 부르지 않지만 기간은 옮겨간다.
    now = DateTime(2026, 9, 16);
    search.search('', 'ko', names, 'kg');
    search.search('지난주 스쿼트 최고', 'ko', names, 'kg', immediately: true);
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1, reason: '두 번째는 저장해 둔 해석을 쓴다');
    expect(
      search.plan!.requests.single.since,
      first!.add(const Duration(days: 7)),
      reason: '"지난주" 는 묻는 날에 따라 다른 주다',
    );

    // 운동 목록이나 단위가 달라지면 뜻이 달라질 수 있어 다시 묻는다.
    search.search(
      '지난주 스쿼트 최고',
      'ko',
      [...names, '덤벨컬'],
      'kg',
      immediately: true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(calls, 2);
    search.search(
      '지난주 스쿼트 최고',
      'ko',
      [...names, '덤벨컬'],
      'lb',
      immediately: true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(calls, 3);
    search.dispose();
  });

  test('앱을 껐다 켜도 저장해 둔 해석을 쓴다', () async {
    var calls = 0;
    Future<Object?> reply(String instructions, String input) async {
      calls++;
      return response([row('스쿼트', 'max')]);
    }

    final dir = Directory.systemTemp.createTempSync('setpad_cache');
    addTearDown(() => dir.deleteSync(recursive: true));
    final now = DateTime(2026, 9, 9);
    final first = RecordSearch(
      RecordAi(respond: reply),
      now: () => now,
      cache: QueryCache(directory: dir),
    );
    await first.refresh('ko');
    first.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    first.dispose();
    // dispose 가 마지막 쓰기를 흘려보낸다.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final second = RecordSearch(
      RecordAi(respond: reply),
      now: () => now,
      cache: QueryCache(directory: dir),
    );
    await second.refresh('ko');
    second.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1, reason: '새로 켠 앱도 파일에서 읽는다');
    expect(second.plan!.requests.single.exercise, '스쿼트');
    second.dispose();
  });

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
    final first = Completer<Object?>();
    var calls = 0;
    Future<Object?> reply(String instructions, String input) async {
      calls++;
      return calls == 1 ? first.future : response([row('푸시업', 'reps')]);
    }

    final search = RecordSearch(RecordAi(respond: reply));
    await search.refresh('ko');
    search.search('스쿼트 얼마', 'ko', names, 'kg', immediately: true);
    await Future<void>.delayed(Duration.zero);
    search.search('푸시업 몇 개', 'ko', names, 'kg', immediately: true);
    first.complete(response([row('스쿼트', 'max')]));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(search.plan!.requests.single.exercise, '푸시업');
    search.dispose();
  });
}
