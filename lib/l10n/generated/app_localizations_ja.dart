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
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '${nString}kcal';
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

  @override
  String answerDays(int n) {
    return '$n日分の記録';
  }

  @override
  String answerWeeks(int n) {
    return '$n週間';
  }

  @override
  String answerFrequency(String n) {
    return '週$n回';
  }

  @override
  String answerPeak(String value) {
    return '最高 $value';
  }

  @override
  String answerNoPeak(int n) {
    return '$n週間、最高記録の更新なし';
  }

  @override
  String answerSince(String date) {
    return '$dateから';
  }

  @override
  String answerAgo(int n) {
    return '$n日前';
  }

  @override
  String answerPerSet(String value) {
    return '1セットあたり $value';
  }

  @override
  String answerChange(String weeks, String value) {
    return '$weeks · $value';
  }

  @override
  String answerChart(String name, int n) {
    return '$name · $n日分の記録';
  }

  @override
  String answerWeightReps(String value, String reps) {
    return '$value × $reps';
  }

  @override
  String answerSets(int n) {
    return '$nセット';
  }

  @override
  String timingBpm(int n) {
    return '$n BPM';
  }

  @override
  String timingProtocol(int work, int rest, int rounds) {
    return 'タバタ $work秒 / $rest秒 · $roundsラウンド';
  }

  @override
  String timingRound(int n, int total) {
    return '$n/$totalラウンド';
  }

  @override
  String timingRoundDone(int n) {
    return '$nラウンド終了';
  }

  @override
  String get timingMetronome => 'メトロノーム';

  @override
  String get timingReady => '準備';

  @override
  String get timingWork => '運動';

  @override
  String get timingRest => '休憩';

  @override
  String get timingComplete => '完了';

  @override
  String get timingStart => '開始';

  @override
  String get timingPause => '一時停止';

  @override
  String get timingReset => 'リセット';

  @override
  String get timingInvalid => 'BPMは10〜120、運動・休憩は1〜600秒、ラウンドは1〜99で入力してください。';

  @override
  String get timingSoundFailed => '音を再生できません。タイマーは動作しています。';

  @override
  String get queryTitle => '記録に質問';

  @override
  String get queryReadyBody =>
      '「スクワットの最高重量は？」「先月の腕立ては何回？」「今月のベンチは先月より伸びた？」などと質問できます。端末内AIが意味を読み取り、保存した記録から計算します。';

  @override
  String get queryManualBody => '自然な言葉での質問には端末内AIの準備が必要です。運動名やメモの検索はいつでも使えます。';

  @override
  String get queryWorking => '質問を読み取っています…';

  @override
  String get queryFailed => '回答を取得できませんでした。もう一度お試しください。';

  @override
  String get queryUnsupported => '運動記録に関する質問をしてください。';

  @override
  String get queryOffline => '接続すると質問できます。';

  @override
  String get queryNoData => '計算に必要な完了記録や数値が不足しています。元の記録を確認してください。';

  @override
  String queryPeriod(String start, String end) {
    return '$start – $end';
  }

  @override
  String get queryAllTime => '全期間';

  @override
  String get queryPresent => '現在';

  @override
  String get queryRepUnit => '回';

  @override
  String get querySetUnit => 'セット';

  @override
  String get queryDayUnit => '日';

  @override
  String get queryAverage => 'セットあたりの平均重量';

  @override
  String get queryMissingData => '質問に必要な運動や測定情報が記録にありません。';

  @override
  String get queryAmbiguous => 'どの運動のどの記録か、もう少し具体的に入力してください。';

  @override
  String queryRank(int n) {
    return '$n位';
  }

  @override
  String timingWorkSeconds(int n) {
    return '運動 $n秒';
  }

  @override
  String timingRestSeconds(int n) {
    return '休憩 $n秒';
  }

  @override
  String timingRounds(int n) {
    return '$nラウンド';
  }

  @override
  String timingBeat(String count) {
    return '$count拍目';
  }

  @override
  String timingHeart(int bpm, int target) {
    return '♥ $bpm → $target';
  }

  @override
  String get accountSignIn => 'ログイン';

  @override
  String get accountSignOut => 'ログアウト';

  @override
  String get planMonthly => '月額プラン';

  @override
  String get planYearly => '年額プラン';

  @override
  String planYearlyTrial(int days, String price) {
    return '$days日間の無料体験後、年額$price。体験終了の24時間前までに解約すれば請求されません。';
  }

  @override
  String planYearlyTrialPlates(int n) {
    return '無料体験中はプレートを$n枚まで補充します。課金が始まると毎月の補充になります。';
  }

  @override
  String get planActive => '利用中';

  @override
  String get restorePurchases => '購入を復元';

  @override
  String get subscriptionRenews =>
      'サブスクリプションは、現在の期間が終わる24時間前までに解約しない限り、同じ価格で自動更新されます。解約はストアのサブスクリプション管理からいつでもできます。';

  @override
  String get termsOfUse => '利用規約（EULA）';

  @override
  String get inputQuotaSpent => '今日の入力補助を使い切りました。自分で入力すればそのまま記録されます。';

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
    return '$gymからの運動';
  }

  @override
  String get partnerInvite => '一緒にやる';

  @override
  String get partnerCode => '相手にこの番号を伝えてください';

  @override
  String get partnerEnter => '番号を入力';

  @override
  String bookingNext(String trainer, String when) {
    return '$trainer · $when';
  }

  @override
  String get bookingNew => 'PT予約';

  @override
  String get bookingNone => 'その日は空きがありません。';

  @override
  String get bookingCancel => '予約を取り消す';

  @override
  String get countAloud => '拍を声に出して数える';

  @override
  String get metricMax => '最高';

  @override
  String get metricTrend => '推移';

  @override
  String get metricLast => '前回';

  @override
  String get metricSessions => '日数';

  @override
  String get metricVolume => 'ボリューム';

  @override
  String get metricReps => '合計回数';

  @override
  String get metricSets => 'セット数';

  @override
  String get metricAverage => '平均';

  @override
  String get metricE1rm => '推定1RM';

  @override
  String get metricMaxReps => '最多回数';

  @override
  String get metricLongest => '最長';

  @override
  String get metricFirst => '初回';

  @override
  String get metricDaysSince => '休んだ日数';

  @override
  String get metricDistance => '総距離';

  @override
  String get metricDuration => '総時間';

  @override
  String get readAsConfirm => 'このように読みました';

  @override
  String get confirmYes => 'はい';

  @override
  String readAsNote(String from, String to) {
    return '$from → $to';
  }

  @override
  String get reviewNumbers => '数値と条件を確認してから適用してください。';

  @override
  String get queryByExercise => '種目別';

  @override
  String get queryByDay => '日別';

  @override
  String get queryByWeek => '週別（月曜始まり）';

  @override
  String get queryByMonth => '月別';

  @override
  String get queryByWeekday => '曜日別';

  @override
  String get queryTotalSum => '合計';

  @override
  String get queryTotalMean => '平均';

  @override
  String queryDiff(String later, String earlier) {
    return '差（$later − $earlier）';
  }

  @override
  String queryExclude(String names) {
    return '$namesを除く';
  }

  @override
  String queryMemo(String terms) {
    return 'メモ: $terms';
  }

  @override
  String queryLastSessions(int n) {
    return '直近$n回';
  }

  @override
  String queryBottomLimit(int n) {
    return '下位$n件・昇順';
  }

  @override
  String queryOutOfScope(String names) {
    return '対象外（この指標の値なし）: $names';
  }

  @override
  String queryMissingFor(String names) {
    return '未計算（値が欠けたセットあり）: $names';
  }

  @override
  String get queryE1rmRule => '推定1RM = 重量 × (1 + 回数 ÷ 30)、1〜10回のセットのみ';

  @override
  String queryMore(int n) {
    return 'ほか$n件';
  }

  @override
  String queryRankingLimit(int n) {
    return '上位$n件・降順';
  }

  @override
  String get queryCompareChip => '比較';

  @override
  String get queryNoRecord => '記録なし';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsRecording => '記録';

  @override
  String get settingsAccount => 'アカウント';

  @override
  String get settingsGym => '通っているジム';

  @override
  String get settingsNoGym => 'ジムのステッカーにスマホをかざすと、トレーナーが作ったルーティンを受け取れます。';

  @override
  String get proTitle => 'Pro プラン';

  @override
  String get proBody =>
      '記録への質問はプレートを使います。1回の質問でふつう1枚ほど、答えに実際に使った分だけ減ります。運動や食事の入力補助はプレートを使いません。';

  @override
  String proFree(int n, int sets) {
    return '無料：入力補助は1日$n回 · $setsセット達成した日にプレート1枚';
  }

  @override
  String proPaid(int n, int input) {
    return 'Pro：毎月プレートを$n枚まで補充 · 入力補助は1日$input回';
  }

  @override
  String get proEverythingElseFree => '記録・タイマー・手首の通知・一緒にやる・ジムはプランなしで全部使えます。';

  @override
  String get proOwned => 'ご利用中です。ありがとうございます。';

  @override
  String get proSignInFirst => 'プランはアカウントに紐づきます。先にログインしてください。';

  @override
  String platesBalance(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '残りプレート$nString枚';
  }

  @override
  String platesSpent(num spent, num balance) {
    final intl.NumberFormat spentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String spentString = spentNumberFormat.format(spent);
    final intl.NumberFormat balanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String balanceString = balanceNumberFormat.format(balance);

    return 'プレート$spentString枚使用 · 残り$balanceString枚';
  }

  @override
  String noPlates(int sets) {
    return 'プレートが足りません。$setsセット達成した日ごとに1枚もらえます。';
  }

  @override
  String noPlatesSignIn(int n) {
    return 'ログイン · 新しいアカウントはプレート$n枚';
  }

  @override
  String platesGetPro(int n) {
    return 'Proを見る · 毎月$n枚';
  }

  @override
  String get purchaseNotConfirmed =>
      '購入を確認できませんでした。支払い済みなら、少し待ってから「購入を復元」を押してください。';

  @override
  String get purchaseOtherAccount => 'この購入は別のアカウントに紐づいています。そのアカウントでログインしてください。';

  @override
  String get tagSignInNeeded => 'ジムとつなぐにはログインが必要です。';

  @override
  String get tagJoinSent => '登録を申請しました。トレーナーが確認するとすぐに始められます。';

  @override
  String get tagJoinWaiting => 'すでに申請済みです。トレーナーが確認中です。';

  @override
  String get tagJoinFailed => '申請できませんでした。少ししてからもう一度かざしてください。';

  @override
  String get bookingPending => '承認待ち';

  @override
  String get bookingWhichGym => 'どのジムですか？';

  @override
  String get tagSignIn => 'ログイン';

  @override
  String get accountDelete => 'アカウント削除';

  @override
  String get accountDeleteAsk => '元に戻せません。ルーティン、記録、チケット、予約がすべて消えます。';

  @override
  String get accountDeleteDo => '削除する';

  @override
  String get accountDeleteFailed => '削除できませんでした。少ししてからもう一度お試しください。';

  @override
  String get signInFailed => 'ログインできませんでした。少ししてからもう一度お試しください。';

  @override
  String get bookingTitle => 'PT予約';

  @override
  String get bookingConfirmed => '確定';

  @override
  String bookingRemaining(int n) {
    return '残り$n回';
  }

  @override
  String get bookingNoPass => 'PTチケットがありません。トレーナーにお問い合わせください。';

  @override
  String bookingNoHours(String trainer) {
    return '$trainerトレーナーはまだ受付時間を開いていません。';
  }

  @override
  String get bookingPick => '時間を選ぶ';

  @override
  String bookingWith(String trainer, int minutes) {
    return '$trainerトレーナー · 1回$minutes分';
  }

  @override
  String get bookingSent => '申請しました。トレーナーが承認すると確定します。';

  @override
  String get bookingUpcoming => '予定';

  @override
  String get bookingClosedDay => 'この日は受け付けていません。';

  @override
  String get bookingCancelAsk => 'この予約をキャンセルしますか？';

  @override
  String get ok => 'OK';

  @override
  String get mealPhoto => '食事の写真';

  @override
  String get mealCamera => 'カメラ';

  @override
  String get mealGallery => 'ライブラリから';

  @override
  String get mealEstimating => 'カロリーを推定中…';

  @override
  String mealIntake(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '摂取 約${nString}kcal';
  }

  @override
  String get mealFailed => '写真からカロリーを推定できませんでした。撮り直してください。';

  @override
  String get mealEstimateNote => '写真からの推定値です';

  @override
  String mealServingsOption(String n) {
    return '$n食分';
  }

  @override
  String get fitAll => '今日の運動';

  @override
  String get sameDayOther => '同じ日のほかの記録';

  @override
  String get mealText => '食事を書く';

  @override
  String get mealTextHint => '食べたものを書いてください。例: バナナ2本、牛乳200ml';

  @override
  String kcalApprox(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '約${nString}kcal';
  }

  @override
  String get mealKcalUnknown => 'カロリー不明';

  @override
  String mealIntakePartial(int n, int m) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '摂取 ${nString}kcal + カロリー不明 $m件';
  }

  @override
  String get mealAmountAsk => 'どれくらい食べましたか？';

  @override
  String get mealBasis => '基準';

  @override
  String get mealEaten => '食べた量';

  @override
  String get mealUnitServing => '食分';

  @override
  String get mealUnitPackage => 'パッケージ全体';

  @override
  String get mealUnitPhoto => '写真の料理';

  @override
  String get mealWhole => '全部';

  @override
  String get mealHalf => '半分';

  @override
  String get mealPhotoWholeNote => '写真に写っている料理全体の推定値です。そのうち食べた分を選んでください。';

  @override
  String get mealTextUnknown =>
      '食べ物がわからず、カロリーを推定できませんでした。食事の行をタップして料理名や量を書き足すと、もう一度推定します。';

  @override
  String get mealTextOffline =>
      '接続できず、カロリーを推定できませんでした。食事の行をタップしてEnterを押すと、もう一度推定します。';

  @override
  String get mealTextTooLong => '500文字を超える食事メモは推定しません。食事の行をタップして分けて書くと推定します。';

  @override
  String get queryUnrepresentable =>
      'この質問は記録検索で計算できない形です。種目は8つ、ランキングは20件、比較は4つまでで、週・月ごとにまとめると指標は1つだけです。分けて質問してください。';

  @override
  String queryTooLong(int max) {
    return '質問は$max文字までです。短くしてください。';
  }

  @override
  String get queryPressEnter => 'Enterを押すと記録について質問できます。';

  @override
  String policyNumberUnreadable(String text) {
    return '「$text」から日数・回数を読み取れませんでした。数字で入力してください。例: 14';
  }

  @override
  String get mealSources => '出典';

  @override
  String get mealSourcesTitle => 'カロリーの根拠';

  @override
  String get mealSourcesNote =>
      '下の表の値で計算しました。タップすると元の表でその名前を開きます。表にない食品はAIの推定値です。';

  @override
  String mealSourcePer(String unit, String kcal) {
    return '100$unitあたり${kcal}kcal';
  }

  @override
  String get mealSourceMfds => '韓国食品医薬品安全処 食品栄養成分DB';

  @override
  String get mealSourceUsda => 'USDA FoodData Central';

  @override
  String get mealAmountInvalid => '0以上の数字を入力してください。';

  @override
  String dayEnergyFull(String intake, String burned, String diff) {
    return '摂取 $intake · 運動 $burned = ${diff}kcal';
  }

  @override
  String dayEnergyApprox(String intake, String burned, String diff) {
    return '摂取 約$intake · 運動 $burned = 約${diff}kcal';
  }

  @override
  String get dayBurnedMissing => '運動消費は未計測 · 差は計算できません';

  @override
  String dayBurnedOnly(String n) {
    return '運動 ${n}kcal · 食事は未記録';
  }

  @override
  String get intakeLabel => '摂取';

  @override
  String get partnerSignIn => '一緒に行うにはログインが必要です。';

  @override
  String get partnerSignInAction => 'ログイン';

  @override
  String get partnerMakeCode => 'コードを作る';

  @override
  String get partnerCopy => 'コピー';

  @override
  String partnerExpiresIn(String t) {
    return 'あと$tで期限切れ';
  }

  @override
  String get partnerExpired => 'コードの期限が切れました。';

  @override
  String get partnerNewCode => '新しいコード';

  @override
  String get partnerStopWaiting => 'やめる';

  @override
  String partnerWith(String name) {
    return '$nameさんと一緒に運動中';
  }

  @override
  String get partnerReconnecting => '再接続中 · 自分の記録は保存され続けます';

  @override
  String partnerTheirRecord(String name) {
    return '$nameさんの記録';
  }

  @override
  String get partnerNoRecordYet => 'まだ記録がありません。';

  @override
  String get partnerLoading => '読み込み中…';

  @override
  String get partnerEnd => '一緒の運動を終了';

  @override
  String get partnerEndedByMe => '一緒の運動を終了しました。自分の記録はそのまま残ります。';

  @override
  String partnerEndedByThem(String name) {
    return '$nameさんが一緒の運動を終了しました。自分の記録はそのまま残ります。';
  }

  @override
  String get partnerErrFormat => 'コードは6文字です。もう一度確認してください。';

  @override
  String get partnerErrInvalid => '一致するコードがありません。使用済みか入力ミスの可能性があります。';

  @override
  String get partnerErrExpired => '期限切れのコードです。新しいコードをもらってください。';

  @override
  String get partnerErrEnded => 'この招待はすでに終了しています。';

  @override
  String get partnerErrOwn => '自分が作ったコードです。相手の端末で入力してください。';

  @override
  String get partnerErrTries => '試行回数が多すぎます。しばらくしてからもう一度お試しください。';

  @override
  String get partnerErrNetwork => 'サーバーに接続できませんでした。通信環境を確認してもう一度お試しください。';

  @override
  String get partnerErrServer => 'サーバーで問題が発生しました。しばらくしてからもう一度お試しください。';

  @override
  String get partnerRetry => 'もう一度';

  @override
  String get partnerReadOnly => '閲覧のみ';

  @override
  String get partnerConflict =>
      '別の端末がより新しい記録を共有しました。この端末の記録はそのまま保存されており、共有だけ止まっています。';

  @override
  String get partnerShareThisDevice => 'この端末の記録で共有する';

  @override
  String get plansTitle => '共同ルーティン';

  @override
  String get planNew => '新しい共同ルーティン';

  @override
  String get planJoin => 'コードで参加';

  @override
  String get planHint => '1行目はタイトル、その後は1行に1種目\n例: スクワット 4セット';

  @override
  String get planDateNone => '日付未定';

  @override
  String planSetsCount(int n) {
    return '$nセット';
  }

  @override
  String get planSave => '提案する';

  @override
  String get planStateLocal => 'この端末だけの下書き · まだサーバーにありません';

  @override
  String get planStateDraft => '下書き · まだ一人です';

  @override
  String planStateWaiting(int v) {
    return '相手の確認待ち · バージョン$v';
  }

  @override
  String planStateNeedsMe(String name, int v) {
    return '$nameさんが変更しました · バージョン$vの確認が必要です';
  }

  @override
  String planStateAgreed(int v) {
    return '合意済み · バージョン$v';
  }

  @override
  String get planStateWithdrawn => '共同の計画は終了しました · 合意した計画と自分の目標は残ります';

  @override
  String planAccept(int v) {
    return 'バージョン$vを承認';
  }

  @override
  String get planChanged => '最後の合意から変わった点';

  @override
  String planAdded(String x) {
    return '追加: $x';
  }

  @override
  String planRemoved(String x) {
    return '削除: $x';
  }

  @override
  String planSetsChanged(String x) {
    return 'セット数変更: $x';
  }

  @override
  String get planReordered => '順番が変わりました';

  @override
  String get planDateChanged => '予定日が変わりました';

  @override
  String get planTitleChanged => 'タイトルが変わりました';

  @override
  String planLastAgreed(int v) {
    return '最後の合意 · バージョン$v';
  }

  @override
  String get planConflict => '相手が先に変更しました。自分の下書きはそのままです。';

  @override
  String planLatest(int v) {
    return '相手の最新の計画 · バージョン$v';
  }

  @override
  String get planKeepMine => '自分の下書きで再提案';

  @override
  String get planTakeLatest => '最新の計画に切り替える';

  @override
  String get planMyTarget => '自分の目標';

  @override
  String planPartnerTarget(String name, String t) {
    return '$name: $t';
  }

  @override
  String get planTargetHint => '例: 100 5 または 100kg 5回 x3 メモ';

  @override
  String get planInvite => '招待コードを作る';

  @override
  String get planStart => 'このルーティンで始める';

  @override
  String get planStartSolo => '自分用のコピーで始める';

  @override
  String get planStartSoloNote => 'まだ合意前です。今始めると合意済みの計画ではなく自分用のコピーで始まります。';

  @override
  String get planOpenWorkout => '始めた運動を開く';

  @override
  String get planCopyNext => '次の運動にコピー';

  @override
  String get planWithdraw => 'この共同計画をやめる';

  @override
  String get planCompare => '計画と実績';

  @override
  String planDoneSets(String name, int planned, int done) {
    return '$name · 計画$plannedセット · 実施$doneセット';
  }

  @override
  String planAddedActual(String x) {
    return '計画になかった種目: $x';
  }

  @override
  String planSkipped(String x) {
    return '行わなかった種目: $x';
  }

  @override
  String planStartedFrom(int v) {
    return '合意した共同ルーティン（バージョン$v）から開始';
  }

  @override
  String planStartedSolo(int v) {
    return '自分用のコピー（バージョン$v、合意前）から開始';
  }

  @override
  String get planShareLink => '招待リンクを送る';

  @override
  String planShareText(String url) {
    return 'setpadで一緒にトレーニング計画を立てよう: $url';
  }

  @override
  String get planLinkCopied => 'リンクをコピーしました。1日間、1回だけ使えます。';

  @override
  String get planLinkJoining => '招待された計画に参加しています…';

  @override
  String get nearbyHint => 'iPhone同士なら、この画面を開いたまま2台を近づけても接続できます。';

  @override
  String get planPropose => '共同ルーティンに提案';

  @override
  String get togetherStart => '一緒にスタート';

  @override
  String get togetherAlternate => '交代で';

  @override
  String togetherWaiting(String name) {
    return '$nameさんを待っています…';
  }

  @override
  String get togetherWaitingHint =>
      '相手の画面にリクエストが表示されます。表示されない場合は相手のアプリが最新か確認してください。';

  @override
  String togetherInvite(String name) {
    return '$nameさんが一緒にやろうと誘っています';
  }

  @override
  String get togetherInviteAlternate => '交代 · 相手が先';

  @override
  String get togetherLeave => 'やめる';

  @override
  String get togetherRejoin => 'もう一度入る';

  @override
  String togetherWith(String name) {
    return '$nameさんと一緒';
  }

  @override
  String get togetherTheirTurn => '相手の番';

  @override
  String togetherLeftBeat(String name, int n) {
    return '$nameさんは$n拍目で止まりました';
  }

  @override
  String togetherLeftRound(String name, int n) {
    return '$nameさんは$nラウンド目で止まりました';
  }

  @override
  String get togetherMe => '自分';

  @override
  String get togetherLog => '記録';

  @override
  String get mealLogAs => '食事として記録';

  @override
  String get proxyWrite => '代わりに記録';

  @override
  String proxyWriting(String name) {
    return '$nameさんの記録を入力中';
  }

  @override
  String get proxyDefaultName => '相手';

  @override
  String get proxyHand => '渡す';

  @override
  String get proxyBack => '自分の記録へ';

  @override
  String proxyShareText(String url) {
    return '一緒に運動しながら代わりに記録しました。setpadで開いて受け取ると自分の記録になります。\n$url';
  }

  @override
  String handoffOffer(String name) {
    return '$nameさんがあなたの記録をつけてくれました';
  }

  @override
  String get handoffTake => '受け取る';

  @override
  String get handoffFailed => '記録を受け取れませんでした。リンクの期限切れか、ネットワークの問題かもしれません。';

  @override
  String get handoffSignIn => '渡された記録を受け取るにはログインが必要です。';

  @override
  String partnerInviteMore(String code) {
    return 'もう1人招待 · コード $code';
  }

  @override
  String get proxyWhose => '誰の記録をつけますか？';

  @override
  String planMemberAccepted(String name) {
    return '$nameさん 同意済み';
  }

  @override
  String planMemberWaiting(String name) {
    return '$nameさん 未確認';
  }

  @override
  String deleteNoteAsk(String title) {
    return '「$title」を削除しますか？';
  }

  @override
  String get mealsTitle => '食事';

  @override
  String get recordMenu => 'その他';

  @override
  String dayIntakeOnly(String intake) {
    return '摂取 ${intake}kcal · 運動消費は未計測';
  }

  @override
  String dayIntakeOnlyApprox(String intake) {
    return '摂取 約${intake}kcal · 運動消費は未計測';
  }

  @override
  String dayUnknownMeals(int m) {
    return 'カロリー不明 $m件';
  }

  @override
  String get healthDataTitle => 'ヘルスケアデータ';

  @override
  String get healthDataIntro =>
      'setpad がヘルスケアアプリ(Apple ヘルスケア、ヘルスコネクト)とやり取りするものと、その理由です。';

  @override
  String get healthDataWrite => '書き込み・ワークアウト — 記録を終えると、その運動をワークアウトとして保存します。';

  @override
  String get healthDataCalories =>
      '読み取り・アクティブカロリー — 運動中にウォッチが計測したアクティブカロリーをその記録に付けます。計測がなければカロリーは表示しません。';

  @override
  String get healthDataHeart =>
      '読み取り・心拍数 — タバタの休憩中、心拍がそのラウンドの最高値より 25bpm 下がると休憩を終え、次のラウンドの開始を知らせます。休憩中はタイマーの行に ♥ 現在 → 目標 と表示されます。心拍がない、または 90 秒より古い値のときは、休憩は時間どおりに終わります。';

  @override
  String get healthDataStays =>
      'ヘルスケアアプリから読み取った値はこの端末の外に出ません。サーバーへ送らず、広告やマーケティングにも使いません。';

  @override
  String get healthDataRevokeIos =>
      '権限は iPhone の設定 → プライバシーとセキュリティ → ヘルスケア → setpad でいつでもオフにできます。';

  @override
  String get healthDataRevokeAndroid =>
      '権限はヘルスコネクト → アプリの権限 → setpad でいつでもオフにできます。';

  @override
  String get healthDataPrivacy => 'プライバシーポリシー';

  @override
  String get restAlarmTitle => '次のラウンド — 心拍が下がりました';

  @override
  String liveSetBusy(String name) {
    return '$nameさんがこのセットを編集中です。終わってからもう一度タップしてください。';
  }

  @override
  String liveExerciseBusy(String name) {
    return '$nameさんが今この種目を記録しています。';
  }

  @override
  String liveExerciseRemoved(String exercise) {
    return '一緒に記録している人が$exerciseを削除しました。入力中の文字はそのまま残っています。';
  }

  @override
  String get trainerReport => 'トレーナー報告';

  @override
  String get trainerUnread => '新しい報告';

  @override
  String trainerRanAt(String when) {
    return '$when 整理';
  }

  @override
  String get trainerRunNow => '今すぐ整理';

  @override
  String get trainerNoReport => 'まだ報告がありません。今すぐ整理しますか？';

  @override
  String get trainerOutdated => 'この報告は新しいバージョンで見られます。アプリを更新してください。';

  @override
  String get trainerFailed => 'サーバーに接続できませんでした。少し後でもう一度お試しください。';

  @override
  String get trainerActUnknown => '結果を確認できませんでした。もう一度押しても二重に記録されません。';

  @override
  String get trainerDone => 'エージェントが処理したこと';

  @override
  String get trainerToday => '今日のレッスン';

  @override
  String get trainerTodo => '確認すること';

  @override
  String get trainerAllClear => '確認することはすべて処理しました。';

  @override
  String get trainerAttendance => '締め前のレッスン';

  @override
  String trainerVisited(String time) {
    return '来館確認 $time';
  }

  @override
  String trainerFinishAll(int count) {
    return 'すべて完了 ($count)';
  }

  @override
  String trainerFinishAsk(int count) {
    return '$count件を完了 — PT回数券から1回ずつ差し引かれます。';
  }

  @override
  String get trainerFinish => '完了する';

  @override
  String get trainerJoinRequest => '登録リクエスト — Web CRM の「今日」画面で確認してください。';

  @override
  String get trainerBook => '予約する';

  @override
  String get trainerSend => '送る';

  @override
  String get trainerPaid => '支払い受領';

  @override
  String get trainerContacted => '連絡済み';

  @override
  String get trainerLater => 'あとで';

  @override
  String trainerPrice(int price) {
    final intl.NumberFormat priceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String priceString = priceNumberFormat.format(price);

    return '₩$priceString';
  }

  @override
  String trainerStarts(String d) {
    return '$dから';
  }

  @override
  String get trainerPayHow => 'お支払い方法は？';

  @override
  String get trainerPaidListPrice =>
      '商品価格のまま支払いとして記録されます。割引・分割払いはウェブCRMの会員画面の会員権タブで登録してください。';

  @override
  String get payCard => 'カード';

  @override
  String get payCash => '現金';

  @override
  String get payTransfer => '振込';

  @override
  String get payOther => 'その他';

  @override
  String get agentSettings => 'エージェント設定';

  @override
  String get agentEnabled => '決まった時刻にまとめる';

  @override
  String get agentTimes => '整理する時刻';

  @override
  String get agentAddTime => '時刻を追加';

  @override
  String get agentDays => '曜日';

  @override
  String get agentAutoConfirm => 'PT申請をすぐ確定';

  @override
  String get agentModes => '業務ごとの方法';

  @override
  String get agentModesHelp =>
      '手動 — エージェントは触れません。下書き — エージェントが用意し、あなたがタップで処理します。自動 — エージェントが処理します。';

  @override
  String get agentModeOff => '手動';

  @override
  String get agentModeDraft => '下書き';

  @override
  String get agentModeAuto => '自動';

  @override
  String get taskPtSchedule => 'PT日程';

  @override
  String get taskRenewal => '再登録・再決済';

  @override
  String get taskAttendance => '出欠整理';

  @override
  String get taskRoutine => 'ルーティン準備';

  @override
  String get taskContact => '会員への連絡';

  @override
  String get gymPolicy => 'ジムの方針';

  @override
  String get policyRenewalDays => '再登録の案内時期（満了の何日前）';

  @override
  String get policyLowSessions => 'PT不足の基準（予約できるPT回数）';

  @override
  String get policyAwayDays => '未来館の基準（日）';

  @override
  String get policyLapsedDays => '離脱とみなす期間（日）';

  @override
  String get policyOffer => '再登録案内の文言';

  @override
  String get policySave => '方針を保存';

  @override
  String get policySaved => '保存しました。';

  @override
  String get trainerWhichGym => 'どのジムですか？';

  @override
  String get trainerBack => '戻る';

  @override
  String get trainerCopy => '文面をコピー';

  @override
  String get trainerCopied => 'コピーしました';

  @override
  String get settingsTrainer => 'トレーナー';
}
