// 세트 무대 편집기 연결(focus-stage-1.8 §8, 레인 E) — logFocusSet·되돌리기, 시작 칸,
// 무대 포트·mux, 휴식 띠, 편집기를 닫으면 휴식·알림 멈춤, 같이 하는 타이머 띠,
// 심박 조건, 알림 권한 한 번, 노트 페이지 ▶·설정 휴식 기본·운동별 휴식.
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/focus.dart';
import 'package:setpad/focus_link.dart';
import 'package:setpad/focus_page.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/rest_recovery.dart';
import 'package:setpad/rest_timer.dart';
import 'package:setpad/run_page.dart';
import 'package:setpad/settings_page.dart';
import 'package:setpad/record_query.dart' show exerciseKey;
import 'package:setpad/workout_timing.dart';

import 'package:setpad/account.dart';
import 'package:setpad/partner.dart';

import 'partner_groups_test.dart' show Scripted;
import 'rest_recovery_test.dart' show FakeHealth;
import 'workout_timing_test.dart' show FakeAudio;

Widget app(Widget child) => CupertinoApp(
  locale: const Locale('ko'),
  supportedLocales: L.supportedLocales,
  localizationsDelegates: L.localizationsDelegates,
  home: CupertinoPageScaffold(
    resizeToAvoidBottomInset: false,
    child: SafeArea(child: child),
  ),
);

class FakeNotifier implements RestNotifier {
  final log = <String>[];
  @override
  Future<void> schedule(DateTime at, String title, String body) async =>
      log.add('schedule $title $body');
  @override
  Future<void> cancel() async => log.add('cancel');
}

FocusLink stageLink(WidgetTester tester) =>
    tester.widget<FocusPage>(find.byType(FocusPage)).link;

Future<void> fold(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(FocusPage))).pop();
  await tester.pumpAndSettle();
}

LoggedSet planned(double v, int reps) =>
    LoggedSet(value: v, reps: reps, done: false);

