/// 체력 요인 — 기록된 **방식**으로 칸(운동 한 블록)과 하루의 요인을 가른다.
///
/// 요인은 운동 종목이 아니라 변인(세트·횟수·채우기·타바타)으로 갈린다(repstack
/// training_constants.rb TM01–TM04 를 바꿔 가져옴 — TM05 의 속도·완전 회복은 기록에
/// 없어 "작업 세트 5회 이하" 로 대신한다). 입력은 내 해낸 세트(`mine`)와 제목·설정뿐이다 —
/// 가동범위·보통 휴식·심박 휴식은 기록에 없어 쓰지 않는다. bpm 은 근력·근지구력·
/// 지속력이 모두 30 이라 신호가 아니다.
library;

import 'editor.dart' show ExerciseBlock, LoggedSet;
import 'exercises.dart' show partOf;
import 'notes.dart';
import 'record_query.dart' show exerciseKey;
import 'workout_timing.dart' show TimingSpec;

enum Factor { strength, endurance, sustain, power, cardio }

/// 칸 하나의 판별: 요인·확실도·근거(문구 종류와 수).
///
/// 근거 [why]: tabata · fill · fillTitle · distance · open · single · drop · hold ·
/// sets. [args] 는 언어와 무관한 수와 원문 조각이다.
typedef FactorRead = ({
  Factor factor,
  bool sure,
  String why,
  List<String> args,
});

// 문턱(repstack 상수와 BG 예에서 끌어낸 해석 — 테스트로 못 박는다).
const singleFillReps = 50; // 한 세트 50회 이상 = 근지구력(중급 "100회 도전")
const dropFirstReps = 15; // 세트마다 최대: 첫 세트 15회 이상
const dropRatio = 0.8; // 끝 세트 ≤ 첫 세트의 80%
const holdSets = 6; // 같은 횟수(5회 넘게) 6세트 이상 = 지속력(초급 5→6→7세트)
const powerReps = 5; // 작업 세트 최대 5회 이하 = 순발력(power 5×5)
const warmUpMinutes = 20; // 앞머리 유산소가 20분 이하거나
const warmUpKm = 3; // 3km 이하면 몸풀기(사용자 결정, 2026-09-25)

/// 주간 목표(repstack 요일표의 개수: 월·목 근력, 화 근지구력, 수 지속력, 금 심폐).
/// 순발력은 근력과 같은 월요일이라 근력 칸에 센다.
const factorGoal = {
  Factor.strength: 2,
  Factor.endurance: 1,
  Factor.sustain: 1,
  Factor.cardio: 1,
};

Factor merged(Factor f) => f == Factor.power ? Factor.strength : f;

final _fillWord = RegExp(
  r'채우|총\s?\d|\btotal\b|\breach\b',
  caseSensitive: false,
);
const _minutes = {'s': 1 / 60, 'min': 1.0, 'h': 60.0};
const _km = {'m': 0.001, 'km': 1.0, 'mi': 1.609344};
final _timeUnits = {..._minutes.keys, ..._km.keys};

