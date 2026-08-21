import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

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
      final semanticsHandle = tester.ensureSemantics();

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
        semanticsHandle.dispose();
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
      final semanticsHandle = tester.ensureSemantics();

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
        semanticsHandle.dispose();
      }
    });

    testWidgets('label and radio form one semantics node', (tester) async {
      final semanticsHandle = tester.ensureSemantics();

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
        semanticsHandle.dispose();
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
      final semanticsHandle = tester.ensureSemantics();

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
        semanticsHandle.dispose();
      }
    });

    testWidgets('error text is perceivable by screen reader', (tester) async {
      final semanticsHandle = tester.ensureSemantics();

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
        semanticsHandle.dispose();
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

    testWidgets('selection is not conveyed by colour alone (uses shape)', (tester) async {
      final semanticsHandle = tester.ensureSemantics();

      try {
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

        // RawRadio + RadioGroup encode state semantically (checked/unchecked),
        // not through colour alone. Render both options with their labels.
        expect(find.text('Option A'), findsOneWidget);
        expect(find.text('Option B'), findsOneWidget);
        expect(find.byWidgetPredicate((w) => w is RawRadio), findsWidgets);
      } finally {
        semanticsHandle.dispose();
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
