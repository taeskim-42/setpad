import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_query.dart' show recordedExercises;
import 'package:setpad/routine.dart';
import 'package:setpad/training_factor.dart';
import 'package:setpad/workout_timing.dart';

import '../tool/routine_grading.dart';
import 'routine_fixture.dart';

/// 주말 = 최근 7일에 모자란 체력 요인(설계 routine-v2 §3.2, §8.1 S6–S8″·S11·S12).
void main() {
  const bare = RoutineAsk(device: true);

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
    // "타바타로" 칩은 타이머 조건을 더한 요청이다 — 채점도 그 요청으로.
    final asked = edits?.mode == 'tabata'
        ? ask.withTimer(const RoutineTimer.tabata())
        : ask;
    expect(routineViolations(d, asked, log, text), isEmpty);
    return d;
  }

  final mw = methodWeek(DateTime(2026, 9, 14));
  final sat = DateTime(2026, 9, 19, 10);
  const all = {
    Factor.strength: 2,
    Factor.endurance: 1,
    Factor.sustain: 1,
    Factor.cardio: 1,
  };

  test('S8 방식 주의 토·일: 다 채웠으면 가장 오래 안 한 근지구력 — 화요일 채우기를 숫자째', () {
    for (final now in [sat, DateTime(2026, 9, 20, 10)]) {
      final d = make(mw, now);
      expect(d.source, 'factor', reason: '$now');
      expect(d.target, Factor.endurance);
      expect(d.short, isFalse);
      expect(d.weekCounts, all);
      expect(d.missing, isEmpty);
      expect(d.sourceDay, DateTime(2026, 9, 15));
      final squat = d.items.first;
      expect(squat.title, '스쿼트 60kg 100개 채우기');
      expect(squat.setup?.totalReps, 100);
      expect(squat.sets.map((s) => s.reps), [30, 25, 25, 20]);
      expect(d.items.map((i) => i.title), [
        '스쿼트 60kg 100개 채우기',
        '푸시업 100개 채우기',
        '랫풀다운',
      ]);
      // 모자란 요인을 채우는 날이라 올리기 칩은 없다.
      expect(d.stepChip, isNull);
    }
  });

  test('S8′ 수·금을 빼면 심폐가 가장 모자라지만 28일 안에 심폐 날이 없어 줄 + 타바타 칩, 근력 날로', () {
    final skip = [
      mw[0],
      mw[1],
      mw[3],
      // 기록한 맨몸 운동 — 타바타로 칩이 이것에 타바타를 붙인다.
      at(DateTime(2026, 9, 15, 7), [
        ExerciseBlock('버피', times(3, () => reps(15))),
      ]),
    ];
    final d = make(skip, sat);
    expect(d.weekCounts, {
      Factor.strength: 1,
      Factor.endurance: 1,
      Factor.sustain: 1,
      Factor.cardio: 0,
    });
    expect(d.missing, [Factor.cardio]);
    expect(d.lines.firstWhere((l) => l.code == 'factorMissing').args.single, [
      'cardio',
    ]);
    expect(d.target, Factor.strength);
    expect(d.short, isTrue);
    expect(d.sourceDay, DateTime(2026, 9, 14));
    expect(d.modeChips.map((c) => c.mode), contains('tabata'));
    // 누르면 기록한 맨몸 운동에 타바타를 붙여 짠다(친 타이머 조건과 같은 길).
    final tabata = make(skip, sat, edits: RoutineEdits()..mode = 'tabata');
    expect(tabata.items, isNotEmpty);
    expect(tabata.items.map((i) => i.key), ['버피']);
    for (final i in tabata.items) {
      expect(TimingSpec.parse(i.title)?.tabata, isTrue, reason: i.title);
    }
  });

  test('S8″ 토요일에 뛴 것은 일요일 셈에 든다', () {
    final withRun = [
      ...mw,
      at(DateTime(2026, 9, 19, 10), [
        ExerciseBlock('러닝', [timed(5, 'km')]),
      ]),
    ];
    final d = make(withRun, DateTime(2026, 9, 20, 10));
    expect(d.weekCounts?[Factor.cardio], 2);
  });

  test('S6 여행 주: 목요일엔 지난 목 러닝(알려진 약점), 다른 루틴 → 2주 전 목; 토요일 셈은 근력 1 · 심폐 1', () {
    final log = [
      ...weekLog(DateTime(2026, 8, 17), 21, splitPlan),
      at(DateTime(2026, 9, 8, 19), [
        ExerciseBlock('푸시업', times(3, () => reps(20))),
      ]),
      at(DateTime(2026, 9, 10, 19), [
        ExerciseBlock('러닝', [timed(5, 'km')]),
      ]),
    ];
    final thu = DateTime(2026, 9, 17, 18);
    final d = make(log, thu);
    expect((d.source, d.sourceDay), ('weekday', DateTime(2026, 9, 10)));
    expect(d.items.single.key, '러닝');
    final alt = make(log, thu, edits: RoutineEdits()..alt = 1);
    expect((alt.weeksAgo, alt.sourceDay), (2, DateTime(2026, 9, 3)));
    final s = make(log, DateTime(2026, 9, 12, 10));
    expect(s.weekCounts, {
      Factor.strength: 1,
      Factor.endurance: 0,
      Factor.sustain: 0,
      Factor.cardio: 1,
    });
  });

  test('S7 첫 주(월·화만): 수요일은 회전, 토요일은 한 번이라도 한 요인만 — 나머지는 줄', () {
    final log = [
      at(DateTime(2026, 9, 14, 19), [
        ExerciseBlock('벤치프레스', times(3, () => kg(60, 10))),
      ]),
      at(DateTime(2026, 9, 15, 19), [
        ExerciseBlock('러닝', [timed(5, 'km')]),
      ]),
    ];
    expect(make(log, DateTime(2026, 9, 16, 18)).source, 'rotation');
    final d = make(log, sat);
    expect(d.source, 'factor');
    expect(d.missing, [Factor.endurance, Factor.sustain]);
    expect(d.target, Factor.strength);
    expect(d.sourceDay, DateTime(2026, 9, 14));
    expect(d.lines.map((l) => l.code), contains('fillHint'));
  });

  test('S11 수요일에 "토요일 루틴" 은 주말 규칙 — 셈은 오늘까지', () {
    final wed = DateTime(2026, 9, 16, 18);
    final log = [
      ...methodWeek(DateTime(2026, 9, 7)),
      ...methodWeek(DateTime(2026, 9, 14)).take(2),
    ];
    final d = make(log, wed, gold: {'when': 6}, text: '토요일 루틴 짜줘');
    expect(d.day, DateTime(2026, 9, 19));
    expect(d.future, isTrue);
    expect(d.source, 'factor');
    // 9/13–9/16 만: 월 순발력(근력) · 화 근지구력.
    expect(d.weekCounts, {
      Factor.strength: 1,
      Factor.endurance: 1,
      Factor.sustain: 0,
      Factor.cardio: 0,
    });
    // 지속력(9/10)·심폐(9/11) 가운데 오래 안 한 지속력.
    expect(d.target, Factor.sustain);
    expect(d.sourceDay, DateTime(2026, 9, 10));
  });

  test('S12 평일 조정 칩: 이 날 요인(근력)을 이번 주 다 채웠고 지속력이 0 이면 칩 하나 — 누르면 지속력 날', () {
    final changed = {
      ...methodPlan,
      4: () => [ExerciseBlock('스쿼트', times(3, () => kg(80, 10)))],
    };
    final log = [
      ...methodWeek(DateTime(2026, 8, 31)),
      ...weekLog(DateTime(2026, 9, 7), 5, changed),
      ...weekLog(DateTime(2026, 9, 14), 3, methodPlan),
    ];
    final thu = DateTime(2026, 9, 17, 18);
    final d = make(log, thu);
    expect((d.source, d.sourceDay), ('weekday', DateTime(2026, 9, 10)));
    expect(d.factor?.factor, Factor.strength);
    expect(d.weekCounts?[Factor.strength], 2);
    expect(d.modeChips, [(mode: 'sustain', count: 0)]);
    final forced = make(log, thu, edits: RoutineEdits()..mode = 'sustain');
    expect(forced.source, 'factor');
    expect(forced.target, Factor.sustain);
    expect(forced.sourceDay, DateTime(2026, 9, 3));
  });

  test('주말에 지난주 같은 요일 기록이 있으면 "지난주 토요일처럼" 칩 — 누르면 같은 요일 규칙', () {
    final log = [
      ...mw,
      at(DateTime(2026, 9, 12, 10), [
        ExerciseBlock('러닝', [timed(5, 'km')]),
      ]),
    ];
    final d = make(log, sat);
    expect(d.source, 'factor');
    expect(d.modeChips.map((c) => c.mode), contains('weekday'));
    final w = make(log, sat, edits: RoutineEdits()..mode = 'weekday');
    expect(
      (w.source, w.weeksAgo, w.sourceDay),
      ('weekday', 1, DateTime(2026, 9, 12)),
    );
  });

  test('픽스처 토요일(오늘 9/9): 심폐 날(9/1 러닝)이 첫 원천, 다른 루틴 → 9/5', () {
    final d = make(
      defaultLog(),
      routineToday,
      gold: {'when': 6},
      text: '토요일 루틴 짜줘',
    );
    expect(d.target, Factor.cardio);
    expect(d.missing, [Factor.endurance, Factor.sustain]);
    expect(d.sourceDay, DateTime(2026, 9, 1));
    final alt = make(
      defaultLog(),
      routineToday,
      gold: {'when': 6},
      text: '토요일 루틴 짜줘',
      edits: RoutineEdits()..alt = 1,
    );
    expect(alt.sourceDay, DateTime(2026, 9, 5));
  });

  test('채점 C14·C15: 고른 까닭이 없거나 원천 날의 요인이 목표와 다르면 깨짐', () {
    final d = make(mw, sat);
    d.target = Factor.cardio;
    expect(
      routineViolations(d, bare, mw, '오늘 루틴 짜줘'),
      contains(startsWith('C15')),
    );
    d.weekCounts = null;
    expect(
      routineViolations(d, bare, mw, '오늘 루틴 짜줘'),
      contains(startsWith('C14')),
    );
    final w = make(mw, DateTime(2026, 9, 24, 18));
    expect(w.source, 'weekday');
    w.weeksAgo = null;
    expect(
      routineViolations(w, bare, mw, '오늘 루틴 짜줘'),
      contains(startsWith('C14')),
    );
  });
}
