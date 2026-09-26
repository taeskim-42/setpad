import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/daily.dart';
import 'package:setpad/day_energy.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';

Future<void> pump(WidgetTester tester, DayLog day) => tester.pumpWidget(
  CupertinoApp(
    locale: const Locale('ko'),
    localizationsDelegates: L.localizationsDelegates,
    supportedLocales: L.supportedLocales,
    home: CupertinoPageScaffold(child: Center(child: DayEnergy(day))),
  ),
);

void main() {
  final day = DateTime(2026, 9, 25);
  Note workout(int? kcal) => Note(
    id: '1',
    createdAt: day.add(const Duration(hours: 7)),
    updatedAt: day,
  )..calories = kcal?.toDouble();

  testWidgets('먹은 것 · 운동 · 차이를 세 칸으로 — 어림은 "약" 이 아니라 추정 표시', (tester) async {
    final note = workout(512)
      ..meals.addAll([
        MealEntry(
          at: day.add(const Duration(hours: 8)),
          kcal: 330,
          source: MealEntry.estimate,
          text: '계란',
        ),
        MealEntry(
          at: day.add(const Duration(hours: 12)),
          kcal: 840,
          source: MealEntry.estimate,
          text: '제육',
        ),
      ]);
    await pump(tester, dayLogs([note], from: day, to: day).single);
    expect(find.text('1,170 kcal'), findsOneWidget);
    expect(find.text('−512 kcal'), findsOneWidget);
    expect(find.text('+658 kcal'), findsOneWidget);
    expect(find.text('추정'), findsNWidgets(2), reason: '먹은 것과 차이에');
    expect(find.textContaining('약'), findsNothing);
  });

  testWidgets('차이는 셈을 늘 적고, 누르면 무엇이 빠진 값인지 말한다', (tester) async {
    await pump(tester, dayLogs([workout(512)], from: day, to: day).single);
    expect(find.text('미기록'), findsOneWidget, reason: '안 적은 식단은 0 이 아니다');
    expect(find.text('먹은 것 − 운동'), findsOneWidget, reason: '값이 없어도 무엇의 차이인지');
    await tester.tap(find.text('차이'));
    await tester.pumpAndSettle();
    expect(find.textContaining('기초대사량'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('기초대사량'), findsNothing);
  });

  testWidgets('기초대사량이 있으면 운동 칸은 쓴 것(기초 + 운동), 차이는 먹은 것 − 쓴 것', (tester) async {
    final note = workout(500)
      ..meals.add(
        MealEntry(
          at: day.add(const Duration(hours: 12)),
          kcal: 2400,
          source: MealEntry.typed,
          text: '밥',
        ),
      );
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: CupertinoPageScaffold(
          child: Center(
            child: DayEnergy(
              dayLogs([note], from: day, to: day).single,
              basal: (kcal: 1700, estimate: true),
            ),
          ),
        ),
      ),
    );
    expect(find.text('쓴 것'), findsOneWidget);
    expect(find.text('−2,200 kcal'), findsOneWidget);
    expect(find.text('+200 kcal'), findsOneWidget);
    expect(find.textContaining('기초 1,700 + 운동 500'), findsOneWidget);
    expect(find.text('추정'), findsWidgets, reason: '몸 정보로 셈한 기초대사는 추정');
  });
}
