import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'editor.dart';
import 'focus.dart';
import 'focus_link.dart';
import 'l10n/generated/app_localizations.dart';
import 'run_page.dart';
import 'set_grid.dart' show cellLabel;
import 'stage_palette.dart';
import 'timer_sheet.dart' show ValueSheet;
import 'units.dart';
import 'workout_timing.dart' show TimingSpec;

// The set stage (spec focus-stage-1.8 §7): one exercise at a time on the dark
// stage of the timer. The next set is the hero, one bar logs it, the rest
// floods the screen in the rest color. Data comes only from [FocusLink] and
// its [RestTimer]; the numbers the person sets live here, per block id.

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
const _small = TextStyle(fontSize: 15, height: 20 / 15);
const _swipeVelocity = 300.0;
const _dark = CupertinoThemeData(
  brightness: Brightness.dark,
  primaryColor: _P.text,
  scaffoldBackgroundColor: _P.bg,
);

/// "1:30".
String _clock(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// The rest's big number: "27" under a minute, "1:30" from there.
String _big(int s) => s < 60 ? '$s' : _clock(s);

int _ceil(Duration d) => (d.inMilliseconds / 1000).ceil();

String _unit(String id) => unitById[id]?.label ?? id;

/// Seconds of a duration set.
int _seconds(LoggedSet s) =>
    ((s.value ?? 0) * (baseFactor[s.unit] ?? 1)).round();

bool _isTimer(ExerciseBlock b) => TimingSpec.parse(b.name) != null;

/// Weight and bodyweight sets start a rest on [Done]; time and distance do
/// not (a small [Start rest] instead).
bool _rests(LoggedSet v) =>
    kindOf(v) == FocusKind.weight || kindOf(v) == FocusKind.reps;

/// A set in one short line: "80 × 5" (another unit spelled out), "12회",
/// "1:00", "5km".
String _setText(L l, LoggedSet v, String weightUnit) {
  final reps = v.reps == null ? '—' : '${v.reps}';
  return switch (kindOf(v)) {
    FocusKind.weight =>
      '${v.unit == weightUnit ? formatNumber(v.value!) : formatValue(v.value!, v.unit)} × $reps',
    FocusKind.reps => v.reps == null ? '— × —' : l.repsCount(v.reps!),
    FocusKind.duration => _clock(_seconds(v)),
    FocusKind.distance => formatValue(v.value!, v.unit),
  };
}

/// For screen readers: "80kg 5회".
String _spokenSet(L l, LoggedSet v) => [
  if (v.value != null) formatValue(v.value!, v.unit),
  if (v.reps != null) l.repsCount(v.reps!),
].join(' ');

class FocusPage extends StatefulWidget {
  const FocusPage({super.key, required this.link});
  final FocusLink link;

  /// Pushes the stage as a full-screen dialog (no iOS edge swipe).
  static Future<void> open(BuildContext context, FocusLink link) =>
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => FocusPage(link: link),
        ),
      );

  @override
  State<FocusPage> createState() => _FocusPageState();
}

/// What [Done] just wrote, for [Undo].
typedef _Logged = ({String blockId, String setId, bool rested});

class _FocusPageState extends State<FocusPage> {
  final _water = _Water();
  Animation<double>? _routeIn;
  Timer? _clockTimer;
  bool? _still;

  /// The block on screen, and where it was (a vanished block falls back to
  /// its neighbour).
  String? _id;
  int _index = 0;

  final _sugg = <String, FocusSuggestion>{};
  final _draft = <String, LoggedSet>{};
  final _hadPlan = <String, bool>{};
  final _edited = <String>{};

  bool _summary = false;
  bool _locked = false, _bright = false;
  Timer? _brightTimer;

  /// 1 s after [Done] the bar takes no touch (a second tap would end the
  /// rest it just started).
  Timer? _cool;
  _Logged? _undo;
  Timer? _undoTimer;

  bool _wasResting = false, _heartBuzzed = false, _gone = false;

  FocusLink get _link => widget.link;

  @override
  void initState() {
    super.initState();
    StagePortrait.enter();
    final blocks = _link.blocks;
    _id = blocks.any((b) => b.id == _link.currentId)
        ? _link.currentId
        : blocks.firstOrNull?.id;
    _index = math.max(0, blocks.indexWhere((b) => b.id == _id));
    _wasResting = _link.rest.running;
    _link.addListener(_onLink);
    _link.rest.addListener(_onRest);
    _link.recovery?.addListener(_onHeart);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = _block;
      if (b != null && mounted && !_restsOn(b)) _link.onLift?.call(b);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The dark faces are clipped at the waterline in screen space; a level
    // that does not move never repaints them, so the clip painted while the
    // page slid in would stay. Paint again once it has arrived.
    final routeIn = ModalRoute.of(context)?.animation;
    if (!identical(routeIn, _routeIn)) {
      _routeIn?.removeStatusListener(_arrived);
      _routeIn = routeIn?..addStatusListener(_arrived);
    }
    // The flood reads the level on its own clock; reduce motion: once a second.
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
    _cool?.cancel();
    _undoTimer?.cancel();
    _brightTimer?.cancel();
    _link.removeListener(_onLink);
    _link.rest.removeListener(_onRest);
    _link.recovery?.removeListener(_onHeart);
    _water.dispose();
    StagePortrait.leave();
    super.dispose();
  }

