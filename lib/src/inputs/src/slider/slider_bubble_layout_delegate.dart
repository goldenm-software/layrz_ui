import 'package:flutter/widgets.dart';

/// [SingleChildLayoutDelegate] that pins a [LayrzSlider] value bubble's
/// horizontal centre to the thumb's current position along the track,
/// without stretching the bubble to the track's full width.
///
/// The parent `Positioned` pins `left: 0, right: 0` only so the `Stack` hands
/// down bounded constraints (an unpinned axis would otherwise be unbounded,
/// which crashes layout) — this delegate then loosens those constraints so
/// the bubble is free to size to its own text rather than stretching to fill
/// the track's width, and places it at `thumbHalfSize + (trackWidth -
/// thumbSize) * fraction` — the same x-coordinate `LayrzSliderPainter` uses
/// for the thumb centre — minus half the bubble's own measured width, so the
/// two stay aligned pixel-for-pixel as the thumb moves.
class LayrzSliderBubbleLayoutDelegate extends SingleChildLayoutDelegate {
  /// The full width of the track the thumb travels across.
  final double trackWidth;

  /// Half of the thumb's edge length — the same inset the painter and
  /// hit-test math apply so the thumb's own centre never leaves the track.
  final double thumbHalfSize;

  /// The thumb's current position as a fraction of the track, `0.0`–`1.0`.
  final double fraction;

  /// Creates a layout delegate that centres its child above the thumb.
  const LayrzSliderBubbleLayoutDelegate({
    required this.trackWidth,
    required this.thumbHalfSize,
    required this.fraction,
  });

  @override
  Size getSize(BoxConstraints constraints) {
    // Only `left`/`right` are pinned on the parent Positioned (see the class
    // doc), so the height constraint arriving here is unbounded.
    // CustomSingleChildLayout's own render box sizes *itself* to
    // `getSize(constraints).constrain(...)` before it ever consults
    // [getConstraintsForChild] for the child, so leaving height unbounded
    // here throws ("RenderBox was given an infinite size") regardless of what
    // the child is given. The bubble's own height is always small (one line
    // of label text plus padding), so a generously loose but finite cap is
    // all that is needed; it never actually determines the bubble's rendered
    // height, only the ceiling this layout box is allowed to claim.
    return Size(constraints.maxWidth, constraints.maxHeight.isFinite ? constraints.maxHeight : 200);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen().copyWith(maxHeight: getSize(constraints).height);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final usableWidth = trackWidth - thumbHalfSize * 2;
    final thumbX = thumbHalfSize + usableWidth * fraction;
    return Offset(thumbX - childSize.width / 2, 0);
  }

  @override
  bool shouldRelayout(covariant LayrzSliderBubbleLayoutDelegate oldDelegate) {
    return trackWidth != oldDelegate.trackWidth ||
        thumbHalfSize != oldDelegate.thumbHalfSize ||
        fraction != oldDelegate.fraction;
  }
}
