import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

/// Shape of an avatar's container.
///
/// Defines whether the avatar is rendered as a perfect circle or as a rounded square.
enum LayrzAvatarShape {
  /// Avatar is a perfect circle; uses [BoxShape.circle].
  circle,

  /// Avatar is a rounded square using the base radius token from the design system.
  ///
  /// The rounding is determined by [LayrzTokens.radius.base] — the standard
  /// corner radius for moderate component rounding. This ensures consistent
  /// visual hierarchy across the design system.
  rounded,
}

/// Extension on [LayrzAvatarShape] to retrieve the rounding radius.
extension LayrzAvatarShapeRadiusExtension on LayrzAvatarShape {
  /// Returns the border radius for this shape.
  ///
  /// For [LayrzAvatarShape.circle], returns a circular radius matching the size.
  /// For [LayrzAvatarShape.rounded], returns the base token radius.
  ///
  /// This method requires a [BuildContext] to access the design system tokens
  /// for the rounded case.
  BorderRadius getRadius(BuildContext context, double size) {
    return switch (this) {
      LayrzAvatarShape.circle => BorderRadius.circular(size / 2),
      LayrzAvatarShape.rounded => BorderRadius.circular(context.tokens.radius.base),
    };
  }
}
