import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';

/// 문서의 빈 곳을 누르면 시스템 자판은 내려가고 커서는 남는다.
///
/// **되돌리기 쉬운 성질이라 못 박아 둔다.** 예전에는 같은 자리에서
/// TextInput.show 를 불러 자판을 다시 올렸고, 그러면 위에 적은 것이 자판에
/// 가려 안 보인다.
void main() {
  testWidgets('빈 곳을 누르면 자판이 내려가고 커서는 남는다', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.textInput,
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.textInput, null));

    final c = RoutineEditorController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: CupertinoPageScaffold(child: RoutineEditor(controller: c)),
      ),
    );
    await tester.pumpAndSettle();

    // 운동 이름을 치는 중 — 시스템 자판이 올라와 있는 상태다.
    await tester.enterText(find.byType(CupertinoTextField).first, '벤치');
    await tester.pumpAndSettle();
    calls.clear();

    // 문서의 빈 곳을 누른다.
    await tester.tapAt(const Offset(200, 120));
    await tester.pumpAndSettle();

    expect(calls, contains('TextInput.hide'),
        reason: '빈 곳을 누르면 자판이 내려가야 한다');
    expect(calls, isNot(contains('TextInput.show')),
        reason: '내려간 자판을 곧바로 다시 올리면 안 된다');
    expect(c.blocks, isEmpty, reason: '치던 것이 사라지면 안 된다');
  });
}
