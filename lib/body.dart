/// 내 몸 정보 — 기초대사량을 셈하는 데만 쓴다. 기기 밖으로 보내지 않는다.
library;

class BodyProfile {
  const BodyProfile({this.heightCm, this.weightKg, this.birthYear, this.sex});
  final double? heightCm, weightKg;
  final int? birthYear;

  /// 'm' 또는 'f'.
  final String? sex;

  bool get complete =>
      heightCm != null && weightKg != null && birthYear != null && sex != null;

  /// 하루 기초대사량(kcal) — Mifflin-St Jeor 식. 넷 중 하나라도 없으면 null.
  /// 10×몸무게 + 6.25×키 − 5×나이 + (남 5 / 여 −161).
  double? bmrPerDay(DateTime on) {
    if (!complete) return null;
    final age = on.year - birthYear!;
    return 10 * weightKg! +
        6.25 * heightCm! -
        5 * age +
        (sex == 'm' ? 5 : -161);
  }

  Map<String, Object?> toJson() => {
    'heightCm': ?heightCm,
    'weightKg': ?weightKg,
    'birthYear': ?birthYear,
    'sex': ?sex,
  };

  static BodyProfile fromJson(Object? j) {
    if (j is! Map) return const BodyProfile();
    double? n(Object? v) => v is num && v > 0 ? v.toDouble() : null;
    final y = j['birthYear'], s = j['sex'];
    return BodyProfile(
      heightCm: n(j['heightCm']),
      weightKg: n(j['weightKg']),
      birthYear: y is int && y > 1900 ? y : null,
      sex: s == 'm' || s == 'f' ? s as String : null,
    );
  }
}

/// 그날 기초대사량. [measured] 는 건강 앱이 잰 값(없으면 null). 없으면 몸 정보로
/// 셈한다 — 오늘은 지금까지 지난 시간만큼만(먹은 것도 지금까지라 견줄 수 있다).
({double kcal, bool estimate})? basalFor(
  DateTime day,
  BodyProfile body, {
  double? measured,
  DateTime? now,
}) {
  if (measured != null && measured > 0) {
    return (kcal: measured, estimate: false);
  }
  final perDay = body.bmrPerDay(day);
  if (perDay == null) return null;
  final t = now ?? DateTime.now();
  final start = DateTime(day.year, day.month, day.day);
  final end = start.add(const Duration(days: 1));
  final share = t.isBefore(end)
      ? (t.difference(start).inMinutes.clamp(0, 1440) / 1440)
      : 1.0;
  return (kcal: perDay * share, estimate: true);
}
