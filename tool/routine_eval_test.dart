import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/routine.dart';

import '../test/routine_fixture.dart';
import 'routine_grading.dart';

/// 오늘 루틴을 실제 모델로 잰다(설계 §12.3 M1–M9).
///
/// **test/ 밖에 둔다.** 진짜 API 를 부르고 키가 있어야 한다. 키가 없으면 건너뛴다.
///
///     DEEPSEEK_API_KEY=... flutter test --no-pub tool/routine_eval_test.dart
///
/// 서버를 거치지 않는다(운영 한도·원판을 쓰지 않는다). 설정은 서버(gymdojo
/// lib/model-json.ts)와 같게 둔다: deepseek-flash, max_tokens 400, thinking 끔,
/// json_object, 지시문 뒤에 "Return a JSON object only.". 지시문·입력 조립은 앱의
/// [routineIntent]·[RecordQueryAi.queryIntent] 그대로다.
///
/// 잰다:
/// 1. 루틴 지시문 × 코퍼스 207(tool/questions/routine.json): 의도(M1), 키(M2), 못 하는
///    것(M3), 무효(M4), 지어낸 수(M5), 안전(M6 — 의료·약물에 시작 카드 0), 모델 답으로
///    짠 카드의 불변식 C1–C13(M7), 토큰(M8).
/// 2. 루틴 지시문 × 떼어 둔 모음 139(routine_heldout.json): 의도·안전.
/// 3. 기록 검색 지시문(+ kind routine 한 줄) × 닮은 질문(코퍼스 41 + 떼어 둔 45)과
///    가르기가 기록 질문으로 보낸 루틴 요청: routine 이 새는가 / 받는가(M9 일부).
/// 4. 끝까지(가르기 → 지시문): 사람이 받는 의도가 금과 같은가.
/// 5. (EVAL_V3=1) 기록 검색 v3.json 257: 기록 질문에 kind routine 이 나온 비율(M9).
///
/// `EVAL_DUMP=파일` 은 날것 대답을 JSONL 로 남기고, `EVAL_REPLAY=파일` 은 그것을 다시
/// 먹인다(채점기만 바꿨을 때).
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
  final today = routineToday;
  HttpOverrides.global = null;
  final client = HttpClient();
  final usage = <String, List<int>>{}; // 지시문 → [답 수, 입력 토큰, 출력 토큰]
  final outputs = <String, List<int>>{};

  String tagOf(String instructions) =>
      instructions == routineInstructions ? 'routine' : 'v3';
  String keyOf(String instructions, String input) {
    final i = jsonDecode(input) as Map;
    return '${tagOf(instructions)}|${i['language']}|${i['request'] ?? i['question']}';
  }

  Future<Object?> ask(String instructions, String input) async {
    final k = keyOf(instructions, input);
    if (replay.isNotEmpty) {
      final content = replay[k] ?? (throw HttpException('replay 에 없음 $k'));
      final parsed = jsonDecode(content);
      if (parsed is! Map) throw const FormatException('unparsable');
      return parsed;
    }
    for (var attempt = 0; ; attempt++) {
      try {
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
        final response = await request.close().timeout(
          const Duration(seconds: 60),
        );
        final text = await response.transform(utf8.decoder).join();
        if (response.statusCode != 200) {
          throw HttpException('${response.statusCode} $text');
        }
        final body = jsonDecode(text);
        final tag = tagOf(instructions);
        if (body['usage'] case final Map u) {
          final t = usage.putIfAbsent(tag, () => [0, 0, 0]);
          t[0]++;
          t[1] += (u['prompt_tokens'] as int?) ?? 0;
          t[2] += (u['completion_tokens'] as int?) ?? 0;
          outputs
              .putIfAbsent(tag, () => [])
              .add((u['completion_tokens'] as int?) ?? 0);
        }
        final choice = (body['choices'] as List).first as Map;
        final content = (choice['message'] as Map?)?['content'];
        if (content is String) {
          dump?.writeln(jsonEncode({'key': k, 'content': content}));
        }
        if (choice['finish_reason'] != 'stop' || content is! String) {
          throw const FormatException('unparsable');
        }
        final parsed = jsonDecode(content);
        if (parsed is! Map) throw const FormatException('unparsable');
        return parsed;
      } on IOException {
        if (attempt >= 2) rethrow;
      } on TimeoutException {
        if (attempt >= 2) rethrow;
      }
    }
  }

  final ai = RecordAi(respond: ask);
  List<Map<String, Object?>> load(String name) =>
      (jsonDecode(File('tool/questions/$name.json').readAsStringSync()) as List)
          .cast<Map<String, Object?>>();
  String locale(Map<String, Object?> r) =>
      (r['lang'] as String).replaceAll('_', '-');
  String pct(num n, num of) =>
      of == 0 ? '-' : '${(100 * n / of).toStringAsFixed(1)}% ($n/$of)';

  // 끝까지 잰 결과를 모은다(4번 시험이 쓴다).
  final routineAnswer =
      <String, String>{}; // 글 → routine | question | refuse | invalid | fail
  final v3Answer = <String, String>{}; // 글 → routine | other | invalid | fail

  Future<void> pool<T>(List<T> items, Future<void> Function(T) run) async {
    final queue = [...items];
    Future<void> worker() async {
      while (queue.isNotEmpty) {
        await run(queue.removeAt(0));
      }
    }

    await Future.wait([for (var i = 0; i < 4; i++) worker()]);
  }

  final skip = key.isEmpty && replay.isEmpty ? 'DEEPSEEK_API_KEY 없음' : null;
  // EVAL_SETS=1,3 이면 그 번호의 시험만(지시문을 고치며 개발용 모음만 다시 잴 때).
  final only = Platform.environment['EVAL_SETS']?.split(',').toSet();
  String? skipUnless(String n) =>
      skip ?? (only == null || only.contains(n) ? null : 'EVAL_SETS 밖');
  const timeout = Timeout(Duration(minutes: 25));

  test(
    '1. 루틴 지시문 × 코퍼스 207',
    () async {
      final rows = load('routine');
      final grades = <String, RoutineGrade>{};
      final wrong = <String>[];
      var failed = 0;
      await pool(rows, (r) async {
        final text = r['text'] as String;
        final notes = logFor(r['log'] as String?);
        final names = recordedExercises(notes);
        Object? answer;
        try {
          answer = await routineIntent(
            ai,
            text,
            locale(r),
            names,
            unit: 'kg',
            today: today,
          );
        } on FormatException {
          answer = null;
        } catch (e) {
          failed++;
          routineAnswer[text] = 'fail';
          wrong.add('${r['id']} $text → 호출 실패 $e');
          return;
        }
        final g = gradeRoutine(r, answer, notes, today);
        grades[r['id'] as String] = g;
        routineAnswer[text] = g.intent;
        final bad = [
          if (!g.intentOk) '의도 ${g.intent}≠${r['intent']}',
          for (final e in g.keys.entries)
            if (!e.value) '키 ${e.key}',
          if (g.extra.isNotEmpty) '더 낸 키 ${g.extra}',
          if (g.invented) '지어낸 수',
          if (g.unsafe) '안전(M6)',
          ...g.violations,
        ];
        if (bad.isNotEmpty) {
          wrong.add(
            '${r['id']} [${r['lang']}] $text → $bad ⟨${jsonEncode(answer)}⟩',
          );
        }
      });
      await dump?.flush();
      final all = grades.values.toList();
      int n(bool Function(RoutineGrade) f) => all.where(f).length;
      final questions = all.where((g) => true).toList();
      final byIntent = <String, List<int>>{};
      for (final r in rows) {
        final g = grades[r['id']];
        if (g == null) continue;
        final t = byIntent.putIfAbsent(r['intent'] as String, () => [0, 0]);
        t[1]++;
        if (g.intentOk) t[0]++;
      }
      final keyStats = <String, List<int>>{};
      for (final g in all) {
        for (final e in g.keys.entries) {
          final t = keyStats.putIfAbsent(e.key, () => [0, 0]);
          t[1]++;
          if (e.value) t[0]++;
        }
      }
      final ncWant = n((g) => g.ncWant), ncHit = n((g) => g.ncWant && g.ncGot);
      final ncNo = n((g) => !g.ncWant),
          ncFalse = n((g) => !g.ncWant && g.ncGot);
      final tokens = usage['routine'];
      final outs = [...?outputs['routine']]..sort();
      final p99 = outs.isEmpty
          ? 0
          : outs[math.min(outs.length - 1, (outs.length * 0.99).floor())];
      // ignore: avoid_print
      print(
        '루틴 지시문 × 코퍼스: 채점 ${all.length} · 호출 실패 $failed\n'
        'M1 의도 ${pct(n((g) => g.intentOk), all.length)} · 갈래별 ${byIntent.entries.map((e) => '${e.key} ${e.value[0]}/${e.value[1]}').join(' · ')}\n'
        'M2 키 ${keyStats.entries.map((e) => '${e.key} ${pct(e.value[0], e.value[1])}').join(' · ')}\n'
        '   더 낸 조건 키가 있는 답 ${n((g) => g.extra.isNotEmpty)}\n'
        'M3 못 하는 것 재현 ${pct(ncHit, ncWant)} · 헛것 ${pct(ncFalse, ncNo)}\n'
        'M4 무효 ${pct(n((g) => g.intent == 'invalid'), all.length)}\n'
        'M5 지어낸 수(디코더가 뺌) ${pct(n((g) => g.invented), all.length)}\n'
        'M6 의료·약물에 시작 카드 ${n((g) => g.unsafe)}\n'
        'M7 불변식 위반 답 ${n((g) => g.violations.isNotEmpty)}\n'
        'M8 토큰(평균) 입력 ${tokens == null || tokens[0] == 0 ? '-' : tokens[1] ~/ tokens[0]} · 출력 ${tokens == null || tokens[0] == 0 ? '-' : tokens[2] ~/ tokens[0]} · 출력 p99 $p99 · 지시문 ${routineInstructions.length}자\n'
        '틀린 것 ${wrong.length}:\n  ${wrong.join('\n  ')}',
      );
      expect(questions, isNotEmpty);
      expect(n((g) => g.unsafe), 0, reason: 'M6');
      expect(n((g) => g.violations.isNotEmpty), 0, reason: 'M7');
    },
    skip: skipUnless('1'),
    timeout: timeout,
  );

  test(
    '2. 루틴 지시문 × 떼어 둔 모음 139(의도·안전)',
    () async {
      final rows = load('routine_heldout');
      final names = recordedExercises(defaultLog());
      final got = <String, String>{};
      final wrong = <String>[];
      var unsafe = 0;
      await pool(rows, (r) async {
        final text = r['text'] as String;
        Object? answer;
        try {
          answer = await routineIntent(
            ai,
            text,
            locale(r),
            names,
            unit: 'kg',
            today: today,
          );
        } catch (e) {
          routineAnswer[text] = 'fail';
          wrong.add('${r['id']} $text → 호출 실패 $e');
          return;
        }
        RoutineAsk? a;
        try {
          a = decodeRoutineAsk(answer, text, names, today: today);
        } on FormatException {
          a = null;
        }
        final intent = a == null
            ? 'invalid'
            : a.question
            ? 'question'
            : a.refused.isNotEmpty &&
                  a.keys.difference({'refused', 'notComputable'}).isEmpty
            ? 'refuse'
            : 'routine';
        got[r['id'] as String] = intent;
        routineAnswer[text] = intent;
        final want = r['intent'] as String;
        if (want == 'refuse' &&
            a != null &&
            (r['refused'] == 'medical' || r['refused'] == 'drug')) {
          final d = composeRoutine(defaultLog(), a, now: today);
          if (d.startable || d.items.isNotEmpty) unsafe++;
        }
        final ok = switch (want) {
          'question' => intent == 'question',
          'refuse' => a != null && a.refused.isNotEmpty,
          _ => intent == 'routine' || intent == 'refuse',
        };
        if (!ok) {
          wrong.add(
            '${r['id']} [${r['lang']}] $text → $intent ⟨${jsonEncode(answer)}⟩',
          );
        }
      });
      await dump?.flush();
      final questions = rows.where((r) => r['intent'] == 'question').toList();
      final routines = rows.where((r) => r['intent'] != 'question').toList();
      int ok(List<Map<String, Object?>> rs, bool Function(String) f) =>
          rs.where((r) => got[r['id']] != null && f(got[r['id']]!)).length;
      // ignore: avoid_print
      print(
        '루틴 지시문 × 떼어 둔 모음: 루틴 요청 → 루틴·거절 ${pct(ok(routines, (i) => i == 'routine' || i == 'refuse'), routines.length)} · '
        '닮은 질문 → question ${pct(ok(questions, (i) => i == 'question'), questions.length)} · '
        '무효 ${pct(got.values.where((i) => i == 'invalid').length, got.length)} · 의료·약물 시작 카드 $unsafe\n'
        '틀린 것 ${wrong.length}:\n  ${wrong.join('\n  ')}',
      );
      expect(unsafe, 0, reason: 'M6');
    },
    skip: skipUnless('2'),
    timeout: timeout,
  );

  test(
    '3. 기록 검색 지시문 × 닮은 질문·기록 질문으로 간 루틴 요청',
    () async {
      final rows = [
        for (final r in load('routine'))
          if (r['intent'] == 'question' ||
              routeHome(r['text'] as String) == HomeRoute.question)
            r,
        for (final r in load('routine_heldout'))
          if (r['intent'] == 'question' ||
              routeHome(r['text'] as String) == HomeRoute.question)
            r,
      ];
      final names = recordedExercises(defaultLog());
      final wrong = <String>[];
      var leak = 0, questions = 0, caught = 0, routed = 0;
      await pool(rows, (r) async {
        final text = r['text'] as String;
        String kind;
        Object? answer;
        try {
          answer = await ai.queryIntent(
            text,
            locale(r),
            names,
            unit: 'kg',
            today: today,
          );
          final q = decodeRecordIntent(
            answer,
            text,
            names,
            unit: 'kg',
            today: today,
            locale: locale(r),
          );
          kind = q.kind == 'routine' ? 'routine' : 'other';
        } on FormatException {
          kind = 'invalid';
        } catch (e) {
          kind = 'fail';
        }
        v3Answer[text] = kind;
        if (r['intent'] == 'question') {
          questions++;
          if (kind == 'routine') {
            leak++;
            wrong.add('질문→routine ${r['id']} $text ⟨${jsonEncode(answer)}⟩');
          }
        } else {
          routed++;
          if (kind == 'routine') {
            caught++;
          } else {
            wrong.add('루틴 요청→$kind ${r['id']} $text ⟨${jsonEncode(answer)}⟩');
          }
        }
      });
      await dump?.flush();
      // ignore: avoid_print
      print(
        '기록 검색 지시문: 닮은 질문이 routine 으로 샌 것 ${pct(leak, questions)} · '
        '기록 질문으로 간 루틴 요청을 routine 으로 받은 것 ${pct(caught, routed)}\n  ${wrong.join('\n  ')}',
      );
    },
    skip: skipUnless('3'),
    timeout: timeout,
  );

  test(
    '4. 끝까지(가르기 → 지시문): 사람이 받는 의도',
    () async {
      final rows = [...load('routine'), ...load('routine_heldout')];
      var ok = 0, graded = 0;
      final wrong = <String>[];
      final perSet = <String, List<int>>{};
      for (final r in rows) {
        final text = r['text'] as String;
        final route = routeHome(text);
        final got = switch (route) {
          HomeRoute.bare => 'routine',
          HomeRoute.refuse => 'refuse',
          HomeRoute.routine => routineAnswer[text] ?? 'missing',
          HomeRoute.question => switch (v3Answer[text]) {
            'routine' => 'routine(칩)',
            null => 'missing',
            _ => 'question',
          },
        };
        if (got == 'missing' || got == 'fail') continue;
        graded++;
        final want = r['intent'] as String;
        final good = switch (want) {
          'question' => got == 'question',
          'refuse' =>
            got == 'refuse' || got == 'routine' && (r['refused'] == null),
          _ => got == 'routine' || got == 'routine(칩)' || got == 'refuse',
        };
        final set = (r['id'] as String).startsWith('h') ? '떼어 둔' : '코퍼스';
        final t = perSet.putIfAbsent('$set/$want', () => [0, 0]);
        t[1]++;
        if (good) {
          ok++;
          t[0]++;
        } else {
          wrong.add('${r['id']} $text: ${route.name} → $got (want $want)');
        }
      }
      // ignore: avoid_print
      print(
        '끝까지 의도: ${pct(ok, graded)} · ${perSet.entries.map((e) => '${e.key} ${e.value[0]}/${e.value[1]}').join(' · ')}\n  ${wrong.join('\n  ')}',
      );
    },
    skip: skipUnless('4'),
    timeout: timeout,
  );

  test(
    '5. 기록 검색 v3.json 257: kind routine 이 샌 비율(M9)',
    () async {
      final rows = load('v3');
      var leak = 0, graded = 0;
      final leaked = <String>[];
      await pool(rows, (c) async {
        final text = c['q'] as String;
        final names = (c['names'] as List).cast<String>();
        try {
          final answer = await ai.queryIntent(
            text,
            (c['lang'] as String).replaceAll('_', '-'),
            names,
            unit: 'kg',
            today: evalTodayRoutine,
          );
          graded++;
          if (answer is Map && answer['kind'] == 'routine') {
            leak++;
            leaked.add('$text ⟨${jsonEncode(answer)}⟩');
          }
        } catch (_) {}
      });
      await dump?.flush();
      // ignore: avoid_print
      print(
        'v3.json: kind routine ${pct(leak, graded)}\n  ${leaked.join('\n  ')}',
      );
    },
    skip:
        skipUnless('5') ??
        (Platform.environment['EVAL_V3'] == '1' ? null : 'EVAL_V3=1 일 때만'),
    timeout: timeout,
  );

  tearDownAll(() async {
    await dump?.close();
    client.close();
    final v3 = usage['v3'];
    if (v3 != null && v3[0] > 0) {
      // ignore: avoid_print
      print(
        '기록 검색 지시문 토큰(평균): 입력 ${v3[1] ~/ v3[0]} · 출력 ${v3[2] ~/ v3[0]} · 답 ${v3[0]}',
      );
    }
  });
}

/// 기록 검색 평가의 기준일(tool/question_grading.dart evalToday 와 같다).
final evalTodayRoutine = DateTime(2026, 9, 9);
