import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/settings_page.dart';
import 'package:setpad/sign_in.dart';

/// 설정은 누른 그 자리에서 바뀌어야 한다. 나갔다 들어와야 바뀌면 사람은
/// 눌러도 안 먹는 줄 안다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('setpad-settings'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<(NotesStore, Account)> open(WidgetTester tester) async {
    final store = NotesStore();
    final account = Account(
      storageDir: dir,
      client: MockClient((request) async {
        if (request.url.path.endsWith('/api/auth/app')) {
          return http.Response(
            jsonEncode({
              'token': 't',
              'user': {'nickname': '도전자'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'plan': null, 'selling': false, 'gyms': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      signInWith: () async => (
        method: SignInMethod.apple,
        idToken: 'id',
        nickname: '도전자',
        code: null,
      ),
    );
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: SettingsPage(store: store, account: account),
      ),
    );
    await tester.pump();
    return (store, account);
  }

  testWidgets('무게 단위를 바꾸면 그 자리에서 바뀐다', (tester) async {
    final (store, _) = await open(tester);
    expect(find.text('kg'), findsOneWidget);
    store.setWeightUnit('lb');
    // 저장은 모아서 하므로 디바운스가 끝날 때까지 기다린다.
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('lb'), findsOneWidget, reason: '저장소 변화가 화면에 닿아야 한다');
  });

  testWidgets('이름을 눌러도 로그아웃되지 않는다', (tester) async {
    final (_, account) = await open(tester);
    await tester.runAsync(() => account.signIn());
    await tester.pump();
    expect(find.text('도전자'), findsOneWidget);
    await tester.tap(find.text('도전자'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(account.signedIn, isTrue, reason: '이름은 누르는 버튼이 아니다');
    // 나가는 길은 따로 있다.
    expect(find.text('로그아웃'), findsOneWidget);
  });
}
