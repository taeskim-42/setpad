// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class LKo extends L {
  LKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '오늘 운동';

  @override
  String get copy => '복사';

  @override
  String get copied => '복사했습니다';

  @override
  String get howTo => '운동 이름을 치고 Enter → 세트를 치고 Enter → 빈 줄에서 Enter면 다음 운동';

  @override
  String get exerciseNameHint => '운동 이름';

  @override
  String get repeatPrevious => '이전과 같이';

  @override
  String get addSet => '세트 추가';

  @override
  String get numberKeypad => '숫자 키패드';

  @override
  String setOrdinal(int n) {
    return '$n세트';
  }

  @override
  String repsCount(int n) {
    return '$n회';
  }
}
