import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'editor.dart';
import 'handoff.dart';
import 'meal.dart';
import 'partner.dart';
import 'record_ai.dart';
import 'units.dart';

/// 한 끼. 사진으로 어림했든, 성분표로 계산했든, 글로 적었든 같은 모양이다.
///
/// **사람이 적은 글이 원본이다.** 열량을 모르면 [kcal] 이 null 이다 — 0 이
/// 아니다. 예전 기록(at·kcal·items 뿐)은 그대로 읽힌다.
class MealEntry {
  MealEntry({
    required this.at,
    required this.kcal,
    this.items = const [],
    this.text,
    this.source,
    this.basis,
    this.eaten,
    this.foods = const [],
    this.sources = const [],
    String? id,
    this.dirty = true,
  }) : id = id ?? newMealId();
  final DateTime at;

  /// 이 기기가 지은 이름. 서버의 같은 줄을 가리키는 열쇠라서, 다시 보내도 한
  /// 줄이고 고치기·지우기도 그 줄에 닿는다. 끼니를 고쳐 새로 만들 때는 **같은
  /// id 를 물려준다.**
  final String id;

  /// 서버에 아직 안 올린 변경이 있는가. 예전 기록은 false 로 읽힌다 — 그때는
  /// 올릴 길이 없었고, 이제 와서 한꺼번에 올리면 코치 목록에 옛 끼니가 쏟아진다.
  bool dirty;

  static final _random = Random();
  static String newMealId() =>
      'm${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_random.nextInt(1 << 32).toRadixString(36)}';

  /// 최종 열량. 모르면 null.
  final int? kcal;
  final List<String> items;

  /// 사람이 친 글 그대로. 글로 적은 끼니에만 있다.
  final String? text;

  /// [kcal] 이 어디서 왔나. 화면이 "약" 을 붙일지 정한다. 예전 기록은 null
  /// 이고 어림으로 다룬다 — 그때는 사진 어림뿐이었다.
  final String? source;
  static const typed = 'typed', label = 'label', estimate = 'estimate';

  /// 다시 계산할 근거와 실제 먹은 양. 둘이 있으면 양을 고쳐 열량을 다시 낸다.
  /// [kcal] 은 이미 먹은 양이 반영된 값이므로 여기에 또 곱하지 않는다.
  final MealBasis? basis;
  final double? eaten;

  /// 글에서 알아본 음식·양·단위.
  final List<MealFood> foods;

  /// [kcal] 을 계산한 표의 줄들. 모델 혼자 어림했으면 비어 있다.
  final List<MealSource> sources;

  bool get approximate => kcal != null && source != typed && source != label;

  /// 글에 적은 열량이 일부 음식의 것뿐이다("닭가슴살 330kcal, 밥 한 공기").
  /// [kcal] 은 적은 합이라 온전한 값이 아니다 — 모르는 끼니처럼 센다.
  bool get partial {
    if (source != typed || text == null) return false;
    final parsed = parseMealText(text!);
    return parsed.kcal == null && parsed.typed != null;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    if (dirty) 'dirty': true,
    'at': at.toIso8601String(),
    'kcal': kcal,
    'items': items,
    'text': ?text,
    'source': ?source,
    'basis': ?basis?.toJson(),
    'eaten': ?eaten,
    if (foods.isNotEmpty) 'foods': [for (final f in foods) f.toJson()],
    if (sources.isNotEmpty) 'sources': [for (final s in sources) s.toJson()],
  };

