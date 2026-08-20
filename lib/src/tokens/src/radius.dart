import 'dart:math';

import 'package:flutter/widgets.dart';

/// Immutable border radius tokens for rounded corners in the design system.
///
/// Border radius values use five semantic levels (1–5) with the following pixel values:
/// - Level 1: 4 pixels
/// - Level 2: 8 pixels
/// - Level 3: 16 pixels
/// - Level 4: 24 pixels
/// - Level 5: 32 pixels
///
/// The [full] member (999.0) creates a pill shape and is kept separately as no
/// level on the 1–5 ramp expresses a pill without hardcoding that value.
/// The [innerRadius] method computes visually consistent inner radii for nested
/// container borders.
@immutable
class LayrzRadiusTokens {
  /// Border radius level 1 — 4 pixels.
  final double r1;

  /// Border radius level 2 — 8 pixels.
  final double r2;

  /// Border radius level 3 — 16 pixels.
  final double r3;

  /// Border radius level 4 — 24 pixels.
  final double r4;

  /// Border radius level 5 — 32 pixels.
  final double r5;

  /// Fully rounded border radius (pill shape), set to 999 pixels.
  final double full;

  /// Creates a new [LayrzRadiusTokens] with all border radius levels.
  const LayrzRadiusTokens({
    this.r1 = 4.0,
    this.r2 = 8.0,
    this.r3 = 16.0,
    this.r4 = 24.0,
    this.r5 = 32.0,
    this.full = 999.0,
  });

  /// Border radius level 1 — [BorderRadius.circular] with 4-pixel radius on all corners.
  BorderRadius get br1 => BorderRadius.circular(r1);

  /// Border radius level 2 — [BorderRadius.circular] with 8-pixel radius on all corners.
  BorderRadius get br2 => BorderRadius.circular(r2);

  /// Border radius level 3 — [BorderRadius.circular] with 16-pixel radius on all corners.
  BorderRadius get br3 => BorderRadius.circular(r3);

  /// Border radius level 4 — [BorderRadius.circular] with 24-pixel radius on all corners.
  BorderRadius get br4 => BorderRadius.circular(r4);

  /// Border radius level 5 — [BorderRadius.circular] with 32-pixel radius on all corners.
  BorderRadius get br5 => BorderRadius.circular(r5);

  /// Computes a visually consistent inner radius value given an outer radius and spacer.
  ///
  /// Returns the scalar radius value (not a BorderRadius object).
  /// This method maintains visual consistency when drawing nested container borders.
  /// It subtracts the [spacer] from the [outerRadius] to determine the inner radius,
  /// but clamps the result to zero to never produce negative radius values.
  ///
  /// For example, given `outerRadius: 12, spacer: 4`, returns 8.0.
  /// Given `outerRadius: 4, spacer: 10`, returns 0.0 (pill shape).
  double innerRadiusValue({
    required double outerRadius,
    required double spacer,
  }) => max(outerRadius - spacer, 0.0);

  /// Computes a visually consistent inner [BorderRadius] given an outer radius and spacer.
  ///
  /// Returns a BorderRadius object with all corners set to the computed inner radius.
  /// This method maintains visual consistency when drawing nested container borders.
  /// It subtracts the [spacer] from the [outerRadius] to determine the inner radius,
  /// but clamps the result to zero to never produce negative radius values.
  ///
  /// For example, given `outerRadius: 12, spacer: 4`, returns BorderRadius.circular(8).
  /// Given `outerRadius: 4, spacer: 10`, returns BorderRadius.circular(0) (pill shape).
  BorderRadius innerRadius({
    required double outerRadius,
    required double spacer,
  }) {
    final radius = max(outerRadius - spacer, 0.0);
    return BorderRadius.circular(radius);
  }

  /// Returns a copy of this radius tokens object with the given fields replaced.
  LayrzRadiusTokens copyWith({
    double? r1,
    double? r2,
    double? r3,
    double? r4,
    double? r5,
    double? full,
  }) {
    return LayrzRadiusTokens(
      r1: r1 ?? this.r1,
      r2: r2 ?? this.r2,
      r3: r3 ?? this.r3,
      r4: r4 ?? this.r4,
      r5: r5 ?? this.r5,
      full: full ?? this.full,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzRadiusTokens &&
          runtimeType == other.runtimeType &&
          r1 == other.r1 &&
          r2 == other.r2 &&
          r3 == other.r3 &&
          r4 == other.r4 &&
          r5 == other.r5 &&
          full == other.full;

  @override
  int get hashCode => Object.hash(r1, r2, r3, r4, r5, full);
}
