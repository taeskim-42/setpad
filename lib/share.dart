import 'package:flutter/services.dart';

const _channel = MethodChannel('setpad/share');

/// 시스템 공유 시트로 글을 넘긴다. 띄웠으면 true.
///
/// 플러그인을 들이지 않았다 — 필요한 것은 글 한 줄을 공유 시트에 올리는 일뿐이고,
/// 그것은 플랫폼마다 몇 줄이다(ios/Runner/AppDelegate.swift, MainActivity.kt).
/// 못 띄우는 곳(데스크톱, 테스트)에서는 false 를 돌려주고 부르는 쪽이 복사로 대신한다.
/// 링크를 기기 브라우저로 연다. 열었으면 true. 개인정보 처리방침처럼 "누르면
/// 열려야 하는" 링크 몇 개가 전부라 플러그인을 들이지 않는다.
Future<bool> openUrl(String url) async {
  try {
    return await _channel.invokeMethod<bool>('open', {'url': url}) ?? false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}

/// 아이폰의 앱 안 로그인 창(ASWebAuthenticationSession)으로 [url] 을 연다.
/// `setpad://` 로 돌아온 주소를 돌려주고, 사람이 닫으면 null 이다. 창을 못
/// 띄웠거나 로그인 창이 실패하면 PlatformException 이 그대로 나간다.
Future<String?> openSignInSheet(String url) =>
    _channel.invokeMethod<String>('signIn', {'url': url});

Future<bool> shareText(String text) async {
  try {
    return await _channel.invokeMethod<bool>('share', {'text': text}) ?? false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}
