import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import 'body.dart';
import 'l10n/generated/app_localizations.dart';
import 'notes.dart';
import 'units.dart';

/// 내 몸 정보 — 키·몸무게·태어난 해·성별. 기초대사량 셈에만 쓰고 기기 안에만 둔다.
class BodyPage extends StatefulWidget {
  const BodyPage({super.key, required this.store});
  final NotesStore store;

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
          ],
        ),
      ),
    );
  }
}
