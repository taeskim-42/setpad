import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/body.dart';
import 'package:setpad/editor.dart';

void main() {
  const me = BodyProfile(
    heightCm: 178,
    weightKg: 80,
    birthYear: 1996,
    sex: 'm',
  );
  test('Mifflin-St Jeor — 30세 남성 178cm 80kg 은 하루 1,767.5kcal', () {
    // 10×80 + 6.25×178 − 5×30 + 5 = 800 + 1112.5 − 150 + 5
    expect(me.bmrPerDay(DateTime(2026, 9, 26)), 1767.5);
    expect(
      const BodyProfile(heightCm: 178, weightKg: 80).bmrPerDay(DateTime(2026)),
      isNull,
    );
  });

  test('건강 앱 값이 먼저, 없으면 셈 — 오늘은 지난 시간만큼', () {
    final day = DateTime(2026, 9, 26);
    expect(basalFor(day, me, measured: 1650), (kcal: 1650.0, estimate: false));
    final noon = basalFor(day, me, now: DateTime(2026, 9, 26, 12));
    expect(noon!.kcal, closeTo(1767.5 / 2, 0.01));
    expect(noon.estimate, isTrue);
    expect(basalFor(day, me, now: DateTime(2026, 9, 28))!.kcal, 1767.5);
    expect(basalFor(day, const BodyProfile()), isNull);
  });

  test('체성분 기록은 저장했다 그대로 읽히고, 값이 하나도 없으면 기록이 아니다', () {
    final r = BodyRecord(
      id: 'b1',
      on: DateTime(2026, 9, 28),
      weightKg: 72.4,
      skeletalMuscleKg: 33.1,
      bodyFatPercent: 19.6,
    );
    final back = BodyRecord.tryFromJson(r.toJson())!;
    expect(
      [
        back.on,
        back.weightKg,
        back.skeletalMuscleKg,
        back.bodyFatPercent,
        back.bmi,
      ],
      [DateTime(2026, 9, 28), 72.4, 33.1, 19.6, null],
    );
    expect(BodyRecord.tryFromJson({'id': 'b2', 'on': '2026-09-28'}), isNull);
    expect(
      BodyRecord.tryFromJson({'id': 'b3', 'on': 'nope', 'weightKg': 70}),
      isNull,
    );
  });

  test('그날의 몸무게: 그날까지 가장 최근 기록, 없으면 몸 정보', () {
    final records = [
      BodyRecord(id: 'a', on: DateTime(2026, 9, 1), weightKg: 75),
      BodyRecord(id: 'b', on: DateTime(2026, 9, 20), weightKg: 73),
      BodyRecord(id: 'c', on: DateTime(2026, 9, 25), bodyFatPercent: 18),
    ];
    expect(weightOn(DateTime(2026, 9, 10), records, me), 75);
    expect(
      weightOn(DateTime(2026, 9, 26), records, me),
      73,
      reason: '몸무게가 없는 기록은 건너뛴다',
    );
    expect(
      weightOn(DateTime(2026, 8, 1), records, me),
      80,
      reason: '기록 전이면 몸 정보',
    );
    expect(
      weightOn(DateTime(2026, 8, 1), records, const BodyProfile()),
      isNull,
    );
  });

  test('워치 없는 근력 운동: (5.0 − 1) MET × kg × 세트당 2.5분, 3시간에서 자른다', () {
    // 70kg, 20세트 = 50분 → 4 × 70 × 50/60 ≈ 233kcal
    expect(strengthKcal(sets: 20, weightKg: 70), closeTo(233.3, 0.1));
    expect(strengthKcal(sets: 200, weightKg: 70), closeTo(4 * 70 * 3, 0.001));
    expect(strengthKcal(sets: 20, weightKg: null), isNull);
    expect(strengthKcal(sets: 0, weightKg: 70), isNull);
  });

  test('종목별 MET: 데드리프트 6.0, 벤치 5.0, 머신·모르는 이름 3.5, 러닝 9.8, 코어 2.8', () {
    expect(metFor('데드리프트'), 6.0);
    expect(metFor('Bench Press'), 5.0);
    expect(metFor('레그익스텐션'), 3.5);
    expect(metFor('엄마표 운동'), 3.5);
    expect(metFor('러닝'), 9.8);
    expect(metFor('플랭크'), 2.8);
  });

  test('종목마다 (MET − 1) × kg × 시간 — 러닝 5km 는 10km/h 로 30분, 3시간에서 자른다', () {
    final dead = ExerciseBlock('데드리프트', [
      for (var i = 0; i < 4; i++) LoggedSet(value: 140, reps: 5),
    ]);
    final run = ExerciseBlock('러닝', [LoggedSet(value: 5, unit: 'km')]);
    // 데드리프트 4세트 = 10분 → 5 × 80 × 10/60 ≈ 66.7, 러닝 5km = 0.5시간 → 8.8 × 80 × 0.5 = 352
    expect(workoutKcal([dead], 80), closeTo(66.67, 0.01));
    expect(workoutKcal([run], 80), closeTo(352, 0.01));
    expect(workoutKcal([dead, run], null), isNull);
    final long = ExerciseBlock('러닝', [LoggedSet(value: 5, unit: 'h')]);
    expect(workoutKcal([long], 80), closeTo(8.8 * 80 * 3, 0.01));
  });

  test('기초대사량: 결과지 값 → 제지방량(Katch–McArdle) → 키·몸무게', () {
    final day = DateTime(2026, 9, 30);
    expect(bmrOn(day, me, BodyRecord(id: 'a', on: day, bmrKcal: 1700)), 1700);
    // 80kg, 체지방 16kg → 제지방 64kg → 370 + 21.6 × 64 = 1752.4
    expect(
      bmrOn(day, me, BodyRecord(id: 'b', on: day, weightKg: 80, bodyFatKg: 16)),
      closeTo(1752.4, 0.01),
    );
    expect(bmrOn(day, me, null), 1767.5);
  });

  test('목적에 맞춘 하루 목표: 감량은 −20%, 단백질을 먼저 채우고 지방 25%, 탄수화물은 나머지', () {
    final t = macroTarget(
      goal: 'lose',
      weightKg: 80,
      bmrPerDay: 1750,
      exerciseKcal: 300,
    )!;
    // (1750 × 1.2 + 300) × 0.8 = 1920kcal, 단백 2.2 × 80 = 176g, 지방 max(1920×0.25/9, 48) = 53.3g
    expect(t.kcal, closeTo(1920, 0.01));
    expect(t.protein, closeTo(176, 0.01));
    expect(t.fat, closeTo(53.33, 0.01));
    expect(t.carbs, closeTo((1920 - 176 * 4 - 53.33 * 9) / 4, 0.05));
    expect(
      macroTarget(
        goal: 'lose',
        weightKg: 80,
        bmrPerDay: 1750,
        leanKg: 64,
      )!.protein,
      closeTo(166.4, 0.01),
      reason: '제지방량을 알면 제지방 kg 당 2.6g',
    );
    expect(macroTarget(goal: null, weightKg: 80, bmrPerDay: 1750), isNull);
    expect(const BodyProfile(goal: 'gain').goal, 'gain');
    expect(BodyProfile.fromJson({'goal': 'bogus'}).goal, isNull);
  });
}
