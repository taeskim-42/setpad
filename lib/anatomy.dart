/// 몸 그림의 셈 — 내 기록을 부위별 세트로 센다. 화면은 anatomy_page.dart.
///
/// 숫자는 전부 내 기록에서 온다: 세트 수는 해낸 내 세트(`mine`)를 센 것이고, 무게·
/// 횟수는 세트를 그대로 옮긴다. 권장량·목표 무게는 없다. 근육 표는 anatomy_data.dart.
library;

import 'anatomy_data.dart';
import 'exercises.dart' show exerciseByName, partOf;
import 'muscle_map_paths.dart';
import 'notes.dart';
import 'parser.dart' show searchKey;
import 'record_query.dart' show exerciseKey, statName;
import 'routine.dart' show PlanSet;

export 'anatomy_data.dart' show Cue, Move, moves;
export 'muscle_map_paths.dart' show Muscle;

/// 부위 → 거친 부위(exercisePart 값). 시트 머리와 "오늘 {부위} 루틴" 이 쓴다.
const muscleCoarse = <Muscle, String>{
  Muscle.chest: 'chest',
  Muscle.frontDelts: 'shoulders',
  Muscle.sideDelts: 'shoulders',
  Muscle.rearDelts: 'shoulders',
  Muscle.traps: 'shoulders',
  Muscle.upperBack: 'back',
  Muscle.lats: 'back',
  Muscle.lowerBack: 'back',
  Muscle.biceps: 'arms',
  Muscle.triceps: 'arms',
  Muscle.forearms: 'arms',
  Muscle.abs: 'core',
  Muscle.obliques: 'core',
  Muscle.hipFlexors: 'core',
  Muscle.glutes: 'legs',
  Muscle.quads: 'legs',
  Muscle.hamstrings: 'legs',
  Muscle.adductors: 'legs',
  Muscle.calves: 'legs',
};

/// 면마다 목록에 보일 부위(위 → 아래). 고관절 굴곡근은 그림에 면이 없어 앞 목록에만.
final frontRegions = [
  for (final m in Muscle.values)
    if (frontMuscles.containsKey(m) || m == Muscle.hipFlexors) m,
];
final backRegions = [
  for (final m in Muscle.values)
    if (backMuscles.containsKey(m)) m,
];

/// 사전 밖 운동의 여덟 언어 이름 → 한국어 이름.
final _extraNames = {
  for (final e in moves.entries)
    if (e.value.names case final n?)
      for (final name in [
        n.ko,
        n.en,
        n.ja,
        n.zhHans,
        n.zhHant,
        n.es,
        n.vi,
        n.th,
      ])
        searchKey(name): e.key,
};

/// 기록 이름 → 표의 운동(한국어 이름). 표에 없으면 null — 근육을 지어내지 않는다.
String? moveKey(String name) {
  final extra = _extraNames[searchKey(statName(name))];
  if (extra != null) return extra;
  final k = exerciseKey(name);
  return moves.containsKey(k) ? k : null;
}

/// 표의 운동 이름(화면 언어).
String moveName(String key, String lang) =>
    exerciseByName[key.toLowerCase()]?.name(lang) ??
    moves[key]?.names?.name(lang) ??
    key;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// 한 기간의 부위별 세트. 주동은 한 세트, 보조는 반 세트로 센다.
class BodyLoad {
  final primary = <Muscle, int>{};
  final secondary = <Muscle, int>{};

  /// 표에 없는 운동: 기록 이름 → 세트(세지 않았다고 말한다).
  final unknown = <String, int>{};
  int cardio = 0;

  double of(Muscle m) => (primary[m] ?? 0) + (secondary[m] ?? 0) / 2;
  double get max => Muscle.values.map(of).fold(0.0, (a, b) => a > b ? a : b);
  bool get empty => max == 0 && unknown.isEmpty && cardio == 0;
}

