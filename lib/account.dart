import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'gym.dart';
import 'purchases.dart';
import 'record_ai.dart';
import 'sign_in.dart';

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
  }) : _purchases = purchases ?? Purchases();

  final String endpoint;
  final Purchases _purchases;

  /// 테스트가 끼워 넣는 자리. 비어 있으면 진짜 그물을 쓴다.
  final http.Client? client;

  /// 테스트가 쓸 임시 폴더. 비어 있으면 앱 문서함에 쓴다.
  final Directory? storageDir;
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

  /// 체육관에서 온 것들을 가져오는 문. 로그인하지 않았으면 아무것도 안 온다.
  GymLink get link => GymLink(endpoint: endpoint, token: token, client: client);

  bool get signedIn => token != null;
  bool get paid => plan != null;
  Map<Plan, String> get prices => {
    for (final entry in _purchases.products.entries)
      entry.key: entry.value.price,
  };

  Future<void> start() async {
    _watch ??= _purchases.proofs.listen(_send);
    await restoreSession();
    await _purchases.start(apple: platformSignIn == SignInMethod.apple);
    if (token != null) await _refresh();
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
    final web = client ?? http.Client();
    try {
      final response = await web.get(
        Uri.parse('$endpoint/api/me'),
        headers: {'authorization': 'Bearer $token'},
      );
      if (response.statusCode == 401) {
        await signOut();
        return false;
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

  Future<bool> signIn() async {
    final credential = await signInWithPlatform();
    if (credential == null) return false;
    final result = await exchange(
      credential,
      endpoint,
      currentToken: token,
      client: client,
    );
    if (result == null) return false;
    token = result.token;
    nickname = result.nickname;
    await _saveSession();
    await _refresh();
    await refreshGyms();
    notifyListeners();
    return true;
  }

  /// 로그아웃. **남긴 파일을 지우는 것까지가 로그아웃이다** — 지우기 전에
  /// 앱이 죽으면 다음에 켤 때 다시 로그인된 채로 뜬다.
  Future<void> signOut() async {
    token = null;
    nickname = '';
    plan = null;
    gyms = const [];
    notifyListeners();
    await _saveSession();
  }

  /// 결제는 로그인이 있어야 한다 — 권한은 기기가 아니라 사람에게 붙는다.
  Future<bool> buy(Plan wanted) async {
    if (!signedIn && !await signIn()) return false;
    await _purchases.buy(wanted);
    return true;
  }

  /// 애플이 요구한다. 기기를 바꾼 사람의 유일한 길이기도 하다.
  Future<void> restore() async {
    if (!signedIn && !await signIn()) return;
    await _purchases.restore();
  }

  Future<void> _send(PurchaseProof proof) async {
    if (token == null) return;
    final web = client ?? http.Client();
    try {
      await web.post(
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
      await _refresh();
    } catch (_) {
      // 못 보냈으면 다음에 앱을 켤 때 스토어가 다시 준다.
    } finally {
      if (client == null) web.close();
    }
  }

  /// 테스트가 서버 답을 한 번 받아 보게 하는 문. 로그인 흐름을 통째로
  /// 흉내 내지 않고 이 한 걸음만 본다.
  @visibleForTesting
  Future<void> refreshForTest() => _refresh();

  Future<void> _refresh() async {
    final web = client ?? http.Client();
    try {
      final response = await web.get(
        Uri.parse('$endpoint/api/purchase'),
        headers: {'authorization': 'Bearer $token'},
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
