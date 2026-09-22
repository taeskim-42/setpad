// 공동 루틴 — 실제 서버, 서로 다른 두 사용자, 앱의 진짜 HTTP 클라이언트.
// "내일 운동 합의 → 당일 시작 → 실제 기록 → 다음 계획" 을 끝까지 돈다.
// 돌리는 법은 partner_server_test.dart 머리말과 같다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/daily.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';
import 'package:setpad/plans.dart';

const endpoint = String.fromEnvironment(
  'PARTNER_SERVER',
  defaultValue: 'http://127.0.0.1:3999',
);
const tokensFile = String.fromEnvironment('PARTNER_TOKENS');

class Phone {
  Phone(this.token, String name)
    : dir = Directory.systemTemp.createTempSync('setpad_plan_it_$name') {
    plans = PlanStore(
      link: () => GymLink(endpoint: endpoint, token: token),
      directory: dir,
    );
    notes = NotesStore(directory: dir);
  }
  final String token;
  final Directory dir;
  late PlanStore plans;
  late final NotesStore notes;

  /// 앱을 껐다 켠다: 디스크에 남은 것만으로 다시 연다.
  Future<void> restart() async {
    await plans.save();
    plans = PlanStore(
      link: () => GymLink(endpoint: endpoint, token: token),
      directory: dir,
    );
    await plans.load();
  }
}

