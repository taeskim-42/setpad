import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_ai.dart';

import 'meal_sync_test.dart' show FakeAi;

class _MemoryStore extends NotesStore {
  @override
  Future<void> flush() async {}
}

void main() {
  test(
    'stored text totals are repaired once and queued for synchronization',
    () {
      final repaired = MealEntry.tryFromJson({
        'id': 'existing-meal',
        'at': '2026-09-27T12:00:00',
        'text': '밥 300kcal, 반찬 200kcal, 총 500kcal',
        'source': MealEntry.typed,
        'kcal': 1000,
      })!;
      expect(repaired.kcal, 500);
      expect(repaired.dirty, isTrue);
      expect(repaired.id, 'existing-meal');
      repaired.dirty = false;
      expect(MealEntry.tryFromJson(repaired.toJson())!.dirty, isFalse);
      final unknown = MealEntry.tryFromJson({
        ...repaired.toJson(),
        'text': '김밥 300kcal~400kcal',
        'kcal': 700,
      })!;
      expect(unknown.kcal, isNull);
      expect(unknown.text, '김밥 300kcal~400kcal');
      expect(
        MealEntry.tryFromJson({
          ...repaired.toJson(),
          'source': MealEntry.estimate,
          'kcal': 550,
        })!.kcal,
        550,
      );
    },
  );

  testWidgets('ambiguous calorie text stays unknown without an AI override', (
    tester,
  ) async {
    final store = _MemoryStore();
    addTearDown(store.dispose);
    final note = store.create();
    final ai = FakeAi((_) async => const MealEstimate(kcal: 999));
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: EditorPage(store: store, note: note, ai: ai),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('meal-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('meal-text-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(CupertinoTextField),
      '김밥 300kcal~400kcal',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(note.meals.single.kcal, isNull);
    expect(ai.asked, isEmpty);
    expect(find.textContaining('총열량이나 먹은 양이 명확하지 않아요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('meal-0')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoTextField), '김밥 350kcal');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(note.meals.single.kcal, 350);
    expect(ai.asked, isEmpty);
    expect(find.textContaining('총열량이나 먹은 양이 명확하지 않아요'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('both meal API paths reject out-of-range calorie totals', () async {
    for (final kcal in [-1, 100001, null, '650']) {
      final ai = RecordAi(
        deviceId: 'meal-validation-device',
        client: MockClient(
          (request) async => http.Response(
            jsonEncode(
              request.url.path == '/api/device'
                  ? {'token': 't'}
                  : {'kcal': kcal},
            ),
            200,
          ),
        ),
      );
      await expectLater(
        ai.estimateMealText('밥', locale: 'ko'),
        throwsA(isA<RecordAiException>()),
      );
      await expectLater(
        ai.estimateMeal(
          Uint8List.fromList([1]),
          mime: 'image/jpeg',
          locale: 'ko',
        ),
        throwsA(isA<RecordAiException>()),
      );
    }
  });
}
