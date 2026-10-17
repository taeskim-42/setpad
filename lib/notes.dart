import 'body.dart';
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
    this.reviewedText,
    this.source,
    this.basis,
    this.eaten,
    this.foods = const [],
    this.sources = const [],
    this.macros,
    String? id,
    this.dirty = true,
  }) : id = id ?? newMealId();

  /// 먹은 양의 탄단지. 표에서 계산한 끼니에만 있다. 양을 따로 고치면 믿을 수 없어 지운다.
  final MealMacros? macros;
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

  /// Confirmed food and amounts; the original input remains in [text].
  final String? reviewedText;
  String? get currentText => reviewedText ?? text;
  String get description => currentText ?? items.join(', ');

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
    'reviewedText': ?reviewedText,
    'source': ?source,
    'basis': ?basis?.toJson(),
    'eaten': ?eaten,
    if (foods.isNotEmpty) 'foods': [for (final f in foods) f.toJson()],
    if (sources.isNotEmpty) 'sources': [for (final s in sources) s.toJson()],
    if (macros != null) 'macros': mealMacrosToJson(macros!),
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
    final stored = kcal is num && kcal.isFinite && kcal >= 0
        ? kcal.round()
        : null;
    final parsed = source == typed && text is String
        ? parseMealText(text)
        : null;
    // Repair only values derived from explicit text; estimates need fresh evidence.
    final corrected =
        parsed != null && (parsed.typed != null || parsed.needsReview)
        ? parsed.kcal ?? parsed.typed
        : stored;
    return MealEntry(
      at: when,
      kcal: corrected,
      items: (j['items'] as List?)?.whereType<String>().toList() ?? const [],
      text: text is String ? text : null,
      reviewedText: j['reviewedText'] is String
          ? j['reviewedText'] as String
          : null,
      source: source is String ? source : null,
      basis: MealBasis.tryFromJson(j['basis']),
      eaten: eaten is num && eaten >= 0 ? eaten.toDouble() : null,
      foods: [
        for (final f in (j['foods'] as List? ?? const []))
          ?MealFood.tryFromJson(f),
      ],
      sources: MealSource.listFrom(j['sources']),
      macros: mealMacrosFromJson(j['macros']),
      id: j['id'] is String ? j['id'] as String : null,
      dirty: j['dirty'] == true || corrected != stored,
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

/// 이 기록을 건강 앱에 남긴 운동 하나. 다시 맞출 때 **이것만** 지우고 새로 쓴다 —
/// 편집기를 나올 때마다 새로 쓰기만 하면 같은 운동이 건강 앱에 여러 번 쌓인다.
class HealthWorkout {
  const HealthWorkout({
    required this.id,
    required this.from,
    required this.to,
    this.kcal,
  });

  /// 건강 앱이 준 식별자(HealthKit UUID, Health Connect 기록 id).
  final String id;

  /// 남긴 구간.
  final DateTime from, to;

  /// 운동에 함께 적은 활동 칼로리. Android 는 적지 않는다(null).
  final int? kcal;

  /// 이 구간 그대로인가. 건강 앱에는 밀리초까지만 간다.
  bool covers(DateTime start, DateTime end) =>
      from.millisecondsSinceEpoch == start.millisecondsSinceEpoch &&
      to.millisecondsSinceEpoch == end.millisecondsSinceEpoch;

  Map<String, Object?> toJson() => {
    'id': id,
    'from': from.toIso8601String(),
    'to': to.toIso8601String(),
    'kcal': ?kcal,
  };

  static HealthWorkout? tryFromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], kcal = j['kcal'];
    final from = j['from'] is String ? DateTime.tryParse(j['from']) : null;
    final to = j['to'] is String ? DateTime.tryParse(j['to']) : null;
    if (id is! String || id.isEmpty || from == null || to == null) return null;
    return HealthWorkout(
      id: id,
      from: from,
      to: to,
      kcal: kcal is num ? kcal.round() : null,
    );
  }
}

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

  /// 이 기록에 새로 넣는 끼니의 시각. 지난 기록에 늦게 적은 끼니는 그날의 같은
  /// 시각이다 — 지금으로 두면 하루 합계와 서버의 먹은 날이 오늘로 간다.
  DateTime mealTime([DateTime? now]) {
    final t = now ?? DateTime.now(), c = createdAt;
    return t.year == c.year && t.month == c.month && t.day == c.day
        ? t
        : DateTime(c.year, c.month, c.day, t.hour, t.minute, t.second);
  }

  /// 이 운동 동안 **애플워치가 잰** 활동 칼로리. 잰 것이 없으면 null 이다.
  /// 앱이 추정하지 않는다 — 0 과 "아무도 안 쟀다"는 다른 말이다.
  double? calories;

  /// 이 기록을 건강 앱에 남긴 운동. 아직 안 남겼거나 1.4.2 전에 남겼으면 null.
  HealthWorkout? healthWorkout;
  EditorDraft? draft;

  /// 트레이너가 내려준 루틴으로 시작한 기록이면 어디 것인지 남는다.
  /// 끝났을 때 그 체육관으로 올리고, 대기열에서 뺀다.
  String? gymId, routineId;

  /// 체육관으로 올린 시각. 헬스장은 신호가 나빠 한 번에 못 갈 때가 있으므로,
  /// 안 보낸 것은 다음에 앱을 켤 때 다시 보낸다.
  DateTime? sentAt;

  /// 서버가 이 기록을 받지 않았다(도장이 없어졌다, 루틴이 엇갈렸다). 같은 것을 다시
  /// 보내도 같은 답이라 보낸 것으로 치고, 기록 화면이 못 올렸다고 말한다. 고치면
  /// 다시 간다.
  bool uploadRejected = false;

  /// 스티커를 대기 전에 적던 오늘 기록이 그 방문이 된 때([NotesStore.visit]). 트레이너
  /// 에게는 기록을 연 아침이 아니라 이때 온 것으로 간다. 처음부터 방문으로 연 기록은
  /// null 이다 — 연 때가 곧 온 때다.
  DateTime? visitAt;

  /// 식단 공유로 끼니가 가는 도장. 스티커를 대지 않은 날의 기록에 붙는다 — 운동과
  /// 출석은 가지 않고 끼니만 간다(gym.dart syncMeals).
  String? mealGymId;

  /// 이 기록의 끼니가 가는 도장. 없으면 끼니는 기기에만 있다.
  String? get mealGym => gymId ?? mealGymId;

  /// 체육관에 온 때. 같은 방문을 가르는 세 시간도 여기서 센다.
  DateTime get cameAt => visitAt ?? createdAt;

  /// 이 기록을 체육관·같이 하기에 묶은 계정(서버의 user id). 노트는 기기에 있어
  /// 로그아웃해도 남는다 — 한 폰을 둘이 쓰면 A 가 못 보낸 운동·끼니·같이 하기
  /// 종료가 B 의 토큰으로 가서 B 의 것이 되거나, A 의 것은 보낸 셈이 되어 영영
  /// 안 갔다. 다른 계정으로 로그인해 있는 동안은 보내지 않고 기다린다. 이 표시가
  /// 생기기 전의 기록은 null — 예전처럼 지금 계정이 보낸다.
  String? owner;

  /// [user] 가 보내도 되는 기록인가.
  bool ownedBy(String? user) => owner == null || owner == user;

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

  /// 체육관 스티커를 대서 연 기록이다 — 그 자체로 출석이다. 받은 루틴을 열어만 봐도
  /// 출석은 남아야 하고(루틴 완료는 아니다), 집에서 목록의 루틴을 열어 본 것은
  /// 출석이 아니다. 둘을 가르는 것이 이것이다.
  bool checkedIn = false;

  /// 그날 끼니들. 운동 칼로리와 견주어 보려고 둔다.
  final List<MealEntry> meals = [];

  /// 지웠는데 서버에는 아직 남아 있을 끼니의 id. 지우기도 그물이 끊기면 밀린다.
  final List<String> deletedMeals = [];

  /// 끼니를 지운다. 서버에 올라갔을 수 있는 것이면 지울 것으로 적어 둔다.
  void removeMeal(MealEntry meal) {
    if (meals.remove(meal) && mealGym != null) deletedMeals.add(meal.id);
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
  ///
  /// 운동 없이 끼니만 적은 날(쉬는 날의 식단)은 먹은 것이 제목이다 — '새 운동'
  /// 으로 비워 두면 그날 무엇을 했는지 목록에서 안 보인다.
  String? get title {
    if (blocks.isNotEmpty) return blocks.map((b) => b.name).toSet().join(' · ');
    final typed = draft?.text.trim();
    if (typed != null && typed.isNotEmpty) return typed;
    final eaten = mealsText;
    return eaten.trim().isEmpty ? typed : eaten;
  }

  /// 먹은 것을 한 줄로 — 끼니마다 친 글 그대로.
  String get mealsText => [for (final m in meals) m.description].join(' · ');

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

  /// 검색이 훑는 글. 운동 이름과 메모, 먹은 것을 본다 — 끼니만 적은 날은 먹은
  /// 것이 제목이라, 제목에 보이는 글로 못 찾으면 막다른 길이다. 숫자로 찾는
  /// 사람은 없다.
  String get searchText => [
    for (final b in blocks) ...[b.name, ...b.sets.expand((s) => s.notes)],
    mealsText,
  ].join(' ').toLowerCase();

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (calories != null) 'calories': calories,
    'healthWorkout': ?healthWorkout?.toJson(),
    if (draft != null) 'draft': draft!.toJson(),
    if (gymId != null) 'gymId': gymId,
    if (routineId != null) 'routineId': routineId,
    if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
    if (uploadRejected) 'uploadRejected': true,
    'visitAt': ?visitAt?.toIso8601String(),
    'mealGymId': ?mealGymId,
    'owner': ?owner,
    if (meals.isNotEmpty) 'meals': [for (final m in meals) m.toJson()],
    if (deletedMeals.isNotEmpty) 'deletedMeals': deletedMeals,
    if (partner != null) 'partner': partner!.toJson(),
    if (proxy != null) 'proxy': proxy!.toJson(),
    'handoffToken': ?handoffToken,
    'handoffRevision': ?handoffRevision,
    if (handoffTouched) 'handoffTouched': true,
    if (checkedIn) 'checkedIn': true,
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
    final sent = j['sentAt'], visit = j['visitAt'];
    if (sent is String) note.sentAt = DateTime.tryParse(sent);
    if (visit is String) note.visitAt = DateTime.tryParse(visit);
    note
      ..uploadRejected = j['uploadRejected'] == true
      ..mealGymId = j['mealGymId'] is String ? j['mealGymId'] as String : null;
    note.owner = j['owner'] as String?;
    note.healthWorkout = HealthWorkout.tryFromJson(j['healthWorkout']);
    for (final m in (j['meals'] as List? ?? const [])) {
      final meal = MealEntry.tryFromJson(m);
      if (meal != null) note.meals.add(meal);
    }
    note.partner = PartnerSession.tryFromJson(j['partner']);
    note
      ..proxy = ProxyRecord.tryFromJson(j['proxy'])
      ..handoffToken = j['handoffToken'] as String?
      ..handoffRevision = (j['handoffRevision'] as num?)?.toInt()
      ..handoffTouched = j['handoffTouched'] == true
      ..checkedIn = j['checkedIn'] == true;
    note.deletedMeals.addAll(
      (j['deletedMeals'] as List? ?? const []).whereType<String>(),
    );
    return note;
  }
}

