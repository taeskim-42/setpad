// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class LKo extends L {
  LKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '오늘 운동';

  @override
  String get copy => '복사';

  @override
  String get copied => '복사했습니다';

  @override
  String get howTo => '운동 이름을 검색하고 세트를 기록하세요.';

  @override
  String get exerciseNameHint => '운동 이름';

  @override
  String get repeatPrevious => '이전과 같이';

  @override
  String get addSet => '세트 추가';

  @override
  String get numberKeypad => '숫자 키패드';

  @override
  String setOrdinal(int n) {
    return '$n세트';
  }

  @override
  String repsCount(int n) {
    return '$n회';
  }

  @override
  String get allNotes => '모든 운동';

  @override
  String noteCount(int n) {
    return '$n개의 운동';
  }

  @override
  String get previous7Days => '이전 7일';

  @override
  String get previous30Days => '이전 30일';

  @override
  String monthLabel(int m) {
    return '$m월';
  }

  @override
  String get search => '검색';

  @override
  String get newNote => '새 운동';

  @override
  String get untitledNote => '새 운동';

  @override
  String get noNotesYet => '아직 기록이 없습니다';

  @override
  String get noSearchResults => '찾는 기록이 없습니다';

  @override
  String dayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.yMd(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get finishExercise => '운동 완료';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String deleteExerciseTitle(String name) {
    return '$name 삭제';
  }

  @override
  String deleteExerciseBody(int n) {
    return '$n개 세트가 함께 지워집니다. 되돌릴 수 없습니다.';
  }

  @override
  String get deleteExerciseEmptyBody => '이 운동을 지웁니다.';

  @override
  String get next => '다음';

  @override
  String stepSizeTitle(String unit) {
    return '$unit 단위';
  }

  @override
  String kcal(int n) {
    return '${n}kcal';
  }

  @override
  String weekdayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.EEEE(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get noteHint => '이 세트에 남길 메모';

  @override
  String get activeEnergy => '활동 칼로리';

  @override
  String get energyUnavailable => '기록 없음';

  @override
  String get energySource => '건강 앱 · 기록 시간대';

  @override
  String get doneEditing => '완료';

  @override
  String get setInputHint => '무게  횟수';

  @override
  String get setRequired => '세트를 먼저 입력해 주세요. 예: 60 12';

  @override
  String get aiTitle => '한 줄 설정';

  @override
  String get aiReady => '사용 가능';

  @override
  String get aiChecking => '확인 중';

  @override
  String get aiSetupNeeded => '설정 필요';

  @override
  String get aiPreparing => '준비 중';

  @override
  String get aiUnavailable => '기본 입력';

  @override
  String get aiReadyBody =>
      '운동 이름 칸에 “벤치 80kg 100개 채우기”처럼 적고 엔터를 누르세요. 무게와 목표를 자동으로 설정합니다. 문장은 기기 안에서 처리됩니다.';

  @override
  String get aiDisabledBody =>
      '설정 앱 → Apple Intelligence 및 Siri에서 Apple Intelligence를 켜 주세요. 모델 준비가 끝난 뒤 앱으로 돌아오면 자동으로 다시 확인합니다.';

  @override
  String get aiOsBody =>
      '한 줄 설정에는 iOS 26 이상과 Apple Intelligence 지원 기기가 필요합니다. 지원 기기라면 설정 → 일반 → 소프트웨어 업데이트를 확인해 주세요.';

  @override
  String get aiDeviceBody =>
      '이 기기는 Apple Intelligence를 지원하지 않아 한 줄 설정을 사용할 수 없습니다.';

  @override
  String get aiPreparingBody =>
      '기기에서 AI 모델을 준비하고 있습니다. Wi-Fi에 연결한 뒤 잠시 후 다시 확인해 주세요.';

  @override
  String get aiDownloadBody =>
      '한 줄 설정에 필요한 AI 모델을 다운로드할 수 있습니다. Wi-Fi 연결을 권장하며, 다운로드에는 시간과 저장 공간이 필요합니다. 준비가 끝나면 문장은 기기 안에서 처리됩니다.';

  @override
  String get aiLanguageBody =>
      '현재 기기의 AI 모델이 앱 언어를 지원하지 않습니다. 지원되는 언어로 변경한 뒤 다시 확인해 주세요.';

  @override
  String get aiPlatformBody =>
      '이 환경에서는 기기 내 AI를 사용할 수 없습니다. 지원되는 iPhone 또는 Android 기기의 앱에서 사용할 수 있습니다.';

  @override
  String get aiUnavailableBody =>
      '현재 기기에서 AI를 사용할 수 없습니다. 기기·OS·시스템 AI 서비스의 지원 및 준비 상태에 따라 달라집니다. 새 기기를 설정한 직후라면 네트워크에 연결한 뒤 다시 확인해 주세요.';

  @override
  String get aiManualBody =>
      '기본 운동 기록은 그대로 사용할 수 있습니다. 운동 이름을 선택한 뒤 세트마다 “80 20” 또는 횟수만 입력하세요.';

  @override
  String get aiPrepare => '모델 준비';

  @override
  String get aiRetry => '다시 확인';

  @override
  String get aiWorking => '운동 설정 중…';

  @override
  String get aiFailure => '문장을 해석하지 못했습니다. 내용을 고쳐 다시 입력하거나 운동 이름으로 사용할 수 있습니다.';

  @override
  String get aiUseName => '운동 이름으로 사용';

  @override
  String goalProgress(int done, int goal) {
    return '$done/$goal회';
  }

  @override
  String repsPerSetLabel(int n) {
    return '세트당 $n회';
  }

  @override
  String setProgress(int done, int goal) {
    return '$done/$goal세트';
  }

  @override
  String get repsInputHint => '횟수';

  @override
  String get setupTitle => '운동 설정';

  @override
  String get setupWeight => '기본 무게';

  @override
  String get setupTotalReps => '총 목표 횟수';

  @override
  String get setupSetReps => '세트당 횟수';

  @override
  String get setupTotalSets => '목표 세트 수';

  @override
  String get moveExercise => '운동 이동';

  @override
  String get weightUnitSetting => '기본 무게 단위';

  @override
  String get weightUnitHelp => '새로 입력하는 운동의 기본 단위입니다. 기존 기록의 무게와 단위는 바뀌지 않습니다.';

  @override
  String answerDays(int n) {
    return '$n일 기록';
  }

  @override
  String answerWeeks(int n) {
    return '$n주';
  }

  @override
  String answerFrequency(String n) {
    return '주 $n회';
  }

  @override
  String answerPeak(String value) {
    return '최고 $value';
  }

  @override
  String answerNoPeak(int n) {
    return '$n주간 최고 기록 유지';
  }

  @override
  String answerSince(String date) {
    return '$date부터';
  }

  @override
  String answerAgo(int n) {
    return '$n일 전';
  }

  @override
  String answerPerSet(String value) {
    return '세트당 $value';
  }

  @override
  String answerChange(String weeks, String value) {
    return '$weeks · $value';
  }

  @override
  String answerChart(String name, int n) {
    return '$name · $n일 기록';
  }

  @override
  String answerWeightReps(String value, String reps) {
    return '$value × $reps';
  }

  @override
  String answerSets(int n) {
    return '$n세트';
  }

  @override
  String timingBpm(int n) {
    return '$n BPM';
  }

  @override
  String timingProtocol(int work, int rest, int rounds) {
    return '타바타 $work초 / $rest초 · $rounds라운드';
  }

  @override
  String timingRound(int n, int total) {
    return '$n/$total라운드';
  }

  @override
  String get timingMetronome => '메트로놈';

  @override
  String get timingReady => '준비';

  @override
  String get timingWork => '운동';

  @override
  String get timingRest => '휴식';

  @override
  String get timingComplete => '완료';

  @override
  String get timingStart => '시작';

  @override
  String get timingPause => '일시정지';

  @override
  String get timingReset => '초기화';

  @override
  String get timingInvalid => 'BPM 20–300, 운동·휴식 1–600초, 라운드 1–99로 입력하세요.';

  @override
  String get timingSoundFailed => '소리를 재생할 수 없습니다. 타이머는 계속 동작합니다.';

  @override
  String get queryTitle => '기록에 질문';

  @override
  String get queryReadyBody =>
      '“스쿼트 최대 무게”, “지난달 푸시업 몇 개 했어?”, “이번 달 벤치는 지난달보다 늘었어?”처럼 물어보세요. 기기 내 AI가 질문을 해석하고 저장된 기록으로 계산합니다.';

  @override
  String get queryManualBody =>
      '자연어 질문은 기기 내 AI가 준비되면 사용할 수 있습니다. 일반 운동명·메모 검색은 항상 가능합니다.';

  @override
  String get queryWorking => '질문을 해석하고 있습니다…';

  @override
  String get queryFailed => '답변을 가져오지 못했습니다. 다시 시도해 주세요.';

  @override
  String get queryUnsupported => '운동 기록과 관련된 질문을 해주세요.';

  @override
  String get queryNoData => '조건에 맞는 완료 기록이 없거나 계산에 필요한 값이 부족합니다.';

  @override
  String queryPeriod(String start, String end) {
    return '$start – $end';
  }

  @override
  String get queryAllTime => '전체 기간';

  @override
  String get queryPresent => '현재';

  @override
  String get queryRepUnit => '회';

  @override
  String get querySetUnit => '세트';

  @override
  String get queryDayUnit => '일';

  @override
  String get queryAverage => '세트당 평균 중량';

  @override
  String get queryMissingData => '질문에 필요한 운동이나 측정 정보가 기록에 없습니다.';

  @override
  String get queryAmbiguous => '어떤 운동의 어떤 기록을 말하는지 조금 더 구체적으로 적어 주세요.';

  @override
  String queryRank(int n) {
    return '$n위';
  }
}
