import 'package:flutter/widgets.dart';

/// Configuration for [LayrzApp]'s debug-only tiled diagonal watermark.
///
/// Passing a non-null [LayrzAppBanner] to `LayrzApp.banner` replaces Flutter's
/// red DEBUG corner banner with a low-opacity, tiled, diagonal watermark that
/// repeats [labelText] across the whole screen. Unlike the SDK's corner
/// banner, this cannot be mistaken for production because it survives
/// cropping (it is not confined to one corner) and it does not obscure any
/// single element, since it renders at low opacity behind the app content and
/// never intercepts pointer events.
///
/// This watermark only ever renders when `kDebugMode` is `true` — see
/// `LayrzApp._wrapWithTheme`. Passing a non-null [LayrzAppBanner] also forces
/// `LayrzApp.debugShowCheckedModeBanner` to `false` internally, so the SDK's
/// own checked-mode banner and this watermark never stack on top of each
/// other.
///
/// There is deliberately no style enum — this is the one tiled-diagonal style
/// that solves the "don't mistake this screenshot for production" problem
/// (see DESIGN-114, DESIGN-27, DESIGN-28).
@immutable
class LayrzAppBanner {
  /// The text repeated across the tiled diagonal watermark, for example
  /// `'STAGING'` or `'INTERNAL BUILD'`.
  final String labelText;

  /// The color the watermark text is painted in, before the painter's own
  /// low-opacity alpha is applied.
  ///
  /// When `null`, `LayrzApp` resolves a muted, neutral default from the
  /// active theme's design tokens at paint time
  /// (`LayrzColorTokens.watermark`), rather than this class hardcoding a
  /// color independent of the caller's theme.
  final Color? color;

  /// Creates a [LayrzAppBanner] configuring `LayrzApp`'s debug-only tiled
  /// diagonal watermark.
  const LayrzAppBanner({
    required this.labelText,
    this.color,
  });

  /// Returns a copy of this [LayrzAppBanner] with the given fields replaced.
  ///
  /// [labelText] replaces [LayrzAppBanner.labelText] when provided.
  /// [color] replaces [LayrzAppBanner.color] when provided. To explicitly
  /// clear an existing [color] back to `null`, construct a new
  /// [LayrzAppBanner] instead of using [copyWith].
  LayrzAppBanner copyWith({
    String? labelText,
    Color? color,
  }) {
    return LayrzAppBanner(
      labelText: labelText ?? this.labelText,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LayrzAppBanner && labelText == other.labelText && color == other.color;

  @override
  int get hashCode => Object.hash(labelText, color);
}
