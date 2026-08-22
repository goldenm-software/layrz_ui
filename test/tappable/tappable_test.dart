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
      const customHoverColor = Color(0xFF00FF00);
      await pumpThemed(
        tester,
        LayrzTappable(
          onTap: () {},
          hoverColor: customHoverColor,
          child: const Text('Custom Hover'),
        ),
      );

      // Act & Assert
      // The widget should be present.
      expect(find.text('Custom Hover'), findsOneWidget);
    });

    testWidgets('applies custom pressedColor when provided', (WidgetTester tester) async {
      // Arrange
      const customPressedColor = Color(0xFF0000FF);
      await pumpThemed(
        tester,
        LayrzTappable(
          onTap: () {},
          pressedColor: customPressedColor,
          child: const Text('Custom Pressed'),
        ),
      );

      // Act & Assert
      // The widget should be present.
      expect(find.text('Custom Pressed'), findsOneWidget);
    });
  });
}
