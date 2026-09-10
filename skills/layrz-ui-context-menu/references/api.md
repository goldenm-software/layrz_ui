# LayrzContextMenu — API Reference

Source: `lib/src/context_menu/src/context_menu.dart` (widget), `context_menu_item.dart` (entry model), `context_menu_layout_delegate.dart` (positioning), `context_menu_panel_items.dart` (internal row rendering, not exported)

- `LayrzContextMenu` class — line 60
- `LayrzContextMenuItem` sealed class — `context_menu_item.dart` line 17
- `LayrzContextMenuEntry` class — `context_menu_item.dart` line 29
- `LayrzContextMenuLabel` class — `context_menu_item.dart` line 96
- `LayrzContextMenuDivider` class — `context_menu_item.dart` line 131
- `LayrzContextMenuLayoutDelegate` class — `context_menu_layout_delegate.dart` line 24

---

## Examples

```dart
// Basic entries with an icon and a destructive action
LayrzContextMenu(
  entries: [
    LayrzContextMenuLabel(labelText: 'Row actions'),
    LayrzContextMenuEntry(
      labelText: 'Edit',
      icon: MdiIcons.pencilOutline,
      onTap: () => _editRow(),
    ),
    LayrzContextMenuEntry(
      labelText: 'Duplicate',
      icon: MdiIcons.contentCopy,
      onTap: () => _duplicateRow(),
    ),
    const LayrzContextMenuDivider(),
    LayrzContextMenuEntry(
      labelText: 'Delete',
      icon: MdiIcons.trashCanOutline,
      color: context.tokens.colors.danger,
      onTap: () => _deleteRow(),
    ),
  ],
  child: Container(
    padding: context.tokens.spacing.pd3,
    child: const Text('Right-click or long-press this row'),
  ),
)

// Disabled entry
LayrzContextMenuEntry(
  labelText: 'Archive',
  icon: MdiIcons.archiveOutline,
  enabled: false,
  onTap: () => _archive(),
)

// Capped panel height for a long entry list
LayrzContextMenu(
  maxHeight: 320,
  entries: manyEntries,
  child: content,
)

// Suppress the web-suppression itself (keep the browser's native menu too)
LayrzContextMenu(
  suppressBrowserContextMenu: false,
  entries: entries,
  child: content,
)
```

---

## Constructor

```dart
const LayrzContextMenu({
  required this.child,
  required this.entries,
  this.maxHeight,
  this.suppressBrowserContextMenu = true,
  super.key,
});
```

```dart
const LayrzContextMenuEntry({
  required this.labelText,
  required this.onTap,
  this.icon,
  this.enabled = true,
  this.color,
});

const LayrzContextMenuLabel({
  required this.labelText,
  this.color,
});

const LayrzContextMenuDivider();
```

---

## Properties

### `LayrzContextMenu`

| Property | Type | Default | Notes |
|---|---|---|---|
| `child` | `Widget` | required | The wrapped widget. Keeps its own tap/long-press gestures where possible. |
| `entries` | `List<LayrzContextMenuItem>` | required | Panel content. Each element is a `LayrzContextMenuEntry`, `LayrzContextMenuLabel`, or `LayrzContextMenuDivider`. |
| `maxHeight` | `double?` | `null` | Maximum panel content height in logical pixels. `null` constrains only by overlay bounds minus padding. Content taller than this scrolls inside the panel. |
| `suppressBrowserContextMenu` | `bool` | `true` | Suppresses the browser's native right-click menu on web while this widget is mounted (restored on dispose). No effect on non-web targets. |

### `LayrzContextMenuEntry`

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String` | required | Text displayed on the row. |
| `onTap` | `VoidCallback` | required | Fires when tapped while `enabled` is `true`. The menu closes automatically right after — never close it yourself. |
| `icon` | `IconData?` | `null` | Optional leading icon. When `null`, no space is reserved for it. |
| `enabled` | `bool` | `true` | `false` mutes the row (`fg3` text/icon) and suppresses `onTap` entirely. |
| `color` | `Color?` | `null` | Optional accent applied to label and icon (e.g. `tokens.colors.danger`). Paint-only — never affects background, geometry, or spacing (D15). |

### `LayrzContextMenuLabel`

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String` | required | Section heading text. Casing/wording is entirely the caller's responsibility — not transformed. |
| `color` | `Color?` | `null` | Optional label text color. `null` uses the muted `fg3` foreground token. |

