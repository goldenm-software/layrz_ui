import 'package:flutter/widgets.dart';

/// Immutable border tokens for stroke widths and border sides in the design system.
///
/// Border tokens define stroke widths and pre-built [BorderSide] objects using
/// semantic colors. This makes it easy to apply consistent borders throughout
/// the design system.
@immutable
class LayrzBorderTokens {
  /// Base stroke width used as the default border width.
  ///
  /// Defaults to 1.5 pixels. Used when [LayrzTokenizer] needs a generic border width.
  final double base;

  /// Thin stroke width of 1 pixel.
  final double stroke1;

  /// Medium stroke width of 2 pixels.
  final double stroke2;

  /// Thick stroke width of 3 pixels.
  final double stroke3;

  /// Color used for all border sides (divider color).
  final Color dividerColor;

  /// Creates a new [LayrzBorderTokens].
  const LayrzBorderTokens({
    this.base = 1.5,
    this.stroke1 = 1.0,
    this.stroke2 = 2.0,
    this.stroke3 = 3.0,
    required this.dividerColor,
  });

  /// A light [BorderSide] with [stroke1] width and [dividerColor].
  BorderSide get light => BorderSide(color: dividerColor, width: stroke1);

  /// A normal [BorderSide] with [stroke2] width and [dividerColor].
  BorderSide get normal => BorderSide(color: dividerColor, width: stroke2);

  /// A thick [BorderSide] with [stroke3] width and [dividerColor].
  BorderSide get thick => BorderSide(color: dividerColor, width: stroke3);

  /// Returns a copy of this border tokens object with the given fields replaced.
  LayrzBorderTokens copyWith({
    double? base,
    double? stroke1,
    double? stroke2,
    double? stroke3,
    Color? dividerColor,
  }) {
    return LayrzBorderTokens(
      base: base ?? this.base,
      stroke1: stroke1 ?? this.stroke1,
      stroke2: stroke2 ?? this.stroke2,
      stroke3: stroke3 ?? this.stroke3,
      dividerColor: dividerColor ?? this.dividerColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzBorderTokens &&
          runtimeType == other.runtimeType &&
          base == other.base &&
          stroke1 == other.stroke1 &&
          stroke2 == other.stroke2 &&
          stroke3 == other.stroke3 &&
          dividerColor == other.dividerColor;

  @override
  int get hashCode => Object.hash(base, stroke1, stroke2, stroke3, dividerColor);
}
