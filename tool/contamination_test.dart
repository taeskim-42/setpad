import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 지시문 예시(`"…" => {…}` 줄)가 평가 문항과 같으면 그 문항은 답을 베껴
/// 맞힌다 — 점수가 부푼다(v2 지시문 예시 27개 중 15개가 v2.json 문항과 같았다).
/// 지시문이 어느 파일에 있든 lib/ 의 예시 줄을 모두 모아 v2·dev·heldout·v3 의
/// 모든 질문과 견준다. 대소문자·띄어쓰기·문장부호는 무시한다.
///
///     flutter test tool/contamination_test.dart
String _norm(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[\s\p{P}\p{S}]+', unicode: true), '');

void main() {
  test('지시문 예시는 평가 문항(v2·dev·heldout·v3)과 같지 않다', () {
    final examples = <String>{
      for (final f in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart'))
          for (final m in RegExp(
            r'^"(.+?)" =>',
            multiLine: true,
          ).allMatches(f.readAsStringSync()))
            m[1]!,
    };
    expect(examples, isNotEmpty, reason: 'lib/ 에서 지시문 예시 줄을 못 찾았다');
    final questions = <String, String>{
      for (final set in ['v2', 'dev', 'heldout', 'v3'])
        for (final c
            in jsonDecode(File('tool/questions/$set.json').readAsStringSync())
                as List)
          _norm((c as Map)['q'] as String): '$set: ${c['q']}',
    };
    final hits = [
      for (final e in examples)
        if (questions[_norm(e)] case final q?) '$q  ⟵  "$e"',
    ];
    expect(
      hits,
      isEmpty,
      reason: '지시문 예시 ${examples.length}개 중 ${hits.length}개가 평가 문항이다',
    );
  });
}
