import 'package:flutter/cupertino.dart';

import 'account.dart';
import 'l10n/generated/app_localizations.dart';
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
Future<bool> askSignIn(
  BuildContext context,
  Account account, {
  String? message,
}) async {
  final l = L.of(context);
  final methods = signInMethods;
  if (methods.isEmpty) return false;
  final chosen = await showCupertinoModalPopup<SignInMethod>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(message ?? l.signInChooseTitle),
      actions: [
        for (final method in methods)
          CupertinoActionSheetAction(
            key: ValueKey('sign-in-${method.name}'),
            onPressed: () => Navigator.pop(ctx, method),
            child: Text(signInLabel(l, method)),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: Text(l.cancel),
      ),
    ),
  );
  if (chosen == null) return false;
  return account.signIn(chosen);
}
