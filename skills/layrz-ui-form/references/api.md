# LayrzForm — API Reference

Source: `lib/src/inputs/src/login/form.dart`

- `LayrzForm` class — line 53

---

## Examples

```dart
// Standard login form
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
          LayrzButton.save(labelText: 'Sign in', onTap: () => _form.submit()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _form;
}

// Handling submit() result explicitly (e.g. showing an error)
Future<void> handleSubmitTap() async {
  final succeeded = await form.submit();
  if (!succeeded && context.mounted) {
    showErrorBanner('Invalid credentials');
  }
}

// Modeling a two-factor first step as `false` (no save yet)
LayrzForm(
  onSubmit: () async {
    await requestOtp(username, password);
    return false;
  },
  child: loginFields,
)
```

---

## Constructor

```dart
const LayrzForm({
  super.key,
  required this.child,
  required this.onSubmit,
});
```

No asserts on this constructor.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `child` | `Widget` | **required** | The subtree this form wraps — typically login/signup fields plus a submit button. Rendered unchanged; `LayrzForm` imposes no layout, sizing, or styling of its own. |
| `onSubmit` | `Future<bool> Function()` | **required** | The caller's own submit handler. `LayrzForm` never calls this itself — the caller invokes it via `submit()` (typically from a submit button's `onTap`). Returning `true` signals success and commits the pending credential save; `false`, or a thrown error, discards it. |

---

## Instance method: `submit()`

```dart
Future<bool> submit()
```

Runs `onSubmit` and commits or discards the pending autofill save based on its result:

1. Awaits `onSubmit()`.
2. On `true`, calls `TextInput.finishAutofillContext(shouldSave: true)`.
3. On `false`, or if `onSubmit` throws, calls `TextInput.finishAutofillContext(shouldSave: false)` instead.
4. The result of `onSubmit` (or its thrown error) is returned/rethrown to the caller unchanged — the discard call happens before the rethrow, so the caller still observes the original exception.

Call this from the submit button's `onTap`. Calling `onSubmit` directly bypasses the entire commit/discard sequence.

---

## Behavior notes

- **Platform behavior — native**: wraps `child` in Flutter's own `AutofillGroup`. `onDisposeAction` is explicitly set to `AutofillContextAction.cancel`, overriding the SDK default of `.commit` — the default would call `finishAutofillContext(shouldSave: true)` unconditionally whenever the group is disposed (e.g. the route pops after a failed submission), reintroducing exactly the failure `submit()` exists to prevent.
- **Platform behavior — web**: wraps `child` in the login sub-module's private `LayrzLoginWebGroup` instead of relying on `AutofillGroup` alone, because Flutter web's autofill engine can't reliably trigger browser password-manager detection through the SDK's own mechanism. `LayrzForm` owns this platform switch internally (checked via `kIsWeb`); the caller never branches on platform.
- **v1 non-goals**: no field validation (the caller's job, or a future `LayrzFormField`-style layer); no built-in two-factor/OTP modeling (treat the first step as a `false` result and drive the second step outside this instance, or wrap the final successful step in its own); no explicit `commit()`/`discard()` controller API — `onSubmit` returning `true` **is** the commit, deliberately, so it can't be forgotten.
- **iOS caveat**: the consuming app must separately declare an Associated Domains entitlement for credential-manager autofill to engage at all — this is application-level configuration `LayrzForm` cannot provide or detect.
- **Safe no-op**: on platforms/browsers without password-manager integration, `onSubmit` still runs and its result still gates the (now no-op) `finishAutofillContext` call — no error, no degraded behavior for the caller's own submit flow.

---

## Companion widgets

- **`LayrzUsernameInput`** / **`LayrzPasswordInput`** — the typical field pair wrapped by `LayrzForm`.
- **`LayrzButton.save`** (or any `LayrzButton`) — the typical submit trigger, calling `form.submit()` from `onTap`.
