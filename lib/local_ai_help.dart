import 'package:flutter/cupertino.dart';

import 'l10n/generated/app_localizations.dart';
import 'local_ai.dart';
import 'units.dart';

String aiStatusLabel(L l, LocalAiStatus status) => switch (status) {
  LocalAiStatus.available => l.aiReady,
  LocalAiStatus.checking => l.aiChecking,
  LocalAiStatus.intelligenceDisabled ||
  LocalAiStatus.osUpdateRequired ||
  LocalAiStatus.downloadable => l.aiSetupNeeded,
  LocalAiStatus.modelNotReady || LocalAiStatus.downloading => l.aiPreparing,
  _ => l.aiUnavailable,
};

Future<void> showLocalAiHelp(
  BuildContext context,
  LocalAiStatus status, {
  required VoidCallback onRetry,
  required VoidCallback onPrepare,
  String? title,
  String? readyBody,
  String? manualBody,
}) {
  final l = L.of(context);
  final explanation = switch (status) {
    LocalAiStatus.available => readyBody ?? l.aiReadyBody,
    LocalAiStatus.intelligenceDisabled => l.aiDisabledBody,
    LocalAiStatus.osUpdateRequired => l.aiOsBody,
    LocalAiStatus.deviceNotEligible => l.aiDeviceBody,
    LocalAiStatus.modelNotReady ||
    LocalAiStatus.downloading => l.aiPreparingBody,
    LocalAiStatus.downloadable => l.aiDownloadBody,
    LocalAiStatus.languageUnavailable => l.aiLanguageBody,
    LocalAiStatus.unsupportedPlatform => l.aiPlatformBody,
    _ => l.aiUnavailableBody,
  };
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text('${title ?? l.aiTitle} · ${aiStatusLabel(l, status)}'),
      message: Text('$explanation\n\n${manualBody ?? l.aiManualBody}'),
      actions: [
        if (status == LocalAiStatus.downloadable)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onPrepare();
            },
            child: Text(l.aiPrepare),
          ),
        if (status != LocalAiStatus.available &&
            status != LocalAiStatus.unsupportedPlatform &&
            status != LocalAiStatus.deviceNotEligible)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onRetry();
            },
            child: Text(l.aiRetry),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: Text(l.doneEditing),
      ),
    ),
  );
}

String setupSummary(WorkoutSetup setup, L l, int reps, int sets) => [
  if (setup.weight != null) formatValue(setup.weight!, setup.unit),
  if (setup.totalReps != null) l.goalProgress(reps, setup.totalReps!),
  if (setup.repsPerSet != null) l.repsPerSetLabel(setup.repsPerSet!),
  if (setup.totalSets != null) l.setProgress(sets, setup.totalSets!),
  if (setup.weight == null &&
      setup.totalReps == null &&
      setup.repsPerSet == null &&
      setup.totalSets == null)
    l.repsInputHint,
].join(' · ');

Future<WorkoutSetup?> editWorkoutSetup(
  BuildContext context,
  WorkoutSetup setup,
) => Navigator.of(context).push<WorkoutSetup>(
  CupertinoPageRoute(builder: (_) => _SetupPage(setup: setup)),
);

class _SetupPage extends StatefulWidget {
  const _SetupPage({required this.setup});
  final WorkoutSetup setup;
  @override
  State<_SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<_SetupPage> {
  late final _name = TextEditingController(text: widget.setup.name);
  late final _weight = TextEditingController(
    text: widget.setup.weight == null ? '' : formatNumber(widget.setup.weight!),
  );
  late final _total = TextEditingController(
    text: widget.setup.totalReps?.toString() ?? '',
  );
  late final _reps = TextEditingController(
    text: widget.setup.repsPerSet?.toString() ?? '',
  );
  late final _sets = TextEditingController(
    text: widget.setup.totalSets?.toString() ?? '',
  );
  late String _unit = widget.setup.unit;

  WorkoutSetup? get _value {
    try {
      num? number(TextEditingController c) =>
          c.text.trim().isEmpty ? null : num.parse(c.text.trim());
      return WorkoutSetup.fromJson({
        'name': _name.text,
        'weight': number(_weight),
        'unit': _unit,
        'totalReps': number(_total),
        'repsPerSet': number(_reps),
        'totalSets': number(_sets),
        'repsOnly': widget.setup.repsOnly,
      });
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _weight, _total, _reps, _sets]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l.setupTitle),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _value == null
              ? null
              : () => Navigator.pop(context, _value),
          child: Text(l.doneEditing),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoFormSection.insetGrouped(
              children: [
                _field(l.exerciseNameHint, _name, text: true),
                _field(l.setupWeight, _weight, decimal: true),
                CupertinoFormRow(
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: _unit,
                    children: const {'kg': Text('kg'), 'lb': Text('lb')},
                    onValueChanged: (value) {
                      if (value != null) setState(() => _unit = value);
                    },
                  ),
                ),
                _field(l.setupTotalReps, _total),
                _field(l.setupSetReps, _reps),
                _field(l.setupTotalSets, _sets),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    bool text = false,
    bool decimal = false,
  }) => CupertinoTextFormFieldRow(
    controller: c,
    prefix: Text(label),
    textAlign: TextAlign.end,
    keyboardType: text
        ? TextInputType.text
        : TextInputType.numberWithOptions(decimal: decimal),
    onChanged: (_) => setState(() {}),
  );
}
