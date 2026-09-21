import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 아이폰 둘을 가까이 대서 초대를 건넨다(ios/Runner/NearbyInvite.swift).
///
/// **연결 수단일 뿐이다.** 오가는 것은 한 번 쓰는 초대 토큰 하나이고, 받은 쪽은 코드를
/// 친 것과 똑같이 서버에 참여를 요청한다. "같이 운동 중" 은 서버가 확정한 뒤다.
///
/// 되는 곳에서만 보인다 — iOS 17 이상의 아이폰. 다른 기기에서는 안내도 버튼도 없고,
/// 코드와 링크는 언제나 그대로 쓸 수 있다. NFC 가 아니므로 화면에서도 그렇게 부르지 않는다.
class Nearby {
  Nearby._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'received') return null;
      final args = (call.arguments as Map).cast<String, Object?>();
      final kind = args['kind'], token = args['token'];
      if (kind is String && token is String) {
        _received.add((kind: kind, token: token));
      }
      return null;
    });
  }
  static final instance = Nearby._();
  static const _channel = MethodChannel('setpad/nearby');
  final _received = StreamController<({String kind, String token})>.broadcast();

  /// 가까이 댄 상대가 건넨 초대. kind 는 'session'(같이 하기) 또는 'plan'(공동 루틴).
  Stream<({String kind, String token})> get received => _received.stream;

  bool? _supported;

  @visibleForTesting
  void reset() => _supported = null;

  /// 이 기기에서 되는가. 한 번 묻고 기억한다.
  Future<bool> get supported async {
    if (_supported != null) return _supported!;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return _supported = false;
    }
    return _supported = await _call('supported');
  }

  /// 초대를 걸어 둔다. 걸려 있는 동안 아이폰을 가까이 대면 시스템이 시작을 묻는다.
  Future<bool> offer({
    required String kind,
    required String token,
    required String title,
  }) async => await supported
      ? _call('offer', {'kind': kind, 'token': token, 'title': title})
      : false;

  /// 거둔다. 창을 닫았거나 초대가 끝났을 때 — 지나가다 닿은 폰에 묻지 않게.
  Future<void> clear() async {
    if (_supported ?? false) await _call('clear');
  }

  Future<bool> _call(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<bool>(method, args) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
