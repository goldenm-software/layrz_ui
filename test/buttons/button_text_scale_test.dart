import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzButton text scale handling', () {
    /// Helper to pump a button with a specific text scale.
    Future<void> pumpButtonAtScale(
      WidgetTester tester,
      double scale, {
      bool withIcon = false,
    }) async {
      await pumpThemed(
        tester,
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: LayrzButton(
            labelText: 'Save Button',
            icon: withIcon ? const IconData(0xe045, fontFamily: 'MaterialIcons') : null,
            onTap: () {},
            type: LayrzButtonType.success,
            style: LayrzButtonStyle.elevated,
          ),
        ),
      );
      // Pump to settle.
      await tester.pump();
    }

    /// Helper to measure the actual rendered width of the RichText content.
    /// The RichText's actual width reflects the scaled text size.
    double getRichTextActualWidth(WidgetTester tester) {
      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsWidgets, reason: 'RichText should be rendered');

      // Measure the actual rendered size of the first RichText (button content).
      final richTextSize = tester.getSize(richTextFinder.first);
      return richTextSize.width;
    }

    /// Helper to extract border width from the button's decoration.
    double getBorderWidth(WidgetTester tester) {
      final containerFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      );
      for (int i = 0; i < containerFinder.evaluate().length; i++) {
        final widget = tester.widget<Container>(containerFinder.at(i));
        if (widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.border?.top.width ?? 0;
        }
      }
      return 0;
    }

    testWidgets(
      'button label at scale 1.0 fills available space without ellipsis',
      (tester) async {
        await pumpButtonAtScale(tester, 1.0);

        final buttonFinder = find.byType(LayrzButton);
        expect(buttonFinder, findsOneWidget);

        final buttonSize = tester.getSize(buttonFinder);
        final buttonWidth = buttonSize.width;

        final borderWidth = getBorderWidth(tester);

        // Expected available width for content = buttonWidth - borders - padding
        final buttonElement = buttonFinder.evaluate().first;
        final tokens = LayrzTheme.of(buttonElement).tokens;
        final expectedContentWidth = buttonWidth - (2 * borderWidth) - (2 * tokens.spacing.sp3);

        final richTextActualWidth = getRichTextActualWidth(tester);

        // At scale 1.0, the RichText width should match the available space.
        // Allow tolerance for rounding and alignment.
        expect(
          richTextActualWidth,
          closeTo(expectedContentWidth, 2.0),
          reason: 'At scale 1.0, RichText width should fill available space',
        );
      },
    );

    testWidgets(
      'button label at scale 1.3 fills available space (currently FAILS due to text scale mismatch)',
      (tester) async {
        await pumpButtonAtScale(tester, 1.3);

        final buttonFinder = find.byType(LayrzButton);
        expect(buttonFinder, findsOneWidget);

        final buttonSize = tester.getSize(buttonFinder);
        final buttonWidth = buttonSize.width;

        final borderWidth = getBorderWidth(tester);

        final buttonElement = buttonFinder.evaluate().first;
        final tokens = LayrzTheme.of(buttonElement).tokens;
        final expectedContentWidth = buttonWidth - (2 * borderWidth) - (2 * tokens.spacing.sp3);

        final richTextActualWidth = getRichTextActualWidth(tester);

        // At scale 1.3, the RichText should now honor text scale.
        // The width should match the available space.
        expect(
          richTextActualWidth,
          closeTo(expectedContentWidth, 2.0),
          reason: 'At scale 1.3, RichText width should fill available space',
        );
      },
    );

    testWidgets(
      'button label at scale 2.0 fills available space (currently FAILS due to text scale mismatch)',
      (tester) async {
        await pumpButtonAtScale(tester, 2.0);

        final buttonFinder = find.byType(LayrzButton);
        expect(buttonFinder, findsOneWidget);

        final buttonSize = tester.getSize(buttonFinder);
        final buttonWidth = buttonSize.width;

        final borderWidth = getBorderWidth(tester);

        final buttonElement = buttonFinder.evaluate().first;
        final tokens = LayrzTheme.of(buttonElement).tokens;
        final expectedContentWidth = buttonWidth - (2 * borderWidth) - (2 * tokens.spacing.sp3);

        final richTextActualWidth = getRichTextActualWidth(tester);

        // At scale 2.0, the RichText should now honor text scale.
        // The width should match the available space.
        expect(
          richTextActualWidth,
          closeTo(expectedContentWidth, 2.0),
          reason: 'At scale 2.0, RichText width should fill available space',
        );
      },
    );
  });
}
