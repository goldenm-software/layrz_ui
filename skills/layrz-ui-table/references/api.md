# LayrzTable — API Reference

Source: `lib/src/table/src/`
- `LayrzTable<T>` class — `table.dart`
- `LayrzColumn<T>` class — `column.dart`
- `LayrzTableController<T>` class — `controller.dart`
- `LayrzTableAction` class — `table_action.dart`
- `LayrzTableEvent<T>` sealed class + subclasses — `events.dart`
- `LayrzTableOnTapBehavior` enum — `on_tap_behavior.dart`

---

## Examples

```dart
// Basic table
LayrzTable<User>(
  items: users,
  columns: [
    LayrzColumn<User>(
      key: const ValueKey('name'),
      headerText: 'Name',
      width: 200,
      valueBuilder: (user) => user.name,
    ),
  ],
)

// With multiselect, row actions, and a controller
final controller = LayrzTableController<User>(minVisibleColumns: 2);

LayrzTable<User>(
  items: users,
  columns: columns,
  controller: controller,
  hasMultiselect: true,
  actionsCount: 1,
  actionsBuilder: (user) => [
    LayrzTableAction(icon: MdiIcons.pencilOutline, labelText: 'Edit', onTap: () => _edit(user)),
  ],
  onFilteredCountChanged: (count) => print('Showing $count rows'),
)

// Disabling search; a column with a resize ceiling
LayrzTable<User>(
  items: users,
  canSearch: false,
  minColumnWidth: 120,
  columns: [
    LayrzColumn<User>(key: const ValueKey('id'), headerText: 'ID', width: 80, valueBuilder: (u) => u.id),
    LayrzColumn<User>(
      key: const ValueKey('name'),
      headerText: 'Name',
      width: 200,
      maxWidth: 400,
      valueBuilder: (u) => u.name,
    ),
  ],
)

// Restoring persisted column widths into a fresh controller
final controller = LayrzTableController<User>(
  columnOrder: [const ValueKey('id'), const ValueKey('name')],
  columnWidths: {const ValueKey('name'): 260}, // e.g. from a persisted LayrzTableColumnWidthsEvent
);
```

---

## Constructor

