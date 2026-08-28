import 'package:flutter/widgets.dart';

import 'tree_controller.dart';
import 'tree_node.dart';
import 'tree_row.dart';
import 'tree_selection.dart';

/// A sliver-form tree view built directly on the SDK's `TreeSliver`, for
/// composing inside a `CustomScrollView` — e.g. one of
/// `LayrzScaffoldShell`'s panes.
///
/// [LayrzSliverTreeView] is the integration point between this module's
/// caller-facing [LayrzTreeNode] shape and the SDK's `TreeSliverNode<T>` /
/// `TreeSliverController`. It owns exactly one responsibility: turning
/// [nodes] into the SDK's tree structure and rendering each row via
/// [nodeBuilder] (or the default [LayrzTreeRow] when none is supplied).
/// Selection is deliberately **not** implemented here — every selection
/// decision lives in `tree_selection.dart`'s [LayrzTreeSelectionController],
/// and this widget only reads from it (`isSelected`/`isPartiallySelected`)
/// and forwards taps into it (`toggle`). That split is what lets either
/// [LayrzTreeSelectionMode] be swapped without touching this file.
///
/// [LayrzTreeView] (the box form) wraps this widget in its own
/// `CustomScrollView`; the tree is implemented once, here.
class LayrzSliverTreeView<T> extends StatefulWidget {
  /// Creates a [LayrzSliverTreeView].
  const LayrzSliverTreeView({
    required this.nodes,
    this.nodeBuilder,
    this.controller,
    this.selectionController,
    this.selectable = false,
    this.onSelectionChanged,
    super.key,
  });

  /// The root-level nodes of the tree. Nested nodes are supplied via each
  /// [LayrzTreeNode.children].
  final List<LayrzTreeNode<T>> nodes;

  /// Builds the widget shown for each node's content. When null, a
  /// [Text] built from `node.content.toString()` is used — matching the
  /// SDK's own `TreeSliver.defaultTreeNodeBuilder` fallback shape, but always
  /// wrapped in [LayrzTreeRow] for chrome and semantics.
  final LayrzTreeNodeBuilder<T>? nodeBuilder;

  /// Optional controller for programmatic expand/collapse and keyboard
  /// navigation.
  ///
  /// If null, this widget creates, owns and disposes an internal controller.
  /// If non-null, the caller owns disposal and the instance must never be
  /// swapped; an assertion fails if a different controller is passed on a
  /// rebuild — matching the pattern used by `LayrzStepper`/`LayrzCalendar`.
  final LayrzTreeController? controller;

  /// Optional controller for multi-node selection.
  ///
  /// If null and [selectable] is true, this widget creates, owns and
  /// disposes an internal [LayrzTreeSelectionController]. If non-null, the
  /// caller owns disposal and the instance must never be swapped.
  final LayrzTreeSelectionController<T>? selectionController;

  /// Whether nodes in this tree can be selected at all.
  ///
  /// When false (the default), no checkbox affordance is rendered and no row
  /// carries selection semantics, regardless of whether
  /// [selectionController] is supplied. This lets a tree opt out of
  /// selection entirely rather than merely start with an empty selection.
  final bool selectable;

  /// Called whenever the set of selected node ids changes, with the new set.
  final void Function(Set<Object> selectedIds)? onSelectionChanged;

  @override
  State<LayrzSliverTreeView<T>> createState() => _LayrzSliverTreeViewState<T>();
}

class _LayrzSliverTreeViewState<T> extends State<LayrzSliverTreeView<T>> {
  final TreeSliverController _sdkController = TreeSliverController();

  LayrzTreeController? _internalController;
  LayrzTreeController get _effectiveController => widget.controller ?? _internalController!;

  LayrzTreeSelectionController<T>? _internalSelectionController;
  LayrzTreeSelectionController<T>? get _effectiveSelectionController =>
      widget.selectionController ?? _internalSelectionController;

