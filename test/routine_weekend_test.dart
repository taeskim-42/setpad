import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_ai.dart' show WorkoutSetup;
import 'package:setpad/record_query.dart' show recordedExercises;
import 'package:setpad/routine.dart';
import 'package:setpad/routine_card.dart' show routineLineTexts, routineWhy;
import 'package:setpad/training_factor.dart';
import 'package:setpad/workout_timing.dart';

import '../tool/routine_grading.dart';
import 'routine_fixture.dart';

/// 주말 = 최근 7일에 모자란 체력 요인(설계 routine-v2 §3.2, §8.1 S6–S8″·S11·S12).
void main() {
  setUpAll(() => initializeDateFormatting());
  final l = lookupL(const Locale('ko'));
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
      // 순서는 모자람이 먼저라 "가장 오래 안 한" 이라고 하지 않는다.
      expect(
        routineWhy(l, d),
        '이번 주 요인은 다 채웠어요 — 다음 차례인 근지구력으로 화요일(9. 15.)처럼 짰어요',
      );
    }
  });

  test('다 채우지 않았는데 모자란 요인의 날이 없으면 "다 채웠어요" 라고 하지 않는다', () {
    final log = [
      at(DateTime(2026, 9, 14, 19), [
        ExerciseBlock('벤치프레스', times(3, () => kg(60, 10))),
      ]),
      at(DateTime(2026, 9, 16, 19), [
        ExerciseBlock('스쿼트', times(7, () => kg(60, 10))),
      ]),
      at(DateTime(2026, 9, 17, 19), [
        ExerciseBlock('오버헤드프레스', times(3, () => kg(40, 10))),
      ]),
    ];
    final d = make(log, sat);
    expect((d.target, d.short), (Factor.sustain, false));
    expect(d.missing, [Factor.endurance, Factor.cardio]);
    expect(
      routineWhy(l, d),
      '모자란 요인은 최근 28일에 쓸 수 있는 날이 없어 수요일(9. 16.) 지속력 날처럼 짰어요',
    );
  });

  // 이번 주: 월 근력 · 수 지속력 · 목 근력 · 금 타바타. 지난 화(9/8)는 스쿼트 채우기(4세트)
  // + 벤치 3×10 — 채우기가 본운동이라 근지구력 날. [warmUp] 이면 러닝 10분으로 몸을 푼 뒤라
  // 채우기가 첫 칸이 아니어도 본운동이다.
  List<Note> endLog({bool warmUp = false}) {
    final fill = ExerciseBlock('스쿼트 60kg 100개 채우기', [
      kg(60, 30),
      kg(60, 25),
      kg(60, 25),
      kg(60, 20),
    ], const WorkoutSetup(name: '스쿼트', weight: 60, totalReps: 100));
    final bench = ExerciseBlock('벤치프레스', times(3, () => kg(60, 10)));
    return [
      at(DateTime(2026, 9, 8, 19), [
        if (warmUp) ExerciseBlock('러닝', [timed(10, 'min')]),
        fill,
        bench,
      ]),
      at(DateTime(2026, 9, 14, 19), [
        ExerciseBlock('데드리프트', times(3, () => kg(100, 10))),
        ExerciseBlock('랫풀다운', times(3, () => kg(50, 10))),
      ]),
      at(DateTime(2026, 9, 16, 19), [
        ExerciseBlock('레그프레스', times(7, () => kg(150, 10))),
      ]),
      at(DateTime(2026, 9, 17, 19), [
        ExerciseBlock('오버헤드프레스', times(3, () => kg(40, 10))),
      ]),
      at(DateTime(2026, 9, 18, 19), [
        ExerciseBlock('버피 타바타', [reps(40)]),
      ]),
    ];
  }

  test('모자란 요인의 칸을 빼라고 하면 그 날은 그 요인 날이 아니다 — 줄로 말하고 다음 요인', () {
    final log = endLog();
    final plain = make(log, sat);
    expect(
      (plain.target, plain.sourceDay),
      (Factor.endurance, DateTime(2026, 9, 8)),
    );
    final d = make(
      log,
      sat,
      gold: {
        'exclude': ['스쿼트'],
      },
      text: '스쿼트 말고',
    );
    expect(d.target, isNot(Factor.endurance));
    expect(d.factorFiltered, [Factor.endurance]);
    expect(d.missing, isEmpty);
    expect([
      for (final x in d.lines) ...routineLineTexts(l, x),
    ], contains('빼라고 한 운동을 빼면 최근 28일에 남는 날이 없는 요인: 근지구력'));
  });

  test('개수를 줄여도 목표 요인 칸은 남긴다(그날 순서대로) — 요인 머리도 남은 칸으로', () {
    // 몸풀기 러닝이 첫 칸이라 앞에서 자르면 채우기가 빠진다.
    final log = endLog(warmUp: true);
    const why = '이번 주 근지구력이 부족해서 화요일(9. 8.)로 짰어요';
    final d = make(log, sat, gold: {'count': 1}, text: '1개만');
    expect((d.source, d.target), ('factor', Factor.endurance));
    expect(d.items.map((i) => i.title), ['스쿼트 60kg 100개 채우기']);
    expect(d.factor?.factor, Factor.endurance);
    expect(routineWhy(l, d), why);
    final two = make(log, sat, gold: {'count': 2}, text: '2개만');
    expect(two.items.map((i) => i.title), ['러닝', '스쿼트 60kg 100개 채우기']);
    expect(two.factor?.factor, Factor.endurance);
    expect(routineWhy(l, two), why);
  });

  test('목표 요인 칸을 ✕ 로 빼면 "부족해서" 대신 빠졌다고 말한다', () {
    final log = endLog(warmUp: true);
    final d = make(
      log,
      sat,
      edits: RoutineEdits()..removed.add('2026-09-08|스쿼트'),
    );
    expect((d.source, d.target), ('factor', Factor.endurance));
    expect(d.items.map((i) => i.key), ['러닝', '벤치프레스']);
    expect(d.factor?.factor, Factor.strength);
    expect(routineWhy(l, d), isNull);
    expect([
      for (final x in d.lines) ...routineLineTexts(l, x),
    ], contains('화요일(9. 8.) 근지구력 날로 짰지만 근지구력 칸은 빠졌어요'));
  });

  test('S8′ 수·금을 빼면 심폐가 가장 모자라지만 28일 안에 심폐 날이 없어 줄 + 타바타 칩, 근력 날로', () {
    final skip = [
      mw[0],
      mw[1],
      mw[3],
      // 기록한 맨몸 운동 — 타바타로 칩이 이것에 타바타를 붙인다. 화요일 채우기 뒤의
      // 마무리라 그날은 근지구력 날 그대로다(본운동은 첫 칸).
      at(DateTime(2026, 9, 15, 20), [
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

  test('픽스처 토요일(오늘 9/9): 심폐 날(9/1 러닝)이 첫 원천, 다른 루틴 → 타바타로 시작한 9/5', () {
    // 픽스처의 9/5 는 푸시업이 본운동이고 타바타는 마무리라 근력 날이다 — 타바타를 앞에 두어
    // 두 번째 심폐 날로 만든다.
    final log = [
      for (final n in defaultLog())
        n.id == '0905' ? session('0905', 9, 5, n.blocks.reversed.toList()) : n,
    ];
    RoutineDraft saturday({int alt = 0}) => make(
      log,
      routineToday,
      gold: {'when': 6},
      text: '토요일 루틴 짜줘',
      edits: RoutineEdits()..alt = alt,
    );
    final d = saturday();
    expect(d.target, Factor.cardio);
    expect(d.missing, [Factor.endurance, Factor.sustain]);
    expect(d.sourceDay, DateTime(2026, 9, 1));
    final alt = saturday(alt: 1);
    expect((alt.source, alt.sourceDay), ('factor', DateTime(2026, 9, 5)));
    expect(alt.factor?.factor, Factor.cardio);
    expect(routineWhy(l, alt), '이번 주 심폐가 부족해서 토요일(9. 5.)로 짰어요');
    // 픽스처 그대로면 심폐 날은 9/1 하나 — 다른 루틴은 회전으로 넘어간다.
    final plain = make(
      defaultLog(),
      routineToday,
      gold: {'when': 6},
      text: '토요일 루틴 짜줘',
      edits: RoutineEdits()..alt = 1,
    );
    expect((plain.source, plain.sourceDay), ('rotation', DateTime(2026, 9, 2)));
  });

  test('채점 C14·C15: 고른 까닭이 없거나 원천 날의 요인이 목표와 다르면 깨짐', () {
    final d = make(mw, sat);
    d.target = Factor.cardio;
    expect(
      routineViolations(d, bare, mw, '오늘 루틴 짜줘'),
      contains(startsWith('C15')),
    );
    // C15 는 루틴에 남은 칸으로 본다 — 채우기 칸이 빠졌는데 말하지 않으면 깨짐.
    final log = endLog(warmUp: true);
    final cut = make(log, sat);
    cut.items.removeWhere((i) => i.key == '스쿼트');
    expect(
      routineViolations(cut, bare, log, '오늘 루틴 짜줘'),
      contains(startsWith('C15')),
    );
    // 남았는데 빠졌다고 말해도 깨짐.
    final said = make(log, sat)
      ..lines.add(
        RoutineLine('factorLost', ['endurance', DateTime(2026, 9, 8)]),
      );
    expect(
      routineViolations(said, bare, log, '오늘 루틴 짜줘'),
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
