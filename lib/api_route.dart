/// 서버로 가는 길. **한 길이 막혀도 이어 가기 위한 자리다.**
///
/// 2026-09-21, 같은 서버로 가는 두 주소 중 하나만 특정 지역에서 TCP 연결이 안 되는
/// 일이 있었다(맘마로그, Railway 제공 주소). 서버는 멀쩡했고 DNS 도 됐다 — 막힌 것은
/// 그 진입 IP 로 가는 길 하나였다. 중국만의 일이 아니다: 어느 통신사, 어느 지역에서도
/// 한 진입 경로는 끊길 수 있다.
///
/// 그래서 앱은 두 가지를 지킨다.
///  1. 주소는 **우리 도메인**만 쓴다(기본값 gym.darak.studio). 인프라 사업자의
///     도메인을 앱에 박으면 그 DNS 를 우리가 못 바꾼다.
///  2. 예비 주소가 주어져 있으면, **연결 자체가 안 될 때만** 그쪽으로 한 번 더 간다.
///     서버가 답한 것(401·403·4xx·5xx)은 길이 통한 것이므로 갈아타지 않는다.
///
/// 예비 주소는 빌드할 때 준다: `--dart-define=API_BACKUP=https://…`. 비어 있으면
/// 길은 하나다. **검증하지 않은 주소를 기본으로 넣지 않는다** — 예비 경로는 기본
/// 경로와 다른 사업자·다른 진입 IP 여야 하고, 대상 지역의 실제 회선에서 확인한 뒤에
/// 넣는다(docs/access-routes.md).
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

const apiBackup = String.fromEnvironment('API_BACKUP');

/// 연결 단계가 이 시간 안에 안 되면 그 길은 막힌 것으로 본다. 기다리기만 하면
/// 운영체제 기본값(1분 남짓)까지 매달려 있고, 그동안 화면은 아무 말도 못 한다.
const connectTimeout = Duration(seconds: 8);

/// 예비 길이 통했으면 이만큼은 그쪽을 먼저 쓴다. 그 뒤에 기본 길을 다시 본다 —
/// 영영 예비에 눌러앉지도, 요청마다 막힌 길을 먼저 두드리지도 않는다.
const _rememberFor = Duration(minutes: 10);

/// 앱의 모든 서버 요청이 쓰는 클라이언트.
http.Client newApiClient({
  String primary = const String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://gym.darak.studio',
  ),
  String backup = apiBackup,
}) {
  // 웹에는 dart:io 가 없다. 브라우저가 연결을 쥐고 있어 여기서 할 일도 없다.
  if (kIsWeb) return http.Client();
  final inner = IOClient(HttpClient()..connectionTimeout = connectTimeout);
  return backup.isEmpty
      ? inner
      : FailoverClient(
          inner,
          primary: Uri.parse(primary),
          backup: Uri.parse(backup),
        );
}

/// 기본 주소로 가는 요청을, 연결이 안 되면 예비 주소로 **한 번** 다시 보낸다.
///
/// 다시 보내는 것은 같은 요청이다 — 본문도 머리말도 그대로라서 기록의 id 와
/// 멱등성 열쇠가 유지된다. 첫 요청이 서버에 닿았는지 알 수 없는 실패(응답 대기 중
/// 시간 초과 등)는 여기서 다루지 않는다: 그것은 부르는 쪽의 재시도이고, 서버가
/// 같은 id 를 한 줄로 합친다.
class FailoverClient extends http.BaseClient {
  FailoverClient(this._inner, {required this.primary, required this.backup});
  final http.Client _inner;
  final Uri primary, backup;

  /// 앱 전체가 같이 기억한다. 요청마다 클라이언트를 새로 만들기 때문이다.
  static DateTime? _backupUntil;

  @visibleForTesting
  static void forget() => _backupUntil = null;

  bool get _preferBackup =>
      _backupUntil != null && DateTime.now().isBefore(_backupUntil!);

  bool _ours(Uri url) => url.host == primary.host || url.host == backup.host;

  Uri _via(Uri route, Uri url) => url.replace(
    scheme: route.scheme,
    host: route.host,
    port: route.hasPort ? route.port : null,
  );

  /// 연결 단계의 실패인가. 서버의 답이나 부르는 쪽의 시간 초과는 아니다.
  static bool _routeFailure(Object error) =>
      error is SocketException ||
      error is HandshakeException ||
      error is TlsException ||
      (error is http.ClientException &&
          RegExp(
            'SocketException|Connection (refused|reset|closed|timed out)|'
            'Failed host lookup|HandshakeException',
          ).hasMatch(error.message));

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 다시 보낼 수 있는 요청만 갈아탄다(본문을 통째로 들고 있는 것).
    if (request is! http.Request || !_ours(request.url)) {
      return _inner.send(request);
    }
    final routes = _preferBackup ? [backup, primary] : [primary, backup];
    Object? failure;
    StackTrace? trace;
    for (final route in routes) {
      final copy = http.Request(request.method, _via(route, request.url))
        ..headers.addAll(request.headers)
        ..bodyBytes = request.bodyBytes
        ..followRedirects = request.followRedirects;
      try {
        final response = await _inner.send(copy);
        // 답이 왔다 = 이 길은 통한다. 무슨 답이든 갈아탈 이유가 아니다.
        _backupUntil = route == backup
            ? DateTime.now().add(_rememberFor)
            : null;
        return response;
      } catch (error, stack) {
        if (!_routeFailure(error)) rethrow;
        failure = error;
        trace = stack;
      }
    }
    // 두 길이 다 막혔다. 부르는 쪽은 이것을 "그물 없음" 으로 다룬다 — 기록은 기기에
    // 남고, 로그아웃하지 않고, 다음 기회에 다시 보낸다.
    Error.throwWithStackTrace(failure!, trace!);
  }

  @override
  void close() => _inner.close();
}
