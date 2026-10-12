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
import 'package:setpad/sign_in_sheet.dart';
import 'package:setpad/sign_in.dart';

/// 설정은 누른 그 자리에서 바뀌어야 한다. 나갔다 들어와야 바뀌면 사람은
/// 눌러도 안 먹는 줄 안다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('setpad-settings'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// 서버가 받은 요청의 경로와 본문.
  final sent = <(String, String)>[];
  setUp(sent.clear);

  Future<(NotesStore, Account)> open(WidgetTester tester) async {
    final store = NotesStore();
    final account = Account(
      storageDir: dir,
      client: MockClient((request) async {
        sent.add((request.url.path, request.body));
        if (request.url.path.endsWith('/api/me/sessions/revoke')) {
          return http.Response(jsonEncode({'token': 'fresh'}), 200);
        }
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
      signInWith: (_) async => (
        method: SignInMethod.apple,
        idToken: 'id',
        nickname: '도전자',
        code: null,
        verifier: null,
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

  testWidgets('운동 기록 가져오기는 설정에서 연다', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('settings-workout-import')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('workout-import-text')), findsOneWidget);
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

  testWidgets('로그인 시트는 \'만 14세 이상입니다\' 를 채워야 수단을 고를 수 있고, 그 확인을 서버에 낸다', (
    tester,
  ) async {
    final (_, account) = await open(tester);
    final l = await L.delegate.load(const Locale('ko'));
    await tester.tap(find.text(l.accountSignIn));
    await tester.pumpAndSettle();
    expect(find.text(l.ageConfirm), findsOneWidget);

    // 비워 두고 누르면 아무 일도 없고, 칸을 붉게 가리킨다.
    await tester.tap(find.byKey(const ValueKey('sign-in-apple')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sign-in-apple')), findsOneWidget);
    expect(
      tester.widget<Text>(find.text(l.ageConfirm)).style?.color?.toARGB32(),
      CupertinoColors.systemRed.color.toARGB32(),
    );
    expect(account.signedIn, isFalse);

    await tester.tap(find.byKey(const ValueKey('sign-in-age')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('sign-in-apple')));
    await tester.pumpAndSettle();
    expect(account.signedIn, isTrue);
    final exchange = sent.lastWhere((r) => r.$1.endsWith('/api/auth/app'));
    expect(jsonDecode(exchange.$2)['ageConfirmed'], isTrue);
  });

  testWidgets('모든 기기에서 로그아웃 — 한 번 묻고, 끊었다고 말하고, 이 폰은 새 토큰으로 이어 간다', (
    tester,
  ) async {
    final (_, account) = await open(tester);
    await tester.runAsync(() => account.signIn());
    await tester.pump();
    final l = await L.delegate.load(const Locale('ko'));
    final row = find.byKey(const ValueKey('settings-sign-out-everywhere'));
    await tester.scrollUntilVisible(row, 100);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text(l.accountSignOutEverywhereAsk), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sign-out-everywhere-confirm')));
    await tester.pumpAndSettle();
    expect(find.text(l.accountSignOutEverywhereDone), findsOneWidget);
    expect(account.token, 'fresh');
    expect(account.signedIn, isTrue, reason: '이 폰은 로그인된 채로 남는다');
  });

  testWidgets('확인 칸 전에 만든 계정은 도장 등록 때 한 번 묻는다 — 아니라면 아무것도 보내지 않는다', (
    tester,
  ) async {
    final (_, account) = await open(tester);
    account.token = 't';
    final l = await L.delegate.load(const Locale('ko'));
    final context = tester.element(find.byType(SettingsPage));
    Future<bool?> ask(String answer) async {
      final asked = confirmAge(context, account);
      await tester.pumpAndSettle();
      expect(find.text(l.ageConfirmAsk), findsOneWidget);
      await tester.tap(find.text(answer));
      await tester.pumpAndSettle();
      return asked;
    }

    expect(await ask(l.cancel), isNull);
    expect(sent.where((r) => r.$1.endsWith('/api/me/age')), isEmpty);
    expect(await ask(l.ageConfirm), isTrue);
    expect(sent.where((r) => r.$1.endsWith('/api/me/age')), hasLength(1));
  });

  testWidgets('식단 공유는 기본 꺼짐이고, 다니는 도장이 하나일 때만 켤 수 있다', (tester) async {
    final (store, account) = await open(tester);
    final toggle = find.byKey(const ValueKey('settings-share-meals'));
    expect(toggle, findsNothing, reason: '다니는 곳이 없다');

    account.gyms = [(id: 'g1', name: 'BPM', trainer: null)];
    account.notifyListeners();
    await tester.pump();
    final note = find.textContaining('BPM 트레이너가 봐요');
    await tester.scrollUntilVisible(note, 100);
    expect(note, findsOneWidget);
    expect(store.sharesMeals, isFalse, reason: '끼니는 건강 정보라 회원이 켜야 간다');
    await tester.tap(
      find.descendant(of: toggle, matching: find.byType(CupertinoSwitch)),
    );
    await tester.pump();
    expect(store.sharesMeals, isTrue);

    account.gyms = [
      (id: 'g1', name: 'BPM', trainer: null),
      (id: 'g2', name: 'Core', trainer: null),
    ];
    account.notifyListeners();
    await tester.pump();
    expect(toggle, findsNothing, reason: '여럿이면 어디로 보낼지 앱이 고르지 않는다');
    // 저장은 모아서 한다 — 그 타이머가 끝날 때까지.
    await tester.pump(const Duration(milliseconds: 600));
  });
}
