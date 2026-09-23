import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'l10n/generated/app_localizations.dart';

/// 건강 앱과 무엇을 왜 주고받는지. 설정에서 열고, Android 에서는 헬스 커넥트가
/// "이 앱이 권한을 왜 쓰는가" 를 물을 때도 이 화면이 열린다(MainActivity).
///
/// Play 가 심박 권한을 "선언된 기능에 필요 없다" 며 반려한 적이 있다(2026-09-23).
/// 심박으로 휴식을 끊는 기능이 타이머 줄에만 보여서 심사에서 안 보였다 — 쓰는
/// 까닭을 여기에 그대로 적는다. 권한을 더하면 여기도 같이 고친다.
class HealthDataPage extends StatelessWidget {
  const HealthDataPage({super.key});

  static const route = '/health-data';
  static const privacyUrl =
      'https://taeskim-42.github.io/setpad-site/privacy.html';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final android = defaultTargetPlatform == TargetPlatform.android;
    Widget line(String text, {Color? color}) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, height: 1.45, color: color),
      ),
    );
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l.healthDataTitle)),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            line(l.healthDataIntro, color: muted),
            line(l.healthDataWrite),
            line(l.healthDataCalories),
            line(l.healthDataHeart),
            line(l.healthDataStays),
            line(
              android ? l.healthDataRevokeAndroid : l.healthDataRevokeIos,
              color: muted,
            ),
            Text(
              l.healthDataPrivacy,
              style: TextStyle(fontSize: 13, color: muted),
            ),
            const Text(privacyUrl, style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
