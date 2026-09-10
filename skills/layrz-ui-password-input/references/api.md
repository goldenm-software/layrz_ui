# LayrzPasswordInput — API Reference

Source: `lib/src/inputs/src/login/password_input.dart`
Companions: `lib/src/inputs/src/login/password_strength.dart`, `lib/src/inputs/src/login/password_strength_meter.dart`

- `LayrzPasswordInput` class — line 61
- `kLayrzPasswordInputDefaultAutofillHints` constant — line 19 (`[AutofillHints.password]`)
- `LayrzPasswordRequirements` class — `password_strength.dart` line 89
- `LayrzPasswordStrengthLevel` enum — `password_strength.dart` line 57
- `LayrzPasswordStrengthMeter` class — `password_strength_meter.dart` line 56

> **Wiki note**: `wiki/Widgets/LayrzPasswordInput.md` is a stale pre-implementation design sketch
> ("awaits team confirmation") and does not reflect the shipped widget — it documents parameters
> (`value`, `placeholder`, `padding`, `borderRadius`, `onSubmitted`, a widget `label`) that do not
> exist on the real class. This reference is written entirely from source; treat the wiki page as
> historical only.

---

## Examples

```dart
// Login field — no strength meter (the default)
LayrzPasswordInput(
  controller: passwordController,
  errors: passwordErrors,
  onSubmit: (_) => form.submit(),
  onChanged: (value) => password = value,
)

// Registration field — live strength meter
LayrzPasswordInput(
  labelText: 'Create a password',
  isRequired: true,
  controller: newPasswordController,
  showStrengthMeter: true,
  autofillHints: const [AutofillHints.newPassword],
  onChanged: (value) => newPassword = value,
)

// Disabled
LayrzPasswordInput(
  controller: passwordController,
  disabled: true,
)

// Dense variant
LayrzPasswordInput(
  controller: passwordController,
  dense: true,
)

// Standalone requirement evaluation (no widget)
final result = LayrzPasswordRequirements.evaluate(candidate);
final level = result.level; // 0-4
final isValid = result.isValid;

// Standalone strength meter from a raw string
LayrzPasswordStrengthMeter.fromPassword(password: candidate)

// Standalone strength meter from a pre-computed snapshot
LayrzPasswordStrengthMeter(requirements: result)
```

---

## Constructor

```dart
const LayrzPasswordInput({
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
  this.autofillHints = kLayrzPasswordInputDefaultAutofillHints,
  this.formId,
  this.showStrengthMeter = false,
});
```

