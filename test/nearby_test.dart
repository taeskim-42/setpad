// 가까이 대서 건네는 초대 — 되는 기기에서만 보이고, 받은 토큰은 코드와 같은 길로 간다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/nearby.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';

const channel = MethodChannel('setpad/nearby');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('아이폰에서만 안내가 보이고, 초대가 열린 동안만 걸려 있으며, 받은 초대는 한 번만 참여한다', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    Nearby.instance.reset();
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return true;
    });
    final dir = Directory.systemTemp.createTempSync('setpad_nearby_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = NotesStore(directory: dir);
    var joins = 0;
    var state = 'waiting';
    final account = Account(
      storageDir: dir,
      client: MockClient((request) async {
        if (request.url.path.endsWith('/join')) {
          joins++;
          expect(
            jsonDecode(request.body)['token'],
            'TOKEN-FROM-THE-OTHER-PHONE',
          );
          state = 'active';
        }
        if (request.url.path.endsWith('/end')) state = 'ended';
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'id': 'S1',
              'state': state,
              'role': state == 'waiting' ? 'host' : 'guest',
              if (state == 'waiting') ...{
                'code': 'AB23CD',
                'token': 'MY-OWN-INVITE-TOKEN-0001',
                'expiresAt': DateTime.now()
                    .add(const Duration(minutes: 10))
                    .toIso8601String(),
              },
              'partner': state == 'active' ? '미나' : null,
              'claimed': true,
              'myRevision': 0,
              'partnerRecord': null,
            }),
          ),
          200,
        );
      }),
    )..token = 'member';
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

    // 초대를 띄우면 그 토큰이 걸린다. 화면에는 NFC 라는 말이 없다.
    // 같이 하기는 … 메뉴 안에 있다.
    await tester.tap(find.byKey(const ValueKey('record-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-partner')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('코드 만들기'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('nearby-hint')), findsOneWidget);
    expect(find.textContaining('NFC'), findsNothing);
    final offer = calls.lastWhere((c) => c.method == 'offer');
    expect(offer.arguments, {
      'kind': 'session',
      'token': 'MY-OWN-INVITE-TOKEN-0001',
      'title': '',
    });
    // 창을 닫으면 거둔다 — 지나가다 닿은 폰에 묻지 않게.
    await tester.tap(find.text('확인'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(calls.last.method, 'clear');

    // 상대가 가까이 대서 건넨 초대가 (같은 것이 두 번) 도착한다 → 참여는 한 번.
    Future<void> arrive() =>
        tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(
            const MethodCall('received', {
              'kind': 'session',
              'token': 'TOKEN-FROM-THE-OTHER-PHONE',
            }),
          ),
          (_) {},
        );
    await arrive();
    await arrive();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(joins, 1);
    expect(note.partner!.state, PartnerState.active);
    expect(find.text('미나 님과 함께 운동 중'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    store.dispose();
    account.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('아이폰이 아니면 안내도 네이티브 호출도 없다', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    Nearby.instance.reset();
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return true;
    });
    final dir = Directory.systemTemp.createTempSync('setpad_nearby_android_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = NotesStore(directory: dir);
    final account = Account(
      storageDir: dir,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'id': 'S1',
            'state': 'waiting',
            'role': 'host',
            'code': 'AB23CD',
            'token': 'MY-OWN-INVITE-TOKEN-0001',
            'expiresAt': DateTime.now()
                .add(const Duration(minutes: 10))
                .toIso8601String(),
            'myRevision': 0,
          }),
          200,
        ),
      ),
    )..token = 'member';
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: EditorPage(store: store, note: store.create(), account: account),
      ),
    );
    await tester.pumpAndSettle();
    // 같이 하기는 … 메뉴 안에 있다.
    await tester.tap(find.byKey(const ValueKey('record-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-partner')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('코드 만들기'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('AB23CD'), findsOneWidget, reason: '코드는 어디서나 된다');
    expect(find.byKey(const ValueKey('nearby-hint')), findsNothing);
    expect(calls, isEmpty, reason: '안 되는 기기에서는 네이티브를 부르지도 않는다');

    await tester.pumpWidget(const SizedBox());
    store.dispose();
    account.dispose();
    debugDefaultTargetPlatformOverride = null;
  });
}
