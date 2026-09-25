import 'package:flutter/cupertino.dart';

import 'editor.dart' show SuggestionChip;
import 'exercises.dart';
import 'gym.dart' show Routine;
import 'l10n/generated/app_localizations.dart';
import 'palette.dart';
import 'record_query.dart' show notComputableLines;
import 'routine.dart';
import 'training_factor.dart';
import 'units.dart';

/// 카드 위의 칩 하나(글과 누를 일).
typedef RoutineAction = ({String label, VoidCallback onTap});

/// 오늘 루틴 카드(설계 §9). 숫자는 [RoutineDraft] 가 기록에서 옮긴 것뿐이고,
/// 근거 줄은 카드에만 있다(세트 메모에 넣지 않는다).
///
/// 위에서 아래로: 상태 줄·칩 → 쌤이 보낸 루틴 → 머리(오늘/내일) → 이렇게 읽었어요 →
/// 거절·못 보는 것·뺀 값 → 왜·부위별 쉰 날 → 시간 → 칸들 → 뺀 것(넣기) → 넣을 칩 →
/// [시작].
class RoutineCard extends StatelessWidget {
  const RoutineCard({
    super.key,
    this.draft,
    this.ask,
    this.status = const [],
    this.actions = const [],
    this.trainer = const [],
    this.onTrainer,
    this.onStart,
    this.started = false,
    this.onRemove,
    this.onRestore,
    this.onAdd,
    this.onOther,
    this.onPrevious,
    this.onPart,
    this.onStep,
    this.onMode,
    this.spent,
    this.lang = 'ko',
  });

  final RoutineDraft? draft;
  final RoutineAsk? ask;

  /// 상태 줄(읽는 중·연결·읽지 못함 …) — 화면이 문구를 만들어 넘긴다.
  final List<String> status;
  final List<RoutineAction> actions;
  final List<Routine> trainer;
  final void Function(Routine)? onTrainer;
  final VoidCallback? onStart;

  /// 이미 [시작] 했다 — 버튼이 "시작함 · 열기" 가 된다(G18).
  final bool started;
  final void Function(RoutineItem)? onRemove;
  final void Function(String key)? onRestore, onAdd;
  final VoidCallback? onOther, onPrevious, onPart, onStep;

  /// 방식 칩([RoutineDraft.modeChips]) — 누르면 [RoutineEdits.mode].
  final void Function(String mode)? onMode;

