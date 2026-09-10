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

  /// The fake rows rendered by the demo shell.
  static const List<_DemoShellItem> _items = [
    _DemoShellItem(
      id: 'overview',
      title: 'Overview',
      description: 'A summary dashboard showing the current state of the workspace at a glance.',
      icon: MdiIcons.viewDashboardOutline,
    ),
    _DemoShellItem(
      id: 'settings',
      title: 'Settings',
      description: 'General configuration for the workspace, including preferences and defaults.',
      icon: MdiIcons.cogOutline,
    ),
    _DemoShellItem(
      id: 'members',
      title: 'Members',
      description: 'The people who have access to this workspace and their assigned roles.',
      icon: MdiIcons.accountGroupOutline,
    ),
    _DemoShellItem(
      id: 'billing',
      title: 'Billing',
      description: 'Invoices, payment methods, and the current subscription plan.',
      icon: MdiIcons.creditCardOutline,
    ),
    _DemoShellItem(
      id: 'integrations',
      title: 'Integrations',
      description: 'Third-party services connected to this workspace.',
      icon: MdiIcons.puzzleOutline,
    ),
    _DemoShellItem(
      id: 'audit-log',
      title: 'Audit Log',
      description: 'A chronological record of changes made across the workspace.',
      icon: MdiIcons.fileDocumentOutline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = LayrzScaffoldController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Scaffold Shell',
      description: 'LayrzScaffoldShell — an adaptive list-detail container with search and row actions.',
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
          onDetailsBuild: _buildDetails,
        ),
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
