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

  http.Client server({required bool member}) => MockClient((request) async {
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
  });

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

  testWidgets(
    '제어 센터·알림 센터(inactive)만 거쳐 돌아오면 체육관·루틴을 다시 묻지 않는다 — 앱을 내렸다 오면 묻는다',
    (tester) async {
      final asked = <String>[];
      final inner = server(member: true);
      final account = Account(
        client: MockClient((request) async {
          asked.add(request.url.path);
          return http.Response.fromStream(await inner.send(request));
        }),
      )..token = 'x';
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
      int gyms() => asked.where((p) => p.endsWith('/api/gyms')).length;
      final before = gyms();

      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(gyms(), before);

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
      await tester.pumpAndSettle();
      expect(gyms(), before + 1);
    },
  );

  testWidgets('못 잡거나 못 취소하면 서버가 적은 까닭을 보이고, 시작이 지난 예약은 다가오는 예약에 없다', (
    tester,
  ) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    http.Response json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
    final account = Account(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          return json({
            'error': 'noPass',
            'message': 'PT 이용권의 상태·기간·잔여 횟수를 확인해 주세요.',
          }, 409);
        }
        if (request.method == 'DELETE') {
          return json({
            'error': 'tooLate',
            'message': '시작 시각이 지난 예약입니다. 트레이너에게 확인해 주세요.',
          }, 409);
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
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: BookingPage(account: account, gymId: 'g1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('예약 취소'), findsOneWidget, reason: '시작이 지난 예약은 취소도 받지 않는다');

    await tester.tap(find.text('예약 취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CupertinoDialogAction, '예약 취소'));
    await tester.pumpAndSettle();
    expect(
      find.text('시작 시각이 지난 예약입니다. 트레이너에게 확인해 주세요.'),
      findsOneWidget,
      reason: '못 취소했는데 아무 말이 없으면 취소된 줄 알고 안 온다',
    );

    await tester.tap(find.text('${tomorrow.day}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15:00'));
    await tester.pumpAndSettle();
    expect(find.text('PT 이용권의 상태·기간·잔여 횟수를 확인해 주세요.'), findsOneWidget);
    expect(find.text('그날은 빈 시간이 없어요.'), findsNothing);
  });
}
