// 공동 루틴 화면 — 그물이 없을 때도 초안은 남고, 합의라고 말하지 않는가.
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/plans.dart';
import 'package:setpad/plans_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('오프라인: 친 계획은 이 기기에 남고, 합의 완료라고 하지 않으며, 본인용 사본으로 시작한다', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('setpad_plan_page_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final notes = NotesStore(directory: dir);
    final plans = PlanStore(
      directory: dir,
      link: () => GymLink(
        endpoint: 'https://x',
        token: 'member',
        client: MockClient((_) async => throw http.ClientException('offline')),
      ),
    );
    final plan = SharedPlan(localId: 'p-local');
    plans.add(plan);
    Note? opened;
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: PlanPage(
          plan: plan,
          plans: plans,
          notes: notes,
          onOpenNote: (n) => opened = n,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(
      find.byKey(const ValueKey('plan-text')),
      '내일 하체\n스쿼트 4세트\n민수식 로우 2\n레그컬 x3',
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(plan.draft!.items.map((i) => (i.name, i.sets)), [
      ('스쿼트', 4),
      ('민수식 로우 2', 0),
      ('레그컬', 3),
    ]);
    // 구조로도 보인다.
    expect(find.text('스쿼트 · 4세트'), findsOneWidget);
    expect(find.text('민수식 로우 2'), findsWidgets);

    await tester.tap(find.text('제안하기'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(plan.id, isNull, reason: '서버에 못 올렸다');
    expect(plan.draft!.title, '내일 하체', reason: '초안은 이 기기에 남는다');
    expect(find.textContaining('합의 완료'), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('plan-state'))).data,
      contains('이 기기에만 있는 초안'),
    );

    // 합의 전에 혼자 시작하면 본인용 사본이다 — 완료한 세트는 하나도 없다.
    expect(find.text('이 루틴으로 시작'), findsNothing);
    expect(find.textContaining('아직 합의 전입니다'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('plan-start')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('plan-start')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(opened, isNotNull);
    expect(opened!.planAgreed, isFalse);
    expect(opened!.blocks.map((b) => (b.name, b.sets.length)), [
      ('스쿼트', 4),
      ('민수식 로우 2', 0),
      ('레그컬', 3),
    ]);
    expect(opened!.blocks.expand((b) => b.sets).any((s) => s.done), isFalse);
    expect(plan.startPending, isTrue, reason: '시작은 나중에 서버에 알린다');
    expect(find.textContaining('본인용 사본'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
    notes.dispose();
  });
}
