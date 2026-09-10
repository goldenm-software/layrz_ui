---
name: layrz-ui-switch-input
description: Use LayrzSwitchInput in a layrz_ui Flutter widget. Apply when adding a boolean toggle rendered as a pill-shaped track with a sliding thumb — settings screens, feature flags, on/off preferences.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A boolean setting shown as a track-and-thumb toggle: settings screens, "Enable X" rows, feature flags.
- The label (when set) is tappable and toggles the control.
- **Do not use** for a small square checkbox look — use `LayrzCheckboxInput` instead.
- **Do not use** for choosing one of several mutually-exclusive options — use `LayrzRadioInput` instead.
- **Do not use** for tristate/indeterminate state — `LayrzSwitchInput` has no tristate support; `value` is always `true` or `false`.

---

## Minimal usage

```dart
LayrzSwitchInput(
  labelText: 'Enable dark mode',
  value: darkModeEnabled,
  onChanged: (value) {
    setState(() => darkModeEnabled = value);
  },
)
```

---

## Key behaviors

- `value` is required and always `bool`. `true` = thumb on the right ("on"); `false` = thumb on the left ("off").
- `onChanged: null` disables the control independently of the `disabled` flag — either one makes it inert.
- The thumb animates its position over `tokens.motion.dTransition` (200ms).
- Space/Enter toggle when focused; a pointer tap never shows the keyboard focus ring.
- Track is 52×28 with a 20×20 thumb, 4px inset on all sides (24px of horizontal travel) — not configurable.
- Padding is fixed internally (`tokens.spacing.pd2` — 10px on all sides); there is no `padding` override.

---

## Colour states

| State | Off track | On track |
|---|---|---|
| Disabled | `sf3` | `sf3` |
| Error (`errors.isNotEmpty`) | `danger` @ 50% tonal | `danger` |
| Hovered / focus-visible / pressed | `sf4` | `primary` |
| Default | `sf3` | `primary` |

Precedence: disabled > error > pressed/hover/focused > default. The thumb itself is `sf1` (white) normally, `fg4` when disabled.

---

## Common patterns

```dart
// 1. Bare switch, no label
LayrzSwitchInput(
  value: isEnabled,
  onChanged: (value) => setState(() => isEnabled = value),
)

// 2. Disabled switch
LayrzSwitchInput(
  labelText: 'Locked setting',
  value: true,
  disabled: true,
)

// 3. With validation errors
LayrzSwitchInput(
  labelText: 'Two-factor authentication',
  value: twoFactorEnabled,
  errors: const ['Two-factor is required for this account type'],
  onChanged: (value) => setState(() => twoFactorEnabled = value),
)
```

---

## Form conventions

- Use `LayrzUiL10n.of(context)` for `labelText` — never hardcode strings.
- Pass `errors: [...]` (a `List<String>`) for validation state — never `context.getErrors`.
- Separate stacked switches with `SizedBox(height: 10)`.
- Prefer `LayrzSwitchInput` over `LayrzCheckboxInput` for settings-screen on/off rows; prefer `LayrzCheckboxInput` for form agreement/selection checkboxes — the choice is purely visual convention, both have identical boolean semantics.
