# LayrzSelectionHandlePainter — API Reference

Source: `lib/src/selection/src/selection_handle_painter.dart`
- `LayrzSelectionHandlePainter` class (`extends CustomPainter`)

---

## Examples

```dart
// The exact usage LayrzTextSelectionControls.buildHandle composes internally
CustomPaint(
  size: const Size(22.0, 22.0),
  painter: LayrzSelectionHandlePainter(
    color: tokens.colors.primary,
  ),
)

// Rotated externally to orient the teardrop's corner
Transform.rotate(
  angle: math.pi / 2.0, // 90° clockwise → corner points NE
  child: CustomPaint(
    size: const Size(22.0, 22.0),
    painter: LayrzSelectionHandlePainter(color: tokens.colors.primary),
  ),
)
```

---

## Constructor

```dart
const LayrzSelectionHandlePainter({
  required this.color,
});
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `color` | `Color` | **required** | The fill color of the handle. Typically `tokens.colors.primary`. |

---

## Overrides

| Member | Signature | Notes |
|---|---|---|
| `paint` | `void paint(Canvas canvas, Size size)` | Draws the teardrop: a circle (`Rect.fromCircle`, radius `size.width / 2`) plus a square corner (`Rect.fromLTWH(0, 0, radius, radius)`) combined into one `Path`, filled with `color`. |
| `shouldRepaint` | `bool shouldRepaint(LayrzSelectionHandlePainter oldDelegate)` | `true` only when `oldDelegate.color != color`. |

---

## Teardrop geometry

- **Circle**: centered at `(radius, radius)`, radius `= size.width / 2` — so for the standard `22×22` size, centered at `(11, 11)` with radius `11`.
- **Square corner**: `Rect.fromLTWH(0, 0, radius, radius)` — the top-left quadrant of the bounding box.
- **Combination**: `Path()..addOval(circle)..addRect(point)`, filled as one path — producing a circular bulge with a pointed corner sticking out at the top-left (NW), unrotated.

## Rotation (applied externally, by the caller)

| Handle type | Rotation | Corner points | Usage |
|---|---|---|---|
| left | 90° clockwise (`π/2`) | NE (up-right) | Selection-start handle |
| right | 0° (none) | NW (up-left) | Selection-end handle |
| collapsed | 45° clockwise (`π/4`) | N (up) | Caret position |

`Transform.rotate` uses clockwise rotation for positive angles in Flutter. This is applied by `LayrzTextSelectionControls.buildHandle`, not by this painter itself — the painter only ever draws the unrotated, NW-cornered base shape.

---

## Behavior notes

- **No decoration beyond fill.** No stroke, border, shadow, or gradient — purely a solid-filled path.
- **Winding rule.** `addOval` + `addRect` on the same `Path` use the default even-odd winding rule, which is what produces the teardrop (rather than, say, a circle with a square hole).
- **Performance.** Lightweight — one path construction and fill per paint call, with no per-frame recomputation beyond that; `shouldRepaint` gates unnecessary repaints on color equality alone.
- **Not directly instantiated in normal use.** Created internally by `LayrzTextSelectionControls.buildHandle` (see the `layrz-ui-text-selection-controls` skill) for each handle it renders.
