import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart' show Locale;
import 'package:setpad/editor.dart';
import 'package:setpad/exercises.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/stats.dart' show Metric;

import 'question_grading.dart';

// ── 가정한 기록 ─────────────────────────────────────────────────────────────
//
// 결과 채점은 정답 plan 과 모델 plan 을 **같은 기록**에 앱의 실행기(runPlan)로
// 돌려, 사람이 보는 표를 견준다. 그 기록이 여기다: 한 사람이 2025-06-02 부터
// 평가 기준일 2026-09-09 까지 적은 것. 이름은 문항의 기록 이름을 **친 그대로**
// 쓴다(줄임말 '벤치'·'스쾃'·'데드'·'랫풀', 타이머 제목 '푸시업 60bpm'·'버피
// 타바타 …', 지은 이름 '홈트 서킷'·'민수식 로우 2', 다른 언어 이름 'Leg Press').
// 그 밖에 같이 한 날(파트너가 적은 세트, 파트너만 한 힙쓰러스트 칸), 건네받은
// 기록, PT 루틴, 덤벨의 kg/lb 섞임, 러닝·사이클의 km + 분, 플랭크 초, 세트
// 메모(8개 언어), 워치 소모 kcal, 끼니(쉰 날 포함, 열량 미상 끼니 포함)가 있다.
// 줄이 서로 달라야 틀린 plan 이 들킨다 — 기간·요일·시간대·조건마다 값이 다르다.

const _cardio = {'러닝', '사이클', '로잉'};
const _timed = {'플랭크', '사이드 플랭크'};
const _bodyweight = {
  '푸시업',
  '풀업',
  '친업',
  '딥스',
  '크런치',
  '싯업',
  '행잉 레그레이즈',
  '레그레이즈',
  '버피',
  '점핑잭',
  '러시안 트위스트',
};
const _base = {
  '벤치프레스': 70.0,
  '인클라인 벤치프레스': 50.0,
  '덤벨 프레스': 22.5,
  '스쿼트': 100.0,
  '데드리프트': 120.0,
  '루마니안 데드리프트': 80.0,
  '오버헤드프레스': 45.0,
  '랫풀다운': 50.0,
  '시티드 로우': 45.0,
  '바벨로우': 55.0,
  '레그프레스': 140.0,
  '레그컬': 35.0,
  '사이드 레터럴 레이즈': 8.0,
  '바벨컬': 25.0,
  '덤벨컬': 12.5,
  '케이블 푸시다운': 25.0,
};
const _partBase = {
  'chest': 40.0,
  'back': 50.0,
  'legs': 60.0,
  'shoulders': 15.0,
  'arms': 20.0,
  'core': 10.0,
};

/// 세트 메모 — 그 언어로, 질문이 '…라고 적은 날' 로 인용하는 말 그대로('잠 못잤다',
/// '허리 아프다', '폼 좋음', '体調悪い' …). 정답의 어간('잠'·'허리')도 모델이 글에서
/// 옮긴 어간('잠 못잤'·'허리 아프')도 같은 날을 고른다. 다른 말로 바꿔 적은 어간
/// ('컨디션 별로' → '컨디션 안 좋')은 다른 날을 고른다 — 사람에게도 다른 답이다.
/// 개수가 홀수라 같은 메모가 짝수 날·홀수 날에 번갈아 붙는다.
const _memos = {
  'ko': [
    '컨디션 안 좋음',
    '잠 못잤다',
    '허리 아프다',
    '폼 좋음',
    '생리 중',
    '어깨 아프다',
    '무릎 시큰',
    '컨디션 별로',
    '손목 뻐근',
  ],
  'en': ['shoulder pain', 'tired', 'knee sore'],
  'ja': ['体調悪い', '肩が痛い', '寝不足'],
  'zh_Hans': ['肩膀疼', '状态不好', '没睡好'],
  'zh_Hant': ['肩膀痛', '狀態不好', '沒睡好'],
  'es': ['dolor de hombro', 'cansado', 'rodilla'],
  'vi': ['đau vai', 'mệt quá', 'đau gối'],
  'th': ['ปวดไหล่', 'เหนื่อย', 'ปวดเข่า'],
};

final _logs = <String, List<Note>>{};

