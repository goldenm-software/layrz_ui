import 'package:flutter/widgets.dart';

/// Immutable shadow tokens for elevation-based drop shadows in the design system.
///
/// Shadow tokens provide two parallel ramps tuned for different component sizes:
/// - **elevationN** — large surfaces: cards, dialogs, sheets, section containers.
///   Softer and wider, with blur = 3 × elevation + 2 and opacity 10%–22%.
/// - **compactN** — small components: buttons, chips, menu items, badges.
///   Darker with greater vertical drop, giving small elements clear separation
///   from the surface where a faint low-offset shadow disappears. Compact shadows
///   use a shifted elevation curve (elevation + 2) with opacity 18%–30%.
///
/// The algorithm computes blur radius, opacity, and offset based on elevation
/// to create a consistent visual hierarchy.
///
/// This implementation is light-theme only (decision D7: dark mode is out of scope).
@immutable
class LayrzShadowTokens {
  /// Surface color (card background) used in shadow calculations.
  ///
  /// Defaults to #FCFCFC (light gray). Used as the base surface color for the
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
    this.surfaceColor = const Color(0xFFFCFCFC),
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

  /// Box shadow at compact level 1 (small components).
  List<BoxShadow> get compact1 => _compactShadows(elevation: 1, radius: baseRadius);

  /// Box shadow at compact level 2 (small components).
  List<BoxShadow> get compact2 => _compactShadows(elevation: 2, radius: baseRadius);

  /// Box shadow at compact level 3 (small components).
  List<BoxShadow> get compact3 => _compactShadows(elevation: 3, radius: baseRadius);

  /// Box shadow at compact level 4 (small components).
  List<BoxShadow> get compact4 => _compactShadows(elevation: 4, radius: baseRadius);

  /// Box shadow at compact level 5 (small components).
  List<BoxShadow> get compact5 => _compactShadows(elevation: 5, radius: baseRadius);

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

  /// Generates a [BoxDecoration] with compact-ramp shadow and optional outline.
  ///
  /// The [elevation] must be between 0 and 5 inclusive. The [radius] defaults to
  /// [baseRadius] if not provided.
  ///
  /// Compact shadows are darker with greater vertical drop than the elevation ramp,
  /// making them suitable for small components like buttons and chips. The larger
  /// offset provides clear separation at small sizes where a faint low-offset
  /// shadow dissolves into the surface. At elevation 0, no shadow is applied, but
  /// a 1-pixel outline border is drawn (unless [hideOnElevationZero] is true).
  ///
  /// The [reverse] parameter flips the shadow offset's vertical direction, useful
  /// for pressed button states.
  ///
  /// The [color] defaults to [surfaceColor] if not provided.
  /// The [shadowColor] defaults to the instance's [shadowColor] if not provided.
  BoxDecoration compact({
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
        ? _compactShadows(elevation: elevation, radius: r, reverse: reverse)
        : null;

    final Border? border = (elevation == 0 && !hideOnElevationZero) ? Border.all(color: outlineColor, width: 1) : null;

    return BoxDecoration(
      color: surfaceCol,
      borderRadius: BorderRadius.circular(r),
      border: border,
      boxShadow: shadows,
    );
  }

  /// Private helper that generates shadows for the elevation ramp.
  ///
  /// Delegates to [_generateShadowsWithFormula] with elevation ramp parameters:
  /// opacity 10%–22%, blur = 3 × elevation + 2.
  List<BoxShadow> _generateShadows({
    required double elevation,
    required double radius,
    bool reverse = false,
  }) {
    return _generateShadowsWithFormula(
      elevation: elevation,
      radius: radius,
      minOpacity: 0.10,
      maxOpacity: 0.22,
      blurMultiplier: 3.0,
      blurOffset: 2.0,
      reverse: reverse,
    );
  }

  /// Private helper that generates shadows for the compact ramp.
  ///
  /// Applies a shift (elevation + 2) to the compact curve, resulting in darker
  /// shadows with greater vertical drop suitable for small components. Delegates
  /// to [_generateShadowsWithFormula] with compact ramp parameters:
  /// opacity 18%–30%, blur = 1.5 × (elevation + 2) + 1.5.
  List<BoxShadow> _compactShadows({
    required double elevation,
    required double radius,
    bool reverse = false,
  }) {
    final e = elevation + 2;
    return _generateShadowsWithFormula(
      elevation: e,
      radius: radius,
      minOpacity: 0.18,
      maxOpacity: 0.30,
      blurMultiplier: 1.5,
      blurOffset: 1.5,
      maxElevation: 7.0,
      reverse: reverse,
    );
  }

  /// Core shadow generator parameterized by opacity range and blur coefficients.
  ///
  /// Emits a single shadow with opacity and blur that scale with elevation.
  /// Opacity ranges from [minOpacity] to [maxOpacity] via linear interpolation.
  /// Blur radius scales as `blurMultiplier × elevation + blurOffset`;
  /// offset increases linearly with elevation.
  ///
  /// The [maxElevation] parameter controls the upper bound for the opacity
  /// interpolation curve (default 5.0 for elevation ramp, 7.0 for compact ramp).
  ///
  /// Returns empty list if elevation <= 0.
  List<BoxShadow> _generateShadowsWithFormula({
    required double elevation,
    required double radius,
    required double minOpacity,
    required double maxOpacity,
    required double blurMultiplier,
    required double blurOffset,
    double maxElevation = 5.0,
    bool reverse = false,
  }) {
    if (elevation <= 0) {
      return <BoxShadow>[];
    }

    final t = elevation.clamp(0, maxElevation) / 5.0;
    final opacity = minOpacity + (maxOpacity - minOpacity) * t;
    final blur = blurMultiplier * elevation + blurOffset;
    var offset = elevation;
    if (reverse) {
      offset = -offset;
    }

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
