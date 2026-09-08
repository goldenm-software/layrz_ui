import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  final tokens = LayrzTokens.light();

  LayrzContextMenuLayoutDelegate buildDelegate({
    required Rect anchorRect,
    Offset? position,
    required Size overlaySize,
    double? maxHeight,
  }) {
    return LayrzContextMenuLayoutDelegate(
      anchorRect: anchorRect,
      position: position,
      overlaySize: overlaySize,
      tokens: tokens,
      maxHeight: maxHeight,
    );
  }

  group('getPositionForChild — pointer anchoring', () {
    test('places the panel top-left exactly at the pointer when it fits', () {
      const anchorRect = Rect.fromLTWH(50, 50, 300, 200);
      const pointerLocal = Offset(120, 80);
      const overlaySize = Size(800, 600);
      const childSize = Size(160, 120);

      final delegate = buildDelegate(
        anchorRect: anchorRect,
        position: pointerLocal,
        overlaySize: overlaySize,
      );

      final position = delegate.getPositionForChild(overlaySize, childSize);

      // Pointer in overlay coordinates == anchorRect.topLeft + position.
      final expectedPointer = anchorRect.topLeft + pointerLocal;
      expect(position, Offset(expectedPointer.dx, expectedPointer.dy));
    });

    test('falls back to anchorRect.topLeft when position is null', () {
      const anchorRect = Rect.fromLTWH(30, 40, 10, 10);
      const overlaySize = Size(800, 600);
      const childSize = Size(100, 80);

      final delegate = buildDelegate(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
      );

      final position = delegate.getPositionForChild(overlaySize, childSize);
      expect(position, anchorRect.topLeft);
    });

    test('flips horizontally when the preferred placement overflows the right edge', () {
      const overlaySize = Size(400, 600);
      // Pointer near the right edge — a 160-wide panel placed to the right
      // of it would overflow.
      const anchorRect = Rect.fromLTWH(0, 0, 0, 0);
      const pointerLocal = Offset(380, 100);
      const childSize = Size(160, 80);

      final delegate = buildDelegate(
        anchorRect: anchorRect,
        position: pointerLocal,
        overlaySize: overlaySize,
      );

      final position = delegate.getPositionForChild(overlaySize, childSize);

      // Flipped: panel's right edge lands at the pointer instead of its left edge.
      expect(position.dx, pointerLocal.dx - childSize.width);
      expect(position.dy, pointerLocal.dy);
    });

    test('flips vertically when the preferred placement overflows the bottom edge', () {
      const overlaySize = Size(400, 600);
      const anchorRect = Rect.fromLTWH(0, 0, 0, 0);
      const pointerLocal = Offset(100, 580);
      const childSize = Size(120, 100);

      final delegate = buildDelegate(
        anchorRect: anchorRect,
        position: pointerLocal,
        overlaySize: overlaySize,
      );

      final position = delegate.getPositionForChild(overlaySize, childSize);

      expect(position.dx, pointerLocal.dx);
      expect(position.dy, pointerLocal.dy - childSize.height);
    });

    test('flips on both axes when the pointer is at the bottom-right corner', () {
      const overlaySize = Size(400, 600);
      const anchorRect = Rect.fromLTWH(0, 0, 0, 0);
      const pointerLocal = Offset(395, 595);
      const childSize = Size(120, 100);

      final delegate = buildDelegate(
        anchorRect: anchorRect,
        position: pointerLocal,
        overlaySize: overlaySize,
      );

      final position = delegate.getPositionForChild(overlaySize, childSize);

      expect(position.dx, pointerLocal.dx - childSize.width);
      expect(position.dy, pointerLocal.dy - childSize.height);
    });

    test('clamps into overlay bounds when the panel is larger than available room on every side', () {
      const overlaySize = Size(200, 200);
      const anchorRect = Rect.fromLTWH(0, 0, 0, 0);
      const pointerLocal = Offset(10, 10);
      // Panel bigger than the overlay itself.
      const childSize = Size(500, 500);

      final delegate = buildDelegate(
        anchorRect: anchorRect,
        position: pointerLocal,
        overlaySize: overlaySize,
      );

      final position = delegate.getPositionForChild(overlaySize, childSize);

      expect(position.dx, 0.0);
      expect(position.dy, 0.0);
    });
  });

  group('getConstraintsForChild', () {
    test('bounds width and height to the overlay size minus padding when maxHeight is null', () {
      const overlaySize = Size(800, 600);
      final delegate = buildDelegate(
        anchorRect: const Rect.fromLTWH(0, 0, 0, 0),
        position: Offset.zero,
        overlaySize: overlaySize,
      );

      final constraints = delegate.getConstraintsForChild(const BoxConstraints());

      final horizontalPadding = 2 * tokens.spacing.sp2;
      final verticalPadding = 2 * tokens.spacing.sp2;
      expect(constraints.maxWidth, overlaySize.width - horizontalPadding);
      expect(constraints.maxHeight, overlaySize.height - verticalPadding);
      expect(constraints.minWidth, 0.0);
      expect(constraints.minHeight, 0.0);
    });

    test('clamps maxHeight to the smaller of the explicit value and available space', () {
      const overlaySize = Size(800, 600);
      final delegate = buildDelegate(
        anchorRect: const Rect.fromLTWH(0, 0, 0, 0),
        position: Offset.zero,
        overlaySize: overlaySize,
        maxHeight: 50.0,
      );

      final constraints = delegate.getConstraintsForChild(const BoxConstraints());
      expect(constraints.maxHeight, 50.0);
    });
  });

  group('shouldRelayout', () {
    test('returns true when anchorRect changes', () {
      final a = buildDelegate(
        anchorRect: const Rect.fromLTWH(0, 0, 10, 10),
        position: Offset.zero,
        overlaySize: const Size(400, 400),
      );
      final b = buildDelegate(
        anchorRect: const Rect.fromLTWH(5, 5, 10, 10),
        position: Offset.zero,
        overlaySize: const Size(400, 400),
      );
      expect(a.shouldRelayout(b), isTrue);
    });

    test('returns false when nothing relevant changes', () {
      final a = buildDelegate(
        anchorRect: const Rect.fromLTWH(0, 0, 10, 10),
        position: const Offset(5, 5),
        overlaySize: const Size(400, 400),
      );
      final b = buildDelegate(
        anchorRect: const Rect.fromLTWH(0, 0, 10, 10),
        position: const Offset(5, 5),
        overlaySize: const Size(400, 400),
      );
      expect(a.shouldRelayout(b), isFalse);
    });

    test('returns true when position changes', () {
      final a = buildDelegate(
        anchorRect: const Rect.fromLTWH(0, 0, 10, 10),
        position: const Offset(5, 5),
        overlaySize: const Size(400, 400),
      );
      final b = buildDelegate(
        anchorRect: const Rect.fromLTWH(0, 0, 10, 10),
        position: const Offset(6, 5),
        overlaySize: const Size(400, 400),
      );
      expect(a.shouldRelayout(b), isTrue);
    });
  });
}
