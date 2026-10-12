import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/purchases.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/sign_in.dart';

/// 로그인은 기기에 남아야 한다. 안 남으면 앱을 껐다 켤 때마다 로그아웃이고,
/// 스티커를 댈 때마다 로그인부터 하게 된다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  /// 키체인(테스트에서는 메모리). 켤 때마다 비어 있다.
  late Map<String, String> vault;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('setpad-session');
    FlutterSecureStorage.setMockInitialValues(vault = {});
    RecordAi.relaunch();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Account account(http.Client web) => Account(client: web, storageDir: dir);

  void keep(Map<String, Object?> session) =>
      vault['session'] = jsonEncode(session);
  Map<String, Object?>? kept() => vault['session'] == null
      ? null
      : jsonDecode(vault['session']!) as Map<String, Object?>;

  test('남겨 둔 로그인으로 다시 켠다', () async {
    keep({'token': 'saved', 'nickname': '김회원'});
    var asked = '';
    final a = account(
      MockClient((request) async {
        asked = request.headers['authorization'] ?? '';
        return http.Response(jsonEncode({'plan': null, 'selling': false}), 200);
      }),
    );
    await a.restoreSession();
    expect(a.signedIn, isTrue);
    expect(a.nickname, '김회원');
    expect(asked, 'Bearer saved', reason: '남겨 둔 토큰을 그대로 들고 간다');
  });

  test('옛 판의 session.json(평문)은 켤 때 한 번 키체인으로 옮기고 지운다', () async {
    final f = File('${dir.path}/session.json')
      ..writeAsStringSync(
        jsonEncode({'token': 'saved', 'nickname': '김회원', 'userId': 'u-1'}),
      );
    final a = account(
      MockClient((_) async => throw const SocketException('꺼짐')),
    );
    await a.restoreSession();
    expect(a.signedIn, isTrue);
    expect(a.link.userId, 'u-1');
    expect(kept(), {'token': 'saved', 'nickname': '김회원', 'userId': 'u-1'});
    expect(f.existsSync(), isFalse, reason: '평문 파일은 백업에 실린다');

    // 이미 키체인에 있으면 남은 파일은 지우기만 한다 — 키체인 것이 새 것이다.
    f.writeAsStringSync(jsonEncode({'token': 'older', 'nickname': '옛 이름'}));
    final b = account(
      MockClient((_) async => throw const SocketException('꺼짐')),
    );
    await b.restoreSession();
    expect(b.token, 'saved');
    expect(f.existsSync(), isFalse);
  });

  test('살아 있는 토큰을 보면 서버가 준 새 토큰으로 바꿔 둔다', () async {
    keep({'token': 'old', 'nickname': '김회원'});
    final a = account(
      MockClient((request) async {
        if (request.url.path.endsWith('/api/me')) {
          // http.Response(String) 은 charset 이 없으면 latin1 로 싸므로 본문에 한글을 넣지 않는다.
          return http.Response(
            jsonEncode({
              'user': {'nickname': 'kim'},
              'gyms': [],
              'token': 'fresh',
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'plan': null, 'selling': false}), 200);
      }),
    );
    await a.restoreSession();
    expect(a.token, 'fresh');
    expect(kept()!['token'], 'fresh', reason: '다음에 켤 때도 새 토큰이어야 한다');
  });

  test('누구로 로그인했는지 남겨 두고, 로그아웃하면 지운다', () async {
    // 밀린 기록을 그 주인의 토큰으로만 보내려면 지금 계정을 알아야 한다(Note.owner).
    keep({'token': 't', 'nickname': '김회원'});
    final a = account(
      MockClient((request) async {
        if (request.url.path.endsWith('/api/me')) {
          return http.Response(
            jsonEncode({
              'user': {'id': 'u-1', 'nickname': 'kim'},
              'token': 't',
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'plan': null, 'selling': false}), 200);
      }),
    );
    await a.restoreSession();
    expect(a.link.userId, 'u-1');
    expect(kept()!['userId'], 'u-1');
    await a.signOut();
    expect(a.link.userId, isNull);
    expect(kept(), isNull, reason: '남긴 것을 지우는 것까지가 로그아웃이다');
  });

  test('서버가 거절한 토큰은 지운다', () async {
    keep({'token': 'expired', 'nickname': '김회원'});
    final a = account(MockClient((_) async => http.Response('{}', 401)));
    await a.restoreSession();
    expect(a.signedIn, isFalse, reason: '죽은 토큰을 들고 있으면 회원이 아닌 사람처럼 보인다');
    expect(kept(), isNull);
  });

  test('어느 길에서든 401 이면 /api/me 로 한 번 확인한다 — 죽었으면 로그아웃, 아니면 그대로', () async {
    var me = 200, meCalls = 0;
    final a = account(
      MockClient((request) async {
        if (request.url.path.endsWith('/api/me')) {
          meCalls++;
          return http.Response(
            jsonEncode({
              'user': {'id': 'u-1', 'nickname': 'kim'},
              'token': 't',
            }),
            me,
          );
        }
        // 체육관·같이 하기·기록 올리기 — GymLink 의 모든 길.
        return http.Response('{"error":"signInRequired"}', 401);
      }),
    )..token = 't';
    a.gyms = [Gym(id: 'g1', name: 'BPM')];
    Future<void> settled() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    // 2초 폴링처럼 겹쳐 와도 묻는 것은 한 번이다.
    await Future.wait([a.refreshGyms(), a.link.gyms(), a.link.gyms()]);
    await settled();
    expect(meCalls, 1);
    expect(a.signedIn, isTrue, reason: '/api/me 가 받아 주면 로그인은 그대로다');
    expect(a.gyms, hasLength(1), reason: '거절된 순간 다니는 곳이 없는 사람이 되지 않는다');

    me = 401;
    await a.link.gyms();
    await settled();
    expect(meCalls, 2);
    expect(a.signedIn, isFalse, reason: '정말 죽은 토큰이면 로그아웃이다');
    expect(a.link.supported, isFalse, reason: '그 뒤로 그 길들은 더 묻지 않는다');
  });

  test('그물이 없을 뿐이면 로그인을 지키지 않고 버리지 않는다', () async {
    keep({'token': 'good', 'nickname': '김회원'});
    final a = account(
      MockClient((_) async => throw const SocketException('꺼짐')),
    );
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
            jsonEncode({'plan': null, 'selling': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
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
    keep({'token': 'good', 'nickname': '김회원'});
    // 옛 판의 파일이 남아 있어도 같이 지운다 — 남으면 다음에 켤 때 옮겨져 다시 로그인된다.
    final f = File('${dir.path}/session.json')
      ..writeAsStringSync(jsonEncode({'token': 'good', 'nickname': '김회원'}));
    var method = '';
    final a = account(
      MockClient((request) async {
        method = request.method;
        return http.Response('{"ok":true}', 200);
      }),
    )..token = 'good';
    expect(await a.deleteAccount(), isNull);
    expect(method, 'DELETE');
    expect(a.signedIn, isFalse);
    expect(kept(), isNull, reason: '서버에서 지웠는데 기기에 남으면 안 된다');
    expect(f.existsSync(), isFalse);
  });

  test('관장은 탈퇴가 막히고 이유가 그대로 온다', () async {
    final a = account(
      MockClient(
        (_) async => http.Response(
          jsonEncode({'error': 'blocked', 'message': '도장을 먼저 지워 주세요.'}),
          409,
          headers: {'content-type': 'application/json'},
        ),
      ),
    )..token = 'good';
    expect(await a.deleteAccount(), '도장을 먼저 지워 주세요.');
    expect(a.signedIn, isTrue, reason: '못 지웠으면 로그인은 그대로여야 한다');
  });

  test('애플 로그인은 폐기용 code 까지 서버에 넘긴다', () async {
    // 이게 안 가면 탈퇴할 때 애플에 알릴 방법이 없다.
    Map<String, Object?>? sent;
    final web = MockClient((request) async {
      sent = jsonDecode(request.body) as Map<String, Object?>;
      return http.Response(
        jsonEncode({
          'token': 't',
          'user': {'nickname': '김회원'},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    await exchange(
      (
        method: SignInMethod.apple,
        idToken: 'id',
        nickname: '김회원',
        code: 'auth-code',
        verifier: null,
      ),
      'https://example.com',
      client: web,
    );
    expect(sent!['code'], 'auth-code');
    expect(sent!['idToken'], 'id');
  });

  test('구글은 넘길 code 가 없어서 보내지 않는다', () async {
    Map<String, Object?>? sent;
    await exchange(
      (
        method: SignInMethod.google,
        idToken: 'id',
        nickname: null,
        code: null,
        verifier: null,
      ),
      'https://example.com',
      client: MockClient((request) async {
        sent = jsonDecode(request.body) as Map<String, Object?>;
        return http.Response(
          jsonEncode({
            'token': 't',
            'user': {'nickname': 'x'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    expect(sent!.containsKey('code'), isFalse);
  });

  test('서버가 로그인을 막으면 조용히 넘어가지 않는다', () async {
    // 조용히 실패하면 무엇이 잘못됐는지 알 길이 없다. 실제로 그래서 헤맸다.
    final a = Account(
      client: MockClient((_) async => http.Response('꺼짐', 500)),
      storageDir: dir,
      signInWith: (_) async => (
        method: SignInMethod.apple,
        idToken: 'id',
        nickname: '김회원',
        code: 'c',
        verifier: null,
      ),
    );
    expect(await a.signIn(), isFalse);
    expect(a.signInRefused, isTrue);
  });

  test('로그아웃하면 앞서 실패한 표시도 지운다', () async {
    final a = Account(
      client: MockClient((_) async => http.Response('꺼짐', 500)),
      storageDir: dir,
      signInWith: (_) async => (
        method: SignInMethod.kakao,
        idToken: 'h',
        nickname: null,
        code: null,
        verifier: 'v',
      ),
    );
    expect(await a.signIn(method: SignInMethod.kakao), isFalse);
    expect(a.signInRefused, isTrue);
    expect(a.lastSignIn, SignInMethod.kakao);
    await a.signOut();
    expect(a.signInRefused, isFalse);
    expect(a.lastSignIn, isNull);
  });

  test('사람이 창을 닫은 것은 실패로 치지 않는다', () async {
    final a = Account(
      client: MockClient((_) async => http.Response('{}', 200)),
      storageDir: dir,
      signInWith: (_) async => throw Exception('사용자가 닫음'),
    );
    expect(await a.signIn(), isFalse);
    expect(a.signInRefused, isFalse, reason: '스스로 그만둔 것에 경고를 띄우지 않는다');
  });

  test('스토어가 멈춰도 로그인이 살아나면 스티커는 기다리지 않는다', () async {
    // 스티커·링크는 토큰만 있으면 된다. start() 전체를 기다리면 스토어 조회가
    // 늘어지는 동안 스티커가 아무 말이 없다.
    keep({'token': 'saved', 'nickname': '김회원'});
    final a = Account(
      client: MockClient((_) async => http.Response('{}', 200)),
      storageDir: dir,
      purchases: _StuckPurchases(),
    );
    unawaited(a.start());
    await a.restored.timeout(const Duration(seconds: 5));
    expect(a.signedIn, isTrue);
  });

  test('웹 로그인이 실패로 돌아오면 조용히 넘어가지 않는다', () async {
    final a = Account(
      client: MockClient((_) async => http.Response('{}', 200)),
      storageDir: dir,
      signInWith: (_) async => throw const WebSignInFailed(),
    );
    expect(await a.signIn(method: SignInMethod.kakao), isFalse);
    expect(a.signInRefused, isTrue);
  });

  test('깨진 파일은 조용히 무시한다', () async {
    File('${dir.path}/session.json').writeAsStringSync('{망가짐');
    final a = account(MockClient((_) async => http.Response('{}', 200)));
    await a.restoreSession();
    expect(a.signedIn, isFalse);
    vault['session'] = '{망가짐';
    final b = account(MockClient((_) async => http.Response('{}', 200)));
    await b.restoreSession();
    expect(b.signedIn, isFalse);
  });

  test('모든 기기에서 로그아웃 — 서버가 다른 토큰을 끊고 준 새 토큰으로 이 폰은 이어 간다', () async {
    keep({'token': 'old', 'nickname': '김회원'});
    var status = 200;
    String? sentWith;
    final a = account(
      MockClient((request) async {
        if (request.url.path.endsWith('/api/me/sessions/revoke')) {
          sentWith = request.headers['authorization'];
          return http.Response(jsonEncode({'token': 'new'}), status);
        }
        return http.Response('{}', 200);
      }),
    );
    await a.restoreSession();
    expect(await a.signOutEverywhere(), isTrue);
    expect(sentWith, 'Bearer old');
    expect(a.token, 'new');
    expect(kept()!['token'], 'new', reason: '다음에 켤 때 끊긴 옛 토큰을 들고 가지 않는다');

    status = 500;
    expect(await a.signOutEverywhere(), isFalse, reason: '못 끊었으면 그렇다고 말한다');
    expect(a.token, 'new');
  });

  test('로그인 시트의 \'만 14세 이상입니다\' 를 서버에 함께 낸다 — 수단을 붙일 때는 내지 않는다', () async {
    final sent = <Map<String, Object?>>[];
    Account signingIn() => Account(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/api/auth/app')) {
          sent.add(jsonDecode(request.body) as Map<String, Object?>);
          return http.Response(
            jsonEncode({
              'token': 't',
              'user': {'nickname': 'kim'},
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      }),
      storageDir: dir,
      signInWith: (method) async => (
        method: method,
        idToken: 'id',
        nickname: null,
        code: null,
        verifier: null,
      ),
    );
    expect(
      await signingIn().signIn(method: SignInMethod.apple, ageConfirmed: true),
      isTrue,
    );
    expect(sent.last['ageConfirmed'], isTrue);
    await signingIn().signIn(method: SignInMethod.google);
    expect(sent.last.containsKey('ageConfirmed'), isFalse);
  });

  group('기기 토큰도 남긴다 — 켤 때마다 새로 받지 않는다(계약 C3)', () {
    const id = 'device-id-0123456789';
    String inDays(num days) => DateTime.now()
        .toUtc()
        .add(Duration(minutes: (days * 24 * 60).round()))
        .toIso8601String();
    RecordAi ai(http.Client web, {String deviceId = id}) => RecordAi(
      endpoint: 'https://example.com',
      deviceId: deviceId,
      client: web,
    );

    test('받은 토큰을 키체인에 두고, 다시 켜도 만료 하루 전까지는 그것을 쓴다', () async {
      var mints = 0;
      final expires = inDays(30);
      final web = MockClient((request) async {
        if (request.url.path == '/api/device') {
          mints++;
          return http.Response(
            jsonEncode({'token': 't$mints', 'expiresAt': expires}),
            200,
          );
        }
        return http.Response('{}', 200);
      });
      expect(await ai(web).bearer(), 't1');
      await pumpEventQueue();
      expect(jsonDecode(vault['deviceToken']!), {
        'token': 't1',
        'expiresAt': expires,
        'id': id,
      });
      RecordAi.relaunch();
      expect(await ai(web).bearer(), 't1');
      expect(mints, 1, reason: '켤 때마다 받으면 주소의 하루 발급 한도를 같이 태운다');

      // 앱을 지웠다 깔아 기기 id 가 바뀌었다 — 키체인에 남은 남의 id 것은 쓰지 않는다.
      RecordAi.relaunch();
      expect(await ai(web, deviceId: 'device-id-abcdefghijkl').bearer(), 't2');

      // 만료가 하루 안으로 다가왔다.
      vault['deviceToken'] = jsonEncode({
        'token': 'old',
        'expiresAt': inDays(0.5),
        'id': id,
      });
      RecordAi.relaunch();
      expect(await ai(web).bearer(), 't3');
    });

    test('서버가 기기 토큰을 거절하면(401) 남긴 것까지 버리고 새로 받는다', () async {
      vault['deviceToken'] = jsonEncode({
        'token': 'dead',
        'expiresAt': inDays(20),
        'id': id,
      });
      final asked = <String?>[];
      double? balance;
      final web = MockClient((request) async {
        if (request.url.path == '/api/device') {
          return http.Response(
            jsonEncode({'token': 'fresh', 'expiresAt': inDays(30)}),
            200,
          );
        }
        asked.add(request.headers['authorization']);
        return request.headers['authorization'] == 'Bearer dead'
            ? http.Response('{"error":"unauthorized"}', 401)
            : http.Response('{"balance":3}', 200);
      });
      await RecordAi(
        endpoint: 'https://example.com',
        deviceId: id,
        client: web,
        onPlates: (b, _) => balance = b,
      ).plates();
      await pumpEventQueue();
      expect(asked, ['Bearer dead', 'Bearer fresh']);
      expect(balance, 3);
      expect(jsonDecode(vault['deviceToken']!)['token'], 'fresh');
    });

    test('이 주소의 오늘 발급이 다 찼으면(429) 십 분은 다시 받지 않는다', () async {
      var mints = 0;
      final web = MockClient((_) async {
        mints++;
        return http.Response('{"error":"tooManyDevices"}', 429);
      });
      expect(await ai(web).bearer(), isNull);
      expect(await ai(web).bearer(), isNull);
      expect(mints, 1, reason: '두드릴수록 그 주소의 수만 는다');
    });

    test('만료를 알려 주지 않는 옛 서버의 토큰은 남기지 않고 이 실행 동안만 쓴다', () async {
      var mints = 0;
      final web = MockClient((_) async {
        mints++;
        return http.Response(jsonEncode({'token': 't$mints'}), 200);
      });
      expect(await ai(web).bearer(), 't1');
      expect(await ai(web).bearer(), 't1');
      await pumpEventQueue();
      expect(vault.containsKey('deviceToken'), isFalse);
      expect(mints, 1);
    });

    test('로그인·로그아웃 때 버리면 키체인의 것도 지운다', () async {
      vault['deviceToken'] = jsonEncode({
        'token': 'kept',
        'expiresAt': inDays(20),
        'id': id,
      });
      RecordAi.forget();
      await pumpEventQueue();
      expect(vault.containsKey('deviceToken'), isFalse);
    });
  });
}

/// 응답이 영영 안 오는 스토어.
class _StuckPurchases extends Purchases {
  @override
  Future<bool> start({bool apple = true}) => Completer<bool>().future;
}
