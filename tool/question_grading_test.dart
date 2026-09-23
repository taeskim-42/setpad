import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/exercises.dart';

import 'question_grading.dart';

/// 채점기와 정답을 모델 없이 잰다(네트워크 없음, 몇 초).
///
///     flutter test tool/question_grading_test.dart
///
/// 정답 257문항(v3)과 옮긴 v2·dev·heldout 정답이 모두 문법을 지나는지, 정답이
/// 자기와 견주면 맞음인지, 지표(deadEnd·swapped …)가 뜻대로 서는지 본다.
List<Map<String, Object?>> _load(String name) =>
    (jsonDecode(File('tool/questions/$name.json').readAsStringSync()) as List)
        .cast<Map>()
        .map((c) => c.cast<String, Object?>())
        .toList();

/// 코퍼스 assumedLog 의 안 적은 운동. 정답의 never 는 이것뿐이어야 한다.
const _notLogged = ['바벨로우', '힙쓰러스트', '케틀벨 스윙', '클린', '머슬업', '딥스', '수영'];

const _ko = [
  '벤치프레스',
  '인클라인 벤치프레스',
  '덤벨 프레스',
  '스쿼트',
  '데드리프트',
  '루마니안 데드리프트',
  '오버헤드프레스',
  '랫풀다운',
  '풀업',
  '시티드 로우',
  '레그프레스',
  '레그컬',
  '사이드 레터럴 레이즈',
  '바벨컬',
  '케이블 푸시다운',
  '플랭크',
  '러닝',
  '사이클',
  '푸시업',
  '버피',
];

Grade _grade(
  Object? got,
  List<Object?> gold, {
  String q = '',
  List<String> names = _ko,
}) => gradePlan(got, gold, names: names, lang: 'ko', question: q);

Map<String, Object?> _shape(Object? plan, {String q = ''}) =>
    planShape(plan, names: _ko, lang: 'ko', question: q);

