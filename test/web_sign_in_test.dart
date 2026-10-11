import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/sign_in.dart';

/// 웹 로그인(카카오·아이폰의 Google)은 브라우저를 거쳐 `setpad://signin` 으로
/// 돌아온다. 표(handoff)와 열쇠(verifier)가 짝이 맞아야 서버가 받는다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const share = MethodChannel('setpad/share');

  String? opened;
  setUp(() {
    opened = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(share, (call) async {
          if (call.method != 'open') return null;
          opened = (call.arguments as Map)['url'] as String;
          return true;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(share, null);
  });

  String unpadded(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  test('카카오는 웹 로그인을 열고, 돌아온 표를 verifier 와 함께 든다', () async {
    final pending = signInViaWeb(SignInMethod.kakao, 'https://example.com');
    await Future<void>.delayed(Duration.zero);
    final url = Uri.parse(opened!);
    expect(url.path, '/api/auth/kakao');
    final challenge = url.queryParameters['app']!;
    expect(challenge, hasLength(43), reason: 'sha256 을 base64url 로, 패딩 없이');

    // 엉뚱한 주소는 로그인과 무관하다.
    expect(finishWebSignIn(Uri.parse('setpad://c/gym-1')), isFalse);
    expect(
      finishWebSignIn(Uri.parse('setpad://signin?handoff=a.b.c')),
      isTrue,
    );
    final credential = (await pending)!;
    expect(credential.method, SignInMethod.kakao);
    expect(credential.idToken, 'a.b.c');
    final verifier = credential.verifier!;
    expect(verifier, hasLength(43));
    expect(
      unpadded(sha256.convert(ascii.encode(verifier)).bytes),
      challenge,
      reason: '서버가 표의 challenge 와 맞춰 보는 값',
    );
  });

  test('브라우저에서 그만두면 로그인도 없다', () async {
    final pending = signInViaWeb(SignInMethod.kakao, 'https://example.com');
    await Future<void>.delayed(Duration.zero);
    finishWebSignIn(Uri.parse('setpad://signin?error=cancelled'));
    expect(await pending, isNull);
  });

  test('브라우저를 못 열면 바로 null 이다', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(share, (_) async => false);
    expect(
      await signInViaWeb(SignInMethod.kakao, 'https://example.com'),
      isNull,
    );
  });

  test('표는 handoff·verifier 로 내고, 남의 수단이면 SignInTaken 이다', () async {
    Map<String, Object?>? sent;
    var status = 200;
    final client = MockClient((request) async {
      sent = jsonDecode(request.body) as Map<String, Object?>;
      return http.Response(
        status == 200
            ? jsonEncode({
                'token': 't',
                'user': {'nickname': '철수'},
              })
            : jsonEncode({'error': 'identityTaken'}),
        status,
        headers: {'content-type': 'application/json'},
      );
    });
    const credential = (
      method: SignInMethod.kakao,
      idToken: 'hand.off',
      nickname: null,
      code: null,
      verifier: 'v',
    );
    final got = await exchange(
      credential,
      'https://example.com',
      currentToken: 'me',
      client: client,
    );
    expect(got?.token, 't');
    expect(sent!['handoff'], 'hand.off');
    expect(sent!['verifier'], 'v');
    expect(sent!.containsKey('provider'), isFalse);
    expect(sent!.containsKey('idToken'), isFalse);

    status = 409;
    await expectLater(
      exchange(credential, 'https://example.com', client: client),
      throwsA(isA<SignInTaken>()),
    );
  });
}
