// 같이 고치는 한 문서 — 실제 서버, 실제 HTTP, 서로 다른 두 사용자.
//   gymdojo 에서  node scripts/e2e-server.mjs
//   flutter test integration/live_doc_server_test.dart --dart-define=PARTNER_TOKENS=<파일>
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';

const endpoint = String.fromEnvironment(
  'PARTNER_SERVER',
  defaultValue: 'http://127.0.0.1:3999',
);
const tokensFile = String.fromEnvironment('PARTNER_TOKENS');

Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 700));

void main() {
  final tokens = (jsonDecode(File(tokensFile).readAsStringSync()) as Map)
      .cast<String, String>();
  final names = tokens.keys.toList();
  GymLink link(int i) => GymLink(endpoint: endpoint, token: tokens[names[i]]!);

  test(
    '둘이 한 문서를 고친다 — 들어온 사람의 운동이 합쳐지고, 동시에 넣은 세트는 둘 다 남고, 지운 운동에 늦게 온 세트는 사라지고, 커서는 스트림으로 온다',
    () async {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final notes = [
        for (final s in ['a', 'b'])
          Note(
            id: 'live-$stamp-$s',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
      ];
      final bench = ExerciseBlock('벤치프레스', [LoggedSet(value: 60, reps: 10)]);
      notes[0].blocks.add(bench);
      notes[1].blocks.add(ExerciseBlock('풀업', [LoggedSet(reps: 8)]));
      final phones = [
        for (var i = 0; i < 2; i++)
          PartnerSync(note: notes[i], link: () => link(i), onChanged: () {}),
      ];
      for (final p in phones) {
        addTearDown(p.dispose);
      }
      final mina = phones[0], jun = phones[1];
      // 편집기가 하는 일: 새 문서가 오면 그것을 놓는다.
      Future<void> sync() async {
        for (final (i, p) in phones.indexed) {
          await p.refresh();
          final doc = p.takeDoc();
          if (doc != null) notes[i].blocks = doc;
        }
      }

      expect(await mina.invite(), isNull);
      expect(await jun.joinWithCode(mina.session!.code!), isNull);
      await sync(); // 문서가 없으니 누군가 심는다.
      await settle();
      await sync(); // 준은 제 풀업을 얹는다.
      await settle();
      await sync();
      List<String> titles(int i) => [for (final b in notes[i].blocks) b.name];
      expect(titles(0), ['벤치프레스', '풀업']);
      expect(titles(1), ['벤치프레스', '풀업']);

      // 둘이 같은 순간에 벤치에 한 세트씩.
      notes[0].blocks[0].sets.add(LoggedSet(value: 70, reps: 8));
      notes[1].blocks[0].sets.add(LoggedSet(value: 50, reps: 12));
      mina.recordChanged();
      jun.recordChanged();
      await settle();
      await sync();
      final seen = notes[0].blocks[0].sets;
      expect(seen, hasLength(3), reason: '둘 다 남는다');
      expect(seen.map((s) => s.author).whereType<String>(), [names[1]]);
      expect(
        mineOnly(notes[0].blocks)[0].sets,
        hasLength(2),
        reason: '내 기록으로 나가는 곳에는 내 세트만',
      );
      // 먼저 닿은 쪽이 앞이다. 어느 쪽이든 두 화면의 순서는 같다.
      expect(
        notes[1].blocks[0].sets.map((s) => s.reps),
        seen.map((s) => s.reps),
      );
      expect(seen.map((s) => s.reps).toSet(), {10, 8, 12});

      // 커서는 스트림으로 온다.
      final got = Completer<PartnerPresence>();
      final sub = link(0).partnerEvents(mina.session!.id).listen((body) {
        for (final p in (body['presence'] as List? ?? const [])) {
          if ((p as Map)['text'] == '60 1' && !got.isCompleted) {
            got.complete(
              PartnerPresence(
                key: p['key'] as String,
                name: p['name'] as String,
                block: p['block'] as String?,
                set: p['set'] as String?,
                text: p['text'] as String,
              ),
            );
          }
        }
      });
      final watch = Stopwatch()..start();
      jun.presence(block: notes[1].blocks[0].id, set: '+', text: '60 1');
      final where = await got.future.timeout(const Duration(seconds: 5));
      await sub.cancel();
      expect([where.name, where.block, where.set], [names[1], bench.id, '+']);
      // ignore: avoid_print
      print('커서가 상대 화면에 닿기까지 ${watch.elapsedMilliseconds}ms');

      // 미나가 벤치를 지우는 사이 준이 벤치에 한 세트 — 갈 곳이 없어 사라진다.
      notes[0].blocks.removeAt(0);
      notes[1].blocks[0].sets.add(LoggedSet(value: 50, reps: 5));
      mina.recordChanged();
      await settle();
      jun.recordChanged();
      await settle();
      await sync();
      expect(titles(0), ['풀업']);
      expect(titles(1), ['풀업']);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
