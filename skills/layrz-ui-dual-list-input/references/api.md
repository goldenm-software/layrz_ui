# LayrzDualListInput\<T\> — API Reference

Source: `lib/src/pickers/src/dual_list/dual_list_input.dart`
- `LayrzDualListInput<T>` class — line 46

**The wiki page for this component is a pre-implementation design sketch** (derived from `layrz_theme.ThemedDualListInput`) that predates the shipped API — several of its parameters (`compareFunction`, `mobileScaleFactor`, optional panel names) do not exist on the shipped widget. This reference describes the shipped `lib/src/pickers/src/dual_list/dual_list_input.dart` implementation only; **code wins**.

---

## Examples

```dart
// Minimal
LayrzDualListInput<String>(
  labelText: 'Team members',
  items: memberItems,
  value: selectedIds,
  itemExtent: 52,
  availableListName: 'Available',
  selectedListName: 'Selected',
  onChanged: (values) => setState(() => selectedIds = values),
)

// Required with errors
LayrzDualListInput<String>(
  labelText: 'Team members',
  isRequired: true,
  items: memberItems,
  value: selectedIds,
  itemExtent: 52,
  availableListName: 'Available',
  selectedListName: 'Selected',
  errors: selectedIds.isEmpty ? ['Select at least one member'] : const [],
  onChanged: (values) => setState(() => selectedIds = values),
)

// Disabled
LayrzDualListInput<String>(
  labelText: 'Team members',
  items: memberItems,
  value: selectedIds,
  itemExtent: 52,
  availableListName: 'Available',
  selectedListName: 'Selected',
  disabled: true,
  onChanged: (values) => setState(() => selectedIds = values),
)

// Search disabled on one panel
LayrzDualListInput<String>(
  labelText: 'Team members',
  items: memberItems,
  value: selectedIds,
  itemExtent: 52,
  availableListName: 'Available',
  selectedListName: 'Selected',
  enableSelectedSearch: false,
  onChanged: (values) => setState(() => selectedIds = values),
)
```

---

## Constructor

```dart
const LayrzDualListInput({
  super.key,
  required this.items,
  this.value = const [],
  this.onChanged,
  this.labelText,
  this.hintText,
  this.isRequired = false,
  this.disabled = false,
  this.errors = const [],
  this.hideDetails = false,
  this.helpTitleText,
  this.helpContentText,
  this.enableAvailableSearch = true,
  this.enableSelectedSearch = true,
  required this.itemExtent,
  this.emptyListText,
  required this.availableListName,
  required this.selectedListName,
}) : assert(
       labelText != null || hintText != null,
       'At least one of labelText or hintText must be non-null.',
     ),
     assert(
       itemExtent >= kLayrzPickerMinItemExtent,
       'itemExtent must be >= $kLayrzPickerMinItemExtent; DualList delegates to '
       'MultiSelect on compact, whose checkbox row needs this height',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `items` | `List<LayrzSelectItem<T>>` | — (required) | All items to choose from. Same `LayrzSelectItem<T>` type used by `LayrzSelectInput`/`LayrzMultiSelectInput`. |
| `value` | `List<T>` | `[]` | Currently selected values, in "Selected"-panel display order. An item is selected exactly when its value is a member of this list (equality-based). |
| `onChanged` | `ValueChanged<List<T>>?` | `null` | Fired on every transfer — a single row tap, or a move-all action — with the full, newly-ordered list. No staged draft, no Cancel/Save. |
| `labelText` | `String?` | `null` | The label text displayed above the field. One of `labelText`/`hintText` is required. |
| `hintText` | `String?` | `null` | Currently unused by the desktop two-panel surface (no closed/idle state); forwarded to the compact `LayrzMultiSelectInput` delegate, whose anchor field does render it. |
| `isRequired` | `bool` | `false` | Whether the field is marked as required. |
| `disabled` | `bool` | `false` | Disables both panels' rows and the move-all affordances; delegates `disabled: true` to the compact path too. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the field. |
| `hideDetails` | `bool` | `false` | Whether to hide the error message block. |
| `helpTitleText` | `String?` | `null` | **Desktop v1 limitation:** the always-visible surface has no anchor field to attach a tooltip trigger to, so this only takes effect on the compact `LayrzMultiSelectInput` delegate. Accepted but has no visible effect on desktop. |
| `helpContentText` | `String?` | `null` | See `helpTitleText` — same desktop v1 limitation. |
| `enableAvailableSearch` | `bool` | `true` | Whether the desktop "Available" panel renders its own search field. |
| `enableSelectedSearch` | `bool` | `true` | Whether the desktop "Selected" panel renders its own search field. |
| `itemExtent` | `double` | — (required) | Expected row height in both desktop panels, and forwarded to the compact delegate's own `itemExtent`. Must be `>= kLayrzPickerMinItemExtent` (52px) — asserted at construction. |
| `emptyListText` | `String?` | `null` | Text shown when a panel has no items (empty partition or no search match). Defaults to localized `LayrzUiL10n.selectEmpty`. |
| `availableListName` | `String` | — (required) | Label for the left ("Available") panel. **Required, no localized fallback.** |
| `selectedListName` | `String` | — (required) | Label for the right ("Selected") panel. **Required, no localized fallback.** |

There is no `compareFunction`, `mobileScaleFactor`, `translations`, or `overridesLayrzTranslations` parameter on the shipped widget, despite these appearing in the wiki's pre-implementation sketch — do not pass them.

---

## Behavior notes

- **Compact delegation (`< 960px`):** renders `LayrzMultiSelectInput<T>` instead of the two-panel surface, forwarding `items`, the field's own live-selected state, `onChanged`, `labelText`, `hintText`, `isRequired`, `disabled`, `errors`, `hideDetails`, `helpTitleText`, `helpContentText`, `emptyListText`, and `itemExtent`. `LayrzMultiSelectInput`'s own "All (count)" / "Selected (count)" tabs exist specifically to support this delegation, so a mobile user can still see what they've selected without a side-by-side layout.
- **Transfer mechanic (v1): tap-to-move + move-all, no drag/reorder.** Tapping a row in either panel moves it immediately (no staging, mirroring `ThemedDualListInput`'s always-live semantics rather than `LayrzMultiSelectInput`'s staged-with-Save model). Two move-all affordances between the panels move every currently-visible (search-filtered) item across in one action. Drag-and-drop transfer and within-"Selected" reordering are explicitly out of scope for this version — `value`'s order always reflects `items`' own declared order.
- **Panels read as input surfaces:** each panel paints `tokens.colors.sf2` as its background, matching the enabled-state resolution every other layrz_ui input uses.
- **Move-all buttons switch style with content:** the two chevron transfer buttons render as `LayrzButtonStyle.filledFab` when there is something on their side to move, and `LayrzButtonStyle.textFab` when empty (or the whole field is disabled).
- **Item type:** items are the shared `LayrzSelectItem<T>` (from `lib/src/inputs/src/select/select_item.dart`) — the same type `LayrzSelectInput`/`LayrzMultiSelectInput` use. "Available" shows items **not** in `value`; "Selected" shows items that **are**, both narrowed from the same `items` list.
- **Fixed surface height:** 400 logical pixels for the two-panel area — not a caller-configurable parameter in this version.
