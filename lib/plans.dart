/// 공동 루틴 — 떨어져 있는 두 사람이 앞으로의 운동을 함께 정한다.
///
/// **계획은 운동이 아니다.** 여기에는 완료한 세트가 없다. "이 루틴으로 시작" 은
/// 합의한 버전의 사본으로 운동 문서를 하나 만들 뿐이고, 그 안의 세트는 전부
/// **안 한 것**으로 시작한다 — 실제로 해내고 표시한 세트만 기록으로 센다.
///
/// **합의는 버전에 대한 것이다.** 서버가 "둘 다 지금 버전을 수락했다" 고 답했을
/// 때만 합의 완료다. 이 기기에서 고친 초안은 서버가 받기 전까지 초안일 뿐이고,
/// 그물이 없을 때는 합의 완료라고 표시하지 않는다.
///
/// 공통(날짜·종목·순서·기본 세트 수)은 둘 다 고치고, 목표(무게·횟수·메모)는
/// 각자 자기 것만 고친다.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'editor.dart';
import 'gym.dart';
import 'notes.dart';
import 'parser.dart';
import 'partner.dart';
import 'units.dart';

final _random = Random();
String _newId(String prefix) =>
    '$prefix${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
    '${_random.nextInt(1 << 20).toRadixString(36)}';

class PlanItem {
  const PlanItem({required this.id, required this.name, required this.sets});
  final String id;

  /// 사람이 친 이름 그대로.
  final String name;

  /// 기본 세트 수. 0 이면 아직 안 정했다.
  final int sets;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'sets': sets};
  static List<PlanItem> listFrom(Object? j) => [
    for (final i in j is List ? j : const [])
      if (i is Map && i['id'] is String && i['name'] is String)
        PlanItem(
          id: i['id'] as String,
          name: i['name'] as String,
          sets: (i['sets'] as num?)?.toInt() ?? 0,
        ),
  ];
}

/// 한 종목에 대한 **내** 목표. 상대와 같을 필요가 없다.
class PlanTarget {
  const PlanTarget({
    this.value,
    this.unit = defaultUnit,
    this.reps,
    this.sets,
    this.note,
  });
  final double? value;
  final String unit;
  final int? reps;

  /// 내 세트 수. 비어 있으면 공통 계획의 세트 수를 따른다.
  final int? sets;
  final String? note;

  bool get isEmpty =>
      value == null && reps == null && sets == null && note == null;

  Map<String, Object?> toJson() => {
    'value': ?value,
    'unit': unit,
    'reps': ?reps,
    'sets': ?sets,
    'note': ?note,
  };

  static Map<String, PlanTarget> mapFrom(Object? j) => {
    if (j is Map)
      for (final e in j.entries)
        if (e.key is String && e.value is Map)
          e.key as String: PlanTarget(
            value: ((e.value as Map)['value'] as num?)?.toDouble(),
            unit: (e.value as Map)['unit'] as String? ?? defaultUnit,
            reps: ((e.value as Map)['reps'] as num?)?.toInt(),
            sets: ((e.value as Map)['sets'] as num?)?.toInt(),
            note: (e.value as Map)['note'] as String?,
          ),
  };

  /// "100kg · 5회 · 3세트" 같은 한 줄. 세트 표기는 밖에서 받는다.
  String label(
    String Function(int) formatReps,
    String Function(int) formatSets,
  ) => [
    if (value != null || reps != null)
      setLabel(value: value, unit: unit, reps: reps, formatReps: formatReps),
    if (sets != null) formatSets(sets!),
    ?note,
  ].join(' · ');
}

const _setWords = r'세트|sets?|セット|组|組|series?|hiệp|เซ็ต';
final _planLine = RegExp(
  '^(.+?)\\s*(?:[x×*]\\s*(\\d{1,2})|(\\d{1,2})\\s*(?:$_setWords))\\s*\$',
  caseSensitive: false,
);

