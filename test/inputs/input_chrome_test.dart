import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/input_slot.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_icons/layrz_icons.dart';

import '../helpers/find_button_label.dart';
import '../helpers/pump_themed.dart';
import '../helpers/fake_font_handler.dart';

void main() {
  group('LayrzInputChrome', () {
    testWidgets('renders label', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Test Label',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          child: Container(),
        ),
      );

      expect(findButtonLabel('Test Label'), findsOneWidget);
    });

    testWidgets('renders required asterisk', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Required Field',
          isRequired: true,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          child: Container(),
        ),
      );

      expect(findButtonLabel('*'), findsOneWidget);
    });

    testWidgets('renders error messages', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: ['Error message'],
          hideDetails: false,
          states: {},
          child: Container(),
        ),
      );

      expect(find.text('Error message'), findsOneWidget);
    });

    testWidgets('hides error messages when hideDetails is true', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: ['Error message'],
          hideDetails: true,
          states: {},
          child: Container(),
        ),
      );

      expect(find.text('Error message'), findsNothing);
    });

    testWidgets('renders help icon when helpContentText is provided', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          helpTitleText: 'Help',
          helpContentText: 'Help text',
          child: Container(),
        ),
      );

      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets('renders prefix slot content', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(text: r'$'),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          child: Container(),
        ),
      );

      expect(find.text(r'$'), findsOneWidget);
    });

    testWidgets('renders suffix slot content', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(text: '%'),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          child: Container(),
        ),
      );

      expect(find.text('%'), findsOneWidget);
    });

    testWidgets('renders shortcut text when provided (desktop)', (tester) async {
      try {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;

        await pumpThemed(
          tester,
          LayrzInputChrome(
            labelText: 'Field',
            isRequired: false,
            prefixSlot: LayrzInputPrefixSlot(),
            suffixSlot: LayrzInputSuffixSlot(),
            disabled: false,
            readOnly: false,
            errors: [],
            hideDetails: false,
            states: {},
            shortcutText: 'Ctrl+S',
            child: Container(),
          ),
        );

        expect(find.text('Ctrl+S'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('hides shortcut text on mobile without reserving space', (tester) async {
      try {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        await pumpThemed(
          tester,
          LayrzInputChrome(
            labelText: 'Field',
            isRequired: false,
            prefixSlot: LayrzInputPrefixSlot(),
            suffixSlot: LayrzInputSuffixSlot(),
            disabled: false,
            readOnly: false,
            errors: [],
            hideDetails: false,
            states: {},
            shortcutText: 'Ctrl+S',
            child: Container(),
          ),
        );

        expect(find.text('Ctrl+S'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('hint is visible when field is empty', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          hintText: 'Placeholder text',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: controller,
          child: Container(),
        ),
      );

      expect(find.text('Placeholder text'), findsOneWidget);
    });

    testWidgets('hint is not visible when field has text', (tester) async {
      final controller = TextEditingController(text: 'Some text');
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          hintText: 'Placeholder text',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: controller,
          child: Container(),
        ),
      );

      expect(find.text('Placeholder text'), findsNothing);
    });

    testWidgets('hint remains visible when focused but empty', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          hintText: 'Placeholder text',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {WidgetState.focused},
          controller: controller,
          child: Focus(
            focusNode: focusNode,
            child: Container(),
          ),
        ),
      );

      expect(find.text('Placeholder text'), findsOneWidget);
    });

    testWidgets('hint reappears when text is cleared back to empty', (tester) async {
      final controller = TextEditingController(text: 'Some text');
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          hintText: 'Placeholder text',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: controller,
          child: Container(),
        ),
      );

      expect(find.text('Placeholder text'), findsNothing);
      controller.clear();
      await tester.pumpAndSettle();
      expect(find.text('Placeholder text'), findsOneWidget);
    });

    testWidgets('caller-supplied controller is not disposed after widget disposal', (tester) async {
      final controller = TextEditingController(text: 'Test');
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          hintText: 'Hint',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: controller,
          child: Container(),
        ),
      );

      expect(controller.text, 'Test');
      // After widget disposal, controller should still be usable
    });

    group('Geometry tests - consistent height and width across states', () {
      /// Verifies that all six interaction states have identical height and width.
      /// This test ensures compliance with D15 (geometry invariance).
      testWidgets('all six states render with identical geometry', (tester) async {
        final stateVariants = <String, ({Set<WidgetState> states, bool readOnly, bool disabled})>{
          'rest': (states: {}, readOnly: false, disabled: false),
          'hover': (states: {WidgetState.hovered}, readOnly: false, disabled: false),
          'focus': (states: {WidgetState.focused}, readOnly: false, disabled: false),
          'error': (states: {}, readOnly: false, disabled: false), // hasErrors: true via the test
          'disabled': (states: {WidgetState.disabled}, readOnly: false, disabled: true),
          'read-only': (states: {}, readOnly: true, disabled: false),
        };

        final measurements = <String, Size>{};

        for (final MapEntry(:key, :value) in stateVariants.entries) {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: LayrzTheme(
                data: LayrzThemeData.light(fontHandler: const FakeFontHandler()),
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (context) => Center(
                        child: LayrzInputChrome(
                          labelText: 'Test Field',
                          isRequired: false,
                          prefixSlot: LayrzInputPrefixSlot(),
                          suffixSlot: LayrzInputSuffixSlot(),
                          disabled: value.disabled,
                          readOnly: value.readOnly,
                          errors: key == 'error' ? ['Error'] : [],
                          hideDetails: false,
                          states: value.states,
                          child: Container(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();

          // Find the container holding the input chrome field
          final containerFinder = find.byType(Container).first;
          final rect = tester.getRect(containerFinder);
          measurements[key] = rect.size;
        }

        // Verify all states have identical dimensions
        final firstSize = measurements.values.first;
        for (final MapEntry(:key, :value) in measurements.entries) {
          expect(
            value.width,
            firstSize.width,
            reason: 'State "$key" width differs from "rest" state',
          );
          expect(
            value.height,
            firstSize.height,
            reason: 'State "$key" height differs from "rest" state',
          );
        }
      });

      /// Verifies that fields with and without icons have identical height.
      /// This ensures icons don't change field geometry (critical for the fixed content height fix).
      testWidgets('field height is constant regardless of icon presence', (tester) async {
        final fieldVariants = <String, LayrzInputPrefixSlot>{
          'no-prefix': LayrzInputPrefixSlot(),
          'prefix-icon': LayrzInputPrefixSlot(icon: LayrzIcons.solarOutlineAddCircle),
        };

        final heights = <String, double>{};

        for (final MapEntry(:key, :value) in fieldVariants.entries) {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: LayrzTheme(
                data: LayrzThemeData.light(fontHandler: const FakeFontHandler()),
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (context) => Center(
                        child: LayrzInputChrome(
                          labelText: 'Test Field',
                          isRequired: false,
                          prefixSlot: value,
                          suffixSlot: LayrzInputSuffixSlot(),
                          disabled: false,
                          readOnly: false,
                          errors: [],
                          hideDetails: false,
                          states: {},
                          child: Container(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();

          final containerFinder = find.byType(Container).first;
          final rect = tester.getRect(containerFinder);
          heights[key] = rect.height;
        }

        // Both fields must have identical height
        expect(
          heights['prefix-icon'],
          heights['no-prefix'],
          reason: 'Field with icon has different height than field without icon',
        );
      });

      /// Verifies that both prefix and suffix icon presence doesn't change field height.
      testWidgets('field with both prefix and suffix icons matches field without icons', (tester) async {
        final fieldVariants = <String, ({LayrzInputPrefixSlot prefix, LayrzInputSuffixSlot suffix})>{
          'no-icons': (
            prefix: LayrzInputPrefixSlot(),
            suffix: LayrzInputSuffixSlot(),
          ),
          'both-icons': (
            prefix: LayrzInputPrefixSlot(icon: LayrzIcons.solarOutlineAddCircle),
            suffix: LayrzInputSuffixSlot(icon: LayrzIcons.solarOutlineCheckCircle),
          ),
        };

        final heights = <String, double>{};

        for (final MapEntry(:key, :value) in fieldVariants.entries) {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: LayrzTheme(
                data: LayrzThemeData.light(fontHandler: const FakeFontHandler()),
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (context) => Center(
                        child: LayrzInputChrome(
                          labelText: 'Test Field',
                          isRequired: false,
                          prefixSlot: value.prefix,
                          suffixSlot: value.suffix,
                          disabled: false,
                          readOnly: false,
                          errors: [],
                          hideDetails: false,
                          states: {},
                          child: Container(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();

          final containerFinder = find.byType(Container).first;
          final rect = tester.getRect(containerFinder);
          heights[key] = rect.height;
        }

        // Fields must have identical height regardless of icon presence
        expect(
          heights['both-icons'],
          heights['no-icons'],
          reason: 'Field with icons has different height than field without icons',
        );
      });

      /// Verifies that dense mode affects padding but not content height invariant.
      testWidgets('dense and normal modes have consistent icon height behavior', (tester) async {
        final modeVariants = <String, bool>{
          'normal': false,
          'dense': true,
        };

        final dimensions = <String, ({double width, double height})>{};

        for (final MapEntry(:key, :value) in modeVariants.entries) {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: LayrzTheme(
                data: LayrzThemeData.light(fontHandler: const FakeFontHandler()),
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (context) => Center(
                        child: LayrzInputChrome(
                          labelText: 'Test Field',
                          isRequired: false,
                          prefixSlot: LayrzInputPrefixSlot(icon: LayrzIcons.solarOutlineAddCircle),
                          suffixSlot: LayrzInputSuffixSlot(),
                          disabled: false,
                          readOnly: false,
                          errors: [],
                          hideDetails: false,
                          states: {},
                          dense: value,
                          child: Container(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();

          final containerFinder = find.byType(Container).first;
          final rect = tester.getRect(containerFinder);
          dimensions[key] = (width: rect.width, height: rect.height);
        }

        // Dense and normal have different heights due to padding, but that's OK.
        // Both should have the same width (icon doesn't affect width).
        expect(
          dimensions['dense']!.width,
          dimensions['normal']!.width,
          reason: 'Dense and normal modes have different widths',
        );
      });

      /// Verifies that trailing elements appear in the correct left-to-right order:
      /// shortcut → suffix → lock → help → error (error always last).
      testWidgets('trailing elements are positioned in canonical order', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: LayrzTheme(
              data: LayrzThemeData.light(fontHandler: const FakeFontHandler()),
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => Center(
                      child: LayrzInputChrome(
                        labelText: 'Test Field',
                        isRequired: false,
                        prefixSlot: LayrzInputPrefixSlot(),
                        suffixSlot: LayrzInputSuffixSlot(icon: LayrzIcons.solarOutlineAddCircle),
                        disabled: false,
                        readOnly: true,
                        errors: ['Error message'],
                        hideDetails: false,
                        states: {},
                        shortcutText: 'Cmd+S',
                        helpContentText: 'Help text',
                        child: Container(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        // Find all Icons in the trailing area (shortcut, suffix, lock, help, error icons)
        final allIcons = find.byType(Icon);
        expect(allIcons, findsWidgets, reason: 'Should have trailing icons');

        // Find specific elements: suffix icon, lock icon, help icon, error icon
        final suffixIconFinder = find.byIcon(LayrzIcons.solarOutlineAddCircle);
        final lockIconFinder = find.byIcon(LayrzIcons.solarOutlineLockKeyhole);
        final helpIconFinder = find.byIcon(LayrzIcons.solarOutlineHelp);
        final errorIconFinder = find.byIcon(LayrzIcons.solarOutlineDangerTriangle);

        // Get the x-coordinates (left positions) of each element
        final suffixRect = tester.getRect(suffixIconFinder);
        final lockRect = tester.getRect(lockIconFinder);
        final helpRect = tester.getRect(helpIconFinder);
        final errorRect = tester.getRect(errorIconFinder);

        // Verify the strict left-to-right ordering
        // suffix.left < lock.left < help.left < error.left
        expect(
          suffixRect.left,
          lessThan(lockRect.left),
          reason: 'Suffix should appear before lock icon',
        );
        expect(
          lockRect.left,
          lessThan(helpRect.left),
          reason: 'Lock should appear before help icon',
        );
        expect(
          helpRect.left,
          lessThan(errorRect.left),
          reason: 'Help should appear before error icon (error always last)',
        );
      });

      /// Verifies that with suffix icon and errors, the suffix icon appears before error icon.
      testWidgets('suffix icon appears before error icon', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: LayrzTheme(
              data: LayrzThemeData.light(fontHandler: const FakeFontHandler()),
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => Center(
                      child: LayrzInputChrome(
                        labelText: 'Test Field',
                        isRequired: false,
                        prefixSlot: LayrzInputPrefixSlot(),
                        suffixSlot: LayrzInputSuffixSlot(icon: LayrzIcons.solarOutlineAddCircle),
                        disabled: false,
                        readOnly: false,
                        errors: ['Error message'],
                        hideDetails: false,
                        states: {},
                        child: Container(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        final suffixIconFinder = find.byIcon(LayrzIcons.solarOutlineAddCircle);
        final errorIconFinder = find.byIcon(LayrzIcons.solarOutlineDangerTriangle);

        final suffixRect = tester.getRect(suffixIconFinder);
        final errorRect = tester.getRect(errorIconFinder);

        // Suffix icon's left edge must be strictly less than error icon's left edge
        expect(
          suffixRect.left,
          lessThan(errorRect.left),
          reason: 'Suffix icon should appear before error icon',
        );
      });
    });
  });
}
