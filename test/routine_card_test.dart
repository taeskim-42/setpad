import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/account.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart'
    show inWeightUnit, kgOf, routineFromRow, routineToRow;
import 'package:setpad/gym_page.dart' show GymRow;
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/partner.dart' show PartnerSession, PartnerState;
import 'package:setpad/query_cache.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart'
    show familyInstructions, maxQuestionLength;
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
    final now = at ?? clock?.call() ?? DateTime.now();
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

  String unit = 'kg';
  @override
  String get weightUnit => unit;

  /// 새 기록의 시각(없으면 지금).
  DateTime Function()? clock;

  final deleted = <Note>[];
  @override
  void delete(Note note) {
    records.remove(note);
    deleted.add(note);
    notifyListeners();
  }
}

/// 지운 기록을 되돌릴 수 있는 가게 — 목록의 '되돌리기' 띠가 뜬다.
class _UndoableRecords extends _Records {
  _UndoableRecords(super.records);
  Note? _undo;
  @override
  void delete(Note note) {
    _undo = note;
    super.delete(note);
  }

  @override
  Note? get undoableDelete => _undo;
  @override
  bool undoDelete() {
    final note = _undo;
    if (note == null) return false;
    _undo = null;
    deleted.remove(note);
    records.insert(0, note);
    notifyListeners();
    return true;
  }

