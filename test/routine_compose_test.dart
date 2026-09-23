import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/exercises.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart' show recordedExercises;
import 'package:setpad/routine.dart';
import 'package:setpad/workout_timing.dart';

import '../tool/routine_grading.dart';
import 'routine_fixture.dart';

/// 짜기(설계 §6–§8, §12.1 C1–C13 + 검토 G1–G20).
///
/// 코퍼스 루틴 요청의 금 라벨을 **모델 답인 것처럼** 넣고 짠 뒤 불변식을 모두 100%
/// 로 본다(막는 문턱). 모델이 실제로 낸 답은 tool/routine_eval_test.dart 가 같은
/// [routineViolations] 로 본다.
void main() {
  final today = routineToday;
  List<Map<String, Object?>> load(String name) =>
      (jsonDecode(File('tool/questions/$name.json').readAsStringSync()) as List)
          .cast<Map<String, Object?>>();

  RoutineDraft compose(
    Object? gold,
    String text, {
    List<Note>? notes,
    RoutineEdits? edits,
  }) {
    final log = notes ?? defaultLog();
    final ask = gold is RoutineAsk
        ? gold
        : decodeRoutineAsk(gold, text, recordedExercises(log), today: today);
    return composeRoutine(log, ask, now: today, edits: edits);
  }

  List<String> keys(RoutineDraft d) => [for (final i in d.items) i.key];
  List<String> codes(RoutineDraft d) => [for (final l in d.lines) l.code];

  group('C1–C13 — 코퍼스 금 라벨로 짠 결과', () {
    test('모든 문항에서 불변식이 100%', () {
      final rows = load('routine').where((r) => r['intent'] != 'question');
      final broken = <String>[];
      var drafts = 0, within48h = 0, partWithin48h = 0, rotations = 0;
      for (final r in rows) {
        final text = r['text'] as String;
        final notes = logFor(r['log'] as String?);
        final gold = (r['gold'] as List).first;
        final ask = decodeRoutineAsk(
          gold,
          text,
          recordedExercises(notes),
          today: today,
        );
        if (ask.question) continue;
        final draft = composeRoutine(notes, ask, now: today);
        drafts++;
        for (final v in routineViolations(draft, ask, notes, text)) {
          broken.add('${r['id']} $text: $v');
        }
        if (draft.source == 'rotation') {
          rotations++;
          final recent = recentKeys(notes, today);
          if (draft.items.any((i) => recent.keys.contains(i.key))) within48h++;
          if (draft.items.any((i) => recent.parts.contains(partOf(i.key)))) {
            partWithin48h++;
          }
        }
      }
      // ignore: avoid_print
      print(
        '짠 카드 $drafts · 불변식 깨짐 ${broken.length}\n'
        'C10(정보): 회전 $rotations 중 48시간 안에 한 운동이 든 것 $within48h · '
        '같은 부위가 든 것 $partWithin48h\n${broken.join('\n')}',
      );
      expect(broken, isEmpty);
    });
  });

  group('못 박는 결과', () {
    test('r-001 맨 요청 → 가장 오래 쉰 9/2 하체(같으면 최근), 어깨로 짜기 칩', () {
      final d = compose({}, '오늘 루틴 짜줘');
      expect(d.source, 'rotation');
      expect(d.sourceDay, DateTime(2026, 9, 2));
      expect(d.restDays, 7);
      expect(keys(d), ['스쿼트', '루마니안 데드리프트', '레그컬']);
      expect(d.partChip, 'shoulders');
      expect(d.partRest.keys.first, 'shoulders');
      expect(d.partRest['shoulders'], 9);
      // 트레이너가 남긴 안 한 세트(45×12)는 옮기지 않는다(C6).
      expect(d.items[2].sets, hasLength(3));
      expect(d.items[0].sets.first, (value: 60.0, unit: 'kg', reps: 8));
      expect(d.startable, isTrue);
      expect(d.paceSessions, greaterThanOrEqualTo(3));
      expect(d.pace, 160);
    });

    test('r-015 하체 위주 → 스쿼트·레그프레스·레그컬, 같은 날 하던 RDL 은 등이라 뺐다(넣기)', () {
      final d = compose({
        'parts': ['legs'],
      }, '하체 위주로 짜줘');
      expect(keys(d), ['스쿼트', '레그프레스', '레그컬']);
      expect(
        d.removed.where((r) => r.reason == 'otherPart').map((r) => r.key),
        contains('루마니안 데드리프트'),
      );
      // lb 로 적은 세트는 lb 그대로다.
      expect(d.items[1].sets.first.unit, 'lb');
    });

    test('r-034 10분 타바타 → 타바타 두 칸 = 8분 6초', () {
      final d = compose({
        'minutes': 10,
        'timer': {'kind': 'tabata'},
      }, '10분 타바타로 끝내자');
      expect(d.items, hasLength(2));
      expect(d.seconds, 486);
      expect(d.items.first.key, '버피');
      for (final i in d.items) {
        expect(TimingSpec.parse(i.title)?.tabata, isTrue, reason: i.title);
        expect(TimingSpec.parse(i.title)?.bpm, isNull, reason: i.title);
      }
    });

    test('r-055 스쿼트 말고 → 스쿼트 없음, 뺀 것에 보인다', () {
      final d = compose({
        'exclude': ['스쿼트'],
      }, '스쿼트 질렸어 스쿼트 말고');
      expect(keys(d), isNot(contains('스쿼트')));
      expect(d.removed.map((r) => r.key), contains('스쿼트'));
    });

    test('r-069 스쿼트 5x5 → 5회×5세트를 한 날이 없어 무게는 비우고 참고 줄(D3·G11)', () {
      final d = compose({
        'parts': ['legs'],
        'targets': [
          {'exercise': '스쿼트', 'sets': 5, 'reps': 5},
        ],
      }, '스쿼트 5x5로 하체');
      final squat = d.items.first;
      expect(squat.key, '스쿼트');
      expect(squat.sets, hasLength(5));
      expect(squat.sets.every((s) => s.value == null && s.reps == 5), isTrue);
      expect(squat.blank, 'repsUnmatched');
      expect(squat.reference, isNotNull);
    });

    test('L2: 그 무게로 5회를 5세트 한 날이 있으면 그 무게', () {
      final log = [
        ...defaultLog(),
        session('0820', 8, 20, [
          ExerciseBlock('스쿼트', times(5, () => kg(80, 5))),
        ]),
      ];
      final d = compose(
        {
          'targets': [
            {'exercise': '스쿼트', 'sets': 5, 'reps': 5},
          ],
        },
        '스쿼트 5x5',
        notes: log,
      );
      final squat = d.items.first;
      expect(squat.why, 'repsMatched');
      expect(squat.day, DateTime(2026, 8, 20));
      expect(squat.sets.every((s) => s.value == 80 && s.reps == 5), isTrue);
    });

    test('r-092 지난 화요일 → 9/8(가장 최근 지난 화요일, D4), 그 전 9/1 칩', () {
      final d = compose({
        'from': {
          'weekdays': [2],
        },
      }, '지난 화요일이랑 똑같이');
      expect(d.sourceDay, DateTime(2026, 9, 8));
      expect(d.previousDay, DateTime(2026, 9, 1));
      expect(keys(d), ['데드리프트', '랫풀다운', '시티드 로우']);
      // 같이 한 사람의 140×3 은 옮기지 않는다(C6).
      expect(d.items.first.sets.any((s) => s.value == 140), isFalse);
      final prev = compose(
        {
          'from': {
            'weekdays': [2],
          },
        },
        '지난 화요일이랑 똑같이',
        edits: RoutineEdits()..previous = true,
      );
      expect(prev.sourceDay, DateTime(2026, 9, 1));
    });

    test('r-100 쌤 루틴 다시 → 9/2(routineId)', () {
      expect(
        compose({
          'from': {'routine': true},
        }, '쌤이 짜준 루틴 다시 하고 싶어').sourceDay,
        DateTime(2026, 9, 2),
      );
    });

    test('r-103 저번 하체 +5kg → 9/2 에 +5', () {
      final d = compose({
        'from': {'part': 'legs'},
        'delta': {'value': 5, 'unit': 'kg'},
      }, '저번 하체 +5kg');
      expect(d.sourceDay, DateTime(2026, 9, 2));
      expect(d.items.first.sets.map((s) => s.value), [65, 97.5, 97.5, 97.5]);
    });

    test('r-124 기록 0 → 처음, 고를 칩(숫자 없음, D1)', () {
      final d = compose({}, '헬스 처음인데 뭐 해야 돼', notes: const []);
      expect(d.items, isEmpty);
      expect(d.addable, starterExercises);
      expect(codes(d), contains('firstTime'));
    });

    test('r-137 데드 빼고 지난주 당기기 날처럼 → 9/4, 데드는 원래 없다고 말한다', () {
      final d = compose({
        'from': {'period': 'lastWeek', 'pattern': 'pull'},
        'exclude': ['데드리프트'],
        'pain': true,
      }, '허리 아파서 데드 빼고 지난주 당기기 날처럼');
      expect(d.sourceDay, DateTime(2026, 9, 4));
      expect(codes(d), contains('excludeAbsent'));
      expect(codes(d), contains('pain'));
    });

    test('r-149 디스크 재활 → 카드 없음, 거절 줄', () {
      final d = compose({
        'refused': {'medical': '디스크 재활'},
      }, '허리 디스크 재활 루틴 짜줘');
      expect(d.held, isTrue);
      expect(d.items, isEmpty);
      expect(d.startable, isFalse);
      expect(d.lines.first.code, 'refused');
    });

    test('r-157 다 한 걸로 기록 → logging 줄 + 루틴', () {
      final d = compose({
        'refused': {'logging': '다 한 걸로 기록'},
      }, '오늘 루틴 짜고 다 한 걸로 기록해줘');
      expect(d.lines.first.args.first, 'logging');
      expect(d.items, isNotEmpty);
    });
  });

  group('검토 gap', () {
    test('G2: 남의 루틴 — 이름만, 시작 없음', () {
      final d = compose({
        'refused': {'person': '친구 루틴'},
        'exercises': ['벤치프레스'],
      }, '친구 루틴 짜줘 벤치 하게');
      expect(d.startable, isFalse);
      expect(d.items.every((i) => i.sets.isEmpty), isTrue);
    });

    test('G3: 의료 + 부위 → 카드 없음', () {
      final d = compose({
        'refused': {'medical': '무릎 수술'},
        'parts': ['legs'],
      }, '무릎 수술 2주 됐는데 하체 짜줘');
      expect(d.items, isEmpty);
      expect(d.startable, isFalse);
    });

    test('G4: 숫자를 바꾼 칸은 설정·제목도 같이 — 가볍게면 설정 무게가 비고 제목에 옛 무게가 없다', () {
      final log = [
        session('0907s', 9, 7, [
          ExerciseBlock(
            '스쿼트 100kg 5x5',
            times(5, () => kg(100, 5)),
            const WorkoutSetup(
              name: '스쿼트',
              weight: 100,
              totalSets: 5,
              repsPerSet: 5,
            ),
          ),
        ]),
      ];
      final light = compose(
        {'intensity': 'light'},
        '가볍게 하고 싶어',
        notes: log,
      ).items.single;
      expect(light.setup?.weight, isNull);
      expect(light.title.contains('100'), isFalse, reason: light.title);
      expect(light.sets.every((s) => s.value == null && s.reps == 5), isTrue);
      final plus = compose(
        {
          'from': {},
          'delta': {'value': 5, 'unit': 'kg'},
        },
        '지난번 +5kg',
        notes: log,
      ).items.single;
      expect(plus.setup?.weight, 105);
      expect(plus.sets.every((s) => s.value == 105), isTrue);
      expect(plus.title.contains('100'), isFalse);
      // 안 바꾼 칸은 제목·설정 그대로다.
      final same = compose({'from': {}}, '지난번 그대로', notes: log).items.single;
      expect(same.title, '스쿼트 100kg 5x5');
      expect(same.setup?.weight, 100);
    });

    test('G6: from 뒤에도 기구·뺄 것 거름, 지목한 운동은 앞에; ○ 뿐인 기록·오늘 기록은 원천이 아니다', () {
      final log = [
        ...defaultLog(),
        // 시작만 하고 안 한 기록(오늘), ○ 뿐.
        Note(
          id: 'started',
          createdAt: DateTime(2026, 9, 9, 7),
          updatedAt: DateTime(2026, 9, 9, 7),
          blocks: [
            ExerciseBlock('벤치프레스', [kg(90, 5, done: false)]),
          ],
        ),
      ];
      final d = compose(
        {
          'from': {},
          'exercises': ['플랭크'],
        },
        '지난번 그대로 + 플랭크 추가',
        notes: log,
      );
      expect(d.sourceDay, DateTime(2026, 9, 8));
      expect(keys(d).first, '플랭크');
      expect(keys(d), containsAll(['데드리프트', '랫풀다운', '시티드 로우']));
      final g = compose({
        'from': {'period': 'yesterday'},
        'equipment': {
          'only': ['dumbbell'],
        },
      }, '어제 거 다시 근데 덤벨만');
      expect(g.items, isEmpty);
      expect(g.removed.map((r) => r.reason).toSet(), {'gear'});
      expect(g.addable, isNotEmpty);
    });

    test('G7: 모델이 고른 운동은 기구 거름을 지나야 한다 — 사람이 말한 것만 무게를 비우고 넣는다', () {
      final picked = compose({
        'exercises': ['벤치프레스', '스쿼트'],
        'equipment': {
          'only': ['dumbbell'],
        },
      }, '덤벨만 있어');
      expect(keys(picked), isNot(contains('벤치프레스')));
      expect(keys(picked), isNot(contains('스쿼트')));
      expect(picked.removed.map((r) => r.key), containsAll(['벤치프레스', '스쿼트']));
      final named = compose({
        'exercises': ['벤치프레스'],
        'equipment': {
          'only': ['dumbbell'],
        },
      }, '벤치 하고 싶은데 덤벨만 있어');
      final bench = named.items.firstWhere((i) => i.key == '벤치프레스');
      expect(bench.blank, 'gear');
      expect(bench.sets.every((s) => s.value == null), isTrue);
    });

    test('G8: 맨몸만이면 기구 무게는 비운다, 딥스는 철봉, 벤치 없이는 벤치 운동을 뺀다', () {
      final log = [
        session('l1', 9, 6, [
          ExerciseBlock('런지', times(3, () => kg(20, 10))),
          ExerciseBlock('딥스', times(3, () => reps(10))),
          ExerciseBlock('푸시업', times(3, () => reps(20))),
        ]),
        ...defaultLog(),
      ];
      final bw = compose(
        {
          'equipment': {
            'only': ['bodyweight'],
          },
        },
        '맨몸으로',
        notes: log,
      );
      final lunge = bw.items.firstWhere((i) => i.key == '런지');
      expect(lunge.blank, 'bodyweight');
      expect(lunge.sets.every((s) => s.value == null && s.reps == 10), isTrue);
      expect(keys(bw), isNot(contains('딥스')));
      expect(gearOf('딥스'), 'bar');
      final noBench = compose(
        {
          'parts': ['chest'],
          'equipment': {
            'without': ['bench'],
          },
        },
        '벤치 없이 가슴',
        notes: log,
      );
      expect(keys(noBench), isNot(contains('벤치프레스')));
      expect(keys(noBench), isNot(contains('덤벨 프레스')));
    });

    test('G9: 부위는 열쇠로(OHP 도 어깨), 부위 모르는 운동은 avoid 에서 뺀다, 뺄 이름은 조각으로도', () {
      final log = [
        session('g9', 9, 6, [
          ExerciseBlock('OHP', times(3, () => kg(40, 8))),
          ExerciseBlock('민수식 로우', times(3, () => kg(30, 10))),
          ExerciseBlock('고블릿 스쿼트', times(3, () => kg(20, 10))),
          ExerciseBlock('핵스쿼트', times(3, () => kg(80, 10))),
        ]),
      ];
      final avoid = compose(
        {
          'avoid': ['shoulders'],
          'pain': '어깨 아파서',
        },
        '어깨 아파서 어깨 빼고',
        notes: log,
      );
      expect(keys(avoid), isNot(contains('오버헤드프레스')));
      expect(keys(avoid), isNot(contains('민수식 로우')));
      expect({
        for (final r in avoid.removed) r.key: r.reason,
      }, containsPair('민수식 로우', 'unknownPart'));
      final squat = compose(
        {
          'exclude': ['스쿼트'],
        },
        '스쿼트 빼고',
        notes: log,
      );
      expect(keys(squat), isNot(contains('고블릿 스쿼트')));
      expect(keys(squat), isNot(contains('핵스쿼트')));
      final row = compose(
        {
          'exclude': ['로우'],
        },
        '로우 빼고',
        notes: log,
      );
      expect(keys(row), isNot(contains('민수식 로우')));
    });

    test('G10: 아픈 곳 — 무게는 비우고 참고 줄, 뺀 것을 사실대로', () {
      final d = compose({'pain': '허리 조심'}, '허리 조심해야 돼');
      expect(
        d.items.every(
          (i) => i.sets.every(
            (s) => s.value == null || !['kg', 'lb'].contains(s.unit),
          ),
        ),
        isTrue,
      );
      expect(d.items.every((i) => i.reference != null), isTrue);
      final line = d.lines.firstWhere((l) => l.code == 'pain');
      expect(line.args.first, '허리 조심');
    });

    test('G11: 원천이 28일보다 오래됐으면 무게를 비운다; 28일 안에 없으면 가장 최근 운동', () {
      final old = [
        session('old', 7, 1, [
          ExerciseBlock('벤치프레스', times(3, () => kg(80, 5))),
          ExerciseBlock('바벨로우', times(3, () => kg(60, 8))),
        ]),
      ];
      final d = compose({}, '오늘 루틴 짜줘', notes: old);
      expect(keys(d), ['벤치프레스', '바벨로우']);
      expect(d.items.every((i) => i.blank == 'stale'), isTrue);
      expect(
        d.items.every((i) => i.sets.every((s) => s.value == null)),
        isTrue,
      );
    });

    test('G12: 스스로 올려 온 폭 — 새 최고의 증가분만, 상한 5%·5kg', () {
      DateTime at(int d) => DateTime(2026, 8, d);
      List<Note> series(List<double> tops) => [
        for (final (i, w) in tops.indexed)
          session('s$i', at(1 + i * 3).month, at(1 + i * 3).day, [
            ExerciseBlock('벤치프레스', [kg(w, 5)]),
          ]),
      ];
      // 강약을 번갈아: 100·80·102.5·82.5·105 → +2.5(두 번), +22.5 아님.
      expect(
        ownStep(series([100, 80, 102.5, 82.5, 105]), '벤치프레스', today)?.step,
        2.5,
      );
      // 워밍업만 적은 날이 끼어도(60·100·60·100) +40 이 되지 않는다.
      expect(ownStep(series([60, 100, 60, 100]), '벤치프레스', today), isNull);
      // 상한: 최고 50kg 의 5% = 2.5.
      expect(ownStep(series([40, 45, 50]), '벤치프레스', today)?.step, 2.5);
      final hard = compose(
        {'intensity': 'hard'},
        '빡세게',
        notes: series([100, 80, 102.5, 82.5, 105]),
      );
      expect(hard.stepChip?.text, '2.5kg');
      final applied = compose(
        {'intensity': 'hard'},
        '빡세게',
        notes: series([100, 80, 102.5, 82.5, 105]),
        edits: RoutineEdits()..step = true,
      );
      expect(applied.items.single.sets.single.value, 107.5);
      expect(applied.items.single.stepped?.evidence, isNotEmpty);
    });

    test('G13: 최근 48시간 메모 줄과 같은 부위 표시', () {
      final d = compose({}, '오늘 루틴 짜줘');
      final memo = d.lines.firstWhere((l) => l.code == 'recentMemo');
      expect(memo.args, [1, '데드리프트', '허리 뻐근']);
      final rdl = d.items.firstWhere((i) => i.key == '루마니안 데드리프트');
      expect(rdl.recent, (part: 'back', days: 1));
    });

    test('G14: 내일 루틴은 미리보기 — 시작 없음, 쉰 날은 내일 기준', () {
      final d = compose(
        deviceAsk('내일 루틴 짜줘', recordedExercises(defaultLog()), bare: true),
        '내일 루틴 짜줘',
      );
      expect(d.future, isTrue);
      expect(d.startable, isFalse);
      expect(d.day, DateTime(2026, 9, 10));
      expect(d.restDays, 8);
    });

    test('G17: 기록 0 + 덤벨만 → 막다른 길 대신 덤벨·맨몸 칩', () {
      final d = compose(
        {
          'equipment': {
            'only': ['dumbbell'],
          },
        },
        '덤벨만 있어',
        notes: const [],
      );
      expect(d.items, isEmpty);
      expect(d.addable, isNotEmpty);
      for (final k in d.addable) {
        expect(['dumbbell', 'bodyweight'], contains(gearOf(k)), reason: k);
      }
      final picked = compose(
        {
          'equipment': {
            'only': ['dumbbell'],
          },
        },
        '덤벨만 있어',
        notes: const [],
        edits: RoutineEdits()..added.add(d.addable.first),
      );
      expect(picked.items.single.why, 'first');
      expect(picked.items.single.sets, isEmpty);
    });

    test('G18: ✕ 는 다시 짜도 남고, 시작 칸은 누를 때마다 새 id', () {
      final edits = RoutineEdits()..removed.add('2026-09-02|레그컬');
      final d = compose({}, '오늘 루틴 짜줘', edits: edits);
      expect(keys(d), isNot(contains('레그컬')));
      expect(d.removed.first.reason, 'user');
      final again = compose({}, '오늘 루틴 짜줘', edits: edits);
      expect(keys(again), isNot(contains('레그컬')));
      final a = startBlocks(d), b = startBlocks(d);
      expect(a.first.id, isNot(b.first.id));
      expect(identical(a.first.sets.first, b.first.sets.first), isFalse);
      expect(
        a.expand((x) => x.sets).every((s) => !s.done && s.notes.isEmpty),
        isTrue,
      );
    });

    test('G19: 친 타바타는 수를 뺀 이름에 — AxB 가 라운드가 되지 않는다', () {
      final log = [
        session('t', 9, 6, [
          ExerciseBlock('스쿼트 100kg 5x5', times(5, () => kg(100, 5))),
          ExerciseBlock('푸시업 3x20', times(3, () => reps(20))),
        ]),
      ];
      final d = compose(
        {
          'exercises': ['스쿼트', '푸시업'],
          'timer': {'kind': 'tabata'},
        },
        '스쿼트랑 푸시업 타바타로',
        notes: log,
      );
      for (final i in d.items) {
        final spec = TimingSpec.parse(i.title)!;
        expect(spec.tabata, isTrue, reason: i.title);
        expect(spec.rounds, 8, reason: i.title);
        expect(
          i.title.contains('5x5') || i.title.contains('3x20'),
          isFalse,
          reason: i.title,
        );
      }
    });

    test('bpm 범위 밖은 붙이지 않고 줄', () {
      final d = compose({
        'exercises': ['스쿼트'],
        'timer': {'kind': 'bpm', 'bpm': 150},
      }, 'bpm 150 스쿼트 루틴');
      expect(TimingSpec.parse(d.items.first.title), isNull);
      expect(codes(d), contains('bpmRange'));
    });

    test('시간: N분에 ±20% 로 맞추고, 못 맞추면 까닭 줄(C9)', () {
      final d = compose({'minutes': 20}, '20분밖에 없어');
      expect((d.seconds - 1200).abs(), lessThanOrEqualTo(240));
      final count = compose({'minutes': 20, 'count': 4}, '20분, 운동 4개');
      expect(count.items, hasLength(4));
      expect(codes(count), contains('countFit'));
    });

    test('검토#7 "(부위)로 짜기" 칩은 부위만 바꾼다 — 시간·개수·증감·거절은 그대로', () {
      for (final (raw, text, key) in [
        ({'minutes': 30}, '30분 루틴 짜줘', 'minutes'),
        ({'count': 2}, '운동 2개만 짜줘', 'count'),
        (
          {
            'delta': {'value': 5, 'unit': 'kg'},
          },
          '오늘은 5kg씩 더 올려서 짜줘',
          'delta',
        ),
      ]) {
        final before = compose(raw, text);
        expect(before.partChip, isNotNull, reason: text);
        final after = compose(
          raw,
          text,
          edits: RoutineEdits()..part = before.partChip,
        );
        expect(after.applied, containsAll({key, 'parts'}), reason: text);
        expect(after.unmet, isEmpty, reason: text);
      }
      final plus = compose(
        {
          'delta': {'value': 5, 'unit': 'kg'},
        },
        '오늘은 5kg씩 더 올려서 짜줘',
        edits: RoutineEdits()..part = 'shoulders',
      );
      final ohp = plus.items.firstWhere((i) => i.key == '오버헤드프레스');
      expect(ohp.sets.first.value, 45);
      const person = {
        'refused': {'person': '동생 운동'},
      };
      final held = compose(person, '동생 운동 좀 짜줘');
      final chip = compose(
        person,
        '동생 운동 좀 짜줘',
        edits: RoutineEdits()..part = held.partChip ?? 'shoulders',
      );
      expect(held.startable, isFalse);
      expect(chip.held, isTrue);
      expect(chip.startable, isFalse);
    });

    test('검토#9 무게만 친 칸은 한 세트·횟수 비움, 지난 기록은 참고 줄', () {
      final d = compose({
        'exercises': ['벤치프레스'],
        'targets': [
          {'exercise': '벤치프레스', 'weight': 100, 'unit': 'kg'},
        ],
        'intensity': 'max',
      }, '벤치 100kg 한번 쳐보게 짜줘');
      final bench = d.items.firstWhere((i) => i.key == '벤치프레스');
      expect(bench.sets, [(value: 100.0, unit: 'kg', reps: null)]);
      expect(bench.why, 'typed');
      expect(bench.reference, isNotNull);
      final e = compose({
        'targets': [
          {'exercise': '스쿼트', 'weight': 120, 'unit': 'kg', 'sets': 3},
        ],
      }, '스쿼트 120kg 3세트');
      final squat = e.items.firstWhere((i) => i.key == '스쿼트');
      expect(
        squat.sets,
        List.filled(3, (value: 120.0, unit: 'kg', reps: null)),
      );
      expect(squat.reference?.sets, isNotEmpty);
      // 수가 모두 글에 없어 빠졌으면 친 칸이 아니다 — 지난 세트를 그대로 옮긴다.
      final none = compose({
        'targets': [
          {'exercise': '스쿼트', 'weight': 120, 'unit': 'kg'},
        ],
      }, '스쿼트 120 도전');
      final copied = none.items.firstWhere((i) => i.key == '스쿼트');
      expect(copied.why, 'copied');
      expect(copied.sets.first, (value: 60.0, unit: 'kg', reps: 8));
    });

    test('검토#1 기기가 읽은 의료 글은 어느 길로 와도 시작할 카드가 없다(G3)', () {
      final d = compose(
        deviceAsk('재활 중인데 오늘 뭐 할까', recordedExercises(defaultLog())),
        '재활 중인데 오늘 뭐 할까',
      );
      expect(d.startable, isFalse);
      expect(d.items, isEmpty);
    });

    test('검토#11 오늘과 같은 요일은 오늘이다(다음 주 미리 보기가 아니다)', () {
      // routineToday 는 수요일이다.
      final d = compose(
        RoutineAsk(when: readWhen('수요일 루틴 짜줘'), device: true),
        '수요일 루틴 짜줘',
      );
      expect(d.day, DateTime(2026, 9, 9));
      expect(d.startable, isTrue);
    });

    test('검토#12 초안의 표지는 카드가 바뀌면 바뀐다', () {
      final a = compose({}, '오늘 루틴 짜줘');
      final b = compose({}, '오늘 루틴 짜줘');
      final c = compose({}, '오늘 루틴 짜줘', edits: RoutineEdits()..alt = 1);
      expect(draftMark(a), draftMark(b));
      expect(draftMark(a), isNot(draftMark(c)));
    });

    test('기본값 속도: 쓸 만한 운동이 셋 안 되면 세트당 150초라고 적는다(D2)', () {
      final d = compose({}, '오늘 루틴 짜줘', notes: fewLog());
      expect(d.paceSessions, 0);
      expect(d.pace, defaultPace);
    });
  });

  test('기구 표: 사전의 모든 운동에 기구가 있다(58)', () {
    for (final e in exercises) {
      expect(exerciseGear[e.ko], isNotNull, reason: e.ko);
    }
    expect(exerciseGear.length, exercises.length);
    for (final k in exercisePattern.keys) {
      expect(exerciseByName[k.toLowerCase()], isNotNull, reason: k);
    }
  });
}
