import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/exercises.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/stats.dart';

class _Records extends NotesStore {
  _Records(this.records);
  final List<Note> records;
  @override
  List<Note> get notes => records;
}

/// 검색 v3 재검토(v3 review)의 결함을 하나씩 못 박는다. 테스트 이름의 R 번호가 그
/// 검토의 발견 순서다. 규칙 층(_ground)이 모델의 맞는 plan 을 덮어쓰지 않는지,
/// 합계·조건·이름이 조용히 틀리지 않는지, 디코더 거절이 막다른 길이 아닌지.
/// 오늘은 2026-09-24(목) 21시, 단위는 kg.
void main() {
  setUpAll(() => initializeDateFormatting());
  final l = lookupL(const Locale('ko'));
  final today = DateTime(2026, 9, 24, 21);
  LoggedSet s(double? v, int? r, {String u = 'kg', String? memo}) => LoggedSet(
    value: v,
    unit: u,
    reps: r,
    notes: memo == null ? null : [memo],
  );
  Note n(String id, int m, int d, List<ExerciseBlock> b, {int y = 2026}) {
    final at = DateTime(y, m, d, 19);
    return Note(id: id, createdAt: at, updatedAt: at, blocks: b);
  }

  RecordQuery decode(
    Map<String, Object?> raw,
    List<Note> notes, {
    String question = '',
    DateTime? at,
  }) => RecordQuery.decode(
    raw,
    recordedExercises(notes),
    today: at ?? today,
    question: question,
  );
  RecordResult run(
    Map<String, Object?> raw,
    List<Note> notes, {
    String question = '',
    DateTime? at,
  }) => runPlan(
    decode(raw, notes, question: question, at: at),
    notes,
    l: l,
    unit: 'kg',
    today: at ?? today,
    confirmed: true,
  )!;

  group('R1 규칙 4 — 비교를 한 기간으로 접지 않는다', () {
    final rows = [
      n('a', 9, 20, [
        ExerciseBlock('바벨로우', [s(80, 5)]),
      ]),
      n('b', 9, 24, [
        ExerciseBlock('바벨로우', [s(85, 5)]),
      ]),
    ];
    test('오늘 vs 지난번(nth) 에 오늘을 윗단 기간으로 붙이지 않는다', () {
      const q = '오늘 로우 지난번보다 나아졌나';
      final raw = {
        'exercises': ['바벨로우'],
        'measures': ['best'],
        'series': [
          {'nth': 2},
          {'nth': 1},
        ],
      };
      expect(
        groundedIntent(raw, q, recordedExercises(rows), today: today),
        isNot(contains('period')),
      );
      final r = run(raw, rows, question: q);
      expect(
        [for (final row in r.rows) row.cells.single.answer?.numericValue],
        [80, 85],
      );
      expect(r.lines.single, contains('+5kg'));
    });

    test('"그 뒤로"·"전후" 의 전·후 series 는 그 달 하나로 접지 않는다', () {
      final names = ['벤치프레스', '스쿼트'];
      for (final (q, raw) in [
        (
          '5월에 이사했는데 그 뒤로 운동 횟수 줄었어?',
          {
            'measures': ['trainingDays'],
            'series': [
              {'until': '2026-04-30'},
              {'since': '2026-05-01'},
            ],
          },
        ),
        (
          '지난주 월요일 전후 스쿼트',
          {
            'exercises': ['스쿼트'],
            'series': [
              {'until': '2026-09-13'},
              {'since': '2026-09-14'},
            ],
          },
        ),
      ]) {
        final g = groundedIntent(raw, q, names, today: today);
        expect(g['series'], raw['series'], reason: q);
        expect(g, isNot(contains('period')), reason: q);
        expect(g['measures'], raw['measures'], reason: q);
      }
    });
  });

  group('R2 규칙 6 — 모델이 낸 측정을 다른 갈래로 바꾸지 않는다', () {
    final rows = [
      n('a', 9, 1, [
        ExerciseBlock('벤치프레스', [s(100, 5)]),
      ]),
      n('b', 9, 10, [
        ExerciseBlock('스쿼트', [s(120, 5)]),
      ]),
    ];
    test('"운동 횟수 줄었어?" 의 운동일수는 무게 추이가 되지 않는다', () {
      const q = '이번달 운동 횟수 줄었어?';
      final raw = {
        'measures': ['trainingDays'],
        'period': 'thisMonth',
      };
      expect(
        groundedIntent(
          raw,
          q,
          recordedExercises(rows),
          today: today,
        )['measures'],
        ['trainingDays'],
      );
      final r = run(raw, rows, question: q);
      expect(r.rows.single.cells.single.answer!.numericValue, 2);
    });

    test('측정을 비웠으면 글의 한 갈래로 채운다', () {
      expect(
        groundedIntent(
          {
            'exercises': ['벤치프레스'],
          },
          '벤치 세트 몇 개 했어',
          recordedExercises(rows),
          today: today,
        )['measures'],
        ['setCount'],
      );
    });

    test('이름 없는 무게 측정은 운동을 섞지 않고 운동별로 편다', () {
      final r = run(
        {
          'measures': ['weightChange'],
          'period': 'thisMonth',
        },
        rows,
        question: '이번달 무게 늘었어?',
      );
      expect(r.rows.map((row) => row.label).toSet(), {'벤치프레스', '스쿼트'});
      expect(r.footnotes, isNot(contains(l.queryMixedWeights)));
    });
  });

  group('R3 기록 이름의 열쇠는 사전 퍼지로 다른 운동에 붙지 않는다', () {
    test('오타 한 자 거리(백↔핵, rows↔rowing)는 같은 운동이 아니다', () {
      expect(exerciseKey('핵스쿼트'), '핵스쿼트');
      expect(exerciseKey('백스쿼트'), isNot('핵스쿼트'));
      expect(exerciseKey('Back Squat'), isNot('핵스쿼트'));
      expect(exerciseKey('rows'), isNot('로잉'));
      // 줄임말(앞부분)과 별칭은 그대로 잇는다.
      expect(exerciseKey('벤치'), '벤치프레스');
      expect(exerciseKey('데드'), '데드리프트');
      expect(exerciseKey('스쾃'), '스쿼트');
      // 백스쿼트·바벨 스쿼트는 스쿼트다(사전 별칭).
      expect(exerciseKey('백스쿼트'), '스쿼트');
      expect(exerciseKey('Back Squat'), '스쿼트');
      expect(exerciseKey('바벨 스쿼트'), '스쿼트');
      // '벤트오버' 는 로우일 수도, 레터럴 레이즈일 수도 있다 — 제 이름이다.
      expect(exerciseKey('벤트오버'), '벤트오버');
    });

    test('백스쿼트와 핵스쿼트를 둘 다 적었으면 두 줄이다', () {
      final rows = [
        n('a', 9, 1, [
          ExerciseBlock('백스쿼트', [s(140, 3)]),
          ExerciseBlock('핵스쿼트', [s(200, 8)]),
        ]),
      ];
      final r = run(
        {
          'exercises': ['백스쿼트', '핵스쿼트'],
          'measures': ['best'],
        },
        rows,
        question: '백스쿼트 vs 핵스쿼트 최고',
      );
      expect(
        [for (final row in r.rows) row.cells.first.answer?.numericValue],
        [140, 200],
      );
    });
  });

  group('R4·R13 합계 — 빠진 줄은 적고, 단위는 맞춰 더한다', () {
    final sb = [
      n('a', 9, 1, [
        ExerciseBlock('스쿼트', [s(140, 3)]),
        ExerciseBlock('벤치프레스', [s(100, 3)]),
      ]),
    ];
    final raw = {
      'exercises': ['스쿼트', '벤치프레스', '데드리프트'],
      'measures': ['best'],
      'total': 'sum',
    };
    test('안 적은 데드리프트는 합계에서 뺐다고 칸이 말한다', () {
      final r = run(raw, sb, question: '3대 합계');
      final total = r.total!.first;
      expect(total.answer!.numericValue, 240);
      expect(total.excluded, {'데드리프트'});
      expect(total.answer!.exercise, contains(l.queryPartial('데드리프트')));
    });

    test('기준 수는 부분합이라고 적힌 합으로 견준다', () {
      final r = run(
        {
          ...raw,
          'against': {'value': 500, 'unit': 'kg'},
        },
        sb,
        question: '3대 500 넘었어?',
      );
      expect(
        r.lines.where((x) => x.contains('500kg')).single,
        contains(l.queryPartial('데드리프트')),
      );
    });

    test('이번 달에 안 한 데드리프트도 뺐다고 말한다', () {
      final r = run(
        {...raw, 'period': 'thisMonth'},
        [
          ...sb,
          n('b', 8, 1, [
            ExerciseBlock('데드리프트', [s(180, 3)]),
          ]),
        ],
        question: '이번달 3대 합계',
      );
      expect(r.total!.first.excluded, {'데드리프트'});
    });

    test('개수형 합계의 0 은 빠진 것이 아니다', () {
      final r = run(
        {
          'exercises': ['스쿼트', '데드리프트'],
          'measures': ['trainingDays'],
          'total': 'sum',
        },
        sb,
        question: '스쿼트랑 데드 합쳐 며칠',
      );
      expect(r.total!.first.excluded, isEmpty);
      expect(r.total!.first.answer!.numericValue, 1);
    });

    test('km 와 m 는 km 로 맞춰 더한다', () {
      final r = run(
        {
          'exercises': ['러닝', '사이클'],
          'measures': ['distance'],
          'total': 'sum',
        },
        [
          n('a', 9, 1, [
            ExerciseBlock('러닝', [s(8, null, u: 'km')]),
            ExerciseBlock('사이클', [s(20000, null, u: 'm')]),
          ]),
        ],
        question: '러닝이랑 사이클 거리 합쳐서',
      );
      expect(r.total!.first.answer!.numericValue, 28);
      expect(r.total!.first.answer!.headline, '28km');
    });
  });

  group('R5 서버가 답했는데 디코더가 거절한 것은 연결 문제가 아니다', () {
    final bench = [
      n('a', 8, 4, [
        ExerciseBlock('벤치프레스', [s(80, 5)]),
      ]),
      n('b', 9, 7, [
        ExerciseBlock('벤치프레스', [s(85, 5)]),
      ]),
    ];
    test('추이 + 달당은 달당 줄이 있는 추이 하나다', () {
      final q = decode(
        {
          'exercises': ['벤치프레스'],
          'measures': ['weightChange'],
          'per': 'month',
        },
        bench,
        question: '한달에 평균 몇키로씩 늘고 있어 벤치',
      );
      expect(q.per, isNull);
      expect(q.measures, [Metric.trend]);
    });

    test('셀 수 없는 조합은 한도(까닭)로 거절한다', () {
      for (final (kind, question, raw) in [
        (
          'perMeasure',
          '벤치 주당 최고',
          {
            'exercises': ['벤치프레스'],
            'measures': ['best'],
            'per': 'week',
          },
        ),
        (
          'shareMeasure',
          '운동별 최고 무게 비중',
          {
            'measures': ['best'],
            'by': 'exercise',
            'relate': 'share',
          },
        ),
        (
          'trainedMeasure',
          '운동한 날 벤치 최고',
          {
            'exercises': ['벤치프레스'],
            'measures': ['best'],
            'trained': true,
          },
        ),
        (
          'sameSeries',
          '',
          {
            'exercises': ['벤치프레스'],
            'series': [{}, {}],
          },
        ),
      ]) {
        expect(
          () => decode(raw, bench, question: question),
          throwsA(isA<QueryLimit>().having((e) => e.kind, 'kind', kind)),
          reason: kind,
        );
        expect(l.queryLimit(kind), isNot(l.queryLimit('other')), reason: kind);
      }
    });

    Future<void> pump(WidgetTester tester, RecordAi ai) async {
      final store = _Records(bench);
      addTearDown(store.dispose);
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: NotesListPage(store: store, onOpen: (_) {}, ai: ai),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> ask(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(CupertinoSearchTextField), text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    testWidgets('모양 실수는 "읽지 못했어요" 이고 담아 둬 Enter 로 원판을 또 쓰지 않는다', (
      tester,
    ) async {
      var asked = 0;
      await pump(
        tester,
        RecordAi(
          respond: (i, _) async {
            // 1단계(갈래 고르기)는 세지 않는다 — 질문 하나에 plan 한 번.
            if (i == familyInstructions) return {'t': <String>[]};
            asked++;
            return {
              'exercises': ['벤치프레스'],
              'series': [
                {
                  'reps': {'>=': 5},
                },
              ],
            };
          },
        ),
      );
      const q = '지난달 벤치 얼마나 자주 해 5회 이상?';
      await ask(tester, q);
      expect(asked, 1);
      expect(find.text(l.queryFailed), findsNothing);
      expect(find.text(l.queryOfflineLocal), findsNothing);
      expect(find.textContaining(l.queryMisreadLocal), findsOneWidget);
      await ask(tester, q);
      await ask(tester, q);
      expect(asked, 1);
    });

    testWidgets('빈 답(응답 형식만 되받음)은 담지 않는다 — 다시 누르면 다시 묻는다', (tester) async {
      var asked = 0;
      await pump(
        tester,
        RecordAi(
          respond: (i, _) async {
            // 1단계(갈래 고르기)는 세지 않는다 — 질문 하나에 plan 한 번.
            if (i == familyInstructions) return {'t': <String>[]};
            asked++;
            return asked == 1
                ? {'type': 'json_object'}
                : {
                    'exercises': ['벤치프레스'],
                    'measures': ['best'],
                  };
          },
        ),
      );
      const q = '벤치 최고 얼마야';
      // 글에 운동이 있으면 기기에서 센 줄과 함께다 — 둘 다 '읽지 못' 을 말한다.
      final misread = find.textContaining('셀 수 있는 모양으로 읽지 못');
      await ask(tester, q);
      expect(misread, findsOneWidget);
      await ask(tester, q);
      expect(asked, 2);
      expect(misread, findsNothing);
    });

    testWidgets('글에 운동이 없어도 까닭을 말한다', (tester) async {
      await pump(
        tester,
        RecordAi(respond: (_, _) async => {'measures': 'best'}),
      );
      await ask(tester, '요즘 어때');
      expect(find.text(l.queryMisread), findsOneWidget);
      expect(find.text(l.queryFailed), findsNothing);
    });
  });

  group('R6 규칙 1 — 상태 메모 조건을 지우지 않고, 지우면 말한다', () {
    final names = seedNames('ko');
    test('글에 그 상태 낱말이 있으면 메모 조건이다', () {
      for (final (q, raw) in [
        (
          '컨디션 별로였던 날 스쿼트 어땠어',
          {
            'exercises': ['스쿼트'],
            'series': [
              {
                'memo': ['컨디션 안 좋'],
              },
              {
                'noMemo': ['컨디션 안 좋'],
              },
            ],
          },
        ),
        (
          '허리 아팠던 날 데드 몇 번',
          {
            'exercises': ['데드리프트'],
            'measures': ['trainingDays'],
            'memo': ['허리 아프'],
          },
        ),
        (
          'knee pain days squat',
          {
            'exercises': ['스쿼트'],
            'memo': ['knee pain'],
          },
        ),
      ]) {
        expect(groundedIntent(raw, q, names, today: today), raw, reason: q);
      }
    });

    test('날짜 모르는 일의 전후를 메모로 가르면 빼고, 뺐다고 말한다', () {
      final rows = [
        n('a', 9, 1, [
          ExerciseBlock('데드리프트', [s(150, 3)]),
        ]),
      ];
      const q = '부상 전후로 데드 무게 비교';
      final raw = {
        'exercises': ['데드리프트'],
        'series': [
          {
            'memo': ['부상'],
          },
          {
            'noMemo': ['부상'],
          },
        ],
      };
      expect(groundedIntent(raw, q, names, today: today), {
        'exercises': ['데드리프트'],
      });
      final plan = decode(raw, rows, question: q);
      expect(
        describePlan(plan, l, 'kg', notes: rows),
        contains(l.queryMemoDropped('부상')),
      );
    });

    test('의도 낱말("그래프")은 메모가 아니다', () {
      final g = groundedIntent(
        {
          'exercises': ['벤치프레스'],
          'memo': ['그래프'],
        },
        '벤치 그래프 보여줘',
        names,
        today: today,
      );
      expect(g, isNot(contains('memo')));
    });
  });

  test('R7 규칙 2·3 — 글의 낱말을 퍼지로 운동 이름에 붙이지 않는다', () {
    final vi = seedNames('vi');
    const q = 'nhìn chung việc tập của tôi thế nào?';
    expect(groundedIntent({'by': 'exercise'}, q, vi, today: today), {
      'by': 'exercise',
    });
  });

  testWidgets('R7 서버에 닿지 못해 기기에서 셀 때도 퍼지로 잡힌 운동은 세지 않는다', (tester) async {
    RecordAi.forget();
    addTearDown(RecordAi.forget);
    final store = _Records([
      n('a', 9, 1, [
        ExerciseBlock('Chùng Chân', [s(20, 10)]),
      ]),
    ]);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: NotesListPage(
          store: store,
          onOpen: (_) {},
          ai: RecordAi(
            endpoint: 'https://example.test',
            deviceId: 'device',
            client: MockClient((_) async => throw http.ClientException('off')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(CupertinoSearchTextField),
      'nhìn chung việc tập của tôi thế nào?',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text(l.queryOfflineLocal), findsNothing);
    expect(find.text(l.queryOffline), findsOneWidget);
  });

  group('R8 무게 하한 조건 — 맨몸 세트는 조건을 못 채운 세트다', () {
    final rows = [
      n('a', 9, 1, [
        ExerciseBlock('스쿼트', [s(null, 15), s(110, 3)]),
      ]),
      n('b', 9, 3, [
        ExerciseBlock('스쿼트', [s(120, 3)]),
      ]),
      n('c', 9, 5, [
        ExerciseBlock('스쿼트', [s(80, 5)]),
      ]),
    ];
    Map<String, Object?> raw(String m) => {
      'exercises': ['스쿼트'],
      'measures': [m],
      'weight': {'op': '>', 'value': 100, 'unit': 'kg'},
    };
    test('운동일수·세트 수는 2 이고, 뺀 맨몸 세트를 적는다', () {
      final days = run(
        raw('trainingDays'),
        rows,
        question: '100kg 넘는 스쿼트 한 날 며칠',
      );
      expect(days.rows.single.cells.single.answer!.numericValue, 2);
      expect(days.footnotes, contains(l.queryNoWeightSets(1, 15)));
      final sets = run(raw('setCount'), rows, question: '100kg 넘는 스쿼트 세트 몇 개');
      expect(sets.rows.single.cells.single.answer!.numericValue, 2);
    });

    test('가장 오래 쉰 기간도 조건을 지난 날로 센다', () {
      final gap = run(
        raw('longestGap'),
        rows,
        question: '100kg 넘는 스쿼트 가장 오래 쉰 기간',
      );
      final a = gap.rows.single.cells.single.answer!;
      expect(a.numericValue, 21);
    });
  });

  test('R11 사전에서 온 "혹시 ○○?" 는 칩(기록으로 다시 세기)이 아니라 글이다', () {
    final rows = [
      n('a', 9, 1, [
        ExerciseBlock('벤치프레스', [s(100, 5)]),
      ]),
    ];
    final q = decode(
      {
        'exercises': ['바밸로우'],
        'measures': ['trainingDays'],
      },
      rows,
      question: '바밸로우 몇번 했어',
    );
    expect(q.never, {'바밸로우'});
    expect(q.maybe['바밸로우'] ?? const <String>[], isNot(contains('바벨로우')));
    expect(
      describePlan(q, l, 'kg', notes: rows),
      contains(l.queryMaybe('바벨로우')),
    );
  });

  group('R12 기준 수 — 배수는 무게가 아니고, 버리면 말한다', () {
    final rows = [
      n('a', 9, 1, [
        ExerciseBlock('데드리프트', [s(150, 3)]),
      ]),
    ];
    test('"2배" 의 2 는 기준 무게가 아니다', () {
      final q = decode(
        {
          'exercises': ['데드리프트'],
          'measures': ['best'],
          'against': {'value': 2},
        },
        rows,
        question: '체중 80인데 데드 2배 넘었어?',
      );
      expect(q.against, isNull);
      expect(
        describePlan(q, l, 'kg', notes: rows),
        contains(l.queryAgainstDropped('2')),
      );
    });

    test('글에 없는 수는 버리고 말한다', () {
      final q = decode(
        {
          'exercises': ['데드리프트'],
          'measures': ['best'],
          'against': {'value': 80},
        },
        rows,
        question: '체중 팔십인데 데드 두 배 넘었어?',
      );
      expect(q.against, isNull);
      expect(
        describePlan(q, l, 'kg', notes: rows),
        contains(l.queryAgainstDropped('80')),
      );
    });

    test('글에 적힌 체중은 기준 수다', () {
      final q = decode(
        {
          'exercises': ['데드리프트'],
          'measures': ['best'],
          'against': {'value': 80, 'unit': 'kg'},
        },
        rows,
        question: '체중 80인데 데드 2배 넘었어?',
      );
      expect(q.against, (value: 80.0, unit: 'kg'));
    });
  });

  group('R14 연도 없는 앞날 기간', () {
    final rows = [
      n('a', 11, 5, y: 2025, [
        ExerciseBlock('스쿼트', [s(100, 5)]),
      ]),
      n('b', 12, 5, y: 2025, [
        ExerciseBlock('스쿼트', [s(110, 5)]),
      ]),
    ];
    final feb = DateTime(2026, 2, 10, 12);
    final raw = {
      'exercises': ['스쿼트'],
      'measures': ['setCount'],
      'series': [
        {'since': '2026-11-01', 'until': '2026-11-30'},
        {'since': '2026-12-01', 'until': '2026-12-31'},
      ],
    };
    test('"1000" 같은 네 자리 수는 연도가 아니다 — 작년으로 당긴다', () {
      final r = run(
        raw,
        rows,
        question: '11월이랑 12월 볼륨 1000 넘은 스쿼트 세트',
        at: feb,
      );
      expect(
        [for (final row in r.rows) row.cells.single.answer?.numericValue],
        [1, 1],
      );
    });

    test('두 칸이 다 아직 안 온 기간이면 차이 줄이 없다', () {
      final r = run(raw, rows, question: '2026년 11월이랑 12월 스쿼트 세트', at: feb);
      expect(r.rows.map((row) => row.cells.single.reason), [
        'future',
        'future',
      ]);
      expect(r.lines, isEmpty);
    });
  });
}
