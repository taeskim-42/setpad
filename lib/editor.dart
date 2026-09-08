import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'keypad.dart';
import 'local_ai.dart';
import 'local_ai_help.dart';
import 'l10n/generated/app_localizations.dart';
import 'exercises.dart';
import 'palette.dart';
import 'parser.dart';
import 'units.dart';

class EditorDraft {
  const EditorDraft({
    required this.text,
    this.block = -1,
    this.memo = false,
    this.editingSet,
    this.editingNote,
    this.setText,
  });
  final String text;
  final int block;
  final bool memo;
  final int? editingSet, editingNote;
  final String? setText;
  Map<String, Object?> toJson() => {
    'text': text,
    'block': block,
    'memo': memo,
    'editingSet': editingSet,
    'editingNote': editingNote,
    'setText': setText,
  };
  static EditorDraft? fromJson(Object? value) {
    if (value is! Map || value['text'] is! String) return null;
    return EditorDraft(
      text: value['text'] as String,
      block: value['block'] is int ? value['block'] as int : -1,
      memo: value['memo'] == true,
      editingSet: value['editingSet'] is int
          ? value['editingSet'] as int
          : null,
      editingNote: value['editingNote'] is int
          ? value['editingNote'] as int
          : null,
      setText: value['setText'] is String ? value['setText'] as String : null,
    );
  }
}

class LoggedSet {
  LoggedSet({
    this.value,
    this.unit = defaultUnit,
    this.reps,
    List<String>? notes,
    this.done = true,
  }) : notes = notes ?? [];

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
  ExerciseBlock(this.name, [List<LoggedSet>? sets, this.setup])
    : sets = sets ?? [];
  String name;
  final List<LoggedSet> sets;
  WorkoutSetup? setup;
  int get completedReps =>
      sets.where((s) => s.done).fold(0, (n, s) => n + (s.reps ?? 0));
}

/// 에디터의 상태. 화면과 떼어 둔 이유는 상위 화면(복사 버튼 등)이 같은 상태를
/// 봐야 하고, 위젯 테스트에서 직접 찔러볼 수 있어야 해서다.
class RoutineEditorController extends ChangeNotifier {
  RoutineEditorController({
    Iterable<String> history = const [],
    this.weightUnit = defaultUnit,
  }) {
    _learned.addAll(history);
  }

  String weightUnit;
  final List<ExerciseBlock> blocks = [];
  final List<String> _learned = [];
  List<String> get recentExercises => List.unmodifiable(_learned);

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

  bool get naming => !inBlock;

  /// 카드를 눌러 그 운동을 다시 연다.
  void openBlock(int index) {
    if (index < 0 || index >= blocks.length || index == _active) return;
    _active = index;
    notifyListeners();
  }

