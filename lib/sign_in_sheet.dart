import 'package:flutter/cupertino.dart';

import 'account.dart';
import 'gym.dart' show MemberLink;
import 'health_page.dart' show HealthDataPage;
import 'l10n/generated/app_localizations.dart';
import 'share.dart';
import 'sign_in.dart';

String signInLabel(L l, SignInMethod method) => switch (method) {
  SignInMethod.apple => l.signInWithApple,
  SignInMethod.google => l.signInWithGoogle,
  SignInMethod.kakao => l.signInWithKakao,
};

/// 수단의 이름. "Apple 연결" 처럼 다른 말에 붙여 쓴다.
String providerName(L l, SignInMethod method) => switch (method) {
  SignInMethod.apple => 'Apple',
  SignInMethod.google => 'Google',
  SignInMethod.kakao => l.kakao,
};

/// 수단을 고르게 하고 들어간다. 들어갔으면 true. 고르지 않았거나 막혔으면 false.
///
/// **로그인하는 자리마다 같은 시트다.** 수단이 여럿이 된 뒤로(sign_in.dart)
/// 어느 자리든 버튼 하나로 바로 들어가면 웹에서 카카오로 가입한 회원이 아이폰에서
/// Apple 로 들어가 새 사람이 된다. 고르는 단계가 그것을 막는다.
///
/// **만 14세 미만은 계정을 만들지 않는다.** 수단을 고르기 전에 '만 14세 이상입니다' 를
/// 채워야 한다 — 비워 두고 수단을 누르면 그 칸을 붉게 가리킬 뿐이다. 서버가 그 확인을
/// 계정에 남긴다(sign_in.dart exchange). 계정을 만드는 자리라 처리방침도 여기서 연다.
Future<bool> askSignIn(
  BuildContext context,
  Account account, {
  String? message,
}) async {
  final l = L.of(context);
  final methods = signInMethods;
  if (methods.isEmpty) return false;
  var adult = false, nudged = false;
  final chosen = await showCupertinoModalPopup<SignInMethod>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => CupertinoActionSheet(
        title: Text(message ?? l.signInChooseTitle),
        message: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AgeBox(
              checked: adult,
              nudged: nudged,
              onChanged: (value) => setState(() {
                adult = value;
                nudged = false;
              }),
            ),
            CupertinoButton(
              key: const ValueKey('sign-in-privacy'),
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              onPressed: () => openUrl(HealthDataPage.privacyUrl),
              child: Text(
                l.healthDataPrivacy,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          for (final method in methods)
            CupertinoActionSheetAction(
              key: ValueKey('sign-in-${method.name}'),
              onPressed: () => adult
                  ? Navigator.pop(ctx, method)
                  : setState(() => nudged = true),
              child: Text(
                signInLabel(l, method),
                style: adult
                    ? null
                    : TextStyle(
                        color: CupertinoColors.inactiveGray.resolveFrom(ctx),
                      ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
      ),
    ),
  );
  if (chosen == null) return false;
  return account.signIn(method: chosen, ageConfirmed: true);
}

/// '만 14세 이상입니다' 칸. 글자를 눌러도 채워진다.
class _AgeBox extends StatelessWidget {
  const _AgeBox({
    required this.checked,
    required this.nudged,
    required this.onChanged,
  });
  final bool checked, nudged;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: GestureDetector(
      key: const ValueKey('sign-in-age'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!checked),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoCheckbox(
              value: checked,
              onChanged: (value) => onChanged(value ?? false),
            ),
            Flexible(
              child: Text(
                L.of(context).ageConfirm,
                style: TextStyle(
                  fontSize: 15,
                  color: nudged
                      ? CupertinoColors.systemRed.resolveFrom(context)
                      : CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// '만 14세 이상인가요?' 를 한 번 묻고 계정에 남긴다(POST /api/me/age). 아니라고 하면
/// null 이고 아무것도 보내지 않는다. 남겼으면 true, 서버에 못 닿았으면 false.
///
/// 확인 칸이 생기기 전에 만든 계정이 도장 등록·초대 수락을 하면 서버가 묻는다(403
/// ageConfirmationRequired). 한 번 남기면 다시 묻지 않는다.
Future<bool?> confirmAge(BuildContext context, Account account) async {
  final l = L.of(context);
  final yes = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(l.ageConfirmAsk, style: const TextStyle(fontSize: 15)),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        CupertinoDialogAction(
          key: const ValueKey('age-confirm'),
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.ageConfirm),
        ),
      ],
    ),
  );
  if (yes != true) return null;
  return account.link.confirmAge();
}
