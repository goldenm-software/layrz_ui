# LayrzBottomSheet — API Reference

Source: `lib/src/sheets/src/bottom_sheet.dart`
- `LayrzBottomSheet` class (static-method surface, private constructor) — line 50
- `LayrzBottomSheet.show<T>()` static method — line 183

---

## Examples

```dart
// Simple picker (modal)
final selected = await LayrzBottomSheet.show<String>(
  context,
  semanticLabel: 'Choose an option. Press Escape to close.',
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: options
        .map((o) => LayrzTappable(onTap: () => Navigator.of(context).pop(o), child: Text(o)))
        .toList(),
  ),
);

// Persistent, non-blocking panel
LayrzBottomSheet.show<void>(
  context,
  isPersistent: true,
  showDragHandle: true,
  builder: (context) => _buildSupplementaryPanel(),
);

// Actions row — right-aligned, pinned below scrollable content
final confirmed = await LayrzBottomSheet.show<bool>(
  context,
  semanticLabel: 'Delete item? Press Escape to cancel.',
  builder: (context) => const Text('This cannot be undone.'),
  actions: [
    LayrzButton.cancel(labelText: 'Cancel', onTap: () => Navigator.of(context).pop(false)),
    LayrzButton.delete(labelText: 'Delete', onTap: () => Navigator.of(context).pop(true)),
  ],
);

// Non-dismissible — only actions/builder content can close it
final confirmed = await LayrzBottomSheet.show<bool>(
  context,
  canDismiss: false,
  semanticLabel: 'Confirm the action.',
  builder: (context) => const Text('This action cannot be undone.'),
  actions: [
    LayrzButton.save(labelText: 'Confirm', onTap: () => Navigator.of(context).pop(true)),
  ],
);

// Caller-owned scrollable (builder returns its own ListView/GridView)
LayrzBottomSheet.show<void>(
  context,
  scrollable: false,
  builder: (context) => ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, i) => Text(items[i]),
  ),
);

// Narrowed sizing bounds — snapSizes derived automatically when omitted
LayrzBottomSheet.show<void>(
  context,
  minSize: 0.3,
  maxSize: 0.5,
  initialSize: 0.4,
  builder: (context) => _buildCompactContent(),
);
```

---

## Constructor

`LayrzBottomSheet` has no public constructor — it is a static-method-only class (`LayrzBottomSheet._()` is a private constructor). The entire API surface is:

```dart
class LayrzBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    List<Widget>? actions,
    bool isPersistent = false,
    bool canDismiss = true,
    String? semanticLabel,
    List<double>? snapSizes,
    double initialSize = 0.5,
    double minSize = 0.25,
    double maxSize = 0.95,
    bool showDragHandle = true,
    bool scrollable = true,
  });
}
```

Asserts (fire at the call site):
- `minSize <= maxSize`
- `initialSize` between `minSize` and `maxSize`
- caller-supplied `snapSizes` (when non-null) is not empty
- every entry in the effective `snapSizes` (caller-supplied or derived) lies within `minSize..maxSize`
- `snapSizes` entries are in strictly ascending order

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `context` | `BuildContext` | required | Must contain a `Navigator`. The sheet is always pushed on the **root** navigator regardless of where this context lives. |
| `builder` | `WidgetBuilder` | required | Constructs the sheet's content. Receives the sheet's own `BuildContext` (use it for `Navigator.of(context).pop(...)`). |
| `actions` | `List<Widget>?` | `null` | Rendered as a right-aligned row pinned below the scrollable content, spacing/position mirroring `LayrzDialog.show`'s `actions`. `null` renders nothing and changes no layout. An empty list behaves like `null`. Never pushed behind the keyboard. |
| `isPersistent` | `bool` | `false` | `true` = no barrier, page stays interactive. `false` = modal, barrier present, Escape dismisses. |
| `canDismiss` | `bool` | `true` | Gates barrier tap, Escape, drag-to-dismiss, and the back gesture together. Does **not** infer from `actions` (unlike the dialog). The drag handle still renders and resizes even when `false` — only drag-past-the-end dismissal is disabled. |
| `semanticLabel` | `String?` | `null` | Announces the modal dialog role and exit path to screen readers. **Required for modal sheets** to get any dialog semantics at all — omitting it adds none, rather than an unlabeled route. Ignored when `isPersistent` is `true`. Must be localized by the caller. |
| `snapSizes` | `List<double>?` | `null` (derives `[0.5, 0.95]` for the default `minSize`/`maxSize`) | Ascending fractions (0.0–1.0) the sheet snaps to while dragging. When `null`, derived from the actual `minSize`/`maxSize` so a narrowed range never produces an out-of-bounds default. |
| `initialSize` | `double` | `0.5` | Fraction of screen height the sheet initially occupies. Must be within `minSize..maxSize`. |
| `minSize` | `double` | `0.25` | Minimum fraction of screen height the sheet can be dragged down to. |
| `maxSize` | `double` | `0.95` | Maximum fraction of screen height the sheet can occupy. |
| `showDragHandle` | `bool` | `true` | Renders a visual drag handle; the whole header region above the content becomes the drag target, not just the visible pill. |
| `scrollable` | `bool` | `true` | Wraps `builder`'s content in the sheet's own `SingleChildScrollView`. Set `false` when `builder` returns its own vertical `ListView`/`GridView` — the sheet then hands its `ScrollController` down via `PrimaryScrollController` instead. |