  static MealEntry? tryFromJson(Object? j) {
    if (j is! Map) return null;
    final at = j['at'], kcal = j['kcal'], text = j['text'];
    if (at is! String) return null;
    // 열량도 글도 없으면 끼니가 아니다 — 깨진 기록이다.
    if (kcal is! num && text is! String) return null;
    final when = DateTime.tryParse(at);
    if (when == null) return null;
    final eaten = j['eaten'], source = j['source'];
    return MealEntry(
      at: when,
      kcal: kcal is num && kcal.isFinite && kcal >= 0 ? kcal.round() : null,
      items: (j['items'] as List?)?.whereType<String>().toList() ?? const [],
      text: text is String ? text : null,
      source: source is String ? source : null,
      basis: MealBasis.tryFromJson(j['basis']),
      eaten: eaten is num && eaten >= 0 ? eaten.toDouble() : null,
      foods: [
        for (final f in (j['foods'] as List? ?? const []))
          ?MealFood.tryFromJson(f),
      ],
      sources: MealSource.listFrom(j['sources']),
      id: j['id'] is String ? j['id'] as String : null,
      dirty: j['dirty'] == true,
    );
  }
}

/// 운동 칸들의 저장 모양. 디스크와 파트너 공유가 같은 것을 쓴다 — 단위·사용자
/// 운동명·메모·수행 상태가 어느 길로 가든 글자 하나 바뀌지 않는다.
List<Map<String, Object?>> blocksToJson(List<ExerciseBlock> blocks) => [
  for (final b in blocks)
    {
      'id': b.id,
      'name': b.name,
      if (b.setup != null) 'setup': b.setup!.toJson(),
      'sets': [
        for (final s in b.sets)
          {
            'id': s.id,
            'author': ?s.author,
            'value': s.value,
            'unit': s.unit,
            'reps': s.reps,
            'notes': s.notes,
            'done': s.done,
          },
      ],
    },
];

/// 내가 적은 세트만 남긴 사본. 같이 고친 문서에는 남의 세트도 있다 — 내 기록으로
/// 나가는 곳(파트너 공유)에는 내 것만 간다. 세트가 하나도 안 남은 운동도 남긴다:
/// 같이 짠 운동 목록은 내 것이기도 하다.
List<ExerciseBlock> mineOnly(List<ExerciseBlock> blocks) => [
  for (final b in blocks)
    ExerciseBlock(
      b.name,
      [
        for (final s in b.sets)
          if (s.author == null) s,
      ],
      b.setup,
      b.id,
    ),
];

List<ExerciseBlock> blocksFromJson(Object? blocks) => [
  for (final b in blocks is List ? blocks : const [])
    if (b is Map && b['name'] is String)
      ExerciseBlock(
        b['name'] as String,
        [
          for (final s in (b['sets'] as List? ?? const []))
            if (s is Map)
              LoggedSet(
                id: s['id'] is String ? s['id'] as String : null,
                author: s['author'] is String ? s['author'] as String : null,
                // 'kg' 는 단위가 생기기 전에 저장된 기록이다. 그때는
                // 무게가 늘 kg 였으므로 그대로 읽어 준다.
                value: ((s['value'] ?? s['kg']) as num?)?.toDouble(),
                unit: s['unit'] as String? ?? defaultUnit,
                reps: (s['reps'] as num?)?.toInt(),
                // 'note'(단수)는 메모가 하나뿐이던 시절의 저장분이다.
                notes:
                    (s['notes'] as List?)?.whereType<String>().toList() ??
                    (s['note'] is String ? [s['note'] as String] : null),
                done: s['done'] as bool? ?? true,
              ),
        ],
        WorkoutSetup.tryFromJson(b['setup']),
        b['id'] is String ? b['id'] as String : null,
      ),
];

/// 한 번의 운동 기록. 메모 앱의 메모 한 장에 해당한다.
///
/// 제목을 따로 받지 않는다 — 첫 운동 이름이 곧 제목이다. 메모 앱이 첫 줄을
/// 제목으로 쓰는 것과 같고, 치는 사람이 제목을 고민할 일이 없다.
class Note {
  Note({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    List<ExerciseBlock>? blocks,
    this.calories,
    this.draft,
    this.gymId,
    this.routineId,
  }) : blocks = blocks ?? [];

  final String id;
  final DateTime createdAt;
  DateTime updatedAt;
  List<ExerciseBlock> blocks;

  /// 이 운동 동안 **애플워치가 잰** 활동 칼로리. 잰 것이 없으면 null 이다.
  /// 앱이 추정하지 않는다 — 0 과 "아무도 안 쟀다"는 다른 말이다.
  double? calories;
  EditorDraft? draft;

