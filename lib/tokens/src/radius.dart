import 'dart:math';

import 'package:flutter/widgets.dart';

/// Immutable border radius tokens for rounded corners in the design system.
///
/// Radius values are typically paired with containers to define border curves.
/// The [innerRadius] method computes visually consistent inner radii for nested
/// container borders.
@immutable
class LayrzRadiusTokens {
  /// Base radius value used in convenience accessors like [borderRadius].
  ///
  /// Defaults to 8 pixels. All other tokens ([r8], [r10], etc.) are independent
  /// and can be overridden separately.
  final double base;

  /// Border radius of 8 pixels.
  final double r8;

  /// Border radius of 10 pixels.
  final double r10;

  /// Border radius of 12 pixels.
  final double r12;

  /// Border radius of 14 pixels.
  final double r14;

  /// Border radius of 16 pixels.
  final double r16;

  /// Border radius of 20 pixels.
  final double r20;

  /// Border radius of 24 pixels.
  final double r24;

  /// Fully rounded border radius (pill shape), set to 999 pixels.
  final double full;

  /// Creates a new [LayrzRadiusTokens] with all border radius values.
  const LayrzRadiusTokens({
    this.base = 8.0,
    this.r8 = 8.0,
    this.r10 = 10.0,
    this.r12 = 12.0,
    this.r14 = 14.0,
    this.r16 = 16.0,
    this.r20 = 20.0,
    this.r24 = 24.0,
    this.full = 999.0,
  });

  /// [BorderRadius] with all corners set to [base].
  BorderRadius get borderRadius => BorderRadius.circular(base);

  /// Computes a visually consistent inner radius given an outer radius and spacer.
  ///
  /// This method maintains visual consistency when drawing nested container borders.
  /// It subtracts the [spacer] from the [outerRadius] to determine the inner radius,
  /// but clamps the result to zero to never produce negative radius values.
  ///
  /// For example, given `outerRadius: 12, spacer: 4`, the inner radius is 8.
  /// Given `outerRadius: 4, spacer: 10`, the inner radius clamps to 0 (pill shape).
  BorderRadius innerRadius({
    required double outerRadius,
    required double spacer,
  }) {
    final radius = max(outerRadius - spacer, 0.0);
    return BorderRadius.circular(radius);
  }

  /// Returns a copy of this radius tokens object with the given fields replaced.
  LayrzRadiusTokens copyWith({
    double? base,
    double? r8,
    double? r10,
    double? r12,
    double? r14,
    double? r16,
    double? r20,
    double? r24,
    double? full,
  }) {
    return LayrzRadiusTokens(
      base: base ?? this.base,
      r8: r8 ?? this.r8,
      r10: r10 ?? this.r10,
      r12: r12 ?? this.r12,
      r14: r14 ?? this.r14,
      r16: r16 ?? this.r16,
      r20: r20 ?? this.r20,
      r24: r24 ?? this.r24,
      full: full ?? this.full,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzRadiusTokens &&
          runtimeType == other.runtimeType &&
          base == other.base &&
          r8 == other.r8 &&
          r10 == other.r10 &&
          r12 == other.r12 &&
          r14 == other.r14 &&
          r16 == other.r16 &&
          r20 == other.r20 &&
          r24 == other.r24 &&
          full == other.full;

  @override
  int get hashCode => Object.hash(base, r8, r10, r12, r14, r16, r20, r24, full);
}
