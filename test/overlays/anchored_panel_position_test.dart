import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  final tokens = LayrzTokens.light();
  final sp2 = tokens.spacing.sp2;

  LayrzAnchoredPanelLayoutDelegate buildDelegate({
    required Rect anchorRect,
    required LayrzPreferredSide preferredSide,
    LayrzAnchoredPanelAlignment alignment = LayrzAnchoredPanelAlignment.start,
    LayrzAnchoredPanelWidthPolicy widthPolicy = LayrzAnchoredPanelWidthPolicy.contentSized,
    LayrzAnchoredPanelWidthBounds widthBounds = const LayrzAnchoredPanelWidthBounds(minWidth: 60.0, maxWidth: 200.0),
    required Size overlaySize,
    double gap = 8.0,
    double? maxHeight,
    void Function(bool flippedUp)? onFlipped,
  }) {
    return LayrzAnchoredPanelLayoutDelegate(
      anchorRect: anchorRect,
      preferredSide: preferredSide,
      alignment: alignment,
      widthPolicy: widthPolicy,
      widthBounds: widthBounds,
      gap: gap,
      overlaySize: overlaySize,
      tokens: tokens,
      maxHeight: maxHeight,
      onFlipped: onFlipped,
    );
  }

  group('getPositionForChild — each side fits', () {
    // Anchor sits comfortably away from every edge of a 400x600 overlay, so a
    // small 60x40 child fits on any of the four sides.
    const anchorRect = Rect.fromLTWH(150, 250, 100, 40);
    const overlaySize = Size(400, 600);
    const childSize = Size(60, 40);

    test('bottom places below and reports onFlipped(false)', () {
      bool? flipped;
      final delegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.bottom,
        overlaySize: overlaySize,
        gap: 8.0,
        onFlipped: (v) => flipped = v,
      );

      final offset = delegate.getPositionForChild(overlaySize, childSize);

      expect(offset.dy, closeTo(anchorRect.bottom + 8.0, 0.01));
      expect(flipped, isFalse);
    });

    test('top places above and reports onFlipped(false)', () {
      bool? flipped;
      final delegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.top,
        overlaySize: overlaySize,
        gap: 8.0,
        onFlipped: (v) => flipped = v,
      );

      final offset = delegate.getPositionForChild(overlaySize, childSize);

      expect(offset.dy, closeTo(anchorRect.top - childSize.height - 8.0, 0.01));
      expect(flipped, isFalse);
    });

    test('left places to the left and reports onFlipped(false)', () {
      bool? flipped;
      final delegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.left,
        overlaySize: overlaySize,
        gap: 8.0,
        onFlipped: (v) => flipped = v,
      );

      final offset = delegate.getPositionForChild(overlaySize, childSize);

      expect(offset.dx, closeTo(anchorRect.left - childSize.width - 8.0, 0.01));
      expect(flipped, isFalse);
    });

    test('right places to the right and reports onFlipped(false)', () {
      bool? flipped;
      final delegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.right,
        overlaySize: overlaySize,
        gap: 8.0,
        onFlipped: (v) => flipped = v,
      );

      final offset = delegate.getPositionForChild(overlaySize, childSize);

      expect(offset.dx, closeTo(anchorRect.right + 8.0, 0.01));
      expect(flipped, isFalse);
    });
  });

  group('getPositionForChild — flips to the opposite side when it does not fit', () {
    const overlaySize = Size(400, 600);
    const childSize = Size(60, 40);

    test('bottom flips to top and reports onFlipped(true)', () {
      // Anchor near the overlay bottom: there is no room below.
      const anchorRect = Rect.fromLTWH(150, 580, 100, 10);
      bool? flipped;
      final delegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.bottom,
        overlaySize: overlaySize,
        gap: 8.0,
        onFlipped: (v) => flipped = v,
      );

      final offset = delegate.getPositionForChild(overlaySize, childSize);

      expect(offset.dy, closeTo(anchorRect.top - childSize.height - 8.0, 0.01));
      expect(flipped, isTrue);
    });

    test('top flips to bottom and reports onFlipped(true)', () {
      // Anchor near the overlay top: there is no room above.
      const anchorRect = Rect.fromLTWH(150, 5, 100, 10);
      bool? flipped;
      final delegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.top,
        overlaySize: overlaySize,
        gap: 8.0,
        onFlipped: (v) => flipped = v,
      );

      final offset = delegate.getPositionForChild(overlaySize, childSize);

      expect(offset.dy, closeTo(anchorRect.bottom + 8.0, 0.01));
      expect(flipped, isTrue);
    });

    test('left flips to right and reports onFlipped(true)', () {
      // Anchor near the overlay's left edge: there is no room to the left.
      const anchorRect = Rect.fromLTWH(5, 250, 10, 40);
      bool? flipped;
      final delegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.left,
        overlaySize: overlaySize,
        gap: 8.0,
        onFlipped: (v) => flipped = v,
      );

      final offset = delegate.getPositionForChild(overlaySize, childSize);

      expect(offset.dx, closeTo(anchorRect.right + 8.0, 0.01));
      expect(flipped, isTrue);
    });

    test('right flips to left and reports onFlipped(true)', () {
      // Anchor near the overlay's right edge: there is no room to the right.
      const anchorRect = Rect.fromLTWH(370, 250, 20, 40);
      bool? flipped;
      final delegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.right,
        overlaySize: overlaySize,
        gap: 8.0,
        onFlipped: (v) => flipped = v,
      );

      final offset = delegate.getPositionForChild(overlaySize, childSize);

      expect(offset.dx, closeTo(anchorRect.left - childSize.width - 8.0, 0.01));
      expect(flipped, isTrue);
    });
  });

  group('getPositionForChild — neither side fits (behaviour change, §8.2)', () {
    test(
      'an over-tall panel with preferredSide.bottom now lands on top and clamps to the overlay top, '
      'not the overlay bottom',
      () {
        // Reachable today via LayrzDurationInput's desktop panel (maxHeight: 400,
        // preferredSide defaults to bottom) on a short viewport. Neither "below"
        // nor "above" fully fits, so the resolution is decided by the unconditional
        // flip rather than a third fallback.
        const anchorRect = Rect.fromLTWH(150, 100, 100, 40);
        const overlaySize = Size(400, 600);
        const childSize = Size(60, 480);

        bool? flipped;
        final delegate = buildDelegate(
          anchorRect: anchorRect,
          preferredSide: LayrzPreferredSide.bottom,
          overlaySize: overlaySize,
          gap: 8.0,
          onFlipped: (v) => flipped = v,
        );

        final offset = delegate.getPositionForChild(overlaySize, childSize);

        // Below doesn't fit (140 + 8 + 480 = 628 > 600) and above doesn't fit either
        // (100 - 8 - 480 = -388 < 0). The unconditional flip still picks top, which
        // clamps to the overlay's top edge (0.0) — previously this clamped to the
        // overlay's bottom-most valid position (600 - 480 = 120).
        expect(offset.dy, closeTo(0.0, 0.01));
        expect(flipped, isTrue);
      },
    );
  });

  group('getPositionForChild — cross-axis alignment', () {
    const overlaySize = Size(400, 600);

    test('alignment values on a vertical side (top/bottom) move the X axis', () {
      const anchorRect = Rect.fromLTWH(150, 250, 100, 40);
      const childSize = Size(60, 40);

      final start = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.bottom,
        alignment: LayrzAnchoredPanelAlignment.start,
        overlaySize: overlaySize,
      ).getPositionForChild(overlaySize, childSize);
      final center = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.bottom,
        alignment: LayrzAnchoredPanelAlignment.center,
        overlaySize: overlaySize,
      ).getPositionForChild(overlaySize, childSize);
      final end = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.bottom,
        alignment: LayrzAnchoredPanelAlignment.end,
        overlaySize: overlaySize,
      ).getPositionForChild(overlaySize, childSize);

      expect(start.dx, closeTo(anchorRect.left, 0.01));
      expect(center.dx, closeTo(anchorRect.center.dx - childSize.width / 2, 0.01));
      expect(end.dx, closeTo(anchorRect.right - childSize.width, 0.01));
      // The Y axis (the main axis for a vertical side) is unaffected by alignment.
      expect(start.dy, closeTo(center.dy, 0.01));
      expect(center.dy, closeTo(end.dy, 0.01));
    });

    test('alignment values on a horizontal side (left/right) move the Y axis', () {
      const anchorRect = Rect.fromLTWH(150, 200, 100, 100);
      const childSize = Size(60, 40);

      final start = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.right,
        alignment: LayrzAnchoredPanelAlignment.start,
        overlaySize: overlaySize,
      ).getPositionForChild(overlaySize, childSize);
      final center = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.right,
        alignment: LayrzAnchoredPanelAlignment.center,
        overlaySize: overlaySize,
      ).getPositionForChild(overlaySize, childSize);
      final end = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.right,
        alignment: LayrzAnchoredPanelAlignment.end,
        overlaySize: overlaySize,
      ).getPositionForChild(overlaySize, childSize);

      expect(start.dy, closeTo(anchorRect.top, 0.01));
      expect(center.dy, closeTo(anchorRect.center.dy - childSize.height / 2, 0.01));
      expect(end.dy, closeTo(anchorRect.bottom - childSize.height, 0.01));
      // The X axis (the main axis for a horizontal side) is unaffected by alignment.
      expect(start.dx, closeTo(center.dx, 0.01));
      expect(center.dx, closeTo(end.dx, 0.01));
    });
  });

  group('getConstraintsForChild — §15 width clamp', () {
    test('contentSized width is clamped to the overlay budget on a narrow-but-sufficient overlay', () {
      const overlaySize = Size(400, 600);
      const anchorRect = Rect.fromLTWH(150, 250, 100, 40);
      final delegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.bottom,
        widthPolicy: LayrzAnchoredPanelWidthPolicy.contentSized,
        widthBounds: const LayrzAnchoredPanelWidthBounds(minWidth: 280.0, maxWidth: 480.0),
        overlaySize: overlaySize,
      );

      final constraints = delegate.getConstraintsForChild(const BoxConstraints());

      expect(constraints.maxWidth, lessThanOrEqualTo(overlaySize.width - 2 * sp2));
      expect(constraints.minWidth, lessThanOrEqualTo(constraints.maxWidth));
    });

    test('contentSized width does not assert on an overlay narrower than minWidth', () {
      const overlaySize = Size(200, 600);
      const anchorRect = Rect.fromLTWH(20, 250, 100, 40);

      final delegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.bottom,
        widthPolicy: LayrzAnchoredPanelWidthPolicy.contentSized,
        widthBounds: const LayrzAnchoredPanelWidthBounds(minWidth: 280.0, maxWidth: 480.0),
        overlaySize: overlaySize,
      );

      final constraints = delegate.getConstraintsForChild(const BoxConstraints());
      final expectedWidth = overlaySize.width - 2 * sp2;

      expect(constraints.minWidth, closeTo(expectedWidth, 0.01));
      expect(constraints.maxWidth, closeTo(expectedWidth, 0.01));
    });

    test('matchAnchor with a wide anchor and a horizontal side does not assert', () {
      const overlaySize = Size(400, 600);
      // A 300-wide anchor centred in a 400-wide overlay leaves only ~42px of room
      // on either side — far less than the anchor's own width.
      const anchorRect = Rect.fromLTWH(50, 250, 300, 40);

      final delegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.right,
        widthPolicy: LayrzAnchoredPanelWidthPolicy.matchAnchor,
        overlaySize: overlaySize,
      );

      final constraints = delegate.getConstraintsForChild(const BoxConstraints());

      expect(constraints.minWidth, lessThanOrEqualTo(constraints.maxWidth));
      expect(constraints.maxWidth, lessThan(anchorRect.width));
    });
  });

  // Of the four `.clamp(0.0, double.infinity)` negative-guards in
  // `getConstraintsForChild`, only the `:170` guard (horizontalBudget) is
  // observable by deleting it in isolation — the test below catches it.
  // The other three guards are masked by construction and stay green even
  // with their clamp deleted on its own; this was verified against the
  // running delegate, not assumed:
  //   - `:178`/`:179` (roomLeft/roomRight): `mainAxisRoom = math.max(roomLeft,
  //     roomRight)`. Whichever sibling room still has its clamp keeps
  //     `mainAxisRoom >= 0` regardless of how negative the unclamped room
  //     goes, since `max` never selects the more-negative operand. They are
  //     defensive/redundant-by-design given the sibling clamp, not
  //     uncovered.
  //   - `:192` (availableHeight): `constrainedHeight` is re-clamped
  //     unconditionally two lines later
  //     (`(... ).clamp(0.0, double.infinity)`), which subsumes `:192`'s own
  //     clamp in every case, `maxHeight` set or not.
  // The four tests still assert the correct BoxConstraints invariants for
  // these degenerate shapes and are kept as regression coverage.
  group('getConstraintsForChild — degenerate overlay negative-guards', () {
    test(
      'an overlay narrower than 2*sp2 clamps maxWidth to 0.0 instead of going negative',
      () {
        // width = 10 < 2*sp2 (20.0), so horizontalBudget would be negative
        // without the clamp at the width-budget guard.
        const overlaySize = Size(10, 600);
        const anchorRect = Rect.fromLTWH(2, 250, 5, 40);

        final delegate = buildDelegate(
          anchorRect: anchorRect,
          preferredSide: LayrzPreferredSide.bottom,
          overlaySize: overlaySize,
        );

        final constraints = delegate.getConstraintsForChild(const BoxConstraints());

        expect(constraints.maxWidth, 0.0);
        expect(constraints.minWidth, lessThanOrEqualTo(constraints.maxWidth));
        expect(constraints.minHeight, lessThanOrEqualTo(constraints.maxHeight));
        expect(constraints.minWidth, greaterThanOrEqualTo(0.0));
        expect(constraints.maxWidth, greaterThanOrEqualTo(0.0));
        expect(constraints.minHeight, greaterThanOrEqualTo(0.0));
        expect(constraints.maxHeight, greaterThanOrEqualTo(0.0));
      },
    );

    test(
      'a horizontal-side anchor flush against the left edge does not drive roomLeft negative',
      () {
        // anchorRect.left == 0, so (anchorRect.left - gap) is -8 without the clamp.
        // preferredSide.left keeps this on the isHorizontal branch that computes
        // roomLeft/roomRight, unlike a vertical side which never reaches them.
        const overlaySize = Size(400, 600);
        const anchorRect = Rect.fromLTWH(0, 250, 100, 40);

        final delegate = buildDelegate(
          anchorRect: anchorRect,
          preferredSide: LayrzPreferredSide.left,
          overlaySize: overlaySize,
        );

        final constraints = delegate.getConstraintsForChild(const BoxConstraints());

        expect(constraints.minWidth, lessThanOrEqualTo(constraints.maxWidth));
        expect(constraints.maxWidth, greaterThanOrEqualTo(0.0));
        expect(constraints.minWidth, greaterThanOrEqualTo(0.0));
        expect(constraints.minHeight, lessThanOrEqualTo(constraints.maxHeight));
        expect(constraints.minHeight, greaterThanOrEqualTo(0.0));
        expect(constraints.maxHeight, greaterThanOrEqualTo(0.0));
      },
    );

    test(
      'a horizontal-side anchor flush against the right edge does not drive roomRight negative',
      () {
        // anchorRect.right == overlaySize.width, so
        // (overlaySize.width - anchorRect.right - gap) is -8 without the clamp.
        const overlaySize = Size(400, 600);
        const anchorRect = Rect.fromLTWH(300, 250, 100, 40);

        final delegate = buildDelegate(
          anchorRect: anchorRect,
          preferredSide: LayrzPreferredSide.right,
          overlaySize: overlaySize,
        );

        final constraints = delegate.getConstraintsForChild(const BoxConstraints());

        expect(constraints.minWidth, lessThanOrEqualTo(constraints.maxWidth));
        expect(constraints.maxWidth, greaterThanOrEqualTo(0.0));
        expect(constraints.minWidth, greaterThanOrEqualTo(0.0));
        expect(constraints.minHeight, lessThanOrEqualTo(constraints.maxHeight));
        expect(constraints.minHeight, greaterThanOrEqualTo(0.0));
        expect(constraints.maxHeight, greaterThanOrEqualTo(0.0));
      },
    );

    test(
      'an overlay shorter than 2*sp2 clamps maxHeight to 0.0 instead of going negative',
      () {
        // height = 10 < 2*sp2 (20.0), so availableHeight would be negative
        // without the clamp at the height-budget guard.
        const overlaySize = Size(400, 10);
        const anchorRect = Rect.fromLTWH(150, 2, 100, 5);

        final delegate = buildDelegate(
          anchorRect: anchorRect,
          preferredSide: LayrzPreferredSide.bottom,
          overlaySize: overlaySize,
        );

        final constraints = delegate.getConstraintsForChild(const BoxConstraints());

        expect(constraints.maxHeight, 0.0);
        expect(constraints.minHeight, lessThanOrEqualTo(constraints.maxHeight));
        expect(constraints.minWidth, lessThanOrEqualTo(constraints.maxWidth));
        expect(constraints.minWidth, greaterThanOrEqualTo(0.0));
        expect(constraints.maxWidth, greaterThanOrEqualTo(0.0));
        expect(constraints.minHeight, greaterThanOrEqualTo(0.0));
        expect(constraints.maxHeight, greaterThanOrEqualTo(0.0));
      },
    );
  });

  group('shouldRelayout', () {
    test('returns true when preferredSide changes', () {
      const anchorRect = Rect.fromLTWH(150, 250, 100, 40);
      const overlaySize = Size(400, 600);

      final oldDelegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.bottom,
        overlaySize: overlaySize,
      );
      final newDelegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.right,
        overlaySize: overlaySize,
      );

      expect(newDelegate.shouldRelayout(oldDelegate), isTrue);
    });

    test('returns false when nothing changes', () {
      const anchorRect = Rect.fromLTWH(150, 250, 100, 40);
      const overlaySize = Size(400, 600);

      final oldDelegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.bottom,
        overlaySize: overlaySize,
      );
      final newDelegate = buildDelegate(
        anchorRect: anchorRect,
        preferredSide: LayrzPreferredSide.bottom,
        overlaySize: overlaySize,
      );

      expect(newDelegate.shouldRelayout(oldDelegate), isFalse);
    });
  });
}