/// 지운 기록이 서버에 남긴 것 하나 — 끼니 줄(`meal`), 운동·출석 줄(`workout`, 기록
/// id), 끝났다고 못 알린 같이 하기(`session`). [owner] 는 그 기록의 계정이다 — 그
/// 계정의 토큰으로만 보낸다([Note.owner]).
typedef ServerDelete = ({String kind, String id, String? owner});

/// 노트 전부를 들고 있고 디스크와 맞춰 두는 곳.
///
/// ponytail: 노트 전체를 JSON 한 파일에 쓴다. 한 사람이 하루 한 장씩 몇 년을
/// 써도 수천 장이라 통째로 읽고 쓰는 값이 싸다. 이게 느껴지면 그때 노트별
/// 파일이나 sqlite 로 간다.
class NotesStore extends ChangeNotifier {
  NotesStore({Directory? directory}) : _override = directory;

  final Directory? _override;
  final List<Note> _notes = [];

  /// 알릴 때마다 오른다. 화면이 '기록이 바뀌었나' 를 싸게 물어, 바뀌지 않았으면
  /// 전체 기록을 다시 세지 않는다(떠 있는 답·오늘 루틴).
  int revision = 0;

  @override
  void notifyListeners() {
    revision++;
    super.notifyListeners();
  }

