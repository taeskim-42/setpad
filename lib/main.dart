import 'dart:async';

import 'package:flutter/material.dart';

import 'editor.dart';
import 'l10n/generated/app_localizations.dart';
import 'health.dart';
import 'notes.dart';
import 'notes_list.dart';

void main() => runApp(const SetpadApp());

/// 인주색 — 한국 도장의 붉은색. 강조는 이 하나뿐이고 나머지는 무채색이다.
const _seal = Color(0xFFC3372A);

class SetpadApp extends StatelessWidget {
  /// [store] 는 테스트가 임시 폴더를 물릴 자리다. 비워 두면 앱 문서 디렉터리를
  /// 쓰는 것을 스스로 만든다 — 그건 플랫폼 채널이라 테스트에서는 못 쓴다.
  const SetpadApp({super.key, this.store});

  final NotesStore? store;

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
      home: _Home(store: store),
    );
  }
}

/// 앱이 켜지는 자리.
///
/// **목록이 아니라 패드로 연다.** 헬스장에서 앱을 여는 이유는 세트를 하나
/// 적으려는 것이지 지난 기록을 넘겨보려는 것이 아니다. 그래서 오늘 것이 있으면
/// 그것을, 없으면 새 기록을 곧바로 펴고, 목록은 뒤로가기 한 번 뒤에 둔다.
class _Home extends StatefulWidget {
  const _Home({this.store});

  final NotesStore? store;

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> with WidgetsBindingObserver {
  late final NotesStore _store = widget.store ?? NotesStore();
  final _health = HealthLink();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  Future<void> _boot() async {
    await _store.load();
    if (!mounted) return;
    setState(() => _ready = true);
    // 첫 프레임이 그려진 뒤에 밀어 넣어야 목록이 뒤에 남는다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _open(_todayOrNew()));
  }

  /// 오늘 고친 메모가 있으면 이어 쓴다. 하루에 앱을 여러 번 여는 흐름에서
  /// 열 때마다 새 기록이 쌓이면 목록이 못 쓰게 된다.
  Note _todayOrNew() {
    final now = DateTime.now();
    for (final n in _store.notes) {
      final d = n.updatedAt;
      if (d.year == now.year && d.month == now.month && d.day == now.day) return n;
    }
    return _store.create();
  }

  Future<void> _open(Note note) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditorPage(store: _store, note: note)),
    );
    // 아무것도 안 치고 나온 새 기록은 남기지 않는다.
    _store.discardIfEmpty(note);
    unawaited(_syncHealth(note));
  }

  /// 편집을 마치고 나올 때 건강 앱과 맞춘다.
  ///
  /// 기다리지 않는다 — 권한 창이 뜨든 안 뜨든 목록은 이미 보여야 한다.
  /// 실패해도 조용하다. 연동은 덤이지 기록의 전제가 아니다.
  Future<void> _syncHealth(Note note) async {
    final sets = note.blocks.expand((b) => b.sets).where((s) => s.done);
    if (sets.isEmpty) return;
    // 시작과 끝. 세트마다 시각을 남기지 않으므로 노트가 만들어진 때와 마지막에
    // 고친 때로 잡는다. 실제로 그 사이에 운동을 한 것이 맞다.
    final start = note.createdAt;
    final end = note.updatedAt;
    if (!end.isAfter(start)) return;

    if (!await _health.authorize()) return;

    // 심박이 얼마나 늦게 도착하는지 남긴다. 심박으로 휴식을 끊어 주는 기능을
    // 만들지 말지가 이 값에 달려 있다 — 몇 초면 되고 몇 분이면 못 한다.
    final hr = await _health.latestHeartRate();
    debugPrint(hr == null
        ? '[심박] 최근 30분에 잰 것이 없다'
        : '[심박] ${hr.bpm}bpm · 잰 시각 ${hr.at} · 지연 ${hr.lag.inSeconds}초');

    final kcal = await _health.activeEnergy(start, end);
    await _health.writeWorkout(
      start: start,
      end: end,
      title: note.title,
      energyBurned: kcal,
    );
    if (kcal != null && mounted) {
      note.calories = kcal;
      _store.touch();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 내려갈 때는 디바운스를 기다리지 않는다.
    if (state != AppLifecycleState.resumed) _store.flush();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.flush();
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFFE9E9EC),
        body: SizedBox.shrink(),
      );
    }
    return NotesListPage(store: _store, onOpen: _open);
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, required this.store, required this.note});

  final NotesStore store;
  final Note note;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _editor = RoutineEditorController();

  @override
  void initState() {
    super.initState();
    _editor.restore(widget.note.blocks);
    _editor.addListener(_persist);
  }

  void _persist() => widget.store.update(widget.note, _editor.blocks);

  @override
  void dispose() {
    _editor.removeListener(_persist);
    widget.store.flush();
    _editor.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: ListenableBuilder(
          listenable: _editor,
          builder: (context, _) => Text(
            _editor.blocks.isEmpty ? l.appTitle : _editor.blocks.first.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
        ),
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
