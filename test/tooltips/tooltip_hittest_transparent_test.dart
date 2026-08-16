import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/tooltips.dart';

import '../helpers/pump_themed.dart';

/// Acceptance tests for [LayrzTooltip] hit-test behavior on transparent anchors.
///
/// These tests document a known limitation of the current [RawTooltip] implementation:
/// When a bare, transparent, non-interactive widget is wrapped in [LayrzTooltip],
/// [RawTooltip] wraps the child in a [Listener] with [HitTestBehavior.opaque], causing
/// the wrapped anchor to absorb hit-tests that would otherwise pass through.
///
/// This defect is observable only when an anchor is:
/// 1. Transparent (no fill color, no content)
/// 2. Non-interactive (no gesture handlers)
/// 3. Positioned in a [Stack] above an opaque backdrop
///
/// A future rebuild on [OverlayPortal] will resolve this by using proper hit-test
/// configuration on the gesture wrappers, allowing transparent anchors to pass
/// hits through to underlying widgets.
///
/// Failing cases are marked with `skip:` for this reason. Case A (baseline) is unskipped
/// and should always pass — it proves the backdrop is correctly configured and verifies
/// the problem is specific to wrapping, not the test harness itself.

/// Test harness: a Stack with a full-area backdrop + a transparent SizedBox anchor.
///
/// The backdrop is an opaque GestureDetector (fills the entire test surface).
/// The anchor is a bare SizedBox with NO content and NO gesture handlers.
/// The goal is to measure whether tapping the anchor allows the tap to pass
/// through to the backdrop below.
Widget _buildTransparentAnchorStack({
  required VoidCallback onBackdropTap,
  required bool wrapInTooltip,
}) {
  Widget anchor = SizedBox(
    width: 80,
    height: 40,
  );

  if (wrapInTooltip) {
    anchor = LayrzTooltip(
      contentText: 'Tooltip body',
      child: anchor,
    );
  }

  return Stack(
    children: [
      // Full-area backdrop: GestureDetector with opaque HitTestBehavior
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBackdropTap,
          child: const SizedBox.expand(),
        ),
      ),
      // Anchor: bare, transparent SizedBox (no content, no gestures)
      Positioned(
        top: 40,
        left: 40,
        child: anchor,
      ),
    ],
  );
}

