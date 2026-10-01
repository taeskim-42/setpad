// 같이 하기 창 — 상태를 보여 주기만 하고, 닫아도 연결은 그대로인가.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';
import 'package:setpad/sign_in.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('로그인 대기 중 중복 요청을 막고 취소 후 재시도하면 성공한 창만 닫힌다', (tester) async {
    final dir = Directory.systemTemp.createTempSync('setpad_partner_sign_in_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = NotesStore(directory: dir);
    var provider = Completer<Credential?>();
    late Completer<void> verified;
    var attempts = 0;
    final account = Account(
      storageDir: dir,
      signInWith: () {
        attempts++;
        return provider.future;
      },
      client: MockClient((request) async {
        if (request.url.path.endsWith('/api/me')) verified.complete();
        return http.Response(
          jsonEncode(
            request.url.path.endsWith('/api/auth/app')
                ? {
                    'token': 'member',
                    'user': {'nickname': '도전자'},
                  }
                : {'plan': null, 'selling': false, 'gyms': []},
          ),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: EditorPage(store: store, note: store.create(), account: account),
      ),
    );
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('record-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-partner')));
    await tester.pumpAndSettle();
    final close = find.byKey(const ValueKey('partner-sheet-close'));
    final loginPosition = tester.getCenter(find.text('로그인'));
    await tester.tapAt(loginPosition);
    await tester.pump();
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    await tester.tapAt(loginPosition);
    expect(attempts, 1);
    provider.complete(null);
    await tester.pumpAndSettle();
    expect(account.signedIn, isFalse);
    expect(close, findsOneWidget);
    expect(find.text('로그인').hitTestable(), findsOneWidget);

    await tester.runAsync(() async {
      provider = Completer<Credential?>();
      verified = Completer<void>();
      await tester.tap(find.text('로그인'));
    });
    await tester.pump();
    expect(attempts, 2);
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    await tester.runAsync(() async {
      provider.complete((
        method: SignInMethod.apple,
        idToken: 'id',
        nickname: '도전자',
        code: null,
      ));
      await verified.future;
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(account.signedIn, isTrue);
    expect(close, findsNothing);
    expect(find.byType(EditorPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
    account.dispose();
  });

  testWidgets('로그인 안내 → 코드 표시 → 상대 참여 → 작은 상태 줄 → 상대 기록 → 종료', (tester) async {
    final dir = Directory.systemTemp.createTempSync('setpad_partner_ui_');
    final store = NotesStore(directory: dir);
    addTearDown(() => dir.deleteSync(recursive: true));
    // 서버가 말하는 상태. 테스트가 바꾼다.
    var state = 'waiting';
    Object? record;
    final account = Account(
      storageDir: dir,
      client: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/end')) state = 'ended';
        if (path.endsWith('/join')) {
          return http.Response('{"error":"invalidCode"}', 404);
        }
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'id': 'S1',
              'state': state,
              'role': 'host',
              if (state == 'waiting') ...{
                'code': 'AB23CD',
                'token': 'tok',
                'expiresAt': DateTime.now()
                    .add(const Duration(minutes: 10))
                    .toIso8601String(),
              },
              'partner': state == 'waiting' ? null : '준',
              'endedByMe': state == 'ended' ? true : null,
              'myRevision': 0,
              'partnerRecord': state == 'active' ? record : null,
            }),
          ),
          200,
        );
      }),
    );
    final note = store.create();
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: EditorPage(store: store, note: note, account: account),
      ),
    );
    await tester.pumpAndSettle();

    // 로그인하지 않아도 버튼은 있고, 누르면 로그인으로 이어진다.
    // 같이 하기는 … 메뉴 안에 있다.
    await tester.tap(find.byKey(const ValueKey('record-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-partner')));
    await tester.pumpAndSettle();
    expect(find.text('같이 하려면 로그인이 필요합니다.'), findsOneWidget);
    account
      ..token = 'member'
      ..notifyListeners(); // 로그인이 끝났다 — 같은 창이 다음 단계로 간다.
    await tester.pumpAndSettle();
    expect(find.text('코드 만들기'), findsOneWidget);
    expect(
      find.text('코드 입력'),
      findsOneWidget,
      reason: '코드는 기다리지 않고 바로 고를 수 있다',
    );

    // 틀린 코드는 그 이유를 말한다.
    await tester.tap(find.text('코드 입력'));
    await tester.pumpAndSettle();
    // Keep the form usable above the keyboard on a small screen with larger text.
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(320, 568)
      ..viewInsets = const FakeViewPadding(bottom: 260);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final code = find.byKey(const ValueKey('partner-code'));
    final submit = find.text('코드 입력').last;
    final close = find.byKey(const ValueKey('partner-sheet-close'));
    await tester.ensureVisible(code);
    expect(code.hitTestable(), findsOneWidget);
    await tester.enterText(code, 'abc');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('코드는 여섯 글자입니다. 다시 확인해 주세요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(code);
    await tester.enterText(code, 'zzzzz9');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.textContaining('맞는 코드가 없습니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(close);
    expect(close.hitTestable(), findsOneWidget);
    await tester.tap(close);
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.pumpAndSettle();
    expect(close, findsNothing);

    // 코드를 만든다 — 만료 시간과 함께 보인다. 아직 "함께 운동 중" 이 아니다.
    // 같이 하기는 … 메뉴 안에 있다.
    await tester.tap(find.byKey(const ValueKey('record-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-partner')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('코드 만들기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('AB23CD'), findsOneWidget);
    expect(find.textContaining('뒤 만료'), findsOneWidget);
    expect(find.byKey(const ValueKey('partner-banner')), findsNothing);
    // 창을 닫아도 초대는 살아 있다.
    await tester.tap(close);
    await tester.pump(const Duration(milliseconds: 500));
    expect(note.partner!.state, PartnerState.waiting);

    // 상대가 들어왔다 — 화면이 떠 있는 동안 도는 확인이 알아챈다.
    state = 'active';
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.byKey(const ValueKey('partner-banner')), findsOneWidget);
    expect(find.text('준 님과 함께 운동 중'), findsOneWidget);

    // 상태 줄을 누르면 상대 기록. 아직 없으면 "없음" 이라고 말한다.
    await tester.tap(find.byKey(const ValueKey('partner-banner')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('아직 올라온 기록이 없습니다.'), findsOneWidget);
    record = {
      'revision': 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'result': [
        {
          'name': '풀업',
          'sets': [
            {
              'value': null,
              'unit': 'kg',
              'reps': 8,
              'notes': <String>[],
              'done': true,
            },
          ],
        },
      ],
    };
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('준 님의 기록 · 읽기 전용'), findsOneWidget);
    expect(find.text('풀업'), findsOneWidget);
    expect(find.text('1 8회'), findsOneWidget);
    expect(note.blocks, isEmpty, reason: '상대 기록은 내 문서에 들어오지 않는다');

    // 끝낸다.
    await tester.tap(find.text('함께 운동 종료'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(note.partner!.state, PartnerState.ended);
    expect(find.textContaining('내 기록은 그대로 남아 있습니다'), findsOneWidget);
    await tester.tap(close);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('partner-banner')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    store.dispose();
    account.dispose();
  });
}
