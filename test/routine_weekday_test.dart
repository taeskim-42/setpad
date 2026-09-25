import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/anatomy.dart' show Muscle;
import 'package:setpad/editor.dart';
import 'package:setpad/handoff.dart' show ProxyRecord;
import 'package:setpad/notes.dart';
import 'package:setpad/record_ai.dart' show WorkoutSetup;
import 'package:setpad/record_query.dart' show recordedExercises;
import 'package:setpad/routine.dart';
import 'package:setpad/training_factor.dart';

import '../tool/routine_grading.dart';
import 'routine_fixture.dart';

/// 평일 = 같은 요일 하루(설계 routine-v2 §3.1, §8.1 S1–S5·S9–S11·S14·S15, §4.4).
void main() {
  const bare = RoutineAsk(device: true);
  // 월 가슴 / 화 등 / 수 하체 / 목 어깨 / 금 팔 — 8/31(월)부터 9/16(수)까지.
  final split = weekLog(DateTime(2026, 8, 31), 17, splitPlan);
  final thu = DateTime(2026, 9, 17, 18);

  RoutineDraft make(
    List<Note> log,
    DateTime now, {
    Object? gold,
    String text = '오늘 루틴 짜줘',
    RoutineEdits? edits,
  }) {
    final ask = gold == null
        ? bare
        : decodeRoutineAsk(gold, text, recordedExercises(log), today: now);
    final d = composeRoutine(log, ask, now: now, edits: edits);
    expect(routineViolations(d, ask, log, text), isEmpty);
    return d;
  }

  List<String> keys(RoutineDraft d) => [for (final i in d.items) i.key];

  test('S1 보통 주: 목요일엔 지난 목요일 하루 그대로 — 칸·세트·요인 설명', () {
    final d = make(split, thu);
    expect(d.source, 'weekday');
    expect(d.weeksAgo, 1);
    expect(d.near, isFalse);
    expect(d.sourceDay, DateTime(2026, 9, 10));
    expect(keys(d), ['오버헤드프레스', '사이드 레터럴 레이즈']);
    expect(
      d.items.first.sets,
      List.filled(3, (value: 40.0, unit: 'kg', reps: 8)),
    );
    expect(d.restDays, 7);
    expect(d.factor?.factor, Factor.strength);
    expect(d.factor?.read.why, 'sets');
    expect(d.factor?.read.args, ['3', '8']);
    expect(d.hasOther, isTrue);
  });

  test('S2 지난 목요일을 빼먹었으면 2주 전 목요일', () {
    final log = weekLog(
      DateTime(2026, 8, 31),
      17,
      splitPlan,
      skip: {DateTime(2026, 9, 10)},
    );
    final d = make(log, thu);
    expect(d.source, 'weekday');
    expect(d.weeksAgo, 2);
    expect(d.sourceDay, DateTime(2026, 9, 3));
  });

  test('S2′ 목요일이 내리 없으면 지난 몇 주의 이웃 요일 — 운동 쉰 날이 긴 쪽', () {
    final log = weekLog(
      DateTime(2026, 8, 31),
      17,
      splitPlan,
      skip: {DateTime(2026, 9, 3), DateTime(2026, 9, 10)},
    );
    final d = make(log, thu);
    expect(d.source, 'weekday');
    expect(d.near, isTrue);
    expect(d.weeksAgo, isNull);
    // 수요일(하체)은 이번 주 수요일에 또 해서 쉰 날이 1 — 금요일(팔)이 6.
    expect(d.sourceDay, DateTime(2026, 9, 11));
    expect(d.restDays, 6);
  });

  test('S2″ 같은 요일도 이웃도 없으면 지금의 회전', () {
    final mondays = weekLog(DateTime(2026, 8, 31), 17, {1: splitPlan[1]!});
    final d = make(mondays, thu);
    expect(d.source, 'rotation');
    expect(d.weeksAgo, isNull);
  });

  test('S3 하루 두 번(아침 러닝 + 저녁 웨이트)은 하루 통째, 요인은 세트가 많은 쪽', () {
    final log = [
      ...split,
      at(DateTime(2026, 9, 10, 7), [
        ExerciseBlock('러닝', [timed(5, 'km')]),
      ]),
    ];
    final d = make(log, thu);
    expect(d.sourceDay, DateTime(2026, 9, 10));
    expect(keys(d), ['러닝', '오버헤드프레스', '사이드 레터럴 레이즈']);
    expect(d.factor?.factor, Factor.strength);
  });

  test('S4 자정 넘김: 목 00:30 에 시작한 수요일 밤 운동은 목요일 — 수요일엔 이웃', () {
    final mid = [
      at(DateTime(2026, 9, 17, 0, 30), [
        ExerciseBlock('스쿼트', times(3, () => kg(90, 5))),
      ]),
    ];
    final t = make(mid, DateTime(2026, 9, 24, 18));
    expect(
      (t.source, t.weeksAgo, t.sourceDay),
      ('weekday', 1, DateTime(2026, 9, 17)),
    );
    final w = make(mid, DateTime(2026, 9, 23, 18));
    expect(
      (w.source, w.near, w.sourceDay),
      ('weekday', true, DateTime(2026, 9, 17)),
    );
  });

  test('S5 같이 한 사람·안 한 세트는 옮기지도 세지도 않고, 건네받은 기록은 내 날, 대신 적은 것은 아니다', () {
    final lastThu =
        at(DateTime(2026, 9, 10, 19), [
            ExerciseBlock('오버헤드프레스', [
              ...times(3, () => kg(40, 8)),
              kg(60, 5, author: '민수'),
              kg(45, 8, done: false),
            ]),
          ])
          ..proxy = ProxyRecord(
            name: '민수',
            blocks: [ExerciseBlock('벤치프레스', times(3, () => kg(200, 5)))],
          );
    final handoff = at(DateTime(2026, 9, 15, 7), [
      ExerciseBlock('데드리프트', times(3, () => kg(120, 5))),
    ])..handoffToken = 'tok';
    final log = [lastThu, handoff];
    final d = make(log, thu);
    expect(keys(d), ['오버헤드프레스']);
    expect(
      d.items.single.sets,
      List.filled(3, (value: 40.0, unit: 'kg', reps: 8)),
    );
    expect(d.factor?.read.args, ['3', '8']);
    final tue = make(log, DateTime(2026, 9, 22, 18));
    expect((tue.source, tue.sourceDay), ('weekday', DateTime(2026, 9, 15)));
  });

  test('S9 A/B 번갈이: 지난주(B), 다른 루틴 한 번에 2주 전(A)', () {
    final ab = [
      for (var w = 0; w < 4; w++)
        at(DateTime(2026, 8, 31 + 7 * w, 19), [
          ExerciseBlock(
            w.isEven ? '벤치프레스' : '스쿼트',
            times(3, () => kg(w.isEven ? 80 : 90, 5)),
          ),
          ExerciseBlock(w.isEven ? '랫풀다운' : '레그컬', times(3, () => kg(50, 10))),
        ]),
    ];
    final mon = DateTime(2026, 9, 28, 18);
    final d = make(ab, mon);
    expect((d.weeksAgo, d.sourceDay), (1, DateTime(2026, 9, 21)));
    expect(keys(d), ['스쿼트', '레그컬']);
    final alt = make(ab, mon, edits: RoutineEdits()..alt = 1);
    expect((alt.weeksAgo, alt.sourceDay), (2, DateTime(2026, 9, 14)));
    expect(keys(alt), ['벤치프레스', '랫풀다운']);
  });

  group('S10 사람이 친 조건', () {
    test('뺄 것은 그 칸만 줄로', () {
      final d = make(
        split,
        thu,
        gold: {
          'exclude': ['오버헤드프레스'],
        },
        text: '오버헤드프레스 말고',
      );
      expect(d.source, 'weekday');
      expect(keys(d), ['사이드 레터럴 레이즈']);
      expect(d.removed.map((r) => r.key), contains('오버헤드프레스'));
    });

    test('피할 부위로 그 요일이 다 걸리면 다음 후보 날(이웃)', () {
      final d = make(
        split,
        thu,
        gold: {
          'avoid': ['shoulders'],
        },
        text: '어깨는 빼고',
      );
      expect(d.source, 'weekday');
      expect(d.near, isTrue);
      expect(d.sourceDay, DateTime(2026, 9, 11));
      expect(keys(d), ['바벨컬', '케이블 푸시다운']);
    });

    test('시간은 다음 후보 날의 칸으로 맞춘다', () {
      final d = make(split, thu, gold: {'minutes': 90}, text: '90분');
      expect(d.source, 'weekday');
      expect(keys(d).take(2), ['오버헤드프레스', '사이드 레터럴 레이즈']);
      expect(d.items.length, greaterThan(2));
    });

    test('부위를 말하면 조건 원천(새 규칙을 타지 않는다)', () {
      final d = make(
        split,
        thu,
        gold: {
          'parts': ['chest'],
        },
        text: '가슴 루틴',
      );
      expect(d.source, 'conditions');
    });
  });

  test('S11 요일 지정: 수요일에 "금요일 루틴" 은 지난 금요일', () {
    final wed = DateTime(2026, 9, 16, 18);
    final fri = make(split, wed, gold: {'when': 5}, text: '금요일 루틴 짜줘');
    expect(fri.day, DateTime(2026, 9, 18));
    expect(
      (fri.source, fri.weeksAgo, fri.sourceDay),
      ('weekday', 1, DateTime(2026, 9, 11)),
    );
  });

  test('평일 원천에도 스스로 올려 온 폭 칩 — 누를 때만 들어간다(§4.4)', () {
    final log = [
      for (final (i, w) in [80.0, 82.5, 85.0, 87.5].indexed)
        at(DateTime(2026, 8, 20 + 7 * i, 19), [
          ExerciseBlock('벤치프레스', times(3, () => kg(w, 5))),
        ]),
    ];
    final d = make(log, thu);
    expect(d.source, 'weekday');
    expect(d.stepChip, (text: '2.5kg', apply: true));
    expect(d.lines.map((l) => l.code), isNot(contains('noStep')));
    expect(d.items.single.sets.first.value, 87.5);
    final up = make(log, thu, edits: RoutineEdits()..step = true);
    expect(up.items.single.sets.every((s) => s.value == 90), isTrue);
    expect(up.items.single.stepped?.step, 2.5);
  });

  test('S14 가볍게 = 칸마다 마지막 세트 하나 빼기, 무게는 내 값 — 채우기·타바타·한 세트 칸은 그대로(F5)', () {
    final log = [
      at(DateTime(2026, 9, 10, 19), [
        ExerciseBlock('오버헤드프레스', times(3, () => kg(40, 8))),
        ExerciseBlock(
          '푸시업 100개 채우기',
          [reps(40), reps(30), reps(30)],
          const WorkoutSetup(name: '푸시업', totalReps: 100, repsOnly: true),
        ),
        ExerciseBlock('버피 타바타', [reps(10)]),
        ExerciseBlock('풀업', [reps(8)]),
      ]),
    ];
    final d = make(log, thu, gold: {'intensity': 'light'}, text: '가볍게 하고 싶어');
    final ohp = d.items.first;
    expect(ohp.sets, List.filled(2, (value: 40.0, unit: 'kg', reps: 8)));
    expect(ohp.blank, isNull);
    for (final i in d.items.skip(1)) {
      expect(i.sets.length, i.key == '푸시업' ? 3 : 1, reason: i.title);
      expect(i.blank, isNull, reason: i.title);
    }
    final kept = d.lines.firstWhere((l) => l.code == 'lightKept');
    expect(kept.args.single, ['푸시업 100개 채우기', '버피 타바타', '풀업']);
  });

  test('S15 근육 겹침: 어제 데드리프트(허리·엉덩이) → 오늘 레그프레스에 "엉덩이 · 어제", 원천은 그대로', () {
    final log = [
      at(DateTime(2026, 9, 10, 19), [
        ExerciseBlock('레그프레스', times(3, () => kg(150, 10))),
        ExerciseBlock('레그컬', times(3, () => kg(40, 12))),
      ]),
      at(DateTime(2026, 9, 16, 19), [
        ExerciseBlock('데드리프트', times(3, () => kg(100, 5))),
      ]),
    ];
    final d = make(log, thu);
    expect(d.sourceDay, DateTime(2026, 9, 10));
    expect(d.items.first.recent, (part: null, muscle: Muscle.glutes, days: 1));
    // 레그컬(허벅지 뒤)은 데드리프트(허리·엉덩이)와 주동 근육이 겹치지 않는다.
    expect(d.items[1].recent, isNull);
  });
}