### `LayrzContextMenuDivider`

No fields — `const LayrzContextMenuDivider()`.

---

## `LayrzContextMenuItem` sealed hierarchy

| Subtype | Role | Interactive | Focusable |
|---|---|---|---|
| `LayrzContextMenuEntry` | Tappable action row | Yes (when `enabled`) | Yes (when `enabled`) |
| `LayrzContextMenuLabel` | Section heading | No | No |
| `LayrzContextMenuDivider` | Separator line | No | No |

Sealed, so any switch over `LayrzContextMenuItem` is exhaustive at compile time — a hypothetical fourth subtype would fail to compile rather than silently falling through.

**Intentionally independent from `LayrzDropdownItem`.** `LayrzContextMenu` does not extend, wrap, or reuse `LayrzDropdownEntry`/`LayrzDropdownLabel` from `lib/src/menus/`, even though the visual language matches closely. A change to one menu family can never silently ripple into the other.

---

## Panel styling

| Property | Value |
|---|---|
| Background | `tokens.colors.sf1` |
| Border radius | `tokens.radius.br3` |
| Shadow | `tokens.shadow.elevation3` |
| Enter animation | Fade, `tokens.motion.dHover` duration, `Curves.easeInOut` |
| Exit animation | None — synchronous, mirroring `RawMenuAnchor`'s own overlay teardown |
| Content overflow | Scrolls internally (`SingleChildScrollView`) when taller than available space or `maxHeight` |
| Entry row height | `kLayrzDropdownEntryHeight` (40px) — shared constant with `LayrzDropdownMenu` for visual parity |
| Entry icon size | `kLayrzDropdownIconSize` (18px) |

---

## Behavior notes

- **Pointer-anchored positioning.** `LayrzContextMenuLayoutDelegate` anchors to the pointer's local offset at the moment of the right-click/long-press (converted to overlay coordinates), not to `child`'s rect. That point becomes the panel's preferred top-left corner: it flips horizontally on right-edge overflow, flips vertically on bottom-edge overflow, then clamps into overlay bounds on both axes. With no captured pointer position, it falls back to the trigger's own top-left corner.
- **Panel width parity with `LayrzDropdownMenu`.** Content-sized within `[kLayrzDropdownMenuMinWidth, kLayrzDropdownMenuMaxWidth]` (160–320px), clamped further to the available overlay width.
- **Both gestures always wired.** `onSecondaryTapDown` and `onLongPressStart` are both always active — which one actually fires is a hardware fact (mouse vs. touch), not something the widget or caller chooses.
- **Child gesture interaction.** `LayrzContextMenu` only listens for gestures that don't have a competing primary-gesture equivalent (`onSecondaryTapDown`) plus `onLongPressStart`. If `child` itself declares a competing long-press recognizer, Flutter's gesture arena resolves which one wins — this is an unavoidable consequence of two long-press recognizers on the same pointer, not a bug.
- **Web suppression is load-bearing, not decorative.** `BrowserContextMenu.disableContextMenu()`/`enableContextMenu()` assert `kIsWeb` internally — the widget checks `kIsWeb` itself before calling either, so it never trips that assertion on native targets.
- **Graceful degradation with no `Overlay`.** `build()` returns `widget.child` unchanged when `Overlay.maybeOf(context)` is `null` — no menu is ever shown, no error is thrown. This keeps `child` renderable in minimal test harnesses without a full `LayrzApp`/`Overlay` ancestry.
- **Dismissal.** The panel closes on an outside tap (`TapRegion.onTapOutside`), closing the underlying `MenuController`.

---

## Related

- `LayrzDropdownMenu` — the button/tap-triggered sibling menu family; anchors to a trigger widget's rect rather than a pointer position, and uses its own independent entry model (`LayrzDropdownEntry`/`LayrzDropdownLabel`).
- `LayrzAnchoredPanel` — the general-purpose anchored overlay panel this widget's layout delegate deliberately does not reuse (side-of-rect anchoring rather than pointer-point anchoring).
