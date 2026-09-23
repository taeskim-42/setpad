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

  group('점 솎기', () {
    List<DayPoint> daily(int n) => [
      for (var i = 0; i < n; i++)
        DayPoint(day.add(Duration(days: i)), 40 + (i % 7).toDouble(), 5, 'kg'),
    ];

    test('적으면 손대지 않는다', () {
      final p = daily(20);
      expect(identical(thinPoints(p), p), isTrue);
    });

    test('많으면 26개 아래로 솎는다', () {
      final thin = thinPoints(daily(101));
      expect(thin.length, lessThanOrEqualTo(26));
      expect(thin.length, greaterThan(20));
    });

    test('남긴 점은 그 구간의 실제 최고이고, 날짜는 지어내지 않는다', () {
      final all = daily(101);
      final thin = thinPoints(all);
      for (final p in thin) {
        expect(all.any((a) => a.day == p.day && a.value == p.value), isTrue);
      }
      // 남긴 점은 제 구간 안에서 가장 무겁다. 구간 폭은 solve 와 같은 식이다 —
      // 값의 주기(7)가 구간 폭(4)보다 길어서 "전부 46" 같은 기대는 틀린다.
      final bucket = (101 / 26).ceil();
      for (final p in thin) {
        final key = p.day.difference(all.first.day).inDays ~/ bucket;
        final peers = all.where(
          (a) => a.day.difference(all.first.day).inDays ~/ bucket == key,
        );
        expect(
          p.value,
          peers.map((a) => a.value).reduce((x, y) => x > y ? x : y),
        );
      }
      final days = thin.map((p) => p.day).toList();
      expect(days, [...days]..sort());
    });
  });

  // 스펙 3.11-A 픽스처. 오늘은 2026-09-23(수), 단위는 kg 다. 여기서는 칸 하나를
  // 세는 stats 만 본다 — 거르기·묶기·"해당 없음" 나누기는 실행기가 한다.
  group('v2 측정', () {
    final today = DateTime(2026, 9, 23, 21);
    LoggedSet s(
      double? v,
      int? r, {
      String u = 'kg',
      bool done = true,
      List<String>? memo,
    }) => LoggedSet(value: v, unit: u, reps: r, done: done, notes: memo);
    Note n(String id, int month, int day, List<ExerciseBlock> blocks) {
      final at = DateTime(2026, month, day, 19);
      return Note(id: id, createdAt: at, updatedAt: at, blocks: blocks);
    }

    final fixture = [
      n('N1', 8, 4, [
        ExerciseBlock('벤치프레스', [s(80, 5), s(85, 3), s(90, 1, done: false)]),
        ExerciseBlock('바벨로우', [s(60, 8), s(60, 8)]),
      ]),
      n('N2', 8, 18, [
        ExerciseBlock('벤치프레스', [s(82.5, 5), s(82.5, 5)]),
        ExerciseBlock('풀업', [s(null, 10), s(null, 8)]),
      ]),
      n('N3', 9, 7, [
        ExerciseBlock('벤치프레스', [
          s(85, 5, memo: ['어깨 뻐근']),
        ]),
        ExerciseBlock('바벨로우', [s(70, 6), s(150, 5, u: 'lb')]),
      ]),
      n('N4', 9, 14, [
        ExerciseBlock('스쿼트', [s(100, 5), s(105, 3)]),
        ExerciseBlock('플랭크', [s(60, null, u: 's'), s(90, null, u: 's')]),
      ]),
      n('N5', 9, 21, [
        ExerciseBlock('벤치프레스', [s(87.5, 2)]),
        ExerciseBlock('러닝', [s(5, null, u: 'km'), s(3000, null, u: 'm')]),
      ]),
      n('N6', 9, 22, [
        ExerciseBlock('딥스', [s(20, 10), s(null, 12)]),
      ]),
    ];
    Answer ask(Metric m, String name, {String unit = 'kg', DateTime? since}) =>
        answer(fixture, m, name, now: today, unit: unit, since: since);

    // 실행기는 한 칸에 운동이 여럿이면 블록 이름을 '*' 로 바꿔 부른다.
    List<Note> star(Iterable<Note> notes, {Set<String> drop = const {}}) => [
      for (final note in notes)
        Note(
          id: note.id,
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          blocks: [
            for (final b in note.blocks)
              if (!drop.contains(b.exercise)) ExerciseBlock('*', b.sets),
          ],
        ),
    ];

    test('최고는 적은 숫자의 종류로 정한다: 무게 → 시간 → 거리 → 반복', () {
      expect(resolveBest(fixture, '벤치프레스'), Metric.max);
      expect(resolveBest(fixture, '딥스'), Metric.max);
      expect(resolveBest(fixture, '플랭크'), Metric.longest);
      expect(resolveBest(fixture, '러닝'), Metric.longest);
      expect(resolveBest(fixture, '풀업'), Metric.maxReps);
    });

    test('벤치 최고 87.5 — 해내지 않은 90 은 없다', () {
      final a = ask(Metric.best, '벤치프레스');
      expect(a.metric, Metric.max);
      expect(a.numericValue, 87.5);
      expect(a.headline, '87.5kg × 2회');
      expect(a.lines.first, '9월 21일');
    });

    test('추정 1RM 은 Epley, 1–10회 세트만', () {
      final a = ask(Metric.e1rm, '벤치프레스');
      expect(a.numericValue, closeTo(85 * (1 + 5 / 30), 1e-9));
      expect(a.headline, '≈99.17kg');
      expect(a.lines.take(2), ['9월 7일', '85kg × 5회']);
      final other = [
        n('x', 9, 1, [
          ExerciseBlock('데드리프트', [s(100, 12), s(60, 10), s(70, 1)]),
        ]),
      ];
      // 100×12 는 정의상 빠지고, 1회는 든 무게 그대로다: 60×(1+10/30)=80 > 70.
      expect(answer(other, Metric.e1rm, '데드리프트').numericValue, 80);
      final missing = [
        n('y', 9, 1, [
          ExerciseBlock('데드리프트', [s(100, 5), s(120, null)]),
        ]),
      ];
      expect(answer(missing, Metric.e1rm, '데드리프트').isEmpty, isTrue);
    });

    test('볼륨: 벤치 2080, 로우는 150lb 를 kg 로 바꿔 ≈1720.19', () {
      expect(ask(Metric.volume, '벤치프레스').headline, '2080kg');
      final row = ask(Metric.volume, '바벨로우');
      expect(row.numericValue, closeTo(960 + 420 + 150 * 0.45359237 * 5, 1e-9));
      expect(row.headline, '≈1720.19kg');
    });

    test('무게가 없으면 최고는 반복·시간·거리다', () {
      final pull = ask(Metric.best, '풀업');
      expect(pull.metric, Metric.maxReps);
      expect((pull.numericValue, pull.headline), (10, '10회'));
      final plank = ask(Metric.best, '플랭크');
      expect(plank.metric, Metric.longest);
      expect((plank.numericValue, plank.headline), (90, '90초'));
      // km 와 m 가 섞이면 km 로 견준다.
      final run = ask(Metric.best, '러닝');
      expect((run.numericValue, run.headline), (5, '5km'));
    });

    test('총 거리·시간: 단위가 섞이면 km, 하나면 그대로', () {
      final run = ask(Metric.distance, '러닝');
      expect((run.numericValue, run.headline), (8, '8km'));
      final plank = ask(Metric.duration, '플랭크');
      expect((plank.numericValue, plank.headline), (150, '150초'));
      expect(ask(Metric.distance, '플랭크').isEmpty, isTrue);
    });

    test('무게를 적은 운동에 빈 세트가 있으면 최고는 모른다', () {
      expect(ask(Metric.best, '딥스').isEmpty, isTrue);
      expect(ask(Metric.maxReps, '딥스').numericValue, 12);
    });

    test("'*' 칸: 세트·날은 다 세고, 합은 해당 없는 운동을 빼야 나온다", () {
      expect(answer(star(fixture), Metric.sets, '*').numericValue, 20);
      expect(answer(star(fixture), Metric.sessions, '*').numericValue, 6);
      expect(answer(star(fixture), Metric.reps, '*').isEmpty, isTrue);
      final reps = answer(star(fixture, drop: {'플랭크', '러닝'}), Metric.reps, '*');
      expect(reps.numericValue, 100);
      // 지난주(9/14–9/20) 는 N4 하나. 플랭크를 빼면 스쿼트만 남는다.
      final lastWeek = star([fixture[3]], drop: {'플랭크'});
      expect(answer(lastWeek, Metric.volume, '*').numericValue, 815);
      // 이번 주는 딥스의 빈 세트 때문에 모른다.
      final thisWeek = star(fixture.skip(4), drop: {'러닝'});
      expect(answer(thisWeek, Metric.volume, '*').isEmpty, isTrue);
    });

    test('lb 로 보면 같은 최고를 lb 로 낸다', () {
      expect(
        ask(Metric.best, '벤치프레스', unit: 'lb').numericValue,
        87.5 / 0.45359237,
      );
    });

    test('처음은 첫날의 세트, 쉰 날은 오늘 − 마지막 날', () {
      final first = ask(Metric.first, '벤치프레스');
      expect(first.lines.first, '8월 4일');
      expect(first.headline, '80kg × 5회  85kg × 3회');
      expect(ask(Metric.daysSince, '풀업').numericValue, 36);
      expect(ask(Metric.daysSince, '스쿼트').numericValue, 9);
      final row = ask(Metric.daysSince, '바벨로우');
      expect((row.numericValue, row.headline), (16, '16일 전'));
    });

    test('쉰 날은 서머타임에 걸려도 달력으로 센다', () {
      final spring = [
        n('z', 3, 8, [
          ExerciseBlock('스쿼트', [s(100, 5)]),
        ]),
      ];
      final a = answer(
        spring,
        Metric.daysSince,
        '스쿼트',
        now: DateTime(2026, 3, 9, 0, 30),
      );
      expect(a.numericValue, 1);
    });

    test('마지막 2번의 추이는 +2.5kg', () {
      final a = ask(Metric.trend, '벤치프레스', since: DateTime(2026, 9, 7));
      expect(a.headline, '+2.5kg');
    });
  });
}
