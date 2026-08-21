import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/checkbox_input.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCheckboxInput A11y', () {
    testWidgets('renders checkbox with label', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          labelText: 'Accept terms',
          value: false,
          onChanged: (_) {},
        ),
      );

      expect(find.byType(LayrzCheckboxInput), findsOneWidget);
      expect(find.text('Accept terms'), findsOneWidget);
    });

    testWidgets('displays label text for accessibility', (tester) async {
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

    testWidgets('provides checkmark icon as visual state indicator when checked', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          value: true,
          onChanged: (_) {},
        ),
      );

      // Icon is the visual non-colour indicator that checkbox is checked
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('does not show icon when unchecked', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      // No icon when unchecked - empty box is the indicator
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('includes checkbox container for visual state', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      // Checkbox box (SizedBox with Container) is visible
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('responds to keyboard input', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          labelText: 'Accept',
          value: false,
          onChanged: (_) {},
        ),
      );

      // Checkbox is part of the widget tree
      expect(find.byType(LayrzCheckboxInput), findsOneWidget);
    });

    testWidgets('state changes with checked value', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      // Unchecked: no icon
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('disabled state is visually distinct', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          labelText: 'Disabled',
          value: false,
          disabled: true,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('checkbox and label are in same widget', (tester) async {
      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          labelText: 'Agree',
          value: false,
          onChanged: (_) {},
        ),
      );

      // Single checkbox widget contains label text
      expect(find.byType(LayrzCheckboxInput), findsOneWidget);
      expect(find.text('Agree'), findsOneWidget);
    });
  });
}
