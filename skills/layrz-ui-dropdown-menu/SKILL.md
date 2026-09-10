---
name: layrz-ui-dropdown-menu
description: Use LayrzDropdownMenu in a layrz_ui Flutter widget. Apply when adding a floating menu triggered by tapping a visible button or "..." affordance — builder-wired trigger, sealed entry/label items, the six semantic entry factories (.save/.cancel/.info/.show/.edit/.delete), and optional keyboard-shortcut display.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.start`, `.center`, `.end`) — never the fully-qualified form (`LayrzDropdownMenuAlignment.start`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A menu triggered by tapping a visible button, icon, or "..." affordance — a toolbar overflow menu, a row's action trigger.
- **Trigger is a builder, not a child.** This prevents the menu from wrapping the trigger and losing gestures to the gesture arena — the trigger wires itself to `controller.open()`/`controller.close()`.
- Use the six semantic factories (`.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`) on `LayrzDropdownEntry` for CRUD-style rows — they preset icon and semantic color.
- Use `shortcut` on an entry to show (and, under a `LayrzApp`, auto-bind) a keyboard shortcut — display-only outside a `LayrzShortcut` ancestor.
- **Do not use** for a menu triggered by right-click or long-press at a pointer position — use `LayrzContextMenu` instead.
- **Do not use** for an arbitrary-content floating panel (a picker's option list, a filter panel) — use `LayrzAnchoredPanel` instead; `LayrzDropdownMenu`'s items are restricted to the sealed `LayrzDropdownItem` hierarchy.

---

## Minimal usage

```dart
LayrzDropdownMenu(
  builder: (context, controller) => LayrzButton(
    labelText: LayrzUiL10n.of(context).actions,
    onTap: controller.isOpen ? controller.close : controller.open,
  ),
  items: [
    LayrzDropdownEntry.edit(
      labelText: LayrzUiL10n.of(context).edit,
      onTap: () => _editItem(),
    ),
    LayrzDropdownEntry.delete(
      labelText: LayrzUiL10n.of(context).delete,
      onTap: () => _deleteItem(),
    ),
  ],
)
```

---

## Key behaviors

- **Builder receives `MenuController`** — wire it directly: `onTap: controller.isOpen ? controller.close : controller.open`. Never wrap the trigger in a `GestureDetector` of your own inside `builder`.
- `items` accepts only `LayrzDropdownEntry` (interactive) and `LayrzDropdownLabel` (non-interactive heading) — the sealed `LayrzDropdownItem` hierarchy makes any other widget type impossible by construction.
- Entry taps close the menu automatically after `onTap` runs — never call a close method yourself.
- **Semantic factories preset icon + color but keep both overridable** — `LayrzDropdownEntry.save(icon: MdiIcons.download, ...)` overrides just the icon.
- `shortcut` (a `Set<LogicalKeyboardKey>`) is display-only by contract, but **auto-binds live** when this menu is mounted under a `LayrzApp` (its ambient `LayrzShortcut` registry) — the shortcut fires without the panel ever opening. Outside that ancestor it stays purely a rendered hint. Hidden entirely on `LayrzPlatform.isMobile`.
- `controller` (a plain SDK `MenuController`) must **never be swapped** across rebuilds — an assertion fires if a different instance is passed to `didUpdateWidget`.
- Enter animation is fade + 4px translate from the anchor's edge; exit is synchronous (no animation) — `RawMenuAnchor` tears down the overlay immediately.

---

## Common patterns

```dart
// Grouped entries under labels
LayrzDropdownMenu(
  builder: (context, controller) => LayrzButton.show(
    labelText: LayrzUiL10n.of(context).viewOptions,
    onTap: controller.open,
  ),
  items: [
    LayrzDropdownLabel(labelText: LayrzUiL10n.of(context).display),
    LayrzDropdownEntry(
      labelText: LayrzUiL10n.of(context).compactView,
      icon: MdiIcons.formatColumns,
      onTap: () => _setViewMode(ViewMode.compact),
    ),
    LayrzDropdownLabel(labelText: LayrzUiL10n.of(context).sort),
    LayrzDropdownEntry(
      labelText: LayrzUiL10n.of(context).byName,
      onTap: () => _sortBy(SortKey.name),
    ),
  ],
)

// Keyboard shortcut display + auto-bind (under a LayrzApp)
LayrzDropdownEntry(
  labelText: LayrzUiL10n.of(context).save,
  icon: MdiIcons.floppy,
  onTap: () => _save(),
  shortcut: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
)

// Color dot for a destructive overflow action
LayrzDropdownEntry(
  labelText: LayrzUiL10n.of(context).delete,
  color: context.tokens.colors.danger,
  onTap: () => _delete(),
)

// Programmatic control via an external controller
final controller = MenuController();

LayrzDropdownMenu(
  controller: controller,
  builder: (context, controller) => LayrzButton(
    labelText: LayrzUiL10n.of(context).open,
    onTap: controller.open,
  ),
  items: [LayrzDropdownEntry(labelText: 'Option 1', onTap: () {})],
);
// controller.open(); controller.close();

// End-aligned panel (right-aligned trigger)
LayrzDropdownMenu(
  alignment: .end,
  builder: (context, controller) => LayrzButton(
    labelText: LayrzUiL10n.of(context).more,
    icon: MdiIcons.dotsVertical,
    style: .filledFab,
    onTap: controller.open,
  ),
  items: items,
)
```

---

## `LayrzDropdownMenuAlignment` enum

| Value | Behavior |
|---|---|
| `.start` (default) | Panel's left edge aligns with the trigger's left edge. |
| `.center` | Panel centers horizontally under the trigger. |
| `.end` | Panel's right edge aligns with the trigger's right edge. |

Panel is positioned per this alignment, then clamped into the overlay bounds if it would overflow.

---

## Usage conventions

- Localize every `labelText` via `LayrzUiL10n.of(context).<key>` — never hardcode strings.
- Prefer the six semantic factories (`.save`/`.cancel`/`.info`/`.show`/`.edit`/`.delete`) for CRUD-style rows over the base constructor with a manual `icon`/`color` — they keep icon/color choices consistent with `LayrzButton`'s own semantic factories.
- Use `color` on a plain `LayrzDropdownEntry` (not a semantic factory) to echo another UI element's color — e.g. matching a `LayrzButtonGroup` button's own semantic color in its overflow menu.
- Never bind the `shortcut` set yourself outside this widget — the application still owns all keyboard binding; `shortcut` is display + optional auto-bind only, not a manual `Shortcuts`/`Actions` wire-up.
- Don't put more than a screenful of `items` without expecting internal scrolling — the panel's `SingleChildScrollView` handles overflow, but a long undifferentiated list is hard to scan; group with `LayrzDropdownLabel`.
