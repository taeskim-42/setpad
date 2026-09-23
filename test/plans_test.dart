// 공동 루틴의 글 읽기·바뀐 것 찾기·운동 시작·다음 계획 복사.
// 서버와의 합의 흐름은 integration/plan_server_test.dart 가 실제 서버로 검증한다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/plans.dart';

void main() {
  test('초대 링크에서 토큰을 꺼내고, 아닌 것은 건드리지 않는다', () {
    const token = 'AbCdEfGhIjKlMnOpQrStUv_-';
    expect(
      planTokenFromLink(Uri.parse('https://gym.darak.studio/plan/$token')),
      token,
    );
    // 웹 화면의 "앱에서 열기" 가 부르는 주소 — 이때는 plan 이 host 다.
    expect(planTokenFromLink(Uri.parse('setpad://plan/$token')), token);
    expect(
      planTokenFromLink(
        Uri.parse('https://gym.darak.studio/plan/$token?utm=x'),
      ),
      token,
    );
    for (final other in [
      'https://gym.darak.studio/c/11111111-2222-3333-4444-555555555555',
      'https://gym.darak.studio/plan/',
      'https://gym.darak.studio/plan/short',
      'https://gym.darak.studio/plan/has spaces and <script>',
      'setpad://c/some-gym',
    ]) {
      expect(planTokenFromLink(Uri.parse(other)), isNull, reason: other);
    }
  });

  test('C·계획 코드 칸에 받은 공유 문구를 붙여 넣으면 그 링크로, 코드가 든 문장이면 그 코드로 참여한다', () async {
    const token = 'AbCdEfGhIjKlMnOpQrStUv_-';
    expect(
      planTokenInText(
        "Let's plan our workout together in setpad: https://gym.darak.studio/plan/$token.",
      ),
      token,
      reason: '문장 끝의 마침표는 링크가 아니다',
    );
    expect(planTokenInText('setpad://plan/$token 에서 열어 줘'), token);
    expect(planTokenInText('AB3K9Z'), isNull);
    expect(planTokenInText('https://gym.darak.studio/c/some-gym'), isNull);

    final dir = Directory.systemTemp.createTempSync('setpad_plan_join_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final bodies = <Object?>[];
    final plans = PlanStore(
      directory: dir,
      link: () => GymLink(
        endpoint: 'https://x',
        token: 'member',
        client: MockClient((request) async {
          bodies.add(jsonDecode(request.body));
          return http.Response('{"error":"invalidCode"}', 404);
        }),
      ),
    );
    await plans.join(
      'setpad에서 운동 계획을 같이 짜요: https://gym.darak.studio/plan/$token',
    );
    await plans.join('같이 짜요, 코드는 AB3K9Z 예요');
    expect(bodies, [
      {'token': token},
      {'code': 'AB3K9Z'},
    ]);
  });

  test('메모장처럼 친 글을 계획으로 읽고, 사용자 운동명을 그대로 둔다', () {
    final plan = parsePlanText('''
내일 하체
스쿼트 4세트
루마니안 데드리프트 3세트
민수식 로우 2
레그컬 x3
Hip thrust 5 sets
''');
    expect(plan.title, '내일 하체');
    expect(plan.items.map((i) => (i.name, i.sets)), [
      ('스쿼트', 4),
      ('루마니안 데드리프트', 3),
      ('민수식 로우 2', 0), // 이름 끝의 숫자는 세트 수가 아니다
      ('레그컬', 3),
      ('Hip thrust', 5),
    ]);
    // 순서를 바꾸고 세트 수를 고쳐도 같은 종목은 같은 id 다 — 목표가 따라간다.
    final again = parsePlanText('내일 하체\n레그컬 x4\n스쿼트 4세트', previous: plan.items);
    expect(again.items[0].id, plan.items[3].id);
    expect(again.items[1].id, plan.items[0].id);
    expect(parsePlanText('   ').items, isEmpty);
    expect(
      planText(plan.title, plan.items.take(3).toList(), (n) => '$n세트'),
      '내일 하체\n스쿼트 4세트\n루마니안 데드리프트 3세트\n민수식 로우 2',
    );
  });

  test('무엇이 바뀌었는지 말한다', () {
    final v1 = parsePlanText('하체\n스쿼트 4세트\n레그컬 3세트\n런지 3세트');
    final v2 = parsePlanText(
      '하체\n런지 3세트\n스쿼트 5세트\n카프 레이즈 4세트',
      previous: v1.items,
    );
    final d = planDiff(
      PlanContent(title: v1.title, plannedOn: '2026-09-22', items: v1.items),
      PlanContent(title: v2.title, plannedOn: '2026-09-23', items: v2.items),
    );
    expect(d.added, ['카프 레이즈']);
    expect(d.removed, ['레그컬']);
    expect(d.changed, ['스쿼트']);
    expect([d.reordered, d.dateChanged, d.titleChanged], [true, true, false]);
  });

  test('계획으로 만든 운동 칸은 전부 안 한 세트이고, 각자의 목표에서 출발한다', () {
    final items = parsePlanText('하체\n스쿼트 4세트\n레그컬 3세트').items;
    final blocks = blocksFromPlan(PlanContent(items: items), {
      items[0].id: const PlanTarget(value: 100, reps: 5, note: '무릎 조심'),
      items[1].id: const PlanTarget(value: 90, unit: 'lb', reps: 12, sets: 2),
    });
    expect(blocks.map((b) => (b.name, b.sets.length)), [
      ('스쿼트', 4),
      ('레그컬', 2),
    ]);
    expect(
      blocks.expand((b) => b.sets).every((s) => !s.done),
      isTrue,
      reason: '계획을 시작했다고 완료한 세트가 생기지 않는다',
    );
    expect(blocks.expand((b) => b.sets).where((s) => s.done), isEmpty);
    expect(blocks[0].completedReps, 0);
    expect((blocks[1].sets.first.value, blocks[1].sets.first.unit), (90, 'lb'));
    expect(blocks[0].sets.first.notes, ['무릎 조심']);
  });

  test('다음 운동으로 복사하면 새 초안이다 — 완료도 합의도 따라오지 않고 원본은 그대로다', () {
    final done = [
      ExerciseBlock('내 방식 스쿼트', [
        LoggedSet(value: 100, reps: 5),
        LoggedSet(value: 105, reps: 3),
        LoggedSet(value: 110, reps: 1, done: false),
      ]),
      ExerciseBlock('풀업', [LoggedSet(reps: 8)]),
    ];
    final next = planFromBlocks('오늘 하체', done);
    expect(next.state, PlanState.local);
    expect(next.id, isNull);
    expect(next.agreedVersion, isNull);
    expect(next.shown.items.map((i) => (i.name, i.sets)), [
      ('내 방식 스쿼트', 3),
      ('풀업', 1),
    ]);
    // 목표는 실제로 **해낸** 마지막 세트에서 온다.
    final squat = next.myTargets[next.shown.items.first.id]!;
    expect((squat.value, squat.reps), (105, 3));
    expect(done.first.sets.map((s) => s.done), [true, true, false]);

    final agreed = SharedPlan(localId: 'old')
      ..id = 'server-id'
      ..state = PlanState.agreed
      ..version = 3
      ..agreedVersion = 3
      ..acceptedByMe = 3
      ..startedNoteId = 'note-1'
      ..content = PlanContent(
        title: '하체',
        plannedOn: '2026-09-22',
        items: next.shown.items,
      )
      ..agreed = PlanContent(
        title: '하체',
        plannedOn: '2026-09-22',
        items: next.shown.items,
      )
      ..myTargets = {
        next.shown.items.first.id: const PlanTarget(value: 100, reps: 5),
      };
    final copy = copyPlan(agreed);
    expect(
      [copy.id, copy.agreedVersion, copy.acceptedByMe, copy.startedNoteId],
      [null, null, null, null],
    );
    expect(copy.state, PlanState.local);
    expect(copy.shown.plannedOn, isNull, reason: '다음 날짜는 새로 정한다');
    expect(copy.shown.items.map((i) => i.name), ['내 방식 스쿼트', '풀업']);
    expect(copy.myTargets.values.single.value, 100);
    expect(agreed.state, PlanState.agreed, reason: '지난 계획은 바뀌지 않는다');
    // 저장했다 읽어도 같다.
    final back = SharedPlan.tryFromJson(agreed.toJson())!;
    expect(
      [back.id, back.agreedVersion, back.startedNoteId],
      ['server-id', 3, 'note-1'],
    );
  });
}
