# LayrzProgressBar — API Reference

Source: `lib/src/progress/src/progress_bar.dart`
- `LayrzProgressBar` class
- Companion enums: `lib/src/progress/src/progress_format.dart` (`LayrzProgressFormat`), `lib/src/progress/src/progress_type.dart` (`LayrzProgressType`)
- `lib/src/progress/src/progress_labeled_bar.dart` — `LayrzLabeledProgressBar`
- `lib/src/progress/src/progress_value_format.dart` — `formatLayrzProgressValue`

**Note:** the wiki page at `wiki/Widgets/LayrzProgressBar.md` names the color enum `LayrzProgressBarType` and omits `format`/circular mode entirely, and states a default `height` of `8.0`. The actual source defines `LayrzProgressType` (not `LayrzProgressBarType`), a full linear/circular `format` axis, and a default `height` of `kLayrzProgressBarHeight` (`16.0`). This reference follows the source.

---

## Examples

```dart
// Determinate linear bar
LayrzProgressBar(value: 0.42, semanticLabel: 'Upload progress')

// Indeterminate linear bar
LayrzProgressBar(semanticLabel: 'Loading')

// Circular ring, determinate
LayrzProgressBar(format: .circular, value: 0.75, semanticLabel: 'Sync progress')

// Circular ring, indeterminate
LayrzProgressBar(format: .circular, semanticLabel: 'Loading')

// Semantic type — danger
LayrzProgressBar(value: 0.92, type: .danger, semanticLabel: 'Storage quota used')

// Custom color
LayrzProgressBar(
  value: 0.5,
  type: .custom,
  color: const Color(0xFF6A0DAD),
)

// Visible percentage label, right-aligned inside the fill
LayrzProgressBar(value: 0.68, showLabel: true)

// Percentage label with 1 decimal place
LayrzProgressBar(value: 0.683, showLabel: true, decimals: 1)

// Custom height and border radius (linear only)
LayrzProgressBar(value: 0.3, height: 10, borderRadius: 4)

// Custom size and stroke width (circular only)
LayrzProgressBar(format: .circular, value: 0.6, size: 80, strokeWidth: 6)
```

---

## Constructor

