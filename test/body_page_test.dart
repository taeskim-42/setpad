import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/body_page.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';

void main() {
  testWidgets('내 몸 정보를 적으면 저장되고 기초대사량이 보인다', (tester) async {
    final dir = Directory.systemTemp.createTempSync('body');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = NotesStore(directory: dir);
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: BodyPage(store: store),
      ),
    );
    final rows = find.byType(CupertinoTextFormFieldRow);
    await tester.enterText(rows.at(0), '178');
    await tester.enterText(rows.at(1), '80');
    await tester.enterText(rows.at(2), '${DateTime.now().year - 30}');
    await tester.tap(find.text('남'));
    await tester.pumpAndSettle();
    expect(store.body.complete, isTrue);
    expect(find.byKey(const ValueKey('body-bmr')), findsOneWidget);
    expect(find.textContaining('1,768'), findsOneWidget);
    // 말이 안 되는 키는 비운 것으로 본다.
    await tester.enterText(rows.at(0), '9');
    await tester.pump();
    expect(store.body.heightCm, isNull);
    // 저장 대기(0.4초)를 흘려보낸다.
    await tester.pump(const Duration(milliseconds: 500));
  });
}
