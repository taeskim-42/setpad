import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/milestones.dart';
import 'package:setpad/notes.dart';

Note day(String id, int d, List<ExerciseBlock> blocks) => Note(
  id: id,
  createdAt: DateTime(2026, 9, d),
  updatedAt: DateTime(2026, 9, d),
  blocks: blocks,
);

void main() {
  test('그때까지의 최고 무게를 넘긴 세트만 — 처음 한 운동, 같은 무게, 안 한 세트는 아니다', () {
    final a = day('a', 1, [
      ExerciseBlock('스쿼트', [LoggedSet(value: 100, reps: 5)], null, 's1'),
    ]);
    final b = day('b', 2, [
      ExerciseBlock(
        '스쿼트',
        [
          LoggedSet(value: 100, reps: 5),
          LoggedSet(value: 105, reps: 3),
          LoggedSet(value: 105, reps: 3),
          LoggedSet(value: 110, reps: 1, done: false),
        ],
        null,
        's2',
      ),
    ]);
    final c = day('c', 3, [
      ExerciseBlock(
        '스쿼트',
        [LoggedSet(value: 240, unit: 'lb', reps: 1)],
        null,
        's3',
      ),
    ]);
    final r = weightRecords([c, b, a]);
    expect(r['a'], isNull, reason: '처음 한 운동');
    expect(r['b'], {
      's2': {1},
    }, reason: '105 첫 세트만, 안 한 110 은 아니다');
    expect(r['c'], {
      's3': {0},
    }, reason: '240lb ≈ 108.9kg 는 105 를 넘는다');
  });

  test('무게를 올려 가는 세트는 맨 윗 세트 하나만 ★ — 몸풀기 세트마다 붙지 않는다', () {
    final before = day('p0', 1, [
      ExerciseBlock('벤치프레스', [LoggedSet(value: 20, reps: 10)], null, 'b0'),
    ]);
    final pyramid = day('p1', 2, [
      ExerciseBlock(
        '벤치프레스',
        [
          for (final kg in <double>[20, 40, 60, 80, 100, 110, 120])
            LoggedSet(value: kg, reps: kg == 120 ? 7 : 10),
          LoggedSet(value: 100, reps: 8),
        ],
        null,
        'b1',
      ),
    ]);
    // 다음 날 같은 무게는 새 기록이 아니다.
    final same = day('p2', 3, [
      ExerciseBlock('벤치프레스', [LoggedSet(value: 120, reps: 5)], null, 'b2'),
    ]);
    final r = weightRecords([before, pyramid, same]);
    expect(r['p1'], {
      'b1': {6},
    });
    expect(r['p2'], isNull);
  });
}
