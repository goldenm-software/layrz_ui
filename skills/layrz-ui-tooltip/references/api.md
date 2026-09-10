# LayrzTooltip — API Reference

Source: `lib/src/tooltips/src/tooltip.dart`
- `LayrzTooltip` class — line 57
- `LayrzTooltipTrigger` enum — `lib/src/tooltips/src/tooltip_trigger.dart`
- `LayrzPreferredSide` enum — `lib/src/positioning/src/preferred_side.dart` (re-exported from the `tooltips` barrel via `tooltip_position.dart`, which also defines the position-delegate algorithm)

---

## Examples

```dart
// Plain-text tooltip
LayrzTooltip(
  contentText: 'Save your work',
  child: LayrzButton.save(labelText: 'Save', onTap: save),
)

// Rich-text tooltip with mixed styles
LayrzTooltip(
  contentRichText: TextSpan(
    text: 'Click to view ',
    children: [
      TextSpan(text: 'details', style: TextStyle(fontWeight: FontWeight.bold)),
    ],
  ),
  child: Container(width: 100, height: 40, child: Text('Info')),
)

// Title + content
LayrzTooltip(
  titleText: 'Shortcut',
  contentText: 'Press Ctrl+S to save',
  child: Icon(MdiIcons.contentSave),
)

// Positioned above the anchor
LayrzTooltip(
  position: .top,
  contentText: 'More information',
  child: Icon(MdiIcons.informationBoxOutline),
)

// Positioned to the right
LayrzTooltip(
  position: .right,
  contentText: 'Tooltip on the right',
  child: Container(width: 80, height: 80),
)

// Tap-to-toggle trigger mode
LayrzTooltip(
  trigger: .tap,
  contentText: 'Tap again to dismiss',
  child: Icon(MdiIcons.helpCircleOutline),
)
```

---

## Constructor

```dart
const LayrzTooltip({
  super.key,
  required this.child,
  this.titleText,
  this.contentText,
  this.contentRichText,
  this.position = LayrzPreferredSide.bottom,
  this.trigger = LayrzTooltipTrigger.pointer,
}) : assert(
       (contentText == null) != (contentRichText == null),
       'Provide exactly one of contentText or contentRichText.',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `child` | `Widget` | — | **Required.** The widget wrapped with the tooltip. Its size, position, and hit-testing are unaffected. |
| `titleText` | `String?` | `null` | Optional title rendered above `contentText`/`contentRichText` in `tokens.typography.body` (heavier than the content's `label` style). |
| `contentText` | `String?` | `null` | Plain-text content. Mutually exclusive with `contentRichText` — exactly one must be non-null. |
| `contentRichText` | `TextSpan?` | `null` | Rich-text content with optional per-span style overrides. Mutually exclusive with `contentText`. |
| `position` | `LayrzPreferredSide` | `.bottom` | Preferred side relative to the anchor. Flips to the opposite side automatically if it would overflow the viewport. |
| `trigger` | `LayrzTooltipTrigger` | `.pointer` | Trigger mode for showing/dismissing — see enum table below. |

---

## `LayrzPreferredSide` enum

| Value | Position |
|---|---|
| `.top` | Above the anchor. |
| `.bottom` | Below the anchor. **Default.** |
| `.left` | To the left of the anchor. |
| `.right` | To the right of the anchor. |

**Automatic flipping**: if the tooltip would overflow the overlay bounds on the preferred side, it flips to the opposite side (top ↔ bottom, left ↔ right). The cross-axis position is clamped to stay on screen. A consistent `kLayrzTooltipOffset` (10.0lp) gap is maintained between the anchor edge and the tooltip surface. This enum is shared with `LayrzAnchoredPanel`'s own `preferredSide` parameter.

---

## `LayrzTooltipTrigger` enum

| Value | Desktop (mouse connected) | Touch-only device |
|---|---|---|
| `.pointer` | Show on hover (`MouseRegion`); hide on pointer-exit. **Default.** | Show on long-press; dismissed only by the *next* `PointerDownEvent` anywhere on screen (releasing the long-press finger does NOT dismiss it). |
| `.tap` | A single tap toggles open/closed; hover has no effect. | Same — a single tap toggles; another tap anywhere dismisses. |

Both modes use a **global pointer route** that intercepts `PointerDownEvent` only (never `PointerUpEvent`) — this is why a long-press-triggered tooltip survives the finger lifting off (`PointerUpEvent`) and only closes on the next new touch.

---

## Behavior notes

- **Overlay requirement and graceful degradation**: `LayrzTooltip` needs an `Overlay` ancestor (provided by `LayrzApp`). If `Overlay.maybeOf(context)` returns null, the widget simply returns `child` unchanged — no tooltip, no crash. This lets tooltips work inside minimal test harnesses.
- **Pass-through interaction**: the tooltip surface uses `IgnorePointer(ignoring: true)`, and the anchor wrapper layers (`MouseRegion`, `GestureDetector`) use `HitTestBehavior.translucent` — pointer events pass through to `child` and to whatever is painted beneath it in a `Stack`.
- **Mouse detection is live**: the widget observes `RendererBinding.instance.mouseTracker.mouseIsConnected` at init and listens for changes, so a mid-session mouse connect/disconnect switches between hover mode and long-press mode automatically.
- **Known gesture-arena limitation**: if `child` has its own `onLongPress` handler, that handler wins the gesture arena on touch devices and the tooltip's long-press trigger never fires (hover on desktop is unaffected). `LayrzButton` sidesteps this internally via its own `hintText` parameter — prefer that for buttons rather than wrapping them in `LayrzTooltip`.
- **`OverlayPortal` over manual `OverlayEntry`**: the overlay content rebuilds every time the host widget rebuilds, so its position is recomputed fresh from the anchor's current location — this avoids the tooltip detaching from its anchor during scrolling, which a one-shot `OverlayEntry` would suffer from.
- **Surface sizing**: max width is 80% of viewport width (`kLayrzTooltipMaxWidthFactor`); size is predicted upfront via `TextPainter` layout before placement is computed.
- **Accessibility**: the tooltip's plain-text content is announced via `Semantics(tooltip: plainText)` on the anchor wrapper (for rich text, `contentRichText.toPlainText()` is used). Keyboard focus does not trigger the tooltip — only hover, long-press, or tap.
- **App lifecycle**: the tooltip auto-dismisses when the app is paused or becomes inactive (`AppLifecycleState.paused`/`.inactive`).
