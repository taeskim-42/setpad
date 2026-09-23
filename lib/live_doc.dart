/// 같이 고치는 한 문서 — 서버와 주고받는 모양과, 두 모양 사이의 차이.
///
/// **위치가 아니라 이름으로 고친다.** 운동과 세트마다 id 가 있어서 수정은
/// "벤치(B)에 세트(x) 를 이렇게" 라고 말한다. 두 사람이 같은 운동에 동시에
/// 세트를 넣어도 둘 다 남고, 누가 운동을 지운 뒤 도착한 세트는 갈 곳이 없어
/// 조용히 사라진다. 같은 세트를 동시에 고치면 나중 것이 이긴다 — 그래서 남이
/// 만지는 칸에는 그 사람 색이 붙는다.
///
/// 서버의 `lib/partner-sessions.ts` docAction 과 같은 규칙을 쓴다.
library;

import 'dart:convert';

import 'editor.dart';
import 'notes.dart';

typedef Json = Map<String, Object?>;

/// 서버가 받는 범위(lib/partner-sessions.ts validSet). 밖의 것은 빈 값으로
/// 보낸다 — 하나가 틀리면 서버가 그 묶음을 통째로 거절한다.
const _maxNumber = 100000, _maxNotes = 20, _maxNote = 500, _maxName = 200;
const _maxSets = 100;

String _cut(String s, int n) =>
    s.runes.length <= n ? s : String.fromCharCodes(s.runes.take(n));

Json _setJson(LoggedSet s) => {
  'id': s.id,
  'value': s.value != null && s.value!.abs() <= _maxNumber ? s.value : null,
  'unit': _cut(s.unit, 16),
  'reps': s.reps != null && s.reps! >= 0 && s.reps! <= _maxNumber
      ? s.reps
      : null,
  // 복사한다. 편집기의 목록을 그대로 실으면 메모를 고치는 순간 "받은 문서" 도
  // 같이 바뀌어 차이가 없어 보이고, 고친 메모가 영영 안 올라간다.
  'notes': [for (final n in s.notes.take(_maxNotes)) _cut(n, _maxNote)],
  'done': s.done,
  // 지난 세션에서 남이 적은 세트는 그 이름을 싣는다. 키는 싣지 않는다 — 서버가
  // 이름만 남겨 누구의 "내 세트" 도 되지 않게 한다.
  if (s.author != null) 'by': {'name': s.author},
};

/// 서버로 가는 모양. 내 세트의 작성자는 싣지 않는다 — 서버가 찍는다.
List<Json> docOf(List<ExerciseBlock> blocks) => [
  for (final b in blocks)
    {
      'id': b.id,
      'name': _cut(b.name, _maxName),
      if (b.setup != null) 'setup': b.setup!.toJson(),
      'sets': [for (final s in b.sets.take(_maxSets)) _setJson(s)],
    },
];

/// 서버 문서를 운동 칸으로. 내가 적은 세트는 작성자가 비고, 남이 적은 세트는
/// 그 사람 이름을 지닌다.
///
/// 지난 세션에서 옮겨 온 세트는 이름만 있고 키가 없다(누구의 것인지 서버는
/// 모른다). 그 세트가 내 기록([local])에 작성자 없이 있으면 내 것이다.
List<ExerciseBlock> blocksOfDoc(
  List<Json> doc,
  String? me, {
  List<ExerciseBlock> local = const [],
}) {
  final mine = {
    for (final b in local)
      for (final s in b.sets)
        if (s.author == null) s.id,
  };
  final blocks = blocksFromJson(doc);
  for (final (i, b) in doc.indexed) {
    for (final (j, s) in ((b['sets'] as List?) ?? const []).indexed) {
      final by = (s as Map)['by'];
      final carriedMine =
          by is Map && by['key'] == '' && mine.contains(s['id']);
      if (by is Map &&
          by['key'] != me &&
          by['name'] is String &&
          !carriedMine) {
        blocks[i].sets[j].author = by['name'] as String;
      }
    }
  }
  return blocks;
}

/// 견줄 때의 모양. 서버를 한 번 거치면 60.0 이 60 이 되고(JSON), jsonb 는 키
/// 순서를 바꾼다. 그대로 견주면 늘 달라 보여서 받은 뒤 첫 수정마다 모든 세트를
/// 다시 보내 — 그사이 남이 고친 것을 옛 값으로 덮었다.
Object? _norm(Object? v) => switch (v) {
  num n => n.toDouble(),
  Map m => {
    for (final k in (m.keys.map((k) => '$k').toList()..sort())) k: _norm(m[k]),
  },
  List l => [for (final x in l) _norm(x)],
  _ => v,
};
String _key(Object? v) => jsonEncode(_norm(v));
bool _sameSet(Object? a, Object? b) {
  if (a is! Map || b is! Map) return false;
  return const [
    'value',
    'unit',
    'reps',
    'notes',
    'done',
  ].every((k) => _key(a[k]) == _key(b[k]));
}

