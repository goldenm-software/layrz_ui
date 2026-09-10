---
name: layrz-ui-multi-select-input
description: Use LayrzMultiSelectInput<T> in a layrz_ui Flutter widget. Apply when adding a multiple-value picker field that opens a searchable, checkbox-per-row dialog/bottom-sheet — staged with Cancel/Select-All(Unselect-All)/Save, resolving to a List<T>.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Picking several values from a list — tags, permissions, categories — with a comma-joined closed-field summary.
- The compact-viewport surface `LayrzDualListInput` itself delegates to below 960px, when you specifically want the always-visible two-panel form on desktop instead.
- **Do not use** for a single value — use `LayrzSelectInput` instead.
- **Do not use** when the field should always show both panels side by side regardless of width — use `LayrzDualListInput` instead.

---

## Minimal usage

```dart
LayrzMultiSelectInput<String>(
  labelText: 'Favorite fruits',
  items: fruitItems,
  value: selectedFruits,
  itemExtent: 52,
  errors: selectedFruitsErrors,
  onChanged: (values) {
    selectedFruits = values;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- **Staged-with-Save, unconditionally — a deliberate divergence from `layrz_theme`'s `ThemedMultiSelectInput`.** There is no `waitUntilClosedToSubmit` flag; the opened surface always carries a Cancel / Select-All(Unselect-All) / Save actions row. Tapping a row only toggles the surface's internal draft — `onChanged` is **not** called and the surface does not close. Only **Save** calls `onChanged`, once, with the full drafted list, and closes. **Cancel** closes and discards every tap made since opening.
- **Closed field shows comma-joined labels, not a count, not chips** — e.g. `"Apple, Banana, Cherry"`, ellipsized on overflow. Labels are extracted from each `LayrzSelectItem.child`'s `Text`/`RichText` content; an item whose `child` renders no text contributes an empty string, so supply `searchableStrings` with the intended label when `child` is non-textual.
- The opened surface also renders **"All (count)" / "Selected (count)" tabs** that re-filter the same list — live counts, search narrows both partitions the same way.
- `itemExtent` is **required** and must be `>= kLayrzPickerMinItemExtent` (52px) — every row renders a full `LayrzCheckboxInput`, which needs that height; enforced by assertion.
- `enableSearch: false` removes the surface's search field entirely — arrow keys alone navigate the list.
- Self-display: the closed field renders from its own internal state updated immediately on Save, independent of whether the caller feeds an updated `value` back in on the next build.

---

## Common patterns

```dart
// 1. Required field with errors
LayrzMultiSelectInput<String>(
  labelText: 'Tags',
  isRequired: true,
  items: tagItems,
  value: selectedTags,
  itemExtent: 52,
  errors: selectedTags.isEmpty ? ['Select at least one tag'] : const [],
  onChanged: (values) => setState(() => selectedTags = values),
)

// 2. Custom search filter
LayrzMultiSelectInput<String>(
  labelText: 'Devices',
  items: deviceItems,
  value: selectedDevices,
  itemExtent: 52,
  filter: (query, item) => item.searchableStrings.any(
    (s) => s.toLowerCase().startsWith(query.toLowerCase()),
  ),
  onChanged: (values) => setState(() => selectedDevices = values),
)

// 3. Search disabled (arrow-key navigation only)
LayrzMultiSelectInput<String>(
  labelText: 'Priority',
  items: priorityItems,
  value: selectedPriorities,
  itemExtent: 52,
  enableSearch: false,
  onChanged: (values) => setState(() => selectedPriorities = values),
)
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)` before calling the parent callback.
- Localize `labelText`/`hintText`/`emptyListText`/`helpTitleText`/`helpContentText` via `LayrzUiL10n.of(context)` for real product strings.
- Pass `errors: <List<String>>` from your own form validation state — there is no `context.getErrors` in layrz_ui; the caller computes and owns the list.
- At least one of `labelText`/`hintText` is required — an assertion enforces this at construction.
- Expect `onChanged` to fire **once, on Save**, with the whole list — never once per row tap. Do not write logic that assumes per-tap callbacks.
