import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/meal.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/workout_timing.dart';

/// 입력 줄 하나로 운동과 끼니를 가르는 것을 잰다. 에디터(_name)와 같은 순서:
///
/// 1. 타이머 이름 → 운동. 2. 음식에만 쓰는 양 → 끼니. 3. 이름 전체가 사전 이름 → 운동.
/// 4. 판정자 — 서버(gymdojo lib/model-json.ts DECIDE_QUESTION)와 같은 모델·질문으로
///    Upstage Solar Decide 에 묻고, P(meal) ≥ 문턱이면 끼니.
/// 5. 판정이 없으면 기기 안의 규칙: 운동 단위·운동 낱말 → 운동, 음식 표·음식 낱말 → 끼니,
///    나머지 운동.
///
/// **test/ 밖에 둔다** — 판정자는 돈이 드는 실제 호출이다(입력 100만 토큰에 $0.1, 한 줄에
/// 약 376토큰).
///
///     UPSTAGE_API_KEY=$(security find-generic-password -s upstage_mammalog -w) \
///       flutter test --no-pub tool/classify_eval_test.dart
///     EVAL_SET=tool/kind_corpus.json ...   # 8개 언어 420줄(2026-10-07). 두 사람이 따로
///                                           # 단 정답이 갈린 줄은 ambiguous 로 두고 채점 않음
///     DECIDE_MEAL_MIN_PCT=40 ...           # 문턱(서버 변수와 같은 이름, 기본 35; 운동 낱말·단위가
///                                           # 있는 줄은 DECIDE_MEAL_MIN_HINTED_PCT, 기본 50)
///     EVAL_FOODS=/tmp/foods.json ...       # 음식 표 조회 결과(gymdojo scripts/food-match-eval.mjs)
///
/// UPSTAGE_API_KEY 가 없으면 4 를 건너뛴다(오프라인·AI 끔과 같다).
///
/// 2026-10-07 잰 값(판정자 있음): kind_corpus 98.1%(운동→끼니 3/192, 끼니→운동 4/186),
/// classify_questions 98.2%(3/116, 1/107). 판정자 없음 69.0%. 틀린 줄은 WOD·지은 이름·은어·
/// 오타('머프', '선생님 스페셜', 'BCAA', 'qpscl')이고, flash 의 P(meal) 은 같은 글에도 호출마다
/// 한두 계단(0.03~0.07) 흔들린다 — 0.3~0.45 에 끼니와 운동이 섞여 어떤 문턱으로도 다 가르지
/// 못한다. 대신 한 번 바꾸면(세트를 적은 운동 이름, 남긴 끼니) 다음부터는 묻지 않는다.
///
/// 지키는 선: 운동을 끼니로 보낸 비율 ≤ 3%, 끼니를 운동으로 둔 비율 ≤ 5%(판정자가 있을 때).
/// 예전 1% 는 이 질문 셋에 맞춰 키운 낱말 목록의 값이었다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final key = Platform.environment['UPSTAGE_API_KEY'] ?? '';
  double pct(String name, int fallback) =>
      (int.tryParse(Platform.environment[name] ?? '') ?? fallback) / 100;
  final mealMin = pct('DECIDE_MEAL_MIN_PCT', 35);
  final hintedMin = pct('DECIDE_MEAL_MIN_HINTED_PCT', 50);
  final foods = switch (Platform.environment['EVAL_FOODS']) {
    final String path => jsonDecode(File(path).readAsStringSync()) as Map,
    null => null,
  };
  HttpOverrides.global = null;
  final client = HttpClient();

  /// P(meal) from Solar Decide, or null when it cannot answer (same as the server's fallback).
  Future<double?> judge(String text) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        final request = await client.postUrl(
          Uri.parse('https://api.upstage.ai/v1/systemone'),
        );
        request.headers
          ..set('authorization', 'Bearer $key')
          ..set('content-type', 'application/json');
        request.add(
          utf8.encode(
            jsonEncode({
              'model': 'solar-decide-flash',
              'state': text,
              'questions': {
                'kind': {
                  'type': 'choice',
                  'instructions':
                      'A line typed into a workout log app. Is it something '
                      'the person ate or drank (meal), or an exercise they '
                      'did (exercise)?',
                  'criteria': {
                    'meal': 'food or drink eaten',
                    'exercise': 'a workout, exercise name, or sets',
                  },
                },
              },
            }),
          ),
        );
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        if (response.statusCode == 429 || response.statusCode >= 500) {
          // The key allows 100 requests a minute.
          await Future<void>.delayed(Duration(seconds: 2 << attempt));
          continue;
        }
        if (response.statusCode != 200) return null;
        final p =
            ((jsonDecode(body) as Map)['answers']
                as Map?)?['kind']?['probabilities']?['meal'];
        return p is num ? p.toDouble() : null;
      } on IOException {
        await Future<void>.delayed(Duration(seconds: 2 << attempt));
      }
    }
    return null;
  }

  final cases =
      (jsonDecode(
                File(
                  Platform.environment['EVAL_SET'] ??
                      'tool/classify_questions.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, Object?>>()
          .where((c) => c['kind'] == 'meal' || c['kind'] == 'exercise')
          .toList();

  test('입력 줄 하나로 운동과 끼니를 가른다', () async {
    final steps = <String, int>{};
    var right = 0, exercises = 0, meals = 0, toMeal = 0, toExercise = 0;
    final errors = <String>[];
    for (final c in cases) {
      final text = c['text'] as String;
      final want = c['kind'] as String;
      final timerOnly =
          TimingSpec.parse(text) != null &&
          !hasSetupIntent(text.replaceAll(timerTokens, ' '));
      final (String got, String step) = await () async {
        if (timerOnly) return ('exercise', '1 타이머');
        if (clearMealEvidence(text)) return ('meal', '2 음식 양');
        if (exerciseName(text, const [])) return ('exercise', '3 운동 이름');
        if (key.isNotEmpty) {
          final p = await judge(text);
          if (p != null) {
            // The app sends hint: 'exercise' for these; the server then asks for more.
            final min = exerciseEvidence(text, const []) ? hintedMin : mealMin;
            return p >= min ? ('meal', '4 판정 끼니') : ('exercise', '4 판정 운동');
          }
        }
        if (exerciseEvidence(text, const [])) return ('exercise', '5 운동 근거');
        if (foods?[text] != null || mealEvidence(text)) {
          return ('meal', '5 끼니 근거');
        }
        return ('exercise', '5 근거 없음');
      }();
      steps[step] = (steps[step] ?? 0) + 1;
      if (want == 'exercise') exercises++;
      if (want == 'meal') meals++;
      if (got == want) {
        right++;
        continue;
      }
      if (want == 'exercise') toMeal++;
      if (want == 'meal') toExercise++;
      errors.add('[${c['category'] ?? c['lang']}] $text → $got ($step)');
    }
    String pct(int n, int of) => '${(100 * n / of).toStringAsFixed(1)}%';
    // ignore: avoid_print
    print(
      '가르기: 정확 $right/${cases.length} = ${pct(right, cases.length)} · '
      '운동→끼니 $toMeal/$exercises = ${pct(toMeal, exercises)} · '
      '끼니→운동 $toExercise/$meals = ${pct(toExercise, meals)} · '
      '판정자 ${key.isEmpty ? '없음' : '있음(문턱 $mealMin · 운동 낱말 $hintedMin)'} · '
      '표 ${foods == null ? '없음' : '있음'}',
    );
    // ignore: avoid_print
    print('단계별: $steps');
    for (final e in errors) {
      // ignore: avoid_print
      print('  $e');
    }
    if (key.isNotEmpty) {
      expect(toMeal / exercises, lessThanOrEqualTo(0.03), reason: '운동→끼니');
      expect(toExercise / meals, lessThanOrEqualTo(0.05), reason: '끼니→운동');
    }
  }, timeout: const Timeout(Duration(minutes: 15)));
}
