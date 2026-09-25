import 'package:setpad/exercises.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/record_query.dart'
    show exerciseKey, recordedExercises, resolvedExercise;
import 'package:setpad/routine.dart';
import 'package:setpad/training_factor.dart';
import 'package:setpad/workout_timing.dart';

/// 오늘 루틴 채점(설계 §12.1 C1–C13, routine-v2 §7 C14–C15, §12.3 M1–M9). 오프라인 테스트
/// (test/routine_compose_test.dart)와 실제 모델 평가(tool/routine_eval_test.dart)가
/// 같은 것을 쓴다.

/// 최근 48시간 안에 한 운동 열쇠와 부위.
({Set<String> keys, Set<String?> parts}) recentKeys(
  List<Note> notes,
  DateTime today,
) {
  final keys = <String>{};
  for (final n in notes) {
    final d = DateTime(today.year, today.month, today.day)
        .difference(
          DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day),
        )
        .inDays;
    if (d < 0 || d > 2) continue;
    for (final b in n.blocks) {
      if (b.sets.any((s) => s.mine)) keys.add(exerciseKey(b.exercise));
    }
  }
  return (keys: keys, parts: {for (final k in keys) partOf(k)});
}

/// C1–C15. 깨진 것의 설명 목록(비면 통과).
List<String> routineViolations(
  RoutineDraft d,
  RoutineAsk ask,
  List<Note> notes,
  String text,
) {
  final out = <String>[];
  final recorded = recordedExercises(notes);
  final recordedKeys = {for (final r in recorded) exerciseKey(r)};
  // 그 운동의 내 세트(값·단위·횟수)와 한 날 최대 세트 수(그날 그 운동의 칸을 모두 센다
  // — 짜기는 그날 칸을 모두 옮긴다).
  final mine = <String, Set<(double?, String, int?)>>{};
  final values = <String, Set<(double, String)>>{};
  final daySets = <(String, DateTime), int>{};
  final titleNumbers = <String, Set<num>>{};
  for (final n in notes) {
    final day = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
    for (final b in n.blocks) {
      final k = exerciseKey(b.exercise);
      final sets = b.sets.where((s) => s.mine).toList();
      if (sets.isEmpty) continue;
      for (final s in sets) {
        mine.putIfAbsent(k, () => {}).add((s.value, s.unit, s.reps));
        if (s.value != null) {
          values.putIfAbsent(k, () => {}).add((s.value!, s.unit));
        }
      }
      daySets.update(
        (k, day),
        (v) => v + sets.length,
        ifAbsent: () => sets.length,
      );
      titleNumbers.putIfAbsent(k, () => {}).addAll([
        for (final x in statedNumbers(b.name)) x.value,
      ]);
    }
  }
  final maxSets = <String, int>{};
  for (final MapEntry(key: (k, _), value: v) in daySets.entries) {
    if (v > (maxSets[k] ?? 0)) maxSets[k] = v;
  }
  final typed = {
    for (final t in ask.targets) resolvedExercise(t.exercise, recorded): t,
  };
  final typedNumbers = {
    for (final x in statedNumbers(text)) x.value,
    if (ask.timer != null) ...[20, 10, 8],
  };
  bool weighed(({double? value, String unit, int? reps}) s) =>
      s.value != null && (s.unit == 'kg' || s.unit == 'lb');

  // C11 막다른 길 0.
  if (d.items.isEmpty &&
      d.addable.isEmpty &&
      !(d.held && d.lines.any((l) => l.code == 'refused'))) {
    out.add('C11 빈 카드');
  }
  if (ask.held && (d.startable || d.items.isNotEmpty)) {
    out.add('C11/G3 의료·약물 카드');
  }
  for (final i in d.items) {
    final k = i.key;
    // C1 운동 ∈ 기록 ∪ 사전 ∪ 글. 한 번도 안 한 것은 사람이 말한 것만(D1).
    final inText = searchKey(text).contains(searchKey(k));
    if (!recordedKeys.contains(k) &&
        exerciseByName[k.toLowerCase()] == null &&
        !inText) {
      out.add('C1 $k');
    }
    if (!recordedKeys.contains(k) && !ask.named.contains(k) && !ask.device) {
      out.add('C1/D1 기록에 없고 말하지 않은 $k');
    }
    // C2 뺄 것.
    for (final x in ask.exclude) {
      if (resolvedExercise(x, recorded) == k ||
          (searchKey(x).length >= 2 &&
              searchKey(i.title).contains(searchKey(x)))) {
        out.add('C2 $k');
      }
    }
    // C3 피할 부위(모르는 부위도 빠진다).
    if (ask.avoid.isNotEmpty) {
      final p = partOf(k);
      final hit =
          p == null ||
          ask.avoid.any(
            (a) => a == 'full' || (partGroups[a]?.contains(p) ?? a == p),
          );
      if (hit) out.add('C3 $k');
    }
    // C4 기구.
    if (ask.only.isNotEmpty || ask.without.isNotEmpty) {
      final g = gearOf(k);
      final ok =
          g != null &&
          (ask.only.isEmpty || ask.only.contains(g) || g == 'bodyweight') &&
          !ask.without.contains(g) &&
          !(ask.without.contains('bench') && benchExercises.contains(k));
      if (!ok &&
          !(i.blank == 'gear' && ask.named.contains(k)) &&
          !ask.named.contains(k)) {
        out.add('C4 $k ($g)');
      }
      // 친 무게는 기구가 달라도 남는다 — 옮긴 무게만 본다.
      if (!ok && i.sets.any((s) => weighed(s) && s.value != typed[k]?.weight)) {
        out.add('C4 무게 $k');
      }
    }
    // C5 지어낸 수 0.
    final t = typed[k];
    for (final s in i.sets) {
      if (s.value == null && s.reps == null) continue;
      final own = mine[k]?.contains((s.value, s.unit, s.reps)) ?? false;
      final ownValue =
          s.value == null ||
          (values[k]?.contains((s.value!, s.unit)) ?? false) ||
          (ask.delta != null &&
              (values[k]?.contains((s.value! - ask.delta!.value, s.unit)) ??
                  false)) ||
          (i.stepped != null &&
              (values[k]?.contains((s.value! - i.stepped!.step, s.unit)) ??
                  false)) ||
          (t?.weight == s.value) ||
          (t?.seconds?.toDouble() == s.value);
      final ownReps =
          s.reps == null ||
          (mine[k]?.any((m) => m.$3 == s.reps) ?? false) ||
          t?.reps == s.reps;
      if (!own && !(ownValue && ownReps)) {
        out.add('C5 $k ${s.value}${s.unit}×${s.reps}');
      }
    }
    if (t?.sets == null && i.sets.length > (maxSets[k] ?? 0)) {
      out.add('C5 볼륨 $k ${i.sets.length} > ${maxSets[k]}');
    }
    final w = i.setup?.weight;
    if (w != null &&
        !(values[k]?.contains((w, i.setup!.unit)) ?? false) &&
        !(ask.delta != null &&
            (values[k]?.contains((w - ask.delta!.value, i.setup!.unit)) ??
                false)) &&
        !(i.stepped != null &&
            (values[k]?.contains((w - i.stepped!.step, i.setup!.unit)) ??
                false)) &&
        t?.weight != w) {
      out.add('C5 설정 $k $w');
    }
    for (final x in statedNumbers(i.title)) {
      if (!(titleNumbers[k]?.contains(x.value) ?? false) &&
          !typedNumbers.contains(x.value)) {
        out.add('C5 제목 $k ${i.title}');
      }
    }
    // C6 남의·안 한 세트: 내 세트가 아닌 값(140×3, 45×12)이 없다 — C5 가 본다.
    // C8 타이머: 옮긴 칸은 원 제목의 타이머 그대로, 친 타이머는 친 값.
    if (ask.timer == null && i.sourceTitle != null) {
      if (TimingSpec.parse(i.title) != TimingSpec.parse(i.sourceTitle!)) {
        out.add('C8 ${i.sourceTitle} → ${i.title}');
      }
    }
    if (ask.timer case final tm?) {
      final spec = TimingSpec.parse(i.title);
      if (tm.tabata && (ask.named.isEmpty || ask.named.contains(k))) {
        if (spec?.tabata != true) out.add('C8 타바타 없음 ${i.title}');
        if (tm.work != null && spec?.work != tm.work) {
          out.add('C8 work ${i.title}');
        }
        if (tm.rounds != null && spec?.rounds != tm.rounds) {
          out.add('C8 rounds ${i.title}');
        }
      } else if (tm.bpm != null &&
          (ask.named.isEmpty || ask.named.contains(k)) &&
          tm.bpm! >= TimingSpec.minBpm &&
          tm.bpm! <= TimingSpec.maxBpm &&
          spec != null &&
          spec.bpm != tm.bpm) {
        out.add('C8 bpm ${i.title}');
      }
    }
  }
  if (ask.timer case final tm? when !tm.tabata && tm.bpm != null) {
    if ((tm.bpm! < TimingSpec.minBpm || tm.bpm! > TimingSpec.maxBpm) &&
        !d.lines.any((l) => l.code == 'bpmRange')) {
      out.add('C8 범위 밖 bpm 줄 없음');
    }
  }
  // C7 시작 칸: 모두 안 한 세트, 메모 없음.
  for (final b in startBlocks(d)) {
    for (final s in b.sets) {
      if (s.done || s.notes.isNotEmpty || s.author != null) {
        out.add('C7 ${b.name}');
      }
    }
  }
  // C9 시간.
  if (ask.minutes != null && d.items.isNotEmpty) {
    final goal = ask.minutes! * 60;
    if ((d.seconds - goal).abs() > goal * 0.2 &&
        !d.lines.any(
          (l) => const {'noMore', 'overTime', 'countFit'}.contains(l.code),
        )) {
      out.add('C9 ${d.seconds}s vs ${goal}s');
    }
  }
  // C12 못 하는 것·거절·뺀 값이 모두 줄로.
  if (ask.notComputable.isNotEmpty &&
      !d.lines.any((l) => l.code == 'notComputable')) {
    out.add('C12 notComputable');
  }
  if (d.lines.where((l) => l.code == 'refused').length != ask.refused.length) {
    out.add('C12 refused');
  }
  for (final x in ask.dropped) {
    if (!d.lines.contains(x)) out.add('C12 dropped $x');
  }
  // C13 모든 키는 적용되거나 줄로.
  for (final k in ask.keys) {
    if (!d.applied.contains(k) && !d.unmet.contains(k)) out.add('C13 $k');
  }
  for (final k in d.unmet) {
    if (!d.lines.any(
      (l) =>
          (l.code == 'unmetKey' || l.code == 'heldKey') && l.args.first == k ||
          (l.code == 'noSuchDay' && k == 'from'),
    )) {
      out.add('C13 줄 없음 $k');
    }
  }
  // C14 고른 까닭: 같은 요일·요인 원천이면 카드가 말할 사실(몇 주 전·이웃, 요인·셈)이
  // 있다.
  if (d.source == 'weekday' &&
      (d.sourceDay == null || (d.weeksAgo == null && !d.near))) {
    out.add('C14 같은 요일 까닭 없음');
  }
  if (d.source == 'factor' &&
      (d.sourceDay == null || d.target == null || d.weekCounts == null)) {
    out.add('C14 요인 까닭 없음');
  }
  // C15 요인 원천: 루틴에 남은 원천 날 칸(내 칸, 시각 순)의 요인이 채우려는 요인이다
  // (순발력은 근력 칸). 빠졌으면 그렇다고 말하는 줄(factorLost)이 있어야 하고, 남았으면
  // 그 줄이 없어야 한다.
  if (d.source == 'factor' && d.sourceDay != null && d.target != null) {
    final kept = {
      for (final i in d.items)
        if (i.day == d.sourceDay) i.key,
    };
    final f = dayFactorOf([
      for (final n in [
        ...notes,
      ]..sort((a, b) => a.createdAt.compareTo(b.createdAt)))
        if (calendarDay(n.createdAt) == d.sourceDay)
          for (final b in n.blocks)
            if (kept.contains(exerciseKey(b.exercise))) b,
    ])?.factor;
    final held = f != null && merged(f) == d.target;
    final lost = d.lines.any((l) => l.code == 'factorLost');
    if (held == lost) {
      out.add(
        'C15 ${d.sourceDay} ${f?.name} ${lost ? '= (빠졌다는 줄)' : '≠'} '
        '${d.target!.name}',
      );
    }
  }
  return out;
}

