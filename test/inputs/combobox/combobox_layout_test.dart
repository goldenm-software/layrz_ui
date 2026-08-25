import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/combobox/combobox_layout.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

void main() {
  final tokens = LayrzTokens.light();

  group('ComboBoxLayoutDelegate.getConstraintsForChild', () {
    test('width is tight to the anchor width', () {
      final delegate = ComboBoxLayoutDelegate(
        anchorRect: const Rect.fromLTWH(10, 10, 220, 40),
        overlaySize: const Size(800, 600),
        tokens: tokens,
        maxHeight: 300,
      );

      final constraints = delegate.getConstraintsForChild(const BoxConstraints());

      expect(constraints.minWidth, 220);
      expect(constraints.maxWidth, 220);
    });

    test('maxHeight is the requested cap when the overlay has ample room', () {
      final delegate = ComboBoxLayoutDelegate(
        anchorRect: const Rect.fromLTWH(10, 10, 220, 40),
        overlaySize: const Size(800, 1200),
        tokens: tokens,
        maxHeight: 300,
      );

      final constraints = delegate.getConstraintsForChild(const BoxConstraints());

      // 1200 - 2*sp2 (20) = 1180, well above the 300 cap — the cap wins.
      expect(constraints.maxHeight, 300);
      expect(constraints.minHeight, 0.0);
    });

    test('maxHeight shrinks to the overlay when the overlay is shorter than the cap', () {
      const overlayHeight = 250.0;
      final delegate = ComboBoxLayoutDelegate(
        anchorRect: const Rect.fromLTWH(10, 10, 220, 40),
        overlaySize: Size(800, overlayHeight),
        tokens: tokens,
        maxHeight: 300,
      );

      final constraints = delegate.getConstraintsForChild(const BoxConstraints());

      expect(constraints.maxHeight, overlayHeight - 2 * tokens.spacing.sp2);
    });

    test('maxHeight never goes negative when the overlay is smaller than the padding', () {
      final delegate = ComboBoxLayoutDelegate(
        anchorRect: const Rect.fromLTWH(10, 10, 220, 40),
        overlaySize: const Size(800, 4),
        tokens: tokens,
        maxHeight: 300,
      );

      final constraints = delegate.getConstraintsForChild(const BoxConstraints());

      expect(constraints.maxHeight, 0.0);
    });
  });

  group('ComboBoxLayoutDelegate.getPositionForChild', () {
    test('places the panel below the anchor with a 4px gap when there is room', () {
      final delegate = ComboBoxLayoutDelegate(
        anchorRect: const Rect.fromLTWH(10, 100, 220, 40),
        overlaySize: const Size(800, 1200),
        tokens: tokens,
        maxHeight: 300,
      );

      final offset = delegate.getPositionForChild(const Size(800, 1200), const Size(220, 150));

      expect(offset.dx, 10);
      expect(offset.dy, 144); // anchorRect.bottom (140) + 4px gap
    });

    test('flips above the anchor when there is no room below but room above', () {
      final delegate = ComboBoxLayoutDelegate(
        anchorRect: const Rect.fromLTWH(10, 550, 220, 40),
        overlaySize: const Size(800, 600),
        tokens: tokens,
        maxHeight: 300,
      );

      final offset = delegate.getPositionForChild(const Size(800, 600), const Size(220, 150));

      // anchorRect.top (550) - childSize.height (150) - 4px gap.
      expect(offset.dy, 396);
    });

    test('falls back to below when the panel fits neither above nor below', () {
      final delegate = ComboBoxLayoutDelegate(
        anchorRect: const Rect.fromLTWH(10, 300, 220, 40),
        overlaySize: const Size(800, 620),
        tokens: tokens,
        maxHeight: 300,
      );

      // A panel taller than the overlay itself fits nowhere; the delegate must
      // still return a finite, clamped offset rather than a negative one.
      final offset = delegate.getPositionForChild(const Size(800, 620), const Size(220, 700));

      expect(offset.dy, greaterThanOrEqualTo(0.0));
    });

    test('clamps the vertical offset so the panel never extends past the overlay bottom', () {
      final delegate = ComboBoxLayoutDelegate(
        anchorRect: const Rect.fromLTWH(10, 590, 220, 40),
        overlaySize: const Size(800, 600),
        tokens: tokens,
        maxHeight: 300,
      );

      final offset = delegate.getPositionForChild(const Size(800, 600), const Size(220, 150));

      expect(offset.dy, lessThanOrEqualTo(600 - 150));
    });

    test('x matches the anchor left edge', () {
      final delegate = ComboBoxLayoutDelegate(
        anchorRect: const Rect.fromLTWH(37, 100, 220, 40),
        overlaySize: const Size(800, 1200),
        tokens: tokens,
        maxHeight: 300,
      );

      final offset = delegate.getPositionForChild(const Size(800, 1200), const Size(220, 150));

      expect(offset.dx, 37);
    });
  });

  group('ComboBoxLayoutDelegate.shouldRelayout', () {
    const anchorRect = Rect.fromLTWH(10, 10, 220, 40);
    const overlaySize = Size(800, 600);

    test('returns false when nothing changed', () {
      final a = ComboBoxLayoutDelegate(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        tokens: tokens,
        maxHeight: 300,
      );
      final b = ComboBoxLayoutDelegate(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        tokens: tokens,
        maxHeight: 300,
      );

      expect(a.shouldRelayout(b), isFalse);
    });

    test('returns true when the anchor rect changed', () {
      final a = ComboBoxLayoutDelegate(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        tokens: tokens,
        maxHeight: 300,
      );
      final b = ComboBoxLayoutDelegate(
        anchorRect: const Rect.fromLTWH(20, 10, 220, 40),
        overlaySize: overlaySize,
        tokens: tokens,
        maxHeight: 300,
      );

      expect(a.shouldRelayout(b), isTrue);
    });

    test('returns true when the overlay size changed', () {
      final a = ComboBoxLayoutDelegate(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        tokens: tokens,
        maxHeight: 300,
      );
      final b = ComboBoxLayoutDelegate(
        anchorRect: anchorRect,
        overlaySize: const Size(900, 600),
        tokens: tokens,
        maxHeight: 300,
      );

      expect(a.shouldRelayout(b), isTrue);
    });

    test('returns true when the tokens changed', () {
      // LayrzTokens overrides `==` structurally, so two `.light()` calls compare
      // equal — the delegate must be given tokens that actually differ to exercise
      // this branch, via `copyWith` on the spacing sub-token.
      final differentTokens = tokens.copyWith(spacing: tokens.spacing.copyWith(sp2: 99));
      final a = ComboBoxLayoutDelegate(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        tokens: tokens,
        maxHeight: 300,
      );
      final b = ComboBoxLayoutDelegate(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        tokens: differentTokens,
        maxHeight: 300,
      );

      expect(a.shouldRelayout(b), isTrue);
    });

    test('returns true when maxHeight changed', () {
      final a = ComboBoxLayoutDelegate(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        tokens: tokens,
        maxHeight: 300,
      );
      final b = ComboBoxLayoutDelegate(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        tokens: tokens,
        maxHeight: 250,
      );

      expect(a.shouldRelayout(b), isTrue);
    });
  });
}
