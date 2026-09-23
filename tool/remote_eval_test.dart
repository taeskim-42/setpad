import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/exercises.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart';
import 'question_grading.dart';

/// 문항 하나: 질문, 언어(seedNames 의 키), 갈래, 기록 이름, 정답 대안, 안 볼 키,
/// 지난 지시문 예시와 글이 같은 문항인가(v2.json 의 오염 14+1문항).
typedef _Case = ({
  String q,
  String lang,
  String cat,
  List<String> names,
  List<Object?> gold,
  List<Object?> ignore,
  bool contaminated,
});

/// 같은 질문, 같은 지시문, 같은 채점기 — 운영 모델을 직접 불러 잰다.
///
/// **test/ 밖에 둔다.** 진짜 API 를 부르고 키가 있어야 하므로 평소 스위트에
/// 섞이면 안 된다. 키가 없으면 건너뛴다. 재려면(약 257 + 212 + 295 + 48 = 812문항,
/// 사용자 승인 뒤에):
///
///     DEEPSEEK_API_KEY=... flutter test --no-pub tool/remote_eval_test.dart
///
/// 서버를 거치지 않는다 — 운영 한도를 쓰지 않으려고. 대신 설정은 서버
/// (gymdojo lib/model-json.ts)와 같게 둔다: deepseek-flash, max_tokens 400,
/// thinking 끔, json_object, 지시문 뒤에 "Return a JSON object only.".
///
/// 지시문 조립·이름 정규화·요청은 앱의 [RecordQueryAi.queryIntent] 그대로다(모델
/// 대신 대답할 자리 respond 만 끼운다). 채점은 앱이 센 plan — 모델 답이
/// [decodeRecordIntent] 를 지나고, 규칙 층을 거친 모양([groundedIntent]) — 을
/// [gradePlan] 이 설계의 뜻대로 풀어 정답과 견준다(v2 의 92.0%·93.2% 도 디코더를
/// 지난 수다). 무효는 앱 디코더의 거절(모양·한도) 또는 [planShape] 의 문법(설계
/// §3.5 + 검토 gaps) 위반이다.
///
/// 모음:
/// - v3: tool/questions/v3.json 257문항. 기록 이름은 문항마다 사람이 친 듯한 목록
///   이다 — 줄임말('벤치'·'데드'·'DL'), 별칭('스쾃'·'OHP'), 다른 언어 이름, 타이머
///   제목('푸시업 60bpm'), 사전에 없는 제 이름('홈트 서킷') 둘. 사전 정식 이름만
///   있으면 '적은 적 없다고 잘못 읽음'·'바꿔치기' 가 구조적으로 0 이다.
/// - v2: v2.json 212문항, 정답은 [v3Gold] 로 옮긴 것. 이름은 그 언어 사전 전체.
/// - heldout: v1 정답 → [v2Expected] → [v3Alternatives]. 이름은 [koNames].
/// - final: tool/questions/final.json 48문항 — **떼어 둔 최종 모음**이다. v3·v2·
///   heldout 은 지시문을 고치며 들여다본 조정용이라(heldout 도 네 번 조정에
///   쓰였다) 더는 떼어 둔 평가가 아니다. final 은 지시문을 고칠 때 보지 않고, 한
///   번만 잰다. 끝에서 N번째(오늘 vs 지난번)·그 뒤로·메모 상태·부분 합계·기준
///   수·사람 이름을 담았다.
///
/// 판정(설계 §12.3 + v3 재검토): 사람에게 답이 없는 것은 모두 deadEnd 다 — 거절,
/// 그리고 셀 수 있는 질문인데 앱이 받지 못한 무효 답·한도 거절. swapped 는 정답의
/// never 가 기록 운동으로 바뀐 것에 더해, 규칙 층이 모델도 정답도 말하지 않은 기록
/// 운동을 plan 에 넣은 것도 센다.
///
/// `EVAL_DUMP=파일` 이면 모델의 날것 대답을 JSONL 로 남긴다. `EVAL_REPLAY=파일`
/// 이면 API 대신 그 대답을 다시 먹인다 — 채점기만 바꿨을 때 모델을 다시 부르지
/// 않고 잰다(지시문을 바꿨으면 다시 불러야 한다).
///
/// 문턱(설계 §12.3 + 검토 gap 4)을 넘지 못하면 요약을 찍은 뒤 실패한다.
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
  // 질문 하나의 열쇠: 언어 + 모델에 간 글. 대답 기록(dump·replay)이 쓴다.
  String keyOf(String input) {
    final i = jsonDecode(input) as Map;
    return '${i['language']}|${i['question']}';
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

  /// 서버 라우트와 같게 — 멈춤 이유가 stop 이 아니거나 JSON 객체가 아니면
  /// 무효(FormatException)다. 그물·HTTP 실패는 IOException 이다.
  Future<Object?> ask(String instructions, String input) async {
    final k = keyOf(input);
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
      if (u['total_tokens'] case final int n) tokens += n;
      if (u['prompt_cache_hit_tokens'] case final int n) cacheHit += n;
      if (u['prompt_cache_miss_tokens'] case final int n) cacheMiss += n;
      if (u['completion_tokens'] case final int n) output += n;
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
      if (set == 'v3' || set == 'final')
        (
          q: c['q'] as String,
          lang: c['lang'] as String,
          cat: c['cat'] as String,
          names: (c['names'] as List).cast<String>(),
          gold: c['gold'] as List,
          ignore: (c['ignore'] as List?) ?? const [],
          contaminated: false,
        )
      else if (set == 'v2')
        (
          q: c['q'] as String,
          lang: c['lang'] as String,
          cat: c['cat'] as String,
          names: seedNames(c['lang'] as String),
          gold: v3Gold(c),
          ignore: (c['ignore'] as List?) ?? const [],
          contaminated: c['contaminated'] == true,
        )
      else if (v2Expected((c['expected'] as Map).cast()) case final gold?)
        (
          q: c['q'] as String,
          lang: 'ko',
          cat: c['cat'] as String,
          names: koNames,
          gold: v3Alternatives(gold),
          ignore: const [],
          contaminated: false,
        ),
  ];

  double rate(int n, int of) => of == 0 ? 0 : 100 * n / of;
  String pct(int n, int of) =>
      of == 0 ? '-' : '${rate(n, of).toStringAsFixed(1)}%';
  String tallies(Map<String, List<int>> t) => [
    for (final e in t.entries) '${e.key} ${e.value[0]}/${e.value[1]}',
  ].join(' · ');

  /// 문턱. 비율은 채점한 문항 중 %, 개수는 문항 수. 설계 §12.3 표와 검토 gap 4
  /// (falseNever·dictSwap 도 문턱). v2.json·heldout 은 v2 의 마지막 측정(v2 정확
  /// 92.0%·무효 1.9%·자신 있게 틀림 5.7%, heldout 93.2%·1.0%)에서 −1pt 까지.
  const minExact = {'v3': 85.0, 'v2': 91.0, 'heldout': 92.2, 'final': 85.0};
  const maxInvalid = {'v3': 2.0, 'v2': 2.9, 'heldout': 2.0, 'final': 2.0};
  const maxSure = {'v3': 4.0, 'v2': 5.7, 'final': 4.0};

  for (final set in ['v3', 'v2', 'heldout', 'final']) {
    test(
      '$model 로 $set 을 잰다',
      () async {
        tokens = cacheHit = cacheMiss = output = 0;
        answered = 0;
        var exact = 0, invalid = 0, unreachable = 0;
        final count = <String, int>{}; // 판정 → 문항 수 (verdicts)
        final perLang = <String, List<int>>{}; // [맞음, 채점]
        final perCat = <String, List<int>>{};
        final split = <String, List<int>>{}; // v2: 오염 / 깨끗
        final errorTags = <String, int>{}, wrong = <String>[];
        final queue = cases(set);
        final total = queue.length;

        Future<void> worker() async {
          while (queue.isNotEmpty) {
            final c = queue.removeAt(0);
            final tallies = [
              perLang.putIfAbsent(c.lang, () => [0, 0]),
              perCat.putIfAbsent(c.cat, () => [0, 0]),
              if (set == 'v2')
                split.putIfAbsent(c.contaminated ? '오염' : '깨끗', () => [0, 0]),
            ];
            String raw() => contents[c.q] ?? '';
            Object? plan;
            Map<String, Object?>? grounded;
            Grade grade;
            try {
              plan = await runZoned(
                () => ai.queryIntent(
                  c.q,
                  c.lang.replaceAll('_', '-'),
                  c.names,
                  unit: 'kg',
                  today: evalToday,
                ),
                zoneValues: {#question: c.q},
              );
              // 앱이 센 것을 채점한다: 디코더가 거절하면(모양·한도) 무효고,
              // 받으면 규칙 층을 지난 plan 이 화면의 답이다.
              final read = decodeRecordIntent(
                plan,
                c.q,
                c.names,
                unit: 'kg',
                today: evalToday,
                locale: c.lang.replaceAll('_', '-'),
              );
              // 앱이 거절로 읽었으면 그 거절이 답이다(셀 것이 남지 않은 plan 포함).
              grounded = read.kind == 'unsupported'
                  ? switch (read.reason) {
                      'unrelated' => {'kind': 'unrelated'},
                      'nothing' => {'notComputable': read.notComputable},
                      _ => {'kind': 'clarify'},
                    }
                  : groundedIntent(plan as Map, c.q, c.names, today: evalToday);
              grade = gradePlan(
                grounded,
                c.gold,
                names: c.names,
                lang: c.lang,
                question: c.q,
                ignore: c.ignore,
                // 모델이 적은 이름은 앱이 푸는 대로 푼다(swapped 가 앱과 같다).
                resolve: (n) => resolvedExercise(n, c.names, lang: c.lang),
              );
            } on IOException catch (err) {
              // 모델 탓이 아니다. 채점에서 뺀다.
              unreachable++;
              wrong.add('${c.q} → 호출 실패 $err');
              continue;
            } on FormatException catch (err) {
              invalid++;
              for (final t in tallies) {
                t[1]++;
              }
              // 셀 수 있는 질문인데 앱이 받지 못했다(모양 실수·한도) — 사람에게는
              // 답이 없다.
              final dead = goldCountable(
                c.gold,
                names: c.names,
                lang: c.lang,
                question: c.q,
              );
              if (dead) count['deadEnd'] = (count['deadEnd'] ?? 0) + 1;
              wrong.add(
                '[${c.lang} ${c.cat}]${dead ? ' <deadEnd>' : ''} ${c.q} → 무효 ${err.message} ⟨${raw()}⟩',
              );
              continue;
            }
            for (final t in tallies) {
              t[1]++;
            }
            final v = {
              ...verdicts(grade),
              // 규칙 층이 모델도 정답도 말하지 않은 기록 운동을 넣었다(베트남어
              // 'chung' → 런지). 모델 답의 이름과 견준다.
              if (ruleSwapped(
                plan,
                grade,
                names: c.names,
                lang: c.lang,
                question: c.q,
                resolve: (n) => resolvedExercise(n, c.names, lang: c.lang),
              ))
                'swapped',
            };
            for (final flag in v) {
              count[flag] = (count[flag] ?? 0) + 1;
            }
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
              '${grade.errors} ⟨${jsonEncode(plan)}⟩'
              '${jsonEncode(grounded) == jsonEncode(plan) ? '' : ' 규칙 층 → ⟨${jsonEncode(grounded)}⟩'}',
            );
          }
        }

        await Future.wait([for (var i = 0; i < 4; i++) worker()]);
        await dump?.flush();
        final graded = total - unreachable;
        int n(String flag) => count[flag] ?? 0;
        final avgTokens = answered == 0 ? 0 : tokens ~/ answered;
        // ignore: avoid_print
        print(
          '$model $set: 정확 $exact/$graded = ${pct(exact, graded)} · '
          '무효 ${pct(invalid, graded)} · 자신 있게 틀림 ${pct(n('confidentlyWrong'), graded)} · '
          '거절 ${n('refused')} · 호출 실패 $unreachable · 평균 토큰 $avgTokens',
        );
        // ignore: avoid_print
        print(
          '$set 지표: deadEnd ${n('deadEnd')} · swapped ${n('swapped')} · '
          'falseNever ${n('falseNever')} · dictSwap ${n('dictSwap')} · '
          'ncMissed ${n('ncMissed')} (${pct(n('ncMissed'), graded)}) · ncFalse ${n('ncFalse')} · '
          'exact ${pct(exact, graded)} · invalid ${pct(invalid, graded)} · '
          'confidentlyWrong ${pct(n('confidentlyWrong'), graded)}',
        );
        if (answered > 0 && replay.isEmpty) {
          // ignore: avoid_print
          print(
            '$set 토큰(평균): 캐시 적중 ${cacheHit ~/ answered} · '
            '캐시 빗나감 ${cacheMiss ~/ answered} · 출력 ${output ~/ answered}',
          );
        }
        // ignore: avoid_print
        print('언어별: ${tallies(perLang)}');
        // ignore: avoid_print
        print('갈래별: ${tallies(perCat)}');
        if (set == 'v2') {
          // ignore: avoid_print
          print('v2 지난 지시문 예시와 같은 문항(오염)/그 밖: ${tallies(split)}');
        }
        // ignore: avoid_print
        print('오류 종류: $errorTags');
        for (final w in wrong) {
          // ignore: avoid_print
          print('  $w');
        }

        final failed = [
          for (final flag in const [
            'deadEnd',
            'swapped',
            'falseNever',
            'dictSwap',
          ])
            if (n(flag) > 0) '$flag ${n(flag)} > 0',
          if (rate(exact, graded) < minExact[set]!)
            'exact ${pct(exact, graded)} < ${minExact[set]}%',
          if (maxSure[set] case final max?
              when rate(n('confidentlyWrong'), graded) > max)
            'confidentlyWrong ${pct(n('confidentlyWrong'), graded)} > $max%',
          if (rate(invalid, graded) > maxInvalid[set]!)
            'invalid ${pct(invalid, graded)} > ${maxInvalid[set]}%',
          if (set == 'v3') ...[
            if (rate(n('ncMissed'), graded) > 3)
              'ncMissed ${pct(n('ncMissed'), graded)} > 3%',
            for (final e in perCat.entries)
              if (rate(e.value[0], e.value[1]) < 70)
                '갈래 ${e.key} ${pct(e.value[0], e.value[1])} < 70%',
            for (final e in perLang.entries)
              if (rate(e.value[0], e.value[1]) < 80)
                '언어 ${e.key} ${pct(e.value[0], e.value[1])} < 80%',
          ],
          if ((set == 'v3' || set == 'final') &&
              replay.isEmpty &&
              avgTokens > 2600)
            '평균 토큰 $avgTokens > 2600',
        ];
        // ignore: avoid_print
        print('$set 문턱: ${failed.isEmpty ? '모두 넘음' : failed.join(' · ')}');
        expect(failed, isEmpty);
      },
      skip: key.isEmpty && replay.isEmpty ? 'DEEPSEEK_API_KEY 없음' : null,
      timeout: const Timeout(Duration(minutes: 25)),
    );
  }
}
