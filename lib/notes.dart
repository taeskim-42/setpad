import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'editor.dart';

/// 한 번의 운동 기록. 메모 앱의 메모 한 장에 해당한다.
///
/// 제목을 따로 받지 않는다 — 첫 운동 이름이 곧 제목이다. 메모 앱이 첫 줄을
/// 제목으로 쓰는 것과 같고, 치는 사람이 제목을 고민할 일이 없다.
class Note {
  Note({required this.id, required this.createdAt, required this.updatedAt, List<ExerciseBlock>? blocks})
      : blocks = blocks ?? [];

  final String id;
  final DateTime createdAt;
  DateTime updatedAt;
  List<ExerciseBlock> blocks;

  /// 목록에 뜨는 제목. 빈 메모는 제목이 없고, 부르는 쪽에서 문구를 정한다.
  String? get title => blocks.isEmpty ? null : blocks.first.name;

  /// 제목 아래 한 줄. 스크린샷의 "1세트 80kg · 25회" 자리다.
  String summary({required String Function(int) setOrdinal, required String Function(int) reps}) {
    for (final b in blocks) {
      final done = b.sets.where((s) => s.done).toList();
      if (done.isEmpty) continue;
      final first = done.first;
      final parts = [
        setOrdinal(done.length),
        if (first.kg != null) '${_num(first.kg!)}kg',
        if (first.reps != null) reps(first.reps!),
      ];
      return parts.join(' · ');
    }
    return '';
  }

  /// 검색이 훑는 글. 운동 이름과 메모만 본다 — 숫자로 찾는 사람은 없다.
  String get searchText =>
      blocks.map((b) => [b.name, ...b.sets.map((s) => s.note ?? '')].join(' ')).join(' ').toLowerCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'blocks': [
          for (final b in blocks)
            {
              'name': b.name,
              'sets': [
                for (final s in b.sets)
                  {'kg': s.kg, 'reps': s.reps, 'note': s.note, 'done': s.done},
              ],
            },
        ],
      };

  static Note fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        blocks: [
          for (final b in (j['blocks'] as List? ?? const []))
            ExerciseBlock(
              b['name'] as String,
              [
                for (final s in (b['sets'] as List? ?? const []))
                  LoggedSet(
                    kg: (s['kg'] as num?)?.toDouble(),
                    reps: s['reps'] as int?,
                    note: s['note'] as String?,
                    done: s['done'] as bool? ?? true,
                  ),
              ],
            ),
        ],
      );
}

String _num(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();

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

  /// 최근에 고친 것이 위로. 메모 앱과 같은 순서다.
  List<Note> get notes => List.unmodifiable(_notes);

  Future<File> _file() async {
    final dir = _override ?? await getApplicationDocumentsDirectory();
    return File('${dir.path}/notes.json');
  }

  Future<void> load() async {
    try {
      final f = await _file();
      if (!f.existsSync()) return;
      final raw = jsonDecode(await f.readAsString()) as List;
      _notes
        ..clear()
        ..addAll(raw.map((e) => Note.fromJson(e as Map<String, dynamic>)));
      _sort();
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
  Future<void> flush() async {
    _debounce?.cancel();
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(_notes.map((n) => n.toJson()).toList()));
    } catch (e) {
      debugPrint('notes.json 을 쓰지 못했다: $e');
    }
  }

  void _sort() => _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Note create() {
    final now = DateTime.now();
    final note = Note(id: now.microsecondsSinceEpoch.toString(), createdAt: now, updatedAt: now);
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

  void delete(Note note) {
    _notes.remove(note);
    notifyListeners();
    _scheduleSave();
  }

  /// 아무것도 안 친 메모는 목록에 남길 이유가 없다. 메모 앱과 같다.
  void discardIfEmpty(Note note) {
    if (note.blocks.isEmpty) delete(note);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
