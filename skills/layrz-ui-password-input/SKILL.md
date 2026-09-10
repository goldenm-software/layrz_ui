---
name: layrz-ui-password-input
description: Use LayrzPasswordInput in a layrz_ui Flutter widget. Apply when adding a credential-secret field for login or registration — built-in eye show/hide toggle, opt-in live strength meter (showStrengthMeter) with a 4-segment bar and requirement checklist, and password-manager autofill hints.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- The password field of a login form — leave `showStrengthMeter` at its default `false`; scoring a password the user already chose and cannot edit from that screen is noise, not guidance.
- The password field of a registration/password-creation flow — pass `showStrengthMeter: true` so the live 4-segment bar and requirement checklist help the user pick a stronger value as they type.
- **Do not use** for a general "secret text" field with different rules — compose `LayrzTextInput` with `obscureText: true` directly if the strength-meter rules or the fixed shield-key icon don't apply.
- **Do not use** for the username/email half of a login form — use `LayrzUsernameInput`, its paired sibling.
- Always pair with `LayrzUsernameInput` inside a `LayrzForm` (or a raw `AutofillGroup` on native) so the browser/OS treats both fields as one credential set.

---

## Minimal usage

```dart
LayrzPasswordInput(
  controller: passwordController,
  errors: passwordErrors,
  onChanged: (value) {
    password = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- **Obscured by default, with a built-in eye toggle** — no `obscureText` parameter exists; visibility is entirely internal state, toggled by the suffix eye icon. You never manage it yourself.
- **`labelText` falls back to a localized "Password"** (`LayrzUiL10nPasswordMixin.loginPasswordLabel`) when omitted — you rarely need to pass it explicitly.
- **`showStrengthMeter` defaults to `false`** — it is opt-in. When `true`, a full-width 4-segment strength bar plus a live requirement checklist (lowercase, uppercase, digit, special character) renders below the field, re-scoring on every keystroke.
- **The strength rules are fixed**, not caller-configurable: valid requires all four character classes; the 0–4 level is then derived purely from length (`<8`→0, `8–11`→1, `12–15`→2, `16–19`→3, `≥20`→4). There is no way to customize thresholds or required classes from this widget.
- **Web renders a real HTML `<input>`** internally (so browser password managers can detect/fill it) while native renders `LayrzTextInput` directly — both expose the identical public API; you never branch on platform yourself.
- `autofillHints` defaults to `[AutofillHints.password]`; override only for a password-creation-specific hint set.
- There is no `value`/`placeholder`/`borderRadius`/`onSubmitted`/`padding` parameter — the widget is fully controller-driven with `onChanged`/`onSubmit`, matching every other layrz_ui input.

---

## Common patterns

```dart
// 1. Login password field (no strength meter)
LayrzPasswordInput(
  controller: passwordController,
  errors: passwordErrors,
  onSubmit: (_) => form.submit(),
  onChanged: (value) => password = value,
)

// 2. Registration password field with live strength meter
LayrzPasswordInput(
  labelText: 'Create a password',
  isRequired: true,
  controller: newPasswordController,
  showStrengthMeter: true,
  autofillHints: const [AutofillHints.newPassword],
  errors: passwordErrors,
  onChanged: (value) => newPassword = value,
)

// 3. Paired with LayrzUsernameInput inside LayrzForm
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

// 4. Using the standalone strength meter/requirements outside this widget
final requirements = LayrzPasswordRequirements.evaluate(candidatePassword);
if (!requirements.isValid) {
  // block submission, surface requirements.strengthLevel to the user
}
```

---

## `LayrzPasswordStrengthLevel` enum (via `LayrzPasswordRequirements.strengthLevel`)

| Value | Meaning |
|---|---|
| `.invalid` | Empty, missing a required character class, or contains a disallowed character. |
| `.veryWeak` | Valid but shorter than 8 characters. |
| `.weak` | Valid, 8–11 characters. |
| `.medium` | Valid, 12–15 characters. |
| `.strong` | Valid, 16–19 characters. |
| `.veryStrong` | Valid, 20+ characters. |

---

## Form conventions

- Guard async `onChanged`/`onSubmit` follow-ups with `if (context.mounted)` before calling the parent callback.
- Pass `errors: <List<String>>` from your own server/validation state — there is no `context.getErrors`.
- Always drive actual form submission through `LayrzForm.submit()`, not this widget's `onSubmit` alone — `LayrzForm` is what commits or discards the pending password-manager save.
- Set `showStrengthMeter: true` only on flows where the user is choosing a new password; leave it `false` on login.
- Localize `labelText` only if the default `LayrzUiL10n` "Password" string doesn't fit your flow (e.g. "New password", "Confirm password").
