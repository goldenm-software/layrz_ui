import 'package:flutter/widgets.dart';

import 'tree_controller.dart';
import 'tree_node.dart';
import 'tree_selection.dart';
import 'tree_sliver_view.dart';

/// A self-scrolling, box-form tree view with expand/collapse and optional
/// multi-node selection.
///
/// [LayrzTreeView] is the easy-to-drop-in form: it wraps [LayrzSliverTreeView]
/// in its own `CustomScrollView`, so it behaves like an ordinary `ListView`-ish
/// widget and can be placed directly in a layout without the caller managing
/// a surrounding scroll view. Use [LayrzSliverTreeView] instead when composing
/// inside an existing `CustomScrollView` (e.g. one of `LayrzScaffoldShell`'s
/// panes) — the tree itself is implemented exactly once, in
/// `tree_sliver_view.dart`; this widget adds no tree logic of its own.
///
/// **Selection** (independent or cascading — see [LayrzTreeSelectionMode]) and
/// **expansion** (via [LayrzTreeController]) are both optional and both
/// implemented in their own files, cleanly separable from this widget and
/// from the SDK integration in `tree_sliver_view.dart`.
class LayrzTreeView<T> extends StatelessWidget {
  /// Creates a [LayrzTreeView].
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

  /// The root-level nodes of the tree. Nested nodes are supplied via each
  /// [LayrzTreeNode.children].
  final List<LayrzTreeNode<T>> nodes;

  /// Builds the widget shown for each node's content. When null, a
  /// [Text] built from `node.content.toString()` is used.
  final LayrzTreeNodeBuilder<T>? nodeBuilder;

  /// Optional controller for programmatic expand/collapse and keyboard
  /// navigation.
  ///
  /// If null, this widget creates, owns and disposes an internal controller.
  /// If non-null, the caller owns disposal and the instance must never be
  /// swapped between rebuilds.
  final LayrzTreeController? controller;

  /// Optional controller for multi-node selection.
  ///
  /// If null and [selectable] is true, this widget creates, owns and
  /// disposes an internal [LayrzTreeSelectionController]. If non-null, the
  /// caller owns disposal and the instance must never be swapped.
  final LayrzTreeSelectionController<T>? selectionController;

  /// Whether nodes in this tree can be selected at all. Defaults to `false`.
  final bool selectable;

  /// Called whenever the set of selected node ids changes, with the new set.
  final void Function(Set<Object> selectedIds)? onSelectionChanged;

  /// Padding applied around the scrollable tree content.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding ?? EdgeInsets.zero,
          sliver: LayrzSliverTreeView<T>(
            nodes: nodes,
            nodeBuilder: nodeBuilder,
            controller: controller,
            selectionController: selectionController,
            selectable: selectable,
            onSelectionChanged: onSelectionChanged,
          ),
        ),
      ],
    );
  }
}
