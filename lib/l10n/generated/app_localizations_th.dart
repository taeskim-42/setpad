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

  @override
  String get moveExercise => 'ย้ายท่าออกกำลังกาย';

  @override
  String get weightUnitSetting => 'หน่วยน้ำหนักเริ่มต้น';

  @override
  String get weightUnitHelp =>
      'ใช้กับท่าออกกำลังกายใหม่ น้ำหนักและหน่วยที่บันทึกไว้จะไม่เปลี่ยน';

  @override
  String answerDays(int n) {
    return 'บันทึก $n วัน';
  }

  @override
  String answerWeeks(int n) {
    return '$n สัปดาห์';
  }

  @override
  String answerFrequency(String n) {
    return '$n ครั้ง/สัปดาห์';
  }

  @override
  String answerPeak(String value) {
    return 'สูงสุด $value';
  }

  @override
  String answerNoPeak(int n) {
    return 'ไม่ทำลายสถิติใน $n สัปดาห์';
  }

  @override
  String answerSince(String date) {
    return 'ตั้งแต่ $date';
  }

  @override
  String answerAgo(int n) {
    return '$n วันที่แล้ว';
  }

  @override
  String answerPerSet(String value) {
    return '$value ต่อเซต';
  }

  @override
  String answerChange(String weeks, String value) {
    return '$weeks · $value';
  }

  @override
  String answerChart(String name, int n) {
    return '$name · บันทึก $n วัน';
  }

  @override
  String answerWeightReps(String value, String reps) {
    return '$value × $reps';
  }

  @override
  String answerSets(int n) {
    return '$n เซต';
  }

  @override
  String timingBpm(int n) {
    return '$n BPM';
  }

  @override
  String timingProtocol(int work, int rest, int rounds) {
    return 'ทาบาตะ $workวิ / $restวิ · $rounds รอบ';
  }

  @override
  String timingRound(int n, int total) {
    return 'รอบ $n/$total';
  }

  @override
  String get timingMetronome => 'เครื่องเคาะจังหวะ';

  @override
  String get timingReady => 'เตรียม';

  @override
  String get timingWork => 'ออกแรง';

  @override
  String get timingRest => 'พัก';

  @override
  String get timingComplete => 'เสร็จสิ้น';

  @override
  String get timingStart => 'เริ่ม';

  @override
  String get timingPause => 'หยุดชั่วคราว';

  @override
  String get timingReset => 'รีเซ็ต';

  @override
  String get timingInvalid =>
      'ใช้ 10–120 BPM, 1–600 วินาทีสำหรับออกกำลังและพัก, และ 1–99 รอบ';

  @override
  String get timingSoundFailed => 'เล่นเสียงไม่ได้ แต่ตัวจับเวลายังทำงาน';

  @override
  String get queryTitle => 'ถามจากบันทึก';

  @override
  String get queryReadyBody =>
      'ถามว่า “สควอตหนักสุดเท่าไร” “เดือนก่อนวิดพื้นกี่ครั้ง” หรือ “เบนช์เดือนนี้ดีขึ้นไหม” AI บนอุปกรณ์ตีความคำถามแล้วคำนวณจากบันทึก';

  @override
  String get queryManualBody =>
      'คำถามภาษาธรรมชาติต้องใช้ AI บนอุปกรณ์ที่พร้อมใช้งาน ค้นหาชื่อท่าและโน้ตได้เสมอ';

  @override
  String get queryWorking => 'กำลังตีความคำถาม…';

  @override
  String get queryFailed => 'ไม่สามารถโหลดคำตอบได้ โปรดลองอีกครั้ง';

  @override
  String get queryUnsupported => 'โปรดถามเกี่ยวกับบันทึกการออกกำลังกายของคุณ';

  @override
  String get queryNoData =>
      'ไม่มีบันทึกที่ทำสำเร็จตรงเงื่อนไข หรือข้อมูลที่จำเป็นไม่ครบ';

  @override
  String queryPeriod(String start, String end) {
    return '$start – $end';
  }

  @override
  String get queryAllTime => 'ทุกช่วงเวลา';

  @override
  String get queryPresent => 'ปัจจุบัน';

  @override
  String get queryRepUnit => 'ครั้ง';

  @override
  String get querySetUnit => 'เซต';

  @override
  String get queryDayUnit => 'วัน';

  @override
  String get queryAverage => 'น้ำหนักเฉลี่ยต่อเซต';

  @override
  String get queryMissingData =>
      'บันทึกไม่มีท่าหรือค่าที่วัดซึ่งจำเป็นต่อคำถามนี้';

  @override
  String get queryAmbiguous => 'โปรดระบุท่าและบันทึกที่ต้องการให้ชัดเจนขึ้น';

  @override
  String queryRank(int n) {
    return 'อันดับ $n';
  }

  @override
  String timingWorkSeconds(int n) {
    return 'ออกกำลัง $n วิ';
  }

  @override
  String timingRestSeconds(int n) {
    return 'พัก $n วิ';
  }

  @override
  String timingRounds(int n) {
    return '$n รอบ';
  }

  @override
  String timingBeat(String count) {
    return 'จังหวะที่ $count';
  }
}
