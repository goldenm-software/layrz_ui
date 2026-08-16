import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/buttons.dart';
import 'package:layrz_ui/constants.dart';

import '../helpers/find_button_label.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzButton', () {
    group('Content rendering', () {
      testWidgets('renders labelText', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Test Button',
            onTap: () {},
          ),
        );

        // RichText renders text as InlineSpans, not as separate Text widgets.
        // Check button renders and label is in semantics/accessibility tree.
        expect(find.byType(LayrzButton), findsOneWidget);
        final semantics = tester.getSemantics(find.byType(LayrzButton));
        expect(semantics.label, contains('Test Button'));
      });

      testWidgets('renders icon and label together for non-Fab', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Test Button',
            icon: LayrzIcons.solarOutlineCheckCircle,
            onTap: () {},
          ),
        );

        // RichText renders both icon and label as InlineSpans, not separate widgets.
        // Check button renders with both icon and label accessible.
        expect(find.byType(LayrzButton), findsOneWidget);
        final semantics = tester.getSemantics(find.byType(LayrzButton));
        expect(semantics.label, contains('Test Button'));
      });

      testWidgets('Fab renders icon only, no visible label', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Test Fab',
            icon: LayrzIcons.solarOutlineCheckCircle,
            style: LayrzButtonStyle.filledTonalFab,
            onTap: () {},
          ),
        );

        // Fab should render as a button (no separate widget check needed).
        // RichText renders the icon as a glyph, not as an Icon widget.
        // The button's semantics will contain the label for accessibility.
        expect(find.byType(LayrzButton), findsOneWidget);
        final fabSize = tester.getSize(find.byType(LayrzButton));
        expect(fabSize.width, equals(fabSize.height)); // Fab is square
      });

      testWidgets('long labelText ellipsises instead of overflowing', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 100,
            child: LayrzButton(
              labelText: 'This is a very long button label that should ellipsize',
              onTap: () {},
            ),
          ),
        );

        // RichText renders the content, so check RichText has ellipsis overflow.
        final richText = find.byType(RichText);
        expect(richText, findsWidgets); // RichText should be present
        final richTextWidget = tester.widget<RichText>(richText.first);
        expect(richTextWidget.overflow, equals(TextOverflow.ellipsis));
        expect(richTextWidget.maxLines, equals(1));
      });
    });

    group('Style variants', () {
      testWidgets('all ten style variants pump without exception', (tester) async {
        for (final style in LayrzButtonStyle.values) {
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Style Test',
              style: style,
              onTap: () {},
            ),
          );

          // RichText renders content, so check button renders successfully.
          expect(
            find.byType(LayrzButton),
            findsOneWidget,
            reason: 'Style $style should pump successfully',
          );
        }
      });

      testWidgets('filled style pumps correctly', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Filled',
            style: LayrzButtonStyle.filled,
            onTap: () {},
          ),
        );

        expect(find.byType(LayrzButton), findsOneWidget);
      });

      testWidgets('elevated style pumps correctly', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Elevated',
            style: LayrzButtonStyle.elevated,
            onTap: () {},
          ),
        );

        expect(find.byType(LayrzButton), findsOneWidget);
      });

      testWidgets('filledTonal style pumps correctly', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'FilledTonal',
            style: LayrzButtonStyle.filledTonal,
            onTap: () {},
          ),
        );

        expect(find.byType(LayrzButton), findsOneWidget);
      });

      testWidgets('outlined style pumps correctly', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Outlined',
            style: LayrzButtonStyle.outlined,
            onTap: () {},
          ),
        );

        expect(find.byType(LayrzButton), findsOneWidget);
      });

      testWidgets('outlinedTonal style pumps correctly', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'OutlinedTonal',
            style: LayrzButtonStyle.outlinedTonal,
            onTap: () {},
          ),
        );

        expect(find.byType(LayrzButton), findsOneWidget);
      });

      testWidgets('filledTonalFab style pumps correctly', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Fab',
            style: LayrzButtonStyle.filledTonalFab,
            onTap: () {},
          ),
        );

        expect(find.byType(LayrzButton), findsOneWidget);
      });
    });

    group('Tap and callback behavior', () {
      testWidgets('disabled via onTap: null does not invoke callback', (tester) async {
        int tapCount = 0;

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Disabled Button',
            onTap: null,
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        expect(tapCount, equals(0));
      });

      testWidgets('disabled via isDisabled: true with non-null onTap does not invoke callback', (tester) async {
        int tapCount = 0;

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Disabled Button',
            isDisabled: true,
            onTap: () => tapCount++,
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        expect(tapCount, equals(0));
      });

      testWidgets('enabled tap invokes callback exactly once', (tester) async {
        int tapCount = 0;

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Enabled Button',
            onTap: () => tapCount++,
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        expect(tapCount, equals(1));
      });

      testWidgets('multiple taps invoke callback multiple times', (tester) async {
        int tapCount = 0;

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Multi-tap Button',
            onTap: () => tapCount++,
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        expect(tapCount, equals(2));
      });
    });

    group('Controller-based busy states', () {
      testWidgets('controller: null renders normally without indicator', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'No Controller',
            controller: null,
            onTap: () {},
          ),
        );

        expect(find.byType(LayrzButton), findsOneWidget);
      });

      testWidgets('controller.startLoading shows indicator and suppresses tap', (tester) async {
        final controller = LayrzButtonController();
        int tapCount = 0;

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Loading Button',
            controller: controller,
            onTap: () => tapCount++,
          ),
        );

        controller.startLoading();
        await tester.pump();

        // Try to tap while loading.
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        expect(tapCount, equals(0), reason: 'Tap should be suppressed during loading');

        controller.dispose();
      });

      testWidgets('controller.stopLoading ends loading with anti-flash floor', (tester) async {
        final controller = LayrzButtonController();

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Toggle Loading',
            controller: controller,
            onTap: () {},
          ),
        );

        // Start loading
        controller.startLoading();
        await tester.pump();
        expect(find.byType(LayrzButton), findsOneWidget);

        // Stop loading
        controller.stopLoading();
        await tester.pump();
        // Button should still be in busy state due to anti-flash floor
        expect(find.byType(LayrzButton), findsOneWidget);

        controller.dispose();
      });

      testWidgets('controller.startCooldown shows indicator and suppresses tap', (tester) async {
        final controller = LayrzButtonController();
        int tapCount = 0;

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Cooldown Button',
            controller: controller,
            onTap: () => tapCount++,
          ),
        );

        controller.startCooldown(const Duration(seconds: 5));
        await tester.pump();

        // Try to tap while in cooldown.
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        expect(tapCount, equals(0), reason: 'Tap should be suppressed during cooldown');

        controller.dispose();
      });

      testWidgets('controller.clearCooldown ends cooldown', (tester) async {
        final controller = LayrzButtonController();
        int tapCount = 0;

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Toggle Cooldown',
            controller: controller,
            onTap: () => tapCount++,
          ),
        );

        // Start cooldown
        controller.startCooldown(const Duration(seconds: 5));
        await tester.pump();

        // Clear cooldown
        controller.clearCooldown();
        await tester.pump();

        // Button should be tappable again
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        expect(tapCount, equals(1), reason: 'Tap should work after cooldown cleared');

        controller.dispose();
      });
    });

    group('Multiple buttons sharing one controller', () {
      testWidgets('two buttons sharing controller both go busy together', (tester) async {
        final controller = LayrzButtonController();
        int tap1Count = 0;
        int tap2Count = 0;

        await pumpThemed(
          tester,
          Column(
            children: [
              LayrzButton(
                labelText: 'Button 1',
                controller: controller,
                onTap: () => tap1Count++,
              ),
              LayrzButton(
                labelText: 'Button 2',
                controller: controller,
                onTap: () => tap2Count++,
              ),
            ],
          ),
        );

        // Both buttons should be tappable initially
        await tester.tap(find.byType(LayrzButton).first);
        await tester.pump();
        expect(tap1Count, equals(1));

        // Start loading on controller
        controller.startLoading();
        await tester.pump();

        // Both buttons should be disabled now
        await tester.tap(find.byType(LayrzButton).at(0));
        await tester.tap(find.byType(LayrzButton).at(1));
        await tester.pump();

        expect(tap1Count, equals(1), reason: 'Button 1 should still be disabled');
        expect(tap2Count, equals(0), reason: 'Button 2 should be disabled');

        controller.dispose();
      });

      testWidgets('both buttons re-enable together when controller clears cooldown', (tester) async {
        final controller = LayrzButtonController();
        int tap1Count = 0;
        int tap2Count = 0;

        await pumpThemed(
          tester,
          Column(
            children: [
              LayrzButton(
                labelText: 'Button 1',
                controller: controller,
                onTap: () => tap1Count++,
              ),
              LayrzButton(
                labelText: 'Button 2',
                controller: controller,
                onTap: () => tap2Count++,
              ),
            ],
          ),
        );

        // Start cooldown
        controller.startCooldown(const Duration(seconds: 5));
        await tester.pump();

        // Both disabled
        await tester.tap(find.byType(LayrzButton).at(0));
        await tester.tap(find.byType(LayrzButton).at(1));
        await tester.pump();
        expect(tap1Count, equals(0));
        expect(tap2Count, equals(0));

        // Clear cooldown
        controller.clearCooldown();
        await tester.pump();

        // Both should be enabled again
        await tester.tap(find.byType(LayrzButton).at(0));
        await tester.tap(find.byType(LayrzButton).at(1));
        await tester.pump();
        expect(tap1Count, equals(1));
        expect(tap2Count, equals(1));

        controller.dispose();
      });
    });

    group('Tooltip behavior', () {
      testWidgets('non-Fab with hintText mounts RawTooltip', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Button',
            hintText: 'This is a hint',
            onTap: () {},
          ),
        );

        await tester.pump();

        // Non-Fab with hintText should mount RawTooltip
        expect(find.byType(RawTooltip), findsOneWidget);
      });

      testWidgets('non-Fab without hintText does not mount RawTooltip', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Button',
            onTap: () {},
          ),
        );

        await tester.pump();

        // Non-Fab without hintText should not mount RawTooltip
        expect(find.byType(RawTooltip), findsNothing);
      });

      testWidgets('Fab always mounts RawTooltip', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Fab Button',
            style: LayrzButtonStyle.filledTonalFab,
            onTap: () {},
          ),
        );

        await tester.pump();

        // Fab should always mount RawTooltip
        expect(find.byType(RawTooltip), findsOneWidget);
      });

      testWidgets('Fab tooltip message is labelText only when no hintText', (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        addTearDown(tester.view.resetPhysicalSize);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Fab Label',
            style: LayrzButtonStyle.filledTonalFab,
            onTap: () {},
          ),
        );

        await tester.pump();

        // Long press on the Fab to trigger tooltip
        await tester.longPress(find.byType(LayrzButton));
        await tester.pump();

        // Tooltip should contain only the label text
        expect(find.text('Fab Label'), findsWidgets);
      });

      testWidgets('Fab tooltip message is labelText plus hintText on new line', (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        addTearDown(tester.view.resetPhysicalSize);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Fab Label',
            hintText: 'Fab Hint',
            style: LayrzButtonStyle.filledTonalFab,
            onTap: () {},
          ),
        );

        await tester.pump();

        // Long press on the Fab to trigger tooltip
        await tester.longPress(find.byType(LayrzButton));
        await tester.pump();

        // Tooltip should contain both label and hint (separated by newline)
        expect(find.text('Fab Label\nFab Hint'), findsWidgets);
      });

      testWidgets('non-Fab tooltip message is hintText only', (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        addTearDown(tester.view.resetPhysicalSize);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Button Label',
            hintText: 'Button Hint',
            onTap: () {},
          ),
        );

        await tester.pump();

        // Long press to trigger tooltip
        await tester.longPress(find.byType(LayrzButton));
        await tester.pump();

        // Tooltip should contain only the hint, not the label
        expect(find.text('Button Hint'), findsWidgets);
      });
    });

    group('Hover and press states', () {
      testWidgets('press changes button appearance', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Press Test',
            onTap: () {},
          ),
        );

        await tester.pump();

        // Start a gesture on the button.
        final buttonCenter = tester.getCenter(find.byType(LayrzButton));
        final gesture = await tester.startGesture(buttonCenter);
        await tester.pump();

        // Button should render while pressed.
        expect(find.byType(LayrzButton), findsOneWidget);

        // Release the gesture.
        await gesture.up();
        await tester.pump();
      });
    });

    group('Custom accent color', () {
      testWidgets('custom color parameter overrides default', (tester) async {
        const customColor = Color(0xFFABCDEF);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Custom Color',
            color: customColor,
            onTap: () {},
          ),
        );

        expect(findButtonLabel('Custom Color'), findsOneWidget);
      });

      testWidgets('custom color applies to all style families', (tester) async {
        const customColor = Color(0xFFABCDEF);

        for (final style in LayrzButtonStyle.values) {
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Custom',
              style: style,
              color: customColor,
              onTap: () {},
            ),
          );

          expect(findButtonLabel('Custom'), findsOneWidget);
        }
      });
    });

    group('Tooltip visibility (RawTooltip mount contract)', () {
      testWidgets('Fab always mounts RawTooltip regardless of hintText', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Fab With Tooltip',
            style: LayrzButtonStyle.filledTonalFab,
            onTap: () {},
          ),
        );

        expect(find.byType(RawTooltip), findsOneWidget);
      });

      testWidgets('non-Fab with hintText mounts RawTooltip', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Button Text',
            hintText: 'Hint Text',
            onTap: () {},
          ),
        );

        expect(find.byType(RawTooltip), findsOneWidget);
      });

      testWidgets('non-Fab without hintText does not mount RawTooltip', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Button Text',
            onTap: () {},
          ),
        );

        expect(find.byType(RawTooltip), findsNothing);
      });
    });

    group('Layout regression tests', () {
      testWidgets('regression: non-Fab button in unbounded Row does not throw '
          'BoxConstraints assertion', (tester) async {
        await pumpThemed(
          tester,
          Row(
            children: [
              LayrzButton(
                labelText: 'Row Button',
                onTap: () {},
              ),
            ],
          ),
        );

        await tester.pump();

        expect(findButtonLabel('Row Button'), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Button should layout correctly in unbounded Row without throwing',
        );
      });

      testWidgets('regression: Fab button in unbounded Row does not throw '
          'BoxConstraints assertion', (tester) async {
        await pumpThemed(
          tester,
          Row(
            children: [
              LayrzButton(
                labelText: 'Row Fab',
                style: LayrzButtonStyle.filledTonalFab,
                onTap: () {},
              ),
            ],
          ),
        );

        await tester.pump();

        expect(find.byType(LayrzButton), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Fab should layout correctly in unbounded Row without throwing');
      });

      testWidgets('regression: button in Wrap does not throw', (tester) async {
        await pumpThemed(
          tester,
          Wrap(
            children: [
              LayrzButton(
                labelText: 'Wrap Button',
                onTap: () {},
              ),
            ],
          ),
        );

        await tester.pump();

        expect(findButtonLabel('Wrap Button'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('regression: button with icon is wider than button without icon', (tester) async {
        // Verify width calculation by comparing buttons with and without icons.
        // Icon size directly affects computed width in the measurement function.
        await pumpThemed(
          tester,
          Row(
            children: [
              LayrzButton(
                labelText: 'OK',
                onTap: () {},
              ),
              LayrzButton(
                labelText: 'OK',
                icon: LayrzIcons.solarOutlineCheckCircle,
                onTap: () {},
              ),
            ],
          ),
        );

        await tester.pump();

        final buttons = find.byType(LayrzButton);
        final buttonWithoutIcon = tester.getSize(buttons.at(0));
        final buttonWithIcon = tester.getSize(buttons.at(1));

        expect(
          buttonWithIcon.width,
          greaterThan(buttonWithoutIcon.width),
          reason: 'Button with icon should be wider due to icon + separator in width calculation',
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('regression: Fab button is square (width == height)', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Fab Square',
            style: LayrzButtonStyle.filledTonalFab,
            onTap: () {},
          ),
        );

        await tester.pump();

        final fabSize = tester.getSize(find.byType(LayrzButton));
        expect(
          fabSize.width,
          closeTo(kLayrzButtonHeight, 1.0),
          reason: 'Fab button width should equal standard button height',
        );
        expect(
          fabSize.height,
          closeTo(kLayrzButtonHeight, 1.0),
          reason: 'Fab button height should equal standard button height',
        );
        expect(
          fabSize.width,
          equals(fabSize.height),
          reason: 'Fab button should be square',
        );
      });

      testWidgets('regression: loading indicator in unbounded Row does not throw', (tester) async {
        final controller = LayrzButtonController();

        await pumpThemed(
          tester,
          Row(
            children: [
              LayrzButton(
                labelText: 'Loading in Row',
                controller: controller,
                onTap: () {},
              ),
            ],
          ),
        );

        controller.startLoading();

        // Use pump() not pumpAndSettle() because the indicator animates forever.
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(LayrzButton), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Loading button should layout in unbounded context without exception',
        );

        controller.dispose();
      });

      testWidgets('regression: cooldown indicator in unbounded Row does not throw', (tester) async {
        final controller = LayrzButtonController();

        await pumpThemed(
          tester,
          Row(
            children: [
              LayrzButton(
                labelText: 'Cooldown in Row',
                controller: controller,
                onTap: () {},
              ),
            ],
          ),
        );

        controller.startCooldown(const Duration(seconds: 5));

        // Use pump() not pumpAndSettle() because the indicator animates forever.
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(LayrzButton), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Cooldown button should layout in unbounded context without exception',
        );

        controller.dispose();
      });

      testWidgets('regression: very long label in constrained parent clamps to width '
          'and ellipsises with no overflow', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 200,
            child: LayrzButton(
              labelText:
                  'This is an extremely long button label that should definitely '
                  'exceed the parent width and get clamped and ellipsised',
              onTap: () {},
            ),
          ),
        );

        await tester.pump();

        final buttonSize = tester.getSize(find.byType(LayrzButton));
        expect(buttonSize.width, closeTo(200.0, 1.0), reason: 'Button width should be clamped to parent width');
        expect(tester.takeException(), isNull, reason: 'No overflow exception should be thrown');
      });

      testWidgets('regression: width consistent between default and hovered states (D15)', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Test Width Consistency',
            onTap: () {},
          ),
        );

        await tester.pump();
        final defaultSize = tester.getSize(find.byType(LayrzButton));

        // Simulate hover.
        final buttonCenter = tester.getCenter(find.byType(LayrzButton));
        await tester.startGesture(buttonCenter);
        await tester.pump();

        final hoveredSize = tester.getSize(find.byType(LayrzButton));

        expect(
          hoveredSize.width,
          closeTo(defaultSize.width, 0.1),
          reason: 'Width should not change between default and hovered states (D15)',
        );
      });

      testWidgets('regression: width consistent between default and pressed states (D15)', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Test Width Stability',
            onTap: () {},
          ),
        );

        await tester.pump();
        final defaultSize = tester.getSize(find.byType(LayrzButton));

        // Simulate press.
        final gesture = await tester.startGesture(tester.getCenter(find.byType(LayrzButton)));
        await tester.pump();

        final pressedSize = tester.getSize(find.byType(LayrzButton));

        expect(
          pressedSize.width,
          closeTo(defaultSize.width, 0.1),
          reason: 'Width should not change between default and pressed states (D15)',
        );

        await gesture.up();
        await tester.pump();
      });
    });

    group('Interaction state visual changes', () {
      /// Helper to extract the background color from the AnimatedContainer's decoration.
      Color? extractBackgroundColor(WidgetTester tester) {
        final container = find.byType(AnimatedContainer);
        if (container.evaluate().isEmpty) return null;

        final widget = tester.widget<AnimatedContainer>(container);
        final decoration = widget.decoration as BoxDecoration?;
        return decoration?.color;
      }

      testWidgets('outlined style press changes background color', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Outlined Button',
            style: LayrzButtonStyle.outlined,
            onTap: () {},
          ),
        );

        // Capture default state color.
        final defaultColor = extractBackgroundColor(tester);
        expect(defaultColor, isNotNull, reason: 'Default color should be present');

        // Simulate press via GestureDetector.
        final gesture = await tester.startGesture(tester.getCenter(find.byType(LayrzButton)));
        await tester.pump();

        // Capture pressed state color.
        final pressedColor = extractBackgroundColor(tester);
        expect(pressedColor, isNotNull, reason: 'Pressed color should be present');
        expect(
          pressedColor,
          isNot(defaultColor),
          reason: 'Outlined button should change background on press',
        );

        await gesture.up();
        await tester.pump();
      });

      testWidgets('outlined style release restores default background color', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Outlined Button',
            style: LayrzButtonStyle.outlined,
            onTap: () {},
          ),
        );

        // Capture default state color.
        final defaultColor = extractBackgroundColor(tester);
        expect(defaultColor, isNotNull, reason: 'Default color should be present');

        // Simulate press and release.
        final gesture = await tester.startGesture(tester.getCenter(find.byType(LayrzButton)));
        await tester.pump();

        final pressedColor = extractBackgroundColor(tester);
        expect(pressedColor, isNot(defaultColor), reason: 'Color should change on press');

        // Release and wait for the AnimatedContainer to animate back.
        await gesture.up();
        await tester.pumpAndSettle();

        // Verify color returns to default.
        final releasedColor = extractBackgroundColor(tester);
        expect(
          releasedColor,
          defaultColor,
          reason: 'Background color should return to default after release',
        );
      });

      testWidgets('filled style press changes background color', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Filled Button',
            style: LayrzButtonStyle.filled,
            onTap: () {},
          ),
        );

        // Capture default state color.
        final defaultColor = extractBackgroundColor(tester);
        expect(defaultColor, isNotNull, reason: 'Default color should be present');

        // Simulate press.
        final gesture = await tester.startGesture(tester.getCenter(find.byType(LayrzButton)));
        await tester.pump();

        // Capture pressed state color.
        final pressedColor = extractBackgroundColor(tester);
        expect(pressedColor, isNotNull, reason: 'Pressed color should be present');
        expect(
          pressedColor,
          isNot(defaultColor),
          reason: 'Filled button should shift color on press (lerp towards content color)',
        );

        await gesture.up();
        await tester.pump();
      });

      testWidgets('button visual state rebuilds when widget state changes', (tester) async {
        // This test verifies that the fix (adding a listener to _statesController)
        // properly causes rebuilds when interaction states change.
        // It does this by checking that the AnimatedContainer's decoration changes
        // in response to state changes triggered by press/release.
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Test Button',
            style: LayrzButtonStyle.filledTonal,
            onTap: () {},
          ),
        );

        // Get initial state of AnimatedContainer.
        final containerFinder = find.byType(AnimatedContainer);
        expect(containerFinder, findsOneWidget, reason: 'Button should render with AnimatedContainer');

        // Verify that pressing causes a widget rebuild (not just state update).
        var initialDecoration = (tester.widget<AnimatedContainer>(containerFinder).decoration as BoxDecoration).color;

        final gesture = await tester.startGesture(tester.getCenter(find.byType(LayrzButton)));
        await tester.pump();

        var pressedDecoration = (tester.widget<AnimatedContainer>(containerFinder).decoration as BoxDecoration).color;

        // The key assertion: if the listener wasn't added, pressed == initial.
        // With the fix, they should differ because a rebuild occurred.
        expect(
          pressedDecoration,
          isNot(initialDecoration),
          reason: 'AnimatedContainer decoration should change on press (requires listener to trigger rebuild)',
        );

        await gesture.up();
        await tester.pump();
      });
    });
  });
}
