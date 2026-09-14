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
      made('d', gymId: 'g', empty: true), // 빈 기록은 보낼 것이 없다
    ];
    var touched = 0;
    await sendPending(link, notes, onSent: () => touched++);
    expect(sent, ['a']);
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
