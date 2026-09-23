import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/record_query.dart';

/// 실제 DeepSeek 평가(tool/remote_eval_test.dart)에서 본 모델 답을 앱이 한 뜻으로
/// 고쳐 읽는 자리. 뜻이 둘로 갈리는 것은 고치지 않는다 — 여기 것은 모두 읽을 수
/// 있는 뜻이 하나뿐이다.
void main() {
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

    test('메모로만 갈랐던 series 는 메모를 지우면 한 series 다 — 같은 series 둘로 거절하지 않는다', () {
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
      }, '부상 전후 데드 비교');
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
          '부상 전후 데드 비교',
          names,
          unit: 'kg',
          today: today,
        ),
        returnsNormally,
      );
    });

    test('한 줄의 합계는 그 칸 자신이다 — "러닝 총 거리" 의 total 은 뺀다', () {
      final plan = ground({
        'exercises': ['푸시업'],
        'period': 'thisMonth',
        'measures': ['repCount'],
        'total': 'sum',
      }, '이번달 푸시업 총 몇 개');
      expect(plan.containsKey('total'), isFalse);
      final three = ground({
        'exercises': ['스쿼트', '벤치프레스', '데드리프트'],
        'measures': ['best'],
        'total': 'sum',
      }, '3대 합계');
      expect(three['total'], 'sum');
    });

    test('측정을 비웠거나 한 갈래 측정만 여럿이면 글이 가리키는 하나다', () {
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
        ['trainingDays'],
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
}
