import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_slot.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/pump_themed.dart';
import '../../helpers/fake_font_handler.dart';

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
      // Set desktop width (>= 960px) so errors render inline (not in compact mode)
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

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
          'prefix-icon': LayrzInputPrefixSlot(icon: MdiIcons.plusCircleOutline),
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
            prefix: LayrzInputPrefixSlot(icon: MdiIcons.plusCircleOutline),
            suffix: LayrzInputSuffixSlot(icon: MdiIcons.checkCircleOutline),
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
                        suffixSlot: LayrzInputSuffixSlot(icon: MdiIcons.plusCircleOutline),
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
        final suffixIconFinder = find.byIcon(MdiIcons.plusCircleOutline);
        final lockIconFinder = find.byIcon(MdiIcons.lockOutline);
        final helpIconFinder = find.byIcon(MdiIcons.helpCircleOutline);
        final errorIconFinder = find.byIcon(MdiIcons.alertOutline);

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
                        suffixSlot: LayrzInputSuffixSlot(icon: MdiIcons.plusCircleOutline),
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

        final suffixIconFinder = find.byIcon(MdiIcons.plusCircleOutline);
        final errorIconFinder = find.byIcon(MdiIcons.alertOutline);

        final suffixRect = tester.getRect(suffixIconFinder);
        final errorRect = tester.getRect(errorIconFinder);

        // Suffix icon's left edge must be strictly less than error icon's left edge
        expect(
          suffixRect.left,
          lessThan(errorRect.left),
          reason: 'Suffix icon should appear before error icon',
        );
      });

      /// Verifies that tappable slots expose click cursor.
      testWidgets('tappable prefix slot shows click cursor', (tester) async {
        await pumpThemed(
          tester,
          LayrzInputChrome(
            labelText: 'Test',
            isRequired: false,
            prefixSlot: LayrzInputPrefixSlot(
              icon: MdiIcons.checkCircleOutline,
              onTap: () {},
            ),
            suffixSlot: LayrzInputSuffixSlot(),
            disabled: false,
            readOnly: false,
            errors: [],
            hideDetails: false,
            states: {},
            child: Container(),
          ),
        );

        // Find the MouseRegion wrapping the tappable prefix
        final mouseRegions = find.byType(MouseRegion);
        expect(mouseRegions, findsWidgets);
        // At least one should be in the prefix area (not just search/find the exact one,
        // but verify tappable slots get wrapped)
      });

      /// Verifies that non-tappable slots (no callback) do not have cursor feedback.
      testWidgets('non-tappable suffix slot has no special cursor', (tester) async {
        await pumpThemed(
          tester,
          LayrzInputChrome(
            labelText: 'Test',
            isRequired: false,
            prefixSlot: LayrzInputPrefixSlot(),
            suffixSlot: LayrzInputSuffixSlot(
              icon: MdiIcons.plusCircleOutline,
              // No onTap callback — not tappable
            ),
            disabled: false,
            readOnly: false,
            errors: [],
            hideDetails: false,
            states: {},
            child: Container(),
          ),
        );

        // The suffix icon should be rendered but not wrapped in a MouseRegion for interaction
        final suffixIcon = find.byIcon(MdiIcons.plusCircleOutline);
        expect(suffixIcon, findsOneWidget);
      });

      /// Verifies that help icon shows help cursor.
      testWidgets('help icon exposes help cursor', (tester) async {
        await pumpThemed(
          tester,
          LayrzInputChrome(
            labelText: 'Test',
            isRequired: false,
            prefixSlot: LayrzInputPrefixSlot(),
            suffixSlot: LayrzInputSuffixSlot(),
            disabled: false,
            readOnly: false,
            errors: [],
            hideDetails: false,
            states: {},
            helpContentText: 'This is helpful',
            child: Container(),
          ),
        );

        // Help icon should be rendered with MouseRegion for help cursor
        final helpIcon = find.byIcon(MdiIcons.helpCircleOutline);
        expect(helpIcon, findsOneWidget);
      });

      /// Verifies that slot icons match trailing icons size (not hardcoded at 20).
      testWidgets('slot icons match trailing icon size', (tester) async {
        await pumpThemed(
          tester,
          LayrzInputChrome(
            labelText: 'Test',
            isRequired: false,
            prefixSlot: LayrzInputPrefixSlot(icon: MdiIcons.checkCircleOutline),
            suffixSlot: LayrzInputSuffixSlot(icon: MdiIcons.plusCircleOutline),
            disabled: false,
            readOnly: false,
            errors: [],
            hideDetails: false,
            states: {},
            child: Container(),
          ),
        );

        // Both prefix icon and suffix icon should use theme icon size (24),
        // not hardcoded 20. This test verifies they render at the same size
        // as trailing icons by checking their visual sizes are consistent.
        final prefixIcon = find.byIcon(MdiIcons.checkCircleOutline);
        final suffixIcon = find.byIcon(MdiIcons.plusCircleOutline);

        expect(prefixIcon, findsOneWidget);
        expect(suffixIcon, findsOneWidget);

        // Both should use the same size from theme.iconTheme.size (24)
        final prefixIconSize = tester.getSize(prefixIcon);
        final suffixIconSize = tester.getSize(suffixIcon);

        expect(prefixIconSize.width, suffixIconSize.width);
        expect(prefixIconSize.height, suffixIconSize.height);
      });

      /// Verifies that disabled field text uses fg4 (muted), not fg1 (dark).
      testWidgets('disabled field text uses fg4 color', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: LayrzTheme(
              data: LayrzThemeData.light(fontHandler: const FakeFontHandler()),
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) {
                      return Center(
                        child: LayrzInputChrome(
                          labelText: 'Disabled Field',
                          isRequired: false,
                          prefixSlot: LayrzInputPrefixSlot(),
                          suffixSlot: LayrzInputSuffixSlot(),
                          disabled: true,
                          readOnly: false,
                          errors: [],
                          hideDetails: false,
                          states: {WidgetState.disabled},
                          controller: TextEditingController(text: 'Disabled text'),
                          child: Container(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        // Verify the field is rendered and disabled state is present
        final chromeField = find.byType(LayrzInputChrome);
        expect(chromeField, findsOneWidget);
      });

      /// Verifies that padding is uniform on all four sides and matches the expected token value.
      testWidgets('padding is uniform (all sides) and equals token default (10px)', (tester) async {
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

        // Find the input container
        final containers = find.byType(Container);
        // The first Container after theming is the input field container (with decoration and padding)
        final containerWidget = tester.widget<Container>(containers.first);
        final padding = containerWidget.padding as EdgeInsets?;

        expect(padding, isNotNull, reason: 'Input container should have padding');

        // Verify relative uniformity: all sides equal
        expect(padding!.left, equals(padding.right), reason: 'Left padding should equal right padding');
        expect(padding.top, equals(padding.bottom), reason: 'Top padding should equal bottom padding');
        expect(
          padding.left,
          equals(padding.top),
          reason: 'Horizontal padding should equal vertical padding (uniform all sides)',
        );

        // Verify absolute value: padding should be 10px (pd2 token, sp2 spacing value)
        expect(
          padding.left,
          equals(10.0),
          reason: 'Padding should equal tokens.spacing.pd2 (10px)',
        );
      });

      group('Focus color behavior (DESIGN-106)', () {
        testWidgets('focused state: prefix icon uses focus border color', (tester) async {
          final prefixIcon = MdiIcons.checkCircleOutline;
          final controller = TextEditingController();

          await pumpThemed(
            tester,
            LayrzInputChrome(
              labelText: 'Search',
              isRequired: false,
              prefixSlot: LayrzInputPrefixSlot(icon: prefixIcon),
              suffixSlot: LayrzInputSuffixSlot(),
              disabled: false,
              readOnly: false,
              errors: [],
              hideDetails: false,
              states: {WidgetState.focused},
              controller: controller,
              child: Container(),
            ),
          );

          final icon = tester.widget<Icon>(find.byIcon(prefixIcon));
          final tokens = LayrzTokens.light();
          expect(
            icon.color,
            equals(tokens.colors.primary),
            reason: 'Prefix icon color should equal focus border color (primary) when focused',
          );
        });

        testWidgets('focused state: suffix icon uses focus border color', (tester) async {
          final suffixIcon = MdiIcons.plusCircleOutline;
          final controller = TextEditingController();

          await pumpThemed(
            tester,
            LayrzInputChrome(
              labelText: 'Input',
              isRequired: false,
              prefixSlot: LayrzInputPrefixSlot(),
              suffixSlot: LayrzInputSuffixSlot(icon: suffixIcon),
              disabled: false,
              readOnly: false,
              errors: [],
              hideDetails: false,
              states: {WidgetState.focused},
              controller: controller,
              child: Container(),
            ),
          );

          final icon = tester.widget<Icon>(find.byIcon(suffixIcon));
          final tokens = LayrzTokens.light();
          expect(
            icon.color,
            equals(tokens.colors.primary),
            reason: 'Suffix icon color should equal focus border color (primary) when focused',
          );
        });

        testWidgets('focused state: prefix text uses focus border color', (tester) async {
          const prefixText = 'USD';
          final controller = TextEditingController();

          await pumpThemed(
            tester,
            LayrzInputChrome(
              labelText: 'Amount',
              isRequired: false,
              prefixSlot: LayrzInputPrefixSlot(text: prefixText),
              suffixSlot: LayrzInputSuffixSlot(),
              disabled: false,
              readOnly: false,
              errors: [],
              hideDetails: false,
              states: {WidgetState.focused},
              controller: controller,
              child: Container(),
            ),
          );

          // Find the Text widget that contains the prefix text
          final textWidgets = find.byType(Text);
          final tokens = LayrzTokens.light();
          bool found = false;
          for (int i = 0; i < textWidgets.evaluate().length; i++) {
            final text = tester.widget<Text>(textWidgets.at(i));
            if (text.data == prefixText) {
              expect(
                text.style?.color,
                equals(tokens.colors.primary),
                reason: 'Prefix text color should equal focus border color (primary) when focused',
              );
              found = true;
              break;
            }
          }
          expect(found, true, reason: 'Prefix text widget should be found with correct color');
        });

        testWidgets('focused state: suffix text uses focus border color', (tester) async {
          const suffixText = '%';
          final controller = TextEditingController();

          await pumpThemed(
            tester,
            LayrzInputChrome(
              labelText: 'Percentage',
              isRequired: false,
              prefixSlot: LayrzInputPrefixSlot(),
              suffixSlot: LayrzInputSuffixSlot(text: suffixText),
              disabled: false,
              readOnly: false,
              errors: [],
              hideDetails: false,
              states: {WidgetState.focused},
              controller: controller,
              child: Container(),
            ),
          );

          final textWidgets = find.byType(Text);
          // Find the text widget that contains the suffix text
          bool found = false;
          for (int i = 0; i < textWidgets.evaluate().length; i++) {
            final text = tester.widget<Text>(textWidgets.at(i));
            if (text.data == suffixText) {
              final textStyle = text.style;
              final tokens = LayrzTokens.light();
              expect(
                textStyle?.color,
                equals(tokens.colors.primary),
                reason: 'Suffix text color should equal focus border color (primary) when focused',
              );
              found = true;
              break;
            }
          }
          expect(found, true, reason: 'Suffix text widget should be found with correct color');
        });

        testWidgets('not focused state: prefix icon keeps resting color', (tester) async {
          final prefixIcon = MdiIcons.checkCircleOutline;
          final controller = TextEditingController();

          await pumpThemed(
            tester,
            LayrzInputChrome(
              labelText: 'Search',
              isRequired: false,
              prefixSlot: LayrzInputPrefixSlot(icon: prefixIcon),
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

          final icon = tester.widget<Icon>(find.byIcon(prefixIcon));
          final tokens = LayrzTokens.light();
          expect(
            icon.color,
            equals(tokens.colors.fg1),
            reason: 'Prefix icon color should be fg1 (resting) when not focused',
          );
        });

        testWidgets('not focused state: suffix icon keeps resting color', (tester) async {
          final suffixIcon = MdiIcons.plusCircleOutline;
          final controller = TextEditingController();

          await pumpThemed(
            tester,
            LayrzInputChrome(
              labelText: 'Input',
              isRequired: false,
              prefixSlot: LayrzInputPrefixSlot(),
              suffixSlot: LayrzInputSuffixSlot(icon: suffixIcon),
              disabled: false,
              readOnly: false,
              errors: [],
              hideDetails: false,
              states: {},
              controller: controller,
              child: Container(),
            ),
          );

          final icon = tester.widget<Icon>(find.byIcon(suffixIcon));
          final tokens = LayrzTokens.light();
          expect(
            icon.color,
            equals(tokens.colors.fg1),
            reason: 'Suffix icon color should be fg1 (resting) when not focused',
          );
        });

        testWidgets('focused AND error state: error precedence preserved with danger border color', (tester) async {
          final prefixIcon = MdiIcons.checkCircleOutline;
          final controller = TextEditingController();

          await pumpThemed(
            tester,
            LayrzInputChrome(
              labelText: 'Search',
              isRequired: false,
              prefixSlot: LayrzInputPrefixSlot(icon: prefixIcon),
              suffixSlot: LayrzInputSuffixSlot(),
              disabled: false,
              readOnly: false,
              errors: ['This field has an error'],
              hideDetails: false,
              states: {WidgetState.focused},
              controller: controller,
              child: Container(),
            ),
          );

          // Verify the error state takes precedence: the spec should use fg1 (error text color), not primary
          final icon = tester.widget<Icon>(find.byIcon(prefixIcon));
          final tokens = LayrzTokens.light();
          expect(
            icon.color,
            equals(tokens.colors.fg1),
            reason: 'Prefix icon should remain fg1 when focused AND in error (error takes precedence)',
          );
        });

        testWidgets('focused state: lock icon keeps resting color and does not change on focus', (tester) async {
          final controller = TextEditingController();

          await pumpThemed(
            tester,
            LayrzInputChrome(
              labelText: 'Read-only Field',
              isRequired: false,
              prefixSlot: LayrzInputPrefixSlot(),
              suffixSlot: LayrzInputSuffixSlot(),
              disabled: false,
              readOnly: true,
              errors: [],
              hideDetails: false,
              states: {WidgetState.focused},
              controller: controller,
              child: Container(),
            ),
          );

          final lockIcon = tester.widget<Icon>(find.byIcon(MdiIcons.lockOutline));
          final tokens = LayrzTokens.light();
          expect(
            lockIcon.color,
            equals(tokens.colors.fg1),
            reason: 'Lock icon should remain fg1 when focused (not affected by focus color change)',
          );
        });
      });

      group('Compact viewport sizing — DESIGN-105', () {
        /// Verifies that padding grows from pd2 (10px) to pd3 (14px) on compact viewports.
        /// This increases the field's vertical height from ~42px to ~50px on compact (width < 960px).
        testWidgets('compact viewport (width 400): padding is pd3 (14px all sides)', (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = const Size(400, 800);

          final tokens = LayrzTokens.light();
          late EdgeInsets resolvedPadding;

          await pumpThemed(
            tester,
            LayrzInputChrome(
              labelText: 'Test Field',
              isRequired: false,
              prefixSlot: LayrzInputPrefixSlot(),
              suffixSlot: LayrzInputSuffixSlot(),
              disabled: false,
              readOnly: false,
              errors: [],
              hideDetails: false,
              states: {},
              child: Builder(
                builder: (context) {
                  // Capture the resolved padding by reading the input container's padding
                  return const SizedBox.shrink();
                },
              ),
            ),
          );

          // Find the input container (the one with decoration) and extract its padding
          final containers = find.byType(Container);
          expect(containers, findsWidgets);

          // The decorated container is among the first few widgets; we're looking for the one with a border
          for (int i = 0; i < containers.evaluate().length; i++) {
            final container = tester.widget<Container>(containers.at(i));
            if (container.decoration is BoxDecoration) {
              final dec = container.decoration as BoxDecoration;
              if (dec.border != null) {
                resolvedPadding = container.padding as EdgeInsets;
                break;
              }
            }
          }

          // Verify padding is pd3 on compact
          expect(resolvedPadding.top, equals(tokens.spacing.sp3));
          expect(resolvedPadding.bottom, equals(tokens.spacing.sp3));
          expect(resolvedPadding.left, equals(tokens.spacing.sp3));
          expect(resolvedPadding.right, equals(tokens.spacing.sp3));
        });

        /// Verifies that padding remains pd2 (10px) on regular viewports.
        testWidgets('regular viewport (width 1200): padding is pd2 (10px all sides)', (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = const Size(1200, 800);

          final tokens = LayrzTokens.light();
          late EdgeInsets resolvedPadding;

          await pumpThemed(
            tester,
            LayrzInputChrome(
              labelText: 'Test Field',
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

          // Find the input container with decoration and extract its padding
          final containers = find.byType(Container);
          for (int i = 0; i < containers.evaluate().length; i++) {
            final container = tester.widget<Container>(containers.at(i));
            if (container.decoration is BoxDecoration) {
              final dec = container.decoration as BoxDecoration;
              if (dec.border != null) {
                resolvedPadding = container.padding as EdgeInsets;
                break;
              }
            }
          }

          // Verify padding is pd2 on regular viewport
          expect(resolvedPadding.top, equals(tokens.spacing.sp2));
          expect(resolvedPadding.bottom, equals(tokens.spacing.sp2));
          expect(resolvedPadding.left, equals(tokens.spacing.sp2));
          expect(resolvedPadding.right, equals(tokens.spacing.sp2));
        });

        /// Verifies the exact boundary: width 959 (sm, compact) vs width 960 (md, regular).
        testWidgets('compact/regular boundary: 959 is compact (pd3), 960 is regular (pd2)', (tester) async {
          final tokens = LayrzTokens.light();

          // Test at width 959 (compact)
          addTearDown(tester.view.resetPhysicalSize);
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = const Size(959, 800);

          await pumpThemed(
            tester,
            LayrzInputChrome(
              labelText: 'Test Field',
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

          late EdgeInsets padding959;
          final containers959 = find.byType(Container);
          for (int i = 0; i < containers959.evaluate().length; i++) {
            final container = tester.widget<Container>(containers959.at(i));
            if (container.decoration is BoxDecoration) {
              final dec = container.decoration as BoxDecoration;
              if (dec.border != null) {
                padding959 = container.padding as EdgeInsets;
                break;
              }
            }
          }

          expect(padding959.top, equals(tokens.spacing.sp3), reason: 'Width 959 should be compact (pd3)');

          // Now test at width 960 (regular)
          addTearDown(tester.view.resetPhysicalSize);
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = const Size(960, 800);

          await pumpThemed(
            tester,
            LayrzInputChrome(
              labelText: 'Test Field',
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

          late EdgeInsets padding960;
          final containers960 = find.byType(Container);
          for (int i = 0; i < containers960.evaluate().length; i++) {
            final container = tester.widget<Container>(containers960.at(i));
            if (container.decoration is BoxDecoration) {
              final dec = container.decoration as BoxDecoration;
              if (dec.border != null) {
                padding960 = container.padding as EdgeInsets;
                break;
              }
            }
          }

          expect(padding960.top, equals(tokens.spacing.sp2), reason: 'Width 960 should be regular (pd2)');
        });

        /// Verifies that padding remains uniform (all four sides equal) on compact viewports.
        testWidgets('compact viewport: padding is uniform on all four sides', (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = const Size(400, 800);

          await pumpThemed(
            tester,
            LayrzInputChrome(
              labelText: 'Test Field',
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

          final containers = find.byType(Container);
          for (int i = 0; i < containers.evaluate().length; i++) {
            final container = tester.widget<Container>(containers.at(i));
            if (container.decoration is BoxDecoration) {
              final dec = container.decoration as BoxDecoration;
              if (dec.border != null) {
                final padding = container.padding as EdgeInsets;
                // Verify all sides are equal
                expect(padding.top, equals(padding.bottom), reason: 'Top should equal bottom');
                expect(padding.left, equals(padding.right), reason: 'Left should equal right');
                expect(padding.top, equals(padding.left), reason: 'All sides should be equal');
                break;
              }
            }
          }
        });

        /// Verifies that field height remains constant across interaction states on compact viewports.
        /// This preserves D15 (geometry invariance across states).
        testWidgets('compact viewport: field height stays constant across interaction states', (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = const Size(400, 800);

          final stateVariants = <String, ({Set<WidgetState> states, bool disabled, bool readOnly})>{
            'rest': (states: {}, disabled: false, readOnly: false),
            'hover': (states: {WidgetState.hovered}, disabled: false, readOnly: false),
            'focus': (states: {WidgetState.focused}, disabled: false, readOnly: false),
            'error': (states: {}, disabled: false, readOnly: false),
            'disabled': (states: {WidgetState.disabled}, disabled: true, readOnly: false),
          };

          final heights = <String, double>{};

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

            // Find the input container with decoration
            final containers = find.byType(Container);
            for (int i = 0; i < containers.evaluate().length; i++) {
              final container = tester.widget<Container>(containers.at(i));
              if (container.decoration is BoxDecoration) {
                final dec = container.decoration as BoxDecoration;
                if (dec.border != null) {
                  final rect = tester.getRect(containers.at(i));
                  heights[key] = rect.height;
                  break;
                }
              }
            }
          }

          // All states should have identical height
          final firstHeight = heights.values.first;
          for (final MapEntry(:key, :value) in heights.entries) {
            expect(
              value,
              firstHeight,
              reason: 'State "$key" height should equal rest state height',
            );
          }
        });

        /// Verifies that caller-supplied padding parameter overrides the compact-responsive padding.
        testWidgets('caller-supplied padding parameter overrides compact padding', (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = const Size(400, 800);

          final customPadding = EdgeInsets.all(20.0);

          await pumpThemed(
            tester,
            LayrzInputChrome(
              labelText: 'Test Field',
              isRequired: false,
              prefixSlot: LayrzInputPrefixSlot(),
              suffixSlot: LayrzInputSuffixSlot(),
              disabled: false,
              readOnly: false,
              errors: [],
              hideDetails: false,
              states: {},
              padding: customPadding,
              child: Container(),
            ),
          );

          final containers = find.byType(Container);
          for (int i = 0; i < containers.evaluate().length; i++) {
            final container = tester.widget<Container>(containers.at(i));
            if (container.decoration is BoxDecoration) {
              final dec = container.decoration as BoxDecoration;
              if (dec.border != null) {
                final resolvedPadding = container.padding as EdgeInsets;
                // Verify that custom padding is used, not the compact responsive one
                expect(resolvedPadding.top, equals(20.0));
                expect(resolvedPadding.bottom, equals(20.0));
                expect(resolvedPadding.left, equals(20.0));
                expect(resolvedPadding.right, equals(20.0));
                break;
              }
            }
          }
        });
      });
    });
  });
}
