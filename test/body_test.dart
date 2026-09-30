import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/body.dart';

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
}
