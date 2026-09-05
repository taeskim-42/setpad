import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/exercises.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/units.dart';

/// pumpAndSettle 의 기본 한도는 10분이다. 무언가 프레임을 계속 잡으면
/// 테스트가 멈춘 것처럼 보이므로 5초로 줄여 빨리 터지게 한다.
Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5));

/// 패드의 입력 칸.
///
/// 목록 화면이 아래에 깔려 있고 거기에도 검색 칸이 있어서, 그냥 TextField 를
/// 찾으면 둘이 잡힌다. 패드 안의 것만 집는다.
final padField =
    find.descendant(of: find.byType(RoutineEditor), matching: find.byType(TextField));

/// 패드 안의 글자. 첫 운동 이름은 앱바 제목에도 나오므로(메모 앱처럼 첫 줄이
/// 제목이다) 그냥 find.text 로 세면 둘이 잡힌다.
Finder inPad(String text) =>
    find.descendant(of: find.byType(RoutineEditor), matching: find.text(text));

/// 카드 안의 '세트 추가' 버튼. 키패드의 큰 키는 '다음'을 맡는다.
final addSetButton =
    find.descendant(of: find.byType(TextButton), matching: find.text('세트 추가'));

/// 키패드로 친다. 세트 칸은 읽기 전용이라 enterText 로는 글자가 안 들어간다 —
/// 실제 기기에서도 시스템 키보드가 아니라 이 키패드가 넣는다.
Future<void> tapKeys(WidgetTester tester, String text) async {
  for (final ch in text.split('')) {
    await tester.tap(find.widgetWithText(InkWell, ch == ' ' ? '␣' : ch).last);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// 위젯 테스트의 기본 기기 언어는 en 이다. 한국어 문구를 확인하려면
/// 기기 언어를 정해 놓고 띄워야 한다.
Future<void> pumpApp(WidgetTester tester,
    {Locale locale = const Locale('ko')}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  // 앱 문서 디렉터리는 플랫폼 채널이라 테스트에 없다. 임시 폴더를 물린다.
  final dir = Directory.systemTemp.createTempSync('setpad_test');
  addTearDown(() => dir.deleteSync(recursive: true));

  await tester.pumpWidget(SetpadApp(store: NotesStore(directory: dir)));
  // 앱은 목록을 깔고 그 위에 패드를 얹는다. 그 전환이 끝나야 패드가 보인다.
  await settle(tester);
}

void main() {
  group('에디터 상태', () {
    test('처음에는 이름을 받고, 이름을 넣으면 세트를 받는다', () {
      final c = RoutineEditorController();
      expect(c.naming, isTrue);
      c.commit('벤치프레스');
      expect(c.naming, isFalse);
      expect(c.blocks.single.name, '벤치프레스');
    });

    test('세트를 넣어도 그 운동 안에 머문다 — 세트를 더 칠 수 있어야 한다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 20회');
      expect(c.blocks.single.sets.length, 1);
      expect(c.inBlock, isTrue);
      c.commit('100kg 18회');
      expect(c.blocks.single.sets.length, 2);
    });

    test('빈 줄에서 Enter면 그 운동을 닫고 나온다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 20회');
      c.commit('');
      expect(c.naming, isTrue);
      c.commit('스쿼트');
      expect(c.blocks.length, 2);
    });

    test('세트를 하나도 안 적고 닫으면 그 운동은 남지 않는다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('');
      expect(c.blocks, isEmpty);
    });

    test('반복 세트는 그 수만큼 쌓인다', () {
      final c = RoutineEditorController()..commit('스쿼트');
      c.commit('100kg 5회 x5');
      expect(c.blocks.single.sets.length, 5);
      expect(c.totalSets, 5);
    });

    test('세트를 받는 중에 숫자 없는 줄이 오면 다음 운동이다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 10회');
      c.commit('스쿼트');
      expect(c.blocks.length, 2);
      expect(c.blocks.last.name, '스쿼트');
      expect(c.inBlock, isTrue);
    });

    test('지우기는 세트부터, 세트가 없으면 운동을 뗀다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 10회 x2');
      c.backspace();
      expect(c.blocks.single.sets.length, 1);
      c.backspace();
      expect(c.blocks.single.sets, isEmpty);
      c.backspace();
      expect(c.blocks, isEmpty);
      // 비어 있어도 터지지 않는다
      c.backspace(); // 비어 있어도 터지지 않는다
      expect(c.blocks, isEmpty);
    });

    test('친 이름이 씨앗 목록보다 먼저 제안된다', () {
      final c = RoutineEditorController()..commit('벤치 살짝 기울여서');
      expect(c.vocabulary('ko').first, '벤치 살짝 기울여서');
    });

    test('복사용 텍스트는 세트가 있는 운동만 담는다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 10회 x2');
      c.commit('스쿼트'); // 세트 없이 남겨둔다
      expect(c.asText(), '벤치프레스\n1세트 100kg · 10회\n2세트 100kg · 10회');
    });
  });

  group('화면', () {
    testWidgets('이름을 치면 화면에 뜨고, 세트 칸으로 넘어간다', (tester) async {
      await pumpApp(tester);

      await tester.enterText(padField, '벤치프레스');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      expect(inPad('벤치프레스'), findsOneWidget);
      // 첫 운동 이름이 곧 메모 제목이다 — 앱바에도 같이 뜬다.
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('벤치프레스')),
          findsOneWidget);

      // 세트 칸은 터치 기기에서 읽기 전용이다 — 시스템 키보드를 부르지 않고
      // 키패드가 글자를 넣는다. 실제 사용 경로가 그쪽이므로 여기서도 그렇게 친다.
      final field = tester.widget<TextField>(padField);
      expect(field.readOnly, isTrue);
      expect(find.byType(SetKeypad), findsOneWidget);
    });

    testWidgets('"벤"을 치면 후보가 뜨고 눌러서 고를 수 있다', (tester) async {
      await pumpApp(tester);

      await tester.enterText(padField, '벤');
      await settle(tester);
      expect(find.widgetWithText(ActionChip, '벤치프레스'), findsOneWidget);

      await tester.tap(find.widgetWithText(ActionChip, '벤치프레스'));
      await settle(tester);
      // 후보는 사라지고 운동 블록이 생긴다
      expect(find.widgetWithText(ActionChip, '벤치프레스'), findsNothing);
      expect(inPad('벤치프레스'), findsOneWidget);
    });

    testWidgets('빈 화면에는 쓰는 법이 적혀 있다', (tester) async {
      await pumpApp(tester);
      expect(find.textContaining('운동 이름을 치고 Enter'), findsOneWidget);
    });
  });

  keypadTests();

  markAndRemoveTests();
}