  Timer? _debounce;
  Future<void> _writes = Future.value();
  final List<String> _exerciseHistory = [];
  final Set<String> _forgottenExercises = {};
  List<String> get exerciseHistory => List.unmodifiable(_exerciseHistory);

  /// 세트를 하나라도 적은 운동 이름 — 사람이 운동으로 남긴 것. 운동과 끼니를 가를
  /// 때 근거가 된다(익힌 이름 [exerciseHistory] 는 근거 없이 만든 칸도 든다).
  Set<String> get doneExercises => {
    for (final n in _notes)
      for (final b in n.blocks)
        if (b.sets.isNotEmpty) ?b.learnedName,
  };
  String _weightUnit = defaultUnit;
  String get weightUnit => _weightUnit;

  /// 박자마다 몇 번째인지 읽어 줄까. 기본은 꺼짐 — 헬스장에서 소리가 갑자기
  /// 나오면 곤란한 사람이 있고, 켜는 것이 끄는 것보다 쉬워야 한다.
  bool _countAloud = false;
  bool get countAloud => _countAloud;

  /// 내 몸 정보(기초대사량 셈에만). 기기 밖으로 보내지 않는다.
  BodyProfile _body = const BodyProfile();
  BodyProfile get body => _body;

  void setBody(BodyProfile value) {
    _body = value;
    notifyListeners();
    _scheduleSave();
  }

