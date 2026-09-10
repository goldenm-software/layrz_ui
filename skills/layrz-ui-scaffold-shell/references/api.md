# LayrzScaffoldShell&lt;T&gt; — API Reference

Source: `lib/src/scaffold/src/scaffold_shell.dart`
- `LayrzScaffoldShell<T>` class
- Companion: `scaffold_controller.dart` — `LayrzScaffoldController`
- Companion: `scaffold_item.dart` — `LayrzScaffoldItem<T>` (see the dedicated `layrz-ui-scaffold-item` skill)
- Companion: `fold_split.dart` — `LayrzFoldSplit`, `LayrzFoldAxis`, `resolveFoldSplit`

---

## Examples

```dart
// Generic list-detail over a domain type
LayrzScaffoldShell<Ticket>(
  controller: controller,
  itemExtent: 64,
  items: tickets
      .map((t) => LayrzScaffoldItem<Ticket>(
            key: ValueKey(t.id),
            item: t,
            tile: TicketRow(ticket: t),
            searchableStrings: {t.title, t.assignee},
          ))
      .toList(),
  onDetailsBuild: (ticket) => TicketDetailPane(ticket: ticket),
)

// Hidden search field
LayrzScaffoldShell<Ticket>(
  controller: controller,
  itemExtent: 64,
  items: items,
  searchable: false,
  onDetailsBuild: (t) => TicketDetailPane(ticket: t),
)

// Title above the search field
LayrzScaffoldShell<Ticket>(
  controller: controller,
  itemExtent: 64,
  items: items,
  title: Text('Tickets', style: context.theme.tokens.typography.h6),
  onDetailsBuild: (t) => TicketDetailPane(ticket: t),
)
```

---

## Constructor

```dart
const LayrzScaffoldShell({
  super.key,
  required this.items,
  required this.onDetailsBuild,
  required this.controller,
  this.footer,
  this.searchable = true,
  this.title,
  required this.itemExtent,
  this.emptyState,
});
```

No compile-time asserts on the widget itself.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `items` | `List<LayrzScaffoldItem<T>>` | required | List entries. Shell does not sort or group them. |
| `onDetailsBuild` | `Widget Function(T)` | required | Builds detail content for the opened item's underlying `T` data. |
| `controller` | `LayrzScaffoldController` | required | Caller-created and caller-disposed; the shell listens but never disposes it. |
| `footer` | `Widget?` | `null` | Optional footer widget in the list panel. |
| `searchable` | `bool` | `true` | Whether the search field renders. Filtering is shell-owned, matched against `LayrzScaffoldItem.searchableStrings`. |
| `title` | `Widget?` | `null` | Optional title widget above the search field. |
| `itemExtent` | `double` | required | Height of each list row. |
| `emptyState` | `Widget?` | `null` | Shown when the (possibly filtered) list is empty. Defaults to a localized message when `null`. |

---

## `LayrzScaffoldController extends ChangeNotifier`

```dart
LayrzScaffoldController({Key? initialOpenedKey});
```

| Member | Signature | Notes |
|---|---|---|
| `openedKey` | `Key? get` | Key of the currently opened item, or `null`. |
| `isOpen` | `bool get` | `openedKey != null`. |
| `open(Key key)` | `void` | Opens the item at `key`. No-op if already open on that key. |
| `close()` | `void` | Closes the detail pane. No-op if already closed. |

Non-generic — tracks selection by `Key`, not `T`. The consuming app creates and disposes it; the shell listens and rebuilds but never disposes it.

---

## Foldable-hinge split (`fold_split.dart`)

`resolveFoldSplit({required List<DisplayFeature> features, required Rect shellRect, double minPaneExtent = 120.0, double minSplitHeight = kLayrzFoldMinSplitHeight})` → `LayrzFoldSplit?`. Called internally by the shell against `MediaQuery.displayFeaturesOf(context)` — not typically invoked directly by consumers.

### `LayrzFoldAxis` enum

| Value | Meaning |
|---|---|
| `.vertical` | Splits content left/right. The only axis that ever produces a split. |
| `.horizontal` | Splits content top/bottom. Always rejected (`resolveFoldSplit` returns `null`) — a stacked layout was tested on real hardware and found to oscillate with the on-screen keyboard. |

### `LayrzFoldSplit`

| Field | Type | Notes |
|---|---|---|
| `axis` | `LayrzFoldAxis` | Always `.vertical` in a non-null result. |
| `leadingExtent` | `double` | List pane width, in the shell's local logical pixels. |
| `trailingExtent` | `double` | Detail pane width. |
| `gap` | `double` | Seam thickness; `0` for a creaseless fold (hairline divider), nonzero for a hinge (spacer divider). |

### Constants

| Constant | Value | Notes |
|---|---|---|
| `kLayrzFoldMinSplitHeight` | `480.0` | Minimum shell height for a vertical seam to split at all. Keyboard opening shrinks the shell below this, so the split disappears automatically when the keyboard is up. |
| `kLayrzFoldPreferredListFraction` | `1 / 3` | When multiple seams qualify (e.g. Galaxy Z TriFold), the one nearest 1/3 of shell width wins. |

Gating rules (all must pass): only a vertical seam qualifies; shell height ≥ `minSplitHeight`; the seam spans the shell's full height and sits strictly inside its width; both resulting panes ≥ `minPaneExtent`; `cutout`-type features are always ignored; posture (`DisplayFeatureState`) is never filtered on.

---

## Companion widgets

- **`LayrzScaffoldItem<T>`** — the list entry model. See the dedicated `layrz-ui-scaffold-item` skill.
- **`LayrzBottomSheet`** — the underlying surface for the narrow-band detail sheet (`LayrzBottomSheet.show`, pushed on the root `Navigator`).

---

## Behavior notes

- **Narrow-band Navigator requirement**: `LayrzBottomSheet.show` always pushes on the **root** Navigator (`Navigator.maybeOf(context, rootNavigator: true)`), so the sheet's `Overlay` entry sits outside any nested `Navigator` (e.g. a go_router `ShellRoute`'s own) and outside `LayrzLayout`'s `SelectableRegion`/chrome. A missing root Navigator fires a debug `assert` and the sheet silently does not appear (no release crash).
- **Selection persists across a breakpoint crossing**: narrow → wide pops the sheet but keeps the detail open; wide → narrow auto-opens the sheet for the already-selected item.
- **Dismissal semantics**: a barrier tap, drag-to-dismiss, or system back on the narrow sheet closes the controller (de-highlighting the row) — UNLESS the shell itself initiated the dismissal for a band-transition reason, in which case selection is preserved.
- **No automatic grouping, sorting, or state restoration** — all are the consumer's responsibility.
- **Detail pane has its own independent `SelectableRegion`**, scoped so a text selection there cannot reach the page behind it, in both wide and narrow presentations.
