import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/account.dart';
import 'package:setpad/booking_page.dart';
import 'package:setpad/editor.dart' show ExerciseBlock;
import 'package:setpad/gym.dart';
import 'package:setpad/gym_page.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart' show EditorPage, SetpadApp;
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/trainer.dart' show shortWhen;

/// 회원 쪽 도장 — 원격 푸시도 웹 회원 화면도 닿지 않는 앱만 쓰는 회원에게 도장이 알리는 것
/// (GET /api/gyms, 계약 C5): 공지·이용권·락커·PT 변화·초대, 그리고 수업 예약과 나가기.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // http.Response(String) 은 charset 이 없으면 latin1 이라 한글이 깨진다.
  http.Response json(Object body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final at = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 19);

  Map<String, Object?> booking(String id, String status, DateTime when) => {
    'id': id,
    'startsAt': when.toUtc().toIso8601String(),
    'endsAt': when.add(const Duration(minutes: 50)).toUtc().toIso8601String(),
    'trainer': '김코치',
    'trainerId': 't1',
    'status': status,
  };

  Map<String, Object?> gymJson({List<Object?> bookings = const []}) => {
    'id': 'g1',
    'name': 'BPM',
    'trainer': '김코치',
    'trainerId': 't1',
    'notices': [
      {
        'id': 'n1',
        'title': '추석 연휴 휴관',
        'body': '10/5~10/7 쉽니다.',
        'pinned': true,
        'createdAt': '2026-10-01T00:00:00.000Z',
      },
    ],
    'access': {
      'membership': {'name': '3개월', 'endsOn': '2026-12-31', 'paused': false},
      'pt': {'name': 'PT 10회', 'remaining': 7, 'endsOn': null, 'paused': false},
    },
    'locker': {'label': 'A-12', 'endsOn': '2026-12-31'},
    'bookings': bookings,
  };

  Widget app(Widget home, {GlobalKey<NavigatorState>? navigator}) =>
      CupertinoApp(
        navigatorKey: navigator,
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: home,
      );

  test('도장 목록은 공지·이용권·락커·앞으로의 PT·초대를 읽고, 못 읽은 한 줄만 버린다', () async {
    final link = GymLink(
      endpoint: 'https://example.com',
      token: 'x',
      client: MockClient(
        (_) async => json({
          'gyms': [
            {
              ...gymJson(bookings: [booking('b1', 'rejected', at)]),
              'notices': [
                (gymJson()['notices'] as List).single,
                {'id': 'broken'},
              ],
            },
            // 옛 서버의 모양 — 이름과 담당만.
            {'id': 'g2', 'name': 'Core', 'trainer': null},
            {'name': 'id 없음'},
          ],
          'invites': [
            {
              'gymId': 'g3',
              'gymName': '짐박스',
              'invitedBy': '이관장',
              'createdAt': '2026-10-12T00:00:00.000Z',
            },
          ],
        }),
      ),
    );
    final found = (await link.gyms())!;
    expect(found.gyms.map((g) => g.id), ['g1', 'g2']);
    final gym = found.gyms.first;
    expect(gym.notices.single.title, '추석 연휴 휴관');
    expect(gym.notices.single.pinned, isTrue);
    expect(gym.membership!.endsOn, DateTime(2026, 12, 31));
    expect(gym.pt!.remaining, 7);
    expect(gym.locker!.label, 'A-12');
    expect(gym.bookings.single.status, 'rejected');
    expect(gym.bookings.single.startsAt, at);
    final old = found.gyms.last;
    expect(old.notices, isEmpty);
    expect(old.membership, isNull);
    expect(old.bookings, isEmpty);
    expect(found.invites.single, (
      gymId: 'g3',
      gymName: '짐박스',
      invitedBy: '이관장',
    ));
  });

  test('내 이용권 한 줄 — 정지는 정지라고, 없으면 없다고 말한다', () async {
    final l = await L.delegate.load(const Locale('ko'));
    expect(passLines(l, Gym.fromJson(gymJson())), [
      '회원권 12/31까지',
      'PT 7회 남음',
      '락커 A-12(12/31까지)',
    ]);
    const paused = (name: '3개월', endsOn: null, paused: true, remaining: 3);
    expect(
      passLines(
        l,
        const Gym(id: 'g', name: 'g', membership: paused, pt: paused),
      ),
      ['회원권 정지 중', 'PT 정지 중'],
    );
    expect(passLines(l, const Gym(id: 'g', name: 'g')), ['쓸 수 있는 회원권이 없어요']);
  });

  test('도장 소식은 지난번 본 것과 견준다 — 회원이 스스로 낸 신청·취소는 소식이 아니고, 무거운 것부터', () async {
    final when = DateTime.utc(2026, 10, 14, 10);
    GymBooking b(
      String id,
      String status, {
      DateTime? at,
      String? trainer,
      String? trainerId = 't1',
    }) => (
      id: id,
      startsAt: at ?? when,
      trainer: trainer ?? '김코치',
      trainerId: trainerId,
      status: status,
    );
    Gym gym(
      List<GymBooking> bookings, {
      String trainerId = 't1',
      List<GymNotice> notices = const [],
    }) => Gym(
      id: 'g1',
      name: 'BPM',
      trainer: '김코치',
      trainerId: trainerId,
      bookings: bookings,
      notices: notices,
    );

    final before = gym([
      b('p', 'pending'),
      b('same', 'booked'),
      b('mv', 'booked'),
      b('tr', 'booked'),
      b('sub', 'booked'),
      b('old', 'booked'),
      b('x', 'booked'),
    ]);
    final seen = gymSeenOf(before);
    expect(gymNews(before, seen), isEmpty);

    final after = gym(
      [
        b('p', 'booked'), // 승인됐다
        b('same', 'booked'),
        b('mv', 'booked', at: when.add(const Duration(hours: 1))),
        // 같은 트레이너가 닉네임만 바꿨다 — id 가 같으니 담당 변경이 아니다.
        b('tr', 'booked', trainer: '김트레이너'),
        b('sub', 'booked', trainer: '박코치', trainerId: 't9'), // 대강
        b('old', 'booked', trainerId: null), // 담당 id 를 모르는 옛 서버

        b('x', 'cancelled'),
        b('mine', 'pending'), // 회원이 낸 신청
        b('gone', 'cancelled'), // 처음 보는 취소 — 대개 회원이 한 것
        b('no', 'rejected'),
        b('given', 'booked'), // 트레이너가 잡아 줬다
      ],
      trainerId: 't2',
      notices: [
        (id: 'n1', title: '휴관', body: '', pinned: true, createdAt: when),
      ],
    );
    expect(
      [for (final n in gymNews(after, seen)) (n.key, n.change)],
      [
        ('b:no', GymChange.rejected),
        ('b:x', GymChange.cancelled),
        ('b:mv', GymChange.moved),
        ('b:sub', GymChange.trainer),
        ('b:p', GymChange.booked),
        ('b:given', GymChange.booked),
        ('t:g1', GymChange.assigned),
        ('n:n1', GymChange.notice),
      ],
    );
    expect(gymNews(after, {...seen, ...gymSeenOf(after)}), isEmpty);

    await initializeDateFormatting('ko');
    final l = await L.delegate.load(const Locale('ko'));
    final sub = gymNews(after, seen).firstWhere((n) => n.key == 'b:sub');
    expect(
      newsText(l, after, sub),
      'PT 담당 변경 · 박코치 트레이너 · ${shortWhen(l, when)}',
    );
  });

  test('본 도장 소식은 저장했다 다시 읽어도 남고, 300개를 넘으면 오래 본 것부터 버린다', () async {
    final dir = Directory.systemTemp.createTempSync('setpad-gym-seen');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = NotesStore(directory: dir)..seedGymSeen('u1', {'n:old': ''});
    store.markGymSeen({for (var i = 0; i < 300; i++) 'b:$i': 'booked'});
    expect(store.gymSeen, hasLength(300));
    expect(store.gymSeen.containsKey('n:old'), isFalse);
    await store.flush();

    final again = NotesStore(directory: dir);
    addTearDown(again.dispose);
    await again.load();
    expect(again.gymSeenOwner, 'u1');
    expect(again.gymSeen, store.gymSeen);
  });

  test('초대 답·나가기·닉네임·수업은 서버가 읽는 모양으로 보내고 답을 가른다', () async {
    final sent = <String>[];
    final bodies = <Object?>[];
    var answer = json({'ok': true});
    final link = GymLink(
      endpoint: 'https://example.com',
      token: 'x',
      client: MockClient((request) async {
        sent.add('${request.method} ${request.url.path}');
        bodies.add(request.body.isEmpty ? null : jsonDecode(request.body));
        return answer;
      }),
    );

    expect(await link.answerInvite('g1', accept: true), InviteAnswer.done);
    expect(bodies.last, {'accept': true, 'consentVersion': gymConsentVersion});
    expect(await link.answerInvite('g1', accept: false), InviteAnswer.done);
    expect(bodies.last, {'accept': false}, reason: '거절은 동의가 아니다');
    expect(sent.last, 'POST /api/gyms/g1/invite');
    for (final (reply, expected) in [
      (json({'error': 'notFound'}, 404), InviteAnswer.gone),
      (
        json({'error': 'ageConfirmationRequired'}, 403),
        InviteAnswer.ageRequired,
      ),
      (json({}, 500), InviteAnswer.failed),
    ]) {
      answer = reply;
      expect(await link.answerInvite('g1', accept: true), expected);
    }

    answer = json({'ok': true});
    expect(await link.leaveGym('g1'), isTrue);
    expect(sent.last, 'DELETE /api/gyms/g1/membership');

    expect(await link.changeNickname('새이름'), isNull);
    expect(sent.last, 'POST /api/me/nickname');
    expect(bodies.last, {'nickname': '새이름'});
    for (final (reply, expected) in [
      (json({'error': 'nicknameTaken'}, 409), 'nicknameTaken'),
      (json({'error': 'invalidNickname'}, 400), 'invalidNickname'),
      (json({}, 503), ''),
    ]) {
      answer = reply;
      expect(await link.changeNickname('누구'), expected);
    }

    answer = json({'error': 'full', 'message': '자리가 다 찼어요.'}, 409);
    expect(await link.bookClass('c1'), '자리가 다 찼어요.');
    expect(sent.last, 'POST /api/classes/c1/booking');
    answer = json({'ok': true});
    expect(await link.cancelClass('c1'), isNull);
    expect(sent.last, 'DELETE /api/classes/c1/booking');

    final offline = GymLink(
      endpoint: 'https://example.com',
      token: 'x',
      client: MockClient((_) async => throw const SocketException('꺼짐')),
    );
    expect(await offline.leaveGym('g1'), isFalse);
    expect(await offline.bookClass('c1'), '', reason: '못 닿았으면 까닭이 없다');
    expect(await offline.classes('g1'), isNull, reason: '수업이 없는 것과 다르다');
    expect(await offline.changeNickname('누구'), '');
  });

  testWidgets('트레이너가 PT 를 거절하면 첫 화면의 도장 줄이 말하고, 도장을 열면 표시한 뒤 본 것으로 적는다', (
    tester,
  ) async {
    var status = 'pending';
    final account =
        Account(
            client: MockClient(
              (request) async => request.url.path == '/api/gyms'
                  ? json({
                      'gyms': [
                        gymJson(bookings: [booking('b1', status, at)]),
                      ],
                      'invites': [],
                    })
                  : json({'routines': [], 'plan': null, 'selling': false}),
            ),
          )
          ..token = 'x'
          ..userId = 'u1';
    final store = NotesStore();
    await tester.pumpWidget(
      app(NotesListPage(store: store, account: account, onOpen: (_) {})),
    );
    await tester.pumpAndSettle();
    final l = await L.delegate.load(const Locale('ko'));
    final rejected = l.newsRejected(shortWhen(l, at));

    // 처음 받은 것은 모두 본 것이다 — 그 전부터 있던 공지가 새 소식이 되지 않는다.
    expect(store.gymSeenOwner, 'u1');
    expect(
      find.text('회원권 12/31까지 · PT 7회 남음 · 락커 A-12(12/31까지)'),
      findsOneWidget,
    );

    status = 'rejected';
    unawaited(account.refreshGyms());
    await tester.pumpAndSettle();
    expect(find.text(rejected), findsOneWidget);

    await tester.tap(find.text('BPM'));
    await tester.pumpAndSettle();
    expect(find.byType(GymPage), findsOneWidget);
    expect(find.text('추석 연휴 휴관'), findsOneWidget);
    expect(
      find.text(rejected),
      findsOneWidget,
      reason: '무엇이 바뀌었는지 도장 화면에도 표시한다',
    );
    expect(store.gymSeen['b:b1'], bookingSeen('rejected', at, 't1'));

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(rejected), findsNothing);
    expect(
      find.text('회원권 12/31까지 · PT 7회 남음 · 락커 A-12(12/31까지)'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 1)); // 저장 디바운스
  });

  testWidgets('처음 맡은 트레이너는 소식이 아니지만 남겨 두어, 그 뒤 바뀌면 도장 화면을 안 열어도 알린다', (
    tester,
  ) async {
    String? trainer, trainerId;
    final account =
        Account(
            client: MockClient(
              (request) async => request.url.path == '/api/gyms'
                  ? json({
                      'gyms': [
                        {
                          ...gymJson(),
                          'trainer': trainer,
                          'trainerId': trainerId,
                        },
                      ],
                      'invites': [],
                    })
                  : json({'routines': [], 'plan': null, 'selling': false}),
            ),
          )
          ..token = 'x'
          ..userId = 'u1';
    final store = NotesStore();
    await tester.pumpWidget(
      app(NotesListPage(store: store, account: account, onOpen: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(store.gymSeenOwner, 'u1');
    expect(store.gymSeen.containsKey('t:g1'), isFalse, reason: '아직 담당이 없다');
    final l = await L.delegate.load(const Locale('ko'));

    (trainer, trainerId) = ('김코치', 't1');
    unawaited(account.refreshGyms());
    await tester.pumpAndSettle();
    expect(store.gymSeen['t:g1'], 't1');
    expect(find.text(l.newsAssigned('김코치')), findsNothing);

    (trainer, trainerId) = ('박코치', 't2');
    unawaited(account.refreshGyms());
    await tester.pumpAndSettle();
    expect(find.text(l.newsAssigned('박코치')), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); // 저장 디바운스
  });

  testWidgets('식단 공유는 켤 때 고른 도장과의 것이다 — 그 도장에서 나가면(내보내져도) 꺼진다', (tester) async {
    var member = true;
    final account =
        Account(
            client: MockClient(
              (request) async => request.url.path == '/api/gyms'
                  ? json({
                      'gyms': [if (member) gymJson()],
                      'invites': [],
                    })
                  : json({'routines': [], 'plan': null, 'selling': false}),
            ),
          )
          ..token = 'x'
          ..userId = 'u1';
    final store = NotesStore()..setShareMeals('g1');
    await tester.pumpWidget(
      app(NotesListPage(store: store, account: account, onOpen: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(store.shareMealsGym, 'g1', reason: '아직 다닌다');

    member = false; // 트레이너가 내보냈다
    unawaited(account.refreshGyms());
    await tester.pumpAndSettle();
    expect(store.sharesMeals, isFalse, reason: '다음에 등록한 도장으로 이어지지 않게');
    await tester.pump(const Duration(seconds: 1)); // 저장 디바운스
  });

  testWidgets('단톡방 수업 링크로 앱이 켜지면 도장 목록이 오기를 기다려 수업 화면을 한 번만 연다', (
    tester,
  ) async {
    // 앱이 꺼진 채 링크를 눌렀다. 로그인은 남아 있고 도장 목록은 아직 안 왔다(목록 화면이
    // 따로 묻는다). 링크는 처음 링크와 스트림으로 두 번 온다.
    final dir = Directory.systemTemp.createTempSync('setpad-classes-link');
    addTearDown(() => dir.deleteSync(recursive: true));
    final gyms = Completer<void>();
    final account = Account(
      storageDir: dir,
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/gyms':
            await gyms.future;
            return json({
              'gyms': [gymJson()],
              'invites': [],
            });
          case '/api/me':
            return json({
              'user': {'id': 'u1', 'nickname': 'kim'},
            });
          case '/api/classes':
            return json({'classes': []});
        }
        return json({'routines': [], 'plan': null, 'selling': false});
      }),
    )..token = 'x';
    final links = StreamController<Uri>();
    addTearDown(links.close);
    await tester.pumpWidget(
      SetpadApp(
        store: NotesStore(directory: dir),
        tags: links.stream,
        account: account,
      ),
    );
    await tester.pump();
    final link = Uri.parse('https://gym.darak.studio/c/g1/classes');
    links
      ..add(link)
      ..add(link);
    // 가려진 화면도 센다 — 두 겹 쌓이면 아래 것은 화면 밖(offstage)에 있다.
    final classes = find.byType(ClassesPage, skipOffstage: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(classes, findsNothing);

    gyms.complete();
    await tester.pumpAndSettle();
    expect(classes, findsOneWidget);
  });

  testWidgets('스티커로 앱이 켜지면 오늘 적던 기록을 밑에 펴지 않는다 — 편집기는 받은 루틴 하나다', (
    tester,
  ) async {
    // 앱이 꺼진 채 스티커를 댔다. 오늘 적던 기록이 따로 있다. 링크는 처음 링크와 스트림으로
    // 두 번 오고, 루틴은 저장소를 읽은 뒤에 온다. 예전에는 오늘 기록이 먼저 펴지고 루틴이 그
    // 위에 쌓여, 목록까지 완료를 두 번 눌러야 했다.
    final dir = Directory.systemTemp.createTempSync('setpad-sticker-cold');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = NotesStore(directory: dir);
    final earlier = store.create()..blocks.add(ExerciseBlock('벤치프레스'));
    final routines = Completer<void>();
    final account = Account(
      storageDir: dir,
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/me':
            return json({
              'user': {'id': 'u1', 'nickname': 'kim'},
            });
          case '/api/gyms':
            return json({
              'gyms': [gymJson()],
              'invites': [],
            });
          case '/api/routines':
            await routines.future;
            return json({
              'routines': [
                {
                  'id': 'r1',
                  'gym_id': 'g1',
                  'gym': 'BPM',
                  'title': '하체',
                  'items': [
                    {'name': '스쿼트', 'sets': []},
                  ],
                },
              ],
            });
        }
        return json({'plan': null, 'selling': false});
      }),
    )..token = 'x';
    final sticker = Uri.parse('https://gym.darak.studio/c/g1');
    final links = StreamController<Uri>();
    addTearDown(links.close);
    await tester.pumpWidget(
      SetpadApp(
        store: store,
        tags: links.stream,
        firstTag: Future.value(sticker),
        account: account,
      ),
    );
    links.add(sticker);
    // 가려진 화면도 센다 — 두 겹 쌓이면 아래 것은 화면 밖(offstage)에 있다.
    List<Note> editors() => [
      for (final page in tester.widgetList<EditorPage>(
        find.byType(EditorPage, skipOffstage: false),
      ))
        page.note,
    ];
    await tester.pumpAndSettle();
    expect(editors(), isEmpty, reason: '루틴이 오기 전에 오늘 기록을 펴지 않는다');

    routines.complete();
    await tester.pumpAndSettle();
    expect(editors().map((n) => n.routineId), ['r1']);
    expect(store.notes, contains(earlier), reason: '오늘 적던 기록은 목록에 그대로다');
    await tester.pump(const Duration(seconds: 1)); // 저장 디바운스
  });

  testWidgets('도장 초대는 안내를 보여 주고, 받으면 그 판을 동의로 보낸다 — 나이 확인이 없는 계정은 한 번 묻는다', (
    tester,
  ) async {
    final posts = <String>[];
    final bodies = <Object?>[];
    var adult = false, member = false;
    final account =
        Account(
            client: MockClient((request) async {
              if (request.method == 'POST') posts.add(request.url.path);
              switch (request.url.path) {
                case '/api/gyms':
                  return json({
                    'gyms': [if (member) gymJson()],
                    'invites': [
                      if (!member)
                        {'gymId': 'g1', 'gymName': 'BPM', 'invitedBy': '이관장'},
                    ],
                  });
                case '/api/gyms/g1/invite':
                  bodies.add(jsonDecode(request.body));
                  if (!adult) {
                    return json({'error': 'ageConfirmationRequired'}, 403);
                  }
                  member = true;
                  return json({'ok': true});
                case '/api/me/age':
                  adult = true;
                  return json({'ok': true});
              }
              return json({'routines': [], 'plan': null, 'selling': false});
            }),
          )
          ..token = 'x'
          ..userId = 'u1';
    await tester.pumpWidget(
      app(NotesListPage(store: NotesStore(), account: account, onOpen: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(find.text('이관장 님이 보냈어요'), findsOneWidget);

    await tester.tap(find.text('BPM에서 초대했어요'));
    await tester.pumpAndSettle();
    expect(find.textContaining('관장·트레이너가 닉네임'), findsOneWidget);
    expect(find.byKey(const ValueKey('gym-consent-privacy')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gym-consent-agree')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('age-confirm')));
    await tester.pumpAndSettle();

    expect(posts, [
      '/api/gyms/g1/invite',
      '/api/me/age',
      '/api/gyms/g1/invite',
    ]);
    expect(bodies, [
      for (var i = 0; i < 2; i++)
        {'accept': true, 'consentVersion': gymConsentVersion},
    ]);
    expect(account.gyms.single.id, 'g1');
    expect(find.text('BPM에서 초대했어요'), findsNothing);
    expect(find.text('BPM'), findsOneWidget, reason: '받은 도장이 바로 목록에 들어온다');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('도장에서 나가면 한 번 묻고, 나가면 그 도장이 바로 빠지고 화면이 닫힌다', (tester) async {
    final sent = <String>[];
    var left = false;
    final account =
        Account(
            client: MockClient((request) async {
              sent.add('${request.method} ${request.url.path}');
              if (request.method == 'DELETE') {
                left = true;
                return json({'ok': true});
              }
              return json({
                'gyms': [if (!left) gymJson()],
                'invites': [],
              });
            }),
          )
          ..token = 'x'
          ..gyms = [Gym.fromJson(gymJson())];
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(app(const SizedBox(), navigator: navigator));
    unawaited(
      navigator.currentState!.push(
        CupertinoPageRoute<void>(
          builder: (_) =>
              GymPage(account: account, store: NotesStore(), gymId: 'g1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('회원권 12/31까지'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('gym-leave')),
      100,
    );
    await tester.tap(find.byKey(const ValueKey('gym-leave')));
    await tester.pumpAndSettle();
    expect(find.textContaining('BPM에서 나갈까요?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gym-leave-confirm')));
    await tester.pumpAndSettle();

    expect(sent, contains('DELETE /api/gyms/g1/membership'));
    expect(account.gyms, isEmpty);
    expect(find.byType(GymPage), findsNothing);
  });

  testWidgets('수업은 날짜로 묶어 보이고, 못 잡으면 서버가 적은 까닭을, 내 수업은 한 번 묻고 취소한다', (
    tester,
  ) async {
    final day = DateTime.now().add(const Duration(days: 2));
    Map<String, Object?> lesson(
      String id,
      String title,
      int hour, {
      String status = 'open',
      bool mine = false,
      int booked = 3,
    }) {
      final start = DateTime(day.year, day.month, day.day, hour);
      return {
        'id': id,
        'title': title,
        'startsAt': start.toUtc().toIso8601String(),
        'endsAt': start
            .add(const Duration(minutes: 50))
            .toUtc()
            .toIso8601String(),
        'trainer': '김코치',
        'capacity': 10,
        'booked': booked,
        'mine': mine,
        'status': status,
      };
    }

    final sent = <String>[];
    final account = Account(
      client: MockClient((request) async {
        sent.add('${request.method} ${request.url.path}?${request.url.query}');
        if (request.method == 'POST') {
          return json({'error': 'full', 'message': '자리가 다 찼어요.'}, 409);
        }
        if (request.method == 'DELETE') return json({'ok': true});
        return json({
          'classes': [
            lesson('c1', '요가', 9),
            lesson('c2', '스피닝', 10, status: 'full', booked: 10),
            lesson('c3', '필라테스', 19, mine: true),
            lesson('c4', '줌바', 20, status: 'cancelled'),
          ],
        });
      }),
    )..token = 'x';
    await tester.pumpWidget(app(ClassesPage(account: account, gymId: 'g1')));
    await tester.pumpAndSettle();
    expect(sent.first, 'GET /api/classes?gym=g1');
    expect(find.text('예약 3/10'), findsOneWidget);
    expect(find.text('마감 10/10'), findsOneWidget);
    expect(find.text('예약됨 · 취소'), findsOneWidget);
    expect(find.text('휴강'), findsOneWidget);
    expect(find.text('09:00–09:50 · 김코치'), findsOneWidget);

    await tester.tap(find.text('예약 3/10'));
    await tester.pumpAndSettle();
    expect(sent, contains('POST /api/classes/c1/booking?'));
    expect(find.text('자리가 다 찼어요.'), findsOneWidget);

    await tester.tap(find.text('마감 10/10'));
    await tester.pumpAndSettle();
    expect(
      sent.where((s) => s.contains('c2')),
      isEmpty,
      reason: '찬 수업은 누를 수 없다',
    );

    await tester.tap(find.text('예약됨 · 취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('class-cancel-confirm')));
    await tester.pumpAndSettle();
    expect(sent, contains('DELETE /api/classes/c3/booking?'));
    expect(find.text('자리가 다 찼어요.'), findsNothing, reason: '이번에는 잘됐다');
  });

  Account bookingServer({
    required bool paused,
    required DateTime soon,
    required DateTime slot,
  }) {
    var booked = false;
    return Account(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            booked = true;
            return json({'id': 'new', 'status': 'booked'});
          }
          if (request.method == 'DELETE') return json({'ok': true});
          return json({
            'bookings': [
              {
                'id': 'old',
                'gym': 'BPM',
                'trainer': '김코치',
                'trainer_id': 't1',
                'starts_at': soon.toUtc().toIso8601String(),
                'status': 'booked',
              },
              if (booked)
                {
                  'id': 'new',
                  'gym': 'BPM',
                  'trainer': '김코치',
                  'trainer_id': 't1',
                  'starts_at': slot.toUtc().toIso8601String(),
                  'status': 'booked',
                },
            ],
            'slots': request.url.queryParameters.containsKey('day')
                ? [slot.toUtc().toIso8601String()]
                : [],
            'weekdays': [0, 1, 2, 3, 4, 5, 6],
            'trainer': '김코치',
            'duration_min': 50,
            'pass': paused ? null : {'remaining': 3},
            'paused': paused,
          });
        }),
      )
      ..token = 'x'
      ..userId = 'u1';
  }

  testWidgets('예약 화면: 이용권이 정지 중이면 없다고 하지 않고 정지라고 말한다', (tester) async {
    await tester.pumpWidget(
      app(
        BookingPage(
          account: bookingServer(paused: true, soon: at, slot: at),
          gymId: 'g1',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('PT 이용권이 정지 중이에요. 트레이너에게 문의해 주세요.'), findsOneWidget);
    expect(find.text('PT 이용권이 없습니다. 트레이너에게 문의해 주세요.'), findsNothing);
  });

  testWidgets('예약 화면에서 회원이 한 신청·취소는 첫 화면의 도장 소식이 되지 않는다', (tester) async {
    final soon = at.add(const Duration(days: 1));
    final slot = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 15);
    final store = NotesStore()..seedGymSeen('u1', {});
    await tester.pumpWidget(
      app(
        BookingPage(
          account: bookingServer(paused: false, soon: soon, slot: slot),
          gymId: 'g1',
          store: store,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('${tomorrow.day}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('예약 취소').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CupertinoDialogAction, '예약 취소'));
    await tester.pumpAndSettle();

    expect(store.gymSeen, {
      'b:new': bookingSeen('booked', slot, 't1'),
      'b:old': bookingSeen('cancelled', soon, 't1'),
    });
    final gym = Gym(
      id: 'g1',
      name: 'BPM',
      bookings: [
        (
          id: 'new',
          startsAt: slot,
          trainer: '김코치',
          trainerId: 't1',
          status: 'booked',
        ),
        (
          id: 'old',
          startsAt: soon,
          trainer: '김코치',
          trainerId: 't1',
          status: 'cancelled',
        ),
      ],
    );
    expect(gymNews(gym, store.gymSeen), isEmpty, reason: '회원이 방금 한 일이다');
    await tester.pump(const Duration(seconds: 1)); // 저장 디바운스
  });
}
