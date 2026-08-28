import 'package:flutter/widgets.dart';

/// Programmatic control over a [LayrzTreeView] or [LayrzSliverTreeView]'s
/// expansion state and keyboard-driven active row.
///
/// This wraps the SDK's `TreeSliverController` rather than replacing it —
/// `TreeSliver` already owns animated expand/collapse and the active-node
/// list, so [LayrzTreeController] only adds what the SDK does not provide: a
/// stable way to query/drive expansion by the caller's own node id (the SDK
/// controller keys off its own `TreeSliverNode<T>` instances, which are
/// internal to `tree_sliver_view.dart`) and the currently keyboard-active
/// node for arrow-key navigation.
///
/// Following the pattern used for `LayrzRefreshIndicator`/`LayrzCalendar` in
/// this batch: pass `null` to let the widget create and dispose its own
/// controller; pass a non-null instance and the caller owns disposal, and the
/// instance may not be swapped for another one later (enforced by an assert
/// in the owning widget's `didUpdateWidget`).
///
/// [LayrzTreeController] itself holds no tree-shaped state — it only forwards
/// to whichever [LayrzTreeControllerBinding] `tree_sliver_view.dart` installs
/// via [bind] once the tree is built, and reports "no-op" values before that
/// (e.g. [isExpanded] returns `false`, [activeId] returns `null`). This keeps
/// the controller's own file free of any dependency on `TreeSliver`/
/// `TreeSliverNode`, matching the same separability requirement placed on
/// `tree_selection.dart`.
class LayrzTreeController extends ChangeNotifier {
  /// Creates a [LayrzTreeController].
  LayrzTreeController();

  LayrzTreeControllerBinding? _binding;

  /// Installs the live callbacks backing this controller. Called once by
  /// [LayrzSliverTreeView]'s state when it builds, and cleared via [unbind]
  /// on dispose. Not part of the API a consumer of this package calls.
  void bind(LayrzTreeControllerBinding binding) => _binding = binding;

  /// Detaches this controller from its bound tree. Called by
  /// [LayrzSliverTreeView]'s state on dispose.
  void unbind() => _binding = null;

  /// Whether the node with the given [id] is currently expanded.
  ///
  /// Returns `false` for an id that does not exist or is not yet bound to a
  /// live tree.
  bool isExpanded(Object id) => _binding?.isExpanded(id) ?? false;

  /// Expands the node with the given [id], if it has children and is not
  /// already expanded.
  void expand(Object id) => _binding?.expand(id);

  /// Collapses the node with the given [id], if it is currently expanded.
  void collapse(Object id) => _binding?.collapse(id);

  /// Toggles the expanded state of the node with the given [id].
  void toggle(Object id) => _binding?.toggle(id);

  /// Expands every node in the tree.
  void expandAll() => _binding?.expandAll();

  /// Collapses every node in the tree, back to only root nodes visible.
  void collapseAll() => _binding?.collapseAll();

  /// The id of the node currently focused for keyboard navigation, or `null`
  /// if no row has been focused yet.
  Object? get activeId => _binding?.activeId;

  /// Moves keyboard focus to the given [id], if it is currently visible
  /// (i.e. every ancestor is expanded).
  void setActive(Object id) => _binding?.setActive(id);
}

/// The set of live callbacks a [LayrzTreeController] forwards to.
///
/// Implemented and supplied by [LayrzSliverTreeView]'s state, which is the
/// only place with access to both the SDK's `TreeSliverController` and the
/// caller-id-to-`TreeSliverNode` lookups needed to satisfy these methods.
/// Kept as a plain callback bundle (rather than exposing the state object
/// itself) so [LayrzTreeController]'s own file carries no dependency on
/// `TreeSliver`/`TreeSliverNode`.
class LayrzTreeControllerBinding {
  /// Creates a [LayrzTreeControllerBinding] from the given callbacks.
  const LayrzTreeControllerBinding({
    required this.isExpanded,
    required this.expand,
    required this.collapse,
    required this.toggle,
    required this.expandAll,
    required this.collapseAll,
    required this.getActiveId,
    required this.setActive,
  });

  /// Backing implementation for [LayrzTreeController.isExpanded].
  final bool Function(Object id) isExpanded;

  /// Backing implementation for [LayrzTreeController.expand].
  final void Function(Object id) expand;

  /// Backing implementation for [LayrzTreeController.collapse].
  final void Function(Object id) collapse;

  /// Backing implementation for [LayrzTreeController.toggle].
  final void Function(Object id) toggle;

  /// Backing implementation for [LayrzTreeController.expandAll].
  final VoidCallback expandAll;

  /// Backing implementation for [LayrzTreeController.collapseAll].
  final VoidCallback collapseAll;

  /// Backing implementation for [LayrzTreeController.activeId]'s getter.
  final Object? Function() getActiveId;

  /// Backing implementation for [LayrzTreeController.setActive].
  final void Function(Object id) setActive;

  /// The id of the node currently focused for keyboard navigation, or `null`.
  Object? get activeId => getActiveId();
}
