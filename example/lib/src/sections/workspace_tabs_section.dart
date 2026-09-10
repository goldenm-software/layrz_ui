import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// The content widget for the workspace tabs section.
///
/// Demonstrates [LayrzWorkspaceTabs] as a browser-like, controlled
/// workspace: the developer keeps the tab list and active id in local
/// state and reacts to open (+), close (×), select, and drag-reorder
/// events, while each [LayrzWorkspaceTab] now owns its own content through
/// `left`/`right` and the widget itself renders the connected content panel
/// — there is no separate body the caller renders and keys by id anymore.
///
/// [LayrzWorkspaceTabs] expects a bounded (typically full-screen) height —
/// its content panel expands to fill whatever height remains below the
/// strip — so each demo below gives it a fixed-height box standing in for a
/// full page body.
class WorkspaceTabsSection extends StatelessWidget {
  /// Creates a new [WorkspaceTabsSection].
  const WorkspaceTabsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Workspace Tabs',
      description:
          'A browser-style, controlled workspace — open, close, reorder, and select tabs; each '
          'tab owns its own content, and the widget renders the connected strip + panel as one piece.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkspaceDemo(tokens: tokens),
          SizedBox(height: tokens.spacing.sp5),
          _PinnedTabDemo(tokens: tokens),
        ],
      ),
    );
  }
}

/// The main interactive demo: open/close/reorder/select against a small set
/// of starter tabs, one of which (`report-1`) demonstrates a split-view tab
/// with both `left` and `right` content panes behind a resizable divider.
class _WorkspaceDemo extends StatefulWidget {
  /// Creates a new [_WorkspaceDemo].
  const _WorkspaceDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  State<_WorkspaceDemo> createState() => _WorkspaceDemoState();
}

class _WorkspaceDemoState extends State<_WorkspaceDemo> {
  /// The current tab list, mutated in response to open/close/reorder events.
  ///
  /// `report-1` carries a non-null `right`, so it renders in split view — a
  /// preview pane alongside a details pane, resizable via the divider
  /// between them.
  late List<LayrzWorkspaceTab> _tabs = [
    _panelTab(id: 'overview', label: 'Overview', icon: MdiIcons.viewDashboardOutline),
    LayrzWorkspaceTab(
      id: 'report-1',
      label: 'Q3 Report',
      icon: MdiIcons.fileChartOutline,
      left: const _DemoPane(title: 'Q3 Report', body: 'The primary document pane for this tab.'),
      right: const _DemoPane(title: 'Notes', body: 'A secondary pane, side-by-side via the resizable split.'),
    ),
    _panelTab(id: 'report-2', label: 'Budget Draft', icon: MdiIcons.fileChartOutline),
  ];

  /// The id of the tab currently rendered as active.
  String _activeId = 'overview';

  /// A monotonically increasing counter used to name newly opened tabs.
  int _nextTabNumber = 1;

  /// Builds a single-pane tab whose `left` is a [_DemoPane] describing
  /// itself, used for every tab in this demo except the split-view one.
  static LayrzWorkspaceTab _panelTab({required String id, required String label, IconData? icon}) {
    return LayrzWorkspaceTab(
      id: id,
      label: label,
      icon: icon,
      left: _DemoPane(
        title: label,
        body: 'This is tab "$id"\'s own content, owned by LayrzWorkspaceTab.left.',
      ),
    );
  }

  /// Adds a new tab, named sequentially, and makes it the active one.
  void _openTab() {
    setState(() {
      final id = 'new-${DateTime.now().microsecondsSinceEpoch}';
      _tabs = [..._tabs, _panelTab(id: id, label: 'Untitled $_nextTabNumber', icon: MdiIcons.fileOutline)];
      _activeId = id;
      _nextTabNumber++;
    });
  }

  /// Removes the tab with [id] and, if it was the active tab, falls back to
  /// a neighbouring tab. [LayrzWorkspaceTabs] itself makes no assumption
  /// about the next active tab -- that choice belongs entirely to the
  /// caller, demonstrated here.
  void _closeTab(String id) {
    setState(() {
      final closingIndex = _tabs.indexWhere((t) => t.id == id);
      _tabs = _tabs.where((t) => t.id != id).toList();
      if (_activeId == id && _tabs.isNotEmpty) {
        _activeId = _tabs[closingIndex.clamp(0, _tabs.length - 1)].id;
      }
    });
  }

  /// Applies a completed drag-reorder to the tab list.
  void _reorderTabs(int oldIndex, int newIndex) {
    setState(() {
      final next = [..._tabs];
      final moved = next.removeAt(oldIndex);
      next.insert(newIndex, moved);
      _tabs = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Browser-Like Workspace', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'Open a new tab with the (+) affordance, close one with its (×), drag a tab to reorder '
          'it, or click a tab to activate it. "Q3 Report" is a split-view tab -- drag the divider '
          'between its two panes to resize them.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        // LayrzWorkspaceTabs expands its content panel to fill available
        // height -- this SizedBox stands in for a full-screen page body.
        SizedBox(
          height: 360,
          child: LayrzWorkspaceTabs(
            tabs: _tabs,
            activeId: _activeId,
            onTabSelected: (id) => setState(() => _activeId = id),
            onTabClosed: _closeTab,
            onNewTab: _openTab,
            onReorder: _reorderTabs,
          ),
        ),
      ],
    );
  }
}

/// Demonstrates a non-closable, pinned "home" tab (`closable: false`)
/// alongside ordinary closable tabs — the pinned tab never renders a close
/// affordance and never emits [LayrzWorkspaceTabs.onTabClosed].
class _PinnedTabDemo extends StatefulWidget {
  /// Creates a new [_PinnedTabDemo].
  const _PinnedTabDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  State<_PinnedTabDemo> createState() => _PinnedTabDemoState();
}

class _PinnedTabDemoState extends State<_PinnedTabDemo> {
  /// The current tab list; the first entry is pinned (`closable: false`).
  List<LayrzWorkspaceTab> _tabs = const [
    LayrzWorkspaceTab(
      id: 'home',
      label: 'Home',
      icon: MdiIcons.homeOutline,
      closable: false,
      left: _DemoPane(title: 'Home', body: 'The pinned home tab -- it never shows a close affordance.'),
    ),
    LayrzWorkspaceTab(
      id: 'notes',
      label: 'Notes',
      left: _DemoPane(title: 'Notes', body: 'An ordinary closable tab alongside the pinned one.'),
    ),
  ];

  /// The id of the tab currently rendered as active.
  String _activeId = 'home';

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pinned Tab (closable: false)', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'The "Home" tab has closable: false — it never shows a close affordance, even '
          'though the strip as a whole has an onTabClosed handler wired.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        SizedBox(
          height: 240,
          child: LayrzWorkspaceTabs(
            tabs: _tabs,
            activeId: _activeId,
            onTabSelected: (id) => setState(() => _activeId = id),
            onTabClosed: (id) => setState(() => _tabs = _tabs.where((t) => t.id != id).toList()),
          ),
        ),
      ],
    );
  }
}

/// A minimal content pane used by every tab in this showcase, so each tab's
/// `left`/`right` content is visibly distinct without duplicating layout
/// code at every call site.
class _DemoPane extends StatelessWidget {
  /// Creates a new [_DemoPane].
  const _DemoPane({required this.title, required this.body});

  /// The pane's heading text.
  final String title;

  /// The pane's descriptive body text.
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: tokens.spacing.pd4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(body, style: tokens.typography.body.copyWith(color: tokens.colors.fg3)),
        ],
      ),
    );
  }
}
