import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
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

  testWidgets('공동 루틴은 첫 화면에도 설정에도 없다 — 같이 짜는 것은 함께 운동하기가 한다', (tester) async {
    final account = Account(client: server(member: false))..token = 'x';
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
    expect(find.text('공동 루틴'), findsNothing);
    await tester.tap(find.byIcon(CupertinoIcons.gear));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-plans')), findsNothing);
    expect(find.text('공동 루틴'), findsNothing);
  });
}
