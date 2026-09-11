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
    return '$n kcal';
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
  String get queryNoData =>
      'Không có bản ghi hoàn thành phù hợp hoặc thiếu giá trị cần thiết.';

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
}
