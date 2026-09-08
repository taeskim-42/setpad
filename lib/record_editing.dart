import 'package:flutter/cupertino.dart';

import 'editor.dart';
import 'l10n/generated/app_localizations.dart';
import 'units.dart';

Future<String?> editExerciseTitle(BuildContext context, String name) =>
    Navigator.of(context).push<String>(
      CupertinoPageRoute(builder: (_) => _RecordEditPage(name: name)),
    );

Future<LoggedSet?> editRecordedSet(
  BuildContext context,
  LoggedSet set,
  int index,
) => Navigator.of(context).push<LoggedSet>(
  CupertinoPageRoute(
    builder: (_) => _RecordEditPage(set: set, index: index),
  ),
);

class _RecordEditPage extends StatefulWidget {
  const _RecordEditPage({this.name, this.set, this.index = 0});
  final String? name;
  final LoggedSet? set;
  final int index;
  @override
  State<_RecordEditPage> createState() => _RecordEditPageState();
}

class _RecordEditPageState extends State<_RecordEditPage> {
  late final _name = TextEditingController(text: widget.name);
  late final _value = TextEditingController(
    text: widget.set?.value == null ? '' : formatNumber(widget.set!.value!),
  );
  late final _reps = TextEditingController(
    text: widget.set?.reps?.toString() ?? '',
  );
  late String _unit = widget.set?.unit ?? defaultUnit;

  Object? get _result {
    if (widget.set == null) {
      final name = _name.text.trim();
      return name.isEmpty || name.length > 120 || name.contains('\n')
          ? null
          : name;
    }
    final valueText = _value.text.trim(), repsText = _reps.text.trim();
    final value = double.tryParse(valueText), reps = int.tryParse(repsText);
    if (valueText.isNotEmpty &&
        (value == null || !value.isFinite || value < 0 || value > 99999)) {
      return null;
    }
    if (repsText.isNotEmpty && (reps == null || reps < 1 || reps > 100000)) {
      return null;
    }
    if (value == null && reps == null) return null;
    return LoggedSet(
      value: value,
      unit: _unit,
      reps: reps,
      notes: [...widget.set!.notes],
      done: widget.set!.done,
    );
  }

  void _submit() {
    final result = _result;
    if (result is String) Navigator.pop(context, result);
    if (result is LoggedSet) Navigator.pop(context, result);
  }

  Future<void> _chooseUnit() async {
    final unit = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          for (final unit in units)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, unit.id),
              child: Text(unit.label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(L.of(ctx).cancel),
        ),
      ),
    );
    if (mounted && unit != null) setState(() => _unit = unit);
  }

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _reps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.set == null
              ? l.exerciseNameHint
              : l.setOrdinal(widget.index + 1),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _result == null ? null : _submit,
          child: Text(l.doneEditing),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoFormSection.insetGrouped(
              children: [
                if (widget.set == null)
                  CupertinoTextFormFieldRow(
                    controller: _name,
                    autofocus: true,
                    placeholder: l.exerciseNameHint,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (_) => _submit(),
                  )
                else ...[
                  CupertinoTextFormFieldRow(
                    controller: _value,
                    autofocus: true,
                    prefix: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _chooseUnit,
                      child: Text('${unitById[_unit]?.label ?? _unit} ▾'),
                    ),
                    textAlign: TextAlign.end,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  CupertinoTextFormFieldRow(
                    controller: _reps,
                    prefix: Text(l.repsInputHint),
                    textAlign: TextAlign.end,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
