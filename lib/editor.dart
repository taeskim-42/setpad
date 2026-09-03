import 'package:flutter/material.dart';

import 'keypad.dart';
import 'parser.dart';

const seal = Color(0xFFC3372A);

/// 세트 한 줄. 무게와 횟수를 따로 들고 있는다 — 칸이 단위를 알기 때문에
/// "kg" 같은 글자를 사람이 칠 이유가 없다.
class SetRow {
  SetRow({this.kg, this.reps, this.done = false});
  double? kg;
  int? reps;
  bool done;

  bool get empty => kg == null && reps == null;
  SetRow copy() => SetRow(kg: kg, reps: reps);
}

class ExerciseBlock {
  ExerciseBlock(this.name, [List<SetRow>? sets]) : sets = sets ?? [SetRow()];
  final String name;
  final List<SetRow> sets;
  String? note;
}

enum Field { kg, reps }

/// 어느 칸에 숫자가 들어가는지. 이 셋이 곧 커서다.
typedef Cursor = ({int block, int set, Field field});

class RoutineEditorController extends ChangeNotifier {
  final List<ExerciseBlock> blocks = [];
  final List<String> _learned = [];

  Cursor? cursor;

  /// 지금 치고 있는 숫자. 확정 전까지 문자열로 들고 있어야
  /// "1" → "10" → "10." → "10.5" 가 자연스럽다.
  String buffer = '';

  List<String> get vocabulary => [
        ..._learned,
        ...seedExercises.where((e) => !_learned.contains(e)),
      ];

  /// 운동 이름을 받는 중인가. 커서가 없으면 그렇다.
  bool get naming => cursor == null;

