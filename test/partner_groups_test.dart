// 셋 이상이 같이 하기 — 사람마다의 기록, 동의한 폰만 도는 타이머, 누구의 것인지 아는 대신 적기.
//
// 서버의 규칙은 gymdojo 의 partner-sessions.test.ts 가 실제 Postgres 로 지킨다. 여기서는
// 서버가 그렇게 답했을 때 앱이 무엇을 하는지만 본다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/gym_sheets.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';
import 'package:setpad/shared_timer.dart';
import 'package:setpad/workout_timing.dart';

import 'workout_timing_test.dart' show FakeAudio;

Map<String, Object?> set(int reps) => {
  'value': null,
  'unit': 'kg',
  'reps': reps,
  'notes': <String>[],
  'done': true,
};

/// 서버가 하는 말을 시험이 직접 정한다.
class Scripted {
  Map<String, Object?> state = {
    'id': 'S1',
    'state': 'active',
    'role': 'host',
    'partner': '준',
    'partnerRecord': null,
    'myRevision': 0,
    'now': 1700000000000,
    'room': 3,
    'code': 'ABCD23',
    'members': [
      {
        'key': 'aaaa1111',
        'name': '준',
        'record': {
          'revision': 1,
          'updatedAt': '2026-09-21T10:00:00Z',
          'result': [
            {
              'name': '버피 타바타',
              'sets': [set(14), set(13)],
            },
          ],
        },
      },
      {'key': 'bbbb2222', 'name': '소라', 'record': null},
    ],
    'timer': null,
    'handoff': null,
  };
  final handoffs = <Map<String, Object?>>[];

  late final client = MockClient((request) async {
    http.Response reply(Map<String, Object?> json) =>
        http.Response.bytes(utf8.encode(jsonEncode(json)), 200);
    if (request.url.path == '/api/handoffs') {
      handoffs.add((jsonDecode(request.body) as Map).cast<String, Object?>());
      return reply({'token': 'HANDOFF-TOKEN-0123456789ab', 'revision': 1});
    }
    if (request.url.path.endsWith('/record')) return reply({'revision': 1});
    return reply(state);
  });
}

