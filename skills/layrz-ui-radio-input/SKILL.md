---
name: layrz-ui-radio-input
description: Use LayrzRadioInput<T> in a layrz_ui Flutter widget. Apply when choosing one of several mutually-exclusive options laid out in a responsive grid — generic typed values via LayrzSelectItem<T>, per-breakpoint column spans (xs/sm/md/lg/xl).
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Choosing exactly one option out of a small, always-visible set: plan tiers, shipping methods, yes/no/maybe radios.
- Options reflow in a responsive 12-column grid (`LayrzRow`/`LayrzCol` under the hood) — good for 2–8 short options shown inline, not for long lists.
- **Do not use** for a long or searchable list of options — use `LayrzSelectInput<T>` instead (opens a dialog/sheet with search).
- **Do not use** for a single boolean toggle — use `LayrzCheckboxInput` or `LayrzSwitchInput` instead.

---

## Minimal usage

```dart
LayrzRadioInput<String>(
  labelText: 'Shipping method',
  items: [
    LayrzSelectItem(value: 'standard', child: const Text('Standard')),
    LayrzSelectItem(value: 'express', child: const Text('Express')),
  ],
  value: shippingMethod,
  onChanged: (value) {
    setState(() => shippingMethod = value);
  },
)
```

---

## Key behaviors

- Items are `List<LayrzSelectItem<T>>` — the same item type `LayrzSelectInput` uses (`value`, `child`, `searchableStrings`). The radio group ignores `searchableStrings` (no search in a radio group).
- **Item values must be unique** — a duplicate triggers a debug assertion (the underlying `RadioGroup` requires unique values for single-selection semantics).
- Tapping the currently-selected option again leaves it selected — there is no toggle-to-null.
- Arrow keys (Up/Down/Left/Right) move focus within the group via the underlying `RadioGroup`.
- `disabled: true` grays out and disables every option; `onChanged` never fires.
- A `child` with no inherent text semantics (icon-only, a colour swatch) announces with no name unless it wraps itself in its own `Semantics(label: ...)`.

---

## Breakpoints

Column spans (1–12) cascade: an unset larger breakpoint inherits the next-smaller one.

| Param | Default | Options per row |
|---|---|---|
| `xs` | `12` | 1 |
| `sm` | `6` | 2 |
| `md` | `4` | 3 |
| `lg` | `3` | 4 |
| `xl` | `2` | 6 |

---

## Common patterns

```dart
// 1. Custom presentation with icon + text (use Text.rich, not raw RichText)
LayrzRadioInput<int>(
  labelText: 'Priority',
  items: [
    LayrzSelectItem(
      value: 1,
      child: Text.rich(TextSpan(text: 'Low')),
    ),
    LayrzSelectItem(
      value: 2,
      child: Text.rich(TextSpan(text: 'High')),
    ),
  ],
  value: priority,
  onChanged: (value) => setState(() => priority = value),
)

// 2. Required field with error
LayrzRadioInput<String>(
  labelText: 'Plan',
  isRequired: true,
  items: plans.map((p) => LayrzSelectItem(value: p.id, child: Text(p.name))).toList(),
  value: selectedPlanId,
  errors: selectedPlanId == null ? const ['Choose a plan'] : const [],
  onChanged: (value) => setState(() => selectedPlanId = value),
)

// 3. One-option-per-row on every breakpoint
LayrzRadioInput<bool>(
  labelText: 'Agree?',
  xs: 12,
  sm: 12,
  md: 12,
  lg: 12,
  xl: 12,
  items: const [
    LayrzSelectItem(value: true, child: Text('Yes')),
    LayrzSelectItem(value: false, child: Text('No')),
  ],
  value: agreed,
  onChanged: (value) => setState(() => agreed = value),
)
```

---

## Form conventions

- Use `LayrzUiL10n.of(context)` for `labelText` — never hardcode strings.
- Pass `errors: [...]` for validation state — never `context.getErrors`.
- Use `Text.rich(...)`, never raw `RichText`, inside `child` when it needs multiple styled text runs — `RichText` does not inherit the ambient `DefaultTextStyle` the item is forced under, and paints with no colour.
- Separate stacked radio groups with `SizedBox(height: 10)`.
