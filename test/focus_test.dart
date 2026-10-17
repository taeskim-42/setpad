import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/focus.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/run_page.dart' show StagePortrait;

LoggedSet s(
  double? value,
  int? reps, {
  bool done = true,
  String unit = 'kg',
  String? author,
}) =>
    LoggedSet(value: value, reps: reps, done: done, unit: unit, author: author);

Note note(String id, DateTime at, List<ExerciseBlock> blocks) =>
    Note(id: id, createdAt: at, updatedAt: at, blocks: blocks);

String v(LoggedSet x) => '${x.value}${x.unit}x${x.reps}';

void main() {
  final key = exerciseKey('벤치프레스');
  FocusSuggestion next(ExerciseBlock b, [List<Note> earlier = const []]) =>
      nextSet(b, earlier, key: key, weightUnit: 'lb');

  final older = note('a', DateTime(2026, 10, 1), [
    ExerciseBlock('벤치프레스', [s(100, 1)]),
  ]);
  final last = note('b', DateTime(2026, 10, 10), [
    ExerciseBlock('벤치프레스', [
      s(60, 10),
      s(70, 8),
      s(999, 1, author: '준'), // someone else's: not mine
      s(80, 6),
      s(90, 1, done: false), // planned, never done
    ]),
    ExerciseBlock('스쿼트', [s(140, 5)]),
  ]);

  group('nextSet', () {
    test('planned: my first ○ with its id; theirs skipped', () {
      final theirs = s(50, 5, done: false, author: '준');
      final mine = s(80, 5, done: false);
      final b = ExerciseBlock('벤치프레스', [s(60, 10), theirs, mine]);
      final n = next(b, [last]);
      expect(n.source, FocusSource.planned);
      expect(n.plannedId, mine.id);
      expect(v(n.values), '80.0kgx5');
      // Last time here (k = 1 done today) is filled whatever the source.
      expect(v(n.lastTimeSame!), '70.0kgx8');
    });

    test(
      'last time: the k-th of my sets in the latest note, then its last',
      () {
        final b = ExerciseBlock('벤치프레스');
        expect(v(next(b, [older, last]).values), '60.0kgx10');
        expect(next(b, [last, older]).source, FocusSource.lastTime);
        b.sets.add(s(62.5, 10));
        expect(v(next(b, [last]).values), '70.0kgx8');
        b.sets.addAll([s(70, 8), s(80, 6), s(80, 6)]);
        // Past last time's three sets: its last one.
        expect(v(next(b, [last]).values), '80.0kgx6');
        expect(next(b, [last]).plannedId, isNull);
      },
    );

    test('last time beats today\'s last set (pyramid follows last time)', () {
      final b = ExerciseBlock('벤치프레스', [s(65, 10)]);
      expect(next(b, [last]).source, FocusSource.lastTime);
      expect(next(b).source, FocusSource.lastSet);
    });

    test('last set: my last done set, never someone else\'s', () {
      final b = ExerciseBlock('벤치프레스', [s(80, 5), s(120, 3, author: '준')]);
      final n = next(b);
      expect(n.source, FocusSource.lastSet);
      expect(v(n.values), '80.0kgx5');
      expect(n.lastTimeSame, isNull);
      // A block with only their sets is not mine to copy.
      expect(
        next(ExerciseBlock('벤치프레스', [s(120, 3, author: '준')])).source,
        FocusSource.none,
      );
    });

    test('setup is its own branch: below last time and last set', () {
      const setup = WorkoutSetup(
        name: '벤치프레스',
        weight: 80,
        repsPerSet: 5,
        totalSets: 5,
      );
      final b = ExerciseBlock('벤치 80kg 5x5', [], setup);
      final n = next(b);
      expect(n.source, FocusSource.setup);
      expect(v(n.values), '80.0kgx5');
      expect(next(b, [last]).source, FocusSource.lastTime);
      b.sets.add(s(82.5, 5));
      expect(next(b).source, FocusSource.lastSet);
      expect(v(next(b).values), '82.5kgx5');
      // A setup with nothing per set (only a total) suggests nothing.
      final total = ExerciseBlock(
        '벤치 5세트',
        [],
        const WorkoutSetup(name: '벤치프레스', totalSets: 5),
      );
      expect(next(total).source, FocusSource.none);
    });

    test('none: no numbers, the weight unit', () {
      final n = next(ExerciseBlock('벤치프레스'), [
        note('c', DateTime(2026, 10, 12), [
          ExerciseBlock('스쿼트', [s(100, 5)]),
        ]),
      ]);
      expect(n.source, FocusSource.none);
      expect(n.values.value, isNull);
      expect(n.values.reps, isNull);
      expect(n.values.unit, 'lb');
    });

    test('a stored weight of 0 comes back as bodyweight', () {
      final n = next(ExerciseBlock('벤치프레스', [s(0, 12)]));
      expect(n.values.value, isNull);
      expect(kindOf(n.values), FocusKind.reps);
    });
  });

  test('planDone: plan ○ all done, setup total sets, total reps', () {
    final planned = ExerciseBlock('벤치프레스', [s(80, 5), s(80, 5, done: false)]);
    expect(planDone(planned, hadPlan: true), isFalse);
    planned.sets.last.done = true;
    expect(planDone(planned, hadPlan: true), isTrue);
    // Without a plan or a setup: never over.
    expect(planDone(planned), isFalse);

    final sets = ExerciseBlock('벤치', [
      s(80, 5),
      s(80, 5, author: '준'),
    ], const WorkoutSetup(name: '벤치', totalSets: 2));
    expect(planDone(sets), isFalse); // their set does not count
    sets.sets.add(s(80, 5));
    expect(planDone(sets), isTrue);

    final reps = ExerciseBlock('푸시업', [
      s(null, 40),
    ], const WorkoutSetup(name: '푸시업', totalReps: 100));
    expect(planDone(reps), isFalse);
    reps.sets.add(s(null, 60));
    expect(planDone(reps), isTrue);
  });

  test('steps by unit; never below 0; weight 0 is bodyweight', () {
    expect(
      {
        for (final u in ['kg', 'lb', 's', 'min', 'km', 'm', 'mi'])
          u: valueStep(u),
      },
      {'kg': 2.5, 'lb': 5, 's': 10, 'min': 1, 'km': 0.5, 'm': 50, 'mi': 0.5},
    );
    expect(v(stepValue(s(80, 5), 1)), '82.5kgx5');
    expect(v(stepValue(s(5, 5, unit: 'lb'), -1)), 'nulllbx5');
    expect(stepValue(s(1, 5), -1).value, isNull); // 1 − 2.5 → 0 → bodyweight
    expect(v(stepValue(s(null, 12), 1)), '2.5kgx12');
    expect(stepValue(s(10, null, unit: 's'), -1).value, 0); // time stays 0
    expect(stepValue(s(0, null, unit: 's'), -1).value, 0);
    expect(v(stepValue(s(0.1, null, unit: 'km'), 1)), '0.6kmxnull');
    expect(stepReps(s(80, 5), 1).reps, 6);
    expect(stepReps(s(80, 1), -1).reps, isNull);
    expect(stepReps(s(80, null), 1).reps, 1);
    expect(stepReps(s(80, null), -1).reps, isNull);
  });

  test(
    'Done is on: weight and bodyweight need a rep, time/distance a value',
    () {
      expect(canLog(s(80, 5)), isTrue);
      expect(canLog(s(80, null)), isFalse);
      expect(canLog(s(null, 12)), isTrue);
      expect(canLog(s(null, null)), isFalse);
      expect(canLog(s(60, null, unit: 's')), isTrue);
      expect(canLog(s(0, null, unit: 's')), isFalse);
      expect(canLog(s(5, null, unit: 'km')), isTrue);
      expect(kindOf(s(5, null, unit: 'km')), FocusKind.distance);
      expect(kindOf(s(60, null, unit: 'min')), FocusKind.duration);
    },
  );

  group('stats', () {
    test('weight: volume in the first unit, other units converted', () {
      final r = stats([
        s(100, 5),
        s(231.4851, 1, unit: 'lb'), // = 105 kg
        s(null, 10), // bodyweight: 0 volume, its reps count
        s(500, 1, author: '준'),
        s(200, 1, done: false),
      ]);
      expect(r.sets, 3);
      expect(r.kind, FocusKind.weight);
      expect(r.unit, 'kg');
      expect(r.total, closeTo(605, 0.01));
      expect(r.reps, 16);
      expect(r.best!.unit, 'lb'); // the heaviest, converted
    });

    test('weight: ties go to more reps; lb first stays lb', () {
      final r = stats([
        s(100, 3, unit: 'lb'),
        s(100, 5, unit: 'lb'),
        s(100, 4, unit: 'lb'),
      ]);
      expect(r.unit, 'lb');
      expect(r.total, 1200);
      expect(r.best!.reps, 5);
    });

    test('bodyweight only: total reps, best is most reps', () {
      final r = stats([s(null, 12), s(null, 15), s(null, 10)]);
      expect(r.kind, FocusKind.reps);
      expect(r.total, 37);
      expect(r.best!.reps, 15);
    });

    test('time and distance: sums in the first unit, best the longest', () {
      final t = stats([s(60, null, unit: 's'), s(2, null, unit: 'min')]);
      expect(t.kind, FocusKind.duration);
      expect(t.unit, 's');
      expect(t.total, 180);
      expect(t.best!.unit, 'min');
      final d = stats([s(1, null, unit: 'km'), s(500, null, unit: 'm')]);
      expect(d.kind, FocusKind.distance);
      expect(d.total, 1.5);
      expect(d.best!.unit, 'km');
    });

    test('nothing: zero sets, no best', () {
      final r = stats(const []);
      expect(r.sets, 0);
      expect(r.best, isNull);
    });
  });

  test(
    'NotesStore: rest default 90 (15..600), per exercise up to 200, asked once',
    () async {
      final dir = Directory.systemTemp.createTempSync('focus');
      addTearDown(() => dir.deleteSync(recursive: true));
      Future<NotesStore> loaded() async {
        final store = NotesStore(directory: dir);
        await store.load();
        addTearDown(store.dispose);
        return store;
      }

      final store = await loaded();
      expect(store.restSeconds, 90);
      expect(store.restFor('벤치프레스'), 90);
      expect(store.focusNotifyAsked, isFalse);
      store.setRestSeconds(5);
      expect(store.restSeconds, 15);
      store.setRestSeconds(120);
      for (var i = 0; i < 205; i++) {
        store.setRestFor('운동$i', 60);
      }
      store.setRestFor('운동3', 180); // used again: newest, kept
      store.setRestFor('벤치프레스', 9999);
      store.setFocusNotifyAsked();
      await store.flush();

      final again = await loaded();
      expect(again.restSeconds, 120);
      expect(again.restByExercise, hasLength(NotesStore.restByExerciseMax));
      expect(again.restFor('벤치프레스'), 600);
      expect(again.restFor('운동3'), 180);
      expect(again.restFor('운동6'), 120); // oldest dropped: the default
      expect(again.restFor('운동7'), 60);
      expect(again.restByExercise.keys.last, '벤치프레스');
      expect(again.focusNotifyAsked, isTrue);
    },
  );

  testWidgets(
    'portrait holds while any stage is alive (timer and set stage share it)',
    (tester) async {
      final sent = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemChrome.setPreferredOrientations') {
            sent.add(call.arguments);
          }
          return null;
        },
      );
      StagePortrait.enter(); // the timer stage
      StagePortrait.enter(); // the set stage opened while it folds away
      StagePortrait.leave(); // the timer stage's dispose
      expect(sent, hasLength(2));
      expect(sent.last, ['DeviceOrientation.portraitUp']);
      StagePortrait.leave();
      expect(sent.last, isEmpty);
    },
  );
}
