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
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '${nString}kcal';
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
  String timingRoundDone(int n) {
    return '$n라운드 종료';
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
  String get timingInvalid => 'BPM 10–120, 운동·휴식 1–600초, 라운드 1–99로 입력하세요.';

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
  String get queryOffline => '연결되면 물어볼 수 있어요.';

  @override
  String get queryNoData => '계산에 필요한 완료 기록이나 값이 부족해요. 원본 기록을 확인해 주세요.';

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

  @override
  String timingWorkSeconds(int n) {
    return '운동 $n초';
  }

  @override
  String timingRestSeconds(int n) {
    return '휴식 $n초';
  }

  @override
  String timingRounds(int n) {
    return '$n라운드';
  }

  @override
  String timingBeat(String count) {
    return '$count';
  }

  @override
  String timingHeart(int bpm, int target) {
    return '♥ $bpm → $target';
  }

  @override
  String get accountSignIn => '로그인하고 백업';

  @override
  String get accountSignOut => '로그아웃';

  @override
  String get planMonthly => '월 이용권';

  @override
  String get planLifetime => '평생 이용권';

  @override
  String get planActive => '이용 중';

  @override
  String get restorePurchases => '구매 복원';

  @override
  String get quotaSpent => '이번 달 질문을 다 썼어요.';

  @override
  String gymMember(String gym, String trainer) {
    return '$gym · $trainer 트레이너';
  }

  @override
  String gymOnly(String gym) {
    return '$gym';
  }

  @override
  String routineFromTrainer(String gym) {
    return '$gym에서 보낸 운동';
  }

  @override
  String get partnerInvite => '같이 하기';

  @override
  String get partnerCode => '상대에게 이 코드를 알려 주세요';

  @override
  String get partnerEnter => '코드 입력';

  @override
  String bookingNext(String trainer, String when) {
    return '$trainer 트레이너 · $when';
  }

  @override
  String get bookingNew => 'PT 예약';

  @override
  String get bookingNone => '그날은 빈 시간이 없어요.';

  @override
  String get bookingCancel => '예약 취소';

  @override
  String get countAloud => '박자를 소리내어 세기';

  @override
  String get metricMax => '최고';

  @override
  String get metricTrend => '추이';

  @override
  String get metricLast => '마지막';

  @override
  String get metricSessions => '운동한 날';

  @override
  String get metricVolume => '볼륨';

  @override
  String get metricReps => '총 횟수';

  @override
  String get metricSets => '세트 수';

  @override
  String get metricAverage => '평균';

  @override
  String get readAsConfirm => '이렇게 읽었어요';

  @override
  String get confirmYes => '맞아요';

  @override
  String readAsNote(String from, String to) {
    return '$from → $to';
  }

  @override
  String get reviewNumbers => '숫자와 조건을 확인한 뒤 적용해 주세요.';

  @override
  String get querySourceOnly => '원본 기록 보기';

  @override
  String get queryCompareOrder => '두 번째 기간 − 첫 번째 기간';

  @override
  String queryRankingLimit(int n) {
    return '상위 $n개 · 내림차순';
  }

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsRecording => '기록';

  @override
  String get settingsAccount => '계정';

  @override
  String get settingsGym => '다니는 체육관';

  @override
  String get settingsNoGym => '헬스장 스티커에 폰을 대면 트레이너가 짠 루틴을 여기서 받습니다.';

  @override
  String get proTitle => '기록에 마음껏 물어보기';

  @override
  String get proBody =>
      '“스쿼트 최대 무게”, “이번 달 벤치는 지난달보다 늘었어?” 처럼 물으면 저장된 기록으로 계산해 답합니다.';

  @override
  String proFree(int n) {
    return '무료 한 달 $n번';
  }

  @override
  String proPaid(int n) {
    return '이용권 하루 $n번';
  }

  @override
  String get proEverythingElseFree => '기록·타이머·건강 앱 연동·체육관 연결은 이용권 없이도 전부 됩니다.';

  @override
  String get proOwned => '이용 중입니다. 고맙습니다.';

  @override
  String get proSignInFirst => '이용권은 계정에 붙습니다. 먼저 로그인해 주세요.';

  @override
  String get tagSignInNeeded => '헬스장과 연결하려면 로그인이 필요합니다.';

  @override
  String get tagJoinSent => '등록을 신청했습니다. 트레이너가 확인하면 바로 시작할 수 있습니다.';

  @override
  String get tagJoinWaiting => '이미 신청하셨습니다. 트레이너가 확인하는 중입니다.';

  @override
  String get tagJoinFailed => '신청하지 못했습니다. 잠시 뒤 다시 대주세요.';

  @override
  String get bookingPending => '승인 대기';

  @override
  String get bookingWhichGym => '어느 헬스장인가요?';

  @override
  String get tagSignIn => '로그인';

  @override
  String get accountDelete => '회원 탈퇴';

  @override
  String get accountDeleteAsk => '되돌릴 수 없습니다. 받은 루틴, 운동 기록, 이용권, 예약이 모두 사라집니다.';

  @override
  String get accountDeleteDo => '탈퇴합니다';

  @override
  String get accountDeleteFailed => '탈퇴하지 못했습니다. 잠시 뒤 다시 시도해 주세요.';

  @override
  String get signInFailed => '로그인하지 못했습니다. 잠시 뒤 다시 시도해 주세요.';

  @override
  String get bookingTitle => 'PT 예약';

  @override
  String get bookingConfirmed => '확정';

  @override
  String bookingRemaining(int n) {
    return '남은 횟수 $n회';
  }

  @override
  String get bookingNoPass => 'PT 이용권이 없습니다. 트레이너에게 문의해 주세요.';

  @override
  String bookingNoHours(String trainer) {
    return '$trainer 트레이너가 아직 받을 시간을 열지 않았습니다.';
  }

  @override
  String get bookingPick => '시간 고르기';

  @override
  String bookingWith(String trainer, int minutes) {
    return '$trainer 트레이너 · 1회 $minutes분';
  }

  @override
  String get bookingSent => '신청했습니다. 트레이너가 승인하면 확정됩니다.';

  @override
  String get bookingUpcoming => '다가오는 예약';

  @override
  String get bookingClosedDay => '이날은 받지 않습니다.';

  @override
  String get bookingCancelAsk => '이 예약을 취소할까요?';

  @override
  String get ok => '확인';

  @override
  String get mealPhoto => '식단 사진';

  @override
  String get mealCamera => '카메라';

  @override
  String get mealGallery => '앨범에서';

  @override
  String get mealEstimating => '칼로리 어림하는 중…';

  @override
  String mealIntake(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '섭취 약 ${nString}kcal';
  }

  @override
  String get mealFailed => '사진에서 칼로리를 어림하지 못했어요. 다시 찍어 주세요.';

  @override
  String get mealEstimateNote => '사진으로 어림한 값이에요';

  @override
  String mealServingsOption(String n) {
    return '$n회분';
  }

  @override
  String get fitAll => '전체 보기';

  @override
  String get sameDayOther => '같은 날의 다른 기록';

  @override
  String get mealText => '식단 적기';

  @override
  String get mealTextHint => '먹은 것을 적어 주세요. 예: 김밥 한 줄, 우유 200ml';

  @override
  String kcalApprox(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '약 ${nString}kcal';
  }

  @override
  String get mealKcalUnknown => '열량 미상';

  @override
  String mealIntakePartial(int n, int m) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '확인된 섭취 ${nString}kcal · 열량 미상 $m건';
  }

  @override
  String get mealAmountAsk => '얼마나 드셨나요?';

  @override
  String get mealBasis => '기준';

  @override
  String get mealEaten => '먹은 양';

  @override
  String get mealUnitServing => '회분';

  @override
  String get mealUnitPackage => '포장 전체';

  @override
  String get mealUnitPhoto => '사진 속 음식';

  @override
  String get mealWhole => '전체';

  @override
  String get mealHalf => '절반';

  @override
  String get mealPhotoWholeNote => '사진에 보이는 음식 전체를 어림한 값이에요. 그중 드신 만큼을 고르세요.';

  @override
  String get mealAmountInvalid => '0 이상의 숫자를 입력해 주세요.';

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

    return '기록 기준 섭취 $intakeString − 운동 $burnedString = ${diffString}kcal';
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

    return '기록 기준 섭취 약 $intakeString − 운동 $burnedString = 약 ${diffString}kcal';
  }

  @override
  String get dayBurnedMissing => '운동 소모량 미측정 · 차이 계산 불가';

  @override
  String dayBurnedOnly(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '운동 ${nString}kcal · 식단 미기록';
  }

  @override
  String get intakeLabel => '섭취';

  @override
  String get partnerSignIn => '같이 하려면 로그인이 필요합니다.';

  @override
  String get partnerSignInAction => '로그인';

  @override
  String get partnerMakeCode => '코드 만들기';

  @override
  String get partnerCopy => '복사';

  @override
  String partnerExpiresIn(String t) {
    return '$t 뒤 만료';
  }

  @override
  String get partnerExpired => '코드가 만료되었습니다.';

  @override
  String get partnerNewCode => '새 코드';

  @override
  String get partnerStopWaiting => '그만두기';

  @override
  String partnerWith(String name) {
    return '$name 님과 함께 운동 중';
  }

  @override
  String get partnerReconnecting => '연결 복구 중 · 내 기록은 계속 저장됩니다';

  @override
  String partnerTheirRecord(String name) {
    return '$name 님의 기록';
  }

  @override
  String get partnerNoRecordYet => '아직 올라온 기록이 없습니다.';

  @override
  String get partnerLoading => '불러오는 중…';

  @override
  String get partnerEnd => '함께 운동 종료';

  @override
  String get partnerEndedByMe => '함께 운동을 종료했습니다. 내 기록은 그대로 남아 있습니다.';

  @override
  String partnerEndedByThem(String name) {
    return '$name 님이 함께 운동을 종료했습니다. 내 기록은 그대로 남아 있습니다.';
  }

  @override
  String get partnerErrFormat => '코드는 여섯 글자입니다. 다시 확인해 주세요.';

  @override
  String get partnerErrInvalid => '맞는 코드가 없습니다. 이미 사용됐거나 잘못 입력했을 수 있어요.';

  @override
  String get partnerErrExpired => '만료된 코드입니다. 상대에게 새 코드를 받아 주세요.';

  @override
  String get partnerErrEnded => '이미 종료된 초대입니다.';

  @override
  String get partnerErrOwn => '내가 만든 코드입니다. 상대의 기기에서 입력해 주세요.';

  @override
  String get partnerErrTries => '시도가 너무 많습니다. 잠시 뒤에 다시 해 주세요.';

  @override
  String get partnerErrNetwork => '서버에 연결하지 못했습니다. 네트워크를 확인하고 다시 시도해 주세요.';

  @override
  String get partnerErrServer => '서버에 문제가 있습니다. 잠시 뒤에 다시 시도해 주세요.';

  @override
  String get partnerRetry => '다시 시도';

  @override
  String get partnerReadOnly => '읽기 전용';

  @override
  String get partnerConflict =>
      '다른 기기에서 더 새 기록을 공유했습니다. 이 기기의 기록은 그대로 저장돼 있고, 공유만 멈춘 상태입니다.';

  @override
  String get partnerShareThisDevice => '이 기기의 기록으로 공유하기';

  @override
  String get plansTitle => '공동 루틴';

  @override
  String get planNew => '새 공동 루틴';

  @override
  String get planJoin => '코드로 참여';

  @override
  String get planHint => '첫 줄은 제목, 그다음은 한 줄에 한 종목\n예: 스쿼트 4세트';

  @override
  String get planDateNone => '날짜 미정';

  @override
  String planSetsCount(int n) {
    return '$n세트';
  }

  @override
  String get planSave => '제안하기';

  @override
  String get planStateLocal => '이 기기에만 있는 초안 · 서버에 아직 올라가지 않았습니다';

  @override
  String get planStateDraft => '초안 · 아직 혼자입니다';

  @override
  String planStateWaiting(int v) {
    return '상대 확인 대기 · 버전 $v';
  }

  @override
  String planStateNeedsMe(String name, int v) {
    return '$name 님이 고쳤습니다 · 버전 $v 확인이 필요합니다';
  }

  @override
  String planStateAgreed(int v) {
    return '합의 완료 · 버전 $v';
  }

  @override
  String get planStateWithdrawn => '함께 계획이 끝났습니다 · 합의본과 내 목표는 남아 있습니다';

  @override
  String planAccept(int v) {
    return '버전 $v 수락';
  }

  @override
  String get planChanged => '마지막 합의본에서 바뀐 것';

  @override
  String planAdded(String x) {
    return '추가: $x';
  }

  @override
  String planRemoved(String x) {
    return '빠짐: $x';
  }

  @override
  String planSetsChanged(String x) {
    return '세트 수 변경: $x';
  }

  @override
  String get planReordered => '순서가 바뀌었습니다';

  @override
  String get planDateChanged => '예정 날짜가 바뀌었습니다';

  @override
  String get planTitleChanged => '제목이 바뀌었습니다';

  @override
  String planLastAgreed(int v) {
    return '마지막 합의본 · 버전 $v';
  }

  @override
  String get planConflict => '상대가 먼저 고쳤습니다. 내 초안은 그대로 있습니다.';

  @override
  String planLatest(int v) {
    return '상대가 고친 최신 계획 · 버전 $v';
  }

  @override
  String get planKeepMine => '내 초안으로 다시 제안';

  @override
  String get planTakeLatest => '최신 계획으로 바꾸기';

  @override
  String get planMyTarget => '내 목표';

  @override
  String planPartnerTarget(String name, String t) {
    return '$name: $t';
  }

  @override
  String get planTargetHint => '예: 100 5 또는 100kg 5회 x3 메모';

  @override
  String get planInvite => '초대 코드 만들기';

  @override
  String get planStart => '이 루틴으로 시작';

  @override
  String get planStartSolo => '본인용 사본으로 시작';

  @override
  String get planStartSoloNote =>
      '아직 합의 전입니다. 지금 시작하면 공동 합의본이 아니라 본인용 사본으로 시작합니다.';

  @override
  String get planOpenWorkout => '시작한 운동 열기';

  @override
  String get planCopyNext => '다음 운동으로 복사';

  @override
  String get planWithdraw => '함께 계획 그만두기';

  @override
  String get planCompare => '계획과 실제';

  @override
  String planDoneSets(String name, int planned, int done) {
    return '$name · 계획 $planned세트 · 수행 $done세트';
  }

  @override
  String planAddedActual(String x) {
    return '계획에 없던 운동: $x';
  }

  @override
  String planSkipped(String x) {
    return '하지 않은 운동: $x';
  }

  @override
  String planStartedFrom(int v) {
    return '공동 루틴 합의본(버전 $v)에서 시작했습니다';
  }

  @override
  String planStartedSolo(int v) {
    return '본인용 사본(버전 $v, 합의 전)에서 시작했습니다';
  }

  @override
  String get planShareLink => '초대 링크 보내기';

  @override
  String planShareText(String url) {
    return 'setpad에서 운동 계획을 같이 짜요: $url';
  }

  @override
  String get planLinkCopied => '링크를 복사했습니다. 하루 동안 한 번 쓸 수 있습니다.';

  @override
  String get planLinkJoining => '초대받은 계획에 참여하는 중…';

  @override
  String get nearbyHint => '아이폰끼리는 이 화면을 연 채 두 기기를 가까이 대도 연결됩니다.';

  @override
  String get planPropose => '공동 루틴으로 제안';

  @override
  String get togetherStart => '같이 시작';

  @override
  String get togetherAlternate => '교대로';

  @override
  String togetherWaiting(String name) {
    return '$name 님을 기다리는 중…';
  }

  @override
  String get togetherWaitingHint => '상대 화면에 요청이 뜹니다. 안 보이면 상대 앱이 최신인지 확인하세요.';

  @override
  String togetherInvite(String name) {
    return '$name 님이 같이 하자고 합니다';
  }

  @override
  String get togetherInviteAlternate => '교대 · 상대가 먼저';

  @override
  String get togetherLeave => '그만';

  @override
  String get togetherRejoin => '다시 들어가기';

  @override
  String togetherWith(String name) {
    return '$name 님과 같이';
  }

  @override
  String get togetherTheirTurn => '상대 차례';

  @override
  String togetherLeftBeat(String name, int n) {
    return '$name 님은 $n번째에서 멈춤';
  }

  @override
  String togetherLeftRound(String name, int n) {
    return '$name 님은 $n라운드에서 멈춤';
  }

  @override
  String get togetherMe => '나';

  @override
  String get togetherLog => '기록';

  @override
  String get mealLogAs => '식단으로 기록';

  @override
  String get proxyWrite => '대신 적기';

  @override
  String proxyWriting(String name) {
    return '$name 님의 기록을 적는 중';
  }

  @override
  String get proxyDefaultName => '상대';

  @override
  String get proxyHand => '건네기';

  @override
  String get proxyBack => '내 기록으로';

  @override
  String proxyShareText(String url) {
    return '같이 운동하며 대신 적은 기록입니다. setpad 에서 열어 받으면 내 운동 기록이 됩니다.\n$url';
  }

  @override
  String handoffOffer(String name) {
    return '$name 님이 내 기록을 적어 주었습니다';
  }

  @override
  String get handoffTake => '받기';

  @override
  String get handoffFailed => '기록을 받지 못했습니다. 링크가 만료됐거나 네트워크 문제일 수 있습니다.';

  @override
  String get handoffSignIn => '건네받은 기록을 받으려면 로그인이 필요합니다.';

  @override
  String partnerInviteMore(String code) {
    return '한 명 더 초대 · 코드 $code';
  }

  @override
  String get proxyWhose => '누구의 기록을 적을까요?';

  @override
  String planMemberAccepted(String name) {
    return '$name 님 동의함';
  }

  @override
  String planMemberWaiting(String name) {
    return '$name 님 확인 전';
  }
}