```dart
const LayrzProgressBar({
  super.key,
  this.value,
  this.format = LayrzProgressFormat.linear,
  this.type = LayrzProgressType.info,
  this.color,
  this.height = kLayrzProgressBarHeight,
  this.borderRadius,
  this.size = kLayrzProgressCircularSize,
  this.strokeWidth = kLayrzProgressCircularStrokeWidth,
  this.semanticLabel,
  this.showLabel = false,
  this.decimals = 0,
}) : assert(
       value == null || (value >= 0.0 && value <= 1.0),
       'value must be null (indeterminate) or within [0.0, 1.0].',
     ),
     assert(decimals >= 0, 'decimals must be zero or a positive integer.');
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `value` | `double?` | `null` | Determinate fraction in `[0.0, 1.0]`. `null` selects indeterminate mode. Asserted null or in-range. |
| `format` | `LayrzProgressFormat` | `.linear` | Rendering shape — linear bar or circular ring. |
| `type` | `LayrzProgressType` | `.info` | Semantic accent color of the indicator fill. |
| `color` | `Color?` | `null` | Explicit indicator color, honored only when `type` is `.custom`. Falls back to `tokens.colors.primary` if unset while `type` is custom. |
| `height` | `double` | `kLayrzProgressBarHeight` (`16.0`) | Bar height in logical pixels. **Linear only** — ignored for `.circular`. |
| `borderRadius` | `double?` | `null` → `tokens.radius.r1` (`6.0`) | Border radius for track and indicator. **Linear only** — ignored for `.circular` (always a full ring). |
| `size` | `double` | `kLayrzProgressCircularSize` (`50.0`) | Diagonal size (width/height) of the ring. **Circular only** — ignored for `.linear`. |
| `strokeWidth` | `double` | `kLayrzProgressCircularStrokeWidth` (`4.0`) | Ring stroke thickness. **Circular only** — ignored for `.linear`. |
| `semanticLabel` | `String?` | `null` | Accessibility description of what this bar represents (e.g. `'Upload progress'`). Falls back to a generic `'Progress'`/`'Loading'` when null. |
| `showLabel` | `bool` | `false` | Paints the value as a percentage label. **Linear, determinate mode only** — ignored (no label) for circular format or indeterminate mode. |
| `decimals` | `int` | `0` | Decimal places in the value label and the `Semantics.value` announcement. Asserted ≥ 0. |

Setting a parameter that does not apply to the current `format` is harmless — it is ignored rather than asserted against, since a caller flipping `format` at runtime should not need to strip out the now-unused parameter.

---

## `LayrzProgressFormat` enum

| Value | Description |
|---|---|
| `.linear` | Horizontal bar, filling from the leading edge (determinate) or sweeping back and forth (indeterminate). Sized by `height`/`borderRadius`. |
| `.circular` | Ring, filling clockwise from 12 o'clock (determinate) or rotating continuously (indeterminate). Sized by `size`/`strokeWidth`. |

Deliberately a separate enum from `LayrzProgressType` — `format` selects shape, `type` selects color; every combination of the two is valid.

---

## `LayrzProgressType` enum

Mirrors `LayrzChipType`'s vocabulary.

| Value | Resolved color | Notes |
|---|---|---|
| `.info` | `tokens.colors.info` | Neutral progress. |
| `.success` | `tokens.colors.success` | Positive progress. |
| `.warning` | `tokens.colors.warning` | Cautionary progress. |
| `.danger` | `tokens.colors.danger` | Destructive/critical progress. |
| `.context` | `tokens.colors.contextual` | Context-dependent progress. |
| `.custom` | `color` constructor parameter | Requires an explicit `color`; falls back to `tokens.colors.primary` if `color` is also null. |

---

## Companion widgets

- **`LayrzLabeledProgressBar`** (`lib/src/progress/src/progress_labeled_bar.dart`) — the `StatelessWidget` that stacks a painted bar with the value-percentage label on top via a `Stack`. `LayrzProgressBar.showLabel` delegates to this internally; ordinary callers should use `showLabel` rather than constructing this directly.
- **`LayrzProgressLabelPainter`** (`lib/src/progress/src/progress_label_painter.dart`) — the `CustomPainter` backing the value label. Exported independently for callers composing the label directly.
- **`LayrzProgressPainter`** (`lib/src/progress/src/progress_painter.dart`) — the `CustomPainter` backing both linear and circular, determinate and indeterminate painting. Exported independently, though ordinary use goes through `LayrzProgressBar`.
- **`LayrzProgressStyleSpec`** (`lib/src/progress/src/progress_style_spec.dart`) — an immutable, paint-only spec (`trackColor`, `indicatorColor`) resolved once per build via `LayrzProgressStyleSpec.resolve(type:, color:, tokens:)`.
- **`formatLayrzProgressValue`** (top-level function, `lib/src/progress/src/progress_value_format.dart`) — formats a determinate `value` at `decimals` precision, backing both the visible label and the `Semantics.value` announcement identically.

---

## Behavior notes

- **Rounding never claims a state the value hasn't reached.** `value == 0.0` exactly always formats as `'0%'`; any `value > 0.0` never formats as all-zero digits (floors up to the smallest positive step, e.g. `'1%'` at `decimals: 0`). `value == 1.0` exactly always formats as `'100%'`; any `value < 1.0` never rounds up to `'100%'` (ceils down to the largest sub-100 value, e.g. `'99%'` at `decimals: 0`). Every other value formats exactly as `toStringAsFixed` produces it.
- **Label placement.** Right-aligned inside the filled (indicator) portion by default, inset by `tokens.spacing.sp1` from the fill boundary. When the fill is too narrow to hold the measured label text, it flips to just outside the bar — onto the track — inset from the fill boundary by the same padding. Colour always matches whichever region the label sits on, derived via `Color.contrastColor` at paint time (never hardcoded).
- **Reduced motion.** `MediaQuery.disableAnimationsOf` freezes the indeterminate sweep/rotation at its start position instead of looping; the underlying `AnimationController` is torn down entirely (not merely left unstarted) and recreated when motion resumes.
- **Circular repaint isolation.** The circular format wraps its painted arc in a `RepaintBoundary` — an indeterminate ring repaints every frame, and isolating it keeps that invalidation from forcing a sibling widget's layer to redraw too. The linear format does not get this treatment, since its rounded-rect fills alias far less noticeably.
- **No circular-mode label.** `showLabel` is ignored entirely in `.circular` format — there is no straight run of pixels to place text along relative to a fill boundary.
