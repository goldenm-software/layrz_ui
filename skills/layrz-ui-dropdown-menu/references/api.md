# LayrzDropdownMenu — API Reference

Source: `lib/src/menus/src/dropdown_menu.dart` (widget + layout delegate), `dropdown_items.dart` (entry/label model), `dropdown_menu_types.dart` (alignment enum), `dropdown_entry_style_spec.dart` (internal style resolution)

- `LayrzDropdownMenu` class — `dropdown_menu.dart` line 53
- `LayrzDropdownMenuBuilder` typedef — `dropdown_menu.dart` line 18
- `LayrzDropdownMenuAlignment` enum — `dropdown_menu_types.dart` line 2
- `LayrzDropdownItem` sealed class — `dropdown_items.dart` line 62
- `LayrzDropdownEntry` class — `dropdown_items.dart` line 164
- `LayrzDropdownLabel` class — `dropdown_items.dart` line 80

---

## Examples

```dart
// Basic menu with entries
LayrzDropdownMenu(
  builder: (context, controller) => LayrzButton(
    labelText: 'Actions',
    onTap: controller.isOpen ? controller.close : controller.open,
  ),
  items: [
    LayrzDropdownEntry(
      labelText: 'Edit',
      icon: MdiIcons.pencilOutline,
      onTap: () => _editItem(),
    ),
    LayrzDropdownEntry(
      labelText: 'Delete',
      icon: MdiIcons.trashCanOutline,
      color: context.tokens.colors.danger,
      onTap: () => _deleteItem(),
    ),
  ],
)

// Semantic factories
LayrzDropdownEntry.save(labelText: 'Save', onTap: () => _save());
LayrzDropdownEntry.cancel(labelText: 'Cancel', onTap: () => _cancel());
LayrzDropdownEntry.delete(labelText: 'Delete', onTap: () => _delete());

// Grouped with labels
LayrzDropdownMenu(
  builder: (context, controller) => LayrzButton.show(
    labelText: 'View Options',
    onTap: controller.open,
  ),
  items: [
    LayrzDropdownLabel(labelText: 'Display'),
    LayrzDropdownEntry(labelText: 'Compact View', onTap: () => _setViewMode(ViewMode.compact)),
    LayrzDropdownLabel(labelText: 'Sort'),
    LayrzDropdownEntry(labelText: 'By Name', onTap: () => _sortBy(SortKey.name)),
  ],
)

// Keyboard shortcut (display + auto-bind under LayrzApp)
LayrzDropdownEntry(
  labelText: 'Save',
  icon: MdiIcons.floppy,
  onTap: () => _save(),
  shortcut: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
)

// Programmatic control
final controller = MenuController();
LayrzDropdownMenu(
  controller: controller,
  builder: (context, controller) => LayrzButton(labelText: 'Open/Close', onTap: controller.open),
  items: [LayrzDropdownEntry(labelText: 'Option 1', onTap: () => _handleOption1())],
);
controller.open();
```

---

## Constructor

```dart
const LayrzDropdownMenu({
  required this.builder,
  required this.items,
  this.controller,
  this.onOpen,
  this.onClose,
  this.childFocusNode,
  this.alignment = LayrzDropdownMenuAlignment.start,
  super.key,
});
```

```dart
typedef LayrzDropdownMenuBuilder = Widget Function(
  BuildContext context,
  MenuController controller,
);
```

```dart
const LayrzDropdownEntry({
  required this.labelText,
  required this.onTap,
  this.icon,
  this.enabled = true,
  this.color,
  this.shortcut,
  super.key,
});

const LayrzDropdownLabel({
  required this.labelText,
  this.color,
  super.key,
});
```

---

## Properties

### `LayrzDropdownMenu`

| Property | Type | Default | Notes |
|---|---|---|---|
| `builder` | `LayrzDropdownMenuBuilder` | required | Builds the trigger widget with access to the `MenuController`; wire it directly (e.g. `onTap: controller.open`). Never wrapped by the menu itself, so the trigger's own gestures are never lost to a gesture-arena conflict. |
| `items` | `List<LayrzDropdownItem>` | required | `LayrzDropdownEntry` or `LayrzDropdownLabel` only — sealed hierarchy guarantee. |
| `controller` | `MenuController?` | `null` | External programmatic control. `null` = menu owns its own controller. **Must never be swapped** for a different non-null instance via rebuild — an assertion fires. `MenuController` holds no disposable resources and can be shared across menu instances. |
| `onOpen` | `VoidCallback?` | `null` | Fires before the overlay is shown and the fade-in starts. |
| `onClose` | `VoidCallback?` | `null` | Fires after the overlay is removed. |
| `childFocusNode` | `FocusNode?` | `null` | Passed to the trigger for keyboard interaction; focus returns here when the menu closes. Caller must keep it alive for the menu's lifetime. |
| `alignment` | `LayrzDropdownMenuAlignment` | `.start` | Horizontal alignment of the panel relative to the trigger; clamped into overlay bounds if it would overflow. |