/// 메모장처럼 친 글을 계획으로 읽는다. 첫 줄은 제목, 나머지는 한 줄에 한 종목:
/// "스쿼트 4세트", "레그컬 x3", "민수식 로우 2"(세트 수 없이 이름만).
///
/// **이름은 바꾸지 않는다.** 앞서 있던 종목과 이름이 같으면 그 id 를 잇는다 —
/// 순서를 바꿔도 각자의 목표가 제 종목에 붙어 있어야 한다.
({String title, List<PlanItem> items}) parsePlanText(
  String text, {
  List<PlanItem> previous = const [],
}) {
  final lines = text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.isEmpty) return (title: '', items: const []);
  final unused = [...previous];
  final items = <PlanItem>[];
  for (final line in lines.skip(1)) {
    final m = _planLine.firstMatch(line);
    final name = (m?[1] ?? line).trim();
    final sets = int.tryParse(m?[2] ?? m?[3] ?? '') ?? 0;
    final at = unused.indexWhere((p) => p.name == name);
    final id = at < 0 ? _newId('i') : unused.removeAt(at).id;
    items.add(PlanItem(id: id, name: name, sets: sets.clamp(0, 50)));
  }
  return (title: lines.first, items: items);
}

String planText(
  String title,
  List<PlanItem> items,
  String Function(int) formatSets,
) => [
  title,
  for (final i in items)
    i.sets > 0 ? '${i.name} ${formatSets(i.sets)}' : i.name,
].join('\n');

/// 무엇이 바뀌었는가 — 재확인할 때 보여 줄 만큼만.
({
  List<String> added,
  List<String> removed,
  List<String> changed,
  bool reordered,
  bool dateChanged,
  bool titleChanged,
})
planDiff(PlanContent from, PlanContent to) {
  final before = {for (final i in from.items) i.id: i},
      after = {for (final i in to.items) i.id: i};
  final kept = [
    for (final i in to.items)
      if (before.containsKey(i.id)) i.id,
  ];
  final keptBefore = [
    for (final i in from.items)
      if (after.containsKey(i.id)) i.id,
  ];
  return (
    added: [
      for (final i in to.items)
        if (!before.containsKey(i.id)) i.name,
    ],
    removed: [
      for (final i in from.items)
        if (!after.containsKey(i.id)) i.name,
    ],
    changed: [
      for (final i in to.items)
        if (before[i.id] != null && before[i.id]!.sets != i.sets) i.name,
    ],
    reordered: !listEquals(kept, keptBefore),
    dateChanged: from.plannedOn != to.plannedOn,
    titleChanged: from.title != to.title,
  );
}

class PlanContent {
  const PlanContent({this.title = '', this.plannedOn, this.items = const []});
  final String title;

  /// 날짜만. 'YYYY-MM-DD' — 시각도 시간대도 없다.
  final String? plannedOn;
  final List<PlanItem> items;

  Map<String, Object?> toJson() => {
    'title': title,
    'plannedOn': plannedOn,
    'items': [for (final i in items) i.toJson()],
  };
  static PlanContent from(Map j) => PlanContent(
    title: j['title'] as String? ?? '',
    plannedOn: j['plannedOn'] as String?,
    items: PlanItem.listFrom(j['items']),
  );
  bool sameAs(PlanContent o) => jsonEncode(toJson()) == jsonEncode(o.toJson());
}

enum PlanState { local, draft, pending, agreed, withdrawn }

/// 같이 짜는 사람 한 명. [key] 는 서버가 지어 준 이 계획 안의 이름표다 — 계정이 아니다.
class PlanMember {
  const PlanMember({
    required this.key,
    required this.name,
    this.accepted,
    this.targets = const {},
    this.startedVersion,
  });
  final String key, name;

  /// 이 사람이 동의한 버전. 현재 버전과 같으면 동의한 것이다.
  final int? accepted;
  final Map<String, PlanTarget> targets;
  final int? startedVersion;
}

class SharedPlan {
  SharedPlan({required this.localId, PlanContent? content})
    : content = content ?? const PlanContent();

