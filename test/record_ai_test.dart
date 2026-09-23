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
    expect(rest.titlesFor('벤치 80kg 10회 30초 휴식'), ['벤치 80kg 10회 30초 휴식']);
  });

  testWidgets(
    'X14: canceling a numeric proposal preserves input and writes nothing',
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
    expect(c.blocks.single.exercise, '벤치');
    // 창에서 값을 고쳐도 제목은 친 글 그대로다.
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
    expect(reading.titlesFor(text), [text], reason: 'bpm 타이머는 제목에서 붙는다');
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
    expect(reading.titlesFor(text), [
      '벤치 60kg 10회',
      '로우 50kg 10회 슈퍼세트',
      '데드리프트',
    ]);
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
    expect(days.titlesFor('월수금 벤치 5x5 스쿼트 5x5'), ['월수금 벤치 5x5', '스쿼트 5x5']);
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

  testWidgets('X6: 여러 운동은 한 창에서 칸별로 확인하고 칸 여럿이 된다', (tester) async {
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
    expect(find.text('벤치 5x5'), findsOneWidget, reason: '칸 머리');
    expect(find.textContaining('설정에 못 옮긴 말: 휴식 90초'), findsOneWidget);
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(
      [for (final b in c.blocks) b.name],
      ['벤치 5x5', '스쿼트 100kg 5x5 휴식 90초'],
    );
    expect(c.blocks[1].setup!.weight, 100);
    expect(c.blocks[0].setup!.totalSets, 5);
  });

  testWidgets('창에서 고쳐도 제목은 친 글 그대로 — bpm 타이머가 남는다(감사 notes 5)', (tester) async {
    const text = 'bpm 푸시업 1칸 100개 채우기';
    final ai = FakeAi(RecordAiStatus.ready)
      ..answer = answerFor([
        {'text': text, 'name': '푸시업', 'totalReps': 100, 'repsOnly': true},
      ]);
    final c = await pumpEditor(tester, ai);
    await submit(tester, text);
    expect(find.textContaining('설정에 못 옮긴 말: 1칸'), findsOneWidget);
    await tester.enterText(find.byType(CupertinoTextFormFieldRow).at(2), '120');
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(c.blocks.single.name, text);
    expect(c.blocks.single.setup!.totalReps, 120);
    expect(TimingSpec.parse(c.blocks.single.name)?.bpm, 120);
  });

  testWidgets('X15: 틀린 칸은 그 밑에 이유를 말한다', (tester) async {
    await pumpEditor(tester, FakeAi(RecordAiStatus.ready));
    await submit(tester, example);
    await tester.enterText(
      find.byType(CupertinoTextFormFieldRow).at(3),
      '8-12',
    );
    await tester.pump();
    expect(find.textContaining('1 이상의 정수로 적어 주세요'), findsOneWidget);
    await tester.enterText(find.byType(CupertinoTextFormFieldRow).at(1), '-20');
    await tester.pump();
    expect(find.textContaining('0보다 크고 2000 이하'), findsOneWidget);
    await tester.enterText(find.byType(CupertinoTextFormFieldRow).at(0), '');
    await tester.pump();
    expect(find.text('운동 이름을 적어 주세요'), findsOneWidget);
  });

  testWidgets('설정 없는 칸에도 ⚙ 가 있어 나중에 설정을 붙인다 — 제목은 그대로', (tester) async {
    final c = await pumpEditor(tester, FakeAi(RecordAiStatus.ready));
    c.addExercise('러닝 5km 3세트');
    c.closeBlock();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CupertinoIcons.gear_alt));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoTextFormFieldRow).at(0), '러닝');
    await tester.enterText(find.byType(CupertinoTextFormFieldRow).at(4), '3');
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(c.blocks.single.name, '러닝 5km 3세트');
    expect(c.blocks.single.exercise, '러닝');
    expect(c.blocks.single.setup!.totalSets, 3);
    expect(find.byIcon(CupertinoIcons.gear_alt), findsNothing);
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

  testWidgets('X13: 창을 연 채 앱을 내렸다 돌아와 완료해도 적용된다', (tester) async {
    final c = await pumpEditor(tester, FakeAi(RecordAiStatus.ready));
    await submit(tester, example);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(c.blocks.single.setup!.totalReps, 100);
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