/// [names] 로 친, [lang] 을 쓰는 한 사람의 기록. 같은 목록은 같은 기록이다(결정적).
///
/// [second] 는 채점의 둘째 기록이다: 무게가 작년 가을(2025-10)에 최고였다가
/// 내리고(데드리프트의 앞뒤 날은 100kg 아래, 벤치는 80kg 에 못 닿는다), 오늘은
/// 여느 날처럼 작다. 첫째 기록은 최고가 8월 중순이고 오늘이 큰 날이라 '지난달·
/// 올해·최근 최고' 가 전체 최고와, '오늘 마지막' 이 전체 마지막과 같다 — 기간·
/// 조건을 떨어뜨린 plan 이 같은 표를 냈다(재검토 rv_mutation). 둘 다에서 같아야
/// 정확이다([gradeCase]).
List<Note> assumedLog(
  List<String> names, [
  String lang = 'ko',
  bool second = false,
]) => _logs['$second\n$lang\n${names.join('\n')}'] ??= _build(
  names,
  _memos[lang]!,
  second,
);

/// 채점하는 기록 둘([assumedLog] 의 첫째·둘째).
List<List<Note>> assumedLogs(List<String> names, [String lang = 'ko']) => [
  assumedLog(names, lang),
  assumedLog(names, lang, true),
];

double _round(double v, double step) => (v / step).round() * step;

