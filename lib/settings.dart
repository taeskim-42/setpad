import 'package:flutter/cupertino.dart';

import 'l10n/generated/app_localizations.dart';
import 'notes.dart';

Future<void> showWeightSettings(BuildContext context, NotesStore store) async {
  final l = L.of(context);
  final unit = await showCupertinoModalPopup<String>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(l.weightUnitSetting),
      message: Text(l.weightUnitHelp),
      actions: [
        for (final unit in ['kg', 'lb'])
          CupertinoActionSheetAction(
            isDefaultAction: unit == store.weightUnit,
            onPressed: () => Navigator.pop(ctx, unit),
            child: Text('${unit == store.weightUnit ? '✓ ' : ''}$unit'),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: Text(l.cancel),
      ),
    ),
  );
  if (unit != null) {
    store.setWeightUnit(unit);
  }
}
