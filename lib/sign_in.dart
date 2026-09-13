import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// 로그인. **켜지 않아도 앱은 그대로 돌아간다.**
///
/// 이 앱은 기록을 기기에 적는 곳이고, 로그인은 그것을 지키기 위한 선택이다 —
/// 폰을 바꿔도 돌아오게 하고, 체육관과 이을 수 있게 한다. 첫 화면에 벽을
/// 세우지 않는다.
///
/// **기기마다 한 가지만 보여준다.** 아이폰은 Apple, 안드로이드는 Google 이다.
/// 둘을 나란히 두면 같은 사람이 기기마다 다른 것을 눌러 계정이 갈라진다.
enum SignInMethod { apple, google }

SignInMethod? get platformSignIn {
  if (kIsWeb) return null;
  if (Platform.isIOS || Platform.isMacOS) return SignInMethod.apple;
  if (Platform.isAndroid) return SignInMethod.google;
  return null;
}

/// 구글이 준 토큰의 대상이 되는 클라이언트. 서버가 확인하는 값과 같아야 한다.
const _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '257502732101-nple77m1bs0p2llunpei9ufdlfvcnc06.apps.googleusercontent.com',
);

/// 제공자에게 받은 신원. 이대로 서버에 넘기면 서버가 서명을 확인한다.
typedef Credential = ({SignInMethod method, String idToken, String? nickname});

Future<Credential?> signInWithPlatform() async {
  switch (platformSignIn) {
    case SignInMethod.apple:
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.fullName],
      );
      final token = apple.identityToken;
      if (token == null) return null;
      // 이름은 처음 한 번만 온다. 그 뒤로는 비어 있으므로 서버가 들고 있어야 한다.
      final given = apple.givenName?.trim() ?? '';
      final family = apple.familyName?.trim() ?? '';
      final name = '$family$given'.trim();
      return (
        method: SignInMethod.apple,
        idToken: token,
        nickname: name.isEmpty ? null : name,
      );
    case SignInMethod.google:
      await GoogleSignIn.instance.initialize(
        serverClientId: _googleServerClientId,
      );
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null) return null;
      return (
        method: SignInMethod.google,
        idToken: token,
        nickname: account.displayName,
      );
    case null:
      return null;
  }
}

/// 제공자 토큰을 우리 토큰으로 바꾼다. 이 토큰이 있어야 백업과 체육관 연결이 된다.
Future<({String token, String nickname})?> exchange(
  Credential credential,
  String endpoint, {
  String? currentToken,
  http.Client? client,
}) async {
  final web = client ?? http.Client();
  try {
    final response = await web
        .post(
          Uri.parse('$endpoint/api/auth/app'),
          headers: {
            'content-type': 'application/json',
            // 이미 로그인해 있으면 수단을 하나 더 붙인다.
            if (currentToken != null) 'authorization': 'Bearer $currentToken',
          },
          body: jsonEncode({
            'provider': credential.method.name,
            'idToken': credential.idToken,
            if (credential.nickname != null) 'nickname': credential.nickname,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return null;
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map) return null;
    final token = body['token'];
    final nickname = (body['user'] as Map?)?['nickname'];
    return token is String
        ? (token: token, nickname: nickname is String ? nickname : '')
        : null;
  } catch (_) {
    return null;
  } finally {
    if (client == null) web.close();
  }
}
