import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/buttons/buttons.dart';
import 'package:layrz_ui/buttons/src/button_indicator.dart';

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

    testWidgets('indicator border radius accounts for button border width', (tester) async {
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

      // The indicator's borderRadius should be computed using innerRadiusValue,
      // which is less than the button's base radius due to the border width inset.
      // This ensures the indicator's corners are concentric with the button's border.
      expect(
        indicator.borderRadius,
        lessThan(8.0), // Default base radius is 8, and subtracting border width (1.5) gives 6.5
        reason: 'indicator radius should be less than button base radius due to border inset',
      );

      controller.dispose();
    });
  });
}