  /// 원판 줄(서버가 답했을 때만). 없으면 기기가 짠 것 — "원판 0장".
  final String? spent;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final faint = TextStyle(
      fontSize: 13,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    );
    const body = TextStyle(fontSize: 14);
    final d = draft;
    Widget chips(List<RoutineAction> list) => Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final a in list)
            SuggestionChip(label: a.label, selected: false, onTap: a.onTap),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in status) Text(s, style: body),
          if (actions.isNotEmpty) chips(actions),
          // 쌤이 보낸 루틴은 맨 위(검색 중에는 목록에서 숨는다).
          for (final r in trainer)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: const Size(44, 44),
              onPressed: onTrainer == null ? null : () => onTrainer!(r),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.person_crop_circle,
                    size: 18,
                    color: seal.resolveFrom(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${r.title} · ${l.routineFromTrainer(r.gym)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (d != null) ..._draft(context, l, d, faint, body, chips),
        ],
      ),
    );
  }

  List<Widget> _draft(
    BuildContext context,
    L l,
    RoutineDraft d,
    TextStyle faint,
    TextStyle body,
    Widget Function(List<RoutineAction>) chips,
  ) {
    String date(DateTime x) => l.routineDate(x);
    final a = ask;
    final head = d.future
        ? l.routineHeaderDay(
            d.day == DateTime(d.today.year, d.today.month, d.today.day + 1)
                ? l.routineTomorrow(date(d.day))
                : '${l.weekdayLabel(d.day)}(${date(d.day)})',
          )
        : l.routineHeaderToday;
    final readAs = a == null || a.device ? null : _readAs(l, a);
    final lines = [
      ?readAs,
      for (final line in d.lines) ...routineLineTexts(l, line),
    ];
    final why = routineWhy(l, d);
    // 원천 날의 체력 요인(설명만): "근력 날 · 3×10".
    final factor = switch (d.factor) {
      final f? when d.source == 'weekday' || d.source == 'factor' =>
        l.routineFactorDay(
          l.routineFactor(f.factor.name),
          factorWhy(l, f.read),
        ),
      _ => null,
    };
    // 최근 7일 요인 셈(모자란 요인으로 짠 날만).
    final counts = switch (d.weekCounts) {
      final c? when d.source == 'factor' => l.routineWeekCounts(
        '${date(DateTime(d.day.year, d.day.month, d.day.day - 6))}–'
        '${date(d.future ? d.today : d.day)}',
        [for (final e in c.entries) '${l.routineFactor(e.key.name)} ${e.value}']
            .join(' · '),
      ),
      _ => null,
    };
    final rest = d.partRest.entries
        .take(7)
        .map((e) => l.routinePartDays(partName(l, e.key), e.value));
    final pace = d.paceSessions > 0
        ? l.routinePaceOwn(d.paceSessions, _minSec(l, d.pace))
        : l.routinePaceDefault(_minSec(l, d.pace));
    return [
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                head,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
            if (d.hasOther && onOther != null)
              SuggestionChip(
                label: l.routineOther,
                selected: false,
                onTap: onOther!,
              ),
          ],
        ),
      ),
      if (factor != null) Text(factor, style: body),
      if (lines.isNotEmpty) Text(lines.join('\n'), style: body),
      if (why != null) Text(why, style: faint),
      if (counts != null) Text(counts, style: faint),
      if (rest.isNotEmpty)
        Text(l.routinePartRest(rest.join(' · ')), style: faint),
      if (d.items.isNotEmpty)
        Text('${l.routineEstimate(d.minutes)} · $pace', style: faint),
      const SizedBox(height: 6),
      for (final (n, i) in d.items.indexed) _item(context, l, n + 1, i, faint),
      if (d.removed.isNotEmpty) ...[
        const SizedBox(height: 6),
        for (final r in d.removed)
          Row(
            children: [
              Expanded(
                child: Text(
                  l.routineRemoved(
                    _label(r.label),
                    l.routineRemovedWhy(r.reason),
                  ),
                  style: faint,
                ),
              ),
              if (onRestore != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 36),
                  onPressed: () => onRestore!(r.key),
                  child: Text(
                    l.routineRestore,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
      ],
      chips([
        if (onAdd != null)
          for (final k in d.addable)
            (label: l.routineAdd(_name(k)), onTap: () => onAdd!(k)),
        if (d.partChip != null && onPart != null)
          (label: l.routineByPart(partName(l, d.partChip!)), onTap: onPart!),
        if (d.stepChip case final s? when s.apply && onStep != null)
          (label: l.routineStepChip(s.text), onTap: onStep!),
        if (d.previousDay != null && onPrevious != null)
          (label: l.routinePrevious(date(d.previousDay!)), onTap: onPrevious!),
        if (onMode != null)
          for (final c in d.modeChips)
            (
              label: switch (c.mode) {
                'tabata' => l.routineTabataChip,
                'weekday' => l.routineLikeLastWeek(l.weekdayLabel(d.day)),
                final f => l.routineFactorChip(f, c.count ?? 0),
              },
              onTap: () => onMode!(c.mode),
            ),
      ]),
      if (d.future)
        Text(l.routineFuture, style: faint)
      else if (d.startable || started)
        Row(
          children: [
            CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              minimumSize: const Size(44, 40),
              onPressed: onStart,
              child: Text(started ? l.routineStarted : l.routineStart),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(spent ?? l.routinePlatesZero, style: faint)),
          ],
        ),
    ];
  }

  String _name(String key) =>
      exerciseByName[key.toLowerCase()]?.name(lang) ?? key;

  /// 사전 이름이면 화면 언어로.
  String _label(String title) =>
      exerciseByName[title.toLowerCase()]?.name(lang) ?? title;

  Widget _item(
    BuildContext context,
    L l,
    int n,
    RoutineItem i,
    TextStyle faint,
  ) {
    String date(DateTime x) => l.routineDate(x);
    final why = switch (i.why) {
      'copied' when i.day != null => l.routineCopied(date(i.day!)),
      'lightDropped' when i.day != null => l.routineLightDropped(date(i.day!)),
      'repsMatched' when i.day != null => l.routineRepsMatched(
        date(i.day!),
        i.sets.firstOrNull?.reps ?? 0,
      ),
      'typed' => l.routineTyped,
      // 시작한 기록에만 있는 칸 — 기록 그대로라 옮긴 날을 말하지 않는다.
      'record' => null,
      'typedWeight' when i.retyped != null => l.routineTypedWeight(
        i.retyped!.count,
        i.retyped!.from.map((s) => formatValue(s.value!, s.unit)).join('·'),
        formatValue(i.retyped!.to.value!, i.retyped!.to.unit),
      ),
      _ => l.routineFirst,
    };
    final notes = [
      if (i.blank != null) l.routineBlank(i.blank!),
      if (i.typedKept) l.routineTypedKept,
      if (i.reference case final r?)
        r.best
            ? l.routineBest(setsText(l, r.sets), date(r.day))
            : l.routineReference(setsText(l, r.sets), date(r.day)),
      if (i.stepped case final s?)
        l.routineStepped('${formatNumber(s.step)}${s.unit}', s.evidence),
      if (i.memo case final m?) l.routineMemo(date(m.day), m.text),
      if (i.recent case final r?)
        l.routineRecent(
          r.muscle != null
              ? l.muscleName(r.muscle!.name)
              : partName(l, r.part!),
          l.routineDaysAgo(r.days),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 20, child: Text('$n', style: faint)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                Text(
                  [
                    if (i.sets.isNotEmpty) setsText(l, i.sets),
                    ?why,
                  ].join('   '),
                  style: const TextStyle(fontSize: 14),
                ),
                if (notes.isNotEmpty) Text(notes.join('\n'), style: faint),
              ],
            ),
          ),
          // 시작한 기록에만 있는 칸은 ✕ 가 없다 — 카드에서 뺄 것이 없다(기록에서 뺀다).
          if (onRemove != null && i.why != 'record')
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              onPressed: () => onRemove!(i),
              child: Icon(
                CupertinoIcons.xmark,
                size: 16,
                semanticLabel: l.delete,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
        ],
      ),
    );
  }
}

