import 'package:flutter/widgets.dart';

/// Extensions on [Color] for hex serialization, integer conversion,
/// and contrast utilities.
extension LayrzColorExtensions on Color {
  /// Serializes this color to a JSON-safe hex string (no alpha). Alias for [toHex].
  String toJson() => toHex();

  /// Returns a 6-digit uppercase hex string without alpha, e.g. `#001E60`.
  String toHex() {
    final r = (this.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (this.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (this.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  /// Alias for [toHex].
  String get hex => toHex();

  /// Returns an 8-digit uppercase hex string with alpha first, e.g. `#FF001E60`.
  String toHexWithAlpha() {
    final a = (this.a * 255).round().toRadixString(16).padLeft(2, '0');
    final r = (this.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (this.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (this.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$a$r$g$b'.toUpperCase();
  }

  /// Alias for [toHexWithAlpha].
  String get hexWithAlpha => toHexWithAlpha();

  /// Encodes this color as a 32-bit ARGB integer.
  int toInt() {
    int toChannel(double x) => (x * 255.0).round() & 0xff;
    return toChannel(a) << 24 | toChannel(r) << 16 | toChannel(g) << 8 | toChannel(b);
  }

  /// Deserializes a color from a JSON hex string. Alias for [fromHex].
  static Color fromJson(String json) => fromHex(json);

  /// Parses a 6-digit hex string (with or without leading `#`) into a [Color].
  ///
  /// [hex] must be in the format `#RRGGBB` or `RRGGBB`.
  static Color fromHex(String hex) {
    final s = hex.startsWith('#') ? hex.substring(1) : hex;
    return Color.fromARGB(
      255,
      int.parse(s.substring(0, 2), radix: 16),
      int.parse(s.substring(2, 4), radix: 16),
      int.parse(s.substring(4, 6), radix: 16),
    );
  }

  /// Parses an 8-digit hex string (with or without leading `#`) into a [Color].
  ///
  /// [hex] must be in the format `#AARRGGBB` or `AARRGGBB`.
  static Color fromHexWithAlpha(String hex) {
    final s = hex.startsWith('#') ? hex.substring(1) : hex;
    return Color.fromARGB(
      int.parse(s.substring(0, 2), radix: 16),
      int.parse(s.substring(2, 4), radix: 16),
      int.parse(s.substring(4, 6), radix: 16),
      int.parse(s.substring(6, 8), radix: 16),
    );
  }

  /// Returns black or white, whichever has better contrast against this color.
  ///
  /// This implementation matches Material's `estimateBrightnessForColor` algorithm
  /// and threshold to ensure consistency across the Flutter ecosystem. It uses the formula:
  ///
  /// ```dart
  /// const threshold = 0.15;
  /// final v = (luminance + 0.05);
  /// return v * v > threshold ? black : white;
  /// ```
  ///
  /// This threshold (0.15) intentionally favours white text more than the strict WCAG 2.0
  /// recommendation. The WCAG spec equivalent is `kThreshold=0.0525`, which corresponds
  /// to a luminance crossover of approximately 0.179 (the value previously used here).
  ///
  /// **Trade-off**: Colours like the Material `success` green (`#4CAF50`, luminance ≈ 0.328)
  /// will use white text, resulting in a contrast ratio of about 2.78:1, which falls
  /// below the 4.5:1 AA threshold. Callers requiring strict WCAG AA compliance should
  /// favour darker accent colours rather than adjusting this threshold.
  ///
  /// See also [opposite], a shorthand alias for this getter.
  Color get contrastColor {
    final luminance = computeLuminance();
    const threshold = 0.15;
    final v = luminance + 0.05;
    return v * v > threshold ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  }

  /// Alias for [contrastColor].
  ///
  /// Returns black or white, whichever has better contrast against this color.
  /// Provided as a shorthand at call sites; [contrastColor] is the canonical
  /// name and the two are always identical.
  Color get opposite => contrastColor;

  /// Returns this color at the given [opacity] (0.0–1.0).
  ///
  /// [opacity] must be between 0.0 and 1.0 inclusive.
  Color withOpacityValue(double opacity) => withValues(alpha: opacity);
}
