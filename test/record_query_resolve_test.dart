import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/stats.dart';

/// 모델이 돌려준 것을 코드가 어디까지 살려 주는가.
///
/// 모델 출력은 코드로 실행되지 않고 검증만 거친다. 검증이 너무 엄하면 답할 수
/// 있던 질문이 "해석 실패"로 죽고, 너무 느슨하면 틀린 답이 조용히 나간다.
/// 여기서는 그 경계를 못 박는다.
void main() {
  const names = ['스쿼트', '벤치프레스', '데드리프트'];
  Map<String, Object?> plan(String exercise, {String unit = 'kg', double? min}) => {
    'kind': 'answer', 'rank': false, 'compare': false, 'limit': 1, 'reason': '',
    'queries': [
      {'exercise': exercise, 'metric': min == null ? 'max' : 'sets',
       'since': null, 'until': null, 'minWeight': min, 'maxWeight': null,
       'minReps': null, 'maxReps': null, 'weightUnit': unit},
    ],
  };

  test('모델이 사용자 철자를 그대로 돌려줘도 목록의 이름으로 맞춘다', () {
    final p = RecordQueryPlan.decode(plan('스쾃'), names);
    expect(p.requests.single.exercise, '스쿼트');
    expect(RecordQueryPlan.decode(plan('벤치'), names).requests.single.exercise, '벤치프레스');
  });

  test('아무것도 안 닮은 이름은 여전히 버린다', () {
    expect(() => RecordQueryPlan.decode(plan('요가'), names), throwsFormatException);
  });

  test('질문이 파운드면 모델이 kg 이라 해도 lb 다', () {
    final p = RecordQueryPlan.decode(
      plan('벤치프레스', unit: 'kg', min: 100), names,
      question: '벤치 100파운드 이상 세트 개수',
    );
    expect(p.requests.single.weightUnit, 'lb');
    expect(p.requests.single.minWeight, 100);
  });

  test('무게 조건이 없으면 단위를 건드리지 않는다', () {
    final p = RecordQueryPlan.decode(plan('벤치프레스'), names, question: '벤치 파운드로 얼마?');
    expect(p.requests.single.weightUnit, 'kg');
  });

  test('파운드 말이 없으면 모델 단위를 믿는다', () {
    final p = RecordQueryPlan.decode(plan('벤치프레스', min: 90), names, question: '벤치 90 이상');
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
        plan('데드리프트', min: 80), names,
        question: '데드 80kg 이상 5회 이상 한 세트 수',
      );
      final r = p.requests.single;
      expect((r.minWeight, r.minReps, r.weightUnit), (80.0, 5, 'kg'));
    });

    test('PR 은 최고다 — 모델이 순위로 읽어도 바로잡는다', () {
      // 실제 모델 출력 그대로: "스쿼트 PR 얼마?" → 운동일수 순위.
      final p = RecordQueryPlan.decode(
        {'action': 'rankExercises', 'metric': 'trainingDays', 'limit': 1,
         'exercises': ['스쿼트'], 'periods': ['all']},
        names, question: '스쿼트 PR 얼마?',
      );
      expect(p.rank, isFalse);
      expect(p.requests.single.exercise, '스쿼트');
      expect(p.requests.single.metric, Metric.max);
    });

    test('PR 이라도 운동이 둘이면 손대지 않는다', () {
      expect(
        () => RecordQueryPlan.decode(
          {'action': 'rankExercises', 'metric': 'trainingDays', 'limit': 1,
           'exercises': ['스쿼트', '벤치프레스'], 'periods': ['all']},
          names, question: '스쿼트랑 벤치 PR',
        ),
        throwsFormatException,   // 원래 규칙대로 순위 검증에서 걸린다
      );
    });

    test('의도에 기간이 없고 글에 있으면 코드가 채운다', () {
      final today = DateTime(2026, 9, 9);
      final p = RecordQueryPlan.decode(
        {'action': 'heaviest', 'exercises': ['스쿼트'], 'periods': ['all']},
        names, today: today, question: '이번 주 스쿼트 최고',
      );
      final r = p.requests.single;
      expect(r.since, isNotNull);
      expect(r.since!.isAfter(today.subtract(const Duration(days: 8))), isTrue);
    });
  });
}
