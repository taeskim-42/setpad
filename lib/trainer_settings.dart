import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import 'account.dart';
import 'editor.dart' show SuggestionChip;
import 'l10n/generated/app_localizations.dart';
import 'palette.dart';
import 'trainer.dart';

/// 에이전트 설정 — 내 것(시각·요일·업무별 방식)과, 관장이면 도장 방침.
///
/// 설정은 바꾸는 그 자리에서 저장한다(iOS 설정 앱처럼). 서버가 받아 준 값으로
/// 화면을 다시 그리므로, 거절되면 원래 값이 그대로 남고 이유가 대화상자로 뜬다
/// (배너는 아래로 내려 바꾸면 화면 밖이다). 방침은 숫자를 치는 칸이라 '방침
/// 저장'을 눌러야 간다.
class TrainerSettingsPage extends StatefulWidget {
  const TrainerSettingsPage({
    super.key,
    required this.account,
    required this.gymId,
    required this.gymName,
    required this.state,
  });
  final Account account;
  final String gymId, gymName;

  /// 트레이너 화면과 같은 것. 저장한 값을 여기에 넣어 두면 다시 열어도 맞다.
  final AgentState state;

  @override
  State<TrainerSettingsPage> createState() => _TrainerSettingsPageState();
}

/// 서버의 AgentTask 순서. PT 일정만 '자동'이 된다(TASK_MODES).
const _tasks = ['pt_schedule', 'renewal', 'attendance', 'routine', 'contact'];

const _policyNumbers = [
  'renewal_notice_days',
  'low_sessions',
  'away_days',
  'lapsed_days',
];

/// 방침 숫자 칸의 글. 칸은 일 또는 회를 센다 — '14', '14일', '3회', '7 days',
/// '14일 전' 을 읽고, 일·회 뒤·앞에 붙은 말('14일간', '3회 이하', '약 14일',
/// '14 days ago')도 그 수로 읽는다. 그 밖의 글은 다른 수로 읽지 않고 [why] 로
/// 까닭을 준다: decimal('1.5'), range('10~14일'), negative('-3'), unit('48시간'·
/// '2주' — 일이 아니다), other(수가 없다). '48시간' 을 48일로 읽으면 뜻이 바뀐다.
({int? value, String? why}) policyNumber(String text) {
  final t = text.trim();
  final n = RegExp(
    r'^(\d+)\s*(?:전|前|before|antes|trước|ก่อน)?$'
    // 앞은 글자만, 뒤는 수 없는 말만 — 소수·범위·음수·두 번째 수는 여기 못 든다.
    r'|^[\p{L}\p{M}\s]*(\d+)\s*'
    r'(?:일|회|번|日|天|次|回|วัน|ครั้ง|ngày|lần|días?|veces|days?|times?)\D*$',
    caseSensitive: false,
    unicode: true,
  ).firstMatch(t);
  if (n != null) return (value: int.parse(n[1] ?? n[2]!), why: null);
  bool has(String pattern) => RegExp(pattern).hasMatch(t);
  return (
    value: null,
    why: has(r'\d\s*[.,]\s*\d')
        ? 'decimal'
        : has(r'\d\s*(?:[~\-–—〜～]|에서|to|至|到)\s*\d')
        ? 'range'
        : has(r'^[-−–]\s*\d')
        ? 'negative'
        : has(r'\d')
        ? 'unit'
        : 'other',
  );
}

class _TrainerSettingsPageState extends State<TrainerSettingsPage> {
  AgentState get _s => widget.state;
  bool _busy = false;

  /// 읽지 못한 방침 칸과 그 까닭. 그 칸 밑에 적고, 저장은 보내지 않는다.
  Map<String, String> _unreadable = {};

  late final _numbers = {
    for (final key in _policyNumbers)
      key: TextEditingController(text: '${_s.policy[key] ?? ''}'),
  };
  late final _offer = TextEditingController(
    text: _s.policy['renewal_offer'] as String? ?? '',
  );

  @override
  void dispose() {
    for (final c in _numbers.values) {
      c.dispose();
    }
    _offer.dispose();
    super.dispose();
  }

  Future<void> _save(Map<String, Object?> change) async {
    setState(() => _busy = true);
    final reply = await widget.account.link.saveAgentSettings(
      widget.gymId,
      change,
    );
    if (!mounted) return;
    final saved = reply.body?['settings'];
    setState(() {
      _busy = false;
      if (saved is Map) _s.settings = AgentSettings.fromJson(saved);
    });
    if (saved is Map) {
      unawaited(syncAgentAlarm(widget.gymId, widget.gymName, _s.settings));
    } else {
      await tellAgent(context, reply.message ?? L.of(context).trainerFailed);
    }
  }

  Future<void> _savePolicy() async {
    final l = L.of(context);
    // 숫자 패드에는 닫는 키가 없다. 닫지 않으면 결과가 키보드 뒤에 가린다.
    FocusScope.of(context).unfocus();
    final typed = {
      for (final key in _policyNumbers) key: _numbers[key]!.text.trim(),
    };
    // 친 글에서 수를 못 읽은 칸은 그 칸에서 말한다. 서버에 보내면 저장 전체가
    // 범위 문구로 거절돼 어느 칸의 무엇이 틀렸는지 흐려진다.
    final read = {
      for (final e in typed.entries)
        if (e.value.isNotEmpty) e.key: policyNumber(e.value),
    };
    final unreadable = {for (final e in read.entries) e.key: ?e.value.why};
    setState(() {
      _unreadable = unreadable;
      _busy = unreadable.isEmpty;
    });
    if (unreadable.isNotEmpty) return;
    final offer = _offer.text.trim();
    // 빈 칸은 null 로 보낸다 — 서버가 허용 범위를 적어 거절한다.
    final reply = await widget.account.link.saveGymPolicy(widget.gymId, {
      for (final key in _policyNumbers) key: read[key]?.value,
      'renewal_offer': offer.isEmpty ? null : offer,
    });
    if (!mounted) return;
    final saved = reply.body?['policy'];
    setState(() {
      _busy = false;
      if (saved is Map) {
        _s.policy = Map<String, Object?>.from(saved);
        // 읽은 대로 저장됐다 — '14일' 이 14 로 들어간 것이 보인다.
        for (final key in _policyNumbers) {
          _numbers[key]!.text = '${saved[key] ?? ''}';
        }
      }
    });
    await tellAgent(
      context,
      saved is Map ? l.policySaved : reply.message ?? l.trainerFailed,
    );
  }

