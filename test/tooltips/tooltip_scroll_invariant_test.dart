import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Regression tests for the tooltip coordinate-space bug (fixed in 0c645dc).
///
/// **The bug:** Before the fix, `_buildTooltipContent` resolved the anchor's
/// position in WINDOW coordinates but placed the tooltip surface in OVERLAY
/// coordinates. When these spaces diverged (e.g., during scroll), the placement
/// was wrong. Symptoms: the tooltip moved exactly 2x the scroll delta.
///
/// **The key condition:** The bug manifests only when the Overlay is NOT
/// window-aligned. In the real showroom app, ShellRoute creates a nested
/// Navigator whose Overlay is inside a page, causing Overlay.of(context) to
/// resolve to that nested overlay. When the page scrolls, the overlay scrolls
/// too, and localToGlobal(Offset.zero) (without ancestor) returns window coords,
/// while localToGlobal(Offset.zero, ancestor: overlayRenderBox) returns coords
/// relative to the scrolled overlay. These diverge by the scroll delta, causing
/// 2x movement.
///
/// **The fix:** Use ancestor: overlayRenderBox to resolve anchor position in
/// overlay coordinates, matching where Positioned places the surface, and use
/// overlayRenderBox.size instead of MediaQuery.sizeOf().
///
/// **Test strategy:** Place an explicit Overlay INSIDE the SingleChildScrollView
/// so the overlay scrolls with the content, making the overlay's coordinate space
/// include the scroll offset. This reproduces the condition.
void main() {
  group('LayrzTooltip scroll invariance (coordinate-space regression)', () {
    testWidgets(
      'Test 1: scroll invariance — relative offset between anchor and tooltip is constant',
      (tester) async {
        final scrollController = ScrollController();
        final anchorKey = GlobalKey();

        // Build a tree where the Overlay is INSIDE the ScrollView, so it
        // scrolls with the content. This makes the overlay's coordinate space
        // different from the window's coordinate space by the scroll offset.
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: LayrzTheme(
              data: LayrzThemeData.light(),
              child: Center(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SizedBox(
                    width: 400,
                    height: 2000,
                    child: Overlay(
                      initialEntries: [
                        OverlayEntry(
                          builder: (overlayContext) => Stack(
                            children: [
                              Positioned(
                                left: 175,
                                top: 400,
                                child: LayrzTooltip(
                                  contentText: 'Tooltip content',
                                  position: LayrzTooltipPosition.bottom,
                                  trigger: LayrzTooltipTrigger.pointer,
                                  child: SizedBox(
                                    key: anchorKey,
                                    width: 50,
                                    height: 40,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0000FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Center(
                                        child: Text('Anchor'),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // ===== At scroll offset 0 =====
        final anchorCenter1 = tester.getCenter(find.byKey(anchorKey));
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);

        await mouse.moveTo(anchorCenter1);
        await tester.pumpAndSettle();

        expect(
          find.text('Tooltip content'),
          findsOneWidget,
          reason: 'Tooltip should show on hover at scroll offset 0',
        );

        final anchorRect1 = tester.getRect(find.byKey(anchorKey));
        final tooltipRect1 = tester.getRect(find.text('Tooltip content'));

        final relativeOffset1 = Offset(
          tooltipRect1.topLeft.dx - anchorRect1.center.dx,
          tooltipRect1.topLeft.dy - anchorRect1.center.dy,
        );

        // debugPrint(
        //   'At scroll 0:\n'
        //   '  Anchor: $anchorRect1\n'
        //   '  Tooltip: $tooltipRect1\n'
        //   '  Relative offset: $relativeOffset1',
        // );

        // Dismiss and scroll
        await mouse.moveTo(const Offset(100, 100));
        await tester.pumpAndSettle();
        expect(
          find.text('Tooltip content'),
          findsNothing,
          reason: 'Tooltip should dismiss when mouse moves away',
        );

        // ===== Scroll by 300 pixels =====
        scrollController.jumpTo(300.0);
        await tester.pumpAndSettle();

        // Re-trigger the tooltip
        final anchorCenter2 = tester.getCenter(find.byKey(anchorKey));
        await mouse.moveTo(anchorCenter2);
        await tester.pumpAndSettle();

        expect(
          find.text('Tooltip content'),
          findsOneWidget,
          reason: 'Tooltip should show on hover after scrolling',
        );

        final anchorRect2 = tester.getRect(find.byKey(anchorKey));
        final tooltipRect2 = tester.getRect(find.text('Tooltip content'));

        final relativeOffset2 = Offset(
          tooltipRect2.topLeft.dx - anchorRect2.center.dx,
          tooltipRect2.topLeft.dy - anchorRect2.center.dy,
        );

        // debugPrint(
        //   'At scroll 300:\n'
        //   '  Anchor: $anchorRect2\n'
        //   '  Tooltip: $tooltipRect2\n'
        //   '  Relative offset: $relativeOffset2',
        // );

        // ===== THE CRITICAL ASSERTION =====
        // The relative offset must be identical at both scroll positions.
        // If the bug is present, the overlay-relative position diverges from
        // window-absolute position by 2x the scroll delta, causing relativeOffset2
        // to differ significantly from relativeOffset1.
        expect(
          relativeOffset1.dx,
          closeTo(relativeOffset2.dx, 1.0),
          reason:
              'Tooltip horizontal offset relative to anchor must be invariant '
              'with scroll (overlay must track coordinate space). '
              'At scroll 0: $relativeOffset1, at scroll 300: $relativeOffset2',
        );
        expect(
          relativeOffset1.dy,
          closeTo(relativeOffset2.dy, 1.0),
          reason:
              'Tooltip vertical offset relative to anchor must be invariant '
              'with scroll (overlay must track coordinate space). '
              'At scroll 0: $relativeOffset1, at scroll 300: $relativeOffset2',
        );
      },
    );

    testWidgets(
      'Test 2: absolute placement while scrolled (bottom position) — geometric contract',
      (tester) async {
        final scrollController = ScrollController();
        final anchorKey = GlobalKey();

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: LayrzTheme(
              data: LayrzThemeData.light(),
              child: Center(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SizedBox(
                    width: 400,
                    height: 2000,
                    child: Overlay(
                      initialEntries: [
                        OverlayEntry(
                          builder: (overlayContext) => Stack(
                            children: [
                              Positioned(
                                left: 175,
                                top: 400,
                                child: LayrzTooltip(
                                  contentText: 'Tooltip content',
                                  position: LayrzTooltipPosition.bottom,
                                  trigger: LayrzTooltipTrigger.pointer,
                                  child: SizedBox(
                                    key: anchorKey,
                                    width: 50,
                                    height: 40,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0000FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Center(
                                        child: Text('Anchor'),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Scroll 300 pixels first
        scrollController.jumpTo(300.0);
        await tester.pumpAndSettle();

        // Trigger the tooltip via mouse hover
        final anchorCenter = tester.getCenter(find.byKey(anchorKey));
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);

        await mouse.moveTo(anchorCenter);
        await tester.pumpAndSettle();

        expect(
          find.text('Tooltip content'),
          findsOneWidget,
          reason: 'Tooltip should show on hover after scrolling',
        );

        // Measure rects
        final anchorRect = tester.getRect(find.byKey(anchorKey));
        final tooltipRect = tester.getRect(find.text('Tooltip content'));

        // For bottom position, the tooltip should be positioned with its top
        // at: anchor.bottom + kLayrzTooltipOffset
        final expectedTooltipTop = anchorRect.bottom + kLayrzTooltipOffset;
        final expectedTooltipLeft = anchorRect.center.dx - (tooltipRect.width / 2);

        // debugPrint(
        //   'While scrolled 300:\n'
        //   '  Anchor: $anchorRect\n'
        //   '  Tooltip: $tooltipRect\n'
        //   '  Expected top: $expectedTooltipTop (actual: ${tooltipRect.top})\n'
        //   '  Expected left: $expectedTooltipLeft (actual: ${tooltipRect.left})',
        // );

        // The actual top should match expected (within 10px for text layout variation)
        expect(
          tooltipRect.top,
          closeTo(expectedTooltipTop, 10.0),
          reason:
              'Tooltip top must be ~kLayrzTooltipOffset below anchor bottom while scrolled. '
              'This validates the fix uses overlay-relative coordinates. '
              'Expected: $expectedTooltipTop, got: ${tooltipRect.top}',
        );

        // The actual left should match expected
        expect(
          tooltipRect.left,
          closeTo(expectedTooltipLeft, 1.0),
          reason:
              'Tooltip must be horizontally centred on anchor while scrolled. '
              'Expected: $expectedTooltipLeft, got: ${tooltipRect.left}',
        );
      },
    );

    testWidgets(
      'Test 3: tooltip moves exactly as far as its anchor when scrolled (not twice)',
      (tester) async {
        final scrollController = ScrollController();
        final anchorKey = GlobalKey();

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: LayrzTheme(
              data: LayrzThemeData.light(),
              child: Center(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SizedBox(
                    width: 400,
                    height: 2000,
                    child: Overlay(
                      initialEntries: [
                        OverlayEntry(
                          builder: (overlayContext) => Stack(
                            children: [
                              Positioned(
                                left: 175,
                                top: 400,
                                child: LayrzTooltip(
                                  contentText: 'Tooltip content',
                                  position: LayrzTooltipPosition.bottom,
                                  trigger: LayrzTooltipTrigger.pointer,
                                  child: SizedBox(
                                    key: anchorKey,
                                    width: 50,
                                    height: 40,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0000FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Center(
                                        child: Text('Anchor'),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);

        // ===== PHASE 1: Trigger at scroll 0 =====
        final anchorCenter1 = tester.getCenter(find.byKey(anchorKey));
        await mouse.moveTo(anchorCenter1);
        await tester.pumpAndSettle();

        expect(
          find.text('Tooltip content'),
          findsOneWidget,
          reason: 'Tooltip should show on hover at scroll 0',
        );

        final anchorRect1 = tester.getRect(find.byKey(anchorKey));
        final tooltipRect1 = tester.getRect(find.text('Tooltip content'));

        // debugPrint(
        //   'At scroll offset 0:\n'
        //   '  Anchor: ${anchorRect1.topLeft}\n'
        //   '  Tooltip: ${tooltipRect1.topLeft}',
        // );

        // ===== PHASE 2: Dismiss tooltip =====
        await mouse.moveTo(const Offset(100, 100));
        await tester.pumpAndSettle();
        expect(
          find.text('Tooltip content'),
          findsNothing,
          reason: 'Tooltip should dismiss when mouse moves away',
        );

        // ===== PHASE 3: Scroll by 250 pixels =====
        const scrollDelta = 250.0;
        scrollController.jumpTo(scrollDelta);
        await tester.pumpAndSettle();

        // ===== PHASE 4: Re-trigger at new scroll position =====
        final anchorCenter2 = tester.getCenter(find.byKey(anchorKey));
        await mouse.moveTo(anchorCenter2);
        await tester.pumpAndSettle();

        expect(
          find.text('Tooltip content'),
          findsOneWidget,
          reason: 'Tooltip should show on hover after scrolling',
        );

        final anchorRect2 = tester.getRect(find.byKey(anchorKey));
        final tooltipRect2 = tester.getRect(find.text('Tooltip content'));

        // debugPrint(
        //   'At scroll offset $scrollDelta:\n'
        //   '  Anchor: ${anchorRect2.topLeft}\n'
        //   '  Tooltip: ${tooltipRect2.topLeft}',
        // );

        // ===== PHASE 5: Verify movement is 1:1, not 2:1 =====
        final anchorMovementY = anchorRect1.top - anchorRect2.top;
        final tooltipMovementY = tooltipRect1.top - tooltipRect2.top;

        // debugPrint(
        //   'Movements:\n'
        //   '  Anchor moved up by: $anchorMovementY\n'
        //   '  Tooltip moved up by: $tooltipMovementY\n'
        //   '  Ratio: ${(tooltipMovementY / anchorMovementY).toStringAsFixed(3)}',
        // );

        // THE CRITICAL ASSERTION:
        // Both should move by ~250px. If the bug is present, the tooltip moves
        // ~500px (2x) because localToGlobal(Offset.zero) uses window coords,
        // which differ from overlay coords by 2x the scroll offset.
        expect(
          anchorMovementY,
          closeTo(scrollDelta, 1.0),
          reason: 'Anchor should move up by scroll delta',
        );

        expect(
          tooltipMovementY,
          closeTo(scrollDelta, 1.0),
          reason:
              'Tooltip must move exactly as far as anchor (1:1 ratio), not 2x. '
              'With the bug, tooltipMovement ≈ 2 × scrollDelta. '
              'Anchor moved $anchorMovementY, tooltip moved $tooltipMovementY',
        );

        // Extra: compute the ratio to catch the 2x signature specifically
        if (anchorMovementY != 0) {
          final ratio = tooltipMovementY / anchorMovementY;
          expect(
            ratio,
            closeTo(1.0, 0.01),
            reason:
                'Tooltip-to-anchor movement ratio must be 1:1 (not 2:1 with bug). '
                'Got ratio: ${ratio.toStringAsFixed(3)}',
          );
        }
      },
    );
  });
}
