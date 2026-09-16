import 'package:flutter/cupertino.dart';

import 'account.dart';
import 'gym.dart';
import 'l10n/generated/app_localizations.dart';
import 'notes.dart';

/// 같이 하기 — 코드를 띄우거나 치거나.
///
/// **코드를 쓰는 이유는 짝이 계속 바뀌기 때문이다.** 헬스장에서는 그날 옆에
/// 있는 사람이 봐준다. 사람끼리 관계로 묶으면 끊는 일이 생기는데, 그날로
/// 끝나면 그럴 일이 없다.
Future<void> showPartnerSheet(
  BuildContext context,
  Account account,
  Note note,
) async {
  final l = L.of(context);
  final choice = await showCupertinoModalPopup<String>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(l.partnerInvite),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx, 'invite'),
          child: Text(l.partnerCode),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx, 'join'),
          child: Text(l.partnerEnter),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: Text(l.cancel),
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  if (choice == 'invite') {
    final code = await account.link.invite(note.id);
    if (!context.mounted) return;
    await _tell(context, code ?? l.partnerFailed, title: l.partnerCode);
    return;
  }

  final code = await _askCode(context, l);
  if (code == null || !context.mounted) return;
  final joined = await account.link.join(code, myWorkoutId: note.id);
  if (!context.mounted) return;
  await _tell(
    context,
    joined == null ? l.partnerFailed : l.partnerJoined(joined.partner ?? code),
  );
}

Future<String?> _askCode(BuildContext context, L l) {
  final input = TextEditingController();
  return showCupertinoDialog<String>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(l.partnerEnter),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: input,
          autofocus: true,
          // 헬스장에서 불러 주는 번호다. 자판을 오래 두드릴 자리가 아니다.
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, letterSpacing: 4),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx, input.text.trim()),
          child: Text(l.confirmYes),
        ),
      ],
    ),
  ).whenComplete(input.dispose);
}

Future<void> _tell(BuildContext context, String message, {String? title}) =>
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: title == null ? null : Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            message,
            style: TextStyle(
              fontSize: title == null ? 15 : 30,
              letterSpacing: title == null ? 0 : 6,
              fontWeight: title == null ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text(L.of(ctx).confirmYes),
          ),
        ],
      ),
    );
