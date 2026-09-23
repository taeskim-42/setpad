import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/agent_alarm.dart';

void main() {
  // 2026-09-23(수) 07:05 한국 = 전날 22:05 UTC.
  final wedMorning = DateTime.utc(2026, 9, 22, 22, 5);

  String seoul(DateTime at) {
    final k = at.toUtc().add(const Duration(hours: 9));
    return '${k.month}/${k.day} ${k.hour}:${k.minute.toString().padLeft(2, '0')}';
  }

  test('한국 시각 +2분, 지나간 오늘은 다음 주로', () {
    // 수(3) 07:02 는 방금 지났다 → 다음 주 수요일. 목(4) → 내일.
    final slots = agentAlarmSlots('gym-a', [420], [3, 4], wedMorning);
    expect(slots.map((s) => seoul(s.at)), ['9/30 7:02', '9/24 7:02']);
  });

  test('기기 시간대와 상관없이 한국 시각 — 오늘 아직 안 온 시각은 오늘', () {
    final slots = agentAlarmSlots('gym-a', [480], [3], wedMorning);
    expect(seoul(slots.single.at), '9/23 8:02');
    expect(slots.single.at.location.name, 'Asia/Seoul');
  });

  test('23:59 +2분은 다음 날 00:01 — 토요일이면 일요일, 월말도 넘긴다', () {
    // 2026-09-30(수) 12:00 한국.
    final slots = agentAlarmSlots(
      'gym-a',
      [1439],
      [6],
      DateTime.utc(2026, 9, 30, 3),
    );
    expect(seoul(slots.single.at), '10/4 0:01');
    expect(slots.single.at.weekday, DateTime.sunday);
  });

  test('id 는 설정에서만 나온다 — 같으면 같고, 도장·시각이 다르면 다르다', () {
    List<int> ids(String gym, List<int> m) => agentAlarmSlots(gym, m, [
      0,
      1,
      2,
      3,
      4,
      5,
      6,
    ], wedMorning).map((s) => s.id).toList();
    final a = ids('gym-a', [420, 1260, 0, 1439]);
    expect(a, ids('gym-a', [420, 1260, 0, 1439]));
    expect(a.toSet().length, 28);
    expect(a.every((id) => id >= 0 && id < 1 << 31), isTrue);
    expect(
      a.toSet().intersection(ids('gym-b', [420, 1260, 0, 1439]).toSet()),
      isEmpty,
    );
  });

  test('중복 값은 한 번만, 끔·빈 요일이면 없다', () {
    expect(agentAlarmSlots('g', [420, 420], [1, 1], wedMorning), hasLength(1));
    expect(agentAlarmSlots('g', [420], [], wedMorning), isEmpty);
  });

  test('init 전(웹·테스트)에는 아무것도 안 하고 권한은 false', () async {
    expect(await AgentAlarm.ensurePermission(), isFalse);
    await AgentAlarm.sync(
      gymId: 'g',
      gymName: '도장',
      enabled: true,
      runMinutes: [420],
      weekdays: [1],
    );
    await AgentAlarm.clearAll();
  });
}