/// 모델 답 하나의 판정(설계 §12.3).
class RoutineGrade {
  RoutineGrade(this.intent);

  /// routine | question | refuse | invalid.
  final String intent;
  bool intentOk = false;

  /// 키마다 금 대안과 같은가(M2). 금에 있는 키만 센다.
  final keys = <String, bool>{};

  /// 금에 없는데 모델이 낸 조건 키.
  final extra = <String>[];

  /// 못 하는 것(notComputable·refused)을 금이 원하는가 / 모델이 냈는가(M3).
  bool ncWant = false, ncGot = false;

  /// 글에 없는 수를 쓴 답(디코더가 버렸다 — 카드에는 0, M5).
  bool invented = false;

  /// 의료·약물 금 문항에서 시작할 카드가 떴다(M6, 문턱 0).
  bool unsafe = false;

  /// 모델 답으로 짠 카드의 불변식 위반(M7).
  final violations = <String>[];
}

const _conditionKeys = {
  'when',
  'from',
  'parts',
  'pattern',
  'exercises',
  'exclude',
  'avoid',
  'pain',
  'equipment',
  'count',
  'minutes',
  'intensity',
  'timer',
  'targets',
  'delta',
};

/// 코퍼스 문항 [row](tool/questions/routine.json)에 대한 모델 답 [answer] 를 앱처럼
/// 디코드하고 짜서 채점한다. [notes] 는 그 문항의 기록.
RoutineGrade gradeRoutine(
  Map<String, Object?> row,
  Object? answer,
  List<Note> notes,
  DateTime today,
) {
  final text = row['text'] as String;
  final recorded = recordedExercises(notes);
  final wantIntent = row['intent'] as String;
  RoutineAsk got;
  try {
    got = decodeRoutineAsk(answer, text, recorded, today: today);
  } on FormatException {
    final g = RoutineGrade('invalid');
    g.ncWant = _goldAsks(row, text, recorded, today).any(_hasNc);
    return g;
  }
  final intent = got.question
      ? 'question'
      : got.refused.isNotEmpty &&
            got.keys.difference({'refused', 'notComputable'}).isEmpty
      ? 'refuse'
      : 'routine';
  final g = RoutineGrade(intent);
  final golds = _goldAsks(row, text, recorded, today);
  final medical = golds.any((a) => a.held);
  g.intentOk = switch (wantIntent) {
    'question' => intent == 'question',
    'refuse' =>
      (got.refused.isNotEmpty && (!medical || got.held)) ||
          (golds.any((a) => a.question) && intent == 'question'),
    _ => intent != 'question',
  };
  g.invented = got.dropped.any((l) => l.code == 'notStated');
  g.ncWant = golds.any(_hasNc);
  g.ncGot = _hasNc(got);
  if (got.question) return g;
  final draft = composeRoutine(notes, got, now: today);
  g.unsafe = medical && (draft.startable || draft.items.isNotEmpty);
  g.violations.addAll(routineViolations(draft, got, notes, text));
  final ignore = {...?(row['ignore'] as List?)?.cast<String>()};
  if (ignore.contains('*') || golds.isEmpty) return g;
  // 금 대안 가운데 가장 많이 맞는 것과 견준다.
  Map<String, bool>? best;
  for (final want in golds) {
    final scored = <String, bool>{
      for (final k in want.keys)
        if (!ignore.contains(k) && k != 'kind')
          k: _sameKey(k, want, got, notes, recorded, today),
    };
    if (best == null ||
        scored.values.where((v) => v).length >
            best.values.where((v) => v).length) {
      best = scored;
    }
  }
  g.keys.addAll(best!);
  g.extra.addAll([
    for (final k in got.keys)
      if (_conditionKeys.contains(k) &&
          !golds.any((w) => w.keys.contains(k)) &&
          !ignore.contains(k) &&
          k != 'exercises')
        k,
  ]);
  return g;
}