void main() {
  group('v3.json 정답', () {
    final v3 = _load('v3');

    test('257문항 · id 가 겹치지 않고 32갈래·8언어를 다 덮는다', () {
      expect(v3, hasLength(257));
      expect({for (final c in v3) c['id']}, hasLength(257));
      expect({for (final c in v3) c['cat']}, hasLength(32));
      expect(
        {for (final c in v3) c['lang']},
        {'ko', 'en', 'ja', 'zh_Hans', 'zh_Hant', 'es', 'vi', 'th'},
      );
      for (final c in v3) {
        expect(c['names'], hasLength(20), reason: '${c['id']}');
        expect(c['gold'], isNotEmpty, reason: '${c['id']}');
      }
    });

    test('모든 정답 대안이 문법을 지나고, never 는 안 적은 운동뿐이다', () {
      final notLogged = {for (final n in _notLogged) exerciseIdentity(n)};
      var plans = 0;
      for (final c in v3) {
        final names = (c['names'] as List).cast<String>();
        for (final g in c['gold'] as List) {
          final Map<String, Object?> shape;
          try {
            shape = planShape(
              g,
              names: names,
              lang: c['lang'] as String,
              question: c['q'] as String,
              fuzzy: false,
            );
          } on FormatException catch (e) {
            fail('${c['id']} ${jsonEncode(g)}: ${e.message}');
          }
          plans++;
          for (final n in (shape['never'] as List?) ?? const []) {
            expect(notLogged, contains(n), reason: '${c['id']} never $n');
          }
        }
      }
      // ignore: avoid_print
      print('v3 정답 $plans 개 모두 문법 통과');
    });

    test('정답 대안은 모델 답으로 넣어도(이름 퍼지 켬) 맞음이고 지표가 서지 않는다', () {
      final flagged = <String>[];
      for (final c in v3) {
        for (final g in c['gold'] as List) {
          final grade = gradePlan(
            g,
            c['gold'] as List,
            names: (c['names'] as List).cast<String>(),
            lang: c['lang'] as String,
            question: c['q'] as String,
            ignore: (c['ignore'] as List?) ?? const [],
          );
          final v = verdicts(grade);
          if (!v.contains('exact') ||
              v.length > 1 && !v.every({'exact', 'refused'}.contains)) {
            flagged.add('${c['id']} ${jsonEncode(g)} → ${grade.errors} $v');
          }
        }
      }
      expect(flagged, isEmpty);
    });
  });

  group('옛 모음 정답을 v3 로', () {
    test('v2.json: compare → series, missing·clarify 는 v3 정답, 모두 문법 통과', () {
      final v2 = _load('v2');
      expect(v2, hasLength(212));
      expect(v2.where((c) => c['contaminated'] == true), hasLength(15));
      for (final c in v2) {
        final gold = v3Gold(c);
        expect(
          jsonEncode(gold),
          isNot(contains('"compare"')),
          reason: c['q'] as String,
        );
        for (final g in gold) {
          expect(
            (g as Map)['kind'],
            isNot(anyOf('missing', 'clarify')),
            reason: c['q'] as String,
          );
          final names = seedNames(c['lang'] as String);
          expect(
            () => planShape(
              g,
              names: names,
              lang: c['lang'] as String,
              fuzzy: false,
            ),
            returnsNormally,
            reason: '${c['q']} ${jsonEncode(g)}',
          );
          final grade = gradePlan(
            g,
            gold,
            names: names,
            lang: c['lang'] as String,
            ignore: (c['ignore'] as List?) ?? const [],
          );
          expect(grade.errors, isEmpty, reason: '${c['q']} ${jsonEncode(g)}');
        }
      }
    });

    test('dev·heldout: v1 정답 → 대안이 모두 문법 통과', () {
      const koNames = [
        '스쿼트',
        '벤치프레스',
        '데드리프트',
        '랫풀다운',
        '레그프레스',
        '바벨로우',
        '덤벨컬',
        '사이드레터럴레이즈',
        '오버헤드프레스',
        '케이블 푸시다운',
        '푸시업',
      ];
      for (final set in ['dev', 'heldout']) {
        var graded = 0;
        for (final c in _load(set)) {
          final gold = v2Expected((c['expected'] as Map).cast());
          if (gold == null) continue;
          graded++;
          for (final g in v3Alternatives(gold)) {
            expect(
              () => planShape(g, names: koNames, lang: 'ko', fuzzy: false),
              returnsNormally,
              reason: '$set ${c['q']} ${jsonEncode(g)}',
            );
          }
        }
        expect(graded, greaterThan(280), reason: set);
      }
    });

    test('날·주 묶음 평균은 per 로도 받는다, compare 는 series 가 된다', () {
      expect(
        v3Alternatives([
          {
            'by': 'week',
            'measures': ['trainingDays'],
            'total': 'mean',
          },
          {
            'exercises': ['스쿼트'],
            'compare': [
              {'period': 'lastMonth'},
              {'period': 'thisMonth'},
            ],
          },
        ]),
        [
          {
            'by': 'week',
            'measures': ['trainingDays'],
            'total': 'mean',
          },
          {
            'measures': ['trainingDays'],
            'per': 'week',
          },
          {
            'exercises': ['스쿼트'],
            'series': [
              {'period': 'lastMonth'},
              {'period': 'thisMonth'},
            ],
          },
        ],
      );
    });
  });

  group('문법 (grammar_check.py 의 거절 11개 + 검토가 더한 것)', () {
    final bad = <String, Object?>{
      'series 0개': {'series': []},
      '없는 측정': {
        'measures': ['bodyweight'],
      },
      '달 묶음 + 측정 둘': {
        'by': 'month',
        'measures': ['best', 'volume'],
      },
      '줄 없는 order': {'order': 'desc'},
      'per + best': {
        'per': 'day',
        'measures': ['best'],
      },
      'hours from=to': {
        'hours': {'from': 5, 'to': 5},
      },
      'share + best': {
        'relate': 'share',
        'measures': ['best'],
        'by': 'exercise',
      },
      'compare 키': {'compare': []},
      '두 series 주 묶음 + 측정 둘': {
        'by': 'week',
        'series': [
          {'period': 'lastMonth'},
          {'period': 'thisMonth'},
        ],
        'measures': ['best', 'volume'],
      },
      'trained + 세트 수': {
        'trained': false,
        'measures': ['setCount'],
      },
      'hours + 섭취': {
        'hours': {'from': 5, 'to': 11},
        'measures': ['intake'],
      },
      'kind missing': {'kind': 'missing'},
      '운동 축 운동일수 비중(gap 12)': {
        'by': 'exercise',
        'measures': ['trainingDays'],
        'relate': 'share',
      },
      '운동일수 per day': {
        'per': 'day',
        'measures': ['trainingDays'],
      },
      '창 없는 shift': {
        'shift': {'years': 1},
      },
      'sessions + nth': {'sessions': 1, 'nth': 2},
      '같은 series 둘': {
        'series': [
          {'period': 'lastMonth'},
          {'since': '2026-08-01', 'until': '2026-08-31'},
        ],
      },
      '빈 custom': {'period': 'custom'},
      '거꾸로 된 날짜': {'since': '2026-09-01', 'until': '2026-08-01'},
      'days + thisMonth': {'period': 'thisMonth', 'days': 7},
      '측정 중복': {
        'measures': ['best', 'best'],
      },
      '날 묶음 + latest': {
        'by': 'day',
        'measures': ['latest'],
      },
      '항목 안의 다른 by': {
        'series': [
          {'by': 'week'},
          {'by': 'month'},
        ],
      },
      '무게 없는 against': {
        'exercises': ['벤치프레스'],
        'measures': ['trainingDays'],
        'against': {'value': 100},
      },
    };
    for (final MapEntry(:key, :value) in bad.entries) {
      test('무효: $key', () {
        expect(() => _shape(value), throwsFormatException);
      });
    }

    test('against 의 수는 질문 글에 있어야 한다(지어낸 수 막기, gap 16)', () {
      final plan = {
        'exercises': ['벤치프레스'],
        'measures': ['best'],
        'against': {'value': 100, 'unit': 'kg'},
      };
      expect(_shape(plan, q: '벤치 100 목표까지 얼마나')['against'], {
        'value': 100.0,
        'unit': 'kg',
      });
      expect(() => _shape(plan, q: '벤치 목표까지 얼마나'), throwsFormatException);
    });

    test('검토가 더한 어휘는 받는다', () {
      for (final plan in [
        {
          'per': 'month',
          'measures': ['trainingDays'],
        },
        {
          'exercises': ['벤치프레스'],
          'nth': 2,
        },
        {
          'exercises': ['벤치프레스'],
          'measures': ['best'],
          'handoff': false,
        },
        {
          'memoAll': ['컨디션', '안 좋'],
          'measures': ['trainingDays'],
        },
        {
          'period': 'thisWeek',
          'measures': ['intake', 'burned', 'balance'],
        },
        {
          'by': 'exercise',
          'measures': ['sessionsSinceBest'],
          'order': 'desc',
          'limit': 5,
        },
        {
          'by': 'week',
          'measures': ['trainingDays'],
          'total': 'sum',
        },
        {
          'notComputable': ['심박'],
        },
        {'kind': 'unrelated'},
        {
          'type': 'json_object',
          'content': {
            'measures': ['best'],
          },
        },
      ]) {
        expect(() => _shape(plan), returnsNormally, reason: jsonEncode(plan));
      }
    });
  });

  group('모양 — 뜻이 같으면 같다', () {
    test('기간 이름과 날짜, 오늘 뒤의 끝, shift 단위', () {
      String window(Object plan) =>
          jsonEncode((_shape(plan)['series'] as List).single);
      expect(
        window({'period': 'lastMonth'}),
        window({'since': '2026-08-01', 'until': '2026-08-31'}),
      );
      expect(
        window({'period': 'thisMonth'}),
        window({'since': '2026-09-01', 'until': '2026-09-30'}),
      );
      expect(window({'period': 'all'}), window({}));
      expect(
        jsonEncode(
          _shape({
            'period': 'recent',
            'days': 28,
            'series': [
              {
                'shift': {'weeks': 4},
              },
              {},
            ],
          }),
        ),
        jsonEncode(
          _shape({
            'period': 'recent',
            'days': 28,
            'series': [
              {
                'shift': {'days': 28},
              },
              {},
            ],
          }),
        ),
      );
      // 달을 밀면 그달 끝으로 당긴다: 3/31 − 1달 = 2/28.
      final shifted =
          (_shape({
                        'since': '2026-03-31',
                        'until': '2026-03-31',
                        'shift': {'months': 1},
                      })['series']
                      as List)
                  .single
              as Map;
      expect(
        [shifted['since'], shifted['until']],
        ['2026-02-28', '2026-02-28'],
      );
      // 작년 이맘때: 최근 30일을 1년 민다.
      final year =
          (_shape({
                    'period': 'recent',
                    'days': 30,
                    'series': [
                      {
                        'shift': {'years': 1},
                      },
                      {},
                    ],
                  })['series']
                  as List)
              .cast<Map>();
      expect(
        {for (final s in year) '${s['since']}–${s['until']}'},
        {'2025-08-11–2025-09-09', '2026-08-11–2026-09-09'},
      );
    });

    test('윗단 이름 여럿 = 이름마다 series, 지목한 by exercise 는 지운다', () {
      final a = jsonEncode(
        _shape({
          'exercises': ['벤치프레스', '스쿼트'],
          'measures': ['best'],
        }),
      );
      expect(
        jsonEncode(
          _shape({
            'series': [
              {
                'exercises': ['스쿼트'],
                'measures': ['best'],
              },
              {
                'exercises': ['벤치프레스'],
                'measures': ['best'],
              },
            ],
          }),
        ),
        a,
      );
      expect(
        jsonEncode(
          _shape({
            'by': 'exercise',
            'exercises': ['벤치프레스', '스쿼트'],
            'measures': ['best'],
          }),
        ),
        a,
      );
    });

    test('이름 × series 는 by exercise 표다', () {
      final s = _shape({
        'exercises': ['벤치프레스', '스쿼트'],
        'series': [
          {'period': 'lastMonth'},
          {'period': 'thisMonth'},
        ],
      });
      expect(s['by'], 'exercise');
      expect(((s['series'] as List).first as Map)['measures'], ['best']);
    });

    test('이름은 언어가 달라도 같은 운동이다 — 기록 이름은 풀이 표에서', () {
      expect(
        _grade(
          {
            'exercises': ['Bench Press', 'スクワット'],
            'measures': ['best'],
          },
          [
            {
              'exercises': ['벤치프레스', '스쿼트'],
              'measures': ['best'],
            },
          ],
        ).errors,
        isEmpty,
      );
      expect(exerciseIdentity('덤벨프레스'), '덤벨 프레스');
      expect(exerciseIdentity('pull-up'), '풀업');
    });

    test('지목 안 한 운동 줄은 첫 칸 내림차순 10줄, nth 1 은 마지막 1일, [22, 0) 은 [22, 24)', () {
      expect(
        jsonEncode(
          _shape({
            'by': 'exercise',
            'measures': ['best'],
          }),
        ),
        jsonEncode(
          _shape({
            'by': 'exercise',
            'measures': ['best'],
            'order': 'desc',
            'limit': 10,
          }),
        ),
      );
      expect(
        jsonEncode(
          _shape({
            'exercises': ['벤치프레스'],
            'nth': 1,
          }),
        ),
        jsonEncode(
          _shape({
            'exercises': ['벤치프레스'],
            'sessions': 1,
          }),
        ),
      );
      expect(
        ((_shape({
                      'hours': {'from': 22, 'to': 0},
                    })['series']
                    as List)
                .single
            as Map)['hours'],
        {'from': 22, 'to': 24},
      );
    });

    test('series 순서는 ratio 에서만 뜻이다', () {
      final gold = [
        {
          'exercises': ['벤치프레스', '스쿼트'],
          'measures': ['best'],
          'relate': 'ratio',
        },
      ];
      expect(
        _grade({
          'exercises': ['스쿼트', '벤치프레스'],
          'measures': ['best'],
          'relate': 'ratio',
        }, gold).errors,
        ['seriesOrder'],
      );
      expect(
        _grade(
          {
            'exercises': ['스쿼트', '벤치프레스'],
            'measures': ['best'],
          },
          [
            {
              'exercises': ['벤치프레스', '스쿼트'],
              'measures': ['best'],
            },
          ],
        ).errors,
        isEmpty,
      );
    });

    test('측정 순서는 순위의 첫 칸일 때만, 메모 어간·시간대 경계는 너그럽게', () {
      expect(
        _grade(
          {
            'exercises': ['스쿼트'],
            'measures': ['trainingDays', 'best'],
          },
          [
            {
              'exercises': ['스쿼트'],
              'measures': ['best', 'trainingDays'],
            },
          ],
        ).errors,
        isEmpty,
      );
      expect(
        _grade(
          {
            'by': 'exercise',
            'measures': ['trainingDays', 'best'],
            'order': 'desc',
          },
          [
            {
              'by': 'exercise',
              'measures': ['best', 'trainingDays'],
              'order': 'desc',
            },
          ],
        ).errors,
        ['series.measures'],
      );
      expect(
        _grade(
          {
            'exercises': ['벤치프레스'],
            'memo': ['컨디션 안 좋'],
          },
          [
            {
              'exercises': ['벤치프레스'],
              'memo': ['컨디션'],
            },
          ],
        ).errors,
        isEmpty,
      );
      expect(
        _grade(
          {
            'hours': {'from': 6, 'to': 11},
            'measures': ['trainingDays'],
          },
          [
            {
              'hours': {'from': 5, 'to': 11},
              'measures': ['trainingDays'],
            },
          ],
        ).errors,
        isEmpty,
      );
      expect(
        _grade(
          {
            'hours': {'from': 8, 'to': 11},
            'measures': ['trainingDays'],
          },
          [
            {
              'hours': {'from': 5, 'to': 11},
              'measures': ['trainingDays'],
            },
          ],
        ).errors,
        ['series.hours'],
      );
    });
  });

  group('지표', () {
    final withRow = [
      {
        'exercises': ['벤치프레스', '바벨로우'],
        'measures': ['best'],
      },
    ];

    test('swapped: 안 적은 바벨로우 대신 기록의 시티드 로우를 셌다', () {
      final v = verdicts(
        _grade({
          'exercises': ['벤치프레스', '시티드 로우'],
          'measures': ['best'],
        }, withRow),
      );
      expect(v, containsAll(['swapped', 'confidentlyWrong']));
      expect(verdicts(_grade(withRow.single, withRow)), {'exact'});
    });

    test('dictSwap: 안 적은 운동을 다른 안 적은 운동으로', () {
      final v = verdicts(
        _grade({
          'exercises': ['벤치프레스', '힙쓰러스트'],
          'measures': ['best'],
        }, withRow),
      );
      expect(v, containsAll(['dictSwap', 'confidentlyWrong']));
      expect(v, isNot(contains('swapped')));
    });

    test('falseNever: 적은 운동을 안 적은 이름으로', () {
      final v = verdicts(
        _grade(
          {
            'exercises': ['딥스'],
            'measures': ['best'],
          },
          [
            {
              'exercises': ['벤치프레스'],
              'measures': ['best'],
            },
          ],
        ),
      );
      expect(v, contains('falseNever'));
    });

    test('deadEnd: 셀 것이 있는 질문을 거절했다 — 셀 것이 없는 질문의 거절은 맞음', () {
      final gold = [
        {
          'exercises': ['데드리프트'],
          'measures': ['best'],
          'notComputable': ['체중'],
        },
      ];
      expect(
        verdicts(_grade({'kind': 'clarify'}, gold)),
        containsAll(['deadEnd', 'refused']),
      );
      expect(
        verdicts(
          _grade({
            'notComputable': ['체중'],
          }, gold),
        ),
        contains('deadEnd'),
      );
      expect(
        verdicts(
          _grade(
            {
              'notComputable': ['heart rate'],
            },
            [
              {
                'notComputable': ['심박'],
              },
            ],
          ),
        ),
        {'exact', 'refused'},
      );
    });

    test('ncMissed / ncFalse: 못 보는 것 한 줄의 있음·없음만 본다', () {
      final gold = [
        {
          'exercises': ['데드리프트'],
          'measures': ['best'],
          'notComputable': ['체중'],
        },
      ];
      expect(
        verdicts(
          _grade({
            'exercises': ['데드리프트'],
            'measures': ['best'],
          }, gold),
        ),
        containsAll(['ncMissed', 'confidentlyWrong']),
      );
      expect(
        verdicts(
          _grade({
            'exercises': ['데드리프트'],
            'measures': ['best'],
            'notComputable': ['몸무게'],
          }, gold),
        ),
        {'exact'},
      );
      expect(
        verdicts(
          _grade(
            {
              'exercises': ['데드리프트'],
              'measures': ['best'],
              'notComputable': ['x'],
            },
            [
              {
                'exercises': ['데드리프트'],
                'measures': ['best'],
              },
            ],
          ),
        ),
        contains('ncFalse'),
      );
    });

    test('무효는 FormatException, 틀린 정답은 StateError', () {
      expect(() => _grade({'compare': []}, withRow), throwsFormatException);
      expect(
        () => _grade(withRow.single, [
          {
            'measures': ['bodyweight'],
          },
        ]),
        throwsStateError,
      );
    });
  });
}
