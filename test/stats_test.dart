import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/stats.dart';

/// 숫자를 세는 코드는 답이 틀려도 사람이 검산할 수 없다. 최소한 이 성질들은
/// 지켜야 한다 — 화면이 붙기 전에 여기서 잡는다.
void main() {
  setUpAll(() => initializeDateFormatting());
  Note note(
    DateTime at,
    String name,
    List<(double, int)> sets, {
    bool done = true,
  }) => Note(
    id: at.microsecondsSinceEpoch.toString(),
    createdAt: at,
    updatedAt: at,
    blocks: [
      ExerciseBlock(name, [
        for (final (w, r) in sets) LoggedSet(value: w, reps: r, done: done),
      ]),
    ],
  );

  final day = DateTime(2026, 8, 1);
  final notes = [
    note(day, '벤치프레스', [(60, 12), (65, 10)]),
    note(day.add(const Duration(days: 7)), '벤치프레스', [(70, 8)]),
    note(day.add(const Duration(days: 14)), '벤치프레스', [(80, 5), (75, 6)]),
    note(day.add(const Duration(days: 3)), '스쿼트', [(100, 5)]),
  ];

  test('하루에 점 하나, 그날 가장 무거운 것', () {
    final p = dailyBest(notes, '벤치프레스');
    expect(p.length, 3);
    expect(p.map((e) => e.value), [65, 70, 80]); // 첫날은 60·65 중 65
  });

  test('다른 운동은 섞이지 않는다', () {
    expect(dailyBest(notes, '스쿼트').single.value, 100);
  });

  test('취소한 세트는 없는 것이다', () {
    final only = [
      note(day, '데드리프트', [(150, 1)], done: false),
    ];
    expect(answer(only, Metric.max, '데드리프트').isEmpty, isTrue);
  });

  test('최고는 가장 무거운 세트와 그날을 낸다', () {
    final a = answer(notes, Metric.max, '벤치프레스');
    expect(a.headline, '80kg × 5회');
    expect(a.lines.first, '8월 15일');
  });

  test('추이는 처음과 끝의 차를 낸다', () {
    final a = answer(notes, Metric.trend, '벤치프레스');
    expect(a.headline, '+15kg'); // 65 → 80
    expect(a.points.length, 3);
  });

  test('마지막은 그날 친 세트를 다 낸다', () {
    final a = answer(
      notes,
      Metric.last,
      '벤치프레스',
      now: day.add(const Duration(days: 20)),
    );
    expect(a.headline, contains('80kg × 5회'));
    expect(a.headline, contains('75kg × 6회'));
    expect(a.lines.last, '6일 전');
  });

  test('볼륨은 무게×횟수의 합이다', () {
    // 60*12 + 65*10 + 70*8 + 80*5 + 75*6 = 720+650+560+400+450
    expect(answer(notes, Metric.volume, '벤치프레스').headline, '2780kg');
  });

  test('since 밖의 날은 빠진다', () {
    final a = answer(
      notes,
      Metric.max,
      '벤치프레스',
      since: day.add(const Duration(days: 10)),
    );
    expect(a.points.length, 1);
    expect(a.headline, '80kg × 5회');
  });

  test('기록이 없으면 빈 답이다', () {
    expect(answer(notes, Metric.max, '레그프레스').isEmpty, isTrue);
  });
}