  /// 이 기기가 지은 이름. 서버에 올리기 전에도 계획은 있다.
  final String localId;
  String? id;
  bool owner = true;
  PlanState state = PlanState.local;
  String? partner;
  int version = 0;

  /// 서버가 마지막으로 말해 준 현재 계획.
  PlanContent content;

  /// 이 기기에서 고치고 아직 서버가 받지 않은 초안. 충돌이 나도 지우지 않는다.
  PlanContent? draft;
  bool conflict = false;

  int? acceptedByMe, acceptedByPartner;
  int? agreedVersion;
  PlanContent? agreed;
  String? code;
  DateTime? inviteExpiresAt;

  /// 메시지로 보내는 초대 링크의 토큰. 코드와 수명이 다르다(하루).
  String? linkToken;
  DateTime? linkExpiresAt;

  Map<String, PlanTarget> myTargets = {};
  int targetsRevision = 0, targetsPushed = 0;
  Map<String, PlanTarget> partnerTargets = {};

  /// 같이 짜는 다른 사람들 전부. 둘이면 한 명이고 [partner]·[partnerTargets] 가 곧 그 사람이다.
  /// 저장하지 않는다 — 서버가 매번 다시 말해 준다.
  List<PlanMember> members = const [];

  /// 더 들어올 수 있는 자리.
  int room = 0;

  /// 이 계획으로 시작한 내 운동 문서와, 그때의 버전.
  String? startedNoteId;
  int? startedVersion;
  bool startedAgreed = false;
  bool startPending = false;
  int? partnerStartedVersion;

  PlanContent get shown => draft ?? content;
  bool get dirty => draft != null && !draft!.sameAs(content);

  /// 상대가 고친 새 버전을 내가 아직 수락하지 않았다.
  bool get needsMyAccept =>
      state == PlanState.pending && acceptedByMe != version;

  void apply(Map<String, Object?> b) {
    id = b['id'] as String?;
    owner = b['role'] == 'owner';
    state = PlanState.values.asNameMap()[b['state']] ?? state;
    partner = b['partner'] as String? ?? partner;
    if (b['version'] is num) {
      version = (b['version'] as num).toInt();
      content = PlanContent.from(b);
    }
    acceptedByMe = (b['acceptedByMe'] as num?)?.toInt();
    acceptedByPartner = (b['acceptedByPartner'] as num?)?.toInt();
    final a = b['agreed'];
    agreedVersion = a is Map ? (a['version'] as num?)?.toInt() : null;
    agreed = a is Map ? PlanContent.from(a) : null;
    final invite = b['invite'];
    code = invite is Map ? invite['code'] as String? : null;
    inviteExpiresAt = invite is Map
        ? DateTime.tryParse('${invite['expiresAt']}')
        : null;
    final link = b['link'];
    linkToken = link is Map ? link['token'] as String? : null;
    linkExpiresAt = link is Map
        ? DateTime.tryParse('${link['expiresAt']}')
        : null;
    final mine = b['myTargets'];
    if (mine is Map && targetsRevision <= targetsPushed) {
      // 밀린 내 변경이 없을 때만 서버 것을 받는다 — 치던 목표가 덮이면 안 된다.
      targetsRevision = targetsPushed =
          (mine['revision'] as num?)?.toInt() ?? 0;
      myTargets = PlanTarget.mapFrom(mine['targets']);
    }
    final theirs = b['partnerTargets'];
    partnerTargets = theirs is Map ? PlanTarget.mapFrom(theirs['targets']) : {};
    final start = b['myStart'];
    if (start is Map) {
      startedNoteId = start['localId'] as String?;
      startedVersion = (start['version'] as num?)?.toInt();
      startedAgreed = start['agreed'] == true;
      startPending = false;
    }
    final other = b['partnerStart'];
    partnerStartedVersion = other is Map
        ? (other['version'] as num?)?.toInt()
        : null;
    final people = b['members'];
    if (people is List) {
      members = [
        for (final m in people)
          if (m is Map && m['key'] is String && m['name'] is String)
            PlanMember(
              key: m['key'] as String,
              name: m['name'] as String,
              accepted: (m['accepted'] as num?)?.toInt(),
              targets: PlanTarget.mapFrom((m['targets'] as Map?)?['targets']),
              startedVersion: ((m['start'] as Map?)?['version'] as num?)
                  ?.toInt(),
            ),
      ];
      room = (b['room'] as num?)?.toInt() ?? 0;
      // "○○ 님과" 는 모두의 이름이다.
      if (members.length > 1) partner = members.map((m) => m.name).join(', ');
    }
    // 서버가 내 초안과 같은 것을 갖게 됐으면 초안은 끝났다.
    if (draft != null && draft!.sameAs(content)) {
      draft = null;
      conflict = false;
    }
  }

