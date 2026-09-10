// 블라인드 평가용. 정답을 모르는 문장 목록을 실제 모델로 돌려 **어떻게
// 읽었는지만** 찍는다. 채점은 사람이 한다 — 그래야 고치는 데 쓴 문항으로
// 자기 채점하는 함정을 피한다.
//
//   flutter run --no-pub -d <device> -t tool/interpret_questions.dart \
//     --dart-define=QUESTIONS=/absolute/path/questions.txt
//
// 한 줄에 한 문장. 빈 줄은 건너뛴다. NotesStore 를 만들거나 실제 기록을
// 읽고 쓰지 않는다 — 운동 이름 목록만 메모리에 둔다.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:setpad/local_ai.dart';
import 'package:setpad/record_query.dart';

const _names = [
  '스쿼트', '벤치프레스', '데드리프트', '랫풀다운', '레그프레스', '바벨로우',
  '덤벨컬', '사이드레터럴레이즈', '오버헤드프레스', '케이블 푸시다운', '푸시업',
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const CupertinoApp(home: CupertinoPageScaffold(child: SizedBox.shrink())),
  );
  const path = String.fromEnvironment('QUESTIONS');
  final questions = path.isEmpty
      ? const <String>[]
      : File(path)
            .readAsLinesSync()
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty && !l.startsWith('#'))
            .toList();
  // 같은 이름의 .json 이 있으면 정답이다 — 그때는 채점까지 한다.
  final expectedFile = File(path.replaceAll(RegExp(r'\.txt$'), '.json'));
  final expected = <String, Map<String, Object?>>{};
  if (path.isNotEmpty && expectedFile.existsSync()) {
    for (final c in jsonDecode(expectedFile.readAsStringSync()) as List) {
      expected[c['q'] as String] = {
        ...(c['expected'] as Map).cast<String, Object?>(),
        'cat': c['cat'],
      };
    }
  }
  final tally = <String, List<bool>>{};
  const ai = LocalAi();
  final status = await ai.status('ko');
  debugPrint('INTERPRET_STATUS ${status.name} · ${questions.length}문장');
  if (status != LocalAiStatus.available || questions.isEmpty) {
    debugPrint('INTERPRET_DONE');
    return;
  }
  await ai.warmRecordQuery('ko');
  for (final q in questions) {
    final watch = Stopwatch()..start();
    Map<String, Object?> out;
    try {
      final plan = await ai.queryRecords(
        q, 'ko', _names, unit: 'kg', today: DateTime(2026, 9, 9),
      );
      out = {
        'kind': plan.kind,
        'rank': plan.rank,
        'compare': plan.compare,
        'reason': plan.reason,
        'searchNames': plan.searchNames,
        'doubts': plan.doubts,
        'readAs': plan.readAs,
        'requests': [
          for (final r in plan.requests)
            {
              'exercise': r.exercise,
              'metric': r.metric.name,
              'since': r.since?.toIso8601String().substring(0, 10),
              'until': r.until?.toIso8601String().substring(0, 10),
              'minWeight': r.minWeight, 'maxWeight': r.maxWeight,
              'minReps': r.minReps, 'maxReps': r.maxReps,
              'unit': r.weightUnit,
            },
        ],
      };
    } catch (e) {
      out = {'error': '$e'};
    }
    final exp = expected[q];
    final errors = exp == null ? null : _grade(out, exp);   // null = 관찰만
    if (exp != null && errors != null) {
      tally.putIfAbsent(exp['cat'] as String, () => []).add(errors.isEmpty);
    }
    debugPrint(
      'INTERPRET ${jsonEncode({
        'question': q,
        'ms': watch.elapsedMilliseconds,
        'cat': ?exp?['cat'],
        'ok': ?errors?.isEmpty,
        'errors': ?errors,
        ...out,
      })}',
      wrapWidth: 10000,
    );
  }
  final all = tally.values.expand((v) => v).toList();
  debugPrint(
    'INTERPRET_SUMMARY ${jsonEncode({
      'passed': all.where((b) => b).length,
      'graded': all.length,
      'byCategory': {
        for (final e in tally.entries)
          e.key: '${e.value.where((b) => b).length}/${e.value.length}',
      },
    })}',
    wrapWidth: 10000,
  );
  debugPrint('INTERPRET_DONE');
}

/// 정답에 적힌 칸만 견준다. 비어 있는 칸은 묻지 않는다. 채점하지 않는
/// 항목(관찰만)은 null.
List<String>? _grade(Map<String, Object?> out, Map<String, Object?> exp) {
  if (exp.containsKey('note') ||
      (exp.containsKey('exercise') && exp['exercise'] == null)) {
    return null;
  }
  final errors = <String>[];
  if (out.containsKey('error')) return ['error'];
  if (exp['kind'] == 'unsupported') {
    if (out['kind'] != 'unsupported') errors.add('kind');
    return errors;
  }
  final requests = (out['requests'] as List?)?.cast<Map>() ?? const [];
  if (exp.containsKey('exercises')) {
    if (requests.length < 2) errors.add('two-exercises');
    return errors;
  }
  if (requests.isEmpty) return ['no-request'];
  final r = requests.first;
  if (r['exercise'] != exp['exercise']) errors.add('exercise');
  if (r['metric'] != exp['metric']) errors.add('metric');
  if (exp['period'] == true && r['since'] == null) errors.add('period-missing');
  if (exp['period'] == false && r['since'] != null) errors.add('period-invented');
  for (final k in ['minWeight', 'maxWeight', 'minReps']) {
    if (exp.containsKey(k) && r[k] != exp[k]) errors.add(k);
  }
  if (exp.containsKey('unit') && r['unit'] != exp['unit']) errors.add('unit');
  return errors;
}
