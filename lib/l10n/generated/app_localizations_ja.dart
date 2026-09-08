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
  String get howTo => '種目を検索してセットを記録しましょう。';

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

  @override
  String get activeEnergy => 'アクティブカロリー';

  @override
  String get energyUnavailable => '記録なし';

  @override
  String get energySource => 'ヘルスケア · この記録の時間帯';

  @override
  String get doneEditing => '完了';

  @override
  String get setInputHint => '重量  回数';

  @override
  String get setRequired => '先にセットを入力してください。例: 60 12';

  @override
  String get aiTitle => '一文で設定';

  @override
  String get aiReady => '利用可能';

  @override
  String get aiChecking => '確認中';

  @override
  String get aiSetupNeeded => '設定が必要';

  @override
  String get aiPreparing => '準備中';

  @override
  String get aiUnavailable => '手動入力';

  @override
  String get aiReadyBody =>
      '種目欄に「ベンチ80kgで合計100回」のように入力してEnterを押すと、重量と目標を設定します。文章は端末内で処理されます。';

  @override
  String get aiDisabledBody =>
      '設定 → Apple IntelligenceとSiriでApple Intelligenceをオンにしてください。モデルの準備後にアプリへ戻ると、自動で再確認します。';

  @override
  String get aiOsBody =>
      '一文での設定にはiOS 26以降とApple Intelligence対応端末が必要です。対応端末では設定 → 一般 → ソフトウェアアップデートを確認してください。';

  @override
  String get aiDeviceBody =>
      'この端末はApple Intelligenceに対応していないため、一文での設定は利用できません。';

  @override
  String get aiPreparingBody =>
      '端末がAIモデルを準備しています。Wi-Fiに接続して、しばらくしてから再確認してください。';

  @override
  String get aiDownloadBody =>
      'AIモデルをダウンロードできます。Wi-Fi接続を推奨します。時間と空き容量が必要です。準備後は文章を端末内で処理します。';

  @override
  String get aiLanguageBody => '端末のAIモデルがアプリの言語に対応していません。対応言語に変更して再確認してください。';

  @override
  String get aiPlatformBody =>
      'この環境では端末内AIを利用できません。対応するiPhoneまたはAndroid端末のアプリをご利用ください。';

  @override
  String get aiUnavailableBody =>
      '現在AIを利用できません。端末、OS、システムAIサービスの対応状況や準備状態によって異なります。端末を設定した直後はネット接続後に再確認してください。';

  @override
  String get aiManualBody =>
      '通常の運動記録は利用できます。種目を選び、セットごとに「80 20」または回数だけを入力してください。';

  @override
  String get aiPrepare => 'モデルを準備';

  @override
  String get aiRetry => '再確認';

  @override
  String get aiWorking => '種目を設定中…';

  @override
  String get aiFailure => '文章を解釈できませんでした。修正して再入力するか、種目名として使用してください。';

  @override
  String get aiUseName => '種目名として使用';

  @override
  String goalProgress(int done, int goal) {
    return '$done/$goal回';
  }

  @override
  String repsPerSetLabel(int n) {
    return 'セットあたり$n回';
  }

  @override
  String setProgress(int done, int goal) {
    return '$done/$goalセット';
  }

  @override
  String get repsInputHint => '回数';

  @override
  String get setupTitle => '種目の設定';

  @override
  String get setupWeight => '基本重量';

  @override
  String get setupTotalReps => '合計回数の目標';

  @override
  String get setupSetReps => 'セットあたりの回数';

  @override
  String get setupTotalSets => 'セット数の目標';

  @override
  String get moveExercise => '種目を移動';

  @override
  String get weightUnitSetting => '重量の既定単位';

  @override
  String get weightUnitHelp => '新しく入力する種目に使います。既存の重量と単位は変更しません。';
}
