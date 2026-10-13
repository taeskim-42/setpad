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
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'app_locale.dart';
import 'l10n/generated/app_localizations.dart';

const apiBackup = String.fromEnvironment('API_BACKUP');

/// 서버가 준 표(계정 토큰·기기 토큰)를 두는 곳 — 아이폰 키체인, 안드로이드 키스토어.
///
/// **문서함의 평문 파일에 두지 않는다.** 그 파일은 기기·PC 백업에 같이 실렸고, 샌
/// 계정 토큰은 /api/me 를 부를 때마다 서른 날이 새로 늘어 끝없이 쓸 수 있었다. 키체인
/// 항목은 이 기기에서만 풀리고(첫 잠금 해제 뒤) 다른 기기로 옮겨지지 않는다. 안드로이드는
/// 이 저장소의 파일을 백업에서 뺀다(res/xml/backup_rules.xml·data_extraction_rules.xml).
const vault = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

/// [vault] 에 묻는다. 못 쓰면(웹, 시험, 키체인이 아직 잠긴 때) null — 표를 못 남긴 것은
/// 다시 받거나 다시 로그인하면 되는 일이지, 앱이 멈출 일이 아니다.
Future<T?> vaulted<T>(Future<T> Function() use) async {
  if (kIsWeb) return null;
  try {
    return await use();
  } catch (e) {
    debugPrint('키체인을 쓰지 못했다: $e');
    return null;
  }
}

/// 연결 단계가 이 시간 안에 안 되면 그 길은 막힌 것으로 본다. 기다리기만 하면
/// 운영체제 기본값(1분 남짓)까지 매달려 있고, 그동안 화면은 아무 말도 못 한다.
const connectTimeout = Duration(seconds: 8);

/// 예비 길이 통했으면 이만큼은 그쪽을 먼저 쓴다. 그 뒤에 기본 길을 다시 본다 —
/// 영영 예비에 눌러앉지도, 요청마다 막힌 길을 먼저 두드리지도 않는다.
const _rememberFor = Duration(minutes: 10);

/// 서버가 견주는 앱 판 번호. `1.6.1` → 10601, 읽을 수 없으면 0. 운영의 MIN_APP_BUILD 도
/// 이 수로 적는다 — 1.6.2 아래를 막으려면 10602 다(gymdojo lib/app-build.ts).
///
/// **스토어의 빌드 번호를 쓰지 않는다.** 아이폰은 96 처럼 하나씩, 안드로이드는
/// 2020년부터의 분(350만쯤)으로 매겨서, 서버의 최소 판(MIN_APP_BUILD) 하나로 두 폰을
/// 함께 가를 수 없다 — 안드로이드 수로 올리면 아이폰이 모두 막힌다. 판 이름은 같다.
int releaseNumber(String version) {
  final n = version.split('.').map(int.tryParse).toList();
  if (n.length != 3 || n.any((x) => x == null || x < 0)) return 0;
  if (n[1]! > 99 || n[2]! > 99) return 0;
  return n[0]! * 10000 + n[1]! * 100 + n[2]!;
}

/// 이 앱의 판 번호. 판 이름은 빌드할 때 준다(fastlane 이 pubspec 의 것을
/// `--dart-define=SETPAD_VERSION=…` 로 넣는다). 없으면(손으로 돌린 빌드) 0 이고, 판
/// 머리말을 보내지 않는다 — 서버는 머리말 없는 요청을 막지 않는다.
final appBuild = releaseNumber(const String.fromEnvironment('SETPAD_VERSION'));

