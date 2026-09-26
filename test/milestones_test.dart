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
}
