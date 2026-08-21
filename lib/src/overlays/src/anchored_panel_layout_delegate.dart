import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'package:layrz_ui/src/tokens/tokens.dart';

/// Specifies how the anchored panel should size its width.
enum LayrzAnchoredPanelWidthPolicy {
  /// Width exactly matches the anchor widget's width.
  matchAnchor,

  /// Width is sized to the panel's content, clamped between min/max bounds.
  contentSized,
}

/// Bounds for content-sized width policy: minimum and maximum width in logical pixels.
///
/// Only used when [LayrzAnchoredPanelWidthPolicy.contentSized] is the active policy.
/// The panel width will be clamped to [minWidth, maxWidth].
class LayrzAnchoredPanelWidthBounds {
  /// Minimum width of the panel in logical pixels.
  ///
  /// The panel will never be narrower than this value, even if the content is smaller.
  final double minWidth;

  /// Maximum width of the panel in logical pixels.
  ///
  /// The panel will never be wider than this value, even if the content is larger.
  final double maxWidth;

  /// Creates bounds for content-sized width policy.
  ///
  /// [minWidth] and [maxWidth] must both be positive. [maxWidth] must be greater
  /// than or equal to [minWidth].
  const LayrzAnchoredPanelWidthBounds({
    required this.minWidth,
    required this.maxWidth,
  }) : assert(minWidth > 0, 'minWidth must be positive'),
       assert(maxWidth > 0, 'maxWidth must be positive'),
       assert(maxWidth >= minWidth, 'maxWidth must be >= minWidth');
}

/// Positions an anchored panel below or above its anchor with horizontal alignment clamping.
///
/// This delegate computes the overlay-relative position of a panel given the anchor's
/// position and size. The panel is placed below the anchor by default, but flips above
/// if insufficient space exists below. If neither fits, the panel prefers below.
///
/// **Width Policy:**
/// - [LayrzAnchoredPanelWidthPolicy.matchAnchor]: panel width equals anchor width
/// - [LayrzAnchoredPanelWidthPolicy.contentSized]: panel width clamped to [widthBounds]
///
/// **Height Policy:** Panel height is constrained by overlay bounds minus padding,
/// with max height applied as an additional constraint.
///
/// **Flip Detection:** The [flippedUp] callback is invoked with true if the panel
/// was flipped above the anchor, or false if positioned below. Useful for rounding
/// corners on the side adjacent to the anchor.
class LayrzAnchoredPanelLayoutDelegate extends SingleChildLayoutDelegate {
  /// The anchor widget's position and size in overlay coordinates.
  final Rect anchorRect;

  /// Horizontal alignment of the panel relative to the anchor.
  final LayrzAnchoredPanelAlignment alignment;

  /// Policy for computing panel width.
  final LayrzAnchoredPanelWidthPolicy widthPolicy;

  /// Width bounds for content-sized policy. Only used when [widthPolicy] is [LayrzAnchoredPanelWidthPolicy.contentSized].
  final LayrzAnchoredPanelWidthBounds widthBounds;

  /// Optional maximum height for the panel's content. If null, height is constrained only by overlay bounds.
  final double? maxHeight;

  /// Space between the anchor and panel in logical pixels.
  final double gap;

  /// The overlay's full size.
  final Size overlaySize;

  /// Design tokens for spacing and radius.
  final LayrzTokens tokens;

  /// Callback to report whether the panel flipped above the anchor.
  ///
  /// Called with `true` if the panel is positioned above the anchor,
  /// `false` if positioned below.
  final void Function(bool flippedUp)? onFlipped;

  /// Creates a new layout delegate for an anchored panel.
  ///
  /// [anchorRect], [alignment], [widthPolicy], [widthBounds], [gap], [overlaySize],
  /// and [tokens] are required. All other parameters are optional.
  LayrzAnchoredPanelLayoutDelegate({
    required this.anchorRect,
    required this.alignment,
    required this.widthPolicy,
    required this.widthBounds,
    required this.gap,
    required this.overlaySize,
    required this.tokens,
    this.maxHeight,
    this.onFlipped,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // Width constraint based on policy
    final double minWidth;
    final double maxWidth;

    switch (widthPolicy) {
      case LayrzAnchoredPanelWidthPolicy.matchAnchor:
        // Panel width equals anchor width
        minWidth = anchorRect.width;
        maxWidth = anchorRect.width;
      case LayrzAnchoredPanelWidthPolicy.contentSized:
        // Panel width clamped to bounds
        minWidth = widthBounds.minWidth;
        maxWidth = widthBounds.maxWidth;
    }

    // Height constraint: overlay bounds minus padding, with optional max height applied
    final availableHeight = (overlaySize.height - 2 * tokens.spacing.sp2).clamp(0.0, double.infinity);
    final constrainedHeight = maxHeight != null ? math.min(availableHeight, maxHeight!) : availableHeight;

    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      maxHeight: constrainedHeight.clamp(0.0, double.infinity),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Calculate Y position: try below first, flip above if no room
    final belowY = anchorRect.bottom + gap;
    final aboveY = anchorRect.top - childSize.height - gap;

    final belowFits = belowY + childSize.height <= size.height;
    final aboveFits = aboveY >= 0.0;

    final y = belowFits ? belowY : (aboveFits ? aboveY : belowY);
    final flippedUp = !belowFits && aboveFits;

    // Notify callback of flip decision
    onFlipped?.call(flippedUp);

    // Clamp to overlay bounds vertically
    final clampedY = y.clamp(0.0, (size.height - childSize.height).clamp(0.0, double.infinity));

    // Calculate X position based on alignment
    double x;
    switch (alignment) {
      case LayrzAnchoredPanelAlignment.start:
        x = anchorRect.left;
      case LayrzAnchoredPanelAlignment.center:
        x = anchorRect.center.dx - childSize.width / 2;
      case LayrzAnchoredPanelAlignment.end:
        x = anchorRect.right - childSize.width;
    }

    // Clamp to overlay bounds horizontally
    final clampedX = x.clamp(0.0, (size.width - childSize.width).clamp(0.0, double.infinity));

    return Offset(clampedX, clampedY);
  }

  @override
  bool shouldRelayout(LayrzAnchoredPanelLayoutDelegate oldDelegate) {
    return oldDelegate.anchorRect != anchorRect ||
        oldDelegate.alignment != alignment ||
        oldDelegate.widthPolicy != widthPolicy ||
        oldDelegate.widthBounds != widthBounds ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.gap != gap ||
        oldDelegate.overlaySize != overlaySize ||
        oldDelegate.tokens != tokens;
  }
}

/// Specifies the horizontal alignment of an anchored panel relative to its anchor.
enum LayrzAnchoredPanelAlignment {
  /// Panel's left edge aligns with the anchor's left edge.
  start,

  /// Panel's center aligns with the anchor's center.
  center,

  /// Panel's right edge aligns with the anchor's right edge.
  end,
}
