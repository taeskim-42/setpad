// 대신 적기 — 상대의 세트를 내 폰에서 적되 내 기록과 섞이지 않고, 받는 사람이
// 받아야 그 사람의 문서가 된다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/handoff.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';

const token = 'HANDOFF-TOKEN-0123456789ab';

/// 같이 하기 세션 하나와 건네기 창구가 있는 서버.
class Server {
  final handoffs = <Map<String, Object?>>[];
  final records = <Map<String, Object?>>[];
  Map<String, Object?>? offer;

  late final client = MockClient((request) async {
    final path = request.url.path;
    http.Response reply(Map<String, Object?> json) =>
        http.Response.bytes(utf8.encode(jsonEncode(json)), 200);
    if (path == '/api/handoffs') {
      final body = (jsonDecode(request.body) as Map).cast<String, Object?>();
      handoffs.add(body);
      return reply({'token': token, 'revision': body['revision']});
    }
    if (path.endsWith('/record')) {
      records.add((jsonDecode(request.body) as Map).cast<String, Object?>());
      return reply({'revision': 1});
    }
    if (path.startsWith('/api/partner-sessions/')) {
      return reply({
        'id': 'S1',
        'state': 'active',
        'role': 'host',
        'partner': '준',
        'myRevision': 0,
        'partnerRecord': null,
        'now': DateTime.now().millisecondsSinceEpoch,
        'timer': null,
        'handoff': offer,
      });
    }
    return http.Response('{}', 200);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('대신 적은 칸은 문서와 함께 저장되고, 링크에서 토큰을 읽는다', () {
    final note =
        Note(
            id: 'n1',
            createdAt: DateTime(2026, 9, 21, 19),
            updatedAt: DateTime(2026, 9, 21, 20),
            blocks: [
              ExerciseBlock('벤치프레스', [LoggedSet(value: 80, reps: 5)]),
            ],
          )
          ..proxy = ProxyRecord(
            name: '준',
            blocks: [
              ExerciseBlock('스쿼트', [LoggedSet(value: 60, reps: 8)]),
            ],
            revision: 3,
            sent: 2,
            token: token,
          );
    final back = Note.fromJson(
      jsonDecode(jsonEncode(note.toJson())) as Map<String, dynamic>,
    );
    expect(back.blocks.single.name, '벤치프레스', reason: '내 기록은 내 기록이다');
    expect(back.proxy!.name, '준');
    expect(back.proxy!.blocks.single.sets.single.reps, 8);
    expect(
      [back.proxy!.revision, back.proxy!.sent, back.proxy!.token],
      [3, 2, token],
    );

    expect(
      handoffTokenFromLink(Uri.parse('https://gym.darak.studio/r/$token')),
      token,
    );
    expect(handoffTokenFromLink(Uri.parse('setpad://r/$token')), token);
    expect(
      handoffTokenFromLink(Uri.parse('https://gym.darak.studio/plan/$token')),
      isNull,
    );
    expect(handoffTokenFromLink(Uri.parse('setpad://r/short')), isNull);
  });

  test('건네받은 기록은 새 문서로 그 운동을 한 시각에 놓이고, 내가 고친 문서는 덮지 않는다', () {
    final dir = Directory.systemTemp.createTempSync('setpad_handoff_');
    final store = NotesStore(directory: dir);
    addTearDown(() {
      store.dispose();
      dir.deleteSync(recursive: true);
    });
    final at = DateTime(2026, 9, 21, 19, 30);
    Handoff handoff(int revision, int sets) => (
      from: '미나',
      workedAt: at,
      revision: revision,
      blocks: [
        ExerciseBlock('스쿼트', [
          for (var i = 0; i < sets; i++) LoggedSet(value: 60, reps: 8),
        ]),
      ],
    );

    final first = placeHandoff(store, token, handoff(1, 1));
    expect(first.createdAt, at);
    expect(first.blocks.single.sets, hasLength(1));
    expect(store.notes, hasLength(1));

    // 같은 링크를 다시 열어도 문서는 하나다.
    expect(identical(placeHandoff(store, token, handoff(1, 1)), first), isTrue);
    // 보낸 사람이 더 적었다 — 손대지 않은 문서는 그 내용으로 맞춘다.
    final updated = placeHandoff(store, token, handoff(2, 3));
    expect(identical(updated, first), isTrue);
    expect(first.blocks.single.sets, hasLength(3));
    expect(store.notes, hasLength(1));

    // 내가 고친 뒤에 또 왔다 — 내 문서는 그대로 두고 따로 들어온다.
    first
      ..handoffTouched = true
      ..blocks.single.sets.removeLast();
    final another = placeHandoff(store, token, handoff(3, 5));
    expect(identical(another, first), isFalse);
    expect(first.blocks.single.sets, hasLength(2), reason: '내가 고친 것이 남아 있다');
    expect(another.blocks.single.sets, hasLength(5));
    expect(store.notes, hasLength(2));
  });

  group('기록 화면', () {
    Future<(Server, NotesStore, Note)> mount(
      WidgetTester tester, {
      void Function(String)? onTake,
      Map<String, Object?>? offer,
    }) async {
      final dir = Directory.systemTemp.createTempSync('setpad_proxy_');
      final store = NotesStore(directory: dir);
      addTearDown(() {
        store.dispose();
        dir.deleteSync(recursive: true);
      });
      final server = Server()..offer = offer;
      final account = Account(storageDir: dir, client: server.client)
        ..token = 'member';
      final note = store.create()
        ..partner = PartnerSession(
          id: 'S1',
          host: true,
          state: PartnerState.active,
          partnerName: '준',
        );
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: EditorPage(
            store: store,
            note: note,
            account: account,
            onTakeHandoff: onTake,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      return (server, store, note);
    }

    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    }

    testWidgets('상대의 세트를 대신 적어도 내 기록은 그대로고, 내 공유에도 섞이지 않는다', (tester) async {
      final (server, _, note) = await mount(tester);
      expect(find.byKey(const ValueKey('proxy-bar')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('write-for')));
      await tester.pump();
      expect(find.text('준 님의 기록을 적는 중'), findsOneWidget);

      await tester.enterText(find.byType(CupertinoTextField).first, '스쿼트');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      tester.widget<SetKeypad>(find.byType(SetKeypad)).onKey('60 8');
      await tester.pump();
      tester.widget<SetKeypad>(find.byType(SetKeypad)).onAddSet!();
      await tester.pump();

      expect(note.blocks, isEmpty, reason: '내 기록에 남의 세트가 들어오면 안 된다');
      expect(note.proxy!.name, '준');
      expect(note.proxy!.blocks.single.name, '스쿼트');
      expect(note.proxy!.blocks.single.sets.single.reps, 8);

      // 조금 뒤에 서버로 올라간다 — 누구의 것인지, 어느 세션인지와 함께.
      await tester.pump(const Duration(milliseconds: 1500));
      final sent = server.handoffs.last;
      expect(
        [sent['forName'], sent['sessionId'], sent['localId']],
        ['준', 'S1', note.id],
      );
      expect(jsonEncode(sent['result']), contains('스쿼트'));
      expect(note.proxy!.token, token);
      expect(note.proxy!.sent, note.proxy!.revision);
      // 같이 하기로 나가는 **내** 기록에는 없다.
      expect(jsonEncode(server.records), isNot(contains('스쿼트')));

      // 내 기록으로 돌아온다. 다시 들어가면 적던 것이 그대로다.
      await tester.tap(find.text('내 기록으로'));
      await tester.pump();
      expect(find.byKey(const ValueKey('proxy-bar')), findsNothing);
      expect(note.blocks, isEmpty);
      await tester.tap(find.byKey(const ValueKey('write-for')));
      await tester.pumpAndSettle();
      expect(find.text('스쿼트'), findsWidgets);
      await close(tester);
    });

    testWidgets('상대가 내 기록을 적어 주었으면 받기가 뜨고, 이미 받았으면 뜨지 않는다', (tester) async {
      final taken = <String>[];
      final offer = {'token': token, 'revision': 2, 'from': '준'};
      final (_, store, _) = await mount(
        tester,
        onTake: taken.add,
        offer: offer,
      );
      await tester.pump(const Duration(milliseconds: 2200));
      expect(find.text('준 님이 내 기록을 적어 주었습니다'), findsOneWidget);
      await tester.tap(find.text('받기'));
      expect(taken, [token]);

      // 받아 두었다 — 같은 번호로는 다시 권하지 않는다.
      placeHandoff(store, token, (
        from: '준',
        workedAt: DateTime(2026, 9, 21, 19),
        revision: 2,
        blocks: [
          ExerciseBlock('스쿼트', [LoggedSet(value: 60, reps: 8)]),
        ],
      ));
      await tester.pump(const Duration(milliseconds: 2200));
      expect(find.byKey(const ValueKey('handoff-offer')), findsNothing);
      await close(tester);
    });
  });
}