List<Note> _build(List<String> names, List<String> memos, bool second) {
  final kinds = {for (final n in names) n: exerciseKey(n)};
  // 목록 앞의 운동일수록 자주 한다: 여섯씩 이틀·사흘·나흘 … 에 한 번(하루 일곱쯤).
  int every(int i) => 2 + i ~/ 6;

  var seed = second ? 20251015 : 20260909;
  double rand() {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff;
  }

  final start = DateTime(2025, 6, 2), end = evalToday;
  final span = end.difference(start).inDays;
  final seen = <String, int>{};
  final notes = <Note>[];
  var k = 0;
  for (
    var d = start;
    !d.isAfter(end);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    final t = d.difference(start).inDays / span;
    // 둘째 기록의 흐름: 작년 가을(t≈0.3)에 최고, 그 뒤 크게 내린다.
    final grow = second ? (t < 0.3 ? t / 0.3 : 1 - 0.8 * (t - 0.3) / 0.7) : t;
    final r = rand();
    // 둘째 기록은 8/24 부터 오늘 전까지 쉬었다 — 이번 주·이번 달·최근 2주가
    // 오늘 하루뿐이라, 기간을 떨어뜨린 '마지막'·'며칠' 이 갈린다.
    final off =
        (!d.isBefore(DateTime(2025, 12, 20)) &&
            d.isBefore(DateTime(2026, 1, 5))) ||
        d == DateTime(2026, 9, 6) ||
        (second && !d.isBefore(DateTime(2026, 8, 24)) && d.isBefore(end));
    final on =
        (!d.isBefore(DateTime(2026, 8, 3)) &&
            !d.isAfter(DateTime(2026, 8, 8))) ||
        (second ? d == end : !d.isBefore(DateTime(2026, 9, 7)));
    // 요즘(8/24 부터)은 더 자주 간다 — 이번 주·지난주·오늘 같은 좁은 창에도 줄이 선다.
    final often = !d.isBefore(DateTime(2026, 8, 24));
    final trained =
        !off && (on || r < (d.weekday >= 6 ? 0.3 : (often ? 0.8 : 0.55)));
    final meals = [
      if (!d.isBefore(DateTime(2026, 1, 1)))
        for (final (i, h) in const [(0, 8), (1, 13), (2, 19)].indexed)
          if (i < 2 || d.day % 3 != 0)
            MealEntry(
              at: DateTime(d.year, d.month, d.day, h.$2, 10),
              kcal: (d.day * 7 + i) % 11 == 0
                  ? null
                  : 450 + (d.day * 37 + h.$2 * 13 + d.month * 5) % 450,
            ),
    ];
    if (!trained) {
      if (meals.isNotEmpty) {
        final at = DateTime(d.year, d.month, d.day, 8);
        notes.add(
          Note(id: 'm${notes.length}', createdAt: at, updatedAt: at)
            ..meals.addAll(meals),
        );
      }
      continue;
    }
    // 시각은 흔한 경계(5·6·7·11·12·17·18·22·24시)에서 떨어뜨린다 — 아침을 5–11시로
    // 적든 6–11시로 적든 같은 날을 고른다. 새벽 4:30 은 '해 뜨기 전' 이다.
    final hours = const [8, 8, 12, 19, 19, 19, 23, 4];
    final hour = d.weekday == 6 ? 10 : hours[(rand() * hours.length).floor()];
    final at = DateTime(d.year, d.month, d.day, hour, 30);
    // 오늘은 큰 날이다(앞의 여덟 운동) — '오늘 vs 지난번' 이 빈 칸끼리 같지 않게.
    // 둘째 기록에서는 목록 끝의 두 운동뿐인 작은 날이다 — '오늘 마지막' 이 전체
    // 마지막과 갈린다.
    final todays = [
      for (final (i, name) in names.indexed)
        // 여섯에 하나쯤은 거른다 — 같은 주기의 운동끼리 날 수가 똑같지 않게.
        if (d == end
            ? (second ? i >= names.length - 2 : i < 8)
            : (k + i) % every(i) == 0 && rand() > 0.15)
          name,
    ];
    if (todays.isEmpty) todays.add(names[k % names.length]);
    final blocks = <ExerciseBlock>[];
    for (final name in todays) {
      final ko = kinds[name]!;
      final n = seen[name] = (seen[name] ?? -1) + 1;
      final jitter = ((n % 3) - 1) * 2.5;
      LoggedSet s(double? v, int? reps, [String unit = 'kg']) =>
          LoggedSet(value: v, reps: reps, unit: unit);
      final List<LoggedSet> sets;
      if (_cardio.contains(ko)) {
        final km = _round(3 + 4 * grow + (n % 3) * 0.5, 0.1);
        sets = [
          s(km, null, 'km'),
          s(_round(km * (ko == '러닝' ? 6 : 3), 1), null, 'min'),
        ];
      } else if (_timed.contains(ko)) {
        sets = [
          s(_round(45 + 30 * grow, 5), null, 's'),
          s(_round(35 + 30 * grow, 5), null, 's'),
        ];
      } else if (_bodyweight.contains(ko)) {
        final reps = 10 + (8 * grow).round() + n % 3;
        // 둘째 기록은 푸시업도 무게를 달고(흐름 따라 10–70kg), 끝 세트가 4회다 —
        // 맨몸 운동의 무게·'5회 이상' 조건이 기간마다 갈린다.
        sets = [
          s(null, reps),
          s(null, reps - 2),
          if (n % 3 == 2 && ko != '버피' && (second || ko != '푸시업'))
            s(second ? _round(10 + 60 * grow, 2.5) : 10, 6)
          else
            s(null, second ? 4 : reps - 3),
        ];
      } else {
        final base = _base[ko] ?? _partBase[exercisePart[ko]] ?? 30.0;
        // 늘다가 8월 중순에 최고, 그 뒤 조금 내린다(최고 뒤 지난 날·정체가 0 이 아니다).
        // 둘째 기록은 기준의 0.55–1.2 배라 데드리프트가 80·100kg 앞뒤를, 벤치가
        // 80kg 앞뒤를 오간다.
        final w = math.max(
          2.5,
          _round(
            second
                ? base * (0.55 + 0.65 * grow) + jitter
                : base * (0.85 + 0.35 * t) -
                      (t > 0.94 ? base * 0.06 : 0) +
                      jitter,
            2.5,
          ),
        );
        final lb = ko.contains('덤벨') && n.isOdd;
        LoggedSet ws(double kg, int reps) =>
            lb ? s(_round(kg / 0.45359237, 5), reps, 'lb') : s(kg, reps);
        sets = [
          ws(math.max(2.5, _round(w * 0.6, 2.5)), 10),
          ws(w, 8 - n % 2),
          ws(w, 6 + n % 3),
          // 둘째 기록의 무거운 세트는 3회 — '5회 이상' 조건이 세트를 가른다.
          if (n.isEven) ws(w + 2.5, second ? 3 : 5),
        ];
      }
      blocks.add(ExerciseBlock(name, sets));
    }
    // 세 날에 한 번 메모, 다섯 날에 한 번 같이, 네 날에 한 번 PT, 열세 날에 한 번 건네받음.
    if (k % 3 == 1) {
      blocks.first.sets[blocks.first.sets.length > 1 ? 1 : 0].notes.add(
        memos[(k ~/ 3) % memos.length],
      );
    }
    final note = Note(
      id: 'w$k',
      createdAt: at,
      updatedAt: at,
      blocks: blocks,
      calories: k % 5 == 4 ? null : 250.0 + (k * 37) % 250,
      routineId: k % 4 == 3 ? 'pt' : null,
    );
    if (k % 5 == 2) {
      note.partner = PartnerSession(
        id: 'p$k',
        host: true,
        state: PartnerState.ended,
        partnerName: 'Kim',
      );
      final first = blocks.first.sets.first;
      blocks.first.sets.add(
        LoggedSet(
          value: first.value,
          reps: first.reps,
          unit: first.unit,
          author: 'Kim',
        ),
      );
      // 파트너만 한 운동 — 내 기록이 아니다(기록한 운동 목록에 없다).
      blocks.add(
        ExerciseBlock('힙쓰러스트', [LoggedSet(value: 80, reps: 10, author: 'Kim')]),
      );
    }
    if (k % 13 == 6) note.handoffToken = 'h$k';
    note.meals.addAll(meals);
    notes.add(note);
    k++;
  }
  return notes;
}

