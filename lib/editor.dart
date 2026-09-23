import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'keypad.dart';
import 'collapsing_drag.dart';
import 'record_ai.dart';
import 'workout_setup_sheet.dart';
import 'l10n/generated/app_localizations.dart';
import 'exercises.dart';
import 'health.dart';
import 'rest_alarm.dart';
import 'rest_recovery.dart';
import 'set_grid.dart';
import 'palette.dart';
import 'parser.dart';
import 'partner.dart';
import 'shared_timer.dart';
import 'units.dart';
import 'workout_timing.dart';

class EditorDraft {
  const EditorDraft({
    required this.text,
    this.block = -1,
    this.memo = false,
    this.editingSet,
    this.editingNote,
    this.setText,
    this.title = false,
    this.resume,
    this.meal = false,
    this.mealIndex,
    this.blockId,
  });
  final String text;
  final int block;

  /// 그 운동의 id. 같이 고치는 중에는 앞의 운동이 지워지거나 순서가 바뀌어
  /// 번호가 다른 운동을 가리킬 수 있다 — 있으면 이것으로 찾는다.
  final String? blockId;
  final bool memo;
  final int? editingSet, editingNote;
  final String? setText;
  final bool title;
  final EditorDraft? resume;

  /// 운동 이름이 아니라 식단을 적던 중이었다. [mealIndex] 는 고치던 끼니.
  final bool meal;
  final int? mealIndex;
  Map<String, Object?> toJson() => {
    'text': text,
    'block': block,
    'memo': memo,
    'editingSet': editingSet,
    'editingNote': editingNote,
    'setText': setText,
    'title': title,
    'resume': resume?.toJson(),
    if (meal) 'meal': true,
    'mealIndex': ?mealIndex,
    'blockId': ?blockId,
  };
  static EditorDraft? fromJson(Object? value) {
    if (value is! Map || value['text'] is! String) return null;
    return EditorDraft(
      text: value['text'] as String,
      title: value['title'] == true,
      resume: fromJson(value['resume']),
      block: value['block'] is int ? value['block'] as int : -1,
      memo: value['memo'] == true,
      editingSet: value['editingSet'] is int
          ? value['editingSet'] as int
          : null,
      editingNote: value['editingNote'] is int
          ? value['editingNote'] as int
          : null,
      setText: value['setText'] is String ? value['setText'] as String : null,
      meal: value['meal'] == true,
      mealIndex: value['mealIndex'] is int ? value['mealIndex'] as int : null,
      blockId: value['blockId'] is String ? value['blockId'] as String : null,
    );
  }
}

/// 같이 고치는 문서에서 운동·세트를 가리키는 이름. 기기마다 따로 만들어도
/// 겹치지 않을 만큼 길다.
String newId() {
  const abc = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return String.fromCharCodes([
    for (var i = 0; i < 12; i++) abc.codeUnitAt(_ids.nextInt(abc.length)),
  ]);
}

final _ids = Random.secure();

class LoggedSet {
  LoggedSet({
    String? id,
    this.value,
    this.unit = defaultUnit,
    this.reps,
    List<String>? notes,
    this.done = true,
    this.author,
  }) : id = id ?? newId(),
       notes = notes ?? [];

  final String id;

  /// 같이 고친 문서에서 **남이** 적은 세트면 그 사람 이름. 내 세트는 null 이다.
  /// 내 통계·건강 앱·공유에는 내 세트만 들어간다([mine]).
  String? author;
  bool get mine => done && author == null;

  /// 무게든 거리든 시간이든, 친 숫자 그대로.
  final double? value;

  /// 그 숫자의 단위. 친 것을 그대로 남긴다 — 예전에는 lb 를 kg 로 바꿔
  /// 저장해서 파운드로 하는 사람의 숫자가 사라졌다.
  final String unit;
  final int? reps;

  /// 이 세트에 남긴 메모들. 하나만 들면 나중에 적은 것이 앞의 것을 덮어쓴다 —
  /// 세트를 끝내고 떠오르는 생각은 대개 하나가 아니다.
  final List<String> notes;

  /// 실제로 해낸 세트인가. 넣는 순간은 해낸 것이라 켜진 채로 시작하고,
  /// 계획만 적어두거나 잘못 넣었을 때 손으로 끈다.
  bool done;
}

class ExerciseBlock {
  ExerciseBlock(this.name, [List<LoggedSet>? sets, this.setup, String? id])
    : sets = sets ?? [],
      id = id ?? newId();
  final String id;
  String name;
  final List<LoggedSet> sets;
  WorkoutSetup? setup;

  /// 이 칸이 가리키는 운동. 화면에 적히는 이름과 다를 수 있다.
  ///
  /// "스쿼트 100kg 100개 채우기" 라고 쳤으면 제목은 그 문장 그대로 남는다 —
  /// 이 앱은 사람이 쓴 글이 곧 기록이다. 다만 통계와 검색은 그 문장이 아니라
  /// **스쿼트**를 봐야 하므로, 한 줄 설정이 알아낸 이름을 여기서 낸다.
  String get exercise => setup?.name ?? name;

  /// 이 칸에서 익힐 운동 이름. 설정을 적은 제목('벤치 80kg 5x5')은 이름이 아니다 —
  /// 설정의 이름, 없으면 수 낱말을 뺀 이름. 이름이 안 남으면 null.
  String? get learnedName => setup?.name ?? learnableName(name);

  /// 내가 적은 마지막 세트. 같이 고치는 문서에서 옆 사람의 단위·무게를 잇지
  /// 않으려고 쓴다. 내 세트가 없으면 그냥 마지막 세트.
  LoggedSet? get myLast =>
      sets.where((s) => s.author == null).lastOrNull ?? sets.lastOrNull;
  int get completedReps =>
      sets.where((s) => s.mine).fold(0, (n, s) => n + (s.reps ?? 0));
}

WorkoutSetup? _noSetup(String _) => null;

/// 에디터의 상태. 화면과 떼어 둔 이유는 상위 화면(복사 버튼 등)이 같은 상태를
/// 봐야 하고, 위젯 테스트에서 직접 찔러볼 수 있어야 해서다.
class RoutineEditorController extends ChangeNotifier {
  RoutineEditorController({
    Iterable<String> history = const [],
    this.weightUnit = defaultUnit,
    this.savedSetup = _noSetup,
  }) {
    _learned.addAll(history);
  }

  /// 저장된 기록에서 제목이 똑같은 칸의 설정(NotesStore.setupOf).
  final WorkoutSetup? Function(String title) savedSetup;

  /// 설정을 붙여 만든 칸 가운데 제목이 [title] 인 가장 최근 것의 설정 — 이 기록
  /// 먼저, 없으면 저장된 기록에서.
  WorkoutSetup? earlierSetup(String title) =>
      blocks.reversed
          .where((b) => b.name == title && b.setup != null)
          .firstOrNull
          ?.setup ??
      savedSetup(title);

  String weightUnit;
  final List<ExerciseBlock> blocks = [];
  final List<String> _learned = [];
  List<String> get recentExercises => List.unmodifiable(_learned);

  void forgetExercise(String name) {
    if (_learned.remove(name)) notifyListeners();
  }

  /// 이 기기에서 실제로 친 이름이 씨앗 목록보다 앞선다.
  /// 씨앗은 화면 언어의 이름으로 낸다 — 검색은 어느 언어로 하든 잡힌다.
  List<String> vocabulary(String lang) => [
    ..._learned,
    ...seedNames(lang).where((e) => !_learned.contains(e)),
  ];

  /// 마지막 운동이 아직 세트를 받는 중인가.
  ///
  /// 이 값이 참이면 커서는 그 운동 카드 **안**에 있고, 거짓이면 카드 밖에서
  /// 새 운동 이름을 기다린다. 화면에서 커서가 있는 자리가 곧 모드라서
  /// 따로 안내할 것이 없다.
  bool get inBlock => _active >= 0 && _active < blocks.length;

  /// 지금 세트를 받고 있는 운동. -1 이면 카드 밖이고 새 운동 이름을 기다린다.
  ///
  /// 예전에는 "닫혔나" 하나였고 세트는 늘 마지막 운동으로 갔다. 그러면 앞서
  /// 끝낸 운동에 한 세트를 더 붙일 방법이 없다 — 실제로는 한 운동을 끝내고
  /// 다른 걸 하다가 돌아오는 일이 흔하다. 어느 카드가 열려 있는지를 들고
  /// 있으면 카드를 눌러 그리로 옮겨갈 수 있다.
  int get activeIndex => _active;
  int _active = -1;

  /// 방금 끝낸 운동. 빈 자리에서 지우기를 누르면 **여기로** 돌아간다 —
  /// 메모장에서 빈 줄의 지우기가 앞줄 끝으로 가는 것과 같다. 문서의 마지막
  /// 운동이 아니다: 앞쪽 운동을 고치고 끝냈으면 돌아갈 곳도 그 앞쪽이다.
  ExerciseBlock? get lastClosed =>
      blocks.contains(_lastClosed) ? _lastClosed : blocks.lastOrNull;
  ExerciseBlock? _lastClosed;

  bool get naming => !inBlock;

  /// 카드를 눌러 그 운동을 다시 연다.
  void openBlock(int index) {
    if (index < 0 || index >= blocks.length || index == _active) return;
    _active = index;
    notifyListeners();
  }

