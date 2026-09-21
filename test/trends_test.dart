// 오늘 문서의 한 줄과 기간 화면이 같은 집계를 쓰는가, 고치면 같이 바뀌는가.
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/daily.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';
import 'package:setpad/trends_page.dart';

Future<void> pumpPage(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    CupertinoApp(
      locale: const Locale('ko'),
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

NotesStore tempStore() {
  final dir = Directory.systemTemp.createTempSync('setpad_trends_');
  final store = NotesStore(directory: dir);
  // 저장을 모아 쓰는 타이머가 남으면 테스트가 끝나지 않는다. 각 테스트가 끝에서
  // 직접 버린다(dispose 가 타이머를 끈다).
  addTearDown(() => dir.deleteSync(recursive: true));
  return store;
}

MealEntry typed(DateTime at, int? kcal) => MealEntry(
  at: at,
  kcal: kcal,
  text: '끼니',
  source: kcal == null ? null : MealEntry.typed,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('오늘 문서의 한 줄은 그날 전체를 말하고, 끼니를 고치면 바로 바뀐다', (tester) async {
    final store = tempStore();
    final now = DateTime.now();
    final morning = store.create(
      blocks: [
        ExerciseBlock('달리기', [LoggedSet(value: 5, unit: 'km')]),
      ],
    )..calories = 200;
    final note = store.create(
      blocks: [
        ExerciseBlock('벤치프레스', [LoggedSet(value: 80, reps: 10)]),
      ],
    )..calories = 250;
    note.meals.addAll([typed(now, 600), typed(now, 1500)]);
    store.saveWeight(WeightEntry(at: now, value: 72.4));
    await pumpPage(tester, EditorPage(store: store, note: note));
    expect(
      find.text('기록 기준 섭취 2,100 − 운동 450 = 1,650kcal'),
      findsOneWidget,
      reason: '같은 날 두 문서의 운동 소모량이 합쳐지고, 부호는 섭취 − 운동이다',
    );
    expect(find.text('체중 72.4kg'), findsOneWidget);
    expect(find.textContaining('운동 − 섭취'), findsNothing);
    expect(morning.calories, 200);

    // 열량을 모르는 끼니가 끼면 차이를 내지 않고, 이유를 그 자리에 적는다.
    note.meals.add(typed(now, null));
    store.touch();
    await tester.pumpAndSettle();
    expect(find.text('확인된 섭취 2,100kcal · 열량 미상 1건'), findsOneWidget);
    expect(find.textContaining('1,650'), findsNothing);

    // 그 끼니를 지우면 다시 계산된다.
    await tester.tap(find.byIcon(CupertinoIcons.xmark).last);
    await tester.pumpAndSettle();
    expect(find.text('기록 기준 섭취 2,100 − 운동 450 = 1,650kcal'), findsOneWidget);

    // 운동 소모량을 아무도 재지 않았으면 0 으로 빼지 않는다.
    note.calories = null;
    morning.calories = null;
    store.touch();
    await tester.pumpAndSettle();
    expect(find.text('섭취 2,100kcal · 운동 소모량 미측정 · 차이 계산 불가'), findsOneWidget);
  });

  testWidgets('30일 기록과 실제 체중 변화를 함께 보고, 체중을 고치면 요약과 그래프가 같이 바뀐다', (
    tester,
  ) async {
    final store = tempStore();
    final today = DateTime(2026, 9, 21);
    DateTime d(int day, [int hour = 12]) => DateTime(2026, 9, day, hour);
    Note add(int day, {double? kcal, List<int?> meals = const []}) {
      final note = store.create(
        blocks: [
          ExerciseBlock('스쿼트', [LoggedSet(value: 100, reps: 5)]),
        ],
      );
      // 만든 날짜를 그날로 — 저장소는 지금 시각으로 만들기 때문이다.
      final dated = Note(
        id: note.id,
        createdAt: d(day, 18),
        updatedAt: d(day, 19),
        blocks: note.blocks,
        calories: kcal,
      )..meals.addAll([for (final k in meals) typed(d(day), k)]);
      store.delete(note);
      return dated;
    }

    final notes = [
      add(1, kcal: 500, meals: [2000]),
      add(10, meals: [3000]),
      add(15, kcal: 300),
      add(20, kcal: 100, meals: [1000, null]),
    ];
    store
      ..saveWeight(WeightEntry(at: d(1, 7), value: 73.0))
      ..saveWeight(WeightEntry(at: d(21, 7), value: 72.4));
    final page = _Seeded(store: store, notes: notes, today: today);
    await pumpPage(tester, page);

    expect(find.text('기록된 섭취 평균 2,500kcal · 2일'), findsOneWidget);
    expect(find.text('기록된 운동 소모 평균 300kcal · 3일'), findsOneWidget);
    expect(find.text('섭취 − 운동 평균 1,500kcal · 둘 다 기록한 1일'), findsOneWidget);
    expect(find.text('열량 미상이 있는 날 1일 · 평균에서 제외'), findsOneWidget);
    expect(
      find.text('측정 체중은 9월 1일 73kg에서 9월 21일 72.4kg(으)로 변했습니다.'),
      findsOneWidget,
    );
    expect(find.textContaining('휴식과 일상생활에서 쓰는 에너지는 제외'), findsOneWidget);
    // 예측이나 환산은 어디에도 없다.
    for (final banned in ['감량', '지방', '흑자', '더 먹어도']) {
      expect(find.textContaining(banned), findsNothing, reason: banned);
    }

    // 체중을 잘못 쳤다 — 고치면 요약 문장이 같이 바뀐다.
    store.saveWeight(
      WeightEntry(id: store.weights.first.id, at: d(1, 7), value: 73.6),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('9월 1일 73.6kg에서'), findsOneWidget);
    // 하나를 지우면 변화를 말하지 않는다.
    store.deleteWeight(store.weights.last);
    await tester.pumpAndSettle();
    expect(find.textContaining('하루뿐입니다'), findsOneWidget);

    // 하루를 고르면 그날의 음식·운동·체중으로 이어진다 (9월 1일 = 30칸 중 10번째).
    final charts = tester.getRect(find.byKey(const ValueKey('trend-charts')));
    await tester.tapAt(
      Offset(charts.left + charts.width * (9.5 / 30), charts.top + 40),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trend-day')), findsOneWidget);
    expect(find.text('기록 기준 섭취 2,000 − 운동 500 = 1,500kcal'), findsOneWidget);
    expect(find.textContaining('체중 73.6kg · 직접 입력'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}

/// 날짜를 못 박은 기록으로 기간 화면을 띄운다.
class _Seeded extends StatelessWidget {
  const _Seeded({
    required this.store,
    required this.notes,
    required this.today,
  });
  final NotesStore store;
  final List<Note> notes;
  final DateTime today;
  @override
  Widget build(BuildContext context) =>
      TrendsPage(store: _With(store, notes), today: today);
}

/// 저장소의 기록 목록만 바꿔 끼운다. 체중과 알림은 진짜 저장소 것이다.
class _With extends NotesStore {
  _With(this.inner, this.fixed);
  final NotesStore inner;
  final List<Note> fixed;
  @override
  List<Note> get notes => fixed;
  @override
  List<WeightEntry> get weights => inner.weights;
  @override
  String get weightUnit => inner.weightUnit;
  @override
  void addListener(VoidCallback listener) => inner.addListener(listener);
  @override
  void removeListener(VoidCallback listener) => inner.removeListener(listener);
  @override
  void saveWeight(WeightEntry entry) => inner.saveWeight(entry);
  @override
  void deleteWeight(WeightEntry entry) => inner.deleteWeight(entry);
}
