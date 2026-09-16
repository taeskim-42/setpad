import 'package:flutter/cupertino.dart';

import 'account.dart';
import 'booking_page.dart';
import 'l10n/generated/app_localizations.dart';

/// 예약 화면으로 보낸다. 다니는 곳이 둘 이상이면 어디인지 먼저 묻는다.
///
/// 서버는 소속이 하나일 때만 생략을 봐 준다. 둘이면 추측하지 않고 거절한다.
Future<void> openBooking(BuildContext context, Account account) async {
  final gyms = account.gyms;
  if (gyms.isEmpty) return;
  var gymId = gyms.first.id;
  if (gyms.length > 1) {
    final picked = await showCupertinoModalPopup<String>(
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
    if (picked == null) return;
    gymId = picked;
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => BookingPage(account: account, gymId: gymId),
    ),
  );
}
