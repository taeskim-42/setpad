import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_route.dart';
import 'package:path_provider/path_provider.dart';

import 'agent_alarm.dart';
import 'gym.dart';
import 'notes.dart';
import 'purchases.dart';
import 'record_ai.dart';
import 'sign_in.dart';

/// 서버가 구매를 받지 않은 이유. 화면이 사람에게 그대로 말한다.
enum PurchaseProblem {
  /// 스토어에 확인되지 않았거나 서버에 닿지 못했다. 복원으로 다시 보낼 수 있다.
  notConfirmed,

  /// 이 구매는 이미 다른 계정에 붙어 있다.
  otherAccount,
}

/// 원판의 하루는 한국 시각으로 센다 — 서버와 같은 날이어야 한 번이 한 번이다.
String kstDay(DateTime t) =>
    t.toUtc().add(const Duration(hours: 9)).toIso8601String().substring(0, 10);

/// 하루 원판 한 장을 받는 문턱. 서버도 같은 수를 본다.
const dailyPlateSets = 10;

/// 계정을 처음 만들면 받는 원판. 서버의 환영 원판과 같은 수여야 한다.
const accountWelcomePlates = 5;

/// 내가 일하는 도장. /api/me 가 준다.
typedef StaffGym = ({String gymId, String gym});

/// 로그인과 결제를 한자리에서 든다.
///
/// **앱은 권한을 만들지 않는다.** 스토어가 "샀다" 고 하는 것을 그대로 믿으면
/// 그 말을 흉내 내는 것만으로 유료가 된다. 앱이 하는 일은 증거를 서버에
/// 넘기는 것까지고, 무엇을 가졌는지는 서버가 돌려주는 답이 정한다.
class Account extends ChangeNotifier {
  Account({
    this.endpoint = RecordAi.defaultEndpoint,
    Purchases? purchases,
    this.client,
    this.storageDir,
    this.deviceId,
    this.aiEnabled,
    Future<Credential?> Function(SignInMethod)? signInWith,
  }) : _purchases = purchases ?? Purchases() {
    _signInWith = signInWith ?? (method) => signInWithMethod(method, endpoint);
    _purchases.onProof = _send;
  }

  final String endpoint;
  final Purchases _purchases;

  /// 테스트가 끼워 넣는 자리. 비어 있으면 진짜 그물을 쓴다.
  final http.Client? client;

  /// 테스트가 쓸 임시 폴더. 비어 있으면 앱 문서함에 쓴다.
  final Directory? storageDir;

  /// 이 기기의 id. 기기 id 는 저장소를 읽은 뒤에 생기므로 부를 때 읽는다.
  final String Function()? deviceId;

  /// AI 도움이 켜져 있는가([RecordAi.enabled]).
  final bool Function()? aiEnabled;

  /// 제공자 로그인 창을 여는 일. 테스트는 진짜 애플 창을 열 수 없다.
  late final Future<Credential?> Function(SignInMethod) _signInWith;

  /// 로그인해서 받은 우리 토큰. 없으면 로그인하지 않은 것이다.
  String? token;
  String nickname = '';

  /// 로그인한 사람의 id(/api/me 의 user.id). 이 기기의 기록에 주인을 적고, 밀린
  /// 것을 그 주인의 토큰으로만 보내는 데 쓴다(Note.owner). 아직 모르면 null.
  String? userId;

  /// 이 계정에 붙은 로그인 수단(`apple`·`google`·`kakao`). /api/me 가 알려 준다.
  /// 설정 화면은 여기 없는 수단을 "연결" 로 보여 준다.
  List<String> providers = const [];

  /// 서버가 확인해 준 것. 앱이 정하지 않는다.
  Plan? plan;

  /// 다음 App Store 구매에 실을 표(appAccountToken, GET /api/purchase 가 준다). 산
  /// 구매가 이 계정·기기에 묶여, 새어 나간 거래 id 만으로는 남이 가져가지 못한다. 모르면
  /// 없이 산다 — 서버는 표 없는 구매를 예전처럼 받는다.
  String? purchaseTag;

