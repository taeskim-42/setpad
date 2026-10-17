// 같이 하기 검토 후속 — 검토에서 재현된 결함마다 실패하던 시나리오를 고정한다.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/partner.dart';
import 'package:setpad/set_grid.dart';

Map<String, Object?> setJson(String id, int reps, String key, String name) => {
  'id': id,
  'value': 60,
  'unit': 'kg',
  'reps': reps,
  'notes': <String>[],
  'done': true,
  'by': {'key': key, 'name': name},
};

Map<String, Object?> activeBody(
  String id,
  String partner,
  String otherKey,
  List<Map<String, Object?>> blocks, {
  List<String> accepted = const [],
  String role = 'host',
}) => {
  'id': id,
  'state': 'active',
  'role': role,
  'partner': partner,
  'myRevision': 0,
  'now': 1700000000000,
  'me': 'mmmm',
  'members': [
    {'key': otherKey, 'name': partner, 'record': null},
  ],
  'room': 4,
  'doc': {
    'version': 1,
    'blocks': blocks,
    'accepted': accepted,
    'finalizedVersion': null,
  },
};

http.Response reply(int status, Object? body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

List<String> setIds(Note note) => [
  for (final b in note.blocks) ...b.sets.map((s) => s.id),
];

PartnerSync syncFor(Note note, MockClient client) {
  final sync = PartnerSync(
    note: note,
    link: () => GymLink(endpoint: 'https://x', token: 'me', client: client),
    onChanged: () {},
  );
  addTearDown(sync.dispose);
  return sync;
}

Note newNote() => Note(
  id: 'n1',
  createdAt: DateTime(2026, 10, 17),
  updatedAt: DateTime(2026, 10, 17),
);

({Account account, Map<String, Object?> state, List<String> asked}) signedIn(
  Directory dir,
) {
  final state = <String, Object?>{};
  final asked = <String>[];
  final account = Account(
    storageDir: dir,
    client: MockClient((request) async {
      final path = request.url.path;
      asked.add(path);
      if (path.endsWith('/events')) return http.Response('', 404);
      if (path.endsWith('/record')) return reply(200, {'revision': 1});
      if (path.endsWith('/join')) return reply(500, {'error': 'server'});
      if (path.contains('/partner-sessions')) return reply(200, state);
      if (path == '/api/me') {
        return reply(200, {
          'user': {'id': 'u1', 'nickname': 'kim'},
        });
      }
      return reply(200, {'plan': null, 'selling': false, 'gyms': []});
    }),
  )..token = 'member';
  return (account: account, state: state, asked: asked);
}

Widget app(Widget home, {double scale = 1}) => CupertinoApp(
  locale: const Locale('ko'),
  localizationsDelegates: L.localizationsDelegates,
  supportedLocales: L.supportedLocales,
  builder: (c, child) => MediaQuery(
    data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);

void main() {
  final l = lookupL(const Locale('ko'));

  group('세션이 바뀔 때', () {
    test('같이 하던 기록에서 다른 초대 링크를 받으면 서버에 묻지 않고 거절한다 — 내 세트가 그대로다', () async {
      final s1 = activeBody('S1', '준', 'jjjj', [
        {
          'id': 'B',
          'name': '벤치',
          'sets': [
            setJson('m1', 10, 'mmmm', '미나'),
            setJson('j1', 8, 'jjjj', '준'),
          ],
        },
      ]);
      final asked = <String>[];
      final note = newNote()
        ..partner = PartnerSession(
          id: 'S1',
          host: true,
          state: PartnerState.active,
        );
      final sync = syncFor(
        note,
        MockClient((r) async {
          asked.add(r.url.path);
          if (r.url.path.endsWith('/doc')) return reply(200, {'version': 2});
          return reply(200, s1);
        }),
      );
      await sync.refresh();
      if (sync.takeDoc() case final b?) note.blocks = b;
      expect(setIds(note), ['m1', 'j1']);

      final error = await sync.joinWithToken('abcdefghijklmnopqrstuvwx');
      expect(error, PartnerError.alreadyInSession);
      expect(sync.error, PartnerError.alreadyInSession);
      expect(asked.where((p) => p.endsWith('/join')), isEmpty);
      expect(await sync.joinWithCode('AB23CD'), PartnerError.alreadyInSession);
      expect(note.partner?.id, 'S1');
      expect(setIds(note), ['m1', 'j1']);
    });

    test('서버가 다른 세션을 말하면 처음 참여처럼 합친다 — 옛 문서 위에 얹어 내 세트를 잃지 않는다', () async {
      var body = activeBody('S1', '준', 'jjjj', [
        {
          'id': 'B',
          'name': '벤치',
          'sets': [
            setJson('m1', 10, 'mmmm', '미나'),
            setJson('j1', 8, 'jjjj', '준'),
          ],
        },
      ]);
      final note = newNote()
        ..partner = PartnerSession(
          id: 'S1',
          host: true,
          state: PartnerState.active,
        );
      final sync = syncFor(
        note,
        MockClient((r) async {
          if (r.url.path.endsWith('/doc')) return reply(200, {'version': 2});
          return reply(200, body);
        }),
      );
      await sync.refresh();
      if (sync.takeDoc() case final b?) note.blocks = b;
      body = activeBody('S2', '철수', 'cccc', [
        {
          'id': 'C',
          'name': '스쿼트',
          'sets': [setJson('c1', 5, 'cccc', '철수')],
        },
      ], role: 'guest');
      await sync.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (sync.takeDoc() case final b?) note.blocks = b;
      expect(note.partner?.id, 'S2');
      expect(setIds(note), containsAll(['c1', 'm1']));
    });
  });

  test('다시 열어 올린 묶음이 남의 세트 하나로 거절돼도 같이 실린 내 오프라인 세트는 올라간다', () async {
    final v1 = [
      {
        'id': 'B',
        'name': '벤치',
        'sets': [setJson('m1', 10, 'mmmm', '미나')],
      },
      {
        'id': 'C',
        'name': '스쿼트',
        'sets': [setJson('m2', 5, 'mmmm', '미나')],
      },
    ];
    final v2 = [
      {
        'id': 'B',
        'name': '벤치',
        'sets': [
          setJson('m1', 10, 'mmmm', '미나'),
          setJson('j1', 8, 'jjjj', '준'),
        ],
      },
      v1[1],
    ];
    final state = activeBody('S1', '준', 'jjjj', v2)
      ..['doc'] = {
        'version': 2,
        'blocks': v2,
        'accepted': <String>[],
        'finalizedVersion': null,
      };
    final edits = <List<Object?>>[];
    final note = newNote()
      ..blocks = blocksFromJson([
        {
          'id': 'C',
          'name': '스쿼트',
          'sets': [
            {
              'id': 'm2',
              'value': 60,
              'unit': 'kg',
              'reps': 5,
              'notes': [],
              'done': true,
            },
            {
              'id': 'm5',
              'value': 70,
              'unit': 'kg',
              'reps': 3,
              'notes': [],
              'done': true,
            },
          ],
        },
      ])
      ..partner =
          (PartnerSession(id: 'S1', host: true, state: PartnerState.active)
            ..docBase = v1
            ..docBaseVersion = 1
            ..me = 'mmmm');
    final sync = syncFor(
      note,
      MockClient((r) async {
        if (r.url.path.endsWith('/doc')) {
          final ops = (jsonDecode(r.body) as Map)['ops'] as List;
          edits.add(ops);
          // 서버(partner-fixes): 남의 세트가 든 운동을 지우면 묶음째 409 notYours.
          if (ops.any((o) => o['kind'] == 'removeBlock' && o['block'] == 'B')) {
            return reply(409, {'error': 'notYours'});
          }
          return reply(200, {'version': 3});
        }
        if (r.url.path.endsWith('/record')) return reply(200, {'revision': 1});
        return reply(200, state);
      }),
    );
    await sync.refresh();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (sync.takeDoc() case final b?) note.blocks = b;
    expect(sync.error, PartnerError.notYours);
    expect(edits.first, hasLength(2), reason: '다시 열면 묶음 하나로 간다');
    expect(
      edits.skip(1).every((ops) => ops.length == 1),
      isTrue,
      reason: '거절된 묶음은 하나씩 다시 보낸다',
    );
    expect(
      edits.any((ops) => jsonEncode(ops).contains('"m5"')) &&
          edits.last.length == 1,
      isTrue,
    );
    expect(setIds(note), containsAll(['m5', 'm1', 'j1']));
  });

  group('루틴 계획', () {
    test('확인하고 나간 사람의 확인은 남은 사람을 계획으로 끌어들이지 않는다', () {
      final s = PartnerSession(id: 'S1', host: true, state: PartnerState.active)
        ..me = 'H'
        ..others = const [PartnerPerson(key: 'C', name: 'C')]
        ..routineAcceptedKeys = ['A'];
      expect(s.routinePlanning, isFalse);
      s.routineAcceptedKeys = ['C'];
      expect(s.routinePlanning, isTrue);
    });

    test('누가 확인하면 확인하지 않은 사람도 계획에 머문다 — 누가 고쳐 확인이 풀려도', () async {
      final blocks = [
        {'id': 'B', 'name': '벤치', 'sets': <Object?>[]},
      ];
      var body = activeBody('S1', '준', 'jjjj', blocks, accepted: ['jjjj']);
      final note = newNote()
        ..partner = PartnerSession(
          id: 'S1',
          host: true,
          state: PartnerState.active,
        );
      final sync = syncFor(
        note,
        MockClient((r) async {
          if (r.url.path.endsWith('/doc')) return reply(200, {'version': 2});
          return reply(200, body);
        }),
      );
      await sync.refresh();
      expect(note.partner!.routinePlanning, isTrue);
      body = activeBody('S1', '준', 'jjjj', blocks);
      await sync.refresh();
      expect(note.partner!.routineAcceptedKeys, isEmpty);
      expect(note.partner!.routinePlanning, isTrue);
    });
  });

  group('끝난 세션의 이름', () {
    Future<Note> endAfter(
      Map<String, Object?> active, {
      required String endedPartner,
    }) async {
      var body = active;
      final note = newNote()
        ..partner = PartnerSession(
          id: 'S1',
          host: active['role'] == 'host',
          state: PartnerState.active,
        );
      final sync = syncFor(note, MockClient((r) async => reply(200, body)));
      await sync.refresh();
      body = {
        ...active,
        'state': 'ended',
        'endedByMe': false,
        'partner': endedPartner,
        'members': <Object?>[],
      }..remove('doc');
      await sync.refresh();
      return note;
    }

    test('셋이 하다 끝나면 이어 붙인 이름을 지킨다(홈의 첫 사람 +N)', () async {
      final note = await endAfter({
        ...activeBody('S1', '준', 'jjjj', const [], role: 'guest'),
        'members': [
          {'key': 'jjjj', 'name': '준', 'record': null},
          {'key': 'ssss', 'name': '소라', 'record': null},
        ],
      }, endedPartner: '준');
      expect(note.partner!.state, PartnerState.ended);
      expect(note.partner!.partnerName, '준, 소라');
    });

    test('먼저 나간 사람이 아니라 마지막에 함께 있던 사람의 이름이 남는다', () async {
      final note = await endAfter(
        activeBody('S1', '소라', 'ssss', const []),
        endedPartner: '준',
      );
      expect(note.partner!.partnerName, '소라');
    });

    testWidgets('종료 띠: 셋 이상이면 이름 없이, 큰 글자에서도 잘리지 않는다', (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final dir = Directory.systemTemp.createTempSync('setpad_review_strip_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = NotesStore(directory: dir);
      final t = signedIn(dir);
      t.state.addAll(
        {
          ...activeBody('S1', '준', 'jjjj', const [], role: 'guest'),
          'members': [
            {'key': 'jjjj', 'name': '준', 'record': null},
            {'key': 'ssss', 'name': '소라', 'record': null},
          ],
        }..remove('doc'),
      );
      final note = store.create()
        ..partner = PartnerSession(
          id: 'S1',
          host: false,
          state: PartnerState.active,
        );
      await tester.pumpWidget(
        app(EditorPage(store: store, note: note, account: t.account), scale: 2),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      t.state
        ..['state'] = 'ended'
        ..['endedByMe'] = false
        ..['members'] = <Object?>[];
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      final strip = find.byKey(const ValueKey('partner-ended'));
      expect(
        find.descendant(of: strip, matching: find.text(l.partnerEndedGroup)),
        findsOneWidget,
      );
      final text = tester.renderObject<RenderParagraph>(
        find
            .descendant(of: strip, matching: find.text(l.partnerEndedGroup))
            .first,
      );
      expect(text.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      t.account.dispose();
    });
  });

  group('홈', () {
    testWidgets('맨 위 같이 운동 중 줄은 최근 것 하나뿐이다 — 끝내지 않은 지난 세션은 쌓이지 않는다', (
      tester,
    ) async {
      final dir = Directory.systemTemp.createTempSync('setpad_review_home_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = NotesStore(directory: dir);
      final ids = <Duration, String>{};
      for (final ago in const [
        Duration(days: 9),
        Duration(days: 5),
        Duration(hours: 2),
        Duration(minutes: 10),
      ]) {
        final n = store.create(at: DateTime.now().subtract(ago))
          ..partner = PartnerSession(
            id: 'S$ago',
            host: true,
            state: PartnerState.active,
            partnerName: '준',
          );
        store.update(n, [
          ExerciseBlock('벤치', [LoggedSet(value: 60, unit: 'kg', reps: 10)]),
        ]);
        n.updatedAt = DateTime.now().subtract(ago);
        ids[ago] = n.id;
      }
      await tester.pumpWidget(app(NotesListPage(store: store, onOpen: (_) {})));
      await tester.pump();
      expect(find.text('준 님과 함께 운동 중'), findsOneWidget);
      expect(
        find.byKey(
          ValueKey('partner-live-${ids[const Duration(minutes: 10)]}'),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });

    testWidgets('같은 기록으로 다시 연 초대가 만료돼도, 남의 세트가 있으면 같이 한 표시가 남는다', (
      tester,
    ) async {
      final dir = Directory.systemTemp.createTempSync('setpad_review_row_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = NotesStore(directory: dir);
      final n = store.create()
        ..partner = PartnerSession(
          id: 'S2',
          host: true,
          state: PartnerState.expired,
        );
      store.update(n, [
        ExerciseBlock('벤치', [
          LoggedSet(value: 60, unit: 'kg', reps: 10),
          LoggedSet(value: 60, unit: 'kg', reps: 8, author: '준'),
        ]),
      ]);
      await tester.pumpWidget(app(NotesListPage(store: store, onOpen: (_) {})));
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('준'),
        ),
        findsWidgets,
      );
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  });

  testWidgets('남의 세트 칸: 읽어 주기는 누구 것인지와 읽기 전용을 말하고 버튼이라 하지 않으며, 칸 전체를 흐리지 않는다', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final block = ExerciseBlock('벤치', [
      LoggedSet(value: 60, unit: 'kg', reps: 10),
      LoggedSet(value: 60, unit: 'kg', reps: 8, author: '준'),
    ]);
    await tester.pumpWidget(
      app(
        CupertinoPageScaffold(
          child: SetGrid(block: block, onTapSet: (_, _) {}, onMove: (_, _) {}),
        ),
      ),
    );
    final mine = tester.getSemantics(
      find.bySemanticsLabel(RegExp('^${l.setOrdinal(1)}')),
    );
    expect(mine, isSemantics(isButton: true, hasTapAction: true));
    final theirs = tester.getSemantics(
      find.bySemanticsLabel(
        RegExp('^${RegExp.escape(l.partnerTheirRecord('준'))}'),
      ),
    );
    final data = theirs.getSemanticsData();
    expect(data.label, contains(l.setOrdinal(2)));
    expect(data.hint, l.partnerReadOnly);
    expect(theirs, isSemantics(isButton: false, hasTapAction: true));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('set-cell-1')),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    handle.dispose();
  });

  testWidgets('링크로 연 참여가 실패하면 편집기가 열린 채로 같은 링크를 다시 눌러 다시 시도한다', (tester) async {
    final dir = Directory.systemTemp.createTempSync('setpad_review_link_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final t = signedIn(dir);
    final links = StreamController<Uri>();
    addTearDown(links.close);
    await tester.pumpWidget(
      SetpadApp(
        store: NotesStore(directory: dir),
        tags: links.stream,
        account: t.account,
      ),
    );
    // 켜지면 오늘 기록이 열린다. 닫아 둔다 — 링크가 편집기를 새로 여는 경우다.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(EditorPage), findsNothing);
    final link = Uri.parse(
      'https://gym.darak.studio/j/abcdefghijklmnopqrstuvwx',
    );
    links.add(link);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(EditorPage), findsOneWidget);
    expect(t.asked.where((p) => p.endsWith('/join')), hasLength(1));
    links.add(link);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(t.asked.where((p) => p.endsWith('/join')), hasLength(2));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
