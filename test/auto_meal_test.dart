// 입력 줄 하나로 운동과 끼니를 가른다 (v3 §2). 순서: 운동 근거(사전·단위) → 분명한
// 끼니 근거(이름 전체가 음식·양·열량) → 익힌 이름 → 약한 끼니 근거 → 음식 표 → 모델의
// "food" → 운동. 알아서 끼니가 되면 '운동으로 바꾸기', 근거 없이 운동이 되면 '끼니로
// 바꾸기' 로 되돌린다.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/meal.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart';

/// 판정자·음식 표와 모델 대신 대답한다. [online] 이 false 면 그물이 없는 것이다.
/// [judge] 는 판정자(Solar)의 답, [table] 은 음식 표에 정확히 있는 이름 — 둘 다
/// 없으면 판정 없음(null).
class _Ai extends RecordAi {
  _Ai({
    this.online = true,
    this.table = const {},
    this.judge = const {},
    this.answer,
  });
  final bool online;
  final Set<String> table;
  final Map<String, bool> judge;
  final Map<String, Object?>? answer;
  final lookups = <String>[];
  final asked = <String>[];

  @override
  bool get supported => online;

  @override
  Future<MealCheck> isMeal(String text) async {
    lookups.add(text);
    return (judged: judge[text], table: table.contains(text));
  }

  @override
  Future<SetupReading> interpret(
    String text,
    String locale,
    List<String> names, {
    String defaultWeightUnit = 'kg',
  }) async {
    asked.add(text);
    if (!online) {
      throw const RecordAiException(RecordAiStatus.unavailable, offline: true);
    }
    return readSetupAnswer(text, answer ?? const {'exercises': []});
  }
}

final _field = find.byType(CupertinoTextField);

