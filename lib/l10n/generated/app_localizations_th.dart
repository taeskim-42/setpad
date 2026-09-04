// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class LTh extends L {
  LTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'การฝึกวันนี้';

  @override
  String get copy => 'คัดลอก';

  @override
  String get copied => 'คัดลอกแล้ว';

  @override
  String get howTo =>
      'พิมพ์ชื่อท่าแล้วกด Enter → พิมพ์เซ็ตแล้วกด Enter → กด Enter ที่บรรทัดว่างเพื่อไปท่าถัดไป';

  @override
  String get exerciseNameHint => 'ชื่อท่า';

  @override
  String get repeatPrevious => 'เหมือนเซ็ตก่อน';

  @override
  String get addSet => 'เพิ่มเซ็ต';

  @override
  String get numberKeypad => 'แป้นตัวเลข';

  @override
  String setOrdinal(int n) {
    return 'เซ็ต $n';
  }

  @override
  String repsCount(int n) {
    return '$n ครั้ง';
  }
}
