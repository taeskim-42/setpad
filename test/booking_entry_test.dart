import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/booking_page.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';

/// PT 예약은 **다니는 곳이 있는 사람에게만** 보인다. 혼자 기록하는 사람이
/// 대부분이고, 그 화면에 예약이 뜨면 무엇을 예약하라는 말인지 알 수 없다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<http.Response> reply(
    http.Request request, {
    required bool member,
  }) async {
    final path = request.url.path;
    if (path.endsWith('/api/gyms')) {
      return http.Response(
        jsonEncode({
          'gyms': member
              ? [
                  {'id': 'g1', 'name': 'BPM', 'trainer': '김코치'},
                ]
              : [],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response(
      jsonEncode({'routines': [], 'plan': null, 'selling': false}),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  http.Client server({required bool member}) =>
      MockClient((request) => reply(request, member: member));

  Future<void> open(WidgetTester tester, {required bool member}) async {
    final account = Account(client: server(member: member))..token = 'x';
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: NotesListPage(
          store: NotesStore(),
          account: account,
          onOpen: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('헬스장에 다니면 첫 화면에서 예약할 수 있다', (tester) async {
    await open(tester, member: true);
    expect(find.text('PT 예약'), findsOneWidget);
  });

  testWidgets('다니는 곳이 없으면 예약은 아예 없다', (tester) async {
    await open(tester, member: false);
    expect(find.text('PT 예약'), findsNothing);
  });

  /// 앱을 내렸다 올린다(잠금 → 해제).
  void away(WidgetTester tester) {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  /// 목록 화면과, 그 화면이 물은 길. [now] 는 목록의 시계다.
  Future<(List<String>, GlobalKey<NavigatorState>)> list(
    WidgetTester tester,
    DateTime Function() now,
  ) async {
    final asked = <String>[];
    final account = Account(
      client: MockClient((request) async {
        asked.add(request.url.path);
        return reply(request, member: true);
      }),
    )..token = 'x';
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      CupertinoApp(
        navigatorKey: navigator,
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: NotesListPage(
          store: NotesStore(),
          account: account,
          onOpen: (_) {},
          now: now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (asked, navigator);
  }

  testWidgets(
    '제어 센터·알림 센터(inactive)만 거쳐 돌아오면 체육관·루틴을 다시 묻지 않는다 — 앱을 내렸다 오면 묻는다',
    (tester) async {
      var now = DateTime(2026, 10, 13, 18);
      final (asked, _) = await list(tester, () => now);
      int gyms() => asked.where((p) => p.endsWith('/api/gyms')).length;
      final before = gyms();
      // 다시 물을 때(5분)는 지났다 — 막는 것은 '앱을 내렸는가' 하나다.
      now = now.add(const Duration(minutes: 6));

      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(gyms(), before);

      away(tester);
      await tester.pumpAndSettle();
      expect(gyms(), before + 1);
    },
  );

  testWidgets('세트마다 잠금을 풀어도 체육관·루틴은 5분에 한 번만 묻고, 날이 바뀌면 바로 묻는다', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 13, 23, 50);
    final (asked, _) = await list(tester, () => now);
    int count(String path) => asked.where((p) => p.endsWith(path)).length;
    expect((count('/api/gyms'), count('/api/routines')), (1, 1));

    for (var set = 0; set < 3; set++) {
      now = now.add(const Duration(minutes: 1, seconds: 30));
      away(tester);
      await tester.pumpAndSettle();
    }
    expect((count('/api/gyms'), count('/api/routines')), (1, 1));

    now = now.add(const Duration(minutes: 1)); // 0시를 넘었다 — 오늘의 루틴이 왔다
    away(tester);
    await tester.pumpAndSettle();
    expect((count('/api/gyms'), count('/api/routines')), (2, 2));
  });

  testWidgets('편집기가 위에 있을 때 돌아오면 묻지 않고, 목록이 다시 보일 때 묻는다', (tester) async {
    var now = DateTime(2026, 10, 13, 18);
    final (asked, navigator) = await list(tester, () => now);
    int gyms() => asked.where((p) => p.endsWith('/api/gyms')).length;
    unawaited(
      navigator.currentState!.push(
        CupertinoPageRoute<void>(
          builder: (_) => const CupertinoPageScaffold(child: SizedBox()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    now = now.add(const Duration(minutes: 10));
    away(tester);
    await tester.pumpAndSettle();
    expect(gyms(), 1, reason: '세트를 적는 동안 목록의 루틴은 쓸 데가 없다');

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(gyms(), 2);
  });

  // 한국어는 서버가 적은 문장 그대로(보던 글이 바뀌지 않는다), 다른 언어는 코드를 보고 앱의
  // 말로 — 서버는 영어로만, 옛 서버는 한국어로만 답한다(gym.dart refusalMessage).
  const tooLate = '시작 시각이 지난 예약입니다. 트레이너에게 확인해 주세요.';
  const noPass = 'PT 이용권의 상태·기간·잔여 횟수를 확인해 주세요.';
  final ja = lookupL(const Locale('ja'));
  for (final (locale, saidTooLate, saidNoPass) in [
    (const Locale('ko'), tooLate, noPass),
    (const Locale('ja'), ja.refusedTooLate, ja.refusedNoPass),
  ]) {
    testWidgets('못 잡거나 못 취소하면 그 까닭을 보이고, 시작이 지난 예약은 다가오는 예약에 없다 ($locale)', (
      tester,
    ) async {
      final l = lookupL(locale);
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      http.Response json(Object body, [int status = 200]) =>
          http.Response.bytes(
            utf8.encode(jsonEncode(body)),
            status,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
      final account = Account(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            return json({'error': 'noPass', 'message': noPass}, 409);
          }
          if (request.method == 'DELETE') {
            return json({'error': 'tooLate', 'message': tooLate}, 409);
          }
          return json({
            'bookings': [
              for (final (id, at) in [
                ('past', now.subtract(const Duration(hours: 1))),
                ('soon', tomorrow.add(const Duration(hours: 10))),
              ])
                {
                  'id': id,
                  'gym': 'BPM',
                  'trainer': '김코치',
                  'starts_at': at.toUtc().toIso8601String(),
                  'status': 'booked',
                },
            ],
            'slots': request.url.queryParameters.containsKey('day')
                ? [
                    tomorrow
                        .add(const Duration(hours: 15))
                        .toUtc()
                        .toIso8601String(),
                  ]
                : [],
            'weekdays': [0, 1, 2, 3, 4, 5, 6],
            'trainer': '김코치',
            'duration_min': 50,
            'pass': {'remaining': 3},
          });
        }),
      )..token = 'x';
      await tester.pumpWidget(
        CupertinoApp(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: BookingPage(account: account, gymId: 'g1'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(l.bookingCancel),
        findsOneWidget,
        reason: '시작이 지난 예약은 취소도 받지 않는다',
      );

      await tester.tap(find.text(l.bookingCancel));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CupertinoDialogAction, l.bookingCancel),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(saidTooLate),
        findsOneWidget,
        reason: '못 취소했는데 아무 말이 없으면 취소된 줄 알고 안 온다',
      );

      await tester.tap(find.text('${tomorrow.day}'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15:00'));
      await tester.pumpAndSettle();
      expect(find.text(saidNoPass), findsOneWidget);
      expect(find.text(l.bookingNone), findsNothing);
    });
  }
}
