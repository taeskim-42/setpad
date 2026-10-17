// UI/UX polish 회귀: 다크 모드 대비(sealOn), 첫 사용 안내, 되돌리기, 44pt 터치 목표,
// 공유 줄의 '보내는 중', 순서 핸들, 식단 메뉴.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/body.dart';
import 'package:setpad/body_page.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/gym_page.dart';
import 'package:setpad/settings_page.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/paywall.dart';
import 'package:setpad/palette.dart';
import 'package:setpad/routine.dart';
import 'package:setpad/routine_card.dart';
import 'package:setpad/setup_chips.dart';

const _darkOn = 0xFF332B19;

Future<void> pumpApp(
  WidgetTester tester,
  Widget home, {
  CupertinoThemeData theme = setpadTheme,
}) async {
  await tester.pumpWidget(
    CupertinoApp(
      locale: const Locale('ko'),
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      theme: theme,
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

NotesStore makeStore(WidgetTester tester) {
  final dir = Directory.systemTemp.createTempSync('setpad_ux_');
  final store = NotesStore(directory: dir);
  addTearDown(() {
    store.dispose();
    dir.deleteSync(recursive: true);
  });
  return store;
}

/// Colour of the text drawn by the closest DefaultTextStyle above [finder].
int textColor(WidgetTester tester, Finder finder) {
  final style = tester.widget<DefaultTextStyle>(
    find.ancestor(of: finder, matching: find.byType(DefaultTextStyle)).first,
  );
  return style.style.color!.toARGB32();
}

Finder rowOf(Note n) =>
    find.byWidgetPredicate((w) => w is Dismissible && w.key == ValueKey(n.id));

void main() {
  group('P1. sealOn — 금색 바탕 위의 글자', () {
    test('sealOn 은 어두울 때 어두운 글자, 밝을 때 흰 글자이고 대비가 충분하다', () {
      expect(sealOn.color.toARGB32(), 0xFFFFFFFF);
      expect(sealOn.darkColor.toARGB32(), _darkOn);
      double lum(Color c) => c.computeLuminance();
      double ratio(Color a, Color b) {
        final hi = lum(a) > lum(b) ? lum(a) : lum(b);
        final lo = lum(a) > lum(b) ? lum(b) : lum(a);
        return (hi + 0.05) / (lo + 0.05);
      }

      expect(ratio(seal.darkColor, sealOn.darkColor), greaterThan(7));
      expect(ratio(seal.color, sealOn.color), greaterThan(4.5));
    });

    testWidgets('앱 테마의 채운 단추는 어두운 모드에서 sealOn 글자다', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(
        tester,
        Center(
          child: CupertinoButton.filled(
            onPressed: () {},
            child: const Text('x'),
          ),
        ),
      );
      expect(textColor(tester, find.text('x')), _darkOn);
      final background =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(CupertinoButton),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as ShapeDecoration;
      expect(background.color!.toARGB32(), seal.darkColor.toARGB32());
    });

    testWidgets('밝은 모드는 그대로 흰 글자', (tester) async {
      await pumpApp(
        tester,
        Center(
          child: CupertinoButton.filled(
            onPressed: () {},
            child: const Text('x'),
          ),
        ),
      );
      expect(textColor(tester, find.text('x')), 0xFFFFFFFF);
    });

    testWidgets('결제 화면의 채운 구매 단추는 어두운 모드에서 sealOn 글자다', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      http.Response json(Object body) => http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json'},
      );
      final account = Account(
        client: MockClient((r) async {
          if (r.url.path == '/api/purchase') {
            return json({'plan': 'yearly', 'selling': true});
          }
          if (r.url.path == '/api/plates') {
            return json({
              'balance': 300,
              'pro': true,
              'plan': 'yearly',
              'input': {'used': 0, 'limit': 100},
            });
          }
          return http.Response('{}', 404);
        }),
      )..token = 'account-token';
      await tester.runAsync(account.refreshForTest);
      await pumpApp(tester, Paywall(account: account));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      final l = await L.delegate.load(const Locale('ko'));
      final label = find.text('${l.planYearly} · ${l.planActive}');
      expect(label, findsOneWidget);
      expect(tester.widget<Text>(label).style!.color!.toARGB32(), _darkOn);
    });

    testWidgets('식단 단추가 눌린 모양일 때 아이콘은 sealOn 이다', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final c = RoutineEditorController();
      final meal = ValueNotifier<({String text, int? index})?>((
        text: '',
        index: null,
      ));
      addTearDown(meal.dispose);
      await pumpApp(
        tester,
        CupertinoPageScaffold(
          child: SafeArea(
            child: RoutineEditor(
              controller: c,
              mealText: meal,
              onMealText: (_, _) => null,
              onMealPhoto: () {},
            ),
          ),
        ),
      );
      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const ValueKey('meal-button')),
          matching: find.byType(Icon),
        ),
      );
      expect(icon.color!.toARGB32(), _darkOn);
    });
  });

  group('E2. 첫 사용 안내', () {
    Future<(NotesStore, Note)> open(
      WidgetTester tester, {
      int others = 0,
    }) async {
      final store = makeStore(tester);
      for (var i = 0; i < others; i++) {
        store.create(at: DateTime.now().subtract(Duration(days: i + 1)));
      }
      final note = store.create();
      await pumpApp(tester, EditorPage(store: store, note: note));
      return (store, note);
    }

    testWidgets('빈 기록 첫 화면에 세 줄이 뜨고, 닫으면 다시 안 뜬다', (tester) async {
      final (store, _) = await open(tester);
      final l = await L.delegate.load(const Locale('ko'));
      expect(find.textContaining(l.firstRunHint1), findsOneWidget);
      expect(find.textContaining(l.firstRunHint2), findsOneWidget);
      expect(find.textContaining(l.firstRunHint3), findsOneWidget);
      // The hint sits above the input line.
      expect(
        tester.getTopLeft(find.textContaining(l.firstRunHint3)).dy,
        lessThan(tester.getTopLeft(find.byType(CupertinoTextField)).dy),
      );
      await tester.tap(find.byKey(const ValueKey('first-run-close')));
      await tester.pumpAndSettle();
      expect(find.textContaining(l.firstRunHint1), findsNothing);
      expect(store.firstRunHintSeen, isTrue);
    });

    testWidgets('닫았다는 표시는 저장되어 다음 실행에도 남는다', (tester) async {
      final dir = Directory.systemTemp.createTempSync('setpad_ux_flag_');
      addTearDown(() => dir.deleteSync(recursive: true));
      await tester.runAsync(() async {
        final first = NotesStore(directory: dir);
        await first.load();
        first.dismissFirstRunHint();
        await first.flush();
        first.dispose();
        final second = NotesStore(directory: dir);
        await second.load();
        expect(second.firstRunHintSeen, isTrue);
        second.dispose();
      });
    });

    testWidgets('저장소에 기록이 둘 이상이면 뜨지 않는다', (tester) async {
      await open(tester, others: 1);
      final l = await L.delegate.load(const Locale('ko'));
      expect(find.textContaining(l.firstRunHint1), findsNothing);
    });

    testWidgets('운동을 하나라도 적으면 사라진다', (tester) async {
      await open(tester);
      final l = await L.delegate.load(const Locale('ko'));
      expect(find.textContaining(l.firstRunHint1), findsOneWidget);
      await tester.enterText(find.byType(CupertinoTextField), '벤치프레스');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.textContaining(l.firstRunHint1), findsNothing);
    });

    testWidgets('큰 글자(2.0)·375pt 에서도 넘치지 않는다', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await open(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('L1. 빈 목록', () {
    testWidgets('비어 있고 검색어도 없으면 0개의 기록 줄이 없고, 기록이 있으면 있다', (tester) async {
      final store = makeStore(tester);
      await pumpApp(tester, NotesListPage(store: store, onOpen: (_) {}));
      final l = await L.delegate.load(const Locale('ko'));
      expect(find.text(l.noteCount(0)), findsNothing);
      expect(find.text(l.noNotesYet), findsOneWidget);
      store.create(
        at: DateTime.now().subtract(const Duration(days: 1)),
        blocks: [
          ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text(l.noteCount(1)), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('E5. 되돌리기', () {
    testWidgets('세트를 지우면 한 줄이 뜨고, 되돌리면 같은 자리에 같은 세트가 돌아온다', (tester) async {
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 10')
        ..addSet('70 8')
        ..addSet('60 12')
        ..closeBlock();
      final middle = c.blocks.single.sets[1];
      expect(middle.value, 70);
      await pumpApp(
        tester,
        CupertinoPageScaffold(child: RoutineEditor(controller: c)),
      );
      final l = await L.delegate.load(const Locale('ko'));
      await tester.tap(find.text('2 70×8'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.xmark).first);
      await tester.pumpAndSettle();
      expect(c.blocks.single.sets, hasLength(2));
      expect(find.text('${l.setRemoved(2)} · '), findsOneWidget);
      final undo = find.byKey(const ValueKey('set-undo'));
      expect(tester.getSize(undo).height, greaterThanOrEqualTo(44));
      await tester.tap(undo);
      await tester.pumpAndSettle();
      expect(c.blocks.single.sets, hasLength(3));
      expect(c.blocks.single.sets[1].value, middle.value);
      expect(c.blocks.single.sets[1].reps, 8);
      expect(find.byKey(const ValueKey('set-undo')), findsNothing);
    });

    testWidgets('5초가 지나면 줄이 접히고, 연달아 지운 것은 끝의 것부터 돌아온다', (tester) async {
      final c = RoutineEditorController()
        ..addExercise('스쿼트')
        ..addSet('100 5')
        ..addSet('90 5')
        ..addSet('80 5')
        ..closeBlock();
      await pumpApp(
        tester,
        CupertinoPageScaffold(child: RoutineEditor(controller: c)),
      );
      Future<void> remove(String cell) async {
        await tester.tap(find.text(cell));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(CupertinoIcons.xmark).first);
        await tester.pumpAndSettle();
      }

      await remove('1 100×5');
      await remove('1 90×5');
      expect(c.blocks.single.sets, hasLength(1));
      await tester.tap(find.byKey(const ValueKey('set-undo')));
      await tester.pumpAndSettle();
      expect(c.blocks.single.sets.map((s) => s.value), [90, 80]);
      await tester.tap(find.byKey(const ValueKey('set-undo')));
      await tester.pumpAndSettle();
      expect(c.blocks.single.sets.map((s) => s.value), [100, 90, 80]);
      await remove('3 80×5');
      expect(find.byKey(const ValueKey('set-undo')), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      expect(find.byKey(const ValueKey('set-undo')), findsNothing);
    });

    testWidgets('그 운동이 이미 없으면 되돌려도 아무 일도 없다', (tester) async {
      final c = RoutineEditorController()
        ..addExercise('스쿼트')
        ..addSet('100 5')
        ..closeBlock();
      final block = c.blocks.single;
      final set = block.sets.single;
      c.removeSet(0, 0);
      c.removeBlock(0);
      c.restoreSet(block, 0, set);
      expect(c.blocks, isEmpty);
    });

    testWidgets('기록을 지우면 목록 위에 되돌리기가 뜨고, 서버 지우기는 그 뒤에 나간다', (tester) async {
      final store = makeStore(tester);
      final keep = store.create(
        at: DateTime.now().subtract(const Duration(days: 2)),
        blocks: [
          ExerciseBlock('풀업', [LoggedSet(reps: 8)]),
        ],
      );
      final gone = store.create(
        at: DateTime.now().subtract(const Duration(days: 1)),
        gymId: 'g1',
        blocks: [
          ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
        ],
      );
      final index = store.notes.indexOf(gone);
      await pumpApp(tester, NotesListPage(store: store, onOpen: (_) {}));
      final l = await L.delegate.load(const Locale('ko'));
      await tester.drag(rowOf(gone), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.delete).last);
      await tester.pumpAndSettle();
      expect(store.notes, [keep]);
      expect(store.pendingDeletes, isNotEmpty, reason: '운동 줄을 서버에서 지울 것이 남았다');
      expect(find.text('${l.noteRemoved} · '), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('note-undo')));
      await tester.pumpAndSettle();
      expect(store.notes.indexOf(gone), index, reason: '같은 자리');
      expect(store.pendingDeletes, isEmpty, reason: '서버로 가기 전이라 지우기가 취소된다');
      expect(find.byKey(const ValueKey('note-undo')), findsNothing);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('5초가 지나면 줄이 접히고 되돌릴 수 없다', (tester) async {
      final store = makeStore(tester);
      final gone = store.create(
        blocks: [
          ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
        ],
      );
      store.create(
        at: DateTime.now().subtract(const Duration(days: 1)),
        blocks: [
          ExerciseBlock('풀업', [LoggedSet(reps: 8)]),
        ],
      );
      await pumpApp(tester, NotesListPage(store: store, onOpen: (_) {}));
      final l = await L.delegate.load(const Locale('ko'));
      await tester.drag(rowOf(gone), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.delete).last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('note-undo')), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      expect(find.byKey(const ValueKey('note-undo')), findsNothing);
      expect(store.undoDelete(), isFalse);
      expect(store.notes, isNot(contains(gone)));
      await tester.pump(const Duration(seconds: 1));
    });

    test('이미 서버로 나간 지우기는 되돌리지 않는다', () {
      final dir = Directory.systemTemp.createTempSync('setpad_ux_undo_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = NotesStore(directory: dir);
      addTearDown(store.dispose);
      final note = store.create(gymId: 'g1');
      store.delete(note);
      expect(store.undoableDelete, same(note));
      store.pendingDeletes
          .clear(); // what sendDeletes does once the server answered
      expect(store.undoableDelete, isNull);
      expect(store.undoDelete(), isFalse);
      expect(store.notes, isEmpty);
    });
  });

  group('E4. ⋯ 메뉴의 식단 남기기', () {
    testWidgets('메뉴에서 식단 남기기를 고르면 사진·앨범·글 시트가 뜬다', (tester) async {
      final store = makeStore(tester);
      await pumpApp(tester, EditorPage(store: store, note: store.create()));
      final l = await L.delegate.load(const Locale('ko'));
      await tester.tap(find.byKey(const ValueKey('record-menu')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('menu-meal')), findsOneWidget);
      expect(find.text(l.mealAdd), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('menu-meal')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('meal-text-toggle')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('meal-text-toggle')));
      await tester.pumpAndSettle();
      expect(find.text(l.mealWrite), findsNothing, reason: '시트가 닫혔다');
    });

    testWidgets('세트를 치는 키패드 모드에서도 메뉴로 끼니를 남길 길이 있다', (tester) async {
      final store = makeStore(tester);
      final note = store.create(
        blocks: [
          ExerciseBlock('벤치프레스', [LoggedSet(value: 80, reps: 10)]),
        ],
      );
      await pumpApp(tester, EditorPage(store: store, note: note));
      await tester.tap(find.text('1 80×10'));
      await tester.pumpAndSettle();
      expect(find.byType(SetKeypad), findsOneWidget);
      expect(find.byKey(const ValueKey('meal-button')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('record-menu')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('menu-meal')), findsOneWidget);
    });
  });

  group('E6. 운동 순서 핸들', () {
    Future<RoutineEditorController> pumpWith(WidgetTester tester, int n) async {
      final c = RoutineEditorController();
      for (var i = 0; i < n; i++) {
        c
          ..addExercise('운동 ${i + 1}')
          ..addSet('50 10')
          ..closeBlock();
      }
      await pumpApp(
        tester,
        CupertinoPageScaffold(child: RoutineEditor(controller: c)),
      );
      return c;
    }

    testWidgets('운동이 하나면 핸들이 없고, 둘 이상이면 모두 흐리게 늘 보인다', (tester) async {
      await pumpWith(tester, 1);
      expect(find.byIcon(CupertinoIcons.line_horizontal_3), findsNothing);
    });

    testWidgets('둘 이상이면 tertiaryLabel 색의 ≡ 가 운동마다 있다', (tester) async {
      await pumpWith(tester, 2);
      final icons = find.byIcon(CupertinoIcons.line_horizontal_3);
      expect(icons, findsNWidgets(2));
      final icon = tester.widget<Icon>(icons.first);
      expect(
        icon.color!.toARGB32(),
        CupertinoColors.tertiaryLabel.color.toARGB32(),
      );
      // The touch box is a full 44.
      final box = find.ancestor(
        of: icons.first,
        matching: find.byType(SizedBox),
      );
      expect(tester.getSize(box.first).shortestSide, 44);
    });

    testWidgets('세트를 처음 길게 눌러 끌 때만 한 번 안내가 뜬다', (tester) async {
      dragHintShown = false;
      final c = RoutineEditorController()
        ..addExercise('스쿼트')
        ..addSet('60 10')
        ..addSet('80 8')
        ..closeBlock();
      await pumpApp(
        tester,
        CupertinoPageScaffold(child: RoutineEditor(controller: c)),
      );
      final l = await L.delegate.load(const Locale('ko'));
      final hint = find.text(l.setDragHint);
      expect(hint, findsNothing);
      Future<void> drag() async {
        final g = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('set-cell-1'))),
        );
        await tester.pump(
          kLongPressTimeout + const Duration(milliseconds: 100),
        );
        await g.moveTo(
          tester.getCenter(find.byKey(const ValueKey('set-cell-0'))),
        );
        await tester.pump();
        await g.up();
        await tester.pump();
      }

      await drag();
      expect(hint, findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(hint, findsNothing);
      await drag();
      expect(hint, findsNothing, reason: '한 번만');
      await tester.pumpAndSettle();
    });
  });

  group('E9. 공유 줄', () {
    Future<Note> openShared(WidgetTester tester, {String? routineId}) async {
      final store = makeStore(tester);
      final account =
          Account(client: MockClient((_) async => http.Response('{}', 200)))
            ..token = 'member'
            ..gyms = [Gym(id: 'g1', name: 'BPM')];
      final note = store.create(
        gymId: 'g1',
        routineId: routineId,
        blocks: [
          ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
        ],
      );
      await pumpApp(
        tester,
        EditorPage(store: store, note: note, account: account),
      );
      return note;
    }

    testWidgets('아직 못 올린 기록은 보내는 중이라고, 올린 기록은 공유 중이라고 말한다', (tester) async {
      final l = await L.delegate.load(const Locale('ko'));
      final note = await openShared(tester);
      expect(find.text(l.shareSending), findsOneWidget);
      expect(find.text(l.shareGym), findsNothing);
      note.sentAt = DateTime.now();
      note.updatedAt = DateTime.now().subtract(const Duration(minutes: 1));
      // The header listens to the store; any touch redraws it.
      final store = (tester.widget<EditorPage>(find.byType(EditorPage))).store;
      store.touch();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(l.shareGym), findsOneWidget);
      expect(find.text(l.shareSending), findsNothing);
    });

    testWidgets('서버가 거절한 기록은 보내는 중이 아니다', (tester) async {
      final l = await L.delegate.load(const Locale('ko'));
      final note = await openShared(tester);
      note.uploadRejected = true;
      (tester.widget<EditorPage>(find.byType(EditorPage))).store.touch();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(l.shareSending), findsNothing);
      expect(find.text(l.shareRejected), findsOneWidget);
    });
  });

  group('E10. 44pt 터치 목표', () {
    testWidgets('SuggestionChip: 알약은 그대로, 누르는 상자는 44', (tester) async {
      await pumpApp(
        tester,
        Center(
          child: SuggestionChip(label: '벤치', selected: false, onTap: () {}),
        ),
      );
      expect(
        tester.getSize(find.byType(CupertinoButton)).height,
        greaterThanOrEqualTo(44),
      );
      final pill = find.descendant(
        of: find.byType(CupertinoButton),
        matching: find.byType(Container),
      );
      expect(tester.getSize(pill.first).height, lessThan(36));
    });

    testWidgets('설정 칩: 누르는 상자는 44, 칩 모양은 그대로', (tester) async {
      await pumpApp(
        tester,
        CupertinoPageScaffold(
          child: SetupChips(
            title: '벤치프레스',
            setup: null,
            reps: 0,
            sets: 0,
            open: true,
            onToggle: () {},
            onChanged: (_) {},
            onEditing: (_) {},
          ),
        ),
      );
      final buttons = find.descendant(
        of: find.byType(SetupChips),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.button == true,
        ),
      );
      expect(buttons, findsWidgets);
      for (final b in buttons.evaluate()) {
        final size = (b.renderObject! as RenderBox).size;
        expect(size.height, greaterThanOrEqualTo(44));
      }
    });

    testWidgets('키패드의 이전과 같이 키는 44', (tester) async {
      await pumpApp(
        tester,
        CupertinoPageScaffold(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SetKeypad(
              onKey: (_) {},
              onBackspace: () {},
              onAddSet: () {},
              onSubmit: () {},
              submitLabel: '완료',
              onText: () {},
              onAdjust: (_) {},
              stepLabel: '1',
              onStepPick: () {},
              onRepeat: () {},
              repeatLabel: '80 10',
            ),
          ),
        ),
      );
      final l = await L.delegate.load(const Locale('ko'));
      final key = find.ancestor(
        of: find.textContaining(l.repeatPrevious),
        matching: find.byType(SizedBox),
      );
      expect(
        key.evaluate().any(
          (e) => (e.renderObject! as RenderBox).size.height >= 44,
        ),
        isTrue,
      );
    });

    testWidgets('운동 제목: 누르는 상자는 44, 제목 옆 빈 곳은 제목 고치기가 아니다', (tester) async {
      final c = RoutineEditorController()
        ..addExercise('벤치')
        ..addSet('80 10')
        ..closeBlock();
      await pumpApp(
        tester,
        CupertinoPageScaffold(child: RoutineEditor(controller: c)),
      );
      final title = find.text('벤치');
      final hit = find.ancestor(
        of: title,
        matching: find.byType(GestureDetector),
      );
      final tight = hit.evaluate().map(
        (e) => (e.renderObject! as RenderBox).size,
      );
      expect(tight.any((s) => s.height >= 44), isTrue);
      expect(
        tight.any((s) => s.height >= 44 && s.width < 200),
        isTrue,
        reason: '짧은 제목 옆 빈 곳까지 제목 고치기가 되지 않는다',
      );
    });
  });

  group('S1·S2·S3. 설정', () {
    Account member({List<Gym> gyms = const []}) =>
        Account(client: MockClient((_) async => http.Response('{}', 404)))
          ..token = 'member'
          ..nickname = '도전자'
          ..gyms = gyms;

    Future<void> openSettings(WidgetTester tester, {Account? account}) async {
      final store = makeStore(tester);
      await pumpApp(tester, SettingsPage(store: store, account: account));
    }

    testWidgets('묶음 목록(inset grouped)이고, AI 도움 바로 아래에 설명이 한 줄 있다', (
      tester,
    ) async {
      await openSettings(tester);
      final l = await L.delegate.load(const Locale('ko'));
      expect(find.byType(CupertinoListSection), findsWidgets);
      expect(find.byType(CupertinoListTile), findsWidgets);
      final toggle = find.byKey(const ValueKey('settings-ai'));
      final note = find.text(l.aiSettingNote);
      expect(toggle, findsOneWidget);
      expect(note, findsOneWidget);
      final gap = tester.getTopLeft(note).dy - tester.getBottomLeft(toggle).dy;
      expect(gap, inInclusiveRange(0, 24), reason: '토글 바로 밑이다');
      // The note says what leaves the phone and what stops when it is off.
      expect(l.aiSettingNote, contains('서버'));
      expect(l.aiSettingNote, contains('끄면'));
      // Section rows are 44 tall at least.
      expect(tester.getSize(toggle).height, greaterThanOrEqualTo(44));
    });

    testWidgets('닉네임은 한 줄이다 — 이름이 값이고 누르면 바꾼다', (tester) async {
      final account = member();
      await openSettings(tester, account: account);
      final l = await L.delegate.load(const Locale('ko'));
      final row = find.byKey(const ValueKey('settings-nickname'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: row, matching: find.text(l.nicknameLabel)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('도전자')),
        findsOneWidget,
      );
      expect(find.text('도전자'), findsOneWidget, reason: '이름만 보이는 줄이 따로 없다');
      expect(find.text(l.nicknameChange), findsNothing);
    });

    testWidgets('다니는 곳이 없으면 묶음 밑에 안내를, 있으면 도장 줄과 식단 공유를 둔다', (tester) async {
      final account = member();
      await openSettings(tester, account: account);
      final l = await L.delegate.load(const Locale('ko'));
      expect(find.text(l.settingsNoGym), findsOneWidget);
      account.gyms = [const Gym(id: 'g1', name: 'BPM')];
      account.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text(l.settingsNoGym), findsNothing);
      expect(find.byKey(const ValueKey('settings-gym-g1')), findsOneWidget);
      final share = find.byKey(const ValueKey('settings-share-meals'));
      await tester.scrollUntilVisible(share, 100);
      expect(share, findsOneWidget);
    });

    testWidgets('375pt·큰 글자 2.0 에서 넘치지 않는다', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await openSettings(
        tester,
        account: member(
          gyms: [const Gym(id: 'g1', name: 'BPM', trainer: '김코치')],
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('대화상자 본문은 13', (tester) async {
      final account = member();
      await openSettings(tester, account: account);
      final l = await L.delegate.load(const Locale('ko'));
      final row = find.byKey(const ValueKey('settings-sign-out-everywhere'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.text(l.accountSignOutEverywhereAsk))
            .style!
            .fontSize,
        13,
      );
    });
  });

  group('G1·G2. 도장 화면', () {
    Future<Account> pumpGym(WidgetTester tester, List<Gym> gyms) async {
      final account =
          Account(client: MockClient((_) async => http.Response('{}', 404)))
            ..token = 'member'
            ..gyms = gyms;
      final store = makeStore(tester);
      await pumpApp(
        tester,
        GymPage(account: account, store: store, gymId: 'g1'),
      );
      return account;
    }

    testWidgets('도장 목록을 아직 못 받았으면 돌아가는 표시를 둔다', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: setpadTheme,
          home: GymPage(
            account: Account(
              client: MockClient((_) async => http.Response('{}', 404)),
            )..token = 'member',
            store: makeStore(tester),
            gymId: 'g1',
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('공지·예약·바로가기·나가기가 묶음 목록이고 나가기는 44 이상이다', (tester) async {
      await pumpGym(tester, [
        Gym(
          id: 'g1',
          name: 'BPM',
          trainer: '김코치',
          notices: [
            (
              id: 'n1',
              title: '추석 연휴 휴관',
              body: '10/5~10/7 쉽니다.',
              pinned: true,
              createdAt: DateTime(2026, 10, 1),
            ),
          ],
        ),
      ]);
      expect(find.byType(CupertinoListSection), findsWidgets);
      expect(find.text('추석 연휴 휴관'), findsOneWidget);
      final leave = find.byKey(const ValueKey('gym-leave'));
      await tester.ensureVisible(leave);
      expect(tester.getSize(leave).height, greaterThanOrEqualTo(44));
    });

    testWidgets('375pt·큰 글자 2.0 에서 넘치지 않는다', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await pumpGym(tester, [
        Gym(
          id: 'g1',
          name: 'BPM 스트렝스 클럽',
          trainer: '김코치',
          notices: [
            (
              id: 'n1',
              title: '추석 연휴 휴관 안내드립니다',
              body: '10/5~10/7 쉬어요. 그 주 PT 는 앞뒤로 옮겨 주세요.',
              pinned: true,
              createdAt: DateTime(2026, 10, 1),
            ),
          ],
        ),
      ]);
      expect(tester.takeException(), isNull);
    });
  });

  group('L3. GymRow 하나로', () {
    testWidgets('PT 예약·초대·도장 줄이 모두 GymRow 이고 PT 줄은 설명 없이 제목만이다', (
      tester,
    ) async {
      final store = makeStore(tester);
      final account =
          Account(client: MockClient((_) async => http.Response('{}', 404)))
            ..token = 'member'
            ..gyms = [const Gym(id: 'g1', name: 'BPM')];
      await pumpApp(
        tester,
        NotesListPage(store: store, account: account, onOpen: (_) {}),
      );
      final l = await L.delegate.load(const Locale('ko'));
      final booking = find.widgetWithText(GymRow, l.bookingNew);
      expect(booking, findsOneWidget);
      expect(find.byType(GymRow), findsAtLeastNWidgets(2));
      expect(tester.getSize(booking).height, greaterThanOrEqualTo(44));
    });

    testWidgets('GymRow: 제목 뒤 배지와 설명을 같이 놓을 수 있고 ›가 붙는다', (tester) async {
      await pumpApp(
        tester,
        Center(
          child: GymRow(
            icon: CupertinoIcons.doc_text,
            title: '보고',
            detail: '두 줄째 설명',
            titleSuffix: const Text('2건'),
            onTap: () {},
          ),
        ),
      );
      expect(find.text('보고'), findsOneWidget);
      expect(find.text('2건'), findsOneWidget);
      expect(find.text('두 줄째 설명'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
    });
  });

  group('R1·N2. 루틴 칩·몸 정보 링크', () {
    testWidgets('그날 에너지의 목표 줄을 누르면 몸 정보가 열린다', (tester) async {
      final store = makeStore(tester);
      store.setBody(
        const BodyProfile(
          heightCm: 178,
          weightKg: 80,
          birthYear: 1996,
          sex: 'm',
          goal: 'gain',
        ),
      );
      final note =
          store.create(
              blocks: [
                ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
              ],
            )
            ..calories = 300
            ..meals.add(
              MealEntry(
                at: DateTime.now(),
                kcal: 600,
                text: '닭가슴살',
                source: MealEntry.estimate,
                macros: (carbs: 20, protein: 50, fat: 10),
              ),
            );
      await pumpApp(tester, EditorPage(store: store, note: note));
      await tester.tap(find.byKey(const ValueKey('day-summary-line')));
      await tester.pumpAndSettle();
      final goal = find.byKey(const ValueKey('day-macros-goal'));
      expect(goal, findsOneWidget);
      expect(tester.getSize(goal).height, greaterThanOrEqualTo(44));
      await tester.tap(goal);
      await tester.pumpAndSettle();
      expect(find.byType(BodyPage), findsOneWidget);
    });
  });

  group('R1. 루틴 카드의 넣을 운동 칩', () {
    Future<L> pumpCard(WidgetTester tester, int addable) async {
      final today = DateTime(2026, 9, 9, 18);
      final draft = RoutineDraft(day: today, today: today)
        ..addable.addAll([for (var i = 0; i < addable; i++) '운동$i']);
      await pumpApp(
        tester,
        CupertinoPageScaffold(
          child: ListView(
            children: [RoutineCard(draft: draft, onAdd: (_) {})],
          ),
        ),
      );
      return L.delegate.load(const Locale('ko'));
    }

    testWidgets('넷을 넘으면 넷만 보이고 더 보기를 누르면 나머지가 나온다', (tester) async {
      final l = await pumpCard(tester, 7);
      for (var i = 0; i < 7; i++) {
        expect(
          find.text(l.routineAdd('운동$i')),
          i < 4 ? findsOneWidget : findsNothing,
          reason: '$i',
        );
      }
      final more = find.byKey(const ValueKey('routine-more-chips'));
      expect(more, findsOneWidget);
      expect(find.text(l.moreChips), findsOneWidget);
      await tester.tap(more);
      await tester.pumpAndSettle();
      for (var i = 0; i < 7; i++) {
        expect(find.text(l.routineAdd('운동$i')), findsOneWidget);
      }
      expect(more, findsNothing);
    });

    testWidgets('넷 이하면 더 보기가 없다', (tester) async {
      final l = await pumpCard(tester, 4);
      expect(find.byKey(const ValueKey('routine-more-chips')), findsNothing);
      expect(find.text(l.routineAdd('운동3')), findsOneWidget);
    });
  });

  group('문구(ko)', () {
    test('모든 기록·n개의 기록·오늘 한 장, 회원 화면에는 헬스장 하나, 트레이너 화면만 도장', () async {
      final l = await L.delegate.load(const Locale('ko'));
      expect(l.allNotes, '모든 기록');
      expect(l.noteCount(3), '3개의 기록');
      expect(l.fitAll, '오늘 한 장');
      final member = {
        'settingsGym': l.settingsGym,
        'settingsNoGym': l.settingsNoGym,
        'proEverythingElseFree': l.proEverythingElseFree,
        'tagSignInNeeded': l.tagSignInNeeded,
        'tagOffline': l.tagOffline,
        'shareRejected': l.shareRejected,
        'ageConfirmAsk': l.ageConfirmAsk,
        'gymLeave': l.gymLeave,
        'gymLeaveAsk': l.gymLeaveAsk('BPM'),
        'gymConsentNotice': l.gymConsentNotice,
        'joinAsk': l.joinAsk,
        'classesNotMember': l.classesNotMember,
        'gymUnverified': l.gymUnverified,
        'nicknameHelp': l.nicknameHelp,
        'gymLinkNotMember': l.gymLinkNotMember,
        'refusedNoTrainer': l.refusedNoTrainer,
        'refusedClassNoAccess': l.refusedClassNoAccess,
      };
      for (final MapEntry(:key, :value) in member.entries) {
        expect(value, isNot(contains('도장')), reason: key);
        expect(value, isNot(contains('체육관')), reason: key);
      }
      // The trainer's own screens keep the word.
      expect(l.trainerWhichGym, contains('도장'));
      expect(l.gymPolicy, contains('도장'));
    });

    test('회원 화면의 안내·오류는 해요체다 — 법·계약 문구만 합쇼', () async {
      final l = await L.delegate.load(const Locale('ko'));
      final haeyo = [
        l.noNotesYet,
        l.noSearchResults,
        l.queryFailed,
        l.signInFailed,
        l.partnerErrNetwork,
        l.partnerErrServer,
        l.partnerEndedByMe,
        l.handoffFailed,
        l.bookingSent,
        l.tagJoinSent,
      ];
      for (final text in haeyo) {
        expect(text, isNot(matches(RegExp(r'(니다|니까)[.!?]?$'))), reason: text);
      }
      for (final text in [l.subscriptionRenews, l.accountDeleteAsk]) {
        expect(text, matches(RegExp(r'니다\.$')), reason: '법·계약 문구는 합쇼 그대로');
      }
    });
  });

  group('l10n 키', () {
    Set<String> keysOf(String lang) =>
        (jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map)
            .keys
            .cast<String>()
            .where((k) => !k.startsWith('@'))
            .toSet();

    test('아홉 언어가 같은 키를 가진다 — 지운 죽은 키가 한 곳에 남지 않는다', () {
      final ko = keysOf('ko');
      for (final lang in [
        'en',
        'ja',
        'es',
        'th',
        'vi',
        'zh',
        'zh_Hans',
        'zh_Hant',
      ]) {
        final other = keysOf(lang);
        expect(other.difference(ko), isEmpty, reason: '$lang 에만 있는 키');
        expect(ko.difference(other), isEmpty, reason: '$lang 에 없는 키');
      }
    });

    test('Apple Intelligence 시절의 안내 키는 코드와 번역에서 모두 사라졌다', () {
      final ko = keysOf('ko');
      for (final key in [
        'aiTitle',
        'aiReady',
        'aiReadyBody',
        'aiUseName',
        'queryTitle',
        'queryReadyBody',
        'mealPhoto',
        'intakeLabel',
        'tagSignIn',
      ]) {
        expect(ko, isNot(contains(key)), reason: key);
      }
    });
  });
}
