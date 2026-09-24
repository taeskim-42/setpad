/// 몸 그림 — 부위를 누르면 그 부위를 쓰는 운동, 내 기록, 자세 팁.
///
/// 전부 기기에서 센다(모델·서버·원판 없음). 색은 해낸 내 세트로만 칠한다.
/// 숫자는 내 세트를 그대로 옮긴 것뿐이다 — 권장량·목표 무게를 보이지 않는다.
/// 그림이 작아 못 누르는 부위가 없게, 같은 부위를 아래 목록에서도 고른다.
library;

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show
        LicenseEntryWithLineBreaks,
        LicenseRegistry,
        mapEquals,
        visibleForTesting;
import 'package:flutter/rendering.dart' show SemanticsProperties;
import 'package:intl/intl.dart';

import 'anatomy.dart';
import 'editor.dart' show SuggestionChip;
import 'exercises.dart' show langKeyOf;
import 'l10n/generated/app_localizations.dart';
import 'muscle_map_paths.dart';
import 'notes.dart';
import 'palette.dart';
import 'record_query.dart' show exerciseKey;
import 'routine_card.dart' show partName, setsText;
import 'units.dart' show formatNumber;

/// 몸 그림 그림(MIT)의 조건은 고지문을 싣는 것이다 — 설정 > 오픈소스 라이선스에 뜬다.
/// 앱이 뜰 때(main) 한 번 부른다.
void registerArtworkLicense() => LicenseRegistry.addLicense(
  () => Stream.value(
    const LicenseEntryWithLineBreaks([
      'MuscleMap body artwork (Jsplice/MuscleMap)',
    ], muscleMapLicense),
  ),
);

/// 홈으로 넘기는 것: 검색칸에 넣을 이름, 또는 오늘 루틴에 넣을 운동 열쇠와 그 부위.
typedef AnatomyHandoff = ({String? search, ({String key, String part})? add});

Path _path(List<List<double>> subs) {
  final path = Path();
  for (final s in subs) {
    path.moveTo(s[0], s[1]);
    for (var i = 2; i < s.length; i += 6) {
      path.cubicTo(s[i], s[i + 1], s[i + 2], s[i + 3], s[i + 4], s[i + 5]);
    }
    path.close();
  }
  return path;
}

final _bodies = {true: _path(frontBody), false: _path(backBody)};
final _muscles = {
  true: {for (final e in frontMuscles.entries) e.key: _path(e.value)},
  false: {for (final e in backMuscles.entries) e.key: _path(e.value)},
};

/// 그림 높이. 옆 어깨처럼 얇은 부위는 가까운 부위 고르기와 목록이 받친다.
const _figureHeight = 440.0;

/// 그림 좌표 → 화면 좌표: 높이를 맞추고 가로 가운데.
({double s, Offset o}) _fit(bool front, Size size) {
  final b = front ? frontBounds : backBounds;
  final s = size.height / (b[3] - b[1]);
  return (
    s: s,
    o: Offset((size.width - (b[2] - b[0]) * s) / 2 - b[0] * s, -b[1] * s),
  );
}

@visibleForTesting
Offset figurePoint(bool front, Size size, Offset art) {
  final f = _fit(front, size);
  return art * f.s + f.o;
}

