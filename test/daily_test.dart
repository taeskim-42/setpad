// 하루 집계와 기간 요약 — 없는 것을 0 으로 세지 않는가, 부호가 맞는가.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/daily.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/notes.dart';

var _n = 0;
Note workout(
  DateTime at, {
  double? kcal,
  Duration length = const Duration(hours: 1),
}) => Note(
  id: 'n${_n++}',
  createdAt: at,
  updatedAt: at.add(length),
  blocks: [
    ExerciseBlock('벤치프레스', [LoggedSet(value: 80, reps: 10)]),
  ],
)..calories = kcal;

MealEntry meal(DateTime at, int? kcal, {String? source, String? id}) =>
    MealEntry(at: at, kcal: kcal, text: '끼니', source: source, id: id);

void main() {
  final day = DateTime(2026, 9, 21);

  test('섭취 2,100 − 운동 450 = 1,650 이고 부호가 뒤집히지 않는다', () {
    final note = workout(day.add(const Duration(hours: 18)), kcal: 450)
      ..meals.addAll([
        meal(day.add(const Duration(hours: 8)), 600, source: MealEntry.typed),
        meal(day.add(const Duration(hours: 13)), 1500, source: MealEntry.typed),
      ]);
    final log = dayLogs([note], [], from: day, to: day).single;
    expect(log.intake, 2100);
    expect(log.burned, 450);
    expect(log.difference, 1650);
    expect(log.intakeEstimated, isFalse);
  });

  test('같은 날 문서가 여럿이면 합치고, 같은 끼니는 한 번만 센다', () {
    final shared = meal(day.add(const Duration(hours: 12)), 700, id: 'same');
    final morning = workout(day.add(const Duration(hours: 7)), kcal: 200)
      ..meals.add(shared);
    final evening = workout(day.add(const Duration(hours: 19)), kcal: 250)
      ..meals.addAll([shared, meal(day.add(const Duration(hours: 20)), 800)]);
    final log = dayLogs([morning, evening], [], from: day, to: day).single;
    expect(log.burned, 450);
    expect(log.intake, 1500, reason: '두 문서에 걸린 끼니를 두 번 더하지 않는다');
    expect(log.notes, hasLength(2));
  });

  test('겹치는 시간대의 활동 에너지를 두 번 재지 않고, 나중에 고친 시각까지 늘리지 않는다', () {
    final first = workout(
      day.add(const Duration(hours: 18)),
      kcal: 300,
      length: const Duration(hours: 1),
    );
    final second = workout(
      day.add(const Duration(hours: 18, minutes: 30)),
      length: const Duration(hours: 1),
    );
    expect(
      sessionStart(second, [first, second]),
      day.add(const Duration(hours: 19)),
      reason: '먼저 잰 문서가 끝난 뒤부터만 잰다',
    );
    expect(sessionStart(first, [first, second]), first.createdAt);
    // 아침에 만든 문서를 밤에 고쳤다 — 그사이 하루치가 운동 칼로리가 되면 안 된다.
    final edited = workout(
      day.add(const Duration(hours: 7)),
      length: const Duration(hours: 15),
    );
    expect(sessionEnd(edited), edited.createdAt.add(maxSession));
  });

  test('미기록·미측정·열량 미상은 0 이 아니다', () {
    final noMeals = workout(day.add(const Duration(hours: 18)), kcal: 400);
    final log = dayLogs([noMeals], [], from: day, to: day).single;
    expect(log.intake, isNull, reason: '안 적은 것은 0kcal 섭취가 아니다');
    expect(log.difference, isNull);

    final unmeasured = workout(day.add(const Duration(hours: 18)))
      ..meals.add(meal(day.add(const Duration(hours: 12)), 900));
    final second = dayLogs([unmeasured], [], from: day, to: day).single;
    expect(second.burned, isNull, reason: '안 잰 것은 0kcal 소모가 아니다');
    expect(second.difference, isNull);

    final unknown = workout(day.add(const Duration(hours: 18)), kcal: 400)
      ..meals.addAll([
        meal(day.add(const Duration(hours: 12)), 1400),
        meal(day.add(const Duration(hours: 19)), null),
      ]);
    final third = dayLogs([unknown], [], from: day, to: day).single;
    expect(third.intake, 1400);
    expect(third.unknownMeals, 1);
    expect(third.difference, isNull, reason: '열량 미상이 섞이면 차이를 내지 않는다');
    expect(third.intakeEstimated, isTrue, reason: '출처 없는 값은 어림이다');
  });

  test('평균은 제 날짜 집합과 분모로 내고, 빈 날을 0 으로 채우지 않는다', () {
    DateTime d(int n, [int hour = 12]) => DateTime(2026, 9, n, hour);
    final notes = [
      // 1일: 둘 다 있음 (2000, 500 → 1500)
      workout(d(1, 18), kcal: 500)..meals.add(meal(d(1), 2000)),
      // 2일: 섭취만 (3000)
      Note(id: 'm2', createdAt: d(2), updatedAt: d(2))
        ..meals.add(meal(d(2), 3000)),
      // 3일: 운동만 (300)
      workout(d(3, 18), kcal: 300),
      // 4일: 열량 미상이 섞인 날 — 평균에서 빠진다
      workout(d(4, 18), kcal: 100)
        ..meals.addAll([meal(d(4), 1000), meal(d(4, 13), null)]),
    ];
    final days = dayLogs(notes, [], from: d(1), to: d(30));
    expect(days, hasLength(4), reason: '기록 없는 26일은 만들어지지 않는다');
    final s = summarize(days);
    expect([s.intakeDays, s.intakeAverage], [2, 2500]);
    expect([s.burnedDays, s.burnedAverage], [3, 300]);
    expect([s.differenceDays, s.differenceAverage], [1, 1500]);
    expect(
      s.differenceAverage,
      isNot(s.intakeAverage! - s.burnedAverage!),
      reason: '서로 다른 날들의 평균을 빼지 않는다',
    );
    expect(s.incompleteDays, 1);
  });

  test('자정 경계: 끼니는 먹은 날에, 체중은 잰 날에 들어간다', () {
    final late = DateTime(2026, 9, 21, 23, 59),
        early = DateTime(2026, 9, 22, 0, 1);
    // 21일 문서에 자정 넘어 적은 끼니가 붙어 있다.
    final note = workout(DateTime(2026, 9, 21, 22), kcal: 300)
      ..meals.addAll([meal(late, 500), meal(early, 700)]);
    final weights = [
      WeightEntry(at: late, value: 72.4),
      WeightEntry(at: early, value: 72.1),
    ];
    final days = dayLogs([note], weights, from: late, to: early);
    expect(days.map((d) => d.day.day), [21, 22]);
    expect(days.first.intake, 500);
    expect(days.last.intake, 700);
    expect(days.last.burned, isNull, reason: '운동은 문서를 만든 날의 것이다');
    expect(days.first.weight!.value, 72.4);
    expect(days.last.weight!.value, 72.1);
  });

  test('체중: 안 잰 날에 값을 만들지 않고, 하루 여러 번 재면 원본을 두고 첫 값을 대표로 쓴다', () {
    final weights = [
      WeightEntry(at: DateTime(2026, 9, 1, 7), value: 73.0),
      WeightEntry(at: DateTime(2026, 9, 1, 21), value: 73.9),
      WeightEntry(at: DateTime(2026, 9, 21, 7), value: 72.4),
    ];
    final days = dayLogs(
      [],
      weights,
      from: DateTime(2026, 9, 1),
      to: DateTime(2026, 9, 30),
    );
    expect(days.map((d) => d.day.day), [1, 21], reason: '사이 날짜를 지어내지 않는다');
    expect(days.first.weights, hasLength(2), reason: '원본은 둘 다 남는다');
    expect(days.first.weight!.value, 73.0);
    final s = summarize(days);
    expect(s.weightChangeKg, closeTo(-0.6, 1e-9));
    expect(
      summarize([days.first]).weightChangeKg,
      isNull,
      reason: '하루치로는 변화를 말하지 않는다',
    );
  });

  test('kg·lb 변환이 맞고, 친 값은 바뀌지 않는다', () {
    final lb = WeightEntry(at: day, value: 160, unit: 'lb');
    expect(lb.kg, closeTo(72.5748, 1e-4));
    expect(lb.inUnit('lb'), closeTo(160, 1e-9));
    expect(formatWeight(lb, 'kg'), '72.6kg');
    expect(formatWeight(lb, 'lb'), '160lb');
    expect(formatWeight(WeightEntry(at: day, value: 72.4), 'lb'), '159.6lb');
    expect(WeightEntry.valid(5, 'kg'), isFalse);
    expect(WeightEntry.valid(-70, 'kg'), isFalse);
    final back = WeightEntry.tryFromJson(jsonDecode(jsonEncode(lb.toJson())))!;
    expect([back.value, back.unit, back.id], [160, 'lb', lb.id]);
  });

  test('체중을 고치고 지우면 집계에 그대로 반영되고, 건강 앱의 같은 측정은 한 번만 들어온다', () async {
    final dir = Directory.systemTemp.createTempSync('setpad_body_');
    final store = NotesStore(directory: dir);
    addTearDown(() {
      store.dispose();
      dir.deleteSync(recursive: true);
    });
    final first = WeightEntry(at: DateTime(2026, 9, 1, 7), value: 73.0);
    store
      ..saveWeight(first)
      ..saveWeight(WeightEntry(at: DateTime(2026, 9, 21, 7), value: 72.4));
    double? change() => summarize(
      dayLogs(
        store.notes,
        store.weights,
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      ),
    ).weightChangeKg;
    expect(change(), closeTo(-0.6, 1e-9));
    // 잘못 친 값을 고친다 — 같은 id 라 하나로 남는다.
    store.saveWeight(WeightEntry(id: first.id, at: first.at, value: 73.4));
    expect(store.weights, hasLength(2));
    expect(change(), closeTo(-1.0, 1e-9));

    final fromHealth = WeightEntry(
      id: 'hABC',
      at: DateTime(2026, 9, 10, 7),
      value: 72.9,
      source: WeightEntry.health,
    );
    store
      ..importWeights([fromHealth])
      ..importWeights([fromHealth]);
    expect(store.weights.where((w) => w.id == 'hABC'), hasLength(1));
    store.deleteWeight(store.weights.firstWhere((w) => w.id == 'hABC'));
    store.importWeights([fromHealth]);
    expect(
      store.weights.where((w) => w.id == 'hABC'),
      isEmpty,
      reason: '지운 측정이 되살아나지 않는다',
    );

    await store.flush();
    final reopened = NotesStore(directory: dir);
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(reopened.weights.map((w) => w.value), [73.4, 72.4]);
    reopened.importWeights([fromHealth]);
    expect(reopened.weights, hasLength(2), reason: '지웠다는 기억도 저장된다');
  });

  test('끼니를 고치거나 지우면 다음 집계가 바로 달라진다', () {
    final note = workout(day.add(const Duration(hours: 18)), kcal: 450)
      ..gymId = null
      ..meals.add(meal(day.add(const Duration(hours: 12)), 2100, id: 'lunch'));
    int? diff() => dayLogs([note], [], from: day, to: day).single.difference;
    expect(diff(), 1650);
    note.meals[0] = meal(day.add(const Duration(hours: 12)), 1800, id: 'lunch');
    expect(diff(), 1350);
    note.removeMeal(note.meals.single);
    expect(diff(), isNull, reason: '끼니가 없으면 0 이 아니라 기록 없음이다');
  });
}
