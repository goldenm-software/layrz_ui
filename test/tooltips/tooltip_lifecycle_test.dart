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
        final anchorCenter = tester.getCenter(find.text('Anchor'));
        final gesture = await tester.startGesture(anchorCenter);
        await tester.pump(const Duration(milliseconds: 500)); // Hold for long-press
        expect(find.text('Test tooltip'), findsOneWidget, reason: 'Tooltip should be showing during long-press');
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 50)); // Small pump after release but before timer fires

        // Verify tooltip is still showing (100ms hide delay hasn't elapsed yet)
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

    testWidgets(
      'Tooltip dismisses on long-press release (DESIGN-77)',
      (tester) async {
        /// Regression test for touch-device tooltip dismissal.
        ///
        /// On touch devices, a long-press shows the tooltip, but the tooltip would never
        /// dismiss because there was no onLongPressEnd handler. The tooltip stayed visible
        /// forever until the widget tree was dismantled.
        ///
        /// This test:
        /// 1. Long-presses the anchor to show the tooltip
        /// 2. Releases the press (fires onLongPressEnd)
        /// 3. Waits for the 100ms hide delay + reverse animation
        /// 4. Asserts the tooltip is completely dismissed

        await pumpThemed(
          tester,
          Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Center(
                  child: LayrzTooltip(
                    contentText: 'Touch tooltip',
                    child: SizedBox(
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

        // Step 1: Long-press to show
        final gesture = await tester.startGesture(anchorCenter);
        await tester.pump(const Duration(milliseconds: 500)); // Trigger long-press
        expect(find.text('Touch tooltip'), findsOneWidget, reason: 'Tooltip should show on long-press');

        // Step 2: Release the gesture (fires onLongPressEnd)
        await gesture.up();
        // Wait for 100ms hide delay + 80ms reverse animation + buffer
        await tester.pumpAndSettle(const Duration(milliseconds: 300));

        // Step 3: Tooltip should be completely gone
        expect(
          find.text('Touch tooltip'),
          findsNothing,
          reason: 'Tooltip must be dismissed after long-press release',
        );
      },
    );

    testWidgets(
      'Tooltip dismisses on long-press cancel (DESIGN-77)',
      (tester) async {
        /// Regression test for long-press cancellation.
        ///
        /// If the gesture is cancelled (e.g., pointer leaves the target),
        /// the tooltip must dismiss cleanly via onLongPressCancel.

        await pumpThemed(
          tester,
          Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Center(
                  child: LayrzTooltip(
                    contentText: 'Cancellable tooltip',
                    child: SizedBox(
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

        // Step 1: Start a long-press gesture
        final gesture = await tester.startGesture(anchorCenter);
        await tester.pump(const Duration(milliseconds: 500)); // Trigger long-press
        expect(find.text('Cancellable tooltip'), findsOneWidget);

        // Step 2: Move far away to cancel the gesture
        await gesture.moveTo(const Offset(-200, -200));
        // The gesture is now cancelled, triggering onLongPressCancel
        await tester.pump();
        await gesture.up();
        // Wait for hide delay + animation
        await tester.pumpAndSettle(const Duration(milliseconds: 300));

        // Step 3: Tooltip should be gone
        expect(
          find.text('Cancellable tooltip'),
          findsNothing,
          reason: 'Tooltip must be dismissed after long-press cancel',
        );
      },
    );

    testWidgets(
      'Tapping away from a touch-opened tooltip dismisses it (DESIGN-77)',
      (tester) async {
        /// Regression test for tap-away dismissal of touch-opened tooltips.
        ///
        /// When a tooltip is opened via long-press, a tap-away barrier is mounted
        /// so the user can tap anywhere on screen to dismiss it. Tapping outside
        /// the tooltip should trigger the tap-away handler and dismiss the tooltip.

        await pumpThemed(
          tester,
          Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => SizedBox.expand(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      LayrzTooltip(
                        contentText: 'Tap-away tooltip',
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: const Center(child: Text('Anchor')),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 50,
                          height: 50,
                          color: const Color(0xFFFF0000),
                          child: const Center(child: Text('TapZone')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        final anchorCenter = tester.getCenter(find.text('Anchor'));

        // Step 1: Long-press to show tooltip
        final gesture = await tester.startGesture(anchorCenter);
        await tester.pump(const Duration(milliseconds: 500)); // Trigger long-press
        expect(find.text('Tap-away tooltip'), findsOneWidget, reason: 'Tooltip should show');

        // Step 2: Release the gesture (normally it would stay open, but this is just setup)
        await gesture.up();
        await tester.pump();
        // The tooltip is still visible at this point (100ms hide delay hasn't elapsed)
        expect(find.text('Tap-away tooltip'), findsOneWidget);

        // Step 3: Tap on the red tap zone (fires tap on barrier)
        final tapZoneCenter = tester.getCenter(find.text('TapZone'));
        await tester.tapAt(tapZoneCenter);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));

        // Step 4: Tooltip should be dismissed
        expect(
          find.text('Tap-away tooltip'),
          findsNothing,
          reason: 'Tap-away should dismiss the touch-opened tooltip',
        );
      },
    );

    testWidgets(
      'Hover-opened tooltip passes pointer events through (passthrough regression)',
      (tester) async {
        /// Regression test to ensure the tap-away barrier does NOT affect hover tooltips.
        ///
        /// The tap-away barrier is ONLY mounted when the tooltip was opened by touch.
        /// When opened via hover, there is NO barrier, so the widget tree beneath the
        /// tooltip remains interactive.

        final interactionLog = <String>[];

        await pumpThemed(
          tester,
          Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => SizedBox.expand(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      LayrzTooltip(
                        contentText: 'Hover tooltip',
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: const Center(child: Text('Anchor')),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => interactionLog.add('tapped'),
                        child: Container(
                          width: 50,
                          height: 50,
                          color: const Color(0xFF0000FF),
                          child: const Center(child: Text('ClickZone')),
                        ),
                      ),
                    ],
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
        expect(find.text('Hover tooltip'), findsOneWidget, reason: 'Tooltip should show on hover');

        // Step 2: Click on the ClickZone while tooltip is visible
        // The tap should NOT be blocked by a barrier (because hover tooltips have no barrier)
        final clickZoneCenter = tester.getCenter(find.text('ClickZone'));
        await tester.tapAt(clickZoneCenter);
        await tester.pumpAndSettle();

        // Step 3: Verify the click went through (no barrier intercepted it)
        expect(
          interactionLog,
          ['tapped'],
          reason: 'Hover-opened tooltip should not block pointer events to widgets beneath',
        );
      },
    );
  });
}
