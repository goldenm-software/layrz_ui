import 'package:flutter/widgets.dart';

import 'font.dart';

/// Resolves [LayrzFont]s into usable font family names and preloads their bytes.
///
/// Implementations may fetch fonts from Google Fonts, local assets, or arbitrary URIs.
abstract class LayrzFontHandler {
  /// Creates a new [LayrzFontHandler].
  const LayrzFontHandler();

  /// Ensures the bytes for [font] are available to the engine before first paint.
  ///
  /// Implementations may download font bytes, load them from local assets, or
  /// register them with the Flutter engine as needed. This method completes
  /// when the font is ready for use.
  ///
  /// Parameters:
  ///   - [font]: The font to preload.
  Future<void> preload(LayrzFont font);

  /// Returns the concrete font family name to put in a [TextStyle.fontFamily].
  ///
  /// Implementations resolve a requested font into a font family string that
  /// the engine recognizes. If the requested family cannot be resolved,
  /// implementations fall back to [fallbacks].
  ///
  /// Parameters:
  ///   - [font]: The font to resolve.
  ///
  /// Returns:
  ///   A font family name that can be used in [TextStyle.fontFamily].
  String resolveFamily(LayrzFont font);

  /// Returns the concrete font family name for a specific font weight.
  ///
  /// Resolves a requested font into a font family string that the engine
  /// recognizes, taking into account the requested weight. Handlers whose
  /// source registers one family per weight variant (e.g., google_fonts)
  /// should override this to return weight-specific families.
  ///
  /// The default implementation ignores the weight and delegates to
  /// [resolveFamily], preserving compatibility with handlers that do not
  /// distinguish families by weight. If the requested family cannot be
  /// resolved, implementations fall back to [fallbacks].
  ///
  /// Parameters:
  ///   - [font]: The font to resolve.
  ///   - [weight]: The desired font weight.
  ///
  /// Returns:
  ///   A font family name that can be used in [TextStyle.fontFamily].
  String resolveFamilyForWeight(LayrzFont font, FontWeight weight) => resolveFamily(font);

  /// Font families tried in order when [resolveFamily] cannot be honoured.
  ///
  /// Fallback families are used when the primary font cannot be resolved.
  List<String> get fallbacks;
}