  void addExercise(String name, {WorkoutSetup? setup, String? learnAs}) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    blocks.add(ExerciseBlock(clean, null, setup));
    // 익히는 것은 운동 이름이다. 친 문장을 통째로 익히면 다음에 그 문장이
    // 후보로 뜬다 — "타바타 벤치프레스 30kg 100개" 가 사전에 남던 것이 그것이다.
    final learned = (learnAs ?? clean).trim();
    if (learned.isNotEmpty) {
      _learned.remove(learned);
      _learned.insert(0, learned);
    }
    _active = blocks.length - 1;
    notifyListeners();
  }

  /// 커서를 옮기지 않고 칸만 더한다 — 상대가 같이 하자고 한 운동이다. 치던 것이
  /// 있어도 그 자리 그대로 남는다. 이름은 익히지 않는다: 내가 친 것이 아니다.
  ExerciseBlock addBlockQuietly(String name) {
    final block = ExerciseBlock(name.trim());
    blocks.add(block);
    notifyListeners();
    return block;
  }

  /// 횟수만으로 한 세트. 같이 하는 타이머의 쉬는 구간에서 한 번 눌러 적는다.
  void logReps(ExerciseBlock block, int reps) {
    if (!blocks.contains(block)) return;
    block.sets.add(
      LoggedSet(
        value: block.setup?.weight,
        unit: block.setup?.unit ?? block.myLast?.unit ?? weightUnit,
        reps: reps,
      ),
    );
    notifyListeners();
  }

  bool addSet(String line) {
    final parsed = parseSetLine(line);
    if (parsed == null || !inBlock) return false;
    LoggedSet makeSet() => LoggedSet(
      value: parsed.value ?? blocks[_active].setup?.weight,
      // 단위를 안 쳤으면 이 운동에서 쓰던 것을 잇는다. 한 운동 안에서
      // 세트마다 단위가 바뀌는 일은 없다.
      unit:
          parsed.unit ??
          blocks[_active].setup?.unit ??
          blocks[_active].myLast?.unit ??
          weightUnit,
      reps: parsed.reps,
      notes: parsed.note == null ? null : [parsed.note!],
    );
    blocks[_active].sets.addAll(List.generate(parsed.count, (_) => makeSet()));
    notifyListeners();
    return true;
  }

  /// 직전 세트 — 키패드의 "이전과 같이" 가 보여줄 것.
  /// 같이 고치는 문서에서는 **내** 마지막 세트다 — 옆 사람의 무게를 이어 받으면
  /// 안 된다. 내 세트가 없으면 그냥 마지막 세트.
  LoggedSet? get lastSet => inBlock ? blocks[_active].myLast : null;

  /// 같은 세트를 한 번 더. 운동 기록에서 가장 흔한 동작이라 한 번에 준다.
  void repeatLastSet() {
    final s = lastSet;
    if (s == null) return;
    blocks[_active].sets.add(
      LoggedSet(
        value: s.value,
        unit: s.unit,
        reps: s.reps,
        notes: [...s.notes],
      ),
    );
    notifyListeners();
  }

  /// 빈 줄에서 Enter — 이 운동은 여기까지. 목록 밖으로 커서가 빠져나온다.
  /// 노션에서 빈 리스트 항목에 Enter를 치면 리스트를 벗어나는 것과 같다.
  void closeBlock() {
    if (!inBlock) return;
    _lastClosed = blocks[_active];
    _active = -1;
    notifyListeners();
  }

  /// 지금 맥락에서 맞는 쪽으로 넣는다.
  void commit(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      closeBlock();
      return;
    }
    if (naming) {
      addExercise(text);
    } else if (!addSet(text)) {
      // 세트를 받는 중에 숫자 없는 줄이 오면 그 운동은 끝났고 다음 운동이다.
      _active = -1;
      addExercise(text);
    }
  }

  /// 설정만 바꾼다. 제목은 사람이 친 글 그대로 둔다 — 제목이 곧 타이머라
  /// 'bpm 푸시업 100개 채우기' 가 '푸시업' 으로 바뀌면 bpm 이 사라진다.
  void updateSetup(int index, WorkoutSetup setup) {
    if (index < 0 || index >= blocks.length) return;
    blocks[index].setup = setup;
    notifyListeners();
  }

  void renameBlock(int index, String name, {bool learn = true}) {
    final clean = name.trim();
    if (index < 0 ||
        index >= blocks.length ||
        clean.isEmpty ||
        clean.length > 120 ||
        clean.contains('\n')) {
      return;
    }
    final block = blocks[index];
    block.name = clean;
    if (block.setup != null) {
      block.setup = WorkoutSetup.fromJson({
        ...block.setup!.toJson(),
        'name': clean,
      });
    }
    if (learn) {
      _learned.remove(clean);
      _learned.insert(0, clean);
    }
    notifyListeners();
  }

  void updateSet(int block, int index, LoggedSet value) {
    if (block < 0 ||
        block >= blocks.length ||
        index < 0 ||
        index >= blocks[block].sets.length) {
      return;
    }
    final previous = blocks[block].sets[index];
    blocks[block].sets[index] = LoggedSet(
      id: previous.id,
      value: value.value,
      unit: value.unit,
      reps: value.reps,
      notes: [...previous.notes],
      done: previous.done,
      author: previous.author,
    );
    notifyListeners();
  }

  /// 고친 세트 줄에 같이 친 것 — 메모는 그 세트에 더하고, "x3" 이면 같은 세트를
  /// 운동 끝에 더 둔다. 새로 친 세트 줄과 같다([addSet]) — 같이 고치는 문서도 새
  /// 세트를 끝에 붙이므로 순서가 어긋나지 않는다. 사본은 적은 사람을 물려받는다.
  void extendSet(int block, int index, {String? note, int count = 1}) {
    final set = blocks[block].sets[index];
    if (note != null) set.notes.add(note);
    blocks[block].sets.addAll([
      for (var i = 1; i < count; i++)
        LoggedSet(
          value: set.value,
          unit: set.unit,
          reps: set.reps,
          notes: [?note],
          done: set.done,
          author: set.author,
        ),
    ]);
    notifyListeners();
  }

  void moveBlock(int from, int to) {
    if (from < 0 || from >= blocks.length || to < 0 || to >= blocks.length) {
      return;
    }
    final active = inBlock ? blocks[_active] : null;
    blocks.insert(to, blocks.removeAt(from));
    _active = active == null ? -1 : blocks.indexOf(active);
    notifyListeners();
  }

  /// 마지막 세트에 메모를 **더한다**.
  ///
  /// 예전에는 세트를 칠 때 같은 줄에 적어 넣는 수밖에 없었다. 그러면 이미
  /// 넣은 세트에는 메모를 달 방법이 없어서 지우고 다시 쳐야 했다 — 정작
  /// 메모를 적고 싶어지는 것은 세트를 끝낸 다음이다.
  ///
  /// 덮어쓰지 않고 쌓는다. 세트를 끝내고 떠오르는 생각은 대개 하나가 아니다.
  void noteLastSet(String text) {
    if (!inBlock) return;
    // 내 마지막 세트에 단다 — 치는 사이 옆 사람이 세트를 더해도 그쪽에 붙지 않는다.
    final set = blocks[_active].myLast;
    if (set == null) return;
    final clean = text.trim();
    if (clean.isEmpty) return;
    set.notes.add(clean);
    notifyListeners();
  }

  /// 메모 한 줄을 고친다. 빈 글이면 지운 것으로 본다.
  void editNote(int block, int set, int index, String text) {
    final notes = blocks[block].sets[set].notes;
    if (index < 0 || index >= notes.length) return;
    final clean = text.trim();
    if (clean.isEmpty) {
      notes.removeAt(index);
    } else {
      notes[index] = clean;
    }
    notifyListeners();
  }

  /// 메모 한 줄을 지운다.
  void removeNote(int block, int set, int index) {
    final notes = blocks[block].sets[set].notes;
    if (index < 0 || index >= notes.length) return;
    notes.removeAt(index);
    notifyListeners();
  }

  /// 해낸 세트인지 뒤집는다. 잘못 눌렀을 때 되돌릴 방법이 있어야 한다.
  void toggleDone(int block, int set) {
    blocks[block].sets[set].done = !blocks[block].sets[set].done;
    notifyListeners();
  }

  /// 세트 하나 취소.
  void removeSet(int block, int set) {
    final b = blocks[block];
    b.sets.removeAt(set);
    notifyListeners();
  }

  /// 운동 통째로 삭제.
  void removeBlock(int block) {
    blocks.removeAt(block);
    if (_active == block) {
      _active = -1;
    } else if (_active > block) {
      _active -= 1;
    }
    notifyListeners();
  }

  /// 다음 지우기가 운동을 통째로 뗄 상황인가. 화면이 물어볼지 정하는 데 쓴다.
  bool get backspaceRemovesBlock => inBlock && blocks[_active].sets.isEmpty;

  /// 빈 칸에서 지우기. **저장된 세트는 지우지 않는다** — 세트를 지우는 것은
  /// 그 줄의 × 다. 카드 밖이면 방금 끝낸 운동으로 돌아가고, 세트가 하나도
  /// 없는 운동 안이면 그 운동을 뗀다(화면이 먼저 묻는다).
  void backspace() {
    if (blocks.isEmpty) return;
    if (!inBlock) {
      _active = blocks.indexOf(lastClosed!);
    } else if (blocks[_active].sets.isEmpty) {
      blocks.removeAt(_active);
      _active = -1;
    } else {
      return;
    }
    notifyListeners();
  }

  void clear() {
    blocks.clear();
    _active = -1;
    notifyListeners();
  }

  /// 저장해 둔 메모를 열 때. 커서는 카드 **밖**에서 시작한다 — 다시 연 사람은
  /// 대개 다음 운동을 치지, 마지막 운동에 세트를 더 붙이지 않는다. 붙이려면
  /// 그 카드를 누르면 된다.
  void restore(List<ExerciseBlock> saved) {
    blocks
      ..clear()
      ..addAll(saved);
    // 저장된 이름도 이 기기에서 친 이름이다. 자동완성이 알아야 한다. 익히는 것은
    // 운동 이름이다 — 제목 문장('벤치 80kg 5x5')이 아니다.
    for (final b in saved.reversed) {
      final name = b.learnedName;
      if (name == null) continue;
      _learned.remove(name);
      _learned.insert(0, name);
    }
    _active = -1;
    _lastClosed = null;
    notifyListeners();
  }

  /// 같이 고치는 문서가 서버에서 왔다. **있던 운동은 그 객체를 고쳐 쓴다** —
  /// 타이머, 카드의 키, 열린 자리, 설정 시트가 모두 그 객체를 붙잡고 있다. 새
  /// 객체로 갈아 끼우면 상대가 세트 하나만 더해도 내 타이머가 꺼졌다.
  ///
  /// 돌려주는 것은 내가 적던 운동을 누가 지웠을 때 그 운동이다.
  ExerciseBlock? replaceBlocks(List<ExerciseBlock> next) {
    final byId = {for (final b in blocks) b.id: b};
    var changed = next.length != blocks.length;
    final merged = <ExerciseBlock>[];
    for (final (i, n) in next.indexed) {
      final have = byId[n.id];
      if (have == null) {
        merged.add(n);
        changed = true;
        continue;
      }
      if (!_sameBlock(have, n)) {
        final sets = {for (final s in have.sets) s.id: s};
        have
          ..name = n.name
          ..setup = n.setup;
        final nextSets = [
          for (final s in n.sets)
            if (sets[s.id] case final old? when _sameSet(old, s)) old else s,
        ];
        have.sets
          ..clear()
          ..addAll(nextSets);
        changed = true;
      }
      if (i >= blocks.length || !identical(blocks[i], have)) changed = true;
      merged.add(have);
    }
    if (!changed) return null;
    final active = inBlock ? blocks[_active] : null;
    blocks
      ..clear()
      ..addAll(merged);
    _active = active == null ? -1 : blocks.indexOf(active);
    if (!blocks.contains(_lastClosed)) _lastClosed = null;
    // 남이 바꾼 것이다. 편집기는 이것을 보고 화면을 내 입력 줄로 끌어내리지 않는다.
    remote = true;
    notifyListeners();
    remote = false;
    return active != null && _active < 0 ? active : null;
  }

  /// 지금 알리는 변경이 같이 고치는 사람에게서 왔는가.
  bool remote = false;

  /// 번호가 아니라 그 운동을 지운다. 확인창이 떠 있는 사이 문서가 바뀌어도
  /// 엉뚱한 운동이 지워지지 않는다.
  void removeBlockObject(ExerciseBlock block) {
    final at = blocks.indexOf(block);
    if (at >= 0) removeBlock(at);
  }

  static bool _sameBlock(ExerciseBlock a, ExerciseBlock b) =>
      a.id == b.id &&
      a.name == b.name &&
      a.setup?.toJson().toString() == b.setup?.toJson().toString() &&
      a.sets.length == b.sets.length &&
      a.sets.indexed.every((e) => _sameSet(e.$2, b.sets[e.$1]));

  static bool _sameSet(LoggedSet x, LoggedSet y) =>
      x.id == y.id &&
      x.author == y.author &&
      x.value == y.value &&
      x.unit == y.unit &&
      x.reps == y.reps &&
      x.done == y.done &&
      listEquals(x.notes, y.notes);

  int get totalSets =>
      blocks.fold(0, (n, b) => n + b.sets.where((s) => s.mine).length);

  /// 클립보드로 나가는 글. 세트·횟수 표기는 화면 언어를 탄다.
  String asText({
    String Function(int n)? setOrdinal,
    String Function(int n)? formatReps,
  }) => blocks
      .map((b) => (name: b.name, sets: b.sets.where((s) => s.mine).toList()))
      .where((b) => b.sets.isNotEmpty)
      .map((b) {
        final lines = <String>[b.name];
        for (var i = 0; i < b.sets.length; i++) {
          final s = b.sets[i];
          lines.add(
            [
              setOrdinal?.call(i + 1) ?? '${i + 1}세트',
              setLabel(
                value: s.value,
                unit: s.unit,
                reps: s.reps,
                formatReps: formatReps ?? (n) => '$n회',
              ),
              ...s.notes,
            ].join(' '),
          );
        }
        return lines.join('\n');
      })
      .join('\n\n');
}

/// 운동을 통째로 지우기 전에 묻는다.
///
/// 부르는 곳이 둘이다 — 카드의 지우기 버튼, 그리고 백스페이스를 계속 눌러
/// 세트가 다 빠진 뒤의 마지막 한 번. 결과가 같으므로 묻는 말도 같아야 한다.
Future<bool> confirmRemoveExercise(
  BuildContext context,
  ExerciseBlock block, {
  String? busy,
}) async {
  final l = L.of(context);
  final yes = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(l.deleteExerciseTitle(block.name)),
      content: Text(
        [
          // 같이 고치는 사람이 지금 이 운동을 적고 있다. 지우면 그 사람 것도 사라진다.
          ?busy == null ? null : l.liveExerciseBusy(busy),
          block.sets.isEmpty
              ? l.deleteExerciseEmptyBody
              : l.deleteExerciseBody(block.sets.length),
        ].join('\n'),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        // 되돌릴 수 없는 쪽을 destructive 로 낸다 — iOS 는 색으로 알린다.
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.delete),
        ),
      ],
    ),
  );
  return yes ?? false;
}

/// 하나의 편집 흐름. 결과를 보는 곳과 치는 곳이 나뉘어 있지 않고,
/// 커서가 늘 "지금 쓰는 자리"에 있다.
class RoutineEditor extends StatefulWidget {
  const RoutineEditor({
    super.key,
    required this.controller,
    this.countAloud = false,
    this.header,
    this.footer,
    this.ai = const RecordAi(),
    this.initialDraft,
    this.onDraftChanged,
    this.onForgetExercise,
    this.onMealPhoto,
    this.mealText,
    this.onMealText,
    this.recentMeals = const [],
    this.recovery,
    this.partner,
    this.presence = const [],
    this.onPresence,
    this.timer,
  });
  final RoutineEditorController controller;

  /// 같이 운동 중이면 있다. 타이머를 같은 순간에 돌리는 데 쓴다.
  final PartnerSync? partner;

  /// 같이 고치는 사람들이 지금 만지는 자리. 그 자리에 그 사람의 색이 붙는다.
  final List<PartnerPresence> presence;

  /// 내가 만지는 자리(운동 번호, 세트 번호, 치는 글)가 바뀔 때마다.
  final void Function(String? block, String? set, String text)? onPresence;

  /// 없으면 여기서 만든다 — 테스트가 시계와 소리를 끼워 넣는 자리다.
  final WorkoutTimer? timer;

  /// 심박으로 휴식을 끊어 주는 쪽. 없으면 여기서 만든다 — 테스트가 끼워
  /// 넣는 자리다.
  final RestRecovery? recovery;

  /// 박자마다 몇 번째인지 읽어 줄까. 설정에서 켠다.
  final bool countAloud;
  final Widget? header;

  /// 입력 줄 아래에 놓이는 것 — 같은 날의 다른 기록처럼 읽기만 하는 자리.
  final Widget? footer;

  /// 질문을 해석해 주는 쪽. 서버에 묻는다.
  final RecordAi ai;
  final EditorDraft? initialDraft;
  final ValueChanged<EditorDraft?>? onDraftChanged;
  final ValueChanged<String>? onForgetExercise;
  final VoidCallback? onMealPhoto;

  /// 식단을 글로 적는 중이면 값이 있다. 운동을 적는 **같은 입력 줄**을 쓴다 —
  /// 입력칸이 둘이면 키보드도 포커스도 둘이 되어 서로 덮는다. 밖(식단 목록)
  /// 에서 값을 넣으면 그 글을 불러와 고치고, 저장하거나 그만두면 null 이 된다.
  final ValueNotifier<({String text, int? index})?>? mealText;

  /// 식단 글을 저장한다. index 가 있으면 그 끼니를 고친 것이다.
  final void Function(String text, int? index)? onMealText;

  /// 전에 적은 식단 글들. 식단을 적는 동안 후보로 뜬다.
  final List<String> recentMeals;

