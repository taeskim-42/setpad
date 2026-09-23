import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/settings_page.dart';
import 'package:setpad/trainer.dart';
import 'package:setpad/trainer_settings.dart';

/// 트레이너 모드. 모양은 gymdojo-crm 의 lib/agent-types.ts 와 /api/agent/** 가 정한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // http.Response(String) 은 charset 이 없으면 latin1 이라 한글이 깨진다.
  http.Response reply(Object body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  const gymId = '11111111-1111-4111-8111-111111111111';
  // 서버는 UUID 가 아닌 runId 면 처리 전체를 400 으로 거절한다.
  const runId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  final v4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );
  const minsu = {
    'id': '22222222-2222-4222-8222-222222222222',
    'nickname': '박민수',
  };

  Map<String, Object?> agentBody({
    String runId = runId,
    int version = 1,
    bool read = false,
    List<String> handled = const [],
  }) => {
    'settings': {
      'enabled': true,
      'run_minutes': [1140, 420],
      'weekdays': [1, 2, 3],
      'modes': {'pt_schedule': 'draft', 'renewal': 'draft'},
      'auto_confirm': false,
    },
    'policy': {'renewal_notice_days': 7, 'renewal_offer': null},
    'role': 'staff',
    'runs': [
      {
        'id': runId,
        'run_for': '2026-09-23',
        'trigger': 'schedule',
        'status': 'done',
        'started_at': '2026-09-22T22:00:00.000Z',
        'finished_at': '2026-09-22T22:00:05.000Z',
        'summary': '확인할 일 5건',
        'read_at': read ? '2026-09-22T23:00:00.000Z' : null,
        'handled': handled,
        'report': {
          'version': version,
          'gym': {'id': gymId, 'name': 'BPM 강남'},
          'staff': {'id': 's', 'nickname': '김코치'},
          'run_for': '2026-09-23',
          'generated_at': '2026-09-22T22:00:05.000Z',
          'summary': '오늘 PT 2건, 확인할 일 5건이에요.',
          'today': [
            {
              'at': '2026-09-23T10:00:00.000Z',
              'member': null,
              'title': '요가',
              'kind': 'class',
            },
            {
              'at': '2026-09-23T01:00:00.000Z',
              'member': minsu,
              'title': 'PT',
              'kind': 'pt',
            },
          ],
          'done': [
            {'kind': 'confirmed', 'member': minsu, 'detail': '9/24 PT 신청 확정'},
          ],
          'items': [
            {
              'kind': 'attendance',
              'key': 'att',
              'bookings': [
                {
                  'id': '33333333-3333-4333-8333-333333333333',
                  'member': minsu,
                  'starts_at': '2026-09-22T01:00:00.000Z',
                  'visited_at': '2026-09-22T00:58:00.000Z',
                },
              ],
            },
            {
              'kind': 'request',
              'key': 'req',
              'member': minsu,
              'requested_at': '2026-09-22T00:00:00.000Z',
            },
            {
              'kind': 'pt_schedule',
              'key': 'pt',
              'member': minsu,
              'starts_at': '2026-09-24T10:00:00.000Z',
              'basis': '최근 4번 중 3번',
            },
            {
              'kind': 'renewal',
              'key': 'ren',
              'member': minsu,
              'reason': 'expiring',
              'reason_label': '만료 5일 전',
              'episode': '2026-09-28',
              'product': {
                'id': '44444444-4444-4444-8444-444444444444',
                'name': 'PT 10회',
                'price': 700000,
              },
              'starts_on': '2026-09-28',
              'message': '민수님, 이용권이 곧 끝나요.',
            },
            {
              'kind': 'routine',
              'key': 'rt',
              'member': minsu,
              'title': '하체',
              'items': [
                {
                  'name': '스쿼트',
                  'sets': [
                    {'kg': 60, 'reps': 10},
                  ],
                },
              ],
              'basis': '9/16 루틴 그대로',
            },
            {
              'kind': 'contact',
              'key': 'away',
              'member': minsu,
              'reason': 'away',
              'reason_label': '8일째 안 옴',
              'episode': '2026-09-15',
              'message': '요즘 어떠세요?',
            },
            // 이 판이 모르는 종류, 깨진 항목 — 둘 다 조용히 건너뛴다.
            {'kind': 'future_thing', 'key': 'x'},
            {'kind': 'pt_schedule', 'key': 'broken', 'member': minsu},
          ],
        },
      },
      {
        'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'status': 'done',
        'started_at': '2026-09-21T22:00:00.000Z',
        'report': null,
      },
    ],
  };

  GymLink linkThat(Future<http.Response> Function(http.Request) handle) =>
      GymLink(
        endpoint: 'https://example.com',
        token: 't',
        client: MockClient(handle),
      );

  group('Account.staff', () {
    late Directory dir;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('setpad-trainer');
      File(
        '${dir.path}/session.json',
      ).writeAsStringSync(jsonEncode({'token': 'saved', 'nickname': '김코치'}));
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('/api/me 의 staff 를 읽고, 로그아웃하면 비운다', () async {
      final a = Account(
        storageDir: dir,
        client: MockClient(
          (request) async => request.url.path == '/api/me'
              ? reply({
                  'user': {'nickname': '김코치'},
                  'gyms': [],
                  'staff': [
                    {'gym_id': gymId, 'gym': 'BPM 강남', 'role': 'owner'},
                  ],
                  'token': 'saved',
                })
              : reply({'plan': null, 'selling': false}),
        ),
      );
      await a.restoreSession();
      expect(a.staff, [(gymId: gymId, gym: 'BPM 강남')]);
      await a.signOut();
      expect(a.staff, isEmpty);
    });

    test('staff 가 없는 서버면 트레이너가 아니다', () async {
      final a = Account(
        storageDir: dir,
        client: MockClient(
          (_) async => reply({'user': {}, 'gyms': [], 'token': 'saved'}),
        ),
      );
      await a.restoreSession();
      expect(a.staff, isEmpty);
    });
  });

  test('보고서를 읽는다 — 모르는 종류와 깨진 항목은 건너뛴다', () async {
    Uri? asked;
    final (:state, reply: answer) = await linkThat((request) async {
      asked = request.url;
      return reply(agentBody());
    }).agentState(gymId);
    expect(answer.status, 200);
    expect(asked!.path, '/api/agent');
    expect(asked!.queryParameters['gymId'], gymId);

    expect(state!.owner, isFalse);
    expect(state.settings.runMinutes, [420, 1140]);
    expect(state.settings.weekdays, {1, 2, 3});
    expect(state.unread, isTrue);
    final report = state.latest!.report!;
    expect(state.latest!.id, runId);
    expect(report.supported, isTrue);
    expect(report.gymName, 'BPM 강남');
    expect(report.today.map((t) => t.title), ['PT', '요가'], reason: '시각순');
    expect(report.done.single.detail, '9/24 PT 신청 확정');
    expect(report.items.map((i) => i.runtimeType), [
      AgentAttendance,
      AgentRequest,
      AgentPtSchedule,
      AgentFollowup,
      AgentRoutine,
      AgentFollowup,
    ]);
    final renewal = report.items[3] as AgentFollowup;
    expect(renewal.product!.price, 700000);
    expect(renewal.startsOn, '2026-09-28');
    expect((report.items[5] as AgentFollowup).product, isNull);
    expect((report.items[4] as AgentRoutine).names, ['스쿼트']);
  });

  test('다른 판의 보고서는 그리지 않는다', () async {
    final (:state, reply: _) = await linkThat(
      (_) async => reply(agentBody(version: 2)),
    ).agentState(gymId);
    expect(state!.latest!.report!.supported, isFalse);
  });

  test('보고서를 못 받으면 서버의 말과 status 를 돌려준다', () async {
    final refused = await linkThat(
      (_) async =>
          reply({'error': 'forbidden', 'message': '이 도장의 관리 권한이 없습니다.'}, 403),
    ).agentState(gymId);
    expect(refused.state, isNull);
    expect(refused.reply.status, 403);
    expect(refused.reply.message, '이 도장의 관리 권한이 없습니다.');

    final offline = await linkThat(
      (_) async => throw const SocketException('꺼짐'),
    ).agentState(gymId);
    expect(offline.state, isNull);
    expect((offline.reply.status, offline.reply.message), (null, null));
  });

  test('처리는 서버가 읽는 모양 그대로 보내고, 거절이면 서버의 말을 돌려준다', () async {
    final sent = <(String, String, Object?)>[];
    final link = linkThat((request) async {
      sent.add((request.method, request.url.path, jsonDecode(request.body)));
      return sent.length == 1
          ? reply({'ok': true, 'outcome': 'done', 'detail': '예약했어요'})
          : reply({'error': 'slotTaken', 'message': '그 시간은 이미 찼어요.'}, 409);
    });
    final action = {
      'kind': 'pt_schedule',
      'memberId': minsu['id'],
      'startsAt': '2026-09-24T10:00:00.000Z',
    };
    final ok = await link.act(gymId, action);
    expect(sent.single.$1, 'POST');
    expect(sent.single.$2, '/api/agent/act');
    expect(sent.single.$3, {'gymId': gymId, 'action': action});
    expect(ok.body!['detail'], '예약했어요');

    final refused = await link.act(gymId, action);
    expect(refused.body, isNull);
    expect(refused.message, '그 시간은 이미 찼어요.');

    final offline = await linkThat(
      (_) async => throw const SocketException('꺼짐'),
    ).act(gymId, action);
    expect((offline.body, offline.message), (null, null));
  });

  test('설정은 바꾼 것만 PUT 으로 보낸다', () async {
    late http.Request got;
    await linkThat((request) async {
      got = request;
      return reply({'settings': agentBody()['settings']});
    }).saveAgentSettings(gymId, {
      'weekdays': [1, 5],
    });
    expect(got.method, 'PUT');
    expect(got.url.path, '/api/agent/settings');
    expect(jsonDecode(got.body), {
      'gymId': gymId,
      'weekdays': [1, 5],
    });
  });

  test('요청 열쇠는 서버가 받는 UUID v4 다', () {
    expect(List.generate(50, (_) => uuid4()).every(v4.hasMatch), isTrue);
  });

  group('화면', () {
    // 목록의 점은 앱 전체에 하나다. 앞 테스트의 값이 남지 않게 한다.
    setUp(() => reportUnread.value = false);

    Widget app(Widget home) => CupertinoApp(
      locale: const Locale('ko'),
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: home,
    );

    Account account(
      Future<http.Response> Function(http.Request) handle, {
      bool staff = true,
    }) => Account(client: MockClient(handle))
      ..token = 'x'
      ..staff = staff ? [(gymId: gymId, gym: 'BPM 강남')] : const [];

    Future<http.Response> server(
      http.Request request, {
      String runId = runId,
      List<String> handled = const [],
    }) async => switch (request.url.path) {
      '/api/agent' => reply(agentBody(runId: runId, handled: handled)),
      '/api/agent/read' => reply({'ok': true}),
      _ => reply({'gyms': [], 'routines': [], 'plan': null, 'selling': false}),
    };

    testWidgets('직원이면 목록 위에 입구와 안 읽은 점이 보인다', (tester) async {
      await tester.pumpWidget(
        app(
          NotesListPage(
            store: NotesStore(),
            account: account(server),
            onOpen: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('트레이너 보고'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == '새 보고서',
        ),
        findsOneWidget,
      );
    });

    testWidgets('직원이 아니면 입구가 없다', (tester) async {
      await tester.pumpWidget(
        app(
          NotesListPage(
            store: NotesStore(),
            account: account(server, staff: false),
            onOpen: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('트레이너 보고'), findsNothing);
    });

    testWidgets('보고서 항목을 그리고, 처리하면 숨기고 서버의 말을 띄운다', (tester) async {
      final acts = <Object?>[];
      final reads = <Object?>[];
      final a = account((request) async {
        if (request.url.path == '/api/agent/read') {
          reads.add(jsonDecode(request.body));
        }
        if (request.url.path == '/api/agent/act') {
          acts.add(jsonDecode(request.body));
          return reply({
            'ok': true,
            'outcome': 'done',
            'detail': '9/24 19:00 PT 예약했어요',
          });
        }
        // 미방문 연락은 웹에서 이미 끝냈다.
        return server(
          request,
          runId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
          handled: ['away'],
        );
      });
      // 항목이 다 그려지게 화면을 길게 둔다(목록은 보이는 것만 만든다).
      tester.view.physicalSize = const Size(1000, 5000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(TrainerPage(account: a, gymId: gymId)));
      await tester.pumpAndSettle();

      expect(find.text('BPM 강남'), findsOneWidget);
      expect(find.text('오늘 PT 2건, 확인할 일 5건이에요.'), findsOneWidget);
      // 열었으니 읽음. 점이 꺼진다.
      expect(reads, [
        {'gymId': gymId, 'runId': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'},
      ]);
      expect(find.text('모두 완료 (1)'), findsOneWidget);
      // 날짜는 웹 CRM 과 같은 꼴: 9/22(화) 10:00.
      expect(
        find.textContaining(
          RegExp(
            r'^박민수 · \d{1,2}/\d{1,2}\([월화수목금토일]\) \d\d:\d\d · 방문 확인 \d\d:\d\d$',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('PT 10회 · 700,000원 · 9/28(월)부터'), findsOneWidget);
      expect(find.text('등록 요청 — 웹 CRM 오늘 화면에서 확인해 주세요.'), findsOneWidget);
      expect(find.text('결제 받음'), findsOneWidget, reason: '상품이 있는 재등록에만');
      expect(find.text('연락함'), findsOneWidget, reason: '끝낸 연락은 가린다');
      expect(find.text('요즘 어떠세요?'), findsNothing);
      expect(find.text('보내기'), findsOneWidget);

      await tester.tap(find.text('잡기'));
      await tester.pumpAndSettle();
      expect(acts.single, {
        'gymId': gymId,
        'action': {
          'kind': 'pt_schedule',
          'memberId': minsu['id'],
          'startsAt': '2026-09-24T10:00:00.000Z',
        },
        // 웹 보고서에서도 가려지게 서버에 어느 항목인지 알린다.
        'runId': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'itemKey': 'pt',
      });
      expect(find.text('잡기'), findsNothing);
      // 결과는 화면 아래 잠깐 떠 있다가 사라진다.
      expect(find.text('9/24 19:00 PT 예약했어요'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('9/24 19:00 PT 예약했어요'), findsNothing);
    });

    testWidgets('서버가 거절하면 그 말을 띄우고 항목은 남긴다', (tester) async {
      final a = account(
        (request) async => request.url.path == '/api/agent/act'
            ? reply({'error': 'slotTaken', 'message': '그 시간은 이미 찼어요.'}, 409)
            : server(request),
      );
      await tester.pumpWidget(app(TrainerPage(account: a, gymId: gymId)));
      await tester.pumpAndSettle();
      // 44pt 알약이라 800×600 화면에서는 아래로 밀린다.
      await tester.ensureVisible(find.text('잡기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('잡기'));
      await tester.pumpAndSettle();
      expect(find.text('그 시간은 이미 찼어요.'), findsOneWidget);
      expect(find.text('잡기'), findsOneWidget);
    });

    /// 항목이 다 그려지게 화면을 길게 둔다(목록은 보이는 것만 만든다).
    void tall(WidgetTester tester) {
      tester.view.physicalSize = const Size(1000, 5000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    testWidgets('결제 받음은 상품가 그대로, 거절 뒤에도 같은 saleKey 로 보낸다', (tester) async {
      final acts = <Map>[];
      final a = account((request) async {
        if (request.url.path != '/api/agent/act') return server(request);
        acts.add(jsonDecode(request.body) as Map);
        return acts.length == 1
            ? reply({'error': 'rejected', 'message': '잠시 뒤에 다시 해 주세요.'}, 409)
            : reply({'ok': true, 'outcome': 'done', 'detail': '재등록을 기록했어요'});
      });
      tall(tester);
      await tester.pumpWidget(app(TrainerPage(account: a, gymId: gymId)));
      await tester.pumpAndSettle();

      await tapText(tester, '결제 받음');
      // 문구의 할인 혜택과 달리 정가가 기록된다는 것을 누르기 전에 본다.
      expect(find.textContaining('상품가 그대로 결제로 기록돼요'), findsOneWidget);
      await tapText(tester, '카드');
      // 거절은 항목 옆에서 보이게 대화상자로 뜬다.
      expect(find.text('잠시 뒤에 다시 해 주세요.'), findsOneWidget);
      await tapText(tester, '확인');
      await tapText(tester, '결제 받음');
      await tapText(tester, '카드');

      final keys = [for (final act in acts) (act['action'] as Map)['saleKey']];
      expect(keys.length, 2);
      expect(v4.hasMatch(keys.first as String), isTrue);
      expect(keys.last, keys.first, reason: '다시 눌러도 두 번 기록되지 않는다');
      expect(acts.first['itemKey'], 'ren');
      expect({...acts.first['action'] as Map}..remove('saleKey'), {
        'kind': 'renewal_sell',
        'memberId': minsu['id'],
        'productId': '44444444-4444-4444-8444-444444444444',
        'startsOn': '2026-09-28',
        'paid': 700000,
        'method': 'card',
      });
      expect(find.text('결제 받음'), findsNothing);
      expect(find.text('재등록을 기록했어요'), findsOneWidget);
    });

    testWidgets('연락함·나중에·모두 완료·보내기는 서버가 읽는 모양으로 보낸다', (tester) async {
      final acts = <Object?>[];
      final a = account((request) async {
        if (request.url.path != '/api/agent/act') return server(request);
        acts.add((jsonDecode(request.body) as Map)['action']);
        return reply({'ok': true, 'outcome': 'done', 'detail': '했어요'});
      });
      tall(tester);
      await tester.pumpWidget(app(TrainerPage(account: a, gymId: gymId)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('연락함').first); // 재등록
      await tester.pumpAndSettle();
      await tapText(tester, '나중에'); // 남은 것은 미방문 연락
      await tapText(tester, '모두 완료 (1)');
      await tapText(tester, '완료하기');
      await tapText(tester, '보내기');

      expect(acts.take(3), [
        {
          'kind': 'followup',
          'memberId': minsu['id'],
          'reason': 'expiring',
          'episode': '2026-09-28',
          'action': 'done',
        },
        {
          'kind': 'followup',
          'memberId': minsu['id'],
          'reason': 'away',
          'episode': '2026-09-15',
          'action': 'snooze',
        },
        {
          'kind': 'attendance',
          'bookingIds': ['33333333-3333-4333-8333-333333333333'],
        },
      ]);
      final routine = acts[3] as Map;
      expect(v4.hasMatch(routine['requestKey'] as String), isTrue);
      expect({...routine}..remove('requestKey'), {
        'kind': 'routine',
        'memberId': minsu['id'],
        'title': '하체',
        // 서버가 준 그대로 되돌려 보낸다.
        'items': [
          {
            'name': '스쿼트',
            'sets': [
              {'kg': 60, 'reps': 10},
            ],
          },
        ],
      });
      expect(find.text('연락함'), findsNothing);
      expect(find.text('보내기'), findsNothing);
    });

    testWidgets('답을 못 받으면 다시 읽어, 서버가 처리했으면 가리고 아니면 알린다', (tester) async {
      var recorded = <String>[];
      var reads = 0;
      final a = account((request) async {
        if (request.url.path == '/api/agent/act') {
          throw const SocketException('답을 잃음');
        }
        if (request.url.path == '/api/agent') reads++;
        return server(request, handled: recorded);
      });
      tall(tester);
      await tester.pumpWidget(app(TrainerPage(account: a, gymId: gymId)));
      await tester.pumpAndSettle();

      await tapText(tester, '나중에');
      expect(reads, 2);
      expect(find.text('결과를 확인하지 못했어요. 다시 눌러도 두 번 기록되지 않아요.'), findsOneWidget);
      await tapText(tester, '확인');

      // 이번에는 서버가 결제를 기록하고 답만 잃었다.
      recorded = ['ren'];
      await tapText(tester, '결제 받음');
      await tapText(tester, '카드');
      expect(reads, 3);
      expect(find.text('결제 받음'), findsNothing);
      expect(find.byType(CupertinoAlertDialog), findsNothing);
    });

    testWidgets('지금 정리하기 — 도는 동안 보이고, 너무 잦으면 서버의 말을 띄운다', (tester) async {
      final running = Completer<http.Response>();
      final a = account(
        (request) =>
            request.method == 'POST' && request.url.path == '/api/agent'
            ? running.future
            : server(request),
      );
      await tester.pumpWidget(app(TrainerPage(account: a, gymId: gymId)));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoActivityIndicator), findsNothing);

      await tester.tap(find.text('지금 정리하기'));
      await tester.pump();
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

      running.complete(
        reply({'error': 'tooSoon', 'message': '2분 뒤에 다시 정리할 수 있어요.'}, 429),
      );
      await tester.pumpAndSettle();
      expect(find.text('2분 뒤에 다시 정리할 수 있어요.'), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    testWidgets('다른 판의 보고서면 업데이트해 달라고 한다', (tester) async {
      final a = account(
        (request) async => request.url.path == '/api/agent'
            ? reply(agentBody(version: 2))
            : server(request),
      );
      await tester.pumpWidget(app(TrainerPage(account: a, gymId: gymId)));
      await tester.pumpAndSettle();
      expect(find.text('이 보고서는 새 버전에서 볼 수 있어요. 앱을 업데이트해 주세요.'), findsOneWidget);
      expect(find.text('잡기'), findsNothing);
    });

    testWidgets('켤 때 직원 목록이 목록 화면보다 늦게 와도 입구가 생긴다', (tester) async {
      // 세션 파일은 비워 두고 토큰을 먼저 쥐여 준다 — 진짜 파일 읽기는 가짜
      // 시계에서 끝나지 않는다. /api/me 를 묻는 데부터가 켤 때와 같다.
      final dir = Directory.systemTemp.createTempSync('setpad-trainer');
      addTearDown(() => dir.deleteSync(recursive: true));
      final a = Account(
        storageDir: dir,
        client: MockClient(
          (request) async => request.url.path == '/api/me'
              ? reply({
                  'user': {},
                  'gyms': [],
                  'staff': [
                    {'gym_id': gymId, 'gym': 'BPM 강남', 'role': 'staff'},
                  ],
                  'token': 'saved',
                })
              : server(request),
        ),
      )..token = 'saved';
      await tester.pumpWidget(
        app(NotesListPage(store: NotesStore(), account: a, onOpen: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(find.text('트레이너 보고'), findsNothing);

      await a.restoreSession();
      await tester.pumpAndSettle();
      expect(find.text('트레이너 보고'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == '새 보고서',
        ),
        findsOneWidget,
      );
    });

    testWidgets('설정은 바꾼 것만, 방침은 다섯 칸을 보내고 결과를 대화상자로 띄운다', (tester) async {
      final paths = <String>[];
      final bodies = <Object?>[];
      final a = account((request) async {
        paths.add(request.url.path);
        bodies.add(jsonDecode(request.body));
        return request.url.path == '/api/agent/settings'
            ? reply({
                'settings': {
                  ...agentBody()['settings'] as Map,
                  'weekdays': [1, 2, 3, 5],
                },
              })
            : reply({
                'error': 'invalidInput',
                'message': '미방문 기준은 2~60일이에요.',
              }, 400);
      });
      final state = AgentState.fromJson({...agentBody(), 'role': 'owner'});
      tall(tester);
      await tester.pumpWidget(
        app(
          TrainerSettingsPage(
            account: a,
            gymId: gymId,
            gymName: 'BPM 강남',
            state: state,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapText(tester, '금');
      expect(paths.single, '/api/agent/settings');
      expect(bodies.single, {
        'gymId': gymId,
        'weekdays': [1, 2, 3, 5],
      });
      expect(state.settings.weekdays, {1, 2, 3, 5});

      await tapText(tester, '방침 저장');
      expect(paths.last, '/api/agent/policy');
      expect(bodies.last, {
        'gymId': gymId,
        'renewal_notice_days': 7,
        'low_sessions': null,
        'away_days': null,
        'lapsed_days': null,
        'renewal_offer': null,
      });
      expect(find.text('미방문 기준은 2~60일이에요.'), findsOneWidget);
    });

    testWidgets('이 도장 직원이 아니면 서버의 말을 보여 주고 정리 버튼을 치운다', (tester) async {
      final a = account(
        (request) async => request.url.path == '/api/agent'
            ? reply({
                'error': 'forbidden',
                'message': '이 도장의 관리 권한이 없습니다.',
              }, 403)
            : server(request),
      );
      await tester.pumpWidget(app(TrainerPage(account: a, gymId: gymId)));
      await tester.pumpAndSettle();
      expect(find.text('이 도장의 관리 권한이 없습니다.'), findsOneWidget);
      expect(find.text('서버에 닿지 못했어요. 잠시 뒤에 다시 해 주세요.'), findsNothing);
      expect(find.text('지금 정리하기'), findsNothing);
    });

    testWidgets('서버에 닿지 못하면 그렇게 말하고 다시 정리할 수 있게 둔다', (tester) async {
      final a = account(
        (request) async => request.url.path == '/api/agent'
            ? throw const SocketException('꺼짐')
            : server(request),
      );
      await tester.pumpWidget(app(TrainerPage(account: a, gymId: gymId)));
      await tester.pumpAndSettle();
      expect(find.text('서버에 닿지 못했어요. 잠시 뒤에 다시 해 주세요.'), findsOneWidget);
      expect(find.text('지금 정리하기'), findsOneWidget);
    });

    testWidgets('보고서를 닫으면 목록의 점을 다시 센다', (tester) async {
      var read = false;
      final a = account((request) async {
        if (request.url.path == '/api/agent/read') read = true;
        return request.url.path == '/api/agent'
            ? reply(agentBody(read: read))
            : server(request);
      });
      await tester.pumpWidget(
        app(NotesListPage(store: NotesStore(), account: a, onOpen: (_) {})),
      );
      await tester.pumpAndSettle();
      final dot = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == '새 보고서',
      );
      expect(dot, findsOneWidget);

      await tester.tap(find.text('트레이너 보고'));
      await tester.pumpAndSettle();
      expect(read, isTrue);
      // 알림으로 연 화면(main 의 _openReport)도 같은 pushTrainer 를 지난다.
      Navigator.of(tester.element(find.byType(TrainerPage))).pop();
      await tester.pumpAndSettle();
      expect(dot, findsNothing);
    });

    testWidgets('문구 복사는 화면 아래 해요체로 잠깐 알린다', (tester) async {
      final copied = <Object?>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text']);
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      tall(tester);
      await tester.pumpWidget(
        app(TrainerPage(account: account(server), gymId: gymId)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('문구 복사').first); // 재등록
      await tester.pump();
      expect(copied, ['민수님, 이용권이 곧 끝나요.']);
      expect(find.text('복사했어요'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('복사했어요'), findsNothing);
    });

    testWidgets('직원 도장이 둘이면 어느 도장인지 묻고, 돌아갈 수 있다', (tester) async {
      final a = account(server)
        ..staff = [
          (gymId: gymId, gym: 'BPM 강남'),
          (gymId: '55555555-5555-4555-8555-555555555555', gym: 'BPM 역삼'),
        ];
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => openTrainer(context, a),
              child: const Text('열기'),
            ),
          ),
        ),
      );
      await tapText(tester, '열기');
      expect(find.text('어느 도장인가요?'), findsOneWidget);
      await tapText(tester, '돌아가기');
      expect(find.byType(TrainerPage), findsNothing);
    });

    testWidgets('설정의 트레이너 보고는 회원용 체육관 섹션 밖, 트레이너 섹션에 있다', (tester) async {
      tall(tester);
      await tester.pumpWidget(
        app(SettingsPage(store: NotesStore(), account: account(server))),
      );
      await tester.pumpAndSettle();
      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(top('다니는 체육관'), lessThan(top('트레이너')));
      expect(top('트레이너'), lessThan(top('트레이너 보고')));
    });
  });
}
