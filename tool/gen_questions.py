#!/usr/bin/env python3
"""정답이 붙은 질문 세트를 만든다 — 자기 문제로 자기 채점하지 않기 위해.

    python3 tool/gen_questions.py heldout   # 시드 고정. 튜닝에 절대 쓰지 않는다
    python3 tool/gen_questions.py dev       # 다른 시드. 고칠 때는 이것만 본다

축을 조합한다: 운동 표기(정식·별칭·접두·오타·조사·띄어쓰기·영어) × 의도 ×
기간 × 숫자 조건 × 말투. 거기에 최악 케이스를 일부러 섞는다 — 무관한 질문,
운동 없는 질문, 두 운동, 수사 한글, 잡담 접두.

정답은 템플릿이 안다. 채점은 tool/interpret_questions.dart 가 한다.
결과 파일: tool/questions/<name>.txt (한 줄 한 문장), <name>.json (정답).
"""
import json, random, sys, pathlib

NAME = sys.argv[1] if len(sys.argv) > 1 else 'heldout'
SEED = {'heldout': 20260909, 'dev': 1}[NAME]
rng = random.Random(SEED)

# 운동: 정식 이름 → 표기 변형들 (변형, 종류)
EX = {
  '벤치프레스': [('벤치프레스','정식'),('벤치','접두'),('bp','별칭'),('bench press','영어'),
             ('벤치 프레스','띄어'),('밴치프레스','오타'),('벤치프레스는','조사'),('벤치는','조사'),('ㅂㅊㅍㄹㅅ','초성')],
  '스쿼트':   [('스쿼트','정식'),('스쾃','별칭'),('스쿼','접두'),('squat','영어'),('스쿼트가','조사'),('스쿼드','오타'),('ㅅㅋㅌ','초성')],
  '데드리프트': [('데드리프트','정식'),('데드','접두'),('dl','별칭'),('deadlift','영어'),('데드 리프트','띄어'),('데드리프트의','조사'),('대드리프트','오타')],
  '오버헤드프레스': [('오버헤드프레스','정식'),('오버헤드','접두'),('ohp','별칭'),('오버헤드 프레스','띄어')],
  '랫풀다운': [('랫풀다운','정식'),('랫풀','접두'),('lat pulldown','영어'),('렛풀다운','오타')],
  '푸시업':   [('푸시업','정식'),('푸쉬업','오타'),('pushup','별칭'),('팔굽혀펴기','별칭?')],
}

# 의도 → 말투들. {x} 자리에 운동 표기.
METRIC = {
  'max':      ['{x} 최고 기록','{x} 최고','{x} PR','{x} 제일 무겁게 든 게','{x} 몇 kg까지 들었지','{x} 맥스 얼마','{x} 개인 기록','{x} 최고 무게는?'],
  'trend':    ['{x} 추이','{x} 늘고 있나','{x} 무게 변화','{x} 정체기인가','{x} 그래프','{x} 요즘 어때'],
  'last':     ['저번에 {x} 얼마 들었지','{x} 마지막 기록','{x} 지난번에 얼마','{x} 최근에 언제 했어','{x} 직전 세트'],
  'sessions': ['{x} 몇 번 했지','{x} 며칠 했어','{x} 몇 일 갔지','{x} 얼마나 자주 해'],
  'volume':   ['{x} 볼륨','{x} 총량','{x} 총 무게','{x} 전체 볼륨 얼마'],
  'sets':     ['{x} 총 몇 세트','{x} 세트 수','{x} 세트 몇 개 했어'],
  'reps':     ['{x} 총 몇 회','{x} 총 반복 횟수','{x} 다 합쳐서 몇 개'],
  'average':  ['{x} 평균 무게','{x} 평균 얼마나 들어'],
}
PERIOD = [('', False), ('이번 주 ', True), ('지난주 ', True), ('이번 달 ', True), ('지난달 ', True),
          ('올해 ', True), ('최근 2주 ', True), ('오늘 ', True), ('9월에 ', True)]
FILTER = [
  ('', {}),
  (' 80kg 이상', {'minWeight': 80.0, 'unit': 'kg'}),
  (' 100파운드 이하', {'maxWeight': 100.0, 'unit': 'lb'}),
  (' 5회 이상', {'minReps': 5}),
  (' 60kg 이상 8회 이상', {'minWeight': 60.0, 'minReps': 8, 'unit': 'kg'}),
  (' 팔십 킬로 이상', {'minWeight': 80.0, 'unit': 'kg'}),   # 수사 한글 — 최악 케이스
]
PREFIX = ['', '', '', '아 근데 ', '진짜 궁금한데 ', '음 ', '야 ']
SUFFIX = ['', '', '?', ' 알려줘', ' 보여줘', ' 궁금', 'ㅋㅋ', ' 좀']

cases = []
def add(q, exp, cat):
    cases.append({'q': q.strip(), 'expected': exp, 'cat': cat})

# 1) 조합 — 각 (운동 변형, 의도)마다 기간·조건·말투를 무작위로 하나씩.
for canon, forms in EX.items():
    for form, kind in forms:
        for metric, phr in METRIC.items():
            tpl = rng.choice(phr)
            per, has_period = rng.choice(PERIOD)
            flt, fexp = rng.choice(FILTER) if metric in ('sets','reps','sessions','volume') else ('', {})
            q = rng.choice(PREFIX) + per + tpl.format(x=form) + flt + rng.choice(SUFFIX)
            exp = {'exercise': canon, 'metric': metric, 'period': has_period, **fexp}
            add(q, exp, f'표기:{kind}')

# 2) 최악 케이스
for q in ['내일 비 오나', '파이썬 계산기 만들어줘', '점심 뭐 먹지', '오늘 기분 어때', '2+2', '안녕']:
    add(q, {'kind': 'unsupported'}, '무관')
for q in ['몇 번 갔지', '이번 달 며칠 운동했어', '지난주 몇 번 갔어', '올해 운동한 날']:
    add(q, {'exercise': '*', 'metric': 'sessions'}, '운동없음')
for q in ['벤치랑 스쿼트 최고', '스쿼트 데드 비교', '벤치프레스 스쿼트 데드리프트 3대 합']:
    add(q, {'exercises': 2}, '두운동')
for q in ['벤치 100kg 넘게 든 세트', '데드 150 초과']:
    add(q, {'exercise': None, 'metric': None}, '초과/미만(모델 몫)')   # 채점 안 함, 관찰만
for q in ['ㅂㅊ', 'ㅅㅋ 최고', 'ㄷㄷ 마지막']:
    add(q, {'note': '초성 2자'}, '초성짧음')

rng.shuffle(cases)
out = pathlib.Path('tool/questions')
(out / f'{NAME}.txt').write_text('\n'.join(c['q'] for c in cases) + '\n')
(out / f'{NAME}.json').write_text(json.dumps(cases, ensure_ascii=False, indent=1))
from collections import Counter
print(f'{NAME}: {len(cases)}문장 · 시드 {SEED}')
for k, v in sorted(Counter(c['cat'] for c in cases).items()): print(f'  {k:16} {v}')
