import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/local_ai.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';

const example = '벤치 80kg 100개 채우기';
const setup = WorkoutSetup(
  name: '벤치프레스',
  weight: 80,
  totalReps: 100,
  repsOnly: true,
);
final field = find.byType(CupertinoTextField);

class FakeAi extends LocalAi {
  FakeAi(this.current);
  LocalAiStatus current;
  int calls = 0;
  int checks = 0;
  int downloads = 0;
  bool fail = false;
  Completer<WorkoutSetup>? pending;
  Completer<LocalAiStatus>? pendingStatus;
  @override
  Future<LocalAiStatus> status(String locale) async {
    checks++;
    return pendingStatus?.future ?? current;
  }

  @override
  Future<WorkoutSetup> interpret(
    String text,
    String locale,
    List<String> names,
  ) async {
    calls++;
    if (fail) throw const FormatException('Cannot parse');
    return pending?.future ?? setup;
  }

  @override
  Future<void> prepare() async {
    downloads++;
    current = LocalAiStatus.available;
  }

  @override
  Future<void> cancel() async {}
}

Future<RoutineEditorController> pumpEditor(
  WidgetTester tester,
  FakeAi ai,
) async {
  final c = RoutineEditorController();
  await tester.pumpWidget(
    CupertinoApp(
      locale: const Locale('ko'),
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: CupertinoPageScaffold(
        resizeToAvoidBottomInset: false,
        child: SafeArea(
          child: RoutineEditor(controller: c, localAi: ai),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return c;
}

Future<void> submit(WidgetTester tester, String text) async {
  await tester.enterText(field, text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'AI output validation rejects malformed numbers and unsupported units',
    () {
      for (final patch in <Map<String, Object?>>[
        {'weight': -10},
        {'weight': double.nan},
        {'totalReps': 1.5},
        {'totalReps': 0},
        {'totalSets': '5'},
        {'unit': 'm'},
        {'name': ''},
      ]) {
        expect(
          () => WorkoutSetup.fromJson({...setup.toJson(), ...patch}),
          throwsFormatException,
        );
      }
      expect(WorkoutSetup.fromJson(setup.toJson()).totalReps, 100);
    },
  );

  test(
    'targets survive saving with no fake completed sets, and basic records still load',
    () {
      final c = RoutineEditorController()
        ..addExercise(setup.name, setup: setup);
      c.closeBlock();
      expect(c.blocks, hasLength(1));
      expect(c.totalSets, 0);
      final now = DateTime.now();
      final note = Note(
        id: '1',
        createdAt: now,
        updatedAt: now,
        blocks: c.blocks,
      );
      final restored = Note.fromJson(jsonDecode(jsonEncode(note.toJson())));
      expect(restored.blocks.single.setup!.totalReps, 100);
      expect(restored.blocks.single.sets, isEmpty);
      final old = note.toJson();
      final block = (old['blocks'] as List).single as Map;
      block.remove('setup');
      expect(Note.fromJson(old).blocks.single.setup, isNull);
      block['setup'] = {'name': '', 'totalReps': -1};
      expect(Note.fromJson(old).blocks.single.name, '벤치프레스');
    },
  );

  test(
    'only completed reps advance the goal and default weight is applied',
    () {
      final c = RoutineEditorController()
        ..addExercise(setup.name, setup: setup);
      c.addSet('20');
      c.addSet('15');
      expect(c.blocks.single.completedReps, 35);
      expect(c.lastSet!.value, 80);
      c.toggleDone(0, 0);
      expect(c.blocks.single.completedReps, 15);
      c.removeSet(0, 1);
      expect(c.blocks.single.completedReps, 0);
    },
  );

  test('native status and structured results use one local channel', () async {
    const channel = MethodChannel('test/local_ai');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'status') return 'intelligenceDisabled';
          return jsonEncode({'isExercise': true, 'name': setup.name, 'unit': 'kg', 'repsOnly': true, 'parameters': [{'kind': 'weight', 'value': 80, 'evidence': '80kg'}, {'kind': 'totalReps', 'value': 100, 'evidence': '100개 채우기'}]});
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    const ai = LocalAi(channel: channel, nativeSupported: true);
    expect(await ai.status('ko'), LocalAiStatus.intelligenceDisabled);
    expect((await ai.interpret(example, 'ko', ['벤치프레스'])).weight, 80);
    expect(calls.map((c) => c.method), ['status', 'interpret']);
    expect((calls.last.arguments as Map)['prompt'], contains(example));
    expect((calls.last.arguments as Map)['input'], example);
  });

  test('a response that silently drops stated numbers is rejected', () async {
    const channel = MethodChannel('test/local_ai_omission');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => jsonEncode({
            'isExercise': true,
            'name': '벤치프레스',
            'parameters': [],
            'unit': 'kg',
            'repsOnly': true,
          }),
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    const ai = LocalAi(channel: channel, nativeSupported: true);
    await expectLater(
      ai.interpret(example, 'ko', ['벤치프레스']),
      throwsFormatException,
    );
  });

  testWidgets(
    'unsupported users can log normally without any AI request or popup',
    (tester) async {
      final ai = FakeAi(LocalAiStatus.deviceNotEligible);
      final c = await pumpEditor(tester, ai);
      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(find.text('한 줄 설정 · 기본 입력'), findsOneWidget);
      await submit(tester, '스쿼트');
      expect(c.blocks.single.name, '스쿼트');
      expect(ai.calls, 0);
      expect(find.byType(SetKeypad), findsOneWidget);
    },
  );

  testWidgets(
    'disabled devices get activation instructions and refresh on resume',
    (tester) async {
      final ai = FakeAi(LocalAiStatus.intelligenceDisabled);
      await pumpEditor(tester, ai);
      await tester.tap(find.text('한 줄 설정 · 설정 필요'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Apple Intelligence 및 Siri'), findsOneWidget);
      expect(ai.downloads, 0);
      await tester.tap(find.text('완료'));
      await tester.pumpAndSettle();
      ai.current = LocalAiStatus.available;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('한 줄 설정 · 사용 가능'), findsOneWidget);
      expect(ai.checks, greaterThanOrEqualTo(2));
    },
  );

  testWidgets('model download starts only after the user chooses it', (
    tester,
  ) async {
    final ai = FakeAi(LocalAiStatus.downloadable);
    await pumpEditor(tester, ai);
    expect(ai.downloads, 0);
    await tester.tap(find.text('한 줄 설정 · 설정 필요'));
    await tester.pumpAndSettle();
    expect(find.textContaining('저장 공간'), findsOneWidget);
    await tester.tap(find.text('모델 준비'));
    await tester.pumpAndSettle();
    expect(ai.downloads, 1);
    expect(find.text('한 줄 설정 · 사용 가능'), findsOneWidget);
  });

  testWidgets('a plan sets weight and goal, then Next records reps directly', (
    tester,
  ) async {
    final ai = FakeAi(LocalAiStatus.available);
    final c = await pumpEditor(tester, ai);
    await submit(tester, example);
    expect(ai.calls, 1);
    expect(c.totalSets, 0);
    expect(find.text('80kg · 0/100회'), findsOneWidget);
    for (final digit in ['2', '0']) {
      await tester.tap(
        find.descendant(of: find.byType(SetKeypad), matching: find.text(digit)),
      );
      await tester.pump();
    }
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(c.lastSet!.value, 80);
    expect(c.lastSet!.reps, 20);
    expect(find.text('80kg · 20/100회'), findsOneWidget);
    expect(ai.calls, 1);
  });

  testWidgets('failure preserves the sentence and offers manual entry', (
    tester,
  ) async {
    final ai = FakeAi(LocalAiStatus.available)..fail = true;
    final c = await pumpEditor(tester, ai);
    await submit(tester, example);
    expect(c.blocks, isEmpty);
    expect(tester.widget<CupertinoTextField>(field).controller!.text, example);
    expect(find.textContaining('문장을 해석하지 못했습니다'), findsOneWidget);
    await tester.tap(find.text('운동 이름으로 사용'));
    await tester.pumpAndSettle();
    expect(c.blocks.single.name, example);
    expect(ai.calls, 1);
  });

  testWidgets('editing during inference discards a late answer', (
    tester,
  ) async {
    final ai = FakeAi(LocalAiStatus.available)
      ..pending = Completer<WorkoutSetup>();
    final c = await pumpEditor(tester, ai);
    await submit(tester, example);
    await tester.enterText(field, '푸시업 총 50개');
    ai.pending!.complete(setup);
    await tester.pumpAndSettle();
    expect(c.blocks, isEmpty);
    expect(
      tester.widget<CupertinoTextField>(field).controller!.text,
      '푸시업 총 50개',
    );
  });

  testWidgets(
    'a quick submission waits for availability rather than losing plan intent',
    (tester) async {
      final ai = FakeAi(LocalAiStatus.available)
        ..pendingStatus = Completer<LocalAiStatus>();
      final c = await pumpEditor(tester, ai);
      await submit(tester, example);
      expect(c.blocks, isEmpty);
      ai.pendingStatus!.complete(LocalAiStatus.available);
      await tester.pumpAndSettle();
      expect(c.blocks.single.setup!.totalReps, 100);
      expect(ai.calls, 1);
    },
  );
}
