---
name: layrz-ui-username-input
description: Use LayrzUsernameInput in a layrz_ui Flutter widget. Apply when adding the credential-identifier field of a login form — pre-wired shield-account icon, email keyboard, autocorrect off, and username/email autofill hints for browser and OS password managers.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- The username/email field of a login or sign-up form, always paired with `LayrzPasswordInput`.
- **Do not use** for a general text field that happens to hold a username unrelated to authentication (e.g. a "display name" profile field) — use `LayrzTextInput` directly; this widget is opinionated specifically for the login-credential-identifier role (icon, keyboard, autofill hints).
- **Do not use** for the password half — use `LayrzPasswordInput`.
- Wrap both login fields in a `LayrzForm` so autofill commit/discard and platform grouping are handled correctly — see `layrz-ui-form`.

---

## Minimal usage

```dart
LayrzUsernameInput(
  controller: usernameController,
  onSubmit: (_) => passwordFocusNode.requestFocus(),
)
```

---

## Key behaviors

- **`labelText` falls back to a localized "Username"** (`LayrzUiL10nPasswordMixin.loginUsernameLabel`) when omitted.
- **Pre-configured natively** with `prefixIcon: shieldAccountOutline`, `keyboardType: TextInputType.emailAddress` (so `@` is easily reachable), and `autocorrect: false` — none of these are parameters you set yourself; they're baked in.
- **`autofillHints` defaults to both `[AutofillHints.username, AutofillHints.email]`** together — the email hint is additionally required by some password managers (e.g. Dashlane) to match the field when the identifier is an email address. Override only for a different identifier shape (e.g. phone number).
- **Web renders a real HTML `<input>`** internally for password-manager detection, native renders `LayrzTextInput` directly — identical public API either way, no platform branching needed from the caller.
- Fully controller-driven: there is no `value` parameter.
- `formId` is normally left `null` — it resolves automatically from the nearest `LayrzLoginWebGroup`; only override when forcing a specific web form id outside that provider.

---

## Common patterns

```dart
// 1. Basic login field, advancing focus to password on submit
LayrzUsernameInput(
  controller: usernameController,
  onSubmit: (_) => passwordFocusNode.requestFocus(),
)

// 2. Required with validation errors
LayrzUsernameInput(
  isRequired: true,
  controller: usernameController,
  errors: usernameErrors,
  onChanged: (value) => usernameErrors = validate(value),
)

// 3. Grouped with the password field inside LayrzForm
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

// 4. Native-only grouping without LayrzForm
AutofillGroup(
  child: Column(
    children: [
      LayrzUsernameInput(controller: usernameController),
      LayrzPasswordInput(controller: passwordController),
    ],
  ),
)
```

---

## Form conventions

- Guard async `onChanged`/`onSubmit` follow-ups with `if (context.mounted)` before calling the parent callback.
- Pass `errors: <List<String>>` from your own validation state — there is no `context.getErrors`.
- Prefer wrapping login forms in `LayrzForm` over a bare `AutofillGroup` — it also drives the password-manager save-commit/discard sequence correctly on submit.
- Localize `labelText` only if the default `LayrzUiL10n` "Username" string doesn't fit (e.g. "Email address").
