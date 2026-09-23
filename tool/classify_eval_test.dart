import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/exercises.dart';
import 'package:setpad/meal.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/workout_timing.dart';

/// 입력 줄 하나로 운동과 끼니를 가르는 것(v3 §2)을 잰다. 에디터(_name)와 같은 순서:
///
/// 1. 타이머 이름 → 운동. 2. 운동 근거 → 운동. 3. 끼니 근거 → 끼니.
/// 4. 음식 표(정확한 이름) → 끼니. 5. 수 없는 줄 → 운동.
/// 6. 수가 든 줄은 모델이 읽고 "food": true 면 끼니, 아니면 운동.
///
/// **test/ 밖에 둔다.** 음식 표는 운영 DB 에만 다 있다(로컬 임베디드 DB 에는 가공식품·
/// USDA 가 없다). 그래서 표 조회 결과는 gymdojo 의 같은 SQL(lib/food-reference.ts
/// foodMatch)을 읽기 전용 연결로 돌린 파일로 받는다:
///
///     node --experimental-strip-types scripts/food-match-eval.mjs \
///       ../setpad/tool/classify_questions.json /tmp/foods.json   # DATABASE_URL 읽기 전용
///     EVAL_FOODS=/tmp/foods.json [DEEPSEEK_API_KEY=...] \
///       flutter test --no-pub tool/classify_eval_test.dart
///
/// EVAL_FOODS 가 없으면 표를 못 본 것(늘 음식 아님)으로 잰다. DEEPSEEK_API_KEY 가
/// 없으면 6 을 건너뛰고 그 줄은 운동이다(오프라인과 같다). 모델은 서버처럼 부른다
/// (input_eval_test.dart 와 같은 모델·max_tokens·json_object).
///
/// 문턱: 운동을 끼니로 보낸 비율 ≤ 1%, 끼니를 운동으로 둔 비율 ≤ 5%.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final key = Platform.environment['DEEPSEEK_API_KEY'] ?? '';
  final foods = switch (Platform.environment['EVAL_FOODS']) {
    final String path => jsonDecode(File(path).readAsStringSync()) as Map,
    null => null,
  };
  HttpOverrides.global = null;
  final client = HttpClient();

  Future<Object?> ask(String instructions, String input) async {
    final request = await client.postUrl(
      Uri.parse('https://api.deepseek.com/chat/completions'),
    );
    request.headers
      ..set('authorization', 'Bearer $key')
      ..set('content-type', 'application/json');
    request.add(
      utf8.encode(
        jsonEncode({
          'model': 'deepseek-flash',
          'max_tokens': 1000,
          'thinking': {'type': 'disabled'},
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'system',
              'content': '$instructions\nReturn a JSON object only.',
            },
            {'role': 'user', 'content': input},
          ],
        }),
      ),
    );
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw HttpException('${response.statusCode} $text');
    }
    final choice = (jsonDecode(text)['choices'] as List).first as Map;
    final content = (choice['message'] as Map?)?['content'];
    if (choice['finish_reason'] != 'stop' || content is! String) {
      throw const RecordAiException(RecordAiStatus.unavailable);
    }
    return jsonDecode(content);
  }

  final ai = RecordAi(respond: ask);
  final cases =
      (jsonDecode(File('tool/classify_questions.json').readAsStringSync())
              as List)
          .cast<Map<String, Object?>>();

  test('입력 줄 하나로 운동과 끼니를 가른다', () async {
    final steps = <String, int>{};
    var right = 0, exercises = 0, meals = 0, toMeal = 0, toExercise = 0;
    final errors = <String>[], modelLines = <String>[];
    for (final c in cases) {
      final text = c['text'] as String;
      final want = c['kind'] as String;
      final numbered = hasSetupIntent(text);
      final timerOnly =
          TimingSpec.parse(text) != null &&
          !hasSetupIntent(text.replaceAll(timerTokens, ' '));
      final (String got, String step) = await () async {
        if (timerOnly) return ('exercise', '1 타이머');
        if (exerciseEvidence(text, const [])) return ('exercise', '2 운동 근거');
        if (mealEvidence(text)) return ('meal', '3 끼니 근거');
        if (foods?[text] != null) return ('meal', '4 음식 표');
        if (!numbered) return ('exercise', '5 수 없는 이름');
        if (key.isEmpty) return ('exercise', '6 모델 없음');
        try {
          final reading = await ai.interpret(text, 'ko', seedNames('ko'));
          return reading.food ? ('meal', '6 모델 food') : ('exercise', '6 모델 운동');
        } catch (e) {
          return ('exercise', '6 모델 실패');
        }
      }();
      steps[step] = (steps[step] ?? 0) + 1;
      if (step.startsWith('6 ')) modelLines.add('$text → $step');
      if (want == 'exercise') exercises++;
      if (want == 'meal') meals++;
      if (got == want) {
        right++;
        continue;
      }
      if (want == 'exercise') toMeal++;
      if (want == 'meal') toExercise++;
      final hit = foods?[text];
      errors.add(
        '[${c['category']}] $text → $got ($step)'
        '${hit is Map ? ' 표: ${hit['name']} (${hit['kind']})' : ''}',
      );
    }
    String pct(int n, int of) => '${(100 * n / of).toStringAsFixed(1)}%';
    // ignore: avoid_print
    print(
      '가르기: 정확 $right/${cases.length} = ${pct(right, cases.length)} · '
      '운동→끼니 $toMeal/$exercises = ${pct(toMeal, exercises)} · '
      '끼니→운동 $toExercise/$meals = ${pct(toExercise, meals)} · '
      '표 ${foods == null ? '없음' : '있음'} · 모델 ${key.isEmpty ? '없음' : '있음'}',
    );
    // ignore: avoid_print
    print('단계별: $steps');
    // ignore: avoid_print
    print('모델이 읽은 줄: $modelLines');
    for (final e in errors) {
      // ignore: avoid_print
      print('  $e');
    }
    expect(toMeal / exercises, lessThanOrEqualTo(0.01), reason: '운동→끼니');
    if (foods != null && key.isNotEmpty) {
      expect(toExercise / meals, lessThanOrEqualTo(0.05), reason: '끼니→운동');
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
