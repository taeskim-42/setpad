import 'dart:async';
import 'package:flutter/cupertino.dart';

import 'l10n/generated/app_localizations.dart';
import 'notes.dart';
import 'account.dart';
import 'answer_card.dart';
import 'record_query.dart';
import 'stats.dart' as stats;
import 'editor.dart' show SuggestionChip;
import 'gym.dart';
import 'booking_entry.dart';
import 'record_ai.dart';
import 'health_summary.dart';
import 'palette.dart';
import 'parser.dart';
import 'settings.dart';

/// 운동 기록 목록.
///
/// 메모 앱의 짜임을 그대로 따른다 — 큰 제목, 날짜로 묶인 카드, 화면 맨 아래
/// 검색. 검색을 아래에 두는 이유는 한 손으로 든 기기에서 엄지가 닿는 자리가
/// 거기여서다. 헬스장에서 한 손으로 쓰는 앱이라 더 그렇다.
///
/// 치수는 Flutter 의 Cupertino 소스가 쥔 iOS 값을 따른다 — 큰 제목 34pt/w700
/// 자간 +0.38, 본문 17pt 자간 -0.41, 좌우 여백 16, 최소 터치 44.
class NotesListPage extends StatefulWidget {
  const NotesListPage({
    super.key,
    required this.store,
    required this.onOpen,
    this.onPlans,
    this.ai = const RecordAi(),
    this.account,
  });

  final NotesStore store;

  /// 질문을 해석해 주는 쪽. 서버에 묻는다.
  final RecordAi ai;

  /// 로그인과 결제. 없으면 설정에 그 항목이 안 뜬다.
  final Account? account;
  final void Function(Note) onOpen;
  final VoidCallback? onPlans;

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage>
    with WidgetsBindingObserver {
  final _query = TextEditingController();
  late final _search = RecordSearch(widget.ai);
  String? _locale;

  /// 칩으로 고른 것. 질문을 해석하는 자리가 아니라 **고르는** 자리다 — 고르면
  /// 틀릴 것이 없고 기다릴 것도 없다. 문장 해석은 부차 경로로 남아 있다.
  stats.Metric? _pick;

  /// 의심스러운 해석을 사용자가 "맞아요" 로 확인한 계획. 같은 계획 객체일 때만
  /// 유효하다 — 검색어가 바뀌어 새 계획이 오면 자연히 풀린다.
  RecordQuery? _confirmed;
  String? _confirmedContext;
  String get _confirmationContext =>
      '${DateTime.now().toIso8601String().substring(0, 10)}|$_locale|${widget.store.weightUnit}';
  bool _isConfirmed(RecordQuery? plan) =>
      plan != null &&
      identical(_confirmed, plan) &&
      _confirmedContext == _confirmationContext;

  /// 검색어 전체가 운동 이름 하나로 읽히는가. 이때만 모델을 건너뛴다 —
  /// 이름만 쳤으면 물을 것이 없다.
  String? get _bareName {
    final q = _query.text.trim();
    if (q.isEmpty) return null;
    final hit = suggest(q, _names, limit: 1);
    return hit.isEmpty ? null : hit.first;
  }

  /// 칩을 띄울 운동. 이름만 쳤든 문장 속에 들어 있든("스쾃 PR 얼마?") 잡는다.
  /// 문장일 때는 모델도 함께 돈다 — 칩은 지름길이지 대체가 아니다.
  String? get _matched {
    final bare = _bareName;
    if (bare != null) return bare;
    for (final raw in _query.text.trim().split(RegExp(r'\s+'))) {
      final word = stripParticle(raw);
      if (word.length < 2 || word.contains(RegExp(r'\d'))) continue;
      final hit = suggest(word, _names, limit: 1);
      if (hit.isNotEmpty) return hit.first;
    }
    return null;
  }

  List<String> get _names => widget.store.notes
      .expand((n) => n.blocks.map((b) => b.exercise))
      .toSet()
      .toList();

  /// 트레이너가 내려준 것. 체육관에 안 다니면 늘 비어 있다.
  List<Routine> _routines = const [];

  /// 다니는 곳이 있는가. 예약은 이 사람에게만 보인다.
  bool get _hasGym => widget.account?.gyms.isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    _search.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final account = widget.account;
    if (account == null || !account.signedIn) return;
    // 트레이너가 방금 등록해 줬을 수 있다. 다시 묻지 않으면 예약 칸이
    // 다음에 앱을 켤 때까지 안 나타난다.
    await account.refreshGyms();
    final found = await account.link.routines();
    if (mounted) setState(() => _routines = found);
  }