  static String plain(num v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  void addExercise(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    blocks.add(ExerciseBlock(clean));
    _learned.remove(clean);
    _learned.insert(0, clean);
    // 새 운동의 첫 세트, 무게 칸부터.
    cursor = (block: blocks.length - 1, set: 0, field: Field.kg);
    buffer = '';
    notifyListeners();
  }

  SetRow? get _current {
    final c = cursor;
    if (c == null) return null;
    return blocks[c.block].sets[c.set];
  }

  /// 직전 세트 — 새 세트를 만들 때 이 값이 미리 들어간다. 대부분의 세트는
  /// 앞 세트와 같고, 다르면 그 자리에서 고치면 된다.
  SetRow? previousOf(int block, int set) =>
      set > 0 ? blocks[block].sets[set - 1] : null;

  void tap(int block, int set, Field field) {
    _flush();
    cursor = (block: block, set: set, field: field);
    final row = blocks[block].sets[set];
    final value = field == Field.kg ? row.kg : row.reps;
    buffer = value == null ? '' : plain(value);
    notifyListeners();
  }

  void press(String digit) {
    if (cursor == null) return;
    if (digit == '.' && buffer.contains('.')) return;
    if (digit == '.' && buffer.isEmpty) buffer = '0';
    buffer += digit;
    _apply();
    notifyListeners();
  }

  void backspace() {
    if (cursor == null || buffer.isEmpty) return;
    buffer = buffer.substring(0, buffer.length - 1);
    _apply();
    notifyListeners();
  }

  /// 원판은 2.5kg 단위로 붙는다. 횟수는 하나씩.
  void adjust(int direction) {
    final c = cursor;
    final row = _current;
    if (c == null || row == null) return;
    if (c.field == Field.kg) {
      final next = ((row.kg ?? 0) + direction * 2.5).clamp(0, 999).toDouble();
      row.kg = next == 0 ? null : next;
      buffer = row.kg == null ? '' : plain(row.kg!);
    } else {
      final next = ((row.reps ?? 0) + direction).clamp(0, 999).toInt();
      row.reps = next == 0 ? null : next;
      buffer = row.reps == null ? '' : plain(row.reps!);
    }
    notifyListeners();
  }

  /// 세트 완료 표시를 손으로 뒤집는다. 자동으로 켜지지만, 잘못 눌렀을 때
  /// 되돌릴 방법이 있어야 한다.
  void toggleDone(int block, int set) {
    final row = blocks[block].sets[set];
    if (row.empty) return;
    row.done = !row.done;
    notifyListeners();
  }

  void _apply() {
    final c = cursor;
    final row = _current;
    if (c == null || row == null) return;
    final n = buffer.isEmpty ? null : double.tryParse(buffer);
    if (c.field == Field.kg) {
      row.kg = n;
    } else {
      row.reps = n?.round();
    }
  }

  void _flush() {
    _apply();
    buffer = '';
  }

  /// 무게 → 횟수 → (다음 세트를 만들고) 무게. 한 방향으로만 흘러서
  /// 버튼 하나로 세트가 쌓인다.
  void next() {
    final c = cursor;
    if (c == null) return;
    if (c.field == Field.kg) {
      _flush();
      final row = blocks[c.block].sets[c.set];
      cursor = (block: c.block, set: c.set, field: Field.reps);
      buffer = row.reps == null ? '' : plain(row.reps!);
      notifyListeners();
      return;
    }
    completeSet();
  }

  /// 이 세트 끝. 다음 세트를 만들고 직전 값을 채워 둔다.
  void completeSet() {
    final c = cursor;
    if (c == null) return;
    _flush();
    final block = blocks[c.block];
    final row = block.sets[c.set];
    if (row.empty) return;
    row.done = true;

    if (c.set == block.sets.length - 1) block.sets.add(row.copy());
    final nextRow = block.sets[c.set + 1];
    cursor = (block: c.block, set: c.set + 1, field: Field.kg);
    buffer = nextRow.kg == null ? '' : plain(nextRow.kg!);
    notifyListeners();
  }

  /// 이 운동 끝. 채우다 만 세트는 남기지 않는다.
  void closeBlock() {
    final c = cursor;
    if (c == null) return;
    _flush();
    final block = blocks[c.block];
    block.sets.removeWhere((s) => s.empty);
    if (block.sets.isEmpty) blocks.removeAt(c.block);
    cursor = null;
    buffer = '';
    notifyListeners();
  }

  void removeSet(int block, int set) {
    final b = blocks[block];
    if (b.sets.length <= 1) return;
    b.sets.removeAt(set);
    final c = cursor;
    if (c != null && c.block == block && c.set >= b.sets.length) {
      cursor = (block: block, set: b.sets.length - 1, field: Field.kg);
      buffer = '';
    }
    notifyListeners();
  }

  void setNote(int block, String? note) {
    blocks[block].note =
        (note == null || note.trim().isEmpty) ? null : note.trim();
    notifyListeners();
  }

  void clear() {
    blocks.clear();
    cursor = null;
    buffer = '';
    notifyListeners();
  }

  int get totalSets =>
      blocks.fold(0, (n, b) => n + b.sets.where((s) => !s.empty).length);

  String asText() => blocks
      .map((b) {
        final rows = b.sets.where((s) => !s.empty).toList();
        if (rows.isEmpty) return null;
        final lines = <String>[b.name];
        for (var i = 0; i < rows.length; i++) {
          lines.add('${i + 1}세트 ${setLabel(kg: rows[i].kg, reps: rows[i].reps)}');
        }
        if (b.note != null) lines.add('— ${b.note}');
        return lines.join('\n');
      })
      .whereType<String>()
      .join('\n\n');
}

class RoutineEditor extends StatefulWidget {
  const RoutineEditor({super.key, required this.controller});
  final RoutineEditorController controller;

