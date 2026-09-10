---
name: layrz-ui-dual-list-input
description: Use LayrzDualListInput<T> in a layrz_ui Flutter widget. Apply when adding a two-panel "Available"/"Selected" transfer field on desktop — tap-to-move plus move-all, no drag/reorder, that delegates to LayrzMultiSelectInput automatically below 960px.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Transferring a curated subset out of a larger pool where seeing both sides at once, side by side, matters — permission sets, group membership, column visibility.
- **Do not use** for a single value — use `LayrzSelectInput` instead.
- **Do not use** when the field should always open a compact modal picker rather than render inline — use `LayrzMultiSelectInput` directly instead (this widget delegates to it automatically on narrow viewports, so you rarely need to reach for it by hand for that reason alone).

---

## Minimal usage

```dart
LayrzDualListInput<String>(
  labelText: 'Team members',
  items: memberItems,
  value: selectedIds,
  itemExtent: 52,
  availableListName: 'Available',
  selectedListName: 'Selected',
  errors: selectedIdsErrors,
  onChanged: (values) {
    selectedIds = values;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- **Desktop-only two-panel surface — automatic compact delegation.** The two-panel layout renders only when `context.isCompact == false` (`>= 960px`). Below that, this widget delegates entirely to `LayrzMultiSelectInput` with the same `items`/`value`/`onChanged`/`itemExtent` — there is no compact rendering of the panels themselves. Never branch on viewport width yourself to switch between these two widgets; this widget already does it.
- **Commits every transfer immediately — no staging, no Save.** Tapping a row in either panel moves that item to the other panel and calls `onChanged` right away. This differs from `LayrzMultiSelectInput`'s own staged-with-Save model.
- **`availableListName` and `selectedListName` are required** — there is no localized fallback; every caller must name both panels explicitly.
- **`itemExtent` is required** and must be `>= kLayrzPickerMinItemExtent` (52px) — enforced by an assertion, since the same value is forwarded to `LayrzMultiSelectInput`'s checkbox row on the compact path.
- Move-all affordances between the panels move only the currently search-filtered/visible items on their side, not the full unfiltered partition.
- Item order is always `items`' own declared order, never tap/transfer order — there is no drag-and-drop or within-panel reordering in this version.
- An item is selected exactly when its value is a member of `value` (equality-based via `T`'s own `==`/`hashCode`) — there is no `compareFunction` parameter.
- The fixed panel-area height is 400px, not caller-configurable.

---

## Common patterns

```dart
// 1. Disabling both panels
LayrzDualListInput<String>(
  labelText: 'Team members',
  items: memberItems,
  value: selectedIds,
  itemExtent: 52,
  availableListName: 'Available',
  selectedListName: 'Selected',
  disabled: true,
  onChanged: (values) => setState(() => selectedIds = values),
)

// 2. Disabling one panel's search field
LayrzDualListInput<String>(
  labelText: 'Team members',
  items: memberItems,
  value: selectedIds,
  itemExtent: 52,
  availableListName: 'Available',
  selectedListName: 'Selected',
  enableSelectedSearch: false,
  onChanged: (values) => setState(() => selectedIds = values),
)

// 3. Building items from a domain list
final memberItems = allMembers
    .map((m) => LayrzSelectItem<String>(value: m.id, child: Text(m.name)))
    .toList();
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)` before calling the parent callback.
- Localize `labelText`/`hintText`/`availableListName`/`selectedListName`/`emptyListText` via `LayrzUiL10n.of(context)` for real product strings.
- Pass `errors: <List<String>>` from your own form validation state — there is no `context.getErrors` in layrz_ui; the caller computes and owns the list.
- At least one of `labelText`/`hintText` is required — an assertion enforces this at construction.
- Because this widget renders full-height inline content (not a modal), give it its own vertical space in the surrounding layout rather than treating it like a compact field row.
