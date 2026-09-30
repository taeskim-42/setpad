/// 내 몸 정보 — 기초대사량·운동 칼로리·탄단지 목표를 셈하는 데만 쓴다. 기기 밖으로 보내지 않는다.
library;

import 'editor.dart';
import 'exercises.dart';
import 'units.dart';

class BodyProfile {
  const BodyProfile({
    this.heightCm,
    this.weightKg,
    this.birthYear,
    this.sex,
    this.goal,
  });
  final double? heightCm, weightKg;
  final int? birthYear;

  /// 'm' 또는 'f'.
  final String? sex;

  /// 운동 목적: 'lose'(체지방 감량) · 'maintain'(유지) · 'gain'(근육 증가). 없으면 탄단지 목표를 안 낸다.
  final String? goal;
  static const goals = ['lose', 'maintain', 'gain'];

  BodyProfile copyWith({double? weightKg, double? heightCm, String? goal}) =>
      BodyProfile(
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        birthYear: birthYear,
        sex: sex,
        goal: goal ?? this.goal,
      );

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
    'goal': ?goal,
  };

  static BodyProfile fromJson(Object? j) {
    if (j is! Map) return const BodyProfile();
    double? n(Object? v) => v is num && v > 0 ? v.toDouble() : null;
    final y = j['birthYear'], s = j['sex'], g = j['goal'];
    return BodyProfile(
      heightCm: n(j['heightCm']),
      weightKg: n(j['weightKg']),
      birthYear: y is int && y > 1900 ? y : null,
      sex: s == 'm' || s == 'f' ? s as String : null,
      goal: goals.contains(g) ? g as String : null,
    );
  }
}

/// 하루 기초대사량을 가장 믿을 만한 것으로: 체성분 결과지에 적힌 값, 없으면 제지방량(몸무게 − 체지방량)
/// 으로 Katch–McArdle(370 + 21.6 × 제지방량), 그것도 없으면 Mifflin-St Jeor. 근육이 많은 사람은 같은
/// 몸무게라도 기초대사량이 높다 — 결과지가 있으면 그것을 쓴다.
double? bmrOn(DateTime day, BodyProfile body, BodyRecord? record) {
  if (record?.bmrKcal case final b? when b >= 500 && b <= 5000) return b;
  final w = record?.weightKg, fat = record?.bodyFatKg;
  final lean = w != null && fat != null && fat < w
      ? w - fat
      : w != null && record?.bodyFatPercent != null
      ? w * (1 - record!.bodyFatPercent! / 100)
      : null;
  if (lean != null && lean > 20) return 370 + 21.6 * lean;
  return body.bmrPerDay(day);
}

/// 그날까지의 가장 최근 체성분 기록.
BodyRecord? recordOn(DateTime day, List<BodyRecord> records) {
  final end = DateTime(day.year, day.month, day.day + 1);
  BodyRecord? best;
  for (final r in records) {
    if (!r.on.isBefore(end)) continue;
    if (best == null || r.on.isAfter(best.on)) best = r;
  }
  return best;
}

