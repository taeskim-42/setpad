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

  @override
  String answerDays(int n) {
    return '$n天记录';
  }

  @override
  String answerWeeks(int n) {
    return '$n周';
  }

  @override
  String answerFrequency(String n) {
    return '每周$n次';
  }

  @override
  String answerPeak(String value) {
    return '最高 $value';
  }

  @override
  String answerNoPeak(int n) {
    return '$n周未刷新最高纪录';
  }

  @override
  String answerSince(String date) {
    return '自$date起';
  }

  @override
  String answerAgo(int n) {
    return '$n天前';
  }

  @override
  String answerPerSet(String value) {
    return '每组 $value';
  }

  @override
  String answerChange(String weeks, String value) {
    return '$weeks · $value';
  }

  @override
  String answerChart(String name, int n) {
    return '$name · $n天记录';
  }

  @override
  String answerWeightReps(String value, String reps) {
    return '$value × $reps';
  }

  @override
  String answerSets(int n) {
    return '$n组';
  }

  @override
  String timingBpm(int n) {
    return '$n BPM';
  }

  @override
  String timingProtocol(int work, int rest, int rounds) {
    return '塔巴塔 $work秒 / $rest秒 · $rounds轮';
  }

  @override
  String timingRound(int n, int total) {
    return '第$n/$total轮';
  }

  @override
  String timingRoundDone(int n) {
    return '第$n轮结束';
  }

  @override
  String get timingMetronome => '节拍器';

  @override
  String get timingReady => '准备';

  @override
  String get timingWork => '运动';

  @override
  String get timingRest => '休息';

  @override
  String get timingComplete => '完成';

  @override
  String get timingStart => '开始';

  @override
  String get timingPause => '暂停';

  @override
  String get timingReset => '重置';

  @override
  String get timingInvalid => '请输入 10–120 BPM、1–600 秒的运动与休息时间、1–99 轮。';

  @override
  String get timingSoundFailed => '无法播放声音，计时器仍在运行。';

  @override
  String get queryTitle => '询问记录';

  @override
  String get queryReadyBody =>
      '可以问“深蹲最重是多少？”“上个月做了多少俯卧撑？”“这个月卧推有进步吗？”。设备端AI理解问题，并从已保存的记录计算数值。';

  @override
  String get queryManualBody => '自然语言提问需要设备端AI准备就绪。运动名称和备注搜索始终可用。';

  @override
  String get queryWorking => '正在理解问题…';

  @override
  String get queryFailed => '无法获取回答，请重试。';

  @override
  String get queryUnsupported => '请提出与运动记录有关的问题。';

  @override
  String get queryOffline => '连接后即可提问。';

  @override
  String get queryNoData => '缺少计算所需的已完成记录或数值。请检查原始记录。';

  @override
  String queryPeriod(String start, String end) {
    return '$start – $end';
  }

  @override
  String get queryAllTime => '全部时间';

  @override
  String get queryPresent => '现在';

  @override
  String get queryRepUnit => '次';

  @override
  String get querySetUnit => '组';

  @override
  String get queryDayUnit => '天';

  @override
  String get queryAverage => '每组平均重量';

  @override
  String get queryMissingData => '记录中没有此问题所需的运动或测量信息。';

  @override
  String get queryAmbiguous => '请具体说明你指的是哪项运动的什么记录。';

  @override
  String queryRank(int n) {
    return '第$n名';
  }

  @override
  String timingWorkSeconds(int n) {
    return '运动 $n 秒';
  }

  @override
  String timingRestSeconds(int n) {
    return '休息 $n 秒';
  }

  @override
  String timingRounds(int n) {
    return '$n 轮';
  }

  @override
  String timingBeat(String count) {
    return '第 $count 拍';
  }

  @override
  String timingHeart(int bpm, int target) {
    return '♥ $bpm → $target';
  }

  @override
  String get accountSignIn => '登录并备份';

  @override
  String get accountSignOut => '退出登录';

  @override
  String get planMonthly => '月度会员';

  @override
  String get planLifetime => '永久会员';

  @override
  String get planActive => '使用中';

  @override
  String get restorePurchases => '恢复购买';

  @override
  String get quotaSpent => '本月的提问次数已用完。';

  @override
  String gymMember(String gym, String trainer) {
    return '$gym · $trainer';
  }

  @override
  String gymOnly(String gym) {
    return '$gym';
  }

  @override
  String routineFromTrainer(String gym) {
    return '来自$gym';
  }

  @override
  String get partnerInvite => '一起训练';

  @override
  String get partnerCode => '把这个号码告诉对方';

  @override
  String get partnerEnter => '输入号码';

  @override
  String partnerJoined(String name) {
    return '与$name一起记录';
  }

  @override
  String get partnerFailed => '号码不对或已过期。';

  @override
  String bookingNext(String trainer, String when) {
    return '$trainer · $when';
  }

  @override
  String get bookingNew => '预约私教';

  @override
  String get bookingNone => '当天没有空闲时间。';

  @override
  String get bookingCancel => '取消预约';

  @override
  String get countAloud => '朗读节拍计数';

  @override
  String get metricMax => '最高';

  @override
  String get metricTrend => '趋势';

  @override
  String get metricLast => '上次';

  @override
  String get metricSessions => '天数';

  @override
  String get metricVolume => '总量';

  @override
  String get metricReps => '总次数';

  @override
  String get metricSets => '组数';

  @override
  String get metricAverage => '平均';

  @override
  String get readAsConfirm => '理解为';

  @override
  String get confirmYes => '对';

  @override
  String readAsNote(String from, String to) {
    return '$from → $to';
  }

  @override
  String get reviewNumbers => '应用前请确认数字和条件。';

  @override
  String get querySourceOnly => '查看原始记录';

  @override
  String get queryCompareOrder => '第二个时段 − 第一个时段';

  @override
  String queryRankingLimit(int n) {
    return '前$n项 · 降序';
  }
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

  @override
  String answerDays(int n) {
    return '$n天记录';
  }

  @override
  String answerWeeks(int n) {
    return '$n周';
  }

  @override
  String answerFrequency(String n) {
    return '每周$n次';
  }

  @override
  String answerPeak(String value) {
    return '最高 $value';
  }

  @override
  String answerNoPeak(int n) {
    return '$n周未刷新最高纪录';
  }

  @override
  String answerSince(String date) {
    return '自$date起';
  }

  @override
  String answerAgo(int n) {
    return '$n天前';
  }

  @override
  String answerPerSet(String value) {
    return '每组 $value';
  }

  @override
  String answerChange(String weeks, String value) {
    return '$weeks · $value';
  }

  @override
  String answerChart(String name, int n) {
    return '$name · $n天记录';
  }

  @override
  String answerWeightReps(String value, String reps) {
    return '$value × $reps';
  }

  @override
  String answerSets(int n) {
    return '$n组';
  }

  @override
  String timingBpm(int n) {
    return '$n BPM';
  }

  @override
  String timingProtocol(int work, int rest, int rounds) {
    return '塔巴塔 $work秒 / $rest秒 · $rounds轮';
  }

  @override
  String timingRound(int n, int total) {
    return '第$n/$total轮';
  }

  @override
  String timingRoundDone(int n) {
    return '第$n轮结束';
  }

  @override
  String get timingMetronome => '节拍器';

  @override
  String get timingReady => '准备';

  @override
  String get timingWork => '运动';

  @override
  String get timingRest => '休息';

  @override
  String get timingComplete => '完成';

  @override
  String get timingStart => '开始';

  @override
  String get timingPause => '暂停';

  @override
  String get timingReset => '重置';

  @override
  String get timingInvalid => '请输入 10–120 BPM、1–600 秒的运动与休息时间、1–99 轮。';

  @override
  String get timingSoundFailed => '无法播放声音，计时器仍在运行。';

  @override
  String get queryTitle => '询问记录';

  @override
  String get queryReadyBody =>
      '可以问“深蹲最重是多少？”“上个月做了多少俯卧撑？”“这个月卧推有进步吗？”。设备端AI理解问题，并从已保存的记录计算数值。';

  @override
  String get queryManualBody => '自然语言提问需要设备端AI准备就绪。运动名称和备注搜索始终可用。';

  @override
  String get queryWorking => '正在理解问题…';

  @override
  String get queryFailed => '无法获取回答，请重试。';

  @override
  String get queryUnsupported => '请提出与运动记录有关的问题。';

  @override
  String get queryOffline => '连接后即可提问。';

  @override
  String get queryNoData => '缺少计算所需的已完成记录或数值。请检查原始记录。';

  @override
  String queryPeriod(String start, String end) {
    return '$start – $end';
  }

  @override
  String get queryAllTime => '全部时间';

  @override
  String get queryPresent => '现在';

  @override
  String get queryRepUnit => '次';

  @override
  String get querySetUnit => '组';

  @override
  String get queryDayUnit => '天';

  @override
  String get queryAverage => '每组平均重量';

  @override
  String get queryMissingData => '记录中没有此问题所需的运动或测量信息。';

  @override
  String get queryAmbiguous => '请具体说明你指的是哪项运动的什么记录。';

  @override
  String queryRank(int n) {
    return '第$n名';
  }

  @override
  String timingWorkSeconds(int n) {
    return '运动 $n 秒';
  }

  @override
  String timingRestSeconds(int n) {
    return '休息 $n 秒';
  }

  @override
  String timingRounds(int n) {
    return '$n 轮';
  }

  @override
  String timingBeat(String count) {
    return '第 $count 拍';
  }

  @override
  String timingHeart(int bpm, int target) {
    return '♥ $bpm → $target';
  }

  @override
  String get accountSignIn => '登录并备份';

  @override
  String get accountSignOut => '退出登录';

  @override
  String get planMonthly => '月度会员';

  @override
  String get planLifetime => '永久会员';

  @override
  String get planActive => '使用中';

  @override
  String get restorePurchases => '恢复购买';

  @override
  String get quotaSpent => '本月的提问次数已用完。';

  @override
  String gymMember(String gym, String trainer) {
    return '$gym · $trainer';
  }

  @override
  String gymOnly(String gym) {
    return '$gym';
  }

  @override
  String routineFromTrainer(String gym) {
    return '来自$gym';
  }

  @override
  String get partnerInvite => '一起训练';

  @override
  String get partnerCode => '把这个号码告诉对方';

  @override
  String get partnerEnter => '输入号码';

  @override
  String partnerJoined(String name) {
    return '与$name一起记录';
  }

  @override
  String get partnerFailed => '号码不对或已过期。';

  @override
  String bookingNext(String trainer, String when) {
    return '$trainer · $when';
  }

  @override
  String get bookingNew => '预约私教';

  @override
  String get bookingNone => '当天没有空闲时间。';

  @override
  String get bookingCancel => '取消预约';

  @override
  String get countAloud => '朗读节拍计数';

  @override
  String get metricMax => '最高';

  @override
  String get metricTrend => '趋势';

  @override
  String get metricLast => '上次';

  @override
  String get metricSessions => '天数';

  @override
  String get metricVolume => '总量';

  @override
  String get metricReps => '总次数';

  @override
  String get metricSets => '组数';

  @override
  String get metricAverage => '平均';

  @override
  String get readAsConfirm => '理解为';

  @override
  String get confirmYes => '对';

  @override
  String readAsNote(String from, String to) {
    return '$from → $to';
  }

  @override
  String get reviewNumbers => '应用前请确认数字和条件。';

  @override
  String get querySourceOnly => '查看原始记录';

  @override
  String get queryCompareOrder => '第二个时段 − 第一个时段';

  @override
  String queryRankingLimit(int n) {
    return '前$n项 · 降序';
  }
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

  @override
  String answerDays(int n) {
    return '$n天紀錄';
  }

  @override
  String answerWeeks(int n) {
    return '$n週';
  }

  @override
  String answerFrequency(String n) {
    return '每週$n次';
  }

  @override
  String answerPeak(String value) {
    return '最高 $value';
  }

  @override
  String answerNoPeak(int n) {
    return '$n週未刷新最高紀錄';
  }

  @override
  String answerSince(String date) {
    return '自$date起';
  }

  @override
  String answerAgo(int n) {
    return '$n天前';
  }

  @override
  String answerPerSet(String value) {
    return '每組 $value';
  }

  @override
  String answerChange(String weeks, String value) {
    return '$weeks · $value';
  }

  @override
  String answerChart(String name, int n) {
    return '$name · $n天紀錄';
  }

  @override
  String answerWeightReps(String value, String reps) {
    return '$value × $reps';
  }

  @override
  String answerSets(int n) {
    return '$n組';
  }

  @override
  String timingBpm(int n) {
    return '$n BPM';
  }

  @override
  String timingProtocol(int work, int rest, int rounds) {
    return '塔巴塔 $work秒 / $rest秒 · $rounds輪';
  }

  @override
  String timingRound(int n, int total) {
    return '第$n/$total輪';
  }

  @override
  String timingRoundDone(int n) {
    return '第$n輪結束';
  }

  @override
  String get timingMetronome => '節拍器';

  @override
  String get timingReady => '準備';

  @override
  String get timingWork => '運動';

  @override
  String get timingRest => '休息';

  @override
  String get timingComplete => '完成';

  @override
  String get timingStart => '開始';

  @override
  String get timingPause => '暫停';

  @override
  String get timingReset => '重設';

  @override
  String get timingInvalid => '請輸入 10–120 BPM、1–600 秒的運動與休息時間、1–99 輪。';

  @override
  String get timingSoundFailed => '無法播放聲音，計時器仍在運行。';

  @override
  String get queryTitle => '詢問紀錄';

  @override
  String get queryReadyBody =>
      '可以問「深蹲最重是多少？」「上個月做了多少伏地挺身？」「這個月臥推有進步嗎？」。裝置端AI理解問題，並從已儲存的紀錄計算數值。';

  @override
  String get queryManualBody => '自然語言提問需要裝置端AI準備就緒。運動名稱和備註搜尋隨時可用。';

  @override
  String get queryWorking => '正在理解問題…';

  @override
  String get queryFailed => '無法取得回答，請再試一次。';

  @override
  String get queryUnsupported => '請提出與運動紀錄有關的問題。';

  @override
  String get queryOffline => '連線後即可提問。';

  @override
  String get queryNoData => '缺少計算所需的已完成紀錄或數值。請檢查原始紀錄。';

  @override
  String queryPeriod(String start, String end) {
    return '$start – $end';
  }

  @override
  String get queryAllTime => '全部時間';

  @override
  String get queryPresent => '現在';

  @override
  String get queryRepUnit => '次';

  @override
  String get querySetUnit => '組';

  @override
  String get queryDayUnit => '天';

  @override
  String get queryAverage => '每組平均重量';

  @override
  String get queryMissingData => '紀錄中沒有此問題所需的運動或測量資訊。';

  @override
  String get queryAmbiguous => '請具體說明你指的是哪項運動的什麼紀錄。';

  @override
  String queryRank(int n) {
    return '第$n名';
  }

  @override
  String timingWorkSeconds(int n) {
    return '運動 $n 秒';
  }

  @override
  String timingRestSeconds(int n) {
    return '休息 $n 秒';
  }

  @override
  String timingRounds(int n) {
    return '$n 輪';
  }

  @override
  String timingBeat(String count) {
    return '第 $count 拍';
  }

  @override
  String timingHeart(int bpm, int target) {
    return '♥ $bpm → $target';
  }

  @override
  String get accountSignIn => '登入並備份';

  @override
  String get accountSignOut => '登出';

  @override
  String get planMonthly => '月費方案';

  @override
  String get planLifetime => '永久方案';

  @override
  String get planActive => '使用中';

  @override
  String get restorePurchases => '回復購買';

  @override
  String get quotaSpent => '本月的提問次數已用完。';

  @override
  String gymMember(String gym, String trainer) {
    return '$gym · $trainer';
  }

  @override
  String gymOnly(String gym) {
    return '$gym';
  }

  @override
  String routineFromTrainer(String gym) {
    return '來自$gym';
  }

  @override
  String get partnerInvite => '一起訓練';

  @override
  String get partnerCode => '把這個號碼告訴對方';

  @override
  String get partnerEnter => '輸入號碼';

  @override
  String partnerJoined(String name) {
    return '與$name一起記錄';
  }

  @override
  String get partnerFailed => '號碼不對或已過期。';

  @override
  String bookingNext(String trainer, String when) {
    return '$trainer · $when';
  }

  @override
  String get bookingNew => '預約私教';

  @override
  String get bookingNone => '當天沒有空閒時間。';

  @override
  String get bookingCancel => '取消預約';

  @override
  String get countAloud => '朗讀節拍計數';

  @override
  String get metricMax => '最高';

  @override
  String get metricTrend => '趨勢';

  @override
  String get metricLast => '上次';

  @override
  String get metricSessions => '天數';

  @override
  String get metricVolume => '總量';

  @override
  String get metricReps => '總次數';

  @override
  String get metricSets => '組數';

  @override
  String get metricAverage => '平均';

  @override
  String get readAsConfirm => '理解為';

  @override
  String get confirmYes => '對';

  @override
  String readAsNote(String from, String to) {
    return '$from → $to';
  }

  @override
  String get reviewNumbers => '套用前請確認數字和條件。';

  @override
  String get querySourceOnly => '查看原始紀錄';

  @override
  String get queryCompareOrder => '第二個時段 − 第一個時段';

  @override
  String queryRankingLimit(int n) {
    return '前$n項 · 遞減';
  }
}
