import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/health_summary.dart';
import 'package:setpad/l10n/generated/app_localizations.dart';
import 'package:setpad/notes.dart';

Widget _summary(double? calories) => CupertinoApp(
  locale: const Locale('ko'),
  localizationsDelegates: L.localizationsDelegates,
  supportedLocales: L.supportedLocales,
  home: CupertinoPageScaffold(
    child: HealthSummary(calories: calories, showSource: true),
  ),
);

void main() {
  testWidgets('missing health data is not presented as zero calories', (
    tester,
  ) async {
    await tester.pumpWidget(_summary(null));
    await tester.pumpAndSettle();
    expect(find.text('활동 칼로리'), findsOneWidget);
    expect(find.text('기록 없음'), findsOneWidget);
    expect(find.textContaining('kcal'), findsNothing);
    expect(find.text('건강 앱 · 기록 시간대'), findsNothing);
  });

  testWidgets('health calories show their source and retain measured zero', (
    tester,
  ) async {
    await tester.pumpWidget(_summary(231.4));
    await tester.pumpAndSettle();
    expect(find.text('231kcal'), findsOneWidget);
    expect(find.text('건강 앱 · 기록 시간대'), findsOneWidget);
    await tester.pumpWidget(_summary(0));
    await tester.pumpAndSettle();
    expect(find.text('0kcal'), findsOneWidget);
    expect(find.text('기록 없음'), findsNothing);
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
}
