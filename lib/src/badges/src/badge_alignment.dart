import 'package:flutter/widgets.dart';

/// Corner alignment for a [LayrzBadge] overlay relative to its child.
///
/// A notification badge conventionally sits at a corner of the widget it
/// decorates (a bell icon, an avatar, a nav item). This enum names the four
/// corners rather than exposing a raw [Alignment], so a call site reads as
/// intent ("topRight") instead of arithmetic.
enum LayrzBadgeAlignment {
  /// Anchors the badge to the top-right corner of the child. The conventional
  /// default for notification counts.
  topRight,

  /// Anchors the badge to the top-left corner of the child.
  topLeft,

  /// Anchors the badge to the bottom-right corner of the child.
  bottomRight,

  /// Anchors the badge to the bottom-left corner of the child.
  bottomLeft;

  /// Resolves this corner to the [Alignment] used to position the badge
  /// within the [Stack] that overlays it on its child.
  Alignment get alignment {
    switch (this) {
      case LayrzBadgeAlignment.topRight:
        return Alignment.topRight;
      case LayrzBadgeAlignment.topLeft:
        return Alignment.topLeft;
      case LayrzBadgeAlignment.bottomRight:
        return Alignment.bottomRight;
      case LayrzBadgeAlignment.bottomLeft:
        return Alignment.bottomLeft;
    }
  }
}
