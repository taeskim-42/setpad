// 같이 하기 — 두 기기가 같은 서버를 보고 연결하고, 기록을 주고받고, 끝낸다.
//
// 서버는 lib/partner-sessions.ts 와 같은 규칙의 가짜다. 진짜 서버의 규칙은
// gymdojo 의 partner-sessions.test.ts 가 실제 Postgres 로 지킨다.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/daily.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart';
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
  var n = 0;

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
    // record
    if (s['ended'] != null) return reply(410, {'error': 'ended'});
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
