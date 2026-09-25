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

  /// 이전 7일보다 앞, 올해의 달 묶음 제목
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

  /// No description provided for @setsPerLineMax.
  ///
  /// In ko, this message translates to:
  /// **'한 번에 {n}세트까지예요. 줄을 나눠 적어 주세요.'**
  String setsPerLineMax(int n);

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

  /// No description provided for @aiFallbackQuota.
  ///
  /// In ko, this message translates to:
  /// **'오늘 적기 도움을 다 써서 적은 그대로 만들었어요'**
  String get aiFallbackQuota;

  /// No description provided for @aiFallbackOffline.
  ///
  /// In ko, this message translates to:
  /// **'연결이 안 돼 적은 그대로 만들었어요. 설정은 칸의 ⚙에서 붙일 수 있어요'**
  String get aiFallbackOffline;

  /// No description provided for @aiFallbackServer.
  ///
  /// In ko, this message translates to:
  /// **'서버가 답하지 않아 적은 그대로 만들었어요. 설정은 칸의 ⚙에서 붙일 수 있어요'**
  String get aiFallbackServer;

  /// No description provided for @aiFallbackUnread.
  ///
  /// In ko, this message translates to:
  /// **'설정으로 읽을 말을 찾지 못해 적은 그대로 만들었어요. 설정은 칸의 ⚙에서 붙일 수 있어요'**
  String get aiFallbackUnread;

  /// No description provided for @inputNameTooLong.
  ///
  /// In ko, this message translates to:
  /// **'운동 이름은 120자까지예요 — 줄을 나눠 적어 주세요'**
  String get inputNameTooLong;

  /// No description provided for @inputTooLong.
  ///
  /// In ko, this message translates to:
  /// **'600자가 넘는 글은 읽지 않아요 — 줄을 나눠 적어 주세요'**
  String get inputTooLong;

  /// No description provided for @setupAdd.
  ///
  /// In ko, this message translates to:
  /// **'설정 붙이기'**
  String get setupAdd;

  /// No description provided for @setupUnparsed.
  ///
  /// In ko, this message translates to:
  /// **'설정에 못 옮긴 말: {words} — 제목에 그대로 남아요'**
  String setupUnparsed(String words);

  /// No description provided for @setupDropped.
  ///
  /// In ko, this message translates to:
  /// **'글에 없는 수라 뺐어요: {numbers}'**
  String setupDropped(String numbers);

  /// No description provided for @setupNameMissing.
  ///
  /// In ko, this message translates to:
  /// **'운동 이름을 적어 주세요'**
  String get setupNameMissing;

  /// No description provided for @setupNameTooLong.
  ///
  /// In ko, this message translates to:
  /// **'운동 이름은 120자까지예요'**
  String get setupNameTooLong;

  /// No description provided for @setupWeightInvalid.
  ///
  /// In ko, this message translates to:
  /// **'0보다 크고 2000 이하인 수로 적어 주세요'**
  String get setupWeightInvalid;

  /// No description provided for @setupCountInvalid.
  ///
  /// In ko, this message translates to:
  /// **'1 이상의 정수로 적어 주세요 — 범위·시간은 제목에 남겨 두세요'**
  String get setupCountInvalid;

  /// No description provided for @setupRepsOnly.
  ///
  /// In ko, this message translates to:
  /// **'횟수만 기록'**
  String get setupRepsOnly;

  /// No description provided for @setupSplit.
  ///
  /// In ko, this message translates to:
  /// **'운동 {count}개로 나눴어요'**
  String setupSplit(int count);

  /// No description provided for @setupMergeAll.
  ///
  /// In ko, this message translates to:
  /// **'한 칸으로 합치기'**
  String get setupMergeAll;

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
  /// **'로그인'**
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

  /// No description provided for @planYearly.
  ///
  /// In ko, this message translates to:
  /// **'연 이용권'**
  String get planYearly;

  /// 연간 이용권 단추 밑의 체험 안내. days 와 price 는 스토어가 준 값.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 무료 체험 뒤 연 {price}. 체험이 끝나기 24시간 전까지 해지하면 청구되지 않습니다.'**
  String planYearlyTrial(int days, String price);

  /// 연간 체험 안내 밑. 체험 동안 원판은 n장까지만(서버 lib/plate-pricing.ts PRO_TRIAL_CENTS).
  ///
  /// In ko, this message translates to:
  /// **'무료 체험 동안은 원판 {n}장까지 채웁니다. 결제가 시작되면 매달 채움으로 바뀝니다.'**
  String planYearlyTrialPlates(int n);

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

  /// 결제 화면의 자동 갱신 안내 (App Store 3.1.2).
  ///
  /// In ko, this message translates to:
  /// **'구독은 현재 기간이 끝나기 24시간 전까지 해지하지 않으면 같은 값으로 자동 갱신됩니다. 해지는 스토어의 구독 관리에서 언제든 할 수 있습니다.'**
  String get subscriptionRenews;

  /// No description provided for @termsOfUse.
  ///
  /// In ko, this message translates to:
  /// **'이용약관(EULA)'**
  String get termsOfUse;

  /// No description provided for @inputQuotaSpent.
  ///
  /// In ko, this message translates to:
  /// **'오늘 적기 도움을 다 썼어요. 직접 적으면 그대로 기록돼요.'**
  String get inputQuotaSpent;

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
  /// **'상대에게 이 코드를 알려 주세요'**
  String get partnerCode;

  /// No description provided for @partnerEnter.
  ///
  /// In ko, this message translates to:
  /// **'코드 입력'**
  String get partnerEnter;

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

  /// 기록 질문 표의 측정 이름. 추정 1RM 은 Epley 식으로 1–10회 세트만 쓴다. 쉰 날은 오늘 − 마지막으로 한 날.
  ///
  /// In ko, this message translates to:
  /// **'추정 1RM'**
  String get metricE1rm;

  /// No description provided for @metricMaxReps.
  ///
  /// In ko, this message translates to:
  /// **'최다 반복'**
  String get metricMaxReps;

  /// No description provided for @metricLongest.
  ///
  /// In ko, this message translates to:
  /// **'최장'**
  String get metricLongest;

  /// No description provided for @metricFirst.
  ///
  /// In ko, this message translates to:
  /// **'처음'**
  String get metricFirst;

  /// No description provided for @metricDaysSince.
  ///
  /// In ko, this message translates to:
  /// **'쉰 날'**
  String get metricDaysSince;

  /// No description provided for @metricDistance.
  ///
  /// In ko, this message translates to:
  /// **'총 거리'**
  String get metricDistance;

  /// No description provided for @metricDuration.
  ///
  /// In ko, this message translates to:
  /// **'총 시간'**
  String get metricDuration;

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

  /// No description provided for @queryByExercise.
  ///
  /// In ko, this message translates to:
  /// **'운동별'**
  String get queryByExercise;

  /// No description provided for @queryByDay.
  ///
  /// In ko, this message translates to:
  /// **'날짜별'**
  String get queryByDay;

  /// No description provided for @queryByWeek.
  ///
  /// In ko, this message translates to:
  /// **'주별 (월요일 시작)'**
  String get queryByWeek;

  /// No description provided for @queryByMonth.
  ///
  /// In ko, this message translates to:
  /// **'월별'**
  String get queryByMonth;

  /// No description provided for @queryByWeekday.
  ///
  /// In ko, this message translates to:
  /// **'요일별'**
  String get queryByWeekday;

  /// No description provided for @queryTotalSum.
  ///
  /// In ko, this message translates to:
  /// **'합계'**
  String get queryTotalSum;

  /// No description provided for @queryTotalMean.
  ///
  /// In ko, this message translates to:
  /// **'평균'**
  String get queryTotalMean;

  /// 두 대상의 차이. 값은 뒤 − 앞이다.
  ///
  /// In ko, this message translates to:
  /// **'차이 ({later} − {earlier})'**
  String queryDiff(String later, String earlier);

  /// No description provided for @queryExclude.
  ///
  /// In ko, this message translates to:
  /// **'{names} 제외'**
  String queryExclude(String names);

  /// No description provided for @queryMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모: {terms}'**
  String queryMemo(String terms);

  /// No description provided for @queryLastSessions.
  ///
  /// In ko, this message translates to:
  /// **'마지막 {n}번'**
  String queryLastSessions(int n);

  /// No description provided for @queryBottomLimit.
  ///
  /// In ko, this message translates to:
  /// **'하위 {n}개 · 오름차순'**
  String queryBottomLimit(int n);

  /// 무게를 한 번도 적지 않은 운동처럼 이 측정의 대상이 아닌 운동. 빼고 센다.
  ///
  /// In ko, this message translates to:
  /// **'이 측정에 쓸 값이 없어 뺐어요: {names}'**
  String queryOutOfScope(String names);

  /// 값이 빠진 세트가 있어 칸을 비운 운동.
  ///
  /// In ko, this message translates to:
  /// **'값이 빠진 세트가 있어 계산하지 않았어요: {names}'**
  String queryMissingFor(String names);

  /// No description provided for @queryE1rmRule.
  ///
  /// In ko, this message translates to:
  /// **'추정 1RM = 무게 × (1 + 횟수 ÷ 30), 1–10회 세트만'**
  String get queryE1rmRule;

  /// No description provided for @queryMore.
  ///
  /// In ko, this message translates to:
  /// **'외 {n}개'**
  String queryMore(int n);

  /// No description provided for @queryRankingLimit.
  ///
  /// In ko, this message translates to:
  /// **'상위 {n}개 · 내림차순'**
  String queryRankingLimit(int n);

  /// 운동 이름이 둘 이상 잡혔을 때 뜨는 칩. 누르면 모델 없이 최고·운동한 날·마지막을 나란히 본다.
  ///
  /// In ko, this message translates to:
  /// **'비교'**
  String get queryCompareChip;

  /// 표에서 지목한 운동에 이 범위의 기록이 하나도 없을 때.
  ///
  /// In ko, this message translates to:
  /// **'기록 없음'**
  String get queryNoRecord;

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
  /// **'Pro 이용권'**
  String get proTitle;

  /// No description provided for @proBody.
  ///
  /// In ko, this message translates to:
  /// **'기록에 묻는 질문은 원판을 씁니다. 질문 하나에 보통 1장쯤 들고, 답에 실제로 쓴 만큼만 빠집니다. 운동과 식단을 적을 때 돕는 적기 도움은 원판을 쓰지 않습니다.'**
  String get proBody;

  /// No description provided for @proFree.
  ///
  /// In ko, this message translates to:
  /// **'무료: 적기 도움 하루 {n}번 · 세트 {sets}개를 채운 날 원판 1장'**
  String proFree(int n, int sets);

  /// No description provided for @proPaid.
  ///
  /// In ko, this message translates to:
  /// **'Pro: 매달 원판 {n}장까지 채움 · 적기 도움 하루 {input}번'**
  String proPaid(int n, int input);

  /// No description provided for @proEverythingElseFree.
  ///
  /// In ko, this message translates to:
  /// **'기록·타이머·손목 알림·건강 앱 연동·같이 하기·체육관은 이용권 없이도 전부 됩니다.'**
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

  /// 원판 잔액. 1.5 처럼 소수가 있다.
  ///
  /// In ko, this message translates to:
  /// **'남은 원판 {n}장'**
  String platesBalance(num n);

  /// No description provided for @platesSpent.
  ///
  /// In ko, this message translates to:
  /// **'원판 {spent}장 사용 · 남은 원판 {balance}장'**
  String platesSpent(num spent, num balance);

  /// No description provided for @noPlates.
  ///
  /// In ko, this message translates to:
  /// **'원판이 모자라요. 세트 {sets}개를 채운 날마다 1장씩 받아요.'**
  String noPlates(int sets);

  /// No description provided for @noPlatesSignIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인하기 · 새 계정은 원판 {n}장'**
  String noPlatesSignIn(int n);

  /// No description provided for @platesGetPro.
  ///
  /// In ko, this message translates to:
  /// **'Pro 보기 · 매달 {n}장'**
  String platesGetPro(int n);

  /// No description provided for @purchaseNotConfirmed.
  ///
  /// In ko, this message translates to:
  /// **'구매를 확인하지 못했습니다. 결제가 됐다면 잠시 뒤 ‘구매 복원’을 눌러 주세요.'**
  String get purchaseNotConfirmed;

  /// No description provided for @purchaseOtherAccount.
  ///
  /// In ko, this message translates to:
  /// **'이 구매는 다른 계정에 연결돼 있습니다. 그 계정으로 로그인해 주세요.'**
  String get purchaseOtherAccount;

  /// No description provided for @tagSignInNeeded.
  ///
  /// In ko, this message translates to:
  /// **'헬스장과 연결하려면 로그인이 필요합니다.'**
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

  /// No description provided for @tagSignIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get tagSignIn;

  /// No description provided for @accountDelete.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴'**
  String get accountDelete;

  /// No description provided for @accountDeleteAsk.
  ///
  /// In ko, this message translates to:
  /// **'되돌릴 수 없습니다. 받은 루틴, 운동 기록, 이용권, 예약이 모두 사라집니다.'**
  String get accountDeleteAsk;

  /// No description provided for @accountDeleteDo.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴합니다'**
  String get accountDeleteDo;

  /// No description provided for @accountDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴하지 못했습니다. 잠시 뒤 다시 시도해 주세요.'**
  String get accountDeleteFailed;

  /// No description provided for @signInFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인하지 못했습니다. 잠시 뒤 다시 시도해 주세요.'**
  String get signInFailed;

  /// No description provided for @bookingTitle.
  ///
  /// In ko, this message translates to:
  /// **'PT 예약'**
  String get bookingTitle;

  /// No description provided for @bookingConfirmed.
  ///
  /// In ko, this message translates to:
  /// **'확정'**
  String get bookingConfirmed;

  /// No description provided for @bookingRemaining.
  ///
  /// In ko, this message translates to:
  /// **'남은 횟수 {n}회'**
  String bookingRemaining(int n);

  /// No description provided for @bookingNoPass.
  ///
  /// In ko, this message translates to:
  /// **'PT 이용권이 없습니다. 트레이너에게 문의해 주세요.'**
  String get bookingNoPass;

  /// No description provided for @bookingNoHours.
  ///
  /// In ko, this message translates to:
  /// **'{trainer} 트레이너가 아직 받을 시간을 열지 않았습니다.'**
  String bookingNoHours(String trainer);

  /// No description provided for @bookingPick.
  ///
  /// In ko, this message translates to:
  /// **'시간 고르기'**
  String get bookingPick;

  /// No description provided for @bookingWith.
  ///
  /// In ko, this message translates to:
  /// **'{trainer} 트레이너 · 1회 {minutes}분'**
  String bookingWith(String trainer, int minutes);

  /// No description provided for @bookingSent.
  ///
  /// In ko, this message translates to:
  /// **'신청했습니다. 트레이너가 승인하면 확정됩니다.'**
  String get bookingSent;

  /// No description provided for @bookingUpcoming.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 예약'**
  String get bookingUpcoming;

  /// No description provided for @bookingClosedDay.
  ///
  /// In ko, this message translates to:
  /// **'이날은 받지 않습니다.'**
  String get bookingClosedDay;

  /// No description provided for @bookingCancelAsk.
  ///
  /// In ko, this message translates to:
  /// **'이 예약을 취소할까요?'**
  String get bookingCancelAsk;

  /// No description provided for @ok.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get ok;

  /// No description provided for @mealPhoto.
  ///
  /// In ko, this message translates to:
  /// **'식단 사진'**
  String get mealPhoto;

  /// No description provided for @mealAdd.
  ///
  /// In ko, this message translates to:
  /// **'식단 남기기'**
  String get mealAdd;

  /// No description provided for @mealWrite.
  ///
  /// In ko, this message translates to:
  /// **'글로 적기'**
  String get mealWrite;

  /// No description provided for @mealTypeHint.
  ///
  /// In ko, this message translates to:
  /// **'음식은 운동 이름 줄에 바로 쳐도 식단으로 남아요'**
  String get mealTypeHint;

  /// No description provided for @mealCamera.
  ///
  /// In ko, this message translates to:
  /// **'카메라'**
  String get mealCamera;

  /// No description provided for @mealGallery.
  ///
  /// In ko, this message translates to:
  /// **'앨범에서'**
  String get mealGallery;

  /// No description provided for @mealEstimating.
  ///
  /// In ko, this message translates to:
  /// **'칼로리 어림하는 중…'**
  String get mealEstimating;

  /// No description provided for @mealIntake.
  ///
  /// In ko, this message translates to:
  /// **'섭취 약 {n}kcal'**
  String mealIntake(int n);

  /// No description provided for @mealFailed.
  ///
  /// In ko, this message translates to:
  /// **'사진에서 칼로리를 어림하지 못했어요. 다시 찍어 주세요.'**
  String get mealFailed;

  /// No description provided for @mealEstimateNote.
  ///
  /// In ko, this message translates to:
  /// **'사진으로 어림한 값이에요'**
  String get mealEstimateNote;

  /// No description provided for @mealServingsOption.
  ///
  /// In ko, this message translates to:
  /// **'{n}회분'**
  String mealServingsOption(String n);

  /// No description provided for @fitAll.
  ///
  /// In ko, this message translates to:
  /// **'오늘 운동'**
  String get fitAll;

  /// No description provided for @sameDayToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 {time}에 남긴 다른 기록'**
  String sameDayToday(String time);

  /// No description provided for @sameDayOn.
  ///
  /// In ko, this message translates to:
  /// **'{date} {time}에 남긴 다른 기록'**
  String sameDayOn(String date, String time);

  /// No description provided for @mealText.
  ///
  /// In ko, this message translates to:
  /// **'식단 적기'**
  String get mealText;

  /// No description provided for @mealTextHint.
  ///
  /// In ko, this message translates to:
  /// **'먹은 것을 적어 주세요. 예: 김밥 한 줄, 우유 200ml'**
  String get mealTextHint;

  /// No description provided for @kcalApprox.
  ///
  /// In ko, this message translates to:
  /// **'{n}kcal 추정'**
  String kcalApprox(int n);

  /// No description provided for @mealKcalUnknown.
  ///
  /// In ko, this message translates to:
  /// **'열량 미상'**
  String get mealKcalUnknown;

  /// No description provided for @mealIntakePartial.
  ///
  /// In ko, this message translates to:
  /// **'확인된 섭취 {n}kcal · 열량 미상 {m}건'**
  String mealIntakePartial(int n, int m);

  /// No description provided for @mealAmountAsk.
  ///
  /// In ko, this message translates to:
  /// **'얼마나 드셨나요?'**
  String get mealAmountAsk;

  /// No description provided for @mealBasis.
  ///
  /// In ko, this message translates to:
  /// **'기준'**
  String get mealBasis;

  /// No description provided for @mealEaten.
  ///
  /// In ko, this message translates to:
  /// **'먹은 양'**
  String get mealEaten;

  /// No description provided for @mealUnitServing.
  ///
  /// In ko, this message translates to:
  /// **'회분'**
  String get mealUnitServing;

  /// No description provided for @mealUnitPackage.
  ///
  /// In ko, this message translates to:
  /// **'포장 전체'**
  String get mealUnitPackage;

  /// No description provided for @mealUnitPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 속 음식'**
  String get mealUnitPhoto;

  /// No description provided for @mealWhole.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get mealWhole;

  /// No description provided for @mealHalf.
  ///
  /// In ko, this message translates to:
  /// **'절반'**
  String get mealHalf;

  /// No description provided for @mealPhotoWholeNote.
  ///
  /// In ko, this message translates to:
  /// **'사진에 보이는 음식 전체를 어림한 값이에요. 그중 드신 만큼을 고르세요.'**
  String get mealPhotoWholeNote;

  /// No description provided for @mealTextUnknown.
  ///
  /// In ko, this message translates to:
  /// **'무슨 음식인지 몰라 열량을 어림하지 못했어요. 끼니 줄을 눌러 음식 이름이나 양을 더 적으면 다시 어림해요.'**
  String get mealTextUnknown;

  /// No description provided for @mealTextOffline.
  ///
  /// In ko, this message translates to:
  /// **'연결이 안 돼 열량을 어림하지 못했어요. 끼니 줄을 누르고 Enter 를 누르면 다시 어림해요.'**
  String get mealTextOffline;

  /// No description provided for @mealTextTooLong.
  ///
  /// In ko, this message translates to:
  /// **'500자가 넘는 식단 글은 어림하지 않아요. 끼니 줄을 눌러 나눠 적으면 어림해요.'**
  String get mealTextTooLong;

  /// No description provided for @queryTooLong.
  ///
  /// In ko, this message translates to:
  /// **'질문은 {max}자까지예요. 줄여서 물어 주세요.'**
  String queryTooLong(int max);

  /// No description provided for @queryPressEnter.
  ///
  /// In ko, this message translates to:
  /// **'Enter 를 누르면 기록에 물어볼 수 있어요.'**
  String get queryPressEnter;

  /// No description provided for @mealRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 어림'**
  String get mealRetry;

  /// No description provided for @kcalAtLeast.
  ///
  /// In ko, this message translates to:
  /// **'{n}kcal 이상'**
  String kcalAtLeast(int n);

  /// No description provided for @mealTextPartial.
  ///
  /// In ko, this message translates to:
  /// **'적은 {n}kcal만 합계에 넣었어요. 나머지 음식은 열량을 몰라요.'**
  String mealTextPartial(int n);

  /// No description provided for @mealTextBelowTyped.
  ///
  /// In ko, this message translates to:
  /// **'어림값이 글에 적은 {n}kcal보다 작아 받지 않았어요. 적은 {n}kcal만 합계에 넣었어요.'**
  String mealTextBelowTyped(int n);

  /// No description provided for @queryLimit.
  ///
  /// In ko, this message translates to:
  /// **'{kind, select, exercises{운동은 한 번에 8개까지 물을 수 있어요. 나눠서 물어 주세요.} measures{한 번에 네 가지까지 셀 수 있어요. 나눠서 물어 주세요.} ranking{순위는 20개까지 보여 줄 수 있어요. 20개 이하로 물어 주세요.} sessions{\'마지막 N번\'은 100번까지예요. 더 길게 보려면 기간으로 물어 주세요. 예: 올해} days{\'최근 N일\'은 3660일(약 10년)까지예요. 더 길게 보려면 전체 기간으로 물어 주세요.} compare{한 번에 6가지까지 견줄 수 있어요. 나눠서 물어 주세요.} compareGrouped{견주기와 운동·날·주·월·요일별 묶음은 한 질문에 함께 셀 수 없어요. 둘 중 하나로 물어 주세요.} groupedMeasure{날·주·월·요일별로 묶어 여러 범위를 견주면 한 가지만 셀 수 있고, 추이·마지막·처음·안 한 지는 묶을 수 없어요.} ordering{순위·합계·평균은 운동별이나 주별처럼 묶어서 물어 주세요.} datesTotal{마지막·처음 날짜는 더하거나 평균 낼 수 없어요.} perMeasure{날당·주당·달당 평균은 세트·횟수·볼륨·거리·시간·날 수·칼로리처럼 더하는 수에만 낼 수 있어요. 최고·평균 무게는 기간으로 물어 주세요.} shareMeasure{비중은 세트 수·볼륨처럼 더하는 수로만 낼 수 있어요.} trainedMeasure{운동한 날·쉰 날로 고르기는 먹은·태운 칼로리에만 써요. 운동 기록은 모두 운동한 날의 것이에요.} sameSeries{견줄 두 범위가 같게 읽혔어요. 무엇과 무엇을 견줄지 적어 주세요.} other{이 질문은 기록 검색이 셀 수 없는 모양이에요. 나눠서 물어 주세요.}}'**
  String queryLimit(String kind);

  /// No description provided for @policyNumberRejected.
  ///
  /// In ko, this message translates to:
  /// **'{why, select, decimal{\'{text}\' — 소수는 받지 않아요. 정수로 적어 주세요. 예: 14} range{\'{text}\' — 범위가 아니라 수 하나로 적어 주세요. 예: 14} negative{\'{text}\' — 0보다 작은 수는 받지 않아요. 예: 14} unit{\'{text}\' — 이 칸은 일·회로 세요. 시간·주·달은 일 수로 바꿔 적어 주세요. 예: 14} many{\'{text}\' — 수는 하나만 적어 주세요. 예: 14} other{\'{text}\' 에서 일·회 수를 읽지 못했어요. 숫자로 적어 주세요. 예: 14}}'**
  String policyNumberRejected(String text, String why);

  /// No description provided for @mealSources.
  ///
  /// In ko, this message translates to:
  /// **'출처'**
  String get mealSources;

  /// No description provided for @mealSourcesTitle.
  ///
  /// In ko, this message translates to:
  /// **'열량 근거'**
  String get mealSourcesTitle;

  /// No description provided for @mealSourcesNote.
  ///
  /// In ko, this message translates to:
  /// **'아래 표의 값으로 계산했어요. 누르면 원본 표에서 같은 이름을 찾아 보여 줘요. 표에 없는 음식은 AI가 어림한 값이에요.'**
  String get mealSourcesNote;

  /// No description provided for @mealSourcePer.
  ///
  /// In ko, this message translates to:
  /// **'100{unit}당 {kcal}kcal'**
  String mealSourcePer(String unit, String kcal);

  /// No description provided for @mealSourceMfds.
  ///
  /// In ko, this message translates to:
  /// **'식약처 식품영양성분 DB'**
  String get mealSourceMfds;

  /// No description provided for @mealSourceUsda.
  ///
  /// In ko, this message translates to:
  /// **'USDA FoodData Central'**
  String get mealSourceUsda;

  /// No description provided for @mealAmountInvalid.
  ///
  /// In ko, this message translates to:
  /// **'0 이상의 숫자를 입력해 주세요.'**
  String get mealAmountInvalid;

  /// No description provided for @dayEnergyFull.
  ///
  /// In ko, this message translates to:
  /// **'먹은 것 {intake} · 운동 {burned} = {diff}kcal'**
  String dayEnergyFull(String intake, String burned, String diff);

  /// No description provided for @dayEnergyApprox.
  ///
  /// In ko, this message translates to:
  /// **'먹은 것 {intake} · 운동 {burned} = {diff}kcal (추정)'**
  String dayEnergyApprox(String intake, String burned, String diff);

  /// No description provided for @dayBurnedMissing.
  ///
  /// In ko, this message translates to:
  /// **'운동 소모량 미측정 · 차이 계산 불가'**
  String get dayBurnedMissing;

  /// No description provided for @dayBurnedOnly.
  ///
  /// In ko, this message translates to:
  /// **'운동 {n}kcal · 식단 미기록'**
  String dayBurnedOnly(String n);

  /// No description provided for @intakeLabel.
  ///
  /// In ko, this message translates to:
  /// **'섭취'**
  String get intakeLabel;

  /// No description provided for @partnerSignIn.
  ///
  /// In ko, this message translates to:
  /// **'같이 하려면 로그인이 필요합니다.'**
  String get partnerSignIn;

  /// No description provided for @partnerSignInAction.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get partnerSignInAction;

  /// No description provided for @partnerMakeCode.
  ///
  /// In ko, this message translates to:
  /// **'코드 만들기'**
  String get partnerMakeCode;

  /// No description provided for @partnerCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get partnerCopy;

  /// No description provided for @partnerExpiresIn.
  ///
  /// In ko, this message translates to:
  /// **'{t} 뒤 만료'**
  String partnerExpiresIn(String t);

  /// No description provided for @partnerExpired.
  ///
  /// In ko, this message translates to:
  /// **'코드가 만료되었습니다.'**
  String get partnerExpired;

  /// No description provided for @partnerNewCode.
  ///
  /// In ko, this message translates to:
  /// **'새 코드'**
  String get partnerNewCode;

  /// No description provided for @partnerStopWaiting.
  ///
  /// In ko, this message translates to:
  /// **'그만두기'**
  String get partnerStopWaiting;

  /// No description provided for @partnerWith.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님과 함께 운동 중'**
  String partnerWith(String name);

  /// No description provided for @partnerReconnecting.
  ///
  /// In ko, this message translates to:
  /// **'연결 복구 중 · 내 기록은 계속 저장됩니다'**
  String get partnerReconnecting;

  /// No description provided for @partnerTheirRecord.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님의 기록'**
  String partnerTheirRecord(String name);

  /// No description provided for @partnerNoRecordYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 올라온 기록이 없습니다.'**
  String get partnerNoRecordYet;

  /// No description provided for @partnerLoading.
  ///
  /// In ko, this message translates to:
  /// **'불러오는 중…'**
  String get partnerLoading;

  /// No description provided for @partnerEnd.
  ///
  /// In ko, this message translates to:
  /// **'함께 운동 종료'**
  String get partnerEnd;

  /// No description provided for @partnerEndedByMe.
  ///
  /// In ko, this message translates to:
  /// **'함께 운동을 종료했습니다. 내 기록은 그대로 남아 있습니다.'**
  String get partnerEndedByMe;

  /// No description provided for @partnerEndedByThem.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님이 함께 운동을 종료했습니다. 내 기록은 그대로 남아 있습니다.'**
  String partnerEndedByThem(String name);

  /// No description provided for @partnerErrFormat.
  ///
  /// In ko, this message translates to:
  /// **'코드는 여섯 글자입니다. 다시 확인해 주세요.'**
  String get partnerErrFormat;

  /// No description provided for @partnerErrInvalid.
  ///
  /// In ko, this message translates to:
  /// **'맞는 코드가 없습니다. 이미 사용됐거나 잘못 입력했을 수 있어요.'**
  String get partnerErrInvalid;

  /// No description provided for @partnerErrExpired.
  ///
  /// In ko, this message translates to:
  /// **'만료된 코드입니다. 상대에게 새 코드를 받아 주세요.'**
  String get partnerErrExpired;

  /// No description provided for @partnerErrEnded.
  ///
  /// In ko, this message translates to:
  /// **'이미 종료된 초대입니다.'**
  String get partnerErrEnded;

  /// No description provided for @partnerErrOwn.
  ///
  /// In ko, this message translates to:
  /// **'내가 만든 코드입니다. 상대의 기기에서 입력해 주세요.'**
  String get partnerErrOwn;

  /// No description provided for @partnerErrTries.
  ///
  /// In ko, this message translates to:
  /// **'시도가 너무 많습니다. 잠시 뒤에 다시 해 주세요.'**
  String get partnerErrTries;

  /// No description provided for @partnerErrNetwork.
  ///
  /// In ko, this message translates to:
  /// **'서버에 연결하지 못했습니다. 네트워크를 확인하고 다시 시도해 주세요.'**
  String get partnerErrNetwork;

  /// No description provided for @partnerErrServer.
  ///
  /// In ko, this message translates to:
  /// **'서버에 문제가 있습니다. 잠시 뒤에 다시 시도해 주세요.'**
  String get partnerErrServer;

  /// No description provided for @partnerRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get partnerRetry;

  /// No description provided for @partnerReadOnly.
  ///
  /// In ko, this message translates to:
  /// **'읽기 전용'**
  String get partnerReadOnly;

  /// No description provided for @partnerConflict.
  ///
  /// In ko, this message translates to:
  /// **'다른 기기에서 더 새 기록을 공유했습니다. 이 기기의 기록은 그대로 저장돼 있고, 공유만 멈춘 상태입니다.'**
  String get partnerConflict;

  /// No description provided for @partnerShareThisDevice.
  ///
  /// In ko, this message translates to:
  /// **'이 기기의 기록으로 공유하기'**
  String get partnerShareThisDevice;

  /// No description provided for @plansTitle.
  ///
  /// In ko, this message translates to:
  /// **'공동 루틴'**
  String get plansTitle;

  /// No description provided for @planNew.
  ///
  /// In ko, this message translates to:
  /// **'새 공동 루틴'**
  String get planNew;

  /// No description provided for @planJoin.
  ///
  /// In ko, this message translates to:
  /// **'코드로 참여'**
  String get planJoin;

  /// No description provided for @planHint.
  ///
  /// In ko, this message translates to:
  /// **'첫 줄은 제목, 그다음은 한 줄에 한 종목\n예: 스쿼트 4세트'**
  String get planHint;

  /// No description provided for @planDateNone.
  ///
  /// In ko, this message translates to:
  /// **'날짜 미정'**
  String get planDateNone;

  /// No description provided for @planSetsCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}세트'**
  String planSetsCount(int n);

  /// No description provided for @planSave.
  ///
  /// In ko, this message translates to:
  /// **'제안하기'**
  String get planSave;

  /// No description provided for @planStateLocal.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에만 있는 초안 · 서버에 아직 올라가지 않았습니다'**
  String get planStateLocal;

  /// No description provided for @planStateDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안 · 아직 혼자입니다'**
  String get planStateDraft;

  /// No description provided for @planStateWaiting.
  ///
  /// In ko, this message translates to:
  /// **'상대 확인 대기 · 버전 {v}'**
  String planStateWaiting(int v);

  /// No description provided for @planStateNeedsMe.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님이 고쳤습니다 · 버전 {v} 확인이 필요합니다'**
  String planStateNeedsMe(String name, int v);

  /// No description provided for @planStateAgreed.
  ///
  /// In ko, this message translates to:
  /// **'합의 완료 · 버전 {v}'**
  String planStateAgreed(int v);

  /// No description provided for @planStateWithdrawn.
  ///
  /// In ko, this message translates to:
  /// **'함께 계획이 끝났습니다 · 합의본과 내 목표는 남아 있습니다'**
  String get planStateWithdrawn;

  /// No description provided for @planAccept.
  ///
  /// In ko, this message translates to:
  /// **'버전 {v} 수락'**
  String planAccept(int v);

  /// No description provided for @planChanged.
  ///
  /// In ko, this message translates to:
  /// **'마지막 합의본에서 바뀐 것'**
  String get planChanged;

  /// No description provided for @planAdded.
  ///
  /// In ko, this message translates to:
  /// **'추가: {x}'**
  String planAdded(String x);

  /// No description provided for @planRemoved.
  ///
  /// In ko, this message translates to:
  /// **'빠짐: {x}'**
  String planRemoved(String x);

  /// No description provided for @planSetsChanged.
  ///
  /// In ko, this message translates to:
  /// **'세트 수 변경: {x}'**
  String planSetsChanged(String x);

  /// No description provided for @planReordered.
  ///
  /// In ko, this message translates to:
  /// **'순서가 바뀌었습니다'**
  String get planReordered;

  /// No description provided for @planDateChanged.
  ///
  /// In ko, this message translates to:
  /// **'예정 날짜가 바뀌었습니다'**
  String get planDateChanged;

  /// No description provided for @planTitleChanged.
  ///
  /// In ko, this message translates to:
  /// **'제목이 바뀌었습니다'**
  String get planTitleChanged;

  /// No description provided for @planLastAgreed.
  ///
  /// In ko, this message translates to:
  /// **'마지막 합의본 · 버전 {v}'**
  String planLastAgreed(int v);

  /// No description provided for @planConflict.
  ///
  /// In ko, this message translates to:
  /// **'상대가 먼저 고쳤습니다. 내 초안은 그대로 있습니다.'**
  String get planConflict;

  /// No description provided for @planLatest.
  ///
  /// In ko, this message translates to:
  /// **'상대가 고친 최신 계획 · 버전 {v}'**
  String planLatest(int v);

  /// No description provided for @planKeepMine.
  ///
  /// In ko, this message translates to:
  /// **'내 초안으로 다시 제안'**
  String get planKeepMine;

  /// No description provided for @planTakeLatest.
  ///
  /// In ko, this message translates to:
  /// **'최신 계획으로 바꾸기'**
  String get planTakeLatest;

  /// No description provided for @planMyTarget.
  ///
  /// In ko, this message translates to:
  /// **'내 목표'**
  String get planMyTarget;

  /// No description provided for @planPartnerTarget.
  ///
  /// In ko, this message translates to:
  /// **'{name}: {t}'**
  String planPartnerTarget(String name, String t);

  /// No description provided for @planTargetHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 100 5 또는 100kg 5회 x3 메모'**
  String get planTargetHint;

  /// No description provided for @planInvite.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드 만들기'**
  String get planInvite;

  /// No description provided for @planStart.
  ///
  /// In ko, this message translates to:
  /// **'이 루틴으로 시작'**
  String get planStart;

  /// No description provided for @planStartSolo.
  ///
  /// In ko, this message translates to:
  /// **'본인용 사본으로 시작'**
  String get planStartSolo;

  /// No description provided for @planStartSoloNote.
  ///
  /// In ko, this message translates to:
  /// **'아직 합의 전입니다. 지금 시작하면 공동 합의본이 아니라 본인용 사본으로 시작합니다.'**
  String get planStartSoloNote;

  /// No description provided for @planOpenWorkout.
  ///
  /// In ko, this message translates to:
  /// **'시작한 운동 열기'**
  String get planOpenWorkout;

  /// No description provided for @planCopyNext.
  ///
  /// In ko, this message translates to:
  /// **'다음 운동으로 복사'**
  String get planCopyNext;

  /// No description provided for @planWithdraw.
  ///
  /// In ko, this message translates to:
  /// **'함께 계획 그만두기'**
  String get planWithdraw;

  /// No description provided for @planCompare.
  ///
  /// In ko, this message translates to:
  /// **'계획과 실제'**
  String get planCompare;

  /// No description provided for @planDoneSets.
  ///
  /// In ko, this message translates to:
  /// **'{name} · 계획 {planned}세트 · 수행 {done}세트'**
  String planDoneSets(String name, int planned, int done);

  /// No description provided for @planAddedActual.
  ///
  /// In ko, this message translates to:
  /// **'계획에 없던 운동: {x}'**
  String planAddedActual(String x);

  /// No description provided for @planSkipped.
  ///
  /// In ko, this message translates to:
  /// **'하지 않은 운동: {x}'**
  String planSkipped(String x);

  /// No description provided for @planStartedFrom.
  ///
  /// In ko, this message translates to:
  /// **'공동 루틴 합의본(버전 {v})에서 시작했습니다'**
  String planStartedFrom(int v);

  /// No description provided for @planStartedSolo.
  ///
  /// In ko, this message translates to:
  /// **'본인용 사본(버전 {v}, 합의 전)에서 시작했습니다'**
  String planStartedSolo(int v);

  /// No description provided for @planShareLink.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크 보내기'**
  String get planShareLink;

  /// No description provided for @planShareText.
  ///
  /// In ko, this message translates to:
  /// **'setpad에서 운동 계획을 같이 짜요: {url}'**
  String planShareText(String url);

  /// No description provided for @planLinkCopied.
  ///
  /// In ko, this message translates to:
  /// **'링크를 복사했습니다. 하루 동안 한 번 쓸 수 있습니다.'**
  String get planLinkCopied;

  /// No description provided for @planLinkJoining.
  ///
  /// In ko, this message translates to:
  /// **'초대받은 계획에 참여하는 중…'**
  String get planLinkJoining;

  /// No description provided for @nearbyHint.
  ///
  /// In ko, this message translates to:
  /// **'아이폰끼리는 이 화면을 연 채 두 기기를 가까이 대도 연결됩니다.'**
  String get nearbyHint;

  /// No description provided for @planPropose.
  ///
  /// In ko, this message translates to:
  /// **'공동 루틴으로 제안'**
  String get planPropose;

  /// No description provided for @togetherStart.
  ///
  /// In ko, this message translates to:
  /// **'같이 시작'**
  String get togetherStart;

  /// No description provided for @togetherAlternate.
  ///
  /// In ko, this message translates to:
  /// **'교대로'**
  String get togetherAlternate;

  /// No description provided for @togetherWaiting.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님을 기다리는 중…'**
  String togetherWaiting(String name);

  /// No description provided for @togetherWaitingHint.
  ///
  /// In ko, this message translates to:
  /// **'상대 화면에 요청이 뜹니다. 안 보이면 상대 앱이 최신인지 확인하세요.'**
  String get togetherWaitingHint;

  /// No description provided for @togetherInvite.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님이 같이 하자고 합니다'**
  String togetherInvite(String name);

  /// No description provided for @togetherInviteAlternate.
  ///
  /// In ko, this message translates to:
  /// **'교대 · 상대가 먼저'**
  String get togetherInviteAlternate;

  /// No description provided for @togetherLeave.
  ///
  /// In ko, this message translates to:
  /// **'그만'**
  String get togetherLeave;

  /// No description provided for @togetherRejoin.
  ///
  /// In ko, this message translates to:
  /// **'다시 들어가기'**
  String get togetherRejoin;

  /// No description provided for @togetherWith.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님과 같이'**
  String togetherWith(String name);

  /// No description provided for @togetherTheirTurn.
  ///
  /// In ko, this message translates to:
  /// **'상대 차례'**
  String get togetherTheirTurn;

  /// No description provided for @togetherLeftBeat.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님은 {n}번째에서 멈춤'**
  String togetherLeftBeat(String name, int n);

  /// No description provided for @togetherLeftRound.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님은 {n}라운드에서 멈춤'**
  String togetherLeftRound(String name, int n);

  /// No description provided for @togetherMe.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get togetherMe;

  /// No description provided for @togetherLog.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get togetherLog;

  /// No description provided for @mealLogAs.
  ///
  /// In ko, this message translates to:
  /// **'식단으로 기록'**
  String get mealLogAs;

  /// No description provided for @mealAutoLogged.
  ///
  /// In ko, this message translates to:
  /// **'끼니로 남겼어요'**
  String get mealAutoLogged;

  /// No description provided for @mealAutoUndo.
  ///
  /// In ko, this message translates to:
  /// **'운동으로 바꾸기'**
  String get mealAutoUndo;

  /// No description provided for @proxyWrite.
  ///
  /// In ko, this message translates to:
  /// **'대신 적기'**
  String get proxyWrite;

  /// No description provided for @proxyWriting.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님의 기록을 적는 중'**
  String proxyWriting(String name);

  /// No description provided for @proxyDefaultName.
  ///
  /// In ko, this message translates to:
  /// **'상대'**
  String get proxyDefaultName;

  /// No description provided for @proxyHand.
  ///
  /// In ko, this message translates to:
  /// **'건네기'**
  String get proxyHand;

  /// No description provided for @proxyBack.
  ///
  /// In ko, this message translates to:
  /// **'내 기록으로'**
  String get proxyBack;

  /// No description provided for @proxyShareText.
  ///
  /// In ko, this message translates to:
  /// **'같이 운동하며 대신 적은 기록입니다. setpad 에서 열어 받으면 내 운동 기록이 됩니다.\n{url}'**
  String proxyShareText(String url);

  /// No description provided for @handoffOffer.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님이 내 기록을 적어 주었습니다'**
  String handoffOffer(String name);

  /// No description provided for @handoffTake.
  ///
  /// In ko, this message translates to:
  /// **'받기'**
  String get handoffTake;

  /// No description provided for @handoffFailed.
  ///
  /// In ko, this message translates to:
  /// **'기록을 받지 못했습니다. 링크가 만료됐거나 네트워크 문제일 수 있습니다.'**
  String get handoffFailed;

  /// No description provided for @handoffSignIn.
  ///
  /// In ko, this message translates to:
  /// **'건네받은 기록을 받으려면 로그인이 필요합니다.'**
  String get handoffSignIn;

  /// No description provided for @partnerInviteMore.
  ///
  /// In ko, this message translates to:
  /// **'한 명 더 초대 · 코드 {code}'**
  String partnerInviteMore(String code);

  /// No description provided for @proxyWhose.
  ///
  /// In ko, this message translates to:
  /// **'누구의 기록을 적을까요?'**
  String get proxyWhose;

  /// No description provided for @planMemberAccepted.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님 동의함'**
  String planMemberAccepted(String name);

  /// No description provided for @planMemberWaiting.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님 확인 전'**
  String planMemberWaiting(String name);

  /// No description provided for @deleteNoteAsk.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\" 기록을 지울까요?'**
  String deleteNoteAsk(String title);

  /// No description provided for @mealsTitle.
  ///
  /// In ko, this message translates to:
  /// **'먹은 것'**
  String get mealsTitle;

  /// No description provided for @energyBurned.
  ///
  /// In ko, this message translates to:
  /// **'운동'**
  String get energyBurned;

  /// No description provided for @energyDifference.
  ///
  /// In ko, this message translates to:
  /// **'차이'**
  String get energyDifference;

  /// No description provided for @energyDiffFormula.
  ///
  /// In ko, this message translates to:
  /// **'먹은 것 − 운동'**
  String get energyDiffFormula;

  /// No description provided for @energyDiffExplain.
  ///
  /// In ko, this message translates to:
  /// **'기록한 먹은 것에서 운동으로 쓴 칼로리를 뺀 값이에요. + 면 운동으로 쓴 것보다 더 먹은 것이고, − 면 덜 먹은 거예요.\n\n기초대사량과 일상 활동으로 쓰는 칼로리는 들어 있지 않아서, 이 값이 곧 살이 찌거나 빠지는 양은 아니에요.'**
  String get energyDiffExplain;

  /// No description provided for @estimateTag.
  ///
  /// In ko, this message translates to:
  /// **'추정'**
  String get estimateTag;

  /// No description provided for @energyNotLogged.
  ///
  /// In ko, this message translates to:
  /// **'미기록'**
  String get energyNotLogged;

  /// No description provided for @energyNotMeasured.
  ///
  /// In ko, this message translates to:
  /// **'미측정'**
  String get energyNotMeasured;

  /// No description provided for @recordMenu.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get recordMenu;

  /// No description provided for @dayIntakeOnly.
  ///
  /// In ko, this message translates to:
  /// **'먹은 것 {intake}kcal · 운동 소모 미측정'**
  String dayIntakeOnly(String intake);

  /// No description provided for @dayIntakeOnlyApprox.
  ///
  /// In ko, this message translates to:
  /// **'먹은 것 {intake}kcal (추정) · 운동 소모 미측정'**
  String dayIntakeOnlyApprox(String intake);

  /// No description provided for @dayUnknownMeals.
  ///
  /// In ko, this message translates to:
  /// **'열량 미상 {m}건'**
  String dayUnknownMeals(int m);

  /// No description provided for @healthDataTitle.
  ///
  /// In ko, this message translates to:
  /// **'건강 데이터'**
  String get healthDataTitle;

  /// No description provided for @healthDataIntro.
  ///
  /// In ko, this message translates to:
  /// **'setpad가 건강 앱(Apple 건강, 헬스 커넥트)과 주고받는 것과 그 이유입니다.'**
  String get healthDataIntro;

  /// No description provided for @healthDataWrite.
  ///
  /// In ko, this message translates to:
  /// **'쓰기 · 운동 — 기록을 마치면 그 운동을 운동 세션으로 남깁니다.'**
  String get healthDataWrite;

  /// No description provided for @healthDataCalories.
  ///
  /// In ko, this message translates to:
  /// **'읽기 · 활동 칼로리 — 운동한 시간 동안 워치가 잰 활동 칼로리를 그 기록에 붙입니다. 잰 것이 없으면 칼로리를 표시하지 않습니다.'**
  String get healthDataCalories;

  /// No description provided for @healthDataHeart.
  ///
  /// In ko, this message translates to:
  /// **'읽기 · 심박수 — 타바타 휴식 중 심박이 그 라운드의 최고치보다 25bpm 내려오면 휴식을 끝내고 다음 라운드 시작을 알립니다. 쉬는 동안 타이머 줄에 ♥ 지금 → 목표로 보입니다. 심박이 없거나 90초보다 오래된 값이면 휴식은 시간대로 끝납니다.'**
  String get healthDataHeart;

  /// No description provided for @healthDataStays.
  ///
  /// In ko, this message translates to:
  /// **'건강 앱에서 읽은 값은 기기 밖으로 나가지 않습니다. 서버로 보내지 않고, 광고나 마케팅에 쓰지 않습니다.'**
  String get healthDataStays;

  /// No description provided for @healthDataRevokeIos.
  ///
  /// In ko, this message translates to:
  /// **'권한은 iPhone 설정 → 개인정보 보호 및 보안 → 건강 → setpad에서 언제든 끌 수 있습니다.'**
  String get healthDataRevokeIos;

  /// No description provided for @healthDataRevokeAndroid.
  ///
  /// In ko, this message translates to:
  /// **'권한은 헬스 커넥트 → 앱 권한 → setpad에서 언제든 끌 수 있습니다.'**
  String get healthDataRevokeAndroid;

  /// No description provided for @healthDataPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get healthDataPrivacy;

  /// AlarmKit alert title when heart rate ends a Tabata rest; forwarded to the watch.
  ///
  /// In ko, this message translates to:
  /// **'다음 라운드 — 심박이 내려왔어요'**
  String get restAlarmTitle;

  /// No description provided for @liveSetBusy.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 이 세트를 고치는 중이에요. 다 고친 뒤에 눌러 주세요.'**
  String liveSetBusy(String name);

  /// No description provided for @liveExerciseBusy.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 지금 이 운동을 적고 있어요.'**
  String liveExerciseBusy(String name);

  /// No description provided for @liveExerciseRemoved.
  ///
  /// In ko, this message translates to:
  /// **'같이 하는 사람이 {exercise}을(를) 지웠어요. 치던 글은 입력 줄에 남아 있어요.'**
  String liveExerciseRemoved(String exercise);

  /// 직원에게만 보이는 입구와 그 화면 제목. 에이전트가 정리한 보고서
  ///
  /// In ko, this message translates to:
  /// **'트레이너 보고'**
  String get trainerReport;

  /// 입구 옆 점의 읽기 이름(스크린 리더)
  ///
  /// In ko, this message translates to:
  /// **'새 보고서'**
  String get trainerUnread;

  /// No description provided for @trainerRanAt.
  ///
  /// In ko, this message translates to:
  /// **'{when} 정리'**
  String trainerRanAt(String when);

  /// No description provided for @trainerRunNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 정리하기'**
  String get trainerRunNow;

  /// No description provided for @trainerNoReport.
  ///
  /// In ko, this message translates to:
  /// **'아직 정리된 보고서가 없어요. 지금 정리해 볼까요?'**
  String get trainerNoReport;

  /// No description provided for @trainerOutdated.
  ///
  /// In ko, this message translates to:
  /// **'이 보고서는 새 버전에서 볼 수 있어요. 앱을 업데이트해 주세요.'**
  String get trainerOutdated;

  /// No description provided for @trainerFailed.
  ///
  /// In ko, this message translates to:
  /// **'서버에 닿지 못했어요. 잠시 뒤에 다시 해 주세요.'**
  String get trainerFailed;

  /// No description provided for @trainerActUnknown.
  ///
  /// In ko, this message translates to:
  /// **'결과를 확인하지 못했어요. 다시 눌러도 두 번 기록되지 않아요.'**
  String get trainerActUnknown;

  /// No description provided for @trainerDone.
  ///
  /// In ko, this message translates to:
  /// **'에이전트가 처리한 일'**
  String get trainerDone;

  /// No description provided for @trainerToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 수업'**
  String get trainerToday;

  /// No description provided for @trainerTodo.
  ///
  /// In ko, this message translates to:
  /// **'확인할 일'**
  String get trainerTodo;

  /// No description provided for @trainerAllClear.
  ///
  /// In ko, this message translates to:
  /// **'확인할 일을 모두 처리했어요.'**
  String get trainerAllClear;

  /// No description provided for @trainerAttendance.
  ///
  /// In ko, this message translates to:
  /// **'마무리 전 수업'**
  String get trainerAttendance;

  /// No description provided for @trainerVisited.
  ///
  /// In ko, this message translates to:
  /// **'방문 확인 {time}'**
  String trainerVisited(String time);

  /// No description provided for @trainerFinishAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 완료 ({count})'**
  String trainerFinishAll(int count);

  /// No description provided for @trainerFinishAsk.
  ///
  /// In ko, this message translates to:
  /// **'{count}건 완료 — PT 이용권에서 1회씩 차감돼요.'**
  String trainerFinishAsk(int count);

  /// No description provided for @trainerFinish.
  ///
  /// In ko, this message translates to:
  /// **'완료하기'**
  String get trainerFinish;

  /// No description provided for @trainerJoinRequest.
  ///
  /// In ko, this message translates to:
  /// **'등록 요청 — 웹 CRM 오늘 화면에서 확인해 주세요.'**
  String get trainerJoinRequest;

  /// No description provided for @trainerBook.
  ///
  /// In ko, this message translates to:
  /// **'잡기'**
  String get trainerBook;

  /// No description provided for @trainerSend.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get trainerSend;

  /// No description provided for @trainerPaid.
  ///
  /// In ko, this message translates to:
  /// **'결제 받음'**
  String get trainerPaid;

  /// No description provided for @trainerContacted.
  ///
  /// In ko, this message translates to:
  /// **'연락함'**
  String get trainerContacted;

  /// No description provided for @trainerLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get trainerLater;

  /// 원화 금액. 상품가는 늘 원이다
  ///
  /// In ko, this message translates to:
  /// **'{price}원'**
  String trainerPrice(int price);

  /// No description provided for @trainerStarts.
  ///
  /// In ko, this message translates to:
  /// **'{d}부터'**
  String trainerStarts(String d);

  /// No description provided for @trainerPayHow.
  ///
  /// In ko, this message translates to:
  /// **'어떻게 받으셨나요?'**
  String get trainerPayHow;

  /// No description provided for @trainerPaidListPrice.
  ///
  /// In ko, this message translates to:
  /// **'상품가 그대로 결제로 기록돼요. 할인·나눠 받기는 웹 CRM 회원 화면의 회원권 탭에서 등록해 주세요.'**
  String get trainerPaidListPrice;

  /// No description provided for @payCard.
  ///
  /// In ko, this message translates to:
  /// **'카드'**
  String get payCard;

  /// No description provided for @payCash.
  ///
  /// In ko, this message translates to:
  /// **'현금'**
  String get payCash;

  /// No description provided for @payTransfer.
  ///
  /// In ko, this message translates to:
  /// **'계좌이체'**
  String get payTransfer;

  /// No description provided for @payOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get payOther;

  /// No description provided for @agentSettings.
  ///
  /// In ko, this message translates to:
  /// **'에이전트 설정'**
  String get agentSettings;

  /// 서버 enabled — 끄면 정해진 시각에만 안 돈다. 지금 정리하기는 그대로. 웹 CRM 과 같은 말
  ///
  /// In ko, this message translates to:
  /// **'정해진 시각에 정리'**
  String get agentEnabled;

  /// No description provided for @agentTimes.
  ///
  /// In ko, this message translates to:
  /// **'정리 시각'**
  String get agentTimes;

  /// No description provided for @agentAddTime.
  ///
  /// In ko, this message translates to:
  /// **'시각 추가'**
  String get agentAddTime;

  /// No description provided for @agentDays.
  ///
  /// In ko, this message translates to:
  /// **'요일'**
  String get agentDays;

  /// No description provided for @agentAutoConfirm.
  ///
  /// In ko, this message translates to:
  /// **'PT 신청 바로 확정'**
  String get agentAutoConfirm;

  /// No description provided for @agentModes.
  ///
  /// In ko, this message translates to:
  /// **'업무별 방식'**
  String get agentModes;

  /// No description provided for @agentModesHelp.
  ///
  /// In ko, this message translates to:
  /// **'직접 — 에이전트는 손대지 않아요. 초안 — 에이전트가 준비하면 내가 눌러 처리해요. 자동 — 에이전트가 처리해요.'**
  String get agentModesHelp;

  /// 서버 값 off — 에이전트는 손대지 않는다
  ///
  /// In ko, this message translates to:
  /// **'직접'**
  String get agentModeOff;

  /// 서버 값 draft — 에이전트가 준비하고 트레이너가 누른다
  ///
  /// In ko, this message translates to:
  /// **'초안'**
  String get agentModeDraft;

  /// 서버 값 auto — PT 일정만 된다
  ///
  /// In ko, this message translates to:
  /// **'자동'**
  String get agentModeAuto;

  /// No description provided for @taskPtSchedule.
  ///
  /// In ko, this message translates to:
  /// **'PT 일정'**
  String get taskPtSchedule;

  /// No description provided for @taskRenewal.
  ///
  /// In ko, this message translates to:
  /// **'재등록·재결제'**
  String get taskRenewal;

  /// No description provided for @taskAttendance.
  ///
  /// In ko, this message translates to:
  /// **'출결 정리'**
  String get taskAttendance;

  /// No description provided for @taskRoutine.
  ///
  /// In ko, this message translates to:
  /// **'루틴 준비'**
  String get taskRoutine;

  /// No description provided for @taskContact.
  ///
  /// In ko, this message translates to:
  /// **'회원 연락'**
  String get taskContact;

  /// No description provided for @gymPolicy.
  ///
  /// In ko, this message translates to:
  /// **'도장 방침'**
  String get gymPolicy;

  /// No description provided for @policyRenewalDays.
  ///
  /// In ko, this message translates to:
  /// **'재등록 안내 시점 (만료 며칠 전)'**
  String get policyRenewalDays;

  /// No description provided for @policyLowSessions.
  ///
  /// In ko, this message translates to:
  /// **'PT 부족 기준 (PT 예약 가능 횟수)'**
  String get policyLowSessions;

  /// No description provided for @policyAwayDays.
  ///
  /// In ko, this message translates to:
  /// **'미방문 기준 (일)'**
  String get policyAwayDays;

  /// No description provided for @policyLapsedDays.
  ///
  /// In ko, this message translates to:
  /// **'이탈 기간 (일)'**
  String get policyLapsedDays;

  /// No description provided for @policyOffer.
  ///
  /// In ko, this message translates to:
  /// **'재등록 안내 문구'**
  String get policyOffer;

  /// No description provided for @policySave.
  ///
  /// In ko, this message translates to:
  /// **'방침 저장'**
  String get policySave;

  /// No description provided for @policySaved.
  ///
  /// In ko, this message translates to:
  /// **'저장했어요.'**
  String get policySaved;

  /// 직원으로 있는 도장이 둘 이상일 때 트레이너 화면 앞에서 묻는 시트 제목. 회원용 bookingWhichGym 과 다른 말(도장)
  ///
  /// In ko, this message translates to:
  /// **'어느 도장인가요?'**
  String get trainerWhichGym;

  /// 트레이너 흐름의 확인·시트에서 물러나는 버튼. 웹 CRM 과 같은 말. 결제 시트 옆 "취소"는 결제 취소로 읽힌다
  ///
  /// In ko, this message translates to:
  /// **'돌아가기'**
  String get trainerBack;

  /// 회원에게 보낼 문구를 복사하는 버튼(웹 CRM 과 같은 말)
  ///
  /// In ko, this message translates to:
  /// **'문구 복사'**
  String get trainerCopy;

  /// 문구를 복사한 뒤 화면 아래 잠깐 뜨는 말. 트레이너 문구는 해요체
  ///
  /// In ko, this message translates to:
  /// **'복사했어요'**
  String get trainerCopied;

  /// 설정의 트레이너 섹션 제목. 회원용 "다니는 체육관" 섹션과 따로
  ///
  /// In ko, this message translates to:
  /// **'트레이너'**
  String get settingsTrainer;

  /// No description provided for @aiSetting.
  ///
  /// In ko, this message translates to:
  /// **'AI 도움'**
  String get aiSetting;

  /// AI 도움을 꺼 두어 모델을 부르지 않았을 때 한 줄(운동 입력·식단 글·기록 질문)
  ///
  /// In ko, this message translates to:
  /// **'AI 도움이 꺼져 있어 적은 그대로 두었어요. 설정 › AI 도움에서 켤 수 있어요'**
  String get aiOff;

  /// No description provided for @aiOffPhoto.
  ///
  /// In ko, this message translates to:
  /// **'AI 도움이 꺼져 있어 사진으로 어림하지 않았어요. 식단 글로 ‘김밥 450kcal’처럼 적으면 그대로 들어가요'**
  String get aiOffPhoto;

  /// 측정에 날이 둘 이상 필요한데 하나뿐일 때 칸 아래 줄
  ///
  /// In ko, this message translates to:
  /// **'날이 둘 이상 있어야 해요'**
  String get answerNeedsTwoDays;

  /// 변화율의 첫 값이 0 이라 셀 수 없을 때
  ///
  /// In ko, this message translates to:
  /// **'기준 값이 없어요'**
  String get answerNoBase;

  /// 주당 변화 속도
  ///
  /// In ko, this message translates to:
  /// **'주당 {value}'**
  String answerPerWeek(String value);

  /// 달당 변화 속도(8주 넘을 때)
  ///
  /// In ko, this message translates to:
  /// **'달당 {value}'**
  String answerPerMonth(String value);

  /// 최고 기록 뒤로 한 운동일 수
  ///
  /// In ko, this message translates to:
  /// **'최고 이후 {n}번 했어요'**
  String answerTimesAfter(int n);

  /// 횟수 단위(숫자 뒤에 붙음)
  ///
  /// In ko, this message translates to:
  /// **'번'**
  String get answerTimesUnit;

  /// 횟수
  ///
  /// In ko, this message translates to:
  /// **'{n}번'**
  String answerTimes(int n);

  /// 최장 연속 운동일
  ///
  /// In ko, this message translates to:
  /// **'{n}일 연속'**
  String answerStreak(int n);

  /// 최장 공백
  ///
  /// In ko, this message translates to:
  /// **'{n}일 쉼'**
  String answerRestDays(int n);

  /// 공백이 오늘까지 이어질 때 끝 날짜 자리
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get answerUntilToday;

  /// 운동 간격 중앙값
  ///
  /// In ko, this message translates to:
  /// **'보통 {value}일마다'**
  String answerEveryDays(String value);

  /// 운동 간격 평균
  ///
  /// In ko, this message translates to:
  /// **'평균 {value}일마다'**
  String answerMeanEvery(String value);

  /// 운동 간격 분포: 쉰 날 0·1·2·3 이상
  ///
  /// In ko, this message translates to:
  /// **'연달아 {a}번 · 하루 쉬고 {b}번 · 이틀 쉬고 {c}번 · 사흘 이상 쉬고 {d}번'**
  String answerGapSpread(int a, int b, int c, int d);

  /// 긴 휴가 하나가 평균을 부풀릴 때
  ///
  /// In ko, this message translates to:
  /// **'가장 긴 쉼 {n}일이 들어 있어요'**
  String answerLongestIncluded(int n);

  /// 섭취 측정인데 끼니가 없을 때
  ///
  /// In ko, this message translates to:
  /// **'끼니를 적은 날이 없어요'**
  String get answerNoMeals;

  /// 어림이 섞인 열량
  ///
  /// In ko, this message translates to:
  /// **'약 {value}'**
  String answerAbout(String value);

  /// 섭취를 센 날 수
  ///
  /// In ko, this message translates to:
  /// **'끼니를 적은 {n}일'**
  String answerMealDays(int n);

  /// 열량 모르는 끼니 수
  ///
  /// In ko, this message translates to:
  /// **'열량을 모르는 끼니 {n}개는 합에 없어요'**
  String queryUnknownMeals(int n);

  /// 소모 측정인데 워치 기록이 없을 때
  ///
  /// In ko, this message translates to:
  /// **'워치로 잰 기록이 없어요'**
  String get answerNoWatch;

  /// 소모를 센 날 수
  ///
  /// In ko, this message translates to:
  /// **'워치로 잰 {n}일'**
  String answerWatchDays(int n);

  /// 섭취−소모인데 둘 다 있는 날이 없을 때
  ///
  /// In ko, this message translates to:
  /// **'섭취와 소모가 둘 다 있는 날이 없어요'**
  String get answerNoBoth;

  /// 섭취·소모가 둘 다 있는 날 수
  ///
  /// In ko, this message translates to:
  /// **'섭취·소모가 둘 다 있는 {n}일'**
  String answerBothDays(int n);

  /// 섭취만 있어 차이에서 뺀 날
  ///
  /// In ko, this message translates to:
  /// **'섭취만 있는 {n}일은 뺐어요'**
  String answerIntakeOnlyDays(int n);

  /// 달 수
  ///
  /// In ko, this message translates to:
  /// **'{n}달'**
  String answerMonths(int n);

  /// 측정: 무게 변화율
  ///
  /// In ko, this message translates to:
  /// **'변화율'**
  String get metricChangePct;

  /// 측정: 최고 이후 지난 날
  ///
  /// In ko, this message translates to:
  /// **'최고 이후 날'**
  String get metricDaysSinceBest;

  /// 측정: 최고 이후 운동일 수(정체)
  ///
  /// In ko, this message translates to:
  /// **'최고 이후 횟수'**
  String get metricSessionsSinceBest;

  /// 측정: 세트당 반복
  ///
  /// In ko, this message translates to:
  /// **'세트당 반복'**
  String get metricMeanReps;

  /// 측정: 최장 연속 운동일
  ///
  /// In ko, this message translates to:
  /// **'최장 연속'**
  String get metricLongestStreak;

  /// 측정: 최장 공백
  ///
  /// In ko, this message translates to:
  /// **'최장 공백'**
  String get metricLongestGap;

  /// 측정: 운동 간격
  ///
  /// In ko, this message translates to:
  /// **'운동 간격'**
  String get metricMeanGap;

  /// 측정: 섭취 열량
  ///
  /// In ko, this message translates to:
  /// **'섭취 열량'**
  String get metricIntake;

  /// 측정: 워치 소모 열량
  ///
  /// In ko, this message translates to:
  /// **'소모 열량'**
  String get metricBurned;

  /// 측정: 섭취 − 소모
  ///
  /// In ko, this message translates to:
  /// **'섭취 − 소모'**
  String get metricBalance;

  /// 범위: 혼자 한 날
  ///
  /// In ko, this message translates to:
  /// **'혼자 한 날'**
  String get queryAlone;

  /// 범위: 같이 한 날(누가 들어온 같이 하기)
  ///
  /// In ko, this message translates to:
  /// **'같이 한 날'**
  String get queryTogether;

  /// 묶음: 부위별
  ///
  /// In ko, this message translates to:
  /// **'부위별'**
  String get queryByPart;

  /// 셀 것이 없는 질문에 기록으로 볼 수 있는 것
  ///
  /// In ko, this message translates to:
  /// **'기록으로는 무게·횟수·세트·운동한 날·끼니 열량을 볼 수 있어요'**
  String get queryCanSee;

  /// 표의 차이 칸 머리
  ///
  /// In ko, this message translates to:
  /// **'차이'**
  String get queryDiffColumn;

  /// 칸: 아직 오지 않은 기간
  ///
  /// In ko, this message translates to:
  /// **'아직 오지 않은 기간'**
  String get queryFutureCell;

  /// 각주: 성장 순위는 주당 속도
  ///
  /// In ko, this message translates to:
  /// **'성장은 주당 속도로 순위를 매겼어요 — 기간이 달라도 공정하게'**
  String get queryGrowthRate;

  /// 범위: 건네받은 기록만
  ///
  /// In ko, this message translates to:
  /// **'건네받은 기록만'**
  String get queryHandoff;

  /// 범위: 건네받은 기록 제외
  ///
  /// In ko, this message translates to:
  /// **'건네받은 기록 제외'**
  String get queryNoHandoff;

  /// 확인 줄: 뺀 건네받은 기록 수
  ///
  /// In ko, this message translates to:
  /// **'건네받은 기록 {n}개 제외'**
  String queryHandoffCount(int n);

  /// 각주: 시간대는 기록을 만든 시각 기준
  ///
  /// In ko, this message translates to:
  /// **'시각은 기록을 만든 때 기준이에요 — 나중에 몰아 적은 기록은 적은 시각으로 들어가요'**
  String get queryHoursNote;

  /// 각주: 여러 운동을 섞은 무게
  ///
  /// In ko, this message translates to:
  /// **'여러 운동을 섞은 무게예요'**
  String get queryMixedWeights;

  /// 못 보는 것: 체중(질문에 적으면 견줌)
  ///
  /// In ko, this message translates to:
  /// **'체중은 기록에 없어요 — 질문에 체중을 적으면 그 수와 견줘요(예: 체중 80인데 데드 몇 배?)'**
  String get queryNcBodyweight;

  /// No description provided for @queryNcWeightForecast.
  ///
  /// In ko, this message translates to:
  /// **'몇 kg 이 될지는 계산하지 않아요 — 기록에는 먹은 것과 운동 소모만 있고, 기초대사량·일상 활동으로 쓰는 칼로리가 없어요'**
  String get queryNcWeightForecast;

  /// 못 보는 것: 심박(정직하게)
  ///
  /// In ko, this message translates to:
  /// **'기록 검색은 아직 심박을 안 봐요 — 운동별·휴식별 심박은 세트 시각이 없어 볼 수 없어요'**
  String get queryNcHeartRate;

  /// 한 번도 적지 않은 운동 표시
  ///
  /// In ko, this message translates to:
  /// **'적은 적 없음'**
  String get queryNeverMark;

  /// 각주: 기준 값이 없어 비율 못 냄
  ///
  /// In ko, this message translates to:
  /// **'기준 값이 없어 비율을 못 내요'**
  String get queryNoBaseRatio;

  /// 칸: 적은 적은 있지만 이 범위엔 없음
  ///
  /// In ko, this message translates to:
  /// **'이 범위엔 기록 없음'**
  String get queryNoneCell;

  /// 범위: 루틴 아닌 날
  ///
  /// In ko, this message translates to:
  /// **'루틴 아닌 날'**
  String get queryNoRoutine;

  /// 범위: 트레이너 루틴으로 한 날
  ///
  /// In ko, this message translates to:
  /// **'루틴으로 한 날'**
  String get queryRoutine;

  /// 진행 중인 기간 표시
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get queryOngoing;

  /// 각주: 운동일수는 겹쳐 비중 못 냄
  ///
  /// In ko, this message translates to:
  /// **'운동일수는 겹치는 날이 있어 비중을 못 내요 — 세트 수로 물어 주세요'**
  String get queryOverlap;

  /// 부위 이름
  ///
  /// In ko, this message translates to:
  /// **'{part, select, chest{가슴} back{등} legs{다리} shoulders{어깨} arms{팔} core{코어} cardio{유산소} upper{상체} lower{하체} other{부위}}'**
  String queryPart(String part);

  /// 표의 배수 칸 머리
  ///
  /// In ko, this message translates to:
  /// **'배수'**
  String get queryRatioColumn;

  /// 각주: 단위가 달라 비율 못 냄
  ///
  /// In ko, this message translates to:
  /// **'단위가 달라 비율을 못 내요'**
  String get queryRatioUnits;

  /// 범위: 쉰 날(운동 안 한 날)
  ///
  /// In ko, this message translates to:
  /// **'쉰 날'**
  String get queryRestDay;

  /// 범위: 운동한 날
  ///
  /// In ko, this message translates to:
  /// **'운동한 날'**
  String get queryTrained;

  /// 범위: 첫 세트만
  ///
  /// In ko, this message translates to:
  /// **'첫 세트'**
  String get querySetFirst;

  /// 범위: 마지막 세트만
  ///
  /// In ko, this message translates to:
  /// **'마지막 세트'**
  String get querySetLast;

  /// 비중(합 대비 %)
  ///
  /// In ko, this message translates to:
  /// **'비중'**
  String get queryShare;

  /// 각주: 제일 적게 한 순위에 안 한 운동을 0 으로
  ///
  /// In ko, this message translates to:
  /// **'안 한 운동도 0 으로 넣었어요'**
  String get queryZeroFilled;

  /// 확인 줄: 질문의 기준 수
  ///
  /// In ko, this message translates to:
  /// **'기준 {value}'**
  String queryAgainst(String value);

  /// 기준 수와 견준 줄
  ///
  /// In ko, this message translates to:
  /// **'{value} ÷ {target} = {ratio}배 · 차이 {diff}'**
  String queryAgainstLine(
    String value,
    String target,
    String ratio,
    String diff,
  );

  /// 확인 줄: 한 운동으로 합친 기록 이름들
  ///
  /// In ko, this message translates to:
  /// **'{name} = {names}'**
  String queryAlias(String name, String names);

  /// 날 수
  ///
  /// In ko, this message translates to:
  /// **'{n}일'**
  String queryDayCount(int n);

  /// 칸: 값의 종류가 달라 뺀 세트
  ///
  /// In ko, this message translates to:
  /// **'값이 다른 세트 {n}개 제외'**
  String queryDroppedSets(int n);

  /// 범위: 시간대
  ///
  /// In ko, this message translates to:
  /// **'{from}–{to}시'**
  String queryHours(int from, int to);

  /// 적은 적 없는 이름에 가까운 운동
  ///
  /// In ko, this message translates to:
  /// **'혹시 {name}?'**
  String queryMaybe(String name);

  /// 범위: 메모에 모든 낱말
  ///
  /// In ko, this message translates to:
  /// **'메모에 모두: {terms}'**
  String queryMemoAll(String terms);

  /// 걸린 메모 글과 그 날 수
  ///
  /// In ko, this message translates to:
  /// **'{text} {n}일'**
  String queryMemoHit(String text, int n);

  /// 확인 줄: 메모 조건에 실제로 걸린 메모들
  ///
  /// In ko, this message translates to:
  /// **'걸린 메모: {hits}'**
  String queryMemoHits(String hits);

  /// 여러 이름 중 일부만 기록이 없을 때
  ///
  /// In ko, this message translates to:
  /// **'{names}: 적은 기록이 없어 빼고 셌어요'**
  String queryNeverPartial(String names);

  /// 기록이 없는 운동 줄
  ///
  /// In ko, this message translates to:
  /// **'{names}: 적은 기록이 없어요'**
  String queryNeverRows(String names);

  /// 범위: 메모에 이 낱말이 없는 날
  ///
  /// In ko, this message translates to:
  /// **'메모 없음: {terms}'**
  String queryNoMemo(String terms);

  /// 칸: 반복을 안 적어 뺀 세트
  ///
  /// In ko, this message translates to:
  /// **'반복을 안 적은 세트 {n}개 제외'**
  String queryNoRepsSets(int n);

  /// 카드 위: 기록에 없어 못 본 것
  ///
  /// In ko, this message translates to:
  /// **'기록에 없어 못 본 것: {things}'**
  String queryNotComputable(String things);

  /// 확인 줄 끝: 못 보는 것
  ///
  /// In ko, this message translates to:
  /// **'못 보는 것: {things}'**
  String queryNotComputableTail(String things);

  /// 셀 것이 하나도 없는 질문
  ///
  /// In ko, this message translates to:
  /// **'기록으로 답할 수 없어요: {things}'**
  String queryNothingComputable(String things);

  /// 칸: 무게 없는 세트를 빼고 셈
  ///
  /// In ko, this message translates to:
  /// **'무게 없는 세트 {n}개 제외 (최다 {reps}회)'**
  String queryNoWeightSets(int n, int reps);

  /// 범위: 끝에서 N번째 운동일
  ///
  /// In ko, this message translates to:
  /// **'끝에서 {n}번째 운동일'**
  String queryNth(int n);

  /// 칸: 시간 칸에서 뺀 거리 세트의 합
  ///
  /// In ko, this message translates to:
  /// **'거리를 적은 {n}번: {value}'**
  String queryOtherDistance(int n, String value);

  /// 칸: 거리 칸에서 뺀 시간 세트의 합
  ///
  /// In ko, this message translates to:
  /// **'시간을 적은 {n}번: {value}'**
  String queryOtherDuration(int n, String value);

  /// 칸: 값이 빠져 합에서 뺀 운동(부분 합계)
  ///
  /// In ko, this message translates to:
  /// **'{names} 제외'**
  String queryPartial(String names);

  /// 모자란 마지막 구간의 날 수
  ///
  /// In ko, this message translates to:
  /// **'({n}일)'**
  String queryPartialChunk(int n);

  /// 확인 줄: 부위와 거기 든 기록한 운동
  ///
  /// In ko, this message translates to:
  /// **'{part}: {names}'**
  String queryPartMembers(String part, String names);

  /// 확인 줄: 날당·주당·달당 평균
  ///
  /// In ko, this message translates to:
  /// **'{per, select, day{하루 평균} week{주당} month{달당} other{평균}}'**
  String queryPer(String per);

  /// 숫자 뒤: /일 /주 /달
  ///
  /// In ko, this message translates to:
  /// **'{per, select, day{/일} week{/주} month{/달} other{/}}'**
  String queryPerSuffix(String per);

  /// 확인 줄: 무엇을 무엇으로 나누는지
  ///
  /// In ko, this message translates to:
  /// **'{a} ÷ {b}'**
  String queryRatioHead(String a, String b);

  /// 비율 줄: a ÷ b(기준)
  ///
  /// In ko, this message translates to:
  /// **'{a} ÷ {b} = {value}배 ({percent}%)'**
  String queryRatioLine(String a, String b, String value, String percent);

  /// 창이 다른 series 의 상대 구간 줄 이름
  ///
  /// In ko, this message translates to:
  /// **'{by, select, day{{n}번째 날} week{{n}번째 주} month{{n}번째 달} other{{n}번째}}'**
  String queryRelative(String by, int n);

  /// 확인 줄: 앞날 기간을 작년으로 읽음
  ///
  /// In ko, this message translates to:
  /// **'아직 오지 않은 기간이라 {year}년으로 읽었어요'**
  String queryRolled(String year);

  /// 진행 중인 창과 같은 날 수로 자른 비교
  ///
  /// In ko, this message translates to:
  /// **'같은 {days}일로 견주면: {earlier} → {later}'**
  String querySamePeriod(int days, String earlier, String later);

  /// 각주: 기록이 짧아 성장 순위에서 뺌
  ///
  /// In ko, this message translates to:
  /// **'기록이 짧아(3일·3주 미만) 순위에서 뺐어요: {names}'**
  String queryShortGrowth(String names);

  /// 범위: 타이머
  ///
  /// In ko, this message translates to:
  /// **'{kind, select, tabata{타바타} bpm{bpm 타이머} other{타이머 없이}}'**
  String queryTimer(String kind);

  /// 각주: 부위를 모르는 운동
  ///
  /// In ko, this message translates to:
  /// **'부위를 모르는 운동은 뺐어요: {names}'**
  String queryUnknownPart(String names);

  /// 값이 빠져 순위에 못 넣은 줄
  ///
  /// In ko, this message translates to:
  /// **'값이 빠져 순위에 못 넣은 {n}개: {names}'**
  String queryUnranked(int n, String names);

  /// 각주: 길이가 다른 기간은 주당으로 견줌
  ///
  /// In ko, this message translates to:
  /// **'기간의 날 수가 달라요({lengths}일) — 차이·비율은 주당으로 셌어요'**
  String queryWindowLengths(String lengths);

  /// 개수형 주·달 묶음에서 0 인 구간 수
  ///
  /// In ko, this message translates to:
  /// **'{by, select, week{{total}주 중 {zeros}주는 0} month{{total}달 중 {zeros}달은 0} other{{total}개 중 {zeros}개는 0}}'**
  String queryZeroBuckets(String by, int total, int zeros);

  /// 운동일수 작은 줄: 가능한 날 중 %
  ///
  /// In ko, this message translates to:
  /// **'가능한 {m}일 중 {percent}%'**
  String queryPossibleDays(int m, String percent);

  /// 서버에 닿지 못해 글에 적힌 운동·기간·의도 낱말로 기기에서 센 답 위에 붙는 줄.
  ///
  /// In ko, this message translates to:
  /// **'서버에 닿지 못해 글에 적힌 운동·기간으로만 기기에서 셌어요. 연결되면 Enter 로 다시 물어보세요.'**
  String get queryOfflineLocal;

  /// 서버는 답했는데 앱이 그 답을 셀 수 있는 plan 으로 읽지 못했다(모양 실수). 연결 문제가 아니다 — 같은 질문은 담아 두어 원판을 다시 쓰지 않는다.
  ///
  /// In ko, this message translates to:
  /// **'이 질문은 셀 수 있는 모양으로 읽지 못했어요. 말을 바꿔 물어봐 주세요.'**
  String get queryMisread;

  /// 모델 답을 읽지 못해 글에 적힌 운동·기간으로 기기에서 센 답 위에 붙는 줄.
  ///
  /// In ko, this message translates to:
  /// **'질문을 셀 수 있는 모양으로 읽지 못해 글에 적힌 운동·기간으로만 기기에서 셌어요. 말을 바꿔 물으면 다시 읽어요.'**
  String get queryMisreadLocal;

  /// 서버가 모델에 두 번 물었는데 두 번 다 읽을 수 없는 답(빈 답·깨진 JSON)이었다(error unreadable). 원판은 돌려줬고 연결 문제가 아니다 — 담지 않으니 다시 물을 수 있다.
  ///
  /// In ko, this message translates to:
  /// **'모델이 읽을 수 없는 답을 두 번 보냈어요. 연결 문제가 아니고, 그 답에는 원판이 나가지 않았어요.'**
  String get queryUnreadable;

  /// 읽을 수 없는 답 뒤에 같은 질문을 다시 묻는 단추.
  ///
  /// In ko, this message translates to:
  /// **'다시 묻기'**
  String get queryAskAgain;

  /// queryUnreadable 과 같은데 이 질문의 1단계(갈래 고르기)에는 원판이 나갔다. 그 값은 아래 원판 줄(platesSpent)이 보인다.
  ///
  /// In ko, this message translates to:
  /// **'모델이 읽을 수 없는 답을 두 번 보냈어요. 연결 문제가 아니에요. 그 답에는 원판이 나가지 않았고, 아래 원판은 질문을 가른 첫 단계에 쓴 거예요.'**
  String get queryUnreadablePaid;

  /// 읽을 수 없는 답 문구 뒤에 붙는다: 글에 적힌 운동이 있어 그동안 기기에서 센 답을 보인다.
  ///
  /// In ko, this message translates to:
  /// **'그동안 글에 적힌 운동·기간으로는 기기에서 셌어요.'**
  String get queryUnreadableLocal;

  /// 합계 줄: 줄마다 단위가 달라(맞출 수 없어) 더하지 못했다.
  ///
  /// In ko, this message translates to:
  /// **'단위가 달라 합계를 못 내요'**
  String get queryTotalUnits;

  /// 확인 줄: 모델이 낸 메모 조건을 규칙이 뺐다.
  ///
  /// In ko, this message translates to:
  /// **'메모 조건 뺌: {words}'**
  String queryMemoDropped(String words);

  /// 확인 줄: 모델이 낸 기준 수가 질문에 무게로 적힌 수가 아니라 뺐다.
  ///
  /// In ko, this message translates to:
  /// **'기준 수 {value} 뺌 — 질문에 무게로 적힌 수가 아니에요'**
  String queryAgainstDropped(String value);

  /// No description provided for @routineDate.
  ///
  /// In ko, this message translates to:
  /// **'{d}'**
  String routineDate(DateTime d);

  /// No description provided for @routineHeaderToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 루틴'**
  String get routineHeaderToday;

  /// No description provided for @routineHeaderDay.
  ///
  /// In ko, this message translates to:
  /// **'{day} 루틴'**
  String routineHeaderDay(String day);

  /// No description provided for @routineTomorrow.
  ///
  /// In ko, this message translates to:
  /// **'내일({date})'**
  String routineTomorrow(String date);

  /// No description provided for @routineWhyRotation.
  ///
  /// In ko, this message translates to:
  /// **'{date} 운동을 {days}일 동안 안 했어요 — 그날처럼 짰어요'**
  String routineWhyRotation(String date, int days);

  /// No description provided for @routineWhyFrom.
  ///
  /// In ko, this message translates to:
  /// **'{date} 그대로 짰어요'**
  String routineWhyFrom(String date);

  /// No description provided for @routineWhyNamed.
  ///
  /// In ko, this message translates to:
  /// **'{date}에 같이 하던 운동으로 채웠어요'**
  String routineWhyNamed(String date);

  /// No description provided for @routinePartRest.
  ///
  /// In ko, this message translates to:
  /// **'최근 28일: {list} 전'**
  String routinePartRest(String list);

  /// No description provided for @routinePartDays.
  ///
  /// In ko, this message translates to:
  /// **'{part} {days}일'**
  String routinePartDays(String part, int days);

  /// No description provided for @routineEstimate.
  ///
  /// In ko, this message translates to:
  /// **'약 {minutes}분'**
  String routineEstimate(int minutes);

  /// No description provided for @routinePaceOwn.
  ///
  /// In ko, this message translates to:
  /// **'최근 {sessions}번 운동의 세트당 {pace}로 어림'**
  String routinePaceOwn(int sessions, String pace);

  /// No description provided for @routinePaceDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본값 세트당 {pace}로 어림 — 운동을 몇 번 적으면 내 속도로 바뀌어요'**
  String routinePaceDefault(String pace);

  /// No description provided for @routineMinSec.
  ///
  /// In ko, this message translates to:
  /// **'{m}분 {s}초'**
  String routineMinSec(int m, int s);

  /// No description provided for @routineReadAs.
  ///
  /// In ko, this message translates to:
  /// **'이렇게 읽었어요: {list}'**
  String routineReadAs(String list);

  /// No description provided for @routineCopied.
  ///
  /// In ko, this message translates to:
  /// **'{date} 그대로'**
  String routineCopied(String date);

  /// No description provided for @routineRepsMatched.
  ///
  /// In ko, this message translates to:
  /// **'{date}에 {reps}회 한 무게'**
  String routineRepsMatched(String date, int reps);

  /// No description provided for @routineTyped.
  ///
  /// In ko, this message translates to:
  /// **'적은 대로'**
  String get routineTyped;

  /// No description provided for @routineFirst.
  ///
  /// In ko, this message translates to:
  /// **'처음'**
  String get routineFirst;

  /// No description provided for @routineBlank.
  ///
  /// In ko, this message translates to:
  /// **'{why, select, light{가볍게라 무게는 비웠어요} pain{아픈 곳이 있어 무게는 비웠어요} gear{기구가 달라 무게는 비웠어요} bodyweight{기구 무게라 비웠어요} stale{오래돼서 무게는 비웠어요} repsUnmatched{그 횟수로 그만큼 한 날이 없어 무게는 비웠어요} other{무게는 비웠어요}}'**
  String routineBlank(String why);

  /// No description provided for @routineReference.
  ///
  /// In ko, this message translates to:
  /// **'참고: {sets} ({date})'**
  String routineReference(String sets, String date);

  /// No description provided for @routineBest.
  ///
  /// In ko, this message translates to:
  /// **'참고: 최고 {set} ({date})'**
  String routineBest(String set, String date);

  /// No description provided for @routineStepped.
  ///
  /// In ko, this message translates to:
  /// **'+{step} ({evidence})'**
  String routineStepped(String step, String evidence);

  /// No description provided for @routineMemo.
  ///
  /// In ko, this message translates to:
  /// **'{date} 메모: {memo}'**
  String routineMemo(String date, String memo);

  /// No description provided for @routineRecent.
  ///
  /// In ko, this message translates to:
  /// **'{part} · {when}'**
  String routineRecent(String part, String when);

  /// No description provided for @routineDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n, plural, =0{오늘} =1{어제} other{{n}일 전}}'**
  String routineDaysAgo(int n);

  /// No description provided for @routineFuture.
  ///
  /// In ko, this message translates to:
  /// **'미리 보기예요 — 그날 \'루틴\'을 치면 그날 기록으로 시작할 수 있어요'**
  String get routineFuture;

  /// No description provided for @routineRefused.
  ///
  /// In ko, this message translates to:
  /// **'{kind, select, diet{식단은 짜 드리지 않아요 — 끼니를 적으면 열량은 볼 수 있어요} medical{재활·수술 뒤 운동은 판단하지 않아요 — 의사·치료사에게 받은 운동을 적으면 그대로 루틴으로 만들어요} drug{약물은 도와드리지 않아요} program{한 번에 하루치만 짜요 — 오늘 루틴이에요} logging{안 한 세트를 완료로 적지는 않아요 — 할 때 눌러 주세요} format{EMOM·슈퍼세트·서킷 타이머는 없어요 — 순서만 짰어요(타바타·bpm 은 돼요)} person{다른 사람 루틴은 짜 드리지 않아요 — 내 기록의 운동 이름만 보여요} other{운동 기록과 루틴만 도와드려요}}'**
  String routineRefused(String kind);

  /// No description provided for @routineNotStated.
  ///
  /// In ko, this message translates to:
  /// **'글에 없는 수라 뺐어요: {what}'**
  String routineNotStated(String what);

  /// No description provided for @routineUnmet.
  ///
  /// In ko, this message translates to:
  /// **'못 맞춘 조건: {what}'**
  String routineUnmet(String what);

  /// No description provided for @routineKeyName.
  ///
  /// In ko, this message translates to:
  /// **'{key, select, when{날짜} from{지난 날} parts{부위} pattern{밀기·당기기} exercises{운동} exclude{뺄 운동} avoid{피할 부위} pain{아픈 곳} equipment{기구} count{운동 수} minutes{시간} intensity{세기} timer{타이머} targets{적은 수} delta{증감} other{조건}}'**
  String routineKeyName(String key);

  /// No description provided for @routineUnknownName.
  ///
  /// In ko, this message translates to:
  /// **'사전에 없어 뺐어요: {name}'**
  String routineUnknownName(String name);

  /// No description provided for @routineNoSuchDay.
  ///
  /// In ko, this message translates to:
  /// **'그런 날이 없어요 — 기록으로 짰어요'**
  String get routineNoSuchDay;

  /// No description provided for @routineExcludeAbsent.
  ///
  /// In ko, this message translates to:
  /// **'뺄 운동이 원래 없어요: {name}'**
  String routineExcludeAbsent(String name);

  /// No description provided for @routineNoneMatched.
  ///
  /// In ko, this message translates to:
  /// **'기록한 {what} 운동이 없어요 — 골라 넣을 수 있어요'**
  String routineNoneMatched(String what);

  /// No description provided for @routineFewer.
  ///
  /// In ko, this message translates to:
  /// **'기록으로 넣을 운동이 {n}개예요'**
  String routineFewer(int n);

  /// No description provided for @routineOtherUnit.
  ///
  /// In ko, this message translates to:
  /// **'{unit}로 적은 세트는 그대로 뒀어요'**
  String routineOtherUnit(String unit);

  /// No description provided for @routineBpmRange.
  ///
  /// In ko, this message translates to:
  /// **'bpm 은 10–120 이에요 — 타이머 없이 넣었어요'**
  String get routineBpmRange;

  /// No description provided for @routineIntensityLine.
  ///
  /// In ko, this message translates to:
  /// **'{kind, select, light{가볍게: 칸마다 마지막 세트 하나를 뺐어요 — 무게는 지난번 그대로예요} lightBlank{가볍게: 칸마다 마지막 세트 하나를 뺐어요} hard{무게는 지난번 그대로예요} max{몇 kg 에 도전할지는 정하지 않아요 — 최고 기록을 옆에 적었어요} other{}}'**
  String routineIntensityLine(String kind);

  /// No description provided for @routineNoStep.
  ///
  /// In ko, this message translates to:
  /// **'올릴 만큼 적어 주세요(예: +2.5kg)'**
  String get routineNoStep;

  /// No description provided for @routinePain.
  ///
  /// In ko, this message translates to:
  /// **'\'{phrase}\' 때문에 뺀 것: {list} · 무게는 비웠어요 · 괜찮은지는 판단하지 않아요'**
  String routinePain(String phrase, String list);

  /// No description provided for @routinePainNone.
  ///
  /// In ko, this message translates to:
  /// **'\'{phrase}\' — 뺀 운동은 없고 무게는 비웠어요 · 괜찮은지는 판단하지 않아요'**
  String routinePainNone(String phrase);

  /// No description provided for @routinePainWord.
  ///
  /// In ko, this message translates to:
  /// **'아프다는 말'**
  String get routinePainWord;

  /// No description provided for @routineFirstTime.
  ///
  /// In ko, this message translates to:
  /// **'처음이에요 — 넣을 운동을 고르면 숫자 없이 들어가요'**
  String get routineFirstTime;

  /// No description provided for @routineCountFit.
  ///
  /// In ko, this message translates to:
  /// **'{count}개로 맞췄어요 — 약 {minutes}분'**
  String routineCountFit(int count, int minutes);

  /// No description provided for @routineNoMore.
  ///
  /// In ko, this message translates to:
  /// **'기록으로 더 넣을 운동이 없어요 — 약 {minutes}분이에요'**
  String routineNoMore(int minutes);

  /// No description provided for @routineOverTime.
  ///
  /// In ko, this message translates to:
  /// **'말한 운동만으로 약 {minutes}분이에요'**
  String routineOverTime(int minutes);

  /// No description provided for @routineOverUsual.
  ///
  /// In ko, this message translates to:
  /// **'고른 운동 {n}개를 모두 넣었어요 — 평소 한 번에 하는 {usual}개보다 많아요'**
  String routineOverUsual(int n, int usual);

  /// No description provided for @routineRecentMemo.
  ///
  /// In ko, this message translates to:
  /// **'{when} {name} 메모: {memo}'**
  String routineRecentMemo(String when, String name, String memo);

  /// No description provided for @routineRemoved.
  ///
  /// In ko, this message translates to:
  /// **'뺀 것: {label} — {why}'**
  String routineRemoved(String label, String why);

  /// No description provided for @routineRemovedWhy.
  ///
  /// In ko, this message translates to:
  /// **'{why, select, named{말한 운동} avoid{피할 부위} unknownPart{부위를 몰라서} gear{기구가 달라서} unknownGear{기구를 몰라서} otherPart{다른 부위라서} user{직접 뺌} other{}}'**
  String routineRemovedWhy(String why);

  /// No description provided for @routineRestore.
  ///
  /// In ko, this message translates to:
  /// **'넣기'**
  String get routineRestore;

  /// No description provided for @routineAdd.
  ///
  /// In ko, this message translates to:
  /// **'+ {name}'**
  String routineAdd(String name);

  /// No description provided for @routineOther.
  ///
  /// In ko, this message translates to:
  /// **'다른 루틴'**
  String get routineOther;

  /// No description provided for @routinePrevious.
  ///
  /// In ko, this message translates to:
  /// **'그 전({date})'**
  String routinePrevious(String date);

  /// No description provided for @routineByPart.
  ///
  /// In ko, this message translates to:
  /// **'{part} 루틴으로 짜기'**
  String routineByPart(String part);

  /// No description provided for @routineStepChip.
  ///
  /// In ko, this message translates to:
  /// **'+{step} 올리기(스스로 올려 온 폭)'**
  String routineStepChip(String step);

  /// No description provided for @routineAskToo.
  ///
  /// In ko, this message translates to:
  /// **'이것도 물을까요: {text} · 원판'**
  String routineAskToo(String text);

  /// No description provided for @routineAsQuestion.
  ///
  /// In ko, this message translates to:
  /// **'기록 질문으로 묻기 · 원판'**
  String get routineAsQuestion;

  /// No description provided for @routineNoConditions.
  ///
  /// In ko, this message translates to:
  /// **'조건 없이 바로 짜기'**
  String get routineNoConditions;

  /// No description provided for @routineWithConditions.
  ///
  /// In ko, this message translates to:
  /// **'조건까지 읽어 짜기 · 원판'**
  String get routineWithConditions;

  /// No description provided for @routineMake.
  ///
  /// In ko, this message translates to:
  /// **'오늘 루틴 만들기'**
  String get routineMake;

  /// No description provided for @routineMakePart.
  ///
  /// In ko, this message translates to:
  /// **'오늘 {part} 루틴 만들기'**
  String routineMakePart(String part);

  /// No description provided for @routineStart.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get routineStart;

  /// No description provided for @routineStarted.
  ///
  /// In ko, this message translates to:
  /// **'시작함 · 열기'**
  String get routineStarted;

  /// No description provided for @routineWorking.
  ///
  /// In ko, this message translates to:
  /// **'조건을 읽는 중…'**
  String get routineWorking;

  /// No description provided for @routineOffline.
  ///
  /// In ko, this message translates to:
  /// **'조건은 연결이 안 돼 못 읽었어요 — 기록으로만 짰어요'**
  String get routineOffline;

  /// No description provided for @routineMisread.
  ///
  /// In ko, this message translates to:
  /// **'조건을 읽지 못했어요 — 기록으로만 짰어요. 말을 바꾸면 다시 읽어요'**
  String get routineMisread;

  /// No description provided for @routineHeldBack.
  ///
  /// In ko, this message translates to:
  /// **'{why, select, offline{연결이 안 돼} noPlates{원판이 없어} other{모델 답을 읽지 못해}} 조건(빼기·아픈 곳)을 못 읽었어요 — 루틴을 만들지 않았어요'**
  String routineHeldBack(String why);

  /// No description provided for @routineTypedWeight.
  ///
  /// In ko, this message translates to:
  /// **'적은 무게로: 작업 세트 {count}개 {from} → {to}'**
  String routineTypedWeight(int count, String from, String to);

  /// No description provided for @routineTypedKept.
  ///
  /// In ko, this message translates to:
  /// **'적은 무게는 그대로 뒀어요'**
  String get routineTypedKept;

  /// No description provided for @routinePlatesBefore.
  ///
  /// In ko, this message translates to:
  /// **'이 글에 앞서 원판을 썼어요 · 이번엔 0장'**
  String get routinePlatesBefore;

  /// No description provided for @routineRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get routineRetry;

  /// No description provided for @routinePressEnter.
  ///
  /// In ko, this message translates to:
  /// **'Enter 를 누르면 조건까지 읽어 짜요 · 원판'**
  String get routinePressEnter;

  /// No description provided for @routineFromQuestion.
  ///
  /// In ko, this message translates to:
  /// **'루틴을 짜 달라는 말로 읽었어요'**
  String get routineFromQuestion;

  /// No description provided for @routinePattern.
  ///
  /// In ko, this message translates to:
  /// **'{p, select, push{밀기} pull{당기기} other{}}'**
  String routinePattern(String p);

  /// No description provided for @routineGear.
  ///
  /// In ko, this message translates to:
  /// **'{g, select, barbell{바벨} dumbbell{덤벨} machine{머신} cable{케이블} bodyweight{맨몸} bar{철봉} kettlebell{케틀벨} band{밴드} bench{벤치} other{기구}}'**
  String routineGear(String g);

  /// No description provided for @routineGearOnly.
  ///
  /// In ko, this message translates to:
  /// **'{list}만'**
  String routineGearOnly(String list);

  /// No description provided for @routineGearWithout.
  ///
  /// In ko, this message translates to:
  /// **'{list} 없이'**
  String routineGearWithout(String list);

  /// No description provided for @routineMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{n}분'**
  String routineMinutes(int n);

  /// No description provided for @routineCount.
  ///
  /// In ko, this message translates to:
  /// **'운동 {n}개'**
  String routineCount(int n);

  /// No description provided for @routineIntensity.
  ///
  /// In ko, this message translates to:
  /// **'{k, select, light{가볍게} hard{무겁게} max{최고 도전} other{}}'**
  String routineIntensity(String k);

  /// No description provided for @routineExclude.
  ///
  /// In ko, this message translates to:
  /// **'뺄 것: {list}'**
  String routineExclude(String list);

  /// No description provided for @routineAvoid.
  ///
  /// In ko, this message translates to:
  /// **'피할 부위: {list}'**
  String routineAvoid(String list);

  /// No description provided for @routinePlatesZero.
  ///
  /// In ko, this message translates to:
  /// **'원판 0장'**
  String get routinePlatesZero;

  /// No description provided for @routineFullBody.
  ///
  /// In ko, this message translates to:
  /// **'전신'**
  String get routineFullBody;

  /// No description provided for @routineNoPlates.
  ///
  /// In ko, this message translates to:
  /// **'조건은 원판이 없어 못 읽었어요 — 기록으로만 짰어요'**
  String get routineNoPlates;

  /// No description provided for @routineBack.
  ///
  /// In ko, this message translates to:
  /// **'루틴으로 돌아가기'**
  String get routineBack;

  /// 확인 줄: 모델이 낸 무게·횟수 조건의 수가 질문에 그 단위로 적힌 수가 아니라 뺐다.
  ///
  /// In ko, this message translates to:
  /// **'숫자 조건 {value} 뺌 — 질문에 그 단위로 적힌 수가 아니에요'**
  String queryBoundDropped(String value);

  /// No description provided for @anatomyTitle.
  ///
  /// In ko, this message translates to:
  /// **'몸 그림'**
  String get anatomyTitle;

  /// No description provided for @anatomyOpen.
  ///
  /// In ko, this message translates to:
  /// **'몸 그림 — 부위별 운동과 자세 팁'**
  String get anatomyOpen;

  /// No description provided for @anatomyPick.
  ///
  /// In ko, this message translates to:
  /// **'몸 그림에서 운동 고르기'**
  String get anatomyPick;

  /// No description provided for @anatomyFront.
  ///
  /// In ko, this message translates to:
  /// **'앞'**
  String get anatomyFront;

  /// No description provided for @anatomyBack.
  ///
  /// In ko, this message translates to:
  /// **'뒤'**
  String get anatomyBack;

  /// No description provided for @anatomyDays.
  ///
  /// In ko, this message translates to:
  /// **'{n}일'**
  String anatomyDays(int n);

  /// No description provided for @muscleName.
  ///
  /// In ko, this message translates to:
  /// **'{m, select, chest{가슴} frontDelts{앞 어깨} sideDelts{옆 어깨} rearDelts{뒤 어깨} traps{승모근 윗부분} upperBack{등 가운데} lats{광배근} lowerBack{허리} biceps{이두} triceps{삼두} forearms{전완} abs{복근} obliques{옆구리} hipFlexors{고관절 굴곡근} glutes{엉덩이} quads{허벅지 앞} hamstrings{허벅지 뒤} adductors{허벅지 안쪽} calves{종아리} other{부위}}'**
  String muscleName(String m);

  /// No description provided for @anatomyLevel.
  ///
  /// In ko, this message translates to:
  /// **'{level, select, low{적음} mid{중간} high{많음} other{없음}}'**
  String anatomyLevel(String level);

  /// No description provided for @anatomyLegend.
  ///
  /// In ko, this message translates to:
  /// **'이 기간에 세트가 많은 부위일수록 진해요'**
  String get anatomyLegend;

  /// No description provided for @anatomyFirstTime.
  ///
  /// In ko, this message translates to:
  /// **'아직 해낸 세트가 없어 색이 없어요. 부위를 누르면 그 부위를 쓰는 운동과 자세 팁을 볼 수 있어요.'**
  String get anatomyFirstTime;

  /// No description provided for @anatomyEmptyWindow.
  ///
  /// In ko, this message translates to:
  /// **'최근 {n}일에 해낸 세트가 없어요'**
  String anatomyEmptyWindow(int n);

  /// No description provided for @anatomyUnknown.
  ///
  /// In ko, this message translates to:
  /// **'근육을 모르는 운동 {n}개는 세지 않았어요. 이름을 누르면 검색에서 그 기록을 봐요.'**
  String anatomyUnknown(int n);

  /// No description provided for @anatomyUnknownMore.
  ///
  /// In ko, this message translates to:
  /// **'외 {n}개'**
  String anatomyUnknownMore(int n);

  /// No description provided for @anatomyCardio.
  ///
  /// In ko, this message translates to:
  /// **'유산소 {n}세트는 근육 그림에 넣지 않았어요'**
  String anatomyCardio(int n);

  /// No description provided for @anatomyCountNote.
  ///
  /// In ko, this message translates to:
  /// **'근육은 ExRx.net·ACE 분류를 따른 어림이에요. * 가 붙은 운동은 근육 배정이 해석이에요. 주로 쓰는 근육은 한 세트, 보조로 쓰는 근육은 반 세트로 세고, 워밍업 세트도 한 세트로 셉니다.'**
  String get anatomyCountNote;

  /// No description provided for @anatomyLimits.
  ///
  /// In ko, this message translates to:
  /// **'영상·자세 분석은 하지 않아요. 통증이 있으면 멈추고 전문가와 상의하세요.'**
  String get anatomyLimits;

  /// No description provided for @anatomyTapHint.
  ///
  /// In ko, this message translates to:
  /// **'근육을 눌러 주세요 — 아래 목록에서도 고를 수 있어요'**
  String get anatomyTapHint;

  /// No description provided for @anatomyNoSurface.
  ///
  /// In ko, this message translates to:
  /// **'몸 안쪽 근육이라 그림에는 없어요'**
  String get anatomyNoSurface;

  /// No description provided for @anatomySets.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 {sets}세트'**
  String anatomySets(int days, String sets);

  /// No description provided for @anatomySetsLine.
  ///
  /// In ko, this message translates to:
  /// **'최근 7일 {week}세트 · 28일 {month}세트'**
  String anatomySetsLine(String week, String month);

  /// No description provided for @anatomyBreakdown.
  ///
  /// In ko, this message translates to:
  /// **'28일 중 주로 쓴 세트 {primary} · 보조로 쓴 세트 {secondary}(반으로 셈)'**
  String anatomyBreakdown(int primary, int secondary);

  /// No description provided for @anatomyLast.
  ///
  /// In ko, this message translates to:
  /// **'마지막: {date}({ago})'**
  String anatomyLast(String date, String ago);

  /// No description provided for @anatomyNever.
  ///
  /// In ko, this message translates to:
  /// **'표에 있는 운동으로는 이 부위를 쓴 기록이 아직 없어요'**
  String get anatomyNever;

  /// No description provided for @anatomyDone.
  ///
  /// In ko, this message translates to:
  /// **'내가 한 운동'**
  String get anatomyDone;

  /// No description provided for @anatomyTry.
  ///
  /// In ko, this message translates to:
  /// **'이 부위를 주로 쓰는 운동'**
  String get anatomyTry;

  /// No description provided for @anatomyTryGear.
  ///
  /// In ko, this message translates to:
  /// **'쓴 적 있는 기구({list})로 할 수 있는 것'**
  String anatomyTryGear(String list);

  /// No description provided for @anatomyAllGear.
  ///
  /// In ko, this message translates to:
  /// **'기구 기록이 없어 전부 보여요'**
  String get anatomyAllGear;

  /// No description provided for @anatomyMoreGear.
  ///
  /// In ko, this message translates to:
  /// **'다른 기구 운동 {n}개 더 보기'**
  String anatomyMoreGear(int n);

  /// No description provided for @anatomyTriedAll.
  ///
  /// In ko, this message translates to:
  /// **'이 부위를 주로 쓰는 운동은 다 해 봤어요'**
  String get anatomyTriedAll;

  /// No description provided for @anatomyRole.
  ///
  /// In ko, this message translates to:
  /// **'{role, select, primary{주로 씀} other{보조}}'**
  String anatomyRole(String role);

  /// No description provided for @anatomyInterpNote.
  ///
  /// In ko, this message translates to:
  /// **'* 가 붙은 운동은 근육 배정이 출처를 옮긴 해석이에요'**
  String get anatomyInterpNote;

  /// No description provided for @anatomyCues.
  ///
  /// In ko, this message translates to:
  /// **'자세 팁'**
  String get anatomyCues;

  /// No description provided for @anatomyMistakes.
  ///
  /// In ko, this message translates to:
  /// **'피할 것'**
  String get anatomyMistakes;

  /// No description provided for @anatomySources.
  ///
  /// In ko, this message translates to:
  /// **'출처: {sites}'**
  String anatomySources(String sites);

  /// No description provided for @anatomyUnsourced.
  ///
  /// In ko, this message translates to:
  /// **'‡ 출처 없이 덧붙인 말'**
  String get anatomyUnsourced;

  /// No description provided for @anatomyAdapted.
  ///
  /// In ko, this message translates to:
  /// **'† 출처 문장을 옮겨 쓴 해석(비슷한 동작의 출처 포함)'**
  String get anatomyAdapted;

  /// No description provided for @anatomyCuesEnglish.
  ///
  /// In ko, this message translates to:
  /// **'자세 팁은 아직 영어로만 있어요'**
  String get anatomyCuesEnglish;

  /// No description provided for @anatomyAddRoutine.
  ///
  /// In ko, this message translates to:
  /// **'오늘 루틴에 넣기'**
  String get anatomyAddRoutine;

  /// No description provided for @anatomyRoutineText.
  ///
  /// In ko, this message translates to:
  /// **'오늘 {part} 루틴'**
  String anatomyRoutineText(String part);

  /// No description provided for @anatomySearch.
  ///
  /// In ko, this message translates to:
  /// **'검색에서 보기'**
  String get anatomySearch;

  /// No description provided for @anatomyRegionValue.
  ///
  /// In ko, this message translates to:
  /// **'최근 {days}일 {sets}세트, {level}'**
  String anatomyRegionValue(int days, String sets, String level);

  /// No description provided for @anatomyRegionHint.
  ///
  /// In ko, this message translates to:
  /// **'두 번 눌러 운동 보기'**
  String get anatomyRegionHint;

  /// No description provided for @anatomyClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get anatomyClose;

  /// No description provided for @openSourceLicenses.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get openSourceLicenses;

  /// 체력 요인 이름(repstack FF01–FF05)
  ///
  /// In ko, this message translates to:
  /// **'{f, select, strength{근력} endurance{근지구력} sustain{지속력} power{순발력} cardio{심폐} other{}}'**
  String routineFactor(String f);

  /// 카드 머리 아래: 원천 날의 요인과 근거(3×10 …)
  ///
  /// In ko, this message translates to:
  /// **'{factor} 날 · {why}'**
  String routineFactorDay(String factor, String why);

  /// 요인을 가른 근거. a·b 는 수나 원문 조각
  ///
  /// In ko, this message translates to:
  /// **'{kind, select, tabata{타바타 {a}} fill{채우기 {a}개} fillTitle{제목 ‘{a}’} distance{{a}} open{{a}회씩, 세트 수 열어 둠} single{한 세트 {a}회} drop{세트마다 최대 {a}} hold{{a}회×{b}세트} other{{a}×{b}}}'**
  String routineFactorWhy(String kind, String a, String b);

  /// No description provided for @routineWhyWeekday.
  ///
  /// In ko, this message translates to:
  /// **'{weeks, plural, =1{지난주 {day}({date}) 운동 그대로예요} other{지난주 {day}엔 기록이 없어 {weeks}주 전 {day}({date})로 짰어요}}'**
  String routineWhyWeekday(int weeks, String day, String date);

  /// No description provided for @routineWhyNear.
  ///
  /// In ko, this message translates to:
  /// **'{day} 기록이 없어 가까운 {near}로 짰어요'**
  String routineWhyNear(String day, String near);

  /// No description provided for @routineWhyFactor.
  ///
  /// In ko, this message translates to:
  /// **'{f, select, strength{이번 주 근력이 부족해서 {date}로 짰어요} endurance{이번 주 근지구력이 부족해서 {date}로 짰어요} sustain{이번 주 지속력이 부족해서 {date}로 짰어요} cardio{이번 주 심폐가 부족해서 {date}로 짰어요} other{{date}로 짰어요}}'**
  String routineWhyFactor(String f, String date);

  /// No description provided for @routineWhyFactorAll.
  ///
  /// In ko, this message translates to:
  /// **'{f, select, strength{이번 주 요인은 다 채웠어요 — 다음 차례인 근력으로 {date}처럼 짰어요} endurance{이번 주 요인은 다 채웠어요 — 다음 차례인 근지구력으로 {date}처럼 짰어요} sustain{이번 주 요인은 다 채웠어요 — 다음 차례인 지속력으로 {date}처럼 짰어요} cardio{이번 주 요인은 다 채웠어요 — 다음 차례인 심폐로 {date}처럼 짰어요} other{{date}처럼 짰어요}}'**
  String routineWhyFactorAll(String f, String date);

  /// No description provided for @routineWeekCounts.
  ///
  /// In ko, this message translates to:
  /// **'최근 7일({range}): {list}'**
  String routineWeekCounts(String range, String list);

  /// No description provided for @routineFactorMissing.
  ///
  /// In ko, this message translates to:
  /// **'최근 28일에 따로 한 날이 없는 요인: {list}'**
  String routineFactorMissing(String list);

  /// No description provided for @routineFillHint.
  ///
  /// In ko, this message translates to:
  /// **'채우기는 목표 수를 적어 주세요(예: 스쿼트 100개 채우기)'**
  String get routineFillHint;

  /// No description provided for @routineTabataChip.
  ///
  /// In ko, this message translates to:
  /// **'타바타로'**
  String get routineTabataChip;

  /// No description provided for @routineLikeLastWeek.
  ///
  /// In ko, this message translates to:
  /// **'지난주 {day}처럼'**
  String routineLikeLastWeek(String day);

  /// No description provided for @routineFactorChip.
  ///
  /// In ko, this message translates to:
  /// **'{f, select, strength{근력으로 짜기 · 이번 주 {n}번} endurance{근지구력으로 짜기 · 이번 주 {n}번} sustain{지속력으로 짜기 · 이번 주 {n}번} cardio{심폐로 짜기 · 이번 주 {n}번} other{}}'**
  String routineFactorChip(String f, int n);

  /// No description provided for @routineLightKept.
  ///
  /// In ko, this message translates to:
  /// **'세트를 뺄 수 없어 그대로 둔 칸(한 세트·채우기·타바타): {list}'**
  String routineLightKept(String list);

  /// 같은 요일을 건너뛴 까닭: how = alt(다른 루틴) | filtered(거른 칸뿐)
  ///
  /// In ko, this message translates to:
  /// **'{how, select, alt{다른 루틴: {weeks}주 전 {day}({date})로 짰어요} other{지난주 {day}은 거른 운동뿐이라 {weeks}주 전 {day}({date})로 짰어요}}'**
  String routineWhyWeekdaySkip(String how, int weeks, String day, String date);

  /// 같은 요일 대신 이웃 요일: how = alt | filtered
  ///
  /// In ko, this message translates to:
  /// **'{how, select, alt{다른 루틴: 가까운 {near}로 짰어요} other{{day}은 거른 운동뿐이라 가까운 {near}로 짰어요}}'**
  String routineWhyNearSkip(String how, String day, String near);

  /// 모자란 요인의 날이 없어 다른 요인 날로 짰다
  ///
  /// In ko, this message translates to:
  /// **'모자란 요인은 최근 28일에 쓸 수 있는 날이 없어 {date} {factor} 날처럼 짰어요'**
  String routineWhyFactorNoDay(String factor, String date);

  /// 요인 원천인데 그 요인 칸이 루틴에서 빠졌다
  ///
  /// In ko, this message translates to:
  /// **'{date} {factor} 날로 짰지만 {factor} 칸은 빠졌어요'**
  String routineFactorLost(String factor, String date);

  /// No description provided for @routineFactorFiltered.
  ///
  /// In ko, this message translates to:
  /// **'빼라고 한 운동을 빼면 최근 28일에 남는 날이 없는 요인: {list}'**
  String routineFactorFiltered(String list);

  /// 가볍게: 이 칸은 원천 날에서 세트 하나를 뺐다
  ///
  /// In ko, this message translates to:
  /// **'{date}에서 한 세트 뺌'**
  String routineLightDropped(String date);

  /// No description provided for @routineDoneToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 이미 한 운동이 들어 있어요: {list}'**
  String routineDoneToday(String list);
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