/// 그날 기초대사량. [measured] 는 건강 앱이 잰 값(없으면 null). 없으면 체성분 기록·몸 정보로
/// 셈한다([bmrOn]) — 오늘은 지금까지 지난 시간만큼만(먹은 것도 지금까지라 견줄 수 있다).
({double kcal, bool estimate})? basalFor(
  DateTime day,
  BodyProfile body, {
  double? measured,
  DateTime? now,
  BodyRecord? record,
}) {
  if (measured != null && measured > 0) {
    return (kcal: measured, estimate: false);
  }
  final perDay = bmrOn(day, body, record);
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

/// 종목별 MET — 2024 Compendium of Physical Activities. 사전에 없는 이름은 부위로, 그것도 모르면
/// 일반 근력 운동(02054, 3.5).
///  - 02050 파워리프팅·보디빌딩 고강도 6.0, 02052 스쿼트·데드리프트 5.0, 02054 여러 종목 8–15회 3.5
///  - 02040 맨몸 운동(푸시업·풀업·딥스) 3.8, 02020 고강도 맨몸(버피·점핑잭) 8.0, 02022 윗몸일으키기 2.8
///  - 러닝 10km/h 9.8, 실내 자전거 보통 6.8, 로잉 머신 보통 7.0, 일립티컬 5.0, 스텝밀 9.0
const exerciseMet = <String, double>{
  '데드리프트': 6.0,
  '파워클린': 6.0,
  '스쿼트': 5.0,
  '프론트 스쿼트': 5.0,
  '루마니안 데드리프트': 5.0,
  '굿모닝': 5.0,
  '핵스쿼트': 5.0,
  '레그프레스': 5.0,
  '런지': 5.0,
  '불가리안 스플릿 스쿼트': 5.0,
  '힙쓰러스트': 5.0,
  '벤치프레스': 5.0,
  '인클라인 벤치프레스': 5.0,
  '디클라인 벤치프레스': 5.0,
  '오버헤드프레스': 5.0,
  '바벨로우': 5.0,
  '티바로우': 5.0,
  '푸시업': 3.8,
  '풀업': 3.8,
  '친업': 3.8,
  '딥스': 3.8,
  '버피': 8.0,
  '점핑잭': 8.0,
  '러닝': 9.8,
  '사이클': 6.8,
  '로잉': 7.0,
  '일립티컬': 5.0,
  '스텝밀': 9.0,
};

/// 거리로 적은 유산소의 보통 속도(km/h) — 시간이 없을 때 시간을 셈한다.
const _speed = <String, double>{'러닝': 10, '사이클': 20, '로잉': 15};

double metFor(String name) {
  final ko = exerciseByName[name.trim().toLowerCase()]?.ko;
  if (ko != null && exerciseMet[ko] != null) return exerciseMet[ko]!;
  return switch (partOf(name)) {
    'cardio' => 7.0,
    'core' => 2.8,
    _ => 3.5,
  };
}

/// 한 종목(블록)을 하는 데 든 시간(시간 단위). 근력 세트는 한 세트와 그 뒤 휴식으로 2.5분,
/// 시간으로 적은 세트는 그 시간(근력·코어는 쉬는 1분을 더해), 거리로 적은 유산소는 보통 속도로.
double blockHours(ExerciseBlock block) {
  final ko = exerciseByName[block.name.trim().toLowerCase()]?.ko;
  final cardio = partOf(block.name) == 'cardio';
  var hours = 0.0;
  for (final set in block.sets.where((s) => s.mine)) {
    final unit = unitById[set.unit];
    final v = set.value;
    if (unit?.kind == UnitKind.duration && v != null && v > 0) {
      final seconds = switch (set.unit) {
        'min' => v * 60,
        'h' => v * 3600,
        _ => v,
      };
      hours += seconds / 3600 + (cardio ? 0 : 1 / 60);
    } else if (unit?.kind == UnitKind.distance &&
        v != null &&
        v > 0 &&
        cardio) {
      final km = switch (set.unit) {
        'm' => v / 1000,
        'mi' => v * 1.609,
        _ => v,
      };
      hours += km / (_speed[ko] ?? 8);
    } else {
      hours += 2.5 / 60;
    }
  }
  return hours;
}

/// 워치 없이 한 운동의 **활동** 에너지 어림(kcal): 종목마다 (MET − 1) × 몸무게 × 시간을 더한다.
/// 쉬는 몫 1 MET 는 하루 기초대사량이 따로 세므로 빼야 두 번 더하지 않는다. 합쳐 3시간에서 자른다.
/// 무게·횟수는 넣지 않는다: 그럴듯해 보여도 휴식과 속도를 모르는 식은 더 정확하지 않다.
double? workoutKcal(Iterable<ExerciseBlock> blocks, double? weightKg) {
  if (weightKg == null || weightKg <= 0) return null;
  var kcal = 0.0, hours = 0.0;
  for (final b in blocks) {
    final h = blockHours(b);
    if (h <= 0) continue;
    final room = (3 - hours).clamp(0, 3).toDouble();
    final used = h < room ? h : room;
    kcal += (metFor(b.name) - 1) * weightKg * used;
    hours += used;
  }
  return hours > 0 ? kcal : null;
}

/// 운동 목적에 맞춘 하루 목표(kcal, g). 체중 대비 단백질이 먼저고, 지방은 열량의 25%(체중 kg 당 0.6g
/// 아래로는 내리지 않는다), 탄수화물은 나머지다.
///  - 열량: 기초대사량 × 1.2(일상) + 그날 운동, 감량 −20% · 유지 · 증량 +10%.
///  - 단백질: 감량 2.2g/kg(제지방량을 알면 2.6g/kg 제지방), 유지 1.6g/kg, 증량 2.0g/kg — ISSN 입장문
///    (운동하는 사람 1.4–2.0g/kg, 열량을 줄일 때 제지방 kg 당 2.3–3.1g).
typedef MacroTarget = ({double kcal, double protein, double fat, double carbs});

MacroTarget? macroTarget({
  required String? goal,
  required double? weightKg,
  required double? bmrPerDay,
  double exerciseKcal = 0,
  double? leanKg,
}) {
  if (goal == null || weightKg == null || bmrPerDay == null) return null;
  final factor = switch (goal) {
    'lose' => 0.8,
    'gain' => 1.1,
    _ => 1.0,
  };
  final kcal = (bmrPerDay * 1.2 + exerciseKcal) * factor;
  final protein = switch (goal) {
    'lose' => leanKg != null ? 2.6 * leanKg : 2.2 * weightKg,
    'gain' => 2.0 * weightKg,
    _ => 1.6 * weightKg,
  };
  final fat = [kcal * 0.25 / 9, 0.6 * weightKg].reduce((a, b) => a > b ? a : b);
  final carbs = ((kcal - protein * 4 - fat * 9) / 4).clamp(0, 2000).toDouble();
  return (kcal: kcal, protein: protein, fat: fat, carbs: carbs);
}

/// 제지방량(kg) — 체성분 기록에서. 모르면 null.
double? leanOf(BodyRecord? r) {
  final w = r?.weightKg;
  if (w == null) return null;
  if (r!.bodyFatKg case final f? when f < w) return w - f;
  if (r.bodyFatPercent case final p?) return w * (1 - p / 100);
  return null;
}
