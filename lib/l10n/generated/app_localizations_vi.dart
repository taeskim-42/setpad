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
}