  @override
  State<RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends State<RoutineEditor> {
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
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
    _name.dispose();
    _nameFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 160), curve: Curves.easeOut);
      }
    });
  }

  List<String> get _matches =>
      _c.naming ? suggest(_name.text, _c.vocabulary) : const [];

  void _addExercise([String? pick]) {
    final value = (pick ?? _name.text).trim();
    if (value.isEmpty) return;
    _c.addExercise(value);
    _name.clear();
    setState(() => _highlight = 0);
    // 이름을 받았으면 시스템 키보드는 물러난다 — 이제 숫자만 친다.
    _nameFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            itemCount: _c.blocks.length + 1,
            itemBuilder: (context, i) {
              if (i < _c.blocks.length) {
                return _BlockCard(controller: _c, index: i, block: _c.blocks[i]);
              }
              return _NameField(
                controller: _name,
                focus: _nameFocus,
                enabled: _c.naming,
                onSubmit: () =>
                    _addExercise(matches.isNotEmpty ? matches[_highlight] : null),
                onChanged: (_) => setState(() => _highlight = 0),
              );
            },
          ),
        ),
        if (matches.isNotEmpty)
          _Suggestions(
            matches: matches,
            highlight: _highlight,
            onPick: _addExercise,
          ),
        if (!_c.naming)
          NumberPad(
            onDigit: _c.press,
            onBackspace: _c.backspace,
            onNext: _c.next,
            onDone: _c.closeBlock,
            onAdjust: _c.adjust,
            nextLabel: _c.cursor?.field == Field.kg ? '횟수 →' : '세트 완료',
            stepLabel: _c.cursor?.field == Field.kg ? '2.5' : '1',
          ),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.focus,
    required this.enabled,
    required this.onSubmit,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool enabled;
  final VoidCallback onSubmit;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: TextField(
        controller: controller,
        focusNode: focus,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onSubmit(),
        onChanged: onChanged,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        cursorColor: seal,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          hintText: '운동 이름 (예: 벤)',
          hintStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.22),
          ),
        ),
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({
    required this.controller,
    required this.index,
    required this.block,
  });

  final RoutineEditorController controller;
  final int index;
  final ExerciseBlock block;

  @override
  Widget build(BuildContext context) {
    final cursor = controller.cursor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const _HeaderRow(),
          for (var i = 0; i < block.sets.length; i++)
            _SetLine(
              number: i + 1,
              row: block.sets[i],
              previous: controller.previousOf(index, i),
              active: cursor != null && cursor.block == index && cursor.set == i
                  ? cursor.field
                  : null,
              onTapKg: () => controller.tap(index, i, Field.kg),
              onTapReps: () => controller.tap(index, i, Field.reps),
              onToggle: () => controller.toggleDone(index, i),
              onDelete: block.sets.length > 1
                  ? () => controller.removeSet(index, i)
                  : null,
            ),
          if (block.note != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 2),
              child: Text(block.note!,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black.withValues(alpha: 0.5))),
            ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Colors.black.withValues(alpha: 0.32),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, left: 2, right: 2),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('세트', style: style)),
          Expanded(flex: 3, child: Text('이전', style: style)),
          Expanded(
              flex: 2,
              child: Text('kg', style: style, textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('회', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _SetLine extends StatelessWidget {
  const _SetLine({
    required this.number,
    required this.row,
    required this.previous,
    required this.active,
    required this.onTapKg,
    required this.onTapReps,
    required this.onToggle,
    this.onDelete,
  });

  final int number;
  final SetRow row;
  final SetRow? previous;

  /// 이 줄에서 어느 칸이 커서를 갖고 있는가.
  final Field? active;
  final VoidCallback onTapKg;
  final VoidCallback onTapReps;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final prevText = previous == null || previous!.empty
        ? '—'
        : setLabel(kg: previous!.kg, reps: previous!.reps);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: row.done ? const Color(0xFFF1F7F4) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('$number',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.45))),
          ),
          Expanded(
            flex: 3,
            child: Text(prevText,
                style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.black.withValues(alpha: 0.3))),
          ),
          Expanded(
            flex: 2,
            child: _Cell(
              value: row.kg == null
                  ? null
                  : RoutineEditorController.plain(row.kg!),
              active: active == Field.kg,
              onTap: onTapKg,
            ),
          ),
          Expanded(
            flex: 2,
            child: _Cell(
              value: row.reps?.toString(),
              active: active == Field.reps,
              onTap: onTapReps,
            ),
          ),
          SizedBox(
            width: 34,
            child: GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                row.done ? Icons.check_circle : Icons.check_circle_outline,
                size: 21,
                color: row.done
                    ? const Color(0xFF1E7A5A)
                    : Colors.black.withValues(alpha: 0.16),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: onDelete == null
                ? null
                : IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 16,
                    color: Colors.black.withValues(alpha: 0.22),
                    icon: const Icon(Icons.close),
                    onPressed: onDelete,
                  ),
          ),
        ],
      ),
    );
  }
}

/// 숫자가 들어가는 칸. 눌러서 커서를 옮긴다.
class _Cell extends StatelessWidget {
  const _Cell({required this.value, required this.active, required this.onTap});
  final String? value;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF7E9E6) : const Color(0xFFF2F2F4),
          borderRadius: BorderRadius.circular(6),
          border: active ? Border.all(color: seal, width: 1.5) : null,
        ),
        child: Text(
          value ?? '',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: active ? seal : Colors.black.withValues(alpha: 0.85),
          ),
        ),
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
        border:
            Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
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
                  color: on ? seal : Colors.black.withValues(alpha: 0.12)),
              visualDensity: VisualDensity.compact,
              onPressed: () => onPick(matches[i]),
            ),
          );
        },
      ),
    );
  }
}
