// 같이 하기 — 두 기기가 같은 서버를 보고 연결하고, 기록을 주고받고, 끝낸다.
//
// 서버는 lib/partner-sessions.ts 와 같은 규칙의 가짜다. 진짜 서버의 규칙은
// gymdojo 의 partner-sessions.test.ts 가 실제 Postgres 로 지킨다.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoApp, CupertinoTextField;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/daily.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart' show EditorPage;
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';

/// 한 서버, 여러 사람. 토큰이 곧 사람이다.
class FakeServer {
  final sessions = <String, Map<String, Object?>>{};
  final records = <String, Map<String, Object?>>{}; // '$session/$user'
  var online = true;
  int? failWith;
  Duration delay = Duration.zero;
  var joins = 0;
  var recordPuts = 0;
  var n = 0;

  /// 서버의 시계(ms). 같이 하는 타이머의 시작 시각을 이것으로 찍는다.
  int Function() now = () => DateTime.now().millisecondsSinceEpoch;

  http.Client clientFor(String user) => MockClient((request) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (!online) throw http.ClientException('offline');
    if (failWith != null) return http.Response('{"error":"boom"}', failWith!);
    if (user == 'expired-token') {
      return http.Response('{"error":"signInRequired"}', 401);
    }
    final path = request.url.path.split('/').skip(3).toList();
    final body = request.body.isEmpty
        ? const <String, Object?>{}
        : (jsonDecode(request.body) as Map).cast<String, Object?>();
    http.Response reply(int status, Map<String, Object?> json) =>
        http.Response.bytes(utf8.encode(jsonEncode(json)), status);
    Map<String, Object?> describe(Map<String, Object?> s) {
      final host = s['host'] == user;
      final other = host ? s['guest'] : s['host'];
      final state = s['ended'] != null
          ? 'ended'
          : s['guest'] != null
          ? 'active'
          : (s['expires'] as DateTime).isBefore(DateTime.now())
          ? 'expired'
          : 'waiting';
      final theirs = records['${s['id']}/$other'];
      return {
        'id': s['id'],
        'state': state,
        'role': host ? 'host' : 'guest',
        if (state == 'waiting' && host) ...{
          'code': s['code'],
          'token': s['token'],
          'expiresAt': (s['expires'] as DateTime).toIso8601String(),
        },
        'partner': other,
        'endedByMe': s['ended'] == null ? null : s['ended'] == user,
        'myRevision': records['${s['id']}/$user']?['revision'] ?? 0,
        'partnerRecord': state == 'active' ? theirs : null,
        'now': now(),
        'timer': state == 'active' && (s['timer'] as Map?)?['title'] != null
            ? {
                for (final k in [
                  'seq',
                  'title',
                  'spec',
                  'alternate',
                  'startAt',
                ])
                  k: (s['timer'] as Map)[k],
                'mine': (s['timer'] as Map)['by'] == user,
                'myLeft': ((s['timer'] as Map)['left'] as Map)[user],
                'partnerLeft': ((s['timer'] as Map)['left'] as Map)[other],
              }
            : null,
      };
    }

    if (path.isEmpty) {
      final open = sessions.values.where(
        (s) =>
            s['host'] == user &&
            s['local'] == body['localId'] &&
            s['ended'] == null,
      );
      final created = open.isEmpty;
      final s =
          open.firstOrNull ??
          {'id': 'S${++n}', 'host': user, 'local': body['localId']};
      if (s['guest'] == null &&
          (s['code'] == null ||
              body['renew'] == true ||
              (s['expires'] as DateTime).isBefore(DateTime.now()))) {
        s['code'] =
            'ABCD${(++n).toString().padLeft(2, '2').replaceAll('0', '3').replaceAll('1', '4')}';
        s['token'] = 'token-${'x' * 20}$n';
        s['expires'] = DateTime.now().add(const Duration(minutes: 10));
      }
      sessions[s['id'] as String] = s;
      return reply(200, {...describe(s), 'created': created});
    }
    if (path.length == 1 && path[0] == 'join') {
      joins++;
      final mine = sessions.values.where(
        (s) =>
            s['guest'] == user &&
            s['guestLocal'] == body['localId'] &&
            s['ended'] == null,
      );
      final found = sessions.values.where(
        (s) =>
            (s['code'] != null && s['code'] == body['code']) ||
            (s['token'] != null && s['token'] == body['token']),
      );
      final s = found.firstOrNull;
      if (s != null &&
          s['guest'] == null &&
          s['ended'] == null &&
          s['host'] != user &&
          (s['expires'] as DateTime).isAfter(DateTime.now())) {
        s
          ..['guest'] = user
          ..['guestLocal'] = body['localId']
          ..['code'] = null
          ..['token'] = null;
        return reply(200, {...describe(s), 'claimed': true});
      }
      if (mine.isNotEmpty) {
        return reply(200, {...describe(mine.first), 'claimed': false});
      }
      if (s?['host'] == user) return reply(409, {'error': 'ownInvite'});
      if (s?['ended'] != null) return reply(410, {'error': 'ended'});
      if (s != null) return reply(410, {'error': 'expired'});
      return reply(404, {'error': 'invalidCode'});
    }
    final s = sessions[path[0]];
    if (s == null || (s['host'] != user && s['guest'] != user)) {
      return reply(404, {'error': 'notFound'});
    }
    if (path.length == 1) return reply(200, describe(s));
    if (path[1] == 'end') {
      s['ended'] ??= user;
      s['code'] = s['token'] = null;
      records.removeWhere((k, _) => k.startsWith('${s['id']}/'));
      return reply(200, describe(s));
    }
    if (s['ended'] != null) return reply(410, {'error': 'ended'});
    if (path[1] == 'timer') {
      // gymdojo 의 timerAction 과 같은 규칙: 조건이 안 맞으면 아무것도 바꾸지 않고
      // 지금의 사실을 돌려준다.
      final t = s['timer'] as Map<String, Object?>?;
      final current = t != null && t['seq'] == body['seq'];
      switch (body['action']) {
        case 'propose':
          s['timer'] = <String, Object?>{
            'seq': ((t?['seq'] as int?) ?? 0) + 1,
            'title': body['title'],
            'spec': body['spec'],
            'alternate': body['alternate'] == true,
            'by': user,
            'startAt': null,
            'left': <String, Object?>{},
          };
        case 'accept' when current && t['by'] != user && t['startAt'] == null:
          t['startAt'] = now() + 2500;
        case 'leave' when current && t['startAt'] != null:
          (t['left'] as Map)[user] = {'ms': body['ms'], 'beat': body['beat']};
        case 'rejoin' when current:
          (t['left'] as Map).remove(user);
        case 'clear' when current:
          // 번호는 남긴다 — 치워진 제안을 향한 늦은 동작이 다음 제안에 꽂히지 않게.
          s['timer'] = <String, Object?>{'seq': t['seq']};
      }
      return reply(200, describe(s));
    }
    // record — gymdojo 의 validResult 와 같은 상한.
    recordPuts++;
    final result = body['result'] as List;
    if (result.length > 100 ||
        result.any((b) => ((b as Map)['sets'] as List).length > 100) ||
        jsonEncode(result).length > 64000) {
      return reply(400, {'error': 'invalidInput'});
    }
    final key = '${s['id']}/$user';
    final stored = (records[key]?['revision'] as int?) ?? 0;
    final revision = body['revision'] as int;
    if (stored == revision) return reply(200, {'revision': revision});
    if (revision < stored ||
        (stored != body['base'] && body['force'] != true)) {
      return reply(409, {
        'error': 'conflict',
        'revision': stored,
        'result': records[key]?['result'] ?? [],
      });
    }
    records[key] = {
      'revision': revision,
      'result': body['result'],
      'updatedAt': DateTime.now().toIso8601String(),
    };
    return reply(200, {'revision': revision});
  });
}

