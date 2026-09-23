import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:setpad/account.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/paywall.dart';
import 'package:setpad/purchases.dart';
import 'package:setpad/record_ai.dart';

/// 원판과 이용권. 서버 대신 가짜 그물이 답한다.
///
/// [answer] 가 null 을 주면 200 {} 이다. 들어온 요청은 [seen] 에 쌓인다.
http.Client _server(
  List<http.Request> seen, [
  http.Response? Function(http.Request)? answer,
]) => MockClient((request) async {
  seen.add(request);
  if (request.url.path == '/api/device') {
    return http.Response(jsonEncode({'token': 'device-token'}), 200);
  }
  return answer?.call(request) ?? http.Response('{}', 200);
});

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

String? _bearer(http.Request r) => r.headers['authorization'];

void main() {
  setUp(RecordAi.forget);

  group('어느 토큰으로 묻나', () {
    test('로그인했으면 계정 토큰, 기기 토큰은 받지도 않는다', () async {
      final seen = <http.Request>[];
      final account = Account(
        client: _server(seen, (_) => _json({'intent': {}}, 200)),
        deviceId: () => 'device-id-0123456789',
      )..token = 'account-token';
      await account.ai.ask('i', 'q', contract: 2);
      expect(seen.map((r) => r.url.path), ['/api/record-query']);
      expect(_bearer(seen.single), 'Bearer account-token');
    });

    test('로그인 전이면 기기 토큰, 로그아웃하면 다시 기기 토큰', () async {
      final seen = <http.Request>[];
      final account = Account(
        client: _server(seen, (_) => _json({'intent': {}}, 200)),
        deviceId: () => 'device-id-0123456789',
        storageDir: Directory.systemTemp.createTempSync('setpad-plates'),
      );
      await account.ai.ask('i', 'q');
      expect(_bearer(seen.last), 'Bearer device-token');

      // 같은 ai 를 들고 있어도 로그인하면 다음 요청부터 계정으로 간다.
      final ai = account.ai;
      account.token = 'account-token';
      await ai.ask('i', 'q');
      expect(_bearer(seen.last), 'Bearer account-token');

      seen.clear();
      await account.signOut();
      await pumpEventQueue();
      // 받아 둔 기기 토큰은 버렸다 — 이 기기의 지갑을 다시 읽으며 새로 받는다.
      expect(seen.map((r) => r.url.path), ['/api/device', '/api/plates']);
      await ai.ask('i', 'q');
      expect(_bearer(seen.last), 'Bearer device-token');
    });

    test('계정 토큰이 401 이면 로그아웃하고 이 기기의 지갑으로 다시 묻는다', () async {
      final seen = <http.Request>[];
      final account = Account(
        client: _server(
          seen,
          (r) => _bearer(r) == 'Bearer dead-token'
              ? _json({'error': 'unauthorized'}, 401)
              : _json({'intent': {}}, 200),
        ),
        deviceId: () => 'device-id-0123456789',
        storageDir: Directory.systemTemp.createTempSync('setpad-plates'),
      )..token = 'dead-token';
      await account.ai.ask('i', 'q', contract: 2);
      expect(account.signedIn, isFalse);
      expect(
        seen.where((r) => r.url.path == '/api/record-query').map(_bearer),
        ['Bearer dead-token', 'Bearer device-token'],
      );
    });

    test('한 줄 설정은 kind:input, 기록 질문은 kind 없이(ask) 간다', () async {
      final seen = <http.Request>[];
      final ai = RecordAi(
        endpoint: 'https://example.test',
        deviceId: 'device-id-0123456789',
        client: _server(
          seen,
          (_) => _json({
            'intent': {
              'exercises': [
                {
                  'text': '스쿼트 60kg 10회 5세트',
                  'name': '스쿼트',
                  'weight': 60,
                  'unit': 'kg',
                  'repsPerSet': 10,
                  'totalSets': 5,
                },
              ],
            },
          }, 200),
        ),
      );
      await ai.interpret('스쿼트 60kg 10회 5세트', 'ko', ['스쿼트']);
      await ai.ask('i', 'q', contract: 2);
      final bodies = [
        for (final r in seen.where((r) => r.url.path == '/api/record-query'))
          jsonDecode(r.body) as Map,
      ];
      expect(bodies.first['kind'], 'input');
      expect(bodies.first['contract'], 2, reason: '여러 운동을 받는 새 계약');
      expect(bodies.last.containsKey('kind'), isFalse);
    });
  });

  group('서버가 막을 때', () {
    Future<(RecordAiStatus?, double?)> statusOf(
      int code,
      Map<String, Object?> body,
    ) async {
      double? balance;
      final ai = RecordAi(
        endpoint: 'https://example.test',
        deviceId: 'device-id-0123456789',
        client: _server([], (_) => _json(body, code)),
        onPlates: (b, _) => balance = b,
      );
      try {
        await ai.ask('i', 'q', contract: 2);
      } on RecordAiException catch (e) {
        return (e.status, balance);
      }
      return (null, balance);
    }

    test('402 는 원판 부족이고 잔액을 알린다', () async {
      expect(await statusOf(402, {'error': 'noPlates', 'balance': 0.004}), (
        RecordAiStatus.noPlates,
        0.004,
      ));
    });

    test('429 는 적기 도움(input)만 한도 소진이고 나머지는 실패다', () async {
      expect(
        (await statusOf(429, {
          'error': 'quotaExceeded',
          'scope': 'input',
          'limit': 10,
        })).$1,
        RecordAiStatus.quotaExceeded,
      );
      for (final scope in ['address', 'global', null]) {
        expect(
          (await statusOf(429, {
            'error': 'quotaExceeded',
            'scope': ?scope,
            'limit': 300,
          })).$1,
          RecordAiStatus.unavailable,
          reason: '$scope',
        );
      }
    });

    test('질문에 쓴 원판과 남은 원판을 받는다', () async {
      final account = Account(
        client: _server(
          [],
          (_) => _json({
            'intent': {},
            'plates': {'spent': 0.95, 'balance': 4.05},
          }, 200),
        ),
      )..token = 'account-token';
      await account.ai.ask('i', 'q', contract: 2);
      expect((account.platesSpent, account.plates), (0.95, 4.05));
    });

    test('원판 수는 소수까지, 영어·스페인어는 1장일 때 단수다', () async {
      final ko = await L.delegate.load(const Locale('ko'));
      expect(ko.platesBalance(4.05), '남은 원판 4.05장');
      expect(ko.platesBalance(3.0), '남은 원판 3장');
      final en = await L.delegate.load(const Locale('en'));
      expect(en.platesBalance(1.0), '1 plate left');
      expect(en.platesBalance(1.5), '1.5 plates left');
      expect(en.platesSpent(1.0, 2.05), 'Used 1 plate · 2.05 left');
      expect(en.platesSpent(0.95, 4.05), 'Used 0.95 plates · 4.05 left');
      final es = await L.delegate.load(const Locale('es'));
      expect(es.platesBalance(1.0), 'Te queda 1 disco');
      expect(es.platesSpent(0.95, 1.0), 'Usaste 0,95 discos · queda 1');
    });

    test('식단 어림이 오늘 몫을 넘으면 한도 소진이다', () async {
      final ai = RecordAi(
        endpoint: 'https://example.test',
        deviceId: 'device-id-0123456789',
        client: _server(
          [],
          (_) => _json({
            'error': 'quotaExceeded',
            'scope': 'input',
            'limit': 10,
          }, 429),
        ),
      );
      await expectLater(
        ai.estimateMealText('김밥 한 줄', locale: 'ko'),
        throwsA(
          isA<RecordAiException>().having(
            (e) => e.status,
            'status',
            RecordAiStatus.quotaExceeded,
          ),
        ),
      );
    });
  });

  group('하루 원판', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('setpad-plates'));
    tearDown(() => dir.deleteSync(recursive: true));

    NotesStore storeWith(int doneSets, DateTime at) =>
        NotesStore(directory: dir)..create(
          at: at,
          blocks: [
            ExerciseBlock('스쿼트', [
              for (var i = 0; i < doneSets; i++) LoggedSet(value: 60, reps: 5),
              LoggedSet(value: 60, reps: 5, done: false),
            ]),
          ],
        );

    test('오늘 세트 10개를 채우면 한 번만 묻는다', () async {
      final seen = <http.Request>[];
      final now = DateTime.utc(2026, 9, 23, 3); // 한국 12시
      final account = Account(
        client: _server(
          seen,
          (r) => r.url.path == '/api/plates/daily'
              ? _json({'granted': true, 'balance': 4}, 200)
              : null,
        ),
        deviceId: () => 'device-id-0123456789',
      );
      final store = storeWith(dailyPlateSets, now);
      await account.claimDaily(store, now: now);
      await account.claimDaily(store, now: now);
      final daily = seen.where((r) => r.url.path == '/api/plates/daily');
      expect(daily, hasLength(1));
      expect(jsonDecode(daily.single.body), {'day': '2026-09-23', 'sets': 10});
      expect(store.platesDay, 'device:2026-09-23');
      expect(account.plates, 4);
      store.dispose();
    });

    test('받은 날은 지갑마다 기억한다 — 기기로 받은 날 로그인하면 계정 지갑도 묻는다', () async {
      final seen = <http.Request>[];
      final now = DateTime.utc(2026, 9, 23, 3);
      final account = Account(
        client: _server(
          seen,
          (r) => r.url.path == '/api/plates/daily'
              ? _json({'granted': true, 'balance': 4}, 200)
              : null,
        ),
        deviceId: () => 'device-id-0123456789',
      );
      final store = storeWith(dailyPlateSets, now);
      await account.claimDaily(store, now: now);
      account.token = 'account-token';
      await account.claimDaily(store, now: now);
      await account.claimDaily(store, now: now);
      expect(
        seen.where((r) => r.url.path == '/api/plates/daily').map(_bearer),
        ['Bearer device-token', 'Bearer account-token'],
      );
      store.dispose();
    });

    test('9개면 묻지 않고, 한국 날짜로 센다', () async {
      final seen = <http.Request>[];
      final account = Account(
        client: _server(seen),
        deviceId: () => 'device-id-0123456789',
      );
      final at = DateTime.utc(2026, 9, 23, 3);
      final store = storeWith(dailyPlateSets - 1, at);
      await account.claimDaily(store, now: at);
      expect(seen, isEmpty);
      // 한국 날짜가 넘어가면 어제 세트는 오늘 것이 아니다.
      expect(kstDay(DateTime.utc(2026, 9, 23, 15)), '2026-09-24');
      store.dispose();
    });

    test('서버가 못 받으면 날을 기억하지 않고, 곧바로 다시 두드리지 않는다', () async {
      final seen = <http.Request>[];
      final account = Account(
        client: _server(seen, (_) => _json({'error': 'invalidInput'}, 400)),
        deviceId: () => 'device-id-0123456789',
      );
      final at = DateTime.utc(2026, 9, 23, 3);
      final store = storeWith(dailyPlateSets, at);
      await account.claimDaily(store, now: at);
      await account.claimDaily(store, now: at.add(const Duration(minutes: 1)));
      expect(
        seen.where((r) => r.url.path == '/api/plates/daily'),
        hasLength(1),
      );
      expect(store.platesDay, isEmpty);
      await account.claimDaily(store, now: at.add(const Duration(minutes: 6)));
      expect(
        seen.where((r) => r.url.path == '/api/plates/daily'),
        hasLength(2),
      );
      store.dispose();
    });
  });

  group('이용권', () {
    test('연간이 먼저이고 평생은 없다', () {
      expect(Plan.values, [Plan.yearly, Plan.monthly]);
      expect(storeId(Plan.yearly, apple: true), 'com.tskim.workoutlog.yearly');
      expect(storeId(Plan.yearly, apple: false), 'yearly');
      expect(planForStoreId('com.tskim.workoutlog.yearly'), Plan.yearly);
      expect(planForStoreId('com.tskim.workoutlog.lifetime'), isNull);
    });

    test('Apple 은 거래 id 를, Google 은 구매 토큰을 서버에 보낸다', () {
      PurchaseDetails purchase(String source, String id, PurchaseStatus status) =>
          PurchaseDetails(
            purchaseID: '2000000123',
            productID: id,
            verificationData: PurchaseVerificationData(
              localVerificationData: '{}',
              // StoreKit 2 가 주는 것은 거래의 JWS 다. 서버는 거래 id 로 묻는다.
              serverVerificationData: 'eyJhbGciOiJFUzI1NiIsIng1YyI6WyJNSUl.jws',
              source: source,
            ),
            transactionDate: null,
            status: status,
          );
      expect(
        proofOf(
          purchase(
            'app_store',
            'com.tskim.workoutlog.yearly',
            PurchaseStatus.purchased,
          ),
        ),
        (plan: Plan.yearly, token: '2000000123', apple: true),
      );
      expect(
        proofOf(purchase('google_play', 'monthly', PurchaseStatus.restored)),
        (
          plan: Plan.monthly,
          token: 'eyJhbGciOiJFUzI1NiIsIng1YyI6WyJNSUl.jws',
          apple: false,
        ),
      );
      expect(
        proofOf(purchase('app_store', 'monthly', PurchaseStatus.pending)),
        isNull,
      );
    });

    group('스토어가 준 요금제', () {
      PricingPhaseWrapper phase(String period, int micros, String price) =>
          PricingPhaseWrapper(
            billingCycleCount: micros == 0 ? 1 : 0,
            billingPeriod: period,
            formattedPrice: price,
            priceAmountMicros: micros,
            priceCurrencyCode: 'KRW',
            recurrenceMode: micros == 0
                ? RecurrenceMode.finiteRecurring
                : RecurrenceMode.infiniteRecurring,
          );
      final trial = SubscriptionOfferDetailsWrapper(
        basePlanId: 'yearly',
        offerId: 'trial',
        offerTags: const [],
        offerIdToken: 'trial-token',
        pricingPhases: [
          phase('P7D', 0, '무료'),
          phase('P1Y', 29000000000, '₩29,000'),
        ],
      );
      final base = SubscriptionOfferDetailsWrapper(
        basePlanId: 'yearly',
        offerTags: const [],
        offerIdToken: 'base-token',
        pricingPhases: [phase('P1Y', 29000000000, '₩29,000')],
      );
      List<GooglePlayProductDetails> play(
        List<SubscriptionOfferDetailsWrapper> options,
      ) => GooglePlayProductDetails.fromProductDetails(
        ProductDetailsWrapper(
          description: '',
          name: '연 이용권',
          productId: 'yearly',
          productType: ProductType.subs,
          title: '연 이용권',
          subscriptionOfferDetails: options,
        ),
      );

      test('Play: 기본 요금제와 체험 오퍼가 따로 와도 체험 오퍼로 사고 값은 체험 뒤 값이다', () {
        for (final options in [
          [trial, base],
          [base, trial],
        ]) {
          final offer = offersFrom(play(options))[Plan.yearly]!;
          expect((offer.price, offer.trialDays), ('₩29,000', 7));
          expect((offer.buy as GooglePlayProductDetails).offerToken, 'trial-token');
        }
        // 체험 자격이 없으면 Play 는 체험 오퍼를 주지 않는다.
        final offer = offersFrom(play([base]))[Plan.yearly]!;
        expect((offer.price, offer.trialDays), ('₩29,000', null));
        expect((offer.buy as GooglePlayProductDetails).offerToken, 'base-token');
      });

      test('App Store: 무료 체험 소개 오퍼는 자격이 있을 때만 약속한다', () {
        final product = AppStoreProduct2Details.fromSK2Product(
          SK2Product(
            id: 'com.tskim.workoutlog.yearly',
            displayName: '연 이용권',
            displayPrice: '₩29,000',
            description: '',
            price: 29000,
            type: SK2ProductType.autoRenewable,
            priceLocale: SK2PriceLocale(
              currencyCode: 'KRW',
              currencySymbol: '₩',
            ),
            subscription: SK2SubscriptionInfo(
              subscriptionGroupID: 'pro',
              subscriptionPeriod: const SK2SubscriptionPeriod(
                value: 1,
                unit: SK2SubscriptionPeriodUnit.year,
              ),
              promotionalOffers: [
                SK2SubscriptionOffer(
                  price: 0,
                  type: SK2SubscriptionOfferType.introductory,
                  period: const SK2SubscriptionPeriod(
                    value: 1,
                    unit: SK2SubscriptionPeriodUnit.week,
                  ),
                  periodCount: 1,
                  paymentMode: SK2SubscriptionOfferPaymentMode.freeTrial,
                ),
              ],
            ),
          ),
        );
        final eligible = offersFrom(
          [product],
          introEligible: {'com.tskim.workoutlog.yearly'},
        )[Plan.yearly]!;
        expect((eligible.price, eligible.trialDays), ('₩29,000', 7));
        expect(offersFrom([product])[Plan.yearly]!.trialDays, isNull);
      });
    });

    Future<void> openPaywall(WidgetTester tester, Account account) async {
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: Paywall(account: account),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('서버가 연간이라 하면 연간 이용 중, 원판이 보인다', (tester) async {
      final account = Account(
        client: _server([], (r) {
          if (r.url.path == '/api/purchase') {
            return _json({'plan': 'yearly', 'selling': true}, 200);
          }
          if (r.url.path == '/api/plates') {
            return _json({
              'balance': 300,
              'pro': true,
              'plan': 'yearly',
              'input': {'used': 0, 'limit': 100},
            }, 200);
          }
          return null;
        }),
      )..token = 'account-token';
      await tester.runAsync(account.refreshForTest);
      expect(account.plan, Plan.yearly);
      await openPaywall(tester, account);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      final l = await L.delegate.load(const Locale('ko'));
      expect(find.text(l.proOwned), findsOneWidget);
      expect(find.text('${l.planYearly} · ${l.planActive}'), findsOneWidget);
      expect(find.text(l.platesBalance(300)), findsOneWidget);
    });

    ProductDetails product(String id, String price) => ProductDetails(
      id: id,
      title: id,
      description: '',
      price: price,
      rawPrice: 0,
      currencyCode: 'KRW',
    );

    testWidgets('체험은 스토어가 줄 때만 단추 밑에 적고, 값이 없는 요금제는 팔지 않는다', (
      tester,
    ) async {
      final purchases = Purchases()
        ..offers = {
          Plan.yearly: (
            buy: product('com.tskim.workoutlog.yearly', '\$19.99'),
            price: '\$19.99',
            trialDays: 7,
          ),
        };
      final account = Account(client: _server([]), purchases: purchases)
        ..token = 'account-token';
      await openPaywall(tester, account);
      final l = await L.delegate.load(const Locale('ko'));
      // 체험 동안은 원판 30장뿐이라는 것도 같은 자리에 적는다(서버 PRO_TRIAL_CENTS).
      expect(
        find.text(
          '${l.planYearlyTrial(7, '\$19.99')}\n'
          '${l.planYearlyTrialPlates(proTrialPlates)}',
        ),
        findsOneWidget,
      );
      expect(find.text('${l.planYearly} · \$19.99'), findsOneWidget);
      expect(find.textContaining(l.planMonthly), findsNothing);
      expect(
        find.text(l.proPaid(proPlatesPerMonth, proInputPerDay)),
        findsOneWidget,
      );
      // 자동 갱신 구독 화면의 갱신 안내와 약관·개인정보 링크.
      expect(find.text(l.subscriptionRenews), findsOneWidget);
      expect(find.text(l.termsOfUse), findsOneWidget);
      expect(find.text(l.healthDataPrivacy), findsOneWidget);

      // 체험 자격이 없으면(스토어가 체험을 안 주면) 약속하지 않는다.
      purchases.offers = {
        Plan.yearly: (
          buy: product('com.tskim.workoutlog.yearly', '\$19.99'),
          price: '\$19.99',
          trialDays: null,
        ),
      };
      await openPaywall(tester, Account(client: _server([]), purchases: purchases)
        ..token = 'account-token');
      expect(find.textContaining(l.planYearlyTrial(7, '').split(' ').first), findsNothing);
      expect(find.textContaining(l.planYearlyTrialPlates(proTrialPlates)), findsNothing);
      expect(find.text('${l.planYearly} · \$19.99'), findsOneWidget);
    });

    for (final (code, problem) in [
      (409, PurchaseProblem.otherAccount),
      (402, PurchaseProblem.notConfirmed),
    ]) {
      testWidgets('서버가 구매를 $code 로 거절하면 말한다', (tester) async {
        final seen = <http.Request>[];
        final account = Account(
          client: _server(
            seen,
            (r) => r.url.path == '/api/purchase' && r.method == 'POST'
                ? _json({'error': 'refused'}, code)
                : null,
          ),
        )..token = 'account-token';
        await openPaywall(tester, account);
        await tester.runAsync(
          () => account.sendForTest((
            plan: Plan.yearly,
            token: 'receipt',
            apple: true,
          )),
        );
        await tester.pumpAndSettle();
        expect(account.purchaseProblem, problem);
        final sent = seen.lastWhere((r) => r.method == 'POST');
        expect(jsonDecode(sent.body), {
          'store': 'apple',
          'plan': 'yearly',
          'token': 'receipt',
        });
        final l = await L.delegate.load(const Locale('ko'));
        expect(
          find.text(
            problem == PurchaseProblem.otherAccount
                ? l.purchaseOtherAccount
                : l.purchaseNotConfirmed,
          ),
          findsOneWidget,
        );
      });
    }
  });
}
