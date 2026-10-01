import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/workout_import.dart';

void main() {
  testWidgets('긴 텍스트를 여러 날짜 미리보기로 바꾸고, 날짜를 확인한 뒤 한 번에 저장한다', (tester) async {
    final directory = Directory.systemTemp.createTempSync('setpad_import_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final store = NotesStore(directory: directory);
    addTearDown(store.dispose);
    Map<String, Object?>? sent;
    final ai = RecordAi(
      endpoint: 'https://example.test',
      accountToken: () => 'test-token',
      client: MockClient((request) async {
        sent = (jsonDecode(request.body) as Map).cast<String, Object?>();
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'sessions': [
                {
                  'date': '2026-09-01',
                  'title': '상체',
                  'exercises': [
                    {
                      'name': '벤치프레스',
                      'sets': [
                        {
                          'value': 60,
                          'unit': 'kg',
                          'reps': 5,
                          'notes': [],
                          'done': true,
                        },
                      ],
                    },
                  ],
                },
                {
                  'date': null,
                  'title': null,
                  'exercises': [
                    {
                      'name': '스쿼트',
                      'sets': [
                        {
                          'value': 80,
                          'unit': 'kg',
                          'reps': 5,
                          'notes': ['마지막 세트'],
                          'done': true,
                        },
                      ],
                    },
                  ],
                },
              ],
              'unparsed': ['날짜가 잘린 기록'],
              'saved': false,
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: WorkoutImportPage(store: store, ai: ai),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('workout-import-text')),
      '2026.9.1 벤치 60kg 5회\n2026.9.3 스쿼트 80kg 5회',
    );
    await tester.tap(find.byKey(const ValueKey('workout-import-primary')));
    await tester.pumpAndSettle();
    expect(sent?['text'], contains('벤치 60kg'));
    expect(find.textContaining('날짜가 잘린 기록'), findsOneWidget);
    expect(find.text('날짜 선택'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('workout-import-session-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workout-import-session-1')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const ValueKey('workout-import-primary')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('날짜 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout-import-date-confirm')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const ValueKey('workout-import-primary')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(
      find.byKey(const ValueKey('workout-import-unparsed-dismiss-0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout-import-primary')));
    await tester.pumpAndSettle();

    expect(store.notes, hasLength(2));
    expect(
      store.notes.map((note) => note.blocks.single.name),
      containsAll(['벤치프레스', '스쿼트']),
    );
    expect(
      store.notes
          .firstWhere((note) => note.blocks.single.name == '벤치프레스')
          .blocks
          .single
          .sets
          .single
          .reps,
      5,
    );
    expect(
      store.notes
          .firstWhere((note) => note.blocks.single.name == '스쿼트')
          .blocks
          .single
          .sets
          .single
          .notes,
      ['마지막 세트'],
    );
  });

  test('긴 원문은 빈 줄에서 나눠 보낸다 — 한 조각이 한 답에 들어가게', () {
    final day = List.filled(30, '벤치 60kg 5회').join('\n');
    final text = List.generate(10, (i) => '9/${i + 1}\n$day').join('\n\n');
    final pieces = importChunks(text, size: 1000);
    expect(pieces.length, greaterThan(1));
    expect(pieces.every((p) => p.length <= 1000), isTrue);
    expect(pieces.join('\n\n'), text);
    expect(importChunks('x' * 2500, size: 1000).map((p) => p.length), [
      1000,
      1000,
      500,
    ]);
  });

  testWidgets('한 조각을 못 읽어도 읽은 것은 남기고, 같은 날 두 운동은 따로 저장한다', (tester) async {
    final directory = Directory.systemTemp.createTempSync('setpad_import_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final store = NotesStore(directory: directory);
    addTearDown(store.dispose);
    Map<String, Object?> session(String name) => {
      'date': '2026-09-01',
      'title': null,
      'exercises': [
        {
          'name': name,
          'sets': [
            {'value': 60, 'unit': 'kg', 'reps': 5, 'notes': [], 'done': true},
          ],
        },
      ],
    };
    var calls = 0;
    final ai = RecordAi(
      endpoint: 'https://example.test',
      accountToken: () => 'test-token',
      client: MockClient((request) async {
        calls++;
        return calls == 1
            ? http.Response.bytes(
                utf8.encode(
                  jsonEncode({
                    'sessions': [session('벤치프레스'), session('턱걸이')],
                    'unparsed': [],
                    'saved': false,
                  }),
                ),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              )
            : http.Response('{"error":"unreadable"}', 502);
      }),
    );
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: WorkoutImportPage(store: store, ai: ai),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('workout-import-text')),
      '${'가' * 1500}\n\n${'나' * 1500}',
    );
    await tester.tap(find.byKey(const ValueKey('workout-import-primary')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.textContaining('1개는 읽지 못했어요'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('workout-import-session-1')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('workout-import-primary')));
    await tester.pumpAndSettle();
    expect(store.notes, hasLength(2));
    expect(store.notes.map((n) => n.id).toSet(), hasLength(2));
  });
}
