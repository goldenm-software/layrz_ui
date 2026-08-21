import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/tokens/tokens.dart';

/// Layout delegate for positioning the combobox overlay.
///
/// Positions the panel below or above the anchor, matching the anchor's width,
/// and clamping to overlay bounds. Flips above the anchor when there is insufficient
/// space below.
class ComboBoxLayoutDelegate extends SingleChildLayoutDelegate {
  /// The anchor widget's position and size.
  final Rect anchorRect;

  /// The overlay's full size.
  final Size overlaySize;

  /// Design tokens for spacing.
  final LayrzTokens tokens;

  /// Maximum height of the overlay.
  final double maxHeight;

  /// Creates a new [ComboBoxLayoutDelegate].
  ComboBoxLayoutDelegate({
    required this.anchorRect,
    required this.overlaySize,
    required this.tokens,
    required this.maxHeight,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // Width matches the anchor, height constrained by max
    return BoxConstraints(
      minWidth: anchorRect.width,
      maxWidth: anchorRect.width,
      maxHeight: (overlaySize.height - 2 * tokens.spacing.sp2).clamp(0.0, maxHeight),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const gap = 4.0;

    // Calculate Y position: try below, fall back to above
    final belowY = anchorRect.bottom + gap;
    final aboveY = anchorRect.top - childSize.height - gap;

    final y = (belowY + childSize.height <= size.height)
        ? belowY
        : (aboveY >= 0 ? aboveY : belowY); // If neither fits, prefer below

    // Clamp to overlay bounds
    final clampedY = y.clamp(0.0, (size.height - childSize.height).clamp(0.0, double.infinity));

    // X matches anchor's left edge
    return Offset(anchorRect.left, clampedY);
  }

  @override
  bool shouldRelayout(ComboBoxLayoutDelegate oldDelegate) {
    return oldDelegate.anchorRect != anchorRect ||
        oldDelegate.overlaySize != overlaySize ||
        oldDelegate.tokens != tokens ||
        oldDelegate.maxHeight != maxHeight;
  }
}
