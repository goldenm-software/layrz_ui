import 'package:flutter/services.dart';
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
///
/// **Keyboard navigation** moves [LayrzTreeController.activeId] across the
/// tree's currently-*visible* rows only — a collapsed subtree's descendants
/// are not navigable, matching what a sighted user can actually see:
/// * ArrowDown / ArrowUp move the active row to the next/previous visible row.
/// * ArrowRight expands the active row if collapsed, or descends into its
///   first child if already expanded (a no-op on a leaf).
/// * ArrowLeft collapses the active row if expanded, or ascends to its
///   parent if already collapsed (or a leaf).
/// Moving the active row is deliberately **not** the same as selecting it —
/// arrow keys never call into [LayrzTreeSelectionController]. See
/// `tree_style_spec.dart`'s `isActive` parameter for how the active row is
/// rendered.
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

  /// Owns keyboard focus for arrow-key navigation across the tree's rows.
  ///
  /// A single node for the whole tree, rather than one per row: the active
  /// row is tracked as data ([_activeId]), not as which widget currently
  /// holds Flutter's focus, so rows can come and go (expand/collapse changes
  /// which are mounted) without focus needing to migrate between widgets.
  final FocusNode _focusNode = FocusNode(debugLabel: 'LayrzSliverTreeView');

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
    _focusNode.dispose();
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
        setActive: _setActive,
      ),
    );
  }

  /// Sets [_activeId] to [id] and rebuilds so the newly-active row's visual
  /// (see `tree_style_spec.dart`'s `isActive`) actually updates. Used both by
  /// the public [LayrzTreeController.setActive] and by this widget's own
  /// arrow-key handling, so the two are indistinguishable to callers of the
  /// controller.
  void _setActive(Object id) => setState(() => _activeId = id);

  /// Flattens [_tree] into the rows currently visible to the user — a node
  /// appears here only if every one of its ancestors is expanded, matching
  /// exactly what a sighted user can see (and, therefore, what arrow-key
  /// navigation is allowed to move across). A collapsed subtree's children
  /// are omitted entirely rather than merely skipped, so ArrowDown/ArrowUp
  /// can never land the active row somewhere invisible.
  List<TreeSliverNode<LayrzTreeNode<T>>> _visibleRows() {
    final visible = <TreeSliverNode<LayrzTreeNode<T>>>[];
    void walk(List<TreeSliverNode<LayrzTreeNode<T>>> nodes) {
      for (final node in nodes) {
        visible.add(node);
        if (node.isExpanded && node.children.isNotEmpty) {
          walk(node.children);
        }
      }
    }

    walk(_tree);
    return visible;
  }

  /// Handles arrow-key navigation. See the class doc comment on
  /// [LayrzSliverTreeView] for the exact key-to-behaviour mapping.
  ///
  /// Returns [KeyEventResult.handled] for every arrow key this widget
  /// recognizes -- even ones that end up a no-op (e.g. ArrowRight on an
  /// already-expanded leaf) -- so the event does not keep bubbling into an
  /// ancestor's own shortcut handling. Any other key is ignored.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isArrowKey =
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowLeft;
    if (!isArrowKey) return KeyEventResult.ignored;

    final visible = _visibleRows();
    if (visible.isEmpty) return KeyEventResult.handled;

    final currentIndex = _activeId == null ? -1 : visible.indexWhere((n) => n.content.id == _activeId);

    if (key == LogicalKeyboardKey.arrowDown) {
      final nextIndex = currentIndex < 0 ? 0 : (currentIndex + 1).clamp(0, visible.length - 1);
      _setActive(visible[nextIndex].content.id);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      final prevIndex = currentIndex < 0 ? 0 : (currentIndex - 1).clamp(0, visible.length - 1);
      _setActive(visible[prevIndex].content.id);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _handleArrowRight(currentIndex < 0 ? visible.first : visible[currentIndex]);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _handleArrowLeft(currentIndex < 0 ? visible.first : visible[currentIndex]);
    }

    return KeyEventResult.handled;
  }

  /// ArrowRight: expands the active row if it is collapsed and has children;
  /// if it is already expanded, descends into its first child instead. A
  /// no-op on a leaf that is not expandable.
  void _handleArrowRight(TreeSliverNode<LayrzTreeNode<T>> active) {
    if (active.children.isEmpty) {
      _setActive(active.content.id);
      return;
    }

    if (!active.isExpanded) {
      _sdkController.expandNode(active);
      _setActive(active.content.id);
    } else {
      _setActive(active.children.first.content.id);
    }
  }

  /// ArrowLeft: collapses the active row if it is currently expanded; if it
  /// is already collapsed (or is a leaf), ascends to its parent instead. A
  /// no-op when a leaf root has no parent to ascend to.
  void _handleArrowLeft(TreeSliverNode<LayrzTreeNode<T>> active) {
    if (active.children.isNotEmpty && active.isExpanded) {
      _sdkController.collapseNode(active);
      _setActive(active.content.id);
      return;
    }

    final parent = _findParent(active.content.id, _tree, null);
    if (parent != null) {
      _setActive(parent.content.id);
    } else {
      _setActive(active.content.id);
    }
  }

  /// Finds the parent of the node identified by [id] within [nodes], or
  /// `null` if [id] is a root (or is not found at all). [ancestor] is the
  /// direct parent of every node in [nodes], carried down from the caller's
  /// own recursion level so a match at any depth can report it directly.
  TreeSliverNode<LayrzTreeNode<T>>? _findParent(
    Object id,
    List<TreeSliverNode<LayrzTreeNode<T>>> nodes,
    TreeSliverNode<LayrzTreeNode<T>>? ancestor,
  ) {
    for (final node in nodes) {
      if (node.content.id == id) return ancestor;
      if (node.children.isNotEmpty) {
        final found = _findParent(id, node.children, node);
        if (found != null) return found;
      }
    }
    return null;
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

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      // TreeSliver is a sliver -- Semantics is a SingleChildRenderObjectWidget
      // producing a RenderBox, which a Viewport rejects as a sliver child.
      // includeSemantics: false keeps Focus a pure InheritedWidget wrapper
      // here; each row already carries its own Semantics via LayrzTreeRow, so
      // nothing is lost by skipping Focus's own semantics node.
      includeSemantics: false,
      child: TreeSliver<LayrzTreeNode<T>>(
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
          final isActive = _activeId != null && layrzNode.id == _activeId;

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
            isActive: isActive,
            onToggle: isLeaf ? null : onToggle,
            onSelect: widget.selectable ? onSelect : null,
            child: content,
          );
        },
      ),
    );
  }
}
