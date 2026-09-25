/// 마일스톤 — 그때까지의 최고 무게를 넘긴 세트. 화면은 그 칸에 ★ 를, 목록은 그
/// 기록에 '최고 무게' 표지를 단다.
library;

import 'editor.dart' show LoggedSet;
import 'notes.dart';
import 'record_query.dart' show exerciseKey;

/// 기록 id → 운동 칸 id → 최고 무게를 새로 넘긴 세트 번호들.
///
/// 만든 순서대로 한 번 훑는다. 운동마다 그때까지의 최고(kg 로 바꿔 견줌)를 들고
/// 가다 넘긴 내 세트(해낸 것)만 적는다. 처음 하는 운동은 넘길 기록이 없어 적지
/// 않는다 — 첫 세트마다 ★ 가 붙으면 뜻이 없다.
Map<String, Map<String, Set<int>>> weightRecords(Iterable<Note> notes) {
  final ordered = notes.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final best = <String, double>{};
  final out = <String, Map<String, Set<int>>>{};
  for (final n in ordered) {
    for (final b in n.blocks) {
      final key = exerciseKey(b.exercise);
      for (final (i, s) in b.sets.indexed) {
        final kg = _kg(s);
        if (kg == null) continue;
        final before = best[key];
        if (before != null && kg > before + 1e-9) {
          ((out[n.id] ??= {})[b.id] ??= {}).add(i);
        }
        if (before == null || kg > before) best[key] = kg;
      }
    }
  }
  return out;
}

double? _kg(LoggedSet s) {
  final v = s.value;
  if (!s.mine || v == null || v <= 0 || (s.reps ?? 0) < 1) return null;
  return switch (s.unit) {
    'kg' => v,
    'lb' => v * 0.45359237,
    _ => null,
  };
}
