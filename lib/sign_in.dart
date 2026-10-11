import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'api_route.dart';
import 'share.dart' show openUrl;

/// 로그인. **켜지 않아도 앱은 그대로 돌아간다.**
///
/// 이 앱은 기록을 기기에 적는 곳이고, 로그인은 그것을 지키기 위한 선택이다 —
/// 폰을 바꿔도 돌아오게 하고, 체육관과 이을 수 있게 한다. 첫 화면에 벽을
/// 세우지 않는다.
///
/// **웹과 같은 수단을 둔다.** 웹(gym.darak.studio)은 카카오·Google·Apple 로
/// 들어오고, 회원 대부분은 거기서 카카오로 가입한다. 앱에 그 수단이 없으면 같은
/// 사람이 앱에서 새 계정이 되고, 트레이너가 보낸 루틴은 웹 계정에만 남는다.
/// 기기가 직접 하는 것은 하나(아이폰 Apple, 안드로이드 Google)이고 나머지는
/// 웹 로그인을 브라우저로 거쳐 받는다([signInViaWeb]). 수단이 갈려도 같은
/// 사람이 되게, 로그인한 채로 다른 수단을 쓰면 서버가 그 계정에 붙인다.
enum SignInMethod { apple, google, kakao }

/// 이 기기가 직접 하는 수단. 아이폰은 Apple, 안드로이드는 Google 이다.
SignInMethod? get platformSignIn {
  if (kIsWeb) return null;
  if (Platform.isIOS || Platform.isMacOS) return SignInMethod.apple;
  if (Platform.isAndroid) return SignInMethod.google;
  return null;
}

/// 이 기기에서 고를 수 있는 수단. 기기가 직접 하는 것이 먼저다.
List<SignInMethod> get signInMethods => switch (platformSignIn) {
  SignInMethod.apple => const [
    SignInMethod.apple,
    SignInMethod.google,
    SignInMethod.kakao,
  ],
  SignInMethod.google => const [SignInMethod.google, SignInMethod.kakao],
  _ => const [],
};

/// 구글이 준 토큰의 대상이 되는 클라이언트. 서버가 확인하는 값과 같아야 한다.
const _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '257502732101-nple77m1bs0p2llunpei9ufdlfvcnc06.apps.googleusercontent.com',
);

/// 제공자에게 받은 신원. 이대로 서버에 넘기면 서버가 서명을 확인한다.
/// 로그인 한 번으로 받는 것.
///
/// `code` 는 애플만 준다. **탈퇴할 때 애플에 알리려면 이것이 있어야 한다** —
/// id_token 은 신원을 증명할 뿐이고, 폐기의 대상은 이 code 로 바꾼 토큰이다.
/// 로그인 순간에만 오므로 그때 서버로 넘긴다.
///
/// `verifier` 가 있으면 웹 로그인을 거친 것이다 — 그때 `idToken` 은 제공자
/// 토큰이 아니라 서버가 준 표(handoff)이고, 표를 낼 때 `verifier` 를 같이 낸다.
typedef Credential = ({
  SignInMethod method,
  String idToken,
  String? nickname,
  String? code,
  String? verifier,
});

Future<Credential?> signInWithMethod(
  SignInMethod method,
  String endpoint,
) async {
  switch (method) {
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
        code: apple.authorizationCode,
        verifier: null,
      );
    case SignInMethod.google:
      // 아이폰에는 Google SDK 설정(GIDClientID)이 없다. 웹 로그인으로 간다.
      if (platformSignIn != SignInMethod.google) {
        return signInViaWeb(method, endpoint);
      }
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
        code: null,
        verifier: null,
      );
    case SignInMethod.kakao:
      return signInViaWeb(method, endpoint);
  }
}

/// 돌아오기를 기다리는 웹 로그인. 한 번에 하나다.
Completer<Uri?>? _webReturn;

