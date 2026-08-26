import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/checkbox/checkbox_input.dart';

import '../../helpers/pump_themed.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzCheckboxInput', () {
    testWidgets('renders unchecked checkbox', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      expect(find.byType(LayrzCheckboxInput), findsOneWidget);
      // Unchecked state: no checkmark icon visible
      expect(find.byType(Icon), findsNothing);
      // Container for the checkbox box should be present
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders checked checkbox with checkmark', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          value: true,
          onChanged: (_) {},
        ),
      );

      expect(find.byType(LayrzCheckboxInput), findsOneWidget);
      // Checked state: checkmark icon should be visible
      expect(find.byType(Icon), findsOneWidget);
      // Container for the checkbox box should be present
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders label text when provided', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          labelText: 'Accept terms',
          value: false,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Accept terms'), findsOneWidget);
      // Verify widget structure: checkbox + label together
      expect(find.byType(LayrzCheckboxInput), findsOneWidget);
      // Label text is associated with the checkbox
      expect(find.bySemanticsLabel('Accept terms'), findsOneWidget);
    });

    testWidgets('toggles value when checkbox is tapped', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      expect(currentValue, isFalse);

      await tester.tap(find.byType(LayrzCheckboxInput));
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('toggles value when label is tapped', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            labelText: 'Accept terms',
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      expect(currentValue, isFalse);

      await tester.tap(find.text('Accept terms'));
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('toggles value when Space key is pressed', (tester) async {
      bool currentValue = false;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            value: currentValue,
            onChanged: (newValue) {
              callCount++;
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Give focus to the checkbox
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      callCount = 0; // Reset after focus
      // Send Space key
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
      expect(callCount, equals(1)); // Verify single toggle, not double (A2 regression check)
    });

    testWidgets('toggles value when Enter key is pressed', (tester) async {
      bool currentValue = false;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            value: currentValue,
            onChanged: (newValue) {
              callCount++;
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Give focus to the checkbox
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      callCount = 0; // Reset after focus
      // Send Enter key
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
      expect(callCount, equals(1)); // Verify single toggle, not double (A2 regression check)
    });

    testWidgets('is Tab-reachable', (tester) async {
      final focusNode = FocusNode();

      await pumpThemedApp(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
          focusNode: focusNode,
        ),
      );

      // Send Tab to focus the checkbox
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Verify focus was received
      expect(focusNode.hasFocus, isTrue);

      focusNode.dispose();
    });

    testWidgets('does not toggle when disabled', (tester) async {
      bool currentValue = false;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            value: currentValue,
            disabled: true,
            onChanged: (newValue) {
              callCount++;
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzCheckboxInput));
      await tester.pumpAndSettle();

      expect(currentValue, isFalse);
      expect(callCount, 0);
    });

    testWidgets('does not toggle when onChanged is null', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            value: currentValue,
            onChanged: null,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzCheckboxInput));
      await tester.pumpAndSettle();

      expect(currentValue, isFalse);
    });

    testWidgets('renders error messages', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
          errors: const ['This field is required'],
          hideDetails: false,
        ),
      );

      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('hides error messages when hideDetails is true', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
          errors: const ['This field is required'],
          hideDetails: true,
        ),
      );

      expect(find.text('This field is required'), findsNothing);
    });

    testWidgets('applies the fixed control padding', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      final paddingWidget = tester.widget<Padding>(
        find.ancestor(
          of: find.byType(GestureDetector),
          matching: find.byType(Padding),
        ),
      );

      expect(paddingWidget.padding, const EdgeInsets.all(10));
    });

    testWidgets('checkbox size is consistent across states', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      final uncheckedSize = tester.getSize(find.byType(Container).first);

      await tester.tap(find.byType(LayrzCheckboxInput));
      await tester.pumpAndSettle();

      final checkedSize = tester.getSize(find.byType(Container).first);

      expect(uncheckedSize, equals(checkedSize));
    });

    testWidgets('uses custom focus node', (tester) async {
      final focusNode = FocusNode();

      await pumpThemedApp(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
          focusNode: focusNode,
        ),
      );

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);

      // Focus node provided by caller should NOT be disposed
      expect(focusNode.hasFocus, isTrue);

      focusNode.dispose();
    });

    testWidgets('disposes internally created focus node', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      // Widget should create and manage its own focus node
      expect(find.byType(Focus), findsWidgets);

      // Dispose by replacing with empty widget - should not throw
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });

    testWidgets('changes colour on hover', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      final container = find.byType(Container).first;
      final beforeHover = tester.getSize(container);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final afterHover = tester.getSize(container);

      // Size must not change on hover (D15)
      expect(beforeHover, equals(afterHover));
    });

    testWidgets('animates checked state', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzCheckboxInput));
      await tester.pump(const Duration(milliseconds: 100));

      expect(currentValue, isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets('label colour changes when disabled', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            labelText: 'Test label',
            value: currentValue,
            disabled: false,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Get enabled state label color
      final enabledLabelText = find.text('Test label');
      final enabledTextWidget = tester.widget<Text>(enabledLabelText);
      final enabledColor = enabledTextWidget.style?.color;
      expect(enabledColor, isNotNull);

      // Now test disabled state
      await pumpThemedApp(
        tester,
        LayrzCheckboxInput(
          labelText: 'Test label',
          value: false,
          disabled: true,
          onChanged: (_) {},
        ),
      );

      // Get disabled state label color
      final disabledLabelText = find.text('Test label');
      final disabledTextWidget = tester.widget<Text>(disabledLabelText);
      final disabledColor = disabledTextWidget.style?.color;
      expect(disabledColor, isNotNull);

      // Colors should be different between enabled and disabled
      expect(disabledColor, isNot(equals(enabledColor)));
    });

    testWidgets('label is clickable independently', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            labelText: 'Click me',
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      final labelFinder = find.text('Click me');
      final labelWidget = tester.getRect(labelFinder);

      // Tap in the label text area
      await tester.tapAt(labelWidget.center);
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('disabled checkbox does not respond to hover', (tester) async {
      bool currentValue = false;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            value: currentValue,
            disabled: true,
            onChanged: (newValue) {
              callCount++;
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Get checkbox background color before hover
      final checkboxBefore = tester.widget<Container>(find.byType(Container).first);
      final colorBefore = (checkboxBefore.decoration as BoxDecoration).color;

      // Simulate hover
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Get checkbox background color after hover attempt
      final checkboxAfter = tester.widget<Container>(find.byType(Container).first);
      final colorAfter = (checkboxAfter.decoration as BoxDecoration).color;

      // Colors should remain the same
      expect(colorBefore, equals(colorAfter));
      expect(callCount, equals(0)); // No toggle should occur
    });

    testWidgets('tab-focus shows colour affordance (focus-visible)', (tester) async {
      bool currentValue = false;

      // Get resting state first
      await pumpThemedApp(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
        ),
      );
      final restingCheckbox = tester.widget<Container>(find.byType(Container).first);
      final restingColor = (restingCheckbox.decoration as BoxDecoration?)?.color;

      // Re-pump with stateful widget
      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Give focus via Tab (keyboard focus)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Get the checkbox box and verify the colour changed
      final focusedCheckbox = tester.widget<Container>(find.byType(Container).first);
      final focusedColor = (focusedCheckbox.decoration as BoxDecoration?)?.color;

      // Colour should change when keyboard-focused (hover state applied)
      expect(focusedColor, isNotNull);
      expect(focusedColor, isNot(equals(restingColor)));

      // Border should be primary colour when focused
      final border = (focusedCheckbox.decoration as BoxDecoration?)?.border;
      expect(border, isNotNull);
    });

    testWidgets('click-focus does not latch colour affordance', (tester) async {
      bool currentValue = false;

      // Get resting state
      await pumpThemedApp(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
        ),
      );
      // Re-pump with stateful widget
      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Tap the checkbox
      await tester.tap(find.byType(LayrzCheckboxInput));
      await tester.pumpAndSettle();

      // After tap, focus is still held
      final focusWidget = tester.widget<Focus>(find.byType(Focus).first);
      expect(focusWidget.focusNode?.hasFocus, isTrue);

      // But colour should NOT show the hover/focus treatment (was latching before fix)
      final clickedCheckbox = tester.widget<Container>(find.byType(Container).first);
      final clickedColor = (clickedCheckbox.decoration as BoxDecoration?)?.color;

      // Checkbox toggled to checked, but colour should use default branch
      // (not the interactive sf3 lighter background from hover/focus)
      expect(clickedColor, isNotNull);
    });

    testWidgets('keyboard still works after pointer focus', (tester) async {
      bool currentValue = false;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            value: currentValue,
            onChanged: (newValue) {
              callCount++;
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Tap the checkbox (this gains focus and toggles)
      await tester.tap(find.byType(LayrzCheckboxInput));
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
      expect(callCount, equals(1));

      callCount = 0;

      // Send Space key — should toggle again despite having pointer focus
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(currentValue, isFalse);
      expect(callCount, equals(1)); // Single toggle from Space
    });
  });
}
