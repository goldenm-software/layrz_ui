import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTooltip scroll behavior', () {
    testWidgets('tooltip follows anchor when page scrolls', (tester) async {
      // Create a scrollable list with a tooltip anchor inside.
      // The anchor is positioned near the top of the list.
      await pumpThemed(
        tester,
        Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      // Add some space at the top to make scrolling visible.
                      Container(height: 200),
                      LayrzTooltip(
                        contentText: 'Tooltip text',
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0000FF),
                            ),
                          ),
                        ),
                      ),
                      // Add space below so we can scroll.
                      Container(height: 500),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      // Long-press the tooltip anchor to open it.
      await tester.longPress(find.byType(SizedBox));
      await tester.pumpAndSettle();

      // Verify tooltip is visible.
      expect(find.text('Tooltip text'), findsWidgets);

      // Capture the tooltip's position before scrolling.
      final tooltipRectBefore = tester.getRect(find.text('Tooltip text'));
      final anchorRectBefore = tester.getRect(find.byType(SizedBox));

      // Scroll down the list.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
      await tester.pumpAndSettle();

      // Verify the tooltip still exists and is visible.
      expect(find.text('Tooltip text'), findsWidgets);

      // Capture the tooltip's position after scrolling.
      final tooltipRectAfter = tester.getRect(find.text('Tooltip text'));
      final anchorRectAfter = tester.getRect(find.byType(SizedBox));

      // Calculate the delta (how much things moved).
      final anchorDelta = anchorRectAfter.top - anchorRectBefore.top;
      final tooltipDelta = tooltipRectAfter.top - tooltipRectBefore.top;

      // The tooltip should have moved by approximately the same amount as the anchor.
      // We use a tolerance of 5 pixels to account for rounding and layout differences.
      expect(
        (tooltipDelta - anchorDelta).abs(),
        lessThan(5),
        reason:
            'Tooltip should follow anchor when scrolling. '
            'Anchor moved ${anchorDelta}px, tooltip moved ${tooltipDelta}px',
      );
    });

    testWidgets('tooltip is correctly positioned when opened while already scrolled', (tester) async {
      // Create a scrollable list.
      await pumpThemed(
        tester,
        CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                Container(height: 500),
                LayrzTooltip(
                  contentText: 'Tooltip text',
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0000FF),
                      ),
                    ),
                  ),
                ),
                Container(height: 500),
              ]),
            ),
          ],
        ),
      );

      // Scroll down so the anchor is in view.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Now long-press to open the tooltip while already scrolled.
      await tester.longPress(find.byType(SizedBox));
      await tester.pumpAndSettle();

      // Verify tooltip is visible.
      expect(find.text('Tooltip text'), findsWidgets);

      // Capture the positions of the tooltip and anchor.
      final tooltipRect = tester.getRect(find.text('Tooltip text'));
      final anchorRect = tester.getRect(find.byType(SizedBox));

      // The tooltip should be positioned relative to the anchor (usually below or above it).
      // It should not be far away from the anchor.
      final horizontalDistance = (tooltipRect.center.dx - anchorRect.center.dx).abs();
      final verticalDistance = (tooltipRect.top - anchorRect.bottom).abs();

      // Horizontal distance should be small (tooltip centred under/over anchor).
      expect(
        horizontalDistance,
        lessThan(100),
        reason: 'Tooltip should be horizontally centered on anchor',
      );

      // Vertical distance should be reasonable (tooltip offset from anchor).
      // Allow up to 50px offset plus tooltip height.
      expect(
        verticalDistance,
        lessThan(150),
        reason: 'Tooltip should be positioned close to anchor vertically',
      );
    });

    testWidgets('no exception thrown when scrollable disposed with tooltip open', (tester) async {
      // Create a widget that can be removed while the tooltip is open.
      bool shouldShowScrollable = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: LayrzTheme(
                data: LayrzThemeData.light(),
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (context) {
                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() => shouldShowScrollable = false);
                              },
                              child: Container(
                                color: const Color(0xFFCCCCCC),
                                padding: const EdgeInsets.all(16),
                                child: const Text('Remove Scrollable'),
                              ),
                            ),
                            if (shouldShowScrollable)
                              Expanded(
                                child: CustomScrollView(
                                  slivers: [
                                    SliverList(
                                      delegate: SliverChildListDelegate([
                                        LayrzTooltip(
                                          contentText: 'Tooltip',
                                          child: SizedBox(
                                            width: 50,
                                            height: 50,
                                          ),
                                        ),
                                        Container(height: 500),
                                      ]),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Long-press the tooltip to open it.
      await tester.longPress(find.byType(SizedBox));
      await tester.pumpAndSettle();

      // Verify tooltip is open.
      expect(find.text('Tooltip'), findsWidgets);

      // Remove the scrollable widget by tapping the container.
      await tester.tap(find.text('Remove Scrollable'));
      await tester.pumpAndSettle();

      // No exception should be thrown during disposal.
      expect(tester.takeException(), isNull);
    });

    testWidgets('tooltip without scrollable ancestor stays open without error', (tester) async {
      // Create a tooltip without an enclosing scrollable.
      await pumpThemed(
        tester,
        LayrzTooltip(
          contentText: 'Tooltip text',
          child: SizedBox(width: 50, height: 50),
        ),
      );

      // Long-press to open the tooltip.
      await tester.longPress(find.byType(SizedBox));
      await tester.pumpAndSettle();

      // Tooltip should be visible and stay in position.
      expect(find.text('Tooltip text'), findsWidgets);

      // No exception should occur.
      expect(tester.takeException(), isNull);
    });
  });
}
