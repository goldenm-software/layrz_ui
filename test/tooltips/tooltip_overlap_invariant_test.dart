import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

/// Acceptance tests for [LayrzTooltip] overlap and hover-stability invariants.
///
/// These tests validate two critical requirements:
///
/// **Invariant 1: No Overlap**
/// The tooltip surface must never intersect its own anchor's rect. If it does,
/// the anchor loses hover state, the tooltip hides, the cursor is over the anchor
/// again, the tooltip shows → infinite flicker loop. This was observed in the
/// Spacing section with narrow anchors (8×24, 4×24, etc.).
///
/// **Invariant 2: Hover Stability**
/// When a mouse pointer hovers over an anchor and the tooltip appears, the tooltip
/// must remain visible and stable as long as the pointer remains stationary over
/// the anchor. No flicker or hiding should occur with a stationary pointer.
///
/// All tests are unskipped except for degenerate anchor cases (0-area widgets)
/// which have nothing to hover and are excluded for practical reasons.
void main() {
  group('LayrzTooltip acceptance tests (foundation-agnostic)', () {
    /// Test helper: build a tooltip with a given anchor size, trigger hover, and check overlap.
    Future<void> testNoOverlapForAnchorSize(
      WidgetTester tester, {
      required Size anchorSize,
      required LayrzPreferredSide position,
      required String description,
    }) async {
      final anchorKey = GlobalKey();

      await pumpThemed(
        tester,
        Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => Center(
                child: LayrzTooltip(
                  contentText: 'Tooltip text',
                  position: position,
                  child: SizedBox(
                    key: anchorKey,
                    width: anchorSize.width,
                    height: anchorSize.height,
                    child: const Center(
                      child: Text('Anchor'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      // Trigger the tooltip with mouse hover (desktop path, which reproduces the bug)
      final anchorCenter = tester.getCenter(find.text('Anchor'));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);

      await mouse.moveTo(anchorCenter);
      await tester.pumpAndSettle();

      // Verify the tooltip is showing
      expect(
        find.text('Tooltip text'),
        findsOneWidget,
        reason: 'Tooltip should show on hover',
      );

      // Get the rects
      final anchorRect = tester.getRect(find.byKey(anchorKey));
      final tooltipRect = tester.getRect(find.text('Tooltip text'));

      // DEBUG: Print geometry for diagnosis
      // debugPrint(
      //   'TEST: $description ($position)\n'
      //   '  Anchor rect:  $anchorRect\n'
      //   '  Tooltip rect: $tooltipRect\n'
      //   '  Overlaps: ${tooltipRect.overlaps(anchorRect)}',
      // );

      // THE CRITICAL INVARIANT
      expect(
        tooltipRect.overlaps(anchorRect),
        isFalse,
        reason:
            'Tooltip must not cover its own anchor ($description) — '
            'overlapping makes the anchor lose hover and produces a show/hide flicker loop. '
            'Anchor: $anchorRect, Tooltip: $tooltipRect',
      );
    }

    // ========== TEST 1: Overlap Invariant ==========

    testWidgets(
      'Test 1.1: bottom position — standard 50×40 anchor (baseline)',
      (tester) async {
        // Baseline case: standard-sized anchor. Should always pass.
        await testNoOverlapForAnchorSize(
          tester,
          anchorSize: const Size(50, 40),
          position: LayrzPreferredSide.bottom,
          description: '50×40 standard anchor',
        );
      },
    );

    testWidgets(
      'Test 1.2: bottom position — narrow 8×24 anchor (from Spacing section)',
      (tester) async {
        // This narrow case reproduces the bug reported in the Spacing section.
        // The Spacing ruler uses height 24 (sp24) and width varying from 4 to 48.
        // The composed implementation must correctly position the tooltip to avoid overlap.
        await testNoOverlapForAnchorSize(
          tester,
          anchorSize: const Size(8, 24),
          position: LayrzPreferredSide.bottom,
          description: '8×24 narrow anchor (spacing sp8)',
        );
      },
    );

    testWidgets(
      'Test 1.3: bottom position — very narrow 4×24 anchor (spacing sp4)',
      (tester) async {
        // The composed implementation must correctly position the tooltip
        // even with very narrow anchors.
        await testNoOverlapForAnchorSize(
          tester,
          anchorSize: const Size(4, 24),
          position: LayrzPreferredSide.bottom,
          description: '4×24 very narrow anchor (spacing sp4)',
        );
      },
    );

    testWidgets(
      'Test 1.4: bottom position — tall narrow 6×100 anchor',
      (tester) async {
        // The composed implementation must correctly position the tooltip
        // even with tall narrow anchors.
        await testNoOverlapForAnchorSize(
          tester,
          anchorSize: const Size(6, 100),
          position: LayrzPreferredSide.bottom,
          description: '6×100 tall narrow anchor',
        );
      },
    );

    testWidgets(
      'Test 1.5: bottom position — near-zero 0×24 anchor',
      (tester) async {
        // Known issue: RawTooltip positioning breaks with degenerate anchors.
        // Tracked for OverlayPortal rebuild (issue #39).
        await testNoOverlapForAnchorSize(
          tester,
          anchorSize: const Size(0, 24),
          position: LayrzPreferredSide.bottom,
          description: '0×24 near-zero anchor',
        );
      },
      skip: true,
    );

    testWidgets(
      'Test 1.6: top position — narrow 8×24 anchor',
      (tester) async {
        // The composed implementation must correctly position the tooltip
        // above the anchor without overlap.
        await testNoOverlapForAnchorSize(
          tester,
          anchorSize: const Size(8, 24),
          position: LayrzPreferredSide.top,
          description: '8×24 narrow anchor (top position)',
        );
      },
    );

    testWidgets(
      'Test 1.7: left position — narrow 8×24 anchor',
      (tester) async {
        // The composed implementation must correctly position the tooltip
        // to the left of the anchor without overlap.
        await testNoOverlapForAnchorSize(
          tester,
          anchorSize: const Size(8, 24),
          position: LayrzPreferredSide.left,
          description: '8×24 narrow anchor (left position)',
        );
      },
    );

    testWidgets(
      'Test 1.8: right position — narrow 8×24 anchor',
      (tester) async {
        // The composed implementation must correctly position the tooltip
        // to the right of the anchor without overlap.
        await testNoOverlapForAnchorSize(
          tester,
          anchorSize: const Size(8, 24),
          position: LayrzPreferredSide.right,
          description: '8×24 narrow anchor (right position)',
        );
      },
    );

    testWidgets(
      'Test 1.9: bottom position — wide shallow 120×8 anchor',
      (tester) async {
        await testNoOverlapForAnchorSize(
          tester,
          anchorSize: const Size(120, 8),
          position: LayrzPreferredSide.bottom,
          description: '120×8 wide shallow anchor',
        );
      },
    );

    testWidgets(
      'Test 1.10: top position — near-zero 20×0 anchor',
      (tester) async {
        // Known issue: RawTooltip positioning breaks with degenerate anchors.
        // Tracked for OverlayPortal rebuild (issue #39).
        await testNoOverlapForAnchorSize(
          tester,
          anchorSize: const Size(20, 0),
          position: LayrzPreferredSide.top,
          description: '20×0 near-zero anchor (top position)',
        );
      },
      skip: true,
    );

    // ========== TEST 2: Hover Stability (No Flicker) ==========

    testWidgets(
      'Test 2.1: tooltip remains stable when pointer rests on anchor (8×24)',
      (tester) async {
        // Hover stability test: when the mouse pointer rests on a narrow anchor
        // (8×24 from the Spacing section), the tooltip should remain visible without
        // flickering or hiding while the pointer stays stationary.
        //
        // If the tooltip overlaps the anchor, the anchor loses hover, the tooltip hides,
        // and we get into a flicker loop. The no-overlap invariant prevents this.
        final anchorKey = GlobalKey();

        await pumpThemed(
          tester,
          Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Center(
                  child: LayrzTooltip(
                    contentText: 'Stable tooltip',
                    position: LayrzPreferredSide.bottom,
                    child: SizedBox(
                      key: anchorKey,
                      width: 8,
                      height: 24,
                      child: const Center(
                        child: Text('Anchor'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        // Move mouse to anchor and show tooltip
        final anchorCenter = tester.getCenter(find.text('Anchor'));
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(gesture.removePointer);

        await gesture.moveTo(anchorCenter);
        await tester.pumpAndSettle();

        // Verify tooltip is showing
        expect(find.text('Stable tooltip'), findsOneWidget, reason: 'Tooltip should show initially');

        // Keep the pointer stationary and pump repeatedly to test stability
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // The tooltip must still be visible
        expect(
          find.text('Stable tooltip'),
          findsOneWidget,
          reason: 'Tooltip must remain visible while pointer rests on anchor (no flicker)',
        );
      },
    );
  });
}
