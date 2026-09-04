// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class LJa extends L {
  LJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '今日のトレーニング';

  @override
  String get copy => 'コピー';

  @override
  String get copied => 'コピーしました';

  @override
  String get howTo => '種目名を入力して Enter → セットを入力して Enter → 空行で Enter を押すと次の種目';

  @override
  String get exerciseNameHint => '種目名';

  @override
  String get repeatPrevious => '前回と同じ';

  @override
  String get addSet => 'セット追加';

  @override
  String get numberKeypad => '数字キーパッド';

  @override
  String setOrdinal(int n) {
    return '$nセット';
  }

  @override
  String repsCount(int n) {
    return '$n回';
  }
}
