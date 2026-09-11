import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/stats.dart';

/// 모델이 돌려준 것을 코드가 어디까지 살려 주는가.
///
/// 모델 출력은 코드로 실행되지 않고 검증만 거친다. 검증이 너무 엄하면 답할 수
/// 있던 질문이 "해석 실패"로 죽고, 너무 느슨하면 틀린 답이 조용히 나간다.
/// 여기서는 그 경계를 못 박는다.
Map _withStatedMetricFor(String action, String q) {
  final plan = RecordQueryPlan.decode(
    {
      'action': action,
      // 순위는 운동을 지목하지 않는다 — 지목하면 순위 검증에 걸린다.
      'exercises': action == 'rankExercises' ? const [] : ['스쿼트'],
      'periods': ['all'],
      if (action == 'rankExercises') 'metric': 'trainingDays',
      if (action == 'rankExercises') 'limit': 1,
    },
    const ['스쿼트', '벤치프레스', '데드리프트'],
    question: q,
  );
  // decode 는 action 을 metric 으로 바꿔 돌려준다. 되돌려 견준다.
  const back = {
    'max': 'heaviest',
    'reps': 'repCount',
    'sets': 'setCount',
    'sessions': 'trainingDays',
    'trend': 'weightHistory',
    'last': 'latest',
    'volume': 'volume',
    'average': 'meanWeight',
  };
  if (plan.rank) return {'action': 'rankExercises'};
  return {'action': back[plan.requests.first.metric.name]};
}

