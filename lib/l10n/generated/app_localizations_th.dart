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
  String timingRoundDone(int n) {
    return 'จบรอบที่ $n';
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
  String get queryOffline => 'ต้องเชื่อมต่อจึงจะถามได้';

  @override
  String get queryNoData =>
      'ขาดบันทึกที่เสร็จแล้วหรือค่าที่จำเป็น โปรดตรวจสอบบันทึกต้นฉบับ';

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

  @override
  String timingHeart(int bpm, int target) {
    return '♥ $bpm → $target';
  }

  @override
  String get accountSignIn => 'ลงชื่อเข้าใช้และสำรองข้อมูล';

  @override
  String get accountSignOut => 'ออกจากระบบ';

  @override
  String get planMonthly => 'รายเดือน';

  @override
  String get planLifetime => 'ตลอดชีพ';

  @override
  String get planActive => 'กำลังใช้งาน';

  @override
  String get restorePurchases => 'กู้คืนการซื้อ';

  @override
  String get quotaSpent => 'คุณใช้คำถามของเดือนนี้หมดแล้ว';

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
    return 'จาก $gym';
  }

  @override
  String get partnerInvite => 'ออกกำลังด้วยกัน';

  @override
  String get partnerCode => 'บอกรหัสนี้กับคู่ซ้อม';

  @override
  String get partnerEnter => 'ใส่รหัส';

  @override
  String partnerJoined(String name) {
    return 'บันทึกร่วมกับ $name';
  }

  @override
  String get partnerFailed => 'รหัสไม่ถูกต้องหรือหมดอายุ';

  @override
  String bookingNext(String trainer, String when) {
    return '$trainer · $when';
  }

  @override
  String get bookingNew => 'จอง PT';

  @override
  String get bookingNone => 'วันนั้นไม่มีเวลาว่าง';

  @override
  String get bookingCancel => 'ยกเลิกการจอง';

  @override
  String get countAloud => 'นับจังหวะออกเสียง';

  @override
  String get metricMax => 'สูงสุด';

  @override
  String get metricTrend => 'แนวโน้ม';

  @override
  String get metricLast => 'ล่าสุด';

  @override
  String get metricSessions => 'จำนวนวัน';

  @override
  String get metricVolume => 'ปริมาณ';

  @override
  String get metricReps => 'ครั้งรวม';

  @override
  String get metricSets => 'จำนวนเซ็ต';

  @override
  String get metricAverage => 'เฉลี่ย';

  @override
  String get readAsConfirm => 'อ่านว่า';

  @override
  String get confirmYes => 'ใช่';

  @override
  String readAsNote(String from, String to) {
    return '$from → $to';
  }

  @override
  String get reviewNumbers => 'ตรวจสอบตัวเลขและเงื่อนไขก่อนนำไปใช้';

  @override
  String get querySourceOnly => 'ดูบันทึกต้นฉบับ';

  @override
  String get queryCompareOrder => 'ช่วงที่สอง − ช่วงแรก';

  @override
  String queryRankingLimit(int n) {
    return 'สูงสุด $n รายการ · มากไปน้อย';
  }

  @override
  String get settingsTitle => 'การตั้งค่า';

  @override
  String get settingsRecording => 'การบันทึก';

  @override
  String get settingsAccount => 'บัญชี';

  @override
  String get settingsGym => 'ยิมของคุณ';

  @override
  String get settingsNoGym =>
      'แตะโทรศัพท์ที่สติกเกอร์ของยิมเพื่อรับโปรแกรมจากเทรนเนอร์';

  @override
  String get proTitle => 'ถามบันทึกของคุณได้ทุกเรื่อง';

  @override
  String get proBody =>
      'ถามว่า “สควอทหนักสุดเท่าไร” หรือ “เดือนนี้เบนช์ดีขึ้นไหม” แล้วรับคำตอบที่คำนวณจากบันทึกของคุณ';

  @override
  String proFree(int n) {
    return 'ฟรี $n ครั้งต่อเดือน';
  }

  @override
  String proPaid(int n) {
    return 'มีแพ็กเกจ $n ครั้งต่อวัน';
  }

  @override
  String get proEverythingElseFree =>
      'การบันทึก จับเวลา เชื่อมสุขภาพ และฟีเจอร์ยิม ใช้ได้โดยไม่ต้องมีแพ็กเกจ';

  @override
  String get proOwned => 'กำลังใช้งาน ขอบคุณครับ';

  @override
  String get proSignInFirst => 'แพ็กเกจผูกกับบัญชี กรุณาเข้าสู่ระบบก่อน';

  @override
  String get tagSignInNeeded => 'เข้าสู่ระบบเพื่อเชื่อมต่อกับยิมของคุณ';

  @override
  String get tagJoinSent => 'ส่งคำขอแล้ว เริ่มได้ทันทีเมื่อเทรนเนอร์ยืนยัน';

  @override
  String get tagJoinWaiting => 'ส่งคำขอไปแล้ว เทรนเนอร์กำลังตรวจสอบ';

  @override
  String get tagJoinFailed => 'ส่งคำขอไม่สำเร็จ อีกสักครู่แตะสติกเกอร์อีกครั้ง';

  @override
  String get bookingPending => 'รอการอนุมัติ';

  @override
  String get bookingWhichGym => 'ยิมไหน';

  @override
  String get tagSignIn => 'เข้าสู่ระบบ';

  @override
  String get accountDelete => 'ลบบัญชี';

  @override
  String get accountDeleteAsk =>
      'ย้อนกลับไม่ได้ โปรแกรม บันทึกการฝึก แพ็กเกจ และการจองจะหายทั้งหมด';

  @override
  String get accountDeleteDo => 'ลบบัญชี';

  @override
  String get accountDeleteFailed =>
      'ลบบัญชีไม่สำเร็จ อีกสักครู่ลองใหม่อีกครั้ง';

  @override
  String get signInFailed => 'เข้าสู่ระบบไม่สำเร็จ อีกสักครู่ลองใหม่อีกครั้ง';

  @override
  String get bookingTitle => 'จอง PT';

  @override
  String get bookingConfirmed => 'ยืนยันแล้ว';

  @override
  String bookingRemaining(int n) {
    return 'เหลือ $n ครั้ง';
  }

  @override
  String get bookingNoPass => 'ยังไม่มีแพ็กเกจ PT กรุณาสอบถามเทรนเนอร์';

  @override
  String bookingNoHours(String trainer) {
    return '$trainer ยังไม่ได้เปิดเวลารับ';
  }

  @override
  String get bookingPick => 'เลือกเวลา';

  @override
  String bookingWith(String trainer, int minutes) {
    return '$trainer · ครั้งละ $minutes นาที';
  }

  @override
  String get bookingSent => 'ส่งคำขอแล้ว จะยืนยันเมื่อเทรนเนอร์อนุมัติ';

  @override
  String get bookingUpcoming => 'นัดที่จะถึง';

  @override
  String get bookingClosedDay => 'วันนี้ไม่เปิดรับ';

  @override
  String get bookingCancelAsk => 'ยกเลิกการจองนี้ไหม';

  @override
  String get ok => 'ตกลง';

  @override
  String get mealPhoto => 'รูปอาหาร';

  @override
  String get mealCamera => 'กล้อง';

  @override
  String get mealGallery => 'จากอัลบั้ม';

  @override
  String get mealEstimating => 'กำลังประมาณแคลอรี…';

  @override
  String mealIntake(int n) {
    return 'รับประทาน ≈ $n kcal';
  }

  @override
  String mealNet(int n) {
    return 'เผาผลาญ − รับประทาน $n kcal';
  }

  @override
  String get mealFailed => 'ประมาณแคลอรีจากรูปนี้ไม่ได้ ลองถ่ายใหม่';

  @override
  String get mealEstimateNote => 'ประมาณจากรูปถ่าย';

  @override
  String get mealServingsAsk => 'กินไปกี่หน่วยบริโภค?';

  @override
  String mealServingsOption(String n) {
    return '$n หน่วยบริโภค';
  }

  @override
  String mealWholePackage(String n) {
    return 'ทั้งห่อ ($n หน่วยบริโภค)';
  }
}