  void addExercise(String name, {WorkoutSetup? setup}) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    blocks.add(ExerciseBlock(clean, null, setup));
    _learned.remove(clean);
    _learned.insert(0, clean);
    _active = blocks.length - 1;
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
          blocks[_active].sets.lastOrNull?.unit ??
          weightUnit,
      reps: parsed.reps,
      notes: parsed.note == null ? null : [parsed.note!],
    );
    blocks[_active].sets.addAll(List.generate(parsed.count, (_) => makeSet()));
    notifyListeners();
    return true;
  }

  /// 직전 세트 — 키패드의 "이전과 같이" 가 보여줄 것.
  LoggedSet? get lastSet => inBlock && blocks[_active].sets.isNotEmpty
      ? blocks[_active].sets.last
      : null;

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

  void updateSetup(int index, WorkoutSetup setup) {
    if (index < 0 || index >= blocks.length) return;
    blocks[index].name = setup.name;
    blocks[index].setup = setup;
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
    final sets = blocks[_active].sets;
    if (sets.isEmpty) return;
    final clean = text.trim();
    if (clean.isEmpty) return;
    sets.last.notes.add(clean);
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

  /// 빈 칸에서 지우기 — 마지막 세트부터, 세트가 없으면 운동을 뗀다.
  void backspace() {
    if (blocks.isEmpty) return;
    if (!inBlock) {
      // 카드 밖이면 마지막 운동 안으로 다시 들어간다.
      _active = blocks.length - 1;
      notifyListeners();
      return;
    }
    final open = blocks[_active];
    if (open.sets.isNotEmpty) {
      open.sets.removeLast();
    } else {
      blocks.removeAt(_active);
      _active = -1;
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
    // 저장된 이름도 이 기기에서 친 이름이다. 자동완성이 알아야 한다.
    for (final b in saved.reversed) {
      _learned.remove(b.name);
      _learned.insert(0, b.name);
    }
    _active = -1;
    notifyListeners();
  }

  int get totalSets =>
      blocks.fold(0, (n, b) => n + b.sets.where((s) => s.done).length);

  /// 클립보드로 나가는 글. 세트·횟수 표기는 화면 언어를 탄다.
  String asText({
    String Function(int n)? setOrdinal,
    String Function(int n)? formatReps,
  }) => blocks
      .map((b) => (name: b.name, sets: b.sets.where((s) => s.done).toList()))
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
  ExerciseBlock block,
) async {
  final l = L.of(context);
  final yes = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(l.deleteExerciseTitle(block.name)),
      content: Text(
        block.sets.isEmpty
            ? l.deleteExerciseEmptyBody
            : l.deleteExerciseBody(block.sets.length),
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
    this.header,
    this.localAi = const LocalAi(),
    this.initialDraft,
    this.onDraftChanged,
  });
  final RoutineEditorController controller;
  final Widget? header;
  final LocalAi localAi;
  final EditorDraft? initialDraft;
  final ValueChanged<EditorDraft?>? onDraftChanged;

  @override
  State<RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends State<RoutineEditor>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  /// 입력 줄이 트리의 다른 자리로 옮겨가도 같은 위젯으로 유지되게 한다.
  final _inputKey = GlobalKey();
  bool _invalidSet = false;
  TextEditingValue? _setDraft;
  int _highlight = 0;
  LocalAiStatus _aiStatus = LocalAiStatus.checking;
  bool _aiBusy = false;
  bool _aiFailed = false;
  int _aiRequest = 0;
  int _statusRequest = 0;
  String? _locale;
  String? _submittedText;
  String? _pendingSubmission;
  WorkoutSetup? get _setup =>
      _c.inBlock ? _c.blocks[_c.activeIndex].setup : null;

  /// 메모를 칠 때만 잠깐 시스템 키보드로 넘어간다. 세트를 하나 넣으면
  /// 다시 키패드로 돌아온다 — 메모는 세트마다 붙는 게 아니라 가끔 붙는다.
  bool _wantText = false;

  /// 칠 것이 들어 있는가. 키패드의 큰 키가 하는 일이 여기 따라 달라진다.
  /// 뒤집힐 때만 다시 그린다 — 글자마다 그릴 이유가 없다.
  bool _hasInput = false;

  /// +/- 가 한 번에 미는 폭. 길게 눌러 바꾼다. null 이면 단위의 기본값이다.
  double? _step;

  /// 지금 고치고 있는 메모의 자리 (운동, 세트, 메모). null 이면 새로 다는 중.
  (int, int, int)? _editing;

  /// 메모 한 줄을 입력칸으로 불러온다. 커밋하면 그 자리를 덮어쓴다.
  void _startEditNote(int block, int set, int note) {
    final text = _c.blocks[block].sets[set].notes[note];
    if (!_wantText && _c.activeIndex == block) _setDraft = _input.value;
    _c.openBlock(block);
    _input.text = text;
    _input.selection = TextSelection.collapsed(offset: _input.text.length);
    setState(() {
      _editing = (_c.activeIndex, set, note);
      _wantText = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reopen();
      final ctx = _inputKey.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx);
    });
  }

  /// 지금 치는 자리의 단위. 아직 안 쳤으면 이 운동에서 쓰던 것을 잇는다.
  String get _unit {
    final typed = parseSetLine(_input.text)?.unit;
    if (typed != null) return typed;
    final sets = _c.inBlock
        ? _c.blocks[_c.activeIndex].sets
        : const <LoggedSet>[];
    return _setup?.unit ?? (sets.isEmpty ? _c.weightUnit : sets.last.unit);
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
      ).hasMatch(_input.text) ||
      _input.text.trimLeft().contains(' ');

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

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    if (draft != null) {
      if (draft.block >= 0 && draft.block < _c.blocks.length) {
        _c.openBlock(draft.block);
        _wantText = draft.memo;
        final st = draft.editingSet, n = draft.editingNote;
        if (st != null &&
            n != null &&
            st >= 0 &&
            st < _c.blocks[draft.block].sets.length &&
            n >= 0 &&
            n < _c.blocks[draft.block].sets[st].notes.length) {
          _editing = (draft.block, st, n);
        }
      }
      _input.text = draft.text;
      _hasInput = draft.text.trim().isNotEmpty;
      if (draft.setText != null) {
        _setDraft = TextEditingValue(text: draft.setText!);
      }
    }
    _c.addListener(_onChanged);
    // Keep memo mode until it is explicitly saved, even if the IME loses focus.
    _input.addListener(_onInput);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (locale != _locale) {
      _locale = locale;
      _refreshAi();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAi();
    } else if (state == AppLifecycleState.paused && _aiBusy) {
      _aiRequest++;
      widget.localAi.cancel();
      setState(() => _aiBusy = false);
    }
  }

  Future<void> _refreshAi() async {
    final request = ++_statusRequest;
    setState(() => _aiStatus = LocalAiStatus.checking);
    final status = await widget.localAi.status(_locale ?? 'en');
    if (mounted && request == _statusRequest) {
      setState(() => _aiStatus = status);
      final pending = _pendingSubmission;
      _pendingSubmission = null;
      if (pending != null && pending == _input.text && _c.naming) _commit();
    }
  }

  Future<void> _prepareAi() async {
    setState(() => _aiStatus = LocalAiStatus.downloading);
    try {
      await widget.localAi.prepare();
    } catch (_) {
      if (mounted) setState(() => _aiStatus = LocalAiStatus.unavailable);
      return;
    }
    if (mounted) await _refreshAi();
  }

  Future<void> _interpret(String text) async {
    if (_aiBusy) return;
    final request = ++_aiRequest;
    _submittedText = text;
    setState(() {
      _aiBusy = true;
      _aiFailed = false;
    });
    try {
      final setup = await widget.localAi.interpret(
        text,
        _locale ?? 'en',
        _c.vocabulary(_lang),
      );
      if (!mounted ||
          request != _aiRequest ||
          !_c.naming ||
          _input.text != text) {
        return;
      }
      setState(() => _aiBusy = false);
      _input.clear();
      _c.addExercise(
        setup.name,
        setup: setup.hasPlan || setup.repsOnly ? setup : null,
      );
      _focus.requestFocus();
    } catch (_) {
      if (mounted && request == _aiRequest) {
        setState(() {
          _aiBusy = false;
          _aiFailed = true;
        });
        _refreshAi();
        _focus.requestFocus();
      }
    } finally {
      if (mounted && request == _aiRequest) setState(() => _aiBusy = false);
    }
  }

  Future<void> _editSetup(int index) async {
    final block = _c.blocks[index];
    _focus.unfocus();
    final setup = await editWorkoutSetup(context, block.setup!);
    if (!mounted) return;
    if (setup != null) _c.updateSetup(_c.blocks.indexOf(block), setup);
    _reopen();
  }

  /// 닫힌 카드를 눌렀을 때. 커서를 그 카드로 옮기고 입력칸을 비운다 —
  /// 치던 글자가 다른 운동으로 딸려 가면 안 된다.
  void _openBlock(int index) {
    if (_wantText) {
      _commit();
      if (_wantText) return;
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

  void _moveBlock(int from, int to) {
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

  void _onInput() {
    if (_pendingSubmission != _input.text) _pendingSubmission = null;
    if (_aiBusy && _input.text != _submittedText) {
      _aiRequest++;
      widget.localAi.cancel();
      _aiBusy = false;
    }
    final has = _input.text.trim().isNotEmpty;
    if (mounted) {
      setState(() {
        _hasInput = has;
        _invalidSet = false;
        _aiFailed = false;
      });
    }
    _saveDraft();
  }

  void _saveDraft() {
    widget.onDraftChanged?.call(
      _input.text.isEmpty && _setDraft == null
          ? null
          : EditorDraft(
              text: _input.text,
              block: _c.activeIndex,
              memo: _wantText,
              editingSet: _editing?.$2,
              editingNote: _editing?.$3,
              setText: _setDraft?.text,
            ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _aiRequest++;
    widget.localAi.cancel();
    _c.removeListener(_onChanged);
    _input.removeListener(_onInput);
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// 세트를 받는 중이면 시스템 키보드가 있을 자리가 없다 — 키패드가 그 자리다.
  bool get _padMode => _c.inBlock && !_wantText;

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
    _saveDraft();
    if (mounted) setState(() {});
    // keyboardType 을 바꾸는 것만으로는 **이미 올라와 있는** 키보드가 내려가지
    // 않는다. 운동 이름을 칠 때 뜬 키보드가 세트 모드에서도 그대로 남아
    // 키패드를 덮었다.
    if (_padMode) SystemChannels.textInput.invokeMethod('TextInput.hide');

    // 줄이 늘었을 때만 따라 내린다. 예전에는 컨트롤러가 바뀔 때마다 무조건
    // 맨 아래로 내렸는데, 세트를 켜고 끄거나 메모를 고칠 때도 화면이 출렁였다.
    // 키패드가 뜨고 지면서 뷰포트 높이가 바뀌면 그때마다 또 움직였다.
    final grew = _lineCount > _lastLineCount;
    _lastLineCount = _lineCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 자리를 옮긴 뒤에도 계속 칠 수 있어야 한다.
      if (mounted && !_focus.hasFocus) _focus.requestFocus();
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

  /// 포커스를 쥔 채 키보드만 내려간 경우 requestFocus 는 아무 일도 하지 않는다.
  /// 그때는 입력 연결을 직접 다시 연다.
  void _reopen() {
    if (!_focus.hasFocus) {
      _focus.requestFocus();
    } else if (!_padMode) {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  List<String> get _matches => !_c.naming
      ? const []
      : _input.text.trim().isEmpty
      ? _c.recentExercises.take(6).toList()
      : suggest(
          _input.text,
          _c.vocabulary(_lang),
          preferred: _c.recentExercises,
        );

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
    final value = pick ?? _input.text;
    if (pick == null &&
        _c.naming &&
        value.trim().isNotEmpty &&
        _aiStatus == LocalAiStatus.checking) {
      _pendingSubmission = value;
      return;
    }
    if (pick == null &&
        _c.naming &&
        value.trim().isNotEmpty &&
        _aiStatus == LocalAiStatus.available) {
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
      _highlight = 0;
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
    }
    _focus.requestFocus();
  }

  void _nextSet() {
    final text = _input.text.trimRight();
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

  void _keypadBackspace() {
    final v = _input.value;
    if (v.text.isEmpty) {
      // 세트가 다 빠진 뒤의 한 번은 운동 자체를 뗀다. 지우기 버튼과 같은
      // 결과이므로 같은 것을 묻는다.
      if (_c.backspaceRemovesBlock) {
        final block = _c.blocks[_c.activeIndex];
        confirmRemoveExercise(context, block).then((yes) {
          if (yes && mounted) _c.backspace();
        });
        return;
      }
      _c.backspace();
      return;
    }
    final end = v.selection.end < 0 ? v.text.length : v.selection.end;
    if (end == 0) return;
    final next = v.text.replaceRange(end - 1, end, '');
    _input.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: end - 1),
    );
    setState(() {});
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _input.text.isEmpty) {
      _c.backspace();
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
        () => _highlight = (_highlight - 1 + matches.length) % matches.length,
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

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            // 빈 곳을 눌러도 커서를 잃지 않는다.
            onTap: _reopen,
            behavior: HitTestBehavior.opaque,
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      if (widget.header != null)
                        SliverToBoxAdapter(child: widget.header!),
                      SliverReorderableList(
                        itemCount: blocks.length,
                        onReorderItem: _moveBlock,
                        itemBuilder: (context, i) => _BlockView(
                          key: ObjectKey(blocks[i]),
                          dragHandle: ReorderableDragStartListener(
                            index: i,
                            child: Semantics(
                              label: L.of(context).moveExercise,
                              child: const SizedBox(
                                width: 36,
                                height: 44,
                                child: Icon(
                                  CupertinoIcons.line_horizontal_3,
                                  size: 18,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ),
                          ),
                          block: blocks[i],
                          input: i == openIndex ? _buildInput() : null,
                          inputSet: _editing?.$2 ?? blocks[i].sets.length - 1,
                          isMemo: _wantText,
                          onToggle: (set) => _c.toggleDone(i, set),
                          onRemoveSet: (set) => _c.removeSet(i, set),
                          onRemoveBlock: () => _c.removeBlock(i),
                          onEditNote: (set, note) =>
                              _startEditNote(i, set, note),
                          onRemoveNote: (set, note) =>
                              _c.removeNote(i, set, note),
                          onEditSetup: () => _editSetup(i),
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
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size.fromHeight(36),
                                onPressed: () => showLocalAiHelp(
                                  context,
                                  _aiStatus,
                                  onRetry: _refreshAi,
                                  onPrepare: _prepareAi,
                                ),
                                child: Text(
                                  _aiBusy
                                      ? L.of(context).aiWorking
                                      : '${L.of(context).aiTitle} · ${aiStatusLabel(L.of(context), _aiStatus)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              if (_aiFailed) ...[
                                Text(
                                  L.of(context).aiFailure,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _commit(_input.text),
                                  child: Text(
                                    L.of(context).aiUseName,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                              if (blocks.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    L.of(context).howTo,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: CupertinoColors.secondaryLabel
                                          .resolveFrom(context),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (matches.isNotEmpty)
          _Suggestions(
            matches: matches,
            highlight: _highlight,
            onPick: (name) => _commit(name),
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
              child: _padMode
                  ? SetKeypad(
                      onKey: _insert,
                      onBackspace: _keypadBackspace,
                      onAddSet: parseSetLine(_input.text) == null
                          ? null
                          : () => _commit(),
                      onSubmit: _nextSet,
                      submitLabel: _hasInput
                          ? L.of(context).next
                          : L.of(context).finishExercise,
                      onText: () {
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
                        final next = bumpLastNumber(_input.text, direction);
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
                      onRepeat: _c.repeatLastSet,
                    )
                  // 메모를 치는 동안에도 돌아올 문은 열어 둔다.
                  : (_c.inBlock && _wantText)
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

    return Focus(
      key: _inputKey,
      onKeyEvent: _onKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoTextField(
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
              _input.text.trim().isNotEmpty && _matches.isNotEmpty
                  ? _matches[_highlight.clamp(0, _matches.length - 1)]
                  : null,
            ),
            onChanged: (_) => setState(() => _highlight = 0),
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
            placeholder: bold
                ? L.of(context).exerciseNameHint
                : _wantText && _c.lastSet != null
                ? L.of(context).noteHint
                : (_setup?.countsReps ?? false)
                ? L.of(context).repsInputHint
                : L.of(context).setInputHint,
            placeholderStyle: TextStyle(
              fontSize: 17,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: CupertinoColors.placeholderText.resolveFrom(context),
            ),
          ),
          if (_invalidSet)
            Text(
              L.of(context).setRequired,
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
  });

  final ExerciseBlock block;
  final Widget dragHandle;

  /// 이 운동이 아직 세트를 받는 중이면 입력 줄이 카드 안에 들어온다.
  final Widget? input;
  final int inputSet;
  final bool isMemo;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onRemoveSet;
  final VoidCallback onRemoveBlock;

  /// (세트 번호, 메모 번호).
  final void Function(int, int) onEditNote;
  final void Function(int, int) onRemoveNote;
  final VoidCallback onEditSetup;

  /// 닫힌 카드를 눌러 그 운동을 다시 연다. 열려 있으면 null 이다.
  final VoidCallback? onOpen;

  Future<void> _confirmRemove(BuildContext context) async {
    if (await confirmRemoveExercise(context, block)) onRemoveBlock();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: _card(context),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  block.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              dragHandle,
              GestureDetector(
                onTap: () => _confirmRemove(context),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    CupertinoIcons.trash,
                    size: 18,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
          if (block.setup != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size.fromHeight(32),
              onPressed: onEditSetup,
              child: Text(
                setupSummary(
                  block.setup!,
                  L.of(context),
                  block.completedReps,
                  block.sets.where((s) => s.done).length,
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          for (final e in block.sets.asMap().entries) ...[
            _SetRow(
              index: e.key,
              set: e.value,
              onToggle: () => onToggle(e.key),
              onRemove: () => onRemoveSet(e.key),
              onEditNote: (i) => onEditNote(e.key, i),
              onRemoveNote: (i) => onRemoveNote(e.key, i),
            ),
            if (input != null && isMemo && e.key == inputSet)
              Padding(
                padding: const EdgeInsets.only(left: 36, right: 8),
                child: input,
              ),
          ],
          if (input != null && (!isMemo || block.sets.isEmpty)) ...[
            Padding(
              padding: EdgeInsets.only(
                top: block.sets.isEmpty ? 2 : 4,
                left: isMemo ? 0 : 86,
              ),
              child: input!,
            ),
          ],
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.index,
    required this.set,
    required this.onToggle,
    required this.onRemove,
    required this.onEditNote,
    required this.onRemoveNote,
  });

  final int index;
  final LoggedSet set;

  /// 메모 한 줄을 눌렀을 때 — 그 줄을 입력칸으로 불러 고친다.
  final ValueChanged<int> onEditNote;
  final ValueChanged<int> onRemoveNote;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final off = !set.done;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 36,
                  height: 36,
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
                width: 50,
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
              Expanded(
                child: Text(
                  setLabel(
                    value: set.value,
                    unit: set.unit,
                    reps: set.reps,
                    formatReps: L.of(context).repsCount,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 32,
                  height: 36,
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 15,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
          // 메모는 세트 아래 제 줄에 둔다. 같은 줄에 붙이면 자리가 없어
          // 잘리는데, 메모는 잘리면 쓸모가 없다 — 길게 적으라고 있는 것이다.
          // 지우기 위한 표시를 따로 두지 않는다. 눌러서 글을 불러온 뒤 지우기로
          // 다 지우면 그 줄이 없어진다 — 문서에서 글을 지우는 것과 같다.
          // 밀어서 지우기도 붙여 봤지만, 글줄에 대고 미는 것이 어색했다.
          for (final e in set.notes.asMap().entries)
            GestureDetector(
              onTap: () => onEditNote(e.key),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(36, 1, 8, 6),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    letterSpacing: -0.08,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.matches,
    required this.highlight,
    required this.onPick,
  });

  final List<String> matches;
  final int highlight;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        // iOS 의 구분선은 0.5pt 다. 1pt 면 굵어서 눈에 걸린다.
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
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
            ),
          );
        },
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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
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
    );
  }
}
