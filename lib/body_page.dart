import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'body.dart';
import 'l10n/generated/app_localizations.dart';
import 'notes.dart';
import 'record_ai.dart';
import 'units.dart';

/// 내 몸 정보 — 키·몸무게·태어난 해·성별. 기초대사량 셈에만 쓰고 기기 안에만 둔다.
class BodyPage extends StatefulWidget {
  const BodyPage({super.key, required this.store, this.ai});
  final NotesStore store;

  /// 결과지 사진을 읽는 문. 없으면(로그인 전 화면 등) 사진 단추를 그리지 않는다.
  final RecordAi? ai;

  @override
  State<BodyPage> createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage> {
  late final BodyProfile _start = widget.store.body;
  late final _height = TextEditingController(text: _text(_start.heightCm));
  late final _weight = TextEditingController(text: _text(_start.weightKg));
  late final _year = TextEditingController(
    text: _start.birthYear?.toString() ?? '',
  );
  late String? _sex = _start.sex;

  static String _text(double? v) => v == null ? '' : formatNumber(v);

  bool _reading = false;
  String? _scanError;

  /// 결과지 사진 → 서버의 모델이 읽은 값 → 사람이 확인·고친 뒤 저장.
  Future<void> _scan(ImageSource source) async {
    final l = L.of(context);
    final ai = widget.ai;
    if (ai == null) return;
    if (!ai.allowed) {
      setState(() => _scanError = l.aiOffPhoto);
      return;
    }
    final XFile? file;
    try {
      // 결과지의 작은 숫자까지 읽히게 음식 사진보다 크게.
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
    } catch (_) {
      if (mounted) setState(() => _scanError = l.bodyScanFailed);
      return;
    }
    if (file == null || !mounted) return;
    setState(() {
      _reading = true;
      _scanError = null;
    });
    BodyRecord? read;
    try {
      read = await ai.scanBody(
        await file.readAsBytes(),
        mime: file.mimeType ?? 'image/jpeg',
        id: 'b${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      );
    } on RecordAiException catch (e) {
      if (mounted) {
        setState(
          () => _scanError = e.status == RecordAiStatus.quotaExceeded
              ? l.inputQuotaSpent
              : e.status == RecordAiStatus.aiOff
              ? l.aiOffPhoto
              : l.bodyScanFailed,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _scanError = l.bodyScanFailed);
    } finally {
      if (mounted) setState(() => _reading = false);
    }
    if (read == null || !mounted) return;
    final confirmed = await reviewBodyRecord(context, read);
    if (confirmed == null || !mounted) return;
    widget.store.saveBodyRecord(confirmed);
    _weight.text = _text(widget.store.body.weightKg);
    setState(() {});
  }

  Future<void> _delete(BodyRecord r) async {
    final l = L.of(context);
    final yes = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l.bodyRecordDelete),
        content: Text(DateFormat.yMMMd(l.localeName).format(r.on)),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (yes == true) {
      widget.store.deleteBodyRecord(r.id);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _year.dispose();
    super.dispose();
  }

  /// 칠 때마다 저장한다. 읽을 수 없는 칸은 비운 것으로 본다.
  void _save() {
    double? n(String t) => double.tryParse(t.trim().replaceAll(',', '.'));
    final y = int.tryParse(_year.text.trim());
    widget.store.setBody(
      BodyProfile(
        heightCm: switch (n(_height.text)) {
          final h? when h >= 80 && h <= 250 => h,
          _ => null,
        },
        weightKg: switch (n(_weight.text)) {
          final w? when w >= 20 && w <= 400 => w,
          _ => null,
        },
        birthYear: y != null && y > 1900 && y <= DateTime.now().year ? y : null,
        sex: _sex,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final bmr = widget.store.body.bmrPerDay(DateTime.now());
    Widget field(
      String label,
      TextEditingController c, {
      bool decimal = true,
    }) => CupertinoTextFormFieldRow(
      controller: c,
      prefix: Text(label),
      textAlign: TextAlign.end,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      onChanged: (_) => _save(),
    );
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l.bodyTitle)),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoFormSection.insetGrouped(
              footer: Text(
                l.bodyNote,
                style: TextStyle(fontSize: 13, color: muted),
              ),
              children: [
                field(l.bodyHeight, _height),
                field(l.bodyWeight, _weight),
                field(l.bodyBirthYear, _year, decimal: false),
                CupertinoFormRow(
                  prefix: Text(l.bodySex),
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: _sex,
                    children: {'m': Text(l.bodyMale), 'f': Text(l.bodyFemale)},
                    onValueChanged: (v) {
                      _sex = v;
                      _save();
                    },
                  ),
                ),
              ],
            ),
            if (bmr != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l.bodyBmr(
                    NumberFormat.decimalPattern(
                      l.localeName,
                    ).format(bmr.round()),
                  ),
                  key: const ValueKey('body-bmr'),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            _records(context, l, muted),
          ],
        ),
      ),
    );
  }

  /// 체성분 기록: 결과지 사진 단추와 잰 날 순 목록(최근이 위). 각 줄은 앞 기록과의 차이를 적는다.
  Widget _records(BuildContext context, L l, Color muted) {
    final records = widget.store.bodyRecords.reversed.toList();
    final n = NumberFormat.decimalPattern(l.localeName);
    String kg(double v) => '${n.format((v * 10).round() / 10)}kg';
    String change(double? now, double? before, String unit) {
      if (now == null || before == null) return '';
      final d = ((now - before) * 10).round() / 10;
      return d == 0 ? '' : ' (${d > 0 ? '+' : '−'}${n.format(d.abs())}$unit)';
    }

    return CupertinoFormSection.insetGrouped(
      header: Text(l.bodyRecordsTitle),
      footer: Text(
        widget.ai == null ? l.bodyRecordsNote : l.bodyScanNote,
        style: TextStyle(fontSize: 13, color: muted),
      ),
      children: [
        if (widget.ai != null)
          CupertinoFormRow(
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    key: const ValueKey('body-scan-camera'),
                    padding: EdgeInsets.zero,
                    onPressed: _reading
                        ? null
                        : () => _scan(ImageSource.camera),
                    child: Text(l.bodyScanCamera),
                  ),
                ),
                Expanded(
                  child: CupertinoButton(
                    key: const ValueKey('body-scan-library'),
                    padding: EdgeInsets.zero,
                    onPressed: _reading
                        ? null
                        : () => _scan(ImageSource.gallery),
                    child: Text(l.bodyScanLibrary),
                  ),
                ),
              ],
            ),
          ),
        if (_reading)
          CupertinoFormRow(
            child: Row(
              children: [
                const CupertinoActivityIndicator(),
                const SizedBox(width: 8),
                Text(l.bodyScanReading),
              ],
            ),
          ),
        if (_scanError != null)
          CupertinoFormRow(
            child: Text(
              _scanError!,
              key: const ValueKey('body-scan-error'),
              style: TextStyle(
                color: CupertinoColors.systemRed.resolveFrom(context),
              ),
            ),
          ),
        if (records.isEmpty)
          CupertinoFormRow(
            child: Text(l.bodyRecordsEmpty, style: TextStyle(color: muted)),
          ),
        for (final (i, r) in records.indexed)
          GestureDetector(
            key: ValueKey('body-record-${r.id}'),
            behavior: HitTestBehavior.opaque,
            onLongPress: () => _delete(r),
            child: CupertinoFormRow(
              prefix: Text(DateFormat.yMMMd(l.localeName).format(r.on)),
              child: Text(
                [
                  if (r.weightKg != null)
                    '${l.bodyWeightShort} ${kg(r.weightKg!)}${change(r.weightKg, i + 1 < records.length ? records[i + 1].weightKg : null, 'kg')}',
                  if (r.skeletalMuscleKg != null)
                    '${l.bodyMuscleShort} ${kg(r.skeletalMuscleKg!)}${change(r.skeletalMuscleKg, i + 1 < records.length ? records[i + 1].skeletalMuscleKg : null, 'kg')}',
                  if (r.bodyFatPercent != null)
                    '${l.bodyFatShort} ${n.format(r.bodyFatPercent)}%${change(r.bodyFatPercent, i + 1 < records.length ? records[i + 1].bodyFatPercent : null, '%p')}',
                ].join('\n'),
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }
}

/// 읽은 값을 사람이 확인하고 고친다. 빈 칸은 모르는 것으로 저장한다. 취소하면 null.
Future<BodyRecord?> reviewBodyRecord(BuildContext context, BodyRecord read) =>
    showCupertinoModalPopup<BodyRecord>(
      context: context,
      builder: (_) => _BodyReviewSheet(read: read),
    );

class _BodyReviewSheet extends StatefulWidget {
  const _BodyReviewSheet({required this.read});
  final BodyRecord read;

  @override
  State<_BodyReviewSheet> createState() => _BodyReviewSheetState();
}

class _BodyReviewSheetState extends State<_BodyReviewSheet> {
  late DateTime _on = widget.read.on;
  late final Map<String, TextEditingController> _fields = {
    for (final (key, value) in [
      ('weight', widget.read.weightKg),
      ('muscle', widget.read.skeletalMuscleKg),
      ('fatKg', widget.read.bodyFatKg),
      ('fatPercent', widget.read.bodyFatPercent),
      ('bmi', widget.read.bmi),
      ('bmr', widget.read.bmrKcal),
      ('visceral', widget.read.visceralFatLevel),
    ])
      key: TextEditingController(
        text: value == null ? '' : formatNumber(value),
      ),
  };

  double? _value(String key, double min, double max) {
    final v = double.tryParse(_fields[key]!.text.trim().replaceAll(',', '.'));
    return v != null && v >= min && v <= max ? v : null;
  }

  BodyRecord get _record => BodyRecord(
    id: widget.read.id,
    on: _on,
    weightKg: _value('weight', 20, 400),
    skeletalMuscleKg: _value('muscle', 5, 120),
    bodyFatKg: _value('fatKg', 0.5, 250),
    bodyFatPercent: _value('fatPercent', 1, 80),
    bmi: _value('bmi', 8, 90),
    bmrKcal: _value('bmr', 500, 5000),
    visceralFatLevel: _value('visceral', 1, 30),
  );

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    Widget field(String key, String label, String unit) =>
        CupertinoTextFormFieldRow(
          key: ValueKey('body-review-$key'),
          controller: _fields[key],
          prefix: Text(label),
          placeholder: unit,
          textAlign: TextAlign.end,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        );
    return CupertinoPopupSurface(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: 12 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    l.bodyReviewTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  child: Text(
                    l.bodyReviewNote,
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ),
                CupertinoFormSection.insetGrouped(
                  children: [
                    CupertinoFormRow(
                      prefix: Text(l.bodyMeasuredOn),
                      child: CupertinoButton(
                        key: const ValueKey('body-review-date'),
                        padding: EdgeInsets.zero,
                        onPressed: () => showCupertinoModalPopup<void>(
                          context: context,
                          builder: (_) => Container(
                            height: 260,
                            color: CupertinoColors.systemBackground.resolveFrom(
                              context,
                            ),
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.date,
                              initialDateTime: _on,
                              maximumDate: DateTime.now(),
                              onDateTimeChanged: (d) => setState(
                                () => _on = DateTime(d.year, d.month, d.day),
                              ),
                            ),
                          ),
                        ),
                        child: Text(DateFormat.yMMMd(l.localeName).format(_on)),
                      ),
                    ),
                    field('weight', l.bodyWeight, 'kg'),
                    field('muscle', l.bodyMuscle, 'kg'),
                    field('fatKg', l.bodyFatKg, 'kg'),
                    field('fatPercent', l.bodyFatPercent, '%'),
                    field('bmi', 'BMI', ''),
                    field('bmr', l.bodyBmrField, 'kcal'),
                    field('visceral', l.bodyVisceral, ''),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        key: const ValueKey('body-review-cancel'),
                        onPressed: () => Navigator.pop(context),
                        child: Text(l.cancel),
                      ),
                    ),
                    Expanded(
                      child: CupertinoButton.filled(
                        key: const ValueKey('body-review-save'),
                        onPressed: _record.empty
                            ? null
                            : () => Navigator.pop(context, _record),
                        child: Text(l.doneEditing),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
