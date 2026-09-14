# LayrzScaffoldShell&lt;T&gt; — API Reference

Source: `lib/src/scaffold/src/scaffold_shell.dart`
- `LayrzScaffoldShell<T>` class
- Companion: `scaffold_controller.dart` — `LayrzScaffoldController`
- Companion: `scaffold_item.dart` — `LayrzScaffoldItem<T>` (see the dedicated `layrz-ui-scaffold-item` skill)
- Companion: `lib/src/table/table.dart` — `LayrzTable<T>`, `LayrzColumn<T>`, `LayrzTableController<T>` (see the dedicated `layrz-ui-table` skill) — the shell's desktop default view

---

## Examples

```dart
// Generic list-detail over a domain type
final controller = LayrzScaffoldController();
final tableController = LayrzTableController<Ticket>();

LayrzScaffoldShell<Ticket>(
  controller: controller,
  title: Text('Tickets'),
  itemExtent: 64,
  items: tickets
      .map((t) => LayrzScaffoldItem<Ticket>(
            key: ValueKey(t.id),
            item: t,
            tile: TicketRow(ticket: t),
            searchableStrings: {t.title, t.assignee},
          ))
      .toList(),
  tableColumns: [
    LayrzColumn<Ticket>(key: const ValueKey('title'), headerText: 'Title', width: 240, valueBuilder: (t) => t.title),
    LayrzColumn<Ticket>(
      key: const ValueKey('assignee'),
      headerText: 'Assignee',
      width: 160,
      valueBuilder: (t) => t.assignee,
    ),
  ],
  tableController: tableController,
  onItemTap: (item) => controller.open(key: item.key, builder: (_) => TicketDetailPane(ticket: item.item)),
)

// Hidden search field
LayrzScaffoldShell<Ticket>(
  controller: controller,
  title: Text('Tickets'),
  itemExtent: 64,
  items: items,
  searchable: false,
  tableColumns: columns,
  tableController: tableController,
  onItemTap: (item) => controller.open(key: item.key, builder: (_) => TicketDetailPane(ticket: item.item)),
)

// Custom label for the desktop table's per-row open button
LayrzScaffoldShell<Ticket>(
  controller: controller,
  title: Text('Tickets', style: context.theme.tokens.typography.h6),
  itemExtent: 64,
  items: items,
  tableColumns: columns,
  tableController: tableController,
  showActionLabel: 'View ticket',
  onItemTap: (item) => controller.open(key: item.key, builder: (_) => TicketDetailPane(ticket: item.item)),
)
```

---

## Constructor

```dart
const LayrzScaffoldShell({
  super.key,
  required this.items,
  this.onItemTap,
  required this.controller,
  this.footer,
  this.searchable = true,
  required this.title,
  required this.itemExtent,
  this.emptyState,
  this.onRefresh,
  this.refreshController,
  required this.tableColumns,
  required this.tableController,
  this.showActionLabel,
});
```

No compile-time asserts on the widget itself.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `items` | `List<LayrzScaffoldItem<T>>` | required | List/table entries. Shell does not sort or group them. |
| `onItemTap` | `void Function(LayrzScaffoldItem<T> item)?` | `null` | Called when a list row OR the desktop table's per-row open button is activated. `null` makes rows/buttons inert. The shell never calls `controller.open` itself. |
| `controller` | `LayrzScaffoldController` | required | Caller-created and caller-disposed; the shell listens but never disposes it. |
| `footer` | `Widget?` | `null` | Optional footer widget in the list panel. |
| `searchable` | `bool` | `true` | Whether the search field renders. Filtering is shell-owned, matched against `LayrzScaffoldItem.searchableStrings`; also passed through as `canSearch` to the internal desktop table. |
| `title` | `Widget` | required | Rendered above the search field in the list panel. While wide and an item is open, rendered in a row with a leading close button that calls `controller.close()`; on narrow it renders as-is. |
| `itemExtent` | `double` | required | Height of each list row. |
| `emptyState` | `Widget?` | `null` | Shown when the (possibly filtered) list is empty. Defaults to a localized message when `null`. |
| `onRefresh` | `Future<void> Function()?` | `null` | Refreshes the LIST PANEL only (never the detail pane or the desktop table). `null` disables the refresh affordance entirely — no indicator, no footer control. |
| `refreshController` | `LayrzRefreshController?` | `null` | Ignored when `onRefresh` is `null`. Drives both the drag-to-refresh gesture and the footer refresh control together. |
| `tableColumns` | `List<LayrzColumn<T>>` | required | Columns for the desktop default table. Ignored entirely by the narrow layout. Each `valueBuilder` reads off `T` directly — the shell unwraps `items.map((i) => i.item)` for the table. |
| `tableController` | `LayrzTableController<T>` | required | Controller for the desktop table's own sort/search/column/selection state. Passed straight through to the internal `LayrzTable`. Caller-owned — the shell never disposes it, and it stays idle-but-valid on a compact-only shell. |
| `showActionLabel` | `String?` | `null` | Label/tooltip for the desktop table's built-in per-row "open" button. `null` uses the localized `LayrzUiL10n.scaffoldOpenItem` ("Open item") default. |

