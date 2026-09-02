import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/models/time_of_day.dart';
import 'package:layrz_ui/src/pickers/src/shared/time_fields_panel.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';
import '../../helpers/pump_themed_app.dart';

/// This file has no corresponding `time_fields_keyboard_handler.dart` --
/// see `grid_keyboard_handler.dart`'s sibling files for the grids' own
/// handler, and the implementation plan's U10 write-up for why the time
/// fields have none. `LayrzNumberInput`'s own ancestor `Focus.onKeyEvent`
/// (`lib/src/inputs/src/number/number_input.dart`, `_handleKeyEvent`)
/// already binds ArrowUp/ArrowDown to step the value and leaves ArrowLeft/
/// ArrowRight for caret movement, positioned strictly closer to the focused
/// `EditableText` leaf than anything a wrapper placed outside
/// [LayrzPickersTimeFieldsPanel] could intercept -- confirmed against the
/// pinned Flutter 3.47.2 SDK's key-event bubbling order (`FocusManager`
/// walks from the primary-focused node outward, stopping at the first
/// `handled`), so no override is reachable from outside `lib/src/inputs/`,
/// which is frozen per CLAUDE.md rule #4 regardless.
///
/// What was an architectural accident for the input is exactly the
/// behaviour the maintainer ruled for these fields: Up/Down steps the
/// value within its clamp bounds, Left/Right keep caret movement, Tab moves
/// between fields. This file turns that accident into a guaranteed
/// contract -- if a future change to `LayrzNumberInput` ever drops this
/// behaviour, these tests fail loudly rather than silently regressing a
/// WCAG 2.1.1 Keyboard commitment.
///
/// Every real caller hosts this panel inside a bounded-width ancestor -- see
/// `time_fields_panel_test.dart`'s identical `_bounded` helper doc for why
/// `pumpThemed` alone is insufficient.
Widget _bounded(Widget child) => SizedBox(width: 700, child: child);

void main() {
  group('LayrzPickersTimeFieldsPanel — arrow keys step values, never caret', () {
    guardedTestWidgets('ArrowUp on the hour field increments its value', (tester) async {
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

      // Field order is hour, minute, second (see the panel's own "Tab
      // order" doc) -- the hour field is the first EditableText.
      await tester.tap(find.byType(EditableText).first);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(changed, isNotNull);
      expect(changed!.hour, 10);
      expect(changed!.minute, 30);
    });

    guardedTestWidgets('ArrowDown on the hour field decrements its value', (tester) async {
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

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(changed, isNotNull);
      expect(changed!.hour, 8);
    });

    guardedTestWidgets('ArrowUp on the minute field increments only the minute', (tester) async {
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

      // Minute is the second EditableText (hour, minute, second order).
      await tester.tap(find.byType(EditableText).at(1));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(changed, isNotNull);
      expect(changed!.hour, 9);
      expect(changed!.minute, 31);
    });

    guardedTestWidgets('ArrowUp at the hour field maximum (23) is refused, never wraps or overflows', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? changed;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 23, minute: 0),
            onChanged: (v) => changed = v,
          ),
        ),
      );

      await tester.tap(find.byType(EditableText).first);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      // The field's existing bounds (0-23 in 24h form, the default) refuse
      // the step at the maximum -- LayrzNumberInput's own
      // `_isIncrementDisabled` guard means `onChanged` never fires here at
      // all, rather than firing with a wrapped-to-0 or overflowed-to-24
      // value. Either "clamp and still report 23" or "refuse and report
      // nothing" would satisfy "never silently change meaning"; asserting
      // `changed` stays null matches this codebase's actual behaviour.
      expect(changed, isNull);
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
  });

  group('LayrzPickersTimeFieldsPanel — Enter never commits/closes anything', () {
    guardedTestWidgets('Enter on a time field does not change the value or throw', (tester) async {
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

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      // This panel has no notion of "close" at all (see its own class doc's
      // trap-4 discipline) -- Enter reaching a time field must not silently
      // invoke onChanged either, since that would falsely look like an
      // edit the user never made.
      expect(changeCount, 0);
    });
  });
}
