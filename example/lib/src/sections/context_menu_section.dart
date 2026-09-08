import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// The content widget for the context menu section.
///
/// Demonstrates [LayrzContextMenu] wrapping a sample card target. Right-click
/// (desktop/web) or long-press (touch) the card to open a panel built from
/// [LayrzContextMenuEntry], [LayrzContextMenuLabel], and
/// [LayrzContextMenuDivider]. Tapping an entry updates a "last action" echo
/// shown below the card so the demo's interactivity is visible without
/// inspecting a snackbar or console log.
class ContextMenuSection extends StatelessWidget {
  /// Creates a new [ContextMenuSection].
  const ContextMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Context Menu',
      description:
          'A Material-free context menu anchored at the pointer, shown on right-click '
          '(desktop/web) or long-press (touch), built from a small, self-contained entry model.',
      child: _ContextMenuDemo(tokens: tokens),
    );
  }
}

/// Stateful demo body holding the "last action" echo.
///
/// Threads [tokens] the same way the other `*Demo` helpers in this showroom
/// do, so the sample card and instructional text stay themed without each
/// re-reading [BuildContext].
class _ContextMenuDemo extends StatefulWidget {
  /// Creates a new [_ContextMenuDemo].
  const _ContextMenuDemo({required this.tokens});

  /// The design system tokens used to style this demo.
  final LayrzTokens tokens;

  @override
  State<_ContextMenuDemo> createState() => _ContextMenuDemoState();
}

class _ContextMenuDemoState extends State<_ContextMenuDemo> {
  /// The label of the most recently activated entry, or `null` before any
  /// entry has been tapped.
  String? _lastAction;

  void _handleAction(String label) {
    setState(() {
      _lastAction = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Right-click or long-press the card below', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp2),
        Text(
          'The panel opens anchored exactly at the pointer position, staying clamped '
          'inside the viewport regardless of how close to an edge it was triggered.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp4),
        LayrzContextMenu(
          entries: [
            LayrzContextMenuLabel(labelText: 'Actions'),
            LayrzContextMenuEntry(
              labelText: 'Rename',
              icon: MdiIcons.renameBox,
              onTap: () => _handleAction('Rename'),
            ),
            LayrzContextMenuEntry(
              labelText: 'Duplicate',
              icon: MdiIcons.contentDuplicate,
              onTap: () => _handleAction('Duplicate'),
            ),
            const LayrzContextMenuDivider(),
            LayrzContextMenuEntry(
              labelText: 'Delete',
              icon: MdiIcons.trashCanOutline,
              color: tokens.colors.danger[500],
              onTap: () => _handleAction('Delete'),
            ),
            LayrzContextMenuEntry(
              labelText: 'Archive (disabled)',
              icon: MdiIcons.archiveOutline,
              enabled: false,
              onTap: () => _handleAction('Archive'),
            ),
          ],
          child: _SampleCard(tokens: tokens),
        ),
        SizedBox(height: tokens.spacing.sp4),
        Container(
          padding: EdgeInsets.all(tokens.spacing.sp3),
          decoration: BoxDecoration(
            color: tokens.colors.sf2,
            borderRadius: tokens.radius.br2,
            border: Border.all(color: tokens.colors.divider),
          ),
          child: Text(
            _lastAction == null ? 'Last action: none yet' : 'Last action: $_lastAction',
            style: tokens.typography.label.copyWith(color: tokens.colors.fg2),
          ),
        ),
      ],
    );
  }
}

/// A small placeholder card used as the context menu's anchor target.
///
/// Stands in for a real list row, grid tile, or document card -- the
/// realistic use case for [LayrzContextMenu].
class _SampleCard extends StatelessWidget {
  /// Creates a new [_SampleCard].
  const _SampleCard({required this.tokens});

  /// The design tokens used to style this card, threaded from the parent build.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 100,
      padding: EdgeInsets.all(tokens.spacing.sp3),
      decoration: BoxDecoration(
        color: tokens.colors.sf2,
        borderRadius: tokens.radius.br2,
        border: Border.all(color: tokens.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(MdiIcons.fileDocumentOutline, size: 20, color: tokens.colors.fg3),
          SizedBox(height: tokens.spacing.sp2),
          Text('report.pdf', style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
        ],
      ),
    );
  }
}
