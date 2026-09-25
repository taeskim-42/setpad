import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/workout_timing.dart';

const example = '벤치 80kg 100개 채우기';
const setup = WorkoutSetup(
  name: '벤치프레스',
  weight: 80,
  totalReps: 100,
  repsOnly: true,
);

/// 모델의 답(contract 2). 가짜도 진짜와 같은 디코더를 탄다.
Map<String, Object?> answerFor(
  List<Map<String, Object?>> exercises, [
  List<String> unparsed = const [],
]) => {'exercises': exercises, 'unparsed': unparsed};
final benchAnswer = answerFor([
  {'text': example, ...setup.toJson()},
]);
final field = find.byType(CupertinoTextField);

class FakeAi extends RecordAi {
  FakeAi(this.current);
  RecordAiStatus current;
  int calls = 0;
  int checks = 0;
  Object? error;
  Map<String, Object?>? answer;
  Completer<Map<String, Object?>>? pending;
  Completer<RecordAiStatus>? pendingStatus;
  @override
  Future<RecordAiStatus> status(String locale) async {
    checks++;
    return pendingStatus?.future ?? current;
  }

  @override
  Future<SetupReading> interpret(
    String text,
    String locale,
    List<String> names, {
    String defaultWeightUnit = 'kg',
  }) async {
    calls++;
    if (error case final e?) throw e;
    return readSetupAnswer(
      text,
      await (pending?.future ?? Future.value(answer ?? benchAnswer)),
    );
  }

  @override
  Future<void> cancel() async {}
}

Future<RoutineEditorController> pumpEditor(
  WidgetTester tester,
  FakeAi ai, {
  RoutineEditorController? controller,
}) async {
  final c = controller ?? RoutineEditorController();
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

/// 칩을 눌러 그 자리에서 고치기 시작한다. 확인 창은 없다.
Future<void> editChip(WidgetTester tester, String key, String text) async {
  await tester.tap(find.byKey(ValueKey('setup-$key')));
  await tester.pump();
  await tester.pump();
  // 누른 칩이 포커스를 받아야 기기에서 키보드가 그 칸에 뜬다. enterText 는
  // 포커스를 스스로 주므로 먼저 따로 본다.
  expect(chipFocused(tester, key), isTrue, reason: '칩 $key 이 포커스를 받는다');
  await tester.enterText(find.byKey(ValueKey('setup-field-$key')), text);
  await tester.pump();
}

bool chipFocused(WidgetTester tester, String key) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(ValueKey('setup-field-$key')),
        matching: find.byType(EditableText),
      ),
    )
    .focusNode
    .hasFocus;

Future<void> applyChip(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('setup-apply')));
  await tester.pumpAndSettle();
}

