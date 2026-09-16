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

/// PT 예약 — 다가오는 것과, 빈 자리 고르기.
Future<void> showBookingSheet(BuildContext context, Account account) async {
  final l = L.of(context);
  // 어느 체육관인지 서버가 추측하지 않는다. 두 곳에 다니면 먼저 고른다.
  final gymId = await _pickGym(context, account);
  if (gymId == null || !context.mounted) return;
  final mine = await account.link.bookings(gymId: gymId);
  if (!context.mounted) return;

  final choice = await showCupertinoModalPopup<String>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(l.bookingNew),
      actions: [
        for (final booking in mine.bookings)
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, 'cancel:${booking.id}'),
            // 신청과 확정을 같은 줄로 보이면 안 된다 — 승인 전에 나가는 사람이 생긴다.
            child: Text(
              '${l.bookingNext(booking.trainer, _when(l, booking.startsAt))}'
              '${booking.status == 'pending' ? ' · ${l.bookingPending}' : ''}'
              ' · ${l.bookingCancel}',
            ),
          ),
        // 오늘부터 이레. 그보다 먼 날을 잡는 일은 드물고, 화면이 길어진다.
        for (var i = 0; i < 7; i++)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'day:$i'),
            child: Text(_dayLabel(l, DateTime.now().add(Duration(days: i)))),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: Text(l.cancel),
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  if (choice.startsWith('cancel:')) {
    await account.link.cancelBooking(choice.substring(7));
    return;
  }

  final day = DateTime.now().add(
    Duration(days: int.parse(choice.substring(4))),
  );
  final open = await account.link.bookings(day: day, gymId: gymId);
  if (!context.mounted) return;
  if (open.slots.isEmpty) {
    await _tell(context, l.bookingNone);
    return;
  }

  final picked = await showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(_dayLabel(l, day)),
      actions: [
        for (final slot in open.slots)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, slot),
            child: Text(_time(slot)),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: Text(l.cancel),
      ),
    ),
  );
  if (picked == null || !context.mounted) return;
  // 고르는 사이 남이 가져갔을 수 있다. 서버가 다시 세고 아니면 거절한다.
  final ok = await account.link.book(picked, gymId: gymId);
  if (context.mounted && !ok) await _tell(context, l.bookingNone);
}

/// 다니는 곳이 하나면 묻지 않는다. 대부분이 그렇다.
Future<String?> _pickGym(BuildContext context, Account account) async {
  final gyms = account.gyms;
  if (gyms.length <= 1) return gyms.firstOrNull?.id;
  return showCupertinoModalPopup<String>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(L.of(ctx).bookingWhichGym),
      actions: [
        for (final gym in gyms)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, gym.id),
            child: Text(gym.name),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: Text(L.of(ctx).cancel),
      ),
    ),
  );
}

String _time(DateTime at) =>
    '${at.hour}:${at.minute.toString().padLeft(2, '0')}';

String _dayLabel(L l, DateTime day) =>
    '${l.dayLabel(day)} · ${l.weekdayLabel(day)}';

String _when(L l, DateTime at) => '${_dayLabel(l, at)} ${_time(at)}';
