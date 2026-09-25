import 'package:setpad/editor.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_ai.dart' show WorkoutSetup;

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

/// 시각 [t] 에 시작한 기록 하나(세트당 45분 안팎).
Note at(DateTime t, List<ExerciseBlock> blocks) => Note(
  id: t.toIso8601String(),
  createdAt: t,
  updatedAt: t.add(const Duration(minutes: 45)),
  blocks: blocks,
);

/// 합성 주(설계 §8.1): [monday] 부터 [days] 일, 요일(1–7)마다 [plan] 의 칸으로 19시에
/// 한 기록. [skip] 의 날은 쉰다.
List<Note> weekLog(
  DateTime monday,
  int days,
  Map<int, List<ExerciseBlock> Function()> plan, {
  Set<DateTime> skip = const {},
}) => [
  for (var i = 0; i < days; i++)
    if (plan[monday.add(Duration(days: i)).weekday] case final p?)
      if (!skip.contains(monday.add(Duration(days: i))))
        at(monday.add(Duration(days: i, hours: 19)), p()),
];

/// 월 가슴 / 화 등 / 수 하체 / 목 어깨 / 금 팔(모두 3세트).
final splitPlan = <int, List<ExerciseBlock> Function()>{
  1: () => [
    ExerciseBlock('벤치프레스', times(3, () => kg(80, 5))),
    ExerciseBlock('인클라인 벤치프레스', times(3, () => kg(50, 10))),
  ],
  2: () => [
    ExerciseBlock('데드리프트', times(3, () => kg(100, 5))),
    ExerciseBlock('랫풀다운', times(3, () => kg(55, 10))),
  ],
  3: () => [
    ExerciseBlock('스쿼트', times(3, () => kg(90, 5))),
    ExerciseBlock('레그컬', times(3, () => kg(40, 12))),
  ],
  4: () => [
    ExerciseBlock('오버헤드프레스', times(3, () => kg(40, 8))),
    ExerciseBlock('사이드 레터럴 레이즈', times(3, () => kg(8, 15))),
  ],
  5: () => [
    ExerciseBlock('바벨컬', times(3, () => kg(30, 10))),
    ExerciseBlock('케이블 푸시다운', times(3, () => kg(25, 12))),
  ],
};

/// 방식만 다른 한 주(설계 §2.4): 월 순발력(5×5) · 화 근지구력(채우기·줄어드는 횟수) ·
/// 수 근력(3×10) · 목 지속력(10회×7세트) · 금 심폐(타바타).
final methodPlan = <int, List<ExerciseBlock> Function()>{
  1: () => [
    ExerciseBlock(
      '스쿼트 100kg 5x5',
      times(5, () => kg(100, 5)),
      const WorkoutSetup(name: '스쿼트', weight: 100, repsPerSet: 5, totalSets: 5),
    ),
    ExerciseBlock('벤치프레스', times(5, () => kg(80, 5))),
  ],
  2: () => [
    ExerciseBlock('스쿼트 60kg 100개 채우기', [
      kg(60, 30),
      kg(60, 25),
      kg(60, 25),
      kg(60, 20),
    ], const WorkoutSetup(name: '스쿼트', weight: 60, totalReps: 100)),
    ExerciseBlock('푸시업 100개 채우기', [reps(30), reps(25), reps(25), reps(20)]),
    ExerciseBlock('랫풀다운', [kg(40, 23), kg(40, 18), kg(40, 15)]),
  ],
  3: () => [
    ExerciseBlock('스쿼트', times(3, () => kg(80, 10))),
    ExerciseBlock('벤치프레스', times(3, () => kg(60, 10))),
  ],
  4: () => [
    ExerciseBlock('스쿼트 30bpm', times(7, () => kg(60, 10))),
    ExerciseBlock('벤치프레스 30bpm', [...times(6, () => kg(40, 10)), kg(40, 7)]),
  ],
  5: () => [
    ExerciseBlock('스쿼트 타바타', [reps(80)]),
    ExerciseBlock('버피 타바타', [reps(40)]),
  ],
};

List<Note> methodWeek(DateTime monday) => weekLog(monday, 5, methodPlan);

/// 코퍼스 기준일(9/9 수) 앞의 합성 기록: 방식 주 두 벌(8/24·8/31), 분할 3주(8/17–9/6).
List<Note> logFor(String? profile) => switch (profile) {
  'empty' => <Note>[],
  'few' => fewLog(),
  'methodWeek' => [
    ...methodWeek(DateTime(2026, 8, 24)),
    ...methodWeek(DateTime(2026, 8, 31)),
  ],
  'split' => weekLog(DateTime(2026, 8, 17), 21, splitPlan),
  _ => defaultLog(),
};
