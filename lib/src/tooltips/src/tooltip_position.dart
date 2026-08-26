import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/positioning/positioning.dart';

/// Computes the position delegate for [RawTooltip] based on the desired position.
///
/// The returned function places the tooltip on the specified side of the anchor,
/// accounting for overflow and clamping to viewport bounds.
///
/// **Parameters:**
/// - [position]: the preferred side (top, bottom, left, right)
///
/// **Returns:** a [TooltipPositionDelegate] closure that computes the tooltip's
/// top-left corner in global coordinates.
///
/// **Algorithm:**
/// 1. Compute the preferred position on the specified side, offset by [kLayrzTooltipOffset].
/// 2. Check if the tooltip would overflow the overlay bounds on that side.
/// 3. If it overflows, flip to the opposite side.
/// 4. Clamp the tooltip on the cross axis to stay inside the overlay.
/// 5. Guard every clamp with `math.max(0.0, overlaySize.dimension - tooltipSize.dimension)`
///    to avoid throwing when the tooltip is larger than the overlay on that axis.
TooltipPositionDelegate positionDelegate(LayrzPreferredSide position) {
  return (TooltipPositionContext context) {
    final target = context.target; // Anchor centre in global coords.
    final targetSize = context.targetSize;
    final tooltipSize = context.tooltipSize;
    final overlaySize = context.overlaySize;

    switch (position) {
      case LayrzPreferredSide.bottom:
        // Horizontal: centre on the target's x-coordinate.
        final centerX = target.dx;
        var tooltipLeft = centerX - (tooltipSize.width / 2);

        // Clamp horizontally, guarding against tooltip wider than overlay.
        final maxLeftOffset = math.max(0.0, overlaySize.width - tooltipSize.width);
        tooltipLeft = tooltipLeft.clamp(0.0, maxLeftOffset);

        // Vertical: try positioning below the target first.
        final bottomY = target.dy + (targetSize.height / 2) + kLayrzTooltipOffset;
        final tooltipBottomIfBelow = bottomY + tooltipSize.height;

        late final double tooltipTop;
        if (tooltipBottomIfBelow <= overlaySize.height) {
          // Fits below; use the below position.
          tooltipTop = bottomY;
        } else {
          // Doesn't fit below; flip above the target.
          tooltipTop = target.dy - (targetSize.height / 2) - tooltipSize.height - kLayrzTooltipOffset;
        }

        return Offset(tooltipLeft, tooltipTop);

      case LayrzPreferredSide.top:
        // Horizontal: centre on the target's x-coordinate.
        final centerX = target.dx;
        var tooltipLeft = centerX - (tooltipSize.width / 2);

        // Clamp horizontally, guarding against tooltip wider than overlay.
        final maxLeftOffset = math.max(0.0, overlaySize.width - tooltipSize.width);
        tooltipLeft = tooltipLeft.clamp(0.0, maxLeftOffset);

        // Vertical: try positioning above the target first.
        final topY = target.dy - (targetSize.height / 2) - tooltipSize.height - kLayrzTooltipOffset;
        final tooltipTopIfAbove = topY;

        late final double tooltipTop;
        if (tooltipTopIfAbove >= 0.0) {
          // Fits above; use the above position.
          tooltipTop = tooltipTopIfAbove;
        } else {
          // Doesn't fit above; flip below the target.
          tooltipTop = target.dy + (targetSize.height / 2) + kLayrzTooltipOffset;
        }

        return Offset(tooltipLeft, tooltipTop);

      case LayrzPreferredSide.left:
        // Vertical: centre on the target's y-coordinate.
        final centerY = target.dy;
        var tooltipTop = centerY - (tooltipSize.height / 2);

        // Clamp vertically, guarding against tooltip taller than overlay.
        final maxTopOffset = math.max(0.0, overlaySize.height - tooltipSize.height);
        tooltipTop = tooltipTop.clamp(0.0, maxTopOffset);

        // Horizontal: try positioning left of the target first.
        final leftX = target.dx - (targetSize.width / 2) - tooltipSize.width - kLayrzTooltipOffset;
        final tooltipLeftIfLeft = leftX;

        late final double tooltipLeft;
        if (tooltipLeftIfLeft >= 0.0) {
          // Fits left; use the left position.
          tooltipLeft = tooltipLeftIfLeft;
        } else {
          // Doesn't fit left; flip right of the target.
          tooltipLeft = target.dx + (targetSize.width / 2) + kLayrzTooltipOffset;
        }

        return Offset(tooltipLeft, tooltipTop);

      case LayrzPreferredSide.right:
        // Vertical: centre on the target's y-coordinate.
        final centerY = target.dy;
        var tooltipTop = centerY - (tooltipSize.height / 2);

        // Clamp vertically, guarding against tooltip taller than overlay.
        final maxTopOffset = math.max(0.0, overlaySize.height - tooltipSize.height);
        tooltipTop = tooltipTop.clamp(0.0, maxTopOffset);

        // Horizontal: try positioning right of the target first.
        final rightX = target.dx + (targetSize.width / 2) + kLayrzTooltipOffset;
        final tooltipRightIfRight = rightX + tooltipSize.width;

        late final double tooltipLeft;
        if (tooltipRightIfRight <= overlaySize.width) {
          // Fits right; use the right position.
          tooltipLeft = rightX;
        } else {
          // Doesn't fit right; flip left of the target.
          tooltipLeft = target.dx - (targetSize.width / 2) - tooltipSize.width - kLayrzTooltipOffset;
        }

        return Offset(tooltipLeft, tooltipTop);
    }
  };
}
