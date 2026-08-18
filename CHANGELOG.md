# Changelog

## 0.0.8

**Final M2 core primitives.** Adds three remaining M2 components and amends the dropdown menu implementation.

### Breaking

- **`LayrzDropdownEntry.color` is now `Color?` instead of `LayrzColorSwatch?`** — The swatch type was originally justified because pressed and hovered states read `accent.shade100` and `accent.shade700`. Those states are now neutral opaque tokens, so no shades are read anywhere. Passing token swatches still compiles and renders identically (each swatch is constructed with shade500 as its primary value), so most callers need no change. Only code that *reads* the field back expecting a swatch (e.g., `entry.color.shade700`) will break at compile time. Reference decision D29.

### Added

- **`LayrzDropdownLabel.color`** — Optional `Color?` parameter that fills the label's tonal band. Null keeps the neutral `surface3` fill, so existing menus are visually unchanged. Paired with D29's dropdown entry colour simplification.

- **`LayrzButtonGroup`** — Horizontal row of `LayrzButton` actions that collapses below the `md` breakpoint into a single fab trigger opening a `LayrzDropdownMenu`. Mode driven by a nullable `bool useDropdown` parameter; no enum exposed. Replaces the old `ThemedActionsButtons` from layrz_theme. Renamed from `LayrzGroupedButton` for uniformity with `LayrzChipGroup` (group components follow `Layrz<Thing>Group` naming). Includes 28 tests covering row mode, dropdown mode, responsive switching, semantic type preservation, disabled states, and accessibility. Reference DESIGN-31.

- **`LayrzButtonType.semanticColor`** — New extension getter on `LayrzButtonType` enum allowing button → entry conversion to use one unified type-to-token mapping.

- **`LayrzAvatar`** — Static display component rendering a layrz_sdk `Avatar` by type (photo, initials, icon), with optional initials fallback. Circular or rounded-square shape via `LayrzAvatarShape` enum. No interaction affordances; callers wrap if needed. Initials algorithm is deterministic but not locale-aware (no Unicode segmentation). Reference decision D31.

- **`LayrzImage`** — Image widget resolving network URLs, data-URIs, bare base64, and asset paths. Includes SVG support via flutter_svg and a bounded cache for decoded base64 bytes. Uses `ImageSource` to detect and parse the source type automatically.

- **Dependencies: layrz_sdk and flutter_svg** — New dependencies to support avatar models and SVG rendering. layrz_sdk requires `layrz_icons: ^1.1.1`, so the package constraint is downgraded from `^2.0.0` to `^1.1.1`. All 20 used IconData symbols are identical in both versions, verified byte-for-byte. Reference decision D30.

### Changed

- **`layrz_icons` constraint lowered from `^2.0.0` to `^1.1.1`** — Required by layrz_sdk 4.4.3. All used symbols are identical across versions. Exit condition: raise constraint back to `^2.0.0` once layrz_sdk upgrades.

### Design Notes

- **D29** documents the post-mortem on `LayrzDropdownEntry.color`. The lesson: when an API's original constraint is removed, actively audit the dependency graph for surviving references to that constraint and remove them. The swatch type should not have survived the interaction-state redesign.

- **D30** records the dependency trade-off: layrz_sdk brings 18 transitive dependencies (including `dio`, `layrz_i18n`, `layrz_logging`, `web_socket_channel`), and flutter_svg adds the vector graphics chain. All verified Material-free. Exit condition explicit: revert to `^2.0.0` once layrz_sdk advances.

- **D31** documents that `LayrzAvatar` is static display-only, following the same pattern as `LayrzChip` per decision D28. No interaction affordances, no elevation — callers own interaction logic.

---

## 0.0.7

**First components from Milestone 2.** Adds four M2 primitives: selectable text, visual chips, chip grouping, and dropdown menu.

### Added

