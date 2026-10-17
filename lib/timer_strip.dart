import 'package:flutter/cupertino.dart';

import 'l10n/generated/app_localizations.dart';
import 'palette.dart';
import 'run_link.dart';
import 'timer_sheet.dart' show TimerMiniBar;
import 'workout_timing.dart';

/// Rounds finished when a run is over: all of them on completion, the ones
/// whose work ended when stopped early.
int roundsDone(WorkoutTimer timer) {
  final spec = timer.spec;
  if (spec == null || !spec.tabata) return 0;
  if (timer.phase == TimingPhase.complete) return spec.rounds;
  return switch (timer.phase) {
    TimingPhase.ready => 0,
    TimingPhase.work => timer.round - 1,
    _ => timer.round,
  };
}

/// Finished rounds not logged as sets yet.
int unloggedRounds(WorkoutTimer timer, RunLink link) {
  if (link.logged) return 0;
  final logged = link.roundReps.whereType<int>().length;
  return (roundsDone(timer) - logged).clamp(0, 99);
}

/// A finished run still owes sets: tabata rounds, or a metronome's count.
/// The one rule for the card's [적기] and for every ask before another run
/// replaces this one (▶ elsewhere, together, the timer sheet).
bool owesLog(WorkoutTimer timer, RunLink link) {
  final spec = timer.spec;
  if (spec == null ||
      !(timer.phase == TimingPhase.complete || timer.endedEarly)) {
    return false;
  }
  return spec.tabata
      ? unloggedRounds(timer, link) > 0
      : !link.logged && timer.count > 0;
}

/// What [owesLog] owes, the way the ask says it: rounds, or reps.
String owesText(L l, WorkoutTimer timer, RunLink link) =>
    timer.spec?.tabata ?? false
    ? l.timerUnloggedAsk(unloggedRounds(timer, link))
    : l.timerUnloggedReps(timer.count);

/// The timer line on an exercise card. Waiting: preview, summary, ▶ start
/// (and "together ▾" in a session). Running with the stage folded: phase
/// colour, the number, the phase and round, pause and open. Over: what was
/// done, log and reset. The stage does the rest.
class TimerStrip extends StatelessWidget {
  const TimerStrip({
    super.key,
    required this.owner,
    required this.spec,
    required this.timer,
    required this.link,
    required this.onStart,
    required this.onOpen,
    required this.onEdit,
    this.target,
    this.together,
  });
  final Object owner;
  final TimingSpec spec;
  final WorkoutTimer timer;
  final RunLink link;

  /// Metronome goal shown in the summary.
  final int? target;

  /// Only while recording together.
  final TogetherTiming? together;

  /// ▶ start alone.
  final VoidCallback onStart;

  /// Open the stage (also its summary).
  final VoidCallback onOpen;

  /// Open the timer sheet.
  final VoidCallback onEdit;

  bool get _canAlternate =>
      spec.tabata && spec.work + 2 * spec.rest <= TimingSpec.maxSeconds;

