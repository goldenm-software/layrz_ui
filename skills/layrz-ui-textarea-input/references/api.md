# LayrzTextAreaInput — API Reference

Source: `lib/src/inputs/src/text/textarea_input.dart`

- `LayrzTextAreaInput` class — line 38

---

## Examples

```dart
// Basic multiline description
LayrzTextAreaInput(
  labelText: 'Description',
  errors: descriptionErrors,
  onChanged: (value) => description = value,
)

// Length-capped with counter
LayrzTextAreaInput(
  labelText: 'Bio',
  maxLength: 280,
  onChanged: (value) => bio = value,
)

// Fewer lines than the default
LayrzTextAreaInput(
  labelText: 'Short comment',
  minLines: 2,
  maxLines: 4,
  onChanged: (value) => comment = value,
)

// With prefix icon and help affordance
LayrzTextAreaInput(
  labelText: 'Internal notes',
  prefixIcon: MdiIcons.notebookOutline,
  helpTitleText: 'Visibility',
  helpContentText: 'Only visible to your team.',
  onChanged: (value) => notes = value,
)

// Read-only rendered content
LayrzTextAreaInput(
  labelText: 'Change log',
  readOnly: true,
  controller: TextEditingController(text: changeLog),
)

// Disabled
LayrzTextAreaInput(
  labelText: 'Locked notes',
  disabled: true,
  controller: TextEditingController(text: 'Cannot edit this'),
)
```

---

## Constructor

```dart
const LayrzTextAreaInput({
  super.key,
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
  this.onChanged,
  this.onFocusChanged,
  this.onTap,
  this.controller,
  this.focusNode,
  this.dense = false,
  this.keyboardType = TextInputType.multiline,
  this.textInputAction = TextInputAction.newline,
  this.inputFormatters = const [],
  this.maxLength,
  this.minLines = 3,
  this.maxLines = 10,
  this.autofocus = false,
  this.textCapitalization = TextCapitalization.none,
  this.autofillHints = const [],
  this.autocorrect = true,
  this.enableSuggestions = true,
  this.actions,
}) : assert(minLines > 0, 'minLines must be a positive integer.'),
     assert(maxLines > 0, 'maxLines must be a positive integer.'),
     assert(minLines <= maxLines, 'minLines ($minLines) must not exceed maxLines ($maxLines).'),
     assert(
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
| `labelText` | `String?` | `null` | Label above the field. There is no `label` widget parameter — `labelText` only. |
| `hintText` | `String?` | `null` | Placeholder shown when empty and unfocused. |
| `isRequired` | `bool` | `false` | Renders a red `*` beside the label. |
| `prefixIcon` | `IconData?` | `null` | Mutually exclusive with `prefix`/`prefixText`. |
| `prefix` | `Widget?` | `null` | Mutually exclusive with `prefixIcon`/`prefixText`. |
| `prefixText` | `String?` | `null` | Mutually exclusive with `prefixIcon`/`prefix`. |
| `onPrefixTap` | `VoidCallback?` | `null` | Fires on prefix tap; ignored when `disabled`. |
| `suffixIcon` | `IconData?` | `null` | Mutually exclusive with `suffix`/`suffixText`. |
| `suffix` | `Widget?` | `null` | Mutually exclusive with `suffixIcon`/`suffixText`. |
| `suffixText` | `String?` | `null` | Mutually exclusive with `suffixIcon`/`suffix`. |
| `onSuffixTap` | `VoidCallback?` | `null` | Fires on suffix tap; ignored when `disabled`. |
| `helpTitleText` | `String?` | `null` | Title of the help-affordance tooltip. |
| `helpContentText` | `String?` | `null` | Body of the help-affordance tooltip. |
| `disabled` | `bool` | `false` | Not editable, not tappable; callbacks never fire. |
| `readOnly` | `bool` | `false` | Not editable, but `onTap` still fires; shows a lock icon in the suffix. |
| `errors` | `List<String>` | `[]` | Same responsive rendering as `LayrzTextInput` (inline ≥ `md`, tooltip below). |
| `hideDetails` | `bool` | `false` | Hides the error/helper block below the field. |
| `onChanged` | `ValueChanged<String>?` | `null` | Fires on every text change. |
| `onFocusChanged` | `ValueChanged<bool>?` | `null` | Fires on focus gain/loss. |
| `onTap` | `VoidCallback?` | `null` | Fires on tap; ignored when `disabled`, fires even when `readOnly`. |
| `controller` | `TextEditingController?` | `null` | Caller-owned if supplied (never disposed); created+disposed internally otherwise. |
| `focusNode` | `FocusNode?` | `null` | Same disposal contract as `controller`. |
| `dense` | `bool` | `false` | Drops internal padding one ramp (`pd2`→`pd1`), identically on every viewport. |
| `keyboardType` | `TextInputType` | `TextInputType.multiline` | Soft keyboard type. |
| `textInputAction` | `TextInputAction?` | `TextInputAction.newline` | Enter inserts a newline rather than submitting. |
| `inputFormatters` | `List<TextInputFormatter>` | `[]` | Standard Flutter text formatters. |
| `maxLength` | `int?` | `null` | Appends a `LengthLimitingTextInputFormatter` and auto-renders a character counter. |
| `minLines` | `int` | `3` | Must be positive and ≤ `maxLines`. |
| `maxLines` | `int` | `10` | Must be positive and ≥ `minLines`. Field scrolls internally once exceeded. |
| `autofocus` | `bool` | `false` | Requests focus on first build. |
| `textCapitalization` | `TextCapitalization` | `.none` | Soft-keyboard capitalization behavior. |
| `autofillHints` | `List<String>` | `[]` | Platform autofill hints. |
| `autocorrect` | `bool` | `true` | Soft-keyboard autocorrect. |
| `enableSuggestions` | `bool` | `true` | Soft-keyboard suggestions. |
| `actions` | `Set<LayrzSelectableAction>?` | `null` | Selection-menu actions offered; `null` = all four, intersected with field state. Pass `const {}` to suppress. |

There is **no** `obscureText`, `onSubmit`, `label` (widget), `placeholder`, `prefixWidget`/`suffixWidget`,
or `showCharacterCount` parameter on this widget — do not invent them.

---

## Behavior notes

- **Line-limited scrolling**: content beyond `maxLines` scrolls internally rather than continuing to grow the field's height.
- **Enter key**: inserts a newline by default; this is not a form-submit widget. If you need submit-on-Enter, handle it at a layer above (e.g. a `Focus`/`Shortcuts` wrapper), not via this widget's API.
- **Character limit**: setting `maxLength` both enforces the limit via formatter and renders the counter — there is no way to show the counter without also capping input, and no way to disable auto-rendering.
- **Composition**: composes the same shared `LayrzInputChrome` + `LayrzEditableField` primitives as `LayrzTextInput` (via `LayrzInputChrome.variableHeight`, which sizes the chrome from `minLines`/`maxLines` instead of a single fixed line height) — visual and interaction-state parity with the rest of the input family is guaranteed by construction, not by convention.
- **Disposal contract**: identical to `LayrzTextInput` — caller-supplied `controller`/`focusNode` are never disposed by this widget.

---

## Companion widgets

- **`LayrzTextInput`** — the single-line sibling; same slot/error/chrome contract.
- **`LayrzNumberInput`** — numeric entry with step buttons, for numeric rather than free-text values.