  int _routineSets(Routine routine) =>
      routine.blocks.fold(0, (n, b) => n + b.sets.length);

  /// 받은 루틴으로 새 기록을 연다.
  ///
  /// **자동으로 채우지 않는다.** 오늘 그걸 안 할 수도 있는데 매번 지우게 하면
  /// 개인 운동을 하려던 사람이 성가시다. 누른 사람만 받는다.
  void _startRoutine(Routine routine) {
    _open(
      widget.store.create(
        blocks: routine.blocks,
        gymId: routine.gymId,
        routineId: routine.id,
      ),
    );
    setState(() => _routines = [..._routines]..remove(routine));
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (locale != _locale) {
      _locale = locale;
      unawaited(_search.refresh(locale));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _confirmed = null;
      // 자리를 비운 사이 트레이너가 등록해 주거나 루틴을 보냈을 수 있다.
      unawaited(_loadRoutines());
      unawaited(
        _search.refresh(_locale ?? 'en').then((_) {
          if (mounted && _query.text.isNotEmpty) _ask(immediately: true);
        }),
      );
    } else {
      _search.cancel();
    }
  }

  void _ask({bool immediately = false}) {
    _search.search(
      _bareName == null ? _query.text : '',
      _locale ?? 'en',
      _names,
      widget.store.weightUnit,
      immediately: immediately,
      notes: widget.store.notes,
    );
  }

  void _open(Note note) {
    _search.cancel();
    widget.onOpen(note);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.removeListener(_changed);
    _search.dispose();
    _query.dispose();
    super.dispose();
  }

  /// 목록에 보일 기록. 답이 있으면 답에 쓰인 기록이다.
  List<Note> _visible(RecordQuery? plan, RecordResult? result) {
    final q = _query.text.trim().toLowerCase();
    final all = widget.store.notes;
    if (result != null) {
      return all.where((n) => result.evidence.contains(n.id)).toList();
    }
    if (plan != null && plan.requiresConfirmation && !_isConfirmed(plan)) {
      return all;
    }
    if (plan?.kind == 'find') {
      return all
          .where(
            (n) =>
                n.blocks.any((b) => plan!.scope.exercises.contains(b.exercise)),
          )
          .toList();
    }
    return q.isEmpty
        ? all
        : all
              .where(
                (n) =>
                    searchKey(n.searchText).contains(searchKey(q)) ||
                    suggest(q, n.blocks.map((b) => b.name).toList()).isNotEmpty,
              )
              .toList();
  }

  /// 결과를 카드로. 칸마다 한 장이다.
  // ponytail: 임시 렌더. 표·차트 카드(TableCard)가 오면 바뀐다.
  List<stats.Answer> _cards(RecordQuery plan, RecordResult result, L l) {
    if (result.render == 'number') {
      final a = result.rows.single.cells.single.answer;
      if (a == null) return const [];
      return [
        stats.Answer(
          metric: a.metric,
          exercise: result.title,
          points: a.points,
          headline: a.headline,
          numericValue: a.numericValue,
          lines: [describeScope(plan.scope, l), ...a.lines].take(3).toList(),
        ),
      ];
    }
    return [
      for (final row in result.rows)
        for (final (i, cell) in row.cells.indexed)
          if (cell.answer case final a?)
            stats.Answer(
              metric: a.metric,
              exercise: '${row.label} · ${result.columns[i]}',
              points: a.points,
              headline: a.headline,
              numericValue: a.numericValue,
              lines: a.lines,
            ),
    ];
  }

