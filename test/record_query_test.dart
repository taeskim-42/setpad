import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/query_cache.dart';
import 'package:setpad/quantities.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/stats.dart';

import 'package:setpad/record_ai.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/exercises.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';

/// 디코더와 규칙 층. 모델 출력은 코드로 실행되지 않고 검증만 거친다 — 검증이
/// 너무 엄하면 답할 수 있던 질문이 "해석 실패"로 죽고, 너무 느슨하면 틀린
/// 답이 조용히 나간다. 여기서는 그 경계를 못 박는다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting());
  const names = ['스쿼트', '벤치프레스', '데드리프트', '바벨로우', '푸시업', '랫풀다운'];
  final today = DateTime(2026, 9, 23);
  final l = lookupL(const Locale('ko'));
  RecordQuery decode(
    Map<String, Object?> raw, {
    String question = '',
    DateTime? on,
    String unit = 'kg',
  }) => RecordQuery.decode(
    raw,
    names,
    question: question,
    today: on ?? today,
    unit: unit,
  );
  Note note(String id, DateTime at, List<ExerciseBlock> blocks) =>
      Note(id: id, createdAt: at, updatedAt: at, blocks: blocks);
  Answer? single(RecordQuery q, List<Note> notes, {String unit = 'kg'}) =>
      runQuery(
        q,
        notes,
        l: l,
        unit: unit,
        today: today,
        confirmed: true,
      )!.rows.single.cells.single.answer;

  group('B. 디코더', () {
    test('모르는 키·단위, 뒤집힌 범위, 없는 날, 말이 안 되는 조합은 거절한다', () {
      for (final raw in <Map<String, Object?>>[
        {'foo': 1},
        {
          'exercises': ['스쿼트'],
          'weight': {'op': '>=', 'value': 100, 'unit': 'st'},
        },
        {
          'exercises': ['스쿼트'],
          'weight': [
            {'op': '>=', 'value': 100},
            {'op': '<=', 'value': 80},
          ],
        },
        {'period': 'custom', 'since': '2026-02-30'},
        {'period': 'recent', 'days': 0},
        {'period': 'future'},
        {'days': 14, 'period': 'lastMonth'},
        {
          'measures': ['trainingDays'],
          'order': 'desc',
        },
        {
          'by': 'week',
          'measures': ['latest'],
        },
        {
          'by': 'week',
          'measures': ['volume', 'setCount'],
        },
        {
          'measures': ['sql'],
        },
        {
          'measures': ['best', 'best'],
        },
        // 같은 series 둘 — 모델이 구분 키를 흘렸다.
        {
          'series': [
            {'period': 'lastMonth'},
            {'period': 'lastMonth'},
          ],
        },
        // v2 의 compare 는 지웠다.
        {
          'by': 'exercise',
          'compare': [
            {'period': 'lastMonth'},
            {'period': 'thisMonth'},
          ],
        },
        // series 항목 안의 plan 키(항목마다 똑같지 않으면 올려 주지 않는다).
        {
          'series': [
            {'period': 'lastMonth', 'by': 'day'},
            {'period': 'thisMonth'},
          ],
        },
        {'series': []},
        {
          'series': [
            for (var i = 1; i <= 7; i++) {'sessions': i},
          ],
        },
        {
          'per': 'day',
          'measures': ['best'],
        },
        {
          'relate': 'share',
          'by': 'exercise',
          'measures': ['best'],
        },
        {
          'hours': {'from': 5, 'to': 5},
        },
        {
          'period': 'all',
          'shift': {'years': 1},
        },
        {
          'period': 'thisYear',
          'shift': {'years': 11},
        },
        {
          'period': 'thisYear',
          'shift': {'years': 1, 'days': 2},
        },
        {
          'memo': ['x' * 30],
          'noMemo': ['y' * 30],
          'exercises': ['z' * 2000],
        },
        {
          'trained': false,
          'measures': ['setCount'],
        },
        {
          'hours': {'from': 5, 'to': 11},
          'measures': ['intake'],
        },
        {
          'by': 'exercise',
          'measures': ['burned'],
        },
        {
          'by': 'week',
          'measures': ['best', 'volume'],
          'series': [
            {'period': 'lastMonth'},
            {'period': 'thisMonth'},
          ],
        },
        {
          'by': 'week',
          'measures': ['longestStreak'],
        },
        {
          'exercises': ['스쿼트'],
          'sessions': 2,
          'nth': 1,
        },
        {'memoAll': true},
        {
          'exercises': ['스쿼트'],
          'against': {'value': -1},
        },
        {
          'exercises': ['스쿼트'],
          'against': {'value': 80, 'unit': 'st'},
        },
        {
          'kind': 'missing',
          'exercises': ['케틀벨 스윙'],
        },
        {
          'exercises': ['스쿼트'],
          'together': 'yes',
        },
        {'part': 'neck'},
        {'timer': 'stopwatch'},
        {'set': 'middle'},
        {
          'per': 'year',
          'measures': ['setCount'],
        },
        {
          'exercises': ['스쿼트', '벤치프레스'],
          'measures': ['latest'],
          'total': 'sum',
        },
        {
          'exercises': ['스쿼트'],
          'reps': {'op': '>=', 'value': 5, 'unit': 'kg'},
        },
        {
          'exercises': ['스쿼트'],
          'weight': {'op': 'approximately', 'value': 100},
        },
        {
          'exercises': ['스쿼트'],
          'weight': {'operator': '>=', 'value': 100},
        },
        {
          'exercises': ['스쿼트'],
          'weight': {'op': '>=', 'value': -20},
        },
        {'kind': 'sql'},
        {'kind': 'find'},
      ]) {
        expect(() => decode(raw), throwsFormatException, reason: '$raw');
      }
    });

    test('C·셀 수 없는 조합·한도는 무엇에 걸렸는지 말하고, 모델의 모양 실수와 가른다', () {
      const many = [
        '스쿼트',
        '벤치프레스',
        '데드리프트',
        '바벨로우',
        '푸시업',
        '랫풀다운',
        '레그프레스',
        '오버헤드프레스',
        '풀업',
      ];
      String? limit(Map<String, Object?> raw, [List<String> list = names]) {
        try {
          RecordQuery.decode(raw, list, today: today);
          return null;
        } on QueryLimit catch (e) {
          return e.kind;
        } on FormatException {
          return 'mistake';
        }
      }

      final periods = [
        for (final p in [
          'lastYear',
          'thisYear',
          'lastMonth',
          'thisMonth',
          'lastWeek',
        ])
          {'period': p},
      ];
      for (final (raw, kind) in <(Map<String, Object?>, String?)>[
        ({'exercises': many}, 'exercises'),
        ({'exclude': many, 'by': 'exercise'}, 'exercises'),
        (
          {
            'measures': ['best', 'volume', 'setCount', 'repCount'],
          },
          'measures',
        ),
        (
          {
            'by': 'exercise',
            'measures': ['best'],
            'order': 'desc',
            'limit': 30,
          },
          'ranking',
        ),
        (
          {
            'exercises': ['스쿼트'],
            'sessions': 150,
          },
          'sessions',
        ),
        (
          {
            'exercises': ['스쿼트'],
            'period': 'recent',
            'days': 7300,
          },
          'days',
        ),
        (
          {
            'measures': ['volume'],
            'series': [
              ...periods,
              {'period': 'today'},
              {'period': 'yesterday'},
            ],
          },
          'compare',
        ),
        (
          {
            'by': 'week',
            'measures': ['setCount'],
            'per': 'week',
          },
          'per',
        ),
        (
          {
            'by': 'exercise',
            'measures': ['intake'],
          },
          'energyGrouped',
        ),
        (
          {
            'by': 'week',
            'measures': ['volume', 'setCount'],
          },
          'groupedMeasure',
        ),
        (
          {
            'by': 'week',
            'measures': ['latest'],
          },
          'groupedMeasure',
        ),
        (
          {
            'measures': ['trainingDays'],
            'order': 'desc',
          },
          'ordering',
        ),
        (
          {
            'exercises': ['스쿼트', '벤치프레스'],
            'measures': ['latest'],
            'total': 'sum',
          },
          'datesTotal',
        ),
        // 모델의 모양 실수 — 다시 물으면 풀릴 수 있다. 한도가 아니다.
        (
          {
            'exercises': ['스쿼트'],
            'foo': 1,
          },
          'mistake',
        ),
        ({'kind': 'sql'}, 'mistake'),
        ({'period': 'custom', 'since': '2026-02-30'}, 'mistake'),
        (
          {
            'measures': ['sql'],
          },
          'mistake',
        ),
        (
          {
            'exercises': ['스쿼트'],
            'sessions': 0,
          },
          'mistake',
        ),
        (
          {
            'compare': [
              {'period': 'lastMonth'},
            ],
          },
          'mistake',
        ),
        ({'series': []}, 'mistake'),
      ]) {
        expect(limit(raw, many), kind, reason: '$raw');
      }
      // 규칙 1: 윗단의 여러 이름은 한 줄씩이다 — by: exercise 를 적었어도.
      final five = RecordQuery.decode(
        {
          'measures': ['best'],
          'by': 'exercise',
          'exercises': many.take(5).toList(),
        },
        many,
        today: today,
      );
      expect(five.series, hasLength(5));
      expect(five.by, isNull);
      expect([
        for (final s in five.series) s.scope.exercises.single,
      ], many.take(5));
      // 모든 한도는 제 까닭 문구가 있다.
      for (final kind in [
        'exercises',
        'measures',
        'ranking',
        'sessions',
        'days',
        'compare',
        'groupedMeasure',
        'ordering',
        'datesTotal',
      ]) {
        expect(l.queryLimit(kind), isNot(l.queryLimit('other')), reason: kind);
      }
    });

    test('못 푸는 것과 무관한 것은 거절이 아니라 까닭이다', () {
      final blank = decode({});
      expect((blank.kind, blank.reason), ('unsupported', 'ambiguous'));
      final unrelated = decode({
        'kind': 'unrelated',
        'exercises': ['x'],
      });
      expect((unrelated.kind, unrelated.reason), ('unsupported', 'unrelated'));
      // 기록에 없는 운동도 줄이 된다 — 질문 전체를 거절하지 않는다(v2 의 missing).
      final missing = decode({
        'exercises': ['요가'],
      });
      expect((missing.kind, missing.reason), ('query', ''));
      expect(missing.never, {'요가'});
      expect(missing.scope.exercises, ['요가']);
      // 셀 것 없이 못 보는 것만 있으면 '셀 것이 없음' 이다 — 까닭을 말한다.
      final heart = decode({
        'notComputable': ['심박'],
      });
      expect((heart.kind, heart.reason), ('unsupported', 'nothing'));
      expect(heart.notComputable, ['심박']);
      expect(refusalLines(heart, l), [
        l.queryNcHeartRate,
        l.queryNothingComputable('심박'),
        l.queryCanSee,
      ]);
      expect(
        decode({'kind': 'clarify'}).reason,
        'ambiguous',
        reason: '"80kg 이상 또는 10회 이상"',
      );
    });

    test('모델이 사용자 철자를 그대로 돌려줘도 목록의 이름으로 맞추고 남긴다', () {
      final q = decode({
        'exercises': ['스쾃'],
      });
      expect(q.scope.exercises, ['스쿼트']);
      expect(q.readAs, {'스쿼트': '스쾃'});
      final find = decode({
        'kind': 'find',
        'exercises': ['벤치'],
      });
      expect(find.kind, 'find');
      expect(find.scope.exercises, ['벤치프레스']);
      expect(find.requiresConfirmation, isFalse);
    });

    test('정규화: 기본 측정, 운동만 다른 series, 운동 둘, 순위의 최고', () {
      final plain = decode({
        'exercises': ['스쿼트'],
      });
      expect(plain.measures, RecordQuery.defaultMeasures);
      expect(plain.requiresConfirmation, isTrue);
      // 운동만 다른 series 는 그대로 series 둘이다(v2 처럼 운동별로 접지 않는다).
      final pair = decode({
        'measures': ['best'],
        'series': [
          {
            'exercises': ['벤치프레스'],
          },
          {
            'exercises': ['바벨로우'],
          },
        ],
      });
      expect(pair.series.map((s) => s.scope.exercises.single), [
        '벤치프레스',
        '바벨로우',
      ]);
      expect(pair.by, isNull);
      final two = decode({
        'exercises': ['벤치프레스', '바벨로우'],
      });
      expect((two.series.length, two.by), (2, null));
      expect(two.measures, RecordQuery.defaultMeasures);
      final ranked = decode({
        'by': 'exercise',
        'measures': ['best'],
        'order': 'desc',
      });
      expect(ranked.measures, [Metric.max]);
      // 규칙 2: 이름 × series 는 표 — 줄은 운동, 칸은 series(측정 하나, 기본 최고).
      final table = decode({
        'exercises': ['벤치프레스', '스쿼트'],
        'series': [
          {'period': 'lastMonth'},
          {'period': 'thisMonth'},
        ],
      });
      expect((table.by, table.series.length), ('exercise', 2));
      expect(table.series.map((s) => s.measures), [
        [Metric.best],
        [Metric.best],
      ]);
      // 규칙 3: series 안의 여러 이름은 합친다.
      final pooled = decode({
        'series': [
          {
            'exercises': ['벤치프레스', '푸시업'],
          },
          {
            'exercises': ['랫풀다운'],
          },
        ],
        'measures': ['setCount'],
      });
      expect(pooled.series.first.scope.exercises, ['벤치프레스', '푸시업']);
    });
    test('고침: kind 를 type 이라고 적은 것 — 값이 kind 일 때만', () {
      expect(decode({'type': 'clarify'}).reason, 'ambiguous');
      final q = decode({
        'type': 'query',
        'exercises': ['스쿼트'],
      });
      expect(q.kind, 'query');
      expect(q.scope.exercises, ['스쿼트']);
      for (final raw in <Map<String, Object?>>[
        {
          'type': 'sum',
          'exercises': ['스쿼트'],
        },
        {'kind': 'query', 'type': 'clarify'},
      ]) {
        expect(() => decode(raw), throwsFormatException, reason: '$raw');
      }
    });

    test('고침: 응답 형식을 되받아 적고 한 겹 감싼 것 — 감싼 것이 하나일 때만', () {
      for (final wrap in ['content', 'value']) {
        final q = decode({
          'type': 'json_object',
          wrap: {
            'exercises': ['데드리프트'],
            'period': 'today',
            'measures': ['meanWeight'],
          },
        });
        expect(q.scope.exercises, ['데드리프트'], reason: wrap);
      }
      // 빈 껍데기를 전체 기록 질의로 읽으면 자신 있게 틀린다 — 거절한다.
      for (final raw in <Map<String, Object?>>[
        {'type': 'json_object'},
        {
          'type': 'json_object',
          'a': {'period': 'today'},
          'b': {'period': 'today'},
        },
      ]) {
        expect(() => decode(raw), throwsFormatException, reason: '$raw');
      }
    });

    test('고침: series 항목마다 똑같이 적은 plan 키는 plan 의 것이다', () {
      final raw = {
        'measures': ['trainingDays'],
        'series': [
          {'period': 'lastYear', 'per': 'week'},
          {'period': 'thisYear', 'per': 'week'},
        ],
      };
      final q = decode(raw);
      expect(q.per, 'week');
      expect(q.series.map((s) => s.scope.since?.year), [2025, 2026]);
      expect(
        ((raw['series'] as List).first as Map).keys,
        contains('per'),
        reason: '들어온 대답은 그대로 — 캐시가 다시 푼다',
      );
      // 측정은 series 키다 — 항목마다 달라도 된다(데드는 1RM, 레그프레스는 세트 수).
      final each = decode({
        'series': [
          {
            'exercises': ['데드리프트'],
            'measures': ['e1rm'],
          },
          {
            'exercises': ['스쿼트'],
            'measures': ['setCount'],
          },
        ],
      });
      expect(each.series.map((s) => s.measures.single), [
        Metric.e1rm,
        Metric.sets,
      ]);
      expect(each.measures, [Metric.e1rm, Metric.sets]);
      // plan 키가 항목마다 다르거나 위와 어긋나면 한 plan 으로 못 쓴다.
      for (final raw in <Map<String, Object?>>[
        {
          'measures': ['trainingDays'],
          'series': [
            {'period': 'lastYear', 'per': 'week'},
            {'period': 'thisYear', 'per': 'month'},
          ],
        },
        {
          'measures': ['trainingDays'],
          'per': 'month',
          'series': [
            {'period': 'lastYear', 'per': 'week'},
            {'period': 'thisYear', 'per': 'week'},
          ],
        },
      ]) {
        expect(() => decode(raw), throwsFormatException, reason: '$raw');
      }
    });
    test('고침: 묶음 없는 한 줄의 합계와 1등은 그 칸 자신이다', () {
      final sum = decode({
        'exercises': ['스쿼트'],
        'period': 'thisMonth',
        'measures': ['repCount'],
        'total': 'sum',
      });
      expect((sum.total, sum.by), (null, null));
      expect(sum.measures, [Metric.reps]);
      expect(
        decode({
          'measures': ['volume', 'setCount'],
          'total': 'sum',
        }).total,
        isNull,
      );
      final top = decode({
        'exercises': ['스쿼트'],
        'measures': ['best'],
        'order': 'desc',
        'limit': 1,
      });
      expect((top.order, top.limit), (null, null));
      expect(top.measures, [Metric.best]);
      // 평균은 주당인지 달당인지, 여러 줄 순위와 운동 없는 순위는 무엇으로
      // 묶는지 모른다. 더해지지 않는 측정의 합계도 모른다.
      for (final raw in <Map<String, Object?>>[
        {
          'measures': ['trainingDays'],
          'total': 'mean',
        },
        {
          'measures': ['best'],
          'total': 'sum',
        },
        {
          'exercises': ['스쿼트'],
          'measures': ['best'],
          'order': 'desc',
          'limit': 3,
        },
        {
          'measures': ['trainingDays'],
          'order': 'desc',
          'limit': 1,
        },
      ]) {
        expect(() => decode(raw), throwsFormatException, reason: '$raw');
      }
    });

    test('범위 조건: 둘은 범위, 단위를 안 적으면 사용자 단위', () {
      final q = decode({
        'exercises': ['벤치프레스'],
        'weight': [
          {'op': '>', 'value': 60},
          {'op': '<', 'value': 80},
        ],
        'measures': ['setCount'],
      }, unit: 'lb');
      expect(q.scope.weight.map((b) => '$b'), ['>60.0lb', '<80.0lb']);
    });
  });

  group('C. 규칙 층', () {
    test('비교하는 말이 있으면 모델의 두 기간을 둔다 — 지난달보다 스쿼트 늘었어?', () {
      final q = decode({
        'exercises': ['스쿼트'],
        'measures': ['best'],
        'series': [
          {'period': 'lastMonth'},
          {'period': 'thisMonth'},
        ],
      }, question: '지난달보다 스쿼트 늘었어?');
      expect(q.series, hasLength(2));
      expect(q.series.first.scope.since, DateTime(2026, 8, 1));
      expect(q.series.last.scope.since, DateTime(2026, 9, 1));
    });

    test('글에 기간이 하나면 모델의 비교 기간 둘은 접는다', () {
      final q = decode(
        {
          'exercises': ['벤치프레스'],
          'measures': ['weightChange'],
          'series': [
            {'period': 'lastMonth'},
            {'period': 'thisMonth'},
          ],
        },
        question: '이번 달 벤치 무게 변화',
        on: DateTime(2026, 9, 9),
      );
      expect(q.series, hasLength(1));
      expect(q.scope.since, DateTime(2026, 9, 1));
      expect(q.measures, [Metric.trend]);
    });

    test('두 달을 이름으로 견주면 모델의 비교를 둔다', () {
      final q = decode(
        {
          'exercises': ['스쿼트'],
          'measures': ['best'],
          'series': [
            {'period': 'lastMonth'},
            {'period': 'thisMonth'},
          ],
        },
        question: '1월과 2월 스쿼트 최고 비교',
        on: DateTime(2031, 2, 10),
      );
      expect(q.series.map((s) => s.scope.since), [
        DateTime(2031, 1),
        DateTime(2031, 2),
      ]);
    });

    test('새 측정은 덮지 않는다 — 벤치 1RM 추이', () {
      final q = decode({
        'exercises': ['벤치프레스'],
        'measures': ['e1rm'],
      }, question: '벤치 1RM 추이');
      expect(q.measures, [Metric.e1rm]);
    });

    test('PR 은 최고다 — 모델이 운동일수 순위로 읽어도 바로잡는다', () {
      final q = decode({
        // 실제 모델 출력 그대로: "스쿼트 PR" → 운동일수 순위.
        'exercises': ['스쿼트'],
        'by': 'exercise',
        'measures': ['trainingDays'],
        'limit': 1,
      }, question: '스쿼트 PR');
      expect((q.by, q.limit), (null, null));
      expect(q.scope.exercises, ['스쿼트']);
      expect(q.measures, [Metric.best]);
    });

    test('글에 적힌 숫자 조건이 모델보다 앞선다', () {
      final both = decode({
        'exercises': ['벤치프레스'],
        'weight': {'op': '>=', 'value': 80, 'unit': 'kg'},
        'measures': ['setCount'],
      }, question: '벤치 80kg 이상 5회 이상 세트 수');
      expect(both.scope.weight.map((b) => '$b'), ['>=80.0kg']);
      expect(both.scope.reps.map((b) => '$b'), ['>=5.0']);
      final repsOnly = decode({
        'exercises': ['벤치프레스'],
        'weight': {'op': '>=', 'value': 5, 'unit': 'kg'},
        'measures': ['setCount'],
      }, question: '벤치 5회 이상 세트 수');
      expect(repsOnly.scope.weight, isEmpty);
      expect(repsOnly.scope.reps.map((b) => '$b'), ['>=5.0']);
    });

    test('메모 낱말 없이 낸 메모 조건은 지운다 — 벤치 최고', () {
      final q = decode({
        'exercises': ['벤치프레스'],
        'memo': ['최고'],
        'measures': ['best'],
      }, question: '벤치 최고');
      expect(q.scope.memo, isEmpty);
    });

    test('어제는 어제다', () {
      final q = decode({
        'exercises': ['벤치프레스'],
      }, question: '어제 벤치');
      expect(
        (q.scope.since, q.scope.until),
        (DateTime(2026, 9, 22), DateTime(2026, 9, 22)),
      );
      expect(statedPeriod('yesterday bench')?.period, 'yesterday');
    });
  });

  group('D. v1 에서 옮긴 것', () {
    test('확인 전에는 답하지 않는다', () {
      final q = decode({
        'exercises': ['스쿼트'],
        'measures': ['setCount'],
      }, question: '스쿼트 몇 세트?');
      final notes = [
        note('one', today, [
          ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
        ]),
      ];
      expect(q.requiresConfirmation, isTrue);
      expect(runQuery(q, notes, l: l, unit: 'kg', today: today), isNull);
      expect(single(q, notes)!.numericValue, 1);
    });

    test('원래 정밀도를 지키고, 반올림한 값은 표시한다', () {
      final notes = [
        note('precise', today, [
          ExerciseBlock('스쿼트', [LoggedSet(value: 82.125, reps: 5)]),
        ]),
      ];
      for (final measure in ['best', 'latest']) {
        final q = decode({
          'exercises': ['스쿼트'],
          'measures': [measure],
        });
        expect(single(q, notes)!.headline, contains('82.125kg'));
      }
      expect(formatRoundedQuantity(82.125, 'ko'), startsWith('≈'));
      expect(formatRoundedQuantity(80, 'ko'), '80');
      expect(formatRoundedQuantity(1 / 3, 'ko', signed: true), '≈+0.33');
    });

    test('값이 빠진 세트로는 합계를 만들지 않는다 — 맨몸·반복 없는 세트는 빼고 말한다', () {
      final notes = [
        note('incomplete', today, [
          ExerciseBlock('스쿼트', [
            LoggedSet(value: 80, reps: 5),
            LoggedSet(value: 80),
            LoggedSet(reps: 5),
          ]),
        ]),
      ];
      RecordResult run(Map<String, Object?> raw) => runQuery(
        decode(raw),
        notes,
        l: l,
        unit: 'kg',
        today: today,
        confirmed: true,
      )!;
      // 반복을 안 적은 무게 세트가 있으면 볼륨은 모른다.
      final volume = run({
        'exercises': ['스쿼트'],
        'measures': ['volume'],
      });
      expect(volume.rows.single.cells.single.reason, 'unknown');
      expect(volume.footnotes, [l.queryMissingFor('스쿼트')]);
      // 무게 하한("80kg 이상")은 무게 없는 세트가 채우지 못한다 — 맨몸 세트 하나
      // 때문에 개수가 '—' 가 되지 않는다. 뺀 세트는 말한다(v3 재검토 R8).
      final over = run({
        'exercises': ['스쿼트'],
        'weight': {'op': '>=', 'value': 80, 'unit': 'kg'},
        'measures': ['setCount'],
      });
      expect(over.rows.single.cells.single.answer!.numericValue, 2);
      expect(over.footnotes, [l.queryNoWeightSets(1, 5)]);
      // 상한("80kg 이하")은 무게 없는 세트를 판정할 수 없다 — 세지 않고 말한다.
      final under = run({
        'exercises': ['스쿼트'],
        'weight': {'op': '<=', 'value': 80, 'unit': 'kg'},
        'measures': ['setCount'],
      });
      expect(under.rows.single.cells.single.reason, 'unknown');
      expect(under.footnotes, [l.queryMissingFor('스쿼트')]);
      // 맨몸 세트 하나가 무게 칸을 지우지 않는다 — 무게 세트로 세고 뺀 것을 말한다.
      final best = run({
        'exercises': ['스쿼트'],
        'measures': ['best'],
      }).rows.single.cells.single;
      expect(best.answer!.numericValue, 80);
      expect(best.answer!.lines.first, l.queryNoWeightSets(1, 5));
      final mean = run({
        'exercises': ['스쿼트'],
        'measures': ['meanWeight'],
      }).rows.single.cells.single;
      expect(mean.answer!.numericValue, 80);
      // 반복 합은 반복을 적은 세트로 센다(맨몸 5회 포함) — 안 적은 세트는 말한다.
      final reps = run({
        'exercises': ['스쿼트'],
        'measures': ['repCount'],
      }).rows.single.cells.single;
      expect(reps.answer!.numericValue, 10);
      expect(reps.answer!.lines.first, l.queryNoRepsSets(1));
    });
    test('문장 제목도 운동으로 센다 — 반복·세트·날', () {
      final notes = [
        for (var i = 0; i < 2; i++)
          note('$i', today, [
            ExerciseBlock(
              '벤치 80kg 100개 채우기',
              [
                LoggedSet(value: 80, reps: 10),
                LoggedSet(value: 100, reps: 99, done: false),
              ],
              const WorkoutSetup(name: '벤치프레스', weight: 80, totalReps: 100),
            ),
          ]),
      ];
      for (final (measure, count) in [
        ('repCount', 20),
        ('setCount', 2),
        ('trainingDays', 1),
      ]) {
        final q = decode({
          'exercises': ['벤치프레스'],
          'measures': [measure],
        });
        expect(single(q, notes)!.numericValue, count, reason: measure);
      }
    });

    test('kg/lb 같음은 경계를 정확히 포함한다', () {
      final notes = [
        note('units', today, [
          ExerciseBlock('벤치프레스', [
            LoggedSet(value: 100, unit: 'lb', reps: 5),
            LoggedSet(value: 45.359237, unit: 'kg', reps: 5),
            LoggedSet(value: 45.359237001, unit: 'kg', reps: 5),
            LoggedSet(value: 45.359236999, unit: 'kg', reps: 5),
          ]),
        ]),
      ];
      final q = decode({
        'exercises': ['벤치프레스'],
        'weight': {'op': '=', 'value': 45.359237, 'unit': 'kg'},
        'measures': ['setCount'],
      });
      expect(single(q, notes)!.numericValue, 2);
      expect(compareWeights(0.1, 'lb', 0.045359237, 'kg'), 0);
      expect(compareWeights(1e-7, 'lb', 4.5359237e-8, 'kg'), 0);
      expect(compareWeights(45.359237001, 'kg', 100, 'lb'), greaterThan(0));
      expect(compareWeights(45.359236999, 'kg', 100, 'lb'), lessThan(0));
    });

    test('kg 조건과 lb 조건은 각자 제 세트를 고르고, 기록은 그대로다', () {
      final records = [
        note('units', today, [
          ExerciseBlock('벤치프레스', [LoggedSet(value: 90, unit: 'kg', reps: 5)]),
          ExerciseBlock('스쿼트', [LoggedSet(value: 110, unit: 'lb', reps: 5)]),
        ]),
      ];
      final q = decode({
        'measures': ['setCount'],
        'series': [
          {
            'exercises': ['벤치프레스'],
            'weight': {'op': '>=', 'value': 80, 'unit': 'kg'},
          },
          {
            'exercises': ['스쿼트'],
            'weight': {'op': '<=', 'value': 100, 'unit': 'lb'},
          },
        ],
      }, question: '벤치프레스 80kg 이상 세트와 스쿼트 100파운드 이하 세트');
      final cells = [
        for (final r in runQuery(
          q,
          records,
          l: l,
          unit: 'kg',
          today: today,
          confirmed: true,
        )!.rows)
          r.cells.single,
      ];
      expect(cells.first.answer!.numericValue, 1);
      // 세트 수는 개수형 — 이 범위에 없으면 0 과 까닭이다.
      expect((cells.last.reason, cells.last.answer!.numericValue), ('none', 0));
      expect(records.single.blocks.last.sets.single.value, 110);
    });

    test('kg/lb 연산자와 단위를 그대로 지킨다', () {
      for (final unit in ['kg', 'lb']) {
        for (final op in ['>=', '<=', '=', '>', '<']) {
          final q = decode({
            'exercises': ['스쿼트'],
            'weight': {'op': op, 'value': 100, 'unit': unit},
            'measures': ['setCount'],
          });
          expect(q.scope.weight.map((b) => '$b'), ['${op}100.0$unit']);
        }
      }
    });

    test('달력: 윤일과 해 바뀜, 자정', () {
      for (final (clock, period, days, since, until) in [
        (
          DateTime(2028, 3, 1),
          'lastMonth',
          null,
          DateTime(2028, 2, 1),
          DateTime(2028, 2, 29),
        ),
        (
          DateTime(2024, 3, 8),
          'thisMonth',
          null,
          DateTime(2024, 3, 1),
          DateTime(2024, 3, 8),
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
        (
          DateTime(2027, 1, 1, 23),
          'yesterday',
          null,
          DateTime(2026, 12, 31),
          DateTime(2026, 12, 31),
        ),
      ]) {
        final p = resolvePeriod(period, days: days, today: clock);
        expect((p.since, p.until), (since, until), reason: period);
        expect(p.since!.hour, 0);
      }
      final q = decode({
        'exercises': ['스쿼트'],
        'measures': ['best'],
        'series': [
          {'period': 'lastMonth'},
          {'period': 'thisMonth'},
        ],
      }, on: DateTime(2024, 3, 8));
      expect(q.series.first.scope.until, DateTime(2024, 2, 29));
    });

    test('글의 기간이 모델의 기간보다 앞선다', () {
      final on = DateTime(2026, 9, 9);
      for (final (text, since, until) in [
        ('지난주', DateTime(2026, 8, 31), DateTime(2026, 9, 6)),
        ('이번 주', DateTime(2026, 9, 7), on),
        ('지난달', DateTime(2026, 8, 1), DateTime(2026, 8, 31)),
        ('최근 2주', DateTime(2026, 8, 27), on),
      ]) {
        final q = decode(
          {
            'exercises': ['랫풀다운'],
            'period': 'recent',
            'days': 28,
            'measures': ['volume'],
          },
          question: '$text 랫풀다운 볼륨?',
          on: on,
        );
        expect((q.scope.since, q.scope.until), (since, until), reason: text);
      }
      // 모델이 기간을 빠뜨려도 글이 채운다.
      final q = decode(
        {
          'exercises': ['스쿼트'],
          'measures': ['best'],
        },
        question: '이번 주 스쿼트 최고',
        on: on,
      );
      expect(q.scope.since, DateTime(2026, 9, 7));
    });

    test('회수만 적힌 조건은 무게 조건을 얻지 못한다', () {
      final q = decode({
        'exercises': ['데드리프트'],
        'period': 'today',
        'weight': {'op': '>=', 'value': 5, 'unit': 'kg'},
        'reps': {'op': '>=', 'value': 5},
        'measures': ['setCount'],
      }, question: '오늘 데드리프트 세트 몇 개 했어 5회 이상?');
      expect(q.scope.weight, isEmpty);
      expect(q.scope.reps.map((b) => '$b'), ['>=5.0']);
      // 단위가 '회' 인 무게 조건도 버린다.
      final unit = decode({
        'exercises': ['벤치프레스'],
        'weight': {'op': '>=', 'value': 5, 'unit': '회'},
        'measures': ['setCount'],
      }, question: '벤치 세트 몇 개 5회 이상');
      expect(unit.scope.weight, isEmpty);
      expect(unit.scope.reps.map((b) => '$b'), ['>=5.0']);
      // 단위 없는 숫자 조건이 따로 있으면 남기고 사람이 확인한다.
      final unitless = decode({
        'exercises': ['스쿼트'],
        'weight': {'op': '>=', 'value': 80, 'unit': 'kg'},
        'reps': {'op': '>=', 'value': 5},
        'measures': ['setCount'],
      }, question: '스쿼트 80 이상 5회 이상 세트');
      expect(unitless.scope.weight.map((b) => '$b'), ['>=80.0kg']);
      expect(unitless.requiresConfirmation, isTrue);
    });

    test('파운드: 글이 정하고, 글에 없으면 모델을 믿는다', () {
      Map<String, Object?> bench(String op, num v, String unit) => {
        'exercises': ['벤치프레스'],
        'weight': {'op': op, 'value': v, 'unit': unit},
        'measures': ['setCount'],
      };
      expect(
        decode(
          bench('>=', 100, 'kg'),
          question: '벤치 100파운드 이상 세트 개수',
        ).scope.weight.map((b) => '$b'),
        ['>=100.0lb'],
      );
      expect(
        decode(
          bench('<=', 100, 'kg'),
          question: '스쿼트 100파운드 이상 세트 수',
        ).scope.weight.map((b) => '$b'),
        ['>=100.0lb'],
        reason: '반대 방향 조건도 글이 바로잡는다',
      );
      expect(
        decode(
          bench('>=', 90, 'kg'),
          question: '벤치 90 이상',
        ).scope.weight.map((b) => '$b'),
        ['>=90.0kg'],
      );
      // 단위 낱말만으로는 이미 바꾼 값을 다시 붙이지 않는다.
      expect(
        decode(
          bench('>=', 45.359237, 'kg'),
          question: '스쿼트 100파운드보다 무거운 세트',
        ).scope.weight.map((b) => '$b'),
        ['>=45.359237kg'],
      );
      expect(
        decode({
          'exercises': ['벤치프레스'],
          'measures': ['best'],
        }, question: '벤치 파운드로 얼마?').scope.weight,
        isEmpty,
      );
    });

    test('메모를 묻는 글의 숫자는 조건이 아니다', () {
      final q = decode({
        'exercises': ['스쿼트'],
        'memo': ['80kg', '계획'],
      }, question: '스쿼트 80kg 이상 하겠다는 계획 메모');
      expect(q.scope.memo, ['80kg', '계획']);
      expect(q.scope.weight, isEmpty);
    });

    test('달 이름은 주어진 시계와 적힌 해로 푼다', () {
      final on = DateTime(2031, 2, 10);
      Map<String, Object?> best() => {
        'exercises': ['스쿼트'],
        'measures': ['best'],
      };
      expect(
        decode(best(), question: '12월 스쿼트 최고', on: on).scope.since,
        DateTime(2030, 12),
      );
      final explicit = decode(best(), question: '2025년 9월 스쿼트 최고', on: on);
      expect(
        (explicit.scope.since, explicit.scope.until),
        (DateTime(2025, 9), DateTime(2025, 9, 30)),
      );
      // 2월에 말하는 "9월" 은 아직 안 온 달이라 작년이다.
      final september = decode(
        best(),
        question: '9월에 스쿼트 몇 kg까지 들었지 좀',
        on: on,
      );
      expect(
        (september.scope.since, september.scope.until),
        (DateTime(2030, 9, 1), DateTime(2030, 9, 30)),
      );
      for (final question in ['9월 3일 스쿼트 최고', '9월부터 스쿼트 최고']) {
        final q = decode(
          {
            ...best(),
            'period': 'custom',
            'since': '2025-09-03',
            'until': '2025-09-03',
          },
          question: question,
          on: on,
        );
        expect(
          (q.scope.since, q.scope.until),
          (DateTime(2025, 9, 3), DateTime(2025, 9, 3)),
        );
        expect(statedPeriod(question, today: on), isNull);
      }
    });

    test('운동 하나를 지목한 순위는 순위가 아니다', () {
      for (final (question, want) in [
        ('지난달 벤치프레스는 정체기인가', Metric.trend),
        ('올해 스쿼트 늘고 있나', Metric.trend),
        ('야 9월에 벤치프레스 PRㅋㅋ', Metric.best),
        ('스쿼트 직전 세트?', Metric.last),
      ]) {
        final q = decode({
          'by': 'exercise',
          'measures': ['trainingDays'],
          'limit': 1,
        }, question: question);
        expect(q.by, isNull, reason: question);
        expect(q.scope.exercises, hasLength(1), reason: question);
        expect(q.measures, [want], reason: question);
      }
      final named = decode({
        'exercises': ['벤치프레스'],
        'by': 'exercise',
        'measures': ['trainingDays'],
        'limit': 1,
      }, question: '벤치프레스는 정체기인가');
      expect(named.by, isNull);
      expect(named.measures, [Metric.trend]);
    });

    test('진짜 순위(운동 이름 없음)는 그대로 순위다', () {
      for (final question in ['가장 자주 한 운동 세 개', '최고 많이 한 운동']) {
        final q = decode({
          'by': 'exercise',
          'measures': ['trainingDays'],
          'order': 'desc',
          'limit': 3,
        }, question: question);
        expect(q.by, 'exercise', reason: question);
      }
      final except = decode({
        'exclude': ['벤치프레스'],
        'by': 'exercise',
        'measures': ['best'],
        'order': 'desc',
        'limit': 1,
      }, question: '벤치 말고 제일 무겁게 든 운동');
      expect(except.by, 'exercise');
      expect(except.scope.exercises, isEmpty);
    });

    test('의도 낱말이 한 갈래면 그것이 측정이다', () {
      Metric run(String measure, String question) => decode({
        'exercises': ['스쿼트'],
        'measures': [measure],
      }, question: question).measures.single;
      expect(run('setCount', '벤치프레스 총 몇 회'), Metric.reps);
      expect(run('setCount', '스쿼트 몇 번 했지'), Metric.sessions);
      expect(run('trainingDays', '데드 최고 무게'), Metric.best);
      // 두 갈래("최고" + "세트 수")면 모델의 답을 둔다.
      expect(run('setCount', '벤치 최고 세트 수'), Metric.sets);
      expect(run('latest', '스쿼트 최고 기록 말고 마지막 기록'), Metric.last);
    });

    test('이름이 필요한데 없으면, 글에서 하나만 잡힐 때 그것으로', () {
      Map<String, Object?> trend() => {
        'measures': ['weightChange'],
      };
      expect(decode(trend(), question: '스쿼트 요즘 어때').scope.exercises, ['스쿼트']);
      expect(
        decode(trend(), question: '스쿼트 벤치 요즘 어때').scope.exercises,
        isEmpty,
      );
      expect(
        decode({
          'period': 'lastWeek',
          'measures': ['trainingDays'],
        }, question: '지난주 스쿼트 며칠 갔어').scope.exercises,
        isEmpty,
        reason: '개수는 이름 없이도 뜻이 선다',
      );
    });

    test('오타를 퍼지로 읽었으면 무엇으로 읽었는지 남긴다', () {
      final q = decode({
        'exercises': ['스쿼드'],
        'measures': ['best'],
      }, question: '스쿼드 최고');
      expect(q.scope.exercises, ['스쿼트']);
      expect(q.readAs, {'스쿼트': '스쿼드'});
      expect(
        decode({
          'exercises': ['스쿼트'],
          'measures': ['best'],
        }, question: '스쿼트 최고').readAs,
        isEmpty,
      );
    });

    group('글이 정하는 것', () {
      test('사전 키와 정확히 같은 낱말만 정식 이름으로 바꾼다', () {
        expect(canonicalizeExercises('스쾃 PR 얼마?', names), '스쿼트 PR 얼마?');
        expect(canonicalizeExercises('bp 최고', names), '벤치프레스 최고');
        expect(canonicalizeExercises('벤치 최고', names), '벤치 최고');
        expect(canonicalizeExercises('밴치 최고', names), '밴치 최고');
        expect(canonicalizeExercises('스쾃은 최고 얼마', names), '스쿼트은 최고 얼마');
        expect(canonicalizeExercises('bp는 PR', names), '벤치프레스는 PR');
        expect(canonicalizeExercises('dl 다 합쳐서 몇 개', names), '데드리프트 다 합쳐서 몇 개');
        expect(canonicalizeExercises('press 최고', names), 'press 최고');
      });

      test('기간 낱말이 하나면 그것, 둘이면 모델에 맡긴다', () {
        expect(statedPeriod('이번 주 어깨 아팠다고 쓴 거 있어?')?.period, 'thisWeek');
        expect(statedPeriod('지난달 벤치')?.period, 'lastMonth');
        expect(statedPeriod('최근 14일 푸시업')?.days, 14);
        expect(statedPeriod('지난달보다 이번 달 스쿼트'), isNull);
        expect(statedPeriod('벤치 최고'), isNull);
        final t = DateTime(2026, 9, 9);
        final sept = statedPeriod('9월에 벤치 몇 번', today: t)!;
        expect(
          (sept.period, sept.since, sept.until),
          ('custom', '2026-09-01', '2026-09-30'),
        );
        expect(statedPeriod('12월 스쿼트', today: t)!.since, '2025-12-01');
        expect(statedPeriod('최근 2주 푸시업')?.days, 14);
        // 정수 한도를 넘는 숫자는 기간이 아니다. 목록을 그리다 죽으면 안 된다.
        expect(statedPeriod('최근 99999999999999999999일 벤치'), isNull);
        expect(statedPeriod('최근 3개월 벤치')?.days, 90);
        expect(statedPeriod('3개월간 벤치'), isNull);
        expect(statedPeriod('9월 1일부터 벤치프레스', today: t), isNull);
        expect(statedPeriod('지난달까지 스쿼트 최고', today: t), isNull);
        expect(statedPeriod('9월 3일 스쿼트', today: t), isNull);
        expect(statedPeriod('9월에 몇 kg까지 들었지', today: t)?.period, 'custom');
        expect(statedPeriod('이번 주 100kg까지 갔나', today: t)?.period, 'thisWeek');
      });

      test('숫자 조건은 글에 적힌 대로', () {
        final f = statedFilters('데드 80kg 이상 5회 이상 한 세트 수');
        expect((f.minWeight, f.unit, f.minReps), (80.0, 'kg', 5));
        final g = statedFilters('벤치 100파운드 이하');
        expect((g.maxWeight, g.unit), (100.0, 'lb'));
        expect(statedFilters('스쿼트 60 이상').minWeight, isNull);
        expect(statedFilters('벤치 팔십 킬로 이상').minWeight, 80);
        expect(statedFilters('스쿼트 백이십 kg 이하').maxWeight, 120);
        expect(statedFilters('푸시업 이십 회 이상').minReps, 20);
        for (final q in [
          '80kg 이상 또는 50kg 이하',
          '80kg 이상 제외',
          '80kg 이상 200lb 이하',
        ]) {
          final x = statedFilters(q);
          expect((x.minWeight, x.maxWeight, x.unit), (null, null, null));
        }
        final y = statedFilters('90kg 이상 80kg 이상 150kg 이하 160kg 이하');
        expect((y.minWeight, y.maxWeight), (90.0, 150.0));
        expect(statedFilters('100lb OR MORE').minWeight, 100);
      });
    });
  });

  group('확인 줄', () {
    test('범위·조건·묶음·순서를 빠짐없이 적는다', () {
      final q = decode({
        'exercises': ['벤치프레스'],
        'measures': ['setCount'],
        'weight': [
          {'op': '>', 'value': 60, 'unit': 'lb'},
          {'op': '<=', 'value': 80.375, 'unit': 'lb'},
        ],
        'reps': {'op': '>=', 'value': 5},
        'weekdays': [1],
        'sessions': 3,
        'series': [
          {'period': 'custom', 'since': '2025-08-01', 'until': '2025-08-31'},
          {'period': 'custom', 'since': '2026-08-01', 'until': '2026-08-31'},
        ],
      });
      final text = describePlan(q, l, 'kg');
      for (final part in [
        '세트 수',
        'kg',
        '차이 (2 − 1)',
        '1. 벤치프레스 · 2025-08-01 – 2025-08-31',
        '2. 벤치프레스 · 2026-08-01 – 2026-08-31',
        '> 60lb',
        '≤ 80.375lb',
        '≥ 5회',
        '월',
        '마지막 3번',
      ]) {
        expect(text, contains(part));
      }
      expect(describeQuery(q, l, 'kg'), text, reason: '옛 이름은 같은 글');
      final ranked = decode({
        'exclude': ['벤치프레스'],
        'by': 'exercise',
        'measures': ['best'],
        'order': 'desc',
        'limit': 3,
      });
      expect(
        describePlan(ranked, l, 'kg'),
        '벤치프레스 제외 · 최고 · kg · 운동별 · 상위 3개 · 내림차순 · 모든 운동 · 전체 기간',
      );
      final pair = decode({
        'exercises': ['벤치프레스', '바벨로우'],
      });
      expect(
        describePlan(pair, l, 'kg'),
        allOf(
          contains('차이 (2 − 1)'),
          contains('1. 벤치프레스 · 전체 기간'),
          contains('2. 바벨로우 · 전체 기간'),
        ),
      );
    });
  });

  group('모델과 캐시', () {
    Map<String, Object?> squat({String? period}) => {
      'exercises': ['스쿼트'],
      'measures': ['best'],
      'period': ?period,
    };

    test('모든 문장 질문은 이름 목록만 들고 모델에 간다 — 기록은 안 간다', () async {
      final received = <String>[];
      Future<Object?> reply(String instructions, String input) async {
        expect(instructions, startsWith('Convert ONLY the final question'));
        final prompt = jsonDecode(input) as Map;
        received.add(prompt['question'] as String);
        expect(prompt['referenceYear'], 2026);
        expect(prompt.containsKey('today'), isFalse);
        expect(prompt.containsKey('records'), isFalse);
        return squat();
      }

      final ai = RecordAi(respond: reply);
      for (final question in ['스쿼트 최대 무게', '스쾃 PR']) {
        await ai.queryIntent(question, 'ko', names, unit: 'kg', today: today);
      }
      expect(received, ['스쿼트 최대 무게', '스쿼트 PR']);
    });

    test('서버에는 contract 3 으로 묻고, 402 는 원판 부족이다', () async {
      final bodies = <Map>[];
      var status = 200;
      final ai = RecordAi(
        endpoint: 'https://example.test',
        deviceId: 'device',
        client: MockClient((request) async {
          if (request.url.path == '/api/device') {
            return http.Response(jsonEncode({'token': 't'}), 200);
          }
          bodies.add(jsonDecode(request.body) as Map);
          return http.Response(
            jsonEncode({'intent': squat()}),
            status,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      expect(await ai.queryIntent('스쿼트 최고', 'ko', names, unit: 'kg'), squat());
      expect(bodies.single['contract'], 3);
      status = 402;
      final search = RecordSearch(ai, cache: QueryCache(directory: _temp()));
      await search.refresh('ko');
      search.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
      await pumpEventQueue();
      expect(
        (search.noPlates, search.failed, search.plan),
        (true, false, null),
      );
      search.dispose();
    });

    test('보내는 중인 질문을 다시 보내도 모델을 또 부르지 않는다', () async {
      final result = Completer<Object?>();
      var calls = 0;
      Future<Object?> reply(String instructions, String input) async {
        calls++;
        return result.future;
      }

      final search = RecordSearch(
        RecordAi(respond: reply),
        cache: QueryCache(directory: _temp()),
      );
      await search.refresh('ko');
      search.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
      await Future<void>.delayed(Duration.zero);
      search.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
      expect(calls, 1);
      result.complete(squat());
      await Future<void>.delayed(Duration.zero);
      expect(search.plan?.scope.exercises, ['스쿼트']);
      search.dispose();
    });

    test('해석은 기기에 남고, 날짜는 꺼낼 때 다시 푼다', () async {
      var calls = 0;
      var now = DateTime(2026, 9, 9);
      Future<Object?> reply(String instructions, String input) async {
        calls++;
        return squat(period: 'lastWeek');
      }

      final search = RecordSearch(
        RecordAi(respond: reply),
        now: () => now,
        cache: QueryCache(directory: _temp()),
      );
      await search.refresh('ko');
      search.search('지난주 스쿼트 최고', 'ko', names, 'kg', immediately: true);
      await Future<void>.delayed(Duration.zero);
      final first = search.plan!.scope.since;

      // 같은 질문을 다음 주에 다시 묻는다. 모델은 부르지 않지만 기간은 옮겨간다.
      now = DateTime(2026, 9, 16);
      search.search('', 'ko', names, 'kg');
      search.search('지난주 스쿼트 최고', 'ko', names, 'kg', immediately: true);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1, reason: '두 번째는 저장해 둔 해석을 쓴다');
      expect(
        search.plan!.scope.since,
        first!.add(const Duration(days: 7)),
        reason: '"지난주" 는 묻는 날에 따라 다른 주다',
      );

      // 운동을 새로 하나 적어도 다시 사지 않는다 — 이름은 꺼낼 때마다 지금의
      // 기록으로 다시 푼다. 단위나 해(referenceYear)가 달라지면 다시 묻는다.
      search.search(
        '지난주 스쿼트 최고',
        'ko',
        [...names, '덤벨컬'],
        'kg',
        immediately: true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      search.search(
        '지난주 스쿼트 최고',
        'ko',
        [...names, '덤벨컬'],
        'lb',
        immediately: true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);
      now = DateTime(2027, 1, 5);
      search.search('지난주 스쿼트 최고', 'ko', names, 'lb', immediately: true);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 3, reason: '절대 날짜가 해를 넘겨 쓰이지 않는다');
      search.dispose();
    });

    test('앱을 껐다 켜도 저장해 둔 해석을 쓴다 — 옛 모양은 다시 묻는다', () async {
      var calls = 0;
      Future<Object?> reply(String instructions, String input) async {
        calls++;
        return squat();
      }

      final dir = _temp();
      // v1 이 남긴 열쇠(앞에 'q2' 가 없다). 읽히지 않고 밀려난다.
      File('${dir.path}/queries.json').writeAsStringSync(
        jsonEncode({
          jsonEncode([
            '스쿼트 최고',
            'ko',
            'kg',
            [...names]..sort(),
          ]): {
            'action': 'heaviest',
          },
        }),
      );
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
      expect(second.plan!.scope.exercises, ['스쿼트']);
      second.dispose();
    });

    test('늦게 온 답은 새 질문을 덮지 못한다', () async {
      final first = Completer<Object?>();
      var calls = 0;
      Future<Object?> reply(String instructions, String input) async {
        calls++;
        return calls == 1
            ? first.future
            : {
                'exercises': ['푸시업'],
                'measures': ['repCount'],
              };
      }

      final search = RecordSearch(
        RecordAi(respond: reply),
        cache: QueryCache(directory: _temp()),
      );
      await search.refresh('ko');
      search.search('스쿼트 얼마', 'ko', names, 'kg', immediately: true);
      await Future<void>.delayed(Duration.zero);
      search.search('푸시업 몇 개', 'ko', names, 'kg', immediately: true);
      first.complete(squat());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(search.plan!.scope.exercises, ['푸시업']);
      search.dispose();
    });

    test('치는 동안에는 모델을 부르지 않는다 — 원판은 제출할 때만 나간다', () async {
      var calls = 0;
      Future<Object?> reply(String instructions, String input) async {
        calls++;
        return squat();
      }

      final search = RecordSearch(
        RecordAi(respond: reply),
        cache: QueryCache(directory: _temp()),
      );
      await search.refresh('ko');
      for (final text in ['스쿼트 최', '스쿼트 최고', '스쿼트 최고 무게']) {
        search.search(text, 'ko', names, 'kg');
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      expect(calls, 0, reason: '단어마다 쉬어도 서버에 가지 않는다');
      expect((search.busy, search.plan), (false, null));
      search.search('스쿼트 최고 무게', 'ko', names, 'kg', immediately: true);
      await pumpEventQueue();
      expect(calls, 1);
      // 한 번 값을 낸 답은 칠 때도 담아 둔 것에서 보인다.
      search.search('', 'ko', names, 'kg');
      search.search('스쿼트 최고 무게', 'ko', names, 'kg');
      expect(search.plan?.scope.exercises, ['스쿼트']);
      expect(calls, 1);
      search.dispose();
    });

    test('버린 답도 담아 둔다 — 값을 낸 답을 다시 사지 않는다', () async {
      final first = Completer<Object?>();
      var calls = 0;
      Future<Object?> reply(String instructions, String input) async {
        calls++;
        return first.future;
      }

      final search = RecordSearch(
        RecordAi(respond: reply),
        cache: QueryCache(directory: _temp()),
      );
      await search.refresh('ko');
      search.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
      await Future<void>.delayed(Duration.zero);
      // 기다리는 동안 앱이 잠깐 가려졌다가(취소) 같은 질문을 다시 냈다.
      search.cancel();
      search.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
      first.complete(squat());
      await pumpEventQueue();
      expect(calls, 1, reason: '앞선 답이 담겨 뒤의 것은 서버에 가지 않는다');
      expect(search.plan?.scope.exercises, ['스쿼트']);
      search.dispose();
    });

    test(
      'C·서버는 답했는데 셀 수 없는 모양이면 무엇에 걸렸는지 말하고, 그 거절을 담아 원판이 또 나가지 않는다',
      () async {
        var calls = 0;
        Future<Object?> reply(String instructions, String input) async {
          calls++;
          // 주 묶음에 측정 둘 — 앱이 셀 수 없는 모양이다.
          return {
            'by': 'week',
            'measures': ['volume', 'setCount'],
          };
        }

        final search = RecordSearch(
          RecordAi(respond: reply),
          cache: QueryCache(directory: _temp()),
        );
        await search.refresh('ko');
        const question = '주별 볼륨이랑 세트 수';
        search.search(question, 'ko', names, 'kg', immediately: true);
        await pumpEventQueue();
        expect(
          (search.unrepresentable, search.failed, search.charged, search.plan),
          ('groupedMeasure', false, true, null),
          reason: '일시 장애가 아니다 — "다시 시도" 가 아니다',
        );

        // 다시 눌러도 서버에 가지 않는다. 같은 곳에서 막힐 것에 원판을 또 내지 않는다.
        search.search('', 'ko', names, 'kg');
        search.search(question, 'ko', names, 'kg', immediately: true);
        await pumpEventQueue();
        expect(calls, 1);
        expect(
          (search.unrepresentable, search.charged),
          ('groupedMeasure', false),
        );
        // 치는 중에도 담아 둔 거절이 보인다.
        search.search(question, 'ko', names, 'kg');
        expect(search.unrepresentable, 'groupedMeasure');
        search.dispose();
      },
    );

    test(
      'C·서버가 답했는데 읽지 못한 답은 연결 문제가 아니다 — 담아 두어 다시 눌러도, 새로 켜도 원판을 또 쓰지 않고, 말을 바꾸면 다시 묻는다 (v3 재검토 R5)',
      () async {
        var calls = 0;
        Future<Object?> reply(String instructions, String input) async {
          calls++;
          // 첫 답만 모르는 키가 섞였다. 다른 질문의 답은 멀쩡하다.
          return calls == 1 ? {...squat(), 'foo': 1} : squat();
        }

        final dir = _temp();
        final search = RecordSearch(
          RecordAi(respond: reply),
          cache: QueryCache(directory: dir),
        );
        await search.refresh('ko');
        search.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
        await pumpEventQueue();
        expect(
          (search.misread, search.failed, search.charged, search.plan, calls),
          (true, false, true, null, 1),
        );
        // 다시 눌러도 서버에 가지 않는다 — 같은 답에 원판을 또 내지 않는다.
        search.search('', 'ko', names, 'kg');
        search.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
        await pumpEventQueue();
        expect((search.misread, search.charged, calls), (true, false, 1));
        search.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // 새로 켠 앱(같은 캐시)도 담아 둔 답을 읽는다.
        final again = RecordSearch(
          RecordAi(respond: reply),
          cache: QueryCache(directory: dir),
        );
        await again.refresh('ko');
        again.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
        await pumpEventQueue();
        expect((again.misread, calls), (true, 1));
        // 말을 바꾸면 새 질문이다.
        again.search('스쿼트 최고 기록', 'ko', names, 'kg', immediately: true);
        await pumpEventQueue();
        expect(calls, 2);
        expect(again.misread, isFalse);
        expect(again.plan?.scope.exercises, ['스쿼트']);
        again.dispose();
      },
    );

    test('C·600자가 넘는 질문은 보내지 않고 그렇다고 말한다 — 입력칸의 글은 부르는 쪽이 둔다', () async {
      var calls = 0;
      final search = RecordSearch(
        RecordAi(
          respond: (_, _) async {
            calls++;
            return squat();
          },
        ),
        cache: QueryCache(directory: _temp()),
      );
      await search.refresh('ko');
      final long = '스쿼트 ${'요즘 어때 ' * 120}';
      search.search(long, 'ko', names, 'kg');
      expect(search.tooLong, isFalse, reason: '치는 동안에는 말하지 않는다');
      search.search(long, 'ko', names, 'kg', immediately: true);
      await pumpEventQueue();
      expect((calls, search.tooLong, search.failed), (0, true, false));
      search.dispose();
    });

    test(
      'C·연결이 안 된다고 굳어 있어도 Enter 때 한 번 다시 확인한다 — 돌아왔으면 묻고, 아니면 그렇다고 말한다',
      () async {
        RecordAi.forget();
        addTearDown(RecordAi.forget);
        var online = false;
        var calls = 0;
        final ai = RecordAi(
          endpoint: 'https://example.test',
          deviceId: 'device',
          client: MockClient((request) async {
            if (!online) throw http.ClientException('offline');
            if (request.url.path == '/api/device') {
              return http.Response(jsonEncode({'token': 't'}), 200);
            }
            calls++;
            return http.Response(
              jsonEncode({'intent': squat()}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        final search = RecordSearch(ai, cache: QueryCache(directory: _temp()));
        await search.refresh('ko');
        expect(search.status, RecordAiStatus.unavailable);

        search.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
        await pumpEventQueue();
        expect((search.offline, search.plan, calls), (true, null, 0));

        // 망이 돌아왔다. 앱을 내렸다 올리지 않아도 Enter 가 다시 확인한다.
        online = true;
        search.search('스쿼트 최고', 'ko', names, 'kg', immediately: true);
        await pumpEventQueue();
        expect(search.status, RecordAiStatus.ready);
        expect((search.offline, calls), (false, 1));
        expect(search.plan?.scope.exercises, ['스쿼트']);
        search.dispose();
      },
    );
  });

  group('v3', () {
    test('사전 맞춤은 강한 것만 — 앞부분·별칭·자모 한 개, 둘에 닿으면 없음', () {
      String? of(String raw) => dictionaryMatch(raw)?.exercise.ko;
      for (final (raw, ko, exact) in [
        ('벤치프레스', '벤치프레스', true),
        ('Bench Press', '벤치프레스', true),
        ('卧推', '벤치프레스', true),
        ('스쾃', '스쿼트', true),
        ('dead', '데드리프트', true),
        ('벤치', '벤치프레스', false),
        ('데드', '데드리프트', false),
        ('bench', '벤치프레스', false),
        ('스쿼드', '스쿼트', false),
        ('바밸로우', '바벨로우', false),
        ('런닝', '러닝', false),
      ]) {
        expect(of(raw), ko, reason: raw);
        expect(dictionaryMatch(raw)!.exact, exact, reason: raw);
      }
      // 둘 이상에 닿거나(레그·덤벨·db), 짧은 말의 먼 퍼지(클린→크런치, 로우→로잉,
      // row→rowing), 사전에 없는 이름은 어느 운동도 아니다.
      for (final raw in [
        '레그',
        '덤벨',
        'db',
        '클린',
        '로우',
        'row',
        '케이블 크런치',
        '케틀벨 스윙',
        '민수식 로우',
      ]) {
        expect(of(raw), isNull, reason: raw);
      }
    });

    test('부위 표: 사전 58개 모두, 레그레이즈는 코어, 러닝은 유산소, 상체·하체 펼침', () {
      expect(exercises, hasLength(58));
      for (final e in exercises) {
        expect(exercisePart[e.ko], isNotNull, reason: e.ko);
      }
      expect(exercisePart.length, 58);
      expect(partOf('레그레이즈'), 'core');
      expect(partOf('Running'), 'cardio');
      expect(partOf('Deadlift'), 'back');
      expect(partOf('민수식 로우'), isNull);
      expect(inPart('벤치프레스', 'upper'), isTrue);
      expect(inPart('데드리프트', 'upper'), isTrue);
      expect(inPart('스쿼트', 'lower'), isTrue);
      expect(inPart('스쿼트', 'upper'), isFalse);
      expect(inPart('플랭크', 'upper'), isFalse);
    });

    test('이름 풀기: 바밸로우는 기록의 덤벨로우가 아니다, 영어 이름은 기록으로, 사전에 없는 이름은 그대로', () {
      const logged = ['벤치프레스', '덤벨로우', '시티드 로우', '스쿼트'];
      RecordQuery q(String name) => RecordQuery.decode(
        {
          'exercises': [name],
          'measures': ['best'],
        },
        logged,
        today: today,
      );
      final row = q('바밸로우');
      expect(row.never, {'바밸로우'});
      expect(row.suggested['바밸로우'], '바벨로우');
      final bench = q('Bench Press');
      expect(bench.never, isEmpty);
      expect(bench.scope.exercises, ['벤치프레스']);
      expect(bench.readAs, {'벤치프레스': 'Bench Press'});
      final bell = q('케틀벨 스윙');
      expect(bell.never, {'케틀벨 스윙'});
      expect(bell.scope.exercises, ['케틀벨 스윙']);
      final squat = q('스쿼드');
      expect(squat.never, isEmpty);
      expect(squat.scope.exercises, ['스쿼트']);
      expect(squat.readAs, {'스쿼트': '스쿼드'});
      // 사전에 있지만 안 적은 운동은 화면 언어의 사전 이름이다.
      final hip = RecordQuery.decode(
        {
          'exercises': ['Hip Thrust'],
        },
        logged,
        today: today,
      );
      expect(hip.never, {'힙쓰러스트'});
      expect(hip.names['힙쓰러스트'], '힙쓰러스트');
      final en = RecordQuery.decode(
        {
          'exercises': ['힙쓰러스트'],
        },
        logged,
        today: today,
        lang: 'en',
      );
      expect(en.names['힙쓰러스트'], 'Hip Thrust');
    });

    test('상속: 기간 네 키는 한 덩이, shift 는 따로 — 작년 이맘때', () {
      final q = decode({
        'exercises': ['벤치프레스'],
        'period': 'recent',
        'days': 30,
        'series': [
          {
            'shift': {'years': 1},
          },
          {},
        ],
      });
      expect(q.series.map((s) => (s.scope.since, s.scope.until)), [
        (DateTime(2025, 8, 25), DateTime(2025, 9, 23)),
        (DateTime(2026, 8, 25), DateTime(2026, 9, 23)),
      ]);
      final own = decode({
        'exercises': ['벤치프레스'],
        'period': 'recent',
        'days': 30,
        'series': [
          {'period': 'lastMonth'},
          {},
        ],
      });
      expect(own.series.first.scope.since, DateTime(2026, 8, 1));
      expect(own.series.first.scope.until, DateTime(2026, 8, 31));
    });

    test('규칙 층은 shift 가 있으면 쉰다 — "작년" 이 lastYear 로 덮이지 않는다', () {
      final q = decode({
        'exercises': ['스쿼트'],
        'period': 'recent',
        'days': 30,
        'series': [
          {
            'shift': {'years': 1},
          },
          {},
        ],
      }, question: '작년 이맘때 대비 스쿼트');
      expect(q.series, hasLength(2));
      expect(q.series.first.scope.since!.year, 2025);
    });

    test('지시문: 8,000자 이하, 예시 plan 은 모두 디코더를 지난다', () {
      expect(planInstructions.length, lessThanOrEqualTo(8000));
      const logged = [
        '스쿼트',
        '벤치프레스',
        '데드리프트',
        '오버헤드프레스',
        '레그프레스',
        '바벨로우',
        '러닝',
        'Squat',
        'Deadlift',
      ];
      var count = 0;
      for (final m in RegExp(
        r'^"(.+?)" => (.*)$',
        multiLine: true,
      ).allMatches(planInstructions)) {
        final q = RecordQuery.decode(
          jsonDecode(m[2]!),
          logged,
          today: today,
          question: m[1]!,
        );
        expect(q.kind, isNot('find'), reason: m[1]);
        count++;
      }
      // 평가 모음과 틀이 같던 예시와 규칙 문장이 이미 말하는 예시를 빼 22개다 —
      // 한 질문의 토큰이 설계 예산(2,600)을 넘었다(v3 재검토).
      expect(count, greaterThanOrEqualTo(22));
    });

    test('기록 이름은 해낸 세트로 정하고, 모델에 그 이름만 간다 — 거절도 담아 원판을 다시 쓰지 않는다', () async {
      final sent = <List<Object?>>[];
      var calls = 0;
      Future<Object?> reply(String instructions, String input) async {
        calls++;
        sent.add((jsonDecode(input) as Map)['exerciseNames'] as List);
        return {
          'notComputable': ['심박'],
        };
      }

      final notes = [
        note('n', today, [
          ExerciseBlock('스쿼트', [LoggedSet(value: 100, reps: 5)]),
          ExerciseBlock('레그프레스', [LoggedSet(value: 100, reps: 5, done: false)]),
        ]),
      ];
      final search = RecordSearch(
        RecordAi(respond: reply),
        now: () => today,
        cache: QueryCache(directory: _temp()),
      );
      await search.refresh('ko');
      search.search(
        '내 심박 평균',
        'ko',
        ['스쿼트', '레그프레스'],
        'kg',
        immediately: true,
        notes: notes,
      );
      await pumpEventQueue();
      expect(sent.single, ['스쿼트']);
      expect(
        (search.plan?.kind, search.plan?.reason),
        ('unsupported', 'nothing'),
      );
      search.search(
        '내 심박 평균',
        'ko',
        ['스쿼트'],
        'kg',
        immediately: true,
        notes: notes,
      );
      await pumpEventQueue();
      expect(calls, 1, reason: '거절도 결정적이다 — 담아 둔다');
      search.dispose();
    });
  });
}

Directory _temp() {
  final dir = Directory.systemTemp.createTempSync('setpad_cache');
  addTearDown(() => dir.deleteSync(recursive: true));
  return dir;
}