String _n(num v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

double _kg(LoggedSet s) => s.unit == 'lb' ? s.value! * 0.45359237 : s.value!;

/// 칸의 요인. 내 세트가 없거나 가를 수 없으면(플랭크 60초) null. 위에서 먼저 맞는
/// 규칙을 쓴다(설계 §2.2).
FactorRead? factorOf(ExerciseBlock b) {
  final mine = b.sets.where((s) => s.mine).toList();
  if (mine.isEmpty) return null;
  FactorRead read(
    Factor f,
    String why,
    List<String> args, {
    bool sure = false,
  }) => (factor: f, sure: sure, why: why, args: args);
  final spec = TimingSpec.parse(b.name);
  final u = b.setup;
  if (spec != null && spec.tabata) {
    return read(Factor.cardio, 'tabata', [
      '${spec.work}/${spec.rest}×${spec.rounds}',
    ], sure: true);
  }
  if (u?.totalReps != null) {
    return read(Factor.endurance, 'fill', ['${u!.totalReps}'], sure: true);
  }
  if (_fillWord.hasMatch(b.name)) {
    return read(Factor.endurance, 'fillTitle', [b.name]);
  }
  if (mine.any((s) => _timeUnits.contains(s.unit))) {
    if (partOf(exerciseKey(b.exercise)) != 'cardio') return null;
    // 수가 있는 첫 세트. 없으면(체크만 한 러닝) 0km 를 지어내지 않고 칸 이름을 댄다.
    final s = mine
        .where((s) => _timeUnits.contains(s.unit) && (s.value ?? 0) > 0)
        .firstOrNull;
    return read(Factor.cardio, 'distance', [
      s == null ? b.name : '${_n(s.value!)}${s.unit}',
    ]);
  }
  if (u?.repsPerSet != null && u?.totalSets == null) {
    return read(Factor.sustain, 'open', ['${u!.repsPerSet}']);
  }
  // 작업 세트 = 가장 무거운 무게의 세트(워밍업을 뺀다). 무게가 없으면 전부.
  final weighed = mine.where(
    (s) => s.value != null && (s.unit == 'kg' || s.unit == 'lb'),
  );
  final top = weighed.isEmpty
      ? null
      : weighed.reduce((a, b) => _kg(b) > _kg(a) ? b : a);
  final work = top == null
      ? mine
      : mine.where((s) => s.value == top.value && s.unit == top.unit).toList();
  final r = [for (final s in work) s.reps ?? 0];
  if (r.length == 1 && r.first >= singleFillReps) {
    return read(Factor.endurance, 'single', ['${r.first}']);
  }
  var down = true;
  for (var i = 1; i < r.length; i++) {
    if (r[i] > r[i - 1]) down = false;
  }
  if (r.length >= 3 &&
      down &&
      r.first >= dropFirstReps &&
      r.last <= r.first * dropRatio) {
    return read(Factor.endurance, 'drop', [r.join('·')]);
  }
  // 지속력: 같은 횟수(순발력 문턱 넘게)를 6세트 이상 — 끝 세트는 모자라도 된다(실패로
  // 끝나는 방식). 무거운 6×3 은 "10개를 몇 세트"(BG:42)가 아니라 아래 순발력이다.
  if (r.length >= holdSets &&
      r.first > powerReps &&
      r.sublist(0, r.length - 1).toSet().length == 1 &&
      r.last <= r.first) {
    return read(Factor.sustain, 'hold', ['${r.first}', '${r.length}']);
  }
  final most = r.reduce((a, b) => a > b ? a : b);
  final shape = ['${r.length}', r.toSet().join('/')];
  if (most > 0 && most <= powerReps) return read(Factor.power, 'sets', shape);
  return read(Factor.strength, 'sets', shape);
}

/// 하루(그날 내 기록 전부)의 요인 — [dayFactorOf] 를 기록 시각 순의 칸으로.
({Factor factor, FactorRead read})? dayFactor(Iterable<Note> notes) =>
    dayFactorOf([
      for (final n in [
        ...notes,
      ]..sort((a, b) => a.createdAt.compareTo(b.createdAt)))
        ...n.blocks,
    ]);

/// 유산소 칸이 몸풀기만큼 짧은가: 내 세트의 시간 합이 [warmUpMinutes] 분 이하거나 거리
/// 합이 [warmUpKm] km 이하. 시간도 거리도 수가 없으면(단위만, 체크만 한 러닝) 짧다 —
/// 수 없는 앞머리 러닝은 대개 몸풀기다.
bool _short(ExerciseBlock b) {
  double? sum(Map<String, double> to) {
    final xs = [
      for (final s in b.sets)
        if (s.mine && s.value != null && to[s.unit] != null)
          s.value! * to[s.unit]!,
    ];
    return xs.isEmpty ? null : xs.reduce((a, c) => a + c);
  }

  final m = sum(_minutes), km = sum(_km);
  return (m == null && km == null) ||
      (m != null && m <= warmUpMinutes) ||
      (km != null && km <= warmUpKm);
}

/// 칸들(시각 순)의 본운동: 요인을 가를 수 있는 첫 칸. 마무리로 붙인 채우기나 보조 운동은
/// 그날을 바꾸지 않는다(사용자 결정, 2026-09-25). 다만 뒤에 다른 운동이 이어지는 앞머리
/// 유산소(거리·시간)가 짧으면([_short]) 몸풀기로 보고 건너뛴다 — 러닝 10km 뒤 푸시업은
/// 심폐 날이다. 가를 칸이 없으면 null.
ExerciseBlock? mainBlock(Iterable<ExerciseBlock> blocks) {
  final reads = [
    for (final b in blocks)
      if (factorOf(b) case final r?) (block: b, why: r.why),
  ];
  if (reads.isEmpty) return null;
  final lifted = reads.any((x) => x.why != 'distance');
  return reads
      .firstWhere((x) => !(lifted && x.why == 'distance' && _short(x.block)))
      .block;
}

/// 칸들(시각 순)의 요인: 본운동([mainBlock])의 요인. 주간 셈에서 순발력은 근력 칸으로
/// 센다([merged], F1).
({Factor factor, FactorRead read})? dayFactorOf(
  Iterable<ExerciseBlock> blocks,
) {
  final b = mainBlock(blocks);
  final r = b == null ? null : factorOf(b);
  return r == null ? null : (factor: r.factor, read: r);
}

DateTime calendarDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// 내 세트가 있는 기록을 달력 날(기기 로컬, 시작 시각)로 묶는다.
Map<DateTime, List<Note>> notesByDay(Iterable<Note> notes) {
  final m = <DateTime, List<Note>>{};
  for (final n in notes) {
    if (n.blocks.any((b) => b.sets.any((s) => s.mine))) {
      m.putIfAbsent(calendarDay(n.createdAt), () => []).add(n);
    }
  }
  return m;
}

int _between(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// 최근 7일(짜는 날 [day] 와 앞 6일, [today] 를 넘지 않는 날)의 요인별 날 수.
/// 순발력은 근력으로 센다. 오늘 이미 한 기록도 센다.
Map<Factor, int> weekCounts(
  Iterable<Note> notes,
  DateTime day,
  DateTime today,
) {
  final got = {for (final f in factorGoal.keys) f: 0};
  for (final e in notesByDay(notes).entries) {
    final ago = _between(e.key, day);
    if (ago < 0 || ago > 6 || e.key.isAfter(calendarDay(today))) continue;
    final f = dayFactor(e.value)?.factor;
    if (f != null) got.update(merged(f), (v) => v + 1);
  }
  return got;
}

/// 모자란 순서: 모자람(목표 − 셈)이 큰 것 → 마지막으로 한 날이 오래된 것(한 번도
/// 안 했으면 먼저) → 근력·근지구력·지속력·심폐 순.
List<Factor> rankFactors(Map<Factor, int> counts, Map<Factor, DateTime> last) {
  final order = factorGoal.keys.toList();
  return [...order]..sort((a, b) {
    final ga = factorGoal[a]! - counts[a]!, gb = factorGoal[b]! - counts[b]!;
    if (ga != gb) return gb.compareTo(ga);
    final la = last[a], lb = last[b];
    if (la != lb) {
      return la == null
          ? -1
          : lb == null
          ? 1
          : la.compareTo(lb);
    }
    return order.indexOf(a).compareTo(order.indexOf(b));
  });
}
