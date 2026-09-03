import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'keypad.dart';
import 'parser.dart';

const seal = Color(0xFFC3372A);

class LoggedSet {
  const LoggedSet({this.kg, this.reps, this.note});
  final double? kg;
  final int? reps;
  final String? note;
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
  List<String> get vocabulary => [
        ..._learned,
        ...seedExercises.where((e) => !_learned.contains(e)),
      ];

  /// 마지막 운동이 아직 세트를 받는 중인가.
  ///
  /// 이 값이 참이면 커서는 그 운동 카드 **안**에 있고, 거짓이면 카드 밖에서
  /// 새 운동 이름을 기다린다. 화면에서 커서가 있는 자리가 곧 모드라서
  /// 따로 안내할 것이 없다.
  bool get inBlock => blocks.isNotEmpty && !_closed;
  bool _closed = true;

  bool get naming => !inBlock;

  void addExercise(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    blocks.add(ExerciseBlock(clean));
    _learned.remove(clean);
    _learned.insert(0, clean);
    _closed = false;
    notifyListeners();
  }

  bool addSet(String line) {
    final parsed = parseSetLine(line);
    if (parsed == null || blocks.isEmpty || _closed) return false;
    final set = LoggedSet(kg: parsed.kg, reps: parsed.reps, note: parsed.note);
    blocks.last.sets.addAll(List.generate(parsed.count, (_) => set));
    notifyListeners();
    return true;
  }

  /// 직전 세트 — 키패드의 "이전과 같이" 가 보여줄 것.
  LoggedSet? get lastSet =>
      inBlock && blocks.last.sets.isNotEmpty ? blocks.last.sets.last : null;

  /// 같은 세트를 한 번 더. 운동 기록에서 가장 흔한 동작이라 한 번에 준다.
  void repeatLastSet() {
    final s = lastSet;
    if (s == null) return;
    blocks.last.sets.add(s);
    notifyListeners();
  }

