# LayrzSlider — API Reference

Source: `lib/src/inputs/src/slider/slider_input.dart` (+ `slider_style.dart`, `slider_geometry.dart`, `slider_painter.dart`)
- `LayrzSlider` class — line 90
- `LayrzSliderColors` class — `slider_style.dart`, line 15 (colour-resolution data holder, not part of the public widget API)

---

## Examples

```dart
// Continuous slider
LayrzSlider(
  labelText: 'Volume',
  value: volume,
  onChanged: (value) => setState(() => volume = value),
)

// Quantised (stepped) slider
LayrzSlider(
  labelText: 'Rating',
  value: rating,
  min: 0,
  max: 100,
  divisions: 4,
  onChanged: (value) => setState(() => rating = value),
)

// Custom range
LayrzSlider(
  labelText: 'Temperature (°C)',
  value: temperature,
  min: -20,
  max: 50,
  onChanged: (value) => setState(() => temperature = value),
)

// Custom value formatter
LayrzSlider(
  labelText: 'Opacity',
  value: opacity,
  min: 0,
  max: 1,
  valueFormatter: (v) => '${(v * 100).round()}%',
  onChanged: (value) => setState(() => opacity = value),
)

// Disabled
LayrzSlider(
  labelText: 'Locked value',
  value: 40,
  disabled: true,
)

// With errors
LayrzSlider(
  labelText: 'Budget allocation',
  value: allocation,
  errors: const ['Must be at least 10%'],
  onChanged: (value) => setState(() => allocation = value),
)

// Autofocus, value label hidden
LayrzSlider(
  labelText: 'Zoom',
  value: zoom,
  autofocus: true,
  showValueLabel: false,
  onChanged: (value) => setState(() => zoom = value),
)
```

---

## Constructor

```dart
const LayrzSlider({
  super.key,
  this.labelText,
  required this.value,
  this.min = 0.0,
  this.max = 100.0,
  this.divisions,
  this.onChanged,
  this.showValueLabel = true,
  this.valueFormatter,
  this.focusNode,
  this.errors = const [],
  this.hideDetails = false,
  this.disabled = false,
  this.autofocus = false,
});
```

No asserts — every combination of parameters is valid (`value` is clamped internally regardless of whether it starts in-range).

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String?` | `null` | Rendered above the track. `null` renders no label row. |
| `value` | `double` | **required** | Always treated as clamped to `[min, max]` and, when `divisions` is set, quantised to the nearest step. |
| `min` | `double` | `0.0` | Must be `≤ max`. Equal to `max` produces a degenerate single-point slider. |
| `max` | `double` | `100.0` | Must be `≥ min`. |
| `divisions` | `int?` | `null` | `2+` snaps to that many equal steps. `null`/`0`/`1` all mean "continuous". |
| `onChanged` | `ValueChanged<double>?` | `null` | Fires continuously during a drag (not only on release) with the already clamped+quantised value. `null` disables the control. |
| `showValueLabel` | `bool` | `true` | Shows the current value as a label above the track. Required affordance since the thumb never resizes (D15) — suppress only when the value is shown elsewhere. |
| `valueFormatter` | `String Function(double value)?` | `null` | Formats the value label and semantics announcement. Default: whole numbers with no decimal, otherwise up to 2 decimal places. |
| `focusNode` | `FocusNode?` | `null` | Internal one created/disposed when omitted. Caller-supplied nodes are never disposed. |
| `errors` | `List<String>` | `[]` | Rendered below the control via the shared footer slot. |
| `hideDetails` | `bool` | `false` | Hides the error message block. |
| `disabled` | `bool` | `false` | Disables the control independently of whether `onChanged` is set. |
| `autofocus` | `bool` | `false` | Requests focus on insertion if nothing else is focused. Forwarded directly to the internal `Focus` widget. |

---

## Behavior notes

- **No `LayrzInputChrome` composition (D63)**: a slider is "a control with a label, not a bordered field" — same excluded category as checkbox/switch/radio. It has no border, no prefix/suffix slots, no dialog.
- **`divisions` quantisation**: `min: 0, max: 100, divisions: 4` produces five reachable values (`0, 25, 50, 75, 100`), one step apart. A drag landing at `62` snaps to `50`.
- **Keyboard step size**: `(max - min) / divisions` when `divisions ≥ 2`, else `(max - min) / 100` (roughly 100 steps across a continuous range). Left/Down decrease, Right/Up increase, Home → `min`, End → `max`. All suppressed when disabled.
- **Live value feedback (core, not decorative)**: per D15, the thumb never changes size on hover/press/focus. The static value label above the track (not overlapping/below, so a dragging finger doesn't cover it) updates on every drag delta. A `LayrzSliderValueBubble` additionally floats above the thumb only while dragging — it supplements, never replaces, the static label; wrapped in `ExcludeSemantics` since the value is already announced via `Semantics.value`.
- **Hit-slop**: the invisible gesture region is 44px tall; the painted track+thumb occupy 36px (28px thumb on an 8px track). The extra hit area is invisible and constant across states, which is compatible with D15 (that rule forbids *visual* geometry changes, not an oversized invisible hit target).
- **Colour/elevation precedence**: disabled > error > pressed (including an active drag) > hover/focused > default — identical ordering to `LayrzCheckboxInput`/`LayrzSwitchInput`. Elevation: disabled = 0 (flush), error = 1 (base, same as default — an error is a colour concern), pressed/dragging or hovered/focus-visible = 2, default = 1.
- **Thumb shape**: a 28px rounded square (`tokens.radius.r2` corners, 2px border) — not a circular disc. Track is 8px thick.
- **Accessibility**: `Semantics(slider: true)` with `value`, `increasedValue`/`decreasedValue` (one step away, clamped), and `onIncrease`/`onDecrease` actions wired to the same step logic as the arrow keys — fully operable via screen reader with no pointer.
- **v1 scope limits**: single value only (no dual-thumb range variant — a future `LayrzRangeSlider` is the intended home for that); no tick marks along the track even when `divisions` is set.
- **Disposal contract**: when `focusNode` is `null`, an internal `FocusNode` is created in `initState` and disposed in `dispose`; a caller-supplied node is never disposed by this widget.
