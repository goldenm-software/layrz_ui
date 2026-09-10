import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'workspace_new_tab_button.dart';
import 'workspace_tab.dart';
import 'workspace_tab_item.dart';

/// The scrollable strip of [LayrzWorkspaceTabItem]s at the top of a
/// [LayrzWorkspaceTabs] workspace, plus the pinned new-tab (+) affordance.
///
/// This widget owns every strip-only concern: horizontal overflow scrolling,
/// keyboard traversal (arrow keys + Enter/Space), and hand-rolled
/// drag-to-reorder. It reports the active tab's current on-screen [Rect]
/// via [onActiveTabRectChanged] after every layout pass, so the parent
/// [LayrzWorkspaceTabs] can translate it into the content panel's local
/// coordinates and carve the panel border's connecting gap at the right
/// x-offset — this widget itself has no notion of the panel below it.
class LayrzWorkspaceTabStrip extends StatefulWidget {
  /// The tabs to render, in display order.
  final List<LayrzWorkspaceTab> tabs;

  /// The id of the currently active tab.
  final String activeId;

  /// Called with a tab's id when the user activates it, by tap or keyboard.
  final ValueChanged<String> onTabSelected;

  /// Called with a tab's id when the user presses its close (×) affordance.
  final ValueChanged<String>? onTabClosed;

  /// Called when the user presses the new-tab (+) affordance.
  final VoidCallback? onNewTab;

  /// Called with `(oldIndex, newIndex)` when the user drags a tab to a new
  /// position in the strip.
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Called with the active tab's current global [Rect] after every layout
  /// pass that can resolve it, or `null` when no tab is active or its box
  /// cannot yet be measured (e.g. mid-layout).
  final ValueChanged<Rect?> onActiveTabRectChanged;

  /// Creates a new [LayrzWorkspaceTabStrip].
  ///
  /// All parameters except [onTabClosed], [onNewTab], and [onReorder] are
  /// required.
  const LayrzWorkspaceTabStrip({
    super.key,
    required this.tabs,
    required this.activeId,
    required this.onTabSelected,
    this.onTabClosed,
    this.onNewTab,
    this.onReorder,
    required this.onActiveTabRectChanged,
  });

  @override
  State<LayrzWorkspaceTabStrip> createState() => _LayrzWorkspaceTabStripState();
}

class _LayrzWorkspaceTabStripState extends State<LayrzWorkspaceTabStrip> {
  /// Scroll controller for the horizontal tab strip.
  final ScrollController _scrollController = ScrollController();

  /// Keyboard focus node for the whole strip; arrow-key traversal moves
  /// [_focusedIndex] without moving Flutter's own focus tree per tab, since
  /// there is no per-tab focus requirement beyond visual/traversal state.
  final FocusNode _focusNode = FocusNode(debugLabel: 'LayrzWorkspaceTabStrip');

  /// A [GlobalKey] per currently-rendered tab, keyed by
  /// [LayrzWorkspaceTab.id], used to look up each tab's on-screen
  /// [RenderBox] while a drag is in progress, and to report the active
  /// tab's rect to [LayrzWorkspaceTabStrip.onActiveTabRectChanged]. Rebuilt
  /// at the top of every [build] so it always matches
  /// [LayrzWorkspaceTabStrip.tabs] by identity, not by index — stable
  /// across reorders.
  final Map<String, GlobalKey> _itemKeys = {};

  /// The index currently highlighted for keyboard traversal.
  ///
  /// Distinct from [LayrzWorkspaceTabStrip.activeId]: arrow keys move this
  /// highlight without activating a tab, matching standard roving-tabindex
  /// behaviour; Enter/Space then activates whatever this index points at.
  int _focusedIndex = 0;

  /// The index of the tab currently being dragged, or `null` when no drag is
  /// in progress.
  int? _draggedIndex;

  /// The last [Rect] reported via [LayrzWorkspaceTabStrip.onActiveTabRectChanged],
  /// used to avoid redundant reports on every frame.
  Rect? _lastReportedRect;

  @override
  void initState() {
    super.initState();
    _syncFocusedIndex();
    _scheduleActiveTabRectRefresh();
  }

  @override
  void didUpdateWidget(LayrzWorkspaceTabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFocusedIndex();
    _scheduleActiveTabRectRefresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Keeps [_focusedIndex] in range and, when possible, tracking the active
  /// tab after [LayrzWorkspaceTabStrip.tabs] or
  /// [LayrzWorkspaceTabStrip.activeId] changes.
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

  /// Schedules [_resolveActiveTabRect] to run after the next frame, once
  /// every tab item has a laid-out [RenderBox] to read from.
  void _scheduleActiveTabRectRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resolveActiveTabRect();
    });
  }

  /// Recomputes the active tab's global [Rect] from its current
  /// [RenderBox] and reports it via
  /// [LayrzWorkspaceTabStrip.onActiveTabRectChanged], skipping the report
  /// when it is unchanged from [_lastReportedRect].
  void _resolveActiveTabRect() {
    final activeIndex = widget.tabs.indexWhere((t) => t.id == widget.activeId);
    if (activeIndex < 0) {
      if (_lastReportedRect != null) {
        _lastReportedRect = null;
        widget.onActiveTabRectChanged(null);
      }
      return;
    }

    final box = _itemKeys[widget.tabs[activeIndex].id]?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect != _lastReportedRect) {
      _lastReportedRect = rect;
      widget.onActiveTabRectChanged(rect);
    }
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
    _scheduleActiveTabRectRefresh();
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

    // The active tab's rect may have shifted since the last frame (a new
    // tab opened, one closed, a reorder, or the strip itself resized) --
    // schedule a refresh on every build so the panel border gap that reads
    // it stays in sync without the caller having to ask.
    _scheduleActiveTabRectRefresh();

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
          // No bottom inset: the active tab's `mergeBottom` open border ends
          // at its own bottom edge (see `LayrzWorkspaceTabChromePainter`),
          // and that edge must land exactly on the content panel's top edge
          // below (see `LayrzWorkspaceTabs`'s `Column([strip,
          // Expanded(panel)])`) so the two open paths abut with no seam. A
          // bottom inset here would leave a gap band between the tab's
          // baseline and the panel, floating the tab above it.
          padding: EdgeInsets.only(
            top: tokens.spacing.sp1,
            left: tokens.spacing.sp2,
            right: tokens.spacing.sp2,
          ),
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
