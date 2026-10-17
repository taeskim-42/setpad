// UI/UX polish 회귀: 다크 모드 대비(sealOn), 첫 사용 안내, 되돌리기, 44pt 터치 목표,
// 공유 줄의 '보내는 중', 순서 핸들, 식단 메뉴.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/body.dart';
import 'package:setpad/body_page.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/gym_page.dart';
import 'package:setpad/keep_all_text.dart';
import 'package:setpad/settings_list.dart';
import 'package:setpad/settings_page.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/paywall.dart';
import 'package:setpad/record_ai.dart' show WorkoutSetup;
import 'package:setpad/palette.dart';
import 'package:setpad/partner.dart';
import 'package:setpad/routine.dart';
import 'package:setpad/routine_card.dart';
import 'package:setpad/setup_chips.dart';
import 'package:setpad/workout_timing.dart';

import 'workout_timing_test.dart' show FakeAudio;

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

/// [f] wraps, and every line but the last ends at a space: no Korean word
/// split across lines ('여기 / 서').
void expectWordBreaks(WidgetTester tester, Finder f) {
  final p = tester.renderObject<RenderParagraph>(
    find.descendant(of: f, matching: find.byType(RichText)),
  );
  final text = p.text.toPlainText();
  double y(int i) => p.getOffsetForCaret(TextPosition(offset: i), Rect.zero).dy;
  var breaks = 0;
  for (var i = 1; i < text.length; i++) {
    if (y(i) <= y(i - 1) + 1) continue;
    breaks++;
    expect(
      text[i - 1],
      ' ',
      reason:
          'a line starts inside a word: '
          '${text.substring(0, i).replaceAll('\u200D', '')} / ...',
    );
  }
  expect(breaks, greaterThan(0), reason: 'it wraps');
}

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

    testWidgets('켜진 sealButton 은 어두운 모드에서 sealOn 글자다', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(
        tester,
        Center(
          child: Builder(
            builder: (context) =>
                sealButton(context, onPressed: () {}, child: const Text('x')),
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
          child: Builder(
            builder: (context) =>
                sealButton(context, onPressed: () {}, child: const Text('x')),
          ),
        ),
      );
      expect(textColor(tester, find.text('x')), 0xFFFFFFFF);
    });

    testWidgets('어두운 모드의 꺼진 채운 단추도 글자가 회색 바탕 위에서 읽힌다', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(
        tester,
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) => sealButton(
                  context,
                  onPressed: null,
                  child: const Text('a'),
                ),
              ),
              // A raw filled button takes the theme's contrasting colour.
              const CupertinoButton.filled(onPressed: null, child: Text('b')),
            ],
          ),
        ),
      );
      // Disabled pill: tertiarySystemFill (dark) over the dark page.
      const page = Color(0xFF000000);
      final pill = Color.alphaBlend(
        CupertinoColors.tertiarySystemFill.darkColor,
        page,
      );
      double ratio(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return ((x > y ? x : y) + 0.05) / ((x > y ? y : x) + 0.05);
      }

      for (final label in ['a', 'b']) {
        final ink = Color(textColor(tester, find.text(label)));
        expect(ink.toARGB32(), isNot(_darkOn), reason: label);
        expect(ratio(ink, pill), greaterThan(4.5), reason: label);
      }
    });

    testWidgets('결제 화면의 이미 산(꺼진) 채운 단추는 어두운 모드에서 sealOn 으로 묻히지 않는다', (
      tester,
    ) async {
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
      // Owned = disabled grey pill: the label falls back to the button's own
      // disabled colour instead of the dark-gold sealOn.
      expect(tester.widget<Text>(label).style!.color, isNull);
      expect(textColor(tester, label), isNot(_darkOn));
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

  group('L4. 홈 목록 날짜', () {
    for (final scale in [1.5, 2.0]) {
      testWidgets('글자 $scale: 두 자리 날짜 숫자도 한 줄, 날짜 칸 안', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = makeStore(tester);
        store.create(
          at: DateTime(2026, 9, 17, 9),
          blocks: [
            ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
          ],
        );
        await pumpApp(tester, NotesListPage(store: store, onOpen: (_) {}));
        final day = find.text('17');
        // One line of the 20 pt number (height 1.15), not '1 / 7'.
        expect(
          tester.getSize(day).height,
          lessThan(
            MediaQuery.textScalerOf(tester.element(day)).scale(20) * 1.15 * 1.5,
          ),
        );
        expect(tester.getRect(day).width, lessThanOrEqualTo(34.01));
        await tester.pump(const Duration(seconds: 1));
      });
    }
  });

  group('L5. 입력 줄의 세트 라벨', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('글자 $scale: 라벨과 자리표시 사이에 틈이 남는다', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final c = RoutineEditorController()
          ..addExercise('벤치프레스')
          ..addSet('80 5')
          ..addSet('80 5')
          ..addSet('80 5');
        await pumpApp(
          tester,
          CupertinoPageScaffold(
            child: SafeArea(child: RoutineEditor(controller: c)),
          ),
        );
        final label = tester.getRect(find.text('4세트'));
        final line = tester.getRect(find.byType(CupertinoTextField));
        // Not "4세트무게": the label never runs into the weight hint.
        expect(line.left - label.right, greaterThanOrEqualTo(5.99));
      });
    }
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
      expect(
        tester.takeAnnouncements().map((a) => a.message),
        contains('${l.setRemoved(2)} · ${l.undo}'),
        reason: '보조기기에도 되돌릴 수 있다고 알린다',
      );
      final undo = find.byKey(const ValueKey('set-undo'));
      expect(tester.getSize(undo).height, greaterThanOrEqualTo(44));
      await tester.tap(undo);
      await tester.pumpAndSettle();
      expect(c.blocks.single.sets, hasLength(3));
      expect(c.blocks.single.sets[1].value, middle.value);
      expect(c.blocks.single.sets[1].reps, 8);
      expect(find.byKey(const ValueKey('set-undo')), findsNothing);
    });

    testWidgets('같이 하는 중에는 세트 되돌리기를 내지 않는다(위치·주인을 서버와 맞출 수 없다)', (
      tester,
    ) async {
      final dir = Directory.systemTemp.createTempSync('setpad_ux_together_');
      final store = NotesStore(directory: dir);
      final note = store.create()
        ..partner = PartnerSession(
          id: 'S1',
          host: true,
          state: PartnerState.active,
        );
      final partner = PartnerSync(
        note: note,
        link: () => GymLink(
          endpoint: 'https://example.com',
          token: 'x',
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
        onChanged: () {},
      );
      addTearDown(() {
        partner.dispose();
        store.dispose();
        dir.deleteSync(recursive: true);
      });
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 10')
        ..addSet('70 8')
        ..closeBlock();
      await pumpApp(
        tester,
        CupertinoPageScaffold(
          child: RoutineEditor(controller: c, partner: partner),
        ),
      );
      await tester.tap(find.text('2 70×8'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.xmark).first);
      await tester.pumpAndSettle();
      expect(c.blocks.single.sets, hasLength(1));
      expect(find.byKey(const ValueKey('set-undo')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('지운 바로 뒤 같이 하기가 시작되면 되돌리기 줄을 거둔다', (tester) async {
      final dir = Directory.systemTemp.createTempSync('setpad_ux_join_');
      final store = NotesStore(directory: dir);
      final note = store.create();
      final partner = PartnerSync(
        note: note,
        link: () => GymLink(
          endpoint: 'https://example.com',
          token: 'x',
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
        onChanged: () {},
      );
      addTearDown(() {
        partner.dispose();
        store.dispose();
        dir.deleteSync(recursive: true);
      });
      final c = RoutineEditorController()
        ..addExercise('벤치프레스')
        ..addSet('80 10')
        ..addSet('70 8')
        ..closeBlock();
      Future<void> show() => pumpApp(
        tester,
        CupertinoPageScaffold(
          child: RoutineEditor(controller: c, partner: partner),
        ),
      );
      await show();
      await tester.tap(find.text('2 70×8'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.xmark).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('set-undo')), findsOneWidget);
      note.partner = PartnerSession(
        id: 'S1',
        host: true,
        state: PartnerState.active,
      );
      await show();
      expect(find.byKey(const ValueKey('set-undo')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 6));
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

    testWidgets('목록을 내려 지워도 되돌리기가 화면에 보이고, 위의 줄들은 밀리지 않으며, 보조기기에 알린다', (
      tester,
    ) async {
      final store = makeStore(tester);
      final notes = [
        for (var i = 0; i < 60; i++)
          store.create(
            at: DateTime.now().subtract(Duration(days: i + 1)),
            blocks: [
              ExerciseBlock('스쿼트 $i', [LoggedSet(value: 80, reps: 5)]),
            ],
          ),
      ];
      await pumpApp(tester, NotesListPage(store: store, onOpen: (_) {}));
      final l = await L.delegate.load(const Locale('ko'));
      final gone = notes[20];
      await tester.scrollUntilVisible(
        rowOf(gone),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      double top(Note n) => tester.getTopLeft(rowOf(n)).dy;
      // The nearest row drawn above the one we delete.
      final above = notes
          .where((n) => n != gone && rowOf(n).evaluate().isNotEmpty)
          .where((n) => top(n) < top(gone))
          .reduce((a, b) => top(a) > top(b) ? a : b);
      final y = top(above);
      await tester.drag(rowOf(gone), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.delete).last);
      await tester.pumpAndSettle();
      final undo = find.byKey(const ValueKey('note-undo'));
      expect(undo.hitTestable(), findsOneWidget, reason: '스크롤한 채로도 누를 수 있다');
      expect(top(above), y, reason: '위의 줄이 밀리지 않는다');
      expect(
        tester.takeAnnouncements().map((a) => a.message),
        contains('${l.noteRemoved} · ${l.undo}'),
      );
      await tester.tap(undo);
      await tester.pumpAndSettle();
      expect(store.notes, contains(gone));
      expect(top(above), y);
      expect(undo, findsNothing);
      await tester.pump(const Duration(seconds: 6));
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

    test('되돌리기 창 안에 새 기록을 만들면 되돌리기를 거둔다 — 같은 쌤 루틴이 둘이 되지 않는다', () {
      final dir = Directory.systemTemp.createTempSync('setpad_ux_undo_new_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = NotesStore(directory: dir);
      addTearDown(store.dispose);
      final first = store.create(
        gymId: 'g1',
        routineId: 'r1',
        blocks: [
          ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
        ],
      );
      store.delete(first);
      expect(store.undoableDelete, same(first));
      // The trainer routine row is back at once; tapping it starts r1 again.
      store.create(gymId: 'g1', routineId: 'r1');
      expect(store.undoableDelete, isNull);
      expect(store.heldDeletes, isEmpty, reason: '거둔 지우기는 이제 서버로 간다');
      expect(store.undoDelete(), isFalse);
      expect(store.notes.where((n) => n.routineId == 'r1'), hasLength(1));
    });

    test('되돌리기가 열린 동안에는 동기화가 그 지우기를 서버로 보내지 않는다', () async {
      final dir = Directory.systemTemp.createTempSync('setpad_ux_hold_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = NotesStore(directory: dir);
      addTearDown(store.dispose);
      final calls = <String>[];
      final link = GymLink(
        endpoint: 'https://example.com',
        token: 'x',
        client: MockClient((r) async {
          calls.add('${r.method} ${r.url.path}');
          return http.Response('{"ok":true}', 200);
        }),
      );
      final note = store.create(gymId: 'g1');
      store.delete(note);
      // A sync (editor close, app resume) runs while the undo line is up.
      await sendDeletes(
        link,
        store.pendingDeletes,
        onSent: () {},
        held: store.heldDeletes,
      );
      expect(calls, isEmpty, reason: '되돌릴 수 있는 동안은 서버를 건드리지 않는다');
      expect(store.undoDelete(), isTrue);
      expect(store.notes, [note]);
      expect(store.pendingDeletes, isEmpty);

      // Once the window closes, the delete goes out.
      store.delete(note);
      store.forgetUndoableDelete();
      await sendDeletes(
        link,
        store.pendingDeletes,
        onSent: () {},
        held: store.heldDeletes,
      );
      expect(calls, ['DELETE /api/workouts']);
      expect(store.pendingDeletes, isEmpty);
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

    testWidgets(
      '늘 보이는 ≡ 위에서 시작한 스크롤은 순서 바꾸기가 되지 않고, 길게 눌러야 끌린다 — 타이머는 그대로 돈다',
      (tester) async {
        var now = Duration.zero;
        final timer = WorkoutTimer(audio: FakeAudio(), now: () => now);
        addTearDown(timer.dispose);
        final c = RoutineEditorController();
        for (var i = 0; i < 8; i++) {
          c
            ..addExercise('운동 ${i + 1}')
            ..addSet('50 10')
            ..closeBlock();
        }
        c.blocks.first.name = '버피 60 bpm';
        final spec = TimingSpec.parse(c.blocks.first.name)!;
        timer.toggle(c.blocks.first, spec);
        expect(timer.running, isTrue);
        await pumpApp(
          tester,
          CupertinoPageScaffold(
            child: RoutineEditor(controller: c, timer: timer),
          ),
        );
        final more = find.byIcon(CupertinoIcons.ellipsis);
        final before = more.evaluate().length;
        expect(before, greaterThan(0));
        final handle = find.byIcon(CupertinoIcons.line_horizontal_3).at(1);

        // A quick flick that happens to start on the handle scrolls the list.
        final scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        final top = scrollable.position.pixels;
        await tester.dragFrom(
          tester.getCenter(handle),
          const Offset(-20, -300),
        );
        await tester.pumpAndSettle();
        expect(more.evaluate().length, before, reason: '카드가 접히지 않았다');
        expect(scrollable.position.pixels, greaterThan(top), reason: '스크롤됐다');
        expect(timer.running, isTrue);

        // A long press on the handle starts the reorder; the timer keeps going.
        final g = await tester.startGesture(tester.getCenter(handle));
        await tester.pump(
          kLongPressTimeout + const Duration(milliseconds: 100),
        );
        await g.moveBy(const Offset(0, 40));
        await tester.pump();
        await tester.pump();
        expect(more, findsNothing, reason: '순서 바꾸기 모드는 모든 카드를 접는다');
        expect(timer.running, isTrue);
        await g.up();
        await tester.pumpAndSettle();
        expect(timer.running, isTrue);
        timer.pause();
      },
    );

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

    testWidgets('남이 적은 세트는 길게 눌러도 끌리지 않는다 — 내 세트만 끌리고 안내도 그때', (tester) async {
      dragHintShown = false;
      final c = RoutineEditorController()
        ..restore([
          ExerciseBlock('스쿼트', [
            LoggedSet(id: 'a', value: 60, unit: 'kg', reps: 10, author: '준'),
            LoggedSet(id: 'b', value: 80, unit: 'kg', reps: 8),
            LoggedSet(id: 'c', value: 90, unit: 'kg', reps: 6),
          ]),
        ]);
      await pumpApp(
        tester,
        CupertinoPageScaffold(child: RoutineEditor(controller: c)),
      );
      final l = await L.delegate.load(const Locale('ko'));
      Future<void> drag(int from, int to) async {
        final g = await tester.startGesture(
          tester.getCenter(find.byKey(ValueKey('set-cell-$from'))),
        );
        await tester.pump(
          kLongPressTimeout + const Duration(milliseconds: 100),
        );
        await g.moveTo(tester.getCenter(find.byKey(ValueKey('set-cell-$to'))));
        await tester.pump();
        await g.up();
        await tester.pump();
      }

      await drag(0, 2);
      expect(c.blocks.single.sets.map((s) => s.id), ['a', 'b', 'c']);
      expect(find.text(l.setDragHint), findsNothing);
      await drag(2, 1);
      expect(c.blocks.single.sets.map((s) => s.id), ['a', 'c', 'b']);
      expect(find.text(l.setDragHint), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
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

    for (final (width, scale) in [(430.0, 1.5), (375.0, 2.0), (375.0, 1.0)]) {
      testWidgets(
        '${width.round()}pt·글자 $scale: 키패드 글자는 낱말 가운데서 끊기지 않고 두 열 바닥이 맞는다',
        (tester) async {
          tester.view.physicalSize = Size(width, 812);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(() {
            tester.view.reset();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
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
                  submitLabel: '운동 완료',
                  onText: () {},
                  onAdjust: (_) {},
                  stepLabel: '2.5kg',
                  onStepPick: () {},
                  onRepeat: () {},
                  repeatLabel: '65kg · 8회',
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          // One line each: '2.5k/g' and '세트 추/가' broke inside the word.
          final texts = find.descendant(
            of: find.byType(SetKeypad),
            matching: find.byType(RichText),
          );
          expect(texts, findsWidgets);
          for (final e in texts.evaluate()) {
            final p = e.renderObject! as RenderParagraph;
            final all = p.text.toPlainText();
            final tops = p
                .getBoxesForSelection(
                  TextSelection(baseOffset: 0, extentOffset: all.length),
                )
                .map((b) => b.top.round())
                .toSet();
            expect(tops, hasLength(1), reason: '"$all" 한 줄');
          }
          Rect face(String label) => tester.getRect(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          // The number grid and the action column end on the same line.
          expect(face('0').bottom, moreOrLessEquals(face('운동 완료').bottom));
          expect(
            face('1').top,
            moreOrLessEquals(face('−').top - 52, epsilon: 0.5),
          );
          // Keys keep their size; the text fits the key, not the other way.
          expect(face('1').height, moreOrLessEquals(46));
        },
      );
    }

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

  testWidgets('운동 제목 아래 목표 진행 줄을 누르면 이름 고치기가 아니라 카드가 열린다', (tester) async {
    final c = RoutineEditorController()
      ..addExercise('벤치', setup: const WorkoutSetup(name: '벤치', totalSets: 5))
      ..addSet('80 10')
      ..closeBlock();
    await pumpApp(
      tester,
      CupertinoPageScaffold(child: RoutineEditor(controller: c)),
    );
    final l = await L.delegate.load(const Locale('ko'));
    final progress = find.textContaining(l.setProgress(1, 5));
    expect(progress, findsOneWidget);
    expect(c.activeIndex, isNot(0));
    await tester.tap(progress);
    await tester.pumpAndSettle();
    expect(c.activeIndex, 0, reason: '카드가 열린다');
    expect(find.byType(SetKeypad), findsOneWidget, reason: '세트 입력 키패드');
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
      final note = find.text(keepAll(l.aiSettingNote));
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

    test('keepAll: 한글 낱말 안에만 이음 표지, 라틴 낱말과 띄어쓰기는 그대로', () {
      expect(
        keepAll('여기서 받아요. AI 로'),
        '여\u200D기\u200D서 받\u200D아\u200D요\u200D. AI 로',
      );
    });

    testWidgets('안내 행과 꼬리글은 낱말 가운데서 줄을 바꾸지 않는다', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      await openSettings(tester, account: member());
      final l = await L.delegate.load(const Locale('ko'));
      expectWordBreaks(tester, find.text(keepAll(l.aiSettingNote)));
      // The screen reader reads the sentence as written.
      expect(find.bySemanticsLabel(l.aiSettingNote), findsOneWidget);
      final notice = find.text(keepAll(l.settingsNoGym));
      await tester.scrollUntilVisible(notice, 100);
      expectWordBreaks(tester, notice);
      semantics.dispose();
    });

    testWidgets('닉네임은 한 줄이다 — 이름이 값이고 누르면 바꾼다', (tester) async {
      final account = member();
      await openSettings(tester, account: account);
      final l = await L.delegate.load(const Locale('ko'));
      final row = find.byKey(const ValueKey('settings-nickname'));
      await tester.scrollUntilVisible(row, 200); // lazy list: build it first
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

    testWidgets('다니는 곳이 없으면 묶음 안에 흐린 안내 행을, 있으면 도장 줄과 식단 공유를 둔다', (
      tester,
    ) async {
      final account = member();
      await openSettings(tester, account: account);
      final l = await L.delegate.load(const Locale('ko'));
      final notice = find.text(keepAll(l.settingsNoGym));
      await tester.scrollUntilVisible(notice, 100); // lazy list: build it first
      expect(notice, findsOneWidget);
      // A row in the gym section's box — not a header and a caption over nothing.
      final row = find.ancestor(of: notice, matching: find.byType(SettingsRow));
      expect(tester.widget<SettingsRow>(row).muted, isTrue);
      expect(tester.widget<SettingsRow>(row).onTap, isNull);
      expect(
        find.descendant(
          of: find.ancestor(
            of: row,
            matching: find.byType(CupertinoListSection),
          ),
          matching: find.text(l.settingsGym),
        ),
        findsOneWidget,
      );
      account.gyms = [const Gym(id: 'g1', name: 'BPM')];
      account.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text(keepAll(l.settingsNoGym)), findsNothing);
      expect(find.byKey(const ValueKey('settings-gym-g1')), findsOneWidget);
      final share = find.byKey(const ValueKey('settings-share-meals'));
      await tester.scrollUntilVisible(share, 100);
      expect(share, findsOneWidget);
    });

    testWidgets('머리글 없는 묶음은 꼬리글이 설명하는 한 줄과 맨 끝 라이선스뿐, 빈 묶음은 없다', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final gyms in [
        const <Gym>[],
        [const Gym(id: 'g1', name: 'BPM')],
      ]) {
        await openSettings(tester, account: member(gyms: gyms));
        final sections = tester
            .widgetList<CupertinoListSection>(find.byType(CupertinoListSection))
            .toList();
        expect(sections.length, greaterThanOrEqualTo(5));
        for (final (i, s) in sections.indexed) {
          final rows = s.children ?? const <Widget>[];
          expect(rows, isNotEmpty, reason: '묶음 $i 에 행이 있다');
          final explainedToggle = rows.length == 1 && s.footer != null;
          final licenses =
              i == sections.length - 1 &&
              rows.single.key == const ValueKey('settings-licenses');
          expect(
            s.header != null || explainedToggle || licenses,
            isTrue,
            reason: '묶음 $i(${rows.map((r) => r.key).join(', ')}) 에 머리글이 있다',
          );
        }
      }
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

    for (final scale in [1.0, 2.0]) {
      testWidgets('375pt·글자 $scale: 긴 라벨은 감기고, 20자 닉네임·로그인 실패 문구도 넘치지 않는다', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(375, 1600);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(() {
          tester.view.reset();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        final l = await L.delegate.load(const Locale('ko'));
        final nickname = '가' * 20;
        await pumpApp(
          tester,
          CupertinoPageScaffold(
            child: ListView(
              children: [
                SettingsSection(
                  children: [
                    SettingsRow(
                      label: l.proPaid(300, 20),
                      accent: true,
                      onTap: () {},
                    ),
                    SettingsRow(
                      label: l.nicknameLabel,
                      detail: nickname,
                      onTap: () {},
                    ),
                    SettingsRow(
                      label: l.linkSignIn('Apple'),
                      note: l.signInTaken,
                      onTap: () {},
                    ),
                    SettingsToggle(
                      label: l.proPaid(300, 20),
                      value: true,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: '넘침 없음');
        bool cut(Finder text) => tester
            .renderObjectList<RenderParagraph>(
              find.descendant(of: text, matching: find.byType(RichText)),
            )
            .any((p) => p.didExceedMaxLines);
        for (final t in find.text(l.proPaid(300, 20)).evaluate()) {
          expect(
            cut(find.byWidget(t.widget)),
            isFalse,
            reason: '혜택 문구가 잘리지 않는다',
          );
        }
        expect(cut(find.text(l.signInTaken)), isFalse);
        expect(
          tester.getSize(find.text(l.nicknameLabel)).width,
          greaterThan(30),
          reason: '긴 닉네임이 라벨을 0폭으로 밀지 않는다',
        );
      });
    }

    testWidgets('대화상자 본문은 13', (tester) async {
      final account = member();
      await openSettings(tester, account: account);
      final l = await L.delegate.load(const Locale('ko'));
      final row = find.byKey(const ValueKey('settings-sign-out-everywhere'));
      await tester.scrollUntilVisible(row, 200); // lazy list: build it first
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

    testWidgets('목록을 받았는데 그 도장이 없으면 끝없이 돌지 않고 회원이 아니라고 말한다', (tester) async {
      final account =
          Account(client: MockClient((_) async => http.Response('{}', 404)))
            ..token = 'member'
            ..gyms = []
            ..gymsLoaded = true;
      await pumpApp(
        tester,
        GymPage(account: account, store: makeStore(tester), gymId: 'g1'),
      );
      final l = await L.delegate.load(const Locale('ko'));
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
      expect(find.text(l.gymLinkNotMember), findsOneWidget);
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
      // The consent notice is the text of a recorded consent version
      // (gymConsentVersion / server GYM_CONSENT_VERSION): it stays word for word
      // until both versions are bumped together.
      expect(l.gymConsentNotice, startsWith('등록하면 이 도장의 관장·트레이너가'));
      // The trainer's own screens keep the word.
      expect(l.trainerWhichGym, contains('도장'));
      expect(l.gymPolicy, contains('도장'));
    });

    test('스페인어 AI 도움 설명은 IA 를 여성형으로 쓴다', () async {
      final es = await L.delegate.load(const Locale('es'));
      expect(es.aiSettingNote, contains('una IA'));
      expect(es.aiSettingNote, isNot(contains('un IA')));
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
