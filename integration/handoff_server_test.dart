// 대신 적은 기록을 건네기 — 실제 서버, 실제 HTTP, 서로 다른 두 사용자.
//   gymdojo 에서  node scripts/e2e-server.mjs
//   flutter test integration/handoff_server_test.dart --dart-define=PARTNER_TOKENS=<파일>
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/handoff.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';

const endpoint = String.fromEnvironment(
  'PARTNER_SERVER',
  defaultValue: 'http://127.0.0.1:3999',
);
const tokensFile = String.fromEnvironment('PARTNER_TOKENS');

void main() {
  final tokens = (jsonDecode(File(tokensFile).readAsStringSync()) as Map)
      .cast<String, String>();
  final names = tokens.keys.toList();
  GymLink link(int i) => GymLink(endpoint: endpoint, token: tokens[names[i]]!);

  test(
    '미나가 준의 세트를 적어 건네고, 준이 받아 자기 문서로 만든다',
    () async {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final dir = Directory.systemTemp.createTempSync('setpad_handoff_it_');
      addTearDown(() => dir.deleteSync(recursive: true));

      // 같이 하는 중이다 — 준의 화면에 받기가 떠야 한다.
      Note note(String id) =>
          Note(id: id, createdAt: DateTime.now(), updatedAt: DateTime.now());
      final minaNote = note('ho-$stamp-a');
      final mina = PartnerSync(
        note: minaNote,
        link: () => link(0),
        onChanged: () {},
      );
      final jun = PartnerSync(
        note: note('ho-$stamp-b'),
        link: () => link(1),
        onChanged: () {},
      );
      addTearDown(mina.dispose);
      addTearDown(jun.dispose);
      expect(await mina.invite(), isNull);
      expect(await jun.joinWithCode(mina.session!.code!), isNull);
      await mina.refresh();

      minaNote.proxy = ProxyRecord(
        name: '준',
        blocks: [
          ExerciseBlock('내 방식 스쿼트', [
            LoggedSet(value: 102.5, unit: 'lb', reps: 8, notes: ['무릎']),
          ]),
        ],
        revision: 1,
      );
      expect(
        await link(0).sendProxy(minaNote, sessionId: mina.session!.id),
        isNull,
      );
      final token = minaNote.proxy!.token!;
      expect(minaNote.proxy!.sent, 1);
      // 밀린 것이 없으면 다시 묻지 않는다. 더 적으면 같은 링크로 올라간다.
      expect(await link(0).sendProxy(minaNote), isNull);
      minaNote.proxy!
        ..blocks.single.sets.add(LoggedSet(value: 105, unit: 'lb', reps: 6))
        ..revision = 2;
      expect(
        await link(0).sendProxy(minaNote, sessionId: mina.session!.id),
        isNull,
      );
      expect(minaNote.proxy!.token, token);

      // 준의 세션 상태에 받기가 뜬다. 미나 자신의 공유 기록에는 아무것도 없다.
      await jun.refresh();
      expect(jun.session!.handoff!.token, token);
      expect(jun.session!.handoff!.revision, 2);
      expect(jun.session!.partnerBlocks, isEmpty);
      await mina.refresh();
      expect(mina.session!.handoff, isNull);

      // 준이 받는다 — 친 이름·단위·메모가 그대로고, 그 운동을 한 시각에 놓인다.
      final got = await link(1).readHandoff(token);
      expect(got.error, isNull);
      final store = NotesStore(directory: dir);
      addTearDown(store.dispose);
      final mine = placeHandoff(store, token, got.handoff!);
      expect(mine.blocks.single.name, '내 방식 스쿼트');
      expect(mine.blocks.single.sets.map((s) => (s.value, s.unit, s.reps)), [
        (102.5, 'lb', 8),
        (105.0, 'lb', 6),
      ]);
      expect(mine.blocks.single.sets.first.notes, ['무릎']);
      expect(
        mine.createdAt.difference(minaNote.createdAt).inSeconds.abs(),
        lessThan(2),
      );
      expect(got.handoff!.from, isNotEmpty);

      // 세션이 끝나도 링크는 산다. 없는 링크는 없다고 한다.
      await mina.end();
      expect(
        (await link(2).readHandoff(token)).error,
        isNull,
        reason: '링크를 쥔 사람은 읽는다',
      );
      expect((await link(1).readHandoff('x' * 24)).error, HandoffError.gone);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
