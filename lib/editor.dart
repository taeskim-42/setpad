import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'parser.dart';

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

/// 에디터의 상태. 화면과 떼어 둔 이유는 상위 화면(복사 버튼 등)이
/// 같은 상태를 봐야 하고, 위젯 테스트에서 직접 찔러볼 수 있어야 해서다.
class RoutineEditorController extends ChangeNotifier {
  final List<ExerciseBlock> blocks = [];
  final List<String> _learned = [];

  /// 이 기기에서 실제로 친 이름이 씨앗 목록보다 앞선다.
  List<String> get vocabulary => [
        ..._learned,
        ...seedExercises.where((e) => !_learned.contains(e)),
      ];

  /// 이름을 받는 중인가, 세트를 받는 중인가. 지금 말이 되는 쪽은 언제나
  /// 하나뿐이라 모드를 누를 버튼이 없다.
  bool get naming => blocks.isEmpty || blocks.last.sets.isNotEmpty;

  void addExercise(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    blocks.add(ExerciseBlock(clean));
    _learned.remove(clean);
    _learned.insert(0, clean);
    notifyListeners();
  }

  bool addSet(String line) {
    final parsed = parseSetLine(line);
    if (parsed == null || blocks.isEmpty) return false;
    final set = LoggedSet(kg: parsed.kg, reps: parsed.reps, note: parsed.note);
    blocks.last.sets.addAll(List.generate(parsed.count, (_) => set));
    notifyListeners();
    return true;
  }

  /// 입력이 무엇이든 지금 맥락에서 맞는 쪽으로 넣는다. 세트를 받는 중인데
  /// 숫자가 없는 줄이 오면 그 운동은 끝났고 다음 운동이라는 뜻이다.
  void commit(String input) {
    final text = input.trim();
    if (text.isEmpty) return;
    if (naming) {
      addExercise(text);
    } else if (!addSet(text)) {
      addExercise(text);
    }
  }

  /// 빈 칸에서 지우기 — 마지막 세트부터, 세트가 없으면 운동을 떼어낸다.
  void backspace() {
    if (blocks.isEmpty) return;
    final last = blocks.last;
    if (last.sets.isNotEmpty) {
      last.sets.removeLast();
    } else {
      blocks.removeLast();
    }
    notifyListeners();
  }

  void clear() {
    blocks.clear();
    notifyListeners();
  }

  int get totalSets => blocks.fold(0, (n, b) => n + b.sets.length);

  /// 복사해서 어디에든 붙일 수 있는 형태.
  String asText() => blocks
      .where((b) => b.sets.isNotEmpty)
      .map((b) {
        final lines = <String>[b.name];
        for (var i = 0; i < b.sets.length; i++) {
          final s = b.sets[i];
          final parts = [
            '${i + 1}세트',
            setLabel(kg: s.kg, reps: s.reps),
            if (s.note != null) s.note!,
          ];
          lines.add(parts.join(' '));
        }
        return lines.join('\n');
      })
      .join('\n\n');
}

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
  int _highlight = 0;

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

  void _onChanged() {
    if (mounted) setState(() {});
    // 새로 쌓인 줄이 바로 보이도록.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<String> get _matches =>
      _c.naming ? suggest(_input.text, _c.vocabulary) : const [];

  void _commit([String? pick]) {
    final value = pick ?? _input.text;
    if (value.trim().isEmpty) return;
    _c.commit(value);
    _input.clear();
    setState(() => _highlight = 0);
    _focus.requestFocus();
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
    final naming = _c.naming;

    return Column(
      children: [
        Expanded(
          child: _c.blocks.isEmpty
              ? const _EmptyHint()
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _c.blocks.length,
                  itemBuilder: (context, i) => _BlockView(block: _c.blocks[i]),
                ),
        ),
        if (matches.isNotEmpty)
          _Suggestions(
            matches: matches,
            highlight: _highlight,
            onPick: (name) => _commit(name),
          ),
        _InputBar(
          controller: _input,
          focus: _focus,
          naming: naming,
          onKey: _onKey,
          onSubmit: () => _commit(matches.isNotEmpty ? matches[_highlight] : null),
          onChanged: (_) => setState(() => _highlight = 0),
          totalSets: _c.totalSets,
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '운동 이름부터',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"벤"만 쳐도 벤치프레스가 뜹니다.\n고른 다음 "100kg 20회 x5"처럼 치면\n세트가 쌓입니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.7,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      );
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block});
  final ExerciseBlock block;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
          Text(
            block.name,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
          ),
          if (block.sets.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '무게와 횟수를 적어 주세요 · 예: 100kg 20회',
                style: TextStyle(fontSize: 12.5, color: Colors.black.withValues(alpha: 0.35)),
              ),
            )
          else
            ...block.sets.asMap().entries.map((e) => _SetRow(index: e.key, set: e.value)),
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
            child: Text(
              '${index + 1}세트',
              style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.35)),
            ),
          ),
          Text(
            setLabel(kg: set.kg, reps: set.reps),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          if (set.note != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                set.note!,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: Colors.black.withValues(alpha: 0.5)),
              ),
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
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: matches.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final on = i == highlight;
          return ActionChip(
            label: Text(matches[i]),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: on ? FontWeight.w800 : FontWeight.w500,
              color: on ? const Color(0xFFC3372A) : Colors.black.withValues(alpha: 0.7),
            ),
            backgroundColor: on ? const Color(0xFFF7E9E6) : Colors.white,
            side: BorderSide(
              color: on ? const Color(0xFFC3372A) : Colors.black.withValues(alpha: 0.12),
            ),
            onPressed: () => onPick(matches[i]),
          );
        },
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focus,
    required this.naming,
    required this.onKey,
    required this.onSubmit,
    required this.onChanged,
    required this.totalSets,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool naming;
  final KeyEventResult Function(FocusNode, KeyEvent) onKey;
  final VoidCallback onSubmit;
  final ValueChanged<String> onChanged;
  final int totalSets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Focus(
                  onKeyEvent: onKey,
                  child: TextField(
                    controller: controller,
                    focusNode: focus,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onSubmit(),
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      hintText: naming ? '운동 이름 (예: 벤)' : '100kg 20회 x5',
                      hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC3372A),
                  minimumSize: const Size(56, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Icon(Icons.keyboard_return, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            naming
                ? '이름을 치고 Enter. 세트가 끝난 운동 위에 다음 운동을 이어 치면 됩니다.'
                : 'Enter로 세트 추가 · 빈 칸에서 지우기를 누르면 마지막 세트가 빠집니다'
                    '${totalSets > 0 ? ' · 총 $totalSets세트' : ''}',
            style: TextStyle(fontSize: 11.5, color: Colors.black.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}