/// 누른 곳의 부위. 정확히 든 부위가 없으면 [reach](화면 pt) 안에서 가장 가까운 것.
Muscle? _hit(bool front, Size size, Offset screen, {double reach = 24}) {
  final f = _fit(front, size);
  final p = (screen - f.o) / f.s;
  final r = reach / f.s;
  for (final ring in [0.0, r / 3, r * 2 / 3, r]) {
    for (var i = 0; i < (ring == 0 ? 1 : 8); i++) {
      final q = p + Offset.fromDirection(i * math.pi / 4, ring);
      for (final e in _muscles[front]!.entries) {
        if (e.value.contains(q)) return e.key;
      }
    }
  }
  return null;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

const _levels = ['none', 'low', 'mid', 'high'];

Color _fill(BuildContext context, int level) => level == 0
    ? CupertinoColors.systemGrey4.resolveFrom(context)
    : seal
          .resolveFrom(context)
          .withValues(alpha: const [0.0, .3, .6, .95][level]);

String _lang(BuildContext context) {
  final locale = Localizations.localeOf(context);
  return langKeyOf(locale.languageCode, locale.scriptCode, locale.countryCode);
}

class AnatomyPage extends StatefulWidget {
  const AnatomyPage({super.key, required this.notes, this.now});
  final List<Note> notes;

  /// 테스트가 오늘을 고정하는 자리.
  final DateTime? now;

  @override
  State<AnatomyPage> createState() => _AnatomyPageState();
}

class _AnatomyPageState extends State<AnatomyPage> {
  bool _front = true;
  int _days = 7;
  bool _missed = false;

  Future<void> _openSheet(Muscle m, DateTime today) async {
    setState(() => _missed = false);
    final got = await showCupertinoModalPopup<AnatomyHandoff>(
      context: context,
      builder: (_) =>
          _MuscleSheet(muscle: m, notes: widget.notes, today: today),
    );
    if (got != null && mounted) Navigator.of(context).pop(got);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final today = _day(widget.now ?? DateTime.now());
    final load = bodyLoad(widget.notes, today: today, days: _days);
    final max = load.max;
    final ever = widget.notes.any(
      (n) => n.blocks.any((b) => b.sets.any((s) => s.mine)),
    );
    final regions = _front ? frontRegions : backRegions;
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final small = TextStyle(fontSize: 13, color: muted);
    int lv(Muscle m) => level(load.of(m), max);
    String value(Muscle m) => l.anatomyRegionValue(
      _days,
      formatNumber(load.of(m)),
      l.anatomyLevel(_levels[lv(m)]),
    );
    Widget swatch(int level) => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: _fill(context, level),
        borderRadius: BorderRadius.circular(3),
      ),
    );
    final unknown = load.unknown.keys.toList();
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l.anatomyTitle)),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: CupertinoSlidingSegmentedControl<bool>(
                    groupValue: _front,
                    children: {
                      true: Text(l.anatomyFront),
                      false: Text(l.anatomyBack),
                    },
                    onValueChanged: (v) => setState(() {
                      _front = v ?? true;
                      _missed = false;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _days,
                    children: {
                      for (final d in const [7, 28]) d: Text(l.anatomyDays(d)),
                    },
                    onValueChanged: (v) => setState(() => _days = v ?? 7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) {
                final size = Size(c.maxWidth, _figureHeight);
                return GestureDetector(
                  key: const ValueKey('anatomy-figure'),
                  // 부위마다 시맨틱 노드가 있다(아래 painter) — 그림 전체를 한 버튼으로 읽지 않게.
                  excludeFromSemantics: true,
                  onTapUp: (d) {
                    final m = _hit(_front, size, d.localPosition);
                    m == null
                        ? setState(() => _missed = true)
                        : _openSheet(m, today);
                  },
                  child: CustomPaint(
                    size: size,
                    painter: _BodyPainter(
                      front: _front,
                      body: CupertinoColors.systemGrey6.resolveFrom(context),
                      line: CupertinoColors.separator.resolveFrom(context),
                      fills: {
                        for (final m in regions) m: _fill(context, lv(m)),
                      },
                      semantics: {
                        for (final m in regions)
                          m: SemanticsProperties(
                            label: l.muscleName(m.name),
                            value: value(m),
                            hint: l.anatomyRegionHint,
                            button: true,
                            textDirection: Directionality.of(context),
                            onTap: () => _openSheet(m, today),
                          ),
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            if (_missed)
              Text(
                l.anatomyTapHint,
                style: TextStyle(
                  fontSize: 14,
                  color: seal.resolveFrom(context),
                ),
              ),
            if (!ever)
              Text(l.anatomyFirstTime, style: const TextStyle(fontSize: 14))
            else if (max == 0 && unknown.isEmpty && load.cardio == 0)
              Text(
                l.anatomyEmptyWindow(_days),
                style: const TextStyle(fontSize: 14),
              )
            else ...[
              Text(l.anatomyLegend, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < 4; i++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        swatch(i),
                        const SizedBox(width: 4),
                        Text(l.anatomyLevel(_levels[i]), style: small),
                      ],
                    ),
                ],
              ),
            ],
            if (unknown.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l.anatomyUnknown(
                    [
                      ...unknown.take(5),
                      if (unknown.length > 5) '…',
                    ].join(' · '),
                  ),
                  style: small,
                ),
              ),
            if (load.cardio > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(l.anatomyCardio(load.cardio), style: small),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 12),
              child: Text(l.anatomyCountNote, style: small),
            ),
            for (final m in regions)
              GestureDetector(
                key: ValueKey('anatomy-row-${m.name}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _openSheet(m, today),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: CupertinoColors.separator.resolveFrom(context),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      swatch(lv(m)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.muscleName(m.name),
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (m == Muscle.hipFlexors)
                              Text(l.anatomyNoSurface, style: small),
                          ],
                        ),
                      ),
                      Text(
                        '${l.anatomySets(_days, formatNumber(load.of(m)))} · '
                        '${l.anatomyLevel(_levels[lv(m)])}',
                        style: small,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 15,
                        color: CupertinoColors.tertiaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(l.anatomyLimits, style: small),
          ],
        ),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.front,
    required this.body,
    required this.line,
    required this.fills,
    required this.semantics,
  });
  final bool front;
  final Color body, line;
  final Map<Muscle, Color> fills;
  final Map<Muscle, SemanticsProperties> semantics;

  @override
  void paint(Canvas canvas, Size size) {
    final f = _fit(front, size);
    canvas
      ..save()
      ..translate(f.o.dx, f.o.dy)
      ..scale(f.s);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 / f.s
      ..color = line;
    canvas.drawPath(_bodies[front]!, Paint()..color = body);
    for (final e in _muscles[front]!.entries) {
      canvas
        ..drawPath(e.value, Paint()..color = fills[e.key] ?? body)
        ..drawPath(e.value, stroke);
    }
    canvas.restore();
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
    final f = _fit(front, size);
    return [
      for (final e in _muscles[front]!.entries)
        if (semantics[e.key] case final p?)
          CustomPainterSemantics(
            key: ValueKey(e.key),
            rect: Rect.fromPoints(
              e.value.getBounds().topLeft * f.s + f.o,
              e.value.getBounds().bottomRight * f.s + f.o,
            ),
            properties: p,
          ),
    ];
  };

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.front != front ||
      old.body != body ||
      old.line != line ||
      !mapEquals(old.fills, fills);

  @override
  bool shouldRebuildSemantics(_BodyPainter old) => true;
}