  /// 이 지갑(계정·기기)의 이용권을 서버에서 읽었다. 못 읽었으면 [reloadStore] 가 다시 묻는다.
  bool _purchaseKnown = false;

  /// 스토어에서 요금제를 읽는 중. 결제 화면은 그동안 '연결하지 못했다' 고 하지 않는다.
  bool storeLoading = false;

  /// **이용권을 팔고 있는가.** 서버가 정한다.
  ///
  /// 스토어에 상품을 올려 두는 것과 앱에서 파는 것은 다른 결정이다. 앱에
  /// 박아 두면 마음이 바뀔 때마다 심사를 다시 받아야 한다. 기본은 안 파는
  /// 것이다 — 서버에 못 닿았을 때 파는 화면이 뜨는 것보다 안 뜨는 편이 낫다.
  bool selling = false;

  /// 내가 다니는 체육관과 도장이 알리는 것. 없으면 앱은 그쪽 화면을 아예 안 그린다.
  List<Gym> gyms = const [];

  /// 아직 답하지 않은 도장 초대. 받아야 회원이 된다.
  List<GymInvite> invites = const [];

  /// 이 로그인으로 /api/gyms 를 받아 왔는가. 받기 전의 빈 목록은 '다니는 곳 없음' 이
  /// 아니다 — 도장 소식은 받아 온 것끼리만 견준다(처음 받은 것은 모두 본 것으로 친다).
  bool gymsLoaded = false;

  /// 직원으로 있는 도장. 비어 있으면 트레이너 화면이 아예 없다. /api/me 에
  /// 물어볼 때마다 새 목록이 된다 — 목록 화면은 그것으로 다시 읽을 때를 안다.
  List<StaffGym> staff = const [];

  /// 체육관에서 온 것들을 가져오는 문. 로그인하지 않았으면 아무것도 안 온다.
  GymLink get link => GymLink(
    endpoint: endpoint,
    token: token,
    userId: userId,
    client: client,
    onUnauthorized: _recheck,
  );

  Future<void>? _rechecking;

  /// 어느 길에서든 서버가 계정 토큰을 거절했다(401). /api/me 로 한 번 확인한다 —
  /// 정말 죽었으면 로그아웃하고([_stillValid]), 그물 탓이면 그대로 둔다. 같이 하기의
  /// 2초 폴링처럼 겹쳐 와도 묻는 것은 한 번이다. 로그아웃하면 토큰이 없어 그 길들은
  /// 더 묻지 않는다.
  void _recheck() {
    if (token == null) return;
    _rechecking ??= _stillValid().whenComplete(() => _rechecking = null);
  }

  /// AI 에 묻는 문. 로그인했으면 계정의 지갑, 아니면 이 기기의 지갑을 쓴다.
  RecordAi get ai => RecordAi(
    endpoint: endpoint,
    deviceId: deviceId?.call() ?? '',
    client: client,
    accountToken: () => token,
    onPlates: _setPlates,
    // 모든 기기에서 로그아웃하는 중에 받은 401 은 이 폰의 로그아웃이 아니다 — 새 토큰이 곧 온다.
    onUnauthorized: () async {
      if (!_revoking) await signOut();
    },
    enabled: aiEnabled,
  );

  /// 남은 원판. 서버가 알려 준 값이고, 모르면 null.
  double? plates;

  /// 방금 기록 질문 하나에 쓴 원판. 지갑만 다시 읽었으면 null.
  double? platesSpent;

  /// 서버가 방금 받은 구매를 거절했다. 다음 구매를 누르면 지운다.
  PurchaseProblem? purchaseProblem;

  void _setPlates(double balance, double? spent) {
    plates = balance;
    platesSpent = spent;
    notifyListeners();
  }

