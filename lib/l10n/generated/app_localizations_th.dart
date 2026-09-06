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

  @override
  String get allNotes => 'บันทึกทั้งหมด';

  @override
  String noteCount(int n) {
    return '$n รายการ';
  }

  @override
  String get previous7Days => '7 วันที่ผ่านมา';

  @override
  String get previous30Days => '30 วันที่ผ่านมา';

  @override
  String monthLabel(int m) {
    return 'เดือน $m';
  }

  @override
  String get search => 'ค้นหา';

  @override
  String get newNote => 'บันทึกใหม่';

  @override
  String get untitledNote => 'บันทึกใหม่';

  @override
  String get noNotesYet => 'ยังไม่มีบันทึก';

  @override
  String get noSearchResults => 'ไม่พบรายการ';

  @override
  String dayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.yMd(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get finishExercise => 'เสร็จ';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get delete => 'ลบ';

  @override
  String deleteExerciseTitle(String name) {
    return 'ลบ $name';
  }

  @override
  String deleteExerciseBody(int n) {
    return 'จะลบ $n เซ็ตด้วย ย้อนกลับไม่ได้';
  }

  @override
  String get deleteExerciseEmptyBody => 'จะลบท่านี้';

  @override
  String get next => 'ถัดไป';

  @override
  String stepSizeTitle(String unit) {
    return 'ขั้นของ $unit';
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
  String get noteHint => 'บันทึกสำหรับเซ็ตนี้';
}
