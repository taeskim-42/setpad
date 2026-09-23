import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart' show maxQuestionLength;
import 'package:setpad/routine.dart';
import 'package:setpad/routine_card.dart';

import 'routine_fixture.dart';

/// 기록을 손에 쥔 가게. 시작하면 새 기록이 목록 맨 앞에 든다.
class _Records extends NotesStore {
  _Records(this.records);
  final List<Note> records;
  final created = <Note>[];
  @override
  List<Note> get notes => records;
  @override
  Note create({
    List<ExerciseBlock>? blocks,
    String? gymId,
    String? routineId,
    String? id,
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    final note = Note(
      id: id ?? 'new${created.length}',
      createdAt: now,
      updatedAt: now,
      blocks: blocks,
      gymId: gymId,
      routineId: routineId,
    );
    records.insert(0, note);
    created.add(note);
    notifyListeners();
    return note;
  }
}

/// 고정 기록을 오늘 기준으로 옮긴다(화면은 지금 시각으로 짠다).
List<Note> relativeLog([List<Note>? log]) {
  final shift = DateTime.now().difference(routineToday);
  final days = Duration(days: shift.inDays);
  return [
    for (final n in log ?? defaultLog())
      Note(
        id: n.id,
        createdAt: n.createdAt.add(days),
        updatedAt: n.updatedAt.add(days),
        blocks: n.blocks,
        routineId: n.routineId,
      ),
  ];
}

/// 오늘 루틴 카드(설계 §12.1 카드 + 검토 G1·G14·G16·G18).
void main() {
  setUpAll(() => initializeDateFormatting());
  final l = lookupL(const Locale('ko'));
  final search = find.byType(CupertinoSearchTextField);

  Future<_Records> pump(
    WidgetTester tester, {
    RecordAi ai = const RecordAi(),
    List<Note>? records,
  }) async {
    final store = _Records(records ?? relativeLog());
    addTearDown(store.dispose);
    final opened = <Note>[];
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: NotesListPage(store: store, onOpen: opened.add, ai: ai),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> type(
    WidgetTester tester,
    String text, {
    bool enter = false,
  }) async {
    await tester.enterText(search, text);
    await tester.pumpAndSettle();
    if (enter) {
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }
  }

  Finder startButton() => find.widgetWithText(CupertinoButton, l.routineStart);

  testWidgets('맨 요청: 치는 동안 카드가 뜨고 모델은 부르지 않는다(원판 0)', (tester) async {
    var asked = 0;
    await pump(
      tester,
      ai: RecordAi(
        respond: (_, _) async {
          asked++;
          return {};
        },
      ),
    );
    await type(tester, '오늘 루틴 짜줘', enter: true);
    expect(find.text(l.routineHeaderToday), findsOneWidget);
    for (final name in ['스쿼트', '루마니안 데드리프트', '레그컬']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(find.text(l.routinePlatesZero), findsOneWidget);
    expect(asked, 0);
    // 친 글은 검색칸에 그대로 남는다.
    expect(
      tester.widget<CupertinoSearchTextField>(search).controller!.text,
      '오늘 루틴 짜줘',
    );
  });

  testWidgets('시작 → 새 기록 하나, 세트는 모두 안 한 것, 트레이너 표지 없음; 다시 눌러도 하나(G18)', (
    tester,
  ) async {
    final store = await pump(tester);
    await type(tester, '오늘 루틴 짜줘');
    await tester.tap(startButton());
    await tester.pumpAndSettle();
    expect(store.created, hasLength(1));
    final note = store.created.single;
    expect(note.routineId, isNull);
    expect(note.gymId, isNull);
    expect(note.blocks.map((b) => b.name), ['스쿼트', '루마니안 데드리프트', '레그컬']);
    expect(
      note.blocks
          .expand((b) => b.sets)
          .every((s) => !s.done && s.notes.isEmpty),
      isTrue,
    );
    await tester.tap(find.widgetWithText(CupertinoButton, l.routineStarted));
    await tester.pumpAndSettle();
    expect(store.created, hasLength(1));
  });

  testWidgets('✕ 는 앱이 돌아와도 풀리지 않고, 넣기로 되살린다(G18)', (tester) async {
    await pump(tester);
    await type(tester, '오늘 루틴 짜줘');
    await tester.tap(find.byIcon(CupertinoIcons.xmark).last);
    await tester.pumpAndSettle();
    expect(find.text('레그컬'), findsNothing);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(find.text('레그컬'), findsNothing);
    expect(
      find.text(l.routineRemoved('레그컬', l.routineRemovedWhy('user'))),
      findsOneWidget,
    );
    await tester.tap(find.text(l.routineRestore));
    await tester.pumpAndSettle();
    expect(find.text('레그컬'), findsOneWidget);
  });

  testWidgets('다른 루틴은 다음 순위의 날을 보인다', (tester) async {
    await pump(tester);
    await type(tester, '오늘 루틴 짜줘');
    await tester.tap(find.text(l.routineOther));
    await tester.pumpAndSettle();
    expect(find.text('루마니안 데드리프트'), findsNothing);
  });

  testWidgets('조건 요청: Enter 에 루틴 지시문으로 묻고, 읽은 조건과 원판 줄', (tester) async {
    String? instructions;
    await pump(
      tester,
      ai: RecordAi(
        respond: (i, _) async {
          instructions = i;
          return {
            'parts': ['legs'],
          };
        },
      ),
    );
    await type(tester, '하체로 짜줘');
    expect(find.text(l.routinePressEnter), findsOneWidget);
    expect(instructions, isNull);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(instructions, routineInstructions);
    expect(find.text('스쿼트'), findsOneWidget);
    expect(find.text('레그프레스'), findsOneWidget);
    // 서버가 답했으니 "원판 0장" 이 아니다.
    expect(find.text(l.routinePlatesZero), findsNothing);
  });

  testWidgets('루틴 지시문이 기록 질문이라 하면 칩으로 기록 검색에 넘긴다', (tester) async {
    final calls = <String>[];
    await pump(
      tester,
      ai: RecordAi(
        respond: (i, _) async {
          calls.add(i == routineInstructions ? 'routine' : 'v3');
          return i == routineInstructions
              ? {'kind': 'question'}
              : {
                  'exercises': ['스쿼트'],
                };
        },
      ),
    );
    await type(tester, '스쿼트 넣어서 짜줘', enter: true);
    expect(calls, ['routine']);
    await tester.tap(find.text(l.routineAsQuestion));
    await tester.pumpAndSettle();
    expect(calls, ['routine', 'v3']);
  });

  testWidgets('기록 검색이 루틴이라 하면 두 칩 — 조건 없이는 모델 없이 카드', (tester) async {
    final calls = <String>[];
    await pump(
      tester,
      ai: RecordAi(
        respond: (i, _) async {
          calls.add(i == routineInstructions ? 'routine' : 'v3');
          return {'kind': 'routine'};
        },
      ),
    );
    await type(tester, '등이랑 이두', enter: true);
    expect(calls, ['v3']);
    expect(find.text(l.routineFromQuestion), findsOneWidget);
    expect(find.text(l.routineWithConditions), findsOneWidget);
    await tester.tap(find.text(l.routineNoConditions));
    await tester.pumpAndSettle();
    expect(find.text(l.routineHeaderToday), findsOneWidget);
    expect(startButton(), findsOneWidget);
    expect(calls, ['v3']);
  });

  group('G1: 모델을 못 쓰면 빼기·아픈 곳 글로 [시작] 카드를 띄우지 않는다', () {
    final texts = ['어깨 아파서 어깨 빼고', '스쿼트 말고', '하체 근육통 심함 하체 빼줘'];
    final modes = <String, RecordAi>{
      '연결': RecordAi(respond: (_, _) async => throw Exception('offline')),
      '원판 없음': RecordAi(
        respond: (_, _) async =>
            throw const RecordAiException(RecordAiStatus.noPlates),
      ),
      '읽지 못함': RecordAi(respond: (_, _) async => {'series': []}),
    };
    for (final t in texts) {
      for (final m in modes.entries) {
        testWidgets('$t × ${m.key}', (tester) async {
          await pump(tester, ai: m.value);
          await type(tester, t, enter: true);
          expect(startButton(), findsNothing);
          expect(find.text(l.routineHeldBack), findsOneWidget);
          await tester.tap(find.text(l.routineNoConditions));
          await tester.pumpAndSettle();
          expect(startButton(), findsOneWidget);
        });
      }
    }

    testWidgets('빼기 낱말이 없으면 기기가 읽은 것으로 짜고 까닭을 말한다', (tester) async {
      await pump(
        tester,
        ai: RecordAi(respond: (_, _) async => throw Exception('offline')),
      );
      await type(tester, '하체로 짜줘', enter: true);
      expect(find.text(l.routineOffline), findsOneWidget);
      expect(find.text(l.routineRetry), findsOneWidget);
      expect(startButton(), findsOneWidget);
      expect(find.text('스쿼트'), findsOneWidget);
    });
  });

  testWidgets('G16: 명령 + 재활 명사는 모델 없이 거절, 카드 없음', (tester) async {
    var asked = 0;
    await pump(
      tester,
      ai: RecordAi(
        respond: (_, _) async {
          asked++;
          return {};
        },
      ),
    );
    await type(tester, '허리 디스크 재활 루틴 짜줘', enter: true);
    expect(find.text(l.routineRefused('medical')), findsOneWidget);
    expect(startButton(), findsNothing);
    expect(asked, 0);
  });

  testWidgets('G3: 모델이 의료 거절 + 부위를 내도 카드 없음', (tester) async {
    await pump(
      tester,
      ai: RecordAi(
        respond: (_, _) async => {
          'refused': {'medical': '무릎 수술'},
          'parts': ['legs'],
        },
      ),
    );
    await type(tester, '무릎 수술했는데 하체 좀 짜줘', enter: true);
    expect(startButton(), findsNothing);
    expect(find.text('스쿼트'), findsNothing);
  });

  testWidgets('G14: 내일 루틴은 미리 보기 — 시작 없음', (tester) async {
    await pump(tester);
    await type(tester, '내일 루틴 짜줘');
    expect(startButton(), findsNothing);
    expect(find.text(l.routineFuture), findsOneWidget);
  });

  testWidgets('이름만 친 글은 칩으로 바로(원판 0)', (tester) async {
    var asked = 0;
    await pump(
      tester,
      ai: RecordAi(
        respond: (_, _) async {
          asked++;
          return {};
        },
      ),
    );
    await type(tester, '하체 루틴');
    await tester.tap(find.text(l.routineMakePart(l.queryPart('legs'))));
    await tester.pumpAndSettle();
    expect(find.text('레그프레스'), findsOneWidget);
    expect(asked, 0);
  });

  group('검토#1 의료 글은 모델을 못 써도 [시작] 카드가 없다(원판 0)', () {
    final texts = [
      '재활 중인데 오늘 뭐 할까',
      '디스크 있는데 오늘 운동 뭐 하지',
      'knee surgery last month, what should I do today',
      '手術したばかりだけど今日のメニューは',
    ];
    final modes = <String, Future<Object?> Function()>{
      '연결': () async => throw Exception('offline'),
      '원판 없음': () async =>
          throw const RecordAiException(RecordAiStatus.noPlates),
      '읽지 못함': () async => {
        'refused': {'medical': '재활'},
        'note': 'x',
      },
    };
    for (final t in texts) {
      for (final m in modes.entries) {
        testWidgets('$t × ${m.key}', (tester) async {
          var asked = 0;
          await pump(
            tester,
            ai: RecordAi(
              respond: (_, _) {
                asked++;
                return m.value();
              },
            ),
          );
          await type(tester, t, enter: true);
          expect(startButton(), findsNothing);
          expect(find.text(l.routineRefused('medical')), findsOneWidget);
          expect(find.text(l.routineNoConditions), findsNothing);
          expect(asked, 0);
        });
      }
    }

    testWidgets('기록 검색이 루틴이라 한 의료 글도 조건 없이 짜는 칩이 없다', (tester) async {
      await pump(
        tester,
        ai: RecordAi(
          respond: (i, _) async => i == routineInstructions
              ? throw Exception('offline')
              : {'kind': 'routine'},
        ),
      );
      await type(tester, '무릎 수술 2주 됐는데 하체 해도 돼?', enter: true);
      expect(find.text(l.routineWithConditions), findsOneWidget);
      expect(find.text(l.routineNoConditions), findsNothing);
      await tester.tap(find.text(l.routineWithConditions));
      await tester.pumpAndSettle();
      expect(startButton(), findsNothing);
      expect(find.text(l.routineRefused('medical')), findsOneWidget);
      expect(find.text(l.routineNoConditions), findsNothing);
    });
  });

  group('검토#2·#15 모델이 깨진 답을 내면', () {
    testWidgets('형식만 되받아 적은 답 → 읽지 못함(조건 글이면 카드 없음), 다시 누르면 다시 묻는다', (
      tester,
    ) async {
      var asked = 0;
      await pump(
        tester,
        ai: RecordAi(
          respond: (_, _) async {
            asked++;
            return asked == 1
                ? {'type': 'json_object'}
                : {
                    'parts': ['legs'],
                    'exclude': ['스쿼트'],
                  };
          },
        ),
      );
      await type(tester, '스쿼트 말고 하체 짜줘', enter: true);
      expect(startButton(), findsNothing);
      expect(find.text(l.routineHeldBack), findsOneWidget);
      expect(find.text(l.routineRetry), findsOneWidget);
      await tester.showKeyboard(search);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(asked, 2);
      expect(startButton(), findsOneWidget);
      expect(find.text('스쿼트'), findsNothing);
    });

    testWidgets('조건 없는 글이면 기기 카드 + 읽지 못함 줄', (tester) async {
      await pump(
        tester,
        ai: RecordAi(respond: (_, _) async => {'type': 'json_object'}),
      );
      await type(tester, '하체로 짜줘', enter: true);
      expect(find.text(l.routineMisread), findsOneWidget);
      expect(find.text(l.routineOffline), findsNothing);
      expect(startButton(), findsOneWidget);
    });

    testWidgets('원판이 나간 깨진 답(502 upstream)은 연결 문구가 아니고, 다시 묻기는 한 번뿐', (
      tester,
    ) async {
      var asked = 0;
      await pump(
        tester,
        ai: RecordAi(
          respond: (_, _) async {
            asked++;
            throw const RecordAiException(
              RecordAiStatus.unavailable,
              code: 'upstream',
              charged: true,
            );
          },
        ),
      );
      await type(tester, '하체로 짜줘', enter: true);
      expect(asked, 1);
      expect(find.text(l.routineMisread), findsOneWidget);
      expect(find.text(l.routineOffline), findsNothing);
      expect(startButton(), findsOneWidget);
      await tester.tap(find.text(l.routineRetry));
      await tester.pumpAndSettle();
      expect(asked, 2);
      expect(find.text(l.routineRetry), findsNothing);
      await tester.showKeyboard(search);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(asked, 2);
      expect(find.text(l.routineMisread), findsOneWidget);
    });
  });

  test('검토#15 502 upstream 에 원판이 실려 오면 원판이 나간 실패다', () async {
    Future<RecordAiException> fail(Map<String, Object?> body) async {
      final ai = RecordAi(
        endpoint: 'https://example.com',
        deviceId: 'device',
        client: MockClient(
          (request) async => request.url.path == '/api/device'
              ? http.Response(jsonEncode({'token': 't'}), 200)
              : http.Response(jsonEncode(body), 502),
        ),
      );
      try {
        await ai.ask('i', 'q', contract: 3);
      } on RecordAiException catch (e) {
        return e;
      }
      throw StateError('no failure');
    }

    RecordAi.forget();
    final charged = await fail({
      'error': 'upstream',
      'plates': {'balance': 9.5, 'spent': 0.5},
    });
    expect(charged.charged, isTrue);
    expect(charged.code, 'upstream');
    RecordAi.forget();
    expect((await fail({'error': 'upstream'})).charged, isFalse);
    RecordAi.forget();
  });

  testWidgets('검토#3 루틴으로 가르는 글이어도 글자가 맞는 기록은 카드 아래에 보인다', (tester) async {
    await pump(tester);
    await type(tester, '타바타');
    expect(find.textContaining('버피 타바타'), findsWidgets);
    // 글자가 맞는 기록이 없으면 "결과 없음" 을 띄우지 않는다.
    await type(tester, '오늘 루틴 짜줘');
    expect(find.text(l.noSearchResults), findsNothing);
    expect(find.text(l.routineHeaderToday), findsOneWidget);
  });

  testWidgets('검토#5 두 모델이 서로 떠넘겨도 되풀이·막다른 길이 없다', (tester) async {
    final calls = <String>[];
    await pump(
      tester,
      ai: RecordAi(
        respond: (i, _) async {
          calls.add(i == routineInstructions ? 'routine' : 'v3');
          return i == routineInstructions
              ? {'kind': 'lookup'}
              : {'kind': 'routine'};
        },
      ),
    );
    await type(tester, '다음 운동 때 벤치 몇키로 치면 돼', enter: true);
    await tester.tap(find.text(l.routineWithConditions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.routineAsQuestion));
    await tester.pumpAndSettle();
    expect(calls, ['v3', 'routine']);
    // 기록 검색은 이 글을 셀 질문으로 못 읽었다 — 칩을 되풀이하지 않고 까닭과 원판 0 길.
    expect(find.text(l.routineWithConditions), findsNothing);
    expect(find.text(l.queryMisread), findsOneWidget);
    await tester.tap(find.text(l.routineNoConditions));
    await tester.pumpAndSettle();
    expect(startButton(), findsOneWidget);
    expect(calls, ['v3', 'routine']);
  });

  testWidgets('검토#6 이름만 칩으로 짠 뒤 Enter 는 모델 카드로 바뀌고 원판 줄이 맞다', (tester) async {
    var asked = 0;
    await pump(
      tester,
      ai: RecordAi(
        respond: (_, _) async {
          asked++;
          return {
            'parts': ['legs'],
            'exclude': ['레그프레스'],
          };
        },
      ),
    );
    await type(tester, '하체 루틴');
    await tester.tap(find.text(l.routineMakePart(l.queryPart('legs'))));
    await tester.pumpAndSettle();
    expect(find.text('레그프레스'), findsOneWidget);
    expect(find.text(l.routinePlatesZero), findsOneWidget);
    await tester.showKeyboard(search);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(asked, 1);
    expect(find.text('레그프레스'), findsNothing);
    expect(find.text(l.routinePlatesZero), findsNothing);
  });

  group('검토#10 실패 까닭을 연결로 뭉개지 않는다', () {
    testWidgets('600자 넘는 글은 모델에 보내지 않고 길이를 말한다 — 다시 시도 없음', (tester) async {
      var asked = 0;
      await pump(
        tester,
        ai: RecordAi(
          respond: (_, _) async {
            asked++;
            return {};
          },
        ),
      );
      await type(tester, '하체 루틴 짜줘 ${'가' * 600}', enter: true);
      expect(asked, 0);
      expect(find.text(l.queryTooLong(maxQuestionLength)), findsOneWidget);
      expect(find.text(l.routineOffline), findsNothing);
      expect(find.text(l.routineRetry), findsNothing);
      expect(find.text(l.routineNoConditions), findsOneWidget);
    });

    testWidgets('원판이 없으면 원판 문구', (tester) async {
      await pump(
        tester,
        ai: RecordAi(
          respond: (_, _) async =>
              throw const RecordAiException(RecordAiStatus.noPlates),
        ),
      );
      await type(tester, '하체로 짜줘', enter: true);
      expect(find.text(l.routineNoPlates), findsOneWidget);
      expect(find.text(l.routineOffline), findsNothing);
      expect(startButton(), findsOneWidget);
    });
  });

  testWidgets('검토#12 시작한 뒤 카드를 바꾸면 [시작] 이 다시 뜨고 새 기록을 만든다', (tester) async {
    final store = await pump(tester);
    await type(tester, '오늘 루틴 짜줘');
    await tester.tap(startButton());
    await tester.pumpAndSettle();
    expect(store.created, hasLength(1));
    await tester.tap(find.text(l.routineOther));
    await tester.pumpAndSettle();
    expect(startButton(), findsOneWidget);
    await tester.tap(startButton());
    await tester.pumpAndSettle();
    expect(store.created, hasLength(2));
    expect(
      store.created.last.blocks.map((b) => b.name),
      isNot(store.created.first.blocks.map((b) => b.name)),
    );
  });

  testWidgets('검토#14 "이것도 물을까요" 뒤에 루틴으로 돌아갈 수 있다(원판 0)', (tester) async {
    final calls = <String>[];
    await pump(
      tester,
      ai: RecordAi(
        respond: (i, _) async {
          calls.add(i == routineInstructions ? 'routine' : 'v3');
          return i == routineInstructions
              ? {
                  'parts': ['legs'],
                  'ask': '지난주 스쿼트 최고 보여주고',
                }
              : {
                  'exercises': ['스쿼트'],
                };
        },
      ),
    );
    const text = '지난주 스쿼트 최고 보여주고 오늘 하체 짜줘';
    await type(tester, text, enter: true);
    await tester.tap(find.text(l.routineAskToo('지난주 스쿼트 최고 보여주고')));
    await tester.pumpAndSettle();
    expect(calls, ['routine', 'v3']);
    expect(find.text(l.routineHeaderToday), findsNothing);
    await tester.tap(find.text(l.routineBack));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CupertinoSearchTextField>(search).controller!.text,
      text,
    );
    expect(find.text(l.routineHeaderToday), findsOneWidget);
    expect(calls, ['routine', 'v3']);
  });

  testWidgets('카드: 쌤이 보낸 루틴이 맨 위', (tester) async {
    Routine? tapped;
    final routine = (
      id: 'b',
      gymId: 'g',
      gym: 'OO짐',
      title: '하체 B',
      blocks: <ExerciseBlock>[],
    );
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: CupertinoPageScaffold(
          child: ListView(
            children: [
              RoutineCard(
                draft: composeRoutine(
                  defaultLog(),
                  const RoutineAsk(),
                  now: routineToday,
                ),
                trainer: [routine],
                onTrainer: (r) => tapped = r,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final trainerY = tester.getTopLeft(find.textContaining('하체 B')).dy;
    final headY = tester.getTopLeft(find.text(l.routineHeaderToday)).dy;
    expect(trainerY, lessThan(headY));
    await tester.tap(find.textContaining('하체 B'));
    expect(tapped?.id, 'b');
  });
}

typedef Routine = ({
  String id,
  String gymId,
  String gym,
  String title,
  List<ExerciseBlock> blocks,
});
