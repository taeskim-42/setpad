import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/health_page.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/settings_page.dart';

/// Play 는 심박 권한을 "제공하는 기능에 필요 없어 보인다" 며 반려했다. 심박을
/// 쓰는 까닭이 설정과 헬스 커넥트의 권한 설명 화면에서 보여야 한다.
void main() {
  testWidgets('설정의 건강 데이터에서 심박으로 휴식을 끝내는 것까지 설명한다', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: SettingsPage(store: NotesStore()),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('settings-health')));
    await tester.pumpAndSettle();
    expect(find.byType(HealthDataPage), findsOneWidget);
    expect(find.textContaining('심박수'), findsOneWidget);
    expect(find.textContaining('25bpm'), findsOneWidget);
    expect(find.byKey(const ValueKey('health-privacy')), findsOneWidget);
    expect(find.textContaining(HealthDataPage.privacyUrl), findsOneWidget);
  });

  test('헬스 커넥트의 권한 설명 요청은 이 화면으로 온다', () {
    final activity = File(
      'android/app/src/main/kotlin/com/taeskim/setpad/MainActivity.kt',
    ).readAsStringSync();
    expect(activity, contains('"${HealthDataPage.route}"'));
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('READ_HEART_RATE'));
    expect(manifest, contains('ACTION_SHOW_PERMISSIONS_RATIONALE'));
    expect(manifest, contains('VIEW_PERMISSION_USAGE'));
  });
}
