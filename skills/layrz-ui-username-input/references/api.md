# LayrzUsernameInput — API Reference

Source: `lib/src/inputs/src/login/username_input.dart`

- `LayrzUsernameInput` class — line 47
- `kLayrzUsernameInputDefaultAutofillHints` constant — line 18 (`[AutofillHints.username, AutofillHints.email]`)

---

## Examples

```dart
// Basic login form field
LayrzUsernameInput(
  controller: usernameController,
  onSubmit: (_) => passwordFocusNode.requestFocus(),
)

// Required with validation errors
LayrzUsernameInput(
  isRequired: true,
  controller: usernameController,
  errors: usernameErrors,
  onChanged: (value) => usernameErrors = validate(value),
)

// Grouped inside LayrzForm (recommended)
LayrzForm(
  onSubmit: () => authenticate(username, password),
  child: Column(
    children: [
      LayrzUsernameInput(controller: usernameController),
      const SizedBox(height: 12),
      LayrzPasswordInput(controller: passwordController),
    ],
  ),
)

// Custom identifier semantics (e.g. phone number instead of email/username)
LayrzUsernameInput(
  labelText: 'Phone number',
  controller: phoneController,
  autofillHints: const [AutofillHints.telephoneNumber],
)

// Disabled
LayrzUsernameInput(
  controller: usernameController,
  disabled: true,
)
```

---

## Constructor

```dart
const LayrzUsernameInput({
  super.key,
  this.labelText,
  this.hintText,
  this.isRequired = false,
  this.controller,
  this.focusNode,
  this.errors = const [],
  this.disabled = false,
  this.dense = false,
  this.onChanged,
  this.onSubmit,
  this.autofillHints = kLayrzUsernameInputDefaultAutofillHints,
  this.formId,
});
```

No asserts on this constructor.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String?` | `null` | Falls back to `LayrzUiL10n.of(context).loginUsernameLabel` ("Username") when omitted. |
| `hintText` | `String?` | `null` | Placeholder shown when empty. |
| `isRequired` | `bool` | `false` | Renders a red `*` beside the label. |
| `controller` | `TextEditingController?` | `null` | Caller-owned if supplied (never disposed); created+disposed internally otherwise. |
| `focusNode` | `FocusNode?` | `null` | Same disposal contract as `controller`. Not used on the web path. |
| `errors` | `List<String>` | `[]` | Caller-owned validation messages. |
| `disabled` | `bool` | `false` | Not editable, not focusable; callbacks never fire. |
| `dense` | `bool` | `false` | Mirrors `LayrzTextInput.dense` natively; tighter CSS padding scale on web. |
| `onChanged` | `ValueChanged<String>?` | `null` | Fires on every text change. |
| `onSubmit` | `ValueChanged<String>?` | `null` | Fires on submit (e.g. Enter). |
| `autofillHints` | `List<String>` | `kLayrzUsernameInputDefaultAutofillHints` (`[AutofillHints.username, AutofillHints.email]`) | On native flows to `LayrzTextInput.autofillHints`; on web translated to the DOM `autocomplete` value in addition to the base username `type`/`autocomplete` pairing. |
| `formId` | `String?` | `null` | Explicit HTML `<form>` id override for web. Normally resolved automatically from the nearest `LayrzLoginWebGroup`. No effect on native. |

There is no `value` parameter — the widget is fully controller-driven.

---

## Behavior notes

- **Native configuration** (baked in, not overridable per-instance): `prefixIcon: MdiIcons.shieldAccountOutline`, `keyboardType: TextInputType.emailAddress`, `autocorrect: false`, plus `autofillHints: widget.autofillHints`. All other parameters pass straight through to the underlying `LayrzTextInput`.
- **Web configuration**: renders `LayrzLoginWebField` with `kind: LayrzLoginFieldKind.username`, wiring `labelText`/`errors`/`autofillHints`/`disabled`/`dense`, resolving `formId` from the explicit override or the nearest `LayrzLoginWebGroup`.
- **Both platforms expose the identical public API** — never branch on `kIsWeb` yourself when using this widget.
- **Grouping**: on native, wrap both login fields in a Flutter `AutofillGroup` (or prefer `LayrzForm`, which also drives the save commit/discard). On web, wrap both fields in `LayrzLoginWebGroup` (or, again, prefer `LayrzForm`, which does this internally) so they share one HTML `<form>` id.

---

## Companion widgets

- **`LayrzPasswordInput`** — the paired credential-secret field.
- **`LayrzTextInput`** — the base chrome this field composes on native.
- **`LayrzForm`** — the recommended wrapper for grouping + autofill-save commit/discard.
