// Run stage (spec 1.8 §6, §12 S). No goldens: sizes, pixel colors and
// takeException, the way Tempo's run_look_test checks its run screen.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/run_link.dart';
import 'package:setpad/run_page.dart';
import 'package:setpad/stage_palette.dart';
import 'package:setpad/timing_audio.dart';
import 'package:setpad/workout_timing.dart';

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

const tabata = TimingSpec(tabata: true);
const phone = Size(393, 852);
const shotKey = ValueKey('shot');

/// One engine on a hand-driven clock, and the link the editor would fill.
class Rig {
  Rig() {
    link
      ..title = '버피'
      ..onLogRound = ((r, n) => rounds.add((r, n)))
      ..onLogCount = counts.add
      ..onLeave = (() => leaves++)
      ..onRejoin = (() => rejoins++)
      ..onLogged = (() => logged++);
  }
  var now = Duration.zero;
  late final timer = WorkoutTimer(
    audio: FakeAudio(),
    now: () => now,
    haptic: (_) {},
  );
  late final link = RunLink(timer);
  final owner = Object();
  final rounds = <(int, int?)>[];
  final counts = <int>[];
  var leaves = 0, rejoins = 0, logged = 0;

  void startAt(TimingSpec spec, Duration at, {int? target}) {
    timer.toggle(owner, spec, target: target);
    now = at;
    timer.tick();
  }
}

class _Home extends StatelessWidget {
  const _Home(this.link);
  final RunLink link;
  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    child: Center(
      child: CupertinoButton(
        key: const ValueKey('open'),
        onPressed: () => RunPage.open(context, link),
        child: const Text('open'),
      ),
    ),
  );
}

/// Opens the stage over a home page.
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
  await t.pump();
  await sheet(t);
  await t.pump();
}

/// Moves the engine's clock and the test clock together.
Future<void> advance(WidgetTester t, Rig r, Duration d) async {
  r.now += d;
  await t.pump(d);
}

Future<void> done(WidgetTester t, Rig r) async {
  await t.pumpWidget(const SizedBox());
  r.timer.dispose();
}

const _ms = Duration(milliseconds: 1);

/// Presses [f] past the press timeout (the swipe detector competes), then
/// holds for [d].
Future<TestGesture> hold(WidgetTester t, Finder f, Duration d) async {
  final g = await t.startGesture(t.getCenter(f));
  await t.pump(_ms * 150);
  await t.pump();
  await t.pump(_ms * 16);
  await t.pump(d);
  return g;
}

/// Lets a route or sheet transition finish (two frames: start, end).
Future<void> sheet(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 600));
  await t.pump();
}

Finder key(String k) => find.byKey(ValueKey(k));

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

int countRgb(Pixels px, Rect r, double fromY, double toY, int rgb) {
  var n = 0;
  for (var y = fromY.ceil(); y < toY.floor(); y++) {
    for (var x = r.left.ceil(); x < r.right.floor(); x++) {
      if (px(x, y) == rgb) n++;
    }
  }
  return n;
}

int rgb(Color c) => c.toARGB32() & 0xFFFFFF;

double luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final x = luminance(a), y = luminance(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

void main() {
  group('look', () {
    testWidgets('one digit fills 40% of the height; two use 90% of the width', (
      t,
    ) async {
      for (final size in [phone, const Size(375, 667)]) {
        final r = Rig()..startAt(tabata, const Duration(seconds: 21));
        await mount(t, r, size: size);
        expect(find.text('2'), findsNWidgets(2));
        final one = t.getSize(key('run-number'));
        expect(one.height, greaterThanOrEqualTo(size.height * 0.4));
        expect(one.width, lessThanOrEqualTo(size.width * 0.9 + 0.5));
        r.now = const Duration(seconds: 13); // "10"
        r.timer.tick();
        await t.pump();
        final two = t.getSize(key('run-number'));
        expect(two.width, closeTo(size.width * 0.9, 1));
        await done(t, r);
      }
    });

    testWidgets('320x568: the number keeps 30% of the height, 1.0 to 2.0', (
      t,
    ) async {
      for (final scale in [1.0, 2.0]) {
        final r = Rig()..startAt(tabata, const Duration(seconds: 21));
        await mount(t, r, size: const Size(320, 568), scale: scale);
        expect(
          t.getSize(key('run-number')).height,
          greaterThanOrEqualTo(568 * 0.3),
          reason: 'x$scale',
        );
        await done(t, r);
      }
    });

    testWidgets(
      'the waterline cuts the digits: white above, dark below, fill around',
      (t) async {
        // 90 s work: the level is easy to put through the number's middle.
        const spec = TimingSpec(tabata: true, work: 90, rest: 10);
        final r = Rig()..startAt(spec, const Duration(seconds: 13));
        await mount(t, r, still: true);
        final box = t.getRect(key('run-number'));
        final level = (852 - box.center.dy) / 852;
        r.now = Duration(milliseconds: (3000 + 90000 * (1 - level)).round());
        r.timer.tick();
        await t.pump(const Duration(milliseconds: 1100));
        final rect = t.getRect(key('run-number'));
        final line = (852 - 852 * r.timer.level).roundToDouble();
        expect(rect.top, lessThan(line - 20));
        expect(rect.bottom, greaterThan(line + 20));
        final px = await pixels(t);
        final white = rgb(StagePalette.text);
        final dark = rgb(StagePalette.onFill);
        expect(countRgb(px, rect, rect.top, line, white), greaterThan(500));
        expect(countRgb(px, rect, line, rect.bottom, white), 0);
        expect(countRgb(px, rect, line, rect.bottom, dark), greaterThan(200));
        // The ground beside the number: empty above, coral below.
        expect(px(4, (line - 10).toInt()), rgb(StagePalette.bg));
        expect(px(4, (line + 10).toInt()), rgb(StagePalette.fillWork));
        await done(t, r);
      },
    );

    testWidgets('the two faces sit on each other', (t) async {
      final r = Rig()..startAt(tabata, const Duration(seconds: 13));
      await mount(t, r);
      final faces = find.text('10');
      expect(faces, findsNWidgets(2));
      expect(t.getRect(faces.at(0)), t.getRect(faces.at(1)));
      final labels = find.text('운동');
      expect(t.getRect(labels.at(0)), t.getRect(labels.at(1)));
      await done(t, r);
    });

    testWidgets('paused: the fill turns grey and stops', (t) async {
      final r = Rig()..startAt(tabata, const Duration(seconds: 13));
      await mount(t, r);
      var px = await pixels(t);
      expect(px(4, 840), rgb(StagePalette.fillWork));
      await t.tap(key('run-pause'));
      await t.pump(const Duration(milliseconds: 200));
      expect(r.timer.running, isFalse);
      expect(find.text('일시정지'), findsNWidgets(2), reason: 'the label');
      px = await pixels(t);
      expect(px(4, 840), rgb(StagePalette.paused));
      await t.tap(key('run-resume'));
      await t.pump(const Duration(milliseconds: 200));
      expect(r.timer.running, isTrue);
      await done(t, r);
    });

    testWidgets('ready is amber, rest is sky; last round gets the frame', (
      t,
    ) async {
      final r = Rig()..startAt(tabata, const Duration(milliseconds: 500));
      await mount(t, r);
      var px = await pixels(t);
      expect(px(4, 840), rgb(StagePalette.fillPrep));
      await advance(t, r, const Duration(seconds: 24)); // 24.5 s: rest
      px = await pixels(t);
      expect(px(4, 840), rgb(StagePalette.fillRest));
      expect(key('run-last-border'), findsNothing);
      r.now = const Duration(seconds: 3 + 30 * 7 + 5); // round 8 work
      await t.pump(const Duration(milliseconds: 200));
      expect(find.text('마지막 라운드'), findsNWidgets(2));
      expect(key('run-last-border'), findsOneWidget);
      await done(t, r);
    });

    testWidgets('the number layer and the flood stay within their budgets', (
      t,
    ) async {
      final r = Rig()
        ..startAt(
          const TimingSpec(tabata: true, bpm: 120),
          const Duration(seconds: 5),
        );
      await mount(t, r);
      final builds = runNumberBuilds, paints = floodPaints;
      for (var i = 0; i < 62; i++) {
        await advance(t, r, _ms * 16);
      }
      // One second: max(1, 120 / 60) + 2 builds, at most 12 flood paints.
      expect(runNumberBuilds - builds, lessThanOrEqualTo(4));
      expect(floodPaints - paints, lessThanOrEqualTo(12));
      await done(t, r);
    });

    test('dark ink on every fill is at least 4.5:1', () {
      for (final fill in [
        StagePalette.fillPrep,
        StagePalette.fillWork,
        StagePalette.fillRest,
      ]) {
        expect(contrast(StagePalette.onFill, fill), greaterThanOrEqualTo(4.5));
      }
      expect(
        contrast(StagePalette.text, StagePalette.bg),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(StagePalette.onFill, StagePalette.fillWork),
        closeTo(5.69, 0.05),
      );
    });
  });

  group('signals', () {
    testWidgets(
      'screen readers: one number label, the phase is a live region',
      (t) async {
        final h = t.ensureSemantics();
        final r = Rig()..startAt(tabata, const Duration(seconds: 13));
        await mount(t, r);
        expect(find.bySemanticsLabel('이번 구간 남은 시간 10초'), findsOneWidget);
        expect(find.bySemanticsLabel('10'), findsNothing);
        expect(
          t.getSemantics(find.bySemanticsLabel('운동, 1/8라운드')),
          isSemantics(isLiveRegion: true),
        );
        expect(find.bySemanticsLabel('접기, 타이머는 계속 돌아요'), findsOneWidget);
        h.dispose();
        await done(t, r);
      },
    );

    testWidgets('the end pulse flashes 3 s before the end, not when still', (
      t,
    ) async {
      for (final still in [false, true]) {
        // 4 s left in the first work interval (3 + 20 = 23).
        final r = Rig()..startAt(tabata, const Duration(seconds: 19));
        await mount(t, r, still: still);
        double alpha() => t.widget<ColoredBox>(key('run-end-pulse')).color.a;
        expect(alpha(), 0);
        await advance(t, r, const Duration(milliseconds: 1100));
        await t.pump(const Duration(milliseconds: 60));
        expect(alpha() > 0, !still, reason: 'still: $still');
        await done(t, r);
      }
    });

    testWidgets('metronome: 3·2·1, then the count pulses and stays on pause', (
      t,
    ) async {
      final r = Rig()
        ..startAt(
          const TimingSpec(bpm: 60),
          const Duration(milliseconds: 1500),
        );
      await mount(t, r);
      expect(find.text('2'), findsNWidgets(2));
      await advance(t, r, const Duration(seconds: 4)); // 5.5 s: count 3
      expect(find.text('3'), findsNWidgets(2));
      Color border() =>
          (t.widget<DecoratedBox>(key('beat-pulse-border')).decoration
                  as BoxDecoration)
              .border!
              .top
              .color;
      await advance(t, r, const Duration(milliseconds: 600)); // count 4
      await t.pump(const Duration(milliseconds: 20));
      expect(find.text('4'), findsNWidgets(2));
      expect(border().a, greaterThan(0.5));
      await t.tap(key('run-pause'));
      await t.pump(const Duration(seconds: 2));
      expect(find.text('4'), findsNWidgets(2), reason: 'the count is kept');
      expect(key('run-back'), findsNothing, reason: 'no skip for a metronome');
      await done(t, r);
    });
  });

  group('input', () {
    testWidgets(
      'taps on the number or the ground and vertical swipes do nothing',
      (t) async {
        final r = Rig()..startAt(tabata, const Duration(seconds: 5));
        await mount(t, r);
        await t.tap(key('run-number'), warnIfMissed: false);
        await t.tapAt(const Offset(200, 300));
        await t.tapAt(const Offset(8, 500));
        await t.dragFrom(const Offset(200, 400), const Offset(0, -300));
        await t.pump(const Duration(milliseconds: 300));
        expect(r.timer.running, isTrue);
        expect(r.timer.phase, TimingPhase.work);
        await done(t, r);
      },
    );

    testWidgets('a horizontal fling skips and goes back', (t) async {
      final r = Rig()..startAt(tabata, const Duration(seconds: 5));
      await mount(t, r);
      await t.flingFrom(const Offset(300, 400), const Offset(-250, 0), 1500);
      await t.pump(const Duration(milliseconds: 100));
      expect(r.timer.phase, TimingPhase.rest);
      await t.flingFrom(const Offset(100, 400), const Offset(250, 0), 1500);
      await t.pump(const Duration(milliseconds: 100));
      expect(r.timer.phase, TimingPhase.work);
      expect(r.timer.running, isTrue);
      await t.tap(key('run-next'));
      await t.pump();
      expect(r.timer.phase, TimingPhase.rest);
      await done(t, r);
    });

    testWidgets('hold to end: 0.5 s keeps running, 1.1 s shows the summary', (
      t,
    ) async {
      final r = Rig()..startAt(tabata, const Duration(seconds: 15));
      await mount(t, r);
      var g = await hold(t, key('run-hold-end'), _ms * 500);
      await g.up();
      await t.pump();
      expect(r.timer.running, isTrue);
      g = await hold(t, key('run-hold-end'), _ms * 1100);
      await g.up();
      await t.pump();
      expect(r.timer.endedEarly, isTrue);
      expect(find.text('여기까지 했어요'), findsOneWidget);
      await done(t, r);
    });

    testWidgets('an end under 10 s closes without a summary', (t) async {
      final r = Rig()..startAt(tabata, const Duration(seconds: 5));
      await mount(t, r);
      final g = await hold(t, key('run-hold-end'), _ms * 1100);
      await g.up();
      await sheet(t);
      expect(find.byType(RunPage), findsNothing);
      expect(r.timer.running, isFalse);
      expect(r.timer.elapsed, Duration.zero);
      await done(t, r);
    });

    testWidgets('lock: under 2 s nothing, then touches and back only nudge', (
      t,
    ) async {
      final r = Rig()..startAt(tabata, const Duration(seconds: 13));
      await mount(t, r);
      var g = await hold(t, key('run-lock'), _ms * 1500);
      await g.up();
      await t.pump();
      expect(find.text('자물쇠를 2초 눌러 풀어요'), findsNothing);
      g = await hold(t, key('run-lock'), _ms * 2100);
      await g.up();
      await t.pump();
      expect(find.text('자물쇠를 2초 눌러 풀어요'), findsOneWidget);
      double ground() => t.widget<Opacity>(key('run-hold-ground')).opacity;
      expect(ground(), 0.35);
      // The pause bar, the end hold and swipes are swallowed.
      await t.tap(key('run-pause'), warnIfMissed: false);
      await t.pump();
      expect(r.timer.running, isTrue);
      expect(ground(), 0.7, reason: 'a swallowed touch brightens the hint');
      await t.pump(const Duration(milliseconds: 400));
      expect(ground(), 0.35);
      g = await hold(t, key('run-hold-end'), _ms * 1100);
      await g.up();
      await t.pump();
      expect(r.timer.endedEarly, isFalse);
      // Android back: no collapse, a nudge.
      await t.binding.handlePopRoute();
      await t.pump();
      expect(find.byType(RunPage), findsOneWidget);
      expect(ground(), 0.7);
      await t.pump(const Duration(milliseconds: 400));
      // Unlock, and back collapses again.
      g = await hold(t, key('run-lock'), _ms * 2100);
      await g.up();
      await t.pump();
      expect(find.text('자물쇠를 2초 눌러 풀어요'), findsNothing);
      await t.binding.handlePopRoute();
      await sheet(t);
      expect(find.byType(RunPage), findsNothing);
      expect(r.timer.running, isTrue);
      await done(t, r);
    });

    testWidgets('paused while locked: the end slot says how to unlock', (
      t,
    ) async {
      final r = Rig()..startAt(tabata, const Duration(seconds: 13));
      await mount(t, r);
      final g = await hold(t, key('run-lock'), _ms * 2100);
      await g.up();
      await t.pump();
      r.timer.pause(); // a call
      await t.pump();
      expect(key('run-resume'), findsOneWidget);
      expect(find.text('자물쇠를 2초 눌러 풀어요'), findsOneWidget);
      double ground() => t.widget<Opacity>(key('run-hold-ground')).opacity;
      expect(ground(), 0.35);
      await t.tap(key('run-resume'), warnIfMissed: false);
      await t.pump();
      expect(r.timer.running, isFalse);
      expect(ground(), 0.7, reason: 'a swallowed touch brightens the hint');
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(key('run-end'), warnIfMissed: false);
      await t.pump();
      expect(r.timer.endedEarly, isFalse);
      expect(ground(), 0.7);
      await t.pump(const Duration(milliseconds: 400));
      await t.binding.handlePopRoute();
      await t.pump();
      expect(find.byType(RunPage), findsOneWidget);
      expect(ground(), 0.7);
      await t.pump(const Duration(milliseconds: 400));
      await done(t, r);
    });

    testWidgets('finished while locked: [again] starts unlocked', (t) async {
      final r = Rig()..startAt(tabata, const Duration(seconds: 5));
      await mount(t, r);
      final g = await hold(t, key('run-lock'), _ms * 2100);
      await g.up();
      await t.pump();
      await advance(t, r, const Duration(seconds: 300));
      expect(r.timer.phase, TimingPhase.complete);
      await t.tap(key('run-again'));
      await t.pump();
      expect(r.timer.running, isTrue);
      expect(find.text('자물쇠를 2초 눌러 풀어요'), findsNothing);
      await t.tap(key('run-pause'));
      await t.pump();
      expect(r.timer.running, isFalse);
      await done(t, r);
    });

    testWidgets('opened again while folding: portrait stays held', (t) async {
      final calls = <Object?>[];
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (c) async {
          if (c.method == 'SystemChrome.setPreferredOrientations') {
            calls.add(c.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final r = Rig()..startAt(tabata, const Duration(seconds: 13));
      await mount(t, r);
      await t.tap(key('run-collapse'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100)); // still folding
      await t.tap(key('open'));
      await sheet(t);
      expect(find.byType(RunPage), findsOneWidget);
      expect(calls.last, ['DeviceOrientation.portraitUp']);
      await t.tap(key('run-collapse'));
      await sheet(t);
      expect(find.byType(RunPage), findsNothing);
      expect(calls.last, isEmpty);
      await done(t, r);
    });

    testWidgets('collapse pops, the timer keeps running; portrait is held', (
      t,
    ) async {
      final calls = <Object?>[];
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (c) async {
          if (c.method == 'SystemChrome.setPreferredOrientations') {
            calls.add(c.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final r = Rig()..startAt(tabata, const Duration(seconds: 13));
      await mount(t, r);
      expect(calls, [
        ['DeviceOrientation.portraitUp'],
      ]);
      expect(find.text('접기'), findsOneWidget);
      await t.tap(key('run-collapse'));
      await sheet(t);
      expect(find.byType(RunPage), findsNothing);
      expect(r.timer.running, isTrue);
      expect(calls.last, isEmpty);
      await done(t, r);
    });
  });

  group('logging', () {
    testWidgets('rest log: − n + [log] → onLogRound(round, n)', (t) async {
      final r = Rig()..startAt(tabata, const Duration(seconds: 13));
      r.link.lastReps = 12;
      await mount(t, r);
      expect(
        key('together-log'),
        findsNothing,
        reason: 'nothing to log in work',
      );
      await advance(t, r, const Duration(seconds: 12)); // 25 s: rest of round 1
      expect(t.widget<Text>(key('together-count')).data, '12');
      await t.tap(key('run-plus'));
      await t.pump();
      await t.tap(key('together-log'));
      await t.pump();
      expect(r.rounds, [(1, 13)]);
      expect(r.link.roundReps, [13]);
      expect(key('together-log'), findsNothing);
      expect(find.text('13회 적었어요'), findsNWidgets(2));
      // Round 2's rest starts from this run's last.
      await advance(t, r, const Duration(seconds: 30));
      expect(t.widget<Text>(key('together-count')).data, '13');
      await done(t, r);
    });

    testWidgets(
      'summary: the main button logs only the rounds not logged yet',
      (t) async {
        const spec = TimingSpec(tabata: true, rounds: 3);
        final r = Rig()..startAt(spec, const Duration(seconds: 70));
        r.link.roundReps.addAll([null, 12]);
        await mount(t, r);
        await advance(t, r, const Duration(seconds: 14)); // 84 s > 83 s
        expect(r.timer.phase, TimingPhase.complete);
        expect(find.text('끝!'), findsOneWidget);
        expect(t.widget<Text>(key('run-summary-hero')).data, '3라운드');
        expect(find.text('2세트 적기'), findsOneWidget);
        expect(find.text('1R –'), findsOneWidget);
        expect(find.text('2R 12'), findsOneWidget);
        // Round 1: 12 (this run's last) + 1.
        await t.tap(key('run-round-1'));
        await sheet(t);
        await t.tap(key('count-sheet-plus'));
        await t.pump();
        await t.tap(key('count-sheet-done'));
        await sheet(t);
        expect(find.text('1R 13'), findsOneWidget);
        expect(r.rounds, isEmpty, reason: 'a draft until the button');
        await t.tap(key('run-log'));
        await sheet(t);
        expect(r.rounds, [(1, 13), (3, null)]);
        expect(r.logged, 1);
        expect(r.link.logged, isTrue);
        expect(find.byType(RunPage), findsNothing);
        await done(t, r);
      },
    );

    testWidgets('summary: fixing a logged round logs it at once; fill rest', (
      t,
    ) async {
      const spec = TimingSpec(tabata: true, rounds: 3);
      final r = Rig()..startAt(spec, const Duration(seconds: 84));
      r.link.roundReps.addAll([10]);
      await mount(t, r);
      await t.tap(key('run-round-1'));
      await sheet(t);
      expect(key('count-sheet-fill'), findsNothing);
      await t.tap(key('count-sheet-minus'));
      await t.pump();
      await t.tap(key('count-sheet-done'));
      await sheet(t);
      expect(r.rounds, [(1, 9)]);
      await t.tap(key('run-round-2'));
      await sheet(t);
      await t.tap(key('count-sheet-fill'));
      await sheet(t);
      expect(find.text('3R 9'), findsOneWidget);
      await t.tap(key('run-log'));
      await sheet(t);
      expect(r.rounds, [(1, 9), (2, 9), (3, 9)]);
      await done(t, r);
    });

    testWidgets('metronome summary logs the count as one set', (t) async {
      final r = Rig()
        ..startAt(
          const TimingSpec(bpm: 60),
          const Duration(seconds: 5),
          target: 5,
        );
      await mount(t, r);
      expect(find.text('/ 5회'), findsNWidgets(2));
      await advance(t, r, const Duration(seconds: 3)); // 8 s > 7.55 s
      expect(t.widget<Text>(key('run-summary-hero')).data, '5회');
      await t.tap(key('run-log'));
      await sheet(t);
      expect(r.counts, [5]);
      expect(r.logged, 1);
      await done(t, r);
    });

    testWidgets('again restarts from the top and forgets this run', (t) async {
      final r = Rig()..startAt(tabata, const Duration(seconds: 300));
      r.link.roundReps.add(10);
      r.link.drafts[2] = 12;
      await mount(t, r);
      expect(r.link.flashed, isTrue);
      await t.tap(key('run-again'));
      await t.pump();
      expect(r.timer.running, isTrue);
      expect(r.timer.phase, TimingPhase.ready);
      expect(r.link.roundReps, isEmpty);
      expect(r.link.drafts, isEmpty);
      expect(r.link.flashed, isFalse);
      await done(t, r);
    });

    testWidgets(
      'folding the summary keeps the picked counts; no second flash',
      (t) async {
        const spec = TimingSpec(tabata: true, rounds: 3);
        final r = Rig()..startAt(spec, const Duration(seconds: 84));
        await mount(t, r);
        await t.tap(key('run-round-1'));
        await sheet(t);
        await t.tap(key('count-sheet-plus'));
        await t.pump();
        await t.tap(key('count-sheet-done'));
        await sheet(t);
        expect(find.text('1R 11'), findsOneWidget);
        await t.tap(key('run-summary-close'));
        await sheet(t);
        expect(find.byType(RunPage), findsNothing);
        expect(r.rounds, isEmpty);
        await t.tap(key('open'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 50));
        final glow = t
            .widgetList<ColoredBox>(find.byType(ColoredBox))
            .where((b) => b.color.toARGB32() & 0xFFFFFF == 0xFFFFFF);
        expect(glow.map((b) => b.color.a), everyElement(0), reason: 'no flash');
        await sheet(t);
        expect(find.text('1R 11'), findsOneWidget);
        expect(find.text('3세트 적기'), findsOneWidget);
        await t.tap(key('run-log'));
        await sheet(t);
        expect(r.rounds, [(1, 11), (2, null), (3, null)]);
        await done(t, r);
      },
    );
  });

  group('together', () {
    TogetherTiming duo({
      bool left = false,
      List<int?> mine = const [],
      List<int?> theirs = const [],
      List<({String name, List<int?> counts})> more = const [],
      String? gone,
    }) => TogetherTiming(
      partner: '미나',
      live: true,
      left: left,
      mine: mine,
      theirs: theirs,
      more: more,
      partnerLeft: gone,
      onPropose: (_) {},
      onCancel: () {},
    );

    testWidgets('no skip, hold to leave, then rejoin', (t) async {
      final r = Rig();
      r.timer.follow(r.owner, tabata, const Duration(seconds: 10));
      r.link.together = duo();
      await mount(t, r);
      expect(key('run-back'), findsNothing);
      expect(key('run-next'), findsNothing);
      expect(find.text('길게 눌러 그만'), findsOneWidget);
      expect(find.text('미나 님과 같이'), findsNWidgets(2));
      // Where the partner stopped replaces "with Mina" while working.
      r.link
        ..together = duo(gone: '미나 님은 3라운드에서 멈춤')
        ..changed();
      await t.pump();
      expect(find.text('미나 님은 3라운드에서 멈춤'), findsNWidgets(2));
      final g = await hold(t, key('run-hold-end'), _ms * 1100);
      await g.up();
      await t.pump();
      expect(r.leaves, 1);
      expect(r.timer.endedEarly, isFalse);
      expect(r.timer.running, isTrue, reason: 'leaving is the editor’s job');
      // The editor leaves (pause + leaveTimer) and says so.
      r.timer.pause();
      r.link
        ..together = duo(left: true)
        ..changed();
      await t.pump();
      expect(key('run-restart'), findsNothing);
      await t.tap(key('run-rejoin'));
      expect(r.rejoins, 1);
      await done(t, r);
    });

    testWidgets('paused together: no restart, end is leave', (t) async {
      final r = Rig();
      r.timer.follow(r.owner, tabata, const Duration(seconds: 10));
      r.link.together = duo();
      await mount(t, r);
      await t.tap(key('run-pause'));
      await t.pump();
      expect(key('run-restart'), findsNothing);
      await t.tap(key('run-end'));
      expect(r.leaves, 1);
      await done(t, r);
    });

    testWidgets('rest log together starts from the last numbers', (t) async {
      final r = Rig();
      r.timer.follow(r.owner, tabata, const Duration(seconds: 25));
      r.link.together = duo(theirs: const [14, null, 9]);
      await mount(t, r);
      expect(t.widget<Text>(key('together-count')).data, '9');
      await t.tap(key('together-log'));
      expect(r.rounds, [(1, 9)]);
      await done(t, r);
    });

    testWidgets('this run decides what is logged, not the sets on the card', (
      t,
    ) async {
      // Two sets of mine from before this run: round 1 is still owed.
      final r = Rig();
      r.timer.follow(r.owner, tabata, const Duration(seconds: 25));
      r.link.together = duo(mine: const [10, 10]);
      await mount(t, r);
      expect(r.timer.phase, TimingPhase.rest);
      expect(key('together-log'), findsOneWidget);
      expect(find.textContaining('적었어요'), findsNothing);
      await done(t, r);
    });

    testWidgets('a skipped round is not borrowed from the next one', (t) async {
      const spec = TimingSpec(tabata: true, rounds: 3);
      final r = Rig();
      r.timer.follow(r.owner, spec, const Duration(seconds: 84));
      r.link.roundReps.addAll([10, null, 11]);
      r.link.together = duo(mine: const [10, 11], theirs: const [9, 9, 9]);
      await mount(t, r);
      expect(r.timer.phase, TimingPhase.complete);
      expect(find.text('1R 10'), findsOneWidget);
      expect(find.text('2R –'), findsOneWidget);
      expect(find.text('3R 11'), findsOneWidget);
      expect(find.text('1세트 적기'), findsOneWidget);
      expect(find.text('10  –  11'), findsOneWidget, reason: 'my row by round');
      await t.tap(key('run-log'));
      await sheet(t);
      expect(r.rounds, [(2, null)]);
      await done(t, r);
    });

    testWidgets('the summary has one row per person', (t) async {
      const spec = TimingSpec(tabata: true, rounds: 2);
      final r = Rig();
      r.timer.follow(r.owner, spec, const Duration(seconds: 52));
      r.link.roundReps.add(12);
      r.link.together = duo(
        // Every set of mine on the card, older runs too: not this table.
        mine: const [8, 12],
        theirs: const [14, 13],
        more: const [(name: '소라', counts: <int?>[])],
        gone: '소라 님은 1라운드에서 멈춤',
      );
      await mount(t, r);
      await advance(t, r, const Duration(seconds: 2));
      expect(r.timer.phase, TimingPhase.complete);
      expect(key('run-people'), findsOneWidget);
      expect(find.text('12  –'), findsOneWidget);
      expect(find.text('14  13'), findsOneWidget);
      expect(find.text('소라'), findsOneWidget);
      expect(find.text('–  –'), findsOneWidget, reason: '소라 logged nothing');
      expect(find.text('소라 님은 1라운드에서 멈춤'), findsOneWidget);
      expect(key('run-again'), findsNothing);
      await done(t, r);
    });
  });

  testWidgets('no overflow: 3 phones x 1.0/1.5/2.0 x ko, en, th, es, vi', (
    t,
  ) async {
    const spec = TimingSpec(tabata: true, bpm: 60);
    for (final size in const [Size(320, 568), Size(375, 667), phone]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        for (final lang in const ['ko', 'en', 'th', 'es', 'vi']) {
          final why = '$size x$scale $lang';
          final r = Rig()..startAt(spec, const Duration(seconds: 5));
          r.link.weightLabel = '16kg';
          await mount(t, r, size: size, scale: scale, lang: lang);
          expect(t.takeException(), isNull, reason: '$why work');
          await advance(t, r, const Duration(seconds: 20)); // rest + log
          expect(key('together-log'), findsOneWidget, reason: why);
          expect(t.takeException(), isNull, reason: '$why rest');
          await t.tap(key('run-pause'));
          await t.pump();
          expect(t.takeException(), isNull, reason: '$why paused');
          r.timer.resume();
          await advance(t, r, const Duration(seconds: 300));
          expect(r.timer.phase, TimingPhase.complete, reason: why);
          expect(t.takeException(), isNull, reason: '$why summary');
          await done(t, r);
        }
      }
    }
  });

  testWidgets('opened paused mid-interval: the number above the water is '
      'repainted light once the page has slid in', (t) async {
    final r = Rig();
    r.startAt(tabata, const Duration(seconds: 13)); // 10 s into the work
    r.timer.pause();
    await mount(t, r);
    await t.pump(const Duration(milliseconds: 600));
    final level = r.timer.level;
    expect(level, inExclusiveRange(0.2, 0.8));
    final line = 852 - 852 * level;
    final rect = t.getRect(key('run-number'));
    expect(rect.top, lessThan(line));
    final px = await pixels(t);
    var light = 0;
    for (
      var y = rect.top.ceil();
      y < math.min(line, rect.bottom).floor();
      y++
    ) {
      for (var x = rect.left.ceil(); x < rect.right.floor(); x++) {
        if (px(x, y) == rgb(StagePalette.text)) light++;
      }
    }
    expect(light, greaterThan(100));
    await done(t, r);
  });
}
