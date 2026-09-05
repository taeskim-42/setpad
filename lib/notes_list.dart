import 'package:flutter/material.dart';

import 'editor.dart' show seal;
import 'l10n/generated/app_localizations.dart';
import 'notes.dart';

/// 메모 목록. 메모 앱과 같은 짜임 — 날짜로 묶고, 검색은 화면 맨 아래에 둔다.
///
/// 검색을 아래에 두는 이유는 한 손으로 드는 기기에서 엄지가 닿는 자리가
/// 거기여서다. 헬스장에서 한 손에 기기를 들고 쓰는 앱이라 더 그렇다.
class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key, required this.store, required this.onOpen});

  final NotesStore store;
  final void Function(Note) onOpen;

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Note> get _visible {
    final q = _query.text.trim().toLowerCase();
    final all = widget.store.notes;
    return q.isEmpty ? all : all.where((n) => n.searchText.contains(q)).toList();
  }

  /// 이전 7일 / 이전 30일 / 그 앞은 달로. 메모 앱과 같은 구간이다.
  List<(String, List<Note>)> _grouped(List<Note> notes, L l) {
    final now = DateTime.now();
    final week = <Note>[], month = <Note>[];
    final older = <String, List<Note>>{};
    for (final n in notes) {
      final days = now.difference(n.updatedAt).inDays;
      if (days < 7) {
        week.add(n);
      } else if (days < 30) {
        month.add(n);
      } else {
        older.putIfAbsent(l.monthLabel(n.updatedAt.month), () => []).add(n);
      }
    }
    return [
      if (week.isNotEmpty) (l.previous7Days, week),
      if (month.isNotEmpty) (l.previous30Days, month),
      ...older.entries.map((e) => (e.key, e.value)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFE9E9EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE9E9EC),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Column(
          children: [
            Text(l.allNotes,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
            ListenableBuilder(
              listenable: widget.store,
              builder: (context, _) => Text(
                l.noteCount(widget.store.notes.length),
                style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.45)),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListenableBuilder(
              listenable: widget.store,
              builder: (context, _) {
                final groups = _grouped(_visible, l);
                if (groups.isEmpty) {
                  return Center(
                    child: Text(
                      _query.text.isEmpty ? l.noNotesYet : l.noSearchResults,
                      style: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
                    ),
                  );
                }
                return ListView.builder(
                  // 하단 검색바에 마지막 항목이 가리지 않도록 띄운다.
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 96),
                  itemCount: groups.length,
                  itemBuilder: (context, i) => _Group(
                    title: groups[i].$1,
                    notes: groups[i].$2,
                    onOpen: widget.onOpen,
                    onDelete: widget.store.delete,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: _SearchBar(
        controller: _query,
        onChanged: (_) => setState(() {}),
        onNew: () => widget.onOpen(widget.store.create()),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.notes, required this.onOpen, required this.onDelete});

  final String title;
  final List<Note> notes;
  final void Function(Note) onOpen;
  final void Function(Note) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
          child: Text(title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (var i = 0; i < notes.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Divider(height: 1, thickness: 0.5, color: Colors.black.withValues(alpha: 0.08)),
                  ),
                _Row(note: notes[i], onOpen: onOpen, onDelete: onDelete),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.note, required this.onOpen, required this.onDelete});

  final Note note;
  final void Function(Note) onOpen;
  final void Function(Note) onDelete;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final summary = [
      note.summary(setOrdinal: l.setOrdinal, reps: l.repsCount),
      // 워치가 잰 값이 있을 때만. 앱이 추정한 숫자가 아니다.
      if (note.calories != null) l.kcal(note.calories!.round()),
    ].where((s) => s.isNotEmpty).join(' · ');
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: seal,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(note),
      child: InkWell(
        onTap: () => onOpen(note),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title ?? l.untitledNote,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: note.title == null ? Colors.black.withValues(alpha: 0.35) : null,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(l.dayLabel(note.updatedAt),
                      style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.45))),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.45))),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 화면 맨 아래 — 검색과 새 운동 기록. 두 화면이 같은 것을 쓴다.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged, required this.onNew});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, size: 20, color: Colors.black.withValues(alpha: 0.45)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: l.search,
                        hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: l.newNote,
            child: GestureDetector(
              onTap: onNew,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: seal, shape: BoxShape.circle),
                child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
