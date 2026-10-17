import 'dart:async';
import 'app_locale.dart';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

import 'body.dart';
import 'day_energy.dart';
import 'editor.dart';
import 'milestones.dart';
import 'unfold.dart';
import 'body_page.dart';
import 'l10n/generated/app_localizations.dart';
import 'health.dart';
import 'health_page.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

import 'account.dart';
import 'api_route.dart' show releaseIdleConnections, updateRequired;
import 'sign_in.dart';
import 'sign_in_sheet.dart';
import 'agent_alarm.dart';
import 'daily.dart';
import 'gym.dart';
import 'booking_entry.dart';
import 'gym_page.dart'
    show ClassesPage, askGymConsent, newsText, openGym, unseenNews;
import 'gym_sheets.dart';
import 'handoff.dart';
import 'meal.dart';
import 'meal_amount_sheet.dart';
import 'meal_review_sheet.dart';
import 'anatomy_page.dart' show registerArtworkLicense;
import 'notes.dart';
import 'metrics.dart';
import 'palette.dart';
import 'partner.dart';
import 'nearby.dart';
import 'notes_list.dart';
import 'record_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'set_grid.dart';
import 'settings.dart';
import 'share.dart';
import 'trainer.dart';

void main() {
  registerArtworkLicense();
  runApp(const SetpadApp());
  // 트레이너 보고 알림. 알림을 눌러 켜졌으면 그 탭을 여기서 받아 두었다가
  // AgentAlarm.taps 로 넘긴다. 테스트는 main 을 부르지 않으니 채널도 안 깬다.
  unawaited(AgentAlarm.init());
}

/// 보고 알림 탭. AgentAlarm.taps 는 한 번만 들을 수 있는 스트림이라 여기서 한 번
/// 붙이고 나눠 듣는다 — 홈이 다시 만들어져도(테스트가 앱을 여러 번 띄운다)
/// 두 번 붙다가 깨지지 않는다. 처음 붙을 때 쌓여 있던 콜드 스타트 탭이 온다.
final _reportTaps = AgentAlarm.taps.asBroadcastStream();

/// 앱 테마. 채운 단추의 글자색은 테마(흰색)에 두고, 켜진 단추만 [sealButton] 이
/// [sealOn] 으로 바꾼다 — Flutter 는 꺼진 채운 단추에도 primaryContrastingColor 를
/// 쓰므로 여기서 바꾸면 어두운 모드의 회색 꺼진 단추 위 글자가 사라진다.
const setpadTheme = CupertinoThemeData(
  primaryColor: seal,
  scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
);

class SetpadApp extends StatelessWidget {
  /// [store] 는 테스트가 임시 폴더를 물릴 자리다. 비워 두면 앱 문서 디렉터리를
  /// 쓰는 것을 스스로 만든다 — 그건 플랫폼 채널이라 테스트에서는 못 쓴다.
  const SetpadApp({
    super.key,
    this.store,
    this.tags,
    this.firstTag,
    this.account,
  });

  final NotesStore? store;

  /// 테스트가 가짜 서버를 물린 계정을 끼울 자리. 비워 두면 스스로 만든다.
  final Account? account;

  /// 스티커가 가리킨 주소가 오는 자리. **테스트는 비워 둔다** — 그 자리에는
  /// 읽을 태그가 없고, 네이티브 채널을 깨우면 없는 플러그인을 부른다.
  final Stream<Uri>? tags;

  /// 앱을 연 주소(콜드 스타트) — [tags] 를 준 테스트가 함께 주는 자리. 앱은
  /// getInitialLink 로 받는다.
  final Future<Uri?>? firstTag;

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
      localeListResolutionCallback: appLocale,
      // 기본 서체를 monospace 로 못 박지 않는다. 숫자가 줄 서는 자리에만
      // 붙이면 되고, 화면 전체를 고정폭으로 두면 한글이 성기게 벌어져 iOS
      // 앱처럼 안 보인다. 나머지는 시스템 서체(SF Pro / Apple SD Gothic Neo)를
      // 그대로 쓴다.
      theme: setpadTheme,
      home: _Home(
        store: store,
        tags: tags,
        firstTag: firstTag,
        account: account,
      ),
      // 헬스 커넥트가 "권한을 왜 쓰는가" 를 물으면 Android 가 이 이름으로 연다
      // (MainActivity.getInitialRoute, onNewIntent).
      onGenerateRoute: (settings) => settings.name == HealthDataPage.route
          ? CupertinoPageRoute<void>(
              settings: settings,
              builder: (_) => const HealthDataPage(),
            )
          : null,
    );
  }
}

/// 앱이 켜지는 자리.
///
/// **목록이 아니라 패드로 연다.** 헬스장에서 앱을 여는 이유는 세트를 하나
/// 적으려는 것이지 지난 기록을 넘겨보려는 것이 아니다. 그래서 오늘 것이 있으면
/// 그것을, 없으면 새 기록을 곧바로 펴고, 목록은 뒤로가기 한 번 뒤에 둔다.
/// 링크(스티커·건네받기·단톡방)로 켜졌으면 그 링크가 연 화면이 먼저다.
class _Home extends StatefulWidget {
  const _Home({this.store, this.tags, this.firstTag, this.account});
  final Stream<Uri>? tags;
  final Future<Uri?>? firstTag;

  final NotesStore? store;
  final Account? account;

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> with WidgetsBindingObserver {
  late final NotesStore _store = widget.store ?? NotesStore();

  /// 저장소를 다 읽었다. 링크도 이것을 기다린다 — 읽기 전에 만든 기록은 읽기가 끝나며
  /// 지워지고, 이미 시작한 루틴을 찾는 확인도 빈 목록을 본다.
  late final Future<void> _loaded = _store.load();
  final _health = HealthLink();

  /// 서버에 묻는 쪽. 로그인했으면 계정으로, 아니면 이 기기로 묻는다.
  RecordAi get _ai => _account.ai;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    updateRequired.addListener(_askUpdate);
    _watchTags();
    _alarmTaps = _reportTaps.listen(_openReport);
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
    await _loaded;
    // 스티커·건네받기·단톡방 링크로 켜졌으면 그 링크가 제 화면을 연다. 오늘 기록을 밑에
    // 또 펴면 편집기가 두 겹이라 목록까지 완료를 두 번 눌러야 했다. 앱을 연 링크는 채널
    // 한 번이면 오고 저장소를 읽는 동안 같이 물었다 — 플러그인이 답하지 않아도 오래 막지 않는다.
    final first = await _firstLink?.timeout(
      const Duration(seconds: 2),
      onTimeout: () => null,
    );
    if (!mounted) return;
    // 세트를 끝낼 때마다 저장소가 알린다. 오늘 문턱을 넘은 첫 순간에 원판을 받는다.
    _store.addListener(_claimDaily);
    setState(() => _ready = true);
    if (first != null && _opensScreen(first)) return;
    // 첫 프레임이 그려진 뒤에 밀어 넣어야 목록이 뒤에 남는다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _open(_todayOrNew()));
  }

  /// 오늘 기록을 이어 쓴다. 하루에 앱을 여러 번 여는 흐름에서 열 때마다 새 기록이
  /// 쌓이면 목록이 못 쓰게 된다.
  Note _todayOrNew() => _store.today();

  bool _updateAsked = false;