  // ---- State.

  ExerciseBlock? _find(String? id) =>
      _link.blocks.where((b) => b.id == id).firstOrNull;

  ExerciseBlock? get _block => _find(_id);

  String? get _ownerId => switch (_link.rest.owner) {
    ExerciseBlock b => b.id,
    String s => s,
    _ => null,
  };

  bool _restsOn(ExerciseBlock b) => _link.rest.running && _ownerId == b.id;

  void _sync() {
    final b = _block;
    _water.value = (
      level: b != null && _restsOn(b) ? _link.rest.level : 0,
      fill: _P.fillRest,
    );
  }

  /// Reads the suggestion again: on entering a block, after [Done], after
  /// undo and when the rest ends — never on [FocusLink.changed].
  void _refresh(ExerciseBlock b) {
    _hadPlan.putIfAbsent(b.id, () => b.sets.any((s) => !s.theirs && !s.done));
    final s =
        _link.suggest?.call(b) ??
        FocusSuggestion(
          values: LoggedSet(unit: _link.weightUnit),
          source: FocusSource.none,
        );
    _sugg[b.id] = s;
    _draft[b.id] = s.values;
    _edited.remove(b.id);
  }

  void _ensure(ExerciseBlock b) {
    if (!_sugg.containsKey(b.id)) _refresh(b);
  }

