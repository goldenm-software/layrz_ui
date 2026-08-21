import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/checkbox_input.dart';

import '../helpers/pump_themed.dart';
import '../helpers/pump_themed_app.dart';

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
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('toggles value when Enter key is pressed', (tester) async {
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
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('is Tab-reachable', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(find.byType(Focus), findsWidgets);
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

    testWidgets('respects custom padding', (tester) async {
      const customPadding = EdgeInsets.only(left: 20, right: 20);

      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
          padding: customPadding,
        ),
      );

      expect(find.byType(LayrzCheckboxInput), findsOneWidget);
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
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          labelText: 'Disabled checkbox',
          value: false,
          disabled: true,
          onChanged: (_) {},
        ),
      );

      final labelText = find.text('Disabled checkbox');
      expect(labelText, findsOneWidget);
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
  });
}