  @override
  State<RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends State<RoutineEditor>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  late final _workoutTimer = widget.timer ?? WorkoutTimer();
  late final _recovery = widget.recovery ?? RestRecovery(health: HealthLink());
  bool _timingKeyboardHidden = false;
  final _listKey = GlobalKey();
  final _headerKey = GlobalKey();
  final _handleKeys = <ExerciseBlock, GlobalKey>{};
  bool _reordering = false;
  bool _restoreFocus = false;

  /// 입력 줄이 트리의 다른 자리로 옮겨가도 같은 위젯으로 유지되게 한다.
  final _inputKey = GlobalKey();
  bool _invalidSet = false;
  TextEditingValue? _setDraft;
  bool _recordTitle = false;
  int? _recordSet;

  /// 고치기 시작할 때의 세트. 치는 대로 저장하므로, 지우는 도중의 읽히지
  /// 않는 글("8" 만 남은 "80kg 10")이 기록으로 남지 않게 이것으로 되돌린다.
  LoggedSet? _recordOriginal;

  /// 기록을 고치려고 열었을 때 입력 줄의 글. 이것과 같으면 고친 것이 없다.
  String? _recordStartText;
  bool _recordTouched = false;

  /// 고치던 메모가 달린 세트. 앞의 운동·세트가 지워져도 번호가 아니라 이것을 따라간다.
  String? _editingSetId;
  EditorDraft? _resume;
  bool get _editingRecord => _recordTitle || _recordSet != null;

  /// 화살표로 **고른** 후보. -1 이면 고른 것이 없고 Enter 는 친 글 그대로
  /// 넣는다 — 후보가 떠 있다는 이유만으로 친 이름이 첫 후보로 바뀌면 안 된다.
  int _highlight = -1;

  /// 빈 입력칸에 심어 두는 폭 없는 글자.
  ///
  /// 화면 키보드는 빈 칸에서 지우기를 눌러도 아무것도 보내지 않는다. 지울
  /// 글자가 하나 있어야 "빈 자리에서 지우기" 를 알 수 있다. 운동 이름을
  /// 기다리는 빈 칸에만 심고, 읽을 때는 늘 [_text] 로 걷어 낸다. 치는 도중에는
  /// 값을 건드리지 않는다 — 한글 조합이 깨진다.
  static const _zw = '\u200B';
  String get _text => _input.text.replaceAll(_zw, '');
  bool get _wantsSentinel =>
      _c.naming && !_editingRecord && !_mealMode && _c.blocks.isNotEmpty;

  bool get _mealMode => widget.mealText?.value != null;

