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
import 'routine.dart' show PlanSet, benchExercises, exerciseGear;

export 'anatomy_data.dart'
    show Basis, Cue, Move, moves, tricepsHeads, unsourcedMachines;
export 'muscle_map_paths.dart' show Muscle;

/// 부위 → 거친 부위(exercisePart 값). 시트 머리와 "오늘 {부위} 루틴" 이 쓴다.
const muscleCoarse = <Muscle, String>{
  Muscle.chest: 'chest',
  Muscle.frontDelts: 'shoulders',
  Muscle.sideDelts: 'shoulders',
  Muscle.rearDelts: 'shoulders',
  Muscle.traps: 'shoulders',
  Muscle.upperBack: 'back',
  Muscle.infraspinatus: 'back',
  Muscle.teresMinor: 'back',
  Muscle.teresMajor: 'back',
  Muscle.lats: 'back',
  Muscle.lowerBack: 'back',
  Muscle.biceps: 'arms',
  Muscle.tricepsLong: 'arms',
  Muscle.tricepsLateral: 'arms',
  Muscle.tricepsMedial: 'arms',
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

/// 사전 밖 운동의 여덟 언어 이름과 별칭 → 한국어 이름.
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
        ...e.value.aliases,
      ])
        searchKey(name): e.key,
};

/// 기록 이름마다 한 번만 푼다 — 시트를 열 때마다 전체 기록을 훑는다.
final _moveKeys = <String, String?>{};

/// 기록 이름 → 표의 운동(한국어 이름). 표에 없으면 null — 근육을 지어내지 않는다.
String? moveKey(String name) => _moveKeys.putIfAbsent(name, () {
  final extra = _extraNames[searchKey(statName(name))];
  if (extra != null) return extra;
  final k = exerciseKey(name);
  return moves.containsKey(k) ? k : null;
});

/// 표의 운동 이름(화면 언어). 사전 밖 운동은 한국어·영어 밖에서 영어 이름이다 —
/// 다른 언어 이름은 원어민 확인 전 번역이다.
String moveName(String key, String lang) =>
    exerciseByName[key.toLowerCase()]?.name(lang) ??
    moves[key]?.names?.name(lang == 'ko' ? 'ko' : 'en') ??
    key;

/// 운동의 기구. 사전 운동은 루틴과 같은 표(exerciseGear) 하나다.
List<String> moveGear(String key) => switch (exerciseGear[key]) {
  final g? => [g],
  null => moves[key]?.gear ?? const [],
};

/// 운동에 있어야 하는 것: 기구(그중 하나)와 벤치. 벤치는 루틴과 같은 표(benchExercises)다
/// — 불가리안 스플릿 스쿼트는 맨몸·벤치다.
List<String> moveNeeds(String key) => [
  ...moveGear(key),
  if (benchExercises.contains(key)) 'bench',
];

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
/// [days] 가 null 이면 전 기간이다.
BodyLoad bodyLoad(
  List<Note> notes, {
  required DateTime today,
  required int? days,
}) {
  final out = BodyLoad();
  for (final n in notes) {
    final ago = _daysBetween(n.createdAt, today);
    if (ago < 0 || (days != null && ago >= days)) continue;
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

/// 내가 한 운동 한 줄: 마지막으로 한 날의 내 세트 그대로(그날 블록을 모두 잇는다).
typedef DoneRow = ({
  String key,
  String name,
  bool primary,
  DateTime day,
  List<PlanSet> sets,
});

/// 이 부위를 주동·보조로 쓴 내 운동(전 기간). 주동 먼저, 그다음 최근 순.
/// 마지막 날은 기록 시각(createdAt)으로 가르고, 그날의 블록은 시각·칸 순으로 잇는다.
/// 이름은 그날 가장 나중에 적은 것이다.
List<DoneRow> doneFor(List<Note> notes, Muscle m) {
  final hits =
      <
        String,
        List<({DateTime at, int seq, String name, List<PlanSet> sets})>
      >{};
  var seq = 0;
  for (final n in notes) {
    for (final b in n.blocks) {
      final key = moveKey(b.exercise);
      final move = moves[key];
      if (move == null) continue;
      if (!move.primary.contains(m) && !move.secondary.contains(m)) continue;
      final sets = [
        for (final s in b.sets)
          if (s.mine) (value: s.value, unit: s.unit, reps: s.reps),
      ];
      if (sets.isEmpty) continue;
      (hits[key!] ??= []).add((
        at: n.createdAt,
        seq: seq++,
        name: b.exercise,
        sets: sets,
      ));
    }
  }
  final rows = [
    for (final MapEntry(:key, :value) in hits.entries)
      () {
        final last = _day(
          value.map((h) => h.at).reduce((a, b) => a.isAfter(b) ? a : b),
        );
        final day = value.where((h) => _day(h.at) == last).toList()
          ..sort((a, b) {
            final c = a.at.compareTo(b.at);
            return c != 0 ? c : a.seq.compareTo(b.seq);
          });
        return (
          key: key,
          name: day.last.name,
          primary: moves[key]!.primary.contains(m),
          day: last,
          sets: [for (final h in day) ...h.sets],
        );
      }(),
  ];
  return rows..sort(
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

/// 해 볼 만한 운동 목록([tryFor]).
typedef TryList = ({
  List<String> shown,
  List<String> hidden,
  Set<String> gear,
  bool allGear,

  /// 이 부위가 주동인 운동이 표에 없어(극하근·소원근·대원근 — ExRx 가 보조로만
  /// 적는다) 보조로 쓰는 운동을 대신 보였다. 화면 제목이 그렇다고 말한다.
  bool secondary,
});

/// 해 볼 만한 운동: 이 부위가 주동이고 아직 안 한 것([Move.suggest] 가 거짓인 것은
/// 빼고). 내가 쓴 기구(없으면 맨몸만)로 할 수 있는 것은 [shown], 아닌 것은 [hidden].
/// 쓴 기구는 기구가 하나뿐인 운동에서만 짐작한다 — 맨몸 런지로 바벨을 썼다고 하지
/// 않는다. 벤치 운동을 했으면 벤치가 있고, 벤치 운동은 벤치가 있어야 보인다.
/// 표의 운동을 한 번도 안 했으면 기구를 모르니 거르지 않는다([allGear]).
TryList tryFor(Muscle m, Set<String> done) {
  final gear = {
    for (final k in done) ...[
      if (moveGear(k) case [final g]) g,
      if (benchExercises.contains(k)) 'bench',
    ],
  }..remove('bodyweight');
  final allGear = done.isEmpty;
  final shown = <String>[], hidden = <String>[];
  final secondary = !moves.values.any(
    (v) => v.suggest && v.primary.contains(m),
  );
  for (final e in moves.entries) {
    final role = secondary ? e.value.secondary : e.value.primary;
    if (!e.value.suggest || !role.contains(m) || done.contains(e.key)) {
      continue;
    }
    final ok =
        allGear ||
        (moveGear(e.key).any((g) => g == 'bodyweight' || gear.contains(g)) &&
            (!benchExercises.contains(e.key) || gear.contains('bench')));
    (ok ? shown : hidden).add(e.key);
  }
  return (
    shown: shown,
    hidden: hidden,
    gear: gear,
    allGear: allGear,
    secondary: secondary,
  );
}

/// 자세 팁 한 줄의 글(화면 언어). 한국어 밖은 영어다 — 화면이 그렇다고 말한다.
String cueText(Cue c, String lang) => lang == 'ko' ? c.ko : c.en;
