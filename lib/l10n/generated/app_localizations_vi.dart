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
  String get howTo => 'Tìm bài tập rồi ghi lại các hiệp.';

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
}