- **`LayrzText`** — Material-free drop-in replacement for Flutter's `Text` that makes text selectable and copyable via `SelectableRegion` with `emptyTextSelectionControls`. Supports both `LayrzText(String)` and `LayrzText.rich(InlineSpan)` constructors mirroring `Text` exactly. Keyboard selection (Ctrl+A) and copy (Ctrl+C) work without additional UI. Resolves null `style` to `tokens.typography.body` rather than inherited `DefaultTextStyle`; drag handles and context menu deferred until Material-free `TextSelectionControls` exists. Reference decision D28 and DESIGN-28.

- **`LayrzChip`** — static, visual-only compact label with optional leading icon and optional delete affordance. Three styles (`filled`, `outlined`, `filledTonal`) and six semantic types (`info`, `success`, `warning`, `danger`, `context`, `custom`). Chip is a label, not a control: no tap, hover, focus, or selected state; only the delete affordance is interactive. Reference decision D28 and DESIGN-29.

- **`LayrzChipGroup`** — horizontal layout of multiple chips with two overflow behaviors. `LayrzChipGroupBehavior.none` (default) renders a single scrollable row. `LayrzChipGroupBehavior.compact` clamps to available width and collapses the remainder into a `+N` indicator chip whose tooltip lists the hidden labels. Caveat: `compact` measures each chip individually, so the `+N` may appear one chip early or late; it costs one text layout per chip per build.

- **`LayrzDropdownMenu`** — menu surface anchored to a trigger widget, built on `RawMenuAnchor` from `package:flutter/widgets.dart`. The trigger is supplied via `builder: (context, controller)` and wires itself through the controller; the menu installs no gesture handling of its own. Items are a sealed hierarchy of `LayrzDropdownEntry` and `LayrzDropdownLabel`, ensuring standardization on rendering. Entries support an optional colour dot (driven by a `LayrzColorSwatch`), an optional icon, `enabled` state, and a **display-only** `Set<LogicalKeyboardKey>` shortcut hint rendered with platform-native glyphs and hidden entirely on iOS and Android. `LayrzDropdownMenuAlignment` offers `start`/`center`/`end` horizontal positioning relative to the trigger. Escape, arrow-key traversal, and outside-tap dismissal are handled by `RawMenuAnchor`. No exit animation — `RawMenuAnchor` tears the overlay down synchronously. Reference DESIGN-30 and milestone-2 item 9.

### Changed

- **`LayrzText` is now a `StatelessWidget`** — public API is unchanged. Its former `State` only duplicated `SelectableRegion`'s own focus-node ownership, so the redundant `State`/`Element` per instance was removed. A caller-supplied `focusNode` remains caller-owned and is never disposed by the widget.

### Design Notes

- **D28** documents the architectural decisions for text, chips, and the sealed item hierarchy (which extends to dropdown). See `engineering/decisions.md#d28`.
- `LayrzText` uses `SelectableRegion` with `emptyTextSelectionControls` from Flutter 3.47 to enable keyboard selection and copy (Ctrl+A, Ctrl+C) without Material imports. When `focusNode` is supplied, the caller owns and must manage its lifetime; `LayrzText` never disposes it.
- `LayrzChip` uses `tokens.radius.full` for pill-shaped border radius and is static by design — no tap, hover, focus, or selection state; only the delete affordance is interactive.
- `LayrzChipGroup.compact` mode measures each chip individually via `LayrzChip.computeWidth()` (using `TextPainter`) to determine when to show the `+N` overflow indicator. This costs one text layout per chip per build; avoid in hot lists.
- **`LayrzDropdownMenu` interaction states:** Dropdown entries render at `surface` at rest, `surface2` on hover and focus, and `surface3` when pressed. Interaction states are neutral and fully opaque because `Colors.transparent` is transparent *black* and lerping from it flashes dark mid-transition. See decision DESIGN-30.

---

## 0.0.6

**Breaking: component enum trimming.** Two design votes removed unused style variants.

