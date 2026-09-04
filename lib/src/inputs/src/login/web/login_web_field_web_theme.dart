part of 'login_web_field_web.dart';

/// Theme-color resolution and the restyle path for [_LayrzLoginWebFieldState].
///
/// Split out of `login_web_field_web.dart` as a `part` (not a standalone library)
/// because every method here reads or writes private instance state shared with the
/// rest of the state class (`_containerElement`, `_placeholderElement`,
/// `_prefixIconPathElement`, `_suffixIconPathElement`, `_selectionStyleElement`) — a
/// `part` file shares its enclosing library's privacy scope, so this state stays
/// private without having to be exposed for a normal cross-file import.
///
/// **This file is the U6 visual-fidelity contract.** Unlike `layrz_session`'s
/// `native_autofill_field_web_theme.dart` (which hardcodes `ThemedInputBorder`'s CSS hex
/// values as source-derived comments), every color and dimension here is read LIVE from
/// [widget.tokens] — the same [LayrzTokens] that [LayrzInputChrome] itself consumes via
/// [LayrzInputStyleSpec.resolve] — so a token change (a new primary color, a new danger
/// shade) is picked up by this DOM chrome exactly the same way it is picked up by every
/// other layrz_ui input, with no separate CSS constant to keep in sync by hand.
extension _LayrzLoginWebFieldThemeMixin on _LayrzLoginWebFieldState {
  /// Resolves the CSS `font-family` value shared by `label` and `input`.
  ///
  /// Reads [LayrzTokens.typography]'s `body` style — the same text style
  /// [LayrzInputChrome] applies to its own editable content
  /// (`_InputComfortableSpec.textStyle`/`.editableTextStyle`, both `tokens.typography.body`)
  /// — rather than `layrz_session`'s `google_font_family.dart` helper (a
  /// `layrz_session`-specific normalizer/Google-Fonts-CSS-link injector this package has
  /// no equivalent of and does not need: [LayrzFont] implementations are themselves
  /// responsible for making their bytes available via [LayrzFont.load], so by the time
  /// this platform view is built the family is already a usable CSS value on the page).
  ///
  /// Lists, in order: the resolved [TextStyle.fontFamily] (if any), every entry in
  /// [TextStyle.fontFamilyFallback] (if any), then the CSS generic keyword `sans-serif`
  /// as a final fallback. Falls back to the bare keyword `sans-serif` alone when the
  /// theme's body style carries no family at all (kept possible defensively — every
  /// concrete [LayrzFont] in this package always sets one).
  String _resolveCssFontFamily() {
    final bodyStyle = widget.tokens.typography.body;
    final families = <String>[
      if (bodyStyle.fontFamily != null && bodyStyle.fontFamily!.isNotEmpty) bodyStyle.fontFamily!,
      ...(bodyStyle.fontFamilyFallback ?? const <String>[]),
    ];
    if (families.isEmpty) return 'sans-serif';
    return [...families.map((f) => "'$f'"), 'sans-serif'].join(', ');
  }

  /// Derives every theme-dependent color this DOM chrome paints from the CURRENT
  /// [_LayrzLoginWebFieldState.states]/[_LayrzLoginWebFieldState.hasErrors]/
  /// [LayrzLoginWebField.tokens], so both the initial build (in `_registerViewFactory`)
  /// and a later restyle ([_applyThemeStyles]) compute colors the same, single way.
  ///
  /// Delegates the fill/border/text triad to [LayrzInputStyleSpec.resolve] — the EXACT
  /// same resolver [LayrzInputChrome] calls — so this DOM field's default/hover/focus/
  /// error/disabled states match the Flutter chrome's resolution precedence
  /// (`disabled > readOnly > error > pressed > hover/focused > default`) rather than a
  /// second, hand-maintained state machine that could drift from it.
  ///
  /// Colors not modeled by [LayrzInputStyleSpec] (the icon/placeholder tints) are read
  /// directly from [LayrzTokens.colors]: `fg2` (or `danger` while in the error state)
  /// for the in-box placeholder — note this placeholder is a DIFFERENT element from the
  /// static label row `login_web_field_web.dart`'s `build()` renders above the box
  /// (which always stays `fg2`, matching [LayrzInputChrome]'s own label `TextSpan`
  /// exactly); `fg3` for icons (matching the chrome's hint-text/lock-icon secondary
  /// tone); and `colors.primary` for the caret/selection accent (matching the focus
  /// border color the spec resolves to).
  _LoginFieldColors _resolveThemeColors() {
    final tokens = widget.tokens;
    final hasErrors = this.hasErrors;
    final spec = LayrzInputStyleSpec.resolve(
      states: states,
      tokens: tokens,
      hasErrors: hasErrors,
      readOnly: false,
    );

    return _LoginFieldColors(
      fillColor: _toCssColor(spec.backgroundColor),
      iconColor: hasErrors ? _toCssColor(tokens.colors.danger) : _toCssColor(tokens.colors.fg3),
      labelColor: hasErrors ? _toCssColor(tokens.colors.danger) : _toCssColor(tokens.colors.fg2),
      textColor: _toCssColor(spec.textColor),
      borderColor: _toCssColor(spec.borderColor),
      borderWidthPx: spec.borderWidth,
      accentHex: _toCssColor(tokens.colors.primary),
    );
  }

