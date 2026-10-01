import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/handoff.dart';
import 'package:setpad/notes.dart';

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
}