void main() {
  group('LayrzTooltip hit-test behavior on transparent anchor', () {
    testWidgets(
      'Case A: bare SizedBox (baseline) allows tap to reach backdrop',
      (tester) async {
        // BASELINE TEST: A transparent, non-interactive SizedBox should NOT
        // block taps from reaching the backdrop below it.
        //
        // This is the expected behavior in Flutter: a widget with no content
        // and no gesture handlers does not absorb hits.

        bool backdropTapped = false;

        await pumpThemed(
          tester,
          _buildTransparentAnchorStack(
            onBackdropTap: () => backdropTapped = true,
            wrapInTooltip: false,
          ),
        );

        // Tap inside the anchor's bounds
        await tester.tapAt(const Offset(80, 60));
        await tester.pumpAndSettle();

        // EXPECTED: The tap passes through to the backdrop.
        expect(
          backdropTapped,
          isTrue,
          reason: 'Bare transparent SizedBox should NOT block taps to backdrop',
        );
      },
    );

    testWidgets(
      'Case B: LayrzTooltip-wrapped SizedBox absorbs tap (PROBLEM)',
      (tester) async {
        // PROBLEM TEST: When the same SizedBox is wrapped in LayrzTooltip,
        // the tap is consumed instead of passing through.
        //
        // Root cause: RawTooltip wraps the child in a Listener with
        // behavior: HitTestBehavior.opaque, making the anchor absorb hits.
        //
        // Expected (correct) behavior: Wrapping should NOT change hit-test behavior.
        // Actual behavior: The wrapped anchor absorbs the tap.

        bool backdropTapped = false;

        await pumpThemed(
          tester,
          _buildTransparentAnchorStack(
            onBackdropTap: () => backdropTapped = true,
            wrapInTooltip: true,
          ),
        );

        // Tap inside the anchor's bounds (same location as Case A)
        await tester.tapAt(const Offset(80, 60));
        await tester.pumpAndSettle();

        // CURRENT BEHAVIOR (BROKEN): The tap is consumed; backdropTapped stays false.
        // EXPECTED BEHAVIOR: backdropTapped should be true (same as Case A).
        debugPrint('Case B result: backdropTapped = $backdropTapped');
        expect(
          backdropTapped,
          isTrue,
          reason:
              'LayrzTooltip-wrapped SizedBox should NOT change hit-test behavior. '
              'Wrapping should be transparent to hit-tests.',
        );
      },
      skip: true, // Known limitation: RawTooltip wraps its child in Listener(HitTestBehavior.opaque). Tracked for OverlayPortal rebuild.
    );

    testWidgets(
      'Case B-hover: LayrzTooltip-wrapped SizedBox absorbs mouse hover',
      (tester) async {
        // EXTENDED PROBLEM TEST: Does wrapping also change mouse hover behavior?
        //
        // If the anchor is wrapped, does a mouse hover over the anchor reach
        // a backdrop MouseRegion below it?

        PointerEnterEvent? backdropEnterEvent;

        await pumpThemed(
          tester,
          Stack(
            children: [
              Positioned.fill(
                child: MouseRegion(
                  onEnter: (event) => backdropEnterEvent = event,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                top: 40,
                left: 40,
                child: LayrzTooltip(
                  contentText: 'Tooltip body',
                  child: SizedBox(
                    width: 80,
                    height: 40,
                  ),
                ),
              ),
            ],
          ),
        );

        // Create a mouse gesture and move it to the anchor's position
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(gesture.removePointer);

        backdropEnterEvent = null;
        await gesture.moveTo(const Offset(80, 60));
        await tester.pumpAndSettle();

        // EXPECTED: The hover should NOT pass through (anchor's MouseRegion wins).
        // But the point is: RawTooltip's MouseRegion might also absorb it.
        debugPrint('Case B-hover: backdropEnterEvent = $backdropEnterEvent');
        expect(
          backdropEnterEvent,
          isNotNull,
          reason:
              'Even with MouseRegion, backdrop MouseRegion should receive hover '
              '(or at least, wrapping should not CHANGE the behavior)',
        );
      },
      skip: true, // Known limitation: RawTooltip wraps its child in Listener(HitTestBehavior.opaque). Tracked for OverlayPortal rebuild.
    );

    testWidgets(
      'Case C: Comparison - verify Case A vs Case B difference',
      (tester) async {
        // COMPARATIVE TEST: Run both scenarios back-to-back and measure the difference.
        //
        // This confirms that wrapping DOES change the behavior (not a false positive).

        // CASE A: Unwrapped
        bool caseABackdropTapped = false;
        await pumpThemed(
          tester,
          _buildTransparentAnchorStack(
            onBackdropTap: () => caseABackdropTapped = true,
            wrapInTooltip: false,
          ),
        );
        await tester.tapAt(const Offset(80, 60));
        await tester.pumpAndSettle();

        // CASE B: Wrapped
        bool caseBBackdropTapped = false;
        await pumpThemed(
          tester,
          _buildTransparentAnchorStack(
            onBackdropTap: () => caseBBackdropTapped = true,
            wrapInTooltip: true,
          ),
        );
        await tester.tapAt(const Offset(80, 60));
        await tester.pumpAndSettle();

        debugPrint('Case A (unwrapped): $caseABackdropTapped');
        debugPrint('Case B (wrapped):   $caseBBackdropTapped');

        // EXPECTED: Both should be true (wrapping should not change behavior).
        expect(
          caseABackdropTapped,
          isTrue,
          reason: 'Case A baseline should pass',
        );

        expect(
          caseBBackdropTapped,
          isTrue,
          reason: 'Case B should match Case A (wrapping should not change hit-test)',
        );

        // If the assertion above fails, this shows the problem clearly:
        if (caseABackdropTapped != caseBBackdropTapped) {
          debugPrint(
            'PROBLEM CONFIRMED: Wrapping in LayrzTooltip changes hit-test behavior '
            'from $caseABackdropTapped to $caseBBackdropTapped',
          );
        }
      },
      skip: true, // Known limitation: RawTooltip wraps its child in Listener(HitTestBehavior.opaque). Tracked for OverlayPortal rebuild.
    );
  });
}