  /// Converts a Flutter [Color] to a CSS `#rrggbb` or `#rrggbbaa` hex string.
  ///
  /// Uses the 8-digit form (with an explicit alpha channel) whenever [color] is not
  /// fully opaque, so a transparent border color (the chrome's own `Color(0x00000000)`
  /// default border, per [LayrzInputStyleSpec.resolve]) renders as genuinely invisible
  /// CSS rather than opaque black — `toARGB32()` alone discards which byte is alpha, so
  /// the alpha channel must be threaded through explicitly.
  String _toCssColor(Color color) {
    final argb = color.toARGB32();
    final a = (argb >> 24) & 0xFF;
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    final rgb =
        '#'
        '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
    if (a == 0xFF) return rgb;
    return '$rgb${a.toRadixString(16).padLeft(2, '0')}';
  }

  /// Re-applies every theme-dependent DOM property using the CURRENT
  /// [LayrzLoginWebField.tokens]/[_LayrzLoginWebFieldState.states]/
  /// [_LayrzLoginWebFieldState.hasErrors]/[LayrzLoginWebField.disabled]/
  /// [LayrzLoginWebField.labelText], against the elements stored during
  /// `_registerViewFactory`'s initial build.
  ///
  /// Called once from the view factory (so construction and later restyles share this
  /// exact same logic) and again from [didUpdateWidget] whenever a theme-relevant field
  /// actually changed, so the native DOM — which is otherwise never rebuilt by Flutter
  /// once created — stays in sync with the app's live tokens/interaction-state/label
  /// instead of freezing at whatever it was when the platform view was first created.
  ///
  /// Does nothing (safely) before the platform view exists yet — every stored element
  /// reference is nullable and this bails out via `?.`/early return whenever
  /// `_containerElement` is still null.
  void _applyThemeStyles() {
    final container = _containerElement;
    if (container == null) return;

    final colors = _resolveThemeColors();

    container.style.background = colors.fillColor;
    container.style.border = colors.borderWidthPx > 0
        ? '${colors.borderWidthPx}px solid ${colors.borderColor}'
        : 'none';

    _placeholderElement?.style.color = colors.labelColor;
    _placeholderElement?.textContent = widget.labelText ?? '';

    _prefixIconPathElement?.setAttribute('fill', colors.iconColor);
    _suffixIconPathElement?.setAttribute('fill', colors.iconColor);
    _errorIconPathElement?.setAttribute('fill', colors.iconColor);
    // The error icon's very presence (not just its tint) tracks the CURRENT
    // [_LayrzLoginWebFieldState.hasErrors] — see [_errorIconSlotElement]'s doc comment
    // for why this can change after the platform view already exists.
    _errorIconSlotElement?.style.display = hasErrors ? 'flex' : 'none';

    final input = _inputElement;
    if (input != null) {
      input.style.color = colors.textColor;
      input.style.setProperty('-webkit-text-fill-color', colors.textColor);
    }

    // 33% alpha (hex `55`) tint of the accent color — mirrors the chrome's own focus
    // ring accent (`tokens.colors.primary`, via [LayrzInputStyleSpec.resolve]'s focused
    // branch) used here as the text-selection highlight instead, since a DOM `<input>`
    // has no separate "focus ring" concept distinct from its own border (already
    // recolored above by [_resolveThemeColors]'s border branch).
    final selectionBackground = '${colors.accentHex}55';
    _selectionStyleElement?.textContent =
        '.$_selectionClass::selection { background: $selectionBackground; color: ${colors.textColor}; }';
  }

  /// Unique class name used to scope this instance's `::selection` rule — derived from
  /// [_viewType] so it's stable across `_registerViewFactory` (which assigns it to
  /// `input.className`) and [_applyThemeStyles] (which must target the exact same
  /// selector when rewriting the rule).
  String get _selectionClass => '$_viewType-input';
}

/// Resolved CSS color/dimension values for one paint of [_LayrzLoginWebFieldState]'s
/// DOM chrome, computed once by [_LayrzLoginWebFieldThemeMixin._resolveThemeColors] and
/// shared by every property assignment that needs a themed value.
///
/// Kept as a small record-like class (rather than a bare Dart record) so each field
/// carries its own doc comment — record positional/named fields cannot be documented
/// individually.
class _LoginFieldColors {
  /// The DOM chrome's background fill, from [LayrzInputStyleSpec.backgroundColor].
  final String fillColor;

  /// The prefix/suffix icon tint — `danger` when [_LayrzLoginWebFieldState.widget]
  /// carries validation errors, otherwise `fg3`.
  final String iconColor;

  /// The in-box placeholder's text color — `danger` when in the error state, otherwise
  /// `fg2`. Distinct from the static label row above the box (always `fg2`, rendered
  /// in Flutter by `login_web_field_web.dart`'s `build()`, matching
  /// [LayrzInputChrome]'s own label `TextSpan` color).
  final String labelColor;

  /// The typed-value text color, from [LayrzInputStyleSpec.textColor].
  final String textColor;

  /// The chrome border color, from [LayrzInputStyleSpec.borderColor].
  final String borderColor;

  /// The chrome border width in logical pixels, from [LayrzInputStyleSpec.borderWidth].
  final double borderWidthPx;

  /// The accent color (`tokens.colors.primary`) used for the text-selection tint.
  final String accentHex;

  /// Creates a [_LoginFieldColors] snapshot.
  const _LoginFieldColors({
    required this.fillColor,
    required this.iconColor,
    required this.labelColor,
    required this.textColor,
    required this.borderColor,
    required this.borderWidthPx,
    required this.accentHex,
  });
}
