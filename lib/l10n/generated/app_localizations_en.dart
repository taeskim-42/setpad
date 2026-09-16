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
    return '$n kcal';
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
  String partnerJoined(String name) {
    return 'Recording with $name';
  }

  @override
  String get partnerFailed => 'That code is wrong or expired.';

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
}
