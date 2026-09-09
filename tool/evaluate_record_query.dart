// Run with flutter run -d <device> -t tool/evaluate_record_query.dart.
// This entry point never constructs a NotesStore, reads records, or writes files.
import 'dart:convert';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:setpad/local_ai.dart';
import 'package:setpad/record_query.dart';

const _names = [
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
Map<String, Object?> expected(
  String exercise,
  String metric, {
  String? since,
  String? until,
  double? minWeight,
  double? maxWeight,
  int? minReps,
  int? maxReps,
  String weightUnit = 'kg',
}) => {
  'exercise': exercise,
  'metric': metric,
  'since': since,
  'until': until,
  'minWeight': minWeight,
  'maxWeight': maxWeight,
  'minReps': minReps,
  'maxReps': maxReps,
  'weightUnit': weightUnit,
};
Map<String, Object?> request(RecordRequest r) => expected(
  r.exercise,
  r.metric.name,
  since: r.since?.toIso8601String().substring(0, 10),
  until: r.until?.toIso8601String().substring(0, 10),
  minWeight: r.minWeight,
  maxWeight: r.maxWeight,
  minReps: r.minReps,
  maxReps: r.maxReps,
  weightUnit: r.weightUnit,
);

class Case {
  Case(
    this.question,
    this.requests, {
    this.kind = 'answer',
    this.rank = false,
    this.compare = false,
    this.reason = '',
    this.limit = 1,
    this.heldOut = false,
  });
  final String question, kind, reason;
  final bool rank, compare, heldOut;
  final int limit;
  final List<Map<String, Object?>> requests;
}

final _cases = [
  Case('내 스쿼트 기록 중 제일 무거웠던 건?', [expected('스쿼트', 'max')]),
  Case('벤치 최고', [expected('벤치프레스', 'max')]),
  Case('벤치 80킬로 이상으로 몇 세트나 했었어?', [expected('벤치프레스', 'sets', minWeight: 80)]),
  Case('스쿼트 60kg 이하로 한 세트 수', [expected('스쿼트', 'sets', maxWeight: 60)]),
  Case('지난달 운동한 날이 며칠이지?', [
    expected('*', 'sessions', since: '2026-08-01', until: '2026-08-31'),
  ]),
  Case('최근 14일 푸시업 총 몇 회 했어?', [
    expected('푸시업', 'reps', since: '2026-08-27', until: '2026-09-09'),
  ]),
  Case('지난주 벤치 평균 무게 알려줘', [
    expected('벤치프레스', 'average', since: '2026-08-31', until: '2026-09-06'),
  ]),
  Case('지난달보다 이번 달 스쿼트 무게 얼마나 늘었어?', [
    expected('스쿼트', 'max', since: '2026-08-01', until: '2026-08-31'),
    expected('스쿼트', 'max', since: '2026-09-01', until: '2026-09-09'),
  ], compare: true),
  Case('가장 자주 한 운동 세 개', [expected('*', 'sessions')], rank: true, limit: 3),
  Case('무릎이 불편했다는 메모 좀 찾아줘', [expected('*', 'sets')], kind: 'insight'),
  Case('요즘 기록 보면 나 어때?', [
    expected('*', 'sets', since: '2026-08-13', until: '2026-09-09'),
  ], kind: 'insight'),
  Case('내일 부산 비 오나?', [], kind: 'unsupported', reason: 'unrelated'),
  Case('데드 제일 높게 찍은 중량이 뭐였지', [expected('데드리프트', 'max')], heldOut: true),
  Case('벤치프레스 90kg 이상으로 운동한 세트 수 알려줘', [
    expected('벤치프레스', 'sets', minWeight: 90),
  ], heldOut: true),
  Case('푸시업은 이번 달에 총 몇 개나 했지', [
    expected('푸시업', 'reps', since: '2026-09-01', until: '2026-09-09'),
  ], heldOut: true),
  Case('저번 주 운동 몇 번 갔더라?', [
    expected('*', 'sessions', since: '2026-08-31', until: '2026-09-06'),
  ], heldOut: true),
  Case('내 벤치 최근 흐름 보여줘', [
    expected('벤치프레스', 'trend', since: '2026-08-13', until: '2026-09-09'),
  ], heldOut: true),
  Case(
    '파이썬으로 계산기 만들어줘',
    [],
    kind: 'unsupported',
    reason: 'unrelated',
    heldOut: true,
  ),
  Case('스쾃 PR 얼마?', [expected('스쿼트', 'max')], heldOut: true),
  Case('벤치프레스 총 반복 횟수는?', [expected('벤치프레스', 'reps')], heldOut: true),
  Case('레그프레스 120kg 넘지 않는 세트 몇 개야?', [
    expected('레그프레스', 'sets', maxWeight: 120),
  ], heldOut: true),
  Case('최근 21일 헬스 간 날 수 알려줘', [
    expected('*', 'sessions', since: '2026-08-20', until: '2026-09-09'),
  ], heldOut: true),
  Case('올해 며칠 운동했는지 궁금해', [
    expected('*', 'sessions', since: '2026-01-01', until: '2026-09-09'),
  ], heldOut: true),
  Case('덤벨컬 마지막으로 몇 킬로 들었지?', [expected('덤벨컬', 'last')], heldOut: true),
  Case('벤치 100파운드 이상 세트 개수', [
    expected('벤치프레스', 'sets', minWeight: 100, weightUnit: 'lb'),
  ], heldOut: true),
  Case(
    '맛있는 김치찌개 레시피 알려줘',
    [],
    kind: 'unsupported',
    reason: 'unrelated',
    heldOut: true,
  ),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const CupertinoApp(home: CupertinoPageScaffold(child: SizedBox.shrink())),
  );
  const ai = LocalAi();
  final status = await ai.status('ko');
  debugPrint('EVAL_STATUS ${status.name}');
  if (status != LocalAiStatus.available) return;
  final times = <int>[];
  var passed = 0;
  for (final c in _cases) {
    final watch = Stopwatch()..start();
    final errors = <String>[];
    Object? actual;
    try {
      final plan = await ai.queryRecords(
        c.question,
        'ko',
        _names,
        unit: 'kg',
        today: DateTime(2026, 9, 9),
      );
      actual = {
        'kind': plan.kind,
        'rank': plan.rank,
        'compare': plan.compare,
        'limit': plan.limit,
        'reason': plan.reason,
        'queries': plan.requests.map(request).toList(),
      };
      if (plan.kind != c.kind) errors.add('kind');
      if (plan.rank != c.rank ||
          plan.compare != c.compare ||
          plan.limit != c.limit) {
        errors.add('operation');
      }
      if (plan.reason != c.reason) errors.add('reason');
      if (jsonEncode(plan.requests.map(request).toList()) !=
          jsonEncode(c.requests)) {
        errors.add('queries');
      }
    } catch (e) {
      errors.add(e.toString());
    }
    watch.stop();
    times.add(watch.elapsedMilliseconds);
    if (errors.isEmpty) passed++;
    debugPrint(
      'EVAL ${jsonEncode({'question': c.question, 'heldOut': c.heldOut, 'ok': errors.isEmpty, 'errors': errors, 'ms': watch.elapsedMilliseconds, 'actual': actual})}',
      wrapWidth: 10000,
    );
  }
  final search = RecordSearch(ai, now: () => DateTime(2026, 9, 9));
  await search.refresh('ko');
  final ready = Completer<void>();
  search.addListener(() {
    if (!search.busy &&
        (search.plan != null || search.failed) &&
        !ready.isCompleted) {
      ready.complete();
    }
  });
  final first = Stopwatch()..start();
  search.search('스쿼트 최고', 'ko', _names, 'kg', immediately: true);
  await ready.future;
  first.stop();
  search.search('', 'ko', _names, 'kg');
  final cached = Stopwatch()..start();
  search.search('스쿼트 최고', 'ko', _names, 'kg');
  cached.stop();
  debugPrint(
    'EVAL_CACHE ${jsonEncode({'firstMs': first.elapsedMilliseconds, 'cachedMicroseconds': cached.elapsedMicroseconds, 'ready': !search.busy && search.plan != null})}',
  );
  search.dispose();
  final sorted = [...times]..sort();
  debugPrint(
    'EVAL_SUMMARY ${jsonEncode({'passed': passed, 'total': _cases.length, 'firstMs': times.first, 'medianMs': sorted[sorted.length ~/ 2], 'p90Ms': sorted[((sorted.length - 1) * 0.9).ceil()]})}',
  );
}