void main() {
  const names = ['스쿼트', '벤치프레스', '데드리프트'];
  Map<String, Object?> plan(
    String exercise, {
    String unit = 'kg',
    double? min,
  }) => {
    'kind': 'answer',
    'rank': false,
    'compare': false,
    'limit': 1,
    'reason': '',
    'queries': [
      {
        'exercise': exercise,
        'metric': min == null ? 'max' : 'sets',
        'since': null,
        'until': null,
        'minWeight': min,
        'maxWeight': null,
        'minReps': null,
        'maxReps': null,
        'weightUnit': unit,
      },
    ],
  };

  test('모델이 사용자 철자를 그대로 돌려줘도 목록의 이름으로 맞춘다', () {
    final p = RecordQueryPlan.decode(plan('스쾃'), names);
    expect(p.requests.single.exercise, '스쿼트');
    expect(
      RecordQueryPlan.decode(plan('벤치'), names).requests.single.exercise,
      '벤치프레스',
    );
  });

  test('아무것도 안 닮은 이름은 여전히 버린다', () {
    expect(
      () => RecordQueryPlan.decode(plan('요가'), names),
      throwsFormatException,
    );
  });

  test('질문이 파운드면 모델이 kg 이라 해도 lb 다', () {
    final p = RecordQueryPlan.decode(
      plan('벤치프레스', unit: 'kg', min: 100),
      names,
      question: '벤치 100파운드 이상 세트 개수',
    );
    expect(p.requests.single.weightUnit, 'lb');
    expect(p.requests.single.minWeight, 100);
  });

  test('무게 조건이 없으면 단위를 건드리지 않는다', () {
    final p = RecordQueryPlan.decode(
      plan('벤치프레스'),
      names,
      question: '벤치 파운드로 얼마?',
    );
    expect(p.requests.single.weightUnit, 'kg');
  });

  test('파운드 말이 없으면 모델 단위를 믿는다', () {
    final p = RecordQueryPlan.decode(
      plan('벤치프레스', min: 90),
      names,
      question: '벤치 90 이상',
    );
    expect(p.requests.single.weightUnit, 'kg');
  });

  group('글이 정하는 것', () {
    test('사전 키와 정확히 같은 낱말만 정식 이름으로 바꾼다', () {
      expect(canonicalizeExercises('스쾃 PR 얼마?', names), '스쿼트 PR 얼마?');
      expect(canonicalizeExercises('bp 최고', names), '벤치프레스 최고');
      // "벤치" 는 사전 키가 아니라 접두어다. 모델이 잘 다루니 건드리지 않는다.
      expect(canonicalizeExercises('벤치 최고', names), '벤치 최고');
      // 오타는 퍼지로 바꾸지 않는다 — 질문이 바뀔 수 있다.
      expect(canonicalizeExercises('밴치 최고', names), '밴치 최고');
    });

    test('기간 낱말이 하나면 그것, 둘이면 모델에 맡긴다', () {
      expect(statedPeriod('이번 주 어깨 아팠다고 쓴 거 있어?')?.period, 'thisWeek');
      expect(statedPeriod('지난달 벤치')?.period, 'lastMonth');
      expect(statedPeriod('최근 14일 푸시업')?.days, 14);
      expect(statedPeriod('지난달보다 이번 달 스쿼트'), isNull);
      expect(statedPeriod('벤치 최고'), isNull);
    });

    test('숫자 조건은 글에 적힌 대로', () {
      final f = statedFilters('데드 80kg 이상 5회 이상 한 세트 수');
      expect((f.minWeight, f.unit, f.minReps), (80.0, 'kg', 5));
      final g = statedFilters('벤치 100파운드 이하');
      expect((g.maxWeight, g.unit), (100.0, 'lb'));
      expect(statedFilters('스쿼트 60 이상').minWeight, isNull); // 단위 없음
    });

    test('모델이 조건 하나를 떨어뜨려도 글이 채운다', () {
      final p = RecordQueryPlan.decode(
        plan('데드리프트', min: 80),
        names,
        question: '데드 80kg 이상 5회 이상 한 세트 수',
      );
      final r = p.requests.single;
      expect((r.minWeight, r.minReps, r.weightUnit), (80.0, 5, 'kg'));
    });

    test('PR 은 최고다 — 모델이 순위로 읽어도 바로잡는다', () {
      // 실제 모델 출력 그대로: "스쿼트 PR 얼마?" → 운동일수 순위.
      final p = RecordQueryPlan.decode(
        {
          'action': 'rankExercises',
          'metric': 'trainingDays',
          'limit': 1,
          'exercises': ['스쿼트'],
          'periods': ['all'],
        },
        names,
        question: '스쿼트 PR 얼마?',
      );
      expect(p.rank, isFalse);
      expect(p.requests.single.exercise, '스쿼트');
      expect(p.requests.single.metric, Metric.max);
    });

    test('PR 이라도 운동이 둘이면 손대지 않는다', () {
      expect(
        () => RecordQueryPlan.decode(
          {
            'action': 'rankExercises',
            'metric': 'trainingDays',
            'limit': 1,
            'exercises': ['스쿼트', '벤치프레스'],
            'periods': ['all'],
          },
          names,
          question: '스쿼트랑 벤치 PR',
        ),
        throwsFormatException, // 원래 규칙대로 순위 검증에서 걸린다
      );
    });

    test('조사가 붙어도 정식 이름으로 바꾼다', () {
      expect(canonicalizeExercises('스쾃은 최고 얼마', names), '스쿼트은 최고 얼마');
      expect(canonicalizeExercises('bp는 PR', names), '벤치프레스는 PR');
    });

    test('수사 한글 조건', () {
      expect(statedFilters('벤치 팔십 킬로 이상').minWeight, 80);
      expect(statedFilters('스쿼트 백이십 kg 이하').maxWeight, 120);
      expect(statedFilters('푸시업 이십 회 이상').minReps, 20);
    });

    test('달 이름과 최근 N주·개월', () {
      final t = DateTime(2026, 9, 9);
      final sept = statedPeriod('9월에 벤치 몇 번', today: t)!;
      expect(
        (sept.period, sept.since, sept.until),
        ('custom', '2026-09-01', '2026-09-30'),
      );
      final dec = statedPeriod('12월 스쿼트', today: t)!;
      expect(dec.since, '2025-12-01'); // 아직 안 온 달은 작년
      expect(statedPeriod('최근 2주 푸시업')?.days, 14);
      expect(statedPeriod('최근 3개월 벤치')?.days, 90);
      expect(statedPeriod('3개월간 벤치'), isNull); // "간" 은 기간 길이지 달 이름이 아니다
    });

    test('의도 낱말이 한 갈래면 그것이 의도다', () {
      Map run(String action, String q) => _withStatedMetricFor(action, q);
      expect(run('setCount', '벤치프레스 총 몇 회')['action'], 'repCount');
      expect(run('setCount', '스쿼트 몇 번 했지')['action'], 'trainingDays');
      expect(run('trainingDays', '데드 최고 무게')['action'], 'heaviest');
      // 두 갈래("최고" + "세트 수")면 모델의 답을 둔다.
      expect(run('setCount', '벤치 최고 세트 수')['action'], 'setCount');
      // 순위·비교는 손대지 않는다.
      expect(run('rankExercises', '최고 많이 한 운동')['action'], 'rankExercises');
    });

    test('단위가 회인 무게 조건은 버리고, 글의 회수 조건이 채운다', () {
      final p = RecordQueryPlan.decode(
        {
          'action': 'setCount',
          'exercises': ['벤치프레스'],
          'periods': ['all'],
          'weight': {'relation': 'atLeast', 'value': 5, 'unit': '회'},
        },
        names,
        question: '벤치 세트 몇 개 5회 이상',
      );
      final r = p.requests.single;
      expect(r.minWeight, isNull);
      expect(r.minReps, 5);
    });

    test('글에 기간이 하나면 모델의 비교 기간 둘은 접는다', () {
      final t = DateTime(2026, 9, 9);
      final p = RecordQueryPlan.decode(
        {
          'action': 'weightHistory',
          'exercises': ['벤치프레스'],
          'periods': ['lastMonth', 'thisMonth'],
        },
        names,
        today: t,
        question: '이번 달 벤치 무게 변화',
      );
      expect(p.compare, isFalse);
      expect(p.requests.length, 1);
      expect(p.requests.single.since, DateTime(2026, 9, 1));
    });

    test('운동 하나를 지목한 순위는 의도 낱말로 바꾼다', () {
      final p = RecordQueryPlan.decode(
        {
          'action': 'rankExercises',
          'metric': 'trainingDays',
          'limit': 1,
          'exercises': ['벤치프레스'],
          'periods': ['all'],
        },
        names,
        question: '벤치프레스는 정체기인가',
      );
      expect(p.rank, isFalse);
      expect(p.requests.single.metric, Metric.trend);
    });

    test('별칭은 낱말마다 잡힌다 — dl', () {
      expect(canonicalizeExercises('dl 다 합쳐서 몇 개', names), '데드리프트 다 합쳐서 몇 개');
      // 정식 영어 이름의 낱말은 안 바꾼다.
      expect(canonicalizeExercises('press 최고', names), 'press 최고');
    });

    test('이름이 필요한데 * 면, 글에서 하나만 잡힐 때 그걸로', () {
      final p = RecordQueryPlan.decode(
        {
          'action': 'weightHistory',
          'exercises': [],
          'periods': ['all'],
        },
        names,
        question: '스쿼트 요즘 어때',
      );
      expect(p.requests.single.exercise, '스쿼트');
      // 둘 잡히면 모른다고 둔다 — 원래 규칙대로 걸린다.
      expect(
        () => RecordQueryPlan.decode(
          {
            'action': 'weightHistory',
            'exercises': [],
            'periods': ['all'],
          },
          names,
          question: '스쿼트 벤치 요즘 어때',
        ),
        throwsFormatException,
      );
    });

    test('의도에 기간이 없고 글에 있으면 코드가 채운다', () {
      final today = DateTime(2026, 9, 9);
      final p = RecordQueryPlan.decode(
        {
          'action': 'heaviest',
          'exercises': ['스쿼트'],
          'periods': ['all'],
        },
        names,
        today: today,
        question: '이번 주 스쿼트 최고',
      );
      final r = p.requests.single;
      expect(r.since, isNotNull);
      expect(r.since!.isAfter(today.subtract(const Duration(days: 8))), isTrue);
    });
  });
}
