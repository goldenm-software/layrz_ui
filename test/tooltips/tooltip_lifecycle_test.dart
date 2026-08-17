import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTooltip lifecycle', () {
    testWidgets(
      'Disposing a tooltip widget while visible does not crash',
      (tester) async {
        /// Regression test for dispose-order bugs when a tooltip manages state.
        /// If the tooltip's state disposes the animation controller before safely
        /// removing the overlay entry, the entry's rebuild tries to read a disposed
        /// animation, causing a crash.
        ///
        /// This test pumps a tooltip, shows it via long-press, then removes the entire
        /// widget tree while the tooltip is visible. It should NOT crash.

        final showTooltip = ValueNotifier<bool>(true);

        await pumpThemed(
          tester,
          ValueListenableBuilder(
            valueListenable: showTooltip,
            builder: (context, shouldShow, _) {
              if (!shouldShow) {
                return const SizedBox.shrink();
              }

              return Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => Center(
                      child: LayrzTooltip(
                        contentText: 'Test tooltip',
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: const Center(child: Text('Anchor')),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );

        // Trigger the tooltip by long-press
        await tester.longPress(find.text('Anchor'));
        await tester.pumpAndSettle();

        // Verify tooltip is showing
        expect(find.text('Test tooltip'), findsOneWidget);

        // Remove the entire widget while tooltip is visible - should not crash
        showTooltip.value = false;
        await tester.pumpAndSettle();

        // Verify no exception was thrown
        expect(tester.takeException(), isNull, reason: 'Disposing with visible tooltip should not crash');
      },
    );

    testWidgets(
      'Re-hovering before hide completes keeps tooltip visible',
      (tester) async {
        /// Regression test for show/hide race conditions in tooltip hide logic.
        ///
        /// If the tooltip's hide behavior uses a callback-based approach (e.g., .then()
        /// on an animation reverse), a re-entry during the hide animation could leave
        /// a pending removal callback that removes the entry even though it was
        /// re-shown. This test hovers in, hovers out (starting hide), then hovers back
        /// in before the hide delay elapses. The tooltip must remain visible.

        final anchorKey = GlobalKey();

        await pumpThemed(
          tester,
          Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Center(
                  child: LayrzTooltip(
                    contentText: 'Persistent tooltip',
                    child: SizedBox(
                      key: anchorKey,
                      width: 50,
                      height: 50,
                      child: const Center(child: Text('Anchor')),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        final anchorCenter = tester.getCenter(find.text('Anchor'));
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);

        // Step 1: Hover to show tooltip
        await mouse.moveTo(anchorCenter);
        await tester.pumpAndSettle();
        expect(find.text('Persistent tooltip'), findsOneWidget, reason: 'Tooltip should show on hover');

        // Step 2: Move mouse away to start hide (but don't wait for it to complete)
        await mouse.moveTo(const Offset(-100, -100));
        // Pump for 50ms (half the standard 100ms hide delay)
        await tester.pump(const Duration(milliseconds: 50));

        // Step 3: Move mouse back to anchor before hide completes
        await mouse.moveTo(anchorCenter);
        await tester.pumpAndSettle();

        // Step 4: Tooltip should still be visible (not removed by pending hide)
        expect(
          find.text('Persistent tooltip'),
          findsOneWidget,
          reason: 'Tooltip must remain visible after re-entering during hide',
        );
      },
    );

    testWidgets(
      'Tooltip dismisses completely on mouse exit',
      (tester) async {
        /// Critical dismissal regression test.
        ///
        /// The tooltip's hide timer (100ms) fires after the forward animation
        /// has completed. If _hideTooltip() only checks for AnimationStatus.forward,
        /// it will miss the call to reverse() and the overlay entry will leak forever.
        ///
        /// This test:
        /// 1. Hovers to show the tooltip (animation completes)
        /// 2. Moves away from the anchor (triggers 100ms hide timer)
        /// 3. Waits past the hide timer and the full reverse animation
        /// 4. Asserts that the tooltip is completely gone (findsNothing)

        final anchorKey = GlobalKey();

        await pumpThemed(
          tester,
          Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Center(
                  child: LayrzTooltip(
                    contentText: 'Disappearing tooltip',
                    child: SizedBox(
                      key: anchorKey,
                      width: 50,
                      height: 50,
                      child: const Center(child: Text('Anchor')),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        final anchorCenter = tester.getCenter(find.text('Anchor'));
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);

        // Step 1: Hover to show tooltip and let animation complete
        await mouse.moveTo(anchorCenter);
        await tester.pumpAndSettle();
        expect(find.text('Disappearing tooltip'), findsOneWidget, reason: 'Tooltip should be visible after hover');

        // Step 2: Move mouse far away to trigger hide delay
        await mouse.moveTo(const Offset(-200, -200));
        // Wait for 100ms hide delay + 80ms reverse animation + buffer for pumpAndSettle
        await tester.pumpAndSettle(const Duration(milliseconds: 300));

        // Step 3: Tooltip should be completely gone
        expect(
          find.text('Disappearing tooltip'),
          findsNothing,
          reason: 'Tooltip must be dismissed and removed from tree after mouse exit',
        );
      },
    );

    testWidgets(
      'No tooltip leak across multiple anchors',
      (tester) async {
        /// Critical multi-anchor regression test.
        ///
        /// If tooltips accumulate and never dismiss, hovering across multiple
        /// anchors will leave multiple surfaces on screen simultaneously.
        /// This is the symptom reported: "nine tooltips stayed on screen".
        ///
        /// This test:
        /// 1. Builds three LayrzTooltip widgets side by side
        /// 2. Hovers the first, then the second, then the third (pumping between)
        /// 3. Asserts at most ONE tooltip surface is visible at any time
        /// 4. After leaving all anchors, asserts ZERO tooltip surfaces remain

        await pumpThemed(
          tester,
          Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LayrzTooltip(
                      contentText: 'Tooltip 1',
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: const Center(child: Text('Anchor 1')),
                      ),
                    ),
                    const SizedBox(width: 50),
                    LayrzTooltip(
                      contentText: 'Tooltip 2',
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: const Center(child: Text('Anchor 2')),
                      ),
                    ),
                    const SizedBox(width: 50),
                    LayrzTooltip(
                      contentText: 'Tooltip 3',
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: const Center(child: Text('Anchor 3')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);

        // Hover each anchor in sequence
        for (int i = 1; i <= 3; i++) {
          final anchorCenter = tester.getCenter(find.text('Anchor $i'));
          await mouse.moveTo(anchorCenter);
          await tester.pumpAndSettle();

          // Count actual tooltip text nodes (not anchors)
          // Expect at most 1 tooltip visible when hovering a specific anchor
          final tooltipCount = find.byType(Text).evaluate().where((e) {
            final widget = e.widget;
            if (widget is! Text) return false;
            final text = widget.data;
            return text != null && text.startsWith('Tooltip');
          }).length;
          expect(tooltipCount <= 1, true, reason: 'At most 1 tooltip should be visible, got $tooltipCount');
        }

        // Move far away from all anchors
        await mouse.moveTo(const Offset(-500, -500));
        // Wait for hide delay + reverse animation + buffer for pumpAndSettle
        await tester.pumpAndSettle(const Duration(milliseconds: 300));

        // All tooltips should be gone - check that no "Tooltip N" text is on screen
        final remainingTooltips = find.byType(Text).evaluate().where((e) {
          final widget = e.widget;
          if (widget is! Text) return false;
          final text = widget.data;
          return text != null && text.startsWith('Tooltip');
        }).length;
        expect(
          remainingTooltips,
          0,
          reason: 'All tooltips must be dismissed when pointer is away from all anchors',
        );
      },
    );
  });
}
