import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/models/time_of_day.dart';
import 'package:layrz_ui/src/pickers/src/shared/time_fields_panel.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';
import '../../helpers/pump_themed_app.dart';

/// Every real caller hosts this panel inside a bounded-width ancestor -- see
/// `time_fields_panel_test.dart`'s identical `_bounded` helper doc for why
/// `pumpThemed` alone is insufficient.
Widget _bounded(Widget child) => SizedBox(width: 700, child: child);

void main() {
  group('LayrzPickersTimeFieldsPanel — arrow keys move the caret, never step the value', () {
    // Each digit group is a bare EditableText (`_DigitField`) with only a
    // digits-only + length-limiting formatter -- unlike the retired
    // LayrzNumberInput-hosted field, it wires no Focus.onKeyEvent of its own,
    // so ArrowUp/ArrowDown fall through to EditableText's own default
    // handling (caret/selection), never a value step. This is a deliberate
    // behavioural change from the old field-row panel, not an oversight --
    // see the class doc's "Tab order" section: only Tab/Shift+Tab traversal
    // and typed-digit editing are this panel's contract.
    guardedTestWidgets('ArrowUp on the hour field does not change its value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var changeCount = 0;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (_) => changeCount++,
          ),
        ),
      );

      await tester.tap(find.byType(EditableText).first);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(changeCount, 0);
    });

    guardedTestWidgets('ArrowDown on the hour field does not change its value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var changeCount = 0;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (_) => changeCount++,
          ),
        ),
      );

      await tester.tap(find.byType(EditableText).first);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(changeCount, 0);
    });

    guardedTestWidgets('ArrowUp on the minute field does not change any value either', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var changeCount = 0;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (_) => changeCount++,
          ),
        ),
      );

      // Minute is the second EditableText (hour, minute, second order).
      await tester.tap(find.byType(EditableText).at(1));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(changeCount, 0);
    });
  });

  group('LayrzPickersTimeFieldsPanel — Left/Right keep caret behaviour, never step', () {
    guardedTestWidgets('ArrowRight on the hour field does NOT change its value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var changeCount = 0;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (_) => changeCount++,
          ),
        ),
      );

      await tester.tap(find.byType(EditableText).first);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(changeCount, 0);
    });

    guardedTestWidgets('ArrowLeft on the hour field does NOT change its value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var changeCount = 0;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (_) => changeCount++,
          ),
        ),
      );

      await tester.tap(find.byType(EditableText).first);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(changeCount, 0);
    });
  });

  group('LayrzPickersTimeFieldsPanel — Tab moves between fields', () {
    guardedTestWidgets('Tab from the hour field moves focus to the minute field', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Tab traversal shortcuts (NextFocusIntent) are installed by
      // WidgetsApp's default shortcut map, which pumpThemed's bare tree
      // does not include -- pumpThemedApp wraps a real LayrzApp instead,
      // see that helper's own doc.
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(value: const LayrzTimeOfDay(hour: 9, minute: 30), onChanged: (_) {}),
        ),
      );

      await tester.tap(find.byType(EditableText).first);
      await tester.pump();

      final hourFocused = tester.state<EditableTextState>(find.byType(EditableText).first).widget.focusNode;
      expect(hourFocused.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final minuteFocused = tester.state<EditableTextState>(find.byType(EditableText).at(1)).widget.focusNode;
      expect(hourFocused.hasFocus, isFalse);
      expect(minuteFocused.hasFocus, isTrue);
    });

    guardedTestWidgets('Tab from the minute field moves focus to the second field when showSeconds is true', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30, second: 15),
            showSeconds: true,
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(EditableText).at(1));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final secondFocused = tester.state<EditableTextState>(find.byType(EditableText).at(2)).widget.focusNode;
      expect(secondFocused.hasFocus, isTrue);
    });
  });

  group('LayrzPickersTimeFieldsPanel — commit key bindings', () {
    guardedTestWidgets('Enter on a time field commits (clamps) the typed value but never throws', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? changed;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (v) => changed = v,
          ),
        ),
      );

      await tester.tap(find.byType(EditableText).first);
      await tester.pump();
      await tester.enterText(find.byType(EditableText).first, '99');
      await tester.pump();

      // Enter maps to TextInputAction.done -> onSubmitted -> _commit(), which
      // clamps and reports -- this panel has no notion of "close" at all
      // (see its own class doc's trap-4 discipline), so this must clamp the
      // typed value without ever throwing or dismissing anything.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(changed, isNotNull);
      expect(changed!.hour, 23);
      expect(find.byType(LayrzPickersTimeFieldsPanel), findsOneWidget);
    });
  });
}
