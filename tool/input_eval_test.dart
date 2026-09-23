import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/exercises.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/workout_timing.dart';

/// 적기 도움(운동 입력 줄, input contract 2)을 운영 모델로 잰다.
///
/// **test/ 밖에 둔다.** 진짜 API 를 부르고 키가 있어야 한다. 키가 없으면
/// 건너뛴다. 재려면(160문항, 1~2분):
///
///     DEEPSEEK_API_KEY=... flutter test --no-pub tool/input_eval_test.dart
///
/// 서버를 거치지 않는다 — 운영 한도를 쓰지 않으려고. 대신 서버(gymdojo
/// lib/model-json.ts, lib/record-query.ts)와 같게 부른다: RECORD_QUERY_MODEL
/// 기본값 deepseek-flash 를 그대로 모델 id 로, max_tokens 1000(INPUT_MAX_TOKENS),
/// thinking 끔, json_object, 지시문 뒤에 "Return a JSON object only.". 서버의
/// 모양 검사(validSetupAnswer)도 옮겨 두었다 — 서버가 거절하면 앱은 502 를 받고
/// 적은 그대로 칸을 만든다(폴백).
///
/// 앱의 경로를 그대로 탄다. 길 나누기는 에디터(_commit)와 같고, 모델 대신
/// 대답할 자리(respond)만 끼워서 지시문 조립·수 대조·이름 되찾기·제목이 실제와
/// 같다.
///
/// 채점:
/// - 정확: 운동 수·순서, 이름, 무게·단위·횟수·세트가 모두 맞고, 친 낱말이 모두
///   제목에 남았다. 이름은 [searchKey] 가 **같아야** 맞다(담기만 하면 맞던 것을
///   고쳤다 — '벤치 원알엠' 은 '벤치' 가 아니다). 정답의 name 이 목록이면 그중
///   하나('불가리안' 또는 친 그대로 '불가리안 스플릿 스쿼트'). 정답에 없는 칸의
///   수는 틀림이다. 대안이 있으면 가장 가까운 대안과 견준다.
/// - 제목에서 잃은 말: 글자·숫자가 든 친 낱말이 어느 제목에도 없다(0이어야 한다).
///   제목에 다 못 담으면 에디터는 칸을 만들지 않고 글을 입력칸에 둔다(입력칸에 둠).
///   타이머 이름('bpm 60 스쿼트')은 줄 전체가 이름이다 — 제목이 곧 설정이라서다.
/// - 잘못 놓음: 칸에 든 수가 정답과 다르다(다른 칸에 간 친 수, 지어낸 수, 단위).
///   빈칸은 잘못 놓음이 아니다 — 그 수는 못 옮긴 말로 사람에게 보인다.
/// - 폴백: 운동이어야 하는데 해석이 운동을 못 냈다(서버 거절·빈 답·무효).
/// - 못 옮긴 말 재현: 모델이 운동을 낸 문항에서, 반드시 보여야 할 조각이
///   못 옮긴 말(앱이 채운 것 포함)에 들었나.
/// - 막다른 길: 에디터가 받지 못하는 예외나 제목(0이어야 한다).
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
  String keyOf(String input) {
    final i = jsonDecode(input) as Map;
    return '${i['language']}|${i['input']}';
  }

  final contents = <String, String>{};
  final rejected = <String>{};
  HttpOverrides.global = null;
  final client = HttpClient();
  var tokens = 0, answered = 0, millis = 0, slowest = 0;

  Future<Object?> ask(String instructions, String input) async {
    final k = keyOf(input);
    Object? parsed;
    if (replay.isNotEmpty) {
      final content = replay[k] ?? (throw HttpException('replay 에 없음 $k'));
      contents[k] = content;
      answered++;
      try {
        parsed = jsonDecode(content);
      } on FormatException {
        rejected.add(k);
        throw const RecordAiException(RecordAiStatus.unavailable);
      }
    } else {
      final clock = Stopwatch()..start();
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
      final ms = clock.elapsedMilliseconds;
      if (response.statusCode != 200) {
        throw HttpException('${response.statusCode} $text');
      }
      final body = jsonDecode(text);
      answered++;
      millis += ms;
      if (ms > slowest) slowest = ms;
      if (body['usage']?['total_tokens'] case final int n) tokens += n;
      final choice = (body['choices'] as List).first as Map;
      final content = (choice['message'] as Map?)?['content'];
      if (content is String) {
        contents[k] = content;
        dump?.writeln(jsonEncode({'key': k, 'content': content}));
      }
      // 서버: 멈춤 이유가 stop 이 아니거나 JSON 이 아니면 502 → 앱은 unavailable.
      if (choice['finish_reason'] != 'stop' || content is! String) {
        rejected.add(k);
        throw const RecordAiException(RecordAiStatus.unavailable);
      }
      try {
        parsed = jsonDecode(content);
      } on FormatException {
        rejected.add(k);
        throw const RecordAiException(RecordAiStatus.unavailable);
      }
    }
    final typed = jsonDecode(input)['input'] as String;
    parsed = typedPiecesOnly(parsed, typed);
    if (!validSetupAnswer(parsed, typed)) {
      rejected.add(k);
      throw const RecordAiException(RecordAiStatus.unavailable);
    }
    return parsed;
  }

  final ai = RecordAi(respond: ask);
  final cases =
      (jsonDecode(File('tool/input_questions.json').readAsStringSync()) as List)
          .cast<Map<String, Object?>>();

  String pct(int n, int of) =>
      of == 0 ? '-' : '${(100 * n / of).toStringAsFixed(1)}%';

  test(
    '$model 로 적기 도움을 잰다',
    () async {
      var exact = 0, graded = 0, misplaced = 0, fallback = 0, deadEnds = 0;
      var unreachable = 0, invented = 0, recalled = 0, fragments = 0;
      var lostWords = 0, keptInInput = 0;
      final perLang = <String, List<int>>{}; // [맞음, 채점]
      final errorTags = <String, int>{};
      final report = <(int, String)>[]; // (심각도, 줄)
      final queue = [...cases];

      Future<void> worker() async {
        while (queue.isNotEmpty) {
          final c = queue.removeAt(0);
          final text = c['input'] as String;
          final lang = c['language'] as String;
          final tag = lang.replaceAll('_', '-');
          final wants = [
            (c['exercises'] as List).cast<Map<String, Object?>>(),
            for (final alt in (c['alternatives'] as List?) ?? const [])
              (alt as List).cast<Map<String, Object?>>(),
          ];
          final must = (c['unparsedMustContain'] as List).cast<String>();
          // 에디터(_commit)와 같은 길 나누기.
          final timerOnly =
              TimingSpec.parse(text) != null &&
              !hasSetupIntent(text.replaceAll(timerTokens, ' '));
          var route = timerOnly
              ? '타이머'
              : hasSetupIntent(text)
              ? '모델'
              : '이름';
          var got = <WorkoutSetup>[];
          var unparsed = <String>[], dropped = <String>[];
          var titles = [text.trim()];
          String? failed, overflow;
          if (route != '모델') {
            got = [WorkoutSetup(name: text.trim())];
          } else {
            try {
              final reading = await ai.interpret(
                text,
                tag,
                seedNames(lang),
                defaultWeightUnit: 'kg',
              );
              // 운동이 아니라는 답이면 에디터는 친 글 그대로 칸을 만든다(폴백).
              // 제목에 다 못 담으면 칸을 만들지 않고 글을 입력칸에 둔다.
              if (reading.exercises.isNotEmpty && !reading.fits) {
                overflow = '입력칸에 둠';
              } else if (reading.exercises.isNotEmpty) {
                titles = reading.titles;
                if (titles.length != reading.exercises.length ||
                    titles.any((t) => t.trim().isEmpty || t.length > 120)) {
                  failed = '막다른 길: 제목 $titles';
                }
              }
              got = [for (final e in reading.exercises) e.setup];
              unparsed = reading.unparsed;
              dropped = reading.dropped;
              if (got.isEmpty) route = '빈 답';
            } on IOException catch (err) {
              // 모델 탓이 아니다. 채점에서 뺀다.
              unreachable++;
              report.add((9, '[$lang] $text → 호출 실패 $err'));
              continue;
            } on RecordAiException {
              route = rejected.contains('$tag|$text') ? '서버 거절' : '연결';
            } on FormatException catch (err) {
              route = '무효 $err';
            } catch (err) {
              failed = '막다른 길: $err';
            }
          }
          graded++;
          final tally = perLang.putIfAbsent(lang, () => [0, 0]);
          tally[1]++;
          if (failed != null) deadEnds++;
          if (dropped.isNotEmpty) invented++;
          // 폴백: 운동이어야 하는데 해석이 운동을 못 냈다.
          final fellBack = got.isEmpty && wants.first.isNotEmpty;
          if (fellBack) fallback++;
          final best = [
            for (final w in wants) _grade(got, w),
          ].reduce((a, b) => a.errors.length <= b.errors.length ? a : b);
          if (best.misplaced) misplaced++;
          final missing = <String>[];
          if (got.isNotEmpty && route == '모델') {
            for (final m in must) {
              fragments++;
              if (unparsed.any((u) => searchKey(u).contains(searchKey(m)))) {
                recalled++;
              } else {
                missing.add(m);
              }
            }
          }
          final lost = [
            for (final w in text.split(RegExp(r'\s+')))
              if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(w) &&
                  !titles.any((t) => t.contains(w)))
                w,
          ];
          if (lost.isNotEmpty) lostWords++;
          if (overflow != null) keptInInput++;
          final errors = [
            ...best.errors,
            if (fellBack) '폴백($route)',
            if (lost.isNotEmpty) '제목에서 잃은 말 $lost',
            ?overflow,
            ?failed,
          ];
          if (errors.isEmpty) {
            exact++;
            tally[0]++;
          }
          for (final e in [...errors, ...missing.map((_) => '못옮긴말')]) {
            errorTags[e] = (errorTags[e] ?? 0) + 1;
          }
          if (errors.isEmpty && missing.isEmpty) continue;
          final shown = [
            for (final s in got)
              {
                for (final e in s.toJson().entries)
                  if (e.value != null &&
                      e.value != false &&
                      !(e.key == 'unit' && s.weight == null))
                    e.key: e.value,
              },
          ];
          report.add((
            failed != null
                ? 0
                : best.misplaced
                ? 1
                : fellBack
                ? 2
                : errors.isNotEmpty
                ? 3
                : 4,
            '[$lang ${c['category']}] $text → ${errors.isEmpty ? '' : '$errors '}'
                '${missing.isEmpty ? '' : '못옮긴말 없음 $missing '}'
                '얻음 ${jsonEncode(shown)} 못옮긴말 ${jsonEncode(unparsed)}'
                '${dropped.isEmpty ? '' : ' 뺌 $dropped'} ⟨${contents['$tag|$text'] ?? route}⟩',
          ));
        }
      }

      await Future.wait([for (var i = 0; i < 4; i++) worker()]);
      await dump?.flush();
      // ignore: avoid_print
      print(
        '$model input: 정확 $exact/$graded = ${pct(exact, graded)} · '
        '잘못 놓음 $misplaced = ${pct(misplaced, graded)} · '
        '폴백 $fallback = ${pct(fallback, graded)} · '
        '못 옮긴 말 재현 $recalled/$fragments = ${pct(recalled, fragments)} · '
        '막다른 길 $deadEnds · 제목에서 잃은 말 $lostWords · 입력칸에 둠 $keptInInput · '
        '서버 거절 ${rejected.length} · '
        '지어낸 수 뺀 문항 $invented · 호출 실패 $unreachable · '
        '평균 토큰 ${answered == 0 ? 0 : tokens ~/ answered} · '
        '평균 ${answered == 0 ? 0 : millis ~/ answered}ms · 최장 ${slowest}ms',
      );
      // ignore: avoid_print
      print(
        '언어별: ${[for (final e in perLang.entries) '${e.key} ${e.value[0]}/${e.value[1]} = ${pct(e.value[0], e.value[1])}'].join(' · ')}',
      );
      // ignore: avoid_print
      print('오류 종류: $errorTags');
      report.sort((a, b) => a.$1.compareTo(b.$1));
      for (final (_, line) in report) {
        // ignore: avoid_print
        print('  $line');
      }
      expect(deadEnds, 0, reason: '막다른 길');
    },
    skip: key.isEmpty && replay.isEmpty ? 'DEEPSEEK_API_KEY 없음' : null,
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

