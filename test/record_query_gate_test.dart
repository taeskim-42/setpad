import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/record_query.dart';
import '../tool/question_grading.dart';

/// 모델 없는 게이트.
///
/// 규칙 층의 계약을 생성된 문장 전부에 대고 몇 초 만에 검사한다. 계약은 둘이다:
/// 1. **맞는 plan 은 바꾸지 않는다.** 정답 plan 을 모델 답으로 넣으면 규칙 층을
///    지난 뒤에도 정답이다 — v3 재검토의 뿌리는 규칙 층이 모델의 맞는 plan 을
///    덮어쓴 것이었다.
/// 2. **떨어뜨린 조건은 채운다.** 모델이 운동 이름만 돌려주고 기간·숫자 조건·
///    측정을 떨어뜨렸으면, 글에 하나만 또렷이 적힌 것을 채워 정답이 된다.
/// 채점은 v1 정답을 v3 대안으로 바꿔(v2Expected → v3Alternatives) 규칙 층을 지난
/// plan([groundedIntent])과 뜻 전체를 견준다(tool/question_grading.dart).
///
/// 모델이 적은 것을 규칙이 바로잡던 '최악의 출력' 게이트는 뺐다 — 뜻이 둘인
/// 낱말로 모델의 측정·기간을 덮으면 맞는 plan 도 덮는다. 오타와 초성은 모델
/// 몫이라 여기서 묻지 않는다.
void main() {
  const names = [
    '스쿼트',
    '벤치프레스',
    '데드리프트',
    '랫풀다운',
    '레그프레스',
    '바벨로우',
    '덤벨컬',
    '사이드레터럴레이즈',
    '오버헤드프레스',
    '케이블 푸시다운',
    '푸시업',
  ];
  final today = DateTime(2026, 9, 9);

  List<Map<String, Object?>> load(String name) =>
      (jsonDecode(File('tool/questions/$name.json').readAsStringSync()) as List)
          .cast<Map>()
          .map((c) => c.cast<String, Object?>())
          .toList();

  /// 모델 답 둘: 정답 그대로, 그리고 운동 이름만 남기고 조건을 모두 떨어뜨린 것.
  List<Map<String, Object?>> answers(List<Object?> gold, String form) => [
    (gold.first as Map).cast<String, Object?>(),
    {
      'exercises': [form],
    },
  ];

  for (final set in ['dev', 'heldout']) {
    test('규칙 층은 맞는 plan 을 두고, 떨어뜨린 조건은 채운다 — $set', () {
      var graded = 0, passed = 0;
      final failures = <String>[];
      for (final c in load(set)) {
        final exp = (c['expected'] as Map).cast<String, Object?>();
        final kind = exp['formKind'];
        // 오타·초성은 모델 몫. 규칙 층의 계약은 별칭·조사·접두·띄어쓰기·영어다.
        if (exp['exercise'] == null ||
            exp['exercise'] == '*' ||
            kind == null ||
            kind == '오타' ||
            kind == '초성' ||
            kind == '별칭?') {
          continue;
        }
        final q = c['q'] as String;
        final gold = v3Alternatives(v2Expected(exp)!);
        for (final (i, intent) in answers(
          gold,
          exp['form'] as String,
        ).indexed) {
          graded++;
          List<String> errors;
          try {
            RecordQuery.decode(intent, names, question: q, today: today);
            errors = gradePlan(
              groundedIntent(intent, q, names, today: today),
              gold,
              names: names,
              lang: 'ko',
              question: q,
            ).errors;
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
