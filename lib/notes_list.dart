import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:intl/intl.dart';

import 'l10n/generated/app_localizations.dart';
import 'notes.dart';
import 'account.dart';
import 'anatomy_page.dart';
import 'answer_card.dart';
import 'daily.dart';
import 'day_energy.dart';
import 'record_query.dart';
import 'stats.dart' as stats;
import 'editor.dart' show SuggestionChip;
import 'exercises.dart' show exerciseByName, langKeyOf;
import 'gym.dart';
import 'booking_entry.dart';
import 'record_ai.dart';
import 'health_summary.dart';
import 'palette.dart';
import 'parser.dart';
import 'paywall.dart';
import 'query_cache.dart';
import 'routine.dart';
import 'routine_card.dart';
import 'settings.dart';
import 'trainer.dart';

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
    this.ai = const RecordAi(),
    this.account,
    this.now = DateTime.now,
  });

  final NotesStore store;

  /// 오늘 루틴을 짜는 시계. 요일로 원천이 갈리므로 테스트가 못 박는다.
  final DateTime Function() now;

  /// 질문을 해석해 주는 쪽. 서버에 묻는다.
  final RecordAi ai;

  /// 로그인과 결제. 없으면 설정에 그 항목이 안 뜬다.
  final Account? account;
  final void Function(Note) onOpen;

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage>
    with WidgetsBindingObserver {
  final _query = TextEditingController();

  /// 기록 검색과 오늘 루틴이 한 저장소(queries.json)를 쓴다 — 따로 쓰면 서로 덮는다.
  late final _cache = QueryCache();
  late final _search = RecordSearch(widget.ai, cache: _cache);
  late final _routine = RoutineSearch(widget.ai, cache: _cache);

  /// 글마다 카드에서 고친 것(✕·넣기·칩). 다시 짜도(앱 복귀·날짜 바뀜) 남는다.
  final _edits = <String, RoutineEdits>{};

  /// 모델 없이 기기가 짜기로 한 글과 그 요청 — 이름만 친 글의 칩, "조건 없이 바로
  /// 짜기", 거절 뒤 "오늘 루틴 만들기".
  (String, RoutineAsk)? _device;

  /// 루틴 지시문이 기록 질문이라고 한 글 → 기록 검색으로 묻는다.
  String? _asQuestion;

  /// 기록 검색이 루틴 요청이라고 한 글 → 루틴 지시문으로 읽는다. 한 글에 둘 중 하나만
  /// 선다 — 두 모델이 서로 떠넘겨도 칩이 되풀이되지 않는다.
  String? _asRoutine;

  /// "이것도 물을까요" 로 검색칸을 바꾼 것: (물은 조각, 원래 글). 되돌아가는 칩이 쓴다.
  (String, String)? _askedToo;
  String? _locale;

  /// 칩으로 고른 측정(plan 의 측정 이름). 질문을 해석하는 자리가 아니라 **고르는**
  /// 자리다 — 고르면 틀릴 것이 없고 기다릴 것도 없다. 칩도 모델 plan 과 같은
  /// 실행기([runPlan])로 센다.
  String? _pick;

  /// "혹시 ○○?" 칩으로 이름을 바꾼 plan. 바꾼 원래 plan 과 같은 객체일 때만 쓴다.
  (RecordQuery, RecordQuery)? _swap;

  /// 이름이 둘 이상일 때 고른 칩. [_multiChips] 의 몇 번째인지다.
  int? _chip;

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
    final hit = suggest(q, _recorded, limit: 1);
    if (hit.isNotEmpty) return hit.first;
    // 안 적은 사전 운동도 이름이다 — 모델 없이 "적은 기록이 없어요" 를 보인다.
    // 사전은 강한 맞춤만 받는다('클린' 은 크런치가 아니다).
    final e = dictionaryMatch(q)?.exercise;
    return e == null
        ? null
        : _known.where((n) => exerciseKey(n) == e.ko).firstOrNull;
  }

  /// 칩을 띄울 운동. 이름만 쳤으면 그것, 문장이면 글이 지목한 것 넷까지,
  /// 그것도 없으면 낱말 하나를 퍼지로 맞춘 것("스쾃 PR 얼마?"). 문장일 때는
  /// 모델도 함께 돈다 — 칩은 지름길이지 대체가 아니다.
  List<String> get _mentioned {
    final bare = _bareName;
    if (bare != null) return [bare];
    final q = _query.text.trim();
    // 안 적은 사전 운동은 이름이 글에 그대로 있을 때만 더한다. 낱말 퍼지로 사전까지
    // 넓히면 '클린' 이 크런치가, 'best' 가 벤트오버가 된다.
    final compact = searchKey(q);
    final words = {
      for (final w in q.split(RegExp(r'\s+')))
        if (dictionaryMatch(stripParticle(w)) case (
          :final exercise,
          exact: true,
        ))
          exercise,
    };
    final recorded = _recorded;
    final pool = [
      ...recorded,
      for (final n in _known.skip(recorded.length))
        if (exerciseByName[n.toLowerCase()] case final e?
            when words.contains(e) ||
                e.keys.any(
                  (k) =>
                      searchKey(k).length >= 3 &&
                      compact.contains(searchKey(k)),
                ))
          n,
    ];
    final named = namedExercises(q, pool).take(4).toList();
    if (named.isNotEmpty) return named;
    for (final raw in q.split(RegExp(r'\s+'))) {
      final word = stripParticle(raw);
      if (word.length < 2 || word.contains(RegExp(r'\d'))) continue;
      final hit = suggest(word, recorded, limit: 1);
      if (hit.isNotEmpty) return [hit.first];
    }
    return const [];
  }

  /// 이름이 둘 이상일 때의 칩(측정 이름). 비교는 측정을 안 적은 plan — "기록 비교" 의
  /// 기본 셋이다.
  List<(String, String?)> _multiChips(L l) => [
    (l.queryCompareChip, null),
    (l.metricMax, 'best'),
    (l.metricSessions, 'trainingDays'),
    (l.metricVolume, 'volume'),
  ];

  /// 기록한 운동 = 해낸 세트가 있는 운동. 계획만 있는 루틴 칸은 아니다.
  List<String> get _recorded => recordedExercises(widget.store.notes);

  /// 칩이 알아보는 이름: 기록한 운동 + 안 적은 사전 운동(화면 언어).
  List<String> get _known => knownExercises(_recorded, _locale ?? 'en');

  /// 트레이너가 내려준 것. 체육관에 안 다니면 늘 비어 있다.
  List<Routine> _routines = const [];

  /// 다니는 곳이 있는가. 예약은 이 사람에게만 보인다.
  bool get _hasGym => widget.account?.gyms.isNotEmpty ?? false;

  /// 직원으로 있는 도장. 트레이너 입구는 이 사람에게만 보인다. 입구의 점은
  /// trainer.dart 의 reportUnread — 알림으로 연 보고서를 닫아도 거기서 꺼진다.
  List<StaffGym> _staff = const [];

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_storeChanged);
    _search.addListener(_changed);
    _routine.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    _loadRoutines();
    // 켤 때는 남겨 둔 로그인이 이 화면보다 늦게 되살아난다. 계정을 듣고 있다가
    // 직원 목록이 오면 그때 보고서를 본다.
    widget.account?.addListener(_accountChanged);
    _staff = widget.account?.staff ?? const [];
    if (_staff.isNotEmpty) unawaited(_checkReports());
  }

  /// /api/me 를 물을 때마다 직원 목록이 새로 온다. 그때만 다시 본다 — 계정은
  /// 결제·체육관 때문에도 자주 알린다.
  void _accountChanged() {
    final staff = widget.account?.staff ?? const <StaffGym>[];
    if (identical(staff, _staff)) return;
    setState(() => _staff = staff);
    unawaited(_checkReports());
  }

  Future<void> _checkReports() async {
    final account = widget.account;
    if (account != null) await checkReports(account);
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

  /// 떠 있는 답. 모델이 준 같은 plan·같은 기록이면 다시 세지 않는다 — '칼로리
  /// 추이' 같은 날별 답은 전체 기록을 훑는다. 기기가 만든 plan(칩)은 그릴 때마다
  /// 새로 나오고 칩을 누르면 바뀌니 기억하지 않는다 — 이름 몇 개만 세는 싼 셈이다.
  (Object, int, String, bool, String)? _answerKey;
  RecordResult? _answerMemo;

  RecordResult? _resultFor(
    RecordQuery query, {
    required bool local,
    required L l,
    required bool confirmed,
  }) {
    final key = (
      query,
      widget.store.revision,
      widget.store.weightUnit,
      confirmed,
      '${l.localeName} ${dayOf(DateTime.now())}',
    );
    if (!local && key == _answerKey) return _answerMemo;
    final result = runPlan(
      query,
      widget.store.notes,
      l: l,
      unit: widget.store.weightUnit,
      confirmed: confirmed,
    );
    _answerKey = key;
    _answerMemo = result;
    return result;
  }

  /// 편집기 밑에 가려져 있으면 다시 그리지 않는다 — 편집기에서 한 글자 칠 때마다
  /// (초안 저장이 알린다) 가려진 목록 전체와 떠 있는 답을 다시 세서 키 하나가
  /// 300ms 걸렸다. 돌아와 보이면 TickerMode 가 바뀌어 한 번 그린다.
  bool _shown = true;

  void _storeChanged() {
    if (mounted && _shown) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 가려지면 TickerMode 가 꺼진다. 다시 보이면 이 뒤에 build 가 돈다.
    _shown = TickerMode.valuesOf(context).enabled;
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
      // 그사이 에이전트가 새 보고서를 썼을 수 있다.
      if (_staff.isNotEmpty) unawaited(_checkReports());
      unawaited(
        _search.refresh(_locale ?? 'en').then((_) {
          // 칩으로 고른 표는 고른 그대로 둔다. 다시 물으면 확인 줄이 겹친다.
          // 담아 둔 답만 다시 푼다(날짜가 바뀌었을 수 있다). 돌아왔다고 원판을
          // 쓰지 않는다 — 묻는 것은 제출할 때뿐이다.
          if (mounted && _query.text.isNotEmpty && _chip == null) _ask();
        }),
      );
    }
    // 가려질 때 기다리던 질문을 버리지 않는다. 서버는 이미 값을 받고 답하는 중이라
    // 버리면 낸 원판만 잃는다. 돌아오면 그 답이 그대로 뜬다.
  }

  /// 이 글의 갈래. 칩으로 고른 것이 가르기보다 앞선다. 기록 검색이 넘긴 글을 루틴
  /// 지시문이 다시 기록 질문이라 하면 더 넘기지 않고 기록 쪽에서 셀 수 있는 것으로
  /// 답한다([_bounced]).
  HomeRoute? _routeOf(String text) {
    if (text.isEmpty) return null;
    if (_asQuestion == text) return HomeRoute.question;
    if (_asRoutine == text) {
      return _routineSaysQuestion(text)
          ? HomeRoute.question
          : HomeRoute.routine;
    }
    return routeHome(text);
  }

  /// 루틴 지시문이 이 글을 기록 질문이라고 답했다.
  bool _routineSaysQuestion(String text) {
    final a = _routine.text == text ? _routine.answer : null;
    return a is Map && (a['kind'] == 'lookup' || a['kind'] == 'question');
  }

  /// 두 모델이 이 글을 한 번씩 서로 넘겼다(기록 검색은 루틴, 루틴 지시문은 기록
  /// 질문). 칩을 되풀이하지 않고 글에 적힌 운동·기간으로 기기에서 센다.
  bool get _bounced {
    final text = _query.text.trim();
    return _search.plan?.kind == 'routine' &&
        (_asQuestion == text || _asRoutine == text);
  }

  void _ask({bool immediately = false}) {
    final text = _query.text.trim();
    // 오늘 루틴: 치는 동안은 담아 둔 답만, 제출하면 루틴 지시문으로 묻는다(원판).
    // "이것도 물을까요" 로 온 조각이면 원래 글의 카드를 그대로 둔다.
    _routine.peek(
      switch (_askedToo) {
        (final asked, final original) when asked == text => original,
        _ => text,
      },
      _locale ?? 'en',
      widget.store.weightUnit,
    );
    final route = _routeOf(text);
    if (route != null && route != HomeRoute.question) {
      if (immediately && route == HomeRoute.routine) {
        // 칩으로 기기가 짠 카드에서 Enter = 조건까지 읽기다. 기기 카드를 두면 모델 답은
        // 버려지고 원판만 나간다.
        if (_device?.$1 == text) setState(() => _device = null);
        unawaited(
          _routine.submit(
            text,
            _locale ?? 'en',
            widget.store.weightUnit,
            _recorded,
          ),
        );
      }
      return;
    }
    _search.search(
      _bareName == null ? _query.text : '',
      _locale ?? 'en',
      _recorded,
      widget.store.weightUnit,
      immediately: immediately,
      notes: widget.store.notes,
    );
  }

  /// 기기가 글에서 만든 plan — 칩으로 고른 것, 또는 서버에 닿지 못해 글에 적힌
  /// 이름·기간·의도 낱말로 만든 것. 모델 plan 이 아니라 확인을 묻지 않는다.
  RecordQuery? _localPlan(List<String> mentioned, L l) {
    if (mentioned.isEmpty) return null;
    final spec = switch ((_pick, _chip)) {
      (final m?, _) when mentioned.length == 1 => {
        'exercises': mentioned,
        'measures': [m],
      },
      (_, final i?) when mentioned.length > 1 => {
        'exercises': mentioned,
        if (_multiChips(l)[i].$2 case final m?) 'measures': [m],
      },
      _ => null,
    };
    if (spec == null && !_unreached && !_misread) return null;
    final strong = spec != null
        ? const <String>[]
        : namedExercises(_query.text.trim(), mentioned, fuzzy: false);
    if (spec == null && strong.isEmpty) return null;
    try {
      return spec != null
          ? decodeRecordIntent(
              spec,
              '',
              _recorded,
              unit: widget.store.weightUnit,
              locale: _locale ?? 'en',
            )
          : wordsPlan(
              _query.text.trim(),
              // 모델 없이 저절로 세는 길이다 — 칩과 달리 사람이 고르지 않았다.
              // 글에 정확히(이름·별칭·줄임말) 적힌 운동만 센다. 낱말 퍼지로
              // 잡힌 것('chung' → 런지)은 칩으로만 둔다.
              strong,
              _recorded,
              unit: widget.store.weightUnit,
              locale: _locale ?? 'en',
            );
    } on FormatException {
      return null;
    }
  }

  /// Enter 를 눌렀는데 서버에 닿지 못했다(연결·서버 오류). 칩이 없어도 글에 적힌
  /// 운동은 기기에서 센다 — 막다른 길이 없다.
  bool get _unreached =>
      _chip == null && _pick == null && (_search.offline || _search.failed);

  /// Enter 를 눌러 서버는 답했는데 그 답을 셀 plan 으로 읽지 못했다(모델이 두 번
  /// 다 읽을 수 없는 답을 낸 것 포함). 연결 문제가 아니다 — 그렇게 말하지 않고,
  /// 글에 적힌 운동은 기기에서 센다.
  bool get _misread =>
      _chip == null &&
      _pick == null &&
      (_search.misread || _search.unreadable || _bounced);

  void _open(Note note) {
    _search.cancel();
    widget.onOpen(note);
  }

  /// 원판이 없어 못 물었다. 로그인 전이면 로그인을, 로그인했으면 Pro 를 권한다.
  List<Widget> _noPlates(L l) {
    final a = widget.account;
    Widget action(String label, VoidCallback onPressed) => CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
    return [
      Text(l.noPlates(dailyPlateSets), style: const TextStyle(fontSize: 14)),
      if (a != null && !a.signedIn)
        action(l.noPlatesSignIn(accountWelcomePlates), () async {
          // 로그인하면 계정 지갑으로 같은 질문을 다시 묻는다.
          if (await a.signIn() && mounted) _ask(immediately: true);
        })
      else if (a != null && a.selling && !a.paid)
        action(
          l.platesGetPro(proPlatesPerMonth),
          () => Navigator.of(
            context,
          ).push(CupertinoPageRoute<void>(builder: (_) => Paywall(account: a))),
        ),
    ];
  }

  String get _lang {
    final locale = Localizations.localeOf(context);
    return langKeyOf(
      locale.languageCode,
      locale.scriptCode,
      locale.countryCode,
    );
  }

  /// 기록 검색이 루틴 요청이라고 했을 때: 조건 없이 바로(원판 0) / 조건까지 읽어(원판).
  /// 의료 글은 조건 없이 짜지 않는다(G3). 루틴 지시문이 이미 기록 질문이라 한 글은
  /// 다시 넘기지 않는다([conditions] false).
  Widget _escapeChips(L l, String text, {bool conditions = true}) => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      if (medicalText(text))
        Text(l.routineRefused('medical'), style: const TextStyle(fontSize: 14))
      else
        SuggestionChip(
          label: l.routineNoConditions,
          selected: false,
          onTap: () => setState(
            () => _device = (
              text,
              RoutineAsk(when: readWhen(text), device: true),
            ),
          ),
        ),
      if (conditions && !medicalText(text))
        SuggestionChip(
          label: l.routineWithConditions,
          selected: false,
          onTap: () {
            setState(() {
              _asRoutine = text;
              if (_asQuestion == text) _asQuestion = null;
            });
            _ask(immediately: true);
          },
        ),
    ],
  );

  /// 몸 그림. 돌아오면 넘긴 것을 검색칸에 둔다 — 제출하지 않으니 모델·원판을 쓰지
  /// 않는다. 루틴에 넣기는 "오늘 {부위} 루틴 만들기" 칩과 같은 기기 요청에 그 운동을
  /// 넣기([RoutineEdits.added])로 더한다 — 숫자는 composeRoutine 이 내 기록에서 옮긴다.
  Future<void> _openAnatomy() async {
    final got = await Navigator.of(context).push<AnatomyHandoff>(
      CupertinoPageRoute(
        builder: (_) => AnatomyPage(notes: widget.store.notes),
      ),
    );
    if (got == null || !mounted) return;
    final String text;
    if (got.add case (:final key, :final part)) {
      final started = _addFromAnatomy(key, part);
      text = _device!.$1;
      if (started != null) {
        _query.text = text;
        setState(() {});
        _open(started);
        return;
      }
    } else {
      text = got.search ?? '';
    }
    _query.text = text;
    setState(() {
      _pick = null;
      _chip = null;
      _confirmed = null;
    });
    _ask();
  }

  /// 몸 그림에서 넣은 카드(글·요청·만든 날). 같은 날 부위를 오가며 넣은 것은 이
  /// 카드 하나에 모은다 — 검색칸을 비웠다 와도 앞에 넣은 것이 남는다.
  (String, RoutineAsk, DateTime)? _anatomy;

  /// 몸 그림의 "오늘 루틴에 넣기". 오늘 몸 그림에서 넣던 카드(없으면 같은 글로 친
  /// 카드)에 더하고 부위를 합친다 — 앞에 넣은 것도, 카드의 ✕·넣기·시작한 기록도 잇는다.
  /// ✕ 로 뺀 운동이면 카드의 넣기처럼 되살린다. 그 카드가 시작한 그대로이면(시작함)
  /// 새 기록을 만들지 않고 시작한 기록에 칸을 붙여 그 기록을 돌려준다(G18 — 같은 운동이
  /// 두 기록에 나뉘지 않는다). 카드는 그 기록 그대로 보인다([showStarted]). 시작한 뒤
  /// ✕·넣기로 카드를 바꿨으면 새 루틴이라(검토#12) 그 루틴에 넣고 기록은 건드리지 않는다.
  Note? _addFromAnatomy(String key, String part) {
    final l = L.of(context);
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final prev = _anatomy?.$3 == day ? _anatomy : null;
    final parts = [...?prev?.$2.parts];
    if (!parts.contains(part)) parts.add(part);
    final text = l.anatomyRoutineText(
      parts.map((p) => partName(l, p)).join('·'),
    );
    final edits =
        (prev == null ? null : _edits.remove(prev.$1)) ??
        _edits[text] ??
        RoutineEdits();
    // 넣기 전 카드(몸 그림 카드, 없으면 같은 글의 칩 카드)가 시작한 그대로인가.
    final before = prev?.$2 ?? (_device?.$1 == text ? _device!.$2 : null);
    final started = before == null
        ? null
        : _started(_compose(before, edits), edits);
    final ask = RoutineAsk(parts: parts, device: true, keys: const {'parts'});
    _edits[text] = edits;
    _anatomy = (text, ask, day);
    _device = (text, ask);
    edits.removed.removeWhere((r) => r.endsWith('|$key'));
    edits.restored.add(key);
    if (!edits.added.contains(key)) edits.added.add(key);
    if (started == null) return null;
    final draft = _compose(ask, edits);
    final item = draft.items.where((i) => i.key == key).firstOrNull;
    if (item != null &&
        !started.blocks.any((b) => exerciseKey(b.exercise) == key)) {
      widget.store.update(started, [...started.blocks, startBlock(item)]);
    }
    // 카드가 바뀌었어도 시작한 기록은 이것이다 — [시작함] 은 이 기록을 열고, 카드는
    // 이 기록을 보인다.
    edits.startedMark = draftMark(draft);
    return started;
  }

  RoutineDraft _compose(RoutineAsk ask, RoutineEdits edits) => composeRoutine(
    widget.store.notes,
    ask,
    now: widget.now(),
    unit: widget.store.weightUnit,
    lang: _lang,
    edits: edits,
  );

  /// 시작 = 트레이너 루틴과 같은 길(새 기록 + 편집기). 누를 때마다 새 칸이다 — 이미
  /// 시작한 카드는 [시작함] 이 그 기록을 연다(두 번 눌러도 기록은 하나다, G18).
  /// 카드가 바뀌었으면(다른 루틴·✕·넣기) 시작한 기록을 열지 않고 새로 시작한다.
  void _startDraft(RoutineDraft draft, RoutineEdits edits) {
    final note = widget.store.create(blocks: startBlocks(draft));
    edits
      ..started = note.id
      ..startedMark = draftMark(draft);
    _open(note);
  }

  /// 이 초안 그대로 시작한 기록.
  Note? _started(RoutineDraft draft, RoutineEdits edits) =>
      edits.startedMark == draftMark(draft)
      ? widget.store.notes.where((n) => n.id == edits.started).firstOrNull
      : null;

  /// 오늘 루틴 카드. 모델은 조건만 읽고, 루틴은 기기가 내 기록으로 짠다.
  /// 모델을 못 쓰면 기기가 글에서 읽을 수 있는 것만으로 짜되, 빼기·아픈 곳 낱말이
  /// 있으면 [시작] 이 있는 카드를 띄우지 않는다(G1) — "스쿼트 말고" 가 스쿼트를
  /// 넣으면 안 된다.
  Widget _routineCard(L l, String text, HomeRoute? route) {
    final recorded = _recorded;
    final lang = _lang;
    final edits = _edits.putIfAbsent(text, RoutineEdits.new);
    final status = <String>[];
    final actions = <RoutineAction>[];
    final extra = <Widget>[];
    RoutineAction plain() => (
      label: l.routineNoConditions,
      onTap: () => setState(
        () => _device = (text, RoutineAsk(when: readWhen(text), device: true)),
      ),
    );
    // 원판이 없으면 로그인·Pro 권유(기존 문구)를 카드 위에.
    Widget withExtra(Widget card) => extra.isEmpty
        ? card
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: extra,
                ),
              ),
              card,
            ],
          );
    Widget bare() => withExtra(
      RoutineCard(
        status: status,
        actions: actions,
        trainer: _routines,
        onTrainer: _startRoutine,
      ),
    );
    RoutineAsk? ask;
    final r = _routine;
    if (_device case (final t, final a) when t == text) {
      ask = a;
    } else if (route == HomeRoute.bare) {
      ask = deviceAsk(text, recorded, bare: true);
    } else if (route == HomeRoute.refuse) {
      final kind = homeRefusal(text) ?? 'other';
      status.add(l.routineRefused(kind));
      if (kind == 'drug' || kind == 'diet') {
        actions.add((
          label: l.routineMake,
          onTap: () => setState(
            () => _device = (
              text,
              RoutineAsk(when: readWhen(text), device: true),
            ),
          ),
        ));
      }
      return bare();
    } else {
      var misread = false;
      if (r.text == text && r.answer != null) {
        try {
          ask = decodeRoutineAsk(
            r.answer,
            text,
            recorded,
            lang: lang,
            sent: canonicalizeExercises(text, recorded),
          );
        } on FormatException {
          misread = true;
        }
        if (ask != null && ask.question) {
          actions.add((
            label: l.routineAsQuestion,
            onTap: () {
              setState(() {
                _asQuestion = text;
                if (_asRoutine == text) _asRoutine = null;
              });
              _ask(immediately: true);
            },
          ));
          return bare();
        }
      }
      if (ask == null) {
        final mine = r.text == text;
        final failed =
            mine &&
            (r.failed || r.noPlates || r.misread || r.tooLong || r.aiOff);
        if (r.busy) {
          status.add(l.routineWorking);
          return bare();
        }
        if (r.noPlates && mine) extra.addAll(_noPlates(l));
        if (failed || misread) {
          // 까닭마다 다른 말(원칙 4): 연결 · 원판 없음 · 모델이 깨진 답 · 너무 긴 글.
          // 다시 시도는 연결 실패와 첫 깨진 답에만 — 긴 글은 다시 해도 같다.
          final canRetry = mine && (r.failed || (r.misread && r.retry));
          RoutineAction retry() =>
              (label: l.routineRetry, onTap: () => _ask(immediately: true));
          if (medicalText(text)) {
            // 의료 글은 기기가 짜지 않는다(G3) — 조건 없이 짜는 칩도 없다.
            status.add(l.routineRefused('medical'));
            if (canRetry) actions.add(retry());
            return bare();
          }
          if (mine && r.tooLong) {
            status.add(l.queryTooLong(maxQuestionLength));
            actions.add(plain());
            return bare();
          }
          if (unreadableConditions(text)) {
            status.add(
              mine && r.aiOff
                  ? l.aiOff
                  : l.routineHeldBack(
                      misread || (mine && r.misread)
                          ? 'misread'
                          : mine && r.noPlates
                          ? 'noPlates'
                          : 'offline',
                    ),
            );
            actions.add(plain());
            if (canRetry) actions.add(retry());
            return bare();
          }
          ask = deviceAsk(text, recorded);
          status.add(
            mine && r.aiOff
                ? l.aiOff
                : misread || (mine && r.misread)
                ? l.routineMisread
                : mine && r.noPlates
                ? l.routineNoPlates
                : l.routineOffline,
          );
          if (canRetry) actions.add(retry());
        } else {
          // 아직 안 물었다 — 이름만 친 글은 칩으로 바로(원판 0), 아니면 Enter 안내.
          if (routineNameOnly(text) case final only?) {
            actions.add((
              label: only.parts.isEmpty
                  ? l.routineMake
                  : l.routineMakePart(partName(l, only.parts.first)),
              onTap: () => setState(
                () => _device = (
                  text,
                  RoutineAsk(
                    parts: only.parts,
                    device: true,
                    keys: {if (only.parts.isNotEmpty) 'parts'},
                  ),
                ),
              ),
            ));
          }
          if (widget.ai.supported) status.add(l.routinePressEnter);
          return bare();
        }
      }
    }
    final draft = _compose(ask, edits);
    // 시작한 그대로인 카드는 그 기록을 보인다(몸 그림에서 붙인 칸까지).
    final started = _started(draft, edits);
    if (started != null) showStarted(draft, started);
    if (ask.ask case final question? when _askedToo?.$1 != question) {
      actions.add((
        label: l.routineAskToo(question),
        onTap: () {
          _query.text = question;
          setState(() {
            _asQuestion = question;
            _askedToo = (question, text);
          });
          _ask(immediately: true);
        },
      ));
    }
    final account = widget.account;
    // 원판 줄: 이 글로 서버가 답했으면(깨진 답 뒤에 칩으로 짠 카드여도) 원판이
    // 나갔다. 다시 친 글이 이번엔 보내지 않았어도 앞서 원판이 나갔으면 그렇게 말한다.
    // 한 번도 원판이 나가지 않은 글의 카드만 원판 0이다.
    final charged = r.charged && r.text == text;
    final before = r.chargedBefore && r.text == text;
    final card = RoutineCard(
      draft: draft,
      ask: ask,
      status: status,
      actions: actions,
      trainer: _routines,
      onTrainer: _startRoutine,
      onStart: started != null
          ? () => _open(started)
          : draft.startable
          ? () => _startDraft(draft, edits)
          : null,
      started: started != null,
      onRemove: (item) => setState(() {
        edits.restored.remove(item.key);
        edits.removed.add(removalKey(draft, item.key));
      }),
      onRestore: (key) => setState(() {
        edits.removed.remove(removalKey(draft, key));
        edits.restored.add(key);
      }),
      onAdd: (key) => setState(() => edits.added.add(key)),
      onOther: () => setState(() => edits.alt++),
      onPrevious: () => setState(() => edits.previous = true),
      onPart: () => setState(() => edits.part = draft.partChip),
      onStep: () => setState(() => edits.step = true),
      onMode: (mode) => setState(() => edits.mode = mode),
      spent: !charged
          ? (before ? l.routinePlatesBefore : null)
          : account?.platesSpent != null
          ? l.platesSpent(account!.platesSpent!, account.plates!)
          : '',
      lang: lang,
    );
    return withExtra(card);
  }

  @override
  void dispose() {
    widget.store.removeListener(_storeChanged);
    WidgetsBinding.instance.removeObserver(this);
    widget.account?.removeListener(_accountChanged);
    _search.removeListener(_changed);
    _routine.removeListener(_changed);
    _routine.dispose();
    _search.dispose();
    _query.dispose();
    super.dispose();
  }

  /// 글이 있는데 아직 모델에 묻지 않았다 — Enter 를 누르면 물을 수 있다.
  bool _unasked(RecordQuery? plan) =>
      _query.text.trim().isNotEmpty &&
      _bareName == null &&
      plan == null &&
      _search.ai.supported &&
      !(_search.busy ||
          _search.failed ||
          _search.misread ||
          _search.unreadable ||
          _search.noPlates ||
          _search.unrepresentable != null ||
          _search.tooLong ||
          _search.offline ||
          _search.aiOff);

  /// 목록에 보일 기록. 답이 있으면 답에 쓰인 기록이다.
  ///
  /// 답이 아직 없으면(확인 전, 해석 중, 실패, 오프라인) 글이 가리킨 운동과
  /// 기간으로 거른다 — 모델을 기다리는 동안 목록이 0 으로 비지 않는다.
  List<Note> _visible(
    RecordQuery? plan,
    RecordResult? result,
    List<String> mentioned,
  ) {
    final q = _query.text.trim().toLowerCase();
    final all = widget.store.notes;
    if (result != null) {
      return all.where((n) => result.evidence.contains(n.id)).toList();
    }
    if (plan?.kind == 'find') {
      return all
          .where(
            (n) =>
                n.blocks.any((b) => plan!.scope.exercises.contains(b.exercise)),
          )
          .toList();
    }
    ({DateTime? since, DateTime? until})? period;
    if (statedPeriod(q) case final p?) {
      try {
        period = resolvePeriod(
          p.period,
          days: p.days,
          since: p.since,
          until: p.until,
        );
      } on FormatException {
        // 못 푸는 기간("최근 9999일")이면 기간으로는 거르지 않는다.
      }
    }
    if (mentioned.isEmpty && period == null) {
      // "가장 많이 한 운동 3개" — 글로 거를 것이 없는 질문이다. 해석을 기다리는
      // 동안과 확인 전에는 다 보인다. 문장을 글자로 찾으면 0 이 된다.
      if (_search.busy || plan?.kind == 'query') return all;
      if (q.isEmpty) return all;
      // 퍼지 맞춤은 이름마다 따로 매긴다 — 기록마다 부르지 않고 다른 이름들에 한
      // 번만(자르지 않고) 부른다. 기록마다 부르던 것이 글자 하나에 수십 ms 였다.
      final names = {
        for (final n in all)
          for (final b in n.blocks) b.name,
      }.toList();
      final fuzzy = suggest(q, names, limit: names.length).toSet();
      final key = searchKey(q);
      return all
          .where(
            (n) =>
                searchKey(n.searchText).contains(key) ||
                n.blocks.any((b) => fuzzy.contains(b.name)),
          )
          .toList();
    }
    return all.where((n) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      return (mentioned.isEmpty ||
              n.blocks.any((b) => mentioned.contains(b.exercise))) &&
          (period?.since == null || !d.isBefore(period!.since!)) &&
          (period?.until == null || !d.isAfter(period!.until!));
    }).toList();
  }

  /// 답 한 장. 모양은 실행기가 정했다 — 숫자 하나, 표, 차트. 위에는 못 보는 것·
  /// 적은 적 없는 운동, 아래에는 차이·각주.
  Widget _answer(RecordQuery q, RecordResult r, L l) {
    final faint = TextStyle(
      fontSize: 13,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    );
    Widget text(List<String> lines, EdgeInsets padding) => Padding(
      padding: padding,
      child: Text(lines.join('\n'), style: faint),
    );
    final Widget card;
    var notes = [...r.lines, ...r.footnotes];
    switch (r.render) {
      case 'table':
        // 표는 차이와 각주를 제 안에 싣는다.
        card = TableCard(query: q, result: r);
        notes = const [];
      case 'chart':
        final dots = [
          for (final row in r.rows)
            if (row.cells.single.answer case final a?
                when a.numericValue != null && row.start != null)
              (row, a),
        ];
        final total = r.total?.single.answer;
        card = AnswerCard(
          answer: stats.Answer(
            metric: q.measures.single,
            exercise: r.title,
            // 값이 없는 구간은 점을 찍지 않는다. 개수형의 0 인 구간은 값(0)이다.
            points: [
              for (final (row, a) in dots)
                stats.DayPoint(
                  row.start!,
                  a.numericValue!,
                  0,
                  a.unit ?? a.points.firstOrNull?.unit ?? '',
                ),
            ],
            // 합계·평균이 있으면 그것, 없으면 마지막 구간과 그 값.
            headline: switch ((total, dots.lastOrNull)) {
              (final t?, _) => '${t.exercise} ${t.headline}',
              (_, (final row, final a)?) => '${row.label} ${a.headline}',
              _ => null,
            },
            lines: [
              describeScope(q.scope, l),
              '${groupLabel(l, q.by!)} · ${r.columns.single}',
            ],
          ),
        );
      default:
        final c = r.rows.single.cells.single;
        final a = c.answer;
        final why = c.reason == 'never' ? null : cellReason(l, c.reason);
        card = a == null
            // 셀 수 없는 칸도 까닭을 말한다(적은 적 없음은 위 줄이 말한다).
            ? why == null
                  ? const SizedBox.shrink()
                  : text([why], const EdgeInsets.fromLTRB(20, 4, 20, 4))
            : AnswerCard(
                answer: stats.Answer(
                  metric: a.metric,
                  exercise: r.title,
                  points: a.points,
                  headline: a.headline,
                  numericValue: a.numericValue,
                  unit: a.unit,
                  lines: [
                    describeScope(q.scope, l),
                    ...a.lines,
                  ].take(3).toList(),
                ),
              );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.header.isNotEmpty)
          text(r.header, const EdgeInsets.fromLTRB(20, 4, 20, 0)),
        card,
        if (notes.isNotEmpty)
          text(notes, const EdgeInsets.fromLTRB(20, 0, 20, 8)),
      ],
    );
  }

  /// 이전 7일, 그 앞은 달마다. '이전 30일' 은 두 달에 걸쳐 8월 기록이 '8월' 머리
  /// 위에 섞였다. 줄에 적힌 날짜(만든 날)로 가르고 달은 최근 것부터, 올해가
  /// 아니면 해도 적는다 — 달만으로 묶으면 작년 9월과 올해 9월이 한 묶음이었다.
  List<(String, List<Note>)> _grouped(List<Note> notes, L l) {
    final now = DateTime.now();
    final week = <Note>[];
    final months = <DateTime, List<Note>>{};
    for (final n in notes) {
      final at = n.createdAt;
      if (now.difference(at).inDays < 7) {
        week.add(n);
      } else {
        months.putIfAbsent(DateTime(at.year, at.month), () => []).add(n);
      }
    }
    final keys = months.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      if (week.isNotEmpty) (l.previous7Days, week),
      for (final m in keys)
        (
          m.year == now.year
              ? l.monthLabel(m.month)
              : DateFormat.yMMMM(l.localeName).format(m),
          months[m]!,
        ),
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
              child: Builder(
                builder: (context) {
                  final text = _query.text.trim();
                  final route = _routeOf(text);
                  final routineMode =
                      (route != null && route != HomeRoute.question) ||
                      _device?.$1 == text;
                  final mentioned = routineMode ? const <String>[] : _mentioned;
                  final asked = routineMode ? null : _search.plan;
                  // "혹시 ○○?" 로 이름을 바꿨으면 그 plan 이다(모델도 원판도 안 쓴다).
                  final plan = switch (_swap) {
                    (final from, final to) when identical(from, asked) => to,
                    _ => asked,
                  };
                  // 자신 있게 틀릴 위험이 있으면 답을 내지 않고 한 번 묻는다.
                  // 틀린 숫자보다 탭 한 번이 싸다.
                  final doubtful =
                      plan != null &&
                      plan.requiresConfirmation &&
                      !_isConfirmed(plan);
                  // 칩과 연결이 안 될 때의 plan 은 기기가 만든 것이라 묻지 않는다.
                  final local = _localPlan(mentioned, l);
                  final query =
                      local ??
                      (plan == null || doubtful || plan.kind != 'query'
                          ? null
                          : plan);
                  final result = query == null
                      ? null
                      : _resultFor(
                          query,
                          local: local != null,
                          l: l,
                          confirmed: local != null || _isConfirmed(query),
                        );
                  final recordedKeys = {
                    for (final r in _recorded) exerciseKey(r),
                  };
                  final unrecorded = [
                    for (final n in mentioned)
                      if (!recordedKeys.contains(exerciseKey(n))) n,
                  ];
                  // 루틴으로 가르는 글이어도 치는 동안의 기록 목록(글자·글이 가리킨
                  // 운동·기간)은 카드 아래에 그대로 둔다 — "타바타", "스쿼트 5x5" 로
                  // 찾던 기록이 사라지지 않는다.
                  final visible = routineMode
                      ? _visible(null, null, _mentioned)
                      : _visible(plan, result, mentioned);
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
                              onPressed: _openAnatomy,
                              // 사람 아이콘은 계정으로 읽힌다 — 몸 모양을 쓴다.
                              child: Icon(
                                Icons.accessibility_new,
                                size: 22,
                                semanticLabel: l.anatomyOpen,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => showWeightSettings(
                                context,
                                widget.store,
                                account: widget.account,
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
                      // 트레이너 보고. **직원에게만 보인다** — 회원 화면에 뜨면
                      // 무엇을 보라는 말인지 알 수 없다.
                      if (_query.text.trim().isEmpty && _staff.isNotEmpty)
                        SliverToBoxAdapter(
                          child: CupertinoButton(
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                            onPressed: () =>
                                openTrainer(context, widget.account!),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.doc_text,
                                  size: 18,
                                  color: seal.resolveFrom(context),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l.trainerReport,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                                  ),
                                ),
                                ValueListenableBuilder(
                                  valueListenable: reportUnread,
                                  builder: (context, unread, _) => !unread
                                      ? const SizedBox.shrink()
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                            left: 6,
                                          ),
                                          child: Semantics(
                                            label: l.trainerUnread,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: seal.resolveFrom(
                                                  context,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                                const Spacer(),
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
                      if (routineMode)
                        SliverToBoxAdapter(child: _routineCard(l, text, route))
                      else if (_askedToo case (
                        final asked,
                        final original,
                      ) when asked == text)
                        // "이것도 물을까요" 로 물은 조각의 답 위에 친 루틴 부분(카드)을 둔다.
                        SliverToBoxAdapter(
                          child: _routineCard(l, original, _routeOf(original)),
                        ),
                      if (_query.text.trim().isNotEmpty && !routineMode)
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
                                // 모델이 읽을 수 없는 답을 두 번 냈다 — 연결 문제가
                                // 아니고 그 답에는 원판이 나가지 않았다(1단계 몫은
                                // 원판 줄이 말한다). 글에 적힌 운동은 그동안 기기에서
                                // 세고, 같은 글로 다시 묻는다.
                                if (_search.unreadable) ...[
                                  Text(
                                    [
                                      _search.charged
                                          ? l.queryUnreadablePaid
                                          : l.queryUnreadable,
                                      if (local != null) l.queryUnreadableLocal,
                                    ].join(' '),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(44, 44),
                                    onPressed: () => _ask(immediately: true),
                                    child: Text(
                                      l.queryAskAgain,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                                // 서버는 답했다 — 연결 문구가 아니라 읽지 못했다고
                                // 말하고, 말을 바꾸면 다시 읽는다고 알린다.
                                if (_search.misread)
                                  Text(
                                    _misread && local != null
                                        ? l.queryMisreadLocal
                                        : l.queryMisread,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                // 다시 해도 같은 거절이다. "다시 시도" 가 아니라
                                // 무엇을 못 하는지 말한다.
                                if (_search.unrepresentable case final kind?)
                                  Text(
                                    l.queryLimit(kind),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                if (_search.tooLong)
                                  Text(
                                    l.queryTooLong(maxQuestionLength),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                if (_search.aiOff)
                                  Text(
                                    l.aiOff,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                if (_search.noPlates) ..._noPlates(l),
                                // "이것도 물을까요" 로 온 조각 — 원래 글(루틴 카드)로 돌아간다.
                                if (_askedToo case (
                                  final asked,
                                  final original,
                                ) when asked == text)
                                  SuggestionChip(
                                    label: l.routineBack,
                                    selected: false,
                                    onTap: () {
                                      _query.text = original;
                                      setState(() => _askedToo = null);
                                      _ask();
                                    },
                                  ),
                                // 기록 검색이 루틴 요청으로 읽었다 — 두 길을 칩으로. 루틴
                                // 지시문이 이미 기록 질문이라 한 글이면 넘기지 않고
                                // 셀 수 없다고 말한다(원판 0 길은 남긴다).
                                if (plan?.kind == 'routine') ...[
                                  if (!medicalText(text))
                                    Text(
                                      !_bounced
                                          ? l.routineFromQuestion
                                          : local != null
                                          ? l.queryMisreadLocal
                                          : l.queryMisread,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  _escapeChips(l, text, conditions: !_bounced),
                                ],
                                // 거절도 까닭별이다: 무관한 질문, 무엇을 셀지 모름,
                                // 기록에 없는 것만 물음(무엇이 없는지 적는다).
                                if (local == null &&
                                    plan?.kind == 'unsupported')
                                  Text(
                                    refusalLines(plan!, l).join('\n'),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                // 이름만 찾았는데 적은 적 없는 운동.
                                if (local == null &&
                                    plan?.kind == 'find' &&
                                    plan!.never.isNotEmpty)
                                  Text(
                                    l.queryNeverRows(
                                      plan.never
                                          .map((k) => plan.names[k] ?? k)
                                          .join(', '),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                // 줄마다 0·까닭이 있으면 표가 말한다. 셀 것이 하나도
                                // 없을 때만 이 줄이다.
                                if (result != null &&
                                    !result.rows.any(
                                      (r) => r.cells.any(
                                        (c) =>
                                            c.answer != null ||
                                            cellReason(l, c.reason) != null,
                                      ),
                                    ) &&
                                    result.header.isEmpty)
                                  Text(
                                    l.queryNoData,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                // 원판을 쓴 질문에만 한 줄. 담아 둔 답은 안 쓴다.
                                if (_search.charged &&
                                    widget.account?.platesSpent != null)
                                  Text(
                                    l.platesSpent(
                                      widget.account!.platesSpent!,
                                      widget.account!.plates!,
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: CupertinoColors.secondaryLabel
                                          .resolveFrom(context),
                                    ),
                                  ),
                                // 서버에 못 닿았을 때만 알린다. 준비 상태를
                                // 늘어놓던 줄은 읽을 것이 없어 뺐다. 칩이 뜬
                                // 글이어도 Enter 를 눌렀으면 왜 답이 없는지 말한다.
                                // 글에 운동이 있으면 기기에서 세고 그렇다고 말한다.
                                if (_unreached && local != null)
                                  Text(
                                    l.queryOfflineLocal,
                                    style: const TextStyle(fontSize: 14),
                                  )
                                else if (_search.offline ||
                                    (mentioned.isEmpty &&
                                        _search.status ==
                                            RecordAiStatus.unavailable))
                                  Text(
                                    l.queryOffline,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (mentioned.isNotEmpty)
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
                                  mentioned.join(' · '),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.23,
                                    color: CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                                  ),
                                ),
                                // 안 적은 운동도 칩이 뜬다. 답이 없을 때는 여기서
                                // 먼저 말한다(답이 있으면 답 위 줄이 말한다).
                                if (unrecorded.isNotEmpty && result == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      l.queryNeverRows(unrecorded.join(', ')),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: CupertinoColors.secondaryLabel
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (mentioned case [final name])
                                      for (final (metric, label) in [
                                        ('best', l.metricMax),
                                        ('weightChange', l.metricTrend),
                                        ('latest', l.metricLast),
                                        ('trainingDays', l.metricSessions),
                                        ('volume', l.metricVolume),
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
                                              _recorded,
                                              widget.store.weightUnit,
                                            );
                                            setState(
                                              () => _pick = _pick == metric
                                                  ? null
                                                  : metric,
                                            );
                                          },
                                        )
                                    else
                                      // 글자는 그대로 두고 모델 결과만 비운다.
                                      for (final (i, (label, _)) in _multiChips(
                                        l,
                                      ).indexed)
                                        SuggestionChip(
                                          label: label,
                                          selected: _chip == i,
                                          onTap: () {
                                            _confirmed = null;
                                            _search.search(
                                              '',
                                              _locale ?? 'en',
                                              _recorded,
                                              widget.store.weightUnit,
                                            );
                                            setState(
                                              () =>
                                                  _chip = _chip == i ? null : i,
                                            );
                                          },
                                        ),
                                  ],
                                ),
                              ],
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
                                  '${l.readAsConfirm} · ${describePlan(plan, l, widget.store.weightUnit, notes: widget.store.notes)}',
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
                      // "혹시 ○○?" — 적은 적 없는 이름에 가까운 운동. 누르면 그
                      // 이름으로 다시 센다(모델도 원판도 안 쓴다).
                      if (local == null &&
                          plan != null &&
                          plan.maybe.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                for (final MapEntry(key: from, value: names)
                                    in plan.maybe.entries)
                                  for (final to in names)
                                    SuggestionChip(
                                      label: l.queryMaybe(to),
                                      selected: false,
                                      onTap: () => setState(() {
                                        final swapped = plan.withName(from, to);
                                        // 이미 "맞아요" 한 읽기면 이름만 바꾼 것도 확인된 것이다.
                                        if (_isConfirmed(plan)) {
                                          _confirmed = swapped;
                                        }
                                        _swap = (asked!, swapped);
                                      }),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      if (local == null &&
                          !doubtful &&
                          plan != null &&
                          plan.readAs.isNotEmpty)
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
                      if (query != null && result != null)
                        SliverToBoxAdapter(child: _answer(query, result, l)),
                      if (!routineMode)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                            child: Text(
                              l.noteCount(visible.length),
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                        ),
                      if (routineMode && groups.isEmpty)
                        const SliverToBoxAdapter(child: SizedBox.shrink())
                      else if (groups.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
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
                                // 기록이 없어도 몸 그림에서 운동을 고를 수 있다.
                                if (_query.text.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: SuggestionChip(
                                      label: l.anatomyPick,
                                      selected: false,
                                      onTap: _openAnatomy,
                                    ),
                                  ),
                                // 치는 동안은 글자로만 찾는다. 0건이면 질문이
                                // 거절된 것처럼 보이니, 물어볼 수 있다고 알린다.
                                if (_unasked(plan))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      l.queryPressEnter,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: CupertinoColors.secondaryLabel
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                      else
                        // 달 제목은 그 달을 지나는 동안 위에 붙어 있다 — 어느 달을
                        // 보는 중인지 늘 보인다. 다음 달이 오면 밀려난다.
                        for (final (title, notes) in groups)
                          SliverMainAxisGroup(
                            slivers: [
                              PinnedHeaderSliver(child: _GroupHeader(title)),
                              // 보이는 줄만 만든다 — 한 해치 200여 줄을 통째로 짓던
                              // 것이 목록을 다시 그릴 때마다의 대부분이었다.
                              SliverList.separated(
                                itemCount: notes.length,
                                itemBuilder: (context, i) => _Row(
                                  key: ValueKey(notes[i].id),
                                  note: notes[i],
                                  query: _query.text.trim(),
                                  onOpen: _open,
                                  onDelete: widget.store.delete,
                                ),
                                separatorBuilder: (context, _) => Padding(
                                  // 구분선은 글자가 시작하는 자리부터 그린다.
                                  padding: const EdgeInsets.only(left: 20),
                                  child: Container(
                                    height: 0.5,
                                    color: CupertinoColors.separator
                                        .resolveFrom(context),
                                  ),
                                ),
                              ),
                            ],
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
              _chip = null;
              _confirmed = null;
              _ask();
            },
            onSubmitted: (_) => _ask(immediately: true),
            // 새 기록 단추도 오늘 기록이 있으면 그것을 연다 — 하루 한 곳.
            onNew: () => _open(widget.store.today()),
          ),
        ],
      ),
    );
  }
}

/// 날짜 묶음 하나. iOS 의 inset grouped 표 한 덩이다.
/// 묶음 제목(이전 7일 · 9월 · 2025년 9월). 붙어 있는 동안 아래 줄을 가리도록
/// 바탕을 칠한다.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Container(
    color: CupertinoColors.systemBackground.resolveFrom(context),
    // 좌우 20 은 목록 줄의 글자 시작과 같다.
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: CupertinoColors.label.resolveFrom(context),
        ),
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
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
                      if (note.meals.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _MealLine(note),
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

/// 목록의 먹은 것 한 줄 — 열량과, 운동한 날이면 무엇을 먹었는지. 끼니만 적은
/// 날은 제목이 이미 먹은 것이라 열량만.
class _MealLine extends StatelessWidget {
  const _MealLine(this.note);
  final Note note;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final unknown = note.unknownMeals;
    final kcal = unknown == note.meals.length
        ? l.mealKcalUnknown
        : [
            l.kcal(note.intake!),
            if (unknown > 0) l.dayUnknownMeals(unknown),
          ].join(' · ');
    return Row(
      children: [
        Text(l.mealsTitle, style: TextStyle(fontSize: 13, color: muted)),
        const SizedBox(width: 6),
        // 행이 버튼이라 색을 적지 않으면 버튼 색(호박)을 물려받는다.
        Text(
          kcal,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        if (note.meals.any((m) => m.approximate)) ...[
          const SizedBox(width: 4),
          const EstimateTag(),
        ],
        if (note.blocks.isNotEmpty) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              note.mealsText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: muted),
            ),
          ),
        ],
      ],
    );
  }
}