  /// 원판을 다시 읽는다. 로그인이 바뀌면 지갑도 바뀐다.
  Future<void> refreshPlates() => ai.plates();

  bool _claiming = false;
  DateTime? _claimFailedAt;

  /// 오늘 끝낸 세트가 [dailyPlateSets] 개를 넘으면 원판 한 장을 받는다.
  /// 서버가 받으면 그날을 기억해 다시 묻지 않는다.
  ///
  /// 기록은 이 기기에만 있어 서버는 세트를 셀 수 없다. 앱이 센 수를 보내고,
  /// 서버는 한 지갑에 하루 한 장만 준다. **그래서 기억도 지갑마다다** — 기기
  /// 지갑으로 받은 날 로그인하면 계정 지갑은 그날 몫을 따로 받는다. 같은 날
  /// 다시 물어도 서버가 한 번만 주므로 해가 없다.
  Future<void> claimDaily(NotesStore store, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final day = '${signedIn ? 'account:$nickname' : 'device'}:${kstDay(at)}';
    if (_claiming || store.platesDay == day) return;
    // 못 보냈으면 잠시 쉰다. 세트를 칠 때마다 막힌 길을 두드리지 않는다.
    final failed = _claimFailedAt;
    if (failed != null && at.difference(failed) < const Duration(minutes: 5)) {
      return;
    }
    final sets = store.notes
        .where((n) => kstDay(n.createdAt) == kstDay(at))
        .expand((n) => n.blocks)
        .expand((b) => b.sets)
        // 같이 고친 기록의 옆 사람 세트는 내 기록이 아니다.
        .where((s) => s.mine)
        .length;
    if (sets < dailyPlateSets) return;
    _claiming = true;
    try {
      if (await ai.claimDaily(kstDay(at), sets)) {
        store.setPlatesDay(day);
        _claimFailedAt = null;
      } else {
        _claimFailedAt = at;
      }
    } finally {
      _claiming = false;
    }
  }

  bool get signedIn => token != null;
  bool get paid => plan != null;

  /// 스토어가 지금 파는 요금제. 값은 스토어가 준 그대로다.
  Map<Plan, Offer> get offers => _purchases.offers;

  /// 남겨 둔 로그인이 되살아났다(또는 못 살렸다). 스티커·링크·알림 탭은 토큰만
  /// 있으면 되므로 [start] 전체가 아니라 이것만 기다린다 — 스토어 조회·이용권·원판
  /// 물음이 약한 그물에서 늘어지면 스티커가 아무 말 없이 멈춰 있었다.
  Future<void> get restored => _restored.future;
  final _restored = Completer<void>();

  Future<void> start() async {
    try {
      await restoreSession();
    } finally {
      if (!_restored.isCompleted) _restored.complete();
    }
    await _purchases.start(apple: platformSignIn == SignInMethod.apple);
    // **로그인 전에도 묻는다.** 파는지 여부는 사람이 아니라 서버가 정하는
    // 것이고, 서버는 로그인 없이도 답한다. 안 물으면 아직 로그인 안 한
    // 사람에게는 무엇을 파는지도, 무료가 몇 번인지도 영영 안 보인다.
    await _refresh();
    await refreshPlates();
  }

  bool _reloading = false;

  /// 파는데 스토어에서 요금제를 못 읽었다.
  bool get _storeMissing => selling && !paid && offers.isEmpty;

