import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/gym.dart' show needsSend;
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

  test('사람이 지운 체육관 기록은 서버의 끼니·운동 줄을 지울 것으로 남는다 — 빈 기록 정리는 남기지 않는다', () async {
    final dir = Directory.systemTemp.createTempSync('setpad-notes-delete-');
    final store = NotesStore(directory: dir);
    addTearDown(() {
      store.dispose();
      dir.deleteSync(recursive: true);
    });
    final note = store.create(gymId: 'g')..owner = 'u1';
    final kept = MealEntry(at: note.createdAt, kcal: 300, text: '김밥');
    final gone = MealEntry(at: note.createdAt, kcal: 200, text: '라면');
    note.meals.addAll([kept, gone]);
    note.removeMeal(gone);
    note.partner = PartnerSession(
      id: 'S9',
      host: true,
      state: PartnerState.ended,
    )..endPending = true;
    store.delete(note);
    final expected = [
      (kind: 'meal', id: gone.id, owner: 'u1'),
      (kind: 'meal', id: kept.id, owner: 'u1'),
      (kind: 'workout', id: note.id, owner: 'u1'),
      (kind: 'session', id: 'S9', owner: 'u1'),
    ];
    expect(store.pendingDeletes, expected);

    // 혼자 쓴 기록은 서버에 간 것이 없다.
    store.delete(store.create());
    // 보낸 지 오래된 빈 출석을 치우는 것은 기기 정리다 — 서버의 출석은 그대로 둔다.
    final visit = store.create(
      gymId: 'g',
      at: DateTime.now().subtract(const Duration(hours: 4)),
    )..sentAt = DateTime.now();
    store.discardIfEmpty(visit);
    expect(store.notes, isEmpty);
    expect(store.pendingDeletes, expected);

    // 앱을 껐다 켜도 남아 있다가 그물이 닿으면 간다.
    await store.flush();
    final reopened = NotesStore(directory: dir);
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(reopened.pendingDeletes, expected);
  });

  group('트레이너에게 가는 기록', () {
    late Directory dir;
    late NotesStore store;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('setpad-notes-share-');
      store = NotesStore(directory: dir);
    });
    tearDown(() {
      store.dispose();
      dir.deleteSync(recursive: true);
    });

    test('스티커를 대면 오늘 먼저 적던 내 기록이 그 방문이 된다 — 스티커 전의 세트·끼니도 같이 간다', () {
      final now = DateTime.now();
      final morning = DateTime(now.year, now.month, now.day);
      final today = store.create(at: morning)
        ..blocks.add(ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]))
        ..meals.add(MealEntry(at: morning, kcal: 400, text: '아침'));
      final (:note, :fresh) = store.visit('g1', 'u1');
      expect(note, same(today), reason: '기록이 둘로 갈리지 않는다');
      expect(fresh, isTrue, reason: '새 방문이라 지금 보낸다');
      expect(note.gymId, 'g1');
      expect(note.owner, 'u1');
      expect(note.visitAt, isNotNull, reason: '아침에 연 기록이어도 온 때는 지금이다');
      expect(needsSend(note), isTrue);
      expect(note.mealGym, 'g1');

      final again = store.visit('g1', 'u1');
      expect(again.note, same(today));
      expect(again.fresh, isFalse);
      expect(store.notes, hasLength(1));
    });

    test('같은 방문인지는 온 때로 센다 — 아침에 연 기록이 저녁에 방문이 됐어도 다시 대면 같은 방문이다', () {
      final now = DateTime.now();
      final adopted = store.create(at: now.subtract(const Duration(hours: 9)))
        ..gymId = 'g1'
        ..visitAt = now.subtract(const Duration(hours: 1));
      expect(store.openVisit('g1', null), same(adopted));
      adopted.visitAt = null;
      expect(store.openVisit('g1', null), isNull, reason: '연 때만 보면 아홉 시간 전이다');
    });

    test('오늘 기록이 다른 도장의 것이거나 남의 것이면 새 방문 기록을 연다', () {
      final other = store.create()..gymId = 'g0';
      final first = store.visit('g1', 'u1');
      expect(first.note, isNot(same(other)));
      expect(first.note.gymId, 'g1');
      expect(first.note.visitAt, isNull, reason: '처음부터 방문으로 연 기록은 연 때가 온 때다');
      expect(other.gymId, 'g0');

      store.delete(first.note);
      store.delete(other);
      final someone = store.create()..owner = 'u2';
      final mine = store.visit('g1', 'u1').note;
      expect(mine, isNot(same(someone)));
      expect(someone.gymId, isNull);
    });

    test('식단 공유는 켠 날부터 연 기록만, 도장이 하나일 때만 묶인다 — 그 전의 끼니가 쏟아지지 않는다', () async {
      final now = DateTime.now();
      final old = store.create(at: now.subtract(const Duration(days: 3)));
      final today = store.create();
      store.linkMeals(today, ['g1'], 'u1');
      expect(today.mealGymId, isNull, reason: '끼니는 건강 정보라 켜야 간다');

      store.setShareMeals(true);
      store.linkMeals(old, ['g1'], 'u1');
      store.linkMeals(today, ['g1', 'g2'], 'u1');
      expect(old.mealGymId, isNull, reason: '켠 날 전의 기록');
      expect(today.mealGymId, isNull, reason: '여럿이면 앱이 고르지 않는다');
      store.linkMeals(today, ['g1'], 'u1');
      expect(today.mealGymId, 'g1');
      expect(today.owner, 'u1');
      expect(today.mealGym, 'g1');
      expect(needsSend(today), isFalse, reason: '운동과 출석은 가지 않는다');

      // 지운 끼니는 서버에서도 지운다. 기록째 지워도 끼니 줄만 — 출석 줄은 없다.
      final meal = MealEntry(at: now, kcal: 500, text: '점심');
      today.meals.add(meal);
      today.removeMeal(meal);
      expect(today.deletedMeals, [meal.id]);
      today.meals.add(MealEntry(at: now, kcal: 300, text: '저녁'));
      store.delete(today);
      expect(store.pendingDeletes.map((d) => d.kind), ['meal', 'meal']);

      // 켠 날은 앱을 껐다 켜도 남는다.
      await store.flush();
      final reopened = NotesStore(directory: dir);
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.sharesMeals, isTrue);
      expect(reopened.sharesMealsOn(now), isTrue);
      expect(
        reopened.sharesMealsOn(now.subtract(const Duration(days: 1))),
        isFalse,
      );
    });

    test('식단 공유를 껐다 다시 켜면 꺼 둔 동안 앞서 나눈 기록에 적은 끼니는 가지 않는다', () {
      store.setShareMeals(true);
      final shared = store.create(
        at: DateTime.now().subtract(const Duration(days: 2)),
      )..mealGymId = 'g1';
      final offline = MealEntry(at: shared.createdAt, kcal: 200, text: '간식');
      shared.meals.add(offline);
      store.setShareMeals(false);
      expect(offline.dirty, isTrue);
      store.setShareMeals(true);
      expect(offline.dirty, isFalse);
    });

    test('못 올린 기록·방문 시각·식단 도장은 저장했다 다시 읽어도 그대로다', () {
      final at = DateTime(2026, 10, 13, 18, 30);
      final note =
          Note(
              id: 'n1',
              createdAt: DateTime(2026, 10, 13, 8),
              updatedAt: DateTime(2026, 10, 13, 19),
              gymId: 'g1',
            )
            ..uploadRejected = true
            ..visitAt = at
            ..mealGymId = 'g2';
      final back = Note.fromJson(
        jsonDecode(jsonEncode(note.toJson())) as Map<String, dynamic>,
      );
      expect(back.uploadRejected, isTrue);
      expect(back.visitAt, at);
      expect(back.cameAt, at);
      expect(back.mealGymId, 'g2');
      final plain = Note.fromJson(
        jsonDecode(
              jsonEncode(Note(id: 'n2', createdAt: at, updatedAt: at).toJson()),
            )
            as Map<String, dynamic>,
      );
      expect(plain.uploadRejected, isFalse);
      expect(plain.visitAt, isNull);
      expect(plain.mealGymId, isNull);
    });
  });
}
