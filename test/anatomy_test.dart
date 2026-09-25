import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show LicenseRegistry;
import 'package:flutter/material.dart' show Icons, LicensePage;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setpad/anatomy.dart';
import 'package:setpad/anatomy_page.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/exercises.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/notes_list.dart';
import 'package:setpad/record_ai.dart';
import 'package:setpad/routine.dart' show benchExercises, exerciseGear;
import 'package:setpad/routine_card.dart' show RoutineCard, setsText;
import 'package:setpad/settings_page.dart';

import 'routine_fixture.dart';

/// 기록을 손에 쥔 가게(routine_card_test 와 같다). 시작하면 새 기록이 맨 앞에 든다.
class _Records extends NotesStore {
  _Records(this.records);
  final List<Note> records;
  final created = <Note>[];
  @override
  List<Note> get notes => records;
  @override
  Note create({
    List<ExerciseBlock>? blocks,
    String? gymId,
    String? routineId,
    String? id,
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    final note = Note(
      id: id ?? 'new${created.length}',
      createdAt: now,
      updatedAt: now,
      blocks: blocks,
    );
    records.insert(0, note);
    created.add(note);
    notifyListeners();
    return note;
  }
}

final today = DateTime(2026, 9, 9);
var _ids = 0;
Note ago(int days, List<ExerciseBlock> blocks) {
  final at = today
      .subtract(Duration(days: days))
      .add(const Duration(hours: 19));
  return Note(id: 'a${_ids++}', createdAt: at, updatedAt: at, blocks: blocks);
}

/// 고정 기록을 오늘로 옮긴다(홈의 루틴 카드는 지금 시각으로 짠다).
List<Note> relativeLog() {
  final shift = Duration(days: DateTime.now().difference(routineToday).inDays);
  return [
    for (final n in defaultLog())
      Note(
        id: n.id,
        createdAt: n.createdAt.add(shift),
        updatedAt: n.updatedAt.add(shift),
        blocks: n.blocks,
        routineId: n.routineId,
      ),
  ];
}

/// 기록의 내 세트에 있는 무게 표기('85kg', '330lb').
Set<String> mineWeights(List<Note> notes) => {
  for (final n in notes)
    for (final b in n.blocks)
      for (final s in b.sets)
        if (s.mine && s.value != null && ['kg', 'lb'].contains(s.unit))
          '${s.value == s.value!.roundToDouble() ? s.value!.round() : s.value}${s.unit}',
};

final _weight = RegExp(r'(\d+(?:\.\d+)?)\s*(kg|lb)');

void main() {
  setUpAll(() => initializeDateFormatting());
  final l = lookupL(const Locale('ko'));

  group('표', () {
    test('사전 운동은 유산소만 빼고 모두 근육 표에 있다', () {
      for (final e in exercises) {
        final cardio = exercisePart[e.ko] == 'cardio';
        expect(moves.containsKey(e.ko), !cardio, reason: e.ko);
      }
    });

    test('운동마다 주동이 있고, 주동·보조가 겹치지 않고, 기구·팁이 있다', () {
      for (final e in moves.entries) {
        final m = e.value;
        expect(m.primary, isNotEmpty, reason: e.key);
        expect(m.primary.toSet().intersection(m.secondary.toSet()), isEmpty);
        expect(moveGear(e.key), isNotEmpty, reason: e.key);
        expect(m.cues, isNotEmpty, reason: e.key);
        expect(m.mistakes, isNotEmpty, reason: e.key);
        expect(m.sites, isNotEmpty, reason: e.key);
        for (final c in [...m.cues, ...m.mistakes]) {
          expect(c.ko.trim(), isNotEmpty);
          expect(c.en.trim(), isNotEmpty);
        }
      }
    });

    test('모든 부위에 운동이 있다 — 주동이 없으면 보조로 쓰는 운동, 누르면 빈 목록이 없다', () {
      for (final m in Muscle.values) {
        expect(
          moves.values.where(
            (v) => v.primary.contains(m) || v.secondary.contains(m),
          ),
          isNotEmpty,
          reason: m.name,
        );
        final t = tryFor(m, {});
        expect([...t.shown, ...t.hidden], isNotEmpty, reason: m.name);
        expect(muscleCoarse[m], isNotNull);
      }
    });

    test('사전 밖 운동은 여덟 언어 이름 어느 것으로 적어도 같은 운동이다', () {
      for (final e in moves.entries.where((e) => e.value.names != null)) {
        final n = e.value.names!;
        for (final name in [
          n.ko,
          n.en,
          n.ja,
          n.zhHans,
          n.zhHant,
          n.es,
          n.vi,
          n.th,
        ]) {
          expect(moveKey(name), e.key, reason: name);
        }
      }
      expect(moveKey('벤치'), '벤치프레스');
      expect(moveKey('Bench Press'), '벤치프레스');
      expect(moveKey('민수식 로우'), isNull);
    });

    test('부위 이름과 새 문구가 아홉 로케일 모두에 있다', () {
      for (final locale in L.supportedLocales) {
        final t = lookupL(locale);
        final fallback = t.muscleName('zzz');
        for (final m in Muscle.values) {
          final name = t.muscleName(m.name);
          expect(name, isNot(fallback), reason: '$locale ${m.name}');
          expect(name.trim(), isNotEmpty);
        }
        expect(t.anatomyTitle.trim(), isNotEmpty);
        expect(t.anatomyCuesEnglish.trim(), isNotEmpty);
      }
    });

    test('면 목록: 앞은 그림에 없는 고관절 굴곡근까지, 모든 부위가 어느 면에든 있다', () {
      expect(frontRegions, contains(Muscle.hipFlexors));
      expect(backRegions, isNot(contains(Muscle.hipFlexors)));
      expect({...frontRegions, ...backRegions}, Muscle.values.toSet());
    });
  });

  group('세기', () {
    test('주동은 한 세트, 보조는 반 세트 — 남의 세트·안 한 세트는 빼고', () {
      final load = bodyLoad(
        [
          ago(0, [
            ExerciseBlock('벤치', [
              ...times(4, () => kg(80, 5)),
              kg(100, 1, author: '민수'),
              kg(90, 3, done: false),
            ]),
          ]),
        ],
        today: today,
        days: 7,
      );
      expect(load.primary[Muscle.chest], 4);
      expect(load.of(Muscle.chest), 4);
      expect(load.secondary[Muscle.frontDelts], 4);
      expect(load.of(Muscle.frontDelts), 2);
      for (final head in tricepsHeads) {
        expect(load.of(head), 2, reason: "$head");
      }
      expect(load.of(Muscle.lats), 0);
    });

    test('기간 경계: 7일은 6일 전까지, 28일은 27일 전까지, 미래는 뺀다', () {
      final notes = [
        ago(6, [
          ExerciseBlock('스쿼트', [kg(100, 5)]),
        ]),
        ago(7, [
          ExerciseBlock('스쿼트', [kg(100, 5)]),
        ]),
        ago(27, [
          ExerciseBlock('스쿼트', [kg(100, 5)]),
        ]),
        ago(28, [
          ExerciseBlock('스쿼트', [kg(100, 5)]),
        ]),
        ago(-1, [
          ExerciseBlock('스쿼트', [kg(100, 5)]),
        ]),
      ];
      expect(bodyLoad(notes, today: today, days: 7).primary[Muscle.quads], 1);
      expect(bodyLoad(notes, today: today, days: 28).primary[Muscle.quads], 3);
    });

    test('모르는 이름은 세트 수와 함께 따로, 유산소는 유산소로', () {
      final load = bodyLoad(
        [
          ago(1, [
            ExerciseBlock('민수식 로우', times(2, () => kg(40, 10))),
            ExerciseBlock('러닝', [timed(5, 'km')]),
            ExerciseBlock('Face Pull', times(3, () => kg(20, 15))),
          ]),
        ],
        today: today,
        days: 7,
      );
      expect(load.unknown, {'민수식 로우': 2});
      expect(load.cardio, 1);
      // 사전 밖 운동(표에는 있다)은 센다.
      expect(load.primary[Muscle.rearDelts], 3);
    });

    test('색 단계는 이 기간 가장 많은 부위에 견준다', () {
      expect(level(0, 9), 0);
      expect(level(9, 9), 3);
      expect(level(3, 9), 1);
      expect(level(3.5, 9), 2);
      expect(level(6, 9), 2);
      expect(level(6.5, 9), 3);
      expect(level(1, 0), 0);
    });
  });

  group('기구 거르기', () {
    test('덤벨만 쓴 사람의 가슴: 덤벨·맨몸만 보이고 나머지는 접힌다(벤치 운동도)', () {
      final t = tryFor(Muscle.chest, {'덤벨컬'});
      expect(t.allGear, isFalse);
      // 덤벨 프레스는 벤치에 눕는다 — 벤치를 쓴 기록이 없으면 접힌다(루틴 표와 같다).
      expect(t.shown, ['푸시업']);
      expect(t.hidden, hasLength(8));
      expect(t.hidden, containsAll(['벤치프레스', '덤벨 프레스']));
      final bench = tryFor(Muscle.chest, {'덤벨컬', '불가리안 스플릿 스쿼트'});
      expect(bench.shown, ['덤벨 프레스', '인클라인 덤벨 프레스', '푸시업']);
    });

    test('표의 운동을 한 번도 안 했으면 거르지 않는다', () {
      final t = tryFor(Muscle.chest, {});
      expect(t.allGear, isTrue);
      expect(t.hidden, isEmpty);
      expect(t.shown, hasLength(9));
    });

    test('한 운동은 해 볼 목록에서 빠진다', () {
      expect(tryFor(Muscle.chest, {'벤치프레스'}).shown, isNot(contains('벤치프레스')));
    });
  });

  test('내가 한 운동: 이름이 달라도 한 줄, 숫자는 마지막 날 내 세트 그대로', () {
    final notes = [
      ago(3, [
        ExerciseBlock('벤치', [kg(80, 5), kg(80, 5), kg(120, 1, author: '민수')]),
      ]),
      ago(10, [ExerciseBlock('벤치프레스', times(3, () => kg(75, 5)))]),
      ago(2, [ExerciseBlock('시티드 로우', times(2, () => kg(50, 10)))]),
    ];
    final rows = doneFor(notes, Muscle.chest);
    expect(rows.map((r) => r.key), ['벤치프레스', '시티드 로우']);
    final bench = rows.first;
    expect(bench.name, '벤치');
    expect(bench.primary, isTrue);
    expect(bench.sets, [
      (value: 80.0, unit: 'kg', reps: 5),
      (value: 80.0, unit: 'kg', reps: 5),
    ]);
    // 로우는 가슴을 보조로 쓴다(ExRx Synergists: Pectoralis Major, Sternal).
    expect(rows.last.primary, isFalse);
  });

  group('화면', () {
    Future<void> pumpPage(
      WidgetTester tester,
      List<Note> notes, {
      Locale locale = const Locale('ko'),
    }) async {
      tester.view
        ..physicalSize = const Size(420, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        CupertinoApp(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: AnatomyPage(notes: notes, now: routineToday),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapArt(WidgetTester tester, bool front, Offset art) async {
      final box = tester.getRect(find.byKey(const ValueKey('anatomy-figure')));
      await tester.tapAt(box.topLeft + figurePoint(front, box.size, art));
      await tester.pumpAndSettle();
    }

    testWidgets('기록 0: 첫 사용 문구, 부위를 누르면 운동이 전부 보인다', (tester) async {
      await pumpPage(tester, []);
      expect(find.text(l.anatomyFirstTime), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('anatomy-row-chest')));
      await tester.pumpAndSettle();
      expect(find.text(l.anatomyNever), findsOneWidget);
      expect(find.text(l.anatomyAllGear), findsOneWidget);
      for (final name in ['벤치프레스', '덤벨 프레스', '케이블 크로스오버', '푸시업']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      // 줄을 누르면 자세 팁이 펼쳐진다.
      await tester.tap(find.byKey(const ValueKey('anatomy-try:벤치프레스')));
      await tester.pumpAndSettle();
      expect(find.text(l.anatomyCues), findsOneWidget);
      expect(find.text('• ${moves['벤치프레스']!.cues.first.ko}'), findsOneWidget);
      expect(find.text(l.anatomyAddRoutine), findsOneWidget);
      // 안 해 본 운동은 검색해도 기록이 없다 — 검색 칩이 없다.
      expect(find.text(l.anatomySearch), findsNothing);
    });

    testWidgets('그림을 누르면 그 부위, 근육 밖은 안내', (tester) async {
      await pumpPage(tester, []);
      // 근육과 부위 이름이 같으면('가슴 · 가슴') 한 번만 적는다.
      Finder header(String m) {
        final muscle = l.muscleName(m);
        final region = l.queryPart(muscleCoarse[Muscle.values.byName(m)]!);
        final title = muscle == region ? muscle : '$muscle · $region';
        return find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.key == const ValueKey('anatomy-title') &&
              w.data == title,
        );
      }

      Future<void> close() async {
        await tester.tap(find.byKey(const ValueKey('anatomy-close')));
        await tester.pumpAndSettle();
      }

      await tapArt(tester, true, const Offset(579, 389));
      expect(header('chest'), findsOneWidget);
      await close();

      // 옆 어깨는 얇다(그림에서 5pt 남짓) — 가운데든, 약 10pt 빗나가도 옆 어깨다.
      for (final x in [703.0, 733.0]) {
        await tapArt(tester, true, Offset(x, 351));
        expect(header('sideDelts'), findsOneWidget, reason: '$x');
        await close();
      }

      // 머리.
      await tapArt(tester, true, const Offset(512, 140));
      expect(find.text(l.anatomyTapHint), findsOneWidget);

      await tester.tap(find.text(l.anatomyBack));
      await tester.pumpAndSettle();
      await tapArt(tester, false, const Offset(575, 735));
      expect(header('glutes'), findsOneWidget);
    });

    testWidgets('VoiceOver: 부위마다 이름·세트·단계가 읽히고 두 번 누르면 시트', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPage(tester, [
        ago(0, [ExerciseBlock('벤치프레스', times(4, () => kg(80, 5)))]),
      ]);
      for (final m in frontRegions.where((m) => m != Muscle.hipFlexors)) {
        expect(
          find.semantics.byLabel(l.muscleName(m.name)),
          findsOne,
          reason: m.name,
        );
      }
      final chest = find.semantics.byLabel(l.muscleName('chest'));
      expect(
        chest.evaluate().single.value,
        l.anatomyRegionValue(7, '4', l.anatomyLevel('high')),
      );
      tester.semantics.tap(chest);
      await tester.pumpAndSettle();
      expect(find.text(l.anatomyDone), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('색 셈이 목록에 그대로: 주동 4세트, 보조 2세트', (tester) async {
      await pumpPage(tester, [
        ago(0, [ExerciseBlock('벤치프레스', times(4, () => kg(80, 5)))]),
      ]);
      String row(String sets, String level) =>
          '${l.anatomySets(7, sets)} · ${l.anatomyLevel(level)}';
      expect(find.text(row('4', 'high')), findsOneWidget);
      // 앞 어깨·삼두 둘 다 2세트(보조 4세트의 반).
      expect(find.text(row('2', 'mid')), findsNWidgets(2));
      expect(find.text(l.anatomyLegend), findsOneWidget);
      // 28일로 바꿔도 같은 기록이다.
      await tester.tap(find.text(l.anatomyDays(28)));
      await tester.pumpAndSettle();
      expect(
        find.text('${l.anatomySets(28, '4')} · ${l.anatomyLevel('high')}'),
        findsOneWidget,
      );
    });

    testWidgets('이 기간 기록이 없으면 그렇게 말한다', (tester) async {
      await pumpPage(tester, [
        ago(20, [
          ExerciseBlock('스쿼트', [kg(100, 5)]),
        ]),
      ]);
      expect(find.text(l.anatomyEmptyWindow(7)), findsOneWidget);
    });

    testWidgets('기구 거르기: 덤벨만 썼으면 바벨·머신·케이블·벤치 운동은 더 보기 뒤에', (tester) async {
      await pumpPage(tester, [
        ago(1, [ExerciseBlock('덤벨컬', times(3, () => kg(12, 10)))]),
      ]);
      await tester.tap(find.byKey(const ValueKey('anatomy-row-chest')));
      await tester.pumpAndSettle();
      expect(find.text('푸시업'), findsOneWidget);
      expect(find.text('덤벨 프레스'), findsNothing);
      expect(find.text('벤치프레스'), findsNothing);
      expect(
        find.text(
          l.anatomyTryGear(
            [l.routineGear('dumbbell'), l.routineGear('bodyweight')].join('·'),
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(l.anatomyMoreGear(8)));
      await tester.pumpAndSettle();
      expect(find.text('벤치프레스'), findsOneWidget);
      expect(find.text('덤벨 프레스'), findsOneWidget);
    });

    testWidgets('영어 밖 화면의 자세 팁은 영어 문장과 그렇다는 한 줄', (tester) async {
      await pumpPage(tester, [], locale: const Locale('ja'));
      final ja = lookupL(const Locale('ja'));
      await tester.tap(find.byKey(const ValueKey('anatomy-row-chest')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('anatomy-try:벤치프레스')));
      await tester.pumpAndSettle();
      expect(find.text('• ${moves['벤치프레스']!.cues.first.en}'), findsOneWidget);
      expect(find.textContaining(ja.anatomyCuesEnglish), findsOneWidget);
    });

    testWidgets('보이는 무게는 전부 내 세트에서 옮긴 것이다', (tester) async {
      final notes = defaultLog();
      final mine = mineWeights(notes);
      await pumpPage(tester, notes);
      final seen = <String>{};
      void collect() {
        for (final t in tester.widgetList<Text>(find.byType(Text))) {
          for (final m in _weight.allMatches(t.data ?? '')) {
            seen.add('${m[1]}${m[2]}');
          }
        }
      }

      collect();
      for (final front in [true, false]) {
        if (!front) {
          await tester.tap(find.text(l.anatomyBack));
          await tester.pumpAndSettle();
        }
        for (final m in front ? frontRegions : backRegions) {
          await tester.tap(find.byKey(ValueKey('anatomy-row-${m.name}')));
          await tester.pumpAndSettle();
          collect();
          await tester.tap(find.byKey(const ValueKey('anatomy-close')));
          await tester.pumpAndSettle();
        }
      }
      expect(seen, isNotEmpty);
      expect(seen.difference(mine), isEmpty);
      // 같이 한 사람의 140kg 는 내 것이 아니다.
      expect(seen, isNot(contains('140kg')));
    });
  });

  test('그림의 MIT 고지문을 라이선스에 싣는다', () async {
    registerArtworkLicense();
    final entries = await LicenseRegistry.licenses.toList();
    final art = entries.where(
      (e) => e.packages.any((p) => p.contains('MuscleMap')),
    );
    expect(art, hasLength(1));
    final text = art.single.paragraphs.map((p) => p.text).join('\n');
    expect(
      text,
      contains('Copyright (c) 2026 Jsplice / MuscleMap contributors'),
    );
    expect(text, contains('shall be included in all'));
  });

  testWidgets('설정의 오픈소스 라이선스 줄이 라이선스 화면을 연다', (tester) async {
    final store = NotesStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: SettingsPage(store: store),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(l.openSourceLicenses));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LicensePage), findsOneWidget);
  });

  group('홈으로 넘기기', () {
    Future<(_Records, int Function())> pumpHome(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(420, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var asked = 0;
      final store = _Records(relativeLog());
      addTearDown(store.dispose);
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: NotesListPage(
            store: store,
            onOpen: (_) {},
            ai: RecordAi(
              respond: (_, _) async {
                asked++;
                return {};
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(l.anatomyOpen));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('anatomy-row-chest')));
      await tester.pumpAndSettle();
      return (store, () => asked);
    }

    String searchText(WidgetTester tester) => tester
        .widget<CupertinoSearchTextField>(find.byType(CupertinoSearchTextField))
        .controller!
        .text;

    testWidgets('오늘 루틴에 넣기: 기존 루틴 카드로, 숫자는 내 마지막 세트, 모델 0', (tester) async {
      final (store, asked) = await pumpHome(tester);
      await tester.tap(find.byKey(const ValueKey('anatomy-done:벤치프레스')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.anatomyAddRoutine));
      await tester.pumpAndSettle();
      expect(find.byType(AnatomyPage), findsNothing);
      expect(searchText(tester), l.anatomyRoutineText(l.queryPart('chest')));
      expect(find.text(l.routineStart), findsOneWidget);
      await tester.tap(find.text(l.routineStart));
      await tester.pumpAndSettle();
      final bench = store.created.single.blocks.singleWhere(
        (b) => b.name == '벤치프레스',
      );
      // 9/7 벤치 60×10, 85×5 ×3 — 카드는 기록의 세트를 옮긴다.
      final logged = {
        for (final s
            in defaultLog()
                .expand((n) => n.blocks)
                .where((b) => b.name == '벤치프레스')
                .expand((b) => b.sets))
          (s.value, s.reps),
      };
      expect(bench.sets, isNotEmpty);
      for (final s in bench.sets) {
        // 비운 무게(null)는 있어도, 기록에 없는 무게는 없다.
        if (s.value != null) expect(logged, contains((s.value, s.reps)));
        expect(s.done, isFalse);
      }
      expect(asked(), 0);
    });

    testWidgets('안 해 본 운동을 넣으면 숫자 없는 칸', (tester) async {
      final (store, asked) = await pumpHome(tester);
      await tester.tap(find.byKey(const ValueKey('anatomy-try:케이블 크로스오버')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.anatomyAddRoutine));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.routineStart));
      await tester.pumpAndSettle();
      final cable = store.created.single.blocks.singleWhere(
        (b) => b.name == '케이블 크로스오버',
      );
      expect(cable.sets.where((s) => s.value != null), isEmpty);
      expect(asked(), 0);
    });

    testWidgets('검색에서 보기: 적은 이름이 검색칸에, 제출하지 않는다', (tester) async {
      final (_, asked) = await pumpHome(tester);
      await tester.tap(find.byKey(const ValueKey('anatomy-done:벤치프레스')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.anatomySearch));
      await tester.pumpAndSettle();
      expect(find.byType(AnatomyPage), findsNothing);
      expect(searchText(tester), '벤치프레스');
      expect(asked(), 0);
    });
  });

  // ─── 리뷰(내용·코드)에서 확인된 것을 고친다 ─────────────────────────────────
  group('리뷰 고침 — 표', () {
    test('업라이트 로우: 그립은 어깨너비나 조금 넓게(ExRx Safety), 좁은 그립은 피할 것', () {
      final m = moves['업라이트 로우']!;
      final cues = m.cues.map((c) => c.ko).join('\n');
      expect(cues, contains('조금 넓게'));
      expect(cues, isNot(contains('좁게')));
      expect(m.cues.map((c) => c.en).join('\n'), contains('slightly wider'));
      expect(
        m.cues.singleWhere((c) => c.ko.contains('몸 가까이')).basis,
        Basis.source,
      );
      expect(
        m.mistakes.singleWhere((c) => c.ko.contains('좁은 그립')).basis,
        Basis.source,
      );
      expect(m.mistakes.where((c) => c.ko.contains('불편한데도')), isEmpty);
    });

    test('파워클린은 셈에는 들지만 부위 추천에는 뜨지 않는다', () {
      for (final m in [
        Muscle.traps,
        Muscle.quads,
        Muscle.glutes,
        Muscle.hamstrings,
      ]) {
        final t = tryFor(m, {});
        expect([...t.shown, ...t.hidden], isNot(contains('파워클린')));
      }
      final load = bodyLoad(
        [
          ago(0, [
            ExerciseBlock('파워클린', [kg(60, 3)]),
          ]),
        ],
        today: today,
        days: 7,
      );
      expect(load.of(Muscle.quads), greaterThan(0));
      // 모든 부위에 추천할 운동이 남는다.
      for (final m in Muscle.values) {
        expect(tryFor(m, {}).shown, isNotEmpty, reason: m.name);
      }
    });

    test('사전 운동의 기구는 루틴 표 하나 — 봉·평행봉 운동은 봉을 쓴 사람에게만', () {
      final dict = {for (final e in exercises) e.ko};
      for (final k in moves.keys.where(dict.contains)) {
        expect(moveGear(k), [exerciseGear[k]], reason: k);
        expect(moves[k]!.gear, isEmpty, reason: '$k: 표를 둘로 두지 않는다');
      }
      expect(moveGear('시티드 로우'), ['cable']);
      expect(moveGear('버티컬 레그레이즈'), ['machine']);
      expect(moveGear('백 익스텐션'), ['machine']);
      final dumbbell = tryFor(Muscle.lats, {'덤벨컬'});
      expect(dumbbell.shown, isNot(contains('풀업')));
      expect(dumbbell.hidden, containsAll(['풀업', '친업']));
      expect(tryFor(Muscle.tricepsLong, {'덤벨컬'}).hidden, contains('딥스'));
      expect(tryFor(Muscle.lats, {'풀업'}).shown, contains('친업'));
    });

    test('기구가 여럿인 운동으로는 쓴 기구를 짐작하지 않는다', () {
      final lunge = tryFor(Muscle.chest, {'런지'});
      expect(lunge.gear, isEmpty);
      expect(lunge.shown, isNot(contains('벤치프레스')));
      expect(tryFor(Muscle.chest, {'파머스 워크'}).gear, isEmpty);
    });

    test('근육 배정이 해석인 운동은 표시가 있다', () {
      for (final k in [
        '바벨로우',
        '덤벨로우',
        '시티드 로우',
        '케이블 로우',
        '티바로우',
        '파워클린',
        '파머스 워크',
        '러시안 트위스트',
      ]) {
        expect(moves[k]!.primaryInterp, isTrue, reason: k);
      }
      for (final k in ['루마니안 데드리프트', '파워클린', '슈퍼맨', '러시안 트위스트']) {
        expect(moves[k]!.secondaryInterp, isTrue, reason: k);
      }
      expect(moves['벤치프레스']!.primaryInterp, isFalse);
      expect(moves['슈퍼맨']!.primaryInterp, isFalse);
    });

    test('팁 표시는 셋: 출처 있음 · 출처 문장에서 옮긴 해석 · 출처 없음', () {
      final all = [
        for (final m in moves.values) ...[...m.cues, ...m.mistakes],
      ];
      expect(all.where((c) => c.basis == Basis.adapted), hasLength(9));
      expect(
        moves['힙쓰러스트']!.mistakes.singleWhere((c) => c.ko.contains('과하게')).basis,
        Basis.adapted,
      );
      expect(all.where((c) => c.basis == Basis.none), isNotEmpty);
    });

    test('데드리프트: 허리 근육은 버티는(등척성) 역할이라고 적는다', () {
      final c = moves['데드리프트']!.cues.first;
      expect(c.ko, contains('등척성'));
      expect(c.basis, Basis.source);
    });

    test('티바로우 한국어가 뜻을 잃지 않는다', () {
      expect(
        moves['티바로우']!.mistakes.map((c) => c.ko),
        contains('끝까지 들려고 상체를 45°보다 더 세운다 — 그럴 땐 무게를 줄인다'),
      );
    });

    test('핵스쿼트·레그프레스: 같은 ExRx 페이지의 기계 안전 단계', () {
      expect(
        moves['핵스쿼트']!.cues.where(
          (c) => c.ko.contains('안전 레버') && c.basis == Basis.source,
        ),
        hasLength(1),
      );
      expect(
        moves['레그프레스']!.cues.where(
          (c) => c.ko.contains('안전 받침') && c.basis == Basis.source,
        ),
        hasLength(1),
      );
    });

    test('출처가 갈리는 주동은 합친다(ExRx + ACE)', () {
      expect(
        moves['해머컬']!.primary,
        containsAll([Muscle.forearms, Muscle.biceps]),
      );
      expect(moves['불가리안 스플릿 스쿼트']!.primary, contains(Muscle.glutes));
      expect(
        moves['레그프레스']!.primary,
        containsAll([Muscle.quads, Muscle.glutes, Muscle.hamstrings]),
      );
      expect(tryFor(Muscle.biceps, {}).shown, contains('해머컬'));
    });

    test('별칭은 하나씩 — 하이퍼익스텐션도 백 익스텐션으로 센다', () {
      expect(moveKey('하이퍼익스텐션'), '백 익스텐션');
      expect(moveKey('hyperextension'), '백 익스텐션');
      expect(moveKey('farmers carry'), '파머스 워크');
      expect(moveKey('파머스캐리'), '파머스 워크');
      expect(moveKey("captain's chair"), '버티컬 레그레이즈');
      expect(moveKey('facepull'), '페이스 풀');
      expect(moveKey('rear delt fly'), '리버스 펙덱');
      for (final m in moves.values) {
        for (final a in m.aliases) {
          expect(a.trim(), a);
          expect(a, isNotEmpty);
        }
      }
      final load = bodyLoad(
        [
          ago(0, [ExerciseBlock('하이퍼익스텐션', times(3, () => reps(12)))]),
        ],
        today: today,
        days: 7,
      );
      expect(load.unknown, isEmpty);
      expect(load.primary[Muscle.lowerBack], 3);
    });

    test('사전 밖 운동 이름: 한국어·영어 밖 화면은 영어 이름(번역 확인 전)', () {
      expect(moveName('파머스 워크', 'ja'), "Farmer's Walk");
      expect(moveName('슈퍼맨', 'vi'), 'Superman');
      expect(moveName('파머스 워크', 'ko'), '파머스 워크');
      expect(moveName('벤치프레스', 'ja'), exerciseByName['벤치프레스']!.ja);
    });

    test('머리말은 "흔한 실수" 가 아니라 "피할 것"', () {
      expect(l.anatomyMistakes, '피할 것');
      expect(lookupL(const Locale('en')).anatomyMistakes, 'Avoid');
      expect(l.anatomyCountNote, contains('ACE'));
    });
  });

  group('리뷰 고침 — 셈', () {
    test('내가 한 운동: 마지막 날의 블록을 모두 잇는다', () {
      final row = doneFor([
        ago(0, [
          ExerciseBlock('벤치프레스', times(3, () => kg(100, 3))),
          ExerciseBlock('벤치프레스', times(2, () => kg(70, 10))),
        ]),
      ], Muscle.chest).single;
      expect(row.sets, [
        ...times(
          3,
          () => kg(100, 3),
        ).map((s) => (value: s.value, unit: s.unit, reps: s.reps)),
        ...times(
          2,
          () => kg(70, 10),
        ).map((s) => (value: s.value, unit: s.unit, reps: s.reps)),
      ]);
    });

    test('같은 날 기록 둘: 시각 순으로 잇고 이름은 나중 것', () {
      Note at(int hour, List<ExerciseBlock> blocks) {
        final t = today.add(Duration(hours: hour));
        return Note(id: 'h$hour', createdAt: t, updatedAt: t, blocks: blocks);
      }

      final morning = at(8, [ExerciseBlock('벤치', times(3, () => kg(60, 10)))]);
      final evening = at(20, [
        ExerciseBlock('벤치프레스', times(3, () => kg(90, 3))),
      ]);
      // 가게 순서는 고친 시각 역순이다 — 아침 기록이 나중에 고쳐졌을 수 있다.
      final row = doneFor([morning, evening], Muscle.chest).single;
      expect(row.name, '벤치프레스');
      expect(row.sets.map((s) => s.value), [60, 60, 60, 90, 90, 90]);
    });

    test('moveKey 는 이름마다 한 번만 푼다(같은 답)', () {
      expect(moveKey('벤치'), moveKey('벤치'));
      expect(moveKey('Face Pull'), '페이스 풀');
    });
  });

  group('리뷰 고침 — 화면', () {
    Future<void> pumpPage(WidgetTester tester, List<Note> notes) async {
      tester.view
        ..physicalSize = const Size(420, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: AnatomyPage(notes: notes, now: routineToday),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapArt(WidgetTester tester, bool front, Offset art) async {
      final box = tester.getRect(find.byKey(const ValueKey('anatomy-figure')));
      await tester.tapAt(box.topLeft + figurePoint(front, box.size, art));
      await tester.pumpAndSettle();
    }

    Finder header(Muscle m) =>
        find.text('${l.muscleName(m.name)} · ${l.queryPart(muscleCoarse[m]!)}');

    testWidgets('등 쪽: 날개뼈 사이는 등 가운데(로우), 목 옆은 승모근 윗부분', (tester) async {
      await pumpPage(tester, []);
      await tester.tap(find.text(l.anatomyBack));
      await tester.pumpAndSettle();
      for (final p in const [Offset(480, 420), Offset(485, 480)]) {
        await tapArt(tester, false, p);
        expect(header(Muscle.upperBack), findsOneWidget, reason: '$p');
        expect(find.text('바벨로우 *'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('anatomy-close')));
        await tester.pumpAndSettle();
      }
      await tapArt(tester, false, const Offset(470, 280));
      expect(header(Muscle.traps), findsOneWidget);
    });

    testWidgets('근육 배정이 해석이면 역할 옆에 *, 출처 문장에서 옮긴 팁은 †', (tester) async {
      await pumpPage(tester, [
        ago(0, [
          ExerciseBlock('바벨로우', times(3, () => kg(60, 8))),
          // 힙쓰러스트는 벤치에 등을 댄다 — 벤치를 쓴 기록이 있어야 접히지 않는다.
          ExerciseBlock('벤치프레스', times(3, () => kg(60, 8))),
        ]),
      ]);
      expect(find.text(l.anatomyCountNote), findsOneWidget);
      await tester.tap(find.text(l.anatomyBack));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('anatomy-row-lats')));
      await tester.pumpAndSettle();
      expect(find.text('바벨로우 *'), findsOneWidget);
      expect(
        find.text(l.anatomyRole('primary')),
        findsWidgets,
        reason: '역할은 이름 옆 표지로',
      );
      expect(find.text(l.anatomyInterpNote), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('anatomy-close')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('anatomy-row-glutes')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('anatomy-try:힙쓰러스트')));
      await tester.pumpAndSettle();
      expect(find.text(l.anatomyMistakes), findsOneWidget);
      expect(find.text('• 엉덩이를 과하게 올려 허리가 꺾인다 †'), findsOneWidget);
      expect(find.textContaining(l.anatomyAdapted), findsOneWidget);
    });

    testWidgets('표에 없는 이름만 있으면 "표의 운동으로는 기록 없음" 과 그 이름들, 이름으로 검색하게 한다', (
      tester,
    ) async {
      AnatomyHandoff? got;
      tester.view
        ..physicalSize = const Size(420, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () async =>
                  got = await Navigator.of(context).push<AnatomyHandoff>(
                    CupertinoPageRoute(
                      builder: (_) => AnatomyPage(
                        notes: [
                          ago(0, [
                            ExerciseBlock(
                              '랫 풀 다운 머신',
                              times(4, () => kg(50, 10)),
                            ),
                          ]),
                        ],
                        now: routineToday,
                      ),
                    ),
                  ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.anatomyBack));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('anatomy-row-lats')));
      await tester.pumpAndSettle();
      expect(find.text(l.anatomyNever), findsOneWidget);
      expect(find.text(l.anatomyUnknown(1)), findsNWidgets(2));
      await tester.tap(
        find.byKey(const ValueKey('anatomy-unknown:랫 풀 다운 머신')).last,
      );
      await tester.pumpAndSettle();
      expect(find.byType(AnatomyPage), findsNothing);
      expect(got?.search, '랫 풀 다운 머신');
    });

    testWidgets('모르는 이름이 다섯 개를 넘으면 몇 개 더인지 말한다', (tester) async {
      await pumpPage(tester, [
        ago(0, [
          for (var i = 0; i < 7; i++) ExerciseBlock('민수식 운동$i', [kg(10, 10)]),
        ]),
      ]);
      expect(find.text(l.anatomyUnknown(7)), findsOneWidget);
      expect(find.text(l.anatomyUnknownMore(2)), findsOneWidget);
    });

    testWidgets('VoiceOver: 그림은 빠지고 목록 줄이 부위마다 한 버튼', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPage(tester, [
        ago(0, [ExerciseBlock('벤치프레스', times(4, () => kg(80, 5)))]),
      ]);
      final figure = tester.getRect(
        find.byKey(const ValueKey('anatomy-figure')),
      );
      for (final m in frontRegions) {
        final node = find.semantics.byLabel(l.muscleName(m.name));
        expect(node, findsOne, reason: m.name);
        final rect = tester.getRect(
          find.byKey(ValueKey('anatomy-row-${m.name}')),
        );
        // 노드는 목록 줄 자리다 — 그림 위에서 서로 겹치는 사각형이 없다.
        expect(rect.overlaps(figure), isFalse, reason: m.name);
      }
      semantics.dispose();
    });
  });

  group('리뷰 고침 — 홈으로 넘기기', () {
    Future<_Records> pumpHome(WidgetTester tester, {List<Note>? notes}) async {
      tester.view
        ..physicalSize = const Size(420, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = _Records(notes ?? relativeLog());
      addTearDown(store.dispose);
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: NotesListPage(
            store: store,
            onOpen: (_) {},
            ai: RecordAi(respond: (_, _) async => {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return store;
    }

    Future<void> add(WidgetTester tester, Muscle m, String id) async {
      await tester.tap(find.bySemanticsLabel(l.anatomyOpen));
      await tester.pumpAndSettle();
      if (!frontRegions.contains(m)) {
        await tester.tap(find.text(l.anatomyBack));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(ValueKey('anatomy-row-${m.name}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('anatomy-$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.anatomyAddRoutine));
      await tester.pumpAndSettle();
    }

    String searchText(WidgetTester tester) => tester
        .widget<CupertinoSearchTextField>(find.byType(CupertinoSearchTextField))
        .controller!
        .text;

    List<String> names(Note n) => [for (final b in n.blocks) b.name];

    testWidgets('시작한 뒤 또 넣으면 그 기록에 붙는다 — 기록은 하나', (tester) async {
      final store = await pumpHome(tester);
      await add(tester, Muscle.chest, 'done:벤치프레스');
      await tester.tap(find.text(l.routineStart));
      await tester.pumpAndSettle();
      await add(tester, Muscle.chest, 'try:케이블 크로스오버');
      await tester.tap(find.text(l.routineStarted));
      await tester.pumpAndSettle();
      expect(store.created, hasLength(1));
      final got = names(store.created.single);
      expect(got, contains('케이블 크로스오버'));
      expect(got.where((n) => n == '벤치프레스'), hasLength(1));
    });

    testWidgets('다른 부위에서 넣어도 앞에 넣은 것이 남는다(검색칸을 비웠다 와도)', (tester) async {
      final store = await pumpHome(tester);
      await add(tester, Muscle.chest, 'done:벤치프레스');
      await tester.enterText(find.byType(CupertinoSearchTextField), '');
      await tester.pumpAndSettle();
      await add(tester, Muscle.tricepsLong, 'try:딥스');
      expect(
        searchText(tester),
        l.anatomyRoutineText('${l.queryPart('chest')}·${l.queryPart('arms')}'),
      );
      await tester.tap(find.text(l.routineStart));
      await tester.pumpAndSettle();
      expect(names(store.created.single), containsAll(['벤치프레스', '딥스']));
    });

    testWidgets('✕ 로 뺀 운동을 몸 그림에서 다시 넣으면 들어간다', (tester) async {
      final store = await pumpHome(tester);
      await add(tester, Muscle.chest, 'try:케이블 크로스오버');
      final row = find
          .ancestor(
            of: find.text('케이블 크로스오버').first,
            matching: find.byType(Row),
          )
          .first;
      await tester.tap(
        find.descendant(of: row, matching: find.bySemanticsLabel(l.delete)),
      );
      await tester.pumpAndSettle();
      await add(tester, Muscle.chest, 'try:케이블 크로스오버');
      await tester.tap(find.text(l.routineStart));
      await tester.pumpAndSettle();
      expect(names(store.created.single), contains('케이블 크로스오버'));
    });

    testWidgets('몸 그림 버튼은 몸 모양, 기록이 없으면 첫 화면에서도 고른다', (tester) async {
      await pumpHome(tester, notes: []);
      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is Icon && w.semanticLabel == l.anatomyOpen,
          ),
          matching: find.byType(Icon),
          matchRoot: true,
        ),
      );
      expect(icon.icon, Icons.accessibility_new);
      await tester.tap(find.text(l.anatomyPick));
      await tester.pumpAndSettle();
      expect(find.byType(AnatomyPage), findsOneWidget);
    });
  });

  // ─── 두 번째 리뷰(독립 검증)에서 확인된 것을 고친다 ────────────────────────────
  group('리뷰2 — 오늘 루틴에 넣기', () {
    late List<Note> opened;
    Future<_Records> pumpHome(WidgetTester tester, {List<Note>? notes}) async {
      opened = [];
      tester.view
        ..physicalSize = const Size(420, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = _Records(notes ?? relativeLog());
      addTearDown(store.dispose);
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: NotesListPage(
            store: store,
            onOpen: opened.add,
            ai: RecordAi(respond: (_, _) async => {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return store;
    }

    Future<void> add(WidgetTester tester, Muscle m, String id) async {
      await tester.tap(find.bySemanticsLabel(l.anatomyOpen));
      await tester.pumpAndSettle();
      if (!frontRegions.contains(m)) {
        await tester.tap(find.text(l.anatomyBack));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(ValueKey('anatomy-row-${m.name}')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(ValueKey('anatomy-$id')));
      await tester.tap(find.byKey(ValueKey('anatomy-$id')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l.anatomyAddRoutine));
      await tester.tap(find.text(l.anatomyAddRoutine));
      await tester.pumpAndSettle();
    }

    String searchText(WidgetTester tester) => tester
        .widget<CupertinoSearchTextField>(find.byType(CupertinoSearchTextField))
        .controller!
        .text;
    List<String> names(Note n) => [for (final b in n.blocks) b.name];
    List<String> cardTexts(WidgetTester tester) => [
      for (final t in tester.widgetList<Text>(
        find.descendant(
          of: find.byType(RoutineCard),
          matching: find.byType(Text),
        ),
      ))
        t.data ?? '',
    ];
    // 카드 칸의 제목: 번호(1, 2, …) 바로 뒤의 글.
    List<String> cardTitles(WidgetTester tester) {
      final t = cardTexts(tester);
      final out = <String>[];
      for (var i = 0; i + 1 < t.length; i++) {
        if (t[i] == '${out.length + 1}') out.add(t[++i]);
      }
      return out;
    }

    Future<void> removeOnCard(WidgetTester tester, String name) async {
      final row = find
          .ancestor(of: find.text(name).first, matching: find.byType(Row))
          .first;
      await tester.tap(
        find.descendant(of: row, matching: find.bySemanticsLabel(l.delete)),
      );
      await tester.pumpAndSettle();
    }

    String wanted(String id) => id.substring(id.indexOf(':') + 1);
    final chestOnly = [
      (Muscle.chest, 'done:벤치프레스'),
      (Muscle.chest, 'try:케이블 크로스오버'),
      (Muscle.chest, 'try:펙덱 플라이'),
      (Muscle.chest, 'try:체스트 프레스'),
    ];
    final mixed = [
      (Muscle.chest, 'done:벤치프레스'),
      (Muscle.tricepsLong, 'try:딥스'),
      (Muscle.rearDelts, 'try:리버스 펙덱'),
      (Muscle.rearDelts, 'try:페이스 풀'),
      (Muscle.chest, 'try:케이블 크로스오버'),
    ];

    for (final (label, seq) in [('같은 부위', chestOnly), ('여러 부위', mixed)]) {
      testWidgets('넣은 운동 ${seq.length}개($label, 시작 전): 첫 운동도 카드·기록에 남고, '
          '평소보다 많다고 한 줄', (tester) async {
        final store = await pumpHome(tester);
        for (final (m, id) in seq) {
          await add(tester, m, id);
        }
        final want = [for (final (_, id) in seq) wanted(id)];
        expect(cardTitles(tester), containsAll(want));
        // fixture 의 최근 28일 한 번에 한 운동 수(중앙값)는 3개다.
        // 카드의 줄들은 한 글에 줄바꿈으로 모인다.
        expect(
          find.textContaining(l.routineOverUsual(want.length, 3)),
          findsOneWidget,
        );
        await tester.tap(find.text(l.routineStart));
        await tester.pumpAndSettle();
        expect(names(store.created.single), containsAll(want));
      });

      testWidgets('넣은 운동 ${seq.length}개($label, 시작 뒤): 기록 하나에 모두, '
          '카드는 그 기록 그대로', (tester) async {
        final store = await pumpHome(tester);
        await add(tester, seq.first.$1, seq.first.$2);
        await tester.tap(find.text(l.routineStart));
        await tester.pumpAndSettle();
        for (final (m, id) in seq.skip(1)) {
          await add(tester, m, id);
        }
        expect(store.created, hasLength(1));
        final record = store.created.single;
        expect(
          names(record),
          containsAll([for (final (_, id) in seq) wanted(id)]),
        );
        expect(names(record).where((n) => n == '벤치프레스'), hasLength(1));
        // 카드는 시작한 기록의 칸을 그 순서대로 보인다(몸 그림에서 붙인 칸까지).
        expect(cardTitles(tester), names(record));
        // 넣은 것이 평소 크기를 채워 초안에서 빠진 칸(푸시업)도 기록에 있으니 보이되,
        // ✕ 는 없다 — 눌러도 바뀔 것이 없다(기록에서 뺀다).
        final pushup = find
            .ancestor(
              of: find.text('푸시업 60bpm').first,
              matching: find.byType(Row),
            )
            .first;
        expect(
          find.descendant(
            of: pushup,
            matching: find.bySemanticsLabel(l.delete),
          ),
          findsNothing,
        );
        expect(find.text(l.routineStarted), findsOneWidget);
        await tester.tap(find.text(l.routineStarted));
        await tester.pumpAndSettle();
        expect(store.created, hasLength(1));
        expect(opened.last.id, record.id);
      });
    }

    testWidgets('시작 뒤 다른 부위를 넣으면 글도 그 부위까지(기록에 든 부위)', (tester) async {
      await pumpHome(tester);
      await add(tester, Muscle.chest, 'done:벤치프레스');
      await tester.tap(find.text(l.routineStart));
      await tester.pumpAndSettle();
      await add(tester, Muscle.tricepsLong, 'try:딥스');
      expect(
        searchText(tester),
        l.anatomyRoutineText('${l.queryPart('chest')}·${l.queryPart('arms')}'),
      );
      expect(find.text(l.routineStarted), findsOneWidget);
    });

    testWidgets('시작 뒤 ✕ 로 카드를 바꾸면 새 루틴 — 몸 그림으로 넣어도 시작한 기록인 척하지 않고 '
        '그 기록을 바꾸지 않는다', (tester) async {
      final store = await pumpHome(tester);
      await add(tester, Muscle.chest, 'done:벤치프레스');
      await tester.tap(find.text(l.routineStart));
      await tester.pumpAndSettle();
      final before = names(store.created.single);
      expect(before, contains('덤벨 프레스'));
      await removeOnCard(tester, '덤벨 프레스');
      await add(tester, Muscle.chest, 'try:케이블 크로스오버');
      expect(names(store.created.single), before);
      expect(find.text(l.routineStarted), findsNothing);
      expect(find.text(l.routineStart), findsOneWidget);
      expect(
        find.text(l.routineRemoved('덤벨 프레스', l.routineRemovedWhy('user'))),
        findsOneWidget,
      );
      expect(cardTitles(tester), isNot(contains('덤벨 프레스')));
      expect(cardTitles(tester), contains('케이블 크로스오버'));
    });

    Future<void> typedChestCard(WidgetTester tester) async {
      await tester.enterText(
        find.byType(CupertinoSearchTextField),
        l.anatomyRoutineText(l.queryPart('chest')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.routineMakePart(l.queryPart('chest'))));
      await tester.pumpAndSettle();
      await removeOnCard(tester, '덤벨 프레스');
    }

    final userRemoved = l.routineRemoved('덤벨 프레스', l.routineRemovedWhy('user'));

    testWidgets('친 글 카드의 ✕ 는 몸 그림으로 넣어도 남는다', (tester) async {
      final store = await pumpHome(tester);
      await typedChestCard(tester);
      expect(find.text(userRemoved), findsOneWidget);
      await add(tester, Muscle.chest, 'try:케이블 크로스오버');
      expect(find.text(userRemoved), findsOneWidget);
      expect(cardTitles(tester), isNot(contains('덤벨 프레스')));
      await tester.tap(find.text(l.routineStart));
      await tester.pumpAndSettle();
      expect(names(store.created.single), isNot(contains('덤벨 프레스')));
      expect(names(store.created.single), contains('케이블 크로스오버'));
    });

    testWidgets('친 글 카드로 시작한 뒤 몸 그림으로 넣으면 그 기록에 — ✕ 줄도 남고 기록은 하나', (
      tester,
    ) async {
      final store = await pumpHome(tester);
      await typedChestCard(tester);
      await tester.tap(find.text(l.routineStart));
      await tester.pumpAndSettle();
      await add(tester, Muscle.chest, 'try:케이블 크로스오버');
      expect(store.created, hasLength(1));
      expect(names(store.created.single), contains('케이블 크로스오버'));
      expect(names(store.created.single), isNot(contains('덤벨 프레스')));
      expect(find.text(userRemoved), findsOneWidget);
      expect(cardTitles(tester), names(store.created.single));
      await tester.tap(find.text(l.routineStarted));
      await tester.pumpAndSettle();
      expect(store.created, hasLength(1));
    });

    testWidgets('시트에 보인 마지막 날 세트 = 카드 = 시작한 기록(그날 블록 모두, 내 세트)', (
      tester,
    ) async {
      final at = DateTime.now().subtract(const Duration(days: 1));
      final store = await pumpHome(
        tester,
        notes: [
          Note(
            id: 'two',
            createdAt: at,
            updatedAt: at,
            blocks: [
              ExerciseBlock('벤치프레스', times(3, () => kg(100, 3))),
              ExerciseBlock('벤치프레스', [
                ...times(2, () => kg(70, 10)),
                kg(120, 1, author: '민수'),
                kg(60, 12, done: false),
              ]),
            ],
          ),
          ...relativeLog(),
        ],
      );
      const shown = '100kg×3 ×3 · 70kg×10 ×2';
      await tester.tap(find.bySemanticsLabel(l.anatomyOpen));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('anatomy-row-chest')));
      await tester.pumpAndSettle();
      expect(find.textContaining(shown), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('anatomy-done:벤치프레스')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.anatomyAddRoutine));
      await tester.pumpAndSettle();
      expect(cardTexts(tester).where((t) => t == shown), hasLength(1));
      await tester.tap(find.text(l.routineStart));
      await tester.pumpAndSettle();
      final bench = store.created.single.blocks.singleWhere(
        (b) => b.name == '벤치프레스',
      );
      expect(
        setsText(l, [
          for (final s in bench.sets)
            (value: s.value, unit: s.unit, reps: s.reps),
        ]),
        shown,
      );
      expect(bench.sets.every((s) => !s.done), isTrue);
    });
  });

  group('리뷰2 — 시트', () {
    Future<void> pumpPage(WidgetTester tester, List<Note> notes) async {
      tester.view
        ..physicalSize = const Size(420, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: AnatomyPage(notes: notes, now: routineToday),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('근육 배정 해석(*)과 출처 없는 팁(‡)은 다른 표시, 각주도 따로', (tester) async {
      // 바벨로우: 주동 배정이 해석이고, 피할 것에 출처 없는 줄이 있다 — 한 시트에 둘 다.
      expect(moves['바벨로우']!.primaryInterp, isTrue);
      final unsourced = [
        ...moves['바벨로우']!.cues,
        ...moves['바벨로우']!.mistakes,
      ].firstWhere((c) => c.basis == Basis.none);
      await pumpPage(tester, [
        ago(0, [ExerciseBlock('바벨로우', times(3, () => kg(60, 8)))]),
      ]);
      await tester.tap(find.text(l.anatomyBack));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('anatomy-row-lats')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('anatomy-done:바벨로우')));
      await tester.pumpAndSettle();
      expect(find.text('바벨로우 *'), findsOneWidget);
      expect(
        find.text(l.anatomyRole('primary')),
        findsWidgets,
        reason: '역할은 이름 옆 표지로',
      );
      expect(find.text('• ${unsourced.ko} ‡'), findsOneWidget);
      expect(find.text('• ${unsourced.ko} *'), findsNothing);
      expect(find.text(l.anatomyInterpNote), findsOneWidget);
      expect(find.textContaining(l.anatomyUnsourced), findsOneWidget);
      expect(l.anatomyInterpNote, startsWith('*'));
      expect(l.anatomyUnsourced, startsWith('‡'));
      for (final loc in L.supportedLocales) {
        final x = lookupL(loc);
        expect(x.anatomyUnsourced, startsWith('‡'), reason: '$loc');
        expect(x.anatomyUnsourced, isNot(contains('*')), reason: '$loc');
        expect(x.anatomyInterpNote, startsWith('*'), reason: '$loc');
      }
    });

    testWidgets('표의 운동 기록이 없고 모르는 이름만 있으면 두 줄: 이 부위 기록 없음 + 모르는 이름', (
      tester,
    ) async {
      await pumpPage(tester, [
        ago(0, [
          ExerciseBlock('요가 스트레칭', [LoggedSet(value: 20, unit: 'min')]),
        ]),
      ]);
      await tester.tap(find.byKey(const ValueKey('anatomy-row-calves')));
      await tester.pumpAndSettle();
      expect(find.text(l.anatomyNever), findsOneWidget);
      // 그림 아래 한 줄 + 시트 한 줄.
      expect(find.text(l.anatomyUnknown(1)), findsNWidgets(2));
    });
  });

  group('리뷰2 — 기구', () {
    test('벤치가 있어야 하는 운동은 몸 그림에서도 벤치 — 루틴 표(benchExercises) 하나', () {
      for (final k in benchExercises) {
        expect(moves.containsKey(k), isTrue, reason: k);
      }
      // 몸 그림 팁이 벤치에 몸을 받치게 하는 운동은 루틴도 벤치 운동으로 본다.
      expect(benchExercises, containsAll(['덤벨로우', '킥백']));
      // 불가리안 스플릿 스쿼트는 맨몸이지만 뒷발을 벤치에 올린다. 맨몸만 한 사람(벤치
      // 기록 없음)에게는 접히고, 벤치 운동을 한 사람에게는 보인다.
      expect(tryFor(Muscle.quads, {'런지'}).hidden, contains('불가리안 스플릿 스쿼트'));
      expect(
        tryFor(Muscle.quads, {'런지'}).shown,
        isNot(contains('불가리안 스플릿 스쿼트')),
      );
      final bench = tryFor(Muscle.quads, {'런지', '덤벨 프레스'});
      expect(bench.shown, contains('불가리안 스플릿 스쿼트'));
      expect(bench.gear, contains('bench'));
    });

    testWidgets('해 볼 운동 줄의 기구에 벤치까지', (tester) async {
      tester.view
        ..physicalSize = const Size(420, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: AnatomyPage(notes: const [], now: routineToday),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('anatomy-row-quads')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('anatomy-try:불가리안 스플릿 스쿼트')),
          matching: find.text(
            '${l.routineGear('bodyweight')}·${l.routineGear('bench')}',
          ),
        ),
        findsOneWidget,
      );
    });
  });
}
