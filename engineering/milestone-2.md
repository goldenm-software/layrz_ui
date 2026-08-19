# Milestone 2: Core Primitives

## Goal

Build foundational interactive widgets that most other components depend on: buttons, tooltips, chips, alerts, avatars, responsive layout, and selectable text.

This is the **first components milestone** after M1 Foundation. All M2 components establish UI patterns and state-management conventions that downstream components (M3–M6) will follow.

## Status

| # | Item | Status |
|---|---|---|
| 1 | LayrzButton with twelve styles and six semantic factories | Done |
| 2 | LayrzCard (elevated surface container) | Done |
| 3 | LayrzTooltip (composed on Overlay) | Done |
| 4 | LayrzAlert (inline status callout) | Done |
| 5 | LayrzChip and LayrzChipGroup | Done |
| 6 | LayrzRow / LayrzCol responsive grid | Done |
| 7 | LayrzConstrainedView | Done |
| 7a | LayrzUiL10n (133-key contract with English defaults) | Done |
| 8 | LayrzTextInput | Done |
| 9 | LayrzDropdownMenu | Done |
| 10 | LayrzButtonGroup (overflow actions menu) | Done |
| 11 | LayrzAvatar and LayrzImage | Done |
| 12 | LayrzText (selectable text) | Done |
| 13 | Material-free text selection (drag handles, toolbar, magnifier) | Todo |

**Note**: This table is the authoritative record of M2 work items, kept in step with the code in the same commit. Each row's status is updated when the item completes. The Notion ⚒️ Progress database is the shared, publicly linkable view of this same status (rows are identified as `DESIGN-N` for cross-reference). Item 2 (LayrzCard) is new scope added after the original milestone plan; it was not in the original eleven items.

## Definition of Done

