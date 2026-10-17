import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';

import 'l10n/generated/app_localizations.dart';
import 'palette.dart';
import 'workout_timing.dart';

/// The tabata word a new name gets in this language — one the parser reads.
String tabataWord(String languageCode) => switch (languageCode) {
  'ko' => '타바타',
  'ja' => 'タバタ',
  _ => 'Tabata',
};

/// The name a new metronome card gets.
const newBpmName = '${TimingSpec.newBpm}bpm';

/// What the sheet's [완료] writes: the new name (the title is the timer) and
/// the metronome goal (0 = none).
typedef TimerSheetResult = ({String name, int target});

/// The name the sheet writes for these switches. Unchanged settings keep the
/// name as typed; values change in place; a switch turned off drops its tokens
/// ([TimingSpec.removeFrom]). Null when nothing would be left of the name.
String? timerSheetName(
  String name,
  TimingSpec? next, {
  String tabataWord = 'Tabata',
}) {
  final old = TimingSpec.parse(name);
  if (next == null) {
    final bare = TimingSpec.removeFrom(name);
    return bare.isEmpty ? null : bare;
  }
  if (old == next) return name.trim();
  final sameKinds =
      old != null &&
      old.tabata == next.tabata &&
      (old.bpm == null) == (next.bpm == null);
  final base = sameKinds ? name : TimingSpec.removeFrom(name);
  return next.applyTo(base, tabataWord: tabataWord).trim();
}

/// The timer sheet: tabata and metronome switches, their values, sound and
/// vibration. Returns null when dismissed.
Future<TimerSheetResult?> showTimerSheet(
  BuildContext context, {
  required String name,
  required int target,
  bool readOnly = false,
  String? readOnlyNote,
  bool countAloud = false,
  ValueChanged<bool>? onCountAloud,
  bool haptics = true,
  ValueChanged<bool>? onHaptics,
}) => showCupertinoModalPopup<TimerSheetResult>(
  context: context,
  builder: (_) => TimerSheet(
    name: name,
    target: target,
    readOnly: readOnly,
    readOnlyNote: readOnlyNote,
    countAloud: countAloud,
    onCountAloud: onCountAloud,
    haptics: haptics,
    onHaptics: onHaptics,
  ),
);

class TimerSheet extends StatefulWidget {
  const TimerSheet({
    super.key,
    required this.name,
    required this.target,
    this.readOnly = false,
    this.readOnlyNote,
    this.countAloud = false,
    this.onCountAloud,
    this.haptics = true,
    this.onHaptics,
  });
  final String name;
  final int target;
  final bool readOnly, countAloud, haptics;

  /// Why it is read-only, when not because the timer is going.
  final String? readOnlyNote;
  final ValueChanged<bool>? onCountAloud, onHaptics;

  @override
  State<TimerSheet> createState() => _TimerSheetState();
}

class _TimerSheetState extends State<TimerSheet> {
  late final _old = TimingSpec.parse(widget.name);
  late bool _tabata = _old?.tabata ?? false;
  late bool _beat = _old?.bpm != null;
  late int _work = _old?.work ?? 20,
      _rest = _old?.rest ?? 10,
      _rounds = _old?.rounds ?? 8,
      // A bare 'bpm' reads as 120 (old titles); a new metronome starts at 60.
      _bpm = (_old?.bpm ?? TimingSpec.newBpm).clamp(
        TimingSpec.minBpm,
        TimingSpec.maxBpm,
      ),
      _target = widget.target;
  late bool _aloud = widget.countAloud, _buzz = widget.haptics;

  TimingSpec? get _spec => !_tabata && !_beat
      ? null
      : TimingSpec(
          tabata: _tabata,
          bpm: _beat ? _bpm : null,
          work: _work,
          rest: _rest,
          rounds: _rounds,
        );

  String? get _name => timerSheetName(
    widget.name,
    _spec,
    tabataWord: tabataWord(Localizations.localeOf(context).languageCode),
  );

