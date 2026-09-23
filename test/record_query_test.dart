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
        {
          'compare': [
            {'period': 'lastMonth'},
            {'period': 'lastMonth'},
          ],
        },
        {
          'by': 'exercise',
          'compare': [
            {'period': 'lastMonth'},
            {'period': 'thisMonth'},
          ],
        },
        {
          'compare': [
            {'period': 'lastMonth', 'by': 'day'},
            {'period': 'thisMonth'},
          ],
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

    test('못 푸는 것과 무관한 것은 거절이 아니라 까닭이다', () {
      final blank = decode({});
      expect((blank.kind, blank.reason), ('unsupported', 'ambiguous'));
      final unrelated = decode({
        'kind': 'unrelated',
        'exercises': ['x'],
      });
      expect((unrelated.kind, unrelated.reason), ('unsupported', 'unrelated'));
      final missing = decode({
        'exercises': ['요가'],
      });
      expect((missing.kind, missing.reason), ('unsupported', 'missingData'));
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

    test('정규화: 기본 측정, 운동만 다른 비교, 운동 둘, 순위의 최고', () {
      final plain = decode({
        'exercises': ['스쿼트'],
      });
      expect(plain.measures, RecordQuery.defaultMeasures);
      expect(plain.requiresConfirmation, isTrue);
      final pair = decode({
        'measures': ['best'],
        'compare': [
          {
            'exercises': ['벤치프레스'],
          },
          {
            'exercises': ['바벨로우'],
          },
        ],
      });
      expect(pair.compare, isEmpty);
      expect(pair.by, 'exercise');
      expect(pair.scope.exercises, ['벤치프레스', '바벨로우']);
      expect(
        decode({
          'exercises': ['벤치프레스', '바벨로우'],
        }).by,
        'exercise',
      );
      final ranked = decode({
        'by': 'exercise',
        'measures': ['best'],
        'order': 'desc',
      });
      expect(ranked.measures, [Metric.max]);
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

    test('고침: 비교 항목마다 똑같이 적은 측정은 질의의 측정이다', () {
      final raw = {
        'compare': [
          {
            'period': 'lastYear',
            'measures': ['trainingDays'],
          },
          {
            'period': 'thisYear',
            'measures': ['trainingDays'],
          },
        ],
      };
      final q = decode(raw);
      expect(q.measures, [Metric.sessions]);
      expect(q.compare.map((v) => v.since?.year), [2025, 2026]);
      expect(
        ((raw['compare'] as List).first as Map).keys,
        contains('measures'),
        reason: '들어온 대답은 그대로 — 캐시가 다시 푼다',
      );
      // 항목마다 다르거나 위와 어긋나면 한 질의로 못 쓴다.
      for (final raw in <Map<String, Object?>>[
        {
          'compare': [
            {
              'period': 'lastYear',
              'measures': ['trainingDays'],
            },
            {
              'period': 'thisYear',
              'measures': ['volume'],
            },
          ],
        },
        {
          'measures': ['volume'],
          'compare': [
            {
              'period': 'lastYear',
              'measures': ['trainingDays'],
            },
            {
              'period': 'thisYear',
              'measures': ['trainingDays'],
            },
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
        'compare': [
          {'period': 'lastMonth'},
          {'period': 'thisMonth'},
        ],
      }, question: '지난달보다 스쿼트 늘었어?');
      expect(q.compare, hasLength(2));
      expect(q.compare.first.since, DateTime(2026, 8, 1));
      expect(q.compare.last.since, DateTime(2026, 9, 1));
    });

    test('글에 기간이 하나면 모델의 비교 기간 둘은 접는다', () {
      final q = decode(
        {
          'exercises': ['벤치프레스'],
          'measures': ['weightChange'],
          'compare': [
            {'period': 'lastMonth'},
            {'period': 'thisMonth'},
          ],
        },
        question: '이번 달 벤치 무게 변화',
        on: DateTime(2026, 9, 9),
      );
      expect(q.compare, isEmpty);
      expect(q.scope.since, DateTime(2026, 9, 1));
      expect(q.measures, [Metric.trend]);
    });

    test('두 달을 이름으로 견주면 모델의 비교를 둔다', () {
      final q = decode(
        {
          'exercises': ['스쿼트'],
          'measures': ['best'],
          'compare': [
            {'period': 'lastMonth'},
            {'period': 'thisMonth'},
          ],
        },
        question: '1월과 2월 스쿼트 최고 비교',
        on: DateTime(2031, 2, 10),
      );
      expect(q.compare.map((v) => v.since), [
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

    test('값이 빠진 세트로는 합계도, 조건 개수도 만들지 않는다', () {
      final notes = [
        note('incomplete', today, [
          ExerciseBlock('스쿼트', [
            LoggedSet(value: 80, reps: 5),
            LoggedSet(value: 80),
            LoggedSet(reps: 5),
          ]),
        ]),
      ];
      for (final raw in <Map<String, Object?>>[
        for (final m in ['repCount', 'volume', 'best', 'meanWeight'])
          {
            'exercises': ['스쿼트'],
            'measures': [m],
          },
        {
          'exercises': ['스쿼트'],
          'weight': {'op': '>=', 'value': 80, 'unit': 'kg'},
          'measures': ['setCount'],
        },
      ]) {
        final r = runQuery(
          decode(raw),
          notes,
          l: l,
          unit: 'kg',
          today: today,
          confirmed: true,
        )!;
        expect(r.rows.single.cells.single.reason, 'unknown', reason: '$raw');
        expect(r.footnotes, [l.queryMissingFor('스쿼트')], reason: '$raw');
      }
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
        'compare': [
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
      final cells = runQuery(
        q,
        records,
        l: l,
        unit: 'kg',
        today: today,
        confirmed: true,
      )!.rows.single.cells;
      expect(cells.first.answer!.numericValue, 1);
      expect(cells.last.reason, 'none');
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
        'compare': [
          {'period': 'lastMonth'},
          {'period': 'thisMonth'},
        ],
      }, on: DateTime(2024, 3, 8));
      expect(q.compare.first.until, DateTime(2024, 2, 29));
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
        'compare': [
          {'period': 'custom', 'since': '2025-08-01', 'until': '2025-08-31'},
          {'period': 'custom', 'since': '2026-08-01', 'until': '2026-08-31'},
        ],
      });
      final text = describeQuery(q, l, 'kg');
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
      final ranked = decode({
        'exclude': ['벤치프레스'],
        'by': 'exercise',
        'measures': ['best'],
        'order': 'desc',
        'limit': 3,
      });
      expect(
        describeQuery(ranked, l, 'kg'),
        '모든 운동 · 벤치프레스 제외 · 최고 · kg · 운동별 · 상위 3개 · 내림차순 · 전체 기간',
      );
      final pair = decode({
        'exercises': ['벤치프레스', '바벨로우'],
      });
      expect(describeQuery(pair, l, 'kg'), contains('차이 (바벨로우 − 벤치프레스)'));
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

    test('서버에는 contract 2 로 묻고, 402 는 원판 부족이다', () async {
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
      expect(bodies.single['contract'], 2);
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
  });
}

Directory _temp() {
  final dir = Directory.systemTemp.createTempSync('setpad_cache');
  addTearDown(() => dir.deleteSync(recursive: true));
  return dir;
}
