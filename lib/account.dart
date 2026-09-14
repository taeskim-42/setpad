import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
  }) : _purchases = purchases ?? Purchases();

  final String endpoint;
  final Purchases _purchases;

  /// 테스트가 끼워 넣는 자리. 비어 있으면 진짜 그물을 쓴다.
  final http.Client? client;
  StreamSubscription<PurchaseProof>? _watch;

  /// 로그인해서 받은 우리 토큰. 없으면 로그인하지 않은 것이다.
  String? token;
  String nickname = '';

  /// 서버가 확인해 준 것. 앱이 정하지 않는다.
  Plan? plan;

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
    await _purchases.start(apple: platformSignIn == SignInMethod.apple);
    if (token != null) await _refresh();
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
    await _refresh();
    await refreshGyms();
    notifyListeners();
    return true;
  }

  void signOut() {
    token = null;
    nickname = '';
    plan = null;
    gyms = const [];
    notifyListeners();
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
