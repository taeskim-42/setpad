import 'package:setpad/editor.dart';
import 'package:setpad/notes.dart';

/// 코퍼스 assumedLog(기준일 2026-09-09 수)에 실제 세트를 붙인 기록(설계 §12.1).
///
/// - 8/26 레그프레스는 lb 로 적었다.
/// - 9/2 는 트레이너 루틴(routineId)이고, 안 한 세트(○) 하나가 남아 있다.
/// - 9/8 에는 같이 한 사람의 세트(author)와 메모 '허리 뻐근' 이 있다.
/// - 제목 '푸시업 60bpm'·'버피 타바타' 는 타이머 제목이다.
/// - 끝 시각은 세트당 160초가 되게 둔다.
final routineToday = DateTime(2026, 9, 9, 18);

LoggedSet kg(
  double v,
  int r, {
  bool done = true,
  String? author,
  String? memo,
}) => LoggedSet(
  value: v,
  reps: r,
  done: done,
  author: author,
  notes: memo == null ? null : [memo],
);
LoggedSet lb(double v, int r) => LoggedSet(value: v, unit: 'lb', reps: r);
LoggedSet reps(int r) => LoggedSet(reps: r);
LoggedSet timed(double v, String unit) => LoggedSet(value: v, unit: unit);
List<LoggedSet> times(int n, LoggedSet Function() make) =>
    List.generate(n, (_) => make());

Note session(
  String id,
  int month,
  int day,
  List<ExerciseBlock> blocks, {
  String? routineId,
  int secondsPerSet = 160,
}) {
  final at = DateTime(2026, month, day, 19);
  final sets = blocks.fold(0, (n, b) => n + b.sets.where((s) => s.mine).length);
  return Note(
    id: id,
    createdAt: at,
    updatedAt: at.add(Duration(seconds: sets * secondsPerSet)),
    blocks: blocks,
    routineId: routineId,
  );
}

List<Note> defaultLog() => [
  session('0718', 7, 18, [
    ExerciseBlock('사이클', [timed(30, 'min')]),
  ]),
  session('0824', 8, 24, [
    ExerciseBlock('벤치프레스', [kg(60, 10), ...times(3, () => kg(80, 5))]),
    ExerciseBlock('인클라인 벤치프레스', times(3, () => kg(50, 10))),
    ExerciseBlock('케이블 푸시다운', times(3, () => kg(25, 12))),
  ]),
  session('0826', 8, 26, [
    ExerciseBlock('스쿼트', [kg(60, 8), ...times(3, () => kg(90, 5))]),
    ExerciseBlock('레그프레스', times(3, () => lb(330, 10))),
    ExerciseBlock('레그컬', times(3, () => kg(40, 12))),
  ]),
  session('0828', 8, 28, [
    ExerciseBlock('데드리프트', times(3, () => kg(100, 5))),
    ExerciseBlock('랫풀다운', times(3, () => kg(55, 10))),
    ExerciseBlock('시티드 로우', times(3, () => kg(50, 10))),
    ExerciseBlock('바벨컬', times(3, () => kg(30, 10))),
  ]),
  session('0831', 8, 31, [
    ExerciseBlock('벤치프레스', [kg(60, 10), kg(85, 3), kg(82.5, 5), kg(82.5, 5)]),
    ExerciseBlock('오버헤드프레스', times(3, () => kg(40, 8))),
    ExerciseBlock('사이드 레터럴 레이즈', times(3, () => kg(8, 15))),
  ]),
  session('0901', 9, 1, [
    ExerciseBlock('러닝', [timed(5, 'km')]),
  ]),
  session('0902', 9, 2, routineId: 'legA', [
    ExerciseBlock('스쿼트', [kg(60, 8), ...times(3, () => kg(92.5, 5))]),
    ExerciseBlock('루마니안 데드리프트', times(3, () => kg(60, 10))),
    ExerciseBlock('레그컬', [
      ...times(3, () => kg(42.5, 12)),
      kg(45, 12, done: false),
    ]),
  ]),
  session('0904', 9, 4, [
    ExerciseBlock('랫풀다운', times(3, () => kg(57.5, 10))),
    ExerciseBlock('풀업', times(3, () => reps(8))),
    ExerciseBlock('시티드 로우', times(3, () => kg(52.5, 10))),
    ExerciseBlock('바벨컬', times(3, () => kg(32.5, 10))),
  ]),
  session('0905', 9, 5, [
    ExerciseBlock('푸시업 60bpm', times(3, () => reps(20))),
    ExerciseBlock('버피 타바타', [reps(10)]),
  ]),
  session('0907', 9, 7, [
    ExerciseBlock('벤치프레스', [kg(60, 10), ...times(3, () => kg(85, 5))]),
    ExerciseBlock('덤벨 프레스', times(3, () => kg(30, 10))),
    ExerciseBlock('케이블 푸시다운', times(3, () => kg(27.5, 12))),
    ExerciseBlock('플랭크', times(3, () => timed(60, 's'))),
  ]),
  session('0908', 9, 8, [
    ExerciseBlock('데드리프트', [
      kg(105, 5, memo: '허리 뻐근'),
      kg(105, 5),
      kg(105, 5),
      kg(140, 3, author: '민수'),
    ]),
    ExerciseBlock('랫풀다운', times(3, () => kg(60, 10))),
    ExerciseBlock('시티드 로우', times(3, () => kg(55, 10))),
  ]),
];

List<Note> fewLog() => [
  session('f905', 9, 5, [ExerciseBlock('푸시업', times(2, () => reps(20)))]),
  session('f907', 9, 7, [
    ExerciseBlock('스쿼트', times(3, () => kg(60, 10))),
    ExerciseBlock('레그프레스', times(3, () => kg(100, 10))),
  ]),
];

List<Note> logFor(String? profile) => switch (profile) {
  'empty' => <Note>[],
  'few' => fewLog(),
  _ => defaultLog(),
};
