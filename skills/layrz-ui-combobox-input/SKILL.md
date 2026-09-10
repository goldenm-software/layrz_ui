---
name: layrz-ui-combobox-input
description: Use LayrzComboBoxInput in a layrz_ui Flutter widget. Apply when adding an editable text field with autocomplete suggestions from a String list — free-form entry allowed by default, with a bold custom-value row when the typed text matches nothing.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Free-text entry with suggestions the user can also ignore: tags, city names, search-as-you-type values that aren't confined to a fixed list.
- The field itself **is** the editable input — unlike `LayrzSelectInput`, it accepts typed text directly, and the opened surface (dialog on desktop, bottom sheet on mobile) is a suggestion picker, not the only way to set a value.
- **Do not use** for picking strictly from a fixed list — use `LayrzSelectInput<T>` instead (read-only field, typed value).
- **Do not use** for a single boolean toggle — use `LayrzCheckboxInput`/`LayrzSwitchInput` instead.
- **Do not use** for a plain free-text field with no suggestions — use `LayrzTextInput` instead.

---

## Minimal usage

```dart
LayrzComboBoxInput(
  labelText: 'City',
  options: cityNames,
  value: city,
  onChanged: (value) {
    setState(() => city = value);
  },
)
```

---

## Key behaviors

- **`onChanged` tracks text, `onSubmit` tracks commits.** `onChanged` fires once per genuine text change (typing, external `value` update, or a commit that actually changes the text). `onSubmit` fires on **every** commit, unconditionally — even re-selecting the option already shown. Use `onSubmit` when you only care that the user made a deliberate choice.
- `allowFreeForm: true` (default) — any typed text is a valid value, reported live via `onChanged` with no separate confirmation. `allowFreeForm: false` reverts the field to the last matching option on blur.
- Opening the suggestion surface starts with an **empty** search field — the closed field's typed text and caret position do not carry over into the dialog/sheet.
- When the typed text matches no option (case-insensitively), a **bold** row (no "custom …" label — weight alone is the indicator) appears first in the surface; tapping it commits the exact typed text.
- `options` is a plain `List<String>` — there is no generic `LayrzComboBoxInput<T>` variant.
- No dropdown-height parameter exists (`maxOptionsToDisplay` and similar do not exist) — the dialog is capped by its own `760` max height; the sheet scrolls its own content.

---

## Common patterns

```dart
// 1. Track only deliberate commits
LayrzComboBoxInput(
  labelText: 'Tag',
  options: existingTags,
  value: tag,
  onSubmit: (value) => addTag(value),
)

// 2. Restrict to existing options only
LayrzComboBoxInput(
  labelText: 'Category',
  options: categories,
  allowFreeForm: false,
  value: category,
  onChanged: (value) => setState(() => category = value),
)

// 3. With prefix icon and error
LayrzComboBoxInput(
  labelText: 'Company',
  options: companyNames,
  prefixIcon: MdiIcons.officeBuildingOutline,
  errors: company.isEmpty ? const ['Company is required'] : const [],
  value: company,
  onChanged: (value) => setState(() => company = value),
)

// 4. No autocomplete filtering (show all options regardless of typed text)
LayrzComboBoxInput(
  labelText: 'Any of these',
  options: options,
  enableAutocomplete: false,
  value: value,
  onChanged: (value) => setState(() => value = value),
)
```

---

## Form conventions

- Use `LayrzUiL10n.of(context)` for `labelText`/`hintText`/`emptyOptionsText` — never hardcode strings.
- Pass `errors: [...]` for validation state — never `context.getErrors`.
- Prefer `onSubmit` over `onChanged` for "the user picked something" logic (e.g. adding a tag to a list); use `onChanged` for live-updating a form field's draft value.
- Separate stacked comboboxes with `SizedBox(height: 10)`.