/// 오늘을 포함한 [days] 달력 날(7일 = 오늘과 앞의 6일)의 내 세트. 미래 날은 뺀다.
BodyLoad bodyLoad(
  List<Note> notes, {
  required DateTime today,
  required int days,
}) {
  final out = BodyLoad();
  for (final n in notes) {
    final ago = _daysBetween(n.createdAt, today);
    if (ago < 0 || ago >= days) continue;
    for (final b in n.blocks) {
      final sets = b.sets.where((s) => s.mine).length;
      if (sets == 0) continue;
      final move = moves[moveKey(b.exercise)];
      if (move == null) {
        if (partOf(exerciseKey(b.exercise)) == 'cardio') {
          out.cardio += sets;
        } else {
          out.unknown.update(b.exercise, (v) => v + sets, ifAbsent: () => sets);
        }
        continue;
      }
      for (final m in move.primary) {
        out.primary.update(m, (v) => v + sets, ifAbsent: () => sets);
      }
      for (final m in move.secondary) {
        out.secondary.update(m, (v) => v + sets, ifAbsent: () => sets);
      }
    }
  }
  return out;
}

/// 색 단계 0–3: 이 기간 가장 많이 한 부위([max])에 견준다. 외부 권장량은 쓰지 않는다.
int level(double v, double max) =>
    v <= 0 || max <= 0 ? 0 : (3 * v / max).ceil().clamp(1, 3);

/// 내가 한 운동 한 줄: 마지막으로 한 날의 내 세트 그대로.
typedef DoneRow = ({
  String key,
  String name,
  bool primary,
  DateTime day,
  List<PlanSet> sets,
});

/// 이 부위를 주동·보조로 쓴 내 운동(전 기간). 주동 먼저, 그다음 최근 순.
List<DoneRow> doneFor(List<Note> notes, Muscle m) {
  final last = <String, DoneRow>{};
  for (final n in notes) {
    final day = _day(n.createdAt);
    for (final b in n.blocks) {
      final mine = b.sets.where((s) => s.mine).toList();
      final key = moveKey(b.exercise);
      final move = moves[key];
      if (mine.isEmpty || move == null) continue;
      final primary = move.primary.contains(m);
      if (!primary && !move.secondary.contains(m)) continue;
      final before = last[key];
      if (before != null && before.day.isAfter(day)) continue;
      last[key!] = (
        key: key,
        name: b.exercise,
        primary: primary,
        day: day,
        sets: [
          for (final s in mine) (value: s.value, unit: s.unit, reps: s.reps),
        ],
      );
    }
  }
  return last.values.toList()..sort(
    (a, b) =>
        a.primary != b.primary ? (a.primary ? -1 : 1) : b.day.compareTo(a.day),
  );
}

/// 표의 운동 가운데 내가 해낸 세트가 있는 것.
Set<String> doneKeys(List<Note> notes) => {
  for (final n in notes)
    for (final b in n.blocks)
      if (b.sets.any((s) => s.mine)) ?moveKey(b.exercise),
};

/// 해 볼 만한 운동: 이 부위가 주동이고 아직 안 한 것. 내가 쓴 기구(없으면 맨몸만)로
/// 할 수 있는 것은 [shown], 아닌 것은 [hidden]. 표의 운동을 한 번도 안 했으면 기구를
/// 모르니 거르지 않는다([allGear]).
({List<String> shown, List<String> hidden, Set<String> gear, bool allGear})
tryFor(Muscle m, Set<String> done) {
  final gear = {for (final k in done) ...?moves[k]?.gear}..remove('bodyweight');
  final allGear = done.isEmpty;
  final shown = <String>[], hidden = <String>[];
  for (final e in moves.entries) {
    if (!e.value.primary.contains(m) || done.contains(e.key)) continue;
    final ok =
        allGear ||
        e.value.gear.any((g) => g == 'bodyweight' || gear.contains(g));
    (ok ? shown : hidden).add(e.key);
  }
  return (shown: shown, hidden: hidden, gear: gear, allGear: allGear);
}

/// 자세 팁 한 줄의 글(화면 언어). 한국어 밖은 영어다 — 화면이 그렇다고 말한다.
String cueText(Cue c, String lang) => lang == 'ko' ? c.ko : c.en;
