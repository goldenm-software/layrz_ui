/// The preferred side on which a floating surface is placed relative to its anchor.
///
/// Surfaces that accept a preferred side place themselves on that side when there is
/// room, and flip to [LayrzPreferredSideExtension.opposite] when there is not. The flip
/// is unconditional: there is no second fit test and no third fallback.
enum LayrzPreferredSide {
  /// Place the surface above the anchor.
  top,

  /// Place the surface below the anchor.
  bottom,

  /// Place the surface to the left of the anchor.
  left,

  /// Place the surface to the right of the anchor.
  right,
}

/// Small geometric helpers on [LayrzPreferredSide].
///
/// This is the type's own API — axis membership and the opposite side. Fit tests,
/// gaps, clamping, and any other constraint arithmetic belong to each consumer's own
/// layout delegate, not here.
extension LayrzPreferredSideExtension on LayrzPreferredSide {
  /// The side directly opposite this one.
  ///
  /// [LayrzPreferredSide.top] and [LayrzPreferredSide.bottom] are each other's
  /// opposite, as are [LayrzPreferredSide.left] and [LayrzPreferredSide.right].
  LayrzPreferredSide get opposite {
    switch (this) {
      case LayrzPreferredSide.top:
        return LayrzPreferredSide.bottom;
      case LayrzPreferredSide.bottom:
        return LayrzPreferredSide.top;
      case LayrzPreferredSide.left:
        return LayrzPreferredSide.right;
      case LayrzPreferredSide.right:
        return LayrzPreferredSide.left;
    }
  }

  /// Whether this side lies on the vertical axis ([LayrzPreferredSide.top] or
  /// [LayrzPreferredSide.bottom]).
  bool get isVertical => this == LayrzPreferredSide.top || this == LayrzPreferredSide.bottom;

  /// Whether this side lies on the horizontal axis ([LayrzPreferredSide.left] or
  /// [LayrzPreferredSide.right]).
  bool get isHorizontal => !isVertical;
}
