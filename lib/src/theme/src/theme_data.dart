import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/fonts/fonts.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

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

  /// The highlight color painted behind selected text app-wide.
  ///
  /// Drives the app-wide `DefaultSelectionStyle.selectionColor` installed by
  /// [LayrzApp], which both `EditableText` (text fields) and `SelectableRegion`
  /// (selectable, non-editable text) resolve their selection highlight from.
  /// Without an ancestor `DefaultSelectionStyle`, both resolve to `null` and
  /// paint fully transparent, making text selection present but invisible.
  ///
  /// This field is first-class themeable — a future dark theme can override it
  /// with different values without touching [LayrzApp] itself.
  ///
  /// Intentionally semi-transparent (see [LayrzThemeData.light]'s default,
  /// `tokens.colors.selectionColor` tinted by
  /// `tokens.colors.tonalOpacity`) so the selected text stays legible
  /// underneath the highlight rather than being fully obscured by an opaque
  /// fill.
  final Color selectionColor;

  /// The caret (text cursor) color used app-wide.
  ///
  /// Drives the app-wide `DefaultSelectionStyle.cursorColor` installed by
  /// [LayrzApp], which `EditableText` resolves its blinking caret color from.
  ///
  /// This field is first-class themeable — a future dark theme can override it
  /// with different values without touching [LayrzApp] itself.
  final Color cursorColor;

  /// Map of theme extensions, keyed by their runtime type.
  ///
  /// Extensions are registered when constructing a [LayrzThemeData] and retrieved
  /// via [extension<T>()] or [maybeExtension<T>()]. This allows components to store
  /// theme-scoped data without polluting the core theme fields.
  ///
  /// This map is always unmodifiable — callers cannot add or remove extensions
  /// from a live theme.
  final Map<Object, LayrzThemeExtension<dynamic>> extensions;

  /// Whether this theme data represents a light or dark appearance.
  ///
  /// Defaults to [Brightness.light]. [LayrzThemeData.light] sets this to
  /// [Brightness.light] and [LayrzThemeData.dark] sets it to [Brightness.dark].
  /// Read via [BuildContext.isDark] to make brightness-dependent decisions.
  final Brightness brightness;

  /// Creates a new [LayrzThemeData] with all token, icon theme, and extension values explicitly set.
  ///
  /// The [extensions] map is stored as-is; pass an empty map for no extensions.
  /// For convenience, use [LayrzThemeData.light()] with the [Iterable] overload instead.
  ///
  /// [selectionColor] and [cursorColor] have no [tokens]-derived default at this
  /// level — since this constructor is `const`, it cannot compute one from
  /// [tokens] — so callers using this constructor directly must supply both
  /// explicitly. [LayrzThemeData.light()] computes sensible defaults from its
  /// own [tokens] and should be preferred unless full manual control is needed.
  ///
  /// [brightness] defaults to [Brightness.light].
  const LayrzThemeData({
    required this.tokens,
    required this.iconTheme,
    required this.selectionColor,
    required this.cursorColor,
    this.extensions = const {},
    this.brightness = Brightness.light,
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
  /// Backwards-compatible shorthand for [tokens.colors.primary].
  Color get primaryColor => tokens.colors.primary;

  /// Canvas / scaffold background color.
  ///
  /// Backwards-compatible shorthand for [tokens.colors.sf1].
  Color get backgroundColor => tokens.colors.sf1;

  /// Surface color used for cards, dialogs, and elevated containers.
  ///
  /// Backwards-compatible shorthand for [tokens.colors.sf1].
  Color get surfaceColor => tokens.colors.sf1;

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
  /// New code should use [tokens.colors.danger].
  Color get dangerColor => tokens.colors.danger;

  /// Success semantic color.
  ///
  /// Backwards-compatible shorthand for [tokens.colors.success].
  Color get successColor => tokens.colors.success;

  /// Warning semantic color.
  ///
  /// Backwards-compatible shorthand for [tokens.colors.warning].
  Color get warningColor => tokens.colors.warning;

  /// Full text-style scale for this theme.
  ///
  /// Backwards-compatible shorthand for [tokens.typography].
  LayrzTextTheme get textTheme => tokens.typography;

  /// Convenience accessor — base body style used as [DefaultTextStyle] at the root.
  ///
  /// Returns [textTheme.body], i.e. [tokens.typography.body].
  TextStyle get textStyle => tokens.typography.body;

  /// Border radius used consistently for rounded corners across all widgets.
  ///
  /// Returns [tokens.radius.r2] (default 8.0 pixels).
  /// Note: This is a behaviour change from layrz_theme, which defaulted to 10.0.
  /// The layrz_ui design system aligns on 8.0 as the base.
  double get borderRadius => tokens.radius.r2;

  /// Light theme using Layrz brand defaults.
  ///
  /// Builds a complete [LayrzTokens] set via [LayrzTokens.light], then wraps it
  /// in a [LayrzThemeData] with an [IconThemeData] seeded from the text color.
  ///
  /// [primaryColor] overrides the default [kLightPrimaryColor].
  /// [font] is the font to use for all text styles. If null, defaults to [LayrzRobotoFont].
  /// [extensions] is an iterable of [LayrzThemeExtension] instances that define
  ///   component-specific theme data. They are normalized to a map keyed by runtime type
  ///   and stored unmodifiable in the resulting theme. Defaults to an empty list.
  /// [selectionColor] overrides the app-wide text-selection highlight color (see
  ///   [LayrzThemeData.selectionColor]). Defaults to `tokens.colors.selectionColor`
  ///   tinted by `tokens.colors.tonalOpacity` — a semi-transparent light blue that keeps
  ///   selected text legible underneath the highlight.
  /// [cursorColor] overrides the app-wide caret color (see [LayrzThemeData.cursorColor]).
  ///   Defaults to `tokens.colors.primary`.
  factory LayrzThemeData.light({
    Color primaryColor = kLightPrimaryColor,
    LayrzFont? font,
    LayrzBreakpointTokens? breakpointTokens,
    Iterable<LayrzThemeExtension<dynamic>> extensions = const [],
    Color? selectionColor,
    Color? cursorColor,
  }) {
    var tokens = LayrzTokens.light(
      primaryColor: primaryColor,
      font: font,
    );

    // Override breakpoints if custom tokens provided
    if (breakpointTokens != null) {
      tokens = tokens.copyWith(breakpoints: breakpointTokens);
    }

    final iconTheme = IconThemeData(color: tokens.colors.fg1, size: 24);
    final extensionsMap = Map<Object, LayrzThemeExtension<dynamic>>.unmodifiable(
      {for (final ext in extensions) ext.type: ext},
    );
    return LayrzThemeData(
      tokens: tokens,
      iconTheme: iconTheme,
      selectionColor:
          selectionColor ?? tokens.colors.selectionColor.withValues(alpha: tokens.colors.tonalOpacity),
      cursorColor: cursorColor ?? tokens.colors.primary,
      extensions: extensionsMap,
      brightness: Brightness.light,
    );
  }

  /// BETA dark theme using Layrz brand defaults.
  ///
  /// Mirrors [LayrzThemeData.light] exactly, but builds its [LayrzTokens] via
  /// [LayrzTokens.dark] and sets [brightness] to [Brightness.dark].
  ///
  /// [primaryColor] overrides the default [kDarkPrimaryColor].
  /// [font] is the font to use for all text styles. If null, defaults to [LayrzRobotoFont].
  /// [breakpointTokens] overrides the default [LayrzBreakpointTokens] when provided.
  /// [extensions] is an iterable of [LayrzThemeExtension] instances that define
  ///   component-specific theme data. They are normalized to a map keyed by runtime type
  ///   and stored unmodifiable in the resulting theme. Defaults to an empty list.
  /// [selectionColor] overrides the app-wide text-selection highlight color (see
  ///   [LayrzThemeData.selectionColor]). Defaults to `tokens.colors.selectionColor`
  ///   tinted by `tokens.colors.tonalOpacity`.
  /// [cursorColor] overrides the app-wide caret color (see [LayrzThemeData.cursorColor]).
  ///   Defaults to `tokens.colors.primary`.
  factory LayrzThemeData.dark({
    Color primaryColor = kDarkPrimaryColor,
    LayrzFont? font,
    LayrzBreakpointTokens? breakpointTokens,
    Iterable<LayrzThemeExtension<dynamic>> extensions = const [],
    Color? selectionColor,
    Color? cursorColor,
  }) {
    var tokens = LayrzTokens.dark(
      primaryColor: primaryColor,
      font: font,
    );

    // Override breakpoints if custom tokens provided
    if (breakpointTokens != null) {
      tokens = tokens.copyWith(breakpoints: breakpointTokens);
    }

    final iconTheme = IconThemeData(color: tokens.colors.fg1, size: 24);
    final extensionsMap = Map<Object, LayrzThemeExtension<dynamic>>.unmodifiable(
      {for (final ext in extensions) ext.type: ext},
    );
    return LayrzThemeData(
      tokens: tokens,
      iconTheme: iconTheme,
      selectionColor:
          selectionColor ?? tokens.colors.selectionColor.withValues(alpha: tokens.colors.tonalOpacity),
      cursorColor: cursorColor ?? tokens.colors.primary,
      extensions: extensionsMap,
      brightness: Brightness.dark,
    );
  }

  /// Returns a copy of this theme data with the given fields replaced.
  ///
  /// Replaces [tokens], [iconTheme], [selectionColor], [cursorColor], and
  /// [extensions]. If [extensions] is not provided (or is null), the existing
  /// extensions are preserved. Otherwise, the provided extensions replace them
  /// entirely (not a merge).
  ///
  /// The delegating getters (e.g. [primaryColor], [textColor]) automatically
  /// resolve from the new [tokens]. [selectionColor] and [cursorColor], however,
  /// are NOT re-derived from a replaced [tokens] — they carry over unchanged
  /// unless explicitly overridden here, since they are first-class fields
  /// rather than tokens-delegating getters.
  ///
  /// Note: Passing an empty iterable will clear all extensions; pass nothing
  /// to preserve them.
  ///
  /// [brightness] replaces the brightness flag when provided; otherwise it
  /// carries over unchanged.
  LayrzThemeData copyWith({
    LayrzTokens? tokens,
    IconThemeData? iconTheme,
    Color? selectionColor,
    Color? cursorColor,
    Iterable<LayrzThemeExtension<dynamic>>? extensions,
    Brightness? brightness,
  }) {
    final newExtensions = extensions != null
        ? Map<Object, LayrzThemeExtension<dynamic>>.unmodifiable(
            {for (final ext in extensions) ext.type: ext},
          )
        : this.extensions;

    return LayrzThemeData(
      tokens: tokens ?? this.tokens,
      iconTheme: iconTheme ?? this.iconTheme,
      selectionColor: selectionColor ?? this.selectionColor,
      cursorColor: cursorColor ?? this.cursorColor,
      extensions: newExtensions,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzThemeData &&
          runtimeType == other.runtimeType &&
          tokens == other.tokens &&
          iconTheme == other.iconTheme &&
          selectionColor == other.selectionColor &&
          cursorColor == other.cursorColor &&
          brightness == other.brightness &&
          mapEquals(extensions, other.extensions);

  @override
  int get hashCode => Object.hash(
    runtimeType,
    tokens,
    iconTheme,
    selectionColor,
    cursorColor,
    brightness,
    Object.hashAllUnordered(extensions.values),
  );
}
