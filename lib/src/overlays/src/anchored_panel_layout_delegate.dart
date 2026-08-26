import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'package:layrz_ui/src/positioning/positioning.dart';
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

/// Positions an anchored panel on any of the four sides of its anchor, with
/// cross-axis alignment and width clamping.
///
/// This delegate computes the overlay-relative position of a panel given the
/// anchor's position and size. The panel is placed on [preferredSide] when there
/// is room, and flips unconditionally to [LayrzPreferredSideExtension.opposite]
/// when there is not — there is no second fit test and no third fallback. When
/// neither the preferred side nor its opposite fits, the panel lands on the
/// opposite side and is clamped into the overlay.
///
/// **Width Policy:**
/// - [LayrzAnchoredPanelWidthPolicy.matchAnchor]: panel width equals anchor width
/// - [LayrzAnchoredPanelWidthPolicy.contentSized]: panel width clamped to [widthBounds]
///
/// In both cases the resulting width is additionally clamped to the space actually
/// available in the overlay, so a panel never overflows its container horizontally.
///
/// **Height Policy:** Panel height is constrained by overlay bounds minus padding,
/// with max height applied as an additional constraint. This is deliberately
/// side-blind — it is not narrowed to the room on the resolved side, to avoid
/// shrinking panels that already ship clamped to the full overlay height.
///
/// **Flip Detection:** The [onFlipped] callback is invoked with `true` if the panel
/// was placed on the side opposite to [preferredSide], or `false` if it landed on
/// [preferredSide] itself. Useful for rounding corners on the side adjacent to the
/// anchor.
class LayrzAnchoredPanelLayoutDelegate extends SingleChildLayoutDelegate {
  /// The anchor widget's position and size in overlay coordinates.
  final Rect anchorRect;

  /// The side of the anchor on which the panel is preferentially placed.
  ///
  /// When the panel does not fit on this side, it flips unconditionally to
  /// [LayrzPreferredSideExtension.opposite].
  final LayrzPreferredSide preferredSide;

  /// Alignment of the panel along the cross axis of its resolved side.
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

  /// Callback reporting whether the panel flipped to the side opposite [preferredSide].
  ///
  /// Called with `true` when the panel was placed on the side opposite to
  /// [preferredSide], `false` when it landed on [preferredSide] itself.
  final void Function(bool flippedUp)? onFlipped;

  /// When true, positions the panel directly on top of the anchor -- same top-left
  /// corner, same width (given [widthPolicy] of [LayrzAnchoredPanelWidthPolicy.matchAnchor]) --
  /// instead of on [preferredSide] with a [gap].
  ///
  /// Defaults to `false`, which preserves the side/gap positioning every existing
  /// caller relies on. When `true`, [preferredSide] and [gap] are ignored entirely for
  /// placement (there is no side to resolve and nothing to flip), and [onFlipped] is
  /// never invoked. The resulting position is still clamped into the overlay bounds,
  /// exactly as the side-based placement is.
  ///
  /// This is the mechanism behind the "elevated field" illusion: a panel that exactly
  /// covers its anchor, with its own border and shadow, reads as though the anchor
  /// itself grew a dropdown rather than as a separate floating surface.
  final bool coverAnchor;

  /// Optional minimum height for the panel's content in logical pixels.
  ///
  /// When null (default), the panel's height is bounded only by [maxHeight] and the
  /// overlay bounds, with no floor -- content shorter than that simply renders
  /// shorter. When set, the panel is never shorter than this value even when its
  /// content would otherwise be shorter, clamped so it never exceeds the computed
  /// maximum height. Useful for a panel that must have room for a fixed-height header
  /// (e.g. a search field) regardless of how few items its content ends up showing.
  final double? minHeight;

