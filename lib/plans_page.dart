import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'account.dart';
import 'editor.dart';
import 'gym_sheets.dart';
import 'l10n/generated/app_localizations.dart';
import 'nearby.dart';
import 'notes.dart';
import 'palette.dart';
import 'parser.dart';
import 'partner.dart';
import 'plans.dart';
import 'share.dart';

String planStateText(L l, SharedPlan p) => switch (p.state) {
  PlanState.local => l.planStateLocal,
  PlanState.draft => l.planStateDraft,
  PlanState.agreed => l.planStateAgreed(p.version),
  PlanState.withdrawn => l.planStateWithdrawn,
  PlanState.pending =>
    p.needsMyAccept
        ? l.planStateNeedsMe(p.partner ?? '', p.version)
        : l.planStateWaiting(p.version),
};

String planDateText(L l, String? day) => day == null
    ? l.planDateNone
    : DateFormat.MMMEd(l.localeName).format(DateTime.parse(day));

/// 공동 루틴 목록. 떨어져 있을 때 여는 화면이다 — 운동 기록도, 가까이 있는 상대도
/// 필요 없다.
class PlansPage extends StatefulWidget {
  const PlansPage({
    super.key,
    required this.plans,
    required this.account,
    required this.notes,
    required this.onOpenNote,
    this.open,
    this.joinToken,
  });
  final PlanStore plans;
  final Account account;
  final NotesStore notes;
  final void Function(Note note) onOpenNote;

  /// 들어오자마자 열 계획(기록에서 방금 만든 초안).
  final SharedPlan? open;

  /// 초대 링크로 들어왔다. 로그인돼 있으면 바로, 아니면 로그인한 뒤에 참여한다.
  final String? joinToken;

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  void _changed() {
    setState(() {});
    // 링크로 왔는데 로그인이 방금 끝났다 — 원래 하려던 참여로 돌아간다.
    unawaited(_joinFromLink());
  }

  String? _pendingToken;
  bool _joining = false;
  PartnerError? _linkError;

  Future<void> _joinFromLink() async {
    final token = _pendingToken;
    if (token == null || _joining || !widget.account.signedIn) return;
    _joining = true;
    _pendingToken = null; // 같은 링크를 두 번 처리하지 않는다.
    if (mounted) setState(() {});
    final result = await widget.plans.join(token, isToken: true);
    _joining = false;
    if (!mounted) return;
    setState(() => _linkError = result.error);
    if (result.plan != null) _open(result.plan!);
  }

