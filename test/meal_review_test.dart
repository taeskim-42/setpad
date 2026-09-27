import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/meal.dart';
import 'package:setpad/meal_amount_sheet.dart';
import 'package:setpad/meal_review_sheet.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_ai.dart';

import 'meal_sync_test.dart' show FakeAi;

class _MemoryStore extends NotesStore {
  @override
  Future<void> flush() async {}
}

Map<String, dynamic> response() => {
  'kcal': 200,
  'items': ['밥'],
  'requiresConfirmation': true,
  'components': [
    {
      'name': '쌀밥',
      'evidence': '밥 100g',
      'ref': 'rice',
      'amount': 100,
      'unit': 'g',
      'kcalPer100': 200,
      'kcal': 200,
      'source': 'mfds',
      'estimatedAmount': false,
    },
  ],
  'refs': [
    {
      'code': 'rice',
      'name': '쌀밥',
      'maker': 'test maker',
      'per': 'g',
      'kcalPer100': 200,
      'kind': 'dish',
      'url': 'https://various.foodsafetykorea.go.kr/rice',
    },
  ],
};

Widget app(Widget home) => CupertinoApp(
  locale: const Locale('ko'),
  localizationsDelegates: L.localizationsDelegates,
  supportedLocales: L.supportedLocales,
  home: home,
);

