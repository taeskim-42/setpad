import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/workout_timing.dart';

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

  test('CRM cumulative targets are plans, not completed sets', () {
    final block = plannedBlocks([
      {
        'name': '타바타 총 200회 채우기 20/10 8라운드',
        'sets': [],
        'setup': {
          'name': '타바타',
          'weight': null,
          'unit': 'kg',
          'totalReps': 200,
          'repsPerSet': null,
          'totalSets': null,
          'repsOnly': true,
        },
      },
    ]).single;
    expect(block.setup?.totalReps, 200);
    expect(block.completedReps, 0);
    expect(block.sets, isEmpty);
    expect(block.name, contains('20/10 8라운드'));
  });

  test('웹이 이름에 적어 보내는 타이머를 앱이 그대로 읽는다', () {
    // 서버 planName 이 만드는 문구 그대로. `timing` 필드는 앱이 읽지 않고, 이름이 계약이다.
    final tabata = TimingSpec.parse('타바타 총 200회 채우기 20/10 8라운드')!;
    expect(
      (tabata.tabata, tabata.work, tabata.rest, tabata.rounds, tabata.bpm),
      (true, 20, 10, 8, null),
    );
    final full = TimingSpec.parse('버피 타바타 총 200회 채우기 30/15 10라운드 90bpm')!;
    expect(
      (full.tabata, full.work, full.rest, full.rounds, full.bpm),
      (true, 30, 15, 10, 90),
    );
    final beat = TimingSpec.parse('푸시업 총 100회 채우기 120bpm')!;
    expect((beat.tabata, beat.bpm), (false, 120));
    expect(TimingSpec.parse('벤치프레스'), isNull);
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

  test('서버 한도를 넘는 기록은 한도 안으로 맞춰서 보낸다', () {
    final items = loggedItems([
      ExerciseBlock('레그프레스', [
        LoggedSet(value: 1100000, reps: 20000),
        LoggedSet(value: -5, reps: -1),
        for (var i = 0; i < 120; i++) LoggedSet(value: 10, reps: 1),
      ]),
      ExerciseBlock('  ', [LoggedSet(value: 1, reps: 1)]),
      ExerciseBlock('가' * 300, []),
      for (var i = 0; i < 120; i++) ExerciseBlock('운동$i', []),
    ]);
    expect(items, hasLength(100), reason: '이름 빈 것은 빠지고 100개에서 멈춘다');
    final sets = items.first['sets'] as List;
    expect(sets, hasLength(100));
    expect(sets[0], {'kg': 9999, 'reps': 10000, 'done': true});
    expect(sets[1], {'kg': 0, 'reps': 0, 'done': true});
    expect((items[1]['name'] as String).length, 200);
  });

  test('시작 시각은 오프셋을 붙여 보낸다', () async {
    Map<String, Object?>? sent;
    final link = GymLink(
      endpoint: 'https://example.com',
      token: 'x',
      client: MockClient((request) async {
        sent = jsonDecode(request.body) as Map<String, Object?>;
        return http.Response('{"id":"1"}', 200);
      }),
    );
    await link.sendWorkout(
      gymId: 'g1',
      localId: 'n',
      startedAt: DateTime(2026, 10, 11, 10),
      blocks: const [],
    );
    expect(
      sent!['startedAt'],
      matches(RegExp(r'Z$')),
      reason: '오프셋 없으면 서버가 한국 시각으로 읽는다',
    );
    expect(
      DateTime.parse(sent!['startedAt'] as String),
      DateTime(2026, 10, 11, 10).toUtc(),
    );
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

  test('스티커를 댄 체육관의 루틴만 묻는다 — 서버 목록은 체육관을 합쳐 자른다', () async {
    final asked = <Uri>[];
    final link = GymLink(
      endpoint: 'https://example.com',
      token: 'x',
      client: MockClient((request) async {
        asked.add(request.url);
        return http.Response('{"routines":[]}', 200);
      }),
    );
    expect(await link.routines(gymId: 'g1'), isEmpty);
    expect(await link.routines(), isEmpty);
    expect(asked.first.queryParameters, {'gymId': 'g1'});
    expect(asked.last.hasQuery, isFalse, reason: '목록 화면은 전부 받는다');
  });

  test('서버가 무너져도 기록하는 일은 그대로 된다', () async {
    final link = GymLink(
      endpoint: 'https://example.com',
      token: 'x',
      client: MockClient((_) async => http.Response('꺼짐', 500)),
    );
    // 못 물어본 것은 '다니는 곳 없음' 이 아니다.
    expect(await link.gyms(), isNull);
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
  _meals();
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
      made('c', gymId: 'g', sentAt: DateTime(2027)), // 이미 보냈고 그 뒤로 안 고쳤다
      // 빈 것도 나간다 — 루틴 없이 그냥 온 날의 출석이 그렇게 생겼다.
      made('d', gymId: 'g', empty: true),
    ];
    var touched = 0;
    await sendPending(link, notes, onSent: () => touched++);
    expect(sent, ['a', 'd']);
    expect(notes.first.sentAt, isNotNull);
    expect(touched, 1);
  });

  test('보낸 뒤에 고친 기록은 다시 간다 — 루틴을 열어만 본 것은 안 간다', () async {
    final sent = <String>[];
    final link = GymLink(
      endpoint: 'https://example.com',
      token: 'x',
      client: MockClient((request) async {
        sent.add(jsonDecode(request.body)['localId'] as String);
        return http.Response('{"id":"1"}', 200);
      }),
    );
    // 잠금 해제 때 반만 올라갔다가(sentAt) 나머지 세트를 적었다(updatedAt 이 뒤).
    final edited = made('a', gymId: 'g', sentAt: DateTime(2026, 9, 2, 10))
      ..updatedAt = DateTime(2026, 9, 2, 11);
    // 받은 루틴을 눌러 봤을 뿐 아무것도 안 고쳤다.
    final looked = made('b', gymId: 'g')..routineId = 'r';
    // 루틴을 받아서 세트를 적었다.
    final did = made('c', gymId: 'g')
      ..routineId = 'r'
      ..updatedAt = DateTime(2026, 9, 4, 12);
    await sendPending(link, [edited, looked, did], onSent: () {});
    expect(sent, ['a', 'c']);
    expect(edited.sentAt!.isAfter(edited.updatedAt), isTrue);
    expect(looked.sentAt, isNull);
  });

  test('A 가 못 보낸 기록은 B 로 로그인해 있는 동안 안 가고, A 가 돌아오면 간다', () async {
    final sent = <(String, String)>[];
    GymLink signedIn(String user) => GymLink(
      endpoint: 'https://example.com',
      token: user,
      userId: user,
      client: MockClient((request) async {
        sent.add((user, jsonDecode(request.body)['localId'] as String));
        return http.Response('{"id":"1"}', 200);
      }),
    );
    final mine = made('a', gymId: 'g')..owner = 'A';
    // 표시가 생기기 전의 기록은 예전처럼 지금 계정이 보내고, 그 계정의 것이 된다.
    final legacy = made('bb', gymId: 'g');
    await sendPending(signedIn('B'), [mine, legacy], onSent: () {});
    expect(sent, [('B', 'bb')]);
    expect(mine.sentAt, isNull);
    expect(legacy.owner, 'B');

    await sendPending(signedIn('A'), [mine, legacy], onSent: () {});
    expect(sent.last, ('A', 'a'));
    expect(sent, hasLength(2));
    expect(mine.sentAt, isNotNull);
  });

  test('스티커로 연 루틴은 열어만 봐도 방문으로 가고, 적으면 같은 줄에 루틴이 붙는다', () async {
    final sent = <Map<String, Object?>>[];
    final link = GymLink(
      endpoint: 'https://example.com',
      token: 'x',
      client: MockClient((request) async {
        sent.add((jsonDecode(request.body) as Map).cast<String, Object?>());
        return http.Response('{"id":"1"}', 200);
      }),
    );
    final tagged = made('t', gymId: 'g')
      ..routineId = 'r'
      ..checkedIn = true;
    await sendPending(link, [tagged], onSent: () {});
    expect(sent.single['localId'], 't');
    expect(sent.single['routineId'], isNull, reason: '루틴을 붙이면 서버가 완료로 닫는다');
    expect(sent.single['result'], isEmpty);

    // 세트를 적었다 — 같은 줄에 루틴과 세트가 붙는다.
    tagged.updatedAt = DateTime.now().add(const Duration(minutes: 1));
    await sendPending(link, [tagged], onSent: () {});
    expect(sent.last['localId'], 't');
    expect(sent.last['routineId'], 'r');
    expect(sent.last['result'], isNotEmpty);
  });

  test('lb 는 kg 로 바꿔 보내고, 시간·거리는 무게 칸을 비운다', () {
    final items = loggedItems([
      ExerciseBlock('벤치프레스', [LoggedSet(value: 135, unit: 'lb', reps: 5)]),
      ExerciseBlock('플랭크', [LoggedSet(value: 60, unit: 's')]),
    ]);
    final bench = (items[0]['sets'] as List).first as Map;
    final plank = (items[1]['sets'] as List).first as Map;
    expect(bench['kg'], 61.23);
    expect(bench.containsKey('value'), isFalse, reason: '무게는 kg 칸 하나다');
    expect(plank.containsKey('kg'), isFalse);
  });

  test('시간·거리 세트는 초·미터로, 세트 메모는 운동 메모로 간다 — 트레이너에게 빈 세트로 보이지 않게', () {
    final items = loggedItems([
      ExerciseBlock('러닝', [
        LoggedSet(value: 5.2, unit: 'km'),
        LoggedSet(value: 3, unit: 'mi', notes: ['오르막']),
      ]),
      ExerciseBlock('플랭크', [
        LoggedSet(value: 1.5, unit: 'min', notes: [' 허리 조심 ', '']),
        LoggedSet(value: 45, unit: 's', notes: ['마지막은 무릎 대고', '숨참']),
        LoggedSet(value: 2, unit: 'h'),
        LoggedSet(value: 9e9, unit: 's'),
      ]),
      ExerciseBlock('스쿼트', [LoggedSet(value: 100, reps: 5)]),
    ]);
    List<Map> sets(int i) => (items[i]['sets'] as List).cast<Map>();
    expect(sets(0)[0], {'value': 5200.0, 'unit': 'm', 'done': true});
    expect(sets(0)[1]['value'], 4828.03);
    expect(items[0]['note'], '2세트: 오르막');
    expect([for (final s in sets(1)) s['value']], [90.0, 45.0, 7200.0, 1e6]);
    expect(sets(1).every((s) => s['unit'] == 's'), isTrue);
    expect(items[1]['note'], '1세트: 허리 조심\n2세트: 마지막은 무릎 대고 · 숨참');
    expect(sets(2).single.containsKey('value'), isFalse);
    expect(items[2].containsKey('note'), isFalse, reason: '메모가 없으면 칸도 없다');

    // 서버는 운동 메모를 500자에서 자른다. 앱도 그 안으로 보낸다.
    final long = loggedItems([
      ExerciseBlock('데드리프트', [
        for (var i = 0; i < 10; i++) LoggedSet(value: 100, notes: ['가' * 80]),
      ]),
    ]);
    expect((long.single['note'] as String).length, 500);
  });

  test('서버가 거절한 기록 하나가 뒤의 기록을 막지 않는다', () async {
    final sent = <String>[];
    final link = GymLink(
      endpoint: 'https://example.com',
      token: 'x',
      client: MockClient((request) async {
        final id = jsonDecode(request.body)['localId'] as String;
        sent.add(id);
        // 'a' 는 서버가 받지 않는 기록이다(예: 남의 루틴). 'b' 는 멀쩡하다.
        return id == 'a'
            ? http.Response('{"error":"notYourRoutine"}', 403)
            : http.Response('{"id":"1"}', 200);
      }),
    );
    final notes = [made('a', gymId: 'g'), made('b', gymId: 'g')];
    var touched = 0;
    await sendPending(link, notes, onSent: () => touched++);
    expect(sent, ['a', 'b'], reason: '거절은 건너뛰고 계속 간다');
    expect(notes.first.sentAt, isNull, reason: '거절된 기록은 보낸 것으로 꾸미지 않는다');
    expect(notes.last.sentAt, isNotNull);
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

  test('지운 기록의 끼니·운동 줄을 서버에서 지운다 — 운동 길을 모르는 서버가 끼니 지우기를 막지 않는다', () async {
    final calls = <String>[];
    var workouts = 405; // 아직 DELETE /api/workouts 가 없는 서버
    final link = GymLink(
      endpoint: 'https://example.com',
      token: 'x',
      userId: 'u1',
      client: MockClient((request) async {
        final url = request.url;
        calls.add(
          '${request.method} ${url.path}${url.hasQuery ? '?${url.query}' : ''}',
        );
        if (url.path == '/api/workouts') return http.Response('', workouts);
        return http.Response('{"ok":true}', 200);
      }),
    );
    final queue = <ServerDelete>[
      (kind: 'workout', id: 'n1', owner: 'u1'),
      (kind: 'meal', id: 'm1', owner: 'u1'),
      (kind: 'session', id: 'S9', owner: null),
      (kind: 'meal', id: 'm2', owner: 'someone-else'),
    ];
    var saved = 0;
    await sendDeletes(link, queue, onSent: () => saved++);
    expect(calls, [
      'DELETE /api/meals/m1',
      'POST /api/partner-sessions/S9/end',
      'DELETE /api/workouts?clientId=n1',
    ]);
    expect(queue, [
      (kind: 'workout', id: 'n1', owner: 'u1'),
      (kind: 'meal', id: 'm2', owner: 'someone-else'),
    ], reason: '옛 서버면 운동 줄은 기다리고, 남의 것은 그 사람의 로그인을 기다린다');
    expect(saved, 1);

    workouts = 404; // 서버에 없는 줄은 지운 것과 같다
    calls.clear();
    await sendDeletes(link, queue, onSent: () => saved++);
    expect(calls, ['DELETE /api/workouts?clientId=n1']);
    expect(queue, [(kind: 'meal', id: 'm2', owner: 'someone-else')]);
    expect(saved, 2);
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

  // 같이 하기는 test/partner_test.dart 로 옮겼다. 예전 테스트는 서버가 한 번도
  // 돌려준 적 없는 응답을 흉내 내고 있었다(기기 id 를 서버 운동 id 자리에 보냈다).

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

  test('못 잡거나 못 취소하면 서버가 적은 까닭을 그대로 준다 — 못 닿았으면 빈 말', () async {
    var status = 409;
    var body = jsonEncode({
      'error': 'noPass',
      'message': 'PT 이용권의 상태·기간·잔여 횟수를 확인해 주세요.',
    });
    final link = linkThat(
      (_) async => http.Response.bytes(utf8.encode(body), status),
    );
    expect(
      await link.book(DateTime(2026, 9, 16, 10)),
      'PT 이용권의 상태·기간·잔여 횟수를 확인해 주세요.',
    );
    body = jsonEncode({
      'error': 'tooLate',
      'message': '시작 시각이 지난 예약입니다. 트레이너에게 확인해 주세요.',
    });
    expect(await link.cancelBooking('b1'), '시작 시각이 지난 예약입니다. 트레이너에게 확인해 주세요.');
    // 까닭 없는 실패(서버가 넘어졌다)와 못 닿은 것은 빈 말이다.
    status = 500;
    body = '<html>';
    expect(await link.book(DateTime(2026, 9, 16, 10)), '');
    expect(await link.cancelBooking('b1'), '');
    final offline = linkThat((_) async => throw http.ClientException('off'));
    expect(await offline.book(DateTime(2026, 9, 16, 10)), '');
    expect(await offline.cancelBooking('b1'), '');
    // 잡았고 지웠다.
    status = 200;
    body = '{"id":"b9","status":"pending"}';
    expect(await link.book(DateTime(2026, 9, 16, 10)), isNull);
    expect(await link.cancelBooking('b9'), isNull);
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
    expect(await link.book(DateTime.utc(2026, 9, 16, 1), gymId: 'g1'), isNull);
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
        (_) async =>
            http.Response(answer, answer.contains('error') ? 404 : 200),
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
    expect(gymFromTag(Uri.parse('https://example.com/c/abc-123/')), 'abc-123');
    expect(gymFromTag(Uri.parse('https://example.com/c/abc?src=nfc')), 'abc');
    // 웹 화면의 "앱에서 열기"가 부르는 모양. 여기서는 'c' 가 host 다.
    expect(gymFromTag(Uri.parse('setpad://c/abc-123')), 'abc-123');
    expect(gymFromTag(Uri.parse('setpad://c/')), isNull);
  });

  test('그 아래 웹 화면 링크는 스티커가 아니다 — 출석도 가입 신청도 하지 않는다', () {
    for (final raw in [
      'https://example.com/c/abc/classes',
      'https://example.com/c/abc/bookings',
      'https://example.com/c/abc/meals',
      'setpad://c/abc/classes',
    ]) {
      expect(gymFromTag(Uri.parse(raw)), isNull, reason: raw);
    }
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

/// 식단 사진 → 어림 칼로리. 사진은 base64 로 한 번 가고 서버에 남지 않는다.
void _meals() {
  test('식단 사진을 보내면 어림 칼로리와 음식 이름이 온다', () async {
    Map<String, Object?>? sent;
    var path = '';
    final ai = RecordAi(
      deviceId: 'device-0123456789abcdef',
      client: MockClient((request) async {
        if (request.url.path == '/api/device') {
          return http.Response('{"token":"t"}', 200);
        }
        path = request.url.path;
        sent = jsonDecode(request.body) as Map<String, Object?>;
        return http.Response(
          '{"kcal":650,"items":["kimchi stew","rice"],"saved":true}',
          200,
        );
      }),
    );
    final estimate = await ai.estimateMeal(
      Uint8List.fromList([1, 2, 3]),
      mime: 'image/jpeg',
      locale: 'ko-KR',
      gymId: 'gym-1',
      kind: 'lunch',
    );
    expect(path, '/api/meals/estimate');
    expect(sent!['image'], base64Encode([1, 2, 3]));
    expect(sent!['mime'], 'image/jpeg');
    expect(sent!['gymId'], 'gym-1');
    expect(estimate.kcal, 650);
    expect(estimate.items, ['kimchi stew', 'rice']);
    expect(estimate.saved, isTrue);
  });

  test('영양성분표는 1회분 열량을 읽고 회분을 곱한다', () async {
    final ai = RecordAi(
      deviceId: 'device-0123456789abcdef',
      client: MockClient((request) async {
        if (request.url.path == '/api/device') {
          return http.Response('{"token":"t"}', 200);
        }
        return http.Response(
          jsonEncode({
            'kcal': 150,
            'items': ['choco pie'],
            'confidence': 'high',
            'label': {
              'perServingKcal': 150,
              'servingSize': '1 serving 35g',
              'servingsPerPackage': 12,
              'product': 'Choco Pie',
            },
          }),
          200,
        );
      }),
    );
    final estimate = await ai.estimateMeal(
      Uint8List.fromList([1]),
      mime: 'image/jpeg',
      locale: 'ko',
    );
    final label = estimate.label!;
    expect(label.perServingKcal, 150);
    expect(label.servingsPerPackage, 12);
    expect(label.kcalFor(0.5), 75);
    expect(label.kcalFor(1.5), 225);
    expect(label.kcalFor(12), 1800);
    expect(NutritionLabel.tryFromJson({'perServingKcal': -1}), isNull);
    expect(NutritionLabel.tryFromJson(null), isNull);
  });

  test('끼니는 기록과 함께 저장되고 되살아나며, 섭취 합계는 끼니가 있을 때만 있다', () {
    final at = DateTime(2026, 9, 20, 12);
    final note = Note(id: 'n', createdAt: at, updatedAt: at);
    expect(note.intake, isNull, reason: '안 적은 것과 0 은 다르다');
    note.meals.add(MealEntry(at: at, kcal: 650, items: ['김치찌개']));
    note.meals.add(MealEntry(at: at, kcal: 200));
    final back = Note.fromJson(
      jsonDecode(jsonEncode(note.toJson())) as Map<String, dynamic>,
    );
    expect(back.intake, 850);
    expect(back.meals.first.items, ['김치찌개']);
    expect(MealEntry.tryFromJson({'at': 'nope', 'kcal': 1}), isNull);
  });
}
