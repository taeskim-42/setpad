import 'dart:convert';
import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'editor.dart';
import 'l10n/generated/app_localizations.dart';
import 'notes.dart';
import 'palette.dart';
import 'parser.dart';
import 'record_query.dart' show exerciseKey;
import 'record_ai.dart';

/// Long histories go to the server in pieces one answer can hold, cut at blank lines (one workout is
/// usually one paragraph), then at line ends, then anywhere.
List<String> importChunks(String text, {int size = 1500}) {
  List<String> pack(Iterable<String> parts, String sep) {
    final out = <String>[];
    for (final part in parts) {
      if (out.isNotEmpty &&
          out.last.length + sep.length + part.length <= size) {
        out.last = '${out.last}$sep$part';
      } else {
        out.add(part);
      }
    }
    return out;
  }

  return pack([
    for (final p in text.split(RegExp(r'\n\s*\n')).map((p) => p.trim()))
      if (p.isEmpty)
        ...const <String>[]
      else if (p.length <= size)
        p
      else
        ...pack([
          for (final line in p.split('\n'))
            for (var i = 0; i < line.length; i += size)
              line.substring(i, min(i + size, line.length)),
        ], '\n'),
  ], '\n\n');
}

class WorkoutImportPage extends StatefulWidget {
  const WorkoutImportPage({super.key, required this.store, required this.ai});

  final NotesStore store;
  final RecordAi ai;

  @override
  State<WorkoutImportPage> createState() => _WorkoutImportPageState();
}