---

## Behavior notes

- **Return value.** `show<T>()` resolves with whatever `Navigator.pop(value)` inside the sheet passed, or `null` if dismissed without a value (barrier tap, Escape, drag-dismiss, back gesture).
- **Root navigator only.** There used to be a `useRootNavigator` parameter (mirroring `LayrzDialog.show`); it was removed — every real call site needed `true`, so there was nothing left to configure. A sheet shown from a nested navigator context (e.g. a `go_router` `ShellRoute`) would otherwise render inside that page's own layout instead of covering the screen.
- **Keyboard handling is automatic.** When the keyboard opens, the sheet's available height shrinks by `viewInsets.bottom` and the sheet pins to fill that reduced space (`minChildSize == maxChildSize == 1.0` while the keyboard is up); `snapSizes` collapses to `[1.0]`. Drag-to-dismiss keeps working via a separate dismiss-only gesture path. Closing the keyboard restores the sheet's exact previous fractional size, not a snap to `maxSize`.
- **Double-pop guard.** Every dismissal route (barrier tap, Escape, drag, back gesture) is guarded by `ModalRoute.of(context)?.isCurrent` — a second fast tap during the exit animation cannot double-pop the caller's own page underneath.
- **`actions` placement.** A sibling of the `Expanded` content area in the sheet's own `Column`, never nested inside whatever scrollable wraps `builder` — a tall `builder` scrolls independently while `actions` stays fixed and reachable.
- **`scrollable: false` mechanics.** The sheet's own `ScrollController` is handed down via `PrimaryScrollController` (covers every platform). A vertical scrollable in `builder` with no explicit `controller` binds to it automatically; a horizontal scrollable never inherits it; a nested second vertical scrollable does not inherit either (only the outer one does).
- **No close ("X") button, ever.** Unlike `LayrzDialog`, a sheet has no dismiss icon by design — it is dismissed by swipe, barrier tap, Escape, or explicit `actions`/`builder` content.
- **Safe area.** The sheet's surface (fill, rounded top corners, shadow) paints edge-to-edge under system bars; only the content is inset clear of them. This composes for free with the keyboard — no extra wiring needed.
- **Reduce motion.** The slide transition is shortened or skipped when `MediaQuery.of(context).disableAnimations` is `true`.

---

## Companion widgets

The `sheets` barrel (`lib/src/sheets/sheets.dart`) also exports:

- **`DragHandle`** (`lib/src/sheets/src/drag_handle.dart`) — the pill-shaped drag affordance rendered above the content when `showDragHandle: true`. Not typically constructed directly by consumers.
- **`LayrzModalRoute`** (`lib/src/sheets/src/modal_route.dart`) — shared base route providing the barrier, reduce-motion animation resolution, and double-pop guard (`LayrzModalRoute.popIfCurrent`) common to every modal surface in the design system, including `LayrzDialog`.

## Related

- `LayrzAnchoredPanel` — the desktop counterpart used by the same picker inputs (`LayrzSelectInput`, `LayrzDurationInput`, `LayrzComboBoxInput`) on wide viewports.
- `LayrzDialog.show` — the sibling modal surface sharing `LayrzModalRoute`; `canDismiss` mirrors its contract as closely as this component's shape allows.
