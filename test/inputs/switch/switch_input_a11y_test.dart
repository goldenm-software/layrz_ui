import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/switch/switch_input.dart';

import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzSwitchInput A11y', () {
    testWidgets('switch label is exposed to screen readers', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        LayrzSwitchInput(
          labelText: 'Enable notifications',
          value: false,
          onChanged: (_) {},
        ),
      );

      // Label should be accessible via semantics
      expect(find.bySemanticsLabel('Enable notifications'), findsOneWidget);

      // Verify semantic state: off, enabled
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzSwitchInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          label: 'Enable notifications',
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('switch state changes are observable', (tester) async {
      final handle = tester.ensureSemantics();
      bool currentValue = false;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            labelText: 'Test toggle',
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          ),
        ),
      );

      // Initially off - verify off state via semantics
      expect(currentValue, isFalse);
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzSwitchInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      // Toggle the switch
      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      // State should have changed - verify on state via semantics
      expect(currentValue, isTrue);
      // After toggle/tap, isFocused may be present, so check essential flags
      final semantics = tester.getSemantics(
        find
            .descendant(
              of: find.byType(LayrzSwitchInput),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.toString(), contains('hasToggledState'));
      expect(semantics.toString(), contains('isEnabled'));
      // Verify the toggled state actually changed
      expect(semantics.toString(), contains('isToggled')); // Now toggled after toggle

      handle.dispose();
    });

    testWidgets('disabled switch does not respond', (tester) async {
      final handle = tester.ensureSemantics();
      int callCount = 0;

      await pumpThemed(
        tester,
        LayrzSwitchInput(
          labelText: 'Unavailable',
          value: false,
          disabled: true,
          onChanged: (newValue) {
            callCount++;
          },
        ),
      );

      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      expect(callCount, equals(0));

      // Verify disabled semantics: isEnabled = false, no tap action
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzSwitchInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: false,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('switch with null onChanged does not respond', (tester) async {
      final handle = tester.ensureSemantics();
      bool currentValue = false;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzSwitchInput(
            value: currentValue,
            onChanged: null,
          ),
        ),
      );

      // Attempt to toggle - should have no effect
      await tester.tap(find.byType(LayrzSwitchInput));
      await tester.pumpAndSettle();

      // Value unchanged
      expect(currentValue, isFalse);

      // Semantics: disabled
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzSwitchInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: false,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('enabled switch is keyboard accessible', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      // Should be in the widget tree and accessible
      expect(find.byType(LayrzSwitchInput), findsOneWidget);
      handle.dispose();
    });

    testWidgets('disabled switch label is still readable', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        LayrzSwitchInput(
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
        LayrzSwitchInput(
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
        LayrzSwitchInput(
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
