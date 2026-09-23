// 입력 줄 하나로 운동과 끼니를 가른다 (v3 §2). 순서: 운동 근거 → 끼니 근거 →
// 음식 표 → 모델의 "food" → 운동. 알아서 끼니가 되면 '운동으로 바꾸기' 로 되돌린다.
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/meal.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/record_ai.dart';

/// 음식 표와 모델 대신 대답한다. [online] 이 false 면 그물이 없는 것이다.
class _Ai extends RecordAi {
  _Ai({this.online = true, this.table = const {}, this.answer});
  final bool online;
  final Set<String> table;
  final Map<String, Object?>? answer;
  final lookups = <String>[];
  final asked = <String>[];

  @override
  bool get supported => online;

  @override
  Future<bool> isFood(String text) async {
    lookups.add(text);
    return table.contains(text);
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
    for (final text in ['점심', '김치찌개', '푸시업 20개', '버피 30개', '세트 메뉴', '컵라면']) {
      expect(mealEvidence(text), isFalse, reason: text);
    }
  });

  Future<(RoutineEditorController, List<String>)> pump(
    WidgetTester tester,
    _Ai ai,
  ) async {
    final c = RoutineEditorController();
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
    final ai = _Ai(table: {'김치찌개'});
    final (c, meals) = await pump(tester, ai);
    await submit(tester, '김치찌개');
    expect(meals, ['김치찌개']);
    expect(c.blocks, isEmpty);
    expect(ai.asked, isEmpty, reason: '음식 표는 모델이 아니다');
    expect(find.textContaining('끼니로 남겼어요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('meal-undo')));
    await tester.pumpAndSettle();
    expect(meals, isEmpty, reason: '그 끼니를 지운다');
    expect(c.blocks.single.name, '김치찌개');
    expect(ai.lookups, ['김치찌개'], reason: '바꾼 뒤에는 표를 다시 보지 않는다');
    expect(find.textContaining('끼니로 남겼어요'), findsNothing);
  });

  testWidgets('끼니 근거가 있으면 표도 모델도 묻지 않고 끼니다 — 다음에 치면 되돌리기 줄은 사라진다', (
    tester,
  ) async {
    final ai = _Ai();
    final (c, meals) = await pump(tester, ai);
    await submit(tester, '점심 김밥 한 줄');
    expect(meals, ['점심 김밥 한 줄']);
    expect(ai.lookups, isEmpty);
    expect(ai.asked, isEmpty);
    await tester.enterText(_field, '벤');
    await tester.pump();
    expect(find.textContaining('끼니로 남겼어요'), findsNothing);
    expect(c.blocks, isEmpty);
  });

  testWidgets('운동 근거가 먼저다 — 케이블 크런치·벤치 80kg 5x5 는 표를 보지 않는다', (tester) async {
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
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(c.blocks.last.setup?.weight, 80);
    expect(ai.lookups, isEmpty);
    expect(meals, isEmpty);
  });

  testWidgets('수가 든 줄: 표에 없으면 모델이 읽고, 음식이라고 답하면 끼니다', (tester) async {
    final ai = _Ai(answer: {'exercises': [], 'unparsed': [], 'food': true});
    final (c, meals) = await pump(tester, ai);
    await submit(tester, '바나나 2개');
    expect(ai.lookups, ['바나나 2개']);
    expect(ai.asked, ['바나나 2개']);
    expect(meals, ['바나나 2개']);
    expect(c.blocks, isEmpty);
    // 운동으로 바꾸면 모델이 다시 읽는다 — 이번에는 음식 답을 끼니로 쓰지 않는다.
    await tester.tap(find.byKey(const ValueKey('meal-undo')));
    await tester.pumpAndSettle();
    expect(meals, isEmpty);
    expect(c.blocks.single.name, '바나나 2개');
    expect(ai.lookups, ['바나나 2개']);
  });

  testWidgets('그물이 없으면 표와 모델을 건너뛰고 운동이다 — 끼니로 칩은 남는다', (tester) async {
    final ai = _Ai(online: false, table: {'김치찌개'});
    final (c, meals) = await pump(tester, ai);
    await submit(tester, '김치찌개');
    expect(ai.lookups, isEmpty);
    expect(meals, isEmpty);
    expect(c.blocks.single.name, '김치찌개');
    // 끼니 근거는 그물 없이도 본다.
    c.closeBlock();
    await submit(tester, '라면 1봉지');
    expect(meals, ['라면 1봉지']);
    await tester.enterText(_field, '김치찌개');
    await tester.pump();
    expect(find.byKey(const ValueKey('log-as-meal')), findsOneWidget);
  });
}
