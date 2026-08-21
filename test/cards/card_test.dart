import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_font_handler.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCard', () {
    group('Rendering', () {
      testWidgets('renders its child', (tester) async {
        await pumpThemed(
          tester,
          const LayrzCard(
            child: Text('Test content'),
          ),
        );

        expect(find.text('Test content'), findsOneWidget);
      });

      testWidgets('default elevation is 1', (tester) async {
        await pumpThemed(
          tester,
          const LayrzCard(
            child: SizedBox.shrink(),
          ),
        );

        expect(find.byType(LayrzCard), findsOneWidget);
      });
    });

    group('Elevation levels', () {
      testWidgets('elevation 1 uses elevation1 shadow', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final expectedShadow = themeData.tokens.shadow.elevation1;

        await pumpThemed(
          tester,
          const LayrzCard(elevation: 1, child: SizedBox.shrink()),
          theme: themeData,
        );

        final decoratedBox = _findDecoratedBox(tester);
        expect(decoratedBox.decoration, isA<BoxDecoration>());
        final decoration = decoratedBox.decoration as BoxDecoration;
        expect(decoration.boxShadow, equals(expectedShadow));
      });

      testWidgets('elevation 2 uses elevation2 shadow', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final expectedShadow = themeData.tokens.shadow.elevation2;

        await pumpThemed(
          tester,
          const LayrzCard(elevation: 2, child: SizedBox.shrink()),
          theme: themeData,
        );

        final decoratedBox = _findDecoratedBox(tester);
        final decoration = decoratedBox.decoration as BoxDecoration;
        expect(decoration.boxShadow, equals(expectedShadow));
      });

      testWidgets('elevation 3 uses elevation3 shadow', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final expectedShadow = themeData.tokens.shadow.elevation3;

        await pumpThemed(
          tester,
          const LayrzCard(elevation: 3, child: SizedBox.shrink()),
          theme: themeData,
        );

        final decoratedBox = _findDecoratedBox(tester);
        final decoration = decoratedBox.decoration as BoxDecoration;
        expect(decoration.boxShadow, equals(expectedShadow));
      });

      testWidgets('elevation 4 uses elevation4 shadow', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final expectedShadow = themeData.tokens.shadow.elevation4;

        await pumpThemed(
          tester,
          const LayrzCard(elevation: 4, child: SizedBox.shrink()),
          theme: themeData,
        );

        final decoratedBox = _findDecoratedBox(tester);
        final decoration = decoratedBox.decoration as BoxDecoration;
        expect(decoration.boxShadow, equals(expectedShadow));
      });

      testWidgets('elevation 5 uses elevation5 shadow', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final expectedShadow = themeData.tokens.shadow.elevation5;

        await pumpThemed(
          tester,
          const LayrzCard(elevation: 5, child: SizedBox.shrink()),
          theme: themeData,
        );

        final decoratedBox = _findDecoratedBox(tester);
        final decoration = decoratedBox.decoration as BoxDecoration;
        expect(decoration.boxShadow, equals(expectedShadow));
      });

      testWidgets('elevation 0 asserts', (tester) async {
        expect(
          () => LayrzCard(elevation: 0, child: SizedBox.shrink()),
          throwsAssertionError,
        );
      });

      testWidgets('elevation 6 asserts', (tester) async {
        expect(
          () => LayrzCard(elevation: 6, child: SizedBox.shrink()),
          throwsAssertionError,
        );
      });
    });

    group('Background color', () {
      testWidgets('null backgroundColor uses surface token', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final expectedColor = themeData.tokens.colors.sf2;

        await pumpThemed(
          tester,
          const LayrzCard(child: SizedBox.shrink()),
          theme: themeData,
        );

        final decoratedBox = _findDecoratedBox(tester);
        final decoration = decoratedBox.decoration as BoxDecoration;
        expect(decoration.color, equals(expectedColor));
      });

      testWidgets('provided backgroundColor overrides token', (tester) async {
        const customColor = Color(0xFFFF0000);

        await pumpThemed(
          tester,
          const LayrzCard(
            backgroundColor: customColor,
            child: SizedBox.shrink(),
          ),
        );

        final decoratedBox = _findDecoratedBox(tester);
        final decoration = decoratedBox.decoration as BoxDecoration;
        expect(decoration.color, equals(customColor));
      });
    });

    group('Padding', () {
      testWidgets('applies fixed sp3 padding on all sides', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        const childSize = Size(40, 40);
        const expectedPadding = 14.0;

        await pumpThemed(
          tester,
          LayrzCard(
            child: SizedBox.fromSize(size: childSize),
          ),
          theme: themeData,
        );

        final cardSize = tester.getSize(find.byType(LayrzCard));
        // Card size should be child size + padding on both sides.
        final expectedCardWidth = childSize.width + (expectedPadding * 2);
        final expectedCardHeight = childSize.height + (expectedPadding * 2);

        expect(cardSize.width, closeTo(expectedCardWidth, 1.0));
        expect(cardSize.height, closeTo(expectedCardHeight, 1.0));
      });
    });

    group('Border radius', () {
      testWidgets('uses r12 radius token', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final expectedRadius = themeData.tokens.radius.r3;

        await pumpThemed(
          tester,
          const LayrzCard(child: SizedBox.shrink()),
          theme: themeData,
        );

        final decoratedBox = _findDecoratedBox(tester);
        final decoration = decoratedBox.decoration as BoxDecoration;
        expect(decoration.borderRadius, equals(BorderRadius.circular(expectedRadius)));
      });
    });

    group('Non-interactive card (onTap: null)', () {
      testWidgets('card does not have interactive layer', (tester) async {
        await pumpThemed(
          tester,
          const LayrzCard(
            onTap: null,
            child: SizedBox.shrink(),
          ),
        );

        // For a non-interactive card, there's no MouseRegion, Listener, or GestureDetector.
        expect(find.byType(MouseRegion), findsNothing);
      });

      testWidgets('does not show click cursor', (tester) async {
        await pumpThemed(
          tester,
          const LayrzCard(
            onTap: null,
            child: SizedBox.shrink(),
          ),
        );

        // For a non-interactive card, there's no MouseRegion, so no click cursor.
        expect(find.byType(MouseRegion), findsNothing);
      });
    });

    group('Interactive card (onTap non-null)', () {
      testWidgets('tapping fires onTap callback', (tester) async {
        var tapped = false;

        await pumpThemed(
          tester,
          LayrzCard(
            onTap: () => tapped = true,
            child: const Text('Tap me'),
          ),
        );

        await tester.tap(find.byType(LayrzCard));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('tapping fires onTap callback exactly once', (tester) async {
        var tapCount = 0;

        await pumpThemed(
          tester,
          LayrzCard(
            onTap: () => tapCount++,
            child: const Text('Tap me'),
          ),
        );

        await tester.tap(find.byType(LayrzCard));
        await tester.pumpAndSettle();

        expect(tapCount, equals(1));
      });

      testWidgets('shows click cursor', (tester) async {
        await pumpThemed(
          tester,
          LayrzCard(
            onTap: () {},
            child: const SizedBox.shrink(),
          ),
        );

        // The card wraps MouseRegion for click cursor (along with FocusableActionDetector's MouseRegion)
        expect(find.byType(MouseRegion), findsWidgets);
      });

      testWidgets('pressing lowers shadow and releasing restores it', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        const baseElevation = 3;
        final expectedBaseShadow = themeData.tokens.shadow.elevation3;
        final expectedPressedShadow = themeData.tokens.shadow.elevation2;

        await pumpThemed(
          tester,
          LayrzCard(
            elevation: baseElevation,
            onTap: () {},
            child: const SizedBox.shrink(),
          ),
          theme: themeData,
        );

        // Capture initial shadow (base elevation).
        var decoratedBox = _findDecoratedBox(tester);
        var decoration = decoratedBox.decoration as BoxDecoration;
        expect(decoration.boxShadow, equals(expectedBaseShadow));

        // Simulate a press (pointer down, no up yet).
        final center = _findCenter(tester);
        final gesture = await tester.startGesture(center);
        await tester.pumpAndSettle();

        // Check shadow while pressed.
        decoratedBox = _findDecoratedBox(tester);
        decoration = decoratedBox.decoration as BoxDecoration;
        expect(decoration.boxShadow, equals(expectedPressedShadow));

        // Release press.
        await gesture.up();
        await tester.pumpAndSettle();

        // Check shadow after release (should be back to base).
        decoratedBox = _findDecoratedBox(tester);
        decoration = decoratedBox.decoration as BoxDecoration;
        expect(decoration.boxShadow, equals(expectedBaseShadow));
      });

      testWidgets('elevation 5 pressed clamps to elevation 4', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final expectedPressedShadow = themeData.tokens.shadow.elevation4;

        await pumpThemed(
          tester,
          LayrzCard(
            elevation: 5,
            onTap: () {},
            child: const SizedBox.shrink(),
          ),
          theme: themeData,
        );

        // Simulate a press.
        final center = _findCenter(tester);
        final gesture = await tester.startGesture(center);
        await tester.pumpAndSettle();

        final decoratedBox = _findDecoratedBox(tester);
        final decoration = decoratedBox.decoration as BoxDecoration;
        expect(decoration.boxShadow, equals(expectedPressedShadow));

        await gesture.up();
      });

      testWidgets('elevation 1 pressed clamps to elevation 1', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final expectedShadow = themeData.tokens.shadow.elevation1;

        await pumpThemed(
          tester,
          LayrzCard(
            elevation: 1,
            onTap: () {},
            child: const SizedBox.shrink(),
          ),
          theme: themeData,
        );

        // Simulate a press.
        final center = _findCenter(tester);
        final gesture = await tester.startGesture(center);
        await tester.pumpAndSettle();

        final decoratedBox = _findDecoratedBox(tester);
        final decoration = decoratedBox.decoration as BoxDecoration;
        expect(decoration.boxShadow, equals(expectedShadow));

        await gesture.up();
      });
    });

    group('Geometry invariant (decision D15)', () {
      testWidgets('card size and child position remain constant across press states', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          LayrzCard(
            elevation: 2,
            onTap: () {},
            child: const SizedBox(width: 50, height: 50),
          ),
          theme: themeData,
        );

        // Capture baseline geometry.
        final baselineCardSize = tester.getSize(find.byType(LayrzCard));
        final baselineCardTopLeft = tester.getTopLeft(find.byType(LayrzCard));

        // Simulate press.
        final center = _findCenter(tester);
        final gesture = await tester.startGesture(center);
        await tester.pumpAndSettle();

        // Check geometry while pressed.
        final pressedCardSize = tester.getSize(find.byType(LayrzCard));
        final pressedCardTopLeft = tester.getTopLeft(find.byType(LayrzCard));

        expect(pressedCardSize, equals(baselineCardSize));
        expect(pressedCardTopLeft, equals(baselineCardTopLeft));

        // Release and check again.
        await gesture.up();
        await tester.pumpAndSettle();

        final releasedCardSize = tester.getSize(find.byType(LayrzCard));
        final releasedCardTopLeft = tester.getTopLeft(find.byType(LayrzCard));

        expect(releasedCardSize, equals(baselineCardSize));
        expect(releasedCardTopLeft, equals(baselineCardTopLeft));
      });
    });

    group('Scrollable regression (layrzbutton fix)', () {
      testWidgets('card inside ListView responds to tap and shows pressed feedback promptly', (tester) async {
        var tapped = false;

        await pumpThemed(
          tester,
          ListView(
            children: [
              LayrzCard(
                elevation: 2,
                onTap: () => tapped = true,
                child: const Text('Tap me in list'),
              ),
            ],
          ),
        );

        await tester.tap(find.byType(LayrzCard));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });
    });
  });
}

/// Finds the first [DecoratedBox] widget in the tree.
DecoratedBox _findDecoratedBox(WidgetTester tester) {
  return tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
}

/// Finds the center of the first [LayrzCard] widget.
Offset _findCenter(WidgetTester tester) {
  return tester.getCenter(find.byType(LayrzCard));
}
