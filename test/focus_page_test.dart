// Set stage screen (spec focus-stage-1.8 §7, §10 U). The rest's clock and the
// link's callbacks are fakes; the suggestions come from the real nextSet.
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/focus.dart';
import 'package:setpad/focus_link.dart';
import 'package:setpad/focus_page.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart' show exerciseKey;
import 'package:setpad/rest_timer.dart';
import 'package:setpad/run_page.dart' show StageStepKey;
import 'package:setpad/stage_palette.dart';
import 'package:setpad/timer_sheet.dart' show ValueSheet;
import 'package:setpad/timing_audio.dart';

class FakeAudio extends TimingAudio {
  @override
  Future<void> configure({
    required bool active,
    int? bpm,
    String? cue,
    double? phase,
  }) async {}

  @override
  Future<void> speak(String text, String locale, {double rate = 1.15}) async {}

  @override
  Future<void> dispose() async {}
}

LoggedSet s(
  double? value,
  int? reps, {
  bool done = true,
  String unit = 'kg',
  String? author,
}) =>
    LoggedSet(value: value, reps: reps, done: done, unit: unit, author: author);

/// The editor's side of the link, recorded.
class Rig {
  Rig(List<ExerciseBlock> blocks, {this.history = const []}) {
    link
      ..blocks = blocks
      ..currentId = blocks.first.id
      ..suggest = (b) {
        suggests++;
        return nextSet(b, history, key: exerciseKey(b.exercise));
      }
      ..lastTime = ((b) => lastTimeOf(history, exerciseKey(b.exercise)))
      ..restFor = ((b) => restOf[b.id] ?? const Duration(seconds: 90))
      ..onRestChanged = ((b, d) => restOf[b.id] = d)
      ..onLog = _log
      ..onUndo = _undo
      ..onStartTimer = timers.add
      ..onOpenSharedTimer = (() => sharedOpened++)
      ..onLift = lifts.add
      ..onRested = rested.add;
  }
  final List<Note> history;
  var clock = Duration.zero;
  late final rest = RestTimer(
    audio: FakeAudio(),
    now: () => clock,
    haptic: (_) {},
  );
  late final link = FocusLink(rest: rest);
  final logs = <(String block, String? planned, String values)>[];
  final undos = <String>[];
  final timers = <ExerciseBlock>[];
  final lifts = <ExerciseBlock>[], rested = <ExerciseBlock>[];
  final restOf = <String, Duration>{};
  final _old = <String, LoggedSet?>{};
  var suggests = 0, sharedOpened = 0;

  String? _log(ExerciseBlock b, String? plannedId, LoggedSet v) {
    logs.add((b.name, plannedId, '${v.value}${v.unit}x${v.reps}'));
    final i = b.sets.indexWhere(
      (x) => x.id == plannedId && !x.done && !x.theirs,
    );
    final set = LoggedSet(
      id: i < 0 ? null : plannedId,
      value: v.value,
      unit: v.unit,
      reps: v.reps,
    );
    if (i < 0) {
      b.sets.add(set);
      _old[set.id] = null;
    } else {
      _old[set.id] = b.sets[i];
      b.sets[i] = set;
    }
    return set.id;
  }

  void _undo(ExerciseBlock b, String id) {
    undos.add(id);
    final i = b.sets.indexWhere((x) => x.id == id);
    final old = _old.remove(id);
    if (old == null) {
      b.sets.removeAt(i);
    } else {
      b.sets[i] = old;
    }
  }

  void dispose() => rest.dispose();
}

class _Home extends StatelessWidget {
  const _Home(this.link);
  final FocusLink link;
  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    child: Center(
      child: CupertinoButton(
        key: const ValueKey('open'),
        onPressed: () => FocusPage.open(context, link),
        child: const Text('open'),
      ),
    ),
  );
}

const phone = Size(393, 852);
const shotKey = ValueKey('shot');

Future<void> settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 600));
  await t.pump();
}