const _fields = ['weight', 'totalReps', 'repsPerSet', 'totalSets'];

/// 대안 하나와 견준다. 칸에 든 수가 정답과 다르면 [misplaced].
({List<String> errors, bool misplaced}) _grade(
  List<WorkoutSetup> got,
  List<Map<String, Object?>> want,
) {
  final errors = <String>[];
  var misplaced = false;
  if (got.length != want.length) {
    errors.add('운동 수 ${got.length}≠${want.length}');
  }
  for (final (i, g) in got.indexed) {
    final w = i < want.length ? want[i] : const <String, Object?>{};
    final names = switch (w['name']) {
      final String name => [name],
      final List names => names.cast<String>(),
      _ => null,
    };
    if (names != null &&
        !names.any((name) => searchKey(name) == searchKey(g.name))) {
      errors.add('이름');
    }
    final values = g.toJson();
    for (final f in _fields) {
      final value = values[f] as num?;
      if (value == w[f]) continue;
      errors.add(f);
      if (value != null) misplaced = true;
    }
    if (g.weight != null &&
        w['weight'] != null &&
        g.unit != (w['unit'] ?? 'kg')) {
      errors.add('unit');
      misplaced = true;
    }
  }
  return (errors: errors, misplaced: misplaced);
}

const _answerKeys = {
  'text',
  'name',
  'weight',
  'unit',
  'totalReps',
  'repsPerSet',
  'totalSets',
  'repsOnly',
};

