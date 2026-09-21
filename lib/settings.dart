import 'package:flutter/cupertino.dart';

import 'account.dart';
import 'notes.dart';
import 'settings_page.dart';

/// 설정을 연다.
///
/// 이름이 무게 단위로 남아 있는 것은 부르는 곳이 둘이라서다. 안에 있던
/// 액션시트는 화면이 되었다 — 이용권이 팝업의 한 줄이면 무엇을 사는지 알
/// 수가 없었다.
Future<void> showWeightSettings(
  BuildContext context,
  NotesStore store, {
  Account? account,
  VoidCallback? onPlans,
}) => Navigator.of(context).push(
  CupertinoPageRoute<void>(
    builder: (_) =>
        SettingsPage(store: store, account: account, onPlans: onPlans),
  ),
);
