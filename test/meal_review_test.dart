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

  testWidgets('탄단지: 음식마다 양만큼, 양을 고치면 같은 비율로, 합계를 저장한다', (tester) async {
    ReviewedMeal? saved;
    final estimate = MealEstimate(
      kcal: 607,
      components: const [
        MealComponent(
          name: 'Chapagetti',
          evidence: '짜파게티 한 봉지',
          kcal: 607.04,
          amount: 140,
          unit: 'g',
          kcalPer100: 433.6,
          macros: (carbs: 95.1, protein: 11.2, fat: 19.7),
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
    expect(find.text('탄 95g · 단 11g · 지 20g'), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('meal-review-amount-0')),
      '70',
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('meal-review-macros')))
          .data,
      '탄 48g · 단 6g · 지 10g',
    );
    final confirm = find.byKey(const ValueKey('meal-review-confirm'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(saved!.macros!.carbs, closeTo(47.55, 1e-9));
    expect(saved!.macros!.protein, closeTo(5.6, 1e-9));
  });

  testWidgets('탄단지 없는 음식이 하나라도 있으면 합계를 내지 않는다', (tester) async {
    ReviewedMeal? saved;
    final estimate = MealEstimate(
      kcal: 700,
      components: const [
        MealComponent(
          name: 'a',
          evidence: 'a 100g',
          kcal: 400,
          amount: 100,
          unit: 'g',
          kcalPer100: 400,
          macros: (carbs: 50, protein: 10, fat: 10),
        ),
        MealComponent(
          name: 'b',
          evidence: 'b 100g',
          kcal: 300,
          amount: 100,
          unit: 'g',
          kcalPer100: 300,
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
    expect(find.byKey(const ValueKey('meal-review-macros')), findsNothing);
    final confirm = find.byKey(const ValueKey('meal-review-confirm'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(saved!.macros, isNull);
  });

  test('끼니의 탄단지는 저장했다 그대로 읽힌다, 예전 기록은 null', () {
    final entry = MealEntry(
      at: DateTime(2026, 9, 30),
      kcal: 607,
      macros: (carbs: 95.1, protein: 11.2, fat: 19.7),
    );
    final back = MealEntry.tryFromJson(jsonDecode(jsonEncode(entry.toJson())))!;
    expect(back.macros, (carbs: 95.1, protein: 11.2, fat: 19.7));
    expect(
      MealEntry.tryFromJson({
        'at': '2026-09-30T00:00:00.000',
        'kcal': 5,
      })!.macros,
      isNull,
    );
  });

  testWidgets('맛 변종만 있으면 고르기 전에는 저장하지 않고, 고르면 그 제품의 양·출처로 저장한다', (
    tester,
  ) async {
    ReviewedMeal? saved;
    const olive = MealSource(
      name: '올리브짜파게티',
      kcalPer100: 436,
      per: 'g',
      url: 'https://example.com/olive',
      kind: 'processed',
    );
    const mala = MealSource(
      name: '마라짜파게티',
      kcalPer100: 425,
      per: 'g',
      url: 'https://example.com/mala',
      kind: 'processed',
    );
    final estimate = MealEstimate(
      kcal: 610,
      components: const [
        MealComponent(
          name: '올리브짜파게티',
          evidence: '짜파게티 한 봉지',
          kcal: 610.4,
          amount: 140,
          unit: 'g',
          kcalPer100: 436,
          needsChoice: true,
          source: olive,
          alternatives: [
            MealComponent(
              name: '마라짜파게티',
              evidence: '짜파게티 한 봉지',
              kcal: 595,
              amount: 140,
              unit: 'g',
              kcalPer100: 425,
              source: mala,
            ),
          ],
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
      find.byKey(const ValueKey('meal-review-needs-choice-0')),
      findsOneWidget,
    );
    final confirm = find.byKey(const ValueKey('meal-review-confirm'));
    await tester.ensureVisible(confirm);
    expect(
      tester.widget<CupertinoButton>(confirm).onPressed,
      isNull,
      reason: '고르기 전에는 저장하지 않는다',
    );
    await tester.tap(find.byKey(const ValueKey('meal-review-choose-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('meal-choice-0-1')));
    await tester.pumpAndSettle();
    expect(find.text('마라짜파게티'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('meal-review-needs-choice-0')),
      findsNothing,
    );
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(saved!.kcal.round(), 595);
    expect(saved!.sources!.single.name, '마라짜파게티');
    expect(saved!.text, '마라짜파게티 140g');
  });

  testWidgets('AI 가 어림한 음식은 그렇게 적는다', (tester) async {
    final estimate = MealEstimate(
      kcal: 120,
      components: const [
        MealComponent(
          name: '무지개깨비죽',
          evidence: '무지개깨비죽 한 그릇',
          kcal: 120,
          amount: 80,
          unit: 'g',
          kcalPer100: 150,
          estimatedAmount: true,
          ai: true,
        ),
      ],
    );
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => CupertinoButton(
            child: const Text('open'),
            onPressed: () => reviewMealEstimate(context, estimate),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('meal-review-ai-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-review-choose-0')), findsNothing);
  });

  test('서버의 AI 성분·대안·고르기 표시를 읽는다', () {
    final e = MealEstimate.fromJson({
      'kcal': 610,
      'requiresConfirmation': true,
      'refs': [
        {
          'code': 'P1',
          'name': '올리브짜파게티',
          'maker': '(주)농심',
          'kind': 'processed',
          'per': 'g',
          'kcalPer100': 436,
          'url': 'https://example.com/p1',
        },
      ],
      'components': [
        {
          'name': '올리브짜파게티',
          'evidence': '짜파게티 한 봉지',
          'ref': 'P1',
          'source': 'mfds',
          'amount': 140,
          'unit': 'g',
          'kcalPer100': 436,
          'kcal': 610.4,
          'estimatedAmount': false,
          'needsChoice': true,
          'alternatives': [
            {
              'ref': 'P2',
              'name': '마라짜파게티',
              'maker': '(주)농심',
              'kind': 'processed',
              'amount': 140,
              'unit': 'g',
              'kcalPer100': 425,
              'kcal': 595,
              'estimatedAmount': false,
              'url': 'https://example.com/p2',
            },
            {
              'ref': 'P3',
              'name': '틀린 줄',
              'amount': 140,
              'unit': 'g',
              'kcalPer100': 425,
              'kcal': 999,
              'url': 'https://example.com/p3',
            },
          ],
        },
      ],
    });
    final c = e.components.single;
    expect(
      [
        c.needsChoice,
        c.source!.name,
        c.alternatives.map((a) => a.name).toList(),
      ],
      [
        true,
        '올리브짜파게티',
        ['마라짜파게티'],
      ],
    );
    final ai = MealEstimate.fromJson({
      'kcal': 120,
      'requiresConfirmation': true,
      'refs': [],
      'components': [
        {
          'name': '무지개깨비죽',
          'evidence': '무지개깨비죽 한 그릇',
          'ref': null,
          'source': 'ai',
          'amount': 80,
          'unit': 'g',
          'kcalPer100': 150,
          'kcal': 120,
          'estimatedAmount': true,
        },
      ],
    });
    expect(
      [ai.components.single.ai, ai.components.single.source],
      [true, null],
    );
  });

  testWidgets('review keeps input precision and rounds only the final total', (
    tester,
  ) async {
    ReviewedMeal? saved;
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
