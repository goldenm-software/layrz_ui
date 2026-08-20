import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

/// Test harness with a full-area backdrop behind the tooltip anchor.
///
/// The backdrop is a [Positioned.fill] layer that is painted BEHIND the anchor.
/// When the tooltip shows (with ignorePointer: true), taps and hovers that hit
/// the tooltip surface will pass through and reach the backdrop below.
///
/// - [onBackdropTap]: fired when the backdrop receives a tap
/// - [onBackdropEnter]: fired when the mouse enters the backdrop
/// - [anchorKey]: allows the test to locate the anchor widget
Widget _buildTooltipPassthroughHarness({
  required VoidCallback onBackdropTap,
  required ValueChanged<PointerEnterEvent> onBackdropEnter,
  required GlobalKey anchorKey,
}) {
  return Stack(
    children: [
      // The backdrop fills the entire test surface and is painted BEHIND.
      Positioned.fill(
        child: MouseRegion(
          onEnter: onBackdropEnter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBackdropTap,
            child: const SizedBox.expand(),
          ),
        ),
      ),
      // The anchor, positioned near the top-left so the tooltip renders
      // below/to the right, overlapping the backdrop.
      Positioned(
        top: 40,
        left: 40,
        child: LayrzTooltip(
          contentText: 'Tooltip body',
          child: SizedBox(
            key: anchorKey,
            width: 80,
            height: 40,
            child: const Center(
              child: Text('Anchor'),
            ),
          ),
        ),
      ),
    ],
  );
}

