---
name: layrz-ui-tree-view
description: Use LayrzTreeView<T> in a layrz_ui Flutter widget. Apply when rendering a hierarchical, expandable/collapsible tree — independent or cascading multi-node selection via LayrzTreeSelectionController, arrow-key navigation via LayrzTreeController, or the sliver form LayrzSliverTreeView<T> composed inside an existing CustomScrollView.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.independent`, `.cascading`) — never the fully-qualified form (`LayrzTreeSelectionMode.independent`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A hierarchical, expandable/collapsible tree of caller data — file trees, org charts, nested categories.
- Use `LayrzTreeView<T>` (box form, self-scrolling) as the default drop-in choice.
- Use `LayrzSliverTreeView<T>` instead when composing inside an existing `CustomScrollView` (e.g. one of `LayrzScaffoldShell`'s panes) — the tree logic is implemented exactly once, in the sliver form.
- Set `selectable: true` for multi-node selection; choose `selectionMode: .cascading` when selecting a parent should select/deselect its descendants too.
- **Do not use** for a flat list with no hierarchy — a plain `ListView`/`LayrzTable` is simpler.
- **Do not use** `TreeView`/`TreeSliver` directly from `package:flutter/widgets.dart` when you want layrz_ui's selection model, styling, and accessibility — this wraps the SDK's `TreeSliver` for you.

---

## Minimal usage

```dart
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
```

---

## Key behaviors

- **`LayrzTreeNode<T>` uses an explicit `id`, not content equality** — identity is stated, never inferred from `content`. `id` must be unique across the *whole* tree, not just among siblings.
- **`children` is fixed at construction** — no async/lazy-loading contract for children appearing after first expand.
- **`selectionMode: .independent` is the default** — selecting a node affects only that node. `.cascading` selects/deselects every descendant, and a partly-selected parent reports `isPartiallySelected` (a third, indeterminate state).
- **Arrow keys move a keyboard cursor; they never mutate selection.** Up/Down move across currently-*visible* rows only (a collapsed subtree's descendants are not navigable). Right expands/descends; Left collapses/ascends.
- **Controller ownership** (both `controller` and `selectionController`): `null` ⇒ the widget creates/owns/disposes its own; non-null ⇒ caller-owned disposal, instance must never be swapped (asserted).
- **`selectable: false` (default) suppresses selection entirely** — no checkbox renders, no row carries selection semantics, regardless of whether `selectionController` is supplied.
- **Row fill is transparent at rest** — hover/press/selected/keyboard-active states each resolve a visible tint on top; the row never draws its own border or radius (any rounded frame is the caller's `ClipRRect`/`DecoratedBox`).

---

## Common patterns

```dart
// 1. Cascading selection with a custom node builder
LayrzTreeView<Asset>(
  nodes: assetNodes,
  selectable: true,
  selectionController: LayrzTreeSelectionController<Asset>(
    roots: assetNodes,
    mode: .cascading,
  ),
  nodeBuilder: (context, node, depth, isExpanded, isLeaf, isSelected, isPartiallySelected, onToggle, onSelect) {
    return Row(
      children: [
        if (!isLeaf)
          LayrzButton(icon: isExpanded ? MdiIcons.chevronDown : MdiIcons.chevronRight, onTap: onToggle, labelText: 'Toggle'),
        Text(node.content.name),
      ],
    );
  },
  onSelectionChanged: (ids) => setState(() => selectedAssetIds = ids),
)

// 2. Composing the sliver form inside a LayrzScaffoldShell pane
CustomScrollView(
  slivers: [
    LayrzSliverTreeView<String>(nodes: nodes, selectable: true),
  ],
)

// 3. Programmatic expand/collapse
final controller = LayrzTreeController();
controller.expandAll();
// ...
controller.collapse('fleet');
```

---

## Usage conventions

- Derive `LayrzTreeNode.id` from a stable domain identifier — never from array index or from `content` itself.
- Prefer `.independent` selection unless the domain genuinely models parent-implies-children (folders, org units) — `.cascading` can silently over-select for a caller who didn't expect it.
- Wrap `LayrzTreeView`/`LayrzSliverTreeView` in your own `ClipRRect` if you also frame it in a rounded, bordered container — the tree's own row fill only insets horizontally, it does not clip to an ancestor's corner radius during fast scrolling.
- Always dispose a caller-supplied `controller`/`selectionController` — the tree never disposes an externally-supplied instance.
