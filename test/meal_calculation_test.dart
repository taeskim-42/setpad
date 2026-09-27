import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/meal.dart';
import 'package:setpad/meal_amount_sheet.dart';
import 'package:setpad/record_ai.dart';

void main() {
  test(
    'consumed totals and explicit same-unit proportions are calculated once',
    () {
      for (final (text, kcal) in [
        ('밥 300kcal, 반찬 200kcal, 총 500kcal', 500),
        ('밥 300kcal, 반찬 200kcal 합계 500kcal', 500),
        ('밥 300kcal, 반찬 200kcal, 전체 500kcal', 500),
        ('밥 300kcal, 반찬 200kcal, 총계500kcal', 500),
        ('밥 300kcal, 반찬 200kcal, 총합은500kcal', 500),
        ('밥 300kcal, 반찬 200kcal, 총합계는500kcal', 500),
        ('밥 300kcal, 반찬 200kcal, 합쳐서500kcal', 500),
        ('밥 300kcal, 국, 총 500kcal', 500),
        ('과자 1봉지 500kcal 반 봉지 먹음', 250),
        ('과자 1봉지 500kcal, 1/2봉지 먹음', 250),
        ('과자 한 봉지 500kcal ½봉지 먹음', 250),
        ('과자 100g당 500kcal 25g 섭취', 125),
        ('과자 1kg당 500kcal 500g 먹음', 250),
        ('음료 1,200ml당 600kcal 1.2L 마심', 600),
        ('과자 100g당 33.3kcal 300g 먹음', 100),
        ('과자 100g당 33.3kcal 300g 먹음, 총100kcal', 100),
        ('과자 반 봉지 250kcal', 250),
        ('당근 100g 40kcal', 40),
        ('식당 밥 300kcal', 300),
        ('프로틴 120kcal, 바나나 90kcal', 210),
        ('피자 2,000kcal', 2000),
        ('100kcal짜리 과자 3개', 300),
        ('과자 100kcal씩 3개', 300),
        ('과자 개당 100kcal 3개', 300),
      ]) {
        final parsed = parseMealText(text);
        expect(
          (parsed.kcal, parsed.typed, parsed.needsReview),
          (kcal, kcal, false),
          reason: text,
        );
      }
      final partial = parseMealText('닭가슴살 330kcal, 밥 한 공기');
      expect(
        (partial.kcal, partial.typed, partial.needsReview),
        (null, 330, false),
      );
    },
  );

  test(
    'ambiguous calorie expressions never become saved values or AI lower bounds',
    () {
      for (final text in [
        '김밥 300kcal~400kcal',
        '김밥 300~400kcal',
        '김밥 300kcal - 400kcal',
        '밥 300kcal 300kcal',
        '밥 300kcal, 300kcal, 김치',
        '밥 300kcal (300칼로리)',
        '과자 100g 500kcal 50g 250kcal',
        '밥 300kcal, 반찬 200kcal, 총 600kcal',
        '밥 300kcal, 반찬 200kcal, 총열량 600kcal',
        '밥 300kcal, 반찬 200kcal, 총 칼로리 600kcal',
        '밥 300kcal, 총 200kcal',
        '총 500kcal, 합계 600kcal',
        '과자 100g당 500kcal',
        '100kcal짜리 과자 300g',
        '과자 봉지당 100kcal 3개',
        '과자 500kcal/100g',
        '과자 500kcal 반만 먹음',
        '반만 먹은 과자500kcal',
        '절반만 먹은김밥500kcal',
        '과자500kcal 반의반만 먹음',
        '과자 100kcal씩 반개씩 두번',
        '과자 100kcal씩 2개씩 3번',
        '밥 －100g 150kcal',
        '밥 100g －150kcal',
        '밥 100g ﹣150kcal',
        '밥 300kcal에서 100kcal 뺌',
        '밥 300kcal에서 100kcal 빼서 먹음',
        '밥 100kcal에서 200kcal',
        '밥 300kcal 중 100kcal만 먹음',
        '밥 300kcal 중 100kcal 먹음',
        '과자 총500kcal 반만 먹음',
        '과자 총500kcal 반 봉지 먹음',
        '과자 500kcal, 절반 먹음',
        '김밥 500kcal 반 먹음',
        '김밥 500kcal 먹지 않음',
        '김밥 500kcal 안 먹음',
        '안 먹은 김밥 500kcal',
        '500kcal짜리 김밥 대신 300kcal 샌드위치 먹음',
        '김밥 500kcal 25% 먹음',
        '과자 500kcal 반 봉지 먹음',
        '과자 1봉지 500kcal 30g 먹음',
        '과자 -100g당 500kcal 20g 먹음',
        '과자 1 1/2봉지 500kcal 반 봉지 먹음',
        '음료 1,20,0kcal',
        '음료 -200kcal',
        '음료 1e3kcal',
        '음료 1O0kcal',
        '음료 200kcal 이상',
        '음료 100001kcal',
      ]) {
        final parsed = parseMealText(text);
        expect(
          (parsed.kcal, parsed.typed, parsed.needsReview),
          (null, null, true),
          reason: text,
        );
      }
    },
  );

  test('label quantities preserve grouping, fractions, and metric units', () {
    for (final (size, amount, unit) in [
      ('1,200ml', 1200.0, 'ml'),
      ('1,200g', 1200.0, 'g'),
      ('1.2L', 1200.0, 'ml'),
      ('1,2 L', 1200.0, 'ml'),
      ('0.5kg', 500.0, 'g'),
      ('1/2봉지', 0.5, '봉지'),
      ('½컵', 0.5, '컵'),
      ('1봉지 (80g)', 1.0, '봉지'),
      ('1 serving 35g', 35.0, 'g'),
    ]) {
      final basis = basesOf(
        NutritionLabel(perServingKcal: 600, servingSize: size),
      ).first;
      expect(
        (basis.amount, basis.unit, basis.kcalFor(amount)),
        (amount, unit, 600),
        reason: size,
      );
    }
    for (final size in [
      '1,20,0ml',
      '80~100g',
      '100g / 200g',
      '1 1/2컵',
      '1/0봉지',
      '-100g',
      '0g',
      '1개 반 (75g)',
      '두개반 (125g)',
    ]) {
      expect(
        basesOf(
          NutritionLabel(perServingKcal: 600, servingSize: size),
        ).map((b) => b.unit),
        [MealBasis.serving],
        reason: size,
      );
    }
  });

  test(
    'label and amount validation reject nonfinite or impossible values without rounding early',
    () {
      final label = NutritionLabel.tryFromJson({
        'perServingKcal': 33.3,
        'servingsPerPackage': 3,
      })!;
      expect(label.kcalFor(3), 100);
      expect(basesOf(label).last.kcalFor(1), 100);
      for (final invalid in [double.nan, double.infinity, -1, 100001]) {
        expect(NutritionLabel.tryFromJson({'perServingKcal': invalid}), isNull);
      }
      for (final invalid in [double.nan, double.infinity, -1, 0, 100001]) {
        expect(
          NutritionLabel.tryFromJson({
            'perServingKcal': 100,
            'servingsPerPackage': invalid,
          })!.servingsPerPackage,
          isNull,
        );
      }
      expect(label.kcalFor(double.infinity), isNull);
      expect(
        const MealBasis(
          kcal: 100,
          amount: double.infinity,
          unit: 'g',
        ).kcalFor(100),
        isNull,
      );
      for (final (text, expected) in [
        ('1,200', 1200.0),
        ('1,200.5', 1200.5),
        ('1,5', 1.5),
        ('0,125', 0.125),
      ]) {
        expect(parseMealAmount(text), expected);
      }
      for (final text in ['1,20,0', 'NaN', 'Infinity', '-3', '1e3']) {
        expect(parseMealAmount(text), isNull);
      }
    },
  );

  testWidgets(
    'amount editor reads 1,200 as 1200 and blocks malformed numbers',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      askMealAmount(
        context,
        bases: [const MealBasis(kcal: 600, amount: 1200, unit: 'ml')],
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('meal-basis-amount')),
        '1,200',
      );
      await tester.enterText(find.byKey(const ValueKey('meal-eaten')), '1,200');
      await tester.pump();
      expect(find.text('600kcal'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('meal-eaten')),
        '1,20,0',
      );
      await tester.pump();
      expect(find.text('600kcal'), findsNothing);
      final done = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, '완료'),
      );
      expect(done.onPressed, isNull);
    },
  );
  test(
    'all API estimates require review and contradictory label totals are rejected',
    () {
      for (final n in [0, 50, 33.3]) {
        final label = NutritionLabel.tryFromJson({
          'perServingKcal': n,
          'servingSize': '100g',
        })!;
        expect(label.kcalFor(1), n.round());
        expect(
          MealEstimate.fromJson({
            'kcal': n,
            'label': {'perServingKcal': n, 'servingSize': '100g'},
          }).requiresConfirmation,
          isTrue,
        );
      }
      expect(
        () => MealEstimate.fromJson({
          'kcal': 500,
          'label': {'perServingKcal': 50, 'servingSize': '100g'},
        }),
        throwsA(isA<RecordAiException>()),
      );
      expect(
        MealEstimate.fromJson({
          'kcal': 100,
          'requiresConfirmation': false,
          'components': [
            {
              'name': '밥',
              'evidence': '밥100kcal',
              'source': 'typed',
              'ref': null,
              'amount': null,
              'unit': null,
              'kcalPer100': null,
              'kcal': 100,
              'estimatedAmount': false,
            },
          ],
        }).requiresConfirmation,
        isTrue,
      );
      for (final invalid in [-1, double.infinity, double.nan, '500']) {
        expect(
          () => MealEstimate.fromJson({
            'kcal': 100,
            'label': {'perServingKcal': invalid},
          }),
          throwsA(isA<RecordAiException>()),
        );
      }
      for (final size in ['0g', '-100g', '1,20,0ml']) {
        final label = NutritionLabel.tryFromJson({
          'perServingKcal': 100,
          'servingSize': size,
        })!;
        expect(basesOf(label).map((b) => b.unit), [MealBasis.serving]);
      }
    },
  );

  testWidgets(
    'correcting OCR basis removes alternatives derived from the rejected values',
    (tester) async {
      final bases = basesOf(
        const NutritionLabel(
          perServingKcal: 300,
          servingSize: '100g',
          servingsPerPackage: 3,
        ),
      );
      ({MealBasis basis, double eaten})? saved;
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: Builder(
            builder: (context) => CupertinoButton(
              child: const Text('open'),
              onPressed: () async => saved = await askMealAmount(
                context,
                bases: bases,
                allowUnitEdit: true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        find.byType(CupertinoSlidingSegmentedControl<int>),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const ValueKey('meal-eaten')), '150');
      await tester.pump();
      expect(
        find.byType(CupertinoSlidingSegmentedControl<int>),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('meal-basis-kcal')),
        '30',
      );
      await tester.pump();
      expect(find.byType(CupertinoSlidingSegmentedControl<int>), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('meal-basis-amount')),
        '50',
      );
      await tester.enterText(
        find.byKey(const ValueKey('meal-basis-unit')),
        'ml',
      );
      await tester.pump();
      final done = find.byKey(const ValueKey('meal-review-confirm'));
      await tester.ensureVisible(done);
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(
        (
          saved!.basis.kcal,
          saved!.basis.amount,
          saved!.basis.unit,
          saved!.eaten,
        ),
        (30, 50, 'ml', 150),
      );
      expect(saved!.basis.kcalFor(saved!.eaten), 90);
    },
  );
}