  /// 트레이너가 내려준 루틴으로 시작한 기록이면 어디 것인지 남는다.
  /// 끝났을 때 그 체육관으로 올리고, 대기열에서 뺀다.
  String? gymId, routineId;

  /// 체육관으로 올린 시각. 헬스장은 신호가 나빠 한 번에 못 갈 때가 있으므로,
  /// 안 보낸 것은 다음에 앱을 켤 때 다시 보낸다.
  DateTime? sentAt;

  /// 이 운동이 시작된 공동 루틴과 그 버전. 계획은 출발점일 뿐이다 — 여기서 실제
  /// 값을 고쳐도 계획은 바뀌지 않고, 계획이 나중에 바뀌어도 이 운동은 그대로다.
  String? planId;
  int? planVersion;

  /// 둘이 합의한 버전으로 시작했는가. false 면 합의 전에 본인용 사본으로 시작했다.
  bool planAgreed = false;

  /// 같이 하기. 상대의 기록은 **여기에만** 있다 — [blocks] 에 섞이지 않으므로
  /// 내 통계·하루 집계·업로드 어디에도 들어가지 않는다.
  PartnerSession? partner;

  /// 같이 운동하는 사람을 위해 **대신 적은** 기록. 내 것이 아니다 — [blocks] 에
  /// 섞이지 않고, 건네면 그 사람 폰에서 그 사람의 문서가 된다.
  ProxyRecord? proxy;

  /// 이 문서가 남이 적어 건네준 기록에서 왔으면 그 링크와 받은 번호. 같은 링크를
  /// 다시 열어도 문서가 둘이 되지 않는다. 받은 뒤에 내가 손댔으면 [handoffTouched]
  /// — 그때는 새로 온 내용으로 덮지 않는다.
  String? handoffToken;
  int? handoffRevision;
  bool handoffTouched = false;

  /// 그날 끼니들. 운동 칼로리와 견주어 보려고 둔다.
  final List<MealEntry> meals = [];

  /// 지웠는데 서버에는 아직 남아 있을 끼니의 id. 지우기도 그물이 끊기면 밀린다.
  final List<String> deletedMeals = [];

  /// 끼니를 지운다. 서버에 올라갔을 수 있는 것이면 지울 것으로 적어 둔다.
  void removeMeal(MealEntry meal) {
    if (meals.remove(meal) && gymId != null) deletedMeals.add(meal.id);
  }

  /// **열량을 아는 끼니만의** 합계. 끼니가 없으면 null — 0 과 "안 적었다" 는
  /// 다르다. [unknownMeals] 가 0 이 아니면 이 값은 하루 총합이 아니다.
  int? get intake =>
      meals.isEmpty ? null : meals.fold<int>(0, (n, m) => n + (m.kcal ?? 0));

  /// 열량을 모르는 끼니 수. 합계를 온전한 총합처럼 보이면 안 되는 이유다.
  int get unknownMeals =>
      meals.where((m) => m.kcal == null || m.partial).length;

  /// 목록에 뜨는 제목 — 그날 한 운동 이름 전부.
  ///
  /// 첫 운동만 내던 것을 바꿨다. 메모 앱은 첫 줄이 곧 제목이라 그게 맞지만
  /// 운동 기록은 다르다. 목록에서 찾는 것은 대개 "저번에 벤치 언제 했지" 나
  /// "화요일에 뭐 했지" 인데, 둘 다 그날 한 것 전부를 봐야 답이 나온다.
  /// 첫 운동은 그날을 대표하지 않는다 — 그냥 먼저 친 것뿐이다.
  ///
  /// 길면 화면이 잘라 준다. 앞의 몇 개만 보여도 첫 하나보다 낫다.
  String? get title => blocks.isEmpty
      ? draft?.text.trim()
      : blocks.map((b) => b.name).toSet().join(' · ');

