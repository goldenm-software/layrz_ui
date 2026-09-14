import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// A tiny, self-contained item shown by [ScaffoldShellSection]'s demo shell.
///
/// Unlike the richer `InputDemo` registry entries used by the Inputs and
/// Pickers showcases, this class exists only to demonstrate [LayrzScaffoldShell]
/// in isolation — it carries just enough data to render a list tile and a
/// simple detail pane.
@immutable
final class _DemoShellItem {
  /// A stable, unique identifier for this item.
  final String id;

  /// The human-readable title shown in the list tile and the detail heading.
  final String title;

  /// A short description shown in the detail pane body.
  final String description;

  /// An icon representing this item in the list tile.
  final IconData icon;

  /// Creates a new [_DemoShellItem].
  const _DemoShellItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Showcases [LayrzScaffoldShell] as a component in its own right.
///
/// Demonstrates the adaptive list-detail behavior — a searchable item list on
/// one side and a detail pane on the other on wide layouts, collapsing to a
/// list-plus-modal-sheet on narrow ones — using a small set of fake rows
/// defined locally in [_DemoShellItem], rather than any real design-system
/// component registry.
///
/// [LayrzScaffoldShell] fills the height its parent gives it, so this demo
/// wraps it in a fixed-height [SizedBox] to keep it bounded inside
/// [ShowroomSection]'s scrolling content area.
class ScaffoldShellSection extends StatefulWidget {
  /// Creates a new [ScaffoldShellSection].
  const ScaffoldShellSection({super.key});

  @override
  State<ScaffoldShellSection> createState() => _ScaffoldShellSectionState();
}

class _ScaffoldShellSectionState extends State<ScaffoldShellSection> {
  late LayrzScaffoldController _controller;

  /// Drives the desktop table's sort/search/column/selection state, exposed so
  /// the app could observe or drive it from outside the shell.
  late LayrzTableController<_DemoShellItem> _tableController;

  /// Drives the demo shell's footer refresh control, so the "last refreshed"
  /// caption below can be updated in lockstep with the same control a user
  /// would actually press.
  late LayrzRefreshController _refreshController;

  /// The fake rows rendered by the demo shell.
  ///
  /// Mutable (unlike the fixed catalog it started from) because [_onRefresh]
  /// prepends a new row on every refresh, so the demo visibly changes
  /// something a user can see rather than just spinning and stopping.
  final List<_DemoShellItem> _items = [
    const _DemoShellItem(
      id: 'overview',
      title: 'Overview',
      description: 'A summary dashboard showing the current state of the workspace at a glance.',
      icon: MdiIcons.viewDashboardOutline,
    ),
    const _DemoShellItem(
      id: 'settings',
      title: 'Settings',
      description: 'General configuration for the workspace, including preferences and defaults.',
      icon: MdiIcons.cogOutline,
    ),
    const _DemoShellItem(
      id: 'members',
      title: 'Members',
      description: 'The people who have access to this workspace and their assigned roles.',
      icon: MdiIcons.accountGroupOutline,
    ),
    const _DemoShellItem(
      id: 'billing',
      title: 'Billing',
      description: 'Invoices, payment methods, and the current subscription plan.',
      icon: MdiIcons.creditCardOutline,
    ),
    const _DemoShellItem(
      id: 'integrations',
      title: 'Integrations',
      description: 'Third-party services connected to this workspace.',
      icon: MdiIcons.puzzleOutline,
    ),
    const _DemoShellItem(
      id: 'audit-log',
      title: 'Audit Log',
      description: 'A chronological record of changes made across the workspace.',
      icon: MdiIcons.fileDocumentOutline,
    ),
  ];

  /// How many refresh cycles have completed, used to give each prepended demo
  /// row a stable, unique key.
  int _refreshCount = 0;

  /// The time the last refresh completed, or null before the first one, shown
  /// in the list panel's footer alongside the refresh control.
  DateTime? _lastRefreshedAt;

