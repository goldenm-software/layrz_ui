---
name: layrz-ui-slider
description: Use LayrzSlider in a layrz_ui Flutter widget. Apply when picking a numeric value from a continuous or quantised range by dragging, tapping, or the keyboard — divisions for stepped snapping, a live value label, and a drag value bubble.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Picking a numeric value from a range by drag/tap/keyboard: volume, brightness, a percentage, a rating out of N.
- Use `divisions` (2 or more) to snap to discrete steps (e.g. a 0/25/50/75/100 rating); omit it for a continuous range.
- **`LayrzSlider` does not compose `LayrzInputChrome`** — it is a bare control with a label, not a bordered field, the same category as `LayrzCheckboxInput`/`LayrzSwitchInput`/`LayrzRadioInput`. Do not expect prefix/suffix slots, a border, or dialogs.
- **Do not use** for a precise numeric entry where the exact value matters more than the gesture — use `LayrzNumberInput` instead.
- **Do not use** for a two-ended range (min AND max) — there is no dual-thumb variant in v1; this is single-value only.

---

## Minimal usage

```dart
LayrzSlider(
  labelText: 'Volume',
  value: volume,
  onChanged: (value) {
    setState(() => volume = value);
  },
)
```

---

## Key behaviors

- `value` is `double`, always clamped to `[min, max]` and, when `divisions` is set, quantised to the nearest step before being painted, announced, or handed to `onChanged`.
- `onChanged: null` disables the control independently of the `disabled` flag — either makes it inert.
- `divisions` of `null`, `0`, or `1` all mean "no quantisation" (continuous, clamped only). `divisions: 2+` snaps to that many equal steps.
- The thumb **never changes size** on hover/press/focus (design invariant D15) — only colour, border colour, and shadow vary. A live value label above the track (default visible, `showValueLabel`) is the required feedback mechanism instead.
- While dragging, a small value bubble additionally appears above the thumb — it supplements, never replaces, the static label (the static label stays visible even if a fingertip covers the thumb/bubble).
- Keyboard (once focused): Left/Down decrease one step, Right/Up increase one step, Home jumps to `min`, End jumps to `max`. Step size is `(max - min) / divisions` when set, else 1% of the range.

---

## Common patterns

```dart
// 1. Quantised (stepped) slider
LayrzSlider(
  labelText: 'Rating',
  value: rating,
  min: 0,
  max: 100,
  divisions: 4, // 0, 25, 50, 75, 100
  onChanged: (value) => setState(() => rating = value),
)

// 2. Custom value formatting
LayrzSlider(
  labelText: 'Brightness',
  value: brightness,
  valueFormatter: (v) => '${v.round()}%',
  onChanged: (value) => setState(() => brightness = value),
)

// 3. Disabled
LayrzSlider(
  labelText: 'Locked value',
  value: 40,
  disabled: true,
)

// 4. With validation error
LayrzSlider(
  labelText: 'Budget allocation',
  value: allocation,
  errors: const ['Must be at least 10%'],
  onChanged: (value) => setState(() => allocation = value),
)

// 5. Hide the value label (value shown elsewhere in the UI)
LayrzSlider(
  labelText: 'Zoom',
  value: zoom,
  showValueLabel: false,
  onChanged: (value) => setState(() => zoom = value),
)
```

---

## Form conventions

- Use `LayrzUiL10n.of(context)` for `labelText` — never hardcode strings.
- Pass `errors: [...]` for validation state — never `context.getErrors`.
- Keep `showValueLabel` at its default (`true`) unless the value is genuinely shown elsewhere nearby — the fixed-size thumb (D15) gives no other confirmation that a drag registered.
- Separate stacked sliders with `SizedBox(height: 10)`.