// ── 사람이 보는 답 ──────────────────────────────────────────────────────────

/// 칸 하나: 값·단위·까닭. [count] 면 값은 정확히 같아야 한다(세트·횟수·날 수).
/// 수가 없는 답(마지막으로 한 날의 세트·날짜)은 [text] 가 그 답이다.
typedef Shown = ({
  double? value,
  String? unit,
  String? reason,
  bool count,
  String? text,
});

/// 화면에 보이는 답. kind: answer | find | unrelated | ambiguous | nothing.
class Visible {
  Visible(
    this.kind, {
    this.columns = const [],
    this.rows = const [],
    this.total,
    this.nc = false,
    this.ordered = false,
    this.relate,
    this.against,
    this.keys = const {},
    this.never = const {},
  });
  final String kind;
  final List<String> columns;

  /// 줄 이름, 칸들, 그 줄의 운동(줄 이름에 든 운동 이름의 열쇠).
  final List<(String, List<Shown>, Set<String>)> rows;
  final List<Shown>? total;

  /// '기록으로 못 보는 것' 줄이 있는가.
  final bool nc;

  /// 줄 순서가 뜻인가(순위·시간 묶음).
  final bool ordered;
  final String? relate;
  final ({double value, String? unit})? against;

  /// 답에 든 운동 열쇠(find 는 찾는 운동), 그중 적은 적 없는 것.
  final Set<String> keys, never;

  bool get answers => kind == 'answer' || kind == 'find';

  @override
  String toString() => kind != 'answer'
      ? '$kind${keys.isEmpty ? '' : ' $keys'}'
      : [
          if (nc) '못봄',
          ?relate,
          if (against != null) '기준 ${against!.value}',
          columns.join('|'),
          for (final (label, cells, _) in rows)
            '$label: ${cells.map(_show).join('|')}',
          if (total != null) '합계: ${total!.map(_show).join('|')}',
        ].join(' / ');
}

String _show(Shown c) => c.value == null
    ? '${c.text ?? '—'}${c.reason == null ? '' : '(${c.reason})'}'
    : '${_num(c.value!)}${c.unit ?? ''}${c.reason == null ? '' : '(${c.reason})'}';

String _num(double v) =>
    v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(2);

L evalL(String lang) {
  final [code, ...rest] = lang.split('_');
  return lookupL(
    Locale.fromSubtags(languageCode: code, scriptCode: rest.firstOrNull),
  );
}

const _counting = {Metric.sessions, Metric.sets, Metric.reps};

/// 디코드한 plan 을 기록에 돌려 사람이 보는 답으로. 실행기가 던지는 것은
/// 무효(FormatException)로 올린다 — 화면에 답이 없다.
Visible visible(RecordQuery q, List<Note> log, L l) {
  if (q.kind == 'unsupported') {
    return Visible(q.reason, nc: q.notComputable.isNotEmpty);
  }
  if (q.kind == 'find') {
    return Visible(
      'find',
      keys: {for (final e in q.scope.exercises) exerciseKey(e)},
    );
  }
  final RecordResult r;
  try {
    r = runPlan(q, log, l: l, unit: 'kg', today: evalToday, confirmed: true)!;
  } on FormatException {
    rethrow;
  } catch (e) {
    throw FormatException('runPlan: $e');
  }
  Shown shown(Cell c) => (
    value: c.answer?.numericValue,
    unit: c.answer?.unit,
    reason: c.reason,
    count: q.per == null && _counting.contains(c.answer?.metric),
    text: c.answer == null || c.answer!.numericValue != null
        ? null
        : [?c.answer!.headline, ...c.answer!.lines].join(' / '),
  );
  final keys = {
    for (final s in q.series)
      ...s.scope.exercises.map((e) => q.never.contains(e) ? e : exerciseKey(e)),
  };
  // 줄 이름의 조각(' · ')이 운동 이름이면 그 운동의 줄이다. 기간만 다른 줄은 이름이
  // 모양 따라 달라도('지난달'·'8/1–8/31') 같은 줄일 수 있지만, 운동이 다른 줄은 다른 줄이다.
  final byLabel = {
    for (final n in recordedExercises(log)) statName(n): exerciseKey(n),
    for (final e in q.names.entries) e.value: e.key,
  };
  Set<String> rowKeys(String label) => {
    for (final part in label.split(' · ')) ?byLabel[part],
  };
  return Visible(
    'answer',
    columns: r.columns,
    rows: [
      for (final row in r.rows)
        (row.label, row.cells.map(shown).toList(), rowKeys(row.label)),
    ],
    total: r.total?.map(shown).toList(),
    nc: q.notComputable.isNotEmpty,
    ordered:
        q.order != null ||
        const {'day', 'week', 'month', 'weekday'}.contains(q.by),
    relate: q.relate,
    against: q.against,
    keys: keys,
    never: q.never,
  );
}

