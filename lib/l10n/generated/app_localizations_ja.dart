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
  String monthLabel(int m) {
    return '$m月';
  }

  @override
  String get search => '検索・質問';

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
  String setsPerLineMax(int n) {
    return '1行で$nセットまでです。行を分けて入力してください。';
  }

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
  String get aiFallbackQuota => '今日の入力サポートを使い切ったので、入力どおりに追加しました';

  @override
  String get aiFallbackOffline => '接続できないため、入力どおりに追加しました。設定はカードの⚙から追加できます';

  @override
  String get aiFallbackServer => 'サーバーが応答しないため、入力どおりに追加しました。設定はカードの⚙から追加できます';

  @override
  String get aiFallbackUnread => '設定にできる内容が見つからず、入力どおりに追加しました。設定はカードの⚙から追加できます';

  @override
  String get inputNameTooLong => '種目名は120文字までです — 行を分けて入力してください';

  @override
  String get inputTooLong => '600文字を超える文は読み取りません — 行を分けて入力してください';

  @override
  String get setupAdd => '設定を追加';

  @override
  String setupUnparsed(String words) {
    return '設定に移せなかった語: $words — タイトルにそのまま残ります';
  }

  @override
  String setupDropped(String numbers) {
    return '入力にない数は外しました: $numbers';
  }

  @override
  String get setupNameMissing => '種目名を入力してください';

  @override
  String get setupNameTooLong => '120文字までです';

  @override
  String get setupWeightInvalid => '0より大きく2000以下の数を入力してください';

  @override
  String get setupCountInvalid => '1以上の整数を入力してください — 範囲や時間はタイトルに残してください';

  @override
  String get setupRepsOnly => '回数だけ記録';

  @override
  String setupSplit(int count) {
    return '$countつの種目に分けました';
  }

  @override
  String get setupMergeAll => '1つにまとめる';

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
  String get mealAdd => '食事を記録';

  @override
  String get mealWrite => '文字で入力';

  @override
  String get mealTypeHint => '食べ物は種目名の行にそのまま入力しても食事として残ります';

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
  String sameDayToday(String time) {
    return '今日 $time に別に残した記録';
  }

  @override
  String sameDayOn(String date, String time) {
    return '$date $time に別に残した記録';
  }

  @override
  String sameDayMore(String first, int n) {
    return '$first ほか$n件';
  }

  @override
  String lastWeekDay(String weekday, String date) {
    return '先週の$weekday（$date）の運動';
  }

  @override
  String weeksAgoDay(int n, String weekday, String date) {
    return '$n週間前の$weekday（$date）の運動';
  }

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
  String queryTooLong(int max) {
    return '質問は$max文字までです。短くしてください。';
  }

  @override
  String get queryPressEnter => 'Enterを押すと記録について質問できます。';

  @override
  String get mealRetry => '再推定';

  @override
  String kcalAtLeast(int n) {
    return '${n}kcal以上';
  }

  @override
  String mealTextPartial(int n) {
    return '書いた${n}kcalだけを合計に入れました。ほかの食べ物のカロリーは不明です。';
  }

  @override
  String mealTextBelowTyped(int n) {
    return '推定値が書いた${n}kcalより小さかったため使いませんでした。書いた${n}kcalだけを合計に入れました。';
  }

  @override
  String queryLimit(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'exercises': '種目は一度に8つまで質問できます。分けて質問してください。',
      'measures': '一度に数えられるのは4つまでです。分けて質問してください。',
      'ranking': 'ランキングは20件まで表示できます。20件以下で質問してください。',
      'sessions': '「直近N回」は100回までです。もっと長く見るには期間で質問してください。例: 今年',
      'days': '「最近N日」は3660日（約10年）までです。もっと長く見るには全期間で質問してください。',
      'compare': '一度に比較できるのは6つまでです。分けて質問してください。',
      'compareGrouped':
          '比較と、種目・日・週・月・曜日ごとのまとめは、1つの質問で同時に計算できません。どちらか一方で質問してください。',
      'groupedMeasure':
          '日・週・月・曜日ごとにまとめて複数の範囲を比べると数えられるのは1つだけで、推移・最後・最初・経過日数はまとめられません。',
      'ordering': 'ランキング・合計・平均は、種目別や週別のようにまとめて質問してください。',
      'datesTotal': '最後・最初の日付は合計や平均にできません。',
      'perMeasure':
          '日・週・月あたりの平均は、セット・回数・ボリューム・距離・時間・日数・kcal のように足せる数にだけ出せます。最高・平均重量は期間で聞いてください。',
      'shareMeasure': '割合はセット数やボリュームのように足せる数でだけ出せます。',
      'trainedMeasure':
          '運動した日・休んだ日の絞り込みは、食べた・消費した kcal にだけ使います。運動記録はすべて運動した日のものです。',
      'sameSeries': '比べる二つの範囲が同じに読めました。何と何を比べるか書いてください。',
      'other': 'この質問は記録検索で計算できない形です。分けて質問してください。',
    });
    return '$_temp0';
  }

  @override
  String policyNumberRejected(String text, String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'decimal': '「$text」— 小数は使えません。整数で入力してください。例: 14',
      'range': '「$text」— 範囲ではなく数字を1つ入力してください。例: 14',
      'negative': '「$text」— 0より小さい数は使えません。例: 14',
      'unit': '「$text」— この欄は日数・回数です。時間・週・月は日数に直して入力してください。例: 14',
      'many': '「$text」— 数字は1つだけ入力してください。例: 14',
      'other': '「$text」から日数・回数を読み取れませんでした。数字で入力してください。例: 14',
    });
    return '$_temp0';
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
  String get mealAutoLogged => '食事として記録しました';

  @override
  String get mealAutoUndo => '運動に変える';

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
  String get energyBurned => '運動';

  @override
  String get energyDifference => '差';

  @override
  String get energyDiffFormula => '食べた分 − 運動';

  @override
  String get energyDiffExplain =>
      '記録した食事のカロリーから、運動で消費したカロリーを引いた値です。プラスなら運動で使った分より多く食べ、マイナスなら少なく食べています。\n\n基礎代謝や日常の活動で使うカロリーは含まれないため、体重の増減そのものではありません。';

  @override
  String get estimateTag => '推定';

  @override
  String get energyNotLogged => '未記録';

  @override
  String get energyNotMeasured => '未計測';

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

  @override
  String get aiSetting => 'AIヘルプ';

  @override
  String get aiOff => 'AIヘルプがオフなので、入力のまま残しました。設定 › AIヘルプ でオンにできます';

  @override
  String get aiOffPhoto =>
      'AIヘルプがオフなので、写真からは推定しませんでした。食事をテキストで「おにぎり 180kcal」のように書くとそのまま入ります';

  @override
  String get answerNeedsTwoDays => '2日以上の記録が必要です';

  @override
  String get answerNoBase => '基準になる値がありません';

  @override
  String answerPerWeek(String value) {
    return '週あたり$value';
  }

  @override
  String answerPerMonth(String value) {
    return '月あたり$value';
  }

  @override
  String answerTimesAfter(int n) {
    return '最高記録のあと$n回';
  }

  @override
  String get answerTimesUnit => '回';

  @override
  String answerTimes(int n) {
    return '$n回';
  }

  @override
  String answerStreak(int n) {
    return '$n日連続';
  }

  @override
  String answerRestDays(int n) {
    return '$n日休み';
  }

  @override
  String get answerUntilToday => '今日';

  @override
  String answerEveryDays(String value) {
    return 'ふだん$value日ごと';
  }

  @override
  String answerMeanEvery(String value) {
    return '平均$value日ごと';
  }

  @override
  String answerGapSpread(int a, int b, int c, int d) {
    return '連日 $a回 · 1日休んで $b回 · 2日休んで $c回 · 3日以上休んで $d回';
  }

  @override
  String answerLongestIncluded(int n) {
    return '最長$n日の休みを含みます';
  }

  @override
  String get answerNoMeals => '食事を記録した日がありません';

  @override
  String answerAbout(String value) {
    return '約$value';
  }

  @override
  String answerMealDays(int n) {
    return '食事を記録した$n日';
  }

  @override
  String queryUnknownMeals(int n) {
    return 'カロリー不明の食事$n件は合計に入っていません';
  }

  @override
  String get answerNoWatch => 'ウォッチで計測した記録がありません';

  @override
  String answerWatchDays(int n) {
    return 'ウォッチで計測した$n日';
  }

  @override
  String get answerNoBoth => '摂取と消費の両方がある日がありません';

  @override
  String answerBothDays(int n) {
    return '摂取と消費の両方がある$n日';
  }

  @override
  String answerIntakeOnlyDays(int n) {
    return '摂取だけの$n日は除きました';
  }

  @override
  String answerMonths(int n) {
    return '$nか月';
  }

  @override
  String get metricChangePct => '変化率';

  @override
  String get metricDaysSinceBest => '最高記録からの日数';

  @override
  String get metricSessionsSinceBest => '最高記録後の回数';

  @override
  String get metricMeanReps => 'セットあたりの回数';

  @override
  String get metricLongestStreak => '最長連続';

  @override
  String get metricLongestGap => '最長の空白';

  @override
  String get metricMeanGap => '運動の間隔';

  @override
  String get metricIntake => '摂取カロリー';

  @override
  String get metricBurned => '消費カロリー';

  @override
  String get metricBalance => '摂取 − 消費';

  @override
  String get queryAlone => 'ひとりの日';

  @override
  String get queryTogether => '一緒にした日';

  @override
  String get queryByPart => '部位別';

  @override
  String get queryCanSee => '記録からは重量・回数・セット・運動した日・食事のカロリーが分かります';

  @override
  String get queryDiffColumn => '差';

  @override
  String get queryFutureCell => 'まだ来ていない期間';

  @override
  String get queryGrowthRate => '伸びは週あたりの速さで順位をつけました（期間が違っても公平に）';

  @override
  String get queryHandoff => '受け取った記録だけ';

  @override
  String get queryNoHandoff => '受け取った記録を除く';

  @override
  String queryHandoffCount(int n) {
    return '受け取った記録$n件を除く';
  }

  @override
  String get queryHoursNote => '時刻は記録を作った時点です。あとでまとめて書いた記録はその時刻になります';

  @override
  String get queryMixedWeights => '複数の種目を混ぜた重量です';

  @override
  String get queryNcBodyweight =>
      '体重は記録にありません。質問に体重を書けばその数と比べます（例: 体重80でデッドは何倍？）';

  @override
  String get queryNcWeightForecast =>
      '何kgになるかは計算しません。記録にあるのは食べた分と運動の消費だけで、基礎代謝や日常の活動で使うカロリーがありません';

  @override
  String get queryNcHeartRate =>
      '記録検索はまだ心拍を見ていません。種目別・休憩別の心拍はセットの時刻がないので見られません';

  @override
  String get queryNeverMark => '記録なし';

  @override
  String get queryNoBaseRatio => '基準値がないので比率を出せません';

  @override
  String get queryNoneCell => 'この範囲に記録なし';

  @override
  String get queryNoRoutine => 'ルーティン以外の日';

  @override
  String get queryRoutine => 'トレーナーのルーティンの日';

  @override
  String get queryOngoing => '進行中';

  @override
  String get queryOverlap => '運動日数は重なる日があるので比重を出せません。セット数で聞いてください';

  @override
  String queryPart(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'chest': '胸',
      'back': '背中',
      'legs': '脚',
      'shoulders': '肩',
      'arms': '腕',
      'core': '体幹',
      'cardio': '有酸素',
      'upper': '上半身',
      'lower': '下半身',
      'other': '部位',
    });
    return '$_temp0';
  }

  @override
  String get queryRatioColumn => '倍率';

  @override
  String get queryRatioUnits => '単位が違うので比率を出せません';

  @override
  String get queryRestDay => '休んだ日';

  @override
  String get queryTrained => '運動した日';

  @override
  String get querySetFirst => '最初のセット';

  @override
  String get querySetLast => '最後のセット';

  @override
  String get queryShare => '比重';

  @override
  String get queryZeroFilled => 'やっていない種目も0として入れました';

  @override
  String queryAgainst(String value) {
    return '基準 $value';
  }

  @override
  String queryAgainstLine(
    String value,
    String target,
    String ratio,
    String diff,
  ) {
    return '$value ÷ $target = $ratio倍 · 差 $diff';
  }

  @override
  String queryAlias(String name, String names) {
    return '$name = $names';
  }

  @override
  String queryDayCount(int n) {
    return '$n日';
  }

  @override
  String queryDroppedSets(int n) {
    return '値の種類が違うセット$n件を除外';
  }

  @override
  String queryHours(int from, int to) {
    return '$from–$to時';
  }

  @override
  String queryMaybe(String name) {
    return 'もしかして$name？';
  }

  @override
  String queryMemoAll(String terms) {
    return 'メモにすべて: $terms';
  }

  @override
  String queryMemoHit(String text, int n) {
    return '$text $n日';
  }

  @override
  String queryMemoHits(String hits) {
    return '該当メモ: $hits';
  }

  @override
  String queryNeverPartial(String names) {
    return '$names: 記録がないので除いて数えました';
  }

  @override
  String queryNeverRows(String names) {
    return '$names: 記録がありません';
  }

  @override
  String queryNoMemo(String terms) {
    return 'メモになし: $terms';
  }

  @override
  String queryNoRepsSets(int n) {
    return '回数のないセット$n件を除外';
  }

  @override
  String queryNotComputable(String things) {
    return '記録にないので見られないもの: $things';
  }

  @override
  String queryNotComputableTail(String things) {
    return '見られないもの: $things';
  }

  @override
  String queryNothingComputable(String things) {
    return '記録では答えられません: $things';
  }

  @override
  String queryNoWeightSets(int n, int reps) {
    return '重量のないセット$n件を除外（最多$reps回）';
  }

  @override
  String queryNth(int n) {
    return '最後から$n番目の運動日';
  }

  @override
  String queryOtherDistance(int n, String value) {
    return '距離を記録した$n回: $value';
  }

  @override
  String queryOtherDuration(int n, String value) {
    return '時間を記録した$n回: $value';
  }

  @override
  String queryPartial(String names) {
    return '$namesを除く';
  }

  @override
  String queryPartialChunk(int n) {
    return '（$n日）';
  }

  @override
  String queryPartMembers(String part, String names) {
    return '$part: $names';
  }

  @override
  String queryPer(String per) {
    String _temp0 = intl.Intl.selectLogic(per, {
      'day': '1日あたり',
      'week': '週あたり',
      'month': '月あたり',
      'other': '平均',
    });
    return '$_temp0';
  }

  @override
  String queryPerSuffix(String per) {
    String _temp0 = intl.Intl.selectLogic(per, {
      'day': '/日',
      'week': '/週',
      'month': '/月',
      'other': '/',
    });
    return '$_temp0';
  }

  @override
  String queryRatioHead(String a, String b) {
    return '$a ÷ $b';
  }

  @override
  String queryRatioLine(String a, String b, String value, String percent) {
    return '$a ÷ $b = $value倍（$percent%）';
  }

  @override
  String queryRelative(String by, int n) {
    String _temp0 = intl.Intl.selectLogic(by, {
      'day': '$n日目',
      'week': '$n週目',
      'month': '$nか月目',
      'other': '$n番目',
    });
    return '$_temp0';
  }

  @override
  String queryRolled(String year) {
    return 'まだ来ていない期間なので$year年として読みました';
  }

  @override
  String querySamePeriod(int days, String earlier, String later) {
    return '同じ$days日で比べると: $earlier → $later';
  }

  @override
  String queryShortGrowth(String names) {
    return '記録が短いので（3日・3週未満）順位から外しました: $names';
  }

  @override
  String queryTimer(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tabata': 'タバタ',
      'bpm': 'BPMタイマー',
      'other': 'タイマーなし',
    });
    return '$_temp0';
  }

  @override
  String queryUnknownPart(String names) {
    return '部位が分からない種目は除きました: $names';
  }

  @override
  String queryUnranked(int n, String names) {
    return '値が欠けて順位に入れられなかった$n件: $names';
  }

  @override
  String queryWindowLengths(String lengths) {
    return '期間の日数が違うので（$lengths日）差と比率は週あたりで数えました';
  }

  @override
  String queryZeroBuckets(String by, int total, int zeros) {
    String _temp0 = intl.Intl.selectLogic(by, {
      'week': '$total週のうち$zeros週が0',
      'month': '$totalか月のうち$zerosか月が0',
      'other': '$total件のうち$zeros件が0',
    });
    return '$_temp0';
  }

  @override
  String queryPossibleDays(int m, String percent) {
    return '可能な$m日のうち$percent%';
  }

  @override
  String get queryOfflineLocal =>
      'サーバーにつながらないため、文中の種目と期間だけで端末上で集計しました。つながったら Enter でもう一度聞いてください。';

  @override
  String get queryMisread => 'この質問は集計できる形に読めませんでした。言い方を変えて聞いてください。';

  @override
  String get queryMisreadLocal =>
      '質問を集計できる形に読めなかったため、文中の種目と期間だけで端末上で集計しました。言い方を変えるともう一度読みます。';

  @override
  String get queryUnreadable =>
      'モデルが読み取れない答えを2回返しました。接続の問題ではなく、その答えにプレートは使われていません。';

  @override
  String get queryAskAgain => 'もう一度聞く';

  @override
  String get queryUnreadablePaid =>
      'モデルが読み取れない答えを2回返しました。接続の問題ではありません。その答えにプレートは使われておらず、下のプレートは質問を振り分けた最初の段階の分です。';

  @override
  String get queryUnreadableLocal => 'その間、文中の種目と期間で端末上で集計しました。';

  @override
  String get queryTotalUnits => '単位が違うため合計を出せません';

  @override
  String queryMemoDropped(String words) {
    return 'メモの条件を外しました: $words';
  }

  @override
  String queryAgainstDropped(String value) {
    return '基準の数 $value を外しました — 質問に重さとして書かれた数ではありません';
  }

  @override
  String routineDate(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.Md(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get routineHeaderToday => '今日のルーティン';

  @override
  String routineHeaderDay(String day) {
    return '$dayのルーティン';
  }

  @override
  String routineTomorrow(String date) {
    return '明日($date)';
  }

  @override
  String routineWhyRotation(String date, int days) {
    return '$dateのメニューを$days日やっていません — その日と同じに組みました';
  }

  @override
  String routineWhyFrom(String date) {
    return '$dateと同じ';
  }

  @override
  String routineWhyNamed(String date) {
    return '$dateに一緒にやった種目で埋めました';
  }

  @override
  String routinePartRest(String list) {
    return '直近28日: $list前';
  }

  @override
  String routinePartDays(String part, int days) {
    return '$part$days日';
  }

  @override
  String routineEstimate(int minutes) {
    return '約$minutes分';
  }

  @override
  String routinePaceOwn(int sessions, String pace) {
    return '直近$sessions回の1セット$paceで見積もり';
  }

  @override
  String routinePaceDefault(String pace) {
    return '既定の1セット$paceで見積もり — 何回か記録すると自分のペースになります';
  }

  @override
  String routineMinSec(int m, int s) {
    return '$m分$s秒';
  }

  @override
  String routineReadAs(String list) {
    return '読み取り: $list';
  }

  @override
  String routineCopied(String date) {
    return '$dateと同じ';
  }

  @override
  String routineRepsMatched(String date, int reps) {
    return '$dateに$reps回できた重さ';
  }

  @override
  String get routineTyped => '入力どおり';

  @override
  String get routineFirst => '初めて';

  @override
  String routineBlank(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'light': '軽めなので重さは空欄',
      'pain': '痛みがあるので重さは空欄',
      'gear': '器具が違うので重さは空欄',
      'bodyweight': '器具の重さなので空欄',
      'stale': '久しぶりなので重さは空欄',
      'repsUnmatched': 'その回数・セット数でやった日がないので重さは空欄',
      'other': '重さは空欄',
    });
    return '$_temp0';
  }

  @override
  String routineReference(String sets, String date) {
    return '参考: $sets($date)';
  }

  @override
  String routineBest(String set, String date) {
    return '参考: 最高 $set($date)';
  }

  @override
  String routineStepped(String step, String evidence) {
    return '+$step($evidence)';
  }

  @override
  String routineMemo(String date, String memo) {
    return '$dateのメモ: $memo';
  }

  @override
  String routineRecent(String part, String when) {
    return '$part · $when';
  }

  @override
  String routineDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n日前',
      one: '昨日',
      zero: '今日',
    );
    return '$_temp0';
  }

  @override
  String get routineFuture => 'プレビューです — その日に「ルーティン」と入力するとその日の記録として始められます';

  @override
  String routineRefused(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'diet': '食事メニューは作りません — 食事を記録するとカロリーは見られます',
      'medical': 'リハビリや手術後の運動は判断しません — 医師・療法士から受けた種目を記録すればそのままルーティンにします',
      'drug': '薬物には協力できません',
      'program': '一度に1日分だけ組みます — 今日のルーティンです',
      'logging': 'やっていないセットを完了にはしません — やるときに押してください',
      'format': 'EMOM・スーパーセット・サーキットのタイマーはありません — 順番だけ組みました(タバタ・bpmは使えます)',
      'person': '他の人のルーティンは組みません — 自分の記録の種目名だけ表示します',
      'other': 'トレーニング記録とルーティンだけお手伝いします',
    });
    return '$_temp0';
  }

  @override
  String routineNotStated(String what) {
    return '入力にない数なので外しました: $what';
  }

  @override
  String routineUnmet(String what) {
    return '合わせられなかった条件: $what';
  }

  @override
  String routineKeyName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'when': '日',
      'from': '過去の日',
      'parts': '部位',
      'pattern': 'プッシュ/プル',
      'exercises': '種目',
      'exclude': '外す種目',
      'avoid': '避ける部位',
      'pain': '痛み',
      'equipment': '器具',
      'count': '種目数',
      'minutes': '時間',
      'intensity': '強度',
      'timer': 'タイマー',
      'targets': '入力した数',
      'delta': '重さの増減',
      'other': '条件',
    });
    return '$_temp0';
  }

  @override
  String routineUnknownName(String name) {
    return '辞書にないので外しました: $name';
  }

  @override
  String get routineNoSuchDay => 'その日はありません — 記録から組みました';

  @override
  String routineExcludeAbsent(String name) {
    return '外す種目はもともとありません: $name';
  }

  @override
  String routineNoneMatched(String what) {
    return '記録した$whatの種目がありません — 選んで追加できます';
  }

  @override
  String routineFewer(int n) {
    return '記録から入れられる種目は$nつです';
  }

  @override
  String routineOtherUnit(String unit) {
    return '$unitで記録したセットはそのままです';
  }

  @override
  String get routineBpmRange => 'bpmは10–120です — タイマーなしで入れました';

  @override
  String routineIntensityLine(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'light': '軽め: 各種目の最後の1セットを減らしました — 重さは前回と同じです',
      'lightBlank': '軽め: 各種目の最後の1セットを減らしました',
      'hard': '重さは前回と同じです',
      'max': '何kgに挑戦するかは決めません — 最高記録を横に書きました',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get routineNoStep => '上げる幅を入力してください(例: +2.5kg)';

  @override
  String routinePain(String phrase, String list) {
    return '「$phrase」で外したもの: $list · 重さは空欄 · 大丈夫かどうかは判断しません';
  }

  @override
  String routinePainNone(String phrase) {
    return '「$phrase」 — 外した種目はなく重さは空欄 · 大丈夫かどうかは判断しません';
  }

  @override
  String get routinePainWord => '痛み';

  @override
  String get routineFirstTime => '初めてです — 入れる種目を選ぶと数字なしで入ります';

  @override
  String routineCountFit(int count, int minutes) {
    return '$count種目に合わせました — 約$minutes分';
  }

  @override
  String routineNoMore(int minutes) {
    return '記録から追加できる種目がありません — 約$minutes分です';
  }

  @override
  String routineOverTime(int minutes) {
    return '指定した種目だけで約$minutes分です';
  }

  @override
  String routineOverUsual(int n, int usual) {
    return '選んだ$n種目をすべて入れました — いつも1回にする$usual種目より多いです';
  }

  @override
  String routineRecentMemo(String when, String name, String memo) {
    return '$whenの$nameのメモ: $memo';
  }

  @override
  String routineRemoved(String label, String why) {
    return '外したもの: $label — $why';
  }

  @override
  String routineRemovedWhy(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'named': '指定した種目',
      'avoid': '避ける部位',
      'unknownPart': '部位が不明',
      'gear': '器具が違う',
      'unknownGear': '器具が不明',
      'otherPart': '別の部位',
      'user': '自分で外した',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get routineRestore => '戻す';

  @override
  String routineAdd(String name) {
    return '+ $name';
  }

  @override
  String get routineOther => '別のルーティン';

  @override
  String get routineWhyShow => '根拠を見る';

  @override
  String get routineWhyHide => '根拠を閉じる';

  @override
  String routinePrevious(String date) {
    return 'その前($date)';
  }

  @override
  String routineByPart(String part) {
    return '$partで組む';
  }

  @override
  String routineStepChip(String step) {
    return '+$step上げる(自分の上げ幅)';
  }

  @override
  String routineAskToo(String text) {
    return 'これも聞く: $text · プレート';
  }

  @override
  String get routineAsQuestion => '記録の質問として聞く · プレート';

  @override
  String get routineNoConditions => '条件なしですぐ組む';

  @override
  String get routineWithConditions => '条件まで読んで組む · プレート';

  @override
  String get routineMake => '今日のルーティンを作る';

  @override
  String routineMakePart(String part) {
    return '今日の$partルーティンを作る';
  }

  @override
  String get routineStart => '開始';

  @override
  String get routineStarted => '開始済み · 開く';

  @override
  String get routineWorking => '条件を読んでいます…';

  @override
  String get routineOffline => '接続できず条件は読めませんでした — 記録だけで組みました';

  @override
  String get routineMisread => '条件を読めませんでした — 記録だけで組みました。言い換えると読み直します';

  @override
  String routineHeldBack(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'offline': '接続できず',
      'noPlates': 'プレートがなく',
      'other': '答えを読めず',
    });
    return '$_temp0条件(外す・痛み)を読めなかったのでルーティンは作りませんでした';
  }

  @override
  String routineTypedWeight(int count, String from, String to) {
    return '入力した重さ: メインセット$countつ $from → $to';
  }

  @override
  String get routineTypedKept => '入力した重さはそのまま';

  @override
  String get routinePlatesBefore => 'この文には前にプレートを使いました · 今回は0枚';

  @override
  String get routineRetry => '再試行';

  @override
  String get routinePressEnter => 'Enterで条件まで読んで組みます · プレート';

  @override
  String get routineFromQuestion => 'ルーティンの依頼として読みました';

  @override
  String routinePattern(String p) {
    String _temp0 = intl.Intl.selectLogic(p, {
      'push': 'プッシュ',
      'pull': 'プル',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineGear(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'barbell': 'バーベル',
      'dumbbell': 'ダンベル',
      'machine': 'マシン',
      'cable': 'ケーブル',
      'bodyweight': '自重',
      'bar': '懸垂バー',
      'kettlebell': 'ケトルベル',
      'band': 'バンド',
      'bench': 'ベンチ',
      'other': '器具',
    });
    return '$_temp0';
  }

  @override
  String routineGearOnly(String list) {
    return '$listのみ';
  }

  @override
  String routineGearWithout(String list) {
    return '$listなし';
  }

  @override
  String routineMinutes(int n) {
    return '$n分';
  }

  @override
  String routineCount(int n) {
    return '$n種目';
  }

  @override
  String routineIntensity(String k) {
    String _temp0 = intl.Intl.selectLogic(k, {
      'light': '軽め',
      'hard': '重め',
      'max': 'PR挑戦',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineExclude(String list) {
    return '外す: $list';
  }

  @override
  String routineAvoid(String list) {
    return '避ける: $list';
  }

  @override
  String get routinePlatesZero => 'プレート0枚';

  @override
  String get routineFullBody => '全身';

  @override
  String get routineNoPlates => 'プレートがなく条件は読めませんでした — 記録だけで組みました';

  @override
  String get routineBack => 'ルーティンに戻る';

  @override
  String queryBoundDropped(String value) {
    return '数の条件 $value を外しました — 質問にその単位で書かれた数ではありません';
  }

  @override
  String get anatomyTitle => 'ボディマップ';

  @override
  String get anatomyOpen => 'ボディマップ — 部位別の種目とフォームのコツ';

  @override
  String get anatomyPick => '体の図から種目を選ぶ';

  @override
  String get anatomyFront => '前';

  @override
  String get anatomyBack => '後ろ';

  @override
  String anatomyDays(int n) {
    return '$n日';
  }

  @override
  String muscleName(String m) {
    String _temp0 = intl.Intl.selectLogic(m, {
      'chest': '胸',
      'frontDelts': '肩の前部',
      'sideDelts': '肩の側部',
      'rearDelts': '肩の後部',
      'traps': '僧帽筋上部',
      'upperBack': '背中の中部',
      'lats': '広背筋',
      'lowerBack': '腰',
      'biceps': '上腕二頭筋',
      'triceps': '上腕三頭筋',
      'forearms': '前腕',
      'abs': '腹筋',
      'obliques': '腹斜筋',
      'hipFlexors': '股関節屈筋',
      'glutes': 'お尻',
      'quads': '太もも前',
      'hamstrings': '太もも裏',
      'adductors': '内もも',
      'calves': 'ふくらはぎ',
      'infraspinatus': '棘下筋',
      'teresMinor': '小円筋',
      'teresMajor': '大円筋',
      'tricepsLong': '上腕三頭筋 長頭',
      'tricepsLateral': '上腕三頭筋 外側頭',
      'tricepsMedial': '上腕三頭筋 内側頭',
      'other': '部位',
    });
    return '$_temp0';
  }

  @override
  String anatomyLevel(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'low': '少ない',
      'mid': '中くらい',
      'high': '多い',
      'other': 'なし',
    });
    return '$_temp0';
  }

  @override
  String get anatomyLegend => 'この期間にセットが多い部位ほど濃くなります';

  @override
  String get anatomyFirstTime =>
      'まだ完了したセットがないので色はありません。部位をタップすると、その部位を使う種目とフォームのコツが見られます。';

  @override
  String anatomyEmptyWindow(int n) {
    return '直近$n日に完了したセットはありません';
  }

  @override
  String anatomyUnknown(int n) {
    return '筋肉がわからない種目$n件は数えていません。名前をタップすると検索で記録を見られます。';
  }

  @override
  String anatomyUnknownMore(int n) {
    return 'ほか$n件';
  }

  @override
  String anatomyCardio(int n) {
    return '有酸素$nセットはボディマップに入れていません';
  }

  @override
  String get anatomyCountNote =>
      '筋肉はExRx.net・ACEの分類に沿った目安です。* の付いた種目は筋肉の割り当てが解釈です。主に使う筋肉は1セット、補助の筋肉は0.5セットとして数え、ウォームアップも1セットに数えます。';

  @override
  String get anatomyLimits => '動画やフォームの分析はしません。痛みがあれば中止して専門家に相談してください。';

  @override
  String get anatomyTapHint => '筋肉をタップしてください — 下のリストからも選べます';

  @override
  String get anatomyNoSurface => '体の奥の筋肉なので図にはありません';

  @override
  String anatomySets(int days, String sets) {
    return '$days日 $setsセット';
  }

  @override
  String anatomySetsLine(String week, String month) {
    return '直近7日 $weekセット · 28日 $monthセット';
  }

  @override
  String anatomyBreakdown(int primary, int secondary) {
    return '28日のうち主に使ったセット $primary · 補助 $secondary(半分で計算)';
  }

  @override
  String anatomyLast(String date, String ago) {
    return '最後: $date($ago)';
  }

  @override
  String get anatomyNever => '表にある種目では、この部位の記録はまだありません';

  @override
  String get anatomyDone => 'やった種目';

  @override
  String get anatomyTry => 'この部位を主に使う種目';

  @override
  String get anatomyTrySecondary => 'この部位を補助で使う種目';

  @override
  String anatomyTryGear(String list) {
    return '使ったことのある器具($list)でできるもの';
  }

  @override
  String get anatomyAllGear => '器具の記録がないのですべて表示しています';

  @override
  String anatomyMoreGear(int n) {
    return 'ほかの器具の種目をあと$n個見る';
  }

  @override
  String get anatomyTriedAll => 'この部位を主に使う種目はすべてやりました';

  @override
  String anatomyRole(String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'primary': '主に使う',
      'other': '補助',
    });
    return '$_temp0';
  }

  @override
  String get anatomyInterpNote => '* の付いた種目は、筋肉の割り当てが出典からの解釈です';

  @override
  String get anatomyCues => 'フォームのコツ';

  @override
  String get anatomyMistakes => '避けること';

  @override
  String anatomySources(String sites) {
    return '出典: $sites';
  }

  @override
  String get anatomyUnsourced => '‡ 出典なしで付け加えた内容';

  @override
  String get anatomyAdapted => '† 出典の文を言い換えた解釈（似た動作の出典を含む）';

  @override
  String get anatomyCuesEnglish => 'フォームのコツは今のところ英語のみです';

  @override
  String get anatomyAddRoutine => '今日のルーティンに入れる';

  @override
  String anatomyRoutineText(String part) {
    return '今日の$partルーティン';
  }

  @override
  String get anatomySearch => '検索で見る';

  @override
  String anatomyRegionValue(int days, String sets, String level) {
    return '直近$days日 $setsセット、$level';
  }

  @override
  String get anatomyRegionHint => 'ダブルタップで種目を見る';

  @override
  String get anatomyClose => '閉じる';

  @override
  String anatomyTileSets(String n) {
    return '$nセット';
  }

  @override
  String get anatomyLastLabel => '最後';

  @override
  String get openSourceLicenses => 'オープンソースライセンス';

  @override
  String routineFactor(String f) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength': '筋力',
      'endurance': '筋持久力',
      'sustain': '持続力',
      'power': '瞬発力',
      'cardio': '心肺',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineFactorDay(String factor, String why) {
    return '$factorの日 · $why';
  }

  @override
  String routineFactorWhy(String kind, String a, String b) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tabata': 'タバタ $a',
      'fill': '$a回達成',
      'fillTitle': 'タイトル「$a」',
      'distance': '$a',
      'open': '1セット$a回、セット数は自由',
      'single': '1セット$a回',
      'drop': '毎セット最大 $a',
      'hold': '$a回×$bセット',
      'other': '$a×$b',
    });
    return '$_temp0';
  }

  @override
  String routineWhyWeekday(int weeks, String day, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '先週の$dayは記録がないので$weeks週間前の$day($date)で組みました',
      one: '先週の$day($date)と同じです',
    );
    return '$_temp0';
  }

  @override
  String routineWhyNear(String day, String near) {
    return '$dayの記録がないので近い$nearで組みました';
  }

  @override
  String routineWhyFactor(String f, String date) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength': '今週は筋力が足りないので$dateで組みました',
      'endurance': '今週は筋持久力が足りないので$dateで組みました',
      'sustain': '今週は持続力が足りないので$dateで組みました',
      'cardio': '今週は心肺が足りないので$dateで組みました',
      'other': '$dateで組みました',
    });
    return '$_temp0';
  }

  @override
  String routineWhyFactorAll(String f, String date) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength': '今週の要素はすべて満たしました — 次の番の筋力で$dateと同じに組みました',
      'endurance': '今週の要素はすべて満たしました — 次の番の筋持久力で$dateと同じに組みました',
      'sustain': '今週の要素はすべて満たしました — 次の番の持続力で$dateと同じに組みました',
      'cardio': '今週の要素はすべて満たしました — 次の番の心肺で$dateと同じに組みました',
      'other': '$dateと同じに組みました',
    });
    return '$_temp0';
  }

  @override
  String routineWeekCounts(String range, String list) {
    return '直近7日($range): $list';
  }

  @override
  String routineFactorMissing(String list) {
    return '直近28日に単独でやった日がない要素: $list';
  }

  @override
  String get routineFillHint => '回数達成は目標回数を書いてください(例: スクワット100回達成)';

  @override
  String get routineTabataChip => 'タバタで';

  @override
  String routineLikeLastWeek(String day) {
    return '先週の$dayのように';
  }

  @override
  String routineFactorChip(String f, int n) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength': '筋力で組む · 今週$n回',
      'endurance': '筋持久力で組む · 今週$n回',
      'sustain': '持続力で組む · 今週$n回',
      'cardio': '心肺で組む · 今週$n回',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineLightKept(String list) {
    return 'そのままにした種目(1セット・回数達成・タバタ): $list';
  }

  @override
  String routineWhyWeekdaySkip(String how, int weeks, String day, String date) {
    String _temp0 = intl.Intl.selectLogic(how, {
      'alt': '別のルーティン: $weeks週間前の$day($date)で組みました',
      'other': '先週の$dayは除外した種目だけなので$weeks週間前の$day($date)で組みました',
    });
    return '$_temp0';
  }

  @override
  String routineWhyNearSkip(String how, String day, String near) {
    String _temp0 = intl.Intl.selectLogic(how, {
      'alt': '別のルーティン: 近い$nearで組みました',
      'other': '$dayは除外した種目だけなので近い$nearで組みました',
    });
    return '$_temp0';
  }

  @override
  String routineWhyFactorNoDay(String factor, String date) {
    return '足りない要素は直近28日に使える日がないので$dateの$factorの日と同じに組みました';
  }

  @override
  String routineFactorLost(String factor, String date) {
    return '$dateの$factorの日で組みましたが、$factorの種目は外れました';
  }

  @override
  String routineFactorFiltered(String list) {
    return '除外した種目を除くと直近28日に残る日がない要素: $list';
  }

  @override
  String routineLightDropped(String date) {
    return '$dateより1セット少なく';
  }

  @override
  String routineDoneToday(String list) {
    return '今日すでにやった種目が入っています: $list';
  }
}
