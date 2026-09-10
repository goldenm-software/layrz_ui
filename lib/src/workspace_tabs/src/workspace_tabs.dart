import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'workspace_panel.dart';
import 'workspace_silhouette_painter.dart';
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
/// it a bordered panel (`LayrzWorkspacePanel`). The caller still owns [tabs]
/// and [activeId], but content now lives on each [LayrzWorkspaceTab] itself
/// rather than being rendered externally and keyed by id.
///
/// **Browser frame**: the whole widget sits inside one rounded `sf2` outer
/// frame with a small inset (`tokens.spacing.sp1`) — the "browser window
/// chrome" holding both the tab strip and the content card. Inactive tabs
/// are the same recessed `sf2`/`sf3` surface as the frame itself, so they
/// read as part of that chrome; the active tab and the content card below
/// it are the one `sf1` surface that pops forward out of the frame. The
/// `sf1` card fills the frame's entire remaining inner area (out to the
/// frame's own inner edge), with the tab strip's band sitting above it —
/// see [LayrzWorkspaceSilhouettePainter] for how the card and the active
/// tab's bump are one single painted shape.
///
/// **Single silhouette**: the active tab and the panel below it read as one
/// connected surface — a single continuous outline traces the whole
/// silhouette of [active tab bump + card], like a browser tab, and a single
/// fill colour spans both regions with no seam between them. This widget is
/// the one that owns that silhouette: it is the only place with both the
/// strip's and the panel's geometry (via the active tab's rect, reported by
/// [LayrzWorkspaceTabStrip.onActiveTabRectChanged], translated into this
/// widget's own inner [Stack] coordinate space), so it layers a single
/// [LayrzWorkspaceSilhouettePainter] as the *bottom* layer of that [Stack],
/// beneath the strip and the panel — both of which paint only their own
/// content on top of it (the strip paints no background of its own at all,
/// and the panel paints no border or fill of its own either) — see
/// [LayrzWorkspaceSilhouettePainter] for why a single painter replaces what
/// used to be two independently-stroked, geometrically-matching paths.
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
  /// Anchors the inner [Stack]'s own [RenderBox] — the one that layers the
  /// silhouette overlay beneath the strip and the panel — used as the
  /// coordinate-space origin the active tab's reported rect (from
  /// [LayrzWorkspaceTabStrip.onActiveTabRectChanged]) is translated into.
  final GlobalKey _stackKey = GlobalKey();

  /// The active tab's horizontal span, in the inner [Stack]'s own local
  /// coordinates. `null` until the strip's first rect report resolves it,
  /// or whenever no tab is active.
  double? _activeTabLeft;

  /// See [_activeTabLeft].
  double? _activeTabRight;

  /// The active tab's top edge, in the inner [Stack]'s own local
  /// y-coordinates — the vertical inset from the strip's own top (the
  /// stack's origin) down to the active tab item's own top edge.
  double? _activeTabTop;

  /// The active tab's own rendered height, i.e. [LayrzWorkspaceSilhouettePainter.tabHeight]:
  /// the distance from the tab's own top edge down to its baseline, where
  /// it opens into the content card.
  double? _activeTabHeight;

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
  /// [LayrzWorkspaceTabStrip]) into the inner [Stack]'s own local
  /// coordinates and stores it, or clears all three bounds when [rect] is
  /// `null`.
  void _handleActiveTabRectChanged(Rect? rect) {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (rect == null || stackBox == null || !stackBox.hasSize) {
      if (_activeTabLeft != null || _activeTabRight != null || _activeTabTop != null || _activeTabHeight != null) {
        setState(() {
          _activeTabLeft = null;
          _activeTabRight = null;
          _activeTabTop = null;
          _activeTabHeight = null;
        });
      }
      return;
    }

    final stackOrigin = stackBox.localToGlobal(Offset.zero);
    final left = rect.left - stackOrigin.dx;
    final right = rect.right - stackOrigin.dx;
    final top = rect.top - stackOrigin.dy;
    final height = rect.height;

    if (left != _activeTabLeft || right != _activeTabRight || top != _activeTabTop || height != _activeTabHeight) {
      setState(() {
        _activeTabLeft = left;
        _activeTabRight = right;
        _activeTabTop = top;
        _activeTabHeight = height;
      });
    }
  }

  /// Builds a [LayrzWorkspaceSilhouettePainter] for the current active-tab
  /// geometry. The same painter configuration is used for both the fill layer
  /// (beneath the strip) and the [strokeOnly] outline layer (above it), so the
  /// two draws trace the identical path.
  LayrzWorkspaceSilhouettePainter _silhouettePainter(
    LayrzTokens tokens,
    double tabTop,
    double tabHeight,
    double? left,
    double? right, {
    bool strokeOnly = false,
  }) {
    return LayrzWorkspaceSilhouettePainter(
      fillColor: tokens.colors.sf1,
      tabTop: tabTop,
      tabHeight: tabHeight,
      tabLeft: left,
      tabRight: right,
      tabTopRadius: tokens.radius.r2,
      // No outward-flaring shoulder: the tab's sides run straight down to the
      // baseline and meet the card's top edge directly (a flared shoulder
      // produced an awkward "ear" at the junction).
      shoulderRadius: 0.0,
      panelRadius: tokens.radius.innerRadiusValue(outerRadius: tokens.radius.r3, spacer: tokens.spacing.sp1),
      // A single clear line traces the whole [active tab + card] silhouette,
      // marking the active content in the primary colour at a visible weight.
      borderColor: tokens.colors.primary.shade500,
      borderWidth: 1.5,
      strokeOnly: strokeOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final activeIndex = widget.tabs.indexWhere((t) => t.id == widget.activeId);
    final activeTab = activeIndex >= 0 ? widget.tabs[activeIndex] : null;

    final top = _activeTabTop;
    final left = _activeTabLeft;
    final right = _activeTabRight;
    // The silhouette only has real geometry to paint once the strip has
    // reported the active tab's rect at least once; until then (the very
    // first frame) `tabHeight` is `0` and the silhouette degrades to a
    // plain rounded rectangle (see
    // `LayrzWorkspaceSilhouettePainter._buildSilhouettePath`'s `null`-span
    // fallback). `IgnorePointer` keeps it from ever intercepting gestures
    // meant for the strip or panel painted on top of it.
    // The active tab's top, measured from the stack's own origin. The
    // silhouette canvas starts at the stack top (`top: 0`) rather than at the
    // tab's top, so there is always room (the frame's `sp1` inset) above the
    // tab for its top border stroke to paint without being clipped at the
    // canvas edge. The painter draws the tab bump starting at this `tabTop`.
    final tabTop = top ?? 0.0;
    // The tab band's bottom, measured from the stack's origin -- where the tab
    // opens into the content card.
    final tabHeight = (top ?? 0.0) + (_activeTabHeight ?? 0.0);

    // The whole widget sits inside one rounded `sf2` "browser frame" with a
    // `sp1` inset -- see the class doc's "Browser frame" section. Inside
    // that inset, a single `Stack` layers the silhouette (bottom) beneath
    // the strip and panel `Column` (top): the silhouette's local `y = 0` is
    // the active tab's own top edge, so it is positioned at `top` (the
    // tab's measured inset from the stack's own origin, i.e. the strip's
    // top) and fills the rest of the inset area down to the stack's bottom
    // -- the `sf1` card filling all the way to the frame's own inner edge.
    return DecoratedBox(
      decoration: BoxDecoration(color: tokens.colors.sf2, borderRadius: tokens.radius.br3),
      child: Padding(
        padding: tokens.spacing.pd1,
        child: Stack(
          key: _stackKey,
          clipBehavior: Clip.none,
          children: [
            // Bottom layer: the silhouette's `sf1` FILL (and border) sits
            // beneath the strip and panel, so the tab labels and card content
            // draw on top of the shared fill.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _silhouettePainter(tokens, tabTop, tabHeight, left, right)),
              ),
            ),
            Column(
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
                    tab: activeTab,
                    splitRatio: _splitRatio,
                    onSplitRatioChanged: (ratio) => setState(() => _splitRatio = ratio),
                  ),
                ),
              ],
            ),
            // Top layer: the SAME silhouette outline painted stroke-only, on
            // top of the strip, so the active tab's border is never covered by
            // an adjacent inactive tab's opaque fill (which would crop it).
            // Both layers build the identical path, so the strokes coincide.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _silhouettePainter(tokens, tabTop, tabHeight, left, right, strokeOnly: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