  @override
  void initState() {
    super.initState();
    widget.plans.addListener(_changed);
    widget.account.addListener(_changed);
    unawaited(widget.plans.refreshAll());
    _pendingToken = widget.joinToken;
    unawaited(_joinFromLink());
    if (widget.open != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(widget.open!));
    }
  }

  @override
  void dispose() {
    widget.plans.removeListener(_changed);
    widget.account.removeListener(_changed);
    super.dispose();
  }

  void _open(SharedPlan plan) => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => PlanPage(
        plan: plan,
        plans: widget.plans,
        notes: widget.notes,
        onOpenNote: widget.onOpenNote,
      ),
    ),
  );

  Future<void> _join() async {
    final l = L.of(context);
    final input = TextEditingController();
    String? problem;
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, redraw) => CupertinoAlertDialog(
          title: Text(l.planJoin),
          content: Column(
            children: [
              const SizedBox(height: 10),
              CupertinoTextField(
                key: const ValueKey('plan-code'),
                controller: input,
                autofocus: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, letterSpacing: 4),
              ),
              if (problem != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(problem!, style: const TextStyle(fontSize: 13)),
                ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                final result = await widget.plans.join(input.text);
                if (!ctx.mounted) return;
                if (result.error != null) {
                  redraw(() => problem = partnerErrorText(l, result.error!));
                  return;
                }
                Navigator.pop(ctx);
                _open(result.plan!);
              },
              child: Text(l.partnerEnter),
            ),
          ],
        ),
      ),
    );
    input.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(l.plansTitle),
        border: null,
      ),
      child: SafeArea(
        child: !widget.account.signedIn
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.partnerSignIn, style: TextStyle(color: muted)),
                    const SizedBox(height: 12),
                    CupertinoButton.filled(
                      onPressed: widget.account.signIn,
                      child: Text(l.partnerSignInAction),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          final plan = SharedPlan(
                            localId:
                                'p${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
                          );
                          widget.plans.add(plan);
                          _open(plan);
                        },
                        child: Text(l.planNew),
                      ),
                      const SizedBox(width: 20),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _join,
                        child: Text(l.planJoin),
                      ),
                    ],
                  ),
                  if (_joining)
                    Text(
                      l.planLinkJoining,
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                  if (_linkError != null)
                    Text(
                      partnerErrorText(l, _linkError!),
                      key: const ValueKey('plan-link-error'),
                      style: TextStyle(
                        fontSize: 13,
                        color: seal.resolveFrom(context),
                      ),
                    ),
                  if (!widget.plans.reachable)
                    Text(
                      l.partnerErrNetwork,
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                  for (final plan in widget.plans.plans)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _open(plan),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.shown.title.isEmpty
                                  ? l.planNew
                                  : plan.shown.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              [
                                planDateText(l, plan.shown.plannedOn),
                                ?plan.partner,
                                planStateText(l, plan),
                              ].join(' · '),
                              style: TextStyle(fontSize: 13, color: muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// 공동 루틴 한 장.
class PlanPage extends StatefulWidget {
  const PlanPage({
    super.key,
    required this.plan,
    required this.plans,
    required this.notes,
    required this.onOpenNote,
  });
  final SharedPlan plan;
  final PlanStore plans;
  final NotesStore notes;
  final void Function(Note note) onOpenNote;

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> with WidgetsBindingObserver {
  late final _text = TextEditingController();
  Timer? _poll;
  String? _day;
  bool _busy = false;

  SharedPlan get plan => widget.plan;
  PlanStore get plans => widget.plans;
  bool get _closed => plan.state == PlanState.withdrawn;

  bool _nearby = false;
  String? _offered;

  /// 아직 혼자인 내 계획이면, 살아 있는 링크 토큰을 가까이 대서도 건넬 수 있게 걸어 둔다.
  void _syncNearby() {
    final alive = plans.linkFor(plan) != null;
    final token = plan.owner && plan.partner == null && alive
        ? plan.linkToken
        : null;
    if (token == _offered) return;
    _offered = token;
    token == null
        ? Nearby.instance.clear()
        : Nearby.instance.offer(
            kind: 'plan',
            token: token,
            title: plan.shown.title,
          );
  }

  void _changed() {
    if (!mounted) return;
    _syncNearby();
    // 서버에서 새 내용이 왔고 내가 고치는 중이 아니면 글도 따라간다.
    if (plan.draft == null) _load(plan.content);
    setState(() {});
  }

  void _load(PlanContent c) {
    final text = planText(c.title, c.items, L.of(context).planSetsCount);
    if (_text.text != text) _text.text = text;
    _day = c.plannedOn;
  }

  @override
  void initState() {
    super.initState();
    plans.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    // 보이는 동안만 상대의 변경을 확인한다.
    _poll = Timer.periodic(
      const Duration(seconds: 4),
      (_) => plans.refresh(plan),
    );
    unawaited(plans.refresh(plan));
    Nearby.instance.supported.then((ok) {
      if (!mounted) return;
      setState(() => _nearby = ok);
      _syncNearby();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_text.text.isEmpty) _load(plan.shown);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(plans.refresh(plan));
  }

  @override
  void dispose() {
    _poll?.cancel();
    Nearby.instance.clear();
    WidgetsBinding.instance.removeObserver(this);
    plans.removeListener(_changed);
    _text.dispose();
    super.dispose();
  }

  PlanContent get _typed {
    final parsed = parsePlanText(_text.text, previous: plan.shown.items);
    return PlanContent(
      title: parsed.title,
      plannedOn: _day,
      items: parsed.items,
    );
  }

  bool get _edited => !_typed.sameAs(plan.content);

  /// 친 글을 초안으로 남긴다 — 서버에 안 닿아도 이 기기에는 남는다.
  void _keep() {
    final typed = _typed;
    plan.draft = typed.sameAs(plan.content) ? null : typed;
    plans.save();
  }

  Future<void> _run(Future<Object?> Function() work) async {
    setState(() => _busy = true);
    await work();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    var picked = _day == null
        ? now.add(const Duration(days: 1))
        : DateTime.parse(_day!);
    final l = L.of(context);
    final result = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoPopupSurface(
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 180,
                // 날짜만 고른다. 시각과 시간대는 묻지 않는다.
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: picked,
                  onDateTimeChanged: (d) => picked = d,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(ctx, ''),
                    child: Text(l.planDateNone),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(
                      ctx,
                      DateFormat('yyyy-MM-dd').format(picked),
                    ),
                    child: Text(l.ok),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null) return;
    setState(() => _day = result.isEmpty ? null : result);
    _keep();
  }

  Future<void> _editTarget(PlanItem item) async {
    final l = L.of(context);
    final old = plan.myTargets[item.id];
    final input = TextEditingController(
      text: old == null
          ? ''
          : [
              if (old.value != null) '${old.value}${old.unit}',
              if (old.reps != null) '${old.reps}',
              if (old.sets != null) 'x${old.sets}',
              ?old.note,
            ].join(' '),
    );
    final typed = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('${item.name} · ${l.planMyTarget}'),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            key: const ValueKey('plan-target'),
            controller: input,
            autofocus: true,
            placeholder: l.planTargetHint,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, input.text),
            child: Text(l.ok),
          ),
        ],
      ),
    );
    input.dispose();
    if (typed == null) return;
    // 세트 한 줄을 읽는 그 파서다: "100 5", "100kg 5회 x3 무릎 조심".
    final parsed = parseSetLine(typed);
    plans.setTarget(
      plan,
      item.id,
      typed.trim().isEmpty
          ? null
          : PlanTarget(
              value: parsed?.value,
              unit: parsed?.unit ?? widget.notes.weightUnit,
              reps: parsed?.reps,
              sets: parsed != null && parsed.count > 1 ? parsed.count : null,
              note: parsed == null ? typed.trim() : parsed.note,
            ),
    );
  }

  bool _copied = false;

  /// 살아 있는 링크가 있으면 그것을, 없으면 새로 받아 공유 시트에 올린다.
  /// 공유 시트를 못 띄우는 곳에서는 복사해 두고 그렇게 말한다.
  Future<void> _shareLink() async {
    final l = L.of(context);
    if (plans.linkFor(plan) == null) await plans.invite(plan, asLink: true);
    final url = plans.linkFor(plan);
    if (url == null) return;
    final text = l.planShareText(url);
    if (!await shareText(text)) {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) setState(() => _copied = true);
    }
  }

  Future<void> _start() async {
    final note = await startWorkout(plans, widget.notes, plan);
    if (mounted) widget.onOpenNote(note);
  }

  List<Widget> _diff(L l, PlanContent from, PlanContent to, TextStyle style) {
    final d = planDiff(from, to);
    return [
      for (final line in [
        if (d.titleChanged) l.planTitleChanged,
        if (d.dateChanged) l.planDateChanged,
        if (d.added.isNotEmpty) l.planAdded(d.added.join(', ')),
        if (d.removed.isNotEmpty) l.planRemoved(d.removed.join(', ')),
        if (d.changed.isNotEmpty) l.planSetsChanged(d.changed.join(', ')),
        if (d.reordered) l.planReordered,
      ])
        Text(line, style: style),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final small = TextStyle(fontSize: 13, height: 1.45, color: muted);
    final strong = small.copyWith(
      color: CupertinoColors.label.resolveFrom(context),
    );
    final shown = _typed;
    final note = plan.startedNoteId == null
        ? null
        : widget.notes.notes
              .where((n) => n.id == plan.startedNoteId)
              .firstOrNull;
    final left = plan.inviteExpiresAt?.difference(DateTime.now());
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(l.plansTitle),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            // 상태 — 서버가 말한 것만. 이 기기의 초안을 합의라고 하지 않는다.
            Text(
              planStateText(l, plan),
              key: const ValueKey('plan-state'),
              style: strong,
            ),
            if (plan.dirty || (plan.id != null && !plans.reachable))
              Text(l.planStateLocal, style: small),
            if (plan.partner != null) Text(plan.partner!, style: small),
            CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: _closed ? null : _pickDay,
              child: Text(
                planDateText(l, _day),
                style: const TextStyle(fontSize: 15),
              ),
            ),
            // 메모장처럼 친다. 한 줄에 한 종목.
            CupertinoTextField(
              key: const ValueKey('plan-text'),
              controller: _text,
              readOnly: _closed,
              minLines: 5,
              maxLines: null,
              placeholder: l.planHint,
              decoration: const BoxDecoration(),
              padding: EdgeInsets.zero,
              style: const TextStyle(fontSize: 17, height: 1.5),
              onChanged: (_) {
                _keep();
                setState(() {});
              },
            ),
            if (plan.conflict) ...[
              const SizedBox(height: 8),
              Text(
                l.planConflict,
                key: const ValueKey('plan-conflict'),
                style: small.copyWith(color: seal.resolveFrom(context)),
              ),
              Text(l.planLatest(plan.version), style: strong),
              Text(
                planText(
                  plan.content.title,
                  plan.content.items,
                  l.planSetsCount,
                ),
                style: small,
              ),
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => plans.savePlan(plan, overLatest: true),
                          ),
                    child: Text(
                      l.planKeepMine,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      plans.takeLatest(plan);
                      _load(plan.content);
                    },
                    child: Text(
                      l.planTakeLatest,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ] else if (_edited && !_closed)
              Align(
                alignment: Alignment.centerLeft,
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  onPressed: _busy
                      ? null
                      : () => _run(() => plans.edit(plan, _typed)),
                  child: Text(l.planSave),
                ),
              ),
            if (plan.needsMyAccept && !_edited) ...[
              const SizedBox(height: 8),
              Text(l.planChanged, style: strong),
              ..._diff(
                l,
                plan.agreed ?? const PlanContent(),
                plan.content,
                small,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  onPressed: _busy
                      ? null
                      : () => _run(() => plans.accept(plan)),
                  child: Text(l.planAccept(plan.version)),
                ),
              ),
            ],
            // 마지막 합의본은 수정안과 따로 남아 있다.
            if (plan.agreed != null && plan.agreedVersion != plan.version) ...[
              const SizedBox(height: 8),
              Text(l.planLastAgreed(plan.agreedVersion!), style: strong),
              Text(
                planText(
                  plan.agreed!.title,
                  plan.agreed!.items,
                  l.planSetsCount,
                ),
                style: small,
              ),
            ],
            const SizedBox(height: 12),
            // 목표는 각자 정한다. 내 것만 고치고 상대 것은 본다.
            for (final item in shown.items)
              GestureDetector(
                key: ValueKey('plan-item-${item.name}'),
                behavior: HitTestBehavior.opaque,
                onTap: _closed ? null : () => _editTarget(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.sets > 0
                            ? '${item.name} · ${l.planSetsCount(item.sets)}'
                            : item.name,
                        style: const TextStyle(fontSize: 15),
                      ),
                      Text(
                        '${l.planMyTarget}: ${plan.myTargets[item.id]?.label(l.repsCount, l.planSetsCount) ?? '–'}',
                        style: strong,
                      ),
                      if (plan.partnerTargets[item.id] != null)
                        Text(
                          l.planPartnerTarget(
                            plan.partner ?? '',
                            plan.partnerTargets[item.id]!.label(
                              l.repsCount,
                              l.planSetsCount,
                            ),
                          ),
                          style: small,
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (plan.owner && plan.partner == null && !_closed) ...[
              if (plan.code != null && left != null && !left.isNegative) ...[
                Row(
                  children: [
                    Text(
                      plan.code!,
                      key: const ValueKey('plan-code-shown'),
                      style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.only(left: 12),
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: plan.code!)),
                      child: Icon(
                        CupertinoIcons.doc_on_doc,
                        size: 19,
                        semanticLabel: l.partnerCopy,
                      ),
                    ),
                  ],
                ),
                Text(
                  l.partnerExpiresIn(
                    '${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}',
                  ),
                  style: small,
                ),
              ],
              CupertinoButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: _busy ? null : () => _run(() => plans.invite(plan)),
                child: Text(
                  plan.code == null ? l.planInvite : l.partnerNewCode,
                ),
              ),
              // 떨어져 있는 상대에게는 링크를 보낸다. 하루 동안 한 번 쓸 수 있다.
              CupertinoButton(
                key: const ValueKey('plan-share-link'),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: _busy ? null : () => _run(_shareLink),
                child: Text(l.planShareLink),
              ),
              if (_copied) Text(l.planLinkCopied, style: small),
              // 링크를 만든 뒤에는, 되는 아이폰끼리 가까이 대서도 건넬 수 있다.
              if (_nearby && _offered != null)
                Text(
                  l.nearbyHint,
                  key: const ValueKey('nearby-hint'),
                  style: small,
                ),
            ],
            if (plans.error != null)
              Text(
                partnerErrorText(l, plans.error!),
                style: small.copyWith(color: seal.resolveFrom(context)),
              ),
            if (plan.startedNoteId == null) ...[
              if (plan.state != PlanState.agreed)
                Text(l.planStartSoloNote, style: small),
              CupertinoButton(
                key: const ValueKey('plan-start'),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: shown.items.isEmpty || _busy ? null : _start,
                child: Text(
                  plan.state == PlanState.agreed
                      ? l.planStart
                      : l.planStartSolo,
                ),
              ),
            ] else ...[
              Text(
                plan.startedAgreed
                    ? l.planStartedFrom(plan.startedVersion ?? 0)
                    : l.planStartedSolo(plan.startedVersion ?? 0),
                style: strong,
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: _start,
                child: Text(l.planOpenWorkout),
              ),
              if (note != null) ..._compare(l, note, small, strong),
            ],
            CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: () {
                final next = copyPlan(plan);
                plans.add(next);
                Navigator.of(context).pushReplacement(
                  CupertinoPageRoute<void>(
                    builder: (_) => PlanPage(
                      plan: next,
                      plans: plans,
                      notes: widget.notes,
                      onOpenNote: widget.onOpenNote,
                    ),
                  ),
                );
              },
              child: Text(l.planCopyNext),
            ),
            if (!_closed)
              CupertinoButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: () async {
                  await plans.withdraw(plan);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Text(
                  l.planWithdraw,
                  style: const TextStyle(color: CupertinoColors.destructiveRed),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 합의했던 계획과 내가 실제로 한 것. 실제로 해냈다고 표시한 세트만 센다.
  List<Widget> _compare(L l, Note note, TextStyle small, TextStyle strong) {
    final planned = (plan.startedAgreed ? plan.agreed : null) ?? plan.content;
    final names = {for (final i in planned.items) i.name};
    int done(ExerciseBlock b) => b.sets.where((s) => s.done).length;
    final extra = [
      for (final b in note.blocks)
        if (!names.contains(b.name) && done(b) > 0) b.name,
    ];
    final skipped = [
      for (final i in planned.items)
        if (note.blocks.where((b) => b.name == i.name && done(b) > 0).isEmpty)
          i.name,
    ];
    return [
      const SizedBox(height: 6),
      Text(l.planCompare, style: strong),
      for (final i in planned.items)
        Text(
          l.planDoneSets(
            i.name,
            plan.myTargets[i.id]?.sets ?? i.sets,
            note.blocks
                .where((b) => b.name == i.name)
                .fold(0, (n, b) => n + done(b)),
          ),
          style: small,
        ),
      if (extra.isNotEmpty)
        Text(l.planAddedActual(extra.join(', ')), style: small),
      if (skipped.isNotEmpty)
        Text(l.planSkipped(skipped.join(', ')), style: small),
    ];
  }
}