  Map<String, Object?> toJson() => {
    'localId': localId,
    'id': ?id,
    'owner': owner,
    'state': state.name,
    'partner': ?partner,
    'version': version,
    'content': content.toJson(),
    'draft': ?draft?.toJson(),
    if (conflict) 'conflict': true,
    'acceptedByMe': ?acceptedByMe,
    'acceptedByPartner': ?acceptedByPartner,
    'agreedVersion': ?agreedVersion,
    'agreed': ?agreed?.toJson(),
    'myTargets': {for (final e in myTargets.entries) e.key: e.value.toJson()},
    'targetsRevision': targetsRevision,
    'targetsPushed': targetsPushed,
    'partnerTargets': {
      for (final e in partnerTargets.entries) e.key: e.value.toJson(),
    },
    'startedNoteId': ?startedNoteId,
    'startedVersion': ?startedVersion,
    if (startedAgreed) 'startedAgreed': true,
    if (startPending) 'startPending': true,
    'partnerStartedVersion': ?partnerStartedVersion,
  };

  static SharedPlan? tryFromJson(Object? j) {
    if (j is! Map || j['localId'] is! String) return null;
    final p = SharedPlan(localId: j['localId'] as String)
      ..id = j['id'] as String?
      ..owner = j['owner'] != false
      ..state = PlanState.values.asNameMap()[j['state']] ?? PlanState.local
      ..partner = j['partner'] as String?
      ..version = (j['version'] as num?)?.toInt() ?? 0
      ..content = j['content'] is Map
          ? PlanContent.from(j['content'] as Map)
          : const PlanContent()
      ..draft = j['draft'] is Map ? PlanContent.from(j['draft'] as Map) : null
      ..conflict = j['conflict'] == true
      ..acceptedByMe = (j['acceptedByMe'] as num?)?.toInt()
      ..acceptedByPartner = (j['acceptedByPartner'] as num?)?.toInt()
      ..agreedVersion = (j['agreedVersion'] as num?)?.toInt()
      ..agreed = j['agreed'] is Map
          ? PlanContent.from(j['agreed'] as Map)
          : null
      ..myTargets = PlanTarget.mapFrom(j['myTargets'])
      ..targetsRevision = (j['targetsRevision'] as num?)?.toInt() ?? 0
      ..targetsPushed = (j['targetsPushed'] as num?)?.toInt() ?? 0
      ..partnerTargets = PlanTarget.mapFrom(j['partnerTargets'])
      ..startedNoteId = j['startedNoteId'] as String?
      ..startedVersion = (j['startedVersion'] as num?)?.toInt()
      ..startedAgreed = j['startedAgreed'] == true
      ..startPending = j['startPending'] == true
      ..partnerStartedVersion = (j['partnerStartedVersion'] as num?)?.toInt();
    return p;
  }
}

/// 이 계획의 사본으로 운동 칸을 만든다. **세트는 전부 안 한 것이다** — 목표는
/// 출발점일 뿐 수행 기록이 아니다.
List<ExerciseBlock> blocksFromPlan(
  PlanContent plan,
  Map<String, PlanTarget> targets,
) => [
  for (final item in plan.items)
    ExerciseBlock(item.name, [
      for (var s = 0; s < (targets[item.id]?.sets ?? item.sets); s++)
        LoggedSet(
          value: targets[item.id]?.value,
          unit: targets[item.id]?.unit ?? defaultUnit,
          reps: targets[item.id]?.reps,
          notes: s == 0 && targets[item.id]?.note != null
              ? [targets[item.id]!.note!]
              : null,
          done: false,
        ),
    ]),
];

