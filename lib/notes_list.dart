import 'package:flutter/cupertino.dart';

import 'l10n/generated/app_localizations.dart';
import 'notes.dart';
import 'health_summary.dart';
import 'palette.dart';

/// 운동 기록 목록.
///
/// 메모 앱의 짜임을 그대로 따른다 — 큰 제목, 날짜로 묶인 카드, 화면 맨 아래
/// 검색. 검색을 아래에 두는 이유는 한 손으로 든 기기에서 엄지가 닿는 자리가
/// 거기여서다. 헬스장에서 한 손으로 쓰는 앱이라 더 그렇다.
///
/// 치수는 Flutter 의 Cupertino 소스가 쥔 iOS 값을 따른다 — 큰 제목 34pt/w700
/// 자간 +0.38, 본문 17pt 자간 -0.41, 좌우 여백 16, 최소 터치 44.
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
    return q.isEmpty
        ? all
        : all.where((n) => n.searchText.contains(q)).toList();
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
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: widget.store,
              builder: (context, _) {
                final groups = _grouped(_visible, l);
                return CustomScrollView(
                  slivers: [
                    // 큰 제목은 스크롤하면 가운데 작은 제목으로 접힌다. iOS
                    // 목록 화면의 기본 동작이고, 직접 흉내 내면 티가 난다.
                    CupertinoSliverNavigationBar(
                      largeTitle: Text(l.allNotes),
                      border: null,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                        child: Text(
                          l.noteCount(_visible.length),
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (groups.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            _query.text.isEmpty
                                ? l.noNotesYet
                                : l.noSearchResults,
                            style: TextStyle(
                              fontSize: 17,
                              letterSpacing: -0.41,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, i) => _Group(
                          title: groups[i].$1,
                          notes: groups[i].$2,
                          onOpen: widget.onOpen,
                          onDelete: widget.store.delete,
                        ),
                      ),
                    // 검색창에 마지막 줄이 가리지 않도록 띄운다.
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  ],
                );
              },
            ),
          ),
          _SearchBar(
            controller: _query,
            onChanged: (_) => setState(() {}),
            onNew: () => widget.onOpen(widget.store.create()),
          ),
        ],
      ),
    );
  }
}

/// 날짜 묶음 하나. iOS 의 inset grouped 표 한 덩이다.
class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.notes,
    required this.onOpen,
    required this.onDelete,
  });

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
          // 좌우 16 은 iOS 의 기본 여백(_kNavBarEdgePadding)과 같은 값이다.
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
              context,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < notes.length; i++) ...[
                if (i > 0)
                  // 구분선은 글자가 시작하는 자리부터 그린다. 왼쪽 끝까지
                  // 긋는 것은 안드로이드 쪽 관습이다.
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Container(
                      height: 0.5,
                      color: CupertinoColors.separator.resolveFrom(context),
                    ),
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
  const _Row({
    required this.note,
    required this.onOpen,
    required this.onDelete,
  });

  final Note note;
  final void Function(Note) onOpen;
  final void Function(Note) onDelete;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final summary = note.summary(setOrdinal: l.setOrdinal, reps: l.repsCount);

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: CupertinoColors.systemRed,
        child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
      ),
      onDismissed: (_) => onDelete(note),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.zero,
        onPressed: () => onOpen(note),
        child: Container(
          // 최소 44 는 iOS 의 최소 터치 크기(kMinInteractiveDimensionCupertino).
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      note.title ?? l.untitledNote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        // 본문 17pt, 자간 -0.41 — iOS 의 body 다.
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        letterSpacing: -0.41,
                        color: note.title == null
                            ? CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              )
                            : CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    ...[
                      const SizedBox(height: 5),
                      Text(
                        [
                          l.dayLabel(note.createdAt),
                          l.weekdayLabel(note.createdAt),
                          if (summary.isNotEmpty) summary,
                        ].join('  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          // 부제는 footnote 13pt.
                          fontSize: 13,
                          letterSpacing: -0.08,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      HealthSummary(calories: note.calories, showSource: true),
                    ],
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 13,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 화면 맨 아래 검색.
/// 화면 맨 아래 — 검색과 새 기록.
///
/// 메모 앱이 둘을 나란히 둔다. 한 손으로 든 기기에서 엄지가 닿는 자리가
/// 거기이고, 새 기록은 이 화면에서 가장 자주 누르는 것이라 위쪽 구석보다
/// 여기가 맞다.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onNew,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: CupertinoSearchTextField(
                controller: controller,
                onChanged: onChanged,
                placeholder: L.of(context).search,
                borderRadius: BorderRadius.circular(22),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              color: sealTint.resolveFrom(context),
              borderRadius: BorderRadius.circular(22),
              onPressed: onNew,
              child: const Icon(CupertinoIcons.square_pencil, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
