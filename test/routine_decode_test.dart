import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/record_query.dart' show recordedExercises;
import 'package:setpad/routine.dart';

import 'routine_fixture.dart';

/// 루틴 요청 디코더(설계 §5.5 + 검토 G2·G3·G5·G20).
void main() {
  final recorded = recordedExercises(defaultLog());
  RoutineAsk decode(Object? raw, String text) =>
      decodeRoutineAsk(raw, text, recorded, today: routineToday);
  List<String> codes(RoutineAsk a) => [for (final l in a.dropped) l.code];

  group('모양 — 통째로 던지는 것은 모양 문제뿐(G5)', () {
    test('객체가 아님·2000자 초과·모르는 윗단 키', () {
      expect(() => decode('[1]', 'x'), throwsFormatException);
      expect(() => decode('not json', 'x'), throwsFormatException);
      expect(
        () => decode({
          'exercises': List.filled(8, 'x' * 40),
          'notComputable': ['y' * 2000],
        }, 'x'),
        throwsFormatException,
      );
      expect(() => decode({'series': []}, 'x'), throwsFormatException);
    });

    test('from 의 키를 윗단에 적은 것은 from 으로, 윗단 part 는 parts 로', () {
      final a = decode({'from': {}, 'together': true}, '민수랑 했던 거 그대로');
      expect(a.from, {'together': true});
      expect(decode({'together': true}, '친구랑 같이 한 거').from, {'together': true});
      expect(
        decode({
          'part': ['full'],
        }, '전신').parts,
        ['full'],
      );
      expect(
        decode({
          'type': 'json_object',
          'parts': ['legs'],
        }, '하체').parts,
        ['legs'],
      );
    });

    test('검토#2 응답 형식만 되받아 적은 답은 읽지 못함이다', () {
      expect(
        () => decode({'type': 'json_object'}, '스쿼트 말고 하체 짜줘'),
        throwsFormatException,
      );
      // 빈 요청({}) 은 "내 기록으로 오늘" 이지만, 빼기·아픈 곳 글에 {} 면 조건을 버린 것이다.
      expect(() => decode({}, '허리 아파서 데드 빼고 짜줘'), throwsFormatException);
      expect(decode({}, '오늘 할 운동 좀 정해줘').keys, isEmpty);
    });

    test('코드 울타리는 벗긴다', () {
      final a = decode('```json\n{"parts":["legs"]}\n```', '하체');
      expect(a.parts, ['legs']);
    });

    test('question 은 다른 키가 있어도 기록 질문 칩이다', () {
      expect(decode({'kind': 'question'}, '벤치 몇 키로 했지').question, isTrue);
    });
  });

  group('값 하나의 실수는 그 값만 뺀다(G5)', () {
    test('목록 밖 부위는 빼고 나머지·아픈 곳·뺄 것은 산다', () {
      final a = decode({
        'parts': ['legs', 'glutes'],
        'avoid': ['shoulders'],
        'pain': '어깨 아파서',
        'exclude': ['스쿼트'],
        'intensity': 'brutal',
      }, '어깨 아파서 스쿼트 말고 하체랑 엉덩이');
      expect(a.parts, ['legs']);
      expect(a.avoid, ['shoulders']);
      expect(a.pain, '어깨 아파서');
      expect(a.exclude, ['스쿼트']);
      expect(a.intensity, isNull);
      expect(codes(a), ['unmet', 'unmet']);
    });

    test('기구: only·without 을 함께 받고, 벤치는 값이다, 스미스는 줄', () {
      final a = decode({
        'equipment': {
          'only': ['dumbbell', 'smith'],
          'without': ['barbell', 'bench'],
        },
      }, '덤벨만 있고 바벨·벤치는 없어 스미스는 있어');
      expect(a.only, {'dumbbell'});
      expect(a.without, {'barbell', 'bench'});
      expect(a.dropped.single.args, ['smith']);
    });

    test('흔한 이름은 고친다: deload→light, normal→없음, pullupBar→bar, 러닝머신→러닝(G8)', () {
      expect(decode({'intensity': 'deload'}, '디로드').intensity, 'light');
      final n = decode({'intensity': 'normal'}, '보통');
      expect(n.intensity, isNull);
      expect(n.dropped, isEmpty);
      final g = decode({
        'equipment': {
          'only': ['pullupBar', 'dumbbell', 'treadmill'],
        },
      }, '철봉이랑 덤벨, 러닝머신밖에 없음');
      expect(g.only, {'bar', 'dumbbell'});
      expect(g.exercises, ['러닝']);
    });

    test('부위 넷은 셋만 받고 넷째는 줄로 남긴다', () {
      final a = decode({
        'parts': ['chest', 'back', 'shoulders', 'arms'],
        'pain': true,
      }, '가슴 등 어깨 팔 다 하고 허리 아파');
      expect(a.parts, hasLength(3));
      expect(a.pain, '');
      expect(a.dropped.single.args, ['arms']);
    });
  });

  group('수의 역할(G2) — 글에 그 역할로 적힌 수만', () {
    test('감량 10kg 은 증감이 아니다', () {
      final a = decode({
        'delta': {'value': 10, 'unit': 'kg'},
      }, '10kg 감량 루틴');
      expect(a.delta, isNull);
      expect(codes(a), ['notStated']);
    });

    test('"5키로 줄여서" 는 −5, "+5kg" 는 +5, "2.5키로씩 더" 는 +2.5', () {
      expect(
        decode({
          'from': {},
          'delta': {'value': 5, 'unit': 'kg'},
        }, '5키로 줄여서 지난번 그대로').delta?.value,
        -5,
      );
      expect(
        decode({
          'delta': {'value': 5, 'unit': 'kg'},
        }, '저번 하체 +5kg').delta?.value,
        5,
      );
      expect(
        decode({
          'delta': {'value': -2.5, 'unit': 'kg'},
        }, '지난번이랑 같은데 2.5키로씩 더').delta?.value,
        2.5,
      );
    });

    test('나이·해 본 횟수는 운동 수가 아니다', () {
      expect(decode({'count': 10}, '子供(10歳)の筋トレメニュー作って').count, isNull);
      expect(decode({'count': 2}, '운동 2번 해봤는데 오늘 뭐 해').count, isNull);
      expect(decode({'count': 3}, '시간 없으니까 3개만').count, 3);
    });

    test('시간: 분·시간(×60)·반시간·한 시간·글로 쓴 수', () {
      expect(decode({'minutes': 60}, '1시간 꽉 채워서 하체').minutes, 60);
      expect(decode({'minutes': 60}, '한 시간 정도 할 루틴').minutes, 60);
      expect(decode({'minutes': 30}, '반시간만 하고 갈래').minutes, 30);
      expect(decode({'minutes': 30}, '只有半小时').minutes, 30);
      expect(decode({'minutes': 20}, 'twenty minutes of arms').minutes, 20);
      expect(decode({'minutes': 25}, '20분밖에 없어').minutes, isNull);
      expect(decode({'minutes': 20}, '20분밖에 없어').minutes, 20);
    });

    test('세트×횟수·초·총 개수', () {
      final a = decode({
        'targets': [
          {'exercise': '데드리프트', 'sets': 3, 'reps': 5},
          {'exercise': '플랭크', 'sets': 3, 'seconds': 60},
          {'exercise': '푸시업', 'total': 20},
        ],
      }, '데드 3x5, 플랭크 1분씩 3세트, 푸시업 스무 개');
      expect(
        [for (final t in a.targets) (t.sets, t.reps, t.seconds, t.total)],
        [(3, 5, null, null), (3, null, 60, null), (null, null, null, 20)],
      );
      final b = decode({
        'targets': [
          {'exercise': '데드리프트', 'sets': 3, 'reps': 6},
        ],
      }, '데드 3x5');
      expect(b.targets.single.reps, isNull);
      expect(codes(b), ['notStated']);
    });

    test('무게는 무게 단위가 붙어야 한다', () {
      final a = decode({
        'targets': [
          {'exercise': '벤치프레스', 'weight': 60, 'unit': 'kg'},
        ],
      }, '벤치 60 쳐');
      expect(a.targets.single.weight, isNull);
      final b = decode({
        'targets': [
          {'exercise': '벤치프레스', 'weight': 60, 'unit': 'kg'},
        ],
      }, '벤치 60kg 으로');
      expect(b.targets.single.weight, 60);
    });

    test('검토#8 무게 단위는 글에서 그 수 바로 뒤의 단위다', () {
      const text = '벤치 225lb 5x5 넣어서 짜줘';
      // 모델이 단위를 빼면 글의 단위(lb)다.
      final a = decode({
        'targets': [
          {'exercise': '벤치프레스', 'weight': 225, 'sets': 5, 'reps': 5},
        ],
      }, text);
      expect(a.targets.single.weight, 225);
      expect(a.targets.single.unit, 'lb');
      // 글과 어긋난 단위(kg)면 그 무게를 빼고 줄로 알린다.
      final b = decode({
        'targets': [
          {
            'exercise': '벤치프레스',
            'weight': 225,
            'unit': 'kg',
            'sets': 5,
            'reps': 5,
          },
        ],
      }, text);
      expect(b.targets.single.weight, isNull);
      expect(b.targets.single.sets, 5);
      expect(codes(b), ['notStated']);
      expect(b.dropped.single.args, ['225kg']);
      // 증감도 같다.
      final c = decode({
        'delta': {'value': 10, 'unit': 'kg'},
      }, '지난번보다 10lb 더');
      expect(c.delta, isNull);
      expect(codes(c), ['notStated']);
      expect(
        decode({
          'delta': {'value': 10},
        }, '지난번보다 10lb 더').delta,
        (value: 10.0, unit: 'lb'),
      );
      expect(
        decode({
          'delta': {'value': 5, 'unit': 'kg'},
        }, '벤치는 100lb 인데 오늘은 5kg씩 더').delta,
        (value: 5.0, unit: 'kg'),
      );
    });

    test('남의 루틴은 숫자를 옮기지 않는다(person)', () {
      final a = decode({
        'refused': {'person': '친구 루틴'},
        'targets': [
          {'exercise': '벤치프레스', 'weight': 60, 'unit': 'kg'},
        ],
      }, '친구 루틴 짜줘 걔는 벤치 60kg 쳐');
      expect(a.forSomeoneElse, isTrue);
      expect(a.targets, isEmpty);
    });

    test('타이머 수', () {
      final a = decode({
        'timer': {'kind': 'tabata', 'work': 30, 'rest': 10, 'rounds': 8},
      }, '30초 운동 10초 휴식 8라운드로 서킷');
      expect((a.timer!.work, a.timer!.rest, a.timer!.rounds), (30, 10, 8));
      final b = decode({
        'timer': {'kind': 'bpm', 'bpm': 60},
      }, '푸시업 bpm 60으로 100개');
      expect(b.timer!.bpm, 60);
      final c = decode({
        'timer': {'kind': 'tabata', 'rounds': 10},
      }, '타바타로');
      expect(c.timer!.rounds, isNull);
    });
  });

  test('G3: 의료·약물은 다른 키가 있어도 시작할 카드가 없다', () {
    final a = decode({
      'refused': {'medical': '무릎 수술'},
      'parts': ['legs'],
    }, '무릎 수술 2주 됐는데 하체 짜줘');
    expect(a.held, isTrue);
    expect(
      decode({
        'refused': {'drug': '스테로이드'},
      }, '스테로이드 사이클 짜줘').held,
      isTrue,
    );
    expect(
      decode({
        'refused': {'weird': '뭔가'},
      }, '뭔가').refused.keys,
      ['other'],
    );
  });

  group('ask(G20) — 원문의 조각으로', () {
    test('원문 조각은 그대로', () {
      expect(
        decode({
          'parts': ['legs'],
          'ask': '지난주 스쿼트 최고 보여주고',
        }, '지난주 스쿼트 최고 보여주고 오늘 하체 짜줘').ask,
        '지난주 스쿼트 최고 보여주고',
      );
    });

    test('별칭을 바꿔 보낸 글의 조각은 원문 자리로 되돌린다', () {
      final a = decodeRoutineAsk(
        {
          'parts': ['shoulders'],
          'ask': '오버헤드프레스 최고 보여주고',
        },
        'ohp 최고 보여주고 오늘 어깨 짜줘',
        ['오버헤드프레스', ...recorded],
        today: routineToday,
      );
      expect(a.ask, 'ohp 최고 보여주고');
    });

    test('못 맞추면 버리지 않고 원문 전체', () {
      expect(
        decode({'ask': '지어낸 질문'}, '오늘 뭐 했지? 그리고 내일 루틴 짜줘').ask,
        '오늘 뭐 했지? 그리고 내일 루틴 짜줘',
      );
    });
  });

  group('from·when', () {
    test('from 안의 모르는 키는 그 키만 뺀다', () {
      final a = decode({
        'from': {
          'weekdays': [2],
          'mood': 'good',
        },
      }, '지난 화요일이랑 똑같이');
      expect(a.from, {
        'weekdays': [2],
      });
      expect(codes(a), ['unmet']);
    });

    test('풀 수 없는 from 은 줄로 남기고 버린다', () {
      final a = decode({
        'from': {
          'shift': {'weeks': 2},
        },
      }, '2주 전');
      expect(a.from, isNull);
      expect(codes(a), ['unmet']);
    });

    test('from 안의 수도 그 뜻으로 적혀 있어야 한다(G2)', () {
      final a = decode({
        'from': {'nth': 2},
      }, '운동 2번 해봤는데 오늘 뭐 해');
      expect(a.from, isNull);
      expect(codes(a), ['notStated']);
      expect(
        decode({
          'from': {
            'period': 'thisWeek',
            'shift': {'weeks': 2},
            'weekdays': [1],
          },
        }, '2주 전 월요일 루틴').from?['shift'],
        {'weeks': 2},
      );
      expect(
        decode({
          'from': {'nth': 2},
        }, '두 번째 전 운동 그대로').from,
        isNotNull,
      );
    });

    test('뜻이 같은 값: lower 는 legs, 기구를 모두 뺀 것은 맨몸만', () {
      expect(
        decode({
          'parts': ['lower'],
        }, '하체').parts,
        ['legs'],
      );
      final a = decode({
        'equipment': {
          'without': [
            'barbell',
            'dumbbell',
            'machine',
            'cable',
            'bar',
            'kettlebell',
            'band',
            'bench',
          ],
        },
      }, '기구 없이');
      expect(a.only, {'bodyweight'});
      expect(a.without, isEmpty);
    });

    test('검토#11 모델이 내일·요일을 빼면 기기가 읽은 앞날로 채운다', () {
      expect(
        decode({
          'parts': ['legs'],
        }, '내일 하체 짜줘').when,
        'tomorrow',
      );
      expect(decode({}, '금요일에 할 거 짜줘').when, 5);
      // 오늘을 말했거나 모델이 지난날(from)로 읽었으면 앞날로 바꾸지 않는다.
      expect(decode({}, '내일은 쉬니까 오늘 빡세게').when, isNull);
      expect(
        decode({
          'from': {
            'weekdays': [4],
          },
        }, '목요일 거로').when,
        isNull,
      );
    });

    test('when', () {
      expect(decode({'when': 'tomorrow'}, '내일').when, 'tomorrow');
      expect(decode({'when': 5}, '금요일').when, 5);
      expect(decode({'when': 'today'}, '오늘').when, isNull);
      expect(codes(decode({'when': 9}, 'x')), ['unmet']);
    });
  });

  test('G7: 글에 적힌 운동만 "지목" 이다', () {
    final a = decode({
      'exercises': ['벤치프레스', '스쿼트'],
      'equipment': {
        'only': ['dumbbell'],
      },
    }, '벤치 하고 싶은데 덤벨만 있어');
    expect(a.named, contains('벤치프레스'));
    expect(a.named, isNot(contains('스쿼트')));
  });
}