### `LayrzDropdownEntry`

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String` | required | Row text. |
| `onTap` | `VoidCallback` | required | Fires on tap; the menu closes automatically right after — never close it yourself. |
| `icon` | `IconData?` | `null` | Optional leading icon. |
| `enabled` | `bool` | `true` | `false` greys the row and disables taps/focus/keyboard input. |
| `color` | `Color?` | `null` | Paints a small leading dot with this exact color, independent of `icon` (an entry may have a dot, an icon, both, or neither). Paint-only. **Breaking change as of 0.0.8**: previously typed `LayrzColorSwatch?`; now a plain `Color?` — source-compatible for callers passing a swatch's base value. |
| `shortcut` | `Set<LogicalKeyboardKey>?` | `null` | Display-only hint formatted via `formatLayrzShortcut` (platform-native glyphs — `⌘`/`⌃` on macOS, `Ctrl` elsewhere). When rendered under a `LayrzApp` (which provides the ambient `LayrzShortcut` registry), the menu auto-binds this combination to `onTap` for as long as the menu widget is mounted — works without the panel being open. Outside that ancestor, purely a display hint; binds no keys. Hidden entirely (no reserved space) when `LayrzPlatform.isMobile`. |

### `LayrzDropdownLabel`

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String` | required | Section heading text; casing/wording untouched by the widget. |
| `color` | `Color?` | `null` | Tints the label's band at `tokens.colors.tonalOpacity`, flattened over the panel surface. `null` keeps the neutral `sf3` band. |

---

## `LayrzDropdownMenuAlignment` enum

| Value | Description |
|---|---|
| `.start` | Panel's left edge aligns with the trigger's left edge. Default. |
| `.center` | Panel centers horizontally under the trigger. |
| `.end` | Panel's right edge aligns with the trigger's right edge. |

---

## Factory constructors

Six semantic factories on `LayrzDropdownEntry`, each requiring `labelText`/`onTap` and accepting the same optional parameters as the main constructor (`icon`/`color` override the preset, plus `enabled`, `shortcut`, `key`):

| Factory | Preset icon | Preset color |
|---|---|---|
| `.save()` | `MdiIcons.contentSaveOutline` | `tokens.colors.success` |
| `.cancel()` | `MdiIcons.closeCircleOutline` | `tokens.colors.danger` |
| `.info()` | `MdiIcons.informationOutline` | `tokens.colors.info` |
| `.show()` | `MdiIcons.eyeOutline` | `tokens.colors.info` |
| `.edit()` | `MdiIcons.pencilOutline` | `tokens.colors.warning` |
| `.delete()` | `MdiIcons.trashCanOutline` | `tokens.colors.danger` |

```dart
LayrzDropdownEntry.save(labelText: 'Export', icon: MdiIcons.download, onTap: () {}); // icon overridden
```

---

## Interaction states

Hover/press/focus change color and background only — geometry is fixed per decision D15.

| State | Background | Label color | Icon color |
|---|---|---|---|
| Resting | `sf1` | `fg1` | `fg1` |
| Hovered | `sf2` | `fg1` | `fg1` |
| Focused | `sf2` | `fg1` | `fg1` |
| Pressed | `sf3` | `fg1` | `fg1` |
| Disabled | `sf1` | `fg3` | `fg3` |

---

## Sizing and layout

| Aspect | Value |
|---|---|
| Menu width | Clamped to `[kLayrzDropdownMenuMinWidth, kLayrzDropdownMenuMaxWidth]` = `[160, 320]` px |
| Entry height | Fixed `kLayrzDropdownEntryHeight` = 40px |
| Entry icon size | `kLayrzDropdownIconSize` = 18px |
| Color dot size | `kLayrzDropdownDotSize` = 8px |
| Panel position | Below the trigger by default; flips above if insufficient space below |
| Enter animation | Fade + 4px translate from the anchor's horizontal edge, `Curves.easeInOut`, tokens.motion.dHover duration |
| Exit animation | None — synchronous, owned by `RawMenuAnchor` |

---

## Behavior notes

- **Menu Controller** is the plain SDK `MenuController` (`package:flutter/widgets.dart`) — `open()`, `close()`, `isOpen`. Access it in the tree via `MenuController.maybeOf(context)`.
- **Keyboard and accessibility:** Escape dismisses and returns focus to the trigger; Up/Down arrow keys traverse focusable entries (labels and disabled entries are skipped); outside taps close the menu; entries expose button semantics with enabled/disabled state.
- **Shortcut auto-binding is mount-scoped**, not open-scoped: registered in `didChangeDependencies` (guarded against double-registration) and de-registered in `dispose`. Only enabled entries with a non-empty `shortcut` and non-null `onTap` are registered; `LayrzDropdownLabel` items are always skipped.
- **Controller swap safety.** In debug, passing a different non-null `controller` instance on a rebuild asserts. `MenuController` itself holds no disposable resources, so a single instance can safely back multiple menus for synchronized open/close.

---

## Companion widgets

The `menus` barrel (`lib/src/menus/menus.dart`) exports the widget and item model above. `LayrzDropdownEntryStyleSpec` (`dropdown_entry_style_spec.dart`) is an internal style-resolution helper, not part of the public surface.

## Related

- `LayrzContextMenu` — the pointer-anchored sibling menu family (right-click/long-press), with its own independent sealed entry model (`LayrzContextMenuEntry`/`LayrzContextMenuLabel`/`LayrzContextMenuDivider`).
- `LayrzAnchoredPanel` — general-purpose anchored overlay for arbitrary (non-sealed) content, used by picker inputs.
- `LayrzButton` — typical trigger widget for a dropdown menu.
