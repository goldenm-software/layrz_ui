import 'package:flutter/widgets.dart';

/// Immutable spacing tokens defining a consistent grid for margins, padding, and gaps.
///
/// All spacing values are multiples of 4, making them harmonious and easy to reason about.
/// The base unit is 8 pixels.
@immutable
class LayrzSpacingTokens {
  /// Base spacing unit used in convenience accessors like [margin] and [padding].
  ///
  /// Defaults to 8 pixels. All other tokens ([sp4], [sp6], etc.) are independent
  /// and can be overridden separately.
  final double base;

  /// Extra-small spacing value (4 pixels).
  final double sp4;

  /// Small spacing value (6 pixels).
  final double sp6;

  /// Small spacing value (8 pixels).
  final double sp8;

  /// Small-medium spacing value (10 pixels).
  final double sp10;

  /// Medium spacing value (12 pixels).
  final double sp12;

  /// Medium spacing value (14 pixels).
  final double sp14;

  /// Medium spacing value (16 pixels).
  final double sp16;

  /// Large spacing value (20 pixels).
  final double sp20;

  /// Large spacing value (24 pixels).
  final double sp24;

  /// Large spacing value (28 pixels).
  final double sp28;

  /// Large spacing value (32 pixels).
  final double sp32;

  /// Large spacing value (36 pixels).
  final double sp36;

  /// Large spacing value (40 pixels).
  final double sp40;

  /// Large spacing value (44 pixels).
  final double sp44;

  /// Large spacing value (48 pixels).
  final double sp48;

  /// Creates a new [LayrzSpacingTokens] with all spacing values.
  const LayrzSpacingTokens({
    this.base = 8.0,
    this.sp4 = 4.0,
    this.sp6 = 6.0,
    this.sp8 = 8.0,
    this.sp10 = 10.0,
    this.sp12 = 12.0,
    this.sp14 = 14.0,
    this.sp16 = 16.0,
    this.sp20 = 20.0,
    this.sp24 = 24.0,
    this.sp28 = 28.0,
    this.sp32 = 32.0,
    this.sp36 = 36.0,
    this.sp40 = 40.0,
    this.sp44 = 44.0,
    this.sp48 = 48.0,
  });

  /// The base spacing value as a [Size], used by convenience accessors.
  Size get spacingSize => Size(base, base);

  /// A [SizedBox] with width and height set to [base].
  Widget get sizedBox => SizedBox.fromSize(size: spacingSize);

  /// [EdgeInsets] with all sides set to [base].
  EdgeInsets get margin => EdgeInsets.all(base);

  /// [EdgeInsets] with all sides set to half of [base].
  EdgeInsets get reducedMargin => EdgeInsets.all(base / 2);

  /// [EdgeInsets] with all sides set to [base].
  EdgeInsets get padding => EdgeInsets.all(base);

  /// Returns a copy of this spacing tokens object with the given fields replaced.
  LayrzSpacingTokens copyWith({
    double? base,
    double? sp4,
    double? sp6,
    double? sp8,
    double? sp10,
    double? sp12,
    double? sp14,
    double? sp16,
    double? sp20,
    double? sp24,
    double? sp28,
    double? sp32,
    double? sp36,
    double? sp40,
    double? sp44,
    double? sp48,
  }) {
    return LayrzSpacingTokens(
      base: base ?? this.base,
      sp4: sp4 ?? this.sp4,
      sp6: sp6 ?? this.sp6,
      sp8: sp8 ?? this.sp8,
      sp10: sp10 ?? this.sp10,
      sp12: sp12 ?? this.sp12,
      sp14: sp14 ?? this.sp14,
      sp16: sp16 ?? this.sp16,
      sp20: sp20 ?? this.sp20,
      sp24: sp24 ?? this.sp24,
      sp28: sp28 ?? this.sp28,
      sp32: sp32 ?? this.sp32,
      sp36: sp36 ?? this.sp36,
      sp40: sp40 ?? this.sp40,
      sp44: sp44 ?? this.sp44,
      sp48: sp48 ?? this.sp48,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzSpacingTokens &&
          runtimeType == other.runtimeType &&
          base == other.base &&
          sp4 == other.sp4 &&
          sp6 == other.sp6 &&
          sp8 == other.sp8 &&
          sp10 == other.sp10 &&
          sp12 == other.sp12 &&
          sp14 == other.sp14 &&
          sp16 == other.sp16 &&
          sp20 == other.sp20 &&
          sp24 == other.sp24 &&
          sp28 == other.sp28 &&
          sp32 == other.sp32 &&
          sp36 == other.sp36 &&
          sp40 == other.sp40 &&
          sp44 == other.sp44 &&
          sp48 == other.sp48;

  @override
  int get hashCode => Object.hashAll(<double>[
    base,
    sp4,
    sp6,
    sp8,
    sp10,
    sp12,
    sp14,
    sp16,
    sp20,
    sp24,
    sp28,
    sp32,
    sp36,
    sp40,
    sp44,
    sp48,
  ]);
}