```dart
LayrzTable({
  required this.items,
  required this.columns,
  this.controller,
  this.actionsBuilder,
  this.actionsCount = 0,
  this.hasMultiselect = false,
  this.canSearch = true,
  this.minColumnWidth = 150,
  this.height = 50,
  this.headerHeight = 40,
  this.emptyText,
  this.emptySearchText,
  this.loadingLabelText,
  this.copyToClipboardText,
  this.onFilteredCountChanged,
  this.isLoading = false,
  super.key,
}) : assert(columns.isNotEmpty, 'columns must not be empty'),
     assert(minColumnWidth > 0, 'minColumnWidth must be greater than 0'),
     assert(actionsCount >= 0, 'actionsCount must not be negative'),
     assert(
       columns.map((column) => column.key).toSet().length == columns.length,
       'every LayrzColumn.key must be unique within columns',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `items` | `List<T>` | — | Required. Rows to render, before filtering and sorting. |
| `columns` | `List<LayrzColumn<T>>` | — | Required, non-empty. Every `key` must be unique. Actual order/visibility comes from `controller`, not this list's order. |
| `controller` | `LayrzTableController<T>?` | `null` | When `null`, the table creates and owns (and disposes) an internal controller. |
| `actionsBuilder` | `List<LayrzTableAction> Function(T item)?` | `null` | Only ever called when `actionsCount > 0`. |
| `actionsCount` | `int` | `0` | Single source of truth for the actions column's existence. Must not be negative. |
| `hasMultiselect` | `bool` | `false` | Renders a pinned-left checkbox cell per row and a header select-all when `true`. |
| `canSearch` | `bool` | `true` | Whether the toolbar renders a search field. The column-menu trigger stays visible regardless. |
| `minColumnWidth` | `double` | `150` | Floor for every column's effective (resized-or-default) width. Must be `> 0`. |
| `height` | `double` | `50` | Fixed height of every data row. |
| `headerHeight` | `double` | `40` | Fixed height of the frozen header row. |
| `emptyText` | `String?` | `null` | Shown when `items` is empty. Localized house default when `null`. |
| `emptySearchText` | `String?` | `null` | Shown when `items` is non-empty but search matches nothing. Localized house default when `null`. |
| `loadingLabelText` | `String?` | `null` | Unused — kept only for constructor compatibility; the label-bearing spinner it fed was replaced by the top progress strip. |
| `copyToClipboardText` | `String?` | `null` | Confirmation-toast title for the default copy-to-clipboard cell tap. House default when `null`. |
| `onFilteredCountChanged` | `void Function(int count)?` | `null` | Called whenever the filtered+sorted row count changes. |
| `isLoading` | `bool` | `false` | Animates the always-reserved 2px top progress strip. Header/rows are never hidden while loading. |

---

## `LayrzColumn<T>` — Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `key` | `Key` | — | Required, unique across the table's `columns`. Equality/`hashCode` are based solely on this. |
| `headerText` | `String` | — | Required. Text shown in the header cell. |
| `valueBuilder` | `String Function(T item)` | — | Required. Extracts display/sort/search string. **Must be isolate-safe.** |
| `richTextBuilder` | `List<InlineSpan> Function(T item)?` | `null` | Overrides visual rendering only — search/default sort still use `valueBuilder`. |
| `alignment` | `Alignment` | `Alignment.centerLeft` | Horizontal alignment of cell content. |
| `isSortable` | `bool` | `true` | Whether tapping the header toggles sort. |
| `width` | `double` | — | Required. The column's default fixed width in logical pixels — no flex/share-remaining-space behavior exists. A user can resize the column by dragging the header handle; the effective width is `controller.columnWidthOverride(key) ?? width`, clamped to `[minColumnWidth, maxWidth]`. |
| `maxWidth` | `double?` | `null` | Resize ceiling in logical pixels. `null` means no upper bound — the column can be dragged arbitrarily wide, with the table scrolling horizontally to accommodate. |
| `onTap` | `CellTap<T>?` | `null` | `typedef CellTap<T> = void Function(T item)`. `null` falls back to copy-to-clipboard. |
| `customSort` | `int Function(T a, T b, bool ascending)?` | `null` | Overrides the default comparator. **Must be isolate-safe.** Must already account for `ascending`. |

`LayrzColumn` also has `copyWith({...})`.

---

## `LayrzTableController<T>` — Constructor & Members

```dart
LayrzTableController({
  List<Key> columnOrder = const [],
  Set<Key> hiddenColumns = const {},
  Map<Key, double> columnWidths = const {},
  this.minVisibleColumns = 1,
}) : assert(minVisibleColumns >= 1, 'minVisibleColumns must be at least 1');
```

| Member | Signature | Notes |
|---|---|---|
| `minVisibleColumns` | `final int` | Floor enforced by `setColumnVisible`/`toggleColumn` (refuse) and `syncColumns`/`setHiddenColumns` (repair/clamp). |
| `columnOrder` | `List<Key> get` | Every known column key, in display order, hidden columns included. |
| `hiddenColumns` | `Set<Key> get` | Currently-hidden column keys. |
| `visibleColumnKeys` | `Set<Key> get` | Subset of `columnOrder` not in `hiddenColumns`. |
| `columnWidthOverrides` | `Map<Key, double> get` | Every column the user has explicitly resized, keyed by column `Key`, mapped to its override width. A column absent from this map renders at its own `LayrzColumn.width` default. Seed via the constructor's `columnWidths`. |
| `columnWidthOverride(Key key)` | `double? get` | The override for one column, or `null` if unresized. |
| `searchText` | `String get` | Current search filter text. |
| `sortColumnKey` | `Key? get` | `null` means unsorted. |
| `sortAscending` | `bool get` | Meaningless while `sortColumnKey` is `null`. |
| `selection` | `Set<T> get` | Current multi-selection. |
| `visibleCount` | `ValueListenable<int> get` | Rows currently shown after search filter. `0` until first layout. |
| `totalCount` | `ValueListenable<int> get` | Length of the unfiltered dataset. `0` until first layout. |
| `events` | `Stream<LayrzTableEvent<T>> get` | Broadcast stream of every mutation, typed. |
| `sort(Key columnKey, bool ascending)` | `void` | Sets sort column/direction. |
| `clearSort()` | `void` | Returns to unsorted (input) order. |
| `search(String text)` | `void` | Sets search text verbatim (no trimming). |
| `setColumnVisible(Key key, bool visible)` | `void` | Hiding is refused (no-op) if it would drop below `minVisibleColumns`. |
| `toggleColumn(Key key)` | `void` | No-op on an unknown key. |
| `reorderColumn(Key key, int targetVisibleIndex)` | `void` | Moves a **visible** column among visible columns only; hidden columns keep their anchor. |
| `syncColumns(List<LayrzColumn<T>> columns)` | `void` | Reconciles by pure key membership; called internally by `LayrzTable` on column-set changes. |
| `setColumnOrder(List<Key> order)` | `void` | Wholesale order replacement, reconciled by known-key membership. |
| `setHiddenColumns(Set<Key> hidden)` | `void` | Wholesale hidden-set replacement; clamped (not refused) against `minVisibleColumns`. |
| `setColumnWidth(Key key, double width)` | `void` | Sets an explicit width override for one column. Stored verbatim (not clamped here — the table clamps effective width to `[minColumnWidth, maxWidth]` when resolving). No-op if unchanged. |
| `clearColumnWidth(Key key)` | `void` | Removes a column's width override, returning it to its `LayrzColumn.width` default. No-op if it had none. |
| `selectItem(T item)` / `deselectItem(T item)` / `toggleSelection(T item)` | `void` | Single-item selection mutators. |
| `selectAll(Iterable<T> items)` | `void` | Replaces selection with every item given. |
| `clearSelection()` | `void` | Empties the selection. |
| `refresh()` | `void` | No state change; always notifies and emits `LayrzTableRefreshEvent`. |
| `updateCounts({required int visible, required int total})` | `void` | Write side of `visibleCount`/`totalCount`; called by `LayrzTable` itself. |
| `dispose()` | `void` | Closes the `events` stream; caller-owned if the controller was caller-supplied. |

---

## `LayrzTableAction` — Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `icon` | `IconData` | — | Required. Shown icon-only (wide) or with `labelText` (compact). |
| `labelText` | `String` | — | Required. Accessibility/tooltip label; visible label on compact viewports. |
| `onTap` | `VoidCallback` | — | Required. |
| `style` | `LayrzButtonStyle?` | `null` | `null` uses the table's own default row-action style. |
| `color` | `Color?` | `null` | `null` resolves the table/button default accent color. |
| `disabled` | `bool` | `false` | Non-interactive when `true`. |

Also has `copyWith({...})`.

---

## `LayrzTableEvent<T>` sealed hierarchy

| Type | Payload | Emitted by |
|---|---|---|
| `LayrzTableSortEvent<T>` | `columnKey: Key?`, `ascending: bool` | `sort`, `clearSort` (`columnKey: null` on clear) |
| `LayrzTableSearchEvent<T>` | `searchText: String` | `search` |
| `LayrzTableSelectionEvent<T>` | `selection: Set<T>` | `selectItem`, `deselectItem`, `toggleSelection`, `selectAll`, `clearSelection` |
| `LayrzTableColumnsEvent<T>` | `columnOrder: List<Key>`, `hiddenColumns: Set<Key>` | `setColumnVisible`, `toggleColumn`, `reorderColumn`, `syncColumns`, `setColumnOrder`, `setHiddenColumns` |
| `LayrzTableColumnWidthsEvent<T>` | `columnWidths: Map<Key, double>` | `setColumnWidth`, `clearColumnWidth`, and the header resize-drag gesture |
| `LayrzTableRefreshEvent<T>` | none | `refresh` |

`LayrzTableEvent<T>` is `sealed` — a `switch` over it is exhaustive with no `default` case needed (six subclasses total). `LayrzTableColumnsEvent` carries `hiddenColumns`, not `visibleColumnKeys` — a key present in `columnOrder` but absent from `hiddenColumns` is visible. This shape mirrors the controller's own constructor, so an event payload can be fed straight into `setColumnOrder`/`setHiddenColumns` to restore a persisted layout. `LayrzTableColumnWidthsEvent.columnWidths` mirrors `columnWidthOverrides`/the constructor's `columnWidths` the same way — a column absent from the map is at its default width.

---

## `LayrzTableOnTapBehavior` enum

| Value | Description |
|---|---|
| `.none` | No default tap behavior applied; cell renders non-interactive to tap. |
| `.copyToClipboard` | Copies the cell's displayed text and shows a confirmation toast. This is the **effective** behavior whenever a column's `onTap` is `null` — kept for API-surface parity with `layrz_theme`; it does not itself drive dispatch (that decision is per-column, by `LayrzColumn.onTap`'s presence). |

---

## Behavior notes

- **No paginator**: the entire filtered/sorted dataset renders through one virtualized `ListView.builder`.
- **Search cache**: a lowercased display-string cache is built once per `items`/`columns` identity change (not per keystroke); search filters against the cache.
- **Off-thread sort**: the default comparator path sends only precomputed sort keys and an index array across the isolate boundary — never the row objects. A `customSort` column instead sends the whole filtered item list across the boundary, since it must compare actual `T` objects.
- **Column widths** are computed once per `LayoutBuilder` pass and handed identically to the header and every row, so cells align pixel-for-pixel. The actions column width is computed from a fixed formula over `actionsCount`, never from actual button content.
- **No flex columns**: every `LayrzColumn.width` is a fixed pixel value. When the visible columns' widths sum wider than the available width, the data area scrolls horizontally; when narrower, the remainder is trailing whitespace — columns never stretch to fill it.
- **Column resizing**: dragging the handle on a header cell's right edge sets an override via `LayrzTableController.setColumnWidth`, clamped to `[minColumnWidth, LayrzColumn.maxWidth]`. The effective width used everywhere (header, cells, layout) is `controller.columnWidthOverride(key) ?? column.width`.
- **Select-all** is computed against the full `items` list, not the search-filtered subset — selecting all always means all, regardless of the current search.
- **Column reconciliation** (`syncColumns`, `setColumnOrder`, `setHiddenColumns`) is always by `Key` membership, never by index.
- **Disposal**: caller-owned when `controller` is supplied; table-owned when omitted.
