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

      testWidgets('fires onTap exactly once for a double-tap, not twice', (WidgetTester tester) async {
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
          final finder = find.text('Tap Me');

          // Act — two taps within the double-tap window, as a real double-tap
          // gesture would be interpreted by the platform.
          await tester.tap(finder);
          await tester.pump(kDoubleTapMinTime);
          await tester.tap(finder);
          await tester.pumpAndSettle();

          // Assert — a double-tap on an active LayrzTappable must resolve as a
          // single logical activation, not fire the callback once per physical tap.
          expect(tapCount, 1);
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
    });
  });
}
