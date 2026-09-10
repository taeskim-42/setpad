import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/stats.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/editor.dart';

void main() {
  const names = ['벤치프레스', '스쿼트'];
  final reference = DateTime(2031, 2, 10);
  RecordQueryPlan decode(Map<String, Object?> raw, String question) =>
      RecordQueryPlan.decode(raw, names, question: question, today: reference);
  Map<String, Object?> metric(String action) => {
    'action': action,
    'exercises': ['스쿼트'],
    'periods': ['all'],
  };

  test('numbers quoted in notes do not become completed-set filters', () {
    final p = decode({
      ...metric('readRecords'),
      'terms': ['80kg', '계획'],
    }, '스쿼트 80kg 이상 하겠다는 계획 메모');
    expect(p.kind, 'insight');
    expect(p.requests.single.minWeight, isNull);
    expect(p.requests.single.maxWeight, isNull);
  });

  test('separate kg and lb conditions select the correct saved sets', () {
    final p = decode({
      'kind': 'answer',
      'queries': [
        {
          'exercise': '벤치프레스',
          'metric': 'sets',
          'minWeight': 80,
          'weightUnit': 'kg',
        },
        {
          'exercise': '스쿼트',
          'metric': 'sets',
          'maxWeight': 100,
          'weightUnit': 'lb',
        },
      ],
    }, '벤치프레스 80kg 이상 세트와 스쿼트 100파운드 이하 세트');
    final records = [
      Note(
        id: 'units',
        createdAt: reference,
        updatedAt: reference,
        blocks: [
          ExerciseBlock('벤치프레스', [LoggedSet(value: 90, unit: 'kg', reps: 5)]),
          ExerciseBlock('스쿼트', [LoggedSet(value: 110, unit: 'lb', reps: 5)]),
        ],
      ),
    ];
    int count(RecordRequest request) => recordsForRequest(
      records,
      request,
      'kg',
    ).expand((n) => n.blocks).expand((b) => b.sets).length;
    expect(p.requests.map(count).toList(), [1, 0]);
    expect(records.single.blocks.last.sets.single.value, 110);
  });

  test('a unit word alone cannot relabel an already converted model bound', () {
    final p = decode({
      'kind': 'answer',
      'queries': [
        {
          'exercise': '스쿼트',
          'metric': 'sets',
          'minWeight': 45.359237,
          'weightUnit': 'kg',
        },
      ],
    }, '스쿼트 100파운드보다 무거운 세트');
    expect(p.requests.single.weightUnit, 'kg');
    expect(p.requests.single.minWeight, 45.359237);
  });

  test('month resolution uses the supplied clock and explicit year', () {
    final priorDecember = decode(metric('heaviest'), '12월 스쿼트 최고');
    expect(priorDecember.requests.single.since, DateTime(2030, 12));
    final explicit = decode(metric('heaviest'), '2025년 9월 스쿼트 최고');
    expect(explicit.requests.single.since, DateTime(2025, 9));
    expect(explicit.requests.single.until, DateTime(2025, 9, 30));
  });

  test(
    'a specific day or open date range is not replaced with a whole month',
    () {
      for (final question in ['9월 3일 스쿼트 최고', '9월부터 스쿼트 최고']) {
        final p = decode({
          ...metric('heaviest'),
          'periods': ['custom'],
          'since': '2025-09-03',
          'until': '2025-09-03',
        }, question);
        expect(p.requests.single.since, DateTime(2025, 9, 3));
        expect(p.requests.single.until, DateTime(2025, 9, 3));
        expect(statedPeriod(question, today: reference), isNull);
      }
    },
  );

  test('two named months keep the model comparison', () {
    final p = decode({
      ...metric('heaviest'),
      'periods': ['lastMonth', 'thisMonth'],
    }, '1월과 2월 스쿼트 최고 비교');
    expect(p.compare, isTrue);
    expect(p.requests.length, 2);
    expect(p.requests.first.since, DateTime(2031, 1));
    expect(p.requests.last.since, DateTime(2031, 2));
  });

  test('mentioning PR or a weight in a note does not change a note query', () {
    for (final q in ['스쿼트 PR 얘기 쓴 메모 찾아줘', '스쿼트 평균 무게에 대한 메모']) {
      final p = decode({
        ...metric('readRecords'),
        'terms': ['메모'],
      }, q);
      expect(p.kind, 'insight');
      expect(p.terms, ['메모']);
    }
    final latest = decode(metric('latest'), '스쿼트 최고 기록 말고 마지막 기록');
    expect(latest.requests.single.metric, Metric.last);
  });

  test(
    'opposite model bound is removed when a single explicit filter corrects it',
    () {
      final p = decode({
        ...metric('setCount'),
        'weight': {'operator': '<=', 'value': 100, 'unit': 'kg'},
      }, '스쿼트 100파운드 이상 세트 수');
      final r = p.requests.single;
      expect((r.minWeight, r.maxWeight, r.weightUnit), (100.0, null, 'lb'));
    },
  );

  test('different exercises retain their own filters and units', () {
    final p = decode({
      'kind': 'answer',
      'queries': [
        {
          'exercise': '벤치프레스',
          'metric': 'sets',
          'minWeight': 80,
          'weightUnit': 'kg',
        },
        {
          'exercise': '스쿼트',
          'metric': 'sets',
          'maxWeight': 100,
          'weightUnit': 'lb',
        },
      ],
    }, '벤치프레스 80kg 이상 세트와 스쿼트 100파운드 이하 세트');
    expect(
      (
        p.requests[0].minWeight,
        p.requests[0].maxWeight,
        p.requests[0].weightUnit,
      ),
      (80.0, null, 'kg'),
    );
    expect(
      (
        p.requests[1].minWeight,
        p.requests[1].maxWeight,
        p.requests[1].weightUnit,
      ),
      (null, 100.0, 'lb'),
    );
  });

  test(
    'alternatives, exclusions, and mixed units do not create a global range',
    () {
      for (final q in [
        '80kg 이상 또는 50kg 이하',
        '80kg 이상 제외',
        '80kg 이상 200lb 이하',
      ]) {
        final f = statedFilters(q);
        expect((f.minWeight, f.maxWeight, f.unit), (null, null, null));
      }
      final f = statedFilters('90kg 이상 80kg 이상 150kg 이하 160kg 이하');
      expect((f.minWeight, f.maxWeight), (90.0, 150.0));
      expect(statedFilters('100lb OR MORE').minWeight, 100);
    },
  );

  test('메모 낱말 없이 readRecords 로 낸 추이 질문은 의도 낱말이 이긴다', () {
    // dev 세트에서 실제로 빠졌던 것들. 모델이 잡담에 이끌려 메모 읽기로 냈다.
    for (final (q, want) in [
      ('스쿼트가 그래프 궁금', Metric.trend),
      ('음 이번 달 벤치프레스 무게 변화 알려줘', Metric.trend),
      ('야 이번 달 저번에 스쿼트 얼마 들었지 보여줘', Metric.last),
      ('아 근데 9월에 벤치프레스 다 합쳐서 몇 개 보여줘', Metric.reps),
    ]) {
      final p = decode({...metric('readRecords'), 'terms': []}, q);
      expect(p.requests.single.metric, want, reason: q);
      expect(p.kind, 'answer', reason: q);
    }
  });

  test('모델이 terms 를 채워도 메모 낱말이 없으면 의도 낱말이 이긴다', () {
    // 실제 모델은 "스쿼트가 그래프 궁금" 에 readRecords + terms:['그래프'] 를 낸다.
    final p = decode({...metric('readRecords'), 'terms': ['그래프']}, '스쿼트가 그래프 궁금');
    expect(p.kind, 'answer');
    expect(p.requests.single.metric, Metric.trend);
  });

  test('메모 낱말이 있으면 readRecords 를 둔다', () {
    final p = decode({...metric('readRecords'), 'terms': []}, '스쿼트 그래프 얘기 쓴 메모');
    expect(p.kind, 'insight');
  });

  test('범위 표현은 달 하나로 잡지 않지만, 무게의 "까지" 는 범위가 아니다', () {
    final t = DateTime(2026, 9, 9);
    expect(statedPeriod('9월 1일부터 벤치프레스', today: t), isNull);
    expect(statedPeriod('지난달까지 스쿼트 최고', today: t), isNull);
    expect(statedPeriod('9월 3일 스쿼트', today: t), isNull);
    expect(statedPeriod('9월에 몇 kg까지 들었지', today: t)?.period, 'custom');
    expect(statedPeriod('이번 주 100kg까지 갔나', today: t)?.period, 'thisWeek');
  });

  test('"9월에" 는 이번 해 9월이다', () {
    final f = statedPeriod('9월에 데드리프트 몇 kg까지 들었지 좀', today: DateTime(2026, 9, 9))!;
    expect((f.period, f.since, f.until), ('custom', '2026-09-01', '2026-09-30'));
    // 이 파일의 decode 도우미는 기준일이 2031-02-10 이다. 2월에 말하는 "9월" 은
    // 아직 안 온 달이라 작년, 2030년 9월이다.
    final p = decode({...metric('heaviest'), 'periods': ['all']}, '9월에 스쿼트 몇 kg까지 들었지 좀');
    expect(p.requests.single.since, DateTime(2030, 9, 1));
    expect(p.requests.single.until, DateTime(2030, 9, 30));
  });

  group('자신 있게 틀리지 않기', () {
    Map<String, Object?> emptyRank() => {
      'action': 'rankExercises', 'metric': 'trainingDays', 'limit': 1,
      'exercises': [], 'periods': ['all'],
    };

    test('운동 없는 순위라도 글에 운동이 하나면 순위가 아니다', () {
      for (final (q, want) in [
        ('지난달 벤치프레스는 정체기인가', Metric.trend),
        ('올해 스쿼트 늘고 있나', Metric.trend),
        ('야 9월에 벤치프레스 PRㅋㅋ', Metric.max),
        ('스쿼트 직전 세트?', Metric.last),
      ]) {
        final p = decode(emptyRank(), q);
        expect(p.rank, isFalse, reason: q);
        expect(p.requests.single.metric, want, reason: q);
        expect(p.requests.single.exercise, isNot('*'), reason: q);
      }
    });

    test('진짜 순위(운동 이름 없음)는 그대로 순위다', () {
      expect(decode(emptyRank(), '가장 자주 한 운동 세 개').rank, isTrue);
    });

    test('글에 시간 말이 없는데 기간을 냈으면 의심한다', () {
      final p = decode({...metric('weightHistory'), 'periods': ['recent'], 'days': 28},
          '스쿼트 추이 알려줘');
      expect(p.doubts, contains('period'));
      final q = decode({...metric('weightHistory'), 'periods': ['recent'], 'days': 28},
          '요즘 스쿼트 추이');
      expect(q.doubts, isNot(contains('period')));
    });

    test('운동이 둘 언급됐는데 하나만 답하면 의심한다', () {
      expect(decode(metric('heaviest'), '벤치프레스랑 스쿼트 최고').doubts, contains('exercises'));
      expect(decode(metric('heaviest'), '스쿼트 최고').doubts, isNot(contains('exercises')));
    });

    test('운동 둘을 이름 없는 순위로 뭉개도 의심한다', () {
      final p = decode(emptyRank(), '벤치프레스랑 스쿼트 최고');
      expect(p.rank, isTrue);                       // 규칙은 손대지 않는다(운동 둘)
      expect(p.doubts, contains('exercises'));      // 대신 묻는다
      expect(decode(emptyRank(), '가장 자주 한 운동 세 개').doubts, isEmpty);
    });

    test('오타를 퍼지로 읽었으면 무엇으로 읽었는지 남긴다', () {
      final p = decode({...metric('heaviest'), 'exercises': ['스쿼드']}, '스쿼드 최고');
      expect(p.requests.single.exercise, '스쿼트');
      expect(p.readAs, {'스쿼트': '스쿼드'});
      expect(decode(metric('heaviest'), '스쿼트 최고').readAs, isEmpty);
    });
  });
}
