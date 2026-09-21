// 공동 루틴 화면 — 그물이 없을 때도 초안은 남고, 합의라고 말하지 않는가.
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
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

  testWidgets('운동 기록 화면에서 바로 공동 루틴으로 제안한다 — 적은 것이 없으면 버튼도 없다', (tester) async {
    final dir = Directory.systemTemp.createTempSync('setpad_propose_');
    final store = NotesStore(directory: dir);
    addTearDown(() {
      store.dispose();
      dir.deleteSync(recursive: true);
    });
    final proposed = <SharedPlan>[];
    Future<void> mount(Note note) async {
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: EditorPage(store: store, note: note, onPlanNext: proposed.add),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    await mount(store.create());
    expect(find.byKey(const ValueKey('propose-plan')), findsNothing);
    await tester.pumpWidget(const SizedBox());

    final note = store.create()
      ..blocks.addAll([
        ExerciseBlock('스쿼트', [
          LoggedSet(value: 100, reps: 5),
          LoggedSet(value: 105, reps: 3),
        ]),
        ExerciseBlock('민수식 로우 2', [LoggedSet(value: 40, reps: 12)]),
      ]);
    await mount(note);
    expect(find.text('공동 루틴으로 제안'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('propose-plan')));
    await tester.pump();
    final draft = proposed.single;
    expect(draft.shown.items.map((i) => (i.name, i.sets)), [
      ('스쿼트', 2),
      ('민수식 로우 2', 1),
    ]);
    // 내 목표는 마지막에 한 무게·횟수에서 온다. 기록은 바뀌지 않는다.
    expect(draft.myTargets[draft.shown.items.first.id]!.value, 105);
    expect(note.blocks.first.sets.length, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('제안한 초안은 목록에 남고 두 번 눌러도 하나다. 로그인 전에는 안내를 가리지 않고, 로그인하면 그 초안으로 간다', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('setpad_propose_gate_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final client = MockClient((_) async => throw http.ClientException('off'));
    final plans = PlanStore(
      directory: dir,
      link: () =>
          GymLink(endpoint: 'https://x', token: 'member', client: client),
    );
    final blocks = [
      ExerciseBlock('스쿼트', [LoggedSet(value: 100, reps: 5)]),
    ];
    final first = plans.adopt(planFromBlocks('하체', blocks));
    final again = plans.adopt(planFromBlocks('하체', blocks));
    expect(identical(first, again), isTrue);
    expect(plans.plans, hasLength(1));
    // 내용이 다르면 다른 초안이다.
    plans.adopt(planFromBlocks('상체', blocks));
    expect(plans.plans, hasLength(2));

    final account = Account(client: client);
    final notes = NotesStore(directory: dir);
    addTearDown(notes.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: PlansPage(
          plans: plans,
          account: account,
          notes: notes,
          open: first,
          onOpenNote: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PlanPage), findsNothing, reason: '로그인 안내가 먼저다');

    account.token = 'member';
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    account.notifyListeners();
    await tester.pump();
    // 새 화면은 첫 프레임에 화면 밖에서 지어지고, 다음 프레임에 들어온다.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(PlanPage), findsOneWidget);
    expect(find.textContaining('스쿼트'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
