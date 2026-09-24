import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show LicenseRegistry;
import 'package:flutter/material.dart' show LicensePage;
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
        expect(m.gear, isNotEmpty, reason: e.key);
        expect(m.cues, isNotEmpty, reason: e.key);
        expect(m.mistakes, isNotEmpty, reason: e.key);
        expect(m.sites, isNotEmpty, reason: e.key);
        for (final c in [...m.cues, ...m.mistakes]) {
          expect(c.ko.trim(), isNotEmpty);
          expect(c.en.trim(), isNotEmpty);
        }
      }
    });

    test('모든 부위에 주동 운동이 있다 — 누르면 빈 목록이 없다', () {
      for (final m in Muscle.values) {
        expect(
          moves.values.where((v) => v.primary.contains(m)),
          isNotEmpty,
          reason: m.name,
        );
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
      expect(load.of(Muscle.triceps), 2);
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
    test('덤벨만 쓴 사람의 가슴: 덤벨·맨몸만 보이고 나머지는 접힌다', () {
      final t = tryFor(Muscle.chest, {'덤벨컬'});
      expect(t.allGear, isFalse);
      expect(t.shown, ['덤벨 프레스', '인클라인 덤벨 프레스', '푸시업']);
      expect(t.hidden, hasLength(6));
      expect(t.hidden, contains('벤치프레스'));
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
      Finder header(String m) => find.text(
        '${l.muscleName(m)} · ${l.queryPart(muscleCoarse[Muscle.values.byName(m)]!)}',
      );
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

    testWidgets('기구 거르기: 덤벨만 썼으면 바벨·머신·케이블은 더 보기 뒤에', (tester) async {
      await pumpPage(tester, [
        ago(1, [ExerciseBlock('덤벨컬', times(3, () => kg(12, 10)))]),
      ]);
      await tester.tap(find.byKey(const ValueKey('anatomy-row-chest')));
      await tester.pumpAndSettle();
      expect(find.text('덤벨 프레스'), findsOneWidget);
      expect(find.text('푸시업'), findsOneWidget);
      expect(find.text('벤치프레스'), findsNothing);
      expect(
        find.text(
          l.anatomyTryGear(
            [l.routineGear('dumbbell'), l.routineGear('bodyweight')].join('·'),
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(l.anatomyMoreGear(6)));
      await tester.pumpAndSettle();
      expect(find.text('벤치프레스'), findsOneWidget);
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
}