CupertinoButton applyButton(WidgetTester tester) =>
    tester.widget(find.byKey(const ValueKey('setup-apply')));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('X3: 일정·시간이 든 글도 모델이 받고, 칸에 못 담는 말은 못 옮긴 말로 남는다', () async {
    final asked = <String>[];
    final ai = RecordAi(
      respond: (_, input) async {
        asked.add(input);
        return answerFor(
          [
            {
              'text': '벤치 80kg 10회',
              'name': '벤치프레스',
              'weight': 80,
              'repsPerSet': 10,
            },
          ],
          ['내일', '모레'],
        );
      },
    );
    final reading = await ai.interpret('내일 벤치 80kg 10회', 'ko', ['벤치프레스']);
    expect(asked, hasLength(1));
    expect(reading.exercises.single.setup.weight, 80);
    expect(reading.exercises.single.setup.repsPerSet, 10);
    expect(reading.exercises.single.setup.name, '벤치', reason: '친 이름');
    expect(reading.unparsed, ['내일'], reason: '글에 없는 "모레" 는 지어낸 말이라 버린다');
    // 모델이 '30초' 를 빠뜨려도 앱이 직접 넣는다.
    final rest = await RecordAi(
      respond: (_, _) async => answerFor([
        {'name': '벤치', 'weight': 80, 'repsPerSet': 10},
      ]),
    ).interpret('벤치 80kg 10회 30초 휴식', 'ko', const []);
    expect(rest.unparsed, ['30초']);
    expect(rest.titles, ['벤치 80kg 10회 30초 휴식']);
  });

  testWidgets('X14: 읽은 줄은 확인 창 없이 바로 칸이 된다 — 페이지를 옮기지 않는다', (tester) async {
    final c = await pumpEditor(tester, FakeAi(RecordAiStatus.ready));
    await submit(tester, example);
    expect(c.blocks.single.name, example);
    expect(c.blocks.single.setup!.totalReps, 100);
    expect(find.byType(CupertinoTextFormFieldRow), findsNothing);
    expect(find.text('80kg'), findsOneWidget, reason: '읽은 값은 칸의 칩으로 보인다');
    expect(
      Navigator.of(tester.element(field)).canPop(),
      isFalse,
      reason: '새 화면이 없다',
    );
    expect(tester.widget<CupertinoTextField>(field).controller!.text, isEmpty);
  });

  testWidgets('읽은 수가 틀렸으면 칩을 눌러 그 자리에서 고친다', (tester) async {
    final c = await pumpEditor(tester, FakeAi(RecordAiStatus.ready));
    await submit(tester, example);
    await editChip(tester, 'weight', '82.125');
    expect(c.blocks.single.setup!.weight, 80, reason: '✓ 전에는 그대로다');
    await applyChip(tester);
    expect(c.blocks.single.setup!.weight, 82.125);
    // 해석기는 '벤치프레스' 라고 답했지만 사람이 친 것은 '벤치' 다. 약어를 풀어
    // 저장 이름을 바꾸지 않는다 — 바꾸려면 후보를 직접 누른다.
    expect(c.blocks.single.exercise, '벤치');
    // 칩에서 값을 고쳐도 제목은 친 글 그대로다.
    expect(c.blocks.single.name, example);
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

  test('X8: 친 수를 빠뜨린 답은 던지지 않고, 빠진 수가 든 낱말을 보인다', () async {
    final ai = RecordAi(
      respond: (_, _) async => answerFor([
        {'name': '벤치프레스', 'unit': 'kg', 'repsOnly': true},
      ]),
    );
    final reading = await ai.interpret(example, 'ko', ['벤치프레스']);
    expect(reading.exercises.single.setup.hasPlan, isFalse);
    expect(reading.unparsed, ['80kg', '100개']);
  });

  test('X8: 보고된 문장 — "1칸" 이 남아도 운동은 만들어지고 1칸은 보인다', () async {
    const text = 'bpm 푸시업 1칸 100개 채우기';
    final reading = readSetupAnswer(
      text,
      answerFor([
        {'text': text, 'name': '푸시업', 'totalReps': 100, 'repsOnly': true},
      ]),
    );
    expect(reading.exercises.single.setup.totalReps, 100);
    expect(reading.exercises.single.setup.name, '푸시업');
    expect(reading.unparsed, ['1칸']);
    expect(reading.titles, [text], reason: 'bpm 타이머는 제목에서 붙는다');
    // 부호를 읽지 않는다: 8-12 는 8 과 12, 3-1-1 은 3·1·1.
    final range = readSetupAnswer(
      '벤치 60kg 8-12회 3세트',
      answerFor([
        {'name': '벤치', 'weight': 60, 'totalSets': 3},
      ]),
    );
    expect(range.unparsed, ['8-12회']);
    expect(range.dropped, isEmpty);
    // "한 세트에 10개" 의 한 세트는 세트당이라는 말이다 — 못 옮긴 말이 아니다.
    expect(
      readSetupAnswer(
        '푸시업 한 세트에 열 개씩 다섯 세트',
        answerFor([
          {'name': '푸시업', 'repsPerSet': 10, 'totalSets': 5, 'repsOnly': true},
        ]),
      ).unparsed,
      isEmpty,
    );
  });

  test('X8: 글에 없는 수는 칸에서 빼고 알린다 — 글로 쓴 수는 친 수다', () {
    final reading = readSetupAnswer(
      '푸시업 총 백 개',
      answerFor([
        {'name': '푸시업', 'totalReps': 100, 'totalSets': 5, 'repsOnly': true},
      ]),
    );
    expect(reading.exercises.single.setup.totalReps, 100);
    expect(reading.exercises.single.setup.totalSets, isNull);
    expect(reading.dropped, ['5']);
  });

  test('X7: 칸에 못 넣는 값은 그 칸만 비운다 — 운동은 남고 친 수는 보인다', () {
    final reading = readSetupAnswer(
      '빈 봉 0kg 스쿼트 20회 2.5세트',
      answerFor([
        {'name': '스쿼트', 'weight': 0, 'repsPerSet': 20, 'totalSets': 2.5},
      ]),
    );
    final s = reading.exercises.single.setup;
    expect([s.weight, s.repsPerSet, s.totalSets], [null, 20, null]);
    expect(reading.unparsed, ['0kg', '2.5세트']);
    expect(
      () => readSetupAnswer('x 1', {'isExercise': true}),
      throwsFormatException,
    );
  });

  test('X9: 수가 앞에 와도 이름을 친 낱말에서 찾는다', () {
    final reading = readSetupAnswer(
      '80kg 벤치 5x5',
      answerFor([
        {'name': '벤치프레스', 'weight': 80, 'repsPerSet': 5, 'totalSets': 5},
      ]),
    );
    expect(reading.exercises.single.setup.name, '벤치');
    expect(reading.unparsed, isEmpty);
    expect(reading.dropped, isEmpty);
  });

  test('X6: 여러 운동은 칸 여럿 — 제목은 그 운동을 적은 부분, 남은 말은 앞 운동에', () {
    const text = '벤치 60kg 10회 + 로우 50kg 10회 슈퍼세트 3세트';
    final reading = readSetupAnswer(
      text,
      answerFor(
        [
          {
            'text': '벤치 60kg 10회',
            'name': '벤치프레스',
            'weight': 60,
            'repsPerSet': 10,
            'totalSets': 3,
          },
          {
            'text': '로우 50kg 10회',
            'name': '바벨로우',
            'weight': 50,
            'repsPerSet': 10,
            'totalSets': 3,
          },
          {'text': '지어낸 운동', 'name': '데드리프트'},
        ],
        ['슈퍼세트'],
      ),
    );
    expect(reading.exercises, hasLength(3));
    expect(reading.exercises[1].setup.name, '로우');
    expect(reading.exercises[2].text, isNull, reason: '글에 없는 부분은 제목이 못 된다');
    expect(reading.titles, ['벤치 60kg 10회', '로우 50kg 10회 슈퍼세트 3세트', '데드리프트']);
    // 앞에 온 일정은 첫 운동의 제목 앞에 붙는다.
    final days = readSetupAnswer(
      '월수금 벤치 5x5 스쿼트 5x5',
      answerFor(
        [
          {'text': '벤치 5x5', 'name': '벤치', 'repsPerSet': 5, 'totalSets': 5},
          {'text': '스쿼트 5x5', 'name': '스쿼트', 'repsPerSet': 5, 'totalSets': 5},
        ],
        ['월수금'],
      ),
    );
    expect(days.titles, ['월수금 벤치 5x5', '스쿼트 5x5']);
    expect(readSetupAnswer('일기 쓰기 3줄', answerFor(const [])).exercises, isEmpty);
  });

  test('수 읽기: 부호 없이, 글로 쓴 수까지(ko·en·ja·zh)', () {
    List<num> values(String text) => [
      for (final n in statedNumbers(text)) n.value,
    ];
    expect(values('벤치 60kg 8-12회'), [60, 8, 12]);
    expect(values('스쿼트 3-1-1 템포'), [3, 1, 1]);
    expect(values('덤벨 22,5kg 1,000개'), [22.5, 1000]);
    expect(values('벤치 팔십 키로로 백 개'), [80, 100]);
    expect(values('이백개 스무 세트 열두 번 백오십 회'), [200, 20, 12, 150]);
    expect(values('백스쿼트 한쪽 10개'), [10], reason: '백·한은 세는 말 앞에서만 수다');
    expect(values('twenty-five push-ups, one hundred fifty reps'), [25, 150]);
    expect(values('tension ten reps'), [10]);
    expect(values('腕立て伏せ百回 深蹲二十五次 三千'), [100, 25, 3000]);
    // 길 고르기: 수나 수량어가 없으면 이름, 있으면 모델.
    expect(hasSetupIntent('벤치 5x5'), isTrue, reason: '표현할 수 있는 글은 모델로');
    expect(hasSetupIntent('푸시업 총 백 개'), isTrue);
    expect(hasSetupIntent('체스트 프레스 머신'), isFalse);
    expect(hasSetupIntent('백스쿼트'), isFalse);
    expect(
      hasSetupIntent('버피 타바타 30/15 10라운드'.replaceAll(timerTokens, ' ')),
      isFalse,
    );
    expect(
      hasSetupIntent('bpm 푸시업 1칸 100개 채우기'.replaceAll(timerTokens, ' ')),
      isTrue,
    );
  });

  testWidgets('a plan sets weight and goal, then Next records reps directly', (
    tester,
  ) async {
    final ai = FakeAi(RecordAiStatus.ready);
    final c = await pumpEditor(tester, ai);
    await submit(tester, example);
    expect(ai.calls, 1);
    expect(c.totalSets, 0);
    expect(find.text('80kg'), findsOneWidget);
    expect(find.text('0/100회'), findsOneWidget);
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
    expect(find.text('20/100회'), findsOneWidget);
    expect(ai.calls, 1);
  });

  testWidgets('X4·X5·X6: 모델을 못 써도 친 글 그대로 칸을 만들고 이유를 한 줄 말한다', (tester) async {
    for (final (error, notice) in <(Object, String)>[
      (
        const RecordAiException(RecordAiStatus.unavailable, offline: true),
        '연결이 안 돼 적은 그대로 만들었어요',
      ),
      (
        const RecordAiException(RecordAiStatus.unavailable),
        '서버가 답하지 않아 적은 그대로 만들었어요',
      ),
      (
        const RecordAiException(RecordAiStatus.quotaExceeded),
        '오늘 적기 도움을 다 써서 적은 그대로 만들었어요',
      ),
      (const FormatException('Not a setup answer'), '설정으로 읽을 말을 찾지 못해'),
    ]) {
      final ai = FakeAi(RecordAiStatus.ready)..error = error;
      final c = await pumpEditor(tester, ai);
      await submit(tester, example);
      expect(c.blocks.single.name, example, reason: '$error');
      expect(c.blocks.single.setup, isNull);
      expect(find.textContaining(notice), findsOneWidget, reason: '$error');
      expect(c.recentExercises.first, '벤치', reason: '문장을 통째로 익히지 않는다');
      // 다음에 무언가 치면 그 한 줄은 사라진다.
      await tester.tap(
        find.descendant(of: find.byType(SetKeypad), matching: find.text('6')),
      );
      await tester.pump();
      expect(find.textContaining(notice), findsNothing);
    }
    // 운동이 아니라는 답도 막다른 길이 아니다.
    final none = FakeAi(RecordAiStatus.ready)..answer = answerFor(const []);
    final c = await pumpEditor(tester, none);
    await submit(tester, example);
    expect(c.blocks.single.name, example);
    expect(find.textContaining('설정은 칸의 ⚙에서'), findsOneWidget);
  });

  testWidgets('X2: 120자 넘는 글이 폴백되면, 600자 넘는 글은 묻지도 않고 입력칸에 둔다', (tester) async {
    final ai = FakeAi(RecordAiStatus.ready)
      ..error = const RecordAiException(RecordAiStatus.unavailable);
    final c = await pumpEditor(tester, ai);
    final long = '벤치 60kg 10회 ${'가' * 120}';
    await submit(tester, long);
    expect(c.blocks, isEmpty);
    expect(tester.widget<CupertinoTextField>(field).controller!.text, long);
    expect(find.textContaining('운동 이름은 120자까지예요'), findsOneWidget);
    expect(ai.calls, 1);
    final huge = '벤치 60kg 10회 ${'가' * 600}';
    await submit(tester, huge);
    expect(ai.calls, 1, reason: '600자 넘는 글은 모델에 보내지 않는다');
    expect(c.blocks, isEmpty);
    expect(tester.widget<CupertinoTextField>(field).controller!.text, huge);
    expect(find.textContaining('600자가 넘는 글은 읽지 않아요'), findsOneWidget);
    // 수 없는 긴 이름도 제목이 될 수 없으니 입력칸에 둔다.
    final name = '가' * 121;
    await submit(tester, name);
    expect(c.blocks, isEmpty);
    expect(find.textContaining('운동 이름은 120자까지예요'), findsOneWidget);
  });

  testWidgets('타이머 토큰만 수를 쓴 글은 묻지 않고, 다른 수가 들면 묻는다', (tester) async {
    final ai = FakeAi(RecordAiStatus.ready);
    final c = await pumpEditor(tester, ai);
    await submit(tester, '버피 타바타 30/15 10라운드');
    expect(ai.calls, 0);
    expect(c.blocks.single.name, '버피 타바타 30/15 10라운드');
    c.closeBlock();
    await tester.pumpAndSettle();
    ai.answer = answerFor([
      {'text': '벤치 5x5', 'name': '벤치', 'repsPerSet': 5, 'totalSets': 5},
    ]);
    await submit(tester, '벤치 5x5');
    expect(ai.calls, 1, reason: '예전엔 이름으로 빠지던 표현할 수 있는 글');
  });

  testWidgets('X6: 여러 운동은 바로 칸 여럿이 되고, 못 옮긴 말은 한 줄로 보인다', (tester) async {
    const text = '벤치 5x5 스쿼트 100kg 5x5 휴식 90초';
    final ai = FakeAi(RecordAiStatus.ready)
      ..answer = answerFor(
        [
          {'text': '벤치 5x5', 'name': '벤치', 'repsPerSet': 5, 'totalSets': 5},
          {
            'text': '스쿼트 100kg 5x5',
            'name': '스쿼트',
            'weight': 100,
            'repsPerSet': 5,
            'totalSets': 5,
          },
        ],
        ['휴식 90초'],
      );
    final c = await pumpEditor(tester, ai);
    await submit(tester, text);
    expect(
      [for (final b in c.blocks) b.name],
      ['벤치 5x5', '스쿼트 100kg 5x5 휴식 90초'],
    );
    expect(c.blocks[1].setup!.weight, 100);
    expect(c.blocks[0].setup!.totalSets, 5);
    expect(find.textContaining('설정에 못 옮긴 말: 휴식 90초'), findsOneWidget);
    expect(find.textContaining('운동 2개로 나눴어요'), findsOneWidget);
    // 다음 세트를 치기 시작하면 나눈 것을 받아들인 것이다.
    await tester.tap(
      find.descendant(of: find.byType(SetKeypad), matching: find.text('6')),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('setup-merge')), findsNothing);
  });

  testWidgets('칩에서 고쳐도 제목은 친 글 그대로 — bpm 타이머가 남는다(감사 notes 5)', (tester) async {
    const text = 'bpm 푸시업 1칸 100개 채우기';
    final ai = FakeAi(RecordAiStatus.ready)
      ..answer = answerFor([
        {'text': text, 'name': '푸시업', 'totalReps': 100, 'repsOnly': true},
      ]);
    final c = await pumpEditor(tester, ai);
    await submit(tester, text);
    expect(find.textContaining('설정에 못 옮긴 말: 1칸'), findsOneWidget);
    await editChip(tester, 'totalReps', '120');
    await applyChip(tester);
    expect(c.blocks.single.name, text);
    expect(c.blocks.single.setup!.totalReps, 120);
    expect(TimingSpec.parse(c.blocks.single.name)?.bpm, 120);
  });

  testWidgets('X15: 틀린 값은 칩 밑에 이유를 말하고, 그동안 ✓ 는 꺼지며 떠나면 전 값을 둔다', (
    tester,
  ) async {
    final c = await pumpEditor(tester, FakeAi(RecordAiStatus.ready));
    await submit(tester, example);
    // 비어 있는 설정은 + 로 펼친다.
    await tester.tap(find.byKey(const ValueKey('setup-more')));
    await tester.pump();
    await editChip(tester, 'repsPerSet', '8-12');
    expect(find.textContaining('1 이상의 정수로 적어 주세요'), findsOneWidget);
    expect(
      applyButton(tester).onPressed,
      isNull,
      reason: '읽을 수 없는 값을 빈칸으로 저장하지 않는다',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('setup-field-repsPerSet')),
      findsOneWidget,
      reason: 'Enter 로도 닫히지 않는다',
    );
    await tester.enterText(
      find.byKey(const ValueKey('setup-field-repsPerSet')),
      '8',
    );
    await tester.pump();
    await applyChip(tester);
    expect(c.blocks.single.setup!.repsPerSet, 8);
    await editChip(tester, 'repsPerSet', '');
    expect(applyButton(tester).onPressed, isNotNull, reason: '빈칸은 틀린 값이 아니다');
    await applyChip(tester);
    expect(c.blocks.single.setup!.repsPerSet, isNull, reason: '빈칸은 그 설정을 뺀다');

    for (final bad in ['60kg', '-20']) {
      await editChip(tester, 'weight', bad);
      expect(find.textContaining('0보다 크고 2000 이하'), findsOneWidget);
      expect(applyButton(tester).onPressed, isNull);
      // 다른 곳으로 떠났다 — 전 값을 두고 닫는다.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('setup-field-weight')), findsNothing);
      expect(c.blocks.single.setup!.weight, 80);
    }
    await editChip(tester, 'weight', '60');
    await applyChip(tester);
    await editChip(tester, 'name', '');
    expect(find.text('운동 이름을 적어 주세요'), findsOneWidget);
    expect(applyButton(tester).onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('setup-field-name')),
      '벤치',
    );
    await tester.pump();
    await applyChip(tester);
    expect(c.blocks.single.setup!.weight, 60);
    expect(c.blocks.single.setup!.totalReps, 100);
  });

  testWidgets('X15: 칩의 1,000 은 천, 22,5 는 22.5 다 — 쉼표를 소수점으로만 읽지 않는다', (
    tester,
  ) async {
    final c = await pumpEditor(tester, FakeAi(RecordAiStatus.ready));
    await submit(tester, example);
    await editChip(tester, 'weight', '22,5');
    await applyChip(tester);
    await editChip(tester, 'totalReps', '1,000');
    await applyChip(tester);
    expect(c.blocks.single.setup!.weight, 22.5);
    expect(c.blocks.single.setup!.totalReps, 1000);
  });

  testWidgets('설정 없는 칸에도 ⚙ 가 있어 그 자리에서 설정을 붙인다 — 제목은 그대로', (tester) async {
    final c = await pumpEditor(tester, FakeAi(RecordAiStatus.ready));
    c.addExercise('러닝 5km 3세트');
    c.closeBlock();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CupertinoIcons.gear_alt));
    await tester.pump();
    await editChip(tester, 'name', '러닝');
    await applyChip(tester);
    expect(c.blocks.single.exercise, '러닝');
    // 하나를 고친 뒤에도 펼친 채다 — 다음 빈 칩을 바로 누른다.
    await editChip(tester, 'totalSets', '3');
    await applyChip(tester);
    expect(c.blocks.single.name, '러닝 5km 3세트');
    expect(c.blocks.single.exercise, '러닝');
    expect(c.blocks.single.setup!.totalSets, 3);
    expect(find.byIcon(CupertinoIcons.gear_alt), findsNothing);
    expect(find.text('0/3세트'), findsOneWidget);
  });

  testWidgets('X12: 답을 기다리다 다른 카드를 눌러도 친 문장은 입력칸 초안으로 남는다', (tester) async {
    final ai = FakeAi(RecordAiStatus.ready)
      ..pending = Completer<Map<String, Object?>>();
    final c = await pumpEditor(tester, ai);
    c.addExercise('스쿼트');
    c.addSet('60 10');
    c.closeBlock();
    await tester.pumpAndSettle();
    await submit(tester, example);
    // 카드의 빈 세트 칸을 눌러 그 운동으로 간다(_openBlock).
    await tester.tap(find.byKey(const ValueKey('add-set-cell')));
    await tester.pumpAndSettle();
    ai.pending!.complete(benchAnswer);
    await tester.pumpAndSettle();
    expect(c.blocks, hasLength(1), reason: '늦은 답은 쓰지 않는다');
    // 그 카드를 끝내고 나오면 친 문장이 돌아온다.
    await tester.tap(find.text('운동 완료'));
    await tester.pumpAndSettle();
    expect(c.naming, isTrue);
    expect(tester.widget<CupertinoTextField>(field).controller!.text, example);
  });

  testWidgets('X13: 칩을 고치다 앱을 내렸다 돌아와 ✓ 해도 적용된다', (tester) async {
    final c = await pumpEditor(tester, FakeAi(RecordAiStatus.ready));
    await submit(tester, example);
    await editChip(tester, 'totalReps', '120');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await applyChip(tester);
    expect(c.blocks.single.setup!.totalReps, 120);
    expect(c.blocks.single.name, example);
  });

  testWidgets('X11: editing during inference discards a late answer', (
    tester,
  ) async {
    final ai = FakeAi(RecordAiStatus.ready)
      ..pending = Completer<Map<String, Object?>>();
    final c = await pumpEditor(tester, ai);
    await submit(tester, example);
    await tester.enterText(field, '푸시업 총 50개');
    ai.pending!.complete(benchAnswer);
    await tester.pumpAndSettle();
    expect(c.blocks, isEmpty);
    expect(
      tester.widget<CupertinoTextField>(field).controller!.text,
      '푸시업 총 50개',
    );
  });

  testWidgets(
    'a quick submission does not wait for availability — the plan is applied',
    (tester) async {
      final ai = FakeAi(RecordAiStatus.ready)
        ..pendingStatus = Completer<RecordAiStatus>();
      final c = await pumpEditor(tester, ai);
      await submit(tester, example);
      expect(c.blocks.single.setup!.totalReps, 100);
      expect(ai.calls, 1);
      ai.pendingStatus!.complete(RecordAiStatus.ready);
      await tester.pumpAndSettle();
      expect(c.blocks, hasLength(1));
    },
  );

  test('X8: 수는 값이 아니라 자리로 맞춘다 — 값이 우연히 같아도 못 옮긴 말은 보이고, 제목은 친 말을 다 담는다', () {
    // 모델이 휴식 60초를 빠뜨렸다. 무게 60 과 값이 같아도 60초는 제 자리의 수다.
    const rest = '벤치 60kg 10회 스쿼트 60kg 10회 휴식 60초';
    final r = readSetupAnswer(
      rest,
      answerFor([
        {'text': '벤치 60kg 10회', 'name': '벤치', 'weight': 60, 'repsPerSet': 10},
        {'text': '스쿼트 60kg 10회', 'name': '스쿼트', 'weight': 60, 'repsPerSet': 10},
      ]),
    );
    expect(r.unparsed, ['60초']);
    expect(r.titles, ['벤치 60kg 10회', '스쿼트 60kg 10회 휴식 60초']);
    // 세트당 횟수가 있다고 아무 1 이나 덮이지 않는다 — '한 세트에' 만 세트당이라는 말이다.
    const beat = 'bpm 푸시업 1칸 10개씩 5세트';
    expect(
      readSetupAnswer(
        beat,
        answerFor([
          {
            'text': beat,
            'name': '푸시업',
            'repsPerSet': 10,
            'totalSets': 5,
            'repsOnly': true,
          },
        ]),
      ).unparsed,
      ['1칸'],
    );
    // 이름에 든 수(MTS100)는 이름 자리의 수만 덮는다.
    const machine = 'MTS100 로우 1칸 스쿼트 50개';
    final m = readSetupAnswer(
      machine,
      answerFor([
        {'text': 'MTS100 로우', 'name': 'MTS100 로우'},
        {'text': '스쿼트 50개', 'name': '스쿼트', 'totalReps': 50, 'repsOnly': true},
      ]),
    );
    expect(m.unparsed, ['1칸']);
    expect(m.titles, ['MTS100 로우 1칸', '스쿼트 50개']);
    // 어느 운동에도 안 적힌 말(수 없는 월수금까지)은 제목에 남는다 — 앞에 오면 첫 운동에.
    const days = '월수금 벤치 5x5 스쿼트 5x5';
    final d = readSetupAnswer(
      days,
      answerFor([
        {'text': '벤치 5x5', 'name': '벤치', 'repsPerSet': 5, 'totalSets': 5},
        {'text': '스쿼트 5x5', 'name': '스쿼트', 'repsPerSet': 5, 'totalSets': 5},
      ]),
    );
    expect(d.titles, ['월수금 벤치 5x5', '스쿼트 5x5']);
    expect(d.fits, isTrue);
    // 두 운동에 걸린 조건(끝의 3세트)은 둘이 같이 쓰고, 제목에서도 사라지지 않는다.
    const superset = '벤치 60kg 12개 + 바벨로우 50kg 12개 3세트';
    final s = readSetupAnswer(
      superset,
      answerFor([
        {
          'text': '벤치 60kg 12개',
          'name': '벤치',
          'weight': 60,
          'repsPerSet': 12,
          'totalSets': 3,
        },
        {
          'text': '바벨로우 50kg 12개',
          'name': '바벨로우',
          'weight': 50,
          'repsPerSet': 12,
          'totalSets': 3,
        },
      ]),
    );
    expect([for (final e in s.exercises) e.setup.totalSets], [3, 3]);
    expect([s.unparsed, s.dropped], [isEmpty, isEmpty]);
    expect(s.titles, ['벤치 60kg 12개', '바벨로우 50kg 12개 3세트']);
    // 붙이면 120자가 넘는 말은 제목에 못 담는다 — 칸을 만들지 않고 입력칸에 둔다.
    final long = '벤치 5x5 ${'가' * 115} 스쿼트 5x5';
    expect(
      readSetupAnswer(
        long,
        answerFor([
          {'text': '벤치 5x5', 'name': '벤치', 'repsPerSet': 5, 'totalSets': 5},
          {'text': '스쿼트 5x5', 'name': '스쿼트', 'repsPerSet': 5, 'totalSets': 5},
        ]),
      ).fits,
      isFalse,
    );
  });

  test('X6: 모델이 text 를 깨뜨려도(�시업) 앞뒤 운동 사이에서 이름으로 자리를 찾는다', () {
    const typed = '푸시업 20개 스쿼트 30개 버피 10개';
    final r = readSetupAnswer(
      typed,
      answerFor([
        {'text': '�시업 20개', 'name': '푸시업', 'totalReps': 20, 'repsOnly': true},
        {'text': '스쿼트 30개', 'name': '스쿼트', 'totalReps': 30, 'repsOnly': true},
        {'text': null, 'name': '버피', 'totalReps': 10, 'repsOnly': true},
      ]),
    );
    expect(r.titles, ['푸시업 20개', '스쿼트 30개', '버피 10개']);
    expect([for (final e in r.exercises) e.setup.totalReps], [20, 30, 10]);
    expect([r.unparsed, r.dropped], [isEmpty, isEmpty]);
  });

  test('X9: 이름은 친 낱말 그대로 — 못 옮긴 말은 이름에 섞지 않는다', () {
    String nameOf(
      String typed,
      Map<String, Object?> e, [
      List<String> unparsed = const [],
    ]) => readSetupAnswer(
      typed,
      answerFor([
        {'text': typed, ...e},
      ], unparsed),
    ).exercises.single.setup.name;

    expect(
      nameOf(
        '벤치 원알엠 70프로 8회 3세트',
        {'name': '벤치프레스', 'repsPerSet': 8, 'totalSets': 3},
        ['원알엠 70프로'],
      ),
      '벤치',
    );
    expect(
      nameOf(
        '랫풀 드롭세트 60-45-30kg 각 10회',
        {'name': '랫풀다운', 'repsPerSet': 10},
        ['드롭세트', '60-45-30kg'],
      ),
      '랫풀',
    );
    expect(
      nameOf(
        '벤치 피라미드 60-70-80kg 10-8-6회',
        {'name': '벤치프레스'},
        ['피라미드 60-70-80kg 10-8-6회'],
      ),
      '벤치',
    );
    expect(nameOf('로잉머신 2000m', {'name': '로잉'}, ['2000m']), '로잉머신');
    expect(
      nameOf('100 push-ups', {
        'name': 'Push Up',
        'totalReps': 100,
        'repsOnly': true,
      }),
      'push-ups',
    );
    expect(
      nameOf('턱걸이 열 개 세 세트', {'name': '풀업', 'repsPerSet': 10, 'totalSets': 3}),
      '턱걸이',
    );
    // 모델이 조건어를 못 옮긴 말에 넣지 않아도 이름에 섞지 않는다.
    expect(
      nameOf('벤치 피라미드 60-70-80kg', {'name': '벤치프레스'}, ['60-70-80kg']),
      '벤치',
    );
    expect(
      nameOf('랫풀 드롭세트 60kg 10회', {
        'name': '랫풀다운',
        'weight': 60,
        'repsPerSet': 10,
      }),
      '랫풀',
    );
    expect(
      nameOf('스쿼트 템포 80kg 5회', {'name': '백스쿼트', 'weight': 80, 'repsPerSet': 5}),
      '스쿼트',
    );
    // 조건어가 곧 이름인 운동은 모델이 그렇게 부르면 그대로다.
    expect(
      nameOf('템포 스쿼트 60kg 8회', {
        'name': '템포 스쿼트',
        'weight': 60,
        'repsPerSet': 8,
      }),
      '템포 스쿼트',
    );
  });

  test('수 읽기: 쉼표로 늘어놓은 수는 따로, 한국어로 쓴 수는 낱말 전체일 때만', () {
    List<num> values(String text) => [
      for (final n in statedNumbers(text)) n.value,
    ];
    expect(values('컬 10,12,15회 3세트'), [10, 12, 15, 3]);
    expect(values('덤벨 22,5kg 1,000개'), [22.5, 1000]);
    final curl = readSetupAnswer(
      '컬 10,12,15회 3세트',
      answerFor([
        {
          'text': '컬 10,12,15회 3세트',
          'name': '컬',
          'repsPerSet': 12,
          'totalSets': 3,
        },
      ]),
    );
    expect(curl.dropped, isEmpty, reason: '12 는 친 수다');
    expect(curl.exercises.single.setup.repsPerSet, 12);
    expect(curl.unparsed, ['10,12,15회']);
    expect(values('벤치 이번 세트 80kg'), [80]);
    expect(values('스쿼트 구분 동작'), isEmpty);
    expect(values('일회용 밴드 로우'), isEmpty);
    expect(hasSetupIntent('스쿼트 구분 동작'), isFalse);
    expect(hasSetupIntent('일회용 밴드 로우'), isFalse);
    expect(values('플랭크 일 분 세 세트 스무개씩 다섯셋트'), [1, 3, 20, 5]);
  });

  test('X8: 붙여 쓴 한국어 수(삼세트·오분·열개정도…)도 친 수다 — 수+세는 말+조사·꼬리, 이번·구분·일회용은 아니다', () {
    List<num> values(String text) => [
      for (final n in statedNumbers(text)) n.value,
    ];
    expect(values('스쿼트 삼세트'), [3]);
    expect(values('벤치 이세트 10회'), unorderedEquals([2, 10]));
    expect(values('플랭크 오분'), [5]);
    expect(values('벤치 60kg 열개정도 3세트'), unorderedEquals([60, 10, 3]));
    expect(values('스쿼트 열개씩만 3세트'), unorderedEquals([10, 3]));
    expect(values('푸시업 스무개하고 3세트'), unorderedEquals([20, 3]));
    expect(values('푸시업 백개쯤'), [100]);
    expect(values('버피 두번째 세트'), [2]);
    expect(values('벤치 이번 세트 80kg'), [80]);
    expect(values('스쿼트 구분 동작'), isEmpty);
    expect(values('스쿼트 구분도 없이'), isEmpty);
    expect(values('일회용 밴드 로우'), isEmpty);
    expect(values('육개장 먹고 삼분할 벤치'), isEmpty);
    expect(hasSetupIntent('플랭크 오분'), isTrue);
    expect(hasSetupIntent('스쿼트 구분 동작'), isFalse);
    for (final (typed, raw, key, value) in [
      (
        '스쿼트 60kg 삼세트 10회',
        {'weight': 60, 'repsPerSet': 10, 'totalSets': 3},
        'totalSets',
        3,
      ),
      (
        '벤치 60kg 열개정도 3세트',
        {'weight': 60, 'repsPerSet': 10, 'totalSets': 3},
        'repsPerSet',
        10,
      ),
    ]) {
      final r = readSetupAnswer(
        typed,
        answerFor([
          {'text': typed, 'name': typed.split(' ').first, ...raw},
        ]),
      );
      expect(r.dropped, isEmpty, reason: typed);
      expect(r.exercises.single.setup.toJson()[key], value, reason: typed);
      expect(r.unparsed, isEmpty, reason: typed);
    }
  });

  test('X8: 칸에 옮긴 수는 이름·못 옮긴 말 밖의 같은 값과 먼저 짝짓는다 — 정말 못 옮긴 말만 보인다', () {
    final mts = readSetupAnswer(
      'MTS100 로우 100개',
      answerFor([
        {
          'text': 'MTS100 로우 100개',
          'name': 'MTS100 로우',
          'totalReps': 100,
          'repsOnly': true,
        },
      ]),
    );
    expect(mts.exercises.single.setup.totalReps, 100);
    expect(mts.unparsed, isEmpty);
    final row = readSetupAnswer(
      '민수식 로우 2 2세트',
      answerFor([
        {'text': '민수식 로우 2 2세트', 'name': '민수식 로우 2', 'totalSets': 2},
      ]),
    );
    expect(row.exercises.single.setup.totalSets, 2);
    expect(row.unparsed, isEmpty);
    final rpe = readSetupAnswer(
      'RPE 8 벤치 80kg 8회',
      answerFor(
        [
          {
            'text': 'RPE 8 벤치 80kg 8회',
            'name': '벤치',
            'weight': 80,
            'repsPerSet': 8,
          },
        ],
        ['RPE 8'],
      ),
    );
    expect(rpe.exercises.single.setup.repsPerSet, 8);
    expect(rpe.unparsed, ['RPE 8']);
  });

  test('v3 §2: 음식 표 조회는 /api/foods/match 에 글만 보내고, 못 물으면 음식이 아니다', () async {
    final sent = <(String, Object?)>[];
    Future<bool> ask(MockClientHandler foods) {
      RecordAi.forget();
      return RecordAi(
        endpoint: 'https://example.com',
        deviceId: 'device',
        client: MockClient((request) async {
          if (request.url.path == '/api/device') {
            return http.Response(jsonEncode({'token': 't'}), 200);
          }
          sent.add((request.url.path, jsonDecode(request.body)));
          return foods(request);
        }),
      ).isFood('김치찌개');
    }

    expect(
      await ask(
        (_) async => http.Response(
          jsonEncode({'food': true, 'name': '김치찌개', 'kind': 'dish'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
      isTrue,
    );
    expect(sent.single.$1, '/api/foods/match');
    expect(sent.single.$2, {'text': '김치찌개'});
    expect(
      await ask((_) async => http.Response(jsonEncode({'food': false}), 200)),
      isFalse,
    );
    for (final fail in <MockClientHandler>[
      (_) async => http.Response(jsonEncode({'error': 'quotaExceeded'}), 429),
      (_) async => http.Response('oops', 502),
      (_) async => throw const SocketException('no route'),
    ]) {
      expect(await ask(fail), isFalse);
    }
    // 모델 대신 대답하는 자리(테스트·평가)와 기기 토큰이 없는 곳은 묻지 않는다.
    expect(
      await RecordAi(respond: (_, _) async => null).isFood('김치찌개'),
      isFalse,
    );
    expect(await const RecordAi().isFood('김치찌개'), isFalse);
    RecordAi.forget();
  });

  test('X4: 와이파이 로그인 화면(HTML)·TLS·소켓 실패는 연결 문제다 — "읽지 못함" 이 아니다', () async {
    for (final handler in <MockClientHandler>[
      (_) async => http.Response('<html>login</html>', 200),
      (_) async => throw const HandshakeException('certificate'),
      (_) async => throw const SocketException('no route'),
    ]) {
      RecordAi.forget();
      Object? error;
      try {
        await RecordAi(
          endpoint: 'https://example.com',
          deviceId: 'device',
          client: MockClient(handler),
        ).interpret('벤치 80kg 10회', 'ko', const []);
      } catch (e) {
        error = e;
      }
      expect(
        error,
        isA<RecordAiException>().having((e) => e.offline, 'offline', isTrue),
        reason: '$error',
      );
    }
    RecordAi.forget();
  });

  testWidgets(
    'X2: 120자 넘는 글은 모델이 읽어 내도 칸을 만들지 않고 입력칸에 둔다 — 제목에 못 담은 말이 사라지지 않게',
    (tester) async {
      const typed =
          '오늘은 어깨가 좀 아파서 가볍게 하려고 한다. 트레이너 선생님이 무게보다 자세가 중요하다고 했다. '
          '그래서 오늘은 벤치 40kg 10회 3세트만 하고 끝낼 생각이다. 다음 주에는 다시 무겁게 할 것이고 스트레칭도 꼭 하기로 했다.';
      expect(typed.length, greaterThan(120));
      final ai = FakeAi(RecordAiStatus.ready)
        ..answer = answerFor([
          {
            'text': '벤치 40kg 10회 3세트',
            'name': '벤치',
            'weight': 40,
            'repsPerSet': 10,
            'totalSets': 3,
          },
        ]);
      final c = await pumpEditor(tester, ai);
      await submit(tester, typed);
      expect(ai.calls, 1);
      expect(find.text('완료'), findsNothing, reason: '확인 창을 열지 않는다');
      expect(c.blocks, isEmpty);
      expect(tester.widget<CupertinoTextField>(field).controller!.text, typed);
      expect(find.textContaining('운동 이름은 120자까지예요'), findsOneWidget);
    },
  );

  testWidgets('X4: 폴백은 문장을 익히지 않는다 — 수 낱말을 뺀 이름만, 운동이 아니면 익히지 않는다', (
    tester,
  ) async {
    for (final (text, learned) in [('100개 푸시업', '푸시업'), ('푸시업 총 백 개', '푸시업')]) {
      final ai = FakeAi(RecordAiStatus.ready)
        ..error = const RecordAiException(
          RecordAiStatus.unavailable,
          offline: true,
        );
      final c = await pumpEditor(tester, ai);
      await submit(tester, text);
      expect(c.blocks.single.name, text);
      expect(c.recentExercises, [learned]);
    }
    final none = FakeAi(RecordAiStatus.ready)..answer = answerFor(const []);
    final c = await pumpEditor(tester, none);
    await submit(tester, '내일 회의 3시');
    expect(c.blocks.single.name, '내일 회의 3시');
    expect(c.recentExercises, isEmpty, reason: '운동이 아니라는 답이면 익히지 않는다');
  });

  testWidgets(
    'X8: 설정을 붙여 만든 칸과 똑같은 줄은 그 설정을 다시 쓴다 — 익힌 이름이라고 수가 든 줄을 묻지 않고 넘기지 않는다',
    (tester) async {
      const bench = WorkoutSetup(
        name: '벤치',
        weight: 80,
        repsPerSet: 5,
        totalSets: 5,
      );
      final ai = FakeAi(RecordAiStatus.ready)
        ..answer = answerFor([
          {'text': '민수식 로우 2', 'name': '민수식 로우 2'},
        ]);
      final c = await pumpEditor(
        tester,
        ai,
        controller: RoutineEditorController(
          history: const ['민수식 로우 2', '벤치 80kg 5x5'],
        ),
      );
      // 익힌 이름이어도 수가 든 줄은 모델이 읽는다.
      await submit(tester, '민수식 로우 2');
      expect(ai.calls, 1);
      expect(c.blocks.single.name, '민수식 로우 2');
      c.closeBlock();
      await submit(tester, '벤치 80kg 5x5');
      expect(ai.calls, 2, reason: '익힌 이름이 설정 문장이어도 설정 없이 만들지 않는다');
      c.restore([
        ExerciseBlock('벤치 80kg 5x5', null, bench),
        ExerciseBlock('스쿼트 100kg 5x5'),
      ]);
      expect(c.recentExercises.take(2), ['벤치', '스쿼트']);
      await tester.pumpAndSettle();
      await submit(tester, '벤치 80kg 5x5');
      expect(ai.calls, 2, reason: '같은 줄은 같은 설정 — 다시 묻지 않는다');
      expect(c.blocks.last.name, '벤치 80kg 5x5');
      expect(c.blocks.last.setup?.toJson(), bench.toJson());
      expect(find.text('완료'), findsNothing);
      c.closeBlock();
      await submit(tester, '스쿼트 100kg 5x5');
      expect(ai.calls, 3, reason: '설정 없는 칸의 제목은 다시 물어 설정을 붙인다');
      c.closeBlock();
      await submit(tester, '벤치');
      expect(ai.calls, 3, reason: '수 없는 이름은 늘 바로 만든다');
      expect(c.blocks.last.setup, isNull);
    },
  );

  testWidgets(
    'X8: 저장한 기록을 다시 켠 뒤 같은 줄을 쳐도 설정이 붙는다 — 불러올 때 제목 문장을 이름으로 익히지 않는다',
    (tester) async {
      const bench = WorkoutSetup(
        name: '벤치',
        weight: 80,
        repsPerSet: 5,
        totalSets: 5,
      );
      final dir = Directory.systemTemp.createTempSync('setpad_learned');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = NotesStore(directory: dir);
      await tester.runAsync(store.load);
      store.create(
        blocks: [
          ExerciseBlock('벤치 80kg 5x5', null, bench),
          ExerciseBlock('100개 푸시업'),
          ExerciseBlock('버피 타바타 30/15 10라운드'),
        ],
      );
      await tester.runAsync(store.flush);
      final reopened = NotesStore(directory: dir);
      await tester.runAsync(reopened.load);
      expect(
        reopened.exerciseHistory,
        unorderedEquals(['벤치', '푸시업', '버피 타바타 30/15 10라운드']),
      );
      expect(reopened.setupOf('벤치 80kg 5x5')?.toJson(), bench.toJson());
      expect(reopened.setupOf('100개 푸시업'), isNull);
      final ai = FakeAi(RecordAiStatus.ready);
      final c = await pumpEditor(
        tester,
        ai,
        controller: RoutineEditorController(
          history: reopened.exerciseHistory,
          savedSetup: reopened.setupOf,
        ),
      );
      await submit(tester, '벤치 80kg 5x5');
      expect(ai.calls, 0);
      expect(c.blocks.single.name, '벤치 80kg 5x5');
      expect(c.blocks.single.setup?.toJson(), bench.toJson());
      c.closeBlock();
      await submit(tester, '100개 푸시업');
      expect(ai.calls, 1, reason: '설정 없이 저장된 줄은 모델이 읽는다');
    },
  );

  testWidgets(
    'X8: 이름만 읽은 줄(민수식 로우 2)도 그 읽음을 기억한다 — 같은 줄을 다시 쳐도 모델을 또 부르지 않는다',
    (tester) async {
      final ai = FakeAi(RecordAiStatus.ready)
        ..answer = answerFor([
          {'text': '민수식 로우 2', 'name': '민수식 로우 2'},
        ]);
      final c = await pumpEditor(tester, ai);
      await submit(tester, '민수식 로우 2');
      expect(ai.calls, 1);
      expect(c.blocks.single.setup?.name, '민수식 로우 2');
      expect(c.blocks.single.setup?.countsReps, isFalse);
      expect(c.recentExercises.first, '민수식 로우 2');
      c.closeBlock();
      await submit(tester, '민수식 로우 2');
      expect(ai.calls, 1, reason: '같은 줄은 같은 읽음');
      expect(c.blocks.map((b) => b.name), ['민수식 로우 2', '민수식 로우 2']);
      expect(c.blocks.last.setup?.name, '민수식 로우 2');

      // 저장했다 다시 켜도 그 읽음이 남는다.
      final dir = Directory.systemTemp.createTempSync('setpad_plain');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = NotesStore(directory: dir);
      await tester.runAsync(store.load);
      store.create(blocks: c.blocks);
      await tester.runAsync(store.flush);
      final reopened = NotesStore(directory: dir);
      await tester.runAsync(reopened.load);
      expect(reopened.setupOf('민수식 로우 2')?.name, '민수식 로우 2');
      expect(reopened.exerciseHistory, contains('민수식 로우 2'));
    },
  );

  test('X8: 다시 쓰는 설정은 그 수가 친 글에 있을 때만이다 — ⚙ 로 고친 설정은 다시 읽는다', () {
    const edited = WorkoutSetup(
      name: '벤치',
      weight: 85,
      repsPerSet: 5,
      totalSets: 5,
    );
    const typed = WorkoutSetup(
      name: '벤치',
      weight: 80,
      repsPerSet: 5,
      totalSets: 5,
    );
    final c = RoutineEditorController()
      ..restore([ExerciseBlock('벤치 80kg 5x5', null, edited)]);
    expect(c.earlierSetup('벤치 80kg 5x5'), isNull);
    c.restore([
      ExerciseBlock('벤치 80kg 5x5', null, typed),
      ExerciseBlock('벤치 팔십 키로 5x5', null, typed),
      ExerciseBlock('민수식 로우 2', null, const WorkoutSetup(name: '민수식 로우 2')),
    ]);
    expect(c.earlierSetup('벤치 80kg 5x5')?.weight, 80);
    expect(c.earlierSetup('벤치 팔십 키로 5x5')?.weight, 80, reason: '글로 쓴 수도 수다');
    expect(c.earlierSetup('민수식 로우 2')?.name, '민수식 로우 2');
    final saved = RoutineEditorController(savedSetup: (_) => edited);
    expect(saved.earlierSetup('벤치 80kg 5x5'), isNull, reason: '저장된 기록도 같다');
  });

  test('조건 말은 낱말 전체일 때만 이름에서 뺀다 — 템포런은 이름이다', () {
    expect(typedName('템포런 30분', '러닝'), '템포런');
    expect(typedName('템포 스쿼트 60kg 8회', '스쿼트'), '스쿼트');
    expect(typedName('드롭세트로 레그프레스 100kg', '레그프레스'), '레그프레스');
    expect(typedName('실패까지 푸시업', ''), '푸시업');
    expect(typedName('pyramid-less row 5x5', ''), 'pyramid-less row');
  });

  test('수 자리 짝짓기: 모델의 text 가 이름뿐이면 이름 밖의 짝 없는 자리가 이름 속 자리보다 먼저다', () {
    final r = readSetupAnswer('MTS100 로우 100개', {
      'exercises': [
        {
          'text': 'MTS100 로우',
          'name': 'MTS100 로우',
          'totalReps': 100,
          'repsOnly': true,
        },
      ],
    });
    expect(r.exercises.single.setup.name, 'MTS100 로우');
    expect(r.exercises.single.setup.totalReps, 100);
    expect(r.unparsed, isEmpty, reason: '100개 는 칸에 들었다');
    final two = readSetupAnswer('민수식 로우 2 2세트', {
      'exercises': [
        {'text': '민수식 로우 2', 'name': '민수식 로우 2', 'totalSets': 2},
      ],
    });
    expect(two.exercises.single.setup.totalSets, 2);
    expect(two.unparsed, isEmpty);
  });

  test('v3 §2: 모델이 음식이라고 답하면(food: true, 운동 없음) 읽음에 싣는다', () {
    expect(
      readSetupAnswer('바나나 2개', {
        'exercises': [],
        'unparsed': [],
        'food': true,
      }).food,
      isTrue,
    );
    expect(
      readSetupAnswer('푸시업 20개', {
        'exercises': [
          {'text': '푸시업 20개', 'name': '푸시업', 'totalReps': 20},
        ],
        'food': true,
      }).food,
      isFalse,
      reason: '운동이 있으면 운동이다',
    );
    expect(readSetupAnswer('내일 회의 3시', {'exercises': []}).food, isFalse);
  });

  testWidgets('X11: 답을 기다리다 앱을 내렸다 돌아오면 늦은 답을 버리지 않고 칸을 만든다', (tester) async {
    final ai = FakeAi(RecordAiStatus.ready)
      ..pending = Completer<Map<String, Object?>>();
    final c = await pumpEditor(tester, ai);
    await submit(tester, example);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    ai.pending!.complete(benchAnswer);
    await tester.pump();
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(c.blocks.single.setup!.totalReps, 100);
    expect(ai.calls, 1, reason: '다시 묻지 않는다');
  });

  testWidgets('운동 하나에 설정할 것이 없어도 못 옮긴 말은 한 줄로 보인다', (tester) async {
    final ai = FakeAi(RecordAiStatus.ready)
      ..answer = answerFor(
        [
          {'text': '러닝 5km', 'name': '러닝'},
        ],
        ['5km'],
      );
    final c = await pumpEditor(tester, ai);
    await submit(tester, '러닝 5km');
    expect(c.blocks.single.name, '러닝 5km');
    // 설정할 것은 없지만 읽은 이름은 칸에 남는다 — 통계는 '러닝' 을 본다.
    expect(c.blocks.single.setup?.name, '러닝');
    expect(c.blocks.single.setup?.countsReps, isFalse);
    expect(c.blocks.single.exercise, '러닝');
    expect(find.textContaining('설정에 못 옮긴 말: 5km'), findsOneWidget);
    expect(
      find.byIcon(CupertinoIcons.gear_alt),
      findsOneWidget,
      reason: '설정 요약 줄 대신 설정 붙이기 단추',
    );
  });

  testWidgets('X6: 잘못 나뉜 줄은 한 번 눌러 한 칸으로 합친다 — 친 말이 제목이 된다', (tester) async {
    const text = '벤치 80kg 8회 드랍 60kg 8회 드랍 40kg 실패까지';
    final ai = FakeAi(RecordAiStatus.ready)
      ..answer = answerFor(
        [
          {
            'text': '벤치 80kg 8회',
            'name': '벤치프레스',
            'weight': 80,
            'repsPerSet': 8,
          },
          {'text': '60kg 8회', 'name': '벤치프레스', 'weight': 60, 'repsPerSet': 8},
          {'text': '40kg 실패까지', 'name': '벤치프레스', 'weight': 40},
        ],
        ['드랍', '실패까지'],
      );
    final c = await pumpEditor(tester, ai);
    await submit(tester, text);
    expect(c.blocks, hasLength(3));
    expect(find.textContaining('운동 3개로 나눴어요'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('setup-merge')));
    await tester.pumpAndSettle();
    expect(c.blocks.single.name, text);
    expect(c.blocks.single.setup!.weight, 80);
    expect(c.blocks.single.setup!.repsPerSet, 8);
    expect(find.byKey(const ValueKey('setup-merge')), findsNothing);
  });

  testWidgets('"횟수만 기록" 은 칩 하나로 켜고 끈다', (tester) async {
    final ai = FakeAi(RecordAiStatus.ready)
      ..answer = answerFor([
        {'text': '스쿼트 100개 채우기', 'name': '스쿼트', 'totalReps': 100},
      ]);
    final c = await pumpEditor(tester, ai);
    await submit(tester, '스쿼트 100개 채우기');
    await tester.tap(find.byKey(const ValueKey('setup-more')));
    await tester.pump();
    expect(find.text('+ 횟수만 기록'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('setup-repsOnly')));
    await tester.pumpAndSettle();
    expect(c.blocks.single.setup!.repsOnly, isTrue);
    await tester.tap(find.byKey(const ValueKey('setup-repsOnly')));
    await tester.pumpAndSettle();
    expect(c.blocks.single.setup!.repsOnly, isFalse);
    // 펼친 빈 칩은 − 로 접는다.
    await tester.tap(find.byKey(const ValueKey('setup-more')));
    await tester.pump();
    expect(find.text('+ 횟수만 기록'), findsNothing);
  });

  testWidgets('칩을 고치는 사이 답이 와도 칩의 포커스를 뺏지 않는다 — 치다 만 값을 저장하지 않는다', (
    tester,
  ) async {
    final ai = FakeAi(RecordAiStatus.ready)
      ..pending = Completer<Map<String, Object?>>();
    final c = await pumpEditor(
      tester,
      ai,
      controller: RoutineEditorController()
        ..addExercise(
          '스쿼트 80kg',
          setup: const WorkoutSetup(name: '스쿼트', weight: 80),
        )
        ..closeBlock(),
    );
    await submit(tester, example);
    await tester.tap(find.byKey(const ValueKey('setup-weight')));
    await tester.pump();
    await tester.pump();
    expect(chipFocused(tester, 'weight'), isTrue);
    tester.testTextInput.enterText('1');
    await tester.pump();
    ai.pending!.complete(benchAnswer);
    await tester.pumpAndSettle();
    expect(c.blocks, hasLength(2), reason: '답은 칸이 된다');
    expect(chipFocused(tester, 'weight'), isTrue, reason: '칩은 열린 채 포커스도 그대로');
    expect(c.blocks.first.setup!.weight, 80, reason: '100 을 치려던 1 을 저장하지 않는다');
    tester.testTextInput.enterText('100');
    await tester.pump();
    await applyChip(tester);
    expect(c.blocks.first.setup!.weight, 100);
  });

  testWidgets('합친 제목이 120자를 넘으면 한 칸으로 합치기를 내놓지 않는다', (tester) async {
    final text = '벤치 80kg 8회 ${'가' * 60} 스쿼트 100kg 5회 ${'나' * 60}';
    expect(text.length, greaterThan(120));
    final ai = FakeAi(RecordAiStatus.ready)
      ..answer = answerFor([
        {'text': '벤치 80kg 8회', 'name': '벤치', 'weight': 80, 'repsPerSet': 8},
        {'text': '스쿼트 100kg 5회', 'name': '스쿼트', 'weight': 100, 'repsPerSet': 5},
      ]);
    final c = await pumpEditor(tester, ai);
    await submit(tester, text);
    expect(c.blocks, hasLength(2));
    expect(c.blocks.every((b) => b.name.length <= 120), isTrue);
    expect(find.byKey(const ValueKey('setup-merge')), findsNothing);
  });

  test('429 중 IP 하루 한도는 적기 도움 한도가 아니다', () async {
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
      await statusOf({'error': 'quotaExceeded', 'scope': 'input', 'limit': 10}),
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
