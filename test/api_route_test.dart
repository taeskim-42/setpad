// 서버로 가는 길이 하나 막혀도 이어 가는가 — 그리고 막힌 것이 아닐 때는 갈아타지 않는가.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/api_route.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/notes.dart';

final primary = Uri.parse('https://gym.darak.studio');
final backup = Uri.parse('https://relay.example.org');

void main() {
  setUp(FailoverClient.forget);

  test('기본 길에 연결이 안 되면 같은 요청을 예비 길로 한 번 보내고, 통한 길을 기억한다', () async {
    final seen = <http.Request>[];
    final client = FailoverClient(
      MockClient((request) async {
        seen.add(request);
        if (request.url.host == primary.host) {
          throw const SocketException('Connection timed out');
        }
        return http.Response('{"ok":true}', 200);
      }),
      primary: primary,
      backup: backup,
    );
    final response = await client.put(
      Uri.parse('https://gym.darak.studio/api/meals/m123?x=1'),
      headers: {
        'authorization': 'Bearer t',
        'content-type': 'application/json',
      },
      body: '{"kcal":375}',
    );
    expect(response.statusCode, 200);
    expect(seen.map((r) => r.url.host), [primary.host, backup.host]);
    final resent = seen.last;
    expect(
      resent.url.toString(),
      'https://relay.example.org/api/meals/m123?x=1',
    );
    expect(resent.method, 'PUT');
    expect(resent.headers['authorization'], 'Bearer t');
    expect(resent.body, '{"kcal":375}', reason: '같은 id, 같은 본문 — 서버가 한 줄로 합친다');

    // 다음 요청은 막힌 길을 또 두드리지 않는다.
    seen.clear();
    await client.get(Uri.parse('https://gym.darak.studio/api/me'));
    expect(seen.map((r) => r.url.host), [backup.host]);
  });

  test('서버가 답했으면 갈아타지 않는다 — 401·403·입력 오류·서버 오류는 길의 문제가 아니다', () async {
    for (final status in [401, 403, 400, 404, 409, 429, 500, 503]) {
      final hosts = <String>[];
      final client = FailoverClient(
        MockClient((request) async {
          hosts.add(request.url.host);
          return http.Response('{"error":"x"}', status);
        }),
        primary: primary,
        backup: backup,
      );
      final response = await client.get(Uri.parse('$primary/api/me'));
      expect(response.statusCode, status);
      expect(hosts, [primary.host], reason: '$status 는 예비 길로 다시 보내지 않는다');
    }
  });

  test('두 길이 다 막히면 한 번씩만 시도하고 그물 없음으로 끝난다 — 무한히 돌지 않는다', () async {
    var attempts = 0;
    final client = FailoverClient(
      MockClient((_) async {
        attempts++;
        throw const SocketException('Network is unreachable');
      }),
      primary: primary,
      backup: backup,
    );
    await expectLater(
      client.get(Uri.parse('$primary/api/me')),
      throwsA(isA<SocketException>()),
    );
    expect(attempts, 2);
  });

  test('길과 상관없는 오류와 남의 주소는 건드리지 않는다', () async {
    final hosts = <String>[];
    final client = FailoverClient(
      MockClient((request) async {
        hosts.add(request.url.host);
        if (request.url.host == primary.host) {
          throw const FormatException('bad');
        }
        return http.Response('ok', 200);
      }),
      primary: primary,
      backup: backup,
    );
    await expectLater(
      client.get(Uri.parse('$primary/api/me')),
      throwsFormatException,
    );
    await client.get(Uri.parse('https://apple.com/x'));
    expect(hosts, [primary.host, 'apple.com']);
  });

  test('서버가 저장한 직후 연결이 끊겨 예비 길로 다시 보내도 기록은 한 건이다', () async {
    // 두 길은 같은 서버·같은 DB 로 간다. 첫 길은 저장까지 하고 답을 못 돌려준다.
    final rows = <String, Map<String, Object?>>{};
    final client = FailoverClient(
      MockClient((request) async {
        final id = request.url.pathSegments.last;
        rows[id] = (jsonDecode(request.body) as Map).cast<String, Object?>();
        if (request.url.host == primary.host) {
          throw const SocketException('Connection reset by peer');
        }
        return http.Response('{"id":"row"}', 200);
      }),
      primary: primary,
      backup: backup,
    );
    final link = GymLink(endpoint: '$primary', token: 't', client: client);
    final note =
        Note(
            id: 'n1',
            createdAt: DateTime(2026, 9, 21),
            updatedAt: DateTime(2026, 9, 21),
            gymId: '11111111-2222-3333-4444-555555555555',
          )
          ..meals.add(
            MealEntry(at: DateTime(2026, 9, 21, 12), kcal: 450, text: '김밥'),
          );
    await syncMeals(link, [note], onSynced: () {});
    expect(rows, hasLength(1), reason: '끼니의 id 가 열쇠라 두 번 닿아도 한 줄이다');
    expect(note.meals.single.dirty, isFalse);
  });

  test('예비 주소가 없으면 길은 하나이고, 앱은 우리 도메인만 부른다', () {
    final client = newApiClient(backup: '');
    expect(client, isNot(isA<FailoverClient>()));
    client.close();
    expect(const String.fromEnvironment('API_BACKUP'), isEmpty);
  });
}
