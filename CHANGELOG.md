# Changelog

## 0.0.9

**The input family's foundation, plus localization.** Adds `LayrzTextInput` — the component every other `Layrz*Input` will compose — and the `LayrzUiL10n` localization contract it depends on.

### Breaking

- **`LayrzAvatar` no longer depends on `layrz_sdk`.** The `avatar` parameter is removed and replaced with `source: LayrzAvatarSource?`. The sealed hierarchy `LayrzAvatarSource` contains four concrete types: `LayrzAvatarUrl`, `LayrzAvatarBase64`, `LayrzAvatarIcon`, and `LayrzAvatarEmoji`. All four variants hold their data directly (URL string, base64 string, `IconData`, emoji string) rather than wrapping SDK types. Migration: replace `Avatar(type: AvatarType.url, url: '...')` with `LayrzAvatarUrl('...')`, `Avatar(type: AvatarType.base64, base64: '...')` with `LayrzAvatarBase64('...')`, `Avatar(type: AvatarType.icon, icon: icon)` with `LayrzAvatarIcon(icon.iconData)` (convert SDK `LayrzIcon` to `IconData`), and `Avatar(type: AvatarType.emoji, emoji: '...')` with `LayrzAvatarEmoji('...')`. The `.image()`, `.icon()`, `.emoji()`, and `.initials()` named constructors are unchanged.

- **`layrz_icons` remains at `^1.1.1`.** Although layrz_ui no longer depends on layrz_sdk directly, the `layrz_ui_extensions` package must depend on both layrz_ui and layrz_sdk to provide the `Avatar` → `LayrzAvatarSource` conversion — and layrz_sdk 4.4.3 pins `layrz_icons: ^1.1.1`. Decision D30's exit condition (raise to 2.x once layrz_sdk upgrades) therefore remains unmet.

### Added

- **`LayrzTextInput`** — Material-free single-line text field built directly on `EditableText`, and the base of the entire input family. Every future `Layrz*Input` composes it rather than reimplementing field chrome, so its label, slots, help affordance, error display and focus decoration are the chrome of every input in the system. Reference DESIGN-33 and decision D32.

  Key API notes: **at least one of `labelText` or `hintText` is required** (a debug assertion enforces it) — a search field wants only a hint, a form field only a label, and both together is valid. Each of the prefix and suffix slots accepts **at most one** of `prefixIcon` / `prefix` / `prefixText` (and the suffix equivalents), asserted in debug. `errors` is a caller-owned `List<String>` rendered joined with `", "` on a single line in bold `w700` — there is no `validator` and the widget never self-validates. `maxLength` renders a `"12/50"` counter right-aligned opposite the error message, which stays neutral `fg3` even when errors are present. `disabled` blocks all interaction; `readOnly` still fires `onTap`, which is what picker-style inputs depend on. `shortcut` renders a `⌘K`-style badge but binds nothing (see DESIGN-71) and is hidden entirely on mobile.

- **`LayrzUiL10n`** — The localization contract for the design system: 133 keys across 17 namespace mixins, each supplying an English default. Ships with `LayrzUiL10nDefault`, `LayrzUiL10nDelegate` and a `context.l10n` accessor, wired automatically by `LayrzApp` so the package works with zero configuration. Consumers extend `LayrzUiL10n` and override only the keys they need; keys added in later versions inherit their English default rather than breaking the subclass. Reference DESIGN-73.

  Integration note: a consumer's own delegate must be declared `LocalizationsDelegate<LayrzUiL10n>`, **never** over a subclass. `LocalizationsDelegate.type` is the key `Localizations.of` looks up, so a subclass-typed delegate is never found and every string silently falls back to English with no error.

- **`LayrzTooltip.titleText`** — Optional title rendered above the tooltip content in a heavier weight. Purely additive; existing tooltips are unchanged.

- **Showroom section for inputs** — The example app gains a `LayrzTextInput` section covering field states, label and hint variants, all three slot forms including arbitrary widgets, error display, the help affordance, `dense`, the shortcut badge and a numeric field.

### Changed

- **Type scale adjusted** — `display` is now 40px at `w700` (was 45px at `w800`), `headline` is `w600` (was `w700`), and `label` is `w400` (was `w300`). `title` (16px `w600`) and `body` (14px `w400`) are unchanged. This is a visual change to every component reading `tokens.typography`, not an API change.

- **`formatLayrzShortcut` moved to a new `keyboard` module** — Relocated from `lib/src/menus/src/` now that it has a second consumer, and given its first test suite. Non-breaking for consumers, who reach it through the root barrel.

### Design Notes

- **Text selection is deliberately deferred.** `LayrzTextInput` passes `null` for both `selectionControls` and `contextMenuBuilder`, which makes `EditableText` skip the selection overlay entirely while caret placement, drag-selection and keyboard selection continue to work. Selection handles, the copy/paste toolbar and the mobile magnifier are tracked separately as DESIGN-74. Material supplies these normally and its implementation cannot be used.

- **Field geometry is deterministic.** Height resolves from the icon size, so a field with icons is exactly as tall as one without, and every interaction state renders at identical height and border width per decision D15. Caller-supplied slot widgets are constrained to that height so a picker passing a colour swatch or avatar cannot stretch the field.

