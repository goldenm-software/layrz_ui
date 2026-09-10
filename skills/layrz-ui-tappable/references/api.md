# LayrzTappable — API Reference

Source: `lib/src/tappable/src/tappable.dart`
- `LayrzTappable` class — line 107

---

## Examples

```dart
// Basic tappable card row
LayrzTappable(
  onTap: onOpen,
  borderRadius: BorderRadius.circular(context.tokens.radius.r2),
  child: Padding(
    padding: EdgeInsets.all(context.tokens.spacing.sp3),
    child: Text(title),
  ),
)

// Transparent idle with hue-matched hover (avoids the black-blink artifact)
LayrzTappable(
  color: context.tokens.colors.sf3.withValues(alpha: 0),
  hoverColor: context.tokens.colors.sf3,
  onTap: onSelect,
  child: content,
)

// Explicit hover/pressed color overrides
LayrzTappable(
  hoverColor: context.tokens.colors.primary.withValues(alpha: 0.08),
  pressedColor: context.tokens.colors.primary.withValues(alpha: 0.16),
  onTap: onSelect,
  child: content,
)

// Long-press and secondary-tap (context menu triggers)
LayrzTappable(
  onTap: onOpen,
  onLongPress: onShowMenu,
  onSecondaryTap: onShowMenu,
  child: content,
)

// Disabled row
LayrzTappable(
  disabled: true,
  onTap: onSelect,
  child: content,
)

// Re-tappable target — double-tap must not collapse to a single call
LayrzTappable(
  collapseDoubleTap: false,
  onTap: () => pickUpEndpoint(date),
  child: dayCell,
)

// Inert wrapper (no callbacks) — still paints idle/disabled surface, no gestures wired
LayrzTappable(
  child: content,
)
```

---

## Constructor

```dart
const LayrzTappable({
  super.key,
  required this.child,
  this.onTap,
  this.onLongPress,
  this.onSecondaryTap,
  this.disabled = false,
  this.borderRadius,
  this.color,
  this.hoverColor,
  this.pressedColor,
  this.collapseDoubleTap = true,
});
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `child` | `Widget` | **required** | The widget to wrap. |
| `onTap` | `VoidCallback?` | `null` | `null` makes the widget inert (no cursor change, no hover/press feedback, no gesture wired). Not wired at all when `disabled` is true. Subject to `collapseDoubleTap` deduplication. |
| `onLongPress` | `VoidCallback?` | `null` | Ignored when `disabled` is true. |
| `onSecondaryTap` | `VoidCallback?` | `null` | Right-click / secondary-tap. Ignored when `disabled` is true. |
| `disabled` | `bool` | `false` | Disables all three gesture callbacks and paints the disabled tint (`fg3` at 12% alpha), regardless of which callbacks are non-null. |
| `borderRadius` | `BorderRadius?` | `null` (→ `BorderRadius.zero`) | Applied to the painted surface. Should match the child's own shape. |
| `color` | `Color?` | `null` (→ `tokens.colors.sf1`) | Idle surface color. The default is **opaque**, not transparent — pass an explicit transparent color to opt out. |
| `hoverColor` | `Color?` | `null` (→ `tokens.colors.sf3`) | Surface color while hovered (desktop/mouse only). |
| `pressedColor` | `Color?` | `null` (→ `tokens.colors.sf4`) | Surface color while the pointer is down within the widget. |
| `collapseDoubleTap` | `bool` | `true` | When `true`, a double-tap within `kDoubleTapTimeout` invokes `onTap` once via a post-resolution cooldown Timer (not a `DoubleTapGestureRecognizer`, to avoid adding latency to every single tap). Set `false` when a second tap on the same target must fire its own `onTap` call. |

---

## Behavior notes

- **State precedence for surface color:** disabled > pressed > hovered > idle. Only one tint paints at a time; there is no compositing between states.
- **Two build paths:** when `disabled` is true, or when all three of `onTap`/`onLongPress`/`onSecondaryTap` are null, the widget renders a plain `DecoratedBox` with no `MouseRegion`/`GestureDetector`/`Listener` at all — genuinely zero gesture overhead, not just disabled handlers. Otherwise it renders the full interactive stack (`MouseRegion` → `Listener` → `GestureDetector` → `AnimatedContainer`).
- **Cursor:** `SystemMouseCursors.click` when at least one gesture is wired and not disabled; `SystemMouseCursors.basic` otherwise.
- **Double-tap cooldown mechanism:** implemented as a `Timer(kDoubleTapTimeout, ...)` armed after each `onTap` invocation, not a second Flutter gesture recognizer — chosen deliberately to keep single-tap latency near 0ms (a `DoubleTapGestureRecognizer` or `SerialTapGestureRecognizer` would either add up to `kDoubleTapTimeout` latency to every tap or leave an uncancellable pending `Timer` that breaks widget-test teardown). A second tap while the cooldown `Timer` is still pending is silently swallowed.
- **No focus ownership:** no `FocusNode`, `Focus`, or keyboard activation path exists on this widget. Composing keyboard accessibility is the caller's responsibility.
- **`didUpdateWidget` resets transient state:** if the widget transitions to `disabled` or to having no gesture callbacks at all, any in-flight hover/press visual state is cleared on the next post-frame callback — it won't get stuck visually "hovered" after becoming inert.
- **Motion:** surface color transitions use `tokens.motion.dHover` duration and `tokens.motion.easing` curve via `AnimatedContainer`, consistent with the rest of the design system's hover timing.
