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
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString 千卡';
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
  String setsPerLineMax(int n) {
    return '每行最多 $n 组，请分成几行输入。';
  }

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
  String get aiFallbackQuota => '今天的输入辅助已用完，已按原文添加';

  @override
  String get aiFallbackOffline => '无法连接，已按原文添加。可在卡片的⚙中添加设置';

  @override
  String get aiFallbackServer => '服务器没有响应，已按原文添加。可在卡片的⚙中添加设置';

  @override
  String get aiFallbackUnread => '没有找到可设置的内容，已按原文添加。可在卡片的⚙中添加设置';

  @override
  String get inputNameTooLong => '动作名称最多120个字 — 请分行输入';

  @override
  String get inputTooLong => '超过600个字的文字不会读取 — 请分行输入';

  @override
  String get setupAdd => '添加设置';

  @override
  String setupUnparsed(String words) {
    return '未转入设置的内容：$words — 保留在标题中';
  }

  @override
  String setupDropped(String numbers) {
    return '已去掉原文中没有的数字：$numbers';
  }

  @override
  String get setupNameMissing => '请输入动作名称';

  @override
  String get setupNameTooLong => '最多120个字';

  @override
  String get setupWeightInvalid => '请输入大于0且不超过2000的数字';

  @override
  String get setupCountInvalid => '请输入1以上的整数 — 范围和时间请留在标题中';

  @override
  String get setupMergeUp => '合并到上一个动作';

  @override
  String get setupKeepApart => '分开保留';

  @override
  String get setupRepsOnly => '只记次数';

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
  String get accountSignIn => '登录';

  @override
  String get accountSignOut => '退出登录';

  @override
  String get planMonthly => '月度会员';

  @override
  String get planYearly => '年度会员';

  @override
  String planYearlyTrial(int days, String price) {
    return '免费试用 $days 天，之后每年 $price。在试用结束前至少 24 小时取消，就不会扣费。';
  }

  @override
  String planYearlyTrialPlates(int n) {
    return '免费试用期间补满到 $n 片。开始扣费后改为每月补满。';
  }

  @override
  String get planActive => '使用中';

  @override
  String get restorePurchases => '恢复购买';

  @override
  String get subscriptionRenews =>
      '除非在当前周期结束前至少 24 小时取消，订阅会按相同价格自动续订。可随时在商店的订阅管理中取消。';

  @override
  String get termsOfUse => '使用条款（EULA）';

  @override
  String get inputQuotaSpent => '今天的输入帮助已用完。自己输入照样会记录。';

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
  String get metricE1rm => '估算1RM';

  @override
  String get metricMaxReps => '最多次数';

  @override
  String get metricLongest => '最长';

  @override
  String get metricFirst => '首次';

  @override
  String get metricDaysSince => '未练天数';

  @override
  String get metricDistance => '总距离';

  @override
  String get metricDuration => '总时长';

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
  String get queryByExercise => '按动作';

  @override
  String get queryByDay => '按天';

  @override
  String get queryByWeek => '按周（周一开始）';

  @override
  String get queryByMonth => '按月';

  @override
  String get queryByWeekday => '按星期';

  @override
  String get queryTotalSum => '合计';

  @override
  String get queryTotalMean => '平均';

  @override
  String queryDiff(String later, String earlier) {
    return '差值（$later − $earlier）';
  }

  @override
  String queryExclude(String names) {
    return '除$names外';
  }

  @override
  String queryMemo(String terms) {
    return '备注：$terms';
  }

  @override
  String queryLastSessions(int n) {
    return '最近$n次';
  }

  @override
  String queryBottomLimit(int n) {
    return '后$n项 · 升序';
  }

  @override
  String queryOutOfScope(String names) {
    return '不适用（此指标无数值）：$names';
  }

  @override
  String queryMissingFor(String names) {
    return '未计算（有缺值的组）：$names';
  }

  @override
  String get queryE1rmRule => '估算1RM = 重量 × (1 + 次数 ÷ 30)，仅限1–10次的组';

  @override
  String queryMore(int n) {
    return '另外$n项';
  }

  @override
  String queryRankingLimit(int n) {
    return '前$n项 · 降序';
  }

  @override
  String get queryCompareChip => '比较';

  @override
  String get queryNoRecord => '无记录';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsRecording => '记录';

  @override
  String get settingsAccount => '账户';

  @override
  String get settingsGym => '你的健身房';

  @override
  String get settingsNoGym => '用手机碰一下健身房的贴纸，就能收到教练写的训练计划。';

  @override
  String get proTitle => 'Pro 会员';

  @override
  String get proBody =>
      '向记录提问会用掉杠铃片——通常每个问题约 1 片，只扣回答实际用掉的量。记录训练和饮食时的输入帮助不用杠铃片。';

  @override
  String proFree(int n, int sets) {
    return '免费：输入帮助每天 $n 次 · 完成 $sets 组的当天送 1 片';
  }

  @override
  String proPaid(int n, int input) {
    return 'Pro：每月补满到 $n 片 · 输入帮助每天 $input 次';
  }

  @override
  String get proEverythingElseFree => '记录、计时、手腕提醒、一起训练和健身房功能，不订阅也全部可用。';

  @override
  String get proOwned => '已开通，谢谢。';

  @override
  String get proSignInFirst => '订阅绑定账户，请先登录。';

  @override
  String platesBalance(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '剩余杠铃片 $nString 片';
  }

  @override
  String platesSpent(num spent, num balance) {
    final intl.NumberFormat spentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String spentString = spentNumberFormat.format(spent);
    final intl.NumberFormat balanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String balanceString = balanceNumberFormat.format(balance);

    return '用了 $spentString 片 · 剩余 $balanceString 片';
  }

  @override
  String noPlates(int sets) {
    return '杠铃片不够了。每天完成 $sets 组可得 1 片。';
  }

  @override
  String noPlatesSignIn(int n) {
    return '登录 · 新账号领取 $n 片';
  }

  @override
  String platesGetPro(int n) {
    return '查看 Pro · 每月 $n 片';
  }

  @override
  String get purchaseNotConfirmed => '无法确认这次购买。如果已扣款，请稍后点“恢复购买”。';

  @override
  String get purchaseOtherAccount => '这笔购买已关联到另一个账号。请用那个账号登录。';

  @override
  String get tagSignInNeeded => '登录后即可与健身房连接。';

  @override
  String get tagJoinSent => '已提交申请。教练确认后即可开始。';

  @override
  String get tagJoinWaiting => '已经申请过了，教练正在确认。';

  @override
  String get tagJoinFailed => '申请没有发送成功。稍后再碰一下贴纸。';

  @override
  String get bookingPending => '待确认';

  @override
  String get bookingWhichGym => '哪一家健身房？';

  @override
  String get tagSignIn => '登录';

  @override
  String get accountDelete => '注销账号';

  @override
  String get accountDeleteAsk => '无法撤销。训练计划、记录、次卡和预约都会消失。';

  @override
  String get accountDeleteDo => '确认注销';

  @override
  String get accountDeleteFailed => '注销失败，请稍后再试。';

  @override
  String get signInFailed => '登录失败，请稍后再试。';

  @override
  String get bookingTitle => 'PT 预约';

  @override
  String get bookingConfirmed => '已确认';

  @override
  String bookingRemaining(int n) {
    return '剩余 $n 次';
  }

  @override
  String get bookingNoPass => '没有 PT 次卡，请联系教练。';

  @override
  String bookingNoHours(String trainer) {
    return '$trainer 教练还没有开放时间。';
  }

  @override
  String get bookingPick => '选择时间';

  @override
  String bookingWith(String trainer, int minutes) {
    return '$trainer 教练 · 每次 $minutes 分钟';
  }

  @override
  String get bookingSent => '已提交申请，教练确认后生效。';

  @override
  String get bookingUpcoming => '即将到来';

  @override
  String get bookingClosedDay => '这天不接受预约。';

  @override
  String get bookingCancelAsk => '取消这次预约吗？';

  @override
  String get ok => '好';

  @override
  String get mealPhoto => '餐食照片';

  @override
  String get mealCamera => '相机';

  @override
  String get mealGallery => '从相册';

  @override
  String get mealEstimating => '正在估算热量…';

  @override
  String mealIntake(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '摄入约 $nString 千卡';
  }

  @override
  String get mealFailed => '无法从这张照片估算热量，请重新拍摄。';

  @override
  String get mealEstimateNote => '根据照片估算';

  @override
  String mealServingsOption(String n) {
    return '$n 份';
  }

  @override
  String get fitAll => '今天的训练';

  @override
  String get sameDayOther => '当天的其他记录';

  @override
  String get mealText => '记录饮食';

  @override
  String get mealTextHint => '吃了什么？例如：香蕉2根，牛奶200ml';

  @override
  String kcalApprox(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '约 $nString 千卡';
  }

  @override
  String get mealKcalUnknown => '热量未知';

  @override
  String mealIntakePartial(int n, int m) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '摄入 $nString 千卡 + $m 项热量未知';
  }

  @override
  String get mealAmountAsk => '吃了多少？';

  @override
  String get mealBasis => '基准';

  @override
  String get mealEaten => '食用量';

  @override
  String get mealUnitServing => '份';

  @override
  String get mealUnitPackage => '整包';

  @override
  String get mealUnitPhoto => '照片中的食物';

  @override
  String get mealWhole => '全部';

  @override
  String get mealHalf => '一半';

  @override
  String get mealPhotoWholeNote => '这是照片中全部食物的估算值，请选择您吃了其中多少。';

  @override
  String get mealTextUnknown => '无法识别这种食物，未能估算热量。点按这餐补充食物名称或分量，即可重新估算。';

  @override
  String get mealTextOffline => '无法连接，未能估算热量。点按这餐后按 Enter 即可重新估算。';

  @override
  String get mealTextTooLong => '超过 500 字的饮食记录不会估算。点按这餐分开记录即可估算。';

  @override
  String queryTooLong(int max) {
    return '问题最多 $max 个字。请缩短后再问。';
  }

  @override
  String get queryPressEnter => '按 Enter 即可询问您的记录。';

  @override
  String get mealRetry => '重新估算';

  @override
  String kcalAtLeast(int n) {
    return '至少 $n 千卡';
  }

  @override
  String mealTextPartial(int n) {
    return '只计入了你写的 $n 千卡，其余食物的热量未知。';
  }

  @override
  String mealTextBelowTyped(int n) {
    return '估算值低于你写的 $n 千卡，因此未采用。只计入了你写的 $n 千卡。';
  }

  @override
  String queryLimit(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'exercises': '一次最多可问 8 个动作。请分开提问。',
      'measures': '一次最多统计 3 项。请分开提问。',
      'ranking': '排名最多显示 20 个。请问 20 个以内。',
      'sessions': '“最近 N 次”最多 100 次。想看更久，请按时间段提问，例如今年。',
      'days': '“最近 N 天”最多 3660 天（约 10 年）。想看更久，请按全部时间提问。',
      'compare': '一次最多对比 4 项。请分开提问。',
      'compareGrouped': '同一个问题不能既对比又按动作、日、周、月或星期分组。请二选一提问。',
      'groupedMeasure': '按日、周、月或星期分组时只能统计一项，且趋势、最后一次、第一次、距上次天数不能分组。',
      'ordering': '排名、合计和平均需要分组，例如按动作或按周。',
      'datesTotal': '最后一次和第一次的日期不能相加或求平均。',
      'other': '记录搜索无法计算这种形式的问题。请分开提问。',
    });
    return '$_temp0';
  }

  @override
  String policyNumberRejected(String text, String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'decimal': '“$text”— 不接受小数。请输入整数，例如 14',
      'range': '“$text”— 请输入一个数字，而不是范围，例如 14',
      'negative': '“$text”— 不接受小于 0 的数，例如 14',
      'unit': '“$text”— 此栏按天数或次数计。请把小时、周或月换算成天数，例如 14',
      'other': '无法从“$text”中读出天数或次数。请输入数字，例如 14',
    });
    return '$_temp0';
  }

  @override
  String get mealSources => '来源';

  @override
  String get mealSourcesTitle => '热量依据';

  @override
  String get mealSourcesNote => '按下表中的数值计算。点按可在原始数据表中打开该名称。表中没有的食物由 AI 估算。';

  @override
  String mealSourcePer(String unit, String kcal) {
    return '每100$unit ${kcal}kcal';
  }

  @override
  String get mealSourceMfds => '韩国食品药品安全处 食品营养成分数据库';

  @override
  String get mealSourceUsda => 'USDA FoodData Central';

  @override
  String get mealAmountInvalid => '请输入不小于 0 的数字。';

  @override
  String dayEnergyFull(String intake, String burned, String diff) {
    return '摄入 $intake · 运动 $burned = $diff 千卡';
  }

  @override
  String dayEnergyApprox(String intake, String burned, String diff) {
    return '摄入 约 $intake · 运动 $burned ≈ $diff 千卡';
  }

  @override
  String get dayBurnedMissing => '运动消耗未测量 · 无法计算差值';

  @override
  String dayBurnedOnly(String n) {
    return '运动 $n 千卡 · 未记录饮食';
  }

  @override
  String get intakeLabel => '摄入';

  @override
  String get partnerSignIn => '需要登录才能一起训练。';

  @override
  String get partnerSignInAction => '登录';

  @override
  String get partnerMakeCode => '生成代码';

  @override
  String get partnerCopy => '复制';

  @override
  String partnerExpiresIn(String t) {
    return '$t 后过期';
  }

  @override
  String get partnerExpired => '代码已过期。';

  @override
  String get partnerNewCode => '新代码';

  @override
  String get partnerStopWaiting => '停止';

  @override
  String partnerWith(String name) {
    return '正在与 $name 一起训练';
  }

  @override
  String get partnerReconnecting => '正在重新连接 · 你的记录会继续保存';

  @override
  String partnerTheirRecord(String name) {
    return '$name 的记录';
  }

  @override
  String get partnerNoRecordYet => '还没有记录。';

  @override
  String get partnerLoading => '加载中…';

  @override
  String get partnerEnd => '结束一起训练';

  @override
  String get partnerEndedByMe => '你已结束一起训练，你的记录保留不变。';

  @override
  String partnerEndedByThem(String name) {
    return '$name 已结束一起训练，你的记录保留不变。';
  }

  @override
  String get partnerErrFormat => '代码为六位，请再确认。';

  @override
  String get partnerErrInvalid => '没有这个代码，可能已被使用或输入有误。';

  @override
  String get partnerErrExpired => '代码已过期，请让对方重新生成。';

  @override
  String get partnerErrEnded => '该邀请已结束。';

  @override
  String get partnerErrOwn => '这是你自己生成的代码，请在对方设备上输入。';

  @override
  String get partnerErrTries => '尝试次数过多，请稍后再试。';

  @override
  String get partnerErrNetwork => '无法连接服务器，请检查网络后重试。';

  @override
  String get partnerErrServer => '服务器出现问题，请稍后重试。';

  @override
  String get partnerRetry => '重试';

  @override
  String get partnerReadOnly => '只读';

  @override
  String get partnerConflict => '你的另一台设备共享了更新的记录。本机记录已保存，只是暂停了共享。';

  @override
  String get partnerShareThisDevice => '用本机记录共享';

  @override
  String get plansTitle => '共同计划';

  @override
  String get planNew => '新建共同计划';

  @override
  String get planJoin => '用代码加入';

  @override
  String get planHint => '第一行是标题，之后每行一个动作\n例：深蹲 4组';

  @override
  String get planDateNone => '日期未定';

  @override
  String planSetsCount(int n) {
    return '$n组';
  }

  @override
  String get planSave => '提出';

  @override
  String get planStateLocal => '仅在本机的草稿 · 尚未上传';

  @override
  String get planStateDraft => '草稿 · 还没有同伴';

  @override
  String planStateWaiting(int v) {
    return '等待对方确认 · 版本 $v';
  }

  @override
  String planStateNeedsMe(String name, int v) {
    return '$name 已修改 · 版本 $v 需要你确认';
  }

  @override
  String planStateAgreed(int v) {
    return '已达成一致 · 版本 $v';
  }

  @override
  String get planStateWithdrawn => '共同计划已结束 · 已达成的计划和你的目标保留';

  @override
  String planAccept(int v) {
    return '接受版本 $v';
  }

  @override
  String get planChanged => '与上次一致版本相比的变化';

  @override
  String planAdded(String x) {
    return '新增：$x';
  }

  @override
  String planRemoved(String x) {
    return '移除：$x';
  }

  @override
  String planSetsChanged(String x) {
    return '组数变化：$x';
  }

  @override
  String get planReordered => '顺序已变化';

  @override
  String get planDateChanged => '日期已变化';

  @override
  String get planTitleChanged => '标题已变化';

  @override
  String planLastAgreed(int v) {
    return '上次一致的计划 · 版本 $v';
  }

  @override
  String get planConflict => '对方先修改了，你的草稿仍然保留。';

  @override
  String planLatest(int v) {
    return '对方的最新计划 · 版本 $v';
  }

  @override
  String get planKeepMine => '用我的草稿重新提出';

  @override
  String get planTakeLatest => '改用最新计划';

  @override
  String get planMyTarget => '我的目标';

  @override
  String planPartnerTarget(String name, String t) {
    return '$name：$t';
  }

  @override
  String get planTargetHint => '例：100 5 或 100kg 5次 x3 备注';

  @override
  String get planInvite => '生成邀请代码';

  @override
  String get planStart => '按此计划开始';

  @override
  String get planStartSolo => '用我自己的副本开始';

  @override
  String get planStartSoloNote => '尚未达成一致。现在开始将使用你自己的副本，而不是已达成一致的计划。';

  @override
  String get planOpenWorkout => '打开已开始的训练';

  @override
  String get planCopyNext => '复制到下一次训练';

  @override
  String get planWithdraw => '退出此共同计划';

  @override
  String get planCompare => '计划与实际';

  @override
  String planDoneSets(String name, int planned, int done) {
    return '$name · 计划 $planned 组 · 完成 $done 组';
  }

  @override
  String planAddedActual(String x) {
    return '计划外：$x';
  }

  @override
  String planSkipped(String x) {
    return '未做：$x';
  }

  @override
  String planStartedFrom(int v) {
    return '从已达成一致的共同计划（版本 $v）开始';
  }

  @override
  String planStartedSolo(int v) {
    return '从你自己的副本（版本 $v，未达成一致）开始';
  }

  @override
  String get planShareLink => '发送邀请链接';

  @override
  String planShareText(String url) {
    return '在 setpad 一起制定训练计划：$url';
  }

  @override
  String get planLinkCopied => '已复制链接，一天内可使用一次。';

  @override
  String get planLinkJoining => '正在加入受邀的计划…';

  @override
  String get nearbyHint => 'iPhone 之间，保持此画面打开并将两台手机靠近也可以连接。';

  @override
  String get planPropose => '提议为共同计划';

  @override
  String get togetherStart => '一起开始';

  @override
  String get togetherAlternate => '轮流';

  @override
  String togetherWaiting(String name) {
    return '正在等待$name…';
  }

  @override
  String get togetherWaitingHint => '请求会显示在对方屏幕上。如果没有，请确认对方的应用是最新版本。';

  @override
  String togetherInvite(String name) {
    return '$name邀请你一起做';
  }

  @override
  String get togetherInviteAlternate => '轮流 · 对方先';

  @override
  String get togetherLeave => '停止';

  @override
  String get togetherRejoin => '重新加入';

  @override
  String togetherWith(String name) {
    return '与$name一起';
  }

  @override
  String get togetherTheirTurn => '对方的回合';

  @override
  String togetherLeftBeat(String name, int n) {
    return '$name在第$n拍停下';
  }

  @override
  String togetherLeftRound(String name, int n) {
    return '$name在第$n回合停下';
  }

  @override
  String get togetherMe => '我';

  @override
  String get togetherLog => '记录';

  @override
  String get mealLogAs => '记为饮食';

  @override
  String get proxyWrite => '代为记录';

  @override
  String proxyWriting(String name) {
    return '正在记录$name的训练';
  }

  @override
  String get proxyDefaultName => '对方';

  @override
  String get proxyHand => '交给对方';

  @override
  String get proxyBack => '回到我的记录';

  @override
  String proxyShareText(String url) {
    return '一起训练时替你记下的记录。在 setpad 中打开并接收，就会成为你的训练记录。\n$url';
  }

  @override
  String handoffOffer(String name) {
    return '$name替你记下了训练';
  }

  @override
  String get handoffTake => '接收';

  @override
  String get handoffFailed => '无法接收记录。链接可能已过期，或网络有问题。';

  @override
  String get handoffSignIn => '需要登录才能接收交给你的记录。';

  @override
  String partnerInviteMore(String code) {
    return '再邀请一人 · 代码 $code';
  }

  @override
  String get proxyWhose => '要记录谁的训练？';

  @override
  String planMemberAccepted(String name) {
    return '$name 已同意';
  }

  @override
  String planMemberWaiting(String name) {
    return '$name 尚未确认';
  }

  @override
  String deleteNoteAsk(String title) {
    return '删除“$title”？';
  }

  @override
  String get mealsTitle => '饮食';

  @override
  String get recordMenu => '更多';

  @override
  String dayIntakeOnly(String intake) {
    return '摄入 $intake 千卡 · 运动消耗未测量';
  }

  @override
  String dayIntakeOnlyApprox(String intake) {
    return '摄入 约 $intake 千卡 · 运动消耗未测量';
  }

  @override
  String dayUnknownMeals(int m) {
    return '$m 项热量未知';
  }

  @override
  String get healthDataTitle => '健康数据';

  @override
  String get healthDataIntro =>
      'setpad 与健康应用(Apple 健康、Health Connect)交换的内容及原因。';

  @override
  String get healthDataWrite => '写入 · 体能训练 — 完成记录后,会保存为一次体能训练。';

  @override
  String get healthDataCalories =>
      '读取 · 活动能量 — 训练期间手表测得的活动能量会附到该记录上。没有测量时不显示热量。';

  @override
  String get healthDataHeart =>
      '读取 · 心率 — Tabata 休息期间,心率比该轮最高值低 25 bpm 时,休息结束并提示下一轮开始。休息时计时器一行显示 ♥ 当前 → 目标。没有心率或读数超过 90 秒时,休息按时结束。';

  @override
  String get healthDataStays => '从健康应用读取的数据不会离开本设备。不会发送到服务器,也不会用于广告或营销。';

  @override
  String get healthDataRevokeIos =>
      '可随时在 iPhone 设置 → 隐私与安全性 → 健康 → setpad 中关闭。';

  @override
  String get healthDataRevokeAndroid =>
      '可随时在 Health Connect → 应用权限 → setpad 中关闭。';

  @override
  String get healthDataPrivacy => '隐私政策';

  @override
  String get restAlarmTitle => '下一轮 — 心率已降下来';

  @override
  String liveSetBusy(String name) {
    return '$name 正在编辑这一组。等对方改完再点。';
  }

  @override
  String liveExerciseBusy(String name) {
    return '$name 正在记录这个动作。';
  }

  @override
  String liveExerciseRemoved(String exercise) {
    return '一起训练的人删除了 $exercise。你正在输入的内容还在输入栏里。';
  }

  @override
  String get trainerReport => '教练报告';

  @override
  String get trainerUnread => '新报告';

  @override
  String trainerRanAt(String when) {
    return '$when 整理';
  }

  @override
  String get trainerRunNow => '立即整理';

  @override
  String get trainerNoReport => '还没有报告。现在整理一份吗？';

  @override
  String get trainerOutdated => '此报告需要新版本查看，请更新应用。';

  @override
  String get trainerFailed => '无法连接服务器，请稍后再试。';

  @override
  String get trainerActUnknown => '未能确认结果。再按一次也不会重复记录。';

  @override
  String get trainerDone => '代理已处理';

  @override
  String get trainerToday => '今日课程';

  @override
  String get trainerTodo => '待确认';

  @override
  String get trainerAllClear => '待确认事项已全部处理。';

  @override
  String get trainerAttendance => '待收尾的课程';

  @override
  String trainerVisited(String time) {
    return '确认到店 $time';
  }

  @override
  String trainerFinishAll(int count) {
    return '全部完成 ($count)';
  }

  @override
  String trainerFinishAsk(int count) {
    return '完成 $count 项 — 每项从私教课次卡扣除 1 次。';
  }

  @override
  String get trainerFinish => '确认完成';

  @override
  String get trainerJoinRequest => '注册申请 — 请在网页版 CRM 的“今天”页面确认。';

  @override
  String get trainerBook => '预约';

  @override
  String get trainerSend => '发送';

  @override
  String get trainerPaid => '已收款';

  @override
  String get trainerContacted => '已联系';

  @override
  String get trainerLater => '稍后';

  @override
  String trainerPrice(int price) {
    final intl.NumberFormat priceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String priceString = priceNumberFormat.format(price);

    return '₩$priceString';
  }

  @override
  String trainerStarts(String d) {
    return '$d起';
  }

  @override
  String get trainerPayHow => '以什么方式收款？';

  @override
  String get trainerPaidListPrice =>
      '将按商品原价记为已收款。折扣或分期收款请在网页 CRM 会员页面的会员卡标签中登记。';

  @override
  String get payCard => '刷卡';

  @override
  String get payCash => '现金';

  @override
  String get payTransfer => '转账';

  @override
  String get payOther => '其他';

  @override
  String get agentSettings => '代理设置';

  @override
  String get agentEnabled => '在设定时间整理';

  @override
  String get agentTimes => '整理时间';

  @override
  String get agentAddTime => '添加时间';

  @override
  String get agentDays => '星期';

  @override
  String get agentAutoConfirm => '私教申请立即确认';

  @override
  String get agentModes => '按任务';

  @override
  String get agentModesHelp => '手动 — 代理不处理。草稿 — 代理准备好，你点一下完成。自动 — 代理直接处理。';

  @override
  String get agentModeOff => '手动';

  @override
  String get agentModeDraft => '草稿';

  @override
  String get agentModeAuto => '自动';

  @override
  String get taskPtSchedule => '私教日程';

  @override
  String get taskRenewal => '续费';

  @override
  String get taskAttendance => '出勤整理';

  @override
  String get taskRoutine => '训练计划';

  @override
  String get taskContact => '联系会员';

  @override
  String get gymPolicy => '健身房规则';

  @override
  String get policyRenewalDays => '续费提醒时间（到期前几天）';

  @override
  String get policyLowSessions => '私教课不足标准（可预约次数）';

  @override
  String get policyAwayDays => '未到店标准（天）';

  @override
  String get policyLapsedDays => '流失期限（天）';

  @override
  String get policyOffer => '续费优惠文案';

  @override
  String get policySave => '保存规则';

  @override
  String get policySaved => '已保存。';

  @override
  String get trainerWhichGym => '哪一家健身房？';

  @override
  String get trainerBack => '返回';

  @override
  String get trainerCopy => '复制文案';

  @override
  String get trainerCopied => '已复制';

  @override
  String get settingsTrainer => '教练';
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
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString 千卡';
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
  String setsPerLineMax(int n) {
    return '每行最多 $n 组，请分成几行输入。';
  }

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
  String get aiFallbackQuota => '今天的输入辅助已用完，已按原文添加';

  @override
  String get aiFallbackOffline => '无法连接，已按原文添加。可在卡片的⚙中添加设置';

  @override
  String get aiFallbackServer => '服务器没有响应，已按原文添加。可在卡片的⚙中添加设置';

  @override
  String get aiFallbackUnread => '没有找到可设置的内容，已按原文添加。可在卡片的⚙中添加设置';

  @override
  String get inputNameTooLong => '动作名称最多120个字 — 请分行输入';

  @override
  String get inputTooLong => '超过600个字的文字不会读取 — 请分行输入';

  @override
  String get setupAdd => '添加设置';

  @override
  String setupUnparsed(String words) {
    return '未转入设置的内容：$words — 保留在标题中';
  }

  @override
  String setupDropped(String numbers) {
    return '已去掉原文中没有的数字：$numbers';
  }

  @override
  String get setupNameMissing => '请输入动作名称';

  @override
  String get setupNameTooLong => '最多120个字';

  @override
  String get setupWeightInvalid => '请输入大于0且不超过2000的数字';

  @override
  String get setupCountInvalid => '请输入1以上的整数 — 范围和时间请留在标题中';

  @override
  String get setupMergeUp => '合并到上一个动作';

  @override
  String get setupKeepApart => '分开保留';

  @override
  String get setupRepsOnly => '只记次数';

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
  String get accountSignIn => '登录';

  @override
  String get accountSignOut => '退出登录';

  @override
  String get planMonthly => '月度会员';

  @override
  String get planYearly => '年度会员';

  @override
  String planYearlyTrial(int days, String price) {
    return '免费试用 $days 天，之后每年 $price。在试用结束前至少 24 小时取消，就不会扣费。';
  }

  @override
  String planYearlyTrialPlates(int n) {
    return '免费试用期间补满到 $n 片。开始扣费后改为每月补满。';
  }

  @override
  String get planActive => '使用中';

  @override
  String get restorePurchases => '恢复购买';

  @override
  String get subscriptionRenews =>
      '除非在当前周期结束前至少 24 小时取消，订阅会按相同价格自动续订。可随时在商店的订阅管理中取消。';

  @override
  String get termsOfUse => '使用条款（EULA）';

  @override
  String get inputQuotaSpent => '今天的输入帮助已用完。自己输入照样会记录。';

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
  String get metricE1rm => '估算1RM';

  @override
  String get metricMaxReps => '最多次数';

  @override
  String get metricLongest => '最长';

  @override
  String get metricFirst => '首次';

  @override
  String get metricDaysSince => '未练天数';

  @override
  String get metricDistance => '总距离';

  @override
  String get metricDuration => '总时长';

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
  String get queryByExercise => '按动作';

  @override
  String get queryByDay => '按天';

  @override
  String get queryByWeek => '按周（周一开始）';

  @override
  String get queryByMonth => '按月';

  @override
  String get queryByWeekday => '按星期';

  @override
  String get queryTotalSum => '合计';

  @override
  String get queryTotalMean => '平均';

  @override
  String queryDiff(String later, String earlier) {
    return '差值（$later − $earlier）';
  }

  @override
  String queryExclude(String names) {
    return '除$names外';
  }

  @override
  String queryMemo(String terms) {
    return '备注：$terms';
  }

  @override
  String queryLastSessions(int n) {
    return '最近$n次';
  }

  @override
  String queryBottomLimit(int n) {
    return '后$n项 · 升序';
  }

  @override
  String queryOutOfScope(String names) {
    return '不适用（此指标无数值）：$names';
  }

  @override
  String queryMissingFor(String names) {
    return '未计算（有缺值的组）：$names';
  }

  @override
  String get queryE1rmRule => '估算1RM = 重量 × (1 + 次数 ÷ 30)，仅限1–10次的组';

  @override
  String queryMore(int n) {
    return '另外$n项';
  }

  @override
  String queryRankingLimit(int n) {
    return '前$n项 · 降序';
  }

  @override
  String get queryCompareChip => '比较';

  @override
  String get queryNoRecord => '无记录';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsRecording => '记录';

  @override
  String get settingsAccount => '账户';

  @override
  String get settingsGym => '你的健身房';

  @override
  String get settingsNoGym => '用手机碰一下健身房的贴纸，就能收到教练写的训练计划。';

  @override
  String get proTitle => 'Pro 会员';

  @override
  String get proBody =>
      '向记录提问会用掉杠铃片——通常每个问题约 1 片，只扣回答实际用掉的量。记录训练和饮食时的输入帮助不用杠铃片。';

  @override
  String proFree(int n, int sets) {
    return '免费：输入帮助每天 $n 次 · 完成 $sets 组的当天送 1 片';
  }

  @override
  String proPaid(int n, int input) {
    return 'Pro：每月补满到 $n 片 · 输入帮助每天 $input 次';
  }

  @override
  String get proEverythingElseFree => '记录、计时、手腕提醒、一起训练和健身房功能，不订阅也全部可用。';

  @override
  String get proOwned => '已开通，谢谢。';

  @override
  String get proSignInFirst => '订阅绑定账户，请先登录。';

  @override
  String platesBalance(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '剩余杠铃片 $nString 片';
  }

  @override
  String platesSpent(num spent, num balance) {
    final intl.NumberFormat spentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String spentString = spentNumberFormat.format(spent);
    final intl.NumberFormat balanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String balanceString = balanceNumberFormat.format(balance);

    return '用了 $spentString 片 · 剩余 $balanceString 片';
  }

  @override
  String noPlates(int sets) {
    return '杠铃片不够了。每天完成 $sets 组可得 1 片。';
  }

  @override
  String noPlatesSignIn(int n) {
    return '登录 · 新账号领取 $n 片';
  }

  @override
  String platesGetPro(int n) {
    return '查看 Pro · 每月 $n 片';
  }

  @override
  String get purchaseNotConfirmed => '无法确认这次购买。如果已扣款，请稍后点“恢复购买”。';

  @override
  String get purchaseOtherAccount => '这笔购买已关联到另一个账号。请用那个账号登录。';

  @override
  String get tagSignInNeeded => '登录后即可与健身房连接。';

  @override
  String get tagJoinSent => '已提交申请。教练确认后即可开始。';

  @override
  String get tagJoinWaiting => '已经申请过了，教练正在确认。';

  @override
  String get tagJoinFailed => '申请没有发送成功。稍后再碰一下贴纸。';

  @override
  String get bookingPending => '待确认';

  @override
  String get bookingWhichGym => '哪一家健身房？';

  @override
  String get tagSignIn => '登录';

  @override
  String get accountDelete => '注销账号';

  @override
  String get accountDeleteAsk => '无法撤销。训练计划、记录、次卡和预约都会消失。';

  @override
  String get accountDeleteDo => '确认注销';

  @override
  String get accountDeleteFailed => '注销失败，请稍后再试。';

  @override
  String get signInFailed => '登录失败，请稍后再试。';

  @override
  String get bookingTitle => 'PT 预约';

  @override
  String get bookingConfirmed => '已确认';

  @override
  String bookingRemaining(int n) {
    return '剩余 $n 次';
  }

  @override
  String get bookingNoPass => '没有 PT 次卡，请联系教练。';

  @override
  String bookingNoHours(String trainer) {
    return '$trainer 教练还没有开放时间。';
  }

  @override
  String get bookingPick => '选择时间';

  @override
  String bookingWith(String trainer, int minutes) {
    return '$trainer 教练 · 每次 $minutes 分钟';
  }

  @override
  String get bookingSent => '已提交申请，教练确认后生效。';

  @override
  String get bookingUpcoming => '即将到来';

  @override
  String get bookingClosedDay => '这天不接受预约。';

  @override
  String get bookingCancelAsk => '取消这次预约吗？';

  @override
  String get ok => '好';

  @override
  String get mealPhoto => '餐食照片';

  @override
  String get mealCamera => '相机';

  @override
  String get mealGallery => '从相册';

  @override
  String get mealEstimating => '正在估算热量…';

  @override
  String mealIntake(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '摄入约 $nString 千卡';
  }

  @override
  String get mealFailed => '无法从这张照片估算热量，请重新拍摄。';

  @override
  String get mealEstimateNote => '根据照片估算';

  @override
  String mealServingsOption(String n) {
    return '$n 份';
  }

  @override
  String get fitAll => '今天的训练';

  @override
  String get sameDayOther => '当天的其他记录';

  @override
  String get mealText => '记录饮食';

  @override
  String get mealTextHint => '吃了什么？例如：香蕉2根，牛奶200ml';

  @override
  String kcalApprox(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '约 $nString 千卡';
  }

  @override
  String get mealKcalUnknown => '热量未知';

  @override
  String mealIntakePartial(int n, int m) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '摄入 $nString 千卡 + $m 项热量未知';
  }

  @override
  String get mealAmountAsk => '吃了多少？';

  @override
  String get mealBasis => '基准';

  @override
  String get mealEaten => '食用量';

  @override
  String get mealUnitServing => '份';

  @override
  String get mealUnitPackage => '整包';

  @override
  String get mealUnitPhoto => '照片中的食物';

  @override
  String get mealWhole => '全部';

  @override
  String get mealHalf => '一半';

  @override
  String get mealPhotoWholeNote => '这是照片中全部食物的估算值，请选择您吃了其中多少。';

  @override
  String get mealTextUnknown => '无法识别这种食物，未能估算热量。点按这餐补充食物名称或分量，即可重新估算。';

  @override
  String get mealTextOffline => '无法连接，未能估算热量。点按这餐后按 Enter 即可重新估算。';

  @override
  String get mealTextTooLong => '超过 500 字的饮食记录不会估算。点按这餐分开记录即可估算。';

  @override
  String queryTooLong(int max) {
    return '问题最多 $max 个字。请缩短后再问。';
  }

  @override
  String get queryPressEnter => '按 Enter 即可询问您的记录。';

  @override
  String get mealRetry => '重新估算';

  @override
  String kcalAtLeast(int n) {
    return '至少 $n 千卡';
  }

  @override
  String mealTextPartial(int n) {
    return '只计入了你写的 $n 千卡，其余食物的热量未知。';
  }

  @override
  String mealTextBelowTyped(int n) {
    return '估算值低于你写的 $n 千卡，因此未采用。只计入了你写的 $n 千卡。';
  }

  @override
  String queryLimit(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'exercises': '一次最多可问 8 个动作。请分开提问。',
      'measures': '一次最多统计 3 项。请分开提问。',
      'ranking': '排名最多显示 20 个。请问 20 个以内。',
      'sessions': '“最近 N 次”最多 100 次。想看更久，请按时间段提问，例如今年。',
      'days': '“最近 N 天”最多 3660 天（约 10 年）。想看更久，请按全部时间提问。',
      'compare': '一次最多对比 4 项。请分开提问。',
      'compareGrouped': '同一个问题不能既对比又按动作、日、周、月或星期分组。请二选一提问。',
      'groupedMeasure': '按日、周、月或星期分组时只能统计一项，且趋势、最后一次、第一次、距上次天数不能分组。',
      'ordering': '排名、合计和平均需要分组，例如按动作或按周。',
      'datesTotal': '最后一次和第一次的日期不能相加或求平均。',
      'other': '记录搜索无法计算这种形式的问题。请分开提问。',
    });
    return '$_temp0';
  }

  @override
  String policyNumberRejected(String text, String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'decimal': '“$text”— 不接受小数。请输入整数，例如 14',
      'range': '“$text”— 请输入一个数字，而不是范围，例如 14',
      'negative': '“$text”— 不接受小于 0 的数，例如 14',
      'unit': '“$text”— 此栏按天数或次数计。请把小时、周或月换算成天数，例如 14',
      'other': '无法从“$text”中读出天数或次数。请输入数字，例如 14',
    });
    return '$_temp0';
  }

  @override
  String get mealSources => '来源';

  @override
  String get mealSourcesTitle => '热量依据';

  @override
  String get mealSourcesNote => '按下表中的数值计算。点按可在原始数据表中打开该名称。表中没有的食物由 AI 估算。';

  @override
  String mealSourcePer(String unit, String kcal) {
    return '每100$unit ${kcal}kcal';
  }

  @override
  String get mealSourceMfds => '韩国食品药品安全处 食品营养成分数据库';

  @override
  String get mealSourceUsda => 'USDA FoodData Central';

  @override
  String get mealAmountInvalid => '请输入不小于 0 的数字。';

  @override
  String dayEnergyFull(String intake, String burned, String diff) {
    return '摄入 $intake · 运动 $burned = $diff 千卡';
  }

  @override
  String dayEnergyApprox(String intake, String burned, String diff) {
    return '摄入 约 $intake · 运动 $burned ≈ $diff 千卡';
  }

  @override
  String get dayBurnedMissing => '运动消耗未测量 · 无法计算差值';

  @override
  String dayBurnedOnly(String n) {
    return '运动 $n 千卡 · 未记录饮食';
  }

  @override
  String get intakeLabel => '摄入';

  @override
  String get partnerSignIn => '需要登录才能一起训练。';

  @override
  String get partnerSignInAction => '登录';

  @override
  String get partnerMakeCode => '生成代码';

  @override
  String get partnerCopy => '复制';

  @override
  String partnerExpiresIn(String t) {
    return '$t 后过期';
  }

  @override
  String get partnerExpired => '代码已过期。';

  @override
  String get partnerNewCode => '新代码';

  @override
  String get partnerStopWaiting => '停止';

  @override
  String partnerWith(String name) {
    return '正在与 $name 一起训练';
  }

  @override
  String get partnerReconnecting => '正在重新连接 · 你的记录会继续保存';

  @override
  String partnerTheirRecord(String name) {
    return '$name 的记录';
  }

  @override
  String get partnerNoRecordYet => '还没有记录。';

  @override
  String get partnerLoading => '加载中…';

  @override
  String get partnerEnd => '结束一起训练';

  @override
  String get partnerEndedByMe => '你已结束一起训练，你的记录保留不变。';

  @override
  String partnerEndedByThem(String name) {
    return '$name 已结束一起训练，你的记录保留不变。';
  }

  @override
  String get partnerErrFormat => '代码为六位，请再确认。';

  @override
  String get partnerErrInvalid => '没有这个代码，可能已被使用或输入有误。';

  @override
  String get partnerErrExpired => '代码已过期，请让对方重新生成。';

  @override
  String get partnerErrEnded => '该邀请已结束。';

  @override
  String get partnerErrOwn => '这是你自己生成的代码，请在对方设备上输入。';

  @override
  String get partnerErrTries => '尝试次数过多，请稍后再试。';

  @override
  String get partnerErrNetwork => '无法连接服务器，请检查网络后重试。';

  @override
  String get partnerErrServer => '服务器出现问题，请稍后重试。';

  @override
  String get partnerRetry => '重试';

  @override
  String get partnerReadOnly => '只读';

  @override
  String get partnerConflict => '你的另一台设备共享了更新的记录。本机记录已保存，只是暂停了共享。';

  @override
  String get partnerShareThisDevice => '用本机记录共享';

  @override
  String get plansTitle => '共同计划';

  @override
  String get planNew => '新建共同计划';

  @override
  String get planJoin => '用代码加入';

  @override
  String get planHint => '第一行是标题，之后每行一个动作\n例：深蹲 4组';

  @override
  String get planDateNone => '日期未定';

  @override
  String planSetsCount(int n) {
    return '$n组';
  }

  @override
  String get planSave => '提出';

  @override
  String get planStateLocal => '仅在本机的草稿 · 尚未上传';

  @override
  String get planStateDraft => '草稿 · 还没有同伴';

  @override
  String planStateWaiting(int v) {
    return '等待对方确认 · 版本 $v';
  }

  @override
  String planStateNeedsMe(String name, int v) {
    return '$name 已修改 · 版本 $v 需要你确认';
  }

  @override
  String planStateAgreed(int v) {
    return '已达成一致 · 版本 $v';
  }

  @override
  String get planStateWithdrawn => '共同计划已结束 · 已达成的计划和你的目标保留';

  @override
  String planAccept(int v) {
    return '接受版本 $v';
  }

  @override
  String get planChanged => '与上次一致版本相比的变化';

  @override
  String planAdded(String x) {
    return '新增：$x';
  }

  @override
  String planRemoved(String x) {
    return '移除：$x';
  }

  @override
  String planSetsChanged(String x) {
    return '组数变化：$x';
  }

  @override
  String get planReordered => '顺序已变化';

  @override
  String get planDateChanged => '日期已变化';

  @override
  String get planTitleChanged => '标题已变化';

  @override
  String planLastAgreed(int v) {
    return '上次一致的计划 · 版本 $v';
  }

  @override
  String get planConflict => '对方先修改了，你的草稿仍然保留。';

  @override
  String planLatest(int v) {
    return '对方的最新计划 · 版本 $v';
  }

  @override
  String get planKeepMine => '用我的草稿重新提出';

  @override
  String get planTakeLatest => '改用最新计划';

  @override
  String get planMyTarget => '我的目标';

  @override
  String planPartnerTarget(String name, String t) {
    return '$name：$t';
  }

  @override
  String get planTargetHint => '例：100 5 或 100kg 5次 x3 备注';

  @override
  String get planInvite => '生成邀请代码';

  @override
  String get planStart => '按此计划开始';

  @override
  String get planStartSolo => '用我自己的副本开始';

  @override
  String get planStartSoloNote => '尚未达成一致。现在开始将使用你自己的副本，而不是已达成一致的计划。';

  @override
  String get planOpenWorkout => '打开已开始的训练';

  @override
  String get planCopyNext => '复制到下一次训练';

  @override
  String get planWithdraw => '退出此共同计划';

  @override
  String get planCompare => '计划与实际';

  @override
  String planDoneSets(String name, int planned, int done) {
    return '$name · 计划 $planned 组 · 完成 $done 组';
  }

  @override
  String planAddedActual(String x) {
    return '计划外：$x';
  }

  @override
  String planSkipped(String x) {
    return '未做：$x';
  }

  @override
  String planStartedFrom(int v) {
    return '从已达成一致的共同计划（版本 $v）开始';
  }

  @override
  String planStartedSolo(int v) {
    return '从你自己的副本（版本 $v，未达成一致）开始';
  }

  @override
  String get planShareLink => '发送邀请链接';

  @override
  String planShareText(String url) {
    return '在 setpad 一起制定训练计划：$url';
  }

  @override
  String get planLinkCopied => '已复制链接，一天内可使用一次。';

  @override
  String get planLinkJoining => '正在加入受邀的计划…';

  @override
  String get nearbyHint => 'iPhone 之间，保持此画面打开并将两台手机靠近也可以连接。';

  @override
  String get planPropose => '提议为共同计划';

  @override
  String get togetherStart => '一起开始';

  @override
  String get togetherAlternate => '轮流';

  @override
  String togetherWaiting(String name) {
    return '正在等待$name…';
  }

  @override
  String get togetherWaitingHint => '请求会显示在对方屏幕上。如果没有，请确认对方的应用是最新版本。';

  @override
  String togetherInvite(String name) {
    return '$name邀请你一起做';
  }

  @override
  String get togetherInviteAlternate => '轮流 · 对方先';

  @override
  String get togetherLeave => '停止';

  @override
  String get togetherRejoin => '重新加入';

  @override
  String togetherWith(String name) {
    return '与$name一起';
  }

  @override
  String get togetherTheirTurn => '对方的回合';

  @override
  String togetherLeftBeat(String name, int n) {
    return '$name在第$n拍停下';
  }

  @override
  String togetherLeftRound(String name, int n) {
    return '$name在第$n回合停下';
  }

  @override
  String get togetherMe => '我';

  @override
  String get togetherLog => '记录';

  @override
  String get mealLogAs => '记为饮食';

  @override
  String get proxyWrite => '代为记录';

  @override
  String proxyWriting(String name) {
    return '正在记录$name的训练';
  }

  @override
  String get proxyDefaultName => '对方';

  @override
  String get proxyHand => '交给对方';

  @override
  String get proxyBack => '回到我的记录';

  @override
  String proxyShareText(String url) {
    return '一起训练时替你记下的记录。在 setpad 中打开并接收，就会成为你的训练记录。\n$url';
  }

  @override
  String handoffOffer(String name) {
    return '$name替你记下了训练';
  }

  @override
  String get handoffTake => '接收';

  @override
  String get handoffFailed => '无法接收记录。链接可能已过期，或网络有问题。';

  @override
  String get handoffSignIn => '需要登录才能接收交给你的记录。';

  @override
  String partnerInviteMore(String code) {
    return '再邀请一人 · 代码 $code';
  }

  @override
  String get proxyWhose => '要记录谁的训练？';

  @override
  String planMemberAccepted(String name) {
    return '$name 已同意';
  }

  @override
  String planMemberWaiting(String name) {
    return '$name 尚未确认';
  }

  @override
  String deleteNoteAsk(String title) {
    return '删除“$title”？';
  }

  @override
  String get mealsTitle => '饮食';

  @override
  String get recordMenu => '更多';

  @override
  String dayIntakeOnly(String intake) {
    return '摄入 $intake 千卡 · 运动消耗未测量';
  }

  @override
  String dayIntakeOnlyApprox(String intake) {
    return '摄入 约 $intake 千卡 · 运动消耗未测量';
  }

  @override
  String dayUnknownMeals(int m) {
    return '$m 项热量未知';
  }

  @override
  String get healthDataTitle => '健康数据';

  @override
  String get healthDataIntro =>
      'setpad 与健康应用(Apple 健康、Health Connect)交换的内容及原因。';

  @override
  String get healthDataWrite => '写入 · 体能训练 — 完成记录后,会保存为一次体能训练。';

  @override
  String get healthDataCalories =>
      '读取 · 活动能量 — 训练期间手表测得的活动能量会附到该记录上。没有测量时不显示热量。';

  @override
  String get healthDataHeart =>
      '读取 · 心率 — Tabata 休息期间,心率比该轮最高值低 25 bpm 时,休息结束并提示下一轮开始。休息时计时器一行显示 ♥ 当前 → 目标。没有心率或读数超过 90 秒时,休息按时结束。';

  @override
  String get healthDataStays => '从健康应用读取的数据不会离开本设备。不会发送到服务器,也不会用于广告或营销。';

  @override
  String get healthDataRevokeIos =>
      '可随时在 iPhone 设置 → 隐私与安全性 → 健康 → setpad 中关闭。';

  @override
  String get healthDataRevokeAndroid =>
      '可随时在 Health Connect → 应用权限 → setpad 中关闭。';

  @override
  String get healthDataPrivacy => '隐私政策';

  @override
  String get restAlarmTitle => '下一轮 — 心率已降下来';

  @override
  String liveSetBusy(String name) {
    return '$name 正在编辑这一组。等对方改完再点。';
  }

  @override
  String liveExerciseBusy(String name) {
    return '$name 正在记录这个动作。';
  }

  @override
  String liveExerciseRemoved(String exercise) {
    return '一起训练的人删除了 $exercise。你正在输入的内容还在输入栏里。';
  }

  @override
  String get trainerReport => '教练报告';

  @override
  String get trainerUnread => '新报告';

  @override
  String trainerRanAt(String when) {
    return '$when 整理';
  }

  @override
  String get trainerRunNow => '立即整理';

  @override
  String get trainerNoReport => '还没有报告。现在整理一份吗？';

  @override
  String get trainerOutdated => '此报告需要新版本查看，请更新应用。';

  @override
  String get trainerFailed => '无法连接服务器，请稍后再试。';

  @override
  String get trainerActUnknown => '未能确认结果。再按一次也不会重复记录。';

  @override
  String get trainerDone => '代理已处理';

  @override
  String get trainerToday => '今日课程';

  @override
  String get trainerTodo => '待确认';

  @override
  String get trainerAllClear => '待确认事项已全部处理。';

  @override
  String get trainerAttendance => '待收尾的课程';

  @override
  String trainerVisited(String time) {
    return '确认到店 $time';
  }

  @override
  String trainerFinishAll(int count) {
    return '全部完成 ($count)';
  }

  @override
  String trainerFinishAsk(int count) {
    return '完成 $count 项 — 每项从私教课次卡扣除 1 次。';
  }

  @override
  String get trainerFinish => '确认完成';

  @override
  String get trainerJoinRequest => '注册申请 — 请在网页版 CRM 的“今天”页面确认。';

  @override
  String get trainerBook => '预约';

  @override
  String get trainerSend => '发送';

  @override
  String get trainerPaid => '已收款';

  @override
  String get trainerContacted => '已联系';

  @override
  String get trainerLater => '稍后';

  @override
  String trainerPrice(int price) {
    final intl.NumberFormat priceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String priceString = priceNumberFormat.format(price);

    return '₩$priceString';
  }

  @override
  String trainerStarts(String d) {
    return '$d起';
  }

  @override
  String get trainerPayHow => '以什么方式收款？';

  @override
  String get trainerPaidListPrice =>
      '将按商品原价记为已收款。折扣或分期收款请在网页 CRM 会员页面的会员卡标签中登记。';

  @override
  String get payCard => '刷卡';

  @override
  String get payCash => '现金';

  @override
  String get payTransfer => '转账';

  @override
  String get payOther => '其他';

  @override
  String get agentSettings => '代理设置';

  @override
  String get agentEnabled => '在设定时间整理';

  @override
  String get agentTimes => '整理时间';

  @override
  String get agentAddTime => '添加时间';

  @override
  String get agentDays => '星期';

  @override
  String get agentAutoConfirm => '私教申请立即确认';

  @override
  String get agentModes => '按任务';

  @override
  String get agentModesHelp => '手动 — 代理不处理。草稿 — 代理准备好，你点一下完成。自动 — 代理直接处理。';

  @override
  String get agentModeOff => '手动';

  @override
  String get agentModeDraft => '草稿';

  @override
  String get agentModeAuto => '自动';

  @override
  String get taskPtSchedule => '私教日程';

  @override
  String get taskRenewal => '续费';

  @override
  String get taskAttendance => '出勤整理';

  @override
  String get taskRoutine => '训练计划';

  @override
  String get taskContact => '联系会员';

  @override
  String get gymPolicy => '健身房规则';

  @override
  String get policyRenewalDays => '续费提醒时间（到期前几天）';

  @override
  String get policyLowSessions => '私教课不足标准（可预约次数）';

  @override
  String get policyAwayDays => '未到店标准（天）';

  @override
  String get policyLapsedDays => '流失期限（天）';

  @override
  String get policyOffer => '续费优惠文案';

  @override
  String get policySave => '保存规则';

  @override
  String get policySaved => '已保存。';

  @override
  String get trainerWhichGym => '哪一家健身房？';

  @override
  String get trainerBack => '返回';

  @override
  String get trainerCopy => '复制文案';

  @override
  String get trainerCopied => '已复制';

  @override
  String get settingsTrainer => '教练';
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
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString 千卡';
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
  String setsPerLineMax(int n) {
    return '每行最多 $n 組，請分成幾行輸入。';
  }

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
  String get aiFallbackQuota => '今天的輸入輔助已用完，已按原文新增';

  @override
  String get aiFallbackOffline => '無法連線，已按原文新增。可在卡片的⚙中新增設定';

  @override
  String get aiFallbackServer => '伺服器沒有回應，已按原文新增。可在卡片的⚙中新增設定';

  @override
  String get aiFallbackUnread => '沒有找到可設定的內容，已按原文新增。可在卡片的⚙中新增設定';

  @override
  String get inputNameTooLong => '動作名稱最多120個字 — 請分行輸入';

  @override
  String get inputTooLong => '超過600個字的文字不會讀取 — 請分行輸入';

  @override
  String get setupAdd => '新增設定';

  @override
  String setupUnparsed(String words) {
    return '未轉入設定的內容：$words — 保留在標題中';
  }

  @override
  String setupDropped(String numbers) {
    return '已去掉原文中沒有的數字：$numbers';
  }

  @override
  String get setupNameMissing => '請輸入動作名稱';

  @override
  String get setupNameTooLong => '最多120個字';

  @override
  String get setupWeightInvalid => '請輸入大於0且不超過2000的數字';

  @override
  String get setupCountInvalid => '請輸入1以上的整數 — 範圍和時間請留在標題中';

  @override
  String get setupMergeUp => '合併到上一個動作';

  @override
  String get setupKeepApart => '分開保留';

  @override
  String get setupRepsOnly => '只記次數';

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
  String get accountSignIn => '登入';

  @override
  String get accountSignOut => '登出';

  @override
  String get planMonthly => '月費方案';

  @override
  String get planYearly => '年費方案';

  @override
  String planYearlyTrial(int days, String price) {
    return '免費試用 $days 天，之後每年 $price。在試用結束前至少 24 小時取消，就不會扣款。';
  }

  @override
  String planYearlyTrialPlates(int n) {
    return '免費試用期間補滿到 $n 片。開始扣款後改為每月補滿。';
  }

  @override
  String get planActive => '使用中';

  @override
  String get restorePurchases => '回復購買';

  @override
  String get subscriptionRenews =>
      '除非在目前週期結束前至少 24 小時取消，訂閱會以相同價格自動續訂。可隨時在商店的訂閱管理中取消。';

  @override
  String get termsOfUse => '使用條款（EULA）';

  @override
  String get inputQuotaSpent => '今天的輸入幫助已用完。自己輸入照樣會記錄。';

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
  String get metricE1rm => '估算1RM';

  @override
  String get metricMaxReps => '最多次數';

  @override
  String get metricLongest => '最長';

  @override
  String get metricFirst => '首次';

  @override
  String get metricDaysSince => '未練天數';

  @override
  String get metricDistance => '總距離';

  @override
  String get metricDuration => '總時長';

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
  String get queryByExercise => '按動作';

  @override
  String get queryByDay => '按天';

  @override
  String get queryByWeek => '按週（週一開始）';

  @override
  String get queryByMonth => '按月';

  @override
  String get queryByWeekday => '按星期';

  @override
  String get queryTotalSum => '合計';

  @override
  String get queryTotalMean => '平均';

  @override
  String queryDiff(String later, String earlier) {
    return '差值（$later − $earlier）';
  }

  @override
  String queryExclude(String names) {
    return '除$names外';
  }

  @override
  String queryMemo(String terms) {
    return '備註：$terms';
  }

  @override
  String queryLastSessions(int n) {
    return '最近$n次';
  }

  @override
  String queryBottomLimit(int n) {
    return '後$n項 · 遞增';
  }

  @override
  String queryOutOfScope(String names) {
    return '不適用（此指標無數值）：$names';
  }

  @override
  String queryMissingFor(String names) {
    return '未計算（有缺值的組）：$names';
  }

  @override
  String get queryE1rmRule => '估算1RM = 重量 × (1 + 次數 ÷ 30)，僅限1–10次的組';

  @override
  String queryMore(int n) {
    return '另外$n項';
  }

  @override
  String queryRankingLimit(int n) {
    return '前$n項 · 遞減';
  }

  @override
  String get queryCompareChip => '比較';

  @override
  String get queryNoRecord => '無記錄';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsRecording => '記錄';

  @override
  String get settingsAccount => '帳戶';

  @override
  String get settingsGym => '你的健身房';

  @override
  String get settingsNoGym => '用手機碰一下健身房的貼紙，就能收到教練寫的訓練計畫。';

  @override
  String get proTitle => 'Pro 方案';

  @override
  String get proBody => '向紀錄提問會用掉槓片——通常每個問題約 1 片，只扣回答實際用掉的量。記錄訓練和飲食時的輸入幫助不用槓片。';

  @override
  String proFree(int n, int sets) {
    return '免費：輸入幫助每天 $n 次 · 完成 $sets 組的當天送 1 片';
  }

  @override
  String proPaid(int n, int input) {
    return 'Pro：每月補滿到 $n 片 · 輸入幫助每天 $input 次';
  }

  @override
  String get proEverythingElseFree => '記錄、計時、手腕提醒、一起訓練和健身房功能，不訂閱也全部可用。';

  @override
  String get proOwned => '已開通，謝謝。';

  @override
  String get proSignInFirst => '訂閱綁定帳戶，請先登入。';

  @override
  String platesBalance(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '剩餘槓片 $nString 片';
  }

  @override
  String platesSpent(num spent, num balance) {
    final intl.NumberFormat spentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String spentString = spentNumberFormat.format(spent);
    final intl.NumberFormat balanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String balanceString = balanceNumberFormat.format(balance);

    return '用了 $spentString 片 · 剩餘 $balanceString 片';
  }

  @override
  String noPlates(int sets) {
    return '槓片不夠了。每天完成 $sets 組可得 1 片。';
  }

  @override
  String noPlatesSignIn(int n) {
    return '登入 · 新帳號領取 $n 片';
  }

  @override
  String platesGetPro(int n) {
    return '查看 Pro · 每月 $n 片';
  }

  @override
  String get purchaseNotConfirmed => '無法確認這次購買。如果已扣款，請稍後點「回復購買」。';

  @override
  String get purchaseOtherAccount => '這筆購買已連結到另一個帳號。請用那個帳號登入。';

  @override
  String get tagSignInNeeded => '登入後即可與健身房連接。';

  @override
  String get tagJoinSent => '已送出申請。教練確認後即可開始。';

  @override
  String get tagJoinWaiting => '已經申請過了，教練正在確認。';

  @override
  String get tagJoinFailed => '申請沒有送出成功。稍後再碰一下貼紙。';

  @override
  String get bookingPending => '待確認';

  @override
  String get bookingWhichGym => '哪一家健身房？';

  @override
  String get tagSignIn => '登入';

  @override
  String get accountDelete => '註銷帳號';

  @override
  String get accountDeleteAsk => '無法復原。訓練計畫、紀錄、堂數和預約都會消失。';

  @override
  String get accountDeleteDo => '確認註銷';

  @override
  String get accountDeleteFailed => '註銷失敗，請稍後再試。';

  @override
  String get signInFailed => '登入失敗，請稍後再試。';

  @override
  String get bookingTitle => 'PT 預約';

  @override
  String get bookingConfirmed => '已確認';

  @override
  String bookingRemaining(int n) {
    return '剩餘 $n 次';
  }

  @override
  String get bookingNoPass => '沒有 PT 堂數，請聯絡教練。';

  @override
  String bookingNoHours(String trainer) {
    return '$trainer 教練還沒有開放時間。';
  }

  @override
  String get bookingPick => '選擇時間';

  @override
  String bookingWith(String trainer, int minutes) {
    return '$trainer 教練 · 每次 $minutes 分鐘';
  }

  @override
  String get bookingSent => '已送出申請，教練確認後生效。';

  @override
  String get bookingUpcoming => '即將到來';

  @override
  String get bookingClosedDay => '這天不接受預約。';

  @override
  String get bookingCancelAsk => '取消這次預約嗎？';

  @override
  String get ok => '好';

  @override
  String get mealPhoto => '餐食照片';

  @override
  String get mealCamera => '相機';

  @override
  String get mealGallery => '從相簿';

  @override
  String get mealEstimating => '正在估算熱量…';

  @override
  String mealIntake(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '攝取約 $nString 大卡';
  }

  @override
  String get mealFailed => '無法從這張照片估算熱量，請重新拍攝。';

  @override
  String get mealEstimateNote => '依照片估算';

  @override
  String mealServingsOption(String n) {
    return '$n 份';
  }

  @override
  String get fitAll => '今天的訓練';

  @override
  String get sameDayOther => '當天的其他紀錄';

  @override
  String get mealText => '記錄飲食';

  @override
  String get mealTextHint => '吃了什麼？例如：香蕉2根，牛奶200ml';

  @override
  String kcalApprox(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '約 $nString 大卡';
  }

  @override
  String get mealKcalUnknown => '熱量未知';

  @override
  String mealIntakePartial(int n, int m) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '攝取 $nString 大卡 + $m 項熱量未知';
  }

  @override
  String get mealAmountAsk => '吃了多少？';

  @override
  String get mealBasis => '基準';

  @override
  String get mealEaten => '食用量';

  @override
  String get mealUnitServing => '份';

  @override
  String get mealUnitPackage => '整包';

  @override
  String get mealUnitPhoto => '照片中的食物';

  @override
  String get mealWhole => '全部';

  @override
  String get mealHalf => '一半';

  @override
  String get mealPhotoWholeNote => '這是照片中全部食物的估算值，請選擇您吃了其中多少。';

  @override
  String get mealTextUnknown => '無法辨識這種食物，未能估算熱量。點按這餐補充食物名稱或份量，即可重新估算。';

  @override
  String get mealTextOffline => '無法連線，未能估算熱量。點按這餐後按 Enter 即可重新估算。';

  @override
  String get mealTextTooLong => '超過 500 字的飲食紀錄不會估算。點按這餐分開記錄即可估算。';

  @override
  String queryTooLong(int max) {
    return '問題最多 $max 個字。請縮短後再問。';
  }

  @override
  String get queryPressEnter => '按 Enter 即可詢問您的紀錄。';

  @override
  String get mealRetry => '重新估算';

  @override
  String kcalAtLeast(int n) {
    return '至少 $n 大卡';
  }

  @override
  String mealTextPartial(int n) {
    return '只計入了你寫的 $n 大卡，其餘食物的熱量未知。';
  }

  @override
  String mealTextBelowTyped(int n) {
    return '估算值低於你寫的 $n 大卡，因此未採用。只計入了你寫的 $n 大卡。';
  }

  @override
  String queryLimit(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'exercises': '一次最多可問 8 個動作。請分開提問。',
      'measures': '一次最多統計 3 項。請分開提問。',
      'ranking': '排名最多顯示 20 個。請問 20 個以內。',
      'sessions': '「最近 N 次」最多 100 次。想看更久，請按時間段提問，例如今年。',
      'days': '「最近 N 天」最多 3660 天（約 10 年）。想看更久，請按全部時間提問。',
      'compare': '一次最多比較 4 項。請分開提問。',
      'compareGrouped': '同一個問題不能既比較又按動作、日、週、月或星期分組。請擇一提問。',
      'groupedMeasure': '按日、週、月或星期分組時只能統計一項，且趨勢、最後一次、第一次、距上次天數不能分組。',
      'ordering': '排名、合計和平均需要分組，例如按動作或按週。',
      'datesTotal': '最後一次和第一次的日期不能相加或求平均。',
      'other': '紀錄搜尋無法計算這種形式的問題。請分開提問。',
    });
    return '$_temp0';
  }

  @override
  String policyNumberRejected(String text, String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'decimal': '「$text」— 不接受小數。請輸入整數，例如 14',
      'range': '「$text」— 請輸入一個數字，而不是範圍，例如 14',
      'negative': '「$text」— 不接受小於 0 的數，例如 14',
      'unit': '「$text」— 此欄按天數或次數計。請把小時、週或月換算成天數，例如 14',
      'other': '無法從「$text」中讀出天數或次數。請輸入數字，例如 14',
    });
    return '$_temp0';
  }

  @override
  String get mealSources => '來源';

  @override
  String get mealSourcesTitle => '熱量依據';

  @override
  String get mealSourcesNote => '依下表中的數值計算。點按可在原始資料表中開啟該名稱。表中沒有的食物由 AI 估算。';

  @override
  String mealSourcePer(String unit, String kcal) {
    return '每100$unit ${kcal}kcal';
  }

  @override
  String get mealSourceMfds => '韓國食品醫藥品安全處 食品營養成分資料庫';

  @override
  String get mealSourceUsda => 'USDA FoodData Central';

  @override
  String get mealAmountInvalid => '請輸入不小於 0 的數字。';

  @override
  String dayEnergyFull(String intake, String burned, String diff) {
    return '攝取 $intake · 運動 $burned = $diff 大卡';
  }

  @override
  String dayEnergyApprox(String intake, String burned, String diff) {
    return '攝取 約 $intake · 運動 $burned ≈ $diff 大卡';
  }

  @override
  String get dayBurnedMissing => '運動消耗未測量 · 無法計算差值';

  @override
  String dayBurnedOnly(String n) {
    return '運動 $n 大卡 · 未記錄飲食';
  }

  @override
  String get intakeLabel => '攝取';

  @override
  String get partnerSignIn => '需要登入才能一起訓練。';

  @override
  String get partnerSignInAction => '登入';

  @override
  String get partnerMakeCode => '產生代碼';

  @override
  String get partnerCopy => '複製';

  @override
  String partnerExpiresIn(String t) {
    return '$t 後過期';
  }

  @override
  String get partnerExpired => '代碼已過期。';

  @override
  String get partnerNewCode => '新代碼';

  @override
  String get partnerStopWaiting => '停止';

  @override
  String partnerWith(String name) {
    return '正在與 $name 一起訓練';
  }

  @override
  String get partnerReconnecting => '正在重新連線 · 你的紀錄會繼續儲存';

  @override
  String partnerTheirRecord(String name) {
    return '$name 的紀錄';
  }

  @override
  String get partnerNoRecordYet => '還沒有紀錄。';

  @override
  String get partnerLoading => '載入中…';

  @override
  String get partnerEnd => '結束一起訓練';

  @override
  String get partnerEndedByMe => '你已結束一起訓練，你的紀錄保留不變。';

  @override
  String partnerEndedByThem(String name) {
    return '$name 已結束一起訓練，你的紀錄保留不變。';
  }

  @override
  String get partnerErrFormat => '代碼為六位，請再確認。';

  @override
  String get partnerErrInvalid => '沒有這個代碼，可能已被使用或輸入有誤。';

  @override
  String get partnerErrExpired => '代碼已過期，請對方重新產生。';

  @override
  String get partnerErrEnded => '該邀請已結束。';

  @override
  String get partnerErrOwn => '這是你自己產生的代碼，請在對方裝置上輸入。';

  @override
  String get partnerErrTries => '嘗試次數過多，請稍後再試。';

  @override
  String get partnerErrNetwork => '無法連線伺服器，請檢查網路後重試。';

  @override
  String get partnerErrServer => '伺服器發生問題，請稍後重試。';

  @override
  String get partnerRetry => '重試';

  @override
  String get partnerReadOnly => '唯讀';

  @override
  String get partnerConflict => '你的另一台裝置分享了較新的紀錄。本機紀錄已儲存，只是暫停了分享。';

  @override
  String get partnerShareThisDevice => '用本機紀錄分享';

  @override
  String get plansTitle => '共同計畫';

  @override
  String get planNew => '新增共同計畫';

  @override
  String get planJoin => '用代碼加入';

  @override
  String get planHint => '第一行是標題，之後每行一個動作\n例：深蹲 4組';

  @override
  String get planDateNone => '日期未定';

  @override
  String planSetsCount(int n) {
    return '$n組';
  }

  @override
  String get planSave => '提出';

  @override
  String get planStateLocal => '僅在本機的草稿 · 尚未上傳';

  @override
  String get planStateDraft => '草稿 · 還沒有同伴';

  @override
  String planStateWaiting(int v) {
    return '等待對方確認 · 版本 $v';
  }

  @override
  String planStateNeedsMe(String name, int v) {
    return '$name 已修改 · 版本 $v 需要你確認';
  }

  @override
  String planStateAgreed(int v) {
    return '已達成一致 · 版本 $v';
  }

  @override
  String get planStateWithdrawn => '共同計畫已結束 · 已達成的計畫和你的目標保留';

  @override
  String planAccept(int v) {
    return '接受版本 $v';
  }

  @override
  String get planChanged => '與上次一致版本相比的變化';

  @override
  String planAdded(String x) {
    return '新增：$x';
  }

  @override
  String planRemoved(String x) {
    return '移除：$x';
  }

  @override
  String planSetsChanged(String x) {
    return '組數變化：$x';
  }

  @override
  String get planReordered => '順序已變化';

  @override
  String get planDateChanged => '日期已變化';

  @override
  String get planTitleChanged => '標題已變化';

  @override
  String planLastAgreed(int v) {
    return '上次一致的計畫 · 版本 $v';
  }

  @override
  String get planConflict => '對方先修改了，你的草稿仍然保留。';

  @override
  String planLatest(int v) {
    return '對方的最新計畫 · 版本 $v';
  }

  @override
  String get planKeepMine => '用我的草稿重新提出';

  @override
  String get planTakeLatest => '改用最新計畫';

  @override
  String get planMyTarget => '我的目標';

  @override
  String planPartnerTarget(String name, String t) {
    return '$name：$t';
  }

  @override
  String get planTargetHint => '例：100 5 或 100kg 5次 x3 備註';

  @override
  String get planInvite => '產生邀請代碼';

  @override
  String get planStart => '按此計畫開始';

  @override
  String get planStartSolo => '用我自己的副本開始';

  @override
  String get planStartSoloNote => '尚未達成一致。現在開始將使用你自己的副本，而不是已達成一致的計畫。';

  @override
  String get planOpenWorkout => '開啟已開始的訓練';

  @override
  String get planCopyNext => '複製到下一次訓練';

  @override
  String get planWithdraw => '退出此共同計畫';

  @override
  String get planCompare => '計畫與實際';

  @override
  String planDoneSets(String name, int planned, int done) {
    return '$name · 計畫 $planned 組 · 完成 $done 組';
  }

  @override
  String planAddedActual(String x) {
    return '計畫外：$x';
  }

  @override
  String planSkipped(String x) {
    return '未做：$x';
  }

  @override
  String planStartedFrom(int v) {
    return '從已達成一致的共同計畫（版本 $v）開始';
  }

  @override
  String planStartedSolo(int v) {
    return '從你自己的副本（版本 $v，未達成一致）開始';
  }

  @override
  String get planShareLink => '傳送邀請連結';

  @override
  String planShareText(String url) {
    return '在 setpad 一起制定訓練計畫：$url';
  }

  @override
  String get planLinkCopied => '已複製連結，一天內可使用一次。';

  @override
  String get planLinkJoining => '正在加入受邀的計畫…';

  @override
  String get nearbyHint => 'iPhone 之間，保持此畫面開啟並將兩支手機靠近也可以連線。';

  @override
  String get planPropose => '提議為共同計畫';

  @override
  String get togetherStart => '一起開始';

  @override
  String get togetherAlternate => '輪流';

  @override
  String togetherWaiting(String name) {
    return '正在等待$name…';
  }

  @override
  String get togetherWaitingHint => '請求會顯示在對方螢幕上。如果沒有，請確認對方的 App 是最新版本。';

  @override
  String togetherInvite(String name) {
    return '$name邀請你一起做';
  }

  @override
  String get togetherInviteAlternate => '輪流 · 對方先';

  @override
  String get togetherLeave => '停止';

  @override
  String get togetherRejoin => '重新加入';

  @override
  String togetherWith(String name) {
    return '與$name一起';
  }

  @override
  String get togetherTheirTurn => '對方的回合';

  @override
  String togetherLeftBeat(String name, int n) {
    return '$name在第$n拍停下';
  }

  @override
  String togetherLeftRound(String name, int n) {
    return '$name在第$n回合停下';
  }

  @override
  String get togetherMe => '我';

  @override
  String get togetherLog => '記錄';

  @override
  String get mealLogAs => '記為飲食';

  @override
  String get proxyWrite => '代為記錄';

  @override
  String proxyWriting(String name) {
    return '正在記錄$name的訓練';
  }

  @override
  String get proxyDefaultName => '對方';

  @override
  String get proxyHand => '交給對方';

  @override
  String get proxyBack => '回到我的紀錄';

  @override
  String proxyShareText(String url) {
    return '一起訓練時替你記下的紀錄。在 setpad 中開啟並接收，就會成為你的訓練紀錄。\n$url';
  }

  @override
  String handoffOffer(String name) {
    return '$name替你記下了訓練';
  }

  @override
  String get handoffTake => '接收';

  @override
  String get handoffFailed => '無法接收紀錄。連結可能已過期，或網路有問題。';

  @override
  String get handoffSignIn => '需要登入才能接收交給你的紀錄。';

  @override
  String partnerInviteMore(String code) {
    return '再邀請一人 · 代碼 $code';
  }

  @override
  String get proxyWhose => '要記錄誰的訓練？';

  @override
  String planMemberAccepted(String name) {
    return '$name 已同意';
  }

  @override
  String planMemberWaiting(String name) {
    return '$name 尚未確認';
  }

  @override
  String deleteNoteAsk(String title) {
    return '刪除「$title」？';
  }

  @override
  String get mealsTitle => '飲食';

  @override
  String get recordMenu => '更多';

  @override
  String dayIntakeOnly(String intake) {
    return '攝取 $intake 大卡 · 運動消耗未測量';
  }

  @override
  String dayIntakeOnlyApprox(String intake) {
    return '攝取 約 $intake 大卡 · 運動消耗未測量';
  }

  @override
  String dayUnknownMeals(int m) {
    return '$m 項熱量未知';
  }

  @override
  String get healthDataTitle => '健康資料';

  @override
  String get healthDataIntro =>
      'setpad 與健康 App(Apple 健康、Health Connect)交換的內容及原因。';

  @override
  String get healthDataWrite => '寫入 · 體能訓練 — 完成記錄後,會儲存為一次體能訓練。';

  @override
  String get healthDataCalories =>
      '讀取 · 活動能量 — 訓練期間手錶測得的活動能量會附到該記錄上。沒有測量時不顯示熱量。';

  @override
  String get healthDataHeart =>
      '讀取 · 心率 — Tabata 休息期間,心率比該輪最高值低 25 bpm 時,休息結束並提示下一輪開始。休息時計時器一行顯示 ♥ 目前 → 目標。沒有心率或讀數超過 90 秒時,休息按時結束。';

  @override
  String get healthDataStays => '從健康 App 讀取的資料不會離開本裝置。不會傳送到伺服器,也不會用於廣告或行銷。';

  @override
  String get healthDataRevokeIos =>
      '可隨時在 iPhone 設定 → 隱私權與安全性 → 健康 → setpad 中關閉。';

  @override
  String get healthDataRevokeAndroid =>
      '可隨時在 Health Connect → 應用程式權限 → setpad 中關閉。';

  @override
  String get healthDataPrivacy => '隱私權政策';

  @override
  String get restAlarmTitle => '下一輪 — 心率已降下來';

  @override
  String liveSetBusy(String name) {
    return '$name 正在編輯這一組。等對方改完再點。';
  }

  @override
  String liveExerciseBusy(String name) {
    return '$name 正在記錄這個動作。';
  }

  @override
  String liveExerciseRemoved(String exercise) {
    return '一起訓練的人刪除了 $exercise。你正在輸入的內容還在輸入欄裡。';
  }

  @override
  String get trainerReport => '教練報告';

  @override
  String get trainerUnread => '新報告';

  @override
  String trainerRanAt(String when) {
    return '$when 整理';
  }

  @override
  String get trainerRunNow => '立即整理';

  @override
  String get trainerNoReport => '還沒有報告。現在整理一份嗎？';

  @override
  String get trainerOutdated => '此報告需要新版本查看，請更新 App。';

  @override
  String get trainerFailed => '無法連線伺服器，請稍後再試。';

  @override
  String get trainerActUnknown => '未能確認結果。再按一次也不會重複記錄。';

  @override
  String get trainerDone => '代理已處理';

  @override
  String get trainerToday => '今日課程';

  @override
  String get trainerTodo => '待確認';

  @override
  String get trainerAllClear => '待確認事項已全部處理。';

  @override
  String get trainerAttendance => '待收尾的課程';

  @override
  String trainerVisited(String time) {
    return '確認到店 $time';
  }

  @override
  String trainerFinishAll(int count) {
    return '全部完成 ($count)';
  }

  @override
  String trainerFinishAsk(int count) {
    return '完成 $count 項 — 每項從私教課次卡扣除 1 次。';
  }

  @override
  String get trainerFinish => '確認完成';

  @override
  String get trainerJoinRequest => '註冊申請 — 請在網頁版 CRM 的「今天」頁面確認。';

  @override
  String get trainerBook => '預約';

  @override
  String get trainerSend => '傳送';

  @override
  String get trainerPaid => '已收款';

  @override
  String get trainerContacted => '已聯絡';

  @override
  String get trainerLater => '稍後';

  @override
  String trainerPrice(int price) {
    final intl.NumberFormat priceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String priceString = priceNumberFormat.format(price);

    return '₩$priceString';
  }

  @override
  String trainerStarts(String d) {
    return '$d起';
  }

  @override
  String get trainerPayHow => '以什麼方式收款？';

  @override
  String get trainerPaidListPrice =>
      '將按商品原價記為已收款。折扣或分期收款請在網頁 CRM 會員頁面的會員卡分頁中登記。';

  @override
  String get payCard => '刷卡';

  @override
  String get payCash => '現金';

  @override
  String get payTransfer => '轉帳';

  @override
  String get payOther => '其他';

  @override
  String get agentSettings => '代理設定';

  @override
  String get agentEnabled => '在設定時間整理';

  @override
  String get agentTimes => '整理時間';

  @override
  String get agentAddTime => '新增時間';

  @override
  String get agentDays => '星期';

  @override
  String get agentAutoConfirm => '私教申請立即確認';

  @override
  String get agentModes => '按任務';

  @override
  String get agentModesHelp => '手動 — 代理不處理。草稿 — 代理準備好，你點一下完成。自動 — 代理直接處理。';

  @override
  String get agentModeOff => '手動';

  @override
  String get agentModeDraft => '草稿';

  @override
  String get agentModeAuto => '自動';

  @override
  String get taskPtSchedule => '私教日程';

  @override
  String get taskRenewal => '續費';

  @override
  String get taskAttendance => '出勤整理';

  @override
  String get taskRoutine => '訓練計畫';

  @override
  String get taskContact => '聯絡會員';

  @override
  String get gymPolicy => '健身房規則';

  @override
  String get policyRenewalDays => '續費提醒時間（到期前幾天）';

  @override
  String get policyLowSessions => '私教課不足標準（可預約次數）';

  @override
  String get policyAwayDays => '未到店標準（天）';

  @override
  String get policyLapsedDays => '流失期限（天）';

  @override
  String get policyOffer => '續費優惠文案';

  @override
  String get policySave => '儲存規則';

  @override
  String get policySaved => '已儲存。';

  @override
  String get trainerWhichGym => '哪一家健身房？';

  @override
  String get trainerBack => '返回';

  @override
  String get trainerCopy => '複製文案';

  @override
  String get trainerCopied => '已複製';

  @override
  String get settingsTrainer => '教練';
}
