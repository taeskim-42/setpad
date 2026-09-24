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
    this.aiConsent,
    Future<Credential?> Function()? signInWith,
  }) : _purchases = purchases ?? Purchases(),
       _signInWith = signInWith ?? signInWithPlatform;

  final String endpoint;
  final Purchases _purchases;

  /// 테스트가 끼워 넣는 자리. 비어 있으면 진짜 그물을 쓴다.
  final http.Client? client;

  /// 테스트가 쓸 임시 폴더. 비어 있으면 앱 문서함에 쓴다.
  final Directory? storageDir;

  /// 이 기기의 id. 기기 id 는 저장소를 읽은 뒤에 생기므로 부를 때 읽는다.
  final String Function()? deviceId;

  /// 모델에 보내기 전에 동의를 묻는 자리([RecordAi.consent]).
  final Future<bool> Function()? aiConsent;

  /// 제공자 로그인 창을 여는 일. 테스트는 진짜 애플 창을 열 수 없다.
  final Future<Credential?> Function() _signInWith;
  StreamSubscription<PurchaseProof>? _watch;

  /// 로그인해서 받은 우리 토큰. 없으면 로그인하지 않은 것이다.
  String? token;
  String nickname = '';

  /// 서버가 확인해 준 것. 앱이 정하지 않는다.
  Plan? plan;

  /// **이용권을 팔고 있는가.** 서버가 정한다.
  ///
  /// 스토어에 상품을 올려 두는 것과 앱에서 파는 것은 다른 결정이다. 앱에
  /// 박아 두면 마음이 바뀔 때마다 심사를 다시 받아야 한다. 기본은 안 파는
  /// 것이다 — 서버에 못 닿았을 때 파는 화면이 뜨는 것보다 안 뜨는 편이 낫다.
  bool selling = false;

  /// 내가 다니는 체육관. 없으면 앱은 그쪽 화면을 아예 안 그린다.
  List<Gym> gyms = const [];

  /// 직원으로 있는 도장. 비어 있으면 트레이너 화면이 아예 없다. /api/me 에
  /// 물어볼 때마다 새 목록이 된다 — 목록 화면은 그것으로 다시 읽을 때를 안다.
  List<StaffGym> staff = const [];

  /// 체육관에서 온 것들을 가져오는 문. 로그인하지 않았으면 아무것도 안 온다.
  GymLink get link => GymLink(endpoint: endpoint, token: token, client: client);

  /// AI 에 묻는 문. 로그인했으면 계정의 지갑, 아니면 이 기기의 지갑을 쓴다.
  RecordAi get ai => RecordAi(
    endpoint: endpoint,
    deviceId: deviceId?.call() ?? '',
    client: client,
    accountToken: () => token,
    onPlates: _setPlates,
    onUnauthorized: signOut,
    consent: aiConsent,
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

  /// 스토어가 지금 파는 요금제. 값과 체험은 스토어가 준 그대로다.
  Map<Plan, Offer> get offers => _purchases.offers;

  Future<void> start() async {
    _watch ??= _purchases.proofs.listen(_send);
    await restoreSession();
    await _purchases.start(apple: platformSignIn == SignInMethod.apple);
    // **로그인 전에도 묻는다.** 파는지 여부는 사람이 아니라 서버가 정하는
    // 것이고, 서버는 로그인 없이도 답한다. 안 물으면 아직 로그인 안 한
    // 사람에게는 무엇을 파는지도, 무료가 몇 번인지도 영영 안 보인다.
    await _refresh();
    await refreshPlates();
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
  // 노트·설정과 같은 자리에 같은 방식으로 쓴다. 저장소를 하나 더 들이지 않는다.

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
      final f = await _sessionFile();
      if (f == null || !f.existsSync()) return;
      final data = jsonDecode(await f.readAsString());
      if (data is! Map) return;
      final saved = data['token'];
      if (saved is! String || saved.isEmpty) return;
      token = saved;
      nickname = data['nickname'] as String? ?? '';
      notifyListeners();
    } catch (e) {
      // 깨진 파일 때문에 앱이 안 뜨면 안 된다. 로그인만 다시 하면 된다.
      debugPrint('session.json 을 읽지 못했다: $e');
    }
  }

  Future<void> _saveSession() async {
    try {
      final f = await _sessionFile();
      if (f == null) return;
      if (token == null) {
        if (f.existsSync()) await f.delete();
        return;
      }
      // 쓰다 말고 꺼져도 반쪽짜리 파일이 남지 않게 한다 — 노트와 같은 방식이다.
      final temporary = File('${f.path}.tmp');
      await temporary.writeAsString(
        jsonEncode({'token': token, 'nickname': nickname}),
        flush: true,
      );
      await temporary.rename(f.path);
    } catch (e) {
      debugPrint('session.json 을 쓰지 못했다: $e');
    }
  }

  /// 남겨 둔 토큰이 아직 살아 있는가.
  ///
  /// 토큰은 서른 날이면 죽는다. 죽은 것을 들고 있으면 체육관 목록이 빈 채로
  /// 와서 **다니는 곳이 없는 사람처럼** 보인다 — 등록을 다시 신청하게 된다.
  /// 그물이 없어서 못 물어본 것과 서버가 거절한 것은 다르다. 거절일 때만 지운다.
  Future<bool> _stillValid() async {
    final web = client ?? newApiClient();
    try {
      // 기다리는 데도 끝이 있어야 한다. 길이 막혔을 때 여기서 매달리면 앱의 나머지
      // (체육관 목록, 밀린 전송)가 같이 멈춘다. 못 물어본 것은 로그아웃이 아니다.
      final response = await web
          .get(
            Uri.parse('$endpoint/api/me'),
            headers: {'authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
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
          if (fresh is String && fresh.isNotEmpty && fresh != token) {
            token = fresh;
            await _saveSession();
          }
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
    } finally {
      if (client == null) web.close();
    }
  }

  /// 다니는 체육관을 다시 읽는다. 트레이너가 방금 등록했을 수 있다.
  Future<void> refreshGyms() async {
    gyms = await link.gyms();
    notifyListeners();
  }

  /// 마지막 로그인이 서버에서 막혔는가.
  ///
  /// **조용히 실패하면 고칠 수가 없다.** 사람이 스스로 닫은 것과 서버가 안
  /// 받아 준 것은 다르다 — 앞은 말할 것이 없고, 뒤는 말해 줘야 한다.
  bool signInRefused = false;

  Future<bool> signIn() async {
    signInRefused = false;
    Credential? credential;
    try {
      credential = await _signInWith();
    } catch (error) {
      // 사람이 창을 닫으면 여기로 온다. 실패가 아니라 그만둔 것이다.
      debugPrint('[로그인] 제공자 단계에서 멈췄다: $error');
      return false;
    }
    if (credential == null) return false;
    final result = await exchange(
      credential,
      endpoint,
      currentToken: token,
      client: client,
    );
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
    plan = null;
    gyms = const [];
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

  /// 결제는 로그인이 있어야 한다 — 권한은 기기가 아니라 사람에게 붙는다.
  Future<bool> buy(Plan wanted) async {
    if (!signedIn && !await signIn()) return false;
    purchaseProblem = null;
    notifyListeners();
    await _purchases.buy(wanted);
    return true;
  }

  /// 애플이 요구한다. 기기를 바꾼 사람의 유일한 길이기도 하다.
  Future<void> restore() async {
    if (!signedIn && !await signIn()) return;
    await _purchases.restore();
  }

  /// 스토어가 준 구매를 서버에 넘긴다. **서버의 답을 읽는다** — 거절당했는데
  /// 아무 말이 없으면 돈을 낸 사람은 산 줄 알고 기다린다.
  Future<void> _send(PurchaseProof proof) async {
    if (token == null) return;
    final web = client ?? newApiClient();
    try {
      final response = await web.post(
        Uri.parse('$endpoint/api/purchase'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'store': proof.apple ? 'apple' : 'google',
          'plan': proof.plan.name,
          'token': proof.token,
        }),
      );
      purchaseProblem = switch (response.statusCode) {
        200 => null,
        409 => PurchaseProblem.otherAccount,
        _ => PurchaseProblem.notConfirmed,
      };
      notifyListeners();
      if (purchaseProblem == null) {
        await _refresh();
        await refreshPlates(); // Pro 가 됐으면 이번 달 원판이 채워진다.
      }
    } catch (_) {
      // 스토어는 이미 완료 처리했다. 복원을 눌러야 다시 보낼 수 있다고 알린다.
      purchaseProblem = PurchaseProblem.notConfirmed;
      notifyListeners();
    } finally {
      if (client == null) web.close();
    }
  }

  /// 테스트가 서버 답을 한 번 받아 보게 하는 문. 로그인 흐름을 통째로
  /// 흉내 내지 않고 이 한 걸음만 본다.
  @visibleForTesting
  Future<void> refreshForTest() => _refresh();

  /// 스토어 없이 구매 하나를 서버에 넘겨 본다.
  @visibleForTesting
  Future<void> sendForTest(PurchaseProof proof) => _send(proof);

  Future<void> _refresh() async {
    final web = client ?? newApiClient();
    try {
      final response = await web.get(
        Uri.parse('$endpoint/api/purchase'),
        // 로그인 전에는 붙일 것이 없다. 'Bearer null' 을 보내지 않는다.
        headers: {if (token != null) 'authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) return;
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final name = body is Map ? body['plan'] : null;
      plan = Plan.values.where((p) => p.name == name).firstOrNull;
      selling = body is Map && body['selling'] == true;
      notifyListeners();
    } catch (_) {
      // 그물이 없으면 알던 것을 그대로 쓴다.
    } finally {
      if (client == null) web.close();
    }
  }

  @override
  void dispose() {
    _watch?.cancel();
    _purchases.dispose();
    super.dispose();
  }
}