void main() {
  test('meal evidence must agree with the source, arithmetic and total', () {
    final valid = MealEstimate.fromJson(response());
    expect(valid.kcal, 200);
    expect(valid.components.single.maker, 'test maker');
    expect(valid.requiresConfirmation, isTrue);
    expect(MealEstimate.fromJson({'kcal': 650}).requiresConfirmation, isTrue);
    final untrusted = response()..['requiresConfirmation'] = false;
    expect(MealEstimate.fromJson(untrusted).requiresConfirmation, isTrue);
    for (final change in <void Function(Map<String, dynamic>)>[
      (j) => j['kcal'] = 300,
      (j) => j['components'][0]['amount'] = 200,
      (j) => j['components'][0]['amount'] = -100,
      (j) => j['components'][0]['kcalPer100'] = double.infinity,
      (j) => j['components'][0]['unit'] = 'ml',
      (j) => j['components'][0]['name'] = '생쌀',
      (j) => j['components'][0]['ref'] = 'unknown',
      (j) => j['components'][0]['source'] = 'typed',
      (j) => j['refs'][0]['per'] = 'ml',
      (j) => j['refs'][0]['kcalPer100'] = 150,
      (j) => j['components'] = [],
    ]) {
      final json = response();
      change(json);
      expect(
        () => MealEstimate.fromJson(json),
        throwsA(isA<RecordAiException>()),
      );
    }
  });

  testWidgets(
    'AI calories require confirmation; edited amounts are recalculated; cancel preserves text',
    (tester) async {
      final store = _MemoryStore();
      addTearDown(store.dispose);
      final note = store.create();
      final ai = FakeAi((_) async => MealEstimate.fromJson(response()));
      await tester.pumpWidget(
        app(EditorPage(store: store, note: note, ai: ai)),
      );
      await tester.pumpAndSettle();
      Future<void> write() async {
        await tester.tap(find.byKey(const ValueKey('meal-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('meal-text-toggle')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(CupertinoTextField), '밥 100g');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }

      await write();
      expect(note.meals.single.kcal, isNull);
      expect(find.text('쌀밥'), findsOneWidget);
      expect(find.text('test maker'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('meal-review-amount-0')),
        '200',
      );
      await tester.pumpAndSettle();
      expect(note.meals.single.kcal, isNull);
      await tester.tap(find.byKey(const ValueKey('meal-review-confirm')));
      await tester.pumpAndSettle();
      expect(note.meals.single.kcal, 400);
      expect(note.meals.single.text, '밥 100g');
      expect(note.meals.single.currentText, '쌀밥 200g');
      expect(note.meals.single.foods.single.amount, 200);
      final restored = MealEntry.tryFromJson(note.meals.single.toJson())!;
      expect(restored.text, '밥 100g');
      expect(restored.currentText, '쌀밥 200g');
      expect(restored.kcal, 400);
      expect(find.text('쌀밥 200g'), findsOneWidget);
      expect(note.meals.single.source, MealEntry.estimate);
      await write();
      await tester.tap(find.byKey(const ValueKey('meal-review-cancel')));
      await tester.pumpAndSettle();
      expect(note.meals.last.kcal, isNull);
      expect(note.meals.last.text, '밥 100g');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'a late estimate or confirmation cannot overwrite an edited meal',
    (tester) async {
      final store = _MemoryStore();
      addTearDown(store.dispose);
      final note = store.create();
      final pending = Completer<MealEstimate>();
      final ai = FakeAi((_) => pending.future);
      await tester.pumpWidget(
        app(EditorPage(store: store, note: note, ai: ai)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('meal-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('meal-text-toggle')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(CupertinoTextField), '밥 100g');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      pending.complete(MealEstimate.fromJson(response()));
      await tester.pumpAndSettle();
      final old = note.meals.single;
      note.meals[0] = MealEntry(
        id: old.id,
        at: old.at,
        kcal: 123,
        text: '밥 123kcal',
        source: MealEntry.typed,
      );
      store.touch();
      await tester.tap(find.byKey(const ValueKey('meal-review-confirm')));
      await tester.pumpAndSettle();
      expect(note.meals.single.kcal, 123);
      expect(note.meals.single.source, MealEntry.typed);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('review keeps input precision and rounds only the final total', (
    tester,
  ) async {
    ({double kcal, String? text})? saved;
    final estimate = MealEstimate(
      kcal: 1,
      components: [
        for (var i = 0; i < 2; i++)
          const MealComponent(
            name: 'food',
            evidence: 'food .125g',
            kcal: .25,
            amount: .125,
            unit: 'g',
            kcalPer100: 200,
          ),
      ],
    );
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => CupertinoButton(
            child: const Text('open'),
            onPressed: () async =>
                saved = await reviewMealEstimate(context, estimate),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const ValueKey('meal-review-amount-0')),
          )
          .controller!
          .text,
      '0.125',
    );
    final confirm = find.byKey(const ValueKey('meal-review-confirm'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(saved!.kcal.round(), 1);
    final basis = MealBasis(
      kcal: saved!.kcal,
      amount: 1,
      unit: MealBasis.photo,
    );
    expect(
      basis.kcalFor(.5),
      0,
      reason: 'editing a photo fraction must not round twice',
    );
  });

  testWidgets(
    'OCR photo remains visible while calories, amount and unit are corrected',
    (tester) async {
      ({MealBasis basis, double eaten})? saved;
      final photo = Uint8List.fromList(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
        ),
      );
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => CupertinoButton(
              child: const Text('open'),
              onPressed: () async => saved = await askMealAmount(
                context,
                bases: [
                  const MealBasis(kcal: 500.125, amount: 100.125, unit: 'g'),
                ],
                photo: photo,
                allowUnitEdit: true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(
        tester
            .widget<CupertinoTextField>(
              find.byKey(const ValueKey('meal-basis-kcal')),
            )
            .controller!
            .text,
        '500.125',
      );
      expect(
        tester
            .widget<CupertinoTextField>(
              find.byKey(const ValueKey('meal-basis-amount')),
            )
            .controller!
            .text,
        '100.125',
      );
      expect(
        tester
            .widget<CupertinoTextField>(
              find.byKey(const ValueKey('meal-eaten')),
            )
            .controller!
            .text,
        '100.125',
      );
      await tester.enterText(
        find.byKey(const ValueKey('meal-basis-amount')),
        '100',
      );
      await tester.enterText(
        find.byKey(const ValueKey('meal-basis-kcal')),
        '50',
      );
      await tester.enterText(
        find.byKey(const ValueKey('meal-basis-unit')),
        'ml',
      );
      await tester.enterText(find.byKey(const ValueKey('meal-eaten')), '200');
      await tester.pumpAndSettle();
      final confirm = find.byKey(const ValueKey('meal-review-confirm'));
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(saved!.basis.unit, 'ml');
      expect(saved!.basis.kcalFor(saved!.eaten), 100);
    },
  );
}