  /// 밖에서 식단 적기를 켰거나 껐다.
  void _onMealRequest() {
    final request = widget.mealText!.value;
    if (request != null) {
      if (_editingRecord && !_finishRecordEdit()) {
        widget.mealText!.value = null;
        return;
      }
      // 치던 세트 줄은 버린다 — 다른 운동 카드를 누를 때와 같다.
      _wantText = false;
      _editing = null;
      _setDraft = null;
      _c.closeBlock();
    }
    final text = request?.text ?? '';
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reopen();
    });
  }

  void _syncSentinel() {
    if (_wantsSentinel && _input.text.isEmpty) {
      _input.value = const TextEditingValue(
        text: _zw,
        selection: TextSelection.collapsed(offset: 1),
      );
    } else if (!_wantsSentinel && _input.text.contains(_zw)) {
      final clean = _text;
      _input.value = TextEditingValue(
        text: clean,
        selection: TextSelection.collapsed(offset: clean.length),
      );
    }
  }

  bool _aiBusy = false;

  /// 적기 도움이 남긴 한 줄 — 왜 적은 그대로 만들었는지, 왜 입력칸에 두었는지.
  /// 다음에 무언가 치면 사라진다.
  String Function(L l)? _aiNotice;
  int _aiRequest = 0;
  String? _locale;
  String? _submittedText;
  WorkoutSetup? get _setup =>
      _c.inBlock ? _c.blocks[_c.activeIndex].setup : null;

  /// 메모를 칠 때만 잠깐 시스템 키보드로 넘어간다. 세트를 하나 넣으면
  /// 다시 키패드로 돌아온다 — 메모는 세트마다 붙는 게 아니라 가끔 붙는다.
  bool _wantText = false;
  bool _textKeyboardHidden = false;

  /// 칠 것이 들어 있는가. 키패드의 큰 키가 하는 일이 여기 따라 달라진다.
  /// 뒤집힐 때만 다시 그린다 — 글자마다 그릴 이유가 없다.
  bool _hasInput = false;

  /// +/- 가 한 번에 미는 폭. 길게 눌러 바꾼다. null 이면 단위의 기본값이다.
  double? _step;

  /// 지금 고치고 있는 메모의 자리 (운동, 세트, 메모). null 이면 새로 다는 중.
  (int, int, int)? _editing;

  /// 메모 한 줄을 입력칸으로 불러온다. 커밋하면 그 자리를 덮어쓴다.
  void _startEditNote(int block, int set, int note) {
    if (_editingRecord && !_finishRecordEdit()) return;
    widget.mealText?.value = null;
    final text = _c.blocks[block].sets[set].notes[note];
    if (!_wantText && _c.activeIndex == block) _setDraft = _input.value;
    _c.openBlock(block);
    _input.text = text;
    _input.selection = TextSelection.collapsed(offset: _input.text.length);
    setState(() {
      _editing = (_c.activeIndex, set, note);
      _editingSetId = _c.blocks[block].sets[set].id;
      _wantText = true;
    });
    _tellPresence();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reopen();
      _showInput();
    });
  }

  /// 지금 치는 자리의 단위. 아직 안 쳤으면 이 운동에서 쓰던 것을 잇는다.
  String get _unit {
    final typed = parseSetLine(_text)?.unit;
    if (typed != null) return typed;
    final sets = _c.inBlock
        ? _c.blocks[_c.activeIndex].sets
        : const <LoggedSet>[];
    if (_recordSet != null && _recordSet! < sets.length) {
      return sets[_recordSet!].unit;
    }
    final mine = _c.inBlock ? _c.blocks[_c.activeIndex].myLast : null;
    return _setup?.unit ?? mine?.unit ?? _c.weightUnit;
  }

  /// 지금 미는 폭. 횟수를 치는 중이면 1이다 — 횟수를 2.5씩 미는 일은 없다.
  double get _stepSize {
    if (_typingReps) return 1;
    return _step ?? (unitById[_unit] ?? unitById[defaultUnit]!).step;
  }

  /// 무게(또는 거리·시간)를 지나 횟수를 치고 있는가.
  bool get _typingReps =>
      (_setup?.countsReps ?? false) ||
      RegExp(
        '($unitPattern)\\s*[\\d.]*\$',
        caseSensitive: false,
      ).hasMatch(_text) ||
      _text.trimLeft().contains(' ');

  /// 길게 눌러 미는 폭을 고른다. 원판이 나라마다 다르고 사람마다 올리는
  /// 폭이 다르다 — 2.5 를 박아두면 파운드로 하는 사람은 매번 손으로 친다.
  Future<void> _pickStep() async {
    final u = unitById[_unit] ?? unitById[defaultUnit]!;
    final picked = await showCupertinoModalPopup<double>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(L.of(context).stepSizeTitle(u.label)),
        actions: [
          for (final v in u.steps)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, v),
              child: Text(
                // 시트에도 단위를 붙인다. 제목에만 있으면 항목을 훑을 때
                // 무엇의 2.5 인지 다시 위를 봐야 한다.
                formatValue(v, u.id),
                style: TextStyle(
                  fontWeight: v == _stepSize
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(L.of(context).cancel),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _step = picked);
  }

  RoutineEditorController get _c => widget.controller;

  /// 마지막으로 본 구간. 같은 구간에서 여러 번 부르지 않으려고 둔다.
  TimingPhase? _seenPhase;
  int? _seenRound;

  /// 타이머가 구간을 넘길 때마다 기준선을 다시 잡는다. 세트가 시작되면
  /// 최고 심박을 새로 세고, 휴식이 시작되면 그때부터 회복을 본다.
  void _followTimer() {
    if (!_workoutTimer.running) {
      if (_seenPhase != null) {
        _seenPhase = null;
        _seenRound = null;
        _recovery.reset();
      }
      return;
    }
    _recovery.listen();
    final phase = _workoutTimer.phase;
    final round = _workoutTimer.round;
    if (phase == _seenPhase && round == _seenRound) return;
    _seenPhase = phase;
    _seenRound = round;
    if (phase == TimingPhase.work) _recovery.beginRound();
    if (phase == TimingPhase.rest) _recovery.beginRest();
  }

  // ── 같이 하는 타이머 ─────────────────────────────────────────────

  /// 같이 돌리는 칸. 내가 제안했거나 받아들인 칸을 기억해 둔다 — 같은 이름의
  /// 칸이 둘이어도 헷갈리지 않는다.
  ExerciseBlock? _sharedBlock;

  SharedTimer? get _shared {
    final session = widget.partner?.session;
    return session?.state == PartnerState.active ? session!.timer : null;
  }

  bool _live(SharedTimer? t) =>
      t != null && t.started && !t.overAt(widget.partner?.clock.now);

  ExerciseBlock? _blockFor(SharedTimer t) {
    final kept = _sharedBlock;
    if (kept != null &&
        _c.blocks.contains(kept) &&
        TimingSpec.parse(kept.name) == t.spec) {
      return kept;
    }
    return _c.blocks.where((b) => b.name == t.title).firstOrNull ??
        _c.blocks.where((b) => TimingSpec.parse(b.name) == t.spec).firstOrNull;
  }

  /// 내 타이머를 같이 하는 자리에 둔다. 상대 소식이 올 때마다, 앱으로 돌아올
  /// 때마다 부른다 — 이미 제자리면 아무 일도 없다.
  void _followShared() {
    if (!mounted) return;
    final t = _shared;
    // 내가 동의한 타이머만 따라간다. 셋이 같이 할 때 다른 둘이 시작했다고 내 폰이
    // 울리면 안 된다.
    if (_live(t) && t!.joined && t.myLeft == null) {
      final block = _blockFor(t);
      final at = t.elapsedAt(widget.partner!.clock.now);
      if (block != null && at != null) {
        final joining = !_workoutTimer.shared || !_workoutTimer.running;
        _workoutTimer.follow(block, t.personal, at);
        if (joining && _workoutTimer.running) {
          _focus.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          _timingKeyboardHidden = true;
        }
      }
    } else if (_workoutTimer.shared &&
        _workoutTimer.running &&
        (t == null || !t.started)) {
      // 상대가 치웠거나 새 제안이 앞의 것을 갈아 치웠다.
      _workoutTimer.reset();
    }
    setState(() {});
  }

  /// 나만 그만둔다. 상대에게는 어디서 멈췄는지가 간다.
  void _leaveShared() {
    final at = _workoutTimer.elapsed, beat = _workoutTimer.beat;
    _workoutTimer.pause();
    widget.partner?.leaveTimer(at, beat);
  }

  void _proposeShared(ExerciseBlock block, TimingSpec spec, bool alternate) {
    final t = _shared;
    _sharedBlock = block;
    // 상대가 같은 것을 먼저 제안해 두었다면 그것을 받는 것이 곧 같이 시작이다.
    if (t != null && !t.started && !t.mine && t.spec == spec) {
      widget.partner!.acceptTimer();
    } else {
      widget.partner!.proposeTimer(block.name, spec, alternate: alternate);
    }
  }

  void _acceptShared() {
    final t = _shared;
    if (t == null || t.joined) return;
    _sharedBlock = _blockFor(t) ?? _c.addBlockQuietly(t.title);
    widget.partner!.acceptTimer();
  }

  /// 시작·정지가 눌렸다. 같이 하는 중이면 그만두기·다시 들어가기다.
  bool _togetherToggle(ExerciseBlock block) {
    final sync = widget.partner, t = _shared;
    if (sync == null || t == null) return false;
    if (_live(t) && t.joined && identical(block, _blockFor(t))) {
      t.myLeft == null ? _leaveShared() : sync.rejoinTimer();
      return true;
    }
    // 다른 칸의 타이머를 혼자 돌리겠다는 것이다. 같이 하던 것에서는 빠진다.
    if (_live(t) && t.joined && t.myLeft == null) _leaveShared();
    if (!t.started && t.mine) sync.clearTimer();
    return false;
  }

  TogetherTiming? _togetherFor(ExerciseBlock block, L l) {
    final sync = widget.partner, session = sync?.session;
    if (sync == null || session?.state != PartnerState.active) return null;
    final t = session!.timer;
    final here = t != null && identical(_blockFor(t), block);
    final mineToo = here && t.joined;
    final cycle = t == null ? 1 : t.personal.work + t.personal.rest;

    // 같이 돌리는 사람마다 한 줄: 이름, 세트마다의 횟수, 그만뒀으면 어디서.
    // 옛 서버는 사람 목록을 주지 않는다 — 그때는 상대가 한 명이다.
    final people = !mineToo
        ? const <
            ({
              String name,
              List<ExerciseBlock> blocks,
              ({int ms, int beat})? left,
            })
          >[]
        : t.others.isEmpty
        ? [
            (
              name: session.partnerName ?? '',
              blocks: session.partnerBlocks,
              left: t.partnerLeft,
            ),
          ]
        : [
            for (final o in t.others)
              (
                name: o.name,
                blocks:
                    session.others
                        .where((p) => p.key == o.key)
                        .firstOrNull
                        ?.blocks ??
                    const <ExerciseBlock>[],
                left: o.left,
              ),
          ];
    List<int?> counts(List<ExerciseBlock> blocks) {
      final theirs =
          blocks.where((b) => b.name == t!.title).firstOrNull ??
          blocks.where((b) => TimingSpec.parse(b.name) == t!.spec).firstOrNull;
      return [for (final s in theirs?.sets ?? const <LoggedSet>[]) s.reps];
    }

    final gone = [
      for (final p in people)
        if (t!.started && p.left != null)
          t.spec.tabata
              ? l.togetherLeftRound(
                  p.name,
                  ((p.left!.ms / 1000 - 3) / cycle).floor().clamp(
                        0,
                        t.spec.rounds - 1,
                      ) +
                      1,
                )
              : l.togetherLeftBeat(p.name, p.left!.beat),
    ];
    final started = mineToo && t.started;
    return TogetherTiming(
      partner: people.firstOrNull?.name ?? session.partnerName ?? '',
      waiting: here && !t.started && t.mine,
      busy: !here && _live(t) && t!.joined && t.myLeft == null,
      live: mineToo && _live(t),
      left: mineToo && t.myLeft != null,
      alternate: mineToo && t.alternate,
      partnerLeft: gone.isEmpty ? null : gone.join('\n'),
      mine: started
          ? [
              for (final s in block.sets)
                if (s.author == null) s.reps,
            ]
          : const [],
      theirs: started && people.isNotEmpty
          ? counts(people.first.blocks)
          : const [],
      more: [
        if (started)
          for (final p in people.skip(1))
            (name: p.name, counts: counts(p.blocks)),
      ],
      onPropose: (alternate) =>
          _proposeShared(block, TimingSpec.parse(block.name)!, alternate),
      onToggle: () => _togetherToggle(block),
      onCancel: sync.clearTimer,
      onLog: (n) => _c.logReps(block, n),
    );
  }

  /// 회복했으면 남은 휴식을 건너뛴다. 심박은 휴식을 짧게 할 뿐이다 —
  /// 값이 없거나 늦게 오면 아무 일도 일어나지 않고 시간이 끊는다.
  void _followHeart() {
    // 타바타 중 심박이 처음 들어오면 경보 권한을 한 번 묻는다 — 쓸 때가 된 순간이다.
    if (!_restAlarmAsked &&
        _recovery.fresh &&
        _workoutTimer.running &&
        _workoutTimer.spec?.tabata == true) {
      _restAlarmAsked = true;
      unawaited(authorizeRestAlarm());
    }
    if (!_recovery.recovered) return;
    final resting = _workoutTimer.phase == TimingPhase.rest;
    _workoutTimer.skipRest();
    // 심박이 휴식을 끝냈다. 폰의 시작 신호에 더해 손목까지 — 폰을 안 보고 있어도.
    if (resting && _workoutTimer.phase != TimingPhase.rest && mounted) {
      unawaited(ringRestAlarm(L.of(context).restAlarmTitle));
    }
  }

  bool _restAlarmAsked = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDraft != null) _restoreDraft(widget.initialDraft!);
    widget.mealText?.addListener(_onMealRequest);
    _c.addListener(_onChanged);
    // Keep memo mode until it is explicitly saved, even if the IME loses focus.
    _input.addListener(_onInput);
    _workoutTimer.addListener(_followTimer);
    _recovery.addListener(_followHeart);
    widget.partner?.addListener(_followShared);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = Localizations.localeOf(context).toLanguageTag();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱을 내리면 타이머가 멈춘다. 돌아오면 같이 하던 자리로 곧바로 돌아간다.
    // 답을 기다리다 앱을 내려도 요청은 버리지 않는다(X11) — 늦은 답이 오면 확인
    // 창이 열려 있고, 돌아온 사람이 거기서 고른다. 다시 물어 한도를 또 쓰지 않는다.
    if (state == AppLifecycleState.resumed) _followShared();
  }

  Future<void> _interpret(String text) async {
    if (_aiBusy) return;
    // 이만큼 긴 글은 모델에 보내지 않는다. 글은 입력칸에 그대로 둔다.
    if (text.length > 600) {
      setState(() => _aiNotice = (l) => l.inputTooLong);
      return;
    }
    final request = ++_aiRequest;
    _submittedText = text;
    setState(() {
      _aiBusy = true;
      _aiNotice = null;
    });
    SetupReading reading;
    try {
      reading = await widget.ai.interpret(
        text,
        _locale ?? 'en',
        _c.vocabulary(_lang),
        defaultWeightUnit: _c.weightUnit,
      );
    } catch (e) {
      if (mounted && request == _aiRequest) {
        _aiBusy = false;
        _fallback(text, _fallbackReason(e));
      }
      return;
    } finally {
      // 기다리는 것은 답까지다. 확인 창이 열린 동안은 바쁘지 않다 — 그래야 창을
      // 연 채 앱을 내렸다 돌아와도 요청이 버려지지 않는다(X13).
      if (mounted && request == _aiRequest) setState(() => _aiBusy = false);
    }
    // 기다리는 사이 글을 고쳤거나 다른 카드로 갔으면 늦은 답은 쓰지 않는다.
    if (!mounted || request != _aiRequest || !_c.naming || _text != text) {
      return;
    }
    if (reading.exercises.isEmpty) {
      // 운동이 아니라는 답이다. 칸은 만들되 이름으로 익히지 않는다.
      _fallback(text, (l) => l.aiFallbackUnread, learn: false);
      return;
    }
    // 제목에 친 말을 다 담지 못한다(120자 넘는 글). 칸을 만들지 않고 글을 둔다 —
    // 모델이 읽은 부분만 제목이 되고 나머지가 사라지면 안 된다(X2).
    if (!reading.fits) {
      setState(() => _aiNotice = (l) => l.inputNameTooLong);
      _focus.requestFocus();
      return;
    }
    final titles = reading.titles;
    final proposed = [for (final e in reading.exercises) e.setup];
    bool planned(WorkoutSetup s) => s.hasPlan || s.repsOnly;
    // 설정할 것도, 알릴 것도 없는 운동 하나("민수식 로우 2")는 묻지 않고 만든다.
    final ask =
        proposed.length > 1 ||
        planned(proposed.single) ||
        reading.dropped.isNotEmpty;
    if (ask) _focus.unfocus();
    final List<WorkoutSetup?>? setups = ask
        ? await editWorkoutSetups(
            context,
            proposed,
            titles: titles,
            sourceText: text,
            unparsed: reading.unparsed,
            dropped: reading.dropped,
          )
        : proposed;
    // 창이 열린 뒤에는 사람이 확정한 것을 적용한다 — 그사이 요청 번호가
    // 바뀌었어도(앱을 내렸다 돌아옴) 버리지 않는다.
    if (!mounted) return;
    if (setups == null) {
      _focus.requestFocus();
      return;
    }
    if (_text == text) _input.clear();
    // 제목은 친 글이다. 창에서 값을 고쳐도 바뀌지 않는다 — 익히는 것은 운동 이름.
    // 앞 운동에 합친 칸(null)은 제목만 앞 칸에 이어 붙는다.
    final made = <(String, WorkoutSetup)>[];
    for (final (i, setup) in setups.indexed) {
      if (setup != null) {
        made.add((titles[i], setup));
      } else if (made.isNotEmpty) {
        made.last = ('${made.last.$1} ${titles[i]}', made.last.$2);
      }
    }
    for (final (title, setup) in made) {
      _c.addExercise(
        title,
        setup: planned(setup) ? setup : null,
        learnAs: setup.name,
      );
    }
    // 묻지 않고 만든 칸에도 못 옮긴 말은 한 줄로 보인다('러닝 5km' 의 5km).
    if (!ask && reading.unparsed.isNotEmpty) {
      final words = reading.unparsed.join(' · ');
      setState(() => _aiNotice = (l) => l.setupUnparsed(words));
    }
    _focus.requestFocus();
  }

  /// 모델을 못 썼다. 그래도 친 글 그대로 칸을 만들고 이유를 한 줄 말한다 —
  /// 막다른 길은 없다. 제목이 될 수 없는 긴 글만 입력칸에 두고 나누라고 한다.
  void _fallback(
    String text,
    String Function(L l) reason, {
    bool learn = true,
  }) {
    final clean = text.trim();
    if (clean.length > 120) {
      setState(() => _aiNotice = (l) => l.inputNameTooLong);
      _focus.requestFocus();
      return;
    }
    _input.clear();
    // 문장을 통째로 익히면 다음에 그 문장이 후보로 뜨고, 똑같이 치면 묻지 않는다.
    // 수 낱말을 뺀 이름만 익히고, 이름이 안 남으면 익히지 않는다.
    _c.addExercise(clean, learnAs: learn ? learnableName(clean) ?? '' : '');
    setState(() => _aiNotice = reason);
    _focus.requestFocus();
  }

  String Function(L l) _fallbackReason(Object error) => switch (error) {
    RecordAiException(status: RecordAiStatus.quotaExceeded) =>
      (l) => l.aiFallbackQuota,
    RecordAiException(offline: true) => (l) => l.aiFallbackOffline,
    RecordAiException() => (l) => l.aiFallbackServer,
    _ => (l) => l.aiFallbackUnread,
  };

  Widget? _noticeLine(BuildContext context) => _aiNotice == null
      ? null
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            _aiNotice!(L.of(context)),
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        );

  Future<void> _editSetup(int index) async {
    if (_editingRecord && !_finishRecordEdit()) return;
    final block = _c.blocks[index];
    _focus.unfocus();
    // 설정 없는 칸도 연다 — 모델을 못 써서 적은 그대로 만든 칸에 나중에 붙인다.
    final setup = await editWorkoutSetup(
      context,
      block.setup ?? WorkoutSetup(name: block.exercise),
    );
    if (!mounted) return;
    if (setup != null &&
        (block.setup != null || setup.hasPlan || setup.repsOnly)) {
      _c.updateSetup(_c.blocks.indexOf(block), setup);
    }
    _reopen();
  }

  EditorDraft get _draft => EditorDraft(
    text: _text,
    block: _c.activeIndex,
    blockId: _c.inBlock ? _c.blocks[_c.activeIndex].id : null,
    memo: _wantText,
    editingSet: _recordSet ?? _editing?.$2,
    editingNote: _editing?.$3,
    setText: _setDraft?.text,
    title: _recordTitle,
    resume: _resume,
    meal: _mealMode,
    mealIndex: widget.mealText?.value?.index,
  );

  void _restoreDraft(EditorDraft draft) {
    if (draft.meal && widget.mealText != null) {
      // initState 에서만 온다 — 아직 듣는 쪽이 없어 값을 넣어도 조용하다.
      widget.mealText!.value = (text: draft.text, index: draft.mealIndex);
    }
    _recordTitle = false;
    _recordSet = null;
    _editing = null;
    _wantText = false;
    _resume = draft.resume;
    final at = draft.blockId == null
        ? draft.block
        : _c.blocks.indexWhere((b) => b.id == draft.blockId);
    if (at >= 0 && at < _c.blocks.length) {
      _c.openBlock(at);
      _wantText = draft.memo;
      _recordTitle = draft.title;
      if (draft.title) {
        _recordStartText = draft.text;
        _recordTouched = false;
      }
      final st = draft.editingSet, n = draft.editingNote;
      if (st != null && st >= 0 && st < _c.blocks[at].sets.length) {
        if (draft.memo &&
            n != null &&
            n >= 0 &&
            n < _c.blocks[at].sets[st].notes.length) {
          _editing = (at, st, n);
          _editingSetId = _c.blocks[at].sets[st].id;
        } else if (!draft.memo) {
          _recordSet = st;
          // 되살린 편집도 그 세트를 id 로 따라가고, 안 바꾸고 닫으면 쓰지 않는다.
          _recordOriginal = _c.blocks[at].sets[st];
          _recordStartText = draft.text;
          _recordTouched = false;
        }
      }
    } else {
      _c.closeBlock();
    }
    _setDraft = draft.setText == null
        ? null
        : TextEditingValue(text: draft.setText!);
    _input.value = TextEditingValue(
      text: draft.text,
      selection: TextSelection.collapsed(offset: draft.text.length),
    );
    _hasInput = draft.text.trim().isNotEmpty;
  }

  void _editTitle(ExerciseBlock block) => _beginRecordEdit(block, null);
  void _editSet(ExerciseBlock block, int index) {
    // 같은 세트를 둘이 동시에 고치면 나중 것만 남는다. 먼저 잡은 사람에게 둔다.
    final busy = _busyOn(block, block.sets[index]);
    if (busy != null) {
      unawaited(_say(L.of(context).liveSetBusy(busy)));
      return;
    }
    _beginRecordEdit(block, index);
  }

  Future<void> _say(String message) => showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      content: Text(message, style: const TextStyle(fontSize: 15)),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(L.of(ctx).ok),
        ),
      ],
    ),
  );

  void _beginRecordEdit(
    ExerciseBlock block,
    int? tapped, {
    bool selectAll = true,
  }) {
    // 누른 세트는 번호가 아니라 그 세트로 잡는다 — 앞 편집을 끝내며 번호가 밀릴 수 있다.
    final id = tapped == null ? null : block.sets[tapped].id;
    if (_editingRecord && !_finishRecordEdit()) return;
    final index = id == null ? null : block.sets.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final resume = _draft;
    widget.mealText?.value = null;
    final set = index == null ? null : block.sets[index];
    _focus.unfocus();
    _wantText = false;
    _editing = null;
    _recordTitle = index == null;
    _recordSet = index;
    _recordOriginal = set;
    _resume = resume;
    _c.openBlock(_c.blocks.indexOf(block));
    _input.value = TextEditingValue(
      text: set == null
          ? block.name
          : [
              if (set.value != null) '${formatNumber(set.value!)}${set.unit}',
              if (set.reps != null) '${set.reps}',
            ].join(' '),
    );
    _recordStartText = _input.text;
    _recordTouched = false;
    _input.selection = TextSelection(
      // 지우기로 돌아왔으면 커서는 줄 끝이다. 눌러서 열었으면 통째로 고른다 —
      // 바로 새 값을 치면 되게.
      baseOffset: selectAll ? 0 : _input.text.length,
      extentOffset: _input.text.length,
    );
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reopen();
      _showInput();
    });
    _saveDraft();
  }

  /// 치는 대로 부르고([done] 아님), 편집을 끝낼 때 한 번 더 부른다([done]).
  /// 줄에 같이 친 메모와 "x3" 은 끝낼 때 한 번만 쓴다 — 치는 도중(x → x3 →
  /// x30)에 세트를 늘렸다 줄였다 하지 않고, 메모가 글자마다 쌓이지 않게.
  bool _applyRecordEdit({bool done = false}) {
    if (!_editingRecord || !_c.inBlock) return false;
    if (_input.value.composing.isValid && !_input.value.composing.isCollapsed) {
      return false;
    }
    final parsed = _recordTitle ? null : parseSetLine(_text);
    final extra =
        done && parsed != null && (parsed.note != null || parsed.count > 1);
    // 연 뒤로 한 글자도 안 바꿨으면 아무것도 쓰지 않는다. 그사이 같이 고치는
    // 사람이 이 칸을 바꿨다면, 내가 열 때의 값으로 되돌리면 안 된다.
    // (쳤다가 원래대로 되돌린 것은 고친 것이다 — 중간 값이 남아 있다.)
    if (_text == _recordStartText && !_recordTouched && !extra) return true;
    _recordTouched = true;
    if (_recordTitle) {
      final name = _text.trim();
      if (name.isEmpty || name.length > 120 || name.contains('\n')) {
        return false;
      }
      if (_c.blocks[_c.activeIndex].name != name) {
        _c.renameBlock(_c.activeIndex, name, learn: false);
      }
      return true;
    }
    final index = _recordSet!;
    if (index >= _c.blocks[_c.activeIndex].sets.length) return false;
    if (parsed == null) {
      final original = _recordOriginal;
      if (original != null) _c.updateSet(_c.activeIndex, index, original);
      return false;
    }
    final previous = _c.blocks[_c.activeIndex].sets[index];
    if (previous.value != parsed.value ||
        previous.reps != parsed.reps ||
        previous.unit != (parsed.unit ?? previous.unit)) {
      _c.updateSet(
        _c.activeIndex,
        index,
        LoggedSet(
          value: parsed.value,
          unit: parsed.unit ?? previous.unit,
          reps: parsed.reps,
        ),
      );
    }
    if (extra) {
      _c.extendSet(
        _c.activeIndex,
        index,
        note: parsed.note,
        count: parsed.count,
      );
    }
    return true;
  }

  /// [validate] 가 false 면(세트·운동을 지울 때) 못 읽는 글이어도 끝낸다. 읽히는
  /// 줄의 메모·xN 은 그래도 적용한다 — 조용히 버리지 않는다.
  bool _finishRecordEdit({bool validate = true}) {
    if (!_editingRecord) return true;
    if (!_applyRecordEdit(done: true) && validate) {
      if (!_recordTitle) setState(() => _invalidSet = true);
      return false;
    }
    if (_recordTitle && validate && _text != _recordStartText) {
      _c.renameBlock(_c.activeIndex, _text);
    }
    final resume = _resume ?? const EditorDraft(text: '');
    _recordTitle = false;
    _recordSet = null;
    _resume = null;
    _restoreDraft(resume);
    setState(() {});
    _saveDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reopen();
    });
    return true;
  }

  /// 닫힌 카드를 눌렀을 때. 커서를 그 카드로 옮기고 입력칸을 비운다 —
  /// 치던 글자가 다른 운동으로 딸려 가면 안 된다.
  void _openBlock(int index) {
    if (_editingRecord && !_finishRecordEdit()) return;
    widget.mealText?.value = null;
    if (_wantText) {
      _commit();
      if (_wantText) return;
    }
    // 치던 운동 이름(답을 기다리던 문장까지)은 버리지 않는다. 그 카드를 끝내고
    // 나오면 입력칸으로 돌아온다(X12).
    if (_c.naming && _text.trim().isNotEmpty) {
      _resume = EditorDraft(text: _text, resume: _resume);
    }
    _input.clear();
    setState(() {
      _wantText = false;
      _editing = null;
      _invalidSet = false;
      _setDraft = null;
    });
    _c.openBlock(index);
    _reopen();
  }

  /// 끌고 있는 운동. 끄는 사이 같이 고치는 사람이 순서를 바꾸면 번호가 다른
  /// 운동을 가리킨다 — 옮길 때 이것으로 다시 찾는다.
  ExerciseBlock? _dragged;

  void _moveBlock(int from, int to) {
    final dragged = _dragged;
    _dragged = null;
    if (dragged != null) {
      final at = _c.blocks.indexOf(dragged);
      if (at < 0) return;
      from = at;
    }
    final editing = _editing;
    final block = editing == null ? null : _c.blocks[editing.$1];
    if (editing != null) {
      final destination = to;
      final oldIndex = editing.$1;
      final nextIndex = oldIndex == from
          ? destination
          : from < oldIndex && destination >= oldIndex
          ? oldIndex - 1
          : from > oldIndex && destination <= oldIndex
          ? oldIndex + 1
          : oldIndex;
      _editing = (nextIndex, editing.$2, editing.$3);
    }
    _c.moveBlock(from, to);
    assert(block == null || identical(_c.blocks[_editing!.$1], block));
  }

  Future<Offset?> _prepareReorder(ExerciseBlock block, Offset pointer) async {
    _workoutTimer.pause();
    if (_editingRecord && !_finishRecordEdit()) return null;
    if (!mounted || _reordering) return null;
    final index = _c.blocks.indexOf(block);
    if (index < 0) return null;
    _dragged = block;
    _restoreFocus = _focus.hasFocus;
    _focus.unfocus();
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    final headerHeight = _headerKey.currentContext?.size?.height ?? 0;
    final top = listBox?.localToGlobal(Offset.zero).dy ?? 0;
    setState(() => _reordering = true);
    if (_scroll.hasClients) {
      final offset = (16 + headerHeight + index * 72 - (pointer.dy - top - 22))
          .clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.jumpTo(offset);
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_reordering) return null;
    final box =
        _handleKeys[block]?.currentContext?.findRenderObject() as RenderBox?;
    return box?.localToGlobal(const Offset(18, 22));
  }

  void _finishReorder() {
    if (!mounted || !_reordering) return;
    setState(() => _reordering = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _restoreFocus) _focus.requestFocus();
    });
  }

  /// 같이 고치는 중에는 내가 고치던 세트 앞에 남이 세트를 넣거나 지울 수 있다.
  /// 번호가 아니라 그 세트를 따라간다. 세트가 사라졌으면 고치기를 그만둔다.
  void _followEditedSet() {
    // 이름을 고치던 운동이 지워졌다. 고치기를 그만둔다 — 남아 있으면 편집기가 막힌다.
    if (_recordTitle && !_c.inBlock) {
      _recordTitle = false;
      _input.clear();
    }
    final editing = _editing, id = _editingSetId;
    if (editing != null && id != null) {
      final (b, st, n) = editing;
      final block = _c.blocks.indexWhere((x) => x.sets.any((s) => s.id == id));
      final set = block < 0
          ? -1
          : _c.blocks[block].sets.indexWhere((s) => s.id == id);
      if (set < 0 || n >= _c.blocks[block].sets[set].notes.length) {
        // 메모가 달린 세트나 그 메모가 사라졌다. 쓰던 글을 다른 세트에 붙이지 않는다.
        _editing = null;
        _editingSetId = null;
        _wantText = false;
        _input.clear();
      } else if (block != b || set != st) {
        _editing = (block, set, n);
      }
    }
    final original = _recordOriginal, at = _recordSet;
    if (original == null || at == null) return;
    final now = _c.inBlock
        ? _c.blocks[_c.activeIndex].sets.indexWhere((s) => s.id == original.id)
        : -1;
    if (now == at) return;
    if (now >= 0) {
      _recordSet = now;
    } else {
      _recordSet = null;
      _recordOriginal = null;
      _input.clear();
    }
  }

  void _tellPresence() {
    final tell = widget.onPresence;
    if (tell == null) return;
    final block = _c.inBlock ? _c.blocks[_c.activeIndex] : null;
    final set = _recordSet;
    tell(
      block?.id,
      block == null || _recordTitle
          ? null
          // 메모를 고치는 중이면 그 메모가 달린 세트다.
          : _editing != null
          ? _editingSetId
          : _wantText
          ? null
          : set != null && set < block.sets.length
          ? block.sets[set].id
          : '+',
      // 식단과 메모는 같이 고치는 기록이 아니다. 치는 글을 보내지 않는다.
      _mealMode || _wantText || _recordTitle ? '' : _text,
    );
  }

  void _onInput() {
    _syncSentinel();
    if (_editingRecord) _applyRecordEdit();
    _tellPresence();
    if (_aiBusy && _text != _submittedText) {
      _aiRequest++;
      widget.ai.cancel();
      _aiBusy = false;
    }
    final has = _text.trim().isNotEmpty;
    if (mounted) {
      setState(() {
        _hasInput = has;
        _invalidSet = false;
        // 남긴 한 줄은 다음에 무언가 칠 때까지 둔다. 입력칸을 비우는 것으로는
        // 지우지 않는다 — 칸을 만들며 비우는 바로 그때 보여야 한다.
        if (has) _aiNotice = null;
      });
    }
    _saveDraft();
  }

  void _saveDraft() {
    widget.onDraftChanged?.call(
      _text.isEmpty && _setDraft == null && _resume == null && !_editingRecord
          ? null
          : _draft,
    );
  }

  @override
  void dispose() {
    // 이 편집기를 떠난다(대신 적기로 넘어가거나 화면을 닫는다). 내 커서를 거둔다.
    widget.onPresence?.call(null, null, '');
    WidgetsBinding.instance.removeObserver(this);
    _aiRequest++;
    widget.ai.cancel();
    widget.mealText?.removeListener(_onMealRequest);
    _c.removeListener(_onChanged);
    _input.removeListener(_onInput);
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    widget.partner?.removeListener(_followShared);
    _workoutTimer.removeListener(_followTimer);
    // 밖에서 받은 것은 밖에서 버린다.
    if (widget.timer == null) _workoutTimer.dispose();
    _recovery.removeListener(_followHeart);
    // 밖에서 받은 것은 밖에서 버린다.
    if (widget.recovery == null) _recovery.dispose();
    super.dispose();
  }

  /// 세트를 받는 중이면 시스템 키보드가 있을 자리가 없다 — 키패드가 그 자리다.
  bool get _padMode => _c.inBlock && !_wantText && !_recordTitle;

  /// 화면에 놓인 줄 수. 이것이 늘었을 때만 따라 내린다.
  int get _lineCount =>
      _c.blocks.length +
      _c.blocks.fold(
        0,
        (n, b) =>
            n + b.sets.length + b.sets.fold(0, (m, s) => m + s.notes.length),
      );
  int _lastLineCount = 0;

  void _onChanged() {
    final timed = _workoutTimer.owner;
    // 같이 하는 중에는 도는 설정이 제목과 다를 수 있다(교대는 휴식이 길다).
    // 제목과 견줄 것은 둘이 정한 설정이다.
    final agreed = _workoutTimer.shared ? _shared?.spec : _workoutTimer.spec;
    if (timed is ExerciseBlock &&
        (!_c.blocks.contains(timed) ||
            TimingSpec.parse(timed.name) != agreed)) {
      // 같이 돌리던 칸을 지웠거나 이름을 바꿨다. 말없이 사라지지 않고 빠진다고 알린다.
      if (_workoutTimer.shared && _workoutTimer.running) _leaveShared();
      _workoutTimer.clear();
    }
    // 제안해 놓고 그 칸을 지웠거나 설정을 바꿨다. 상대가 받아도 돌릴 칸이 없으니 거둔다.
    final offered = _shared;
    if (offered != null &&
        offered.mine &&
        !offered.started &&
        _blockFor(offered) == null) {
      widget.partner!.clearTimer();
    }
    _followEditedSet();
    _saveDraft();
    _syncSentinel();
    _tellPresence();
    if (mounted) setState(() {});
    // keyboardType 을 바꾸는 것만으로는 **이미 올라와 있는** 키보드가 내려가지
    // 않는다. 운동 이름을 칠 때 뜬 키보드가 세트 모드에서도 그대로 남아
    // 키패드를 덮었다.
    if (_padMode) SystemChannels.textInput.invokeMethod('TextInput.hide');

    // 줄이 늘었을 때만 따라 내린다. 예전에는 컨트롤러가 바뀔 때마다 무조건
    // 맨 아래로 내렸는데, 세트를 켜고 끄거나 메모를 고칠 때도 화면이 출렁였다.
    // 키패드가 뜨고 지면서 뷰포트 높이가 바뀌면 그때마다 또 움직였다.
    // 남이 줄을 더했을 때는 따라 내리지 않는다 — 위를 보던 사람을 끌어내린다.
    final grew = _lineCount > _lastLineCount && !_c.remote;
    _lastLineCount = _lineCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 자리를 옮긴 뒤에도 계속 칠 수 있어야 한다.
      if (mounted &&
          !_reordering &&
          !_timingKeyboardHidden &&
          !_focus.hasFocus) {
        _focus.requestFocus();
      }
      if (!grew) return;
      final ctx = _inputKey.currentContext;
      if (ctx == null) return;

      // **맨 아래로 던지지 않는다.** 치는 자리가 보일 만큼만 움직인다.
      //
      // maxScrollExtent 로 내리던 것을 바꿨다. 운동 이름을 넣는 순간에는
      // 시스템 키보드가 내려가고 키패드가 올라오는데, 그 도중에 재면 뷰포트가
      // 실제보다 좁아 maxScrollExtent 가 크게 나온다. 그 값으로 던지면 앞의
      // 카드가 화면 위로 사라졌다가, 레이아웃이 자리를 잡으면 되돌아온다 —
      // 화면이 튀는 것이 이것이었다. ensureVisible 은 모자란 만큼만 움직이므로
      // 도중에 재도 넘치지 않는다.
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  void _dismissTextKeyboard() {
    // 고치던 세트·이름이 있으면 빈 곳을 누른 것은 "됐다" 다 — 고친 것은 남기고
    // 선택을 푼다. 값이 틀리면 풀지 않고 그 자리에 남긴다.
    if (_editingRecord) {
      _finishRecordEdit();
      return;
    }
    if (_padMode) {
      // 키패드도 내릴 수 있어야 한다 — 내리면 그날 기록 전체가 다시 보인다.
      // 입력 줄이나 세트 칸을 누르면 _reopen 이 다시 올린다.
      if (!_timingKeyboardHidden) setState(() => _timingKeyboardHidden = true);
      return;
    }
    if (!_focus.hasFocus) _focus.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    if (!_textKeyboardHidden) setState(() => _textKeyboardHidden = true);
  }

  /// 입력 줄이 가려졌을 때만, 모자란 만큼만 움직인다. 그냥 ensureVisible 은
  /// 입력 줄을 화면 맨 위로 끌어올려 고치는 운동의 이름과 칸을 밀어냈다.
  void _showInput() {
    final ctx = _inputKey.currentContext;
    if (ctx == null) return;
    for (final policy in const [
      ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    ]) {
      Scrollable.ensureVisible(ctx, alignmentPolicy: policy);
    }
  }

  /// 포커스를 쥔 채 키보드만 내려간 경우 입력 연결을 직접 다시 연다.
  void _reopen() {
    if (_timingKeyboardHidden) setState(() => _timingKeyboardHidden = false);
    if (_textKeyboardHidden) setState(() => _textKeyboardHidden = false);
    if (!_focus.hasFocus) {
      _focus.requestFocus();
    } else if (!_padMode) {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  Future<void> _forgetExercise(String name) async {
    final forget = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(name),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(L.of(context).delete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, false),
          child: Text(L.of(context).cancel),
        ),
      ),
    );
    if (forget != true || !mounted) return;
    _c.forgetExercise(name);
    widget.onForgetExercise?.call(name);
  }

  List<String> get _matches => _mealMode
      ? widget.recentMeals
            .where((m) => m.contains(_text.trim()) && m != _text.trim())
            .take(6)
            .toList()
      : !_c.naming
      ? const []
      : _text.trim().isEmpty
      ? _c.recentExercises.take(6).toList()
      : suggest(_text, _c.vocabulary(_lang), preferred: _c.recentExercises);

  /// 사전에서 어느 언어의 이름을 낼지. 검색은 언어를 가리지 않는다.
  String get _lang {
    final locale = Localizations.localeOf(context);
    return langKeyOf(
      locale.languageCode,
      locale.scriptCode,
      locale.countryCode,
    );
  }

  void _commit([String? pick]) {
    if (_editingRecord) {
      _finishRecordEdit();
      return;
    }
    final value = pick ?? _text;
    if (_mealMode) {
      // 식단은 묻지 않고 그대로 저장한다 — 모르는 음식도, 양이 없는 글도.
      final index = widget.mealText!.value!.index;
      if (value.trim().isNotEmpty || index != null) {
        widget.onMealText?.call(value.trim(), index);
      }
      widget.mealText!.value = null;
      return;
    }
    // 타이머 이름("버피 타바타 30/15 10라운드")은 묻지 않고 바로 만든다 — 글의
    // 수가 모두 타이머 토큰에 쓰였을 때다. "bpm 푸시업 100개 채우기" 처럼 다른
    // 수가 든 문장은 해석을 거친다 — 제목에 bpm 이 남으니 타이머는 그대로 붙고,
    // 100개 채우기는 설정으로 붙는다.
    final timerOnly =
        TimingSpec.parse(value) != null &&
        !hasSetupIntent(value.replaceAll(timerTokens, ' '));
    // 수 없는 이름과 타이머 이름은 제목이 되므로 120자까지다. 글은 입력칸에 둔다.
    if (pick == null &&
        _c.naming &&
        value.trim().length > 120 &&
        (timerOnly || !hasSetupIntent(value))) {
      setState(() => _aiNotice = (l) => l.inputNameTooLong);
      return;
    }
    if (_c.naming && timerOnly) {
      _input.clear();
      _c.addExercise(value.trim());
      _reopen();
      return;
    }
    if (pick == null &&
        _c.naming &&
        value.trim().isNotEmpty &&
        !hasSetupIntent(value)) {
      _commit(value);
      return;
    }
    // 설정을 붙여 만든 칸과 똑같은 줄(어제의 '벤치 80kg 5x5')은 그 설정을 다시
    // 쓴다 — 다시 묻지 않고, 설정 없이 만들지도 않는다. 익힌 이름만 같은 줄은
    // 아니다: 제목에서 익힌 이름이 수를 품었어도 모델이 읽는다.
    if (pick == null && _c.naming) {
      if (_c.earlierSetup(value.trim()) case final setup?) {
        _input.clear();
        _c.addExercise(value.trim(), setup: setup, learnAs: setup.name);
        _reopen();
        return;
      }
    }
    // 물어보고 안 되면 그때 알린다. 미리 상태를 확인하느라 기다리지 않는다.
    if (pick == null && _c.naming && value.trim().isNotEmpty) {
      _interpret(value);
      return;
    }
    final editing = _editing;
    // 메모 모드에서 친 것은 마지막 세트의 메모다. 그냥 넘기면 숫자가 없는
    // 줄이라 파서가 새 운동 이름으로 읽어 버린다.
    final memo =
        pick == null && (editing != null || (_wantText && _c.lastSet != null));
    final wasText = _wantText;
    // Text entered inside an exercise must never become another exercise name.
    if (pick == null &&
        _c.inBlock &&
        !memo &&
        value.trim().isNotEmpty &&
        parseSetLine(value) == null) {
      setState(() => _invalidSet = true);
      return;
    }

    // **모드를 먼저 되돌린다.** 컨트롤러를 먼저 건드리면 _onChanged 가 아직
    // 메모 모드인 줄 알고 시스템 키보드를 안 내린다. 그 상태에서 키패드가
    // 올라와 둘이 겹치고, iOS 가 뒤늦게 키보드를 내리면서 화면이 튄다.
    _input.clear();
    setState(() {
      _highlight = -1;
      _wantText = false;
      _editing = null;
      _invalidSet = false;
    });
    // 빈 메모처럼 컨트롤러가 알림을 안 보내는 경우도 있으므로 여기서 직접
    // 내린다 — 옆 효과에 기대지 않는다.
    if (wasText) SystemChannels.textInput.invokeMethod('TextInput.hide');

    if (memo) {
      if (editing != null) {
        final (b, st, n) = editing;
        _c.editNote(b, st, n, value);
      } else {
        _c.noteLastSet(value);
      }
      if (_setDraft != null) _input.value = _setDraft!;
      _setDraft = null;
    } else if (!wasText || value.trim().isNotEmpty) {
      _c.commit(value);
      _resumeElsewhere();
    }
    _saveDraft();
    _focus.requestFocus();
  }

  /// 저장된 세트를 고치다가 "세트 추가" — 고친 값을 저장하고 같은 운동의
  /// **새 세트 자리**로 간다. 새 세트는 거기서 확정해야 생긴다. "완료" 는
  /// 편집을 끝내고 있던 자리로 돌아가므로 둘은 다른 일을 한다.
  void _addSetAfterEdit() {
    if (!_applyRecordEdit(done: true)) {
      setState(() => _invalidSet = true);
      return;
    }
    // 같은 운동의 새 세트 줄에 치던 글이 있었으면 그것을 잇는다. 다른 자리에
    // 치던 글(반쯤 친 운동 이름, 다른 운동의 세트 줄)은 **버리지 않고 들고
    // 있다가** 이 운동을 끝내고 나갈 때 그 자리로 돌려놓는다 — 초안에도 같이
    // 저장되므로 앱이 죽어도 남는다.
    final resume = _resume;
    final here =
        resume != null &&
        (resume.blockId != null && _c.inBlock
            ? resume.blockId == _c.blocks[_c.activeIndex].id
            : resume.block == _c.activeIndex) &&
        !resume.memo;
    final pending = here ? resume.text : '';
    _recordSet = null;
    if (here) _resume = resume.resume;
    _input.value = TextEditingValue(
      text: pending,
      selection: TextSelection.collapsed(offset: pending.length),
    );
    setState(() => _invalidSet = false);
    _saveDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reopen();
      _showInput();
    });
  }

  /// 운동을 끝내고 나왔는데 들고 있던 초안이 있으면 그 자리로 돌아간다.
  void _resumeElsewhere() {
    final resume = _resume;
    if (resume == null || !_c.naming || _editingRecord) return;
    _resume = null;
    _restoreDraft(resume);
    setState(() {});
  }

  void _nextSet() {
    if (_editingRecord) {
      _finishRecordEdit();
      return;
    }
    final text = _text.trimRight();
    if (!(_setup?.countsReps ?? false) &&
        text.isNotEmpty &&
        !text.contains(' ')) {
      _insert(' ');
      return;
    }
    _commit();
  }

  /// 키패드가 커서 자리에 글자를 넣는다.
  void _insert(String text) {
    final v = _input.value;
    final start = v.selection.start < 0 ? v.text.length : v.selection.start;
    final end = v.selection.end < 0 ? v.text.length : v.selection.end;
    final next = v.text.replaceRange(start, end, text);
    _input.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    setState(() {});
  }

  /// 빈 자리에서 지우기 — 메모장의 빈 줄에서 지우기가 앞줄 끝으로 가는 것.
  ///
  /// 키패드·물리 키보드·화면 키보드가 모두 여기로 온다. **저장된 세트를 지우지
  /// 않는다.** 직전 세트를 입력칸으로 불러 커서를 끝에 둘 뿐이고, 그 뒤에 치는
  /// 것은 그 세트를 고친다. 세트를 지우는 것은 그 줄의 × 다.
  void _backspaceOnEmpty() {
    if (_mealMode) {
      // 빈 식단 줄에서 지우기는 식단 적기를 접는 것이다 — 고치던 끼니가 아니면
      // 마지막 세트로 돌아간다. 운동 이름 줄에서와 같은 손놀림이다.
      if (widget.mealText!.value!.index != null) return;
      widget.mealText!.value = null;
    }
    if (_editingRecord || _wantText || _c.blocks.isEmpty) return;
    // 세트가 없는 운동 안에서는 운동 자체를 뗀다. 지우기 버튼과 같은
    // 결과이므로 같은 것을 묻는다.
    if (_c.backspaceRemovesBlock) {
      final block = _c.blocks[_c.activeIndex];
      confirmRemoveExercise(
        context,
        block,
        busy: widget.presence
            .where((p) => p.block == block.id)
            .firstOrNull
            ?.name,
      ).then((yes) {
        if (!yes || !mounted) return;
        // 확인창이 떠 있는 사이 문서가 바뀌었을 수 있다. 물어본 그 운동을 지운다.
        if (_c.inBlock && identical(_c.blocks[_c.activeIndex], block)) {
          _c.backspace();
        } else {
          _c.removeBlockObject(block);
        }
        _resumeElsewhere();
      });
      return;
    }
    final block = _c.inBlock ? _c.blocks[_c.activeIndex] : _c.lastClosed!;
    if (block.sets.isEmpty) {
      _c.backspace();
      return;
    }
    // 돌아갈 곳은 **내** 마지막 세트다. 남이 고치는 중이면 잡지 않는다.
    final mine = block.sets.lastIndexWhere((s) => s.author == null);
    final at = mine < 0 ? block.sets.length - 1 : mine;
    final busy = _busyOn(block, block.sets[at]);
    if (busy != null) {
      unawaited(_say(L.of(context).liveSetBusy(busy)));
      return;
    }
    _beginRecordEdit(block, at, selectAll: false);
  }

  /// 이 세트를 지금 고치고 있는 다른 사람의 이름.
  String? _busyOn(ExerciseBlock block, LoggedSet set) => widget.presence
      .where((p) => p.block == block.id && p.set == set.id)
      .firstOrNull
      ?.name;

  void _keypadBackspace() {
    final v = _input.value;
    if (v.text.isEmpty) {
      _backspaceOnEmpty();
      return;
    }
    // 고른 글이 있으면 그것을, 없으면 커서 앞 한 글자를 지운다.
    final end = v.selection.end < 0 ? v.text.length : v.selection.end;
    final start = v.selection.isCollapsed || v.selection.start < 0
        ? end - 1
        : v.selection.start;
    if (start < 0) return;
    final next = v.text.replaceRange(start, end, '');
    _input.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start),
    );
    setState(() {});
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace && _text.isEmpty) {
      _backspaceOnEmpty();
      return KeyEventResult.handled;
    }
    final matches = _matches;
    if (matches.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _highlight = (_highlight + 1) % matches.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(
        () => _highlight =
            ((_highlight < 0 ? 0 : _highlight) - 1 + matches.length) %
            matches.length,
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final blocks = _c.blocks;
    // 커서가 든 카드가 입력 줄을 품는다.
    final openIndex = _c.activeIndex;

    // 읽어 줄지와 어느 말로 읽을지는 화면이 정한다 — 타이머는 소리만 낸다.
    _workoutTimer
      ..countAloud = widget.countAloud
      ..voiceLocale = Localizations.localeOf(context).toLanguageTag()
      ..announceRound = L.of(context).timingRoundDone;
    final incoming = _shared;
    return Column(
      children: [
        // 상대가 같이 하자고 했다. 목록과 함께 흘러가지 않게 맨 위에 붙여 둔다 —
        // 받아야 시작하는데 안 보이면 상대는 하염없이 기다린다.
        // 이미 시작한 것에도 들어갈 수 있다(돌고 있는 시계에 들어선다). 교대는 둘의
        // 것이라 시작한 뒤에는 자리가 없다.
        if (incoming != null &&
            !incoming.joined &&
            !(incoming.started && incoming.alternate) &&
            !incoming.overAt(widget.partner!.clock.now))
          _TogetherInvite(
            name: widget.partner!.session!.partnerName ?? '',
            timer: incoming,
            onAccept: _acceptShared,
            onDecline: widget.partner!.clearTimer,
          ),
        Expanded(
          child: GestureDetector(
            // 빈 곳을 눌러도 커서를 잃지 않는다.
            onTap: _dismissTextKeyboard,
            behavior: HitTestBehavior.opaque,
            child: CustomScrollView(
              key: _listKey,
              controller: _scroll,
              slivers: [
                SliverPadding(
                  // 옆 여백은 16 — 24 였을 때는 "62.5×10" 다섯 칸이 한 줄에 안 들어갔다.
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      if (widget.header != null)
                        SliverToBoxAdapter(
                          child: KeyedSubtree(
                            key: _headerKey,
                            child: widget.header!,
                          ),
                        ),
                      SliverReorderableList(
                        itemCount: blocks.length,
                        onReorderItem: _moveBlock,
                        proxyDecorator: (child, index, animation) =>
                            ReorderProxy(
                              onRemoved: _finishReorder,
                              child: ColoredBox(
                                color: CupertinoColors.systemBackground
                                    .resolveFrom(context),
                                child: child,
                              ),
                            ),
                        itemBuilder: (context, i) => _BlockView(
                          key: ObjectKey(blocks[i]),
                          collapsed: _reordering,
                          onEditTitle: () => _editTitle(blocks[i]),
                          onEditSet: (set) => _editSet(blocks[i], set),
                          dragHandle: CollapsingDragStartListener(
                            index: i,
                            prepare: (pointer) =>
                                _prepareReorder(blocks[i], pointer),
                            onCanceled: _finishReorder,
                            child: Semantics(
                              label: L.of(context).moveExercise,
                              child: SizedBox(
                                key: _handleKeys.putIfAbsent(
                                  blocks[i],
                                  GlobalKey.new,
                                ),
                                width: 36,
                                height: _reordering ? 44 : 28,
                                child: const Icon(
                                  CupertinoIcons.line_horizontal_3,
                                  size: 18,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ),
                          ),
                          block: blocks[i],
                          timing: TimingSpec.parse(blocks[i].name) == null
                              ? null
                              : WorkoutTimingControls(
                                  owner: blocks[i],
                                  spec: TimingSpec.parse(blocks[i].name)!,
                                  timer: _workoutTimer,
                                  recovery: _recovery,
                                  together: _togetherFor(
                                    blocks[i],
                                    L.of(context),
                                  ),
                                  onStart: () {
                                    _focus.unfocus();
                                    SystemChannels.textInput.invokeMethod(
                                      'TextInput.hide',
                                    );
                                    setState(
                                      () => _timingKeyboardHidden = true,
                                    );
                                  },
                                  // 설정을 따로 저장하지 않는다. 제목을 다시
                                  // 적으면 글로 고친 것과 같은 자리가 바뀐다.
                                  onChanged: (next) => _c.renameBlock(
                                    i,
                                    next.applyTo(blocks[i].name),
                                    learn: false,
                                  ),
                                ),
                          titleInput:
                              i == openIndex && _recordTitle && !_reordering
                              ? _buildInput(bold: true)
                              : null,
                          editingSet: i == openIndex ? _recordSet : null,
                          input: i == openIndex && !_reordering && !_recordTitle
                              ? _buildInput()
                              : null,
                          inputSet: _editing?.$2 ?? blocks[i].sets.length - 1,
                          isMemo: _wantText,
                          onToggle: (set) => _c.toggleDone(i, set),
                          // 고치던 세트를 지운다. 줄에 같이 친 메모·xN 은 먼저
                          // 적용한다 — "x3" 이면 그 사본은 남는다.
                          onRemoveSet: (set) {
                            _finishRecordEdit(validate: false);
                            _c.removeSet(i, set);
                          },
                          onRemoveBlock: (block) {
                            // 다른 운동을 지우면 고치던 줄은 평소처럼 확정한다 —
                            // 못 읽는 글이면 입력칸에 이유와 함께 남는다.
                            _finishRecordEdit(validate: i != openIndex);
                            _c.removeBlockObject(block);
                            _resumeElsewhere();
                          },
                          onEditNote: (set, note) =>
                              _startEditNote(i, set, note),
                          onRemoveNote: (set, note) =>
                              _c.removeNote(i, set, note),
                          onEditSetup: () => _editSetup(i),
                          uniformCell: widestSetCell(context, blocks),
                          cursors: [
                            for (final p in widget.presence)
                              if (p.block == blocks[i].id) p,
                          ],
                          // 열려 있는 카드는 이미 거기다 — 누를 것이 없다.
                          onOpen: i == openIndex ? null : () => _openBlock(i),
                        ),
                      ),
                      if (_c.naming)
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInput(bold: true),
                              for (final p in widget.presence)
                                if (p.block == null && p.text.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      p.text,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: cursorColor(p.name),
                                      ),
                                    ),
                                  ),
                              // 물어보는 중일 때만 한 줄. 준비 상태 같은 것은
                              // 이제 없다 — 서버에 물어보면 되거나 안 되거나다.
                              if (_aiBusy)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    L.of(context).aiWorking,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: CupertinoColors.secondaryLabel
                                          .resolveFrom(context),
                                    ),
                                  ),
                                ),
                              ?_noticeLine(context),
                            ],
                          ),
                        ),
                      // 적은 그대로 만든 칸 바로 아래 — 왜 설정이 없는지.
                      if (!_c.naming && _aiNotice != null)
                        SliverToBoxAdapter(child: _noticeLine(context)),
                      if (widget.footer != null)
                        SliverToBoxAdapter(child: widget.footer!),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if ((matches.isNotEmpty ||
                widget.onMealPhoto != null ||
                widget.mealText != null) &&
            !_textKeyboardHidden)
          _Suggestions(
            matches: matches,
            highlight: _highlight,
            onPick: (name) => _commit(name),
            onForget: _forgetExercise,
            onMealPhoto: widget.onMealPhoto,
            mealMode: _mealMode,
            // 운동 이름을 적는 바로 그 줄에 음식을 쳤다면, 한 번 눌러 끼니로 남긴다.
            // 앱이 알아서 가르지 않는다 — "케이블 크런치" 를 과자로 읽으면 기록이
            // 바뀐다. 사람이 누른다.
            onLogAsMeal:
                !_mealMode &&
                    _c.naming &&
                    !_editingRecord &&
                    widget.onMealText != null &&
                    _text.trim().isNotEmpty
                ? () {
                    final text = _text.trim();
                    _input.clear();
                    widget.onMealText!(text, null);
                  }
                : null,
            onMealText: widget.mealText == null
                ? null
                : () => widget.mealText!.value = _mealMode
                      ? null
                      : (text: '', index: null),
          ),
        // Both keyboards share one bottom area. Keep the keypad anchored while
        // the system inset shrinks; only text mode needs space above the IME.
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: _padMode ? 0 : MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: _timingKeyboardHidden
                  ? const SizedBox.shrink()
                  : _padMode
                  ? SetKeypad(
                      onKey: _insert,
                      onBackspace: _keypadBackspace,
                      onAddSet: parseSetLine(_text) == null
                          ? null
                          : _recordSet != null
                          ? _addSetAfterEdit
                          : () => _commit(),
                      onSubmit: _nextSet,
                      submitLabel: _recordSet != null
                          ? L.of(context).doneEditing
                          : _hasInput
                          ? L.of(context).next
                          : L.of(context).finishExercise,
                      onText: () {
                        if (_editingRecord && !_finishRecordEdit()) return;
                        // 글자판으로 넘어가는 것은 곧 메모를 적겠다는 뜻이다. 이 화면에
                        // 글자가 필요한 자리는 거기뿐이다 — 운동 이름은 카드 밖에서
                        // 치고 그때는 애초에 키패드가 안 뜬다.
                        if (_c.lastSet != null) {
                          _setDraft = _input.value;
                          _input.clear();
                        }
                        setState(() => _wantText = true);
                        // 읽기 전용이 풀린 뒤라야 키보드가 글자판으로 열린다.
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _reopen(),
                        );
                      },
                      onAdjust: (direction) {
                        final next = bumpLastNumber(_text, direction);
                        _input.value = TextEditingValue(
                          text: next,
                          selection: TextSelection.collapsed(
                            offset: next.length,
                          ),
                        );
                        setState(() {});
                      },
                      // 무게를 치는 중이면 원판 단위, kg 를 지나 횟수를 치는 중이면 하나.
                      // 무엇의 2.5 인지 보여야 한다. 횟수를 치는 중이면 단위가 없으므로
                      // 숫자만 낸다 — "1회" 는 늘 1이라 붙일 값이 없다.
                      stepLabel: _typingReps
                          ? formatNumber(_stepSize)
                          : formatValue(_stepSize, _unit),
                      onStepPick: _pickStep,
                      repeatLabel: _c.lastSet == null
                          ? null
                          : setLabel(
                              value: _c.lastSet!.value,
                              unit: _c.lastSet!.unit,
                              reps: _c.lastSet!.reps,
                              formatReps: L.of(context).repsCount,
                            ),
                      onRepeat: _recordSet != null ? null : _c.repeatLastSet,
                    )
                  // 메모를 치는 동안에도 돌아올 문은 열어 둔다.
                  : (_c.inBlock && _wantText && !_recordTitle)
                  ? ColoredBox(
                      color: keypadBackground.resolveFrom(context),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          height: 44,
                          width: double.infinity,
                          child: Row(
                            children: [
                              Expanded(
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _commit(),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.keyboard,
                                        size: 19,
                                        color: seal.resolveFrom(context),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        L.of(context).numberKeypad,
                                        style: TextStyle(
                                          fontSize: 17,
                                          letterSpacing: -0.41,
                                          color: seal.resolveFrom(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SafeArea(
                      top: false,
                      child: SizedBox(width: double.infinity),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInput({bool bold = false}) {
    final platform = defaultTargetPlatform;
    final touch =
        platform == TargetPlatform.iOS || platform == TargetPlatform.android;
    final readOnly = touch && !bold && !_wantText && _c.inBlock;
    final hint = _mealMode
        ? L.of(context).mealTextHint
        : bold
        ? L.of(context).exerciseNameHint
        : _wantText && _c.lastSet != null
        ? L.of(context).noteHint
        : (_setup?.countsReps ?? false)
        ? L.of(context).repsInputHint
        : L.of(context).setInputHint;
    final hintStyle = TextStyle(
      fontSize: 17,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
      color: CupertinoColors.placeholderText.resolveFrom(context),
    );

    return Focus(
      key: _inputKey,
      onKeyEvent: _onKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // 심어 둔 글자 때문에 칸이 "비어 있지 않아" 안내문이 사라진다.
              // 그때는 같은 자리에 직접 그린다.
              if (_input.text == _zw)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(hint, style: hintStyle),
                    ),
                  ),
                ),
              CupertinoTextField(
                // iOS 자동 고침과 예측 막대를 끈다. "랫풀다운" 을 멋대로 고치는 것을
                // 막고, 예측 막대가 프레임마다 뱉던 NSLayoutConstraint 경고도 같이
                // 사라진다 — 그 경고는 iOS 키보드의 것이지 우리 것이 아니다.
                autocorrect: false,
                enableSuggestions: false,
                controller: _input,
                focusNode: _focus,
                autofocus: true,
                readOnly: readOnly,
                showCursor: !_padMode,
                keyboardType: readOnly
                    ? TextInputType.none
                    : _wantText
                    ? TextInputType.multiline
                    : TextInputType.text,
                textInputAction: TextInputAction.done,
                minLines: _wantText ? 2 : 1,
                maxLines: _wantText ? null : 1,
                onTap: _reopen,
                onSubmitted: (_) => _commit(
                  _highlight >= 0 &&
                          _highlight < _matches.length &&
                          TimingSpec.parse(_text) == null
                      ? _matches[_highlight]
                      : null,
                ),
                onChanged: (_) => setState(() => _highlight = -1),
                inputFormatters: [
                  // 심어 둔 글자가 지워졌다 = 빈 자리에서 지우기를 눌렀다. 글자는
                  // 되돌려 두고(다음 지우기도 알아야 한다) 앞줄로 돌아간다.
                  TextInputFormatter.withFunction((before, after) {
                    final erased = before.text == _zw && after.text.isEmpty;
                    if (!erased) return after;
                    scheduleMicrotask(() {
                      if (mounted) _backspaceOnEmpty();
                    });
                    return before;
                  }),
                ],
                style: TextStyle(
                  fontSize: 17,
                  height: _wantText ? 1.5 : null,
                  letterSpacing: bold ? -0.41 : 0,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: CupertinoColors.label.resolveFrom(context),
                ),
                cursorColor: CupertinoColors.label.resolveFrom(context),
                decoration: const BoxDecoration(),
                padding: EdgeInsets.symmetric(vertical: bold ? 10 : 6),
                placeholder: _input.text == _zw ? null : hint,
                placeholderStyle: hintStyle,
              ),
            ],
          ),
          if (_invalidSet)
            Text(
              tooManySets(_text)
                  ? L.of(context).setsPerLineMax(maxSetsPerLine)
                  : L.of(context).setRequired,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({
    super.key,
    required this.dragHandle,
    this.collapsed = false,
    this.titleInput,
    this.timing,
    this.editingSet,
    required this.onEditTitle,
    required this.onEditSet,
    required this.block,
    this.input,
    required this.inputSet,
    required this.isMemo,
    required this.onToggle,
    required this.onRemoveSet,
    required this.onRemoveBlock,
    required this.onOpen,
    required this.onEditNote,
    required this.onRemoveNote,
    required this.onEditSetup,
    this.uniformCell,
    this.cursors = const [],
  });

  final ExerciseBlock block;

  /// 이 운동을 지금 만지는 다른 사람들.
  final List<PartnerPresence> cursors;
  final Widget dragHandle;
  final bool collapsed;
  final Widget? titleInput;
  final Widget? timing;
  final int? editingSet;
  final VoidCallback onEditTitle;
  final ValueChanged<int> onEditSet;

  /// 이 운동이 아직 세트를 받는 중이면 입력 줄이 카드 안에 들어온다.
  final Widget? input;
  final int inputSet;
  final bool isMemo;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onRemoveSet;
  final ValueChanged<ExerciseBlock> onRemoveBlock;

  /// (세트 번호, 메모 번호).
  final void Function(int, int) onEditNote;
  final void Function(int, int) onRemoveNote;
  final VoidCallback onEditSetup;

  /// 문서 전체에서 맞출 칸 폭.
  final double? uniformCell;

  /// 닫힌 카드를 눌러 그 운동을 다시 연다. 열려 있으면 null 이다.
  final VoidCallback? onOpen;

  Future<void> _confirmRemove(BuildContext context) async {
    if (await confirmRemoveExercise(
      context,
      block,
      busy: cursors.firstOrNull?.name,
    )) {
      onRemoveBlock(block);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: collapsed ? null : onOpen,
      behavior: HitTestBehavior.opaque,
      child: _card(context),
    );
  }

  Widget _card(BuildContext context) {
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final unit = sharedUnit(block);
    return Container(
      // 상자들이 제 여백을 가져서 카드 사이는 그만큼 좁혀도 된다 — 8종목 40세트가
      // 한 화면에 들어가는 밀도는 지킨다.
      margin: EdgeInsets.only(bottom: collapsed ? 16 : 6),
      padding: EdgeInsets.only(bottom: collapsed ? 12 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    titleInput ??
                    GestureDetector(
                      onTap: collapsed ? null : onEditTitle,
                      behavior: HitTestBehavior.opaque,
                      // 이름은 맨 글자다. 상자를 씌워 봤더니 줄마다 회색이라 지저분했다 —
                      // 눌러 고치는 것은 세트 칸의 테두리가 말해 준다.
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          block.name,
                          maxLines: collapsed ? 1 : null,
                          overflow: collapsed ? TextOverflow.ellipsis : null,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.41,
                          ),
                        ),
                      ),
                    ),
              ),
              // 여섯이 한 운동에 몰려도 제목을 밀어내지 않는다 — 둘까지 이름, 나머지는 수.
              for (final p in cursors.take(2)) _CursorTag(p),
              if (cursors.length > 2)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '+${cursors.length - 2}',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ),
              // 칸에서 뺀 단위를 여기 한 번 적는다.
              if (unit != null && !collapsed)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    unitById[unit]?.label ?? unit,
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ),
              dragHandle,
              // 설정 없는 칸도 나중에 설정을 붙인다. 있으면 아래 요약 줄을 누른다.
              if (!collapsed && block.setup == null)
                GestureDetector(
                  onTap: onEditSetup,
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    button: true,
                    label: L.of(context).setupAdd,
                    child: SizedBox(
                      width: 32,
                      height: 28,
                      child: Icon(
                        CupertinoIcons.gear_alt,
                        size: 17,
                        color: CupertinoColors.tertiaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ),
                ),
              // 지우기는 늘 제자리에 있다. 잘못 닿아도 지우기 전에 묻는다.
              if (!collapsed)
                GestureDetector(
                  onTap: () => _confirmRemove(context),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 36,
                    height: 28,
                    child: Icon(
                      CupertinoIcons.trash,
                      size: 17,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
            ],
          ),
          if (!collapsed) ...[
            ?timing,
            if (block.setup != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size.fromHeight(28),
                onPressed: onEditSetup,
                child: Text(
                  setupSummary(
                    block.setup!,
                    L.of(context),
                    block.completedReps,
                    block.sets.where((s) => s.mine).length,
                  ),
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              ),
            // 읽는 자리는 조밀하게 — 세트마다 한 칸, 한 줄에 여러 칸.
            if (block.sets.isNotEmpty || cursors.any((p) => p.set != null))
              SetGrid(
                block: block,
                uniform: uniformCell,
                onTapSet: onEditSet,
                // 빈 칸 하나가 늘 남아 있다. 누르면 이 운동에 다음 세트를 적는다.
                onAdd: input == null ? onOpen : null,
                editingSet: editingSet,
                cursors: {
                  for (final p in cursors)
                    if (p.set == '+')
                      block.sets.length: cursorColor(p.name)
                    else if (block.sets.indexWhere((s) => s.id == p.set)
                        case final at when at >= 0)
                      at: cursorColor(p.name),
                },
              ),
            // 상대가 치는 중인 글. 세트가 되기 전의 것이라 그 사람 색으로 흐리게.
            for (final p in cursors)
              if (p.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    p.text,
                    style: TextStyle(fontSize: 15, color: cursorColor(p.name)),
                  ),
                ),
            // 고치는 세트만 제 줄을 넓게 얻는다. 완료 표시와 지우기도 여기 있다.
            if (editingSet != null && editingSet! < block.sets.length)
              _SetRow(
                index: editingSet!,
                input: input,
                set: block.sets[editingSet!],
                onToggle: () => onToggle(editingSet!),
                onRemove: () => onRemoveSet(editingSet!),
              ),
            // 메모는 칸 아래 제 줄에 둔다. 칸에 붙이면 자리가 없어 잘리는데,
            // 메모는 잘리면 쓸모가 없다. 눌러서 글을 불러온 뒤 다 지우면 그
            // 줄이 없어진다 — 문서에서 글을 지우는 것과 같다.
            for (final (i, set) in block.sets.indexed) ...[
              for (final (n, note) in set.notes.indexed)
                GestureDetector(
                  onTap: () => onEditNote(i, n),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 1, 8, 5),
                    // 어느 세트의 메모인지 앞에 적는다 — 칸과 떨어져 있어서다.
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 14,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.75,
                              color: CupertinoColors.tertiaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            note,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              letterSpacing: -0.08,
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (input != null && isMemo && i == inputSet)
                Padding(
                  padding: const EdgeInsets.only(left: 14, right: 8),
                  child: input,
                ),
            ],
            if (input != null &&
                editingSet == null &&
                (!isMemo || block.sets.isEmpty))
              isMemo
                  ? input!
                  // 빈 자리를 들여쓰기만 해 두면 왜 밀려 있는지 알 수 없다.
                  // 몇 세트째인지 옅게 적어 둔다.
                  : Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(
                            L.of(context).setOrdinal(block.sets.length + 1),
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: -0.08,
                              color: CupertinoColors.tertiaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: input!),
                      ],
                    ),
          ],
        ],
      ),
    );
  }
}

