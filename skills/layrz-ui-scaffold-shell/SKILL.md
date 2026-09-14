---
name: layrz-ui-scaffold-shell
description: Use LayrzScaffoldShell<T> in a layrz_ui Flutter app. Apply when building a list-detail view — a full-width table by default on desktop that collapses into a two-pane split when an item opens, single-pane + modal sheet on mobile, or shell-owned search filtering via LayrzScaffoldItem.searchableStrings.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A generic list-detail view: emails, users, tickets, any master/detail pattern where opening a row shows details.
- Generic over item type `T` — works with any domain object via `LayrzScaffoldItem<T>`.
- The shell owns list/table rendering, search filtering, and desktop/mobile presentation switching; the consumer owns the detail content (via `LayrzScaffoldController.open`) and the table's columns (`tableColumns`).
- **Do not use** for the top-level app shell (nav rail + drawer) — use `LayrzLayout` instead.
- **Do not use** for a fixed, author-defined tab set — use `LayrzTabView` instead.
- **Do not use** raw `Row`/`ListView`/`LayrzTable` hand-rolling — this shell already handles the desktop-table/split/mobile-sheet switching, search, and selection persistence.

---

## Minimal usage

```dart
final controller = LayrzScaffoldController();
final tableController = LayrzTableController<User>();

LayrzScaffoldShell<User>(
  controller: controller,
  title: Text('Users', style: context.theme.tokens.typography.h6),
  itemExtent: 56,
  items: users
      .map(
        (user) => LayrzScaffoldItem<User>(
          key: ValueKey(user.id),
          item: user,
          tile: Text(user.name),
          searchableStrings: {user.name, user.email},
        ),
      )
      .toList(),
  tableColumns: [
    LayrzColumn<User>(key: const ValueKey('name'), headerText: 'Name', width: 200, valueBuilder: (u) => u.name),
    LayrzColumn<User>(key: const ValueKey('email'), headerText: 'Email', width: 260, valueBuilder: (u) => u.email),
  ],
  tableController: tableController,
  onItemTap: (item) => controller.open(
    key: item.key,
    builder: (_) => Column(
      children: [
        Text(item.item.name, style: context.theme.tokens.typography.h6),
        Text('Email: ${item.item.email}'),
      ],
    ),
  ),
)
```

Dispose `controller` and `tableController` yourself — the shell never disposes either.

---

## Key behaviors

- **Not a router** — `LayrzScaffoldShell<T>` never navigates; the consumer owns routing and the detail content's own widgets.
- **Desktop defaults to a full-width table, not a split.** On a wide container (`!context.isCompact`, ≥ 960px) with nothing open, the shell renders a full-width `LayrzTable<T>` built from `items` + `tableColumns`, with one built-in per-row "open" action button. Opening an item (via that button, or a list row on narrow) collapses the shell into the classic list(300px)+detail split for as long as something is open; the two presentations cross-fade, and the table stays mounted (not disposed) behind the split for performance.
- **Selection is keyed, not instance-based**: `LayrzScaffoldController.openedKey` tracks a `Key`, not the item — refetching the list with new `T` instances (same keys) preserves selection.
- **Search is shell-owned, not customizable**: filters `LayrzScaffoldItem.searchableStrings` case-insensitively as substrings; also drives `canSearch` on the internal desktop table. No `filter` callback, no way to intercept the query. Set `searchable: false` to hide the field entirely.
- **The shell never opens the detail pane itself.** Both the list rows (narrow, and the wide split) and the desktop table's built-in per-row open button route through `onItemTap`; the caller decides what happens, typically calling `controller.open(key:, builder:)` for the tapped item.
- **Closing the detail is the app's responsibility.** There is no built-in "close" button inside the detail content itself — the list panel's own header close button (shown while wide and open) calls `controller.close()` to return to the table, but any close affordance placed *inside* the detail builder (e.g. a header back button in a narrow sheet) must call `controller.close()` explicitly.
- **Narrow band requires a `Navigator` ancestor** (e.g. inside `LayrzApp`) — the detail sheet pushes on the **root** navigator. Missing one fires a debug assert; the list still renders without detail capability.
- **Selection survives every presentation change** — breakpoint crossing included — none of it clears `controller.openedKey` on its own (narrow→wide pops the sheet but keeps the selection; wide→narrow re-opens the sheet for it).

---

## Presentations

| Band | Nothing open | Item open |
|---|---|---|
| Wide (`!context.isCompact`, ≥ 960px) | Full-width `LayrzTable<T>` (built from `items` + `tableColumns`) | Classic side-by-side split: 300px list pane (left) + detail pane (right), cross-faded over the still-mounted table |
| Narrow (`context.isCompact`, < 960px) | List panel, full width | `LayrzBottomSheet` layered over the list |

`tableColumns` never affects the narrow layout — it is only ever consumed by the desktop default table.

---

## Common patterns

```dart
// 1. Reacting to selection outside the detail builder
ListenableBuilder(
  listenable: controller,
  builder: (context, _) {
    final openedKey = controller.openedKey;
    return Text(openedKey == null ? 'Nothing selected' : 'Selected: $openedKey');
  },
)

// 2. Closing the detail from inside its own builder (e.g. a narrow-sheet back button)
onItemTap: (item) => controller.open(
  key: item.key,
  builder: (_) => Column(
    children: [
      LayrzButton.cancel(labelText: 'Close', isFab: true, onTap: controller.close),
      UserDetailView(user: item.item),
    ],
  ),
),

// 3. Empty state, footer, and a custom open-button label
LayrzScaffoldShell<User>(
  controller: controller,
  title: Text('Users'),
  itemExtent: 56,
  items: items,
  searchable: users.isNotEmpty,
  emptyState: Center(child: Text(LayrzUiL10n.of(context).noResultsFound)),
  footer: LayrzButton.save(labelText: 'Add user', isFab: true, onTap: onAddUser),
  tableColumns: columns,
  tableController: tableController,
  showActionLabel: 'View user',
  onItemTap: (item) => controller.open(key: item.key, builder: (_) => UserDetailView(user: item.item)),
)
```

---

## Usage conventions

- Always dispose your own `LayrzScaffoldController` and `LayrzTableController<T>` — the shell listens to both but never disposes either.
- Build `LayrzScaffoldItem.tile` yourself — there is no rich-text tile base class; any widget works (`Row`, custom card, etc.).
- Design `tableColumns` around the same domain object as `items` — each `LayrzColumn<T>.valueBuilder` reads directly off `T` (the shell unwraps `LayrzScaffoldItem.item` for you); there is no separate per-item cell data type.
- Sort and group `items` yourself before passing them — the shell does neither, and the internal table renders them in that order absent its own sort/search state.
- Ensure a `Navigator` ancestor exists (normally satisfied automatically inside `LayrzApp`) so the narrow-band detail sheet can present.
- Give the caller-owned `tableController` a stable lifetime (e.g. a `State` field) — creating it inline in `build()` resets the desktop table's sort/search/column state on every rebuild.