Future<void> mount(
  WidgetTester t,
  Rig r, {
  Size size = phone,
  double scale = 1,
  String lang = 'ko',
  bool still = false,
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = size;
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  await t.pumpWidget(
    RepaintBoundary(
      key: shotKey,
      child: MediaQuery(
        data: MediaQueryData.fromView(
          t.view,
        ).copyWith(disableAnimations: still),
        child: CupertinoApp(
          locale: Locale(lang),
          supportedLocales: L.supportedLocales,
          localizationsDelegates: L.localizationsDelegates,
          home: _Home(r.link),
        ),
      ),
    ),
  );
  await t.tap(find.byKey(const ValueKey('open')));
  await settle(t);
}

Future<void> done(WidgetTester t, Rig r) async {
  r.rest.stop();
  await t.pumpWidget(const SizedBox());
  r.dispose();
}

/// Moves the rest's clock and the test clock together.
Future<void> advance(WidgetTester t, Rig r, Duration d) async {
  r.clock += d;
  await t.pump(d);
}

Finder key(String k) => find.byKey(ValueKey(k));

String text(WidgetTester t, String k) {
  final w = t.widget(key(k));
  if (w is Text) return w.data ?? w.textSpan!.toPlainText();
  // The hero: a FittedBox around rich text.
  final rich = t.widget<RichText>(
    find.descendant(of: key(k), matching: find.byType(RichText)).first,
  );
  return rich.text.toPlainText();
}

Future<void> tapKey(WidgetTester t, String k) async {
  await t.tap(key(k));
  await t.pump();
}

typedef Pixels = int Function(int x, int y);

Future<Pixels> pixels(WidgetTester t) async {
  late ByteData data;
  late int w;
  await t.runAsync(() async {
    final b = t.renderObject<RenderRepaintBoundary>(find.byKey(shotKey));
    final img = await b.toImage(pixelRatio: 1);
    data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    w = img.width;
  });
  return (x, y) {
    final o = (y * w + x) * 4;
    return data.getUint8(o) << 16 |
        data.getUint8(o + 1) << 8 |
        data.getUint8(o + 2);
  };
}

int rgb(Color c) => c.toARGB32() & 0xFFFFFF;

ExerciseBlock bench([List<LoggedSet>? sets]) => ExerciseBlock('벤치프레스', sets);

Note note(DateTime at, List<ExerciseBlock> blocks) =>
    Note(id: 'n$at', createdAt: at, updatedAt: at, blocks: blocks);

void main() {
  final lastWeek = note(DateTime(2026, 10, 10), [
    bench([s(60, 10), s(80, 5), s(80, 5)]),
  ]);

  group('LIFT: what is suggested and why', () {
    testWidgets('planned: the ○ set, "계획", last time here under it', (t) async {
      final r = Rig(
        [
          bench([s(60, 10), s(80, 5, done: false)]),
        ],
        history: [lastWeek],
      );
      await mount(t, r);
      expect(text(t, 'focus-name'), '벤치프레스');
      expect(text(t, 'focus-label'), '2세트 · 계획');
      expect(text(t, 'focus-hero'), '80 kg × 5');
      expect(text(t, 'focus-last-line'), '지난번 이 자리 80 × 5');
      await done(t, r);
    });

    testWidgets('LIFT: the hero is drawn white on the empty stage', (t) async {
      final r = Rig([
        bench([s(80, 5)]),
      ]);
      await mount(t, r);
      final rect = t.getRect(key('focus-hero'));
      final px = await pixels(t);
      var white = 0;
      for (var y = rect.top.ceil(); y < rect.bottom.floor(); y++) {
        for (var x = rect.left.ceil(); x < rect.right.floor(); x++) {
          if (px(x, y) == rgb(StagePalette.text)) white++;
        }
      }
      expect(white, greaterThan(1000));
      await done(t, r);
    });

    testWidgets('last time, last set, setup, none', (t) async {
      // Last time: today's k-th (k = 1) of last week.
      var r = Rig(
        [
          bench([s(60, 10)]),
        ],
        history: [lastWeek],
      );
      await mount(t, r);
      expect(text(t, 'focus-label'), '2세트 · 지난번 이 자리');
      expect(text(t, 'focus-hero'), '80 kg × 5');
      await done(t, r);

      r = Rig([
        bench([s(70, 8)]),
      ]);
      await mount(t, r);
      expect(text(t, 'focus-label'), '2세트 · 지난 세트와 같이');
      expect(text(t, 'focus-hero'), '70 kg × 8');
      expect(key('focus-last-line'), findsNothing);
      await done(t, r);

      r = Rig([
        ExerciseBlock(
          '벤치 80kg 5x5',
          [],
          const WorkoutSetup(
            name: '벤치프레스',
            weight: 80,
            repsPerSet: 5,
            totalSets: 5,
          ),
        ),
      ]);
      await mount(t, r);
      expect(text(t, 'focus-label'), '1세트 · 설정대로');
      expect(text(t, 'focus-hero'), '80 kg × 5');
      await done(t, r);

      r = Rig([bench()]);
      await mount(t, r);
      expect(text(t, 'focus-label'), '1세트 · 무게와 횟수를 정해요');
      expect(text(t, 'focus-hero'), '— × —');
      // Nothing to log: the bar picks the numbers.
      expect(key('focus-pick'), findsOneWidget);
      expect(key('focus-done'), findsNothing);
      await done(t, r);
    });

    testWidgets('bodyweight, time and distance heroes', (t) async {
      var r = Rig([
        ExerciseBlock('턱걸이', [s(null, 12)]),
      ]);
      await mount(t, r);
      expect(text(t, 'focus-hero'), '12회');
      expect(find.text('맨몸'), findsOneWidget);
      await done(t, r);

      r = Rig([
        ExerciseBlock('플랭크', [s(60, null, unit: 's')]),
      ]);
      await mount(t, r);
      expect(text(t, 'focus-hero'), '1:00');
      expect(key('focus-reps-value'), findsNothing);
      await done(t, r);

      r = Rig([
        ExerciseBlock('러닝', [s(5, null, unit: 'km')]),
      ]);
      await mount(t, r);
      expect(text(t, 'focus-hero'), '5 km');
      await done(t, r);
    });
  });

  group('steppers and wheels', () {
    testWidgets('the unit step; 0 is bodyweight; holding repeats', (t) async {
      final r = Rig([
        bench([s(2.5, 5)]),
      ]);
      await mount(t, r);
      await tapKey(t, 'focus-value-more');
      expect(text(t, 'focus-hero'), '5 kg × 5');
      await tapKey(t, 'focus-value-less');
      await tapKey(t, 'focus-value-less');
      expect(text(t, 'focus-hero'), '5회');
      expect(find.text('맨몸'), findsOneWidget);
      // Bodyweight can't go lower.
      expect(t.widget<StageStepKey>(key('focus-value-less')).onStep, isNull);
      // Held: about one more rep per 100 ms.
      final g = await t.startGesture(t.getCenter(key('focus-reps-more')));
      await t.pump(const Duration(milliseconds: 600));
      await t.pump(const Duration(milliseconds: 500));
      await g.up();
      await t.pump();
      final reps = int.parse(text(t, 'focus-hero').replaceAll('회', ''));
      expect(reps, greaterThan(8));
      // Nothing was written by the steppers.
      expect(r.logs, isEmpty);
      await done(t, r);
    });

    testWidgets('lb steps by 5', (t) async {
      final r = Rig([
        bench([s(135, 5, unit: 'lb')]),
      ]);
      r.link.weightUnit = 'lb';
      await mount(t, r);
      await tapKey(t, 'focus-value-more');
      expect(text(t, 'focus-hero'), '140 lb × 5');
      await done(t, r);
    });

    testWidgets('the wheel sheet sets the value; presets from last time', (
      t,
    ) async {
      final r = Rig(
        [
          bench([s(60, 10)]),
        ],
        history: [lastWeek],
      );
      await mount(t, r);
      await tapKey(t, 'focus-value-value');
      await settle(t);
      expect(find.text('무게'), findsWidgets);
      await tapKey(t, 'value-more');
      expect(text(t, 'focus-hero'), '82.5 kg × 5');
      await tapKey(t, 'value-preset-8000');
      expect(text(t, 'focus-hero'), '80 kg × 5');
      await tapKey(t, 'value-done');
      await settle(t);
      await tapKey(t, 'focus-reps-value');
      await settle(t);
      await tapKey(t, 'value-more');
      await tapKey(t, 'value-done');
      await settle(t);
      expect(text(t, 'focus-hero'), '80 kg × 6');
      expect(r.logs, isEmpty);
      await done(t, r);
    });
  });

  group('done, rest, undo', () {
    testWidgets(
      'done logs the planned id, the bar sleeps 1 s, undo takes set and rest',
      (t) async {
        final planned = s(80, 5, done: false);
        final r = Rig([
          bench([s(60, 10), planned, s(80, 5, done: false)]),
        ]);
        await mount(t, r);
        await tapKey(t, 'focus-done');
        expect(r.logs, [('벤치프레스', planned.id, '80.0kgx5')]);
        expect(r.rest.running, isTrue);
        expect(r.rested.single.name, '벤치프레스');
        expect(text(t, 'focus-label'), '휴식');
        // A second tap within the second does not skip the new rest.
        await t.tap(key('focus-skip'), warnIfMissed: false);
        await t.pump();
        expect(r.rest.running, isTrue);
        expect(key('focus-undo'), findsOneWidget);
        await tapKey(t, 'focus-undo');
        expect(r.undos, [planned.id]);
        expect(r.rest.running, isFalse);
        expect(text(t, 'focus-label'), '2세트 · 계획');
        expect(key('focus-undo'), findsNothing);
        await done(t, r);
      },
    );

    testWidgets('the undo chip goes after 5 s', (t) async {
      final r = Rig([
        bench([s(80, 5)]),
      ]);
      await mount(t, r);
      await tapKey(t, 'focus-done');
      expect(key('focus-undo'), findsOneWidget);
      await advance(t, r, const Duration(seconds: 5));
      await t.pump();
      expect(key('focus-undo'), findsNothing);
      await done(t, r);
    });

    testWidgets('REST: water, seconds left, ±15, end pulse, then LIFT on 0 s', (
      t,
    ) async {
      final r = Rig([
        bench([s(80, 5)]),
      ]);
      await mount(t, r);
      await tapKey(t, 'focus-done');
      expect(text(t, 'focus-hero'), '1:30');
      expect(text(t, 'focus-next-up'), '다음 · 3세트 80 × 5');
      await t.pump(const Duration(seconds: 1)); // bar awake again
      await advance(t, r, const Duration(seconds: 45));
      expect(text(t, 'focus-hero'), '45');
      // Half the rest: the rest color below the middle, dark above.
      final px = await pixels(t);
      expect(px(4, 852 - 100), rgb(StagePalette.fillRest));
      expect(px(4, 200), rgb(StagePalette.bg));

      await tapKey(t, 'focus-rest-more');
      expect(r.rest.length, const Duration(seconds: 105));
      expect(r.restOf.values.single, const Duration(seconds: 105));
      await tapKey(t, 'focus-rest-less');
      await tapKey(t, 'focus-rest-less');
      expect(r.rest.length, const Duration(seconds: 75));

      final suggested = r.suggests;
      await advance(t, r, const Duration(seconds: 28)); // 2 s left
      expect(text(t, 'focus-hero'), '2');
      final pulse = t.widget<ColoredBox>(key('run-end-pulse'));
      await t.pump(const Duration(milliseconds: 100));
      expect(
        t.widget<ColoredBox>(key('run-end-pulse')).color.a,
        greaterThan(pulse.color.a),
      );
      await advance(t, r, const Duration(seconds: 3));
      expect(r.rest.running, isFalse);
      expect(text(t, 'focus-label'), '3세트 · 지난 세트와 같이');
      expect(r.suggests, greaterThan(suggested));
      expect(r.lifts, isNotEmpty);
      await done(t, r);
    });

    testWidgets('next set now ends the rest', (t) async {
      final r = Rig([
        bench([s(80, 5)]),
      ]);
      await mount(t, r);
      await tapKey(t, 'focus-done');
      await t.pump(const Duration(seconds: 1));
      await tapKey(t, 'focus-skip');
      expect(r.rest.running, isFalse);
      expect(key('focus-done'), findsOneWidget);
      await done(t, r);
    });

    testWidgets('time sets do not start a rest; a small button does', (
      t,
    ) async {
      final r = Rig([
        ExerciseBlock('플랭크', [s(60, null, unit: 's')]),
      ]);
      await mount(t, r);
      await tapKey(t, 'focus-done');
      expect(r.logs, hasLength(1));
      expect(r.rest.running, isFalse);
      await tapKey(t, 'focus-start-rest');
      expect(r.rest.running, isTrue);
      await done(t, r);
    });
  });

  group('blocks', () {
    testWidgets('another block: LIFT with the rest pill; the pill goes back', (
      t,
    ) async {
      final row = ExerciseBlock('바벨로우', [s(60, 10)]);
      final r = Rig([
        bench([s(80, 5)]),
        row,
      ]);
      await mount(t, r);
      await tapKey(t, 'focus-done');
      await tapKey(t, 'focus-next');
      expect(text(t, 'focus-name'), '바벨로우');
      expect(key('focus-done'), findsOneWidget);
      expect(key('focus-rest-pill'), findsOneWidget);
      expect(r.link.currentId, row.id);
      // Superset: logging the row starts a new rest there.
      await t.pump(const Duration(seconds: 1));
      await tapKey(t, 'focus-done');
      expect((r.rest.owner as ExerciseBlock?)?.id, row.id);
      expect(text(t, 'focus-label'), '휴식');
      await tapKey(t, 'focus-prev');
      expect(text(t, 'focus-name'), '벤치프레스');
      await tapKey(t, 'focus-rest-pill');
      expect(text(t, 'focus-name'), '바벨로우');
      await done(t, r);
    });

    testWidgets('swipes move between blocks', (t) async {
      final r = Rig([
        bench([s(80, 5)]),
        ExerciseBlock('스쿼트', [s(100, 5)]),
      ]);
      await mount(t, r);
      await t.fling(
        key('focus-hero'),
        const Offset(-200, 0),
        1000,
        warnIfMissed: false,
      );
      await t.pump();
      expect(text(t, 'focus-name'), '스쿼트');
      await t.fling(
        key('focus-hero'),
        const Offset(200, 0),
        1000,
        warnIfMissed: false,
      );
      await t.pump();
      expect(text(t, 'focus-name'), '벤치프레스');
      await done(t, r);
    });

    testWidgets('changed() redraws without touching the values', (t) async {
      final b = bench([s(80, 5)]);
      final r = Rig([b]);
      await mount(t, r);
      await tapKey(t, 'focus-value-more');
      expect(text(t, 'focus-hero'), '82.5 kg × 5');
      final reads = r.suggests;
      b.sets.add(s(100, 3, author: '준'));
      r.link.changed();
      await t.pump();
      expect(text(t, 'focus-hero'), '82.5 kg × 5');
      expect(r.suggests, reads);
      expect(key('focus-chip-1'), findsOneWidget);
      await done(t, r);
    });

    testWidgets("someone else's sets are dim and take no tap", (t) async {
      final r = Rig([
        bench([s(80, 5), s(100, 3, author: '준')]),
      ]);
      await mount(t, r);
      final dim = find.ancestor(
        of: key('focus-chip-1'),
        matching: find.byType(Opacity),
      );
      expect(t.widget<Opacity>(dim.first).opacity, 0.4);
      await t.tap(key('focus-chip-1'), warnIfMissed: false);
      await t.pump();
      expect(text(t, 'focus-hero'), '80 kg × 5');
      // Mine: takes its numbers, writes nothing.
      await tapKey(t, 'focus-value-more');
      await tapKey(t, 'focus-chip-0');
      expect(text(t, 'focus-hero'), '80 kg × 5');
      expect(r.logs, isEmpty);
      await done(t, r);
    });

    testWidgets('a timer block starts the timer', (t) async {
      final tab = ExerciseBlock('버피 타바타 20/10 x8');
      final r = Rig([tab]);
      await mount(t, r);
      expect(key('focus-timer-summary'), findsOneWidget);
      await tapKey(t, 'focus-start-timer');
      expect(r.timers.single, same(tab));
      await done(t, r);
    });

    testWidgets('the plan done: "계획 끝", one more offered, next exercise', (
      t,
    ) async {
      final squat = ExerciseBlock('스쿼트', [s(100, 5, done: false)]);
      final r = Rig([
        bench([s(80, 5, done: false)]),
        squat,
      ]);
      await mount(t, r);
      expect(key('focus-next-exercise'), findsNothing);
      await tapKey(t, 'focus-done');
      await t.pump(const Duration(seconds: 1));
      await tapKey(t, 'focus-skip');
      expect(text(t, 'focus-label'), '2세트 · 계획 끝');
      expect(text(t, 'focus-hero'), '80 kg × 5');
      expect(key('focus-done'), findsOneWidget);
      expect(find.text('다음 운동: 스쿼트 →'), findsOneWidget);
      await tapKey(t, 'focus-next-exercise');
      expect(text(t, 'focus-name'), '스쿼트');
      await done(t, r);
    });

    testWidgets('summary: rows, last time and the difference', (t) async {
      final squat = ExerciseBlock('스쿼트', [s(100, 5)]);
      final r = Rig(
        [
          bench([s(60, 10), s(80, 5), s(80, 5)]),
          squat,
        ],
        history: [
          note(DateTime(2026, 10, 10), [
            bench([s(60, 10), s(80, 5)]),
          ]),
        ],
      );
      await mount(t, r);
      // Not the plan's end here: the finish button opens the summary.
      await tapKey(t, 'focus-next');
      await tapKey(t, 'focus-prev');
      await tapKey(t, 'focus-finish');
      expect(key('focus-summary'), findsOneWidget);
      expect(find.text('벤치프레스 끝!'), findsOneWidget);
      expect(find.text('1400kg'), findsOneWidget); // 600 + 400 + 400
      expect(find.text('80 × 5'), findsOneWidget); // best
      expect(find.text('3'), findsOneWidget);
      expect(
        find.descendant(of: key('focus-diff'), matching: find.text('+400kg')),
        findsOneWidget,
      );
      await tapKey(t, 'focus-one-more');
      expect(key('focus-done'), findsOneWidget);
      await tapKey(t, 'focus-finish');
      await tapKey(t, 'focus-summary-next');
      expect(text(t, 'focus-name'), '스쿼트');
      await done(t, r);
    });
  });

  group('lock, collapse, stray taps', () {
    testWidgets('locked: nothing works, a touch lights the hint, back nudges', (
      t,
    ) async {
      final r = Rig([
        bench([s(80, 5)]),
      ]);
      await mount(t, r);
      final g = await t.startGesture(t.getCenter(key('focus-lock')));
      await t.pump(const Duration(milliseconds: 150));
      await t.pump();
      await t.pump(const Duration(milliseconds: 2100));
      await g.up();
      await t.pump();
      expect(key('focus-locked-hint'), findsOneWidget);
      await t.tap(key('focus-done'), warnIfMissed: false);
      await t.pump();
      expect(r.logs, isEmpty);
      final dim = t.widget<Opacity>(
        find
            .descendant(
              of: key('focus-locked-hint'),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(dim.opacity, greaterThan(0.85));
      await t.pump(const Duration(milliseconds: 400));
      expect(
        t
            .widget<Opacity>(
              find
                  .descendant(
                    of: key('focus-locked-hint'),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        lessThan(0.6),
      );
      // Android back while locked keeps the stage.
      await t.binding.handlePopRoute();
      await settle(t);
      expect(key('focus-hero'), findsOneWidget);
      await done(t, r);
    });

    testWidgets('collapse pops and the rest keeps going', (t) async {
      final r = Rig([
        bench([s(80, 5)]),
      ]);
      await mount(t, r);
      await tapKey(t, 'focus-done');
      await t.tap(key('run-collapse'));
      await settle(t);
      expect(find.byType(FocusPage), findsNothing);
      expect(r.rest.running, isTrue);
      await done(t, r);
    });

    testWidgets('taps on the number and the ground do nothing', (t) async {
      final r = Rig([
        bench([s(80, 5)]),
      ]);
      await mount(t, r);
      await t.tap(key('focus-hero'), warnIfMissed: false);
      await t.tapAt(const Offset(200, 140));
      await t.pump();
      expect(r.logs, isEmpty);
      expect(text(t, 'focus-hero'), '80 kg × 5');
      expect(find.byType(ValueSheet), findsNothing);
      await done(t, r);
    });

    testWidgets('the shared timer strip opens the timer stage', (t) async {
      final r = Rig([
        bench([s(80, 5)]),
      ]);
      r.link.sharedTimerRunning = true;
      await mount(t, r);
      await tapKey(t, 'focus-shared-timer');
      expect(r.sharedOpened, 1);
      await done(t, r);
    });
  });

  group('no overflow', () {
    for (final size in const [Size(320, 568), Size(375, 667), phone]) {
      for (final lang in const ['ko', 'en', 'th', 'es', 'vi']) {
        testWidgets('${size.width.toInt()}x${size.height.toInt()} $lang', (
          t,
        ) async {
          for (final scale in const [1.0, 1.5, 2.0]) {
            final r = Rig(
              [
                bench([
                  s(82.5, 12),
                  s(80, 5, done: false),
                  s(100, 3, author: '준'),
                ]),
                ExerciseBlock('바벨로우 · 아주 긴 이름의 운동', [s(60, 10)]),
              ],
              history: [lastWeek],
            );
            await mount(t, r, size: size, scale: scale, lang: lang);
            expect(t.takeException(), isNull, reason: 'lift x$scale');
            await tapKey(t, 'focus-done');
            await t.pump(const Duration(seconds: 1));
            expect(t.takeException(), isNull, reason: 'rest x$scale');
            await tapKey(t, 'focus-next');
            expect(t.takeException(), isNull, reason: 'pill x$scale');
            await t.pump(const Duration(seconds: 1));
            await tapKey(t, 'focus-finish');
            expect(t.takeException(), isNull, reason: 'summary x$scale');
            await done(t, r);
          }
        });
      }
    }
  });
}
