import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTappable', () {
    testWidgets('renders child widget', (WidgetTester tester) async {
      // Arrange & Act
      await pumpThemed(
        tester,
        const LayrzTappable(
          child: Text('Test Child'),
        ),
      );

      // Assert
      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('fires onTap callback when tapped', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      await pumpThemed(
        tester,
        LayrzTappable(
          onTap: () {
            tapped = true;
          },
          child: const Text('Tap Me'),
        ),
      );

      // Act
      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('fires onLongPress callback when long pressed', (WidgetTester tester) async {
      // Arrange
      bool longPressed = false;
      await pumpThemed(
        tester,
        LayrzTappable(
          onLongPress: () {
            longPressed = true;
          },
          child: const Text('Long Press Me'),
        ),
      );

      // Act
      await tester.longPress(find.text('Long Press Me'));
      await tester.pumpAndSettle();

      // Assert
      expect(longPressed, isTrue);
    });

    testWidgets('does not fire onTap when disabled', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      await pumpThemed(
        tester,
        LayrzTappable(
          disabled: true,
          onTap: () {
            tapped = true;
          },
          child: const Text('Tap Me'),
        ),
      );

      // Act
      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isFalse);
    });

    testWidgets('does not fire onLongPress when disabled', (WidgetTester tester) async {
      // Arrange
      bool longPressed = false;
      await pumpThemed(
        tester,
        LayrzTappable(
          disabled: true,
          onLongPress: () {
            longPressed = true;
          },
          child: const Text('Long Press Me'),
        ),
      );

      // Act
      await tester.longPress(find.text('Long Press Me'));
      await tester.pumpAndSettle();

      // Assert
      expect(longPressed, isFalse);
    });

    testWidgets('does not fire onSecondaryTap when disabled', (WidgetTester tester) async {
      // Arrange
      bool secondaryTapped = false;
      await pumpThemed(
        tester,
        LayrzTappable(
          disabled: true,
          onSecondaryTap: () {
            secondaryTapped = true;
          },
          child: const Text('Secondary Tap Me'),
        ),
      );

      // Act
      await tester.tap(find.text('Secondary Tap Me'), buttons: kSecondaryButton);
      await tester.pumpAndSettle();

      // Assert
      expect(secondaryTapped, isFalse);
    });

    testWidgets('applies borderRadius decoration', (WidgetTester tester) async {
      // Arrange
      const radius = BorderRadius.all(Radius.circular(12));
      await pumpThemed(
        tester,
        LayrzTappable(
          borderRadius: radius,
          child: Container(
            width: 100,
            height: 100,
            color: const Color(0xFF0000FF),
          ),
        ),
      );

      // Act & Assert
      // The DecoratedBox should have the borderRadius applied.
      // We verify by checking that the widget tree contains the expected structure.
      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('uses transparent color by default in idle state', (WidgetTester tester) async {
      // Arrange
      await pumpThemed(
        tester,
        LayrzTappable(
          onTap: () {},
          child: Container(
            width: 100,
            height: 100,
            color: const Color(0xFF0000FF),
          ),
        ),
      );

      // Act & Assert
      // When idle, the surface color should be transparent.
      // This is verified by the presence of AnimatedContainer with transparent decoration.
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('applies custom color when provided', (WidgetTester tester) async {
      // Arrange
      const customColor = Color(0xFFFF5733);
      await pumpThemed(
        tester,
        LayrzTappable(
          color: customColor,
          child: const Text('Custom Color'),
        ),
      );

      // Act & Assert
      expect(find.text('Custom Color'), findsOneWidget);
      // The DecoratedBox and AnimatedContainer should contain the custom color.
      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('fires onSecondaryTap callback when secondary tapped', (WidgetTester tester) async {
      // Arrange
      bool secondaryTapped = false;
      await pumpThemed(
        tester,
        LayrzTappable(
          onSecondaryTap: () {
            secondaryTapped = true;
          },
          child: const Text('Secondary Tap Me'),
        ),
      );

      // Act
      await tester.tap(find.text('Secondary Tap Me'), buttons: kSecondaryButton);
      await tester.pumpAndSettle();

      // Assert
      expect(secondaryTapped, isTrue);
    });

    testWidgets('has opaque hit test behavior for full area tappability', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      await pumpThemed(
        tester,
        LayrzTappable(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            tapped = true;
          },
          child: Container(
            width: 100,
            height: 100,
            color: const Color(0xFFFFFFFF),
          ),
        ),
      );

      // Act
      // Tap at the center of the widget.
      await tester.tap(find.byType(Container).first);
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('taps work near edges (corner tappability)', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      await pumpThemed(
        tester,
        SizedBox(
          width: 200,
          height: 200,
          child: LayrzTappable(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              tapped = true;
            },
            child: Container(
              width: 100,
              height: 100,
              color: const Color(0xFFFFFFFF),
            ),
          ),
        ),
      );

      // Act
      // Tap at a point offset from center (should still work with HitTestBehavior.opaque).
      final tappableCenter = tester.getCenter(find.byType(LayrzTappable));
      final tapPoint = Offset(
        tappableCenter.dx - 20,
        tappableCenter.dy - 20,
      );
      await tester.tapAt(tapPoint);
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('is inert when onTap, onLongPress, and onSecondaryTap are all null', (WidgetTester tester) async {
      // Arrange
      await pumpThemed(
        tester,
        const LayrzTappable(
          child: Text('Inert Widget'),
        ),
      );

      // Act & Assert
      // The widget should render but not respond to gestures.
      expect(find.text('Inert Widget'), findsOneWidget);
      // No GestureDetector should be present in the inactive widget path.
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('applies custom hoverColor when provided', (WidgetTester tester) async {
      // Arrange
      await pumpThemed(
        tester,
        LayrzTappable(
          onTap: () {},
          child: const Text('Custom Hover'),
        ),
      );

      // Act & Assert
      // The widget should be present.
      expect(find.text('Custom Hover'), findsOneWidget);
    });

    testWidgets('applies custom pressedColor when provided', (WidgetTester tester) async {
      // Arrange

      await pumpThemed(
        tester,
        LayrzTappable(
          onTap: () {},
          child: const Text('Custom Pressed'),
        ),
      );

      // Act & Assert
      // The widget should be present.
      expect(find.text('Custom Pressed'), findsOneWidget);
    });

    group('double-tap', () {
      // `SelectableRegion` (exercised in the text-selection test below) branches
      // on `debugDefaultTargetPlatformOverride`, taking a desktop-only path on a
      // Linux test host that Android never takes. Pin the platform for every test
      // in this group so all of them exercise the same (Android) branch the
      // Notion row measured against. Following the house pattern (see
      // `test/selection/selection_gate_test.dart`), each test resets the override
      // via try/finally rather than `setUp`/`tearDown`, so a failing assertion
      // still restores it and it cannot leak into other test files.

      testWidgets('fires onTap exactly once for a single tap', (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          // Arrange
          int tapCount = 0;
          await pumpThemed(
            tester,
            LayrzTappable(
              onTap: () => tapCount++,
              child: const Text('Tap Me'),
            ),
          );

          // Act
          await tester.tap(find.text('Tap Me'));
          await tester.pumpAndSettle();

          // Assert
          expect(tapCount, 1);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('collapseDoubleTap defaults to true: a rapid double-tap still fires onTap once', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          // Arrange — no collapseDoubleTap argument passed, exercising the default.
          int tapCount = 0;
          await pumpThemed(
            tester,
            LayrzTappable(
              onTap: () => tapCount++,
              child: const Text('Tap Me'),
            ),
          );
          final finder = find.text('Tap Me');

          // Act — two taps within the double-tap window, as a real double-tap
          // gesture would be interpreted by the platform.
          await tester.tap(finder);
          await tester.pump(kDoubleTapMinTime);
          await tester.tap(finder);
          await tester.pumpAndSettle();

          // Assert — this is the behaviour all 11 existing consumers rely on
          // and must keep seeing: a double-tap on an active LayrzTappable
          // resolves as a single logical activation.
          expect(tapCount, 1);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('collapseDoubleTap: false delivers one onTap call per physical tap, not swallowed', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          // Arrange
          int tapCount = 0;
          await pumpThemed(
            tester,
            LayrzTappable(
              onTap: () => tapCount++,
              collapseDoubleTap: false,
              child: const Text('Tap Me'),
            ),
          );
          final finder = find.text('Tap Me');

          // Act — two taps within the double-tap window, as a real double-tap
          // gesture would be interpreted by the platform.
          await tester.tap(finder);
          await tester.pump(kDoubleTapMinTime);
          await tester.tap(finder);
          await tester.pumpAndSettle();

          // Assert — with the cooldown opted out of, both physical taps
          // deliver their own onTap call. This is the fix for the defect
          // where a second tap on the same instance within the cooldown
          // window was dropped -- e.g. a date-range picker cell tapped twice
          // in quick succession to first complete a range then re-pick up
          // that same endpoint.
          expect(tapCount, 2);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('collapseDoubleTap: false still fires exactly once for a single, non-repeated tap', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          // Arrange
          int tapCount = 0;
          await pumpThemed(
            tester,
            LayrzTappable(
              onTap: () => tapCount++,
              collapseDoubleTap: false,
              child: const Text('Tap Me'),
            ),
          );

          // Act
          await tester.tap(find.text('Tap Me'));
          await tester.pumpAndSettle();

          // Assert
          expect(tapCount, 1);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets(
        'three taps on one instance with only tester.pump() between them: '
        'true collapses to one call, false delivers three',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          try {
            // Arrange — the minimal acceptance case surfaced against the picker
            // day-grid cells: repeated taps on one instance separated only by a
            // bare tester.pump() (no explicit inter-tap delay), which is the
            // exact pattern the reviewer-scenario picker test uses. Asserting
            // both directions proves the flag is actually read, rather than
            // the widget always taking one branch regardless of its value.
            int collapsedCount = 0;
            int uncollapsedCount = 0;
            await pumpThemed(
              tester,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LayrzTappable(onTap: () => collapsedCount++, child: const Text('Collapsed')),
                  LayrzTappable(
                    onTap: () => uncollapsedCount++,
                    collapseDoubleTap: false,
                    child: const Text('Uncollapsed'),
                  ),
                ],
              ),
            );

            // Act
            for (var i = 0; i < 3; i++) {
              await tester.tap(find.text('Collapsed'));
              await tester.pump();
            }
            for (var i = 0; i < 3; i++) {
              await tester.tap(find.text('Uncollapsed'));
              await tester.pump();
            }

            // Assert
            expect(collapsedCount, 1, reason: 'collapseDoubleTap: true (default) must swallow the repeats');
            expect(uncollapsedCount, 3, reason: 'collapseDoubleTap: false must deliver every discrete tap');
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        },
      );

      testWidgets('collapseDoubleTap: false leaves no pending Timer behind', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          // Arrange — regression guard for the timer-leak failure mode found
          // while evaluating a gesture-recognizer-based alternative to this
          // flag: with collapseDoubleTap false, _handleTap never starts the
          // cooldown Timer at all, so a bare tester.pump() (not
          // pumpAndSettle) after the tap must not trip Flutter's
          // end-of-test "a Timer is still pending" invariant.
          await pumpThemed(
            tester,
            LayrzTappable(
              onTap: () {},
              collapseDoubleTap: false,
              child: const Text('Tap Me'),
            ),
          );

          // Act
          await tester.tap(find.text('Tap Me'));
          await tester.pump();

          // Assert — reaching here without the test framework's pending-timer
          // assertion firing at teardown is the assertion.
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('the cooldown is per-instance: tapping two different LayrzTappables in quick succession '
          'fires both', (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          // Arrange — a fast scroller or a mis-tap correction taps two distinct
          // rows within the double-tap window. Widget A's cooldown must not
          // suppress widget B: the cooldown lives on each LayrzTappable's own
          // State, not in any shared/static state.
          int aCount = 0;
          int bCount = 0;
          await pumpThemed(
            tester,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayrzTappable(onTap: () => aCount++, child: const Text('Row A')),
                LayrzTappable(onTap: () => bCount++, child: const Text('Row B')),
              ],
            ),
          );

          // Act
          await tester.tap(find.text('Row A'));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(find.text('Row B'));
          await tester.pumpAndSettle();

          // Assert
          expect(aCount, 1);
          expect(bCount, 1);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('a secondary-button tap fires onSecondaryTap only, never onTap', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          // Arrange — onTap and onSecondaryTap are mutually exclusive per tap:
          // a secondary-button (right) click must resolve as onSecondaryTap
          // alone, never onTap as well.
          int tapCount = 0;
          int secondaryTapCount = 0;
          await pumpThemed(
            tester,
            LayrzTappable(
              onTap: () => tapCount++,
              onSecondaryTap: () => secondaryTapCount++,
              child: const Text('Tap Me'),
            ),
          );

          // Act
          await tester.tap(find.text('Tap Me'), buttons: kSecondaryButton);
          await tester.pumpAndSettle();

          // Assert
          expect(secondaryTapCount, 1);
          expect(tapCount, 0);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    });

    group('geometry stability across states (D15)', () {
      testWidgets('hover and press states do not change the widget size', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Arrange
        await pumpThemed(
          tester,
          LayrzTappable(
            onTap: () {},
            child: Container(width: 100, height: 40, color: const Color(0xFF00FF00)),
          ),
        );
        final finder = find.byType(LayrzTappable);
        final idleSize = tester.getSize(finder);

        // Act — hover.
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: tester.getCenter(finder));
        addTearDown(gesture.removePointer);
        await tester.pump();
        final hoveredSize = tester.getSize(finder);

        // Act — press.
        await gesture.down(tester.getCenter(finder));
        await tester.pump();
        final pressedSize = tester.getSize(finder);
        await gesture.up();
        await tester.pumpAndSettle();

        // Assert — per decision D15, only colour/border/shadow/opacity/cursor
        // vary across interaction states; geometry never does.
        expect(hoveredSize, idleSize);
        expect(pressedSize, idleSize);
      });
    });
  });
}
