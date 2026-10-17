import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'l10n/generated/app_localizations.dart';
import 'run_link.dart';
import 'stage_palette.dart';
import 'workout_timing.dart';

// The full-screen run stage (spec 1.8 §6), ported from Tempo's run page:
// the flood ("수위"), the two-faced text, the end pulse, the last-round
// border, the pause bar, hold to end, hold to lock, the beat pulse and the
// summary. Data comes only from [RunLink] and its [WorkoutTimer].

typedef _P = StagePalette;

const _tnum = [FontFeature.tabularFigures()];
const _title1 = TextStyle(
  fontSize: 32,
  height: 40 / 32,
  fontWeight: FontWeight.w700,
);
const _title3 = TextStyle(
  fontSize: 20,
  height: 28 / 20,
  fontWeight: FontWeight.w600,
);
const _label = TextStyle(
  fontSize: 16,
  height: 22 / 16,
  fontWeight: FontWeight.w600,
);
const _labelTnum = TextStyle(
  fontSize: 16,
  height: 22 / 16,
  fontWeight: FontWeight.w600,
  fontFeatures: _tnum,
);
const _small = TextStyle(fontSize: 15, height: 20 / 15);

/// "1:30" (seconds, already rounded by the caller).
String _clock(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// The big number: "27" under a minute, "1:30" from there.
String _big(int s) => s < 60 ? '$s' : _clock(s);

/// A time for screen readers: "27초", "1분 30초".
String _spoken(L l, int s) =>
    s < 60 ? l.timerSecondsValue(s) : l.routineMinSec(s ~/ 60, s % 60);

int _ceilSeconds(Duration d) => (d.inMilliseconds / 1000).ceil();

/// Hold to end (spec §6.4).
const kHoldToEnd = Duration(seconds: 1);

/// Hold to lock or unlock: twice the end hold, so pocket pressure that fills
/// the end hold cannot also unlock.
const kHoldToLock = Duration(seconds: 2);

/// Horizontal fling speed that skips (logical px/s).
const _swipeVelocity = 300.0;

/// How often the number layer was built (tests bound it per second).
@visibleForTesting
int runNumberBuilds = 0;

/// How often the flood was painted (tests bound it per second).
@visibleForTesting
int floodPaints = 0;

/// Level of the fill (0..1) and its color, read from the engine.
typedef StageWater = ({double level, Color fill});

/// Screen y of the waterline, whole pixels so the fill and the clip of the
/// dark faces meet exactly. The status bar strip above [top] stays empty.
double _waterLine(double h, double top, double level) =>
    (h - (h - top) * level).roundToDouble();

/// The status bar height of the view: the content sits inside a SafeArea,
/// which zeroes MediaQuery.padding below it.
double _statusTop(BuildContext context) =>
    MediaQueryData.fromView(View.of(context)).padding.top;

/// Full-screen run stage. Collapsing it leaves the timer running.
class RunPage extends StatefulWidget {
  const RunPage({super.key, required this.link});
  final RunLink link;

  /// Pushes the stage as a full-screen dialog (no iOS edge swipe).
  static Future<void> open(BuildContext context, RunLink link) =>
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => RunPage(link: link),
        ),
      );

  @override
  State<RunPage> createState() => _RunPageState();
}

/// Portrait while any full-screen stage (timer or set stage) is alive.
/// Opened again while the last one is still folding away, the old one's
/// [leave] must not let go of portrait under the new one.
abstract final class StagePortrait {
  static int _open = 0;

  /// In a stage's initState.
  static void enter() {
    _open++;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  /// In a stage's dispose.
  static void leave() {
    if (--_open == 0) SystemChrome.setPreferredOrientations([]);
  }
}

/// Labels on the stages stop growing at this text scale; the big number
/// ignores the OS scale.
const kStageMaxTextScale = 1.5;

class _RunPageState extends State<RunPage> {
  late final _water = StageWaterLevel(_read());
  Animation<double>? _routeIn;
  Timer? _clockTimer;
  bool? _still;
  bool _locked = false;
  int _nudge = 0;
  bool _gone = false;

  RunLink get _link => widget.link;
  WorkoutTimer get _timer => widget.link.timer;

  @override
  void initState() {
    super.initState();
    StagePortrait.enter();
    _timer.addListener(_sync);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The dark faces are clipped at the waterline in screen space; a level
    // that does not move (paused) never repaints them, so the clip painted
    // while the page slid in would stay. Paint again once it has arrived.
    final routeIn = ModalRoute.of(context)?.animation;
    if (!identical(routeIn, _routeIn)) {
      _routeIn?.removeStatusListener(_arrived);
      _routeIn = routeIn?..addStatusListener(_arrived);
    }
    // The flood reads the level on its own clock, not on engine notifies.
    // Reduce motion: once a second.
    final still = MediaQuery.disableAnimationsOf(context);
    if (still == _still) return;
    _still = still;
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(
      Duration(milliseconds: still ? 1000 : 100),
      (_) => _sync(),
    );
  }

  void _arrived(AnimationStatus s) {
    if (s.isCompleted) _water.repaint();
  }

  @override
  void dispose() {
    _routeIn?.removeStatusListener(_arrived);
    _clockTimer?.cancel();
    _timer.removeListener(_sync);
    _water.dispose();
    StagePortrait.leave();
    super.dispose();
  }

  StageWater _read() {
    final t = _timer;
    final fill = !t.running
        ? _P.paused
        : switch (t.phase) {
            TimingPhase.ready => _P.fillPrep,
            TimingPhase.rest => _P.fillRest,
            _ => _P.fillWork,
          };
    return (level: t.spec == null ? 0 : t.level, fill: fill);
  }

  void _sync() => _water.value = _read();

  bool get _over =>
      _timer.endedEarly ||
      (_timer.spec != null && _timer.phase == TimingPhase.complete);

  /// Closes the stage; the timer keeps going.
  void _close() {
    if (_gone || !mounted) return;
    // The editor may have closed it already (onLogged).
    if (ModalRoute.of(context)?.isCurrent == false) return;
    _gone = true;
    Navigator.of(context).pop();
  }

  void _toggleLock() {
    final l = L.of(context);
    setState(() => _locked = !_locked);
    if (_timer.haptics) unawaited(HapticFeedback.mediumImpact());
    SemanticsService.sendAnnouncement(
      View.of(context),
      _locked ? l.timerLockedAnnounce : l.timerUnlockedAnnounce,
      Directionality.of(context),
    );
  }

  /// A touch the lock swallowed: the end button says how to unlock. No
  /// haptic — a pocket must not keep buzzing.
  void _nudgeLock() {
    if (_locked) setState(() => _nudge++);
  }

  void _swipe(DragEndDetails d) {
    if (_locked) return _nudgeLock();
    final v = d.primaryVelocity ?? 0;
    if (v <= -_swipeVelocity) {
      _timer.skip();
    } else if (v >= _swipeVelocity) {
      _timer.back();
    }
  }

