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

  @override
  String get allNotes => 'すべての記録';

  @override
  String noteCount(int n) {
    return '$n件の記録';
  }

  @override
  String get previous7Days => '過去7日間';

  @override
  String get previous30Days => '過去30日間';

  @override
  String monthLabel(int m) {
    return '$m月';
  }

  @override
  String get search => '検索';

  @override
  String get newNote => '新規記録';

  @override
  String get untitledNote => '新規記録';

  @override
  String get noNotesYet => 'まだ記録がありません';

  @override
  String get noSearchResults => '該当する記録がありません';

  @override
  String dayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.yMd(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get finishExercise => '完了';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String deleteExerciseTitle(String name) {
    return '$nameを削除';
  }

  @override
  String deleteExerciseBody(int n) {
    return '$nセットも一緒に削除されます。元に戻せません。';
  }

  @override
  String get deleteExerciseEmptyBody => 'この種目を削除します。';

  @override
  String get next => '次へ';

  @override
  String stepSizeTitle(String unit) {
    return '$unitの刻み';
  }

  @override
  String kcal(int n) {
    return '${n}kcal';
  }

  @override
  String weekdayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.EEEE(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get noteHint => 'このセットのメモ';
}