class Phone {
  Phone(FakeServer server, this.user, String noteId)
    : note = Note(
        id: noteId,
        createdAt: DateTime(2026, 9, 21, 18),
        updatedAt: DateTime(2026, 9, 21, 19),
      ) {
    sync = PartnerSync(
      note: note,
      link: () => GymLink(
        endpoint: 'https://x',
        token: user,
        client: server.clientFor(user),
      ),
      onChanged: () => saves++,
    );
  }
  final String user;
  final Note note;
  late final PartnerSync sync;
  var saves = 0;

  /// 세트를 하나 적는다 — 먼저 문서에, 그다음 공유로.
  void log(String name, LoggedSet set) {
    final block = note.blocks.where((b) => b.name == name).firstOrNull;
    block == null
        ? note.blocks.add(ExerciseBlock(name, [set]))
        : block.sets.add(set);
    sync.recordChanged();
  }
}

Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 700));

void main() {
  test('초대 → 참여 → 양쪽이 같은 상태를 보고, 세트 추가·수정·삭제가 상대에게 간다', () async {
    final server = FakeServer();
    // 미나의 운동은 서버에 올린 적 없는 로컬 문서다 — 그래도 초대가 된다.
    final mina = Phone(server, '미나', '1726900000000001');
    final jun = Phone(server, '준', '1726900000000002');
    addTearDown(mina.sync.dispose);
    addTearDown(jun.sync.dispose);

    expect(await mina.sync.invite(), isNull);
    expect(mina.note.partner!.state, PartnerState.waiting);
    final code = mina.note.partner!.code!;
    // 코드를 받았다고 같이 운동 중인 것은 아니다.
    expect(mina.note.partner!.state, isNot(PartnerState.active));

    expect(await jun.sync.joinWithCode(' ${code.toLowerCase()} '), isNull);
    expect(jun.note.partner!.state, PartnerState.active);
    expect(jun.note.partner!.partnerName, '미나');
    // 초대한 쪽은 다음 확인 때 참여를 안다.
    await mina.sync.refresh();
    expect(mina.note.partner!.state, PartnerState.active);
    expect(mina.note.partner!.partnerName, '준');
    expect(mina.note.partner!.code, isNull);

    // 미나가 적는다: 사용자 운동명, lb, 메모, 안 한 세트까지.
    mina.log(
      '내 방식 벤치 변형',
      LoggedSet(value: 102.5, unit: 'lb', reps: 8, notes: ['어깨 조심']),
    );
    mina.log(
      '내 방식 벤치 변형',
      LoggedSet(value: 105, unit: 'lb', reps: 6, done: false),
    );
    await settle();
    await jun.sync.refresh();
    final seen = jun.note.partner!.partnerBlocks.single;
    expect(seen.name, '내 방식 벤치 변형');
    expect(seen.sets.map((s) => (s.value, s.unit, s.reps, s.done)), [
      (102.5, 'lb', 8, true),
      (105.0, 'lb', 6, false),
    ]);
    expect(seen.sets.first.notes, ['어깨 조심']);
    expect(jun.note.blocks, isEmpty, reason: '상대 기록이 내 운동 칸에 섞이지 않는다');

    // 준의 기록도 미나에게 간다.
    jun.log('풀업', LoggedSet(reps: 8));
    await settle();
    await mina.sync.refresh();
    expect(mina.note.partner!.partnerBlocks.single.name, '풀업');

    // 수정과 삭제.
    mina.note.blocks.single.sets
      ..removeLast()
      ..first.done = false;
    mina.sync.recordChanged();
    await settle();
    await jun.sync.refresh();
    expect(jun.note.partner!.partnerBlocks.single.sets, hasLength(1));
    expect(jun.note.partner!.partnerBlocks.single.sets.single.done, isFalse);

    // 파트너의 운동은 내 하루 집계에 들어가지 않는다.
    jun.note.calories = 300;
    final day = dayLogs(
      [jun.note],
      from: jun.note.createdAt,
      to: jun.note.createdAt,
    ).single;
    expect(day.notes.single.blocks.map((b) => b.name), ['풀업']);
    expect(day.burned, 300);
  });

  test('틀린 코드·만료·인증 만료·서버 오류·그물 끊김을 서로 다른 이유로 알린다', () async {
    final server = FakeServer();
    final mina = Phone(server, '미나', 'a1'), jun = Phone(server, '준', 'b1');
    addTearDown(mina.sync.dispose);
    addTearDown(jun.sync.dispose);

    // 모양이 틀린 코드는 서버에 묻지도 않는다.
    expect(await jun.sync.joinWithCode('ABC'), PartnerError.invalidFormat);
    expect(await jun.sync.joinWithCode('ABCD10'), PartnerError.invalidFormat);
    expect(server.joins, 0);
    expect(await jun.sync.joinWithCode('ZZZZZ9'), PartnerError.invalidCode);

    await mina.sync.invite();
    final code = mina.note.partner!.code!;
    expect(await mina.sync.joinWithCode(code), PartnerError.ownInvite);
    server.sessions.values.single['expires'] = DateTime.now().subtract(
      const Duration(minutes: 1),
    );
    expect(await jun.sync.joinWithCode(code), PartnerError.expired);
    // 만료된 초대는 새 코드로 다시 연다 — 같은 세션이다.
    await mina.sync.invite();
    expect(mina.note.partner!.code, isNot(code));
    expect(server.sessions, hasLength(1));

    server.failWith = 500;
    expect(
      await jun.sync.joinWithCode(mina.note.partner!.code!),
      PartnerError.server,
    );
    server.failWith = null;
    server.online = false;
    expect(
      await jun.sync.joinWithCode(mina.note.partner!.code!),
      PartnerError.network,
    );
    expect(jun.sync.reachable, isFalse);
    server.online = true;
    final stale = Phone(server, 'expired-token', 'c1');
    addTearDown(stale.sync.dispose);
    expect(await stale.sync.invite(), PartnerError.signInRequired);
    // 로그인하지 않았으면 그물에 나가지도 않는다.
    final anonymous = PartnerSync(
      note: Note(id: 'z', createdAt: DateTime(2026), updatedAt: DateTime(2026)),
      link: () => const GymLink(endpoint: 'https://x'),
      onChanged: () {},
    );
    addTearDown(anonymous.dispose);
    expect(await anonymous.invite(), PartnerError.signInRequired);
  });

  test('C·같이 하기 코드 칸에 받은 문구를 통째로 붙여 넣어도 코드를 뽑아 참여한다', () async {
    expect(normalizePartnerCode('한 명 더 초대 · 코드 AB3K9Z'), 'AB3K9Z');
    expect(normalizePartnerCode('Invite one more · code AB3K9Z'), 'AB3K9Z');
    expect(normalizePartnerCode(' ab3-k9z '), 'AB3K9Z');
    expect(
      normalizePartnerCode('AB3K9Z 아니면 CD4M8N'),
      isNull,
      reason: '둘이면 어느 것인지 모른다',
    );
    expect(
      normalizePartnerCode('https://x/plan/abcdefghijk_AB3K9Z-lmnopq'),
      isNull,
      reason: '링크 토큰 속 글자는 코드가 아니다',
    );

    final server = FakeServer();
    final mina = Phone(server, '미나', 'p1'), jun = Phone(server, '준', 'p2');
    addTearDown(mina.sync.dispose);
    addTearDown(jun.sync.dispose);
    await mina.sync.invite();
    final code = mina.note.partner!.code!;
    expect(await jun.sync.joinWithCode('한 명 더 초대 · 코드 $code'), isNull);
    expect(jun.note.partner!.state, PartnerState.active);
  });

  test('C·손으로 옮겨 적은 소문자 코드도 문장 속에서 찾는다 — 낱말이 하나일 때만', () {
    expect(normalizePartnerCode('코드 ab3k9z'), 'AB3K9Z');
    expect(normalizePartnerCode('code: ab3k9z'), 'AB3K9Z');
    // 원문 대문자 코드가 있으면 그것이다 — 소문자 영어 낱말이 코드처럼 보여도.
    expect(normalizePartnerCode('please join · code AB3K9Z'), 'AB3K9Z');
    expect(normalizePartnerCode('코드 ab3k9z 아니면 cd4m8n'), isNull);
  });

  testWidgets('C·같이 하기 코드 칸에 받은 문구를 붙여 넣으면 칸이 자르지 않고 그 코드로 참여한다', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('setpad_partner_paste_');
    final store = NotesStore(directory: dir);
    addTearDown(() => dir.deleteSync(recursive: true));
    final joins = <Map>[];
    final account = Account(
      storageDir: dir,
      client: MockClient((request) async {
        if (request.url.path.endsWith('/join')) {
          joins.add(jsonDecode(request.body) as Map);
          return http.Response('{"error":"invalidCode"}', 404);
        }
        return http.Response('{}', 200);
      }),
    )..token = 'member';
    final l = lookupL(const Locale('ko'));
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: EditorPage(store: store, note: store.create(), account: account),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('record-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-partner')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.partnerEnter));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('partner-code'));
    const pasted = '한 명 더 초대 · 코드 AB3K9Z';
    await tester.enterText(field, pasted);
    await tester.pump();
    expect(
      tester.widget<CupertinoTextField>(field).controller!.text,
      pasted,
      reason: '칸이 여덟 글자에서 자르면 코드가 사라진다',
    );
    await tester.tap(find.text(l.partnerEnter).last);
    await tester.pumpAndSettle();
    expect(joins.map((b) => b['code']), ['AB3K9Z']);
    expect(find.text(l.partnerErrFormat), findsNothing);
  });

  test('같은 토큰이 여러 번 들어와도, 응답을 못 받아 다시 보내도 참여는 한 번이다', () async {
    final server = FakeServer();
    final mina = Phone(server, '미나', 'a2'), jun = Phone(server, '준', 'b2');
    addTearDown(mina.sync.dispose);
    addTearDown(jun.sync.dispose);
    await mina.sync.invite();
    final token = mina.note.partner!.token!;
    // NFC 를 두 번 댔다 / 콜백이 겹쳤다.
    await Future.wait([
      jun.sync.joinWithToken(token),
      jun.sync.joinWithToken(token),
    ]);
    await jun.sync.joinWithToken(token);
    expect(server.joins, 1);
    expect(jun.note.partner!.state, PartnerState.active);
    // 응답이 유실돼 앱이 모르는 채로 다시 코드로 참여해도 같은 세션이다.
    final again = Phone(server, '준', 'b2');
    addTearDown(again.sync.dispose);
    expect(await again.sync.joinWithToken(token), isNull);
    expect(again.note.partner!.id, jun.note.partner!.id);
    expect(server.sessions, hasLength(1));
    // 초대를 두 번 눌러도 세션은 하나다.
    await mina.sync.invite();
    expect(server.sessions, hasLength(1));
  });

  test('취소한 뒤에 늦게 온 성공으로 다시 연결되지 않는다', () async {
    final server = FakeServer();
    final mina = Phone(server, '미나', 'a3'), jun = Phone(server, '준', 'b3');
    addTearDown(mina.sync.dispose);
    addTearDown(jun.sync.dispose);
    await mina.sync.invite();
    final code = mina.note.partner!.code!;
    server.delay = const Duration(milliseconds: 200);
    final joining = jun.sync.joinWithCode(code);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    jun.sync.cancel(); // 창을 닫았다
    await joining;
    server.delay = Duration.zero;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(jun.note.partner, isNull, reason: '취소한 화면에 세션이 붙지 않는다');
    await mina.sync.refresh();
    expect(
      mina.note.partner!.state,
      PartnerState.ended,
      reason: '서버에 생긴 참여도 되돌려, 한쪽만 연결된 상태가 남지 않는다',
    );
  });

  test('창을 닫는 것은 취소가 아니고, 취소는 그 요청이 만든 것만 되돌린다', () async {
    final server = FakeServer();
    final mina = Phone(server, '미나', 'a7'), jun = Phone(server, '준', 'b7');
    addTearDown(mina.sync.dispose);
    addTearDown(jun.sync.dispose);
    await mina.sync.invite();
    final code = mina.note.partner!.code!;
    // 1) 참여를 보내 놓고 창만 닫았다(취소를 누르지 않았다) — 참여는 그대로 확정된다.
    server.delay = const Duration(milliseconds: 150);
    await jun.sync.joinWithCode(code);
    server.delay = Duration.zero;
    expect(jun.note.partner!.state, PartnerState.active);

    // 2) 이미 확정된 뒤에 같은 참여를 다시 보냈다가 취소했다. 늦게 온 성공은 "이 요청이
    //    만든 참여" 가 아니므로(claimed:false) 확정된 세션을 끝내지 않는다.
    final second = Phone(server, '준', 'b7');
    addTearDown(second.sync.dispose);
    server.delay = const Duration(milliseconds: 150);
    final retry = second.sync.joinWithCode(code);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    second.sync.cancel();
    await retry;
    server.delay = Duration.zero;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await mina.sync.refresh();
    expect(
      mina.note.partner!.state,
      PartnerState.active,
      reason: '상대의 세션이 끝나지 않았다',
    );
    await jun.sync.refresh();
    expect(jun.note.partner!.state, PartnerState.active);

    // 3) 초대도 같다: 이미 열려 있던 초대를 다시 연 요청을 취소해도 그 초대는 남는다.
    final kim = Phone(server, '김', 'k7');
    addTearDown(kim.sync.dispose);
    await kim.sync.invite();
    final kept = kim.note.partner!.code;
    server.delay = const Duration(milliseconds: 150);
    final reopen = kim.sync.invite();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    kim.sync.cancel();
    await reopen;
    server.delay = Duration.zero;
    await kim.sync.refresh();
    expect(kim.note.partner!.state, PartnerState.waiting);
    expect(kim.note.partner!.code, kept);
  });

  test('오프라인이던 다른 기기의 업로드가 더 새 기록을 덮지 못하고, 내 문서는 그대로다', () async {
    final server = FakeServer();
    final phoneA = Phone(server, '미나', 'a8'), jun = Phone(server, '준', 'b8');
    addTearDown(phoneA.sync.dispose);
    addTearDown(jun.sync.dispose);
    await phoneA.sync.invite();
    await jun.sync.joinWithCode(phoneA.note.partner!.code!);
    await phoneA.sync.refresh();
    phoneA.log('벤치', LoggedSet(value: 80, reps: 10));
    await settle();

    // 같은 계정의 두 번째 기기가 같은 세션을 이어받아 더 새 기록을 올린다.
    final phoneB = Phone(server, '미나', 'a8');
    addTearDown(phoneB.sync.dispose);
    phoneB.note.partner = PartnerSession.tryFromJson(
      phoneA.note.partner!.toJson(),
    );
    await phoneB.sync.refresh();
    phoneB.log('벤치', LoggedSet(value: 80, reps: 10));
    phoneB.log('벤치', LoggedSet(value: 85, reps: 8));
    phoneB.log('벤치', LoggedSet(value: 90, reps: 5));
    await settle();

    // 첫 기기는 그동안 오프라인이었고, 옛 기록 위에서 하나를 고쳤다.
    phoneA.note.blocks.single.sets.single.done = false;
    phoneA.sync.recordChanged();
    await settle();
    expect(phoneA.sync.conflict, isNotNull, reason: '조용히 덮어쓰지 않고 알린다');
    expect(phoneA.sync.conflict!.blocks.single.sets, hasLength(3));
    expect(
      phoneA.note.blocks.single.sets,
      hasLength(1),
      reason: '이 기기의 문서는 바뀌지 않는다',
    );
    await jun.sync.refresh();
    expect(
      jun.note.partner!.partnerBlocks.single.sets,
      hasLength(3),
      reason: '더 새 기록이 살아 있다',
    );
    // 응답을 못 받은 재시도는 충돌이 아니다.
    final again =
        await GymLink(
          endpoint: 'https://x',
          token: '미나',
          client: server.clientFor('미나'),
        ).savePartnerRecord(
          phoneB.note.partner!.id,
          phoneB.note.partner!.pushed,
          phoneB.note.blocks,
          base: phoneB.note.partner!.pushed - 1,
        );
    expect(again.error, isNull);
    // 사람이 이 기기의 기록을 고르면 그때 덮는다.
    await phoneA.sync.shareThisDevice();
    expect(phoneA.sync.conflict, isNull);
    await jun.sync.refresh();
    expect(jun.note.partner!.partnerBlocks.single.sets, hasLength(1));
  });

  test('그물이 끊겨도 내 기록은 먼저 저장되고, 돌아오면 밀린 것이 한 번에 맞는다', () async {
    final server = FakeServer();
    final mina = Phone(server, '미나', 'a4'), jun = Phone(server, '준', 'b4');
    addTearDown(mina.sync.dispose);
    addTearDown(jun.sync.dispose);
    await mina.sync.invite();
    await jun.sync.joinWithCode(mina.note.partner!.code!);
    await mina.sync.refresh();

    server.online = false;
    final before = mina.saves;
    mina.log('스쿼트', LoggedSet(value: 100, reps: 5));
    mina.log('스쿼트', LoggedSet(value: 100, reps: 5));
    mina.note.blocks.single.sets.removeLast(); // 하나는 지웠다
    mina.sync.recordChanged();
    await settle();
    expect(mina.note.blocks.single.sets, hasLength(1), reason: '내 문서는 그대로다');
    expect(mina.saves, greaterThan(before), reason: '이 기기에 먼저 저장된다');
    expect(
      mina.note.partner!.state,
      PartnerState.active,
      reason: '끊긴 것이 끝난 것은 아니다',
    );
    await mina.sync.refresh();
    expect(mina.sync.reachable, isFalse);

    // 밀린 상태로 앱을 껐다 켠다 — 번호가 저장돼 있어 이어서 올린다.
    final reopened = Note.fromJson(
      jsonDecode(jsonEncode(mina.note.toJson())) as Map<String, dynamic>,
    );
    expect(reopened.partner!.revision, greaterThan(reopened.partner!.pushed));

    server.online = true;
    await mina.sync.refresh();
    await jun.sync.refresh();
    expect(mina.sync.reachable, isTrue);
    final theirs = jun.note.partner!.partnerBlocks.single;
    expect(theirs.sets, hasLength(1), reason: '지운 세트가 되살아나지도, 두 번 생기지도 않는다');
  });

  test('오래된 전체본이 최신을 덮어쓰지 못한다', () async {
    final server = FakeServer();
    final mina = Phone(server, '미나', 'a5'), jun = Phone(server, '준', 'b5');
    addTearDown(mina.sync.dispose);
    addTearDown(jun.sync.dispose);
    await mina.sync.invite();
    await jun.sync.joinWithCode(mina.note.partner!.code!);
    await mina.sync.refresh();
    mina.log('벤치', LoggedSet(value: 80, reps: 10));
    mina.log('벤치', LoggedSet(value: 82.5, reps: 8));
    await settle();
    final id = mina.note.partner!.id;
    // 늦게 도착한 옛 업로드(번호 1, 세트 하나).
    final late =
        await GymLink(
          endpoint: 'https://x',
          token: '미나',
          client: server.clientFor('미나'),
        ).savePartnerRecord(id, 1, [
          ExerciseBlock('벤치', [LoggedSet(value: 80, reps: 10)]),
        ], base: 0);
    expect(late.body?['error'], 'conflict');
    await jun.sync.refresh();
    expect(jun.note.partner!.partnerBlocks.single.sets, hasLength(2));
  });

  test('함께 운동을 끝내도 내 운동은 남고, 공유는 멈추고, 끝난 초대는 살아나지 않는다', () async {
    final server = FakeServer();
    final mina = Phone(server, '미나', 'a6'), jun = Phone(server, '준', 'b6');
    addTearDown(mina.sync.dispose);
    addTearDown(jun.sync.dispose);
    await mina.sync.invite();
    final token = mina.note.partner!.token!;
    await jun.sync.joinWithCode(mina.note.partner!.code!);
    await mina.sync.refresh();
    mina.log('데드리프트', LoggedSet(value: 140, reps: 3));
    jun.log('풀업', LoggedSet(reps: 8));
    await settle();
    await jun.sync.refresh();

    await jun.sync.end();
    expect(jun.note.partner!.state, PartnerState.ended);
    expect(jun.note.partner!.endedByMe, isTrue);
    expect(jun.note.blocks.single.name, '풀업', reason: '내 운동은 남는다');
    expect(
      jun.note.partner!.partnerBlocks,
      isEmpty,
      reason: '상대 기록은 더 들고 있지 않는다',
    );
    await mina.sync.refresh();
    expect(mina.note.partner!.state, PartnerState.ended);
    expect(mina.note.partner!.endedByMe, isFalse, reason: '상대가 끝냈다는 것을 안다');
    expect(mina.note.blocks.single.name, '데드리프트');

    // 끝난 뒤의 변경은 공유되지 않는다.
    final pushedBefore = server.records.length;
    mina.log('데드리프트', LoggedSet(value: 150, reps: 1));
    await settle();
    expect(server.records.length, pushedBefore);
    expect(mina.note.blocks.single.sets, hasLength(2));
    // 끝난 초대의 토큰으로는 다시 붙지 않는다.
    final sora = Phone(server, '소라', 'c6');
    addTearDown(sora.sync.dispose);
    expect(await sora.sync.joinWithToken(token), PartnerError.invalidCode);
  });

  test('넘치는 기록은 서버 상한에 맞춰 잘라 보내고, 그래도 거절되면 폴링마다 다시 보내지 않는다', () async {
    final server = FakeServer();
    final mina = Phone(server, '미나', 'a9'), jun = Phone(server, '준', 'b9');
    addTearDown(mina.sync.dispose);
    addTearDown(jun.sync.dispose);
    await mina.sync.invite();
    await jun.sync.joinWithCode(mina.note.partner!.code!);
    await mina.sync.refresh();

    // 한 운동에 세트 101개 — 100개까지 간다.
    mina.note.blocks.add(
      ExerciseBlock('플랭크', [for (var i = 0; i < 101; i++) LoggedSet(reps: 1)]),
    );
    mina.sync.recordChanged();
    await settle();
    await jun.sync.refresh();
    expect(jun.note.partner!.partnerBlocks.single.sets, hasLength(100));

    // 잘라도 64KB 를 넘는다(긴 메모) — 한 번 거절되면 같은 번호로 또 보내지 않는다.
    mina.note.blocks.add(
      ExerciseBlock('메모', [
        for (var i = 0; i < 100; i++) LoggedSet(reps: 1, notes: ['가' * 500]),
      ]),
    );
    mina.sync.recordChanged();
    await settle();
    final puts = server.recordPuts;
    await mina.sync.refresh();
    await mina.sync.refresh();
    expect(server.recordPuts, puts, reason: '같은 본문을 반복해 보내지 않는다');
    expect(mina.sync.conflict, isNull);
  });

  test('그물 없이 끝낸 같이 하기는 편집기 없이도 다음에 서버에 끝났다고 알린다', () async {
    final server = FakeServer();
    final mina = Phone(server, '미나', 'a10'), jun = Phone(server, '준', 'b10');
    addTearDown(mina.sync.dispose);
    addTearDown(jun.sync.dispose);
    await mina.sync.invite();
    await jun.sync.joinWithCode(mina.note.partner!.code!);
    await mina.sync.refresh();

    server.online = false;
    await jun.sync.end();
    expect(jun.note.partner!.endPending, isTrue);

    // 앱을 껐다 켰다 — 저장된 기록에서 다시 읽는다.
    final reopened = Note.fromJson(
      jsonDecode(jsonEncode(jun.note.toJson())) as Map<String, dynamic>,
    );
    final link = GymLink(
      endpoint: 'https://x',
      token: '준',
      client: server.clientFor('준'),
    );
    var sent = 0;
    await sendPendingEnds(link, [reopened], onSent: () => sent++);
    expect(reopened.partner!.endPending, isTrue, reason: '그물이 없으면 다음에');
    expect(sent, 0);

    server.online = true;
    // 서버가 넘어져 있으면(배포 중의 502 등) 끝난 것이 아니다. 다음에 다시 보낸다.
    server.failWith = 502;
    await sendPendingEnds(link, [reopened], onSent: () => sent++);
    expect(reopened.partner!.endPending, isTrue, reason: '5xx 는 다음에');
    expect(sent, 0);

    server.failWith = null;
    await sendPendingEnds(link, [reopened], onSent: () => sent++);
    expect(reopened.partner!.endPending, isFalse);
    expect(sent, 1);
    await mina.sync.refresh();
    expect(mina.note.partner!.state, PartnerState.ended);
  });

  test('다른 계정이 연 같이 하기의 밀린 종료는 지금 계정으로 보내지도 지우지도 않는다', () async {
    final server = FakeServer();
    final mina = Phone(server, '미나', 'a11'), jun = Phone(server, '준', 'b11');
    addTearDown(mina.sync.dispose);
    addTearDown(jun.sync.dispose);
    await mina.sync.invite();
    await jun.sync.joinWithCode(mina.note.partner!.code!);
    server.online = false;
    await jun.sync.end();
    server.online = true;
    jun.note.owner = '준';
    GymLink signedIn(String user) => GymLink(
      endpoint: 'https://x',
      token: user,
      userId: user,
      client: server.clientFor(user),
    );

    // 준이 로그아웃하고 같은 폰에 소라가 들어왔다. 서버는 404 를 줄 것이다.
    await sendPendingEnds(signedIn('소라'), [jun.note], onSent: () {});
    expect(jun.note.partner!.endPending, isTrue);

    await sendPendingEnds(signedIn('준'), [jun.note], onSent: () {});
    expect(jun.note.partner!.endPending, isFalse);
    await mina.sync.refresh();
    expect(mina.note.partner!.state, PartnerState.ended);
  });

  test('다른 계정이 연 같이 하기는 지금 계정으로 묻지 않고, 404 를 끝남으로 굳히지 않는다', () async {
    final server = FakeServer();
    final mina = Phone(server, '미나', 'a12'), jun = Phone(server, '준', 'b12');
    addTearDown(mina.sync.dispose);
    addTearDown(jun.sync.dispose);
    await mina.sync.invite();
    await jun.sync.joinWithCode(mina.note.partner!.code!);
    await mina.sync.refresh();
    mina.note.owner = '미나';
    expect(mina.note.partner!.state, PartnerState.active);

    // 미나가 로그아웃하고 같은 폰에 소라가 들어와 그 기록을 열었다(편집기는 열린
    // 세션이면 start() 한다). 서버는 소라에게 404 를 준다.
    final sora = PartnerSync(
      note: mina.note,
      link: () => GymLink(
        endpoint: 'https://x',
        token: '소라',
        userId: '소라',
        client: server.clientFor('소라'),
      ),
      onChanged: () {},
    );
    addTearDown(sora.dispose);
    sora.start();
    await sora.refresh();
    expect(mina.note.partner!.state, PartnerState.active);
    expect(server.sessions.values.single['ended'], isNull);
  });

  test(
    '열린 같이 하기가 없으면 start() 해도 2초 폴링이 걸리지 않는다 — 편집기는 앱을 올릴 때마다 부른다',
    () async {
      final server = FakeServer();
      final mina = Phone(server, '미나', 'a13'), jun = Phone(server, '준', 'b13');
      addTearDown(mina.sync.dispose);
      addTearDown(jun.sync.dispose);
      var polls = 0;
      void start(PartnerSync sync) => runZoned(
        sync.start,
        zoneSpecification: ZoneSpecification(
          createPeriodicTimer: (self, parent, zone, period, tick) {
            polls++;
            return parent.createPeriodicTimer(zone, period, tick);
          },
        ),
      );

      start(jun.sync);
      expect(polls, 0, reason: '혼자 쓰는 기록이다');
      await mina.sync.invite();
      start(mina.sync);
      expect(polls, 1, reason: '초대를 연 기록은 돈다');
    },
  );

  test('서버가 쉬었다 오라고 하면(503·429 Retry-After) 그때까지 폴링하지 않는다', () async {
    var states = 0;
    final note =
        Note(
            id: 'n-quiet',
            createdAt: DateTime(2026, 9, 21, 18),
            updatedAt: DateTime(2026, 9, 21, 18),
          )
          ..partner = PartnerSession(
            id: 'S1',
            host: true,
            state: PartnerState.active,
          );
    final sync = PartnerSync(
      note: note,
      link: () => GymLink(
        endpoint: 'https://x',
        token: 't',
        client: MockClient((request) async {
          // 스트림이 안 열리면 폴링이 제 속도로 돈다 — 그 속도를 늦출 수 있어야 한다.
          if (request.url.path.endsWith('/events')) {
            return http.Response('', 404);
          }
          if (request.method == 'GET') {
            states++;
            return http.Response(
              '{"error":"busy"}',
              503,
              headers: {'retry-after': '1'},
            );
          }
          return http.Response('{}', 200);
        }),
      ),
      onChanged: () {},
      interval: const Duration(milliseconds: 20),
    );
    addTearDown(sync.dispose);
    sync.start();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(states, 1, reason: '20ms 마다 다시 묻지 않는다');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    expect(states, greaterThan(1), reason: '쉬는 시간이 지나면 다시 묻는다');
  });

  testWidgets('느린 그물에서 폴링이 상태 요청을 겹쳐 쌓지 않고, 서버에 닿지 못하면 물러섰다가 닿으면 돌아온다', (
    tester,
  ) async {
    var gets = 0, open = 0, most = 0;
    var slow = true, down = false;
    final note =
        Note(
            id: 'n-backoff',
            createdAt: DateTime(2026, 9, 21, 18),
            updatedAt: DateTime(2026, 9, 21, 18),
          )
          ..partner = PartnerSession(
            id: 'S1',
            host: true,
            state: PartnerState.active,
          );
    final sync = PartnerSync(
      note: note,
      link: () => GymLink(
        endpoint: 'https://x',
        token: 't',
        client: MockClient((request) async {
          // 스트림이 안 열리면 폴링이 2초마다 제 속도로 돈다.
          if (request.url.path.endsWith('/events')) {
            return http.Response('', 404);
          }
          if (request.method != 'GET') return http.Response('{}', 200);
          gets++;
          if (down) return http.Response('', 502);
          most = open + 1 > most ? open + 1 : most;
          open++;
          if (slow) await Future<void>.delayed(const Duration(seconds: 8));
          open--;
          return http.Response(
            '{"id":"S1","state":"active","role":"host"}',
            200,
          );
        }),
      ),
      onChanged: () {},
    );
    sync.start();
    // 답이 8초씩 걸린다(요청은 10초에 포기한다). 옛 앱은 2초마다 새로 물어 너덧이 함께 떠 있었다.
    await tester.pump(const Duration(seconds: 30));
    expect(most, 1, reason: '묻는 중이면 새로 묻지 않고 그 답을 기다린다');

    slow = false;
    down = true;
    await tester.pump(const Duration(seconds: 12));
    final failing = gets;
    await tester.pump(const Duration(minutes: 2));
    // 물러서지 않으면 2초마다, 2분에 60번 묻는다.
    expect(gets - failing, lessThan(15), reason: '닿지 못하면 물러선다');

    down = false;
    await tester.pump(const Duration(seconds: 40));
    final back = gets;
    await tester.pump(const Duration(seconds: 20));
    expect(gets - back, greaterThanOrEqualTo(9), reason: '닿으면 다시 2초마다 묻는다');

    sync.dispose();
    await tester.pump();
  });

  test('배포로 모두의 스트림이 한꺼번에 끊겨도 같은 순간에 다시 붙지 않는다 — 1~3초 사이로 흩어진다', () async {
    final waits = <Duration>[];
    final phones = [
      for (var i = 0; i < 8; i++)
        PartnerSync(
          note:
              Note(
                  id: 'n-herd$i',
                  createdAt: DateTime(2026, 9, 21, 18),
                  updatedAt: DateTime(2026, 9, 21, 18),
                )
                ..partner = PartnerSession(
                  id: 'S$i',
                  host: true,
                  state: PartnerState.active,
                ),
          link: () => GymLink(
            endpoint: 'https://x',
            token: 't',
            client: MockClient((request) async {
              final state = '{"id":"S$i","state":"active","role":"host"}';
              // 상태 한 줄을 주고 끊긴다 — 배포로 서버가 내려갔다.
              return http.Response(
                request.url.path.endsWith('/events')
                    ? 'data: $state\n\n'
                    : state,
                200,
              );
            }),
          ),
          onChanged: () {},
        ),
    ];
    for (final phone in phones) {
      addTearDown(phone.dispose);
      // 다시 열기로 잡은 때를 본다. 요청 시간 제한(10·15·40초)은 이 범위 밖이다.
      runZoned(
        phone.start,
        zoneSpecification: ZoneSpecification(
          createTimer: (self, parent, zone, wait, run) {
            if (wait >= const Duration(seconds: 1) &&
                wait < const Duration(seconds: 3)) {
              waits.add(wait);
            }
            return parent.createTimer(zone, wait, run);
          },
        ),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(waits, hasLength(phones.length), reason: '잘 흐르던 스트림은 곧 다시 연다');
    expect(waits.toSet().length, greaterThan(1), reason: '같은 순간에 몰리지 않는다');
  });

  group('정체 때 덜 두드린다', () {
    Note activeNote(String id) =>
        Note(
            id: id,
            createdAt: DateTime(2026, 9, 21, 18),
            updatedAt: DateTime(2026, 9, 21, 18),
          )
          ..partner = PartnerSession(
            id: 'S1',
            host: true,
            state: PartnerState.active,
          );
    const state = '{"id":"S1","state":"active","role":"host"}';

    test('presence 는 한 번에 하나만 가고, 풀리면 마지막 자리 하나만 더 간다', () async {
      final places = <Object?>[];
      var open = 0, most = 0;
      final first = Completer<void>();
      final sync = PartnerSync(
        note: activeNote('n-presence'),
        link: () => GymLink(
          endpoint: 'https://x',
          token: 't',
          client: MockClient((request) async {
            if (!request.url.path.endsWith('/presence')) {
              return http.Response(state, 200);
            }
            places.add(jsonDecode(request.body)['block']);
            most = ++open > most ? open : most;
            if (places.length == 1) await first.future;
            open--;
            return http.Response('{}', 200);
          }),
        ),
        onChanged: () {},
        interval: const Duration(milliseconds: 20),
      );
      addTearDown(sync.dispose);
      for (var i = 0; i < 5; i++) {
        sync.presence(block: 'b$i');
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }
      expect(places, ['b0'], reason: '멈춘 서버에 치는 만큼 연결을 쌓지 않는다');
      first.complete();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(places, ['b0', 'b4']);
      expect(most, 1);
    });

    test('가던 presence 가 실패해도 stop() 의 커서 지우기는 간다', () async {
      final places = <Object?>[];
      final first = Completer<void>();
      final sync = PartnerSync(
        note: activeNote('n-presence-stop'),
        link: () => GymLink(
          endpoint: 'https://x',
          token: 't',
          client: MockClient((request) async {
            if (!request.url.path.endsWith('/presence')) {
              return http.Response(state, 200);
            }
            places.add(jsonDecode(request.body)['block']);
            if (places.length == 1) {
              await first.future;
              return http.Response('{"error":"oops"}', 500);
            }
            return http.Response('{}', 200);
          }),
        ),
        onChanged: () {},
        interval: const Duration(milliseconds: 20),
      );
      addTearDown(sync.dispose);
      sync.presence(block: 'b0');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      sync.stop();
      first.complete();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(places, ['b0', null], reason: '남은 커서가 20초 동안 남의 손을 막지 않는다');
    });

    test(
      'presence 가 Retry-After 를 받으면 그동안 presence 도 기록 PUT 도 가지 않는다',
      () async {
        final puts = <String>[];
        var busy = true;
        final note = activeNote('n-quiet-put')
          ..blocks.add(ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]));
        final sync = PartnerSync(
          note: note,
          link: () => GymLink(
            endpoint: 'https://x',
            token: 't',
            client: MockClient((request) async {
              if (request.method == 'GET') return http.Response(state, 200);
              puts.add(request.url.pathSegments.last);
              if (busy) {
                busy = false;
                return http.Response(
                  '{"error":"busy"}',
                  503,
                  headers: {'retry-after': '1'},
                );
              }
              return http.Response('{"revision":1}', 200);
            }),
          ),
          onChanged: () {},
          interval: const Duration(milliseconds: 20),
        );
        addTearDown(sync.dispose);
        sync.presence(block: 'b0');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(puts, ['presence']);
        sync.presence(block: 'b1');
        sync.recordChanged();
        await Future<void>.delayed(const Duration(milliseconds: 600));
        expect(puts, ['presence'], reason: '쉬는 1초 동안은 0번');
        await Future<void>.delayed(const Duration(milliseconds: 500));
        sync.presence(block: 'b2');
        await sync.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(puts, containsAll(['presence', 'record']));
        expect(puts.where((p) => p == 'presence'), hasLength(2));
      },
    );

    test('같이 고치기 PUT 도 Retry-After 동안은 가지 않는다', () async {
      final edits = <List<Object?>>[];
      var busy = true;
      final note = activeNote('n-quiet-doc')
        ..blocks.add(ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]));
      final sync = PartnerSync(
        note: note,
        link: () => GymLink(
          endpoint: 'https://x',
          token: 't',
          client: MockClient((request) async {
            if (request.method == 'GET') return http.Response(state, 200);
            final body = jsonDecode(request.body) as Map;
            if (!request.url.path.endsWith('/doc') ||
                body['action'] != 'edit') {
              return http.Response('{"version":1}', 200);
            }
            edits.add(body['ops'] as List);
            if (busy) {
              busy = false;
              return http.Response(
                '{"error":"busy"}',
                503,
                headers: {'retry-after': '1'},
              );
            }
            return http.Response('{"version":2}', 200);
          }),
        ),
        onChanged: () {},
        interval: const Duration(milliseconds: 20),
      );
      addTearDown(sync.dispose);
      await sync.refresh(); // the host plants the doc
      await Future<void>.delayed(const Duration(milliseconds: 50));
      note.blocks.single.sets.add(LoggedSet(value: 90, reps: 5));
      sync.pushDoc();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(edits, hasLength(1));
      final refused = edits.single;
      note.blocks.single.sets.add(LoggedSet(value: 100, reps: 5));
      sync.pushDoc();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(edits, hasLength(1), reason: '쉬는 1초 동안은 0번');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      note.blocks.single.sets.add(LoggedSet(value: 110, reps: 5));
      sync.pushDoc();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(edits.length, greaterThan(1));
      expect(edits[1], refused, reason: '못 간 것부터 차례대로 다시 간다');
    });

    test('스트림이 살아 있으면 상태 GET 은 서른 틱에 한 번이다', () async {
      var gets = 0;
      final events = StreamController<List<int>>();
      final sync = PartnerSync(
        note: activeNote('n-insurance'),
        link: () => GymLink(
          endpoint: 'https://x',
          token: 't',
          client: MockClient.streaming((request, _) async {
            if (request.url.path.endsWith('/events')) {
              events.add(utf8.encode('data: $state\n\n'));
              return http.StreamedResponse(events.stream, 200);
            }
            if (request.method == 'GET') gets++;
            return http.StreamedResponse(Stream.value(utf8.encode(state)), 200);
          }),
        ),
        onChanged: () {},
        interval: const Duration(milliseconds: 20),
      );
      addTearDown(events.close);
      addTearDown(sync.dispose);
      sync.start();
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      // ~65 ticks: the first refresh plus one every 30 ticks — not one per tick.
      expect(gets, inInclusiveRange(1, 4));
    });

    test(
      '일찍 죽는 스트림은 1·2·4초로 물러서고, 처음부터 안 흐르면 15~30초, Retry-After 면 그만큼 쉰다',
      () async {
        // Records each reopen wait and fires it at once, so the test does not sit through them.
        Future<List<Duration>> reopenWaits(
          http.Response Function() events,
          int count,
        ) async {
          final waits = <Duration>[];
          final sync = PartnerSync(
            note: activeNote('n-drop'),
            link: () => GymLink(
              endpoint: 'https://x',
              token: 't',
              client: MockClient(
                (request) async => request.url.path.endsWith('/events')
                    ? events()
                    : http.Response(state, 200),
              ),
            ),
            onChanged: () {},
          );
          runZoned(
            sync.start,
            zoneSpecification: ZoneSpecification(
              createTimer: (self, parent, zone, wait, run) {
                // Request time limits are fixed; reopen waits carry jitter.
                const limits = [
                  Duration(seconds: 10),
                  Duration(seconds: 15),
                  Duration(seconds: 40),
                ];
                if (wait < const Duration(seconds: 1) ||
                    limits.contains(wait)) {
                  return parent.createTimer(zone, wait, run);
                }
                waits.add(wait);
                return parent.createTimer(zone, Duration.zero, run);
              },
            ),
          );
          for (var i = 0; i < 100 && waits.length < count; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
          sync.dispose();
          return waits;
        }

        bool within(Duration d, int lo, int hi) =>
            d >= Duration(seconds: lo) && d <= Duration(seconds: hi);
        final short = await reopenWaits(
          () => http.Response('data: $state\n\n', 200),
          3,
        );
        expect(within(short[0], 1, 2), isTrue, reason: '${short[0]}');
        expect(within(short[1], 2, 4), isTrue, reason: '${short[1]}');
        expect(within(short[2], 4, 8), isTrue, reason: '${short[2]}');

        // Three young deaths, then one that lived 30 s+ (a deploy): it comes back in 1–2 s.
        var drops = 0;
        for (final want in [1, 2, 4]) {
          final Duration base;
          (base, drops) = PartnerSync.reopenBackoff(
            streamed: true,
            short: true,
            drops: drops,
          );
          expect(base, Duration(seconds: want));
        }
        expect(
          PartnerSync.reopenBackoff(streamed: true, short: false, drops: 6),
          (const Duration(seconds: 1), 0),
        );

        final never = await reopenWaits(() => http.Response('', 404), 1);
        expect(within(never.first, 15, 30), isTrue, reason: '${never.first}');

        final refused = await reopenWaits(
          () => http.Response('', 503, headers: {'retry-after': '45'}),
          1,
        );
        expect(
          within(refused.first, 44, 45),
          isTrue,
          reason: '${refused.first}',
        );
      },
    );
  });

  test('남이 고친 문서를 받아 다시 저장해도 내 기록이 그대로면 올리지 않는다', () async {
    final server = FakeServer();
    final mina = Phone(server, '미나', 'a14'), jun = Phone(server, '준', 'b14');
    addTearDown(mina.sync.dispose);
    addTearDown(jun.sync.dispose);
    await mina.sync.invite();
    await jun.sync.joinWithCode(mina.note.partner!.code!);
    jun.log('풀업', LoggedSet(reps: 8));
    await settle();
    final puts = server.recordPuts, revision = jun.note.partner!.revision;
    expect(puts, greaterThan(0));

    // 미나의 세트가 같이 고치는 문서로 들어와 준의 편집기가 다시 저장했다. 준의 기록은
    // 그대로다 — 옛 앱은 이때마다 번호를 올리고 같은 기록을 다시 올렸다.
    jun.note.blocks.single.sets.add(LoggedSet(reps: 5, author: '미나'));
    jun.sync.recordChanged();
    jun.sync.recordChanged();
    await settle();
    expect(server.recordPuts, puts);
    expect(jun.note.partner!.revision, revision);

    // 남이 더한 빈 운동 칸은 같이 짠 목록이라 내 기록에도 있다 — 바뀐 것이다.
    jun.note.blocks.add(ExerciseBlock('딥스'));
    jun.sync.recordChanged();
    await settle();
    expect(server.recordPuts, puts + 1);
    await mina.sync.refresh();
    expect(mina.note.partner!.partnerBlocks.map((b) => b.name), ['풀업', '딥스']);
  });

  test('편집기를 닫거나 앱을 내려 듣기를 그만두면 SSE 연결을 바로 끊는다 — 아무도 안 적는 쉬는 시간이어도', () async {
    // 진짜 소켓이다. 첫 상태 한 줄 다음에는 빈 줄(: keep)만 온다 — 상태가 안 바뀐다.
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final hungUp = Completer<void>();
    void gone([Object? _]) {
      if (!hungUp.isCompleted) hungUp.complete();
    }

    server.listen((socket) {
      socket
        ..listen((_) {}, onDone: gone, onError: gone)
        ..done.then(gone, onError: gone)
        ..write(
          'HTTP/1.1 200 OK\r\ncontent-type: text/event-stream\r\n'
          'connection: close\r\n\r\n'
          'data: {"id":"S1","state":"active"}\n\n',
        );
      final keep = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) => socket.write(': keep\n\n'),
      );
      unawaited(
        hungUp.future.then((_) {
          keep.cancel();
          socket.destroy();
        }),
      );
    });
    // 위젯 시험 바인딩은 HttpClient 를 400 만 주는 가짜로 바꿔 둔다. 이 시험은 진짜로 간다.
    await HttpOverrides.runWithHttpOverrides(() async {
      final link = GymLink(
        endpoint: 'http://127.0.0.1:${server.port}',
        token: 't',
      );
      final first = Completer<Map<String, Object?>>();
      final events = link.partnerEvents('S1').listen(first.complete);
      expect((await first.future)['id'], 'S1');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(hungUp.isCompleted, isFalse, reason: '듣는 동안은 열려 있다');

      unawaited(events.cancel());
      // 옛 앱은 다음 data 줄이 올 때까지 소켓을 쥐고 있었다(그동안 서버는 계속 읽는다).
      await hungUp.future.timeout(const Duration(seconds: 2));
    }, _RealHttp());
  });

  test('저장된 기록은 같이 하기가 없던 시절 것도 그대로 읽힌다', () {
    final old = Note.fromJson({
      'id': 'old',
      'createdAt': '2026-01-01T10:00:00.000',
      'updatedAt': '2026-01-01T11:00:00.000',
      'blocks': [
        {
          'name': '벤치프레스',
          'sets': [
            {'kg': 80, 'reps': 10, 'note': '가볍다'},
          ],
        },
      ],
    });
    expect(old.partner, isNull);
    expect(old.blocks.single.sets.single.value, 80);
    expect(old.blocks.single.sets.single.notes, ['가볍다']);
    expect(PartnerSession.tryFromJson({'nope': 1}), isNull);
  });
}

/// 진짜 [HttpClient] — 위젯 시험 바인딩이 깔아 둔 가짜(모든 요청에 400)를 이 영역에서만 걷는다.
class _RealHttp extends HttpOverrides {}
