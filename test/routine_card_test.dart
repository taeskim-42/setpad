import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/record_ai.dart';
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
