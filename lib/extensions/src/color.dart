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
  /// Uses the WCAG relative luminance formula with a 0.179 threshold.
  Color get contrastColor {
    final luminance = computeLuminance();
    return luminance > 0.179 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  }

  /// Returns this color at the given [opacity] (0.0–1.0).
  ///
  /// [opacity] must be between 0.0 and 1.0 inclusive.
  Color withOpacityValue(double opacity) => withValues(alpha: opacity);
}
