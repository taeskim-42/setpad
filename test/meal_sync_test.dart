// 식단 추정과 확정 저장이 갈렸는가 — 서버의 같은 줄에 맞는가.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/meal.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_ai.dart';

const gym = '11111111-2222-3333-4444-555555555555';

Note noteAt(String? gymId) => Note(
  id: 'n1',
  createdAt: DateTime(2026, 9, 21, 12),
  updatedAt: DateTime(2026, 9, 21, 12),
  gymId: gymId,
);

class FakeAi extends RecordAi {
  FakeAi(this.answer);
  Future<MealEstimate> Function(String text) answer;
  final asked = <String>[];
  @override
  bool get supported => true;
  @override
  Future<MealEstimate> estimateMealText(String text, {required String locale}) {
    asked.add(text);
    return answer(text);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('확정은 끼니의 id 로 PUT, 고치면 같은 id, 지우면 DELETE — 그물이 없으면 밀린다', () async {
    final calls = <(String, String, Map<String, Object?>?)>[];
    var online = false;
    final link = GymLink(
      endpoint: 'https://x',
      token: 't',
      client: MockClient((request) async {
        if (!online) throw http.ClientException('offline');
        calls.add((
          request.method,
          request.url.path,
          request.body.isEmpty
              ? null
              : (jsonDecode(request.body) as Map).cast<String, Object?>(),
        ));
        return http.Response('{"id":"row"}', 200);
      }),
    );
    final note = noteAt(gym);
    final first = MealEntry(
      at: DateTime(2026, 9, 21, 12, 30),
      kcal: 375,
      items: const ['그래놀라'],
      source: MealEntry.label,
      basis: const MealBasis(kcal: 250, amount: 100, unit: 'g'),
      eaten: 150,
    );
    note.meals.add(first);
    var saves = 0;
    await syncMeals(link, [note], onSynced: () => saves++);
    expect(calls, isEmpty);
    expect(first.dirty, isTrue, reason: '못 보냈으면 밀려 있다');

    // 밀린 채로 앱이 죽어도 남는다.
    final reloaded = Note.fromJson(
      jsonDecode(jsonEncode(note.toJson())) as Map<String, dynamic>,
    );
    expect(reloaded.meals.single.id, first.id);
    expect(reloaded.meals.single.dirty, isTrue);

    online = true;
    await syncMeals(link, [note], onSynced: () => saves++);
    await syncMeals(link, [note], onSynced: () => saves++); // 다시 불러도 또 보내지 않는다
    expect(calls, hasLength(1));
    expect(calls.single.$1, 'PUT');
    expect(calls.single.$2, '/api/meals/${first.id}');
    expect(calls.single.$3, {
      'gymId': gym,
      'kind': 'lunch',
      'eatenOn': '2026-09-21',
      'kcal': 375,
      'source': 'label',
      'items': ['그래놀라'],
      'amount': '150g',
    });
    expect(first.dirty, isFalse);
    expect(saves, 1);

    // 양을 고치면 같은 id 로 다시 간다 — 서버의 같은 줄이 바뀐다.
    note.meals[0] = MealEntry(
      id: first.id,
      at: first.at,
      kcal: 250,
      items: first.items,
      source: MealEntry.label,
      basis: first.basis,
      eaten: 100,
    );
    await syncMeals(link, [note], onSynced: () {});
    expect(calls.last.$2, '/api/meals/${first.id}');
    expect(calls.last.$3!['kcal'], 250);

    // 지우면 그 줄을 지운다. 그물이 없을 때 지운 것도 밀렸다가 간다.
    online = false;
    note.removeMeal(note.meals.single);
    await syncMeals(link, [note], onSynced: () {});
    expect(note.deletedMeals, [first.id]);
    online = true;
    await syncMeals(link, [note], onSynced: () {});
    expect(calls.last.$1, 'DELETE');
    expect(calls.last.$2, '/api/meals/${first.id}');
    expect(note.deletedMeals, isEmpty);
  });

  test('도장 기록이 아니면 서버로 가지 않고, 예전 끼니는 한꺼번에 올라가지 않는다', () async {
    var calls = 0;
    final link = GymLink(
      endpoint: 'https://x',
      token: 't',
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    final local = noteAt(null)
      ..meals.add(MealEntry(at: DateTime(2026, 9, 21), kcal: null, text: '김밥'));
    local.removeMeal(local.meals.single);
    expect(local.deletedMeals, isEmpty, reason: '올린 적 없는 것을 지우러 가지 않는다');
    final old = MealEntry.tryFromJson({
      'at': '2026-09-01T12:00:00.000',
      'kcal': 650,
      'items': ['김치찌개'],
    })!;
    expect(old.dirty, isFalse);
    expect(old.id, isNotEmpty);
    await syncMeals(link, [
      local,
      noteAt(gym)..meals.add(old),
    ], onSynced: () {});
    expect(calls, 0);
  });

  test('추정 요청은 저장하지 말라고 말하고, 글 추정은 원문을 보낸다', () async {
    final bodies = <Map<String, Object?>>[];
    final ai = RecordAi(
      endpoint: 'https://x',
      deviceId: 'device-id-0123456789',
      client: MockClient((request) async {
        if (request.url.path == '/api/device') {
          return http.Response('{"token":"d"}', 200);
        }
        bodies.add((jsonDecode(request.body) as Map).cast<String, Object?>());
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'kcal': 713,
              'items': ['김밥', '라면'],
              'saved': false,
              'refs': [
                {
                  'name': '김밥',
                  'kind': 'dish',
                  'per': 'g',
                  'kcalPer100': 140,
                  'url': 'https://various.foodsafetykorea.go.kr/x',
                },
                // 기기 브라우저로 여는 주소다 — https 가 아니면 받지 않는다.
                {
                  'name': '라면',
                  'kind': 'dish',
                  'per': 'g',
                  'kcalPer100': 120,
                  'url': 'http://example.com',
                },
              ],
            }),
          ),
          200,
        );
      }),
    );
    final estimate = await ai.estimateMealText('김밥 한 줄, 라면 반 개', locale: 'ko');
    expect(estimate.kcal, 713);
    expect(estimate.sources.map((s) => (s.name, s.kcalPer100)), [('김밥', 140)]);
    expect(bodies.single, {
      'text': '김밥 한 줄, 라면 반 개',
      'language': 'ko',
      'save': false,
    });
  });

  testWidgets('글 식단은 먼저 저장되고, 어림값은 나중에 같은 끼니에 붙으며, 실패하면 미상으로 남는다', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('setpad_meal_sync_');
    final store = NotesStore(directory: dir);
    addTearDown(() {
      store.dispose();
      dir.deleteSync(recursive: true);
    });
    final puts = <Map<String, Object?>>[];
    final account = Account(
      client: MockClient((request) async {
        if (request.method == 'PUT') {
          puts.add({
            'path': request.url.path,
            ...(jsonDecode(request.body) as Map).cast<String, Object?>(),
          });
        }
        return http.Response('{}', 200);
      }),
      storageDir: dir,
    )..token = 'member';
    final note = store.create(gymId: gym);
    late Future<MealEstimate> Function(String) reply;
    final ai = FakeAi((text) => reply(text));
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: EditorPage(store: store, note: note, account: account, ai: ai),
      ),
    );
    await tester.pumpAndSettle();
    final input = find.byType(CupertinoTextField);
    Future<void> write(String text) async {
      // 식단 적기는 입력 줄 위 막대에 있다 — 화면 맨 위의 버튼은 뺐다.
      await tester.tap(find.byKey(const ValueKey('meal-text-toggle')));
      await tester.pumpAndSettle();
      await tester.enterText(input, text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    reply = (_) async => const MealEstimate(kcal: 713, items: ['김밥', '라면']);
    await write('김밥 한 줄, 라면 반 개');
    final meal = note.meals.single;
    expect(meal.text, '김밥 한 줄, 라면 반 개', reason: '원문 그대로');
    expect(meal.kcal, 713);
    expect(meal.source, MealEntry.estimate);
    expect(find.text('713kcal'), findsWidgets);
    // 어림이라는 것은 숫자 앞 '약'(藥으로 읽혔다)이 아니라 먹은 것 칸의 추정 표시다.
    expect(find.text('추정'), findsOneWidget);
    // 서버에는 미상으로 먼저, 어림값으로 나중에 — 같은 줄에.
    expect(puts.map((p) => p['kcal']), [null, 713]);
    expect(puts.map((p) => p['path']).toSet(), {'/api/meals/${meal.id}'});
    expect(puts.every((p) => p['text'] == '김밥 한 줄, 라면 반 개'), isTrue);

    // 어림에 실패해도 기록은 남고 열량은 미상이다.
    reply = (_) async =>
        throw const RecordAiException(RecordAiStatus.unavailable);
    await write('엄마표 비밀 반찬 조금');
    expect(note.meals.last.text, '엄마표 비밀 반찬 조금');
    expect(note.meals.last.kcal, isNull);
    expect(note.unknownMeals, 1);

    // 직접 적은 열량은 묻지 않는다.
    final asked = ai.asked.length;
    await write('닭가슴살 150g 165kcal');
    expect(ai.asked, hasLength(asked));
    expect(note.meals.last.source, MealEntry.typed);
    expect(puts.last['source'], 'typed');
  });

  test('C·식단 글 — 천 단위 쉼표는 수의 일부이고, 일부만 적은 열량은 합계로 끝내지 않는다', () {
    // 쉼표 뒤만 읽던 때: '2,000kcal' 은 0, '1,200칼로리' 는 200 이었다.
    expect(parseMealText('피자 2,000kcal').kcal, 2000);
    final buffet = parseMealText('1,200칼로리 뷔페');
    expect(buffet.kcal, 1200);
    expect(buffet.foods.single.name, '뷔페');
    expect(parseMealText('샐러드 300kcal 정도').kcal, 300);
    // 열량을 안 적은 음식이 있으면 합계를 모른다 — 0 으로 치지 않는다.
    final partial = parseMealText('닭가슴살 330kcal, 밥 한 공기');
    expect(partial.kcal, isNull);
    expect(partial.foods.map((f) => (f.name, f.amount, f.unit)), [
      ('닭가슴살', null, null),
      ('밥', 1.0, '공기'),
    ]);
    // 쉼표가 없어도 열량 양쪽의 말은 다른 음식이다.
    final two = parseMealText('프로틴 120kcal 바나나');
    expect(two.kcal, isNull);
    expect(two.foods.map((f) => f.name), ['프로틴', '바나나']);
    expect(parseMealText('프로틴 120kcal, 바나나 90kcal').kcal, 210);
  });

  test('C·열량을 다 적은 끼니는 뒤에 붙은 말·양이 있어도 적은 값 그대로다 — 어림을 부르지 않는다', () {
    // 뒤의 토막이 서술어·양·괄호뿐이면 같은 음식의 말이다. 전에는 '먹음' 을
    // 열량 없는 음식으로 세어 적은 500 을 버리고 어림(적기 도움 한 칸)을 불렀다.
    for (final (text, kcal) in [
      ('점심 500kcal 먹음', 500),
      ('라떼 150kcal 한 잔', 150),
      ('닭가슴살 165kcal (100g)', 165),
      ('아침 400kcal 정도 먹었다', 400),
      ('총 1,500kcal 먹음', 1500),
      ('밥 300kcal 김치 20kcal 먹었어요', 320),
      ('coffee 90kcal, 2 cups', 90), // 쉼표 뒤의 양뿐인 조각도 앞 음식의 말이다
      ('라면, 500kcal', 500), // 열량만 있는 조각은 앞 음식의 값이다
    ]) {
      final parsed = parseMealText(text);
      expect((parsed.kcal, parsed.typed), (kcal, kcal), reason: text);
    }
    expect(parseMealText('점심 500kcal 먹음').foods.single.name, '점심 먹음');
    // 또렷이 다른 음식이 있으면 합계를 모른다. 적은 값은 부분으로 남는다.
    final partial = parseMealText('프로틴 120kcal 바나나 한 개');
    expect((partial.kcal, partial.typed), (null, 120));
    expect(parseMealText('김밥 한 줄').typed, isNull);
  });

  testWidgets('C·식단 어림이 막히면 까닭을 한 번 말하고, 끼니 줄을 눌러 Enter 로 다시 어림한다', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('setpad_meal_reason_');
    final store = NotesStore(directory: dir);
    addTearDown(() {
      store.dispose();
      dir.deleteSync(recursive: true);
    });
    final l = lookupL(const Locale('ko'));
    final note = store.create();
    late Future<MealEstimate> Function(String) reply;
    final ai = FakeAi((text) => reply(text));
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: EditorPage(store: store, note: note, ai: ai),
      ),
    );
    await tester.pumpAndSettle();
    final input = find.byType(CupertinoTextField);
    Future<void> submit(String text) async {
      await tester.enterText(input, text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    Future<void> write(String text) async {
      await tester.tap(find.byKey(const ValueKey('meal-text-toggle')));
      await tester.pumpAndSettle();
      await submit(text);
    }

    // 모르는 음식 — 서버 422 unknownFood.
    reply = (_) async => throw const RecordAiException(
      RecordAiStatus.unavailable,
      code: 'unknownFood',
    );
    await write('엄마표 비밀 반찬 조금');
    expect(note.meals.single.kcal, isNull);
    expect(find.text(l.mealTextUnknown), findsOneWidget);

    // 연결이 안 됨 — 까닭이 다르다.
    reply = (_) async =>
        throw const RecordAiException(RecordAiStatus.unavailable);
    await write('김밥 한 줄');
    expect(find.text(l.mealTextOffline), findsOneWidget);
    expect(find.text(l.mealTextUnknown), findsNothing);

    // 끼니 줄을 누르면 글이 돌아오고, 그대로 Enter 를 누르면 다시 어림한다.
    reply = (_) async => const MealEstimate(kcal: 480, items: ['김밥']);
    await tester.tap(find.byKey(const ValueKey('meal-1')));
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(ai.asked.last, '김밥 한 줄');
    expect(note.meals[1].kcal, 480);
    expect(note.meals, hasLength(2), reason: '같은 끼니를 고친다');
    expect(
      find.text(l.mealTextOffline),
      findsNothing,
      reason: '붙었으면 실패 말은 지운다',
    );

    // 일부만 적은 열량은 합계로 끝내지 않고 어림을 부른다 — 글은 친 그대로 간다.
    reply = (_) async => const MealEstimate(kcal: 630, items: ['닭가슴살', '밥']);
    await write('닭가슴살 330kcal, 밥 한 공기');
    expect(ai.asked.last, '닭가슴살 330kcal, 밥 한 공기');
    expect(note.meals.last.kcal, 630);
    expect(note.meals.last.source, MealEntry.estimate);

    // 서버가 받지 않는 길이는 보내지 않고 까닭을 말한다. 끼니는 남는다.
    final asked = ai.asked.length;
    await write('김밥 한 줄, ' * 70);
    expect(ai.asked, hasLength(asked));
    expect(note.meals, hasLength(4));
    expect(find.text(l.mealTextTooLong), findsOneWidget);
  });

  testWidgets(
    'C·적은 열량은 어림이 막혀도·더 작게 와도 남고, 실패 말은 그 끼니의 것만 뜨고 지워지며, 줄에서 다시 어림한다',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('setpad_meal_partial_');
      final store = NotesStore(directory: dir);
      addTearDown(() {
        store.dispose();
        dir.deleteSync(recursive: true);
      });
      final l = lookupL(const Locale('ko'));
      final note = store.create();
      late Future<MealEstimate> Function(String) reply;
      final ai = FakeAi((text) => reply(text));
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: EditorPage(store: store, note: note, ai: ai),
        ),
      );
      await tester.pumpAndSettle();
      final input = find.byType(CupertinoTextField);
      Future<void> submit(String text) async {
        await tester.enterText(input, text);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }

      Future<void> write(String text) async {
        await tester.tap(find.byKey(const ValueKey('meal-text-toggle')));
        await tester.pumpAndSettle();
        await submit(text);
      }

      // 어림을 기다리는 동안 줄은 어림 중이라고 말하고, 다시 어림 단추는 없다.
      final pending = Completer<MealEstimate>();
      reply = (_) => pending.future;
      await write('김밥');
      expect(find.textContaining(l.mealEstimating), findsOneWidget);
      expect(find.byKey(const ValueKey('meal-retry-0')), findsNothing);
      // 그사이 열량을 적어 고쳤다. 옛 끼니의 실패는 이 끼니의 말이 아니다.
      await tester.tap(find.byKey(const ValueKey('meal-0')));
      await tester.pumpAndSettle();
      await submit('김밥 480kcal');
      pending.completeError(
        const RecordAiException(RecordAiStatus.unavailable),
      );
      await tester.pumpAndSettle();
      expect(
        (note.meals.single.kcal, note.meals.single.text),
        (480, '김밥 480kcal'),
      );
      expect(find.text(l.mealTextOffline), findsNothing);

      // 모르는 음식의 말은 다른 끼니의 어림이 붙어도 지워지지 않는다.
      reply = (_) async => throw const RecordAiException(
        RecordAiStatus.unavailable,
        code: 'unknownFood',
      );
      await write('엄마표 반찬 조금');
      reply = (_) async => const MealEstimate(kcal: 480, items: ['김밥']);
      await write('김밥 한 줄');
      expect(note.meals[2].kcal, 480);
      expect(find.text(l.mealTextUnknown), findsOneWidget);
      // 열량을 모르는 끼니는 그 줄에서 다시 어림한다. 붙으면 그 끼니의 말을 지운다.
      expect(find.byKey(const ValueKey('meal-retry-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('meal-retry-2')), findsNothing);
      reply = (_) async => const MealEstimate(kcal: 300, items: ['반찬']);
      await tester.tap(find.byKey(const ValueKey('meal-retry-1')));
      await tester.pumpAndSettle();
      expect(ai.asked.last, '엄마표 반찬 조금');
      expect(
        (note.meals[1].kcal, note.meals[1].source),
        (300, MealEntry.estimate),
      );
      expect(find.text(l.mealTextUnknown), findsNothing);
      expect(find.byKey(const ValueKey('meal-retry-1')), findsNothing);

      // 어림이 적은 합보다 작으면 받지 않는다 — 적은 330 만 넣고 그렇다고 말한다.
      reply = (_) async => const MealEstimate(kcal: 200, items: ['닭가슴살', '밥']);
      await write('닭가슴살 330kcal, 밥 한 공기');
      expect(
        (note.meals[3].kcal, note.meals[3].source),
        (330, MealEntry.typed),
      );
      expect(find.text(l.mealTextBelowTyped(330)), findsOneWidget);
      expect(find.textContaining(l.kcalAtLeast(330)), findsOneWidget);
      expect(find.byKey(const ValueKey('meal-retry-3')), findsOneWidget);
      // 서버가 먼저 같은 검사로 거절해도(502 belowTyped) 연결 탓이 아니라 같은 까닭이다.
      reply = (_) async => throw const RecordAiException(
        RecordAiStatus.unavailable,
        code: 'belowTyped',
      );
      await tester.tap(find.byKey(const ValueKey('meal-retry-3')));
      await tester.pumpAndSettle();
      expect(
        (note.meals[3].kcal, note.meals[3].source),
        (330, MealEntry.typed),
      );
      expect(find.text(l.mealTextBelowTyped(330)), findsOneWidget);

      // 어림이 막혀도 적은 330 은 합계에 남는다. 까닭과 함께 그렇다고 말한다.
      reply = (_) async =>
          throw const RecordAiException(RecordAiStatus.unavailable);
      await write('닭가슴살 330kcal, 엄마표 반찬 조금');
      expect(note.meals[4].kcal, 330);
      expect(
        find.text('${l.mealTextOffline}\n${l.mealTextPartial(330)}'),
        findsOneWidget,
      );
      expect(note.intake, 480 + 300 + 480 + 330 + 330);
      expect(note.unknownMeals, 2, reason: '적은 것만 든 끼니는 온전한 값이 아니다');
    },
  );

  testWidgets('C·끼니 어림 실패 말은 사람이 그 끼니를 고치거나 지우면 사라진다', (tester) async {
    final dir = Directory.systemTemp.createTempSync('setpad_meal_stale_');
    final store = NotesStore(directory: dir);
    addTearDown(() {
      store.dispose();
      dir.deleteSync(recursive: true);
    });
    final l = lookupL(const Locale('ko'));
    final note = store.create();
    final ai = FakeAi(
      (_) async => throw const RecordAiException(RecordAiStatus.unavailable),
    );
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: EditorPage(store: store, note: note, ai: ai),
      ),
    );
    await tester.pumpAndSettle();
    final input = find.byType(CupertinoTextField);
    Future<void> submit(String text) async {
      await tester.enterText(input, text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const ValueKey('meal-text-toggle')));
    await tester.pumpAndSettle();
    await submit('김밥');
    expect(find.text(l.mealTextOffline), findsOneWidget);

    // 안내가 시킨 대로 줄을 눌러 열량을 적었다 — 어림할 일이 없으니 옛 말은 틀린 말이다.
    await tester.tap(find.byKey(const ValueKey('meal-0')));
    await tester.pumpAndSettle();
    await submit('김밥 480kcal');
    expect(
      (note.meals.single.kcal, note.meals.single.source),
      (480, MealEntry.typed),
    );
    expect(find.text(l.mealTextOffline), findsNothing);

    // 실패한 끼니를 지워도 그 끼니의 말은 남지 않는다.
    await tester.tap(find.byKey(const ValueKey('meal-text-toggle')));
    await tester.pumpAndSettle();
    await submit('엄마표 반찬 조금');
    expect(find.text(l.mealTextOffline), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('meal-delete-1')));
    await tester.pumpAndSettle();
    expect(note.meals.single.text, '김밥 480kcal');
    expect(find.text(l.mealTextOffline), findsNothing);
  });

  testWidgets('표로 셈한 끼니는 출처를 누르면 그 표의 값과 링크가 나오고, 저장본에도 남는다', (tester) async {
    final dir = Directory.systemTemp.createTempSync('setpad_meal_sources_');
    final store = NotesStore(directory: dir);
    addTearDown(() {
      store.dispose();
      dir.deleteSync(recursive: true);
    });
    final note = store.create();
    final ai = FakeAi(
      (text) async => text.contains('김치찌개')
          ? const MealEstimate(
              kcal: 244,
              items: ['김치찌개'],
              sources: [
                MealSource(
                  name: '김치찌개_돼지고기',
                  kcalPer100: 61,
                  per: 'g',
                  url: 'https://various.foodsafetykorea.go.kr/x',
                  kind: 'dish',
                ),
              ],
            )
          : const MealEstimate(kcal: 300, items: ['잡탕']),
    );
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: EditorPage(store: store, note: note, ai: ai),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> write(String text) async {
      await tester.tap(find.byKey(const ValueKey('meal-text-toggle')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(CupertinoTextField), text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    await write('김치찌개 400g');
    await write('엄마표 잡탕');
    // 모델 혼자 어림한 끼니에는 출처가 없다 — 없는 근거를 보여 주지 않는다.
    expect(find.byKey(const ValueKey('meal-sources-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-sources-1')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('meal-sources-0')));
    await tester.pumpAndSettle();
    expect(find.text('열량 근거'), findsOneWidget);
    expect(find.text('김치찌개_돼지고기'), findsOneWidget);
    expect(find.text('100g당 61kcal · 식약처 식품영양성분 DB'), findsOneWidget);
    await tester.tap(find.text('김치찌개_돼지고기'));
    await tester.pumpAndSettle();
    expect(find.text('열량 근거'), findsNothing);

    // 저장본에도 남는다 — 다시 열어도 같은 링크다.
    final kept = MealEntry.tryFromJson(
      jsonDecode(jsonEncode(note.meals.first.toJson())),
    )!.sources.single;
    expect(
      (kept.name, kept.kcalPer100, kept.url),
      ('김치찌개_돼지고기', 61, 'https://various.foodsafetykorea.go.kr/x'),
    );
  });
}
