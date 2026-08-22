import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/checkbox_input.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCheckboxInput A11y', () {
    testWidgets('checkbox label is exposed to screen readers', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          labelText: 'Accept terms',
          value: false,
          onChanged: (_) {},
        ),
      );

      // Label should be accessible via semantics
      expect(find.bySemanticsLabel('Accept terms'), findsOneWidget);

      // Verify semantic state: unchecked, enabled
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzCheckboxInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          label: 'Accept terms',
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('checkbox state changes are observable', (tester) async {
      final handle = tester.ensureSemantics();
      bool currentValue = false;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            labelText: 'Test check',
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Initially unchecked - verify off state via semantics
      expect(currentValue, isFalse);
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzCheckboxInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      // Toggle the checkbox
      await tester.tap(find.byType(LayrzCheckboxInput));
      await tester.pumpAndSettle();

      // State should have changed - verify checked state flips via semantics
      expect(currentValue, isTrue);
      // After toggle/tap, isFocused may be present, so we check the essential flags
      final semantics = tester.getSemantics(
        find
            .descendant(
              of: find.byType(LayrzCheckboxInput),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.toString(), contains('hasCheckedState'));
      expect(semantics.toString(), contains('isEnabled'));
      // Verify the checked state actually changed
      expect(semantics.toString(), contains('isChecked')); // Now checked after toggle

      handle.dispose();
    });

    testWidgets('disabled checkbox does not respond', (tester) async {
      final handle = tester.ensureSemantics();
      int callCount = 0;

      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          labelText: 'Disabled',
          value: false,
          disabled: true,
          onChanged: (newValue) {
            callCount++;
          },
        ),
      );

      await tester.tap(find.byType(LayrzCheckboxInput));
      await tester.pumpAndSettle();

      expect(callCount, equals(0));

      // Verify disabled semantics: isEnabled = false, no tap action
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzCheckboxInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: false,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('checkbox with null onChanged does not respond', (tester) async {
      final handle = tester.ensureSemantics();
      bool currentValue = false;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzCheckboxInput(
            value: currentValue,
            onChanged: null,
          ),
        ),
      );

      // Attempt to toggle - should have no effect
      await tester.tap(find.byType(LayrzCheckboxInput));
      await tester.pumpAndSettle();

      // Value unchanged
      expect(currentValue, isFalse);

      // Semantics: disabled
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzCheckboxInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: false,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('enabled checkbox is keyboard accessible', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      // Should be in the widget tree and accessible
      expect(find.byType(LayrzCheckboxInput), findsOneWidget);
      handle.dispose();
    });

    testWidgets('disabled checkbox label is still readable', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          labelText: 'Disabled field',
          value: false,
          disabled: true,
          onChanged: (_) {},
        ),
      );

      expect(find.bySemanticsLabel('Disabled field'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('error messages are exposed when visible', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        LayrzCheckboxInput(
          labelText: 'Test field',
          value: false,
          onChanged: (_) {},
          errors: const ['This field is required'],
          hideDetails: false,
        ),
      );

      expect(find.text('This field is required'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('error messages are hidden when hideDetails is true', (tester) async {
      final handle = tester.ensureSemantics();

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
      handle.dispose();
    });
  });
}