  /// 체성분 기록, 잰 날 순. 기기 안에만 둔다.
  List<BodyRecord> _bodyRecords = [];
  List<BodyRecord> get bodyRecords => List.unmodifiable(_bodyRecords);

  /// 기록을 더한다(같은 id 면 바꾼다). 가장 최근 기록의 몸무게가 몸 정보의 몸무게가 된다 —
  /// 기초대사량과 운동 어림이 새 몸무게로 셈한다.
  void saveBodyRecord(BodyRecord record, {double? heightCm}) {
    _bodyRecords = [
      for (final r in _bodyRecords)
        if (r.id != record.id) r,
      record,
    ]..sort((a, b) => a.on.compareTo(b.on));
    final latest = _bodyRecords.lastWhere(
      (r) => r.weightKg != null,
      orElse: () => record,
    );
    if (latest.weightKg != null || heightCm != null) {
      _body = _body.copyWith(
        heightCm: heightCm,
        weightKg: latest.weightKg ?? _body.weightKg,
      );
    }
    notifyListeners();
    _scheduleSave();
  }

  void deleteBodyRecord(String id) {
    _bodyRecords = [
      for (final r in _bodyRecords)
        if (r.id != id) r,
    ];
    notifyListeners();
    _scheduleSave();
  }

  /// 그날 운동을 어림할 몸무게. 없으면 null — 그러면 어림하지 않는다.
  double? weightOnDay(DateTime day) => weightOn(day, _bodyRecords, _body);

  /// AI 도움(DeepSeek)을 쓰는가. 기본은 켜짐이고 묻지 않는다. 설정의 AI 도움
  /// 줄에서 끄면 모델로 가는 문이 모두 닫히고 기기 안에서만 한다(RecordAi.enabled).
  ///
  /// 저장 키는 1.4.0 의 동의 시트가 쓰던 'aiConsent' 그대로다 — 거기서 '나중에' 를
  /// 고른 사람(false)은 꺼진 채로 남고, 답하지 않은 사람(없음)은 켜진다.
  bool _aiOn = true;
  bool get aiOn => _aiOn;

  void setAiOn(bool value) {
    if (value == _aiOn) return;
    _aiOn = value;
    notifyListeners();
    _scheduleSave();
  }

  /// 식단을 나누는 도장과 켠 날(그날 0시). null 이면 나누지 않는다 — 끼니는 건강 정보라
  /// 회원이 켜야 간다. **켤 때 이름을 보여 준 그 도장에만 간다** — 그 도장을 나간 뒤 다른
  /// 도장에 등록해도 그쪽으로 이어지지 않는다. 스티커·받은 루틴으로 연 기록은 이것과
  /// 상관없이 그 도장에 간다.
  ({String gymId, DateTime since})? _shareMeals;
  String? get shareMealsGym => _shareMeals?.gymId;
  bool get sharesMeals => _shareMeals != null;

  /// [day] 에 연 기록의 끼니를 나누는가. 켠 날 전의 기록은 켜도 가지 않는다 — 몇 달치
  /// 끼니가 코치 목록에 한꺼번에 쏟아지지 않게.
  bool sharesMealsOn(DateTime day) {
    final since = _shareMeals?.since;
    return since != null && !day.isBefore(since);
  }

  /// [gymId] 와 식단을 나누기 시작한다. null 이면 그만둔다.
  void setShareMeals(String? gymId) {
    if (gymId == shareMealsGym) return;
    final now = DateTime.now();
    final since = DateTime(now.year, now.month, now.day);
    _shareMeals = gymId == null ? null : (gymId: gymId, since: since);
    if (gymId != null) {
      // 꺼 둔 동안 앞서 나눈 기록에 적은 끼니는 다시 켰다고 가지 않는다.
      for (final n in _notes) {
        if (n.gymId == null &&
            n.mealGymId != null &&
            n.createdAt.isBefore(since)) {
          for (final m in n.meals) {
            m.dirty = false;
          }
        }
      }
    }
    notifyListeners();
    _scheduleSave();
  }

  /// 끼니가 바뀐 기록을 식단 공유에 묶는다 — 켤 때 고른 그 도장에, 아직 다니고 있을 때만.
  /// 스티커·루틴으로 연 기록은 이미 그 도장의 것이다.
  void linkMeals(Note note, List<String> gymIds, String? user) {
    final gymId = shareMealsGym;
    if (note.gymId != null ||
        note.mealGymId != null ||
        !gymIds.contains(gymId) ||
        !sharesMealsOn(note.createdAt) ||
        !note.ownedBy(user)) {
      return;
    }
    note
      ..mealGymId = gymId
      ..owner ??= user;
    _scheduleSave();
  }

