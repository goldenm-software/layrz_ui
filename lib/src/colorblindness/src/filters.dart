import 'dart:ui' show ColorFilter;

/// The 4x5 identity color matrix — the matrix a [ColorFilter.matrix] must be
/// given to leave colors completely unchanged.
///
/// Every filter function in this file interpolates linearly between this
/// identity matrix (at `strength == 0.0`) and its own base simulation matrix
/// (at `strength == 1.0`).
const List<double> identityMatrix = [
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
];

/// Linearly interpolates between [identityMatrix] and [baseMatrix] by
/// [strength].
///
/// [baseMatrix] is the full-effect (`strength == 1.0`) 4x5 color matrix for a
/// specific colorblindness simulation. [strength] is clamped conceptually to
/// the `0.0`-`1.0` range by callers (`0.0` is identity, `1.0` is the full
/// [baseMatrix]); values outside that range extrapolate rather than clamp.
///
/// Returns a new 20-element list suitable for [ColorFilter.matrix].
List<double> _lerpMatrix(List<double> baseMatrix, double strength) {
  return List.generate(20, (i) => identityMatrix[i] * (1 - strength) + baseMatrix[i] * strength);
}

/// The base (full-effect) color matrix simulating protanopia (red-blind
/// color vision), verbatim from the color-science matrix used by the legacy
/// `layrz_theme` design system.
const List<double> _protanopiaBaseMatrix = [
  0.567, 0.433, 0.0, 0.0, 0.0, //
  0.558, 0.442, 0.0, 0.0, 0.0,
  0.0, 0.242, 0.758, 0.0, 0.0,
  0.0, 0.0, 0.0, 1.0, 0.0,
];

/// Returns the protanopia (red-blind) simulation color matrix at the given
/// [strength] (`0.0` = identity / no effect, `1.0` = full simulation).
List<double> protanopiaFilter(double strength) => _lerpMatrix(_protanopiaBaseMatrix, strength);

/// The base (full-effect) color matrix simulating protanomaly (red-weak
/// color vision), verbatim from the color-science matrix used by the legacy
/// `layrz_theme` design system.
const List<double> _protanomalyBaseMatrix = [
  0.817, 0.183, 0.0, 0.0, 0.0, //
  0.333, 0.667, 0.0, 0.0, 0.0,
  0.0, 0.125, 0.875, 0.0, 0.0,
  0.0, 0.0, 0.0, 1.0, 0.0,
];

/// Returns the protanomaly (red-weak) simulation color matrix at the given
/// [strength] (`0.0` = identity / no effect, `1.0` = full simulation).
List<double> protanomalyFilter(double strength) => _lerpMatrix(_protanomalyBaseMatrix, strength);

/// The base (full-effect) color matrix simulating deuteranopia (green-blind
/// color vision), verbatim from the color-science matrix used by the legacy
/// `layrz_theme` design system.
const List<double> _deuteranopiaBaseMatrix = [
  0.8, 0.2, 0.0, 0.0, 0.0, //
  0.258, 0.742, 0.0, 0.0, 0.0,
  0.0, 0.141, 0.859, 0.0, 0.0,
  0.0, 0.0, 0.0, 1.0, 0.0,
];

/// Returns the deuteranopia (green-blind) simulation color matrix at the
/// given [strength] (`0.0` = identity / no effect, `1.0` = full simulation).
List<double> deuteranopiaFilter(double strength) => _lerpMatrix(_deuteranopiaBaseMatrix, strength);

/// The base (full-effect) color matrix simulating deuteranomaly (green-weak
/// color vision), verbatim from the color-science matrix used by the legacy
/// `layrz_theme` design system.
const List<double> _deuteranomalyBaseMatrix = [
  0.8, 0.2, 0.0, 0.0, 0.0, //
  0.3, 0.7, 0.0, 0.0, 0.0,
  0.0, 0.258, 0.742, 0.0, 0.0,
  0.0, 0.0, 0.0, 1.0, 0.0,
];

/// Returns the deuteranomaly (green-weak) simulation color matrix at the
/// given [strength] (`0.0` = identity / no effect, `1.0` = full simulation).
List<double> deuteranomalyFilter(double strength) => _lerpMatrix(_deuteranomalyBaseMatrix, strength);

/// The base (full-effect) color matrix simulating tritanopia (blue-blind
/// color vision), verbatim from the color-science matrix used by the legacy
/// `layrz_theme` design system.
const List<double> _tritanopiaBaseMatrix = [
  0.95, 0.05, 0.0, 0.0, 0.0, //
  0.0, 0.433, 0.567, 0.0, 0.0,
  0.0, 0.475, 0.525, 0.0, 0.0,
  0.0, 0.0, 0.0, 1.0, 0.0,
];

/// Returns the tritanopia (blue-blind) simulation color matrix at the given
/// [strength] (`0.0` = identity / no effect, `1.0` = full simulation).
List<double> tritanopiaFilter(double strength) => _lerpMatrix(_tritanopiaBaseMatrix, strength);

/// The base (full-effect) color matrix simulating tritanomaly (blue-weak
/// color vision), verbatim from the color-science matrix used by the legacy
/// `layrz_theme` design system.
const List<double> _tritanomalyBaseMatrix = [
  0.967, 0.033, 0.0, 0.0, 0.0, //
  0.0, 0.733, 0.267, 0.0, 0.0,
  0.0, 0.183, 0.817, 0.0, 0.0,
  0.0, 0.0, 0.0, 1.0, 0.0,
];

/// Returns the tritanomaly (blue-weak) simulation color matrix at the given
/// [strength] (`0.0` = identity / no effect, `1.0` = full simulation).
List<double> tritanomalyFilter(double strength) => _lerpMatrix(_tritanomalyBaseMatrix, strength);
