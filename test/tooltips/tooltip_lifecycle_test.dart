import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/tooltips.dart';

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
  });
}
