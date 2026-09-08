import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'editor.dart';
import 'local_ai.dart';
import 'units.dart';

/// 한 번의 운동 기록. 메모 앱의 메모 한 장에 해당한다.
///
/// 제목을 따로 받지 않는다 — 첫 운동 이름이 곧 제목이다. 메모 앱이 첫 줄을
/// 제목으로 쓰는 것과 같고, 치는 사람이 제목을 고민할 일이 없다.
class Note {
  Note({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    List<ExerciseBlock>? blocks,
    this.calories,
    this.draft,
  }) : blocks = blocks ?? [];

  final String id;
  final DateTime createdAt;
  DateTime updatedAt;
  List<ExerciseBlock> blocks;

  /// 이 운동 동안 **애플워치가 잰** 활동 칼로리. 잰 것이 없으면 null 이다.
  /// 앱이 추정하지 않는다 — 0 과 "아무도 안 쟀다"는 다른 말이다.
  double? calories;
  EditorDraft? draft;

  /// 목록에 뜨는 제목 — 그날 한 운동 이름 전부.
  ///
  /// 첫 운동만 내던 것을 바꿨다. 메모 앱은 첫 줄이 곧 제목이라 그게 맞지만
  /// 운동 기록은 다르다. 목록에서 찾는 것은 대개 "저번에 벤치 언제 했지" 나
  /// "화요일에 뭐 했지" 인데, 둘 다 그날 한 것 전부를 봐야 답이 나온다.
  /// 첫 운동은 그날을 대표하지 않는다 — 그냥 먼저 친 것뿐이다.
  ///
  /// 길면 화면이 잘라 준다. 앞의 몇 개만 보여도 첫 하나보다 낫다.
  String? get title => blocks.isEmpty
      ? draft?.text.trim()
      : blocks.map((b) => b.name).toSet().join(' · ');

  /// 제목 아래 한 줄 — 그날 총계.
  ///
  /// 첫 운동의 첫 세트만 내던 것을 바꿨다. 그날 열두 세트를 했는데
  /// "1세트 · 80kg · 10회" 라고 뜨면 틀린 말은 아니지만 쓸모가 없다.
  String summary({
    required String Function(int) setOrdinal,
    required String Function(int) reps,
  }) {
    final total = blocks.fold(
      0,
      (n, b) => n + b.sets.where((s) => s.done).length,
    );
    return total == 0 ? '' : setOrdinal(total);
  }

  /// 검색이 훑는 글. 운동 이름과 메모만 본다 — 숫자로 찾는 사람은 없다.
  String get searchText => blocks
      .map((b) => [b.name, ...b.sets.expand((s) => s.notes)].join(' '))
      .join(' ')
      .toLowerCase();

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (calories != null) 'calories': calories,
    if (draft != null) 'draft': draft!.toJson(),
    'blocks': [
      for (final b in blocks)
        {
          'name': b.name,
          if (b.setup != null) 'setup': b.setup!.toJson(),
          'sets': [
            for (final s in b.sets)
              {
                'value': s.value,
                'unit': s.unit,
                'reps': s.reps,
                'notes': s.notes,
                'done': s.done,
              },
          ],
        },
    ],
  };

  static Note fromJson(Map<String, dynamic> j) => Note(
    id: j['id'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    calories: (j['calories'] as num?)?.toDouble(),
    draft: EditorDraft.fromJson(j['draft']),
    blocks: [
      for (final b in (j['blocks'] as List? ?? const []))
        ExerciseBlock(b['name'] as String, [
          for (final s in (b['sets'] as List? ?? const []))
            LoggedSet(
              // 'kg' 는 단위가 생기기 전에 저장된 기록이다. 그때는
              // 무게가 늘 kg 였으므로 그대로 읽어 준다.
              value: ((s['value'] ?? s['kg']) as num?)?.toDouble(),
              unit: s['unit'] as String? ?? defaultUnit,
              reps: s['reps'] as int?,
              // 'note'(단수)는 메모가 하나뿐이던 시절의 저장분이다.
              notes:
                  ((s['notes'] as List?)?.cast<String>()) ??
                  (s['note'] == null ? null : [s['note'] as String]),
              done: s['done'] as bool? ?? true,
            ),
        ], WorkoutSetup.tryFromJson(b['setup'])),
    ],
  );
}

/// 노트 전부를 들고 있고 디스크와 맞춰 두는 곳.
///
/// ponytail: 노트 전체를 JSON 한 파일에 쓴다. 한 사람이 하루 한 장씩 몇 년을
/// 써도 수천 장이라 통째로 읽고 쓰는 값이 싸다. 이게 느껴지면 그때 노트별
/// 파일이나 sqlite 로 간다.
class NotesStore extends ChangeNotifier {
  NotesStore({Directory? directory}) : _override = directory;

