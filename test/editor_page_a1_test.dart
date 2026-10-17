// The record page around my editor: it opens at the top, keeps my editor
// (and its run) while writing for someone, and asks before a run is dropped.
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/account.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';
import 'package:setpad/run_page.dart';

import 'package:setpad/gym.dart';
import 'package:setpad/shared_timer.dart';
import 'package:setpad/workout_timing.dart';

import 'handoff_test.dart' show Server;
import 'partner_groups_test.dart' show Scripted;
import 'workout_timing_test.dart' show FakeAudio;

/// Pushes the record page over a home page; returns before the push settles.
Future<(NotesStore, Note, GlobalKey<NavigatorState>)> push(
  WidgetTester tester,
  List<ExerciseBlock> blocks, {
  bool partner = false,
  EditorDraft? draft,
}) async {
  final dir = Directory.systemTemp.createTempSync('a1_');
  final store = NotesStore(directory: dir);
  addTearDown(() {
    store.dispose();
    dir.deleteSync(recursive: true);
  });
  final account = partner
      ? (Account(storageDir: dir, client: Server().client)..token = 'member')
      : null;
  final note = store.create(blocks: blocks)..draft = draft;
  if (partner) {
    note.partner = PartnerSession(
      id: 'S1',
      host: true,
      state: PartnerState.active,
      partnerName: '준',
    );
  }
  // The tabata's permission asks answer at once (no platform here).
  const alarm = MethodChannel('setpad/rest_alarm');
  final messenger = tester.binding.defaultBinaryMessenger
    ..setMockMethodCallHandler(alarm, (_) async => false);
  addTearDown(() => messenger.setMockMethodCallHandler(alarm, null));
  final nav = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    CupertinoApp(
      navigatorKey: nav,
      locale: const Locale('ko'),
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: const CupertinoPageScaffold(child: SizedBox()),
    ),
  );
  nav.currentState!.push(
    CupertinoPageRoute<void>(
      builder: (_) => EditorPage(store: store, note: note, account: account),
    ),
  );
  await tester.pump();
  return (store, note, nav);
}

ScrollPosition list(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

Future<void> close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  final today = [
    ExerciseBlock('벤치프레스', [
      for (final r in [12, 10, 8, 8]) LoggedSet(value: 60, reps: r),
    ]),
    ExerciseBlock('버피 타바타 20/10 x8'),
    ExerciseBlock('푸시업 60bpm'),
    ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
    ExerciseBlock('로우', [
      for (var i = 0; i < 3; i++) LoggedSet(value: 50, reps: 10),
    ]),
  ];

  testWidgets('a record opens with its date row whole: a caret reveal on '
      'the settling layout does not leave the list a few points down', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await push(tester, [
      for (final b in today) ExerciseBlock(b.name, [...b.sets]),
    ], draft: const EditorDraft(text: '', block: 0));
    await tester.pump(const Duration(milliseconds: 50));
    expect(list(tester).maxScrollExtent, greaterThan(26));
    // What the cold start showed: the list 26 pt down mid-push.
    list(tester).jumpTo(26);
    await tester.pumpAndSettle();
    expect(list(tester).pixels, 0);
    await close(tester);
  });

  testWidgets('the line being typed at the end of a long record still '
      'shows when it opens', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await push(tester, [
      for (final n in ['벤치', '스쿼트', '데드', '로우', '런지', '컬'])
        ExerciseBlock(n, [
          for (var i = 0; i < 6; i++) LoggedSet(value: 100, reps: 5),
        ]),
    ]);
    await tester.pumpAndSettle();
    expect(list(tester).pixels, greaterThan(0));
    await close(tester);
  });

  testWidgets('writing for my partner keeps my editor: the folded timer '
      'keeps going and sounding, and is there when I come back', (
    tester,
  ) async {
    final configured = <bool>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('setpad/timing'),
      (c) async {
        if (c.method == 'configure') {
          configured.add((c.arguments as Map)['active'] as bool);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('setpad/timing'),
        null,
      ),
    );
    await push(tester, [ExerciseBlock('버피 타바타 20/10 x8')], partner: true);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(RunPage))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('timer-strip-number')), findsOneWidget);

    configured.clear();
    await tester.tap(find.byKey(const ValueKey('write-for')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('proxy-bar')), findsOneWidget);
    expect(configured, isNot(contains(false)), reason: 'still sounding');
    expect(find.byType(RunPage), findsNothing);

    await tester.tap(find.text('내 기록으로'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('timer-strip-number')), findsOneWidget);
    await close(tester);
  });

  testWidgets('done, back or the system back with a timer going asks; '
      'stop and leave closes the record', (tester) async {
    final (_, _, nav) = await push(tester, [ExerciseBlock('버피 타바타 20/10 x8')]);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('timer-start')));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(RunPage))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(find.text('도는 타이머를 멈추고 나갈까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(EditorPage), findsOneWidget);

    // The system back (Android) goes the same way.
    await nav.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('도는 타이머를 멈추고 나갈까요?'), findsOneWidget);
    await tester.tap(find.text('멈추고 나가기'));
    await tester.pumpAndSettle();
    expect(find.byType(EditorPage), findsNothing);
    await close(tester);
  });

  testWidgets('nothing running: done closes at once', (tester) async {
    await push(tester, [
      ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
    ]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(find.byType(EditorPage), findsNothing);
    await close(tester);
  });

  testWidgets('my editor kept behind the proxy one follows a shared run but '
      'does not open the stage over it', (tester) async {
    final server = Scripted();
    server.state = {
      ...server.state,
      'timer': {
        'seq': 1,
        'title': '스쿼트 60bpm',
        'alternate': false,
        'mine': false,
        'joined': true,
        'startAt': 1700000000000 - 20000,
        'spec': {
          'bpm': 60,
          'tabata': false,
          'work': 20,
          'rest': 10,
          'rounds': 8,
        },
        'myLeft': null,
        'partnerLeft': null,
      },
    };
    final note =
        Note(
            id: 'n1',
            createdAt: DateTime(2026, 9, 21),
            updatedAt: DateTime(2026, 9, 21),
          )
          ..partner = PartnerSession(
            id: 'S1',
            host: true,
            state: PartnerState.active,
          );
    final sync = PartnerSync(
      note: note,
      clock: ServerClock(monotonic: () => Duration.zero),
      link: () =>
          GymLink(endpoint: 'https://x', token: 'me', client: server.client),
      onChanged: () {},
    );
    final timer = WorkoutTimer(audio: FakeAudio(), now: () => Duration.zero);
    final c = RoutineEditorController()..addExercise('스쿼트 60bpm');
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: CupertinoPageScaffold(
          resizeToAvoidBottomInset: false,
          child: SafeArea(
            // What the record page does while I write for someone.
            child: TickerMode(
              enabled: false,
              child: RoutineEditor(controller: c, partner: sync, timer: timer),
            ),
          ),
        ),
      ),
    );
    await sync.refresh();
    await tester.pumpAndSettle();
    expect(timer.running && timer.shared, isTrue);
    expect(find.byType(RunPage), findsNothing);
    await tester.pumpWidget(const SizedBox());
    sync.dispose();
    timer.dispose();
  });
}
