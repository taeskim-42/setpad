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
  String monthLabel(int m) {
    return 'เดือน $m';
  }

  @override
  String get search => 'ค้นหาหรือถาม';

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
  String setsPerLineMax(int n) {
    return 'ป้อนได้บรรทัดละไม่เกิน $n เซ็ต แบ่งเป็นหลายบรรทัด';
  }

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
  String get aiFallbackQuota =>
      'ใช้ตัวช่วยพิมพ์ของวันนี้หมดแล้ว จึงเพิ่มตามที่พิมพ์ไว้';

  @override
  String get aiFallbackOffline =>
      'เชื่อมต่อไม่ได้ จึงเพิ่มตามที่พิมพ์ไว้ ตั้งค่าได้จาก ⚙ ของการ์ด';

  @override
  String get aiFallbackServer =>
      'เซิร์ฟเวอร์ไม่ตอบ จึงเพิ่มตามที่พิมพ์ไว้ ตั้งค่าได้จาก ⚙ ของการ์ด';

  @override
  String get aiFallbackUnread =>
      'ไม่พบสิ่งที่ตั้งค่าได้ จึงเพิ่มตามที่พิมพ์ไว้ ตั้งค่าได้จาก ⚙ ของการ์ด';

  @override
  String get inputNameTooLong =>
      'ชื่อท่ายาวได้ไม่เกิน 120 ตัวอักษร — แยกเป็นหลายบรรทัด';

  @override
  String get inputTooLong =>
      'ข้อความที่ยาวเกิน 600 ตัวอักษรจะไม่ถูกอ่าน — แยกเป็นหลายบรรทัด';

  @override
  String get setupAdd => 'เพิ่มการตั้งค่า';

  @override
  String setupUnparsed(String words) {
    return 'ส่วนที่ย้ายเข้าการตั้งค่าไม่ได้: $words — ยังอยู่ในชื่อ';
  }

  @override
  String setupDropped(String numbers) {
    return 'ตัดตัวเลขที่ไม่มีในข้อความออกแล้ว: $numbers';
  }

  @override
  String get setupNameMissing => 'ใส่ชื่อท่า';

  @override
  String get setupNameTooLong => 'ไม่เกิน 120 ตัวอักษร';

  @override
  String get setupWeightInvalid => 'ใส่ตัวเลขที่มากกว่า 0 และไม่เกิน 2000';

  @override
  String get setupCountInvalid =>
      'ใส่จำนวนเต็มตั้งแต่ 1 ขึ้นไป — ช่วงและเวลาให้คงไว้ในชื่อ';

  @override
  String get setupRepsOnly => 'บันทึกแค่จำนวนครั้ง';

  @override
  String setupSplit(int count) {
    return 'แยกเป็น $count ท่า';
  }

  @override
  String get setupMergeAll => 'รวมเป็นรายการเดียว';

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
  String get accountSignIn => 'ลงชื่อเข้าใช้';

  @override
  String get accountSignOut => 'ออกจากระบบ';

  @override
  String get planMonthly => 'รายเดือน';

  @override
  String get planYearly => 'รายปี';

  @override
  String planYearlyTrial(int days, String price) {
    return 'ทดลองใช้ฟรี $days วัน จากนั้น $price ต่อปี ยกเลิกอย่างน้อย 24 ชั่วโมงก่อนสิ้นสุดช่วงทดลองจะไม่ถูกเรียกเก็บเงิน';
  }

  @override
  String planYearlyTrialPlates(int n) {
    return 'ระหว่างทดลองใช้ฟรี เติมแผ่นน้ำหนักให้ถึง $n แผ่น เมื่อเริ่มเรียกเก็บเงินจะเป็นการเติมรายเดือน';
  }

  @override
  String get planActive => 'กำลังใช้งาน';

  @override
  String get restorePurchases => 'กู้คืนการซื้อ';

  @override
  String get subscriptionRenews =>
      'การสมัครสมาชิกจะต่ออายุอัตโนมัติในราคาเดิม เว้นแต่จะยกเลิกอย่างน้อย 24 ชั่วโมงก่อนสิ้นสุดรอบปัจจุบัน ยกเลิกได้ทุกเมื่อในการจัดการการสมัครสมาชิกของสโตร์';

  @override
  String get termsOfUse => 'ข้อกำหนดการใช้งาน (EULA)';

  @override
  String get inputQuotaSpent =>
      'ใช้ตัวช่วยจดของวันนี้หมดแล้ว พิมพ์เองก็ยังบันทึกได้ตามปกติ';

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
  String get metricE1rm => '1RM โดยประมาณ';

  @override
  String get metricMaxReps => 'ครั้งสูงสุด';

  @override
  String get metricLongest => 'ยาวที่สุด';

  @override
  String get metricFirst => 'ครั้งแรก';

  @override
  String get metricDaysSince => 'วันที่ไม่ได้ฝึก';

  @override
  String get metricDistance => 'ระยะทางรวม';

  @override
  String get metricDuration => 'เวลารวม';

  @override
  String get readAsConfirm => 'อ่านว่า';

  @override
  String get confirmYes => 'ใช่';

  @override
  String readAsNote(String from, String to) {
    return '$from → $to';
  }

  @override
  String get queryByExercise => 'ตามท่า';

  @override
  String get queryByDay => 'ตามวัน';

  @override
  String get queryByWeek => 'ตามสัปดาห์ (เริ่มวันจันทร์)';

  @override
  String get queryByMonth => 'ตามเดือน';

  @override
  String get queryByWeekday => 'ตามวันในสัปดาห์';

  @override
  String get queryTotalSum => 'รวม';

  @override
  String get queryTotalMean => 'เฉลี่ย';

  @override
  String queryDiff(String later, String earlier) {
    return 'ส่วนต่าง ($later − $earlier)';
  }

  @override
  String queryExclude(String names) {
    return 'ยกเว้น $names';
  }

  @override
  String queryMemo(String terms) {
    return 'บันทึก: $terms';
  }

  @override
  String queryLastSessions(int n) {
    return '$n ครั้งล่าสุด';
  }

  @override
  String queryBottomLimit(int n) {
    return 'ต่ำสุด $n รายการ · น้อยไปมาก';
  }

  @override
  String queryOutOfScope(String names) {
    return 'ไม่นับ (ไม่มีค่าสำหรับการวัดนี้): $names';
  }

  @override
  String queryMissingFor(String names) {
    return 'ไม่ได้คำนวณ (มีเซ็ตที่ขาดค่า): $names';
  }

  @override
  String get queryE1rmRule =>
      '1RM โดยประมาณ = น้ำหนัก × (1 + จำนวนครั้ง ÷ 30) เฉพาะเซ็ต 1–10 ครั้ง';

  @override
  String queryMore(int n) {
    return 'อีก $n รายการ';
  }

  @override
  String queryRankingLimit(int n) {
    return 'สูงสุด $n รายการ · มากไปน้อย';
  }

  @override
  String get queryCompareChip => 'เปรียบเทียบ';

  @override
  String get queryNoRecord => 'ไม่มีบันทึก';

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
  String get proTitle => 'Pro';

  @override
  String get proBody =>
      'การถามบันทึกของคุณใช้แผ่นน้ำหนัก โดยปกติประมาณ 1 แผ่นต่อคำถาม และหักเท่าที่คำตอบใช้จริง ตัวช่วยจดการออกกำลังกายและมื้ออาหารไม่ใช้แผ่นน้ำหนัก';

  @override
  String proFree(int n, int sets) {
    return 'ฟรี: ตัวช่วยจดวันละ $n ครั้ง · วันที่ทำครบ $sets เซ็ตได้ 1 แผ่น';
  }

  @override
  String proPaid(int n, int input) {
    return 'Pro: เติมแผ่นน้ำหนักให้ถึง $n แผ่นทุกเดือน · ตัวช่วยจดวันละ $input ครั้ง';
  }

  @override
  String get proEverythingElseFree =>
      'การบันทึก ตัวจับเวลา การแจ้งเตือนที่ข้อมือ ออกกำลังด้วยกัน และยิม ใช้ได้ทั้งหมดโดยไม่ต้องมี Pro';

  @override
  String get proOwned => 'กำลังใช้งาน ขอบคุณครับ';

  @override
  String get proSignInFirst => 'แพ็กเกจผูกกับบัญชี กรุณาเข้าสู่ระบบก่อน';

  @override
  String platesBalance(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'เหลือแผ่นน้ำหนัก $nString แผ่น';
  }

  @override
  String platesSpent(num spent, num balance) {
    final intl.NumberFormat spentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String spentString = spentNumberFormat.format(spent);
    final intl.NumberFormat balanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String balanceString = balanceNumberFormat.format(balance);

    return 'ใช้ $spentString แผ่น · เหลือ $balanceString แผ่น';
  }

  @override
  String noPlates(int sets) {
    return 'แผ่นน้ำหนักไม่พอ ทุกวันที่ทำครบ $sets เซ็ตจะได้ 1 แผ่น';
  }

  @override
  String noPlatesSignIn(int n) {
    return 'เข้าสู่ระบบ · บัญชีใหม่รับ $n แผ่น';
  }

  @override
  String platesGetPro(int n) {
    return 'ดู Pro · เดือนละ $n แผ่น';
  }

  @override
  String get purchaseNotConfirmed =>
      'ยืนยันการซื้อไม่ได้ ถ้าถูกเรียกเก็บเงินแล้ว โปรดแตะ “กู้คืนการซื้อ” อีกสักครู่';

  @override
  String get purchaseOtherAccount =>
      'การซื้อนี้ผูกกับบัญชีอื่น โปรดเข้าสู่ระบบด้วยบัญชีนั้น';

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
  String get mealAdd => 'บันทึกมื้ออาหาร';

  @override
  String get mealWrite => 'พิมพ์เอง';

  @override
  String get mealTypeHint =>
      'พิมพ์ชื่ออาหารลงในบรรทัดชื่อท่าได้เลย ระบบจะบันทึกเป็นมื้ออาหาร';

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
  String get fitAll => 'การออกกำลังวันนี้';

  @override
  String sameDayToday(String time) {
    return 'บันทึกแยกของวันนี้ เวลา $time';
  }

  @override
  String sameDayOn(String date, String time) {
    return 'บันทึกแยกของวันที่ $date เวลา $time';
  }

  @override
  String sameDayMore(String first, int n) {
    return '$first และอีก $n ท่า';
  }

  @override
  String lastWeekDay(String weekday, String date) {
    return '$weekdayที่แล้ว ($date)';
  }

  @override
  String weeksAgoDay(int n, String weekday, String date) {
    return '$weekday เมื่อ $n สัปดาห์ก่อน ($date)';
  }

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
  String get mealTextUnknown =>
      'ประมาณแคลอรีไม่ได้ เพราะไม่รู้จักอาหารนี้ แตะมื้อนั้นเพื่อเพิ่มชื่ออาหารหรือปริมาณ แล้วจะประมาณใหม่';

  @override
  String get mealTextOffline =>
      'ประมาณแคลอรีไม่ได้ เพราะไม่มีการเชื่อมต่อ แตะมื้อนั้นแล้วกด Enter เพื่อประมาณใหม่';

  @override
  String get mealTextTooLong =>
      'บันทึกอาหารที่ยาวเกิน 500 ตัวอักษรจะไม่ถูกประมาณ แตะมื้อนั้นแล้วแบ่งเขียนเพื่อให้ประมาณได้';

  @override
  String queryTooLong(int max) {
    return 'คำถามยาวได้ไม่เกิน $max ตัวอักษร โปรดย่อให้สั้นลง';
  }

  @override
  String get queryPressEnter => 'กด Enter เพื่อถามเกี่ยวกับบันทึกของคุณ';

  @override
  String get mealRetry => 'ประมาณใหม่';

  @override
  String kcalAtLeast(int n) {
    return '≥ $n kcal';
  }

  @override
  String mealTextPartial(int n) {
    return 'นับเฉพาะ $n kcal ที่คุณเขียนไว้ อาหารอื่นยังไม่ทราบแคลอรี';
  }

  @override
  String mealTextBelowTyped(int n) {
    return 'ค่าประมาณออกมาน้อยกว่า $n kcal ที่คุณเขียนไว้ จึงไม่ได้ใช้ นับเฉพาะ $n kcal ของคุณ';
  }

  @override
  String queryLimit(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'exercises': 'ถามได้ครั้งละไม่เกิน 8 ท่า ลองถามแยกเป็นส่วน',
      'measures': 'นับได้ครั้งละไม่เกิน 4 อย่าง ลองถามแยกเป็นส่วน',
      'ranking': 'อันดับแสดงได้ไม่เกิน 20 รายการ โปรดถามไม่เกิน 20',
      'sessions':
          '\'N ครั้งล่าสุด\' ได้ไม่เกิน 100 ครั้ง ถ้าต้องการนานกว่านั้น ให้ถามตามช่วงเวลา เช่น ปีนี้',
      'days':
          '\'N วันล่าสุด\' ได้ไม่เกิน 3660 วัน (ประมาณ 10 ปี) ถ้าต้องการนานกว่านั้น ให้ถามทั้งหมด',
      'compare': 'เปรียบเทียบได้ครั้งละไม่เกิน 6 อย่าง ลองถามแยกเป็นส่วน',
      'compareGrouped':
          'การเปรียบเทียบจัดกลุ่มตามท่า วัน สัปดาห์ เดือน หรือวันในสัปดาห์ในคำถามเดียวกันไม่ได้ โปรดถามอย่างใดอย่างหนึ่ง',
      'groupedMeasure':
          'เมื่อเทียบหลายช่วงโดยจัดกลุ่มตามวัน สัปดาห์ เดือน หรือวันในสัปดาห์ นับได้เพียงอย่างเดียว และแนวโน้ม ครั้งล่าสุด ครั้งแรก และจำนวนวันตั้งแต่ครั้งล่าสุดจัดกลุ่มไม่ได้',
      'ordering':
          'อันดับ ผลรวม และค่าเฉลี่ยต้องจัดกลุ่ม เช่น ตามท่าหรือตามสัปดาห์',
      'datesTotal': 'วันที่ครั้งล่าสุดและครั้งแรกนำมารวมหรือหาค่าเฉลี่ยไม่ได้',
      'perMeasure':
          'ค่าเฉลี่ยต่อวัน ต่อสัปดาห์ หรือต่อเดือน ใช้ได้กับค่าที่บวกกันได้เท่านั้น เช่น เซ็ต ครั้ง วอลุ่ม ระยะทาง เวลา จำนวนวัน และ kcal ถ้าจะดูน้ำหนักสูงสุดหรือเฉลี่ย ให้ถามตามช่วงเวลา',
      'shareMeasure':
          'สัดส่วนคิดได้เฉพาะค่าที่บวกกันได้ เช่น จำนวนเซ็ตหรือวอลุ่ม',
      'trainedMeasure':
          'การเลือกวันที่ออกกำลังกายหรือวันพักใช้กับ kcal ที่กินและเผาผลาญเท่านั้น บันทึกการออกกำลังกายทั้งหมดมาจากวันที่ออกกำลังกาย',
      'sameSeries':
          'สองฝั่งที่จะเทียบถูกอ่านเป็นช่วงเดียวกัน บอกว่าจะเทียบอะไรกับอะไร',
      'other': 'การค้นหาบันทึกคำนวณคำถามรูปแบบนี้ไม่ได้ ลองถามแยกเป็นส่วน',
    });
    return '$_temp0';
  }

  @override
  String policyNumberRejected(String text, String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'decimal': '\'$text\' — ใช้ทศนิยมไม่ได้ โปรดใส่จำนวนเต็ม เช่น 14',
      'range': '\'$text\' — โปรดใส่ตัวเลขเดียว ไม่ใช่ช่วง เช่น 14',
      'negative': '\'$text\' — ใช้ตัวเลขที่น้อยกว่า 0 ไม่ได้ เช่น 14',
      'unit':
          '\'$text\' — ช่องนี้นับเป็นวันหรือครั้ง โปรดแปลงชั่วโมง สัปดาห์ หรือเดือนเป็นจำนวนวัน เช่น 14',
      'many': '\'$text\' — โปรดใส่ตัวเลขเพียงตัวเดียว เช่น 14',
      'other':
          'อ่านจำนวนวันหรือจำนวนครั้งจาก \'$text\' ไม่ได้ โปรดใส่ตัวเลข เช่น 14',
    });
    return '$_temp0';
  }

  @override
  String get mealSources => 'แหล่งที่มา';

  @override
  String get mealSourcesTitle => 'ที่มาของแคลอรี';

  @override
  String get mealSourcesNote =>
      'คำนวณจากค่าในตารางด้านล่าง แตะเพื่อเปิดชื่อนั้นในตารางต้นฉบับ อาหารที่ไม่มีในตารางเป็นค่าประมาณโดย AI';

  @override
  String mealSourcePer(String unit, String kcal) {
    return '$kcal kcal ต่อ 100 $unit';
  }

  @override
  String get mealSourceMfds => 'ฐานข้อมูลองค์ประกอบอาหารของ MFDS เกาหลี';

  @override
  String get mealSourceUsda => 'USDA FoodData Central';

  @override
  String get mealAmountInvalid => 'กรุณาใส่ตัวเลขตั้งแต่ 0 ขึ้นไป';

  @override
  String dayEnergyFull(String intake, String burned, String diff) {
    return 'กิน $intake · ออกกำลัง $burned = $diff kcal';
  }

  @override
  String dayEnergyApprox(String intake, String burned, String diff) {
    return 'กิน ≈ $intake · ออกกำลัง $burned ≈ $diff kcal';
  }

  @override
  String get dayBurnedMissing =>
      'ยังไม่ได้วัดพลังงานที่ใช้ออกกำลัง · คำนวณส่วนต่างไม่ได้';

  @override
  String dayBurnedOnly(String n) {
    return 'ออกกำลัง $n kcal · ยังไม่ได้บันทึกอาหาร';
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

  @override
  String get togetherStart => 'เริ่มพร้อมกัน';

  @override
  String get togetherAlternate => 'สลับกัน';

  @override
  String togetherWaiting(String name) {
    return 'กำลังรอ $name…';
  }

  @override
  String get togetherWaitingHint =>
      'คำขอจะขึ้นบนหน้าจอของอีกฝ่าย ถ้าไม่ขึ้น ให้ตรวจว่าแอปของอีกฝ่ายเป็นเวอร์ชันล่าสุด';

  @override
  String togetherInvite(String name) {
    return '$name ชวนทำด้วยกัน';
  }

  @override
  String get togetherInviteAlternate => 'สลับกัน · อีกฝ่ายเริ่มก่อน';

  @override
  String get togetherLeave => 'หยุด';

  @override
  String get togetherRejoin => 'กลับเข้าร่วม';

  @override
  String togetherWith(String name) {
    return 'ทำด้วยกันกับ $name';
  }

  @override
  String get togetherTheirTurn => 'ตาของอีกฝ่าย';

  @override
  String togetherLeftBeat(String name, int n) {
    return '$name หยุดที่จังหวะที่ $n';
  }

  @override
  String togetherLeftRound(String name, int n) {
    return '$name หยุดที่รอบที่ $n';
  }

  @override
  String get togetherMe => 'ฉัน';

  @override
  String get togetherLog => 'บันทึก';

  @override
  String get mealLogAs => 'บันทึกเป็นมื้ออาหาร';

  @override
  String get mealAutoLogged => 'บันทึกเป็นมื้ออาหารแล้ว';

  @override
  String get mealAutoUndo => 'เปลี่ยนเป็นการออกกำลังกาย';

  @override
  String get proxyWrite => 'บันทึกแทน';

  @override
  String proxyWriting(String name) {
    return 'กำลังบันทึกของ $name';
  }

  @override
  String get proxyDefaultName => 'คู่ฝึก';

  @override
  String get proxyHand => 'ส่งให้';

  @override
  String get proxyBack => 'กลับไปของฉัน';

  @override
  String proxyShareText(String url) {
    return 'บันทึกการออกกำลังที่จดแทนให้ตอนฝึกด้วยกัน เปิดใน setpad เพื่อรับเข้าบันทึกของคุณ\n$url';
  }

  @override
  String handoffOffer(String name) {
    return '$name จดบันทึกการออกกำลังให้คุณ';
  }

  @override
  String get handoffTake => 'รับ';

  @override
  String get handoffFailed =>
      'รับบันทึกไม่ได้ ลิงก์อาจหมดอายุหรือเครือข่ายมีปัญหา';

  @override
  String get handoffSignIn => 'ต้องเข้าสู่ระบบเพื่อรับบันทึกที่ส่งมาให้';

  @override
  String partnerInviteMore(String code) {
    return 'ชวนอีกคน · รหัส $code';
  }

  @override
  String get proxyWhose => 'จะบันทึกของใคร?';

  @override
  String planMemberAccepted(String name) {
    return '$name เห็นด้วยแล้ว';
  }

  @override
  String planMemberWaiting(String name) {
    return '$name ยังไม่ยืนยัน';
  }

  @override
  String deleteNoteAsk(String title) {
    return 'ลบ \"$title\" หรือไม่?';
  }

  @override
  String get mealsTitle => 'อาหาร';

  @override
  String get energyBurned => 'ออกกำลังกาย';

  @override
  String get energyDifference => 'ส่วนต่าง';

  @override
  String get fold => 'ย่อ';

  @override
  String get energySurplus => 'เกิน';

  @override
  String get energyDeficit => 'ขาด';

  @override
  String get milestoneBest => 'น้ำหนักสูงสุด';

  @override
  String get energyDiffFormula => 'ที่กิน − ออกกำลังกาย';

  @override
  String get energyDiffExplain =>
      'แคลอรีที่บันทึกว่ากิน ลบด้วยแคลอรีที่ใช้ไปกับการออกกำลังกาย ค่าบวกคือกินมากกว่าที่ออกกำลังกายใช้ไป ค่าลบคือกินน้อยกว่า\n\nยังไม่รวมการเผาผลาญขณะพักและกิจกรรมประจำวัน จึงไม่ใช่น้ำหนักที่ขึ้นหรือลง';

  @override
  String get estimateTag => 'ประมาณ';

  @override
  String get energyNotLogged => 'ยังไม่บันทึก';

  @override
  String get energyNotMeasured => 'ยังไม่วัด';

  @override
  String get recordMenu => 'เพิ่มเติม';

  @override
  String dayIntakeOnly(String intake) {
    return 'กิน $intake kcal · ยังไม่ได้วัดพลังงานที่ใช้ออกกำลัง';
  }

  @override
  String dayIntakeOnlyApprox(String intake) {
    return 'กิน ≈ $intake kcal · ยังไม่ได้วัดพลังงานที่ใช้ออกกำลัง';
  }

  @override
  String dayUnknownMeals(int m) {
    return 'ไม่ทราบแคลอรี $m รายการ';
  }

  @override
  String get healthDataTitle => 'ข้อมูลสุขภาพ';

  @override
  String get healthDataIntro =>
      'สิ่งที่ setpad แลกเปลี่ยนกับแอปสุขภาพ (Apple Health, Health Connect) และเหตุผล';

  @override
  String get healthDataWrite =>
      'เขียน · การออกกำลังกาย — เมื่อบันทึกเสร็จ จะบันทึกเป็นเซสชันการออกกำลังกาย';

  @override
  String get healthDataCalories =>
      'อ่าน · แคลอรี่ที่เผาผลาญ — แคลอรี่ที่นาฬิกาวัดได้ระหว่างออกกำลังกายจะถูกเพิ่มในบันทึกนั้น ถ้าไม่มีการวัด จะไม่แสดงแคลอรี่';

  @override
  String get healthDataHeart =>
      'อ่าน · อัตราการเต้นของหัวใจ — ระหว่างพักในทาบาตะ เมื่อหัวใจเต้นต่ำกว่าค่าสูงสุดของรอบนั้น 25 bpm จะจบการพักและแจ้งเริ่มรอบถัดไป ระหว่างพักจะแสดง ♥ ปัจจุบัน → เป้าหมาย ในแถบตัวจับเวลา ถ้าไม่มีค่าหัวใจหรือค่าเก่ากว่า 90 วินาที การพักจะจบตามเวลา';

  @override
  String get healthDataStays =>
      'ค่าที่อ่านจากแอปสุขภาพจะไม่ออกจากอุปกรณ์นี้ ไม่ส่งไปยังเซิร์ฟเวอร์ และไม่ใช้เพื่อโฆษณาหรือการตลาด';

  @override
  String get healthDataRevokeIos =>
      'ปิดสิทธิ์ได้ทุกเมื่อที่ การตั้งค่า iPhone → ความเป็นส่วนตัวและความปลอดภัย → สุขภาพ → setpad';

  @override
  String get healthDataRevokeAndroid =>
      'ปิดสิทธิ์ได้ทุกเมื่อที่ Health Connect → สิทธิ์ของแอป → setpad';

  @override
  String get healthDataPrivacy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get restAlarmTitle => 'รอบถัดไป — หัวใจเต้นช้าลงแล้ว';

  @override
  String liveSetBusy(String name) {
    return '$name กำลังแก้เซ็ตนี้อยู่ แตะอีกครั้งเมื่อแก้เสร็จ';
  }

  @override
  String liveExerciseBusy(String name) {
    return '$name กำลังบันทึกท่านี้อยู่ตอนนี้';
  }

  @override
  String liveExerciseRemoved(String exercise) {
    return 'คนที่ออกกำลังด้วยกันลบ $exercise แล้ว ข้อความที่พิมพ์อยู่ยังอยู่ในช่องพิมพ์';
  }

  @override
  String get trainerReport => 'รายงานเทรนเนอร์';

  @override
  String get trainerUnread => 'รายงานใหม่';

  @override
  String trainerRanAt(String when) {
    return 'สรุปเมื่อ $when';
  }

  @override
  String get trainerRunNow => 'สรุปตอนนี้';

  @override
  String get trainerNoReport => 'ยังไม่มีรายงาน สรุปตอนนี้เลยไหม';

  @override
  String get trainerOutdated => 'รายงานนี้ต้องใช้เวอร์ชันใหม่ โปรดอัปเดตแอป';

  @override
  String get trainerFailed =>
      'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ โปรดลองอีกครั้งภายหลัง';

  @override
  String get trainerActUnknown => 'ยืนยันผลไม่ได้ กดอีกครั้งก็จะไม่บันทึกซ้ำ';

  @override
  String get trainerDone => 'สิ่งที่เอเจนต์ทำแล้ว';

  @override
  String get trainerToday => 'คลาสวันนี้';

  @override
  String get trainerTodo => 'สิ่งที่ต้องตรวจ';

  @override
  String get trainerAllClear => 'จัดการทุกอย่างที่ต้องตรวจแล้ว';

  @override
  String get trainerAttendance => 'คลาสที่ยังไม่ปิด';

  @override
  String trainerVisited(String time) {
    return 'ยืนยันการมา $time';
  }

  @override
  String trainerFinishAll(int count) {
    return 'เสร็จทั้งหมด ($count)';
  }

  @override
  String trainerFinishAsk(int count) {
    return 'ทำเสร็จ $count รายการ — จะหักจากแพ็กเกจ PT รายการละ 1 ครั้ง';
  }

  @override
  String get trainerFinish => 'ทำเสร็จ';

  @override
  String get trainerJoinRequest =>
      'คำขอสมัคร — โปรดตรวจที่หน้า \"วันนี้\" ใน CRM บนเว็บ';

  @override
  String get trainerBook => 'จอง';

  @override
  String get trainerSend => 'ส่ง';

  @override
  String get trainerPaid => 'รับชำระแล้ว';

  @override
  String get trainerContacted => 'ติดต่อแล้ว';

  @override
  String get trainerLater => 'ภายหลัง';

  @override
  String trainerPrice(int price) {
    final intl.NumberFormat priceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String priceString = priceNumberFormat.format(price);

    return '₩$priceString';
  }

  @override
  String trainerStarts(String d) {
    return 'ตั้งแต่ $d';
  }

  @override
  String get trainerPayHow => 'ชำระด้วยวิธีใด';

  @override
  String get trainerPaidListPrice =>
      'จะบันทึกการชำระเต็มราคาสินค้า หากมีส่วนลดหรือแบ่งชำระ โปรดบันทึกที่แท็บสมาชิกภาพในหน้าสมาชิกของ CRM บนเว็บ';

  @override
  String get payCard => 'บัตร';

  @override
  String get payCash => 'เงินสด';

  @override
  String get payTransfer => 'โอนเงิน';

  @override
  String get payOther => 'อื่น ๆ';

  @override
  String get agentSettings => 'ตั้งค่าเอเจนต์';

  @override
  String get agentEnabled => 'สรุปตามเวลาที่ตั้งไว้';

  @override
  String get agentTimes => 'เวลาสรุป';

  @override
  String get agentAddTime => 'เพิ่มเวลา';

  @override
  String get agentDays => 'วัน';

  @override
  String get agentAutoConfirm => 'ยืนยันคำขอ PT ทันที';

  @override
  String get agentModes => 'แยกตามงาน';

  @override
  String get agentModesHelp =>
      'ด้วยตัวเอง — เอเจนต์ไม่แตะต้อง ร่าง — เอเจนต์เตรียมไว้ให้คุณแตะเพื่อจัดการ อัตโนมัติ — เอเจนต์จัดการให้';

  @override
  String get agentModeOff => 'ด้วยตัวเอง';

  @override
  String get agentModeDraft => 'ร่าง';

  @override
  String get agentModeAuto => 'อัตโนมัติ';

  @override
  String get taskPtSchedule => 'ตาราง PT';

  @override
  String get taskRenewal => 'ต่ออายุ';

  @override
  String get taskAttendance => 'การเข้าเรียน';

  @override
  String get taskRoutine => 'เตรียมรูทีน';

  @override
  String get taskContact => 'ติดต่อสมาชิก';

  @override
  String get gymPolicy => 'นโยบายยิม';

  @override
  String get policyRenewalDays => 'ช่วงเวลาแจ้งต่ออายุ (กี่วันก่อนหมดอายุ)';

  @override
  String get policyLowSessions => 'เกณฑ์ PT ใกล้หมด (จำนวนครั้งที่จองได้)';

  @override
  String get policyAwayDays => 'ไม่มาเกิน (วัน)';

  @override
  String get policyLapsedDays => 'ถือว่าเลิกมาหลัง (วัน)';

  @override
  String get policyOffer => 'ข้อความเสนอต่ออายุ';

  @override
  String get policySave => 'บันทึกนโยบาย';

  @override
  String get policySaved => 'บันทึกแล้ว';

  @override
  String get trainerWhichGym => 'ยิมไหน';

  @override
  String get trainerBack => 'ย้อนกลับ';

  @override
  String get trainerCopy => 'คัดลอกข้อความ';

  @override
  String get trainerCopied => 'คัดลอกแล้ว';

  @override
  String get settingsTrainer => 'เทรนเนอร์';

  @override
  String get aiSetting => 'ตัวช่วย AI';

  @override
  String get aiOff =>
      'ตัวช่วย AI ปิดอยู่ จึงเก็บไว้ตามที่พิมพ์ เปิดได้ที่ การตั้งค่า › ตัวช่วย AI';

  @override
  String get aiOffPhoto =>
      'ตัวช่วย AI ปิดอยู่ จึงไม่ได้ประมาณจากรูป พิมพ์มื้ออาหารเป็นข้อความ เช่น ‘ข้าวผัด 550kcal’ แล้วจะถูกบันทึกตามนั้น';

  @override
  String get answerNeedsTwoDays => 'ต้องมีอย่างน้อยสองวัน';

  @override
  String get answerNoBase => 'ไม่มีค่าอ้างอิง';

  @override
  String answerPerWeek(String value) {
    return '$value ต่อสัปดาห์';
  }

  @override
  String answerPerMonth(String value) {
    return '$value ต่อเดือน';
  }

  @override
  String answerTimesAfter(int n) {
    return 'ทำ $n ครั้งหลังสถิติสูงสุด';
  }

  @override
  String get answerTimesUnit => ' ครั้ง';

  @override
  String answerTimes(int n) {
    return '$n ครั้ง';
  }

  @override
  String answerStreak(int n) {
    return 'ติดต่อกัน $n วัน';
  }

  @override
  String answerRestDays(int n) {
    return 'พัก $n วัน';
  }

  @override
  String get answerUntilToday => 'วันนี้';

  @override
  String answerEveryDays(String value) {
    return 'ปกติทุก $value วัน';
  }

  @override
  String answerMeanEvery(String value) {
    return 'เฉลี่ยทุก $value วัน';
  }

  @override
  String answerGapSpread(int a, int b, int c, int d) {
    return 'ติดกัน $a ครั้ง · พัก 1 วัน $b ครั้ง · พัก 2 วัน $c ครั้ง · พัก 3 วันขึ้นไป $d ครั้ง';
  }

  @override
  String answerLongestIncluded(int n) {
    return 'รวมช่วงพักยาวที่สุด $n วัน';
  }

  @override
  String get answerNoMeals => 'ไม่มีวันที่บันทึกมื้ออาหาร';

  @override
  String answerAbout(String value) {
    return 'ประมาณ $value';
  }

  @override
  String answerMealDays(int n) {
    return '$n วันที่บันทึกมื้ออาหาร';
  }

  @override
  String queryUnknownMeals(int n) {
    return 'มื้อที่ไม่รู้แคลอรี $n มื้อไม่ได้รวมในผลรวม';
  }

  @override
  String get answerNoWatch => 'ไม่มีบันทึกที่วัดด้วยนาฬิกา';

  @override
  String answerWatchDays(int n) {
    return '$n วันที่วัดด้วยนาฬิกา';
  }

  @override
  String get answerNoBoth => 'ไม่มีวันที่มีทั้งการกินและการเผาผลาญ';

  @override
  String answerBothDays(int n) {
    return '$n วันที่มีทั้งการกินและการเผาผลาญ';
  }

  @override
  String answerIntakeOnlyDays(int n) {
    return 'ไม่นับ $n วันที่มีแต่การกิน';
  }

  @override
  String answerMonths(int n) {
    return '$n เดือน';
  }

  @override
  String get metricChangePct => 'อัตราเปลี่ยนแปลง';

  @override
  String get metricDaysSinceBest => 'วันนับจากสถิติสูงสุด';

  @override
  String get metricSessionsSinceBest => 'ครั้งหลังสถิติสูงสุด';

  @override
  String get metricMeanReps => 'ครั้งต่อเซ็ต';

  @override
  String get metricLongestStreak => 'ติดต่อกันนานสุด';

  @override
  String get metricLongestGap => 'ช่วงพักนานสุด';

  @override
  String get metricMeanGap => 'ระยะห่างการออกกำลัง';

  @override
  String get metricIntake => 'แคลอรีที่กิน';

  @override
  String get metricBurned => 'แคลอรีที่เผาผลาญ';

  @override
  String get metricBalance => 'กิน − เผาผลาญ';

  @override
  String get queryAlone => 'วันที่ทำคนเดียว';

  @override
  String get queryTogether => 'วันที่ทำกับคู่';

  @override
  String get queryByPart => 'ตามส่วนของร่างกาย';

  @override
  String get queryCanSee =>
      'บันทึกบอกได้ถึงน้ำหนัก ครั้ง เซ็ต วันที่ออกกำลัง และแคลอรีมื้ออาหาร';

  @override
  String get queryDiffColumn => 'ส่วนต่าง';

  @override
  String get queryFutureCell => 'ยังมาไม่ถึง';

  @override
  String get queryGrowthRate =>
      'จัดอันดับการเติบโตด้วยอัตราต่อสัปดาห์ เพื่อให้ช่วงเวลาต่างกันเทียบได้';

  @override
  String get queryHandoff => 'เฉพาะบันทึกที่ได้รับมา';

  @override
  String get queryNoHandoff => 'ไม่รวมบันทึกที่ได้รับมา';

  @override
  String queryHandoffCount(int n) {
    return 'ไม่รวมบันทึกที่ได้รับมา $n รายการ';
  }

  @override
  String get queryHoursNote =>
      'เวลาคือเวลาที่สร้างบันทึก ถ้าบันทึกย้อนหลังจะนับตามเวลาที่บันทึก';

  @override
  String get queryMixedWeights => 'น้ำหนักนี้รวมหลายท่า';

  @override
  String get queryNcBodyweight =>
      'ไม่มีน้ำหนักตัวในบันทึก ใส่น้ำหนักในคำถามแล้วจะเทียบให้ (เช่น หนัก 80 เดดลิฟต์ได้กี่เท่า)';

  @override
  String get queryNcWeightForecast =>
      'ไม่คำนวณว่าน้ำหนักจะเป็นเท่าไร เพราะบันทึกมีแค่สิ่งที่กินและแคลอรีจากการออกกำลังกาย ไม่มีการเผาผลาญขณะพักและกิจกรรมประจำวัน';

  @override
  String get queryNcHeartRate =>
      'การค้นหาบันทึกยังไม่ดูชีพจร และดูรายท่าหรือรายช่วงพักไม่ได้เพราะเซ็ตไม่มีเวลา';

  @override
  String get queryNeverMark => 'ไม่เคยบันทึก';

  @override
  String get queryNoBaseRatio => 'ไม่มีค่าอ้างอิงจึงหาอัตราส่วนไม่ได้';

  @override
  String get queryNoneCell => 'ไม่มีบันทึกในช่วงนี้';

  @override
  String get queryNoRoutine => 'วันที่ไม่ใช้รูทีน';

  @override
  String get queryRoutine => 'วันที่ใช้รูทีนเทรนเนอร์';

  @override
  String get queryOngoing => 'กำลังดำเนินอยู่';

  @override
  String get queryOverlap =>
      'วันออกกำลังซ้อนกันจึงหาสัดส่วนไม่ได้ ลองถามด้วยจำนวนเซ็ต';

  @override
  String queryPart(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'chest': 'อก',
      'back': 'หลัง',
      'legs': 'ขา',
      'shoulders': 'ไหล่',
      'arms': 'แขน',
      'core': 'แกนกลาง',
      'cardio': 'คาร์ดิโอ',
      'upper': 'ร่างกายส่วนบน',
      'lower': 'ร่างกายส่วนล่าง',
      'other': 'ส่วนของร่างกาย',
    });
    return '$_temp0';
  }

  @override
  String get queryRatioColumn => 'อัตราส่วน';

  @override
  String get queryRatioUnits => 'หน่วยต่างกันจึงหาอัตราส่วนไม่ได้';

  @override
  String get queryRestDay => 'วันพัก';

  @override
  String get queryTrained => 'วันที่ออกกำลัง';

  @override
  String get querySetFirst => 'เซ็ตแรก';

  @override
  String get querySetLast => 'เซ็ตสุดท้าย';

  @override
  String get queryShare => 'สัดส่วน';

  @override
  String get queryZeroFilled => 'นับท่าที่ไม่ได้ทำเป็น 0';

  @override
  String queryAgainst(String value) {
    return 'เทียบกับ $value';
  }

  @override
  String queryAgainstLine(
    String value,
    String target,
    String ratio,
    String diff,
  ) {
    return '$value ÷ $target = $ratio เท่า · ต่าง $diff';
  }

  @override
  String queryAlias(String name, String names) {
    return '$name = $names';
  }

  @override
  String queryDayCount(int n) {
    return '$n วัน';
  }

  @override
  String queryDroppedSets(int n) {
    return 'ไม่นับ $n เซ็ตที่ค่าต่างชนิด';
  }

  @override
  String queryHours(int from, int to) {
    return '$from:00–$to:00 น.';
  }

  @override
  String queryMaybe(String name) {
    return 'หมายถึง $name หรือเปล่า';
  }

  @override
  String queryMemoAll(String terms) {
    return 'บันทึกมีครบ: $terms';
  }

  @override
  String queryMemoHit(String text, int n) {
    return '$text ($n วัน)';
  }

  @override
  String queryMemoHits(String hits) {
    return 'บันทึกที่ตรง: $hits';
  }

  @override
  String queryNeverPartial(String names) {
    return '$names: ไม่เคยบันทึก จึงนับโดยไม่รวม';
  }

  @override
  String queryNeverRows(String names) {
    return '$names: ไม่เคยบันทึก';
  }

  @override
  String queryNoMemo(String terms) {
    return 'บันทึกไม่มี: $terms';
  }

  @override
  String queryNoRepsSets(int n) {
    return 'ไม่นับ $n เซ็ตที่ไม่ได้ใส่จำนวนครั้ง';
  }

  @override
  String queryNotComputable(String things) {
    return 'ไม่มีในบันทึกจึงดูไม่ได้: $things';
  }

  @override
  String queryNotComputableTail(String things) {
    return 'ดูไม่ได้: $things';
  }

  @override
  String queryNothingComputable(String things) {
    return 'บันทึกตอบเรื่องนี้ไม่ได้: $things';
  }

  @override
  String queryNoWeightSets(int n, int reps) {
    return 'ไม่นับ $n เซ็ตที่ไม่มีน้ำหนัก (สูงสุด $reps ครั้ง)';
  }

  @override
  String queryNth(int n) {
    return 'วันออกกำลังลำดับที่ $n จากท้าย';
  }

  @override
  String queryOtherDistance(int n, String value) {
    return '$n ครั้งที่ใส่ระยะทาง: $value';
  }

  @override
  String queryOtherDuration(int n, String value) {
    return '$n ครั้งที่ใส่เวลา: $value';
  }

  @override
  String queryPartial(String names) {
    return 'ไม่รวม $names';
  }

  @override
  String queryPartialChunk(int n) {
    return '($n วัน)';
  }

  @override
  String queryPartMembers(String part, String names) {
    return '$part: $names';
  }

  @override
  String queryPer(String per) {
    String _temp0 = intl.Intl.selectLogic(per, {
      'day': 'ต่อวัน',
      'week': 'ต่อสัปดาห์',
      'month': 'ต่อเดือน',
      'other': 'เฉลี่ย',
    });
    return '$_temp0';
  }

  @override
  String queryPerSuffix(String per) {
    String _temp0 = intl.Intl.selectLogic(per, {
      'day': '/วัน',
      'week': '/สัปดาห์',
      'month': '/เดือน',
      'other': '/',
    });
    return '$_temp0';
  }

  @override
  String queryRatioHead(String a, String b) {
    return '$a ÷ $b';
  }

  @override
  String queryRatioLine(String a, String b, String value, String percent) {
    return '$a ÷ $b = $value เท่า ($percent%)';
  }

  @override
  String queryRelative(String by, int n) {
    String _temp0 = intl.Intl.selectLogic(by, {
      'day': 'วันที่ $n',
      'week': 'สัปดาห์ที่ $n',
      'month': 'เดือนที่ $n',
      'other': 'ลำดับที่ $n',
    });
    return '$_temp0';
  }

  @override
  String queryRolled(String year) {
    return 'ยังมาไม่ถึงจึงอ่านเป็นปี $year';
  }

  @override
  String querySamePeriod(int days, String earlier, String later) {
    return 'เทียบ $days วันเท่ากัน: $earlier → $later';
  }

  @override
  String queryShortGrowth(String names) {
    return 'สั้นเกินไปจึงไม่จัดอันดับ (น้อยกว่า 3 วันหรือ 3 สัปดาห์): $names';
  }

  @override
  String queryTimer(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tabata': 'ทาบาตะ',
      'bpm': 'ตัวจับเวลา BPM',
      'other': 'ไม่มีตัวจับเวลา',
    });
    return '$_temp0';
  }

  @override
  String queryUnknownPart(String names) {
    return 'ไม่นับท่าที่ไม่รู้ส่วนของร่างกาย: $names';
  }

  @override
  String queryUnranked(int n, String names) {
    return '$n รายการที่ไม่ได้จัดอันดับเพราะค่าหาย: $names';
  }

  @override
  String queryWindowLengths(String lengths) {
    return 'ช่วงเวลายาวไม่เท่ากัน ($lengths วัน) จึงคิดส่วนต่างและอัตราส่วนต่อสัปดาห์';
  }

  @override
  String queryZeroBuckets(String by, int total, int zeros) {
    String _temp0 = intl.Intl.selectLogic(by, {
      'week': '$zeros จาก $total สัปดาห์เป็น 0',
      'month': '$zeros จาก $total เดือนเป็น 0',
      'other': '$zeros จาก $total เป็น 0',
    });
    return '$_temp0';
  }

  @override
  String queryPossibleDays(int m, String percent) {
    return '$percent% จาก $m วันที่เป็นไปได้';
  }

  @override
  String get queryOfflineLocal =>
      'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ จึงนับในเครื่องจากท่าและช่วงเวลาที่พิมพ์ไว้เท่านั้น เมื่อเชื่อมต่อได้แล้วกด Enter เพื่อถามอีกครั้ง';

  @override
  String get queryMisread =>
      'อ่านคำถามนี้ให้เป็นสิ่งที่นับได้ไม่ได้ ลองถามด้วยคำอื่น';

  @override
  String get queryMisreadLocal =>
      'อ่านคำถามให้เป็นสิ่งที่นับได้ไม่ได้ จึงนับในเครื่องจากท่าและช่วงเวลาในข้อความเท่านั้น ถามด้วยคำอื่นเพื่อให้อ่านใหม่';

  @override
  String get queryUnreadable =>
      'โมเดลส่งคำตอบที่อ่านไม่ได้มาสองครั้ง ไม่ใช่ปัญหาการเชื่อมต่อ และคำตอบนั้นไม่ได้ใช้แผ่นน้ำหนัก';

  @override
  String get queryAskAgain => 'ถามอีกครั้ง';

  @override
  String get queryUnreadablePaid =>
      'โมเดลส่งคำตอบที่อ่านไม่ได้มาสองครั้ง ไม่ใช่ปัญหาการเชื่อมต่อ คำตอบนั้นไม่ได้ใช้แผ่นน้ำหนัก แผ่นน้ำหนักด้านล่างใช้ไปกับขั้นแรกที่จัดประเภทคำถาม';

  @override
  String get queryUnreadableLocal =>
      'ระหว่างนี้ได้นับในเครื่องจากท่าและช่วงเวลาในข้อความแล้ว';

  @override
  String get queryTotalUnits => 'หน่วยต่างกัน จึงรวมไม่ได้';

  @override
  String queryMemoDropped(String words) {
    return 'ตัดเงื่อนไขโน้ตออก: $words';
  }

  @override
  String queryAgainstDropped(String value) {
    return 'ตัดค่าอ้างอิง $value ออก — ไม่ใช่น้ำหนักที่เขียนไว้ในคำถาม';
  }

  @override
  String routineDate(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.Md(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get routineHeaderToday => 'รูทีนวันนี้';

  @override
  String routineHeaderDay(String day) {
    return 'รูทีน$day';
  }

  @override
  String routineTomorrow(String date) {
    return 'พรุ่งนี้ ($date)';
  }

  @override
  String routineWhyRotation(String date, int days) {
    return 'ไม่ได้เล่นแบบวันที่ $date มา $days วันแล้ว — จัดให้เหมือนวันนั้น';
  }

  @override
  String routineWhyFrom(String date) {
    return 'เหมือนวันที่ $date';
  }

  @override
  String routineWhyNamed(String date) {
    return 'เติมด้วยท่าที่เล่นคู่กันในวันที่ $date';
  }

  @override
  String routinePartRest(String list) {
    return '28 วันล่าสุด: $list ที่แล้ว';
  }

  @override
  String routinePartDays(String part, int days) {
    return '$part $days วัน';
  }

  @override
  String routineEstimate(int minutes) {
    return 'ประมาณ $minutes นาที';
  }

  @override
  String routinePaceOwn(int sessions, String pace) {
    return 'ประมาณจากเซ็ตละ $pace ของการเล่น $sessions ครั้งล่าสุด';
  }

  @override
  String routinePaceDefault(String pace) {
    return 'ประมาณจากค่าเริ่มต้นเซ็ตละ $pace — บันทึกสักไม่กี่ครั้งจะใช้จังหวะของคุณ';
  }

  @override
  String routineMinSec(int m, int s) {
    return '$m นาที $s วินาที';
  }

  @override
  String routineReadAs(String list) {
    return 'อ่านได้ว่า: $list';
  }

  @override
  String routineCopied(String date) {
    return 'เหมือนวันที่ $date';
  }

  @override
  String routineRepsMatched(String date, int reps) {
    return 'น้ำหนักที่ทำได้ $reps ครั้งเมื่อ $date';
  }

  @override
  String get routineTyped => 'ตามที่พิมพ์';

  @override
  String get routineFirst => 'ครั้งแรก';

  @override
  String routineBlank(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'light': 'เว้นน้ำหนักไว้ (วันเบาๆ)',
      'pain': 'เว้นน้ำหนักไว้ (มีอาการเจ็บ)',
      'gear': 'เว้นน้ำหนักไว้ (อุปกรณ์ต่างกัน)',
      'bodyweight': 'เว้นน้ำหนักอุปกรณ์ไว้',
      'stale': 'เว้นน้ำหนักไว้ (นานแล้ว)',
      'repsUnmatched': 'เว้นน้ำหนักไว้ (ไม่มีวันที่ทำครั้งและเซ็ตเท่านั้น)',
      'other': 'เว้นน้ำหนักไว้',
    });
    return '$_temp0';
  }

  @override
  String routineReference(String sets, String date) {
    return 'อ้างอิง: $sets ($date)';
  }

  @override
  String routineBest(String set, String date) {
    return 'อ้างอิง: สูงสุด $set ($date)';
  }

  @override
  String routineStepped(String step, String evidence) {
    return '+$step ($evidence)';
  }

  @override
  String routineMemo(String date, String memo) {
    return 'โน้ต $date: $memo';
  }

  @override
  String routineRecent(String part, String when) {
    return '$part · $when';
  }

  @override
  String routineDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n วันก่อน',
      one: 'เมื่อวาน',
      zero: 'วันนี้',
    );
    return '$_temp0';
  }

  @override
  String get routineFuture =>
      'นี่คือตัวอย่าง — พิมพ์ \'รูทีน\' ในวันนั้นเพื่อเริ่มเป็นบันทึกของวันนั้น';

  @override
  String routineRefused(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'diet': 'ไม่จัดตารางอาหาร — บันทึกมื้ออาหารเพื่อดูแคลอรีได้',
      'medical':
          'ไม่ตัดสินเรื่องกายภาพหรือการออกกำลังหลังผ่าตัด — บันทึกท่าที่หมอหรือนักกายภาพให้มา แล้วจะทำเป็นรูทีนให้',
      'drug': 'ช่วยเรื่องยาไม่ได้',
      'program': 'จัดทีละวัน — นี่คือรูทีนวันนี้',
      'logging': 'จะไม่บันทึกเซ็ตที่ยังไม่ได้เล่นว่าเสร็จ — แตะตอนที่เล่น',
      'format':
          'ไม่มีตัวจับเวลา EMOM ซูเปอร์เซ็ต หรือเซอร์กิต — จัดแค่ลำดับ (ทาบาตะและ bpm ใช้ได้)',
      'person': 'ไม่จัดรูทีนให้คนอื่น — แสดงแค่ชื่อท่าจากบันทึกของคุณ',
      'other': 'ช่วยได้เฉพาะบันทึกการออกกำลังและรูทีน',
    });
    return '$_temp0';
  }

  @override
  String routineNotStated(String what) {
    return 'ตัดออก ไม่มีในที่พิมพ์: $what';
  }

  @override
  String routineUnmet(String what) {
    return 'ใช้เงื่อนไขนี้ไม่ได้: $what';
  }

  @override
  String routineKeyName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'when': 'วัน',
      'from': 'วันก่อนหน้า',
      'parts': 'ส่วนของร่างกาย',
      'pattern': 'ดัน/ดึง',
      'exercises': 'ท่า',
      'exclude': 'ท่าที่ตัดออก',
      'avoid': 'ส่วนที่เลี่ยง',
      'pain': 'อาการเจ็บ',
      'equipment': 'อุปกรณ์',
      'count': 'จำนวนท่า',
      'minutes': 'เวลา',
      'intensity': 'ความหนัก',
      'timer': 'ตัวจับเวลา',
      'targets': 'ตัวเลขที่พิมพ์',
      'delta': 'น้ำหนักที่เพิ่มลด',
      'other': 'เงื่อนไข',
    });
    return '$_temp0';
  }

  @override
  String routineUnknownName(String name) {
    return 'ไม่มีในพจนานุกรม ตัดออก: $name';
  }

  @override
  String get routineNoSuchDay => 'ไม่มีวันนั้น — จัดจากบันทึกแทน';

  @override
  String routineExcludeAbsent(String name) {
    return 'ไม่มีท่านี้อยู่แล้ว: $name';
  }

  @override
  String routineNoneMatched(String what) {
    return 'ไม่มีท่า$whatในบันทึก — เลือกเพิ่มได้';
  }

  @override
  String routineFewer(int n) {
    return 'มีท่าจากบันทึกแค่ $n ท่า';
  }

  @override
  String routineOtherUnit(String unit) {
    return 'เซ็ตที่บันทึกเป็น $unit คงไว้ตามเดิม';
  }

  @override
  String get routineBpmRange =>
      'bpm ต้องอยู่ระหว่าง 10–120 — ใส่โดยไม่มีตัวจับเวลา';

  @override
  String routineIntensityLine(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'light':
          'เบาๆ: ลดเซ็ตสุดท้ายของแต่ละท่าลงหนึ่งเซ็ต — น้ำหนักเท่าครั้งก่อน',
      'lightBlank': 'เบาๆ: ลดเซ็ตสุดท้ายของแต่ละท่าลงหนึ่งเซ็ต',
      'hard': 'น้ำหนักเท่าครั้งก่อน',
      'max': 'ไม่กำหนดน้ำหนักที่จะลอง — เขียนสถิติสูงสุดไว้ข้างๆ',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get routineNoStep => 'พิมพ์ว่าจะเพิ่มเท่าไร (เช่น +2.5kg)';

  @override
  String routinePain(String phrase, String list) {
    return 'เพราะ \'$phrase\' จึงตัด: $list · เว้นน้ำหนักไว้ · ไม่ได้ตัดสินว่าปลอดภัยหรือไม่';
  }

  @override
  String routinePainNone(String phrase) {
    return '\'$phrase\' — ไม่ได้ตัดท่าใด เว้นน้ำหนักไว้ · ไม่ได้ตัดสินว่าปลอดภัยหรือไม่';
  }

  @override
  String get routinePainWord => 'อาการเจ็บ';

  @override
  String get routineFirstTime => 'ครั้งแรก — เลือกท่าที่จะใส่ (ไม่มีตัวเลข)';

  @override
  String routineCountFit(int count, int minutes) {
    return 'ปรับเป็น $count ท่า — ประมาณ $minutes นาที';
  }

  @override
  String routineNoMore(int minutes) {
    return 'ไม่มีท่าในบันทึกให้เพิ่มอีก — ประมาณ $minutes นาที';
  }

  @override
  String routineOverTime(int minutes) {
    return 'แค่ท่าที่ระบุก็ประมาณ $minutes นาที';
  }

  @override
  String routineOverUsual(int n, int usual) {
    return 'ใส่ครบทั้ง $n ท่าที่คุณเลือกแล้ว — มากกว่า $usual ท่าที่มักทำต่อครั้ง';
  }

  @override
  String routineRecentMemo(String when, String name, String memo) {
    return 'โน้ต$name $when: $memo';
  }

  @override
  String routineRemoved(String label, String why) {
    return 'ตัดออก: $label — $why';
  }

  @override
  String routineRemovedWhy(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'named': 'ท่าที่ระบุ',
      'avoid': 'ส่วนที่เลี่ยง',
      'unknownPart': 'ไม่รู้ส่วนของร่างกาย',
      'gear': 'อุปกรณ์ต่างกัน',
      'unknownGear': 'ไม่รู้อุปกรณ์',
      'otherPart': 'คนละส่วน',
      'user': 'ตัดเอง',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get routineRestore => 'ใส่กลับ';

  @override
  String routineAdd(String name) {
    return '+ $name';
  }

  @override
  String get routineOther => 'รูทีนอื่น';

  @override
  String get routineWhyShow => 'ดูเหตุผล';

  @override
  String get routineWhyHide => 'ซ่อนเหตุผล';

  @override
  String routinePrevious(String date) {
    return 'ก่อนหน้า ($date)';
  }

  @override
  String routineByPart(String part) {
    return 'จัดรูทีน$part';
  }

  @override
  String routineStepChip(String step) {
    return '+$step (ระยะที่คุณเพิ่มเอง)';
  }

  @override
  String routineAskToo(String text) {
    return 'ถามด้วย: $text · แผ่น';
  }

  @override
  String get routineAsQuestion => 'ถามเป็นคำถามบันทึก · แผ่น';

  @override
  String get routineNoConditions => 'จัดเลยโดยไม่มีเงื่อนไข';

  @override
  String get routineWithConditions => 'อ่านเงื่อนไขด้วย · แผ่น';

  @override
  String get routineMake => 'จัดรูทีนวันนี้';

  @override
  String routineMakePart(String part) {
    return 'จัดรูทีน$partวันนี้';
  }

  @override
  String get routineStart => 'เริ่ม';

  @override
  String get routineStarted => 'เริ่มแล้ว · เปิด';

  @override
  String get routineWorking => 'กำลังอ่านเงื่อนไข…';

  @override
  String get routineOffline =>
      'ไม่มีการเชื่อมต่อ อ่านเงื่อนไขไม่ได้ — จัดจากบันทึกอย่างเดียว';

  @override
  String get routineMisread =>
      'อ่านเงื่อนไขไม่ได้ — จัดจากบันทึกอย่างเดียว พิมพ์ใหม่เพื่ออ่านอีกครั้ง';

  @override
  String routineHeldBack(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'offline': 'ไม่มีการเชื่อมต่อ',
      'noPlates': 'แผ่นน้ำหนักไม่พอ',
      'other': 'อ่านคำตอบไม่ได้',
    });
    return '$_temp0 จึงอ่านเงื่อนไข (ท่าที่ตัด อาการเจ็บ) ไม่ได้ — ไม่ได้จัดรูทีน';
  }

  @override
  String routineTypedWeight(int count, String from, String to) {
    return 'น้ำหนักที่พิมพ์: เซ็ตหลัก $count เซ็ต $from → $to';
  }

  @override
  String get routineTypedKept => 'คงน้ำหนักที่พิมพ์ไว้';

  @override
  String get routinePlatesBefore =>
      'ข้อความนี้เคยใช้แผ่นไปแล้ว · ครั้งนี้ 0 แผ่น';

  @override
  String get routineRetry => 'ลองอีกครั้ง';

  @override
  String get routinePressEnter => 'กด Enter เพื่ออ่านเงื่อนไขด้วย · แผ่น';

  @override
  String get routineFromQuestion => 'อ่านเป็นคำขอจัดรูทีน';

  @override
  String routinePattern(String p) {
    String _temp0 = intl.Intl.selectLogic(p, {
      'push': 'ดัน',
      'pull': 'ดึง',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineGear(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'barbell': 'บาร์เบล',
      'dumbbell': 'ดัมเบล',
      'machine': 'เครื่อง',
      'cable': 'เคเบิล',
      'bodyweight': 'น้ำหนักตัว',
      'bar': 'บาร์โหน',
      'kettlebell': 'เคตเทิลเบล',
      'band': 'ยางยืด',
      'bench': 'ม้านั่ง',
      'other': 'อุปกรณ์',
    });
    return '$_temp0';
  }

  @override
  String routineGearOnly(String list) {
    return '$listเท่านั้น';
  }

  @override
  String routineGearWithout(String list) {
    return 'ไม่มี$list';
  }

  @override
  String routineMinutes(int n) {
    return '$n นาที';
  }

  @override
  String routineCount(int n) {
    return '$n ท่า';
  }

  @override
  String routineIntensity(String k) {
    String _temp0 = intl.Intl.selectLogic(k, {
      'light': 'เบาๆ',
      'hard': 'หนัก',
      'max': 'ลองทำสถิติ',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineExclude(String list) {
    return 'ตัด: $list';
  }

  @override
  String routineAvoid(String list) {
    return 'เลี่ยง: $list';
  }

  @override
  String get routinePlatesZero => '0 แผ่น';

  @override
  String get routineFullBody => 'ทั้งตัว';

  @override
  String get routineNoPlates =>
      'แผ่นน้ำหนักไม่พอ อ่านเงื่อนไขไม่ได้ — จัดจากบันทึกอย่างเดียว';

  @override
  String get routineBack => 'กลับไปที่รูทีน';

  @override
  String queryBoundDropped(String value) {
    return 'ตัดเงื่อนไข $value ออก — คำถามไม่ได้ระบุตัวเลขนี้ในหน่วยนั้น';
  }

  @override
  String get anatomyTitle => 'แผนที่ร่างกาย';

  @override
  String get anatomyOpen =>
      'แผนที่ร่างกาย — ท่าออกกำลังและเคล็ดลับท่าทางตามกล้ามเนื้อ';

  @override
  String get anatomyPick => 'เลือกท่าจากภาพร่างกาย';

  @override
  String get anatomyFront => 'ด้านหน้า';

  @override
  String get anatomyBack => 'ด้านหลัง';

  @override
  String anatomyDays(int n) {
    return '$n วัน';
  }

  @override
  String muscleName(String m) {
    String _temp0 = intl.Intl.selectLogic(m, {
      'chest': 'อก',
      'frontDelts': 'ไหล่หน้า',
      'sideDelts': 'ไหล่ข้าง',
      'rearDelts': 'ไหล่หลัง',
      'traps': 'บ่าบน',
      'upperBack': 'หลังช่วงกลาง',
      'lats': 'ปีก',
      'lowerBack': 'หลังล่าง',
      'biceps': 'ไบเซ็ป',
      'triceps': 'ไตรเซ็ป',
      'forearms': 'แขนท่อนล่าง',
      'abs': 'หน้าท้อง',
      'obliques': 'ท้องด้านข้าง',
      'hipFlexors': 'กล้ามเนื้องอสะโพก',
      'glutes': 'ก้น',
      'quads': 'ต้นขาหน้า',
      'hamstrings': 'ต้นขาหลัง',
      'adductors': 'ต้นขาด้านใน',
      'calves': 'น่อง',
      'infraspinatus': 'อินฟราสไปนาตัส',
      'teresMinor': 'เทเรสไมเนอร์',
      'teresMajor': 'เทเรสเมเจอร์',
      'tricepsLong': 'ไตรเซปส์หัวยาว',
      'tricepsLateral': 'ไตรเซปส์หัวด้านข้าง',
      'tricepsMedial': 'ไตรเซปส์หัวด้านใน',
      'other': 'กล้ามเนื้อ',
    });
    return '$_temp0';
  }

  @override
  String anatomyLevel(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'low': 'น้อย',
      'mid': 'ปานกลาง',
      'high': 'มาก',
      'other': 'ไม่มี',
    });
    return '$_temp0';
  }

  @override
  String get anatomyLegend => 'กล้ามเนื้อที่มีเซ็ตมากในช่วงนี้จะมีสีเข้มกว่า';

  @override
  String get anatomyFirstTime =>
      'ยังไม่มีเซ็ตที่ทำเสร็จ จึงยังไม่มีสี แตะกล้ามเนื้อเพื่อดูท่าที่ใช้กล้ามเนื้อนั้นและเคล็ดลับท่าทาง';

  @override
  String anatomyEmptyWindow(int n) {
    return 'ไม่มีเซ็ตที่ทำเสร็จใน $n วันที่ผ่านมา';
  }

  @override
  String anatomyUnknown(int n) {
    return 'ไม่ได้นับ $n ท่าที่ไม่รู้กล้ามเนื้อ แตะชื่อเพื่อดูบันทึกในการค้นหา';
  }

  @override
  String anatomyUnknownMore(int n) {
    return 'และอีก $n ท่า';
  }

  @override
  String anatomyCardio(int n) {
    return 'เซ็ตคาร์ดิโอที่ไม่ได้ใส่ในแผนที่: $n';
  }

  @override
  String get anatomyCountNote =>
      'กล้ามเนื้ออิงการจัดกลุ่มของ ExRx.net และ ACE และเป็นค่าประมาณ ท่าที่มี * คือการตีความว่าใช้กล้ามเนื้อใด เซ็ตหนึ่งนับเต็มสำหรับกล้ามเนื้อหลัก และครึ่งหนึ่งสำหรับกล้ามเนื้อช่วย เซ็ตวอร์มอัพก็นับด้วย';

  @override
  String get anatomyLimits =>
      'ไม่มีการวิเคราะห์วิดีโอหรือท่าทาง หากเจ็บ ให้หยุดและปรึกษาผู้เชี่ยวชาญ';

  @override
  String get anatomyTapHint =>
      'แตะที่กล้ามเนื้อ — หรือเลือกจากรายการด้านล่างก็ได้';

  @override
  String get anatomyNoSurface => 'กล้ามเนื้อชั้นลึก ไม่มีในภาพ';

  @override
  String anatomySets(int days, String sets) {
    return 'เซ็ตใน $days วัน: $sets';
  }

  @override
  String anatomySetsLine(String week, String month) {
    return 'เซ็ต — 7 วันล่าสุด: $week · 28 วัน: $month';
  }

  @override
  String anatomyBreakdown(int primary, int secondary) {
    return '28 วัน: กล้ามเนื้อหลัก $primary · ช่วย $secondary (นับครึ่ง)';
  }

  @override
  String anatomyLast(String date, String ago) {
    return 'ครั้งล่าสุด: $date ($ago)';
  }

  @override
  String get anatomyNever => 'ยังไม่มีเซ็ตของกล้ามเนื้อนี้จากท่าที่อยู่ในตาราง';

  @override
  String get anatomyDone => 'ท่าที่คุณเคยทำ';

  @override
  String get anatomyTry => 'ท่าที่ใช้กล้ามเนื้อนี้เป็นหลัก';

  @override
  String get anatomyTrySecondary => 'ท่าที่ใช้ส่วนนี้เป็นกล้ามเนื้อช่วย';

  @override
  String anatomyTryGear(String list) {
    return 'ทำได้ด้วยอุปกรณ์ที่เคยใช้ ($list)';
  }

  @override
  String get anatomyAllGear => 'ยังไม่มีอุปกรณ์ในบันทึก จึงแสดงทั้งหมด';

  @override
  String anatomyMoreGear(int n) {
    return 'ดูอีก $n ท่าที่ใช้อุปกรณ์อื่น';
  }

  @override
  String get anatomyTriedAll => 'คุณทำครบทุกท่าที่ใช้กล้ามเนื้อนี้เป็นหลักแล้ว';

  @override
  String anatomyRole(String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'primary': 'หลัก',
      'other': 'ช่วย',
    });
    return '$_temp0';
  }

  @override
  String get anatomyInterpNote =>
      '* ท่านี้ระบุกล้ามเนื้อโดยตีความจากแหล่งที่มา';

  @override
  String get anatomyCues => 'เคล็ดลับท่าทาง';

  @override
  String get anatomyMistakes => 'สิ่งที่ควรเลี่ยง';

  @override
  String anatomySources(String sites) {
    return 'ที่มา: $sites';
  }

  @override
  String get anatomyUnsourced => '‡ เพิ่มเติมโดยไม่มีที่มา';

  @override
  String get anatomyAdapted =>
      '† ตีความจากข้อความของแหล่งที่มา (รวมถึงแหล่งของท่าที่คล้ายกัน)';

  @override
  String get anatomyCuesEnglish => 'ตอนนี้เคล็ดลับท่าทางมีเฉพาะภาษาอังกฤษ';

  @override
  String get anatomyAddRoutine => 'เพิ่มในรูทีนวันนี้';

  @override
  String anatomyRoutineText(String part) {
    return 'รูทีน$partวันนี้';
  }

  @override
  String get anatomySearch => 'ดูในการค้นหา';

  @override
  String anatomyRegionValue(int days, String sets, String level) {
    return 'เซ็ตใน $days วัน: $sets, $level';
  }

  @override
  String get anatomyRegionHint => 'แตะสองครั้งเพื่อดูท่า';

  @override
  String get anatomyClose => 'ปิด';

  @override
  String anatomyTileSets(String n) {
    return '$n เซ็ต';
  }

  @override
  String get anatomyLastLabel => 'ล่าสุด';

  @override
  String get openSourceLicenses => 'สัญญาอนุญาตโอเพนซอร์ส';

  @override
  String routineFactor(String f) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength': 'ความแข็งแรง',
      'endurance': 'ความทนทานของกล้ามเนื้อ',
      'sustain': 'ความต่อเนื่อง',
      'power': 'พลังระเบิด',
      'cardio': 'หัวใจและปอด',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineFactorDay(String factor, String why) {
    return 'วัน$factor · $why';
  }

  @override
  String routineFactorWhy(String kind, String a, String b) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tabata': 'ทาบาตะ $a',
      'fill': 'ให้ครบ $a ครั้ง',
      'fillTitle': 'ชื่อ ‘$a’',
      'distance': '$a',
      'open': 'เซ็ตละ $a ครั้ง ไม่กำหนดจำนวนเซ็ต',
      'single': 'เซ็ตเดียว $a ครั้ง',
      'drop': 'สุดแต่ละเซ็ต $a',
      'hold': '$a ครั้ง × $b เซ็ต',
      'other': '$a×$b',
    });
    return '$_temp0';
  }

  @override
  String routineWhyWeekday(int weeks, String day, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other:
          '$dayที่แล้วไม่มีบันทึก — จัดจาก$dayเมื่อ $weeks สัปดาห์ก่อน ($date)',
      one: 'เหมือน$dayที่แล้ว ($date)',
    );
    return '$_temp0';
  }

  @override
  String routineWhyNear(String day, String near) {
    return 'ไม่มีบันทึก$day — จัดจากวันใกล้เคียง $near';
  }

  @override
  String routineWhyFactor(String f, String date) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength': 'สัปดาห์นี้ความแข็งแรงยังขาด — จัดจาก $date',
      'endurance': 'สัปดาห์นี้ความทนทานของกล้ามเนื้อยังขาด — จัดจาก $date',
      'sustain': 'สัปดาห์นี้ความต่อเนื่องยังขาด — จัดจาก $date',
      'cardio': 'สัปดาห์นี้หัวใจและปอดยังขาด — จัดจาก $date',
      'other': 'จัดจาก $date',
    });
    return '$_temp0';
  }

  @override
  String routineWhyFactorAll(String f, String date) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength':
          'สัปดาห์นี้ครบทุกด้านแล้ว — ถึงคิวความแข็งแรง จึงจัดเหมือน $date',
      'endurance':
          'สัปดาห์นี้ครบทุกด้านแล้ว — ถึงคิวความทนทานของกล้ามเนื้อ จึงจัดเหมือน $date',
      'sustain':
          'สัปดาห์นี้ครบทุกด้านแล้ว — ถึงคิวความต่อเนื่อง จึงจัดเหมือน $date',
      'cardio':
          'สัปดาห์นี้ครบทุกด้านแล้ว — ถึงคิวหัวใจและปอด จึงจัดเหมือน $date',
      'other': 'จัดเหมือน $date',
    });
    return '$_temp0';
  }

  @override
  String routineWeekCounts(String range, String list) {
    return '7 วันล่าสุด ($range): $list';
  }

  @override
  String routineFactorMissing(String list) {
    return 'ไม่มีวันที่ทำแยกใน 28 วันล่าสุด: $list';
  }

  @override
  String get routineFillHint =>
      'ถ้าจะเล่นให้ครบจำนวน ให้พิมพ์เป้าหมาย (เช่น สควอต ให้ครบ 100 ครั้ง)';

  @override
  String get routineTabataChip => 'ทำเป็นทาบาตะ';

  @override
  String routineLikeLastWeek(String day) {
    return 'เหมือน$dayที่แล้ว';
  }

  @override
  String routineFactorChip(String f, int n) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength': 'จัดเพื่อความแข็งแรง · สัปดาห์นี้ $n ครั้ง',
      'endurance': 'จัดเพื่อความทนทานของกล้ามเนื้อ · สัปดาห์นี้ $n ครั้ง',
      'sustain': 'จัดเพื่อความต่อเนื่อง · สัปดาห์นี้ $n ครั้ง',
      'cardio': 'จัดเพื่อหัวใจและปอด · สัปดาห์นี้ $n ครั้ง',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineLightKept(String list) {
    return 'คงไว้ตามเดิม (เซ็ตเดียว ให้ครบจำนวน หรือทาบาตะ): $list';
  }

  @override
  String routineWhyWeekdaySkip(String how, int weeks, String day, String date) {
    String _temp0 = intl.Intl.selectLogic(how, {
      'alt': 'รูทีนอื่น: $dayเมื่อ $weeks สัปดาห์ก่อน ($date)',
      'other':
          '$dayที่แล้วมีแต่ท่าที่ตัดออก — จัดจาก$dayเมื่อ $weeks สัปดาห์ก่อน ($date)',
    });
    return '$_temp0';
  }

  @override
  String routineWhyNearSkip(String how, String day, String near) {
    String _temp0 = intl.Intl.selectLogic(how, {
      'alt': 'รูทีนอื่น: วันใกล้เคียง $near',
      'other': 'บันทึก$dayมีแต่ท่าที่ตัดออก — จัดจากวันใกล้เคียง $near',
    });
    return '$_temp0';
  }

  @override
  String routineWhyFactorNoDay(String factor, String date) {
    return 'ด้านที่ยังขาดไม่มีวันที่ใช้ได้ใน 28 วันล่าสุด — จึงจัดเหมือนวัน$factor $date';
  }

  @override
  String routineFactorLost(String factor, String date) {
    return 'จัดจากวัน$factor $date แต่ท่า$factorถูกตัดออก';
  }

  @override
  String routineFactorFiltered(String list) {
    return 'ตัดท่าที่ขอให้ตัดแล้วไม่เหลือวันใน 28 วันล่าสุด: $list';
  }

  @override
  String routineLightDropped(String date) {
    return 'น้อยกว่าวันที่ $date หนึ่งเซ็ต';
  }

  @override
  String routineDoneToday(String list) {
    return 'มีท่าที่ทำไปแล้ววันนี้: $list';
  }
}
