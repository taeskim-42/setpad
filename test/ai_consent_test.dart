// AI 도움(DeepSeek) — 묻지 않고 켜져 있고, 설정의 AI 도움 줄에서 끄면 모델로
// 가는 것이 모두 멈춘다. 모델로 가는 문(ask·estimateMeal·estimateMealText)은 모두
// RecordAi.enabled 를 지나므로, 화면마다 처음 써도 시트 없이 가는지, 꺼 두면
// 아무것도 나가지 않고 기기 안의 길이 남는지 본다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/account.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/routine.dart';
import 'package:setpad/settings_page.dart';

import 'routine_fixture.dart';

final l = lookupL(const Locale('ko'));

const _modelPaths = {'/api/record-query', '/api/meals/estimate'};

/// 서버 대신. 들어온 경로를 적는다 — 꺼 두었는데 모델 경로가 불리면 여기 남는다.
({RecordAi ai, List<String> paths}) serverAi(bool Function() enabled) {
  final paths = <String>[];
  final ai = RecordAi(
    endpoint: 'https://x',
    deviceId: 'd' * 16,
    enabled: enabled,
    client: MockClient((request) async {
      paths.add(request.url.path);
      return switch (request.url.path) {
        '/api/device' => http.Response('{"token":"t"}', 200),
        '/api/foods/match' => http.Response('{"food":false}', 200),
        '/api/meals/estimate' => http.Response(
          jsonEncode({
            'kcal': 480,
            'items': ['김밥'],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
        _ => http.Response(jsonEncode({'intent': {}}), 200),
      };
    }),
  );
  return (ai: ai, paths: paths);
}

Directory tempDir() {
  final dir = Directory.systemTemp.createTempSync('setpad_ai_');
  addTearDown(() => dir.deleteSync(recursive: true));
  return dir;
}

/// 아무것도 고르지 않은 새 가게 — 새로 깐 사람, 1.4.0 에서 시트를 그냥 닫은 사람.
NotesStore tempStore() {
  final store = NotesStore(directory: tempDir());
  addTearDown(store.dispose);
  return store;
}

/// 기록을 손에 쥔 가게. 오늘 루틴은 기록으로 짠다.
class _Records extends NotesStore {
  _Records(this.records, Directory dir) : super(directory: dir);
  final List<Note> records;
  @override
  List<Note> get notes => records;
}

/// 고정 기록을 오늘 기준으로 옮긴다(화면은 지금 시각으로 짠다).
List<Note> relativeLog() {
  final days = Duration(days: DateTime.now().difference(routineToday).inDays);
  return [
    for (final n in defaultLog())
      Note(
        id: n.id,
        createdAt: n.createdAt.add(days),
        updatedAt: n.updatedAt.add(days),
        blocks: n.blocks,
        routineId: n.routineId,
      ),
  ];
}

Widget app(Widget home) => CupertinoApp(
  locale: const Locale('ko'),
  localizationsDelegates: L.localizationsDelegates,
  supportedLocales: L.supportedLocales,
  home: home,
);

/// 모델 앞에 뜨는 창이 없다 — 예전 동의 시트는 액션시트였다.
void expectNoPrompt() {
  expect(find.byType(CupertinoActionSheet), findsNothing);
  expect(find.byType(CupertinoAlertDialog), findsNothing);
}

Future<void> submit(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(CupertinoTextField).last, text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

Future<void> search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(CupertinoSearchTextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// 운동 입력 줄 하나. 모델이 읽으면 칸이 된다.
Future<({RoutineEditorController c, List<String> asked})> inputLine(
  WidgetTester tester,
  NotesStore store,
) async {
  final asked = <String>[];
  final ai = RecordAi(
    enabled: () => store.aiOn,
    respond: (instructions, input) async {
      asked.add(input);
      return {
        'exercises': [
          {
            'text': '벤치 80kg 5x5',
            'name': '벤치',
            'weight': 80,
            'repsPerSet': 5,
            'totalSets': 5,
          },
        ],
      };
    },
  );
  final c = RoutineEditorController();
  await tester.pumpWidget(
    app(
      CupertinoPageScaffold(
        resizeToAvoidBottomInset: false,
        child: SafeArea(
          child: RoutineEditor(controller: c, ai: ai),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (c: c, asked: asked);
}

/// 식단 글을 한 줄 넣는다.
Future<void> writeMeal(WidgetTester tester, String text) async {
  await tester.tap(find.byKey(const ValueKey('meal-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('meal-text-toggle')));
  await tester.pumpAndSettle();
  await submit(tester, text);
}

/// 식단 사진 → 카메라. 사진 고르는 창(플랫폼)은 [picked] 에 적고 취소로 답한다.
Future<List<String>> pickMealPhoto(WidgetTester tester) async {
  final picked = <String>[];
  const channel = MethodChannel('plugins.flutter.io/image_picker');
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (call) async {
    picked.add(call.method);
    return null;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  await tester.tap(find.byType(CupertinoTextField).last);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('meal-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l.mealCamera));
  await tester.pumpAndSettle();
  return picked;
}

void main() {
  setUpAll(() => initializeDateFormatting());
  RecordAi.forget();
  setUp(RecordAi.forget);

  group('켜짐 스위치가 남는 자리', () {
    Future<NotesStore> loaded(Directory dir) async {
      final store = NotesStore(directory: dir);
      await store.load();
      addTearDown(store.dispose);
      return store;
    }

    void preferences(Directory dir, Map<String, Object?> data) => File(
      '${dir.path}/preferences.json',
    ).writeAsStringSync(jsonEncode(data));

    test('처음이면 켜져 있고, 끈 것은 설정 파일에 남는다', () async {
      final dir = tempDir();
      final store = await loaded(dir);
      expect(store.aiOn, isTrue);
      store.setAiOn(false);
      await store.flush();
      expect((await loaded(dir)).aiOn, isFalse);
    });

    test('1.4.0 에서 나중에를 고른 사람은 꺼진 채, 답하지 않은 사람은 켜진다', () async {
      final declined = tempDir();
      preferences(declined, {'aiConsent': false, 'deviceId': 'd' * 16});
      expect((await loaded(declined)).aiOn, isFalse);

      final unanswered = tempDir();
      preferences(unanswered, {'deviceId': 'd' * 16});
      expect((await loaded(unanswered)).aiOn, isTrue);

      final agreed = tempDir();
      preferences(agreed, {'aiConsent': true, 'deviceId': 'd' * 16});
      expect((await loaded(agreed)).aiOn, isTrue);
    });

    test('계정이 만드는 RecordAi 가 스위치를 부를 때마다 읽는다', () {
      final store = tempStore();
      final ai = Account(aiEnabled: () => store.aiOn).ai;
      expect(ai.allowed, isTrue);
      store.setAiOn(false);
      expect(ai.allowed, isFalse);
    });

    testWidgets('설정의 AI 도움 줄: 처음부터 켜져 있고, 끄고 켜는 데 아무것도 묻지 않는다', (tester) async {
      final store = tempStore();
      await tester.pumpWidget(app(SettingsPage(store: store)));
      await tester.pumpAndSettle();
      expect(find.text(l.aiSetting), findsOneWidget);
      final toggle = find.descendant(
        of: find.byKey(const ValueKey('settings-ai')),
        matching: find.byType(CupertinoSwitch),
      );
      expect(tester.widget<CupertinoSwitch>(toggle).value, isTrue);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expectNoPrompt();
      expect(store.aiOn, isFalse);
      expect(tester.widget<CupertinoSwitch>(toggle).value, isFalse);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expectNoPrompt();
      expect(store.aiOn, isTrue);
      expect(tester.widget<CupertinoSwitch>(toggle).value, isTrue);
    });
  });

  group('처음 써도 묻지 않고 보낸다', () {
    test('한 줄 설정·기록 질문·오늘 루틴·식단 글·식단 사진 모두 모델에 간다', () async {
      final store = tempStore();
      final s = serverAi(() => store.aiOn);
      Future<void> sends(Future<Object?> Function() call) async {
        final before = s.paths.length;
        try {
          await call();
        } on FormatException {
          // 가짜 서버의 빈 답이다. 여기서 보는 것은 모델에 갔는가뿐이다.
        }
        expect(s.paths.skip(before).where(_modelPaths.contains), isNotEmpty);
      }

      await sends(() => s.ai.interpret('벤치 80kg 5x5', 'ko', const []));
      await sends(
        () => s.ai.queryIntent('벤치 최고 기록', 'ko', const ['벤치'], unit: 'kg'),
      );
      await sends(
        () => routineIntent(s.ai, '오늘 루틴 짜줘', 'ko', const ['벤치'], unit: 'kg'),
      );
      await sends(() => s.ai.estimateMealText('김밥 한 줄', locale: 'ko'));
      await sends(
        () => s.ai.estimateMeal(
          Uint8List.fromList(const [0xff, 0xd8, 0xff, 0xd9]),
          mime: 'image/jpeg',
          locale: 'ko',
        ),
      );
    });

    testWidgets('운동 입력 줄: 친 글을 모델이 읽는다', (tester) async {
      final store = tempStore();
      final line = await inputLine(tester, store);
      await submit(tester, '벤치 80kg 5x5');
      expectNoPrompt();
      expect(line.asked, hasLength(1));
      expect(find.text(l.aiOff), findsNothing);
    });

    testWidgets('식단 글: 열량을 안 적은 끼니를 모델이 어림한다', (tester) async {
      final store = tempStore();
      final note = store.create();
      final s = serverAi(() => store.aiOn);
      await tester.pumpWidget(
        app(EditorPage(store: store, note: note, ai: s.ai)),
      );
      await tester.pumpAndSettle();
      await writeMeal(tester, '김밥 한 줄');
      expectNoPrompt();
      expect(s.paths, contains('/api/meals/estimate'));
      expect(note.meals.single.kcal, 480);
    });

    testWidgets('식단 사진: 막지 않고 바로 사진 고르기로 간다', (tester) async {
      final store = tempStore();
      final note = store.create();
      final s = serverAi(() => store.aiOn);
      await tester.pumpWidget(
        app(EditorPage(store: store, note: note, ai: s.ai)),
      );
      await tester.pumpAndSettle();
      final picked = await pickMealPhoto(tester);
      expectNoPrompt();
      expect(picked, ['pickImage']);
      expect(find.text(l.aiOffPhoto), findsNothing);
    });

    testWidgets('기록 질문: 두 단계(갈래 고르기 → plan) 모두 묻지 않고 간다', (tester) async {
      final store = tempStore();
      final note = store.create();
      note.blocks.add(ExerciseBlock('벤치프레스', [LoggedSet(value: 80, reps: 5)]));
      var stageOne = 0, planCalls = 0;
      final ai = RecordAi(
        enabled: () => store.aiOn,
        respond: (i, _) async {
          if (i == familyInstructions) {
            stageOne++;
            return {
              't': ['rank'],
            };
          }
          planCalls++;
          return {
            'exercises': ['벤치프레스'],
            'measures': ['best'],
          };
        },
      );
      await tester.pumpWidget(
        app(NotesListPage(store: store, onOpen: (_) {}, ai: ai)),
      );
      await tester.pumpAndSettle();
      await search(tester, '벤치프레스 최고 기록 얼마야');
      expectNoPrompt();
      expect((stageOne, planCalls), (1, 1));
      expect(find.textContaining(l.readAsConfirm), findsOneWidget);
      expect(find.text(l.aiOff), findsNothing);
    });

    testWidgets('오늘 루틴: 조건 요청을 루틴 지시문으로 묻는다', (tester) async {
      final store = _Records(relativeLog(), tempDir());
      addTearDown(store.dispose);
      final sent = <String>[];
      final ai = RecordAi(
        enabled: () => store.aiOn,
        respond: (i, _) async {
          sent.add(i);
          return {
            'parts': ['legs'],
          };
        },
      );
      await tester.pumpWidget(
        app(NotesListPage(store: store, onOpen: (_) {}, ai: ai)),
      );
      await tester.pumpAndSettle();
      await search(tester, '하체로 짜줘');
      expectNoPrompt();
      expect(sent, [routineInstructions]);
      expect(find.text('스쿼트'), findsOneWidget);
      expect(find.text(l.aiOff), findsNothing);
    });
  });

  group('끄면 아무것도 보내지 않고, 막다른 길은 없다', () {
    test('한 줄 설정·기록 질문·오늘 루틴·식단 글·식단 사진 모두 아무것도 보내지 않는다', () async {
      final store = tempStore()..setAiOn(false);
      final s = serverAi(() => store.aiOn);
      Future<void> off(Future<Object?> Function() call) => expectLater(
        call(),
        throwsA(
          isA<RecordAiException>().having(
            (e) => e.status,
            'status',
            RecordAiStatus.aiOff,
          ),
        ),
      );
      await off(() => s.ai.interpret('벤치 80kg 5x5', 'ko', const []));
      await off(
        () => s.ai.queryIntent('벤치 최고 기록', 'ko', const ['벤치'], unit: 'kg'),
      );
      await off(
        () => routineIntent(s.ai, '오늘 루틴 짜줘', 'ko', const ['벤치'], unit: 'kg'),
      );
      await off(() => s.ai.estimateMealText('김밥 한 줄', locale: 'ko'));
      await off(
        () => s.ai.estimateMeal(
          Uint8List.fromList(const [0xff, 0xd8, 0xff, 0xd9]),
          mime: 'image/jpeg',
          locale: 'ko',
        ),
      );
      expect(s.paths, isEmpty, reason: '기기 토큰조차 받으러 가지 않는다');
    });

    test('음식 표 조회와 수 없는 이름은 모델이 아니다 — 꺼 두어도 된다', () async {
      final store = tempStore()..setAiOn(false);
      final s = serverAi(() => store.aiOn);
      expect(await s.ai.isFood('김치찌개'), isFalse);
      expect(s.paths, contains('/api/foods/match'));
      final reading = await s.ai.interpret('벤치프레스', 'ko', const []);
      expect(reading.exercises.single.setup.name, '벤치프레스');
    });

    testWidgets('운동 입력 줄: 친 글 그대로 칸이 되고 AI 가 꺼졌다고 한 줄 말한다; 다시 켜면 모델을 쓴다', (
      tester,
    ) async {
      final store = tempStore()..setAiOn(false);
      final line = await inputLine(tester, store);
      await submit(tester, '벤치 80kg 5x5');
      expect(line.asked, isEmpty, reason: '모델에 아무것도 가지 않았다');
      expect(line.c.blocks.single.name, '벤치 80kg 5x5');
      expect(line.c.blocks.single.setup, isNull);
      expect(find.text(l.aiOff), findsOneWidget);

      store.setAiOn(true);
      line.c.closeBlock();
      await submit(tester, '스쿼트 100kg 3x5');
      expect(line.asked, hasLength(1));
      expectNoPrompt();
      // setAiOn 의 저장 대기(0.4초). 예전엔 확인 창이 열리는 동안 지나갔다.
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('식단 글: 친 글과 적은 kcal 은 그대로 남고, 열량을 안 적은 끼니는 AI 가 꺼졌다고 말한다', (
      tester,
    ) async {
      final store = tempStore()..setAiOn(false);
      final note = store.create();
      final s = serverAi(() => store.aiOn);
      await tester.pumpWidget(
        app(EditorPage(store: store, note: note, ai: s.ai)),
      );
      await tester.pumpAndSettle();
      await writeMeal(tester, '김밥 한 줄');
      expect(note.meals.single.text, '김밥 한 줄');
      expect(note.meals.single.kcal, isNull);
      expect(find.text(l.aiOff), findsOneWidget);

      await writeMeal(tester, '라면 500kcal');
      expect(note.meals.last.kcal, 500, reason: '적은 kcal 은 모델 없이 들어간다');
      expect(s.paths, isEmpty);
    });

    testWidgets('식단 사진: 사진을 고르기 전에 멈추고, 글로 적는 길을 말한다', (tester) async {
      final store = tempStore()..setAiOn(false);
      final note = store.create();
      final s = serverAi(() => store.aiOn);
      await tester.pumpWidget(
        app(EditorPage(store: store, note: note, ai: s.ai)),
      );
      await tester.pumpAndSettle();
      final picked = await pickMealPhoto(tester);
      expect(picked, isEmpty, reason: '사진 고르기도 열지 않는다');
      expect(find.text(l.aiOffPhoto), findsOneWidget);
      expect(note.meals, isEmpty);
      expect(s.paths, isEmpty);
    });

    testWidgets('기록 질문: 두 단계 어느 쪽도 보내지 않고 AI 가 꺼졌다고 말한다 — 기기 안 목록은 그대로', (
      tester,
    ) async {
      final store = tempStore()..setAiOn(false);
      final note = store.create();
      note.blocks.add(ExerciseBlock('벤치프레스', [LoggedSet(value: 80, reps: 5)]));
      final asked = <String>[];
      final ai = RecordAi(
        enabled: () => store.aiOn,
        respond: (instructions, input) async {
          asked.add(instructions);
          return {'kind': 'unrelated'};
        },
      );
      await tester.pumpWidget(
        app(NotesListPage(store: store, onOpen: (_) {}, ai: ai)),
      );
      await tester.pumpAndSettle();
      await search(tester, '벤치 최고 기록');
      expect(asked, isEmpty);
      expect(find.text(l.aiOff), findsOneWidget);
      expect(find.text(l.queryPressEnter), findsNothing);
      expect(find.textContaining('벤치프레스'), findsWidgets, reason: '기기 안 목록');
    });

    testWidgets('오늘 루틴: 아무것도 보내지 않고 기기가 기록으로 짠다', (tester) async {
      final store = _Records(relativeLog(), tempDir())..setAiOn(false);
      addTearDown(store.dispose);
      final sent = <String>[];
      final ai = RecordAi(
        enabled: () => store.aiOn,
        respond: (i, _) async {
          sent.add(i);
          return {};
        },
      );
      await tester.pumpWidget(
        app(NotesListPage(store: store, onOpen: (_) {}, ai: ai)),
      );
      await tester.pumpAndSettle();
      await search(tester, '하체로 짜줘');
      expect(sent, isEmpty);
      expect(find.text(l.aiOff), findsOneWidget);
      expect(find.text(l.routineOffline), findsNothing);
      expect(
        find.widgetWithText(CupertinoButton, l.routineStart),
        findsOneWidget,
      );
    });
  });
}
