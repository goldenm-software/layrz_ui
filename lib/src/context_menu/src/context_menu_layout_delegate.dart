import 'package:flutter/rendering.dart';

import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Positions a [LayrzContextMenu] panel at the pointer location that opened
/// it, flipping and clamping as needed so the panel never overflows the
/// overlay bounds.
///
/// Unlike `LayrzAnchoredPanelLayoutDelegate` (which anchors to a side of a
/// trigger widget's rect), this delegate anchors to a single point: the
/// pointer's local offset at the moment of the right-click or long-press,
/// converted to overlay coordinates as `anchorRect.topLeft + position`. That
/// point becomes the panel's *preferred* top-left corner, then:
///
/// - If the panel would overflow the right edge, its horizontal placement is
///   flipped so the pointer point becomes the panel's right edge instead.
/// - If the panel would overflow the bottom edge, its vertical placement is
///   flipped so the pointer point becomes the panel's bottom edge instead.
/// - The final position is clamped into the overlay bounds on both axes, so
///   even a panel too large to avoid overflow entirely still stays fully
///   on-screen.
class LayrzContextMenuLayoutDelegate extends SingleChildLayoutDelegate {
  /// The triggering anchor's rect in overlay coordinates.
  ///
  /// Combined with [position] (both supplied by
  /// `RawMenuOverlayInfo`/`MenuController.open`), this yields the pointer's
  /// location in overlay coordinates: `anchorRect.topLeft + position`.
  final Rect anchorRect;

  /// The pointer's local offset relative to [anchorRect]'s top-left corner,
  /// as passed to `MenuController.open(position: ...)`.
  ///
  /// `null` only in the defensive case where the menu was opened without a
  /// captured pointer position; the panel then anchors to [anchorRect]'s own
  /// top-left corner instead of a pointer point.
  final Offset? position;

  /// The full size of the overlay the panel is painted into.
  final Size overlaySize;

  /// Design tokens, used for the padding kept between the panel and the
  /// overlay's own edges.
  final LayrzTokens tokens;

  /// Optional maximum height for the panel's content in logical pixels.
  ///
  /// When `null`, height is constrained only by the overlay bounds minus
  /// padding.
  final double? maxHeight;

  /// Creates a new layout delegate for a [LayrzContextMenu] panel.
  ///
  /// [anchorRect], [overlaySize], and [tokens] are required. [position] and
  /// [maxHeight] are optional.
  LayrzContextMenuLayoutDelegate({
    required this.anchorRect,
    required this.overlaySize,
    required this.tokens,
    this.position,
    this.maxHeight,
  });

  /// The pointer's location in overlay coordinates.
  ///
  /// Falls back to [anchorRect]'s top-left corner when [position] was not
  /// supplied.
  Offset get _pointerOffset => position == null ? anchorRect.topLeft : anchorRect.topLeft + position!;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final horizontalPadding = 2 * tokens.spacing.sp2;
    final verticalPadding = 2 * tokens.spacing.sp2;

    final availableWidth = (overlaySize.width - horizontalPadding).clamp(0.0, double.infinity);
    final availableHeight = (overlaySize.height - verticalPadding).clamp(0.0, double.infinity);

    final constrainedHeight = maxHeight != null ? maxHeight!.clamp(0.0, availableHeight) : availableHeight;

    // Width parity with `LayrzDropdownMenu`: the panel is content-sized within
    // the same [kLayrzDropdownMenuMinWidth, kLayrzDropdownMenuMaxWidth] band
    // the dropdown menu uses, not the full overlay width. The upper bound is
    // additionally clamped to `availableWidth` so the panel never overflows a
    // viewport narrower than `kLayrzDropdownMenuMaxWidth` itself.
    final maxWidth = kLayrzDropdownMenuMaxWidth.clamp(0.0, availableWidth);
    final minWidth = kLayrzDropdownMenuMinWidth.clamp(0.0, maxWidth);

    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: 0.0,
      maxHeight: constrainedHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final pointer = _pointerOffset;

    // Preferred placement: panel's top-left corner sits exactly at the
    // pointer. Flip each axis independently when the preferred placement
    // would overflow that edge.
    double x = pointer.dx;
    if (x + childSize.width > size.width) {
      x = pointer.dx - childSize.width;
    }

    double y = pointer.dy;
    if (y + childSize.height > size.height) {
      y = pointer.dy - childSize.height;
    }

    // Clamp into overlay bounds on both axes, covering the case where the
    // panel is too large to avoid overflow even after flipping.
    final clampedX = x.clamp(0.0, (size.width - childSize.width).clamp(0.0, double.infinity));
    final clampedY = y.clamp(0.0, (size.height - childSize.height).clamp(0.0, double.infinity));

    return Offset(clampedX, clampedY);
  }

  @override
  bool shouldRelayout(LayrzContextMenuLayoutDelegate oldDelegate) {
    return oldDelegate.anchorRect != anchorRect ||
        oldDelegate.position != position ||
        oldDelegate.overlaySize != overlaySize ||
        oldDelegate.tokens != tokens ||
        oldDelegate.maxHeight != maxHeight;
  }
}
