import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/editor.dart' show LoggedSet;
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

    // 둘째 기록: 최고는 작년 가을, 데드리프트는 100kg 앞뒤, 오늘은 여느 날.
    final second = assumedLog(ko, 'ko', true);
    List<LoggedSet> of(String name, bool Function(DateTime) when) => [
      for (final n in second)
        if (when(n.createdAt))
          for (final b in n.blocks)
            if (b.name == name) ...b.sets.where((s) => s.author == null),
    ];
    double best(String name, bool Function(DateTime) when) => of(
      name,
      when,
    ).map((s) => s.value ?? 0).fold(0.0, (a, b) => a > b ? a : b);
    final squat = ko.firstWhere((n) => exerciseKey(n) == '스쿼트');
    final dead = ko.firstWhere((n) => exerciseKey(n) == '데드리프트');
    bool always(DateTime _) => true;
    bool thisYear(DateTime d) => d.year == 2026;
    bool august(DateTime d) => d.year == 2026 && d.month == 8;
    expect(best(squat, thisYear), lessThan(best(squat, always)));
    expect(best(squat, august), lessThan(best(squat, thisYear)));
    final deadWeights = of(dead, always).map((s) => s.value!).toList();
    expect(deadWeights.any((w) => w > 100), isTrue);
    expect(
      of(dead, august).map((s) => s.value!).every((w) => w < 100),
      isTrue,
      reason: '요즘 데드는 100kg 아래',
    );
    final today = [
      for (final n in second)
        if (n.createdAt.isAfter(DateTime(2026, 9, 9))) ...n.blocks,
    ];
    expect(today.length, lessThan(8), reason: '오늘은 여느 날');
  });

  // 재검토(rv_mutation): 정답 plan 의 뜻을 바꾼 plan 이 '정확' 으로 채점되던 수.
  // 한 기록에서는 heldout 기간 지움 62/256 · 기간 옮김 80/256 · 조건 지움 39/107,
  // v2 조건 지움 8/26 이었다. 두 기록에서 모두 같아야 정확이다(heldout 28 · 34 ·
  // 31, v2 조건 지움 0) — 그 수가 이 문턱을 넘으면 채점기가 기간·조건 회귀를
  // 다시 못 잡는 것이다. 모음 셋에 1분쯤 걸린다.
  group('뜻을 바꾼 정답은 정확이 아니다', () {
    const periodKeys = {'period', 'days', 'since', 'until', 'shift'};
    const condKeys = {
      'weight',
      'reps',
      'weekdays',
      'hours',
      'set',
      'memo',
      'memoAll',
      'noMemo',
      'together',
      'routine',
      'handoff',
      'timer',
      'trained',
    };
    String? back(Object? d, int days) => d is String
        ? DateTime.parse(
            d,
          ).subtract(Duration(days: days)).toIso8601String().substring(0, 10)
        : null;
    Map<String, Object?>? mutate(Object? gold, String kind) {
      if (gold is! Map) return null;
      final m = (jsonDecode(jsonEncode(gold)) as Map).cast<String, Object?>();
      var changed = false;
      for (final x in [
        m,
        if (m['series'] case final List l) ...l.whereType<Map>(),
      ]) {
        switch (kind) {
          case 'dropPeriod' || 'dropCond':
            for (final k in kind == 'dropPeriod' ? periodKeys : condKeys) {
              if (x.remove(k) != null) changed = true;
            }
          case 'movePeriod':
            const swap = {
              'thisMonth': 'lastMonth',
              'lastMonth': 'thisMonth',
              'thisWeek': 'lastWeek',
              'lastWeek': 'thisWeek',
              'thisYear': 'lastYear',
              'lastYear': 'thisYear',
              'today': 'yesterday',
              'yesterday': 'today',
            };
            // 한 기간만 옮긴다 — 두 series 의 기간을 다 맞바꾸면 같은 두 줄이다.
            if (changed) break;
            if (swap[x['period']] case final p?) {
              x['period'] = p;
              changed = true;
            } else if (x['period'] == 'recent') {
              x['days'] = ((x['days'] as num?) ?? 28) * 2;
              changed = true;
            } else if (x['since'] case final String s) {
              x['since'] = back(s, 60);
              changed = true;
            } else if (x['until'] case final String u) {
              x['until'] = back(u, 60);
              changed = true;
            }
          case 'bestToE1rm':
            if (x['measures'] case final List ms when ms.contains('best')) {
              x['measures'] = [for (final y in ms) y == 'best' ? 'e1rm' : y];
              changed = true;
            }
        }
      }
      return changed ? m : null;
    }

    const kinds = ['dropPeriod', 'movePeriod', 'dropCond', 'bestToE1rm'];
    // 두 기록에서 잰 수(2026-09-24)가 문턱이다. 늘면 실패한다.
    // 남은 것은 두 기록 모두에서 답이 같은 것이다: 요즘 데드는 늘 80kg 위(첫째)거나
    // 요즘 기록이 없다(둘째), 60kg 이상 8회 이상인 푸시업 세트는 어디에도 없다,
    // e1rm 과 최고가 같은 줄(1회 세트)이다.
    const ceiling = {
      'v3': {'dropPeriod': 1, 'movePeriod': 4, 'dropCond': 2, 'bestToE1rm': 11},
      'v2': {'dropPeriod': 0, 'movePeriod': 0, 'dropCond': 0, 'bestToE1rm': 1},
      'heldout': {
        'dropPeriod': 28,
        'movePeriod': 34,
        'dropCond': 31,
        'bestToE1rm': 0,
      },
    };
    for (final set in ceiling.keys) {
      test(set, () {
        final tried = <String, int>{}, accepted = <String, int>{};
        final seen = <String>[];
        for (final c in evalCases(set)) {
          final golds = {for (final g in c.gold) jsonEncode(g)};
          try {
            if (gradeCase(c, null).want.kind != 'answer') continue;
          } on StateError {
            continue;
          }
          for (final k in kinds) {
            final mut = mutate(c.gold.first, k);
            if (mut == null || golds.contains(jsonEncode(mut))) continue;
            final RecordQuery q;
            try {
              q = decodeRecordIntent(
                mut,
                '',
                c.names,
                unit: 'kg',
                today: evalToday,
                locale: c.lang.replaceAll('_', '-'),
              );
            } on FormatException {
              continue;
            }
            tried[k] = (tried[k] ?? 0) + 1;
            if (gradeCase(c, q).errors.isEmpty) {
              accepted[k] = (accepted[k] ?? 0) + 1;
              seen.add('[$k] ${c.q} → ${jsonEncode(mut)}');
            }
          }
        }
        // ignore: avoid_print
        print(
          '$set: ${[for (final k in kinds) '$k ${accepted[k] ?? 0}/${tried[k] ?? 0}'].join(' · ')}',
        );
        for (final e in seen.take(12)) {
          // ignore: avoid_print
          print('  $e');
        }
        expect({
          for (final k in kinds)
            if ((accepted[k] ?? 0) > ceiling[set]![k]!) k: accepted[k],
        }, isEmpty);
      });
    }
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
          'measures': ['weightChange'],
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
        for (final (i, log) in assumedLogs(c.names, c.lang).indexed) {
          final wants = <Visible>[];
          for (final g in c.gold) {
            try {
              wants.add(goldVisible(g, c.names, c.lang, log));
            } on StateError catch (e) {
              broken.add('${c.q}: ${e.message}');
            }
          }
          if (i == 0) {
            alternatives += wants.length;
            distinct += {for (final w in wants) '$w'}.length;
          }
          for (final w in wants) {
            expect(
              gradeOutcome(wants, w, ignore: c.ignore).errors,
              isEmpty,
              reason: c.q,
            );
          }
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
