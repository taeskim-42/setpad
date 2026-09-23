// 공동 루틴 화면 — 그물이 없을 때도 초안은 남고, 합의라고 말하지 않는가.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/editor.dart';
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

  testWidgets('셋이 짜는 계획: 사람마다 동의 여부와 목표가 보이고, 자리가 남았으면 주인이 더 부른다', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('setpad_plan_group_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final notes = NotesStore(directory: dir);
    addTearDown(notes.dispose);
    Map<String, Object?> body(int version) => {
      'id': '11111111-1111-4111-8111-111111111111',
      'role': 'owner',
      'state': 'pending',
      'partner': '준',
      'version': version,
      'editedByMe': true,
      'title': '토요일 상체',
      'plannedOn': null,
      'items': [
        {'id': 'a', 'name': '벤치프레스', 'sets': 4},
      ],
      'acceptedByMe': version,
      'acceptedByPartner': version,
      'agreed': null,
      'room': 3,
      'invite': {
        'code': 'ABCD23',
        'expiresAt': DateTime.now()
            .add(const Duration(minutes: 9))
            .toIso8601String(),
      },
      'myTargets': {'revision': 0, 'targets': {}},
      'partnerTargets': null,
      'myStart': null,
      'partnerStart': null,
      'withdrawnByMe': null,
      'members': [
        {
          'key': 'aaaa1111',
          'name': '준',
          'accepted': version,
          'targets': {
            'revision': 1,
            'targets': {
              'a': {'value': 80, 'unit': 'kg', 'reps': 5, 'sets': 4},
            },
          },
          'start': null,
        },
        {
          'key': 'bbbb2222',
          'name': '소라',
          'accepted': null,
          'targets': null,
          'start': null,
        },
      ],
    };
    final plans = PlanStore(
      directory: dir,
      link: () => GymLink(
        endpoint: 'https://x',
        token: 'member',
        client: MockClient(
          (_) async =>
              http.Response.bytes(utf8.encode(jsonEncode(body(2))), 200),
        ),
      ),
    );
    final plan = SharedPlan(localId: 'p-group')..apply(body(2));
    plans.add(plan);
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: PlanPage(
          plan: plan,
          plans: plans,
          notes: notes,
          onOpenNote: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(plan.members.map((m) => m.name), ['준', '소라']);
    expect(plan.partner, '준, 소라');
    expect(find.text('준 님 동의함'), findsOneWidget);
    expect(find.text('소라 님 확인 전'), findsOneWidget);
    expect(find.textContaining('준: '), findsOneWidget, reason: '준의 목표가 한 줄');
    // 상대가 이미 있어도 자리가 남았으니 코드가 보인다.
    expect(find.byKey(const ValueKey('plan-code-shown')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('계획 줄에 적은 무게·횟수는 이름에 섞이지 않고 내 목표가 되며, 치던 글이 지워지지 않는다', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('setpad_plan_target_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final notes = NotesStore(directory: dir);
    addTearDown(notes.dispose);
    final plans = PlanStore(
      directory: dir,
      link: () => GymLink(
        endpoint: 'https://x',
        token: 'member',
        client: MockClient((_) async => throw http.ClientException('offline')),
      ),
    );
    final plan = SharedPlan(
      localId: 'p-target',
      content: const PlanContent(
        title: '하체',
        items: [PlanItem(id: 'a', name: '벤치', sets: 3)],
      ),
    );
    plans.add(plan);
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: PlanPage(
          plan: plan,
          plans: plans,
          notes: notes,
          onOpenNote: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final box = find.byKey(const ValueKey('plan-text'));
    String text() => tester.widget<CupertinoTextField>(box).controller!.text;
    expect(text(), '하체\n벤치 3세트');

    // 있던 줄에 무게·횟수를 덧붙인다 — 공통 계획은 그대로고 내 목표가 된다.
    await tester.enterText(box, '하체\n벤치 3세트 80kg 5회');
    await tester.pump(const Duration(milliseconds: 100));
    expect(plan.draft, isNull, reason: '공통 계획은 바뀌지 않았다');
    final mine = plan.myTargets['a']!;
    expect((mine.value, mine.unit, mine.reps), (80, 'kg', 5));
    expect(find.text('내 목표: 80kg · 5회'), findsOneWidget);
    // 새 소식이 와도 치던 글은 그대로다.
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    plans.notifyListeners();
    await tester.pump(const Duration(milliseconds: 100));
    expect(text(), '하체\n벤치 3세트 80kg 5회');

    // 'AxB' 는 세트 수×횟수다 — 이름에 숫자가 섞이지 않는다.
    await tester.enterText(box, '하체\n벤치 3세트 80kg 5회\n스쿼트 5x5');
    await tester.pump(const Duration(milliseconds: 100));
    expect(plan.draft!.items.map((i) => (i.name, i.sets)), [
      ('벤치', 3),
      ('스쿼트', 5),
    ]);
    final squat = plan.draft!.items.last.id;
    expect(plan.myTargets[squat]?.reps, 5);
    expect(plan.myTargets['a']?.value, 80, reason: '안 바꾼 줄의 목표는 다시 쓰지 않는다');

    // 목표 칸에서 고친 것은 다른 줄을 쳐도 되돌아가지 않는다.
    await tester.tap(find.text('벤치 · 3세트'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const ValueKey('plan-target')),
      '100 5 5 5',
    );
    await tester.tap(find.text('확인'));
    await tester.pump(const Duration(milliseconds: 300));
    final edited = plan.myTargets['a']!;
    expect((edited.value, edited.reps, edited.note), (100, 5, '5 5'));
    await tester.enterText(box, '하체\n벤치 3세트 80kg 5회\n스쿼트 5x5\n런지');
    await tester.pump(const Duration(milliseconds: 100));
    expect(plan.myTargets['a']!.value, 100);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  group('계획 글은 다시 열어도 같은 계획이다', () {
    Future<SharedPlan> open(
      WidgetTester tester,
      PlanContent content, {
      void Function(http.Request)? onRequest,
    }) async {
      final dir = Directory.systemTemp.createTempSync('setpad_plan_again_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final notes = NotesStore(directory: dir);
      addTearDown(notes.dispose);
      final plans = PlanStore(
        directory: dir,
        link: () => GymLink(
          endpoint: 'https://x',
          token: 'member',
          client: MockClient((r) async {
            onRequest?.call(r);
            throw http.ClientException('offline');
          }),
        ),
      );
      final plan = SharedPlan(localId: 'p', content: content)
        ..id = 'srv'
        ..owner = false
        ..state = PlanState.pending
        ..version = 2
        ..myTargets = {'a': const PlanTarget(value: 80, unit: 'kg')};
      plans.add(plan);
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: PlanPage(
            plan: plan,
            plans: plans,
            notes: notes,
            onOpenNote: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      return plan;
    }

    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    }

    testWidgets('첫 종목에 목표만 적어 제목 없이 저장된 계획 — 수락할 수 있고 종목과 목표가 보인다', (
      tester,
    ) async {
      // '벤치 80kg\n스쿼트 5세트' 를 쳐서 올린 계획이 이렇다.
      final plan = await open(
        tester,
        const PlanContent(
          items: [
            PlanItem(id: 'a', name: '벤치', sets: 0),
            PlanItem(id: 'b', name: '스쿼트', sets: 5),
          ],
        ),
      );
      expect(plan.draft, isNull);
      expect(find.text('버전 2 수락'), findsOneWidget);
      expect(find.text('제안하기'), findsNothing);
      expect(find.text('내 목표: 80kg'), findsOneWidget);
      expect(find.text('스쿼트 · 5세트'), findsOneWidget);
      await close(tester);
    });

    testWidgets('수가 든 옛 제목("스트롱리프트 5x5")은 제목으로 남아 수락할 수 있다', (tester) async {
      final plan = await open(
        tester,
        const PlanContent(
          title: '스트롱리프트 5x5',
          items: [PlanItem(id: 'a', name: '스쿼트', sets: 5)],
        ),
      );
      expect(plan.draft, isNull);
      expect(find.text('버전 2 수락'), findsOneWidget);
      expect(find.text('제안하기'), findsNothing);
      await close(tester);
    });

    testWidgets('목표 글이 든 줄의 이름을 고쳐도 고아 목표가 쌓이지 않고, 목표는 한 번에 보낸다', (
      tester,
    ) async {
      var puts = 0;
      final plan = await open(
        tester,
        const PlanContent(
          title: '하체',
          items: [PlanItem(id: 'a', name: '벤치프레스', sets: 3)],
        ),
        onRequest: (r) {
          if (r.method == 'PUT' && r.url.path.endsWith('/targets')) puts++;
        },
      );
      final box = find.byKey(const ValueKey('plan-text'));
      for (final name in ['벤치프레스', '벤치프레', '벤치프', '벤치', '벤', '벤치', '인클라인 벤치']) {
        await tester.enterText(box, '하체\n$name 3세트 80kg 5회');
        await tester.pump(const Duration(milliseconds: 50));
      }
      final ids = plan.shown.items.map((i) => i.id).toSet();
      expect(plan.myTargets.keys.where((k) => !ids.contains(k)), isEmpty);
      final mine = plan.myTargets[plan.shown.items.single.id]!;
      expect((mine.value, mine.reps), (80, 5));
      expect(puts, 0, reason: '치는 동안에는 보내지 않는다');
      await tester.pump(const Duration(seconds: 2));
      expect(puts, 1);
      await close(tester);
    });
  });
}