  @override
  void initState() {
    super.initState();
    _controller = LayrzScaffoldController();
    _tableController = LayrzTableController<_DemoShellItem>();
    _refreshController = LayrzRefreshController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _tableController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  /// Simulates a network round-trip and then mutates the demo data so the
  /// refresh is visibly obvious: a new row is prepended to the list and the
  /// footer's "last refreshed" timestamp advances.
  Future<void> _onRefresh() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    _refreshCount++;
    if (mounted) {
      setState(() {
        _items.insert(
          0,
          _DemoShellItem(
            id: 'refreshed-$_refreshCount',
            title: 'Refreshed item #$_refreshCount',
            description:
                'This row was added by the simulated refresh — pull down, or use the footer '
                'control, to add another.',
            icon: MdiIcons.refresh,
          ),
        );
        _lastRefreshedAt = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Scaffold Shell',
      description:
          'LayrzScaffoldShell — an adaptive list-detail container. On desktop it opens on a full-width '
          'table and collapses to the list-detail split once an item is opened; on compact viewports it '
          'is a list plus a modal detail sheet. Includes search and a list-level refresh affordance '
          '(drag-to-refresh on touch, and an always-available footer control alongside the timestamp below).',
      child: SizedBox(
        height: 400,
        child: LayrzScaffoldShell<_DemoShellItem>(
          title: Text('Workspace', style: tokens.typography.title),
          itemExtent: 41.0,
          searchable: true,
          controller: _controller,
          items: _items.map((item) {
            return LayrzScaffoldItem<_DemoShellItem>(
              key: ValueKey(item.id),
              item: item,
              tile: _buildTile(item),
              searchableStrings: {item.title},
            );
          }).toList(),
          // On desktop, the shell opens on this full-width table (DESIGN-216);
          // pressing a row's "open" button collapses it into the list-detail
          // split. Compact viewports skip the table entirely.
          tableController: _tableController,
          tableColumns: [
            LayrzColumn<_DemoShellItem>(
              key: const ValueKey('title'),
              headerText: 'Title',
              valueBuilder: (item) => item.title,
              width: 240,
            ),
            LayrzColumn<_DemoShellItem>(
              key: const ValueKey('description'),
              headerText: 'Description',
              valueBuilder: (item) => item.description,
              width: 420,
            ),
          ],
          onItemTap: (item) => _controller.open(
            key: item.key,
            builder: (context) => _buildDetails(item.item),
          ),
          onRefresh: _onRefresh,
          refreshController: _refreshController,
          footer: _buildFooter(tokens),
        ),
      ),
    );
  }

  /// Builds the list panel's footer, shown alongside the built-in refresh
  /// control to demonstrate that a consumer-supplied [LayrzScaffoldShell.footer]
  /// coexists with the refresh affordance rather than being replaced by it.
  Widget _buildFooter(LayrzTokens tokens) {
    final label = _lastRefreshedAt == null
        ? 'Not refreshed yet'
        : 'Last refreshed at ${_lastRefreshedAt!.hour.toString().padLeft(2, '0')}:'
              '${_lastRefreshedAt!.minute.toString().padLeft(2, '0')}:'
              '${_lastRefreshedAt!.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1),
      child: Text(
        label,
        style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
      ),
    );
  }

  /// Builds a list tile for a single [_DemoShellItem].
  Widget _buildTile(_DemoShellItem item) {
    final tokens = context.tokens;
    return Row(
      mainAxisAlignment: .start,
      crossAxisAlignment: .center,
      spacing: tokens.spacing.sp1,
      children: [
        LayrzAvatar.icon(
          icon: item.icon,
          size: 30.0,
          borderRadius: tokens.radius.r2,
          elevation: 0,
        ),
        Flexible(
          child: Text(
            item.title,
            style: tokens.typography.body.copyWith(fontWeight: .bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Builds the detail pane content for a selected [_DemoShellItem].
  Widget _buildDetails(_DemoShellItem item) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Closing the detail is the app's responsibility (the shell only
          // cross-fades table<->split off the controller's open state).
          Align(
            alignment: Alignment.centerRight,
            child: LayrzButton(
              icon: MdiIcons.close,
              style: LayrzButtonStyle.textFab,
              labelText: 'Close',
              onTap: _controller.close,
            ),
          ),
          Text(item.title, style: tokens.typography.headline),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            item.description,
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
        ],
      ),
    );
  }
}