void main() {
  test('운동 근거: 운동 단위·사전 이름(앞부분·초성·별칭)·익힌 이름·낱말 묶음', () {
    for (final text in [
      '벤치 80kg 5x5',
      '스쾃 5세트',
      '푸시업 60bpm',
      '버피 타바타',
      '벤치',
      '데드',
      'ㅂㅊㅍㄹㅅ',
      'rdl',
      'Deadlift',
      '케이블 크런치',
      '아침 러닝',
      '레그 프레스 100',
    ]) {
      expect(exerciseEvidence(text, const []), isTrue, reason: text);
    }
    expect(exerciseEvidence('민수식 로우', const ['민수식 로우']), isTrue);
    for (final text in [
      '김치찌개',
      '바나나 2개',
      'ham',
      'side salad',
      'protein bar',
      '민수식 로우',
      '점심 김밥',
    ]) {
      expect(exerciseEvidence(text, const []), isFalse, reason: text);
    }
  });

  test('끼니 근거: 열량, 끼니 낱말 + 다른 말, 음식에만 쓰는 양', () {
    for (final text in [
      '김밥 450kcal',
      '라면 500칼로리',
      '점심 김밥',
      '저녁은 삼겹살',
      'lunch burrito',
      '밥 한 공기',
      '라면 1봉지',
      '콜라 1캔',
      '소주 2병',
      '피자 두 조각',
      '닭가슴살 150g',
      '우유 200ml',
      'oatmeal 1 cup',
      '짜장면 곱빼기',
    ]) {
      expect(mealEvidence(text), isTrue, reason: text);
    }
    for (final text in ['점심', '마라샹궈', '푸시업 20개', '버피 30개', '세트 메뉴']) {
      expect(mealEvidence(text), isFalse, reason: text);
    }
  });

  test('종목·유산소 낱말은 운동 근거다 — 끼니 낱말(때)이나 kcal(소모 열량)이 붙어도', () {
    for (final text in [
      '저녁 요가',
      '저녁 PT',
      '아침 수영 1km',
      '점심 산책',
      '저녁 배드민턴',
      '저녁 먹고 산책',
      '점심 줄넘기 500개',
      'lunch walk',
      'after dinner walk',
      '트레드밀 300kcal',
      '천국의 계단 20분 200kcal',
      '수영 500kcal',
      '걷기 200kcal',
      '줌바 1시간 400kcal',
      '실내자전거 300kcal',
      '파워워킹 250kcal',
      '핫요가',
      'spin class 450 kcal',
    ]) {
      expect(exerciseEvidence(text, const []), isTrue, reason: text);
    }
    for (final text in ['점심 김밥', '김밥 450kcal', 'lunch burrito']) {
      expect(exerciseEvidence(text, const []), isFalse, reason: text);
    }
  });

  test('익힌 이름은 이름 전체가 같을 때만 운동 근거다 — 음식에만 쓰는 양이 먼저다', () {
    // '계란' 을 한 번 운동으로 익혔어도 '삶은 계란' 의 계란은 근거가 아니다.
    expect(exerciseEvidence('삶은 계란 2개', const ['계란']), isFalse);
    expect(exerciseEvidence('마라샹궈 덮밥', const ['마라샹궈']), isFalse);
    // '커피' 를 익혔어도 1잔 은 끼니의 양이다.
    expect(exerciseEvidence('커피 1잔', const ['커피']), isFalse);
    expect(exerciseEvidence('마라샹궈 1그릇', const ['마라샹궈']), isFalse);
    // 익힌 이름 그대로면(수를 빼고) 운동이다.
    expect(exerciseEvidence('민수식 로우 2', const ['민수식 로우']), isTrue);
    expect(exerciseEvidence('마라샹궈', const ['마라샹궈']), isTrue);
  });

  test('흔한 음식 낱말은 표에 없어도 끼니 근거다(수 없는 한 낱말도)', () {
    for (final text in [
      '밥',
      '계란',
      '삶은 계란',
      '커피',
      'coffee',
      '맥주',
      'beer',
      '와인',
      'wine',
      '떡',
      '회',
      '과자',
      '컵라면',
      '빅맥',
      'salad',
      'sushi',
      'steak',
      'burger',
      'fries',
      'latte',
    ]) {
      expect(mealEvidence(text), isTrue, reason: text);
    }
  });

  test('운동 단위가 있어도 이름이 흔한 음식 낱말 하나면 운동 근거가 아니다 — 끼니다', () {
    for (final text in ['치킨 1세트', '버거 2세트', 'steak 1 lb', '1 lb burger']) {
      expect(exerciseEvidence(text, const []), isFalse, reason: text);
      expect(mealEvidence(text), isTrue, reason: text);
    }
    // 이름이 운동이면 단위가 근거다.
    for (final text in ['벤치 80kg', '푸시업 20회', '케이블 크런치 3세트', '민수식 로우 3세트']) {
      expect(exerciseEvidence(text, const []), isTrue, reason: text);
    }
  });

  test('클린은 운동 근거지만 사전 별칭이 아니다 — 기록 검색의 클린이 파워클린이 되지 않는다', () {
    expect(exerciseEvidence('클린', const []), isTrue);
    expect(exerciseEvidence('clean', const []), isTrue);
    expect(canonicalizeExercises('클린 최고 기록', ['클린', '파워클린']), '클린 최고 기록');
    expect(namedExercises('클린 최고 기록', ['파워클린', '클린']), ['클린']);
  });

  test('흔한 음식 낱말은 운동 근거가 아니다', () {
    for (final w in foodWords) {
      expect(exerciseEvidence(w, const []), isFalse, reason: w);
    }
  });

  Future<(RoutineEditorController, List<String>)> pump(
    WidgetTester tester,
    _Ai ai, {
    List<String> history = const [],
    List<String> done = const [],
  }) async {
    final c = RoutineEditorController(history: history);
    final meals = <String>[];
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: CupertinoPageScaffold(
          resizeToAvoidBottomInset: false,
          child: SafeArea(
            child: RoutineEditor(
              controller: c,
              ai: ai,
              mealText: ValueNotifier(null),
              onMealText: (text, index) {
                meals.add(text);
                return () => meals.remove(text);
              },
              doneExercises: () => done,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (c, meals);
  }

  Future<void> submit(WidgetTester tester, String text) async {
    await tester.enterText(_field, text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  testWidgets('음식 표에 있는 이름은 끼니로 남고, 한 줄에서 운동으로 바꾼다 — 바꾸면 다시 가르지 않는다', (
    tester,
  ) async {
    final ai = _Ai(table: {'마라샹궈'});
    final (c, meals) = await pump(tester, ai);
    await submit(tester, '마라샹궈');
    expect(meals, ['마라샹궈']);
    expect(c.blocks, isEmpty);
    expect(ai.asked, isEmpty, reason: '음식 표는 모델이 아니다');
    expect(find.textContaining('끼니로 남겼어요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('meal-undo')));
    await tester.pumpAndSettle();
    expect(meals, isEmpty, reason: '그 끼니를 지운다');
    expect(c.blocks.single.name, '마라샹궈');
    expect(ai.lookups, ['마라샹궈'], reason: '바꾼 뒤에는 표를 다시 보지 않는다');
    expect(find.textContaining('끼니로 남겼어요'), findsNothing);
  });

  testWidgets(
    '분명한 끼니(열량·음식 양)는 묻지 않고, 끼니 낱말은 판정이 없을 때만 쓴다 — 다음에 치면 되돌리기 줄은 사라진다',
    (tester) async {
      final ai = _Ai();
      final (c, meals) = await pump(tester, ai);
      await submit(tester, '삼겹살 2인분');
      expect(meals, ['삼겹살 2인분']);
      expect(ai.lookups, isEmpty, reason: '음식에만 쓰는 양은 뜻이 하나뿐이다');
      await submit(tester, '점심 김밥 한 줄');
      expect(meals, ['삼겹살 2인분', '점심 김밥 한 줄']);
      expect(ai.lookups, ['점심 김밥 한 줄'], reason: '판정자가 먼저, 낱말 목록은 답이 없을 때');
      expect(ai.asked, isEmpty);
      await tester.enterText(_field, '벤');
      await tester.pump();
      expect(find.textContaining('끼니로 남겼어요'), findsNothing);
      expect(c.blocks, isEmpty);
    },
  );

  testWidgets(
    '운동 근거가 표보다 먼저다 — 판정이 없으면 케이블 크런치는 같은 이름의 과자가 표에 있어도 운동, 벤치 80kg 5x5 는 묻지도 않는다',
    (tester) async {
      final ai = _Ai(
        table: {'케이블 크런치'},
        answer: {
          'exercises': [
            {
              'text': '벤치 80kg 5x5',
              'name': '벤치',
              'weight': 80,
              'repsPerSet': 5,
              'totalSets': 5,
            },
          ],
          'food': true,
        },
      );
      final (c, meals) = await pump(tester, ai);
      await submit(tester, '케이블 크런치');
      expect(c.blocks.single.name, '케이블 크런치');
      c.closeBlock();
      await submit(tester, '벤치 80kg 5x5');
      expect(c.blocks.last.setup?.weight, 80);
      expect(ai.lookups, ['케이블 크런치']);
      expect(meals, isEmpty);
    },
  );

  testWidgets('수가 든 줄: 표에 없으면 모델이 읽고, 음식이라고 답하면 끼니다', (tester) async {
    final ai = _Ai(answer: {'exercises': [], 'unparsed': [], 'food': true});
    final (c, meals) = await pump(tester, ai);
    await submit(tester, '두리안 2개');
    expect(ai.lookups, ['두리안 2개']);
    expect(ai.asked, ['두리안 2개']);
    expect(meals, ['두리안 2개']);
    expect(c.blocks, isEmpty);
    // 운동으로 바꾸면 모델이 다시 읽는다 — 이번에는 음식 답을 끼니로 쓰지 않는다.
    await tester.tap(find.byKey(const ValueKey('meal-undo')));
    await tester.pumpAndSettle();
    expect(meals, isEmpty);
    expect(c.blocks.single.name, '두리안 2개');
    expect(ai.lookups, ['두리안 2개']);
  });

  testWidgets('그물이 없으면 표와 모델을 건너뛰고 운동이다 — 포크·나이프로 끼니는 남긴다', (tester) async {
    final ai = _Ai(online: false, table: {'마라샹궈'});
    final (c, meals) = await pump(tester, ai);
    await submit(tester, '마라샹궈');
    expect(ai.lookups, isEmpty);
    expect(meals, isEmpty);
    expect(c.blocks.single.name, '마라샹궈');
    // 끼니 근거는 그물 없이도 본다.
    c.closeBlock();
    await submit(tester, '라면 1봉지');
    expect(meals, ['라면 1봉지']);
    await submit(tester, '김치찌개');
    expect(meals, ['라면 1봉지', '김치찌개'], reason: '흔한 음식 이름은 그물 없이도 끼니다');
    await tester.enterText(_field, '마라샹궈');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('meal-button')));
    await tester.pumpAndSettle();
    expect(meals, ['라면 1봉지', '김치찌개', '마라샹궈']);
  });

  testWidgets('운동 이름 줄에 친 글은 포크·나이프를 누르면 끼니 하나로 남고, 입력 줄은 비워진다', (
    tester,
  ) async {
    final (c, meals) = await pump(tester, _Ai());
    // '식단으로 기록' 칩은 없다 — 포크·나이프 하나가 한다.
    await tester.enterText(_field, '김치찌개');
    await tester.pump();
    expect(find.text('식단으로 기록'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('meal-button')));
    await tester.pumpAndSettle();
    expect(meals, ['김치찌개']);
    expect(c.blocks, isEmpty, reason: '운동 칸이 생기면 안 된다');
    expect(tester.widget<CupertinoTextField>(_field).controller!.text, isEmpty);
  });
  testWidgets('표에 없는 음식을 운동으로 익혀도, 그 낱말이 든 다른 줄은 모델의 food 답으로 끼니다', (
    tester,
  ) async {
    final ai = _Ai(answer: {'exercises': [], 'unparsed': [], 'food': true});
    final (c, meals) = await pump(tester, ai);
    await submit(tester, '마라샹궈');
    expect(c.blocks.single.name, '마라샹궈');
    expect(c.recentExercises, contains('마라샹궈'));
    c.closeBlock();
    await submit(tester, '매운 마라샹궈 2개');
    expect(ai.asked, ['매운 마라샹궈 2개']);
    expect(meals, ['매운 마라샹궈 2개']);
    expect(c.blocks, hasLength(1));
  });

  testWidgets('그물이 응답하지 않으면 음식 표를 1.5초만 기다리고 운동 칸을 만든다', (tester) async {
    final paths = <String>[];
    final ai = RecordAi(
      endpoint: 'https://example.invalid',
      accountToken: () => 'acct',
      client: MockClient((request) {
        paths.add(request.url.path);
        return Completer<http.Response>().future;
      }),
    );
    final c = RoutineEditorController();
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: CupertinoPageScaffold(
          child: SafeArea(
            child: RoutineEditor(
              controller: c,
              ai: ai,
              mealText: ValueNotifier(null),
              onMealText: (text, index) => null,
            ),
          ),
        ),
      ),
    );
    await tester.enterText(_field, '민수식 로우');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(RecordAi.decideWait + const Duration(milliseconds: 100));
    expect(paths, ['/api/foods/match']);
    expect(c.blocks.single.name, '민수식 로우');
    await tester.pumpAndSettle();
  });

  testWidgets('수 없는 120자 넘는 식단 글도 끼니 근거가 있으면 끼니다 — 120자 안내는 운동 이름에만', (
    tester,
  ) async {
    final ai = _Ai();
    final (c, meals) = await pump(tester, ai);
    final line = List.filled(12, '점심 김치찌개 공기밥').join(' ');
    expect(line.length, greaterThan(120));
    await submit(tester, line);
    expect(meals, [line]);
    expect(c.blocks, isEmpty);
    expect(find.textContaining('120'), findsNothing);
    // 끼니 근거가 없는 긴 이름은 여전히 입력칸에 두고 알린다.
    final name = List.filled(20, '민수식 로우').join(' ');
    await submit(tester, name);
    expect(c.blocks, isEmpty);
    expect(find.textContaining('120'), findsOneWidget);
    expect(ai.lookups, [line, name], reason: '200자까지는 판정자가 끼니인지 먼저 본다');
  });

  testWidgets('좁은 화면·긴 문구(태국어)에서도 되돌리기 줄이 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ai = _Ai(table: {'ข้าวผัด'});
    final meals = <String>[];
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('th'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: CupertinoPageScaffold(
          resizeToAvoidBottomInset: false,
          child: SafeArea(
            child: RoutineEditor(
              controller: RoutineEditorController(),
              ai: ai,
              mealText: ValueNotifier(null),
              onMealText: (text, index) {
                meals.add(text);
                return () => meals.remove(text);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await submit(tester, 'ข้าวผัด');
    expect(meals, ['ข้าวผัด']);
    expect(find.byKey(const ValueKey('meal-undo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '자동으로 만든 칸의 이름(세트 없음)은 근거가 아니다 — 아메리카노가 한 번 운동 칸이 되었어도 판정자가 가른다',
    (tester) async {
      final ai = _Ai(judge: {'아메리카노': true, '마라샹궈': true});
      final (c, meals) = await pump(
        tester,
        ai,
        history: ['아메리카노', '마라샹궈', '민수식 로우'],
        done: ['민수식 로우'],
      );
      await submit(tester, '아메리카노');
      await submit(tester, '마라샹궈');
      expect(meals, ['아메리카노', '마라샹궈']);
      expect(c.blocks, isEmpty);
      expect(ai.lookups, ['아메리카노', '마라샹궈']);
      // 세트를 적은 운동 이름은 사람이 운동으로 남긴 것이다 — 묻지 않고 운동이다.
      await submit(tester, '민수식 로우');
      expect(c.blocks.single.name, '민수식 로우');
      expect(ai.lookups, ['아메리카노', '마라샹궈']);
      expect(find.byKey(const ValueKey('exercise-to-meal')), findsNothing);
    },
  );

  testWidgets('판정자의 답이 낱말 목록보다 먼저다 — 운동이라고 하면 음식 낱말이 있어도 운동이다', (tester) async {
    final ai = _Ai(judge: {'치킨윙': false});
    final (c, meals) = await pump(tester, ai);
    await submit(tester, '치킨윙');
    expect(meals, isEmpty);
    expect(c.blocks.single.name, '치킨윙');
    expect(find.byKey(const ValueKey('exercise-to-meal')), findsOneWidget);
  });

  testWidgets('근거 없이 만든 운동 칸은 한 줄에서 끼니로 바꾸고, 그 이름을 익히지 않는다', (tester) async {
    final ai = _Ai(online: false);
    final (c, meals) = await pump(tester, ai);
    await submit(tester, '마라샹궈');
    expect(c.blocks.single.name, '마라샹궈');
    expect(find.textContaining('운동으로 적었어요'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercise-to-meal')));
    await tester.pumpAndSettle();
    expect(c.blocks, isEmpty, reason: '빈 운동 칸을 지운다');
    expect(meals, ['마라샹궈']);
    expect(c.recentExercises, isNot(contains('마라샹궈')));
    expect(find.byKey(const ValueKey('meal-undo')), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-to-meal')), findsNothing);
  });

  testWidgets('근거 없이 만든 칸에 세트를 치면 끼니로 바꾸기 줄은 사라진다', (tester) async {
    final (c, _) = await pump(tester, _Ai(online: false));
    await submit(tester, '마라샹궈');
    expect(find.byKey(const ValueKey('exercise-to-meal')), findsOneWidget);
    // 세트 줄은 키패드로 친다.
    tester.widget<SetKeypad>(find.byType(SetKeypad)).onKey('8');
    await tester.pump();
    expect(find.byKey(const ValueKey('exercise-to-meal')), findsNothing);
    expect(c.blocks.single.name, '마라샹궈');
  });

  testWidgets('운동 근거가 있는 칸에는 끼니로 바꾸기 줄이 없다', (tester) async {
    final (c, _) = await pump(tester, _Ai(online: false));
    await submit(tester, '벤치프레스');
    expect(c.blocks.single.name, '벤치프레스');
    expect(find.byKey(const ValueKey('exercise-to-meal')), findsNothing);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('${platform.name}: 식단 글 모드에서 한글을 칠 때 앱은 자판으로 값을 되밀지 않는다', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final meal = ValueNotifier<({String text, int? index})?>(null);
      final meals = <String>[];
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 5')
        ..closeBlock();
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: CupertinoPageScaffold(
            resizeToAvoidBottomInset: false,
            child: SafeArea(
              child: RoutineEditor(
                controller: c,
                ai: _Ai(),
                mealText: meal,
                onMealText: (text, index) {
                  meals.add(text);
                  return null;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      meal.value = (text: '', index: null);
      await tester.pumpAndSettle();
      final field = tester.widget<CupertinoTextField>(_field).controller!;
      expect(field.text, isEmpty, reason: '식단 줄에는 표지가 없다');
      tester.testTextInput.log.clear();
      // 지우고-넣기(사이에 빈 값)와 조합 범위, 사이마다 프레임.
      for (final v in [
        const TextEditingValue(
          text: 'ㅇ',
          selection: TextSelection.collapsed(offset: 1),
        ),
        const TextEditingValue(selection: TextSelection.collapsed(offset: 0)),
        const TextEditingValue(
          text: '아',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
        const TextEditingValue(
          text: '아이',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 1, end: 2),
        ),
        const TextEditingValue(
          text: '아이스',
          selection: TextSelection.collapsed(offset: 3),
        ),
      ]) {
        tester.testTextInput.updateEditingValue(v);
        await tester.pump(const Duration(milliseconds: 16));
        expect(field.value, v);
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.testTextInput.log.where(
          (call) => call.method == 'TextInput.setEditingState',
        ),
        isEmpty,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(meals, ['아이스']);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
