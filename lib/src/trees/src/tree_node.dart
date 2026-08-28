import 'package:flutter/widgets.dart';

/// An immutable data node for use with [LayrzTreeView] and [LayrzSliverTreeView].
///
/// [LayrzTreeNode] is the layrz_ui-facing node type. It is a thin, typed wrapper
/// that carries the caller's [content] plus an explicit [id] used as the stable
/// selection and lookup key (see [LayrzTreeSelectionController]). The SDK's own
/// `TreeSliverNode<T>` requires `==`-equality on its `content` to resolve nodes
/// (`TreeSliverController.getNodeFor`), which is fragile for arbitrary caller
/// data — two structurally distinct business objects can compare equal, or
/// the same object can fail to compare equal after a rebuild produces a new
/// instance. Requiring an explicit [id] sidesteps that entirely: identity is
/// stated, not inferred.
///
/// This class does not model expansion or depth — those remain properties of
/// the underlying `TreeSliverNode<LayrzTreeNode<T>>` that [LayrzTreeView] and
/// [LayrzSliverTreeView] build internally. [LayrzTreeNode] only describes the
/// tree's *shape* (content plus children) as supplied by the caller.
@immutable
class LayrzTreeNode<T> {
  /// Creates a [LayrzTreeNode].
  const LayrzTreeNode({
    required this.id,
    required this.content,
    this.children = const [],
    this.initiallyExpanded = false,
  });

  /// The stable identity of this node, used as the selection and lookup key.
  ///
  /// Must be unique across the whole tree (not just among siblings). Two
  /// nodes sharing an [id] is a caller error and produces undefined selection
  /// behaviour, since [LayrzTreeSelectionController] and the SDK's own
  /// content-keyed lookups both key off it.
  final Object id;

  /// The caller-supplied payload rendered by [LayrzTreeNodeBuilder].
  final T content;

  /// The child nodes of this node.
  ///
  /// An empty list marks this node as a leaf. Non-goal per the batch plan:
  /// this list is fixed at construction time — there is no async/lazy-loading
  /// contract for children appearing after first expand.
  final List<LayrzTreeNode<T>> children;

  /// Whether this node starts expanded when the tree first builds.
  ///
  /// Only meaningful when [children] is non-empty. Ignored thereafter — once
  /// built, expansion state is owned by the SDK's `TreeSliver` and mutated via
  /// its controller, not by this field.
  final bool initiallyExpanded;

  @override
  bool operator ==(Object other) => identical(this, other) || (other is LayrzTreeNode<T> && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Signature for a function that builds the [Widget] representing a single
/// row of a [LayrzTreeView] or [LayrzSliverTreeView].
///
/// [depth] is the zero-based nesting level (0 for a root node). [isExpanded]
/// and [isLeaf] describe the row's disclosure state, and [isSelected] /
/// [isPartiallySelected] describe its selection state under whichever
/// [LayrzTreeSelectionMode] is active — see `tree_selection.dart`. [onToggle]
/// switches the node's expanded state and is null for a leaf. [onSelect]
/// toggles the node's selection and is provided whenever selection is
/// enabled for the tree.
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
