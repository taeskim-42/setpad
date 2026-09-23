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
  String setsPerLineMax(int n) {
    return '한 번에 $n세트까지예요. 줄을 나눠 적어 주세요.';
  }

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
  String get aiFallbackQuota => '오늘 적기 도움을 다 써서 적은 그대로 만들었어요';

  @override
  String get aiFallbackOffline => '연결이 안 돼 적은 그대로 만들었어요. 설정은 칸의 ⚙에서 붙일 수 있어요';

  @override
  String get aiFallbackServer => '서버가 답하지 않아 적은 그대로 만들었어요. 설정은 칸의 ⚙에서 붙일 수 있어요';

  @override
  String get aiFallbackUnread =>
      '설정으로 읽을 말을 찾지 못해 적은 그대로 만들었어요. 설정은 칸의 ⚙에서 붙일 수 있어요';

  @override
  String get inputNameTooLong => '운동 이름은 120자까지예요 — 줄을 나눠 적어 주세요';

  @override
  String get inputTooLong => '600자가 넘는 글은 읽지 않아요 — 줄을 나눠 적어 주세요';

  @override
  String get setupAdd => '설정 붙이기';

  @override
  String setupUnparsed(String words) {
    return '설정에 못 옮긴 말: $words — 제목에 그대로 남아요';
  }

  @override
  String setupDropped(String numbers) {
    return '글에 없는 수라 뺐어요: $numbers';
  }

  @override
  String get setupNameMissing => '운동 이름을 적어 주세요';

  @override
  String get setupNameTooLong => '운동 이름은 120자까지예요';

  @override
  String get setupWeightInvalid => '0보다 크고 2000 이하인 수로 적어 주세요';

  @override
  String get setupCountInvalid => '1 이상의 정수로 적어 주세요 — 범위·시간은 제목에 남겨 두세요';

  @override
  String get setupMergeUp => '앞 운동에 합치기';

  @override
  String get setupKeepApart => '따로 두기';

  @override
  String get setupRepsOnly => '횟수만 기록';

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
  String get accountSignIn => '로그인';

  @override
  String get accountSignOut => '로그아웃';

  @override
  String get planMonthly => '월 이용권';

  @override
  String get planYearly => '연 이용권';

  @override
  String planYearlyTrial(int days, String price) {
    return '$days일 무료 체험 뒤 연 $price. 체험이 끝나기 24시간 전까지 해지하면 청구되지 않습니다.';
  }

  @override
  String planYearlyTrialPlates(int n) {
    return '무료 체험 동안은 원판 $n장까지 채웁니다. 결제가 시작되면 매달 채움으로 바뀝니다.';
  }

  @override
  String get planActive => '이용 중';

  @override
  String get restorePurchases => '구매 복원';

  @override
  String get subscriptionRenews =>
      '구독은 현재 기간이 끝나기 24시간 전까지 해지하지 않으면 같은 값으로 자동 갱신됩니다. 해지는 스토어의 구독 관리에서 언제든 할 수 있습니다.';

  @override
  String get termsOfUse => '이용약관(EULA)';

  @override
  String get inputQuotaSpent => '오늘 적기 도움을 다 썼어요. 직접 적으면 그대로 기록돼요.';

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
  String get metricE1rm => '추정 1RM';

  @override
  String get metricMaxReps => '최다 반복';

  @override
  String get metricLongest => '최장';

  @override
  String get metricFirst => '처음';

  @override
  String get metricDaysSince => '쉰 날';

  @override
  String get metricDistance => '총 거리';

  @override
  String get metricDuration => '총 시간';

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
  String get queryByExercise => '운동별';

  @override
  String get queryByDay => '날짜별';

  @override
  String get queryByWeek => '주별 (월요일 시작)';

  @override
  String get queryByMonth => '월별';

  @override
  String get queryByWeekday => '요일별';

  @override
  String get queryTotalSum => '합계';

  @override
  String get queryTotalMean => '평균';

  @override
  String queryDiff(String later, String earlier) {
    return '차이 ($later − $earlier)';
  }

  @override
  String queryExclude(String names) {
    return '$names 제외';
  }

  @override
  String queryMemo(String terms) {
    return '메모: $terms';
  }

  @override
  String queryLastSessions(int n) {
    return '마지막 $n번';
  }

  @override
  String queryBottomLimit(int n) {
    return '하위 $n개 · 오름차순';
  }

  @override
  String queryOutOfScope(String names) {
    return '이 측정에 쓸 값이 없어 뺐어요: $names';
  }

  @override
  String queryMissingFor(String names) {
    return '값이 빠진 세트가 있어 계산하지 않았어요: $names';
  }

  @override
  String get queryE1rmRule => '추정 1RM = 무게 × (1 + 횟수 ÷ 30), 1–10회 세트만';

  @override
  String queryMore(int n) {
    return '외 $n개';
  }

  @override
  String queryRankingLimit(int n) {
    return '상위 $n개 · 내림차순';
  }

  @override
  String get queryCompareChip => '비교';

  @override
  String get queryNoRecord => '기록 없음';

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
  String get proTitle => 'Pro 이용권';

  @override
  String get proBody =>
      '기록에 묻는 질문은 원판을 씁니다. 질문 하나에 보통 1장쯤 들고, 답에 실제로 쓴 만큼만 빠집니다. 운동과 식단을 적을 때 돕는 적기 도움은 원판을 쓰지 않습니다.';

  @override
  String proFree(int n, int sets) {
    return '무료: 적기 도움 하루 $n번 · 세트 $sets개를 채운 날 원판 1장';
  }

  @override
  String proPaid(int n, int input) {
    return 'Pro: 매달 원판 $n장까지 채움 · 적기 도움 하루 $input번';
  }

  @override
  String get proEverythingElseFree =>
      '기록·타이머·손목 알림·건강 앱 연동·같이 하기·체육관은 이용권 없이도 전부 됩니다.';

  @override
  String get proOwned => '이용 중입니다. 고맙습니다.';

  @override
  String get proSignInFirst => '이용권은 계정에 붙습니다. 먼저 로그인해 주세요.';

  @override
  String platesBalance(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '남은 원판 $nString장';
  }

  @override
  String platesSpent(num spent, num balance) {
    final intl.NumberFormat spentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String spentString = spentNumberFormat.format(spent);
    final intl.NumberFormat balanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String balanceString = balanceNumberFormat.format(balance);

    return '원판 $spentString장 사용 · 남은 원판 $balanceString장';
  }

  @override
  String noPlates(int sets) {
    return '원판이 모자라요. 세트 $sets개를 채운 날마다 1장씩 받아요.';
  }

  @override
  String noPlatesSignIn(int n) {
    return '로그인하기 · 새 계정은 원판 $n장';
  }

  @override
  String platesGetPro(int n) {
    return 'Pro 보기 · 매달 $n장';
  }

  @override
  String get purchaseNotConfirmed =>
      '구매를 확인하지 못했습니다. 결제가 됐다면 잠시 뒤 ‘구매 복원’을 눌러 주세요.';

  @override
  String get purchaseOtherAccount => '이 구매는 다른 계정에 연결돼 있습니다. 그 계정으로 로그인해 주세요.';

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
  String get fitAll => '오늘 운동';

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
  String get mealTextUnknown =>
      '무슨 음식인지 몰라 열량을 어림하지 못했어요. 끼니 줄을 눌러 음식 이름이나 양을 더 적으면 다시 어림해요.';

  @override
  String get mealTextOffline =>
      '연결이 안 돼 열량을 어림하지 못했어요. 끼니 줄을 누르고 Enter 를 누르면 다시 어림해요.';

  @override
  String get mealTextTooLong =>
      '500자가 넘는 식단 글은 어림하지 않아요. 끼니 줄을 눌러 나눠 적으면 어림해요.';

  @override
  String queryTooLong(int max) {
    return '질문은 $max자까지예요. 줄여서 물어 주세요.';
  }

  @override
  String get queryPressEnter => 'Enter 를 누르면 기록에 물어볼 수 있어요.';

  @override
  String get mealRetry => '다시 어림';

  @override
  String kcalAtLeast(int n) {
    return '${n}kcal 이상';
  }

  @override
  String mealTextPartial(int n) {
    return '적은 ${n}kcal만 합계에 넣었어요. 나머지 음식은 열량을 몰라요.';
  }

  @override
  String mealTextBelowTyped(int n) {
    return '어림값이 글에 적은 ${n}kcal보다 작아 받지 않았어요. 적은 ${n}kcal만 합계에 넣었어요.';
  }

  @override
  String queryLimit(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'exercises': '운동은 한 번에 8개까지 물을 수 있어요. 나눠서 물어 주세요.',
      'measures': '한 번에 세 가지까지 셀 수 있어요. 나눠서 물어 주세요.',
      'ranking': '순위는 20개까지 보여 줄 수 있어요. 20개 이하로 물어 주세요.',
      'sessions': '\'마지막 N번\'은 100번까지예요. 더 길게 보려면 기간으로 물어 주세요. 예: 올해',
      'days': '\'최근 N일\'은 3660일(약 10년)까지예요. 더 길게 보려면 전체 기간으로 물어 주세요.',
      'compare': '한 번에 4가지까지 견줄 수 있어요. 나눠서 물어 주세요.',
      'compareGrouped':
          '견주기와 운동·날·주·월·요일별 묶음은 한 질문에 함께 셀 수 없어요. 둘 중 하나로 물어 주세요.',
      'groupedMeasure':
          '날·주·월·요일별로 묶으면 한 가지만 셀 수 있고, 추이·마지막·처음·안 한 지는 묶을 수 없어요.',
      'ordering': '순위·합계·평균은 운동별이나 주별처럼 묶어서 물어 주세요.',
      'datesTotal': '마지막·처음 날짜는 더하거나 평균 낼 수 없어요.',
      'other': '이 질문은 기록 검색이 셀 수 없는 모양이에요. 나눠서 물어 주세요.',
    });
    return '$_temp0';
  }

  @override
  String policyNumberRejected(String text, String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'decimal': '\'$text\' — 소수는 받지 않아요. 정수로 적어 주세요. 예: 14',
      'range': '\'$text\' — 범위가 아니라 수 하나로 적어 주세요. 예: 14',
      'negative': '\'$text\' — 0보다 작은 수는 받지 않아요. 예: 14',
      'unit': '\'$text\' — 이 칸은 일·회로 세요. 시간·주·달은 일 수로 바꿔 적어 주세요. 예: 14',
      'many': '\'$text\' — 수는 하나만 적어 주세요. 예: 14',
      'other': '\'$text\' 에서 일·회 수를 읽지 못했어요. 숫자로 적어 주세요. 예: 14',
    });
    return '$_temp0';
  }

  @override
  String get mealSources => '출처';

  @override
  String get mealSourcesTitle => '열량 근거';

  @override
  String get mealSourcesNote =>
      '아래 표의 값으로 계산했어요. 누르면 원본 표에서 같은 이름을 찾아 보여 줘요. 표에 없는 음식은 AI가 어림한 값이에요.';

  @override
  String mealSourcePer(String unit, String kcal) {
    return '100$unit당 ${kcal}kcal';
  }

  @override
  String get mealSourceMfds => '식약처 식품영양성분 DB';

  @override
  String get mealSourceUsda => 'USDA FoodData Central';

  @override
  String get mealAmountInvalid => '0 이상의 숫자를 입력해 주세요.';

  @override
  String dayEnergyFull(String intake, String burned, String diff) {
    return '섭취 $intake · 운동 $burned = ${diff}kcal';
  }

  @override
  String dayEnergyApprox(String intake, String burned, String diff) {
    return '섭취 약 $intake · 운동 $burned = 약 ${diff}kcal';
  }

  @override
  String get dayBurnedMissing => '운동 소모량 미측정 · 차이 계산 불가';

  @override
  String dayBurnedOnly(String n) {
    return '운동 ${n}kcal · 식단 미기록';
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
  String get mealAutoLogged => '끼니로 남겼어요';

  @override
  String get mealAutoUndo => '운동으로 바꾸기';

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

  @override
  String deleteNoteAsk(String title) {
    return '\"$title\" 기록을 지울까요?';
  }

  @override
  String get mealsTitle => '먹은 것';

  @override
  String get recordMenu => '더 보기';

  @override
  String dayIntakeOnly(String intake) {
    return '섭취 ${intake}kcal · 운동 소모 미측정';
  }

  @override
  String dayIntakeOnlyApprox(String intake) {
    return '섭취 약 ${intake}kcal · 운동 소모 미측정';
  }

  @override
  String dayUnknownMeals(int m) {
    return '열량 미상 $m건';
  }

  @override
  String get healthDataTitle => '건강 데이터';

  @override
  String get healthDataIntro =>
      'setpad가 건강 앱(Apple 건강, 헬스 커넥트)과 주고받는 것과 그 이유입니다.';

  @override
  String get healthDataWrite => '쓰기 · 운동 — 기록을 마치면 그 운동을 운동 세션으로 남깁니다.';

  @override
  String get healthDataCalories =>
      '읽기 · 활동 칼로리 — 운동한 시간 동안 워치가 잰 활동 칼로리를 그 기록에 붙입니다. 잰 것이 없으면 칼로리를 표시하지 않습니다.';

  @override
  String get healthDataHeart =>
      '읽기 · 심박수 — 타바타 휴식 중 심박이 그 라운드의 최고치보다 25bpm 내려오면 휴식을 끝내고 다음 라운드 시작을 알립니다. 쉬는 동안 타이머 줄에 ♥ 지금 → 목표로 보입니다. 심박이 없거나 90초보다 오래된 값이면 휴식은 시간대로 끝납니다.';

  @override
  String get healthDataStays =>
      '건강 앱에서 읽은 값은 기기 밖으로 나가지 않습니다. 서버로 보내지 않고, 광고나 마케팅에 쓰지 않습니다.';

  @override
  String get healthDataRevokeIos =>
      '권한은 iPhone 설정 → 개인정보 보호 및 보안 → 건강 → setpad에서 언제든 끌 수 있습니다.';

  @override
  String get healthDataRevokeAndroid =>
      '권한은 헬스 커넥트 → 앱 권한 → setpad에서 언제든 끌 수 있습니다.';

  @override
  String get healthDataPrivacy => '개인정보 처리방침';

  @override
  String get restAlarmTitle => '다음 라운드 — 심박이 내려왔어요';

  @override
  String liveSetBusy(String name) {
    return '$name님이 이 세트를 고치는 중이에요. 다 고친 뒤에 눌러 주세요.';
  }

  @override
  String liveExerciseBusy(String name) {
    return '$name님이 지금 이 운동을 적고 있어요.';
  }

  @override
  String liveExerciseRemoved(String exercise) {
    return '같이 하는 사람이 $exercise을(를) 지웠어요. 치던 글은 입력 줄에 남아 있어요.';
  }

  @override
  String get trainerReport => '트레이너 보고';

  @override
  String get trainerUnread => '새 보고서';

  @override
  String trainerRanAt(String when) {
    return '$when 정리';
  }

  @override
  String get trainerRunNow => '지금 정리하기';

  @override
  String get trainerNoReport => '아직 정리된 보고서가 없어요. 지금 정리해 볼까요?';

  @override
  String get trainerOutdated => '이 보고서는 새 버전에서 볼 수 있어요. 앱을 업데이트해 주세요.';

  @override
  String get trainerFailed => '서버에 닿지 못했어요. 잠시 뒤에 다시 해 주세요.';

  @override
  String get trainerActUnknown => '결과를 확인하지 못했어요. 다시 눌러도 두 번 기록되지 않아요.';

  @override
  String get trainerDone => '에이전트가 처리한 일';

  @override
  String get trainerToday => '오늘 수업';

  @override
  String get trainerTodo => '확인할 일';

  @override
  String get trainerAllClear => '확인할 일을 모두 처리했어요.';

  @override
  String get trainerAttendance => '마무리 전 수업';

  @override
  String trainerVisited(String time) {
    return '방문 확인 $time';
  }

  @override
  String trainerFinishAll(int count) {
    return '모두 완료 ($count)';
  }

  @override
  String trainerFinishAsk(int count) {
    return '$count건 완료 — PT 이용권에서 1회씩 차감돼요.';
  }

  @override
  String get trainerFinish => '완료하기';

  @override
  String get trainerJoinRequest => '등록 요청 — 웹 CRM 오늘 화면에서 확인해 주세요.';

  @override
  String get trainerBook => '잡기';

  @override
  String get trainerSend => '보내기';

  @override
  String get trainerPaid => '결제 받음';

  @override
  String get trainerContacted => '연락함';

  @override
  String get trainerLater => '나중에';

  @override
  String trainerPrice(int price) {
    final intl.NumberFormat priceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String priceString = priceNumberFormat.format(price);

    return '$priceString원';
  }

  @override
  String trainerStarts(String d) {
    return '$d부터';
  }

  @override
  String get trainerPayHow => '어떻게 받으셨나요?';

  @override
  String get trainerPaidListPrice =>
      '상품가 그대로 결제로 기록돼요. 할인·나눠 받기는 웹 CRM 회원 화면의 회원권 탭에서 등록해 주세요.';

  @override
  String get payCard => '카드';

  @override
  String get payCash => '현금';

  @override
  String get payTransfer => '계좌이체';

  @override
  String get payOther => '기타';

  @override
  String get agentSettings => '에이전트 설정';

  @override
  String get agentEnabled => '정해진 시각에 정리';

  @override
  String get agentTimes => '정리 시각';

  @override
  String get agentAddTime => '시각 추가';

  @override
  String get agentDays => '요일';

  @override
  String get agentAutoConfirm => 'PT 신청 바로 확정';

  @override
  String get agentModes => '업무별 방식';

  @override
  String get agentModesHelp =>
      '직접 — 에이전트는 손대지 않아요. 초안 — 에이전트가 준비하면 내가 눌러 처리해요. 자동 — 에이전트가 처리해요.';

  @override
  String get agentModeOff => '직접';

  @override
  String get agentModeDraft => '초안';

  @override
  String get agentModeAuto => '자동';

  @override
  String get taskPtSchedule => 'PT 일정';

  @override
  String get taskRenewal => '재등록·재결제';

  @override
  String get taskAttendance => '출결 정리';

  @override
  String get taskRoutine => '루틴 준비';

  @override
  String get taskContact => '회원 연락';

  @override
  String get gymPolicy => '도장 방침';

  @override
  String get policyRenewalDays => '재등록 안내 시점 (만료 며칠 전)';

  @override
  String get policyLowSessions => 'PT 부족 기준 (PT 예약 가능 횟수)';

  @override
  String get policyAwayDays => '미방문 기준 (일)';

  @override
  String get policyLapsedDays => '이탈 기간 (일)';

  @override
  String get policyOffer => '재등록 안내 문구';

  @override
  String get policySave => '방침 저장';

  @override
  String get policySaved => '저장했어요.';

  @override
  String get trainerWhichGym => '어느 도장인가요?';

  @override
  String get trainerBack => '돌아가기';

  @override
  String get trainerCopy => '문구 복사';

  @override
  String get trainerCopied => '복사했어요';

  @override
  String get settingsTrainer => '트레이너';
}