/// gymdojo lib/record-intent.ts 의 typedPiecesOnly 를 옮긴 것. 친 글에 없는 text 는
/// null, 그런 못 옮긴 말은 지운다 — 답 전체를 버리지 않는다. 모양이 틀린 것은 둔다.
Object? typedPiecesOnly(Object? v, String typed) {
  if (v is! Map) return v;
  bool foreign(Object? s) => s is String && !typed.contains(s.trim());
  return {
    ...v,
    if (v['exercises'] case final List list)
      'exercises': [
        for (final e in list)
          e is Map && foreign(e['text']) ? {...e, 'text': null} : e,
      ],
    if (v['unparsed'] case final List list)
      'unparsed': [
        for (final u in list)
          if (!foreign(u)) u,
      ],
  };
}

/// gymdojo lib/record-intent.ts 의 validSetupAnswer 를 옮긴 것. 서버가 이
/// 모양을 거절하면 502 이고 앱은 폴백한다. text·unparsed 는 친 글의 부분이어야
/// 한다(typedPiecesOnly 가 먼저 걸러 낸다) — 무료 경로가 자유 글을 싣지 못하게.
bool validSetupAnswer(Object? v, String typed) {
  if (v is! Map || jsonEncode(v).length > 2000) return false;
  if (v.keys.any((k) => k != 'exercises' && k != 'unparsed')) return false;
  final list = v['exercises'];
  if (list is! List || list.length > 6) return false;
  final unparsed = v['unparsed'];
  if (unparsed != null &&
      !(unparsed is List &&
          unparsed.length <= 8 &&
          unparsed.every(
            (s) => s is String && s.length <= 80 && typed.contains(s.trim()),
          ))) {
    return false;
  }
  bool number(Object? x, num max) =>
      x == null || (x is num && x.isFinite && x >= 0 && x <= max);
  return list.every((e) {
    if (e is! Map || e.keys.any((k) => !_answerKeys.contains(k))) return false;
    final text = e['text'], name = e['name'], unit = e['unit'];
    return (text == null ||
            (text is String &&
                text.length <= 120 &&
                typed.contains(text.trim()))) &&
        name is String &&
        name.trim().isNotEmpty &&
        name.length <= 120 &&
        (unit == null || unit == 'kg' || unit == 'lb') &&
        number(e['weight'], 10000) &&
        number(e['totalReps'], 100000) &&
        number(e['repsPerSet'], 10000) &&
        number(e['totalSets'], 1000) &&
        (e['repsOnly'] == null || e['repsOnly'] is bool);
  });
}
