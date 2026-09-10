# LayrzCard — API Reference

Source: `lib/src/cards/src/card.dart`
- `LayrzCard` class — line 35

---

## Examples

```dart
// Basic non-interactive card
LayrzCard(
  elevation: 1,
  child: Padding(
    padding: const EdgeInsets.all(4),
    child: Text('Card content'),
  ),
)

// Interactive card with custom background
LayrzCard(
  elevation: 2,
  backgroundColor: context.tokens.colors.sf2,
  onTap: () => Navigator.of(context).push(...),
  child: Column(
    children: [
      Text('Tap me'),
      const SizedBox(height: 8),
      Text('Navigate on tap'),
    ],
  ),
)

// Higher elevation, e.g. inside a dialog
LayrzCard(
  elevation: 4,
  onTap: () => selectItem(),
  child: myListRow,
)
```

---

## Constructor

```dart
const LayrzCard({
  super.key,
  required this.child,
  this.elevation = 1,
  this.backgroundColor,
  this.onTap,
}) : assert(
       elevation >= 1 && elevation <= 5,
       'elevation must be between 1 and 5, got $elevation',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `child` | `Widget` | — | **Required.** The content displayed inside the card. |
| `elevation` | `int` | `1` | Discrete shadow level, 1–5 inclusive. Asserted at construction. Higher values produce a larger drop shadow. |
| `backgroundColor` | `Color?` | `null` | Background fill. When null, resolves to the design system's surface token (the page canvas background). When provided, overrides the token entirely. |
| `onTap` | `VoidCallback?` | `null` | Tap handler. `null` (default) makes the card fully inert; non-null makes it interactive with hover/press/focus shadow feedback and keyboard activation. |

---

## Behavior notes

- **Interaction state model** (`onTap` non-null): hover or focus steps the shadow **up** one elevation level, clamped at 5; a press steps it **down** one level, clamped at 1 (press takes precedence over hover in source, so a hover-then-press sequence settles at `elevation - 1`, not back at the base level). All transitions animate via `AnimatedContainer` using `tokens.motion.dHover` duration and `tokens.motion.easing` curve.
- **Padding and radius are fixed, not parameters**: `tokens.spacing.sp3` (16lp) padding, `tokens.radius.r3` (16lp) corner radius. Geometry never varies with `elevation`, `backgroundColor`, or interaction state.
- **No outer margin by design**: per the design system's spacing model, inter-card spacing is owned by `LayrzRow`/`LayrzConstrainedView`'s `spacing` parameter rather than by a card-level margin, which would double-count spacing when cards are placed inside those containers.
- **Accessibility**: non-interactive cards (`onTap: null`) attach no `Semantics` node of their own — they're opaque containers. Interactive cards are wrapped in `Semantics(button: true, enabled: true)`, Tab-focusable, and activatable via Enter/Space (`ActivateIntent` bound to `widget.onTap!()`).
- **Cursor**: interactive cards set `SystemMouseCursors.click` on hover via `MouseRegion`.
