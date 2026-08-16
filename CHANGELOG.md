## 0.0.2

### Breaking
- `lib/layrz_ui.dart` is removed; import specific domain entrypoints instead — e.g. `import 'package:layrz_ui/buttons.dart';` or `import 'package:layrz_ui/theme.dart';` in place of a single `import 'package:layrz_ui/layrz_ui.dart';`.
- Semantic colour tokens are now `LayrzColorSwatch` rather than `Color`; the base values moved from the 600 to the 500 palette shade, so semantic colours are visibly brighter.
- `contrastColor` now uses Material's brightness threshold instead of the stricter WCAG crossover; labels on `success`, `danger` and `info` backgrounds change from black to white.

### Added
- `LayrzButton` — the first component with twelve styles (`filled`, `elevated`, `filledTonal`, `outlined`, `outlinedTonal`, `text`, each with a Fab counterpart), built only on `package:flutter/widgets.dart`.
- Six semantic factories on `LayrzButton`: `.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`, each with an `isElevated` flag.
- `LayrzButtonType` — `success`, `info`, `context`, `danger`, `warning`, `custom`; a `color` override applies only to `custom`.
- `LayrzButtonController` — one controller drives many buttons so a whole view shares one busy state, with a cooldown duration that auto-clears on expiry and an anti-flash floor preventing very short busy states from strobing.
- `LayrzColorSwatch` — a Material-free equivalent of `MaterialColor` giving every semantic colour a full tonal range from `shade50` through `shade900`.
- A compact shadow ramp, `compact1`–`compact5`, for small components alongside the existing surface `elevation` ramp.
- `Color.opposite` as a shorthand alias for `contrastColor`.
- `LayrzRadiusTokens.innerRadiusValue` for computing concentric inner radii.

### Changed
- The package adopts the Flutter SDK layout: entrypoints at the top of `lib/`, implementation under `lib/src/`.
- `elevation1` now has a real vertical offset; it previously computed to zero and was invisible.

## 0.0.1

### Added
- `LayrzApp` and `LayrzApp.router` — drop-in `WidgetsApp` replacements with zero Material or Cupertino dependency.
- A complete immutable design-token system: `LayrzTokens` aggregating `LayrzColorTokens`, `LayrzTextTheme`, `LayrzSpacingTokens`, `LayrzRadiusTokens`, `LayrzShadowTokens`, `LayrzBorderTokens` and `LayrzMotionTokens`.
- `LayrzTokenizer` — a thin façade over the tokens, kept in sync with direct `theme.tokens` access.
- `LayrzThemeExtension<T>` — a Material-free equivalent of `ThemeExtension<T>`, so components can attach theme-scoped data; retrieved with `extension<T>()` / `maybeExtension<T>()` or `context.themeExtension<T>()`.
- `LayrzPreviewTheme` for Flutter 3.47 widget previews, exposed via `package:layrz_ui/preview.dart`.
- `LayrzFontHandler` with a `LayrzGoogleFontsHandler` implementation (google_fonts `TextStyle` APIs only, never `*TextTheme()`).
- The `WidgetState` / `WidgetStateProperty` / `WidgetStatesController` family re-exported from `package:flutter/widgets.dart`.
- `LayrzPlatform` for platform detection, `LayrzColorExtensions`, `LayrzContextExtensions`, and the responsive grid + duration + colour constants.
- A CI pipeline enforcing analyze, tests, formatting, the Material/Cupertino invariant, a google_fonts guard, a test-mirror structure check and a coverage ratchet.
- `public_member_api_docs` enforcement, so every public member ships documented.

### Fixed
- `LayrzTheme` extends `InheritedTheme` and implements `wrap()`, so the theme survives Overlay and route boundaries — dialogs, tooltips, menus and dropdowns can resolve `LayrzTheme.of(context)`.

### Changed
- Light mode only. `LayrzThemeData.dark()`, `LayrzThemeMode`, `context.isDark` and the dark token variants were removed; `errorColor` is now `dangerColor`. The accent colour was removed entirely.
- The theme now loads its font automatically rather than relying on the host app.
- Base border radius is 8.0 (layrz_theme used 10.0).

### Documentation
- `engineering/` holds the architecture, decision log, token spec and milestone plans; per-component usage documentation lives in the GitHub wiki.
