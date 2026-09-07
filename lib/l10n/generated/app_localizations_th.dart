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
  String get howTo => 'ค้นหาท่าออกกำลังกายแล้วบันทึกเซต';

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

  @override
  String get activeEnergy => 'พลังงานจากกิจกรรม';

  @override
  String get energyUnavailable => 'ไม่มีข้อมูล';

  @override
  String get energySource => 'สุขภาพ · ช่วงเวลาของบันทึกนี้';

  @override
  String get doneEditing => 'เสร็จสิ้น';

  @override
  String get setInputHint => 'น้ำหนัก  ครั้ง';

  @override
  String get setRequired => 'ป้อนเซ็ตก่อน เช่น 60 12';

  @override
  String get aiTitle => 'ตั้งค่าด้วยประโยคเดียว';

  @override
  String get aiReady => 'พร้อมใช้งาน';

  @override
  String get aiChecking => 'กำลังตรวจสอบ';

  @override
  String get aiSetupNeeded => 'ต้องตั้งค่า';

  @override
  String get aiPreparing => 'กำลังเตรียม';

  @override
  String get aiUnavailable => 'ป้อนเอง';

  @override
  String get aiReadyBody =>
      'พิมพ์เช่น “เบนช์เพรส 80kg ให้ครบ 100 ครั้ง” แล้วกด Enter เพื่อตั้งค่าน้ำหนักและเป้าหมาย ข้อความจะประมวลผลบนอุปกรณ์นี้';

  @override
  String get aiDisabledBody =>
      'เปิดการตั้งค่า → Apple Intelligence และ Siri แล้วเปิด Apple Intelligence เมื่อโมเดลพร้อม กลับเข้าแอปเพื่อตรวจสอบอัตโนมัติ';

  @override
  String get aiOsBody =>
      'ต้องใช้ iOS 26 ขึ้นไปและอุปกรณ์ที่รองรับ Apple Intelligence ตรวจสอบการตั้งค่า → ทั่วไป → รายการอัปเดตซอฟต์แวร์';

  @override
  String get aiDeviceBody =>
      'อุปกรณ์นี้ไม่รองรับ Apple Intelligence จึงใช้การตั้งค่าด้วยประโยคเดียวไม่ได้';

  @override
  String get aiPreparingBody =>
      'อุปกรณ์กำลังเตรียมโมเดล AI เชื่อมต่อ Wi-Fi แล้วตรวจสอบอีกครั้งภายหลัง';

  @override
  String get aiDownloadBody =>
      'ดาวน์โหลดโมเดล AI ได้ แนะนำให้ใช้ Wi-Fi การดาวน์โหลดต้องใช้เวลาและพื้นที่จัดเก็บ เมื่อพร้อมแล้ว ข้อความจะประมวลผลบนอุปกรณ์';

  @override
  String get aiLanguageBody =>
      'โมเดล AI ไม่รองรับภาษาของแอป เปลี่ยนเป็นภาษาที่รองรับแล้วตรวจสอบอีกครั้ง';

  @override
  String get aiPlatformBody =>
      'ใช้ AI บนอุปกรณ์ในสภาพแวดล้อมนี้ไม่ได้ โปรดใช้แอปบน iPhone หรือ Android ที่รองรับ';

  @override
  String get aiUnavailableBody =>
      'ยังใช้ AI ไม่ได้ ขึ้นอยู่กับอุปกรณ์ ระบบปฏิบัติการ และบริการ AI ของระบบ หากเพิ่งตั้งค่าอุปกรณ์ ให้เชื่อมต่ออินเทอร์เน็ตแล้วตรวจสอบอีกครั้ง';

  @override
  String get aiManualBody =>
      'ยังบันทึกการออกกำลังกายได้ตามปกติ เลือกท่าแล้วป้อน “80 20” หรือจำนวนครั้งสำหรับแต่ละเซ็ต';

  @override
  String get aiPrepare => 'เตรียมโมเดล';

  @override
  String get aiRetry => 'ตรวจสอบอีกครั้ง';

  @override
  String get aiWorking => 'กำลังตั้งค่าท่า…';

  @override
  String get aiFailure =>
      'ตีความข้อความไม่ได้ โปรดแก้ไขแล้วลองใหม่ หรือใช้เป็นชื่อท่า';

  @override
  String get aiUseName => 'ใช้เป็นชื่อท่า';

  @override
  String goalProgress(int done, int goal) {
    return '$done/$goal ครั้ง';
  }

  @override
  String repsPerSetLabel(int n) {
    return '$n ครั้งต่อเซ็ต';
  }

  @override
  String setProgress(int done, int goal) {
    return '$done/$goal เซ็ต';
  }

  @override
  String get repsInputHint => 'จำนวนครั้ง';

  @override
  String get setupTitle => 'ตั้งค่าท่า';

  @override
  String get setupWeight => 'น้ำหนักเริ่มต้น';

  @override
  String get setupTotalReps => 'เป้าหมายครั้งรวม';

  @override
  String get setupSetReps => 'จำนวนครั้งต่อเซ็ต';

  @override
  String get setupTotalSets => 'เป้าหมายเซ็ต';
}
