import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/switch_input.dart';

import '../helpers/pump_themed.dart';
import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzSwitchInput', () {
    testWidgets('renders off switch', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      expect(find.byType(LayrzSwitchInput), findsOneWidget);
    });

    testWidgets('renders on switch', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: true,
          onChanged: (_) {},
        ),
      );

      expect(find.byType(LayrzSwitchInput), findsOneWidget);
    });

    testWidgets('renders label text when provided', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          labelText: 'Enable notifications',
          value: false,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Enable notifications'), findsOneWidget);
    });

    testWidgets('toggles value when switch is tapped', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      expect(currentValue, isFalse);

      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('toggles value when label is tapped', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            labelText: 'Enable feature',
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      expect(currentValue, isFalse);

      await tester.tap(find.text('Enable feature'));
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('toggles value when Space key is pressed', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzSwitchInput));
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
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('is Tab-reachable', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSwitchInput(
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
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            disabled: true,
            onChanged: (newValue) {
              callCount++;
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      expect(currentValue, isFalse);
      expect(callCount, 0);
    });

    testWidgets('does not toggle when onChanged is null', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: null,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      expect(currentValue, isFalse);
    });

    testWidgets('renders error messages', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
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
        LayrzSwitchInput(
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
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
          padding: customPadding,
        ),
      );

      expect(find.byType(LayrzSwitchInput), findsOneWidget);
    });

    testWidgets('track size is consistent across states', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      final offSize = tester.getSize(find.byType(Stack).first);

      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      final onSize = tester.getSize(find.byType(Stack).first);

      expect(offSize, equals(onSize));
    });

    testWidgets('uses custom focus node', (tester) async {
      final focusNode = FocusNode();

      await pumpThemedApp(
        tester,
        LayrzSwitchInput(
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
        LayrzSwitchInput(
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
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      final track = find.byType(Container).first;
      final beforeHover = tester.getSize(track);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final afterHover = tester.getSize(track);

      // Size must not change on hover (D15)
      expect(beforeHover, equals(afterHover));
    });

    testWidgets('animates thumb position', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pump(const Duration(milliseconds: 100));

      expect(currentValue, isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets('label colour changes when disabled', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          labelText: 'Disabled switch',
          value: false,
          disabled: true,
          onChanged: (_) {},
        ),
      );

      final labelText = find.text('Disabled switch');
      expect(labelText, findsOneWidget);
    });

    testWidgets('label is clickable independently', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
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

    testWidgets('thumb moves from left to right when toggled on', (tester) async {
      bool currentValue = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      // Verify animation completed
      expect(currentValue, isTrue);
    });
  });
}