void main() {
  group('logFocusSet', () {
    test('계획 세트는 plannedId 로 다시 찾는다 — 제안 뒤 상대 세트가 앞에 끼어도 같은 세트가 해냄', () {
      final p1 = planned(80, 5), p2 = planned(80, 5);
      final b = ExerciseBlock('벤치프레스', [
        LoggedSet(value: 60, reps: 10),
        p1,
        p2,
      ]);
      final c = RoutineEditorController()..restore([b]);
      final s = nextSet(b, const [], key: 'bench');
      expect(s.plannedId, p1.id);

      // A partner's set comes in before the planned one.
      final theirs = LoggedSet(value: 100, reps: 3, author: '준');
      c.replaceBlocks([
        ExerciseBlock(b.name, [b.sets[0], theirs, p1, p2], null, b.id),
      ]);
      final id = c.logFocusSet(b, s.plannedId, LoggedSet(value: 82.5, reps: 5));
      expect(id, p1.id);
      final written = b.sets.firstWhere((x) => x.id == p1.id);
      expect([written.value, written.reps, written.done], [82.5, 5, true]);
      expect(b.sets.length, 4, reason: 'no new set');
      expect(b.sets[1].value, 100, reason: 'their set untouched');
      expect(b.sets[3].done, isFalse);
    });

    test('계획이 없거나 이미 해냈으면 새 세트, 무게 0 은 맨몸, 남의 세트는 고치지 않는다', () {
      final theirs = LoggedSet(value: 50, reps: 8, author: '준', done: false);
      final done = LoggedSet(value: 70, reps: 5);
      final b = ExerciseBlock('턱걸이', [theirs, done]);
      final c = RoutineEditorController()..restore([b]);
      var notified = 0;
      c.addListener(() => notified++);

      final a = c.logFocusSet(b, null, LoggedSet(value: 0, reps: 12))!;
      expect(b.sets.last.id, a);
      expect(
        [b.sets.last.value, b.sets.last.reps, b.sets.last.done],
        [null, 12, true],
      );
      final t = c.logFocusSet(b, theirs.id, LoggedSet(value: 60, reps: 6))!;
      expect(t, isNot(theirs.id));
      expect([theirs.value, theirs.done], [50, false]);
      final d = c.logFocusSet(b, done.id, LoggedSet(value: 72.5, reps: 5))!;
      expect(d, isNot(done.id));
      expect(done.value, 70);
      expect(b.sets.length, 5);
      expect(notified, 3, reason: 'each write goes the save/push path');
      expect(
        c.logFocusSet(ExerciseBlock('없는 칸'), null, LoggedSet(reps: 1)),
        isNull,
      );
    });

    test('되돌리기: 새 세트는 지우고, 계획 세트는 옛 값·○ 로', () {
      final p = planned(80, 5);
      final b = ExerciseBlock('스쿼트', [p]);
      final c = RoutineEditorController()..restore([b]);
      final pid = c.logFocusSet(b, p.id, LoggedSet(value: 85, reps: 4))!;
      final nid = c.logFocusSet(b, null, LoggedSet(value: 85, reps: 4))!;
      expect(b.sets.length, 2);
      c.undoFocusSet(b, nid);
      expect(b.sets.map((s) => s.id), [pid]);
      b.sets.single.notes.add('무릎');
      c.undoFocusSet(b, pid);
      final back = b.sets.single;
      expect([back.id, back.value, back.reps, back.done], [p.id, 80, 5, false]);
      expect(back.notes, ['무릎'], reason: 'a note added since stays');
      // Only what the stage wrote, once.
      c.undoFocusSet(b, pid);
      expect(b.sets.single.done, isFalse);
      final other = LoggedSet(value: 1, reps: 1);
      b.sets.add(other);
      c.undoFocusSet(b, other.id);
      expect(b.sets.length, 2);
    });
  });

  group('편집기 연결', () {
    late FakeAudio audio;
    late Duration now;
    late RestTimer rest;
    late FakeNotifier notifier;
    setUp(() {
      audio = FakeAudio();
      now = Duration.zero;
      notifier = FakeNotifier();
      rest = RestTimer(
        audio: FakeAudio(),
        now: () => now,
        haptic: (_) {},
        notifier: notifier,
      );
    });
    tearDown(() => rest.dispose());

    Future<void> advance(WidgetTester tester, Duration to) async {
      now = to;
      rest.tick();
      await tester.pump();
    }

    testWidgets('history 가 없으면(대신 적기) 무대가 없고, 있으면 시작 칸 규칙대로 연다', (
      tester,
    ) async {
      final c = RoutineEditorController()..addExercise('푸시업');
      await tester.pumpWidget(app(RoutineEditor(controller: c, audio: audio)));
      expect(c.openFocus, isNull);

      final a = ExerciseBlock('벤치', [LoggedSet(value: 60, reps: 10)]);
      final b = ExerciseBlock('로우', [planned(50, 10)]);
      final d = ExerciseBlock('컬', [LoggedSet(value: 10, reps: 12)]);
      final c2 = RoutineEditorController()..restore([a, b, d]);
      var asked = 0;
      await tester.pumpWidget(
        app(
          RoutineEditor(
            key: const ValueKey('own'),
            controller: c2,
            audio: audio,
            history: () => const [],
            askRestNotify: () async => asked++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(c2.openFocus, isNotNull);

      // No cursor: the first block with a planned ○ left.
      c2.openFocus!();
      await tester.pumpAndSettle();
      expect(stageLink(tester).currentId, b.id);
      expect(audio.calls.last.active, isTrue, reason: 'stage keeps it on');
      await fold(tester);
      expect(audio.calls.last.active, isFalse);

      // The cursor's block first.
      c2.openBlock(2);
      await tester.pump();
      c2.openFocus!();
      await tester.pumpAndSettle();
      expect(stageLink(tester).currentId, d.id);
      await fold(tester);

      // Nothing planned, no cursor: the last block.
      c2.closeBlock();
      c2.logFocusSet(b, b.sets.single.id, LoggedSet(value: 50, reps: 10));
      await tester.pump();
      c2.openFocus!();
      await tester.pumpAndSettle();
      expect(stageLink(tester).currentId, d.id);
      expect(stageLink(tester).blocks, [a, b, d]);
      await fold(tester);
      expect(asked, 1, reason: 'the notification permission once');

      await tester.pumpWidget(const SizedBox());
      expect(c2.openFocus, isNull);
    });

    testWidgets('링크: 제안은 지난 기록에서, 쓰기·되돌리기는 컨트롤러로, 휴식 길이는 운동 key 로', (
      tester,
    ) async {
      final b = ExerciseBlock('벤치프레스');
      final c = RoutineEditorController()..restore([b]);
      final earlier = Note(
        id: 'n0',
        createdAt: DateTime(2026, 10, 10),
        updatedAt: DateTime(2026, 10, 10),
        blocks: [
          ExerciseBlock('벤치프레스', [
            LoggedSet(value: 70, reps: 8),
            LoggedSet(value: 75, reps: 6),
          ]),
        ],
      );
      final saved = <(String, int)>[];
      await tester.pumpWidget(
        app(
          RoutineEditor(
            controller: c,
            audio: audio,
            rest: rest,
            history: () => [earlier],
            restFor: (key) => key == exerciseKeyOf(b) ? 120 : 90,
            onRestChanged: (key, s) => saved.add((key, s)),
          ),
        ),
      );
      c.openFocus!();
      await tester.pumpAndSettle();
      final link = stageLink(tester);
      final s = link.suggest!(b);
      expect(s.source, FocusSource.lastTime);
      expect([s.values.value, s.values.reps], [70, 8]);
      expect(link.lastTime!(b)!.sets.length, 2);
      expect(link.restFor!(b), const Duration(seconds: 120));
      link.onRestChanged!(b, const Duration(seconds: 135));
      expect(saved, [(exerciseKeyOf(b), 135)]);

      final id = link.onLog!(b, s.plannedId, s.values)!;
      expect(b.sets.single.id, id);
      // The UX lane's "set removed · undo" line is not this path's.
      link.onUndo!(b, id);
      await tester.pump();
      expect(b.sets, isEmpty);
      expect(find.text('되돌리기'), findsNothing);
      await fold(tester);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('접은 뒤 휴식이 돌면 편집기 위 띠 — 탭하면 그 칸으로 무대, 끝나면 사라진다', (tester) async {
      final a = ExerciseBlock('벤치', [LoggedSet(value: 60, reps: 10)]);
      final b = ExerciseBlock('로우', [LoggedSet(value: 50, reps: 10)]);
      final c = RoutineEditorController()..restore([a, b]);
      await tester.pumpWidget(
        app(
          RoutineEditor(
            controller: c,
            audio: audio,
            rest: rest,
            history: () => const [],
          ),
        ),
      );
      c.openFocus!();
      await tester.pumpAndSettle();
      final link = stageLink(tester);
      link.rest.start(a, const Duration(seconds: 90));
      await tester.pump();
      expect(find.byKey(const ValueKey('focus-rest-strip')), findsNothing);
      await fold(tester);
      expect(find.text('휴식 1:30 · 열기'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('focus-rest-strip'))).height,
        greaterThanOrEqualTo(44),
      );
      await advance(tester, const Duration(seconds: 48));
      expect(find.text('휴식 0:42 · 열기'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('focus-rest-strip')));
      await tester.pumpAndSettle();
      expect(stageLink(tester).currentId, a.id, reason: 'the resting block');
      await fold(tester);
      await advance(tester, const Duration(seconds: 91));
      expect(rest.running, isFalse);
      expect(find.byKey(const ValueKey('focus-rest-strip')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('편집기를 닫으면 휴식이 조용히 멈추고 알림도 취소된다', (tester) async {
      final b = ExerciseBlock('벤치', [LoggedSet(value: 60, reps: 10)]);
      final c = RoutineEditorController()..restore([b]);
      var done = 0;
      rest.onDone = () => done++;
      await tester.pumpWidget(
        app(
          RoutineEditor(
            controller: c,
            audio: audio,
            rest: rest,
            history: () => const [],
          ),
        ),
      );
      rest.start(b, const Duration(seconds: 90));
      // The app went away mid-rest: the notice is set, with the next set.
      rest.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(notifier.log.last, startsWith('schedule 휴식 끝 다음 · 2세트 60kg'));
      rest.didChangeAppLifecycleState(AppLifecycleState.resumed);
      notifier.log.clear();
      await tester.pumpWidget(const SizedBox());
      expect(rest.running, isFalse);
      expect(notifier.log, ['cancel']);
      expect(done, 0);
      expect(rest.notice, isNull);
    });

    testWidgets('mux: 휴식이 끝나도, 타이머가 멈춰도 다른 쪽의 화면 켜 둠이 꺼지지 않는다', (tester) async {
      final b = ExerciseBlock('벤치', [LoggedSet(value: 60, reps: 10)]);
      final m = ExerciseBlock('푸시업 120bpm');
      final c = RoutineEditorController()..restore([b, m]);
      await tester.pumpWidget(
        app(
          RoutineEditor(controller: c, audio: audio, history: () => const []),
        ),
      );
      await tester.pumpAndSettle();
      c.openFocus!();
      await tester.pumpAndSettle();
      final rest = stageLink(tester).rest;
      rest.start(b, const Duration(seconds: 90));
      rest.stop();
      await tester.pump();
      expect(audio.calls.last.active, isTrue, reason: 'stage still open');
      rest.start(b, const Duration(seconds: 90));
      await fold(tester);
      expect(audio.calls.last.active, isTrue, reason: 'the rest still runs');

      // A metronome on the other card, then paused: the rest keeps it on.
      await tester.tap(find.byKey(const ValueKey('timer-start')));
      await tester.pumpAndSettle();
      expect(find.byType(RunPage), findsOneWidget);
      expect(audio.calls.last.active, isTrue);
      Navigator.of(tester.element(find.byType(RunPage))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('timer-strip-pause')));
      await tester.pump();
      expect(audio.calls.last.active, isTrue);
      expect(audio.calls.last.bpm, isNull);
      // The rest is muted while the timer runs — not now; its stop turns
      // everything off.
      rest.stop();
      await tester.pump();
      expect(audio.calls.last.active, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('같이 하는 타이머가 세트 무대 뒤에서 돌면 무대 띠, 탭하면 타이머 무대가 위로', (tester) async {
      final timer = WorkoutTimer(
        audio: FakeAudio(),
        now: () => now,
        haptic: (_) {},
      );
      addTearDown(timer.dispose);
      final t = ExerciseBlock('버피 타바타');
      final c = RoutineEditorController()..restore([t]);
      await tester.pumpWidget(
        app(
          RoutineEditor(
            controller: c,
            audio: audio,
            timer: timer,
            rest: rest,
            history: () => const [],
          ),
        ),
      );
      c.openFocus!();
      await tester.pumpAndSettle();
      final link = stageLink(tester);
      expect(link.sharedTimerRunning, isFalse);
      timer.follow(t, TimingSpec.parse(t.name)!, Duration.zero);
      expect(timer.shared && timer.running, isTrue);
      expect(link.sharedTimerRunning, isTrue);
      link.onOpenSharedTimer!();
      await tester.pumpAndSettle();
      expect(find.byType(RunPage), findsOneWidget);
      expect(link.sharedTimerRunning, isFalse);
      timer.reset();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('심박: 세트 휴식 중에도 듣고, 타이머 notify 가 와도 끊지 않는다; '
        'LIFT=beginRound, 했어요=beginRest', (tester) async {
      final health = FakeHealth();
      final recovery = RestRecovery(health: health);
      addTearDown(recovery.dispose);
      final timer = WorkoutTimer(
        audio: FakeAudio(),
        now: () => now,
        haptic: (_) {},
      );
      addTearDown(timer.dispose);
      final b = ExerciseBlock('벤치', [LoggedSet(value: 60, reps: 10)]);
      final c = RoutineEditorController()..restore([b]);
      await tester.pumpWidget(
        app(
          RoutineEditor(
            controller: c,
            audio: audio,
            timer: timer,
            rest: rest,
            recovery: recovery,
            history: () => const [],
          ),
        ),
      );
      c.openFocus!();
      await tester.pumpAndSettle();
      final link = stageLink(tester);
      expect(health.watched, isFalse, reason: 'LIFT alone does not listen');
      link.onLift!(b);
      rest.start(b, const Duration(seconds: 90));
      link.onRested!(b);
      expect(health.watched, isTrue);
      final at = DateTime.now();
      health.push(150, at);
      await tester.pump();
      expect(recovery.peak, 150);
      // A timer notify (an idle timer) does not stop or reset it.
      timer.notifyListeners();
      expect(health.watched, isTrue);
      expect(recovery.peak, 150);
      link.onLift!(b);
      expect(recovery.peak, isNull, reason: 'a new set, a new baseline');
      rest.stop();
      expect(health.watched, isFalse, reason: 'rest over: not listening');
      await fold(tester);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('노트 페이지·설정', () {
    late Directory dir;
    late NotesStore store;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('setpad_focus_editor_');
      store = NotesStore(directory: dir);
    });
    tearDown(() {
      store.dispose();
      dir.deleteSync(recursive: true);
    });

    Future<void> pumpPage(WidgetTester tester, Widget page) async {
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: page,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('▶ 는 운동이 있을 때만; 누르면 무대, ±15 는 그 운동의 휴식으로 저장된다', (tester) async {
      final empty = store.create();
      await pumpPage(tester, EditorPage(store: store, note: empty));
      expect(find.byKey(const ValueKey('focus-open')), findsNothing);
      await tester.pumpWidget(const SizedBox());

      final note = store.create(
        blocks: [
          ExerciseBlock('벤치프레스', [LoggedSet(value: 80, reps: 5)]),
        ],
      );
      await pumpPage(tester, EditorPage(store: store, note: note));
      expect(find.bySemanticsLabel('운동 화면'), findsOneWidget);
      final open = find.byKey(const ValueKey('focus-open'));
      expect(tester.getSize(open).height, greaterThanOrEqualTo(44));
      await tester.tap(open);
      await tester.pumpAndSettle();
      final link = stageLink(tester);
      final b = link.blocks.single;
      expect(link.restFor!(b), const Duration(seconds: 90));
      link.onRestChanged!(b, const Duration(seconds: 120));
      expect(store.restFor(exerciseKeyOf(b)), 120);
      expect(link.restFor!(b), const Duration(seconds: 120));
      expect(store.restSeconds, 90, reason: 'the default is the setting\'s');
      await fold(tester);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('대신 적는 편집기에는 ▶ 가 없다', (tester) async {
      final server = Scripted();
      final account = Account(storageDir: dir, client: server.client)
        ..token = 'me';
      final note =
          store.create(
              blocks: [
                ExerciseBlock('스쿼트', [LoggedSet(value: 100, reps: 5)]),
              ],
            )
            ..partner = PartnerSession(
              id: 'S1',
              host: true,
              state: PartnerState.active,
            );
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: EditorPage(store: store, note: note, account: account),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2300));
      expect(find.byKey(const ValueKey('focus-open')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('write-for')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('소라').last);
      await tester.pumpAndSettle();
      expect(find.text('소라 님의 기록을 적는 중'), findsOneWidget);
      expect(find.byKey(const ValueKey('focus-open')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    test('알림 권한은 처음 한 번만 묻는다', () async {
      var asked = 0;
      Future<bool> ask() async {
        asked++;
        return false;
      }

      await askFocusNotifyOnce(store, ask);
      await askFocusNotifyOnce(store, ask);
      expect(asked, 1);
      expect(store.focusNotifyAsked, isTrue);
    });

    testWidgets('설정의 세트 사이 휴식 기본: 1:30, 휠 시트로 바꾸면 저장된다', (tester) async {
      await pumpPage(tester, SettingsPage(store: store));
      final row = find.byKey(const ValueKey('settings-rest'));
      await tester.scrollUntilVisible(row, 100);
      expect(find.text('세트 사이 휴식 기본'), findsOneWidget);
      expect(find.text('1:30'), findsOneWidget);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.text('휴식 시간'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('value-more')));
      await tester.pump();
      expect(store.restSeconds, 105);
      await tester.tap(find.byKey(const ValueKey('value-done')));
      await tester.pumpAndSettle();
      expect(find.text('1:45'), findsOneWidget);
    });
  });
}

String exerciseKeyOf(ExerciseBlock b) => exerciseKey(b.exercise);
