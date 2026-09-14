# LayrzScaffoldItem&lt;T&gt; — API Reference

Source: `lib/src/scaffold/src/scaffold_item.dart`
- `LayrzScaffoldItem<T>` class

---

## Examples

```dart
// Minimal
LayrzScaffoldItem<User>(
  key: ValueKey(user.id),
  item: user,
  tile: Text(user.name),
)

// With search metadata
LayrzScaffoldItem<User>(
  key: ValueKey(user.id),
  item: user,
  tile: Row(
    children: [
      LayrzAvatar(source: LayrzAvatarUrl(user.avatarUrl)),
      const SizedBox(width: 8),
      Text(user.name),
    ],
  ),
  searchableStrings: {user.name, user.email},
)
```

---

## Constructor

```dart
const LayrzScaffoldItem({
  required this.key,
  required this.item,
  required this.tile,
  this.searchableStrings = const {},
});
```

No compile-time asserts.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `key` | `Key` | required | Identity key. Determines selection persistence in `LayrzScaffoldController`, independent of `item`-instance equality. |
| `item` | `T` | required | The underlying domain data. Reaches the app's detail content indirectly (the caller's own `onItemTap` handler receives the whole `LayrzScaffoldItem<T>`, so `item.item` is available there), and feeds `LayrzScaffoldShell`'s desktop default table directly (each `LayrzColumn<T>.valueBuilder` reads off it). |
| `tile` | `Widget` | required | Rendered for this entry in the list panel. Any widget — no rich-text tile base class exists. |
| `searchableStrings` | `Set<String>` | `{}` | Matched case-insensitively as substrings by the shell's built-in search. Empty ⇒ unsearchable (still renders). |

---

## Equality

`LayrzScaffoldItem` implements `==`/`hashCode` by `key` alone:

```dart
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is LayrzScaffoldItem && other.key == key;
}

@override
int get hashCode => key.hashCode;
```

Two items with the same `key` are equal regardless of `item`, `tile`, or `searchableStrings` — this is what lets `LayrzScaffoldShell`'s internal list and controller compare items cheaply.

---

## Behavior notes

- `key` must be unique across the whole `items` list passed to `LayrzScaffoldShell` — colliding keys produce undefined selection behavior.
- There is no separate rich-text tile abstraction (no `LayrzScaffoldTile`/`LayrzScaffoldValueTile`) — build `tile` as any ordinary widget.
- There is no `actions` field. Row-level quick actions and any hover/swipe reveal behavior are not built into `LayrzScaffoldItem` — build them into `tile` yourself if a row needs them.
- `searchableStrings` is evaluated fresh on every shell rebuild; recompute it from the current `item` state rather than caching it stale.
- `item` is the same object `LayrzScaffoldShell`'s desktop table renders as a row (via `LayrzScaffoldItem.item` unwrapped into `LayrzTable<T>.items`), so any `LayrzColumn<T>` passed to the shell's `tableColumns` must read directly off `T`, not off `LayrzScaffoldItem<T>`.
