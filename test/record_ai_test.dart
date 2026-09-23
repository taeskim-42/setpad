import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/record_ai.dart';
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

class FakeAi extends RecordAi {
  FakeAi(this.current);
  RecordAiStatus current;
  int calls = 0;
  int checks = 0;
  bool fail = false;
  Completer<WorkoutSetup>? pending;
  Completer<RecordAiStatus>? pendingStatus;
  @override
  Future<RecordAiStatus> status(String locale) async {
    checks++;
    return pendingStatus?.future ?? current;
  }

  @override
  Future<WorkoutSetup> interpret(
    String text,
    String locale,
    List<String> names, {
    String defaultWeightUnit = 'kg',
  }) async {
    calls++;
    if (fail) throw const FormatException('Cannot parse');
    return pending?.future ?? setup;
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
          child: RoutineEditor(controller: c, ai: ai),
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
    'unsupported schedules and durations cannot become partial setups',
    () async {
      final ai = RecordAi(
        respond: (_, _) async => throw StateError('물어보면 안 된다'),
      );
      for (final text in [
        '내일 벤치 80kg 10회',
        '월요일 스쿼트 60kg 5세트',
        '벤치 80kg 10회 30초 휴식',
        'tomorrow squat 60kg 5 sets',
      ]) {
        await expectLater(
          ai.interpret(text, 'ko', ['벤치프레스', '스쿼트']),
          throwsFormatException,
          reason: text,
        );
      }
    },
  );

  testWidgets(
    'canceling a numeric proposal preserves input and writes nothing',
    (tester) async {
      final c = await pumpEditor(tester, FakeAi(RecordAiStatus.ready));
      await submit(tester, example);
      expect(c.blocks, isEmpty);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(c.blocks, isEmpty);
      expect(
        tester.widget<CupertinoTextField>(field).controller!.text,
        example,
      );
    },
  );

  testWidgets('corrected numbers are applied only after confirmation', (
    tester,
  ) async {
    final c = await pumpEditor(tester, FakeAi(RecordAiStatus.ready));
    await submit(tester, example);
    final weight = find.byType(CupertinoTextFormFieldRow).at(1);
    await tester.enterText(weight, '82.125');
    expect(c.blocks, isEmpty);
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(c.blocks.single.setup!.weight, 82.125);
    // 해석기는 '벤치프레스' 라고 답했지만 사람이 친 것은 '벤치' 다. 약어를 풀어
    // 저장 이름을 바꾸지 않는다 — 바꾸려면 후보를 직접 누른다.
    expect(c.blocks.single.name, '벤치');
    expect(c.blocks.single.sets, isEmpty);
  });

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

  test('a response that silently drops stated numbers is rejected', () async {
    final ai = RecordAi(
      respond: (_, _) async => {
        'isExercise': true,
        'name': '벤치프레스',
        'parameters': [],
        'unit': 'kg',
        'repsOnly': true,
      },
    );
    await expectLater(
      ai.interpret(example, 'ko', ['벤치프레스']),
      throwsFormatException,
    );
  });

  testWidgets('a plan sets weight and goal, then Next records reps directly', (
    tester,
  ) async {
    final ai = FakeAi(RecordAiStatus.ready);
    final c = await pumpEditor(tester, ai);
    await submit(tester, example);
    expect(ai.calls, 1);
    expect(c.blocks, isEmpty, reason: 'Unconfirmed numbers are never applied');
    expect(find.textContaining('숫자와 조건을 확인'), findsOneWidget);
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(c.totalSets, 0);
    expect(find.text('80kg · 0/100회'), findsOneWidget);
    // 친 문장이 제목으로 남는다. 이 칸이 가리키는 운동은 **친 이름**('벤치')
    // 이고 사전에 익히는 것도 그 이름이다 — 문장이 다음 후보로 뜨면 안 되고,
    // 해석기가 고른 '벤치프레스' 로 기록이 합쳐져도 안 된다.
    expect(c.blocks.single.name, example);
    expect(c.blocks.single.exercise, '벤치');
    expect(c.recentExercises.first, '벤치');
    expect(find.text(example), findsOneWidget);
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
    final ai = FakeAi(RecordAiStatus.ready)..fail = true;
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
    final ai = FakeAi(RecordAiStatus.ready)
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
      final ai = FakeAi(RecordAiStatus.ready)
        ..pendingStatus = Completer<RecordAiStatus>();
      final c = await pumpEditor(tester, ai);
      await submit(tester, example);
      expect(c.blocks, isEmpty);
      ai.pendingStatus!.complete(RecordAiStatus.ready);
      await tester.pumpAndSettle();
      expect(c.blocks, isEmpty);
      await tester.tap(find.text('완료'));
      await tester.pumpAndSettle();
      expect(c.blocks.single.setup!.totalReps, 100);
      expect(ai.calls, 1);
    },
  );

  test('429 중 IP 하루 한도는 이번 달 한도가 아니다', () async {
    Future<RecordAiStatus?> statusOf(Map<String, Object?> body) async {
      final ai = RecordAi(
        endpoint: 'https://example.com',
        deviceId: 'device',
        client: MockClient(
          (request) async => request.url.path == '/api/device'
              ? http.Response(jsonEncode({'token': 't'}), 200)
              : http.Response(jsonEncode(body), 429),
        ),
      );
      try {
        await ai.ask('i', 'q', contract: 2);
      } on RecordAiException catch (e) {
        return e.status;
      }
      return null;
    }

    expect(
      await statusOf({'error': 'quotaExceeded', 'limit': 30}),
      RecordAiStatus.quotaExceeded,
    );
    expect(
      await statusOf({
        'error': 'quotaExceeded',
        'limit': 300,
        'scope': 'address',
      }),
      RecordAiStatus.unavailable,
    );
  });
}
