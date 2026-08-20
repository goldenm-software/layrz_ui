import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTooltip scroll behavior', () {
    testWidgets(
      'tooltip is correctly positioned when opened while already scrolled (tight tolerance)',
      (tester) async {
        final scrollController = ScrollController();
        const anchorKey = Key('tooltip_anchor');

        // Build the test tree without pumpThemed
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: LayrzTheme(
              data: LayrzThemeData.light(),
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) {
                      return SizedBox(
                        height: 400,
                        child: CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            SliverList(
                              delegate: SliverChildListDelegate([
                                Container(height: 500),
                                LayrzTooltip(
                                  contentText: 'Tooltip text',
                                  child: SizedBox(
                                    key: anchorKey,
                                    width: 50,
                                    height: 50,
                                    child: Container(
                                      color: const Color(0xFF0000FF),
                                    ),
                                  ),
                                ),
                                Container(height: 500),
                              ]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        // Scroll down so the anchor is visible
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();

        // VERIFY SCROLL OCCURRED
        expect(
          scrollController.offset,
          greaterThan(0.0),
          reason: 'Scroll did not occur. Scroll position: ${scrollController.offset}',
        );

        // Long-press while already scrolled
        await tester.longPress(find.byKey(anchorKey));
        await tester.pumpAndSettle();

        // Verify tooltip is visible
        expect(find.text('Tooltip text'), findsWidgets);

        // Get the rects
        final tooltipRect = tester.getRect(find.text('Tooltip text'));
        final anchorRect = tester.getRect(find.byKey(anchorKey));

        // TIGHT TOLERANCE: tooltip surface should be kLayrzTooltipOffset below the anchor
        // Note: tooltipRect is the Text widget's bounds, not the entire Surface container.
        // The Surface has 6px top padding (sp6), so we need to subtract that to get the
        // actual surface position.
        const surfaceTopPadding = 6.0;
        final tooltipSurfaceTop = tooltipRect.top - surfaceTopPadding;
        final expectedVerticalOffset = kLayrzTooltipOffset;
        final actualVerticalOffset = tooltipSurfaceTop - anchorRect.bottom;


        // Check vertical positioning: tooltip surface should be kLayrzTooltipOffset below anchor
        expect(
          actualVerticalOffset,
          closeTo(expectedVerticalOffset, 1.0),
          reason:
              'Tooltip surface should be positioned ${expectedVerticalOffset}px below anchor. '
              'Actual offset: ${actualVerticalOffset.toStringAsFixed(1)}px. '
              'Anchor bottom: ${anchorRect.bottom}, Tooltip surface top: $tooltipSurfaceTop',
        );

        // Check horizontal centering: tooltip should be centered on anchor
        final horizontalDistance = (tooltipRect.center.dx - anchorRect.center.dx).abs();
        expect(
          horizontalDistance,
          lessThan(5.0),
          reason:
              'Tooltip should be horizontally centered on anchor within 5px. '
              'Actual distance: ${horizontalDistance.toStringAsFixed(1)}px.',
        );
      },
    );

    testWidgets('no exception thrown when scrollable disposed with tooltip open', (tester) async {
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

      // Long-press the tooltip to open it
      await tester.longPress(find.byType(SizedBox));
      await tester.pumpAndSettle();

      // Verify tooltip is open
      expect(find.text('Tooltip'), findsWidgets);

      // Remove the scrollable widget by tapping the container
      await tester.tap(find.text('Remove Scrollable'));
      await tester.pumpAndSettle();

      // No exception should be thrown during disposal
      expect(tester.takeException(), isNull);
    });

    testWidgets('tooltip without scrollable ancestor stays open without error', (tester) async {
      await pumpThemed(
        tester,
        LayrzTooltip(
          contentText: 'Tooltip text',
          child: SizedBox(width: 50, height: 50),
        ),
      );

      // Long-press to open the tooltip
      await tester.longPress(find.byType(SizedBox));
      await tester.pumpAndSettle();

      // Tooltip should be visible
      expect(find.text('Tooltip text'), findsWidgets);

      // No exception should occur
      expect(tester.takeException(), isNull);
    });
  });
}
