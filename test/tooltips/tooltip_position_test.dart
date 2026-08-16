import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/tooltips.dart';

void main() {
  group('layrzTooltipPositionDelegate', () {
    test('bottom: centres horizontally on target', () {
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.bottom);
      final context = TooltipPositionContext(
        target: const Offset(100, 100), // Centre of anchor
        targetSize: const Size(50, 40), // Width and height
        tooltipSize: const Size(80, 20),
        overlaySize: const Size(400, 600),
        preferBelow: true,
        verticalOffset: 0,
      );

      final offset = delegate(context);

      // Horizontally: 100 - 80/2 = 60
      expect(offset.dx, closeTo(60.0, 0.01));

      // Vertically: 100 + 40/2 + 10 = 130
      expect(offset.dy, closeTo(130.0, 0.01));
    });

    test('bottom: flips above when overflow detected', () {
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.bottom);
      final context = TooltipPositionContext(
        target: const Offset(200, 580), // Near bottom
        targetSize: const Size(50, 40),
        tooltipSize: const Size(80, 30),
        overlaySize: const Size(400, 600),
        preferBelow: true,
        verticalOffset: 0,
      );

      final offset = delegate(context);

      // Would overflow below: 580 + 20 + 10 = 610 > 600, so flip above
      // Above: 580 - 20 - 30 - 10 = 520
      expect(offset.dy, closeTo(520.0, 0.01));
    });

    test('bottom: clamps horizontally at left edge', () {
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.bottom);
      final context = TooltipPositionContext(
        target: const Offset(20, 100), // Near left edge
        targetSize: const Size(50, 40),
        tooltipSize: const Size(80, 20),
        overlaySize: const Size(400, 600),
        preferBelow: true,
        verticalOffset: 0,
      );

      final offset = delegate(context);

      // Would go to 20 - 40 = -20, clamp to 0
      expect(offset.dx, closeTo(0.0, 0.01));
    });

    test('bottom: clamps horizontally at right edge', () {
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.bottom);
      final context = TooltipPositionContext(
        target: const Offset(380, 100), // Near right edge
        targetSize: const Size(50, 40),
        tooltipSize: const Size(80, 20),
        overlaySize: const Size(400, 600),
        preferBelow: true,
        verticalOffset: 0,
      );

      final offset = delegate(context);

      // Would go to 380 - 40 = 340, but max is 400 - 80 = 320, clamp to 320
      expect(offset.dx, closeTo(320.0, 0.01));
    });

    test('top: positions above the target', () {
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.top);
      final context = TooltipPositionContext(
        target: const Offset(200, 300),
        targetSize: const Size(50, 40),
        tooltipSize: const Size(80, 20),
        overlaySize: const Size(400, 600),
        preferBelow: true,
        verticalOffset: 0,
      );

      final offset = delegate(context);

      // Above: 300 - 20 - 20 - 10 = 250
      expect(offset.dy, closeTo(250.0, 0.01));
    });

    test('top: flips below when overflow detected', () {
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.top);
      final context = TooltipPositionContext(
        target: const Offset(200, 30), // Near top
        targetSize: const Size(50, 40),
        tooltipSize: const Size(80, 25),
        overlaySize: const Size(400, 600),
        preferBelow: true,
        verticalOffset: 0,
      );

      final offset = delegate(context);

      // Would go above: 30 - 20 - 25 - 10 = -25 < 0, so flip below
      // Below: 30 + 20 + 10 = 60
      expect(offset.dy, closeTo(60.0, 0.01));
    });

    test('left: positions to the left of the target', () {
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.left);
      final context = TooltipPositionContext(
        target: const Offset(300, 300),
        targetSize: const Size(50, 40),
        tooltipSize: const Size(80, 25),
        overlaySize: const Size(400, 600),
        preferBelow: true,
        verticalOffset: 0,
      );

      final offset = delegate(context);

      // Left: 300 - 25 - 80 - 10 = 185
      expect(offset.dx, closeTo(185.0, 0.01));

      // Vertically centred: 300 - 25/2 = 287.5
      expect(offset.dy, closeTo(287.5, 0.01));
    });

    test('left: flips right when overflow detected', () {
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.left);
      final context = TooltipPositionContext(
        target: const Offset(50, 300),
        targetSize: const Size(50, 40),
        tooltipSize: const Size(80, 25),
        overlaySize: const Size(400, 600),
        preferBelow: true,
        verticalOffset: 0,
      );

      final offset = delegate(context);

      // Would go left: 50 - 25 - 80 - 10 = -65 < 0, so flip right
      // Right: 50 + 25 + 10 = 85
      expect(offset.dx, closeTo(85.0, 0.01));
    });

    test('right: positions to the right of the target', () {
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.right);
      final context = TooltipPositionContext(
        target: const Offset(100, 300),
        targetSize: const Size(50, 40),
        tooltipSize: const Size(80, 25),
        overlaySize: const Size(400, 600),
        preferBelow: true,
        verticalOffset: 0,
      );

      final offset = delegate(context);

      // Right: 100 + 25 + 10 = 135
      expect(offset.dx, closeTo(135.0, 0.01));

      // Vertically centred: 300 - 25/2 = 287.5
      expect(offset.dy, closeTo(287.5, 0.01));
    });

    test('right: flips left when overflow detected', () {
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.right);
      final context = TooltipPositionContext(
        target: const Offset(350, 300),
        targetSize: const Size(50, 40),
        tooltipSize: const Size(80, 25),
        overlaySize: const Size(400, 600),
        preferBelow: true,
        verticalOffset: 0,
      );

      final offset = delegate(context);

      // Would go right: 350 + 25 + 10 + 80 = 465 > 400, so flip left
      // Left: 350 - 25 - 80 - 10 = 235
      expect(offset.dx, closeTo(235.0, 0.01));
    });

    test('bottom: handles tooltip larger than overlay horizontally', () {
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.bottom);
      final context = TooltipPositionContext(
        target: const Offset(200, 300),
        targetSize: const Size(50, 40),
        tooltipSize: const Size(500, 20), // Wider than overlay
        overlaySize: const Size(400, 600),
        preferBelow: true,
        verticalOffset: 0,
      );

      // Should not throw even though maxLeftOffset is negative.
      // Guards with math.max(0.0, overlaySize.width - tooltipSize.width).
      final offset = delegate(context);
      expect(offset, isNotNull);
      expect(offset.dx, closeTo(0.0, 0.01)); // Clamped to 0
    });

    test('top: handles tooltip larger than overlay vertically', () {
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.top);
      final context = TooltipPositionContext(
        target: const Offset(200, 300),
        targetSize: const Size(50, 40),
        tooltipSize: const Size(80, 700), // Taller than overlay
        overlaySize: const Size(400, 600),
        preferBelow: true,
        verticalOffset: 0,
      );

      // Should not throw; should still position and clamp.
      final offset = delegate(context);
      expect(offset, isNotNull);
    });

    test('left: clamps vertically at top edge', () {
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.left);
      final context = TooltipPositionContext(
        target: const Offset(200, 10), // Near top
        targetSize: const Size(50, 20),
        tooltipSize: const Size(80, 40),
        overlaySize: const Size(400, 600),
        preferBelow: true,
        verticalOffset: 0,
      );

      final offset = delegate(context);

      // Would go to 10 - 20 = -10, clamp to 0
      expect(offset.dy, closeTo(0.0, 0.01));
    });

    test('right: clamps vertically at bottom edge', () {
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.right);
      final context = TooltipPositionContext(
        target: const Offset(200, 590), // Near bottom
        targetSize: const Size(50, 20),
        tooltipSize: const Size(80, 40),
        overlaySize: const Size(400, 600),
        preferBelow: true,
        verticalOffset: 0,
      );

      final offset = delegate(context);

      // Would go to 590 - 20 = 570, but max is 600 - 40 = 560, clamp to 560
      expect(offset.dy, closeTo(560.0, 0.01));
    });

    test('bottom: matches button tooltip behaviour exactly', () {
      // This test locks in the exact behavior from button_tooltip_position.dart.
      // It must be byte-for-byte identical for the button refactor to be safe.
      final delegate = layrzTooltipPositionDelegate(LayrzTooltipPosition.bottom);

      // Test case from button: tooltip below target, centred horizontally.
      final context = TooltipPositionContext(
        target: const Offset(100, 100),
        targetSize: const Size(80, 45),
        tooltipSize: const Size(100, 30),
        overlaySize: const Size(300, 500),
        preferBelow: true,
        verticalOffset: 0,
      );

      final offset = delegate(context);

      // Horizontal: 100 - 50 = 50 (centred).
      // Max horizontal: 300 - 100 = 200.
      // Clamped: 50.
      expect(offset.dx, closeTo(50.0, 0.01));

      // Vertical: 100 + 22.5 + 10 = 132.5 (below with offset).
      expect(offset.dy, closeTo(132.5, 0.01));
    });
  });
}
