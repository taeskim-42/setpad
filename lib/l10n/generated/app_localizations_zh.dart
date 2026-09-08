// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class LZh extends L {
  LZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '今日训练';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get howTo => '搜索运动名称，记录每一组。';

  @override
  String get exerciseNameHint => '动作名称';

  @override
  String get repeatPrevious => '同上一组';

  @override
  String get addSet => '添加组';

  @override
  String get numberKeypad => '数字键盘';

  @override
  String setOrdinal(int n) {
    return '第$n组';
  }

  @override
  String repsCount(int n) {
    return '$n次';
  }

  @override
  String get allNotes => '所有记录';

  @override
  String noteCount(int n) {
    return '$n 条记录';
  }

  @override
  String get previous7Days => '过去 7 天';

  @override
  String get previous30Days => '过去 30 天';

  @override
  String monthLabel(int m) {
    return '$m月';
  }

  @override
  String get search => '搜索';

  @override
  String get newNote => '新建记录';

  @override
  String get untitledNote => '新建记录';

  @override
  String get noNotesYet => '还没有记录';

  @override
  String get noSearchResults => '没有匹配的记录';

  @override
  String dayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.yMd(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get finishExercise => '完成';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String deleteExerciseTitle(String name) {
    return '删除$name';
  }

  @override
  String deleteExerciseBody(int n) {
    return '将同时删除 $n 组。无法撤销。';
  }

  @override
  String get deleteExerciseEmptyBody => '将删除此动作。';

  @override
  String get next => '下一步';

  @override
  String stepSizeTitle(String unit) {
    return '$unit 步进';
  }

  @override
  String kcal(int n) {
    return '$n 千卡';
  }

  @override
  String weekdayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.EEEE(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get noteHint => '这一组的备注';

  @override
  String get activeEnergy => '活动热量';

  @override
  String get energyUnavailable => '暂无记录';

  @override
  String get energySource => '健康 · 本次记录时段';

  @override
  String get doneEditing => '完成';

  @override
  String get setInputHint => '重量  次数';

  @override
  String get setRequired => '请先输入一组，例如：60 12';

  @override
  String get aiTitle => '一句话设置';

  @override
  String get aiReady => '可用';

  @override
  String get aiChecking => '正在检查';

  @override
  String get aiSetupNeeded => '需要设置';

  @override
  String get aiPreparing => '准备中';

  @override
  String get aiUnavailable => '手动输入';

  @override
  String get aiReadyBody =>
      '在动作名称栏输入“卧推80kg，累计完成100次”并按回车，即可自动设置重量和目标。文字在设备内处理。';

  @override
  String get aiDisabledBody =>
      '请在设置 → Apple Intelligence与Siri中开启Apple Intelligence。模型准备完成后返回应用，将自动重新检查。';

  @override
  String get aiOsBody =>
      '一句话设置需要iOS 26或更新版本和支持Apple Intelligence的设备。请在设置 → 通用 → 软件更新中检查。';

  @override
  String get aiDeviceBody => '此设备不支持Apple Intelligence，无法使用一句话设置。';

  @override
  String get aiPreparingBody => '设备正在准备AI模型。请连接Wi-Fi，稍后再检查。';

  @override
  String get aiDownloadBody => '可以下载AI模型。建议连接Wi-Fi；下载需要时间和储存空间。准备完成后，文字在设备内处理。';

  @override
  String get aiLanguageBody => '设备的AI模型不支持应用语言。请切换到支持的语言后重试。';

  @override
  String get aiPlatformBody => '此环境无法使用设备内AI。请在支持的iPhone或Android设备上使用应用。';

  @override
  String get aiUnavailableBody =>
      '目前无法使用AI，取决于设备、系统及系统AI服务的支持和准备情况。刚完成设备设置时，请联网后稍后重试。';

  @override
  String get aiManualBody => '仍可正常记录运动。选择动作后，每组输入“80 20”或仅输入次数。';

  @override
  String get aiPrepare => '准备模型';

  @override
  String get aiRetry => '重新检查';

  @override
  String get aiWorking => '正在设置动作…';

  @override
  String get aiFailure => '无法理解此内容。请修改后重试，或将其作为动作名称。';

  @override
  String get aiUseName => '用作动作名称';

  @override
  String goalProgress(int done, int goal) {
    return '$done/$goal次';
  }

  @override
  String repsPerSetLabel(int n) {
    return '每组$n次';
  }

  @override
  String setProgress(int done, int goal) {
    return '$done/$goal组';
  }

  @override
  String get repsInputHint => '次数';

  @override
  String get setupTitle => '动作设置';

  @override
  String get setupWeight => '默认重量';

  @override
  String get setupTotalReps => '累计次数目标';

  @override
  String get setupSetReps => '每组次数';

  @override
  String get setupTotalSets => '组数目标';

  @override
  String get moveExercise => '移动动作';

  @override
  String get weightUnitSetting => '默认重量单位';

  @override
  String get weightUnitHelp => '用于新输入的动作。已有记录的重量和单位保持不变。';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class LZhHans extends LZh {
  LZhHans() : super('zh_Hans');

  @override
  String get appTitle => '今日训练';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get howTo => '搜索运动名称，记录每一组。';

  @override
  String get exerciseNameHint => '动作名称';

  @override
  String get repeatPrevious => '同上一组';

  @override
  String get addSet => '添加组';

  @override
  String get numberKeypad => '数字键盘';

  @override
  String setOrdinal(int n) {
    return '第$n组';
  }

  @override
  String repsCount(int n) {
    return '$n次';
  }

  @override
  String get allNotes => '所有记录';

  @override
  String noteCount(int n) {
    return '$n 条记录';
  }

  @override
  String get previous7Days => '过去 7 天';

  @override
  String get previous30Days => '过去 30 天';

  @override
  String monthLabel(int m) {
    return '$m月';
  }

  @override
  String get search => '搜索';

  @override
  String get newNote => '新建记录';

  @override
  String get untitledNote => '新建记录';

  @override
  String get noNotesYet => '还没有记录';

  @override
  String get noSearchResults => '没有匹配的记录';

  @override
  String dayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.yMd(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get finishExercise => '完成';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String deleteExerciseTitle(String name) {
    return '删除$name';
  }

  @override
  String deleteExerciseBody(int n) {
    return '将同时删除 $n 组。无法撤销。';
  }

  @override
  String get deleteExerciseEmptyBody => '将删除此动作。';

  @override
  String get next => '下一步';

  @override
  String stepSizeTitle(String unit) {
    return '$unit 步进';
  }

  @override
  String kcal(int n) {
    return '$n 千卡';
  }

  @override
  String weekdayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.EEEE(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get noteHint => '这一组的备注';

  @override
  String get activeEnergy => '活动热量';

  @override
  String get energyUnavailable => '暂无记录';

  @override
  String get energySource => '健康 · 本次记录时段';

  @override
  String get doneEditing => '完成';

  @override
  String get setInputHint => '重量  次数';

  @override
  String get setRequired => '请先输入一组，例如：60 12';

  @override
  String get aiTitle => '一句话设置';

  @override
  String get aiReady => '可用';

  @override
  String get aiChecking => '正在检查';

  @override
  String get aiSetupNeeded => '需要设置';

  @override
  String get aiPreparing => '准备中';

  @override
  String get aiUnavailable => '手动输入';

  @override
  String get aiReadyBody =>
      '在动作名称栏输入“卧推80kg，累计完成100次”并按回车，即可自动设置重量和目标。文字在设备内处理。';

  @override
  String get aiDisabledBody =>
      '请在设置 → Apple Intelligence与Siri中开启Apple Intelligence。模型准备完成后返回应用，将自动重新检查。';

  @override
  String get aiOsBody =>
      '一句话设置需要iOS 26或更新版本和支持Apple Intelligence的设备。请在设置 → 通用 → 软件更新中检查。';

  @override
  String get aiDeviceBody => '此设备不支持Apple Intelligence，无法使用一句话设置。';

  @override
  String get aiPreparingBody => '设备正在准备AI模型。请连接Wi-Fi，稍后再检查。';

  @override
  String get aiDownloadBody => '可以下载AI模型。建议连接Wi-Fi；下载需要时间和储存空间。准备完成后，文字在设备内处理。';

  @override
  String get aiLanguageBody => '设备的AI模型不支持应用语言。请切换到支持的语言后重试。';

  @override
  String get aiPlatformBody => '此环境无法使用设备内AI。请在支持的iPhone或Android设备上使用应用。';

  @override
  String get aiUnavailableBody =>
      '目前无法使用AI，取决于设备、系统及系统AI服务的支持和准备情况。刚完成设备设置时，请联网后稍后重试。';

  @override
  String get aiManualBody => '仍可正常记录运动。选择动作后，每组输入“80 20”或仅输入次数。';

  @override
  String get aiPrepare => '准备模型';

  @override
  String get aiRetry => '重新检查';

  @override
  String get aiWorking => '正在设置动作…';

  @override
  String get aiFailure => '无法理解此内容。请修改后重试，或将其作为动作名称。';

  @override
  String get aiUseName => '用作动作名称';

  @override
  String goalProgress(int done, int goal) {
    return '$done/$goal次';
  }

  @override
  String repsPerSetLabel(int n) {
    return '每组$n次';
  }

  @override
  String setProgress(int done, int goal) {
    return '$done/$goal组';
  }

  @override
  String get repsInputHint => '次数';

  @override
  String get setupTitle => '动作设置';

  @override
  String get setupWeight => '默认重量';

  @override
  String get setupTotalReps => '累计次数目标';

  @override
  String get setupSetReps => '每组次数';

  @override
  String get setupTotalSets => '组数目标';

  @override
  String get moveExercise => '移动动作';

  @override
  String get weightUnitSetting => '默认重量单位';

  @override
  String get weightUnitHelp => '用于新输入的动作。已有记录的重量和单位保持不变。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class LZhHant extends LZh {
  LZhHant() : super('zh_Hant');

  @override
  String get appTitle => '今日訓練';

  @override
  String get copy => '複製';

  @override
  String get copied => '已複製';

  @override
  String get howTo => '搜尋運動名稱，記錄每一組。';

  @override
  String get exerciseNameHint => '動作名稱';

  @override
  String get repeatPrevious => '同上一組';

  @override
  String get addSet => '新增組';

  @override
  String get numberKeypad => '數字鍵盤';

  @override
  String setOrdinal(int n) {
    return '第$n組';
  }

  @override
  String repsCount(int n) {
    return '$n次';
  }

  @override
  String get allNotes => '所有記錄';

  @override
  String noteCount(int n) {
    return '$n 筆記錄';
  }

  @override
  String get previous7Days => '過去 7 天';

  @override
  String get previous30Days => '過去 30 天';

  @override
  String monthLabel(int m) {
    return '$m月';
  }

  @override
  String get search => '搜尋';

  @override
  String get newNote => '新增記錄';

  @override
  String get untitledNote => '新增記錄';

  @override
  String get noNotesYet => '還沒有記錄';

  @override
  String get noSearchResults => '沒有符合的記錄';

  @override
  String dayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.yMd(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get finishExercise => '完成';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String deleteExerciseTitle(String name) {
    return '刪除$name';
  }

  @override
  String deleteExerciseBody(int n) {
    return '將一併刪除 $n 組。無法復原。';
  }

  @override
  String get deleteExerciseEmptyBody => '將刪除此動作。';

  @override
  String get next => '下一步';

  @override
  String stepSizeTitle(String unit) {
    return '$unit 級距';
  }

  @override
  String kcal(int n) {
    return '$n 千卡';
  }

  @override
  String weekdayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.EEEE(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get noteHint => '這一組的備註';

  @override
  String get activeEnergy => '活動熱量';

  @override
  String get energyUnavailable => '暫無紀錄';

  @override
  String get energySource => '健康 · 本次紀錄時段';

  @override
  String get doneEditing => '完成';

  @override
  String get setInputHint => '重量  次數';

  @override
  String get setRequired => '請先輸入一組，例如：60 12';

  @override
  String get aiTitle => '一句話設定';

  @override
  String get aiReady => '可用';

  @override
  String get aiChecking => '正在檢查';

  @override
  String get aiSetupNeeded => '需要設定';

  @override
  String get aiPreparing => '準備中';

  @override
  String get aiUnavailable => '手動輸入';

  @override
  String get aiReadyBody =>
      '在動作名稱欄輸入「臥推80kg，累計完成100次」並按Enter，即可自動設定重量和目標。文字在裝置內處理。';

  @override
  String get aiDisabledBody =>
      '請在設定 → Apple Intelligence與Siri中開啟Apple Intelligence。模型準備完成後返回App，將自動重新檢查。';

  @override
  String get aiOsBody =>
      '一句話設定需要iOS 26或更新版本和支援Apple Intelligence的裝置。請在設定 → 一般 → 軟體更新中檢查。';

  @override
  String get aiDeviceBody => '此裝置不支援Apple Intelligence，無法使用一句話設定。';

  @override
  String get aiPreparingBody => '裝置正在準備AI模型。請連接Wi-Fi，稍後再檢查。';

  @override
  String get aiDownloadBody => '可以下載AI模型。建議連接Wi-Fi；下載需要時間和儲存空間。準備完成後，文字在裝置內處理。';

  @override
  String get aiLanguageBody => '裝置的AI模型不支援App語言。請切換到支援的語言後重試。';

  @override
  String get aiPlatformBody => '此環境無法使用裝置內AI。請在支援的iPhone或Android裝置上使用App。';

  @override
  String get aiUnavailableBody =>
      '目前無法使用AI，取決於裝置、系統及系統AI服務的支援和準備情況。剛完成裝置設定時，請連網後稍後重試。';

  @override
  String get aiManualBody => '仍可正常記錄運動。選擇動作後，每組輸入「80 20」或僅輸入次數。';

  @override
  String get aiPrepare => '準備模型';

  @override
  String get aiRetry => '重新檢查';

  @override
  String get aiWorking => '正在設定動作…';

  @override
  String get aiFailure => '無法理解此內容。請修改後重試，或將其作為動作名稱。';

  @override
  String get aiUseName => '用作動作名稱';

  @override
  String goalProgress(int done, int goal) {
    return '$done/$goal次';
  }

  @override
  String repsPerSetLabel(int n) {
    return '每組$n次';
  }

  @override
  String setProgress(int done, int goal) {
    return '$done/$goal組';
  }

  @override
  String get repsInputHint => '次數';

  @override
  String get setupTitle => '動作設定';

  @override
  String get setupWeight => '預設重量';

  @override
  String get setupTotalReps => '累計次數目標';

  @override
  String get setupSetReps => '每組次數';

  @override
  String get setupTotalSets => '組數目標';

  @override
  String get moveExercise => '移動動作';

  @override
  String get weightUnitSetting => '預設重量單位';

  @override
  String get weightUnitHelp => '用於新輸入的動作。已有紀錄的重量和單位保持不變。';
}
