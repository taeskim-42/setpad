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
  String get howTo => 'Type an exercise, then log your sets.';

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
}
