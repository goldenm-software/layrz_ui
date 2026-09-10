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

// With row-level quick actions
LayrzScaffoldItem<User>(
  key: ValueKey(user.id),
  item: user,
  tile: Text(user.name),
  actions: [
    LayrzButton.edit(labelText: 'Edit ${user.name}', isFab: true, onTap: () => onEdit(user)),
    LayrzButton.delete(labelText: 'Delete ${user.name}', isFab: true, onTap: () => onDelete(user)),
  ],
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
  this.actions = const [],
});
```

No compile-time asserts.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `key` | `Key` | required | Identity key. Determines selection persistence in `LayrzScaffoldController`, independent of `item`-instance equality. |
| `item` | `T` | required | The underlying domain data, passed to `LayrzScaffoldShell.onDetailsBuild` when this item is opened. |
| `tile` | `Widget` | required | Rendered for this entry in the list panel. Any widget — no rich-text tile base class exists. |
| `searchableStrings` | `Set<String>` | `{}` | Matched case-insensitively as substrings by the shell's built-in search. Empty ⇒ unsearchable (still renders). |
| `actions` | `List<LayrzButton>` | `[]` | Row-level quick actions revealed at the trailing edge. Empty ⇒ no reveal machinery mounted at all. |

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

## Row Actions (`actions`)

Any list of `LayrzButton` instances. Prefer the icon-only Fab presentation (`isFab: true`) since the revealed strip is typically narrow relative to the row.

**How the reveal works** (decision D15 — color/position only, never row resize):

- The row's own box stays exactly the same size whether or not actions are revealed.
- Actions sit pinned to the trailing edge, underneath the row body; revealing them translates the row body horizontally over that strip.
- **Desktop** (`context.isCompact == false`, ≥ 960px): hovering the row translates the body left to reveal actions; moving the pointer away hides them.
- **Mobile** (`context.isCompact == true`, < 960px): a leftward swipe reveals actions (tracked live, snapped open/closed on release by distance/velocity); a rightward swipe or a tap on the row while revealed hides them again.
- In both cases the row body stays tappable to open the detail pane. On compact, a tap while actions are revealed only dismisses the reveal (common "swipe list" convention); tap again once hidden to open the item.
- When `actions` is empty, none of this applies — the row behaves exactly as it always has.

---

## Behavior notes

- `key` must be unique across the whole `items` list passed to `LayrzScaffoldShell` — colliding keys produce undefined selection behavior.
- There is no separate rich-text tile abstraction (no `LayrzScaffoldTile`/`LayrzScaffoldValueTile`) — build `tile` as any ordinary widget.
- `searchableStrings` is evaluated fresh on every shell rebuild; recompute it from the current `item` state rather than caching it stale.