/// 앱이 보여 주는 언어의 태그(`ko`, `en`, `zh-Hant` …). 화면과 같은 규칙([appLocale])으로
/// 기기 언어에서 고른다 — 앱 안에 따로 언어 설정이 없다. 모든 요청에 `accept-language` 로
/// 실어, 서버가 사람에게 쓰는 말(거절의 까닭, 알림)을 화면과 같은 언어로 고르게 한다
/// (gymdojo 는 ko 면 한국어, 그 밖은 영어). [device] 는 시험이 기기 언어를 줄 자리다.
String appLanguage([List<Locale>? device]) => appLocale(
  device ?? PlatformDispatcher.instance.locales,
  L.supportedLocales,
).toLanguageTag();

/// 서버가 이 판을 더는 받지 않는다(426 updateRequired). 홈이 업데이트 안내를 띄운다.
final updateRequired = ValueNotifier<bool>(false);

/// 서버가 쉬었다 오라고 한 시간(429·503 의 Retry-After 초). 없으면 null.
Duration? retryAfter(http.BaseResponse response) {
  final seconds = int.tryParse(response.headers['retry-after'] ?? '');
  return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
}

/// 앱 전체가 함께 쓰는 클라이언트. **닫지 않는다** — 연결을 다시 써서 요청마다
/// TCP·TLS 를 새로 맺지 않는다(서버는 싱가포르다. 새로 맺는 데 왕복이 두세 번 든다).
///
/// 부르는 쪽이 시간 초과로 그만둬도 그 연결은 서버가 답할 때까지 남는다. 서버가 그
/// 일로 값을 매기는 요청(기록 질문)은 그만둘 때 끊는다(RecordAi._ask). 오래 열어 두는
/// 같이 하기 스트림은 저마다의 클라이언트를 열고 닫는다(partnerEvents).
final http.Client apiClient = newApiClient();

/// 서버로 가는 클라이언트를 만든다. 앱은 [apiClient] 하나를 쓴다.
http.Client newApiClient({
  String primary = const String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://gym.darak.studio',
  ),
  String backup = apiBackup,
  int? build,
  @visibleForTesting String Function() language = appLanguage,
  @visibleForTesting http.Client? inner,
}) {
  // 웹에는 dart:io 가 없다. 브라우저가 연결을 쥐고 있어 길을 고를 일도 없다.
  if (kIsWeb) {
    return _AppClient(inner ?? http.Client(), build ?? appBuild, language);
  }
  final base =
      inner ?? IOClient(HttpClient()..connectionTimeout = connectTimeout);
  return _AppClient(
    backup.isEmpty
        ? base
        : FailoverClient(
            base,
            primary: Uri.parse(primary),
            backup: Uri.parse(backup),
          ),
    build ?? appBuild,
    language,
  );
}

/// 모든 요청에 앱 판(`x-setpad-build`)과 앱의 언어(`accept-language`, [appLanguage])를
/// 싣고, 서버가 이 판을 더는 받지 않는다고 답하면(426) 알린다. 사고 난 판을 서버가 끊어
/// 낼 수 있는 자리다. 같이 하기 스트림도 이 클라이언트로 가므로 같은 머리말을 단다.
class _AppClient extends http.BaseClient {
  _AppClient(this._inner, this._build, this._language);
  final http.Client _inner;
  final int _build;
  final String Function() _language;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_build > 0) request.headers['x-setpad-build'] = '$_build';
    request.headers['accept-language'] = _language();
    final response = await _inner.send(request);
    if (response.statusCode == 426) updateRequired.value = true;
    return response;
  }

  @override
  void close() => _inner.close();
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

  /// 앱 전체가 같이 기억한다. 같이 하기 스트림은 저마다의 클라이언트를 쓴다.
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
    // 끊을 수 있는 요청은 사본도 같은 신호에 끊긴다.
    final abort = switch (request) {
      http.Abortable(:final abortTrigger) => abortTrigger,
      _ => null,
    };
    Object? failure;
    StackTrace? trace;
    for (final route in routes) {
      final url = _via(route, request.url);
      final copy =
          (abort == null
                ? http.Request(request.method, url)
                : http.AbortableRequest(
                    request.method,
                    url,
                    abortTrigger: abort,
                  ))
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