  /// 제목 아래 한 줄 — 그날 총계.
  ///
  /// 첫 운동의 첫 세트만 내던 것을 바꿨다. 그날 열두 세트를 했는데
  /// "1세트 · 80kg · 10회" 라고 뜨면 틀린 말은 아니지만 쓸모가 없다.
  String summary({
    required String Function(int) setOrdinal,
    required String Function(int) reps,
  }) {
    final total = blocks.fold(
      0,
      (n, b) => n + b.sets.where((s) => s.mine).length,
    );
    return total == 0 ? '' : setOrdinal(total);
  }

  /// 검색이 훑는 글. 운동 이름과 메모만 본다 — 숫자로 찾는 사람은 없다.
  String get searchText => blocks
      .map((b) => [b.name, ...b.sets.expand((s) => s.notes)].join(' '))
      .join(' ')
      .toLowerCase();

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (calories != null) 'calories': calories,
    if (draft != null) 'draft': draft!.toJson(),
    if (gymId != null) 'gymId': gymId,
    if (routineId != null) 'routineId': routineId,
    if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
    if (meals.isNotEmpty) 'meals': [for (final m in meals) m.toJson()],
    if (deletedMeals.isNotEmpty) 'deletedMeals': deletedMeals,
    if (partner != null) 'partner': partner!.toJson(),
    if (proxy != null) 'proxy': proxy!.toJson(),
    'handoffToken': ?handoffToken,
    'handoffRevision': ?handoffRevision,
    if (handoffTouched) 'handoffTouched': true,
    'planId': ?planId,
    'planVersion': ?planVersion,
    if (planAgreed) 'planAgreed': true,
    'blocks': blocksToJson(blocks),
  };

  static Note fromJson(Map<String, dynamic> j) => _restore(
    j,
    Note(
      id: j['id'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
      updatedAt: DateTime.parse(j['updatedAt'] as String),
      calories: (j['calories'] as num?)?.toDouble(),
      draft: EditorDraft.fromJson(j['draft']),
      gymId: j['gymId'] as String?,
      routineId: j['routineId'] as String?,
      blocks: blocksFromJson(j['blocks']),
    ),
  );

  /// 생성자에 없는 값을 읽은 뒤에 채운다.
  static Note _restore(Map<String, dynamic> j, Note note) {
    final sent = j['sentAt'];
    if (sent is String) note.sentAt = DateTime.tryParse(sent);
    for (final m in (j['meals'] as List? ?? const [])) {
      final meal = MealEntry.tryFromJson(m);
      if (meal != null) note.meals.add(meal);
    }
    note.partner = PartnerSession.tryFromJson(j['partner']);
    note
      ..proxy = ProxyRecord.tryFromJson(j['proxy'])
      ..handoffToken = j['handoffToken'] as String?
      ..handoffRevision = (j['handoffRevision'] as num?)?.toInt()
      ..handoffTouched = j['handoffTouched'] == true;
    note
      ..planId = j['planId'] as String?
      ..planVersion = (j['planVersion'] as num?)?.toInt()
      ..planAgreed = j['planAgreed'] == true;
    note.deletedMeals.addAll(
      (j['deletedMeals'] as List? ?? const []).whereType<String>(),
    );
    return note;
  }
}

/// 노트 전부를 들고 있고 디스크와 맞춰 두는 곳.
///
/// ponytail: 노트 전체를 JSON 한 파일에 쓴다. 한 사람이 하루 한 장씩 몇 년을
/// 써도 수천 장이라 통째로 읽고 쓰는 값이 싸다. 이게 느껴지면 그때 노트별
/// 파일이나 sqlite 로 간다.
class NotesStore extends ChangeNotifier {
  NotesStore({Directory? directory}) : _override = directory;

  final Directory? _override;
  final List<Note> _notes = [];
  Timer? _debounce;
  Future<void> _writes = Future.value();
  final List<String> _exerciseHistory = [];
  final Set<String> _forgottenExercises = {};
  List<String> get exerciseHistory => List.unmodifiable(_exerciseHistory);
  String _weightUnit = defaultUnit;
  String get weightUnit => _weightUnit;

