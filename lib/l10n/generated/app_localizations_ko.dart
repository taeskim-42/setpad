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
  String get setupRepsOnly => '횟수만 기록';

  @override
  String setupSplit(int count) {
    return '운동 $count개로 나눴어요';
  }

  @override
  String get setupMergeAll => '한 칸으로 합치기';

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
  String get mealAdd => '식단 남기기';

  @override
  String get mealWrite => '글로 적기';

  @override
  String get mealTypeHint => '음식은 운동 이름 줄에 바로 쳐도 식단으로 남아요';

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
  String sameDayToday(String time) {
    return '오늘 $time에 남긴 다른 기록';
  }

  @override
  String sameDayOn(String date, String time) {
    return '$date $time에 남긴 다른 기록';
  }

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

    return '${nString}kcal 추정';
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
      'measures': '한 번에 네 가지까지 셀 수 있어요. 나눠서 물어 주세요.',
      'ranking': '순위는 20개까지 보여 줄 수 있어요. 20개 이하로 물어 주세요.',
      'sessions': '\'마지막 N번\'은 100번까지예요. 더 길게 보려면 기간으로 물어 주세요. 예: 올해',
      'days': '\'최근 N일\'은 3660일(약 10년)까지예요. 더 길게 보려면 전체 기간으로 물어 주세요.',
      'compare': '한 번에 6가지까지 견줄 수 있어요. 나눠서 물어 주세요.',
      'compareGrouped':
          '견주기와 운동·날·주·월·요일별 묶음은 한 질문에 함께 셀 수 없어요. 둘 중 하나로 물어 주세요.',
      'groupedMeasure':
          '날·주·월·요일별로 묶어 여러 범위를 견주면 한 가지만 셀 수 있고, 추이·마지막·처음·안 한 지는 묶을 수 없어요.',
      'ordering': '순위·합계·평균은 운동별이나 주별처럼 묶어서 물어 주세요.',
      'datesTotal': '마지막·처음 날짜는 더하거나 평균 낼 수 없어요.',
      'perMeasure':
          '날당·주당·달당 평균은 세트·횟수·볼륨·거리·시간·날 수·칼로리처럼 더하는 수에만 낼 수 있어요. 최고·평균 무게는 기간으로 물어 주세요.',
      'shareMeasure': '비중은 세트 수·볼륨처럼 더하는 수로만 낼 수 있어요.',
      'trainedMeasure':
          '운동한 날·쉰 날로 고르기는 먹은·태운 칼로리에만 써요. 운동 기록은 모두 운동한 날의 것이에요.',
      'sameSeries': '견줄 두 범위가 같게 읽혔어요. 무엇과 무엇을 견줄지 적어 주세요.',
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
    return '먹은 것 $intake · 운동 $burned = ${diff}kcal';
  }

  @override
  String dayEnergyApprox(String intake, String burned, String diff) {
    return '먹은 것 $intake · 운동 $burned = ${diff}kcal (추정)';
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
  String get energyBurned => '운동';

  @override
  String get energyDifference => '차이';

  @override
  String get energyDiffFormula => '먹은 것 − 운동';

  @override
  String get energyDiffExplain =>
      '기록한 먹은 것에서 운동으로 쓴 칼로리를 뺀 값이에요. + 면 운동으로 쓴 것보다 더 먹은 것이고, − 면 덜 먹은 거예요.\n\n기초대사량과 일상 활동으로 쓰는 칼로리는 들어 있지 않아서, 이 값이 곧 살이 찌거나 빠지는 양은 아니에요.';

  @override
  String get estimateTag => '추정';

  @override
  String get energyNotLogged => '미기록';

  @override
  String get energyNotMeasured => '미측정';

  @override
  String get recordMenu => '더 보기';

  @override
  String dayIntakeOnly(String intake) {
    return '먹은 것 ${intake}kcal · 운동 소모 미측정';
  }

  @override
  String dayIntakeOnlyApprox(String intake) {
    return '먹은 것 ${intake}kcal (추정) · 운동 소모 미측정';
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

  @override
  String get aiSetting => 'AI 도움';

  @override
  String get aiOff => 'AI 도움이 꺼져 있어 적은 그대로 두었어요. 설정 › AI 도움에서 켤 수 있어요';

  @override
  String get aiOffPhoto =>
      'AI 도움이 꺼져 있어 사진으로 어림하지 않았어요. 식단 글로 ‘김밥 450kcal’처럼 적으면 그대로 들어가요';

  @override
  String get answerNeedsTwoDays => '날이 둘 이상 있어야 해요';

  @override
  String get answerNoBase => '기준 값이 없어요';

  @override
  String answerPerWeek(String value) {
    return '주당 $value';
  }

  @override
  String answerPerMonth(String value) {
    return '달당 $value';
  }

  @override
  String answerTimesAfter(int n) {
    return '최고 이후 $n번 했어요';
  }

  @override
  String get answerTimesUnit => '번';

  @override
  String answerTimes(int n) {
    return '$n번';
  }

  @override
  String answerStreak(int n) {
    return '$n일 연속';
  }

  @override
  String answerRestDays(int n) {
    return '$n일 쉼';
  }

  @override
  String get answerUntilToday => '오늘';

  @override
  String answerEveryDays(String value) {
    return '보통 $value일마다';
  }

  @override
  String answerMeanEvery(String value) {
    return '평균 $value일마다';
  }

  @override
  String answerGapSpread(int a, int b, int c, int d) {
    return '연달아 $a번 · 하루 쉬고 $b번 · 이틀 쉬고 $c번 · 사흘 이상 쉬고 $d번';
  }

  @override
  String answerLongestIncluded(int n) {
    return '가장 긴 쉼 $n일이 들어 있어요';
  }

  @override
  String get answerNoMeals => '끼니를 적은 날이 없어요';

  @override
  String answerAbout(String value) {
    return '약 $value';
  }

  @override
  String answerMealDays(int n) {
    return '끼니를 적은 $n일';
  }

  @override
  String queryUnknownMeals(int n) {
    return '열량을 모르는 끼니 $n개는 합에 없어요';
  }

  @override
  String get answerNoWatch => '워치로 잰 기록이 없어요';

  @override
  String answerWatchDays(int n) {
    return '워치로 잰 $n일';
  }

  @override
  String get answerNoBoth => '섭취와 소모가 둘 다 있는 날이 없어요';

  @override
  String answerBothDays(int n) {
    return '섭취·소모가 둘 다 있는 $n일';
  }

  @override
  String answerIntakeOnlyDays(int n) {
    return '섭취만 있는 $n일은 뺐어요';
  }

  @override
  String answerMonths(int n) {
    return '$n달';
  }

  @override
  String get metricChangePct => '변화율';

  @override
  String get metricDaysSinceBest => '최고 이후 날';

  @override
  String get metricSessionsSinceBest => '최고 이후 횟수';

  @override
  String get metricMeanReps => '세트당 반복';

  @override
  String get metricLongestStreak => '최장 연속';

  @override
  String get metricLongestGap => '최장 공백';

  @override
  String get metricMeanGap => '운동 간격';

  @override
  String get metricIntake => '섭취 열량';

  @override
  String get metricBurned => '소모 열량';

  @override
  String get metricBalance => '섭취 − 소모';

  @override
  String get queryAlone => '혼자 한 날';

  @override
  String get queryTogether => '같이 한 날';

  @override
  String get queryByPart => '부위별';

  @override
  String get queryCanSee => '기록으로는 무게·횟수·세트·운동한 날·끼니 열량을 볼 수 있어요';

  @override
  String get queryDiffColumn => '차이';

  @override
  String get queryFutureCell => '아직 오지 않은 기간';

  @override
  String get queryGrowthRate => '성장은 주당 속도로 순위를 매겼어요 — 기간이 달라도 공정하게';

  @override
  String get queryHandoff => '건네받은 기록만';

  @override
  String get queryNoHandoff => '건네받은 기록 제외';

  @override
  String queryHandoffCount(int n) {
    return '건네받은 기록 $n개 제외';
  }

  @override
  String get queryHoursNote =>
      '시각은 기록을 만든 때 기준이에요 — 나중에 몰아 적은 기록은 적은 시각으로 들어가요';

  @override
  String get queryMixedWeights => '여러 운동을 섞은 무게예요';

  @override
  String get queryNcBodyweight =>
      '체중은 기록에 없어요 — 질문에 체중을 적으면 그 수와 견줘요(예: 체중 80인데 데드 몇 배?)';

  @override
  String get queryNcWeightForecast =>
      '몇 kg 이 될지는 계산하지 않아요 — 기록에는 먹은 것과 운동 소모만 있고, 기초대사량·일상 활동으로 쓰는 칼로리가 없어요';

  @override
  String get queryNcHeartRate =>
      '기록 검색은 아직 심박을 안 봐요 — 운동별·휴식별 심박은 세트 시각이 없어 볼 수 없어요';

  @override
  String get queryNeverMark => '적은 적 없음';

  @override
  String get queryNoBaseRatio => '기준 값이 없어 비율을 못 내요';

  @override
  String get queryNoneCell => '이 범위엔 기록 없음';

  @override
  String get queryNoRoutine => '루틴 아닌 날';

  @override
  String get queryRoutine => '루틴으로 한 날';

  @override
  String get queryOngoing => '진행 중';

  @override
  String get queryOverlap => '운동일수는 겹치는 날이 있어 비중을 못 내요 — 세트 수로 물어 주세요';

  @override
  String queryPart(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'chest': '가슴',
      'back': '등',
      'legs': '다리',
      'shoulders': '어깨',
      'arms': '팔',
      'core': '코어',
      'cardio': '유산소',
      'upper': '상체',
      'lower': '하체',
      'other': '부위',
    });
    return '$_temp0';
  }

  @override
  String get queryRatioColumn => '배수';

  @override
  String get queryRatioUnits => '단위가 달라 비율을 못 내요';

  @override
  String get queryRestDay => '쉰 날';

  @override
  String get queryTrained => '운동한 날';

  @override
  String get querySetFirst => '첫 세트';

  @override
  String get querySetLast => '마지막 세트';

  @override
  String get queryShare => '비중';

  @override
  String get queryZeroFilled => '안 한 운동도 0 으로 넣었어요';

  @override
  String queryAgainst(String value) {
    return '기준 $value';
  }

  @override
  String queryAgainstLine(
    String value,
    String target,
    String ratio,
    String diff,
  ) {
    return '$value ÷ $target = $ratio배 · 차이 $diff';
  }

  @override
  String queryAlias(String name, String names) {
    return '$name = $names';
  }

  @override
  String queryDayCount(int n) {
    return '$n일';
  }

  @override
  String queryDroppedSets(int n) {
    return '값이 다른 세트 $n개 제외';
  }

  @override
  String queryHours(int from, int to) {
    return '$from–$to시';
  }

  @override
  String queryMaybe(String name) {
    return '혹시 $name?';
  }

  @override
  String queryMemoAll(String terms) {
    return '메모에 모두: $terms';
  }

  @override
  String queryMemoHit(String text, int n) {
    return '$text $n일';
  }

  @override
  String queryMemoHits(String hits) {
    return '걸린 메모: $hits';
  }

  @override
  String queryNeverPartial(String names) {
    return '$names: 적은 기록이 없어 빼고 셌어요';
  }

  @override
  String queryNeverRows(String names) {
    return '$names: 적은 기록이 없어요';
  }

  @override
  String queryNoMemo(String terms) {
    return '메모 없음: $terms';
  }

  @override
  String queryNoRepsSets(int n) {
    return '반복을 안 적은 세트 $n개 제외';
  }

  @override
  String queryNotComputable(String things) {
    return '기록에 없어 못 본 것: $things';
  }

  @override
  String queryNotComputableTail(String things) {
    return '못 보는 것: $things';
  }

  @override
  String queryNothingComputable(String things) {
    return '기록으로 답할 수 없어요: $things';
  }

  @override
  String queryNoWeightSets(int n, int reps) {
    return '무게 없는 세트 $n개 제외 (최다 $reps회)';
  }

  @override
  String queryNth(int n) {
    return '끝에서 $n번째 운동일';
  }

  @override
  String queryOtherDistance(int n, String value) {
    return '거리를 적은 $n번: $value';
  }

  @override
  String queryOtherDuration(int n, String value) {
    return '시간을 적은 $n번: $value';
  }

  @override
  String queryPartial(String names) {
    return '$names 제외';
  }

  @override
  String queryPartialChunk(int n) {
    return '($n일)';
  }

  @override
  String queryPartMembers(String part, String names) {
    return '$part: $names';
  }

  @override
  String queryPer(String per) {
    String _temp0 = intl.Intl.selectLogic(per, {
      'day': '하루 평균',
      'week': '주당',
      'month': '달당',
      'other': '평균',
    });
    return '$_temp0';
  }

  @override
  String queryPerSuffix(String per) {
    String _temp0 = intl.Intl.selectLogic(per, {
      'day': '/일',
      'week': '/주',
      'month': '/달',
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
    return '$a ÷ $b = $value배 ($percent%)';
  }

  @override
  String queryRelative(String by, int n) {
    String _temp0 = intl.Intl.selectLogic(by, {
      'day': '$n번째 날',
      'week': '$n번째 주',
      'month': '$n번째 달',
      'other': '$n번째',
    });
    return '$_temp0';
  }

  @override
  String queryRolled(String year) {
    return '아직 오지 않은 기간이라 $year년으로 읽었어요';
  }

  @override
  String querySamePeriod(int days, String earlier, String later) {
    return '같은 $days일로 견주면: $earlier → $later';
  }

  @override
  String queryShortGrowth(String names) {
    return '기록이 짧아(3일·3주 미만) 순위에서 뺐어요: $names';
  }

  @override
  String queryTimer(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tabata': '타바타',
      'bpm': 'bpm 타이머',
      'other': '타이머 없이',
    });
    return '$_temp0';
  }

  @override
  String queryUnknownPart(String names) {
    return '부위를 모르는 운동은 뺐어요: $names';
  }

  @override
  String queryUnranked(int n, String names) {
    return '값이 빠져 순위에 못 넣은 $n개: $names';
  }

  @override
  String queryWindowLengths(String lengths) {
    return '기간의 날 수가 달라요($lengths일) — 차이·비율은 주당으로 셌어요';
  }

  @override
  String queryZeroBuckets(String by, int total, int zeros) {
    String _temp0 = intl.Intl.selectLogic(by, {
      'week': '$total주 중 $zeros주는 0',
      'month': '$total달 중 $zeros달은 0',
      'other': '$total개 중 $zeros개는 0',
    });
    return '$_temp0';
  }

  @override
  String queryPossibleDays(int m, String percent) {
    return '가능한 $m일 중 $percent%';
  }

  @override
  String get queryOfflineLocal =>
      '서버에 닿지 못해 글에 적힌 운동·기간으로만 기기에서 셌어요. 연결되면 Enter 로 다시 물어보세요.';

  @override
  String get queryMisread => '이 질문은 셀 수 있는 모양으로 읽지 못했어요. 말을 바꿔 물어봐 주세요.';

  @override
  String get queryMisreadLocal =>
      '질문을 셀 수 있는 모양으로 읽지 못해 글에 적힌 운동·기간으로만 기기에서 셌어요. 말을 바꿔 물으면 다시 읽어요.';

  @override
  String get queryUnreadable =>
      '모델이 읽을 수 없는 답을 두 번 보냈어요. 연결 문제가 아니고, 그 답에는 원판이 나가지 않았어요.';

  @override
  String get queryAskAgain => '다시 묻기';

  @override
  String get queryUnreadablePaid =>
      '모델이 읽을 수 없는 답을 두 번 보냈어요. 연결 문제가 아니에요. 그 답에는 원판이 나가지 않았고, 아래 원판은 질문을 가른 첫 단계에 쓴 거예요.';

  @override
  String get queryUnreadableLocal => '그동안 글에 적힌 운동·기간으로는 기기에서 셌어요.';

  @override
  String get queryTotalUnits => '단위가 달라 합계를 못 내요';

  @override
  String queryMemoDropped(String words) {
    return '메모 조건 뺌: $words';
  }

  @override
  String queryAgainstDropped(String value) {
    return '기준 수 $value 뺌 — 질문에 무게로 적힌 수가 아니에요';
  }

  @override
  String routineDate(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.Md(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get routineHeaderToday => '오늘 루틴';

  @override
  String routineHeaderDay(String day) {
    return '$day 루틴';
  }

  @override
  String routineTomorrow(String date) {
    return '내일($date)';
  }

  @override
  String routineWhyRotation(String date, int days) {
    return '$date 운동을 $days일 동안 안 했어요 — 그날처럼 짰어요';
  }

  @override
  String routineWhyFrom(String date) {
    return '$date 그대로 짰어요';
  }

  @override
  String routineWhyNamed(String date) {
    return '$date에 같이 하던 운동으로 채웠어요';
  }

  @override
  String routinePartRest(String list) {
    return '최근 28일: $list 전';
  }

  @override
  String routinePartDays(String part, int days) {
    return '$part $days일';
  }

  @override
  String routineEstimate(int minutes) {
    return '약 $minutes분';
  }

  @override
  String routinePaceOwn(int sessions, String pace) {
    return '최근 $sessions번 운동의 세트당 $pace로 어림';
  }

  @override
  String routinePaceDefault(String pace) {
    return '기본값 세트당 $pace로 어림 — 운동을 몇 번 적으면 내 속도로 바뀌어요';
  }

  @override
  String routineMinSec(int m, int s) {
    return '$m분 $s초';
  }

  @override
  String routineReadAs(String list) {
    return '이렇게 읽었어요: $list';
  }

  @override
  String routineCopied(String date) {
    return '$date 그대로';
  }

  @override
  String routineRepsMatched(String date, int reps) {
    return '$date에 $reps회 한 무게';
  }

  @override
  String get routineTyped => '적은 대로';

  @override
  String get routineFirst => '처음';

  @override
  String routineBlank(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'light': '가볍게라 무게는 비웠어요',
      'pain': '아픈 곳이 있어 무게는 비웠어요',
      'gear': '기구가 달라 무게는 비웠어요',
      'bodyweight': '기구 무게라 비웠어요',
      'stale': '오래돼서 무게는 비웠어요',
      'repsUnmatched': '그 횟수로 그만큼 한 날이 없어 무게는 비웠어요',
      'other': '무게는 비웠어요',
    });
    return '$_temp0';
  }

  @override
  String routineReference(String sets, String date) {
    return '참고: $sets ($date)';
  }

  @override
  String routineBest(String set, String date) {
    return '참고: 최고 $set ($date)';
  }

  @override
  String routineStepped(String step, String evidence) {
    return '+$step ($evidence)';
  }

  @override
  String routineMemo(String date, String memo) {
    return '$date 메모: $memo';
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
      other: '$n일 전',
      one: '어제',
      zero: '오늘',
    );
    return '$_temp0';
  }

  @override
  String get routineFuture => '미리 보기예요 — 그날 \'루틴\'을 치면 그날 기록으로 시작할 수 있어요';

  @override
  String routineRefused(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'diet': '식단은 짜 드리지 않아요 — 끼니를 적으면 열량은 볼 수 있어요',
      'medical': '재활·수술 뒤 운동은 판단하지 않아요 — 의사·치료사에게 받은 운동을 적으면 그대로 루틴으로 만들어요',
      'drug': '약물은 도와드리지 않아요',
      'program': '한 번에 하루치만 짜요 — 오늘 루틴이에요',
      'logging': '안 한 세트를 완료로 적지는 않아요 — 할 때 눌러 주세요',
      'format': 'EMOM·슈퍼세트·서킷 타이머는 없어요 — 순서만 짰어요(타바타·bpm 은 돼요)',
      'person': '다른 사람 루틴은 짜 드리지 않아요 — 내 기록의 운동 이름만 보여요',
      'other': '운동 기록과 루틴만 도와드려요',
    });
    return '$_temp0';
  }

  @override
  String routineNotStated(String what) {
    return '글에 없는 수라 뺐어요: $what';
  }

  @override
  String routineUnmet(String what) {
    return '못 맞춘 조건: $what';
  }

  @override
  String routineKeyName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'when': '날짜',
      'from': '지난 날',
      'parts': '부위',
      'pattern': '밀기·당기기',
      'exercises': '운동',
      'exclude': '뺄 운동',
      'avoid': '피할 부위',
      'pain': '아픈 곳',
      'equipment': '기구',
      'count': '운동 수',
      'minutes': '시간',
      'intensity': '세기',
      'timer': '타이머',
      'targets': '적은 수',
      'delta': '증감',
      'other': '조건',
    });
    return '$_temp0';
  }

  @override
  String routineUnknownName(String name) {
    return '사전에 없어 뺐어요: $name';
  }

  @override
  String get routineNoSuchDay => '그런 날이 없어요 — 기록으로 짰어요';

  @override
  String routineExcludeAbsent(String name) {
    return '뺄 운동이 원래 없어요: $name';
  }

  @override
  String routineNoneMatched(String what) {
    return '기록한 $what 운동이 없어요 — 골라 넣을 수 있어요';
  }

  @override
  String routineFewer(int n) {
    return '기록으로 넣을 운동이 $n개예요';
  }

  @override
  String routineOtherUnit(String unit) {
    return '$unit로 적은 세트는 그대로 뒀어요';
  }

  @override
  String get routineBpmRange => 'bpm 은 10–120 이에요 — 타이머 없이 넣었어요';

  @override
  String routineIntensityLine(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'light': '가볍게: 칸마다 마지막 세트 하나를 뺐어요 — 무게는 지난번 그대로예요',
      'lightBlank': '가볍게: 칸마다 마지막 세트 하나를 뺐어요',
      'hard': '무게는 지난번 그대로예요',
      'max': '몇 kg 에 도전할지는 정하지 않아요 — 최고 기록을 옆에 적었어요',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get routineNoStep => '올릴 만큼 적어 주세요(예: +2.5kg)';

  @override
  String routinePain(String phrase, String list) {
    return '\'$phrase\' 때문에 뺀 것: $list · 무게는 비웠어요 · 괜찮은지는 판단하지 않아요';
  }

  @override
  String routinePainNone(String phrase) {
    return '\'$phrase\' — 뺀 운동은 없고 무게는 비웠어요 · 괜찮은지는 판단하지 않아요';
  }

  @override
  String get routinePainWord => '아프다는 말';

  @override
  String get routineFirstTime => '처음이에요 — 넣을 운동을 고르면 숫자 없이 들어가요';

  @override
  String routineCountFit(int count, int minutes) {
    return '$count개로 맞췄어요 — 약 $minutes분';
  }

  @override
  String routineNoMore(int minutes) {
    return '기록으로 더 넣을 운동이 없어요 — 약 $minutes분이에요';
  }

  @override
  String routineOverTime(int minutes) {
    return '말한 운동만으로 약 $minutes분이에요';
  }

  @override
  String routineOverUsual(int n, int usual) {
    return '고른 운동 $n개를 모두 넣었어요 — 평소 한 번에 하는 $usual개보다 많아요';
  }

  @override
  String routineRecentMemo(String when, String name, String memo) {
    return '$when $name 메모: $memo';
  }

  @override
  String routineRemoved(String label, String why) {
    return '뺀 것: $label — $why';
  }

  @override
  String routineRemovedWhy(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'named': '말한 운동',
      'avoid': '피할 부위',
      'unknownPart': '부위를 몰라서',
      'gear': '기구가 달라서',
      'unknownGear': '기구를 몰라서',
      'otherPart': '다른 부위라서',
      'user': '직접 뺌',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get routineRestore => '넣기';

  @override
  String routineAdd(String name) {
    return '+ $name';
  }

  @override
  String get routineOther => '다른 루틴';

  @override
  String routinePrevious(String date) {
    return '그 전($date)';
  }

  @override
  String routineByPart(String part) {
    return '$part 루틴으로 짜기';
  }

  @override
  String routineStepChip(String step) {
    return '+$step 올리기(스스로 올려 온 폭)';
  }

  @override
  String routineAskToo(String text) {
    return '이것도 물을까요: $text · 원판';
  }

  @override
  String get routineAsQuestion => '기록 질문으로 묻기 · 원판';

  @override
  String get routineNoConditions => '조건 없이 바로 짜기';

  @override
  String get routineWithConditions => '조건까지 읽어 짜기 · 원판';

  @override
  String get routineMake => '오늘 루틴 만들기';

  @override
  String routineMakePart(String part) {
    return '오늘 $part 루틴 만들기';
  }

  @override
  String get routineStart => '시작';

  @override
  String get routineStarted => '시작함 · 열기';

  @override
  String get routineWorking => '조건을 읽는 중…';

  @override
  String get routineOffline => '조건은 연결이 안 돼 못 읽었어요 — 기록으로만 짰어요';

  @override
  String get routineMisread => '조건을 읽지 못했어요 — 기록으로만 짰어요. 말을 바꾸면 다시 읽어요';

  @override
  String routineHeldBack(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'offline': '연결이 안 돼',
      'noPlates': '원판이 없어',
      'other': '모델 답을 읽지 못해',
    });
    return '$_temp0 조건(빼기·아픈 곳)을 못 읽었어요 — 루틴을 만들지 않았어요';
  }

  @override
  String routineTypedWeight(int count, String from, String to) {
    return '적은 무게로: 작업 세트 $count개 $from → $to';
  }

  @override
  String get routineTypedKept => '적은 무게는 그대로 뒀어요';

  @override
  String get routinePlatesBefore => '이 글에 앞서 원판을 썼어요 · 이번엔 0장';

  @override
  String get routineRetry => '다시 시도';

  @override
  String get routinePressEnter => 'Enter 를 누르면 조건까지 읽어 짜요 · 원판';

  @override
  String get routineFromQuestion => '루틴을 짜 달라는 말로 읽었어요';

  @override
  String routinePattern(String p) {
    String _temp0 = intl.Intl.selectLogic(p, {
      'push': '밀기',
      'pull': '당기기',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineGear(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'barbell': '바벨',
      'dumbbell': '덤벨',
      'machine': '머신',
      'cable': '케이블',
      'bodyweight': '맨몸',
      'bar': '철봉',
      'kettlebell': '케틀벨',
      'band': '밴드',
      'bench': '벤치',
      'other': '기구',
    });
    return '$_temp0';
  }

  @override
  String routineGearOnly(String list) {
    return '$list만';
  }

  @override
  String routineGearWithout(String list) {
    return '$list 없이';
  }

  @override
  String routineMinutes(int n) {
    return '$n분';
  }

  @override
  String routineCount(int n) {
    return '운동 $n개';
  }

  @override
  String routineIntensity(String k) {
    String _temp0 = intl.Intl.selectLogic(k, {
      'light': '가볍게',
      'hard': '무겁게',
      'max': '최고 도전',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineExclude(String list) {
    return '뺄 것: $list';
  }

  @override
  String routineAvoid(String list) {
    return '피할 부위: $list';
  }

  @override
  String get routinePlatesZero => '원판 0장';

  @override
  String get routineFullBody => '전신';

  @override
  String get routineNoPlates => '조건은 원판이 없어 못 읽었어요 — 기록으로만 짰어요';

  @override
  String get routineBack => '루틴으로 돌아가기';

  @override
  String queryBoundDropped(String value) {
    return '숫자 조건 $value 뺌 — 질문에 그 단위로 적힌 수가 아니에요';
  }

  @override
  String get anatomyTitle => '몸 그림';

  @override
  String get anatomyOpen => '몸 그림 — 부위별 운동과 자세 팁';

  @override
  String get anatomyPick => '몸 그림에서 운동 고르기';

  @override
  String get anatomyFront => '앞';

  @override
  String get anatomyBack => '뒤';

  @override
  String anatomyDays(int n) {
    return '$n일';
  }

  @override
  String muscleName(String m) {
    String _temp0 = intl.Intl.selectLogic(m, {
      'chest': '가슴',
      'frontDelts': '앞 어깨',
      'sideDelts': '옆 어깨',
      'rearDelts': '뒤 어깨',
      'traps': '승모근 윗부분',
      'upperBack': '등 가운데',
      'lats': '광배근',
      'lowerBack': '허리',
      'biceps': '이두',
      'triceps': '삼두',
      'forearms': '전완',
      'abs': '복근',
      'obliques': '옆구리',
      'hipFlexors': '고관절 굴곡근',
      'glutes': '엉덩이',
      'quads': '허벅지 앞',
      'hamstrings': '허벅지 뒤',
      'adductors': '허벅지 안쪽',
      'calves': '종아리',
      'other': '부위',
    });
    return '$_temp0';
  }

  @override
  String anatomyLevel(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'low': '적음',
      'mid': '중간',
      'high': '많음',
      'other': '없음',
    });
    return '$_temp0';
  }

  @override
  String get anatomyLegend => '이 기간에 세트가 많은 부위일수록 진해요';

  @override
  String get anatomyFirstTime =>
      '아직 해낸 세트가 없어 색이 없어요. 부위를 누르면 그 부위를 쓰는 운동과 자세 팁을 볼 수 있어요.';

  @override
  String anatomyEmptyWindow(int n) {
    return '최근 $n일에 해낸 세트가 없어요';
  }

  @override
  String anatomyUnknown(int n) {
    return '근육을 모르는 운동 $n개는 세지 않았어요. 이름을 누르면 검색에서 그 기록을 봐요.';
  }

  @override
  String anatomyUnknownMore(int n) {
    return '외 $n개';
  }

  @override
  String anatomyCardio(int n) {
    return '유산소 $n세트는 근육 그림에 넣지 않았어요';
  }

  @override
  String get anatomyCountNote =>
      '근육은 ExRx.net·ACE 분류를 따른 어림이에요. * 가 붙은 운동은 근육 배정이 해석이에요. 주로 쓰는 근육은 한 세트, 보조로 쓰는 근육은 반 세트로 세고, 워밍업 세트도 한 세트로 셉니다.';

  @override
  String get anatomyLimits => '영상·자세 분석은 하지 않아요. 통증이 있으면 멈추고 전문가와 상의하세요.';

  @override
  String get anatomyTapHint => '근육을 눌러 주세요 — 아래 목록에서도 고를 수 있어요';

  @override
  String get anatomyNoSurface => '몸 안쪽 근육이라 그림에는 없어요';

  @override
  String anatomySets(int days, String sets) {
    return '$days일 $sets세트';
  }

  @override
  String anatomySetsLine(String week, String month) {
    return '최근 7일 $week세트 · 28일 $month세트';
  }

  @override
  String anatomyBreakdown(int primary, int secondary) {
    return '28일 중 주로 쓴 세트 $primary · 보조로 쓴 세트 $secondary(반으로 셈)';
  }

  @override
  String anatomyLast(String date, String ago) {
    return '마지막: $date($ago)';
  }

  @override
  String get anatomyNever => '표에 있는 운동으로는 이 부위를 쓴 기록이 아직 없어요';

  @override
  String get anatomyDone => '내가 한 운동';

  @override
  String get anatomyTry => '이 부위를 주로 쓰는 운동';

  @override
  String anatomyTryGear(String list) {
    return '쓴 적 있는 기구($list)로 할 수 있는 것';
  }

  @override
  String get anatomyAllGear => '기구 기록이 없어 전부 보여요';

  @override
  String anatomyMoreGear(int n) {
    return '다른 기구 운동 $n개 더 보기';
  }

  @override
  String get anatomyTriedAll => '이 부위를 주로 쓰는 운동은 다 해 봤어요';

  @override
  String anatomyRole(String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'primary': '주로 씀',
      'other': '보조',
    });
    return '$_temp0';
  }

  @override
  String get anatomyInterpNote => '* 가 붙은 운동은 근육 배정이 출처를 옮긴 해석이에요';

  @override
  String get anatomyCues => '자세 팁';

  @override
  String get anatomyMistakes => '피할 것';

  @override
  String anatomySources(String sites) {
    return '출처: $sites';
  }

  @override
  String get anatomyUnsourced => '‡ 출처 없이 덧붙인 말';

  @override
  String get anatomyAdapted => '† 출처 문장을 옮겨 쓴 해석(비슷한 동작의 출처 포함)';

  @override
  String get anatomyCuesEnglish => '자세 팁은 아직 영어로만 있어요';

  @override
  String get anatomyAddRoutine => '오늘 루틴에 넣기';

  @override
  String anatomyRoutineText(String part) {
    return '오늘 $part 루틴';
  }

  @override
  String get anatomySearch => '검색에서 보기';

  @override
  String anatomyRegionValue(int days, String sets, String level) {
    return '최근 $days일 $sets세트, $level';
  }

  @override
  String get anatomyRegionHint => '두 번 눌러 운동 보기';

  @override
  String get anatomyClose => '닫기';

  @override
  String get openSourceLicenses => '오픈소스 라이선스';

  @override
  String routineFactor(String f) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength': '근력',
      'endurance': '근지구력',
      'sustain': '지속력',
      'power': '순발력',
      'cardio': '심폐',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineFactorDay(String factor, String why) {
    return '$factor 날 · $why';
  }

  @override
  String routineFactorWhy(String kind, String a, String b) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tabata': '타바타 $a',
      'fill': '채우기 $a개',
      'fillTitle': '제목 ‘$a’',
      'distance': '$a',
      'open': '$a회씩, 세트 수 열어 둠',
      'single': '한 세트 $a회',
      'drop': '세트마다 최대 $a',
      'hold': '$a회×$b세트',
      'other': '$a×$b',
    });
    return '$_temp0';
  }

  @override
  String routineWhyWeekday(int weeks, String day, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '지난주 $day엔 기록이 없어 $weeks주 전 $day($date)로 짰어요',
      one: '지난주 $day($date) 운동 그대로예요',
    );
    return '$_temp0';
  }

  @override
  String routineWhyNear(String day, String near) {
    return '$day 기록이 없어 가까운 $near로 짰어요';
  }

  @override
  String routineWhyFactor(String f, String date) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength': '이번 주 근력이 부족해서 $date로 짰어요',
      'endurance': '이번 주 근지구력이 부족해서 $date로 짰어요',
      'sustain': '이번 주 지속력이 부족해서 $date로 짰어요',
      'cardio': '이번 주 심폐가 부족해서 $date로 짰어요',
      'other': '$date로 짰어요',
    });
    return '$_temp0';
  }

  @override
  String routineWhyFactorAll(String f, String date) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength': '이번 주 요인은 다 채웠어요 — 다음 차례인 근력으로 $date처럼 짰어요',
      'endurance': '이번 주 요인은 다 채웠어요 — 다음 차례인 근지구력으로 $date처럼 짰어요',
      'sustain': '이번 주 요인은 다 채웠어요 — 다음 차례인 지속력으로 $date처럼 짰어요',
      'cardio': '이번 주 요인은 다 채웠어요 — 다음 차례인 심폐로 $date처럼 짰어요',
      'other': '$date처럼 짰어요',
    });
    return '$_temp0';
  }

  @override
  String routineWeekCounts(String range, String list) {
    return '최근 7일($range): $list';
  }

  @override
  String routineFactorMissing(String list) {
    return '최근 28일에 따로 한 날이 없는 요인: $list';
  }

  @override
  String get routineFillHint => '채우기는 목표 수를 적어 주세요(예: 스쿼트 100개 채우기)';

  @override
  String get routineTabataChip => '타바타로';

  @override
  String routineLikeLastWeek(String day) {
    return '지난주 $day처럼';
  }

  @override
  String routineFactorChip(String f, int n) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength': '근력으로 짜기 · 이번 주 $n번',
      'endurance': '근지구력으로 짜기 · 이번 주 $n번',
      'sustain': '지속력으로 짜기 · 이번 주 $n번',
      'cardio': '심폐로 짜기 · 이번 주 $n번',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineLightKept(String list) {
    return '세트를 뺄 수 없어 그대로 둔 칸(한 세트·채우기·타바타): $list';
  }

  @override
  String routineWhyWeekdaySkip(String how, int weeks, String day, String date) {
    String _temp0 = intl.Intl.selectLogic(how, {
      'alt': '다른 루틴: $weeks주 전 $day($date)로 짰어요',
      'other': '지난주 $day은 거른 운동뿐이라 $weeks주 전 $day($date)로 짰어요',
    });
    return '$_temp0';
  }

  @override
  String routineWhyNearSkip(String how, String day, String near) {
    String _temp0 = intl.Intl.selectLogic(how, {
      'alt': '다른 루틴: 가까운 $near로 짰어요',
      'other': '$day은 거른 운동뿐이라 가까운 $near로 짰어요',
    });
    return '$_temp0';
  }

  @override
  String routineWhyFactorNoDay(String factor, String date) {
    return '모자란 요인은 최근 28일에 쓸 수 있는 날이 없어 $date $factor 날처럼 짰어요';
  }

  @override
  String routineFactorLost(String factor, String date) {
    return '$date $factor 날로 짰지만 $factor 칸은 빠졌어요';
  }

  @override
  String routineFactorFiltered(String list) {
    return '빼라고 한 운동을 빼면 최근 28일에 남는 날이 없는 요인: $list';
  }

  @override
  String routineLightDropped(String date) {
    return '$date에서 한 세트 뺌';
  }

  @override
  String routineDoneToday(String list) {
    return '오늘 이미 한 운동이 들어 있어요: $list';
  }
}
