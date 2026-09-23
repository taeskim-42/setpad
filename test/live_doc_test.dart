import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/live_doc.dart';

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
}