---

## `LayrzScaffoldController extends ChangeNotifier`

```dart
LayrzScaffoldController({Key? initialOpenedKey});
```

| Member | Signature | Notes |
|---|---|---|
| `openedKey` | `Key? get` | Key of the currently opened item, or `null`. Looked up against `LayrzScaffoldShell.items` only to highlight the matching row — it is not the source of truth for `isOpen`. |
| `openedBuilder` | `WidgetBuilder? get` | The builder for the currently open detail content, or `null` when closed. This — not `openedKey` — is what the shell actually renders in the detail pane/sheet, and is the source of truth for `isOpen`. |
| `isOpen` | `bool get` | `openedBuilder != null` (deliberately not based on `openedKey`, so a keyless "create new item" open still reads as open). |
| `totalCount` | `ValueListenable<int> get` | Number of items in the unfiltered list. `0` until the shell's list panel completes its first filter computation. |
| `filteredCount` | `ValueListenable<int> get` | Number of items shown after the active search filter. |
| `open({required WidgetBuilder builder, Key? key})` | `void` | Opens the detail pane with `builder`. `key` is **optional** — omit it (or pass a synthetic key matching no row) to open with no row highlighted, e.g. a "create new item" flow. A no-op if the same `key` is already open with an `identical` `builder`. |
| `close()` | `void` | Closes the detail pane. No-op if already closed (checked via `openedBuilder`, not `openedKey`). |
| `updateCounts({required int total, required int filtered})` | `void` | Write side of `totalCount`/`filteredCount`; called internally by the shell's list panel. |

Non-generic — tracks selection by `Key`, and the detail content by `WidgetBuilder`, not `T`. The consuming app creates and disposes it; the shell listens and rebuilds but never disposes it.

**There is no `onDetailsBuild` parameter on the shell.** Detail content comes entirely from what the app passes to `controller.open(builder: ...)` inside its own `onItemTap` handler — the shell has no knowledge of how the detail pane is built.

---

## Companion widgets

- **`LayrzScaffoldItem<T>`** — the list entry model. See the dedicated `layrz-ui-scaffold-item` skill.
- **`LayrzTable<T>` / `LayrzColumn<T>` / `LayrzTableController<T>`** — the desktop default view. See the dedicated `layrz-ui-table` skill. The shell recycles the table's own per-row actions slot (`actionsCount: 1`) for its built-in "open" button; it resolves the tapped row's data object back to its owning `LayrzScaffoldItem` by identity before calling `onItemTap`.
- **`LayrzBottomSheet`** — the underlying surface for the narrow-band detail sheet (`LayrzBottomSheet.show`, pushed on the root `Navigator`).

---

## Behavior notes

- **Wide layout has two presentations, chosen by `controller.isOpen`** — nothing open renders a full-width `LayrzTable<T>` over `items`/`tableColumns`; an item open renders the classic 300px-list + detail split. The two cross-fade (`AnimatedSwitcher` over the split layer, using the motion tokens' standard transition/easing) rather than swap instantly.
- **The desktop table is never disposed on open/close.** It stays mounted behind the split in a `Stack`, covered with `IgnorePointer`/`ExcludeSemantics` while the split is shown, so re-opening/closing does not pay the table's first-mount cost again (~150ms measured on web for a fresh `LayrzTable` build).
- **Narrow-band Navigator requirement**: `LayrzBottomSheet.show` always pushes on the **root** Navigator (`Navigator.maybeOf(context, rootNavigator: true)`), so the sheet's `Overlay` entry sits outside any nested `Navigator` (e.g. a go_router `ShellRoute`'s own) and outside `LayrzLayout`'s `SelectableRegion`/chrome. A missing root Navigator fires a debug `assert` and the sheet silently does not appear (no release crash).
- **Selection persists across a breakpoint crossing**: narrow → wide pops the sheet but keeps the detail open (returning to the split, not the table, since the controller is still open); wide → narrow auto-opens the sheet for the already-open item.
- **Dismissal semantics**: a barrier tap, drag-to-dismiss, or system back on the narrow sheet closes the controller (de-highlighting the row and returning the wide layout to its table) — UNLESS the shell itself initiated the dismissal for a band-transition reason, in which case selection is preserved.
- **No automatic grouping, sorting, or state restoration** — all are the consumer's responsibility, both for `items` order and for `tableController`'s sort/search/column state.
- **Detail pane has its own independent `SelectableRegion`**, scoped so a text selection there cannot reach the page behind it, in both wide and narrow presentations.
- **There is no foldable-hinge-aware split.** The shell has exactly two width-driven presentations (wide/narrow, via `context.isCompact`); a foldable device's hinge is not specially detected or accommodated — it follows the ordinary wide/narrow path by width like any other device.