  /// Creates a new layout delegate for an anchored panel.
  ///
  /// [anchorRect], [preferredSide], [alignment], [widthPolicy], [widthBounds], [gap],
  /// [overlaySize], and [tokens] are required. All other parameters are optional.
  LayrzAnchoredPanelLayoutDelegate({
    required this.anchorRect,
    required this.preferredSide,
    required this.alignment,
    required this.widthPolicy,
    required this.widthBounds,
    required this.gap,
    required this.overlaySize,
    required this.tokens,
    this.maxHeight,
    this.onFlipped,
    this.coverAnchor = false,
    this.minHeight,
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

    // The overlay's horizontal budget, minus padding on both sides. Applies on
    // every side — a panel must never be wider than the overlay itself.
    final horizontalBudget = (overlaySize.width - 2 * tokens.spacing.sp2).clamp(0.0, double.infinity);

    // For a horizontal side, width is the MAIN axis, so it is additionally bounded
    // by the larger of the two rooms beside the anchor. `getPositionForChild` picks
    // between them once `childSize` is known; this must not constrain the child
    // smaller than whichever one it ends up on.
    final double mainAxisRoom;
    if (preferredSide.isHorizontal) {
      final roomLeft = (anchorRect.left - gap).clamp(0.0, double.infinity);
      final roomRight = (overlaySize.width - anchorRect.right - gap).clamp(0.0, double.infinity);
      mainAxisRoom = math.max(roomLeft, roomRight);
    } else {
      mainAxisRoom = horizontalBudget;
    }

    final effectiveMaxWidth = math.min(maxWidth, math.min(horizontalBudget, mainAxisRoom));
    // Never let min exceed max — matchAnchor sets min == max == anchorRect.width,
    // and contentSized sets a fixed minWidth; both can outgrow a narrow overlay.
    final effectiveMinWidth = math.min(minWidth, effectiveMaxWidth);

    // Height constraint: overlay bounds minus padding, with optional max height
    // applied. Deliberately side-blind — see class doc.
    final availableHeight = (overlaySize.height - 2 * tokens.spacing.sp2).clamp(0.0, double.infinity);
    final constrainedHeight = (maxHeight != null ? math.min(availableHeight, maxHeight!) : availableHeight).clamp(
      0.0,
      double.infinity,
    );

    // Never let the floor exceed the ceiling — a `minHeight` larger than the
    // computed maximum (a cramped overlay, a small `maxHeight`) would otherwise
    // violate `BoxConstraints`' own invariant.
    final effectiveMinHeight = minHeight != null ? math.min(minHeight!, constrainedHeight) : 0.0;

    return BoxConstraints(
      minWidth: effectiveMinWidth,
      maxWidth: effectiveMaxWidth,
      minHeight: effectiveMinHeight,
      maxHeight: constrainedHeight,
    );
  }

  /// Resolves which side the panel actually lands on, given the now-known [childSize].
  ///
  /// Flips unconditionally to [LayrzPreferredSideExtension.opposite] of
  /// [preferredSide] when the preferred side does not fit — there is no second
  /// fit test against the opposite side.
  LayrzPreferredSide _resolveSide(Size size, Size childSize) {
    switch (preferredSide) {
      case LayrzPreferredSide.bottom:
        final fits = anchorRect.bottom + gap + childSize.height <= size.height;
        return fits ? LayrzPreferredSide.bottom : LayrzPreferredSide.top;
      case LayrzPreferredSide.top:
        final fits = anchorRect.top - gap - childSize.height >= 0.0;
        return fits ? LayrzPreferredSide.top : LayrzPreferredSide.bottom;
      case LayrzPreferredSide.left:
        final fits = anchorRect.left - gap - childSize.width >= 0.0;
        return fits ? LayrzPreferredSide.left : LayrzPreferredSide.right;
      case LayrzPreferredSide.right:
        final fits = anchorRect.right + gap + childSize.width <= size.width;
        return fits ? LayrzPreferredSide.right : LayrzPreferredSide.left;
    }
  }

  /// The cross-axis X coordinate for [alignment], used when the resolved side is
  /// vertical (top or bottom).
  double _crossAxisX(Size childSize) {
    switch (alignment) {
      case LayrzAnchoredPanelAlignment.start:
        return anchorRect.left;
      case LayrzAnchoredPanelAlignment.center:
        return anchorRect.center.dx - childSize.width / 2;
      case LayrzAnchoredPanelAlignment.end:
        return anchorRect.right - childSize.width;
    }
  }

  /// The cross-axis Y coordinate for [alignment], used when the resolved side is
  /// horizontal (left or right).
  double _crossAxisY(Size childSize) {
    switch (alignment) {
      case LayrzAnchoredPanelAlignment.start:
        return anchorRect.top;
      case LayrzAnchoredPanelAlignment.center:
        return anchorRect.center.dy - childSize.height / 2;
      case LayrzAnchoredPanelAlignment.end:
        return anchorRect.bottom - childSize.height;
    }
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    if (coverAnchor) {
      // No side to resolve and nothing to flip -- the panel always starts at the
      // anchor's own top-left corner, clamped into the overlay exactly like the
      // side-based placement below.
      final clampedX = anchorRect.left.clamp(0.0, (size.width - childSize.width).clamp(0.0, double.infinity));
      final clampedY = anchorRect.top.clamp(0.0, (size.height - childSize.height).clamp(0.0, double.infinity));
      return Offset(clampedX, clampedY);
    }

    final resolved = _resolveSide(size, childSize);
    onFlipped?.call(resolved != preferredSide);

    double x;
    double y;
    switch (resolved) {
      case LayrzPreferredSide.bottom:
        y = anchorRect.bottom + gap;
        x = _crossAxisX(childSize);
      case LayrzPreferredSide.top:
        y = anchorRect.top - childSize.height - gap;
        x = _crossAxisX(childSize);
      case LayrzPreferredSide.left:
        x = anchorRect.left - childSize.width - gap;
        y = _crossAxisY(childSize);
      case LayrzPreferredSide.right:
        x = anchorRect.right + gap;
        y = _crossAxisY(childSize);
    }

    // Clamp to overlay bounds on both axes.
    final clampedX = x.clamp(0.0, (size.width - childSize.width).clamp(0.0, double.infinity));
    final clampedY = y.clamp(0.0, (size.height - childSize.height).clamp(0.0, double.infinity));

    return Offset(clampedX, clampedY);
  }

  @override
  bool shouldRelayout(LayrzAnchoredPanelLayoutDelegate oldDelegate) {
    return oldDelegate.anchorRect != anchorRect ||
        oldDelegate.preferredSide != preferredSide ||
        oldDelegate.alignment != alignment ||
        oldDelegate.widthPolicy != widthPolicy ||
        oldDelegate.widthBounds != widthBounds ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.gap != gap ||
        oldDelegate.overlaySize != overlaySize ||
        oldDelegate.tokens != tokens ||
        oldDelegate.coverAnchor != coverAnchor ||
        oldDelegate.minHeight != minHeight;
  }
}

/// Specifies the alignment of an anchored panel along the cross axis of its resolved side.
///
/// The cross axis is horizontal when the panel is placed above or below the anchor,
/// and vertical when it is placed to the left or right — the same axis-relative
/// convention Flutter uses for [CrossAxisAlignment].
enum LayrzAnchoredPanelAlignment {
  /// Panel's leading cross-axis edge aligns with the anchor's leading edge:
  /// the left edges on a vertical side, the top edges on a horizontal side.
  ///
  /// `start` is the leading edge in left-to-right layouts. [Directionality] is not
  /// yet honoured; in right-to-left layouts this still means the left edge.
  start,

  /// Panel's cross-axis center aligns with the anchor's cross-axis center:
  /// horizontal centers on a vertical side, vertical centers on a horizontal side.
  center,

  /// Panel's trailing cross-axis edge aligns with the anchor's trailing edge:
  /// the right edges on a vertical side, the bottom edges on a horizontal side.
  ///
  /// `end` is the trailing edge in left-to-right layouts. [Directionality] is not
  /// yet honoured; in right-to-left layouts this still means the right edge.
  end,
}
