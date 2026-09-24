// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Today\'s Workout';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get exerciseNameHint => 'Exercise name';

  @override
  String get repeatPrevious => 'Same as last';

  @override
  String get addSet => 'Add Set';

  @override
  String get numberKeypad => 'Number Keypad';

  @override
  String setOrdinal(int n) {
    return 'Set $n';
  }

  @override
  String repsCount(int n) {
    return '$n reps';
  }

  @override
  String get allNotes => 'All Workouts';

  @override
  String noteCount(int n) {
    return '$n workouts';
  }

  @override
  String get previous7Days => 'Previous 7 Days';

  @override
  String get previous30Days => 'Previous 30 Days';

  @override
  String monthLabel(int m) {
    return '$m';
  }

  @override
  String get search => 'Search';

  @override
  String get newNote => 'New workout';

  @override
  String get untitledNote => 'New workout';

  @override
  String get noNotesYet => 'Nothing logged yet';

  @override
  String get noSearchResults => 'No matching records';

  @override
  String dayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.yMd(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get finishExercise => 'Done';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String deleteExerciseTitle(String name) {
    return 'Delete $name';
  }

  @override
  String deleteExerciseBody(int n) {
    return '$n sets will be deleted. This cannot be undone.';
  }

  @override
  String get deleteExerciseEmptyBody => 'This exercise will be removed.';

  @override
  String get next => 'Next';

  @override
  String stepSizeTitle(String unit) {
    return '$unit step';
  }

  @override
  String kcal(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString kcal';
  }

  @override
  String weekdayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.EEEE(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get noteHint => 'Note for this set';

  @override
  String get activeEnergy => 'Active energy';

  @override
  String get energyUnavailable => 'No data';

  @override
  String get energySource => 'Health · During this entry';

  @override
  String get doneEditing => 'Done';

  @override
  String get setInputHint => 'Weight  Reps';

  @override
  String get setRequired => 'Enter a set first, e.g. 60 12.';

  @override
  String setsPerLineMax(int n) {
    return 'Up to $n sets per line. Split it into more lines.';
  }

  @override
  String get aiTitle => 'One-line setup';

  @override
  String get aiReady => 'Available';

  @override
  String get aiChecking => 'Checking';

  @override
  String get aiSetupNeeded => 'Setup needed';

  @override
  String get aiPreparing => 'Preparing';

  @override
  String get aiUnavailable => 'Manual entry';

  @override
  String get aiReadyBody =>
      'Type “bench 80kg, reach 100 reps” in the exercise field and press Enter. Weight and goals are set automatically. Your text is processed on this device.';

  @override
  String get aiDisabledBody =>
      'Open Settings → Apple Intelligence & Siri and turn on Apple Intelligence. Return after the model is ready; availability is checked again automatically.';

  @override
  String get aiOsBody =>
      'One-line setup needs iOS 26 or later and an Apple Intelligence-compatible device. On a supported device, check Settings → General → Software Update.';

  @override
  String get aiDeviceBody =>
      'This device does not support Apple Intelligence, so one-line setup is unavailable.';

  @override
  String get aiPreparingBody =>
      'The device is preparing its AI model. Connect to Wi-Fi and check again later.';

  @override
  String get aiDownloadBody =>
      'The AI model for one-line setup is available to download. Wi-Fi is recommended; the download needs time and storage. Once ready, your text is processed on this device.';

  @override
  String get aiLanguageBody =>
      'This device’s AI model does not support the app language. Switch to a supported language and check again.';

  @override
  String get aiPlatformBody =>
      'On-device AI is unavailable in this environment. Use the app on a supported iPhone or Android device.';

  @override
  String get aiUnavailableBody =>
      'AI is currently unavailable. Availability depends on the device, OS, and system AI service. If the device was recently set up, connect to the internet and check again later.';

  @override
  String get aiManualBody =>
      'You can still log workouts normally. Choose an exercise, then enter “80 20” or just the reps for each set.';

  @override
  String get aiPrepare => 'Prepare model';

  @override
  String get aiRetry => 'Check again';

  @override
  String get aiWorking => 'Setting up exercise…';

  @override
  String get aiFailure =>
      'Could not interpret this entry. Edit it and try again, or use it as an exercise name.';

  @override
  String get aiUseName => 'Use as exercise name';

  @override
  String get aiFallbackQuota =>
      'You\'ve used today\'s input help, so it was added as typed';

  @override
  String get aiFallbackOffline =>
      'No connection, so it was added as typed. Add a setup from the card\'s ⚙';

  @override
  String get aiFallbackServer =>
      'The server didn\'t answer, so it was added as typed. Add a setup from the card\'s ⚙';

  @override
  String get aiFallbackUnread =>
      'Found nothing to set up, so it was added as typed. Add a setup from the card\'s ⚙';

  @override
  String get inputNameTooLong =>
      'Exercise names are up to 120 characters — split it into lines';

  @override
  String get inputTooLong =>
      'Text over 600 characters isn\'t read — split it into lines';

  @override
  String get setupAdd => 'Add setup';

  @override
  String setupUnparsed(String words) {
    return 'Not moved into the setup: $words — kept in the title';
  }

  @override
  String setupDropped(String numbers) {
    return 'Removed numbers not in your text: $numbers';
  }

  @override
  String get setupNameMissing => 'Enter an exercise name';

  @override
  String get setupNameTooLong => 'Up to 120 characters';

  @override
  String get setupWeightInvalid => 'Enter a number above 0, up to 2000';

  @override
  String get setupCountInvalid =>
      'Enter a whole number of 1 or more — keep ranges and times in the title';

  @override
  String get setupMergeUp => 'Merge into previous';

  @override
  String get setupKeepApart => 'Keep separate';

  @override
  String get setupRepsOnly => 'Reps only';

  @override
  String goalProgress(int done, int goal) {
    return '$done/$goal reps';
  }

  @override
  String repsPerSetLabel(int n) {
    return '$n reps per set';
  }

  @override
  String setProgress(int done, int goal) {
    return '$done/$goal sets';
  }

  @override
  String get repsInputHint => 'Reps';

  @override
  String get setupTitle => 'Exercise setup';

  @override
  String get setupWeight => 'Default weight';

  @override
  String get setupTotalReps => 'Total rep goal';

  @override
  String get setupSetReps => 'Reps per set';

  @override
  String get setupTotalSets => 'Set goal';

  @override
  String get moveExercise => 'Move exercise';

  @override
  String get weightUnitSetting => 'Default weight unit';

  @override
  String get weightUnitHelp =>
      'Used for new exercises. Existing weights and units stay as recorded.';

  @override
  String answerDays(int n) {
    return '$n recorded days';
  }

  @override
  String answerWeeks(int n) {
    return '$n weeks';
  }

  @override
  String answerFrequency(String n) {
    return '$n/week';
  }

  @override
  String answerPeak(String value) {
    return 'Best $value';
  }

  @override
  String answerNoPeak(int n) {
    return 'Best unchanged for $n weeks';
  }

  @override
  String answerSince(String date) {
    return 'Since $date';
  }

  @override
  String answerAgo(int n) {
    return '$n days ago';
  }

  @override
  String answerPerSet(String value) {
    return '$value per set';
  }

  @override
  String answerChange(String weeks, String value) {
    return '$weeks · $value';
  }

  @override
  String answerChart(String name, int n) {
    return '$name · $n recorded days';
  }

  @override
  String answerWeightReps(String value, String reps) {
    return '$value × $reps';
  }

  @override
  String answerSets(int n) {
    return '$n sets';
  }

  @override
  String timingBpm(int n) {
    return '$n BPM';
  }

  @override
  String timingProtocol(int work, int rest, int rounds) {
    return 'Tabata ${work}s / ${rest}s · $rounds rounds';
  }

  @override
  String timingRound(int n, int total) {
    return 'Round $n/$total';
  }

  @override
  String timingRoundDone(int n) {
    return 'Round $n done';
  }

  @override
  String get timingMetronome => 'Metronome';

  @override
  String get timingReady => 'Ready';

  @override
  String get timingWork => 'Work';

  @override
  String get timingRest => 'Rest';

  @override
  String get timingComplete => 'Complete';

  @override
  String get timingStart => 'Start';

  @override
  String get timingPause => 'Pause';

  @override
  String get timingReset => 'Reset';

  @override
  String get timingInvalid =>
      'Use 10–120 BPM, 1–600 s for work and rest, and 1–99 rounds.';

  @override
  String get timingSoundFailed =>
      'Sound is unavailable. The timer is still running.';

  @override
  String get queryTitle => 'Ask your records';

  @override
  String get queryReadyBody =>
      'Ask “What is my squat best?”, “How many push-ups last month?”, or “Has my bench improved this month?”. On-device AI interprets the question; saved records supply the numbers.';

  @override
  String get queryManualBody =>
      'Natural-language questions need on-device AI to be ready. Exercise-name and note searches always work.';

  @override
  String get queryWorking => 'Interpreting your question…';

  @override
  String get queryFailed => 'Could not load the answer. Please try again.';

  @override
  String get queryUnsupported =>
      'Please ask a question about your workout records.';

  @override
  String get queryOffline => 'Questions need a connection.';

  @override
  String get queryNoData =>
      'Completed records or required measurements are missing. Check the original records.';

  @override
  String queryPeriod(String start, String end) {
    return '$start – $end';
  }

  @override
  String get queryAllTime => 'All time';

  @override
  String get queryPresent => 'Present';

  @override
  String get queryRepUnit => 'reps';

  @override
  String get querySetUnit => 'sets';

  @override
  String get queryDayUnit => 'days';

  @override
  String get queryAverage => 'Average weight per set';

  @override
  String get queryMissingData =>
      'The exercise or measurement needed for this question is not in your records.';

  @override
  String get queryAmbiguous =>
      'Please clarify which exercise and record you mean.';

  @override
  String queryRank(int n) {
    return 'Rank $n';
  }

  @override
  String timingWorkSeconds(int n) {
    return 'Work ${n}s';
  }

  @override
  String timingRestSeconds(int n) {
    return 'Rest ${n}s';
  }

  @override
  String timingRounds(int n) {
    return '$n rounds';
  }

  @override
  String timingBeat(String count) {
    return 'Beat $count';
  }

  @override
  String timingHeart(int bpm, int target) {
    return '♥ $bpm → $target';
  }

  @override
  String get accountSignIn => 'Sign in';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planYearly => 'Yearly';

  @override
  String planYearlyTrial(int days, String price) {
    return '$days-day free trial, then $price a year. Cancel at least 24 hours before the trial ends and you won\'t be charged.';
  }

  @override
  String planYearlyTrialPlates(int n) {
    return 'During the free trial, plates are topped up to $n. Monthly top-ups start once billing does.';
  }

  @override
  String get planActive => 'Active';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get subscriptionRenews =>
      'Subscriptions renew automatically at the same price unless canceled at least 24 hours before the current period ends. Cancel anytime in your store\'s subscription settings.';

  @override
  String get termsOfUse => 'Terms of Use (EULA)';

  @override
  String get inputQuotaSpent =>
      'You\'ve used today\'s input help. Typing it in yourself still works.';

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
    return 'From $gym';
  }

  @override
  String get partnerInvite => 'Work out together';

  @override
  String get partnerCode => 'Read this code to your partner';

  @override
  String get partnerEnter => 'Enter a code';

  @override
  String bookingNext(String trainer, String when) {
    return '$trainer · $when';
  }

  @override
  String get bookingNew => 'Book a session';

  @override
  String get bookingNone => 'No open times that day.';

  @override
  String get bookingCancel => 'Cancel booking';

  @override
  String get countAloud => 'Count beats aloud';

  @override
  String get metricMax => 'Best';

  @override
  String get metricTrend => 'Trend';

  @override
  String get metricLast => 'Last';

  @override
  String get metricSessions => 'Days';

  @override
  String get metricVolume => 'Volume';

  @override
  String get metricReps => 'Total reps';

  @override
  String get metricSets => 'Sets';

  @override
  String get metricAverage => 'Average';

  @override
  String get metricE1rm => 'Est. 1RM';

  @override
  String get metricMaxReps => 'Most reps';

  @override
  String get metricLongest => 'Longest';

  @override
  String get metricFirst => 'First';

  @override
  String get metricDaysSince => 'Days since';

  @override
  String get metricDistance => 'Total distance';

  @override
  String get metricDuration => 'Total time';

  @override
  String get readAsConfirm => 'Read as';

  @override
  String get confirmYes => 'Yes';

  @override
  String readAsNote(String from, String to) {
    return '$from → $to';
  }

  @override
  String get reviewNumbers =>
      'Check the numbers and conditions before applying.';

  @override
  String get queryByExercise => 'By exercise';

  @override
  String get queryByDay => 'By day';

  @override
  String get queryByWeek => 'By week (from Monday)';

  @override
  String get queryByMonth => 'By month';

  @override
  String get queryByWeekday => 'By weekday';

  @override
  String get queryTotalSum => 'Total';

  @override
  String get queryTotalMean => 'Average';

  @override
  String queryDiff(String later, String earlier) {
    return 'Difference ($later − $earlier)';
  }

  @override
  String queryExclude(String names) {
    return 'Except $names';
  }

  @override
  String queryMemo(String terms) {
    return 'Memo: $terms';
  }

  @override
  String queryLastSessions(int n) {
    return 'Last $n sessions';
  }

  @override
  String queryBottomLimit(int n) {
    return 'Bottom $n · ascending';
  }

  @override
  String queryOutOfScope(String names) {
    return 'Left out (no values for this measure): $names';
  }

  @override
  String queryMissingFor(String names) {
    return 'Not calculated (sets with missing values): $names';
  }

  @override
  String get queryE1rmRule =>
      'Est. 1RM = weight × (1 + reps ÷ 30), sets of 1–10 reps only';

  @override
  String queryMore(int n) {
    return '$n more';
  }

  @override
  String queryRankingLimit(int n) {
    return 'Top $n · descending';
  }

  @override
  String get queryCompareChip => 'Compare';

  @override
  String get queryNoRecord => 'No records';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsRecording => 'Recording';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsGym => 'Your gym';

  @override
  String get settingsNoGym =>
      'Tap your phone on the gym sticker to get the routine your trainer wrote.';

  @override
  String get proTitle => 'Pro';

  @override
  String get proBody =>
      'Questions about your log use plates — usually about one per question, and only what the answer actually used. Input help for logging workouts and meals doesn\'t use plates.';

  @override
  String proFree(int n, int sets) {
    return 'Free: input help $n times a day · 1 plate on each day you finish $sets sets';
  }

  @override
  String proPaid(int n, int input) {
    return 'Pro: plates topped up to $n every month · input help $input times a day';
  }

  @override
  String get proEverythingElseFree =>
      'Logging, timers, wrist alerts, health sync, working out together and gyms all work without Pro.';

  @override
  String get proOwned => 'Active. Thank you.';

  @override
  String get proSignInFirst =>
      'A plan belongs to an account. Please sign in first.';

  @override
  String platesBalance(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString plates left',
      one: '1 plate left',
    );
    return '$_temp0';
  }

  @override
  String platesSpent(num spent, num balance) {
    final intl.NumberFormat spentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String spentString = spentNumberFormat.format(spent);
    final intl.NumberFormat balanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String balanceString = balanceNumberFormat.format(balance);

    String _temp0 = intl.Intl.pluralLogic(
      spent,
      locale: localeName,
      other: '$spentString plates',
      one: '1 plate',
    );
    return 'Used $_temp0 · $balanceString left';
  }

  @override
  String noPlates(int sets) {
    return 'Not enough plates. You get 1 on each day you finish $sets sets.';
  }

  @override
  String noPlatesSignIn(int n) {
    return 'Sign in · new accounts get $n plates';
  }

  @override
  String platesGetPro(int n) {
    return 'See Pro · $n a month';
  }

  @override
  String get purchaseNotConfirmed =>
      'We couldn\'t confirm the purchase. If you were charged, tap “Restore purchases” in a moment.';

  @override
  String get purchaseOtherAccount =>
      'This purchase is linked to another account. Sign in with that account.';

  @override
  String get tagSignInNeeded => 'Sign in to connect with your gym.';

  @override
  String get tagJoinSent =>
      'Request sent. You can start as soon as a trainer confirms it.';

  @override
  String get tagJoinWaiting => 'Already requested. A trainer is reviewing it.';

  @override
  String get tagJoinFailed =>
      'Could not send the request. Tap the sticker again in a moment.';

  @override
  String get bookingPending => 'Awaiting approval';

  @override
  String get bookingWhichGym => 'Which gym?';

  @override
  String get tagSignIn => 'Sign in';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteAsk =>
      'This cannot be undone. Your routines, workout records, passes and bookings will all be gone.';

  @override
  String get accountDeleteDo => 'Delete';

  @override
  String get accountDeleteFailed =>
      'Could not delete the account. Please try again in a moment.';

  @override
  String get signInFailed => 'Could not sign in. Please try again in a moment.';

  @override
  String get bookingTitle => 'PT booking';

  @override
  String get bookingConfirmed => 'Confirmed';

  @override
  String bookingRemaining(int n) {
    return '$n left';
  }

  @override
  String get bookingNoPass => 'No PT pass. Please ask your trainer.';

  @override
  String bookingNoHours(String trainer) {
    return '$trainer has not opened any hours yet.';
  }

  @override
  String get bookingPick => 'Pick a time';

  @override
  String bookingWith(String trainer, int minutes) {
    return '$trainer · $minutes min';
  }

  @override
  String get bookingSent =>
      'Requested. It is confirmed once your trainer approves.';

  @override
  String get bookingUpcoming => 'Upcoming';

  @override
  String get bookingClosedDay => 'Not available on this day.';

  @override
  String get bookingCancelAsk => 'Cancel this booking?';

  @override
  String get ok => 'OK';

  @override
  String get mealPhoto => 'Meal photo';

  @override
  String get mealCamera => 'Camera';

  @override
  String get mealGallery => 'From library';

  @override
  String get mealEstimating => 'Estimating calories…';

  @override
  String mealIntake(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Intake ≈ $nString kcal';
  }

  @override
  String get mealFailed =>
      'Couldn\'t estimate calories from that photo. Try another.';

  @override
  String get mealEstimateNote => 'Estimated from the photo';

  @override
  String mealServingsOption(String n) {
    return '$n serving(s)';
  }

  @override
  String get fitAll => 'Today\'s workout';

  @override
  String get sameDayOther => 'Other records from this day';

  @override
  String get mealText => 'Write meal';

  @override
  String get mealTextHint => 'What did you eat? e.g. 2 bananas, milk 200ml';

  @override
  String kcalApprox(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '≈ $nString kcal';
  }

  @override
  String get mealKcalUnknown => 'kcal unknown';

  @override
  String mealIntakePartial(int n, int m) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Intake $nString kcal + $m with unknown kcal';
  }

  @override
  String get mealAmountAsk => 'How much did you eat?';

  @override
  String get mealBasis => 'Basis';

  @override
  String get mealEaten => 'Amount eaten';

  @override
  String get mealUnitServing => 'servings';

  @override
  String get mealUnitPackage => 'whole package';

  @override
  String get mealUnitPhoto => 'food in the photo';

  @override
  String get mealWhole => 'All';

  @override
  String get mealHalf => 'Half';

  @override
  String get mealPhotoWholeNote =>
      'This estimates everything visible in the photo. Choose how much of it you ate.';

  @override
  String get mealTextUnknown =>
      'Couldn\'t estimate calories — the food wasn\'t recognized. Tap the meal to add a name or amount and it will be estimated again.';

  @override
  String get mealTextOffline =>
      'Couldn\'t estimate calories — no connection. Tap the meal and press Enter to estimate again.';

  @override
  String get mealTextTooLong =>
      'Meal notes over 500 characters aren\'t estimated. Tap the meal and split it up to get an estimate.';

  @override
  String queryTooLong(int max) {
    return 'Questions can be up to $max characters. Please shorten it.';
  }

  @override
  String get queryPressEnter => 'Press Enter to ask about your records.';

  @override
  String get mealRetry => 'Estimate again';

  @override
  String kcalAtLeast(int n) {
    return '≥ $n kcal';
  }

  @override
  String mealTextPartial(int n) {
    return 'Only the $n kcal you wrote is counted; the other foods\' calories are unknown.';
  }

  @override
  String mealTextBelowTyped(int n) {
    return 'The estimate came out below the $n kcal you wrote, so it wasn\'t used. Only your $n kcal is counted.';
  }

  @override
  String queryLimit(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'exercises':
          'Up to 8 exercises can be asked at once. Try asking in parts.',
      'measures': 'Up to 4 things can be counted at once. Try asking in parts.',
      'ranking': 'Rankings show up to 20. Ask for 20 or fewer.',
      'sessions':
          '\'Last N sessions\' goes up to 100. For longer, ask by period, e.g. this year.',
      'days':
          '\'Last N days\' goes up to 3660 days (about 10 years). For longer, ask about all time.',
      'compare': 'Up to 6 things can be compared at once. Try asking in parts.',
      'compareGrouped':
          'A comparison can\'t also be grouped by exercise, day, week, month or weekday in one question. Ask for one or the other.',
      'groupedMeasure':
          'Comparing several ranges grouped by day, week, month or weekday counts only one thing, and trend, last, first and days-since can\'t be grouped.',
      'ordering':
          'Rankings, totals and averages need a grouping, such as by exercise or by week.',
      'datesTotal': 'Last and first dates can\'t be added up or averaged.',
      'perMeasure':
          'Per-day, per-week and per-month averages work only for amounts that add up, such as sets, reps, volume, distance, time, days and kcal. Ask about the best or average weight over a period instead.',
      'shareMeasure':
          'A share can only be taken of amounts that add up, such as sets or volume.',
      'trainedMeasure':
          'Picking training or rest days only applies to kcal eaten and burned. Workout records all come from training days.',
      'sameSeries':
          'The two sides of the comparison were read as the same. Say what to compare with what.',
      'other':
          'Record search can\'t compute a question shaped like this. Try asking in parts.',
    });
    return '$_temp0';
  }

  @override
  String policyNumberRejected(String text, String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'decimal':
          '\'$text\' — decimals aren\'t accepted. Enter a whole number, e.g. 14',
      'range': '\'$text\' — enter one number, not a range, e.g. 14',
      'negative': '\'$text\' — numbers below 0 aren\'t accepted, e.g. 14',
      'unit':
          '\'$text\' — this field counts days or sessions. Convert hours, weeks or months to days, e.g. 14',
      'many': '\'$text\' — enter just one number, e.g. 14',
      'other':
          'Couldn\'t read a number of days or sessions from \'$text\'. Enter a number, e.g. 14',
    });
    return '$_temp0';
  }

  @override
  String get mealSources => 'Source';

  @override
  String get mealSourcesTitle => 'Where the calories come from';

  @override
  String get mealSourcesNote =>
      'Calculated from the table values below. Tap one to open that name in the original table. Foods not in the table were estimated by AI.';

  @override
  String mealSourcePer(String unit, String kcal) {
    return '$kcal kcal per 100 $unit';
  }

  @override
  String get mealSourceMfds => 'Korea MFDS food composition database';

  @override
  String get mealSourceUsda => 'USDA FoodData Central';

  @override
  String get mealAmountInvalid => 'Enter a number of 0 or more.';

  @override
  String dayEnergyFull(String intake, String burned, String diff) {
    return 'Intake $intake · exercise $burned = $diff kcal';
  }

  @override
  String dayEnergyApprox(String intake, String burned, String diff) {
    return 'Intake ≈ $intake · exercise $burned ≈ $diff kcal';
  }

  @override
  String get dayBurnedMissing => 'Exercise energy not measured · no difference';

  @override
  String dayBurnedOnly(String n) {
    return 'Exercise $n kcal · no meals logged';
  }

  @override
  String get intakeLabel => 'Intake';

  @override
  String get partnerSignIn => 'Sign in to work out together.';

  @override
  String get partnerSignInAction => 'Sign in';

  @override
  String get partnerMakeCode => 'Create a code';

  @override
  String get partnerCopy => 'Copy';

  @override
  String partnerExpiresIn(String t) {
    return 'Expires in $t';
  }

  @override
  String get partnerExpired => 'The code has expired.';

  @override
  String get partnerNewCode => 'New code';

  @override
  String get partnerStopWaiting => 'Stop';

  @override
  String partnerWith(String name) {
    return 'Working out with $name';
  }

  @override
  String get partnerReconnecting => 'Reconnecting · your record keeps saving';

  @override
  String partnerTheirRecord(String name) {
    return '$name\'s record';
  }

  @override
  String get partnerNoRecordYet => 'Nothing logged yet.';

  @override
  String get partnerLoading => 'Loading…';

  @override
  String get partnerEnd => 'Stop working out together';

  @override
  String get partnerEndedByMe =>
      'You stopped working out together. Your record is kept.';

  @override
  String partnerEndedByThem(String name) {
    return '$name stopped working out together. Your record is kept.';
  }

  @override
  String get partnerErrFormat => 'A code has six characters. Check it again.';

  @override
  String get partnerErrInvalid =>
      'No such code. It may already be used or mistyped.';

  @override
  String get partnerErrExpired => 'That code has expired. Ask for a new one.';

  @override
  String get partnerErrEnded => 'That invite has already ended.';

  @override
  String get partnerErrOwn =>
      'That is your own code. Enter it on the other phone.';

  @override
  String get partnerErrTries => 'Too many tries. Please try again later.';

  @override
  String get partnerErrNetwork =>
      'Could not reach the server. Check your connection and try again.';

  @override
  String get partnerErrServer =>
      'The server had a problem. Please try again shortly.';

  @override
  String get partnerRetry => 'Try again';

  @override
  String get partnerReadOnly => 'read only';

  @override
  String get partnerConflict =>
      'Another of your devices shared a newer record. This device\'s record is safe; only sharing is paused.';

  @override
  String get partnerShareThisDevice => 'Share this device\'s record';

  @override
  String get plansTitle => 'Shared plans';

  @override
  String get planNew => 'New shared plan';

  @override
  String get planJoin => 'Join with a code';

  @override
  String get planHint =>
      'First line is the title, then one exercise per line\ne.g. Squat 4 sets';

  @override
  String get planDateNone => 'No date yet';

  @override
  String planSetsCount(int n) {
    return '$n sets';
  }

  @override
  String get planSave => 'Propose';

  @override
  String get planStateLocal =>
      'Draft on this device only · not on the server yet';

  @override
  String get planStateDraft => 'Draft · no partner yet';

  @override
  String planStateWaiting(int v) {
    return 'Waiting for your partner · version $v';
  }

  @override
  String planStateNeedsMe(String name, int v) {
    return '$name changed it · version $v needs your OK';
  }

  @override
  String planStateAgreed(int v) {
    return 'Agreed · version $v';
  }

  @override
  String get planStateWithdrawn =>
      'Shared planning ended · the agreed plan and your targets are kept';

  @override
  String planAccept(int v) {
    return 'Accept version $v';
  }

  @override
  String get planChanged => 'Changed since the last agreed plan';

  @override
  String planAdded(String x) {
    return 'Added: $x';
  }

  @override
  String planRemoved(String x) {
    return 'Removed: $x';
  }

  @override
  String planSetsChanged(String x) {
    return 'Sets changed: $x';
  }

  @override
  String get planReordered => 'The order changed';

  @override
  String get planDateChanged => 'The date changed';

  @override
  String get planTitleChanged => 'The title changed';

  @override
  String planLastAgreed(int v) {
    return 'Last agreed plan · version $v';
  }

  @override
  String get planConflict =>
      'Your partner changed it first. Your draft is still here.';

  @override
  String planLatest(int v) {
    return 'Your partner\'s latest plan · version $v';
  }

  @override
  String get planKeepMine => 'Propose my draft again';

  @override
  String get planTakeLatest => 'Use the latest plan';

  @override
  String get planMyTarget => 'My target';

  @override
  String planPartnerTarget(String name, String t) {
    return '$name: $t';
  }

  @override
  String get planTargetHint => 'e.g. 100 5 or 100kg 5 reps x3 note';

  @override
  String get planInvite => 'Create an invite code';

  @override
  String get planStart => 'Start this plan';

  @override
  String get planStartSolo => 'Start my own copy';

  @override
  String get planStartSoloNote =>
      'Not agreed yet. Starting now uses your own copy, not an agreed plan.';

  @override
  String get planOpenWorkout => 'Open the workout';

  @override
  String get planCopyNext => 'Copy to the next workout';

  @override
  String get planWithdraw => 'Leave this shared plan';

  @override
  String get planCompare => 'Plan and actual';

  @override
  String planDoneSets(String name, int planned, int done) {
    return '$name · planned $planned · done $done';
  }

  @override
  String planAddedActual(String x) {
    return 'Not in the plan: $x';
  }

  @override
  String planSkipped(String x) {
    return 'Skipped: $x';
  }

  @override
  String planStartedFrom(int v) {
    return 'Started from the agreed shared plan (version $v)';
  }

  @override
  String planStartedSolo(int v) {
    return 'Started from your own copy (version $v, not agreed)';
  }

  @override
  String get planShareLink => 'Send an invite link';

  @override
  String planShareText(String url) {
    return 'Let\'s plan our workout together in setpad: $url';
  }

  @override
  String get planLinkCopied => 'Link copied. It works once, for one day.';

  @override
  String get planLinkJoining => 'Joining the plan you were invited to…';

  @override
  String get nearbyHint =>
      'Between iPhones, you can also connect by holding the two phones close with this screen open.';

  @override
  String get planPropose => 'Propose plan';

  @override
  String get togetherStart => 'Start together';

  @override
  String get togetherAlternate => 'Take turns';

  @override
  String togetherWaiting(String name) {
    return 'Waiting for $name…';
  }

  @override
  String get togetherWaitingHint =>
      'A request shows on your partner\'s screen. If it doesn\'t, check that their app is up to date.';

  @override
  String togetherInvite(String name) {
    return '$name wants to do this together';
  }

  @override
  String get togetherInviteAlternate => 'Taking turns · partner goes first';

  @override
  String get togetherLeave => 'Stop';

  @override
  String get togetherRejoin => 'Rejoin';

  @override
  String togetherWith(String name) {
    return 'Together with $name';
  }

  @override
  String get togetherTheirTurn => 'Partner\'s turn';

  @override
  String togetherLeftBeat(String name, int n) {
    return '$name stopped at beat $n';
  }

  @override
  String togetherLeftRound(String name, int n) {
    return '$name stopped in round $n';
  }

  @override
  String get togetherMe => 'Me';

  @override
  String get togetherLog => 'Log';

  @override
  String get mealLogAs => 'Log as meal';

  @override
  String get mealAutoLogged => 'Logged as a meal';

  @override
  String get mealAutoUndo => 'Make it exercise';

  @override
  String get proxyWrite => 'Log for them';

  @override
  String proxyWriting(String name) {
    return 'Logging $name\'s workout';
  }

  @override
  String get proxyDefaultName => 'Partner';

  @override
  String get proxyHand => 'Hand over';

  @override
  String get proxyBack => 'Back to mine';

  @override
  String proxyShareText(String url) {
    return 'A workout logged for you while we trained. Open it in setpad to add it to your log.\n$url';
  }

  @override
  String handoffOffer(String name) {
    return '$name logged your workout for you';
  }

  @override
  String get handoffTake => 'Take it';

  @override
  String get handoffFailed =>
      'Couldn\'t get the record. The link may have expired, or the network is down.';

  @override
  String get handoffSignIn =>
      'Sign in to take a record that was handed to you.';

  @override
  String partnerInviteMore(String code) {
    return 'Invite one more · code $code';
  }

  @override
  String get proxyWhose => 'Whose workout are you logging?';

  @override
  String planMemberAccepted(String name) {
    return '$name agreed';
  }

  @override
  String planMemberWaiting(String name) {
    return '$name has not confirmed yet';
  }

  @override
  String deleteNoteAsk(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get mealsTitle => 'Meals';

  @override
  String get recordMenu => 'More';

  @override
  String dayIntakeOnly(String intake) {
    return 'Intake $intake kcal · exercise energy not measured';
  }

  @override
  String dayIntakeOnlyApprox(String intake) {
    return 'Intake ≈ $intake kcal · exercise energy not measured';
  }

  @override
  String dayUnknownMeals(int m) {
    return '$m with unknown kcal';
  }

  @override
  String get healthDataTitle => 'Health data';

  @override
  String get healthDataIntro =>
      'What setpad exchanges with your health app (Apple Health, Health Connect), and why.';

  @override
  String get healthDataWrite =>
      'Write · Workouts — when you finish a record, it is saved as a workout session.';

  @override
  String get healthDataCalories =>
      'Read · Active calories — the active calories your watch measured during the workout are added to that record. If nothing was measured, no calories are shown.';

  @override
  String get healthDataHeart =>
      'Read · Heart rate — during a Tabata rest, once your heart rate is 25 bpm below that round\'s peak, the rest ends and the next round is signalled. While resting, the timer line shows ♥ now → target. With no heart rate, or a reading older than 90 seconds, the rest ends on time.';

  @override
  String get healthDataStays =>
      'What is read from your health app never leaves this device. It is not sent to a server and is not used for ads or marketing.';

  @override
  String get healthDataRevokeIos =>
      'You can turn these off at any time in iPhone Settings → Privacy & Security → Health → setpad.';

  @override
  String get healthDataRevokeAndroid =>
      'You can turn these off at any time in Health Connect → App permissions → setpad.';

  @override
  String get healthDataPrivacy => 'Privacy policy';

  @override
  String get restAlarmTitle => 'Next round — your heart rate is down';

  @override
  String liveSetBusy(String name) {
    return '$name is editing this set. Tap it again when they are done.';
  }

  @override
  String liveExerciseBusy(String name) {
    return '$name is writing in this exercise right now.';
  }

  @override
  String liveExerciseRemoved(String exercise) {
    return 'Someone in your session removed $exercise. What you were typing is still in the input line.';
  }

  @override
  String get trainerReport => 'Trainer report';

  @override
  String get trainerUnread => 'New report';

  @override
  String trainerRanAt(String when) {
    return 'Prepared $when';
  }

  @override
  String get trainerRunNow => 'Prepare now';

  @override
  String get trainerNoReport => 'No report yet. Prepare one now?';

  @override
  String get trainerOutdated =>
      'This report needs a newer version. Please update the app.';

  @override
  String get trainerFailed =>
      'Couldn\'t reach the server. Please try again shortly.';

  @override
  String get trainerActUnknown =>
      'Couldn\'t confirm the result. Tapping again won\'t record it twice.';

  @override
  String get trainerDone => 'Done by the agent';

  @override
  String get trainerToday => 'Today\'s sessions';

  @override
  String get trainerTodo => 'To check';

  @override
  String get trainerAllClear => 'Everything to check is done.';

  @override
  String get trainerAttendance => 'Sessions to wrap up';

  @override
  String trainerVisited(String time) {
    return 'Checked in $time';
  }

  @override
  String trainerFinishAll(int count) {
    return 'Complete all ($count)';
  }

  @override
  String trainerFinishAsk(int count) {
    return 'Complete $count — one session is deducted from the PT pass for each.';
  }

  @override
  String get trainerFinish => 'Complete';

  @override
  String get trainerJoinRequest =>
      'Membership request — review it on the Today screen of the web CRM.';

  @override
  String get trainerBook => 'Book';

  @override
  String get trainerSend => 'Send';

  @override
  String get trainerPaid => 'Payment received';

  @override
  String get trainerContacted => 'Contacted';

  @override
  String get trainerLater => 'Later';

  @override
  String trainerPrice(int price) {
    final intl.NumberFormat priceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String priceString = priceNumberFormat.format(price);

    return '₩$priceString';
  }

  @override
  String trainerStarts(String d) {
    return 'From $d';
  }

  @override
  String get trainerPayHow => 'How was it paid?';

  @override
  String get trainerPaidListPrice =>
      'The full list price is recorded as paid. For a discount or split payment, register it on the member\'s Membership tab in the web CRM.';

  @override
  String get payCard => 'Card';

  @override
  String get payCash => 'Cash';

  @override
  String get payTransfer => 'Bank transfer';

  @override
  String get payOther => 'Other';

  @override
  String get agentSettings => 'Agent settings';

  @override
  String get agentEnabled => 'Prepare at set times';

  @override
  String get agentTimes => 'Report times';

  @override
  String get agentAddTime => 'Add a time';

  @override
  String get agentDays => 'Days';

  @override
  String get agentAutoConfirm => 'Confirm PT requests right away';

  @override
  String get agentModes => 'Per task';

  @override
  String get agentModesHelp =>
      'Manual — the agent leaves it alone. Draft — the agent prepares it and you finish it with a tap. Auto — the agent does it.';

  @override
  String get agentModeOff => 'Manual';

  @override
  String get agentModeDraft => 'Draft';

  @override
  String get agentModeAuto => 'Auto';

  @override
  String get taskPtSchedule => 'PT schedule';

  @override
  String get taskRenewal => 'Renewals';

  @override
  String get taskAttendance => 'Attendance';

  @override
  String get taskRoutine => 'Routines';

  @override
  String get taskContact => 'Member contact';

  @override
  String get gymPolicy => 'Gym policy';

  @override
  String get policyRenewalDays => 'Renewal notice timing (days before expiry)';

  @override
  String get policyLowSessions => 'Low PT threshold (PT sessions bookable)';

  @override
  String get policyAwayDays => 'Away after (days)';

  @override
  String get policyLapsedDays => 'Lapsed after (days)';

  @override
  String get policyOffer => 'Renewal offer text';

  @override
  String get policySave => 'Save policy';

  @override
  String get policySaved => 'Saved.';

  @override
  String get trainerWhichGym => 'Which gym?';

  @override
  String get trainerBack => 'Go back';

  @override
  String get trainerCopy => 'Copy message';

  @override
  String get trainerCopied => 'Copied';

  @override
  String get settingsTrainer => 'Trainer';

  @override
  String get answerNeedsTwoDays => 'Needs at least two days';

  @override
  String get answerNoBase => 'No baseline value';

  @override
  String answerPerWeek(String value) {
    return '$value per week';
  }

  @override
  String answerPerMonth(String value) {
    return '$value per month';
  }

  @override
  String answerTimesAfter(int n) {
    return '$n sessions since the best';
  }

  @override
  String get answerTimesUnit => ' times';

  @override
  String answerTimes(int n) {
    return '$n times';
  }

  @override
  String answerStreak(int n) {
    return '$n days in a row';
  }

  @override
  String answerRestDays(int n) {
    return '$n days off';
  }

  @override
  String get answerUntilToday => 'today';

  @override
  String answerEveryDays(String value) {
    return 'Usually every $value days';
  }

  @override
  String answerMeanEvery(String value) {
    return 'On average every $value days';
  }

  @override
  String answerGapSpread(int a, int b, int c, int d) {
    return 'Back to back $a · after 1 rest day $b · after 2 $c · after 3+ $d';
  }

  @override
  String answerLongestIncluded(int n) {
    return 'Includes a $n-day break';
  }

  @override
  String get answerNoMeals => 'No days with meals logged';

  @override
  String answerAbout(String value) {
    return 'about $value';
  }

  @override
  String answerMealDays(int n) {
    return '$n days with meals';
  }

  @override
  String queryUnknownMeals(int n) {
    return '$n meals with unknown calories aren\'t in the total';
  }

  @override
  String get answerNoWatch => 'No watch-measured workouts';

  @override
  String answerWatchDays(int n) {
    return '$n days measured by watch';
  }

  @override
  String get answerNoBoth => 'No days with both meals and watch calories';

  @override
  String answerBothDays(int n) {
    return '$n days with both intake and burn';
  }

  @override
  String answerIntakeOnlyDays(int n) {
    return 'Left out $n days with meals only';
  }

  @override
  String answerMonths(int n) {
    return '$n months';
  }

  @override
  String get metricChangePct => 'Change %';

  @override
  String get metricDaysSinceBest => 'Days since best';

  @override
  String get metricSessionsSinceBest => 'Sessions since best';

  @override
  String get metricMeanReps => 'Reps per set';

  @override
  String get metricLongestStreak => 'Longest streak';

  @override
  String get metricLongestGap => 'Longest break';

  @override
  String get metricMeanGap => 'Days between workouts';

  @override
  String get metricIntake => 'Calories eaten';

  @override
  String get metricBurned => 'Calories burned';

  @override
  String get metricBalance => 'Eaten − burned';

  @override
  String get queryAlone => 'Alone';

  @override
  String get queryTogether => 'With a partner';

  @override
  String get queryByPart => 'By body part';

  @override
  String get queryCanSee =>
      'Your log can show weights, reps, sets, training days and meal calories';

  @override
  String get queryDiffColumn => 'Difference';

  @override
  String get queryFutureCell => 'Not here yet';

  @override
  String get queryGrowthRate =>
      'Growth is ranked by weekly rate, so different spans compare fairly';

  @override
  String get queryHandoff => 'Handed-over records only';

  @override
  String get queryNoHandoff => 'Without handed-over records';

  @override
  String queryHandoffCount(int n) {
    return '$n handed-over records left out';
  }

  @override
  String get queryHoursNote =>
      'Times are when each record was created; records written later count at that time';

  @override
  String get queryMixedWeights => 'These weights mix several exercises';

  @override
  String get queryNcBodyweight =>
      'Bodyweight isn\'t in your log. Put it in the question and it\'s compared (e.g. I weigh 80, how many times is my deadlift?)';

  @override
  String get queryNcHeartRate =>
      'Record search doesn\'t look at heart rate yet; per exercise or per rest it can\'t, since sets have no times';

  @override
  String get queryNeverMark => 'Never logged';

  @override
  String get queryNoBaseRatio => 'No baseline value, so no ratio';

  @override
  String get queryNoneCell => 'No records in this range';

  @override
  String get queryNoRoutine => 'Without a routine';

  @override
  String get queryRoutine => 'With a trainer routine';

  @override
  String get queryOngoing => 'in progress';

  @override
  String get queryOverlap =>
      'Training days overlap, so no share; ask with set counts';

  @override
  String queryPart(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'chest': 'Chest',
      'back': 'Back',
      'legs': 'Legs',
      'shoulders': 'Shoulders',
      'arms': 'Arms',
      'core': 'Core',
      'cardio': 'Cardio',
      'upper': 'Upper body',
      'lower': 'Lower body',
      'other': 'Body part',
    });
    return '$_temp0';
  }

  @override
  String get queryRatioColumn => 'Ratio';

  @override
  String get queryRatioUnits => 'Different units, so no ratio';

  @override
  String get queryRestDay => 'Rest days';

  @override
  String get queryTrained => 'Training days';

  @override
  String get querySetFirst => 'First set';

  @override
  String get querySetLast => 'Last set';

  @override
  String get queryShare => 'Share';

  @override
  String get queryZeroFilled => 'Exercises you didn\'t do are counted as 0';

  @override
  String queryAgainst(String value) {
    return 'vs $value';
  }

  @override
  String queryAgainstLine(
    String value,
    String target,
    String ratio,
    String diff,
  ) {
    return '$value ÷ $target = $ratio× · difference $diff';
  }

  @override
  String queryAlias(String name, String names) {
    return '$name = $names';
  }

  @override
  String queryDayCount(int n) {
    return '$n days';
  }

  @override
  String queryDroppedSets(int n) {
    return '$n sets with other values left out';
  }

  @override
  String queryHours(int from, int to) {
    return '$from:00–$to:00';
  }

  @override
  String queryMaybe(String name) {
    return 'Did you mean $name?';
  }

  @override
  String queryMemoAll(String terms) {
    return 'Memo has all: $terms';
  }

  @override
  String queryMemoHit(String text, int n) {
    return '$text ($n days)';
  }

  @override
  String queryMemoHits(String hits) {
    return 'Matching memos: $hits';
  }

  @override
  String queryNeverPartial(String names) {
    return '$names: never logged, counted without them';
  }

  @override
  String queryNeverRows(String names) {
    return '$names: never logged';
  }

  @override
  String queryNoMemo(String terms) {
    return 'Memo without: $terms';
  }

  @override
  String queryNoRepsSets(int n) {
    return '$n sets without reps left out';
  }

  @override
  String queryNotComputable(String things) {
    return 'Not in your log, so not shown: $things';
  }

  @override
  String queryNotComputableTail(String things) {
    return 'Can\'t see: $things';
  }

  @override
  String queryNothingComputable(String things) {
    return 'Your log can\'t answer this: $things';
  }

  @override
  String queryNoWeightSets(int n, int reps) {
    return '$n sets without weight left out (up to $reps reps)';
  }

  @override
  String queryNth(int n) {
    return 'Training day $n from the end';
  }

  @override
  String queryOtherDistance(int n, String value) {
    return '$n sets with distance: $value';
  }

  @override
  String queryOtherDuration(int n, String value) {
    return '$n sets with time: $value';
  }

  @override
  String queryPartial(String names) {
    return 'without $names';
  }

  @override
  String queryPartialChunk(int n) {
    return '($n days)';
  }

  @override
  String queryPartMembers(String part, String names) {
    return '$part: $names';
  }

  @override
  String queryPer(String per) {
    String _temp0 = intl.Intl.selectLogic(per, {
      'day': 'per day',
      'week': 'per week',
      'month': 'per month',
      'other': 'average',
    });
    return '$_temp0';
  }

  @override
  String queryPerSuffix(String per) {
    String _temp0 = intl.Intl.selectLogic(per, {
      'day': '/day',
      'week': '/wk',
      'month': '/mo',
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
    return '$a ÷ $b = $value× ($percent%)';
  }

  @override
  String queryRelative(String by, int n) {
    String _temp0 = intl.Intl.selectLogic(by, {
      'day': 'Day $n',
      'week': 'Week $n',
      'month': 'Month $n',
      'other': 'No. $n',
    });
    return '$_temp0';
  }

  @override
  String queryRolled(String year) {
    return 'Not here yet, so read as $year';
  }

  @override
  String querySamePeriod(int days, String earlier, String later) {
    return 'Same $days days: $earlier → $later';
  }

  @override
  String queryShortGrowth(String names) {
    return 'Too short to rank (under 3 days or 3 weeks): $names';
  }

  @override
  String queryTimer(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tabata': 'Tabata',
      'bpm': 'BPM timer',
      'other': 'No timer',
    });
    return '$_temp0';
  }

  @override
  String queryUnknownPart(String names) {
    return 'Left out exercises with no known body part: $names';
  }

  @override
  String queryUnranked(int n, String names) {
    return '$n left out of the ranking for missing values: $names';
  }

  @override
  String queryWindowLengths(String lengths) {
    return 'The periods differ in length ($lengths days), so differences and ratios are per week';
  }

  @override
  String queryZeroBuckets(String by, int total, int zeros) {
    String _temp0 = intl.Intl.selectLogic(by, {
      'week': '$zeros of $total weeks at 0',
      'month': '$zeros of $total months at 0',
      'other': '$zeros of $total at 0',
    });
    return '$_temp0';
  }

  @override
  String queryPossibleDays(int m, String percent) {
    return '$percent% of $m possible days';
  }

  @override
  String get queryOfflineLocal =>
      'Couldn\'t reach the server, so this was counted on your device from the exercises and dates in your text. Press Enter to ask again once you\'re online.';

  @override
  String get queryMisread =>
      'This question couldn\'t be read into something to count. Try rephrasing it.';

  @override
  String get queryMisreadLocal =>
      'The question couldn\'t be read into something to count, so this was counted on your device from the exercises and period in your text only. Rephrase it to ask again.';

  @override
  String get queryUnreadable =>
      'The model sent an unreadable answer twice. It isn\'t your connection, and no plates were spent on that answer.';

  @override
  String get queryAskAgain => 'Ask again';

  @override
  String get queryUnreadablePaid =>
      'The model sent an unreadable answer twice. It isn\'t your connection. That answer spent no plates; the plates below went to the first step, which sorted your question.';

  @override
  String get queryUnreadableLocal =>
      'Meanwhile, the exercises and period in your text were counted on your device.';

  @override
  String get queryTotalUnits => 'Units differ, so there\'s no total';

  @override
  String queryMemoDropped(String words) {
    return 'Memo condition left out: $words';
  }

  @override
  String queryAgainstDropped(String value) {
    return 'Reference number $value left out — it isn\'t a weight written in the question';
  }

  @override
  String queryBoundDropped(String value) {
    return 'Dropped the condition $value — the question doesn\'t state that number in that unit';
  }
}
