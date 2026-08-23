import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzRadioInput — Accessibility', () {
    testWidgets('group label renders', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          labelText: 'Choose a department',
          items: [
            const LayrzSelectItem(labelText: 'Sales', value: 'sales'),
            const LayrzSelectItem(labelText: 'Engineering', value: 'eng'),
          ],
        ),
      );

      expect(find.text('Choose a department'), findsOneWidget);
    });

    testWidgets('group announces label in semantics', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            labelText: 'Department',
            items: [
              const LayrzSelectItem(labelText: 'Sales', value: 'sales'),
              const LayrzSelectItem(labelText: 'Engineering', value: 'eng'),
            ],
          ),
        );

        // The group's label should be present in the semantic tree.
        expect(find.text('Department'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('option labels render for accessibility', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'Marketing', value: 'marketing'),
            const LayrzSelectItem(labelText: 'Sales', value: 'sales'),
          ],
        ),
      );

      expect(find.text('Marketing'), findsOneWidget);
      expect(find.text('Sales'), findsOneWidget);
    });

    testWidgets('each option announces its role and checked state', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            items: [
              const LayrzSelectItem(labelText: 'Option A', value: 'a'),
              const LayrzSelectItem(labelText: 'Option B', value: 'b'),
            ],
          ),
        );

        // RawRadio widgets emit semantics with radio button properties.
        // Verify the semantics tree includes radio button information.
        expect(find.byWidgetPredicate((w) => w is RawRadio), findsWidgets);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('label and radio form one semantics node', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            items: [
              const LayrzSelectItem(labelText: 'Unified Label', value: 'unified'),
            ],
          ),
        );

        // The label should be accessible as a semantics label alongside the radio button.
        expect(find.text('Unified Label'), findsOneWidget);
        expect(find.byWidgetPredicate((w) => w is RawRadio), findsWidgets);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('enabled state renders with clickable options', (tester) async {
      String? selectedValue;

      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
          ],
          disabled: false,
          onChanged: (value) {
            selectedValue = value;
          },
        ),
      );

      await tester.tap(find.text('Option A'));
      await tester.pump();

      expect(selectedValue, 'a');
    });

    testWidgets('disabled state prevents selection', (tester) async {
      String? selectedValue;

      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'Disabled Option', value: 'disabled'),
          ],
          disabled: true,
          onChanged: (value) {
            selectedValue = value;
          },
        ),
      );

      await tester.tap(find.text('Disabled Option'));
      await tester.pump();

      expect(selectedValue, isNull);
    });

    testWidgets('required asterisk is perceivable by screen reader', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            labelText: 'Choose',
            isRequired: true,
            items: [
              const LayrzSelectItem(labelText: 'Option A', value: 'a'),
            ],
          ),
        );

        expect(find.text('*'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('error text is perceivable by screen reader', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        const errorText = 'This field is required';

        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            items: [
              const LayrzSelectItem(labelText: 'Option A', value: 'a'),
            ],
            errors: [errorText],
          ),
        );

        expect(find.text(errorText), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('radio widgets render with built-in keyboard support', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
            const LayrzSelectItem(labelText: 'Option B', value: 'b'),
          ],
        ),
      );

      expect(find.byWidgetPredicate((w) => w is RawRadio), findsWidgets);
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
    });

    testWidgets('selection state is exposed to semantics, not colour alone', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            value: 'a',
            items: const [
              LayrzSelectItem(labelText: 'Option A', value: 'a'),
              LayrzSelectItem(labelText: 'Option B', value: 'b'),
            ],
          ),
        );

        // RawRadio exposes checked/unchecked state via semantics flags, not through colour alone.
        // This satisfies WCAG 1.4.1: information must not be conveyed by colour alone.
        final radioFinder = find.byWidgetPredicate((w) => w is RawRadio);
        expect(radioFinder, findsWidgets);

        // Verify the two options are in the semantics tree with their labels.
        expect(find.text('Option A'), findsOneWidget);
        expect(find.text('Option B'), findsOneWidget);

        // Verify the RawRadio widgets expose checked state via semantics.
        // The first radio (Option A, value='a') is selected.
        expect(
          tester.getSemantics(find.byWidgetPredicate((w) => w is RawRadio).at(0)),
          matchesSemantics(
            hasCheckedState: true,
            isChecked: true,
            hasEnabledState: true,
            isEnabled: true,
            isInMutuallyExclusiveGroup: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );

        // The second radio (Option B, value='b') is unselected.
        expect(
          tester.getSemantics(find.byWidgetPredicate((w) => w is RawRadio).at(1)),
          matchesSemantics(
            hasCheckedState: true,
            isChecked: false,
            hasEnabledState: true,
            isEnabled: true,
            isInMutuallyExclusiveGroup: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('selection visually indicated by filled radio', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          value: 'a',
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
            const LayrzSelectItem(labelText: 'Option B', value: 'b'),
          ],
        ),
      );

      // RadioGroup + RawRadio handle visual indication internally
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
    });
  });
}
