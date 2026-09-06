import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'keypad.dart';
import 'l10n/generated/app_localizations.dart';
import 'exercises.dart';
import 'palette.dart';
import 'parser.dart';
import 'units.dart';

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
  ExerciseBlock(this.name, [List<LoggedSet>? sets]) : sets = sets ?? [];
  final String name;
  final List<LoggedSet> sets;
}

/// 에디터의 상태. 화면과 떼어 둔 이유는 상위 화면(복사 버튼 등)이 같은 상태를
/// 봐야 하고, 위젯 테스트에서 직접 찔러볼 수 있어야 해서다.
class RoutineEditorController extends ChangeNotifier {
  final List<ExerciseBlock> blocks = [];
  final List<String> _learned = [];

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
    // 열려 있던 운동이 빈 채로 남으면 치우고 나간다 — closeBlock 과 같은 규칙.
    if (inBlock && blocks[_active].sets.isEmpty) {
      blocks.removeAt(_active);
      if (index > _active) index -= 1;
    }
    _active = index;
    notifyListeners();
  }

  void addExercise(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    blocks.add(ExerciseBlock(clean));
    _learned.remove(clean);
    _learned.insert(0, clean);
    _active = blocks.length - 1;
    notifyListeners();
  }

  bool addSet(String line) {
    final parsed = parseSetLine(line);
    if (parsed == null || !inBlock) return false;
    final set = LoggedSet(
      value: parsed.value,
      // 단위를 안 쳤으면 이 운동에서 쓰던 것을 잇는다. 한 운동 안에서
      // 세트마다 단위가 바뀌는 일은 없다.
      unit: parsed.unit ?? blocks[_active].sets.lastOrNull?.unit ?? defaultUnit,
      reps: parsed.reps,
      notes: parsed.note == null ? null : [parsed.note!],
    );
    blocks[_active].sets.addAll(List.generate(parsed.count, (_) => set));
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
    blocks[_active].sets.add(s);
    notifyListeners();
  }

  /// 빈 줄에서 Enter — 이 운동은 여기까지. 목록 밖으로 커서가 빠져나온다.
  /// 노션에서 빈 리스트 항목에 Enter를 치면 리스트를 벗어나는 것과 같다.
  void closeBlock() {
    if (!inBlock) return;
    // 세트를 하나도 안 적은 운동은 남길 이유가 없다.
    if (blocks[_active].sets.isEmpty) blocks.removeAt(_active);
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
    // 세트가 안 남은 운동은 치운다. 단 지금 치고 있는 운동은 남긴다 — 커서가
    // 그 안에 있는데 카드가 사라지면 어디에 치는지 알 수 없다.
    if (b.sets.isEmpty && block != _active) {
      blocks.removeAt(block);
      if (_active > block) _active -= 1;
    }
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
  const RoutineEditor({super.key, required this.controller});
  final RoutineEditorController controller;

  @override
  State<RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends State<RoutineEditor> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  /// 입력 줄이 트리의 다른 자리로 옮겨가도 같은 위젯으로 유지되게 한다.
  final _inputKey = GlobalKey();
  int _highlight = 0;

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
    _input.text = _c.blocks[block].sets[set].notes[note];
    _input.selection = TextSelection.collapsed(offset: _input.text.length);
    setState(() {
      _editing = (block, set, note);
      _wantText = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _reopen());
  }

  /// 지금 치는 자리의 단위. 아직 안 쳤으면 이 운동에서 쓰던 것을 잇는다.
  String get _unit {
    final typed = parseSetLine(_input.text)?.unit;
    if (typed != null) return typed;
    final sets = _c.inBlock
        ? _c.blocks[_c.activeIndex].sets
        : const <LoggedSet>[];
    return sets.isEmpty ? defaultUnit : sets.last.unit;
  }

  /// 지금 미는 폭. 횟수를 치는 중이면 1이다 — 횟수를 2.5씩 미는 일은 없다.
  double get _stepSize {
    if (_typingReps) return 1;
    return _step ?? (unitById[_unit] ?? unitById[defaultUnit]!).step;
  }

  /// 무게(또는 거리·시간)를 지나 횟수를 치고 있는가.
  bool get _typingReps =>
      RegExp(
        '($unitPattern)\\s*[\\d.]*\$',
        caseSensitive: false,
      ).hasMatch(_input.text) ||
      _input.text.trimRight().contains(' ');

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
    _c.addListener(_onChanged);
    // 시스템 키보드를 스와이프로 내리면 포커스가 풀린다. 그대로 두면 키패드도
    // 사라진 채 남아서, 세트를 하나 커밋하기 전에는 되돌릴 방법이 없었다.
    _focus.addListener(() {
      if (!_focus.hasFocus && _wantText) setState(() => _wantText = false);
    });
    _input.addListener(_onInput);
  }

  /// 닫힌 카드를 눌렀을 때. 커서를 그 카드로 옮기고 입력칸을 비운다 —
  /// 치던 글자가 다른 운동으로 딸려 가면 안 된다.
  void _openBlock(int index) {
    _input.clear();
    setState(() => _wantText = false);
    _c.openBlock(index);
    _reopen();
  }

  void _onInput() {
    final has = _input.text.trim().isNotEmpty;
    if (has != _hasInput && mounted) setState(() => _hasInput = has);
  }

  @override
  void dispose() {
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
      _c.blocks.fold(0, (n, b) => n + b.sets.length + b.sets.fold(0, (m, s) => m + s.notes.length));
  int _lastLineCount = 0;

  void _onChanged() {
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

  List<String> get _matches =>
      _c.naming ? suggest(_input.text, _c.vocabulary(_lang)) : const [];

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
    final editing = _editing;
    // 메모 모드에서 친 것은 마지막 세트의 메모다. 그냥 넘기면 숫자가 없는
    // 줄이라 파서가 새 운동 이름으로 읽어 버린다.
    final memo = pick == null && (editing != null || (_wantText && _c.lastSet != null));
    final wasText = _wantText;

    // **모드를 먼저 되돌린다.** 컨트롤러를 먼저 건드리면 _onChanged 가 아직
    // 메모 모드인 줄 알고 시스템 키보드를 안 내린다. 그 상태에서 키패드가
    // 올라와 둘이 겹치고, iOS 가 뒤늦게 키보드를 내리면서 화면이 튄다.
    _input.clear();
    setState(() {
      _highlight = 0;
      _wantText = false;
      _editing = null;
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
    } else {
      _c.commit(value);
    }
    _focus.requestFocus();
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
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: blocks.length + (_c.naming ? 1 : 0),
              itemBuilder: (context, i) {
                if (i < blocks.length) {
                  return _BlockView(
                    block: blocks[i],
                    input: i == openIndex ? _buildInput() : null,
                    onToggle: (set) => _c.toggleDone(i, set),
                    onRemoveSet: (set) => _c.removeSet(i, set),
                    onRemoveBlock: () => _c.removeBlock(i),
                    onEditNote: (set, note) => _startEditNote(i, set, note),
                    onRemoveNote: (set, note) => _c.removeNote(i, set, note),
                    // 열려 있는 카드는 이미 거기다 — 누를 것이 없다.
                    onOpen: i == openIndex ? null : () => _openBlock(i),
                    onAddSet: i == openIndex ? () => _commit() : null,
                  );
                }
                // 카드 밖 — 새 운동 이름 자리. 이것도 카드 안에 넣는다.
                // 회색 배경 위에 글자만 떠 있으면 어디에 치는 것인지 보이지
                // 않고, iOS 화면에서 혼자 미완성으로 읽힌다.
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  constraints: const BoxConstraints(minHeight: 44),
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemGroupedBackground
                        .resolveFrom(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildInput(bold: true),
                  ),
                );
              },
            ),
          ),
        ),
        if (matches.isNotEmpty)
          _Suggestions(
            matches: matches,
            highlight: _highlight,
            onPick: (name) => _commit(name),
          ),
        // 세트를 받는 중일 때만. 운동 이름은 어휘가 무한해서 시스템 키보드가 맞다.
        if (_c.inBlock && !_wantText)
          SetKeypad(
            hasInput: _hasInput,
            onKey: _insert,
            onBackspace: _keypadBackspace,
            onSubmit: () {
              // 참조 앱의 Next 와 같다 — 아직 한 칸도 안 띄웠으면 다음 자리로
              // 옮기고, 이미 옮겨 왔으면 그 줄을 세트로 넣는다.
              final t = _input.text.trimRight();
              if (t.isNotEmpty && !t.contains(' ')) {
                _insert(' ');
                return;
              }
              _commit();
            },
            onText: () {
              // 글자판으로 넘어가는 것은 곧 메모를 적겠다는 뜻이다. 이 화면에
              // 글자가 필요한 자리는 거기뿐이다 — 운동 이름은 카드 밖에서
              // 치고 그때는 애초에 키패드가 안 뜬다.
              setState(() => _wantText = true);
              // 읽기 전용이 풀린 뒤라야 키보드가 글자판으로 열린다.
              WidgetsBinding.instance.addPostFrameCallback((_) => _reopen());
            },
            onAdjust: (direction) {
              final next = bumpLastNumber(_input.text, direction);
              _input.value = TextEditingValue(
                text: next,
                selection: TextSelection.collapsed(offset: next.length),
              );
              setState(() {});
            },
            // 무게를 치는 중이면 원판 단위, kg 를 지나 횟수를 치는 중이면 하나.
            // 무엇의 2.5 인지 보여야 한다. 횟수를 치는 중이면 단위가 없으므로
            // 숫자만 낸다 — "1회" 는 늘 1이라 붙일 값이 없다.
            stepLabel: _typingReps
                ? formatNumber(_stepSize)
                : formatValue(_stepSize, _unit),
            // 칠 것이 있으면 늘 '다음'이다. 세트를 넣는 일은 화면 버튼이
            // 맡으므로, 같은 이름의 버튼이 둘이 되지 않게 한다.
            submitLabel: _hasInput
                ? L.of(context).next
                : L.of(context).finishExercise,
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
          ),
        // 메모를 치는 동안에도 돌아올 문은 열어 둔다.
        if (_c.inBlock && _wantText)
          ColoredBox(
            color: keypadBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 44,
                width: double.infinity,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() => _wantText = false);
                    _focus.requestFocus();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.keyboard,
                        size: 19,
                        color: seal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        L.of(context).numberKeypad,
                        style: const TextStyle(
                          fontSize: 17,
                          letterSpacing: -0.41,
                          color: seal,
                        ),
                      ),
                    ],
                  ),
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
      child: CupertinoTextField(
        controller: _input,
        focusNode: _focus,
        autofocus: true,
        // 터치 기기에서 세트를 받는 중이면 읽기 전용 — 시스템 키보드를 아예
        // 부르지 않는다. 글자는 아래 키패드가 넣는다. 데스크톱·웹에서는 물리
        // 키보드로 그냥 치는 편이 빨라서 걸지 않는다.
        readOnly: readOnly,
        showCursor: true,
        keyboardType: readOnly ? TextInputType.none : TextInputType.text,
        textInputAction: TextInputAction.done,
        onTap: _reopen,
        onSubmitted: (_) =>
            _commit(_matches.isNotEmpty ? _matches[_highlight] : null),
        onChanged: (_) => setState(() => _highlight = 0),
        // 운동 이름은 본문(17), 세트 줄은 숫자가 자리를 지켜야 해서 고정폭이다.
        style: TextStyle(
          fontSize: 17,
          letterSpacing: bold ? -0.41 : 0,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          fontFamily: bold ? null : 'Menlo',
          color: CupertinoColors.label.resolveFrom(context),
        ),
        // 커서는 글자 색을 따른다. 인주색은 강조하는 자리에 쓰는 것이고,
        // 글을 쓰는 자리에서 빨간 막대가 서 있으면 무언가 잘못된 것처럼 읽힌다.
        cursorColor: CupertinoColors.label.resolveFrom(context),
        // 카드 안에 이미 면이 있으므로 입력 칸은 테두리를 두지 않는다.
        decoration: const BoxDecoration(),
        padding: EdgeInsets.symmetric(vertical: bold ? 10 : 6),
        placeholder: bold ? L.of(context).exerciseNameHint : '100  20',
        placeholderStyle: TextStyle(
          fontSize: 17,
          letterSpacing: bold ? -0.41 : 0,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          fontFamily: bold ? null : 'Menlo',
          color: CupertinoColors.placeholderText.resolveFrom(context),
        ),
      ),
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({
    required this.block,
    this.input,
    required this.onToggle,
    required this.onRemoveSet,
    required this.onRemoveBlock,
    required this.onOpen,
    required this.onEditNote,
    required this.onRemoveNote,
    this.onAddSet,
  });

  final ExerciseBlock block;

  /// 이 운동이 아직 세트를 받는 중이면 입력 줄이 카드 안에 들어온다.
  final Widget? input;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onRemoveSet;
  final VoidCallback onRemoveBlock;

  /// (세트 번호, 메모 번호).
  final void Function(int, int) onEditNote;
  final void Function(int, int) onRemoveNote;

  /// 닫힌 카드를 눌러 그 운동을 다시 연다. 열려 있으면 null 이다.
  final VoidCallback? onOpen;

  /// 카드 안의 '세트 추가'. 열려 있는 카드에만 있다.
  final VoidCallback? onAddSet;

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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        // iOS 의 목록 카드는 그림자를 쓰지 않는다. 회색 배경 위의 흰 면과
        // 모서리 10 으로 나눈다 — 그림자는 안드로이드 쪽 관습이다.
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  block.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.41,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _confirmRemove(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                  child: Icon(
                    CupertinoIcons.trash,
                    size: 18,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
          ...block.sets.asMap().entries.map(
            (e) => _SetRow(
              index: e.key,
              set: e.value,
              onToggle: () => onToggle(e.key),
              onRemove: () => onRemoveSet(e.key),
              onEditNote: (i) => onEditNote(e.key, i),
              onRemoveNote: (i) => onRemoveNote(e.key, i),
            ),
          ),
          if (input != null) ...[
            Padding(
              padding: EdgeInsets.only(
                top: block.sets.isEmpty ? 2 : 4,
                // 세트 값이 시작하는 자리와 같다(체크 32 + 세트 번호 42).
                // 치는 숫자와 들어간 숫자가 한 줄로 서야 눈이 안 흔들린다.
                left: 74,
              ),
              child: input!,
            ),
            // 키패드의 큰 키는 '다음'(무게→횟수)을 맡는다. 세트를 넣는 일은
            // 화면에 둔다 — 지금 무엇을 넣는지가 보이는 자리에 있어야 한다.
            if (onAddSet != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  // iOS 의 은은한 채움 버튼. 최소 높이 44 를 지킨다.
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.fromHeight(44),
                    borderRadius: BorderRadius.circular(10),
                    color: sealTint.resolveFrom(context),
                    onPressed: onAddSet,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.add, size: 18, color: seal),
                        const SizedBox(width: 6),
                        Text(
                          L.of(context).addSet,
                          style: const TextStyle(
                            fontSize: 17,
                            letterSpacing: -0.41,
                            color: seal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        // 해낸 세트는 바탕이 깔린다 — 멀리서 봐도 몇 개 했는지 보인다.
        color: off ? null : doneTint.resolveFrom(context),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 32,
                  child: Icon(
                    off
                        ? CupertinoIcons.circle
                        : CupertinoIcons.check_mark_circled_solid,
                    size: 19,
                    color: off
                        ? CupertinoColors.tertiaryLabel.resolveFrom(context)
                        : CupertinoColors.systemGreen.resolveFrom(context),
                  ),
                ),
              ),
              SizedBox(
                width: 42,
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
              Text(
                setLabel(
                  value: set.value,
                  unit: set.unit,
                  reps: set.reps,
                  formatReps: L.of(context).repsCount,
                ),
                style: TextStyle(
                  // 숫자가 줄 서는 자리라 고정폭이다.
                  fontSize: 16,
                  fontFamily: 'Menlo',
                  color: off
                      ? CupertinoColors.tertiaryLabel.resolveFrom(context)
                      : CupertinoColors.label.resolveFrom(context),
                  decoration: off ? TextDecoration.lineThrough : null,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
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
                padding: const EdgeInsets.fromLTRB(74, 1, 24, 3),
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
                ? seal
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
            color: selected ? seal : CupertinoColors.label.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}
