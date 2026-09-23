// 공동 루틴의 글 읽기·바뀐 것 찾기·운동 시작·다음 계획 복사.
// 서버와의 합의 흐름은 integration/plan_server_test.dart 가 실제 서버로 검증한다.
import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

import 'package:setpad/editor.dart';
import 'package:setpad/plans.dart';
import 'package:setpad/workout_timing.dart';

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

  test('계획 글의 AxB 는 세트 수×횟수이고, 무게·횟수는 이름이 아니라 목표 글이다', () {
    final plan = parsePlanText('''
하체
벤치 3x10
스쿼트 5×5
벤치 10회 3세트
벤치 80kg 5세트
데드 3 x 5
로우 80 10
민수식 로우 2
레그컬 x3
''');
    expect(plan.title, '하체');
    expect(plan.items.map((i) => (i.name, i.sets)), [
      ('벤치', 3),
      ('스쿼트', 5),
      ('벤치', 3),
      ('벤치', 5),
      ('데드', 3),
      ('로우', 0),
      ('민수식 로우 2', 0), // 맨숫자 하나는 여전히 이름이다
      ('레그컬', 3),
    ]);
    String? target(int i) => plan.targets[plan.items[i].id];
    PlanTarget? read(int i) =>
        target(i) == null ? null : planTarget(target(i)!, 'kg');
    expect(read(0)?.reps, 10);
    expect(read(1)?.reps, 5);
    expect(read(2)?.reps, 10);
    expect((read(3)?.value, read(3)?.unit, read(3)?.reps), (80, 'kg', null));
    expect(read(4)?.reps, 5);
    expect((read(5)?.value, read(5)?.reps), (80, 10));
    expect(target(6), isNull);
    expect(target(7), isNull);
    // 목표는 세트 수를 따로 들지 않는다 — 세트 수는 공통 계획의 것이다.
    expect(read(0)?.sets, isNull);
  });

  test('첫 줄이 종목처럼 적혔으면 제목으로 먹지 않는다', () {
    final plan = parsePlanText('스쿼트 4세트\n벤치 3세트');
    expect(plan.title, '');
    expect(plan.items.map((i) => (i.name, i.sets)), [('스쿼트', 4), ('벤치', 3)]);
    // 글로 되돌려도 같은 계획이다.
    final again = parsePlanText(
      planText(plan.title, plan.items, (n) => '$n세트'),
      previous: plan.items,
    );
    expect(again.title, '');
    expect(again.items.map((i) => i.id), plan.items.map((i) => i.id));
    // 숫자로 시작하는 제목("5x5 스트렝스")이나 수가 없는 제목은 제목이다.
    expect(parsePlanText('5x5 스트렝스\n스쿼트 5x5').title, '5x5 스트렝스');
    expect(parsePlanText('민수식 로우 2\n스쿼트').title, '민수식 로우 2');
  });

  test('글 → 계획 → 글 → 계획이 같다 — 파서가 만든 계획은 다시 열어도 그대로다', () {
    // 첫 줄에 목표만 있는 줄('벤치 80kg')도 섞는다. 그 계획은 제목이 없고, 글로
    // 그리면 목표가 빠진 '벤치' 가 된다 — 그래도 제목으로 먹히면 안 된다.
    const pool = [
      '하체',
      '스트롱리프트 5x5',
      '5x5 스트렝스',
      '벤치 80kg',
      '로우 80 10',
      '유산소 30분',
      '벤치 100kg 도전',
      '스쿼트 5세트',
      '레그컬 x3',
      '민수식 로우 2',
      '민수식 로우 2 3세트',
      '벤치 3x10',
      '케틀벨 16kg 스윙 3세트',
      'EMOM 10분 버피',
      '스쿼트 20회 bpm 30 3세트',
      '타바타 버피 x6 2세트',
      '벤치 60세트',
      '스쿼트 80x10',
      '런지 x3 x4',
      '데드 3 x 5',
      'Hip thrust 5 sets',
      '3x10 벤치',
      '로우 80,10',
      '벤치 80kg 5 3세트',
      '플랭크 1분',
      '스쿼트 bpm 30 20',
      '벤치 80kg 5회 무릎 조심',
      '스쿼트 20회 30 bpm 3세트',
      '스쿼트 20회 30bpm 3세트',
      '타바타 버피 30초 / 15초 x8',
      '타바타 버피 20 x8',
      '타바타 30 80 kg x5',
    ];
    final random = Random(7);
    final texts = [
      for (final first in pool) '$first\n스쿼트 5세트',
      for (var n = 0; n < 300; n++)
        [
          for (var k = 0; k < 1 + random.nextInt(4); k++)
            pool[random.nextInt(pool.length)],
        ].join('\n'),
    ];
    for (final format in [(int n) => '$n세트', (int n) => '$n sets']) {
      for (final text in texts) {
        final c = parsePlanText(text);
        final shown = planText(c.title, c.items, format);
        for (final again in [
          parsePlanText(shown, previous: c.items, title: c.title),
          parsePlanText(shown, previous: c.items),
        ]) {
          expect(again.title, c.title, reason: '$text → $shown');
          expect(
            again.items.map((i) => (i.id, i.name, i.sets)),
            c.items.map((i) => (i.id, i.name, i.sets)),
            reason: '$text → $shown',
          );
        }
      }
    }
    // 제목 없는 계획은 빈 첫 줄로 그린다 — 첫 종목이 제목이 되지 않게.
    final untitled = parsePlanText('벤치 80kg\n스쿼트 5세트');
    expect(untitled.title, '');
    expect(
      planText(untitled.title, untitled.items, (n) => '$n세트'),
      '\n벤치\n스쿼트 5세트',
    );
  });

  test('저장된 계획에 제목이 있으면 수가 든 옛 제목("스트롱리프트 5x5")도 제목이다', () {
    const content = PlanContent(
      title: '스트롱리프트 5x5',
      items: [PlanItem(id: 'a', name: '스쿼트', sets: 5)],
    );
    final again = parsePlanText(
      planText(content.title, content.items, (n) => '$n세트'),
      previous: content.items,
      title: content.title,
    );
    expect(again.title, '스트롱리프트 5x5');
    expect(again.items.map((i) => (i.id, i.name, i.sets)), [('a', '스쿼트', 5)]);
    // 새로 친 첫 줄은 여전히 종목처럼 읽는다.
    expect(parsePlanText('스쿼트 4세트\n벤치', title: '하체').title, '');
  });

  test('저장된 제목 앞에 빈 줄을 넣어도 제목은 종목이 되지 않는다', () {
    const items = [PlanItem(id: 'a', name: '스쿼트', sets: 5)];
    for (final text in ['\n하체\n스쿼트 5세트', '  \n\n하체\n스쿼트 5세트']) {
      final again = parsePlanText(text, previous: items, title: '하체');
      expect(again.title, '하체', reason: text);
      expect(again.items.map((i) => (i.id, i.name, i.sets)), [('a', '스쿼트', 5)]);
    }
    // 저장된 제목이 없으면 빈 첫 줄은 여전히 '제목 없음' 이다.
    expect(parsePlanText('\n벤치\n스쿼트 5세트').title, '');
    // 제목 줄을 지웠으면 제목이 없다 — 힌트가 있어도.
    expect(parsePlanText('\n스쿼트 5세트', title: '하체').title, '');
  });

  test('타이머가 읽는 표기는 목표 뒤에 와도 이름에 남는다 — 30 bpm, 타바타 30초 / 15초·xN', () {
    const lines = [
      '스쿼트 20회 30 bpm 3세트',
      '스쿼트 20회 30bpm 3세트',
      '스쿼트 20회 bpm 30 3세트',
      '타바타 버피 30초 / 15초 x8',
      '타바타 버피 20 x8',
      '타바타 30 80 kg x5',
      '타바타 버피 8 라운드 2세트',
    ];
    final plan = parsePlanText(['하체', ...lines].join('\n'));
    expect(plan.items.map((i) => (i.name, i.sets, plan.targets[i.id])), [
      ('스쿼트 30 bpm', 3, '20회'),
      ('스쿼트 30bpm', 3, '20회'),
      ('스쿼트 bpm 30', 3, '20회'),
      ('타바타 버피 30초 / 15초 x8', 0, null),
      ('타바타 버피 20 x8', 0, null),
      ('타바타 30 x5', 0, '80kg'),
      ('타바타 버피 8 라운드', 2, null),
    ]);
    // 이름에서 붙는 타이머가 친 줄에서 읽은 것과 같다 — 30bpm 이 120 이 되거나
    // 30초/15초 가 기본 20/10 이 되지 않는다.
    for (final (i, line) in lines.indexed) {
      expect(
        TimingSpec.parse(plan.items[i].name),
        TimingSpec.parse(line),
        reason: line,
      );
    }
    // bpm 의 30 이 무게 30kg 으로 지어지지 않는다.
    expect(planTarget(plan.targets[plan.items[0].id]!, 'kg')?.value, isNull);
  });

  test('계획 줄은 수 표기만 목표로 옮기고, 글 낱말과 타이머 표기는 이름에 남긴다', () {
    final plan = parsePlanText('''
하체
케틀벨 16kg 스윙 3세트
EMOM 10분 버피
스쿼트 20회 bpm 30 3세트
타바타 버피 x6 2세트
벤치 80kg 5 3세트
민수식 로우 2 80kg
''');
    expect(plan.items.map((i) => (i.name, i.sets)), [
      ('케틀벨 스윙', 3),
      ('EMOM 버피', 0),
      ('스쿼트 bpm 30', 3),
      ('타바타 버피 x6', 2),
      ('벤치', 3),
      ('민수식 로우 2', 0),
    ]);
    expect(plan.items.map((i) => plan.targets[i.id]), [
      '16kg',
      '10분',
      '20회',
      null,
      '80kg 5',
      '80kg',
    ]);
    // bpm 은 이름에 남아 타이머가 붙는다 — 무게로 지어지지 않는다.
    expect(TimingSpec.parse(plan.items[2].name)?.bpm, 30);
    expect(TimingSpec.parse(plan.items[3].name)?.rounds, 6);
  });

  test('세트 수 없이 목표만 적은 줄도 시작한 운동에서 사라지지 않는다 — 목표로 한 세트', () {
    final plan = parsePlanText('하체\n벤치 80kg 5회\nEMOM 10분 버피\n로우 80 10\n풀업');
    final blocks = blocksFromPlan(PlanContent(items: plan.items), {
      for (final e in plan.targets.entries) e.key: planTarget(e.value, 'kg')!,
    });
    expect(blocks.map((b) => (b.name, b.sets.length)), [
      ('벤치', 1),
      ('EMOM 버피', 1),
      ('로우', 1),
      ('풀업', 0),
    ]);
    expect((blocks[0].sets.single.value, blocks[0].sets.single.reps), (80, 5));
    expect(
      (blocks[1].sets.single.value, blocks[1].sets.single.unit),
      (10, 'min'),
    );
    expect(blocks.expand((b) => b.sets).every((s) => !s.done), isTrue);
  });

  test('세트 수로 못 쓰는 표기는 버리지 않고 목표 글에 친 그대로 남는다', () {
    final plan = parsePlanText('하체\n벤치 60세트\n스쿼트 80x10\n런지 x3 x4');
    expect(plan.items.map((i) => (i.name, i.sets)), [
      ('벤치', 0),
      ('스쿼트', 0),
      ('런지', 3),
    ]);
    expect(plan.items.map((i) => plan.targets[i.id]), ['60세트', '80x10', 'x4']);
    expect(planTarget('60세트', 'kg')?.note, '60세트');
  });

  test('목표 한 줄은 세트 줄 파서로 읽고, 남는 것은 메모다', () {
    final t = planTarget('100kg 5회 x3 무릎 조심', 'lb')!;
    expect(
      (t.value, t.unit, t.reps, t.sets, t.note),
      (100, 'kg', 5, 3, '무릎 조심'),
    );
    // 여분 숫자는 메모로 남는다 — 예전에는 사라졌다.
    final extra = planTarget('100 5 5 5', 'kg')!;
    expect((extra.value, extra.reps, extra.note), (100, 5, '5 5'));
    expect(planTarget('80키로 5회', 'lb')?.unit, 'kg');
    expect(planTarget('무릎 조심', 'lb')?.note, '무릎 조심');
    expect(planTarget('   ', 'kg'), isNull);
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