- **Decision D35 was retracted.** It amended D15 to permit dashed borders on modal states. The dashed border was removed before release — it never rendered, because the painter drew beneath an opaque fill — so the amendment defends nothing and D15 stands unamended. References D32, D33 and D34.

- **The i18n binding lives in a separate package.** `layrz_ui_i18n` (`goldenm-software/layrz_ui_i18n`) adapts `LayrzUiL10n` to the `layrz_i18n` engine. It is not published from this repository, and `layrz_ui` deliberately carries no dependency on any translation engine.

---

## 0.0.8

**Final M2 core primitives.** Adds three remaining M2 components and amends the dropdown menu implementation.

### Breaking

- **`LayrzDropdownEntry.color` is now `Color?` instead of `LayrzColorSwatch?`** — The swatch type was originally justified because pressed and hovered states read `accent.shade100` and `accent.shade700`. Those states are now neutral opaque tokens, so no shades are read anywhere. Passing token swatches still compiles and renders identically (each swatch is constructed with shade500 as its primary value), so most callers need no change. Only code that *reads* the field back expecting a swatch (e.g., `entry.color.shade700`) will break at compile time. Reference decision D29.

### Added

- **`LayrzDropdownLabel.color`** — Optional `Color?` parameter that fills the label's tonal band. Null keeps the neutral `surface3` fill, so existing menus are visually unchanged. Paired with D29's dropdown entry colour simplification.
- **`LayrzDropdownEntry` semantic factories** — Six convenience factories preset icon and semantic colour to match action semantics: `.save()` (icon `solarOutlineInboxIn`, colour `tokens.colors.success`), `.cancel()` (icon `solarOutlineCloseSquare`, colour `tokens.colors.danger`), `.info()` (icon `solarOutlineInfoSquare`, colour `tokens.colors.info`), `.show()` (icon `solarOutlineEyeScan`, colour `tokens.colors.info`), `.edit()` (icon `solarOutlinePenNewSquare`, colour `tokens.colors.warning`), `.delete()` (icon `solarOutlineTrashBinMinimalisticN2`, colour `tokens.colors.danger`). All factories accept optional `icon` and `color` overrides. Semantic type is resolved to token colour at build time via a private enum, never exposed as public API.
- **`LayrzButtonGroup`** — Responsive group of dropdown items rendering as a row of buttons or collapsed into a single dropdown trigger. Takes `items: List<LayrzDropdownItem>` (entries and labels). In row mode (above `md` breakpoint), `LayrzDropdownEntry` items convert to labelled `LayrzButton` instances; `LayrzDropdownLabel` items are silently skipped. In dropdown mode, all items pass through to `LayrzDropdownMenu` unchanged. Mode driven by a nullable `bool useDropdown` parameter. The `triggerHintText` parameter is required and serves as the trigger's stable accessible name. Reference DESIGN-31 and the model inversion: items are the source of truth, not derived from buttons.

- **`LayrzButtonGroup.builder`** — Variant constructor allowing a custom trigger widget. Identical to the default constructor except the trigger is built via `builder: (context, controller)` instead of the hardcoded `triggerHintText` / `triggerIcon`. Row mode is identical for both constructors. Gesture-arena warning: wire the controller directly to the trigger's `onTap`, do not wrap in `GestureDetector`.

- **`LayrzAvatar`** — Static display component rendering a layrz_sdk `Avatar` by type (URL, base64, icon, emoji), with initials as the fallback when the avatar is null or missing. Always a rounded box using the `r12` radius token, consistent with `LayrzCard` and `LayrzAlert`, and carries a fixed `tokens.shadow.compact1` drop shadow in all render modes. No interaction affordances; callers wrap if needed. Initials algorithm is deterministic but not locale-aware (no Unicode segmentation). Reference decision D31.

- **`LayrzImage`** — Image widget resolving network URLs, data-URIs, bare base64, and asset paths. Includes SVG support via flutter_svg and a bounded cache for decoded base64 bytes. Uses `ImageSource` to detect and parse the source type automatically.

- **Dependencies: layrz_sdk and flutter_svg** — New dependencies to support avatar models and SVG rendering. layrz_sdk requires `layrz_icons: ^1.1.1`, so the package constraint is downgraded from `^2.0.0` to `^1.1.1`. All 20 used IconData symbols are identical in both versions, verified byte-for-byte. Reference decision D30.

### Changed

- **`layrz_icons` constraint lowered from `^2.0.0` to `^1.1.1`** — Required by layrz_sdk 4.4.3. All used symbols are identical across versions. Exit condition: raise constraint back to `^2.0.0` once layrz_sdk upgrades.

### Design Notes

- **D29** documents the post-mortem on `LayrzDropdownEntry.color`. The lesson: when an API's original constraint is removed, actively audit the dependency graph for surviving references to that constraint and remove them. The swatch type should not have survived the interaction-state redesign.

- **D30** records the dependency trade-off: layrz_sdk brings 18 transitive dependencies (including `dio`, `layrz_i18n`, `layrz_logging`, `web_socket_channel`), and flutter_svg adds the vector graphics chain. All verified Material-free. Exit condition explicit: revert to `^2.0.0` once layrz_sdk advances.

- **D31** documents that `LayrzAvatar` is static display-only, following the same pattern as `LayrzChip` per decision D28. No interaction affordances, no elevation parameter — but the avatar always carries a fixed `tokens.shadow.compact1` drop shadow. Callers own interaction logic.

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
