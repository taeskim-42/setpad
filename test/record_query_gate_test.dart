import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/exercises.dart';
import 'package:setpad/record_query.dart';
import '../tool/question_grading.dart';

/// 모델 없는 게이트.
///
/// 규칙 층("글에 또렷이 적힌 것은 코드가 읽는다")이 무엇을 약속하는지를
/// 생성된 문장 전부에 대고 몇 초 만에 검사한다. 모델 출력은 **일부러 최악**
/// 으로 흉내 낸다 — 메모 조건을 지어내고, 측정을 틀리고, 기간과 조건을
/// 떨어뜨리고, 사용자 철자를 그대로 돌려준다. 채점은 v1 정답을 v2 모양으로
/// 바꿔(v2Expected) 뜻 전체를 견준다. 실제 모델이 그렇게 냈던
/// 날이 있었다(dev 에서 11건 회귀). 이 게이트는 그런 회귀를 시뮬레이터
/// 없이 커밋 전에 잡는다.
///
/// 이것은 규칙 층의 계약이지 모델 정확도가 아니다. 오타와 초성은 모델
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

  /// 모델이 낼 법한 최악의 출력 넷. 코드 층은 넷 모두에서 정답으로 돌아와야 한다.
  List<Map<String, Object?>> worst(String question, String form) => [
    // 1. 잡담에 이끌려 메모 조건을 아무 낱말로 채웠고, 측정은 틀렸다.
    {
      'exercises': [form],
      'memo': [question.split(' ').last],
      'measures': ['trainingDays'],
    },
    // 2. 측정을 틀렸다(전부 세트 수로), 기간과 조건은 떨어뜨렸다.
    {
      'exercises': [form],
      'measures': ['setCount'],
    },
    // 3. 운동 하나를 지목한 순위로 냈다.
    {
      'exercises': [form],
      'by': 'exercise',
      'measures': ['trainingDays'],
      'limit': 1,
    },
    // 4. 운동 없는 순위로 냈다 — 실제 모델이 "정체기인가·늘고 있나·PR" 에
    //    가장 자주 내던 모양이다. 글에 운동이 하나 있으면 순위가 아니다.
    {
      'by': 'exercise',
      'measures': ['trainingDays'],
      'limit': 1,
    },
  ];

  for (final set in ['dev', 'heldout']) {
    test('규칙 층은 최악의 모델 출력을 정답으로 돌린다 — $set', () {
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
        for (final (i, intent) in worst(q, exp['form'] as String).indexed) {
          graded++;
          List<String> errors;
          try {
            errors =
                gradeRecordQuery(
                  RecordQuery.decode(intent, names, question: q, today: today),
                  exp,
                  names,
                ) ??
                ['ungraded'];
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

  test('채점기 — 운동은 집합, 비교는 순서, 메모는 정답 어간, 대안은 하나만', () {
    RecordQuery read(Map<String, Object?> m) =>
        RecordQuery.decode(m, names, today: evalToday);
    List<String> grade(
      Map<String, Object?> got,
      List<Object?> gold, {
      List<String> ignore = const [],
    }) => gradeQuery(read(got), gold, names, ignore: ignore);
    expect(
      grade(
        {
          'exercises': ['바벨로우', '벤치프레스'],
        },
        [
          {
            'exercises': ['벤치프레스', '바벨로우'],
          },
        ],
      ),
      isEmpty,
    );
    final months = [
      {'period': 'lastMonth'},
      {'period': 'thisMonth'},
    ];
    expect(
      grade(
        {
          'measures': ['volume'],
          'compare': months.reversed.toList(),
        },
        [
          {
            'measures': ['volume'],
            'compare': months,
          },
        ],
      ),
      ['compare'],
    );
    final shoulder = {
      'memo': ['어깨'],
      'measures': ['trainingDays'],
    };
    expect(
      grade(
        {
          'memo': ['어깨', '통증'],
          'measures': ['trainingDays'],
        },
        [shoulder],
      ),
      isEmpty,
    );
    expect(
      grade(
        {
          'memo': ['통증'],
          'measures': ['trainingDays'],
        },
        [shoulder],
      ),
      ['memo'],
    );
    final days = {
      'by': 'exercise',
      'measures': ['daysSince'],
      'order': 'desc',
    };
    expect(grade({...days, 'limit': 3}, [days], ignore: ['limit']), isEmpty);
    expect(grade({...days, 'limit': 3}, [days]), ['limit']);
    expect(
      grade(
        {'kind': 'clarify'},
        [
          {'kind': 'unrelated'},
          {'kind': 'clarify'},
        ],
      ),
      isEmpty,
    );
    // "넘게" 는 > 다. 이상(>=)은 틀림이다.
    expect(
      grade(
        {
          'exercises': ['데드리프트'],
          'weight': {'op': '>=', 'value': 100, 'unit': 'kg'},
        },
        [
          {
            'exercises': ['데드리프트'],
            'weight': {'op': '>', 'value': 100, 'unit': 'kg'},
          },
        ],
      ),
      ['weight'],
    );
  });

  test('v2 질문 모음 — 정답은 풀리고, 맞게 낸 모델 답은 규칙 층을 지난다', () {
    final cases = load('v2');
    final count = <String, int>{};
    final broken = <String>[];
    for (final c in cases) {
      final lang = c['lang'] as String, q = c['q'] as String;
      final names = seedNames(lang), gold = c['gold'] as List;
      count['$lang ${c['cat']}'] = (count['$lang ${c['cat']}'] ?? 0) + 1;
      // 정답마다 디코드되고 제 자신과 맞는다.
      for (final g in gold) {
        final read = RecordQuery.decode(g, names, today: evalToday);
        expect(gradeQuery(read, [g], names), isEmpty, reason: '$q $g');
      }
      // 모델이 첫 정답을 그대로 냈다면, 글을 읽는 규칙 층이 그것을 망치면
      // 안 된다 — 최악 출력 게이트의 반대쪽이다.
      final errors = gradeQuery(
        decodeRecordIntent(gold.first, q, names, unit: 'kg', today: evalToday),
        gold,
        names,
        ignore: (c['ignore'] as List?) ?? const [],
      );
      if (errors.isNotEmpty) broken.add('$lang $q');
    }
    // 알려진 것: 베트남어 "nhìn chung"(전체적으로)의 chung 이 퍼지로
    // Chùng Chân(런지)에 닿아 순위가 운동 하나로 접힌다(parser namedExercises).
    expect(broken, ['vi nhìn chung việc tập của tôi thế nào?']);
    final cats = {for (final c in cases) c['cat']};
    for (final lang in [
      'ko',
      'en',
      'ja',
      'zh_Hans',
      'zh_Hant',
      'es',
      'vi',
      'th',
    ]) {
      for (final cat in cats) {
        final n = count['$lang $cat'] ?? 0;
        expect(
          n,
          lang == 'ko' ? greaterThanOrEqualTo(5) : 3,
          reason: '$lang $cat',
        );
      }
    }
    // v1 모음의 v2 정답(두 운동, 초과)도 풀린다.
    for (final set in ['dev', 'heldout']) {
      for (final c in load(set)) {
        final gold = v2Expected((c['expected'] as Map).cast<String, Object?>());
        for (final g in gold ?? const []) {
          final read = RecordQuery.decode(g, names, today: evalToday);
          expect(gradeQuery(read, [g], names), isEmpty, reason: '${c['q']}');
        }
      }
    }
  });
}
