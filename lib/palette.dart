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

/// 인주색. 이 앱의 유일한 강조색이고 밝기와 무관하게 같다 —
/// 아이콘·앱스토어 자산이 이 색이라 바뀌면 앱이 달라 보인다.
const seal = Color(0xFFC3372A);

/// 인주색을 아주 옅게 깐 바탕. 강조 버튼과 고른 항목에 쓴다.
const sealTint = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFF7E9E6),
  darkColor: Color(0xFF3A2321),
);

/// 해낸 세트 줄에 깔리는 옅은 초록.
const doneTint = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFF1F7F4),
  darkColor: Color(0xFF15241D),
);

/// 키패드 바탕. iOS 키보드가 자판 뒤에 까는 그 회색 자리다.
const keypadBackground = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFD8D9DE),
  darkColor: Color(0xFF1C1C1E),
);

/// 숫자 키.
const keyFace = CupertinoDynamicColor.withBrightness(
  color: CupertinoColors.white,
  darkColor: Color(0xFF48484A),
);

/// 기능 키. 숫자 키보다 한 단계 눌러 둔다 — iOS 키보드의 얼개다.
const keyDim = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFBEC0C7),
  darkColor: Color(0xFF2C2C2E),
);

/// 키 밑에 깔리는 그림자. 어두운 바탕에서는 그림자가 보이지 않으므로 뺀다 —
/// 밝은 데서 입체로 보이던 것을 어두운 데서 억지로 흉내 내면 지저분해진다.
const keyShadow = CupertinoDynamicColor.withBrightness(
  color: Color(0x33000000),
  darkColor: Color(0x00000000),
);
