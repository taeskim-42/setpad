import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/record_query.dart';

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
}
