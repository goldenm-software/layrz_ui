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

  /// Composites this colour over [background] and returns a fully opaque result.
  ///
  /// Uses [Color.alphaBlend] from `dart:ui` to blend this colour onto [background],
  /// returning the visually identical opaque result.
  ///
  /// **Why this exists**: A translucent fill lets anything painted behind it show through,
  /// including a [BoxDecoration]'s shadow. Shadows render as a smudge inside the box
  /// rather than a shadow beneath it when the fill is translucent. Flattening the colour
  /// onto the surface it will actually be painted over yields the identical pixel colour
  /// while being fully opaque — so shadows render correctly.
  ///
  /// **Important caveat**: The result is visually identical only when painted directly
  /// over [background]. If this colour will be painted over a different surface, the
  /// flattened result will be incorrect.
  ///
  /// Example: flatten a 20% accent tint onto the surface token:
  /// ```dart
  /// final tonal = accent.withOpacityValue(0.2);
  /// final opaque = tonal.flattenOn(tokens.colors.sf1);
  /// // opaque is fully opaque and has the same colour as tonal would appear on surface
  /// ```
  Color flattenOn(Color background) => Color.alphaBlend(this, background);

  /// Whether this colour is fully opaque.
  ///
  /// Returns true if the alpha channel is at maximum (fully opaque),
  /// false otherwise (including fully transparent and partially transparent).
  bool get isOpaque => a == 1.0;
}
