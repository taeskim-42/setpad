import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'editor.dart';

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
    final text = _editor.asText();
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('복사했습니다'), duration: Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '오늘 운동',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          ListenableBuilder(
            listenable: _editor,
            builder: (context, _) => TextButton(
              onPressed: _editor.blocks.isEmpty ? null : _copy,
              child: const Text('복사', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: RoutineEditor(controller: _editor),
          ),
        ),
      ),
    );
  }
}
