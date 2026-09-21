// 식단 추정과 확정 저장이 갈렸는가 — 서버의 같은 줄에 맞는가.
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
          utf8.encode('{"kcal":713,"items":["김밥","라면"],"saved":false}'),
          200,
        );
      }),
    );
    final estimate = await ai.estimateMealText('김밥 한 줄, 라면 반 개', locale: 'ko');
    expect(estimate.kcal, 713);
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
    expect(find.textContaining('약 713kcal'), findsWidgets);
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
}
