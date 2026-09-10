---
name: layrz-ui-scaffold-shell
description: Use LayrzScaffoldShell<T> in a layrz_ui Flutter app. Apply when building a list-detail view — two-pane desktop, single-pane + modal sheet on mobile, foldable-hinge-aware side-by-side split, or shell-owned search filtering via LayrzScaffoldItem.searchableStrings.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A generic list-detail view: emails, users, tickets, any master/detail pattern where selecting a list row shows details.
- Generic over item type `T` — works with any domain object via `LayrzScaffoldItem<T>`.
- The shell owns list rendering, search filtering, and desktop/mobile/foldable presentation switching; the consumer owns the detail content (`onDetailsBuild`) and the opened-item state (`LayrzScaffoldController`).
- **Do not use** for the top-level app shell (nav rail + drawer) — use `LayrzLayout` instead.
- **Do not use** for a fixed, author-defined tab set — use `LayrzTabView` instead.
- **Do not use** raw `Row`/`ListView` list-detail hand-rolling — this shell already handles the desktop/mobile/foldable split, search, and selection persistence.

---

## Minimal usage

```dart
final controller = LayrzScaffoldController();

LayrzScaffoldShell<User>(
  controller: controller,
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
  onDetailsBuild: (user) => Column(
    children: [
      Text(user.name, style: context.theme.tokens.typography.h6),
      Text('Email: ${user.email}'),
    ],
  ),
)
```

---

## Key behaviors

- **Not a router** — `LayrzScaffoldShell<T>` never navigates; the consumer owns routing and the detail widget's own content.
- **Selection is keyed, not instance-based**: `LayrzScaffoldController.openedKey` tracks a `Key`, not the item — refetching the list with new `T` instances (same keys) preserves selection.
- **Search is shell-owned, not customizable**: filters `LayrzScaffoldItem.searchableStrings` case-insensitively as substrings. No `filter` callback, no way to intercept the query. Set `searchable: false` to hide the field entirely.
- **Row tapping is implicit** — there is no `onTap` on the shell; tapping a row calls `controller.open(item.key)` internally. Listen to the controller (`ListenableBuilder`) to react to selection outside `onDetailsBuild`.
- **Narrow band requires a `Navigator` ancestor** (e.g. inside `LayrzApp`) — the detail sheet pushes on the **root** navigator. Missing one fires a debug assert; the list still renders without detail capability.
- **Foldable-hinge awareness**: on a device reporting a genuine vertical fold/hinge crossing the shell, the shell forces an asymmetric side-by-side split at the seam — independent of breakpoint band. A horizontal seam never splits (keyboard-oscillation bug, fixed by design).
- **Selection survives every presentation change** — breakpoint crossing, fold appearing/disappearing, rotation — none of it clears `controller.openedKey`.

---

## Presentations

| Band | List pane | Detail |
|---|---|---|
| Expanded (md/lg/xl) | 300px fixed, left | Side-by-side, fills remaining width |
| Foldable (vertical seam, ≥480px shell height) | Sized to the mapped hinge seam (asymmetric) | Side-by-side at the true seam position |
| Narrow (sm/xs) | Always visible, full width | `LayrzBottomSheet` layered over the list |

---

## Common patterns

```dart
// 1. Reacting to selection outside onDetailsBuild
ListenableBuilder(
  listenable: controller,
  builder: (context, _) {
    final openedKey = controller.openedKey;
    return Text(openedKey == null ? 'Nothing selected' : 'Selected: $openedKey');
  },
)

// 2. Row-level quick actions (edit/delete), revealed on hover (desktop) / swipe (mobile)
LayrzScaffoldItem<User>(
  key: ValueKey(user.id),
  item: user,
  tile: Text(user.name),
  actions: [
    LayrzButton.edit(labelText: 'Edit ${user.name}', isFab: true, onTap: () => onEdit(user)),
    LayrzButton.delete(labelText: 'Delete ${user.name}', isFab: true, onTap: () => onDelete(user)),
  ],
)

// 3. Empty state and footer
LayrzScaffoldShell<User>(
  controller: controller,
  itemExtent: 56,
  items: items,
  searchable: users.isNotEmpty,
  emptyState: Center(child: Text(LayrzUiL10n.of(context).noResultsFound)),
  footer: LayrzButton.save(labelText: 'Add user', isFab: true, onTap: onAddUser),
  onDetailsBuild: (user) => UserDetailView(user: user),
)
```

---

## Usage conventions

- Always dispose your own `LayrzScaffoldController` — the shell listens but never disposes it.
- Build `LayrzScaffoldItem.tile` yourself — there is no rich-text tile base class; any widget works (`Row`, custom card, etc.).
- Prefer the icon-only Fab presentation (`isFab: true`) for `LayrzScaffoldItem.actions` — the revealed strip is typically narrow relative to the row.
- Sort and group `items` yourself before passing them — the shell does neither.
- Ensure a `Navigator` ancestor exists (normally satisfied automatically inside `LayrzApp`) so the narrow-band detail sheet can present.