  /// 도장 소식(공지·PT·담당) 가운데 회원이 이미 본 것 — gym.dart 의 gymSeenOf 꼴이다.
  /// [gymSeenOwner] 의 것이고, 처음 켰거나 다른 계정이면 그때 있던 것을 모두 본 것으로
  /// 치고 시작한다([seedGymSeen]) — 몇 달치 예약·공지가 한꺼번에 '새 소식' 이 되지 않게.
  final Map<String, String> _gymSeen = {};
  String? _gymSeenOwner;
  Map<String, String> get gymSeen => Map.unmodifiable(_gymSeen);
  String? get gymSeenOwner => _gymSeenOwner;

  void seedGymSeen(String owner, Map<String, String> seen) {
    _gymSeenOwner = owner;
    _gymSeen
      ..clear()
      ..addAll(seen);
    notifyListeners();
    _scheduleSave();
  }

  /// [seen] 을 본 것으로 적는다.
  void markGymSeen(Map<String, String> seen) {
    var changed = false;
    for (final MapEntry(:key, :value) in seen.entries) {
      if (_gymSeen[key] == value) continue;
      // 지우고 넣어 맨 뒤로 — 아래에서 오래 본 것부터 버린다.
      _gymSeen
        ..remove(key)
        ..[key] = value;
      changed = true;
    }
    if (!changed) return;
    // ponytail: 300개를 넘으면 오래 본 것부터 버린다. 공지가 날마다 와도 몇 KB 이고,
    // 버린 것이 아직 목록에 있으면 한 번 더 소식으로 뜰 뿐이다.
    while (_gymSeen.length > 300) {
      _gymSeen.remove(_gymSeen.keys.first);
    }
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

  /// 저장소를 읽는 중이다. 그동안의 저장은 미룬다([flush]).
  bool _loading = false;

  Future<void> load() async {
    // 처음 켰으면 기기 id 를 만든다. 저장은 기록을 다 읽은 뒤에 건다 — 읽는 사이에
    // 저장이 돌면 아직 빈 목록이 notes.json 을 덮는다.
    var minted = false;
    _loading = true;
    try {
      final f = await _file();
      final preferences = File('${f.parent.path}/preferences.json');
      try {
        if (preferences.existsSync()) {
          final data = jsonDecode(await preferences.readAsString()) as Map;
          // First: a field below that does not read must not cost the device its id (and with it
          // the wallet bought without signing in).
          final saved = data['deviceId'];
          if (saved is String && saved.length >= 16) _deviceId = saved;
          _weightUnit = data['weightUnit'] == 'lb' ? 'lb' : defaultUnit;
          _countAloud = data['countAloud'] == true;
          _body = BodyProfile.fromJson(data['body']);
          _bodyRecords = [
            for (final r in (data['bodyRecords'] as List? ?? const []))
              ?BodyRecord.tryFromJson(r),
          ]..sort((a, b) => a.on.compareTo(b.on));
          _aiOn = data['aiConsent'] != false;
          if (data['platesDay'] case final String day) _platesDay = day;
          if ((data['shareMealsGym'], data['shareMealsSince']) case (
            final String gymId,
            final String since,
          )) {
            if (DateTime.tryParse(since) case final day?) {
              _shareMeals = (gymId: gymId, since: day);
            }
          }
          if (data['gymSeenOwner'] case final String owner) {
            _gymSeenOwner = owner;
          }
          if (data['gymSeen'] case final Map seen) {
            _gymSeen.addAll({
              for (final MapEntry(:key, :value) in seen.entries)
                if (key is String && value is String) key: value,
            });
          }
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
          _deletes
            ..clear()
            ..addAll([
              for (final d in data['pendingDeletes'] as List? ?? const [])
                if (d case {'kind': final String kind, 'id': final String id})
                  (
                    kind: kind,
                    id: id,
                    owner: d['owner'] is String ? d['owner'] as String : null,
                  ),
            ]);
        }
      } catch (e) {
        debugPrint('Could not load preferences: $e');
        // The next save writes defaults over what did not read — keep the original beside it.
        try {
          await preferences.copy(
            '${preferences.path}.bak-${DateTime.now().millisecondsSinceEpoch}',
          );
        } catch (_) {}
      }
      if (_deviceId.isEmpty) {
        final random = Random.secure();
        _deviceId = base64Url
            .encode(List.generate(18, (_) => random.nextInt(256)))
            .replaceAll('=', '');
        minted = true;
      }
      if (f.existsSync()) await _readNotes(f);
    } catch (e) {
      // 파일이 깨졌다고 앱이 안 뜨면 안 된다. 읽은 만큼으로 시작한다 — 원본은
      // [_readNotes] 가 옆에 남겨 두었으니 손으로 살릴 수 있다.
      debugPrint('notes.json 을 읽지 못했다: $e');
    } finally {
      _loading = false;
    }
    if (minted) _scheduleSave();
    notifyListeners();
  }

  /// 기록을 하나씩 읽는다 — 하나가 깨졌다고(다음 판의 저장 모양, 손으로 고친 파일)
  /// 나머지를 버리지 않는다. 못 읽은 것이 있으면 원본을 `notes.json.bak-<시각>` 으로
  /// 남긴다: 다음 저장은 읽은 것만으로 notes.json 을 덮는다.
  Future<void> _readNotes(File f) async {
    final read = <Note>[];
    var whole = true;
    try {
      for (final e in jsonDecode(await f.readAsString()) as List) {
        try {
          read.add(Note.fromJson(e as Map<String, dynamic>));
        } catch (error) {
          whole = false;
          debugPrint('기록 하나를 읽지 못했다: $error');
        }
      }
    } catch (error) {
      whole = false;
      debugPrint('notes.json 을 읽지 못했다: $error');
    }
    if (!whole) {
      // A failed copy (a full disk, in practice) must not cost what did read.
      try {
        await f.copy('${f.path}.bak-${DateTime.now().millisecondsSinceEpoch}');
      } catch (error) {
        debugPrint('notes.json 사본을 남기지 못했다: $error');
      }
    }
    _notes
      ..clear()
      ..addAll(read);
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
  }

  /// 연달아 치는 동안 매번 쓰지 않도록 모아서 쓴다.
  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), flush);
  }

  /// JSON 에는 무한·NaN 이 없다. 그런 값 하나(자릿수 제한 없는 입력이 double 로
  /// 넘친 것)에 저장 전체가 실패해 그 뒤 모든 저장이 멈추지 않게, 그 값만 비운다.
  static Object? _finiteJson(Object? value) =>
      value is double ? null : (value as dynamic).toJson();

  /// 지금 당장 쓴다. 화면을 떠날 때와 앱이 내려갈 때 부른다.
  ///
  /// **읽는 중이면 쓰지 않고 미룬다.** 켜자마자 앱이 내려가면(두 번째 스티커, 바로 다른
  /// 앱으로) 아직 빈 목록과 기본 설정이 notes.json·preferences.json 을 덮었다 — 그 뒤
  /// 앱이 죽으면 기록·설정·기기 id 가 모두 사라진다. 다 읽은 뒤에 쓴다.
  Future<void> flush() {
    if (_loading) {
      _scheduleSave();
      return _writes;
    }
    _debounce?.cancel();
    final notes = jsonEncode(
      _notes.map((n) => n.toJson()).toList(),
      toEncodable: _finiteJson,
    );
    final preferences = jsonEncode({
      'weightUnit': _weightUnit,
      'countAloud': _countAloud,
      'body': _body.toJson(),
      if (_bodyRecords.isNotEmpty)
        'bodyRecords': [for (final r in _bodyRecords) r.toJson()],
      'aiConsent': _aiOn,
      'deviceId': _deviceId,
      'platesDay': _platesDay,
      'shareMealsGym': ?_shareMeals?.gymId,
      'shareMealsSince': ?_shareMeals?.since.toIso8601String(),
      'gymSeenOwner': ?_gymSeenOwner,
      if (_gymSeen.isNotEmpty) 'gymSeen': _gymSeen,
      'exercises': _exerciseHistory,
      'forgottenExercises': _forgottenExercises.toList(),
      if (_deletes.isNotEmpty)
        'pendingDeletes': [
          for (final d in _deletes)
            {'kind': d.kind, 'id': d.id, 'owner': ?d.owner},
        ],
    }, toEncodable: _finiteJson);
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

  /// 치다 만 것과 커서 자리. 기록이 아니므로 updatedAt 을 건드리지 않는다 — 카드를
  /// 열기만 해도 여기로 와서, 열어만 본 받은 루틴이 '고친 것' 이 되어 0세트로 완료
  /// 처리돼 올라갔다(gym.dart _lookedOnly).
  ///
  /// 알리지 않고 저장만 한다. 글자마다 오는 것이라, 알리면 듣는 화면(오늘 머리말의
  /// 하루 집계, 원판 문턱 세기)이 키 하나마다 모든 기록을 다시 훑는다. 초안을 그리는
  /// 화면은 없다 — 목록의 제목은 목록이 다시 보일 때 그린다.
  void updateDraft(Note note, EditorDraft? draft) {
    if (mapEquals(note.draft?.toJson(), draft?.toJson())) return;
    note.draft = draft;
    _scheduleSave();
  }

  void _sort() => _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  /// 그날의 기록 — 하루에 한 곳에 적는다. 오늘 만든 기록이 있으면 그것, 없으면
  /// 새로. 같은 날 기록이 둘이면 하나는 고칠 수 없는 곳에 따로 보였다.
  Note today({DateTime? now}) {
    final t = now ?? DateTime.now();
    for (final n in _notes) {
      final d = n.createdAt;
      if ((n.proxy == null || (n.title?.isNotEmpty ?? false)) &&
          d.year == t.year &&
          d.month == t.month &&
          d.day == t.day) {
        return n;
      }
    }
    return create(at: now);
  }

  Note create({
    List<ExerciseBlock>? blocks,
    String? gymId,
    String? routineId,
    String? id,
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    // Imported workouts share one instant per day; ids must still differ.
    var n = now.microsecondsSinceEpoch;
    while (_notes.any((x) => x.id == '$n')) {
      n++;
    }
    final note = Note(
      // 계획에서 시작한 운동은 서버가 기억하는 id 를 받는다 — 시작을 다시 눌러도
      // 같은 문서가 열리게.
      id: id ?? '$n',
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

  /// 사람이 지운 기록이 서버에 남긴 것. 기록은 이미 목록에 없으니 저장소가 들고
  /// 있다가 그물이 닿으면 보내고(gym.dart sendDeletes), 보낸 것은 거기서 뺀다.
  final List<ServerDelete> _deletes = [];
  List<ServerDelete> get pendingDeletes => _deletes;

  /// 사람이 기록을 지웠다. 서버에 올라갔을 수 있는 끼니와 운동·출석 줄도 지우도록
  /// 남긴다 — 회원은 지웠다고 믿는데 코치 화면에 그대로 남아 있었다. 아직 열린 같이
  /// 하기와 끝났다고 못 알린 같이 하기는 끝내도록(손님이면 나가도록) 남긴다 — 기록과
  /// 함께 사라지면 상대 폰에서 세션이 안 끝난다.
  /// 빈 기록 정리([discardIfEmpty])는 서버의 출석을 두고 기기에서만 치운다.
  void delete(Note note) {
    final owner = note.owner;
    if (note.mealGym != null) {
      _deletes.addAll([
        for (final id in {
          ...note.deletedMeals,
          for (final m in note.meals) m.id,
        })
          (kind: 'meal', id: id, owner: owner),
      ]);
    }
    if (note.gymId != null) {
      _deletes.add((kind: 'workout', id: note.id, owner: owner));
    }
    if (note.partner case final s? when s.liveOnServer) {
      _deletes.add((kind: 'session', id: s.id, owner: owner));
    }
    _forget(note);
  }

  void _forget(Note note) {
    _notes.remove(note);
    notifyListeners();
    _scheduleSave();
  }

  /// 아무것도 안 친 메모는 목록에 남길 이유가 없다. 메모 앱과 같다. 끼니만 적은
  /// 기록(쉬는 날의 식단)은 빈 기록이 아니다.
  void discardIfEmpty(Note note) {
    // 열린 같이 하기와 그물 없이 끝낸 같이 하기는 이 기록에만 매달려 있다. 지우면 상대
    // 폰에서 세션이 안 끝난다 — 아무것도 안 쳤어도 남겨 두어 끝낼 수 있게 한다.
    if (note.partner?.liveOnServer ?? false) return;
    // 루틴을 열어만 봤다. 받은 루틴은 목록에 그대로 있고, 이것은 한 것이 아니다.
    // 끼니·대신 적기는 touch() 로만 저장돼 updatedAt 이 그대로다 — 그것까지 봐야
    // 세트 없이 끼니 사진만 남긴 루틴 기록이 끼니째 지워지지 않는다. 스티커로 연
    // 것은 출석이라 남긴다(아직 못 보냈으면 다음에 간다).
    if (note.routineId != null &&
        !note.checkedIn &&
        note.sentAt == null &&
        !note.updatedAt.isAfter(note.createdAt) &&
        _blankBesidesSets(note)) {
      _forget(note);
      return;
    }
    if (note.blocks.isEmpty && _blankBesidesSets(note)) {
      // 루틴 없이 온 날의 출석은 빈 기록이다. 아직 못 보냈으면 지우지 않는다 —
      // 지우면 신호 없던 날의 출석이 트레이너에게 영영 안 간다. 보냈어도 세 시간은
      // 둔다: 그사이 다시 대면 이 기록을 다시 열어야 같은 방문이 둘로 세지 않는다
      // (main.dart _attendOnly). 지나면 [pruneVisits] 가 치운다.
      if (note.gymId != null &&
          (note.sentAt == null || note.cameAt.isAfter(visitWindowStart()))) {
        return;
      }
      _forget(note);
    }
  }

  /// 같은 방문으로 보는 시간. 웹이 열린 운동을 다시 여는 세 시간과 같다.
  static const visitWindow = Duration(hours: 3);
  static DateTime visitWindowStart() => DateTime.now().subtract(visitWindow);

  /// 세 시간 안에 같은 체육관에서 연 [user] 의 기록. 다른 계정의 방문을 다시
  /// 열면 내 출석이 안 생긴다(main.dart _attendOnly).
  Note? openVisit(String gymId, String? user) {
    final since = visitWindowStart();
    return _notes
        .where(
          (n) => n.gymId == gymId && n.cameAt.isAfter(since) && n.ownedBy(user),
        )
        .firstOrNull;
  }

  /// 스티커를 댔다 — 이 방문의 기록과, 새로 온 것인가.
  ///
  /// 세 시간 안에 같은 체육관에서 연 내 기록이 있으면 같은 방문이다([openVisit]). 없으면
  /// **오늘 먼저 적던 내 기록을 이 방문으로 삼는다.** 앱은 켤 때 오늘 기록을 열고, 회원은
  /// 아침 끼니와 스티커를 대기 전의 세트를 거기에 적는다 — 새 기록을 따로 열면 그것들이
  /// 체육관 없는 기록에 남아 트레이너에게 영영 안 갔다. 스티커를 댄 순간에만 붙이므로
  /// 집에서 적은 날이 출석이 되지는 않는다. 오늘 기록이 다른 도장의 것이거나 남의
  /// 것이면 새로 연다.
  ({Note note, bool fresh}) visit(String gymId, String? user) {
    final open = openVisit(gymId, user);
    if (open != null) return (note: open, fresh: false);
    final today = this.today();
    if (today.gymId == null && today.ownedBy(user)) {
      attend(today, gymId, user);
      return (note: today, fresh: true);
    }
    final note = create(gymId: gymId)..owner = user;
    touch();
    return (note: note, fresh: true);
  }

  /// [note] 를 [gymId] 에 온 기록으로 삼는다 — 스티커를 대 오늘 기록이 방문이 될 때와,
  /// 스티커 없이 온 회원이 스스로 보낼 때. 그때가 온 때다.
  void attend(Note note, String gymId, String? user) {
    note
      ..gymId = gymId
      ..visitAt = DateTime.now()
      ..owner ??= user;
    touch();
  }

  /// 세트 말고는 남긴 것이 없다 — 끼니도, 서버에 알릴 끼니 삭제도, 대신 적은 것도,
  /// 친 글도. 이것이 아니면 기록을 지울 때 그것들이 같이 사라진다.
  static bool _blankBesidesSets(Note n) =>
      n.meals.isEmpty &&
      n.deletedMeals.isEmpty &&
      n.proxy == null &&
      (n.draft?.text.trim().isEmpty ?? true);

  /// 세트 말고는 아무것도 매달려 있지 않다 — 끼니·출석·보낸 것·열린 같이 하기도 없다.
  /// 이것일 때만 지워도 세트 말고 잃는 것이 없다(루틴 "시작 취소").
  static bool onlySets(Note n) =>
      _blankBesidesSets(n) &&
      n.gymId == null &&
      n.sentAt == null &&
      !(n.partner?.liveOnServer ?? false);

  /// 편집기가 지금 열어 둔 기록. 정리하다 지우면 그 뒤에 친 것이 목록에 없는 기록에
  /// 쓰여 사라진다.
  final Set<Note> open = {};

  /// 보낸 지 세 시간이 지난 빈 출석 기록을 치운다. 앱이 밀린 것을 보낼 때 같이 돈다.
  void pruneVisits() {
    final stale = [
      for (final n in _notes)
        // 루틴 기록도 블록을 다 지웠으면 빈 출석이다. 열어만 본 루틴은 블록이 차 있어 남는다.
        if (n.gymId != null &&
            n.sentAt != null &&
            n.blocks.isEmpty &&
            _blankBesidesSets(n) &&
            !open.contains(n) &&
            !(n.partner?.liveOnServer ?? false) &&
            !n.cameAt.isAfter(visitWindowStart()))
          n,
    ];
    if (stale.isEmpty) return;
    _notes.removeWhere(stale.contains);
    notifyListeners();
    _scheduleSave();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
