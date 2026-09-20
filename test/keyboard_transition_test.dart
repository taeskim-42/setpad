import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/keypad.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';

final _field = find.descendant(
  of: find.byType(RoutineEditor),
  matching: find.byType(CupertinoTextField),
);
final _list = find.descendant(
  of: find.byType(RoutineEditor),
  matching: find.byWidgetPredicate(
    (widget) => widget is CustomScrollView && widget.controller != null,
  ),
);

Future<void> _pumpPhone(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  tester.view.viewPadding = const FakeViewPadding(top: 59, bottom: 34);
  tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
  tester.platformDispatcher.localesTestValue = [const Locale('ko')];
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearLocalesTestValue();
  });
  final directory = Directory.systemTemp.createTempSync('setpad_keyboard_');
  addTearDown(() => directory.deleteSync(recursive: true));
  await tester.pumpWidget(SetpadApp(store: NotesStore(directory: directory)));
  await tester.pumpAndSettle();
}

Future<void> _inset(WidgetTester tester, double height) async {
  tester.view.viewInsets = FakeViewPadding(bottom: height);
  tester.view.padding = FakeViewPadding(
    top: 59,
    bottom: height < 34 ? 34 - height : 0,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  expect(tester.takeException(), isNull);
}

Future<void> _pickExercise(WidgetTester tester) async {
  await tester.enterText(_field, '벤치');
  await tester.pumpAndSettle();
  await tester.tap(find.text('벤치프레스'));
  await tester.pump();
}

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    group(platform.name, () {
      testWidgets(
        'keypad stays at the bottom while the system keyboard closes',
        (tester) async {
          await _pumpPhone(tester);
          await _inset(tester, 336);
          expect(
            find.byKey(const ValueKey('keyboard-background')),
            findsNothing,
            reason: 'The app must not paint outside the rounded keyboard.',
          );
          await _pickExercise(tester);

          final bottom = tester.getRect(find.byType(RoutineEditor)).bottom;
          var previousListBottom = tester.getRect(_list).bottom;
          for (final height in [336.0, 280.0, 200.0, 100.0, 0.0]) {
            await _inset(tester, height);
            expect(
              tester.getRect(find.byType(SetKeypad)).bottom,
              closeTo(bottom, 1),
              reason: 'The keypad must not move with the closing keyboard.',
            );
            final listBottom = tester.getRect(_list).bottom;
            expect(listBottom, greaterThanOrEqualTo(previousListBottom));
            previousListBottom = listBottom;
          }
          await tester.pumpAndSettle();
          expect(tester.widget<CupertinoTextField>(_field).readOnly, isTrue);
          expect(tester.testTextInput.isVisible, isFalse);
        },
        variant: TargetPlatformVariant({platform}),
      );

      testWidgets(
        'adding an exercise to a long list does not overshoot the final scroll',
        (tester) async {
          await _pumpPhone(tester);
          final controller = tester
              .widget<RoutineEditor>(find.byType(RoutineEditor))
              .controller;
          controller.commit('랫풀다운');
          controller.commit('50 10 x12');
          controller.commit('');
          await tester.pumpAndSettle();
          await _inset(tester, 336);
          await tester.enterText(_field, '벤치');
          await tester.pumpAndSettle();
          final scroll = tester.widget<CustomScrollView>(_list).controller!;
          final before = scroll.offset;
          final offsets = <double>[];

          await tester.tap(find.text('벤치프레스'));
          await tester.pump();
          for (final height in [336.0, 336.0, 280.0, 200.0, 100.0, 0.0]) {
            await _inset(tester, height);
            offsets.add(scroll.offset);
          }
          await tester.pumpAndSettle();
          expect(
            offsets.reduce(math.max),
            lessThanOrEqualTo(math.max(before, scroll.offset) + 1),
            reason:
                'Scrolling must not overshoot and rebound as the IME closes.',
          );
          final viewport = tester.getRect(_list);
          final input = tester.getRect(_field);
          expect(input.top, greaterThanOrEqualTo(viewport.top));
          expect(input.bottom, lessThanOrEqualTo(viewport.bottom));
        },
        variant: TargetPlatformVariant({platform}),
      );

      testWidgets(
        'number keypad button remains above the memo keyboard',
        (tester) async {
          await _pumpPhone(tester);
          await _pickExercise(tester);
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(CupertinoIcons.keyboard));
          await tester.pumpAndSettle();
          await _inset(tester, 336);

          final keyboardTop = tester.view.physicalSize.height - 336;
          expect(
            tester.getRect(find.text('숫자 키패드')).bottom,
            lessThanOrEqualTo(keyboardTop),
          );
          tester.testTextInput.log.clear();
          await tester.tap(find.text('숫자 키패드'));
          await tester.pump();
          expect(
            tester.testTextInput.log.any(
              (call) => call.method == 'TextInput.hide',
            ),
            isTrue,
          );
          await _inset(tester, 0);
          await tester.pumpAndSettle();
          expect(find.byType(SetKeypad), findsOneWidget);
          expect(tester.testTextInput.isVisible, isFalse);
        },
        variant: TargetPlatformVariant({platform}),
      );
    });
  }
}