  /// 서버가 이 판을 더는 받지 않는다(426). 스토어로 가는 안내를 한 번 띄우고 닫지
  /// 못하게 둔다 — 사고 난 판을 서버가 끊어 낸 것이라, 이 판으로는 서버와 다시
  /// 이야기하지 못한다. 적은 기록은 기기에 그대로 있다.
  void _askUpdate() {
    if (!updateRequired.value || _updateAsked || !mounted) return;
    _updateAsked = true;
    unawaited(
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => PopScope(
          canPop: false,
          child: CupertinoAlertDialog(
            content: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                L.of(ctx).updateRequired,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                key: const ValueKey('update-store'),
                isDefaultAction: true,
                onPressed: () => openUrl(_storeUrl),
                child: Text(L.of(ctx).updateAction),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 이 앱의 스토어 쪽. 웹의 '앱 받기'(gymdojo get-app.tsx)와 같은 주소다.
  static String get _storeUrl => defaultTargetPlatform == TargetPlatform.iOS
      ? 'https://apps.apple.com/app/id6757940370'
      : 'https://play.google.com/store/apps/details?id=com.taeskim.setpad';

  Future<void> _open(Note note) async {
    // 이미 열려 있으면 그 편집기로 돌아간다. 하나 더 열면 두 편집기가 저마다의
    // 목록을 들고 있다가, 아래 것이 저장할 때 위에서 더한 운동을 덮는다. 스티커·
    // 건네받기·목록이 모두 여기로 온다.
    if (_store.open.contains(note)) {
      Navigator.of(
        context,
      ).popUntil((r) => r.settings.name == note.id || r.isFirst);
      return;
    }
    _store.open.add(note);
    await Navigator.of(context).push(
      CupertinoPageRoute(
        settings: RouteSettings(name: note.id),
        builder: (_) => EditorPage(
          store: _store,
          note: note,
          account: _account,
          // 빠지면 기본값(기기 id 없음)이 쓰여, 열량 없는 끼니의 추정이 조용히 멈췄다.
          ai: _ai,
          onTakeHandoff: _takeHandoff,
        ),
      ),
    );
    _store.open.remove(note);
    // 아무것도 안 치고 나온 새 기록은 남기지 않는다.
    _store.discardIfEmpty(note);
    // 끝났다. 체육관 기록이면 지금 올린다 — 잠금 해제 때 반만 간 것도 여기서 다 간다.
    // 그물 없이 끝낸 같이 하기도 여기서 간다 — 닫으면 편집기의 폴링이 멈춘다.
    if (note.gymId != null || (note.partner?.endPending ?? false)) {
      unawaited(_sendPendingWorkouts());
    }
    _healthSync = _healthSync
        .then((_) => _syncHealth(note))
        .catchError((Object e) => debugPrint('건강 앱 맞추기 실패: $e'));
  }

  /// 편집을 마치고 나올 때 건강 앱과 맞춘다.
  ///
  /// 기다리지 않는다 — 권한 창이 뜨든 안 뜨든 목록은 이미 보여야 한다.
  /// 실패해도 조용하다. 연동은 덤이지 기록의 전제가 아니다.
  Future<void> _syncHealth(Note note) async {
    final sets = note.blocks.expand((b) => b.sets).where((s) => s.mine);
    if (sets.isEmpty) return;
    // 시작과 끝. 세트마다 시각을 남기지 않으므로 노트가 만들어진 때와 마지막에
    // 고친 때로 잡는다. 실제로 그 사이에 운동을 한 것이 맞다.
    // 다른 문서가 이미 잰 구간은 빼고, 나중에 고친 시각까지 늘어나지 않게 자른다
    // — 같은 활동 에너지를 두 번 더하거나 하루치를 운동 칼로리라 부르지 않으려고.
    final start = sessionStart(note, _store.notes);
    final end = sessionEnd(note);
    if (!end.isAfter(start)) return;

    if (!await _health.authorize()) return;

    final kcal = await _health.activeEnergy(start, end);
    final saved = await _health.saveWorkout(
      start: start,
      end: end,
      title: note.title,
      energyBurned: kcal,
      previous: note.healthWorkout,
      clearLegacy: !sessionOverlapsOther(note, _store.notes, start),
    );
    var changed = !identical(saved, note.healthWorkout);
    note.healthWorkout = saved;
    if (kcal != null && kcal != note.calories) {
      note.calories = kcal;
      changed = true;
    }
    if (changed && mounted) _store.touch();
  }

  /// 건강 앱 맞추기는 한 번에 하나씩. 빨리 두 번 나오면 둘이 같은 옛 운동을 보고
  /// 각자 새로 써서 운동이 둘이 된다.
  Future<void> _healthSync = Future.value();

  /// 로그인과 결제. **없어도 앱은 그대로 돈다** — 켜지 않은 사람은 그냥 쓴다.
  /// 기기 id 는 store 가 처음 켤 때 만들므로 부를 때 읽는다.
  late final _account =
      (widget.account ??
            Account(
              deviceId: () => _store.deviceId,
              aiEnabled: () => _store.aiOn,
            ))
        ..start().then((_) => _sendPendingWorkouts());

  void _claimDaily() => unawaited(_account.claimDaily(_store));

  StreamSubscription<String>? _alarmTaps;

  /// 보고 알림을 눌렀다. 그 도장의 트레이너 화면을 열고, 닫으면 목록의 점을
  /// 다시 센다. 이제 그 도장 직원이 아니면 화면이 서버의 말(403)을 보여 주고
  /// 그 도장 알림을 지운다.
  Future<void> _openReport(String gymId) async {
    // 알림을 눌러 켜진 앱은 남겨 둔 로그인이 살아나야 보고서를 읽을 토큰이 있다.
    await _account.restored;
    if (!mounted || !_account.signedIn) return;
    await pushTrainer(context, _account, gymId);
  }

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

  String? _lastHandoff;

  /// 지금 연 단톡방 수업·예약 링크. 처음 링크와 스트림이 같은 것을 두 번 준다.
  String? _lastScreenLink;

  /// 남이 대신 적어 건네준 기록을 받는다. **받아야 내 것이 된다** — 새 운동 문서로
  /// 들어오고, 그 운동을 한 시각에 놓인다. 같은 링크를 다시 열면 같은 문서가 열리고,
  /// 보낸 사람이 그사이 더 적었으면 그 내용으로 맞춘다. 다만 내가 이미 고친 문서는
  /// 덮지 않는다 — 그때는 새 문서로 따로 들어온다.
  // ponytail: 받는 쪽도 로그인이 필요하다. 서버는 기기 토큰으로도 읽게 해 두었으니,
  // 계정 없는 사람이 받아야 하면 RecordAi 의 기기 토큰을 여기에 빌려주면 된다.
  Future<void> _takeHandoff(String token) async {
    final l = L.of(context);
    if (!_account.signedIn) {
      await askSignIn(context, _account, message: l.handoffSignIn);
      if (!mounted || !_account.signedIn) return;
    }
    final reply = await _account.link.readHandoff(token);
    if (!mounted) return;
    final h = reply.handoff;
    // 내가 적어 보낸 링크를 내 폰에서 눌렀다. 받으면 상대의 세트가 내 기록이 된다.
    if (h?.mine ?? false) {
      final sent = _store.notes
          .where((n) => n.proxy?.token == token)
          .firstOrNull;
      if (sent != null) return _open(sent);
      return _tellTag(l.handoffMine);
    }
    final had = _store.notes.where((n) => n.handoffToken == token).toList();
    if (h == null) {
      // 못 받았어도 전에 받아 둔 것이 있으면 그것을 연다.
      if (had.isNotEmpty) return _open(had.first);
      return _tellTag(l.handoffFailed);
    }
    final note = placeHandoff(_store, token, h);
    _store.touch();
    await _open(note);
  }

  /// 지금 처리 중인 같이 하기 초대 링크. 처음 링크와 스트림이 같은 것을 두 번 준다.
  String? _lastPartnerLink;

  /// 같이 하기 초대 링크를 받았다. 오늘 기록을 열고 그 편집기가 토큰으로 참여한다 —
  /// 가까이 대서 받은 토큰과 같은 길이다(PartnerSync.joinWithToken). 로그인은 여기서 먼저:
  /// 참여한 뒤에 로그인하라고 하면 토큰을 다시 받을 길이 없다.
  Future<void> _joinFromLink(String token) async {
    if (!_account.signedIn) {
      final ok = await askSignIn(
        context,
        _account,
        message: L.of(context).partnerSignIn,
      );
      if (!mounted || !ok) return;
    }
    final note = _todayOrNew();
    pendingPartnerJoin.value = (noteId: note.id, token: token);
    await _open(note);
  }

  /// 이 링크가 제 화면을 여는가 — [_openTag] 가 가르는 넷: 건네받기, 같이 하기 초대,
  /// 단톡방의 수업·예약, 스티커.
  static bool _opensScreen(Uri uri) =>
      handoffTokenFromLink(uri) != null ||
      partnerTokenFromLink(uri) != null ||
      gymScreenFromLink(uri) != null ||
      gymFromTag(uri) != null;

  Future<void> _openTag(Uri uri) async {
    // 브라우저로 간 웹 로그인이 돌아온 것. 기다리던 로그인이 받는다(sign_in.dart).
    if (finishWebSignIn(uri)) return;
    // 앱이 꺼진 채로 열렸으면 남겨 둔 로그인이 아직 안 살아났다. 그 전에 보면
    // 로그인한 사람에게도 로그인을 묻는다. start() 전체(스토어·이용권·원판)는
    // 기다리지 않는다 — 약한 그물에서 그것이 늘어지면 스티커가 아무 말이 없었다.
    await _loaded;
    await _account.restored;
    if (!mounted) return;
    final handoff = handoffTokenFromLink(uri);
    if (handoff != null) {
      // 같은 링크가 두 번 전달되는 일이 있다(처음 링크 + 스트림).
      if (handoff == _lastHandoff) return;
      _lastHandoff = handoff;
      await _takeHandoff(handoff);
      _lastHandoff = null;
      return;
    }
    if (partnerTokenFromLink(uri) case final token?) {
      if (token == _lastPartnerLink) return;
      _lastPartnerLink = token;
      try {
        await _joinFromLink(token);
      } finally {
        _lastPartnerLink = null;
      }
      return;
    }
    // 단톡방의 수업·예약 링크. 출석도 가입 신청도 아니다 — 다니는 도장이면 그 화면을 연다.
    if (gymScreenFromLink(uri) case (:final gymId, :final page)) {
      final key = uri.toString();
      if (_lastScreenLink == key) return;
      _lastScreenLink = key;
      try {
        // 이 앱이 링크를 받으니 웹 화면으로는 갈 수 없다 — 말없이 빈 목록에 두지 않는다.
        // 로그인이 풀린 폰(새 폰, 로그아웃, 끊긴 토큰)이면 스티커처럼 여기서 로그인한다.
        if (!_account.signedIn) {
          final ok = await askSignIn(
            context,
            _account,
            message: L.of(context).tagSignInNeeded,
          );
          if (!mounted) return;
          if (!ok) {
            if (_account.signInRefused) {
              await _tellTag(L.of(context).signInFailed);
            }
            return;
          }
        }
        bool member() => _account.gyms.any((g) => g.id == gymId);
        // 앱이 꺼진 채 열렸으면 도장 목록이 아직 없다 — 목록 화면이 따로 묻는다. 기다리지
        // 않고 보면 다니는 회원에게도 아무 화면이 안 뜬다. 한 번 묻는다(_handleTag 와 같다).
        if (!member()) await _account.refreshGyms();
        if (!mounted) return;
        if (!member()) {
          // 목록을 한 번도 못 받았으면 그물 탓이다. 받았는데 없으면 이 도장 회원이 아니다.
          await _tellTag(
            _account.gymsLoaded
                ? L.of(context).gymLinkNotMember
                : L.of(context).partnerErrNetwork,
          );
          return;
        }
        if (page == 'bookings') {
          await openBooking(context, _account, store: _store, gymId: gymId);
        } else {
          await Navigator.of(context).push(
            CupertinoPageRoute<void>(
              builder: (_) => ClassesPage(account: _account, gymId: gymId),
            ),
          );
        }
      } finally {
        _lastScreenLink = null;
      }
      return;
    }
    final gymId = gymFromTag(uri);
    if (gymId == null) return;
    if (_handling == gymId) {
      // 같은 스티커가 또 왔다. 처음 링크와 스트림이 같은 것을 두 번 주는 것이면
      // 무시한다. 브라우저 로그인을 기다리는 중이었으면 — 사람이 카카오 화면에서
      // 그냥 돌아온 것이다 — 그 기다림을 놓고 새로 처리한다. 안 그러면 열 분
      // 동안 스티커가 아무 말이 없다.
      if (!cancelWebSignIn()) return;
      await _handlingTag;
      if (!mounted) return;
    }
    _handling = gymId;
    final run = _handleTag(uri, gymId);
    _handlingTag = run;
    try {
      await run;
    } finally {
      if (identical(_handlingTag, run)) {
        _handling = null;
        _handlingTag = null;
      }
    }
  }

  /// 지금 처리 중인 스티커. 같은 것을 다시 댔을 때 앞의 것이 끝나기를 기다린다.
  Future<void>? _handlingTag;

  Future<void> _handleTag(Uri uri, String gymId) async {
    // **여기서 로그인까지 끝낸다.** 안내만 하고 웹으로 보내면 거기서 또
    // 로그인 수단을 고르게 되고, 웹의 카카오와 앱의 Apple 은 서로 다른
    // 사람이 된다. 기기가 쓰는 수단 하나로 여기서 들어오고 이어서 진행한다.
    if (!_account.signedIn) {
      final l = L.of(context);
      final ok = await askSignIn(context, _account, message: l.tagSignInNeeded);
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

    final routines = await _account.link.routines(gymId: gymId);
    if (!mounted) return;
    if (routines == null) {
      // 못 물어봤다. 루틴이 없는 것으로 치면 빈 출석이 되거나 가입 신청이 나간다.
      await _tellTag(L.of(context).tagOffline);
      return;
    }
    final mine = routines.where((r) => r.gymId == gymId).firstOrNull;
    if (mine == null) {
      // 그 체육관에 다니지 않는 것과, 다니는데 오늘 받은 것이 없는 것은
      // 해야 할 일이 다르다. 둘 다 **안내가 아니라 행동으로 끝난다** — 말만
      // 하고 멈추면 회원이 될 길도, 출석이 남을 길도 앱 안에 없다.
      bool member() => _account.gyms.any((g) => g.id == gymId);
      // 켤 때 목록을 못 받았을 수 있다. 회원에게 가입 안내를 띄우기 전에 한 번 묻는다.
      if (!member()) await _account.refreshGyms();
      if (!mounted) return;
      await (member() ? _attendOnly(gymId) : _askJoin(gymId));
      return;
    }
    // 이미 시작한 루틴이면 그 기록을 다시 연다. 또 만들면 같은 루틴이 둘이 된다.
    final started = _store.notes
        .where((n) => n.routineId == mine.id)
        .firstOrNull;
    final note =
        started ??
        (_store.create(
          blocks: inWeightUnit(mine.blocks, _store.weightUnit),
          gymId: mine.gymId,
          routineId: mine.id,
        )..owner = _account.userId);
    // 스티커를 댄 것이 곧 출석이다 — 루틴을 열어만 보고 닫아도 트레이너 화면에 온
    // 것은 뜬다. 루틴 완료는 세트를 적어야 된다(gym.dart sendPending).
    if (!note.checkedIn) {
      note.checkedIn = true;
      _store.touch();
      unawaited(_sendPendingWorkouts());
    }
    _open(note);
  }

  /// 회원이 아닌 사람. 댄 김에 신청한다 — 트레이너 화면에 바로 뜨고, 확인하면 회원이 된다.
  ///
  /// **신청 전에 한 번 묻는다.** 신청이 곧 동의다: 회원이 되면 도장이 닉네임·그 도장에서 한
  /// 운동·끼니·예약을 보고, 서버는 그때 보여 준 안내의 판을 남긴다. 예전에는 대는 순간
  /// 신청이 나가서 무엇을 보게 되는지 말할 자리가 없었다.
  Future<void> _askJoin(String gymId) async {
    final l = L.of(context);
    final agreed = await askGymConsent(
      context,
      title: l.joinAsk,
      agree: l.joinAgree,
    );
    if (agreed != true || !mounted) return;
    var state = await _account.link.requestJoin(gymId);
    if (!mounted) return;
    // '만 14세 이상' 확인 칸이 생기기 전에 만든 계정이다. 한 번 묻고 남긴 뒤 다시
    // 신청한다 — 아니라고 하면 신청하지 않는다(만 14세 미만은 도장에 등록하지 않는다).
    // 남기지 못했으면 아래에서 신청하지 못했다고 말한다.
    if (state == JoinState.ageRequired) {
      final recorded = await confirmAge(context, _account);
      if (recorded == null || !mounted) return;
      if (recorded) state = await _account.link.requestJoin(gymId);
      if (!mounted) return;
    }
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

  /// 루틴이 없는 날. **온 것은 온 것이다** — 기록 하나가 곧 출석이고,
  /// 이것이 없으면 트레이너의 오늘 화면에 이 사람이 영영 안 뜬다.
  ///
  /// 같은 날 두 번 대도 한 번이다. 웹이 세 시간 안의 기록을 다시 여는 것과
  /// 같은 규칙을 쓴다 — 폰이 잠겼다 돌아온 것을 두 번째 방문으로 세지 않는다.
  /// 오늘 먼저 적던 기록이 있으면 그것이 이 방문이 된다(NotesStore.visit).
  Future<void> _attendOnly(String gymId) async {
    final (:note, :fresh) = _store.visit(gymId, _account.userId);
    if (fresh) unawaited(_sendPendingWorkouts());
    if (mounted) _open(note);
  }

  Future<void> _tellTag(String message) => showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message, style: const TextStyle(fontSize: 13)),
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
  /// 그물 없이 끝낸 같이 하기도 — 편집기를 닫으면 그 화면의 폴링도 멈추므로
  /// 여기서 안 보내면 상대에게는 세션이 영영 살아 있다. 지운 기록이 서버에 남긴
  /// 끼니·운동 줄도 여기서 지운다.
  ///
  /// 한 번에 하나만 돈다. 도는 중에 또 부르면 끝난 뒤 한 번 더 전부 돈다 — 편집기를
  /// 닫은 기록이 빠지지 않게. [later] 는 첫 번만 쓴다 — 올리는 중에 온 복귀는 열린
  /// 기록도 마저 올린다(겹친 부름 하나에 한 번이라 괜찮다).
  Future<void> _sendPendingWorkouts({bool Function(Note note)? later}) {
    if (_syncing case final running?) {
      _syncAgain = true;
      return running;
    }
    return _syncing = () async {
      do {
        _syncAgain = false;
        await _syncOnce(later);
        later = null;
      } while (_syncAgain && mounted);
    }().whenComplete(() => _syncing = null);
  }

  Future<void>? _syncing;
  bool _syncAgain = false;

  Future<void> _syncOnce(bool Function(Note note)? later) async {
    await sendPending(
      _account.link,
      _store.notes,
      onSent: _store.touch,
      later: later,
    );
    await syncMeals(
      _account.link,
      _store.notes,
      shareMealsGym: _store.shareMealsGym,
      onSynced: _store.touch,
    );
    await sendPendingEnds(_account.link, _store.notes, onSent: _store.touch);
    await sendDeletes(
      _account.link,
      _store.pendingDeletes,
      onSent: _store.touch,
      // 목록의 '되돌리기' 가 떠 있는 동안 그 지우기는 내보내지 않는다.
      held: _store.heldDeletes,
    );
    // 보낸 지 세 시간이 지난 빈 출석 기록은 목록에서 치운다.
    _store.pruneVisits();
  }

  /// 앱을 연 링크. 없으면 null 로 끝난다. [_boot] 가 이것을 보고 오늘 기록을 펼지 정한다.
  Future<Uri?>? _firstLink;

  /// 앱이 닫혀 있다 열린 경우와, 떠 있는데 댄 경우를 한 줄기로 받는다.
  void _watchTags() {
    final given = widget.tags;
    Future<Uri?>? first;
    if (given != null) {
      _tags = given.listen(_openTag);
      first = widget.firstTag;
    } else if (!kIsWeb) {
      // 웹에는 스티커를 읽을 것이 없다. 채널을 깨우지 않는다.
      final links = AppLinks();
      _tags = links.uriLinkStream.listen(_openTag, onError: (Object _) {});
      first = links.getInitialLink();
    }
    _firstLink = first?.catchError((Object _) => null);
    unawaited(
      _firstLink?.then((uri) {
        if (uri != null) _openTag(uri);
      }),
    );
  }

  /// 앱을 정말 내렸다(hidden·paused). 제어 센터·알림 센터·Face ID 는 inactive 만
  /// 거쳐 돌아온다 — 그때마다 열린 기록을 다시 올리고 스토어를 다시 묻지 않는다.
  bool _away = false;

  /// 열린 편집기의 기록을 5분 안에 이미 올렸다. 잠금을 풀 때마다 다시 올리지 않고,
  /// 편집기를 닫을 때 마저 올린다.
  bool _settling(Note note) =>
      _store.open.contains(note) &&
      note.sentAt != null &&
      DateTime.now().difference(note.sentAt!) < const Duration(minutes: 5);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 내려갈 때는 디바운스를 기다리지 않는다.
    if (state != AppLifecycleState.resumed) _store.flush();
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      if (!_away) releaseIdleConnections();
      _away = true;
    }
    if (state == AppLifecycleState.resumed && _away) {
      _away = false;
      // 돌아왔다. 그동안 신호가 잡혔을 수 있다.
      unawaited(_sendPendingWorkouts(later: _settling));
      // 켤 때 못 읽은 이용권·요금제가 있으면 다시 읽는다(읽었으면 묻지 않는다).
      unawaited(_account.reloadStore());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    updateRequired.removeListener(_askUpdate);
    _tags?.cancel();
    _store.removeListener(_claimDaily);
    _alarmTaps?.cancel();
    if (widget.account == null) _account.dispose();
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
    this.onTakeHandoff,
  });

  final NotesStore store;
  final Note note;

  /// 상대가 대신 적어 준 내 기록을 받는다. 받은 것은 새 운동 문서로 열린다.
  final void Function(String token)? onTakeHandoff;

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
  /// 돌아오면 바로 최신 상태를 다시 묻는다. 제어 센터·알림 센터·Face ID 는
  /// inactive 만 거쳐 돌아온다 — 그때마다 끊고 다시 붙지 않는다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _partner?.start();
    } else if (state != AppLifecycleState.inactive) {
      _partner?.stop();
    }
  }

  final _documentHeaderKey = GlobalKey<_DocumentHeaderState>();

  /// 어림을 기다리는 끼니. 그 줄은 '다시 어림' 대신 어림 중이라고 말한다.
  /// 고친 끼니는 새 객체라서, 옛 끼니의 늦은 답이 새 줄의 표시를 지우지 않는다.
  final _estimatingMeals = <MealEntry>{};
  late final _editor = RoutineEditorController(
    history: widget.store.exerciseHistory,
    weightUnit: widget.store.weightUnit,
    savedSetup: widget.store.setupOf,
  );
  String? _lastLearned;
  final _mealText = ValueNotifier<({String text, int? index})?>(null);

  // ── 대신 적기 ────────────────────────────────────────────────────
  // 같이 운동하는 사람의 세트를 내 폰에서 적는다. 같은 편집기를 쓰되 **다른
  // 칸**(note.proxy)에 적힌다 — 내 기록·내 통계·같이 하기 공유와 섞이지 않는다.
  bool _writingFor = false;
  RoutineEditorController? _proxyEditor;
  Timer? _proxySend;
  HandoffError? _proxyError;

  Future<void> _writeFor() async {
    final note = widget.note;
    final people = note.partner?.state == PartnerState.active
        ? note.partner!.others
        : const <PartnerPerson>[];
    if (note.proxy == null && people.length > 1) {
      // 셋 이상이 같이 한다. 누구의 것인지 알아야 그 사람 화면에만 받기가 뜬다.
      final who = await showCupertinoModalPopup<PartnerPerson>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(L.of(ctx).proxyWhose),
          actions: [
            for (final p in people)
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(ctx, p),
                child: Text(p.name),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(L.of(ctx).cancel),
          ),
        ),
      );
      if (who == null || !mounted) return;
      note.proxy = ProxyRecord(name: who.name, forKey: who.key);
    }
    final proxy = note.proxy ??= ProxyRecord(
      name: people.firstOrNull?.name ?? note.partner?.partnerName ?? '',
      forKey: people.firstOrNull?.key,
    );
    // 이름은 같이 하는 상대를 따라간다. 혼자 적기 시작했다가 나중에 연결해도 맞는다.
    if (proxy.name.isEmpty) proxy.name = note.partner?.partnerName ?? '';
    if (proxy.blocks.isEmpty && note.partner?.doc != null) {
      proxy.blocks = blocksFromJson(note.partner!.doc).map((block) {
        for (final set in block.sets) {
          set
            ..author = null
            ..done = false;
        }
        return block;
      }).toList();
    }
    _proxyEditor ??=
        RoutineEditorController(
            history: widget.store.exerciseHistory,
            weightUnit: widget.store.weightUnit,
            savedSetup: widget.store.setupOf,
          )
          ..restore(proxy.blocks)
          ..addListener(_persistProxy);
    setState(() => _writingFor = true);
  }

  void _persistProxy() {
    final proxy = widget.note.proxy;
    if (proxy == null) return;
    proxy
      ..blocks = _proxyEditor!.blocks
      ..revision += 1;
    // 먼저 이 기기에 남긴다. 올리는 것은 그다음이고, 그물이 없으면 밀려 있다가 간다.
    widget.store.touch();
    _proxySend?.cancel();
    _proxySend = Timer(const Duration(seconds: 1), _sendProxy);
  }

  Future<HandoffError?> _sendProxy() async {
    final link = widget.account?.link;
    if (link == null) return HandoffError.signInRequired;
    final session = widget.note.partner;
    final error = await link.sendProxy(
      widget.note,
      sessionId: session?.state == PartnerState.active ? session!.id : null,
    );
    widget.store.touch();
    if (mounted) setState(() => _proxyError = error);
    return error;
  }

  /// 건넨다 — 올린 것을 확인하고 링크를 공유한다. 같이 하는 중이면 상대 화면에는
  /// 이미 "받기" 가 떠 있다. 링크는 폰이 곁에 없는 사람에게 보내는 길이다.
  Future<void> _handOver() async {
    _proxySend?.cancel();
    final error = await _sendProxy();
    final token = widget.note.proxy?.token;
    final link = widget.account?.link;
    if (!mounted || error != null || token == null || link == null) return;
    await shareText(L.of(context).proxyShareText(link.handoffUrl(token)));
  }

  /// 상대가 적어 준 내 기록이 와 있고, 아직 받지 않았다.
  ({String token, int revision, String from})? get _offered {
    final offer = widget.note.partner?.handoff;
    if (offer == null || widget.onTakeHandoff == null) return null;
    final taken = widget.store.notes.any(
      (n) =>
          n.handoffToken == offer.token &&
          (n.handoffRevision ?? 0) >= offer.revision,
    );
    return taken ? null : offer;
  }

  /// 같은 날 만든 다른 기록들. 하루에 문서가 여럿일 수 있다 — 오전에 한 장,
  /// 저녁에 한 장. 합치거나 베끼지 않고 이 문서 아래에 읽기 전용으로 보여 준다.
  /// 이 기록에서 최고 무게를 새로 넘긴 세트. 기록이 바뀔 때만 다시 센다 — 편집기는
  /// 칸마다 묻는다.
  (int, Map<String, Set<int>>)? _recordsMemo;
  Map<String, Set<int>> _records() {
    final rev = widget.store.revision;
    if (_recordsMemo case (final r, final m) when r == rev) return m;
    final m = weightRecords(widget.store.notes)[widget.note.id] ?? const {};
    _recordsMemo = (rev, m);
    return m;
  }

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

  /// 지난주 같은 요일의 운동 — 없으면 4주 전까지 같은 요일을 거슬러 본다. 오늘
  /// 무엇을 얼마나 할지 옆에서 본다(읽기 전용). 같은 날 기록은 하나로 모은다
  /// ([NotesStore.today]) — 그래서 여기 보일 것은 지난 운동이다.
  (Note, int)? get _lastWeek {
    final at = widget.note.createdAt;
    for (var w = 1; w <= 4; w++) {
      final d = DateTime(at.year, at.month, at.day - 7 * w);
      for (final n in widget.store.notes) {
        final c = n.createdAt;
        if (n != widget.note &&
            n.blocks.any((b) => b.sets.isNotEmpty) &&
            c.year == d.year &&
            c.month == d.month &&
            c.day == d.day) {
          return (n, w);
        }
      }
    }
    return null;
  }

  /// 글로 적은 한 끼를 저장한다. 묻지 않는다 — 모르는 음식도, 양이 없는 글도
  /// 친 그대로 남고, 열량은 사람이 적었을 때만 있다. 일부만 적었으면 적은 합을
  /// 먼저 넣어 둔다 — 어림이 막혀도 적은 수는 합계에서 빠지지 않는다. 고치다
  /// 다 지우면 그 끼니가 없어진다.
  ///
  /// 새로 남긴 끼니면 그것을 지우는 함수를 돌려준다 — 운동 줄에서 알아서 끼니로
  /// 남긴 것을 '운동으로 바꾸기' 로 되돌린다. 그사이 어림이 붙어 바뀌었어도 같은
  /// 끼니(id)를 지운다.
  VoidCallback? _saveMealText(String text, int? index) {
    final meals = widget.note.meals;
    final old = index != null && index < meals.length ? meals[index] : null;
    VoidCallback? undo;
    if (text.isEmpty) {
      if (old != null) widget.note.removeMeal(old);
    } else {
      final parsed = parseMealText(text);
      final kcal = parsed.kcal ?? parsed.typed;
      final entry = MealEntry(
        id: old?.id, // 고친 끼니는 서버의 같은 줄이다.
        at: old?.at ?? widget.note.mealTime(),
        kcal: kcal,
        text: text,
        source: kcal == null ? null : MealEntry.typed,
        foods: parsed.foods,
      );
      old == null ? meals.add(entry) : meals[index!] = entry;
      if (parsed.kcal == null) _estimateMealText(entry);
      if (old == null) {
        undo = () {
          final now = widget.note.meals.where((m) => m.id == entry.id);
          if (now.isEmpty) return;
          widget.note.removeMeal(now.first);
          _mealsChanged();
        };
      }
    }
    _mealsChanged();
    return undo;
  }

  /// 끼니가 바뀌었다. 먼저 이 기기에 쓰고, 그다음 서버의 같은 줄에 맞춘다 —
  /// 그물이 없으면 밀려 있다가 다음에 간다. 식단 공유를 켰으면 스티커를 대지 않은 날의
  /// 기록도 다니는 도장에 묶는다(NotesStore.linkMeals).
  void _mealsChanged() {
    final account = widget.account;
    if (account != null && account.signedIn) {
      widget.store.linkMeals(widget.note, [
        for (final g in account.gyms) g.id,
      ], account.userId);
    }
    widget.store.touch();
    final link = account?.link;
    if (link == null || widget.note.mealGym == null) return;
    syncMeals(
      link,
      [widget.note],
      shareMealsGym: widget.store.shareMealsGym,
      onSynced: widget.store.touch,
    );
  }

  /// 원문은 이미 저장됐다. 열량을 안 적은 끼니에 어림값을 붙여 볼 뿐이고,
  /// 못 붙이면 미상으로 남는다. 그사이 사람이 고쳤거나 지웠으면 손대지 않고
  /// 말도 하지 않는다 — 그 끼니의 일이 아니다.
  ///
  /// 못 붙였으면 **왜인지 한 번 말한다** — 모르는 음식인지, 연결이 안 된 것인지.
  /// 조용히 '열량 미상' 만 두면 무엇을 고쳐야 하는지 알 길이 없다. 그 끼니 줄에
  /// '다시 어림' 이 뜨고, 줄을 눌러 고친 뒤 Enter 를 눌러도 다시 어림한다.
  ///
  /// 글에 적힌 열량은 버리지 않는다. 어림이 적은 합보다 작으면 받지 않는다 —
  /// 적은 음식 값만으로도 그보다 크다. 그때와 어림이 막혔을 때는 적은 합이
  /// 남아 있고([_saveMealText]), 그렇다고 말한다.
  Future<void> _estimateMealText(MealEntry entry) async {
    if (_estimatingMeals.contains(entry)) return;
    final l = L.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final parsed = parseMealText(entry.text!);
    final typed = parsed.typed;
    MealEstimate? estimate;
    String? failure;
    // 서버는 500자까지 받는다. 보내 봐야 거절이니 먼저 말한다.
    if (parsed.needsReview) {
      failure = l.mealTextNeedsReview;
    } else if (entry.text!.length > 500) {
      failure = l.mealTextTooLong;
    } else if (!widget.ai.supported) {
      failure = l.mealTextOffline;
    } else {
      _estimatingMeals.add(entry);
      try {
        estimate = await widget.ai.estimateMealText(
          entry.text!,
          locale: locale,
        );
      } on RecordAiException catch (e) {
        failure = switch ((e.status, e.code)) {
          (RecordAiStatus.aiOff, _) => l.aiOff,
          (RecordAiStatus.quotaExceeded, _) => l.inputQuotaSpent,
          // 붐빔·오늘 몫 소진은 연결 문제가 아니다(계약 C1).
          (RecordAiStatus.busy, _) => l.aiBusy,
          (RecordAiStatus.budgetExhausted, _) => l.aiBudgetExhausted,
          (_, 'unknownFood' || 'notFood') => l.mealTextUnknown,
          (_, 'ambiguousAmount') => l.mealTextNeedsReview,
          // 서버도 적은 합보다 작은 어림을 내보내지 않는다 — 아래의 같은 까닭이다.
          (_, 'belowTyped') when typed != null => null,
          _ => l.mealTextOffline,
        };
      } catch (_) {
        failure = l.mealTextOffline;
      } finally {
        _estimatingMeals.remove(entry);
      }
    }
    if (!mounted) return;
    if (!widget.note.meals.contains(entry)) return;
    void tell(String? message) =>
        _documentHeaderKey.currentState?.tell(message, entry);
    if (estimate == null || (typed != null && estimate.kcal < typed)) {
      return tell(
        [
          failure ?? l.mealTextBelowTyped(typed!),
          if (failure != null && typed != null) l.mealTextPartial(typed),
        ].join('\n'),
      );
    }
    final reviewed = estimate.requiresConfirmation
        ? await reviewMealEstimate(context, estimate)
        : (
            kcal: estimate.kcal.toDouble(),
            text: null,
            macros: estimate.macros,
            sources: null,
          );
    if (!mounted || !widget.note.meals.contains(entry) || reviewed == null) {
      return;
    }
    final kcal = reviewed.kcal.round();
    if (typed != null && kcal < typed) return tell(l.mealTextBelowTyped(typed));
    final at = widget.note.meals.indexOf(entry);
    tell(null);
    widget.note.meals[at] = MealEntry(
      id: entry.id,
      at: entry.at,
      kcal: kcal,
      items: estimate.confirmedItems,
      text: entry.text,
      reviewedText: reviewed.text,
      source: MealEntry.estimate,
      foods: reviewed.text == null
          ? entry.foods
          : parseMealText(reviewed.text!).foods,
      sources: reviewed.sources ?? estimate.sources,
      macros: reviewed.macros,
    );
    _mealsChanged();
  }

  /// 이 화면을 연 때의 기록.
  late final String _openedJson = jsonEncode(blocksToJson(widget.note.blocks));

  /// 마지막으로 저장한 기록. 카드를 열고 닫기만 해도 편집기는 알린다 — 그때마다
  /// 저장하면 updatedAt 이 움직여, 열어만 본 받은 루틴이 '고친 것' 이 되어 0세트로
  /// 완료 처리돼 올라갔다(gym.dart _lookedOnly). 연 때가 아니라 마지막 저장과
  /// 견준다 — 세트를 적었다 지운 것도 고친 것이라 다시 가야 한다.
  late String _savedJson = _openedJson;

  @override
  void initState() {
    super.initState();
    _openedJson;
    _editor.restore(widget.note.blocks);
    _lastLearned = _editor.recentExercises.firstOrNull;
    _editor.addListener(_persist);
    WidgetsBinding.instance.addObserver(this);
    _partner?.addListener(_partnerChanged);
    // 가까이 댄 상대가 건넨 같이 하기 초대. 코드를 친 것과 같은 길로 참여한다 —
    // 같은 토큰이 여러 번 와도 참여는 한 번이다(PartnerSync.joinWithToken).
    _nearbyInvites = Nearby.instance.received
        .where((invite) => invite.kind == 'session')
        .listen((invite) async {
          final sync = _partner;
          final account = widget.account;
          if (sync == null || account == null) return;
          final error = await sync.joinWithToken(invite.token);
          // 들어갔으면 문서 위 띠가 말한다. 못 들어갔으면(로그인 필요·만료·정원)
          // 시트가 이유를 그린다 — 참여만 부르고 말면 실패가 아무 말 없이 사라진다.
          if (error != null && mounted) {
            await showPartnerSheet(
              context,
              account,
              sync,
              onWriteFor: _writeFor,
            );
          }
        });
    // 링크로 받은 초대. 이 기록 앞으로 온 것만 — 열려 있는 동안 와도 받는다.
    pendingPartnerJoin.addListener(_joinPending);
    _joinPending();
    _wasActive = widget.note.partner?.state == PartnerState.active;
    // 다시 들어왔을 때 서버에 상태를 물어 복구한다(열린 세션이 있을 때만 돈다).
    _partner?.start();
  }

  /// 링크로 받은 같이 하기 초대를 이 기록으로 받는다. 못 들어갔으면 시트가 이유를 말한다.
  Future<void> _joinPending() async {
    final pending = pendingPartnerJoin.value;
    final sync = _partner, account = widget.account;
    if (pending == null || pending.noteId != widget.note.id) return;
    pendingPartnerJoin.value = null;
    if (sync == null || account == null) return;
    final error = await sync.joinWithToken(pending.token);
    if (error != null && mounted) {
      await showPartnerSheet(context, account, sync, onWriteFor: _writeFor);
    }
  }

  /// 같이 하던 중이었는가 — 남이 끝냈을 때 한 줄로 알리려고 지난 상태를 기억한다.
  bool _wasActive = false;

  /// 남이 끝낸 같이 하기. 띠로 한 번 알리고, 닫으면 사라진다.
  String? _endedBy;

  void _openPartnerSheet() => showPartnerSheet(
    context,
    widget.account!,
    _partner!,
    onWriteFor: _writeFor,
  );

  /// 오늘 한 장 — 그날 한 세트 전부, 먹은 것, 섭취−운동을 한 화면에.
  void _showDaySheet() {
    final l = L.of(context);
    final at = widget.note.createdAt;
    final day = dayLogs(
      widget.store.notes,
      from: at,
      to: at,
      weightOn: widget.store.weightOnDay,
    ).firstOrNull;
    showFitAll(
      context,
      [
        (
          caption: DateFormat.jm(l.localeName).format(widget.note.createdAt),
          blocks: _editor.blocks,
        ),
        for (final n in _sameDay)
          (
            caption: DateFormat.jm(l.localeName).format(n.createdAt),
            blocks: n.blocks,
          ),
      ],
      energy: day == null ? null : dayEnergyText(l, day),
      meals: [
        for (final m in day?.meals ?? const <MealEntry>[])
          (
            text: m.description,
            kcal: m.kcal == null
                ? l.mealKcalUnknown
                : m.partial
                ? l.kcalAtLeast(m.kcal!)
                : m.approximate
                ? l.kcalApprox(m.kcal!)
                : l.kcal(m.kcal!),
          ),
      ],
    );
  }

  /// 이 기록으로 할 수 있는 일들. 머리 줄에 흩어 두었을 때는 어느 것이 식단이고
  /// 어느 것이 운동의 것인지 헷갈렸다 — 한 곳에 모은다.
  void _showMenu() {
    final l = L.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          if (_editor.blocks.isNotEmpty)
            CupertinoActionSheetAction(
              key: const ValueKey('menu-day-sheet'),
              onPressed: () {
                Navigator.pop(ctx);
                _showDaySheet();
              },
              child: Text(l.fitAll),
            ),
          // 같이 하기. 로그인하지 않았으면 창 안에서 로그인으로 이어진다.
          if (_partner != null)
            CupertinoActionSheetAction(
              key: const ValueKey('menu-partner'),
              onPressed: () {
                Navigator.pop(ctx);
                showPartnerSheet(
                  context,
                  widget.account!,
                  _partner,
                  onWriteFor: _writeFor,
                );
              },
              child: Text(l.partnerInvite),
            ),
          // 자판을 내렸거나 세트를 치는 중이면 입력 줄 위의 식단 단추가 없다 —
          // 끼니는 여기서도 남긴다. 대신 적는 중에는 내 기록의 식단이 화면에 없다.
          if (!_writingFor)
            CupertinoActionSheetAction(
              key: const ValueKey('menu-meal'),
              onPressed: () {
                Navigator.pop(ctx);
                _documentHeaderKey.currentState?._pick();
              },
              child: Text(l.mealAdd),
            ),
          CupertinoActionSheetAction(
            key: const ValueKey('menu-settings'),
            onPressed: () async {
              Navigator.pop(ctx);
              await showWeightSettings(
                context,
                widget.store,
                account: widget.account,
              );
              if (mounted) {
                setState(() => _editor.weightUnit = widget.store.weightUnit);
              }
            },
            child: Text(l.settingsTitle),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
      ),
    );
  }

  void _partnerChanged() {
    if (!mounted) return;
    // 세션이 열리면 돌고, 끝나면 멈춘다.
    (widget.note.partner?.open ?? false) ? _partner!.start() : _partner!.stop();
    // 함께하던 것이 남의 손으로 끝났다. 띠만 조용히 사라지면 무슨 일인지 모른다.
    final now = widget.note.partner;
    final active = now?.state == PartnerState.active;
    if (_wasActive &&
        now?.state == PartnerState.ended &&
        now?.endedByMe != true) {
      _endedBy = now?.partnerName ?? '';
    } else if (active) {
      _endedBy = null;
    }
    _wasActive = active;
    // 같이 고치는 문서가 새로 왔다. 편집기를 그것으로 — 내 커서는 그 운동을 따라간다.
    final appliedVersion = widget.note.partner?.routineAppliedVersion;
    final doc = _partner.takeDoc();
    if (doc != null) {
      final lost = _editor.replaceBlocks(doc);
      if (widget.note.partner?.routineAppliedVersion != appliedVersion) {
        widget.store.touch();
      }
      if (lost != null) {
        unawaited(
          showCupertinoDialog<void>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              content: Text(
                L.of(ctx).liveExerciseRemoved(lost.name),
                style: const TextStyle(fontSize: 13),
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(L.of(ctx).ok),
                ),
              ],
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  void _persist() {
    // 편집기가 초안을 되살리며 첫 그리기 도중에 부를 수 있다. 그때 저장소가 알리면
    // 그리는 중에 다시 그리라는 것이 되어 예외가 난다 — 한 프레임 미룬다.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _persist();
      });
      return;
    }
    final recent = _editor.recentExercises.firstOrNull;
    if (recent != _lastLearned && recent != null) {
      widget.store.rememberExercise(recent);
    }
    _lastLearned = recent;
    final note = widget.note;
    // 연 때의 기록과 견준다. note.blocks 는 첫 저장 뒤로 편집기의 목록 그 자체라
    // 서로 견주면 늘 같았다 — 건네받은 기록을 고쳐도 다시 받기가 덮었다.
    // 같이 고치는 사람에게서 온 변경은 내가 고친 것이 아니다.
    final json = jsonEncode(blocksToJson(_editor.blocks));
    if (note.handoffToken != null &&
        !note.handoffTouched &&
        !_editor.remote &&
        json != _openedJson) {
      // 건네받은 기록을 내가 고쳤다. 이제 내 것이다 — 보낸 사람이 더 적어 보내도
      // 이 문서를 덮지 않는다.
      note.handoffTouched = true;
    }
    if (json == _savedJson) return;
    _savedJson = json;
    widget.store.update(widget.note, _editor.blocks);
    // 내 기록은 방금 이 기기에 저장됐다. 그다음에 상대에게 보낸다.
    _partner?.recordChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nearbyInvites?.cancel();
    pendingPartnerJoin.removeListener(_joinPending);
    _partner?.removeListener(_partnerChanged);
    _partner?.dispose();
    _proxySend?.cancel();
    _proxyEditor
      ?..removeListener(_persistProxy)
      ..dispose();
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
            // 위 막대에는 … 와 완료뿐이다. 나머지는 전부 메뉴 안에 — 버튼이 넷씩
            // 늘어서 있으면 어느 것도 눈에 안 들어온다.
            CupertinoButton(
              key: const ValueKey('record-menu'),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              onPressed: _showMenu,
              child: Icon(
                CupertinoIcons.ellipsis_circle,
                size: 21,
                semanticLabel: l.recordMenu,
              ),
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
                    onTap: _openPartnerSheet,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(gutter, 2, gutter, 2),
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
                              // 연결이 끊긴 동안은 그 말만 — 세션 이름까지 한 줄에 넣으면
                              // 정작 이 상태가 말줄임표에 잘렸다.
                              !_partner!.reachable
                                  ? l.partnerReconnecting
                                  : [
                                      if (widget
                                          .note
                                          .partner!
                                          .routinePlanning) ...[
                                        l.partnerRoutinePlanning,
                                        l.partnerRoutineProgress(
                                          widget
                                              .note
                                              .partner!
                                              .routineAcceptedCount,
                                          widget
                                              .note
                                              .partner!
                                              .routineParticipantCount,
                                        ),
                                      ] else if (widget
                                          .note
                                          .partner!
                                          .routineReady)
                                        l.partnerRoutineReadyTitle
                                      else
                                        l.partnerWith(
                                          widget.note.partner!.partnerName ??
                                              '',
                                        ),
                                    ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                          if (!_writingFor &&
                              widget.note.partner!.routinePlanning)
                            CupertinoButton(
                              key: const ValueKey(
                                'partner-routine-confirm-editor',
                              ),
                              padding: const EdgeInsets.only(left: 4),
                              minimumSize: const Size(44, 44),
                              onPressed:
                                  widget.note.partner!.myRoutineAccepted ||
                                      !_partner.canConfirmRoutine ||
                                      widget.note.draft?.text
                                              .trim()
                                              .isNotEmpty ==
                                          true
                                  ? null
                                  : () => unawaited(_partner.confirmRoutine()),
                              child: Text(
                                widget.note.partner!.myRoutineAccepted
                                    ? l.partnerRoutineConfirmed
                                    : l.partnerRoutineConfirm,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          if (!_writingFor)
                            CupertinoButton(
                              key: const ValueKey('write-for'),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(44, 44),
                              onPressed: _writeFor,
                              child: Text(
                                l.proxyWrite,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (_endedBy case final name? when !_writingFor)
                  _Strip(
                    key: const ValueKey('partner-ended'),
                    text: l.partnerEndedByThem(name),
                    action: l.ok,
                    onAction: () => setState(() => _endedBy = null),
                  ),
                if (_offered != null && !_writingFor)
                  _Strip(
                    key: const ValueKey('handoff-offer'),
                    text: l.handoffOffer(_offered!.from),
                    action: l.handoffTake,
                    onAction: () => widget.onTakeHandoff!(_offered!.token),
                  ),
                if (_writingFor)
                  _Strip(
                    key: const ValueKey('proxy-bar'),
                    strong: true,
                    text: [
                      l.proxyWriting(
                        widget.note.proxy!.name.isEmpty
                            ? l.proxyDefaultName
                            : widget.note.proxy!.name,
                      ),
                      if (_proxyError == HandoffError.network)
                        l.partnerReconnecting
                      else if (_proxyError == HandoffError.signInRequired)
                        l.partnerSignIn,
                    ].join(' · '),
                    action: l.proxyHand,
                    onAction: widget.note.proxy!.blocks.isEmpty
                        ? null
                        : _handOver,
                    second: l.proxyBack,
                    onSecond: () => setState(() => _writingFor = false),
                  ),
                if (_writingFor)
                  Expanded(
                    child: RoutineEditor(
                      // 다른 칸을 적는 다른 편집기다. 내 기록의 타이머·식단·공유가
                      // 여기로 새지 않게 아무것도 넘기지 않는다.
                      key: const ValueKey('proxy-editor'),
                      countAloud: widget.store.countAloud,
                      controller: _proxyEditor!,
                      ai: widget.ai,
                    ),
                  )
                else
                  Expanded(
                    child: RoutineEditor(
                      key: const ValueKey('own-editor'),
                      countAloud: widget.store.countAloud,
                      controller: _editor,
                      partner: _partner,
                      // 같이 고치는 사람들이 지금 만지는 자리와, 내가 만지는 자리.
                      presence:
                          widget.note.partner?.state == PartnerState.active
                          ? widget.note.partner!.presence
                          : const [],
                      onPresence: _partner == null
                          ? null
                          : (block, set, text) => _partner.presence(
                              block: block,
                              set: set,
                              text: text,
                            ),
                      ai: widget.ai,
                      header: _DocumentHeader(
                        key: _documentHeaderKey,
                        note: widget.note,
                        store: widget.store,
                        ai: widget.ai,
                        account: widget.account,
                        mealText: _mealText,
                        onMealsChanged: _mealsChanged,
                        estimating: _estimatingMeals,
                        onRetryMeal: _estimateMealText,
                        // 같이 하기의 문. 메뉴 안에만 두면 있는 줄도 모른다.
                        onPartner:
                            _partner != null &&
                                (widget.account?.signedIn ?? false)
                            ? _openPartnerSheet
                            : null,
                        partnerActive:
                            widget.note.partner?.state == PartnerState.active,
                      ),
                      emptyHint: ListenableBuilder(
                        listenable: widget.store,
                        builder: (_, _) =>
                            widget.store.firstRunHintSeen ||
                                widget.store.notes.length > 1
                            ? const SizedBox.shrink()
                            : FirstRunHint(
                                onClose: widget.store.dismissFirstRunHint,
                              ),
                      ),
                      footer: switch (_lastWeek) {
                        (final n, final w) => Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: _PastCard(
                            note: n,
                            title:
                                (w == 1
                                ? l.lastWeekDay
                                : (String a, String b) =>
                                      l.weeksAgoDay(w, a, b))(
                                  l.weekdayLabel(n.createdAt),
                                  l.routineDate(n.createdAt),
                                ),
                          ),
                        ),
                        _ => null,
                      },
                      mealText: _mealText,
                      onMealText: _saveMealText,
                      recentMeals: <String>{
                        for (final n in widget.store.notes)
                          for (final m in n.meals.reversed)
                            if (m.text != null) ?m.currentText,
                      }.take(24).toList(),
                      doneExercises: () => widget.store.doneExercises,
                      initialDraft: widget.note.draft,
                      onDraftChanged: (draft) =>
                          widget.store.updateDraft(widget.note, draft),
                      onForgetExercise: widget.store.forgetExercise,
                      records: (b) => _records()[b.id] ?? const {},
                      onMealPhoto: () =>
                          _documentHeaderKey.currentState?._pick(),
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
    this.account,
    this.mealText,
    this.onMealsChanged,
    this.estimating = const {},
    this.onRetryMeal,
    this.onPartner,
    this.partnerActive = false,
  });
  final Note note;
  final NotesStore store;
  final RecordAi ai;

  /// 같이 하기 창을 연다. 로그인하지 않았으면 null — 단추가 없다.
  final VoidCallback? onPartner;

  /// 같이 운동 중이다. 단추에 점을 찍는다.
  final bool partnerActive;

  /// 다니는 도장이 있으면 이 기록이 트레이너에게 가는지 한 줄로 말한다.
  final Account? account;

  /// 어림을 기다리는 끼니와, 열량을 모르는 글 끼니를 다시 어림하는 길.
  final Set<MealEntry> estimating;
  final Future<void> Function(MealEntry)? onRetryMeal;

  /// 식단 글은 아래 입력 줄에서 친다. 여기서는 그 모드를 켜기만 한다.
  final ValueNotifier<({String text, int? index})?>? mealText;

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
  /// 그날 에너지 세 칸을 펼쳤는가. 기본은 접힌 한 줄.
  bool _energyOpen = false;

  /// 건강 앱이 잰 그날 휴식 에너지. 없으면 몸 정보로 셈한다([basalFor]).
  static final _health = HealthLink();
  double? _measuredBasal;

  Future<void> _loadBasal() async {
    final day = dayOf(widget.note.createdAt);
    final next = day.add(const Duration(days: 1));
    final now = DateTime.now();
    final got = await _health.basalEnergy(day, now.isBefore(next) ? now : next);
    if (mounted && got != _measuredBasal) setState(() => _measuredBasal = got);
  }

  bool _estimating = false;

  /// 머리의 알림 한 줄과, 그것이 어느 끼니의 어림 실패인가(사진 쪽 말이면 null).
  /// 끼니는 그 객체다 — 고치면 새 객체라, 고치거나 지운 끼니의 말은 보이지 않는다.
  ({String text, MealEntry? meal})? _error;

  /// 보일 알림. 그 끼니가 이 문서에 그대로 있을 때만 — 사람이 열량을 적어
  /// 고쳤거나 지웠으면 '어림하지 못했어요' 는 이제 틀린 말이다.
  String? get _notice {
    final e = _error;
    return e == null || e.meal == null || note.meals.contains(e.meal)
        ? e?.text
        : null;
  }

  Note get note => widget.note;

  // 식단은 아래 입력 줄에서도 저장된다. 저장소가 바뀌면 다시 그린다.
  void _onStore() => setState(() {});

  /// 식단 글 끼니 [meal] 의 어림이 막힌 이유를 사진 쪽과 같은 자리에 적는다.
  /// null 이면 지우되, **그 끼니가 남긴 말만** 지운다 — 다른 끼니의 어림이
  /// 붙었다고 앞 끼니의 '모르는 음식' 을 덮지 않는다.
  void tell(String? message, MealEntry meal) {
    if (message == null && _error?.meal != meal) return;
    setState(
      () => _error = message == null ? null : (text: message, meal: meal),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
    widget.account?.addListener(_onStore);
    unawaited(_loadBasal());
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    widget.account?.removeListener(_onStore);
    super.dispose();
  }

  /// 이 기록이 트레이너에게 가는가 — 회원이 화면에서 알 수 있어야 한다. 같은 날 기록이
  /// 가는 것과 안 가는 것으로 갈렸는데, 어느 것인지 볼 데가 없었다. 다니는 도장이
  /// 없으면 줄도 없다. 두 번째 값은 사람이 손써야 하는 줄인가.
  (String, bool)? _shareLine(L l) {
    final a = widget.account;
    if (a == null || !a.signedIn) return null;
    if (note.gymId != null) {
      // 헬스장은 신호가 나쁘다 — 아직 한 번도 못 올렸으면 그렇다고 말한다(올라가면
      // [sendPending] 이 sentAt 을 찍고 이 줄이 바뀐다). 루틴을 열어만 본 기록은
      // 보내지 않으니([needsSend]) 기다린다고 하지 않는다.
      return note.uploadRejected
          ? (l.shareRejected, true)
          : note.sentAt == null && needsSend(note)
          ? (l.shareSending, false)
          : (l.shareGym, false);
    }
    if (a.gyms.isEmpty) return null;
    // 묶인 도장과 지금 나누고 있을 때만 끼니가 간다(syncMeals).
    final meals =
        note.mealGymId != null && note.mealGymId == widget.store.shareMealsGym;
    return (meals ? l.shareMealsOnly : l.shareNone, false);
  }

  /// 도장에서 바뀐 PT(거절·취소·시간·확정). 원격 푸시가 없고 앱은 이 편집기로
  /// 켜지므로, 목록까지 가지 않아도 보이게 여기에도 한 줄 — 누르면 그 도장 화면이 열리고
  /// 본 것이 된다. 공지는 목록의 도장 줄에만 둔다.
  (Gym, String)? _ptNews(L l) {
    final a = widget.account;
    if (a == null) return null;
    for (final gym in a.gyms) {
      final news = [
        for (final n in unseenNews(a, widget.store, gym))
          if (n.booking != null) n,
      ];
      if (news.isEmpty) continue;
      final first = newsText(l, gym, news.first);
      return (
        gym,
        news.length == 1 ? first : l.newsMore(first, news.length - 1),
      );
    }
    return null;
  }

  /// 스티커 없이 온 날(폰에 NFC 가 없다, 잊었다). 회원이 '오늘 이 체육관에서 한 운동' 이라고
  /// 스스로 보낸다 — 출석도 같이 남는다. 오늘 기록에 내가 적은 세트가 있고 다니는 도장이
  /// 하나일 때만. 한 폰을 둘이 쓰면 남의 기록에는 없다(NotesStore.visit 와 같은 규칙).
  bool get _canSend {
    final a = widget.account;
    if (a == null ||
        !a.signedIn ||
        note.gymId != null ||
        a.gyms.length != 1 ||
        !note.ownedBy(a.userId)) {
      return false;
    }
    final now = DateTime.now(), c = note.createdAt;
    return c.year == now.year &&
        c.month == now.month &&
        c.day == now.day &&
        note.blocks.any((b) => b.sets.any((s) => s.mine));
  }

  Future<void> _sendToGym() async {
    final a = widget.account!;
    final gym = a.gyms.single;
    final yes = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            L.of(ctx).shareSendAsk(gym.name),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(L.of(ctx).cancel),
          ),
          CupertinoDialogAction(
            key: const ValueKey('share-send-yes'),
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(L.of(ctx).shareSend),
          ),
        ],
      ),
    );
    if (yes != true || !mounted || note.gymId != null) return;
    widget.store.attend(note, gym.id, a.userId);
    // 기다리지 않는다 — 못 보냈으면 편집기를 닫을 때·앱을 다시 올릴 때 간다.
    unawaited(sendPending(a.link, [note], onSent: widget.store.touch));
    unawaited(
      syncMeals(
        a.link,
        [note],
        shareMealsGym: widget.store.shareMealsGym,
        onSynced: widget.store.touch,
      ),
    );
  }

  Future<void> _addMeal(ImageSource source) async {
    final l = L.of(context);
    // 사진을 고르기 전에 본다 — 고른 뒤에 막히면 헛걸음이다. 꺼 두었으면
    // 글로 적는 길을 말한다(적은 kcal 은 그대로 들어간다).
    if (!widget.ai.allowed) {
      setState(() => _error = (text: l.aiOffPhoto, meal: null));
      return;
    }
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
      if (mounted) setState(() => _error = (text: l.mealFailed, meal: null));
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
        // OCR values stay editable beside the original photo until confirmed.
        if (!mounted) return;
        setState(() => _estimating = false);
        final picked = await askMealAmount(
          context,
          bases: basesOf(label),
          title: label.product,
          note: l.mealLabelReviewNote,
          photo: bytes,
          allowUnitEdit: true,
        );
        if (picked == null || !mounted) return;
        note.meals.add(_measured(picked, MealEntry.label, label.product));
      } else {
        if (!mounted) return;
        setState(() => _estimating = false);
        final reviewed = await reviewMealEstimate(
          context,
          estimate,
          photo: bytes,
        );
        if (reviewed == null || !mounted) return;
        final kcal = reviewed.kcal.round();
        note.meals.add(
          MealEntry(
            at: note.mealTime(),
            kcal: kcal,
            items: estimate.confirmedItems,
            reviewedText: reviewed.text,
            source: MealEntry.estimate,
            sources: reviewed.sources ?? estimate.sources,
            macros: reviewed.macros,
            basis: MealBasis(
              kcal: reviewed.kcal,
              amount: 1,
              unit: MealBasis.photo,
            ),
            eaten: 1,
          ),
        );
      }
      _changed();
    } on RecordAiException catch (e) {
      _error = (
        text: switch (e.status) {
          RecordAiStatus.quotaExceeded => l.inputQuotaSpent,
          RecordAiStatus.aiOff => l.aiOffPhoto,
          RecordAiStatus.busy => l.aiBusy,
          RecordAiStatus.budgetExhausted => l.aiBudgetExhausted,
          _ => l.mealFailed,
        },
        meal: null,
      );
    } catch (_) {
      _error = (text: l.mealFailed, meal: null);
    }
    if (mounted) setState(() => _estimating = false);
  }

  /// 근거와 먹은 양으로 한 끼를 만든다. 열량은 여기서 한 번만 반올림된다.
  void _changed() => (widget.onMealsChanged ?? widget.store.touch)();

  /// 끼니를 지운다. 묻고 지운다 — 땀 묻은 손이 '다시 어림' 옆의 × 를 스치면 사진
  /// 어림까지 붙은 끼니가 사라지고 서버에서도 지워졌다. 기록 지우기와 같은 창이다.
  Future<void> _deleteMeal(MealEntry meal) async {
    final l = L.of(context);
    final yes = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l.mealDeleteAsk(meal.description)),
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
    );
    if (yes != true || !mounted) return;
    note.removeMeal(meal);
    _changed();
    setState(() {});
  }

  MealEntry _measured(
    ({MealBasis basis, double eaten}) picked,
    String source,
    String? name, {
    MealEntry? old,
  }) => MealEntry(
    id: old?.id, // 양을 고친 끼니는 서버의 같은 줄이다.
    at: old?.at ?? note.mealTime(),
    kcal: picked.basis.kcalFor(picked.eaten),
    items: old != null && old.basis?.unit == MealBasis.photo
        ? old.items
        : [?name],
    source: source,
    basis: picked.basis,
    eaten: picked.eaten,
    reviewedText: old?.reviewedText,
    // 양만 고쳤다. 100g 당 값은 그대로라 근거도 그대로다.
    sources: old?.sources ?? const [],
  );

  /// 끼니 한 줄을 눌렀다. 글로 적은 것은 입력 줄로 불러 고치고, 근거가 있는
  /// 것은 먹은 양을 다시 받는다. 저장된 열량에 또 곱하지 않는다 — 근거에서
  /// 다시 계산해 **그 자리를** 바꾼다.
  Future<void> _editMeal(int index) async {
    final meal = note.meals[index];
    if (meal.text != null) {
      widget.mealText?.value = (text: meal.currentText!, index: index);
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
    if (picked == null ||
        !mounted ||
        index >= note.meals.length ||
        note.meals[index] != meal) {
      return;
    }
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
      // 식단 단추는 아이콘 하나다 — 사진·앨범·글을 여기서 고른다. 글자 단추 둘은
      // 운동 후보 칩 자리를 먹었다.
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l.mealAdd),
        message: Text(l.mealTypeHint),
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
          if (widget.mealText case final text?)
            CupertinoActionSheetAction(
              key: const ValueKey('meal-text-toggle'),
              onPressed: () {
                Navigator.pop(ctx);
                text.value = (text: '', index: null);
              },
              child: Text(l.mealWrite),
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
    final log = dayLogs(
      widget.store.notes,
      from: at,
      to: at,
      weightOn: widget.store.weightOnDay,
    ).firstOrNull;
    final record = recordOn(dayOf(at), widget.store.bodyRecords);
    final basal = basalFor(
      dayOf(at),
      widget.store.body,
      measured: _measuredBasal,
      record: record,
    );
    // 운동 목적을 정했으면 그날의 탄단지 목표 — 먹은 것과 나란히 보인다.
    final target = macroTarget(
      goal: widget.store.body.goal,
      weightKg: widget.store.weightOnDay(at),
      bmrPerDay: bmrOn(dayOf(at), widget.store.body, record),
      exerciseKcal: log?.burned ?? 0,
      leanKg: leanOf(record),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.onPartner == null)
            Text(
              '${l.dayLabel(at)} · ${l.weekdayLabel(at)}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: muted),
            )
          else
            // 날짜는 가운데 그대로, 오른쪽 끝에 같이 하기. 왼쪽에 같은 폭을 비워 둔다.
            Row(
              children: [
                const SizedBox(width: 44),
                Expanded(
                  child: Text(
                    '${l.dayLabel(at)} · ${l.weekdayLabel(at)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ),
                CupertinoButton(
                  key: const ValueKey('header-partner'),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  onPressed: widget.onPartner,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        CupertinoIcons.person_2,
                        size: 20,
                        color: widget.partnerActive
                            ? seal.resolveFrom(context)
                            : muted,
                        semanticLabel: l.partnerInvite,
                      ),
                      if (widget.partnerActive)
                        Positioned(
                          key: const ValueKey('header-partner-dot'),
                          right: -2,
                          top: -1,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: seal.resolveFrom(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          if (_shareLine(l) case (final text, final act)?)
            Padding(
              key: const ValueKey('share-line'),
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: act ? seal.resolveFrom(context) : muted,
                ),
              ),
            ),
          if (_canSend)
            Center(
              child: CupertinoButton(
                key: const ValueKey('share-send'),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(44, 44),
                onPressed: _sendToGym,
                child: Text(l.shareSend, style: const TextStyle(fontSize: 13)),
              ),
            ),
          if (_ptNews(l) case (final gym, final text)?)
            Center(
              child: CupertinoButton(
                key: const ValueKey('pt-news'),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(44, 44),
                onPressed: () =>
                    openGym(context, widget.account!, widget.store, gym.id),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: seal.resolveFrom(context),
                  ),
                ),
              ),
            ),
          // 그날 에너지는 한 줄로 접어 둔다 — 운동을 적는 화면에서 세 칸은 컸다.
          // 누르면 먹은 것 · 운동 · 차이 세 칸. 둘 다 없는 날은 줄도 없다.
          if (log != null &&
              (log.intake != null || log.burned != null || basal != null))
            Padding(
              key: const ValueKey('day-summary'),
              padding: const EdgeInsets.only(bottom: 2),
              // 한 줄 ↔ 세 칸을 부드럽게 바꾼다.
              child: AnimatedSize(
                duration: Unfold.duration,
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: Unfold.duration,
                  child: _energyOpen
                      // 펼친 뒤에는 접는 자리가 보여야 한다 — 칸을 눌러도 접히지만
                      // 그것은 알 수 없었다.
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            DayEnergy(log, basal: basal),
                            if (log.macros != null || target != null)
                              DayMacros(
                                log,
                                target: target,
                                onGoal: () => Navigator.of(context).push(
                                  CupertinoPageRoute<void>(
                                    builder: (_) => BodyPage(
                                      store: widget.store,
                                      ai: widget.account?.ai,
                                    ),
                                  ),
                                ),
                              ),
                            CupertinoButton(
                              key: const ValueKey('day-summary-fold'),
                              padding: const EdgeInsets.only(top: 2),
                              minimumSize: const Size(44, 44),
                              onPressed: () =>
                                  setState(() => _energyOpen = false),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l.fold,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const Icon(
                                    CupertinoIcons.chevron_up,
                                    size: 13,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : GestureDetector(
                          key: const ValueKey('day-summary-line'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _energyOpen = true),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: minTap,
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    [
                                      energyLine(l, log, basal),
                                      if ((log.difference ?? 0) > 0)
                                        l.energySurplus,
                                      if ((log.difference ?? 0) < 0)
                                        l.energyDeficit,
                                    ].join(' · '),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: muted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  CupertinoIcons.chevron_down,
                                  size: 12,
                                  color: muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
          if (note.meals.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final (i, meal) in note.meals.indexed)
              Row(
                children: [
                  Expanded(
                    // 먹은 것이 앞, 열량은 오른쪽 끝에 — 줄마다 같은 자리라 훑어 읽힌다.
                    // 어림이라는 것은 위 '먹은 것' 칸의 추정 표시가 말한다.
                    child: GestureDetector(
                      key: ValueKey('meal-$i'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _editMeal(i),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: minTap),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                [
                                  meal.description,
                                  if (meal.basis != null &&
                                      meal.eaten != null &&
                                      !(meal.basis!.unit == MealBasis.photo &&
                                          meal.eaten == 1))
                                    mealEatenText(l, meal.basis!, meal.eaten!),
                                ].where((t) => t.isNotEmpty).join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.label.resolveFrom(
                                    context,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.estimating.contains(meal)
                                  ? l.mealEstimating
                                  : meal.kcal == null
                                  ? l.mealKcalUnknown
                                  : meal.partial
                                  ? l.kcalAtLeast(meal.kcal!)
                                  : [
                                      l.kcal(meal.kcal!),
                                      if (meal.macros case final m?)
                                        mealMacrosText(l, m),
                                    ].join(' · '),
                              style: TextStyle(
                                fontSize: 13,
                                color: muted,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 글은 있는데 열량을 (다) 모른다 — 그 자리에서 다시 어림한다.
                  // 어림을 기다리는 동안은 줄이 그렇다고 말하니 단추를 두지 않는다.
                  if (widget.onRetryMeal != null &&
                      meal.text != null &&
                      (meal.kcal == null || meal.partial) &&
                      !widget.estimating.contains(meal))
                    CupertinoButton(
                      key: ValueKey('meal-retry-$i'),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(44, 44),
                      onPressed: () {
                        widget.onRetryMeal!(meal);
                        setState(() {});
                      },
                      child: Text(
                        l.mealRetry,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  // 표에서 찾은 값으로 셈했으면 그 표를 보여 준다 — 숫자만으로는 믿을 까닭이 없다.
                  if (meal.sources.isNotEmpty)
                    CupertinoButton(
                      key: ValueKey('meal-sources-$i'),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(44, 44),
                      onPressed: () => showMealSources(context, meal.sources),
                      child: Text(
                        l.mealSources,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  CupertinoButton(
                    key: ValueKey('meal-delete-$i'),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    onPressed: () => _deleteMeal(meal),
                    child: Icon(
                      CupertinoIcons.xmark,
                      size: 14,
                      color: muted,
                      semanticLabel: l.delete,
                    ),
                  ),
                ],
              ),
          ],
          if (_notice case final notice?)
            Text(
              notice,
              style: TextStyle(fontSize: 13, color: seal.resolveFrom(context)),
            ),
          // 식단 사진·글 버튼은 여기 없다. 입력 줄 위의 막대에 같은 것이 늘 있어서
          // 화면 맨 위에 또 둘 이유가 없었다. 사진을 읽는 동안이라는 것만 알린다.
          if (_estimating)
            Text(
              l.mealEstimating,
              style: TextStyle(fontSize: 13, color: muted),
            ),
          // 여기까지가 하루·식단, 아래부터가 운동이다. 줄 하나가 두 동네를 가른다 —
          // 버튼을 여기 두었을 때는 어느 쪽 것인지 헷갈렸다.
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              key: const ValueKey('section-divider'),
              height: 0.5,
              color: CupertinoColors.separator.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// 지난 운동 한 장 — 기본은 접힌 한 줄("지난주 금요일(9. 18.) 운동 · 스쿼트 외 3개"),
/// 누르면 세트까지 읽기 전용으로 펼친다. 펼친 채로 두면 지금 적는 기록보다 길어
/// 무엇을 적는 중인지 흐려졌다.
class _PastCard extends StatefulWidget {
  const _PastCard({required this.note, required this.title});
  final Note note;
  final String title;

  @override
  State<_PastCard> createState() => _PastCardState();
}

class _PastCardState extends State<_PastCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final n = widget.note;
    final names = n.blocks.map((b) => b.name).toSet().toList();
    final what = names.length <= 1
        ? names.join()
        : l.sameDayMore(names.first, names.length - 1);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            key: ValueKey('past-${n.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: minTap),
              child: Row(
                children: [
                  Icon(CupertinoIcons.calendar, size: 14, color: muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: widget.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (what.isNotEmpty && !_open)
                            TextSpan(text: ' · $what'),
                        ],
                      ),
                      maxLines: _open ? null : 1,
                      overflow: _open ? null : TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                  ),
                  UnfoldChevron(open: _open, color: muted),
                ],
              ),
            ),
          ),
          // 지난 운동은 무엇을 얼마나 했는지만 — 그날 메모는 뺀다.
          Unfold(
            open: _open,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final b in n.blocks) BlockSummary(block: b, notes: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 기록 화면 위의 한 줄 — 무슨 일이 벌어지고 있는지와, 누를 것 하나둘.
class _Strip extends StatelessWidget {
  const _Strip({
    super.key,
    required this.text,
    required this.action,
    required this.onAction,
    this.second,
    this.onSecond,
    this.strong = false,
  });
  final String text, action;
  final VoidCallback? onAction;
  final String? second;
  final VoidCallback? onSecond;

  /// 내 기록이 아닌 것을 적는 중이다. 헷갈리면 안 되는 상태라 색을 입힌다.
  final bool strong;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(gutter, 4, gutter, 0),
    padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
    decoration: BoxDecoration(
      color: strong
          ? seal.resolveFrom(context).withValues(alpha: 0.12)
          : CupertinoColors.secondarySystemBackground.resolveFrom(context),
      borderRadius: BorderRadius.circular(radiusCard),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        if (second != null)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(44, 44),
            onPressed: onSecond,
            child: Text(second!, style: const TextStyle(fontSize: 13)),
          ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(44, 44),
          onPressed: onAction,
          child: Text(
            action,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
