import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_ai.dart';

/// 체육관과 주고받는 모양. 웹이 쓰는 모양과 앱의 칸이 어긋나면 조용히 빈
/// 운동이 되므로, 양방향 변환을 글자 단위로 못 박아 둔다.
void main() {
  test('트레이너가 적은 계획이 운동 칸이 된다', () {
    final blocks = plannedBlocks([
      {
        'name': '벤치프레스',
        'sets': [
          {'kg': 60, 'reps': 10},
          {'kg': 60, 'reps': 8},
        ],
      },
      {
        'name': '턱걸이',
        'sets': [
          {'reps': 10},
        ],
      },
    ]);
    expect(blocks.map((b) => b.name), ['벤치프레스', '턱걸이']);
    expect(blocks.first.sets.first.value, 60);
    expect(blocks.first.sets.first.reps, 10);
    // 계획은 아직 해낸 것이 아니다. 받자마자 완료로 뜨면 안 한 운동이 기록된다.
    expect(blocks.first.sets.every((s) => !s.done), isTrue);
    expect(blocks.last.sets.single.value, isNull, reason: '무게 없는 운동이 있다');
  });

  test('망가진 계획은 조용히 건너뛴다', () {
    // 서버가 무엇을 주든 앱이 터지면 안 된다.
    expect(plannedBlocks(null), isEmpty);
    expect(plannedBlocks('문자열'), isEmpty);
    expect(
      plannedBlocks([
        {'sets': []},
      ]),
      isEmpty,
      reason: '이름 없는 것은 운동이 아니다',
    );
  });

  test('앱의 기록이 웹이 읽는 모양으로 나간다', () {
    final items = loggedItems([
      ExerciseBlock('스쿼트', [
        LoggedSet(value: 100, reps: 5),
        LoggedSet(value: 100, reps: 3, done: false),
      ]),
    ]);
    expect(items.single['name'], '스쿼트');
    final sets = items.single['sets'] as List;
    expect(sets.first, {'kg': 100.0, 'reps': 5, 'done': true});
    expect((sets.last as Map)['done'], isFalse, reason: '취소한 세트는 안 한 것이다');
  });

  test('문장형 제목이어도 집계는 운동 이름으로 나간다', () {
    // "스쿼트 100kg 100개 채우기" 처럼 친 것은 제목으로 남지만, 트레이너가
    // 보는 것은 스쿼트여야 한다.
    final block = ExerciseBlock('스쿼트 100kg 100개 채우기', [
      LoggedSet(value: 100, reps: 10),
    ]);
    block.setup = const WorkoutSetup(name: '스쿼트', weight: 100);
    expect(loggedItems([block]).single['name'], '스쿼트');
  });

  test('로그인하지 않았으면 아무것도 묻지 않는다', () async {
    var calls = 0;
    final link = GymLink(
      endpoint: 'https://example.com',
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    expect(await link.gyms(), isEmpty);
    expect(await link.routines(), isEmpty);
    expect(calls, 0, reason: '토큰이 없으면 그물을 쓰지 않는다');
  });

  test('서버가 무너져도 기록하는 일은 그대로 된다', () async {
    final link = GymLink(
      endpoint: 'https://example.com',
      token: 'x',
      client: MockClient((_) async => http.Response('꺼짐', 500)),
    );
    expect(await link.gyms(), isEmpty);
    expect(
      await link.sendWorkout(
        gymId: 'g',
        localId: 'w1',
        startedAt: DateTime(2026),
        blocks: const [],
      ),
      isFalse,
    );
  });

  test('끝낸 운동을 올릴 때 기기 id 를 같이 보낸다', () async {
    Map<String, Object?>? sent;
    final link = GymLink(
      endpoint: 'https://example.com',
      token: 'x',
      client: MockClient((request) async {
        sent = jsonDecode(request.body) as Map<String, Object?>;
        return http.Response('{"id":"1"}', 200);
      }),
    );
    final ok = await link.sendWorkout(
      gymId: 'g1',
      localId: 'note-7',
      routineId: 'r1',
      startedAt: DateTime.utc(2026, 9, 14, 10),
      blocks: [
        ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
      ],
      note: '무릎 괜찮았음',
    );
    expect(ok, isTrue);
    // 같은 운동을 두 번 올려도 한 줄이 되게 하는 열쇠다.
    expect(sent!['localId'], 'note-7');
    expect(sent!['routineId'], 'r1');
    expect(sent!['note'], '무릎 괜찮았음');
  });
  _pending();
  _shared();
  _tags();
}

/// 헬스장은 신호가 나쁘다. 못 보낸 것은 다음에 다시 보낸다.
void _pending() {
  Note made(String id, {String? gymId, DateTime? sentAt, bool empty = false}) {
    final at = DateTime(2026, 9, id.length + 1);
    final note = Note(
      id: id,
      createdAt: at,
      updatedAt: at,
      gymId: gymId,
      blocks: empty
          ? []
          : [
              ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
            ],
    );
    note.sentAt = sentAt;
    return note;
  }

  test('보낼 것만 보내고, 보낸 것은 표시된다', () async {
    final sent = <String>[];
    final link = GymLink(
      endpoint: 'https://example.com',
      token: 'x',
      client: MockClient((request) async {
        sent.add(jsonDecode(request.body)['localId'] as String);
        return http.Response('{"id":"1"}', 200);
      }),
    );
    final notes = [
      made('a', gymId: 'g'),
      made('b'), // 체육관 것이 아니다 — 개인 운동은 안 나간다
      made('c', gymId: 'g', sentAt: DateTime(2026)), // 이미 보냈다
      // 빈 것도 나간다 — 루틴 없이 그냥 온 날의 출석이 그렇게 생겼다.
      made('d', gymId: 'g', empty: true),
    ];
    var touched = 0;
    await sendPending(link, notes, onSent: () => touched++);
    expect(sent, ['a', 'd']);
    expect(notes.first.sentAt, isNotNull);
    expect(touched, 1);
  });

  test('한 번 막히면 멈춘다 — 다음에 다시 보낸다', () async {
    var calls = 0;
    final link = GymLink(
      endpoint: 'https://example.com',
      token: 'x',
      client: MockClient((_) async {
        calls++;
        return http.Response('꺼짐', 500);
      }),
    );
    final notes = [made('a', gymId: 'g'), made('b', gymId: 'g')];
    var touched = 0;
    await sendPending(link, notes, onSent: () => touched++);
    expect(calls, 1, reason: '하나가 막히면 나머지도 막힌다');
    expect(notes.every((n) => n.sentAt == null), isTrue);
    expect(touched, 0, reason: '보낸 것이 없으면 저장할 것도 없다');
  });
}

/// 같이 쓰기와 예약. 서버와 주고받는 모양만 못 박는다.
void _shared() {
  GymLink linkThat(Future<http.Response> Function(http.Request r) reply) =>
      GymLink(
        endpoint: 'https://example.com',
        token: 'x',
        client: MockClient(reply),
      );

  test('코드를 띄우고, 받은 코드로 짝이 된다', () async {
    final sent = <Map<String, Object?>>[];
    final link = linkThat((request) async {
      sent.add(jsonDecode(request.body) as Map<String, Object?>);
      return http.Response(
        jsonEncode(
          sent.length == 1
              ? {'code': 'AB23CD'}
              : {'workoutId': 'host-1', 'partner': '민수'},
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    expect(await link.invite('mine-1'), 'AB23CD');
    final joined = await link.join('AB23CD', myWorkoutId: 'mine-1');
    expect(joined?.workoutId, 'host-1');
    expect(joined?.partner, '민수');
    // 내 운동도 같이 보내야 서로의 짝이 된다 — 봐주기는 한쪽만 하는 일이 아니다.
    expect(sent.last['workoutId'], 'mine-1');
    expect(sent.last['code'], 'AB23CD');
  });

  test('틀린 코드는 짝이 되지 않는다', () async {
    final link = linkThat((_) async => http.Response('{}', 404));
    expect(await link.join('XXXXXX'), isNull);
  });

  test('짝이 적은 것을 읽고, 내가 적은 것을 올린다', () async {
    Map<String, Object?>? put;
    final link = linkThat((request) async {
      if (request.method == 'PUT') {
        put = jsonDecode(request.body) as Map<String, Object?>;
        return http.Response('{"ok":true}', 200);
      }
      return http.Response(
        jsonEncode({
          'result': [
            {
              'name': '스쿼트',
              'sets': [
                {'kg': 100, 'reps': 5},
              ],
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final blocks = await link.readShared('w1');
    expect(blocks?.single.name, '스쿼트');
    expect(blocks?.single.sets.single.value, 100);

    expect(
      await link.writeShared('w1', [
        ExerciseBlock('벤치프레스', [LoggedSet(value: 60, reps: 10)]),
      ]),
      isTrue,
    );
    expect((put!['result'] as List).single['name'], '벤치프레스');
  });

  test('예약과 빈 자리를 읽는다', () async {
    final link = linkThat(
      (_) async => http.Response(
        jsonEncode({
          'bookings': [
            {
              'id': 'b1',
              'gym': '다락짐',
              'trainer': '이코치',
              'starts_at': '2026-09-16T01:00:00.000Z',
              'status': 'pending',
            },
          ],
          'slots': ['2026-09-16T02:00:00.000Z'],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    final found = await link.bookings(day: DateTime(2026, 9, 16));
    expect(found.bookings.single.trainer, '이코치');
    // 신청과 확정은 회원이 오늘 나갈지를 가른다. 확정으로 보이면 안 된다.
    expect(found.bookings.single.status, 'pending');
    // 서버는 UTC 로 주고 화면은 여기 시각으로 보여야 한다.
    expect(found.bookings.single.startsAt.isUtc, isFalse);
    expect(found.slots.single.isUtc, isFalse);
  });

  test('그 사이 남이 가져갔으면 잡히지 않는다', () async {
    final link = linkThat(
      (_) async => http.Response('{"error":"slotTaken"}', 409),
    );
    expect(await link.book(DateTime(2026, 9, 16, 10)), isFalse);
  });

  test('어느 체육관인지 서버에 말한다', () async {
    // 두 곳에 다니면 서버가 추측하지 않고 거절한다.
    late Uri asked;
    Map<String, Object?>? posted;
    final link = linkThat((request) async {
      asked = request.url;
      if (request.method == 'POST') {
        posted = jsonDecode(request.body) as Map<String, Object?>;
        return http.Response('{"id":"b9","status":"pending"}', 200);
      }
      return http.Response('{"bookings":[],"slots":[]}', 200);
    });
    await link.bookings(day: DateTime(2026, 9, 16), gymId: 'g1');
    expect(asked.queryParameters['gymId'], 'g1');
    expect(asked.queryParameters['day'], '2026-09-16');
    expect(await link.book(DateTime.utc(2026, 9, 16, 1), gymId: 'g1'), isTrue);
    expect(posted!['gymId'], 'g1');
  });

  test('스티커에 댄 것이 곧 등록 신청이다', () async {
    for (final (answer, expected) in [
      ('{"state":"requested"}', JoinState.requested),
      ('{"state":"waiting"}', JoinState.waiting),
      ('{"state":"member"}', JoinState.member),
      ('{"error":"noGym"}', JoinState.failed),
    ]) {
      final link = linkThat(
        (_) async => http.Response(answer, answer.contains('error') ? 404 : 200),
      );
      expect(await link.requestJoin('g1'), expected);
    }
    // 로그인하지 않았으면 신청할 사람이 없다.
    const anonymous = GymLink(endpoint: 'https://example.com');
    expect(await anonymous.requestJoin('g1'), JoinState.failed);
  });
}

/// 스티커가 가리키는 주소.
void _tags() {
  test('태그 주소에서 체육관을 꺼낸다', () {
    expect(gymFromTag(Uri.parse('https://example.com/c/abc-123')), 'abc-123');
    // 뒤에 뭐가 더 붙어도 체육관은 같다.
    expect(gymFromTag(Uri.parse('https://example.com/c/abc/classes')), 'abc');
  });

  test('체육관 주소가 아니면 아무것도 열지 않는다', () {
    for (final raw in [
      'https://example.com/',
      'https://example.com/c',
      'https://example.com/c/',
      'https://example.com/gym/abc',
      'https://example.com/setpad',
    ]) {
      expect(gymFromTag(Uri.parse(raw)), isNull, reason: raw);
    }
  });
}
