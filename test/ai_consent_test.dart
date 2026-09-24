// AI 도움(DeepSeek) 동의 — 처음 모델을 부르기 전에 한 번 묻고, '나중에' 여도
// 막다른 길은 없다. 모델로 가는 문(ask·estimateMeal·estimateMealText)은 모두
// RecordAi.consent 를 지나므로, 화면마다 동의 없이 아무것도 나가지 않는지 본다.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/ai_consent.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/routine.dart';
import 'package:setpad/settings_page.dart';

final l = lookupL(const Locale('ko'));

/// 서버 대신. 들어온 경로를 적는다 — 동의 없이 모델 경로가 불리면 여기 남는다.
({RecordAi ai, List<String> paths, List<int> asked}) serverAi(
  Future<bool> Function() consent,
) {
  final paths = <String>[];
  final asked = <int>[];
  final ai = RecordAi(
    endpoint: 'https://x',
    deviceId: 'd' * 16,
    consent: () {
      asked.add(1);
      return consent();
    },
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
  return (ai: ai, paths: paths, asked: asked);
}

NotesStore tempStore() {
  final dir = Directory.systemTemp.createTempSync('setpad_ai_consent_');
  addTearDown(() => dir.deleteSync(recursive: true));
  final store = NotesStore(directory: dir);
  addTearDown(store.dispose);
  return store;
}

Widget app(Widget home) => CupertinoApp(
  locale: const Locale('ko'),
  localizationsDelegates: L.localizationsDelegates,
  supportedLocales: L.supportedLocales,
  home: home,
);

/// 누르면 동의를 묻는 단추 하나. 답은 [answers] 에 쌓인다.
Widget asker(NotesStore store, List<bool> answers, {bool again = false}) => app(
  Builder(
    builder: (context) => CupertinoButton(
      onPressed: () async =>
          answers.add(await askAiConsent(context, store, again: again)),
      child: const Text('ask'),
    ),
  ),
);

void main() {
  RecordAi.forget();
  setUp(RecordAi.forget);

  group('동의 시트', () {
    testWidgets('DeepSeek·거치는 서버·보내는 것·처리방침을 말하고, 동의하면 기억해 다시 묻지 않는다', (
      tester,
    ) async {
      final store = tempStore();
      final answers = <bool>[];
      await tester.pumpWidget(asker(store, answers));
      await tester.tap(find.text('ask'));
      await tester.pumpAndSettle();
      expect(find.textContaining('DeepSeek'), findsWidgets);
      expect(find.textContaining('gym.darak.studio'), findsOneWidget);
      expect(find.text(l.aiConsentSent), findsOneWidget);
      expect(find.text(l.aiConsentLater), findsOneWidget);
      expect(find.byKey(const ValueKey('ai-consent-privacy')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ai-consent-agree')));
      await tester.pumpAndSettle();
      expect(answers, [true]);
      expect(store.aiConsent, isTrue);

      await tester.tap(find.text('ask'));
      await tester.pumpAndSettle();
      expect(find.text(l.aiConsentTitle), findsNothing, reason: '한 번만 묻는다');
      expect(answers, [true, true]);
    });

    testWidgets('나중에를 고르면 기억해 다시 묻지 않고, 설정에서 켤 때(again)만 다시 보여 준다', (
      tester,
    ) async {
      final store = tempStore();
      final answers = <bool>[];
      await tester.pumpWidget(asker(store, answers));
      await tester.tap(find.text('ask'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ai-consent-later')));
      await tester.pumpAndSettle();
      expect(answers, [false]);
      expect(store.aiConsent, isFalse);
      await tester.tap(find.text('ask'));
      await tester.pumpAndSettle();
      expect(find.text(l.aiConsentTitle), findsNothing);
      expect(answers, [false, false]);

      await tester.pumpWidget(asker(store, answers, again: true));
      await tester.tap(find.text('ask'));
      await tester.pumpAndSettle();
      expect(find.text(l.aiConsentTitle), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ai-consent-agree')));
      await tester.pumpAndSettle();
      expect(answers.last, isTrue);
      expect(store.aiConsent, isTrue);
    });

    testWidgets('고르지 않고 닫으면 이번만 끄고 기억하지 않는다 — 다음에 다시 묻는다', (tester) async {
      final store = tempStore();
      final answers = <bool>[];
      await tester.pumpWidget(asker(store, answers));
      await tester.tap(find.text('ask'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // 시트 바깥
      await tester.pumpAndSettle();
      expect(answers, [false]);
      expect(store.aiConsent, isNull);
    });

    test('고른 것은 설정 파일에 남는다', () async {
      final dir = Directory.systemTemp.createTempSync('setpad_ai_consent_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = NotesStore(directory: dir);
      await store.load();
      store.setAiConsent(false);
      await store.flush();
      final again = NotesStore(directory: dir);
      await again.load();
      expect(again.aiConsent, isFalse);
      store.dispose();
      again.dispose();
    });

    test('계정이 만드는 RecordAi 가 동의를 묻는 자리를 들고 간다', () {
      Future<bool> no() async => false;
      expect(Account(aiConsent: no).ai.consent, same(no));
    });
  });

  group('모델로 가는 문은 동의를 지난다 (RecordAi)', () {
    test('동의하지 않으면 한 줄 설정·기록 질문·오늘 루틴·식단 글·식단 사진 모두 아무것도 보내지 않는다', () async {
      final s = serverAi(() async => false);
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
      expect(s.asked, hasLength(5));
    });

    test('음식 표 조회와 수 없는 이름은 모델이 아니다 — 동의를 묻지 않는다', () async {
      final s = serverAi(() async => false);
      expect(await s.ai.isFood('김치찌개'), isFalse);
      expect(s.paths, contains('/api/foods/match'));
      final reading = await s.ai.interpret('벤치프레스', 'ko', const []);
      expect(reading.exercises.single.setup.name, '벤치프레스');
      expect(s.asked, isEmpty);
    });

    test('동의하면 그대로 보낸다', () async {
      final s = serverAi(() async => true);
      final estimate = await s.ai.estimateMealText('김밥 한 줄', locale: 'ko');
      expect(estimate.kcal, 480);
      expect(s.paths, ['/api/device', '/api/meals/estimate']);
    });
  });

  group('나중에여도 막다른 길은 없다', () {
    Future<void> submit(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(CupertinoTextField).last, text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    testWidgets('적기 도움(운동 입력 줄): 친 글 그대로 칸이 되고 AI 가 꺼졌다고 한 줄 말한다', (
      tester,
    ) async {
      var consent = false;
      final asked = <String>[];
      final ai = RecordAi(
        consent: () async => consent,
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
      await submit(tester, '벤치 80kg 5x5');
      expect(asked, isEmpty, reason: '모델에 아무것도 가지 않았다');
      expect(c.blocks.single.name, '벤치 80kg 5x5');
      expect(c.blocks.single.setup, isNull);
      expect(find.text(l.aiOff), findsOneWidget);

      // 켜면 같은 입력 줄이 모델을 쓴다.
      consent = true;
      c.closeBlock();
      await submit(tester, '스쿼트 100kg 3x5');
      expect(asked, hasLength(1));
    });

    testWidgets('식단 글: 친 글과 적은 kcal 은 그대로 남고, 열량을 안 적은 끼니는 AI 가 꺼졌다고 말한다', (
      tester,
    ) async {
      final store = tempStore();
      final note = store.create();
      final s = serverAi(() async => false);
      await tester.pumpWidget(
        app(EditorPage(store: store, note: note, ai: s.ai)),
      );
      await tester.pumpAndSettle();
      Future<void> write(String text) async {
        await tester.tap(find.byKey(const ValueKey('meal-text-toggle')));
        await tester.pumpAndSettle();
        await submit(tester, text);
      }

      await write('김밥 한 줄');
      expect(note.meals.single.text, '김밥 한 줄');
      expect(note.meals.single.kcal, isNull);
      expect(find.text(l.aiOff), findsOneWidget);

      await write('라면 500kcal');
      expect(note.meals.last.kcal, 500, reason: '적은 kcal 은 모델 없이 들어간다');
      expect(s.paths, isEmpty);
    });

    testWidgets('식단 사진: 사진을 고르기 전에 묻고, 꺼 두었으면 글로 적는 길을 말한다', (tester) async {
      final store = tempStore();
      final note = store.create();
      final s = serverAi(() async => false);
      await tester.pumpWidget(
        app(EditorPage(store: store, note: note, ai: s.ai)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CupertinoTextField).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.mealPhoto));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.mealCamera));
      await tester.pumpAndSettle();
      expect(s.asked, hasLength(1));
      expect(find.text(l.aiOffPhoto), findsOneWidget);
      expect(note.meals, isEmpty);
      expect(s.paths, isEmpty);
    });

    testWidgets('기록 질문: 아무것도 보내지 않고 AI 가 꺼졌다고 말한다 — 기기 안 목록은 그대로', (
      tester,
    ) async {
      final store = tempStore();
      final note = store.create();
      note.blocks.add(ExerciseBlock('벤치프레스', [LoggedSet(value: 80, reps: 5)]));
      final asked = <String>[];
      final ai = RecordAi(
        consent: () async => false,
        respond: (instructions, input) async {
          asked.add(input);
          return {'kind': 'unrelated'};
        },
      );
      await tester.pumpWidget(
        app(NotesListPage(store: store, onOpen: (_) {}, ai: ai)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(CupertinoSearchTextField), '벤치 최고 기록');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(asked, isEmpty);
      expect(find.text(l.aiOff), findsOneWidget);
      expect(find.text(l.queryPressEnter), findsNothing);
      expect(find.textContaining('벤치프레스'), findsWidgets, reason: '기기 안 목록');
    });

    testWidgets('설정의 AI 도움 줄: 켜면 무엇을 보내는지 보여 주고 묻고, 끄면 바로 꺼진다', (tester) async {
      final store = tempStore();
      store.setAiConsent(false);
      await tester.pumpWidget(app(SettingsPage(store: store)));
      await tester.pumpAndSettle();
      final toggle = find.descendant(
        of: find.byKey(const ValueKey('settings-ai')),
        matching: find.byType(CupertinoSwitch),
      );
      expect(tester.widget<CupertinoSwitch>(toggle).value, isFalse);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.textContaining('gym.darak.studio'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ai-consent-agree')));
      await tester.pumpAndSettle();
      expect(store.aiConsent, isTrue);
      expect(tester.widget<CupertinoSwitch>(toggle).value, isTrue);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(store.aiConsent, isFalse);
      expect(find.text(l.aiConsentTitle), findsNothing);
    });
  });
}