void main() {
  final tokens = (jsonDecode(File(tokensFile).readAsStringSync()) as Map)
      .cast<String, String>();
  final names = tokens.keys.toList();

  test(
    '내일 운동 합의 → 당일 시작 → 실제 기록 → 다음 계획',
    () async {
      final mina = Phone(tokens[names[0]]!, 'a');
      final jun = Phone(tokens[names[1]]!, 'b');
      final sora = Phone(tokens[names[2]]!, 'c');
      addTearDown(() {
        for (final p in [mina, jun, sora]) {
          p.notes.dispose();
          p.dir.deleteSync(recursive: true);
        }
      });
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final day =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

      // 1) 오늘 수행 기록 없이 내일 루틴을 만든다.
      final typed = parsePlanText('내일 하체\n스쿼트 4세트\n민수식 루마니안 데드 2 3세트\n레그컬 3세트');
      final plan = SharedPlan(
        localId: 'it-${DateTime.now().microsecondsSinceEpoch}',
      );
      mina.plans.add(plan);
      expect(
        await mina.plans.edit(
          plan,
          PlanContent(title: typed.title, plannedOn: day, items: typed.items),
        ),
        isNull,
      );
      expect(mina.notes.notes, isEmpty, reason: '운동 기록 없이 계획이 선다');
      expect(
        [plan.state, plan.version, plan.acceptedByMe],
        [PlanState.draft, 1, 1],
      );

      // 0) 떨어져 있는 상대에게는 링크를 보낸다: 하루를 살고, 코드를 새로 뽑아도 죽지 않는다.
      final remote = SharedPlan(
        localId: 'it-link-${DateTime.now().microsecondsSinceEpoch}',
      );
      sora.plans.add(remote);
      await sora.plans.edit(
        remote,
        const PlanContent(
          title: '주말 등',
          items: [PlanItem(id: 'r1', name: '소라식 풀업', sets: 5)],
        ),
      );
      expect(await sora.plans.invite(remote, asLink: true), isNull);
      final url = sora.plans.linkFor(remote)!;
      expect(url, startsWith('$endpoint/plan/'));
      expect(
        remote.linkExpiresAt!.difference(DateTime.now()).inHours,
        greaterThanOrEqualTo(23),
      );
      await sora.plans.invite(remote); // 옆 사람에게 불러 줄 코드도 따로 만든다
      expect(sora.plans.linkFor(remote), url, reason: '코드를 만들어도 보낸 링크는 그대로다');
      // 받은 쪽: 링크에서 토큰을 꺼내 참여한다. 링크를 두 번 열어도 같은 계획이다.
      final token = planTokenFromLink(Uri.parse(url))!;
      final viaLink = await mina.plans.join(token, isToken: true);
      expect(viaLink.error, isNull);
      expect(viaLink.plan!.content.items.single.name, '소라식 풀업');
      expect(
        (await mina.plans.join(token, isToken: true)).plan!.id,
        viaLink.plan!.id,
      );
      // 링크는 살아 있는 동안 한 명 더 받는다. 준은 들어왔다가 나간다.
      final third = await jun.plans.join(token, isToken: true);
      expect(third.error, isNull);
      expect(third.plan!.members.map((m) => m.name).length, 2);
      expect(await jun.plans.withdraw(third.plan!), isNull);
      // 링크가 브라우저로 떨어졌을 때의 안내 화면도 살아 있다(내용은 보여 주지 않는다).
      final page = await HttpClient()
          .getUrl(Uri.parse(url))
          .then((r) => r.close());
      final html = await page.transform(utf8.decoder).join();
      expect(page.statusCode, 200);
      expect(html, contains('setpad://plan/$token'));
      expect(html, isNot(contains('소라식 풀업')));
      await mina.plans.withdraw(viaLink.plan!);

      // 2) 초대 → 참여 → 양쪽에 같은 계획.
      expect(await mina.plans.invite(plan), isNull);
      final code = plan.code!;
      expect((await mina.plans.join(code)).error, PartnerError.ownInvite);
      final joined = await jun.plans.join(' ${code.toLowerCase()} ');
      expect(joined.error, isNull);
      final theirs = joined.plan!;
      expect(theirs.content.toJson(), plan.content.toJson());
      expect(theirs.content.plannedOn, day, reason: '날짜만 — 시각 없이');
      // 3) 사용자 운동명 보존.
      expect(theirs.content.items[1].name, '민수식 루마니안 데드 2');
      // 15) 초대받지 않은 사람은 아무것도 못 한다. (코드를 아는 세 번째 사람은 들어올 수 있다 —
      // 그것이 셋이 짜는 길이다. 여기서는 둘의 흐름을 보려고 바로 나가게 한다.)
      final asThird = await sora.plans.join(code);
      expect(asThird.error, isNull);
      expect(await sora.plans.withdraw(asThird.plan!), isNull);
      final intruder = SharedPlan(localId: 'x')..id = plan.id;
      expect(await sora.plans.refresh(intruder), PartnerError.ended);
      intruder.version = 1;
      expect(await sora.plans.accept(intruder), PartnerError.ended);
      intruder.draft = const PlanContent(title: '가로채기');
      expect(await sora.plans.savePlan(intruder), PartnerError.ended);

      // 4) 각자의 서로 다른 목표.
      final squat = plan.content.items.first.id;
      mina.plans.setTarget(
        plan,
        squat,
        const PlanTarget(value: 100, reps: 5, note: '무릎 조심'),
      );
      jun.plans.setTarget(
        theirs,
        squat,
        const PlanTarget(value: 135, unit: 'lb', reps: 8, sets: 3),
      );
      await mina.plans.pushTargets(plan);
      await jun.plans.pushTargets(theirs);
      await mina.plans.refresh(plan);
      await jun.plans.refresh(theirs);
      expect(
        (plan.partnerTargets[squat]!.value, plan.partnerTargets[squat]!.unit),
        (135, 'lb'),
      );
      expect(
        (
          theirs.partnerTargets[squat]!.value,
          theirs.partnerTargets[squat]!.note,
        ),
        (100, '무릎 조심'),
      );
      expect(plan.myTargets[squat]!.value, 100, reason: '같은 종목이어도 무게는 각자다');

      // 5) 양쪽이 같은 버전을 수락해야 합의.
      expect(plan.state, PlanState.pending);
      expect(await jun.plans.accept(theirs), isNull);
      await mina.plans.refresh(plan);
      expect(
        [plan.state, plan.agreedVersion, theirs.state],
        [PlanState.agreed, 1, PlanState.agreed],
      );

      // 6) 합의 후 내용을 고치면 다시 확인해야 하고, 마지막 합의본은 남는다.
      final reordered = parsePlanText(
        '내일 하체\n민수식 루마니안 데드 2 3세트\n스쿼트 5세트',
        previous: theirs.content.items,
      );
      expect(
        await jun.plans.edit(
          theirs,
          PlanContent(
            title: reordered.title,
            plannedOn: day,
            items: reordered.items,
          ),
        ),
        isNull,
      );
      await mina.plans.refresh(plan);
      expect(
        [plan.state, plan.version, plan.needsMyAccept],
        [PlanState.pending, 2, true],
      );
      expect([plan.agreedVersion, plan.agreed!.items.length], [1, 3]);
      final diff = planDiff(plan.agreed!, plan.content);
      expect(
        [diff.removed, diff.changed, diff.reordered],
        [
          ['레그컬'],
          ['스쿼트'],
          true,
        ],
      );
      expect(
        plan.myTargets[squat]!.value,
        100,
        reason: '순서가 바뀌어도 내 목표는 제 종목에 있다',
      );

      // 7) 동시 수정: 미나는 옛 버전 위에서 고치고 있었다 → 충돌, 내 초안은 남는다.
      final stale = SharedPlan.tryFromJson(plan.toJson())!..version = 1;
      final mine = parsePlanText(
        '내일 하체 (미나안)\n스쿼트 4세트\n런지 3세트',
        previous: plan.agreed!.items,
      );
      final myDraft = PlanContent(
        title: mine.title,
        plannedOn: day,
        items: mine.items,
      );
      mina.plans.plans
        ..remove(plan)
        ..add(stale);
      await mina.plans.edit(stale, myDraft);
      expect(stale.conflict, isTrue);
      expect(stale.draft!.title, '내일 하체 (미나안)', reason: '내 입력이 조용히 사라지지 않는다');
      expect(stale.content.title, '내일 하체', reason: '최신 내용도 확인할 수 있다');
      expect(stale.version, 2);
      await jun.plans.refresh(theirs);
      expect(theirs.content.title, '내일 하체', reason: '상대의 저장이 덮이지 않았다');
      // 최신을 보고 받아들인다 → 그 버전을 수락 → 합의 v2.
      mina.plans.takeLatest(stale);
      expect(await mina.plans.accept(stale), isNull);
      expect([stale.state, stale.agreedVersion], [PlanState.agreed, 2]);

      // 8) 초대 코드는 죽었지만 참여한 두 사람은 계획을 연다. 9) 앱을 껐다 켜도 복원된다.
      await jun.restart();
      final restored = jun.plans.plans.single;
      expect(
        [restored.id, restored.agreedVersion, restored.state],
        [plan.id, 1, PlanState.pending],
        reason: '디스크에는 끄기 전 상태가 있다',
      );
      await jun.plans.refresh(restored);
      expect(
        [restored.state, restored.agreedVersion, restored.content.items.length],
        [PlanState.agreed, 2, 2],
      );
      expect(restored.myTargets[squat]!.sets, 3);

      // 10) 계획을 시작해도 완료 세트는 없다. 11) 버전과 연결된다.
      final note = await startWorkout(jun.plans, jun.notes, restored);
      expect(
        [note.planId, note.planVersion, note.planAgreed],
        [plan.id, 2, true],
      );
      expect(note.blocks.map((b) => b.name), ['민수식 루마니안 데드 2', '스쿼트']);
      expect(note.blocks.last.sets, hasLength(3), reason: '준의 개인 세트 수');
      expect(note.blocks.expand((b) => b.sets).where((s) => s.done), isEmpty);
      expect(
        dayLogs([note], from: note.createdAt, to: note.createdAt),
        isEmpty,
        reason: '시작만으로는 운동한 날도 아니다',
      );
      // 다시 눌러도 같은 운동이다.
      final again = await startWorkout(jun.plans, jun.notes, restored);
      expect(again.id, note.id);
      expect(jun.notes.notes, hasLength(1));
      // 한 명이 먼저 시작했고, 상대는 그 사실과 버전만 안다.
      await mina.plans.refresh(stale);
      expect(stale.partnerStartedVersion, 2);

      // 12) 실제 수행을 고쳐도 계획은 그대로다. 운동을 더하고 빼도 된다.
      note.blocks.last.sets
        ..[0] = LoggedSet(value: 140, unit: 'lb', reps: 6)
        ..[1] = LoggedSet(value: 140, unit: 'lb', reps: 5);
      note.blocks.add(ExerciseBlock('카프 레이즈', [LoggedSet(reps: 15)]));
      jun.notes.update(note, note.blocks);
      await jun.plans.refresh(restored);
      expect(restored.myTargets[squat]!.value, 135);
      expect(restored.agreed!.items.map((i) => i.name), [
        '민수식 루마니안 데드 2',
        '스쿼트',
      ]);
      expect(note.blocks.last.sets.where((s) => s.done), hasLength(1));

      // 시작 뒤에 계획이 바뀌어도 진행 중인 운동은 자동으로 바뀌지 않는다.
      final v3 = parsePlanText('내일 하체\n스쿼트 5세트', previous: stale.content.items);
      await mina.plans.edit(
        stale,
        PlanContent(title: v3.title, plannedOn: day, items: v3.items),
      );
      await jun.plans.refresh(restored);
      expect(restored.version, 3);
      expect(note.blocks.map((b) => b.name), [
        '민수식 루마니안 데드 2',
        '스쿼트',
        '카프 레이즈',
      ]);
      expect(note.planVersion, 2);
      // 늦게 합류한 미나는 합의 안 된 v3 이 아니라 마지막 합의본 v2 로 시작한다.
      final minaNote = await startWorkout(mina.plans, mina.notes, stale);
      expect([minaNote.planVersion, minaNote.planAgreed], [2, true]);
      expect(minaNote.blocks.map((b) => b.name), ['민수식 루마니안 데드 2', '스쿼트']);
      expect(minaNote.blocks.last.sets.first.value, 100);

      // 16) 파트너의 기록은 내 통계에 들지 않는다: 하루 집계는 내 문서만 읽는다.
      final logs = dayLogs(
        jun.notes.notes,
        from: note.createdAt,
        to: note.createdAt,
      );
      expect(logs.single.notes.single.id, note.id);
      expect(jun.notes.notes.any((n) => n.id == minaNote.id), isFalse);

      // 13) 실시간 공유 세션을 끝내도 합의한 계획과 내 기록은 남는다.
      final live = PartnerSync(
        note: note,
        link: () => GymLink(endpoint: endpoint, token: jun.token),
        onChanged: () {},
      );
      final liveMina = PartnerSync(
        note: minaNote,
        link: () => GymLink(endpoint: endpoint, token: mina.token),
        onChanged: () {},
      );
      addTearDown(live.dispose);
      addTearDown(liveMina.dispose);
      await liveMina.invite();
      await live.joinWithCode(minaNote.partner!.code!);
      await live.end();
      expect(note.partner!.state, PartnerState.ended);
      await jun.plans.refresh(restored);
      expect([restored.agreedVersion, restored.startedNoteId], [2, note.id]);
      expect(note.blocks, hasLength(3));

      // 14) 다음 계획으로 복사: 새 초안, 완료·합의 없음, 지난 것은 그대로.
      final next = copyPlan(restored);
      jun.plans.add(next);
      await jun.plans.push();
      expect(next.id, isNot(plan.id));
      expect(
        [next.state, next.version, next.agreedVersion, next.startedNoteId],
        [PlanState.draft, 1, null, null],
      );
      expect(next.content.items.map((i) => i.name), ['민수식 루마니안 데드 2', '스쿼트']);
      expect(next.content.plannedOn, isNull);
      final fromRecord = planFromBlocks('지난 하체', note.blocks);
      expect(fromRecord.shown.items.map((i) => (i.name, i.sets)), [
        ('민수식 루마니안 데드 2', 3),
        ('스쿼트', 3),
        ('카프 레이즈', 1),
      ]);
      await jun.plans.refresh(restored);
      expect([restored.agreedVersion, restored.startedVersion], [2, 2]);

      // 나가는 것은 별도 동작이다: 남은 사람은 합의본과 자기 것을 보고(다시 혼자인 초안), 떠난 쪽의 새 것은 오지 않는다.
      expect(await jun.plans.withdraw(restored), isNull);
      await mina.plans.refresh(stale);
      expect(stale.state, PlanState.draft);
      expect([stale.agreedVersion, stale.myTargets[squat]!.value], [2, 100]);
      expect(stale.partnerTargets, isEmpty);
      expect(await jun.plans.refresh(restored), PartnerError.ended);
      expect(minaNote.blocks, hasLength(2), reason: '내 운동은 그대로다');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
