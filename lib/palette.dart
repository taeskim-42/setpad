/// 앱이 쓰는 색.
///
/// **밝기는 앱이 정하지 않는다.** CupertinoThemeData 에 brightness 를 주지
/// 않으면 Flutter 가 시스템 설정을 따른다(theme.dart 의
/// `data.brightness ?? MediaQuery.platformBrightnessOf`). 메모 앱이 그렇게
/// 동작하고, 밤에 어두워지는 것은 iOS 설정 > 디스플레이 및 밝기 > 자동이
/// 하는 일이지 앱이 하는 일이 아니다.
///
/// 그래서 여기 있는 색은 전부 **밝기 두 벌**을 든다. 한 벌만 든 색이 하나라도
/// 섞이면 밤에 그 부분만 눈을 찌른다.
///
/// 바탕·글자·구분선은 CupertinoColors 의 시스템 색을 그대로 쓴다(메모 앱과
/// 같은 값이다). 여기 있는 것은 시스템에 대응이 없는 것들뿐이다.
library;

import 'package:flutter/cupertino.dart';

/// Warm ink for document actions, with readable contrast in either appearance.
const seal = CupertinoDynamicColor.withBrightness(
  color: Color(0xFF966300),
  darkColor: Color(0xFFE9B949),
);

/// Soft amber fill for document actions and selected suggestions.
const sealTint = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFF8F0DB),
  darkColor: Color(0xFF332B19),
);

/// 해낸 세트 줄에 깔리는 옅은 초록.
const doneTint = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFF1F7F4),
  darkColor: Color(0xFF15241D),
);

/// 키패드 바탕. iOS 키보드가 자판 뒤에 까는 그 회색 자리다.
const keypadBackground = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFE9E9ED),
  darkColor: Color(0xFF1C1C1E),
);

/// 숫자 키.
const keyFace = CupertinoDynamicColor.withBrightness(
  color: CupertinoColors.white,
  darkColor: Color(0xFF48484A),
);

/// 기능 키. 숫자 키보다 한 단계 눌러 둔다 — iOS 키보드의 얼개다.
const keyDim = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFD8D9DF),
  darkColor: Color(0xFF2C2C2E),
);

/// 키 밑에 깔리는 그림자. 어두운 바탕에서는 그림자가 보이지 않으므로 뺀다 —
/// 밝은 데서 입체로 보이던 것을 어두운 데서 억지로 흉내 내면 지저분해진다.
const keyShadow = CupertinoDynamicColor.withBrightness(
  color: Color(0x33000000),
  darkColor: Color(0x00000000),
);
