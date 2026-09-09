import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'workspace_new_tab_button.dart';
import 'workspace_tab.dart';
import 'workspace_tab_item.dart';

/// A browser-style, controlled tab strip: the developer owns the tab list,
/// the active tab, and the content rendered below; this widget renders only
/// the chrome-style tab bar and reports selection, close, new-tab, and
/// reorder events.
///
/// **Controlled, bar-only model**: [LayrzWorkspaceTabs] never renders or owns
/// a body — it paints the strip and nothing else. The caller keeps [tabs]
/// and [activeId] in its own state, renders the active tab's content
/// separately (typically directly below this widget), and reacts to this
/// widget's callbacks by mutating that state.
///
/// This is a deliberately different component from `LayrzTabView`, which
/// owns a fixed, author-defined set of pill tabs and swaps its own child
/// content. `LayrzWorkspaceTabs` is a dynamic, user-driven workspace/document
/// manager: tabs open, close, and reorder at runtime, and the widget itself
/// never touches the content those tabs represent.
///
/// **v1 scope**: per-tab close (×), a pinned new-tab (+) affordance, and
/// hand-rolled drag-to-reorder. Overflow beyond the strip's width is handled
/// by horizontal scrolling rather than an overflow menu; there is no context
/// menu, no middle-click-to-close, and no tab groups/pinning beyond
/// [LayrzWorkspaceTab.closable].
///
/// **Visual**: the active tab's chrome merges into the content panel below
/// it (flat bottom edge, rounded top, `tokens.colors.sf1` fill matching the
/// panel surface); inactive tabs recede with a quieter fill and foreground.
/// See `LayrzWorkspaceTabChromePainter` for the connected-tab shape itself.
///
/// **Accessibility**: each tab is a `Semantics(button: true, selected: ...)`
/// node; the close (×) and new-tab (+) affordances are independently
/// labeled and focusable. The strip supports arrow-key traversal between
/// tabs and Enter/Space to activate the focused one.
class LayrzWorkspaceTabs extends StatefulWidget {
  /// The tabs to render, in display order.
  final List<LayrzWorkspaceTab> tabs;

  /// The id of the currently active tab.
  ///
  /// Must match one of [tabs]' [LayrzWorkspaceTab.id] values for a tab to
  /// render as active; if it matches none (e.g. transiently, while the
  /// caller is updating state after a close), no tab renders as active.
  final String activeId;

  /// Called with a tab's id when the user activates it, by tap or by
  /// keyboard (Enter/Space on the focused tab).
  final ValueChanged<String> onTabSelected;

  /// Called with a tab's id when the user presses its close (×) affordance.
  ///
  /// A `null` value hides every tab's close affordance, regardless of each
  /// tab's own [LayrzWorkspaceTab.closable] value — there is nothing to wire
  /// a close tap to. A closable tab still never emits this when the widget
  /// itself carries no handler.
  final ValueChanged<String>? onTabClosed;

  /// Called when the user presses the new-tab (+) affordance.
  ///
  /// A `null` value hides the affordance entirely.
  final VoidCallback? onNewTab;

  /// Called with `(oldIndex, newIndex)` when the user drags a tab to a new
  /// position in the strip.
  ///
  /// A `null` value disables drag-to-reorder — tabs remain tappable but no
  /// longer draggable. Indices are positions into [tabs] at the moment the
  /// move is reported, matching the convention that [oldIndex] is where the
  /// dragged tab currently is and [newIndex] is where it should move to.
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Creates a new [LayrzWorkspaceTabs].
  ///
  /// [tabs] and [activeId] are required. [onTabSelected] is required since a
  /// strip the caller can never react to serves no purpose. [onTabClosed],
  /// [onNewTab], and [onReorder] are optional; each `null` value disables
  /// (hides, for the close/new-tab affordances) the corresponding feature.
  const LayrzWorkspaceTabs({
    super.key,
    required this.tabs,
    required this.activeId,
    required this.onTabSelected,
    this.onTabClosed,
    this.onNewTab,
    this.onReorder,
  });

  @override
  State<LayrzWorkspaceTabs> createState() => _LayrzWorkspaceTabsState();
}

class _LayrzWorkspaceTabsState extends State<LayrzWorkspaceTabs> {
  /// Scroll controller for the horizontal tab strip.
  final ScrollController _scrollController = ScrollController();

  /// Keyboard focus node for the whole strip; arrow-key traversal moves
  /// [_focusedIndex] without moving Flutter's own focus tree per tab, since
  /// there is no per-tab focus requirement beyond visual/traversal state.
  final FocusNode _focusNode = FocusNode(debugLabel: 'LayrzWorkspaceTabs');

  /// A [GlobalKey] per currently-rendered tab, keyed by
  /// [LayrzWorkspaceTab.id], used to look up each tab's on-screen
  /// [RenderBox] while a drag is in progress. Rebuilt at the top of every
  /// [build] so it always matches [LayrzWorkspaceTabs.tabs] by identity, not
  /// by index — stable across reorders.
  final Map<String, GlobalKey> _itemKeys = {};

  /// The index currently highlighted for keyboard traversal.
  ///
  /// Distinct from [LayrzWorkspaceTabs.activeId]: arrow keys move this
  /// highlight without activating a tab, matching standard roving-tabindex
  /// behaviour; Enter/Space then activates whatever this index points at.
  int _focusedIndex = 0;