No asserts on this constructor.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String?` | `null` | Falls back to `LayrzUiL10n.of(context).loginPasswordLabel` ("Password") when omitted. |
| `hintText` | `String?` | `null` | Placeholder shown when empty. |
| `isRequired` | `bool` | `false` | Renders a red `*` beside the label. |
| `controller` | `TextEditingController?` | `null` | Caller-owned if supplied (never disposed); created+disposed internally otherwise. |
| `focusNode` | `FocusNode?` | `null` | Same disposal contract as `controller`. Web path does not use it. |
| `errors` | `List<String>` | `[]` | Caller-owned validation messages. |
| `disabled` | `bool` | `false` | Field and eye-toggle both stop responding to input/taps. |
| `dense` | `bool` | `false` | Mirrors `LayrzTextInput.dense` natively; selects the tighter CSS padding on the web DOM field. |
| `onChanged` | `ValueChanged<String>?` | `null` | Fires on every text change. |
| `onSubmit` | `ValueChanged<String>?` | `null` | Fires on submit (e.g. Enter). Does not itself drive autofill commit — see `LayrzForm`. |
| `autofillHints` | `List<String>` | `kLayrzPasswordInputDefaultAutofillHints` (`[AutofillHints.password]`) | On native flows to `LayrzTextInput.autofillHints`; on web translated to the DOM `autocomplete` value. |
| `formId` | `String?` | `null` | Explicit HTML `<form>` id override for web. Normally resolved automatically from the nearest `LayrzLoginWebGroup`. No effect on native. |
| `showStrengthMeter` | `bool` | `false` | When `true`, renders `LayrzPasswordStrengthMeter` below the field, re-scoring live as the controller text changes. |

There is **no** `value` parameter (fully controller-driven), no `placeholder` (use `hintText`), no
`padding`/`borderRadius` override, and no `onSubmitted` — the real callback name is `onSubmit`.

---

## `LayrzPasswordStrengthLevel` enum

Source: `password_strength.dart`

| Value | Description |
|---|---|
| `.invalid` | Not a valid password (empty, missing a required character class, or contains a disallowed character) — always level 0 regardless of length. |
| `.veryWeak` | Valid, but shorter than 8 characters. |
| `.weak` | Valid, 8–11 characters. |
| `.medium` | Valid, 12–15 characters. |
| `.strong` | Valid, 16–19 characters. |
| `.veryStrong` | Valid, 20 characters or longer. |

---

## `LayrzPasswordRequirements` (companion value class)

Not a widget — a pure, unit-testable value class computed via `LayrzPasswordRequirements.evaluate(String password)`.

| Member | Type | Notes |
|---|---|---|
| `hasLowercase` | `bool` | Matches `[a-z]`. |
| `hasUppercase` | `bool` | Matches `[A-Z]`. |
| `hasDigit` | `bool` | Matches `[0-9]`. |
| `hasSpecial` | `bool` | Matches the special-character set `` !@#$%^&*()_-+=[]{};:'",.<>/?`~|\ ``. |
| `hasOnlyAllowedCharacters` | `bool` | Whole-string check — every character must belong to an allowed class; one disallowed character (e.g. an emoji) fails this regardless of the four requirements above. |
| `password` | `String` | The evaluated value; only used internally by `level` for its length. |
| `isValid` | `bool` (getter) | Non-empty, `hasOnlyAllowedCharacters`, and all four requirements met. No partial credit. |
| `level` | `int` (getter) | 0–4, per the length table under `LayrzPasswordStrengthLevel`. Always 0 when `!isValid`. |
| `strengthLevel` | `LayrzPasswordStrengthLevel` (getter) | Named bucket for `level`. |
| `colorFor(LayrzColorTokens colors)` | `Color` | `danger` at level 0, `warning` at 1–2, `success` at 3–4. |

---

## `LayrzPasswordStrengthMeter` (companion widget)

Source: `password_strength_meter.dart`. Renders the 4-segment fill bar plus the four-row requirement
checklist that `LayrzPasswordInput` embeds when `showStrengthMeter: true`. Rarely used standalone,
but available when a caller wants the meter decoupled from the field (e.g. showing it next to a
confirm-password field instead).

Two constructors, exactly one of `requirements`/`password` must be supplied:

```dart
const LayrzPasswordStrengthMeter({super.key, required LayrzPasswordRequirements this.requirements});
const LayrzPasswordStrengthMeter.fromPassword({super.key, required String this.password});
```

| Property | Type | Notes |
|---|---|---|
| `requirements` | `LayrzPasswordRequirements?` | A pre-computed snapshot. Mutually exclusive with `password`. |
| `password` | `String?` | A raw string, re-evaluated via `LayrzPasswordRequirements.evaluate` on every build — pass the live controller text to keep it in sync. Mutually exclusive with `requirements`. |

Level 0 legitimately renders `danger` red — there is no "never alarm the user" softening; a genuinely
weak/invalid password shows as such.

---

## Behavior notes

- **Platform split is invisible to the caller**: native renders `LayrzTextInput` directly with a
  `shieldKeyOutline` prefix icon and the eye toggle composed as a `suffix` widget (not `suffixIcon`,
  specifically so the toggle can carry its own accessible name/live-region announcement). Web renders
  a real HTML `<input>` via `LayrzLoginWebField` so browser password managers can detect and fill it,
  with the same `LayrzPasswordStrengthMeter` rendered as a Flutter sibling below when enabled. Both
  paths expose the identical public API.
- **Eye toggle accessibility**: the toggle announces its *next* action via `Semantics.label`
  (`passwordShow`/`passwordHide`) and separately announces the state change that *just happened* via
  a live-region node — these are deliberately two different mechanisms, not a single label update.
- **Strength meter recomputation**: when `showStrengthMeter` is true, the widget listens to the
  controller and re-scores on every change, even though the field's own layout doesn't otherwise read
  the text directly.
- **Grouping**: pair with `LayrzUsernameInput` inside a `LayrzForm` (recommended) or a raw
  `AutofillGroup` (native-only, manual) so both fields are treated as one credential set by the
  platform/browser.
