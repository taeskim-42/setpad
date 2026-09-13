import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart';
import 'question_grading.dart';

/// 같은 질문, 같은 지시문, 같은 채점기 — 모델만 바꿔 잰다.
///
/// **test/ 밖에 둔다.** 진짜 API 를 부르고 키가 있어야 하므로 평소 스위트에
/// 섞이면 안 된다. 재려면:
///
///     ANTHROPIC_API_KEY=... flutter test --no-pub tool/remote_eval_test.dart
///
/// 앱의 경로를 그대로 탄다. 채널만 가로채서 기기 안 모델 대신 API 를 부르므로
/// 프롬프트 조립·이름 정규화·디코딩·규칙 층이 전부 실제와 같다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const model = 'claude-haiku-4-5-20251001';
  final key = Platform.environment['ANTHROPIC_API_KEY'] ?? '';
  // flutter_test 는 모든 HTTP 를 막는 가짜 클라이언트를 끼운다. 이 평가는
  // 진짜 API 를 불러야 하므로 그 가로채기를 끈다.
  HttpOverrides.global = null;
  final client = HttpClient();

  Future<String> ask(String instructions, String input) async {
    final request = await client.postUrl(
      Uri.parse('https://api.anthropic.com/v1/messages'),
    );
    request.headers
      ..set('x-api-key', key)
      ..set('anthropic-version', '2023-06-01')
      ..set('content-type', 'application/json');
    request.add(
      utf8.encode(
        jsonEncode({
          'model': model,
          'max_tokens': 400,
          'system': [
            {
              'type': 'text',
              'text': instructions,
              // 지시문은 모든 사용자가 같다. 캐시가 맞으면 값도 지연도 준다.
              'cache_control': {'type': 'ephemeral'},
            },
          ],
          'messages': [
            {'role': 'user', 'content': input},
          ],
        }),
      ),
    );
    final response = await request.close();
    final body = jsonDecode(await response.transform(utf8.decoder).join());
    if (response.statusCode != 200) {
      throw Exception('${response.statusCode} ${body['error']?['message']}');
    }
    final parts = body['content'] as List;
    final joined = parts.map((p) => p['text'] ?? '').join().trim();
    // 서버 라우트가 하는 것과 같게 — 모델이 ```json 울타리를 치기도 한다.
    if (!joined.startsWith('```')) return joined;
    return joined
        .substring(joined.indexOf('\n') + 1, joined.lastIndexOf('```'))
        .trim();
  }

  test('Haiku 로 held-out 을 다시 잰다', () async {
    if (key.isEmpty) {
      // ignore: avoid_print
      print('ANTHROPIC_API_KEY 없음 — 건너뜀');
      return;
    }
    final ai = RecordAi(
      respond: (instructions, input) => ask(instructions, input),
    );
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
    final cases =
        (jsonDecode(File('tool/questions/heldout.json').readAsStringSync())
                as List)
            .cast<Map>();

    var graded = 0, passed = 0, failed = 0;
    final wrong = <String>[], errorTags = <String, int>{};
    final latencies = <int>[];
    final queue = List<Map>.from(cases);

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final c = queue.removeAt(0);
        final exp = (c['expected'] as Map).cast<String, Object?>();
        final q = c['q'] as String;
        final watch = Stopwatch()..start();
        RecordQueryPlan? plan;
        try {
          plan = await ai.queryRecords(
            q,
            'ko',
            names,
            unit: 'kg',
            today: today,
          );
        } catch (err) {
          failed++;
          if (wrong.length < 10) wrong.add('$q → 실패 $err');
          continue;
        }
        latencies.add(watch.elapsedMilliseconds);
        final errors = gradeRecordQuestion({
          'kind': plan.kind,
          'rank': plan.rank,
          'compare': plan.compare,
          'requests': [
            for (final r in plan.requests)
              {
                'exercise': r.exercise,
                'metric': r.metric.name,
                'since': r.since?.toIso8601String().substring(0, 10),
                'until': r.until?.toIso8601String().substring(0, 10),
                'minWeight': r.minWeight,
                'maxWeight': r.maxWeight,
                'minReps': r.minReps,
                'maxReps': r.maxReps,
                'unit': r.weightUnit,
              },
          ],
        }, exp);
        if (errors == null) continue;
        graded++;
        if (errors.isEmpty) {
          passed++;
        } else {
          for (final e in errors) {
            final tag = e.split('.').last;
            errorTags[tag] = (errorTags[tag] ?? 0) + 1;
          }
          if (wrong.length < 12) {
            wrong.add('$q → $errors (의심 ${plan.doubts})');
          }
        }
        if (q.contains('최근에 언제 했어') || q.contains('전체 볼륨 얼마')) {
          // 기기 안 모델이 자신 있게 틀렸던 문장들.
          // ignore: avoid_print
          print('  [비교] $q → ${errors.isEmpty ? "맞음" : errors.toString()}');
        }
      }
    }

    await Future.wait([for (var i = 0; i < 4; i++) worker()]);
    latencies.sort();
    // ignore: avoid_print
    print(
      'Haiku held-out: $passed/$graded = ${(100 * passed / graded).toStringAsFixed(1)}%  (호출 실패 $failed)',
    );
    // ignore: avoid_print
    print(
      '지연 중앙값 ${latencies.isEmpty ? 0 : latencies[latencies.length ~/ 2]}ms · 90p ${latencies.isEmpty ? 0 : latencies[(latencies.length * 0.9).floor()]}ms',
    );
    // ignore: avoid_print
    print('오류 종류: $errorTags');
    for (final w in wrong) {
      // ignore: avoid_print
      print('  $w');
    }
  }, timeout: const Timeout(Duration(minutes: 25)));
}
