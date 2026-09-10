---
name: layrz-ui-progress-bar
description: Use LayrzProgressBar in a layrz_ui Flutter widget. Apply when rendering a determinate or indeterminate progress indicator — linear bar or circular ring format, semantic color types, an optional value percentage label, or the LayrzLabeledProgressBar companion.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.linear`, `.circular`, `.success`) — never the fully-qualified form (`LayrzProgressFormat.linear`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any progress affordance: file upload/download, sync status, multi-step operation progress, a loading spinner of unknown duration.
- Use `format: .linear` (default) for a horizontal track — the common case for inline progress under a form or list item.
- Use `format: .circular` for a compact ring — dashboards, cards, or anywhere a linear bar would be too wide.
- Pass `value` (a `double` in `[0.0, 1.0]`) for determinate progress; leave `value: null` (the default) for indeterminate — an infinite sweep/rotation with no known completion point.
- Set `showLabel: true` to paint the current value as a percentage inside the bar. Linear + determinate only — ignored for circular format or indeterminate mode.
- **Do not use** for a draggable value selector — use `LayrzSlider` instead.
- **Do not use** for a step-by-step wizard indicator — this widget has no circular *stepper* semantics and no active/completed vocabulary; compose your own step indicator instead.

---

## Minimal usage

```dart
// Determinate — upload progress
LayrzProgressBar(value: 0.42, semanticLabel: 'Upload progress')

// Indeterminate — unknown-duration operation
LayrzProgressBar(semanticLabel: 'Loading')
```

---

## Key behaviors

- **`null` always means indeterminate, never zero progress.** A caller wanting to show "no progress yet" must pass `0.0` explicitly.
- **Determinate direction is the opposite of `LayrzButtonIndicator`.** This bar *fills* from empty to full as `value` rises (linear) or sweeps clockwise from 12 o'clock (circular) — `LayrzButtonIndicator`'s countdown depletes instead. This is a deliberate divergence.
- `format` selects shape; `type` selects semantic color. The two are independent axes — every combination is valid.
- `height`/`borderRadius` apply only to `.linear`; `size`/`strokeWidth` apply only to `.circular`. Setting the wrong one for the current `format` is harmless — it is simply ignored, not asserted against.
- `showLabel` is right-aligned inside the filled region by default; when the fill is too narrow to hold the label, it automatically flips to just outside the bar, onto the track. The label's contrast color always matches whichever region it lands on.
- `decimals` (default `0`) never lets a genuinely-started value read as `'0%'`, nor a sub-1.0 value read as `'100%'` — see `formatLayrzProgressValue`'s rounding rule in the reference.
- The percentage/busy state is always announced via `Semantics.value`/`Semantics.label`, regardless of `showLabel` — turning the visible label off never removes the accessible announcement.
- Reduced motion (`MediaQuery.disableAnimationsOf`) freezes the indeterminate sweep/rotation at its start position instead of looping.
- This widget is **display-only** — it is not interactive/draggable.

---

## Format vs type — two independent axes

| Axis | Enum | Controls |
|---|---|---|
| Shape | `LayrzProgressFormat` (`.linear` / `.circular`) | Which geometry is painted, and which sizing parameters apply. |
| Color | `LayrzProgressType` (`.info` / `.success` / `.warning` / `.danger` / `.context` / `.custom`) | The semantic accent color of the indicator fill, mirroring `LayrzChipType`. |

---

## Common patterns

```dart
// Circular ring, determinate, custom color
LayrzProgressBar(
  format: .circular,
  value: 0.75,
  type: .custom,
  color: const Color(0xFF6A0DAD),
  semanticLabel: 'Sync progress',
)

// Linear bar with a visible percentage label
LayrzProgressBar(
  value: 0.68,
  showLabel: true,
  decimals: 1,
)

// Danger-colored determinate bar for a critical operation
LayrzProgressBar(
  value: quotaUsed,
  type: .danger,
  semanticLabel: 'Storage quota used',
)

// Indeterminate circular spinner
LayrzProgressBar(format: .circular, semanticLabel: 'Loading')
```

---

## Usage conventions

- Always pass `semanticLabel` describing what the progress represents (e.g. `'Upload progress'`) — omitting it falls back to a generic `'Progress'`/`'Loading'` announcement that is less useful to screen reader users.
- Prefer the determinate mode whenever real progress is known; reserve indeterminate for operations with no measurable completion point.
- Do not hardcode a `color` unless `type` is `.custom` — every other `type` resolves its own token color, and passing `color` alongside a non-custom `type` is simply ignored.
- Keep `showLabel` off for bars embedded in tight layouts (e.g. table cells) where the flip-to-track fallback has no room to render legibly.
- Separate a `LayrzProgressBar` from surrounding content with `SizedBox(height: 10)` or the equivalent spacing token.