  /// The index of the tab currently being dragged, or `null` when no drag is
  /// in progress.
  int? _draggedIndex;

  @override
  void initState() {
    super.initState();
    _syncFocusedIndex();
  }

  @override
  void didUpdateWidget(LayrzWorkspaceTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFocusedIndex();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Keeps [_focusedIndex] in range and, when possible, tracking the active
  /// tab after [LayrzWorkspaceTabs.tabs] or [LayrzWorkspaceTabs.activeId]
  /// changes.
  void _syncFocusedIndex() {
    final activeIndex = widget.tabs.indexWhere((t) => t.id == widget.activeId);
    if (activeIndex >= 0) {
      _focusedIndex = activeIndex;
    } else if (_focusedIndex >= widget.tabs.length) {
      _focusedIndex = widget.tabs.isEmpty ? 0 : widget.tabs.length - 1;
    }
  }

  /// Returns the [GlobalKey] for [tab], creating one on first use and
  /// dropping keys for tabs no longer present so the map never grows
  /// unbounded across opens/closes.
  GlobalKey _keyFor(LayrzWorkspaceTab tab) {
    final liveIds = widget.tabs.map((t) => t.id).toSet();
    _itemKeys.removeWhere((id, _) => !liveIds.contains(id));
    return _itemKeys.putIfAbsent(tab.id, () => GlobalKey());
  }

  /// Handles a key event on the strip's [Focus] node: arrow-key traversal
  /// between tabs and Enter/Space activation of the focused tab.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (widget.tabs.isEmpty) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight) {
      setState(() => _focusedIndex = (_focusedIndex + 1).clamp(0, widget.tabs.length - 1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      setState(() => _focusedIndex = (_focusedIndex - 1).clamp(0, widget.tabs.length - 1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      widget.onTabSelected(widget.tabs[_focusedIndex].id);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Starts a drag for the tab at [index].
  void _handleDragStart(int index) {
    if (widget.onReorder == null) return;
    setState(() => _draggedIndex = index);
  }

  /// Updates the in-progress drag using the pointer's current global
  /// position and, when it now sits over a different tab than
  /// [_draggedIndex], reorders immediately — matching a live browser tab
  /// strip, where the dragged tab visibly swaps position as soon as it
  /// crosses a neighbour's centre.
  void _handleDragUpdate(Offset globalPosition) {
    final draggedIndex = _draggedIndex;
    if (draggedIndex == null) return;

    final targetIndex = _resolveTargetIndex(globalPosition);
    if (targetIndex == null || targetIndex == draggedIndex) return;

    widget.onReorder!(draggedIndex, targetIndex);
    setState(() => _draggedIndex = targetIndex);
  }

  /// Ends the current drag, clearing all drag-tracking state.
  void _handleDragEnd() {
    if (_draggedIndex == null) return;
    setState(() => _draggedIndex = null);
  }

  /// Resolves which tab index [globalPosition] currently sits over, by
  /// comparing it against each live tab's [RenderBox] bounds (in global
  /// coordinates) via [_itemKeys].
  ///
  /// Returns `null` when no tab's box can be resolved (e.g. mid-layout).
  int? _resolveTargetIndex(Offset globalPosition) {
    for (final (index, tab) in widget.tabs.indexed) {
      final box = _itemKeys[tab.id]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final topLeft = box.localToGlobal(Offset.zero);
      final rect = topLeft & box.size;
      if (globalPosition.dx >= rect.left && globalPosition.dx <= rect.right) {
        return index;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final strip = widget.tabs.isEmpty
        ? const SizedBox.shrink()
        : Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (index, tab) in widget.tabs.indexed) ...[
                    if (index > 0) SizedBox(width: tokens.spacing.sp1),
                    KeyedSubtree(
                      key: _keyFor(tab),
                      child: Listener(
                        onPointerDown: widget.onReorder == null ? null : (_) => _handleDragStart(index),
                        onPointerMove: widget.onReorder == null ? null : (event) => _handleDragUpdate(event.position),
                        onPointerUp: widget.onReorder == null ? null : (_) => _handleDragEnd(),
                        onPointerCancel: widget.onReorder == null ? null : (_) => _handleDragEnd(),
                        child: LayrzWorkspaceTabItem(
                          tab: tab,
                          isActive: tab.id == widget.activeId,
                          isFocused: index == _focusedIndex,
                          isDragging: index == _draggedIndex,
                          onSelected: () {
                            _focusNode.requestFocus();
                            setState(() => _focusedIndex = index);
                            widget.onTabSelected(tab.id);
                          },
                          onClosed: !tab.closable || widget.onTabClosed == null
                              ? null
                              : () => widget.onTabClosed!(tab.id),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: DecoratedBox(
        decoration: BoxDecoration(color: tokens.colors.sf2),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1),
          child: Row(
            children: [
              strip,
              if (widget.tabs.isEmpty) const Spacer(),
              if (widget.onNewTab != null) ...[
                SizedBox(width: tokens.spacing.sp1),
                LayrzWorkspaceNewTabButton(onTap: widget.onNewTab!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
