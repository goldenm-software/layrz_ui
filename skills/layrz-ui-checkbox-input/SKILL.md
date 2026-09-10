---
name: layrz-ui-checkbox-input
description: Use LayrzCheckboxInput in a layrz_ui Flutter widget. Apply when adding a boolean toggle rendered as a checkbox — plain on/off state with an optional tappable label, no tristate.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A single boolean setting: "Remember me", "I agree to the terms", feature flags, form checkboxes.
- The label (when set) is tappable and toggles the control — no separate `GestureDetector` needed.
- **Do not use** for a pill-shaped on/off toggle — use `LayrzSwitchInput` instead.
- **Do not use** for choosing one of several mutually-exclusive options — use `LayrzRadioInput` instead.
- **Do not use** for tristate/indeterminate state — `LayrzCheckboxInput` has no tristate support; `value` is always `true` or `false`.

---

## Minimal usage

```dart
LayrzCheckboxInput(
  labelText: LayrzUiL10n.of(context).actionSave,
  value: agreedToTerms,
  onChanged: (value) {
    setState(() => agreedToTerms = value);
  },
)
```

---

## Key behaviors

- `value` is required and always `bool` — never `null`.
- `onChanged: null` disables the control independently of the `disabled` flag — either one makes it inert.
- Toggling animates the checked state over `tokens.motion.dTransition` (200ms).
- Space/Enter toggle the control when it has keyboard focus; a pointer tap does not show the keyboard focus ring (`:focus-visible` semantics).
- There is no `style` parameter (`.asCheckbox`/`.asSwitch`/`.asField`) — this widget is always a bare checkbox. The switch rendering is the separate `LayrzSwitchInput` widget.
- Padding is fixed internally (`tokens.spacing.pd2` — 10px on all sides); there is no `padding` override.

---

## Common patterns

```dart
// 1. Bare checkbox, no label
LayrzCheckboxInput(
  value: isSelected,
  onChanged: (value) => setState(() => isSelected = value),
)

// 2. Disabled checkbox
LayrzCheckboxInput(
  labelText: LayrzUiL10n.of(context).actionSave,
  value: true,
  disabled: true,
)

// 3. With validation errors
LayrzCheckboxInput(
  labelText: 'I accept the terms',
  value: accepted,
  errors: accepted ? const [] : const ['You must accept to continue'],
  onChanged: (value) => setState(() => accepted = value),
)
```

---

## Form conventions

- Use `LayrzUiL10n.of(context)` for `labelText` — never hardcode strings.
- Pass `errors: [...]` (a `List<String>`) for validation state — never `context.getErrors`.
- Separate stacked checkboxes with `SizedBox(height: 10)`.
- When `onChanged` is null the control renders disabled automatically — don't also set `disabled: true` redundantly unless the two states genuinely differ.
