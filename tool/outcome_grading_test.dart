import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/record_query.dart';

import 'outcome_grading.dart';
import 'question_grading.dart';

/// 결과 채점기(outcome_grading.dart) 자체 검사 — 네트워크 없음.
///
///     flutter test --no-pub tool/outcome_grading_test.dart
void main() {
  setUpAll(() => initializeDateFormatting());
  const sets = ['v3', 'v2', 'heldout', 'final', 'blind'];

  test('가정한 기록은 사람이 친 이름 그대로이고, 줄마다 값이 다를 만큼 넓다', () {
    final lists = {
      for (final s in sets)
        for (final c in evalCases(s))
          '${c.lang}\n${c.names.join('\n')}': (c.names, c.lang),
    };
    for (final (names, lang) in lists.values) {
      final log = assumedLog(names, lang);
      expect(
        recordedExercises(log).toSet(),
        names.toSet(),
        reason: '기록한 운동 = 모델에 간 이름 ($names)',
      );
    }
    final ko = evalCases('v3').first.names;
    final log = assumedLog(ko);
    final sets0 = [
      for (final n in log)
        for (final b in n.blocks) ...b.sets,
    ];
    expect(log.any((n) => n.partner?.partnerName != null), isTrue);
    expect(log.any((n) => n.handoffToken != null), isTrue);
    expect(log.any((n) => n.routineId != null), isTrue);
    expect(sets0.any((s) => s.author != null), isTrue, reason: '파트너 세트');
    for (final u in ['kg', 'lb', 'km', 'min', 's']) {
      expect(sets0.any((s) => s.unit == u), isTrue, reason: u);
    }
    expect(sets0.any((s) => s.value == null && s.reps != null), isTrue);
    expect(sets0.any((s) => s.notes.isNotEmpty), isTrue);
    expect(log.any((n) => n.blocks.isEmpty && n.meals.isNotEmpty), isTrue);
    expect(log.any((n) => n.calories != null), isTrue);
    final days = {
      for (final n in log)
        if (n.blocks.isNotEmpty)
          DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day),
    };
    expect(days, contains(DateTime(2026, 9, 9)), reason: '오늘 한 운동');
    expect(days, containsAll([DateTime(2026, 9, 7), DateTime(2026, 9, 8)]));
    expect(days, isNot(contains(DateTime(2026, 9, 6))));
    expect(days.first.isBefore(DateTime(2025, 8, 1)), isTrue, reason: '작년 이맘때');
  });

  // 한국어 기록 이름 목록(v3 의 158문항이 쓰는 것).
  final ko = evalCases('v3').first.names;
  OutcomeGrade judge(
    Object gold,
    Object? model, {
    List<Object?> ignore = const [],
  }) {
    final log = assumedLog(ko);
    Visible? got;
    try {
      got = visible(
        decodeRecordIntent(model, '', ko, unit: 'kg', today: evalToday),
        log,
        evalL('ko'),
      );
    } on FormatException {
      got = null;
    }
    return gradeOutcome(
      [goldVisible(gold, ko, 'ko', log)],
      got,
      ignore: ignore,
    );
  }

  group('모양이 달라도 사람에게 같은 답이면 맞다', () {
    final same = <String, (Object, Object)>{
      '지난달 = 8/1–8/31': (
        {
          'exercises': ['벤치프레스'],
          'period': 'lastMonth',
          'measures': ['best'],
        },
        {
          'exercises': ['벤치'],
          'period': 'custom',
          'since': '2026-08-01',
          'until': '2026-08-31',
          'measures': ['best'],
        },
      ),
      '끝에서 두 번 = 마지막 두 운동일을 날별로': (
        {
          'exercises': ['스쿼트'],
          'measures': ['volume'],
          'series': [
            {'nth': 2},
            {'nth': 1},
          ],
        },
        {
          'exercises': ['스쿼트'],
          'measures': ['volume'],
          'sessions': 2,
          'by': 'day',
        },
      ),
      '칸을 더 보여도 된다': (
        {
          'exercises': ['벤치프레스'],
          'measures': ['best'],
        },
        {
          'exercises': ['벤치프레스'],
          'measures': ['best', 'e1rm', 'trainingDays'],
        },
      ),
      '운동 둘 = 운동별 묶음': (
        {
          'exercises': ['벤치프레스', '스쿼트'],
          'measures': ['best'],
        },
        {
          'by': 'exercise',
          'exercises': ['스쿼트', '벤치프레스'],
          'measures': ['best'],
        },
      ),
      '글에서 옮긴 어간과 정답 어간이 같은 날을 고른다': (
        {
          'exercises': ['스쿼트'],
          'measures': ['trainingDays', 'volume'],
          'series': [
            {
              'memo': ['잠'],
            },
            {
              'noMemo': ['잠'],
            },
          ],
        },
        {
          'exercises': ['스쿼트'],
          'measures': ['trainingDays', 'volume'],
          'series': [
            {
              'noMemo': ['잠 못잤'],
            },
            {
              'memo': ['잠 못잤'],
            },
          ],
        },
      ),
      '아침 5–11시 = 6–11시(경계에 운동이 없다)': (
        {
          'hours': {'from': 5, 'to': 11},
          'measures': ['trainingDays'],
        },
        {
          'hours': {'from': 6, 'to': 11},
          'measures': ['trainingDays'],
        },
      ),
    };
    for (final MapEntry(key: name, value: (gold, model)) in same.entries) {
      test(name, () {
        final g = judge(gold, model);
        expect(g.errors, isEmpty, reason: '정답 ${g.want} · 모델 ${g.got}');
        expect(outcomeVerdicts(g), contains('exact'));
      });
    }
  });

  group('사람에게 다른 답은 잡는다', () {
    final wrong = <String, (Object, Object?, String, String)>{
      '다른 기간 → 틀린 숫자': (
        {
          'exercises': ['벤치프레스'],
          'period': 'lastMonth',
          'measures': ['volume'],
        },
        {
          'exercises': ['벤치프레스'],
          'period': 'thisMonth',
          'measures': ['volume'],
        },
        'values',
        'confidentlyWrong',
      ),
      '정답의 측정이 빠짐': (
        {
          'exercises': ['벤치프레스'],
          'measures': ['best', 'trainingDays'],
        },
        {
          'exercises': ['벤치프레스'],
          'measures': ['best'],
        },
        'measures',
        'confidentlyWrong',
      ),
      '비율의 기준이 뒤바뀜': (
        {
          'exercises': ['벤치프레스', '스쿼트'],
          'measures': ['best'],
          'relate': 'ratio',
        },
        {
          'exercises': ['스쿼트', '벤치프레스'],
          'measures': ['best'],
          'relate': 'ratio',
        },
        'relate',
        'confidentlyWrong',
      ),
      '셀 수 있는데 되묻기 → 막다른 길': (
        {
          'exercises': ['벤치프레스'],
          'measures': ['best'],
        },
        {'kind': 'clarify'},
        'kind',
        'deadEnd',
      ),
      '앱이 받지 못한 답 → 막다른 길': (
        {
          'exercises': ['벤치프레스'],
          'measures': ['best'],
        },
        {
          'by': 'week',
          'measures': ['best', 'volume'],
        },
        'invalid',
        'deadEnd',
      ),
      '안 적은 운동 대신 기록 운동 → 바꿔치기': (
        {
          'exercises': ['힙쓰러스트'],
          'measures': ['best'],
        },
        {
          'exercises': ['레그프레스'],
          'measures': ['best'],
        },
        'rows',
        'swapped',
      ),
      '못 보는 것 줄이 빠짐': (
        {
          'exercises': ['벤치프레스'],
          'measures': ['best'],
          'notComputable': ['체중'],
        },
        {
          'exercises': ['벤치프레스'],
          'measures': ['best'],
        },
        'notComputable',
        'ncMissed',
      ),
      '순위 방향이 반대': (
        {
          'by': 'exercise',
          'measures': ['trainingDays'],
          'order': 'desc',
          'limit': 3,
        },
        {
          'by': 'exercise',
          'measures': ['trainingDays'],
          'order': 'asc',
          'limit': 3,
        },
        'rows',
        'confidentlyWrong',
      ),
      '적힌 말을 다른 말로 바꾼 메모 어간': (
        {
          'measures': ['volume'],
          'memo': ['컨디션 별로'],
        },
        {
          'measures': ['volume'],
          'memo': ['컨디션 안 좋'],
        },
        'values',
        'confidentlyWrong',
      ),
      '같이 한 날 대신 메모': (
        {
          'exercises': ['스쿼트'],
          'measures': ['best'],
          'together': true,
        },
        {
          'exercises': ['스쿼트'],
          'measures': ['best'],
          'memo': ['같이'],
        },
        'reasons',
        'confidentlyWrong',
      ),
    };
    for (final MapEntry(key: name, value: (gold, model, error, flag))
        in wrong.entries) {
      test(name, () {
        final g = judge(gold, model);
        expect(g.errors, contains(error), reason: '정답 ${g.want} · 모델 ${g.got}');
        expect(outcomeVerdicts(g), contains(flag));
        expect(outcomeVerdicts(g), isNot(contains('exact')));
      });
    }
  });

  for (final set in sets) {
    test('$set: 정답 대안은 모두 앱에서 돌고, 자기 자신과 같은 답이다', () {
      var alternatives = 0, distinct = 0;
      final broken = <String>[];
      for (final c in evalCases(set)) {
        final log = assumedLog(c.names, c.lang);
        final wants = <Visible>[];
        for (final g in c.gold) {
          try {
            wants.add(goldVisible(g, c.names, c.lang, log));
          } on StateError catch (e) {
            broken.add('${c.q}: ${e.message}');
          }
        }
        alternatives += wants.length;
        distinct += {for (final w in wants) '$w'}.length;
        for (final w in wants) {
          expect(
            gradeOutcome(wants, w, ignore: c.ignore).errors,
            isEmpty,
            reason: c.q,
          );
        }
      }
      // ignore: avoid_print
      print(
        '$set: 정답 대안 $alternatives개 → 보이는 답 $distinct가지 · 안 도는 정답 ${broken.length}',
      );
      for (final b in broken) {
        // ignore: avoid_print
        print('  $b');
      }
      expect(broken, isEmpty);
    });
  }
}