String _minSec(L l, int seconds) =>
    l.routineMinSec(seconds ~/ 60, seconds % 60);

/// 세트 줄: 같은 세트가 이어지면 "×3" 으로 접는다. 값만 있으면 값, 횟수만 있으면 횟수.
String setsText(L l, List<PlanSet> sets) {
  String one(PlanSet s) => switch ((s.value, s.reps)) {
    (final v?, final r?) => '${formatValue(v, s.unit)}×$r',
    (final v?, null) => formatValue(v, s.unit),
    (null, final r?) => l.repsCount(r),
    _ => '—',
  };
  final out = <String>[];
  var i = 0;
  while (i < sets.length) {
    var j = i;
    while (j + 1 < sets.length && sets[j + 1] == sets[i]) {
      j++;
    }
    out.add(j > i ? '${one(sets[i])} ×${j - i + 1}' : one(sets[i]));
    i = j + 1;
  }
  return out.join(' · ');
}

/// 모델이 읽은 조건 한 줄 — "이렇게 읽었어요: 다리 · 덤벨만 · 30분 · 뺄 것: 런지".
String? _readAs(L l, RoutineAsk a) {
  final parts = [
    for (final p in a.parts) partName(l, p),
    if (a.pattern != null) l.routinePattern(a.pattern!),
    if (a.only.isNotEmpty)
      l.routineGearOnly(a.only.map(l.routineGear).join('·')),
    if (a.without.isNotEmpty)
      l.routineGearWithout(a.without.map(l.routineGear).join('·')),
    if (a.minutes != null) l.routineMinutes(a.minutes!),
    if (a.count != null) l.routineCount(a.count!),
    if (a.intensity != null) l.routineIntensity(a.intensity!),
    if (a.timer != null)
      a.timer!.tabata ? 'tabata' : 'bpm ${a.timer!.bpm ?? ''}'.trim(),
    if (a.delta != null)
      '${a.delta!.value > 0 ? '+' : ''}${formatNumber(a.delta!.value)}${a.delta!.unit}',
    if (a.exercises.isNotEmpty) a.exercises.join('·'),
    if (a.exclude.isNotEmpty) l.routineExclude(a.exclude.join('·')),
    if (a.avoid.isNotEmpty)
      l.routineAvoid(a.avoid.map((p) => partName(l, p)).join('·')),
  ];
  return parts.isEmpty ? null : l.routineReadAs(parts.join(' · '));
}

/// 카드의 "왜" 줄 — 원천을 고른 까닭. 말할 것이 없으면 null.
String? routineWhy(L l, RoutineDraft d) {
  final src = d.sourceDay;
  if (src == null) return null;
  final date = l.routineDate(src);
  final weekday = '${l.weekdayLabel(src)}($date)';
  final target = d.target;
  return switch (d.source) {
    'rotation' when d.restDays != null => l.routineWhyRotation(
      date,
      d.restDays!,
    ),
    'from' => l.routineWhyFrom(date),
    'conditions' => l.routineWhyNamed(date),
    'weekday' when d.near && d.skipped != null => l.routineWhyNearSkip(
      d.skipped!,
      l.weekdayLabel(d.day),
      weekday,
    ),
    'weekday' when d.near => l.routineWhyNear(l.weekdayLabel(d.day), weekday),
    'weekday' when d.skipped != null => l.routineWhyWeekdaySkip(
      d.skipped!,
      d.weeksAgo ?? 1,
      l.weekdayLabel(src),
      date,
    ),
    'weekday' => l.routineWhyWeekday(
      d.weeksAgo ?? 1,
      l.weekdayLabel(src),
      date,
    ),
    // 목표 요인 칸이 루틴에서 빠졌으면 줄(factorLost)이 말한다.
    'factor'
        when target == null || d.lines.any((x) => x.code == 'factorLost') =>
      null,
    'factor' when d.short => l.routineWhyFactor(target!.name, weekday),
    // "다 채웠어요" 는 모든 요인이 목표에 닿았을 때만. 아니면 모자란 요인의 날이 없었다.
    'factor'
        when factorGoal.entries.every(
          (g) => (d.weekCounts?[g.key] ?? 0) >= g.value,
        ) =>
      l.routineWhyFactorAll(target!.name, weekday),
    'factor' => l.routineWhyFactorNoDay(l.routineFactor(target!.name), weekday),
    _ => null,
  };
}

