import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/buttons/src/button_tooltip_position.dart';
import 'package:layrz_ui/constants/constants.dart';

void main() {
  group('layrzButtonTooltipPosition', () {
    /// Helper to create a TooltipPositionContext with sensible defaults.
    ///
    /// Note: The Flutter SDK hardcodes verticalOffset to 0.0 when using a
    /// positionDelegate, so tests use 0.0 to match actual runtime behavior.
    TooltipPositionContext createContext({
      required Offset target,
      required Size targetSize,
      required Size tooltipSize,
      required Size overlaySize,
      double verticalOffset = 0.0,
    }) {
      return TooltipPositionContext(
        target: target,
        targetSize: targetSize,
        tooltipSize: tooltipSize,
        verticalOffset: verticalOffset,
        overlaySize: overlaySize,
      );
    }

    test('centres tooltip horizontally on target', () {
      // Target at 100, 200 with width 80; tooltip width 120.
      // Correct centring: 100 (target centre) - 60 (half tooltip width) = 40.
      final context = createContext(
        target: const Offset(100, 200),
        targetSize: Size(80, kLayrzButtonHeight),
        tooltipSize: const Size(120, 30),
        overlaySize: const Size(400, 600),
      );

      final position = layrzButtonTooltipPosition(context);

      expect(position.dx, 40);
    });

    test('positions tooltip below target with correct vertical gap', () {
      // Target at 100, 200 (centre) with height kLayrzButtonHeight.
      // Target bottom edge: 200 + (kLayrzButtonHeight / 2).
      // Tooltip top: that + kLayrzButtonTooltipVerticalOffset.
      final context = createContext(
        target: const Offset(100, 200),
        targetSize: Size(80, kLayrzButtonHeight),
        tooltipSize: const Size(120, 30),
        overlaySize: const Size(400, 600),
      );

      final position = layrzButtonTooltipPosition(context);

      final expectedY = 200 + (kLayrzButtonHeight / 2) + kLayrzButtonTooltipVerticalOffset;
      expect(position.dy, expectedY);
    });

    test(
      'applies kLayrzButtonTooltipVerticalOffset gap from target bottom edge '
      '(SDK supplies verticalOffset: 0.0)',
      () {
        // Verify that the vertical gap equals kLayrzButtonTooltipVerticalOffset
        // measured from the target's bottom edge, independent of context.verticalOffset
        // (which the SDK hardcodes to 0.0 when using a positionDelegate).
        // This test would have caught the original bug where the gap was missing.
        final targetCenter = 200.0;
        final targetHeight = kLayrzButtonHeight;

        final context = createContext(
          target: Offset(100, targetCenter),
          targetSize: Size(80, targetHeight),
          tooltipSize: const Size(120, 30),
          overlaySize: const Size(400, 600),
          verticalOffset: 0.0, // What the SDK actually provides.
        );

        final position = layrzButtonTooltipPosition(context);

        // Expected: target center + half-height + the design token gap.
        final expectedY = targetCenter + (targetHeight / 2) + kLayrzButtonTooltipVerticalOffset;
        expect(position.dy, expectedY);
      },
    );

    test('clamps left edge when tooltip would overflow left', () {
      // Overlay width 200, tooltip width 120.
      // Target at 30 (centre): 30 - 60 = -30 (would overflow).
      // Clamped to 0.
      final context = createContext(
        target: const Offset(30, 200),
        targetSize: Size(80, kLayrzButtonHeight),
        tooltipSize: const Size(120, 30),
        overlaySize: const Size(200, 600),
      );

      final position = layrzButtonTooltipPosition(context);

      expect(position.dx, 0);
    });

    test('clamps right edge when tooltip would overflow right', () {
      // Overlay width 200, tooltip width 120.
      // Target at 170 (centre): 170 - 60 = 110. Right edge: 110 + 120 = 230 (exceeds 200).
      // Clamped to 80 (200 - 120).
      final context = createContext(
        target: const Offset(170, 200),
        targetSize: Size(80, kLayrzButtonHeight),
        tooltipSize: const Size(120, 30),
        overlaySize: const Size(200, 600),
      );

      final position = layrzButtonTooltipPosition(context);

      expect(position.dx, 80);
    });

    test('flips tooltip above target when below would overflow bottom', () {
      // Target at 550 (centre) with height kLayrzButtonHeight. Tooltip height 30.
      // Below: 550 + (kLayrzButtonHeight / 2) + kLayrzButtonTooltipVerticalOffset.
      // Bottom edge: that + 30. If > 600 (overlay height), flip above.
      // Flipped above: 550 - (kLayrzButtonHeight / 2) - 30 - kLayrzButtonTooltipVerticalOffset.
      final context = createContext(
        target: const Offset(100, 550),
        targetSize: Size(80, kLayrzButtonHeight),
        tooltipSize: const Size(120, 30),
        overlaySize: const Size(400, 600),
      );

      final position = layrzButtonTooltipPosition(context);

      final expectedY = 550 - (kLayrzButtonHeight / 2) - 30 - kLayrzButtonTooltipVerticalOffset;
      expect(position.dy, expectedY);
    });

    test('tooltip stays on screen when flipped above', () {
      // Verify the flipped position places the tooltip fully within bounds.
      final context = createContext(
        target: const Offset(100, 550),
        targetSize: Size(80, kLayrzButtonHeight),
        tooltipSize: const Size(120, 30),
        overlaySize: const Size(400, 600),
      );

      final position = layrzButtonTooltipPosition(context);

      // Tooltip should be above the target.
      expect(position.dy, lessThan(550 - 20)); // 550 - 20 is target's top edge.
      // Bottom edge should not exceed overlay height.
      expect(position.dy + 30, lessThanOrEqualTo(600));
    });

    test('centres wider tooltip on target without drift', () {
      // Tooltip wider than target. Target 100 (centre), width 40; tooltip width 200.
      // Correct centring: 100 - 100 = 0.
      final context = createContext(
        target: const Offset(100, 200),
        targetSize: const Size(40, 40),
        tooltipSize: const Size(200, 30),
        overlaySize: const Size(400, 600),
      );

      final position = layrzButtonTooltipPosition(context);

      expect(position.dx, 0);
    });

    test('gap is non-zero and equals design token (SDK supplies 0.0 offset)', () {
      // This test would have caught the original bug where context.verticalOffset
      // (which is always 0.0) was used instead of kLayrzButtonTooltipVerticalOffset.
      // Verify the gap is actually non-zero and matches our design constant.
      expect(kLayrzButtonTooltipVerticalOffset, isNot(0.0));

      final context = createContext(
        target: const Offset(100, 200),
        targetSize: Size(80, kLayrzButtonHeight),
        tooltipSize: const Size(120, 30),
        overlaySize: const Size(400, 600),
        verticalOffset: 0.0, // SDK always passes 0.0
      );

      final position = layrzButtonTooltipPosition(context);

      // The gap should be our design constant, not zero.
      final gapFromBottomEdge = position.dy - (200 + (kLayrzButtonHeight / 2));
      expect(gapFromBottomEdge, kLayrzButtonTooltipVerticalOffset);
      expect(gapFromBottomEdge, isNot(0.0));
    });

    test('prefers below when both below and above fit', () {
      // Target in the middle of a tall overlay.
      // Below: 300 + (kLayrzButtonHeight / 2) + kLayrzButtonTooltipVerticalOffset.
      // Still well within 800. Should position below, not above.
      final context = createContext(
        target: const Offset(100, 300),
        targetSize: Size(80, kLayrzButtonHeight),
        tooltipSize: const Size(120, 30),
        overlaySize: const Size(400, 800),
      );

      final position = layrzButtonTooltipPosition(context);

      // Below would be 300 + (height/2) + gap.
      final expectedBelow = 300 + (kLayrzButtonHeight / 2) + kLayrzButtonTooltipVerticalOffset;
      expect(position.dy, expectedBelow);
    });

    test('geometry does not depend on kLayrzButtonHeight constant', () {
      // This test verifies that the positioning logic uses measured context
      // values, not hardcoded constants. If the function ever reverted to using
      // kLayrzButtonHeight, this test would catch it.
      //
      // We use a non-standard target height (not 40) to ensure the function
      // relies on context.targetSize.height, not kLayrzButtonHeight.
      final context = createContext(
        target: const Offset(100, 200),
        targetSize: const Size(80, 60), // Not 40 (kLayrzButtonHeight value).
        tooltipSize: const Size(120, 30),
        overlaySize: const Size(400, 600),
      );

      final position = layrzButtonTooltipPosition(context);

      // Expected: 200 + 30 (half of non-standard height 60) + gap.
      final expectedY = 200 + 30 + kLayrzButtonTooltipVerticalOffset;
      expect(position.dy, expectedY);
      // If the function used kLayrzButtonHeight (40) it would compute
      // 200 + 20 + gap, which would fail this assertion.
    });
  });
}
