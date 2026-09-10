# LayrzSelectInput&lt;T&gt; — API Reference

Source: `lib/src/inputs/src/select/select_input.dart` (+ `select_input_surface.dart`, `select_item.dart`)
- `LayrzSelectInput<T>` class — line 67
- `LayrzSelectItem<T>` class — `select_item.dart`, line 20

---

## Examples

```dart
// Basic select
LayrzSelectInput<String>(
  labelText: 'Country',
  itemExtent: 48,
  items: countries.map((c) => LayrzSelectItem(value: c.code, child: Text(c.name))).toList(),
  value: countryCode,
  onChanged: (item) => setState(() => countryCode = item?.value),
)

// Clearable
LayrzSelectInput<String>(
  labelText: 'Assignee',
  itemExtent: 48,
  canUnselect: true,
  items: userItems,
  value: assigneeId,
  onChanged: (item) => setState(() => assigneeId = item?.value),
)

// No search
LayrzSelectInput<int>(
  labelText: 'Priority',
  itemExtent: 40,
  enableSearch: false,
  items: priorityItems,
  value: priority,
  onChanged: (item) => setState(() => priority = item?.value),
)

// Custom filter function
LayrzSelectInput<String>(
  labelText: 'City',
  itemExtent: 48,
  items: cityItems,
  filter: (query, item) => item.searchableStrings.any(
    (s) => s.toLowerCase().startsWith(query.toLowerCase()),
  ),
  value: city,
  onChanged: (item) => setState(() => city = item?.value),
)

// With prefix icon and help tooltip
LayrzSelectInput<String>(
  labelText: 'Timezone',
  itemExtent: 44,
  prefixIcon: MdiIcons.earth,
  helpTitleText: 'Timezone',
  helpContentText: 'Used to schedule reports.',
  items: timezoneItems,
  value: timezone,
  onChanged: (item) => setState(() => timezone = item?.value),
)

// Dense field
LayrzSelectInput<String>(
  labelText: 'Compact select',
  itemExtent: 40,
  dense: true,
  items: items,
  value: value,
  onChanged: (item) => setState(() => value = item?.value),
)
```

---

## Constructor

