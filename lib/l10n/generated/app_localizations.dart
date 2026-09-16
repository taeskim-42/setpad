import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ja'),
    Locale('ko'),
    Locale('th'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// 앱 바 제목
  ///
  /// In ko, this message translates to:
  /// **'오늘 운동'**
  String get appTitle;

  /// No description provided for @copy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In ko, this message translates to:
  /// **'복사했습니다'**
  String get copied;

  /// No description provided for @exerciseNameHint.
  ///
  /// In ko, this message translates to:
  /// **'운동 이름'**
  String get exerciseNameHint;

  /// 키패드 맨 위. 뒤에 직전 세트가 붙는다
  ///
  /// In ko, this message translates to:
  /// **'이전과 같이'**
  String get repeatPrevious;

  /// No description provided for @addSet.
  ///
  /// In ko, this message translates to:
  /// **'세트 추가'**
  String get addSet;

  /// No description provided for @numberKeypad.
  ///
  /// In ko, this message translates to:
  /// **'숫자 키패드'**
  String get numberKeypad;

  /// 세트 번호
  ///
  /// In ko, this message translates to:
  /// **'{n}세트'**
  String setOrdinal(int n);

  /// 횟수
  ///
  /// In ko, this message translates to:
  /// **'{n}회'**
  String repsCount(int n);

  /// No description provided for @allNotes.
  ///
  /// In ko, this message translates to:
  /// **'모든 운동'**
  String get allNotes;

  /// No description provided for @noteCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}개의 운동'**
  String noteCount(int n);

  /// No description provided for @previous7Days.
  ///
  /// In ko, this message translates to:
  /// **'이전 7일'**
  String get previous7Days;

  /// No description provided for @previous30Days.
  ///
  /// In ko, this message translates to:
  /// **'이전 30일'**
  String get previous30Days;

  /// 30일보다 오래된 묶음의 제목
  ///
  /// In ko, this message translates to:
  /// **'{m}월'**
  String monthLabel(int m);

  /// No description provided for @search.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get search;

  /// No description provided for @newNote.
  ///
  /// In ko, this message translates to:
  /// **'새 운동'**
  String get newNote;

  /// No description provided for @untitledNote.
  ///
  /// In ko, this message translates to:
  /// **'새 운동'**
  String get untitledNote;

  /// No description provided for @noNotesYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 기록이 없습니다'**
  String get noNotesYet;

  /// No description provided for @noSearchResults.
  ///
  /// In ko, this message translates to:
  /// **'찾는 기록이 없습니다'**
  String get noSearchResults;

  /// 목록의 날짜. 요일 또는 날짜
  ///
  /// In ko, this message translates to:
  /// **'{d}'**
  String dayLabel(DateTime d);

  /// 키패드 큰 키. 칠 것이 없을 때 — 이 운동을 닫고 다음 운동으로
  ///
  /// In ko, this message translates to:
  /// **'운동 완료'**
  String get finishExercise;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @deleteExerciseTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} 삭제'**
  String deleteExerciseTitle(String name);

  /// No description provided for @deleteExerciseBody.
  ///
  /// In ko, this message translates to:
  /// **'{n}개 세트가 함께 지워집니다. 되돌릴 수 없습니다.'**
  String deleteExerciseBody(int n);

  /// No description provided for @deleteExerciseEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'이 운동을 지웁니다.'**
  String get deleteExerciseEmptyBody;

  /// No description provided for @next.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get next;

  /// +/- 롱프레스 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'{unit} 단위'**
  String stepSizeTitle(String unit);

  /// 목록에 붙는 소모 칼로리. 워치가 잰 값만 뜬다
  ///
  /// In ko, this message translates to:
  /// **'{n}kcal'**
  String kcal(int n);

  /// 최근 기록의 요일. 메모 앱이 최근 것을 요일로 낸다
  ///
  /// In ko, this message translates to:
  /// **'{d}'**
  String weekdayLabel(DateTime d);

  /// No description provided for @noteHint.
  ///
  /// In ko, this message translates to:
  /// **'이 세트에 남길 메모'**
  String get noteHint;

  /// No description provided for @activeEnergy.
  ///
  /// In ko, this message translates to:
  /// **'활동 칼로리'**
  String get activeEnergy;

  /// No description provided for @energyUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'기록 없음'**
  String get energyUnavailable;

  /// No description provided for @energySource.
  ///
  /// In ko, this message translates to:
  /// **'건강 앱 · 기록 시간대'**
  String get energySource;

  /// No description provided for @doneEditing.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get doneEditing;

  /// No description provided for @setInputHint.
  ///
  /// In ko, this message translates to:
  /// **'무게  횟수'**
  String get setInputHint;

  /// No description provided for @setRequired.
  ///
  /// In ko, this message translates to:
  /// **'세트를 먼저 입력해 주세요. 예: 60 12'**
  String get setRequired;

  /// No description provided for @aiTitle.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 설정'**
  String get aiTitle;

  /// No description provided for @aiReady.
  ///
  /// In ko, this message translates to:
  /// **'사용 가능'**
  String get aiReady;

  /// No description provided for @aiChecking.
  ///
  /// In ko, this message translates to:
  /// **'확인 중'**
  String get aiChecking;

  /// No description provided for @aiSetupNeeded.
  ///
  /// In ko, this message translates to:
  /// **'설정 필요'**
  String get aiSetupNeeded;

  /// No description provided for @aiPreparing.
  ///
  /// In ko, this message translates to:
  /// **'준비 중'**
  String get aiPreparing;

  /// No description provided for @aiUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'기본 입력'**
  String get aiUnavailable;

  /// No description provided for @aiReadyBody.
  ///
  /// In ko, this message translates to:
  /// **'운동 이름 칸에 “벤치 80kg 100개 채우기”처럼 적고 엔터를 누르세요. 무게와 목표를 자동으로 설정합니다. 문장은 기기 안에서 처리됩니다.'**
  String get aiReadyBody;

  /// No description provided for @aiDisabledBody.
  ///
  /// In ko, this message translates to:
  /// **'설정 앱 → Apple Intelligence 및 Siri에서 Apple Intelligence를 켜 주세요. 모델 준비가 끝난 뒤 앱으로 돌아오면 자동으로 다시 확인합니다.'**
  String get aiDisabledBody;

  /// No description provided for @aiOsBody.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 설정에는 iOS 26 이상과 Apple Intelligence 지원 기기가 필요합니다. 지원 기기라면 설정 → 일반 → 소프트웨어 업데이트를 확인해 주세요.'**
  String get aiOsBody;

  /// No description provided for @aiDeviceBody.
  ///
  /// In ko, this message translates to:
  /// **'이 기기는 Apple Intelligence를 지원하지 않아 한 줄 설정을 사용할 수 없습니다.'**
  String get aiDeviceBody;

  /// No description provided for @aiPreparingBody.
  ///
  /// In ko, this message translates to:
  /// **'기기에서 AI 모델을 준비하고 있습니다. Wi-Fi에 연결한 뒤 잠시 후 다시 확인해 주세요.'**
  String get aiPreparingBody;

  /// No description provided for @aiDownloadBody.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 설정에 필요한 AI 모델을 다운로드할 수 있습니다. Wi-Fi 연결을 권장하며, 다운로드에는 시간과 저장 공간이 필요합니다. 준비가 끝나면 문장은 기기 안에서 처리됩니다.'**
  String get aiDownloadBody;

  /// No description provided for @aiLanguageBody.
  ///
  /// In ko, this message translates to:
  /// **'현재 기기의 AI 모델이 앱 언어를 지원하지 않습니다. 지원되는 언어로 변경한 뒤 다시 확인해 주세요.'**
  String get aiLanguageBody;

  /// No description provided for @aiPlatformBody.
  ///
  /// In ko, this message translates to:
  /// **'이 환경에서는 기기 내 AI를 사용할 수 없습니다. 지원되는 iPhone 또는 Android 기기의 앱에서 사용할 수 있습니다.'**
  String get aiPlatformBody;

  /// No description provided for @aiUnavailableBody.
  ///
  /// In ko, this message translates to:
  /// **'현재 기기에서 AI를 사용할 수 없습니다. 기기·OS·시스템 AI 서비스의 지원 및 준비 상태에 따라 달라집니다. 새 기기를 설정한 직후라면 네트워크에 연결한 뒤 다시 확인해 주세요.'**
  String get aiUnavailableBody;

  /// No description provided for @aiManualBody.
  ///
  /// In ko, this message translates to:
  /// **'기본 운동 기록은 그대로 사용할 수 있습니다. 운동 이름을 선택한 뒤 세트마다 “80 20” 또는 횟수만 입력하세요.'**
  String get aiManualBody;

  /// No description provided for @aiPrepare.
  ///
  /// In ko, this message translates to:
  /// **'모델 준비'**
  String get aiPrepare;

  /// No description provided for @aiRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 확인'**
  String get aiRetry;

  /// No description provided for @aiWorking.
  ///
  /// In ko, this message translates to:
  /// **'운동 설정 중…'**
  String get aiWorking;

  /// No description provided for @aiFailure.
  ///
  /// In ko, this message translates to:
  /// **'문장을 해석하지 못했습니다. 내용을 고쳐 다시 입력하거나 운동 이름으로 사용할 수 있습니다.'**
  String get aiFailure;

  /// No description provided for @aiUseName.
  ///
  /// In ko, this message translates to:
  /// **'운동 이름으로 사용'**
  String get aiUseName;

  /// No description provided for @goalProgress.
  ///
  /// In ko, this message translates to:
  /// **'{done}/{goal}회'**
  String goalProgress(int done, int goal);

  /// No description provided for @repsPerSetLabel.
  ///
  /// In ko, this message translates to:
  /// **'세트당 {n}회'**
  String repsPerSetLabel(int n);

  /// No description provided for @setProgress.
  ///
  /// In ko, this message translates to:
  /// **'{done}/{goal}세트'**
  String setProgress(int done, int goal);

  /// No description provided for @repsInputHint.
  ///
  /// In ko, this message translates to:
  /// **'횟수'**
  String get repsInputHint;

  /// No description provided for @setupTitle.
  ///
  /// In ko, this message translates to:
  /// **'운동 설정'**
  String get setupTitle;

  /// No description provided for @setupWeight.
  ///
  /// In ko, this message translates to:
  /// **'기본 무게'**
  String get setupWeight;

  /// No description provided for @setupTotalReps.
  ///
  /// In ko, this message translates to:
  /// **'총 목표 횟수'**
  String get setupTotalReps;

  /// No description provided for @setupSetReps.
  ///
  /// In ko, this message translates to:
  /// **'세트당 횟수'**
  String get setupSetReps;

  /// No description provided for @setupTotalSets.
  ///
  /// In ko, this message translates to:
  /// **'목표 세트 수'**
  String get setupTotalSets;

  /// No description provided for @moveExercise.
  ///
  /// In ko, this message translates to:
  /// **'운동 이동'**
  String get moveExercise;

  /// No description provided for @weightUnitSetting.
  ///
  /// In ko, this message translates to:
  /// **'기본 무게 단위'**
  String get weightUnitSetting;

  /// No description provided for @weightUnitHelp.
  ///
  /// In ko, this message translates to:
  /// **'새로 입력하는 운동의 기본 단위입니다. 기존 기록의 무게와 단위는 바뀌지 않습니다.'**
  String get weightUnitHelp;

  /// No description provided for @answerDays.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 기록'**
  String answerDays(int n);

  /// No description provided for @answerWeeks.
  ///
  /// In ko, this message translates to:
  /// **'{n}주'**
  String answerWeeks(int n);

  /// No description provided for @answerFrequency.
  ///
  /// In ko, this message translates to:
  /// **'주 {n}회'**
  String answerFrequency(String n);

  /// No description provided for @answerPeak.
  ///
  /// In ko, this message translates to:
  /// **'최고 {value}'**
  String answerPeak(String value);

  /// No description provided for @answerNoPeak.
  ///
  /// In ko, this message translates to:
  /// **'{n}주간 최고 기록 유지'**
  String answerNoPeak(int n);

  /// No description provided for @answerSince.
  ///
  /// In ko, this message translates to:
  /// **'{date}부터'**
  String answerSince(String date);

  /// No description provided for @answerAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 전'**
  String answerAgo(int n);

  /// No description provided for @answerPerSet.
  ///
  /// In ko, this message translates to:
  /// **'세트당 {value}'**
  String answerPerSet(String value);

  /// No description provided for @answerChange.
  ///
  /// In ko, this message translates to:
  /// **'{weeks} · {value}'**
  String answerChange(String weeks, String value);

  /// No description provided for @answerChart.
  ///
  /// In ko, this message translates to:
  /// **'{name} · {n}일 기록'**
  String answerChart(String name, int n);

  /// No description provided for @answerWeightReps.
  ///
  /// In ko, this message translates to:
  /// **'{value} × {reps}'**
  String answerWeightReps(String value, String reps);

  /// No description provided for @answerSets.
  ///
  /// In ko, this message translates to:
  /// **'{n}세트'**
  String answerSets(int n);

  /// No description provided for @timingBpm.
  ///
  /// In ko, this message translates to:
  /// **'{n} BPM'**
  String timingBpm(int n);

  /// No description provided for @timingProtocol.
  ///
  /// In ko, this message translates to:
  /// **'타바타 {work}초 / {rest}초 · {rounds}라운드'**
  String timingProtocol(int work, int rest, int rounds);

  /// No description provided for @timingRound.
  ///
  /// In ko, this message translates to:
  /// **'{n}/{total}라운드'**
  String timingRound(int n, int total);

  /// 라운드가 끝날 때 소리로 읽어 주는 말.
  ///
  /// In ko, this message translates to:
  /// **'{n}라운드 종료'**
  String timingRoundDone(int n);

  /// No description provided for @timingMetronome.
  ///
  /// In ko, this message translates to:
  /// **'메트로놈'**
  String get timingMetronome;

  /// No description provided for @timingReady.
  ///
  /// In ko, this message translates to:
  /// **'준비'**
  String get timingReady;

  /// No description provided for @timingWork.
  ///
  /// In ko, this message translates to:
  /// **'운동'**
  String get timingWork;

  /// No description provided for @timingRest.
  ///
  /// In ko, this message translates to:
  /// **'휴식'**
  String get timingRest;

  /// No description provided for @timingComplete.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get timingComplete;

  /// No description provided for @timingStart.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get timingStart;

  /// No description provided for @timingPause.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get timingPause;

  /// No description provided for @timingReset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get timingReset;

  /// No description provided for @timingInvalid.
  ///
  /// In ko, this message translates to:
  /// **'BPM 10–120, 운동·휴식 1–600초, 라운드 1–99로 입력하세요.'**
  String get timingInvalid;

  /// No description provided for @timingSoundFailed.
  ///
  /// In ko, this message translates to:
  /// **'소리를 재생할 수 없습니다. 타이머는 계속 동작합니다.'**
  String get timingSoundFailed;

  /// No description provided for @queryTitle.
  ///
  /// In ko, this message translates to:
  /// **'기록에 질문'**
  String get queryTitle;

  /// No description provided for @queryReadyBody.
  ///
  /// In ko, this message translates to:
  /// **'“스쿼트 최대 무게”, “지난달 푸시업 몇 개 했어?”, “이번 달 벤치는 지난달보다 늘었어?”처럼 물어보세요. 기기 내 AI가 질문을 해석하고 저장된 기록으로 계산합니다.'**
  String get queryReadyBody;

  /// No description provided for @queryManualBody.
  ///
  /// In ko, this message translates to:
  /// **'자연어 질문은 기기 내 AI가 준비되면 사용할 수 있습니다. 일반 운동명·메모 검색은 항상 가능합니다.'**
  String get queryManualBody;

  /// No description provided for @queryWorking.
  ///
  /// In ko, this message translates to:
  /// **'질문을 해석하고 있습니다…'**
  String get queryWorking;

  /// No description provided for @queryFailed.
  ///
  /// In ko, this message translates to:
  /// **'답변을 가져오지 못했습니다. 다시 시도해 주세요.'**
  String get queryFailed;

  /// No description provided for @queryUnsupported.
  ///
  /// In ko, this message translates to:
  /// **'운동 기록과 관련된 질문을 해주세요.'**
  String get queryUnsupported;

  /// 서버에 못 닿아 질문을 못 할 때.
  ///
  /// In ko, this message translates to:
  /// **'연결되면 물어볼 수 있어요.'**
  String get queryOffline;

  /// No description provided for @queryNoData.
  ///
  /// In ko, this message translates to:
  /// **'계산에 필요한 완료 기록이나 값이 부족해요. 원본 기록을 확인해 주세요.'**
  String get queryNoData;

  /// No description provided for @queryPeriod.
  ///
  /// In ko, this message translates to:
  /// **'{start} – {end}'**
  String queryPeriod(String start, String end);

  /// No description provided for @queryAllTime.
  ///
  /// In ko, this message translates to:
  /// **'전체 기간'**
  String get queryAllTime;

  /// No description provided for @queryPresent.
  ///
  /// In ko, this message translates to:
  /// **'현재'**
  String get queryPresent;

  /// No description provided for @queryRepUnit.
  ///
  /// In ko, this message translates to:
  /// **'회'**
  String get queryRepUnit;

  /// No description provided for @querySetUnit.
  ///
  /// In ko, this message translates to:
  /// **'세트'**
  String get querySetUnit;

  /// No description provided for @queryDayUnit.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get queryDayUnit;

  /// No description provided for @queryAverage.
  ///
  /// In ko, this message translates to:
  /// **'세트당 평균 중량'**
  String get queryAverage;

  /// No description provided for @queryMissingData.
  ///
  /// In ko, this message translates to:
  /// **'질문에 필요한 운동이나 측정 정보가 기록에 없습니다.'**
  String get queryMissingData;

  /// No description provided for @queryAmbiguous.
  ///
  /// In ko, this message translates to:
  /// **'어떤 운동의 어떤 기록을 말하는지 조금 더 구체적으로 적어 주세요.'**
  String get queryAmbiguous;

  /// No description provided for @queryRank.
  ///
  /// In ko, this message translates to:
  /// **'{n}위'**
  String queryRank(int n);

  /// No description provided for @timingWorkSeconds.
  ///
  /// In ko, this message translates to:
  /// **'운동 {n}초'**
  String timingWorkSeconds(int n);

  /// No description provided for @timingRestSeconds.
  ///
  /// In ko, this message translates to:
  /// **'휴식 {n}초'**
  String timingRestSeconds(int n);

  /// No description provided for @timingRounds.
  ///
  /// In ko, this message translates to:
  /// **'{n}라운드'**
  String timingRounds(int n);

  /// 세는 말. 한국어는 하나·둘·셋, 나머지는 숫자다.
  ///
  /// In ko, this message translates to:
  /// **'{count}'**
  String timingBeat(String count);

  /// Heart rate during rest: current beats per minute and the value that ends the rest early.
  ///
  /// In ko, this message translates to:
  /// **'♥ {bpm} → {target}'**
  String timingHeart(int bpm, int target);

  /// No description provided for @accountSignIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인하고 백업'**
  String get accountSignIn;

  /// No description provided for @accountSignOut.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get accountSignOut;

  /// No description provided for @planMonthly.
  ///
  /// In ko, this message translates to:
  /// **'월 이용권'**
  String get planMonthly;

  /// No description provided for @planLifetime.
  ///
  /// In ko, this message translates to:
  /// **'평생 이용권'**
  String get planLifetime;

  /// No description provided for @planActive.
  ///
  /// In ko, this message translates to:
  /// **'이용 중'**
  String get planActive;

  /// No description provided for @restorePurchases.
  ///
  /// In ko, this message translates to:
  /// **'구매 복원'**
  String get restorePurchases;

  /// No description provided for @quotaSpent.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 질문을 다 썼어요.'**
  String get quotaSpent;

  /// 다니는 체육관과 담당 트레이너.
  ///
  /// In ko, this message translates to:
  /// **'{gym} · {trainer} 트레이너'**
  String gymMember(String gym, String trainer);

  /// 담당 트레이너가 없는 체육관.
  ///
  /// In ko, this message translates to:
  /// **'{gym}'**
  String gymOnly(String gym);

  /// 트레이너가 내려준 루틴 줄.
  ///
  /// In ko, this message translates to:
  /// **'{gym}에서 보낸 운동'**
  String routineFromTrainer(String gym);

  /// No description provided for @partnerInvite.
  ///
  /// In ko, this message translates to:
  /// **'같이 하기'**
  String get partnerInvite;

  /// No description provided for @partnerCode.
  ///
  /// In ko, this message translates to:
  /// **'상대에게 이 번호를 불러 주세요'**
  String get partnerCode;

  /// No description provided for @partnerEnter.
  ///
  /// In ko, this message translates to:
  /// **'번호 입력'**
  String get partnerEnter;

  /// No description provided for @partnerJoined.
  ///
  /// In ko, this message translates to:
  /// **'{name}와 같이 기록합니다'**
  String partnerJoined(String name);

  /// No description provided for @partnerFailed.
  ///
  /// In ko, this message translates to:
  /// **'번호가 맞지 않거나 시간이 지났어요.'**
  String get partnerFailed;

  /// No description provided for @bookingNext.
  ///
  /// In ko, this message translates to:
  /// **'{trainer} 트레이너 · {when}'**
  String bookingNext(String trainer, String when);

  /// No description provided for @bookingNew.
  ///
  /// In ko, this message translates to:
  /// **'PT 예약'**
  String get bookingNew;

  /// No description provided for @bookingNone.
  ///
  /// In ko, this message translates to:
  /// **'그날은 빈 시간이 없어요.'**
  String get bookingNone;

  /// No description provided for @bookingCancel.
  ///
  /// In ko, this message translates to:
  /// **'예약 취소'**
  String get bookingCancel;

  /// No description provided for @countAloud.
  ///
  /// In ko, this message translates to:
  /// **'박자를 소리내어 세기'**
  String get countAloud;

  /// 검색창 아래 칩. 운동 이름이 잡히면 무엇을 볼지 고르는 다섯 개.
  ///
  /// In ko, this message translates to:
  /// **'최고'**
  String get metricMax;

  /// No description provided for @metricTrend.
  ///
  /// In ko, this message translates to:
  /// **'추이'**
  String get metricTrend;

  /// No description provided for @metricLast.
  ///
  /// In ko, this message translates to:
  /// **'마지막'**
  String get metricLast;

  /// No description provided for @metricSessions.
  ///
  /// In ko, this message translates to:
  /// **'운동한 날'**
  String get metricSessions;

  /// No description provided for @metricVolume.
  ///
  /// In ko, this message translates to:
  /// **'볼륨'**
  String get metricVolume;

  /// No description provided for @metricReps.
  ///
  /// In ko, this message translates to:
  /// **'총 횟수'**
  String get metricReps;

  /// No description provided for @metricSets.
  ///
  /// In ko, this message translates to:
  /// **'세트 수'**
  String get metricSets;

  /// No description provided for @metricAverage.
  ///
  /// In ko, this message translates to:
  /// **'평균'**
  String get metricAverage;

  /// 해석이 의심스러울 때 답 대신 띄우는 줄. 뒤에 운동·의도·기간이 붙는다.
  ///
  /// In ko, this message translates to:
  /// **'이렇게 읽었어요'**
  String get readAsConfirm;

  /// No description provided for @confirmYes.
  ///
  /// In ko, this message translates to:
  /// **'맞아요'**
  String get confirmYes;

  /// 오타를 퍼지로 읽었을 때. from 은 사람이 친 것, to 는 읽은 운동 이름.
  ///
  /// In ko, this message translates to:
  /// **'{from} → {to}'**
  String readAsNote(String from, String to);

  /// No description provided for @reviewNumbers.
  ///
  /// In ko, this message translates to:
  /// **'숫자와 조건을 확인한 뒤 적용해 주세요.'**
  String get reviewNumbers;

  /// No description provided for @querySourceOnly.
  ///
  /// In ko, this message translates to:
  /// **'원본 기록 보기'**
  String get querySourceOnly;

  /// No description provided for @queryCompareOrder.
  ///
  /// In ko, this message translates to:
  /// **'두 번째 기간 − 첫 번째 기간'**
  String get queryCompareOrder;

  /// No description provided for @queryRankingLimit.
  ///
  /// In ko, this message translates to:
  /// **'상위 {n}개 · 내림차순'**
  String queryRankingLimit(int n);

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsRecording.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get settingsRecording;

  /// No description provided for @settingsAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get settingsAccount;

  /// No description provided for @settingsGym.
  ///
  /// In ko, this message translates to:
  /// **'다니는 체육관'**
  String get settingsGym;

  /// No description provided for @settingsNoGym.
  ///
  /// In ko, this message translates to:
  /// **'헬스장 스티커에 폰을 대면 트레이너가 짠 루틴을 여기서 받습니다.'**
  String get settingsNoGym;

  /// No description provided for @proTitle.
  ///
  /// In ko, this message translates to:
  /// **'기록에 마음껏 물어보기'**
  String get proTitle;

  /// No description provided for @proBody.
  ///
  /// In ko, this message translates to:
  /// **'“스쿼트 최대 무게”, “이번 달 벤치는 지난달보다 늘었어?” 처럼 물으면 저장된 기록으로 계산해 답합니다.'**
  String get proBody;

  /// No description provided for @proFree.
  ///
  /// In ko, this message translates to:
  /// **'무료 한 달 {n}번'**
  String proFree(int n);

  /// No description provided for @proPaid.
  ///
  /// In ko, this message translates to:
  /// **'이용권 하루 {n}번'**
  String proPaid(int n);

  /// No description provided for @proEverythingElseFree.
  ///
  /// In ko, this message translates to:
  /// **'기록·타이머·건강 앱 연동·체육관 연결은 이용권 없이도 전부 됩니다.'**
  String get proEverythingElseFree;

  /// No description provided for @proOwned.
  ///
  /// In ko, this message translates to:
  /// **'이용 중입니다. 고맙습니다.'**
  String get proOwned;

  /// No description provided for @proSignInFirst.
  ///
  /// In ko, this message translates to:
  /// **'이용권은 계정에 붙습니다. 먼저 로그인해 주세요.'**
  String get proSignInFirst;

  /// No description provided for @tagSignInNeeded.
  ///
  /// In ko, this message translates to:
  /// **'헬스장과 연결하려면 로그인이 필요합니다. 로그인하고 스티커에 다시 대주세요.'**
  String get tagSignInNeeded;

  /// No description provided for @tagJoinSent.
  ///
  /// In ko, this message translates to:
  /// **'등록을 신청했습니다. 트레이너가 확인하면 바로 시작할 수 있습니다.'**
  String get tagJoinSent;

  /// No description provided for @tagJoinWaiting.
  ///
  /// In ko, this message translates to:
  /// **'이미 신청하셨습니다. 트레이너가 확인하는 중입니다.'**
  String get tagJoinWaiting;

  /// No description provided for @tagJoinFailed.
  ///
  /// In ko, this message translates to:
  /// **'신청하지 못했습니다. 잠시 뒤 다시 대주세요.'**
  String get tagJoinFailed;

  /// No description provided for @bookingPending.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기'**
  String get bookingPending;

  /// No description provided for @bookingWhichGym.
  ///
  /// In ko, this message translates to:
  /// **'어느 헬스장인가요?'**
  String get bookingWhichGym;

  /// No description provided for @ok.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get ok;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'ja',
    'ko',
    'th',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return LZhHans();
          case 'Hant':
            return LZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'es':
      return LEs();
    case 'ja':
      return LJa();
    case 'ko':
      return LKo();
    case 'th':
      return LTh();
    case 'vi':
      return LVi();
    case 'zh':
      return LZh();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
