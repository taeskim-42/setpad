import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'editor.dart';
import 'l10n/generated/app_localizations.dart';

void main() => runApp(const SetpadApp());

/// 인주색 — 한국 도장의 붉은색. 강조는 이 하나뿐이고 나머지는 무채색이다.
const _seal = Color(0xFFC3372A);

class SetpadApp extends StatelessWidget {
  const SetpadApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ColorScheme.fromSeed(seedColor: _seal, brightness: Brightness.light);

    return MaterialApp(
      title: 'Setpad',
      debugShowCheckedModeBanner: false,
      // 지원 언어를 하나 더하거나 뺄 때 여기를 같이 고칠 일이 없도록
      // 생성된 목록을 그대로 쓴다. arb 파일이 곧 지원 언어 목록이다.
      supportedLocales: L.supportedLocales,
      localizationsDelegates: L.localizationsDelegates,
      // 기기는 zh-TW / zh-HK 처럼 **문자 체계 없이** 보낸다. 그대로 두면
      // 번체에 못 붙고 기본 zh(간체)로 떨어져 대만 사용자가 간체를 본다.
      // 나라 코드를 보고 문자 체계를 채운 뒤 평소 규칙에 넘긴다.
      localeListResolutionCallback: (locales, supported) =>
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
          ], supported),
      theme: ThemeData(
        colorScheme: base.copyWith(primary: _seal, surface: Colors.white),
        scaffoldBackgroundColor: const Color(0xFFE9E9EC),
        // 숫자가 줄지어 서는 화면이라 자릿수 폭이 고정된 서체가 필요하다.
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Apple SD Gothic Neo', 'Noto Sans KR', 'sans-serif'],
        useMaterial3: true,
      ),
      home: const EditorPage(),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _editor = RoutineEditorController();

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  void _copy() {
    final l = L.of(context);
    final text = _editor.asText(
      setOrdinal: l.setOrdinal,
      formatReps: l.repsCount,
    );
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(L.of(context).copied),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l.appTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          ListenableBuilder(
            listenable: _editor,
            builder: (context, _) => TextButton(
              onPressed: _editor.blocks.isEmpty ? null : _copy,
              child: Text(l.copy,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                ListenableBuilder(
                  listenable: _editor,
                  builder: (context, _) => _editor.blocks.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l.howTo,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: Colors.black.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(child: RoutineEditor(controller: _editor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