  Future<void> _pick({
    required String title,
    required int value,
    required List<int> values,
    required List<int> presets,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
  }) => showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => ValueSheet(
      title: title,
      value: value,
      values: values,
      presets: presets,
      label: label,
      onChanged: (v) => setState(() => onChanged(v)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final name = _name;
    final edit = !widget.readOnly;
    final seconds = secondsValues;
    Widget toggle(
      String label,
      bool value,
      ValueChanged<bool>? onChanged,
      Key key,
    ) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      // One node: what the switch turns on, and whether it is on.
      child: MergeSemantics(
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 17))),
            CupertinoSwitch(key: key, value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.timerSheetTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _Done(
                      key: const ValueKey('timer-sheet-done'),
                      bold: true,
                      onPressed: name == null
                          ? null
                          : () => Navigator.pop<TimerSheetResult>(
                              context,
                              edit
                                  ? (
                                      name: name,
                                      target: _beat ? _target : widget.target,
                                    )
                                  : null,
                            ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.readOnly)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            widget.readOnlyNote ?? l.timerReadOnly,
                            style: TextStyle(fontSize: 13, color: muted),
                          ),
                        ),
                      if (name == null)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            l.timerNameNeeded,
                            key: const ValueKey('timer-name-needed'),
                            style: TextStyle(fontSize: 13, color: muted),
                          ),
                        ),
                      toggle(
                        l.timerTabata,
                        _tabata,
                        edit ? (v) => setState(() => _tabata = v) : null,
                        const ValueKey('timer-tabata'),
                      ),
                      if (_tabata) ...[
                        Wrap(
                          children: [
                            _ValueChip(
                              key: const ValueKey('timer-work'),
                              text: l.timingWorkSeconds(_work),
                              onTap: !edit
                                  ? null
                                  : () => _pick(
                                      title: l.timerWorkTitle,
                                      value: _work,
                                      values: seconds,
                                      presets: const [20, 30, 45, 60],
                                      label: l.timerSecondsValue,
                                      onChanged: (v) => _work = v,
                                    ),
                            ),
                            _ValueChip(
                              key: const ValueKey('timer-rest'),
                              text: l.timingRestSeconds(_rest),
                              onTap: !edit
                                  ? null
                                  : () => _pick(
                                      title: l.timerRestTitle,
                                      value: _rest,
                                      values: seconds,
                                      presets: const [10, 15, 30, 60],
                                      label: l.timerSecondsValue,
                                      onChanged: (v) => _rest = v,
                                    ),
                            ),
                            _ValueChip(
                              key: const ValueKey('timer-rounds'),
                              text: l.timingRounds(_rounds),
                              onTap: !edit
                                  ? null
                                  : () => _pick(
                                      title: l.timerRoundsTitle,
                                      value: _rounds,
                                      values: [for (var i = 1; i <= 99; i++) i],
                                      presets: const [4, 6, 8, 10, 12],
                                      label: (n) => '$n',
                                      onChanged: (v) => _rounds = v,
                                    ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              TimerMiniBar(spec: _spec!, width: 64),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  l.timerTotalLine(timerClock(_spec!.duration)),
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: muted,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      toggle(
                        l.timerBeat,
                        _beat,
                        edit ? (v) => setState(() => _beat = v) : null,
                        const ValueKey('timer-beat'),
                      ),
                      if (_beat)
                        Wrap(
                          children: [
                            _ValueChip(
                              key: const ValueKey('timer-bpm'),
                              text: l.timingBpm(_bpm),
                              onTap: !edit
                                  ? null
                                  : () => _pick(
                                      title: l.timerBpmTitle,
                                      value: _bpm,
                                      values: [
                                        for (
                                          var i = TimingSpec.minBpm;
                                          i <= TimingSpec.maxBpm;
                                          i++
                                        )
                                          i,
                                      ],
                                      presets: const [20, 30, 40, 60, 90],
                                      label: l.timingBpm,
                                      onChanged: (v) => _bpm = v,
                                    ),
                            ),
                            _ValueChip(
                              key: const ValueKey('timer-target'),
                              text: _target == 0
                                  ? l.timerNoTarget
                                  : l.timerTargetChip(_target),
                              onTap: !edit
                                  ? null
                                  : () => _pick(
                                      title: l.timerTargetTitle,
                                      value: _target,
                                      values: [
                                        for (var i = 0; i <= 999; i++) i,
                                      ],
                                      presets: const [10, 20, 30, 50, 100],
                                      label: (n) =>
                                          n == 0 ? l.timerNoTarget : '$n',
                                      onChanged: (v) => _target = v,
                                    ),
                            ),
                          ],
                        ),
                      if (widget.onCountAloud != null)
                        toggle(l.countAloud, _aloud, (v) {
                          setState(() => _aloud = v);
                          widget.onCountAloud!(v);
                        }, const ValueKey('timer-aloud')),
                      if (widget.onHaptics != null)
                        toggle(l.timerHaptics, _buzz, (v) {
                          setState(() => _buzz = v);
                          widget.onHaptics!(v);
                        }, const ValueKey('timer-haptics')),
                    ],
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

/// Seconds on the wheel: every second to a minute, then every 5 to 600.
final secondsValues = [
  for (var i = TimingSpec.minSeconds; i <= 60; i++) i,
  for (var i = 65; i <= TimingSpec.maxSeconds; i += 5) i,
];

/// One value: [−] big number [+] (hold repeats), a wheel and presets. Every
/// change is applied at once through [onChanged].
class ValueSheet extends StatefulWidget {
  const ValueSheet({
    super.key,
    required this.title,
    required this.value,
    required this.values,
    required this.presets,
    required this.label,
    required this.onChanged,
  });
  final String title;
  final int value;

  /// Allowed values, ascending. A value outside them is kept as one more stop.
  final List<int> values;
  final List<int> presets;
  final String Function(int) label;
  final ValueChanged<int> onChanged;

  @override
  State<ValueSheet> createState() => _ValueSheetState();
}

class _ValueSheetState extends State<ValueSheet> {
  late final List<int> _values = {
    ...widget.values,
    widget.value.clamp(widget.values.first, widget.values.last),
  }.toList()..sort();
  late int _index = _values.indexOf(
    widget.value.clamp(widget.values.first, widget.values.last),
  );
  late final _wheel = FixedExtentScrollController(initialItem: _index);
  String? _hint;

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  void _set(int index, {bool fromWheel = false}) {
    final l = L.of(context);
    final clamped = index.clamp(0, _values.length - 1);
    final hint = index < 0
        ? l.timerMinValue
        : index >= _values.length
        ? l.timerMaxValue
        : null;
    if (hint != null && hint != _hint) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        hint,
        Directionality.of(context),
      );
    }
    setState(() {
      _hint = hint;
      _index = clamped;
    });
    if (!fromWheel && _wheel.hasClients) _wheel.jumpToItem(clamped);
    widget.onChanged(_values[clamped]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(
        top: false,
        // Large text on a small phone: scroll, so the presets stay in reach.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _Done(
                      key: const ValueKey('value-done'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RepeatKey(
                      key: const ValueKey('value-less'),
                      icon: CupertinoIcons.minus,
                      onStep: () => _set(_index - 1),
                    ),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.label(_values[_index]),
                          key: const ValueKey('value-number'),
                          textScaler: TextScaler.noScaling,
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    _RepeatKey(
                      key: const ValueKey('value-more'),
                      icon: CupertinoIcons.plus,
                      onStep: () => _set(_index + 1),
                    ),
                  ],
                ),
                // At least the room of one small line; large text takes more.
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 18),
                  child: Text(
                    _hint ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: MediaQuery.withNoTextScaling(
                    child: CupertinoPicker(
                      scrollController: _wheel,
                      itemExtent: 36,
                      onSelectedItemChanged: (i) => _set(i, fromWheel: true),
                      children: [
                        for (final v in _values)
                          Center(child: Text(widget.label(v))),
                      ],
                    ),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    for (final p in widget.presets)
                      _ValueChip(
                        key: ValueKey('value-preset-$p'),
                        text: widget.label(p),
                        selected: _values[_index] == p,
                        onTap: () => _set(_values.indexOf(p)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [완료] in a sheet header: at most half the width, shrinking its label
/// rather than pushing the title row over the edge (large text, long words).
class _Done extends StatelessWidget {
  const _Done({super.key, required this.onPressed, this.bold = false});
  final VoidCallback? onPressed;
  final bool bold;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width / 2),
    child: CupertinoButton(
      minimumSize: const Size(44, 44),
      onPressed: onPressed,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          L.of(context).doneEditing,
          maxLines: 1,
          style: bold ? const TextStyle(fontWeight: FontWeight.w600) : null,
        ),
      ),
    ),
  );
}

/// −/+ that repeats while held: after 300 ms, every 100 ms.
class _RepeatKey extends StatefulWidget {
  const _RepeatKey({super.key, required this.icon, required this.onStep});
  final IconData icon;
  final VoidCallback onStep;

  @override
  State<_RepeatKey> createState() => _RepeatKeyState();
}

class _RepeatKeyState extends State<_RepeatKey> {
  Timer? _repeat;

  /// The key repeated while held, so letting go is not one more step.
  bool _held = false;

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
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) {
      _held = false;
      _stop();
      _repeat = Timer(const Duration(milliseconds: 300), () {
        _held = true;
        widget.onStep();
        _repeat = Timer.periodic(
          const Duration(milliseconds: 100),
          (_) => widget.onStep(),
        );
      });
    },
    onPointerUp: (_) => _stop(),
    onPointerCancel: (_) => _stop(),
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(56, 56),
      onPressed: () {
        if (!_held) widget.onStep();
      },
      child: Icon(widget.icon, size: 28),
    ),
  );
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({
    super.key,
    required this.text,
    required this.onTap,
    this.selected = false,
  });
  final String text;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        margin: const EdgeInsets.fromLTRB(0, 4, 8, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sealTint.resolveFrom(context),
          border: selected
              ? Border.all(color: seal.resolveFrom(context), width: 1.5)
              : null,
          borderRadius: BorderRadius.circular(22),
        ),
        // Hug the text: a Wrap hands out the full width (a chip a row made
        // the value sheet taller than a small phone).
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: onTap == null
                  ? CupertinoColors.secondaryLabel.resolveFrom(context)
                  : seal.resolveFrom(context),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    ),
  );
}

/// 8 pt preview of a timer: a tabata's work/rest split, a metronome's dots.
class TimerMiniBar extends StatelessWidget {
  const TimerMiniBar({super.key, required this.spec, this.width = 28});
  final TimingSpec spec;
  final double width;

  @override
  Widget build(BuildContext context) {
    final work = CupertinoColors.systemRed.resolveFrom(context);
    final rest = CupertinoColors.systemBlue.resolveFrom(context);
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: 8,
        child: spec.tabata
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: [
                    Expanded(
                      flex: spec.work,
                      child: ColoredBox(color: work),
                    ),
                    Expanded(
                      flex: spec.rest,
                      child: ColoredBox(color: rest),
                    ),
                  ],
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 4; i++)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: seal.resolveFrom(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