  /// 켤 때 못 읽은 것을 다시 읽는다 — 이 지갑의 이용권·파는지(서버)와 스토어의 요금제.
  ///
  /// **켤 때 한 번만 읽으면 그 실행 동안 살 수 없었다.** 지하 헬스장처럼 신호 없는
  /// 곳에서 켜면 Pro 로 가는 길이 숨거나, 결제 화면에 단추 없이 문구만 남았다. 결제
  /// 화면을 열 때와 앱으로 돌아올 때 부른다. 이미 읽었으면 묻지 않는다.
  Future<void> reloadStore() async {
    if (_reloading || (_purchaseKnown && !_storeMissing)) return;
    // 알리지 않는다 — 결제 화면은 그릴 때 읽고, 화면을 그리는 중에 불릴 수 있다.
    _reloading = storeLoading = true;
    try {
      if (!_purchaseKnown) await _refresh();
      if (_storeMissing) {
        await _purchases.start(apple: platformSignIn == SignInMethod.apple);
      }
    } finally {
      _reloading = storeLoading = false;
      notifyListeners();
    }
  }

  /// 남겨 둔 로그인을 되살린다. 스토어를 건드리지 않아 테스트가 이것만 부른다.
  @visibleForTesting
  Future<void> restoreSession() async {
    await _loadSession();
    if (token != null) await _stillValid();
  }

  // ── 로그인을 기기에 남긴다 ─────────────────────────────────
  //
  // **이것이 없으면 앱을 껐다 켤 때마다 로그아웃이다.** 스티커를 대는 사람은
  // 대개 앱이 꺼진 상태에서 대므로, 댈 때마다 로그인부터 하게 된다. 로그인이
  // 풀렸다 붙었다 하는 것처럼 보이던 것이 이것이다.
  //
  // 키체인에 둔다([vault]). 예전에는 문서함의 session.json(평문)이었고, 그 파일은
  // 기기·PC 백업에 같이 실렸다.

  static const _sessionKey = 'session';

  /// 옛 판이 로그인을 두던 자리. 켤 때 한 번 키체인으로 옮기고 지운다.
  Future<File?> _sessionFile() async {
    if (kIsWeb) return null; // 웹에는 문서함이 없다.
    try {
      final dir = storageDir ?? await getApplicationDocumentsDirectory();
      return File('${dir.path}/session.json');
    } catch (e) {
      debugPrint('세션 파일 자리를 못 찾았다: $e');
      return null;
    }
  }

  Future<void> _loadSession() async {
    try {
      final legacy = await _sessionFile();
      // 키체인은 앱을 지워도 남는다(iOS). 문서함은 같이 지워지므로 거기 표시가 없으면 새로
      // 깐 앱이다 — 지운 사람의 로그인으로 뜨지 않게 남은 것을 버린다. 폰을 넘기거나 다시
      // 깔아 로그아웃하려던 사람의 길이다. 옛 판(session.json)에서 올라온 것은 키체인이 비어
      // 있어 버릴 것이 없다. 기기 토큰은 기기 id 로 가른다(RecordAi._usable).
      final mark = legacy == null
          ? null
          : File('${legacy.parent.path}/installed');
      if (mark != null && !mark.existsSync()) {
        try {
          // 표시를 먼저 남긴다 — 못 남겼으면 버리지 않는다. 켤 때마다 로그아웃되지 않게.
          mark.createSync();
          await vaulted(() => vault.delete(key: _sessionKey));
        } catch (e) {
          debugPrint('설치 표시를 남기지 못했다: $e');
        }
      }
      var saved = await vaulted(() => vault.read(key: _sessionKey));
      if (legacy != null && legacy.existsSync()) {
        // 키체인에 옮겼을 때만 지운다 — 못 옮겼으면 다음에 켤 때 다시 옮긴다.
        if (saved == null) {
          saved = await legacy.readAsString();
          final moved = await vaulted(() async {
            await vault.write(key: _sessionKey, value: saved);
            return true;
          });
          if (moved == true) await legacy.delete();
        } else {
          await legacy.delete();
        }
      }
      if (saved == null) return;
      final data = jsonDecode(saved);
      if (data is! Map) return;
      final token = data['token'];
      if (token is! String || token.isEmpty) return;
      this.token = token;
      nickname = data['nickname'] as String? ?? '';
      userId = data['userId'] as String?;
      notifyListeners();
    } catch (e) {
      // 깨진 값 때문에 앱이 안 뜨면 안 된다. 로그인만 다시 하면 된다.
      debugPrint('남겨 둔 로그인을 읽지 못했다: $e');
    }
  }

