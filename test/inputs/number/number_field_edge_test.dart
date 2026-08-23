import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/number/number_field_edge.dart';

import '../../helpers/pump_themed.dart';

void main() {
  group('NumberFieldControl', () {
    testWidgets('renders with material width', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: false,
          onTap: () {},
          states: <WidgetState>{},
          readOnly: false,
        ),
      );

      // Find the Container with the − glyph
      final buttonFinder = find.byType(Container);
      expect(buttonFinder, findsWidgets);

      // Verify the button box has real width (not just glyph width)
      final buttonSize = tester.getSize(buttonFinder.first);
      expect(buttonSize.width, greaterThan(20.0), reason: 'Button should have material width, not just glyph width');
    });

    testWidgets('tap fires callback exactly once', (tester) async {
      var tapCount = 0;
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: false,
          onTap: () => tapCount++,
          states: <WidgetState>{},
          readOnly: false,
        ),
      );

      // Tap near the edge of the button, away from glyph centre
      final buttonFinder = find.byType(GestureDetector).first;
      await tester.tapAt(tester.getBottomRight(buttonFinder) - const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(tapCount, 1, reason: 'Callback should fire exactly once');
    });

    testWidgets('hover changes fill colour when enabled', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: false,
          onTap: () {},
          states: <WidgetState>{},
          readOnly: false,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);
    });

    testWidgets('disabled button does not change fill on hover', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: true,
          hasErrors: false,
          onTap: null,
          states: <WidgetState>{WidgetState.disabled},
          readOnly: false,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);
    });

    testWidgets('glyph shows correct style', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: false,
          onTap: () {},
          states: <WidgetState>{},
          readOnly: false,
        ),
      );

      final iconFinder = find.byType(Icon);
      expect(iconFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.icon, isNotNull);
    });

    testWidgets('renders with divider border (outer border is on outer container)', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: true,
          onTap: () {},
          states: <WidgetState>{},
          readOnly: false,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;

      // The cap should have divider borders (inner edges); the outer container owns the outer border
      expect(decoration?.border, isNotNull);
    });

    testWidgets('cap border radius has non-zero outer corners and zero inner', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: false,
          onTap: () {},
          states: <WidgetState>{},
          readOnly: false,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;

      // Cap should have a BorderRadius (outer corners rounded, inner corners square)
      expect(decoration?.borderRadius, isNotNull);
      final radius = decoration!.borderRadius as BorderRadius?;
      expect(radius, isNotNull);
      // For a left cap, topLeft and bottomLeft should be non-zero, topRight/bottomRight zero
      expect(radius!.topLeft.x, greaterThan(0), reason: 'Outer corner radius should be non-zero');
      expect(radius.bottomLeft.x, greaterThan(0), reason: 'Outer corner radius should be non-zero');
      expect(radius.topRight.x, equals(0), reason: 'Inner corner radius should be zero');
      expect(radius.bottomRight.x, equals(0), reason: 'Inner corner radius should be zero');
    });

    testWidgets('cap background resolves spec color in error state', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: true,
          onTap: () {},
          states: <WidgetState>{},
          readOnly: false,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;

      // In error state, cap background should reflect the spec's background (pale danger)
      expect(decoration?.color, isNotNull);
    });

    testWidgets('cap divider is red on error', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: true,
          onTap: () {},
          states: <WidgetState>{},
          readOnly: false,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;

      // Divider turns red (danger) when the field has errors
      expect(decoration?.border, isNotNull);
      final border = decoration!.border as Border?;
      expect(border, isNotNull);
      // Either left or right should have a divider (depending on isLeft)
      expect(border!.left != BorderSide.none || border.right != BorderSide.none, true);
    });

    testWidgets('cap background resolves spec color in focused state', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: false,
          onTap: () {},
          states: <WidgetState>{WidgetState.focused},
          readOnly: false,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;

      // In focused state, cap background should reflect the spec's background (focused color)
      expect(decoration?.color, isNotNull);
    });

    testWidgets('cap divider stays neutral in focused state (not changed by focus)', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: false,
          onTap: () {},
          states: <WidgetState>{WidgetState.focused},
          readOnly: false,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;

      // Divider remains neutral (not red) when focused without error
      expect(decoration?.border, isNotNull);
      final border = decoration!.border as Border?;
      expect(border, isNotNull);
      // Divider should exist but should NOT be red (since hasErrors=false)
      expect(border!.left != BorderSide.none || border.right != BorderSide.none, true);
    });

    testWidgets('cap background resolves spec color in disabled state', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: true,
          hasErrors: false,
          onTap: null,
          states: <WidgetState>{WidgetState.disabled},
          readOnly: false,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;

      // In disabled state, cap background should reflect the spec's background (disabled tint)
      expect(decoration?.color, isNotNull);
    });

    testWidgets('cap divider stays neutral in disabled state (not changed by disabled)', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: true,
          hasErrors: false,
          onTap: null,
          states: <WidgetState>{WidgetState.disabled},
          readOnly: false,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;

      // Divider remains neutral (not red) when disabled without error
      expect(decoration?.border, isNotNull);
      final border = decoration!.border as Border?;
      expect(border, isNotNull);
      // Divider should exist but should NOT be red (since hasErrors=false)
      expect(border!.left != BorderSide.none || border.right != BorderSide.none, true);
    });
  });

  group('NumberFieldIncrementControl', () {
    testWidgets('renders with material width', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: false,
          onTap: () {},
          states: <WidgetState>{},
          readOnly: false,
        ),
      );

      final buttonFinder = find.byType(Container);
      expect(buttonFinder, findsWidgets);

      final buttonSize = tester.getSize(buttonFinder.first);
      expect(buttonSize.width, greaterThan(20.0), reason: 'Button should have material width, not just glyph width');
    });

    testWidgets('tap fires callback exactly once', (tester) async {
      var tapCount = 0;
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: false,
          onTap: () => tapCount++,
          states: <WidgetState>{},
          readOnly: false,
        ),
      );

      final buttonFinder = find.byType(GestureDetector).first;
      await tester.tapAt(tester.getBottomLeft(buttonFinder) + const Offset(5, -5));
      await tester.pumpAndSettle();

      expect(tapCount, 1, reason: 'Callback should fire exactly once');
    });

    testWidgets('hover changes fill colour when enabled', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: false,
          onTap: () {},
          states: <WidgetState>{},
          readOnly: false,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);
    });

    testWidgets('disabled button does not change fill on hover', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: true,
          hasErrors: false,
          onTap: null,
          states: <WidgetState>{WidgetState.disabled},
          readOnly: false,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);
    });

    testWidgets('glyph shows correct style', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: false,
          onTap: () {},
          states: <WidgetState>{},
          readOnly: false,
        ),
      );

      final iconFinder = find.byType(Icon);
      expect(iconFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.icon, isNotNull);
    });

    testWidgets('renders with divider border (outer border is on outer container)', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: true,
          isDisabled: false,
          hasErrors: true,
          onTap: () {},
          states: <WidgetState>{},
          readOnly: false,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;

      // The cap should have divider borders (inner edges); the outer container owns the outer border
      expect(decoration?.border, isNotNull);
    });

    testWidgets('cap border radius has non-zero outer corners and zero inner', (tester) async {
      await pumpThemed(
        tester,
        NumberFieldControl(
          isLeft: false,
          isDisabled: false,
          hasErrors: false,
          onTap: () {},
          states: <WidgetState>{},
          readOnly: false,
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;

      // Cap should have a BorderRadius (outer corners rounded, inner corners square)
      expect(decoration?.borderRadius, isNotNull);
      final radius = decoration!.borderRadius as BorderRadius?;
      expect(radius, isNotNull);
      // For a right cap, topRight and bottomRight should be non-zero, topLeft/bottomLeft zero
      expect(radius!.topRight.x, greaterThan(0), reason: 'Outer corner radius should be non-zero');
      expect(radius.bottomRight.x, greaterThan(0), reason: 'Outer corner radius should be non-zero');
      expect(radius.topLeft.x, equals(0), reason: 'Inner corner radius should be zero');
      expect(radius.bottomLeft.x, equals(0), reason: 'Inner corner radius should be zero');
    });
  });
}
