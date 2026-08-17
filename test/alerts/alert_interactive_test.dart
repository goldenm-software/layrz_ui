import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_font_handler.dart';
import '../helpers/pump_themed.dart';

/// Helper to find the AnimatedContainer inside a LayrzAlert.
Finder _findAnimatedContainer() => find.descendant(
  of: find.byType(LayrzAlert),
  matching: find.byType(AnimatedContainer),
);

void main() {
  group('LayrzAlert Interactive', () {
    group('Non-interactive (onTap: null)', () {
      testWidgets('inert alert does not have FocusableActionDetector', (tester) async {
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: null,
            ),
          ),
        );

        // Inert alerts have no interactive machinery
        final focusableDetectors = find.byType(FocusableActionDetector);
        expect(
          focusableDetectors,
          findsNothing,
          reason: 'Inert alerts must not have FocusableActionDetector (no keyboard support)',
        );
      });

      testWidgets('inert alert does not respond to taps', (tester) async {
        var tapped = false;

        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: null,
            ),
          ),
        );

        // Try to tap the alert - nothing should happen
        await tester.tap(find.byType(LayrzAlert));
        await tester.pumpAndSettle();

        expect(tapped, isFalse, reason: 'Inert alert (onTap: null) should not respond to taps');
      });
    });

    group('Interactive (onTap non-null)', () {
      testWidgets('interactive alert has FocusableActionDetector for accessibility', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () {},
            ),
          ),
        );

        // Interactive alerts have FocusableActionDetector
        final focusableDetectors = find.byType(FocusableActionDetector);
        expect(
          focusableDetectors,
          findsOneWidget,
          reason: 'Interactive alerts must have FocusableActionDetector (Semantics: button=true, keyboard support)',
        );
      });

      testWidgets('tapping fires onTap callback', (tester) async {
        var tapped = false;

        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () => tapped = true,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzAlert));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('tapping fires onTap callback exactly once', (tester) async {
        var tapCount = 0;

        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () => tapCount++,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzAlert));
        await tester.pumpAndSettle();

        expect(tapCount, equals(1));
      });

      testWidgets('interactive alert has FocusableActionDetector for keyboard support', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () {},
            ),
          ),
        );

        // Interactive alerts must have FocusableActionDetector to support Enter/Space activation
        final focusableDetectors = find.byType(FocusableActionDetector);
        expect(
          focusableDetectors,
          findsOneWidget,
          reason:
              'Interactive alerts must have FocusableActionDetector which wires ActivateIntent '
              '(Enter/Space) to onTap via CallbackAction',
        );
      });
    });

    group('Hover lift behavior — transform values verified', () {
      testWidgets('interactive alert has AnimatedContainer with transform for lift effect', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () {},
            ),
          ),
          theme: themeData,
        );

        // Pump to settle
        await tester.pumpAndSettle();

        // Find the AnimatedContainer
        final container = tester.widget<AnimatedContainer>(_findAnimatedContainer());

        // Verify it has a transform property (used for lift)
        expect(
          container.transform,
          isNotNull,
          reason: 'AnimatedContainer must have a transform for paint-only lift effect',
        );

        // Verify transform uses Matrix4.translationValues(0, -lift, 0)
        final translation = container.transform!.getTranslation();
        // Initial state: at rest, so translation.y should be 0
        expect(
          translation.y,
          equals(0.0),
          reason: 'At rest, transform translation.y must be 0.0 (no lift)',
        );

        // Verify the animation duration matches tokens
        expect(
          container.duration,
          equals(themeData.tokens.motion.dHover),
          reason: 'AnimatedContainer must animate with dHover duration',
        );

        // Verify the curve is correct
        expect(
          container.curve,
          equals(themeData.tokens.motion.easingEnter),
          reason: 'AnimatedContainer must animate with easingEnter curve',
        );
      });

      testWidgets('pressing and releasing fires callback (verifies FocusableActionDetector + '
          'GestureDetector wiring)', (tester) async {
        var tapped = false;

        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () => tapped = true,
            ),
          ),
          theme: themeData,
        );

        // Simulate press and release
        final center = tester.getCenter(find.byType(LayrzAlert));
        final gesture = await tester.startGesture(center);
        await tester.pumpAndSettle();

        await gesture.up();
        await tester.pumpAndSettle();

        expect(
          tapped,
          isTrue,
          reason: 'onTap should fire when pressing and releasing',
        );
      });
    });

    group('Anti-flicker test — hit region invariant (test 6 must catch broken implementations)', () {
      testWidgets('pressing near bottom edge: hit region stays fixed (proves transform is paint-only)', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () {},
            ),
          ),
          theme: themeData,
        );

        // Get the alert bounds
        final rect = tester.getRect(find.byType(LayrzAlert));

        // Simulate press near the bottom edge
        final bottomCenter = Offset(rect.center.dx, rect.bottomRight.dy - 2);
        final gesture = await tester.startGesture(bottomCenter);
        await tester.pumpAndSettle();

        // Pump multiple frames during press
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        // The alert's hit region (rect) must NOT move during or after press
        final pressedRect = tester.getRect(find.byType(LayrzAlert));
        expect(
          pressedRect.topLeft,
          equals(rect.topLeft),
          reason:
              'CRITICAL: Hit region must not move during press. If this fails, the lift '
              'uses layout properties (padding/margin) instead of paint-only transform.',
        );
        expect(
          pressedRect.size,
          equals(rect.size),
          reason: 'Hit region size must not change during press',
        );

        await gesture.up();
        await tester.pumpAndSettle();

        final releasedRect = tester.getRect(find.byType(LayrzAlert));
        expect(
          releasedRect,
          equals(rect),
          reason:
              'Hit region must be identical before, during, and after press '
              '— proof of paint-only transform',
        );
      });
    });

    group('Layout neutrality (Decision D15) — paint-only proof (test 7 must catch broken '
        'implementations)', () {
      testWidgets('alert size remains constant during interaction', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () {},
            ),
          ),
          theme: themeData,
        );

        // Capture baseline size
        final baselineSize = tester.getSize(find.byType(LayrzAlert));

        // Simulate press
        final center = tester.getCenter(find.byType(LayrzAlert));
        final gesture = await tester.startGesture(center);
        await tester.pumpAndSettle();

        // Check size while pressed
        final pressedSize = tester.getSize(find.byType(LayrzAlert));
        expect(
          pressedSize,
          equals(baselineSize),
          reason:
              'CRITICAL: Size must not change while pressed. If this fails, the lift uses '
              'animated padding or other layout properties instead of transform.',
        );

        await gesture.up();
        await tester.pumpAndSettle();

        // Check size after press
        final releasedSize = tester.getSize(find.byType(LayrzAlert));
        expect(releasedSize, equals(baselineSize), reason: 'Size must not change after press');
      });

      testWidgets('alert position (layout bounds) remains constant during interaction', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              onTap: () {},
            ),
          ),
          theme: themeData,
        );

        // Capture baseline position (layout bounds)
        final baselineTopLeft = tester.getTopLeft(find.byType(LayrzAlert));

        // Simulate press
        final center = tester.getCenter(find.byType(LayrzAlert));
        final gesture = await tester.startGesture(center);
        await tester.pumpAndSettle();

        // Check position while pressed
        final pressedTopLeft = tester.getTopLeft(find.byType(LayrzAlert));
        expect(
          pressedTopLeft,
          equals(baselineTopLeft),
          reason:
              'CRITICAL: Layout position must not move while pressed. If this fails, the '
              'lift uses layout properties instead of paint-only transform.',
        );

        await gesture.up();
        await tester.pumpAndSettle();

        // Check position after press
        final releasedTopLeft = tester.getTopLeft(find.byType(LayrzAlert));
        expect(
          releasedTopLeft,
          equals(baselineTopLeft),
          reason: 'Layout position must not move after press',
        );
      });
    });

    group('All styles support interactivity', () {
      for (final style in LayrzAlertStyle.values) {
        testWidgets('$style supports onTap', (tester) async {
          var tapped = false;

          await pumpThemed(
            tester,
            SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Title',
                description: 'Description',
                style: style,
                onTap: () => tapped = true,
              ),
            ),
          );

          await tester.tap(find.byType(LayrzAlert));
          await tester.pumpAndSettle();

          expect(tapped, isTrue);
        });
      }
    });

    group('Hover lift translation — concrete values verified', () {
      testWidgets('hovering lifts the surface by kLayrzAlertHoverLift', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Body',
              onTap: () {},
            ),
          ),
          theme: themeData,
        );

        Matrix4? transformOf() => tester
            .widget<AnimatedContainer>(
              find
                  .descendant(
                    of: find.byType(LayrzAlert),
                    matching: find.byType(AnimatedContainer),
                  )
                  .first,
            )
            .transform;

        // At rest: no lift
        expect(
          transformOf()!.getTranslation().y,
          equals(0.0),
          reason: 'At rest the surface must not be translated',
        );

        // Move mouse over the alert
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        await gesture.moveTo(tester.getCenter(find.byType(LayrzAlert)));
        await tester.pumpAndSettle();

        // Hovering: lifted up by kLayrzAlertHoverLift
        expect(
          transformOf()!.getTranslation().y,
          equals(-kLayrzAlertHoverLift),
          reason: 'Hovering must lift the surface by exactly kLayrzAlertHoverLift',
        );

        // Move mouse away
        await gesture.moveTo(const Offset(2000, 2000));
        await tester.pumpAndSettle();

        // Back to rest: no lift
        expect(
          transformOf()!.getTranslation().y,
          equals(0.0),
          reason: 'Leaving the alert must return it to rest',
        );
      });

      testWidgets('pressed surface settles back to y=0', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Body',
              onTap: () {},
            ),
          ),
          theme: themeData,
        );

        Matrix4? transformOf() => tester
            .widget<AnimatedContainer>(
              find
                  .descendant(
                    of: find.byType(LayrzAlert),
                    matching: find.byType(AnimatedContainer),
                  )
                  .first,
            )
            .transform;

        // Move mouse over to lift
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await gesture.moveTo(tester.getCenter(find.byType(LayrzAlert)));
        await tester.pumpAndSettle();

        // Verify lifted
        expect(transformOf()!.getTranslation().y, equals(-kLayrzAlertHoverLift));

        // Press
        final center = tester.getCenter(find.byType(LayrzAlert));
        final pressGesture = await tester.startGesture(center);
        await tester.pumpAndSettle();

        // Pressed: settled to y=0
        expect(
          transformOf()!.getTranslation().y,
          equals(0.0),
          reason: 'Pressed surface must settle back to y=0',
        );

        await pressGesture.up();
        await tester.pumpAndSettle();
      });
    });

    group('Keyboard activation — Enter and Space keys', () {
      testWidgets('Enter and Space activate onTap inside LayrzApp', (tester) async {
        var taps = 0;

        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(fontHandler: const FakeFontHandler()),
            debugShowCheckedModeBanner: false,
            home: Center(
              child: SizedBox(
                width: 300,
                child: LayrzAlert(
                  title: 'Title',
                  description: 'Body',
                  onTap: () => taps++,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Focus the alert via Tab key (enabled by WidgetsApp focus traversal policy)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Send Enter key
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        expect(taps, equals(1), reason: 'Enter must activate an interactive alert');

        // Send Space key
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        expect(taps, equals(2), reason: 'Space must activate an interactive alert');
      });
    });
  });
}
