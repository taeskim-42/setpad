import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/exercises.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart';
import 'question_grading.dart';

/// 문항 하나: 질문, 언어(seedNames 의 키), 운동 목록, 정답 대안, 안 볼 키.
typedef _Case = ({
  String q,
  String lang,
  String cat,
  List<String> names,
  List<Object?> gold,
  List<Object?> ignore,
});

/// 같은 질문, 같은 지시문, 같은 채점기 — 운영 모델을 직접 불러 잰다.
///
/// **test/ 밖에 둔다.** 진짜 API 를 부르고 키가 있어야 하므로 평소 스위트에
/// 섞이면 안 된다. 키가 없으면 건너뛴다. 재려면(약 510문항, 사용자 승인 뒤에):
///
///     DEEPSEEK_API_KEY=... flutter test --no-pub tool/remote_eval_test.dart
///
/// 서버를 거치지 않는다 — 운영 한도를 쓰지 않으려고. 대신 설정은 서버
/// (gymdojo lib/model-json.ts)와 같게 둔다: deepseek-flash, max_tokens 400,
/// thinking 끔, json_object, 지시문 뒤에 "Return a JSON object only.".
///
/// 앱의 경로를 그대로 탄다. 모델 대신 대답할 자리(respond)만 끼워서 프롬프트
/// 조립·이름 정규화·디코딩·규칙 층이 전부 실제와 같다.
///
/// `EVAL_DUMP=파일` 이면 모델의 날것 대답을 JSONL 로 남긴다. `EVAL_REPLAY=파일`
/// 이면 API 대신 그 대답을 다시 먹인다 — 디코더만 바꿨을 때 모델을 다시 부르지
/// 않고 잰다(지시문을 바꿨으면 다시 불러야 한다).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const model = 'deepseek-flash';
  final key = Platform.environment['DEEPSEEK_API_KEY'] ?? '';
  final dump = switch (Platform.environment['EVAL_DUMP']) {
    final String path => File(path).openWrite(),
    null => null,
  };
  final replay = <String, String>{
    if (Platform.environment['EVAL_REPLAY'] case final String path)
      for (final line in File(path).readAsLinesSync())
        if (jsonDecode(line) case {
          'key': final String k,
          'content': final String c,
        })
          k: c,
  };
  // 질문 하나의 열쇠: 언어 + 모델에 간 글. 대답 기록과 실패 줄이 같이 쓴다.
  String keyOf(String input) {
    final i = jsonDecode(input) as Map;
    return '${i['language']}|${i['question']}';
  }

  final contents = <String, String>{};
  // flutter_test 는 모든 HTTP 를 막는 가짜 클라이언트를 끼운다. 이 평가는
  // 진짜 API 를 불러야 하므로 그 가로채기를 끈다.
  HttpOverrides.global = null;
  final client = HttpClient();
  var tokens = 0, answered = 0;

  /// 서버 라우트와 같게 — 멈춤 이유가 stop 이 아니거나 JSON 객체가 아니면
  /// 무효(FormatException)다. 그물·HTTP 실패는 IOException 이다.
  Future<Object?> ask(String instructions, String input) async {
    final k = keyOf(input);
    if (replay.isNotEmpty) {
      final content = replay[k] ?? (throw HttpException('replay 에 없음 $k'));
      contents[k] = content;
      answered++;
      final parsed = jsonDecode(content);
      if (parsed is! Map) throw const FormatException('unparsable');
      return parsed;
    }
    final request = await client.postUrl(
      Uri.parse('https://api.deepseek.com/chat/completions'),
    );
    request.headers
      ..set('authorization', 'Bearer $key')
      ..set('content-type', 'application/json');
    request.add(
      utf8.encode(
        jsonEncode({
          'model': model,
          'max_tokens': 400,
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
    final body = jsonDecode(text);
    answered++;
    if (body['usage']?['total_tokens'] case final int n) tokens += n;
    final choice = (body['choices'] as List).first as Map;
    final content = (choice['message'] as Map?)?['content'];
    if (content is String) {
      contents[k] = content;
      dump?.writeln(jsonEncode({'key': k, 'content': content}));
    }
    if (choice['finish_reason'] != 'stop' || content is! String) {
      throw const FormatException('unparsable');
    }
    final parsed = jsonDecode(content);
    if (parsed is! Map) throw const FormatException('unparsable');
    return parsed;
  }

  final ai = RecordAi(respond: ask);

  /// dev·heldout 의 운동 목록. v1 정답이 이 이름을 쓴다.
  const koNames = [
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

  List<Map<String, Object?>> load(String name) =>
      (jsonDecode(File('tool/questions/$name.json').readAsStringSync()) as List)
          .cast<Map>()
          .map((c) => c.cast<String, Object?>())
          .toList();

  List<_Case> cases(String set) => [
    for (final c in load(set))
      if (set == 'v2')
        (
          q: c['q'] as String,
          lang: c['lang'] as String,
          cat: c['cat'] as String,
          names: seedNames(c['lang'] as String),
          gold: c['gold'] as List,
          ignore: (c['ignore'] as List?) ?? const [],
        )
      else if (v2Expected((c['expected'] as Map).cast()) case final gold?)
        (
          q: c['q'] as String,
          lang: 'ko',
          cat: c['cat'] as String,
          names: koNames,
          gold: gold,
          ignore: const [],
        ),
  ];

  String pct(int n, int of) =>
      of == 0 ? '-' : '${(100 * n / of).toStringAsFixed(1)}%';

  for (final set in ['v2', 'heldout']) {
    test(
      '$model 로 $set 을 잰다',
      () async {
        tokens = 0;
        answered = 0;
        var exact = 0, invalid = 0, refused = 0, wrongButSure = 0;
        var unreachable = 0;
        final perLang = <String, List<int>>{}; // [맞음, 채점]
        final errorTags = <String, int>{}, wrong = <String>[];
        String raw(_Case c) =>
            contents['${c.lang.replaceAll('_', '-')}|${canonicalizeExercises(c.q, c.names)}'] ??
            '';
        final queue = cases(set);

        Future<void> worker() async {
          while (queue.isNotEmpty) {
            final c = queue.removeAt(0);
            final tally = perLang.putIfAbsent(c.lang, () => [0, 0]);
            RecordQuery plan;
            try {
              plan = decodeRecordIntent(
                await ai.queryIntent(
                  c.q,
                  c.lang.replaceAll('_', '-'),
                  c.names,
                  unit: 'kg',
                  today: evalToday,
                ),
                c.q,
                c.names,
                unit: 'kg',
                today: evalToday,
              );
            } on IOException catch (err) {
              // 모델 탓이 아니다. 채점에서 뺀다.
              unreachable++;
              wrong.add('${c.q} → 호출 실패 $err');
              continue;
            } catch (err) {
              invalid++;
              tally[1]++;
              wrong.add('${c.q} → 무효 $err ⟨${raw(c)}⟩');
              continue;
            }
            tally[1]++;
            final errors = gradeQuery(plan, c.gold, c.names, ignore: c.ignore);
            if (errors.isEmpty) {
              exact++;
              tally[0]++;
              continue;
            }
            // 거절은 틀려도 숫자를 보이지 않는다. 숫자를 보일 질의가
            // 틀린 것이 "자신 있게 틀림" 이다.
            if (plan.kind == 'unsupported') {
              refused++;
            } else {
              wrongButSure++;
            }
            for (final e in errors) {
              errorTags[e] = (errorTags[e] ?? 0) + 1;
            }
            wrong.add('[${c.lang} ${c.cat}] ${c.q} → $errors ⟨${raw(c)}⟩');
          }
        }

        await Future.wait([for (var i = 0; i < 4; i++) worker()]);
        await dump?.flush();
        final graded = exact + invalid + refused + wrongButSure;
        // ignore: avoid_print
        print(
          '$model $set: 정확 $exact/$graded = ${pct(exact, graded)} · '
          '무효 ${pct(invalid, graded)} · 자신 있게 틀림 ${pct(wrongButSure, graded)} · '
          '거절 $refused · 호출 실패 $unreachable · '
          '평균 토큰 ${answered == 0 ? 0 : tokens ~/ answered}',
        );
        // ignore: avoid_print
        print(
          '언어별: ${[for (final e in perLang.entries) '${e.key} ${e.value[0]}/${e.value[1]}'].join(' · ')}',
        );
        // ignore: avoid_print
        print('오류 종류: $errorTags');
        for (final w in wrong) {
          // ignore: avoid_print
          print('  $w');
        }
      },
      skip: key.isEmpty && replay.isEmpty ? 'DEEPSEEK_API_KEY 없음' : null,
      timeout: const Timeout(Duration(minutes: 25)),
    );
  }
}