  /// 박자마다 몇 번째인지 읽어 줄까. 기본은 꺼짐 — 헬스장에서 소리가 갑자기
  /// 나오면 곤란한 사람이 있고, 켜는 것이 끄는 것보다 쉬워야 한다.
  bool _countAloud = false;
  bool get countAloud => _countAloud;

  /// AI 도움(DeepSeek)에 동의했는가. null 이면 아직 묻지 않았다 — 처음 AI 를
  /// 부를 때 한 번 묻는다(ai_consent.dart). false 면 묻지 않고 기기 안에서만 한다.
  bool? _aiConsent;
  bool? get aiConsent => _aiConsent;

  void setAiConsent(bool value) {
    if (value == _aiConsent) return;
    _aiConsent = value;
    notifyListeners();
    _scheduleSave();
  }

  /// 이 기기를 가리키는 무작위 문자열. 사람을 가리키지 않는다.
  ///
  /// 질문을 서버에 보낼 때 셀 대상이 필요해서 만든다. 계정도 로그인도 없고,
  /// 지우면 다음에 새로 만들어진다.
  String _deviceId = '';
  String get deviceId => _deviceId;

  /// 하루 원판을 마지막으로 받은 날(한국 날짜). 같은 날 두 번 묻지 않는다.
  String _platesDay = '';
  String get platesDay => _platesDay;

  void setPlatesDay(String day) {
    _platesDay = day;
    _scheduleSave();
  }

  /// 최근에 고친 것이 위로. 메모 앱과 같은 순서다.
  List<Note> get notes => List.unmodifiable(_notes);

  Future<File> _file() async {
    final dir = _override ?? await getApplicationDocumentsDirectory();
    return File('${dir.path}/notes.json');
  }

  Future<void> load() async {
    try {
      final f = await _file();
      try {
        final preferences = File('${f.parent.path}/preferences.json');
        if (preferences.existsSync()) {
          final data = jsonDecode(await preferences.readAsString()) as Map;
          _weightUnit = data['weightUnit'] == 'lb' ? 'lb' : defaultUnit;
          _countAloud = data['countAloud'] == true;
          if (data['aiConsent'] case final bool consent) _aiConsent = consent;
          final saved = data['deviceId'];
          if (saved is String && saved.length >= 16) _deviceId = saved;
          if (data['platesDay'] case final String day) _platesDay = day;
          _exerciseHistory
            ..clear()
            ..addAll(
              (data['exercises'] as List? ?? []).whereType<String>().toSet(),
            );
          _forgottenExercises
            ..clear()
            ..addAll(
              (data['forgottenExercises'] as List? ?? []).whereType<String>(),
            );
        }
      } catch (e) {
        debugPrint('Could not load preferences: $e');
      }
      if (_deviceId.isEmpty) {
        // 처음 켰다. 만들어 두고 다음 저장 때 같이 나간다.
        final random = Random.secure();
        _deviceId = base64Url
            .encode(List.generate(18, (_) => random.nextInt(256)))
            .replaceAll('=', '');
        _scheduleSave();
      }
      if (!f.existsSync()) {
        notifyListeners();
        return;
      }
      final raw = jsonDecode(await f.readAsString()) as List;
      _notes
        ..clear()
        ..addAll(raw.map((e) => Note.fromJson(e as Map<String, dynamic>)));
      _sort();
      for (final n in _notes) {
        for (final b in n.blocks.reversed) {
          // 익히는 것은 운동 이름이다 — 제목 문장('벤치 80kg 5x5')이 아니다.
          final name = b.learnedName;
          if (name != null &&
              !_forgottenExercises.contains(name) &&
              !_exerciseHistory.contains(name)) {
            _exerciseHistory.add(name);
          }
        }
      }
      notifyListeners();
    } catch (e) {
      // 파일이 깨졌다고 앱이 안 뜨면 안 된다. 빈 목록으로 시작하고, 원본은
      // 덮어쓰기 전까지 그대로 있으므로 손으로 살릴 수 있다.
      debugPrint('notes.json 을 읽지 못했다: $e');
    }
  }

