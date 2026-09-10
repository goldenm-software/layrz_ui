# LayrzComboBoxInput — API Reference

Source: `lib/src/inputs/src/combobox/combobox_input.dart` (+ `combobox_surface.dart`)
- `LayrzComboBoxInput` class — line 64

---

## Examples

```dart
// Basic combobox
LayrzComboBoxInput(
  labelText: 'City',
  options: cityNames,
  value: city,
  onChanged: (value) => setState(() => city = value),
)

// Restricted to existing options (no free-form)
LayrzComboBoxInput(
  labelText: 'Category',
  options: categories,
  allowFreeForm: false,
  value: category,
  onChanged: (value) => setState(() => category = value),
)

// React only to deliberate commits, not every keystroke
LayrzComboBoxInput(
  labelText: 'Add tag',
  options: existingTags,
  onSubmit: (value) => addTag(value),
)

// Custom empty-results text
LayrzComboBoxInput(
  labelText: 'Airport',
  options: airportCodes,
  emptyOptionsText: 'No matching airports',
  value: airport,
  onChanged: (value) => setState(() => airport = value),
)

// With prefix icon, suffix icon, and help tooltip
LayrzComboBoxInput(
  labelText: 'Company',
  options: companyNames,
  prefixIcon: MdiIcons.officeBuildingOutline,
  helpTitleText: 'Company',
  helpContentText: 'Type to search or enter a new company.',
  value: company,
  onChanged: (value) => setState(() => company = value),
)

// Dense field, disabled autocomplete filtering
LayrzComboBoxInput(
  labelText: 'Any option',
  options: options,
  enableAutocomplete: false,
  dense: true,
  value: value,
  onChanged: (value) => setState(() => value = value),
)
```

---

## Constructor

```dart
const LayrzComboBoxInput({
  required this.options,
  super.key,
  this.value,
  this.onChanged,
  this.onSubmit,
  this.allowFreeForm = true,
  this.emptyOptionsText,
  this.enableAutocomplete = true,
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
  this.readOnly = false,
  this.errors = const [],
  this.hideDetails = false,
  this.controller,
  this.focusNode,
  this.dense = false,
  this.keyboardType = TextInputType.text,
  this.textInputAction,
  this.inputFormatters = const [],
  this.actions,
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
| `options` | `List<String>` | **required** | Autocomplete suggestions matched against the typed text. |
| `value` | `String?` | `null` | Current text content. |
| `onChanged` | `ValueChanged<String>?` | `null` | Fires once per genuine text change — keystroke, external `value` push, or a commit whose text differs from what was shown. |
| `onSubmit` | `ValueChanged<String>?` | `null` | Fires on **every** commit, unconditionally — including a same-value re-selection. |
| `allowFreeForm` | `bool` | `true` | Whether typed text not matching any option can still be committed. |
| `emptyOptionsText` | `String?` | `null` | Shown when the filtered options list is empty. Falls back to `LayrzUiL10n.comboboxEmpty`. |
| `enableAutocomplete` | `bool` | `true` | Whether filtering by typed text is applied at all. |
| `labelText` | `String?` | `null` | Label above the field. |
| `hintText` | `String?` | `null` | Placeholder text. |
| `isRequired` | `bool` | `false` | Renders a red `*` beside the label. |
| `prefixIcon` | `IconData?` | `null` | Mutually exclusive with `prefix`/`prefixText`. |
| `prefix` | `Widget?` | `null` | Mutually exclusive with `prefixIcon`/`prefixText`. |
| `prefixText` | `String?` | `null` | Mutually exclusive with `prefixIcon`/`prefix`. |
| `onPrefixTap` | `VoidCallback?` | `null` | Fires when the prefix is tapped (ignored if disabled). |
| `suffixIcon` | `IconData?` | `null` | Mutually exclusive with `suffix`/`suffixText`. |
| `suffix` | `Widget?` | `null` | Mutually exclusive with `suffixIcon`/`suffixText`. |
| `suffixText` | `String?` | `null` | Mutually exclusive with `suffixIcon`/`suffix`. |
| `onSuffixTap` | `VoidCallback?` | `null` | Fires when the suffix is tapped (ignored if disabled). |
| `helpTitleText` | `String?` | `null` | Title of the two-part help tooltip. |
| `helpContentText` | `String?` | `null` | Content of the two-part help tooltip. |
| `disabled` | `bool` | `false` | Field does not accept input or open the surface. |
| `readOnly` | `bool` | `false` | Field does not accept typed input but still opens the surface on tap. |
| `errors` | `List<String>` | `[]` | Rendered below the field regardless of whether `labelText` is set. |
| `hideDetails` | `bool` | `false` | Hides the error message block. |
| `controller` | `TextEditingController?` | `null` | Internal one created/disposed when omitted. |
| `focusNode` | `FocusNode?` | `null` | Internal one created/disposed when omitted. |
| `dense` | `bool` | `false` | `false`: 14px padding compact / 10px regular. `true`: 10px compact / 6px regular — same on both the closed field and the opened surface's row. |
| `keyboardType` | `TextInputType` | `TextInputType.text` | Keyboard type for the field. |
| `textInputAction` | `TextInputAction?` | `null` | Text input action (e.g. `.done`, `.search`). |
| `inputFormatters` | `List<TextInputFormatter>` | `[]` | Applied to the field's input. |
| `actions` | `Set<LayrzSelectableAction>?` | `null` | Narrows the text-selection context menu. `null` offers all four built-ins (copy/cut/paste/selectAll); pass `const {}` to suppress the toolbar entirely. |

---

## Behavior notes

- **Selection callbacks disagree by design**: `onChanged` answers "did the text change?" (silent on a same-value re-selection); `onSubmit` answers "did the user just commit?" (fires every time, unconditionally). A caller reacting to "user made a selection" — even a repeated one — must use `onSubmit`.
- **Surface**: `LayrzResponsiveModal.show` resolves to a `LayrzDialog` (`maxWidth: 600, maxHeight: 760`) on desktop or a non-scrollable `LayrzBottomSheet` on mobile, both hosting the same `BottomSheetContent` widget with its own independent search field, starting empty on every open. The full `options` pool is always reachable — never pre-filtered by the closed field's own text.
- **Bold custom-value row**: rendered first in the surface, in `FontWeight.w600`, when the typed search text matches no existing option case-insensitively; omitted when the search text is empty or exactly matches an option. Tapping it commits the exact typed text (user's own casing).
- **Keyboard**: Enter on the closed field opens the surface (mirrors arrow-down); once the surface is open, arrow keys navigate its rows (the custom-value row counts as row 0 when present) and Enter commits the highlighted row.
- **No `position`/`LComboboxPosition` parameter** — the surface is always the dialog/sheet described above, never an above/below anchored overlay. No `label` widget, no `placeholder` (`hintText` only), no `prefixWidget`/`suffixWidget` (`prefix`/`suffix` instead), and no `textStyle` parameter.
- **Disposal contract**: when `controller`/`focusNode` is `null`, the widget creates and disposes its own instance; a caller-supplied instance is never disposed.
