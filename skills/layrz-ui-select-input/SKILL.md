---
name: layrz-ui-select-input
description: Use LayrzSelectInput<T> in a layrz_ui Flutter widget. Apply when picking a single value from a list via a searchable dialog (desktop) or bottom sheet (mobile) — generic typed values via LayrzSelectItem<T>, optional clear affordance via canUnselect.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Picking one value from a list too long or too dynamic for an inline radio group: countries, users, categories, any lookup list.
- The field itself is always **read-only** — it never accepts typed input; tapping it opens a selection surface (`LayrzResponsiveModal`: dialog on desktop ≥960px, bottom sheet below that).
- **Do not use** for a short, always-visible set of options — use `LayrzRadioInput<T>` instead (no dialog, inline grid).
- **Do not use** for free-text entry with suggestions — use `LayrzComboBoxInput` instead (editable field, `String` value).
- **Do not use** for a boolean toggle — use `LayrzCheckboxInput`/`LayrzSwitchInput` instead.

---

## Minimal usage

```dart
LayrzSelectInput<String>(
  labelText: 'Country',
  itemExtent: 48,
  items: countries.map((c) => LayrzSelectItem(value: c.code, child: Text(c.name))).toList(),
  value: selectedCountryCode,
  onChanged: (item) {
    setState(() => selectedCountryCode = item?.value);
  },
)
```

---

## Key behaviors

- `itemExtent` is **required** — the expected row height inside the opened list.
- The field **self-displays**: picking an item updates the field's own display immediately, whether or not the caller feeds an updated `value` back. A caller-supplied `value` change is still honored and reconciles the display.
- The field shows exactly two states: nothing selected → `hintText`; an item selected → that item's `child` widget rendered identically to how it renders in the list (not a degraded plain-text label).
- Search lives entirely in the opened surface (`enableSearch: true`, default) — never in the closed field. Set `enableSearch: false` to drop the search field; arrow keys alone navigate the list then.
- `canUnselect: true` renders a clear ("×") affordance next to the dropdown chevron once something is selected; tapping it calls `onChanged(null)` directly — independent of whether `items` has an explicit null-value entry.
- The dropdown chevron always renders as an external sibling — never inside `suffixSlot` — so a caller-supplied `suffixIcon`/`suffix`/`suffixText` never displaces it.
- No `actions` row in the opened surface — picking an item is itself the decision, there is no separate Save step.

---

## Common patterns

```dart
// 1. Clearable select
LayrzSelectInput<String>(
  labelText: 'Assignee',
  itemExtent: 48,
  canUnselect: true,
  items: users.map((u) => LayrzSelectItem(value: u.id, child: Text(u.name))).toList(),
  value: assigneeId,
  onChanged: (item) => setState(() => assigneeId = item?.value),
)

// 2. No search (short list, arrow-key navigation only)
LayrzSelectInput<int>(
  labelText: 'Priority',
  itemExtent: 40,
  enableSearch: false,
  items: const [
    LayrzSelectItem(value: 1, child: Text('Low')),
    LayrzSelectItem(value: 2, child: Text('High')),
  ],
  value: priority,
  onChanged: (item) => setState(() => priority = item?.value),
)

// 3. Custom item child with icon + text (use Text.rich, not raw RichText)
LayrzSelectInput<String>(
  labelText: 'Status',
  itemExtent: 48,
  items: [
    LayrzSelectItem(
      value: 'active',
      child: Text.rich(TextSpan(text: 'Active')),
      searchableStrings: {'Active', 'On'},
    ),
  ],
  value: status,
  onChanged: (item) => setState(() => status = item?.value),
)

// 4. Required with error
LayrzSelectInput<String>(
  labelText: 'Country',
  itemExtent: 48,
  isRequired: true,
  items: countryItems,
  value: countryCode,
  errors: countryCode == null ? const ['Country is required'] : const [],
  onChanged: (item) => setState(() => countryCode = item?.value),
)
```

---

## Form conventions

- Use `LayrzUiL10n.of(context)` for `labelText`/`hintText`/`emptyListText` — never hardcode strings.
- Pass `errors: [...]` for validation state — never `context.getErrors`.
- Put search-relevant text in `LayrzSelectItem.searchableStrings` explicitly — `child`'s rendered text is **not** implicitly searchable.
- Use `Text.rich(...)`, never raw `RichText`, inside `child` when it needs multiple styled text runs.
- Separate stacked selects with `SizedBox(height: 10)`.