  /// 연달아 치는 동안 매번 쓰지 않도록 모아서 쓴다.
  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), flush);
  }

  /// 지금 당장 쓴다. 화면을 떠날 때와 앱이 내려갈 때 부른다.
  Future<void> flush() {
    _debounce?.cancel();
    final notes = jsonEncode(_notes.map((n) => n.toJson()).toList());
    final preferences = jsonEncode({
      'weightUnit': _weightUnit,
      'countAloud': _countAloud,
      'aiConsent': ?_aiConsent,
      'deviceId': _deviceId,
      'platesDay': _platesDay,
      'exercises': _exerciseHistory,
      'forgottenExercises': _forgottenExercises.toList(),
    });
    return _writes = _writes.then((_) async {
      try {
        final f = await _file();
        await _atomicWrite(f, notes);
        await _atomicWrite(
          File('${f.parent.path}/preferences.json'),
          preferences,
        );
      } catch (e) {
        debugPrint('Could not save notes: $e');
      }
    });
  }

  Future<void> _atomicWrite(File file, String text) async {
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(text, flush: true);
    await temporary.rename(file.path);
  }

  void setWeightUnit(String unit) {
    if (unit != 'kg' && unit != 'lb') return;
    _weightUnit = unit;
    notifyListeners();
    _scheduleSave();
  }

  void setCountAloud(bool value) {
    if (value == _countAloud) return;
    _countAloud = value;
    notifyListeners();
    _scheduleSave();
  }

  /// 설정을 붙여 만든 칸 가운데 제목이 [title] 인 가장 최근 것의 설정. 같은 루틴
  /// 줄을 다음 날 또 치면 편집기가 이 설정을 다시 쓴다.
  WorkoutSetup? setupOf(String title) => _notes
      .expand((n) => n.blocks)
      .where((b) => b.name == title && b.setup != null)
      .firstOrNull
      ?.setup;

  void rememberExercise(String name) {
    if (name.trim().isEmpty) return;
    _forgottenExercises.remove(name);
    _exerciseHistory.remove(name);
    _exerciseHistory.insert(0, name);
    _scheduleSave();
  }

  void forgetExercise(String name) {
    if (!_exerciseHistory.remove(name)) return;
    _forgottenExercises.add(name);
    _scheduleSave();
  }

  void updateDraft(Note note, EditorDraft? draft) {
    if (mapEquals(note.draft?.toJson(), draft?.toJson())) return;
    note.draft = draft;
    note.updatedAt = DateTime.now();
    _sort();
    notifyListeners();
    _scheduleSave();
  }

  void _sort() => _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Note create({
    List<ExerciseBlock>? blocks,
    String? gymId,
    String? routineId,
    String? id,
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    final note = Note(
      // 계획에서 시작한 운동은 서버가 기억하는 id 를 받는다 — 시작을 다시 눌러도
      // 같은 문서가 열리게.
      id: id ?? now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
      blocks: blocks,
      gymId: gymId,
      routineId: routineId,
    );
    _notes.insert(0, note);
    notifyListeners();
    _scheduleSave();
    return note;
  }

  /// 편집 결과를 노트에 담는다. 목록의 순서와 요약이 여기서 갱신된다.
  void update(Note note, List<ExerciseBlock> blocks) {
    note.blocks = blocks;
    note.updatedAt = DateTime.now();
    _sort();
    notifyListeners();
    _scheduleSave();
  }

  /// 노트 안을 직접 고친 뒤 알리고 저장한다. 순서는 건드리지 않는다 —
  /// 칼로리가 뒤늦게 붙었다고 목록이 재배열되면 사람이 놓친다.
  void touch() {
    notifyListeners();
    _scheduleSave();
  }

  void delete(Note note) {
    _notes.remove(note);
    notifyListeners();
    _scheduleSave();
  }

  /// 아무것도 안 친 메모는 목록에 남길 이유가 없다. 메모 앱과 같다.
  void discardIfEmpty(Note note) {
    if (note.blocks.isEmpty && (note.draft?.text.trim().isEmpty ?? true)) {
      delete(note);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
