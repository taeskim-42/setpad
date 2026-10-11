import 'package:flutter/widgets.dart';

/// 기기 언어 목록에서 앱이 쓸 언어 하나를 고른다. 화면과 알림이 같이 쓴다 — 따로
/// 고르면 화면은 번체인데 트레이너 보고 알림만 간체로 뜬다.
///
/// 기기는 zh-TW / zh-HK 처럼 **문자 체계 없이** 보낸다. 그대로 두면 번체에 못 붙고
/// 기본 zh(간체)로 떨어져 대만 사용자가 간체를 본다. 나라 코드를 보고 문자 체계를
/// 채운 뒤 평소 규칙에 넘긴다.
Locale appLocale(List<Locale>? locales, Iterable<Locale> supported) =>
    basicLocaleListResolution([
      for (final l in locales ?? const <Locale>[])
        if (l.languageCode == 'zh' && l.scriptCode == null)
          Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: const ['TW', 'HK', 'MO'].contains(l.countryCode)
                ? 'Hant'
                : 'Hans',
            countryCode: l.countryCode,
          )
        else
          l,
    ], supported);
