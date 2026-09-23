import 'package:flutter/services.dart';

const _channel = MethodChannel('setpad/rest_alarm');

/// 휴식이 끝났다고 손목까지 알린다(iOS 26 AlarmKit — 경보가 짝지은 워치로 넘어간다).
///
/// 되지 않는 곳(iOS 26 전, Android, 테스트)에서는 false 다. 폰의 신호음은 이것과
/// 따로 늘 난다 — 이것은 폰을 보지 않고 있을 때를 위한 덤이다.
Future<bool> ringRestAlarm(String title) => _call('ring', {'title': title});

/// 경보 권한을 묻는다. 이미 정했으면 묻지 않고 그 답을 돌려준다.
Future<bool> authorizeRestAlarm() => _call('authorize');

Future<bool> _call(String method, [Map<String, Object?>? args]) async {
  try {
    return await _channel.invokeMethod<bool>(method, args) ?? false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}
