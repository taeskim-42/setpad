import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'editor.dart';
import 'l10n/generated/app_localizations.dart';
import 'health.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

import 'account.dart';
import 'daily.dart';
import 'gym.dart';
import 'gym_sheets.dart';
import 'meal.dart';
import 'meal_amount_sheet.dart';
import 'notes.dart';
import 'palette.dart';
import 'partner.dart';
import 'plans.dart';
import 'plans_page.dart';
import 'nearby.dart';
import 'notes_list.dart';
import 'record_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'set_grid.dart';
import 'settings.dart';

void main() => runApp(const SetpadApp());

class SetpadApp extends StatelessWidget {
  /// [store] 는 테스트가 임시 폴더를 물릴 자리다. 비워 두면 앱 문서 디렉터리를
  /// 쓰는 것을 스스로 만든다 — 그건 플랫폼 채널이라 테스트에서는 못 쓴다.
  const SetpadApp({super.key, this.store, this.tags});

  final NotesStore? store;

  /// 스티커가 가리킨 주소가 오는 자리. **테스트는 비워 둔다** — 그 자리에는
  /// 읽을 태그가 없고, 네이티브 채널을 깨우면 없는 플러그인을 부른다.
  final Stream<Uri>? tags;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Setpad',
      debugShowCheckedModeBanner: false,
      // 지원 언어를 하나 더하거나 뺄 때 여기를 같이 고칠 일이 없도록
      // 생성된 목록을 그대로 쓴다. arb 파일이 곧 지원 언어 목록이다.
      supportedLocales: L.supportedLocales,
      localizationsDelegates: L.localizationsDelegates,
      // 기기는 zh-TW / zh-HK 처럼 **문자 체계 없이** 보낸다. 그대로 두면
      // 번체에 못 붙고 기본 zh(간체)로 떨어져 대만 사용자가 간체를 본다.
      // 나라 코드를 보고 문자 체계를 채운 뒤 평소 규칙에 넘긴다.
      localeListResolutionCallback: (locales, supported) =>
          basicLocaleListResolution([
            for (final l in locales ?? const <Locale>[])
              if (l.languageCode == 'zh' && l.scriptCode == null)
                Locale.fromSubtags(
                  languageCode: 'zh',
                  scriptCode: const ['TW', 'HK', 'MO'].contains(l.countryCode)
                      ? 'Hant'
                      : 'Hans',
                  countryCode: l.countryCode,
                )
              else
                l,
          ], supported),
      // 기본 서체를 monospace 로 못 박지 않는다. 숫자가 줄 서는 자리에만
      // 붙이면 되고, 화면 전체를 고정폭으로 두면 한글이 성기게 벌어져 iOS
      // 앱처럼 안 보인다. 나머지는 시스템 서체(SF Pro / Apple SD Gothic Neo)를
      // 그대로 쓴다.
      theme: const CupertinoThemeData(
        primaryColor: seal,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      home: _Home(store: store, tags: tags),
    );
  }
}

/// 앱이 켜지는 자리.
///
/// **목록이 아니라 패드로 연다.** 헬스장에서 앱을 여는 이유는 세트를 하나
/// 적으려는 것이지 지난 기록을 넘겨보려는 것이 아니다. 그래서 오늘 것이 있으면
/// 그것을, 없으면 새 기록을 곧바로 펴고, 목록은 뒤로가기 한 번 뒤에 둔다.
class _Home extends StatefulWidget {
  const _Home({this.store, this.tags});
  final Stream<Uri>? tags;

  final NotesStore? store;

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> with WidgetsBindingObserver {
  late final NotesStore _store = widget.store ?? NotesStore();
  final _health = HealthLink();

  /// 서버에 묻는 쪽. 기기 id 는 store 가 처음 켤 때 만들므로 그 뒤에 읽는다.
  RecordAi get _ai => RecordAi(deviceId: _store.deviceId);
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _watchTags();
    _nearbyPlans = Nearby.instance.received
        .where((invite) => invite.kind == 'plan')
        .listen((invite) => _openPlans(joinToken: invite.token));
    // 심박이 올 때마다 남긴다. HealthKit 이 실제로 얼마나 자주 깨워 주는지를
    // 재는 것이 지금 목적이다 — 그 값에 따라 휴식 타이머가 성립하는지가
    // 갈린다. 문서로 확인하지 못한 빈도 제한을 실측으로 대신한다.
    _health.onBeat(({required bpm, required lag, sinceLastWake}) {
      debugPrint(
        '[심박] ${bpm}bpm · 지연 ${lag.inSeconds}초'
        '${sinceLastWake == null ? ' · 첫 신호' : ' · 직전 신호와 ${sinceLastWake.inSeconds}초 간격'}',
      );
    });
    _boot();
  }

