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
  String setsPerLineMax(int n) {
    return 'Tối đa $n hiệp mỗi dòng. Hãy chia thành nhiều dòng.';
  }

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
  String get aiFallbackQuota =>
      'Bạn đã dùng hết trợ giúp nhập hôm nay nên đã thêm đúng như bạn gõ';

  @override
  String get aiFallbackOffline =>
      'Không có kết nối nên đã thêm đúng như bạn gõ. Có thể thêm thiết lập từ ⚙ của thẻ';

  @override
  String get aiFallbackServer =>
      'Máy chủ không phản hồi nên đã thêm đúng như bạn gõ. Có thể thêm thiết lập từ ⚙ của thẻ';

  @override
  String get aiFallbackUnread =>
      'Không tìm thấy gì để thiết lập nên đã thêm đúng như bạn gõ. Có thể thêm thiết lập từ ⚙ của thẻ';

  @override
  String get inputNameTooLong =>
      'Tên bài tập tối đa 120 ký tự — hãy tách thành nhiều dòng';

  @override
  String get inputTooLong =>
      'Văn bản dài hơn 600 ký tự sẽ không được đọc — hãy tách thành nhiều dòng';

  @override
  String get setupAdd => 'Thêm thiết lập';

  @override
  String setupUnparsed(String words) {
    return 'Chưa chuyển vào thiết lập: $words — vẫn giữ trong tiêu đề';
  }

  @override
  String setupDropped(String numbers) {
    return 'Đã bỏ các số không có trong văn bản: $numbers';
  }

  @override
  String get setupNameMissing => 'Nhập tên bài tập';

  @override
  String get setupNameTooLong => 'Tối đa 120 ký tự';

  @override
  String get setupWeightInvalid => 'Nhập số lớn hơn 0 và không quá 2000';

  @override
  String get setupCountInvalid =>
      'Nhập số nguyên từ 1 trở lên — giữ khoảng và thời gian trong tiêu đề';

  @override
  String get setupMergeUp => 'Gộp vào bài trước';

  @override
  String get setupKeepApart => 'Để riêng';

  @override
  String get setupRepsOnly => 'Chỉ ghi số lần';

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
  String get accountSignIn => 'Đăng nhập';

  @override
  String get accountSignOut => 'Đăng xuất';

  @override
  String get planMonthly => 'Hàng tháng';

  @override
  String get planYearly => 'Theo năm';

  @override
  String planYearlyTrial(int days, String price) {
    return 'Dùng thử miễn phí $days ngày, sau đó $price mỗi năm. Hủy ít nhất 24 giờ trước khi hết thời gian dùng thử thì sẽ không bị tính phí.';
  }

  @override
  String planYearlyTrialPlates(int n) {
    return 'Trong thời gian dùng thử miễn phí, nạp đầy đến $n bánh tạ. Khi bắt đầu tính phí sẽ chuyển sang nạp hằng tháng.';
  }

  @override
  String get planActive => 'Đang dùng';

  @override
  String get restorePurchases => 'Khôi phục giao dịch';

  @override
  String get subscriptionRenews =>
      'Gói đăng ký tự động gia hạn với cùng mức giá trừ khi bạn hủy ít nhất 24 giờ trước khi kỳ hiện tại kết thúc. Bạn có thể hủy bất cứ lúc nào trong phần quản lý gói đăng ký của cửa hàng.';

  @override
  String get termsOfUse => 'Điều khoản sử dụng (EULA)';

  @override
  String get inputQuotaSpent =>
      'Bạn đã dùng hết trợ giúp ghi hôm nay. Tự nhập vẫn được lưu như thường.';

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
  String get metricE1rm => '1RM ước tính';

  @override
  String get metricMaxReps => 'Số lần nhiều nhất';

  @override
  String get metricLongest => 'Dài nhất';

  @override
  String get metricFirst => 'Lần đầu';

  @override
  String get metricDaysSince => 'Số ngày nghỉ';

  @override
  String get metricDistance => 'Tổng quãng đường';

  @override
  String get metricDuration => 'Tổng thời gian';

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
  String get queryByExercise => 'Theo bài tập';

  @override
  String get queryByDay => 'Theo ngày';

  @override
  String get queryByWeek => 'Theo tuần (từ thứ Hai)';

  @override
  String get queryByMonth => 'Theo tháng';

  @override
  String get queryByWeekday => 'Theo thứ trong tuần';

  @override
  String get queryTotalSum => 'Tổng';

  @override
  String get queryTotalMean => 'Trung bình';

  @override
  String queryDiff(String later, String earlier) {
    return 'Chênh lệch ($later − $earlier)';
  }

  @override
  String queryExclude(String names) {
    return 'Trừ $names';
  }

  @override
  String queryMemo(String terms) {
    return 'Ghi chú: $terms';
  }

  @override
  String queryLastSessions(int n) {
    return '$n buổi gần nhất';
  }

  @override
  String queryBottomLimit(int n) {
    return 'Thấp nhất $n · tăng dần';
  }

  @override
  String queryOutOfScope(String names) {
    return 'Bỏ qua (không có giá trị cho số đo này): $names';
  }

  @override
  String queryMissingFor(String names) {
    return 'Chưa tính (có hiệp thiếu giá trị): $names';
  }

  @override
  String get queryE1rmRule =>
      '1RM ước tính = mức tạ × (1 + số lần ÷ 30), chỉ hiệp 1–10 lần';

  @override
  String queryMore(int n) {
    return 'Thêm $n';
  }

  @override
  String queryRankingLimit(int n) {
    return 'Top $n · giảm dần';
  }

  @override
  String get queryCompareChip => 'So sánh';

  @override
  String get queryNoRecord => 'Chưa có bản ghi';

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
  String get proTitle => 'Pro';

  @override
  String get proBody =>
      'Hỏi về nhật ký tập sẽ dùng bánh tạ — thường khoảng 1 bánh mỗi câu, và chỉ trừ đúng phần câu trả lời đã dùng. Trợ giúp ghi buổi tập và bữa ăn không dùng bánh tạ.';

  @override
  String proFree(int n, int sets) {
    return 'Miễn phí: trợ giúp ghi $n lần mỗi ngày · 1 bánh tạ cho mỗi ngày hoàn thành $sets hiệp';
  }

  @override
  String proPaid(int n, int input) {
    return 'Pro: nạp đầy đến $n bánh tạ mỗi tháng · trợ giúp ghi $input lần mỗi ngày';
  }

  @override
  String get proEverythingElseFree =>
      'Ghi chép, hẹn giờ, nhắc trên cổ tay, tập cùng nhau và phòng gym đều dùng được mà không cần Pro.';

  @override
  String get proOwned => 'Đang hoạt động. Cảm ơn bạn.';

  @override
  String get proSignInFirst =>
      'Gói gắn với tài khoản. Vui lòng đăng nhập trước.';

  @override
  String platesBalance(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Còn $nString bánh tạ';
  }

  @override
  String platesSpent(num spent, num balance) {
    final intl.NumberFormat spentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String spentString = spentNumberFormat.format(spent);
    final intl.NumberFormat balanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String balanceString = balanceNumberFormat.format(balance);

    return 'Đã dùng $spentString bánh tạ · còn $balanceString';
  }

  @override
  String noPlates(int sets) {
    return 'Không đủ bánh tạ. Mỗi ngày hoàn thành $sets hiệp bạn nhận 1 bánh.';
  }

  @override
  String noPlatesSignIn(int n) {
    return 'Đăng nhập · tài khoản mới nhận $n bánh tạ';
  }

  @override
  String platesGetPro(int n) {
    return 'Xem Pro · $n mỗi tháng';
  }

  @override
  String get purchaseNotConfirmed =>
      'Không xác nhận được giao dịch. Nếu đã bị trừ tiền, hãy nhấn “Khôi phục giao dịch” sau ít phút.';

  @override
  String get purchaseOtherAccount =>
      'Giao dịch này đã gắn với tài khoản khác. Hãy đăng nhập bằng tài khoản đó.';

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
  String get fitAll => 'Buổi tập hôm nay';

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
  String get mealTextUnknown =>
      'Không ước tính được calo vì không nhận ra món ăn. Chạm vào bữa ăn để thêm tên món hoặc lượng, ứng dụng sẽ ước tính lại.';

  @override
  String get mealTextOffline =>
      'Không ước tính được calo vì không có kết nối. Chạm vào bữa ăn và nhấn Enter để ước tính lại.';

  @override
  String get mealTextTooLong =>
      'Ghi chú bữa ăn dài hơn 500 ký tự sẽ không được ước tính. Chạm vào bữa ăn và chia nhỏ để được ước tính.';

  @override
  String queryTooLong(int max) {
    return 'Câu hỏi tối đa $max ký tự. Vui lòng rút ngắn.';
  }

  @override
  String get queryPressEnter => 'Nhấn Enter để hỏi về bản ghi của bạn.';

  @override
  String get mealRetry => 'Ước tính lại';

  @override
  String kcalAtLeast(int n) {
    return '≥ $n kcal';
  }

  @override
  String mealTextPartial(int n) {
    return 'Chỉ tính $n kcal bạn đã ghi; calo của các món còn lại chưa rõ.';
  }

  @override
  String mealTextBelowTyped(int n) {
    return 'Giá trị ước tính thấp hơn $n kcal bạn đã ghi nên không được dùng. Chỉ tính $n kcal của bạn.';
  }

  @override
  String queryLimit(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'exercises': 'Mỗi lần hỏi được tối đa 8 bài tập. Hãy hỏi từng phần.',
      'measures': 'Mỗi lần đếm được tối đa 4 thứ. Hãy hỏi từng phần.',
      'ranking': 'Bảng xếp hạng hiển thị tối đa 20. Hãy hỏi 20 trở xuống.',
      'sessions':
          '\'N buổi gần nhất\' tối đa 100 buổi. Muốn xem dài hơn, hãy hỏi theo khoảng thời gian, ví dụ năm nay.',
      'days':
          '\'N ngày gần đây\' tối đa 3660 ngày (khoảng 10 năm). Muốn xem dài hơn, hãy hỏi toàn bộ thời gian.',
      'compare': 'Mỗi lần so sánh được tối đa 6 thứ. Hãy hỏi từng phần.',
      'compareGrouped':
          'Một câu hỏi không thể vừa so sánh vừa nhóm theo bài tập, ngày, tuần, tháng hoặc thứ trong tuần. Hãy hỏi một trong hai.',
      'groupedMeasure':
          'Khi so sánh nhiều khoảng và nhóm theo ngày, tuần, tháng hoặc thứ trong tuần chỉ đếm được một thứ, và xu hướng, lần cuối, lần đầu, số ngày kể từ lần cuối không nhóm được.',
      'ordering':
          'Xếp hạng, tổng và trung bình cần nhóm, ví dụ theo bài tập hoặc theo tuần.',
      'datesTotal':
          'Ngày lần cuối và lần đầu không cộng hay lấy trung bình được.',
      'perMeasure':
          'Trung bình theo ngày, tuần hoặc tháng chỉ dùng cho các số cộng được như hiệp, lần, khối lượng, quãng đường, thời gian, số ngày và kcal. Hãy hỏi mức tạ cao nhất hoặc trung bình theo khoảng thời gian.',
      'shareMeasure':
          'Tỷ trọng chỉ tính được với các số cộng được như số hiệp hoặc khối lượng.',
      'trainedMeasure':
          'Lọc ngày có tập hoặc ngày nghỉ chỉ dùng cho kcal ăn vào và đốt. Mọi ghi chép tập luyện đều thuộc ngày có tập.',
      'sameSeries':
          'Hai vế cần so sánh được đọc giống nhau. Hãy nói rõ so sánh cái gì với cái gì.',
      'other':
          'Tìm kiếm bản ghi không tính được câu hỏi có dạng này. Hãy hỏi từng phần.',
    });
    return '$_temp0';
  }

  @override
  String policyNumberRejected(String text, String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'decimal':
          '\'$text\' — không nhận số thập phân. Hãy nhập số nguyên, ví dụ 14',
      'range': '\'$text\' — hãy nhập một con số, không phải khoảng, ví dụ 14',
      'negative': '\'$text\' — không nhận số nhỏ hơn 0, ví dụ 14',
      'unit':
          '\'$text\' — ô này đếm theo ngày hoặc buổi. Hãy đổi giờ, tuần hoặc tháng sang số ngày, ví dụ 14',
      'many': '\'$text\' — hãy chỉ nhập một con số, ví dụ 14',
      'other':
          'Không đọc được số ngày hoặc số buổi từ \'$text\'. Hãy nhập một con số, ví dụ 14',
    });
    return '$_temp0';
  }

  @override
  String get mealSources => 'Nguồn';

  @override
  String get mealSourcesTitle => 'Nguồn gốc lượng calo';

  @override
  String get mealSourcesNote =>
      'Được tính từ các giá trị trong bảng bên dưới. Chạm để mở tên đó trong bảng gốc. Món không có trong bảng do AI ước tính.';

  @override
  String mealSourcePer(String unit, String kcal) {
    return '$kcal kcal mỗi 100 $unit';
  }

  @override
  String get mealSourceMfds => 'CSDL thành phần thực phẩm của MFDS Hàn Quốc';

  @override
  String get mealSourceUsda => 'USDA FoodData Central';

  @override
  String get mealAmountInvalid => 'Hãy nhập số từ 0 trở lên.';

  @override
  String dayEnergyFull(String intake, String burned, String diff) {
    return 'Nạp $intake · tập $burned = $diff kcal';
  }

  @override
  String dayEnergyApprox(String intake, String burned, String diff) {
    return 'Nạp ≈ $intake · tập $burned ≈ $diff kcal';
  }

  @override
  String get dayBurnedMissing =>
      'Chưa đo năng lượng tập · không tính được chênh lệch';

  @override
  String dayBurnedOnly(String n) {
    return 'Tập $n kcal · chưa ghi bữa ăn';
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
  String get mealAutoLogged => 'Đã ghi thành bữa ăn';

  @override
  String get mealAutoUndo => 'Đổi thành bài tập';

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

  @override
  String get recordMenu => 'Thêm';

  @override
  String dayIntakeOnly(String intake) {
    return 'Nạp $intake kcal · chưa đo năng lượng tập';
  }

  @override
  String dayIntakeOnlyApprox(String intake) {
    return 'Nạp ≈ $intake kcal · chưa đo năng lượng tập';
  }

  @override
  String dayUnknownMeals(int m) {
    return '$m chưa rõ kcal';
  }

  @override
  String get healthDataTitle => 'Dữ liệu sức khỏe';

  @override
  String get healthDataIntro =>
      'Những gì setpad trao đổi với ứng dụng sức khỏe (Apple Health, Health Connect) và lý do.';

  @override
  String get healthDataWrite =>
      'Ghi · Buổi tập — khi bạn kết thúc một bản ghi, nó được lưu thành một buổi tập.';

  @override
  String get healthDataCalories =>
      'Đọc · Calo hoạt động — lượng calo hoạt động đồng hồ đo được trong lúc tập được gắn vào bản ghi đó. Nếu không đo được gì, ứng dụng không hiển thị calo.';

  @override
  String get healthDataHeart =>
      'Đọc · Nhịp tim — trong lúc nghỉ Tabata, khi nhịp tim giảm 25 bpm so với mức cao nhất của hiệp đó, thời gian nghỉ kết thúc và hiệp tiếp theo được báo. Khi nghỉ, dòng hẹn giờ hiện ♥ hiện tại → mục tiêu. Nếu không có nhịp tim, hoặc số đo cũ hơn 90 giây, thời gian nghỉ kết thúc đúng giờ.';

  @override
  String get healthDataStays =>
      'Dữ liệu đọc từ ứng dụng sức khỏe không rời khỏi thiết bị này. Không gửi lên máy chủ và không dùng cho quảng cáo hay tiếp thị.';

  @override
  String get healthDataRevokeIos =>
      'Bạn có thể tắt bất cứ lúc nào trong Cài đặt iPhone → Quyền riêng tư & Bảo mật → Sức khỏe → setpad.';

  @override
  String get healthDataRevokeAndroid =>
      'Bạn có thể tắt bất cứ lúc nào trong Health Connect → Quyền của ứng dụng → setpad.';

  @override
  String get healthDataPrivacy => 'Chính sách quyền riêng tư';

  @override
  String get restAlarmTitle => 'Hiệp tiếp theo — nhịp tim đã giảm';

  @override
  String liveSetBusy(String name) {
    return '$name đang sửa hiệp này. Chạm lại khi họ sửa xong.';
  }

  @override
  String liveExerciseBusy(String name) {
    return '$name đang ghi bài tập này.';
  }

  @override
  String liveExerciseRemoved(String exercise) {
    return 'Người tập cùng đã xóa $exercise. Nội dung bạn đang gõ vẫn còn trong dòng nhập.';
  }

  @override
  String get trainerReport => 'Báo cáo huấn luyện viên';

  @override
  String get trainerUnread => 'Báo cáo mới';

  @override
  String trainerRanAt(String when) {
    return 'Tổng hợp lúc $when';
  }

  @override
  String get trainerRunNow => 'Tổng hợp ngay';

  @override
  String get trainerNoReport => 'Chưa có báo cáo. Tổng hợp ngay nhé?';

  @override
  String get trainerOutdated =>
      'Báo cáo này cần phiên bản mới hơn. Hãy cập nhật ứng dụng.';

  @override
  String get trainerFailed =>
      'Không kết nối được máy chủ. Hãy thử lại sau ít phút.';

  @override
  String get trainerActUnknown =>
      'Chưa xác nhận được kết quả. Bấm lại cũng không bị ghi hai lần.';

  @override
  String get trainerDone => 'Tác tử đã xử lý';

  @override
  String get trainerToday => 'Buổi tập hôm nay';

  @override
  String get trainerTodo => 'Cần xem';

  @override
  String get trainerAllClear => 'Đã xử lý hết các việc cần xem.';

  @override
  String get trainerAttendance => 'Buổi chưa chốt';

  @override
  String trainerVisited(String time) {
    return 'Xác nhận đến $time';
  }

  @override
  String trainerFinishAll(int count) {
    return 'Hoàn tất tất cả ($count)';
  }

  @override
  String trainerFinishAsk(int count) {
    return 'Hoàn tất $count buổi — mỗi buổi trừ 1 lượt từ gói PT.';
  }

  @override
  String get trainerFinish => 'Hoàn tất';

  @override
  String get trainerJoinRequest =>
      'Yêu cầu đăng ký — hãy xem ở màn hình Hôm nay trong CRM trên web.';

  @override
  String get trainerBook => 'Đặt lịch';

  @override
  String get trainerSend => 'Gửi';

  @override
  String get trainerPaid => 'Đã nhận thanh toán';

  @override
  String get trainerContacted => 'Đã liên hệ';

  @override
  String get trainerLater => 'Để sau';

  @override
  String trainerPrice(int price) {
    final intl.NumberFormat priceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String priceString = priceNumberFormat.format(price);

    return '₩$priceString';
  }

  @override
  String trainerStarts(String d) {
    return 'Từ $d';
  }

  @override
  String get trainerPayHow => 'Thanh toán bằng cách nào?';

  @override
  String get trainerPaidListPrice =>
      'Sẽ ghi nhận thanh toán đúng giá niêm yết. Nếu giảm giá hoặc trả nhiều lần, hãy nhập ở thẻ Gói tập trong trang hội viên trên CRM web.';

  @override
  String get payCard => 'Thẻ';

  @override
  String get payCash => 'Tiền mặt';

  @override
  String get payTransfer => 'Chuyển khoản';

  @override
  String get payOther => 'Khác';

  @override
  String get agentSettings => 'Cài đặt tác tử';

  @override
  String get agentEnabled => 'Tổng hợp vào giờ đã đặt';

  @override
  String get agentTimes => 'Giờ tổng hợp';

  @override
  String get agentAddTime => 'Thêm giờ';

  @override
  String get agentDays => 'Ngày';

  @override
  String get agentAutoConfirm => 'Xác nhận yêu cầu PT ngay';

  @override
  String get agentModes => 'Theo từng việc';

  @override
  String get agentModesHelp =>
      'Tự làm — tác tử không đụng tới. Nháp — tác tử chuẩn bị, bạn chạm để xử lý. Tự động — tác tử xử lý.';

  @override
  String get agentModeOff => 'Tự làm';

  @override
  String get agentModeDraft => 'Nháp';

  @override
  String get agentModeAuto => 'Tự động';

  @override
  String get taskPtSchedule => 'Lịch PT';

  @override
  String get taskRenewal => 'Gia hạn';

  @override
  String get taskAttendance => 'Điểm danh';

  @override
  String get taskRoutine => 'Chuẩn bị bài tập';

  @override
  String get taskContact => 'Liên hệ hội viên';

  @override
  String get gymPolicy => 'Chính sách phòng tập';

  @override
  String get policyRenewalDays =>
      'Thời điểm nhắc gia hạn (số ngày trước khi hết hạn)';

  @override
  String get policyLowSessions => 'Ngưỡng sắp hết PT (số buổi PT còn đặt được)';

  @override
  String get policyAwayDays => 'Vắng mặt sau (ngày)';

  @override
  String get policyLapsedDays => 'Coi là rời bỏ sau (ngày)';

  @override
  String get policyOffer => 'Lời mời gia hạn';

  @override
  String get policySave => 'Lưu chính sách';

  @override
  String get policySaved => 'Đã lưu.';

  @override
  String get trainerWhichGym => 'Phòng tập nào?';

  @override
  String get trainerBack => 'Quay lại';

  @override
  String get trainerCopy => 'Sao chép tin nhắn';

  @override
  String get trainerCopied => 'Đã sao chép';

  @override
  String get settingsTrainer => 'Huấn luyện viên';

  @override
  String get answerNeedsTwoDays => 'Cần ít nhất hai ngày';

  @override
  String get answerNoBase => 'Không có giá trị gốc';

  @override
  String answerPerWeek(String value) {
    return '$value mỗi tuần';
  }

  @override
  String answerPerMonth(String value) {
    return '$value mỗi tháng';
  }

  @override
  String answerTimesAfter(int n) {
    return '$n buổi kể từ kỷ lục';
  }

  @override
  String get answerTimesUnit => ' lần';

  @override
  String answerTimes(int n) {
    return '$n lần';
  }

  @override
  String answerStreak(int n) {
    return '$n ngày liên tiếp';
  }

  @override
  String answerRestDays(int n) {
    return 'nghỉ $n ngày';
  }

  @override
  String get answerUntilToday => 'hôm nay';

  @override
  String answerEveryDays(String value) {
    return 'Thường $value ngày một lần';
  }

  @override
  String answerMeanEvery(String value) {
    return 'Trung bình $value ngày một lần';
  }

  @override
  String answerGapSpread(int a, int b, int c, int d) {
    return 'Liền nhau $a lần · nghỉ 1 ngày $b lần · nghỉ 2 ngày $c lần · nghỉ từ 3 ngày $d lần';
  }

  @override
  String answerLongestIncluded(int n) {
    return 'Có một lần nghỉ dài $n ngày';
  }

  @override
  String get answerNoMeals => 'Không có ngày nào ghi bữa ăn';

  @override
  String answerAbout(String value) {
    return 'khoảng $value';
  }

  @override
  String answerMealDays(int n) {
    return '$n ngày có ghi bữa ăn';
  }

  @override
  String queryUnknownMeals(int n) {
    return '$n bữa không rõ calo không được tính';
  }

  @override
  String get answerNoWatch => 'Không có buổi tập đo bằng đồng hồ';

  @override
  String answerWatchDays(int n) {
    return '$n ngày đo bằng đồng hồ';
  }

  @override
  String get answerNoBoth => 'Không có ngày nào có cả ăn và đốt';

  @override
  String answerBothDays(int n) {
    return '$n ngày có cả ăn và đốt';
  }

  @override
  String answerIntakeOnlyDays(int n) {
    return 'Đã bỏ $n ngày chỉ có ăn';
  }

  @override
  String answerMonths(int n) {
    return '$n tháng';
  }

  @override
  String get metricChangePct => 'Tỷ lệ thay đổi';

  @override
  String get metricDaysSinceBest => 'Ngày từ kỷ lục';

  @override
  String get metricSessionsSinceBest => 'Buổi từ kỷ lục';

  @override
  String get metricMeanReps => 'Lần mỗi hiệp';

  @override
  String get metricLongestStreak => 'Chuỗi dài nhất';

  @override
  String get metricLongestGap => 'Lần nghỉ dài nhất';

  @override
  String get metricMeanGap => 'Khoảng cách giữa buổi tập';

  @override
  String get metricIntake => 'Calo nạp vào';

  @override
  String get metricBurned => 'Calo tiêu hao';

  @override
  String get metricBalance => 'Nạp − tiêu hao';

  @override
  String get queryAlone => 'Tập một mình';

  @override
  String get queryTogether => 'Tập cùng bạn';

  @override
  String get queryByPart => 'Theo nhóm cơ';

  @override
  String get queryCanSee =>
      'Nhật ký cho biết mức tạ, số lần, số hiệp, ngày tập và calo bữa ăn';

  @override
  String get queryDiffColumn => 'Chênh lệch';

  @override
  String get queryFutureCell => 'Chưa tới';

  @override
  String get queryGrowthRate =>
      'Mức tăng được xếp theo tốc độ mỗi tuần để so sánh công bằng';

  @override
  String get queryHandoff => 'Chỉ bản ghi được chuyển cho bạn';

  @override
  String get queryNoHandoff => 'Không tính bản ghi được chuyển';

  @override
  String queryHandoffCount(int n) {
    return 'Bỏ $n bản ghi được chuyển';
  }

  @override
  String get queryHoursNote =>
      'Giờ là lúc tạo bản ghi; ghi bù sau sẽ tính theo lúc ghi';

  @override
  String get queryMixedWeights => 'Mức tạ này gộp nhiều bài tập';

  @override
  String get queryNcBodyweight =>
      'Nhật ký không có cân nặng. Ghi cân nặng vào câu hỏi để so sánh (vd: nặng 80, deadlift gấp mấy lần?)';

  @override
  String get queryNcHeartRate =>
      'Tìm kiếm chưa xem nhịp tim; theo bài hay theo lúc nghỉ thì không được vì hiệp không có giờ';

  @override
  String get queryNeverMark => 'Chưa từng ghi';

  @override
  String get queryNoBaseRatio => 'Không có giá trị gốc nên không tính tỷ lệ';

  @override
  String get queryNoneCell => 'Không có bản ghi trong phạm vi này';

  @override
  String get queryNoRoutine => 'Ngày không theo giáo án';

  @override
  String get queryRoutine => 'Ngày theo giáo án HLV';

  @override
  String get queryOngoing => 'đang diễn ra';

  @override
  String get queryOverlap =>
      'Ngày tập bị trùng nên không tính tỷ trọng; hãy hỏi theo số hiệp';

  @override
  String queryPart(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'chest': 'Ngực',
      'back': 'Lưng',
      'legs': 'Chân',
      'shoulders': 'Vai',
      'arms': 'Tay',
      'core': 'Core',
      'cardio': 'Cardio',
      'upper': 'Thân trên',
      'lower': 'Thân dưới',
      'other': 'Nhóm cơ',
    });
    return '$_temp0';
  }

  @override
  String get queryRatioColumn => 'Tỷ lệ';

  @override
  String get queryRatioUnits => 'Khác đơn vị nên không tính tỷ lệ';

  @override
  String get queryRestDay => 'Ngày nghỉ';

  @override
  String get queryTrained => 'Ngày tập';

  @override
  String get querySetFirst => 'Hiệp đầu';

  @override
  String get querySetLast => 'Hiệp cuối';

  @override
  String get queryShare => 'Tỷ trọng';

  @override
  String get queryZeroFilled => 'Bài không tập được tính là 0';

  @override
  String queryAgainst(String value) {
    return 'so với $value';
  }

  @override
  String queryAgainstLine(
    String value,
    String target,
    String ratio,
    String diff,
  ) {
    return '$value ÷ $target = $ratio lần · chênh $diff';
  }

  @override
  String queryAlias(String name, String names) {
    return '$name = $names';
  }

  @override
  String queryDayCount(int n) {
    return '$n ngày';
  }

  @override
  String queryDroppedSets(int n) {
    return 'Bỏ $n hiệp khác loại giá trị';
  }

  @override
  String queryHours(int from, int to) {
    return '${from}h–${to}h';
  }

  @override
  String queryMaybe(String name) {
    return 'Có phải $name?';
  }

  @override
  String queryMemoAll(String terms) {
    return 'Ghi chú có đủ: $terms';
  }

  @override
  String queryMemoHit(String text, int n) {
    return '$text ($n ngày)';
  }

  @override
  String queryMemoHits(String hits) {
    return 'Ghi chú khớp: $hits';
  }

  @override
  String queryNeverPartial(String names) {
    return '$names: chưa từng ghi, đã tính không có';
  }

  @override
  String queryNeverRows(String names) {
    return '$names: chưa từng ghi';
  }

  @override
  String queryNoMemo(String terms) {
    return 'Ghi chú không có: $terms';
  }

  @override
  String queryNoRepsSets(int n) {
    return 'Bỏ $n hiệp không ghi số lần';
  }

  @override
  String queryNotComputable(String things) {
    return 'Không có trong nhật ký nên không xem được: $things';
  }

  @override
  String queryNotComputableTail(String things) {
    return 'Không xem được: $things';
  }

  @override
  String queryNothingComputable(String things) {
    return 'Nhật ký không trả lời được: $things';
  }

  @override
  String queryNoWeightSets(int n, int reps) {
    return 'Bỏ $n hiệp không có tạ (nhiều nhất $reps lần)';
  }

  @override
  String queryNth(int n) {
    return 'Buổi tập thứ $n tính từ cuối';
  }

  @override
  String queryOtherDistance(int n, String value) {
    return '$n hiệp ghi quãng đường: $value';
  }

  @override
  String queryOtherDuration(int n, String value) {
    return '$n hiệp ghi thời gian: $value';
  }

  @override
  String queryPartial(String names) {
    return 'không tính $names';
  }

  @override
  String queryPartialChunk(int n) {
    return '($n ngày)';
  }

  @override
  String queryPartMembers(String part, String names) {
    return '$part: $names';
  }

  @override
  String queryPer(String per) {
    String _temp0 = intl.Intl.selectLogic(per, {
      'day': 'mỗi ngày',
      'week': 'mỗi tuần',
      'month': 'mỗi tháng',
      'other': 'trung bình',
    });
    return '$_temp0';
  }

  @override
  String queryPerSuffix(String per) {
    String _temp0 = intl.Intl.selectLogic(per, {
      'day': '/ngày',
      'week': '/tuần',
      'month': '/tháng',
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
    return '$a ÷ $b = $value lần ($percent%)';
  }

  @override
  String queryRelative(String by, int n) {
    String _temp0 = intl.Intl.selectLogic(by, {
      'day': 'Ngày $n',
      'week': 'Tuần $n',
      'month': 'Tháng $n',
      'other': 'Thứ $n',
    });
    return '$_temp0';
  }

  @override
  String queryRolled(String year) {
    return 'Chưa tới nên hiểu là năm $year';
  }

  @override
  String querySamePeriod(int days, String earlier, String later) {
    return 'Cùng $days ngày: $earlier → $later';
  }

  @override
  String queryShortGrowth(String names) {
    return 'Quá ngắn để xếp hạng (dưới 3 ngày hoặc 3 tuần): $names';
  }

  @override
  String queryTimer(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tabata': 'Tabata',
      'bpm': 'Hẹn giờ BPM',
      'other': 'Không hẹn giờ',
    });
    return '$_temp0';
  }

  @override
  String queryUnknownPart(String names) {
    return 'Đã bỏ bài không rõ nhóm cơ: $names';
  }

  @override
  String queryUnranked(int n, String names) {
    return '$n mục không xếp hạng vì thiếu giá trị: $names';
  }

  @override
  String queryWindowLengths(String lengths) {
    return 'Các giai đoạn dài khác nhau ($lengths ngày) nên chênh lệch và tỷ lệ tính theo tuần';
  }

  @override
  String queryZeroBuckets(String by, int total, int zeros) {
    String _temp0 = intl.Intl.selectLogic(by, {
      'week': '$zeros/$total tuần bằng 0',
      'month': '$zeros/$total tháng bằng 0',
      'other': '$zeros/$total bằng 0',
    });
    return '$_temp0';
  }

  @override
  String queryPossibleDays(int m, String percent) {
    return '$percent% trong $m ngày có thể';
  }

  @override
  String get queryOfflineLocal =>
      'Không kết nối được máy chủ nên đã đếm trên máy chỉ theo bài tập và thời gian trong câu. Khi có mạng, nhấn Enter để hỏi lại.';

  @override
  String get queryMisread =>
      'Không đọc được câu hỏi này thành phép đếm. Hãy thử hỏi theo cách khác.';

  @override
  String get queryMisreadLocal =>
      'Không đọc được câu hỏi thành phép đếm nên đã đếm trên máy chỉ theo bài tập và khoảng thời gian trong câu. Hỏi theo cách khác để đọc lại.';

  @override
  String get queryUnreadable =>
      'Mô hình đã gửi câu trả lời không đọc được hai lần. Không phải do kết nối, và câu trả lời đó không tốn bánh tạ nào.';

  @override
  String get queryAskAgain => 'Hỏi lại';

  @override
  String get queryUnreadablePaid =>
      'Mô hình đã gửi câu trả lời không đọc được hai lần. Không phải do kết nối. Câu trả lời đó không tốn bánh tạ nào; số bánh tạ bên dưới là cho bước đầu phân loại câu hỏi.';

  @override
  String get queryUnreadableLocal =>
      'Trong lúc đó, đã đếm trên máy theo bài tập và khoảng thời gian trong câu.';

  @override
  String get queryTotalUnits => 'Đơn vị khác nhau nên không cộng tổng được';

  @override
  String queryMemoDropped(String words) {
    return 'Đã bỏ điều kiện ghi chú: $words';
  }

  @override
  String queryAgainstDropped(String value) {
    return 'Đã bỏ số mốc $value — đó không phải cân nặng ghi trong câu hỏi';
  }

  @override
  String queryBoundDropped(String value) {
    return 'Đã bỏ điều kiện $value — câu hỏi không ghi số này theo đơn vị đó';
  }
}
