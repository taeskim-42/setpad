// 같이 하기 창 — 상태를 보여 주기만 하고, 닫아도 연결은 그대로인가.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter/services.dart';
import 'package:setpad/account.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
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
      signInWith: (_) {
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
    // 수단을 고르는 시트가 먼저 뜬다(sign_in_sheet.dart). 고르면 제공자 창이다.
    // 기다리는 동안 돌아가는 표시가 있어 settle 은 끝나지 않는다 — 시트가 뜰 만큼만.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // 수단을 고르기 전에 '만 14세 이상입니다' 를 채운다.
    await tester.tap(find.byKey(const ValueKey('sign-in-age')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('sign-in-apple')));
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
      // 시트에서 고르는 것까지 같은 runAsync 안이다 — 밖에서 고르면 시트의
      // 결과가 이 영역의 큐에 남아 로그인이 시작되지 않는다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const ValueKey('sign-in-age')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('sign-in-apple')));
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
        verifier: null,
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

  /// 로그인한 계정과, 시험이 말을 정하는 서버. 요청은 (경로, 본문)으로 적어 둔다.
  ({Account account, Map<String, Object?> state, List<(String, Map)> asked})
  signedIn(Directory dir) {
    final state = <String, Object?>{};
    final asked = <(String, Map)>[];
    final account = Account(
      storageDir: dir,
      client: MockClient((request) async {
        final path = request.url.path;
        final body = request.body.isEmpty
            ? const {}
            : jsonDecode(request.body) as Map;
        asked.add((path, body));
        if (path.endsWith('/events')) return http.Response('', 404);
        if (path.endsWith('/record')) {
          return http.Response('{"revision":1}', 200);
        }
        if (path.contains('/partner-sessions')) {
          return http.Response.bytes(utf8.encode(jsonEncode(state)), 200);
        }
        return http.Response(
          jsonEncode({'plan': null, 'selling': false, 'gyms': []}),
          200,
        );
      }),
    )..token = 'member';
    return (account: account, state: state, asked: asked);
  }

  Map<String, Object?> setJson(String id, int reps, String key, String name) =>
      {
        'id': id,
        'value': 60,
        'unit': 'kg',
        'reps': reps,
        'notes': <String>[],
        'done': true,
        'by': {'key': key, 'name': name},
      };

  testWidgets(
    '같이 기록이 기본: "함께 운동 중" 배너, 머리의 같이 하기 단추와 점, 남의 세트는 못 고치고, 상대가 끝내면 띠로 알린다',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('setpad_partner_live_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = NotesStore(directory: dir);
      final t = signedIn(dir);
      t.state.addAll({
        'id': 'S1',
        'state': 'active',
        'role': 'host',
        'partner': '준',
        'myRevision': 0,
        'now': 1700000000000,
        'me': 'mmmm',
        'members': [
          {'key': 'jjjj', 'name': '준', 'record': null},
        ],
        'room': 4,
        'doc': {
          'version': 1,
          'blocks': [
            {
              'id': 'B',
              'name': '벤치',
              'sets': [
                setJson('m1', 10, 'mmmm', '미나'),
                setJson('j1', 8, 'jjjj', '준'),
              ],
            },
          ],
          // 서버는 문서가 있는 세션마다 확인 목록을 보낸다 — 비어 있으면 아무도 확인하지 않았다.
          'accepted': <String>[],
          'finalizedVersion': null,
        },
      });
      final note = store.create()
        ..partner = PartnerSession(
          id: 'S1',
          host: true,
          state: PartnerState.active,
          partnerName: '준',
        );
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: EditorPage(store: store, note: note, account: t.account),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('준 님과 함께 운동 중'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('partner-routine-confirm-editor')),
        findsNothing,
        reason: '루틴 확인은 고른 사람에게만',
      );
      expect(find.byKey(const ValueKey('header-partner-dot')), findsOneWidget);
      expect(note.blocks.single.sets.map((s) => s.author), [null, '준']);

      // 남의 세트를 누르면 고칠 수 없다고 말하고, 아무것도 바뀌지 않는다.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('set-cell-1')));
      await tester.pump();
      expect(find.textContaining('상대가 적은 세트는 고칠 수 없어요'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pump(const Duration(milliseconds: 300));

      // 머리의 단추로 창을 연다. 루틴으로 굳히는 것은 거기서 고른다.
      await tester.tap(find.byKey(const ValueKey('header-partner')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.byKey(const ValueKey('partner-routine-plan')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('partner-routine-plan')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('partner-routine-plan')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        t.asked.where((a) => a.$2['action'] == 'accept').single.$2['version'],
        1,
      );
      await tester.tap(find.byKey(const ValueKey('partner-sheet-close')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(note.partner!.routinePlanning, isTrue);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('partner-banner')),
          matching: find.textContaining('루틴 함께 만들기'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('partner-routine-confirm-editor')),
        findsOneWidget,
      );

      // 상대가 끝냈다 — 띠가 한 줄로 말한다. 남의 세트는 남고 여전히 읽기 전용이다.
      t.state
        ..['state'] = 'ended'
        ..['endedByMe'] = false
        ..['members'] = []
        ..['doc'] = null;
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.byKey(const ValueKey('partner-ended')), findsOneWidget);
      expect(find.textContaining('준 님이 함께 운동을 종료했습니다'), findsOneWidget);
      expect(find.byKey(const ValueKey('partner-banner')), findsNothing);
      expect(note.blocks.single.sets.map((s) => s.author), [null, '준']);
      await tester.tap(find.byKey(const ValueKey('set-cell-1')));
      await tester.pump();
      expect(find.textContaining('상대가 적은 세트는 고칠 수 없어요'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(CupertinoAlertDialog),
          matching: find.text('확인'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      // 띠는 닫으면 사라진다.
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('partner-ended')),
          matching: find.text('확인'),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('partner-ended')), findsNothing);

      await tester.pumpWidget(const SizedBox());
      store.dispose();
      t.account.dispose();
    },
  );

  testWidgets('링크로 받은 초대는 그 기록의 편집기가 토큰으로 참여한다', (tester) async {
    final dir = Directory.systemTemp.createTempSync('setpad_partner_link_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = NotesStore(directory: dir);
    final t = signedIn(dir);
    t.state.addAll({
      'id': 'S9',
      'state': 'active',
      'role': 'guest',
      'partner': '미나',
      'myRevision': 0,
    });
    final note = store.create();
    const token = 'abcdefghijklmnopqrstuvwx';
    pendingPartnerJoin.value = (
      noteId: 'another-note',
      token: 'zzzz${'z' * 20}',
    );
    pendingPartnerJoin.value = (noteId: note.id, token: token);
    addTearDown(() => pendingPartnerJoin.value = null);
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: EditorPage(store: store, note: note, account: t.account),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final joins = t.asked.where((a) => a.$1.endsWith('/join')).toList();
    expect(joins.single.$2['token'], token);
    expect(pendingPartnerJoin.value, isNull);
    expect(note.partner?.state, PartnerState.active);
    expect(find.text('미나 님과 함께 운동 중'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
    t.account.dispose();
  });

  testWidgets(
    '코드 입력을 누르면 클립보드의 코드를 한 번만 읽어 칩으로 권하고, 누르면 그 코드로 참여한다 · 기다리는 코드는 공유한다',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('setpad_partner_paste_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = NotesStore(directory: dir);
      final t = signedIn(dir);
      t.state.addAll({
        'id': 'S2',
        'state': 'waiting',
        'role': 'host',
        'code': 'AB23CD',
        'token': 'tok_abcdefghijklmnopqrstu',
        'expiresAt': DateTime.now()
            .add(const Duration(minutes: 10))
            .toIso8601String(),
        'myRevision': 0,
      });
      var clipboardReads = 0;
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            clipboardReads++;
            return {'text': '한 명 더 초대 · 코드 XY34ZW'};
          }
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      String? shared;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('setpad/share'),
        (call) async {
          shared = (call.arguments as Map)['text'] as String?;
          return true;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('setpad/share'),
          null,
        ),
      );
      final note = store.create();
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: EditorPage(store: store, note: note, account: t.account),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('header-partner-dot')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('header-partner')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(clipboardReads, 0, reason: '코드 입력을 누르기 전에는 클립보드를 읽지 않는다');
      await tester.tap(find.text('코드 입력'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('상대 화면에 보이는 여섯 글자를 입력하세요.'), findsOneWidget);
      // 칸은 저절로 포커스된다 — 칸을 다시 누르지 않아도 칩이 보인다.
      expect(clipboardReads, 1);
      expect(find.text('붙여넣기 XY34ZW'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('partner-code')));
        await tester.pump();
      }
      expect(clipboardReads, 1, reason: '칸을 누를 때마다 다시 읽지 않는다(붙여넣기 허락 창)');
      final code = tester.widget<CupertinoTextField>(
        find.byKey(const ValueKey('partner-code')),
      );
      expect(code.controller!.text, isEmpty, reason: '칩을 누르기 전에는 칸에 쓰지 않는다');
      await tester.tap(find.byKey(const ValueKey('partner-paste')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(code.controller!.text, 'XY34ZW');
      expect(
        t.asked.where((a) => a.$1.endsWith('/join')).single.$2['code'],
        'XY34ZW',
      );

      // 서버는 기다리는 초대(내 코드)를 말한다 — 코드와 링크를 공유 시트로 보낸다.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('AB23CD'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('partner-share')));
      await tester.pump();
      expect(shared, contains('AB23CD'));
      expect(shared, contains('/j/tok_abcdefghijklmnopqrstu'));
      expect(copied, isNull);

      await tester.pumpWidget(const SizedBox());
      store.dispose();
      t.account.dispose();
    },
  );

  testWidgets('홈 목록 맨 위에 같이 운동 중인 기록이 있고, 같이 한 기록 줄에는 상대 이름이 붙는다', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('setpad_partner_home_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = NotesStore(directory: dir);
    final live = store.create()
      ..partner = PartnerSession(
        id: 'S1',
        host: true,
        state: PartnerState.active,
        partnerName: '준',
      );
    store.update(live, [
      ExerciseBlock('벤치', [LoggedSet(value: 60, unit: 'kg', reps: 10)]),
    ]);
    final past =
        store.create(at: DateTime.now().subtract(const Duration(days: 2)))
          ..partner = PartnerSession(
            id: 'S0',
            host: false,
            state: PartnerState.ended,
            partnerName: '소라, 준',
          );
    store.update(past, [
      ExerciseBlock('스쿼트', [LoggedSet(value: 100, unit: 'kg', reps: 5)]),
    ]);
    Note? opened;
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: NotesListPage(store: store, onOpen: (n) => opened = n),
      ),
    );
    await tester.pump();
    expect(find.byKey(ValueKey('partner-live-${live.id}')), findsOneWidget);
    expect(find.text('준 님과 함께 운동 중'), findsOneWidget);
    expect(find.textContaining('소라 +1'), findsOneWidget);
    await tester.tap(find.text('준 님과 함께 운동 중'));
    await tester.pump();
    expect(opened, live);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
