import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// 살 수 있는 것.
///
/// **id 는 스토어에 등록한 것과 글자 그대로 같아야 한다.** 애플은 번들을 앞에
/// 붙이고 구글은 안 붙이는데, 스토어마다 따로 정한 것이라 코드가 둘 다 안다.
enum Plan { monthly, lifetime }

const _ids = <Plan, ({String apple, String google})>{
  Plan.monthly: (apple: 'com.tskim.workoutlog.monthly', google: 'monthly'),
  Plan.lifetime: (apple: 'com.tskim.workoutlog.lifetime', google: 'lifetime'),
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
  Purchases({InAppPurchase? store}) : _store = store ?? InAppPurchase.instance;
  final InAppPurchase _store;
  StreamSubscription<List<PurchaseDetails>>? _watch;

  /// 확인된 구매가 올라올 자리. 화면이 이걸 서버로 넘긴다.
  final _proofs = StreamController<PurchaseProof>.broadcast();
  Stream<PurchaseProof> get proofs => _proofs.stream;

  Map<Plan, ProductDetails> products = const {};

  Future<bool> start({bool apple = true}) async {
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
    // 평생은 비소모성이라 non-consumable 로 산다. 구독도 같은 문을 쓴다.
    await _store.buyNonConsumable(purchaseParam: param);
  }

  /// 애플이 요구한다 — 없으면 심사에서 막힌다. 기기를 바꾼 사람의 유일한 길이다.
  Future<void> restore() => _store.restorePurchases();

  void dispose() {
    _watch?.cancel();
    _proofs.close();
  }
}