class _MuscleSheet extends StatefulWidget {
  const _MuscleSheet({
    required this.muscle,
    required this.notes,
    required this.today,
  });
  final Muscle muscle;
  final List<Note> notes;
  final DateTime today;

  @override
  State<_MuscleSheet> createState() => _MuscleSheetState();
}

class _MuscleSheetState extends State<_MuscleSheet> {
  /// 펼친 운동 줄('done:열쇠' / 'try:열쇠').
  String? _open;
  bool _more = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final lang = _lang(context);
    final m = widget.muscle;
    final part = muscleCoarse[m]!;
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final small = TextStyle(fontSize: 13, color: muted);
    final week = bodyLoad(widget.notes, today: widget.today, days: 7);
    final month = bodyLoad(widget.notes, today: widget.today, days: 28);
    final done = doneFor(widget.notes, m);
    final t = tryFor(m, doneKeys(widget.notes));
    final last = done.isEmpty
        ? null
        : done.map((r) => r.day).reduce((a, b) => a.isAfter(b) ? a : b);
    String date(DateTime d) => DateFormat.MMMd(l.localeName).format(d);
    void add(String key) =>
        Navigator.pop(context, (search: null, add: (key: key, part: part)));
    Widget header(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
    Widget row({
      required String id,
      required String move,
      required String title,
      required String subtitle,
      required String addKey,
      String? search,
    }) {
      final open = _open == id;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            key: ValueKey('anatomy-$id'),
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = open ? null : id),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16)),
                        if (subtitle.isNotEmpty) Text(subtitle, style: small),
                      ],
                    ),
                  ),
                  Icon(
                    open
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 15,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ),
          if (open) ..._cues(l, lang, moves[move]!, small),
          if (open)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  SuggestionChip(
                    label: l.anatomyAddRoutine,
                    selected: false,
                    onTap: () => add(addKey),
                  ),
                  if (search != null)
                    SuggestionChip(
                      label: l.anatomySearch,
                      selected: false,
                      onTap: () =>
                          Navigator.pop(context, (search: search, add: null)),
                    ),
                ],
              ),
            ),
        ],
      );
    }

    Widget tryRow(String key) => row(
      id: 'try:$key',
      move: key,
      title: moveName(key, lang),
      subtitle: moves[key]!.gear.map(l.routineGear).join('·'),
      // 사전 운동은 열쇠, 사전 밖 운동은 화면 언어 이름(카드 제목이 된다).
      addKey: moves[key]!.names?.name(lang) ?? key,
    );

    return CupertinoPopupSurface(
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        '${l.muscleName(m.name)} · ${partName(l, part)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  CupertinoButton(
                    key: const ValueKey('anatomy-close'),
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 26,
                      semanticLabel: l.anatomyClose,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                    ),
                  ),
                ],
              ),
              if (last == null)
                Text(l.anatomyNever, style: const TextStyle(fontSize: 14))
              else ...[
                Text(
                  l.anatomySetsLine(
                    formatNumber(week.of(m)),
                    formatNumber(month.of(m)),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  l.anatomyBreakdown(
                    month.primary[m] ?? 0,
                    month.secondary[m] ?? 0,
                  ),
                  style: small,
                ),
                Text(
                  l.anatomyLast(
                    date(last),
                    l.routineDaysAgo(_daysBetween(last, widget.today)),
                  ),
                  style: small,
                ),
              ],
              if (done.isNotEmpty) header(l.anatomyDone),
              for (final r in done)
                row(
                  id: 'done:${r.key}',
                  move: r.key,
                  title:
                      '${r.name} · ${l.anatomyRole(r.primary ? 'primary' : 'secondary')}',
                  // 마지막으로 한 날의 내 세트 그대로.
                  subtitle: '${setsText(l, r.sets)} · ${date(r.day)}',
                  addKey: exerciseKey(r.name),
                  search: r.name,
                ),
              header(l.anatomyTry),
              if (t.shown.isEmpty && t.hidden.isEmpty)
                Text(l.anatomyTriedAll, style: small)
              else
                Text(
                  t.allGear
                      ? l.anatomyAllGear
                      : l.anatomyTryGear(
                          [
                            ...t.gear,
                            'bodyweight',
                          ].map(l.routineGear).join('·'),
                        ),
                  style: small,
                ),
              for (final k in t.shown) tryRow(k),
              // 거른 뒤 남은 것이 없으면 펼친 채로 — 빈 목록을 보이지 않는다.
              if (t.hidden.isNotEmpty && !_more && t.shown.isNotEmpty)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: () => setState(() => _more = true),
                  child: Text(
                    l.anatomyMoreGear(t.hidden.length),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              if (_more || t.shown.isEmpty)
                for (final k in t.hidden) tryRow(k),
            ],
          ),
        ),
      ),
    );
  }

  /// 자세 팁·흔한 실수. 한국어 밖 화면은 영어 문장이다 — 그렇다고 한 줄 적는다.
  List<Widget> _cues(L l, String lang, Move move, TextStyle small) {
    Widget line(Cue c) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '• ${cueText(c, lang)}${c.sourced ? '' : ' *'}',
        style: const TextStyle(fontSize: 14),
      ),
    );
    final all = [...move.cues, ...move.mistakes];
    return [
      Text(
        l.anatomyCues,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      for (final c in move.cues) line(c),
      const SizedBox(height: 6),
      Text(
        l.anatomyMistakes,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      for (final c in move.mistakes) line(c),
      const SizedBox(height: 4),
      Text(
        [
          l.anatomySources(move.sites.join(' · ')),
          if (all.any((c) => !c.sourced)) l.anatomyUnsourced,
          if (lang != 'ko' && lang != 'en') l.anatomyCuesEnglish,
        ].join('\n'),
        style: small,
      ),
    ];
  }
}