  Future<void> _saveSession() async {
    if (token == null) {
      // 로그아웃은 옛 파일까지 지워야 끝난다 — 남으면 다음에 켤 때 옮겨져 다시 로그인된다.
      try {
        final legacy = await _sessionFile();
        if (legacy != null && legacy.existsSync()) await legacy.delete();
      } catch (e) {
        debugPrint('session.json 을 지우지 못했다: $e');
      }
      await vaulted(() => vault.delete(key: _sessionKey));
      return;
    }
    await vaulted(
      () => vault.write(
        key: _sessionKey,
        value: jsonEncode({
          'token': token,
          'nickname': nickname,
          'userId': ?userId,
        }),
      ),
    );
  }

  /// 남겨 둔 토큰이 아직 살아 있는가.
  ///
  /// 토큰은 서른 날이면 죽는다. 죽은 것을 들고 있으면 체육관 목록이 빈 채로
  /// 와서 **다니는 곳이 없는 사람처럼** 보인다 — 등록을 다시 신청하게 된다.
  /// 그물이 없어서 못 물어본 것과 서버가 거절한 것은 다르다. 거절일 때만 지운다.
  Future<bool> _stillValid() async {
    final web = client ?? apiClient;
    final asked = token;
    try {
      // 기다리는 데도 끝이 있어야 한다. 길이 막혔을 때 여기서 매달리면 앱의 나머지
      // (체육관 목록, 밀린 전송)가 같이 멈춘다. 못 물어본 것은 로그아웃이 아니다.
      final response = await web
          .get(
            Uri.parse('$endpoint/api/me'),
            headers: {'authorization': 'Bearer $asked'},
          )
          .timeout(const Duration(seconds: 15));
      // 기다리는 사이 토큰이 바뀌었다 — 모든 기기에서 로그아웃이 이 폰의 새 토큰을 받았거나
      // 다시 로그인했다. 이 답은 옛 토큰의 것이니 새 토큰을 지우거나 덮지 않는다. 지금
      // 끊는 중이면 새 토큰이 아직 오는 중이다 — 그 답도 이 폰의 것이 아니다.
      if (token != asked || _revoking) return true;
      if (response.statusCode == 401) {
        await signOut();
        return false;
      }
      // 서버는 살아 있는 토큰을 볼 때마다 새 것을 같이 준다. 받아 두면 서른
      // 날이 앱을 켠 날부터 다시 세어져, 쓰는 사람은 로그아웃을 안 만난다.
      if (response.statusCode == 200) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          final fresh = body is Map ? body['token'] : null;
          final user = body is Map ? body['user'] : null;
          final id = user is Map ? user['id'] : null;
          var save = false;
          if (fresh is String && fresh.isNotEmpty && fresh != token) {
            token = fresh;
            save = true;
          }
          if (id is String && id != userId) {
            userId = id;
            save = true;
          }
          if (save) await _saveSession();
          final named = body is Map ? body['providers'] : null;
          providers = [
            for (final name in named is List ? named : const [])
              if (name is String) name,
          ];
          final rows = body is Map ? body['staff'] : null;
          staff = [
            for (final row in rows is List ? rows : const [])
              if (row is Map && row['gym_id'] is String)
                (gymId: row['gym_id'] as String, gym: '${row['gym'] ?? ''}'),
          ];
          notifyListeners();
        } catch (_) {
          // 답을 못 읽었을 뿐이다. 알던 토큰을 그대로 쓴다.
        }
      }
      return true;
    } catch (_) {
      return true; // 물어보지 못했을 뿐이다. 알던 것을 그대로 쓴다.
    }
  }

  /// 다니는 체육관을 다시 읽는다. 트레이너가 방금 등록했을 수 있다. 못 물어봤으면
  /// 알던 것을 그대로 둔다 — 신호가 약한 헬스장에서 다니는 곳이 없는 사람이 되지 않게.
  Future<void> refreshGyms() async {
    final found = await link.gyms();
    if (found == null) return;
    gyms = found.gyms;
    invites = found.invites;
    gymsLoaded = true;
    notifyListeners();
  }

  /// 이 도장에서 나간다. 나갔으면 목록에서 바로 뺀다 — 다시 읽기를 못 해도 나간 도장이
  /// 남아 있지 않게.
  Future<bool> leaveGym(String gymId) async {
    if (!await link.leaveGym(gymId)) return false;
    gyms = [
      for (final g in gyms)
        if (g.id != gymId) g,
    ];
    notifyListeners();
    unawaited(refreshGyms());
    return true;
  }

  /// 닉네임을 바꾼다. 바꿨으면 null, 아니면 [MemberLink.changeNickname] 의 까닭.
  Future<String?> changeNickname(String wanted) async {
    // 서버도 이렇게 다듬어 남긴다 — 이 기기에 남기는 것도 같아야 한다.
    final name = wanted.trim().replaceAll(RegExp(r'\s+'), ' ');
    final problem = await link.changeNickname(name);
    if (problem != null) return problem;
    nickname = name;
    await _saveSession();
    notifyListeners();
    return null;
  }

  /// 마지막 로그인이 서버에서 막혔는가.
  ///
  /// **조용히 실패하면 고칠 수가 없다.** 사람이 스스로 닫은 것과 서버가 안
  /// 받아 준 것은 다르다 — 앞은 말할 것이 없고, 뒤는 말해 줘야 한다.
  bool signInRefused = false;

  /// 붙이려던 수단이 이미 다른 계정의 것이라 서버가 거절했다. 로그인은 그대로다.
  bool signInTaken = false;

  /// 마지막으로 시도한 수단. 설정은 실패 문구를 이 수단의 줄에만 붙인다.
  SignInMethod? lastSignIn;

  /// 들어간다. [method] 가 없으면 기기가 직접 하는 수단이다. 이미 로그인해 있으면
  /// 그 계정에 수단을 하나 더 붙인다. [ageConfirmed] 는 로그인 시트의 '만 14세
  /// 이상입니다' 칸이다 — 서버가 계정에 남긴다(만드는 계정도, 이미 있는 계정도).
  Future<bool> signIn({SignInMethod? method, bool ageConfirmed = false}) async {
    signInRefused = signInTaken = false;
    final chosen = method ?? platformSignIn;
    if (chosen == null) return false;
    lastSignIn = chosen;
    Credential? credential;
    try {
      credential = await _signInWith(chosen);
    } on WebSignInFailed {
      signInRefused = true;
      notifyListeners();
      return false;
    } catch (error) {
      // 사람이 창을 닫으면 여기로 온다. 실패가 아니라 그만둔 것이다.
      debugPrint('[로그인] 제공자 단계에서 멈췄다: $error');
      return false;
    }
    if (credential == null) return false;
    final ({String token, String nickname})? result;
    try {
      result = await exchange(
        credential,
        endpoint,
        // 로그인 전이면 기기 토큰이다 — 서버가 이 기기에서 산 것을 계정으로 옮긴다.
        currentToken: await ai.bearer(),
        client: client,
        ageConfirmed: ageConfirmed,
      );
    } on SignInTaken {
      signInTaken = true;
      notifyListeners();
      return signedIn;
    }
    if (result == null) {
      signInRefused = true;
      notifyListeners();
      return false;
    }
    token = result.token;
    nickname = result.nickname;
    RecordAi.forget();
    plates = platesSpent = null;
    await _saveSession();
    await _refresh();
    await refreshPlates();
    await refreshGyms();
    // 직원 도장은 /api/me 만 알려 준다. 켤 때만 물으면 방금 로그인한 트레이너는
    // 다음에 켤 때까지 트레이너 화면을 못 본다.
    await _stillValid();
    notifyListeners();
    return signedIn;
  }

  /// 로그아웃. **남긴 파일을 지우는 것까지가 로그아웃이다** — 지우기 전에
  /// 앱이 죽으면 다음에 켤 때 다시 로그인된 채로 뜬다.
  Future<void> signOut() async {
    token = null;
    nickname = '';
    userId = null;
    // 로그인한 채로 수단을 붙이다 실패한 표시가 로그아웃 뒤 로그인 줄에 남지 않게.
    signInRefused = signInTaken = false;
    lastSignIn = null;
    providers = const [];
    plan = null;
    // 이제 이 기기의 지갑이다. 그 이용권과 구매 표는 결제 화면이 열릴 때 다시 읽는다.
    purchaseTag = null;
    _purchaseKnown = false;
    gyms = const [];
    invites = const [];
    gymsLoaded = false;
    RecordAi.forget();
    plates = platesSpent = null;

    staff = const [];
    // 보고 알림은 기기에 요일마다 걸려 있어 로그인과 함께 풀리지 않는다. 목록
    // 화면은 staff 가 바뀔 때만 지우는데, 켜자마자 토큰이 거절되면 staff 가
    // 처음부터 비어 있어 바뀐 적이 없다. 그래서 여기서 지운다.
    unawaited(AgentAlarm.clearAll());
    notifyListeners();
    await _saveSession();
    // 이제 이 기기의 지갑이다.
    unawaited(refreshPlates());
  }

  /// [signOutEverywhere] 가 서버에 묻는 중이다. 서버가 끊은 직후 옛 토큰으로 나간 요청이
  /// 받은 401 은 새 토큰의 답보다 먼저 올 수 있다 — 그것으로 이 폰을 로그아웃하지 않는다.
  bool _revoking = false;

  /// 모든 기기에서 로그아웃 — 잃어버린 폰이나 백업에서 샌 로그인을 서버에서 끊는다.
  /// 그때까지 나간 이 사람의 토큰은 모두 거절되고, 이 폰은 서버가 준 새 토큰으로
  /// 이어 간다(POST /api/me/sessions/revoke). 끊었으면 true.
  Future<bool> signOutEverywhere() async {
    if (!signedIn) return false;
    _revoking = true;
    final fresh = await link.revokeSessions().whenComplete(
      () => _revoking = false,
    );
    if (fresh == null) return false;
    token = fresh;
    await _saveSession();
    notifyListeners();
    return true;
  }

  /// 탈퇴. 서버가 지운 뒤에 기기에 남은 로그인도 지운다.
  ///
  /// **막혔으면 이유를 그대로 올려 보낸다** — "안 됩니다"만 보여 주면 관장인
  /// 자기 계정을 왜 못 지우는지 알 길이 없다.
  Future<String?> deleteAccount() async {
    if (!signedIn) return null;
    final result = await link.deleteAccount();
    if (!result.ok) return result.reason ?? '';
    await signOut();
    return null;
  }

  /// **로그인 없이 산다**(App Store 5.1.1(v)). 로그인 전에 산 것은 이 기기에
  /// 붙고, 이 기기에서 로그인하면 계정으로 옮겨 가 다른 기기에서도 쓴다.
  Future<bool> buy(Plan wanted) async {
    purchaseProblem = null;
    notifyListeners();
    await _purchases.buy(wanted, appAccountToken: purchaseTag);
    return true;
  }

  /// 애플이 요구한다. 기기를 바꾼 사람의 유일한 길이기도 하다.
  Future<void> restore() async {
    await _purchases.restore();
  }

  /// 스토어가 준 구매를 서버에 넘긴다. **서버의 답을 읽는다** — 거절당했는데
  /// 아무 말이 없으면 돈을 낸 사람은 산 줄 알고 기다린다.
  ///
  /// 서버가 확정해 답했으면 true 다 — 받았다(200), 남의 계정 것(409), 확인되지 않는
  /// 구매(402)·잘못된 요청(400). 그때만 스토어에 거래를 닫는다([Purchases]). 그 밖의 답
  /// (그물·시간 초과·5xx·표 없음·401·426·429, 그리고 이 길이 내지 않는 403·404 같은
  /// 경로·인프라의 답)은 닫지 않고 두어, 스토어가 다음에 켤 때 다시 준다 — 결제 직후
  /// 그물이 끊긴 구매가 '복원' 을 눌러야만 서버에 닿던 길이다.
  Future<bool> _send(PurchaseProof proof) async {
    final bearer = await ai.bearer();
    if (bearer == null) {
      purchaseProblem = PurchaseProblem.notConfirmed;
      notifyListeners();
      return false;
    }
    final web = client ?? apiClient;
    try {
      final response = await web
          .post(
            Uri.parse('$endpoint/api/purchase'),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer $bearer',
            },
            body: jsonEncode({
              'store': proof.apple ? 'apple' : 'google',
              'plan': proof.plan.name,
              'token': proof.token,
            }),
          )
          // 서버는 스토어에 되물어 답한다. 그래도 끝없이 기다리지는 않는다.
          .timeout(const Duration(seconds: 20));
      final status = response.statusCode;
      purchaseProblem = switch (status) {
        200 => null,
        409 => PurchaseProblem.otherAccount,
        _ => PurchaseProblem.notConfirmed,
      };
      notifyListeners();
      if (purchaseProblem == null) {
        await _refresh();
        await refreshPlates(); // Pro 가 됐으면 이번 달 원판이 채워진다.
      }
      return const {200, 400, 402, 409}.contains(status);
    } catch (_) {
      // 그물·시간 초과. 거래는 열어 두었으니 다음에 켤 때 스토어가 다시 준다.
      purchaseProblem = PurchaseProblem.notConfirmed;
      notifyListeners();
      return false;
    }
  }

  /// 테스트가 서버 답을 한 번 받아 보게 하는 문. 로그인 흐름을 통째로
  /// 흉내 내지 않고 이 한 걸음만 본다.
  @visibleForTesting
  Future<void> refreshForTest() => _refresh();

  /// 스토어 없이 구매 하나를 서버에 넘겨 본다. 서버가 확정해 답했으면 true.
  @visibleForTesting
  Future<bool> sendForTest(PurchaseProof proof) => _send(proof);

  Future<void> _refresh() async {
    // 로그인 전에는 기기 토큰이다 — 로그인 없이 산 것도 여기서 보인다.
    final bearer = await ai.bearer();
    final web = client ?? apiClient;
    try {
      // 다른 물음과 같이 끝이 있다. 연결된 뒤 답이 멈추면 start() 가 끝나지 않는다.
      final response = await web
          .get(
            Uri.parse('$endpoint/api/purchase'),
            // 'Bearer null' 을 보내지 않는다.
            headers: {if (bearer != null) 'authorization': 'Bearer $bearer'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map) return;
      selling = body['selling'] == true;
      // 표 없이 물은 답(plan:null)은 누구의 것도 아니다. 기기 토큰을 못 받은 날 그
      // 답으로 덮으면 로그인 없이 산 사람이 무료로 보였다 — 알던 것을 그대로 둔다.
      if (bearer != null) {
        plan = Plan.values.where((p) => p.name == body['plan']).firstOrNull;
        final tag = body['appAccountToken'];
        purchaseTag = tag is String && tag.isNotEmpty ? tag : null;
        _purchaseKnown = true;
      }
      notifyListeners();
    } catch (_) {
      // 그물이 없으면 알던 것을 그대로 쓴다.
    }
  }

  @override
  void dispose() {
    _purchases.dispose();
    super.dispose();
  }
}
