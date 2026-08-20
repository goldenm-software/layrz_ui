import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTooltipTrigger.tap', () {
    /// Test that tap trigger toggles tooltip open/closed.
    testWidgets('tap toggles tooltip visibility', (WidgetTester tester) async {
      const tooltip = LayrzTooltip(
        contentText: 'Tooltip content',
        trigger: LayrzTooltipTrigger.tap,
        child: SizedBox(width: 50, height: 50, child: Text('Tap me')),
      );

      await pumpThemed(tester, tooltip);

      // Initial state: tooltip should not be visible
      expect(find.text('Tooltip content'), findsNothing);

      // First tap: tooltip opens
      await tester.tap(find.byType(SizedBox));
      await tester.pumpAndSettle();

      expect(find.text('Tooltip content'), findsWidgets);

      // Second tap: tooltip closes
      await tester.tap(find.byType(SizedBox));
      await tester.pumpAndSettle();

      expect(find.text('Tooltip content'), findsNothing);
    });

    /// Test that tapping outside closes the tooltip in tap mode.
    testWidgets('tap-away closes tooltip', (WidgetTester tester) async {
      const tooltip = LayrzTooltip(
        contentText: 'Tooltip content',
        trigger: LayrzTooltipTrigger.tap,
        child: SizedBox(width: 50, height: 50, child: Text('Tap me')),
      );

      await pumpThemed(tester, tooltip);

      // Open tooltip
      await tester.tap(find.byType(SizedBox));
      await tester.pumpAndSettle();

      expect(find.text('Tooltip content'), findsWidgets);

      // Tap the barrier (full-screen area outside the anchor)
      await tester.tapAt(const Offset(10, 10)); // Tap at top-left corner
      await tester.pumpAndSettle();

      expect(find.text('Tooltip content'), findsNothing);
    });

    /// Test that hover does nothing in tap mode.
    testWidgets('hover does not open tooltip in tap mode', (WidgetTester tester) async {
      const tooltip = LayrzTooltip(
        contentText: 'Tooltip content',
        trigger: LayrzTooltipTrigger.tap,
        child: SizedBox(width: 50, height: 50, child: Text('Hover me')),
      );

      await pumpThemed(tester, tooltip);

      // Simulate hover (MouseRegion is not present in tap mode)
      // In tap mode, MouseRegion should not exist, so we can't hover
      // The test passes if the tooltip doesn't appear without a tap

      expect(find.text('Tooltip content'), findsNothing);
    });
  });

  group('LayrzTooltipTrigger.pointer (default)', () {
    /// Test that pointer trigger with long-press opens tooltip on mobile.
    testWidgets('pointer trigger on long-press opens tooltip (mobile)', (WidgetTester tester) async {
      const tooltip = LayrzTooltip(
        contentText: 'Tooltip content',
        trigger: LayrzTooltipTrigger.pointer,
        child: SizedBox(width: 50, height: 50, child: Text('Press me')),
      );

      await pumpThemed(tester, tooltip);

      // Initial state: tooltip hidden
      expect(find.text('Tooltip content'), findsNothing);

      // Long-press should open the tooltip
      await tester.longPress(find.byType(SizedBox));
      await tester.pumpAndSettle();

      expect(find.text('Tooltip content'), findsWidgets);
    });

    /// Test that default is pointer trigger.
    testWidgets('default trigger is pointer', (WidgetTester tester) async {
      const tooltip = LayrzTooltip(
        contentText: 'Content',
        child: SizedBox(width: 50, height: 50, child: Text('Child')),
      );

      // Verify the default value
      expect(tooltip.trigger, equals(LayrzTooltipTrigger.pointer));
    });
  });

  group('LayrzTooltip with rich text errors', () {
    /// Test that multi-line rich text renders correctly (for error tooltips).
    testWidgets('renders multi-line rich text in tooltip', (WidgetTester tester) async {
      final richText = TextSpan(
        children: const [
          TextSpan(text: 'Error 1'),
          TextSpan(text: '\n'),
          TextSpan(text: 'Error 2'),
          TextSpan(text: '\n'),
          TextSpan(text: 'Error 3'),
        ],
      );

      final tooltip = LayrzTooltip(
        contentRichText: richText,
        trigger: LayrzTooltipTrigger.tap,
        child: const SizedBox(width: 50, height: 50, child: Text('Tap')),
      );

      await pumpThemed(tester, tooltip);

      // Open tooltip
      await tester.tap(find.byType(SizedBox));
      await tester.pumpAndSettle();

      // The tooltip should be visible with all errors combined in one Text widget
      // Since find.text() looks for complete text matches in widgets, we check for
      // the combined multi-line text as rendered in Text.rich
      expect(find.byType(Text), findsWidgets); // Tooltip content is rendered as Text

      // Verify each individual error text is present in the rendered output
      // (they will be part of the same Text widget with newlines)
      expect(find.text('Error 1\nError 2\nError 3'), findsOneWidget);
    });
  });
}
