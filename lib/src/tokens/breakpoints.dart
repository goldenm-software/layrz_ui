import 'package:flutter/widgets.dart';

/// Enumeration of responsive breakpoint bands.
///
/// Each band represents a range of viewport widths. Bands are used by [LayrzCol]
/// and related grid components to select responsive column spans and styling.
enum LayrzBreakpoint {
  /// Extra-small screens: viewport width < 600px.
  xs,

  /// Small screens: viewport width from 600px to < 960px.
  sm,

  /// Medium screens: viewport width from 960px to < 1264px.
  md,

  /// Large screens: viewport width from 1264px to < 1904px.
  lg,

  /// Extra-large screens: viewport width >= 1904px.
  xl,
}

/// Immutable breakpoint tokens defining responsive band thresholds.
///
/// [LayrzBreakpointTokens] defines the pixel-width thresholds that determine
/// which breakpoint band a viewport width falls into. The field names represent
/// the *upper bound of the band below*:
/// - [xs] = 600: xs band is < 600; sm band starts at 600
/// - [sm] = 960: sm band is 600–959; md band starts at 960
/// - [md] = 1264: md band is 960–1263; lg band starts at 1264
/// - [lg] = 1904: lg band is 1264–1903; xl band starts at 1904
///
/// Apps can override these thresholds to customize responsive breakpoints.
/// When overridden, all components that read from these tokens will adapt
/// their behavior accordingly. For example, a custom [LayrzBreakpointTokens]
/// with `xs: 500` will place a width of 550 in the `sm` band instead of `xs`.
@immutable
class LayrzBreakpointTokens {
  /// The upper bound (exclusive) for the extra-small (xs) band in logical pixels.
  ///
  /// Screens with viewport width < 600 are in the xs band.
  /// Screens with viewport width >= 600 are in the sm band or higher.
  ///
  /// Defaults to 600 pixels.
  final double xs;

  /// The upper bound (exclusive) for the small (sm) band in logical pixels.
  ///
  /// Screens with viewport width 600–959 are in the sm band.
  /// Screens with viewport width >= 960 are in the md band or higher.
  ///
  /// Defaults to 960 pixels.
  final double sm;

  /// The upper bound (exclusive) for the medium (md) band in logical pixels.
  ///
  /// Screens with viewport width 960–1263 are in the md band.
  /// Screens with viewport width >= 1264 are in the lg band or higher.
  ///
  /// Defaults to 1264 pixels.
  final double md;

  /// The upper bound (exclusive) for the large (lg) band in logical pixels.
  ///
  /// Screens with viewport width 1264–1903 are in the lg band.
  /// Screens with viewport width >= 1904 are in the xl band.
  ///
  /// Defaults to 1904 pixels.
  final double lg;

  /// Creates a new [LayrzBreakpointTokens] with all threshold values.
  ///
  /// The [xs], [sm], [md], and [lg] parameters define the upper bounds
  /// (exclusive) of their respective bands. These must be in strictly
  /// ascending order (xs < sm < md < lg), though this is not asserted
  /// at construction time — invalid configurations will produce undefined
  /// behavior in [bandAt].
  const LayrzBreakpointTokens({
    this.xs = 600.0,
    this.sm = 960.0,
    this.md = 1264.0,
    this.lg = 1904.0,
  });

  /// Resolves the breakpoint band for a given viewport width.
  ///
  /// The band is determined by comparing [width] against the thresholds:
  /// - width < [xs] → [LayrzBreakpoint.xs]
  /// - [xs] ≤ width < [sm] → [LayrzBreakpoint.sm]
  /// - [sm] ≤ width < [md] → [LayrzBreakpoint.md]
  /// - [md] ≤ width < [lg] → [LayrzBreakpoint.lg]
  /// - width ≥ [lg] → [LayrzBreakpoint.xl]
  LayrzBreakpoint bandAt(double width) {
    if (width < xs) {
      return LayrzBreakpoint.xs;
    } else if (width < sm) {
      return LayrzBreakpoint.sm;
    } else if (width < md) {
      return LayrzBreakpoint.md;
    } else if (width < lg) {
      return LayrzBreakpoint.lg;
    } else {
      return LayrzBreakpoint.xl;
    }
  }

  /// Returns a copy of this breakpoint tokens object with the given fields replaced.
  LayrzBreakpointTokens copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
  }) {
    return LayrzBreakpointTokens(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzBreakpointTokens &&
          runtimeType == other.runtimeType &&
          xs == other.xs &&
          sm == other.sm &&
          md == other.md &&
          lg == other.lg;

  @override
  int get hashCode => Object.hash(xs, sm, md, lg);
}
