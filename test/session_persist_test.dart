import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';

/// 로그인은 기기에 남아야 한다. 안 남으면 앱을 껐다 켤 때마다 로그아웃이고,
/// 스티커를 댈 때마다 로그인부터 하게 된다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('setpad-session'));
  tearDown(() => dir.deleteSync(recursive: true));

  Account account(http.Client web) => Account(client: web, storageDir: dir);

  test('남겨 둔 로그인으로 다시 켠다', () async {
    File('${dir.path}/session.json')
        .writeAsStringSync(jsonEncode({'token': 'saved', 'nickname': '김회원'}));
    var asked = '';
    final a = account(MockClient((request) async {
      asked = request.headers['authorization'] ?? '';
      return http.Response(jsonEncode({'plan': null, 'selling': false}), 200);
    }));
    await a.restoreSession();
    expect(a.signedIn, isTrue);
    expect(a.nickname, '김회원');
    expect(asked, 'Bearer saved', reason: '남겨 둔 토큰을 그대로 들고 간다');
  });

  test('서버가 거절한 토큰은 지운다', () async {
    final f = File('${dir.path}/session.json')
      ..writeAsStringSync(jsonEncode({'token': 'expired', 'nickname': '김회원'}));
    final a = account(MockClient((_) async => http.Response('{}', 401)));
    await a.restoreSession();
    expect(a.signedIn, isFalse, reason: '죽은 토큰을 들고 있으면 회원이 아닌 사람처럼 보인다');
    expect(f.existsSync(), isFalse);
  });

  test('그물이 없을 뿐이면 로그인을 지키지 않고 버리지 않는다', () async {
    File('${dir.path}/session.json')
        .writeAsStringSync(jsonEncode({'token': 'good', 'nickname': '김회원'}));
    final a = account(MockClient((_) async => throw const SocketException('꺼짐')));
    await a.restoreSession();
    expect(a.signedIn, isTrue, reason: '못 물어본 것과 거절당한 것은 다르다');
  });

  test('로그인 전에도 파는지 묻는다', () async {
    // 안 물으면 로그인 안 한 사람에게는 무료가 몇 번인지도 안 보인다.
    var asked = 0;
    String? sentAuth = 'x';
    final a = Account(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/api/purchase')) {
          asked++;
          sentAuth = request.headers['authorization'];
          return http.Response(
            jsonEncode({'plan': null, 'selling': true}), 200,
            headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200);
      }),
      storageDir: dir,
    );
    await a.refreshForTest();
    expect(asked, 1);
    expect(a.selling, isTrue);
    expect(sentAuth, isNull, reason: "붙일 토큰이 없으면 헤더도 없다");
  });

  test('탈퇴하면 기기에 남은 로그인도 사라진다', () async {
    final f = File('${dir.path}/session.json')
      ..writeAsStringSync(jsonEncode({'token': 'good', 'nickname': '김회원'}));
    var method = '';
    final a = account(MockClient((request) async {
      method = request.method;
      return http.Response('{"ok":true}', 200);
    }))..token = 'good';
    expect(await a.deleteAccount(), isNull);
    expect(method, 'DELETE');
    expect(a.signedIn, isFalse);
    expect(f.existsSync(), isFalse, reason: '서버에서 지웠는데 기기에 남으면 안 된다');
  });

  test('관장은 탈퇴가 막히고 이유가 그대로 온다', () async {
    final a = account(MockClient((_) async => http.Response(
        jsonEncode({'error': 'blocked', 'message': '도장을 먼저 지워 주세요.'}), 409,
        headers: {'content-type': 'application/json'})))
      ..token = 'good';
    expect(await a.deleteAccount(), '도장을 먼저 지워 주세요.');
    expect(a.signedIn, isTrue, reason: '못 지웠으면 로그인은 그대로여야 한다');
  });

  test('깨진 파일은 조용히 무시한다', () async {
    File('${dir.path}/session.json').writeAsStringSync('{망가짐');
    final a = account(MockClient((_) async => http.Response('{}', 200)));
    await a.restoreSession();
    expect(a.signedIn, isFalse);
  });
}