  /// Hold to end / tap to end while paused. Together it is "leave". Under
  /// 10 s the engine resets and the stage closes without a summary.
  void _end() {
    if (_timer.shared) {
      _link.onLeave?.call();
      return;
    }
    _timer.end();
    if (!_over) _close();
  }

  /// A new run: the link forgets this one's log by itself (runId). A lock
  /// from the run before does not carry over — the summary showed it open.
  void _restart() {
    if (_locked) setState(() => _locked = false);
    _timer.restart();
  }

  @override
  Widget build(BuildContext context) {
    final link = _link;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: _P.bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      // Every label row stops at 1.5x; the number ignores the OS scale.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: kStageMaxTextScale,
        child: CupertinoTheme(
          data: const CupertinoThemeData(
            brightness: Brightness.dark,
            primaryColor: _P.text,
            scaffoldBackgroundColor: _P.bg,
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: _P.text),
            child: ListenableBuilder(
              listenable: Listenable.merge([_timer, link, ?link.recovery]),
              builder: (context, _) {
                final over = _over;
                final locked = _locked && !over;
                Widget child;
                if (_timer.spec == null) {
                  // The timer was cleared under the stage (another block).
                  WidgetsBinding.instance.addPostFrameCallback((_) => _close());
                  child = const SizedBox.expand();
                } else if (over) {
                  child = SafeArea(
                    child: _Summary(
                      link: link,
                      onClose: _close,
                      onAgain: _restart,
                    ),
                  );
                } else {
                  child = _stage(context, locked);
                }
                return PopScope(
                  // Android back collapses; locked, it only nudges.
                  canPop: !locked,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop) _nudgeLock();
                  },
                  child: ColoredBox(color: _P.bg, child: child),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _stage(BuildContext context, bool locked) {
    final t = _timer, s = t.spec!;
    final lastRound =
        t.running &&
        s.tabata &&
        s.rounds > 1 &&
        t.phase == TimingPhase.work &&
        t.round == s.rounds;
    return StageWaterScope(
      water: _water,
      child: Stack(
        fit: StackFit.expand,
        children: [
          StageFlood(water: _water),
          StageEndPulse(listenable: t, beat: () => _endBeat(t)),
          SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              // The « » buttons carry the screen reader actions.
              excludeFromSemantics: true,
              onHorizontalDragEnd: _swipe,
              child: _body(context, locked),
            ),
          ),
          if (lastRound)
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  key: ValueKey('run-last-border'),
                  decoration: BoxDecoration(
                    border: Border.fromBorderSide(
                      BorderSide(color: _P.text, width: 6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, bool locked) {
    final l = L.of(context);
    final t = _timer, s = t.spec!, link = _link;
    final duo = t.shared ? link.together : null;
    final phase = t.phase, round = t.round;
    final short = MediaQuery.sizeOf(context).height < 700;
    final paused = !t.running;
    final theirTurn =
        duo != null &&
        duo.alternate &&
        t.running &&
        (phase == TimingPhase.rest ||
            (phase == TimingPhase.ready && t.remaining > 3));
    final label = paused
        ? l.timerPaused
        : theirTurn
        ? l.togetherTheirTurn
        : switch (phase) {
            TimingPhase.ready => l.timingReady,
            TimingPhase.work
                when s.tabata && s.rounds > 1 && round == s.rounds =>
              l.timerLastRound,
            TimingPhase.work => l.timingWork,
            TimingPhase.rest => l.timingRest,
            TimingPhase.complete => l.timingComplete,
          };
    final side = s.tabata
        ? (phase == TimingPhase.ready
              ? null
              : l.timerRoundShort(round, s.rounds))
        : l.timingBpm(s.bpm!);
    final a11y = [
      label,
      if (s.tabata && phase != TimingPhase.ready)
        l.timingRound(round, s.rounds),
    ].join(', ');

    // Extra lines under the info row.
    final heart = link.recovery;
    final showHeart =
        heart != null &&
        s.tabata &&
        phase == TimingPhase.rest &&
        heart.fresh &&
        heart.bpm != null &&
        heart.target != null;
    final together = duo == null
        ? null
        : duo.partnerLeft ?? (duo.live ? l.togetherWith(duo.partner) : null);
    final logged = _roundLogged(link, round);
    final restLog =
        s.tabata &&
        phase == TimingPhase.rest &&
        !(duo?.left ?? false) &&
        link.onLogRound != null;

    Widget line(String text, TextStyle style, {bool sub = true}) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: StageFaces(
        builder: (ink) => Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(color: sub ? ink.sub : ink.main),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Top(
          title: [
            link.title,
            ?link.weightLabel,
          ].where((e) => e.isNotEmpty).join(' · '),
          label: label,
          side: side,
          a11y: a11y,
          collapse: StageGate(
            locked: locked,
            label: l.timerCollapseA11y,
            onBlocked: _nudgeLock,
            child: StageCollapseButton(onTap: _close),
          ),
        ),
        SizedBox(height: short ? 4 : 8),
        Expanded(child: _Number(timer: t)),
        _Info(timer: t),
        if (showHeart)
          line(l.timingHeart(heart.bpm!, heart.target!), _title3, sub: false),
        if (showHeart && link.heartShared)
          line(l.timerHeartShared, const TextStyle(fontSize: 13)),
        if (together != null) line(together, _small),
        if (t.soundFailed)
          line(l.timingSoundFailed, const TextStyle(fontSize: 13)),
        if (restLog && logged != null)
          line(l.timerLogged(logged), _title3, sub: false)
        else if (restLog)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: StageGate(
              locked: locked,
              label: l.timerRestLog,
              onBlocked: _nudgeLock,
              child: _RestLog(
                // A new round counts afresh.
                key: ValueKey('together-count-$round'),
                initial: _restDefault(link),
                onLog: (n) => _logRound(link, round, n),
              ),
            ),
          ),
        SizedBox(height: short ? 8 : 16),
        _controls(l, paused: paused, locked: locked, duo: duo),
        SizedBox(height: short ? 12 : 24),
      ],
    );
  }

  Widget _controls(
    L l, {
    required bool paused,
    required bool locked,
    required TogetherTiming? duo,
  }) {
    final t = _timer;
    final canSkip = t.canSkip;
    Widget gate(String label, Widget child) => StageGate(
      locked: locked,
      label: label,
      onBlocked: _nudgeLock,
      child: child,
    );
    final back = gate(
      l.timerSkipBack,
      StageRoundButton(
        key: const ValueKey('run-back'),
        icon: CupertinoIcons.backward_end_fill,
        label: l.timerSkipBack,
        onTap: t.back,
      ),
    );
    final next = gate(
      l.timerSkipNext,
      StageRoundButton(
        key: const ValueKey('run-next'),
        icon: CupertinoIcons.forward_end_fill,
        label: l.timerSkipNext,
        onTap: t.skip,
      ),
    );
    final lock = StageLockButton(
      key: const ValueKey('run-lock'),
      locked: locked,
      onToggle: _toggleLock,
    );
    Widget bar(Widget main) => Row(
      children: [
        if (canSkip) ...[back, const SizedBox(width: 12)],
        Expanded(child: main),
        if (canSkip) ...[const SizedBox(width: 12), next],
      ],
    );
    final List<Widget> rows;
    if (duo != null && duo.left) {
      // Left a shared timer: come back in, or close.
      rows = [
        Row(
          children: [
            Expanded(
              child: StageButton(
                key: const ValueKey('run-rejoin'),
                label: l.togetherRejoin,
                primary: true,
                onTap: _link.onRejoin,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StageButton(
                key: const ValueKey('run-close'),
                label: l.timerClose,
                onTap: _close,
              ),
            ),
          ],
        ),
      ];
    } else if (!paused) {
      rows = [
        bar(
          gate(
            l.timingPause,
            StageBar(
              key: const ValueKey('run-pause'),
              icon: CupertinoIcons.pause_fill,
              label: l.timingPause,
              onTap: t.pause,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            lock,
            const SizedBox(width: 12),
            Expanded(
              child: _HoldToEnd(
                key: const ValueKey('run-hold-end'),
                label: t.shared ? l.timerHoldLeave : l.timerHoldEnd,
                a11y: t.shared ? l.togetherLeave : l.timerEnd,
                lockedLabel: l.timerLockedHint,
                locked: locked,
                nudge: _nudge,
                onBlocked: _nudgeLock,
                onEnd: _end,
              ),
            ),
          ],
        ),
      ];
    } else {
      rows = [
        bar(
          gate(
            l.timerResume,
            StageBar(
              key: const ValueKey('run-resume'),
              icon: CupertinoIcons.play_fill,
              label: l.timerResume,
              onTap: t.resume,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Paused by a call while locked: the way out must stay.
            if (locked) ...[lock, const SizedBox(width: 12)],
            if (!t.shared) ...[
              Expanded(
                child: gate(
                  l.timerRestart,
                  StageButton(
                    key: const ValueKey('run-restart'),
                    label: l.timerRestart,
                    onTap: _restart,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              // Locked, the end says how to unlock and lights up on a touch,
              // as it does while running.
              child: locked
                  ? _HoldToEnd(
                      key: const ValueKey('run-end'),
                      label: t.shared ? l.togetherLeave : l.timerEnd,
                      a11y: t.shared ? l.togetherLeave : l.timerEnd,
                      lockedLabel: l.timerLockedHint,
                      locked: true,
                      nudge: _nudge,
                      onBlocked: _nudgeLock,
                      onEnd: _end,
                    )
                  : StageButton(
                      key: const ValueKey('run-end'),
                      label: t.shared ? l.togetherLeave : l.timerEnd,
                      onTap: _end,
                    ),
            ),
          ],
        ),
      ];
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// Reps logged for [round] (1-based) in this run; null when not logged.
/// Only this run's log counts — not the sets already on the card, not a
/// shared table (those are in set order, not round order).
int? _roundLogged(RunLink link, int round) =>
    round <= link.roundReps.length ? link.roundReps[round - 1] : null;

/// Rest log start: this run's last, the block's last set, then 10.
int _restDefault(RunLink link) =>
    link.roundReps.whereType<int>().lastOrNull ??
    link.lastReps ??
    link.together?.mine.whereType<int>().lastOrNull ??
    link.together?.theirs.whereType<int>().lastOrNull ??
    10;

/// Writes one round (1-based) into this run and hands it to the editor.
/// Null reps is a set without a count ('–'), not a clear.
void _logRound(RunLink link, int round, int? reps) {
  while (link.roundReps.length < round) {
    link.roundReps.add(null);
  }
  link.roundReps[round - 1] = reps;
  link.onLogRound?.call(round, reps);
  link.changed();
}

/// Takes a logged round's set away again: the round is owed once more.
void _clearRound(RunLink link, int round) {
  if (round <= link.roundReps.length) link.roundReps[round - 1] = null;
  link.onClearRound?.call(round);
  link.changed();
}

// ---- Flood ("수위") and the two faces of text over it.

/// The flood level; [repaint] tells the flood and the clips to paint again
/// at an unchanged level (the clips were painted while the page slid in).
class StageWaterLevel extends ChangeNotifier
    implements ValueListenable<StageWater> {
  StageWaterLevel(this._value);
  StageWater _value;

  @override
  StageWater get value => _value;
  set value(StageWater v) {
    if (v == _value) return;
    _value = v;
    notifyListeners();
  }

  void repaint() => notifyListeners();
}

class StageWaterScope extends InheritedWidget {
  const StageWaterScope({super.key, required this.water, required super.child});
  final ValueListenable<StageWater> water;

  static ValueListenable<StageWater> of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StageWaterScope>()!.water;

  @override
  bool updateShouldNotify(StageWaterScope old) => water != old.water;
}

/// Full-screen fill from the bottom. Repaints on the level alone.
class StageFlood extends StatelessWidget {
  const StageFlood({super.key, required this.water});
  final ValueListenable<StageWater> water;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      key: const ValueKey('run-flood'),
      painter: _FloodPainter(water, _statusTop(context)),
      child: const SizedBox.expand(),
    ),
  );
}

class _FloodPainter extends CustomPainter {
  _FloodPainter(this.water, this.top) : super(repaint: water);
  final ValueListenable<StageWater> water;
  final double top;

  @override
  void paint(Canvas canvas, Size size) {
    floodPaints++;
    final w = water.value;
    final line = _waterLine(size.height, top, w.level);
    if (line >= size.height) return;
    canvas.drawRect(
      Rect.fromLTRB(0, line, size.width, size.height),
      Paint()..color = w.fill,
    );
  }

  @override
  bool shouldRepaint(_FloodPainter old) => old.water != water || old.top != top;
}

/// Ink of one face: light on the empty part, dark on the fill.
class StageInk {
  const StageInk(this.main, this.sub, {required this.first});
  final Color main, sub;

  /// The face screen readers and keyed test finders see.
  final bool first;
}

const _onEmpty = StageInk(_P.text, _P.textSecondary, first: true);
const _onFill = StageInk(_P.onFill, _P.onFill, first: false);

/// [builder] drawn twice with the same layout: the dark face is clipped to
/// the fill, so a glyph on the waterline changes color half-way.
class StageFaces extends StatelessWidget {
  const StageFaces({super.key, required this.builder});
  final Widget Function(StageInk ink) builder;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      builder(_onEmpty),
      StageFloodClip(
        water: StageWaterScope.of(context),
        child: ExcludeSemantics(child: builder(_onFill)),
      ),
    ],
  );
}

class StageFloodClip extends SingleChildRenderObjectWidget {
  const StageFloodClip({super.key, required this.water, required super.child});
  final ValueListenable<StageWater> water;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderStageFloodClip(
    water,
    MediaQuery.sizeOf(context).height,
    _statusTop(context),
  );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderStageFloodClip renderObject,
  ) => renderObject
    ..water = water
    ..screenHeight = MediaQuery.sizeOf(context).height
    ..top = _statusTop(context);
}

class RenderStageFloodClip extends RenderProxyBox {
  RenderStageFloodClip(this._water, this._screenHeight, this._top);
  ValueListenable<StageWater> _water;
  double _screenHeight, _top;

  set water(ValueListenable<StageWater> v) {
    if (identical(v, _water)) return;
    if (attached) _water.removeListener(markNeedsPaint);
    _water = v;
    if (attached) _water.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  set screenHeight(double v) {
    if (v == _screenHeight) return;
    _screenHeight = v;
    markNeedsPaint();
  }

  set top(double v) {
    if (v == _top) return;
    _top = v;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _water.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _water.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    // Global position: the clip follows the fill wherever the text sits.
    final line =
        _waterLine(_screenHeight, _top, _water.value.level) -
        localToGlobal(Offset.zero).dy;
    if (line >= size.height) return;
    context.pushClipRect(
      needsCompositing,
      offset,
      Rect.fromLTRB(0, math.max(line, 0), size.width, size.height),
      super.paint,
    );
  }
}

// ---- Top, number, info.

class StageCollapseButton extends StatelessWidget {
  const StageCollapseButton({
    super.key,
    required this.onTap,
    this.compact = false,
  });
  final VoidCallback onTap;

  /// The chevron alone (a crowded top row); the label stays for readers.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Semantics(
      button: true,
      label: l.timerCollapseA11y,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('run-collapse'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _P.bg,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.chevron_down, size: 18, color: _P.text),
              if (!compact) ...[
                const SizedBox(width: 6),
                Text(
                  l.timerCollapse,
                  style: _small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _P.text,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Top extends StatelessWidget {
  const _Top({
    required this.title,
    required this.label,
    required this.side,
    required this.a11y,
    required this.collapse,
  });
  final String title, label, a11y;
  final String? side;
  final Widget collapse;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            collapse,
            const SizedBox(width: 8),
            Expanded(
              child: StageFaces(
                builder: (ink) => Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _small.copyWith(color: ink.sub),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                // Read when the phase changes only; the container keeps the
                // one-second number out of this live region.
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: a11y,
                  child: ExcludeSemantics(
                    child: StageFaces(
                      builder: (ink) => FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          label,
                          key: ink.first ? const ValueKey('run-label') : null,
                          maxLines: 1,
                          style: _title1.copyWith(color: ink.main),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (side != null) ...[
                const SizedBox(width: 8),
                ExcludeSemantics(
                  child: StageFaces(
                    builder: (ink) => Text(
                      side!,
                      style: _title3.copyWith(
                        color: ink.sub,
                        fontFeatures: _tnum,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// The hero: seconds left (tabata, ready) or the count (metronome). 90% of
/// the width, at most 45% of the screen height, never the OS text scale.
class _Number extends StatelessWidget {
  const _Number({required this.timer});
  final WorkoutTimer timer;

  @override
  Widget build(BuildContext context) {
    runNumberBuilds++;
    final l = L.of(context);
    final t = timer, s = t.spec!;
    final win = MediaQuery.sizeOf(context);
    final maxSize = win.height * 0.45;
    final phase = t.phase;
    final metronome = !s.tabata;
    String shown;
    String a11y;
    String? subline;
    if (metronome && phase == TimingPhase.work) {
      final n = t.count;
      shown = n == 0 ? l.timerGo : '$n';
      a11y = n == 0
          ? l.timerGo
          : t.target == null
          ? l.timerBeatA11y(n)
          : l.timerCountA11y(n, t.target!);
      if (t.target != null && n > 0) subline = l.timerTarget(t.target!);
    } else {
      final left = phase == TimingPhase.complete ? 0 : t.remaining;
      shown = _big(left);
      a11y = l.timerRemainingA11y(_spoken(l, left));
    }
    // Tabata with a beat: the count under the seconds, as a word in Korean.
    String? beatLine;
    if (!metronome && s.bpm != null && phase == TimingPhase.work) {
      final n = t.count;
      if (n > 0) {
        beatLine = l.timerBeatLine(
          spokenCount(n, l.localeName.split('_').first),
        );
        a11y = '$a11y, ${l.timerBeatA11y(n)}';
      }
    }
    Widget hero(StageInk ink) => FittedBox(
      key: ink.first ? const ValueKey('run-number') : null,
      fit: BoxFit.scaleDown,
      child: Text(
        shown,
        maxLines: 1,
        softWrap: false,
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontSize: maxSize,
          height: 1.0,
          fontWeight: FontWeight.w700,
          fontFeatures: _tnum,
          color: ink.main,
        ),
      ),
    );
    Widget faces(Animation<double>? pulse) => StageFaces(
      builder: (ink) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: pulse == null
                ? hero(ink)
                : _PulseBox(
                    pulse: pulse,
                    color: ink.main,
                    keyed: ink.first,
                    child: hero(ink),
                  ),
          ),
          if (beatLine != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                beatLine,
                maxLines: 1,
                style: _title1.copyWith(color: ink.main, fontFeatures: _tnum),
              ),
            ),
          if (subline != null) ...[
            const SizedBox(height: 8),
            Text(subline, style: _title3.copyWith(color: ink.sub)),
          ],
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: win.width * 0.05),
      // Not a live region: the number would be read every second.
      child: Semantics(
        container: true,
        label: a11y,
        child: ExcludeSemantics(
          child: metronome ? _BeatPulse(timer: t, builder: faces) : faces(null),
        ),
      ),
    );
  }
}

/// Next interval and time left (tabata), elapsed and estimate (metronome),
/// then the round bar.
class _Info extends StatelessWidget {
  const _Info({required this.timer});
  final WorkoutTimer timer;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final t = timer, s = t.spec!;
    final phase = t.phase;
    // (shown, spoken)
    (String, String)? left;
    (String, String)? right;
    if (s.tabata) {
      final lastRound = t.round >= s.rounds;
      final next = switch (phase) {
        TimingPhase.ready => l.timingWorkSeconds(s.work),
        TimingPhase.work when !lastRound || s.tail => l.timingRestSeconds(
          s.rest,
        ),
        TimingPhase.rest when !lastRound => l.timingWorkSeconds(s.work),
        _ => null,
      };
      if (next != null) left = (l.timerNext(next), l.timerNext(next));
      // Without the 3 s ready, as TimingSpec.shownSeconds: the ready shows
      // the card's total, not 3 s more.
      final rest = math.max(
        0,
        math.min(s.shownSeconds, _ceilSeconds(t.total! - t.elapsed)),
      );
      right = (
        l.timerLeftTotal(_clock(rest)),
        l.timerLeftTotal(_spoken(l, rest)),
      );
    } else {
      final played = math.max(0, t.elapsed.inSeconds - 3);
      left = (
        l.timerElapsed(_clock(played)),
        l.timerElapsed(_spoken(l, played)),
      );
      final goal = t.target;
      if (goal != null) {
        final about = math.max(0, ((goal - t.count) * 60 / s.bpm!).ceil());
        right = (
          l.timerAboutLeft(_clock(about)),
          l.timerAboutLeft(_spoken(l, about)),
        );
      }
    }
    final shownLeft = left, shownRight = right;
    Widget text((String, String) v, StageInk ink) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        v.$1,
        maxLines: 1,
        semanticsLabel: v.$2,
        style: _labelTnum.copyWith(color: ink.sub),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StageFaces(
            builder: (ink) => MergeSemantics(
              child: Wrap(
                alignment: shownRight == null
                    ? WrapAlignment.start
                    : shownLeft == null
                    ? WrapAlignment.end
                    : WrapAlignment.spaceBetween,
                runSpacing: 4,
                children: [
                  if (shownLeft != null) text(shownLeft, ink),
                  if (shownRight != null) text(shownRight, ink),
                ],
              ),
            ),
          ),
          if (s.tabata) ...[const SizedBox(height: 8), _RoundBar(timer: t)],
        ],
      ),
    );
  }
}

/// One cell per round on its own dark ground (the cell colors would melt into
/// the flood): past white, current the phase color, the rest surface2.
class _RoundBar extends StatelessWidget {
  const _RoundBar({required this.timer});
  final WorkoutTimer timer;

  @override
  Widget build(BuildContext context) {
    final t = timer, s = t.spec!;
    final phase = t.phase;
    final done = switch (phase) {
      TimingPhase.ready => 0,
      TimingPhase.complete => s.rounds,
      _ => t.round - 1,
    };
    final current = !t.running
        ? _P.paused
        : phase == TimingPhase.rest
        ? _P.fillRest
        : _P.fillWork;
    final gap = s.rounds > 40 ? 1.0 : 2.0;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _P.bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < s.rounds; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  Expanded(
                    child: ColoredBox(
                      color: i < done
                          ? _P.text
                          : i == done && phase != TimingPhase.ready
                          ? current
                          : _P.surface2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Pulses.

/// The second a tabata interval's end pulse is for: 3, 2 and 1 s before the
/// end. None for intervals under 4 s, pause and the summary.
Object? _endBeat(WorkoutTimer t) {
  final s = t.spec;
  if (!t.running || s == null || !s.tabata) return null;
  final phase = t.phase;
  if (phase != TimingPhase.work && phase != TimingPhase.rest) return null;
  if ((phase == TimingPhase.work ? s.work : s.rest) < 4) return null;
  final left = t.remaining;
  if (left < 1 || left > 3) return null;
  return (t.round, phase, left);
}

/// White flash once for each new [beat] while [listenable] notifies (the
/// tabata stage: [_endBeat]; the set stage: the rest's 3, 2, 1). Off under
/// reduce motion; under the text.
class StageEndPulse extends StatefulWidget {
  const StageEndPulse({
    super.key,
    required this.listenable,
    required this.beat,
  });
  final Listenable listenable;

  /// What this moment pulses for (a value that changes per flash), or null.
  final Object? Function() beat;

  @override
  State<StageEndPulse> createState() => _EndPulseState();
}

class _EndPulseState extends State<StageEndPulse>
    with SingleTickerProviderStateMixin {
  static const _peak = 0.18;
  static final _alpha = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: _peak,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 100,
    ),
    TweenSequenceItem(tween: Tween(begin: _peak, end: 0.0), weight: 150),
  ]);

  late final _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: 1,
    animationBehavior: AnimationBehavior.preserve,
  );

  /// The beat already pulsed.
  Object? _last;

  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_onTick);
  }

  @override
  void didUpdateWidget(StageEndPulse old) {
    super.didUpdateWidget(old);
    if (identical(old.listenable, widget.listenable)) return;
    old.listenable.removeListener(_onTick);
    widget.listenable.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_onTick);
    _ac.dispose();
    super.dispose();
  }

  void _onTick() {
    final key = widget.beat();
    if (key == null || key == _last) return;
    _last = key;
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    _ac.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _ac,
          builder: (_, _) => ColoredBox(
            key: const ValueKey('run-end-pulse'),
            color: _P.text.withValues(alpha: _alpha.evaluate(_ac)),
          ),
        ),
      ),
    ),
  );
}

/// One controller per stage for the beat pulse; fires on every new count.
/// Above 180 BPM there is no visual pulse (WCAG 2.3.1: 3 flashes a second).
class _BeatPulse extends StatefulWidget {
  const _BeatPulse({required this.timer, required this.builder});
  final WorkoutTimer timer;
  final Widget Function(Animation<double> pulse) builder;

  @override
  State<_BeatPulse> createState() => _BeatPulseState();
}

class _BeatPulseState extends State<_BeatPulse>
    with SingleTickerProviderStateMixin {
  late final _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: 1,
    animationBehavior: AnimationBehavior.preserve,
  );
  late int _count = widget.timer.count;

  @override
  void initState() {
    super.initState();
    widget.timer.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.timer.removeListener(_onTick);
    _ac.dispose();
    super.dispose();
  }

  void _onTick() {
    final t = widget.timer;
    final n = t.count;
    if (n == _count) return;
    _count = n;
    if (t.running && n > 0 && (t.spec?.bpm ?? 0) <= 180) _ac.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => widget.builder(_ac);
}

/// Square box around the number; its size depends on the room only, so
/// 9 → 10 → 100 does not resize it. Reduce motion: no scale, the border
/// still flashes.
class _PulseBox extends StatelessWidget {
  const _PulseBox({
    required this.pulse,
    required this.color,
    required this.keyed,
    required this.child,
  });

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.04,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 100,
    ),
    TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 150),
  ]);

  final Animation<double> pulse;
  final Color color;
  final bool keyed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, box) => SizedBox.square(
        dimension: math.min(box.maxWidth, box.maxHeight),
        child: AnimatedBuilder(
          animation: pulse,
          child: Center(child: child),
          builder: (_, child) => Transform.scale(
            scale: still ? 1.0 : _scale.evaluate(pulse),
            child: DecoratedBox(
              key: keyed ? const ValueKey('beat-pulse-border') : null,
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: color.withValues(alpha: 1 - pulse.value),
                  width: 3,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Controls. Buttons sit on the flood, so each has its own solid ground.

/// While locked: dimmed, out of the focus order, disabled for a screen
/// reader; a touch only nudges.
class StageGate extends StatelessWidget {
  const StageGate({
    super.key,
    required this.locked,
    required this.label,
    required this.onBlocked,
    required this.child,
  });
  final bool locked;
  final String label;
  final VoidCallback onBlocked;
  final Widget child;

  static const dim = 0.35;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return Semantics(
      button: true,
      enabled: false,
      label: label,
      excludeSemantics: true,
      child: ExcludeFocus(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBlocked,
          child: Opacity(
            opacity: dim,
            child: IgnorePointer(child: child),
          ),
        ),
      ),
    );
  }
}

/// One line that shrinks instead of breaking.
Widget stageOneLine(String text, TextStyle style) => FittedBox(
  fit: BoxFit.scaleDown,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(text, maxLines: 1, style: style),
  ),
);

/// The 88 pt bar for the thumb: pause, or resume.
class StageBar extends StatelessWidget {
  const StageBar({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;

  /// Null: shown but not pressable (dimmed, disabled for a screen reader).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap == null ? false : null,
    label: label,
    onTap: onTap,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: onTap == null ? _P.text.withValues(alpha: 0.5) : _P.text,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: _P.bg),
                const SizedBox(width: 8),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w700,
                    color: _P.bg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A 56 pt button: outlined on the dark ground, or white when [primary].
class StageButton extends StatelessWidget {
  const StageButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: label,
    onTap: onTap,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56, minWidth: 44),
        decoration: BoxDecoration(
          color: primary ? _P.text : _P.bg,
          borderRadius: BorderRadius.circular(16),
          border: primary ? null : Border.all(color: _P.outline, width: 1.5),
        ),
        alignment: Alignment.center,
        child: stageOneLine(
          label,
          _label.copyWith(color: primary ? _P.bg : _P.text),
        ),
      ),
    ),
  );
}

/// « and »: 56 pt circles.
class StageRoundButton extends StatelessWidget {
  const StageRoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;

  /// Null: there is nothing that way — drawn dim, disabled for readers.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: label,
    onTap: onTap,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? StageGate.dim : 1,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _P.bg,
            shape: BoxShape.circle,
            border: Border.all(color: _P.text, width: 2),
          ),
          child: Icon(icon, size: 28, color: _P.text),
        ),
      ),
    ),
  );
}

