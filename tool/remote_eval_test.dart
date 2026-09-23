import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart';
import 'outcome_grading.dart';
import 'question_grading.dart';

/// 같은 질문, 같은 지시문, 같은 채점기 — 운영 모델을 직접 불러 잰다.
///
/// **test/ 밖에 둔다.** 진짜 API 를 부르고 키가 있어야 하므로 평소 스위트에
/// 섞이면 안 된다. 키가 없으면 건너뛴다. 모음 다섯 개 약 1,060문항이라 2분을
/// 넘는다 — 백그라운드로 돌리고 로그를 본다:
///
///     DEEPSEEK_API_KEY=... EVAL_DUMP=run.jsonl \
///       flutter test --no-pub tool/remote_eval_test.dart > run.log 2>&1
///
/// 환경 변수:
/// - `EVAL_MODEL`: 부를 모델(기본 deepseek-flash, 운영과 같다).
/// - `EVAL_SETS`: 잴 모음, 쉼표로(기본 v3,v2,heldout,final,blind).
/// - `EVAL_DUMP=파일`: 모델의 날것 대답을 JSONL 로 남긴다.
/// - `EVAL_STAGE2=single|all`: 대조 실험. 1단계를 부르지 않는다. single 은 한
///   지시문(기준선), all 은 모든 갈래를 실은 2단계 지시문 하나로 묻는다.
/// - `EVAL_TEMPERATURE`: 기본 0 — 서버(record-query 의 ask)와 같다. 대조 실험은
///   다른 값을 준다('none' 이면 보내지 않는다: 공급자 기본값).
/// - `EVAL_REPLAY=파일`: API 대신 그 대답을 다시 먹인다 — 채점기·디코더·실행기만
///   바꿨을 때 모델을 다시 부르지 않고 잰다(지시문을 바꿨으면 다시 불러야 한다).
///   대답이 없는 문항은 '호출 실패' 로 빠진다.
///
/// 서버를 거치지 않는다 — 운영 한도를 쓰지 않으려고. 대신 설정은 서버
/// (gymdojo lib/model-json.ts)와 같게 둔다: max_tokens 400, temperature 0,
/// thinking 끔, json_object, 지시문 뒤에 "Return a JSON object only.". 지시문 조립·이름
/// 정규화·요청은 앱의 [RecordQueryAi.queryIntent] 그대로다.
///
/// **채점은 결과로 한다(outcome_grading.dart).** 정답 plan 과 모델 plan 을 둘 다
/// 앱의 디코더([decodeRecordIntent])와 실행기([runPlan])에 넣고, 같은 가정 기록
/// ([assumedLog])에서 사람이 보는 표를 견준다: 같은 줄, 정답이 물은 측정이 모두
/// 같은 값(개수는 정확히, 그 밖은 ±0.5%), 같은 까닭(적은 적 없음·범위에 없음·아직
/// 안 옴), 같은 '못 보는 것' 줄. 칸을 더 보이는 것은 괜찮다. 정답은 뜻 그대로라
/// 규칙 층을 지나지 않고, 모델 답은 앱처럼 규칙 층을 지난다. plan 모양 채점
/// ([gradePlan])은 보조 줄로 남긴다.
///
/// 모음:
/// - v3(257)·v2(212)·heldout(295)·final(48): 지시문을 고치며 들여다본 조정용이다.
///   final 도 두 번 재고 그 뒤 지시문을 고쳤다.
/// - blind: tool/questions/blind.json — **떼어 둔 모음**. 끝에서 N번째(오늘 vs
///   지난번)·전후·그 뒤로·최근 N번을 사람이 친 기록 이름('민수식 로우 2'·'렛풀')과
///   함께 담았다. 지시문을 고칠 때 이 모음의 실패를 보지 않는다.
///
/// 판정([outcomeVerdicts]): deadEnd 는 정답은 세는데 거절·무효인 것, swapped 는
/// 정답의 적은 적 없는 운동 대신 기록 운동을 센 것.
///
/// 문턱을 넘지 못하면 요약을 찍은 뒤 실패한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting());
  final env = Platform.environment;
  final model = env['EVAL_MODEL'] ?? 'deepseek-flash';
  final key = env['DEEPSEEK_API_KEY'] ?? '';
  final stage2 = env['EVAL_STAGE2'];
  // 서버(gymdojo lib/record-query.ts)는 기록 질문에 temperature 0 을 보낸다.
  final temperature = double.tryParse(env['EVAL_TEMPERATURE'] ?? '0');
  final dump = switch (env['EVAL_DUMP']) {
    final String path => File(path).openWrite(),
    null => null,
  };
  final replay = <String, String>{
    if (env['EVAL_REPLAY'] case final String path)
      for (final line in File(path).readAsLinesSync())
        if (jsonDecode(line) case {
          'key': final String k,
          'content': final String c,
        })
          k: c,
  };
  // 부른 한 번의 열쇠: 단계 + 언어 + 모델에 간 글. 대답 기록(dump·replay)이 쓴다.
  // 한 지시문은 옛 열쇠 그대로, 1단계는 'cls|', 2단계는 지시문의 지문(갈래 조합).
  String keyOf(String instructions, String input) {
    final i = jsonDecode(input) as Map;
    final stage = instructions == familyInstructions
        ? 'cls|'
        : instructions == planInstructions
        ? ''
        : '${instructions.codeUnits.fold(7, (h, c) => (h * 31 + c) & 0xFFFFFFF)}|';
    return '$stage${i['language']}|${i['question']}';
  }

  // 실패 줄에 날것을 보이려고 문항 글로도 담는다(요청은 zone 이 문항을 안다).
  final contents = <String, String>{};
  void keep(String k, String content) {
    contents[k] = content;
    if (Zone.current[#question] case final String q) contents[q] = content;
  }

  // flutter_test 는 모든 HTTP 를 막는 가짜 클라이언트를 끼운다. 이 평가는
  // 진짜 API 를 불러야 하므로 그 가로채기를 끈다.
  HttpOverrides.global = null;
  final client = HttpClient();
  var tokens = 0, answered = 0, cacheHit = 0, cacheMiss = 0, output = 0;
  var stage1 = 0, hit1 = 0, miss1 = 0, out1 = 0; // 1단계(갈래 고르기)가 쓴 토큰

  /// 서버 라우트와 같게 — 멈춤 이유가 stop 이 아니거나 JSON 객체가 아니면
  /// 무효(FormatException)다. 그물·HTTP 실패는 IOException 이다.
  Future<Object?> ask(String instructions, String input) async {
    // 대조 실험: 1단계를 부르지 않는다. single 은 꼬리표 없는 답을 주어 한
    // 지시문(planInstructions, 기준선)으로, all 은 2단계에 모든 갈래를 싣는다.
    if (stage2 != null && instructions == familyInstructions) {
      return stage2 == 'single' ? <String, Object?>{} : {'t': <String>[]};
    }
    if (stage2 == 'all') {
      instructions = focusedInstructions(planFamilies.toSet());
    }
    final k = keyOf(instructions, input);
    if (replay.isNotEmpty) {
      final content = replay[k] ?? (throw HttpException('replay 에 없음 $k'));
      keep(k, content);
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
          'temperature': ?temperature,
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
    if (body['usage'] case final Map u) {
      final first = instructions == familyInstructions;
      if (u['total_tokens'] case final int n) {
        tokens += n;
        if (first) stage1 += n;
      }
      if (u['prompt_cache_hit_tokens'] case final int n) {
        cacheHit += n;
        if (first) hit1 += n;
      }
      if (u['prompt_cache_miss_tokens'] case final int n) {
        cacheMiss += n;
        if (first) miss1 += n;
      }
      if (u['completion_tokens'] case final int n) {
        output += n;
        if (first) out1 += n;
      }
    }
    final choice = (body['choices'] as List).first as Map;
    final content = (choice['message'] as Map?)?['content'];
    if (content is String) {
      keep(k, content);
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

  double rate(int n, int of) => of == 0 ? 0 : 100 * n / of;
  String pct(int n, int of) =>
      of == 0 ? '-' : '${rate(n, of).toStringAsFixed(1)}%';
  String tallies(Map<String, List<int>> t) => [
    for (final e in t.entries) '${e.key} ${e.value[0]}/${e.value[1]}',
  ].join(' · ');
  String cut(Object? o, [int max = 400]) {
    final s = '$o';
    return s.length <= max ? s : '${s.substring(0, max)}…';
  }

  /// 문턱. 비율은 채점한 문항 중 %, 개수는 문항 수. v2.json·heldout 은 v2 의
  /// 마지막 측정(v2 정확 92.0%·무효 1.9%·자신 있게 틀림 5.7%, heldout 93.2%·1.0%)
  /// 에서 −1pt 까지. 평균 토큰은 v2 시절 약 1,960 + 25%.
  const minExact = {
    'v3': 85.0,
    'v2': 91.0,
    'heldout': 92.2,
    'final': 85.0,
    'blind': 85.0,
  };
  const maxInvalid = {
    'v3': 2.0,
    'v2': 2.9,
    'heldout': 2.0,
    'final': 2.0,
    'blind': 2.0,
  };
  const maxSure = {'v3': 4.0, 'v2': 5.7, 'final': 4.0, 'blind': 4.0};
  const maxTokens = 2450;

  final sets = (env['EVAL_SETS'] ?? 'v3,v2,heldout,final,blind').split(',');
  for (final set in sets) {
    test(
      '$model 로 $set 을 잰다',
      () async {
        tokens = cacheHit = cacheMiss = output = stage1 = hit1 = miss1 = out1 =
            0;
        answered = 0;
        var asked = 0; // 모델이 답한 질문 수(부른 횟수가 아니다)
        var exact = 0, invalid = 0, unreachable = 0, shapeExact = 0;
        var shapeInvalid = 0, goldBroken = 0;
        final count = <String, int>{}; // 판정 → 문항 수
        final perLang = <String, List<int>>{}; // [맞음, 채점]
        final perCat = <String, List<int>>{};
        final shapeCat = <String, List<int>>{};
        final split = <String, List<int>>{}; // v2: 오염 / 깨끗
        final errorTags = <String, int>{}, wrong = <String>[];
        final queue = evalCases(set.trim());
        final total = queue.length;

        Future<void> worker() async {
          while (queue.isNotEmpty) {
            final c = queue.removeAt(0);
            final log = assumedLog(c.names, c.lang);
            final locale = c.lang.replaceAll('_', '-');
            final wants = <Visible>[];
            for (final g in c.gold) {
              try {
                wants.add(goldVisible(g, c.names, c.lang, log));
              } on StateError catch (e) {
                wrong.add('[${c.lang} ${c.cat}] <정답 오류> ${c.q} → ${e.message}');
              }
            }
            if (wants.isEmpty) {
              goldBroken++;
              continue;
            }
            String raw() => contents[c.q] ?? '';
            Object? plan;
            Visible? got;
            String? why;
            try {
              plan = await runZoned(
                () => ai.queryIntent(
                  c.q,
                  locale,
                  c.names,
                  unit: 'kg',
                  today: evalToday,
                ),
                zoneValues: {#question: c.q},
              );
              asked++;
              // 앱이 센 것: 디코더(규칙 층 포함)가 받은 plan 을 가정 기록에 돌린다.
              got = visible(
                decodeRecordIntent(
                  plan,
                  c.q,
                  c.names,
                  unit: 'kg',
                  today: evalToday,
                  locale: locale,
                ),
                log,
                evalL(c.lang),
              );
            } on IOException catch (err) {
              // 모델 탓이 아니다. 채점에서 뺀다.
              unreachable++;
              wrong.add('${c.q} → 호출 실패 $err');
              continue;
            } on FormatException catch (err) {
              asked++;
              why = err.message;
            }
            final grade = gradeOutcome(wants, got, ignore: c.ignore);
            final v = outcomeVerdicts(grade);

            // 보조: plan 모양 채점(설계 §3.5 문법, 이전 채점기).
            var shapeOk = false;
            Map<String, Object?>? grounded;
            if (got != null && plan is Map) {
              try {
                final read = decodeRecordIntent(
                  plan,
                  c.q,
                  c.names,
                  unit: 'kg',
                  today: evalToday,
                  locale: locale,
                );
                grounded = read.kind == 'unsupported'
                    ? switch (read.reason) {
                        'unrelated' => {'kind': 'unrelated'},
                        'nothing' => {'notComputable': read.notComputable},
                        _ => {'kind': 'clarify'},
                      }
                    : groundedIntent(plan, c.q, c.names, today: evalToday);
                shapeOk = gradePlan(
                  grounded,
                  c.gold,
                  names: c.names,
                  lang: c.lang,
                  question: c.q,
                  ignore: c.ignore,
                  resolve: (n) => resolvedExercise(n, c.names, lang: c.lang),
                ).errors.isEmpty;
              } on FormatException {
                shapeInvalid++;
              } on StateError {
                // 정답이 옛 문법(planShape)에 없는 모양이다 — 보조 채점만 못 한다.
              }
            } else {
              shapeInvalid++;
            }
            if (shapeOk) shapeExact++;
            shapeCat.putIfAbsent(c.cat, () => [0, 0])
              ..[0] += shapeOk ? 1 : 0
              ..[1] += 1;

            final tallies = [
              perLang.putIfAbsent(c.lang, () => [0, 0]),
              perCat.putIfAbsent(c.cat, () => [0, 0]),
              if (set == 'v2')
                split.putIfAbsent(c.contaminated ? '오염' : '깨끗', () => [0, 0]),
            ];
            for (final t in tallies) {
              t[1]++;
            }
            for (final flag in v) {
              count[flag] = (count[flag] ?? 0) + 1;
            }
            if (got == null) invalid++;
            if (v.contains('exact')) {
              exact++;
              for (final t in tallies) {
                t[0]++;
              }
              continue;
            }
            for (final e in grade.errors) {
              errorTags[e] = (errorTags[e] ?? 0) + 1;
            }
            final marks = v.difference({'confidentlyWrong'}).join(',');
            wrong.add(
              '[${c.lang} ${c.cat}]${marks.isEmpty ? '' : ' <$marks>'} ${c.q} → '
              '${grade.errors}${why == null ? '' : ' 무효 $why'} ⟨${plan == null ? raw() : jsonEncode(plan)}⟩'
              '${grounded == null || jsonEncode(grounded) == jsonEncode(plan) ? '' : ' 규칙 층 → ⟨${jsonEncode(grounded)}⟩'}'
              '\n      정답 ${cut(grade.want)}\n      모델 ${cut(grade.got)}',
            );
          }
        }

        await Future.wait([for (var i = 0; i < 4; i++) worker()]);
        await dump?.flush();
        final graded = total - unreachable - goldBroken;
        int n(String flag) => count[flag] ?? 0;
        // 질문 하나가 쓴 토큰(두 단계면 두 번 부른 합).
        final avgTokens = asked == 0 || replay.isNotEmpty ? 0 : tokens ~/ asked;
        // ignore: avoid_print
        print(
          '$model $set: 정확 $exact/$graded = ${pct(exact, graded)} · '
          '무효 ${pct(invalid, graded)} · 자신 있게 틀림 ${pct(n('confidentlyWrong'), graded)} · '
          '거절 ${n('refused')} · 호출 실패 $unreachable · 평균 토큰 $avgTokens',
        );
        // ignore: avoid_print
        print(
          '$set 지표(결과): deadEnd ${n('deadEnd')} · swapped ${n('swapped')} · '
          'falseNever ${n('falseNever')} · dictSwap ${n('dictSwap')} · '
          'ncMissed ${n('ncMissed')} (${pct(n('ncMissed'), graded)}) · ncFalse ${n('ncFalse')} · '
          'exact ${pct(exact, graded)} · invalid ${pct(invalid, graded)} · '
          'confidentlyWrong ${pct(n('confidentlyWrong'), graded)}'
          '${goldBroken == 0 ? '' : ' · 정답 오류 $goldBroken'}',
        );
        // ignore: avoid_print
        print(
          '$set 모양 채점(보조): 정확 $shapeExact/$graded = ${pct(shapeExact, graded)} · '
          '무효(문법 포함) ${pct(shapeInvalid, graded)}',
        );
        if (answered > 0 && replay.isEmpty) {
          // ignore: avoid_print
          print(
            '$set 토큰(질문당 평균): 합 $avgTokens = 1단계 ${stage1 ~/ asked} + '
            '2단계 ${(tokens - stage1) ~/ asked} · 캐시 적중 ${cacheHit ~/ asked} · '
            '캐시 빗나감 ${cacheMiss ~/ asked} · 출력 ${output ~/ asked} · 부른 횟수 $answered',
          );
          // 원가: deepseek-flash 피크 단가(gymdojo lib/plate-pricing.ts PEAK_USD_PER_M —
          // 적중 0.006, 빗나감 0.3, 출력 1.2 USD/백만). 원판은 셋을 같은 값으로 센다.
          double usd(int hit, int miss, int out) =>
              (hit * 0.006 + miss * 0.3 + out * 1.2) / asked / 1e6 * 10000;
          // ignore: avoid_print
          print(
            '$set 단계별(질문당): 1단계 적중 ${hit1 ~/ asked} · 빗나감 ${miss1 ~/ asked} · '
            '출력 ${out1 ~/ asked} / 2단계 적중 ${(cacheHit - hit1) ~/ asked} · '
            '빗나감 ${(cacheMiss - miss1) ~/ asked} · 출력 ${(output - out1) ~/ asked} · '
            '원가(피크) 1만 질문당 \$${usd(cacheHit, cacheMiss, output).toStringAsFixed(2)} '
            '(1단계 \$${usd(hit1, miss1, out1).toStringAsFixed(2)})',
          );
        }
        // ignore: avoid_print
        print('언어별(결과): ${tallies(perLang)}');
        // ignore: avoid_print
        print('갈래별(결과): ${tallies(perCat)}');
        // ignore: avoid_print
        print('갈래별(모양): ${tallies(shapeCat)}');
        if (set == 'v2') {
          // ignore: avoid_print
          print('v2 지난 지시문 예시와 같은 문항(오염)/그 밖: ${tallies(split)}');
        }
        // ignore: avoid_print
        print('어긋남 종류(결과): $errorTags');
        // 떼어 둔 모음은 틀린 문항을 찍지 않는다 — 지시문을 고치는 사람이 보고
        // 맞추면 더는 떼어 둔 모음이 아니다. 갈래별 수만 본다.
        for (final w in set == 'blind' ? const <String>[] : wrong) {
          // ignore: avoid_print
          print('  $w');
        }

        final failed = [
          for (final flag in const ['deadEnd', 'swapped'])
            if (n(flag) > 0) '$flag ${n(flag)} > 0',
          if (rate(exact, graded) < minExact[set]!)
            'exact ${pct(exact, graded)} < ${minExact[set]}%',
          if (maxSure[set] case final max?
              when rate(n('confidentlyWrong'), graded) > max)
            'confidentlyWrong ${pct(n('confidentlyWrong'), graded)} > $max%',
          if (rate(invalid, graded) > maxInvalid[set]!)
            'invalid ${pct(invalid, graded)} > ${maxInvalid[set]}%',
          if (replay.isEmpty && avgTokens > maxTokens)
            '평균 토큰 $avgTokens > $maxTokens',
          if (goldBroken > 0) '정답 오류 $goldBroken',
        ];
        // ignore: avoid_print
        print('$set 문턱: ${failed.isEmpty ? '모두 넘음' : failed.join(' · ')}');
        expect(failed, isEmpty);
      },
      skip: key.isEmpty && replay.isEmpty ? 'DEEPSEEK_API_KEY 없음' : null,
      timeout: const Timeout(Duration(minutes: 40)),
    );
  }
}
