import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_ai.dart' show WorkoutSetup;
import 'package:setpad/training_factor.dart';

import 'routine_fixture.dart';

/// 체력 요인 판별(설계 routine-v2 §2.2–2.3). 규칙마다 칸 하나, 문턱의 양쪽.
void main() {
  FactorRead? of(String name, List<LoggedSet> sets, [WorkoutSetup? setup]) =>
      factorOf(ExerciseBlock(name, sets, setup));
  Factor? f(String name, List<LoggedSet> sets, [WorkoutSetup? setup]) =>
      of(name, sets, setup)?.factor;
  // 요인·근거 종류·근거 수(목록은 == 로 견줄 수 없어 글로).
  String show(FactorRead? x) =>
      x == null ? '-' : '${x.factor.name} ${x.why} ${x.args.join(',')}';

  group('칸 하나', () {
    test('1 타바타 제목 → 심폐(확실), 라운드 수만큼 센다', () {
      final x = of('버피 타바타', [reps(10)])!;
      expect(x.factor, Factor.cardio);
      expect(x.sure, isTrue);
      expect(show(x), 'cardio tabata 20/10×8');
      expect(x.weight, 8);
      expect(of('버피 타바타', times(10, () => reps(10)))!.weight, 10);
    });

    test('2 설정 totalReps → 근지구력(확실)', () {
      final x = of('스쿼트 60kg 100개 채우기', [
        kg(60, 30),
        kg(60, 25),
        kg(60, 25),
        kg(60, 20),
      ], const WorkoutSetup(name: '스쿼트', weight: 60, totalReps: 100))!;
      expect(x.sure, isTrue);
      expect(show(x), 'endurance fill 100');
    });

    test('3 설정 없이 제목의 채우기 낱말 → 근지구력(짐작)', () {
      final x = of('푸시업 100개 채우기', [reps(30), reps(30)])!;
      expect((x.factor, x.sure, x.why), (Factor.endurance, false, 'fillTitle'));
      expect(f('푸시업 total 100', [reps(50), reps(50)]), Factor.endurance);
    });

    test('4 시간·거리 세트: 유산소 부위면 심폐, 아니면(플랭크) 없음', () {
      final run = of('러닝', [timed(5, 'km')])!;
      expect(show(run), 'cardio distance 5km');
      expect(f('사이클', [timed(30, 'min')]), Factor.cardio);
      expect(of('플랭크', times(3, () => timed(60, 's'))), isNull);
    });

    test('5 설정에 세트당 횟수만 있고 세트 수가 열려 있음 → 지속력', () {
      final x = of(
        '스쿼트',
        times(5, () => kg(60, 10)),
        const WorkoutSetup(name: '스쿼트', weight: 60, repsPerSet: 10),
      )!;
      expect(show(x), 'sustain open 10');
      // 세트 수까지 정해 두면 근력(5×10).
      expect(
        f(
          '스쿼트',
          times(5, () => kg(60, 10)),
          const WorkoutSetup(
            name: '스쿼트',
            weight: 60,
            repsPerSet: 10,
            totalSets: 5,
          ),
        ),
        Factor.strength,
      );
    });

    test('6 작업 세트 하나에 50회 이상 → 근지구력, 49회는 근력', () {
      expect(of('푸시업', [reps(50)])!.why, 'single');
      expect(f('푸시업', [reps(50)]), Factor.endurance);
      expect(f('푸시업', [reps(49)]), Factor.strength);
    });

    test('7 세트마다 최대(줄기만, 첫 ≥15, 끝 ≤ 첫의 80%) → 근지구력', () {
      final x = of('랫풀다운', [kg(40, 23), kg(40, 18), kg(40, 15)])!;
      expect(show(x), 'endurance drop 23·18·15');
      // 첫 세트 14 → 아님.
      expect(f('랫풀다운', [kg(40, 14), kg(40, 12), kg(40, 10)]), Factor.strength);
      // 끝이 정확히 80% → 맞음, 넘으면 아님.
      expect(f('랫풀다운', [kg(40, 20), kg(40, 18), kg(40, 16)]), Factor.endurance);
      expect(f('랫풀다운', [kg(40, 20), kg(40, 18), kg(40, 17)]), Factor.strength);
      // 두 세트는 모자란다.
      expect(f('랫풀다운', [kg(40, 23), kg(40, 15)]), Factor.strength);
      // 중간에 오르면 아님.
      expect(
        f('랫풀다운', [kg(40, 23), kg(40, 15), kg(40, 18), kg(40, 12)]),
        Factor.strength,
      );
    });

    test('8 같은 횟수 6세트 이상(끝 세트는 모자라도 됨) → 지속력, 5세트는 근력', () {
      final x = of('스쿼트 30bpm', times(7, () => kg(60, 10)))!;
      expect(show(x), 'sustain hold 10,7');
      expect(
        f('벤치프레스 30bpm', [...times(6, () => kg(40, 10)), kg(40, 7)]),
        Factor.sustain,
      );
      expect(f('스쿼트', times(6, () => kg(60, 10))), Factor.sustain);
      expect(f('스쿼트', times(5, () => kg(60, 10))), Factor.strength);
      expect(
        f('스쿼트', [...times(5, () => kg(60, 10)), kg(60, 11)]),
        Factor.strength,
      );
    });

    test('9 작업 세트 최대 5회 이하 → 순발력, 6회는 근력', () {
      final x = of('스쿼트', times(3, () => kg(90, 5)))!;
      expect(show(x), 'power sets 3,5');
      expect(f('스쿼트', times(3, () => kg(90, 6))), Factor.strength);
    });

    test('10 나머지 → 근력(횟수가 많아도, 5×20)', () {
      final x = of('오버헤드프레스', times(3, () => kg(40, 8)))!;
      expect(show(x), 'strength sets 3,8');
      expect(f('푸시업', times(5, () => reps(20))), Factor.strength);
      expect(of('레그컬', [kg(40, 12), kg(40, 12), kg(40, 10)])!.args, [
        '3',
        '12/10',
      ]);
    });

    test('작업 세트: 워밍업(가벼운 세트)은 빼고, 남의 세트·안 한 세트는 보지 않는다', () {
      // 60×10 워밍업 + 80×5×3 → 5회라 순발력.
      expect(
        f('벤치프레스', [kg(60, 10), ...times(3, () => kg(80, 5))]),
        Factor.power,
      );
      // 140×3(민수)은 작업 세트가 아니다 — 105×5×3.
      final dl = of('데드리프트', [
        ...times(3, () => kg(105, 5)),
        kg(140, 3, author: '민수'),
      ])!;
      expect(dl.args, ['3', '5']);
      expect(dl.weight, 3);
      expect(of('벤치프레스', [kg(60, 10, done: false)]), isNull);
      expect(of('벤치프레스', [kg(60, 10, author: '민수')]), isNull);
    });
  });

  group('하루', () {
    Factor? day(List<Note> notes, int m, int d) =>
        dayFactor(notesByDay(notes)[DateTime(2026, m, d)]!)?.factor;

    test('픽스처(K): 무게를 더해 가장 큰 요인', () {
      final log = defaultLog();
      expect(day(log, 8, 24), Factor.strength);
      expect(day(log, 9, 1), Factor.cardio);
      expect(day(log, 9, 2), Factor.strength);
      // 푸시업 3세트(근력) 대 타바타 8라운드(심폐).
      expect(day(log, 9, 5), Factor.cardio);
      expect(day(log, 9, 8), Factor.strength);
    });

    test('방식 주(L): 월 순발력 · 화 근지구력 · 수 근력 · 목 지속력 · 금 심폐', () {
      final log = methodWeek(DateTime(2026, 9, 14));
      expect(
        [for (var d = 14; d <= 18; d++) day(log, 9, d)],
        [
          Factor.power,
          Factor.endurance,
          Factor.strength,
          Factor.sustain,
          Factor.cardio,
        ],
      );
      final tue = dayFactor(notesByDay(log)[DateTime(2026, 9, 15)]!)!;
      expect(tue.read.why, 'fill');
    });

    test('같으면 그날 첫 칸의 요인, 가를 칸이 없으면 없음', () {
      final tie = [
        at(DateTime(2026, 9, 1, 19), [
          ExerciseBlock('스쿼트', times(3, () => kg(90, 5))),
          ExerciseBlock('레그컬', times(3, () => kg(40, 12))),
        ]),
      ];
      expect(day(tie, 9, 1), Factor.power);
      final plank = [
        at(DateTime(2026, 9, 1, 19), [
          ExerciseBlock('플랭크', times(3, () => timed(60, 's'))),
        ]),
      ];
      expect(day(plank, 9, 1), isNull);
    });

    test('하루 두 번(아침 러닝 + 저녁 웨이트)은 한 날 — 세트가 많은 쪽', () {
      final two = [
        at(DateTime(2026, 9, 10, 7), [
          ExerciseBlock('러닝', [timed(5, 'km')]),
        ]),
        at(DateTime(2026, 9, 10, 19), splitPlan[4]!()),
      ];
      expect(notesByDay(two), hasLength(1));
      expect(day(two, 9, 10), Factor.strength);
    });
  });

  group('한 주', () {
    test('최근 7일(짜는 날과 앞 6일, 오늘까지) — 순발력은 근력 칸', () {
      final mw = methodWeek(DateTime(2026, 9, 14));
      final sat = DateTime(2026, 9, 19);
      expect(weekCounts(mw, sat, sat), {
        Factor.strength: 2,
        Factor.endurance: 1,
        Factor.sustain: 1,
        Factor.cardio: 1,
      });
      // 픽스처 오늘 9/9, 토요일 9/12: 9/6–9/9 만 센다(9/5 타바타는 7일 밖).
      expect(weekCounts(defaultLog(), DateTime(2026, 9, 12), routineToday), {
        Factor.strength: 2,
        Factor.endurance: 0,
        Factor.sustain: 0,
        Factor.cardio: 0,
      });
      // 토요일에 뛴 것은 일요일 셈에 든다.
      final withSat = [
        ...mw,
        at(DateTime(2026, 9, 19, 10), [
          ExerciseBlock('러닝', [timed(5, 'km')]),
        ]),
      ];
      final sun = DateTime(2026, 9, 20);
      expect(weekCounts(withSat, sun, sun)[Factor.cardio], 2);
      // 오늘 뒤의 기록은 세지 않는다.
      expect(weekCounts(mw, sat, DateTime(2026, 9, 15))[Factor.strength], 1);
    });

    test('모자란 순서: 모자람 → 오래 안 한 것(안 했으면 먼저) → 근력·근지구력·지속력·심폐', () {
      final all = {
        Factor.strength: 2,
        Factor.endurance: 1,
        Factor.sustain: 1,
        Factor.cardio: 1,
      };
      final last = {
        Factor.strength: DateTime(2026, 9, 16),
        Factor.endurance: DateTime(2026, 9, 15),
        Factor.sustain: DateTime(2026, 9, 17),
        Factor.cardio: DateTime(2026, 9, 18),
      };
      expect(rankFactors(all, last).first, Factor.endurance);
      final gap = {...all, Factor.strength: 1, Factor.cardio: 0};
      expect(rankFactors(gap, {...last}..remove(Factor.cardio)).take(2), [
        Factor.cardio,
        Factor.strength,
      ]);
      expect(rankFactors(all, const {}), [
        Factor.strength,
        Factor.endurance,
        Factor.sustain,
        Factor.cardio,
      ]);
    });
  });
}
