import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'editor.dart';
import 'l10n/generated/app_localizations.dart';
import 'health.dart';
import 'health_summary.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

import 'account.dart';
import 'gym.dart';
import 'gym_sheets.dart';
import 'notes.dart';
import 'palette.dart';
import 'notes_list.dart';
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
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _watchTags();
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
        builder: (_) =>
            EditorPage(store: _store, note: note, account: _account),
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
    final start = note.createdAt;
    final end = note.updatedAt;
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

  /// 로그인과 결제. **없어도 앱은 그대로 돈다** — 켜지 않은 사람은 그냥 쓴다.
  late final _account = Account()..start().then((_) => _sendPendingWorkouts());

  /// 스티커를 댔을 때. 앱이 닫혀 있었어도 열리면서 여기로 온다.
  StreamSubscription<Uri>? _tags;

  /// 태그가 가리킨 체육관의 오늘 루틴을 받아 바로 연다.
  ///
  /// **스티커에 댄 사람은 지금 그 헬스장에 서 있다.** 목록으로 보내 한 번 더
  /// 누르게 하지 않는다 — 손에 폰을 들고 기구 앞에 있는 참이다.
  Future<void> _openTag(Uri uri) async {
    final gymId = gymFromTag(uri);
    if (gymId == null) return;

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
            child: Text(l.tagSignInNeeded, style: const TextStyle(fontSize: 15)),
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
      if (go != true || !await _account.signIn() || !mounted) return;
      // 로그인했으니 댄 것을 그대로 이어서 처리한다. 다시 대라고 하지 않는다.
      if (mounted) await _openTag(uri);
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
  Future<void> _sendPendingWorkouts() =>
      sendPending(_account.link, _store.notes, onSent: _store.touch);

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
    return NotesListPage(store: _store, onOpen: _open, account: _account);
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({
    super.key,
    required this.store,
    required this.note,
    this.account,
  });

  final NotesStore store;
  final Note note;

  /// 설정에서 로그인·결제를 띄우려고 넘어온다.
  final Account? account;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final _editor = RoutineEditorController(
    history: widget.store.exerciseHistory,
    weightUnit: widget.store.weightUnit,
  );
  String? _lastLearned;

  @override
  void initState() {
    super.initState();
    _editor.restore(widget.note.blocks);
    _lastLearned = _editor.recentExercises.firstOrNull;
    _editor.addListener(_persist);
  }

  void _persist() {
    final recent = _editor.recentExercises.firstOrNull;
    if (recent != null && recent != _lastLearned) {
      widget.store.rememberExercise(recent);
      _lastLearned = recent;
    }
    widget.store.update(widget.note, _editor.blocks);
  }

  @override
  void dispose() {
    _editor.removeListener(_persist);
    widget.store.flush();
    _editor.dispose();
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
            // 같이 하기. 로그인한 사람에게만 — 짝을 서버가 들고 있어야 한다.
            if (widget.account?.signedIn ?? false)
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                onPressed: () =>
                    showPartnerSheet(context, widget.account!, widget.note),
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
            child: RoutineEditor(
              countAloud: widget.store.countAloud,
              controller: _editor,
              header: _DocumentHeader(note: widget.note),
              initialDraft: widget.note.draft,
              onDraftChanged: (draft) =>
                  widget.store.updateDraft(widget.note, draft),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentHeader extends StatelessWidget {
  const _DocumentHeader({required this.note});
  final Note note;

  /// 메모 앱의 머리다 — 날짜 한 줄이 가운데에 작게 놓이고 끝이다.
  ///
  /// 예전에는 그 아래에 "오늘 운동" 을 크게 적었다. 날짜 바로 밑에 같은 말을
  /// 한 번 더 쓴 셈이고, 제목은 어차피 첫 운동 이름이 된다(목록이 그것을
  /// 쓴다). 칼로리는 숫자가 있을 때만 나온다 — "기록 없음" 은 정보가 아니다.
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final at = note.createdAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l.dayLabel(at)} · ${l.weekdayLabel(at)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          if (note.calories != null) ...[
            const SizedBox(height: 12),
            HealthSummary(calories: note.calories, showSource: true),
          ],
        ],
      ),
    );
  }
}
