// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class LVi extends L {
  LVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Buổi Tập Hôm Nay';

  @override
  String get copy => 'Sao chép';

  @override
  String get copied => 'Đã sao chép';

  @override
  String get howTo =>
      'Nhập tên bài tập rồi Enter → nhập hiệp rồi Enter → Enter ở dòng trống để sang bài kế';

  @override
  String get exerciseNameHint => 'Tên bài tập';

  @override
  String get repeatPrevious => 'Như hiệp trước';

  @override
  String get addSet => 'Thêm Hiệp';

  @override
  String get numberKeypad => 'Bàn Phím Số';

  @override
  String setOrdinal(int n) {
    return 'Hiệp $n';
  }

  @override
  String repsCount(int n) {
    return '$n lần';
  }

  @override
  String get allNotes => '모든 운동';

  @override
  String noteCount(int n) {
    return '$n개의 운동';
  }

  @override
  String get previous7Days => '이전 7일';

  @override
  String get previous30Days => '이전 30일';

  @override
  String monthLabel(int m) {
    return '$m월';
  }

  @override
  String get search => '검색';

  @override
  String get newNote => '새 운동';

  @override
  String get untitledNote => '새 운동';

  @override
  String get noNotesYet => '아직 기록이 없습니다';

  @override
  String get noSearchResults => '찾는 기록이 없습니다';

  @override
  String dayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.yMd(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get finishExercise => '운동 완료';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String deleteExerciseTitle(String name) {
    return '$name 삭제';
  }

  @override
  String deleteExerciseBody(int n) {
    return '$n개 세트가 함께 지워집니다. 되돌릴 수 없습니다.';
  }

  @override
  String get deleteExerciseEmptyBody => '이 운동을 지웁니다.';

  @override
  String get next => '다음';

  @override
  String stepSizeTitle(String unit) {
    return '$unit 단위';
  }

  @override
  String kcal(int n) {
    return '${n}kcal';
  }
}
