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

/// 체성분 한 번(인바디 결과지나 손으로 적은 것). 적힌 값만 — 모르는 칸은 null.
/// 기기 안에만 둔다. 사진은 읽을 때 한 번 서버의 모델에 건네고 남기지 않는다.
class BodyRecord {
  const BodyRecord({
    required this.id,
    required this.on,
    this.weightKg,
    this.skeletalMuscleKg,
    this.bodyFatKg,
    this.bodyFatPercent,
    this.bmi,
    this.bmrKcal,
    this.visceralFatLevel,
  });
  final String id;

  /// 잰 날(현지 날짜).
  final DateTime on;
  final double? weightKg, skeletalMuscleKg, bodyFatKg, bodyFatPercent, bmi;
  final double? bmrKcal, visceralFatLevel;

  bool get empty => [
    weightKg,
    skeletalMuscleKg,
    bodyFatKg,
    bodyFatPercent,
    bmi,
    bmrKcal,
    visceralFatLevel,
  ].every((v) => v == null);

  Map<String, Object?> toJson() => {
    'id': id,
    'on':
        '${on.year.toString().padLeft(4, '0')}-${on.month.toString().padLeft(2, '0')}-${on.day.toString().padLeft(2, '0')}',
    'weightKg': ?weightKg,
    'skeletalMuscleKg': ?skeletalMuscleKg,
    'bodyFatKg': ?bodyFatKg,
    'bodyFatPercent': ?bodyFatPercent,
    'bmi': ?bmi,
    'bmrKcal': ?bmrKcal,
    'visceralFatLevel': ?visceralFatLevel,
  };

  static BodyRecord? tryFromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], on = j['on'];
    final day = on is String ? DateTime.tryParse(on) : null;
    if (id is! String || day == null) return null;
    double? n(Object? v) =>
        v is num && v.isFinite && v > 0 ? v.toDouble() : null;
    final r = BodyRecord(
      id: id,
      on: DateTime(day.year, day.month, day.day),
      weightKg: n(j['weightKg']),
      skeletalMuscleKg: n(j['skeletalMuscleKg']),
      bodyFatKg: n(j['bodyFatKg']),
      bodyFatPercent: n(j['bodyFatPercent']),
      bmi: n(j['bmi']),
      bmrKcal: n(j['bmrKcal']),
      visceralFatLevel: n(j['visceralFatLevel']),
    );
    return r.empty ? null : r;
  }
}

/// 그날의 몸무게: 그날까지 잰 가장 최근 기록, 없으면 몸 정보에 적은 값.
double? weightOn(DateTime day, List<BodyRecord> records, BodyProfile profile) {
  final end = DateTime(day.year, day.month, day.day + 1);
  BodyRecord? best;
  for (final r in records) {
    if (r.weightKg == null || !r.on.isBefore(end)) continue;
    if (best == null || r.on.isAfter(best.on)) best = r;
  }
  return best?.weightKg ?? profile.weightKg;
}

/// 워치 없이 한 근력 운동의 **활동** 에너지 어림(kcal).
///
/// 2024 Compendium of Physical Activities 의 저항 운동(02052, 스쿼트·데드리프트 등) 5.0 MET 에서
/// 쉬는 몫 1 MET 를 뺀 4.0 × 몸무게(kg) × 시간. 쉬는 몫은 하루 기초대사량이 따로 세므로 빼야
/// 두 번 더하지 않는다. 시간은 세트마다 약 2.5분(한 세트와 그 뒤 휴식)으로 보고 3시간에서 자른다
/// — 문서를 연 시각·고친 시각은 나중에 몰아 적거나 저녁에 다시 열면 엉뚱해진다.
/// 무게·횟수는 넣지 않는다: 그럴듯해 보여도 휴식과 속도를 모르는 식은 더 정확하지 않다.
/// 워치가 잰 값이 있으면 그것을 쓴다 — 이것은 없을 때만, 늘 '추정'으로 보인다.
double? strengthKcal({required int sets, required double? weightKg}) {
  if (weightKg == null || weightKg <= 0 || sets <= 0) return null;
  final hours = (sets * 2.5).clamp(0, 180) / 60;
  return (5.0 - 1.0) * weightKg * hours;
}