/// 정답 대안 하나를 사람이 보는 답으로. 정답은 뜻 그대로라 규칙 층을 지나지
/// 않는다(질문 글 없이 디코드). 정답이 디코드되지 않으면 [StateError].
Visible goldVisible(
  Object? gold,
  List<String> names,
  String lang,
  List<Note> log,
) {
  try {
    final q = decodeRecordIntent(
      gold,
      '',
      names,
      unit: 'kg',
      today: evalToday,
      locale: lang.replaceAll('_', '-'),
    );
    return visible(q, log, evalL(lang));
  } on FormatException catch (e) {
    throw StateError('정답이 앱에서 안 돌아감 $gold: ${e.message}');
  }
}

bool _same(Shown w, Shown g) {
  if (w.reason != g.reason) return false;
  final a = w.value, b = g.value;
  if (a == null || b == null) return a == b && w.text == g.text;
  if (w.unit != g.unit) return false;
  if (w.count && g.count) return a == b;
  return (a - b).abs() <= 0.005 * math.max(a.abs(), b.abs()) + 1e-9;
}

/// 가장 적게 어긋나는 짝(작은 쪽이 [free] 개 이하일 때만 모두 본다).
List<int>? _bestMatch(
  List<int> wants,
  List<int> gots,
  int Function(int w, int g) cost,
) {
  if (wants.length > gots.length) return null;
  if (wants.isEmpty) return const [];
  List<int>? best;
  var bestCost = 1 << 30;
  void go(List<int> pick, int sum) {
    if (sum >= bestCost) return;
    if (pick.length == wants.length) {
      best = [...pick];
      bestCost = sum;
      return;
    }
    for (final g in gots) {
      if (pick.contains(g)) continue;
      go([...pick, g], sum + cost(wants[pick.length], g));
    }
  }

  if (wants.length > 6) {
    // ponytail: 줄이 많으면 욕심껏 짝짓는다 — 이름이 다른 줄이 일곱 개 넘으면 어차피 틀렸다.
    final used = <int>{};
    return [
      for (final w in wants)
        () {
          final g = gots
              .where((g) => !used.contains(g))
              .reduce((a, b) => cost(w, a) <= cost(w, b) ? a : b);
          used.add(g);
          return g;
        }(),
    ];
  }
  go([], 0);
  return best;
}

