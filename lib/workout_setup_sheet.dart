import 'package:flutter/cupertino.dart';

import 'l10n/generated/app_localizations.dart';
import 'parser.dart';
import 'record_ai.dart';
import 'units.dart';

String setupSummary(WorkoutSetup setup, L l, int reps, int sets) => [
  if (setup.weight != null) formatValue(setup.weight!, setup.unit),
  if (setup.totalReps != null) l.goalProgress(reps, setup.totalReps!),
  if (setup.repsPerSet != null) l.repsPerSetLabel(setup.repsPerSet!),
  if (setup.totalSets != null) l.setProgress(sets, setup.totalSets!),
  if (setup.weight == null &&
      setup.totalReps == null &&
      setup.repsPerSet == null &&
      setup.totalSets == null)
    l.repsInputHint,
].join(' · ');

Future<WorkoutSetup?> editWorkoutSetup(
  BuildContext context,
  WorkoutSetup setup,
) async => (await editWorkoutSetups(context, [setup]))?.single;

/// 한 줄에서 읽은 운동들을 한 화면에서 확인한다. 여럿이면 칸마다 [titles] 를
/// 머리에 단다. 칸에 못 옮긴 말([unparsed])과 글에 없어 뺀 수([dropped])는 맨
/// 위에 한 줄씩 — 사람은 무엇이 설정이 되고 무엇이 제목에만 남는지 보고 고른다.
///
/// 잘못 나뉜 운동(드랍 세트의 둘째 무게)은 빼지 않고 **앞 운동에 합친다** — 그
/// 자리는 null 로 오고, 부르는 쪽은 그 제목을 앞 칸 제목에 이어 붙인다. 친 말은
/// 남는다. 합친 제목이 120자를 넘으면 합칠 수 없다.
Future<List<WorkoutSetup?>?> editWorkoutSetups(
  BuildContext context,
  List<WorkoutSetup> setups, {
  List<String> titles = const [],
  String? sourceText,
  List<String> unparsed = const [],
  List<String> dropped = const [],
}) => Navigator.of(context).push<List<WorkoutSetup?>>(
  CupertinoPageRoute(
    builder: (_) => _SetupPage(
      setups: setups,
      titles: titles,
      sourceText: sourceText,
      unparsed: unparsed,
      dropped: dropped,
    ),
  ),
);

class _SetupPage extends StatefulWidget {
  const _SetupPage({
    required this.setups,
    required this.titles,
    required this.unparsed,
    required this.dropped,
    this.sourceText,
  });
  final List<WorkoutSetup> setups;
  final List<String> titles, unparsed, dropped;
  final String? sourceText;
  @override
  State<_SetupPage> createState() => _SetupPageState();
}

/// 운동 하나의 입력 칸들.
class _Fields {
  _Fields(this.setup)
    : name = TextEditingController(text: setup.name),
      weight = TextEditingController(text: _text(setup.weight)),
      total = TextEditingController(text: _text(setup.totalReps)),
      reps = TextEditingController(text: _text(setup.repsPerSet)),
      sets = TextEditingController(text: _text(setup.totalSets)),
      unit = setup.unit,
      repsOnly = setup.repsOnly;
  final WorkoutSetup setup;
  final TextEditingController name, weight, total, reps, sets;
  String unit;
  bool repsOnly;
  List<TextEditingController> get all => [name, weight, total, reps, sets];

  static String _text(num? n) => n?.toString() ?? '';

  /// 빈칸은 null, 읽을 수 없는 글('8-12', '60kg')은 NaN — 규칙이 거절하므로 그 칸
  /// 밑에 이유가 뜨고 완료는 꺼진다. 빈칸으로 바꿔 저장하지 않는다(X15). 수 읽기는
  /// 친 글과 같다 — '1,000' 은 천, '22,5' 는 22.5.
  static num? _number(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;
    final n = statedNumbers(clean);
    return n.length == 1 && n.single.start == 0 && n.single.end == clean.length
        ? n.single.value
        : double.nan;
  }

  /// 칸 하나가 틀린 이유. 규칙은 [WorkoutSetup.fromJson] 하나다 — 그 칸만 넣어 본다.
  static String? problem(String key, String text, L l) {
    if (key == 'name') {
      if (text.trim().isEmpty) return l.setupNameMissing;
      return text.trim().length > 120 ? l.setupNameTooLong : null;
    }
    if (text.trim().isEmpty) return null;
    final value = _number(text);
    final ok =
        value != null &&
        WorkoutSetup.tryFromJson({'name': 'x', key: value}) != null;
    return ok
        ? null
        : key == 'weight'
        ? l.setupWeightInvalid
        : l.setupCountInvalid;
  }