  /// 이전 7일 / 이전 30일 / 그 앞은 달로. 메모 앱과 같은 구간이다.
  List<(String, List<Note>)> _grouped(List<Note> notes, L l) {
    final now = DateTime.now();
    final week = <Note>[], month = <Note>[];
    final older = <String, List<Note>>{};
    for (final n in notes) {
      final days = now.difference(n.updatedAt).inDays;
      if (days < 7) {
        week.add(n);
      } else if (days < 30) {
        month.add(n);
      } else {
        older.putIfAbsent(l.monthLabel(n.updatedAt.month), () => []).add(n);
      }
    }
    return [
      if (week.isNotEmpty) (l.previous7Days, week),
      if (month.isNotEmpty) (l.previous30Days, month),
      ...older.entries.map((e) => (e.key, e.value)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: Column(
        children: [
          Expanded(
            // 목록의 빈 곳을 누르면 자판이 내려간다. 메모 앱이 그렇고, 올라온
            // 자판이 화면 절반을 가리면 방금 찾은 것을 볼 수가 없다.
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListenableBuilder(
                listenable: widget.store,
                builder: (context, _) {
                  final plan = _search.plan;
                  // 자신 있게 틀릴 위험이 있으면 답을 내지 않고 한 번 묻는다.
                  // 틀린 숫자보다 탭 한 번이 싸다.
                  final doubtful =
                      plan != null &&
                      plan.requiresConfirmation &&
                      !_isConfirmed(plan);
                  final result =
                      plan == null || doubtful || plan.kind != 'query'
                      ? null
                      : runQuery(
                          plan,
                          widget.store.notes,
                          l: l,
                          unit: widget.store.weightUnit,
                          confirmed: _isConfirmed(plan),
                        );
                  final visible = _visible(plan, result);
                  final groups = _grouped(visible, l);
                  return CustomScrollView(
                    slivers: [
                      // 큰 제목은 스크롤하면 가운데 작은 제목으로 접힌다. iOS
                      // 목록 화면의 기본 동작이고, 직접 흉내 내면 티가 난다.
                      CupertinoSliverNavigationBar(
                        largeTitle: Text(l.allNotes),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => showWeightSettings(
                                context,
                                widget.store,
                                account: widget.account,
                                // 홈 화면의 공동 루틴 버튼은 뺐다. 목록은 설정에서 연다.
                                onPlans: widget.onPlans,
                              ),
                              child: const Icon(CupertinoIcons.gear, size: 21),
                            ),
                          ],
                        ),
                        border: null,
                      ),
                      // 트레이너가 보낸 것. 찾는 중에는 숨긴다 — 검색 결과
                      // 위에 다른 것이 끼면 무엇을 보는 중인지 흐려진다.
                      if (_query.text.trim().isEmpty)
                        for (final routine in _routines)
                          SliverToBoxAdapter(
                            child: CupertinoButton(
                              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                              onPressed: () => _startRoutine(routine),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.person_crop_circle,
                                    size: 18,
                                    color: seal.resolveFrom(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          routine.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: CupertinoColors.label
                                                .resolveFrom(context),
                                          ),
                                        ),
                                        Text(
                                          // 무엇이 들어 있는지 한 줄. 세트가 있으면
                                          // 세트 수를, 누적 목표뿐이면 이름만.
                                          [
                                            l.routineFromTrainer(routine.gym),
                                            if (_routineSets(routine) > 0)
                                              l.setOrdinal(
                                                _routineSets(routine),
                                              ),
                                          ].join(' · '),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: CupertinoColors
                                                .secondaryLabel
                                                .resolveFrom(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      // PT 예약. **다니는 곳이 있는 사람에게만 보인다** —
                      // 헬스장과 상관없이 혼자 기록하는 사람이 대부분이고,
                      // 그 사람 화면에 예약이 뜨면 무엇을 예약하라는 말인지
                      // 알 수가 없다. 설정 안에만 두면 회원이 찾지 못한다.
                      if (_query.text.trim().isEmpty && _hasGym)
                        SliverToBoxAdapter(
                          child: CupertinoButton(
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                            onPressed: () =>
                                openBooking(context, widget.account!),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.calendar,
                                  size: 18,
                                  color: seal.resolveFrom(context),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l.bookingNew,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.label.resolveFrom(
                                        context,
                                      ),
                                    ),
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 15,
                                  color: CupertinoColors.tertiaryLabel
                                      .resolveFrom(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_query.text.trim().isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_search.busy)
                                  Text(
                                    l.queryWorking,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                if (_search.failed)
                                  Text(
                                    l.queryFailed,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                if (_search.quota)
                                  Text(
                                    l.quotaSpent,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                if (plan?.kind == 'unsupported')
                                  Text(switch (plan?.reason) {
                                    'missingData' => l.queryMissingData,
                                    'ambiguous' => l.queryAmbiguous,
                                    _ => l.queryUnsupported,
                                  }, style: const TextStyle(fontSize: 14)),
                                if (result != null &&
                                    !result.rows.any(
                                      (r) =>
                                          r.cells.any((c) => c.answer != null),
                                    ))
                                  Text(
                                    l.queryNoData,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                // 서버에 못 닿았을 때만 알린다. 준비 상태를
                                // 늘어놓던 줄은 읽을 것이 없어 뺐다.
                                if (_matched == null &&
                                    _search.status ==
                                        RecordAiStatus.unavailable)
                                  Text(
                                    l.queryOffline,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (_matched case final name?)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                            // 이름과 칩을 한 Wrap 에 섞으면 이름이 길 때 칩이
                            // 이름 끝에 매달려 두 줄로 갈라진다. 이름은 제 줄에
                            // 두고 칩은 그 아래에서 시작한다.
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.23,
                                    color: CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final (metric, label) in [
                                      (stats.Metric.max, l.metricMax),
                                      (stats.Metric.trend, l.metricTrend),
                                      (stats.Metric.last, l.metricLast),
                                      (stats.Metric.sessions, l.metricSessions),
                                      (stats.Metric.volume, l.metricVolume),
                                    ])
                                      SuggestionChip(
                                        label: label,
                                        selected: _pick == metric,
                                        onTap: () {
                                          _query.text = name;
                                          _confirmed = null;
                                          _search.search(
                                            '',
                                            _locale ?? 'en',
                                            _names,
                                            widget.store.weightUnit,
                                          );
                                          setState(
                                            () => _pick = _pick == metric
                                                ? null
                                                : metric,
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_pick case final metric? when _matched != null)
                        SliverToBoxAdapter(
                          child: AnswerCard(
                            answer: stats.answer(
                              widget.store.notes,
                              metric,
                              _matched!,
                              labels: l,
                              unit: widget.store.weightUnit,
                            ),
                          ),
                        ),
                      if (doubtful)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '${l.readAsConfirm} · ${describeQuery(plan, l, widget.store.weightUnit)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                                  ),
                                ),
                                SuggestionChip(
                                  label: l.confirmYes,
                                  selected: false,
                                  onTap: () => setState(() {
                                    _confirmed = plan;
                                    _confirmedContext = _confirmationContext;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (!doubtful && plan != null && plan.readAs.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                            child: Text(
                              plan.readAs.entries
                                  .map((e) => l.readAsNote(e.value, e.key))
                                  .join(' · '),
                              style: TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                        ),
                      if (result != null) ...[
                        for (final answer in _cards(plan!, result, l))
                          SliverToBoxAdapter(child: AnswerCard(answer: answer)),
                        if (result.diff.isNotEmpty ||
                            result.footnotes.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: Text(
                                [
                                  ...result.diff,
                                  ...result.footnotes,
                                ].join('\n'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ),
                          ),
                      ],
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                          child: Text(
                            l.noteCount(visible.length),
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (groups.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              _query.text.isEmpty
                                  ? l.noNotesYet
                                  : l.noSearchResults,
                              style: TextStyle(
                                fontSize: 17,
                                letterSpacing: -0.41,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverList.builder(
                          itemCount: groups.length,
                          itemBuilder: (context, i) => _Group(
                            title: groups[i].$1,
                            notes: groups[i].$2,
                            query: _query.text.trim(),
                            onOpen: _open,
                            onDelete: widget.store.delete,
                          ),
                        ),
                      // 검색창에 마지막 줄이 가리지 않도록 띄운다.
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    ],
                  );
                },
              ),
            ),
          ),
          _SearchBar(
            controller: _query,
            onChanged: (_) {
              _pick = null;
              _confirmed = null;
              _ask();
            },
            onSubmitted: (_) => _ask(immediately: true),
            onNew: () => _open(widget.store.create()),
          ),
        ],
      ),
    );
  }
}

/// 날짜 묶음 하나. iOS 의 inset grouped 표 한 덩이다.
class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.notes,
    required this.query,
    required this.onOpen,
    required this.onDelete,
  });

  final String title;
  final List<Note> notes;
  final String query;
  final void Function(Note) onOpen;
  final void Function(Note) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // 좌우 16 은 iOS 의 기본 여백(_kNavBarEdgePadding)과 같은 값이다.
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ),
        // 카드에 담지 않는다. 메모 앱의 목록은 한 장의 종이 위에 줄이 그어진
        // 모양이고, 카드에 담으면 기록 하나하나가 무거워 보인다.
        Column(
          children: [
            for (var i = 0; i < notes.length; i++) ...[
              if (i > 0)
                // 구분선은 글자가 시작하는 자리부터 그린다. 왼쪽 끝까지
                // 긋는 것은 안드로이드 쪽 관습이다.
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Container(
                    height: 0.5,
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
                ),
              _Row(
                note: notes[i],
                query: query,
                onOpen: onOpen,
                onDelete: onDelete,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.note,
    required this.query,
    required this.onOpen,
    required this.onDelete,
  });

  final Note note;
  final String query;
  final void Function(Note) onOpen;
  final void Function(Note) onDelete;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final summary = note.summary(setOrdinal: l.setOrdinal, reps: l.repsCount);

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: CupertinoColors.systemRed,
        child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
      ),
      // 밀기만으로 지우지 않는다. 손가락이 스치면 하루 기록이 사라졌다.
      confirmDismiss: (_) => showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(l.deleteNoteAsk(note.title ?? l.untitledNote)),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.delete),
            ),
          ],
        ),
      ).then((yes) => yes ?? false),
      onDismissed: (_) => onDelete(note),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.zero,
        onPressed: () => onOpen(note),
        child: Container(
          // 최소 44 는 iOS 의 최소 터치 크기(kMinInteractiveDimensionCupertino).
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: highlightMatch(
                          note.title ?? l.untitledNote,
                          query,
                          hit: TextStyle(color: seal.resolveFrom(context)),
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        // 본문 17pt, 자간 -0.41 — iOS 의 body 다.
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        letterSpacing: -0.41,
                        color: note.title == null
                            ? CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              )
                            : CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    ...[
                      const SizedBox(height: 5),
                      Text(
                        [
                          l.dayLabel(note.createdAt),
                          l.weekdayLabel(note.createdAt),
                          if (summary.isNotEmpty) summary,
                        ].join('  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          // 부제는 footnote 13pt.
                          fontSize: 13,
                          letterSpacing: -0.08,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                      // 칼로리는 숫자가 있을 때만 스스로 나타난다.
                      if (note.calories != null) ...[
                        const SizedBox(height: 6),
                        HealthSummary(calories: note.calories),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 화면 맨 아래 검색.
/// 화면 맨 아래 — 검색과 새 기록.
///
/// 메모 앱이 둘을 나란히 둔다. 한 손으로 든 기기에서 엄지가 닿는 자리가
/// 거기이고, 새 기록은 이 화면에서 가장 자주 누르는 것이라 위쪽 구석보다
/// 여기가 맞다.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onNew,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: CupertinoSearchTextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                placeholder: L.of(context).search,
                borderRadius: BorderRadius.circular(22),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              color: sealTint.resolveFrom(context),
              borderRadius: BorderRadius.circular(22),
              onPressed: onNew,
              child: const Icon(CupertinoIcons.square_pencil, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

/// 제목에서 검색어가 잡은 자리를 강조한다.
///
/// 글자 그대로 들어 있으면 그 글자만, 오타나 초성으로 잡힌 것이면 그 운동
/// 이름 전체를 칠한다. 초성 매칭은 원문의 어느 글자에 대응하는지가 정해져
/// 있지 않아서, 억지로 일부만 칠하면 엉뚱한 자리가 색이 든다.
List<InlineSpan> highlightMatch(
  String title,
  String query, {
  required TextStyle hit,
}) {
  final q = query.trim();
  if (q.isEmpty) return [TextSpan(text: title)];

  final at = title.toLowerCase().indexOf(q.toLowerCase());
  if (at >= 0) {
    return [
      if (at > 0) TextSpan(text: title.substring(0, at)),
      TextSpan(text: title.substring(at, at + q.length), style: hit),
      if (at + q.length < title.length)
        TextSpan(text: title.substring(at + q.length)),
    ];
  }

  // 제목은 '벤치프레스 · 스쿼트' 꼴이다. 운동 이름 단위로 퍼지 매칭을 본다.
  const sep = ' · ';
  final parts = title.split(sep);
  final spans = <InlineSpan>[];
  for (var i = 0; i < parts.length; i++) {
    if (i > 0) spans.add(const TextSpan(text: sep));
    final matched = suggest(q, [parts[i]], limit: 1).isNotEmpty;
    spans.add(TextSpan(text: parts[i], style: matched ? hit : null));
  }
  return spans;
}
