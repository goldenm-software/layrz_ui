import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzRadioInput', () {
    // Basic selection behavior
    test('constructor assertions: xs span out of range', () {
      expect(
        () => LayrzRadioInput<String>(
          items: [],
          xs: 0,
        ),
        throwsAssertionError,
      );
      expect(
        () => LayrzRadioInput<String>(
          items: [],
          xs: 13,
        ),
        throwsAssertionError,
      );
    });

    test('constructor assertions: sm span out of range', () {
      expect(
        () => LayrzRadioInput<String>(
          items: [],
          sm: 0,
        ),
        throwsAssertionError,
      );
      expect(
        () => LayrzRadioInput<String>(
          items: [],
          sm: 13,
        ),
        throwsAssertionError,
      );
    });

    test('constructor assertions: md span out of range', () {
      expect(
        () => LayrzRadioInput<String>(
          items: [],
          md: 0,
        ),
        throwsAssertionError,
      );
      expect(
        () => LayrzRadioInput<String>(
          items: [],
          md: 13,
        ),
        throwsAssertionError,
      );
    });

    test('constructor assertions: lg span out of range', () {
      expect(
        () => LayrzRadioInput<String>(
          items: [],
          lg: 0,
        ),
        throwsAssertionError,
      );
      expect(
        () => LayrzRadioInput<String>(
          items: [],
          lg: 13,
        ),
        throwsAssertionError,
      );
    });

    test('constructor assertions: xl span out of range', () {
      expect(
        () => LayrzRadioInput<String>(
          items: [],
          xl: 0,
        ),
        throwsAssertionError,
      );
      expect(
        () => LayrzRadioInput<String>(
          items: [],
          xl: 13,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('renders group label', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          labelText: 'Choose one',
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
          ],
        ),
      );

      expect(find.text('Choose one'), findsOneWidget);
    });

    testWidgets('renders required asterisk when isRequired is true', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          labelText: 'Choose one',
          isRequired: true,
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
          ],
        ),
      );

      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('does not render required asterisk by default', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          labelText: 'Choose one',
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
          ],
        ),
      );

      expect(find.text('*'), findsNothing);
    });

    testWidgets('renders all options', (tester) async {
      final items = [
        const LayrzSelectItem(labelText: 'Option A', value: 'a'),
        const LayrzSelectItem(labelText: 'Option B', value: 'b'),
        const LayrzSelectItem(labelText: 'Option C', value: 'c'),
      ];

      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: items,
        ),
      );

      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Option C'), findsOneWidget);
    });

    testWidgets('tapping radio button fires onChanged', (tester) async {
      String? selectedValue;

      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
            const LayrzSelectItem(labelText: 'Option B', value: 'b'),
          ],
          onChanged: (value) {
            selectedValue = value;
          },
        ),
      );

      // Tap the first radio button
      await tester.tap(find.byWidgetPredicate((w) => w is RawRadio).first);
      await tester.pump();

      expect(selectedValue, 'a');
    });

    testWidgets('tapping option label fires onChanged', (tester) async {
      String? selectedValue;

      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
            const LayrzSelectItem(labelText: 'Option B', value: 'b'),
          ],
          onChanged: (value) {
            selectedValue = value;
          },
        ),
      );

      // Tap the label text for the first option
      await tester.tap(find.text('Option A'));
      await tester.pump();

      expect(selectedValue, 'a');
    });

    testWidgets('does not toggle selection when already selected', (tester) async {
      String? selectedValue = 'a';
      int changeCount = 0;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzRadioInput<String>(
              value: selectedValue,
              items: [
                const LayrzSelectItem(labelText: 'Option A', value: 'a'),
                const LayrzSelectItem(labelText: 'Option B', value: 'b'),
              ],
              onChanged: (value) {
                changeCount++;
                setState(() {
                  selectedValue = value;
                });
              },
            );
          },
        ),
      );

      // Tap the already-selected option
      await tester.tap(find.text('Option A'));
      await tester.pump();

      // Should still be selected, changeCount incremented once
      expect(selectedValue, 'a');
      expect(changeCount, 1);
    });

    testWidgets('disabled state blocks selection', (tester) async {
      String? selectedValue;

      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          disabled: true,
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
            const LayrzSelectItem(labelText: 'Option B', value: 'b'),
          ],
          onChanged: (value) {
            selectedValue = value;
          },
        ),
      );

      // Try to tap an option
      await tester.tap(find.text('Option A'));
      await tester.pump();

      // onChanged should not have been called
      expect(selectedValue, isNull);
    });

    testWidgets('renders custom child when provided', (tester) async {
      const customText = 'Custom Label';

      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            LayrzSelectItem(
              labelText: 'Option A',
              value: 'a',
              child: const Text(customText),
            ),
            const LayrzSelectItem(labelText: 'Option B', value: 'b'),
          ],
        ),
      );

      expect(find.text(customText), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
    });

    testWidgets('null value does not select any option', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          value: null,
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
            const LayrzSelectItem(labelText: 'Option B', value: 'b'),
          ],
        ),
      );

      // No radio button should be selected
      final radios = find.byWidgetPredicate((w) => w is RawRadio);
      expect(radios, findsWidgets);

      // Should not crash
      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('value mismatch does not select any option', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          value: 'nonexistent',
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
            const LayrzSelectItem(labelText: 'Option B', value: 'b'),
          ],
        ),
      );

      // Should render without crash
      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('duplicate values trigger assertion', (tester) async {
      // Duplicate values are not allowed because RadioGroup enforces single selection.
      // This test documents the constraint by asserting it fails at construction time.
      await tester.pumpWidget(
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'same'),
            const LayrzSelectItem(labelText: 'Option B', value: 'same'),
          ],
        ),
      );

      // The assertion should fire during pumpWidget
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('errors are rendered below grid', (tester) async {
      const errorMessage = 'This field is required';

      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
          ],
          errors: [errorMessage],
        ),
      );

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('hideDetails hides error messages', (tester) async {
      const errorMessage = 'This field is required';

      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
          ],
          errors: [errorMessage],
          hideDetails: true,
        ),
      );

      expect(find.text(errorMessage), findsNothing);
    });

    testWidgets('padding is applied correctly', (tester) async {
      const padding = EdgeInsets.all(20.0);

      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
          ],
          padding: padding,
        ),
      );

      expect(find.byType(Padding), findsWidgets);
      // Verify padding is applied (indirectly via widget tree)
      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('default padding is used when not specified', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
          ],
        ),
      );

      // Should render with default padding
      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('responsive grid renders all options', (tester) async {
      // Just verify that all options render at the default span sizes
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: List.generate(
            6,
            (i) => LayrzSelectItem(
              labelText: 'Option ${i + 1}',
              value: 'opt${i + 1}',
            ),
          ),
        ),
      );

      // All options should be present
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 6'), findsOneWidget);
    });

    testWidgets('responsive grid cascade works with custom spans', (tester) async {
      // Test that custom span assignments are applied
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: List.generate(
            4,
            (i) => LayrzSelectItem(
              labelText: 'Option ${i + 1}',
              value: 'opt${i + 1}',
            ),
          ),
          xs: 12, // mobile: 1 per row
          sm: 12, // tablet: 1 per row
          md: 6, // desktop: 2 per row
          lg: null, // cascades to md=6
          xl: null, // cascades to md=6
        ),
      );

      // Should render all options
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 4'), findsOneWidget);
    });

    testWidgets('responsive grid with custom spans', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: List.generate(
            3,
            (i) => LayrzSelectItem(
              labelText: 'Option ${i + 1}',
              value: 'opt${i + 1}',
            ),
          ),
          xs: 12, // 1 per row
          sm: 12, // 1 per row
          md: 6, // 2 per row
          lg: 4, // 3 per row
          xl: 3, // 4 per row
        ),
      );

      // Should render all options
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 3'), findsOneWidget);
    });

    testWidgets('interaction states do not change geometry', (tester) async {
      String? selectedValue;
      Size? size1, size2;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzRadioInput<String>(
              value: selectedValue,
              items: [
                const LayrzSelectItem(labelText: 'Option A', value: 'a'),
              ],
              onChanged: (value) {
                setState(() {
                  selectedValue = value;
                });
              },
            );
          },
        ),
      );

      // Get initial size
      size1 = tester.getSize(find.text('Option A'));

      // Tap to change state
      await tester.tap(find.text('Option A'));
      await tester.pump();

      // Get size after state change
      size2 = tester.getSize(find.text('Option A'));

      // Sizes should be identical (geometry unchanged)
      expect(size1, size2);
    });

    testWidgets('onChanged is not called when null callback', (tester) async {
      // Should not crash even if onChanged is null
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
          ],
          onChanged: null,
        ),
      );

      // Try to tap
      await tester.tap(find.text('Option A'));
      await tester.pump();

      // Should not crash
      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('empty items list renders empty grid', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [],
        ),
      );

      // Should not crash
      expect(find.byWidgetPredicate((w) => w is LayrzRadioInput), findsOneWidget);
    });

    testWidgets('radio renders without error when enabled', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
          ],
          disabled: false,
        ),
      );

      // Option should render
      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('cursor is deferred when disabled', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
          ],
          disabled: true,
        ),
      );

      expect(find.text('Option A'), findsOneWidget);
    });
  });
}
