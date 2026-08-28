import 'package:flutter/foundation.dart';

import 'tree_node.dart';

/// How selecting a node in a [LayrzTreeView] or [LayrzSliverTreeView] affects
/// its descendants.
///
/// The SDK's `TreeSliver`/`TreeSliverNode` model has no concept of selection
/// at all — it only tracks expansion. Everything selection-related in this
/// module, including this enum and [LayrzTreeSelectionController], is custom
/// logic layered on top of that model, deliberately kept in this file so it
/// stays swappable without touching the `TreeSliver` integration
/// (`tree_sliver_view.dart`).
///
/// **Default: [independent].** This was an explicit open question the batch
/// plan flagged as its highest-risk unresolved decision (two reviewers
/// disagreed: one favoured independent selection as the simpler, more
/// composable design-system primitive with prior art in `LayrzChip`'s
/// none/single/multi convention and VS Code's non-cascading explorer; the
/// other argued cascading matches a user's intuition that selecting a folder
/// selects its contents). Both modes are shipped side by side rather than
/// picking a winner. [independent] is the default because it is the more
/// conservative, less surprising choice for a design-system *primitive*:
/// cascading is easy for a consumer to opt into explicitly, but a consumer
/// who did not expect cascading and gets it anyway has silently selected more
/// than they intended, which is the more dangerous failure direction for a
/// shared building block to default to.
enum LayrzTreeSelectionMode {
  /// Selecting a node affects only that node. Its parent and children are
  /// left exactly as they were.
  ///
  /// Matches `LayrzChip`'s existing selection conventions (no forced
  /// hierarchy) and how most desktop file-tree explorers behave by default.
  independent,

  /// Selecting a parent node selects (or deselects) every descendant along
  /// with it, and a parent whose descendants are only partly selected is
  /// reported as partially selected via
  /// [LayrzTreeSelectionController.isPartiallySelected] — a third,
  /// indeterminate visual state distinct from fully checked or fully
  /// unchecked.
  cascading,
}

/// Owns the set of selected node ids for a [LayrzTreeView] or
/// [LayrzSliverTreeView] and implements both [LayrzTreeSelectionMode]s.
///
/// This class is entirely independent of `TreeSliver`/`TreeSliverController`
/// — it only needs the caller's [LayrzTreeNode] shape (for
/// [LayrzTreeSelectionMode.cascading] to walk descendants and ancestors) and
/// a set of currently-selected ids. `tree_sliver_view.dart` wires this
/// controller's [toggle] to each row's `onSelect` and reads [isSelected] /
/// [isPartiallySelected] to build each row — nothing here reaches into the
/// SDK's tree state, and nothing in the SDK integration reimplements
/// selection. Reversing the batch's ratified default, or changing either
/// mode's behaviour, is a change to this file alone.
class LayrzTreeSelectionController<T> extends ChangeNotifier {
  /// Creates a [LayrzTreeSelectionController].
  LayrzTreeSelectionController({
    required this._roots,
    this._mode = LayrzTreeSelectionMode.independent,
    Set<Object>? initialSelectedIds,
  }) : _selectedIds = {...?initialSelectedIds};

  LayrzTreeSelectionMode _mode;

  /// The active selection mode. Changing this does not retroactively alter
  /// the current selection; it only changes how future [toggle] calls behave.
  LayrzTreeSelectionMode get mode => _mode;
  set mode(LayrzTreeSelectionMode value) {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
  }

  List<LayrzTreeNode<T>> _roots;

  /// Replaces the tree shape this controller walks for
  /// [LayrzTreeSelectionMode.cascading] parent/descendant resolution.
  ///
  /// Called by the owning tree widget whenever its `nodes` input changes, so
  /// this controller's cascade and partial-selection logic always walks the
  /// current shape rather than a stale one.
  void updateRoots(List<LayrzTreeNode<T>> roots) {
    _roots = roots;
  }

  final Set<Object> _selectedIds;

  /// The ids of every currently fully-selected node.
  ///
  /// Under [LayrzTreeSelectionMode.cascading], a parent whose descendants are
  /// only partly selected is intentionally excluded from this set — it
  /// belongs to [partiallySelectedIds] instead. This keeps "fully selected"
  /// and "partially selected" mutually exclusive and unambiguous to callers.
  Set<Object> get selectedIds => Set.unmodifiable(_selectedIds);

  /// Whether the node with the given [id] is fully selected.
  bool isSelected(Object id) => _selectedIds.contains(id);