  final Directory? _override;
  final List<Note> _notes = [];
  Timer? _debounce;
  Future<void> _writes = Future.value();
  final List<String> _exerciseHistory = [];
  List<String> get exerciseHistory => List.unmodifiable(_exerciseHistory);
  String _weightUnit = defaultUnit;
  String get weightUnit => _weightUnit;

  /// 최근에 고친 것이 위로. 메모 앱과 같은 순서다.
  List<Note> get notes => List.unmodifiable(_notes);

  Future<File> _file() async {
    final dir = _override ?? await getApplicationDocumentsDirectory();
    return File('${dir.path}/notes.json');
  }

  Future<void> load() async {
    try {
      final f = await _file();
      try {
        final preferences = File('${f.parent.path}/preferences.json');
        if (preferences.existsSync()) {
          final data = jsonDecode(await preferences.readAsString()) as Map;
          _weightUnit = data['weightUnit'] == 'lb' ? 'lb' : defaultUnit;
          _exerciseHistory
            ..clear()
            ..addAll((data['exercises'] as List? ?? []).whereType<String>().toSet());
        }
      } catch (e) {
        debugPrint('Could not load preferences: $e');
      }
      if (!f.existsSync()) return;
      final raw = jsonDecode(await f.readAsString()) as List;
      _notes
        ..clear()
        ..addAll(raw.map((e) => Note.fromJson(e as Map<String, dynamic>)));
      _sort();
      for (final n in _notes) {
        for (final b in n.blocks.reversed) {
          if (!_exerciseHistory.contains(b.name)) _exerciseHistory.add(b.name);
        }
      }
      notifyListeners();
    } catch (e) {
      // 파일이 깨졌다고 앱이 안 뜨면 안 된다. 빈 목록으로 시작하고, 원본은
      // 덮어쓰기 전까지 그대로 있으므로 손으로 살릴 수 있다.
      debugPrint('notes.json 을 읽지 못했다: $e');
    }
  }

  /// 연달아 치는 동안 매번 쓰지 않도록 모아서 쓴다.
  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), flush);
  }

  /// 지금 당장 쓴다. 화면을 떠날 때와 앱이 내려갈 때 부른다.
  Future<void> flush() {
    _debounce?.cancel();
    final notes = jsonEncode(_notes.map((n) => n.toJson()).toList());
    final preferences = jsonEncode({
      'weightUnit': _weightUnit,
      'exercises': _exerciseHistory,
    });
    return _writes = _writes.then((_) async {
      try {
        final f = await _file();
        await _atomicWrite(f, notes);
        await _atomicWrite(
          File('${f.parent.path}/preferences.json'),
          preferences,
        );
      } catch (e) {
        debugPrint('Could not save notes: $e');
      }
    });
  }

  Future<void> _atomicWrite(File file, String text) async {
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(text, flush: true);
    await temporary.rename(file.path);
  }

  void setWeightUnit(String unit) {
    if (unit != 'kg' && unit != 'lb') return;
    _weightUnit = unit;
    notifyListeners();
    _scheduleSave();
  }

  void rememberExercise(String name) {
    if (name.trim().isEmpty) return;
    _exerciseHistory.remove(name);
    _exerciseHistory.insert(0, name);
    _scheduleSave();
  }

  void updateDraft(Note note, EditorDraft? draft) {
    if (mapEquals(note.draft?.toJson(), draft?.toJson())) return;
    note.draft = draft;
    note.updatedAt = DateTime.now();
    _sort();
    notifyListeners();
    _scheduleSave();
  }

  void _sort() => _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Note create() {
    final now = DateTime.now();
    final note = Note(
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
    );
    _notes.insert(0, note);
    notifyListeners();
    _scheduleSave();
    return note;
  }

  /// 편집 결과를 노트에 담는다. 목록의 순서와 요약이 여기서 갱신된다.
  void update(Note note, List<ExerciseBlock> blocks) {
    note.blocks = blocks;
    note.updatedAt = DateTime.now();
    _sort();
    notifyListeners();
    _scheduleSave();
  }

  /// 노트 안을 직접 고친 뒤 알리고 저장한다. 순서는 건드리지 않는다 —
  /// 칼로리가 뒤늦게 붙었다고 목록이 재배열되면 사람이 놓친다.
  void touch() {
    notifyListeners();
    _scheduleSave();
  }

  void delete(Note note) {
    _notes.remove(note);
    notifyListeners();
    _scheduleSave();
  }

  /// 아무것도 안 친 메모는 목록에 남길 이유가 없다. 메모 앱과 같다.
  void discardIfEmpty(Note note) {
    if (note.blocks.isEmpty && (note.draft?.text.trim().isEmpty ?? true)) {
      delete(note);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