class _WorkoutImportPageState extends State<WorkoutImportPage> {
  // Each piece and each screenshot is one input-help call; together they stay within a free day (10).
  static const _maxText = 6000, _maxImages = 5;
  final _text = TextEditingController();
  final _picker = ImagePicker();
  final _images = <XFile>[];
  List<_ImportWorkout>? _workouts;
  List<String> _unparsed = [];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    _disposeWorkouts();
    super.dispose();
  }

  void _disposeWorkouts() {
    for (final workout in _workouts ?? const <_ImportWorkout>[]) {
      workout.dispose();
    }
  }

  void _setError(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _paste() async {
    final value = await Clipboard.getData(Clipboard.kTextPlain);
    if (value?.text == null || !mounted) return;
    final next = [
      _text.text.trim(),
      value!.text!.trim(),
    ].where((s) => s.isNotEmpty).join('\n\n');
    if (next.length > _maxText) {
      _setError(L.of(context).workoutImportTextLimit);
      return;
    }
    setState(() {
      _text.text = next;
      _error = null;
    });
  }

  Future<void> _chooseTextFiles() async {
    final limitMessage = L.of(context).workoutImportTextLimit;
    try {
      final files = await openFiles(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Workout text',
            extensions: ['txt', 'md', 'text', 'csv'],
            // iOS picks by type, not extension, and refuses a group without one.
            uniformTypeIdentifiers: [
              'public.plain-text',
              'public.comma-separated-values-text',
              'net.daringfireball.markdown',
            ],
          ),
        ],
      );
      if (files.isEmpty || !mounted) return;
      final parts = <String>[
        _text.text.trim(),
        for (final file in files)
          '--- ${file.name} ---\n${utf8.decode(await file.readAsBytes(), allowMalformed: true).replaceAll('\u0000', '')}',
      ];
      final next = parts.where((part) => part.trim().isNotEmpty).join('\n\n');
      if (next.length > _maxText) {
        if (mounted) _setError(limitMessage);
        return;
      }
      setState(() {
        _text.text = next;
        _error = null;
      });
    } catch (_) {
      if (mounted) _setError(L.of(context).workoutImportFailed);
    }
  }

  Future<void> _chooseImages() async {
    try {
      final files = await _picker.pickMultiImage(
        limit: _maxImages,
        imageQuality: 82,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (!mounted || files.isEmpty) return;
      if (_images.length + files.length > _maxImages) {
        _setError(L.of(context).workoutImportImageLimit);
        return;
      }
      setState(() {
        _images.addAll(files);
        _error = null;
      });
    } catch (_) {
      if (mounted) _setError(L.of(context).workoutImportFailed);
    }
  }

  String? _mime(XFile file) {
    final mime = file.mimeType;
    if (const {'image/jpeg', 'image/png', 'image/webp'}.contains(mime)) {
      return mime;
    }
    return switch (file.name.toLowerCase().split('.').last) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
  }

  Future<void> _analyze() async {
    final l = L.of(context);
    final locale = l.localeName;
    if (!widget.ai.allowed) {
      _setError(l.workoutImportAiOff);
      return;
    }
    final text = _text.text.trim();
    if (text.isEmpty && _images.isEmpty) {
      _setError(l.workoutImportEmpty);
      return;
    }
    if (text.length > _maxText) {
      _setError(l.workoutImportTextLimit);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    _disposeWorkouts();
    final workouts = <_ImportWorkout>[];
    final unparsed = <String>[];
    final sources = <Future<Map<String, Object?>> Function()>[
      for (final piece in importChunks(text))
        () => widget.ai.importWorkout(locale: locale, text: piece),
      for (final image in _images)
        () async => widget.ai.importWorkout(
          locale: locale,
          image: await image.readAsBytes(),
          mime: _mime(image),
        ),
    ];
    // One source that cannot be read does not cost the others.
    var failed = 0;
    var spent = false;
    for (final read in sources) {
      if (spent) {
        failed++;
        continue;
      }
      try {
        _readResult(await read(), workouts, unparsed);
      } on RecordAiException catch (e) {
        failed++;
        spent = e.status == RecordAiStatus.quotaExceeded;
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) {
      for (final workout in workouts) {
        workout.dispose();
      }
      return;
    }
    setState(() {
      _busy = false;
      if (workouts.isEmpty) {
        _error = spent ? l.inputQuotaSpent : l.workoutImportFailed;
        return;
      }
      _workouts = workouts;
      _unparsed = unparsed;
      _error = failed == 0
          ? null
          : [
              l.workoutImportPartial(failed),
              if (spent) l.inputQuotaSpent,
            ].join('\n');
    });
  }

  void _readResult(
    Map<String, Object?> result,
    List<_ImportWorkout> workouts,
    List<String> unparsed,
  ) {
    final sessions = result['sessions'];
    final unresolved = result['unparsed'];
    if (sessions is! List || unresolved is! List) {
      throw const FormatException('Invalid import response');
    }
    // Nothing from a reply that breaks halfway: its sessions join only when all of them read.
    final found = <_ImportWorkout>[];
    try {
      for (final row in sessions) {
        if (row is! Map || row['exercises'] is! List) {
          throw const FormatException('Invalid workout');
        }
        final dateText = row['date'];
        final date = dateText == null
            ? null
            : dateText is String
            ? DateTime.tryParse(dateText)
            : null;
        if (dateText != null && date == null) {
          throw const FormatException('Invalid date');
        }
        final exercises = <_ImportExercise>[];
        for (final exercise in row['exercises'] as List) {
          if (exercise is! Map ||
              exercise['name'] is! String ||
              exercise['sets'] is! List) {
            throw const FormatException('Invalid exercise');
          }
          final sets = <_ImportSet>[];
          for (final rawSet in exercise['sets'] as List) {
            if (rawSet is! Map ||
                rawSet['unit'] is! String ||
                rawSet['notes'] is! List ||
                rawSet['done'] is! bool ||
                rawSet['value'] != null && rawSet['value'] is! num ||
                rawSet['reps'] != null && rawSet['reps'] is! num) {
              throw const FormatException('Invalid set');
            }
            final unit = rawSet['unit'] as String;
            if (!const {
              'kg',
              'lb',
              'reps',
              's',
              'min',
              'km',
              'm',
              'mi',
              '',
            }.contains(unit)) {
              throw const FormatException('Invalid unit');
            }
            sets.add(
              _ImportSet(
                value: (rawSet['value'] as num?)?.toDouble(),
                unit: unit,
                reps: (rawSet['reps'] as num?)?.toInt(),
                notes: [
                  for (final note in rawSet['notes'] as List)
                    if (note is String) note,
                ],
                done: rawSet['done'] as bool,
              ),
            );
          }
          exercises.add(_ImportExercise(exercise['name'] as String, sets));
        }
        found.add(_ImportWorkout(date: date, exercises: exercises));
      }
    } catch (_) {
      for (final workout in found) {
        workout.dispose();
      }
      rethrow;
    }
    workouts.addAll(found);
    unparsed.addAll(unresolved.whereType<String>());
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _possibleDuplicate(_ImportWorkout workout) {
    final date = workout.date;
    if (date == null) return false;
    final names = {for (final e in workout.exercises) exerciseKey(e.name.text)};
    return widget.store.notes.any(
      (note) =>
          _sameDay(note.createdAt, date) &&
          note.blocks.any((block) => names.contains(exerciseKey(block.name))),
    );
  }

  Future<void> _chooseDate(_ImportWorkout workout) async {
    var selected = workout.date ?? DateTime.now();
    final result = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(L.of(context).cancel),
                ),
                CupertinoButton(
                  key: const ValueKey('workout-import-date-confirm'),
                  onPressed: () => Navigator.pop(context, selected),
                  child: Text(L.of(context).ok),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selected,
                minimumDate: DateTime(2000),
                maximumDate: DateTime.now().add(const Duration(days: 366)),
                onDateTimeChanged: (value) => selected = value,
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) setState(() => workout.date = result);
  }

  void _save() {
    final workouts = _workouts ?? const <_ImportWorkout>[];
    if (workouts.isEmpty || workouts.any((workout) => workout.date == null)) {
      _setError(L.of(context).workoutImportMissingDate);
      return;
    }
    if (_unparsed.isNotEmpty) {
      _setError(L.of(context).workoutImportUnparsed);
      return;
    }
    final prepared = <({DateTime date, List<ExerciseBlock> blocks})>[];
    for (final workout in workouts) {
      final blocks = <ExerciseBlock>[];
      for (final exercise in workout.exercises) {
        final name = exercise.name.text.trim();
        if (name.isEmpty) continue;
        final sets = <LoggedSet>[];
        for (final set in exercise.sets) {
          final source = set.value.text.trim();
          final parsed = source.isEmpty ? null : parseSetLine(source);
          final notes = set.notes.text
              .split('·')
              .map((note) => note.trim())
              .where((note) => note.isNotEmpty)
              .toList();
          final parsedNote = parsed?.note?.trim();
          if (parsedNote != null && parsedNote.isNotEmpty) {
            notes.add(parsedNote);
          }
          if (parsed == null && source.isNotEmpty) notes.add(source);
          if (source.isEmpty && notes.isEmpty) continue;
          sets.add(
            LoggedSet(
              value: parsed?.value,
              unit: parsed?.unit ?? widget.store.weightUnit,
              reps: parsed?.reps,
              notes: notes,
              done: set.done,
            ),
          );
        }
        blocks.add(ExerciseBlock(name, sets));
      }
      if (blocks.isEmpty) {
        _setError(L.of(context).workoutImportEmpty);
        return;
      }
      final date = workout.date!;
      prepared.add((
        date: DateTime(date.year, date.month, date.day, 12),
        blocks: blocks,
      ));
    }
    for (final workout in prepared) {
      widget.store.create(at: workout.date, blocks: workout.blocks);
    }
    Navigator.of(context).pop();
  }

  Widget _button(String title, IconData icon, VoidCallback onPressed) =>
      CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        onPressed: _busy ? null : onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      );

  Widget _inputView(L l) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
    children: [
      Text(
        l.workoutImportHint,
        style: TextStyle(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          height: 1.4,
        ),
      ),
      const SizedBox(height: 12),
      CupertinoTextField(
        key: const ValueKey('workout-import-text'),
        controller: _text,
        minLines: 7,
        maxLines: 14,
        textInputAction: TextInputAction.newline,
        placeholder: l.workoutImportTextPlaceholder,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
        onChanged: (_) => setState(() => _error = null),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: Text(
          '${_text.text.length}/$_maxText',
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
      ),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          _button(
            l.workoutImportPaste,
            CupertinoIcons.doc_on_clipboard,
            _paste,
          ),
          _button(
            l.workoutImportTextFiles,
            CupertinoIcons.folder,
            _chooseTextFiles,
          ),
          _button(
            l.workoutImportScreenshots,
            CupertinoIcons.photo,
            _chooseImages,
          ),
        ],
      ),
      if (_images.isNotEmpty) ...[
        const SizedBox(height: 8),
        for (final image in _images)
          Row(
            children: [
              const Icon(CupertinoIcons.photo, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  image.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: _busy
                    ? null
                    : () => setState(() => _images.remove(image)),
                child: const Icon(CupertinoIcons.xmark, size: 15),
              ),
            ],
          ),
      ],
      if (_busy)
        const Padding(
          padding: EdgeInsets.only(top: 20),
          child: Center(child: CupertinoActivityIndicator()),
        ),
    ],
  );

  Widget _previewView(L l) {
    final workouts = _workouts!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Text(
          l.workoutImportReview,
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: CupertinoButton(
            key: const ValueKey('workout-import-edit-sources'),
            padding: EdgeInsets.zero,
            onPressed: () => setState(() {
              _disposeWorkouts();
              _workouts = null;
              _unparsed = [];
              _error = null;
            }),
            child: Text(l.workoutImportEditSources),
          ),
        ),
        if (_unparsed.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l.workoutImportUnparsed,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          for (final (index, line) in _unparsed.indexed)
            Row(
              key: ValueKey('workout-import-unparsed-$index'),
              children: [
                Expanded(
                  child: Text(
                    '• $line',
                    style: TextStyle(color: seal.resolveFrom(context)),
                  ),
                ),
                CupertinoButton(
                  key: ValueKey('workout-import-unparsed-dismiss-$index'),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  onPressed: () => setState(() => _unparsed.removeAt(index)),
                  child: Text(l.workoutImportRemove),
                ),
              ],
            ),
        ],
        const SizedBox(height: 12),
        for (final workout in workouts.indexed)
          _workoutCard(l, workout.$2, workout.$1),
      ],
    );
  }

  Widget _workoutCard(L l, _ImportWorkout workout, int index) {
    final date = workout.date;
    return Container(
      key: ValueKey('workout-import-session-$index'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.zero,
                  onPressed: () => _chooseDate(workout),
                  child: Text(
                    date == null
                        ? l.workoutImportChooseDate
                        : DateFormat.yMMMd(l.localeName).format(date),
                    style: TextStyle(
                      color: date == null
                          ? seal.resolveFrom(context)
                          : CupertinoColors.label.resolveFrom(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: () => setState(() {
                  _workouts!.remove(workout);
                  workout.dispose();
                }),
                child: Icon(
                  CupertinoIcons.delete,
                  size: 17,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
          if (date == null)
            Text(
              l.workoutImportMissingDate,
              style: TextStyle(fontSize: 12, color: seal.resolveFrom(context)),
            ),
          if (_possibleDuplicate(workout))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l.workoutImportDuplicate,
                style: TextStyle(
                  fontSize: 12,
                  color: seal.resolveFrom(context),
                ),
              ),
            ),
          for (final exercise in workout.exercises)
            _exerciseCard(l, exercise, workout),
          CupertinoButton(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
            onPressed: () =>
                setState(() => workout.exercises.add(_ImportExercise('', []))),
            child: Text(l.workoutImportAddExercise),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(
    L l,
    _ImportExercise exercise,
    _ImportWorkout workout,
  ) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: exercise.name,
                placeholder: l.exerciseNameHint,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.only(left: 4),
              minimumSize: const Size(38, 44),
              onPressed: () => setState(() {
                workout.exercises.remove(exercise);
                exercise.dispose();
              }),
              child: Icon(
                CupertinoIcons.delete,
                size: 16,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
        for (final set in exercise.sets)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(34, 40),
                  onPressed: () => setState(() => set.done = !set.done),
                  child: Icon(
                    set.done
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    size: 19,
                    color: set.done
                        ? seal.resolveFrom(context)
                        : CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      CupertinoTextField(
                        controller: set.value,
                        placeholder: l.setInputHint,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      if (set.notes.text.isNotEmpty || set.notesHasInput)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: CupertinoTextField(
                            controller: set.notes,
                            placeholder: l.noteHint,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            style: const TextStyle(fontSize: 13),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemBackground
                                  .resolveFrom(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.only(left: 4),
                  minimumSize: const Size(38, 40),
                  onPressed: () => setState(() {
                    exercise.sets.remove(set);
                    set.dispose();
                  }),
                  child: Icon(
                    CupertinoIcons.delete,
                    size: 15,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
        CupertinoButton(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.zero,
          onPressed: () => setState(() => exercise.sets.add(_ImportSet())),
          child: Text(l.workoutImportAddSet),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final preview = _workouts != null;
    final needsReview =
        (_workouts?.any((workout) => workout.date == null) ?? false) ||
        _unparsed.isNotEmpty;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l.workoutImportTitle)),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: preview ? _previewView(l) : _inputView(l)),
            // Next to the button, so it shows however far the list is scrolled.
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  _error!,
                  key: const ValueKey('workout-import-error'),
                  style: TextStyle(
                    color: CupertinoColors.systemRed.resolveFrom(context),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  key: const ValueKey('workout-import-primary'),
                  onPressed: _busy || needsReview
                      ? null
                      : preview
                      ? _save
                      : _analyze,
                  child: _busy
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : Text(
                          preview
                              ? l.workoutImportSave
                              : l.workoutImportAnalyze,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportWorkout {
  _ImportWorkout({required this.date, required this.exercises});
  DateTime? date;
  final List<_ImportExercise> exercises;
  void dispose() {
    for (final exercise in exercises) {
      exercise.dispose();
    }
  }
}

class _ImportExercise {
  _ImportExercise(String name, this.sets)
    : name = TextEditingController(text: name);
  final TextEditingController name;
  final List<_ImportSet> sets;
  void dispose() {
    name.dispose();
    for (final set in sets) {
      set.dispose();
    }
  }
}

class _ImportSet {
  _ImportSet({
    double? value,
    String unit = '',
    int? reps,
    List<String> notes = const [],
    this.done = true,
  }) : value = TextEditingController(text: _format(value, unit, reps)),
       notes = TextEditingController(text: notes.join(' · ')),
       notesHasInput = notes.isNotEmpty;

  final TextEditingController value;
  final TextEditingController notes;
  final bool notesHasInput;
  bool done;

  static String _format(double? value, String unit, int? reps) {
    final parts = <String>[];
    if (value != null) {
      final amount = value == value.roundToDouble() ? value.toInt() : value;
      parts.add('$amount${unit == 'reps' ? '회' : unit}');
    }
    if (reps != null) parts.add('$reps회');
    return parts.join(' ');
  }

  void dispose() {
    value.dispose();
    notes.dispose();
  }
}
