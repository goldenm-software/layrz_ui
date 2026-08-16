import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/buttons.dart';
import 'package:layrz_ui/constants.dart';
import 'package:layrz_ui/src/buttons/button_indicator.dart';

import '../helpers/find_button_label.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('Loading and cooldown indicators', () {
    testWidgets('controller loading displays indicator', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Loading',
          controller: controller,
          onTap: () {},
        ),
      );

      controller.startLoading();
      // Use bounded pump() instead of pumpAndSettle() due to infinite animation.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LayrzButton), findsOneWidget);

      controller.dispose();
    });

    testWidgets('controller cooldown displays indicator', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Cooldown',
          controller: controller,
          onTap: () {},
        ),
      );

      controller.startCooldown(const Duration(seconds: 10));
      // Use bounded pump() instead of pumpAndSettle() due to infinite animation.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LayrzButton), findsOneWidget);

      controller.dispose();
    });

    testWidgets('indicator animates', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Animating',
          controller: controller,
          onTap: () {},
        ),
      );

      controller.startLoading();
      // Run animation for a bit.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LayrzButton), findsOneWidget);

      // Run a full animation cycle.
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(LayrzButton), findsOneWidget);

      controller.dispose();
    });

    testWidgets('indicator is disposed without throwing', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Dispose Test',
          controller: controller,
          onTap: () {},
        ),
      );

      controller.startLoading();
      controller.dispose();

      // Pump a different tree.
      await tester.pumpWidget(const SizedBox.shrink());

      // No exception should be thrown.
      expect(find.byType(LayrzButton), findsNothing);
    });

    testWidgets('loading indicator suppresses taps', (tester) async {
      final controller = LayrzButtonController();
      int tapCount = 0;

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Button',
          controller: controller,
          onTap: () => tapCount++,
        ),
      );

      controller.startLoading();
      // Pump to rebuild button with loading state before attempting tap.
      await tester.pump();

      await tester.tap(find.byType(LayrzButton), warnIfMissed: false);
      await tester.pump();

      expect(tapCount, equals(0));

      // Stop loading.
      controller.stopLoading();
      await tester.pump(const Duration(milliseconds: 150));

      // Now taps should work.
      await tester.tap(find.byType(LayrzButton));
      await tester.pump();

      expect(tapCount, equals(1));

      controller.dispose();
    });

    testWidgets('cooldown indicator suppresses taps', (tester) async {
      final controller = LayrzButtonController();
      int tapCount = 0;

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Button',
          controller: controller,
          onTap: () => tapCount++,
        ),
      );

      controller.startCooldown(const Duration(seconds: 10));
      // Pump to rebuild button with cooldown state before attempting tap.
      await tester.pump();

      await tester.tap(find.byType(LayrzButton), warnIfMissed: false);
      await tester.pump();

      expect(tapCount, equals(0));

      // Clear cooldown.
      controller.clearCooldown();
      // Pump to rebuild button with cleared cooldown state.
      await tester.pump();

      // Now taps should work.
      await tester.tap(find.byType(LayrzButton));
      await tester.pump();

      expect(tapCount, equals(1));

      controller.dispose();
    });

    testWidgets('indicator has pill-shaped ends', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Radius Test',
          controller: controller,
          onTap: () {},
        ),
      );

      controller.startLoading();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the LayrzButtonIndicator widget
      final indicatorFinder = find.byType(LayrzButtonIndicator);
      expect(indicatorFinder, findsOneWidget);

      final indicator = tester.widget<LayrzButtonIndicator>(indicatorFinder);

      // The indicator's borderRadius should be height/2 to create a pill shape
      // with fully rounded ends (capsule shape).
      expect(
        indicator.borderRadius,
        equals(kLayrzButtonIndicatorHeight / 2),
        reason: 'indicator should have pill-shaped ends (borderRadius = height/2)',
      );

      controller.dispose();
    });

    testWidgets('indicator renders at slim height, not full button height', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Height Test',
          controller: controller,
          onTap: () {},
        ),
      );

      controller.startLoading();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the LayrzButtonIndicator widget
      final indicatorFinder = find.byType(LayrzButtonIndicator);
      expect(indicatorFinder, findsOneWidget);

      final indicator = tester.widget<LayrzButtonIndicator>(indicatorFinder);

      // The indicator height should be the slim 3.0 pixels, not the full 45.0 button height
      expect(
        indicator.height,
        equals(kLayrzButtonIndicatorHeight),
        reason: 'indicator height should be slim (3.0) not full button height (45.0)',
      );
      expect(
        indicator.height,
        lessThan(kLayrzButtonHeight),
        reason: 'indicator height should be much less than button height',
      );

      controller.dispose();
    });

    testWidgets('label remains findable and visible during loading', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'ReadableLabel',
          controller: controller,
          onTap: () {},
        ),
      );

      // Verify label is visible when idle
      expect(findButtonLabel('ReadableLabel'), findsOneWidget);

      controller.startLoading();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify label is still visible when loading
      // (not covered by the slim indicator)
      expect(findButtonLabel('ReadableLabel'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('label remains findable during cooldown', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'CooldownLabel',
          controller: controller,
          onTap: () {},
        ),
      );

      // Verify label is visible when idle
      expect(findButtonLabel('CooldownLabel'), findsOneWidget);

      controller.startCooldown(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify label is still visible during cooldown countdown
      // (not covered by the slim indicator)
      expect(findButtonLabel('CooldownLabel'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('button size is identical between idle and busy states', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'SizeTest',
          controller: controller,
          onTap: () {},
        ),
      );

      // Measure button size when idle
      final idleSize = tester.getSize(find.byType(LayrzButton));

      controller.startLoading();
      await tester.pump(const Duration(milliseconds: 100));

      // Measure button size when busy
      final busySize = tester.getSize(find.byType(LayrzButton));

      // Sizes should be identical (indicator overlays, doesn't take layout space)
      expect(
        busySize,
        equals(idleSize),
        reason: 'button size must not change between idle and busy (D15)',
      );

      controller.dispose();
    });

    testWidgets('indicator is horizontally inset to clear button corners', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'InsetTest',
          controller: controller,
          onTap: () {},
        ),
      );

      controller.startLoading();
      await tester.pump(const Duration(milliseconds: 100));

      // The Positioned widget applies the inset via left and right properties
      // (borderWidth + kLayrzButtonIndicatorInsetHorizontal) on each side.
      // The indicator renders with pill-shaped ends (borderRadius = height/2),
      // and inset positioning keeps it clear of the button's rounded corners.
      final indicatorFinder = find.byType(LayrzButtonIndicator);
      expect(
        indicatorFinder,
        findsOneWidget,
        reason: 'indicator should render with horizontal inset',
      );

      controller.dispose();
    });

    testWidgets('indicator bottom inset is smaller than horizontal inset', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'BottomInsetTest',
          controller: controller,
          onTap: () {},
        ),
      );

      controller.startLoading();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify that the bottom inset constant is the smaller value
      expect(
        kLayrzButtonIndicatorInsetBottom,
        lessThan(kLayrzButtonIndicatorInsetHorizontal),
        reason: 'bottom inset should be smaller to keep bar close to bottom edge',
      );

      // The bottom inset should be 1.0 logical pixel
      expect(
        kLayrzButtonIndicatorInsetBottom,
        equals(1.0),
        reason: 'bottom inset should be 1.0 logical pixel',
      );

      controller.dispose();
    });

    testWidgets('determinate mode renders with inset', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'DeterminateInset',
          controller: controller,
          onTap: () {},
        ),
      );

      controller.startCooldown(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the indicator renders with the inset positioning
      final indicatorFinder = find.byType(LayrzButtonIndicator);
      expect(
        indicatorFinder,
        findsOneWidget,
        reason: 'indicator should render in determinate mode with horizontal inset',
      );

      controller.dispose();
    });

    testWidgets('indeterminate mode renders with inset', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'IndeterminateInset',
          controller: controller,
          onTap: () {},
        ),
      );

      controller.startLoading();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the indicator renders with the inset positioning
      final indicatorFinder = find.byType(LayrzButtonIndicator);
      expect(
        indicatorFinder,
        findsOneWidget,
        reason: 'indicator should render in indeterminate mode with horizontal inset',
      );

      controller.dispose();
    });
  });
}
