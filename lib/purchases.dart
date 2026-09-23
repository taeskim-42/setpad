import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:in_app_purchase/in_app_purchase.dart';

/// 살 수 있는 것. 파는 화면에 이 순서로 놓인다 — 연간이 먼저다.
///
/// **id 는 스토어에 등록한 것과 글자 그대로 같아야 한다.** 애플은 번들을 앞에
/// 붙이고 구글은 안 붙이는데, 스토어마다 따로 정한 것이라 코드가 둘 다 안다.
/// 평생 이용권은 더 팔지 않는다.
enum Plan { yearly, monthly }

const _ids = <Plan, ({String apple, String google})>{
  Plan.yearly: (apple: 'com.tskim.workoutlog.yearly', google: 'yearly'),
  Plan.monthly: (apple: 'com.tskim.workoutlog.monthly', google: 'monthly'),
};

String storeId(Plan plan, {required bool apple}) =>
    apple ? _ids[plan]!.apple : _ids[plan]!.google;

Plan? planForStoreId(String id) {
  for (final entry in _ids.entries) {
    if (entry.value.apple == id || entry.value.google == id) return entry.key;
  }
  return null;
}

/// 스토어에서 온 구매 하나. 서버가 확인할 것만 담는다.
typedef PurchaseProof = ({Plan plan, String token, bool apple});

/// 결제. **여기서는 아무 권한도 주지 않는다.**
///
/// 스토어가 "샀다" 고 말하는 것을 앱이 그대로 믿으면, 그 말을 흉내 내는 것만
/// 으로 유료가 된다. 앱이 하는 일은 구매를 시작하고 증거를 받아 서버에 넘기는
/// 것까지다 — 진짜인지는 서버가 스토어에 직접 물어 정한다.
class Purchases {
  Purchases({InAppPurchase? store}) : _given = store;

  // **만들 때 스토어를 깨우지 않는다.** InAppPurchase.instance 는 곧바로
  // 결제 채널에 붙는데, 결제와 상관없는 자리에서 Account 를 만들기만 해도
  // 거기 끌려간다(테스트가 채널 오류로 죽었다). 실제로 쓸 때 붙는다.
  final InAppPurchase? _given;
  InAppPurchase get _store => _given ?? InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _watch;

  /// 확인된 구매가 올라올 자리. 화면이 이걸 서버로 넘긴다.
  final _proofs = StreamController<PurchaseProof>.broadcast();
  Stream<PurchaseProof> get proofs => _proofs.stream;

  Map<Plan, ProductDetails> products = const {};

  /// 스토어에 붙어 파는 것을 읽어 온다.
  ///
  /// **여기서 터지면 앱 전체가 못 뜬다.** 결제 채널은 기기에 따라 아예 없다
  /// (Play 서비스 없는 기기, 테스트 환경). 못 붙은 것은 "팔 것이 없다"와
  /// 같은 뜻이므로 그렇게 답하고 지나간다 — 기록하는 일은 그대로 된다.
  Future<bool> start({bool apple = true}) async {
    try {
      if (!await _store.isAvailable()) return false;
      final found = await _store.queryProductDetails({
        for (final plan in Plan.values) storeId(plan, apple: apple),
      });
      products = {
        for (final detail in found.productDetails)
          ?planForStoreId(detail.id): detail,
      };
      _watch ??= _store.purchaseStream.listen(_onPurchases);
      return products.isNotEmpty;
    } catch (e) {
      debugPrint('스토어에 붙지 못했다: $e');
      return false;
    }
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      final plan = planForStoreId(purchase.productID);
      if (plan != null &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        _proofs.add((
          plan: plan,
          token: purchase.verificationData.serverVerificationData,
          apple: purchase.verificationData.source == 'app_store',
        ));
      }
      // 스토어는 완료를 알릴 때까지 같은 구매를 계속 준다. 서버 확인과 무관하게
      // 닫아야 하며, 권한은 서버가 돌려주는 답으로만 바뀐다.
      if (purchase.pendingCompletePurchase) {
        unawaited(_store.completePurchase(purchase));
      }
    }
  }

  Future<void> buy(Plan plan) async {
    final detail = products[plan];
    if (detail == null) return;
    final param = PurchaseParam(productDetails: detail);
    // in_app_purchase 는 구독도 non-consumable 문으로 산다.
    await _store.buyNonConsumable(purchaseParam: param);
  }

  /// 애플이 요구한다 — 없으면 심사에서 막힌다. 기기를 바꾼 사람의 유일한 길이다.
  Future<void> restore() => _store.restorePurchases();

  void dispose() {
    _watch?.cancel();
    _proofs.close();
  }
}