/// 보이는 답 둘의 어긋남. 빈 목록이면 사람에게 같은 답이다.
///
/// - 줄: 이름이 같은 줄끼리, 남은 줄은 값이 가장 잘 맞는 짝끼리(기간을 다른
///   모양으로 적어 줄 이름만 다른 것 — '지난달' 과 '8/1–8/31'). 줄 수가 다르면 'rows'.
/// - 칸: 이름이 같은 칸끼리, 남은 정답 칸은 값이 맞는 모델 칸과. 정답의 칸이
///   모두 있어야 한다('measures'); 모델이 더 보인 칸은 괜찮다.
/// - 값: 개수는 정확히, 나머지는 ±0.5%. 까닭(never·none·future·unknown …)도 같아야.
/// - 순위·시간 묶음은 줄 순서('order'), 비율은 기준 줄('relate'), 합계 줄('total'),
///   기준 수('against'), 못 보는 것 줄('notComputable').
List<String> outcomeErrors(
  Visible want,
  Visible got, {
  Iterable<Object?> ignore = const [],
}) {
  if (want.kind != got.kind) return const ['kind'];
  final errors = <String>[
    if (want.nc != got.nc && !ignore.contains('notComputable')) 'notComputable',
  ];
  if (want.kind == 'find') {
    return [
      ...errors,
      if (want.keys.difference(got.keys).isNotEmpty ||
          got.keys.difference(want.keys).isNotEmpty)
        'exercises',
    ];
  }
  if (want.kind != 'answer') return errors;
  final skipMeasures = ignore.contains('measures');
  final limitFree = ignore.contains('limit');

  // 칸: 이름으로.
  final colOf = <int, int>{};
  for (var i = 0; i < want.columns.length; i++) {
    final j = got.columns.indexOf(want.columns[i]);
    if (j >= 0 && !colOf.containsValue(j)) colOf[i] = j;
  }
  // 줄: 이름으로, 그다음 값으로.
  var wantRows = want.rows, gotRows = got.rows;
  if (limitFree) {
    // 줄 수는 안 본다: 순위면 앞의 N줄이 같아야 하고, 아니면 적은 쪽의 줄이
    // 많은 쪽에 모두 있어야 한다('3대 중 제일 뒤처진 거' → 한 줄).
    if (want.ordered) {
      final n = math.min(wantRows.length, gotRows.length);
      wantRows = wantRows.take(n).toList();
      gotRows = gotRows.take(n).toList();
    } else {
      final a = {for (final r in wantRows) r.$1},
          b = {for (final r in gotRows) r.$1};
      if (a.containsAll(b) || b.containsAll(a)) {
        final common = a.intersection(b);
        wantRows = [
          for (final r in wantRows)
            if (common.contains(r.$1)) r,
        ];
        gotRows = [
          for (final r in gotRows)
            if (common.contains(r.$1)) r,
        ];
      }
    }
  }
  if (wantRows.length != gotRows.length) return [...errors, 'rows'];
  if (skipMeasures) {
    final a = {for (final r in wantRows) r.$1},
        b = {for (final r in gotRows) r.$1};
    return [
      ...errors,
      if (!limitFree && (a.length != b.length || !a.containsAll(b))) 'rows',
    ];
  }
  bool sameKeys(int w, int g) =>
      wantRows[w].$3.length == gotRows[g].$3.length &&
      wantRows[w].$3.containsAll(gotRows[g].$3);
  int rowCost(int w, int g) => [
    if (!sameKeys(w, g)) 100,
    for (final e in colOf.entries)
      if (wantRows[w].$2[e.key].reason != 'notAsked' &&
          !_same(wantRows[w].$2[e.key], gotRows[g].$2[e.value]))
        1,
  ].fold(0, (a, b) => a + b);
  final rowOf = <int, int>{};
  for (var i = 0; i < wantRows.length; i++) {
    final label = wantRows[i].$1;
    final j = gotRows.indexWhere((r) => r.$1 == label);
    if (j >= 0 && !rowOf.containsValue(j)) rowOf[i] = j;
  }
  final freeW = [
    for (var i = 0; i < wantRows.length; i++)
      if (!rowOf.containsKey(i)) i,
  ];
  final freeG = [
    for (var j = 0; j < gotRows.length; j++)
      if (!rowOf.containsValue(j)) j,
  ];
  final pairs = _bestMatch(freeW, freeG, rowCost)!;
  for (var x = 0; x < freeW.length; x++) {
    rowOf[freeW[x]] = pairs[x];
  }
  if (rowOf.entries.any((e) => !sameKeys(e.key, e.value))) errors.add('rows');
  // 남은 정답 칸: 값이 가장 잘 맞는 모델 칸과.
  final freeC = [
    for (var i = 0; i < want.columns.length; i++)
      if (!colOf.containsKey(i)) i,
  ];
  final openC = [
    for (var j = 0; j < got.columns.length; j++)
      if (!colOf.containsValue(j)) j,
  ];
  int colCost(int w, int g) => [
    for (final e in rowOf.entries)
      if (wantRows[e.key].$2[w].reason != 'notAsked' &&
          !_same(wantRows[e.key].$2[w], gotRows[e.value].$2[g]))
        1,
  ].length;
  final asked = [
    for (final i in freeC)
      if (wantRows.any((r) => r.$2[i].reason != 'notAsked')) i,
  ];
  final cols = _bestMatch(asked, openC, colCost);
  if (cols == null) {
    errors.add('measures');
  } else {
    for (var x = 0; x < asked.length; x++) {
      colOf[asked[x]] = cols[x];
    }
  }
  var values = false, reasons = false;
  for (final MapEntry(key: w, value: g) in rowOf.entries) {
    for (final MapEntry(key: i, value: j) in colOf.entries) {
      final a = wantRows[w].$2[i], b = gotRows[g].$2[j];
      if (a.reason == 'notAsked' || _same(a, b)) continue;
      if (a.reason != b.reason) {
        reasons = true;
      } else {
        values = true;
      }
    }
  }
  if (values) errors.add('values');
  if (reasons) errors.add('reasons');
  if (want.ordered &&
      !ignore.contains('order') &&
      rowOf.entries.any((e) => e.key != e.value)) {
    errors.add('order');
  }
  if (want.relate == 'ratio' && !ignore.contains('relate')) {
    // 기준(첫 줄)이 같아야 '몇 배' 가 같은 말이다.
    if (got.relate != 'ratio' || (rowOf[0] ?? 0) != 0) errors.add('relate');
  }
  if (want.total case final wt?) {
    final gt = got.total;
    if (gt == null ||
        colOf.entries.any(
          (e) =>
              wt[e.key].reason != 'notAsked' && !_same(wt[e.key], gt[e.value]),
        )) {
      errors.add('total');
    }
  }
  if (want.against case final a?) {
    final b = got.against;
    if (b == null ||
        (a.value - b.value).abs() > 1e-9 ||
        (a.unit ?? 'kg') != (b.unit ?? 'kg')) {
      errors.add('against');
    }
  }
  return errors;
}

