// 셋이 같이 하기 — 실제 서버, 실제 HTTP, 서로 다른 세 사용자.
//   gymdojo 에서  node scripts/e2e-server.mjs
//   flutter test integration/group_server_test.dart --dart-define=PARTNER_TOKENS=<파일>
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/handoff.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';
import 'package:setpad/workout_timing.dart';

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
    '세 사람이 한 코드로 모이고, 각자의 기록을 보고, 동의한 사람만 타이머를 돌리고, 한 명이 나가도 이어진다',
    () async {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final notes = [
        for (final s in ['a', 'b', 'c'])
          Note(
            id: 'grp-$stamp-$s',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
      ];
      final phones = [
        for (var i = 0; i < 3; i++)
          PartnerSync(note: notes[i], link: () => link(i), onChanged: () {}),
      ];
      for (final p in phones) {
        addTearDown(p.dispose);
      }
      final mina = phones[0], jun = phones[1], sora = phones[2];

      expect(await mina.invite(), isNull);
      final code = mina.session!.code!;
      expect(await jun.joinWithCode(code), isNull);
      expect(
        await sora.joinWithCode(code),
        isNull,
        reason: '같은 코드로 한 명 더 들어온다',
      );
      await mina.refresh();
      expect(mina.session!.others, hasLength(2));
      expect(mina.session!.code, code, reason: '호스트는 코드를 계속 본다');
      expect(mina.session!.room, 3);
      expect(sora.session!.others.map((p) => p.name).toSet().length, 2);

      // 소라의 기록이 소라의 이름 아래로 간다.
      notes[2].blocks.add(
        ExerciseBlock('스쿼트', [LoggedSet(value: 60, reps: 8)]),
      );
      sora.recordChanged();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await mina.refresh();
      final soraSeen = mina.session!.others.firstWhere(
        (p) => p.blocks.isNotEmpty,
      );
      expect(soraSeen.blocks.single.name, '스쿼트');

      // 미나가 제안하고 준만 받는다 — 소라는 동의하지 않았다.
      await mina.proposeTimer('스쿼트 60bpm', const TimingSpec(bpm: 60));
      await jun.refresh();
      await jun.acceptTimer();
      await sora.refresh();
      await mina.refresh();
      expect(mina.session!.timer!.started, isTrue);
      expect(
        [jun.session!.timer!.joined, sora.session!.timer!.joined],
        [true, false],
      );
      expect(mina.session!.timer!.others, hasLength(1));
      // 소라가 나중에 받는다 — 시작 시각은 그대로다.
      final startAt = mina.session!.timer!.startAt;
      await sora.acceptTimer();
      expect(sora.session!.timer!.joined, isTrue);
      expect(sora.session!.timer!.startAt, startAt);

      // 미나가 소라의 세트를 대신 적는다 — 소라에게만 받기가 뜬다.
      notes[0].proxy = ProxyRecord(
        name: soraSeen.name,
        forKey: soraSeen.key,
        blocks: [
          ExerciseBlock('런지', [LoggedSet(reps: 12)]),
        ],
        revision: 1,
      );
      expect(
        await link(0).sendProxy(notes[0], sessionId: mina.session!.id),
        isNull,
      );
      await jun.refresh();
      await sora.refresh();
      expect(jun.session!.handoff, isNull);
      expect(sora.session!.handoff!.token, notes[0].proxy!.token);

      // 준이 나간다. 나머지 둘은 계속한다.
      await jun.end();
      expect(jun.session!.state, PartnerState.ended);
      await mina.refresh();
      expect(mina.session!.state, PartnerState.active);
      expect(mina.session!.others, hasLength(1));
      // 호스트가 끝내면 모두에게 끝난다.
      await mina.end();
      await sora.refresh();
      expect(sora.session!.state, PartnerState.ended);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
