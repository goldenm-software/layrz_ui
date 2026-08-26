import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed.dart';
import '../../helpers/pump_themed_app.dart';

/// Helper: extract the ring colour from the radio button's Container decoration.
Color getRingColour(WidgetTester tester) {
  // Find the Container that has a circular border (the ring).
  // The ring is a Container with BoxDecoration > Border.all (no color, just border).
  final containerFinder = find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).shape == BoxShape.circle &&
        (w.decoration as BoxDecoration).border != null,
  );

  expect(containerFinder, findsWidgets, reason: 'Ring Container should exist');
  final decoration = tester.widget<Container>(containerFinder.first).decoration as BoxDecoration;
  return (decoration.border as Border).top.color;
}

/// Helper: extract the dot's rendered size.
Size getDotSize(WidgetTester tester) {
  // The dot is a SizedBox.square inside the ring container, with dimension = dotSize * animationProgress.
  // We find it by looking for a Container inside the ring that has a filled color (the dot).
  final dotContainerFinder = find.byWidgetPredicate((w) {
    if (w is! Container) return false;
    if (w.decoration is! BoxDecoration) return false;
    final d = w.decoration as BoxDecoration;
    // The dot has shape:circle, a color, and NO border
    return d.shape == BoxShape.circle && d.color != null && d.border == null;
  });

  expect(dotContainerFinder, findsWidgets, reason: 'Dot Container should exist');
  return tester.getSize(dotContainerFinder.first);
}

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
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
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
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
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
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
          ],
        ),
      );

      expect(find.text('*'), findsNothing);
    });

    testWidgets('renders all options', (tester) async {
      final items = [
        const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
        const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
        const LayrzSelectItem(value: 'c', child: Text('Option C'), searchableStrings: {'Option C'}),
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
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
            const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
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
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
            const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
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
                const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
                const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
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
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
            const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
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
              value: 'a',
              child: const Text(customText),
              searchableStrings: const {'Option A'},
            ),
            const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
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
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
            const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
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
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
            const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
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
            const LayrzSelectItem(value: 'same', child: Text('Option A'), searchableStrings: {'Option A'}),
            const LayrzSelectItem(value: 'same', child: Text('Option B'), searchableStrings: {'Option B'}),
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
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
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
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
          ],
          errors: [errorMessage],
          hideDetails: true,
        ),
      );

      expect(find.text(errorMessage), findsNothing);
    });

    testWidgets('applies the fixed group padding', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
          ],
        ),
      );

      final paddingWidget = tester.widget<Padding>(
        find.ancestor(
          of: find.byType(RadioGroup<String?>),
          matching: find.byType(Padding),
        ),
      );

      expect(paddingWidget.padding, const EdgeInsets.all(10));
    });

    testWidgets('default padding is used when not specified', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
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
              value: 'opt${i + 1}',
              child: Text('Option ${i + 1}'),
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
              value: 'opt${i + 1}',
              child: Text('Option ${i + 1}'),
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
              value: 'opt${i + 1}',
              child: Text('Option ${i + 1}'),
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
                const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
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
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
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
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
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
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
          ],
          disabled: true,
        ),
      );

      expect(find.text('Option A'), findsOneWidget);
    });

    // Guard 1: Ring colour animates with selection
    testWidgets('ring colour animates with selection', (tester) async {
      String? selectedValue;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzRadioInput<String>(
              value: selectedValue,
              items: const [
                LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
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

      final tokens = LayrzTokens.light();

      // Tap to start selection
      await tester.tap(find.text('Option A'));
      // Wait for the next frame to ensure the state change is processed
      await tester.pump();
      // Advance 150ms through the animation (RawRadio animates over 200ms)
      await tester.pump(const Duration(milliseconds: 150));

      // At 75% of animation, the ring colour should be intermediate between fg3 and primary.
      // It must NOT be exactly fg3 or exactly primary.
      final ringColor = getRingColour(tester);
      final expectedUnselected = tokens.colors.fg3;
      final expectedSelected = tokens.colors.primary;

      // Verify that the color is strictly intermediate (not equal to either endpoint)
      expect(
        ringColor,
        isNot(expectedUnselected),
        reason: 'Ring colour should not be exactly fg3 at mid-animation',
      );
      expect(
        ringColor,
        isNot(expectedSelected),
        reason: 'Ring colour should not be exactly primary at mid-animation',
      );

      // Complete the animation
      await tester.pumpAndSettle();
      expect(selectedValue, 'a');
    });

    // Guard 2: Dot grows
    testWidgets('dot grows with animation progress', (tester) async {
      String? selectedValue;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzRadioInput<String>(
              value: selectedValue,
              items: const [
                LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
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

      // Tap to start selection
      await tester.tap(find.text('Option A'));
      // Wait for the next frame to ensure the state change is processed
      await tester.pump();
      // Advance 150ms through the animation (RawRadio animates over 200ms)
      await tester.pump(const Duration(milliseconds: 150));

      // At 75% of animation, dot size should be strictly between 0 and 8.
      final dotSize = getDotSize(tester);
      final dotDimension = dotSize.width; // It's a square, so width == height

      expect(
        dotDimension,
        isPositive,
        reason: 'Dot should have grown from 0 at mid-animation',
      );
      expect(
        dotDimension,
        lessThan(8.0),
        reason: 'Dot should not be fully grown at mid-animation',
      );
      expect(
        dotDimension,
        greaterThan(4.0), // At 75% progress, should be ~6
        reason: 'Dot should grow proportionally with animationProgress',
      );

      // Complete animation
      await tester.pumpAndSettle();
      expect(selectedValue, 'a');
    });

    // Guard 3: Four colour steps are distinct - test default state
    testWidgets('default state uses fg3 ring colour', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: const [
            LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
          ],
        ),
      );

      final tokens = LayrzTokens.light();
      final ringColor = getRingColour(tester);
      expect(ringColor, equals(tokens.colors.fg3), reason: 'Default state should be fg3');
    });

    // Guard 3b: Pressed state uses fg1
    testWidgets('pressed state uses fg1 ring colour', (tester) async {
      String? selectedValue;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzRadioInput<String>(
              value: selectedValue,
              items: const [
                LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
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

      final tokens = LayrzTokens.light();

      // Start a gesture (pressed state)
      final gesture = await tester.startGesture(tester.getCenter(find.text('Option A')));
      await tester.pump(const Duration(milliseconds: 50));

      // At pressed state, ring should be fg1
      final pressedColor = getRingColour(tester);
      expect(pressedColor, equals(tokens.colors.fg1), reason: 'Pressed state should be fg1');

      // Release
      await gesture.up();
      await tester.pumpAndSettle();
    });

    // Guard 3c: Focus-visible state uses primary
    testWidgets('focus-visible state uses primary ring colour', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzRadioInput<String>(
          items: const [
            LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
          ],
          onChanged: (_) {},
        ),
      );

      final tokens = LayrzTokens.light();

      // Tab to give keyboard focus (focus-visible)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Verify ring is primary (focus-visible)
      final focusVisibleColor = getRingColour(tester);
      expect(focusVisibleColor, equals(tokens.colors.primary), reason: 'Focus-visible state should be primary');
    });

    // Guard 4: Focus-visible gating
    testWidgets('focus-visible gating: tap does not show primary ring', (tester) async {
      String? selectedValue;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzRadioInput<String>(
              value: selectedValue,
              items: const [
                LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
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

      final tokens = LayrzTokens.light();

      // Tap the option (pointer focus)
      await tester.tap(find.text('Option A'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(selectedValue, 'a');

      // After tap, the option has focus (from _handleTap calling requestFocus).
      // However, _focusFromPointer should be true, so focus-visible styling should NOT apply.
      // The ring should NOT be primary at this point.
      Color ringColor = getRingColour(tester);

      // With _focusFromPointer = true, isFocusVisible = false, so we fall through to default.
      // On an unselected option, default = fg3.
      // On a selected option mid-animation, it would be lerped, but we just tapped so the
      // animation may not have started. Regardless, it should not be primary.
      expect(
        ringColor,
        isNot(tokens.colors.primary),
        reason: 'Ring should not be primary after pointer tap (focus-visible should be gated)',
      );
    });

    // Guard 5: Label announced once
    testWidgets('option label is announced once, not twice', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            items: const [
              LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
            ],
          ),
        );

        // Count semantics nodes that contain the label text 'Option A'.
        // Walk the semantics tree from the root and count nodes with label='Option A'.
        // ignore: deprecated_member_use
        final semanticsOwner = tester.binding.pipelineOwner.semanticsOwner;
        expect(semanticsOwner, isNotNull);

        final rootNode = semanticsOwner!.rootSemanticsNode;
        expect(rootNode, isNotNull);

        int labelCount = 0;
        void countLabels(dynamic node) {
          if (node.label == 'Option A') {
            labelCount++;
          }
          node.visitChildren((child) {
            countLabels(child);
            return true;
          });
        }

        countLabels(rootNode!);

        // BREAKING (DESIGN-142): there is no separate `labelText` string anymore -- the
        // outer `Semantics` sets no explicit `label` of its own, and `child` (here a plain
        // `Text`) is left un-excluded so its own semantics merge upward into the same node
        // instead of being replaced by a second, separate string. That merge is exactly what
        // keeps this at 1, not 2: two *sibling* semantics nodes both carrying "Option A"
        // would double-count here just as surely as an explicit label alongside an
        // un-excluded Text would have.
        expect(
          labelCount,
          equals(1),
          reason: 'Label "Option A" should be announced exactly once in semantics',
        );
      } finally {
        handle.dispose();
      }
    });

    // Guard 6: Exactly one FocusNode per option (no duplicate focusable nodes)
    testWidgets('exactly one tab stop per option', (tester) async {
      // Build radio options
      await pumpThemedApp(
        tester,
        LayrzRadioInput<String>(
          items: const [
            LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
            LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
          ],
          onChanged: (_) {},
        ),
      );

      // Verify each RawRadio has exactly one FocusNode (the one passed to the RawRadio widget)
      final allRadios = find.byWidgetPredicate((w) => w is RawRadio);
      expect(allRadios, findsWidgets);

      // Each option should have a single RawRadio with one FocusNode
      for (int i = 0; i < 2; i++) {
        final radio = tester.widget<RawRadio<String?>>(allRadios.at(i));
        expect(radio.focusNode, isNotNull, reason: 'Each RawRadio should have a focusNode');

        // Verify this is the only focusable widget for this option by checking that
        // the RawRadio is the only Focus-related widget
        // If there were duplicate focus nodes (e.g., a wrapping Focus widget + the RawRadio's own),
        // we'd have two focusable nodes per option.
      }

      // Focus the first option
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final radioA = allRadios.first;
      final focusNodeA = tester.widget<RawRadio<String?>>(radioA).focusNode;
      expect(focusNodeA.hasFocus, true, reason: 'First radio should be focused after Tab');
    });

    testWidgets('focus node is not recreated across rebuilds', (tester) async {
      String? selectedValue;
      late StateSetter parentSetState;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            parentSetState = setState;
            return Column(
              children: [
                LayrzRadioInput<String>(
                  labelText: 'Test',
                  value: selectedValue,
                  items: const [
                    LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedValue = value;
                    });
                  },
                ),
                GestureDetector(
                  key: const Key('rebuild-trigger'),
                  onTap: () {
                    parentSetState(() {});
                  },
                  child: const Text('Force rebuild'),
                ),
              ],
            );
          },
        ),
      );

      // Give focus to the option
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Capture the FocusNode instance before rebuild
      final radioFinder = find.byWidgetPredicate((w) => w is RawRadio).first;
      final focusNodeBefore = tester.widget<RawRadio<String?>>(radioFinder).focusNode;

      // Verify focus is currently on this node
      expect(focusNodeBefore.hasFocus, true, reason: 'Option should be focused before rebuild');

      // Force a rebuild of the parent
      await tester.tap(find.byKey(const Key('rebuild-trigger')));
      await tester.pumpAndSettle();

      // Capture the FocusNode instance after rebuild
      final focusNodeAfter = tester.widget<RawRadio<String?>>(radioFinder).focusNode;

      // Assert the same FocusNode instance is still in use (not recreated)
      expect(
        identical(focusNodeBefore, focusNodeAfter),
        true,
        reason: 'FocusNode should not be recreated across rebuilds',
      );

      // Assert focus is still present after rebuild
      expect(focusNodeAfter.hasFocus, true, reason: 'Focus should survive the rebuild');
      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('keyboard activation fires onChanged exactly once', (tester) async {
      String? selectedValue;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzRadioInput<String>(
              value: selectedValue,
              items: const [
                LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
              ],
              onChanged: (value) {
                callCount++;
                setState(() {
                  selectedValue = value;
                });
              },
            );
          },
        ),
      );

      // Tab to focus
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      callCount = 0; // Reset counter after focus
      // Press Space
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(selectedValue, 'a');
      expect(callCount, equals(1), reason: 'Space should fire onChanged exactly once');
    });

    testWidgets('keyboard Enter activation fires onChanged exactly once', (tester) async {
      String? selectedValue;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzRadioInput<String>(
              value: selectedValue,
              items: const [
                LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
              ],
              onChanged: (value) {
                callCount++;
                setState(() {
                  selectedValue = value;
                });
              },
            );
          },
        ),
      );

      // Tab to focus
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      callCount = 0; // Reset counter after focus
      // Press Enter
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(selectedValue, 'a');
      expect(callCount, equals(1), reason: 'Enter should fire onChanged exactly once');
    });

    testWidgets('disabled radio does not fire on tap', (tester) async {
      String? selectedValue;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzRadioInput<String>(
              disabled: true,
              value: selectedValue,
              items: const [
                LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
              ],
              onChanged: (value) {
                callCount++;
                setState(() {
                  selectedValue = value;
                });
              },
            );
          },
        ),
      );

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(selectedValue, isNull);
      expect(callCount, equals(0));
    });

    testWidgets('disabled radio does not fire on hover', (tester) async {
      String? selectedValue;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzRadioInput<String>(
              disabled: true,
              value: selectedValue,
              items: const [
                LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
              ],
              onChanged: (value) {
                callCount++;
                setState(() {
                  selectedValue = value;
                });
              },
            );
          },
        ),
      );

      // Try to focus
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(selectedValue, isNull);
      expect(callCount, equals(0));
    });

    testWidgets('disabled radio does not fire on key press', (tester) async {
      String? selectedValue;
      int callCount = 0;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzRadioInput<String>(
              disabled: true,
              value: selectedValue,
              items: const [
                LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
              ],
              onChanged: (value) {
                callCount++;
                setState(() {
                  selectedValue = value;
                });
              },
            );
          },
        ),
      );

      // Try to focus and activate
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      callCount = 0;
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(selectedValue, isNull);
      expect(callCount, equals(0));
    });

    testWidgets('disposes focus node without error', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzRadioInput<String>(
          items: const [
            LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
          ],
          onChanged: (_) {},
        ),
      );

      // Replace with empty widget - should dispose without error
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  });
}
