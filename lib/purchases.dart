import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// 살 수 있는 것. 파는 화면에 이 순서로 놓인다 — 연간이 먼저다.
///
/// **id 는 스토어에 등록한 것과 글자 그대로 같아야 한다.** 애플은 번들을 앞에
/// 붙이고 구글은 안 붙이는데, 스토어마다 따로 정한 것이라 코드가 둘 다 안다.
/// 평생 이용권은 없다.
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

/// 스토어가 준 구매를 서버에 넘길 증거로. 산 것도 복원한 것도 아니면 null.
///
/// **Apple 은 거래 id 를 보낸다.** StoreKit 2 의 serverVerificationData 는 거래의
/// JWS(인증서 사슬까지 몇 KB)인데, 서버는 거래 id 로 App Store 에 되묻는다 —
/// JWS 를 보내면 길이에서 막히거나 Apple 이 모르는 id 가 되어 모든 구매가
/// '확인하지 못함'이 된다. Google 은 구매 토큰 그대로다.
PurchaseProof? proofOf(PurchaseDetails purchase) {
  final plan = planForStoreId(purchase.productID);
  if (plan == null ||
      (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored)) {
    return null;
  }
  final apple = purchase.verificationData.source == 'app_store';
  return (
    plan: plan,
    token: apple
        ? purchase.purchaseID ?? ''
        : purchase.verificationData.serverVerificationData,
    apple: apple,
  );
}

/// 스토어가 파는 요금제 하나. [buy] 로 산다. **무료 체험은 없다** — 무료는 가입
/// 원판과 하루 원판이다(gymdojo lib/plate-pricing.ts).
typedef Offer = ({ProductDetails buy, String price});

/// 스토어가 준 상품들을 요금제마다 하나로 모은다.
///
/// **Play 는 한 구독의 기본 요금제와 오퍼를 같은 id 로 하나씩 따로 준다.** 마지막
/// 것만 남기면 할인 오퍼로 사게 될 수 있다. 그래서 기본 요금제가 있으면 그것으로
/// 사고, 가격은 이어서 내는 마지막 단계의 값이다.
Map<Plan, Offer> offersFrom(Iterable<ProductDetails> found) {
  final best = <Plan, (int, Offer)>{};
  for (final detail in found) {
    final plan = planForStoreId(detail.id);
    if (plan == null) continue;
    var rank = 0;
    Offer offer = (buy: detail, price: detail.price);
    if (detail is GooglePlayProductDetails) {
      final index = detail.subscriptionIndex;
      final option = index == null
          ? null
          : detail.productDetails.subscriptionOfferDetails?[index];
      if (option != null) {
        offer = (buy: detail, price: option.pricingPhases.last.formattedPrice);
        // 기본 요금제 > 그 밖의 오퍼.
        rank = option.offerId == null ? 1 : 0;
      }
    }
    if ((best[plan]?.$1 ?? -1) < rank) best[plan] = (rank, offer);
  }
  return {for (final e in best.entries) e.key: e.value.$2};
}

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

  /// 스토어가 준 구매를 서버에 넘기는 일([Account] 가 단다). 서버가 확정해 답했으면
  /// true 이고, 그때만 거래를 닫는다.
  Future<bool> Function(PurchaseProof proof)? onProof;

  Map<Plan, Offer> offers = const {};

  /// 스토어에 붙어 파는 것을 읽어 온다.
  ///
  /// **여기서 터지면 앱 전체가 못 뜬다.** 결제 채널은 기기에 따라 아예 없다
  /// (Play 서비스 없는 기기, 테스트 환경). 못 붙은 것은 "팔 것이 없다"와
  /// 같은 뜻이므로 그렇게 답하고 지나간다 — 기록하는 일은 그대로 된다.
  Future<bool> start({bool apple = true}) async {
    try {
      if (!await _store.isAvailable()) return false;
      // 상품을 묻기 전에 듣는다 — 그물이 없어 상품을 못 읽어도, 닫지 않은 지난 거래는
      // 스토어가 켤 때 다시 준다(App Store). Play 는 다시 주지 않아 직접 찾는다.
      _watch ??= _store.purchaseStream.listen(_onPurchases);
      if (!apple) unawaited(_unfinishedOnPlay());
      final found = await _store.queryProductDetails({
        for (final plan in Plan.values) storeId(plan, apple: apple),
      });
      offers = offersFrom(found.productDetails);
      return offers.isNotEmpty;
    } catch (e) {
      debugPrint('스토어에 붙지 못했다: $e');
      return false;
    }
  }

  /// Play 에서 아직 확인(acknowledge)하지 않은 구매 — 결제 직후 서버에 못 닿은 것.
  /// **Play 는 사흘 안에 확인하지 않은 구매를 환불한다.** 그 전에 서버가 받아 주면 닫힌다.
  Future<void> _unfinishedOnPlay() async {
    try {
      final past = await _store
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
          .queryPastPurchases();
      await _onPurchases([
        for (final purchase in past.pastPurchases)
          if (purchase.pendingCompletePurchase) purchase,
      ]);
    } catch (e) {
      debugPrint('Play 의 지난 구매를 읽지 못했다: $e');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      // 스토어는 닫을 때까지 같은 구매를 다시 준다. **서버가 확정해 답한 뒤에 닫는다** —
      // 먼저 닫으면 서버에 못 닿은 구매는 '복원' 을 눌러야만 다시 갔다. 권한은 서버가
      // 돌려주는 답으로만 바뀐다. 산 것도 복원한 것도 아닌 거래(실패·취소)는 바로 닫는다.
      // 결제가 아직 끝나지 않은 것(pending — 부모 승인, 느린 결제 수단)은 닫을 수 없다.
      if (purchase.status == PurchaseStatus.pending) continue;
      final proof = proofOf(purchase);
      final settled = proof == null || (await onProof?.call(proof) ?? false);
      if (!settled || !purchase.pendingCompletePurchase) continue;
      try {
        await _store.completePurchase(purchase);
      } catch (e) {
        // 닫지 못한 거래는 스토어가 다시 준다. 같은 묶음의 다른 구매는 그대로 보낸다.
        debugPrint('거래를 닫지 못했다: $e');
      }
    }
  }

  /// [appAccountToken] 은 App Store 구매에 싣는 표(서버가 준 UUID)다 — 구매가 이
  /// 계정·기기에 묶인다. Play 에는 싣지 않는다.
  Future<void> buy(Plan plan, {String? appAccountToken}) async {
    final detail = offers[plan]?.buy;
    if (detail == null) return;
    // Play 는 넘긴 상품이 가리키는 요금제·오퍼로 산다.
    final param = PurchaseParam(
      productDetails: detail,
      applicationUserName: detail is GooglePlayProductDetails
          ? null
          : appAccountToken,
    );
    // in_app_purchase 는 구독도 non-consumable 문으로 산다.
    await _store.buyNonConsumable(purchaseParam: param);
  }

  /// 애플이 요구한다 — 없으면 심사에서 막힌다. 기기를 바꾼 사람의 유일한 길이다.
  Future<void> restore() => _store.restorePurchases();

  void dispose() {
    _watch?.cancel();
  }
}