/// Lock / unlock: a 56 pt circle held [kHoldToLock]. A screen reader's
/// double tap (and Enter / Space) toggles at once.
class StageLockButton extends StatefulWidget {
  const StageLockButton({
    super.key,
    required this.locked,
    required this.onToggle,
  });
  final bool locked;
  final VoidCallback onToggle;

  static const size = 56.0;

  @override
  State<StageLockButton> createState() => _LockButtonState();
}

class _LockButtonState extends State<StageLockButton>
    with SingleTickerProviderStateMixin {
  // preserve: "remove animations" must not run the 2 s hold in 100 ms.
  late final AnimationController _c =
      AnimationController(
        vsync: this,
        duration: kHoldToLock,
        animationBehavior: AnimationBehavior.preserve,
      )..addStatusListener((s) {
        if (s != AnimationStatus.completed) return;
        widget.onToggle();
        _c.reset();
      });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _release() => _c.reset();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final locked = widget.locked;
    return Semantics(
      button: true,
      focusable: true,
      label: locked ? l.timerUnlock : l.timerLock,
      hint: locked ? l.timerUnlockHint : l.timerLockHint,
      onTap: widget.onToggle,
      excludeSemantics: true,
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onToggle();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _c.forward(from: 0),
          onTapUp: (_) => _release(),
          onTapCancel: _release,
          child: CustomPaint(
            foregroundPainter: _HoldBorder(
              _c,
              locked ? _P.text : _P.outline,
              locked ? _P.bg : _P.text,
              radius: StageLockButton.size / 2,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: locked ? _P.text : _P.bg,
              ),
              child: SizedBox.square(
                dimension: StageLockButton.size,
                child: Icon(
                  locked
                      ? CupertinoIcons.lock_fill
                      : CupertinoIcons.lock_open_fill,
                  size: 26,
                  color: locked ? _P.bg : _P.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// End (or leave) that must be held [kHoldToEnd]; a screen reader's long
/// press ends at once. Locked, it says how to unlock and a swallowed touch
/// brightens it for 300 ms.
class _HoldToEnd extends StatefulWidget {
  const _HoldToEnd({
    super.key,
    required this.label,
    required this.a11y,
    required this.lockedLabel,
    required this.locked,
    required this.nudge,
    required this.onBlocked,
    required this.onEnd,
  });
  final String label, a11y, lockedLabel;
  final bool locked;
  final int nudge;
  final VoidCallback onBlocked, onEnd;

  @override
  State<_HoldToEnd> createState() => _HoldToEndState();
}

class _HoldToEndState extends State<_HoldToEnd>
    with SingleTickerProviderStateMixin {
  late final _c =
      AnimationController(
        vsync: this,
        duration: kHoldToEnd,
        animationBehavior: AnimationBehavior.preserve,
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onEnd();
      });

  var _bright = false;
  Timer? _flash;

  @override
  void didUpdateWidget(_HoldToEnd old) {
    super.didUpdateWidget(old);
    if (widget.nudge == old.nudge || !widget.locked) return;
    _flash?.cancel();
    setState(() => _bright = true);
    _flash = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _bright = false);
    });
  }

  @override
  void dispose() {
    _flash?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _release() {
    if (_c.status != AnimationStatus.completed) _c.reset();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.locked;
    return Semantics(
      button: true,
      enabled: !locked,
      label: widget.a11y,
      onLongPress: locked ? null : widget.onEnd,
      excludeSemantics: true,
      child: ExcludeFocus(
        excluding: locked,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => locked ? widget.onBlocked() : _c.forward(from: 0),
          onTapUp: (_) => _release(),
          onTapCancel: _release,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                key: const ValueKey('run-hold-ground'),
                opacity: locked ? (_bright ? 0.7 : StageGate.dim) : 1,
                child: CustomPaint(
                  painter: _HoldBorder(_c, _P.outline, _P.text),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: _P.bg,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: SizedBox(height: 56, width: double.infinity),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: stageOneLine(
                    locked ? widget.lockedLabel : widget.label,
                    _label.copyWith(
                      color: _P.text.withValues(
                        alpha: locked && !_bright ? 0.8 : 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resting outline plus the share of it [progress] has filled, 3 px.
class _HoldBorder extends CustomPainter {
  _HoldBorder(this.progress, this.border, this.fill, {this.radius = 16})
    : super(repaint: progress);
  final Animation<double> progress;
  final Color border, fill;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1.5),
          Radius.circular(radius),
        ),
      );
    Paint stroke(Color c, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = c;
    canvas.drawPath(path, stroke(border, 1.5));
    for (final m in path.computeMetrics()) {
      canvas.drawPath(
        m.extractPath(0, m.length * progress.value),
        stroke(fill, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_HoldBorder old) =>
      old.progress != progress ||
      old.border != border ||
      old.fill != fill ||
      old.radius != radius;
}

/// A 56 pt − or + that repeats while held.
class StageStepKey extends StatefulWidget {
  const StageStepKey({
    super.key,
    required this.icon,
    required this.label,
    required this.onStep,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onStep;

  @override
  State<StageStepKey> createState() => _StepKeyState();
}

class _StepKeyState extends State<StageStepKey> {
  Timer? _repeat;

  void _stop() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.onStep;
    return Semantics(
      button: true,
      enabled: on != null,
      label: widget.label,
      onTap: on,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: on,
        onLongPressStart: on == null
            ? null
            : (_) => _repeat = Timer.periodic(
                const Duration(milliseconds: 100),
                (_) => widget.onStep?.call(),
              ),
        onLongPressEnd: (_) => _stop(),
        onLongPressCancel: _stop,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _P.bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: on == null ? _P.outline : _P.text,
              width: 2,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 26,
            color: on == null ? _P.outline : _P.text,
          ),
        ),
      ),
    );
  }
}

/// During a rest: the reps of the round just done, in one press —
/// [−] 12 [+] [Log]. No keyboard: a 10 s rest is no time to type.
class _RestLog extends StatefulWidget {
  const _RestLog({super.key, required this.initial, required this.onLog});
  final int initial;
  final ValueChanged<int> onLog;

  @override
  State<_RestLog> createState() => _RestLogState();
}

class _RestLogState extends State<_RestLog> {
  late int _n = widget.initial;

  void _step(int d) => setState(() => _n = (_n + d).clamp(0, 999));

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        // The keys sit beside the box, under its label.
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          StageStepKey(
            key: const ValueKey('run-minus'),
            icon: CupertinoIcons.minus,
            label: '${l.timerRestLog} −',
            onStep: _n > 0 ? () => _step(-1) : null,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // What the box counts, over it: the number is not the
                // rest's countdown above.
                ExcludeSemantics(
                  child: StageFaces(
                    builder: (ink) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        l.timerRestLog,
                        maxLines: 1,
                        style: _small.copyWith(color: ink.sub),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Semantics(
                  label: l.timerRestLog,
                  value: '$_n',
                  child: ExcludeSemantics(
                    child: Container(
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: _P.bg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$_n',
                          key: const ValueKey('together-count'),
                          textScaler: TextScaler.noScaling,
                          style: const TextStyle(
                            fontSize: 44,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            fontFeatures: _tnum,
                            color: _P.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          StageStepKey(
            key: const ValueKey('run-plus'),
            icon: CupertinoIcons.plus,
            label: '${l.timerRestLog} +',
            onStep: _n < 999 ? () => _step(1) : null,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            child: StageButton(
              key: const ValueKey('together-log'),
              label: l.togetherLog,
              primary: true,
              onTap: () => widget.onLog(_n),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Summary (same stage, once the run completed or was ended).

class _Summary extends StatefulWidget {
  const _Summary({
    required this.link,
    required this.onClose,
    required this.onAgain,
  });
  final RunLink link;
  final VoidCallback onClose, onAgain;

  @override
  State<_Summary> createState() => _SummaryState();
}

class _SummaryState extends State<_Summary>
    with SingleTickerProviderStateMixin {
  late final _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );

  RunLink get _link => widget.link;

  /// Reps picked for rounds not logged yet (1-based); logged on the button.
  /// On the link, so folding the summary and opening it again keeps them.
  Map<int, int?> get _draft => _link.drafts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Once per run, not again when the summary is opened again.
    if (_link.flashed) return;
    _link.flashed = true;
    if (!_link.timer.endedEarly && !MediaQuery.disableAnimationsOf(context)) {
      _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  /// Rounds whose work was done: every round on completion, else the ones
  /// that reached their rest.
  int get _roundsDone {
    final t = _link.timer, s = t.spec!;
    return switch (t.phase) {
      TimingPhase.complete => s.rounds,
      TimingPhase.rest => t.round,
      TimingPhase.work => t.round - 1,
      TimingPhase.ready => 0,
    };
  }

  /// Work and rest seconds played (the 3 s ready left out).
  (int, int) get _totals {
    final t = _link.timer, s = t.spec!;
    final e = math.max(0, t.elapsed.inMilliseconds - 3000) ~/ 1000;
    final cycle = s.work + s.rest;
    final full = e ~/ cycle, into = e % cycle;
    return (
      full * s.work + math.min(into, s.work),
      full * s.rest + math.max(0, into - s.work),
    );
  }

  List<int> get _unlogged => [
    for (var i = 1; i <= _roundsDone; i++)
      if (_roundLogged(_link, i) == null) i,
  ];

  void _logAll() {
    final link = _link, t = link.timer;
    if (t.spec!.tabata) {
      for (final i in _unlogged) {
        _logRound(link, i, _draft[i]);
      }
    } else if (t.count > 0) {
      link.onLogCount?.call(t.count);
    }
    _done();
  }

  void _done() {
    _link
      ..logged = true
      ..changed();
    _link.onLogged?.call();
    widget.onClose();
  }

  Future<void> _editRound(int round) async {
    final current = _roundLogged(_link, round) ?? _draft[round];
    final logged = _roundLogged(_link, round) != null;
    final res = await showCupertinoModalPopup<({int? reps, bool fill})>(
      context: context,
      builder: (_) => _CountSheet(
        round: round,
        initial: current ?? _restDefault(_link),
        canFill: !logged,
      ),
    );
    if (res == null || !mounted) return;
    if (logged) {
      res.reps == null
          ? _clearRound(_link, round)
          : _logRound(_link, round, res.reps);
      return;
    }
    setState(() {
      _draft[round] = res.reps;
      if (res.fill) {
        for (final i in _unlogged.where((i) => i > round)) {
          _draft[i] = res.reps;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final link = _link, t = link.timer, s = t.spec!;
    final short = MediaQuery.sizeOf(context).height < 600;
    final duo = t.shared ? link.together : null;
    // My row is this run's rounds; the others are their sets on the card.
    final people = [
      if (duo != null) ...[
        (l.togetherMe, link.roundReps),
        (duo.partner, duo.theirs),
        for (final p in duo.more) (p.name, p.counts),
      ],
    ];
    final chip = [
      if (s.tabata) l.timingProtocol(s.work, s.rest, s.rounds),
      if (s.bpm != null) l.timingBpm(s.bpm!),
    ].join(' · ');
    final String hero;
    final List<(String, String)> rows;
    if (s.tabata) {
      final (work, rest) = _totals;
      hero = l.timerRoundsDone(_roundsDone);
      rows = [
        (l.timingWork, _clock(work)),
        if (s.rest > 0) (l.timingRest, _clock(rest)),
        (l.timerTotal, _clock(work + rest)),
      ];
    } else {
      final goal = t.target;
      hero = goal != null && t.endedEarly
          ? l.timerRepsOfTarget(t.count, goal)
          : l.timerRepsDone(t.count);
      rows = [
        (l.timerTime, _clock(math.max(0, t.elapsed.inSeconds - 3))),
        (l.timerTempo, l.timingBpm(s.bpm!)),
      ];
    }
    final unlogged = s.tabata ? _unlogged.length : (t.count > 0 ? 1 : 0);
    final canLog = !link.logged && unlogged > 0;
    final primary = !canLog
        ? l.timerClose
        : s.tabata
        ? l.timerLogSetsCount(unlogged)
        : l.timerLogSets;
    final heart = link.recovery;
    final lastRest = s.tabata && heart?.peak != null && heart?.bpm != null
        ? l.timerLastRest(heart!.peak!, heart.bpm!)
        : null;
    const secondary = TextStyle(fontSize: 15, color: _P.textSecondary);

    final body = CustomScrollView(
      key: const ValueKey('run-summary'),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text(
                  t.endedEarly ? l.timerStopped : l.timerDone,
                  textAlign: TextAlign.center,
                  style: _title1.copyWith(color: _P.text),
                ),
                const SizedBox(height: 8),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _P.surface2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Text(
                        chip,
                        textAlign: TextAlign.center,
                        style: _label.copyWith(color: _P.text),
                      ),
                    ),
                  ),
                ),
                if (link.title.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    [link.title, ?link.weightLabel].join(' · '),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: secondary,
                  ),
                ],
                SizedBox(height: short ? 12 : 24),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    hero,
                    key: const ValueKey('run-summary-hero'),
                    maxLines: 1,
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      fontSize: 48,
                      height: 56 / 48,
                      fontWeight: FontWeight.w700,
                      fontFeatures: _tnum,
                      color: _P.text,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    for (final (label, value) in rows)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label, style: secondary),
                          Text(
                            value,
                            style: _title3.copyWith(
                              color: _P.text,
                              fontFeatures: _tnum,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (s.tabata && _roundsDone > 0) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 1; i <= _roundsDone; i++)
                        _RoundChip(
                          key: ValueKey('run-round-$i'),
                          text: l.timerRoundChip(
                            i,
                            '${_roundLogged(link, i) ?? _draft[i] ?? '–'}',
                          ),
                          logged: _roundLogged(link, i) != null,
                          label: l.timerRoundCountTitle(i),
                          onTap: link.logged ? null : () => _editRound(i),
                        ),
                    ],
                  ),
                ],
                if (people.any((p) => p.$2.isNotEmpty)) ...[
                  const SizedBox(height: 16),
                  _People(rows: people, left: duo!.partnerLeft),
                ],
                if (lastRest != null) ...[
                  const SizedBox(height: 12),
                  Text(lastRest, textAlign: TextAlign.center, style: secondary),
                ],
                const Spacer(),
                SizedBox(height: short ? 8 : 16),
                StageButton(
                  key: const ValueKey('run-log'),
                  label: primary,
                  primary: true,
                  onTap: canLog ? _logAll : _done,
                ),
                if (!t.shared) ...[
                  const SizedBox(height: 8),
                  StageButton(
                    key: const ValueKey('run-again'),
                    label: l.timerAgain,
                    onTap: widget.onAgain,
                  ),
                ],
                if (canLog) ...[
                  const SizedBox(height: 8),
                  StageButton(
                    key: const ValueKey('run-summary-close'),
                    label: l.timerClose,
                    onTap: widget.onClose,
                  ),
                ],
                SizedBox(height: short ? 8 : 16),
              ],
            ),
          ),
        ),
      ],
    );
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, box) => Padding(
            // Wide windows: a 640 pt column in the middle.
            padding: EdgeInsets.symmetric(
              horizontal: math.max(0, (box.maxWidth - 640) / 2),
            ),
            child: body,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _flash,
              builder: (_, _) => ColoredBox(
                color: _P.text.withValues(alpha: 0.2 * (1 - _flash.value)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundChip extends StatelessWidget {
  const _RoundChip({
    super.key,
    required this.text,
    required this.logged,
    required this.label,
    required this.onTap,
  });
  final String text, label;
  final bool logged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    value: text,
    onTap: onTap,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _P.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: logged ? _P.text : _P.outline),
        ),
        // Hug the text: a Wrap hands out the full width.
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(text, style: _labelTnum.copyWith(color: _P.text)),
        ),
      ),
    ),
  );
}

/// Together: one row per person, '–' where nothing was logged (not 0).
class _People extends StatelessWidget {
  const _People({required this.rows, required this.left});
  final List<(String, List<int?>)> rows;

  /// Where the others left, if they did.
  final String? left;

  @override
  Widget build(BuildContext context) {
    final longest = rows.map((r) => r.$2.length).reduce(math.max);
    return Column(
      key: const ValueKey('run-people'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (name, counts) in rows)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: _P.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    [
                      ...counts,
                      for (var i = counts.length; i < longest; i++) null,
                    ].map((n) => n ?? '–').join('  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _labelTnum.copyWith(color: _P.text),
                  ),
                ),
              ],
            ),
          ),
        if (left != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              left!,
              style: const TextStyle(fontSize: 13, color: _P.textSecondary),
            ),
          ),
      ],
    );
  }
}

/// Reps of one round: − big number +, presets, "all remaining rounds",
/// clear. Returns null when dismissed.
class _CountSheet extends StatefulWidget {
  const _CountSheet({
    required this.round,
    required this.initial,
    required this.canFill,
  });
  final int round, initial;
  final bool canFill;

  @override
  State<_CountSheet> createState() => _CountSheetState();
}

class _CountSheetState extends State<_CountSheet> {
  late int _n = widget.initial;

  void _set(int v) => setState(() => _n = v.clamp(0, 999));

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final media = MediaQuery.of(context);
    void pop(({int? reps, bool fill}) v) => Navigator.of(context).pop(v);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: kStageMaxTextScale,
      child: CupertinoTheme(
        data: const CupertinoThemeData(brightness: Brightness.dark),
        child: Container(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + media.padding.bottom),
          child: SingleChildScrollView(
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: _P.text,
                decoration: TextDecoration.none,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l.timerRoundCountTitle(widget.round),
                      style: _title3.copyWith(color: _P.text),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      StageStepKey(
                        key: const ValueKey('count-sheet-minus'),
                        icon: CupertinoIcons.minus,
                        label: '${l.timerRoundCountTitle(widget.round)} −',
                        onStep: _n > 0 ? () => _set(_n - 1) : null,
                      ),
                      Expanded(
                        child: Semantics(
                          label: l.timerRoundCountTitle(widget.round),
                          value: '$_n',
                          child: ExcludeSemantics(
                            child: Text(
                              '$_n',
                              key: const ValueKey('count-sheet-value'),
                              textAlign: TextAlign.center,
                              textScaler: TextScaler.noScaling,
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w700,
                                fontFeatures: _tnum,
                                color: _P.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                      StageStepKey(
                        key: const ValueKey('count-sheet-plus'),
                        icon: CupertinoIcons.plus,
                        label: '${l.timerRoundCountTitle(widget.round)} +',
                        onStep: _n < 999 ? () => _set(_n + 1) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final v in const [5, 8, 10, 12, 15, 20])
                        _RoundChip(
                          key: ValueKey('count-sheet-preset-$v'),
                          text: '$v',
                          logged: v == _n,
                          label: '$v',
                          onTap: () => _set(v),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StageButton(
                    key: const ValueKey('count-sheet-done'),
                    label: l.doneEditing,
                    primary: true,
                    onTap: () => pop((reps: _n, fill: false)),
                  ),
                  if (widget.canFill) ...[
                    const SizedBox(height: 8),
                    StageButton(
                      key: const ValueKey('count-sheet-fill'),
                      label: l.timerFillRest(_n),
                      onTap: () => pop((reps: _n, fill: true)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  StageButton(
                    key: const ValueKey('count-sheet-clear'),
                    label: l.timerClear,
                    onTap: () => pop((reps: null, fill: false)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
