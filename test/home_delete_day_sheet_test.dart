// 홈에서 밀기만으로 기록이 지워지지 않는가, 오늘 한 장에 운동·먹은 것·섭취−운동이 다 있는가.
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';

Widget app(Widget home) => CupertinoApp(
  locale: const Locale('ko'),
  localizationsDelegates: L.localizationsDelegates,
  supportedLocales: L.supportedLocales,
  home: home,
);

void main() {
  testWidgets('홈에서 밀면 묻고, 취소하면 남고, 삭제를 누르면 지워진다', (tester) async {
    final dir = Directory.systemTemp.createTempSync('setpad_home_del_');
    final store = NotesStore(directory: dir);
    addTearDown(() {
      store.dispose();
      dir.deleteSync(recursive: true);
    });
    store.create().blocks.add(
      ExerciseBlock('벤치프레스', [LoggedSet(value: 80, reps: 5)]),
    );
    await tester.pumpWidget(app(NotesListPage(store: store, onOpen: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text('벤치프레스'), findsOneWidget);

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('지울까요'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(store.notes, hasLength(1), reason: '취소하면 그대로다');
    expect(find.text('벤치프레스'), findsOneWidget);

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(store.notes, isEmpty);
    // 저장 지연 타이머를 흘려보낸다.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('오늘 한 장: 세트 전부, 먹은 것, 섭취−운동이 한 화면에 있다', (tester) async {
    final dir = Directory.systemTemp.createTempSync('setpad_day_sheet_');
    final store = NotesStore(directory: dir);
    addTearDown(() {
      store.dispose();
      dir.deleteSync(recursive: true);
    });
    final note = store.create()
      ..blocks.addAll([
        ExerciseBlock('랫풀', [
          LoggedSet(value: 60, reps: 10),
          LoggedSet(value: 40, reps: 20),
        ]),
        ExerciseBlock('벤치', [LoggedSet(value: 60, reps: 10)]),
      ])
      ..calories = 450
      ..meals.addAll([
        MealEntry(
          at: DateTime.now(),
          kcal: 600,
          text: '김치찌개',
          source: MealEntry.estimate,
        ),
        MealEntry(at: DateTime.now(), kcal: null, text: '엄마표 반찬'),
      ]);
    await tester.pumpWidget(app(EditorPage(store: store, note: note)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.byIcon(CupertinoIcons.arrow_up_left_arrow_down_right),
    );
    await tester.pumpAndSettle();
    expect(find.text('오늘 한 장'), findsOneWidget);
    expect(find.text('랫풀'), findsOneWidget);
    expect(find.text('벤치'), findsOneWidget);
    expect(find.text('김치찌개'), findsOneWidget);
    expect(find.text('엄마표 반찬'), findsOneWidget);
    expect(find.text('열량 미상'), findsOneWidget);
    // 열량 미상이 섞이면 차이를 내지 않고 그렇다고 적는다.
    final energy = tester
        .widget<Text>(find.byKey(const ValueKey('sheet-energy')))
        .data!;
    expect(energy, contains('600'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