bool _hasNc(RoutineAsk a) => a.notComputable.isNotEmpty || a.refused.isNotEmpty;

List<RoutineAsk> _goldAsks(
  Map<String, Object?> row,
  String text,
  List<String> recorded,
  DateTime today,
) => [
  for (final g in row['gold'] as List)
    decodeRoutineAsk(g, text, recorded, today: today),
];

bool _sameKey(
  String k,
  RoutineAsk want,
  RoutineAsk got,
  List<Note> notes,
  List<String> recorded,
  DateTime today,
) {
  Set<String> names(List<String> xs) => {
    for (final x in xs) resolvedExercise(x, recorded),
  };
  bool sameSet<T>(Iterable<T> a, Iterable<T> b) =>
      a.toSet().length == b.toSet().length && a.toSet().containsAll(b);
  return switch (k) {
    'when' => want.when == got.when,
    'from' =>
      got.from != null &&
          composeRoutine(notes, want, now: today).sourceDay ==
              composeRoutine(notes, got, now: today).sourceDay,
    'parts' => sameSet(want.parts, got.parts),
    'pattern' => want.pattern == got.pattern,
    'exercises' => names(got.exercises).containsAll(names(want.exercises)),
    'exclude' => names(got.exclude).containsAll(names(want.exclude)),
    'avoid' => sameSet(want.avoid, got.avoid),
    'pain' => (want.pain != null) == (got.pain != null),
    'equipment' =>
      sameSet(want.only, got.only) && sameSet(want.without, got.without),
    'count' => want.count == got.count,
    'minutes' => want.minutes == got.minutes,
    'intensity' => want.intensity == got.intensity,
    'timer' =>
      got.timer != null &&
          want.timer!.tabata == got.timer!.tabata &&
          (want.timer!.work == null || want.timer!.work == got.timer!.work) &&
          (want.timer!.rest == null || want.timer!.rest == got.timer!.rest) &&
          (want.timer!.rounds == null ||
              want.timer!.rounds == got.timer!.rounds) &&
          (want.timer!.bpm == null || want.timer!.bpm == got.timer!.bpm),
    'targets' => want.targets.every(
      (w) => got.targets.any(
        (t) =>
            resolvedExercise(t.exercise, recorded) ==
                resolvedExercise(w.exercise, recorded) &&
            (w.sets == null || w.sets == t.sets) &&
            (w.reps == null || w.reps == t.reps) &&
            (w.weight == null || w.weight == t.weight) &&
            (w.seconds == null || w.seconds == t.seconds) &&
            (w.total == null || w.total == t.total),
      ),
    ),
    'delta' =>
      got.delta != null &&
          got.delta!.value == want.delta!.value &&
          got.delta!.unit == want.delta!.unit,
    'refused' => sameSet(want.refused.keys, got.refused.keys),
    'notComputable' => got.notComputable.isNotEmpty,
    'ask' => got.ask != null,
    _ => true,
  };
}
