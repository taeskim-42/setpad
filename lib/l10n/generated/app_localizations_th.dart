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
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString kcal';
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
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'รับประทาน ≈ $nString kcal';
  }

  @override
  String get mealFailed => 'ประมาณแคลอรีจากรูปนี้ไม่ได้ ลองถ่ายใหม่';

  @override
  String get mealEstimateNote => 'ประมาณจากรูปถ่าย';

  @override
  String mealServingsOption(String n) {
    return '$n หน่วยบริโภค';
  }

  @override
  String get fitAll => 'ดูทั้งหมด';

  @override
  String get sameDayOther => 'บันทึกอื่นในวันเดียวกัน';

  @override
  String get mealText => 'จดมื้ออาหาร';

  @override
  String get mealTextHint => 'กินอะไรไปบ้าง เช่น กล้วย 2 ลูก, นม 200ml';

  @override
  String kcalApprox(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '≈ $nString kcal';
  }

  @override
  String get mealKcalUnknown => 'ไม่ทราบแคลอรี';

  @override
  String mealIntakePartial(int n, int m) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'รับประทาน $nString kcal + ไม่ทราบแคลอรี $m รายการ';
  }

  @override
  String get mealAmountAsk => 'กินไปเท่าไร';

  @override
  String get mealBasis => 'เกณฑ์';

  @override
  String get mealEaten => 'ปริมาณที่กิน';

  @override
  String get mealUnitServing => 'หน่วยบริโภค';

  @override
  String get mealUnitPackage => 'ทั้งห่อ';

  @override
  String get mealUnitPhoto => 'อาหารในรูป';

  @override
  String get mealWhole => 'ทั้งหมด';

  @override
  String get mealHalf => 'ครึ่งหนึ่ง';

  @override
  String get mealPhotoWholeNote =>
      'นี่คือค่าประมาณของอาหารทั้งหมดในรูป เลือกปริมาณที่คุณกิน';

  @override
  String get mealAmountInvalid => 'กรุณาใส่ตัวเลขตั้งแต่ 0 ขึ้นไป';

  @override
  String dayEnergyFull(int intake, int burned, int diff) {
    final intl.NumberFormat intakeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String intakeString = intakeNumberFormat.format(intake);
    final intl.NumberFormat burnedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnedString = burnedNumberFormat.format(burned);
    final intl.NumberFormat diffNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String diffString = diffNumberFormat.format(diff);

    return 'ตามที่บันทึก: กิน $intakeString − ออกกำลัง $burnedString = $diffString kcal';
  }

  @override
  String dayEnergyApprox(int intake, int burned, int diff) {
    final intl.NumberFormat intakeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String intakeString = intakeNumberFormat.format(intake);
    final intl.NumberFormat burnedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnedString = burnedNumberFormat.format(burned);
    final intl.NumberFormat diffNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String diffString = diffNumberFormat.format(diff);

    return 'ตามที่บันทึก: กิน ≈ $intakeString − ออกกำลัง $burnedString ≈ $diffString kcal';
  }

  @override
  String get dayBurnedMissing =>
      'ยังไม่ได้วัดพลังงานที่ใช้ออกกำลัง · คำนวณส่วนต่างไม่ได้';

  @override
  String dayBurnedOnly(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'ออกกำลัง $nString kcal · ยังไม่ได้บันทึกอาหาร';
  }

  @override
  String get intakeLabel => 'กิน';

  @override
  String get partnerSignIn => 'ต้องเข้าสู่ระบบเพื่อออกกำลังด้วยกัน';

  @override
  String get partnerSignInAction => 'เข้าสู่ระบบ';

  @override
  String get partnerMakeCode => 'สร้างรหัส';

  @override
  String get partnerCopy => 'คัดลอก';

  @override
  String partnerExpiresIn(String t) {
    return 'หมดอายุใน $t';
  }

  @override
  String get partnerExpired => 'รหัสหมดอายุแล้ว';

  @override
  String get partnerNewCode => 'รหัสใหม่';

  @override
  String get partnerStopWaiting => 'เลิก';

  @override
  String partnerWith(String name) {
    return 'กำลังออกกำลังกับ $name';
  }

  @override
  String get partnerReconnecting =>
      'กำลังเชื่อมต่อใหม่ · บันทึกของคุณยังถูกเก็บต่อ';

  @override
  String partnerTheirRecord(String name) {
    return 'บันทึกของ $name';
  }

  @override
  String get partnerNoRecordYet => 'ยังไม่มีบันทึก';

  @override
  String get partnerLoading => 'กำลังโหลด…';

  @override
  String get partnerEnd => 'เลิกออกกำลังด้วยกัน';

  @override
  String get partnerEndedByMe =>
      'คุณเลิกออกกำลังด้วยกันแล้ว บันทึกของคุณยังอยู่';

  @override
  String partnerEndedByThem(String name) {
    return '$name เลิกออกกำลังด้วยกันแล้ว บันทึกของคุณยังอยู่';
  }

  @override
  String get partnerErrFormat => 'รหัสมี 6 ตัวอักษร กรุณาตรวจอีกครั้ง';

  @override
  String get partnerErrInvalid => 'ไม่พบรหัสนี้ อาจถูกใช้ไปแล้วหรือพิมพ์ผิด';

  @override
  String get partnerErrExpired => 'รหัสหมดอายุแล้ว ขอรหัสใหม่จากอีกฝ่าย';

  @override
  String get partnerErrEnded => 'คำเชิญนี้สิ้นสุดแล้ว';

  @override
  String get partnerErrOwn => 'นี่คือรหัสของคุณเอง ให้กรอกที่เครื่องของอีกฝ่าย';

  @override
  String get partnerErrTries => 'ลองหลายครั้งเกินไป โปรดลองใหม่ภายหลัง';

  @override
  String get partnerErrNetwork =>
      'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสอบเครือข่ายแล้วลองใหม่';

  @override
  String get partnerErrServer => 'เซิร์ฟเวอร์มีปัญหา โปรดลองใหม่อีกครั้ง';

  @override
  String get partnerRetry => 'ลองใหม่';

  @override
  String get partnerReadOnly => 'อ่านอย่างเดียว';

  @override
  String get partnerConflict =>
      'อุปกรณ์อื่นของคุณแชร์บันทึกที่ใหม่กว่า บันทึกในเครื่องนี้ยังอยู่ หยุดแค่การแชร์';

  @override
  String get partnerShareThisDevice => 'แชร์บันทึกของเครื่องนี้';

  @override
  String get plansTitle => 'แผนร่วม';

  @override
  String get planNew => 'แผนร่วมใหม่';

  @override
  String get planJoin => 'เข้าร่วมด้วยรหัส';

  @override
  String get planHint =>
      'บรรทัดแรกคือชื่อ จากนั้นบรรทัดละหนึ่งท่า\nเช่น สควอต 4 เซ็ต';

  @override
  String get planDateNone => 'ยังไม่กำหนดวัน';

  @override
  String planSetsCount(int n) {
    return '$n เซ็ต';
  }

  @override
  String get planSave => 'เสนอ';

  @override
  String get planStateLocal => 'ร่างเฉพาะในเครื่องนี้ · ยังไม่ขึ้นเซิร์ฟเวอร์';

  @override
  String get planStateDraft => 'ร่าง · ยังไม่มีคู่';

  @override
  String planStateWaiting(int v) {
    return 'รอคู่ยืนยัน · เวอร์ชัน $v';
  }

  @override
  String planStateNeedsMe(String name, int v) {
    return '$name แก้ไขแล้ว · ต้องยืนยันเวอร์ชัน $v';
  }

  @override
  String planStateAgreed(int v) {
    return 'ตกลงแล้ว · เวอร์ชัน $v';
  }

  @override
  String get planStateWithdrawn =>
      'การวางแผนร่วมสิ้นสุดแล้ว · แผนที่ตกลงและเป้าหมายของคุณยังอยู่';

  @override
  String planAccept(int v) {
    return 'ยอมรับเวอร์ชัน $v';
  }

  @override
  String get planChanged => 'สิ่งที่เปลี่ยนจากแผนที่ตกลงล่าสุด';

  @override
  String planAdded(String x) {
    return 'เพิ่ม: $x';
  }

  @override
  String planRemoved(String x) {
    return 'เอาออก: $x';
  }

  @override
  String planSetsChanged(String x) {
    return 'เปลี่ยนจำนวนเซ็ต: $x';
  }

  @override
  String get planReordered => 'ลำดับเปลี่ยน';

  @override
  String get planDateChanged => 'วันที่เปลี่ยน';

  @override
  String get planTitleChanged => 'ชื่อเปลี่ยน';

  @override
  String planLastAgreed(int v) {
    return 'แผนที่ตกลงล่าสุด · เวอร์ชัน $v';
  }

  @override
  String get planConflict => 'คู่ของคุณแก้ไขก่อน ร่างของคุณยังอยู่';

  @override
  String planLatest(int v) {
    return 'แผนล่าสุดของคู่ · เวอร์ชัน $v';
  }

  @override
  String get planKeepMine => 'เสนอร่างของฉันอีกครั้ง';

  @override
  String get planTakeLatest => 'ใช้แผนล่าสุด';

  @override
  String get planMyTarget => 'เป้าหมายของฉัน';

  @override
  String planPartnerTarget(String name, String t) {
    return '$name: $t';
  }

  @override
  String get planTargetHint => 'เช่น 100 5 หรือ 100kg 5 ครั้ง x3 โน้ต';

  @override
  String get planInvite => 'สร้างรหัสเชิญ';

  @override
  String get planStart => 'เริ่มด้วยแผนนี้';

  @override
  String get planStartSolo => 'เริ่มด้วยสำเนาของฉัน';

  @override
  String get planStartSoloNote =>
      'ยังไม่ได้ตกลงกัน หากเริ่มตอนนี้จะใช้สำเนาของคุณเอง ไม่ใช่แผนที่ตกลงแล้ว';

  @override
  String get planOpenWorkout => 'เปิดการออกกำลังที่เริ่มแล้ว';

  @override
  String get planCopyNext => 'คัดลอกไปครั้งถัดไป';

  @override
  String get planWithdraw => 'ออกจากแผนร่วมนี้';

  @override
  String get planCompare => 'แผนกับที่ทำจริง';

  @override
  String planDoneSets(String name, int planned, int done) {
    return '$name · แผน $planned · ทำ $done';
  }

  @override
  String planAddedActual(String x) {
    return 'ไม่ได้อยู่ในแผน: $x';
  }

  @override
  String planSkipped(String x) {
    return 'ไม่ได้ทำ: $x';
  }

  @override
  String planStartedFrom(int v) {
    return 'เริ่มจากแผนร่วมที่ตกลงแล้ว (เวอร์ชัน $v)';
  }

  @override
  String planStartedSolo(int v) {
    return 'เริ่มจากสำเนาของคุณ (เวอร์ชัน $v ยังไม่ตกลง)';
  }

  @override
  String get planShareLink => 'ส่งลิงก์เชิญ';

  @override
  String planShareText(String url) {
    return 'มาวางแผนออกกำลังด้วยกันใน setpad: $url';
  }

  @override
  String get planLinkCopied => 'คัดลอกลิงก์แล้ว ใช้ได้หนึ่งครั้งภายในหนึ่งวัน';

  @override
  String get planLinkJoining => 'กำลังเข้าร่วมแผนที่ได้รับเชิญ…';

  @override
  String get nearbyHint =>
      'ระหว่าง iPhone ด้วยกัน เปิดหน้านี้ค้างไว้แล้วนำสองเครื่องมาใกล้กันก็เชื่อมต่อได้';

  @override
  String get planPropose => 'เสนอแผนร่วม';
}