  late List<TreeSliverNode<LayrzTreeNode<T>>> _tree;
  Object? _activeId;

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _internalController = LayrzTreeController();
    }
    if (widget.selectable && widget.selectionController == null) {
      _internalSelectionController = LayrzTreeSelectionController<T>(roots: widget.nodes);
    }
    _effectiveSelectionController?.addListener(_onSelectionChanged);

    _tree = _buildSdkTree(widget.nodes);
    _bindController();
  }

  @override
  void didUpdateWidget(LayrzSliverTreeView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    assert(
      widget.controller == oldWidget.controller,
      'LayrzSliverTreeView does not support changing the controller instance. '
      'The same controller must be passed, or null must remain null.',
    );
    assert(
      widget.selectionController == oldWidget.selectionController,
      'LayrzSliverTreeView does not support changing the selectionController instance. '
      'The same controller must be passed, or null must remain null.',
    );

    if (widget.nodes != oldWidget.nodes) {
      _tree = _buildSdkTree(widget.nodes);
      _effectiveSelectionController?.updateRoots(widget.nodes);
    }

    if (oldWidget.selectionController != widget.selectionController) {
      oldWidget.selectionController?.removeListener(_onSelectionChanged);
      _effectiveSelectionController?.addListener(_onSelectionChanged);
    }
  }

  @override
  void dispose() {
    _effectiveController.unbind();
    _effectiveSelectionController?.removeListener(_onSelectionChanged);
    if (widget.controller == null) {
      _internalController?.dispose();
    }
    if (widget.selectionController == null) {
      _internalSelectionController?.dispose();
    }
    super.dispose();
  }

  void _onSelectionChanged() {
    setState(() {});
    widget.onSelectionChanged?.call(_effectiveSelectionController?.selectedIds ?? const {});
  }

  void _bindController() {
    _effectiveController.bind(
      LayrzTreeControllerBinding(
        isExpanded: (id) => _findSdkNode(id)?.isExpanded ?? false,
        expand: (id) {
          final node = _findSdkNode(id);
          if (node != null) _sdkController.expandNode(node);
        },
        collapse: (id) {
          final node = _findSdkNode(id);
          if (node != null) _sdkController.collapseNode(node);
        },
        toggle: (id) {
          final node = _findSdkNode(id);
          if (node != null) _sdkController.toggleNode(node);
        },
        expandAll: _sdkController.expandAll,
        collapseAll: _sdkController.collapseAll,
        getActiveId: () => _activeId,
        setActive: (id) => setState(() => _activeId = id),
      ),
    );
  }

  List<TreeSliverNode<LayrzTreeNode<T>>> _buildSdkTree(List<LayrzTreeNode<T>> nodes) {
    return nodes
        .map(
          (node) => TreeSliverNode<LayrzTreeNode<T>>(
            node,
            expanded: node.initiallyExpanded,
            children: _buildSdkTree(node.children),
          ),
        )
        .toList();
  }

  TreeSliverNode<LayrzTreeNode<T>>? _findSdkNode(Object id) => _findSdkNodeIn(id, _tree);

  TreeSliverNode<LayrzTreeNode<T>>? _findSdkNodeIn(Object id, List<TreeSliverNode<LayrzTreeNode<T>>> nodes) {
    for (final node in nodes) {
      if (node.content.id == id) return node;
      if (node.children.isNotEmpty) {
        final found = _findSdkNodeIn(id, node.children);
        if (found != null) return found;
      }
    }
    return null;
  }

  int _maxDepth(List<LayrzTreeNode<T>> nodes, [int depth = 0]) {
    var max = depth;
    for (final node in nodes) {
      if (node.children.isNotEmpty) {
        final childDepth = _maxDepth(node.children, depth + 1);
        if (childDepth > max) max = childDepth;
      }
    }
    return max;
  }

  @override
  Widget build(BuildContext context) {
    final totalDepth = _maxDepth(widget.nodes);
    final selection = _effectiveSelectionController;

    return TreeSliver<LayrzTreeNode<T>>(
      tree: _tree,
      controller: _sdkController,
      treeNodeBuilder: (context, node, animationStyle) {
        // The SDK's TreeSliverNodeBuilder typedef is fixed to
        // TreeSliverNode<Object?> regardless of this widget's own type
        // parameter, since treeNodeBuilder must have a stable, non-generic
        // signature. TreeSliver<T> always calls back with the same
        // TreeSliverNode<T> instances it was built from (see
        // _TreeSliverState.build in sliver_tree.dart), so this cast is safe.
        final sdkNode = node as TreeSliverNode<LayrzTreeNode<T>>;
        final layrzNode = sdkNode.content;
        final depth = sdkNode.depth ?? 0;
        final isLeaf = layrzNode.children.isEmpty;
        final isSelected = selection?.isSelected(layrzNode.id) ?? false;
        final isPartiallySelected = selection?.isPartiallySelected(layrzNode.id) ?? false;

        void onToggle() => _sdkController.toggleNode(sdkNode);
        void onSelect() => selection?.toggle(layrzNode.id);

        final content = widget.nodeBuilder != null
            ? widget.nodeBuilder!(
                context,
                layrzNode,
                depth,
                sdkNode.isExpanded,
                isLeaf,
                isSelected,
                isPartiallySelected,
                isLeaf ? null : onToggle,
                widget.selectable ? onSelect : null,
              )
            : Text(layrzNode.content.toString());

        return LayrzTreeRow<T>(
          node: layrzNode,
          depth: depth,
          isExpanded: sdkNode.isExpanded,
          isLeaf: isLeaf,
          isSelected: isSelected,
          isPartiallySelected: isPartiallySelected,
          totalDepth: totalDepth,
          onToggle: isLeaf ? null : onToggle,
          onSelect: widget.selectable ? onSelect : null,
          child: content,
        );
      },
    );
  }
}