/// 고치고 있는 세트 한 줄. 읽는 자리는 [SetGrid] 의 칸이다.
class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.index,
    required this.set,
    required this.onToggle,
    required this.onRemove,
    this.input,
  });

  final int index;
  final LoggedSet set;
  final Widget? input;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final off = !set.done;
    return Row(
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 30,
            height: 44,
            child: Icon(
              off
                  ? CupertinoIcons.circle
                  : CupertinoIcons.check_mark_circled_solid,
              size: 19,
              color: off
                  ? CupertinoColors.tertiaryLabel.resolveFrom(context)
                  : seal.resolveFrom(context),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            L.of(context).setOrdinal(index + 1),
            // caption 자리. 세트 번호는 값이 아니라 이름표다.
            style: TextStyle(
              fontSize: 13,
              letterSpacing: -0.08,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
        Expanded(child: input ?? const SizedBox.shrink()),
        GestureDetector(
          onTap: onRemove,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              CupertinoIcons.xmark,
              size: 15,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.matches,
    required this.highlight,
    required this.onPick,
    required this.onForget,
    this.onMealPhoto,
    this.onMealText,
    this.onLogAsMeal,
    this.mealMode = false,
  });

  /// 지금 친 글을 끼니로 남긴다. 칠 것이 없거나 운동 이름을 적는 중이 아니면 null.
  final VoidCallback? onLogAsMeal;
  final VoidCallback? onMealText;
  final bool mealMode;
  final List<String> matches;
  final int highlight;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onForget;
  final VoidCallback? onMealPhoto;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
        child: Container(
          key: const ValueKey('exercise-suggestions'),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
              context,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              if (onMealPhoto != null) ...[
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(44, 44),
                  onPressed: onMealPhoto,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.camera, size: 18),
                      const SizedBox(width: 5),
                      Text(
                        L.of(context).mealPhoto,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
              if (onMealText != null)
                CupertinoButton(
                  key: const ValueKey('meal-text-toggle'),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(44, 44),
                  onPressed: onMealText,
                  child: Icon(
                    CupertinoIcons.square_pencil,
                    size: 19,
                    semanticLabel: L.of(context).mealText,
                    color: mealMode
                        ? seal.resolveFrom(context)
                        : CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              if (onMealPhoto != null || onMealText != null) ...[
                Container(
                  width: 0.5,
                  height: 24,
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
                const SizedBox(width: 8),
              ],
              if (onLogAsMeal != null) ...[
                CupertinoButton(
                  key: const ValueKey('log-as-meal'),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(44, 32),
                  color: CupertinoColors.tertiarySystemFill.resolveFrom(
                    context,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: onLogAsMeal,
                  child: Text(
                    L.of(context).mealLogAs,
                    style: TextStyle(
                      fontSize: 14,
                      color: seal.resolveFrom(context),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: matches.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final on = i == highlight;
                    return Center(
                      child: SuggestionChip(
                        label: matches[i],
                        selected: on,
                        onTap: () => onPick(matches[i]),
                        onLongPress: () => onForget(matches[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 이름 후보 알약.
///
/// Material 의 ActionChip 을 걷어냈다 — 리플과 모서리 모양이 안드로이드
/// 그대로라 iOS 화면에서 혼자 튄다. iOS 는 눌린 것을 색으로 알리고, 누를 때는
/// 리플 대신 잠깐 흐려진다(CupertinoButton 이 그렇게 한다).
class SuggestionChip extends StatelessWidget {
  const SuggestionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? sealTint.resolveFrom(context)
                : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
                    context,
                  ),
            // 알약은 완전한 원형 끝이다. iOS 의 필터 칩이 그렇게 생겼다.
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected
                  ? seal.resolveFrom(context)
                  : CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              // footnote 13pt.
              fontSize: 13,
              letterSpacing: -0.08,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? seal.resolveFrom(context)
                  : CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// 상대의 "같이 하자". 받으면 몇 초 뒤 두 폰이 같이 3·2·1 을 센다.
class _TogetherInvite extends StatelessWidget {
  const _TogetherInvite({
    required this.name,
    required this.timer,
    required this.onAccept,
    required this.onDecline,
  });
  final String name;
  final SharedTimer timer;
  final VoidCallback onAccept, onDecline;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Container(
      key: const ValueKey('together-invite'),
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.togetherInvite(name),
                  style: TextStyle(fontSize: 13, color: muted),
                ),
                Text(
                  timer.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (timer.alternate)
                  Text(
                    l.togetherInviteAlternate,
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
              ],
            ),
          ),
          CupertinoButton.filled(
            key: const ValueKey('together-accept'),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(0, 38),
            onPressed: onAccept,
            child: Text(l.togetherStart),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            onPressed: onDecline,
            child: Icon(
              CupertinoIcons.xmark,
              size: 18,
              color: muted,
              semanticLabel: l.cancel,
            ),
          ),
        ],
      ),
    );
  }
}

/// 사람마다 한 색. 이름에서 나오므로 두 폰이 같은 사람을 같은 색으로 보고,
/// 그 사람이 적은 세트와 그 사람의 커서가 같은 색이다.
Color cursorColor(String key) {
  // 셋 이상이면 여섯 색으로는 겹치기 쉽다. 빨강·노랑·회색은 뺐다(지우기·경고·
  // 흐린 글과 헷갈린다).
  const palette = [
    CupertinoColors.systemOrange,
    CupertinoColors.systemPurple,
    CupertinoColors.systemTeal,
    CupertinoColors.systemPink,
    CupertinoColors.systemIndigo,
    CupertinoColors.systemGreen,
    CupertinoColors.systemBrown,
    CupertinoColors.systemCyan,
    CupertinoColors.systemMint,
    CupertinoColors.systemBlue,
  ];
  return palette[key.codeUnits.fold(0, (h, c) => (h * 31 + c) & 0xffff) %
      palette.length];
}

/// 운동 이름 옆의 이름표 — 이 사람이 지금 이 운동을 보고 있다.
class _CursorTag extends StatelessWidget {
  const _CursorTag(this.p);
  final PartnerPresence p;

  @override
  Widget build(BuildContext context) {
    final color = cursorColor(p.name);
    return Container(
      key: ValueKey('cursor-${p.key}'),
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(maxWidth: 72),
      child: Text(
        p.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
