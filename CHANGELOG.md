## 0.0.3

### Breaking
- The text scale collapses from fifteen styles to five: `display`, `headline`, `title`, `body`, `label`. All `*Large`, `*Medium` and `*Small` names are removed with no aliases; each new name carries the former `Medium` values.
- Font weights now carry hierarchy: `display` w800, `headline` w700, `title` w600, `body` w400, `label` w300. Previously all styles painted at regular weight regardless of the tag.
- `layrzTooltipPositionDelegate` is renamed to `positionDelegate`.
- Breakpoints move from compile-time constants (`kExtraSmallGrid`, etc.) onto the theme as `LayrzBreakpointTokens`, permitting per-app override. Add `context.breakpoint` to retrieve the active band from viewport width.
- Grid breakpoints are now viewport-driven; the `useScreenWidth` escape hatch is removed. A row always selects spans from `MediaQuery.sizeOf(context).width`, then divides its own measured pixel width by the selected span count. The two widths routinely differ for grids inside narrow containers on large screens, matching CSS Grid and Bootstrap.
- `kLayrzButtonTooltipVerticalOffset` is removed; button tooltips now use `LayrzTooltip` with `kLayrzTooltipOffset`.

### Added
- `LayrzTooltip` — a Material-free tooltip composed on `Overlay`, with `LayrzTooltipPosition` (top/bottom/left/right) positioning. Content is `contentText` or `contentRichText`; never covers its anchor, flips at viewport edges, and leaves the wrapped widget's layout and hit-testing untouched.
- `LayrzAlert` and `LayrzAlertIcon` — inline status callout with six severities (`info`, `success`, `warning`, `danger`, `context`, `custom`) and five visual styles (`.layrz`, `.filledTonal`, `.filled`, `.outlined`, `.filledIcon`), resolved through `LayrzAlertStyleSpec`.
- `LayrzAlert.onTap` makes alerts interactive: tap, Enter or Space activate the callback; hover and focus trigger a paint-only surface lift and shadow appears at elevation 2, while press settles the surface and shadow steps to elevation 1.
- `LayrzCard` — a styled surface with fixed 16u padding, token radius, and elevation (int 1–5) selecting the shadow ramp. Optionally interactive via `onTap`.
- `LayrzRow`, `LayrzCol` and `LayrzConstrainedView` — a 12-column responsive grid. Columns declare span per breakpoint (1–12) as plain ints, cascading downward when a band is unset. Rows greedily wrap columns and size them by available width. `LayrzConstrainedView` centres and clamps a column to `maxWidth` with internal vertical spacing.
- `Color.flattenOn` and `Color.isOpaque` on `LayrzColorExtensions` — flatten a translucent colour onto a background for pixel-perfect compositing; test colour opacity without inspecting alpha directly.
- `LayrzFontHandler.resolveFamilyForWeight` — resolves a font family for a specific weight. Defaults to `resolveFamily`, preserving compatibility; handlers like `LayrzGoogleFontsHandler` override it to return weight-specific families.

### Changed
- Font weights across the scale: `display` w800, `headline` w700, `title` w600, `body` w400, `label` w300 (was w100). The `title` step moves from w500.
- `LayrzButton` now composes `LayrzTooltip` instead of its own private tooltip implementation.

### Fixed
- Font weights render correctly. Every style previously resolved to a single-face family, so all weights painted at regular. Font families are now resolved per weight via `resolveFamilyForWeight`, and every weight the scale uses is preloaded; web showroom no longer flashes fallback text.
- `LayrzButton`'s pressed state activates correctly under fast mobile taps.
- Icon tree-shaking disabled for web release builds to prevent runtime errors.

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