/// 카드 줄 하나의 문구(화면 언어). 줄이 없어지는 일은 없다 — 모르는 줄은 코드를 보인다.
List<String> routineLineTexts(L l, RoutineLine line) {
  final a = line.args;
  String s(int i) => '${a[i]}';
  return switch (line.code) {
    'future' => const [],
    'refused' => [l.routineRefused(s(0))],
    'notComputable' => notComputableLines(l, (a[0] as List).cast<String>()),
    'notStated' => [l.routineNotStated(s(0))],
    'unmet' => [l.routineUnmet(s(0))],
    'unmetKey' || 'heldKey' => [l.routineUnmet(l.routineKeyName(s(0)))],
    'unknownName' => [l.routineUnknownName(s(0))],
    'noSuchDay' => [l.routineNoSuchDay],
    'excludeAbsent' => [l.routineExcludeAbsent(s(0))],
    'noneMatched' => [
      l.routineNoneMatched(switch (s(0).split(':')) {
        ['part', final p] => p.split(',').map((p) => partName(l, p)).join('·'),
        ['pattern', final p] => l.routinePattern(p),
        ['gear', final g] => g.split(',').map(l.routineGear).join('·'),
        _ => '',
      }),
    ],
    'fewer' => [l.routineFewer(a[0] as int)],
    'otherUnit' => [l.routineOtherUnit(s(0))],
    'bpmRange' => [l.routineBpmRange],
    // 비운 칸이 있으면(아픔·기구·오래됨) "무게는 지난번 그대로" 를 빼고 말한다.
    'light' || 'hard' || 'max' => switch ((line.code, a.contains('blank'))) {
      ('light', true) => [l.routineIntensityLine('lightBlank')],
      ('hard', true) => const [],
      _ => [l.routineIntensityLine(line.code)],
    },
    'noStep' => [l.routineNoStep],
    'pain' => [
      (a[1] as List).isEmpty
          ? l.routinePainNone(s(0).isEmpty ? l.routinePainWord : s(0))
          : l.routinePain(
              s(0).isEmpty ? l.routinePainWord : s(0),
              (a[1] as List).join('·'),
            ),
    ],
    'firstTime' => [l.routineFirstTime],
    'countFit' => [l.routineCountFit(a[0] as int, a[1] as int)],
    'overUsual' => [l.routineOverUsual(a[0] as int, a[1] as int)],
    'noMore' => [l.routineNoMore(a[0] as int)],
    'overTime' => [l.routineOverTime(a[0] as int)],
    'recentMemo' => [
      l.routineRecentMemo(l.routineDaysAgo(a[0] as int), s(1), s(2)),
    ],
    'factorMissing' => [
      l.routineFactorMissing(
        (a[0] as List).map((f) => l.routineFactor('$f')).join('·'),
      ),
    ],
    'factorFiltered' => [
      l.routineFactorFiltered(
        (a[0] as List).map((f) => l.routineFactor('$f')).join('·'),
      ),
    ],
    'factorLost' => [
      l.routineFactorLost(
        l.routineFactor(s(0)),
        '${l.weekdayLabel(a[1] as DateTime)}(${l.routineDate(a[1] as DateTime)})',
      ),
    ],
    'doneToday' => [l.routineDoneToday((a[0] as List).join('·'))],
    'fillHint' => [l.routineFillHint],
    'lightKept' => [l.routineLightKept((a[0] as List).join('·'))],
    _ => [line.toString()],
  };
}

/// 요인을 가른 근거 한 줄("3×10", "채우기 100개", "타바타 20/10×8" …).
String factorWhy(L l, FactorRead r) => l.routineFactorWhy(
  r.why,
  r.args.firstOrNull ?? '',
  r.args.length > 1 ? r.args[1] : '',
);

/// 부위 이름. 전신은 기록 검색 문구에 없어 따로 둔다.
String partName(L l, String part) =>
    part == 'full' ? l.routineFullBody : l.queryPart(part);
