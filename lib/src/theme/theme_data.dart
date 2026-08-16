import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/constants.dart';
import 'package:layrz_ui/fonts.dart';
import 'package:layrz_ui/tokens.dart';

import 'theme_extension.dart';

/// Immutable design data for the layrz_ui design system.
///
/// Holds a complete [LayrzTokens] set (all colors, typography, spacing, radius, shadow, border,
/// and motion tokens), an [IconThemeData] for icon styling, and optional theme extensions
/// for storing component-specific design data.
///
/// Consumed by [LayrzTheme.of] in every layrz_ui widget.
///
/// For backwards compatibility, deprecated color fields (e.g. [primaryColor], [textColor])
/// are provided as getters that delegate to [tokens]. This keeps existing call sites working
/// while centralizing all design values in [tokens].
@immutable
class LayrzThemeData {
  /// The complete immutable design-token set backing this theme.
  final LayrzTokens tokens;

  /// Base icon theme applied via [IconTheme] at the root.
  final IconThemeData iconTheme;

  /// Map of theme extensions, keyed by their runtime type.
  ///
  /// Extensions are registered when constructing a [LayrzThemeData] and retrieved
  /// via [extension<T>()] or [maybeExtension<T>()]. This allows components to store
  /// theme-scoped data without polluting the core theme fields.
  ///
  /// This map is always unmodifiable — callers cannot add or remove extensions
  /// from a live theme.
  final Map<Object, LayrzThemeExtension<dynamic>> extensions;

  /// Creates a new [LayrzThemeData] with all token, icon theme, and extension values explicitly set.
  ///
  /// The [extensions] map is stored as-is; pass an empty map for no extensions.
  /// For convenience, use [LayrzThemeData.light()] with the [Iterable] overload instead.
  const LayrzThemeData({
    required this.tokens,
    required this.iconTheme,
    this.extensions = const {},
  });

  // ===== EXTENSION ACCESSORS =====

  /// Retrieves a registered theme extension, throwing if it is not found.
  ///
  /// Use this when the extension is guaranteed to be registered (e.g., as part
  /// of the theme construction contract). For optional access, use [maybeExtension].
  ///
  /// Throws an assertion error if the extension is not registered. The error
  /// message suggests registering the extension when creating the theme.
  ///
  /// Type parameter [T] must be a concrete subclass of [LayrzThemeExtension<T>].
  ///
  /// Example:
  /// ```dart
  /// final buttonExtension = theme.extension<ButtonVariantsExtension>();
  /// ```
  T extension<T extends LayrzThemeExtension<T>>() {
    assert(
      extensions.containsKey(T),
      'No extension of type $T registered in LayrzThemeData. '
      'Register it when creating the theme: '
      'LayrzThemeData.light(extensions: [YourExtension(...)])',
    );
    return extensions[T]! as T;
  }

  /// Retrieves a registered theme extension, returning null if it is not found.
  ///
  /// Use this for optional access when an extension might not be registered.
  /// For required access, use [extension] instead — it provides a clearer assertion.
  ///
  /// Type parameter [T] must be a concrete subclass of [LayrzThemeExtension<T>].
  ///
  /// Example:
  /// ```dart
  /// final buttonExtension = theme.maybeExtension<ButtonVariantsExtension>();
  /// if (buttonExtension != null) {
  ///   // Use the extension
  /// }
  /// ```
  T? maybeExtension<T extends LayrzThemeExtension<T>>() {
    return extensions[T] as T?;
  }

  // ===== DELEGATING GETTERS — BACKWARDS COMPATIBILITY =====
  //
  // These getters delegate to [tokens] to provide a backwards-compatible API.
  // New code should access [tokens] directly; these exist to avoid breaking
  // existing call sites.

  /// Primary brand color (deep navy blue by default).
  ///
  /// Backwards-compatible shorthand for [tokens.colors.primary.shade500].
  Color get primaryColor => tokens.colors.primary.shade500;

  /// Canvas / scaffold background color.
  ///
  /// Backwards-compatible shorthand for [tokens.colors.background].
  Color get backgroundColor => tokens.colors.background;

  /// Surface color used for cards, dialogs, and elevated containers.
  ///
  /// Backwards-compatible shorthand for [tokens.colors.surface].
  Color get surfaceColor => tokens.colors.surface;

  /// Default text color drawn on [backgroundColor].
  ///
  /// Backwards-compatible shorthand for [tokens.colors.fg1].
  Color get textColor => tokens.colors.fg1;

  /// Muted / hint text color for placeholders and supporting text.
  ///
  /// Backwards-compatible shorthand for [tokens.colors.fg3].
  Color get hintColor => tokens.colors.fg3;

  /// Border and divider color.
  ///
  /// Backwards-compatible shorthand for [tokens.colors.divider].
  Color get borderColor => tokens.colors.divider;

  /// Error / danger semantic color.
  ///
  /// Renamed from [errorColor] to [dangerColor] in alignment with the token system.
  /// This getter provides backwards compatibility under the old name.
  /// New code should use [tokens.colors.danger.shade500].
  Color get dangerColor => tokens.colors.danger.shade500;

  /// Success semantic color.
  ///
  /// Backwards-compatible shorthand for [tokens.colors.success.shade500].
  Color get successColor => tokens.colors.success.shade500;

  /// Warning semantic color.
  ///
  /// Backwards-compatible shorthand for [tokens.colors.warning.shade500].
  Color get warningColor => tokens.colors.warning.shade500;

  /// Full text-style scale for this theme.
  ///
  /// Backwards-compatible shorthand for [tokens.typography].
  LayrzTextTheme get textTheme => tokens.typography;

