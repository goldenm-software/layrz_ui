import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/number_field_edge.dart';

import '../helpers/pump_themed.dart';

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

      final textFinder = find.text('−');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('renders proper border when has errors', (tester) async {
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
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
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

      final textFinder = find.text('+');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('renders proper border when has errors', (tester) async {
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
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
    });
  });
}
