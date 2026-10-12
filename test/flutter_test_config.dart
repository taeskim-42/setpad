import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// 모든 시험 앞에 둔다. 로그인 표의 키체인(lib/api_route.dart vault)은 시험마다 비어
/// 있는 메모리다 — 플랫폼 채널의 답은 위젯 시험의 가짜 시계에서 오지 않아, 키체인을
/// 기다리는 길(남겨 둔 로그인 읽기, 켠 뒤 첫 기기 토큰)이 멈춘다. 앞 시험이 남긴
/// 로그인이 다음 시험으로 새지도 않는다.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  await testMain();
}
