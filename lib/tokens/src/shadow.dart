import 'package:flutter/widgets.dart';

/// Immutable shadow tokens for elevation-based drop shadows in the design system.
///
/// Shadow tokens map elevation levels (0–5) to [BoxShadow] lists. The algorithm
/// computes blur radius, opacity, and offset based on elevation to create a
/// consistent visual hierarchy.
///
/// This implementation is light-theme only (decision D7: dark mode is out of scope).
@immutable
class LayrzShadowTokens {
  /// Surface color (card background) used in shadow calculations.
  ///
  /// Defaults to white (#FFFFFF). Used as the base surface color for the
  /// elevation algorithm.
  final Color surfaceColor;

  /// Base border radius for shadow calculations.
  ///
  /// Defaults to 8 pixels. Used when [elevation] is called without an explicit [radius].
  final double baseRadius;

  /// Shadow color used in the elevation algorithm.
  ///
  /// Defaults to black. When not provided to [elevation], this color is used
  /// and then alpha-adjusted based on the elevation level.
  final Color shadowColor;

  /// Outline color for the 1-pixel border at elevation 0.
  ///
  /// Defaults to black at 10% opacity. Used when drawing the outline at elevation 0
  /// (when [hideOnElevationZero] is false).
  final Color outlineColor;

  /// Creates a new [LayrzShadowTokens].
  const LayrzShadowTokens({
    this.surfaceColor = const Color(0xFFFFFFFF),
    this.baseRadius = 8.0,
    this.shadowColor = const Color(0xFF000000),
    this.outlineColor = const Color.fromRGBO(0, 0, 0, 0.1),
  });

  /// Box shadow at elevation level 1.
  List<BoxShadow> get elevation1 => _generateShadows(elevation: 1, radius: baseRadius);

  /// Box shadow at elevation level 2.
  List<BoxShadow> get elevation2 => _generateShadows(elevation: 2, radius: baseRadius);

  /// Box shadow at elevation level 3.
  List<BoxShadow> get elevation3 => _generateShadows(elevation: 3, radius: baseRadius);

  /// Box shadow at elevation level 4.
  List<BoxShadow> get elevation4 => _generateShadows(elevation: 4, radius: baseRadius);

  /// Box shadow at elevation level 5.
  List<BoxShadow> get elevation5 => _generateShadows(elevation: 5, radius: baseRadius);

  /// Generates a [BoxDecoration] with elevation-based shadow and optional outline.
  ///
  /// The [elevation] must be between 0 and 5 inclusive. The [radius] defaults to
  /// [baseRadius] if not provided.
  ///
  /// At elevation 0, no shadow is applied, but a 1-pixel outline border is drawn
  /// (unless [hideOnElevationZero] is true).
  ///
  /// The [reverse] parameter flips the shadow offset's vertical direction, useful
  /// for raised or pressed button states.
  ///
  /// The [color] defaults to [surfaceColor] if not provided.
  /// The [shadowColor] defaults to the instance's [shadowColor] if not provided.
  BoxDecoration elevation({
    double elevation = 1,
    double? radius,
    Color? color,
    Color? shadowColor,
    bool reverse = false,
    bool hideOnElevationZero = false,
  }) {
    assert(
      elevation >= 0 && elevation <= 5,
      'elevation must be between 0 and 5',
    );
    assert(radius == null || radius >= 0, 'radius must be non-negative');

    final r = radius ?? baseRadius;
    final surfaceCol = color ?? surfaceColor;

    final List<BoxShadow>? shadows = elevation > 0
        ? _generateShadows(elevation: elevation, radius: r, reverse: reverse)
        : null;

    final Border? border = (elevation == 0 && !hideOnElevationZero) ? Border.all(color: outlineColor, width: 1) : null;

    return BoxDecoration(
      color: surfaceCol,
      borderRadius: BorderRadius.circular(r),
      border: border,
      boxShadow: shadows,
    );
  }

  /// Private helper that generates shadows for a given elevation level.
  List<BoxShadow> _generateShadows({
    required double elevation,
    required double radius,
    bool reverse = false,
  }) {
    if (elevation <= 0) {
      return <BoxShadow>[];
    }

    // Compute opacity: linear interpolation from 0.06 (elevation 0) to 0.12 (elevation 5)
    final t = elevation.clamp(0, 5) / 5.0;
    final opacity = 0.06 + (0.12 - 0.06) * t;

    // Compute blur radius: 3 * elevation + 2
    final blur = 3 * elevation + 2.0;

    // Compute vertical offset: (elevation - 1) pixels down, reversed if needed
    var offset = elevation - 1.0;
    if (reverse) {
      offset = -offset;
    }

    // Create the main shadow
    return <BoxShadow>[
      BoxShadow(
        color: shadowColor.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: 0,
        offset: Offset(0, offset),
      ),
    ];
  }

  /// Returns a copy of this shadow tokens object with the given fields replaced.
  LayrzShadowTokens copyWith({
    Color? surfaceColor,
    double? baseRadius,
    Color? shadowColor,
    Color? outlineColor,
  }) {
    return LayrzShadowTokens(
      surfaceColor: surfaceColor ?? this.surfaceColor,
      baseRadius: baseRadius ?? this.baseRadius,
      shadowColor: shadowColor ?? this.shadowColor,
      outlineColor: outlineColor ?? this.outlineColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzShadowTokens &&
          runtimeType == other.runtimeType &&
          surfaceColor == other.surfaceColor &&
          baseRadius == other.baseRadius &&
          shadowColor == other.shadowColor &&
          outlineColor == other.outlineColor;

  @override
  int get hashCode => Object.hash(surfaceColor, baseRadius, shadowColor, outlineColor);
}
