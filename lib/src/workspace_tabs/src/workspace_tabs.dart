import 'package:flutter/widgets.dart';

import 'workspace_panel.dart';
import 'workspace_tab.dart';
import 'workspace_tab_strip.dart';

/// A browser-style, controlled workspace: the developer owns the tab list
/// and the active tab id; this widget renders the chrome-style tab strip
/// *and* the connected content panel for the active tab, reading that
/// panel's content straight from [LayrzWorkspaceTab.left]/
/// [LayrzWorkspaceTab.right], and reports selection, close, new-tab, and
/// reorder events.
///
/// **Tab-owns-content model**: this supersedes the original bar-only
/// design. [LayrzWorkspaceTabs] now renders both pieces as one connected
/// whole — the strip on top (`LayrzWorkspaceTabStrip`), and directly below
/// it a bordered panel (`LayrzWorkspacePanel`) whose top edge opens under
/// the active tab and curves into that tab's own outward shoulders, so the
/// two shapes trace a single continuous outline with no seam between them.
/// The caller still owns [tabs] and [activeId], but content now lives on
/// each [LayrzWorkspaceTab] itself rather than being rendered externally and
/// keyed by id.
///
/// This is a deliberately different component from `LayrzTabView`, which
/// owns a fixed, author-defined set of pill tabs and swaps its own child
/// content. `LayrzWorkspaceTabs` is a dynamic, user-driven workspace/document
/// manager: tabs open, close, and reorder at runtime.
///
/// **v1 scope**: per-tab close (×), a pinned new-tab (+) affordance,
/// hand-rolled drag-to-reorder, and a resizable two-pane split per tab.
/// Overflow beyond the strip's width is handled by horizontal scrolling
/// rather than an overflow menu; there is no context menu, no
/// middle-click-to-close, and no tab groups/pinning beyond
/// [LayrzWorkspaceTab.closable].
///
/// **Full-screen / expanding layout**: this widget builds a `Column` of
/// `[strip, Expanded(panel)]` — the strip takes its intrinsic height and the
/// panel expands to fill whatever height remains. It is designed to be
/// placed inside a bounded-height ancestor (typically a full page body,
/// itself inside a `Column`'s own `Expanded` or a `Scaffold`-equivalent
/// body), the same way a browser's own tab/content region fills its window.
/// Placing it inside an unbounded-height ancestor (e.g. a plain
/// `SingleChildScrollView` with no height constraint) is the caller's
/// responsibility to avoid, exactly as for any other `Expanded`-based
/// widget — [LayrzWorkspaceTabs] itself does not clamp or measure a
/// fallback height.
///
/// **Split view**: when the active tab's [LayrzWorkspaceTab.right] is
/// non-null, the panel shows [LayrzWorkspaceTab.left] and
/// [LayrzWorkspaceTab.right] side-by-side behind a draggable vertical
/// divider (`LayrzWorkspaceSplitView`) the user can drag to resize the
/// split, clamped so neither pane shrinks below
/// `kLayrzWorkspaceSplitMinPaneExtent`. **The split ratio is a single value
/// per currently-active panel** (not persisted per tab id) — switching
/// tabs and switching back resets to the default 50/50 ratio. This is a
/// deliberate v1 scope choice; per-tab ratio memory is a nice-to-have left
/// for a future revision.
///
/// **Accessibility**: each tab is a `Semantics(button: true, selected: ...)`
/// node; the close (×) and new-tab (+) affordances are independently
/// labeled and focusable, and the split divider exposes an adjustable
/// (`slider: true`) semantics node. The strip supports arrow-key traversal
/// between tabs and Enter/Space to activate the focused one.
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
  /// Anchors the content panel's [RenderBox], used as the coordinate-space
  /// origin the active tab's reported rect (from
  /// [LayrzWorkspaceTabStrip.onActiveTabRectChanged]) is translated into, so
  /// [LayrzWorkspacePanel] can carve its top-border gap at the right
  /// x-offset.
  final GlobalKey _panelKey = GlobalKey();

  /// The active tab's horizontal span, in the panel's own local
  /// coordinates. `null` until the strip's first rect report resolves it,
  /// or whenever no tab is active.
  double? _activeTabLeft;

  /// See [_activeTabLeft].
  double? _activeTabRight;

  /// The current split ratio for whichever tab is active, as the fraction
  /// of width given to [LayrzWorkspaceTab.left]. Reset to the default 50/50
  /// whenever the active tab id changes — see the class doc's "Split view"
  /// section for why this is a single value rather than persisted per tab.
  double _splitRatio = 0.5;

  @override
  void didUpdateWidget(LayrzWorkspaceTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeId != widget.activeId) {
      _splitRatio = 0.5;
    }
  }

  /// Translates the active tab's global [rect] (reported by
  /// [LayrzWorkspaceTabStrip]) into the content panel's own local
  /// x-coordinates and stores it, or clears both bounds when [rect] is
  /// `null`.
  void _handleActiveTabRectChanged(Rect? rect) {
    final panelBox = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    if (rect == null || panelBox == null || !panelBox.hasSize) {
      if (_activeTabLeft != null || _activeTabRight != null) {
        setState(() {
          _activeTabLeft = null;
          _activeTabRight = null;
        });
      }
      return;
    }

    final panelOriginX = panelBox.localToGlobal(Offset.zero).dx;
    final left = rect.left - panelOriginX;
    final right = rect.right - panelOriginX;

    if (left != _activeTabLeft || right != _activeTabRight) {
      setState(() {
        _activeTabLeft = left;
        _activeTabRight = right;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = widget.tabs.indexWhere((t) => t.id == widget.activeId);
    final activeTab = activeIndex >= 0 ? widget.tabs[activeIndex] : null;

    // The strip takes its intrinsic height; the panel expands to fill
    // whatever height remains, so this widget is meant to sit inside a
    // bounded-height (typically full-screen) ancestor -- see the class doc's
    // "Full-screen / expanding layout" section.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayrzWorkspaceTabStrip(
          tabs: widget.tabs,
          activeId: widget.activeId,
          onTabSelected: widget.onTabSelected,
          onTabClosed: widget.onTabClosed,
          onNewTab: widget.onNewTab,
          onReorder: widget.onReorder,
          onActiveTabRectChanged: _handleActiveTabRectChanged,
        ),
        Expanded(
          child: LayrzWorkspacePanel(
            key: _panelKey,
            tab: activeTab,
            activeTabLeft: _activeTabLeft,
            activeTabRight: _activeTabRight,
            splitRatio: _splitRatio,
            onSplitRatioChanged: (ratio) => setState(() => _splitRatio = ratio),
          ),
        ),
      ],
    );
  }
}
