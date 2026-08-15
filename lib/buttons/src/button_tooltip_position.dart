import 'package:flutter/widgets.dart';

import '../../constants/constants.dart';

/// Positions a tooltip centred horizontally on its target and offset below it.
///
/// This delegate computes the tooltip's location based on the target's center point
/// (as provided by [TooltipPositionContext.target] in global coordinates), accounting
/// for the tooltip and target sizes, and respecting the overlay bounds.
///
/// **Horizontal alignment**: The tooltip is centred on the target. When the tooltip
/// would overflow the left or right edge of the overlay, it clamps inward to stay
/// fully visible.
///
/// **Vertical alignment**: The tooltip is positioned [kLayrzButtonTooltipVerticalOffset]
/// pixels below the target's bottom edge. If placing it below would push it past the
/// bottom of the overlay, it flips above the target instead, positioned
/// [kLayrzButtonTooltipVerticalOffset] pixels above the target's top edge.
///
/// Parameters:
///   - [context]: The tooltip positioning context containing target location, sizes,
///     and overlay bounds.
///
/// Returns the tooltip's top-left corner in global coordinates.
Offset layrzButtonTooltipPosition(TooltipPositionContext context) {
  // Horizontal: centre the tooltip on the target's x-coordinate.
  // context.target.dx is already the centre; subtract half the tooltip width to centre it.
  var tooltipLeft = context.target.dx - (context.tooltipSize.width / 2);

  // Clamp horizontally to stay within overlay bounds.
  final minLeft = 0.0;
  final maxLeft = context.overlaySize.width - context.tooltipSize.width;
  tooltipLeft = tooltipLeft.clamp(minLeft, maxLeft);

  // Vertical: try positioning below the target first.
  // context.target.dy is the centre; add half the target height to reach the bottom edge,
  // then add the design token gap.
  final tooltipBelowY = context.target.dy + (context.targetSize.height / 2) + kLayrzButtonTooltipVerticalOffset;

  // Determine if placing below would overflow the bottom of the overlay.
  final tooltipBottomIfBelow = tooltipBelowY + context.tooltipSize.height;
  final fitsBelow = tooltipBottomIfBelow <= context.overlaySize.height;

  late final double tooltipTop;
  if (fitsBelow) {
    // Tooltip fits below; use the below position.
    tooltipTop = tooltipBelowY;
  } else {
    // Tooltip doesn't fit below; flip it above the target instead.
    tooltipTop =
        context.target.dy -
        (context.targetSize.height / 2) -
        context.tooltipSize.height -
        kLayrzButtonTooltipVerticalOffset;
  }

  return Offset(tooltipLeft, tooltipTop);
}