  /// The editor changed the document: follow a vanished block to its
  /// neighbour; nothing left closes the stage. Values are not touched.
  void _onLink() {
    final blocks = _link.blocks;
    if (blocks.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _close());
      return;
    }
    final i = blocks.indexWhere((b) => b.id == _id);
    if (i >= 0) {
      _index = i;
      return;
    }
    _index = _index.clamp(0, blocks.length - 1);
    _id = blocks[_index].id;
    _summary = false;
    _link.currentId = _id;
  }

  void _onRest() {
    final running = _link.rest.running;
    if (_wasResting && !running) {
      // The rest ended (0 s, skip, or stopped): its block is back to a set.
      final b = _find(_ownerId);
      if (b != null) {
        _refresh(b);
        _link.onLift?.call(b);
      }
      _heartBuzzed = false;
    }
    _wasResting = running;
  }

  /// Heart rate back mid-rest: one heavy buzz, no sound (not the 3·2·1).
  void _onHeart() {
    final r = _link.recovery;
    if (r == null || !_link.rest.running || _heartBuzzed || !r.recovered) {
      return;
    }
    _heartBuzzed = true;
    if (_link.rest.haptics) unawaited(HapticFeedback.heavyImpact());
  }

  void _setDraft(ExerciseBlock b, LoggedSet v) => setState(() {
    _draft[b.id] = v;
    _edited.add(b.id);
  });

  void _close() {
    if (_gone || !mounted) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    _gone = true;
    Navigator.of(context).pop();
  }

  void _goTo(String id) {
    final i = _link.blocks.indexWhere((b) => b.id == id);
    if (i < 0) return;
    setState(() {
      _id = id;
      _index = i;
      _summary = false;
      _link.currentId = id;
    });
  }

  void _go(int delta) {
    final i = _index + delta;
    if (i < 0 || i >= _link.blocks.length) return;
    _goTo(_link.blocks[i].id);
  }

  void _swipe(DragEndDetails d) {
    if (_locked) return _nudgeLock();
    final v = d.primaryVelocity ?? 0;
    if (v <= -_swipeVelocity) {
      _go(1);
    } else if (v >= _swipeVelocity) {
      _go(-1);
    }
  }

  void _toggleLock() {
    final l = L.of(context);
    setState(() => _locked = !_locked);
    if (_link.rest.haptics) unawaited(HapticFeedback.mediumImpact());
    SemanticsService.sendAnnouncement(
      View.of(context),
      _locked ? l.timerLockedAnnounce : l.timerUnlockedAnnounce,
      Directionality.of(context),
    );
  }

  /// A touch the lock swallowed: the hint under the bar lights up for 300 ms.
  void _nudgeLock() {
    if (!_locked) return;
    _brightTimer?.cancel();
    setState(() => _bright = true);
    _brightTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _bright = false);
    });
  }

  /// [Done]: writes the set (the planned one by id, else a new one), starts
  /// the rest for weight and bodyweight sets, reads the next suggestion.
  void _log(ExerciseBlock b) {
    final v = _draft[b.id], s = _sugg[b.id];
    if (v == null || s == null || _cool != null || !canLog(v)) return;
    final id = _link.onLog?.call(b, s.plannedId, v);
    if (id == null) return;
    final l = L.of(context);
    final rested = _rests(v);
    final fresh = _find(b.id) ?? b;
    _refresh(fresh);
    if (rested) _startRest(fresh, l);
    _cool?.cancel();
    _cool = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _cool = null);
    });
    _undoTimer?.cancel();
    _undo = (blockId: b.id, setId: id, rested: rested);
    _undoTimer = Timer(
      Duration(seconds: MediaQuery.accessibleNavigationOf(context) ? 15 : 5),
      () {
        if (mounted) setState(() => _undo = null);
      },
    );
    SemanticsService.sendAnnouncement(
      View.of(context),
      l.focusLogged(_spokenSet(l, v)),
      Directionality.of(context),
    );
    setState(() => _summary = false);
  }

  void _startRest(ExerciseBlock b, L l) {
    final rest = _link.rest;
    final next = _draft[b.id];
    final body = next == null
        ? ''
        : l.focusNextUp(
            '${l.focusSetLabel(_setNumber(b))} ${_setText(l, next, _link.weightUnit)}',
          );
    final title = l.focusRestOverTitle;
    rest.notice = () => (title: title, body: body);
    rest.start(b, _link.restFor?.call(b) ?? const Duration(seconds: 90));
    _wasResting = true;
    _heartBuzzed = false;
    _link.onRested?.call(b);
  }

  /// Takes back the set just logged and the rest it started.
  void _takeBack() {
    final u = _undo;
    if (u == null) return;
    final b = _find(u.blockId);
    if (b != null) _link.onUndo?.call(b, u.setId);
    if (u.rested && _link.rest.running && _ownerId == u.blockId) {
      _link.rest.stop();
    }
    _undoTimer?.cancel();
    _cool?.cancel();
    final fresh = _find(u.blockId);
    setState(() {
      _undo = null;
      _cool = null;
      _summary = false;
      if (fresh != null) _refresh(fresh);
    });
  }

  void _restBy(ExerciseBlock b, int seconds) {
    final rest = _link.rest;
    rest.add(Duration(seconds: seconds));
    _link.onRestChanged?.call(b, rest.length);
  }

  /// The set's number: the planned one's place among mine, else one past my
  /// done sets.
  int _setNumber(ExerciseBlock b) {
    final mine = b.sets.where((s) => !s.theirs).toList();
    final planned = _sugg[b.id]?.plannedId;
    final at = planned == null ? -1 : mine.indexWhere((s) => s.id == planned);
    if (at >= 0) return at + 1;
    return mine.where((s) => s.done).length + 1;
  }

  // ---- Wheel sheets (no system keyboard on the stage).

  Future<void> _wheel({
    required String title,
    required int value,
    required List<int> values,
    required List<int> presets,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
  }) {
    final all = {...values, ...presets}.toList()..sort();
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: kStageMaxTextScale,
        child: CupertinoTheme(
          data: _dark,
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: _P.text,
              decoration: TextDecoration.none,
            ),
            child: ValueSheet(
              title: title,
              value: value,
              values: all,
              presets: presets.toSet().toList(),
              label: label,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

  /// The numbers people pick from: last time here, today's last, the setup.
  List<LoggedSet> _presets(ExerciseBlock b) => [
    ?_sugg[b.id]?.lastTimeSame,
    ?b.sets.where((s) => s.mine).lastOrNull,
    if (b.setup case final s?)
      LoggedSet(value: s.weight, unit: s.unit, reps: s.repsPerSet),
  ];

  /// The value wheel: weight in its plate grid (0 = bodyweight), time and
  /// distance in their unit's step. Hundredths, so 82.5 is a stop.
  Future<void> _pickValue(ExerciseBlock b) {
    final l = L.of(context);
    final v = _draft[b.id]!;
    final kind = unitById[v.unit]?.kind ?? UnitKind.weight;
    final step = (valueStep(v.unit) * 100).round();
    final max = switch (v.unit) {
      'kg' => 500,
      'lb' => 1100,
      's' => 3600,
      'min' => 180,
      'h' => 12,
      'm' => 20000,
      _ => 100,
    };
    int c(double x) => (x * 100).round();
    return _wheel(
      title: switch (kind) {
        UnitKind.weight => l.focusWeightTitle,
        UnitKind.duration => l.timerTime,
        UnitKind.distance => l.focusDistanceTitle,
      },
      value: c(v.value ?? 0),
      values: [for (var i = 0; i <= max * 100; i += step) i],
      presets: [
        for (final p in _presets(b))
          if (p.value != null && p.unit == v.unit) c(p.value!),
      ],
      label: (n) => n == 0 && kind == UnitKind.weight
          ? l.focusBodyweight
          : formatValue(n / 100, v.unit),
      onChanged: (n) {
        final cur = _draft[b.id]!;
        _setDraft(
          b,
          LoggedSet(
            value: n == 0 && kind == UnitKind.weight ? null : n / 100,
            unit: cur.unit,
            reps: cur.reps,
          ),
        );
      },
    );
  }

  Future<void> _pickReps(ExerciseBlock b) {
    final l = L.of(context);
    return _wheel(
      title: l.focusRepsTitle,
      value: _draft[b.id]!.reps ?? 0,
      values: [for (var i = 0; i <= 100; i++) i],
      presets: [
        for (final p in _presets(b))
          if (p.reps case final r? when r <= 100) r,
      ],
      label: (n) => n == 0 ? '—' : l.repsCount(n),
      onChanged: (n) {
        final cur = _draft[b.id]!;
        _setDraft(
          b,
          LoggedSet(value: cur.value, unit: cur.unit, reps: n == 0 ? null : n),
        );
      },
    );
  }

  /// Nothing to log yet: the value wheel, then the reps wheel.
  Future<void> _pickBoth(ExerciseBlock b) async {
    await _pickValue(b);
    if (!mounted || !_rests(_draft[b.id]!)) return;
    await _pickReps(b);
  }

  Future<void> _pickRest(ExerciseBlock b) {
    final l = L.of(context);
    final rest = _link.rest;
    final now = _restsOn(b)
        ? rest.length.inSeconds
        : (_link.restFor?.call(b) ?? const Duration(seconds: 90)).inSeconds;
    return _wheel(
      title: l.focusRestTitle,
      value: now.clamp(15, 600),
      values: [for (var i = 15; i <= 600; i += 15) i],
      presets: const [60, 90, 120, 180],
      label: _clock,
      onChanged: (s) {
        _link.onRestChanged?.call(b, Duration(seconds: s));
        if (_restsOn(b)) rest.add(Duration(seconds: s) - rest.length);
        setState(() {});
      },
    );
  }

  // ---- Build.

  @override
  Widget build(BuildContext context) {
    final link = _link;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: _P.bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: kStageMaxTextScale,
        child: CupertinoTheme(
          data: _dark,
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: _P.text),
            child: ListenableBuilder(
              listenable: Listenable.merge([link, link.rest, ?link.recovery]),
              builder: (context, _) {
                final b = _block;
                Widget child;
                if (b == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _close());
                  child = const SizedBox.expand();
                } else if (_summary) {
                  child = SafeArea(child: _summaryView(context, b));
                } else {
                  _ensure(b);
                  child = _stage(context, b);
                }
                return PopScope(
                  // Android back collapses; locked, it only nudges.
                  canPop: !_locked,
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

  Widget _stage(BuildContext context, ExerciseBlock b) {
    final rest = _link.rest;
    return StageWaterScope(
      water: _water,
      child: Stack(
        fit: StackFit.expand,
        children: [
          StageFlood(water: _water),
          StageEndPulse(
            listenable: rest,
            beat: () {
              final left = _ceil(rest.remaining);
              return _restsOn(b) && left >= 1 && left <= 3 ? left : null;
            },
          ),
          SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              // « » carry the screen reader actions.
              excludeFromSemantics: true,
              onHorizontalDragEnd: _swipe,
              child: _body(context, b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gate(String label, Widget child) => StageGate(
    locked: _locked,
    label: label,
    onBlocked: _nudgeLock,
    child: child,
  );

  Widget _body(BuildContext context, ExerciseBlock b) {
    final l = L.of(context);
    final link = _link, rest = link.rest;
    final blocks = link.blocks;
    final short = MediaQuery.sizeOf(context).height < 700;
    final timer = _isTimer(b);
    final resting = _restsOn(b);
    final v = _draft[b.id]!;
    final s = _sugg[b.id]!;
    final done = !timer && planDone(b, hadPlan: _hadPlan[b.id] ?? false);
    final n = _setNumber(b);
    final next = _index + 1 < blocks.length ? blocks[_index + 1] : null;

    final String status;
    if (resting) {
      status = l.timingRest;
    } else if (timer) {
      status = l.timerSheetTitle;
    } else {
      final source = done
          ? l.focusPlanDone
          : _edited.contains(b.id)
          ? null
          : switch (s.source) {
              FocusSource.planned => l.focusPlanned,
              FocusSource.lastTime => l.focusLastTimeSame,
              FocusSource.lastSet => l.focusSameAsLast,
              FocusSource.setup => l.focusFromSetup,
              FocusSource.none => l.focusPickValues,
            };
      status = [l.focusSetLabel(n), ?source].join(' · ');
    }

    // Top strip: a shared timer started over the stage.
    final shared = link.sharedTimerRunning && link.onOpenSharedTimer != null
        ? GestureDetector(
            key: const ValueKey('focus-shared-timer'),
            behavior: HitTestBehavior.opaque,
            onTap: link.onOpenSharedTimer,
            child: Semantics(
              button: true,
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _P.fillWork,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: stageOneLine(
                  l.focusSharedTimer,
                  _label.copyWith(color: _P.onFill),
                ),
              ),
            ),
          )
        : null;

    final restPill = rest.running && !resting && _find(_ownerId) != null
        ? _Pill(
            key: const ValueKey('focus-rest-pill'),
            text: l.focusRestLength(_clock(_ceil(rest.remaining))),
            a11y: l.focusRestPillA11y(_clock(_ceil(rest.remaining))),
            onTap: _locked ? _nudgeLock : () => _goTo(_ownerId!),
          )
        : null;
    final undo = _undo == null
        ? null
        : _gate(
            l.focusUndo,
            _Pill(
              key: const ValueKey('focus-undo'),
              text: l.focusUndo,
              a11y: l.focusUndo,
              icon: CupertinoIcons.arrow_uturn_left,
              onTap: _takeBack,
            ),
          );

    Widget faces(String text, TextStyle style, {Key? key, bool sub = true}) =>
        StageFaces(
          builder: (ink) => Text(
            text,
            key: ink.first ? key : null,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style.copyWith(color: sub ? ink.sub : ink.main),
          ),
        );

    final heart = link.recovery;
    final String? heartLine = !resting || heart == null
        ? null
        : heart.recovered
        ? l.focusHeartBack
        : heart.fresh && heart.bpm != null && heart.target != null
        ? l.timingHeart(heart.bpm!, heart.target!)
        : null;

    // Long words on a narrow phone shrink the top row's buttons instead of
    // pushing it over the edge.
    final width = MediaQuery.sizeOf(context).width;
    Widget fit(double share, Widget child) => ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width * share),
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?shared,
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              fit(
                0.32,
                _gate(l.timerCollapseA11y, StageCollapseButton(onTap: _close)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StageFaces(
                  builder: (ink) => Text(
                    l.focusExerciseOf(_index + 1, blocks.length),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _small.copyWith(color: ink.sub, fontFeatures: _tnum),
                  ),
                ),
              ),
              if (restPill != null) ...[
                const SizedBox(width: 8),
                fit(0.25, restPill),
              ],
              if (undo != null) ...[const SizedBox(width: 8), fit(0.25, undo)],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: StageFaces(
            builder: (ink) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                b.name,
                key: ink.first ? const ValueKey('focus-name') : null,
                maxLines: 1,
                style: _title1.copyWith(color: ink.main),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          // Read when the state changes only.
          child: Semantics(
            container: true,
            liveRegion: true,
            label: status,
            child: ExcludeSemantics(
              child: StageFaces(
                builder: (ink) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    status,
                    key: ink.first ? const ValueKey('focus-label') : null,
                    maxLines: 1,
                    style: _title3.copyWith(color: ink.sub),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: short ? 2 : 8),
        Expanded(child: _hero(context, b, v, n, resting, timer)),
        if (!resting && !timer && s.lastTimeSame != null)
          faces(
            l.focusLastTimeLine(_setText(l, s.lastTimeSame!, link.weightUnit)),
            const TextStyle(fontSize: 13, height: 18 / 13),
            key: const ValueKey('focus-last-line'),
          ),
        if (heartLine != null)
          faces(
            heartLine,
            _title3,
            key: const ValueKey('focus-heart'),
            sub: false,
          ),
        SizedBox(height: short ? 6 : 12),
        if (!timer)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: resting ? _restControls(l, b) : _liftControls(l, b, v),
          ),
        if (!timer && b.sets.isNotEmpty) ...[
          SizedBox(height: short ? 6 : 8),
          _chips(l, b),
        ],
        SizedBox(height: short ? 8 : 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _barRow(l, b, v, resting: resting, timer: timer),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _bottomRow(l, b, done ? next : null),
        ),
        SizedBox(height: short ? 8 : 24),
      ],
    );
  }

  /// The big number, drawn twice over the waterline.
  Widget _hero(
    BuildContext context,
    ExerciseBlock b,
    LoggedSet v,
    int n,
    bool resting,
    bool timer,
  ) {
    final l = L.of(context);
    final win = MediaQuery.sizeOf(context);
    TextStyle big(Color c, double size) => TextStyle(
      fontSize: size,
      height: 1.0,
      fontWeight: FontWeight.w700,
      fontFeatures: _tnum,
      color: c,
    );
    if (timer) {
      final spec = TimingSpec.parse(b.name)!;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: StageFaces(
            builder: (ink) => Text(
              spec.summary(l),
              key: ink.first ? const ValueKey('focus-timer-summary') : null,
              textAlign: TextAlign.center,
              style: _title1.copyWith(color: ink.main, fontFeatures: _tnum),
            ),
          ),
        ),
      );
    }
    final String a11y;
    final InlineSpan Function(Color c, double size) span;
    String? subline;
    if (resting) {
      final left = _ceil(_link.rest.remaining);
      a11y = l.focusRestA11y(_clock(left));
      span = (c, f) => TextSpan(text: _big(left), style: big(c, f));
      subline = l.focusNextUp(
        '${l.focusSetLabel(n)} ${_setText(l, v, _link.weightUnit)}',
      );
    } else {
      a11y = l.focusHeroA11y(
        [
          l.focusSetLabel(n),
          _spokenSet(l, v),
        ].where((e) => e.isNotEmpty).join(', '),
      );
      final (head, tail) = switch (kindOf(v)) {
        _ when v.value == null && v.reps == null => ('— × —', null),
        FocusKind.weight => (
          formatNumber(v.value!),
          ' ${_unit(v.unit)} × ${v.reps ?? '—'}',
        ),
        FocusKind.reps => (l.repsCount(v.reps!), null),
        FocusKind.duration => (_clock(_seconds(v)), null),
        FocusKind.distance => (formatNumber(v.value!), ' ${_unit(v.unit)}'),
      };
      span = (c, f) => TextSpan(
        text: head,
        style: big(c, f),
        children: [
          if (tail != null) TextSpan(text: tail, style: big(c, f * 0.34)),
        ],
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: win.width * 0.05),
      child: Semantics(
        container: true,
        label: a11y,
        child: ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, box) {
              // Sized to fit at about 1:1: a huge line scaled far down by the
              // FittedBox is dropped by the iOS text renderer.
              final probe = TextPainter(
                text: span(_P.text, 100),
                textDirection: Directionality.of(context),
                textScaler: TextScaler.noScaling,
                maxLines: 1,
              )..layout();
              final size = math.max(
                1.0,
                [
                  win.height * 0.45,
                  box.maxHeight - (subline == null ? 0 : 44),
                  100 * box.maxWidth / math.max(1.0, probe.width),
                ].reduce(math.min),
              );
              probe.dispose();
              return StageFaces(
                builder: (ink) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        key: ink.first ? const ValueKey('focus-hero') : null,
                        fit: BoxFit.scaleDown,
                        child: Text.rich(
                          span(ink.main, size),
                          maxLines: 1,
                          softWrap: false,
                          textScaler: TextScaler.noScaling,
                        ),
                      ),
                    ),
                    if (subline != null)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          subline,
                          key: ink.first
                              ? const ValueKey('focus-next-up')
                              : null,
                          maxLines: 1,
                          style: _title3.copyWith(
                            color: ink.main,
                            fontFeatures: _tnum,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Weight (or time, distance) and reps: [−] value [+], a wheel on the value.
  Widget _liftControls(L l, ExerciseBlock b, LoggedSet v) {
    final kind = kindOf(v);
    final unitKind = unitById[v.unit]?.kind ?? UnitKind.weight;
    final step = formatValue(valueStep(v.unit), v.unit);
    final value = _Stepper(
      id: 'value',
      title: switch (unitKind) {
        UnitKind.weight => l.focusWeightTitle,
        UnitKind.duration => l.timerTime,
        UnitKind.distance => l.focusDistanceTitle,
      },
      text: v.value == null
          ? (unitKind == UnitKind.weight ? l.focusBodyweight : '—')
          : kind == FocusKind.duration
          ? _clock(_seconds(v))
          : formatValue(v.value!, v.unit),
      less: l.focusWeightDown(step),
      more: l.focusWeightUp(step),
      onLess: (v.value ?? 0) > 0
          ? () => _setDraft(b, stepValue(_draft[b.id]!, -1))
          : null,
      onMore: () => _setDraft(b, stepValue(_draft[b.id]!, 1)),
      onPick: () => _pickValue(b),
      gate: _gate,
    );
    if (!_rests(v)) {
      // Time and distance: no reps; the rest is started by hand.
      final canRest = b.sets.any((s) => s.mine) && !_link.rest.running;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          value,
          if (canRest) ...[
            const SizedBox(height: 8),
            _gate(
              l.focusStartRest,
              StageButton(
                key: const ValueKey('focus-start-rest'),
                label: l.focusStartRest,
                onTap: () => setState(() => _startRest(b, l)),
              ),
            ),
          ],
        ],
      );
    }
    final reps = _Stepper(
      id: 'reps',
      title: l.focusRepsTitle,
      text: v.reps == null ? '—' : l.repsCount(v.reps!),
      less: l.focusRepsDown,
      more: l.focusRepsUp,
      onLess: v.reps != null
          ? () => _setDraft(b, stepReps(_draft[b.id]!, -1))
          : null,
      onMore: () => _setDraft(b, stepReps(_draft[b.id]!, 1)),
      onPick: () => _pickReps(b),
      gate: _gate,
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 400
          ? Row(
              children: [
                Expanded(child: value),
                const SizedBox(width: 12),
                Expanded(child: reps),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [value, const SizedBox(height: 8), reps],
            ),
    );
  }

  /// During the rest: [−15] rest length (a wheel) [+15].
  Widget _restControls(L l, ExerciseBlock b) => _Stepper(
    id: 'rest',
    title: l.focusRestTitle,
    text: l.focusRestLength(_clock(_link.rest.length.inSeconds)),
    less: l.focusRestLess,
    more: l.focusRestMore,
    onLess: () => _restBy(b, -15),
    onMore: () => _restBy(b, 15),
    onPick: () => _pickRest(b),
    gate: _gate,
  );

  /// Today's sets of this block: mine done (white), planned (outlined), the
  /// one up next (thick border), others' dimmed and untouchable. A tap on
  /// mine takes its numbers (nothing is written).
  Widget _chips(L l, ExerciseBlock b) {
    final planned = _sugg[b.id]?.plannedId;
    return SizedBox(
      height: 44,
      child: Semantics(
        label: l.focusTodaySets,
        container: true,
        child: ListView.separated(
          key: const ValueKey('focus-chips'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: b.sets.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            final s = b.sets[i];
            final text =
                '${i + 1}  ${cellLabel(s, shared: _link.weightUnit, formatReps: l.repsCount)}';
            final chip = Container(
              key: ValueKey('focus-chip-$i'),
              constraints: const BoxConstraints(minWidth: 56),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: s.done ? _P.surface2 : _P.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: s.id == planned ? _P.text : _P.outline,
                  width: s.id == planned ? 2.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                text,
                maxLines: 1,
                style: _label.copyWith(
                  color: s.done ? _P.text : _P.textSecondary,
                  fontFeatures: _tnum,
                ),
              ),
            );
            if (s.theirs) {
              return Opacity(
                opacity: 0.4,
                child: IgnorePointer(
                  child: Semantics(label: s.author, child: chip),
                ),
              );
            }
            return _gate(
              text,
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: s.value == null && s.reps == null
                    ? null
                    : () => _setDraft(
                        b,
                        LoggedSet(value: s.value, unit: s.unit, reps: s.reps),
                      ),
                child: chip,
              ),
            );
          },
        ),
      ),
    );
  }

  /// [«] the bar [»]: Done, Next set now (resting), Set weight and reps
  /// (nothing to log), Start timer (a timer block).
  Widget _barRow(
    L l,
    ExerciseBlock b,
    LoggedSet v, {
    required bool resting,
    required bool timer,
  }) {
    final cool = _cool != null;
    final StageBar bar;
    if (timer) {
      bar = StageBar(
        key: const ValueKey('focus-start-timer'),
        icon: CupertinoIcons.play_fill,
        label: l.focusStartTimer,
        onTap: _link.onStartTimer == null ? null : () => _link.onStartTimer!(b),
      );
    } else if (resting) {
      bar = StageBar(
        key: const ValueKey('focus-skip'),
        icon: CupertinoIcons.forward_end_fill,
        label: l.focusNextSetNow,
        onTap: cool ? null : _link.rest.skip,
      );
    } else if (!canLog(v)) {
      bar = StageBar(
        key: const ValueKey('focus-pick'),
        icon: CupertinoIcons.slider_horizontal_3,
        label: l.focusPickButton,
        onTap: () => _pickBoth(b),
      );
    } else {
      bar = StageBar(
        key: const ValueKey('focus-done'),
        icon: CupertinoIcons.checkmark_alt,
        label: l.focusDone,
        onTap: cool ? null : () => _log(b),
      );
    }
    final blocks = _link.blocks;
    Widget side(int delta) {
      final i = _index + delta;
      if (i < 0 || i >= blocks.length) return const SizedBox(width: 56);
      final label = delta < 0 ? l.focusPrevExercise : l.focusNextExerciseA11y;
      return _gate(
        label,
        StageRoundButton(
          key: ValueKey(delta < 0 ? 'focus-prev' : 'focus-next'),
          icon: delta < 0
              ? CupertinoIcons.chevron_left_2
              : CupertinoIcons.chevron_right_2,
          label: label,
          onTap: () => _go(delta),
        ),
      );
    }

    return Row(
      children: [
        side(-1),
        const SizedBox(width: 12),
        Expanded(child: _gate(bar.label, bar)),
        const SizedBox(width: 12),
        side(1),
      ],
    );
  }

  /// [lock] and [Finish exercise], or — the plan done — [Next: Squat →].
  /// Locked, the slot says how to unlock and lights up on a touch.
  Widget _bottomRow(L l, ExerciseBlock b, ExerciseBlock? next) {
    final Widget slot;
    if (_locked) {
      slot = GestureDetector(
        key: const ValueKey('focus-locked-hint'),
        behavior: HitTestBehavior.opaque,
        onTap: _nudgeLock,
        child: Opacity(
          opacity: _bright ? 0.9 : StageGate.dim + 0.15,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: _P.bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _P.outline, width: 1.5),
            ),
            alignment: Alignment.center,
            child: stageOneLine(
              l.timerLockedHint,
              _label.copyWith(color: _P.text),
            ),
          ),
        ),
      );
    } else if (next != null) {
      slot = StageButton(
        key: const ValueKey('focus-next-exercise'),
        label: '${l.focusNextExercise(next.name)} →',
        primary: true,
        onTap: () => _goTo(next.id),
      );
    } else {
      slot = StageButton(
        key: const ValueKey('focus-finish'),
        label: l.focusExerciseDone,
        onTap: () => setState(() => _summary = true),
      );
    }
    return Row(
      children: [
        StageLockButton(
          key: const ValueKey('focus-lock'),
          locked: _locked,
          onToggle: _toggleLock,
        ),
        const SizedBox(width: 12),
        Expanded(child: slot),
      ],
    );
  }

  // ---- Summary.

  /// "1200kg", "4:30", "5km", "36회" for [st]'s total.
  String _total(L l, FocusStats st) => switch (st.kind) {
    FocusKind.weight => formatValue((st.total * 10).round() / 10, st.unit),
    FocusKind.duration => _clock(
      (st.total * (baseFactor[st.unit] ?? 1)).round(),
    ),
    FocusKind.distance => formatValue((st.total * 100).round() / 100, st.unit),
    FocusKind.reps => l.repsCount(st.total.round()),
  };

  /// Today minus last time, in today's unit: "+120kg", "Same", "−40kg".
  String? _diff(L l, FocusStats now, FocusStats then) {
    if (now.kind != then.kind) return null;
    var before = then.total;
    if (now.kind == FocusKind.weight && then.unit != now.unit) {
      before = now.unit == 'lb' ? before * 2.20462 : before / 2.20462;
    } else if (now.kind == FocusKind.duration ||
        now.kind == FocusKind.distance) {
      before =
          before * (baseFactor[then.unit] ?? 1) / (baseFactor[now.unit] ?? 1);
    }
    final d = now.total - before;
    final r = (d * 10).round() / 10;
    if (r == 0) return l.focusSame;
    final sign = r > 0 ? '+' : '−';
    final abs = r.abs();
    final text = switch (now.kind) {
      FocusKind.weight || FocusKind.distance => formatValue(abs, now.unit),
      FocusKind.duration => _clock((abs * (baseFactor[now.unit] ?? 1)).round()),
      FocusKind.reps => l.repsCount(abs.round()),
    };
    return '$sign$text';
  }

  Widget _summaryView(BuildContext context, ExerciseBlock b) {
    final l = L.of(context);
    final link = _link;
    final st = stats(b.sets);
    final last = link.lastTime?.call(b);
    final then = last == null ? null : stats(last.sets);
    final next = _index + 1 < link.blocks.length
        ? link.blocks[_index + 1]
        : null;
    const secondary = TextStyle(fontSize: 15, color: _P.textSecondary);
    final best = st.best;
    final rows = [
      (l.focusSets, '${st.sets}'),
      (
        switch (st.kind) {
          FocusKind.weight => l.focusVolume,
          FocusKind.duration => l.focusTotalTime,
          FocusKind.distance => l.focusTotalDistance,
          FocusKind.reps => l.focusTotalReps,
        },
        _total(l, st),
      ),
      if (best != null) (l.focusBest, _setText(l, best, link.weightUnit)),
    ];
    final diff = then == null ? null : _diff(l, st, then);
    final mine = b.sets.where((s) => s.mine).toList();
    return CustomScrollView(
      key: const ValueKey('focus-summary'),
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
                  l.focusSummaryTitle(b.name),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _title1.copyWith(color: _P.text),
                ),
                const SizedBox(height: 16),
                if (mine.isNotEmpty)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (i, s) in mine.indexed)
                        Container(
                          constraints: const BoxConstraints(
                            minHeight: 44,
                            minWidth: 56,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _P.surface2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            widthFactor: 1,
                            heightFactor: 1,
                            child: Text(
                              '${i + 1}  ${cellLabel(s, shared: link.weightUnit, formatReps: l.repsCount)}',
                              style: _label.copyWith(
                                color: _P.text,
                                fontFeatures: _tnum,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 24),
                Wrap(
                  key: const ValueKey('focus-summary-rows'),
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    for (final (label, value) in rows)
                      MergeSemantics(
                        child: Column(
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
                      ),
                  ],
                ),
                if (last != null && then != null) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        l.focusLastTime(
                          DateFormat.MMMd(l.localeName).format(last.at),
                          _total(l, then),
                        ),
                        key: const ValueKey('focus-last-time'),
                        textAlign: TextAlign.center,
                        style: secondary,
                      ),
                      if (diff != null)
                        Container(
                          key: const ValueKey('focus-diff'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _P.surface2,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            diff,
                            style: _label.copyWith(
                              color: _P.text,
                              fontFeatures: _tnum,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const Spacer(),
                const SizedBox(height: 16),
                if (next != null) ...[
                  StageButton(
                    key: const ValueKey('focus-summary-next'),
                    label: '${l.focusNextExercise(next.name)} →',
                    primary: true,
                    onTap: () => _goTo(next.id),
                  ),
                  const SizedBox(height: 8),
                ],
                StageButton(
                  key: const ValueKey('focus-one-more'),
                  label: l.focusOneMore,
                  primary: next == null,
                  onTap: () => setState(() => _summary = false),
                ),
                const SizedBox(height: 8),
                StageButton(
                  key: const ValueKey('focus-summary-close'),
                  label: l.timerCollapse,
                  onTap: _close,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The flood level; [repaint] tells the flood and the clips to paint again
/// at an unchanged level.
class _Water extends ChangeNotifier implements ValueListenable<StageWater> {
  StageWater _value = (level: 0, fill: _P.fillRest);

  @override
  StageWater get value => _value;
  set value(StageWater v) {
    if (v == _value) return;
    _value = v;
    notifyListeners();
  }

  void repaint() => notifyListeners();
}

/// [−] value [+]: the value cell opens a wheel; − and + repeat while held.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.id,
    required this.title,
    required this.text,
    required this.less,
    required this.more,
    required this.onLess,
    required this.onMore,
    required this.onPick,
    required this.gate,
  });
  final String id, title, text, less, more;
  final VoidCallback? onLess, onMore;
  final VoidCallback onPick;
  final Widget Function(String label, Widget child) gate;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      gate(
        less,
        StageStepKey(
          key: ValueKey('focus-$id-less'),
          icon: CupertinoIcons.minus,
          label: less,
          onStep: onLess,
        ),
      ),
      Expanded(
        child: gate(
          title,
          Semantics(
            button: true,
            label: title,
            value: text,
            onTap: onPick,
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('focus-$id-value'),
              behavior: HitTestBehavior.opaque,
              onTap: onPick,
              child: Container(
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: _P.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _P.outline, width: 1.5),
                ),
                alignment: Alignment.center,
                child: stageOneLine(
                  text,
                  const TextStyle(
                    fontSize: 22,
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
      ),
      gate(
        more,
        StageStepKey(
          key: ValueKey('focus-$id-more'),
          icon: CupertinoIcons.plus,
          label: more,
          onStep: onMore,
        ),
      ),
    ],
  );
}

/// A 44 pt pill on its own dark ground (the rest pill, undo).
class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.text,
    required this.a11y,
    required this.onTap,
    this.icon,
  });
  final String text, a11y;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: a11y,
    onTap: onTap,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: icon == null ? _P.fillRest : _P.text,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: _P.bg),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  maxLines: 1,
                  style: _small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _P.onFill,
                    fontFeatures: _tnum,
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