Widget app(Widget home) => CupertinoApp(
  locale: const Locale('ko'),
  localizationsDelegates: L.localizationsDelegates,
  supportedLocales: L.supportedLocales,
  home: home,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('서버가 말한 사람들을 다 읽는다 — 이름은 모두의 것이고, 기록은 사람마다 따로다', () async {
    final server = Scripted();
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
      link: () =>
          GymLink(endpoint: 'https://x', token: 'me', client: server.client),
      onChanged: () {},
    );
    addTearDown(sync.dispose);
    await sync.refresh();
    final s = note.partner!;
    expect(s.others.map((p) => (p.key, p.name)), [
      ('aaaa1111', '준'),
      ('bbbb2222', '소라'),
    ]);
    expect(s.partnerName, '준, 소라');
    expect(s.room, 3);
    expect(s.others.first.blocks.single.sets.map((x) => x.reps), [14, 13]);
    expect(s.others.last.blocks, isEmpty);

    // 옛 서버는 사람 목록을 주지 않는다 — 그때는 예전처럼 한 명이다.
    server.state = {...server.state}
      ..remove('members')
      ..remove('room');
    await sync.refresh();
    expect(note.partner!.others, isEmpty);
    expect(note.partner!.partnerName, '준');
  });

  test('같이 하는 타이머: 동의했는지를 읽고, 모두가 그만둬야 끝난 것이다', () {
    Map<String, Object?> json(Map<String, Object?> more) => {
      'seq': 1,
      'title': '스쿼트 60bpm',
      'alternate': false,
      'mine': false,
      'startAt': 1700000000000,
      'spec': {'bpm': 60, 'tabata': false, 'work': 20, 'rest': 10, 'rounds': 8},
      ...more,
    };
    final left = {'ms': 1000, 'beat': 1};
    // 다른 둘이 시작했다. 나는 아직 동의하지 않았다.
    final watching = SharedTimer.tryFromJson(json({'joined': false}))!;
    expect([watching.started, watching.joined], [true, false]);
    // 옛 서버(칸이 없다)에서는 시작했으면 동의한 것이다 — 둘뿐이므로.
    expect(SharedTimer.tryFromJson(json({}))!.joined, isTrue);
    expect(
      SharedTimer.tryFromJson(json({'startAt': null}))!.joined,
      isFalse,
      reason: '아직 받지 않은 제안',
    );

    final three = SharedTimer.tryFromJson(
      json({
        'joined': true,
        'myLeft': left,
        'others': [
          {'key': 'a', 'name': '준', 'left': left},
          {'key': 'b', 'name': '소라', 'left': null},
        ],
      }),
    )!;
    expect(three.overAt(1700000100000), isFalse, reason: '소라가 아직 하고 있다');
  });

  testWidgets('같이 하기 창: 사람마다 한 묶음이고, 자리가 있으면 한 명 더 부를 수 있다', (tester) async {
    final server = Scripted();
    final dir = Directory.systemTemp.createTempSync('setpad_group_sheet_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final account = Account(storageDir: dir, client: server.client)
      ..token = 'me';
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
      link: () => account.link,
      onChanged: () {},
    );
    await sync.refresh();
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => showPartnerSheet(context, account, sync),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('준, 소라'), findsWidgets);
    expect(find.textContaining('준 님의 기록'), findsOneWidget);
    expect(find.textContaining('소라 님의 기록'), findsOneWidget);
    expect(find.textContaining('ABCD23'), findsOneWidget);
    expect(find.byKey(const ValueKey('invite-more')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    sync.dispose();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('타이머 칸: 셋이면 세 줄이다', (tester) async {
    var now = Duration.zero;
    final timer = WorkoutTimer(audio: FakeAudio(), now: () => now);
    final owner = Object();
    const spec = TimingSpec(tabata: true);
    timer.follow(owner, spec, const Duration(seconds: 25));
    await tester.pumpWidget(
      app(
        CupertinoPageScaffold(
          child: SafeArea(
            child: WorkoutTimingControls(
              owner: owner,
              spec: spec,
              timer: timer,
              onStart: () {},
              together: TogetherTiming(
                partner: '준',
                live: true,
                mine: const [12],
                theirs: const [14, 13],
                more: const [(name: '소라', counts: <int?>[])],
                partnerLeft: '소라 님은 1라운드에서 멈춤',
                onPropose: (_) {},
                onToggle: () => true,
                onCancel: () {},
                onLog: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('12  –'), findsOneWidget);
    expect(find.text('14  13'), findsOneWidget);
    expect(find.text('–  –'), findsOneWidget, reason: '소라는 아직 하나도 안 적었다');
    expect(find.text('소라'), findsOneWidget);
    expect(find.text('소라 님은 1라운드에서 멈춤'), findsOneWidget);
    now = const Duration(seconds: 1);
    timer.dispose();
  });

  testWidgets('다른 둘이 시작한 타이머에 내 폰은 끌려가지 않고, 받으면 돌고 있는 자리로 들어간다', (
    tester,
  ) async {
    final server = Scripted();
    server.state = {
      ...server.state,
      'timer': {
        'seq': 1,
        'title': '스쿼트 60bpm',
        'alternate': false,
        'mine': false,
        'joined': false,
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
        'others': [
          {'key': 'aaaa1111', 'name': '준', 'left': null},
          {'key': 'bbbb2222', 'name': '소라', 'left': null},
        ],
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
    final c = RoutineEditorController();
    await tester.pumpWidget(
      app(
        CupertinoPageScaffold(
          resizeToAvoidBottomInset: false,
          child: SafeArea(
            child: RoutineEditor(controller: c, partner: sync, timer: timer),
          ),
        ),
      ),
    );
    await sync.refresh();
    await tester.pump();
    expect(timer.running, isFalse, reason: '동의하지 않은 폰은 울리지 않는다');
    expect(c.blocks, isEmpty);
    expect(find.byKey(const ValueKey('together-invite')), findsOneWidget);

    // 받는다 — 서버가 동의를 적고, 다음 소식에 돌고 있는 자리로 들어간다.
    await tester.tap(find.byKey(const ValueKey('together-accept')));
    (server.state['timer'] as Map)['joined'] = true;
    await tester.pump();
    await sync.refresh();
    await tester.pump();
    expect(c.blocks.single.name, '스쿼트 60bpm');
    expect(timer.running && timer.shared, isTrue);
    expect(timer.elapsed, const Duration(seconds: 20));
    expect(find.byKey(const ValueKey('together-invite')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    sync.dispose();
    timer.dispose();
  });

  testWidgets('셋이 같이 할 때 대신 적기는 누구의 것인지 묻고, 그 사람을 서버에 말한다', (tester) async {
    final server = Scripted();
    final dir = Directory.systemTemp.createTempSync('setpad_group_proxy_');
    final store = NotesStore(directory: dir);
    addTearDown(() {
      store.dispose();
      dir.deleteSync(recursive: true);
    });
    final account = Account(storageDir: dir, client: server.client)
      ..token = 'me';
    final note = store.create()
      ..partner = PartnerSession(
        id: 'S1',
        host: true,
        state: PartnerState.active,
      );
    await tester.pumpWidget(
      app(EditorPage(store: store, note: note, account: account)),
    );
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.tap(find.byKey(const ValueKey('write-for')));
    await tester.pumpAndSettle();
    expect(find.text('누구의 기록을 적을까요?'), findsOneWidget);
    await tester.tap(find.text('소라').last);
    await tester.pumpAndSettle();
    expect(find.text('소라 님의 기록을 적는 중'), findsOneWidget);
    expect([note.proxy!.name, note.proxy!.forKey], ['소라', 'bbbb2222']);

    await tester.enterText(find.byType(CupertinoTextField).first, '스쿼트');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(server.handoffs.last['forKey'], 'bbbb2222');
    expect(server.handoffs.last['forName'], '소라');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
