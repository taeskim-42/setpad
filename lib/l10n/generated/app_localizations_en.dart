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
  String get accountSignIn => 'Sign in and back up';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planLifetime => 'Lifetime';

  @override
  String get planActive => 'Active';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get quotaSpent => 'You have used this month’s questions.';

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
  String get querySourceOnly => 'View original records';

  @override
  String get queryCompareOrder => 'Second period − first period';

  @override
  String queryRankingLimit(int n) {
    return 'Top $n · descending';
  }

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
  String get proTitle => 'Ask your log anything';

  @override
  String get proBody =>
      'Ask things like “heaviest squat” or “is my bench up from last month?” and get answers computed from your own log.';

  @override
  String proFree(int n) {
    return 'Free: $n a month';
  }

  @override
  String proPaid(int n) {
    return 'With a plan: $n a day';
  }

  @override
  String get proEverythingElseFree =>
      'Logging, timers, health sync and gym features all work without a plan.';

  @override
  String get proOwned => 'Active. Thank you.';

  @override
  String get proSignInFirst =>
      'A plan belongs to an account. Please sign in first.';

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
  String get fitAll => 'Fit all';

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
  String get mealAmountInvalid => 'Enter a number of 0 or more.';

  @override
  String dayEnergyFull(int intake, int burned, int diff) {
    final intl.NumberFormat intakeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String intakeString = intakeNumberFormat.format(intake);
    final intl.NumberFormat burnedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnedString = burnedNumberFormat.format(burned);
    final intl.NumberFormat diffNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String diffString = diffNumberFormat.format(diff);

    return 'Logged: intake $intakeString − exercise $burnedString = $diffString kcal';
  }

  @override
  String dayEnergyApprox(int intake, int burned, int diff) {
    final intl.NumberFormat intakeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String intakeString = intakeNumberFormat.format(intake);
    final intl.NumberFormat burnedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnedString = burnedNumberFormat.format(burned);
    final intl.NumberFormat diffNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String diffString = diffNumberFormat.format(diff);

    return 'Logged: intake ≈ $intakeString − exercise $burnedString ≈ $diffString kcal';
  }

  @override
  String get dayBurnedMissing => 'Exercise energy not measured · no difference';

  @override
  String dayBurnedOnly(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Exercise $nString kcal · no meals logged';
  }

  @override
  String get energyExplain =>
      'Logged intake minus exercise energy. Energy used at rest and in daily life is not included.';

  @override
  String weightLabel(String w) {
    return 'Weight $w';
  }

  @override
  String get weightAdd => 'Log weight';

  @override
  String get weightFromHealth => 'Import from Health';

  @override
  String get weightInvalid => 'Check the weight.';

  @override
  String get weightRule =>
      'When you weigh more than once a day, the first reading is used. Days without a reading stay empty.';

  @override
  String get trendsTitle => 'Records and body';

  @override
  String trendDays(int n) {
    return '${n}d';
  }

  @override
  String trendIntakeAvg(int n, int d) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Avg logged intake $nString kcal · $d days';
  }

  @override
  String trendBurnedAvg(int n, int d) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Avg exercise energy $nString kcal · $d days';
  }

  @override
  String trendDiffAvg(int n, int d) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Avg intake − exercise $nString kcal · $d days with both';
  }

  @override
  String trendIncomplete(int d) {
    return '$d days with unknown kcal · left out of averages';
  }

  @override
  String trendWeightChange(String a, String aw, String b, String bw) {
    return 'Measured weight went from $aw on $a to $bw on $b.';
  }

  @override
  String get trendWeightOne =>
      'Weight was measured on one day only. A change needs a reading from another day.';

  @override
  String get trendWeightNone => 'No weight was measured in this period.';

  @override
  String get trendNoData => 'Nothing was logged in this period.';

  @override
  String get intakeLabel => 'Intake';

  @override
  String get burnedLabel => 'Exercise';

  @override
  String get diffLabel => 'Intake − exercise';

  @override
  String get weightMeasured => 'Weight (measured)';

  @override
  String get sourceHealth => 'Health app';

  @override
  String get sourceManual => 'Entered by hand';

  @override
  String get burnedSource =>
      'Active energy your watch measured during the workout';

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
  String get planFromRecord => 'Plan the next workout together from this';

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
}
