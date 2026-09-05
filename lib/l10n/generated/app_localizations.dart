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

  /// 첫 화면 안내. 화살표는 그대로 둔다
  ///
  /// In ko, this message translates to:
  /// **'운동 이름을 치고 Enter → 세트를 치고 Enter → 빈 줄에서 Enter면 다음 운동'**
  String get howTo;

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