/// 지난 운동(또는 지난 계획)에서 다음 계획의 초안을 뜬다. 완료 표시도 합의도
/// 따라오지 않는다 — 새 초안이다. 원본은 건드리지 않는다.
SharedPlan planFromBlocks(String title, List<ExerciseBlock> blocks) {
  final items = [
    for (final b in blocks)
      PlanItem(id: _newId('i'), name: b.name, sets: b.sets.length),
  ];
  final plan = SharedPlan(localId: _newId('p'))
    ..draft = PlanContent(title: title, items: items);
  for (final (i, b) in blocks.indexed) {
    final last = b.sets.where((s) => s.done).lastOrNull ?? b.sets.lastOrNull;
    if (last == null || (last.value == null && last.reps == null)) continue;
    plan.myTargets[items[i].id] = PlanTarget(
      value: last.value,
      unit: last.unit,
      reps: last.reps,
    );
  }
  if (plan.myTargets.isNotEmpty) plan.targetsRevision = 1;
  return plan;
}

SharedPlan copyPlan(SharedPlan from) {
  final source = from.agreed ?? from.content;
  final ids = {for (final i in source.items) i.id: _newId('i')};
  final plan = SharedPlan(localId: _newId('p'))
    ..draft = PlanContent(
      title: source.title,
      items: [
        for (final i in source.items)
          PlanItem(id: ids[i.id]!, name: i.name, sets: i.sets),
      ],
    );
  for (final e in from.myTargets.entries) {
    if (ids[e.key] != null) plan.myTargets[ids[e.key]!] = e.value;
  }
  if (plan.myTargets.isNotEmpty) plan.targetsRevision = 1;
  return plan;
}

extension PlanLink on GymLink {
  Future<PartnerReply> _plan(
    String method,
    String path, [
    Map<String, Object?>? body,
  ]) async {
    if (!supported) return (body: null, error: PartnerError.signInRequired);
    return withClient((web) async {
      try {
        final request = http.Request(
          method,
          Uri.parse('$endpoint/api/shared-plans$path'),
        )..headers.addAll({...headers, 'content-type': 'application/json'});
        if (body != null) request.body = jsonEncode(body);
        final response = await http.Response.fromStream(
          await web.send(request).timeout(const Duration(seconds: 10)),
        );
        Object? decoded;
        try {
          decoded = jsonDecode(utf8.decode(response.bodyBytes));
        } catch (_) {}
        final map = decoded is Map ? decoded.cast<String, Object?>() : null;
        if (response.statusCode == 200 && map != null) {
          return (body: map, error: null);
        }
        return (
          body: map,
          error: switch ((response.statusCode, map?['error'])) {
            (401, _) => PartnerError.signInRequired,
            (_, 'invalidCode') => PartnerError.invalidCode,
            (_, 'expired') => PartnerError.expired,
            (_, 'withdrawn') || (_, 'notFound') => PartnerError.ended,
            (_, 'ownInvite') => PartnerError.ownInvite,
            (429, _) => PartnerError.tooManyTries,
            (400, _) => PartnerError.invalidFormat,
            _ => PartnerError.server,
          },
        );
      } catch (_) {
        return (body: null, error: PartnerError.network);
      }
    });
  }
}

/// 이 기기의 공동 루틴들. 서버가 안 닿아도 열리고 고쳐진다.
class PlanStore extends ChangeNotifier {
  PlanStore({required this.link, Directory? directory}) : _override = directory;
  final GymLink Function() link;
  final Directory? _override;
  final List<SharedPlan> plans = [];
  PartnerError? error;
  bool reachable = true;

  Future<File> _file() async => File(
    '${(_override ?? await getApplicationDocumentsDirectory()).path}/plans.json',
  );

