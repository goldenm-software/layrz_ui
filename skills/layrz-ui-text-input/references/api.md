# LayrzTextInput — API Reference

Source: `lib/src/inputs/src/text/text_input.dart`

- `LayrzTextInput` class — line 28

---

## Examples

```dart
// Basic labelled field
LayrzTextInput(
  labelText: 'Email',
  hintText: 'user@example.com',
  keyboardType: TextInputType.emailAddress,
  onChanged: (value) => email = value,
)

// Hint-only, no label (search bars, inline filters)
LayrzTextInput(
  hintText: 'Search…',
  prefixIcon: MdiIcons.magnify,
  onChanged: (value) => query = value,
)

// Required with validation errors
LayrzTextInput(
  labelText: 'Username',
  isRequired: true,
  errors: username.isEmpty ? ['Username is required'] : [],
  onChanged: (value) => username = value,
)

// Read-only picker-style field
LayrzTextInput(
  labelText: 'Date',
  readOnly: true,
  controller: TextEditingController(text: selectedDate?.toString() ?? ''),
  onTap: () => showDatePicker(),
)

// Disabled field
LayrzTextInput(
  labelText: 'Locked field',
  disabled: true,
  controller: TextEditingController(text: 'This field is disabled'),
)

// Obscured (password-shaped) with error list
LayrzTextInput(
  labelText: 'Password',
  isRequired: true,
  obscureText: true,
  errors: validatePassword(password),
  onChanged: (value) => password = value,
)

// Keyboard shortcut badge
LayrzTextInput(
  labelText: 'Command',
  shortcut: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyK},
  onChanged: (value) => command = value,
)

// Narrowed text-selection menu (no cut/paste allowed)
LayrzTextInput(
  labelText: 'Read-mostly field',
  actions: const {LayrzSelectableAction.copy, LayrzSelectableAction.selectAll},
  onChanged: (value) => value = value,
)
```

---

## Constructor

```dart
const LayrzTextInput({
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
  this.onSubmit,
  this.onFocusChanged,
  this.onTap,
  this.controller,
  this.focusNode,
  this.dense = false,
  this.keyboardType = TextInputType.text,
  this.textInputAction,
  this.inputFormatters = const [],
  this.maxLength,
  this.autofocus = false,
  this.textCapitalization = TextCapitalization.none,
  this.autofillHints = const [],
  this.obscureText = false,
  this.autocorrect = true,
  this.enableSuggestions = true,
  this.shortcut,
  this.actions,
  this.textAlign = TextAlign.start,
  this.helperText,
  this.borderRadius,
  this.showBorder = true,
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

Note: the widget also debug-asserts `labelText != null || hintText != null` is NOT literally present as
a constructor assert in source — it is documented and enforced structurally by `LayrzInputChrome`
underneath. Always supply at least one.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String?` | `null` | Label above the field. At least one of `labelText`/`hintText` must be non-null. |
| `hintText` | `String?` | `null` | Placeholder shown when the field is empty and unfocused. |
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
| `errors` | `List<String>` | `[]` | Joined with `", "` inline (≥ `md`), or shown in a tap-tooltip below `md`. |
| `hideDetails` | `bool` | `false` | Hides the error/helper block below the field (the field's own error border still applies). |
| `onChanged` | `ValueChanged<String>?` | `null` | Fires on every text change. |
| `onSubmit` | `ValueChanged<String>?` | `null` | Fires on submit (e.g. Enter / IME done). |
| `onFocusChanged` | `ValueChanged<bool>?` | `null` | Fires on focus gain/loss. |
| `onTap` | `VoidCallback?` | `null` | Fires on tap; ignored when `disabled`, fires even when `readOnly`. |
| `controller` | `TextEditingController?` | `null` | Caller-owned if supplied (never disposed); created+disposed internally otherwise. |
| `focusNode` | `FocusNode?` | `null` | Same disposal contract as `controller`. |
| `dense` | `bool` | `false` | Drops internal padding one ramp (`pd2`→`pd1`). No other geometry changes. |
| `keyboardType` | `TextInputType` | `TextInputType.text` | Soft keyboard type. |
| `textInputAction` | `TextInputAction?` | `null` | IME action button (e.g. `.done`, `.next`). |
| `inputFormatters` | `List<TextInputFormatter>` | `[]` | Standard Flutter text formatters. |
| `maxLength` | `int?` | `null` | Appends a `LengthLimitingTextInputFormatter` and shows a counter. |
| `autofocus` | `bool` | `false` | Requests focus on first build. |
| `textCapitalization` | `TextCapitalization` | `.none` | Soft-keyboard capitalization behavior. |
| `autofillHints` | `List<String>` | `[]` | Platform autofill hints. |
| `obscureText` | `bool` | `false` | Masks the value (e.g. for a raw password field — prefer `LayrzPasswordInput`). |
| `autocorrect` | `bool` | `true` | Soft-keyboard autocorrect. |
| `enableSuggestions` | `bool` | `true` | Soft-keyboard suggestions. |
| `shortcut` | `Set<LogicalKeyboardKey>?` | `null` | Display-only keyboard-shortcut badge; hidden on mobile; binds no functionality. |
| `actions` | `Set<LayrzSelectableAction>?` | `null` | Selection-menu actions offered. `null` = all four (copy/cut/paste/selectAll), further intersected with field state (e.g. obscured never offers copy/cut). Pass `const {}` to suppress entirely. |
| `textAlign` | `TextAlign` | `TextAlign.start` | Alignment of the editable value. |
| `helperText` | `String?` | `null` | Shown below the field; hidden whenever `errors` is non-empty. |
| `borderRadius` | `BorderRadius?` | `null` | Overrides the chrome's corner radius (used by composite inputs like `LayrzNumberInput`). |
| `showBorder` | `bool` | `true` | When `false`, the chrome renders no border (composite-input use only). |

---

## Behavior notes

- **Interaction-state precedence**: disabled > read-only > error > pressed > hover/focused > default. Geometry (border width, padding, radius) is byte-identical across every state — only color/transparency vary (D15).
- **Responsive error rendering**: at `md`+ (≥ 960px) errors render inline, joined by `", "`, with the character counter (if `maxLength` set) beside them. Below `md`, the inline slot is hidden and errors move into a tap-triggered `LayrzTooltip` anchored to the error icon, one message per line. This swap is automatic — never opt-in/out from the caller side.
- **Disposal contract**: a `controller`/`focusNode` supplied by the caller is never disposed by this widget; when omitted, the widget creates and disposes its own.
- **Slot exclusivity is debug-asserted**, not silently resolved — passing two of the prefix (or suffix) trio throws in debug builds.
- **Single-line only**: `maxLines` is always 1 internally; for multiline use `LayrzTextAreaInput`, a distinct widget, not a parameter variant of this one.
- **`LayrzInputChrome` is frozen** — this widget's visual chrome cannot be modified per-call beyond the documented parameters (`borderRadius`, `showBorder`, `dense`). There is no `padding` override.

---

## Companion widgets

The `inputs` module also exports, and composes on top of this widget:

- **`LayrzTextAreaInput`** — multiline variant with `minLines`/`maxLines` growth and internal scrolling.
- **`LayrzNumberInput`** — numeric entry with step buttons (composes the shared chrome directly, not this widget).
- **`LayrzPasswordInput`** — composes `LayrzTextInput` directly, adding an eye-toggle suffix and optional strength meter.
- **`LayrzUsernameInput`** — composes `LayrzTextInput` directly, pre-configured with a shield-account prefix icon and login autofill hints.