void main() {
  group('LayrzTooltip pass-through behavior (tooltip does not block input)', () {
    testWidgets(
      'Case 0 (REPRO): desktop mouse-hover-then-click sequence',
      (tester) async {
        // DESKTOP REPRODUCTION TEST
        //
        // This reproduces the exact user-reported failure:
        // 1. User hovers mouse over anchor → tooltip shows via hover
        // 2. User mouse-clicks inside the tooltip surface area
        // 3. Click should pass through to the backdrop (ignorePointer: true)
        //
        // The existing tests (Case 1, Case 2) use touch/longPress and tester.tapAt,
        // which do not exercise the mouse-hover trigger path.
        //
        // This test will FAIL if:
        // - The hover trigger does not work, OR
        // - The click under the tooltip is consumed instead of passing through

        bool backdropTapped = false;
        final anchorKey = GlobalKey();

        await pumpThemed(
          tester,
          _buildTooltipPassthroughHarness(
            onBackdropTap: () => backdropTapped = true,
            onBackdropEnter: (_) {},
            anchorKey: anchorKey,
          ),
        );

        // Verify the anchor is in the tree
        expect(find.text('Anchor'), findsOneWidget);

        // Step 1: Create a mouse pointer (desktop input)
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);

        // Step 2: Move the mouse to the anchor position to trigger hover
        final anchorCenter = tester.getCenter(find.text('Anchor'));
        await mouse.moveTo(anchorCenter);
        await tester.pumpAndSettle();

        // Debug: check if tooltip is showing
        final tooltipFound = find.text('Tooltip body').evaluate().isNotEmpty;
        debugPrint('DEBUG: After mouse hover to anchor, tooltip found: $tooltipFound');

        // Verify the tooltip is now SHOWING due to hover (not long-press)
        expect(
          find.text('Tooltip body'),
          findsOneWidget,
          reason: 'Tooltip should show when mouse hovers over anchor (hoverDelay: 0)',
        );

        // Step 3: Get the tooltip surface rect
        final tooltipRect = tester.getRect(find.text('Tooltip body'));
        final pointInTooltip = tooltipRect.center;

        // Guard: verify the tooltip rect is valid
        expect(tooltipRect.width, greaterThan(0));
        expect(tooltipRect.height, greaterThan(0));
        expect(tooltipRect.contains(pointInTooltip), isTrue);

        // Step 4: Move mouse to a point inside the tooltip surface
        await mouse.moveTo(pointInTooltip);
        await tester.pump();

        // Step 5: Mouse-click inside the tooltip surface (mouse down + up)
        await mouse.down(pointInTooltip);
        await tester.pump();
        await mouse.up();
        await tester.pumpAndSettle();

        // Step 6: Assert that the backdrop received the click
        // This FAILS if the click is consumed by RawTooltip instead of passing through
        expect(
          backdropTapped,
          isTrue,
          reason:
              'Mouse-click inside tooltip should pass through to backdrop '
              'when ignorePointer: true (DESKTOP MOUSE-HOVER-THEN-CLICK PATH)',
        );
      },
    );

    testWidgets(
      'Case 0b (ANCHOR INTERACTIVITY): anchor remains interactive while tooltip shows',
      (tester) async {
        // ANCHOR INTERACTIVITY TEST
        //
        // Check if the anchor child (the button) remains interactive after the
        // tooltip shows on hover. This tests whether the anchor's gesture/mouse
        // handlers still work when the tooltip is visible.
        //
        // Scenario:
        // 1. Create an anchor with a GestureDetector.onTap
        // 2. Hover to show tooltip
        // 3. Try to tap the anchor while tooltip is visible
        // 4. Anchor's onTap should still fire

        bool anchorTapped = false;
        final anchorKey = GlobalKey();

        await pumpThemed(
          tester,
          Stack(
            children: [
              Positioned.fill(
                child: SizedBox.expand(),
              ),
              Positioned(
                top: 40,
                left: 40,
                child: LayrzTooltip(
                  contentText: 'Tooltip body',
                  child: GestureDetector(
                    key: anchorKey,
                    onTap: () => anchorTapped = true,
                    child: SizedBox(
                      width: 80,
                      height: 40,
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

        // Create a mouse pointer
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);

        // Step 1: Hover the anchor to show the tooltip
        final anchorCenter = tester.getCenter(find.text('Anchor'));
        await mouse.moveTo(anchorCenter);
        await tester.pumpAndSettle();

        expect(find.text('Tooltip body'), findsOneWidget, reason: 'Tooltip should show');

        // Step 2: While tooltip is visible, try to click the anchor
        anchorTapped = false;
        await mouse.down(anchorCenter);
        await tester.pump();
        await mouse.up();
        await tester.pumpAndSettle();

        // Assertion: anchor's onTap should still fire
        expect(
          anchorTapped,
          isTrue,
          reason:
              'Anchor GestureDetector.onTap should fire even while tooltip is showing '
              '(anchor should remain interactive)',
        );
      },
    );

    testWidgets(
      'Case 0b (REPRO EXTENDED): mouse hover on backdrop after tooltip shows',
      (tester) async {
        // EXTENDED REPRODUCTION: MOUSE HOVER PASSTHROUGH
        //
        // This test extends Case 0 by checking if mouse HOVER on the backdrop
        // passes through the tooltip surface.
        //
        // Scenario:
        // 1. Mouse hovers over anchor → tooltip shows
        // 2. Mouse moves to hover over backdrop area (underneath tooltip)
        // 3. Backdrop's MouseRegion should detect the hover
        //
        // This will FAIL if the tooltip blocks hover events from reaching the backdrop.

        PointerHoverEvent? backdropHoverEvent;
        final anchorKey = GlobalKey();

        await pumpThemed(
          tester,
          Stack(
            children: [
              Positioned.fill(
                child: MouseRegion(
                  onHover: (event) => backdropHoverEvent = event,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 40,
                child: LayrzTooltip(
                  contentText: 'Tooltip body',
                  child: SizedBox(
                    key: anchorKey,
                    width: 80,
                    height: 40,
                    child: const Center(
                      child: Text('Anchor'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        // Create a mouse pointer
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);

        // Step 1: Hover the anchor to show the tooltip
        final anchorCenter = tester.getCenter(find.text('Anchor'));
        await mouse.moveTo(anchorCenter);
        await tester.pumpAndSettle();

        expect(find.text('Tooltip body'), findsOneWidget, reason: 'Tooltip should show');

        // Step 2: Move mouse to a point on the backdrop (underneath tooltip)
        final tooltipRect = tester.getRect(find.text('Tooltip body'));

        // Find a point that is:
        // - INSIDE the tooltip surface area (so it's visually "under" the tooltip)
        // - But NOT in the anchor's widget tree (different x position)
        final pointUnderTooltip = Offset(
          tooltipRect.center.dx,
          tooltipRect.center.dy + 20, // Move down into the tooltip area
        );

        // Reset the backdrop hover event
        backdropHoverEvent = null;

        // Move mouse to this point (should pass through tooltip to backdrop)
        await mouse.moveTo(pointUnderTooltip);
        await tester.pumpAndSettle();

        // This assertion FAILS if the tooltip blocks hover from reaching the backdrop
        expect(
          backdropHoverEvent,
          isNotNull,
          reason:
              'Mouse hover inside tooltip surface should pass through to backdrop MouseRegion '
              '(EXTENDED REPRO: hover passthrough after tooltip shows)',
        );
      },
    );

    testWidgets(
      'Case 1: tap passes through a SHOWING tooltip to backdrop GestureDetector',
      (tester) async {
        // DESIGN-77 UPDATE: The global pointer route dismisses tooltips on PointerDownEvent
        // but does NOT claim the pointer, so taps pass through to underlying widgets.
        //
        // This test uses longPress (touch), so the pointer route observes the down event,
        // dismisses the tooltip, and lets the tap propagate to the backdrop GestureDetector.

        bool backdropTapped = false;
        final anchorKey = GlobalKey();

        await pumpThemed(
          tester,
          _buildTooltipPassthroughHarness(
            onBackdropTap: () => backdropTapped = true,
            onBackdropEnter: (_) {},
            anchorKey: anchorKey,
          ),
        );

        // Verify the anchor is in the tree
        expect(find.text('Anchor'), findsOneWidget);

        // Long-press the anchor to show the tooltip via TOUCH
        await tester.longPress(find.text('Anchor'));
        await tester.pumpAndSettle();

        // Verify the tooltip is actually visible
        expect(find.text('Tooltip body'), findsOneWidget, reason: 'Tooltip should be visible after long-press');

        // Get the bounding rect of the tooltip surface
        final tooltipRect = tester.getRect(find.text('Tooltip body'));

        // Guard: the tooltip rect must be meaningful (not empty)
        expect(tooltipRect.width, greaterThan(0), reason: 'Tooltip rect should have positive width');
        expect(tooltipRect.height, greaterThan(0), reason: 'Tooltip rect should have positive height');

        // Pick a point at the center of the tooltip surface
        final pointInTooltip = tooltipRect.center;

        // Guard: verify the point is actually inside the tooltip
        expect(
          tooltipRect.contains(pointInTooltip),
          isTrue,
          reason: 'Point should be inside tooltip rect; prevents accidental pass',
        );

        // Tap inside the tooltip surface
        await tester.tapAt(pointInTooltip);
        await tester.pumpAndSettle();

        // Assert: The backdrop DOES receive the tap (global route observes without claiming)
        expect(
          backdropTapped,
          isTrue,
          reason:
              'Tap inside tooltip passes through to backdrop via global pointer route '
              '(pointer route dismisses tooltip but does not claim the pointer, DESIGN-77)',
        );

        // Assert: The tooltip is now dismissed
        expect(
          find.text('Tooltip body'),
          findsNothing,
          reason: 'Tap inside tooltip should dismiss it via global pointer route',
        );
      },
    );

    testWidgets(
      'Case 2: hover passes through a SHOWING tooltip to backdrop MouseRegion',
      (tester) async {
        // DESIGN-77 UPDATE: The global pointer route observes PointerDownEvent to dismiss
        // tooltips but does NOT block mouse hover. Mouse movement is not claimed by the
        // route, so hover events pass through to underlying MouseRegions.

        PointerEnterEvent? backdropEnterEvent;
        final anchorKey = GlobalKey();

        await pumpThemed(
          tester,
          _buildTooltipPassthroughHarness(
            onBackdropTap: () {},
            onBackdropEnter: (event) => backdropEnterEvent = event,
            anchorKey: anchorKey,
          ),
        );

        // Long-press the anchor to show the tooltip via TOUCH
        await tester.longPress(find.text('Anchor'));
        await tester.pumpAndSettle();

        // Verify the tooltip is visible
        expect(find.text('Tooltip body'), findsOneWidget, reason: 'Tooltip must be visible for hover test');

        // Get the tooltip surface rect
        final tooltipRect = tester.getRect(find.text('Tooltip body'));
        final pointInTooltip = tooltipRect.center;

        // Guard: verify the point is in the tooltip
        expect(tooltipRect.contains(pointInTooltip), isTrue, reason: 'Point must be inside tooltip rect');

        // Create a mouse gesture and move it into the tooltip surface
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(gesture.removePointer);
        await tester.pump();

        // Move the mouse pointer to the tooltip surface center
        await gesture.moveTo(pointInTooltip);
        await tester.pumpAndSettle();

        // Assert: The backdrop MouseRegion.onEnter DOES fire.
        // The global pointer route observes without claiming, allowing hover to pass through.
        expect(
          backdropEnterEvent,
          isNotNull,
          reason:
              'Hover inside tooltip passes through to backdrop MouseRegion '
              '(global pointer route observes without claiming mouse events, DESIGN-77)',
        );
      },
    );

    testWidgets(
      'Case 3: wrapping does not degrade the anchor\'s tap callback',
      (tester) async {
        // Requirement: A child wrapped in LayrzTooltip must retain its own
        // gesture handling. Tapping the child should fire its onTap callback
        // whether or not the tooltip is showing.

        bool childTapped = false;

        // Test 3a: Child with onTap, unwrapped (baseline)
        await pumpThemed(
          tester,
          GestureDetector(
            onTap: () => childTapped = true,
            child: SizedBox(
              width: 80,
              height: 40,
              child: const Center(child: Text('Anchor')),
            ),
          ),
        );

        childTapped = false;
        await tester.tap(find.text('Anchor'));
        await tester.pumpAndSettle();

        final unwrappedResult = childTapped;
        expect(unwrappedResult, isTrue, reason: 'Unwrapped child onTap should fire');

        // Test 3b: Same child, wrapped in LayrzTooltip
        await pumpThemed(
          tester,
          GestureDetector(
            onTap: () => childTapped = true,
            child: LayrzTooltip(
              contentText: 'Tooltip body',
              child: SizedBox(
                width: 80,
                height: 40,
                child: const Center(child: Text('Anchor')),
              ),
            ),
          ),
        );

        childTapped = false;
        await tester.tap(find.text('Anchor'));
        await tester.pumpAndSettle();

        final wrappedResult = childTapped;
        expect(wrappedResult, isTrue, reason: 'Wrapped child onTap should fire identically');

        // Assertion: behavior is identical
        expect(wrappedResult, equals(unwrappedResult), reason: 'Wrapping should not degrade tap handling');
      },
    );

    testWidgets(
      'baseline: simple long-press shows tooltip (no gesture conflicts)',
      (tester) async {
        // Baseline test: LayrzTooltip with a simple child (Container, no gestures)
        // should show the tooltip when long-pressed.
        // This establishes that RawTooltip is wired correctly.

        await pumpThemed(
          tester,
          LayrzTooltip(
            contentText: 'Tooltip body',
            child: Container(
              width: 80,
              height: 40,
              color: const Color(0xFF007AFF),
            ),
          ),
        );

        // Verify the child is in the tree
        expect(find.byType(Container), findsOneWidget);

        // Long-press the container
        await tester.longPress(find.byType(Container));
        await tester.pumpAndSettle();

        // Assert: Tooltip shows on long-press
        expect(find.text('Tooltip body'), findsOneWidget, reason: 'Tooltip should show when long-pressed');
      },
    );

    testWidgets(
      'child onLongPress vs tooltip long-press trigger (gesture arena)',
      (tester) async {
        // Measurement test: What happens to a child\'s onLongPress callback when
        // the child is wrapped in LayrzTooltip (which uses RawTooltip with
        // triggerMode: longPress)?
        //
        // RawTooltip.triggerMode.longPress competes in the gesture arena.
        // This test observes the actual outcome and documents the constraint.

        bool childLongPressed = false;

        await pumpThemed(
          tester,
          LayrzTooltip(
            contentText: 'Tooltip body',
            child: GestureDetector(
              onLongPress: () => childLongPressed = true,
              child: SizedBox(
                width: 80,
                height: 40,
                child: const Center(child: Text('Anchor')),
              ),
            ),
          ),
        );

        await tester.longPress(find.text('Anchor'));
        await tester.pumpAndSettle();

        final tooltipShown = find.text('Tooltip body').evaluate().isNotEmpty;

        // Assert BOTH observed facts explicitly, matching reality.
        expect(childLongPressed, isTrue, reason: 'Child GestureDetector.onLongPress fires in gesture arena');
        expect(tooltipShown, isFalse, reason: 'Child onLongPress wins gesture arena; RawTooltip does not trigger');
      },
    );
  });
}