  Future<void> load() async {
    try {
      final f = await _file();
      if (!f.existsSync()) return;
      plans
        ..clear()
        ..addAll([
          for (final p in jsonDecode(await f.readAsString()) as List)
            ?SharedPlan.tryFromJson(p),
        ]);
      notifyListeners();
    } catch (e) {
      debugPrint('Could not load plans: $e');
    }
  }

  Future<void> _writes = Future.value();
  Future<void> save() {
    final text = jsonEncode([for (final p in plans) p.toJson()]);
    notifyListeners();
    return _writes = _writes.then((_) async {
      try {
        final f = await _file();
        final tmp = File('${f.path}.tmp');
        await tmp.writeAsString(text, flush: true);
        await tmp.rename(f.path);
      } catch (e) {
        debugPrint('Could not save plans: $e');
      }
    });
  }

  PartnerError? _done(SharedPlan plan, PartnerReply reply) {
    reachable = reply.error != PartnerError.network;
    // 충돌이어도 서버의 최신 계획은 같이 온다 — 내 초안 옆에 보여 줄 수 있게.
    if (reply.body?['id'] is String) plan.apply(reply.body!);
    if (reply.body?['error'] == 'conflict') plan.conflict = true;
    error = reply.body?['error'] == 'conflict' ? null : reply.error;
    save();
    return error;
  }

  void add(SharedPlan plan) {
    plans.insert(0, plan);
    save();
  }

  /// 운동 기록에서 뜬 초안을 들인다. 같은 내용의 **아직 안 올린** 초안이 있으면
  /// 그것을 돌려준다 — 제안 버튼을 두 번 눌렀다고 목록에 같은 것이 둘 생기지 않는다.
  SharedPlan adopt(SharedPlan draft) {
    String text(SharedPlan p) =>
        planText(p.shown.title, p.shown.items, (n) => 'x$n');
    final same = plans
        .where((p) => p.id == null && text(p) == text(draft))
        .firstOrNull;
    if (same != null) return same;
    add(draft);
    return draft;
  }

