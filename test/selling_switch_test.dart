import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/settings_page.dart';

/// 서버가 뭐라고 답하든 그대로 따르는지 본다. 이 스위치가 새면 팔지 않기로
/// 한 날에도 앱이 이용권을 판다.
http.Client _server({required bool selling, String? plan}) =>
    MockClient((request) async {
      if (request.url.path.endsWith('/api/purchase')) {
        return http.Response(
          jsonEncode({'plan': plan, 'selling': selling}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(jsonEncode({}), 200);
    });

Future<Account> _account({required bool selling, String? plan}) async {
  final a = Account(client: _server(selling: selling, plan: plan))
    ..token = 'test';
  await a.refreshForTest();
  return a;
}

Future<void> _open(WidgetTester tester, Account account) async {
  await tester.pumpWidget(
    CupertinoApp(
      locale: const Locale('ko'),
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: SettingsPage(store: NotesStore(), account: account),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('안 판다고 하면 이용권 칸이 아예 없다', (tester) async {
    final a = await _account(selling: false);
    expect(a.selling, isFalse);
    await _open(tester, a);
    expect(find.text('기록에 마음껏 물어보기'), findsNothing);
    expect(find.text('구매 복원'), findsNothing);
  });

  testWidgets('판다고 하면 이용권 칸이 나온다', (tester) async {
    final a = await _account(selling: true);
    expect(a.selling, isTrue);
    await _open(tester, a);
    expect(find.text('기록에 마음껏 물어보기'), findsOneWidget);
    expect(find.text('구매 복원'), findsOneWidget);
  });

  testWidgets('안 팔아도 이미 산 사람에게는 보인다', (tester) async {
    final a = await _account(selling: false, plan: 'lifetime');
    expect(a.paid, isTrue);
    await _open(tester, a);
    // 무엇을 샀는지 확인할 자리는 팔기를 멈춰도 남아야 한다.
    expect(find.text('기록에 마음껏 물어보기'), findsOneWidget);
  });

  testWidgets('서버에 못 닿으면 팔지 않는다', (tester) async {
    final a = Account(
      client: MockClient((_) async => http.Response('nope', 500)),
    )..token = 'test';
    await a.refreshForTest();
    expect(a.selling, isFalse, reason: '모를 때는 안 파는 쪽이 되돌리기 쉽다');
  });
}
