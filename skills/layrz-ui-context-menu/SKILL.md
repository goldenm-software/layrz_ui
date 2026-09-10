---
name: layrz-ui-context-menu
description: Use LayrzContextMenu in a layrz_ui Flutter widget. Apply when adding a secondary, pointer-anchored action menu triggered by right-click on desktop/web or long-press on touch — table rows, cards, canvas items, tree nodes — using entries, labels, and dividers.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A secondary action menu triggered by right-click (desktop/web) or long-press (touch) on an arbitrary widget — a table row, a card, a canvas item, a tree node.
- Both gestures are **always wired on every platform** — which one actually fires is a hardware fact (mice expose a secondary button, touch surfaces don't), not a caller choice.
- The panel anchors to the **exact pointer position** that triggered it, not to `child`'s bounding rect, and flips/clamps to always stay on-screen.
- **Do not use** for a menu triggered by tapping a visible button or "..." affordance — use `LayrzDropdownMenu` instead; it anchors to the trigger's own rect via a builder-wired tap.
- **Do not use** for a general-purpose floating panel anchored to a widget side (input pickers) — use `LayrzAnchoredPanel` instead.

---

## Minimal usage

```dart
LayrzContextMenu(
  entries: [
    LayrzContextMenuEntry(
      labelText: LayrzUiL10n.of(context).edit,
      icon: MdiIcons.pencilOutline,
      onTap: () => _editRow(),
    ),
    LayrzContextMenuEntry(
      labelText: LayrzUiL10n.of(context).delete,
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
```

---

## Key behaviors

- `LayrzContextMenu` ships its **own** sealed entry hierarchy — `LayrzContextMenuItem` → `LayrzContextMenuEntry` (interactive), `LayrzContextMenuLabel` (non-interactive heading), `LayrzContextMenuDivider` (separator). This is intentionally **independent** from `LayrzDropdownItem`/`LayrzDropdownEntry` used by `LayrzDropdownMenu` — a change to one family never ripples into the other.
- `child` keeps its own tap/long-press gestures where possible — this widget only listens for `onSecondaryTapDown` and `onLongPressStart`. A competing long-press recognizer on `child` is resolved by Flutter's normal gesture arena (unavoidable, not a bug).
- `LayrzContextMenuEntry.onTap` closes the menu automatically right after it runs — never call a close method yourself.
- **Graceful degradation:** with no ancestor `Overlay`, the widget returns `child` unchanged — no menu, no error. Keeps `child` renderable in minimal test harnesses.
- On web, `suppressBrowserContextMenu: true` (default) disables the browser's native right-click menu while this widget is mounted, restoring it on dispose. No effect on non-web targets.
- If the menu is opened with no captured pointer position (defensive fallback), the panel anchors at the trigger's own top-left corner instead.

---

## Common patterns

```dart
// Grouped entries with a label and a divider before a destructive action
LayrzContextMenu(
  entries: [
    LayrzContextMenuLabel(labelText: LayrzUiL10n.of(context).rowActions),
    LayrzContextMenuEntry(
      labelText: LayrzUiL10n.of(context).duplicate,
      icon: MdiIcons.contentCopy,
      onTap: () => _duplicateRow(),
    ),
    const LayrzContextMenuDivider(),
    LayrzContextMenuEntry(
      labelText: LayrzUiL10n.of(context).delete,
      icon: MdiIcons.trashCanOutline,
      color: context.tokens.colors.danger,
      onTap: () => _deleteRow(),
    ),
  ],
  child: _RowContent(item: item),
)

// A disabled entry
LayrzContextMenu(
  entries: [
    LayrzContextMenuEntry(
      labelText: LayrzUiL10n.of(context).archive,
      icon: MdiIcons.archiveOutline,
      enabled: item.canArchive,
      onTap: () => _archive(item),
    ),
  ],
  child: _CardTile(item: item),
)

// Tall content, capped panel height
LayrzContextMenu(
  maxHeight: 320,
  entries: buildLongEntryList(),
  child: _CanvasNode(node: node),
)

// Web-only: keep the browser's native context menu (rare)
LayrzContextMenu(
  suppressBrowserContextMenu: false,
  entries: entries,
  child: content,
)
```

---

## Companion subtypes

| Type | Role | Notes |
|---|---|---|
| `LayrzContextMenuEntry` | Interactive, tappable row | `labelText`, `onTap` required. `icon`, `enabled`, `color` optional (accent paints label/icon only, never background/geometry). |
| `LayrzContextMenuLabel` | Non-interactive section heading | `labelText` required, `color` optional. Never responds to input; skipped during keyboard traversal. |
| `LayrzContextMenuDivider` | Thin separator line | No fields; `const LayrzContextMenuDivider()`. |

---

## Usage conventions

- Localize every `labelText` via `LayrzUiL10n.of(context).<key>` — never hardcode strings.
- Use `color: context.tokens.colors.danger` on an `LayrzContextMenuEntry` for destructive actions, matching `LayrzDropdownEntry`'s convention of an explicit accent color.
- Use `MdiIcons` (from `flutter_material_design_icons`, already a layrz_ui dependency) for `icon` — never a Material `Icons.*` constant.
- Keep entry counts short and scannable; group related entries under a `LayrzContextMenuLabel` and separate destructive actions with a `LayrzContextMenuDivider` rather than color alone.
- Don't wrap `child` in your own `GestureDetector` for tap/long-press unless you specifically intend to compete in the gesture arena — `LayrzContextMenu` already preserves `child`'s existing gestures.
