---
name: layrz-ui-scaffold-item
description: Use LayrzScaffoldItem<T> in a layrz_ui Flutter widget. Apply when populating LayrzScaffoldShell's items list — pairing a domain object with a stable key, a pre-built tile widget, and searchable strings.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- The element type of `LayrzScaffoldShell<T>.items` — always constructed inline when building that list, never used standalone.
- Wraps a caller domain object (`item: T`) with an identity `key`, a pre-built `tile` widget, and `searchableStrings` for the shell's built-in search filtering.
- **Do not use** for a general-purpose list item outside `LayrzScaffoldShell` — it has no meaning without the shell that consumes it.
- **Do not use** for rich-text tile composition assuming a base class exists — there is no `LayrzScaffoldTile`; `tile` accepts any widget you build yourself.

---

## Minimal usage

```dart
LayrzScaffoldItem<User>(
  key: ValueKey(user.id),
  item: user,
  tile: Text(user.name),
  searchableStrings: {user.name, user.email},
)
```

---

## Key behaviors

- **Equality is by `key` alone** — two `LayrzScaffoldItem`s with the same `key` are `==` regardless of `item`, `tile`, or `searchableStrings` content. This is what lets the shell track selection cheaply across list rebuilds with new `T` instances (e.g. refetched from an API).
- **`key` must be stable and unique** — reuse the same `Key` (typically `ValueKey(domainObject.id)`) across rebuilds so `LayrzScaffoldController.openedKey` continues to resolve to the same logical row.
- **`searchableStrings` drives the shell's built-in filter** — matched case-insensitively as substrings. An empty set (the default) makes the item unsearchable; it still renders, it just never matches a query.
- **`tile` is any widget, not a specialized type** — build your own `Row`/`Column`/card exactly as you would for any other list row.
- **`item` also feeds the desktop table** — `LayrzScaffoldShell`'s wide-layout default table reads each row's cells straight off `item` (of type `T`) via `LayrzColumn.valueBuilder`; there is no separate per-item cell data on `LayrzScaffoldItem` itself.

---

## Common patterns

```dart
// 1. Tile with avatar + subtitle
LayrzScaffoldItem<User>(
  key: ValueKey(user.id),
  item: user,
  tile: Row(
    children: [
      LayrzAvatar(source: LayrzAvatarUrl(user.avatarUrl)),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name),
            Text(user.email, style: context.theme.tokens.typography.caption),
          ],
        ),
      ),
    ],
  ),
  searchableStrings: {user.name, user.email},
)

// 2. Unsearchable item (renders, never matches a query)
LayrzScaffoldItem<Divider>(
  key: const ValueKey('section-divider'),
  item: sectionDivider,
  tile: Container(height: 1, color: context.theme.tokens.colors.divider),
)
```

---

## Usage conventions

- Always derive `key` from a stable domain identifier (`ValueKey(user.id)`), never from list index — an index-keyed item loses selection identity when the list reorders or filters.
- Populate `searchableStrings` with every field a user would reasonably search by (name, email, id) — omissions silently make a field unsearchable.
- Keep `tile` free of its own tap handling for row selection — the shell's list panel already makes the whole row tappable to open the detail pane; a competing `GestureDetector` inside `tile` can shadow that.
- If a row needs its own quick actions (edit/delete), build them into `tile` yourself (e.g. an `IconButton`-style widget in a trailing slot) — `LayrzScaffoldItem` has no dedicated `actions` field or built-in hover/swipe reveal machinery.
