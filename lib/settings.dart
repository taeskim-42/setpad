import 'package:flutter/cupertino.dart';

import 'account.dart';
import 'l10n/generated/app_localizations.dart';
import 'notes.dart';
import 'purchases.dart';

Future<void> showWeightSettings(
  BuildContext context,
  NotesStore store, {
  Account? account,
}) async {
  final l = L.of(context);
  final plan = account?.plan;
  final prices = account?.prices ?? const <Plan, String>{};
  String planLabel(Plan p) {
    final name = p == Plan.monthly ? l.planMonthly : l.planLifetime;
    if (plan == p) return '$name · ${l.planActive}';
    // 값은 스토어가 준 문자열을 그대로 쓴다 — 나라마다 통화도 자릿수도 다르다.
    final price = prices[p];
    return price == null ? name : '$name · $price';
  }

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
        // 같은 자리에 둔다. 설정이 몇 개뿐인데 화면을 따로 만들 이유가 없다.
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx, 'countAloud'),
          child: Text('${store.countAloud ? '✓ ' : ''}${l.countAloud}'),
        ),
        if (account != null) ...[
          // 다니는 체육관. 있는 사람에게만 보인다 — 대부분은 안 다닌다.
          for (final gym in account.gyms)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                gym.trainer == null
                    ? l.gymOnly(gym.name)
                    : l.gymMember(gym.name, gym.trainer!),
              ),
            ),
          // 이미 가진 것은 팔지 않는다. 평생을 산 사람에게 월을 보이면 안 된다.
          if (plan != Plan.lifetime)
            for (final p in Plan.values)
              if (plan != p || p == Plan.monthly)
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(ctx, 'buy:${p.name}'),
                  child: Text('${plan == p ? '✓ ' : ''}${planLabel(p)}'),
                ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'restore'),
            child: Text(l.restorePurchases),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'account'),
            child: Text(
              account.signedIn
                  ? '${account.nickname} · ${l.accountSignOut}'
                  : l.accountSignIn,
            ),
          ),
        ],
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: Text(l.cancel),
      ),
    ),
  );
  if (choice == null) return;
  if (choice == 'countAloud') {
    store.setCountAloud(!store.countAloud);
  } else if (choice == 'restore') {
    await account?.restore();
  } else if (choice == 'account') {
    account!.signedIn ? account.signOut() : await account.signIn();
  } else if (choice.startsWith('buy:')) {
    final wanted = Plan.values.firstWhere((p) => p.name == choice.substring(4));
    await account?.buy(wanted);
  } else {
    store.setWeightUnit(choice);
  }
}