  Future<void> _boot() async {
    await _store.load();
    if (!mounted) return;
    setState(() => _ready = true);
    // 첫 프레임이 그려진 뒤에 밀어 넣어야 목록이 뒤에 남는다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _open(_todayOrNew()));
  }

  /// 오늘 고친 메모가 있으면 이어 쓴다. 하루에 앱을 여러 번 여는 흐름에서
  /// 열 때마다 새 기록이 쌓이면 목록이 못 쓰게 된다.
  Note _todayOrNew() {
    final now = DateTime.now();
    for (final n in _store.notes) {
      final d = n.updatedAt;
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        return n;
      }
    }
    return _store.create();
  }

  Future<void> _open(Note note) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => EditorPage(
          store: _store,
          note: note,
          account: _account,
          onPlanNext: _proposePlan,
        ),
      ),
    );
    // 아무것도 안 치고 나온 새 기록은 남기지 않는다.
    _store.discardIfEmpty(note);
    unawaited(_syncHealth(note));
  }

  /// 편집을 마치고 나올 때 건강 앱과 맞춘다.
  ///
  /// 기다리지 않는다 — 권한 창이 뜨든 안 뜨든 목록은 이미 보여야 한다.
  /// 실패해도 조용하다. 연동은 덤이지 기록의 전제가 아니다.
  Future<void> _syncHealth(Note note) async {
    final sets = note.blocks.expand((b) => b.sets).where((s) => s.done);
    if (sets.isEmpty) return;
    // 시작과 끝. 세트마다 시각을 남기지 않으므로 노트가 만들어진 때와 마지막에
    // 고친 때로 잡는다. 실제로 그 사이에 운동을 한 것이 맞다.
    // 다른 문서가 이미 잰 구간은 빼고, 나중에 고친 시각까지 늘어나지 않게 자른다
    // — 같은 활동 에너지를 두 번 더하거나 하루치를 운동 칼로리라 부르지 않으려고.
    final start = sessionStart(note, _store.notes);
    final end = sessionEnd(note);
    if (!end.isAfter(start)) return;

    if (!await _health.authorize()) return;
    // 관찰은 한 번만 걸면 계속 산다.
    unawaited(_health.watchHeartRate());

    // 심박이 얼마나 늦게 도착하는지 남긴다. 심박으로 휴식을 끊어 주는 기능을
    // 만들지 말지가 이 값에 달려 있다 — 몇 초면 되고 몇 분이면 못 한다.
    final hr = await _health.latestHeartRate();
    debugPrint(
      hr == null
          ? '[심박] 최근 30분에 잰 것이 없다'
          : '[심박] ${hr.bpm}bpm · 잰 시각 ${hr.at} · 지연 ${hr.lag.inSeconds}초',
    );

    final kcal = await _health.activeEnergy(start, end);
    await _health.writeWorkout(
      start: start,
      end: end,
      title: note.title,
      energyBurned: kcal,
    );
    if (kcal != null && mounted) {
      note.calories = kcal;
      _store.touch();
    }
  }

  /// 공동 루틴. 서버가 안 닿아도 이 기기에 저장된 계획은 열린다.
  late final _plans = PlanStore(link: () => _account.link)..load();

  void _openPlans({SharedPlan? open, String? joinToken}) =>
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => PlansPage(
            plans: _plans,
            account: _account,
            notes: _store,
            open: open,
            joinToken: joinToken,
            // 계획에서 시작한 운동은 평소의 운동 문서다.
            onOpenNote: (note) => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => EditorPage(
                  store: _store,
                  note: note,
                  account: _account,
                  ai: _ai,
                  onPlanNext: _proposePlan,
                ),
              ),
            ),
          ),
        ),
      );

  /// 운동 기록에서 "공동 루틴으로 제안". 기록 위에 그 루틴 화면이 바로 뜬다 —
  /// 고치고, 초대하고, 같은 버전에 동의하는 일이 전부 거기서 이어지고, 뒤로
  /// 가면 하던 기록이다. 로그인 전이면 로그인 안내가 있는 목록을 거친다.
  void _proposePlan(SharedPlan fromRecord) {
    // 목록에 들여 둔다. 그래야 초대하기 전에 뒤로 가도 초안이 남는다.
    final draft = _plans.adopt(fromRecord);
    if (!_account.signedIn) return _openPlans(open: draft);
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => PlanPage(
          plan: draft,
          plans: _plans,
          notes: _store,
          onOpenNote: (note) => Navigator.of(context).push(
            CupertinoPageRoute<void>(
              builder: (_) => EditorPage(
                store: _store,
                note: note,
                account: _account,
                ai: _ai,
                onPlanNext: _proposePlan,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 로그인과 결제. **없어도 앱은 그대로 돈다** — 켜지 않은 사람은 그냥 쓴다.
  late final _account = Account()..start().then((_) => _sendPendingWorkouts());

  /// 스티커를 댔을 때. 앱이 닫혀 있었어도 열리면서 여기로 온다.
  StreamSubscription<Uri>? _tags;

  /// 태그가 가리킨 체육관의 오늘 루틴을 받아 바로 연다.
  ///
  /// **스티커에 댄 사람은 지금 그 헬스장에 서 있다.** 목록으로 보내 한 번 더
  /// 누르게 하지 않는다 — 손에 폰을 들고 기구 앞에 있는 참이다.
  /// 지금 처리 중인 태그. **한 번 댄 것을 두 번 처리하지 않는다** —
  /// app_links 는 앱을 연 주소를 스트림으로도 주고 getInitialLink 로도 줘서
  /// 같은 태그가 두 번 들어온다. 안내창이 두 개 겹쳐 뜨던 이유다.
  String? _handling;

  String? _lastPlanToken;
  StreamSubscription<({String kind, String token})>? _nearbyPlans;

  Future<void> _openTag(Uri uri) async {
    // 공동 루틴 초대 링크. 공동 루틴 화면이 로그인과 참여를 이어서 처리한다.
    final planToken = planTokenFromLink(uri);
    if (planToken != null) {
      // 같은 링크가 두 번 전달되는 일이 있다(처음 링크 + 스트림).
      if (planToken == _lastPlanToken) return;
      _lastPlanToken = planToken;
      _openPlans(joinToken: planToken);
      return;
    }
    final gymId = gymFromTag(uri);
    if (gymId == null) return;
    if (_handling == gymId) return;
    _handling = gymId;
    try {
      await _handleTag(uri, gymId);
    } finally {
      _handling = null;
    }
  }

  Future<void> _handleTag(Uri uri, String gymId) async {
    // **여기서 로그인까지 끝낸다.** 안내만 하고 웹으로 보내면 거기서 또
    // 로그인 수단을 고르게 되고, 웹의 카카오와 앱의 Apple 은 서로 다른
    // 사람이 된다. 기기가 쓰는 수단 하나로 여기서 들어오고 이어서 진행한다.
    if (!_account.signedIn) {
      final l = L.of(context);
      final go = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l.tagSignInNeeded,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.tagSignIn),
            ),
          ],
        ),
      );
      if (go != true) return;
      final ok = await _account.signIn();
      if (!mounted) return;
      if (!ok) {
        // 사람이 스스로 닫은 것은 말할 것이 없다. 서버가 막은 것만 말한다.
        if (_account.signInRefused) await _tellTag(L.of(context).signInFailed);
        return;
      }
      // 로그인했으니 댄 것을 그대로 이어서 처리한다. 다시 대라고 하지 않는다.
      await _handleTag(uri, gymId);
      return;
    }

    final routines = await _account.link.routines();
    if (!mounted) return;
    final mine = routines.where((r) => r.gymId == gymId).firstOrNull;
    if (mine == null) {
      // 그 체육관에 다니지 않는 것과, 다니는데 오늘 받은 것이 없는 것은
      // 해야 할 일이 다르다. 둘 다 **안내가 아니라 행동으로 끝난다** — 말만
      // 하고 멈추면 회원이 될 길도, 출석이 남을 길도 앱 안에 없다.
      final member = _account.gyms.any((g) => g.id == gymId);
      await (member ? _attendOnly(gymId) : _askJoin(gymId));
      return;
    }
    _open(
      _store.create(blocks: mine.blocks, gymId: mine.gymId, routineId: mine.id),
    );
  }

  /// 회원이 아닌 사람. **댄 것이 곧 신청이다** — 한 번 더 누르게 하지 않는다.
  /// 트레이너 화면에 바로 뜨고, 확인하면 회원이 된다.
  Future<void> _askJoin(String gymId) async {
    final state = await _account.link.requestJoin(gymId);
    if (!mounted) return;
    if (state == JoinState.member) {
      // 방금 트레이너가 확인해 준 참이다. 안내 대신 하러 온 일을 시작한다.
      await _account.refreshGyms();
      if (mounted) await _attendOnly(gymId);
      return;
    }
    await _tellTag(switch (state) {
      JoinState.requested => L.of(context).tagJoinSent,
      JoinState.waiting => L.of(context).tagJoinWaiting,
      _ => L.of(context).tagJoinFailed,
    });
  }

  /// 루틴이 없는 날. **온 것은 온 것이다** — 빈 기록 하나가 곧 출석이고,
  /// 이것이 없으면 트레이너의 오늘 화면에 이 사람이 영영 안 뜬다.
  ///
  /// 같은 날 두 번 대도 한 번이다. 웹이 세 시간 안의 기록을 다시 여는 것과
  /// 같은 규칙을 쓴다 — 폰이 잠겼다 돌아온 것을 두 번째 방문으로 세지 않는다.
  Future<void> _attendOnly(String gymId) async {
    final since = DateTime.now().subtract(const Duration(hours: 3));
    final open = _store.notes
        .where((n) => n.gymId == gymId && n.createdAt.isAfter(since))
        .firstOrNull;
    final note = open ?? _store.create(gymId: gymId);
    if (open == null) unawaited(_sendPendingWorkouts());
    if (mounted) _open(note);
  }

  Future<void> _tellTag(String message) => showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message, style: const TextStyle(fontSize: 15)),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(L.of(ctx).ok),
        ),
      ],
    ),
  );

  /// 체육관에서 시작한 기록 중 아직 못 보낸 것을 보낸다.
  /// 헬스장은 신호가 나빠 한 번에 못 갈 때가 있다.
  /// 밀린 끼니 변경(확정·수정·삭제)도 같은 기회에 같이 간다.
  Future<void> _sendPendingWorkouts() async {
    await sendPending(_account.link, _store.notes, onSent: _store.touch);
    await syncMeals(_account.link, _store.notes, onSynced: _store.touch);
  }

  /// 앱이 닫혀 있다 열린 경우와, 떠 있는데 댄 경우를 한 줄기로 받는다.
  void _watchTags() {
    final given = widget.tags;
    if (given != null) {
      _tags = given.listen(_openTag);
      return;
    }
    // 웹에는 스티커를 읽을 것이 없다. 채널을 깨우지 않는다.
    if (kIsWeb) return;
    final links = AppLinks();
    _tags = links.uriLinkStream.listen(_openTag, onError: (Object _) {});
    unawaited(
      links
          .getInitialLink()
          .then((uri) {
            if (uri != null) _openTag(uri);
          })
          .catchError((Object _) {}),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 내려갈 때는 디바운스를 기다리지 않는다.
    if (state != AppLifecycleState.resumed) {
      _store.flush();
    } else {
      // 돌아왔다. 그동안 신호가 잡혔을 수 있다.
      unawaited(_sendPendingWorkouts());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tags?.cancel();
    _nearbyPlans?.cancel();
    _account.dispose();
    _store.flush();
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const CupertinoPageScaffold(child: SizedBox.shrink());
    }
    return NotesListPage(
      store: _store,
      onOpen: _open,
      onPlans: () => _openPlans(),
      account: _account,
      ai: _ai,
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({
    super.key,
    required this.store,
    required this.note,
    this.account,
    this.ai = const RecordAi(),
    this.onPlanNext,
  });

  final NotesStore store;
  final Note note;

  /// 이 기록으로 다음 운동을 함께 계획한다. 초안을 받아 공동 루틴 화면을 연다.
  final void Function(SharedPlan draft)? onPlanNext;

  /// 문장 해석과 식단 사진이 같은 문을 쓴다.
  final RecordAi ai;

  /// 설정에서 로그인·결제를 띄우려고 넘어온다.
  final Account? account;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> with WidgetsBindingObserver {
  /// 같이 하기. 로그인·결제 계정이 있을 때만 있다.
  late final PartnerSync? _partner = widget.account == null
      ? null
      : PartnerSync(
          note: widget.note,
          link: () => widget.account!.link,
          onChanged: widget.store.touch,
        );

  StreamSubscription<({String kind, String token})>? _nearbyInvites;

  /// 화면이 보이는 동안만 상대의 변경을 확인한다. 백그라운드에서는 멈추고,
  /// 돌아오면 바로 최신 상태를 다시 묻는다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _partner?.start();
    } else {
      _partner?.stop();
    }
  }

  final _documentHeaderKey = GlobalKey<_DocumentHeaderState>();
  late final _editor = RoutineEditorController(
    history: widget.store.exerciseHistory,
    weightUnit: widget.store.weightUnit,
  );
  String? _lastLearned;
  final _mealText = ValueNotifier<({String text, int? index})?>(null);

  /// 같은 날 만든 다른 기록들. 하루에 문서가 여럿일 수 있다 — 오전에 한 장,
  /// 저녁에 한 장. 합치거나 베끼지 않고 이 문서 아래에 읽기 전용으로 보여 준다.
  List<Note> get _sameDay {
    final at = widget.note.createdAt;
    return [
      for (final n in widget.store.notes)
        if (n != widget.note &&
            n.blocks.isNotEmpty &&
            n.createdAt.year == at.year &&
            n.createdAt.month == at.month &&
            n.createdAt.day == at.day)
          n,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// 글로 적은 한 끼를 저장한다. 묻지 않는다 — 모르는 음식도, 양이 없는 글도
  /// 친 그대로 남고, 열량은 사람이 적었을 때만 있다. 고치다 다 지우면 그
  /// 끼니가 없어진다.
  void _saveMealText(String text, int? index) {
    final meals = widget.note.meals;
    final old = index != null && index < meals.length ? meals[index] : null;
    if (text.isEmpty) {
      if (old != null) widget.note.removeMeal(old);
    } else {
      final parsed = parseMealText(text);
      final entry = MealEntry(
        id: old?.id, // 고친 끼니는 서버의 같은 줄이다.
        at: old?.at ?? DateTime.now(),
        kcal: parsed.kcal,
        text: text,
        source: parsed.kcal == null ? null : MealEntry.typed,
        foods: parsed.foods,
      );
      old == null ? meals.add(entry) : meals[index!] = entry;
      if (parsed.kcal == null) _estimateMealText(entry);
    }
    _mealsChanged();
  }

  /// 끼니가 바뀌었다. 먼저 이 기기에 쓰고, 그다음 서버의 같은 줄에 맞춘다 —
  /// 그물이 없으면 밀려 있다가 다음에 간다.
  void _mealsChanged() {
    widget.store.touch();
    final link = widget.account?.link;
    if (link == null || widget.note.gymId == null) return;
    syncMeals(link, [widget.note], onSynced: widget.store.touch);
  }

  /// 원문은 이미 저장됐다. 열량을 안 적은 끼니에 어림값을 붙여 볼 뿐이고,
  /// 못 붙이면 미상으로 남는다. 그사이 사람이 고쳤거나 지웠으면 손대지 않는다.
  Future<void> _estimateMealText(MealEntry entry) async {
    if (!widget.ai.supported) return;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final MealEstimate estimate;
    try {
      estimate = await widget.ai.estimateMealText(entry.text!, locale: locale);
    } catch (_) {
      return;
    }
    final at = widget.note.meals.indexOf(entry);
    if (at < 0) return;
    widget.note.meals[at] = MealEntry(
      id: entry.id,
      at: entry.at,
      kcal: estimate.kcal,
      items: estimate.items,
      text: entry.text,
      source: MealEntry.estimate,
      foods: entry.foods,
    );
    _mealsChanged();
  }

  @override
  void initState() {
    super.initState();
    _editor.restore(widget.note.blocks);
    _lastLearned = _editor.recentExercises.firstOrNull;
    _editor.addListener(_persist);
    WidgetsBinding.instance.addObserver(this);
    _partner?.addListener(_partnerChanged);
    // 가까이 댄 상대가 건넨 같이 하기 초대. 코드를 친 것과 같은 길로 참여한다 —
    // 같은 토큰이 여러 번 와도 참여는 한 번이다(PartnerSync.joinWithToken).
    _nearbyInvites = Nearby.instance.received
        .where((invite) => invite.kind == 'session')
        .listen((invite) => _partner?.joinWithToken(invite.token));
    // 다시 들어왔을 때 서버에 상태를 물어 복구한다(열린 세션이 있을 때만 돈다).
    if (widget.note.partner?.open ?? false) _partner?.start();
  }

  /// 이 기록의 종목·세트 수와 내가 마지막에 한 무게·횟수로 새 초안을 뜬다.
  /// 완료 표시는 따라가지 않고, 이 기록은 바뀌지 않는다.
  VoidCallback? get _planNext =>
      widget.onPlanNext == null || widget.note.blocks.isEmpty
      ? null
      : () => widget.onPlanNext!(
          planFromBlocks(widget.note.title ?? '', widget.note.blocks),
        );

  void _partnerChanged() {
    if (!mounted) return;
    // 세션이 열리면 돌고, 끝나면 멈춘다.
    (widget.note.partner?.open ?? false) ? _partner!.start() : _partner!.stop();
    setState(() {});
  }

  void _persist() {
    final recent = _editor.recentExercises.firstOrNull;
    if (recent != _lastLearned && recent != null) {
      widget.store.rememberExercise(recent);
    }
    _lastLearned = recent;
    widget.store.update(widget.note, _editor.blocks);
    // 내 기록은 방금 이 기기에 저장됐다. 그다음에 상대에게 보낸다.
    _partner?.recordChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nearbyInvites?.cancel();
    _partner?.removeListener(_partnerChanged);
    _partner?.dispose();
    _editor.removeListener(_persist);
    widget.store.flush();
    _editor.dispose();
    _mealText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return CupertinoPageScaffold(
      // One shared keyboard area is managed by the editor.
      resizeToAvoidBottomInset: false,
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        border: null,
        previousPageTitle: l.allNotes,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 같이 하기. 로그인하지 않았으면 창 안에서 로그인으로 이어진다 —
            // 버튼이 아예 없으면 기능이 있는 줄도 모른다.
            if (_partner != null)
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                onPressed: () =>
                    showPartnerSheet(context, widget.account!, _partner),
                child: Icon(
                  CupertinoIcons.person_2,
                  size: 20,
                  semanticLabel: l.partnerInvite,
                ),
              ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onPressed: () async {
                await showWeightSettings(
                  context,
                  widget.store,
                  account: widget.account,
                );
                if (mounted) {
                  setState(() => _editor.weightUnit = widget.store.weightUnit);
                }
              },
              child: const Icon(CupertinoIcons.gear, size: 21),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l.doneEditing,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        // The keypad owns the bottom safe area, including during IME transitions.
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // 같이 운동 중이면 상대 이름과 상태를 작게. 누르면 상대 기록이 나온다.
                if (widget.note.partner?.state == PartnerState.active)
                  GestureDetector(
                    key: const ValueKey('partner-banner'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        showPartnerSheet(context, widget.account!, _partner),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.person_2_fill,
                            size: 14,
                            color: seal.resolveFrom(context),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _partner!.reachable
                                  ? l.partnerWith(
                                      widget.note.partner!.partnerName ?? '',
                                    )
                                  : l.partnerReconnecting,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: RoutineEditor(
                    countAloud: widget.store.countAloud,
                    controller: _editor,
                    partner: _partner,
                    ai: widget.ai,
                    header: _DocumentHeader(
                      key: _documentHeaderKey,
                      note: widget.note,
                      store: widget.store,
                      ai: widget.ai,
                      mealText: _mealText,
                      onMealsChanged: _mealsChanged,
                      onProposePlan: _planNext,
                      onFitAll: () => showFitAll(context, [
                        (
                          caption: DateFormat.jm(
                            l.localeName,
                          ).format(widget.note.createdAt),
                          blocks: _editor.blocks,
                        ),
                        for (final n in _sameDay)
                          (
                            caption: DateFormat.jm(
                              l.localeName,
                            ).format(n.createdAt),
                            blocks: n.blocks,
                          ),
                      ]),
                    ),
                    footer: _sameDay.isEmpty ? null : _SameDay(notes: _sameDay),
                    mealText: _mealText,
                    onMealText: _saveMealText,
                    recentMeals: <String>{
                      for (final n in widget.store.notes)
                        for (final m in n.meals.reversed) ?m.text,
                    }.take(24).toList(),
                    initialDraft: widget.note.draft,
                    onDraftChanged: (draft) =>
                        widget.store.updateDraft(widget.note, draft),
                    onForgetExercise: widget.store.forgetExercise,
                    onMealPhoto: () => _documentHeaderKey.currentState?._pick(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentHeader extends StatefulWidget {
  const _DocumentHeader({
    super.key,
    required this.note,
    required this.store,
    required this.ai,
    this.mealText,
    this.onProposePlan,
    this.onFitAll,
    this.onMealsChanged,
  });
  final Note note;
  final NotesStore store;
  final RecordAi ai;

  /// 식단 글은 아래 입력 줄에서 친다. 여기서는 그 모드를 켜기만 한다.
  final ValueNotifier<({String text, int? index})?>? mealText;

  /// 이 기록을 공동 루틴으로 제안한다. 적은 것이 없으면 null 이다.
  final VoidCallback? onProposePlan;
  final VoidCallback? onFitAll;

  /// 끼니를 더하거나 고치거나 지웠다. 저장과 서버 맞춤은 문서 쪽이 한다.
  final VoidCallback? onMealsChanged;

  @override
  State<_DocumentHeader> createState() => _DocumentHeaderState();
}

/// 메모 앱의 머리다 — 날짜 한 줄이 가운데에 작게 놓이고 끝이다.
///
/// 예전에는 그 아래에 "오늘 운동" 을 크게 적었다. 날짜 바로 밑에 같은 말을
/// 한 번 더 쓴 셈이고, 제목은 어차피 첫 운동 이름이 된다(목록이 그것을
/// 쓴다). 칼로리는 숫자가 있을 때만 나온다 — "기록 없음" 은 정보가 아니다.
///
/// 식단은 사진 한 장으로 어림한다. 운동으로 쓴 것과 먹은 것을 같은 줄에
/// 두면 "오늘 얼마나 남았나" 가 한눈에 읽힌다. 숫자는 어림이라고 적는다.
class _DocumentHeaderState extends State<_DocumentHeader> {
  bool _estimating = false;
  String? _error;

  Note get note => widget.note;

  // 식단은 아래 입력 줄에서도 저장된다. 저장소가 바뀌면 다시 그린다.
  void _onStore() => setState(() {});

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    super.dispose();
  }

  Future<void> _addMeal(ImageSource source) async {
    final l = L.of(context);
    final XFile? file;
    try {
      // 1024px 이면 접시가 충분히 보이고, 보내는 양은 수백 KB 다.
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
    } catch (_) {
      if (mounted) setState(() => _error = l.mealFailed);
      return;
    }
    if (file == null || !mounted) return;
    final locale = Localizations.localeOf(context).toLanguageTag();
    setState(() {
      _estimating = true;
      _error = null;
    });
    try {
      final bytes = await file.readAsBytes();
      final hour = DateTime.now().hour;
      final estimate = await widget.ai.estimateMeal(
        bytes,
        mime: file.mimeType ?? 'image/jpeg',
        locale: locale,
        gymId: note.gymId,
        kind: hour < 10
            ? 'breakfast'
            : hour < 15
            ? 'lunch'
            : hour < 21
            ? 'dinner'
            : 'snack',
      );
      final label = estimate.label;
      if (label != null) {
        // 성분표는 인쇄된 숫자다. 얼마나 먹었는지만 받아 계산한다. 취소하면
        // 아무것도 남기지 않는다 — 다시 찍어도 끼니가 둘이 되지 않는다.
        if (!mounted) return;
        setState(() => _estimating = false);
        final picked = await askMealAmount(
          context,
          bases: basesOf(label),
          title: label.product,
        );
        if (picked == null || !mounted) return;
        note.meals.add(_measured(picked, MealEntry.label, label.product));
      } else {
        // 사진 어림은 **보이는 음식 전체**의 값이다. 묻지 않고 전체로 남기고,
        // 덜 먹었으면 그 줄을 눌러 고친다 — 매번 창을 띄우지 않는다.
        note.meals.add(
          MealEntry(
            at: DateTime.now(),
            kcal: estimate.kcal,
            items: estimate.items,
            source: MealEntry.estimate,
            basis: MealBasis(
              kcal: estimate.kcal.toDouble(),
              amount: 1,
              unit: MealBasis.photo,
            ),
            eaten: 1,
          ),
        );
      }
      _changed();
    } on RecordAiException {
      _error = l.mealFailed;
    } catch (_) {
      _error = l.mealFailed;
    }
    if (mounted) setState(() => _estimating = false);
  }

  /// 근거와 먹은 양으로 한 끼를 만든다. 열량은 여기서 한 번만 반올림된다.
  void _changed() => (widget.onMealsChanged ?? widget.store.touch)();

  MealEntry _measured(
    ({MealBasis basis, double eaten}) picked,
    String source,
    String? name, {
    MealEntry? old,
  }) => MealEntry(
    id: old?.id, // 양을 고친 끼니는 서버의 같은 줄이다.
    at: old?.at ?? DateTime.now(),
    kcal: picked.basis.kcalFor(picked.eaten),
    items: old != null && old.basis?.unit == MealBasis.photo
        ? old.items
        : [?name],
    source: source,
    basis: picked.basis,
    eaten: picked.eaten,
  );

  /// 끼니 한 줄을 눌렀다. 글로 적은 것은 입력 줄로 불러 고치고, 근거가 있는
  /// 것은 먹은 양을 다시 받는다. 저장된 열량에 또 곱하지 않는다 — 근거에서
  /// 다시 계산해 **그 자리를** 바꾼다.
  Future<void> _editMeal(int index) async {
    final meal = note.meals[index];
    if (meal.text != null) {
      widget.mealText?.value = (text: meal.text!, index: index);
      return;
    }
    final basis = meal.basis;
    if (basis == null) return; // 예전 기록 — 다시 계산할 근거가 없다.
    final photo = basis.unit == MealBasis.photo;
    final picked = await askMealAmount(
      context,
      bases: [basis],
      title: meal.items.isEmpty ? null : meal.items.join(', '),
      note: photo ? L.of(context).mealPhotoWholeNote : null,
      initialBasis: basis,
      initialEaten: meal.eaten,
    );
    if (picked == null || !mounted || index >= note.meals.length) return;
    note.meals[index] = _measured(
      picked,
      meal.source ?? MealEntry.estimate,
      meal.items.firstOrNull,
      old: meal,
    );
    _changed();
    setState(() {});
  }

  void _pick() {
    final l = L.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l.mealPhoto),
        message: Text(l.mealEstimateNote),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _addMeal(ImageSource.camera);
            },
            child: Text(l.mealCamera),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _addMeal(ImageSource.gallery);
            },
            child: Text(l.mealGallery),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final at = note.createdAt;
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    // 하루치다 — 이 문서 하나가 아니라 그날의 문서와 끼니 전부.
    final log = dayLogs(widget.store.notes, from: at, to: at).firstOrNull;
    final energy = log == null ? null : dayEnergyText(l, log);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l.dayLabel(at)} · ${l.weekdayLabel(at)}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: muted),
          ),
          // 섭취 · 운동 · 차이를 작은 한 줄로.
          if (energy != null)
            Padding(
              key: const ValueKey('day-summary'),
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                energy,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
          if (note.meals.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final (i, meal) in note.meals.indexed)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      key: ValueKey('meal-$i'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _editMeal(i),
                      child: Text(
                        [
                          meal.kcal == null
                              ? l.mealKcalUnknown
                              : meal.approximate
                              ? l.kcalApprox(meal.kcal!)
                              : l.kcal(meal.kcal!),
                          meal.text ?? meal.items.join(', '),
                          if (meal.basis != null &&
                              meal.eaten != null &&
                              !(meal.basis!.unit == MealBasis.photo &&
                                  meal.eaten == 1))
                            mealEatenText(l, meal.basis!, meal.eaten!),
                        ].where((t) => t.isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(32, 32),
                    onPressed: () {
                      note.removeMeal(meal);
                      _changed();
                      setState(() {});
                    },
                    child: Icon(CupertinoIcons.xmark, size: 14, color: muted),
                  ),
                ],
              ),
          ],
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(fontSize: 13, color: seal.resolveFrom(context)),
            ),
          Row(
            children: [
              // 식단 사진·글 버튼은 여기 없다. 입력 줄 위의 막대에 같은 것이 늘 있어서
              // 화면 맨 위에 또 둘 이유가 없었다. 사진을 읽는 동안이라는 것만 알린다.
              if (_estimating)
                Text(
                  l.mealEstimating,
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              // 같이 하기 창 안에 숨어 있던 것을 기록 화면으로 꺼냈다. 기록을 보다가
              // "이걸로 같이 하자" 가 떠오르는 자리가 여기다. 남는 폭을 다 쓰고,
              // 말이 긴 언어에서는 넘치지 않고 줄인다.
              Expanded(
                child: widget.onProposePlan == null
                    ? const SizedBox.shrink()
                    : LayoutBuilder(
                        builder: (context, box) {
                          const style = TextStyle(fontSize: 14);
                          final words = TextPainter(
                            text: TextSpan(
                              text: l.planPropose,
                              style: DefaultTextStyle.of(
                                context,
                              ).style.merge(style),
                            ),
                            textDirection: Directionality.of(context),
                            maxLines: 1,
                          )..layout();
                          // 말이 다 들어갈 때만 적는다. 잘린 말보다 아이콘이 낫다.
                          final roomy =
                              words.width + 16 + 6 + 16 <= box.maxWidth;
                          words.dispose();
                          return Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: CupertinoButton(
                              key: const ValueKey('propose-plan'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: const Size(44, 36),
                              onPressed: widget.onProposePlan,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.person_2,
                                    size: 16,
                                    semanticLabel: l.planPropose,
                                  ),
                                  if (roomy) ...[
                                    const SizedBox(width: 6),
                                    Text(l.planPropose, style: style),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (widget.onFitAll != null && note.blocks.isNotEmpty)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 36),
                  onPressed: widget.onFitAll,
                  child: Icon(
                    CupertinoIcons.arrow_up_left_arrow_down_right,
                    size: 16,
                    semanticLabel: l.fitAll,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 같은 날의 다른 기록 — 읽기 전용이다. 원본은 제 문서에 그대로 있고 여기서는
/// 보여 주기만 한다. 고치려면 그 문서를 연다.
class _SameDay extends StatelessWidget {
  const _SameDay({required this.notes});
  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final n in notes) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${l.sameDayOther} · ${DateFormat.jm(l.localeName).format(n.createdAt)}',
                style: TextStyle(fontSize: 13, color: muted),
              ),
            ),
            for (final b in n.blocks) BlockSummary(block: b),
          ],
        ],
      ),
    );
  }
}
