# LayrzTreeView&lt;T&gt; — API Reference

Source: `lib/src/trees/src/tree_view.dart`
- `LayrzTreeView<T>` class (box form, wraps `LayrzSliverTreeView<T>` in its own `CustomScrollView`)
- Companion: `tree_sliver_view.dart` — `LayrzSliverTreeView<T>` (sliver form; the tree is implemented exactly once, here)
- Companion: `tree_controller.dart` — `LayrzTreeController`, `LayrzTreeControllerBinding`
- Companion: `tree_node.dart` — `LayrzTreeNode<T>`, `LayrzTreeNodeBuilder<T>` typedef
- Companion: `tree_selection.dart` — `LayrzTreeSelectionController<T>`, `LayrzTreeSelectionMode` enum
- Companion: `tree_row.dart`, `tree_indent_guide.dart` — `LayrzTreeRow<T>`, `LayrzTreeIndentGuide` (default row chrome, exported for composition)

---

## Examples

```dart
// Minimal box-form tree
LayrzTreeView<String>(
  nodes: [
    LayrzTreeNode(
      id: 'fleet',
      content: 'Fleet',
      initiallyExpanded: true,
      children: [
        LayrzTreeNode(id: 'truck-1', content: 'Truck 1'),
        LayrzTreeNode(id: 'truck-2', content: 'Truck 2'),
      ],
    ),
  ],
  selectable: true,
  onSelectionChanged: (selectedIds) => print(selectedIds),
)

// Sliver form composed inside an existing CustomScrollView
CustomScrollView(
  slivers: [
    LayrzSliverTreeView<String>(nodes: nodes, selectable: true),
  ],
)

// Cascading selection, externally-owned controller
final selectionController = LayrzTreeSelectionController<Asset>(
  roots: assetNodes,
  mode: .cascading,
);

LayrzTreeView<Asset>(
  nodes: assetNodes,
  selectable: true,
  selectionController: selectionController,
  onSelectionChanged: (ids) => debugPrint('$ids'),
)

// Custom node builder
LayrzTreeView<String>(
  nodes: nodes,
  nodeBuilder: (context, node, depth, isExpanded, isLeaf, isSelected, isPartiallySelected, onToggle, onSelect) {
    return Text(node.content);
  },
)
```

---

## Constructor: `LayrzTreeView<T>`

```dart
const LayrzTreeView({
  required this.nodes,
  this.nodeBuilder,
  this.controller,
  this.selectionController,
  this.selectable = false,
  this.onSelectionChanged,
  this.padding,
  super.key,
});
```

### Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `nodes` | `List<LayrzTreeNode<T>>` | required | Root-level nodes; nesting comes via each node's `children`. |
| `nodeBuilder` | `LayrzTreeNodeBuilder<T>?` | `null` | Builds each row's content. `null` ⇒ `Text(node.content.toString())`, always wrapped in `LayrzTreeRow` for chrome/semantics. |
| `controller` | `LayrzTreeController?` | `null` | `null` ⇒ widget creates/owns/disposes its own. Non-null ⇒ caller-owned; instance must never be swapped (asserted). |
| `selectionController` | `LayrzTreeSelectionController<T>?` | `null` | Only relevant when `selectable` is true. Same ownership contract as `controller`. |
| `selectable` | `bool` | `false` | `false` ⇒ no checkbox, no selection semantics on any row, regardless of `selectionController`. |
| `onSelectionChanged` | `void Function(Set<Object> selectedIds)?` | `null` | Fires whenever the selected-id set changes. |
| `padding` | `EdgeInsetsGeometry?` | `null` | `LayrzTreeView` only — padding around the scrollable content (applied via `SliverPadding`). |