  /// 서버의 내 계획들로 맞춘다. 이 기기에만 있는 초안은 그대로 둔다.
  Future<void> refreshAll() async {
    final reply = await link()._plan('GET', '');
    reachable = reply.error != PartnerError.network;
    if (reply.error != null) return notifyListeners();
    final seen = <String>{};
    for (final raw in (reply.body!['plans'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final body = raw.cast<String, Object?>();
      seen.add(body['id'] as String);
      final plan =
          plans.where((p) => p.id == body['id']).firstOrNull ??
          (SharedPlan(localId: _newId('p'))..let(plans.add));
      plan.apply(body);
    }
    // 서버에서 더는 안 보이는 것(내가 철회했다)은 이 기기에서도 닫는다.
    for (final p in plans) {
      if (p.id != null &&
          !seen.contains(p.id) &&
          p.state != PlanState.withdrawn) {
        p.state = PlanState.withdrawn;
      }
    }
    await push();
    save();
  }

  /// 밀린 것을 보낸다: 아직 서버에 없는 초안, 고친 공통 계획, 내 목표, 시작 기록.
  Future<void> push() async {
    for (final plan in [...plans]) {
      if (plan.state == PlanState.withdrawn) continue;
      if (plan.id == null) {
        final d = plan.shown;
        final reply = await link()._plan('POST', '', {
          'localId': plan.localId,
          ...d.toJson(),
        });
        if (_done(plan, reply) != null) continue;
      } else if (plan.dirty && !plan.conflict) {
        await savePlan(plan);
      }
      await pushTargets(plan);
      if (plan.startPending && plan.id != null && plan.startedNoteId != null) {
        _done(
          plan,
          await link()._plan('POST', '/${plan.id}/start', {
            'localId': plan.startedNoteId,
          }),
        );
      }
    }
  }

  Future<PartnerError?> refresh(SharedPlan plan) async {
    if (plan.id == null) {
      await push();
      return error;
    }
    final result = _done(plan, await link()._plan('GET', '/${plan.id}'));
    if (result == null) await push();
    return result;
  }

  /// 공통 계획을 고친다. 먼저 이 기기에 초안으로 남고, 그다음 서버로 간다.
  Future<PartnerError?> edit(SharedPlan plan, PlanContent next) async {
    plan.draft = next;
    // 디스크 쓰기를 기다리지 않는다 — 쓰는 순서는 save 가 지키고, 화면은 바로 간다.
    unawaited(save());
    if (plan.id == null) {
      await push();
      return error;
    }
    return savePlan(plan);
  }

  Future<PartnerError?> savePlan(
    SharedPlan plan, {
    bool overLatest = false,
  }) async {
    final draft = plan.draft;
    if (draft == null || plan.id == null) return null;
    if (overLatest) plan.conflict = false; // 최신을 보고도 내 안을 다시 제안한다
    return _done(
      plan,
      await link()._plan('PUT', '/${plan.id}', {
        'base': plan.version,
        ...draft.toJson(),
      }),
    );
  }

  /// 충돌에서 내 초안을 버리고 최신 계획을 받아들인다.
  void takeLatest(SharedPlan plan) {
    plan
      ..draft = null
      ..conflict = false;
    save();
  }

  Future<PartnerError?> accept(SharedPlan plan) async => plan.id == null
      ? PartnerError.network
      : _done(
          plan,
          await link()._plan('POST', '/${plan.id}/accept', {
            'version': plan.version,
          }),
        );

  /// 옆에서 불러 줄 코드(10분) 또는 메시지로 보낼 링크(하루). 서로의 것을 죽이지 않는다.
  Future<PartnerError?> invite(SharedPlan plan, {bool asLink = false}) async {
    if (plan.id == null) await push();
    if (plan.id == null) return error ?? PartnerError.network;
    return _done(
      plan,
      await link()._plan('POST', '/${plan.id}/invite', {
        if (asLink) 'kind': 'link',
      }),
    );
  }

  /// 보낼 주소. 앱이 있으면 앱이 받고, 없으면 그 주소의 안내 화면이 뜬다.
  String? linkFor(SharedPlan plan) {
    final token = plan.linkToken, until = plan.linkExpiresAt;
    if (token == null || until == null || until.isBefore(DateTime.now())) {
      return null;
    }
    return '${link().endpoint}/plan/$token';
  }

  /// 코드로, 또는 링크·근접 통신으로 받은 토큰으로 참여한다. 같은 초대다.
  Future<({SharedPlan? plan, PartnerError? error})> join(
    String typed, {
    bool isToken = false,
  }) async {
    final code = isToken ? null : normalizePartnerCode(typed);
    if (!isToken && code == null) {
      return (plan: null, error: PartnerError.invalidFormat);
    }
    final reply = await link()._plan('POST', '/join', {
      if (isToken) 'token': typed else 'code': code,
    });
    reachable = reply.error != PartnerError.network;
    if (reply.error != null) return (plan: null, error: reply.error);
    final plan =
        plans.where((p) => p.id == reply.body!['id']).firstOrNull ??
        (SharedPlan(localId: _newId('p'))..let((p) => plans.insert(0, p)));
    plan.apply(reply.body!);
    save();
    return (plan: plan, error: null);
  }

  void setTarget(SharedPlan plan, String itemId, PlanTarget? target) {
    target == null || target.isEmpty
        ? plan.myTargets.remove(itemId)
        : plan.myTargets[itemId] = target;
    plan.targetsRevision++;
    save();
    unawaited(pushTargets(plan));
  }

  Future<void> pushTargets(SharedPlan plan) async {
    if (plan.id == null || plan.targetsRevision <= plan.targetsPushed) return;
    final sending = plan.targetsRevision;
    final reply = await link()._plan('PUT', '/${plan.id}/targets', {
      'revision': sending,
      'base': plan.targetsPushed,
      'targets': {
        for (final e in plan.myTargets.entries) e.key: e.value.toJson(),
      },
    });
    reachable = reply.error != PartnerError.network;
    if (reply.error == null) {
      plan.targetsPushed = sending;
      plan.apply(reply.body!);
    } else if (reply.body?['error'] == 'conflict') {
      // 다른 기기가 내 목표를 고쳤다. 이 기기의 값이 지금 친 것이므로 그 위에 올린다.
      plan.targetsPushed =
          (reply.body!['revision'] as num?)?.toInt() ?? plan.targetsPushed;
      plan.targetsRevision = plan.targetsPushed + 1;
      return pushTargets(plan);
    }
    save();
  }

  /// 이 계획으로 시작한다. 돌려주는 것은 운동 문서의 id 와 그 사본이다.
  ///
  /// 서버가 첫 시작을 기억하므로 다시 눌러도, 다른 기기에서 눌러도 같은 운동이다.
  /// 그물이 없으면 이 기기가 가진 계획으로 시작하고 나중에 알린다.
  Future<({String noteId, PlanContent content, bool agreed})> start(
    SharedPlan plan,
  ) async {
    if (plan.startedNoteId == null) {
      final candidate = DateTime.now().microsecondsSinceEpoch.toString();
      if (plan.id != null) {
        _done(
          plan,
          await link()._plan('POST', '/${plan.id}/start', {
            'localId': candidate,
          }),
        );
      }
      if (plan.startedNoteId == null) {
        plan
          ..startedNoteId = candidate
          ..startedVersion = plan.agreedVersion ?? plan.version
          // 서버가 예전에 확인해 준 합의만 합의다.
          ..startedAgreed = plan.agreedVersion != null
          ..startPending = true;
        save();
      }
    }
    return (
      noteId: plan.startedNoteId!,
      // 합의본이 있으면 그것, 없으면 지금 내가 보고 있는 것(서버에 못 올린 초안
      // 포함) — 본인용 사본은 내 눈앞의 계획이다.
      content: plan.agreed ?? plan.shown,
      agreed: plan.startedAgreed,
    );
  }

  Future<PartnerError?> withdraw(SharedPlan plan) async {
    if (plan.id == null) {
      plans.remove(plan);
      save();
      return null;
    }
    final reply = await link()._plan('POST', '/${plan.id}/withdraw');
    reachable = reply.error != PartnerError.network;
    if (reply.error == null) plans.remove(plan);
    error = reply.error;
    save();
    return reply.error;
  }
}

/// 이 계획으로 실제 운동을 시작한다(이미 시작했으면 그 운동을 연다).
///
/// 만들어지는 것은 평소의 운동 문서 하나다. 세트는 전부 **안 한 것**으로 들어가고,
/// 어느 계획의 몇 번 버전에서 왔는지가 문서에 남는다. 다시 눌러도, 응답을 못 받고
/// 다시 눌러도 같은 문서다.
Future<Note> startWorkout(
  PlanStore plans,
  NotesStore notes,
  SharedPlan plan,
) async {
  final started = await plans.start(plan);
  final existing = notes.notes.where((n) => n.id == started.noteId).firstOrNull;
  if (existing != null) return existing;
  final note =
      notes.create(
          id: started.noteId,
          blocks: blocksFromPlan(started.content, plan.myTargets),
        )
        ..planId = plan.id ?? plan.localId
        ..planVersion = plan.startedVersion
        ..planAgreed = started.agreed;
  notes.touch();
  return note;
}

/// 초대 링크에서 토큰을 꺼낸다. `https://…/plan/<토큰>` 과, 웹 화면의 "앱에서 열기"
/// 가 부르는 `setpad://plan/<토큰>`(이때는 'plan' 이 host 로 잡힌다).
String? planTokenFromLink(Uri uri) {
  final parts = uri.pathSegments;
  final token = parts.length >= 2 && parts.first == 'plan'
      ? parts[1]
      : uri.host == 'plan' && parts.isNotEmpty
      ? parts.first
      : null;
  return token != null && RegExp(r'^[A-Za-z0-9_-]{22,64}$').hasMatch(token)
      ? token
      : null;
}

extension<T> on T {
  T let(void Function(T) f) {
    f(this);
    return this;
  }
}
