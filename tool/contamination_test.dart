import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 지시문 예시(`"…" => {…}` 줄)가 평가 문항과 같으면 그 문항은 답을 베껴
/// 맞힌다 — 점수가 부푼다(v2 지시문 예시 27개 중 15개가 v2.json 문항과 같았다).
/// 지시문이 어느 파일에 있든 lib/ 의 예시 줄을 모두 모아 v2·dev·heldout·v3·final
/// 의 모든 질문과 견준다. 대소문자·띄어쓰기·문장부호는 무시한다.
///
/// 완전 일치만 보면 틀이 같은 예시('레그프레스 요즘 제자리야?' ↔ '…정체기인가')를
/// 놓친다. 떼어 둔 최종 모음(final.json)은 더 엄격하다: 글자 두 개씩 묶음의 겹침
/// (자카드)이 지시문 예시와 0.3 미만, 조정용 모음(v2·dev·heldout·v3)과 0.5 미만.
///
///     flutter test tool/contamination_test.dart
String _norm(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[\s\p{P}\p{S}]+', unicode: true), '');

/// 두 글의 글자 두 개씩 묶음 겹침(0–1).
double _overlap(String a, String b) {
  Set<String> grams(String s) {
    final t = _norm(s);
    return {for (var i = 0; i + 1 < t.length; i++) t.substring(i, i + 2)};
  }

  final x = grams(a), y = grams(b);
  final union = x.union(y).length;
  return union == 0 ? 0 : x.intersection(y).length / union;
}

List<String> _questions(String set) => [
  for (final c
      in jsonDecode(File('tool/questions/$set.json').readAsStringSync())
          as List)
    (c as Map)['q'] as String,
];

Set<String> _examples() => {
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
    if (f.path.endsWith('.dart'))
      for (final m in RegExp(
        r'^"(.+?)" =>',
        multiLine: true,
      ).allMatches(f.readAsStringSync()))
        m[1]!,
};

void main() {
  test('떼어 둔 최종 모음은 지시문 예시·조정용 모음과 글꼴도 닮지 않는다', () {
    final examples = _examples();
    final tuning = [
      for (final set in const ['v2', 'dev', 'heldout', 'v3'])
        ..._questions(set),
    ];
    final close = [
      for (final q in _questions('final')) ...[
        for (final e in examples)
          if (_overlap(q, e) >= 0.3) '$q ≈ 예시 "$e"',
        for (final t in tuning)
          if (_overlap(q, t) >= 0.5) '$q ≈ 조정용 "$t"',
      ],
    ];
    expect(close, isEmpty);
  });

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
      for (final set in ['v2', 'dev', 'heldout', 'v3', 'final'])
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
