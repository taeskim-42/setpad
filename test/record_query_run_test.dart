import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/stats.dart';

/// 실행기. 모델 없이 질의 → 기록 → 칸.
///
/// 픽스처는 스펙 3.11-A 그대로다. 오늘은 2026-09-23(수), 단위는 kg.
/// TZ=America/New_York 에서도 같은 답이어야 한다 — 날짜와 주 경계가 시간대로
/// 흔들리면 안 된다.
void main() {
  setUpAll(() => initializeDateFormatting());
  final l = lookupL(const Locale('ko'));
  final today = DateTime(2026, 9, 23, 21);
  LoggedSet s(
    double? v,
    int? r, {
    String u = 'kg',
    bool done = true,
    List<String>? memo,
  }) => LoggedSet(value: v, unit: u, reps: r, done: done, notes: memo);
  Note n(String id, int month, int day, List<ExerciseBlock> blocks) {
    final at = DateTime(2026, month, day, 19);
    return Note(id: id, createdAt: at, updatedAt: at, blocks: blocks);
  }

  final fixture = [
    n('N1', 8, 4, [
      ExerciseBlock('벤치프레스', [s(80, 5), s(85, 3), s(90, 1, done: false)]),
      ExerciseBlock('바벨로우', [s(60, 8), s(60, 8)]),
    ]),
    n('N2', 8, 18, [
      ExerciseBlock('벤치프레스', [s(82.5, 5), s(82.5, 5)]),
      ExerciseBlock('풀업', [s(null, 10), s(null, 8)]),
    ]),
    n('N3', 9, 7, [
      ExerciseBlock('벤치프레스', [
        s(85, 5, memo: ['어깨 뻐근']),
      ]),
      ExerciseBlock('바벨로우', [s(70, 6), s(150, 5, u: 'lb')]),
    ]),
    n('N4', 9, 14, [
      ExerciseBlock('스쿼트', [s(100, 5), s(105, 3)]),
      ExerciseBlock('플랭크', [s(60, null, u: 's'), s(90, null, u: 's')]),
    ]),
    n('N5', 9, 21, [
      ExerciseBlock('벤치프레스', [s(87.5, 2)]),
      ExerciseBlock('러닝', [s(5, null, u: 'km'), s(3000, null, u: 'm')]),
    ]),
    n('N6', 9, 22, [
      ExerciseBlock('딥스', [s(20, 10), s(null, 12)]),
    ]),
  ];
  final names = {
    for (final n in fixture)
      for (final b in n.blocks) b.exercise,
  }.toList();

  RecordResult run(
    Map<String, Object?> raw, {
    String unit = 'kg',
    String question = '',
  }) => runQuery(
    RecordQuery.decode(
      raw,
      names,
      unit: unit,
      today: today,
      question: question,
    ),
    fixture,
    l: l,
    unit: unit,
    today: today,
    confirmed: true,
  )!;
  Answer? one(Map<String, Object?> raw, {String unit = 'kg'}) {
    final r = run(raw, unit: unit);
    expect(r.render, 'number');
    return r.rows.single.cells.single.answer;
  }

  double? value(Map<String, Object?> raw) => one(raw)?.numericValue;
  Map<String, Object?> of(String exercise, String measure) => {
    'exercises': [exercise],
    'measures': [measure],
  };

  test('벤치 vs 로우 기본 측정: 대조형 표와 차이', () {
    final r = run({
      'exercises': ['벤치프레스', '바벨로우'],
    });
    expect(r.render, 'table');
    expect(r.title, '벤치프레스 · 바벨로우');
    expect(r.columns, ['최고', '운동한 날', '마지막']);
    expect(r.rows.map((row) => row.label), ['벤치프레스', '바벨로우']);
    final [bench, row] = r.rows;
    expect(bench.cells[0].answer!.headline, '87.5kg × 2회');
    expect(bench.cells[0].answer!.lines.first, '9월 21일');
    expect(row.cells[0].answer!.headline, '70kg × 6회');
    expect(row.cells[0].answer!.lines.first, '9월 7일');
    expect(bench.cells[1].answer!.numericValue, 4);
    expect(row.cells[1].answer!.numericValue, 2);
    expect(bench.cells[2].answer!.lines.first, '9월 21일');
    expect(row.cells[2].answer!.lines.first, '9월 7일');
    expect(r.diff, hasLength(2));
    expect(r.diff[0], contains('-17.5kg (-20%)'));
    expect(r.diff[0], contains('바벨로우 − 벤치프레스'));
    expect(r.diff[1], contains('-2일'));
    expect(r.evidence, {'N1', 'N2', 'N3', 'N5'});
  });

  test('운동 하나의 측정들 — 최고·추정 1RM·볼륨·반복·시간·거리', () {
    final best = one(of('벤치프레스', 'best'))!;
    expect(best.numericValue, 87.5, reason: '해내지 않은 90 은 없다');
    final e1rm = run(of('벤치프레스', 'e1rm'));
    final a = e1rm.rows.single.cells.single.answer!;
    expect(a.headline, '≈99.17kg');
    expect(a.lines.take(2), ['9월 7일', '85kg × 5회']);
    expect(e1rm.footnotes, contains(l.queryE1rmRule));
    expect(value(of('벤치프레스', 'volume')), 2080);
    expect(
      value(of('바벨로우', 'volume')),
      closeTo(960 + 420 + 150 * 0.45359237 * 5, 1e-9),
    );
    expect(one(of('풀업', 'best'))!.headline, '10회');
    expect(one(of('플랭크', 'best'))!.headline, '90초');
    expect(one(of('러닝', 'best'))!.headline, '5km');
    expect(one(of('러닝', 'distance'))!.headline, '8km');
    expect(one(of('플랭크', 'duration'))!.headline, '150초');
    expect(one(of('벤치프레스', 'first'))!.lines.first, '8월 4일');
    expect(value(of('바벨로우', 'daysSince')), 16);
    expect(
      one(of('벤치프레스', 'best'), unit: 'lb')!.numericValue,
      87.5 / 0.45359237,
    );
  });

  test('값이 빠진 세트가 든 운동은 칸을 비우고 각주에 적는다', () {
    final r = run(of('딥스', 'best'));
    expect(r.rows.single.cells.single.reason, 'unknown');
    expect(r.footnotes, [l.queryMissingFor('딥스')]);
  });

  test('전체 합계는 운동 단위로 해당 없음을 뺀다', () {
    final thisWeek = run({
      'period': 'thisWeek',
      'measures': ['volume'],
    });
    expect(thisWeek.rows.single.cells.single.reason, 'unknown');
    expect(thisWeek.footnotes, [
      l.queryOutOfScope('러닝'),
      l.queryMissingFor('딥스'),
    ]);
    final lastWeek = run({
      'period': 'lastWeek',
      'measures': ['volume'],
    });
    expect(lastWeek.rows.single.cells.single.answer!.numericValue, 815);
    expect(lastWeek.footnotes, [l.queryOutOfScope('플랭크')]);
    final reps = run({
      'measures': ['repCount'],
    });
    expect(reps.rows.single.cells.single.answer!.numericValue, 100);
    expect(reps.footnotes, [l.queryOutOfScope('러닝, 플랭크')]);
    expect(
      value({
        'measures': ['setCount'],
      }),
      20,
    );
    expect(
      value({
        'measures': ['trainingDays'],
      }),
      6,
    );
  });

  test('무게 조건: > 와 >= 는 경계가 다르고, lb 는 코드가 바꾼다', () {
    Map<String, Object?> heavier(String op, num v, String unit, String who) => {
      'exercises': [who],
      'weight': {'op': op, 'value': v, 'unit': unit},
      'measures': ['trainingDays'],
    };
    expect(value(heavier('>', 85, 'kg', '벤치프레스')), 1);
    expect(value(heavier('>=', 85, 'kg', '벤치프레스')), 3);
    expect(value(heavier('>', 150, 'lb', '바벨로우')), 1, reason: '150lb 는 빠진다');
  });

  test('메모를 물으면 메모가 든 날만', () {
    final r = run({
      'memo': ['어깨'],
      'measures': ['trainingDays'],
    }, question: '어깨 메모 적은 날');
    expect(r.rows.single.cells.single.answer!.numericValue, 1);
    expect(r.evidence, {'N3'});
  });

  test('월요일마다 운동별 — 동률은 이름순', () {
    final r = run({
      'weekdays': [1],
      'by': 'exercise',
      'measures': ['trainingDays'],
      'order': 'desc',
    });
    expect(
      [
        for (final row in r.rows)
          (row.label, row.cells.single.answer!.numericValue),
      ],
      [('벤치프레스', 2), ('러닝', 1), ('바벨로우', 1), ('스쿼트', 1), ('플랭크', 1)],
    );
  });

  test('마지막 두 번의 추이, 두 달의 비교', () {
    final trend = one({...of('벤치프레스', 'weightChange'), 'sessions': 2})!;
    expect(trend.headline, '+2.5kg');
    final r = run({
      ...of('벤치프레스', 'best'),
      'compare': [
        {'period': 'lastMonth'},
        {'period': 'thisMonth'},
      ],
    });
    expect(r.render, 'table');
    expect(r.columns, ['2026-08-01 – 2026-08-31', '2026-09-01 – 2026-09-23']);
    expect(
      [for (final c in r.rows.single.cells) c.answer!.numericValue],
      [85, 87.5],
    );
    expect(r.diff.single, contains('+2.5kg (≈+2.94%)'));
  });

  test('가장 오래 안 한 운동 셋 — 나머지는 가린다', () {
    final r = run({
      'by': 'exercise',
      'measures': ['daysSince'],
      'order': 'desc',
      'limit': 3,
    });
    expect(
      [
        for (final row in r.rows)
          (row.label, row.cells.single.answer!.numericValue),
      ],
      [('풀업', 36), ('바벨로우', 16), ('스쿼트', 9)],
    );
    expect(r.hidden, 4);
    expect(r.footnotes, [l.queryMore(4)]);
  });

  test('벤치 말고 제일 무거운 운동 — 무게 없는 운동은 각주, 빈 세트는 누락', () {
    final r = run({
      'exclude': ['벤치프레스'],
      'by': 'exercise',
      'measures': ['best'],
      'order': 'desc',
      'limit': 1,
    });
    expect(r.rows.single.label, '스쿼트');
    expect(r.rows.single.cells.single.answer!.headline, '105kg × 3회');
    expect(r.footnotes, [
      l.queryOutOfScope('러닝, 풀업, 플랭크'),
      l.queryMissingFor('딥스'),
      l.queryMore(2),
    ]);
  });

  test('합계와 주당 평균 — 빈 주도 센다', () {
    final sum = run({
      'exercises': ['스쿼트', '벤치프레스'],
      'measures': ['best'],
      'total': 'sum',
    });
    expect(sum.total!.single.answer!.numericValue, 192.5);
    final weeks = run({
      'by': 'week',
      'measures': ['trainingDays'],
      'total': 'mean',
    });
    expect(weeks.render, 'chart');
    expect(weeks.rows.first.start, DateTime(2026, 8, 3));
    expect(
      [
        for (final row in weeks.rows)
          row.cells.single.answer?.numericValue ?? 0,
      ],
      [1, 0, 1, 0, 0, 1, 1, 2],
    );
    expect(weeks.total!.single.answer!.numericValue, 0.75);
  });

  test('확인 전인 모델 질의는 답이 없고, 칩으로 고른 질의는 묻지 않는다', () {
    final q = RecordQuery.decode(of('벤치프레스', 'best'), names, today: today);
    expect(q.requiresConfirmation, isTrue);
    expect(runQuery(q, fixture, l: l, unit: 'kg', today: today), isNull);
    const chip = RecordQuery(
      scope: QueryScope(exercises: ['벤치프레스', '바벨로우']),
      by: 'exercise',
    );
    expect(chip.requiresConfirmation, isFalse);
    expect(
      runQuery(chip, fixture, l: l, unit: 'kg', today: today)!.rows,
      hasLength(2),
    );
  });

  test('글의 이상·이하만 그쪽 끝을 덮고, 모델의 초과·미만은 남는다', () {
    double? sets(Object weight, String question) => run({
      'exercises': ['벤치프레스'],
      'weight': weight,
      'measures': ['setCount'],
    }, question: question).rows.single.cells.single.answer?.numericValue;
    expect(
      sets([
        {'op': '>', 'value': 80, 'unit': 'kg'},
        {'op': '<=', 'value': 85, 'unit': 'kg'},
      ], '벤치프레스 80kg 초과 85kg 이하 세트 수'),
      4,
      reason: '80kg 세트는 빠진다',
    );
    expect(
      sets([
        {'op': '>=', 'value': 80, 'unit': 'kg'},
        {'op': '<', 'value': 85, 'unit': 'kg'},
      ], '벤치프레스 80kg 이상 85kg 미만 세트 수'),
      3,
    );
    final q = RecordQuery.decode(
      {
        'exercises': ['벤치프레스'],
        'reps': [
          {'op': '>', 'value': 3},
          {'op': '<=', 'value': 5},
        ],
        'measures': ['setCount'],
      },
      names,
      today: today,
      question: '벤치프레스 3회 초과 5회 이하 세트 수',
    );
    expect('${q.scope.reps}', '[>3.0, <=5.0]');
  });

  test('줄 하나로 줄인 순위도 표다 — 무엇이 1위인지 보여야 한다', () {
    final heaviest = run({
      'exclude': ['벤치프레스'],
      'by': 'exercise',
      'measures': ['best'],
      'order': 'desc',
      'limit': 1,
    });
    expect(heaviest.render, 'table');
    final weekday = run({
      'by': 'weekday',
      'measures': ['trainingDays'],
      'order': 'desc',
      'limit': 1,
    });
    expect(weekday.render, 'table');
    expect(weekday.rows.single.label, '월');
  });

  test('개수만 준 순위는 큰 순이다 — 확인 줄과 제목이 그렇게 적는다', () {
    final q = RecordQuery.decode(
      {
        'by': 'exercise',
        'measures': ['trainingDays'],
        'limit': 1,
      },
      names,
      today: today,
    );
    expect(q.order, 'desc');
    expect(describeQuery(q, l, 'kg'), contains(l.queryRankingLimit(1)));
    final r = runQuery(
      q,
      fixture,
      l: l,
      unit: 'kg',
      today: today,
      confirmed: true,
    )!;
    expect(r.title, contains(l.queryRankingLimit(1)));
    expect(r.rows.single.label, '벤치프레스');
  });

  test('순위를 매긴 주 묶음은 차트가 아니라 표다', () {
    final r = run({
      'by': 'week',
      'measures': ['trainingDays'],
      'order': 'desc',
      'limit': 3,
    });
    expect(r.render, 'table');
  });

  test('주 묶음은 오늘 뒤의 빈 주를 만들지 않는다 — 평균에 0 으로 들지 않는다', () {
    final r = run({
      'by': 'week',
      'measures': ['trainingDays'],
      'total': 'mean',
    }, question: '9월 주당 평균 몇 번 갔어?');
    expect(
      [for (final row in r.rows) row.start],
      [
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 7),
        DateTime(2026, 9, 14),
        DateTime(2026, 9, 21),
      ],
    );
    expect(r.total!.single.answer!.numericValue, 1.0);
  });

  test('같은 운동을 두 번 적으면 한 번이다', () {
    final q = RecordQuery.decode(
      {
        'exercises': ['벤치프레스', '벤치'],
        'measures': ['best'],
      },
      names,
      today: today,
    );
    expect(q.scope.exercises, ['벤치프레스']);
    expect(q.by, isNull);
    final sum = run({
      'exercises': ['스쿼트', '스쿼트', '벤치프레스'],
      'measures': ['best'],
      'total': 'sum',
    });
    expect(sum.total!.single.answer!.numericValue, 192.5);
  });

  test('시간 묶음의 최고는 한 번만 푼다 — kg 과 회가 한 차트에 섞이지 않는다', () {
    final dips = [
      n('D1', 9, 1, [
        ExerciseBlock('딥스', [s(10, 8)]),
      ]),
      n('D2', 9, 8, [
        ExerciseBlock('딥스', [s(null, 15)]),
      ]),
      n('D3', 9, 15, [
        ExerciseBlock('딥스', [s(15, 6)]),
      ]),
    ];
    final r = runQuery(
      RecordQuery.decode(
        {
          'exercises': ['딥스'],
          'by': 'week',
          'measures': ['best'],
          'period': 'thisMonth',
        },
        ['딥스'],
        today: today,
      ),
      dips,
      l: l,
      unit: 'kg',
      today: today,
      confirmed: true,
    )!;
    final cells = [for (final row in r.rows) row.cells.single];
    expect(
      [for (final c in cells) c.answer?.metric],
      [Metric.max, null, Metric.max, null],
    );
    expect([for (final c in cells) c.reason], [null, 'unknown', null, 'none']);
    expect(r.footnotes, [l.queryMissingFor('딥스')]);
  });

  test('추정 1RM: 11회 이상 세트뿐이면 해당 없음이지 누락이 아니다', () {
    final r = runQuery(
      RecordQuery.decode(
        {
          'exercises': ['레그프레스'],
          'measures': ['e1rm'],
        },
        ['레그프레스'],
        today: today,
      ),
      [
        n('L1', 9, 1, [
          ExerciseBlock('레그프레스', [s(100, 15), s(100, 12)]),
        ]),
      ],
      l: l,
      unit: 'kg',
      today: today,
      confirmed: true,
    )!;
    expect(r.rows.single.cells.single.reason, 'none');
    expect(r.footnotes, [l.queryE1rmRule, l.queryOutOfScope('레그프레스')]);
  });

  test('전체 최고가 시간과 거리를 함께 잡으면 시간 운동만 대상이다', () {
    final r = run({
      'exclude': ['스쿼트', '벤치프레스', '바벨로우', '딥스', '풀업'],
      'measures': ['best'],
    });
    expect(r.rows.single.cells.single.answer!.headline, '90초');
    expect(r.footnotes, [l.queryOutOfScope('러닝')]);
  });
}
