import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/stats.dart';

/// 실제 DeepSeek 평가(tool/remote_eval_test.dart)에서 본 모델 답을 앱이 한 뜻으로
/// 고쳐 읽는 자리. 뜻이 둘로 갈리는 것은 고치지 않는다 — 여기 것은 모두 읽을 수
/// 있는 뜻이 하나뿐이다.
void main() {
  setUpAll(() => initializeDateFormatting());
  const names = ['스쿼트', '벤치프레스', '데드리프트', '바벨로우', '푸시업', '랫풀다운'];
  const en = ['Squat', 'Bench Press', 'Deadlift', 'Overhead Press', 'Running'];
  final today = DateTime(2026, 9, 23);

  Map<String, Object?> ground(
    Map<String, Object?> plan,
    String q, [
    List<String> logged = names,
  ]) => groundedIntent(plan, q, logged, today: today);

  group('이름', () {
    test('구의 흔한 낱말(lift·row)은 운동 이름이 아니다 — 글을 바꾸지도, 지목하지도 않는다', () {
      const q = 'which lift is improving fastest';
      expect(canonicalizeExercises(q, en), q);
      expect(namedExercises(q, en), isEmpty);
      final plan = ground(
        {
          'by': 'exercise',
          'measures': ['changePct'],
          'order': 'desc',
          'limit': 1,
        },
        q,
        en,
      );
      expect(plan['by'], 'exercise');
      expect(plan.containsKey('exercises'), isFalse);
    });

    test('로마자 키는 낱말 속에서 찾지 않는다 — trung 의 run, over 의 overhead', () {
      expect(namedExercises('nên tập trung vào bài nào', ['Chạy Bộ']), isEmpty);
      expect(
        namedExercises('top 5 exercises over the last 3 months', en),
        isEmpty,
      );
      expect(namedExercises('bench press 최고', en), ['Bench Press']);
      expect(namedExercises('running 거리', en), ['Running']);
    });

    test('여러 낱말 사전 이름은 통째로 기록 이름이 된다 — 더 긴 이름의 앞부분이면 두지 않는다', () {
      const vi = ['Bench Press', 'Đẩy Ngực Dốc Lên', 'Squat'];
      expect(
        canonicalizeExercises('squat gấp mấy lần đẩy ngực', vi),
        'squat gấp mấy lần Bench Press',
      );
      // 인클라인은 목록에 있는 제 이름 그대로, 목록에 없어도 벤치로 바꾸지 않는다.
      expect(
        canonicalizeExercises('đẩy ngực dốc lên tháng này', vi),
        'Đẩy Ngực Dốc Lên tháng này',
      );
      expect(
        canonicalizeExercises('đẩy ngực dốc lên tháng này', ['Bench Press']),
        'đẩy ngực dốc lên tháng này',
      );
      // 낱말 한가운데서는 바꾸지 않는다.
      expect(canonicalizeExercises('đẩy ngựcx', ['Bench Press']), 'đẩy ngựcx');
    });

    test('모델 글자가 깨진 이름(�)은 기록 하나에만 맞으면 그 운동이다', () {
      expect(resolvedExercise('�시업', names), '푸시업');
    });
  });

  group('모양', () {
    test('응답 형식 되받기(type: json_object)와 입력 칸 이름(exerciseNames)을 걷어낸다', () {
      final q = decodeRecordIntent(
        {
          'type': 'json_object',
          'exerciseNames': ['벤치프레스'],
          'measures': ['best'],
        },
        '벤치 최고',
        names,
        unit: 'kg',
        today: today,
      );
      expect(q.kind, 'query');
      expect(q.series.single.scope.exercises, ['벤치프레스']);
    });

    test('빈 목록은 없는 것과 같다 — notComputable: [] 로 거절하지 않는다', () {
      final plan = ground({
        'notComputable': [],
        'measures': ['trainingDays'],
        'series': [
          {'together': true},
          {'together': false},
        ],
      }, '파트너랑 한 날 vs 혼자 한 날');
      expect(plan.containsKey('notComputable'), isFalse);
    });

    test('find 는 운동 이름뿐일 때다 — "데드 기록 보여줘" 는 그 운동의 plan', () {
      final plan = ground({
        'kind': 'find',
        'exercises': ['데드리프트'],
      }, '데드 기록 좀 보여줘');
      expect(plan.containsKey('kind'), isFalse);
      final q = decodeRecordIntent(
        {
          'kind': 'find',
          'exercises': ['데드리프트'],
        },
        '데드 기록 좀 보여줘',
        names,
        unit: 'kg',
        today: today,
      );
      expect(q.kind, 'query');
      final bare = decodeRecordIntent(
        {
          'kind': 'find',
          'exercises': ['스쿼트'],
        },
        '스쾃',
        names,
        unit: 'kg',
        today: today,
      );
      expect(bare.kind, 'find');
    });

    test('기록한 운동을 모두 적은 목록(9개부터)은 모든 운동이다 — 운동마다 한 줄', () {
      const logged = [...names, '레그프레스', '오버헤드프레스', '러닝'];
      final plan = ground(
        {
          'exercises': logged,
          'memo': ['폼 좋'],
          'measures': ['best'],
        },
        '메모에 폼 좋다고 쓴 날 최고',
        logged,
      );
      expect(plan.containsKey('exercises'), isFalse);
      expect(plan['by'], 'exercise');
    });
  });

  group('규칙 층', () {
    test('안 적은 운동의 "기록 없음" 은 notComputable 이 아니다 — 그 줄이 이미 말한다', () {
      final plan = ground({
        'exercises': ['벤치프레스', '힙쓰러스트'],
        'measures': ['best'],
        'notComputable': ['힙쓰러스트 기록 없음'],
      }, '벤치 vs 힙쓰러스트 최고');
      expect(plan.containsKey('notComputable'), isFalse);
      final kept = ground({
        'exercises': ['스쿼트'],
        'measures': ['best'],
        'notComputable': ['파트너 기록'],
      }, '파트너랑 나 스쿼트 누가 더 세');
      expect(kept['notComputable'], ['파트너 기록']);
      final pace = ground({
        'exercises': ['수영'],
        'measures': ['distance'],
        'notComputable': ['수영 페이스'],
      }, '수영 페이스 빨라졌어');
      expect(pace['notComputable'], ['수영 페이스']);
    });

    test('기준 수는 글에 적힌 수만 — null·0·지어낸 수는 뺀다', () {
      for (final value in [null, 0, 80]) {
        final plan = ground({
          'exercises': ['데드리프트'],
          'measures': ['best'],
          'against': {'value': value, 'unit': 'kg'},
        }, '체중 대비 데드 몇 배');
        expect(plan.containsKey('against'), isFalse, reason: '$value');
      }
      final kept = ground({
        'exercises': ['데드리프트'],
        'measures': ['best'],
        'against': {'value': 72, 'unit': 'kg'},
      }, '몸무게 72인데 데드 몇 배');
      expect(kept['against'], isNotNull);
    });

    test(
      '지어낸 메모로만 갈랐던 series 는 메모를 지우면 한 series 다 — 같은 series 둘로 거절하지 않는다',
      () {
        final plan = ground({
          'exercises': ['데드리프트'],
          'measures': ['best'],
          'series': [
            {
              'memo': ['부상'],
            },
            {
              'noMemo': ['부상'],
            },
          ],
        }, '다리 수술 전후 데드 비교');
        expect(plan.containsKey('series'), isFalse);
        expect(
          () => decodeRecordIntent(
            {
              'exercises': ['데드리프트'],
              'series': [
                {
                  'memo': ['부상'],
                },
                {
                  'noMemo': ['부상'],
                },
              ],
            },
            '다리 수술 전후 데드 비교',
            names,
            unit: 'kg',
            today: today,
          ),
          returnsNormally,
        );
      },
    );

    test('한 줄의 합계는 그 칸 자신이다 — "러닝 총 거리" 의 total 은 디코더가 뺀다', () {
      RecordQuery read(Map<String, Object?> plan, String q) =>
          decodeRecordIntent(plan, q, names, unit: 'kg', today: today);
      expect(
        read({
          'exercises': ['푸시업'],
          'period': 'thisMonth',
          'measures': ['repCount'],
          'total': 'sum',
        }, '이번달 푸시업 총 몇 개').total,
        isNull,
      );
      expect(
        read({
          'exercises': ['스쿼트', '벤치프레스', '데드리프트'],
          'measures': ['best'],
          'total': 'sum',
        }, '3대 합계').total,
        'sum',
      );
    });

    test('측정을 비웠으면 글이 가리키는 하나로 채우고, 모델이 적은 측정은 그 측정을 담았으면 둔다', () {
      expect(
        ground({
          'exercises': ['벤치프레스'],
          'period': 'thisWeek',
        }, '이번 주 벤치프레스 그래프')['measures'],
        ['weightChange'],
      );
      expect(
        ground({
          'exercises': ['벤치프레스'],
          'measures': ['trainingDays', 'setCount'],
        }, '벤치프레스 얼마나 자주 해')['measures'],
        ['trainingDays', 'setCount'],
      );
    });

    test('못 보는 말이 있으면 의도 낱말로 측정을 덮지 않는다 — "평균보다 센 편" 의 평균', () {
      expect(
        ground({
          'exercises': ['벤치프레스'],
          'measures': ['best'],
          'notComputable': ['한국 남자 평균'],
        }, '나 한국 남자 평균보다 벤치 센 편이야?')['measures'],
        ['best'],
      );
    });
  });

  // 실측 덤프(v3·v2·heldout 의 flash·pro 대답 여러 벌)에서 디코더가 거절하던 모양
  // 가운데 뜻이 하나뿐인 것. 거절하면 사람에게는 '읽지 못했어요' 뿐이다.
  group('한 뜻 고치기 — 실측에서 거절되던 모양', () {
    RecordQuery read(
      Map<String, Object?> raw, {
      String q = '',
      List<String> logged = names,
    }) => RecordQuery.decode(raw, logged, question: q, today: today);
    final l = lookupL(const Locale('ko'));
    LoggedSet set(double kg, int reps) =>
        LoggedSet(value: kg, unit: 'kg', reps: reps);
    Note day(String id, int m, int d, List<ExerciseBlock> blocks) {
      final at = DateTime(2026, m, d, 19);
      return Note(id: id, createdAt: at, updatedAt: at, blocks: blocks);
    }

    RecordResult run(Map<String, Object?> raw, List<Note> notes) => runPlan(
      RecordQuery.decode(raw, recordedExercises(notes), today: today),
      notes,
      l: l,
      unit: 'kg',
      today: today,
      confirmed: true,
    )!;

    test('응답 형식 껍데기 속 plan — 질문을 되받았거나 스키마 꼴이어도 맵이 하나면 그것', () {
      expect(
        ground({
          'type': 'json_object',
          'question': '3 ท่าที่เล่นบ่อยที่สุด',
          'response': {
            'by': 'exercise',
            'measures': ['trainingDays'],
            'order': 'desc',
            'limit': 3,
          },
        }, '3 ท่าที่เล่นบ่อยที่สุด'),
        {
          'by': 'exercise',
          'measures': ['trainingDays'],
          'order': 'desc',
          'limit': 3,
        },
      );
      final schema = ground({
        'type': 'json_object',
        'properties': {
          'timer': 'tabata',
          'period': 'thisMonth',
          'measures': ['trainingDays'],
        },
        'required': ['timer', 'period', 'measures'],
      }, 'ตาบาต้าเดือนนี้กี่ครั้ง');
      expect(schema, {
        'timer': 'tabata',
        'period': 'thisMonth',
        'measures': ['trainingDays'],
      });
      // plan 키가 곁에 있으면 어느 것이 plan 인지 모른다 — 벗기지 않는다.
      expect(
        () => read({
          'type': 'json_object',
          'by': 'exercise',
          'extra': {'by': 'day'},
        }),
        throwsFormatException,
      );
    });

    test('이름 칸 — exercise 하나, 되받은 nameHints, 이름 없는 find', () {
      expect(
        read({
          'kind': 'find',
          'exercise': '데드리프트',
        }, q: '데드 기록 좀 보여줘').scope.exercises,
        ['데드리프트'],
      );
      final echo = ground({
        'exercises': ['벤치프레스'],
        'nameHints': ['bench press'],
        'measures': ['setCount'],
      }, '이번 주 벤치 세트 수');
      expect(echo.containsKey('nameHints'), isFalse);
      expect(echo['exercises'], ['벤치프레스']);
      final empty = read({'kind': 'find'}, q: '데드리프트 기록 좀 보여줘');
      expect(empty.kind, 'query');
      expect(empty.scope.exercises, ['데드리프트']);
    });

    test('기간 칸 — custom 칸, all 에 붙은 날짜, 기간 이름 곁의 양끝 날짜, 0 과 음수 shift', () {
      final custom = read({
        'by': 'month',
        'measures': ['trainingDays'],
        'series': [
          {
            'custom': {'since': '2026-03-01', 'until': '2026-05-31'},
          },
          {
            'custom': {'since': '2026-06-01', 'until': '2026-08-31'},
          },
        ],
      });
      expect(custom.series.map((s) => s.scope.since), [
        DateTime(2026, 3, 1),
        DateTime(2026, 6, 1),
      ]);
      final before = read({
        'exercises': ['스쿼트'],
        'measures': ['setCount'],
        'series': [
          {'period': 'all', 'until': '2026-08-19'},
          {'period': 'custom', 'since': '2026-08-20'},
        ],
      });
      expect(before.series.first.scope.until, DateTime(2026, 8, 19));
      // "작년 12월보다 이번달" — 기간 이름 곁에 양끝 날짜를 적었으면 날짜가 기간이다.
      final december = read({
        'period': 'thisMonth',
        'measures': ['trainingDays'],
        'series': [
          {'period': 'lastYear', 'since': '2025-12-01', 'until': '2025-12-31'},
          <String, Object?>{},
        ],
      });
      expect(december.series.first.scope.since, DateTime(2025, 12, 1));
      expect(december.series.first.scope.until, DateTime(2025, 12, 31));
      // 한쪽 날짜만이면 이름이 다른 쪽 끝인지 모른다 — 두 뜻이라 거절된다.
      expect(
        () => read({
          'period': 'thisMonth',
          'until': '2026-09-05',
          'measures': ['trainingDays'],
        }),
        throwsFormatException,
      );
      // 날짜 범위를 기간 칸에 싸서 적었다.
      final july = read({
        'exercises': ['벤치프레스'],
        'period': {'since': '2026-07-01', 'until': '2026-07-31'},
      });
      expect(
        (july.scope.since, july.scope.until),
        (DateTime(2026, 7, 1), DateTime(2026, 7, 31)),
      );
      // "9월 14일부터 18일까지" — 시작날을 기간 칸에 적었다.
      final holiday = read({
        'period': '2026-09-14',
        'until': '2026-09-18',
        'measures': ['volume'],
      });
      expect(
        (holiday.scope.since, holiday.scope.until),
        (DateTime(2026, 9, 14), DateTime(2026, 9, 18)),
      );
      final zero = read({
        'exercises': ['데드리프트'],
        'period': 'lastMonth',
        'shift': {'months': 0, 'days': 0},
        'measures': ['latest'],
      });
      expect(zero.scope.since, DateTime(2026, 8, 1));
      // "연휴 전주랑 다음주" — 음수 shift 는 앞으로 민다.
      final around = read({
        'period': 'custom',
        'since': '2026-09-07',
        'until': '2026-09-11',
        'measures': ['volume'],
        'series': [
          {
            'shift': {'weeks': 1},
          },
          {
            'shift': {'weeks': -1},
          },
        ],
      });
      expect(around.series.map((s) => s.scope.since), [
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 14),
      ]);
    });

    test('series 가 이미 가른 묶음은 뺀다 — 해마다 두 해, 날마다 최장 연속, 평일·주말의 요일마다', () {
      expect(
        read({
          'by': 'year',
          'measures': ['trainingDays'],
          'series': [
            {'period': 'lastYear'},
            {'period': 'thisYear'},
          ],
        }).by,
        isNull,
      );
      expect(
        () => read({
          'by': 'year',
          'measures': ['trainingDays'],
        }),
        throwsFormatException,
      );
      expect(
        read({
          'measures': ['longestStreak'],
          'by': 'day',
        }).by,
        isNull,
      );
      expect(
        () => read({
          'measures': ['longestStreak'],
          'by': 'week',
        }),
        throwsA(isA<QueryLimit>()),
      );
      expect(
        read({
          'by': 'weekday',
          'measures': ['trainingDays'],
          'series': [
            {
              'weekdays': [1, 2, 3, 4, 5],
            },
            {
              'weekdays': [6, 7],
            },
          ],
        }).by,
        isNull,
      );
      // 주말 안에서 요일마다는 series 가 가른 것이 아니다 — 둔다.
      expect(
        read({
          'by': 'weekday',
          'measures': ['trainingDays'],
          'weekdays': [6, 7],
        }).by,
        'weekday',
      );
    });

    test(
      '되받아 적은 것 — unrelated: false, total: true, 뺄 이름을 운동 칸에도, 윗단에 다시 적은 series 조건, 수 없는 기준, minReps',
      () {
        expect(
          read({
            'exercises': ['데드리프트'],
            'measures': ['best'],
            'against': {'unit': 'kg'},
          }).against,
          isNull,
        );
        // "한달에 평균 몇 키로씩" — 달마다 묶고 달당으로 나눈 추이는 속도 하나다.
        final rate = read({
          'exercises': ['벤치프레스'],
          'by': 'month',
          'per': 'month',
          'measures': ['weightChange'],
        });
        expect((rate.by, rate.per), (null, null));
        final five = read({
          'exercises': ['벤치프레스'],
          'measures': ['volume'],
          'minReps': 5,
        });
        expect(five.scope.reps.single.op, '>=');
        expect(
          read({
            'unrelated': false,
            'exercises': ['스쿼트'],
            'measures': ['best'],
          }).names.keys,
          ['스쿼트'],
        );
        expect(
          read({
            'exercises': ['스쿼트', '벤치프레스'],
            'measures': ['best'],
            'total': true,
          }).total,
          'sum',
        );
        final heaviest = read({
          'exercises': ['벤치프레스'],
          'exclude': ['벤치프레스'],
          'by': 'exercise',
          'measures': ['best'],
          'order': 'desc',
          'limit': 1,
        });
        expect(heaviest.scope.exercises, isEmpty);
        expect(heaviest.exclude, ['벤치프레스']);
        // "80kg 이상 또는 10회 이상" — 윗단에 다시 적으면 두 series 가 같아진다.
        final either = read({
          'weight': {'op': '>=', 'value': 80, 'unit': 'kg'},
          'reps': {'op': '>=', 'value': 10},
          'measures': ['setCount'],
          'series': [
            {
              'weight': {'op': '>=', 'value': 80, 'unit': 'kg'},
            },
            {
              'reps': {'op': '>=', 'value': 10},
            },
          ],
        });
        expect(either.series.map((s) => s.scope.reps.length), [0, 1]);
        expect(either.series.map((s) => s.scope.weight.length), [1, 0]);
        // 윗단 조건이 모두에 걸려도 series 가 서로 다르면 뜻이 있다 — 둔다.
        final both = read({
          'weight': {'op': '>=', 'value': 80, 'unit': 'kg'},
          'measures': ['setCount'],
          'series': [
            {
              'weight': {'op': '>=', 'value': 80, 'unit': 'kg'},
              'period': 'lastMonth',
            },
            {'period': 'thisMonth'},
          ],
        });
        expect(both.series.map((s) => s.scope.weight.length), [1, 1]);
      },
    );

    test('이름 없이 조건끼리 무게만 견주면 운동마다다 — 서로 다른 운동의 무게를 한 수로 섞지 않는다', () {
      Map<String, Object?> hours(int from, int to) => {
        'hours': {'from': from, 'to': to},
      };
      expect(
        read({
          'measures': ['best'],
          'series': [hours(5, 11), hours(17, 23)],
        }).by,
        'exercise',
      );
      // 이름·부위를 적었거나 무게 아닌 측정이 섞이면 섞은 수가 뜻이 있다 — 둔다.
      for (final raw in [
        {
          'exercises': ['스쿼트'],
          'measures': ['best'],
          'series': [hours(5, 11), hours(17, 23)],
        },
        {
          'measures': ['best'],
          'series': [
            {'part': 'legs'},
            {'part': 'chest'},
          ],
        },
        {
          'measures': ['best', 'trainingDays'],
          'series': [hours(5, 11), hours(17, 23)],
        },
      ]) {
        expect(read(raw).by, isNull, reason: '$raw');
      }
    });

    test('이름 하나의 순위는 그 한 줄이고, 운동별 비중 하나는 전체 대비다', () {
      final one = read({
        'exercises': ['스쿼트'],
        'by': 'exercise',
        'measures': ['best'],
        'order': 'desc',
        'limit': 1,
      });
      expect((one.by, one.order, one.limit), (null, null, null));
      final share = read({
        'measures': ['volume'],
        'by': 'exercise',
        'relate': 'share',
        'exercises': ['스쿼트'],
      });
      expect((share.relate, share.by), ('ratio', null));
      expect(share.series.last.scope.exercises, ['스쿼트']);
    });

    test('기록 이름을 모두 늘어놓은 목록 — 모든 운동, 하나 빠지면 뺀 운동, 모르는 이름이 섞이면 한도', () {
      const logged = [...names, '레그프레스', '오버헤드프레스', '풀업', '레그컬'];
      final all = read({
        'exercises': logged,
        'measures': ['best'],
      }, logged: logged);
      expect(all.by, 'exercise');
      expect(all.exclude, isEmpty);
      final other = read({
        'exercises': [
          for (final n in logged)
            if (n != '벤치프레스') n,
        ],
        'measures': ['best'],
        'order': 'desc',
        'limit': 1,
      }, logged: logged);
      expect(other.by, 'exercise');
      expect(other.exclude, ['벤치프레스']);
      expect(
        () => read({
          'exercises': [...logged.take(8), '케틀벨 스윙'],
        }, logged: logged),
        throwsA(isA<QueryLimit>().having((e) => e.kind, 'kind', 'exercises')),
      );
      final pooled = read({
        'measures': ['best'],
        'series': [
          {'exercises': logged},
          {
            'exercises': ['스쿼트'],
          },
        ],
      }, logged: logged);
      expect(pooled.series.first.scope.exercises, isEmpty);
    });

    test('측정은 한 줄에 넷까지 — 표의 칸 한도와 같다', () {
      expect(
        read({
          'exercises': ['벤치프레스'],
          'measures': [
            'best',
            'weightChange',
            'daysSinceBest',
            'sessionsSinceBest',
          ],
        }).measures,
        hasLength(4),
      );
      expect(
        () => read({
          'exercises': ['벤치프레스'],
          'measures': [
            'best',
            'weightChange',
            'daysSinceBest',
            'sessionsSinceBest',
            'latest',
          ],
        }),
        throwsA(isA<QueryLimit>().having((e) => e.kind, 'kind', 'measures')),
      );
    });

    test('주별로 측정 여럿은 칸이 측정인 표다', () {
      final notes = [
        day('a', 9, 1, [
          ExerciseBlock('스쿼트', [set(100, 5), set(100, 5)]),
        ]),
        day('b', 9, 8, [
          ExerciseBlock('스쿼트', [set(110, 5)]),
        ]),
      ];
      final r = run({
        'by': 'week',
        'period': 'thisMonth',
        'measures': ['volume', 'setCount'],
      }, notes);
      expect(r.render, 'table');
      expect(r.columns, [
        metricLabel(l, Metric.volume),
        metricLabel(l, Metric.sets),
      ]);
      expect(r.rows.first.cells.map((c) => c.answer?.numericValue), [1000, 2]);
      expect(r.rows[1].cells.map((c) => c.answer?.numericValue), [550, 1]);
    });

    test('운동한 날(trained: true)은 운동 기록의 거름이 아니고, 쉰 날에는 운동 기록이 없다', () {
      final notes = [
        day('a', 9, 1, [
          ExerciseBlock('스쿼트', [set(100, 5)]),
        ]),
        day('b', 9, 8, [
          ExerciseBlock('스쿼트', [set(110, 5)]),
        ]),
      ];
      final r = run({
        'exercises': ['스쿼트'],
        'measures': ['trainingDays'],
        'series': [
          {'trained': true},
          {'trained': false},
        ],
      }, notes);
      expect(r.rows.map((row) => row.cells.first.answer?.numericValue), [2, 0]);
    });

    test('날당 평균(per)을 적은 한 줄의 total mean 은 그 칸이다 — per 없는 평균은 모른다', () {
      expect(
        read({
          'measures': ['intake'],
          'period': 'thisWeek',
          'total': 'mean',
          'per': 'day',
        }).total,
        isNull,
      );
      expect(
        () => read({
          'measures': ['trainingDays'],
          'total': 'mean',
        }),
        throwsFormatException,
      );
    });

    test('이름을 적은 줄은 순위가 있어도 모두 보인다 — 적은 적 없는 쪽도', () {
      final q = read({
        'exercises': ['벤치프레스', '케틀벨 스윙'],
        'measures': ['best'],
        'by': 'exercise',
        'order': 'desc',
        'limit': 1,
      });
      expect((q.order, q.limit), ('desc', null));
      expect(q.series, hasLength(2));
    });

    test('못 보는 것은 80자까지 — 말이 긴 언어의 한 구절', () {
      expect(
        read({
          'measures': ['intake'],
          'notComputable': ['calorías de días de descanso no registradas'],
        }).notComputable,
        hasLength(1),
      );
    });
  });

  // 규칙 층이 남긴 것: 모두 글에 **하나뿐인** 뜻이다(지어낸 것 빼기, 떨어뜨린 것
  // 채우기, 뜻이 하나인 낱말과 어긋난 것 바로잡기).
  group('규칙 층 — 한 뜻만', () {
    test('못 보는 것이 이미 \'적은 적 없음\' 줄이면 디코드한 plan 에도 없다', () {
      final q = decodeRecordIntent(
        {
          'exercises': ['벤치프레스', '힙쓰러스트'],
          'measures': ['best'],
          'notComputable': ['힙쓰러스트 기록'],
        },
        '벤치 vs 힙쓰러스트 최고',
        names,
        unit: 'kg',
        today: today,
      );
      expect(q.notComputable, isEmpty);
      expect(q.never, isNotEmpty);
    });

    test('이상·이하는 그 수의 쪽과 경계를 정하고, 다른 종류의 수로 적은 조건은 뺀다', () {
      final reps = ground({
        'exercises': ['벤치프레스'],
        'measures': ['setCount'],
        'weight': {'op': '>=', 'value': 5, 'unit': 'kg'},
      }, '이번 주 벤치 몇 번 했지 5회 이상');
      expect(reps['reps'], {'op': '>=', 'value': 5});
      expect(reps.containsKey('weight'), isFalse);
      // 뺀 조건은 확인 줄이 말한다.
      final l = lookupL(const Locale('ko'));
      expect(
        describePlan(
          decodeRecordIntent(
            {
              'exercises': ['벤치프레스'],
              'measures': ['setCount'],
              'weight': {'op': '>=', 'value': 7, 'unit': 'kg'},
            },
            '벤치 몇 세트 했어 5회 이상',
            names,
            unit: 'kg',
            today: today,
          ),
          l,
          'kg',
        ),
        contains(l.queryBoundDropped('7')),
      );
      final op = ground({
        'exercises': ['벤치프레스'],
        'measures': ['setCount'],
        'weight': {'op': '>', 'value': 80, 'unit': 'kg'},
      }, '벤치 80kg 이상 세트 수');
      expect(op['weight'], {'op': '>=', 'value': 80, 'unit': 'kg'});
      // 글이 읽지 못한 조건('60 넘는')은 모델 것 그대로다 — 무게 단위가 없다고
      // 지우지 않는다.
      final kept = ground({
        'exercises': ['벤치프레스'],
        'measures': ['setCount'],
        'weight': {'op': '>', 'value': 60, 'unit': 'kg'},
      }, '벤치 60 넘는 세트 5회 이상');
      expect(kept['weight'], {'op': '>', 'value': 60, 'unit': 'kg'});
      expect(kept['reps'], {'op': '>=', 'value': 5});
    });

    test('연도 없이 적은 달을 모델이 다른 해로 적으면 해만 글을 따른다 — 견주는 글이어도', () {
      final g = ground({
        'exercises': ['스쿼트'],
        'measures': ['best'],
        'period': 'custom',
        'since': '2025-09-01',
        'until': '2025-09-30',
      }, '9월보다 스쿼트 늘었어?');
      expect((g['since'], g['until']), ('2026-09-01', '2026-09-30'));
      final stated = ground({
        'exercises': ['스쿼트'],
        'measures': ['best'],
        'period': 'custom',
        'since': '2025-09-01',
        'until': '2025-09-30',
      }, '2025년 9월 스쿼트 최고');
      expect(stated['since'], '2025-09-01');
    });

    test('기간을 떨어뜨렸으면 채우고, "요즘 어때" 는 기간이 아니다', () {
      expect(
        ground({
          'exercises': ['스쿼트'],
        }, '지난달 스쿼트 요즘 어때')['period'],
        'lastMonth',
      );
      expect(
        ground({
          'exercises': ['스쿼트'],
          'measures': ['weightChange'],
        }, '요즘 스쿼트 지난달보다 늘었어').containsKey('period'),
        isFalse,
      );
    });
  });
}