  WorkoutSetup? get value => WorkoutSetup.tryFromJson({
    'name': name.text,
    'weight': _number(weight.text),
    'unit': unit,
    'totalReps': _number(total.text),
    'repsPerSet': _number(reps.text),
    'totalSets': _number(sets.text),
    'repsOnly': repsOnly,
  });
}

class _SetupPageState extends State<_SetupPage> {
  late final _fields = [for (final s in widget.setups) _Fields(s)];

  /// 앞 운동에 합친 칸.
  final _merged = <int>{};

  /// 합친 칸은 null. 남은 칸 중 틀린 것이 있으면 전체가 null — 완료가 꺼진다.
  List<WorkoutSetup?>? get _value {
    final values = [
      for (final (i, f) in _fields.indexed)
        _merged.contains(i) ? null : f.value,
    ];
    final kept = [
      for (var i = 0; i < values.length; i++)
        if (!_merged.contains(i)) values[i],
    ];
    return kept.contains(null) ? null : values;
  }

  /// [i] 를 합쳐도 제목이 120자 안인가.
  bool _canMerge(int i) {
    final titles = <String>[];
    for (final (j, t) in widget.titles.indexed) {
      if ((_merged.contains(j) || j == i) && titles.isNotEmpty) {
        titles.last = '${titles.last} $t';
      } else {
        titles.add(t);
      }
    }
    return titles.every((t) => t.length <= 120);
  }

  @override
  void dispose() {
    for (final f in _fields) {
      for (final c in f.all) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final value = _value;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l.setupTitle),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        // 틀린 칸이 있으면 누를 수 없다. 대신 그 칸 밑에 이유가 적혀 있다.
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: value == null
              ? null
              : () => Navigator.pop(context, _value),
          child: Text(l.doneEditing),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            if (widget.sourceText case final source?)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text('${l.reviewNumbers}\n$source'),
              ),
            if (widget.unparsed.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  l.setupUnparsed(widget.unparsed.join(' · ')),
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              ),
            if (widget.dropped.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  l.setupDropped(widget.dropped.join(', ')),
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              ),
            for (final (i, f) in _fields.indexed)
              CupertinoFormSection.insetGrouped(
                header: _fields.length > 1 && i < widget.titles.length
                    ? Text(widget.titles[i])
                    : null,
                children: _merged.contains(i)
                    ? [
                        CupertinoFormRow(
                          child: CupertinoButton(
                            onPressed: () => setState(() => _merged.remove(i)),
                            child: Text(l.setupKeepApart),
                          ),
                        ),
                      ]
                    : [
                        _field(
                          l,
                          'name',
                          l.exerciseNameHint,
                          f.name,
                          text: true,
                        ),
                        _field(
                          l,
                          'weight',
                          l.setupWeight,
                          f.weight,
                          decimal: true,
                        ),
                        CupertinoFormRow(
                          child: CupertinoSlidingSegmentedControl<String>(
                            groupValue: f.unit,
                            children: const {
                              'kg': Text('kg'),
                              'lb': Text('lb'),
                            },
                            onValueChanged: (value) {
                              if (value != null) setState(() => f.unit = value);
                            },
                          ),
                        ),
                        _field(l, 'totalReps', l.setupTotalReps, f.total),
                        _field(l, 'repsPerSet', l.setupSetReps, f.reps),
                        _field(l, 'totalSets', l.setupTotalSets, f.sets),
                        CupertinoFormRow(
                          prefix: Text(l.setupRepsOnly),
                          child: CupertinoSwitch(
                            value: f.repsOnly,
                            onChanged: (on) => setState(() => f.repsOnly = on),
                          ),
                        ),
                        if (i > 0 && i < widget.titles.length)
                          CupertinoFormRow(
                            child: CupertinoButton(
                              onPressed: _canMerge(i)
                                  ? () => setState(() => _merged.add(i))
                                  : null,
                              child: Text(l.setupMergeUp),
                            ),
                          ),
                      ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    L l,
    String key,
    String label,
    TextEditingController c, {
    bool text = false,
    bool decimal = false,
  }) => CupertinoTextFormFieldRow(
    controller: c,
    prefix: Text(label),
    textAlign: TextAlign.end,
    keyboardType: text
        ? TextInputType.text
        : TextInputType.numberWithOptions(decimal: decimal),
    // 틀린 칸은 그 밑에 이유를 적는다(X15). "완료" 만 말없이 꺼지지 않는다.
    autovalidateMode: AutovalidateMode.always,
    validator: (value) => _Fields.problem(key, value ?? '', l),
    onChanged: (_) => setState(() {}),
  );
}