### Breaking
- **`LayrzButtonStyle` trimmed from 12 to 6 values** — only `elevated`, `elevatedFab`, `outlined`, `outlinedFab`, `outlinedTonal`, `outlinedTonalFab` remain. Removed: `filled`, `filledFab`, `filledTonal`, `filledTonalFab`, `text`, `fab`. See decision D27 and DESIGN-20.
- **`LayrzAlertStyle` trimmed from 5 to 2 values** — only `layrz`, `filledIcon` remain. Removed: `filledTonal`, `filled`, `outlined`. Consequence: all alerts now render in split-panel layout. See decision D27 and DESIGN-22.
- **Semantic factory signature change** — six button factories (`.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`) replace the `isElevated` boolean with an exposed `style:` parameter defaulting to `LayrzButtonStyle.elevated`. The `isFab` parameter remains. `isElevated` is no longer a parameter. Factories map the given style to its Fab twin via a new `asFab` getter on the enum extension. Example: `LayrzButton.save(labelText: 'Save', onTap: _save, style: LayrzButtonStyle.outlined)`.
- **`kLayrzAlertIconBoxSize` and `kLayrzAlertIconSize` removed** — orphaned by the alert style trim. Only `kLayrzAlertFilledIconSize` remains.

### Added
- `LayrzButtonStyle.asFab` enum extension — maps a regular style to its Fab twin (e.g., `outlined.asFab` → `outlinedFab`). Used internally by semantic factories.

### Changed
- `LayrzButton` semantic factories now expose the `style:` parameter for controlling button emphasis via style choice rather than a boolean. Developers explicitly pass `style: LayrzButtonStyle.outlined` for quiet buttons.
- All `LayrzAlert` instances now render in split-panel layout (the old `.layrz` and `.filledIcon` styles were the two split-panel options; the removed styles were single-panel).

### Design Rule (Not Enforced in Code)
- Button labels should be concise; do not rely on `TextOverflow.ellipsis` / `maxLines: 1` to truncate long text. This is design guidance only, not a runtime constraint.

---

## 0.0.5

**Breaking: every import path changes.** A single barrel replaces the fourteen per-domain entrypoints.

```dart
// Before (0.0.4)
import 'package:layrz_ui/buttons.dart';
import 'package:layrz_ui/theme.dart';
import 'package:layrz_ui/tokens.dart';

// After (0.0.5)
import 'package:layrz_ui/layrz_ui.dart';
```

### Breaking
- The fourteen per-domain entrypoints (`alerts.dart`, `app.dart`, `buttons.dart`, `cards.dart`, `constants.dart`, `extensions.dart`, `fonts.dart`, `grid.dart`, `platform.dart`, `state.dart`, `theme.dart`, `tokenizer.dart`, `tokens.dart`, `tooltips.dart`) are removed. Import `package:layrz_ui/layrz_ui.dart` instead; it exports all of them.
- Deferred imports were the one benefit of the per-domain split, and they apply only to web and Android. layrz_ui targets all six Flutter platforms, so the split was not earning its complexity. Recorded as D26; D19 is superseded.

### Changed
- `package:layrz_ui/preview.dart` is unchanged and remains a separate opt-in import. It is deliberately not exported by the root barrel.
- Implementation files move to `lib/src/<module>/src/` behind a per-module barrel at `lib/src/<module>/<module>.dart`. This is internal layout only; consumers import the root barrel.

## 0.0.4

**Documentation-only release.** No API changes, no code changes, no migration required. If you're using 0.0.3, you already have all the features described here.

### Documentation
- README corrected: removed examples for removed APIs (`LayrzThemeMode`, `context.isDark`, `LayrzThemeData.dark()`, `kDarkBackgroundColor`, `kAccentColor`, grid breakpoint constants `kExtraSmallGrid` et al., and the old fifteen-name text scale). Installation and usage examples moved to the GitHub wiki for sustained maintenance alongside the per-widget pages.
- Wiki corrected across seven pages (`Getting-Started`, `Theming`, `LayrzTokenizer`, `LayrzAlert`, `LayrzTooltip`, and two legacy examples) to reflect the five-style text scale (`display`, `headline`, `title`, `body`, `label`) that replaced the fifteen-name scale in 0.0.3.
- Progress tracking moved from a private GitHub Project to a public Notion board, linked from the README.

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
