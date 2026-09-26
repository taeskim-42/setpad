import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/body.dart';

void main() {
  const me = BodyProfile(heightCm: 178, weightKg: 80, birthYear: 1996, sex: 'm');
  test('Mifflin-St Jeor — 30세 남성 178cm 80kg 은 하루 1,767.5kcal', () {
    // 10×80 + 6.25×178 − 5×30 + 5 = 800 + 1112.5 − 150 + 5
    expect(me.bmrPerDay(DateTime(2026, 9, 26)), 1767.5);
    expect(const BodyProfile(heightCm: 178, weightKg: 80).bmrPerDay(DateTime(2026)), isNull);
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
}
