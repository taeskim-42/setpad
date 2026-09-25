import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'l10n/generated/app_localizations.dart';
import 'palette.dart';
import 'parser.dart';
import 'record_ai.dart';
import 'units.dart';

/// 빈칸은 null, 읽을 수 없는 글('8-12', '60kg')은 NaN — 규칙이 거절하므로 칩
/// 밑에 이유가 뜨고 적용되지 않는다. 빈칸으로 바꿔 저장하지 않는다(X15). 수 읽기는
/// 친 글과 같다 — '1,000' 은 천, '22,5' 는 22.5.
num? _number(String text) {
  final clean = text.trim();
  if (clean.isEmpty) return null;
  final n = statedNumbers(clean);
  return n.length == 1 && n.single.start == 0 && n.single.end == clean.length
      ? n.single.value
      : double.nan;
}

/// 칸 하나가 틀린 이유. 규칙은 [WorkoutSetup.fromJson] 하나다 — 그 칸만 넣어 본다.
String? _problem(String key, String text, L l) {
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

/// 칸 제목 밑의 설정 한 줄 — 무게·목표·세트를 칩으로 보인다. 누른 칩만 **그
/// 자리에서** 고친다. 화면을 옮기지 않는다: 설정은 이 칸의 일부지 다른 페이지가
/// 아니다. 모델이 읽은 값도 확인 창 없이 여기 뜨고, 틀렸으면 여기서 고친다.
class SetupChips extends StatefulWidget {
  const SetupChips({
    super.key,
    required this.title,
    required this.setup,
    required this.reps,
    required this.sets,
    required this.open,
    required this.onToggle,
    required this.onChanged,
    required this.onEditing,
  });

  /// 칸 제목. 설정의 운동 이름이 이와 같으면 이름 칩을 따로 보이지 않는다.
  final String title;

  /// 없으면 제목을 이름으로 한 빈 설정에서 시작한다(⚙ 로 연 칸).
  final WorkoutSetup? setup;

  /// 내가 해낸 횟수·세트 — 목표 칩의 진행.
  final int reps, sets;

  /// 비어 있는 설정도 칩으로 보인다('+ 기본 무게' …). ⚙ 나 + 를 누른 뒤다.
  /// 칩 하나를 고친 뒤에도 펼친 채다 — 다음 빈 칩을 누른 탭이 사라지면 안 된다.
  final bool open;

  /// + 로 펼치고 − 로 접는다.
  final VoidCallback onToggle;
  final ValueChanged<WorkoutSetup> onChanged;

  /// 칩 하나를 고치기 시작했다(true)·끝냈다(false). 그동안 에디터는 입력 줄로
  /// 포커스를 되찾지 않고 키패드를 내린다 — 시스템 키보드가 이 칩의 것이다.
  final ValueChanged<bool> onEditing;

  @override
  State<SetupChips> createState() => _SetupChipsState();
}

class _SetupChipsState extends State<SetupChips> {
  /// 고치는 칩: 'name' 또는 [WorkoutSetup] 의 수 칸 이름.
  String? _key;
  final _text = TextEditingController();
  final _focus = FocusNode();
  String _unit = 'kg';

  WorkoutSetup get _setup => widget.setup ?? WorkoutSetup(name: widget.title);

  @override
  void initState() {
    super.initState();
    // 다른 곳을 눌러 칩을 떠났다 — 읽히는 값이면 적용하고, 아니면 전 값을 둔다.
    _focus.addListener(() {
      if (!_focus.hasFocus) _finish();
    });
  }

  @override
  void dispose() {
    // 고치던 칸이 지워졌다. 에디터가 입력 줄을 되찾게 알린다 — 그리는 도중이라
    // 다음 틀에서.
    if (_key != null) {
      final done = widget.onEditing;
      WidgetsBinding.instance.addPostFrameCallback((_) => done(false));
    }
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _start(String key) {
    final s = _setup;
    final text = switch (key) {
      'name' => s.name,
      'weight' => s.weight == null ? '' : formatNumber(s.weight!),
      'totalReps' => '${s.totalReps ?? ''}',
      'repsPerSet' => '${s.repsPerSet ?? ''}',
      _ => '${s.totalSets ?? ''}',
    };
    // 통째로 골라 둔다 — 대개 새 수를 친다.
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection(baseOffset: 0, extentOffset: text.length),
    );
    _unit = s.unit;
    setState(() => _key = key);
    // autofocus 는 쓰지 않는다 — 입력 줄이 같은 화면에서 포커스를 쥐고 있으면
    // 버려진다. 아직 붙지 않은 노드라도 붙는 순간 포커스를 받는다.
    _focus.requestFocus();
    widget.onEditing(true);
  }

  /// [submit] 은 ✓·Enter 다. 읽을 수 없는 값이면 칩을 열어 둔 채 이유를 보인다.
  /// 다른 곳을 눌러 떠난 것이면 전 값을 두고 닫는다 — 빈칸으로 저장하지 않는다.
  void _finish({bool submit = false}) {
    final key = _key;
    if (key == null || !mounted) return;
    if (_problem(key, _text.text, L.of(context)) != null) {
      if (submit) {
        _focus.requestFocus();
      } else {
        _close();
      }
      return;
    }
    final s = _setup;
    final next = WorkoutSetup.tryFromJson({
      ...s.toJson(),
      key: key == 'name' ? _text.text : _number(_text.text),
      if (key == 'weight') 'unit': _unit,
    });
    _close();
    if (next != null && !mapEquals(next.toJson(), s.toJson())) {
      widget.onChanged(next);
    }
  }

  void _close() {
    setState(() => _key = null);
    widget.onEditing(false);
  }

  void _toggleRepsOnly() => widget.onChanged(
    WorkoutSetup.fromJson({..._setup.toJson(), 'repsOnly': !_setup.repsOnly}),
  );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = _setup;
    final label = <String, String>{
      'weight': l.setupWeight,
      'totalReps': l.setupTotalReps,
      'repsPerSet': l.setupSetReps,
      'totalSets': l.setupTotalSets,
    };
    final value = <String, String?>{
      'weight': s.weight == null ? null : formatValue(s.weight!, s.unit),
      'totalReps': s.totalReps == null
          ? null
          : l.goalProgress(widget.reps, s.totalReps!),
      'repsPerSet': s.repsPerSet == null
          ? null
          : l.repsPerSetLabel(s.repsPerSet!),
      'totalSets': s.totalSets == null
          ? null
          : l.setProgress(widget.sets, s.totalSets!),
    };
    final missing = [
      for (final k in label.keys)
        if (value[k] == null) k,
    ];
    Widget field(String k, String text, {bool ghost = false}) => _key == k
        ? _editor(l, k, label[k] ?? l.exerciseNameHint)
        : _Chip(
            key: ValueKey('setup-$k'),
            text: ghost ? '+ $text' : text,
            ghost: ghost,
            onTap: () => _start(k),
          );
    final problem = _key == null ? null : _problem(_key!, _text.text, l);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 제목이 곧 운동 이름이면 두 번 적지 않는다. 제목이 친 문장이면
              // 통계가 볼 이름이 무엇인지 여기서 보인다.
              if (s.name != widget.title || widget.open || _key == 'name')
                field('name', s.name),
              for (final k in label.keys)
                if (value[k] case final v?) field(k, v),
              if (s.repsOnly)
                _Chip(
                  key: const ValueKey('setup-repsOnly'),
                  text: l.setupRepsOnly,
                  onTap: _toggleRepsOnly,
                ),
              if (widget.open) ...[
                for (final k in missing) field(k, label[k]!, ghost: true),
                if (!s.repsOnly)
                  _Chip(
                    key: const ValueKey('setup-repsOnly'),
                    text: '+ ${l.setupRepsOnly}',
                    ghost: true,
                    onTap: _toggleRepsOnly,
                  ),
              ],
              if (widget.open || missing.isNotEmpty || !s.repsOnly)
                _Chip(
                  key: const ValueKey('setup-more'),
                  text: widget.open ? '−' : '+',
                  ghost: true,
                  semantics: l.setupAdd,
                  onTap: widget.onToggle,
                ),
            ],
          ),
          if (problem != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                problem,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemRed.resolveFrom(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 칩 자리에 들어앉는 입력 칸. ✓·단위를 눌러도 칩을 떠난 것이 아니다.
  Widget _editor(L l, String key, String hint) {
    final ink = seal.resolveFrom(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final ok = _problem(key, _text.text, l) == null;
    return TextFieldTapRegion(
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 2, 6, 2),
        padding: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: sealTint.resolveFrom(context),
          border: Border.all(color: ink),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 48,
                maxWidth: key == 'name' ? 200 : 88,
              ),
              child: IntrinsicWidth(
                child: CupertinoTextField(
                  key: ValueKey('setup-field-$key'),
                  controller: _text,
                  focusNode: _focus,
                  placeholder: hint,
                  keyboardType: key == 'name'
                      ? TextInputType.text
                      : TextInputType.numberWithOptions(
                          decimal: key == 'weight',
                        ),
                  textInputAction: TextInputAction.done,
                  decoration: null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  style: const TextStyle(fontSize: 15),
                  onChanged: (_) => setState(() {}),
                  // 기본은 Enter 에 포커스를 놓는다 — 그러면 틀린 값에서도 닫힌다.
                  onEditingComplete: () {},
                  onSubmitted: (_) => _finish(submit: true),
                  onTapOutside: (_) => _focus.unfocus(),
                ),
              ),
            ),
            if (key == 'weight')
              for (final u in const ['kg', 'lb'])
                GestureDetector(
                  key: ValueKey('setup-unit-$u'),
                  onTap: () => setState(() => _unit = u),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 6,
                    ),
                    child: Text(
                      u,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: u == _unit
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: u == _unit ? ink : muted,
                      ),
                    ),
                  ),
                ),
            CupertinoButton(
              key: const ValueKey('setup-apply'),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(32, 28),
              onPressed: ok ? () => _finish(submit: true) : null,
              child: const Icon(CupertinoIcons.checkmark_alt, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

/// 설정 칩. 채운 칩은 호박색, 비어 있는 칸(+ 기본 무게)은 테두리만.
class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.text,
    required this.onTap,
    this.ghost = false,
    this.semantics,
  });
  final String text;
  final VoidCallback onTap;
  final bool ghost;
  final String? semantics;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantics,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 2, 6, 2),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: ghost ? null : sealTint.resolveFrom(context),
          border: ghost
              ? Border.all(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                )
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: ghost
                ? CupertinoColors.secondaryLabel.resolveFrom(context)
                : seal.resolveFrom(context),
          ),
        ),
      ),
    ),
  );
}