  /// 빈 줄에서 Enter — 이 운동은 여기까지. 목록 밖으로 커서가 빠져나온다.
  /// 노션에서 빈 리스트 항목에 Enter를 치면 리스트를 벗어나는 것과 같다.
  void closeBlock() {
    if (!inBlock) return;
    // 세트를 하나도 안 적은 운동은 남길 이유가 없다.
    if (blocks.last.sets.isEmpty) blocks.removeLast();
    _closed = true;
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
      _closed = true;
      addExercise(text);
    }
  }

  /// 빈 칸에서 지우기 — 마지막 세트부터, 세트가 없으면 운동을 뗀다.
  void backspace() {
    if (blocks.isEmpty) return;
    if (_closed) {
      // 카드 밖이면 마지막 운동 안으로 다시 들어간다.
      _closed = false;
      notifyListeners();
      return;
    }
    final last = blocks.last;
    if (last.sets.isNotEmpty) {
      last.sets.removeLast();
    } else {
      blocks.removeLast();
      _closed = true;
    }
    notifyListeners();
  }

  void clear() {
    blocks.clear();
    _closed = true;
    notifyListeners();
  }

  int get totalSets => blocks.fold(0, (n, b) => n + b.sets.length);

  String asText() => blocks
      .where((b) => b.sets.isNotEmpty)
      .map((b) {
        final lines = <String>[b.name];
        for (var i = 0; i < b.sets.length; i++) {
          final s = b.sets[i];
          lines.add([
            '${i + 1}세트',
            setLabel(kg: s.kg, reps: s.reps),
            if (s.note != null) s.note!,
          ].join(' '));
        }
        return lines.join('\n');
      })
      .join('\n\n');
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

  RoutineEditorController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChanged);
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// 세트를 받는 중이면 시스템 키보드가 있을 자리가 없다 — 키패드가 그 자리다.
  bool get _padMode => _c.inBlock && !_wantText;

  void _onChanged() {
    if (mounted) setState(() {});
    // keyboardType 을 바꾸는 것만으로는 **이미 올라와 있는** 키보드가 내려가지
    // 않는다. 운동 이름을 칠 때 뜬 키보드가 세트 모드에서도 그대로 남아
    // 키패드를 덮었다.
    if (_padMode) SystemChannels.textInput.invokeMethod('TextInput.hide');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 자리를 옮긴 뒤에도 계속 칠 수 있어야 한다.
      if (mounted && !_focus.hasFocus) _focus.requestFocus();
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 160), curve: Curves.easeOut);
      }
    });
  }

  List<String> get _matches =>
      _c.naming ? suggest(_input.text, _c.vocabulary) : const [];

  void _commit([String? pick]) {
    final value = pick ?? _input.text;
    _c.commit(value);
    _input.clear();
    setState(() {
      _highlight = 0;
      _wantText = false;
    });
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
    if (event.logicalKey == LogicalKeyboardKey.backspace && _input.text.isEmpty) {
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
      setState(() => _highlight = (_highlight - 1 + matches.length) % matches.length);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final blocks = _c.blocks;
    // 커서가 카드 안에 있으면 마지막 카드가 입력 줄을 품는다.
    final openIndex = _c.inBlock ? blocks.length - 1 : -1;

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            // 빈 곳을 눌러도 커서를 잃지 않는다.
            onTap: () => _focus.requestFocus(),
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
                  );
                }
                // 카드 밖 — 새 운동 이름 자리
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _buildInput(bold: true),
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
            onKey: _insert,
            onBackspace: _keypadBackspace,
            onSubmit: () => _commit(),
            onText: () {
              setState(() => _wantText = true);
              _focus.requestFocus();
            },
            repeatLabel: _c.lastSet == null
                ? null
                : setLabel(kg: _c.lastSet!.kg, reps: _c.lastSet!.reps),
            onRepeat: _c.repeatLastSet,
          ),
      ],
    );
  }

  Widget _buildInput({bool bold = false}) {
    final platform = Theme.of(context).platform;
    final touch =
        platform == TargetPlatform.iOS || platform == TargetPlatform.android;
    final readOnly = touch && !bold && !_wantText && _c.inBlock;

    return Focus(
      key: _inputKey,
      onKeyEvent: _onKey,
      child: TextField(
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
        onSubmitted: (_) =>
            _commit(_matches.isNotEmpty ? _matches[_highlight] : null),
        onChanged: (_) => setState(() => _highlight = 0),
        style: TextStyle(
          fontSize: bold ? 15.5 : 14,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
        cursorColor: seal,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: bold ? 10 : 6),
          hintText: bold ? '운동 이름' : '100kg 20회 x5',
          hintStyle: TextStyle(
            fontSize: bold ? 15.5 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.22),
          ),
        ),
      ),
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block, this.input});
  final ExerciseBlock block;

  /// 이 운동이 아직 세트를 받는 중이면 입력 줄이 카드 안에 들어온다.
  final Widget? input;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(block.name,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
          ...block.sets.asMap().entries.map((e) => _SetRow(index: e.key, set: e.value)),
          if (input != null)
            Padding(
              padding: EdgeInsets.only(top: block.sets.isEmpty ? 2 : 4, left: 46),
              child: input!,
            ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.index, required this.set});
  final int index;
  final LoggedSet set;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 46,
            child: Text('${index + 1}세트',
                style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.35))),
          ),
          Text(setLabel(kg: set.kg, reps: set.reps),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          if (set.note != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(set.note!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: Colors.black.withValues(alpha: 0.5))),
            ),
          ],
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
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: matches.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final on = i == highlight;
          return Center(
            child: ActionChip(
              label: Text(matches[i]),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                color: on ? seal : Colors.black.withValues(alpha: 0.7),
              ),
              backgroundColor: on ? const Color(0xFFF7E9E6) : Colors.white,
              side: BorderSide(
                color: on ? seal : Colors.black.withValues(alpha: 0.12),
              ),
              visualDensity: VisualDensity.compact,
              onPressed: () => onPick(matches[i]),
            ),
          );
        },
      ),
    );
  }
}