  @override
  void forgetUndoableDelete() => _undo = null;
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
    DateTime? now,
    _Records? into,
    QueryCache? edits,
    Account? account,
    Locale locale = const Locale('ko'),
    DateTime Function()? clock,
  }) async {
    final store = into ?? _Records(records ?? defaultLog());
    if (into == null) addTearDown(store.dispose);
    final opened = <Note>[];
    await tester.pumpWidget(
      CupertinoApp(
        locale: locale,
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: NotesListPage(
          store: store,
          onOpen: opened.add,
          ai: ai,
          // 요일 규칙이 있어 시계를 못 박는다 — 기준일 9/9(수) 18시.
          now: clock ?? () => now ?? routineToday,
          routineEdits: edits,
          account: account,
        ),
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

  testWidgets(
    'a muscle growth wish creates and starts a routine from recorded exercises',
    (tester) async {
      final calls = <String>[];
      final store = await pump(
        tester,
        records: defaultLog(),
        ai: RecordAi(
          respond: (instructions, input) async {
            calls.add(instructions);
            return instructions == routineInstructions
                ? {
                    'exercises': ['랫풀다운', '풀업'],
                  }
                : {'kind': 'unrelated'};
          },
        ),
      );
      await type(tester, '나는 대원근을 키우고 싶음.', enter: true);
      expect(calls, [routineInstructions]);
      expect(find.text(l.queryUnsupported), findsNothing);
      expect(find.byType(RoutineCard), findsOneWidget);
      expect(find.text('랫풀다운'), findsOneWidget);
      expect(find.text('풀업'), findsOneWidget);
      await tester.ensureVisible(startButton());
      await tester.tap(startButton());
      await tester.pumpAndSettle();
      expect(store.created, hasLength(1));
      expect(store.created.single.blocks.map((block) => block.name), [
        '랫풀다운',
        '풀업',
      ]);
      expect(
        store.created.single.blocks
            .expand((block) => block.sets)
            .every((set) => !set.done),
        isTrue,
      );
    },
  );

  testWidgets(
    'a growth goal without history starts after selecting an exercise',
    (tester) async {
      final store = await pump(
        tester,
        records: [],
        ai: RecordAi(
          respond: (instructions, _) async =>
              instructions == routineInstructions
              ? {
                  'exercises': ['랫풀다운', '풀업'],
                }
              : {'kind': 'unrelated'},
        ),
      );
      await type(tester, '나는 대원근을 키우고 싶음.', enter: true);
      expect(find.byType(RoutineCard), findsOneWidget);
      expect(find.text(l.queryUnsupported), findsNothing);
      final add = find.text(l.routineAdd('랫풀다운'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.ensureVisible(startButton());
      await tester.tap(startButton());
      await tester.pumpAndSettle();
      expect(store.created, hasLength(1));
      expect(store.created.single.blocks.single.name, '랫풀다운');
      expect(
        store.created.single.blocks.single.sets.every(
          (set) => !set.done && set.value == null && set.reps == null,
        ),
        isTrue,
      );
    },
  );

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
    // 기기가 짠 카드는 원판 줄이 없다 — '원판 0장' 은 읽을 것이 없어 뺐다.
    expect(find.text(l.routinePlatesZero), findsNothing);
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

  test('카드 고침은 파일에 남는다 — 새로 연 저장소가 그대로 읽는다', () async {
    final dir = Directory.systemTemp.createTempSync('routine_edits');
    addTearDown(() => dir.deleteSync(recursive: true));
    final e = RoutineEdits()
      ..removed.add('2026-09-02|레그컬')
      ..restored.add('스쿼트')
      ..added.add('플랭크')
      ..alt = 2
      ..mode = 'strength'
      ..started = 'n1'
      ..startedMark = '[["스쿼트"]]';
    final a = QueryCache(directory: dir, fileName: 'routine_edits.json');
    a.put('k', e.toJson());
    await a.flush();
    final b = QueryCache(directory: dir, fileName: 'routine_edits.json');
    await b.load();
    final back = RoutineEdits.fromJson(b['k']);
    expect(back.toJson(), e.toJson());
    expect(back.isEmpty, isFalse);
    expect(RoutineEdits.fromJson({'alt': 'x', 'removed': 3}).isEmpty, isTrue);
    // 기록 검색의 담은 답과 다른 파일이다.
    expect(File('${dir.path}/queries.json').existsSync(), isFalse);
  });

  testWidgets('앱을 다시 켜도 시작한 카드는 "시작함 · 열기" — 새 기록을 또 만들지 않는다', (tester) async {
    final edits = QueryCache(
      directory: Directory.systemTemp.createTempSync('routine_edits'),
      fileName: 'routine_edits.json',
    );
    final store = await pump(tester, edits: edits);
    await type(tester, '오늘 루틴 짜줘');
    await tester.tap(find.byIcon(CupertinoIcons.xmark).last);
    await tester.pumpAndSettle();
    await tester.tap(startButton());
    await tester.pumpAndSettle();
    expect(store.created, hasLength(1));
    // 화면을 통째로 내렸다가(앱 종료) 같은 저장소로 다시 연다.
    await tester.pumpWidget(const SizedBox());
    await pump(tester, into: store, edits: edits);
    await type(tester, '오늘 루틴 짜줘');
    expect(find.text('레그컬'), findsNothing);
    await tester.tap(find.widgetWithText(CupertinoButton, l.routineStarted));
    await tester.pumpAndSettle();
    expect(store.created, hasLength(1));
  });

  testWidgets('홈의 "오늘 루틴" 줄: 글을 치지 않고 기기 카드(원판 0), 검색칸에 쓰지 않는다', (
    tester,
  ) async {
    final calls = <String>[];
    final store = await pump(
      tester,
      ai: RecordAi(
        respond: (i, _) async {
          calls.add(i);
          return {};
        },
      ),
    );
    final row = find.widgetWithText(GymRow, l.routineHeaderToday);
    expect(row, findsOneWidget);
    // 9/9 수요일 = 지속력.
    expect(
      find.text(l.routineWeekdayFactor(l.weekdayLabel(routineToday), '지속력')),
      findsOneWidget,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(row, findsNothing);
    expect(startButton(), findsOneWidget);
    expect(find.text('루마니안 데드리프트'), findsOneWidget);
    expect(
      tester.widget<CupertinoSearchTextField>(search).controller!.text,
      isEmpty,
    );
    expect(calls, isEmpty);
    await tester.tap(startButton());
    await tester.pumpAndSettle();
    expect(store.created, hasLength(1));
    // 닫으면 줄로 돌아간다.
    await tester.tap(find.text(l.routineClose));
    await tester.pumpAndSettle();
    expect(row, findsOneWidget);
    expect(startButton(), findsNothing);
  });

  testWidgets('기록이 하나도 없어도 빈 목록에 "오늘 루틴 만들기" 칩과 줄', (tester) async {
    await pump(tester, records: []);
    expect(find.widgetWithText(GymRow, l.routineHeaderToday), findsOneWidget);
    await tester.tap(find.text(l.routineMake));
    await tester.pumpAndSettle();
    expect(find.text(l.routineHeaderToday), findsOneWidget);
    expect(find.text(l.routineClose), findsOneWidget);
    // 첫 주 기본 루틴: 수요일 = 지속력, 숫자 없이 [시작] 할 수 있다.
    expect(find.text(l.routineFirstPlan('지속력')), findsOneWidget);
    expect(find.text('레그프레스'), findsOneWidget);
    expect(startButton(), findsOneWidget);
  });

  testWidgets('바꾸기: 시트에서 고르면 그 운동의 내 세트로 바뀌고, 다시 켜도 남는다', (tester) async {
    final edits = QueryCache(
      directory: Directory.systemTemp.createTempSync('routine_edits'),
      fileName: 'routine_edits.json',
    );
    final store = await pump(tester, edits: edits);
    await type(tester, '오늘 루틴 짜줘');
    await tester.tap(find.text(l.routineSwap).last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('레그프레스 · '));
    await tester.pumpAndSettle();
    expect(find.text('레그컬'), findsNothing);
    expect(find.text('레그프레스'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await pump(tester, into: store, edits: edits);
    await type(tester, '오늘 루틴 짜줘');
    expect(find.text('레그프레스'), findsOneWidget);
    expect(find.text('레그컬'), findsNothing);
  });

  group('시작한 뒤 카드에서 고치면 시작한 기록에 옮긴다(검토 #6)', () {
    Finder started() => find.widgetWithText(CupertinoButton, l.routineStarted);

    testWidgets('✕ 는 기록에서 그 칸을 빼고, 바꾸기는 그 자리에 새 칸 — 기록은 하나, 시작함 그대로', (
      tester,
    ) async {
      final store = await pump(tester);
      await type(tester, '오늘 루틴 짜줘');
      await tester.tap(startButton());
      await tester.pumpAndSettle();
      final note = store.created.single;
      await tester.tap(find.text(l.routineSwap).last);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('레그프레스 · '));
      await tester.pumpAndSettle();
      expect(note.blocks.map((b) => b.name), ['스쿼트', '루마니안 데드리프트', '레그프레스']);
      expect(note.blocks.last.sets.every((s) => !s.done), isTrue);
      expect(started(), findsOneWidget);
      await tester.tap(find.byIcon(CupertinoIcons.xmark).at(1));
      await tester.pumpAndSettle();
      expect(note.blocks.map((b) => b.name), ['스쿼트', '레그프레스']);
      expect(started(), findsOneWidget);
      // 넣기로 되살리면 기록 끝에 붙는다.
      await tester.tap(find.text(l.routineRestore));
      await tester.pumpAndSettle();
      expect(note.blocks.map((b) => b.name), ['스쿼트', '레그프레스', '루마니안 데드리프트']);
      expect(store.created, hasLength(1));
      await tester.tap(started());
      await tester.pumpAndSettle();
      expect(store.created, hasLength(1));
    });

    testWidgets('적은 세트가 있는 칸은 ✕ 로도 기록에서 지우지 않는다', (tester) async {
      final store = await pump(tester);
      await type(tester, '오늘 루틴 짜줘');
      await tester.tap(startButton());
      await tester.pumpAndSettle();
      final note = store.created.single;
      note.blocks.last.sets.first.done = true;
      await tester.tap(find.byIcon(CupertinoIcons.xmark).last);
      await tester.pumpAndSettle();
      expect(note.blocks.map((b) => b.name), contains('레그컬'));
    });

    testWidgets('같이 하는 사람이 적은 세트가 있는 칸도 ✕ 로 기록에서 지우지 않는다', (tester) async {
      final store = await pump(tester);
      await type(tester, '오늘 루틴 짜줘');
      await tester.tap(startButton());
      await tester.pumpAndSettle();
      final note = store.created.single;
      note.blocks.last.sets.first.author = '준';
      expect(note.blocks.last.sets.first.done, isFalse);
      await tester.tap(find.byIcon(CupertinoIcons.xmark).last);
      await tester.pumpAndSettle();
      expect(note.blocks.map((b) => b.name), contains('레그컬'));
    });

    testWidgets('시작 취소: ○ 뿐이면 바로 지우고 [시작] 으로', (tester) async {
      final store = await pump(tester);
      await type(tester, '오늘 루틴 짜줘');
      await tester.tap(startButton());
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.routineUnstart));
      await tester.pumpAndSettle();
      expect(store.deleted, store.created);
      expect(startButton(), findsOneWidget);
      expect(find.text(l.routineUnstart), findsNothing);
    });

    testWidgets('시작 취소: 적은 세트가 있으면 묻고, 취소하면 그대로', (tester) async {
      final store = await pump(tester);
      await type(tester, '오늘 루틴 짜줘');
      await tester.tap(startButton());
      await tester.pumpAndSettle();
      store.created.single.blocks.first.sets.first.done = true;
      await tester.tap(find.text(l.routineUnstart));
      await tester.pumpAndSettle();
      expect(find.text(l.routineUnstartAsk), findsOneWidget);
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(store.deleted, isEmpty);
      expect(started(), findsOneWidget);
      await tester.tap(find.text(l.routineUnstart));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.delete));
      await tester.pumpAndSettle();
      expect(store.deleted, hasLength(1));
      expect(startButton(), findsOneWidget);
    });

    testWidgets('시작 취소: 같이 하는 사람이 적은 세트가 있어도 묻는다', (tester) async {
      final store = await pump(tester);
      await type(tester, '오늘 루틴 짜줘');
      await tester.tap(startButton());
      await tester.pumpAndSettle();
      store.created.single.blocks.first.sets.first.author = '준';
      await tester.tap(find.text(l.routineUnstart));
      await tester.pumpAndSettle();
      expect(find.text(l.routineUnstartAsk), findsOneWidget);
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(store.deleted, isEmpty);
    });

    testWidgets('시작 취소를 되돌리면 그 기록이 돌아오고 카드도 다시 시작함 — 기록은 하나', (tester) async {
      final store = _UndoableRecords(defaultLog());
      addTearDown(store.dispose);
      await pump(tester, into: store);
      await type(tester, '오늘 루틴 짜줘');
      await tester.tap(startButton());
      await tester.pumpAndSettle();
      final note = store.created.single;
      await tester.tap(find.text(l.routineUnstart));
      await tester.pumpAndSettle();
      expect(startButton(), findsOneWidget);
      await tester.tap(find.text(l.undo));
      await tester.pumpAndSettle();
      expect(store.records, contains(note));
      expect(started(), findsOneWidget);
      await tester.tap(started());
      await tester.pumpAndSettle();
      expect(store.created, hasLength(1));
    });

    testWidgets('시작 취소: 끼니·출석이 든 기록은 지우지 않고 안 한 칸만 걷는다 — 묻지도 지우지도 않는다', (
      tester,
    ) async {
      final store = await pump(tester);
      await type(tester, '오늘 루틴 짜줘');
      await tester.tap(startButton());
      await tester.pumpAndSettle();
      final note = store.created.single;
      // 연필(오늘 기록)로 아침 끼니를 적고 스티커를 댔다.
      note.meals.add(MealEntry(at: routineToday, kcal: 500, text: '아침'));
      note.gymId = 'g1';
      note.blocks.first.sets.first.done = true;
      await tester.tap(find.text(l.routineUnstart));
      await tester.pumpAndSettle();
      expect(find.text(l.routineUnstartAsk), findsNothing);
      expect(store.deleted, isEmpty);
      expect(store.records, contains(note));
      expect(note.meals, hasLength(1));
      expect(note.gymId, 'g1');
      // 적은 세트가 있는 칸만 남는다.
      expect(note.blocks.map((b) => b.name), ['스쿼트']);
      expect(startButton(), findsOneWidget);
    });

    testWidgets('앱을 켠 채 자정을 넘기면 어제 시작해 다 한 기록은 오늘 카드의 기록에 든다 — 새로 켠 것과 같다', (
      tester,
    ) async {
      var clock = routineToday;
      final store = _Records(defaultLog())..clock = () => clock;
      addTearDown(store.dispose);
      await pump(tester, into: store, clock: () => clock);
      await type(tester, '오늘 루틴 짜줘');
      await tester.tap(startButton());
      await tester.pumpAndSettle();
      for (final b in store.created.single.blocks) {
        for (final s in b.sets) {
          s.done = true;
        }
      }
      clock = DateTime(2026, 9, 10, 8);
      await type(tester, '');
      await type(tester, '오늘 루틴 짜줘');
      expect(started(), findsNothing);
      expect(startButton(), findsOneWidget);
      List<String> shown() => [
        for (final t in tester.widgetList<Text>(find.byType(Text)))
          if (t.data != null) t.data!,
      ];
      final alive = shown();
      await tester.pumpWidget(const SizedBox());
      await pump(tester, into: store, clock: () => clock);
      await type(tester, '오늘 루틴 짜줘');
      expect(alive, shown());
    });

    testWidgets('홈 "오늘 루틴" 줄로 시작한 뒤 "오늘 루틴 짜줘" 를 쳐도 시작함 — 기록은 하나', (
      tester,
    ) async {
      final store = await pump(tester);
      await tester.tap(find.widgetWithText(GymRow, l.routineHeaderToday));
      await tester.pumpAndSettle();
      await tester.tap(startButton());
      await tester.pumpAndSettle();
      await type(tester, '오늘 루틴 짜줘');
      expect(startButton(), findsNothing);
      expect(started(), findsOneWidget);
      await tester.tap(started());
      await tester.pumpAndSettle();
      expect(store.created, hasLength(1));
      // 다른 날을 짜는 맨 요청은 그 기록을 가져가지 않는다.
      await type(tester, '내일 루틴 짜줘');
      expect(started(), findsNothing);
    });

    testWidgets('320pt·글자 2배에서도 시작 줄이 넘치지 않고 시작 취소를 누를 수 있다', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 568 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final store = _Records(defaultLog());
      addTearDown(store.dispose);
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(
              c,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: NotesListPage(
            store: store,
            onOpen: (_) {},
            now: () => routineToday,
            routineEdits: QueryCache(fileName: 'layout_320.json'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(GymRow, l.routineHeaderToday));
      await tester.pumpAndSettle();
      // 카드가 화면보다 길다 — 단추를 직접 누른다.
      void press(Finder f) => tester
          .widget<CupertinoButton>(
            find.ancestor(of: f, matching: find.byType(CupertinoButton)).first,
          )
          .onPressed!();
      press(find.text(l.routineStart));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text(l.routineUnstart)).right,
        lessThanOrEqualTo(320),
      );
      press(find.text(l.routineUnstart));
      await tester.pumpAndSettle();
      expect(store.deleted, hasLength(1));
    });
  });

  group('쌤 루틴(검토 #10·#17)', () {
    final row = {
      'id': 'r1',
      'gym_id': 'g1',
      'gym': 'OO짐',
      'title': '하체 B',
      'items': [
        {
          'name': '스쿼트',
          'sets': [
            {'kg': 60, 'reps': 5},
            {'kg': 60, 'reps': 5},
          ],
          'setup': {'name': '스쿼트', 'weight': 60, 'unit': 'kg', 'totalSets': 2},
        },
      ],
    };

    test('lb 로 적는 사람에게는 lb 로 — 올릴 때 kgOf 가 같은 kg 로 되돌린다', () {
      final r = routineFromRow(row);
      expect(inWeightUnit(r.blocks, 'kg'), same(r.blocks));
      final b = inWeightUnit(r.blocks, 'lb').single;
      expect(b.sets.map((s) => (s.value, s.unit, s.reps, s.done)), [
        (132.28, 'lb', 5, false),
        (132.28, 'lb', 5, false),
      ]);
      expect((b.setup?.weight, b.setup?.unit), (132.28, 'lb'));
      expect(kgOf(b.sets.first), 60);
      // 남겼다 읽어도 같은 루틴.
      final back = routineFromRow(routineToRow(r));
      expect(
        (back.id, back.gymId, back.gym, back.title),
        ('r1', 'g1', 'OO짐', '하체 B'),
      );
      expect(back.blocks.single.sets.map((s) => (s.value, s.reps)), [
        (60.0, 5),
        (60.0, 5),
      ]);
      expect(back.blocks.single.setup?.totalSets, 2);
    });

    testWidgets('받은 쌤 루틴은 남겨 두었다가 다음에 못 받아도 보이고, 누르면 내 단위로', (tester) async {
      final dir = Directory.systemTemp.createTempSync('routine_trainer');
      final edits = QueryCache(directory: dir, fileName: 'routine_edits.json');
      Account account({required bool online}) =>
          Account(
              storageDir: dir,
              client: MockClient((request) async {
                if (request.url.path == '/api/routines') {
                  return online
                      ? http.Response.bytes(
                          utf8.encode(
                            jsonEncode({
                              'routines': [row],
                            }),
                          ),
                          200,
                        )
                      : http.Response('', 503);
                }
                if (request.url.path == '/api/gyms') {
                  return http.Response(
                    jsonEncode({'gyms': [], 'invites': []}),
                    200,
                  );
                }
                return http.Response('{}', 200);
              }),
            )
            ..token = 'x'
            ..userId = 'u1';
      final store = await pump(
        tester,
        edits: edits,
        account: account(online: true),
      );
      expect(find.text('하체 B'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await pump(
        tester,
        into: store,
        edits: edits,
        account: account(online: false),
      );
      expect(find.text('하체 B'), findsOneWidget);
      store.unit = 'lb';
      await tester.tap(find.text('하체 B'));
      await tester.pumpAndSettle();
      final sets = store.created.single.blocks.single.sets;
      expect(sets.map((s) => (s.value, s.unit)).toSet(), {(132.28, 'lb')});
      // 다른 계정에는 보이지 않는다.
      await tester.pumpWidget(const SizedBox());
      await pump(
        tester,
        into: _Records([]),
        edits: edits,
        account: account(online: false)..userId = 'u2',
      );
      expect(find.text('하체 B'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1)); // 저장·재시도 타이머
    });

    testWidgets('받는 사이 계정이 바뀌면 늦게 온 목록은 보이지도 새 계정 열쇠로 남지도 않는다', (tester) async {
      final dir = Directory.systemTemp.createTempSync('routine_switch');
      final edits = QueryCache(directory: dir, fileName: 'routine_edits.json');
      final reply = Completer<http.Response>();
      final account =
          Account(
              storageDir: dir,
              client: MockClient((request) async {
                if (request.url.path == '/api/routines') return reply.future;
                if (request.url.path == '/api/gyms') {
                  return http.Response(
                    jsonEncode({'gyms': [], 'invites': []}),
                    200,
                  );
                }
                return http.Response('{}', 200);
              }),
            )
            ..token = 'x'
            ..userId = 'u1';
      await pump(tester, edits: edits, account: account);
      account.userId = 'u2';
      reply.complete(
        http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'routines': [row],
            }),
          ),
          200,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('하체 B'), findsNothing);
      expect(edits[jsonEncode(['t1', 'u2'])], isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
    });
  });

  testWidgets('홈 맨 위 줄: 같이 운동 중 → 쌤 루틴 → 오늘 루틴 → 초대(나머지는 그대로)', (tester) async {
    final dir = Directory.systemTemp.createTempSync('home_rows');
    addTearDown(() => dir.deleteSync(recursive: true));
    final account =
        Account(
            storageDir: dir,
            client: MockClient((request) async {
              final body = switch (request.url.path) {
                '/api/routines' => {
                  'routines': [
                    {
                      'id': 'r1',
                      'gym_id': 'g1',
                      'gym': 'OO짐',
                      'title': '하체 B',
                      'items': [
                        {
                          'name': '스쿼트',
                          'sets': [
                            {'kg': 60, 'reps': 5},
                          ],
                        },
                      ],
                    },
                  ],
                },
                '/api/gyms' => {
                  'gyms': [],
                  'invites': [
                    {'gymId': 'g2', 'gymName': 'XX짐', 'verified': true},
                  ],
                },
                _ => {},
              };
              return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
            }),
          )
          ..token = 'x'
          ..userId = 'u1';
    // '함께 운동 중' 줄은 12시간 안에 고친 기록만 — 지금 고친 것.
    final live =
        Note(id: 'live', createdAt: routineToday, updatedAt: DateTime.now())
          ..partner = PartnerSession(
            id: 'S1',
            host: true,
            state: PartnerState.active,
            partnerName: '준',
          );
    await pump(
      tester,
      records: [live, ...defaultLog()],
      account: account,
      edits: QueryCache(directory: dir, fileName: 'routine_edits.json'),
    );
    final tops = [
      find.descendant(
        of: find.byKey(const ValueKey('partner-live-live')),
        matching: find.byType(GymRow),
      ),
      find.text('하체 B'),
      find.widgetWithText(GymRow, l.routineHeaderToday),
      find.text(l.inviteFrom('XX짐')),
    ].map((f) => tester.getTopLeft(f).dy).toList();
    expect(tops, [...tops]..sort());
    expect(tops.toSet(), hasLength(4));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1)); // 저장·재시도 타이머
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
          // 기록 검색 1단계(갈래 고르기)는 같은 질문의 앞 부름이다 — 세지 않는다.
          if (i == familyInstructions) return {'t': <String>[]};
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
          if (i == familyInstructions) return {'t': <String>[]};
          calls.add(i == routineInstructions ? 'routine' : 'v3');
          return {'kind': 'routine'};
        },
      ),
    );
    await type(tester, '등이랑 이두', enter: true);
    expect(calls, ['v3']);
    expect(find.text(l.routineFromQuestion), findsOneWidget);
    expect(find.text(l.routineWithConditions), findsOneWidget);
    // 원판은 칩 라벨이 아니라 한 줄로.
    expect(l.routineWithConditions, isNot(contains('원판')));
    expect(
      find.text(l.routinePlateCost(l.routineWithConditions)),
      findsOneWidget,
    );
    await tester.tap(find.text(l.routineNoConditions));
    await tester.pumpAndSettle();
    expect(find.text(l.routineHeaderToday), findsOneWidget);
    expect(startButton(), findsOneWidget);
    expect(calls, ['v3']);
  });

  group('G1: 모델을 못 쓰면 빼기·아픈 곳 글로 [시작] 카드를 띄우지 않는다', () {
    // 이름을 댄 뺄 운동("스쿼트 말고")은 기기가 읽는다(아래) — 여기는 이름 없는 빼기.
    final texts = ['어깨 아파서 어깨 빼고', '무릎 쓰는 거 말고', '하체 근육통 심함 하체 빼줘'];
    // 검토#10 까닭마다 제 말: 연결 · 원판 없음 · 답을 읽지 못함.
    final modes = <String, (RecordAi, String)>{
      '연결': (
        RecordAi(respond: (_, _) async => throw Exception('offline')),
        'offline',
      ),
      '원판 없음': (
        RecordAi(
          respond: (_, _) async =>
              throw const RecordAiException(RecordAiStatus.noPlates),
        ),
        'noPlates',
      ),
      '읽지 못함': (RecordAi(respond: (_, _) async => {'series': []}), 'misread'),
    };
    for (final t in texts) {
      for (final m in modes.entries) {
        testWidgets('$t × ${m.key}', (tester) async {
          await pump(tester, ai: m.value.$1);
          await type(tester, t, enter: true);
          expect(startButton(), findsNothing);
          expect(find.text(l.routineHeldBack(m.value.$2)), findsOneWidget);
          for (final other in modes.values.where((o) => o != m.value)) {
            expect(find.text(l.routineHeldBack(other.$2)), findsNothing);
          }
          await tester.tap(find.text(l.routineNoConditions));
          await tester.pumpAndSettle();
          expect(startButton(), findsOneWidget);
        });
      }
    }

    testWidgets('뺄 운동 이름만 있으면 기기가 빼고 짠다 — "조건 없이" 가 스쿼트를 넣지 않는다', (
      tester,
    ) async {
      await pump(
        tester,
        ai: RecordAi(respond: (_, _) async => throw Exception('offline')),
      );
      await type(tester, '스쿼트 말고 하체 짜줘', enter: true);
      expect(startButton(), findsOneWidget);
      expect(find.text(l.routineDeviceExcluded('스쿼트')), findsOneWidget);
      expect(find.text(l.routineOffline), findsOneWidget);
      expect(find.text('스쿼트'), findsNothing);
      expect(
        find.text(l.routineRemoved('스쿼트', l.routineRemovedWhy('named'))),
        findsOneWidget,
      );
      expect(find.text('레그프레스'), findsOneWidget);
    });

    testWidgets('영어 화면: 기기가 읽은 뺄 운동은 화면 언어 이름으로', (tester) async {
      final en = lookupL(const Locale('en'));
      await pump(
        tester,
        locale: const Locale('en'),
        ai: RecordAi(respond: (_, _) async => throw Exception('offline')),
      );
      await type(tester, 'leg routine without deadlift', enter: true);
      expect(find.text(en.routineDeviceExcluded('Deadlift')), findsOneWidget);
      expect(find.textContaining('데드리프트'), findsNothing);
    });

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

    testWidgets('AI 도움을 꺼 두었으면 아무것도 보내지 않고 기기가 짜며, 연결 탓이라 하지 않는다', (
      tester,
    ) async {
      final sent = <String>[];
      final ai = RecordAi(
        enabled: () => false,
        respond: (_, input) async {
          sent.add(input);
          return {};
        },
      );
      await pump(tester, ai: ai);
      await type(tester, '하체로 짜줘', enter: true);
      expect(sent, isEmpty);
      expect(find.text(l.aiOff), findsOneWidget);
      expect(find.text(l.routineOffline), findsNothing);
      expect(find.text(l.routineRetry), findsNothing, reason: '다시 눌러도 같다');
      expect(startButton(), findsOneWidget);
      // 이름 없는 빼기 글은 기기가 조건을 못 읽으니 [시작] 없이 까닭과 조건 없이
      // 짜기만(G1).
      await type(tester, '무릎 쓰는 거 말고', enter: true);
      expect(sent, isEmpty);
      expect(find.text(l.aiOff), findsOneWidget);
      expect(find.text(l.routineHeldBack('offline')), findsNothing);
      expect(startButton(), findsNothing);
      expect(find.text(l.routineNoConditions), findsOneWidget);
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

    testWidgets('검토#1 명령 낱말 없는 의료 글은 기기가 거절 — 모델도 원판도 없다', (tester) async {
      final calls = <String>[];
      await pump(
        tester,
        ai: RecordAi(
          respond: (i, _) async {
            if (i == familyInstructions) return {'t': <String>[]};
            calls.add(i == routineInstructions ? 'routine' : 'v3');
            return {'kind': 'routine'};
          },
        ),
      );
      for (final t in [
        '무릎 수술 2주 됐는데 하체 해도 돼?',
        'can I squat after surgery?',
        'リハビリ中だけどスクワットしてもいい？',
      ]) {
        await type(tester, t, enter: true);
        expect(find.text(l.routineRefused('medical')), findsOneWidget);
        expect(startButton(), findsNothing);
      }
      expect(calls, isEmpty);
    });

    testWidgets('검토#1 기록 검색이 루틴이라 한 의료 글은 칩 없이 거절 — 조건까지 읽기로 원판이 나가지 않는다', (
      tester,
    ) async {
      final calls = <String>[];
      await pump(
        tester,
        ai: RecordAi(
          respond: (i, _) async {
            if (i == familyInstructions) return {'t': <String>[]};
            calls.add(i == routineInstructions ? 'routine' : 'v3');
            return {'kind': 'routine'};
          },
        ),
      );
      await type(tester, '재활 운동 몇 번 했어', enter: true);
      expect(calls, ['v3']);
      expect(find.text(l.routineRefused('medical')), findsOneWidget);
      expect(find.text(l.routineWithConditions), findsNothing);
      expect(find.text(l.routineNoConditions), findsNothing);
    });
  });

  testWidgets('검토#1 의료 낱말이 든 제목 찾기는 거절하지 않고 기록 검색에 묻는다', (tester) async {
    final calls = <String>[];
    await pump(
      tester,
      ai: RecordAi(
        respond: (i, _) async {
          if (i == familyInstructions) return {'t': <String>[]};
          calls.add(i == routineInstructions ? 'routine' : 'v3');
          return {
            'exercises': ['스쿼트'],
          };
        },
      ),
    );
    await type(tester, '재활 스쿼트', enter: true);
    expect(calls, ['v3']);
    expect(find.text(l.routineRefused('medical')), findsNothing);
  });

  testWidgets('검토#6 원판이 나간 글은 다시 쳐도 "원판 0장" 이라 하지 않는다 — 앞서 썼다고 말한다', (
    tester,
  ) async {
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
    await type(tester, '무릎 쓰는 거 말고', enter: true);
    await tester.tap(find.text(l.routineRetry));
    await tester.pumpAndSettle();
    expect(asked, 2);
    await type(tester, '하체 루틴');
    await type(tester, '무릎 쓰는 거 말고', enter: true);
    // 깨진 답을 두 번 받은 글은 보내지 않는다 — 이번엔 원판이 나가지 않았다.
    expect(asked, 2);
    await tester.tap(find.text(l.routineNoConditions));
    await tester.pumpAndSettle();
    expect(startButton(), findsOneWidget);
    expect(find.text(l.routinePlatesZero), findsNothing);
    expect(find.text(l.routinePlatesBefore), findsOneWidget);
    // 담아 둔 답도 같다: 이번엔 0장이지만 이 글에는 앞서 원판이 나갔다.
    await type(tester, '하체로 짜줘', enter: true);
    expect(asked, 3);
    expect(find.text(l.routinePlatesBefore), findsNothing);
    await type(tester, '하체 루틴');
    await type(tester, '하체로 짜줘', enter: true);
    expect(asked, 3);
    expect(startButton(), findsOneWidget);
    expect(find.text(l.routinePlatesZero), findsNothing);
    expect(find.text(l.routinePlatesBefore), findsOneWidget);
    // 한 번도 보내지 않은 글의 칩 카드만 원판 0장이다.
    await type(tester, '하체 루틴');
    await tester.tap(find.text(l.routineMakePart(l.queryPart('legs'))));
    await tester.pumpAndSettle();
    // 기기가 짠 카드는 원판 줄이 없다 — '원판 0장' 은 읽을 것이 없어 뺐다.
    expect(find.text(l.routinePlatesZero), findsNothing);
  });

  testWidgets('검증 O2·O4 친 무게는 비우지 않고, 바꾼 세트와 나머지를 비운 까닭을 말한다', (tester) async {
    await pump(
      tester,
      records: [
        session('o1', 7, 20, [
          ExerciseBlock('벤치프레스', [kg(60, 10), ...times(3, () => kg(85, 5))]),
        ]),
      ],
      ai: RecordAi(
        respond: (_, _) async => {
          'exercises': ['벤치프레스'],
          'targets': [
            {'exercise': '벤치프레스', 'weight': 50, 'unit': 'kg'},
          ],
        },
      ),
    );
    await type(tester, '벤치 50kg 로 짜줘', enter: true);
    expect(
      find.textContaining(l.routineTypedWeight(4, '60kg·85kg', '50kg')),
      findsOneWidget,
    );
    expect(find.textContaining(l.routineBlank('stale')), findsNothing);
    expect(find.textContaining('50kg×10'), findsWidgets);
  });

  testWidgets('검증 O4 오래된 기록이어도 친 무게는 남고 나머지를 비운 까닭을 말한다', (tester) async {
    await pump(
      tester,
      records: [
        session('o1', 7, 20, [
          ExerciseBlock('벤치프레스', [kg(60, 10), ...times(3, () => kg(85, 5))]),
        ]),
      ],
      ai: RecordAi(
        respond: (_, _) async => {
          'exercises': ['벤치프레스'],
          'targets': [
            {'exercise': '벤치프레스', 'weight': 100, 'unit': 'kg'},
          ],
        },
      ),
    );
    await type(tester, '벤치 100kg 로 짜줘', enter: true);
    expect(find.textContaining(l.routineBlank('stale')), findsOneWidget);
    expect(find.textContaining(l.routineTypedKept), findsOneWidget);
    expect(
      find.textContaining(l.routineTypedWeight(3, '85kg', '100kg')),
      findsOneWidget,
    );
    expect(find.textContaining('100kg×5'), findsWidgets);
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
      await type(tester, '무릎 쓰는 거 말고 하체 짜줘', enter: true);
      expect(startButton(), findsNothing);
      expect(find.text(l.routineHeldBack('misread')), findsOneWidget);
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

  testWidgets('서버가 다시 묻고도 못 읽은 답(502 unreadable)은 연결 문구가 아니고 원판도 안 나갔다', (
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
            code: 'unreadable',
          );
        },
      ),
    );
    await type(tester, '하체로 짜줘', enter: true);
    expect(asked, 1);
    expect(find.text(l.routineMisread), findsOneWidget);
    expect(find.text(l.routineOffline), findsNothing);
    expect(find.text(l.routinePlatesBefore), findsNothing);
    expect(startButton(), findsOneWidget);
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
    // 글이 가리킨 운동의 기록도 평소 목록처럼 남는다("스쿼트 5x5" 로 찾던 스쿼트 기록).
    // 목록 줄(기록 한 장)은 여러 글자 조각으로 된 Text.rich 다.
    int rows() => find
        .textContaining('스쿼트')
        .evaluate()
        .where((e) => e.widget is Text && (e.widget as Text).data == null)
        .length;
    await type(tester, '스쿼트');
    final plain = rows();
    expect(plain, greaterThan(0));
    await type(tester, '스쿼트 5x5');
    expect(routeHome('스쿼트 5x5'), HomeRoute.routine);
    expect(rows(), plain);
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
          if (i == familyInstructions) return {'t': <String>[]};
          calls.add(i == routineInstructions ? 'routine' : 'v3');
          return i == routineInstructions
              ? {'kind': 'lookup'}
              : {'kind': 'routine'};
        },
      ),
    );
    // 기록 검색(루틴이라 함) → 한 번 넘김 → 루틴 지시문(기록 질문이라 함): 더 넘기지
    // 않고 글에 적힌 운동으로 기기에서 센 답 + 원판 0 길.
    await type(tester, '다음 운동 때 벤치 몇키로 치면 돼', enter: true);
    await tester.tap(find.text(l.routineWithConditions));
    await tester.pumpAndSettle();
    expect(calls, ['v3', 'routine']);
    expect(find.text(l.routineAsQuestion), findsNothing);
    expect(find.text(l.routineWithConditions), findsNothing);
    expect(find.text(l.queryMisreadLocal), findsOneWidget);
    await tester.tap(find.text(l.routineNoConditions));
    await tester.pumpAndSettle();
    expect(startButton(), findsOneWidget);
    expect(calls, ['v3', 'routine']);
    // 거꾸로(루틴 지시문 → 한 번 넘김 → 기록 검색)도 한 번 넘긴 뒤 답한다.
    calls.clear();
    await type(tester, '벤치 몇 키로로 할지 짜줘', enter: true);
    expect(calls, ['routine']);
    await tester.tap(find.text(l.routineAsQuestion));
    await tester.pumpAndSettle();
    expect(calls, ['routine', 'v3']);
    expect(find.text(l.routineWithConditions), findsNothing);
    expect(find.text(l.queryMisreadLocal), findsOneWidget);
    expect(find.text(l.routineNoConditions), findsOneWidget);
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
    // 기기가 짠 카드는 원판 줄이 없다 — '원판 0장' 은 읽을 것이 없어 뺐다.
    expect(find.text(l.routinePlatesZero), findsNothing);
    await tester.showKeyboard(search);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(asked, 1);
    expect(find.text('레그프레스'), findsNothing);
    expect(find.text(l.routinePlatesZero), findsNothing);
  });

  testWidgets('검토#6 원판이 나간 글은 칩으로 짠 카드여도 "원판 0장" 이라 하지 않는다', (tester) async {
    await pump(
      tester,
      ai: RecordAi(respond: (_, _) async => {'type': 'json_object'}),
    );
    await type(tester, '무릎 쓰는 거 말고 하체 짜줘', enter: true);
    await tester.tap(find.text(l.routineNoConditions));
    await tester.pumpAndSettle();
    expect(startButton(), findsOneWidget);
    expect(find.text(l.routinePlatesZero), findsNothing);
  });

  testWidgets('검토#9 무게만 친 칸: 작업 세트만 바꾸고 무엇을 바꿨는지 말한다', (tester) async {
    await pump(
      tester,
      ai: RecordAi(
        respond: (_, _) async => {
          'exercises': ['벤치프레스'],
          'targets': [
            {'exercise': '벤치프레스', 'weight': 100, 'unit': 'kg'},
          ],
        },
      ),
    );
    await type(tester, '벤치 100kg 로 짜줘', enter: true);
    expect(
      find.textContaining(l.routineTypedWeight(3, '85kg', '100kg')),
      findsOneWidget,
    );
    expect(find.textContaining('60kg×10'), findsWidgets);
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
          if (i == familyInstructions) return {'t': <String>[]};
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
    // 원판 줄: 값은 쓴 토큰만큼이라 수를 못박지 않고, 질문을 다시 적지 않는다.
    expect(find.text(l.routinePlateCost(l.routineAskTooName)), findsOneWidget);
    expect(l.routinePlateCost('x'), isNot(contains('1')));
    expect(
      find.text(l.routinePlateCost(l.routineAskToo('지난주 스쿼트 최고 보여주고'))),
      findsNothing,
    );
    await tester.tap(find.text(l.routineAskToo('지난주 스쿼트 최고 보여주고')));
    await tester.pumpAndSettle();
    expect(calls, ['routine', 'v3']);
    // 물은 조각의 답과 함께 친 루틴 부분(카드)도 화면에 남는다.
    expect(find.text(l.routineHeaderToday), findsOneWidget);
    expect(find.text('스쿼트'), findsWidgets);
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

  testWidgets('S13 평일 카드: 쌤 루틴 아래 같은 요일 초안 — 지난주 수요일 줄과 요인 머리', (tester) async {
    await pump(tester);
    await type(tester, '오늘 루틴 짜줘');
    final d = DateTime(2026, 9, 2);
    expect(
      find.text(l.routineWhyWeekday(1, l.weekdayLabel(d), l.routineDate(d))),
      findsOneWidget,
    );
    // 9/2: 본운동(첫 칸) 스쿼트의 작업 세트 3×5 → 순발력 날. 뒤의 루마니안·레그컬(3×10)은
    // 그날을 바꾸지 않는다.
    expect(
      find.text(
        l.routineFactorDay(
          l.routineFactor('power'),
          l.routineFactorWhy('sets', '3', '5'),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('주말 카드: 모자란 요인 줄·셈 줄·없는 요인 줄, 타바타로 칩을 누르면 타바타', (tester) async {
    final mw = methodWeek(DateTime(2026, 9, 14));
    await pump(
      tester,
      records: [
        mw[0],
        mw[1],
        mw[3],
        // 화요일 채우기 뒤 마무리 버피 — 그날은 근지구력 날 그대로다.
        at(DateTime(2026, 9, 15, 20), [
          ExerciseBlock('버피', times(3, () => reps(15))),
        ]),
      ],
      now: DateTime(2026, 9, 19, 10),
    );
    await type(tester, '오늘 루틴 짜줘');
    final mon = DateTime(2026, 9, 14);
    expect(
      find.text(
        l.routineWhyFactor(
          'strength',
          '${l.weekdayLabel(mon)}(${l.routineDate(mon)})',
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining(l.routineFactor('cardio')), findsWidgets);
    expect(
      find.textContaining(l.routineFactorMissing(l.routineFactor('cardio'))),
      findsOneWidget,
    );
    // 요인 셈은 '근거 보기' 안에 있다.
    await tester.tap(find.byKey(const ValueKey('routine-details')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('${l.routineFactor('strength')} 1'),
      findsOneWidget,
    );
    // 내가 쓴 bpm(목요일 30bpm)으로 짜는 칩도 — 수를 적는다.
    expect(find.text(l.routineBpmChip(30)), findsOneWidget);
    await tester.tap(find.text(l.routineTabataChip));
    await tester.pumpAndSettle();
    expect(find.textContaining('타바타'), findsWidgets);
    expect(find.text(l.routineTabataChip), findsNothing);
  });

  testWidgets('평일 조정 칩: 누르면 그 요인으로 한 날', (tester) async {
    final changed = {
      ...methodPlan,
      4: () => [ExerciseBlock('스쿼트', times(3, () => kg(80, 10)))],
    };
    await pump(
      tester,
      records: [
        ...methodWeek(DateTime(2026, 8, 31)),
        ...weekLog(DateTime(2026, 9, 7), 5, changed),
        ...weekLog(DateTime(2026, 9, 14), 3, methodPlan),
      ],
      now: DateTime(2026, 9, 17, 18),
    );
    await type(tester, '오늘 루틴 짜줘');
    await tester.tap(find.text(l.routineFactorChip('sustain', 0)));
    await tester.pumpAndSettle();
    expect(find.text('스쿼트 30bpm'), findsOneWidget);
  });

  testWidgets('요일표 알약: 이 요일의 요인, 벗어난 날엔 줄·셈 알약·요일표 칩 — 누르면 그 요인 날', (
    tester,
  ) async {
    final drifted = {...methodPlan, 1: methodPlan[5]!, 3: methodPlan[3]!};
    final mon = DateTime(2026, 9, 14, 18);
    await pump(
      tester,
      records: weekLog(DateTime(2026, 8, 31), 14, drifted),
      now: mon,
    );
    await type(tester, '오늘 루틴 짜줘');
    expect(
      find.text(l.routineWeekdayFactor(l.weekdayLabel(mon), '근력')),
      findsOneWidget,
    );
    expect(find.text(l.routineDrift('근력', '심폐')), findsOneWidget);
    // 셈은 접지 않고 알약으로 보인다.
    expect(
      find.textContaining('${l.routineFactor('strength')} 1'),
      findsOneWidget,
    );
    await tester.tap(find.text(l.routineFactorChip('strength', 1)));
    await tester.pumpAndSettle();
    expect(find.textContaining('이번 주 근력이 부족해서'), findsOneWidget);
    expect(find.text(l.routineDrift('근력', '심폐')), findsNothing);
  });
}

typedef Routine = ({
  String id,
  String gymId,
  String gym,
  String title,
  List<ExerciseBlock> blocks,
});