/// 결과 채점 한 문항. [errors] 는 가장 가까운 정답 대안과의 어긋남, [got] 이
/// null 이면 무효(앱이 받지 못한 답)다.
typedef OutcomeGrade = ({
  List<String> errors,
  Visible? got,
  Visible want,
  bool goldCountable,
});

OutcomeGrade gradeOutcome(
  List<Visible> wants,
  Visible? got, {
  Iterable<Object?> ignore = const [],
}) {
  if (wants.isEmpty) throw StateError('no gold');
  final countable = wants.every((w) => w.kind == 'answer');
  if (got == null) {
    return (
      errors: const ['invalid'],
      got: null,
      want: wants.first,
      goldCountable: countable,
    );
  }
  ({List<String> errors, Visible want})? best;
  for (final w in wants) {
    final e = outcomeErrors(w, got, ignore: ignore);
    if (best == null || e.length < best.errors.length) {
      best = (errors: e, want: w);
    }
    if (e.isEmpty) break;
  }
  return (
    errors: best!.errors,
    got: got,
    want: best.want,
    goldCountable: countable,
  );
}

/// 한 문항을 두 기록([assumedLogs])에서 채점한다 — 둘 다에서 같아야 정확이다.
/// 첫 기록에서 어긋나면 그 채점, 아니면 둘째 기록의 채점이다. [got] 이 null 이면
/// 무효(앱이 받지 못한 답)다. 실행기가 던지면 그 기록에서 무효다. 앱에서 안 도는
/// 정답 대안은 뺀다 — 모두 안 돌면 [StateError].
OutcomeGrade gradeCase(EvalCase c, RecordQuery? got) {
  late OutcomeGrade grade;
  for (final log in assumedLogs(c.names, c.lang)) {
    final wants = <Visible>[];
    Object? broken;
    for (final g in c.gold) {
      try {
        wants.add(goldVisible(g, c.names, c.lang, log));
      } on StateError catch (e) {
        broken = e;
      }
    }
    if (wants.isEmpty) throw broken ?? StateError('no gold');
    Visible? shown;
    if (got != null) {
      try {
        shown = visible(got, log, evalL(c.lang));
      } on FormatException {
        shown = null;
      }
    }
    grade = gradeOutcome(wants, shown, ignore: c.ignore);
    if (grade.errors.isNotEmpty) break;
  }
  return grade;
}

/// 정답 plan 하나가 쓰는 2단계 갈래([planFamilies]) — 그 갈래 모듈의 키·측정이
/// 있으면 그 갈래다. 어림이다: 기간 키는 series 안(기간 비교)이나 shift·nth 일
/// 때만 period, 조건 키는 cond, 순위·합계·평균·빼기와 운동 밖의 묶음은 rank,
/// relate·against 는 ratio, 못 보는 것·무관은 refuse.
Set<String> goldFamilies(Object? gold) {
  final out = <String>{};
  void scan(Object? x, {bool inSeries = false}) {
    if (x is! Map) return;
    for (final MapEntry(:key, :value) in x.entries) {
      final k = '$key';
      if ((inSeries && _periodish.contains(k)) || k == 'shift' || k == 'nth') {
        out.add('period');
      }
      if (const {'relate', 'against'}.contains(k)) out.add('ratio');
      if (const {
        'weight',
        'reps',
        'weekdays',
        'hours',
        'set',
        'memo',
        'noMemo',
        'together',
        'routine',
        'handoff',
        'timer',
      }.contains(k)) {
        out.add('cond');
      }
      if (const {'order', 'limit', 'total', 'per', 'exclude'}.contains(k) ||
          (k == 'by' && value != 'exercise')) {
        out.add('rank');
      }
      if (k == 'trained') out.add('intake');
      if (k == 'notComputable' || (k == 'kind' && value == 'unrelated')) {
        out.add('refuse');
      }
      if (k == 'measures' && value is List) {
        for (final m in value) {
          if (const {'longestStreak', 'longestGap', 'meanGap'}.contains(m)) {
            out.add('days');
          }
          if (const {'intake', 'burned', 'balance'}.contains(m)) {
            out.add('intake');
          }
          if (const {
            'changePct',
            'daysSinceBest',
            'sessionsSinceBest',
          }.contains(m)) {
            out.add('rank');
          }
        }
      }
      if (k == 'series' && value is List) {
        for (final i in value) {
          scan(i, inSeries: true);
        }
      }
    }
  }

  scan(gold);
  return out;
}

