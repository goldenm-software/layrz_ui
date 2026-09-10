# LayrzMultiSelectInput\<T\> — API Reference

Source: `lib/src/pickers/src/multi_select/multi_select_input.dart`
- `LayrzMultiSelectInput<T>` class — line 67
- `_MultiSelectDrawerActions` (private, Cancel/Select-All(Unselect-All)/Save row) — line 446

---

## Examples

```dart
// Minimal
LayrzMultiSelectInput<String>(
  labelText: 'Favorite fruits',
  items: fruitItems,
  value: selectedFruits,
  itemExtent: 52,
  onChanged: (values) => setState(() => selectedFruits = values),
)

// Required with errors
LayrzMultiSelectInput<String>(
  labelText: 'Tags',
  isRequired: true,
  items: tagItems,
  value: selectedTags,
  itemExtent: 52,
  errors: selectedTags.isEmpty ? ['Select at least one tag'] : const [],
  onChanged: (values) => setState(() => selectedTags = values),
)

// Custom search filter
LayrzMultiSelectInput<String>(
  labelText: 'Devices',
  items: deviceItems,
  value: selectedDevices,
  itemExtent: 52,
  filter: (query, item) => item.searchableStrings.any(
    (s) => s.toLowerCase().startsWith(query.toLowerCase()),
  ),
  onChanged: (values) => setState(() => selectedDevices = values),
)

// Search disabled
LayrzMultiSelectInput<String>(
  labelText: 'Priority',
  items: priorityItems,
  value: selectedPriorities,
  itemExtent: 52,
  enableSearch: false,
  onChanged: (values) => setState(() => selectedPriorities = values),
)

// Disabled
LayrzMultiSelectInput<String>(
  labelText: 'Locked tags',
  items: tagItems,
  value: selectedTags,
  itemExtent: 52,
  disabled: true,
)
```

---

## Constructor

```dart
const LayrzMultiSelectInput({
  super.key,
  required this.items,
  this.value = const [],
  this.onChanged,
  this.enableSearch = true,
  this.filter,
  this.emptyListText,
  this.labelText,
  this.hintText,
  this.isRequired = false,
  this.helpTitleText,
  this.helpContentText,
  this.disabled = false,
  this.errors = const [],
  this.hideDetails = false,
  this.controller,
  this.focusNode,
  this.dense = false,
  required this.itemExtent,
}) : assert(
       labelText != null || hintText != null,
       'At least one of labelText or hintText must be non-null.',
     ),
     assert(
       itemExtent >= kLayrzPickerMinItemExtent,
       'itemExtent must be >= $kLayrzPickerMinItemExtent to fit the row content (checkbox + padding) '
       'without a vertical overflow.',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `items` | `List<LayrzSelectItem<T>>` | — (required) | The items to choose from. Same `LayrzSelectItem<T>` type shared verbatim with `LayrzSelectInput`. |
| `value` | `List<T>` | `[]` | The currently selected values. May be empty. Feeding this back after `onChanged` fires is not required for the field's own display to update (self-display), but a caller-supplied change is still honored. |
| `onChanged` | `ValueChanged<List<T>>?` | `null` | Fired once, when the user presses Save, with the full drafted list. Never called for a row tap, Select All, Unselect All, or Cancel. |
| `enableSearch` | `bool` | `true` | Whether the opened surface renders its own search field. When `false`, arrow keys alone navigate the list. |
| `filter` | `bool Function(String query, LayrzSelectItem<T> item)?` | `null` | Optional custom filter for search results. When `null`, uses `LayrzSelectItem.matches`. |
| `emptyListText` | `String?` | `null` | Text shown when the search finds no matching items. Defaults to localized `LayrzUiL10n.selectEmpty`. |
| `labelText` | `String?` | `null` | The label text displayed above the field. One of `labelText`/`hintText` is required. |
| `hintText` | `String?` | `null` | Placeholder shown when the field has no selection. |
| `isRequired` | `bool` | `false` | Whether the field is marked as required. |
| `helpTitleText` | `String?` | `null` | Title text for the help affordance tooltip. |
| `helpContentText` | `String?` | `null` | Content text for the help affordance tooltip. |
| `disabled` | `bool` | `false` | Whether the field is disabled. Disabled fields do not open the surface on tap. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the field. |
| `hideDetails` | `bool` | `false` | Whether to hide the error/help detail block. |
| `controller` | `TextEditingController?` | `null` | The anchor field's text controller. Never fed the joined label text — read only for the chrome's own hint-visibility bookkeeping. Created and disposed internally if omitted. |
| `focusNode` | `FocusNode?` | `null` | The anchor field's focus node. Created and disposed internally if omitted. |
| `dense` | `bool` | `false` | Whether the field uses the dense density variant. |
| `itemExtent` | `double` | — (required) | Expected height of each item in the opened surface's list. Must be `>= kLayrzPickerMinItemExtent` (52px) — a full `LayrzCheckboxInput` row is 40px tall plus padding; asserted at construction. |

---

## Behavior notes

- **Commit model — staged-with-Save, unconditionally (deliberate divergence from `ThemedMultiSelectInput`).** `ThemedMultiSelectInput` commits per tap by default; `waitUntilClosedToSubmit` no longer exists as a flag here — the staged behavior is the *only* behavior. The opened surface's Cancel / Select-All(Unselect-All) / Save row:
  - a row tap toggles the surface's internal draft only — no callback, no close;
  - "Select all" / "Unselect all" mutate the same draft only — the middle button's label swaps between the two based on whether the draft currently has any selection;
  - **Save** is the only action that calls `onChanged` (with the full drafted list) and closes the surface;
  - **Cancel** closes without calling `onChanged`, discarding every tap since opening.
- **Container:** opens through `LayrzResponsiveModal.show` — a centered `LayrzDialog` (`maxWidth: 600, maxHeight: 760`) at `>= 960px`, a `LayrzBottomSheet` below that (`initialSize: 0.6, maxSize: 0.9, snapSizes: [0.6, 0.9]`, `scrollable: false`). The surface renders a `LayrzPickerDialogHeader` (title, inline search when `enableSearch` is true, close "X") pinned above a checkbox-per-row scrolling list.
- **"All (count)" / "Selected (count)" tabs (DESIGN-43):** a light re-filter strip between the header divider and the list — not a second content tree, and not `LayrzTabView` (which would fight the pinned-header layout). "All" is every item (or search match); "Selected" is only items currently in the draft. Both counts update live. This exists specifically to support `LayrzDualListInput`'s compact-viewport delegation.
- **Closed field display:** comma-joined `LayrzSelectItem.child` text content (e.g. `"Apple, Banana, Cherry"`), ellipsized on overflow — deliberately not a count (loses which items) and not chips (needs unbounded vertical room). Extracted by inspecting each selected item's `child` for `Text`/`RichText`; a non-textual `child` contributes an empty string rather than being silently dropped.
- **Self-display:** the field renders from its own internal `_displayedValues`, updated immediately when Save commits, independent of whether the caller feeds an updated `value` back on the next build. A caller-supplied `value` change is still honored via `didUpdateWidget`.
- **Migration from `ThemedMultiSelectInput<T>` (BREAKING):** `waitUntilClosedToSubmit`, `autoclose`, `dialogConstraints`, `hideTitle`, `translations`, `overridesLayrzTranslations`, `autoselectFirst`, and `customChild` are all removed. `itemExtent` is now **required** (previously defaulted to `50`).
