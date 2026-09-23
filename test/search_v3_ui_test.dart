import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/answer_card.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart';

class _Records extends NotesStore {
  _Records(this.records);
  final List<Note> records;
  @override
  List<Note> get notes => records;
}

/// 검색 v3 화면: 모델 plan 과 칩이 같은 실행기로 세고, 기록에 없는 운동도 줄이
/// 되며(적은 적 없음), 서버에 닿지 못해도 글에 적힌 운동은 기기에서 센다.
void main() {
  setUpAll(() => initializeDateFormatting());
  final l = lookupL(const Locale('ko'));
  LoggedSet set(double kg, int reps) => LoggedSet(value: kg, reps: reps);
  Note on(String id, int month, int day, List<ExerciseBlock> blocks) {
    final at = DateTime(2026, month, day, 19);
    return Note(id: id, createdAt: at, updatedAt: at, blocks: blocks);
  }

  // 벤치프레스만 적었다. 바벨로우는 한 번도 안 했다.
  final bench = [
    on('B1', 8, 4, [
      ExerciseBlock('벤치프레스', [set(80, 5), set(85, 3)]),
    ]),
    on('B2', 8, 18, [
      ExerciseBlock('벤치프레스', [set(82.5, 5)]),
    ]),
    on('B3', 9, 7, [
      ExerciseBlock('벤치프레스', [set(85, 5)]),
    ]),
  ];
  const question = '벤치프레스 vs 바벨로우 기록 비교';
  final table = find.byType(TableCard);
  Finder inTable(String text) =>
      find.descendant(of: table, matching: find.text(text));

  Future<void> pump(
    WidgetTester tester,
    RecordAi ai, {
    List<Note>? records,
  }) async {
    final store = _Records(records ?? bench);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: NotesListPage(store: store, onOpen: (_) {}, ai: ai),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> ask(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(CupertinoSearchTextField), text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  /// 두 줄 다 있고, 바벨로우 줄은 0·— 와 '적은 적 없음' 이다.
  void expectBothRows(WidgetTester tester) {
    expect(table, findsOneWidget);
    for (final text in ['벤치프레스', '바벨로우', '3일 기록', '0일 기록']) {
      expect(inTable(text), findsWidgets, reason: text);
    }
    expect(inTable('—'), findsNWidgets(2), reason: '바벨로우의 최고·마지막');
    expect(inTable(l.queryNeverMark), findsOneWidget, reason: '까닭은 한 번');
    expect(
      find.text(l.queryNeverRows('바벨로우')),
      findsOneWidget,
      reason: '표 위 한 줄',
    );
    expect(
      find.descendant(
        of: table,
        matching: find.text('운동한 날 · 차이 (바벨로우 − 벤치프레스): -3일 (-100%)'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  }

  group('벤치프레스 vs 바벨로우 — 바벨로우는 적은 적 없다', () {
    testWidgets('온라인: 사전 이름도 칩이 되고, 모델 plan 은 확인 뒤 두 줄을 다 보인다', (tester) async {
      var asked = 0;
      await pump(
        tester,
        RecordAi(
          respond: (i, _) async {
            // 1단계(갈래 고르기)는 세지 않는다 — 질문 하나에 plan 한 번.
            if (i == familyInstructions) return {'t': <String>[]};
            asked++;
            return {
              'exercises': ['벤치프레스', '바벨로우'],
            };
          },
        ),
      );
      await tester.enterText(find.byType(CupertinoSearchTextField), question);
      await tester.pumpAndSettle();
      // 치는 동안: 두 이름 모두 칩 줄에 잡히고, 안 적은 것은 먼저 말한다.
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == '벤치프레스 · 바벨로우'),
        findsOneWidget,
      );
      expect(find.text(l.queryNeverRows('바벨로우')), findsOneWidget);
      expect(asked, 0);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(asked, 1);
      expect(table, findsNothing, reason: '확인 전에는 답이 없다');
      expect(
        find.textContaining('2. 바벨로우 (${l.queryNeverMark}) · 전체 기간'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(SuggestionChip, l.confirmYes));
      await tester.pumpAndSettle();
      expectBothRows(tester);

      // 칩도 같은 실행기다 — 같은 표, 모델은 다시 안 부른다.
      await tester.tap(find.widgetWithText(SuggestionChip, l.queryCompareChip));
      await tester.pumpAndSettle();
      expectBothRows(tester);
      expect(find.textContaining(l.readAsConfirm), findsNothing);
      expect(asked, 1);
    });

    testWidgets('오프라인: 서버에 닿지 못하면 글의 두 운동을 기기에서 세고 그렇다고 말한다', (tester) async {
      RecordAi.forget();
      addTearDown(RecordAi.forget);
      await pump(
        tester,
        RecordAi(
          endpoint: 'https://example.test',
          deviceId: 'device',
          client: MockClient((_) async => throw http.ClientException('off')),
        ),
      );
      await ask(tester, question);
      expect(find.text(l.queryOfflineLocal), findsOneWidget);
      expect(find.text(l.queryOffline), findsNothing);
      expect(find.textContaining(l.readAsConfirm), findsNothing);
      expectBothRows(tester);
    });
  });

  testWidgets('안 적은 사전 운동 이름만 치면 모델 없이 적은 기록이 없다고 말하고, 칩은 0 을 센다', (
    tester,
  ) async {
    var asked = 0;
    await pump(
      tester,
      RecordAi(
        respond: (i, _) async {
          // 1단계(갈래 고르기)는 세지 않는다 — 질문 하나에 plan 한 번.
          if (i == familyInstructions) return {'t': <String>[]};
          asked++;
          return {'kind': 'unrelated'};
        },
      ),
    );
    await ask(tester, '힙쓰러스트');
    expect(asked, 0, reason: '이름만 쳤으면 물을 것이 없다 — 원판도 안 나간다');
    expect(find.text(l.queryNeverRows('힙쓰러스트')), findsOneWidget);
    await tester.tap(find.widgetWithText(SuggestionChip, l.metricSessions));
    await tester.pumpAndSettle();
    // 점 없는 수(0 으로 채운 칸)도 카드가 된다.
    final card = tester.widget<AnswerCard>(find.byType(AnswerCard));
    expect(card.answer.headline, '0일 기록');
    expect(find.byType(DotChart), findsNothing);
    expect(find.text(l.queryNeverRows('힙쓰러스트')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('G4 적은 적 없는 이름에 "혹시 ○○?" 칩 — 누르면 그 기록으로 다시 센다(모델 없이)', (
    tester,
  ) async {
    var asked = 0;
    await pump(
      tester,
      RecordAi(
        respond: (i, _) async {
          // 1단계(갈래 고르기)는 세지 않는다 — 질문 하나에 plan 한 번.
          if (i == familyInstructions) return {'t': <String>[]};
          asked++;
          return {
            'exercises': ['로우'],
            'measures': ['best'],
          };
        },
      ),
      records: [
        on('R1', 9, 1, [
          ExerciseBlock('덤벨로우', [set(30, 10)]),
        ]),
        on('R2', 9, 8, [
          ExerciseBlock('덤벨로우', [set(32.5, 8)]),
          ExerciseBlock('벤치프레스', [set(80, 5)]),
        ]),
      ],
    );
    await ask(tester, '로우 최고 얼마');
    expect(asked, 1);
    expect(find.textContaining('로우 (${l.queryNeverMark})'), findsOneWidget);
    final maybe = find.widgetWithText(SuggestionChip, l.queryMaybe('덤벨로우'));
    expect(maybe, findsOneWidget);
    await tester.tap(maybe);
    await tester.pumpAndSettle();
    // 이름만 사람이 골랐다 — 나머지는 모델이 읽은 것이라 확인은 그대로 묻는다.
    expect(find.textContaining(l.readAsConfirm), findsOneWidget);
    expect(find.byType(AnswerCard), findsNothing);
    await tester.tap(find.widgetWithText(SuggestionChip, l.confirmYes));
    await tester.pumpAndSettle();
    final card = tester.widget<AnswerCard>(find.byType(AnswerCard));
    expect(card.answer.exercise, '덤벨로우');
    expect(card.answer.headline, contains('32.5kg'));
    expect(asked, 1);
  });

  testWidgets('기록에 없는 것만 물으면 다시 시도가 아니라 무엇이 없는지 말한다', (tester) async {
    await pump(
      tester,
      RecordAi(
        respond: (_, _) async => {
          'notComputable': ['심박'],
        },
      ),
    );
    await ask(tester, '운동할 때 심박 어땠어');
    expect(find.textContaining(l.queryNcHeartRate), findsOneWidget);
    expect(find.textContaining(l.queryCanSee), findsOneWidget);
    expect(find.text(l.queryFailed), findsNothing);
  });

  testWidgets('G8 개수형 주별 차트는 0 인 주도 점으로 찍고 N주 중 M주 0 을 말한다', (tester) async {
    await pump(
      tester,
      RecordAi(
        respond: (_, _) async => {
          'exercises': ['벤치프레스'],
          'by': 'week',
          'measures': ['trainingDays'],
          'period': 'custom',
          'since': '2026-08-03',
          'until': '2026-08-30',
        },
      ),
    );
    await ask(tester, '벤치 매주 빠짐없이 했나');
    await tester.tap(find.widgetWithText(SuggestionChip, l.confirmYes));
    await tester.pumpAndSettle();
    final painter =
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.painter is DotChartPainter,
                  ),
                )
                .painter
            as DotChartPainter;
    expect(painter.points.map((p) => p.value), [1, 0, 1, 0]);
    expect(
      find.textContaining(l.queryZeroBuckets('week', 4, 2)),
      findsOneWidget,
    );
  });

  group('TableCard', () {
    Future<void> show(WidgetTester tester, Map<String, Object?> plan) async {
      final records = [
        ...bench,
        on('S1', 9, 9, [
          ExerciseBlock('스쿼트', [set(100, 5)]),
        ]),
      ];
      final q = RecordQuery.decode(plan, recordedExercises(records));
      final r = runPlan(q, records, l: l, unit: 'kg', confirmed: true)!;
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: CupertinoPageScaffold(
            child: SingleChildScrollView(
              child: TableCard(query: q, result: r),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    testWidgets('series 마다 측정이 다르면 묻지 않은 칸은 빈칸이다 — — 도 0 도 아니다', (
      tester,
    ) async {
      await show(tester, {
        'series': [
          {
            'exercises': ['벤치프레스'],
            'measures': ['best'],
          },
          {
            'exercises': ['스쿼트'],
            'measures': ['trainingDays'],
          },
        ],
      });
      expect(inTable('—'), findsNothing);
      expect(inTable('0일 기록'), findsNothing);
      expect(inTable('1일 기록'), findsOneWidget);
    });

    testWidgets('비중 칸은 % 로 선다', (tester) async {
      await show(tester, {
        'exercises': ['벤치프레스', '스쿼트'],
        'measures': ['setCount'],
        'relate': 'share',
      });
      expect(inTable(l.queryShare), findsOneWidget);
      expect(inTable('80%'), findsOneWidget, reason: '세트 4 ÷ 5');
      expect(inTable('20%'), findsOneWidget);
    });
  });

  // 모델이 쓴 plan 은 두 단계로 받았든, 담아 둔 답을 꺼냈든 "이렇게 읽었어요" 와
  // "맞아요" 뒤에만 숫자를 보인다 — 틀린 숫자보다 탭 한 번이 싸다.
  testWidgets('확인 안전망: 두 단계 답도, 담아 둔 답도 "맞아요" 전에는 숫자가 없다', (tester) async {
    var stageOne = 0, planCalls = 0;
    await pump(
      tester,
      RecordAi(
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
      ),
    );
    const question = '벤치프레스 최고 기록 얼마야';
    final yes = find.widgetWithText(SuggestionChip, l.confirmYes);
    void expectUnconfirmed() {
      expect(find.textContaining(l.readAsConfirm), findsOneWidget);
      expect(yes, findsOneWidget);
      expect(find.byType(AnswerCard), findsNothing);
      expect(table, findsNothing);
    }

    await ask(tester, question);
    expect((stageOne, planCalls), (1, 1));
    expectUnconfirmed();
    await tester.tap(yes);
    await tester.pumpAndSettle();
    expect(find.byType(AnswerCard), findsOneWidget);
    // 담아 둔 답: 글을 지웠다 다시 치면 모델에 안 가고 꺼낸다 — 그래도 다시 묻는다.
    await tester.enterText(find.byType(CupertinoSearchTextField), '');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoSearchTextField), question);
    await tester.pumpAndSettle();
    expect((stageOne, planCalls), (1, 1), reason: '담아 둔 답이다');
    expectUnconfirmed();
    // Enter 로 내도 담아 둔 답이다 — 원판도, 확인 없이 숫자도 없다.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect((stageOne, planCalls), (1, 1));
    expectUnconfirmed();
    await tester.tap(yes);
    await tester.pumpAndSettle();
    expect(find.byType(AnswerCard), findsOneWidget);
  });

  testWidgets(
    '모델이 두 번 다 읽을 수 없는 답을 내면(unreadable) 연결 문구가 아니라 그 까닭을 말하고, 다시 묻기는 1단계를 또 사지 않는다',
    (tester) async {
      var stageOne = 0, planCalls = 0;
      var broken = true;
      await pump(
        tester,
        RecordAi(
          respond: (i, _) async {
            if (i == familyInstructions) {
              stageOne++;
              return {
                't': ['rank'],
              };
            }
            planCalls++;
            if (broken) {
              throw const RecordAiException(
                RecordAiStatus.unavailable,
                code: 'unreadable',
              );
            }
            return {
              'exercises': ['벤치프레스'],
              'measures': ['best'],
            };
          },
        ),
      );
      await ask(tester, '벤치프레스 최고 기록 얼마야');
      expect(find.text(l.queryUnreadable), findsOneWidget);
      for (final other in [
        l.queryFailed,
        l.queryOffline,
        l.queryOfflineLocal,
        l.queryMisread,
      ]) {
        expect(find.text(other), findsNothing, reason: other);
      }
      expect(find.byType(AnswerCard), findsNothing);
      broken = false;
      await tester.tap(find.text(l.queryAskAgain));
      await tester.pumpAndSettle();
      expect((stageOne, planCalls), (1, 2), reason: '1단계 꼬리표는 담아 두었다');
      expect(find.text(l.queryUnreadable), findsNothing);
      // 다시 받은 답도 모델이 쓴 plan 이다 — 확인부터.
      expect(find.textContaining(l.readAsConfirm), findsOneWidget);
      expect(find.byType(AnswerCard), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
