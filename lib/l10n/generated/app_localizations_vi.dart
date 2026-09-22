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
  String get noteHint => 'Ghi chú cho hiệp này';

  @override
  String get activeEnergy => 'Năng lượng hoạt động';

  @override
  String get energyUnavailable => 'Chưa có dữ liệu';

  @override
  String get energySource => 'Sức khỏe · Trong thời gian ghi lại';

  @override
  String get doneEditing => 'Xong';

  @override
  String get setInputHint => 'Tạ  Số lần';

  @override
  String get setRequired => 'Nhập hiệp trước, ví dụ: 60 12.';

  @override
  String get aiTitle => 'Thiết lập bằng một câu';

  @override
  String get aiReady => 'Sẵn sàng';

  @override
  String get aiChecking => 'Đang kiểm tra';

  @override
  String get aiSetupNeeded => 'Cần thiết lập';

  @override
  String get aiPreparing => 'Đang chuẩn bị';

  @override
  String get aiUnavailable => 'Nhập thủ công';

  @override
  String get aiReadyBody =>
      'Nhập “đẩy ngực 80kg, đạt tổng 100 lần” rồi nhấn Enter. Tạ và mục tiêu được thiết lập tự động. Văn bản được xử lý trên thiết bị.';

  @override
  String get aiDisabledBody =>
      'Mở Cài đặt → Apple Intelligence & Siri và bật Apple Intelligence. Quay lại khi mô hình sẵn sàng; ứng dụng sẽ tự kiểm tra lại.';

  @override
  String get aiOsBody =>
      'Cần iOS 26 trở lên và thiết bị hỗ trợ Apple Intelligence. Kiểm tra Cài đặt → Cài đặt chung → Cập nhật phần mềm.';

  @override
  String get aiDeviceBody =>
      'Thiết bị này không hỗ trợ Apple Intelligence nên không thể thiết lập bằng một câu.';

  @override
  String get aiPreparingBody =>
      'Thiết bị đang chuẩn bị mô hình AI. Kết nối Wi-Fi và kiểm tra lại sau.';

  @override
  String get aiDownloadBody =>
      'Có thể tải mô hình AI. Nên dùng Wi-Fi; quá trình tải cần thời gian và dung lượng. Khi sẵn sàng, văn bản được xử lý trên thiết bị.';

  @override
  String get aiLanguageBody =>
      'Mô hình AI chưa hỗ trợ ngôn ngữ ứng dụng. Chuyển sang ngôn ngữ được hỗ trợ và kiểm tra lại.';

  @override
  String get aiPlatformBody =>
      'AI trên thiết bị không khả dụng trong môi trường này. Hãy dùng ứng dụng trên iPhone hoặc Android được hỗ trợ.';

  @override
  String get aiUnavailableBody =>
      'AI hiện chưa khả dụng. Điều này phụ thuộc thiết bị, hệ điều hành và dịch vụ AI hệ thống. Nếu vừa thiết lập thiết bị, hãy kết nối mạng và kiểm tra lại sau.';

  @override
  String get aiManualBody =>
      'Bạn vẫn có thể ghi bài tập bình thường. Chọn bài tập rồi nhập “80 20” hoặc chỉ số lần cho mỗi hiệp.';

  @override
  String get aiPrepare => 'Chuẩn bị mô hình';

  @override
  String get aiRetry => 'Kiểm tra lại';

  @override
  String get aiWorking => 'Đang thiết lập bài tập…';

  @override
  String get aiFailure =>
      'Không hiểu được nội dung. Hãy sửa rồi thử lại, hoặc dùng làm tên bài tập.';

  @override
  String get aiUseName => 'Dùng làm tên bài tập';

  @override
  String goalProgress(int done, int goal) {
    return '$done/$goal lần';
  }

  @override
  String repsPerSetLabel(int n) {
    return '$n lần mỗi hiệp';
  }

  @override
  String setProgress(int done, int goal) {
    return '$done/$goal hiệp';
  }

  @override
  String get repsInputHint => 'Số lần';

  @override
  String get setupTitle => 'Thiết lập bài tập';

  @override
  String get setupWeight => 'Mức tạ mặc định';

  @override
  String get setupTotalReps => 'Mục tiêu tổng số lần';

  @override
  String get setupSetReps => 'Số lần mỗi hiệp';

  @override
  String get setupTotalSets => 'Mục tiêu số hiệp';

  @override
  String get moveExercise => 'Di chuyển bài tập';

  @override
  String get weightUnitSetting => 'Đơn vị cân nặng mặc định';

  @override
  String get weightUnitHelp =>
      'Dùng cho bài tập mới. Giữ nguyên mức tạ và đơn vị đã ghi.';

  @override
  String answerDays(int n) {
    return '$n ngày ghi nhận';
  }

  @override
  String answerWeeks(int n) {
    return '$n tuần';
  }

  @override
  String answerFrequency(String n) {
    return '$n lần/tuần';
  }

  @override
  String answerPeak(String value) {
    return 'Cao nhất $value';
  }

  @override
  String answerNoPeak(int n) {
    return 'Chưa vượt kỷ lục trong $n tuần';
  }

  @override
  String answerSince(String date) {
    return 'Từ $date';
  }

  @override
  String answerAgo(int n) {
    return '$n ngày trước';
  }

  @override
  String answerPerSet(String value) {
    return '$value mỗi hiệp';
  }

  @override
  String answerChange(String weeks, String value) {
    return '$weeks · $value';
  }

  @override
  String answerChart(String name, int n) {
    return '$name · $n ngày ghi nhận';
  }

  @override
  String answerWeightReps(String value, String reps) {
    return '$value × $reps';
  }

  @override
  String answerSets(int n) {
    return '$n hiệp';
  }

  @override
  String timingBpm(int n) {
    return '$n BPM';
  }

  @override
  String timingProtocol(int work, int rest, int rounds) {
    return 'Tabata ${work}giây / ${rest}giây · $rounds vòng';
  }

  @override
  String timingRound(int n, int total) {
    return 'Vòng $n/$total';
  }

  @override
  String timingRoundDone(int n) {
    return 'Xong hiệp $n';
  }

  @override
  String get timingMetronome => 'Máy đếm nhịp';

  @override
  String get timingReady => 'Chuẩn bị';

  @override
  String get timingWork => 'Tập';

  @override
  String get timingRest => 'Nghỉ';

  @override
  String get timingComplete => 'Hoàn tất';

  @override
  String get timingStart => 'Bắt đầu';

  @override
  String get timingPause => 'Tạm dừng';

  @override
  String get timingReset => 'Đặt lại';

  @override
  String get timingInvalid =>
      'Dùng 10–120 BPM, 1–600 giây cho tập và nghỉ, và 1–99 hiệp.';

  @override
  String get timingSoundFailed =>
      'Không phát được âm thanh. Bộ đếm giờ vẫn chạy.';

  @override
  String get queryTitle => 'Hỏi về bản ghi';

  @override
  String get queryReadyBody =>
      'Hỏi “Squat nặng nhất bao nhiêu?”, “Tháng trước chống đẩy bao nhiêu lần?” hoặc “Bench tháng này có tiến bộ không?”. AI trên thiết bị hiểu câu hỏi; số liệu được tính từ bản ghi.';

  @override
  String get queryManualBody =>
      'Câu hỏi tự nhiên cần AI trên thiết bị sẵn sàng. Luôn có thể tìm tên bài tập và ghi chú.';

  @override
  String get queryWorking => 'Đang hiểu câu hỏi…';

  @override
  String get queryFailed => 'Không thể tải câu trả lời. Vui lòng thử lại.';

  @override
  String get queryUnsupported =>
      'Hãy đặt câu hỏi về nhật ký tập luyện của bạn.';

  @override
  String get queryOffline => 'Cần kết nối để hỏi.';

  @override
  String get queryNoData =>
      'Thiếu bản ghi đã hoàn thành hoặc số đo cần thiết. Hãy kiểm tra bản ghi gốc.';

  @override
  String queryPeriod(String start, String end) {
    return '$start – $end';
  }

  @override
  String get queryAllTime => 'Toàn bộ thời gian';

  @override
  String get queryPresent => 'Hiện tại';

  @override
  String get queryRepUnit => 'lần';

  @override
  String get querySetUnit => 'hiệp';

  @override
  String get queryDayUnit => 'ngày';

  @override
  String get queryAverage => 'Mức tạ trung bình mỗi hiệp';

  @override
  String get queryMissingData =>
      'Bản ghi không có bài tập hoặc dữ liệu đo cần thiết.';

  @override
  String get queryAmbiguous => 'Hãy làm rõ bài tập và bản ghi bạn muốn hỏi.';

  @override
  String queryRank(int n) {
    return 'Hạng $n';
  }

  @override
  String timingWorkSeconds(int n) {
    return 'Tập ${n}s';
  }

  @override
  String timingRestSeconds(int n) {
    return 'Nghỉ ${n}s';
  }

  @override
  String timingRounds(int n) {
    return '$n hiệp';
  }

  @override
  String timingBeat(String count) {
    return 'Nhịp $count';
  }

  @override
  String timingHeart(int bpm, int target) {
    return '♥ $bpm → $target';
  }

  @override
  String get accountSignIn => 'Đăng nhập và sao lưu';

  @override
  String get accountSignOut => 'Đăng xuất';

  @override
  String get planMonthly => 'Hàng tháng';

  @override
  String get planLifetime => 'Trọn đời';

  @override
  String get planActive => 'Đang dùng';

  @override
  String get restorePurchases => 'Khôi phục giao dịch';

  @override
  String get quotaSpent => 'Bạn đã dùng hết câu hỏi tháng này.';

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
    return 'Từ $gym';
  }

  @override
  String get partnerInvite => 'Tập cùng nhau';

  @override
  String get partnerCode => 'Đọc mã này cho bạn tập';

  @override
  String get partnerEnter => 'Nhập mã';

  @override
  String bookingNext(String trainer, String when) {
    return '$trainer · $when';
  }

  @override
  String get bookingNew => 'Đặt buổi PT';

  @override
  String get bookingNone => 'Ngày đó không còn giờ trống.';

  @override
  String get bookingCancel => 'Huỷ đặt lịch';

  @override
  String get countAloud => 'Đếm nhịp thành tiếng';

  @override
  String get metricMax => 'Tốt nhất';

  @override
  String get metricTrend => 'Xu hướng';

  @override
  String get metricLast => 'Lần cuối';

  @override
  String get metricSessions => 'Số ngày';

  @override
  String get metricVolume => 'Khối lượng';

  @override
  String get metricReps => 'Tổng số lần';

  @override
  String get metricSets => 'Số hiệp';

  @override
  String get metricAverage => 'Trung bình';

  @override
  String get readAsConfirm => 'Hiểu là';

  @override
  String get confirmYes => 'Đúng';

  @override
  String readAsNote(String from, String to) {
    return '$from → $to';
  }

  @override
  String get reviewNumbers => 'Kiểm tra các số và điều kiện trước khi áp dụng.';

  @override
  String get querySourceOnly => 'Xem bản ghi gốc';

  @override
  String get queryCompareOrder => 'Giai đoạn thứ hai − giai đoạn thứ nhất';

  @override
  String queryRankingLimit(int n) {
    return 'Top $n · giảm dần';
  }

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsRecording => 'Ghi chép';

  @override
  String get settingsAccount => 'Tài khoản';

  @override
  String get settingsGym => 'Phòng tập của bạn';

  @override
  String get settingsNoGym =>
      'Chạm điện thoại vào sticker của phòng tập để nhận giáo án từ huấn luyện viên.';

  @override
  String get proTitle => 'Hỏi nhật ký của bạn bất cứ điều gì';

  @override
  String get proBody =>
      'Hỏi “squat nặng nhất là bao nhiêu” hay “tháng này bench có tăng không” và nhận câu trả lời tính từ nhật ký của bạn.';

  @override
  String proFree(int n) {
    return 'Miễn phí $n lần mỗi tháng';
  }

  @override
  String proPaid(int n) {
    return 'Có gói: $n lần mỗi ngày';
  }

  @override
  String get proEverythingElseFree =>
      'Ghi chép, hẹn giờ, đồng bộ sức khỏe và tính năng phòng tập đều dùng được mà không cần gói.';

  @override
  String get proOwned => 'Đang hoạt động. Cảm ơn bạn.';

  @override
  String get proSignInFirst =>
      'Gói gắn với tài khoản. Vui lòng đăng nhập trước.';

  @override
  String get tagSignInNeeded => 'Đăng nhập để kết nối với phòng tập của bạn.';

  @override
  String get tagJoinSent =>
      'Đã gửi yêu cầu. Bạn có thể bắt đầu ngay khi huấn luyện viên xác nhận.';

  @override
  String get tagJoinWaiting =>
      'Bạn đã gửi yêu cầu rồi. Huấn luyện viên đang xem xét.';

  @override
  String get tagJoinFailed =>
      'Không gửi được yêu cầu. Lát nữa hãy chạm lại vào sticker.';

  @override
  String get bookingPending => 'Chờ duyệt';

  @override
  String get bookingWhichGym => 'Phòng tập nào?';

  @override
  String get tagSignIn => 'Đăng nhập';

  @override
  String get accountDelete => 'Xóa tài khoản';

  @override
  String get accountDeleteAsk =>
      'Không thể hoàn tác. Giáo án, nhật ký tập, gói tập và lịch hẹn sẽ mất hết.';

  @override
  String get accountDeleteDo => 'Xóa tài khoản';

  @override
  String get accountDeleteFailed =>
      'Không xóa được tài khoản. Vui lòng thử lại sau.';

  @override
  String get signInFailed => 'Không đăng nhập được. Vui lòng thử lại sau.';

  @override
  String get bookingTitle => 'Đặt lịch PT';

  @override
  String get bookingConfirmed => 'Đã xác nhận';

  @override
  String bookingRemaining(int n) {
    return 'Còn $n buổi';
  }

  @override
  String get bookingNoPass => 'Bạn chưa có gói PT. Hãy hỏi huấn luyện viên.';

  @override
  String bookingNoHours(String trainer) {
    return '$trainer chưa mở khung giờ nào.';
  }

  @override
  String get bookingPick => 'Chọn giờ';

  @override
  String bookingWith(String trainer, int minutes) {
    return '$trainer · $minutes phút';
  }

  @override
  String get bookingSent =>
      'Đã gửi yêu cầu. Sẽ xác nhận khi huấn luyện viên duyệt.';

  @override
  String get bookingUpcoming => 'Sắp tới';

  @override
  String get bookingClosedDay => 'Ngày này không nhận.';

  @override
  String get bookingCancelAsk => 'Hủy lịch hẹn này?';

  @override
  String get ok => 'OK';

  @override
  String get mealPhoto => 'Ảnh bữa ăn';

  @override
  String get mealCamera => 'Máy ảnh';

  @override
  String get mealGallery => 'Từ thư viện';

  @override
  String get mealEstimating => 'Đang ước tính calo…';

  @override
  String mealIntake(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Nạp vào ≈ $nString kcal';
  }

  @override
  String get mealFailed => 'Không ước tính được calo từ ảnh này. Hãy chụp lại.';

  @override
  String get mealEstimateNote => 'Ước tính từ ảnh';

  @override
  String mealServingsOption(String n) {
    return '$n khẩu phần';
  }

  @override
  String get fitAll => 'Hôm nay trên một trang';

  @override
  String get sameDayOther => 'Bản ghi khác trong ngày';

  @override
  String get mealText => 'Ghi bữa ăn';

  @override
  String get mealTextHint => 'Bạn đã ăn gì? VD: 2 quả chuối, sữa 200ml';

  @override
  String kcalApprox(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '≈ $nString kcal';
  }

  @override
  String get mealKcalUnknown => 'Chưa rõ kcal';

  @override
  String mealIntakePartial(int n, int m) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Nạp vào $nString kcal + $m món chưa rõ kcal';
  }

  @override
  String get mealAmountAsk => 'Bạn đã ăn bao nhiêu?';

  @override
  String get mealBasis => 'Cơ sở';

  @override
  String get mealEaten => 'Lượng đã ăn';

  @override
  String get mealUnitServing => 'khẩu phần';

  @override
  String get mealUnitPackage => 'cả gói';

  @override
  String get mealUnitPhoto => 'món trong ảnh';

  @override
  String get mealWhole => 'Tất cả';

  @override
  String get mealHalf => 'Một nửa';

  @override
  String get mealPhotoWholeNote =>
      'Đây là ước tính cho toàn bộ món trong ảnh. Hãy chọn phần bạn đã ăn.';

  @override
  String get mealAmountInvalid => 'Hãy nhập số từ 0 trở lên.';

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

    return 'Theo ghi chép: nạp $intakeString − tập $burnedString = $diffString kcal';
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

    return 'Theo ghi chép: nạp ≈ $intakeString − tập $burnedString ≈ $diffString kcal';
  }

  @override
  String get dayBurnedMissing =>
      'Chưa đo năng lượng tập · không tính được chênh lệch';

  @override
  String dayBurnedOnly(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Tập $nString kcal · chưa ghi bữa ăn';
  }

  @override
  String get intakeLabel => 'Nạp';

  @override
  String get partnerSignIn => 'Cần đăng nhập để tập cùng nhau.';

  @override
  String get partnerSignInAction => 'Đăng nhập';

  @override
  String get partnerMakeCode => 'Tạo mã';

  @override
  String get partnerCopy => 'Sao chép';

  @override
  String partnerExpiresIn(String t) {
    return 'Hết hạn sau $t';
  }

  @override
  String get partnerExpired => 'Mã đã hết hạn.';

  @override
  String get partnerNewCode => 'Mã mới';

  @override
  String get partnerStopWaiting => 'Thôi';

  @override
  String partnerWith(String name) {
    return 'Đang tập cùng $name';
  }

  @override
  String get partnerReconnecting =>
      'Đang kết nối lại · ghi chép của bạn vẫn được lưu';

  @override
  String partnerTheirRecord(String name) {
    return 'Ghi chép của $name';
  }

  @override
  String get partnerNoRecordYet => 'Chưa có ghi chép nào.';

  @override
  String get partnerLoading => 'Đang tải…';

  @override
  String get partnerEnd => 'Dừng tập cùng nhau';

  @override
  String get partnerEndedByMe =>
      'Bạn đã dừng tập cùng nhau. Ghi chép của bạn vẫn còn.';

  @override
  String partnerEndedByThem(String name) {
    return '$name đã dừng tập cùng nhau. Ghi chép của bạn vẫn còn.';
  }

  @override
  String get partnerErrFormat => 'Mã có sáu ký tự. Hãy kiểm tra lại.';

  @override
  String get partnerErrInvalid =>
      'Không có mã này. Có thể đã dùng hoặc gõ sai.';

  @override
  String get partnerErrExpired => 'Mã đã hết hạn. Hãy xin mã mới.';

  @override
  String get partnerErrEnded => 'Lời mời này đã kết thúc.';

  @override
  String get partnerErrOwn =>
      'Đây là mã của chính bạn. Hãy nhập trên máy của người kia.';

  @override
  String get partnerErrTries => 'Thử quá nhiều lần. Hãy thử lại sau.';

  @override
  String get partnerErrNetwork =>
      'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.';

  @override
  String get partnerErrServer => 'Máy chủ gặp sự cố. Hãy thử lại sau.';

  @override
  String get partnerRetry => 'Thử lại';

  @override
  String get partnerReadOnly => 'chỉ xem';

  @override
  String get partnerConflict =>
      'Thiết bị khác của bạn đã chia sẻ bản ghi mới hơn. Bản ghi trên máy này vẫn an toàn; chỉ tạm dừng chia sẻ.';

  @override
  String get partnerShareThisDevice => 'Chia sẻ bản ghi của máy này';

  @override
  String get plansTitle => 'Kế hoạch chung';

  @override
  String get planNew => 'Kế hoạch chung mới';

  @override
  String get planJoin => 'Tham gia bằng mã';

  @override
  String get planHint =>
      'Dòng đầu là tiêu đề, sau đó mỗi dòng một bài\nVD: Squat 4 hiệp';

  @override
  String get planDateNone => 'Chưa có ngày';

  @override
  String planSetsCount(int n) {
    return '$n hiệp';
  }

  @override
  String get planSave => 'Đề xuất';

  @override
  String get planStateLocal => 'Bản nháp chỉ trên máy này · chưa lên máy chủ';

  @override
  String get planStateDraft => 'Bản nháp · chưa có bạn tập';

  @override
  String planStateWaiting(int v) {
    return 'Chờ bạn tập xác nhận · phiên bản $v';
  }

  @override
  String planStateNeedsMe(String name, int v) {
    return '$name đã sửa · cần bạn xác nhận phiên bản $v';
  }

  @override
  String planStateAgreed(int v) {
    return 'Đã thống nhất · phiên bản $v';
  }

  @override
  String get planStateWithdrawn =>
      'Đã dừng lập kế hoạch chung · kế hoạch đã thống nhất và mục tiêu của bạn vẫn còn';

  @override
  String planAccept(int v) {
    return 'Chấp nhận phiên bản $v';
  }

  @override
  String get planChanged => 'Thay đổi so với bản đã thống nhất';

  @override
  String planAdded(String x) {
    return 'Thêm: $x';
  }

  @override
  String planRemoved(String x) {
    return 'Bỏ: $x';
  }

  @override
  String planSetsChanged(String x) {
    return 'Đổi số hiệp: $x';
  }

  @override
  String get planReordered => 'Thứ tự đã đổi';

  @override
  String get planDateChanged => 'Ngày đã đổi';

  @override
  String get planTitleChanged => 'Tiêu đề đã đổi';

  @override
  String planLastAgreed(int v) {
    return 'Bản thống nhất gần nhất · phiên bản $v';
  }

  @override
  String get planConflict => 'Bạn tập đã sửa trước. Bản nháp của bạn vẫn còn.';

  @override
  String planLatest(int v) {
    return 'Kế hoạch mới nhất của bạn tập · phiên bản $v';
  }

  @override
  String get planKeepMine => 'Đề xuất lại bản nháp của tôi';

  @override
  String get planTakeLatest => 'Dùng kế hoạch mới nhất';

  @override
  String get planMyTarget => 'Mục tiêu của tôi';

  @override
  String planPartnerTarget(String name, String t) {
    return '$name: $t';
  }

  @override
  String get planTargetHint => 'VD: 100 5 hoặc 100kg 5 lần x3 ghi chú';

  @override
  String get planInvite => 'Tạo mã mời';

  @override
  String get planStart => 'Bắt đầu theo kế hoạch này';

  @override
  String get planStartSolo => 'Bắt đầu bản sao của tôi';

  @override
  String get planStartSoloNote =>
      'Chưa thống nhất. Bắt đầu bây giờ sẽ dùng bản sao của riêng bạn, không phải kế hoạch đã thống nhất.';

  @override
  String get planOpenWorkout => 'Mở buổi tập đã bắt đầu';

  @override
  String get planCopyNext => 'Sao chép sang buổi sau';

  @override
  String get planWithdraw => 'Rời kế hoạch chung này';

  @override
  String get planCompare => 'Kế hoạch và thực tế';

  @override
  String planDoneSets(String name, int planned, int done) {
    return '$name · kế hoạch $planned · đã làm $done';
  }

  @override
  String planAddedActual(String x) {
    return 'Ngoài kế hoạch: $x';
  }

  @override
  String planSkipped(String x) {
    return 'Bỏ qua: $x';
  }

  @override
  String planStartedFrom(int v) {
    return 'Bắt đầu từ kế hoạch đã thống nhất (phiên bản $v)';
  }

  @override
  String planStartedSolo(int v) {
    return 'Bắt đầu từ bản sao của bạn (phiên bản $v, chưa thống nhất)';
  }

  @override
  String get planShareLink => 'Gửi liên kết mời';

  @override
  String planShareText(String url) {
    return 'Cùng lên kế hoạch tập trong setpad: $url';
  }

  @override
  String get planLinkCopied =>
      'Đã sao chép liên kết. Dùng được một lần trong một ngày.';

  @override
  String get planLinkJoining => 'Đang tham gia kế hoạch được mời…';

  @override
  String get nearbyHint =>
      'Giữa các iPhone, bạn cũng có thể kết nối bằng cách đưa hai máy lại gần nhau khi đang mở màn hình này.';

  @override
  String get planPropose => 'Đề xuất kế hoạch';

  @override
  String get togetherStart => 'Bắt đầu cùng nhau';

  @override
  String get togetherAlternate => 'Luân phiên';

  @override
  String togetherWaiting(String name) {
    return 'Đang chờ $name…';
  }

  @override
  String get togetherWaitingHint =>
      'Yêu cầu sẽ hiện trên màn hình của bạn tập. Nếu không thấy, hãy kiểm tra ứng dụng của họ đã cập nhật chưa.';

  @override
  String togetherInvite(String name) {
    return '$name rủ bạn tập cùng';
  }

  @override
  String get togetherInviteAlternate => 'Luân phiên · bạn tập làm trước';

  @override
  String get togetherLeave => 'Dừng';

  @override
  String get togetherRejoin => 'Vào lại';

  @override
  String togetherWith(String name) {
    return 'Cùng với $name';
  }

  @override
  String get togetherTheirTurn => 'Lượt của bạn tập';

  @override
  String togetherLeftBeat(String name, int n) {
    return '$name dừng ở nhịp $n';
  }

  @override
  String togetherLeftRound(String name, int n) {
    return '$name dừng ở hiệp $n';
  }

  @override
  String get togetherMe => 'Tôi';

  @override
  String get togetherLog => 'Ghi';

  @override
  String get mealLogAs => 'Ghi là bữa ăn';

  @override
  String get proxyWrite => 'Ghi hộ';

  @override
  String proxyWriting(String name) {
    return 'Đang ghi buổi tập của $name';
  }

  @override
  String get proxyDefaultName => 'Bạn tập';

  @override
  String get proxyHand => 'Trao lại';

  @override
  String get proxyBack => 'Về của tôi';

  @override
  String proxyShareText(String url) {
    return 'Buổi tập mình ghi hộ bạn khi tập cùng. Mở trong setpad để nhận vào nhật ký của bạn.\n$url';
  }

  @override
  String handoffOffer(String name) {
    return '$name đã ghi buổi tập giúp bạn';
  }

  @override
  String get handoffTake => 'Nhận';

  @override
  String get handoffFailed =>
      'Không nhận được bản ghi. Liên kết có thể đã hết hạn hoặc mạng có vấn đề.';

  @override
  String get handoffSignIn =>
      'Cần đăng nhập để nhận bản ghi được trao cho bạn.';

  @override
  String partnerInviteMore(String code) {
    return 'Mời thêm một người · mã $code';
  }

  @override
  String get proxyWhose => 'Bạn ghi buổi tập của ai?';

  @override
  String planMemberAccepted(String name) {
    return '$name đã đồng ý';
  }

  @override
  String planMemberWaiting(String name) {
    return '$name chưa xác nhận';
  }

  @override
  String deleteNoteAsk(String title) {
    return 'Xóa \"$title\"?';
  }

  @override
  String get mealsTitle => 'Bữa ăn';
}