void markAndRemoveTests() {
  group('세트 표시와 취소', () {
    test('넣는 순간은 해낸 세트다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 10회');
      expect(c.blocks.single.sets.single.done, isTrue);
      expect(c.totalSets, 1);
    });

    test('완료를 끄면 집계에서 빠지고 내보내기에도 안 담긴다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 10회');
      c.commit('90kg 8회');
      c.toggleDone(0, 1);
      expect(c.totalSets, 1);
      expect(c.asText(), '벤치프레스\n1세트 100kg · 10회');
    });

    test('세트를 취소하면 그 줄만 빠진다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 10회');
      c.commit('90kg 8회');
      c.removeSet(0, 0);
      expect(c.blocks.single.sets.length, 1);
      expect(c.blocks.single.sets.single.value, 90);
    });

    test('운동을 삭제하면 통째로 사라진다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 10회');
      c.commit('');
      c.commit('스쿼트');
      c.commit('120kg 5회');
      c.removeBlock(0);
      expect(c.blocks.length, 1);
      expect(c.blocks.single.name, '스쿼트');
    });

    test('모두 지워도 터지지 않고 처음 상태로 돌아간다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 10회');
      c.removeBlock(0);
      expect(c.blocks, isEmpty);
      expect(c.naming, isTrue);
    });
  });
}

