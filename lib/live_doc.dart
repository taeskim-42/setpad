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

Json _setJson(LoggedSet s) => {
  'id': s.id,
  'value': s.value,
  'unit': s.unit,
  'reps': s.reps,
  'notes': s.notes,
  'done': s.done,
};

/// 서버로 가는 모양. 작성자는 싣지 않는다 — 서버가 찍는다.
List<Json> docOf(List<ExerciseBlock> blocks) => [
  for (final b in blocks)
    {
      'id': b.id,
      'name': b.name,
      if (b.setup != null) 'setup': b.setup!.toJson(),
      'sets': [for (final s in b.sets) _setJson(s)],
    },
];

/// 서버 문서를 운동 칸으로. 내가 적은 세트는 작성자가 비고, 남이 적은 세트는
/// 그 사람 이름을 지닌다.
List<ExerciseBlock> blocksOfDoc(List<Json> doc, String? me) {
  final blocks = blocksFromJson(doc);
  for (final (i, b) in doc.indexed) {
    for (final (j, s) in ((b['sets'] as List?) ?? const []).indexed) {
      final by = (s as Map)['by'];
      if (by is Map && by['key'] != me && by['name'] is String) {
        blocks[i].sets[j].author = by['name'] as String;
      }
    }
  }
  return blocks;
}

String _key(Object? v) => jsonEncode(v);
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
      if (!_sameSet(old[(s as Map)['id']], s)) {
        ops.add({'kind': 'set', 'block': b['id'], 'set': s});
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
        } else {
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
        j >= 0 ? sets[j] = {...s, 'by': ?(sets[j] as Map)['by']} : sets.add(s);
      case 'removeSet' when i >= 0:
        (blocks[i]['sets'] as List).removeWhere(
          (x) => (x as Map)['id'] == op['set'],
        );
      case 'removeBlock' when i >= 0:
        blocks.removeAt(i);
      case 'order':
        final named = [
          for (final id in op['ids'] as List)
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