  /// Whether the node with the given [id] is partially selected — only
  /// meaningful under [LayrzTreeSelectionMode.cascading], where a parent with
  /// some but not all descendants selected renders a third, indeterminate
  /// state. Always `false` under [LayrzTreeSelectionMode.independent], since
  /// that mode has no concept of a derived parent state.
  bool isPartiallySelected(Object id) {
    if (_mode == LayrzTreeSelectionMode.independent) return false;
    if (_selectedIds.contains(id)) return false;
    final node = _findNode(id, _roots);
    if (node == null || node.children.isEmpty) return false;
    return _anyDescendantSelected(node);
  }

  /// Whether any leaf-or-partial descendant of [node] is selected — used to
  /// tell "no descendant touched at all" apart from "some descendant is
  /// selected but not enough for [node] itself to be fully selected."
  bool _anyDescendantSelected(LayrzTreeNode<T> node) {
    for (final child in node.children) {
      if (_selectedIds.contains(child.id)) return true;
      if (child.children.isNotEmpty && _anyDescendantSelected(child)) return true;
    }
    return false;
  }

  /// Toggles the selection state of the node with the given [id].
  ///
  /// Under [LayrzTreeSelectionMode.independent], only [id] itself changes.
  /// Under [LayrzTreeSelectionMode.cascading], toggling a parent applies the
  /// same new state to every descendant, and every ancestor's fully-selected
  /// state is recomputed afterward (an ancestor becomes fully selected only
  /// when all of its children are, and is otherwise left out of
  /// [selectedIds], surfacing through [isPartiallySelected] instead when
  /// appropriate).
  void toggle(Object id) {
    final node = _findNode(id, _roots);
    if (node == null) return;

    final becomingSelected = !_selectedIds.contains(id);

    switch (_mode) {
      case LayrzTreeSelectionMode.independent:
        if (becomingSelected) {
          _selectedIds.add(id);
        } else {
          _selectedIds.remove(id);
        }
      case LayrzTreeSelectionMode.cascading:
        _setDescendantsSelected(node, becomingSelected);
        final chain = <LayrzTreeNode<T>>[];
        _collectAncestorChain(id, _roots, [], chain);
        // Recompute from the deepest ancestor upward so each parent's derived
        // state reflects its children's just-updated state, not a stale one.
        for (final ancestor in chain.reversed) {
          _recomputeNode(ancestor);
        }
    }

    notifyListeners();
  }

  /// Clears every selected id.
  void clear() {
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    notifyListeners();
  }

  void _setDescendantsSelected(LayrzTreeNode<T> node, bool selected) {
    if (selected) {
      _selectedIds.add(node.id);
    } else {
      _selectedIds.remove(node.id);
    }
    for (final child in node.children) {
      _setDescendantsSelected(child, selected);
    }
  }

  /// Fills [outChain] with every ancestor of the node identified by [id],
  /// ordered from the root down to (but excluding) the node itself.
  bool _collectAncestorChain(
    Object id,
    List<LayrzTreeNode<T>> nodes,
    List<LayrzTreeNode<T>> path,
    List<LayrzTreeNode<T>> outChain,
  ) {
    for (final node in nodes) {
      if (node.id == id) {
        outChain.addAll(path);
        return true;
      }
      if (node.children.isNotEmpty) {
        final found = _collectAncestorChain(id, node.children, [...path, node], outChain);
        if (found) return true;
      }
    }
    return false;
  }

  /// Recomputes whether [node] is fully selected, from its direct children's
  /// current membership in [_selectedIds].
  ///
  /// Only direct children are consulted, not the whole subtree: by the time
  /// an ancestor is recomputed (callers walk deepest-first — see [toggle]),
  /// any child that is itself a parent has already had its own
  /// [_selectedIds] membership updated by this same method, so checking one
  /// level down is sufficient and avoids conflating "fully selected child"
  /// with "some descendant, anywhere below, happens to be selected."
  void _recomputeNode(LayrzTreeNode<T> node) {
    final allChildrenSelected = node.children.isNotEmpty && node.children.every((c) => _selectedIds.contains(c.id));
    if (allChildrenSelected) {
      _selectedIds.add(node.id);
    } else {
      _selectedIds.remove(node.id);
    }
  }

  LayrzTreeNode<T>? _findNode(Object id, List<LayrzTreeNode<T>> nodes) {
    for (final node in nodes) {
      if (node.id == id) return node;
      if (node.children.isNotEmpty) {
        final found = _findNode(id, node.children);
        if (found != null) return found;
      }
    }
    return null;
  }
}
