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
  String get allNotes => 'Tất cả bản ghi';

  @override
  String noteCount(int n) {
    return '$n bản ghi';
  }

  @override
  String get previous7Days => '7 ngày qua';

  @override
  String get previous30Days => '30 ngày qua';

  @override
  String monthLabel(int m) {
    return 'Tháng $m';
  }

  @override
  String get search => 'Tìm kiếm';

  @override
  String get newNote => 'Bản ghi mới';

  @override
  String get untitledNote => 'Bản ghi mới';

  @override
  String get noNotesYet => 'Chưa có bản ghi nào';

  @override
  String get noSearchResults => 'Không có kết quả';

  @override
  String dayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.yMd(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get finishExercise => 'Xong';

  @override
  String get cancel => 'Huỷ';

  @override
  String get delete => 'Xoá';

  @override
  String deleteExerciseTitle(String name) {
    return 'Xoá $name';
  }

  @override
  String deleteExerciseBody(int n) {
    return '$n hiệp cũng sẽ bị xoá. Không thể hoàn tác.';
  }

  @override
  String get deleteExerciseEmptyBody => 'Bài tập này sẽ bị xoá.';

  @override
  String get next => 'Tiếp';

  @override
  String stepSizeTitle(String unit) {
    return 'Bước $unit';
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
  String get noteHint => 'Ghi chú cho hiệp này';
}
