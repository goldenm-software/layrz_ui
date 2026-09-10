---
name: layrz-ui-form
description: Use LayrzForm in a layrz_ui Flutter widget. Apply when wrapping a login/signup field group — commits or discards a browser/OS password-manager save via submit() based on whether the caller's async handler succeeded, and groups fields for autofill on both native and web.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Wrapping `LayrzUsernameInput` + `LayrzPasswordInput` (plus a submit button) in any login or signup flow, so the platform/browser password manager only ever offers to save a credential after a confirmed-successful submission.
- **Do not use** for general-purpose form validation or data collection — `LayrzForm` has no field-level validation, no `key`-based `FormState`, and no data model of its own; it is purely a behavioral autofill wrapper. Model validation with your own state and `errors` lists on each input.
- **Do not use** for a multi-step flow that ends in a second challenge (e.g. OTP/2FA) as a single unit — model the first step as a `false` result (nothing to save yet) and drive the second step outside this `LayrzForm`, or wrap the final successful step in its own instance.
- Always call `submit()` from the button's `onTap` — **never call your own `onSubmit` handler directly** if the autofill save prompt matters; calling it directly bypasses the commit/discard sequence entirely.

---

## Minimal usage

```dart
class _LoginFormState extends State<LoginForm> {
  String _username = '';
  String _password = '';
  late final LayrzForm _form;

  @override
  void initState() {
    super.initState();
    _form = LayrzForm(
      onSubmit: () => authenticate(_username, _password),
      child: Column(
        children: [
          LayrzUsernameInput(onChanged: (value) => _username = value),
          const SizedBox(height: 12),
          LayrzPasswordInput(onChanged: (value) => _password = value),
          const SizedBox(height: 16),
          LayrzButton.save(
            labelText: 'Sign in',
            onTap: () => _form.submit(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _form;
}
```

---

## Key behaviors

- **`submit()` is the only intended commit path** — it awaits `onSubmit`, then calls `TextInput.finishAutofillContext(shouldSave: true)` on a `true` result, or `shouldSave: false` on a `false` result **or** if `onSubmit` throws. A thrown error still propagates to the caller after the discard is issued.
- **Renders no chrome and imposes no layout** — `child` is rendered unchanged, wrapped only in the platform-appropriate autofill grouping widget. Arrange fields, spacing, and the submit button entirely yourself inside `child`.
- **Disposal never saves** — on native, `AutofillGroup.onDisposeAction` is explicitly `.cancel`, overriding the Flutter default of `.commit`. Popping the route after a failed submission never silently offers a save.
- **Platform switch is internal** — native wraps `child` in a real `AutofillGroup`; web wraps it in an internal HTML-`<form>`-backed group instead, because Flutter web's autofill engine can't rely on `AutofillGroup` alone. You never branch on `kIsWeb` yourself.
- **iOS needs an Associated Domains entitlement** at the app level for credential-manager autofill to engage — `LayrzForm` cannot configure this; missing entitlements are an app-config gap, not a widget defect.
- **Safe no-op where unsupported** — on platforms/browsers with no password-manager integration, `onSubmit` still runs and its result still gates the (no-op) `finishAutofillContext` call; nothing breaks.

---

## Common patterns

```dart
// 1. Standard login form (username + password + save button)
LayrzForm(
  onSubmit: () => authenticate(username, password),
  child: Column(
    children: [
      LayrzUsernameInput(controller: usernameController),
      const SizedBox(height: 12),
      LayrzPasswordInput(controller: passwordController),
      const SizedBox(height: 16),
      LayrzButton.save(
        labelText: 'Sign in',
        isLoading: isSubmitting,
        onTap: () async {
          setState(() => isSubmitting = true);
          await form.submit();
          if (context.mounted) setState(() => isSubmitting = false);
        },
      ),
    ],
  ),
)

// 2. Registration form with strength meter, no separate validation layer implied
LayrzForm(
  onSubmit: () => register(username, password),
  child: Column(
    children: [
      LayrzUsernameInput(controller: usernameController),
      const SizedBox(height: 12),
      LayrzPasswordInput(
        controller: passwordController,
        showStrengthMeter: true,
        autofillHints: const [AutofillHints.newPassword],
      ),
      const SizedBox(height: 16),
      LayrzButton.save(labelText: 'Create account', onTap: () => form.submit()),
    ],
  ),
)

// 3. First step of a two-factor flow — model as `false`, no save offered yet
LayrzForm(
  onSubmit: () async {
    final accepted = await requestOtp(username, password);
    return false; // never save here; the real success is the OTP step
  },
  child: /* username + password fields */,
)
```

---

## Form conventions

- Store the `LayrzForm` instance (e.g. `late final LayrzForm _form`) rather than rebuilding it inline, so the same instance's `submit()` is reachable from the submit button across rebuilds.
- Wire the submit button's `onTap` to `form.submit()` — never to your own `onSubmit` function directly.
- Guard any UI update after `await form.submit()` with `if (context.mounted)`.
- Field-level validation (`errors` on each `LayrzUsernameInput`/`LayrzPasswordInput`) is entirely your responsibility — `LayrzForm` reacts only to the boolean result of `onSubmit`, never to field contents.
- For native, you may still use a bare `AutofillGroup` if you specifically don't want the save commit/discard behavior — but prefer `LayrzForm` for any real login/signup flow, since it is a strict superset (grouping plus the safe commit sequence).
