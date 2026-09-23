// 애플 인앱 상품 심사용 스크린샷을 찍으려고 판매 화면만 띄운다.
//
// 스토어에 붙지 않는다 — 값은 우리가 넣고, 로그인한 것으로 둔다. 심사원이
// 보고 싶은 것은 "무엇을 파는 화면인가" 하나다.
import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:setpad/account.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/paywall.dart';
import 'package:setpad/purchases.dart';

ProductDetails _p(String id, String title, String price, double raw) =>
    ProductDetails(
      id: id,
      title: title,
      description: '',
      price: price,
      rawPrice: raw,
      currencyCode: 'KRW',
    );

void main() {
  // Purchases 가 스토어 채널을 잡으므로 바인딩이 먼저 서야 한다.
  WidgetsFlutterBinding.ensureInitialized();
  final purchases = Purchases()
    ..products = {
      Plan.yearly: _p('com.tskim.workoutlog.yearly', '연 이용권', '₩29,000', 29000),
      Plan.monthly: _p('com.tskim.workoutlog.monthly', '월 이용권', '₩4,900', 4900),
    };
  final account = Account(purchases: purchases)..token = 'screenshot';

  runApp(
    CupertinoApp(
      locale: const Locale('ko'),
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      debugShowCheckedModeBanner: false,
      home: Paywall(account: account),
    ),
  );
}
