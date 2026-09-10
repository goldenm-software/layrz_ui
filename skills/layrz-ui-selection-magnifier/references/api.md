# LayrzSelectionMagnifier — API Reference

Source: `lib/src/selection/src/selection_magnifier.dart`
- `LayrzSelectionMagnifier` class (`StatelessWidget`) — the widget itself renders nothing (`SizedBox.shrink()`); the real API is its static method
- `_LayrzMagnifierWidget` (private) — the actual magnifier lens widget, built internally by the configuration's `magnifierBuilder`

---

## Examples

```dart
// Standard integration — pass straight to magnifierConfiguration
EditableText(
  controller: controller,
  focusNode: focusNode,
  style: style,
  selectionControls: LayrzTextSelectionControls.instance,
  magnifierConfiguration: LayrzSelectionMagnifier.magnifierConfigurationFor(),
)

// No magnification (lens shows actual size)
LayrzSelectionMagnifier.magnifierConfigurationFor(scale: 1.0);

// Stronger magnification for accessibility
LayrzSelectionMagnifier.magnifierConfigurationFor(scale: 1.5);
```

---

## Constructor

```dart
const LayrzSelectionMagnifier({
  super.key,
  this.scale = 1.25,
});
```

| Property | Type | Default | Notes |
|---|---|---|---|
| `scale` | `double` | `1.25` | Magnification factor. `1.0` = actual size, `1.25` = 25% larger (default), `1.5` = 50% larger, `2.0` = 100% larger. |

`build(BuildContext)` returns `const SizedBox.shrink()` — this widget itself is never meaningfully rendered in a tree; it exists as a namespace holder for `magnifierConfigurationFor`.

---

## Static members

| Member | Signature | Notes |
|---|---|---|
| `magnifierConfigurationFor` | `static TextMagnifierConfiguration? magnifierConfigurationFor({double scale = 1.25})` | **The actual entry point.** Returns a configuration wiring the magnifier into `EditableText.magnifierConfiguration`, or `null` on non-touch platforms. |

```dart
static TextMagnifierConfiguration? magnifierConfigurationFor({double scale = 1.25}) {
  if (!LayrzPlatform.isTouchOS) return null;
  return TextMagnifierConfiguration(
    magnifierBuilder: (context, controller, info) =>
        _LayrzMagnifierWidget(scale: scale, magnifierInfo: info),
  );
}
```

---

## Platform gating

Gated on `LayrzPlatform.isTouchOS` — **deliberately not `LayrzPlatform.isMobile`**:

| Getter | Behavior |
|---|---|
| `LayrzPlatform.isTouchOS` | `true` for Android/iOS, whether running natively **or in a mobile browser**. |
| `LayrzPlatform.isMobile` | Routes through `LayrzPlatform.current`, which short-circuits on `kIsWeb` — would incorrectly report `false` for Android/iOS in a mobile browser. |

Using `isMobile` for this gate would strip the magnifier from exactly the platforms it's required to support (mobile web) — this was a deliberate platform-detection decision (DESIGN-147), not an oversight.

| Platform | Magnifier shown? |
|---|---|
| Android/iOS, native | Yes |
| Android/iOS, mobile web | Yes |
| Windows/macOS/Linux, native or desktop web | No — `magnifierConfigurationFor` returns `null` |

---

## Visual properties

| Property | Value |
|---|---|
| Lens size | 77.37 × 37.9 logical pixels — Material's own standard magnifier dimensions, not configurable |
| Position | Horizontally at the user's finger (clamped to current line boundaries); vertically above the current text line |
| Shape | Rounded rectangle |
| Elevation | Positioned above all other content via an overlay |

---

## Behavior notes

- **Positioning algorithm.** Horizontal position is the finger's x-coordinate clamped to the current line's bounds; vertical position sits above the caret with a fixed offset (`kStandardVerticalFocalPointShift = 22.0`) to avoid obscuring the finger; the focal point (what part of the text is magnified) is computed so the text under the finger appears centered in the lens, then clamped to screen bounds via `MagnifierController.shiftWithinBounds`.
- **Real-time updates.** The internal `_LayrzMagnifierWidget` listens to `MagnifierInfo` via `ValueListenableBuilder`, recomputing position and focal point on every drag update.
- **Dismissal.** Shown only during long-press+drag selection; dismissed when the drag ends, selection is cleared, or the user taps elsewhere — this is `EditableText`'s own magnifier lifecycle, not something this class manages.
- **Accessibility.** Visually present but not exposed as a separate interactive element to screen readers — it is a visual aid, not a control.
