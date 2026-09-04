import 'package:flutter/widgets.dart';

/// Corner position for a [LayrzAiMarker] overlay relative to its child, used
/// by `LayrzAiMarker.wrap`.
///
/// Mirrors `LayrzBadgeAlignment` (`lib/src/badges/src/badge_alignment.dart`)
/// naming so the two overlay wrappers in the design system read the same way
/// at a call site — a corner name, not raw [Alignment] arithmetic.
enum LayrzAiMarkerPosition {
  /// Anchors the marker to the top-right corner of the child. The
  /// conventional default for an AI-disclosure marker on a card or bubble.
  topRight,

  /// Anchors the marker to the top-left corner of the child.
  topLeft,

  /// Anchors the marker to the bottom-right corner of the child.
  bottomRight,

  /// Anchors the marker to the bottom-left corner of the child.
  bottomLeft;

  /// Resolves this corner to the [Alignment] used to position the marker
  /// within the [Stack] that overlays it on its child.
  Alignment get alignment {
    switch (this) {
      case LayrzAiMarkerPosition.topRight:
        return Alignment.topRight;
      case LayrzAiMarkerPosition.topLeft:
        return Alignment.topLeft;
      case LayrzAiMarkerPosition.bottomRight:
        return Alignment.bottomRight;
      case LayrzAiMarkerPosition.bottomLeft:
        return Alignment.bottomLeft;
    }
  }

  /// The outward nudge applied so the marker reads as sitting on the corner
  /// of its child rather than fully inside the bounding box.
  ///
  /// Mirrors `LayrzBadge._translationFor`'s fractional-translation approach.
  Offset get translation {
    switch (this) {
      case LayrzAiMarkerPosition.topRight:
        return const Offset(0.3, -0.3);
      case LayrzAiMarkerPosition.topLeft:
        return const Offset(-0.3, -0.3);
      case LayrzAiMarkerPosition.bottomRight:
        return const Offset(0.3, 0.3);
      case LayrzAiMarkerPosition.bottomLeft:
        return const Offset(-0.3, 0.3);
    }
  }
}
