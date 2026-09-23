import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/live_doc.dart';
import 'package:setpad/record_ai.dart';

LoggedSet set(String id, int reps) =>
    LoggedSet(id: id, value: 60, unit: 'kg', reps: reps);

void main() {
  test('차이는 id 로 말한다 — 더하기·고치기·지우기·순서가 서로 섞이지 않는다', () {
    final bench = ExerciseBlock('벤치', [set('a', 10)], null, 'B');
    final squat = ExerciseBlock('스쿼트', [set('s', 5)], null, 'S');
    final from = docOf([bench, squat]);
    // 벤치에 한 세트, 첫 세트 고침, 스쿼트를 앞으로, 새 운동, 그리고 이름 바꾸기.
    final to = docOf([
      ExerciseBlock('스쿼트', [set('s', 5)], null, 'S'),
      ExerciseBlock('벤치프레스', [set('a', 12), set('b', 8)], null, 'B'),
      ExerciseBlock('풀업', [], null, 'P'),
    ]);
    final ops = diffDoc(from, to).expand((b) => b).toList();
    expect(ops.map((o) => o['kind']), containsAll(['block', 'set', 'order']));
    expect(applyDoc(from, ops).map((b) => b['id']), ['S', 'B', 'P']);
    expect(diffDoc(applyDoc(from, ops), to), isEmpty, reason: '얹은 결과가 곧 목표다');
    // 같은 것을 두 번 얹어도 같다 — 끊겨서 다시 보내도 안전하다.
    expect(applyDoc(applyDoc(from, ops), ops), applyDoc(from, ops));
  });

  test('동시에 같은 운동에 넣은 세트는 둘 다 남고, 지워진 운동을 향한 세트는 사라진다', () {
    final base = docOf([
      ExerciseBlock('벤치', [set('a', 10)], null, 'B'),
    ]);
    final mine = diffDoc(
      base,
      docOf([
        ExerciseBlock('벤치', [set('a', 10), set('m', 9)], null, 'B'),
      ]),
    ).expand((b) => b).toList();
    final theirs = diffDoc(
      base,
      docOf([
        ExerciseBlock('벤치', [set('a', 10), set('t', 7)], null, 'B'),
      ]),
    ).expand((b) => b).toList();
    final merged = applyDoc(applyDoc(base, theirs), mine);
    expect(
      [for (final s in merged.single['sets'] as List) (s as Map)['id']],
      ['a', 't', 'm'],
    );
    final removed = applyDoc(base, [
      {'kind': 'removeBlock', 'block': 'B'},
    ]);
    expect(applyDoc(removed, mine), isEmpty);
  });

  test('서버 문서에서 남이 적은 세트는 이름을 달고, 내 세트는 내 것으로 온다', () {
    final doc = [
      {
        'id': 'B',
        'name': '벤치',
        'sets': [
          {
            'id': 'a',
            'value': 60,
            'unit': 'kg',
            'reps': 10,
            'notes': [],
            'done': true,
            'by': {'key': 'me', 'name': '미나'},
          },
          {
            'id': 'b',
            'value': 50,
            'unit': 'kg',
            'reps': 8,
            'notes': [],
            'done': true,
            'by': {'key': 'j', 'name': '준'},
          },
        ],
      },
    ];
    final sets = blocksOfDoc(doc, 'me').single.sets;
    expect(sets.map((s) => s.author), [null, '준']);
    expect(sets.map((s) => s.mine), [true, false], reason: '내 통계에는 내 세트만');
    expect(sets.map((s) => s.id), ['a', 'b']);
  });

  test('서버를 거쳐 60.0 이 60 이 되고 키 순서가 바뀌어도 차이가 없다 — 남의 수정을 옛 값으로 덮지 않는다', () {
    final local = docOf([
      ExerciseBlock(
        '벤치',
        [set('a', 10)],
        WorkoutSetup(name: '벤치', weight: 60, unit: 'kg', totalReps: 100),
        'B',
      ),
    ]);
    // 서버가 돌려준 모양: 정수, 키 순서 뒤바뀜, 작성자 붙음.
    final server = (jsonDecode(jsonEncode(local)) as List).cast<Json>();
    final b = server.single;
    b['setup'] = Map.fromEntries((b['setup'] as Map).entries.toList().reversed);
    for (final s in b['sets'] as List) {
      (s as Map)['value'] = (s['value'] as num).toInt();
      s['by'] = {'key': 'me', 'name': '미나'};
    }
    expect(diffDoc(server, local), isEmpty);
  });

  test('고치기가 늦게 닿아도 지워진 세트나 운동을 되살리지 않는다 — 새 것만 새 것이라고 말한다', () {
    final base = docOf([
      ExerciseBlock('벤치', [set('a', 10)], null, 'B'),
    ]);
    final ops = diffDoc(
      base,
      docOf([
        ExerciseBlock('벤치프레스', [set('a', 12), set('n', 5)], null, 'B'),
      ]),
    ).expand((b) => b).toList();
    final kinds = [for (final o in ops) (o['kind'], o['new'], o['at'])];
    expect(
      kinds,
      containsAll([
        ('set', null, null),
        ('set', true, null),
        ('block', null, null),
      ]),
    );
    // 그사이 누가 벤치를 통째로 지웠다가, 같은 id 로 빈 벤치를 새로 만들지는 않는다.
    final gone = applyDoc(base, [
      {'kind': 'removeSet', 'block': 'B', 'set': 'a'},
    ]);
    final after = applyDoc(gone, ops).single['sets'] as List;
    expect(
      [for (final s in after) (s as Map)['id']],
      ['n'],
      reason: 'a 는 되살아나지 않는다',
    );
    expect(applyDoc(const [], ops), isEmpty, reason: '이름 바꾸기가 운동을 만들지 않는다');
  });

  test('지난 세션에서 남이 적은 세트는 이름만 싣고 키는 싣지 않는다', () {
    final s = set('x', 5)..author = '준';
    final json = docOf([
      ExerciseBlock('벤치', [s], null, 'B'),
    ]);
    expect(((json.single['sets'] as List).single as Map)['by'], {'name': '준'});
  });

  test('문서가 와도 있던 운동은 같은 객체로 남는다 — 타이머·열린 자리가 붙잡고 있다', () {
    final c = RoutineEditorController();
    final bench = ExerciseBlock('벤치 120bpm', [set('a', 10)], null, 'B');
    c.restore([bench]);
    c.openBlock(0);
    final lost = c.replaceBlocks([
      ExerciseBlock(
        '벤치 120bpm',
        [set('a', 10), set('p', 8)..author = '준'],
        null,
        'B',
      ),
      ExerciseBlock('스쿼트', [], null, 'S'),
    ]);
    expect(lost, isNull);
    expect(identical(c.blocks.first, bench), isTrue);
    expect(bench.sets.map((s) => s.author), [null, '준']);
    expect(c.activeIndex, 0);
    // 내가 적던 운동이 사라지면 그것을 돌려준다.
    expect(c.replaceBlocks([ExerciseBlock('스쿼트', [], null, 'S')]), same(bench));
    expect(c.inBlock, isFalse);
  });

  test('처음 참여: 같은 운동이 문서에 있으면 문서가 이기고, 내게만 있는 세트·운동만 붙는다 (실제 모양으로)', () {
    // 서버에서 온 문서는 JSON 이라 List<dynamic>, 내 것은 docOf 라 타입이 붙은 목록이다.
    // 이 둘을 섞어 찾다가 타입 오류로 죽었다.
    final doc =
        (jsonDecode(
                  jsonEncode(
                    docOf([
                      ExerciseBlock('벤치', [set('a', 12)], null, 'B'),
                    ]),
                  ),
                )
                as List)
            .cast<Json>();
    final local = docOf([
      ExerciseBlock('벤치', [set('a', 10), set('mine', 5)], null, 'B'),
      ExerciseBlock('풀업', [set('p', 8)], null, 'P'),
    ]);
    final joined = joinDoc(doc, local);
    expect([for (final b in joined) b['id']], ['B', 'P']);
    final sets = joined.first['sets'] as List;
    expect(
      [for (final s in sets) ((s as Map)['id'], s['reps'])],
      [('a', 12), ('mine', 5)],
      reason: '문서의 12 가 내 낡은 10 을 이긴다',
    );
    final ops = diffDoc(doc, joined).expand((b) => b).toList();
    expect(
      ops.where((o) => o['kind'] == 'removeSet' || o['kind'] == 'removeBlock'),
      isEmpty,
    );
  });

  test('보내는 값은 서버가 받는 범위 안이다 — 하나 때문에 묶음이 통째로 거절되지 않는다', () {
    final s = LoggedSet(
      id: 'x',
      value: 1e9,
      reps: -3,
      notes: [for (var i = 0; i < 30; i++) 'n' * 600],
    );
    final json = (docOf([
      ExerciseBlock('a' * 300, [s], null, 'B'),
    ]).single);
    final sj = (json['sets'] as List).single as Map;
    expect([sj['value'], sj['reps']], [null, null]);
    expect((sj['notes'] as List).length, 20);
    expect(((sj['notes'] as List).first as String).length, 500);
    expect((json['name'] as String).length, 200);
    // 메모를 고치면 차이가 난다 — 보낸 문서가 편집기의 목록을 붙잡고 있지 않다.
    final t = LoggedSet(id: 't', value: 60, reps: 5);
    final shadow = docOf([
      ExerciseBlock('벤치', [t], null, 'B'),
    ]);
    t.notes.add('새 메모');
    expect(
      diffDoc(
        shadow,
        docOf([
          ExerciseBlock('벤치', [t], null, 'B'),
        ]),
      ),
      isNotEmpty,
    );
  });

  test('지난 세션에서 옮겨 온 내 세트는 내 폰에서 내 것으로 남는다', () {
    final mine = set('m', 5);
    final doc = [
      {
        'id': 'B',
        'name': '벤치',
        'sets': [
          {
            'id': 'm',
            'value': 60,
            'unit': 'kg',
            'reps': 5,
            'notes': [],
            'done': true,
            'by': {'key': '', 'name': '준'},
          },
          {
            'id': 'o',
            'value': 60,
            'unit': 'kg',
            'reps': 5,
            'notes': [],
            'done': true,
            'by': {'key': '', 'name': '미나'},
          },
        ],
      },
    ];
    final sets = blocksOfDoc(
      doc,
      'jun-key',
      local: [
        ExerciseBlock('벤치', [mine], null, 'B'),
      ],
    ).single.sets;
    expect(sets.map((s) => s.author), [null, '미나']);
  });
}
