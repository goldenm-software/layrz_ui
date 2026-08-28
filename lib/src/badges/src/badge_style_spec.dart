import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'badge_type.dart';

/// Immutable specification of visual properties for a [LayrzBadge] (or its
/// bare visual) in a given semantic type.
///
/// A [LayrzBadgeStyleSpec] holds only paint properties: the background fill
/// and the content color (the color used for the number/icon painted inside
/// the badge). It is computed by [resolve] from a type, an optional explicit
/// color, and tokens. Badges are static (no interaction states), so the spec
/// is a pure function of its inputs — mirroring `LayrzChipStyleSpec`'s shape.
@immutable
class LayrzBadgeStyleSpec {
  /// The fill color of the badge background.
  final Color backgroundColor;

  /// The color of the badge content (number text or icon glyph).
  final Color contentColor;

  /// Creates a new [LayrzBadgeStyleSpec].
  const LayrzBadgeStyleSpec({
    required this.backgroundColor,
    required this.contentColor,
  });

  /// Returns a copy of this spec with the given fields replaced.
  LayrzBadgeStyleSpec copyWith({
    Color? backgroundColor,
    Color? contentColor,
  }) {
    return LayrzBadgeStyleSpec(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      contentColor: contentColor ?? this.contentColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzBadgeStyleSpec &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          contentColor == other.contentColor;

  @override
  int get hashCode => Object.hash(backgroundColor, contentColor);

  /// Resolves a [LayrzBadgeStyleSpec] from a semantic [type], an optional
  /// explicit [color] override, and [tokens].
  ///
  /// [type] selects the semantic color token via [LayrzBadgeType.colorToken],
  /// following the same convention as `LayrzChipType`. [color] overrides the
  /// resolved accent regardless of [type] when non-null — this is how a caller
  /// supplies a custom color without having to also pass `type: custom`.
  /// When [type] is [LayrzBadgeType.custom] and [color] is null, the accent
  /// falls back to `tokens.colors.primary.shade500`. [contentColor] is derived
  /// from the accent via [LayrzColorExtensions.contrastColor] so text/icon
  /// content always has adequate contrast against the fill.
  static LayrzBadgeStyleSpec resolve({
    required LayrzBadgeType type,
    required Color? color,
    required LayrzTokens tokens,
  }) {
    final accent = color ?? type.colorToken(tokens) ?? tokens.colors.primary.shade500;
    return LayrzBadgeStyleSpec(
      backgroundColor: accent,
      contentColor: accent.contrastColor,
    );
  }
}
