---
name: layrz-ui-button-group
description: Use LayrzButtonGroup in a layrz_ui Flutter widget. Apply when rendering a set of related actions that should collapse from a row of buttons into a single dropdown trigger on narrow viewports — table row actions, toolbar action clusters, or any list of LayrzDropdownEntry items that also need a plain-row rendering.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.start`) — never the fully-qualified form (`LayrzDropdownMenuAlignment.start`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A cluster of related actions on a list row, table row, or toolbar — save/edit/delete groups are the canonical case.
- Whenever the same action set must render as either a row of buttons (desktop) or a single overflow trigger (mobile), driven by the responsive breakpoint rather than by hand.
- Whenever you need grouping/section headers among actions (`LayrzDropdownLabel`) — labels only render in dropdown mode.
- **Do not use** for a single standalone action — use `LayrzButton` directly.
- **Do not use** as a generic dropdown menu unrelated to a set of buttons — use `LayrzDropdownMenu` directly.
- **Do not use** when the row must never collapse regardless of width — pass `useDropdown: false` on `LayrzButtonGroup` itself rather than reaching for a bare `Wrap` of `LayrzButton`s (you'd lose the label-skipping and accent-mapping conversion rules for free).

---

## Minimal usage

```dart
LayrzButtonGroup(
  triggerHintText: 'Row actions',
  items: [
    LayrzDropdownEntry.edit(labelText: 'Edit', onTap: onEdit),
    LayrzDropdownEntry.delete(labelText: 'Delete', onTap: onDelete),
  ],
)
```

---

## Key behaviors

- **Items are the source of truth.** `items` is a `List<LayrzDropdownItem>` (entries and labels), never a list of buttons — the widget converts entries to `LayrzButton`s itself in row mode.
- **Responsive by default.** `useDropdown: null` (the default) switches automatically at the `md` breakpoint (960px) via `context.breakpoint`, using `LayrzBreakpoint.md`, not `context.isCompact` directly. Pass `true`/`false` to force a mode unconditionally.
- **Row mode drops labels.** `LayrzDropdownLabel` items are silently skipped when rendering as a row — they only organize entries inside the dropdown menu.
- **Semantic colour carries over.** An entry built via a semantic factory (`.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`) keeps its resolved accent colour when converted to a row button, even though the resulting `LayrzButton` always uses `type: .custom`.
- **`triggerHintText` is required** on the default constructor — it is both the collapsed trigger's tooltip and its accessible name, since platform overflow menus need a stable name rather than an enumeration of contents.
- **The builder constructor drops the default trigger entirely.** `LayrzButtonGroup.builder` fixes `triggerHintText` and `triggerIcon` to `null` — your `builder` widget owns its own trigger and accessible name.
- An empty `items` list renders nothing (`SizedBox.shrink()`) in either mode.

---

## Common patterns

```dart
// 1. Force row mode — e.g. inside a wide table cell that must never collapse
LayrzButtonGroup(
  triggerHintText: 'Table actions',
  items: [
    LayrzDropdownEntry.save(labelText: 'Save', onTap: onSave),
    LayrzDropdownEntry.edit(labelText: 'Edit', onTap: onEdit),
    LayrzDropdownEntry.delete(labelText: 'Delete', onTap: onDelete),
  ],
  useDropdown: false,
)

// 2. Force dropdown mode with section labels
LayrzButtonGroup(
  triggerHintText: 'Table actions',
  items: [
    LayrzDropdownLabel(labelText: 'Modify'),
    LayrzDropdownEntry.save(labelText: 'Save', onTap: onSave),
    LayrzDropdownEntry.edit(labelText: 'Edit', onTap: onEdit),
    LayrzDropdownLabel(labelText: 'Danger zone'),
    LayrzDropdownEntry.delete(labelText: 'Delete', onTap: onDelete),
  ],
  useDropdown: true,
)

// 3. Responsive (automatic) — row above 960px, dropdown below
LayrzButtonGroup(
  triggerHintText: 'Actions',
  items: [
    LayrzDropdownEntry.save(labelText: 'Save', onTap: onSave),
    LayrzDropdownEntry.delete(labelText: 'Delete', onTap: onDelete),
  ],
)

// 4. Custom trigger widget via the builder constructor
LayrzButtonGroup.builder(
  useDropdown: true,
  items: [
    LayrzDropdownEntry.save(labelText: 'Save', onTap: onSave),
    LayrzDropdownEntry.delete(labelText: 'Delete', onTap: onDelete),
  ],
  builder: (context, controller) => LayrzButton(
    labelText: 'Options',
    icon: MdiIcons.cogOutline,
    style: .outlinedFab,
    onTap: controller.isOpen ? controller.close : controller.open,
  ),
)
```

---

## Usage conventions

- Give `triggerHintText` a description of the *group*, not a list of its contents — e.g. `'Row actions'`, not `'Edit, Delete'`.
- Never wrap a custom `builder` trigger's tap handler in its own `GestureDetector` — `LayrzButton` keeps a non-null `onTapCancel` even disabled, which wins the gesture arena and silently prevents the menu from opening. Wire `controller.open`/`controller.close` straight to the trigger widget's own `onTap`.
- Keep entry `labelText` short — row mode renders it as a full `LayrzButton` label, not just a menu row, so long labels will wrap the row layout on medium viewports.
- Reach for the semantic `LayrzDropdownEntry` factories (`.save`, `.edit`, `.delete`, …) instead of building entries with an explicit `color`, so the row-mode accent colour and dropdown icon stay consistent with the rest of the app.
- Let `spacing` default to `tokens.spacing.sp2` unless the surrounding layout has an established different gap — don't hardcode a pixel value.
