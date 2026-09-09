import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// The content widget for the workspace tabs section.
///
/// Demonstrates [LayrzWorkspaceTabs] as a browser-like, controlled tab strip:
/// the developer keeps the tab list and active id in local state and reacts
/// to open (+), close (×), select, and drag-reorder events. The widget below
/// only ever renders the strip — the content panel is entirely owned by this
/// demo, exactly as a real caller would wire it.
class WorkspaceTabsSection extends StatelessWidget {
  /// Creates a new [WorkspaceTabsSection].
  const WorkspaceTabsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Workspace Tabs',
      description:
          'A browser-style, controlled tab strip — open, close, reorder, and select tabs; '
          'the developer owns the tab list and the content behind it.',
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
/// of starter tabs, each rendering its own distinct panel below the strip.
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
  List<LayrzWorkspaceTab> _tabs = const [
    LayrzWorkspaceTab(id: 'overview', label: 'Overview', icon: MdiIcons.viewDashboardOutline),
    LayrzWorkspaceTab(id: 'report-1', label: 'Q3 Report', icon: MdiIcons.fileChartOutline),
    LayrzWorkspaceTab(id: 'report-2', label: 'Budget Draft', icon: MdiIcons.fileChartOutline),
  ];

  /// The id of the tab currently rendered as active.
  String _activeId = 'overview';

  /// A monotonically increasing counter used to name newly opened tabs.
  int _nextTabNumber = 1;

  /// Adds a new tab, named sequentially, and makes it the active one.
  void _openTab() {
    setState(() {
      final id = 'new-${DateTime.now().microsecondsSinceEpoch}';
      _tabs = [
        ..._tabs,
        LayrzWorkspaceTab(id: id, label: 'Untitled $_nextTabNumber', icon: MdiIcons.fileOutline),
      ];
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
          'Open a new tab with the (+) affordance, close one with its (×), drag a tab to '
          'reorder it, or click a tab to activate it. The panel below always renders '
          'whatever the developer wires for the active tab id.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        Container(
          decoration: BoxDecoration(
            color: tokens.colors.sf1,
            borderRadius: tokens.radius.br2,
            border: Border.all(color: tokens.colors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayrzWorkspaceTabs(
                tabs: _tabs,
                activeId: _activeId,
                onTabSelected: (id) => setState(() => _activeId = id),
                onTabClosed: _closeTab,
                onNewTab: _openTab,
                onReorder: _reorderTabs,
              ),
              Padding(
                padding: tokens.spacing.pd4,
                child: _tabs.isEmpty
                    ? Text(
                        'All tabs closed — use (+) to open a new one.',
                        style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
                      )
                    : _ActivePanel(
                        tab: _tabs.firstWhere(
                          (t) => t.id == _activeId,
                          orElse: () => _tabs.first,
                        ),
                        tokens: tokens,
                      ),
              ),
            ],
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
    LayrzWorkspaceTab(id: 'home', label: 'Home', icon: MdiIcons.homeOutline, closable: false),
    LayrzWorkspaceTab(id: 'notes', label: 'Notes'),
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
        Container(
          decoration: BoxDecoration(
            color: tokens.colors.sf1,
            borderRadius: tokens.radius.br2,
            border: Border.all(color: tokens.colors.divider),
          ),
          clipBehavior: Clip.antiAlias,
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

/// The demo content panel rendered for whichever tab is currently active.
class _ActivePanel extends StatelessWidget {
  /// Creates a new [_ActivePanel].
  const _ActivePanel({required this.tab, required this.tokens});

  /// The currently active tab, used to key this panel's content.
  final LayrzWorkspaceTab tab;

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(tab.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (tab.icon != null) ...[
              Icon(tab.icon, size: 20.0, color: tokens.colors.fg2),
              SizedBox(width: tokens.spacing.sp2),
            ],
            Text(tab.label, style: tokens.typography.title),
          ],
        ),
        SizedBox(height: tokens.spacing.sp2),
        Text(
          'This is the developer-owned content for tab "${tab.id}". LayrzWorkspaceTabs never '
          'renders this itself -- it only tells the caller which tab is active.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
      ],
    );
  }
}