`LayrzSliverTreeView<T>` has the identical constructor shape minus `padding` (slivers don't self-pad).

---

## `LayrzTreeNode<T>`

```dart
const LayrzTreeNode({
  required this.id,
  required this.content,
  this.children = const [],
  this.initiallyExpanded = false,
});
```

| Property | Type | Default | Notes |
|---|---|---|---|
| `id` | `Object` | required | Stable identity for selection/lookup. Must be unique across the whole tree — a collision is a caller error with undefined selection behavior. |
| `content` | `T` | required | Caller payload, passed to `LayrzTreeNodeBuilder`. |
| `children` | `List<LayrzTreeNode<T>>` | `[]` | Empty ⇒ leaf. Fixed at construction — no lazy loading. |
| `initiallyExpanded` | `bool` | `false` | Only meaningful when `children` is non-empty. Ignored after first build — expansion is then owned by the SDK's `TreeSliver`. |

`@immutable`, `==`/`hashCode` by `id` only.

### `LayrzTreeNodeBuilder<T>` typedef

```dart
typedef LayrzTreeNodeBuilder<T> = Widget Function(
  BuildContext context,
  LayrzTreeNode<T> node,
  int depth,
  bool isExpanded,
  bool isLeaf,
  bool isSelected,
  bool isPartiallySelected,
  VoidCallback? onToggle,
  VoidCallback? onSelect,
);
```

`depth` is zero-based (0 = root). `onToggle` is `null` for a leaf row. `onSelect` is non-null only when selection is enabled for the tree.

---

## `LayrzTreeController extends ChangeNotifier`

```dart
LayrzTreeController();
```

| Member | Signature | Notes |
|---|---|---|
| `isExpanded(Object id)` | `bool` | `false` for an unbound or unknown id. |
| `expand(Object id)` / `collapse(Object id)` / `toggle(Object id)` | `void` | Programmatic expand/collapse by caller id. |
| `expandAll()` / `collapseAll()` | `void` | Bulk expand/collapse. |
| `activeId` | `Object? get` | The keyboard-navigation active row's id, or `null`. |
| `setActive(Object id)` | `void` | Moves keyboard focus to `id`, if currently visible. |
| `bind(LayrzTreeControllerBinding binding)` | `void` | Installs live callbacks; called internally by `LayrzSliverTreeView`'s state — not part of the public consumer API. |
| `unbind()` | `void` | Detaches from the bound tree; called internally on dispose. |

Before a tree binds it, every query returns a safe "unbound" default (`isExpanded` → `false`, `activeId` → `null`).

---

## `LayrzTreeSelectionController<T> extends ChangeNotifier`

```dart
LayrzTreeSelectionController({
  required List<LayrzTreeNode<T>> roots,
  LayrzTreeSelectionMode mode = LayrzTreeSelectionMode.independent,
  Set<Object>? initialSelectedIds,
});
```

| Member | Signature | Notes |
|---|---|---|
| `mode` | `LayrzTreeSelectionMode` get/set | Changing it does not retroactively alter the current selection — only future `toggle` calls. |
| `selectedIds` | `Set<Object> get` | Unmodifiable. Under `.cascading`, a partially-selected parent is excluded — it surfaces via `isPartiallySelected` instead. |
| `isSelected(Object id)` | `bool` | Query full-selection state. |
| `isPartiallySelected(Object id)` | `bool` | Always `false` under `.independent`. |
| `toggle(Object id)` | `void` | Toggles selection, applying cascade/ancestor-recompute rules for the active mode. |
| `clear()` | `void` | Clears every selected id. |
| `updateRoots(List<LayrzTreeNode<T>> roots)` | `void` | Called internally when `nodes` changes, so cascade logic walks the current tree shape. |

### `LayrzTreeSelectionMode` enum

| Value | Behavior |
|---|---|
| `.independent` (default) | Selecting a node affects only that node; parent/children untouched. Matches `LayrzChip`'s conventions and most desktop file-tree explorers. |
| `.cascading` | Selecting a parent selects/deselects every descendant. A partly-selected parent reports `isPartiallySelected` — a third, indeterminate state (dash glyph, not a checkmark). |

`.independent` is the default deliberately — the more conservative choice for a shared primitive; a caller who didn't expect cascading and gets it anyway has silently over-selected.

---

## Companion widgets

- **`LayrzTreeRow<T>`** — the default row chrome: hover/press/selected/keyboard-active tinting, indent guides, checkbox (when selectable), and the row's merged `Semantics` node. Exported for composition when building a custom `nodeBuilder` that still wants the standard chrome.
- **`LayrzTreeIndentGuide`** — paints one vertical guide line per ancestor level. Carries no semantics of its own — depth is communicated via the row's own `Semantics` label instead.

---

## Behavior notes

- **`LayrzSliverTreeView` is the single implementation** — `LayrzTreeView` is a thin `CustomScrollView` + `SliverPadding` wrapper around it; there is no separate tree logic in the box form.
- **Keyboard navigation detail**: Up/Down move the active row across currently-visible rows only (a collapsed subtree's descendants are never included, matching what a sighted user can see). Right expands a collapsed row or descends into its first child if already expanded (no-op on a leaf). Left collapses an expanded row or ascends to its parent if already collapsed/a leaf. Arrow keys never call into `LayrzTreeSelectionController`.
- **Row interaction-state fills** (composable, not mutually exclusive): resting = transparent; hovered = `sf3` tint; pressed = `sf4` tint (stronger); selected/partially-selected = `primary` at `alpha: 0.12` (direct alpha, not a generated shade — avoids `LayrzColorSwatch.fromColor`'s dark-seed clamp-to-black defect); a selected row's hover/press tint composes on top rather than replacing the selected tint; keyboard-active is a constant-width outline whose color changes, composing with any of the above.
- **The row never draws its own border/radius** and has no parameter for a caller-supplied radius — frame it yourself (`ClipRRect`/`DecoratedBox`) if you want a rounded bordered container; add your own `ClipRRect` around the tree too if you need scrolled content clipped to that frame during fast scrolling.
- **Accessibility**: each row's `Semantics` states role, expansion, depth ("Level 2 of 3"), and selection as one merged announcement. `focused` is only ever set to `true` (never explicitly `false`) — set only on the actually-active row.