  void _together(BuildContext context) {
    final duo = together!;
    if (!_canAlternate) {
      duo.onPropose(false);
      return;
    }
    final l = L.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheet) => CupertinoActionSheet(
        actions: [
          for (final (label, alternate) in [
            (l.togetherStart, false),
            (l.togetherAlternate, true),
          ])
            CupertinoActionSheetAction(
              key: ValueKey(
                alternate ? 'together-alternate' : 'together-simultaneous',
              ),
              onPressed: () {
                Navigator.pop(sheet);
                duo.onPropose(alternate);
              },
              child: Text(label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheet),
          child: Text(l.cancel),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([timer, link]),
    builder: (context, _) {
      final selected = identical(timer.owner, owner);
      final over =
          selected && (timer.phase == TimingPhase.complete || timer.endedEarly);
      final going =
          selected && !over && (timer.running || timer.elapsed > Duration.zero);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: !spec.valid
            ? _invalid(context)
            : over
            ? _over(context)
            : going
            ? _going(context)
            : together?.waiting ?? false
            ? _waiting(context)
            : _idle(context),
      );
    },
  );

  Widget _invalid(BuildContext context) => GestureDetector(
    onTap: onEdit,
    behavior: HitTestBehavior.opaque,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          L.of(context).timingInvalid,
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ),
    ),
  );

  Widget _idle(BuildContext context) {
    final l = L.of(context);
    final duo = together;
    final canPropose =
        duo != null && !duo.live && !duo.waiting && !duo.busy && spec.valid;
    final summary = GestureDetector(
      key: const ValueKey('timer-summary'),
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Text(
        spec.summary(l, target: target),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    final buttons = [
      _Pill(
        key: const ValueKey('timer-start'),
        icon: CupertinoIcons.play_fill,
        label: l.timingStart,
        onPressed: onStart,
      ),
      if (canPropose) ...[
        const SizedBox(width: 6),
        _Pill(
          key: const ValueKey('together-start'),
          label: l.timerTogether,
          trailing: _canAlternate ? CupertinoIcons.chevron_down : null,
          onPressed: () => _together(context),
        ),
      ],
    ];
    // Large text or long labels: the summary drops under the strip instead
    // of shrinking away, and the pills wrap rather than overflow.
    return LayoutBuilder(
      builder: (context, box) {
        final pills =
            _Pill.widthOf(context, l.timingStart, icon: true) +
            (canPropose
                ? 6 +
                      _Pill.widthOf(
                        context,
                        l.timerTogether,
                        icon: _canAlternate,
                      )
                : 0);
        final wide =
            MediaQuery.textScalerOf(context).scale(13) > 15 ||
            28 + 16 + 72 + pills > box.maxWidth;
        return wide ? _stacked(buttons, summary) : _inline(buttons, summary);
      },
    );
  }

  Widget _stacked(List<Widget> buttons, Widget summary) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          TimerMiniBar(spec: spec),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final b in buttons)
                  if (b is! SizedBox) b,
              ],
            ),
          ),
        ],
      ),
      summary,
    ],
  );

  Widget _inline(List<Widget> buttons, Widget summary) {
    return Row(
      children: [
        TimerMiniBar(spec: spec),
        const SizedBox(width: 8),
        Expanded(child: summary),
        const SizedBox(width: 8),
        ...buttons,
      ],
    );
  }

  Widget _waiting(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final duo = together!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.togetherWaiting(duo.partner),
                style: TextStyle(fontSize: 14, color: muted),
              ),
            ),
            CupertinoButton(
              key: const ValueKey('together-cancel'),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(44, 44),
              onPressed: duo.onCancel,
              child: Text(l.cancel, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        Text(
          l.togetherWaitingHint,
          style: TextStyle(fontSize: 12, color: muted),
        ),
      ],
    );
  }

  Widget _going(BuildContext context) {
    final l = L.of(context);
    final phase = timer.phase;
    final paused = !timer.running;
    final color = paused
        ? CupertinoColors.systemGrey.resolveFrom(context)
        : switch (phase) {
            TimingPhase.ready => CupertinoColors.systemOrange,
            TimingPhase.work => CupertinoColors.systemRed,
            _ => CupertinoColors.systemBlue,
          }.resolveFrom(context);
    final number = !spec.tabata && phase == TimingPhase.work
        ? '${timer.count}'
        : timer.remaining < 60
        ? '${timer.remaining}'
        : timerClock(timer.remaining);
    final label = [
      if (paused)
        l.timerPaused
      else
        switch (phase) {
          TimingPhase.ready => l.timingReady,
          TimingPhase.work => l.timingWork,
          TimingPhase.rest => l.timingRest,
          TimingPhase.complete => l.timingComplete,
        },
      if (spec.tabata)
        l.timerRoundShort(timer.round, spec.rounds)
      else if (spec.bpm != null)
        l.timingBpm(spec.bpm!),
    ].join(' · ');
    final ink = seal.resolveFrom(context);
    return GestureDetector(
      key: const ValueKey('timer-strip-open'),
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            number,
            key: const ValueKey('timer-strip-number'),
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: paused ? color : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // Together, pausing alone is leaving — that lives on the stage.
          if (!timer.shared)
            CupertinoButton(
              key: const ValueKey('timer-strip-pause'),
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              onPressed: paused ? timer.resume : timer.pause,
              child: Icon(
                paused ? CupertinoIcons.play_fill : CupertinoIcons.pause_fill,
                size: 20,
                color: ink,
                semanticLabel: paused ? l.timerResume : l.timingPause,
              ),
            ),
          CupertinoButton(
            key: const ValueKey('timer-strip-expand'),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(44, 44),
            onPressed: onOpen,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.timerOpen, style: TextStyle(fontSize: 14, color: ink)),
                Icon(CupertinoIcons.chevron_right, size: 14, color: ink),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _over(BuildContext context) {
    final l = L.of(context);
    final time = timerClock(timer.elapsed.inSeconds);
    final line = spec.tabata
        ? l.timerDoneLine(roundsDone(timer), time)
        : l.timerDoneBpmLine(timer.count, time);
    final owes = owesLog(timer, link);
    final ink = seal.resolveFrom(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            line,
            key: const ValueKey('timer-done-line'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (owes)
          Flexible(
            child: CupertinoButton(
              key: const ValueKey('timer-log-now'),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(44, 44),
              onPressed: onOpen,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.timerLogNow,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                    Icon(CupertinoIcons.chevron_right, size: 14, color: ink),
                  ],
                ),
              ),
            ),
          ),
        CupertinoButton(
          key: const ValueKey('timer-reset'),
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 44),
          onPressed: timer.reset,
          child: Icon(
            CupertinoIcons.arrow_counterclockwise,
            size: 18,
            color: ink,
            semanticLabel: l.timingReset,
          ),
        ),
      ],
    );
  }
}

/// 44 pt seal pill.
class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailing,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon, trailing;

  /// The width this pill takes with [label] at the current text size.
  static double widthOf(
    BuildContext context,
    String label, {
    bool icon = false,
  }) {
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      maxLines: 1,
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    )..layout();
    final width = text.width + 28 + (icon ? 18 : 0);
    text.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final ink = seal.resolveFrom(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      minimumSize: const Size(44, 44),
      color: sealTint.resolveFrom(context),
      borderRadius: BorderRadius.circular(22),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: ink),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            Icon(trailing, size: 12, color: ink),
          ],
        ],
      ),
    );
  }
}
