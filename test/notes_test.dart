import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/handoff.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/partner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('대신 적기가 딸린 내 기록은 다시 불러와도 오늘 기록으로 이어진다', () async {
    final dir = Directory.systemTemp.createTempSync('setpad-notes-');
    final store = NotesStore(directory: dir);
    final restored = NotesStore(directory: dir);
    addTearDown(() {
      store.dispose();
      restored.dispose();
      dir.deleteSync(recursive: true);
    });
    final today = DateTime(2026, 10, 1, 18);
    final mine =
        store.create(
            at: today,
            blocks: [
              ExerciseBlock('벤치프레스', [LoggedSet(value: 60, reps: 10)]),
            ],
          )
          ..proxy = ProxyRecord(
            name: '준',
            blocks: [
              ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 8)]),
            ],
          );
    store.create(at: today.add(const Duration(hours: 1))).proxy = ProxyRecord(
      name: '소라',
      blocks: [
        ExerciseBlock('풀업', [LoggedSet(reps: 5)]),
      ],
    );
    await store.flush();
    await restored.load();

    final resumed = restored.today(now: today.add(const Duration(hours: 2)));
    expect(resumed.id, mine.id);
    expect(restored.notes, hasLength(2));
    expect(resumed.blocks.single.name, '벤치프레스');
    expect(resumed.proxy!.blocks.single.name, '스쿼트');
  });

  test('지난 기록에 늦게 넣은 끼니는 그 기록의 날로 간다', () {
    final at = DateTime(2026, 9, 30, 19);
    final note = Note(id: 'n', createdAt: at, updatedAt: at);
    final now = DateTime(2026, 10, 1, 8, 5);
    expect(note.mealTime(now), DateTime(2026, 9, 30, 8, 5));
    expect(Note(id: 't', createdAt: now, updatedAt: now).mealTime(now), now);
  });

  test('받은 루틴 기록은 세트 없이 끼니·대신 적기만 해도 지우지 않는다', () {
    final store = NotesStore(directory: Directory.systemTemp);
    addTearDown(store.dispose);
    // 열어만 본 루틴은 지운다 — 받은 루틴은 목록에 그대로 있다.
    final opened = store.create(gymId: 'g', routineId: 'r1');
    store.discardIfEmpty(opened);
    expect(store.notes, isNot(contains(opened)));

    // 끼니·대신 적기는 touch() 로만 저장돼 updatedAt 이 안 움직인다.
    final meal = store.create(gymId: 'g', routineId: 'r2')
      ..meals.add(MealEntry(at: DateTime(2026, 10, 1, 12), kcal: 650));
    store.touch();
    store.discardIfEmpty(meal);
    expect(store.notes, contains(meal));

    final proxy = store.create(gymId: 'g', routineId: 'r3')
      ..proxy = ProxyRecord(name: '준');
    store.touch();
    store.discardIfEmpty(proxy);
    expect(store.notes, contains(proxy));

    // 스티커로 연 루틴은 열어만 봐도 출석이다 — 못 보냈으면 남아 있다가 간다.
    final tagged = store.create(gymId: 'g', routineId: 'r4')..checkedIn = true;
    store.discardIfEmpty(tagged);
    expect(store.notes, contains(tagged));
  });

  test('보낸 빈 출석 기록은 세 시간 동안 남고, 지나면 치운다', () {
    final store = NotesStore(directory: Directory.systemTemp);
    addTearDown(store.dispose);
    // 방금 대고 나왔다. 다시 대면 이것을 다시 열어야 같은 방문이 둘로 안 센다.
    final now = store.create(gymId: 'g')..sentAt = DateTime.now();
    store.discardIfEmpty(now);
    expect(store.notes, contains(now));
    store.pruneVisits();
    expect(store.notes, contains(now));

    // 네 시간 전에 보낸 빈 출석은 목록에서 치운다.
    final fourHoursAgo = DateTime.now().subtract(const Duration(hours: 4));
    final old = store.create(gymId: 'g', at: fourHoursAgo)
      ..sentAt = fourHoursAgo;
    store.pruneVisits();
    expect(store.notes, isNot(contains(old)));
    expect(store.notes, contains(now));
  });

  test('스티커를 다시 대면 세 시간 안의 내 방문을 열고, 다른 계정의 방문은 열지 않는다', () {
    final store = NotesStore(directory: Directory.systemTemp);
    addTearDown(store.dispose);
    final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final a = store.create(gymId: 'g', at: hourAgo)
      ..owner = 'A'
      ..sentAt = hourAgo;
    expect(store.openVisit('g', 'A'), a);
    expect(store.openVisit('g', 'B'), isNull, reason: 'B 의 출석이 따로 생겨야 한다');
    // 표시가 생기기 전의 방문은 예전처럼 다시 연다.
    final legacy = store.create(gymId: 'h', at: hourAgo);
    expect(store.openVisit('h', 'B'), legacy);
  });

  test('그물 없이 끝낸 같이 하기가 남은 빈 기록은 지우지 않는다', () {
    final store = NotesStore(directory: Directory.systemTemp);
    addTearDown(store.dispose);
    final note = store.create()
      ..partner = PartnerSession(id: 's', host: true, state: PartnerState.ended)
      ..partner!.endPending = true;
    store.discardIfEmpty(note);
    expect(store.notes, contains(note), reason: '지우면 상대 폰에서 세션이 안 끝난다');
  });

  test('열려 있는 출석 기록과, 끼니 삭제·대신 적기가 남은 빈 기록은 치우지 않는다', () {
    final store = NotesStore(directory: Directory.systemTemp);
    addTearDown(store.dispose);
    final fourHoursAgo = DateTime.now().subtract(const Duration(hours: 4));
    final opened = store.create(gymId: 'g', at: fourHoursAgo)..sentAt = fourHoursAgo;
    store.open.add(opened);
    store.pruneVisits();
    expect(store.notes, contains(opened), reason: '편집기가 쥐고 있다');
    store.open.remove(opened);

    final pendingDelete = store.create(gymId: 'g', at: fourHoursAgo)
      ..sentAt = fourHoursAgo
      ..deletedMeals.add('meal-1');
    store.discardIfEmpty(pendingDelete);
    store.pruneVisits();
    expect(store.notes, contains(pendingDelete), reason: '서버에 알릴 끼니 삭제가 남았다');

    final proxyOnly = store.create(gymId: 'g', at: fourHoursAgo)
      ..sentAt = fourHoursAgo
      ..proxy = ProxyRecord(name: '준');
    store.discardIfEmpty(proxyOnly);
    expect(store.notes, contains(proxyOnly), reason: '대신 적은 것이 있다');
  });

  test('스티커로 연 루틴의 블록을 다 지우고 닫았으면 세 시간 뒤에 치운다', () {
    final store = NotesStore(directory: Directory.systemTemp);
    addTearDown(store.dispose);
    final fourHoursAgo = DateTime.now().subtract(const Duration(hours: 4));
    final emptied = store.create(gymId: 'g', routineId: 'r', at: fourHoursAgo)
      ..checkedIn = true
      ..sentAt = fourHoursAgo;
    store.pruneVisits();
    expect(store.notes, isNot(contains(emptied)));

    // 열어만 본 루틴은 블록이 차 있다 — 치우지 않는다.
    final looked = store.create(
      gymId: 'g',
      routineId: 'r2',
      at: fourHoursAgo,
      blocks: [ExerciseBlock('스쿼트', [LoggedSet(value: 60, reps: 5, done: false)])],
    )
      ..checkedIn = true
      ..sentAt = fourHoursAgo;
    store.pruneVisits();
    expect(store.notes, contains(looked));
  });

  test(
    'repeated exercise names stay concise while all completed sets count',
    () {
      final note = Note(
        id: 'test',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        blocks: [
          ExerciseBlock('벤치프레스', [LoggedSet(reps: 10)]),
          ExerciseBlock('스쿼트', [LoggedSet(reps: 10, done: false)]),
          ExerciseBlock('벤치프레스', [LoggedSet(reps: 8)]),
        ],
      );
      expect(note.title, '벤치프레스 · 스쿼트');
      expect(
        note.summary(setOrdinal: (n) => '$n세트', reps: (n) => '$n회'),
        '2세트',
      );
      expect(note.blocks, hasLength(3));
    },
  );

  group('notes.json 이 상해도 기록을 잃지 않는다', () {
    late Directory dir;
    setUp(
      () => dir = Directory.systemTemp.createTempSync('setpad-notes-safe-'),
    );
    tearDown(() => dir.deleteSync(recursive: true));

    File notesFile() => File('${dir.path}/notes.json');
    List<File> backups() => [
      for (final f in dir.listSync().whereType<File>())
        if (f.path.contains('notes.json.bak-')) f,
    ];

    test('못 읽는 기록 하나는 그것만 빠지고, 오늘 기록을 써도 나머지는 남는다 — 원본은 옆에 남는다', () async {
      final at = DateTime(2026, 10, 1, 18);
      final first = NotesStore(directory: dir)
        ..create(
          at: at,
          blocks: [
            ExerciseBlock('벤치프레스', [LoggedSet(value: 60, reps: 10)]),
          ],
        )
        ..create(
          at: at.subtract(const Duration(days: 1)),
          blocks: [
            ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
          ],
        );
      await first.flush();
      first.dispose();
      // 다음 판이 바꾼 저장 모양 — 이 판은 문자열 횟수를 못 읽는다.
      final raw = jsonDecode(notesFile().readAsStringSync()) as List;
      raw.firstWhere(
        (n) => n['blocks'][0]['name'] == '벤치프레스',
      )['blocks'][0]['sets'][0]['reps'] = '8-10';
      final original = jsonEncode(raw);
      notesFile().writeAsStringSync(original);

      final store = NotesStore(directory: dir);
      addTearDown(store.dispose);
      await store.load();
      expect(store.notes.map((n) => n.title), ['스쿼트']);
      // 앱은 켜자마자 오늘 기록을 연다 — 새로 만들고 곧 저장한다.
      store.today(now: at.add(const Duration(days: 1)));
      await store.flush();

      final saved = jsonDecode(notesFile().readAsStringSync()) as List;
      expect(saved, hasLength(2));
      expect(
        [
          for (final n in saved)
            for (final b in n['blocks']) b['name'],
        ],
        ['스쿼트'],
      );
      expect(backups().single.readAsStringSync(), original);
    });

    test('통째로 못 읽어도 빈 채로 뜨고, 원본은 옆에 남는다', () async {
      notesFile().writeAsStringSync('[{"id": "1"');
      final store = NotesStore(directory: dir);
      addTearDown(store.dispose);
      await store.load();
      expect(store.notes, isEmpty);
      expect(backups().single.readAsStringSync(), '[{"id": "1"');
    });

    test('멀쩡한 파일은 옆에 아무것도 남기지 않는다', () async {
      final first = NotesStore(directory: dir)..create();
      await first.flush();
      first.dispose();
      final store = NotesStore(directory: dir);
      addTearDown(store.dispose);
      await store.load();
      expect(store.notes, hasLength(1));
      expect(backups(), isEmpty);
    });

    test('무한대 값 하나가 저장 전체를 멈추지 않는다 — 그 값만 빈다', () async {
      final store = NotesStore(directory: dir);
      addTearDown(store.dispose);
      store
        ..create(
          blocks: [
            ExerciseBlock('벤치프레스', [
              LoggedSet(value: double.infinity, reps: 5),
              LoggedSet(value: 60, reps: 5),
            ]),
          ],
        )
        ..setBody(store.body.copyWith(weightKg: double.nan, heightCm: 175));
      await store.flush();

      final reopened = NotesStore(directory: dir);
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.notes.single.blocks.single.sets.map((s) => s.value), [
        null,
        60,
      ]);
      expect(reopened.body.heightCm, 175);
      expect(reopened.body.weightKg, isNull);
    });
  });

  test('치는 중의 초안은 알리지 않고 저장만 한다 — 글자마다 모든 기록을 다시 세지 않는다', () async {
    final dir = Directory.systemTemp.createTempSync('setpad-notes-draft-');
    final store = NotesStore(directory: dir);
    addTearDown(() {
      store.dispose();
      dir.deleteSync(recursive: true);
    });
    final note = store.create();
    var told = 0;
    store.addListener(() => told++);
    final revision = store.revision;
    store.updateDraft(note, const EditorDraft(text: '벤치'));
    expect(told, 0);
    expect(store.revision, revision);
    await store.flush();

    final reopened = NotesStore(directory: dir);
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(reopened.notes.single.draft?.text, '벤치');
  });
}
