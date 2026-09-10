# LayrzIconInput — API Reference

Source: `lib/src/pickers/src/icon/icon_input.dart`
- `LayrzIconInput` class — line 57

Icon source: `package:flutter_mdi_remap` (`MdiRemapIcon`, `findMdiRemapIconByName`, `allMdiRemapIcons`, `searchMdiRemapIcons`) — a ~7,447-entry Material Design Icons registry, rendered via `flutter_material_design_icons`'s `Icon(icon.data, ...)`.

---

## Examples

```dart
// Minimal
LayrzIconInput(
  labelText: 'Icon',
  hintText: 'Pick an icon',
  value: iconName,
  onChanged: (value) => setState(() => iconName = value),
)

// Required with errors
LayrzIconInput(
  labelText: 'Category icon',
  isRequired: true,
  value: categoryIconName,
  errors: categoryIconName == null ? ['Pick an icon'] : const [],
  onChanged: (value) => setState(() => categoryIconName = value),
)

// Resolving a persisted name back to a renderable icon
final icon = iconName == null ? null : findMdiRemapIconByName(iconName!);
if (icon != null) Icon(icon.data, size: 24);

// Disabled, pre-filled
LayrzIconInput(
  labelText: 'Locked icon',
  value: 'mdi-lock',
  disabled: true,
)
```

---

## Constructor

```dart
const LayrzIconInput({
  super.key,
  this.value,
  this.onChanged,
  this.labelText,
  this.hintText,
  this.isRequired = false,
  this.errors = const [],
  this.hideDetails = false,
  this.disabled = false,
  this.controller,
  this.focusNode,
  this.dense = false,
  this.helpTitleText,
  this.helpContentText,
}) : assert(
       labelText != null || hintText != null,
       'At least one of labelText or hintText must be non-null.',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `value` | `String?` | `null` | The currently selected icon's stable `'mdi-...'` name, or `null` when nothing has been picked yet. Round-trips through `findMdiRemapIconByName`. |
| `onChanged` | `ValueChanged<String>?` | `null` | Called with the newly picked icon's name on commit (a tap in the surface). Never called with `null` — there is no Clear affordance. |
| `labelText` | `String?` | `null` | The label text displayed above the field. One of `labelText`/`hintText` is required. |
| `hintText` | `String?` | `null` | Placeholder shown when the field is empty and no `labelText` describes it. |
| `isRequired` | `bool` | `false` | Whether the field is marked as required. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the field. |
| `hideDetails` | `bool` | `false` | Whether to hide the error/help detail block. |
| `disabled` | `bool` | `false` | Whether the field is non-interactive. |
| `controller` | `TextEditingController?` | `null` | The anchor field's text controller. Created and disposed internally if omitted. |
| `focusNode` | `FocusNode?` | `null` | The anchor field's focus node. Created and disposed internally if omitted. |
| `dense` | `bool` | `false` | Whether the field uses the dense density variant. |
| `helpTitleText` | `String?` | `null` | Title text for the help affordance tooltip. |
| `helpContentText` | `String?` | `null` | Content text for the help affordance tooltip. |

There is no `allowedIcons`, `translations`, or `overridesLayrzTranslations` parameter — localization goes through `LayrzUiL10n` (`iconPickerSearch`, `iconPickerEmpty`), and the full registry is always searchable.

---

## Behavior notes

- **Commit-on-tap — no Save row.** Tapping an icon both fires `onChanged` and closes the surface immediately, via `LayrzModalRoute.popIfCurrent`. No `actions` list is passed to `LayrzResponsiveModal.show`, so Escape/barrier tap/back all close with no value picked. Mirrors `LayrzEmojiInput`'s identical commit-on-tap contract.
- **Container:** opens through `LayrzResponsiveModal.show` — a centered `LayrzDialog` at `>= 960px`, a `LayrzBottomSheet` below that (`initialSize: 0.6, maxSize: 0.9, snapSizes: [0.6, 0.9]`, `scrollable: false`). Both carry a `LayrzPickerDialogHeader` above the search field and icon grid; the dialog's own floating close icon is suppressed since the header already renders one.
- **Value type rationale:** stores the registry's stable `'mdi-...'` name string, not a raw `IconData` (codepoint not stable across `flutter_material_design_icons` versions) and not `MdiRemapIcon` itself — keeps the public contract a plain, directly-serializable `String`.
- **Search:** case-insensitive against both `MdiRemapIcon.name` and `MdiRemapIcon.tags` via `searchMdiRemapIcons`; an empty query resolves to the full `allMdiRemapIcons()` registry.
- **Virtualization required at this item count.** The grid (8 columns, 44×44 logical-pixel cells, keyboard-navigable) is hosted with `shrinkWrap: false` inside an `Expanded` section of the surface's bounded `Column`, so only visible-plus-nearby cells are built. The filtered list is memoized and recomputed only when the search text actually changes.
- **Self-display:** the closed field resolves its displayed name via `findMdiRemapIconByName` from the anchor's own text on every build, updated immediately on a fresh pick — so it reflects a committed pick even before the caller feeds a new `value` back in, and equally resolves a name the caller supplies from persisted storage this widget never itself produced.
- **Affordance icon:** `MdiIcons.shapeOutline` on the field's own picker-affordance slot.
