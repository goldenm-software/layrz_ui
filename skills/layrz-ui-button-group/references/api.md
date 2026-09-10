# LayrzButtonGroup — API Reference

Source: `lib/src/buttons/src/button_group.dart`
- `LayrzButtonGroup` class — line 28

---

## Examples

```dart
// Automatic responsive collapse (row >= md, dropdown < md)
LayrzButtonGroup(
  triggerHintText: 'Actions',
  items: [
    LayrzDropdownEntry.save(labelText: 'Save', onTap: () {}),
    LayrzDropdownEntry.delete(labelText: 'Delete', onTap: () {}),
  ],
)

// Forced row mode
LayrzButtonGroup(
  triggerHintText: 'Table actions',
  items: [
    LayrzDropdownEntry.save(labelText: 'Save', onTap: () {}),
    LayrzDropdownEntry.edit(labelText: 'Edit', onTap: () {}),
    LayrzDropdownEntry.delete(labelText: 'Delete', onTap: () {}),
  ],
  useDropdown: false,
)

// Forced dropdown mode with section labels
LayrzButtonGroup(
  triggerHintText: 'Table actions',
  items: [
    LayrzDropdownLabel(labelText: 'Modify'),
    LayrzDropdownEntry.save(labelText: 'Save', onTap: () {}),
    LayrzDropdownEntry.edit(labelText: 'Edit', onTap: () {}),
    LayrzDropdownLabel(labelText: 'Danger zone'),
    LayrzDropdownEntry.delete(labelText: 'Delete', onTap: () {}),
  ],
  useDropdown: true,
)

// Custom trigger icon (dropdown mode only)
LayrzButtonGroup(
  triggerHintText: 'More actions',
  triggerIcon: MdiIcons.dotsHorizontal,
  items: [
    LayrzDropdownEntry.info(labelText: 'Details', onTap: () {}),
  ],
)

// Custom alignment for the dropdown panel
LayrzButtonGroup(
  triggerHintText: 'Actions',
  alignment: .end,
  items: [
    LayrzDropdownEntry.edit(labelText: 'Edit', onTap: () {}),
  ],
)

// Builder constructor — fully custom trigger widget
LayrzButtonGroup.builder(
  useDropdown: true,
  items: [
    LayrzDropdownEntry.save(labelText: 'Save', onTap: () {}),
    LayrzDropdownEntry.delete(labelText: 'Delete', onTap: () {}),
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

## Constructor

```dart
// Default constructor
const LayrzButtonGroup({
  required this.items,
  required this.triggerHintText,
  this.useDropdown,
  this.spacing,
  this.triggerIcon,
  this.alignment = LayrzDropdownMenuAlignment.start,
  super.key,
}) : builder = null;

// Builder constructor
const LayrzButtonGroup.builder({
  required this.items,
  required this.builder,
  this.useDropdown,
  this.spacing,
  this.alignment = LayrzDropdownMenuAlignment.start,
  super.key,
}) : triggerHintText = null,
     triggerIcon = null;
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `items` | `List<LayrzDropdownItem>` | **required** | `LayrzDropdownEntry` or `LayrzDropdownLabel` instances, in order. Passed through unchanged in dropdown mode; in row mode, entries become buttons and labels are skipped. Empty list renders nothing in either mode. |
| `triggerHintText` | `String?` | **required** on the default ctor | Accessible name + tooltip for the collapsed trigger. Fixed to `null` on `.builder()` — the caller's trigger owns its own name. |
| `useDropdown` | `bool?` | `null` | `null` = auto-switch at the `md` breakpoint; `true` = always dropdown; `false` = always row. |
| `spacing` | `double?` | `null` (→ `tokens.spacing.sp2`) | Gap between buttons in row mode only. |
| `triggerIcon` | `IconData?` | `null` (→ `MdiIcons.dotsVertical`) | Icon on the default collapsed trigger. Dropdown mode only. Fixed to `null` on `.builder()`. |
| `builder` | `LayrzDropdownMenuBuilder?` | `null` on default ctor; **required** on `.builder()` | Supplies a fully custom trigger widget, receiving the menu's `MenuController`. Only called in dropdown mode. |
| `alignment` | `LayrzDropdownMenuAlignment` | `.start` | Horizontal alignment of the dropdown panel against the trigger. Dropdown mode only. |

---

## Row-mode entry-to-button conversion

Each `LayrzDropdownEntry` becomes a `LayrzButton` (style always `.filled`, non-Fab):

| Entry property | Button property |
|---|---|
| `labelText` | `labelText` |
| `icon` | `icon` |
| `onTap` | `onTap` (nulled when the entry is disabled) |
| `enabled` | `isDisabled` (inverted) |
| `color` / semantic type | `color`, resolved via `entry.resolveAccent(tokens)` — button always uses `type: .custom` |
| `shortcut` | dropped — `LayrzButton` has no shortcut field |

`LayrzDropdownLabel` items are omitted entirely in row mode.

---

## Behavior notes

- The responsive check is `context.breakpoint.index < LayrzBreakpoint.md.index` — i.e. it collapses below `md` (960px), matching the `context.isCompact` threshold but computed from `breakpoint` directly rather than the `isCompact` getter.
- Row mode wraps buttons in a `Wrap` with `spacing` between them (no explicit `runSpacing` override — relies on `Wrap`'s default).
- The default (non-builder) trigger is a `LayrzButton` with `style: .textFab` and `icon: triggerIcon ?? MdiIcons.dotsVertical` — always icon-only.
- **Gesture-arena gotcha for custom triggers:** `LayrzButton` retains a non-null `onTapCancel` even while conceptually "disabled," which wins the gesture arena over an ancestor `GestureDetector`. Never wrap a `builder` trigger in your own `GestureDetector` — wire `controller.open`/`controller.close` directly to the trigger's own tap handler, or the menu will silently never open.
- Dropdown-mode items pass straight through to `LayrzDropdownMenu`, so any `LayrzDropdownEntry`/`LayrzDropdownLabel` behavior documented for that widget (auto-close on selection, etc.) applies unchanged here.