```dart
const LayrzSelectInput({
  super.key,
  required this.items,
  this.value,
  this.onChanged,
  this.enableSearch = true,
  this.canUnselect = false,
  this.filter,
  this.emptyListText,
  this.labelText,
  this.hintText,
  this.isRequired = false,
  this.prefixIcon,
  this.prefix,
  this.prefixText,
  this.onPrefixTap,
  this.suffixIcon,
  this.suffix,
  this.suffixText,
  this.onSuffixTap,
  this.helpTitleText,
  this.helpContentText,
  this.disabled = false,
  this.errors = const [],
  this.hideDetails = false,
  this.focusNode,
  this.dense = false,
  required this.itemExtent,
}) : assert(
       (prefixIcon == null || prefix == null) &&
           (prefix == null || prefixText == null) &&
           (prefixIcon == null || prefixText == null),
       'At most one of prefixIcon, prefix, or prefixText may be non-null.',
     ),
     assert(
       (suffixIcon == null || suffix == null) &&
           (suffix == null || suffixText == null) &&
           (suffixIcon == null || suffixText == null),
       'At most one of suffixIcon, suffix, or suffixText may be non-null.',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `items` | `List<LayrzSelectItem<T>>` | **required** | The options list. |
| `value` | `T?` | `null` | Currently selected value. |
| `onChanged` | `void Function(LayrzSelectItem<T>?)?` | `null` | Fires on pick or clear, with the picked `LayrzSelectItem` or `null`. |
| `enableSearch` | `bool` | `true` | Whether the opened surface renders its own search field. |
| `canUnselect` | `bool` | `false` | Shows a clear affordance next to the chevron once something is selected. |
| `filter` | `bool Function(String query, LayrzSelectItem<T> item)?` | `null` | Overrides `LayrzSelectItem.matches`. |
| `emptyListText` | `String?` | `null` | Shown when search finds nothing. Falls back to `LayrzUiL10n.selectEmpty`. |
| `labelText` | `String?` | `null` | Label above the field. |
| `hintText` | `String?` | `null` | Placeholder shown when nothing is selected. |
| `isRequired` | `bool` | `false` | Renders a red `*` beside the label. |
| `prefixIcon` | `IconData?` | `null` | Mutually exclusive with `prefix`/`prefixText`. |
| `prefix` | `Widget?` | `null` | Mutually exclusive with `prefixIcon`/`prefixText`. |
| `prefixText` | `String?` | `null` | Mutually exclusive with `prefixIcon`/`prefix`. |
| `onPrefixTap` | `VoidCallback?` | `null` | Fires when the prefix is tapped. |
| `suffixIcon` | `IconData?` | `null` | Mutually exclusive with `suffix`/`suffixText`. Never displaced by the dropdown chevron. |
| `suffix` | `Widget?` | `null` | Mutually exclusive with `suffixIcon`/`suffixText`. |
| `suffixText` | `String?` | `null` | Mutually exclusive with `suffixIcon`/`suffix`. |
| `onSuffixTap` | `VoidCallback?` | `null` | Fires when the suffix is tapped. |
| `helpTitleText` | `String?` | `null` | Title of the two-part help tooltip. |
| `helpContentText` | `String?` | `null` | Content of the two-part help tooltip. |
| `disabled` | `bool` | `false` | Field does not open the surface on tap. |
| `errors` | `List<String>` | `[]` | Rendered below the field regardless of whether `labelText` is set. |
| `hideDetails` | `bool` | `false` | Hides the error message block. |
| `focusNode` | `FocusNode?` | `null` | Internal node created/disposed when omitted. |
| `dense` | `bool` | `false` | `false`: 14px padding compact / 10px regular. `true`: 10px compact / 6px regular. |
| `itemExtent` | `double` | **required** | Expected row height inside the opened list. |

---

## Companion type: `LayrzSelectItem<T>`

```dart
const LayrzSelectItem({
  required this.value,
  required this.child,
  this.searchableStrings = const {},
});
```

| Field | Type | Notes |
|---|---|---|
| `value` | `T?` | The typed value handed back on selection. Nullable — selecting an item with `value: null` clears the selection. |
| `child` | `Widget` | **Required.** The item's only presentation — rendered identically in the list and in the field itself while idle. |
| `searchableStrings` | `Set<String>` | The **only** thing search matches against — `child`'s rendered text is not implicitly searchable. An empty set means the item can never be found by search (it still renders normally). |

Also exposes `copyWith(...)` and `bool matches(String query)` (case-insensitive substring match against `searchableStrings`; empty/whitespace query matches everything).

---

## Behavior notes

- **Selection surface**: `LayrzResponsiveModal.show` resolves to a `LayrzDialog` (`maxWidth: 600, maxHeight: 760`) on desktop (`≥960px`) or a `LayrzBottomSheet` (non-scrollable, since the surface owns its own scroll) below that. The surface renders a `LayrzPickerDialogHeader` (title = `labelText`, inline dense search, close "X") pinned above a scrolling `ListView` — no `actions` row.
- **Field is always read-only**: it never accepts typed input on either `enableSearch` value. All typing happens in the opened surface's own search field.
- **Self-display**: `_displayedValue` (internal state) updates immediately on pick, independent of whether the caller re-feeds `value`. `didUpdateWidget` still reconciles an externally-changed `value`.
- **`RichText` trap**: `child` renders under a forced ambient `DefaultTextStyle`. `Text`/`Text.rich` inherit it; a raw `RichText` does not — its `TextSpan` paints with no colour if unset, which the engine renders solid white. Use `Text.rich`, never raw `RichText`, for multi-styled-run content.
- **Whole chrome is tappable**: a `LayrzTappable` fallback wraps the chrome so tapping the label or padding (not just the text) opens the surface, while a tap on the text itself still places a cursor / long-press still shows selection handles on the (always-empty) internal controller.
- **No `dialogConstraints`, `overrideHeightDialog`, `autoclose`, `autoSelectFirst`, or `returnNullOnClose`** — none of these parameters exist on the shipped widget, despite appearing in older pre-implementation sketches.