/// [from] 을 [to] 로 만드는 수정들. 서버가 받는 한 번의 묶음은 50개까지다.
List<List<Json>> diffDoc(List<Json> from, List<Json> to) {
  final ops = <Json>[];
  final before = {for (final b in from) b['id']: b};
  final after = {for (final b in to) b['id']};
  for (final b in from) {
    if (!after.contains(b['id'])) {
      ops.add({'kind': 'removeBlock', 'block': b['id']});
    }
  }
  for (final (i, b) in to.indexed) {
    final was = before[b['id']];
    if (was == null) {
      ops.add({'kind': 'block', 'at': i, 'block': b});
      continue;
    }
    if (was['name'] != b['name'] || _key(was['setup']) != _key(b['setup'])) {
      ops.add({
        'kind': 'block',
        'block': {
          'id': b['id'],
          'name': b['name'],
          'setup': ?b['setup'],
          'sets': const [],
        },
      });
    }
    final old = {for (final s in (was['sets'] as List)) (s as Map)['id']: s};
    final now = {for (final s in (b['sets'] as List)) (s as Map)['id']};
    for (final s in (was['sets'] as List)) {
      if (!now.contains((s as Map)['id'])) {
        ops.add({'kind': 'removeSet', 'block': b['id'], 'set': s['id']});
      }
    }
    for (final s in (b['sets'] as List)) {
      final was = old[(s as Map)['id']];
      if (!_sameSet(was, s)) {
        // 새 세트라고 말해야 서버가 더한다. 고치기가 늦게 닿았는데 그 세트가
        // 이미 지워졌으면 되살리지 않는다.
        ops.add({
          'kind': 'set',
          if (was == null) 'new': true,
          'block': b['id'],
          'set': s,
        });
      }
    }
  }
  final order = [for (final b in to) b['id']];
  if (_key([for (final b in applyDoc(from, ops)) b['id']]) != _key(order)) {
    ops.add({'kind': 'order', 'ids': order});
  }
  return [
    for (var i = 0; i < ops.length; i += 50)
      ops.sublist(i, i + 50 > ops.length ? ops.length : i + 50),
  ];
}

/// 서버와 같은 규칙으로 수정을 얹는다. 아직 서버에 닿지 않은 내 수정을 새로
/// 온 문서 위에 다시 얹을 때 쓴다 — 다시 얹어도 결과가 같다.
List<Json> applyDoc(List<Json> doc, List<Json> ops) {
  final blocks = [
    for (final b in doc)
      {
        ...b,
        'sets': [...(b['sets'] as List)],
      },
  ];
  int at(Object? id) => blocks.indexWhere((b) => b['id'] == id);
  for (final op in ops) {
    final i = at(op['block'] is Map ? null : op['block']);
    switch (op['kind']) {
      case 'block':
        final b = op['block'] as Json, j = at(b['id']);
        if (j >= 0) {
          blocks[j] = {...blocks[j], 'name': b['name'], 'setup': b['setup']}
            ..removeWhere((k, v) => k == 'setup' && v == null);
        } else if (op['at'] is int) {
          final pos = op['at'] is int
              ? (op['at'] as int).clamp(0, blocks.length)
              : blocks.length;
          blocks.insert(pos, {
            ...b,
            'sets': [...(b['sets'] as List)],
          });
        }
      case 'set' when i >= 0:
        final sets = blocks[i]['sets'] as List, s = op['set'] as Map;
        final j = sets.indexWhere((x) => (x as Map)['id'] == s['id']);
        if (j >= 0) {
          sets[j] = {...s, 'by': ?(sets[j] as Map)['by']};
        } else if (op['new'] == true) {
          sets.add(s);
        }
      case 'removeSet' when i >= 0:
        (blocks[i]['sets'] as List).removeWhere(
          (x) => (x as Map)['id'] == op['set'],
        );
      case 'removeBlock' when i >= 0:
        blocks.removeAt(i);
      case 'order':
        final named = [
          for (final id in (op['ids'] as List).toSet())
            if (at(id) >= 0) blocks[at(id)],
        ];
        final rest = blocks.where((b) => !named.contains(b)).toList();
        blocks
          ..clear()
          ..addAll([...named, ...rest]);
    }
  }
  return blocks;
}

/// 처음 참여할 때: 서버 문서에 이 기기에만 있는 것을 더한 것. 문서에 있는 것은
/// 문서가 이긴다 — 내 사본이 낡았을 수 있다(지난 세션의 같은 기록으로 다시
/// 짝을 지은 경우). 문서에 없는 세트와 운동만 뒤에 붙는다. 지운 것은 싣지
/// 않는다 — 남이 더한 것을 지우게 될 수 있다.
List<Json> joinDoc(List<Json> doc, List<Json> local) {
  final mine = {for (final b in local) b['id']: b};
  List<Object?> sets(Json b) => b['sets'] as List;
  Set<Object?> ids(Json b) => {for (final s in sets(b)) (s as Map)['id']};
  return [
    for (final b in doc)
      if (mine[b['id']] case final m?)
        {
          ...b,
          'sets': [
            ...sets(b),
            for (final x in sets(m))
              if (!ids(b).contains((x as Map)['id'])) x,
          ],
        }
      else
        b,
    for (final m in local)
      if (!doc.any((b) => b['id'] == m['id'])) m,
  ];
}
