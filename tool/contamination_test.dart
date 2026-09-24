import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'outcome_grading.dart';

/// 지시문 예시(`"…" => {…}` 줄)가 평가 문항과 같으면 그 문항은 답을 베껴
/// 맞힌다 — 점수가 부푼다(v2 지시문 예시 27개 중 15개가 v2.json 문항과 같았다).
/// 지시문이 어느 파일에 있든 lib/ 의 예시 줄을 모두 모아 v2·dev·heldout·v3·final
/// 의 모든 질문과 견준다. 대소문자·띄어쓰기·문장부호는 무시한다.
///
/// 완전 일치만 보면 틀이 같은 예시('레그프레스 요즘 제자리야?' ↔ '…정체기인가')를
/// 놓친다. 떼어 둔 모음(final.json, blind.json)은 더 엄격하다: 글자 두 개씩 묶음의
/// 겹침(자카드)이 지시문 예시와 0.3 미만, 조정용 모음과 0.5 미만. blind 는 final 도
/// 조정용으로 본다(final 은 두 번 재고 그 뒤 지시문을 고쳤다).
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
  for (final (held, tuningSets) in const [
    ('final', ['v2', 'dev', 'heldout', 'v3']),
    ('blind', ['v2', 'dev', 'heldout', 'v3', 'final']),
  ]) {
    test('떼어 둔 $held 모음은 지시문 예시·조정용 모음과 글꼴도 닮지 않는다', () {
      final examples = _examples();
      final tuning = [for (final set in tuningSets) ..._questions(set)];
      final close = [
        for (final q in _questions(held)) ...[
          for (final e in examples)
            if (_overlap(q, e) >= 0.3) '$q ≈ 예시 "$e"',
          for (final t in tuning)
            if (_overlap(q, t) >= 0.5) '$q ≈ 조정용 "$t"',
        ],
      ];
      expect(close, isEmpty);
    });
  }

  // 재검토: 예시 '운동 전반 요약해줘' 의 plan 이 v2 '종합' 정답 9개와 같은 모양
  // ({by: exercise, measures: [trainingDays, best, latest], order: desc})이었다 — 글은
  // 달라도 정답의 관례(order desc)를 지시문이 가르쳤다. 예시의 plan 은 어느 평가
  // 정답 대안과도 같지 않다(그 문항이 안 보는 키를 빼고 견줘도).
  test('지시문 예시의 plan 은 평가 정답 대안과 같지 않다', () {
    Object? canon(Object? x) => switch (x) {
      final Map m => {
        for (final k in (m.keys.map((k) => '$k').toList()..sort()))
          k: canon(m[k]),
      },
      final List l => [for (final e in l) canon(e)],
      final num n => n.toDouble(),
      _ => x,
    };
    String key(Object? plan, [Iterable<Object?> ignore = const []]) =>
        jsonEncode(
          canon(
            plan is Map
                ? {
                    for (final e in plan.entries)
                      if (!ignore.contains(e.key)) e.key: e.value,
                  }
                : plan,
          ),
        );
    final plans = <String, String>{
      for (final f in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart'))
          for (final m in RegExp(
            r'^"(.+?)" => (\{.*\})$',
            multiLine: true,
          ).allMatches(f.readAsStringSync()))
            m[1]!: m[2]!,
    };
    expect(plans, isNotEmpty);
    final hits = <String>{};
    for (final set in ['v2', 'heldout', 'v3', 'final', 'blind']) {
      for (final c in evalCases(set)) {
        for (final g in c.gold) {
          for (final MapEntry(key: q, value: raw) in plans.entries) {
            final plan = jsonDecode(raw);
            if (key(plan) == key(g) ||
                (c.ignore.isNotEmpty &&
                    key(plan, c.ignore) == key(g, c.ignore))) {
              hits.add('"$q" ⟵ $set: ${c.q}');
            }
          }
        }
      }
    }
    for (final h in hits) {
      // ignore: avoid_print
      print('  $h');
    }
    expect(hits, isEmpty);
  });

  test('루틴 지시문 예시는 루틴 평가 문항과 같지 않고, 떼어 둔 루틴 모음과는 글꼴도 닮지 않는다', () {
    List<String> texts(String set) => [
      for (final c
          in jsonDecode(File('tool/questions/$set.json').readAsStringSync())
              as List)
        (c as Map)['text'] as String,
    ];
    final examples = _examples();
    final corpus = [...texts('routine'), ...texts('routine_heldout')];
    final same = [
      for (final e in examples)
        for (final t in corpus)
          if (_norm(e) == _norm(t) ||
              (_norm(t).length >= 6 &&
                  (_norm(e).contains(_norm(t)) || _norm(t).contains(_norm(e)))))
            '$t  ⟵  "$e"',
    ];
    // 글꼴 닮음은 루틴 지시문(lib/routine.dart) 예시만 본다 — 떼어 둔 닮은 질문
    // "최근 루틴 기록 쭉 보여줘" 는 기록 검색 예시 "스쿼트 기록 쭉 보여줘" 와 닮았다
    // (그 문항은 가르기·루틴 지시문 평가용이고, 기록 검색 지시문의 점수에 쓰지 않는다).
    final routineExamples = {
      for (final m in RegExp(
        r'^"(.+?)" =>',
        multiLine: true,
      ).allMatches(File('lib/routine.dart').readAsStringSync()))
        m[1]!,
    };
    expect(routineExamples, hasLength(greaterThan(20)));
    final close = [
      for (final t in texts('routine_heldout'))
        for (final e in routineExamples)
          if (_overlap(t, e) >= 0.3) '$t ≈ 예시 "$e"',
    ];
    expect(same, isEmpty);
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
      for (final set in ['v2', 'dev', 'heldout', 'v3', 'final', 'blind'])
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
