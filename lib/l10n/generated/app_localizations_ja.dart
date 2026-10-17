// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class LJa extends L {
  LJa([String locale = 'ja']) : super(locale);

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
  String get aiWorking => '種目を設定中…';

  @override
  String get aiJudging => '読み取り中…';

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
  String get moveSetEarlier => '前へ移動';

  @override
  String get moveSetLater => '後ろへ移動';

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
  String get queryAmbiguous => 'どの運動のどの記録か、もう少し具体的に入力してください。';

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
  String get proSignInOptional => 'ログインしなくても購入できます。ログインすると他の端末でもプランを使えます。';

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
  String get accountDelete => 'アカウント削除';

  @override
  String get accountDeleteAsk =>
      '元に戻せません。ルーティン、記録、チケット、予約がすべて消えます。App Store・Google Play の購読は、ストアで解約するまで課金が続きます。';

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
  String get mealFailed => '写真からカロリーを推定できませんでした。撮り直してください。';

  @override
  String mealServingsOption(String n) {
    return '$n食分';
  }

  @override
  String get fitAll => '今日の運動';

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
  String get mealReviewTitle => '食品と量を確認';

  @override
  String get mealReviewNote =>
      '食品名と食べた量を確認してください。量は下で修正できます。食品が違う場合はキャンセルして再入力または再撮影してください。';

  @override
  String get mealEstimatedAmount => 'AIが推定した量です。実際に食べた量に修正してください。';

  @override
  String get mealLabelReviewNote => '写真の熱量・基準量・単位と照合し、読み違えた値を修正してから保存してください。';

  @override
  String get mealTextNeedsReview =>
      '合計カロリーまたは食べた量が不明です。食事をタップして、実際に摂取したカロリーか正確な量を入力してください。';

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
  String get mealSourceOff => 'Open Food Facts';

  @override
  String mealMacros(String carbs, String protein, String fat) {
    return '炭水化物 ${carbs}g · たんぱく質 ${protein}g · 脂質 ${fat}g';
  }

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
  String dayBurnedOnly(String n) {
    return '運動 ${n}kcal · 食事は未記録';
  }

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
  String get nearbyHint => 'iPhone同士なら、この画面を開いたまま2台を近づけても接続できます。';

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
  String get mealAutoLogged => '食事として記録しました';

  @override
  String get mealAutoUndo => '運動に変える';

  @override
  String get exerciseAutoLogged => '運動として記録しました';

  @override
  String get exerciseAutoUndo => '食事に変える';

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
  String deleteNoteAsk(String title) {
    return '「$title」を削除しますか？';
  }

  @override
  String mealDeleteAsk(String meal) {
    return '食事「$meal」を削除しますか？';
  }

  @override
  String get mealsTitle => '食事';

  @override
  String get energyBurned => '運動';

  @override
  String get energyDifference => '差';

  @override
  String get fold => '閉じる';

  @override
  String get energySurplus => '黒字';

  @override
  String get energyDeficit => '赤字';

  @override
  String get milestoneBest => '最高重量';

  @override
  String get energyDiffFormula => '食べた分 − 運動';

  @override
  String get energyDiffExplain =>
      '記録した食事のカロリーから、その日の消費カロリー（基礎代謝＋運動）を引いた値です。プラスは黒字、マイナスは赤字です。\n\n基礎代謝はヘルスケアの安静時エネルギーを優先し、なければ体の情報から計算します（推定）。歩くなどの日常の活動は含まれないため、体重の増減そのものではありません。';

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
  String get healthDataBasal =>
      '読み取り · 安静時エネルギー（基礎代謝）— その日の消費カロリーに加え、食べた分との差を計算します。記録がなければ 設定 › 体の情報 から計算します。';

  @override
  String get bodyTitle => '体の情報';

  @override
  String get bodyNote =>
      '基礎代謝の計算にだけ使います。ヘルスケアに安静時エネルギーがあればそちらを優先します。この情報は端末の外に送りません。';

  @override
  String get bodyHeight => '身長 (cm)';

  @override
  String get bodyWeight => '体重 (kg)';

  @override
  String get bodyBirthYear => '生まれ年';

  @override
  String get bodySex => '性別';

  @override
  String get bodyMale => '男性';

  @override
  String get bodyFemale => '女性';

  @override
  String bodyBmr(String kcal) {
    return '1日の基礎代謝 約${kcal}kcal（Mifflin-St Jeor式）';
  }

  @override
  String get energySpent => '消費';

  @override
  String energySpentNote(String basal, String exercise) {
    return '基礎 $basal + 運動 $exercise';
  }

  @override
  String get energyDiffFormulaBasal => '食べた分 − 消費';

  @override
  String energyLine(String intake, String used, String diff) {
    return '食べた分 $intake · 消費 $used = ${diff}kcal';
  }

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
  String get agentTelegram => 'Telegram 通知';

  @override
  String get agentTelegramHelp =>
      '決まった時刻のまとめが終わると、ご自身の Telegram に件数だけお知らせします。会員の名前や文面は送りません。';

  @override
  String get agentTelegramConnect => 'Telegram を連携';

  @override
  String get agentTelegramConnected => '連携済み';

  @override
  String get agentTelegramDisconnect => '連携を解除';

  @override
  String get agentTelegramCheck => '連携を確認';

  @override
  String get agentTelegramWaiting =>
      'Telegram で「開始」を押してから戻ってください。リンクは10分以内に1回だけ使えます。';

  @override
  String get agentTelegramCopied => 'リンクをコピーしました。Telegram で開いてください。';

  @override
  String get agentTelegramNotYet => 'まだ連携されていません。Telegram で「開始」を押したか確認してください。';

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
    return 'これも聞く: $text';
  }

  @override
  String get routineAsQuestion => '記録の質問として聞く';

  @override
  String get routineNoConditions => '条件なしですぐ組む';

  @override
  String get routineWithConditions => '条件まで読んで組む';

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
  String anatomyBreakdown(int primary, int secondary) {
    return '28日のうち主に使ったセット $primary · 補助 $secondary(半分で計算)';
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
  String get anatomyZoomReset => '元のサイズ';

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

  @override
  String kcalEstimated(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '約${nString}kcal';
  }

  @override
  String dayBurnedOnlyApprox(String n) {
    return '運動 ${n}kcal(推定)· 食事未記録';
  }

  @override
  String get bodyRecordsTitle => '体組成の記録';

  @override
  String get bodyRecordsEmpty => 'まだ記録がありません';

  @override
  String get bodyRecordsNote => '記録はこの端末にだけ保存します。長押しで削除します。';

  @override
  String get bodyScanNote =>
      'InBody などの結果用紙を撮ると AI が印字された値を読みます。写真は読むときだけ送り、残しません。確認した値だけを端末に保存し、最新の体重を基礎代謝と運動カロリーの推定に使います。長押しで削除します。';

  @override
  String get bodyScanCamera => '撮影する';

  @override
  String get bodyScanLibrary => '写真を選ぶ';

  @override
  String get bodyScanReading => '読み取り中…';

  @override
  String get bodyScanFailed => '読み取れませんでした。数字がはっきり見えるように撮り直してください。';

  @override
  String get bodyReviewTitle => '読み取った値を確認';

  @override
  String get bodyReviewNote => '用紙と違えば直し、分からない欄は空けてください。';

  @override
  String get bodyMeasuredOn => '測定日';

  @override
  String get bodyMuscle => '骨格筋量 (kg)';

  @override
  String get bodyFatKg => '体脂肪量 (kg)';

  @override
  String get bodyFatPercent => '体脂肪率 (%)';

  @override
  String get bodyBmrField => '基礎代謝量 (kcal)';

  @override
  String get bodyVisceral => '内臓脂肪レベル';

  @override
  String get bodyWeightShort => '体重';

  @override
  String get bodyMuscleShort => '骨格筋';

  @override
  String get bodyFatShort => '体脂肪';

  @override
  String get bodyRecordDelete => 'この記録を削除しますか?';

  @override
  String get mealChooseProduct => '別の製品にする ›';

  @override
  String get mealNeedsChoice => 'この名前どおりの製品が表にありません。食べた製品を選んでください。';

  @override
  String get mealAiEstimate => 'AI 推定 — どの食品表にもないため AI が見積もりました';

  @override
  String mealChoiceTitle(String food) {
    return '「$food」— どの製品ですか?';
  }

  @override
  String get bodyGoal => 'トレーニングの目的';

  @override
  String get bodyGoalLose => '減量';

  @override
  String get bodyGoalMaintain => '維持';

  @override
  String get bodyGoalGain => '筋肉を増やす';

  @override
  String bodyTargets(int kcal, int carbs, int protein, int fat) {
    return '1日の目標 ${kcal}kcal · 炭水化物 ${carbs}g · たんぱく質 ${protein}g · 脂質 ${fat}g';
  }

  @override
  String get bodyTargetsNeed => '目的と体重・身長・生まれ年・性別(または体組成の記録)を入れると1日の目標が出ます';

  @override
  String get bodyTargetsNote =>
      '運動しない日の基準で、運動した日はその分を足します。熱量: 基礎代謝 × 1.2 + 運動、減量 −20% · 増量 +10%。たんぱく質: 減量 体重1kgあたり2.2g(除脂肪量が分かれば除脂肪1kgあたり2.6g)、維持1.6g、増量2.0g。脂質: 熱量の25%。炭水化物: 残り。目安であり医学的助言ではありません。';

  @override
  String dayMacros(String carbs, String protein, String fat) {
    return '食べた量: 炭水化物 $carbs · たんぱく質 $protein · 脂質 ${fat}g';
  }

  @override
  String dayMacrosVsTarget(
    String carbs,
    String carbsTarget,
    String protein,
    String proteinTarget,
    String fat,
    String fatTarget,
  ) {
    return '炭 $carbs/$carbsTarget · た $protein/$proteinTarget · 脂 $fat/${fatTarget}g';
  }

  @override
  String dayMacrosGoal(int kcal) {
    return '今日の運動を含む ${kcal}kcal 基準 — 目的は体の情報で変えられます';
  }

  @override
  String dayMacrosMissing(int n) {
    return '三大栄養素が分からない食事 $n 件は含みません';
  }

  @override
  String get partnerRoutinePlanning => 'ルーティンを一緒に作成';

  @override
  String get partnerRoutineReadyTitle => '共有ルーティン';

  @override
  String partnerRoutineProgress(int accepted, int total) {
    return '$accepted/$total人が確認';
  }

  @override
  String get partnerRoutineConfirm => '自分のルーティンを確認';

  @override
  String get partnerRoutineConfirmed => '確認済み';

  @override
  String get partnerRoutineFinalized => '全員が確認しました。自分の記録に追加しました。';

  @override
  String get partnerRoutineChanged => 'ルーティンが変更されました。最新の内容を確認してください。';

  @override
  String get partnerRoutineEmpty => '先に運動を1つ以上追加してください。';

  @override
  String get partnerRoutineStarted => 'ルーティンは確定済みです。';

  @override
  String get workoutImportTitle => '運動記録を読み込む';

  @override
  String get workoutImportHint =>
      'メモを貼り付けるか、テキストファイルと複数の画像を追加してください。確認前には保存されません。';

  @override
  String get workoutImportTextPlaceholder => 'ここに運動記録を貼り付け';

  @override
  String get workoutImportPaste => '貼り付け';

  @override
  String get workoutImportTextFiles => 'テキストファイル';

  @override
  String get workoutImportScreenshots => '画像を追加';

  @override
  String get workoutImportAnalyze => 'プレビューを作成';

  @override
  String get workoutImportEmpty => 'テキストか画像を追加してください。';

  @override
  String get workoutImportFailed => '読み取れませんでした。元データは残っています。もう一度お試しください。';

  @override
  String get workoutImportReview => '日付と運動を確認・編集してから、すべて保存してください。';

  @override
  String get workoutImportMissingDate => '日付を確認';

  @override
  String get workoutImportChooseDate => '日付を選択';

  @override
  String get workoutImportUnparsed => '要確認';

  @override
  String get workoutImportSave => 'すべて保存';

  @override
  String get workoutImportAddExercise => '運動を追加';

  @override
  String get workoutImportAddSet => 'セットを追加';

  @override
  String get workoutImportRemove => '削除';

  @override
  String get workoutImportDuplicate => '似た記録がすでにある可能性があります';

  @override
  String get workoutImportTextLimit => '一度に読み込めるテキストは6,000文字までです。';

  @override
  String get workoutImportEditSources => '入力を編集';

  @override
  String get workoutImportImageLimit => '画像は1回につき最大5枚まで追加できます。';

  @override
  String get workoutImportAiOff => 'AIヘルプがオフなので記録を読み取れません。設定 › AIヘルプ でオンにできます';

  @override
  String workoutImportPartial(int n) {
    return '$n件は読み取れませんでした。元データは残っているので、直してもう一度お試しください。';
  }

  @override
  String get kakao => 'カカオ';

  @override
  String get signInChooseTitle => 'ログイン方法を選んでください';

  @override
  String get signInWithApple => 'Appleで続ける';

  @override
  String get signInWithGoogle => 'Googleで続ける';

  @override
  String get signInWithKakao => 'カカオで始める';

  @override
  String linkSignIn(String method) {
    return '$methodを連携';
  }

  @override
  String get signInTaken => 'このログイン方法はすでに別のアカウントに連携されています。';

  @override
  String get tagOffline => 'ジムに接続できませんでした。電波が入ったらもう一度かざしてください。';

  @override
  String get handoffMine => 'これはあなたが書いて送った記録です。受け取る人の端末で開いてください。';

  @override
  String get partnerErrFull => '満員です。このセッションにはこれ以上参加できません。';

  @override
  String get agentAlarmTitle => '今日のまとめができました';

  @override
  String agentAlarmBody(String gym) {
    return '$gym · エージェントの報告を確認してください';
  }

  @override
  String get agentAlarmChannel => 'エージェント報告';

  @override
  String get agentAlarmChannelDesc => 'トレーナーの報告ができたらお知らせします';

  @override
  String get updateRequired =>
      'このバージョンはサーバーに接続できなくなりました。アプリをアップデートしてください。記録はこの端末に残っています。';

  @override
  String get updateAction => 'アップデート';

  @override
  String get shareGym => 'トレーナーと共有している記録です';

  @override
  String get shareRejected => 'ジムが受け付けなかった記録です · トレーナーに確認してください';

  @override
  String get shareMealsOnly =>
      'トレーナーと共有するのは食事だけです · 運動はジムのステッカーにスマホをかざすと共有されます';

  @override
  String get shareNone => 'トレーナーと共有していない記録です · ジムのステッカーにスマホをかざすと共有されます';

  @override
  String get shareMealsSetting => '食事をトレーナーと共有';

  @override
  String shareMealsNote(String gym) {
    return 'オンにした日から、ジムに行かない日に記録した食事も$gymのトレーナーが見られます。ステッカーにかざした日の記録は、この設定に関係なく共有されます。';
  }

  @override
  String get shareSend => 'トレーナーに送る';

  @override
  String shareSendAsk(String gym) {
    return '今日$gymでした運動としてトレーナーに送りますか？来館としても記録されます。';
  }

  @override
  String get aiBusy => 'いまAIが混み合っています。少し待ってからもう一度お試しください。';

  @override
  String get aiBudgetExhausted =>
      '本日利用できるAIの上限に達しました。Wi-Fiに接続中ならモバイル通信に切り替えてもう一度お試しください。それ以外は明日また使えます。';

  @override
  String get accountSignOutEverywhere => 'すべてのデバイスからログアウト';

  @override
  String get accountSignOutEverywhereAsk =>
      'ほかのスマホやウェブに残っているログインをすべて解除します。このスマホはログインしたままです。';

  @override
  String get accountSignOutEverywhereDone => 'ほかのデバイスのログインをすべて解除しました。';

  @override
  String get accountSignOutEverywhereFailed =>
      'ログインを解除できませんでした。接続を確認してもう一度お試しください。';

  @override
  String get storeUnreachable => 'ストアに接続できませんでした · 再試行';

  @override
  String get ageConfirm => '14歳以上です';

  @override
  String get ageConfirmAsk => 'ジムに登録するには14歳以上である必要があります。14歳以上ですか？';

  @override
  String get gymClasses => 'クラス予約';

  @override
  String get gymLeave => 'このジムを退会';

  @override
  String gymLeaveAsk(String gym) {
    return '$gymを退会しますか？ルーティンが届かなくなり、運動と食事も共有されなくなります。今後のPT・クラス予約はキャンセルされ、これまでの記録と支払い履歴はジムに残ります。';
  }

  @override
  String get gymNotices => 'お知らせ';

  @override
  String passMembershipUntil(String date) {
    return '会員権 $dateまで';
  }

  @override
  String get passMembershipOn => '会員権 利用中';

  @override
  String get passMembershipPaused => '会員権 休止中';

  @override
  String passPtLeft(int n) {
    return 'PT 残り$n回';
  }

  @override
  String get passPtUnlimited => 'PT 回数無制限';

  @override
  String get passPtPaused => 'PT 休止中';

  @override
  String passLocker(String label) {
    return 'ロッカー $label';
  }

  @override
  String passLockerUntil(String label, String date) {
    return 'ロッカー $label（$dateまで）';
  }

  @override
  String get passNone => '利用できる会員権がありません';

  @override
  String get bookingRejected => '拒否';

  @override
  String get bookingCancelled => 'キャンセル';

  @override
  String get bookingPaused => 'PTチケットが休止中です。トレーナーにお問い合わせください。';

  @override
  String newsBooked(String when) {
    return 'PT確定 · $when';
  }

  @override
  String newsRejected(String when) {
    return 'PT申請が拒否されました · $when';
  }

  @override
  String newsCancelled(String when) {
    return 'PTキャンセル · $when';
  }

  @override
  String newsMoved(String when) {
    return 'PT時間変更 · $when';
  }

  @override
  String newsTrainer(String trainer, String when) {
    return 'PT担当変更 · $trainer · $when';
  }

  @override
  String newsAssigned(String trainer) {
    return '担当トレーナー変更 · $trainer';
  }

  @override
  String newsNotice(String title) {
    return 'お知らせ · $title';
  }

  @override
  String newsMore(String news, int n) {
    return '$news ほか$n件';
  }

  @override
  String inviteFrom(String gym) {
    return '$gymから招待が届きました';
  }

  @override
  String inviteBy(String name) {
    return '$nameさんから';
  }

  @override
  String get inviteAccept => '同意して登録';

  @override
  String get inviteGone => 'この招待はもうありません。';

  @override
  String get decline => '拒否';

  @override
  String get gymConsentNotice =>
      '登録すると、このジムのオーナーとトレーナーがあなたのニックネーム、このジムでの運動、記録した食事、予約を見られるようになります。メモ・体組成・会員権・支払いなどジムが自分で記録する情報はジムが管理します。ジムを退会するとその時点から共有されなくなり、これまでの記録と支払い履歴はジムに残ります。';

  @override
  String get joinAsk => 'このジムに登録を申請しますか？';

  @override
  String get joinAgree => '同意して申請';

  @override
  String get classesNone => 'これから2週間のクラスはありません。';

  @override
  String get classesNotMember => 'このジムの会員だけがクラスを見られます。会員登録についてはジムに確認してください。';

  @override
  String get gymUnverified => '未確認のジム';

  @override
  String classBook(int booked, int capacity) {
    return '予約 $booked/$capacity';
  }

  @override
  String classFull(int booked, int capacity) {
    return '満員 $booked/$capacity';
  }

  @override
  String get classMine => '予約済み · キャンセル';

  @override
  String get classCancelled => '休講';

  @override
  String get classCancelAsk => 'このクラスの予約をキャンセルしますか？';

  @override
  String get trainerPtRequests => 'PT申請';

  @override
  String get trainerApprove => '承認';

  @override
  String trainerRejectAsk(String member, String when) {
    return '$memberさんの$whenのPT申請を拒否しますか？';
  }

  @override
  String get trainerApproved => '承認しました';

  @override
  String get trainerRejected => '拒否しました';

  @override
  String trainerPendingCount(int n) {
    return '承認待ち $n';
  }

  @override
  String get nicknameChange => 'ニックネームを変更';

  @override
  String get nicknameHelp => 'ジムに表示される名前です。1〜20文字で入力してください。';

  @override
  String get nicknameTaken => 'そのニックネームは既に使われています。';

  @override
  String get save => '保存';

  @override
  String get gymLinkNotMember => 'このジムの会員だけが開けます。';

  @override
  String get ageConfirmFirst => '先に「14歳以上です」にチェックしてください。';

  @override
  String get noticeNew => '新しいお知らせ';

  @override
  String get noticePinned => '固定';

  @override
  String get refusedSignIn => 'もう一度ログインしてください。';

  @override
  String get refusedGone => 'この予約またはクラスはもうありません。';

  @override
  String get refusedBookingTime => '予約の日付と時間を確認してください。';

  @override
  String get refusedBookingForbidden => 'この予約を変更する権限がありません。';

  @override
  String get refusedNoTrainer => 'まだ担当トレーナーがいません。ジムにお問い合わせください。';

  @override
  String get refusedBookingChanged => 'この予約はすでに処理されたか、変更されています。';

  @override
  String get refusedSlotTaken => 'その時間は受け付けていないか、ほかの予約と重なっています。';

  @override
  String get refusedNoPass => 'PTチケットの状態・期間・残り回数を確認してください。';

  @override
  String get refusedTooLate => 'この予約は開始時刻を過ぎています。';

  @override
  String get refusedClassFull => 'このクラスは満員です。';

  @override
  String get refusedClassNoAccess => 'クラスの日に使える会員権がありません。期間や休止状態をジムに確認してください。';

  @override
  String get refusedClassCancelled => 'このクラスは休講になりました。';

  @override
  String get refusedAccountBlocked =>
      'ジムのオーナーまたはトレーナーです。ジムを抜けるかジムを削除してから、アカウントを削除してください。';

  @override
  String get firstRunHint1 => '種目名を書きます。例: ベンチプレス';

  @override
  String get firstRunHint2 => '次に「80 10」のように重さと回数を書きます';

  @override
  String get firstRunHint3 => '「タバタ」や「60bpm」と書くとタイマーが付きます';

  @override
  String get firstRunClose => 'ヒントを閉じる';

  @override
  String get undo => '元に戻す';

  @override
  String setRemoved(int n) {
    return '$nセット目を消しました';
  }

  @override
  String get setDragHint => 'セットを別のマスにドラッグすると順番が変わります';

  @override
  String get noteRemoved => '記録を削除しました';

  @override
  String get shareSending => 'トレーナーに送信中 · 電波がつながると送られます';

  @override
  String get aiSettingNote =>
      'オンにすると、書いた運動・食事の文、食事の写真、記録への質問をサーバーのAIが読み取ります。オフにするとAIには送られず、書いた文はそのまま残ります。';

  @override
  String get nicknameLabel => 'ニックネーム';

  @override
  String get moreChips => 'もっと見る';

  @override
  String get allExercises => 'すべての記録';

  @override
  String routineWeekdayFactor(String day, String factor) {
    return '$day = $factor';
  }

  @override
  String routineDrift(String planned, String own) {
    return '週間表では$plannedの日ですが、前回のこの曜日は$ownの日でした — そのままだとまた$ownの日になります';
  }

  @override
  String get routineWeekendDetail => '週末 · 今週足りない要素で';

  @override
  String get routineClose => '閉じる';

  @override
  String routineDeviceExcluded(String list) {
    return '除く種目は端末で読みました: $list';
  }

  @override
  String routinePlateCost(String list) {
    return 'プレートを使います(使った分): $list';
  }

  @override
  String routineEstimateNoFirst(int minutes) {
    return '約$minutes分 · 初めての種目を除く';
  }

  @override
  String routineBpmChip(int bpm) {
    return '${bpm}bpmのテンポで';
  }

  @override
  String get routineSwap => '替える';

  @override
  String routineSwapTitle(String name) {
    return '$nameの代わりに — 最近28日にやった同じ部位・器具の種目';
  }

  @override
  String routineFirstPlan(String factor) {
    return '初めてなので週間表($factor)で組みました · 数字は記録しながら埋めます';
  }

  @override
  String routineFirstPlanWeekend(String factor) {
    return '初めてなので今週足りない要素($factor)で組みました · 数字は記録しながら埋めます';
  }

  @override
  String routineDriftKept(String planned) {
    return '週間表では$plannedの日ですが、今週の$plannedはもう済んだので前回のこの曜日のままです';
  }

  @override
  String get routineAskTooName => 'これも聞く';

  @override
  String get routineUnstart => '開始を取り消す';

  @override
  String get routineUnstartAsk => 'この記録には記入済みのセットがあります。記録ごと削除しますか?';

  @override
  String get partnerErrLeft => '一緒に運動していた人が退出しました。';

  @override
  String get partnerErrBusy => 'すでに一緒の運動が開いています。終了してから参加し直してください。';

  @override
  String get partnerEndedGroup => '一緒の運動が終了しました。自分の記録はそのまま残ります。';

  @override
  String get partnerNotYours => '相手が記録したセットは変更できません。その人の記録です。';

  @override
  String get partnerRoutinePlan => 'ルーティンとして確定';

  @override
  String get partnerCodeHint => '相手の画面に表示されている6文字を入力してください。';

  @override
  String partnerPaste(String code) {
    return '貼り付け $code';
  }

  @override
  String get partnerShare => '共有';

  @override
  String partnerShareText(String code) {
    return 'setpad 一緒にやるコード $code\nアプリで記録 → ⋯ → 一緒にやる → 番号を入力';
  }

  @override
  String partnerShareTextLink(String code, String url) {
    return 'setpad 一緒にやるコード $code\nアプリで記録 → ⋯ → 一緒にやる → 番号を入力、またはこのリンクからすぐ参加:\n$url';
  }

  @override
  String get partnerInviteMoreNew => 'もう1人招待 · 新しいコード';

  @override
  String get partnerHomeOpen => '開く';

  @override
  String get togetherInviteSomeone => '一緒にやろうと誘われています';

  @override
  String get timerCollapse => '小さくする';

  @override
  String get timerCollapseA11y => '小さくします。タイマーは動き続けます';

  @override
  String get timerPaused => '一時停止中';

  @override
  String get timerResume => '再開';

  @override
  String get timerRestart => '最初から';

  @override
  String get timerEnd => '終了';

  @override
  String get timerHoldEnd => '長押しで終了';

  @override
  String get timerHoldLeave => '長押しでやめる';

  @override
  String get timerLock => '画面ロック';

  @override
  String get timerUnlock => 'ロック解除';

  @override
  String get timerLockHint => 'ダブルタップでロック';

  @override
  String get timerUnlockHint => 'ダブルタップで解除';

  @override
  String get timerLockedHint => '鍵を2秒長押しで解除';

  @override
  String get timerLockedAnnounce => '画面をロックしました';

  @override
  String get timerUnlockedAnnounce => 'ロックを解除しました';

  @override
  String get timerSkipNext => '次の区間';

  @override
  String get timerSkipBack => '前の区間';

  @override
  String get timerLastRound => '最終ラウンド';

  @override
  String timerRoundShort(int n, int total) {
    return 'R $n/$total';
  }

  @override
  String timerNext(String items) {
    return '次 · $items';
  }

  @override
  String timerLeftTotal(String time) {
    return '全体の残り $time';
  }

  @override
  String timerElapsed(String time) {
    return '経過 $time';
  }

  @override
  String timerAboutLeft(String time) {
    return '残り約 $time';
  }

  @override
  String get timerGo => 'スタート!';

  @override
  String timerTarget(int target) {
    return '/ $target回';
  }

  @override
  String timerBeatLine(String count) {
    return '$count拍目';
  }

  @override
  String timerBeatA11y(int n) {
    return '$n拍目';
  }

  @override
  String timerCountA11y(int count, int target) {
    return '$target回中$count回';
  }

  @override
  String timerRemainingA11y(String time) {
    return 'この区間の残り $time';
  }

  @override
  String get timerHeartShared => '一緒のときは心拍で休憩を切り上げません';

  @override
  String get timerRestLog => 'このラウンドの回数';

  @override
  String timerLogged(int n) {
    return '$n回を記録しました';
  }

  @override
  String get timerDone => '終了!';

  @override
  String get timerStopped => 'ここまでやりました';

  @override
  String timerRoundsDone(int n) {
    return '$nラウンド';
  }

  @override
  String timerRepsDone(int n) {
    return '$n回';
  }

  @override
  String timerRepsOfTarget(int n, int target) {
    return '$n / $target回';
  }

  @override
  String get timerTotal => '合計時間';

  @override
  String get timerTime => '時間';

  @override
  String get timerTempo => 'テンポ';

  @override
  String timerRoundChip(int n, String reps) {
    return 'R$n $reps';
  }

  @override
  String timerRoundCountTitle(int n) {
    return 'ラウンド$nの回数';
  }

  @override
  String timerFillRest(int n) {
    return '残りのラウンドすべて $n回';
  }

  @override
  String get timerClear => 'クリア';

  @override
  String get timerLogSets => 'セットとして記録';

  @override
  String timerLogSetsCount(int n) {
    return '$nセットを記録';
  }

  @override
  String get timerAgain => 'もう一度';

  @override
  String get timerClose => '閉じる';

  @override
  String timerLastRest(int from, int to) {
    return '最後の休憩 ♥ $from → $to';
  }

  @override
  String timerSummaryTabata(int work, int rest, int rounds, String total) {
    return '運動$work秒 · 休憩$rest秒 × $rounds · $total';
  }

  @override
  String timerTargetChip(int n) {
    return '目標$n回';
  }

  @override
  String get timerNoTarget => '目標なし';

  @override
  String get timerOpen => '開く';

  @override
  String timerDoneLine(int rounds, String time) {
    return '完了 · $roundsラウンド · $time';
  }

  @override
  String timerDoneBpmLine(int count, String time) {
    return '完了 · $count回 · $time';
  }

  @override
  String get timerLogNow => '記録';

  @override
  String get timerTogether => '一緒に';

  @override
  String get timerSwitchAsk => '動いているタイマーを止めて、これを開始しますか?';

  @override
  String get timerSwitchConfirm => '止めて開始';

  @override
  String timerUnloggedAsk(int n) {
    return '未記録の$nラウンドがあります';
  }

  @override
  String get timerLogFirst => '先に記録';

  @override
  String get timerDiscardStart => '破棄して開始';

  @override
  String get timerActionFailed => '送信できませんでした · 再試行';

  @override
  String get timerSheetTitle => 'タイマー';

  @override
  String get timerAddChip => '+ タイマー';

  @override
  String get timerTabata => 'タバタ';

  @override
  String get timerBeat => 'メトロノーム';

  @override
  String timerTotalLine(String time) {
    return '合計 $time';
  }

  @override
  String get timerHaptics => '振動';

  @override
  String get timerHapticsSetting => 'タイマーの振動';

  @override
  String get timerReadOnly => '止めてから変更できます';

  @override
  String get timerNameNeeded => '先に名前を入力してください';

  @override
  String get timerWorkTitle => '運動時間';

  @override
  String get timerRestTitle => '休憩時間';

  @override
  String get timerRoundsTitle => 'ラウンド';

  @override
  String get timerBpmTitle => 'テンポ (BPM)';

  @override
  String get timerTargetTitle => '目標回数';

  @override
  String timerSecondsValue(int n) {
    return '$n秒';
  }

  @override
  String get timerMinValue => '最小値です';

  @override
  String get timerMaxValue => '最大値です';

  @override
  String timerUnloggedReps(int n) {
    return '未記録の$n回があります';
  }

  @override
  String get focusOpen => 'ワークアウト画面';

  @override
  String focusExerciseOf(int n, int total) {
    return '種目 $n/$total';
  }

  @override
  String get focusPrevExercise => '前の種目';

  @override
  String get focusNextExerciseA11y => '次の種目';

  @override
  String focusSetLabel(int n) {
    return '$nセット目';
  }

  @override
  String get focusPlanned => '予定';

  @override
  String get focusLastTimeSame => '前回の同じセット';

  @override
  String get focusSameAsLast => '前のセットと同じ';

  @override
  String get focusFromSetup => '設定どおり';

  @override
  String get focusPickValues => '重さと回数を決めます';

  @override
  String get focusPickButton => '重さ・回数を決める';

  @override
  String get focusPlanDone => '予定終了';

  @override
  String focusLastTimeLine(String set) {
    return '前回の同じセット $set';
  }

  @override
  String get focusBodyweight => '自重';

  @override
  String get focusDone => '完了';

  @override
  String get focusNextSetNow => 'すぐ次のセット';

  @override
  String get focusStartRest => '休憩開始';

  @override
  String focusNextUp(String set) {
    return '次 · $set';
  }

  @override
  String focusRestLength(String time) {
    return '休憩 $time';
  }

  @override
  String focusRestPillA11y(String time) {
    return '別の種目の休憩が残り $time';
  }

  @override
  String get focusRestLess => '休憩を15秒減らす';

  @override
  String get focusRestMore => '休憩を15秒増やす';

  @override
  String focusWeightUp(String step) {
    return '$step 増やす';
  }

  @override
  String focusWeightDown(String step) {
    return '$step 減らす';
  }

  @override
  String get focusRepsUp => '1回増やす';

  @override
  String get focusRepsDown => '1回減らす';

  @override
  String get focusTodaySets => '今日のセット';

  @override
  String get focusExerciseDone => 'この種目を終える';

  @override
  String focusNextExercise(String name) {
    return '次の種目: $name';
  }

  @override
  String get focusOneMore => 'もう1セット';

  @override
  String focusSummaryTitle(String name) {
    return '$name 完了!';
  }

  @override
  String get focusSets => 'セット';

  @override
  String get focusVolume => 'ボリューム';

  @override
  String get focusTotalTime => '合計時間';

  @override
  String get focusTotalDistance => '合計距離';

  @override
  String get focusTotalReps => '回数';

  @override
  String get focusBest => '最高';

  @override
  String focusLastTime(String when, String value) {
    return '前回 · $when · $value';
  }

  @override
  String get focusSame => '同じ';

  @override
  String get focusUndo => '元に戻す';

  @override
  String focusLogged(String set) {
    return '$set を記録しました';
  }

  @override
  String get focusHeartBack => '心拍が戻りました · すぐ次のセット';

  @override
  String focusRestPill(String time) {
    return '休憩 $time · 開く';
  }

  @override
  String get focusSharedTimer => '一緒に使うタイマー · 開く';

  @override
  String get focusStartTimer => 'タイマー開始';

  @override
  String focusHeroA11y(String set) {
    return '$set';
  }

  @override
  String focusRestA11y(String time) {
    return '休憩の残り $time';
  }

  @override
  String get focusRestDefault => 'セット間の休憩の既定';

  @override
  String get focusRestTitle => '休憩時間';

  @override
  String get focusWeightTitle => '重さ';

  @override
  String get focusRepsTitle => '回数';

  @override
  String get focusRestOverTitle => '休憩終了';

  @override
  String get focusDistanceTitle => '距離';

  @override
  String get focusPickTime => '時間を決める';

  @override
  String get focusPickDistance => '距離を決める';
}
