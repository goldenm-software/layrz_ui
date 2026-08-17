import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import 'package:example/src/showroom.dart';

void main() {
  group('Showroom', () {
    testWidgets('builds without exception', (WidgetTester tester) async {
      await tester.pumpWidget(LayrzApp(title: kAppTitle, theme: LayrzThemeData.light(), home: const Showroom()));

      expect(find.byType(Showroom), findsOneWidget);
    });

    testWidgets('displays all section titles', (WidgetTester tester) async {
      await tester.pumpWidget(LayrzApp(title: kAppTitle, theme: LayrzThemeData.light(), home: const Showroom()));

      // Verify all section titles are present
      expect(find.text('Typography'), findsOneWidget);
      expect(find.text('Colors'), findsOneWidget);
      expect(find.text('Spacing'), findsOneWidget);
      expect(find.text('Radius'), findsOneWidget);
      expect(find.text('Elevation & Shadow'), findsOneWidget);
      expect(find.text('Borders & Strokes'), findsOneWidget);
      expect(find.text('Motion'), findsOneWidget);
      expect(find.text('Token Access Paths'), findsOneWidget);
    });

    testWidgets('token access paths agree', (WidgetTester tester) async {
      await tester.pumpWidget(LayrzApp(title: kAppTitle, theme: LayrzThemeData.light(), home: const Showroom()));

      // The access-paths section renders match indicators (✓/✗)
      // We expect all to be ✓ (success/green)
      final successIndicators = find.text('✓');
      expect(successIndicators, findsWidgets);

      // No ✗ (mismatch) indicators should be present
      final mismatchIndicators = find.text('✗');
      expect(mismatchIndicators, findsNothing);
    });

    testWidgets('spacing ruler bars have different widths', (WidgetTester tester) async {
      await tester.pumpWidget(LayrzApp(title: kAppTitle, theme: LayrzThemeData.light(), home: const Showroom()));

      // Find the sp4 and sp48 bars by their keys
      final sp4Bar = find.byKey(const ValueKey('spacing-bar-sp4'));
      final sp48Bar = find.byKey(const ValueKey('spacing-bar-sp48'));

      expect(sp4Bar, findsOneWidget);
      expect(sp48Bar, findsOneWidget);

      // Get the rendered sizes of each bar
      final sp4Size = tester.getSize(sp4Bar);
      final sp48Size = tester.getSize(sp48Bar);

      // sp48 should be 12× the width of sp4 (48 / 4 = 12)
      // Allow small tolerance for rounding
      expect(sp48Size.width, greaterThan(sp4Size.width * 10));
      expect(sp4Size.width, greaterThan(0));
    });

    testWidgets('innerRadius formula is correct and differs from naive approach', (WidgetTester tester) async {
      await tester.pumpWidget(LayrzApp(title: kAppTitle, theme: LayrzThemeData.light(), home: const Showroom()));

      // Find correct variant inner and outer containers
      final correctOuterContainer = find.byKey(const ValueKey('innerRadius-demo-correct-outer'));
      final correctInnerContainer = find.byKey(const ValueKey('innerRadius-demo-correct-inner'));

      // Find naive variant inner and outer containers
      final naiveOuterContainer = find.byKey(const ValueKey('innerRadius-demo-naive-outer'));
      final naiveInnerContainer = find.byKey(const ValueKey('innerRadius-demo-naive-inner'));

      // Find clamp case containers
      final clampOuterContainer = find.byKey(const ValueKey('innerRadius-demo-clamp-outer'));
      final clampInnerContainer = find.byKey(const ValueKey('innerRadius-demo-clamp-inner'));

      // Verify all containers exist
      expect(correctOuterContainer, findsOneWidget);
      expect(correctInnerContainer, findsOneWidget);
      expect(naiveOuterContainer, findsOneWidget);
      expect(naiveInnerContainer, findsOneWidget);
      expect(clampOuterContainer, findsOneWidget);
      expect(clampInnerContainer, findsOneWidget);

      // Extract BorderRadius from correct variant
      final correctOuterDecoration = (tester.widget<Container>(correctOuterContainer).decoration as BoxDecoration);
      final correctInnerDecoration = (tester.widget<Container>(correctInnerContainer).decoration as BoxDecoration);
      final correctOuterRadius = (correctOuterDecoration.borderRadius as BorderRadius).topLeft.x;
      final correctInnerRadius = (correctInnerDecoration.borderRadius as BorderRadius).topLeft.x;

      // Extract BorderRadius from naive variant
      final naiveInnerDecoration = (tester.widget<Container>(naiveInnerContainer).decoration as BoxDecoration);
      final naiveInnerRadius = (naiveInnerDecoration.borderRadius as BorderRadius).topLeft.x;

      // Extract BorderRadius from clamp case
      final clampInnerDecoration = (tester.widget<Container>(clampInnerContainer).decoration as BoxDecoration);
      final clampInnerRadius = (clampInnerDecoration.borderRadius as BorderRadius).topLeft.x;

      // Main assertion: correct inner should be outer - spacer (24 - 12 = 12)
      expect(correctOuterRadius, closeTo(24.0, 0.1));
      expect(correctInnerRadius, closeTo(12.0, 0.1)); // 24 - 12 = 12

      // Naive should reuse the outer radius (24), making it different from correct
      expect(naiveInnerRadius, closeTo(24.0, 0.1));
      expect(naiveInnerRadius, isNot(closeTo(correctInnerRadius, 0.1)));

      // Clamp case: outer=8, spacer=12, result should be clamped to 0
      expect(clampInnerRadius, closeTo(0.0, 0.1));
    });

    testWidgets('hover animation does not change container size', (WidgetTester tester) async {
      // Test that hovering over the demo container does not change its size.
      // The border width must remain constant to prevent geometry shifts.
      await tester.pumpWidget(LayrzApp(title: kAppTitle, theme: LayrzThemeData.light(), home: const Showroom()));

      final hoverDemoFinder = find.byKey(const Key('hover-demo-container'));
      expect(hoverDemoFinder, findsOneWidget);

      // Scroll the motion section into view
      await tester.ensureVisible(hoverDemoFinder);
      await tester.pumpAndSettle();

      // Measure size before hover
      final sizeBeforeHover = tester.getSize(hoverDemoFinder);
      expect(sizeBeforeHover.height, greaterThan(0), reason: 'Container has zero height before hover');

      // Get initial color to verify hover state later
      final initialWidget = tester.widget<AnimatedContainer>(hoverDemoFinder);
      final initialDecoration = initialWidget.decoration as BoxDecoration;
      final initialColor = initialDecoration.color;

      // Create a mouse gesture and move it to trigger hover
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      final containerCenter = tester.getCenter(hoverDemoFinder);
      await gesture.addPointer(location: containerCenter);
      await tester.pump();

      // Move mouse over the container to trigger hover state
      await gesture.moveTo(containerCenter);
      await tester.pumpAndSettle(); // Wait for AnimatedContainer animation to complete

      // Verify hover state actually changed by checking the color
      final hoveredWidget = tester.widget<AnimatedContainer>(hoverDemoFinder);
      final hoveredDecoration = hoveredWidget.decoration as BoxDecoration;
      final hoveredColor = hoveredDecoration.color;
      expect(
        hoveredColor,
        isNot(equals(initialColor)),
        reason: 'Hover state did not change (color unchanged). Hover may not have been triggered.',
      );

      // Measure size after hover
      final sizeAfterHover = tester.getSize(hoverDemoFinder);

      // Assert sizes are identical (height should not grow from border width change)
      expect(
        sizeAfterHover.height,
        equals(sizeBeforeHover.height),
        reason:
            'Height changed from ${sizeBeforeHover.height} to ${sizeAfterHover.height} on hover. '
            'Border width must not change during interaction.',
      );
      expect(
        sizeAfterHover.width,
        equals(sizeBeforeHover.width),
        reason: 'Width changed on hover. Geometry must not shift during interaction.',
      );
    });

    testWidgets('press animation does not change container size', (WidgetTester tester) async {
      // Test that pressing the demo container does not change its size.
      // The border width must remain constant to prevent geometry shifts.
      await tester.pumpWidget(LayrzApp(title: kAppTitle, theme: LayrzThemeData.light(), home: const Showroom()));

      final pressDemoFinder = find.byKey(const Key('press-demo-container'));
      expect(pressDemoFinder, findsOneWidget);

      // Scroll the motion section into view
      await tester.ensureVisible(pressDemoFinder);
      await tester.pumpAndSettle();

      // Measure size before press
      final sizeBeforePress = tester.getSize(pressDemoFinder);
      expect(sizeBeforePress.height, greaterThan(0), reason: 'Container has zero height before press');

      // Get initial color to verify press state later
      final initialWidget = tester.widget<AnimatedContainer>(pressDemoFinder);
      final initialDecoration = initialWidget.decoration as BoxDecoration;
      final initialColor = initialDecoration.color;

      // Start a tap gesture (hold down)
      final gesture = await tester.startGesture(tester.getCenter(pressDemoFinder));
      addTearDown(gesture.removePointer);

      // Wait for animation during press
      await tester.pumpAndSettle();

      // Verify press state actually changed by checking the color
      final pressedWidget = tester.widget<AnimatedContainer>(pressDemoFinder);
      final pressedDecoration = pressedWidget.decoration as BoxDecoration;
      final pressedColor = pressedDecoration.color;
      expect(
        pressedColor,
        isNot(equals(initialColor)),
        reason: 'Press state did not change (color unchanged). Press may not have been triggered.',
      );

      // Measure size during press
      final sizeDuringPress = tester.getSize(pressDemoFinder);

      // Assert sizes are identical (height should not grow from border width change)
      expect(
        sizeDuringPress.height,
        equals(sizeBeforePress.height),
        reason:
            'Height changed from ${sizeBeforePress.height} to ${sizeDuringPress.height} on press. '
            'Border width must not change during interaction.',
      );
      expect(
        sizeDuringPress.width,
        equals(sizeBeforePress.width),
        reason: 'Width changed during press. Geometry must not shift during interaction.',
      );

      // Release the gesture
      await gesture.up();
      await tester.pumpAndSettle();

      // Verify size returns to original after release
      final sizeAfterRelease = tester.getSize(pressDemoFinder);
      expect(
        sizeAfterRelease.height,
        equals(sizeBeforePress.height),
        reason: 'Height did not return to original after release.',
      );
    });
  });
}
