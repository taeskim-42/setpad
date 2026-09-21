// 같이 하는 타이머 — 실제 서버, 실제 HTTP, 서로 다른 두 사용자.
//
// 돌리는 법은 partner_server_test.dart 와 같다:
//   gymdojo 에서  node scripts/e2e-server.mjs
//   flutter test integration/timer_server_test.dart --dart-define=PARTNER_TOKENS=<파일>
//
// 여기서 재는 것은 **두 폰이 계산한 자리의 차이**다. 가짜 서버로는 0 이 나올
// 수밖에 없는 값이라, 진짜 왕복 시간이 끼는 곳에서 따로 잰다. 한 기계 안의
// 서버라 왕복이 짧다 — 실제 그물에서의 값은 아니다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';
import 'package:setpad/workout_timing.dart';

const endpoint = String.fromEnvironment(
  'PARTNER_SERVER',
  defaultValue: 'http://127.0.0.1:3999',
);
const tokensFile = String.fromEnvironment('PARTNER_TOKENS');

PartnerSync phone(String token, String noteId) => PartnerSync(
  note: Note(id: noteId, createdAt: DateTime.now(), updatedAt: DateTime.now()),
  link: () => GymLink(endpoint: endpoint, token: token),
  onChanged: () {},
);

void main() {
  final tokens = (jsonDecode(File(tokensFile).readAsStringSync()) as Map)
      .cast<String, String>();
  final names = tokens.keys.toList();

  test(
    '제안 → 받기 → 두 폰이 같은 자리 → 그만두기 → 다시 들어가기 → 치우기',
    () async {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final mina = phone(tokens[names[0]]!, 'timer-$stamp-a');
      final jun = phone(tokens[names[1]]!, 'timer-$stamp-b');
      final sora = phone(tokens[names[2]]!, 'timer-$stamp-c');
      addTearDown(mina.dispose);
      addTearDown(jun.dispose);
      addTearDown(sora.dispose);

      expect(await mina.invite(), isNull);
      // 혼자서는 제안할 수 없다 — 앱은 묻지도 않는다.
      await mina.proposeTimer(
        '버피 타바타 20/10 x8',
        const TimingSpec(tabata: true),
      );
      expect(mina.session!.timer, isNull);

      expect(await jun.joinWithCode(mina.session!.code!), isNull);
      await mina.refresh();
      expect(mina.clock.now, isNotNull, reason: '서버가 시각을 알려 준다');

      await mina.proposeTimer(
        '버피 타바타 20/10 x8',
        const TimingSpec(tabata: true),
        alternate: true,
      );
      final proposed = mina.session!.timer!;
      expect(
        [proposed.mine, proposed.started, proposed.alternate, proposed.title],
        [true, false, true, '버피 타바타 20/10 x8'],
      );

      // 제안한 사람은 스스로 받을 수 없다.
      await mina.acceptTimer();
      expect(mina.session!.timer!.started, isFalse);

      await jun.refresh();
      expect(jun.session!.timer!.mine, isFalse);
      expect(jun.session!.timer!.spec, const TimingSpec(tabata: true));
      await jun.acceptTimer();
      final accepted = jun.session!.timer!;
      final lead = accepted.startAt! - jun.clock.now!;
      expect(
        lead,
        inInclusiveRange(1500, 2500),
        reason: '시작은 조금 뒤다: ${lead}ms',
      );
      // 두 번 받아도 시작 시각은 움직이지 않는다.
      await jun.acceptTimer();
      expect(jun.session!.timer!.startAt, accepted.startAt);

      // 두 폰이 각자 잰 서버 시계로 같은 순간에 자리를 계산한다.
      final gaps = <int>[];
      for (var i = 0; i < 10; i++) {
        await Future.wait([mina.refresh(), jun.refresh()]);
        final a = mina.session!.timer!.elapsedAt(mina.clock.now)!;
        final b = jun.session!.timer!.elapsedAt(jun.clock.now)!;
        // 교대라서 준은 미나보다 정확히 (20+10)초 뒤에 있다.
        gaps.add((a.inMilliseconds - b.inMilliseconds - 30000).abs());
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      // ignore: avoid_print
      print('두 폰이 계산한 자리의 차이(ms): $gaps');
      expect(gaps.reduce((a, b) => a > b ? a : b), lessThan(50));

      // 남의 세션에는 닿지 못한다.
      expect(sora.session, isNull);
      final outsider =
          await GymLink(
            endpoint: endpoint,
            token: tokens[names[2]]!,
          ).partnerTimer(mina.session!.id, {
            'action': 'clear',
            'seq': accepted.seq,
          });
      expect(outsider.error, PartnerError.ended, reason: '없는 것과 같은 답이다');
      await mina.refresh();
      expect(mina.session!.timer, isNotNull);

      // 그만두는 것은 각자다.
      await jun.leaveTimer(const Duration(seconds: 47), 12);
      await mina.refresh();
      expect(mina.session!.timer!.partnerLeft, (ms: 47000, beat: 12));
      expect(mina.session!.timer!.myLeft, isNull);
      await jun.rejoinTimer();
      await mina.refresh();
      expect(mina.session!.timer!.partnerLeft, isNull);

      // 어느 쪽이든 치울 수 있고, 끝난 세션에는 타이머가 없다.
      await jun.clearTimer();
      await mina.refresh();
      expect(mina.session!.timer, isNull);
      await mina.proposeTimer('스쿼트 60bpm', const TimingSpec(bpm: 60));
      expect(mina.session!.timer!.seq, greaterThan(accepted.seq));
      await jun.end();
      await mina.refresh();
      expect(mina.session!.state, PartnerState.ended);
      expect(mina.session!.timer, isNull);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