/// 웹 로그인을 기기 브라우저로 거쳐 받는다.
///
/// 앱에는 카카오 SDK 가 없고 들이지 않는다 — 웹이 이미 카카오 로그인을 한다.
/// 브라우저로 `/api/auth/kakao?app=<challenge>` 를 열면 서버가 로그인을 끝내고
/// `setpad://signin?handoff=…` 로 돌아온다(main.dart 의 링크 처리가
/// [finishWebSignIn] 을 부른다). 그 표를 서버에 낼 때 challenge 의 원본
/// (verifier)을 같이 낸다 — 원본은 기기 밖으로 나간 적이 없으니, 주소창으로
/// 오간 표만 가로채서는 쓸 수 없다(PKCE).
// ponytail: verifier 는 메모리에만 있다. 브라우저에 가 있는 동안 iOS 가 앱을
// 죽이면 돌아온 표를 못 받는다 — 그때는 다시 누르면 된다. 자주 생기면 파일에 적는다.
Future<Credential?> signInViaWeb(SignInMethod method, String endpoint) async {
  final verifier = _randomUrlSafe();
  final challenge = _urlSafe(sha256.convert(ascii.encode(verifier)).bytes);
  final path = method == SignInMethod.kakao
      ? '/api/auth/kakao'
      : '/api/signin/${method.name}';

  // 앞서 기다리던 것이 있으면 그만둔다. 돌아오는 표는 하나의 verifier 에만 맞는다.
  final before = _webReturn;
  if (before != null && !before.isCompleted) before.complete(null);
  final waiting = _webReturn = Completer<Uri?>();

  if (!await openUrl('$endpoint$path?app=$challenge')) {
    if (identical(_webReturn, waiting)) _webReturn = null;
    return null;
  }
  final Uri? back;
  try {
    // 안드로이드에서 브라우저를 그냥 닫으면 돌아오는 주소가 없다. 다섯 분이 지나면
    // 그만둔 것으로 본다 — 그만둔 사람에게 '실패' 라고 하지 않는다. 서버가 못 받아 준
    // 것은 서버가 error 를 붙여 앱으로 돌려보낸다(시도를 잃은 경우도).
    back = await waiting.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => null,
    );
  } finally {
    if (identical(_webReturn, waiting)) _webReturn = null;
  }

  // 사람이 그만둔 것(cancelled)과 다시 눌러 앞의 것을 버린 것(null)은 말할 것이
  // 없다. 그 밖의 error 는 서버가 못 받아 준 것이다.
  final error = back?.queryParameters['error'];
  if (error != null && error != 'cancelled') throw const WebSignInFailed();
  final handoff = back?.queryParameters['handoff'];
  if (handoff == null || handoff.isEmpty) return null;
  return (
    method: method,
    idToken: handoff,
    nickname: null,
    code: null,
    verifier: verifier,
  );
}

/// 기다리던 웹 로그인을 그만둔다(null 로 끝낸다). 기다리던 것이 있었으면 true.
///
/// 브라우저는 앱 밖에서 열려, 사람이 카카오 화면에서 그냥 돌아오면 앱은 알 길이
/// 없다. 같은 스티커를 다시 대는 것이 그 신호다(main.dart _openTag).
bool cancelWebSignIn() {
  final waiting = _webReturn;
  if (waiting == null || waiting.isCompleted) return false;
  waiting.complete(null);
  return true;
}

/// `setpad://signin?…` 가 왔다. 기다리던 로그인이 있으면 깨운다. 그 주소였으면 true.
bool finishWebSignIn(Uri uri) {
  if (uri.scheme != 'setpad' || uri.host != 'signin') return false;
  final waiting = _webReturn;
  if (waiting != null && !waiting.isCompleted) waiting.complete(uri);
  return true;
}

String _urlSafe(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

String _randomUrlSafe() {
  final random = Random.secure();
  return _urlSafe(List.generate(32, (_) => random.nextInt(256)));
}

/// 웹 로그인이 error 로 돌아왔거나 끝내 안 돌아왔다. 사람이 그만둔 것과 달리
/// 말해 줘야 한다([Account.signInRefused]).
class WebSignInFailed implements Exception {
  const WebSignInFailed();
}

/// 로그인한 채로 붙이려던 수단이 이미 다른 계정의 것이다. 서버는 말없이 그쪽으로
/// 옮기지 않는다 — 붙였다고 믿은 사람이 남의 계정에 앉게 된다.
class SignInTaken implements Exception {
  const SignInTaken();
}

/// 제공자 토큰을 우리 토큰으로 바꾼다. 이 토큰이 있어야 백업과 체육관 연결이 된다.
Future<({String token, String nickname})?> exchange(
  Credential credential,
  String endpoint, {
  String? currentToken,
  http.Client? client,
}) async {
  final web = client ?? newApiClient();
  try {
    final response = await web
        .post(
          Uri.parse('$endpoint/api/auth/app'),
          headers: {
            'content-type': 'application/json',
            // 이미 로그인해 있으면 수단을 하나 더 붙인다.
            if (currentToken != null) 'authorization': 'Bearer $currentToken',
          },
          body: jsonEncode(
            credential.verifier != null
                ? {
                    'handoff': credential.idToken,
                    'verifier': credential.verifier,
                    // 카카오는 수단만 봐서는 기기를 모른다.
                    if (!kIsWeb && Platform.isIOS)
                      'platform': 'ios'
                    else if (!kIsWeb && Platform.isAndroid)
                      'platform': 'android',
                  }
                : {
                    'provider': credential.method.name,
                    'idToken': credential.idToken,
                    if (credential.nickname != null)
                      'nickname': credential.nickname,
                    if (credential.code != null) 'code': credential.code,
                  },
          ),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 409) throw const SignInTaken();
    if (response.statusCode != 200) return null;
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map) return null;
    final token = body['token'];
    final nickname = (body['user'] as Map?)?['nickname'];
    return token is String
        ? (token: token, nickname: nickname is String ? nickname : '')
        : null;
  } on SignInTaken {
    rethrow;
  } catch (_) {
    return null;
  } finally {
    if (client == null) web.close();
  }
}
