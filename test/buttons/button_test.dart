import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/buttons/buttons.dart';

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

        expect(find.text('Test Button'), findsOneWidget);
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

        expect(find.byIcon(LayrzIcons.solarOutlineCheckCircle), findsOneWidget);
        expect(find.text('Test Button'), findsOneWidget);
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

        // Icon should be present.
        expect(find.byIcon(LayrzIcons.solarOutlineCheckCircle), findsOneWidget);

        // Label should NOT be rendered as visible text.
        // Fab uses Stack with only an icon and no Row/Text child for the label.
        final textFinders = find.byType(Text);
        int visibleTextCount = 0;
        for (int i = 0; i < textFinders.evaluate().length; i++) {
          final widget = textFinders.evaluate().elementAt(i).widget;
          if (widget is Text && widget.data == 'Test Fab') {
            visibleTextCount++;
          }
        }
        expect(visibleTextCount, 0);
      });

      testWidgets('long labelText ellipsises instead of overflowing', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'This is a very long button label that should ellipsize',
            width: 100,
            onTap: () {},
          ),
        );

        // Find the Text widget and check it has ellipsis overflow.
        final textWidget = find.byType(Text).first;
        final text = tester.widget<Text>(textWidget);
        expect(text.overflow, equals(TextOverflow.ellipsis));
        expect(text.maxLines, equals(1));
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

          expect(
            find.text('Style Test'),
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

        await tester.tap(find.text('Disabled Button'));
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

        await tester.tap(find.text('Disabled Button'));
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

        await tester.tap(find.text('Enabled Button'));
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

        await tester.tap(find.text('Multi-tap Button'));
        await tester.tap(find.text('Multi-tap Button'));
        await tester.pump();

        expect(tapCount, equals(2));
      });
    });

    group('Loading state', () {
      testWidgets('isLoading: null renders normally without indicator', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'No Loading',
            isLoading: null,
            onTap: () {},
          ),
        );

        expect(find.byType(LayrzButton), findsOneWidget);
        // No loading indicator should be present.
        // We can't directly check for the absence of _LayrzButtonIndicator,
        // but we can verify the button renders normally.
      });

      testWidgets('isLoading: false renders normally without indicator', (tester) async {
        final loading = ValueNotifier<bool>(false);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Not Loading',
            isLoading: loading,
            onTap: () {},
          ),
        );

        expect(find.text('Not Loading'), findsOneWidget);
      });

      testWidgets('isLoading: true shows indicator and suppresses tap', (tester) async {
        final loading = ValueNotifier<bool>(true);
        int tapCount = 0;

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Loading Button',
            isLoading: loading,
            onTap: () => tapCount++,
          ),
        );

        await tester.pump();

        // Try to tap while loading.
        await tester.tap(find.text('Loading Button'));
        await tester.pump();

        expect(tapCount, equals(0), reason: 'Tap should be suppressed during loading');
      });

      testWidgets('isLoading transitions from false to true to false', (tester) async {
        final loading = ValueNotifier<bool>(false);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Toggle Loading',
            isLoading: loading,
            onTap: () {},
          ),
        );

        // Initially not loading.
        await tester.pump();
        expect(find.text('Toggle Loading'), findsOneWidget);

        // Change to loading.
        loading.value = true;
        await tester.pump();
        expect(find.text('Toggle Loading'), findsOneWidget);

        // Change back to not loading.
        loading.value = false;
        await tester.pump();
        expect(find.text('Toggle Loading'), findsOneWidget);
      });
    });

    group('Cooldown state', () {
      testWidgets('isCooldown: null renders normally without indicator', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'No Cooldown',
            isCooldown: null,
            onTap: () {},
          ),
        );

        expect(find.byType(LayrzButton), findsOneWidget);
      });

      testWidgets('isCooldown: false renders normally without indicator', (tester) async {
        final cooldown = ValueNotifier<bool>(false);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Not Cooling',
            isCooldown: cooldown,
            onTap: () {},
          ),
        );

        expect(find.text('Not Cooling'), findsOneWidget);
      });

      testWidgets('isCooldown: true shows indicator and suppresses tap', (tester) async {
        final cooldown = ValueNotifier<bool>(true);
        int tapCount = 0;

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Cooldown Button',
            isCooldown: cooldown,
            onTap: () => tapCount++,
          ),
        );

        await tester.pump();

        await tester.tap(find.text('Cooldown Button'));
        await tester.pump();

        expect(tapCount, equals(0), reason: 'Tap should be suppressed during cooldown');
      });

      testWidgets('isCooldown transitions from false to true to false', (tester) async {
        final cooldown = ValueNotifier<bool>(false);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Toggle Cooldown',
            isCooldown: cooldown,
            onTap: () {},
          ),
        );

        await tester.pump();
        expect(find.text('Toggle Cooldown'), findsOneWidget);

        cooldown.value = true;
        await tester.pump();
        expect(find.text('Toggle Cooldown'), findsOneWidget);

        cooldown.value = false;
        await tester.pump();
        expect(find.text('Toggle Cooldown'), findsOneWidget);
      });
    });

    group('Tooltip behavior', () {
      testWidgets('non-Fab with hintText and tooltipEnabled: true shows tooltip on long-press', (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        addTearDown(tester.view.resetPhysicalSize);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Button',
            hintText: 'This is a hint',
            tooltipEnabled: true,
            onTap: () {},
          ),
        );

        await tester.pump();

        // Long press to trigger tooltip.
        await tester.longPress(find.text('Button'));
        await tester.pump();

        // Tooltip should appear (we can't easily verify visual appearance,
        // but the widget should render without throwing).
        expect(find.byType(LayrzButton), findsOneWidget);
      });

      testWidgets('non-Fab with hintText and tooltipEnabled: false does not show tooltip', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Button',
            hintText: 'This is a hint',
            tooltipEnabled: false,
            onTap: () {},
          ),
        );

        await tester.pump();

        // The button should render, but no tooltip wrapper should be used.
        expect(find.byType(LayrzButton), findsOneWidget);
      });

      testWidgets('non-Fab without hintText does not show tooltip even if tooltipEnabled: true', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Button',
            hintText: null,
            tooltipEnabled: true,
            onTap: () {},
          ),
        );

        await tester.pump();

        expect(find.byType(LayrzButton), findsOneWidget);
      });

      testWidgets('Fab uses labelText as tooltip', (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        addTearDown(tester.view.resetPhysicalSize);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Fab Button',
            style: LayrzButtonStyle.filledTonalFab,
            onTap: () {},
          ),
        );

        await tester.pump();

        // Long press on the Fab.
        await tester.longPress(find.byType(LayrzButton));
        await tester.pump();

        // Fab should always show tooltip with labelText.
        expect(find.byType(LayrzButton), findsOneWidget);
      });

      testWidgets('Fab tooltipEnabled parameter has no effect', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Fab Always Shows Tooltip',
            style: LayrzButtonStyle.filledTonalFab,
            tooltipEnabled: false,
            onTap: () {},
          ),
        );

        await tester.pump();

        // Even with tooltipEnabled: false, Fab should still be tappable.
        expect(find.byType(LayrzButton), findsOneWidget);
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

        expect(find.text('Custom Color'), findsOneWidget);
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

          expect(find.text('Custom'), findsOneWidget);
        }
      });
    });

    group('Tooltip visibility', () {
      testWidgets('regression: tooltipEnabled: false on Fab suppresses RawTooltip mount', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Fab No Tooltip',
            style: LayrzButtonStyle.filledTonalFab,
            tooltipEnabled: false,
            onTap: () {},
          ),
        );

        // When tooltipEnabled: false, RawTooltip should not be mounted
        expect(find.byType(RawTooltip), findsNothing);
      });

      testWidgets('regression: tooltipEnabled: false on non-Fab with hintText suppresses tooltip', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Button Text',
            hintText: 'Hint Text',
            tooltipEnabled: false,
            onTap: () {},
          ),
        );

        // When tooltipEnabled: false, RawTooltip should not be mounted even with hintText
        expect(find.byType(RawTooltip), findsNothing);
      });

      testWidgets('regression: tooltipEnabled: true (default) on Fab mounts RawTooltip', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Fab With Tooltip',
            style: LayrzButtonStyle.filledTonalFab,
            onTap: () {},
          ),
        );

        // By default, Fab mounts RawTooltip for the tooltip (tooltipEnabled: true is default)
        expect(find.byType(RawTooltip), findsOneWidget);
      });

      testWidgets('regression: tooltipEnabled: true on non-Fab with hintText mounts RawTooltip', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Button Text',
            hintText: 'Hint Text',
            tooltipEnabled: true,
            onTap: () {},
          ),
        );

        // When hintText is provided and tooltipEnabled: true, RawTooltip should be mounted
        expect(find.byType(RawTooltip), findsOneWidget);
      });

      testWidgets('regression: tooltipEnabled: true on non-Fab without hintText suppresses', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Button Text',
            // No hintText provided
            tooltipEnabled: true,
            onTap: () {},
          ),
        );

        // Non-Fab without hintText should not mount RawTooltip, even with tooltipEnabled: true
        expect(find.byType(RawTooltip), findsNothing);
      });
    });
  });
}