- All 12 items below complete
- `flutter analyze` reports zero issues
- `flutter test` reports 100% pass on all M2 tests
- Coverage floor (90%) not breached
- Invariant verified: `grep -r "package:flutter/material\|package:flutter/cupertino" lib/` returns empty
- All new public code documented per CLAUDE.md rule #1
- Every widget has `@Preview` annotations (rule #3)
- All M2 components integrated with theme system (LayrzTheme, tokens, state resolution)
- Wiki pages created/updated for all M2 components

---

---

## Work Items

### 1. LayrzButton with Six Styles and Six Semantic Factories

**What changes**:
- Create `lib/src/buttons/button.dart` — `LayrzButton` widget
- Implement six style variants via parameter: `elevated`, `outlined`, `outlinedTonal`, and their Fab counterparts (`elevatedFab`, `outlinedFab`, `outlinedTonalFab`)
- Implement six semantic factories (`.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`)
- Material-free construction: RawTooltip → FocusableActionDetector → MouseRegion → GestureDetector → AnimatedContainer
- Create `lib/buttons.dart` barrel with re-exports

**API contract**:

`LayrzButton` constructor:
- `labelText` (String, required) — the only label form; no Widget label parameter
- `icon` (IconData?, optional) — from layrz_icons 2.0.0 (bare IconData constants)
- `onTap` (VoidCallback?, nullable) — null disables the button; also respects `isDisabled` flag
- `isDisabled` (bool, default false) — explicit disable flag; either `onTap: null` OR `isDisabled: true` disables
- `color` (Color?, optional) — overrides the accent, defaulting to tokens.colors.primary (only used when `type == LayrzButtonType.custom`)
- `style` (LayrzButtonStyle, required or with sensible default) — one of the twelve variants
- `controller` (LayrzButtonController?, optional) — An optional controller that drives the busy state (loading or cooldown). Multiple buttons can share a single controller instance. When null, the button has no loading or cooldown states.
- `hintText` (String?, optional) — tooltip hint text. When non-null, shown via RawTooltip. Fab buttons always show a tooltip; non-Fab buttons show a tooltip only when hintText is non-null. Fab tooltip displays `labelText` alone, or `labelText\nhintText` if hint is provided.

**Button sizing is fixed and standardised** — height, padding, icon size, and spacing all use design system constants. Buttons can be constrained by their parent but the intrinsic sizing is standardised and not caller-configurable.

**Semantic factories**:

Each factory takes:
- `labelText` (String, required) — button label
- `onTap` (VoidCallback, required) — callback
- `isFab` (bool, default false) — when true, renders the compact icon-only FAB variant (factory automatically maps the given `style` to its Fab twin via `asFab`); otherwise renders the full regular variant.
- `style` (LayrzButtonStyle, default `elevated`) — the button's visual style. Only non-Fab values are accepted (asserted). All six factories default to `elevated`.
- `controller` (LayrzButtonController?, optional) — An optional controller that drives loading/cooldown states. Multiple buttons can share a single controller.
- `isDisabled` (bool, default false)

| Factory | Icon | Semantic Color | Default `style` |
|---|---|---|---|
| `.save()` | `solarOutlineInboxIn` | `success` (green) | `elevated` |
| `.cancel()` | `solarOutlineCloseSquare` | `danger` (red) | `elevated` |
| `.info()` | `solarOutlineInfoSquare` | `info` (blue) | `elevated` |
| `.show()` | `solarOutlineEyeScan` | `info` (blue) | `elevated` |
| `.edit()` | `solarOutlinePenNewSquare` | `warning` (orange) | `elevated` |
| `.delete()` | `solarOutlineTrashBinMinimalisticN2` | `danger` (red) | `elevated` |

**Style context**: All factories default to `elevated`, reflecting typical button placement on plain surfaces where shadow depth helps the button stand out. Callers pass `style: LayrzButtonStyle.outlined` when nesting buttons inside elevated containers (cards, dialogs) or when a quieter appearance is desired for secondary or destructive actions like `.cancel()` or `.delete()`.

**Six style variants**:

| Pair | Regular | FAB | Visual Treatment |
|---|---|---|---|
| 1 | `.elevated` | `.elevatedFab` | Solid background with drop shadow |
| 2 | `.outlined` | `.outlinedFab` | Transparent background with accent border, no shadow |
| 3 | `.outlinedTonal` | `.outlinedTonalFab` | Semi-transparent background (tonal) with accent border, no shadow |

**Loading and cooldown states**:
- Loading indicator: shown as indeterminate progress bar; the button is disabled
- Cooldown indicator: shown as determinate progress bar that depletes over the countdown duration; the button is disabled
- No countdown numeral is displayed; the bar provides visual feedback of remaining time
- The `LayrzButtonController` manages the cooldown timing and provides `cooldownRemaining` for callers that want to display custom countdown UI
- `.legacyLoading()` is **not** ported from ThemedButton
- `onLongPress` and `customLongPressDuration` are **not** ported

**Material-free construction**:

The button is built without Material imports via this layer stack (inside-out):
1. `Semantics` — accessibility and semantic meaning
2. `RawTooltip` (from package:flutter/widgets.dart, Flutter 3.47) — for hintText; asserts an Overlay ancestor (provided by LayrzApp via WidgetsApp)
3. `FocusableActionDetector` — focus handling and keyboard navigation
4. `MouseRegion` — cursor and hover detection
5. `GestureDetector` — tap and long-press gestures
6. `AnimatedContainer` — visual state transitions (colour, shadow, opacity, border colour)

**Four-State Interaction Model and Fill Ladder**:

`LayrzButton` implements a four-state model with a shared fill ladder:

| State | Meaning | Precedence |
|---|---|---|
| **Default** | Idle, no pointer or keyboard interaction | — |
| **Hovered / Focused** | Pointer over the button, or keyboard focus | 2nd (hovered and focused render identically) |
| **Pressed** | Pointer/finger held down | 3rd (highest visual weight among active states) |
| **Disabled** | Non-interactive (disabled, loading, or cooldown) | **1st (overrides all others)** |

**Fill Ladder Principle**:

Each style starts on a different rung and climbs the same ladder as interaction increases: **transparent → tonal → solid**. This unified approach ensures visual consistency across all styles and makes adding new styles simple.

| Style | Default | Hovered / Focused | Pressed |
|---|---|---|---|
| `outlined` / `outlinedFab` | transparent + border | tonal + border | solid + border |
| `outlinedTonal` / `outlinedTonalFab` | tonal + border | tonal (stronger) + border | solid + border |
| `elevated` / `elevatedFab` | solid + shadow | solid + bigger shadow | solid (no shadow) |

**Key Invariants**:

- **Outlined pair border**: The border color remains constant across default, hovered, and pressed states (only the fill changes). This prevents visual "pop" when the border would otherwise vanish or shift.
- **Elevated shadow**: Only `elevated` and `elevatedFab` change shadows — they grow on hover (from `compact1` to `compact2`) and disappear on press (creating a "pressed down" metaphor). All other styles have fixed or zero shadows.
- **Focus as hover**: Keyboard focus resolves to the same appearance as mouse hover, satisfying WCAG 2.4.7 (Focus Visible, AA) without adding a fifth visual state.

**D15 Compliance** (Interaction States via Geometry Invariants):

Hover, press, focus, and disabled states vary only:
- Colour (background and text)
- Border colour
- Shadow (elevation)
- Opacity
- Cursor

They do **not** vary:
- Width or height (geometry is computed once, outside interaction resolution)
- Border width (constant per style)
- Padding or margin

This prevents reflow and flicker during state changes.

**Dependencies**:
- M1: LayrzTheme, tokens, state resolution (WidgetState, WidgetStateProperty)
- `layrz_icons: ^2.0.0` — added to pubspec.yaml (2.0.0 provides bare IconData constants)

**Files affected**:
- `lib/buttons.dart` (entrypoint barrel, new)
- `lib/src/buttons/` (new module directory)
- `lib/src/buttons/button.dart` (new, ~300–400 lines)
- `lib/src/buttons/button_style.dart` (new, enums and style definitions)
- `pubspec.yaml` (add layrz_icons dependency)
- `test/buttons/button_test.dart` (tests)
- `wiki/Widgets/LayrzButton.md` (wiki page, update with resolved spec)

**Acceptance criteria**:
- Constructor has every parameter documented (rule #1)
- All twelve styles render correctly with appropriate visual treatment
- All six semantic factories render with correct icons and colours
- `LayrzButtonController` drives loading/cooldown states; one controller can drive many buttons
- Loading state shows indeterminate progress indicator and disables interaction
- Cooldown state shows determinate progress indicator depleting over countdown duration and disables interaction; cooldown auto-clears on expiry
- Anti-flash floor prevents visibility changes < 100ms
- Hover state varies colour, shadow, opacity, and cursor only — no geometry change (D15)
- Press state varies colour only (D15)
- Focus state renders identically to hover (WCAG 2.4.7 compliance)
- Disabled state grays out and shows `not-allowed` cursor
- FAB variants render icon-only with appropriate sizing
- RawTooltip shows hintText on hover (with caveat that Overlay ancestor is required)
- `flutter analyze` clean, tests green (coverage >90%), Material/Cupertino grep empty
- `@Preview` annotations present at bottom of button.dart file
- Wiki page documents final API, examples, and RawTooltip caveat

---

### 2. LayrzCard (Elevated Surface Container)

**What changes**:
- Create `lib/src/cards/card.dart` — `LayrzCard` widget
- Create `lib/cards.dart` barrel with re-exports
- Support five discrete elevation levels (1–5); no custom elevation
- Support optional background color override; default to surface token
- Support optional interactive behavior via `onTap` parameter
- Material-free construction: Container + FocusableActionDetector + MouseRegion + Listener + GestureDetector + AnimatedContainer
- Create tests in `test/cards/` mirroring the source structure

**API contract**:

`LayrzCard` constructor:
- `child` (Widget, required) — the widget displayed inside the card
- `elevation` (int, default 1) — elevation level from 1–5, asserted at construction
- `backgroundColor` (Color?, optional) — override the surface token color; null defaults to tokens.colors.surface
- `onTap` (VoidCallback?, optional) — null disables the card (inert); non-null makes it interactive

**Interaction behavior**:
- **Non-interactive** (`onTap: null`): inert, fixed shadow, no hover/press feedback, not focusable, not announced as button
- **Interactive** (`onTap: non-null`): hover steps shadow +1 (clamped at 5), press steps shadow −1 (clamped at 1), keyboard-focusable, activatable by Enter/Space, announced as button

**Styling**:
- Padding fixed at `tokens.spacing.sp16` (16u) on all sides; not exposed
- Border radius fixed at `tokens.radius.r12` (12u); not exposed
- No outer margin (inter-child spacing owned by LayrzRow/LayrzConstrainedView)

**D15 Compliance** (no geometry changes):
- Hover, press, and focus states vary shadow and colour only
- Size, padding, border width, and radius remain constant across all states
- Focus indicator is conveyed via shadow elevation, not outline

**Dependencies**:
- M1: LayrzTheme, tokens, state resolution (WidgetState, WidgetStatesController)

**Files affected**:
- `lib/cards.dart` (entrypoint barrel, new)
- `lib/src/cards/` (new module directory)
- `lib/src/cards/card.dart` (new, ~200–250 lines)
- `test/cards/card_test.dart` (tests)
- `wiki/Widgets/LayrzCard.md` (wiki page)

**Acceptance criteria**:
- Constructor has every parameter documented (rule #1)
- Five elevation levels map correctly to shadow tokens
- Interactive cards respond to hover/press/focus with shadow elevation changes
- Non-interactive cards are inert
- D15 verified: no geometry changes during state transitions
- Keyboard activation (Enter/Space) works identically to tap
- `flutter analyze` clean, tests green (coverage >90%), Material/Cupertino grep empty
- `@Preview` annotations present at bottom of card.dart file
- Wiki page documents final API, interaction model, and D15 compliance

---

### 3. LayrzTooltip (Composed on Overlay)

**What changes**:
- Create `lib/src/tooltips/tooltip.dart` — `LayrzTooltip` widget, composed on `Overlay` / `OverlayEntry`
- Create `lib/src/tooltips/tooltip_position.dart` — position enumeration and delegate function
- Create `lib/src/constants/tooltip.dart` — sizing constants
- Create `lib/tooltips.dart` barrel with re-exports
- Retire temporary RawTooltip use in LayrzButton (`_buildTooltip()` and `layrzButtonTooltipPosition()` helpers removed, `lib/src/buttons/button_tooltip_position.dart` deleted, `kLayrzButtonTooltipVerticalOffset` removed)

**Implementation note**: The initial design assumption was that `LayrzTooltip` would be a thin wrapper over `RawTooltip`. During implementation, two issues emerged: (1) `RawTooltip` wraps the child in `Listener(HitTestBehavior.opaque)`, making the anchor bounds opaque and breaking hit-test transparency in overlapping layouts, and (2) the `positionDelegate` quirk with hardcoded `verticalOffset: 0.0` required baking gap logic into the delegate. The decision was reversed: `LayrzTooltip` was rebuilt as a composed implementation on `Overlay` / `OverlayEntry`, which fixed both issues and is now the shipped design.

**API contract**:

`LayrzTooltip` constructor:
- `child` (Widget, required) — the widget being wrapped with the tooltip
- `contentText` (String?, optional) — plain-text tooltip content (mutually exclusive with `contentRichText`)
- `contentRichText` (TextSpan?, optional) — rich-text content with per-span styling overrides (mutually exclusive with `contentText`)
- `position` (LayrzTooltipPosition, default `bottom`) — preferred position relative to the anchor (top, bottom, left, right); automatically flips to opposite side if tooltip would overflow

**Surface styling is fixed** to ensure visual consistency:
- Background color: `tokens.colors.fg1`
- Text color: `tokens.colors.background`
- Text style: `tokens.typography.labelSmall`
- Padding: horizontal `sp12`, vertical `sp6`
- Border radius: `r8`
- Max width: 80% of viewport width (guarded by `kLayrzTooltipMaxWidthFactor`)

**LayrzTooltipPosition enum** — specifies anchor position:
- `top` — position above the anchor
- `bottom` — position below the anchor (default)
- `left` — position to the left of the anchor
- `right` — position to the right of the anchor

**Positioning algorithm**:
1. Compute preferred position on the specified side, offset by `kLayrzTooltipOffset` (10u gap)
2. Check if the tooltip would overflow the overlay bounds on that side
3. If it overflows, flip to the opposite side
4. Clamp the tooltip on the cross axis to stay inside the overlay bounds

**Key invariants**:
- **Hit-test transparency** — The wrapper layers use `HitTestBehavior.translucent`, ensuring that wrapping a widget in `LayrzTooltip` does not change its hit-testing. Pointers pass through to the child and to layers beneath. The tooltip surface itself uses `ignorePointer: true` and is fully pass-through.
- **Layout neutrality** — Wrapping a widget in `LayrzTooltip` does not change its size, position, or layout. The tooltip is a separate `Overlay` portal.
- **Anchor-always-visible guarantee** — The tooltip always renders outside the anchor's bounding box on all four sides. This prevents the anchor from losing hover state and entering a flicker loop.
- **Graceful degradation**: If no Overlay ancestor exists, the widget returns its child unchanged (no tooltip shown). This allows tooltips to work in test harnesses without full ancestor trees.
- **Content is text-only**: Either `contentText` XOR `contentRichText`, enforced by constructor assert; no Widget content parameter. Mirrors LayrzButton's `labelText`-only rule
- **Trigger modes**: Long-press (touch) or hover (desktop); auto-dismiss on pointer-exit
- **No `color` parameter**: Surface color is standardised on `tokens.colors.fg1`/`tokens.colors.background`; removed from the original `ThemedTooltip` spec

**Dependencies**:
- M1: LayrzTheme, tokens
- Flutter 3.47: @Preview API (for widget preview annotations)
- Flutter SDK: Overlay, OverlayEntry, TextPainter, RenderBox (for measuring and positioning)

**Files affected**:
- `lib/tooltips.dart` (entrypoint barrel, new)
- `lib/src/tooltips/` (new module directory)
- `lib/src/tooltips/tooltip.dart` (new, ~150 lines)
- `lib/src/tooltips/tooltip_position.dart` (new, ~150 lines)
- `lib/src/constants/tooltip.dart` (new)
- `lib/src/buttons/button_tooltip_position.dart` (deleted)
- `test/tooltips/tooltip_test.dart` (new, tests)
- `test/tooltips/tooltip_passthrough_test.dart` (new, pass-through verification)
- `wiki/Widgets/LayrzTooltip.md` (new wiki page)
- `example/lib/src/sections/tooltips_section.dart` (new example usage)

**Acceptance criteria**:
- Constructor has every parameter documented (rule #1)
- Exactly one of `contentText` or `contentRichText` is non-null (enforced by assert)
- Surface styling is fixed and consistent with spec (fg1 background, background text color, labelSmall style, sp12/sp6 padding, r8 radius)
- `LayrzTooltipPosition` enum correctly positions tooltip on specified side (top, bottom, left, right)
- Overflow detection flips tooltip to opposite side when needed; tests verify all four positions and all four flips
- Cross-axis clamping keeps tooltip inside overlay bounds
- Hit-test transparency verified: wrapping a widget in `LayrzTooltip` does not change its hit-testing; anchor wrapper uses `HitTestBehavior.translucent`
- Surface pass-through verified: tooltip surface uses `ignorePointer: true`; content painted behind visible tooltip remains interactive
- Layout neutrality verified: wrapping does not change size, position, or layout of the child
- Anchor-always-visible verified: tooltip never overlaps the anchor's bounding box across all four positions and various anchor sizes (down to 4×24)
- Graceful degradation: returns child unchanged when no Overlay ancestor
- `kLayrzTooltipOffset` gap between tooltip and anchor is consistent (10u)
- `kLayrzTooltipMaxWidthFactor` constrains tooltip to 80% of viewport width
- Animation: fade-in/out with tokens.motion.dHover and tokens.motion.dPress timings
- Dismissal: auto-dismiss on pointer-exit; no tooltip leak across anchors on re-hover
- Lifecycle safety: no crashes on rapid mount/unmount cycles; no memory leaks
- `flutter analyze` clean, tests green (coverage >90%), Material/Cupertino grep empty
- `@Preview` annotations present at bottom of tooltip.dart file
- Wiki page documents final API, positioning, hit-test transparency guarantee, layout neutrality, anchor-always-visible invariant, and graceful degradation
- LayrzButton `_buildTooltip()` and `layrzButtonTooltipPosition()` helpers retired

---

### 4. LayrzAlert (Inline Status Callout)

**What changes**:
- Create `lib/src/alerts/alert.dart` — `LayrzAlert` widget with optional interactive behavior
- Create `lib/src/alerts/alert_type.dart` — semantic type enumeration
- Create `lib/src/alerts/alert_style.dart` — visual style enumeration
- Create `lib/src/alerts/alert_style_spec.dart` — immutable style specification resolver
- Create `lib/src/alerts/alert_icon.dart` — `LayrzAlertIcon` standalone building block
- Create `lib/src/constants/alert.dart` — sizing constants including `kLayrzAlertHoverLift`
- Create `lib/alerts.dart` barrel with re-exports
- Add `flattenOn` and `isOpaque` extension methods to `LayrzColorExtensions` for flattening translucent colors and checking opacity

**API contract**:

`LayrzAlert` constructor:
- `title` (String, required) — the title text displayed in bold
- `description` (String, required) — the body text with optional line-limiting
- `type` (LayrzAlertType, default `info`) — semantic type controlling icon and default color
- `style` (LayrzAlertStyle, default `layrz`) — visual style determining background, border, and text treatment
- `maxLines` (int, default 3) — maximum lines for description before ellipsis truncation
- `color` (Color?, optional) — override color, only used when `type == LayrzAlertType.custom`
- `icon` (IconData?, optional) — override icon, only used when `type == LayrzAlertType.custom`
- `iconSize` (double?, optional) — override icon glyph size; defaults to `kLayrzAlertIconSize` or `kLayrzAlertFilledIconSize` depending on style
- `onTap` (VoidCallback?, optional, default null) — callback invoked when the alert is tapped; null disables interactivity

**LayrzAlertType enum** — controls semantic color and icon:
- `info` — `tokens.colors.info` (blue), icon: `solarOutlineInfoSquare`
- `success` — `tokens.colors.success` (green), icon: `solarOutlineCheckSquare`
- `warning` — `tokens.colors.warning` (orange), icon: `solarOutlineDangerSquare`
- `danger` — `tokens.colors.danger` (red), icon: `solarOutlineCloseSquare`
- `context` — `tokens.colors.contextual`, icon: `solarOutlineMenuDotsSquare`
- `custom` — explicit `color` and `icon` parameters required; falls back to `tokens.colors.primary` and `solarOutlineInfoSquare` if not provided

**LayrzAlertStyle enum** — controls visual appearance:

| Style | Left Panel | Right Panel | Border | Icon/Text Color |
|---|---|---|---|---|
| `layrz` (default) | tonal accent (20% opacity) | surface | solid accent | accent (icon) / fg1 title, fg2 body |
| `filledIcon` | solid accent | surface | solid accent | contrast (icon) / fg1 title, fg2 body |

**LayrzAlertStyleSpec resolver** — immutable specification holding resolved colors:
- `backgroundColor` — fill color of right panel (surface)
- `borderColor` — color of alert border (solid accent)
- `borderWidth` — width in logical pixels (from tokens.border.base)
- `leftPanelColor` — fill color of left panel (tonal or solid accent depending on style)
- `iconColor` — color of icon glyph
- `titleColor` — color of title text (fg1)
- `bodyColor` — color of description text (fg2)

**Layout patterns**:
- **All styles** — split-panel layout with left panel (colored background, centered icon, sp16 padding) and right panel (surface background, title/description, sp16 padding); border painted via `foregroundDecoration` over both panels

**Interaction behavior**:
- **Non-interactive** (`onTap: null`, the default): Alert is inert — no cursor change, no hover/press visual feedback, not focusable, announces as a container to assistive technology. Rendering is identical to the pre-interactive design.
- **Interactive** (`onTap: non-null`): Alert responds to user interaction:
  - **Hover**: Surface lifts by `kLayrzAlertHoverLift` (4.0 logical pixels); shadow steps up one level. Animated with `tokens.motion.dHover` and `tokens.motion.easingEnter`.
  - **Focus**: Renders identically to hover (lifted, shadow elevated). Reachable via Tab navigation; activatable by Enter or Space (requires `LayrzApp` ancestor).
  - **Press**: Surface settles back down; shadow steps down one level.
  - **Lift mechanism**: Paint-only transform (`Matrix4.translationValues(0, -_currentLift, 0)`), not a layout change. The alert's bounding box and hit-test region remain constant across all states. This prevents hover oscillation (the surface cannot move out from under the pointer).

**D15 Compliance and Lift Amendment**:
- Interaction states vary only: shadow (via elevation), cursor, and colour. They do **not** vary: size, padding, margin, border width, or radius.
- The lift is a paint-only transform and is permitted under an amendment to decision D15 (2026-08-16). See [`Decisions (D15)`](https://github.com/goldenm-software/layrz_ui/blob/main/engineering/decisions.md) for the original decision and the amendment for the rationale and controlled conditions.

**Key invariants**:
- **Both title and description are required** — strict 1:1 port from ThemedAlert; no optional variants
- **`onTap` is optional** — null (default) disables interactivity; non-null enables it. Non-interactive alerts are the default and recommended pattern for informational callouts with no required user action.
- **No custom colour parameter on non-custom types** — color parameter is ignored unless `type == LayrzAlertType.custom`
- **LayrzAlertIcon is a standalone building block** (per decision D11) — LayrzAlert does not consume it; it is exported separately for reuse
- **Tonal opacity applied consistently** — via `tokens.colors.tonalOpacity` for tonal fills
- **Contrast color computed from accent** — via `accent.contrastColor` extension for white-on-dark and black-on-light
- **No geometry changes during state changes** — responsive, no fixed height on text elements (WCAG 1.4.4 support); only icon chips and filledIcon left panel are fixed-size

**Dependencies**:
- M1: LayrzTheme, tokens, extensions (contrastColor, withOpacityValue)
- `layrz_icons: ^2.0.0` — semantic icons

**Files affected**:
- `lib/alerts.dart` (entrypoint barrel, new)
- `lib/src/alerts/` (new module directory)
- `lib/src/alerts/alert.dart` (new, ~290 lines)
- `lib/src/alerts/alert_type.dart` (new, ~85 lines)
- `lib/src/alerts/alert_style.dart` (new, ~48 lines)
- `lib/src/alerts/alert_style_spec.dart` (new, ~166 lines)
- `lib/src/alerts/alert_icon.dart` (new, ~103 lines, standalone building block)
- `lib/src/constants/alert.dart` (new)
- `test/alerts/alert_test.dart` (new, comprehensive tests)
- `test/alerts/alert_type_test.dart` (new, type enum tests)
- `test/alerts/alert_style_test.dart` (new, style enum tests)
- `test/alerts/alert_icon_test.dart` (new, icon building block tests)
- `wiki/Widgets/LayrzAlert.md` (new wiki page)
- `wiki/Widgets/LayrzAlertIcon.md` (new wiki page for icon building block)
- `example/lib/src/sections/alerts_section.dart` (new example usage)

**Acceptance criteria**:
- Constructor has every parameter documented (rule #1)
- Both `title` and `description` are required (enforced by constructor signature)
- `onTap` parameter correctly controls interactivity: null disables, non-null enables
- Non-interactive alerts (`onTap: null`) render with no state changes and no cursor change
- Interactive alerts (`onTap: non-null`) respond to hover, press, and focus with visual feedback
- Hover/focus lift exactly `kLayrzAlertHoverLift` (4.0 logical pixels) via transform
- Lift is paint-only: bounding box and hit-test region are constant across states (verified via layout tests)
- Hover oscillation is prevented: alert surface cannot move out from under the pointer (hover detection wraps the transform)
- Animation timing uses `tokens.motion.dHover` and `tokens.motion.easingEnter`
- Press state settles surface back to rest position; shadow steps down one level
- Keyboard activation (Enter or Space) works identically to tap; no explicit shortcut binding needed (provided by LayrzApp)
- Interactive alerts announce as button with enabled state; non-interactive alert announces as container
- `LayrzAlertType` enum correctly maps to token colors via `colorToken()` method
- `LayrzAlertType` enum correctly maps to icons via `icon` property
- Custom type falls back to `primary` color and `solarOutlineInfoSquare` icon
- `LayrzAlertStyle` enum resolves to correct spec via `LayrzAlertStyleSpec.resolve()`
- **Layrz style**: split-panel layout with tonal (20% opacity) left panel, surface right panel, solid accent border, accent icon, fg1/fg2 text
- **FilledTonal style**: single-panel, tonal background, no border, no icon chip, accent text
- **Filled style**: single-panel, solid accent background, accent border, no icon chip, contrast text
- **Outlined style**: single-panel, transparent background, accent border, no icon chip, accent text
- **FilledIcon style**: split-panel layout with solid accent left (contrast icon), surface right (fg1 title, fg2 body), solid accent border
- Split-panel border painted via `foregroundDecoration` (not surrounding `BoxDecoration`) to avoid antialiasing seams between panels
- Interactive alerts with translucent fills flatten them to opaque equivalents via `flattenOn` extension to prevent shadows from bleeding through
- `Color.flattenOn(background)` and `Color.isOpaque` extension methods added to `LayrzColorExtensions`
- `iconSize` parameter overrides default (kLayrzAlertIconSize or kLayrzAlertFilledIconSize)
- `maxLines` limits description text before ellipsis
- `LayrzAlertIcon` is a standalone public widget exported from `lib/alerts.dart`
- `flutter analyze` clean, tests green (coverage >90%), Material/Cupertino grep empty
- `@Preview` annotations present at bottom of alert.dart file (one per style)
- Wiki pages document final API, interaction model, style specs table (with split-panel column), icon building block, layout patterns, and implementation notes on border painting and fill flattening
- Tests verify interactive behavior: hover lift translation, layout neutrality, oscillation safety, keyboard activation, and shadow rendering with flattened fills

---

### 5. LayrzChip and LayrzChipGroup

**What it is**:

`LayrzChip` — static, visual-only compact label widget with optional leading icon and delete affordance. **Not a selection control.** The chip itself has no tap, hover, focus, or selected state — only the optional delete icon is interactive.

`LayrzChipGroup` — horizontal layout of multiple chips with two overflow behaviors: `.none` (single scrollable row) or `.compact` (clamp to available width with `+N` overflow indicator).

Chips render at fixed height with pill-shaped border radius (`tokens.radius.full`). The `computeWidth()` method measures chip width for the group's compact layout.

**Key design rule**: Chips are visual-only. Selection state, toggling, and checkbox-style affordances are **out of scope**. These are labels, not controls.

**LayrzChipStyle** enumeration (three values):
- `filled` — solid accent background, no border
- `outlined` — transparent background with accent border
- `filledTonal` — semi-transparent (tonal) background, no border

**LayrzChipType** enumeration (six values for semantic color):
- `info`, `success`, `warning`, `danger`, `context` — resolve to token colors
- `custom` — use explicit `color` parameter

**LayrzChipGroupBehavior** enumeration (two values):
- `none` (default) — single horizontal row that scrolls on overflow
- `compact` — clamp to available width; remainder collapses into a `+N` chip whose tooltip lists hidden labels. **Caveat**: Requires finite `maxWidth` constraint (asserts otherwise). Measures each chip individually, so the `+N` indicator may appear one chip early or late depending on rounding. Costs one text layout per chip per build.

**Dependencies**: M1 (LayrzTheme, tokens, WidgetState, extensions), M2.3 (LayrzTooltip for compact overflow tooltip).

**Files affected**:
- `lib/src/chips/chips.dart` (per-module barrel, new)
- `lib/src/chips/src/chip.dart` (new, LayrzChip widget)
- `lib/src/chips/src/chip_group.dart` (new, LayrzChipGroup widget)
- `lib/src/chips/src/chip_style.dart` (new, enum)
- `lib/src/chips/src/chip_type.dart` (new, enum)
- `lib/src/chips/src/chip_group_behavior.dart` (new, enum)
- `lib/src/chips/src/chip_style_spec.dart` (new, style resolution)
- `lib/layrz_ui.dart` (update to export chips module)
- `test/chips/chip_test.dart` (tests)
- `test/chips/chip_group_test.dart` (tests)
- `wiki/Widgets/LayrzChip.md` (new wiki page)
- `wiki/Widgets/LayrzChipGroup.md` (new wiki page)

---

### 6. LayrzRow / LayrzCol Responsive Grid

**Brief description**:

`LayrzRow` — 12-column responsive grid container (wraps Row internally). Children are `LayrzCol` instances.

`LayrzCol` — column definition within a responsive row. Specifies width at each breakpoint (xs, sm, md, lg, xl).

Example:
```dart
LayrzRow(
  children: [
    LayrzCol(xs: 12, sm: 6, md: 4, child: ...),
    LayrzCol(xs: 12, sm: 6, md: 8, child: ...),
  ],
)
```

Breakpoints are themeable via `LayrzBreakpointTokens` on the theme (default thresholds: xs=600, sm=960, md=1264, lg=1904). Apps can customize breakpoints when creating a custom theme without modifying layrz_ui's code.

**Porting note**: `ResponsiveRow.builder(itemCount:, itemBuilder:)` was deliberately not ported to layrz_ui. Callers use `LayrzRow(children: List.generate(...))` instead, which is simpler and clearer. This resolves the review trigger on decision D9 in `engineering/decisions.md`. The `useScreenWidth` escape hatch was removed; breakpoints are always viewport-driven per decision D21.

**Dependencies**: M1 (tokens, breakpoint tokens).

**Files affected**:
- `lib/grid.dart` (entrypoint barrel, new)
- `lib/src/grid/` (new module directory)
- `lib/src/grid/row.dart` (new)
- `lib/src/grid/col.dart` (new)
- `lib/src/grid/grid_previews.dart` (preview annotations for both widgets)
- `test/grid/row_test.dart` (tests)
- `test/grid/col_test.dart` (tests)
- `test/grid/grid_a11y_test.dart` (accessibility tests)

---

### 7. LayrzConstrainedView

**Brief description**:

`LayrzConstrainedView` — constrains the maximum width of its children, centres them horizontally, and lays them out in a vertical `Column` internally. The Bootstrap `.container` / 960-grid pattern — a centred, constrained column for page layouts.

Example:
```dart
LayrzConstrainedView(
  maxWidth: 960,
  spacing: 16,
  children: [
    // page content
  ],
)
```

The component constructs the internal `Column` itself; callers pass `children` directly, not a pre-built `Column`. Nothing is clipped — it constrains and centres, which is why it is not called "cropped". The `maxWidth` parameter is caller-configurable; the example uses 960, but any value is valid.

**Exposed vs. Fixed Parameters — Architecture Decision**:

Because the `Column` is built internally, properties a caller would normally set on it must be deliberately exposed or they become inaccessible. The decision is:

- **`spacing` (double?, optional)** — **Exposed.** Controls the gap between children. When not provided, defaults to `context.tokens.spacing.base` from the theme, allowing design system control. Callers can pass `0` for flush layouts or any other value.

- **`mainAxisAlignment` and `crossAxisAlignment`** — **Fixed (not exposed).** The internal `Column` is fixed to `mainAxisAlignment: MainAxisAlignment.start` and `crossAxisAlignment: CrossAxisAlignment.stretch`. These are deliberately not exposed as parameters because this component is designed for a specific layout pattern (top-to-bottom, full width). Callers needing different alignments pass their own `Column` as a child.

**Dependencies**: M1 (constants, tokens).

**Files affected**:
- `lib/grid.dart` (update entrypoint barrel — already exists from item 5)
- `lib/src/grid/constrained_view.dart` (new)
- `test/grid/constrained_view_test.dart` (tests)

---

### 8. LayrzTextInput

**Brief description**:

`LayrzTextInput` — foundational text input widget. Base of the entire M3+ input family: every other `Layrz*Input` composes it, and picker-style inputs render as a read-only `LayrzTextInput` that opens their surface on tap.

At least 6 M3 components and 14 M4 pickers depend on it. Its chrome — label, prefix/suffix, help affordance, padding, error display, focus decoration — becomes the chrome of every input in the system, so visual decisions here are not local.

**BLOCKER — IMPORTANT**: The visual design diverges from `ThemedTextInput` per internal meetings and is not captured anywhere. Before implementation starts, a Figma frame, meeting doc, or Notion link must be attached that shows the final design direction. Without this, roughly twenty downstream components (M3–M5 inputs and pickers) will be redone later.

**Hidden scope**: `EditableText` needs concrete selection handles and a selection toolbar. Material supplies those and they cannot be used, so a Material-free `TextSelectionControls` is required and may warrant its own milestone item — note `RawMagnifier` and `SystemContextMenu` as relevant Flutter SDK types. Item 12 (`LayrzText`) ships without custom selection controls using `emptyTextSelectionControls` from the SDK; once this item's work lands, `LayrzText` can optionally adopt it for touch affordances. The two are independent, not blocking.

**Primitive**: `EditableText`.

**Dependencies**: M1 (LayrzTheme, tokens).

**Files affected**:
- `lib/inputs.dart` (entrypoint barrel, new)
- `lib/src/inputs/` (new module directory)
- `lib/src/inputs/text_input.dart` (new)
- `test/inputs/text_input_test.dart` (tests)

---

### 9. LayrzDropdownMenu

**Status**: Shipped in 0.0.7 and amended in 0.0.8. All tests passing. Implementation complete per decision D28. In 0.0.8, entry colour simplified from `LayrzColorSwatch?` to `Color?` (decision D29), and dropdown labels gained an optional colour parameter for tonal band styling.

**What it is**:

`LayrzDropdownMenu` — a popup menu anchored to a trigger widget, built on `RawMenuAnchor` (Flutter 3.47). Menu items are a **sealed hierarchy** — arbitrary widgets cannot be inserted. This ensures all menus across the app have a consistent look and behavior.

The trigger is a builder function that receives the `MenuController`, allowing the caller to wire their own tap handler directly to the controller. This is **not a wrapped child** — the menu installs no gesture handling; the trigger owns the gesture. Reason: `LayrzButton` (a common trigger) keeps a non-null `onTapCancel` even when disabled, creating a gesture recognizer that wins the arena. A menu wrapping its trigger in a `GestureDetector` would never open.

**Menu items** (sealed class `LayrzDropdownItem`):
- `LayrzDropdownEntry` — interactive row with label, optional icon, optional color override (for destructive actions), and an `onTap` callback. Automatically closes the menu after tapping. Only focusable entries can be traversed with arrow keys.
- `LayrzDropdownLabel` — non-focusable section heading with optional tonal colour band

**Animation**: Menu enters with fade + 4px translate from the anchor's side. **There is no exit animation** — `RawMenuAnchor` tears the overlay down synchronously on close. Documented so nobody files it as a bug.

**Keyboard interaction**: Escape closes, arrow keys traverse focusable entries (dividers and labels are skipped), outside-tap dismissal is automatic.

**Positioning**: Panel is positioned below the anchor by default. If insufficient space, it flips above. Horizontal alignment is configurable via `LayrzDropdownMenuAlignment` enum (`start`, `center`, `end`), with bounds clamping.

**Dependencies**: M1 (LayrzTheme, tokens, extensions), Flutter 3.47 (RawMenuAnchor), M2.1 (LayrzButton recommended for triggers).

**Files affected** (tracking on separate branch):
- `lib/src/menus/menus.dart` (per-module barrel, new)
- `lib/src/menus/src/dropdown_menu.dart` (new, LayrzDropdownMenu widget)
- `lib/src/menus/src/dropdown_items.dart` (new, sealed item hierarchy)
- `lib/src/menus/src/dropdown_menu_types.dart` (new, LayrzDropdownMenuAlignment enum)
- `lib/src/menus/src/dropdown_entry_style_spec.dart` (new, style resolution)
- `lib/layrz_ui.dart` (update to export menus module)
- `test/menus/dropdown_menu_test.dart` (tests)
- `test/menus/dropdown_items_test.dart` (tests)
- `wiki/Widgets/LayrzDropdownMenu.md` (wiki page will be restored when implementation lands)

---

### 10. LayrzButtonGroup

**Brief description**:

`LayrzButtonGroup` — row of primary actions with an overflow menu for secondary actions. Replaces the old section 2 components (`LayrzActionButton` / `LayrzActionsButtons`), which are superseded by this unified pattern. Renamed from `LayrzGroupedButton` for uniformity with the shipped `LayrzChipGroup`; group components follow the `Layrz<Thing>Group` naming convention.

A horizontal group of buttons (typically 2–4) that renders in a row on large viewports, collapsing to a single fab trigger opening a `LayrzDropdownMenu` below the `md` breakpoint. Mode is controlled by a nullable `bool useDropdown` parameter; no enum is exposed. Depends on LayrzDropdownMenu for the overflow surface and LayrzButton for the individual actions.

**Dependencies**: M1 (LayrzTheme, tokens), M2.9 (LayrzDropdownMenu), M2.1 (LayrzButton).

**Files affected**:
- `lib/src/buttons/src/button_group.dart` (new)
- `lib/src/buttons/src/button_group_previews.dart` (new, preview annotations)
- `lib/src/buttons/src/button_type.dart` (new, LayrzButtonType.semanticColor extension)
- `lib/src/buttons/buttons.dart` (update barrel)
- `test/buttons/button_group_test.dart` (new, 28 comprehensive tests)
- `example/lib/src/sections/button_group_section.dart` (new showroom section)

---

### 11. LayrzAvatar and LayrzImage

**Brief description**:

`LayrzAvatar` — static display component rendering a layrz_sdk `Avatar` by type, with fallback to generated initials. Always a rounded box using the `r12` radius token, consistent with `LayrzCard` and `LayrzAlert`. No interaction affordances (callers wrap if needed). Per decision D31, avatars are display-only.

`LayrzImage` — image widget resolving network URLs, data-URIs, bare base64, and asset paths. Includes SVG support via flutter_svg and a bounded cache for decoded base64 bytes.

**Dependencies**: M1 (LayrzTheme, tokens), layrz_sdk (Avatar model), flutter_svg (SVG rendering).

**Files affected**:
- `lib/src/images/images.dart` (per-module barrel, new)
- `lib/src/images/src/avatar.dart` (new, LayrzAvatar)
- `lib/src/images/src/image.dart` (new, LayrzImage)
- `lib/src/images/src/image_source.dart` (new, source resolution logic)
- `lib/src/images/src/images_previews.dart` (new, preview annotations)
- `lib/layrz_ui.dart` (update to export images module)
- `test/images/avatar_test.dart` (tests, includes accessibility suite)
- `test/images/avatar_a11y_test.dart` (accessibility tests)
- `test/images/image_test.dart` (tests)
- `test/images/image_source_test.dart` (source detection tests)
- `example/lib/src/sections/images_section.dart` (new showroom section)

---

### 12. LayrzText (Selectable Text)

**What it is**:

`LayrzText` is a **Material-free, text-only drop-in replacement for Flutter's `Text`** that makes text selectable and copyable by wrapping `SelectableRegion` from `package:flutter/widgets.dart`. Any `Text` child becomes selectable because `Text` builds a `RichText` which already participates in selection by registering with an inherited `SelectionRegistrar`. Flutter's default is non-selectable text; `LayrzText` bridges the scope gap.

`SelectableRegion` implements copy via `CopySelectionTextIntent` and `SelectAllTextIntent`, so keyboard selection (Ctrl+A) and copy (Ctrl+C) work without additional UI.

**API mirrors `Text` exactly**, including both constructors:
- `LayrzText(String data, {...})` — single-line text
- `LayrzText.rich(InlineSpan textSpan, {...})` — styled rich text

All `Text` parameters are supported: `style`, `strutStyle`, `textAlign`, `textDirection`, `locale`, `softWrap`, `overflow`, `textScaler`, `maxLines`, `semanticsLabel`, `semanticsIdentifier`, `textWidthBasis`, `textHeightBehavior`, `selectionColor`.

**Four additions beyond `Text`**:
- `selectable` (bool, default true) — when false, renders as a plain `Text` (no `SelectableRegion`) for performance in hot lists
- `focusNode` (FocusNode?) — caller-owned when supplied; created and disposed internally when null
- `onSelectionChanged` (ValueChanged<SelectedContent?>?) — receives `SelectedContent.plainText` when selection changes, or null when cleared
- **One deliberate divergence**: null `style` resolves to `tokens.typography.body` (not the inherited `DefaultTextStyle`). Call this out prominently.

Ships with `emptyTextSelectionControls` from `package:flutter/widgets.dart` (a no-op implementation satisfying `SelectableRegion`'s required `selectionControls` parameter). Drag handles on touch and a context menu are deferred — not required for initial ship. When `LayrzTextInput` (item 8) lands with a Material-free `TextSelectionControls`, `LayrzText` can optionally adopt it for touch affordances.

**Not an input. No editing.** This widget is separate from `LayrzTextInput` (item 8). LayrzText provides read-only selection and copy; LayrzTextInput provides editing. No relationship beyond both touching text.

**Primitive**: `SelectableRegion` (Flutter 3.47), `emptyTextSelectionControls` (Flutter).

**Dependencies**: M1 (LayrzTheme, tokens, extensions).

**Files affected**:
- `lib/src/text/text.dart` (per-module barrel, new)
- `lib/src/text/src/text.dart` (new, LayrzText widget)
- `lib/src/text/src/text_previews.dart` (new, @Preview annotations)
- `lib/layrz_ui.dart` (update to export text module)
- `test/text/text_test.dart` (tests)
- `wiki/Widgets/LayrzText.md` (new wiki page)

---

## Acceptance Criteria

M2 is complete when all the following criteria are satisfied:

- **Item 1 (LayrzButton)**: Constructor documented, six styles render correctly, six semantic factories render with icons and colours, loading/cooldown states externally-owned via ValueListenable, D15 interaction states verified (no geometry changes), RawTooltip caveat noted, `flutter analyze` clean, tests green, `@Preview` annotations present, D27 style trim from 12 to 6 applied
- **Item 2 (LayrzCard)**: Five elevation levels, optional backgroundColor override, interactive cards respond to hover/press/focus with shadow elevation changes, non-interactive cards are inert, D15 verified (no geometry changes during state transitions), `flutter analyze` clean, tests green, `@Preview` annotations present
- **Item 3 (LayrzTooltip)**: Wraps RawTooltip, theme-aware positioning with overflow detection and flipping, content is text-only (contentText XOR contentRichText), pass-through requirement (`ignorePointer: true`), graceful degradation with no Overlay ancestor, animation with motion tokens, RawTooltip Overlay requirement documented, SDK `verticalOffset` gotcha documented, LayrzButton `_buildTooltip()` helpers retired, `flutter analyze` clean, tests green (including passthrough verification), `@Preview` annotations present
- **Item 4 (LayrzAlert)**: Six semantic types (info, success, warning, danger, context, custom), two visual styles (layrz, filledIcon) with split-panel layout and correct style spec resolution, both title and description required, LayrzAlertIcon standalone building block, interactive and non-interactive modes with D15 compliance, `flutter analyze` clean, tests green, `@Preview` annotations present for each style, D27 style trim from 5 to 2 applied
- **Item 5 (LayrzChip/ChipGroup)**: Chip styling, delete action, group selection behaviour, state management via WidgetState
- **Item 6 (LayrzRow/Col)**: 12-column grid, breakpoint-specific widths, responsive adaptation
- **Item 7 (LayrzConstrainedView)**: Constrains max width, centres horizontally, lays children in Column internally, nothing clipped, exposes spacing parameter with default from tokens
- **Item 8 (LayrzTextInput)**: Design blocker resolved (Figma/Notion link attached), EditableText with Material-free selection controls, label/prefix/suffix/help/error chrome, focus decoration, foundation for all M3+ inputs
- **Item 9 (LayrzDropdownMenu)**: Menu surface anchored to trigger, RawMenuAnchor integration, single/multi-item selection, theme integration, prerequisite for LayrzButtonGroup
- **Item 10 (LayrzButtonGroup)**: Horizontal action buttons with overflow menu, LayrzDropdownMenu integration, semantically replaces old LayrzActionButton/ActionsButtons
- **Item 11 (LayrzAvatar/LayrzImage)**: Avatar from URL/base64/initials, image fallback, placeholder rendering
- **Item 12 (LayrzText)**: Wraps `SelectableRegion` with `emptyTextSelectionControls`, making child `Text` selectable and copyable; keyboard copy (Ctrl+C) works via `SelectableRegion`'s `CopySelectionTextIntent`; drag handles and context menu deferred as optional enhancements
- **All tests pass**: `flutter test` reports 100% pass
- **Coverage floor maintained**: `flutter test --coverage` reports >90% coverage (current baseline 97.21%)
- **Invariant verified**: `grep -r "package:flutter/material\|package:flutter/cupertino" lib/` returns empty
- **All code documented**: Every public member has doc comments per rule #1
- **All visual components have @Preview**: Annotations at bottom of widget files
- **Wiki updated**: Pages created for all M2 components with API, examples, and design rationale
- **engineering/milestone-2.md Status table updated**: All items marked Done (authoritative record kept in sync with code)

---

## Explicit Non-Goals

The following **are out of scope** for M2:

- **Any M3+ components** (inputs, pickers, etc.) — M3 and beyond
- **Dark theme** — layrz_ui targets light mode only; see decision D7 in engineering/decisions.md
- **Accessibility audit** — baseline WCAG coverage via Semantics is in place; comprehensive audit is deferred
- **Performance optimization** — measure after all M2 components exist

---

**Milestone 2 plan finalized**: 2026-08-15