void keypadTests() {
  group('키패드', () {
    test('직전 세트를 그대로 한 번 더 넣는다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 20회 어깨 뻐근');
      c.repeatLastSet();
      expect(c.blocks.single.sets.length, 2);
      final last = c.blocks.single.sets.last;
      expect(last.value, 100);
      expect(last.reps, 20);
      expect(last.note, '어깨 뻐근');
    });

    test('세트가 없으면 반복할 것도 없다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      expect(c.lastSet, isNull);
      c.repeatLastSet();
      expect(c.blocks.single.sets, isEmpty);
    });

    test('운동 이름을 받는 중에는 반복 대상이 없다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      c.commit('100kg 20회');
      c.commit(''); // 운동 닫기
      expect(c.lastSet, isNull);
    });
  });

  group('키패드 화면', () {
    testWidgets('세트를 받는 중에만 키패드가 뜬다', (tester) async {
      await pumpApp(tester);
      // 처음엔 운동 이름을 받으므로 키패드가 없다
      expect(find.byType(SetKeypad), findsNothing);

      await tester.enterText(padField, '벤치프레스');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      expect(find.byType(SetKeypad), findsOneWidget);
    });

    testWidgets('키패드만으로 세트 한 줄이 완성된다', (tester) async {
      await pumpApp(tester);
      await tester.enterText(padField, '스쿼트');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      // 키패드 안에서만 찾는다 — 화면에도 같은 숫자가 떠 있을 수 있다.
      Finder key(String label) => find.descendant(
            of: find.byType(SetKeypad),
            matching: find.text(label),
          );
      // 단위 키는 없다 — 파서가 "100 20" 을 100kg 20회로 읽는다.
      for (final k in ['1', '0', '0', '␣', '2', '0']) {
        await tester.tap(key(k));
        await tester.pump();
      }
      // 키패드의 큰 키는 '다음'이고, 세트를 넣는 것은 화면 버튼이다.
      await tester.tap(addSetButton);
      await settle(tester);

      expect(find.text('100kg · 20회'), findsOneWidget);
    });
  });

  group('키보드 전환', () {
    testWidgets('메모로 넘어갔다가 키패드로 돌아온다', (tester) async {
      await pumpApp(tester);
      await tester.enterText(padField.last, '벤치프레스');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      expect(find.byType(SetKeypad), findsOneWidget);

      // ⌨ — 시스템 키보드로 넘어간다
      await tester.tap(find.byIcon(Icons.keyboard_alt_outlined));
      await settle(tester);
      expect(find.byType(SetKeypad), findsNothing);

      // 되돌아올 문이 남아 있어야 한다
      await tester.tap(find.text('숫자 키패드'));
      await settle(tester);
      expect(find.byType(SetKeypad), findsOneWidget);
    });
  });

  group('다국어 화면', () {
    testWidgets('영어 기기에서는 영어로 뜬다', (tester) async {
      await pumpApp(tester, locale: const Locale('en'));
      expect(find.text("Today's Workout"), findsOneWidget);
      expect(find.textContaining('Type an exercise'), findsOneWidget);

      await tester.enterText(padField.last, 'bench');
      await settle(tester);
      expect(find.text('Bench Press'), findsOneWidget);

      await tester.tap(find.text('Bench Press'));
      await settle(tester);
      // 아직 아무 숫자도 안 쳤으므로 큰 키는 '다음'이 아니라 '끝내기'다.
      expect(find.text('Done'), findsOneWidget);

      // 세트 칸은 읽기 전용이라 키패드로만 친다 — 실제 사용 경로도 그쪽이다.
      Finder key(String label) => find.descendant(
            of: find.byType(SetKeypad), matching: find.text(label));
      for (final k in ['1', '0', '0', '␣', '1', '0']) {
        await tester.tap(key(k));
        await tester.pump();
      }
      // 키패드 큰 키는 'Next'. 세트를 넣는 것은 화면 버튼이다.
      await tester.tap(find.descendant(
          of: find.byType(TextButton), matching: find.text('Add Set')));
      await settle(tester);
      expect(find.text('Set 1'), findsOneWidget);
      expect(find.text('100kg · 10 reps'), findsOneWidget);
    });

    testWidgets('일본어 기기에서는 일본어 이름이 나온다', (tester) async {
      await pumpApp(tester, locale: const Locale('ja'));
      expect(find.text('今日のトレーニング'), findsOneWidget);
      // 한글로 쳐도 일본어 이름으로 나온다
      await tester.enterText(padField.last, '벤치');
      await settle(tester);
      expect(find.text('ベンチプレス'), findsOneWidget);
    });

    testWidgets('zh-TW 처럼 문자 체계 없이 와도 번체로 붙는다', (tester) async {
      await pumpApp(tester, locale: const Locale('zh', 'TW'));
      expect(find.text('今日訓練'), findsOneWidget);

      await pumpApp(tester, locale: const Locale('zh', 'CN'));
      expect(find.text('今日训练'), findsOneWidget);
    });

    testWidgets('번체 중국어는 간체와 다른 이름을 낸다', (tester) async {
      await pumpApp(tester,
          locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'));
      expect(find.text('今日訓練'), findsOneWidget);
      await tester.enterText(padField.last, 'bench');
      await settle(tester);
      expect(find.text('臥推'), findsOneWidget);
    });
  });

  group('메모 목록', () {
    /// 임시 폴더를 물린 앱. 저장까지 도는 경로를 그대로 쓴다.
    Future<NotesStore> pumpWithStore(WidgetTester tester, Directory dir) async {
      tester.platformDispatcher.localesTestValue = [const Locale('ko')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final store = NotesStore(directory: dir);
      await tester.pumpWidget(SetpadApp(store: store));
      await settle(tester);
      return store;
    }

    testWidgets('친 것이 디스크에 남고 다시 열면 그대로 있다', (tester) async {
      final dir = Directory.systemTemp.createTempSync('setpad_persist');
      addTearDown(() => dir.deleteSync(recursive: true));

      final store = await pumpWithStore(tester, dir);
      await tester.enterText(padField, '벤치프레스');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      // testWidgets 는 가짜 비동기 안에서 돈다. 진짜 파일 IO 를 그냥 await 하면
      // 완료 신호가 오지 않아 테스트가 멈춘다 — runAsync 로 진짜 시간에 맡긴다.
      late NotesStore reopened;
      await tester.runAsync(() async {
        await store.flush();
        expect(File('${dir.path}/notes.json').existsSync(), isTrue);
        // 앱을 새로 켠 것과 같다 — 저장소를 처음부터 만들어 읽는다.
        reopened = NotesStore(directory: dir);
        await reopened.load();
      });
      expect(reopened.notes.single.blocks.single.name, '벤치프레스');
    });

    testWidgets('앱은 패드로 열리고, 뒤로 가면 목록이 있다', (tester) async {
      final dir = Directory.systemTemp.createTempSync('setpad_nav');
      addTearDown(() => dir.deleteSync(recursive: true));
      await pumpWithStore(tester, dir);

      // 열자마자 패드다 — 목록을 거치게 하지 않는다. (키패드는 운동 이름을
      // 친 뒤 세트를 받을 때 뜨므로, 여는 순간의 증거는 패드 자체다.)
      expect(find.byType(RoutineEditor), findsOneWidget);
      expect(find.text('모든 운동'), findsNothing);

      await tester.enterText(padField, '스쿼트');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      // pageBack() 은 툴팁이 'Back' 인 것을 찾는다. 이 앱은 한국어라 '뒤로'여서
      // 못 찾는다 — 뒤로가기 위젯을 직접 누른다.
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.text('모든 운동'), findsOneWidget);
      expect(find.text('스쿼트'), findsOneWidget);
    });

    testWidgets('하단 검색이 이름으로 거른다', (tester) async {
      final dir = Directory.systemTemp.createTempSync('setpad_search');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = NotesStore(directory: dir);
      store.create().blocks.add(ExerciseBlock('벤치프레스'));
      store.create().blocks.add(ExerciseBlock('데드리프트'));

      tester.platformDispatcher.localesTestValue = [const Locale('ko')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(SetpadApp(store: store));
      await settle(tester);
      // pageBack() 은 툴팁이 'Back' 인 것을 찾는다. 이 앱은 한국어라 '뒤로'여서
      // 못 찾는다 — 뒤로가기 위젯을 직접 누른다.
      await tester.tap(find.byType(BackButton));
      await settle(tester);

      expect(find.text('벤치프레스'), findsOneWidget);
      expect(find.text('데드리프트'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, '검색'), '데드');
      await settle(tester);
      expect(find.text('벤치프레스'), findsNothing);
      expect(find.text('데드리프트'), findsOneWidget);
    });

    test('아무것도 안 친 메모는 목록에 남지 않는다', () {
      final store = NotesStore(directory: Directory.systemTemp);
      final empty = store.create();
      store.discardIfEmpty(empty);
      expect(store.notes, isEmpty);

      final used = store.create()..blocks.add(ExerciseBlock('풀업'));
      store.discardIfEmpty(used);
      expect(store.notes.single.blocks.single.name, '풀업');
    });

    test('요약은 첫 운동의 세트 수와 무게·횟수를 낸다', () {
      final n = Note(id: '1', createdAt: DateTime.now(), updatedAt: DateTime.now(), blocks: [
        ExerciseBlock('벤치프레스', [
          LoggedSet(value: 80, reps: 25),
          LoggedSet(value: 80, reps: 20),
        ]),
      ]);
      expect(n.title, '벤치프레스');
      expect(n.summary(setOrdinal: (x) => '$x세트', reps: (x) => '$x회'), '2세트 · 80kg · 25회');
    });
  });

  group('키패드 큰 키', () {
    testWidgets('칠 것이 있으면 "다음", 비어 있으면 "운동 완료"', (tester) async {
      await pumpApp(tester);
      await tester.enterText(padField, '벤치프레스');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      // 세트를 받는 중이고 아직 아무것도 안 쳤다 — 더할 세트가 없다.
      expect(find.text('운동 완료'), findsOneWidget);
      expect(find.text('다음'), findsNothing);

      // 세트 칸은 읽기 전용이다 — enterText 가 안 먹는다. 실제 경로대로 친다.
      await tapKeys(tester, '100 20');
      expect(find.text('다음'), findsOneWidget);
      expect(find.text('운동 완료'), findsNothing);
      // 세트를 넣는 것은 화면 버튼이다.
      expect(addSetButton, findsOneWidget);
    });

    testWidgets('빈 칸에서 누르면 운동이 닫히고 다음은 새 운동 이름이다', (tester) async {
      await pumpApp(tester);
      await tester.enterText(padField, '벤치프레스');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      await tapKeys(tester, '100 20');
      await tester.tap(addSetButton);
      await settle(tester);

      await tester.tap(find.text('운동 완료'));
      await settle(tester);

      // 카드 밖으로 나왔으므로 키패드는 사라지고 이름을 받는다.
      expect(find.byType(SetKeypad), findsNothing);
      await tester.enterText(padField, '스쿼트');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      expect(inPad('스쿼트'), findsOneWidget);
      expect(inPad('벤치프레스'), findsOneWidget);
    });

    testWidgets('앱바에 복사 버튼이 없다', (tester) async {
      await pumpApp(tester);
      expect(find.text('복사'), findsNothing);
    });
  });

  group('카드 편집과 삭제', () {
    /// 운동 두 개를 세트까지 넣고 카드 밖으로 나온 상태를 만든다.
    Future<void> twoExercises(WidgetTester tester) async {
      await pumpApp(tester);
      for (final name in ['벤치프레스', '스쿼트']) {
        await tester.enterText(padField, name);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await settle(tester);
        await tapKeys(tester, '100 10');
        await tester.tap(addSetButton);
        await settle(tester);
        await tester.tap(find.text('운동 완료'));
        await settle(tester);
      }
    }

    test('닫은 운동을 다시 열면 세트가 거기로 들어간다', () {
      final c = RoutineEditorController()
        ..commit('벤치프레스')
        ..commit('100 10')
        ..commit('')            // 벤치프레스 닫기
        ..commit('스쿼트')
        ..commit('120 5')
        ..commit('');           // 스쿼트 닫기
      expect(c.inBlock, isFalse);

      c.openBlock(0);           // 벤치프레스 카드를 눌렀다
      expect(c.inBlock, isTrue);
      expect(c.activeIndex, 0);

      c.commit('100 8');
      // 스쿼트가 아니라 벤치프레스에 붙어야 한다.
      expect(c.blocks[0].sets.length, 2);
      expect(c.blocks[1].sets.length, 1);
    });

    test('열려 있던 빈 운동은 다른 카드로 옮길 때 치운다', () {
      final c = RoutineEditorController()
        ..commit('벤치프레스')
        ..commit('100 10')
        ..commit('')
        ..commit('스쿼트');     // 세트 없이 열려만 있다
      expect(c.blocks.length, 2);

      c.openBlock(0);
      expect(c.blocks.length, 1);          // 빈 스쿼트는 사라진다
      expect(c.blocks.single.name, '벤치프레스');
      expect(c.activeIndex, 0);
    });

    test('가운데 운동을 지워도 커서가 엉뚱한 곳으로 가지 않는다', () {
      final c = RoutineEditorController()
        ..commit('A')..commit('10 10')..commit('')
        ..commit('B')..commit('20 10')..commit('')
        ..commit('C')..commit('30 10');
      expect(c.activeIndex, 2);

      c.removeBlock(0);                    // 앞의 것을 지웠다
      expect(c.activeIndex, 1);            // C 를 계속 가리켜야 한다
      expect(c.blocks[c.activeIndex].name, 'C');

      c.commit('30 8');
      expect(c.blocks.last.sets.length, 2);
    });

    testWidgets('카드를 누르면 그 운동이 열린다', (tester) async {
      await twoExercises(tester);
      expect(find.byType(SetKeypad), findsNothing);   // 카드 밖

      await tester.tap(inPad('벤치프레스'));
      await settle(tester);
      expect(find.byType(SetKeypad), findsOneWidget); // 세트를 받는 중
    });

    testWidgets('삭제는 물어보고, 취소하면 남는다', (tester) async {
      await twoExercises(tester);
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await settle(tester);

      expect(find.text('벤치프레스 삭제'), findsOneWidget);
      expect(find.textContaining('되돌릴 수 없습니다'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await settle(tester);
      expect(inPad('벤치프레스'), findsOneWidget);
    });

    testWidgets('삭제를 누르면 지워진다', (tester) async {
      await twoExercises(tester);
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await settle(tester);
      await tester.tap(find.widgetWithText(TextButton, '삭제'));
      await settle(tester);

      expect(inPad('벤치프레스'), findsNothing);
      expect(inPad('스쿼트'), findsOneWidget);
    });
  });

  group('지우기 연쇄', () {
    testWidgets('세트가 다 빠진 뒤의 지우기는 운동을 떼기 전에 묻는다', (tester) async {
      await pumpApp(tester);
      await tester.enterText(padField, '벤치프레스');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      await tapKeys(tester, '100 10');
      await tester.tap(addSetButton);
      await settle(tester);

      final back = find.byIcon(Icons.backspace_outlined);
      await tester.tap(back);          // 세트 하나 — 묻지 않는다
      await settle(tester);
      expect(find.text('벤치프레스 삭제'), findsNothing);
      expect(inPad('벤치프레스'), findsOneWidget);

      await tester.tap(back);          // 이제 운동 차례 — 물어야 한다
      await settle(tester);
      expect(find.text('벤치프레스 삭제'), findsOneWidget);
      expect(find.textContaining('이 운동을 지웁니다'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await settle(tester);
      expect(inPad('벤치프레스'), findsOneWidget);   // 취소했으니 남는다

      await tester.tap(back);
      await settle(tester);
      await tester.tap(find.widgetWithText(TextButton, '삭제'));
      await settle(tester);
      expect(inPad('벤치프레스'), findsNothing);
    });

    test('다음 지우기가 운동을 뗄 상황인지 알린다', () {
      final c = RoutineEditorController()..commit('벤치프레스');
      expect(c.backspaceRemovesBlock, isTrue);     // 세트가 없다
      c.commit('100 10');
      expect(c.backspaceRemovesBlock, isFalse);    // 뗄 세트가 있다
      c.backspace();
      expect(c.backspaceRemovesBlock, isTrue);
      c.commit('');                                // 카드 밖으로
      expect(c.backspaceRemovesBlock, isFalse);    // 열린 운동이 없다
    });
  });

  group('이름 검색 — 대충 쳐도 걸린다', () {
    List<String> find_(String q) => suggest(q, seedNames('ko'));

    test('정확히 치던 것은 그대로다', () {
      // 관대한 단계를 뒤에 붙였을 뿐이므로 잘 되던 검색은 순서까지 같아야 한다.
      expect(find_('벤치프레스').first, '벤치프레스');
      expect(find_('벤치').first, '벤치프레스');
      expect(find_('bench').first, '벤치프레스');
      expect(find_('ㅂㅊ').first, '벤치프레스');       // 초성
      expect(find_('데드').first, '데드리프트');
    });

    test('한 글자 틀려도 찾는다', () {
      expect(find_('벤치프래스'), contains('벤치프레스'));   // 레→래
      expect(find_('밴치프레스'), contains('벤치프레스'));   // 벤→밴
      expect(find_('벤치프레스으'), contains('벤치프레스')); // 덧붙임
      expect(find_('데트리프트'), contains('데드리프트'));   // 드→트
      expect(find_('스콰트'), contains('스쿼트'));
    });

    test('영문 오타와 자리바꿈도 잡는다', () {
      expect(find_('bnech'), contains('벤치프레스'));   // 자리바꿈
      expect(find_('bech'), contains('벤치프레스'));    // 글자 빠짐
    });

    test('공백을 안 띄워도 찾는다', () {
      expect(find_('benchpress'), contains('벤치프레스'));
    });

    test('한글은 자모로 재므로 음절이 뭉개져도 잡는다', () {
      // '스퀏' 은 음절로 세면 세 자 중 두 자가 틀린 것이라 못 잡았다.
      // 자모로는 ㅅㅡㅋㅝㅅ / ㅅㅡㅋㅝㅌㅡ — 여섯 중 둘이라 잡힌다.
      expect(find_('스퀏'), contains('스쿼트'));
    });

    test('자모로 재도 잡음은 안 받는다', () {
      // 관대함을 늘린 대가로 아무거나 걸리면 못 쓴다.
      expect(find_('ㅋㅋ'), isEmpty);
      expect(find_('ㅋㅋㅋ'), isEmpty);
      expect(find_('zzzz'), isEmpty);
    });

    test('짧은 질의에는 관대하지 않다 — 아무거나 걸리면 못 쓴다', () {
      // 두 글자까지는 오타를 봐주지 않는다. 걸리는 것은 전부 진짜 앞글자 일치다.
      for (final name in find_('벤')) {
        expect(name.toLowerCase().contains('벤'), isTrue, reason: name);
      }
      expect(find_('ㅋㅋ'), isEmpty);
    });
  });

  group('단위', () {
    test('한 운동 안에서는 단위가 이어진다', () {
      // 첫 세트에 lb 를 쳤으면 다음 줄에 안 붙여도 파운드다. 한 운동 안에서
      // 세트마다 단위가 바뀌는 일은 없다.
      final c = RoutineEditorController()
        ..commit('벤치프레스')
        ..commit('225lb 5')
        ..commit('225 5');
      expect(c.blocks.single.sets.map((s) => s.unit), ['lb', 'lb']);
    });

    test('단위를 안 쳤으면 kg 이다', () {
      final c = RoutineEditorController()..commit('스쿼트')..commit('100 10');
      expect(c.blocks.single.sets.single.unit, 'kg');
    });

    test('표시는 친 단위 그대로다', () {
      expect(setLabel(value: 225, unit: 'lb', reps: 5), '225lb · 5회');
      expect(setLabel(value: 5, unit: 'km'), '5km');
      expect(setLabel(value: 60, unit: 's'), '60초');
    });

    test('단위마다 미는 폭이 다르다', () {
      // 2.5kg 은 국내 원판 한 쌍, 5lb 는 파운드 원판 한 쌍이다.
      expect(unitById['kg']!.step, 2.5);
      expect(unitById['lb']!.step, 5);
      expect(unitById['s']!.steps, contains(30));
    });

    test('예전 기록(kg 필드)도 읽힌다', () {
      // 단위가 생기기 전 저장분이다. 그때는 무게가 늘 kg 였다.
      final n = Note.fromJson({
        'id': '1',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'blocks': [
          {'name': '벤치프레스', 'sets': [{'kg': 80, 'reps': 10, 'done': true}]},
        ],
      });
      final set = n.blocks.single.sets.single;
      expect(set.value, 80);
      expect(set.unit, 'kg');
    });
  });
}
