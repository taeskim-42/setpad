#!/usr/bin/env python3
"""1년치 기록을 만든다 — 초급에서 중급으로 넘어간 사람.

    python3 tool/seed_year.py > /tmp/notes.json

**왜 필요한가.** 화면과 통계를 눈으로 보려면 진짜처럼 생긴 기록이 있어야 한다.
스크린샷용으로 쓰던 씨앗은 다섯 날짜뿐이라, 추이도 정체도 안 보이고 1년을
넘겨보는 목록도 못 만든다.

**무엇이 '진짜처럼'인가.** 매주 2.5kg 씩 꼬박꼬박 오르는 데이터는 가짜다.
실제 1년은 이렇게 생겼다:
  - 처음 석 달은 갈 때마다 오른다(초보자 효과)
  - 그다음 막힌다. 같은 무게를 두세 번 반복하다 실패하고 10% 빼고 다시 온다
  - 아프거나 여행 가거나 명절이면 한두 주가 통째로 빈다
  - 쉬고 오면 첫 주는 이전보다 조금 못 든다
  - 보조 운동은 두 달쯤 지나 붙는다. 처음부터 열 종목을 하지 않는다
"""
import json
import random
import sys
from datetime import datetime, timedelta

random.seed(20260908)

END = datetime(2026, 9, 8, 20, 30)
START = END - timedelta(days=364)

# 이름, 시작 무게, 한 번에 오르는 폭, 막히기 시작하는 무게
BIG = [
    ('스쿼트',        50.0, 5.0,  110.0),
    ('벤치프레스',    40.0, 2.5,   75.0),
    ('데드리프트',    60.0, 5.0,  140.0),
    ('오버헤드프레스', 25.0, 2.5,   45.0),
    ('바벨로우',      40.0, 2.5,   70.0),
]
# 보조 운동은 나중에 붙는다. (이름, 시작일 오프셋, 시작 무게, 증가폭, 반복수)
SMALL = [
    ('랫풀다운',           60,  40.0, 2.5, (12, 10, 10)),
    ('레그프레스',         75, 100.0, 10.0, (15, 12, 12)),
    ('덤벨컬',             90,  10.0, 1.0,  (12, 12, 10)),
    ('사이드레터럴레이즈', 120,   6.0, 1.0,  (15, 15, 12)),
    ('케이블 푸시다운',    150,  20.0, 2.5, (15, 12, 12)),
]

# 3분할. 초반 두 달은 전신이라 큰 것 셋을 매번 한다.
SPLIT = [['스쿼트', '벤치프레스', '바벨로우'],
         ['데드리프트', '오버헤드프레스'],
         ['스쿼트', '벤치프레스', '랫풀다운']]

MEMOS = {
    'fail': ['마지막 세트 못 채움', '한 개 남기고 실패', '보조 받고 겨우'],
    'deload': ['무게 빼고 다시', '자세부터 잡자', '허리가 뻐근해서 줄임'],
    'pr': ['오늘 잘 됐다', '가볍게 올라감', '다음엔 더 갈 수 있을 듯'],
    'plain': ['그립 좁게', '벨트 착용', '호흡 신경 쓰기', '무릎 밖으로'],
}

state = {n: {'w': w, 'step': s, 'stall_at': c, 'miss': 0, 'best': w}
         for n, w, s, c in BIG}
small_state = {n: {'w': w, 'step': s, 'reps': r, 'from': f}
               for n, f, w, s, r in SMALL}

notes = []
day = START
week = 0
gaps = {6, 7, 23, 24, 38}          # 감기·여행·명절로 통째로 비는 주
rested = False

while day < END:
    week = (day - START).days // 7
    if week in gaps:
        day += timedelta(days=7)
        rested = True
        continue

    # 주 3회, 가끔 4회. 요일은 월/수/금 언저리에서 흔들린다.
    times = 4 if week > 20 and random.random() < 0.35 else 3
    offsets = sorted(random.sample([0, 1, 2, 3, 4, 5], times))

    for i, off in enumerate(offsets):
        d = day + timedelta(days=off,
                            hours=random.randint(-2, 3),
                            minutes=random.randint(0, 55))
        if d >= END:
            break
        plan = list(SPLIT[(week * len(offsets) + i) % len(SPLIT)])
        # 보조 운동은 때가 되면 한둘씩 붙는다.
        for name, st in small_state.items():
            if (d - START).days >= st['from'] and random.random() < 0.45:
                plan.append(name)
        plan = [p for p in plan if p in state or p in small_state][:5]

        blocks = []
        for name in plan:
            if name in state:
                s = state[name]
                w = s['w']
                # 쉬고 온 첫 주는 조금 못 든다.
                if rested:
                    w = max(s['step'], round((w * 0.92) / s['step']) * s['step'])
                    s['w'] = w
                hard = w >= s['stall_at']
                fail = hard and random.random() < 0.45
                reps = [5, 5, 5] if not fail else [5, 5, random.choice([2, 3, 4])]
                sets = [(w, r) for r in reps]
                if fail:
                    s['miss'] += 1
                    memo = random.choice(MEMOS['fail'])
                    if s['miss'] >= 2:                      # 두 번 실패하면 뺀다
                        s['w'] = round((w * 0.9) / s['step']) * s['step']
                        s['miss'] = 0
                        memo = random.choice(MEMOS['deload'])
                else:
                    s['miss'] = 0
                    memo = random.choice(MEMOS['pr']) if w > s['best'] else (
                        random.choice(MEMOS['plain']) if random.random() < 0.18 else None)
                    s['best'] = max(s['best'], w)
                    # 막히기 전에는 갈 때마다, 그 뒤로는 가끔만 오른다.
                    if w < s['stall_at'] or random.random() < 0.4:
                        s['w'] = w + s['step']
            else:
                st = small_state[name]
                w = st['w']
                sets = [(w, r) for r in st['reps']]
                memo = random.choice(MEMOS['plain']) if random.random() < 0.1 else None
                if random.random() < 0.25:
                    st['w'] = w + st['step']

            blocks.append({
                'name': name,
                'sets': [
                    {'value': v, 'unit': 'kg', 'reps': r,
                     'notes': [memo] if (memo and j == len(sets) - 1) else [],
                     'done': True}
                    for j, (v, r) in enumerate(sets)
                ],
            })

        end = d + timedelta(minutes=random.randint(48, 82))
        notes.append({
            'id': str(int(d.timestamp() * 1000000)),
            'createdAt': d.isoformat(),
            'updatedAt': end.isoformat(),
            # 애플워치를 찬 날만 칼로리가 있다. 앱은 추정하지 않는다.
            **({'calories': round(random.uniform(280, 520), 1)}
               if random.random() < 0.55 else {}),
            'blocks': blocks,
        })
        rested = False
    day += timedelta(days=7)

notes.sort(key=lambda n: n['updatedAt'], reverse=True)
json.dump(notes, sys.stdout, ensure_ascii=False)

def peak(name):
    best = 0.0
    for n in notes:
        for b in n['blocks']:
            if b['name'] == name:
                best = max(best, max(s['value'] for s in b['sets']))
    return best

print(f"\n기록 {len(notes)}일 · {START:%Y-%m-%d} ~ {END:%Y-%m-%d}", file=sys.stderr)
for name, w, *_ in BIG:
    print(f"  {name:12} {w:>5.1f} → {peak(name):>5.1f}kg", file=sys.stderr)
