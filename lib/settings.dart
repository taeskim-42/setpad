import 'package:flutter/cupertino.dart';

import 'l10n/generated/app_localizations.dart';
import 'notes.dart';

Future<void> showWeightSettings(BuildContext context, NotesStore store) async {
  final l = L.of(context);
  final choice = await showCupertinoModalPopup<String>(
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
        // 같은 자리에 둔다. 설정이 둘뿐인데 화면을 따로 만들 이유가 없다.
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx, 'countAloud'),
          child: Text('${store.countAloud ? '✓ ' : ''}${l.countAloud}'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: Text(l.cancel),
      ),
    ),
  );
  if (choice == 'countAloud') {
    store.setCountAloud(!store.countAloud);
  } else if (choice != null) {
    store.setWeightUnit(choice);
  }
}