  /// 정리 시각을 고른다. [current] 가 null 이면 새로 더한다.
  Future<void> _pickTime(int? current) async {
    final l = L.of(context);
    // 5분 간격 바퀴라 처음 값도 5분에 맞춰야 한다(맞지 않으면 assert).
    var picked = (current ?? 420) ~/ 5 * 5;
    final ok = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l.cancel),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l.ok),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  minuteInterval: 5,
                  initialDateTime: DateTime(
                    2000,
                    1,
                    1,
                    picked ~/ 60,
                    picked % 60,
                  ),
                  onDateTimeChanged: (t) => picked = t.hour * 60 + t.minute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final times = {
      ..._s.settings.runMinutes.where((m) => m != current),
      picked,
    }.toList()..sort();
    await _save({'run_minutes': times});
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = _s.settings;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l.agentSettings)),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _toggle(l.agentEnabled, s.enabled, (v) => _save({'enabled': v})),

            _section(l.agentTimes),
            for (final m in s.runMinutes)
              _row(
                _clock(m),
                onTap: () => _pickTime(m),
                // 하나는 남아야 한다(서버: 1~4개).
                trailing: s.runMinutes.length > 1
                    ? CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 32),
                        onPressed: _busy
                            ? null
                            : () => _save({
                                'run_minutes': [
                                  for (final t in s.runMinutes)
                                    if (t != m) t,
                                ],
                              }),
                        child: Icon(
                          CupertinoIcons.minus_circle,
                          size: 20,
                          semanticLabel: l.delete,
                          color: CupertinoColors.systemRed.resolveFrom(context),
                        ),
                      )
                    : null,
              ),
            if (s.runMinutes.length < 4)
              _row(l.agentAddTime, accent: true, onTap: () => _pickTime(null)),

            _section(l.agentDays),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var d = 0; d < 7; d++)
                    SuggestionChip(
                      // 2023-01-01 은 일요일 — 서버의 0.
                      label: DateFormat.E(
                        l.localeName,
                      ).format(DateTime(2023, 1, 1 + d)),
                      selected: s.weekdays.contains(d),
                      onTap: () {
                        if (_busy) return;
                        final days = {...s.weekdays};
                        if (!days.remove(d)) days.add(d);
                        _save({'weekdays': days.toList()..sort()});
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _toggle(
              l.agentAutoConfirm,
              s.autoConfirm,
              (v) => _save({'auto_confirm': v}),
            ),

            _section(l.agentModes),
            _note(l.agentModesHelp),
            for (final task in _tasks) _mode(l, task, s.modes[task] ?? 'draft'),

            if (_s.owner) ...[
              _section(l.gymPolicy),
              for (final (key, label) in [
                ('renewal_notice_days', l.policyRenewalDays),
                ('low_sessions', l.policyLowSessions),
                ('away_days', l.policyAwayDays),
                ('lapsed_days', l.policyLapsedDays),
              ]) ...[
                _row(
                  label,
                  trailing: SizedBox(
                    width: 64,
                    child: CupertinoTextField(
                      key: ValueKey('policy-$key'),
                      controller: _numbers[key],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                if (_unreadable[key] case final why?)
                  _note(
                    l.policyNumberRejected(_numbers[key]!.text.trim(), why),
                  ),
              ],
              _row(l.policyOffer),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: CupertinoTextField(
                  controller: _offer,
                  maxLength: 200,
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CupertinoButton.filled(
                  onPressed: _busy ? null : _savePolicy,
                  child: Text(l.policySave),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  Widget _mode(L l, String task, String mode) => _row(
    switch (task) {
      'pt_schedule' => l.taskPtSchedule,
      'renewal' => l.taskRenewal,
      'attendance' => l.taskAttendance,
      'routine' => l.taskRoutine,
      _ => l.taskContact,
    },
    trailing: CupertinoSlidingSegmentedControl<String>(
      groupValue: mode,
      children: {
        'off': Text(l.agentModeOff),
        'draft': Text(l.agentModeDraft),
        if (task == 'pt_schedule') 'auto': Text(l.agentModeAuto),
      },
      onValueChanged: (v) {
        if (v != null && v != mode && !_busy) {
          _save({
            'modes': {task: v},
          });
        }
      },
    ),
  );

  Widget _row(
    String label, {
    Widget? trailing,
    bool accent = false,
    VoidCallback? onTap,
  }) {
    final body = Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: accent ? FontWeight.w600 : FontWeight.w400,
                color: accent
                    ? seal.resolveFrom(context)
                    : CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
    return onTap == null || _busy
        ? body
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: body,
          );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      _row(
        label,
        trailing: CupertinoSwitch(
          value: value,
          onChanged: _busy ? null : onChanged,
        ),
      );

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    ),
  );

  Widget _note(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        height: 1.45,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    ),
  );
}