const _periodish = {
  'period',
  'since',
  'until',
  'days',
  'shift',
  'nth',
  'sessions',
};

/// 판정(결과 기준):
/// - exact: 사람에게 같은 답이다.
/// - invalid: 앱이 모델 답을 받지 못했다(모양·한도·실행 실패).
/// - refused: 거절(unrelated·ambiguous·못 보는 것만).
/// - deadEnd: 정답은 세는데 모델 답은 거절이거나 무효다.
/// - confidentlyWrong: 틀린 숫자(또는 목록)를 보인다.
/// - swapped: 정답의 적은 적 없는 운동 대신 기록의 다른 운동이 들어왔다.
/// - falseNever: 정답의 기록 운동이 빠지고 적은 적 없는 이름이 들어왔다.
/// - dictSwap: 정답의 적은 적 없는 운동이 다른 적은 적 없는 이름이 되었다.
/// - ncMissed / ncFalse: 못 보는 것 줄을 빠뜨림 / 정답에 없는데 보임.
Set<String> outcomeVerdicts(OutcomeGrade g) {
  final got = g.got, want = g.want;
  if (got == null) return {'invalid', if (g.goldCountable) 'deadEnd'};
  final refused = !got.answers;
  final lostNever = want.never.difference(got.keys);
  final lostRecorded = want.keys.difference(want.never).difference(got.keys);
  final newRecorded = got.keys.difference(got.never).difference(want.keys);
  final newNever = got.never.difference(want.never);
  return {
    if (g.errors.isEmpty) 'exact',
    if (refused) 'refused',
    if (refused && g.goldCountable) 'deadEnd',
    if (g.errors.isNotEmpty && !refused) 'confidentlyWrong',
    if (lostNever.isNotEmpty && newRecorded.isNotEmpty) 'swapped',
    if (lostRecorded.isNotEmpty && newNever.isNotEmpty) 'falseNever',
    if (lostNever.isNotEmpty && newNever.isNotEmpty) 'dictSwap',
    if (want.nc && !got.nc) 'ncMissed',
    if (!want.nc && got.nc) 'ncFalse',
  };
}

// ── 모음 ─────────────────────────────────────────────────────────────────

/// 문항 하나: 질문, 언어(seedNames 의 키), 갈래, 기록 이름, 정답 대안, 안 볼 키,
/// 지난 지시문 예시와 글이 같은 문항인가(v2.json 의 오염 14+1문항).
typedef EvalCase = ({
  String q,
  String lang,
  String cat,
  List<String> names,
  List<Object?> gold,
  List<Object?> ignore,
  bool contaminated,
});

/// dev·heldout 의 운동 목록. v1 정답이 이 이름을 쓴다.
const koNames = [
  '스쿼트',
  '벤치프레스',
  '데드리프트',
  '랫풀다운',
  '레그프레스',
  '바벨로우',
  '덤벨컬',
  '사이드레터럴레이즈',
  '오버헤드프레스',
  '케이블 푸시다운',
  '푸시업',
];

/// 평가 모음. v3·final·blind 는 문항마다 기록 이름이 있고, v2 는 그 언어 사전
/// 전체, heldout 은 [koNames] 다.
List<EvalCase> evalCases(String set) => [
  for (final c
      in (jsonDecode(File('tool/questions/$set.json').readAsStringSync())
              as List)
          .cast<Map>()
          .map((c) => c.cast<String, Object?>()))
    if (c['names'] is List)
      (
        q: c['q'] as String,
        lang: c['lang'] as String,
        cat: c['cat'] as String,
        names: (c['names'] as List).cast<String>(),
        gold: c['gold'] as List,
        ignore: (c['ignore'] as List?) ?? const [],
        contaminated: false,
      )
    else if (set == 'v2')
      (
        q: c['q'] as String,
        lang: c['lang'] as String,
        cat: c['cat'] as String,
        names: seedNames(c['lang'] as String),
        gold: v3Gold(c),
        ignore: (c['ignore'] as List?) ?? const [],
        contaminated: c['contaminated'] == true,
      )
    else if (v2Expected((c['expected'] as Map).cast()) case final gold?)
      (
        q: c['q'] as String,
        lang: 'ko',
        cat: c['cat'] as String,
        names: koNames,
        gold: v3Alternatives(gold),
        ignore: const [],
        contaminated: false,
      ),
];
