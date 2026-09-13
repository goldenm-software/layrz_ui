import 'dart:ui';

import 'package:layrz_ui/src/colorblindness/src/filters.dart';

/// The color-vision deficiency simulation mode applied by [LayrzApp]'s
/// `colorblindMode` parameter.
///
/// Each non-[normal] value corresponds to a real, named form of color vision
/// deficiency and maps to a matrix [ColorFilter] (see [ColorblindFilter])
/// that approximates how colors on screen appear to someone with that
/// condition. Wiring this at the app root lets a sighted developer or
/// designer preview the app under each condition; it is a simulation aid,
/// not an accessibility fix in itself.
///
/// `layrz_ui` defines this enum locally rather than depending on an external
/// package (such as `layrz_sdk`) that would pull in a transitive Material
/// dependency and violate this package's Material-free invariant.
enum ColorblindMode {
  /// Simulates protanopia — complete red blindness (missing red cone cells).
  protanopia,

  /// Simulates protanomaly — red-weak color vision (reduced red cone
  /// sensitivity, milder than [protanopia]).
  protanomaly,

  /// Simulates deuteranopia — complete green blindness (missing green cone
  /// cells). This is the most common form of color vision deficiency.
  deuteranopia,

  /// Simulates deuteranomaly — green-weak color vision (reduced green cone
  /// sensitivity, milder than [deuteranopia]).
  deuteranomaly,

  /// Simulates tritanopia — complete blue blindness (missing blue cone
  /// cells). Rare.
  tritanopia,

  /// Simulates tritanomaly — blue-weak color vision (reduced blue cone
  /// sensitivity, milder than [tritanopia]).
  tritanomaly,

  /// No colour-vision-deficiency simulation applied (typical colour vision).
  /// Colors render unmodified. This is the default for [LayrzApp].
  normal;

  /// Maps each [ColorblindMode] value to its uppercase JSON wire string.
  ///
  /// Kept as a hand-written map (rather than `json_serializable`/`@JsonEnum`)
  /// so this module stays free of `build_runner` codegen.
  static const Map<ColorblindMode, String> _jsonValues = {
    ColorblindMode.protanopia: 'PROTANOPIA',
    ColorblindMode.protanomaly: 'PROTANOMALY',
    ColorblindMode.deuteranopia: 'DEUTERANOPIA',
    ColorblindMode.deuteranomaly: 'DEUTERANOMALY',
    ColorblindMode.tritanopia: 'TRITANOPIA',
    ColorblindMode.tritanomaly: 'TRITANOMALY',
    ColorblindMode.normal: 'NORMAL',
  };

  /// Serializes this value to its uppercase JSON wire string, e.g.
  /// [ColorblindMode.deuteranopia] becomes `'DEUTERANOPIA'`.
  String toJson() => _jsonValues[this]!;

  /// Parses a [ColorblindMode] back from its uppercase JSON wire string.
  ///
  /// [json] is matched case-sensitively against the strings produced by
  /// [toJson]. Falls back to [ColorblindMode.normal] when [json] does not
  /// match any known value, so callers never need to handle a parse
  /// exception for malformed or unrecognized input.
  static ColorblindMode fromJson(String json) {
    for (final entry in _jsonValues.entries) {
      if (entry.value == json) return entry.key;
    }
    return ColorblindMode.normal;
  }
}

/// Resolves a [ColorblindMode] to the matrix [ColorFilter] that simulates it.
extension ColorblindFilter on ColorblindMode {
  /// Returns the [ColorFilter] for this mode at the given [strength] (`0.0` =
  /// no effect / identity, `1.0` = full simulation). Values interpolate
  /// linearly between identity and the full simulation matrix.
  ///
  /// [ColorblindMode.normal] always returns the identity [ColorFilter.matrix]
  /// regardless of [strength], since there is no simulation to apply.
  ColorFilter filter(double strength) {
    switch (this) {
      case ColorblindMode.protanopia:
        return ColorFilter.matrix(protanopiaFilter(strength));
      case ColorblindMode.protanomaly:
        return ColorFilter.matrix(protanomalyFilter(strength));
      case ColorblindMode.deuteranopia:
        return ColorFilter.matrix(deuteranopiaFilter(strength));
      case ColorblindMode.deuteranomaly:
        return ColorFilter.matrix(deuteranomalyFilter(strength));
      case ColorblindMode.tritanopia:
        return ColorFilter.matrix(tritanopiaFilter(strength));
      case ColorblindMode.tritanomaly:
        return ColorFilter.matrix(tritanomalyFilter(strength));
      case ColorblindMode.normal:
        return const ColorFilter.matrix(identityMatrix);
    }
  }
}
