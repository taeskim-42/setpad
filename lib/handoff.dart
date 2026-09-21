/// 대신 적은 기록 — 같이 운동하는 사람의 세트를 내 폰에서 적어 주고, 끝나면 건넨다.
///
/// **남의 기록을 고치는 길이 아니다.** 내 폰에 있는 동안은 내 문서에 딸린 별도의
/// 칸([ProxyRecord])이고 — 내 통계·하루 집계·같이 하기 공유 어디에도 섞이지 않는다 —
/// 받는 사람이 자기 앱에서 받기를 눌러야 그 사람 폰에 새 운동 문서로 들어간다.
///
/// 받는 사람의 폰은 사물함에 있을 수도 있다. 그래서 같이 하기 세션에 기대지 않고
/// 이레짜리 링크 하나로 건넨다. 세션 중이면 상대 화면에 "받기" 가 바로 뜬다.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'editor.dart';
import 'gym.dart';
import 'notes.dart';

class ProxyRecord {
  ProxyRecord({
    required this.name,
    List<ExerciseBlock>? blocks,
    this.revision = 0,
    this.sent = 0,
    this.token,
    this.forKey,
  }) : blocks = blocks ?? [];

  /// 내가 부르는 그 사람의 이름. 같이 하는 중이면 상대의 별명이다.
  String name;
  List<ExerciseBlock> blocks;

  /// 고칠 때마다 오르는 번호와, 서버가 받았다고 한 번호. 다르면 올릴 것이 밀려 있다.
  int revision, sent;

  /// 셋 이상이 같이 할 때 누구의 것인지 — 세션 안의 이름표. 그 사람 화면에만
  /// "받기" 가 뜬다. 둘이 할 때는 없어도 된다.
  String? forKey;

  /// 건넬 링크의 토큰. 한 번 만들어지면 같은 운동에서는 바뀌지 않는다.
  String? token;

  Map<String, Object?> toJson() => {
    'name': name,
    'blocks': blocksToJson(blocks),
    'revision': revision,
    'sent': sent,
    'token': ?token,
    'forKey': ?forKey,
  };

  static ProxyRecord? tryFromJson(Object? j) {
    if (j is! Map || j['name'] is! String) return null;
    return ProxyRecord(
      name: j['name'] as String,
      blocks: blocksFromJson(j['blocks']),
      revision: j['revision'] is int ? j['revision'] as int : 0,
      sent: j['sent'] is int ? j['sent'] as int : 0,
      token: j['token'] is String ? j['token'] as String : null,
      forKey: j['forKey'] is String ? j['forKey'] as String : null,
    );
  }
}

/// 건네받은 기록 한 장.
typedef Handoff = ({
  String from,
  DateTime workedAt,
  int revision,
  List<ExerciseBlock> blocks,
});

enum HandoffError { signInRequired, gone, network, server }

String? handoffTokenFromLink(Uri uri) {
  final parts = uri.pathSegments;
  final token = parts.length >= 2 && parts.first == 'r'
      ? parts[1]
      : uri.host == 'r' && parts.isNotEmpty
      ? parts.first
      : null;
  return token != null && RegExp(r'^[A-Za-z0-9_-]{22,64}$').hasMatch(token)
      ? token
      : null;
}

extension HandoffLink on GymLink {
  String handoffUrl(String token) => '$endpoint/r/$token';

  /// 대신 적은 것을 올린다. 같은 운동은 같은 링크다. 밀린 것이 없으면 묻지 않는다.
  Future<HandoffError?> sendProxy(Note note, {String? sessionId}) async {
    final proxy = note.proxy;
    if (proxy == null || proxy.blocks.isEmpty) return null;
    if (proxy.sent >= proxy.revision && proxy.token != null) return null;
    if (!supported) return HandoffError.signInRequired;
    final sending = proxy.revision;
    return withClient((web) async {
      try {
        final response = await web
            .put(
              Uri.parse('$endpoint/api/handoffs'),
              headers: {...headers, 'content-type': 'application/json'},
              body: jsonEncode({
                'localId': note.id,
                'revision': sending,
                'workedAt': note.createdAt.toUtc().toIso8601String(),
                'forName': proxy.name,
                'sessionId': ?sessionId,
                'forKey': ?proxy.forKey,
                'result': blocksToJson(proxy.blocks),
              }),
            )
            .timeout(const Duration(seconds: 10));
        final body = _json(response);
        if (response.statusCode == 200 && body?['token'] is String) {
          proxy
            ..token = body!['token'] as String
            ..sent = sending;
          return null;
        }
        return response.statusCode == 401
            ? HandoffError.signInRequired
            : HandoffError.server;
      } catch (_) {
        return HandoffError.network;
      }
    });
  }

  Future<({Handoff? handoff, HandoffError? error})> readHandoff(
    String token,
  ) async {
    if (!supported) return (handoff: null, error: HandoffError.signInRequired);
    return withClient((web) async {
      try {
        final response = await web
            .get(Uri.parse('$endpoint/api/handoffs/$token'), headers: headers)
            .timeout(const Duration(seconds: 10));
        final body = _json(response);
        final at = DateTime.tryParse('${body?['workedAt']}');
        final blocks = blocksFromJson(body?['result']);
        if (response.statusCode == 200 && at != null && blocks.isNotEmpty) {
          return (
            handoff: (
              from: body!['from'] as String? ?? '',
              workedAt: at.toLocal(),
              revision: (body['revision'] as num?)?.toInt() ?? 1,
              blocks: blocks,
            ),
            error: null,
          );
        }
        return (
          handoff: null,
          error: switch (response.statusCode) {
            401 => HandoffError.signInRequired,
            404 || 410 => HandoffError.gone,
            _ => HandoffError.server,
          },
        );
      } catch (_) {
        return (handoff: null, error: HandoffError.network);
      }
    });
  }
}

Map<String, Object?>? _json(http.Response response) {
  try {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return decoded is Map ? decoded.cast<String, Object?>() : null;
  } catch (_) {
    return null;
  }
}

/// 건네받은 기록을 이 기기의 문서로 놓는다. 같은 링크는 같은 문서다 — 다시 열어도
/// 둘이 되지 않고, 보낸 사람이 더 적었으면 그 내용으로 맞춘다. **내가 이미 고친
/// 문서는 덮지 않는다**: 그때는 새 문서로 따로 들어온다.
Note placeHandoff(NotesStore store, String token, Handoff h) {
  final had = store.notes.where((n) => n.handoffToken == token).toList();
  final current = had
      .where((n) => (n.handoffRevision ?? 0) >= h.revision)
      .firstOrNull;
  if (current != null) return current;
  final untouched = had.where((n) => !n.handoffTouched).firstOrNull;
  if (untouched != null) {
    store.update(untouched, h.blocks);
    return untouched..handoffRevision = h.revision;
  }
  return store.create(
      id: 'h${token.substring(0, 16)}-${h.revision}',
      blocks: h.blocks,
      at: h.workedAt,
    )
    ..handoffToken = token
    ..handoffRevision = h.revision;
}
