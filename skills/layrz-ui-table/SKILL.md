---
name: layrz-ui-table
description: Use LayrzTable in a layrz_ui Flutter widget. Apply when rendering a virtualized, sortable, searchable data table — column visibility/reorder menu, opt-in multiselect, opt-in pinned-right row actions, or controller-driven state via LayrzTableController.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.copyToClipboard`) — never the fully-qualified form (`LayrzTableOnTapBehavior.copyToClipboard`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any list of domain objects that needs sorting, search, and/or column management — user tables, device lists, report rows.
- Use `hasMultiselect: true` when rows need bulk selection (bulk delete, bulk export).
- Use `actionsBuilder` + `actionsCount` for per-row actions (edit/delete icons) — `actionsCount` is the single source of truth for whether the actions column exists at all.
- Pass a `LayrzTableController<T>` when sort/search/column state must survive a rebuild higher up the tree, or when you need to react to state changes via `controller.events`.
- **Do not use** for a small, fixed list with no sort/search/column needs — a plain `ListView.builder` of `LayrzCard`s is simpler.
- **Do not use** for paginated server-side data — `LayrzTable` has **no paginator**; it renders the entire `items` list through one virtualized `ListView.builder`.

---

## Minimal usage

```dart
LayrzTable<User>(
  items: users,
  columns: [
    LayrzColumn<User>(
      key: const ValueKey('name'),
      headerText: 'Name',
      valueBuilder: (user) => user.name,
    ),
    LayrzColumn<User>(
      key: const ValueKey('email'),
      headerText: 'Email',
      valueBuilder: (user) => user.email,
    ),
  ],
)
```

---

## Key behaviors

- Every `LayrzColumn.key` must be unique within `columns` — asserted at construction. `columns` must be non-empty.
- `LayrzColumn.valueBuilder` and `customSort` **must be isolate-safe** — they may run in a background isolate during sort (via `compute`). Never capture `BuildContext`, i18n lookups, or a `ChangeNotifier`/`State` in them.
- No paginator exists — the whole filtered/sorted `items` list renders through one virtualized `ListView.builder` below a frozen header.
- `actionsCount` (not `actionsBuilder`) is the single source of truth for the actions column — `actionsCount == 0` (the default) means no actions column at all, even if `actionsBuilder` is supplied.
- `hasMultiselect` defaults to `false` (opt-in). The header's select-all checkbox is computed against the full `items` list, not the search-filtered rows.
- A column without `LayrzColumn.onTap` falls back to copying the cell's displayed text to the clipboard on tap.
- Supply `controller` to own disposal yourself; when omitted, the table creates and disposes its own internal `LayrzTableController<T>`.
- A 2px loading strip is always reserved above the header; it animates when `isLoading` is `true`, or while the table's own off-thread sort/filter recompute is in flight.

---

## Common patterns

```dart
// 1. Controller-driven table with multiselect and row actions
final controller = LayrzTableController<User>();

LayrzTable<User>(
  items: users,
  columns: columns,
  controller: controller,
  hasMultiselect: true,
  actionsCount: 2,
  actionsBuilder: (user) => [
    LayrzTableAction(
      icon: MdiIcons.pencilOutline,
      labelText: 'Edit',
      onTap: () => _edit(user),
    ),
    LayrzTableAction(
      icon: MdiIcons.trashCanOutline,
      labelText: 'Delete',
      onTap: () => _delete(user),
      style: .outlined,
    ),
  ],
)

// 2. Custom sort comparator for a non-string column
LayrzColumn<User>(
  key: const ValueKey('status'),
  headerText: 'Status',
  valueBuilder: (user) => user.isActive ? 'Active' : 'Inactive',
  customSort: (a, b, ascending) {
    final result = (a.isActive ? 0 : 1).compareTo(b.isActive ? 0 : 1);
    return ascending ? result : -result;
  },
)

// 3. Reacting to state changes via the event stream
controller.events.listen((event) {
  switch (event) {
    case LayrzTableSortEvent<User>():
      // persist event.columnKey / event.ascending
      break;
    case LayrzTableSearchEvent<User>():
      // persist event.searchText
      break;
    case LayrzTableSelectionEvent<User>():
      print('Selected ${event.selection.length} users');
      break;
    case LayrzTableColumnsEvent<User>():
      // persist event.columnOrder / event.hiddenColumns
      break;
    case LayrzTableRefreshEvent<User>():
      _reload();
      break;
  }
});

// 4. Fixed-width column with a per-cell tap handler
LayrzColumn<User>(
  key: const ValueKey('email'),
  headerText: 'Email',
  width: 220,
  valueBuilder: (user) => user.email,
  onTap: (user) => _openProfile(user),
)
```

---

## Usage conventions

- Give `emptyText` and `emptySearchText` distinct, localized strings via `LayrzUiL10n.of(context)` when the house defaults don't fit the domain — they render for different conditions (no items at all vs. search matches nothing).
- Keep `LayrzColumn.valueBuilder`/`customSort` pure functions over `T` — build them outside `build()` (e.g. as a `static` list or a field) so they don't capture widget state by accident.
- Drive `isLoading` from the caller's own fetch/refresh state; the table's internal off-thread sort/filter recompute animates the same strip automatically, so don't try to also flip `isLoading` for that.
- Prefer listening to `controller.events` over diffing `ListenableBuilder` snapshots when you only care about one kind of change (e.g. persisting column layout) — it avoids re-deriving what changed on every `notifyListeners()`.
- Keep a `LayrzTableController<T>` alive across rebuilds (e.g. in a `State` field) whenever you need sort/search/column state to survive — an inline `LayrzTableController<T>()` in `build()` resets on every rebuild.
