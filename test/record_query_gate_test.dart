import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/record_query.dart';

/// 모델 없는 게이트.
///
/// 규칙 층("글에 또렷이 적힌 것은 코드가 읽는다")이 무엇을 약속하는지를
/// 생성된 문장 전부에 대고 몇 초 만에 검사한다. 모델 출력은 **일부러 최악**
/// 으로 흉내 낸다 — 메모 읽기로 빠지고, 의도를 틀리고, 기간과 조건을
/// 떨어뜨리고, 사용자 철자를 그대로 돌려준다. 실제 모델이 그렇게 냈던
/// 날이 있었다(dev 에서 11건 회귀). 이 게이트는 그런 회귀를 시뮬레이터
/// 없이 커밋 전에 잡는다.
///
/// 이것은 규칙 층의 계약이지 모델 정확도가 아니다. 오타와 초성은 모델
/// 몫이라 여기서 묻지 않는다.
void main() {
  const names = [
    '스쿼트', '벤치프레스', '데드리프트', '랫풀다운', '레그프레스', '바벨로우',
    '덤벨컬', '사이드레터럴레이즈', '오버헤드프레스', '케이블 푸시다운', '푸시업',
  ];
  final today = DateTime(2026, 9, 9);

  List<Map<String, Object?>> load(String name) =>
      (jsonDecode(File('tool/questions/$name.json').readAsStringSync()) as List)
          .cast<Map>()
          .map((c) => c.cast<String, Object?>())
          .toList();

  /// 모델이 낼 법한 최악의 출력 셋. 코드 층은 셋 모두에서 정답으로 돌아와야 한다.
  List<Map<String, Object?>> worst(String question, String form) => [
    // 1. 잡담에 이끌려 메모 읽기로 빠지고 terms 를 아무 낱말로 채웠다.
    {'action': 'readRecords', 'exercises': [form], 'periods': ['all'],
     'terms': [question.split(' ').last]},
    // 2. 의도를 틀렸다(전부 세트 수로), 기간과 조건은 떨어뜨렸다.
    {'action': 'setCount', 'exercises': [form], 'periods': ['all']},
    // 3. 순위로 냈다 — 운동 하나 지목한 순위는 언제나 무효다.
    {'action': 'rankExercises', 'metric': 'trainingDays', 'limit': 1,
     'exercises': [form], 'periods': ['all']},
  ];

  List<String> grade(RecordQueryPlan p, Map<String, Object?> exp) {
    final e = <String>[];
    if (p.requests.isEmpty) return ['no-request'];
    final r = p.requests.first;
    if (r.exercise != exp['exercise']) e.add('exercise');
    if (r.metric.name != exp['metric']) e.add('metric');
    if (exp['period'] == true && r.since == null) e.add('period-missing');
    if (exp['period'] == false && r.since != null) e.add('period-invented');
    if (exp.containsKey('minWeight') && r.minWeight != exp['minWeight']) e.add('minWeight');
    if (exp.containsKey('maxWeight') && r.maxWeight != exp['maxWeight']) e.add('maxWeight');
    if (exp.containsKey('minReps') && r.minReps != exp['minReps']) e.add('minReps');
    if (exp.containsKey('unit') && r.weightUnit != exp['unit']) e.add('unit');
    return e;
  }

  for (final set in ['dev', 'heldout']) {
    test('규칙 층은 최악의 모델 출력을 정답으로 돌린다 — $set', () {
      var graded = 0, passed = 0;
      final failures = <String>[];
      for (final c in load(set)) {
        final exp = (c['expected'] as Map).cast<String, Object?>();
        final kind = exp['formKind'];
        // 오타·초성은 모델 몫. 규칙 층의 계약은 별칭·조사·접두·띄어쓰기·영어다.
        if (exp['exercise'] == null || exp['exercise'] == '*' ||
            kind == null || kind == '오타' || kind == '초성' || kind == '별칭?') {
          continue;
        }
        final q = c['q'] as String;
        for (final (i, intent) in worst(q, exp['form'] as String).indexed) {
          graded++;
          List<String> errors;
          try {
            errors = grade(
              RecordQueryPlan.decode(intent, names, question: q, today: today),
              exp,
            );
          } catch (err) {
            errors = ['exception: $err'];
          }
          if (errors.isEmpty) {
            passed++;
          } else {
            failures.add('[$i] $q → $errors');
          }
        }
      }
      // ignore: avoid_print
      print('GATE $set: $passed/$graded');
      for (final f in failures.take(25)) {
        // ignore: avoid_print
        print('  ✗ $f');
      }
      // 전수 일치. 하나라도 빠지면 규칙 층이 물러난 것이다 — 어느 질문인지
      // 위에 찍힌다.
      expect(passed, graded);
    });
  }
}
