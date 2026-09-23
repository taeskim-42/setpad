import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

    test('한 줄 설정은 kind:input, 기록 질문은 kind 없이(ask) 간다', () async {
      final seen = <http.Request>[];
      final ai = RecordAi(
        endpoint: 'https://example.test',
        deviceId: 'device-id-0123456789',
        client: _server(
          seen,
          (_) => _json({
            'intent': {
              'isExercise': true,
              'name': '스쿼트',
              'weight': 60,
              'unit': 'kg',
              'repsPerSet': 10,
              'totalSets': 5,
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
      expect(plateCount(4.05), '4.05');
      expect(plateCount(3), '3');
      expect(plateCount(1.5), '1.5');
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
      expect(store.platesDay, '2026-09-23');
      expect(account.plates, 4);
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
      expect(find.text(l.platesBalance('300')), findsOneWidget);
    });

    testWidgets('사기 전에는 연간 단추 밑에 체험과 체험 뒤 값을 적는다', (tester) async {
      final account = Account(client: _server([]))..token = 'account-token';
      await openPaywall(tester, account);
      final l = await L.delegate.load(const Locale('ko'));
      // 스토어가 값을 못 줬으면 정가를 적는다.
      expect(find.text(l.planYearlyTrial('₩29,000')), findsOneWidget);
      expect(find.text(l.proPaid(proPlatesPerMonth)), findsOneWidget);
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