  /// Convenience accessor — base body style used as [DefaultTextStyle] at the root.
  ///
  /// Returns [textTheme.bodyMedium], i.e. [tokens.typography.bodyMedium].
  TextStyle get textStyle => tokens.typography.bodyMedium;

  /// Border radius used consistently for rounded corners across all widgets.
  ///
  /// Returns [tokens.radius.base] (default 8.0 pixels).
  /// Note: This is a behaviour change from layrz_theme, which defaulted to 10.0.
  /// The layrz_ui design system aligns on 8.0 as the base.
  double get borderRadius => tokens.radius.base;

  /// Light theme using Layrz brand defaults.
  ///
  /// Builds a complete [LayrzTokens] set via [LayrzTokens.light], then wraps it
  /// in a [LayrzThemeData] with an [IconThemeData] seeded from the text color.
  ///
  /// [primaryColor] overrides the default [kPrimaryColor].
  /// [fontName] is the convenience parameter for loading a Google Font by name (default: 'Open Sans').
  ///   If provided, it is wrapped into a [LayrzFont] with [LayrzFontSource.google].
  /// [titleFont] and [bodyFont] are advanced overrides that take precedence over [fontName].
  ///   Use these for local or URI-based fonts, or to specify different fonts for titles vs. body.
  /// [fontHandler] resolves font family names and preloads font bytes. Defaults to
  ///   [LayrzGoogleFontsHandler], ensuring fonts are loaded via Google Fonts by default.
  ///   Pass a custom handler to load from alternative sources.
  /// [extensions] is an iterable of [LayrzThemeExtension] instances that define
  ///   component-specific theme data. They are normalized to a map keyed by runtime type
  ///   and stored unmodifiable in the resulting theme. Defaults to an empty list.
  factory LayrzThemeData.light({
    Color primaryColor = kPrimaryColor,
    String fontName = kLayrzFontName,
    LayrzFont? titleFont,
    LayrzFont? bodyFont,
    LayrzFontHandler fontHandler = const LayrzGoogleFontsHandler(),
    LayrzBreakpointTokens? breakpointTokens,
    Iterable<LayrzThemeExtension<dynamic>> extensions = const [],
  }) {
    // Use provided fonts, or wrap fontName into LayrzFont for Google Fonts
    final resolvedTitleFont =
        titleFont ??
        LayrzFont(
          source: LayrzFontSource.google,
          name: fontName,
        );
    final resolvedBodyFont =
        bodyFont ??
        LayrzFont(
          source: LayrzFontSource.google,
          name: fontName,
        );

    var tokens = LayrzTokens.light(
      primaryColor: primaryColor,
      titleFont: resolvedTitleFont,
      bodyFont: resolvedBodyFont,
      fontHandler: fontHandler,
    );

    // Override breakpoints if custom tokens provided
    if (breakpointTokens != null) {
      tokens = tokens.copyWith(breakpoints: breakpointTokens);
    }

    final iconTheme = IconThemeData(color: tokens.colors.fg1, size: 24);
    final extensionsMap = Map<Object, LayrzThemeExtension<dynamic>>.unmodifiable(
      {for (final ext in extensions) ext.type: ext},
    );
    return LayrzThemeData(tokens: tokens, iconTheme: iconTheme, extensions: extensionsMap);
  }

  /// Preloads a font to avoid first-frame rendering in a fallback family.
  ///
  /// This is optional — fonts load either way when the theme is constructed.
  /// Call this in your app's `main()` before `runApp()` to ensure the font is
  /// fully loaded before the first frame is painted, avoiding visual flashing.
  ///
  /// Parameters:
  ///   - [fontName]: The font name to preload (default: 'Open Sans').
  ///   - [handler]: The font handler to use for preloading. Defaults to
  ///     [LayrzGoogleFontsHandler], which handles Google Fonts.
  ///
  /// Example:
  /// ```dart
  /// Future<void> main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   try {
  ///     await LayrzThemeData.preloadFont('Open Sans');
  ///   } catch (e) {
  ///     debugPrint('Font preload failed: $e');
  ///   }
  ///   runApp(const MyApp());
  /// }
  /// ```
  static Future<void> preloadFont([String fontName = kLayrzFontName, LayrzFontHandler? fontHandler]) async {
    final handler = fontHandler ?? const LayrzGoogleFontsHandler();
    return handler.preload(
      LayrzFont(
        source: LayrzFontSource.google,
        name: fontName,
      ),
    );
  }

  /// Returns a copy of this theme data with the given fields replaced.
  ///
  /// Replaces [tokens], [iconTheme], and [extensions]. If [extensions] is not
  /// provided (or is null), the existing extensions are preserved. Otherwise,
  /// the provided extensions replace them entirely (not a merge).
  ///
  /// The delegating getters (e.g. [primaryColor], [textColor]) automatically
  /// resolve from the new [tokens].
  ///
  /// Note: Passing an empty iterable will clear all extensions; pass nothing
  /// to preserve them.
  LayrzThemeData copyWith({
    LayrzTokens? tokens,
    IconThemeData? iconTheme,
    Iterable<LayrzThemeExtension<dynamic>>? extensions,
  }) {
    final newExtensions = extensions != null
        ? Map<Object, LayrzThemeExtension<dynamic>>.unmodifiable(
            {for (final ext in extensions) ext.type: ext},
          )
        : this.extensions;

    return LayrzThemeData(
      tokens: tokens ?? this.tokens,
      iconTheme: iconTheme ?? this.iconTheme,
      extensions: newExtensions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzThemeData &&
          runtimeType == other.runtimeType &&
          tokens == other.tokens &&
          iconTheme == other.iconTheme &&
          mapEquals(extensions, other.extensions);

  @override
  int get hashCode => Object.hash(runtimeType, tokens, iconTheme, Object.hashAllUnordered(extensions.values));
}
