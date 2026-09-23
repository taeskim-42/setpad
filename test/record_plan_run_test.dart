import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/exercises.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/stats.dart';

/// 기록 검색 v3 실행기 — 고정 기록으로 모델 없이. 검토(search-v3-critique)의 막다른
/// 길·자신 있게 틀린 숫자 28가지를 하나씩 못 박는다. 테스트 이름의 G 번호가 그 검토의
/// 갈래 번호다. 오늘은 2026-09-09(수) 21시, 단위는 kg.
void main() {
  setUpAll(() => initializeDateFormatting());
  final l = lookupL(const Locale('ko'));
  final today = DateTime(2026, 9, 9, 21);
  LoggedSet s(
    double? v,
    int? r, {
    String u = 'kg',
    bool done = true,
    String? memo,
    String? author,
  }) => LoggedSet(
    value: v,
    unit: u,
    reps: r,
    done: done,
    notes: memo == null ? null : [memo],
    author: author,
  );
  Note n(
    String id,
    int month,
    int day,
    int hour,
    List<ExerciseBlock> blocks, {
    int minute = 0,
    String? partner,
    bool invited = false,
    String? routine,
    String? handoff,
    double? calories,
    List<MealEntry> meals = const [],
  }) {
    final at = DateTime(2026, month, day, hour, minute);
    final note = Note(
      id: id,
      createdAt: at,
      updatedAt: at,
      blocks: blocks,
      calories: calories,
      routineId: routine,
    );
    if (partner != null || invited) {
      note.partner = PartnerSession(
        id: 'p$id',
        host: true,
        state: partner == null ? PartnerState.expired : PartnerState.ended,
        partnerName: partner,
      );
    }
    note.handoffToken = handoff;
    note.meals.addAll(meals);
    return note;
  }

  MealEntry meal(int month, int day, int hour, int? kcal) =>
      MealEntry(at: DateTime(2026, month, day, hour), kcal: kcal);

  // 이름은 사람이 친 그대로다: '벤치'·'Bench Press' 는 벤치프레스, '스쾃' 은 스쿼트,
  // '푸시업 60bpm' 은 타이머 제목, '민수식 로우' 는 사전에 없는 이름.
  final fixture = [
    n('A1', 8, 3, 7, [
      ExerciseBlock('벤치', [s(60, 10), s(62.5, 8)]),
      ExerciseBlock('스쾃', [s(100, 5), s(100, 5)]),
    ]),
    n('A2', 8, 5, 19, [
      ExerciseBlock('Bench Press', [s(65, 5)]),
      ExerciseBlock('풀업', [s(null, 10), s(10, 6)]),
      ExerciseBlock('러닝', [s(5, null, u: 'km'), s(30, null, u: 'min')]),
    ]),
    n('A3', 8, 10, 7, [
      ExerciseBlock('벤치', [s(67.5, 5)]),
      ExerciseBlock('데드리프트', [s(140, 3, memo: '허리 뻐근')]),
    ]),
    n('A4', 8, 12, 20, routine: 'r1', [
      ExerciseBlock('스쾃', [s(110, 3)]),
      ExerciseBlock('민수식 로우', [s(50, 10)]),
    ]),
    n('A5', 8, 24, 23, minute: 30, partner: 'Kim', [
      ExerciseBlock('벤치', [s(70, 3)]),
      ExerciseBlock('크런치', [s(null, 20)]),
    ]),
    n(
      'A6',
      8,
      26,
      6,
      invited: true,
      meals: [meal(8, 26, 12, 600)],
      [
        ExerciseBlock('데드리프트', [s(150, 2, memo: '컨디션 좋음')]),
      ],
    ),
    n('A7', 9, 1, 19, [
      ExerciseBlock('푸시업 60bpm', [s(null, 30)]),
      ExerciseBlock('버피 타바타 30/15 10라운드', [s(null, 10)]),
    ]),
    n('A8', 9, 2, 19, handoff: 'h1', [
      ExerciseBlock('벤치', [s(72.5, 2)]),
    ]),
    n('A9', 9, 3, 19, [
      ExerciseBlock('스쾃', [s(115, 2, memo: '컨디션 별로')]),
      ExerciseBlock('풀업', [s(null, 12)]),
      ExerciseBlock('벤치', [s(80, 1, author: 'Lee')]),
    ]),
    n('M1', 9, 5, 12, meals: [meal(9, 5, 12, 800)], []),
    n(
      'A10',
      9,
      7,
      7,
      minute: 30,
      calories: 300,
      meals: [meal(9, 7, 8, 500), meal(9, 7, 12, null)],
      [
        ExerciseBlock('푸시업', [s(null, 20), s(null, 15)]),
        ExerciseBlock('데드리프트', [s(155, 1)]),
      ],
    ),
    n(
      'A11',
      9,
      8,
      19,
      calories: 250,
      meals: [meal(9, 8, 12, 700)],
      [
        ExerciseBlock('레그프레스', [s(100, 10, done: false)]),
        ExerciseBlock('벤치', [s(75, 1)]),
        ExerciseBlock('스쾃', [s(105, 5)]),
      ],
    ),
  ];
  final names = recordedExercises(fixture);

  RecordQuery plan(Map<String, Object?> raw, {String question = ''}) =>
      RecordQuery.decode(raw, names, today: today, question: question);
  RecordResult run(Map<String, Object?> raw, {String question = ''}) => runPlan(
    plan(raw, question: question),
    fixture,
    l: l,
    unit: 'kg',
    today: today,
    confirmed: true,
  )!;
  List<(String, double?)> column(RecordResult r, [int j = 0]) => [
    for (final row in r.rows) (row.label, row.cells[j].answer?.numericValue),
  ];

  test('G28: 기록한 운동은 해낸 세트가 있는 운동이다 — 계획만 있는 칸은 "적은 적 없음"', () {
    expect(names, isNot(contains('레그프레스')));
    final q = plan({
      'exercises': ['레그프레스'],
      'measures': ['trainingDays'],
    });
    expect(q.never, {'레그프레스'});
    final r = run({
      'exercises': ['레그프레스'],
      'measures': ['trainingDays'],
    });
    final c = r.rows.single.cells.single;
    expect((c.reason, c.answer!.numericValue), ('never', 0));
    expect(c.answer!.lines, [l.queryNeverMark]);
    expect(r.header, [l.queryNeverRows('레그프레스')]);
  });

  test('G2: 이름 정체성 — 벤치·Bench Press 는 한 운동으로 세고, 확인 줄이 합친 이름을 보인다', () {
    final r = run({
      'exercises': ['벤치프레스'],
      'measures': ['trainingDays', 'best'],
    });
    expect(r.rows.single.label, '벤치프레스');
    final [days, best] = r.rows.single.cells;
    expect(days.answer!.numericValue, 6);
    expect(best.answer!.numericValue, 75);
    // 영어로 물어도, 줄여 물어도 같은 운동이다.
    for (final said in ['Bench Press', '벤치', '卧推']) {
      final q = plan({
        'exercises': [said],
        'measures': ['trainingDays'],
      });
      expect(q.never, isEmpty, reason: said);
      expect(q.series.single.scope.exercises, ['벤치프레스'], reason: said);
    }
    final text = describePlan(
      plan({
        'exercises': ['벤치프레스'],
      }),
      l,
      'kg',
      notes: fixture,
    );
    expect(text, contains(l.queryAlias('벤치프레스', 'Bench Press·벤치')));
    // 부위도 이 표로 푼다 — '벤치' 는 가슴이다.
    expect(partOf(exerciseKey('벤치')), 'chest');
    expect(exerciseKey('스쾃'), '스쿼트');
    expect(exerciseKey('데드'), '데드리프트');
    expect(exerciseKey('민수식 로우'), '민수식 로우');
  });

  test('G3: 타이머 제목의 통계 이름은 타이머 토큰을 뺀 이름이다 — 푸시업 + bpm', () {
    expect(statName('푸시업 60bpm'), '푸시업');
    expect(statName('버피 타바타 30/15 10라운드'), '버피');
    expect(statName('벤치프레스'), '벤치프레스');
    Map<String, Object?> pushups(String? timer) => {
      'exercises': ['푸시업'],
      'timer': ?timer,
      'measures': ['repCount'],
    };
    expect(
      run(pushups('bpm')).rows.single.cells.single.answer!.numericValue,
      30,
    );
    expect(
      run(pushups('none')).rows.single.cells.single.answer!.numericValue,
      35,
    );
    expect(
      run(pushups(null)).rows.single.cells.single.answer!.numericValue,
      65,
    );
    // 운동별 줄에서도 '푸시업' 과 '푸시업 60bpm' 은 한 줄이다.
    final rows = run({
      'by': 'exercise',
      'measures': ['repCount'],
      'period': 'thisMonth',
    }).rows.map((r) => r.label);
    expect(rows.where((x) => x.startsWith('푸시업')), ['푸시업']);
    expect(rows, contains('버피'));
  });

  test('G4: 사전 퍼지는 이름을 바꾸지 않는다 — 클린은 크런치가 아니고, 바밸로우는 "혹시 바벨로우?"', () {
    final clean = plan({
      'exercises': ['스쿼트', '클린'],
      'measures': ['best'],
    });
    expect(clean.never, {'클린'});
    expect(clean.series.map((s) => s.scope.exercises.single), ['스쿼트', '클린']);
    final typo = plan({
      'exercises': ['바밸로우'],
      'measures': ['best'],
    });
    expect(typo.never, {'바밸로우'});
    // 사전에서 온 제안은 기록에 없는 운동이라 칩이 아니라 확인 줄의 글이다.
    expect(typo.suggested['바밸로우'], '바벨로우');
    expect(typo.maybe['바밸로우'] ?? const <String>[], isNot(contains('바벨로우')));
    expect(
      describePlan(typo, l, 'kg'),
      contains('바밸로우 (${l.queryNeverMark}) ${l.queryMaybe('바벨로우')}'),
    );
    // 기록에 있는 운동의 오타는 그 운동이다 — 무엇으로 읽었는지 남긴다.
    final squat = plan({
      'exercises': ['스쿼드'],
      'measures': ['best'],
    });
    expect(squat.never, isEmpty);
    expect(squat.series.single.scope.exercises, ['스쿼트']);
    expect(squat.readAs, {'스쾃': '스쿼드'});
    // "이 운동 말이에요?" — 한 번 누르면 원판 없이 다시 센다.
    final swapped = typo.withName('바밸로우', '민수식 로우');
    expect(swapped.never, isEmpty);
    // 이름만 바꿨다 — 기간·측정은 모델이 읽은 것이라 확인은 그대로다.
    expect(swapped.requiresConfirmation, typo.requiresConfirmation);
    final r = runPlan(
      swapped,
      fixture,
      l: l,
      unit: 'kg',
      today: today,
      confirmed: true,
    )!;
    expect(r.rows.single.cells.single.answer!.numericValue, 50);
  });

  test('G1: 합친 칸은 운동별로 센 뒤 합친다 — 맨몸 세트는 빼고, 값이 빠진 운동은 "… 제외"', () {
    final r = run({
      'measures': ['volume', 'setCount'],
      'series': [
        {'part': 'upper'},
        {'part': 'lower'},
      ],
    });
    expect(r.rows.map((row) => row.label), [
      l.queryPart('upper'),
      l.queryPart('lower'),
    ]);
    final upper = r.rows.first.cells;
    // 벤치 2192.5 + 데드 875 + 풀업 무게 세트 60 = 3127.5. 푸시업은 무게가 없어 대상 아님.
    expect(upper[0].answer!.numericValue, 3127.5);
    expect(upper[0].answer!.lines.first, l.queryNoWeightSets(2, 12));
    expect(upper[1].answer!.numericValue, 16);
    expect(r.rows.last.cells[0].answer!.numericValue, 2085);
    expect(r.rows.last.cells[1].answer!.numericValue, 5);
    expect(r.footnotes, [
      l.queryUnknownPart('민수식 로우'),
      l.queryOutOfScope('푸시업'),
    ]);
    // 반복 없는 무게 세트가 든 운동은 합에서 빼고 칸이 말한다(0 이나 조용한 부분합이 아니다).
    final partial = runPlan(
      plan({
        'exercises': ['벤치프레스', '데드리프트'],
        'measures': ['setCount'],
      }),
      [
        ...fixture,
        n('X', 9, 9, 8, [
          ExerciseBlock('데드리프트', [s(160, null)]),
        ]),
      ],
      l: l,
      unit: 'kg',
      today: today,
      confirmed: true,
    )!;
    expect(column(partial), [('벤치프레스', 7), ('데드리프트', 4)]);
    final pooled = runPlan(
      plan({
        'measures': ['volume'],
        'series': [
          {
            'exercises': ['벤치프레스', '데드리프트'],
          },
        ],
      }),
      [
        ...fixture,
        n('X', 9, 9, 8, [
          ExerciseBlock('데드리프트', [s(160, null)]),
        ]),
      ],
      l: l,
      unit: 'kg',
      today: today,
      confirmed: true,
    )!;
    final cell = pooled.rows.single.cells.single;
    expect(cell.answer!.numericValue, 2192.5);
    expect(cell.excluded, {'데드리프트'});
    expect(cell.answer!.lines.first, l.queryPartial('데드리프트'));
    expect(pooled.footnotes, contains(l.queryMissingFor('데드리프트')));
  });

  test('G1-3: 순위에 값이 빠진 줄이 있으면 본문 줄로 말한다', () {
    final r = runPlan(
      plan({
        'by': 'exercise',
        'measures': ['volume'],
        'order': 'desc',
        'limit': 1,
      }),
      [
        ...fixture,
        n('X', 9, 9, 8, [
          ExerciseBlock('데드리프트', [s(160, null)]),
        ]),
      ],
      l: l,
      unit: 'kg',
      today: today,
      confirmed: true,
    )!;
    expect(r.rows.single.label, '벤치프레스');
    expect(r.lines, contains(l.queryUnranked(1, '데드리프트')));
  });

  test('G5: 길이가 다른 창은 주당으로 견주고, 진행 중인 달은 같은 날 수로도 견준다', () {
    final r = run({
      'measures': ['trainingDays'],
      'series': [
        {'period': 'thisMonth'},
        {'period': 'lastMonth'},
      ],
    });
    // 기간만 다른 series 는 날짜순이다.
    final ongoing = '2026-09-01 – 2026-09-09 · ${l.queryOngoing}';
    expect(column(r), [('2026-08-01 – 2026-08-31', 6), (ongoing, 5)]);
    // 날 수가 다른 창은 가능한 날 중 몇 % 도 보인다.
    expect(
      r.rows.first.cells.single.answer!.lines.first,
      l.queryPossibleDays(31, '≈19.35'),
    );
    // 31일과 9일을 그대로 빼지 않는다 — 주당으로 견준다(원래 합은 칸에 그대로).
    expect(r.lines.first, contains('≈+2.53일/주'));
    expect(
      r.lines,
      contains(
        l.querySamePeriod(
          9,
          '2026-08-01 – 2026-08-31 ${l.answerDays(2)}',
          '$ongoing ${l.answerDays(5)}',
        ),
      ),
    );
    expect(r.footnotes, contains(l.queryWindowLengths('31 · 9')));
  });

  test('G6: 규칙 4 는 기간만 다를 때만 접는다 — 올해 초 스쿼트랑 요즘 레그프레스', () {
    final q = plan({
      'measures': ['best'],
      'series': [
        {
          'exercises': ['스쿼트'],
          'since': '2026-01-01',
          'until': '2026-02-28',
        },
        {
          'exercises': ['레그프레스'],
          'period': 'recent',
          'days': 28,
        },
      ],
    }, question: '올해 초 스쿼트랑 요즘 레그프레스 무게');
    expect(q.series.map((s) => s.scope.since), [
      DateTime(2026, 1, 1),
      DateTime(2026, 8, 13),
    ]);
  });

  test('G7: 성장은 속도(%/주)로 순위를 매기고, 짧은 기록은 빼고 말한다', () {
    final r = run({
      'by': 'exercise',
      'measures': ['changePct'],
      'order': 'desc',
      'limit': 5,
    });
    expect(r.rows.map((row) => row.label), ['벤치프레스', '데드리프트', '스쾃']);
    final bench = r.rows.first.cells.single.answer!;
    expect(bench.numericValue, 20);
    expect(bench.rate, closeTo(20 / 6, 1e-9));
    expect(r.footnotes, contains(l.queryGrowthRate));
    expect(r.footnotes, contains(l.queryShortGrowth('민수식 로우, 풀업')));
  });

  test('G8: 0 으로 채운 칸은 단위를 알고, 차이도 낸다 — 개수형 주 묶음은 0 인 주를 센다', () {
    final r = run({
      'exercises': ['데드리프트', '케틀벨 스윙'],
      'measures': ['trainingDays'],
    });
    expect(column(r), [('데드리프트', 3), ('케틀벨 스윙', 0)]);
    expect(r.rows.last.cells.single.answer!.unit, l.queryDayUnit);
    expect(r.lines.single, contains('-3일'));
    expect(r.header, [l.queryNeverRows('케틀벨 스윙')]);
    final weeks = run({
      'exercises': ['데드리프트'],
      'by': 'week',
      'period': 'lastMonth',
      'measures': ['trainingDays'],
    });
    expect(weeks.render, 'chart');
    expect(column(weeks).map((c) => c.$2), [0, 0, 1, 0, 1, 0]);
    // 0 인 주도 점이 있다 — 빠진 주가 차트에서 사라지지 않는다.
    expect(weeks.rows.first.cells.single.answer!.points.single.value, 0);
    expect(weeks.lines, [l.queryZeroBuckets('week', 6, 4)]);
  });

  test('G9: 같이 한 날은 누가 들어온 날이다 — 초대만 하고 끝난 날은 혼자다', () {
    final r = run({
      'measures': ['trainingDays'],
      'series': [
        {'together': true},
        {'together': false},
      ],
    });
    expect(column(r).map((c) => c.$2), [2, 9]);
    expect(
      describePlan(
        plan({
          'together': true,
          'measures': ['trainingDays'],
        }),
        l,
        'kg',
        notes: fixture,
      ),
      contains('${l.queryTogether} ${l.queryDayCount(2)}'),
    );
  });

  test('G10: 메모 조건은 실제로 걸린 메모와 날 수를 확인 줄에 보이고, memoAll 은 모두 든 날만', () {
    final q = plan({
      'memo': ['컨디션'],
      'measures': ['trainingDays'],
    }, question: '컨디션 메모 쓴 날');
    expect(
      describePlan(q, l, 'kg', notes: fixture),
      contains(
        l.queryMemoHits(
          '${l.queryMemoHit('컨디션 좋음', 1)} · ${l.queryMemoHit('컨디션 별로', 1)}',
        ),
      ),
    );
    final all = run({
      'memo': ['컨디션', '별로'],
      'memoAll': true,
      'measures': ['trainingDays'],
    }, question: '컨디션 별로라고 적은 날');
    expect(all.rows.single.cells.single.answer!.numericValue, 1);
    expect(all.evidence, {'A9'});
    final without = run({
      'exercises': ['데드리프트'],
      'noMemo': ['허리'],
      'measures': ['trainingDays'],
    }, question: '허리 메모 없는 날 데드');
    expect(without.rows.single.cells.single.answer!.numericValue, 2);
  });

  test('G11: 건네받은 기록은 handoff 로 빼거나 고른다', () {
    Map<String, Object?> bench(bool handoff) => {
      'exercises': ['벤치프레스'],
      'handoff': handoff,
      'measures': ['trainingDays'],
    };
    expect(run(bench(false)).rows.single.cells.single.answer!.numericValue, 5);
    expect(run(bench(true)).rows.single.cells.single.answer!.numericValue, 1);
    expect(
      describePlan(plan(bench(false)), l, 'kg', notes: fixture),
      contains(l.queryHandoffCount(1)),
    );
  });

  test('G12: 운동일수의 합계는 겹치지 않게 세고, 운동별 비중은 내지 않는다', () {
    final sum = run({
      'exercises': ['벤치프레스', '데드리프트'],
      'measures': ['trainingDays'],
      'total': 'sum',
    });
    expect(column(sum), [('벤치프레스', 6), ('데드리프트', 3)]);
    expect(sum.total!.single.answer!.numericValue, 8, reason: '8/10 은 하루');
    final share = run({
      'by': 'exercise',
      'measures': ['trainingDays'],
      'relate': 'share',
    });
    expect(share.columns, [l.metricSessions, l.queryShare]);
    expect(share.rows.every((r) => r.cells[1].reason == 'overlap'), isTrue);
    expect(share.footnotes, contains(l.queryOverlap));
    // 세트 수 비중은 합이 100 이다.
    final sets = run({
      'by': 'exercise',
      'measures': ['setCount'],
      'relate': 'share',
    });
    final total = sets.rows.fold<double>(
      0,
      (t, r) => t + r.cells[1].answer!.numericValue!,
    );
    expect(total, closeTo(100, 1e-9));
  });

  test('G13: 관계가 있으면 날짜순으로 뒤집지 않는다 — 모델이 적은 기준이 먼저', () {
    final r = run({
      'measures': ['trainingDays'],
      'relate': 'ratio',
      'series': [
        {'period': 'thisMonth'},
        {'period': 'lastMonth'},
      ],
    });
    expect(column(r).map((c) => c.$1), [
      '2026-09-01 – 2026-09-09 · ${l.queryOngoing}',
      '2026-08-01 – 2026-08-31',
    ]);
    expect(
      r.lines.single,
      contains('2026-08-01 – 2026-08-31 ÷ 2026-09-01 – 2026-09-09'),
    );
    expect(
      describePlan(
        plan({
          'measures': ['trainingDays'],
          'relate': 'ratio',
          'series': [
            {'period': 'thisMonth'},
            {'period': 'lastMonth'},
          ],
        }),
        l,
        'kg',
      ),
      contains('÷'),
    );
  });

  test('G14: 연도 없이 적은 앞날 기간은 한 해 당기고, 캐시 열쇠에는 해가 든다', () {
    final feb = DateTime(2027, 2, 10);
    final raw = {
      'measures': ['trainingDays'],
      'series': [
        {'since': '2027-11-01', 'until': '2027-11-30'},
        {'since': '2027-12-01', 'until': '2027-12-31'},
      ],
    };
    final q = RecordQuery.decode(
      raw,
      names,
      today: feb,
      question: '11월이랑 12월 운동 며칠',
    );
    expect(q.series.map((s) => s.scope.since), [
      DateTime(2026, 11, 1),
      DateTime(2026, 12, 1),
    ]);
    expect(q.series.every((s) => s.scope.rolled), isTrue);
    expect(describePlan(q, l, 'kg'), contains(l.queryRolled('2026')));
    // 해를 적었으면 그대로 두고, 아직 오지 않은 기간이라고 말한다.
    final stated = RecordQuery.decode(
      raw,
      names,
      today: feb,
      question: '2027년 11월이랑 12월 운동 며칠',
    );
    final r = runPlan(
      stated,
      fixture,
      l: l,
      unit: 'kg',
      today: feb,
      confirmed: true,
    )!;
    expect(r.rows.map((row) => row.cells.single.reason), ['future', 'future']);
    expect(r.rows.first.cells.single.answer!.lines, [l.queryFutureCell]);
  });

  test('G15: 끝에서 N번째 운동일 — 오늘 vs 지난번', () {
    // 실제 질문 글로 부른다 — 규칙 층이 글의 '오늘' 을 모든 series 의 기간으로
    // 붙이면 끝에서 2번째 날이 늘 비었다(v3 재검토 R1).
    final r = run({
      'exercises': ['벤치프레스'],
      'measures': ['best'],
      'series': [
        {'nth': 2},
        {'nth': 1},
      ],
    }, question: '오늘 벤치 지난번보다 늘었어?');
    expect(column(r).map((c) => c.$2), [72.5, 75]);
    expect(r.rows.first.label, '${l.queryNth(2)} · 9월 2일');
    expect(r.lines.single, contains('+2.5kg'));
    expect(
      describePlan(
        plan({
          'exercises': ['벤치프레스'],
          'nth': 2,
        }),
        l,
        'kg',
        notes: fixture,
      ),
      contains('${l.queryNth(2)} 9월 2일'),
    );
  });

  test('G16: 질문에 적힌 기준 수와 견준다 — 지어낸 수는 버린다', () {
    final raw = {
      'exercises': ['데드리프트'],
      'measures': ['best'],
      'against': {'value': 80, 'unit': 'kg'},
    };
    final r = run(raw, question: '체중 80인데 데드 2배 넘었어?');
    expect(
      r.lines.single,
      l.queryAgainstLine('데드리프트 155kg × 1회', '80kg', '≈1.94', '+75kg'),
    );
    expect(plan(raw, question: '데드 체중의 2배 넘었어?').against, isNull);
  });

  test('G17: 섭취 − 소모는 둘 다 있는 날만 뺀다', () {
    final r = run({
      'period': 'thisMonth',
      'measures': ['balance', 'intake', 'burned'],
    });
    final [balance, intake, burned] = r.rows.single.cells;
    expect(balance.answer!.numericValue, 650);
    expect(balance.answer!.headline, '+650kcal');
    expect(balance.answer!.lines, [
      l.answerBothDays(2),
      l.answerIntakeOnlyDays(1),
    ]);
    expect(intake.answer!.numericValue, 2000);
    expect(intake.answer!.headline, l.answerAbout('2000kcal'));
    expect(intake.answer!.lines, [l.answerMealDays(3), l.queryUnknownMeals(1)]);
    expect(burned.answer!.numericValue, 550);
    // 쉰 날 먹은 것 / 운동한 날 먹은 것.
    final rest = run({
      'trained': false,
      'period': 'thisMonth',
      'measures': ['intake'],
    });
    expect(rest.rows.single.cells.single.answer!.numericValue, 800);
    final perDay = run({
      'trained': true,
      'period': 'thisMonth',
      'measures': ['intake'],
      'per': 'day',
    });
    expect(perDay.rows.single.cells.single.answer!.numericValue, 600);
  });

  test('G18: 유산소에 거리와 시간이 섞이면 종류별로 완결된 수를 보인다', () {
    final distance = run({
      'exercises': ['러닝'],
      'measures': ['distance'],
    }).rows.single.cells.single.answer!;
    expect(distance.headline, '5km');
    expect(distance.lines.first, l.queryOtherDuration(1, '30분'));
    final time = run({
      'exercises': ['러닝'],
      'measures': ['duration'],
    }).rows.single.cells.single.answer!;
    expect(time.headline, '30분');
    expect(time.lines.first, l.queryOtherDistance(1, '5km'));
  });

  test('G19: 정체는 최고 이후 한 운동일 수로 — 그만둔 운동이 위로 오지 않는다', () {
    final r = run({
      'by': 'exercise',
      'measures': ['sessionsSinceBest'],
      'order': 'desc',
      'limit': 1,
    });
    expect(r.rows.single.label, '스쾃');
    expect(r.rows.single.cells.single.answer!.numericValue, 1);
  });

  test('G20: "제일 적게 한" 개수형 순위는 안 한 운동도 0 으로 넣는다', () {
    final r = run({
      'period': 'thisMonth',
      'by': 'exercise',
      'measures': ['trainingDays'],
      'order': 'asc',
      'limit': 3,
    });
    expect(column(r), [('러닝', 0), ('민수식 로우', 0), ('크런치', 0)]);
    expect(r.footnotes, contains(l.queryZeroFilled));
  });

  test('G21: 창이 다른 series 의 주 묶음은 각 창의 시작부터 7일씩', () {
    final r = run({
      'by': 'week',
      'measures': ['trainingDays'],
      'series': [
        {'period': 'lastMonth'},
        {'period': 'thisMonth'},
      ],
    });
    expect(r.render, 'table');
    expect(r.rows.map((row) => row.label), [
      for (var i = 1; i <= 5; i++) l.queryRelative('week', i),
    ]);
    expect(
      [
        for (final row in r.rows)
          [for (final c in row.cells) c.answer?.numericValue],
      ],
      [
        [2, 4, 2],
        [2, 1, -1],
        [0, null, null],
        [2, null, null],
        [0, null, null],
      ],
    );
    expect(r.rows[1].cells[1].answer!.lines.first, l.queryPartialChunk(2));
    expect(r.rows[4].cells[0].answer!.lines.first, l.queryPartialChunk(3));
  });

  test('G22: 운동 간격은 중앙값이 헤드라인이다 — 긴 쉼 하나가 부풀리지 않는다', () {
    final gap = run({
      'measures': ['meanGap'],
    }).rows.single.cells.single.answer!;
    expect(gap.numericValue, 2);
    expect(gap.headline, l.answerEveryDays('2'));
    expect(gap.lines, [
      l.answerMeanEvery('3.6'),
      l.answerGapSpread(3, 3, 0, 4),
      l.answerLongestIncluded(11),
    ]);
    final streak = run({
      'measures': ['longestStreak', 'longestGap'],
    }).rows.single.cells;
    expect(streak[0].answer!.headline, l.answerStreak(3));
    expect(streak[1].answer!.headline, l.answerRestDays(11));
    expect(streak[1].answer!.lines.first, l.queryPeriod('8월 13일', '8월 23일'));
  });

  test('G23: series 안 이름 일부만 기록이 없으면 나머지로 세고 말한다', () {
    final r = run({
      'measures': ['setCount'],
      'series': [
        {
          'exercises': ['벤치프레스', '딥스'],
        },
        {
          'exercises': ['랫풀다운', '풀업'],
        },
      ],
    });
    expect(column(r).map((c) => c.$2), [7, 3]);
    expect(r.header, [l.queryNeverPartial('딥스, 랫풀다운')]);
    expect(r.never, ['딥스', '랫풀다운']);
  });

  test('G24: 달당 평균 — 진행 중인 달을 표시한다', () {
    final c = run({
      'measures': ['trainingDays'],
      'per': 'month',
    }).rows.single.cells.single.answer!;
    expect(c.numericValue, 5.5);
    expect(c.headline, '5.5일/달');
    expect(c.lines.first, '${l.answerMonths(2)} · ${l.queryOngoing}');
  });

  test('G25: 비율이 최고와 오면 추정 1RM 도 보이고, 줄마다 기준을 적는다', () {
    final q = plan({
      'exercises': ['벤치프레스', '데드리프트'],
      'measures': ['best'],
      'relate': 'ratio',
    });
    expect(q.measures, [Metric.best, Metric.e1rm]);
    final r = runPlan(
      q,
      fixture,
      l: l,
      unit: 'kg',
      today: today,
      confirmed: true,
    )!;
    expect(r.lines, [
      '${l.metricMax} · ${l.queryRatioLine('데드리프트', '벤치프레스', '≈2.07', '≈206.67')}',
      '${l.metricE1rm} · ${l.queryRatioLine('데드리프트', '벤치프레스', '2', '200')}',
    ]);
  });

  test('G26: 심박은 정직하게 — 기록 검색이 아직 안 본다', () {
    final r = run({
      'exercises': ['러닝'],
      'measures': ['distance'],
      'notComputable': ['심박', '페이스'],
    });
    expect(r.header, [l.queryNcHeartRate, l.queryNotComputable('페이스')]);
    expect(notComputableLines(l, ['체중']), [l.queryNcBodyweight]);
  });

  test('G27: 이거나 조건은 두 series 로 나란히 — clarify 가 아니다', () {
    final r = run({
      'measures': ['setCount'],
      'series': [
        {
          'weight': {'op': '>=', 'value': 100, 'unit': 'kg'},
        },
        {
          'reps': {'op': '<=', 'value': 2},
        },
      ],
    }, question: '100kg 이상이거나 2회 이하인 세트 수');
    expect(r.rows, hasLength(2));
    expect(r.rows.every((row) => row.cells.single.answer != null), isTrue);
  });

  test('부위·시간대·세트 순번·루틴·기간 밀기', () {
    final parts = run({
      'by': 'part',
      'measures': ['setCount'],
    });
    expect(column(parts), [
      (l.queryPart('chest'), 10),
      (l.queryPart('back'), 6),
      (l.queryPart('legs'), 5),
      (l.queryPart('core'), 1),
      (l.queryPart('cardio'), 3),
    ]);
    expect(parts.footnotes, contains(l.queryUnknownPart('민수식 로우')));
    Map<String, Object?> hours(int from, int to) => {
      'hours': {'from': from, 'to': to},
      'measures': ['trainingDays'],
    };
    final night = run(hours(22, 6));
    expect(night.rows.single.cells.single.answer!.numericValue, 1);
    expect(night.footnotes, [l.queryHoursNote]);
    expect(run(hours(5, 11)).rows.single.cells.single.answer!.numericValue, 4);
    final sets = run({
      'exercises': ['벤치프레스'],
      'measures': ['meanWeight'],
      'series': [
        {'set': 'first'},
        {'set': 'last'},
      ],
    });
    expect(column(sets).map((c) => c.$2), [
      closeTo(410 / 6, 1e-9),
      closeTo(412.5 / 6, 1e-9),
    ]);
    expect(
      run({
        'routine': true,
        'measures': ['trainingDays'],
      }).rows.single.cells.single.answer!.numericValue,
      1,
    );
    // 달을 밀면 날을 그달 끝으로 당긴다: 3/31 − 1달 = 2/29(윤년), 2/28.
    for (final (year, day) in [(2024, 29), (2026, 28)]) {
      final q = RecordQuery.decode(
        {
          'since': '$year-03-31',
          'until': '$year-03-31',
          'series': [
            {
              'shift': {'months': 1},
            },
            {},
          ],
        },
        names,
        today: DateTime(year, 4, 1),
      );
      expect(q.series.first.scope.since, DateTime(year, 2, day));
    }
  });

  test('설계의 예시 plan 58개: 모두 디코드되고, 실행기는 막다른 길 없이 칸마다 값 또는 까닭을 낸다', () {
    const examples = [
      ('001', r'''{"exercises": ["벤치프레스", "오버헤드프레스"]}'''),
      ('007', r'''{"exercises": ["벤치프레스", "힙쓰러스트"], "measures": ["best"]}'''),
      (
        '008',
        r'''{"exercises": ["데드리프트", "케틀벨 스윙"], "measures": ["trainingDays"]}''',
      ),
      (
        '011',
        r'''{"exercises": ["러닝", "수영"], "period": "thisMonth", "measures": ["distance"]}''',
      ),
      ('013', r'''{"exercises": ["벤치프레스", "바벨로우"], "measures": ["best"]}'''),
      (
        '014',
        r'''{"measures": ["best"], "series": [{"exercises": ["데드리프트"], "period": "lastYear"}, {"exercises": ["스쿼트"], "period": "thisYear"}]}''',
      ),
      (
        '017',
        r'''{"measures": ["best"], "series": [{"exercises": ["스쿼트"], "since": "2026-01-01", "until": "2026-02-28"}, {"exercises": ["레그프레스"], "period": "recent", "days": 28}]}''',
      ),
      (
        '019',
        r'''{"series": [{"exercises": ["벤치프레스"], "measures": ["e1rm"]}, {"exercises": ["스쿼트"], "measures": ["volume"]}]}''',
      ),
      ('022', r'''{"exercises": ["플랭크", "스쿼트"], "measures": ["best"]}'''),
      (
        '023',
        r'''{"measures": ["trainingDays"], "series": [{"period": "lastMonth"}, {"period": "thisMonth"}]}''',
      ),
      (
        '024',
        r'''{"exercises": ["데드리프트"], "measures": ["volume"], "series": [{"since": "2026-01-01", "until": "2026-06-30"}, {"since": "2026-07-01", "until": "2026-12-31"}]}''',
      ),
      (
        '029',
        r'''{"exercises": ["벤치프레스"], "period": "recent", "days": 30, "series": [{"shift": {"years": 1}}, {}]}''',
      ),
      (
        '030',
        r'''{"period": "recent", "days": 28, "measures": ["trainingDays"], "series": [{"shift": {"days": 28}}, {}]}''',
      ),
      (
        '031',
        r'''{"period": "thisYear", "measures": ["volume"], "series": [{"shift": {"years": 1}}, {}]}''',
      ),
      (
        '034',
        r'''{"exercises": ["스쿼트"], "measures": ["best"], "series": [{"until": "2026-07-14"}, {"since": "2026-07-15"}]}''',
      ),
      (
        '038',
        r'''{"exercises": ["데드리프트"], "measures": ["weightChange"], "notComputable": ["부상 날짜"]}''',
      ),
      (
        '043',
        r'''{"measures": ["volume", "setCount"], "series": [{"part": "upper"}, {"part": "lower"}]}''',
      ),
      (
        '047',
        r'''{"by": "part", "measures": ["setCount"], "relate": "share"}''',
      ),
      (
        '048',
        r'''{"measures": ["setCount", "volume"], "relate": "ratio", "series": [{"exercises": ["벤치프레스", "인클라인 벤치프레스", "덤벨 프레스", "오버헤드프레스", "케이블 푸시다운"]}, {"exercises": ["랫풀다운", "풀업", "시티드 로우", "바벨컬"]}]}''',
      ),
      (
        '049',
        r'''{"by": "exercise", "measures": ["meanWeight"], "series": [{"hours": {"from": 5, "to": 11}}, {"hours": {"from": 17, "to": 23}}]}''',
      ),
      (
        '051',
        r'''{"hours": {"from": 0, "to": 6}, "measures": ["trainingDays"]}''',
      ),
      (
        '053',
        r'''{"measures": ["trainingDays"], "series": [{"weekdays": [1, 2, 3, 4, 5]}, {"weekdays": [6, 7]}]}''',
      ),
      (
        '056',
        r'''{"measures": ["volume"], "per": "day", "series": [{"weekdays": [1, 2, 3, 4, 5]}, {"weekdays": [6, 7]}]}''',
      ),
      (
        '058',
        r'''{"measures": ["volume", "setCount"], "per": "day", "series": [{"together": true}, {"together": false}]}''',
      ),
      (
        '060',
        r'''{"exercises": ["스쿼트"], "measures": ["best"], "notComputable": ["파트너 기록"]}''',
      ),
      (
        '063',
        r'''{"measures": ["volume", "setCount"], "per": "day", "series": [{"routine": true}, {"routine": false}]}''',
      ),
      (
        '067',
        r'''{"exercises": ["벤치프레스", "스쿼트"], "measures": ["best"], "relate": "ratio"}''',
      ),
      (
        '069',
        r'''{"exercises": ["벤치프레스", "스쿼트", "데드리프트"], "measures": ["best"], "relate": "ratio"}''',
      ),
      (
        '071',
        r'''{"measures": ["volume"], "relate": "ratio", "series": [{}, {"exercises": ["스쿼트"]}]}''',
      ),
      (
        '073',
        r'''{"exercises": ["벤치프레스"], "measures": ["best"], "notComputable": ["체중"]}''',
      ),
      (
        '076',
        r'''{"exercises": ["스쿼트", "벤치프레스", "데드리프트"], "measures": ["best"], "total": "sum", "notComputable": ["윌크스 점수"]}''',
      ),
      (
        '077',
        r'''{"by": "exercise", "measures": ["changePct", "weightChange"], "order": "desc", "limit": 5}''',
      ),
      (
        '082',
        r'''{"by": "exercise", "measures": ["daysSinceBest"], "order": "desc", "limit": 5}''',
      ),
      ('083', r'''{"measures": ["longestStreak"]}'''),
      ('088', r'''{"measures": ["meanGap"]}'''),
      ('090', r'''{"measures": ["longestGap"]}'''),
      (
        '093',
        r'''{"exercises": ["벤치프레스"], "measures": ["meanWeight"], "series": [{"set": "first"}, {"set": "last"}]}''',
      ),
      ('094', r'''{"exercises": ["스쿼트"], "measures": ["meanReps"]}'''),
      (
        '099',
        r'''{"exercises": ["벤치프레스"], "measures": ["best", "meanWeight"], "series": [{"memo": ["컨디션"]}, {"noMemo": ["컨디션"]}]}''',
      ),
      (
        '105',
        r'''{"measures": ["intake"], "per": "day", "series": [{"trained": true}, {"trained": false}]}''',
      ),
      ('110', r'''{"notComputable": ["심박"]}'''),
      (
        '113',
        r'''{"by": "day", "measures": ["burned"], "order": "desc", "limit": 1}''',
      ),
      ('114', r'''{"timer": "tabata", "measures": ["trainingDays"]}'''),
      (
        '118',
        r'''{"period": "thisMonth", "by": "exercise", "measures": ["trainingDays"], "order": "desc", "limit": 5}''',
      ),
      (
        '120',
        r'''{"by": "exercise", "measures": ["daysSince"], "order": "desc", "limit": 3}''',
      ),
      ('124', r'''{"measures": ["setCount"], "per": "day"}'''),
      (
        '128',
        r'''{"exercises": ["벤치프레스", "스쿼트"], "by": "month", "measures": ["best"]}''',
      ),
      (
        '130',
        r'''{"by": "week", "measures": ["volume"], "series": [{"period": "lastMonth"}, {"period": "thisMonth"}]}''',
      ),
      (
        '131',
        r'''{"exercises": ["벤치프레스", "스쿼트"], "by": "weekday", "measures": ["trainingDays"]}''',
      ),
      (
        '132',
        r'''{"weight": {"op": ">=", "value": 80, "unit": "kg"}, "measures": ["setCount"], "series": [{"period": "lastMonth"}, {"period": "thisMonth"}]}''',
      ),
      (
        '137',
        r'''{"exercises": ["러닝"], "measures": ["distance", "duration"], "notComputable": ["페이스"]}''',
      ),
      (
        '140',
        r'''{"exercises": ["벤치프레스"], "measures": ["best"], "relate": "ratio", "series": [{}, {"sessions": 1}]}''',
      ),
      (
        '144',
        r'''{"by": "exercise", "measures": ["trainingDays", "daysSinceBest", "daysSince"], "order": "desc", "limit": 10}''',
      ),
      (
        '149',
        r'''{"exercises": ["벤치프레스"], "measures": ["best", "weightChange"], "notComputable": ["체지방 변화"]}''',
      ),
      ('157', r'''{"notComputable": ["다른 회원 기록"]}'''),
      (
        '159',
        r'''{"exercises": ["Bench Press", "Hip Thrust"], "measures": ["best"]}''',
      ),
      (
        '189',
        r'''{"measures": ["best"], "series": [{"exercises": ["卧推"], "period": "lastMonth"}, {"exercises": ["深蹲"], "period": "thisMonth"}]}''',
      ),
      (
        '216',
        r'''{"exercises": ["Press de Banca", "Hip Thrust"], "measures": ["best"]}''',
      ),
    ];
    for (final (id, json) in examples) {
      final q = RecordQuery.decode(jsonDecode(json), names, today: today);
      if (q.kind == 'unsupported') {
        // 셀 것이 없는 질문(심박·다른 회원)은 까닭이 있는 거절이다.
        expect(q.reason, 'nothing', reason: id);
        expect(refusalLines(q, l), isNotEmpty, reason: id);
        continue;
      }
      final r = runPlan(
        q,
        fixture,
        l: l,
        unit: 'kg',
        today: today,
        confirmed: true,
      )!;
      expect(r.columns, isNotEmpty, reason: id);
      for (final row in r.rows) {
        expect(row.cells, hasLength(r.columns.length), reason: id);
        for (final c in row.cells) {
          expect(
            c.answer != null || c.reason != null,
            isTrue,
            reason: '$id ${row.label}',
          );
        }
      }
      expect(describePlan(q, l, 'kg', notes: fixture), isNotEmpty, reason: id);
    }
  });
}
