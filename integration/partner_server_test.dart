// 실제 서버 통합 검증 — 앱의 진짜 HTTP 클라이언트로, 서로 다른 두 사용자가.
//
// 평소 `flutter test` 에는 들어가지 않는다(서버가 있어야 한다). 돌리는 법:
//   gymdojo 에서  node scripts/e2e-server.mjs   (임베디드 Postgres + next, 운영 DB 와 무관)
//   테스트 사용자 토큰을 만들어 PARTNER_TOKENS 파일(JSON: {이름: 토큰})로 두고
//   flutter test integration/partner_server_test.dart --dart-define=PARTNER_TOKENS=<파일>
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

PartnerSync phone(String token, String noteId) {
  final note = Note(
    id: noteId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  return PartnerSync(
    note: note,
    link: () => GymLink(endpoint: endpoint, token: token),
    onChanged: () {},
  );
}

Future<void> wait([int ms = 900]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  final tokens = (jsonDecode(File(tokensFile).readAsStringSync()) as Map)
      .cast<String, String>();
  final names = tokens.keys.toList();

  test(
    '두 사용자가 실제 서버에서 연결하고, 기록을 주고받고, 끝낸다',
    () async {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final mina = phone(tokens[names[0]]!, 'it-$stamp-a');
      final jun = phone(tokens[names[1]]!, 'it-$stamp-b');
      final sora = phone(tokens[names[2]]!, 'it-$stamp-c');
      addTearDown(mina.dispose);
      addTearDown(jun.dispose);
      addTearDown(sora.dispose);

      // 1. 서버에 올린 적 없는 로컬 운동으로 초대한다.
      expect(await mina.invite(), isNull);
      final code = mina.session!.code!, token = mina.session!.token!;
      expect(mina.session!.state, PartnerState.waiting);
      expect(code, matches(r'^[A-HJ-NP-Z2-9]{6}$'));
      expect(mina.session!.expiresAt!.isAfter(DateTime.now()), isTrue);
      // 두 번 눌러도 같은 초대다.
      await mina.invite();
      expect(mina.session!.code, code);

      // 2. 잘못된 길들은 저마다 다른 이유로 막힌다.
      expect(await mina.joinWithCode(code), PartnerError.ownInvite);
      expect(await jun.joinWithCode('ZZZZZ9'), PartnerError.invalidCode);
      final stranger = PartnerSync(
        note: Note(
          id: 'x',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        link: () => const GymLink(endpoint: endpoint, token: 'not-a-token'),
        onChanged: () {},
      );
      addTearDown(stranger.dispose);
      expect(await stranger.invite(), PartnerError.signInRequired);

      // 3. 참여 — 소문자로, 공백을 섞어 쳐도.
      expect(await jun.joinWithCode(' ${code.toLowerCase()} '), isNull);
      expect(jun.session!.state, PartnerState.active);
      expect(jun.session!.partnerName, names[0]);
      // 같은 초대의 토큰을 또 대도(재시도) 같은 세션이다.
      final again = phone(tokens[names[1]]!, 'it-$stamp-b');
      addTearDown(again.dispose);
      expect(await again.joinWithToken(token), isNull);
      expect(again.session!.id, jun.session!.id);
      // 다른 사람은 그 코드로 못 들어온다.
      expect(await sora.joinWithCode(code), PartnerError.invalidCode);

      // 4. 호스트 화면도 참여를 안다.
      await mina.refresh();
      expect(mina.session!.state, PartnerState.active);
      expect(mina.session!.partnerName, names[1]);

      // 5. 세트를 고친 순간부터 상대 클라이언트가 그것을 **관측할 때까지**를 잰다.
      //    확인 주기가 아니라 실제로 걸린 시간이다: 모으기 + 업로드 + 상대의 다음 확인.
      //    시작 위상을 흩어 여러 번 재고 최소·중앙·최대를 낸다.
      mina.note.blocks.add(
        ExerciseBlock('내 방식 벤치 변형', [
          LoggedSet(value: 102.5, unit: 'lb', reps: 8, notes: ['어깨 조심']),
        ]),
      );
      jun.start(); // 화면이 떠 있는 동안 도는 확인
      final samples = <int>[];
      for (var i = 0; i < 7; i++) {
        await wait(300 + i * 370); // 확인 주기와 어긋난 시각에 고친다
        final reps = 20 + i;
        mina.note.blocks.single.sets[0] = LoggedSet(
          value: 102.5,
          unit: 'lb',
          reps: reps,
          notes: ['어깨 조심'],
        );
        final sent = DateTime.now();
        mina.recordChanged();
        while (jun.session!.partnerBlocks.firstOrNull?.sets.firstOrNull?.reps !=
                reps &&
            DateTime.now().difference(sent) < const Duration(seconds: 8)) {
          await wait(20);
        }
        samples.add(DateTime.now().difference(sent).inMilliseconds);
      }
      jun.stop();
      samples.sort();
      // ignore: avoid_print
      print(
        '[integration] 수정→상대 관측 ${samples.length}회: '
        '최소 ${samples.first}ms · 중앙 ${samples[samples.length ~/ 2]}ms · 최대 ${samples.last}ms · 전체 $samples',
      );
      expect(samples.last, lessThan(3000), reason: '가장 느린 것도 3초 안이어야 한다');
      mina.note.blocks.single.sets[0] = LoggedSet(
        value: 102.5,
        unit: 'lb',
        reps: 8,
        notes: ['어깨 조심'],
      );
      mina.recordChanged();
      await wait();
      await jun.refresh();
      final seen = jun.session!.partnerBlocks.single;
      expect(seen.name, '내 방식 벤치 변형');
      expect(
        (seen.sets.single.value, seen.sets.single.unit, seen.sets.single.reps),
        (102.5, 'lb', 8),
      );
      expect(seen.sets.single.notes, ['어깨 조심']);

      // 6. 수정·삭제·완료 상태.
      mina.note.blocks.single.sets
        ..single.done = false
        ..add(LoggedSet(value: 105, unit: 'lb', reps: 6));
      mina.recordChanged();
      await wait();
      mina.note.blocks.single.sets.removeLast();
      mina.recordChanged();
      await wait();
      await jun.refresh();
      expect(jun.session!.partnerBlocks.single.sets, hasLength(1));
      expect(jun.session!.partnerBlocks.single.sets.single.done, isFalse);

      // 7. 늦게 도착한 옛 전체본은 거절된다.
      final late = await GymLink(
        endpoint: endpoint,
        token: tokens[names[0]],
      ).savePartnerRecord(mina.session!.id, 1, const [], base: 0);
      expect(late.body?['error'], 'conflict');

      // 8. 재진입: 저장해 둔 세션으로 다시 물으면 같은 상태가 복구된다.
      final reopened = Note.fromJson(
        jsonDecode(jsonEncode(jun.note.toJson())) as Map<String, dynamic>,
      );
      final back = PartnerSync(
        note: reopened,
        link: () => GymLink(endpoint: endpoint, token: tokens[names[1]]),
        onChanged: () {},
      );
      addTearDown(back.dispose);
      await back.refresh();
      expect(back.session!.state, PartnerState.active);
      expect(back.session!.partnerBlocks.single.sets, hasLength(1));

      // 9. 끝내기. 각자의 운동은 남고, 상대 기록 접근은 멈춘다.
      await jun.end();
      expect(jun.session!.state, PartnerState.ended);
      await mina.refresh();
      expect(mina.session!.state, PartnerState.ended);
      expect(mina.session!.endedByMe, isFalse);
      expect(mina.note.blocks.single.name, '내 방식 벤치 변형');
      expect(mina.session!.partnerBlocks, isEmpty);
      expect(await sora.joinWithToken(token), PartnerError.invalidCode);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
