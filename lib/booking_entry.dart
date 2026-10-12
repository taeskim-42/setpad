import 'package:flutter/cupertino.dart';

import 'account.dart';
import 'booking_page.dart';
import 'l10n/generated/app_localizations.dart';
import 'notes.dart';

/// 예약 화면으로 보낸다. 다니는 곳이 둘 이상이면 어디인지 먼저 묻는다 — 도장 화면처럼
/// 이미 정해진 곳에서 열면 [gymId] 로 바로 간다.
///
/// 서버는 소속이 하나일 때만 생략을 봐 준다. 둘이면 추측하지 않고 거절한다.
/// [store] 가 있으면 회원이 거기서 한 신청·취소를 도장 소식에서 뺀다.
Future<void> openBooking(
  BuildContext context,
  Account account, {
  NotesStore? store,
  String? gymId,
}) async {
  final gyms = account.gyms;
  if (gyms.isEmpty) return;
  var chosen = gymId ?? gyms.first.id;
  if (gymId == null && gyms.length > 1) {
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
    chosen = picked;
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) =>
          BookingPage(account: account, gymId: chosen, store: store),
    ),
  );
}
