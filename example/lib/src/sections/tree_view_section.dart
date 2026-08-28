import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// A small file/folder payload used to give each demo row a realistic label
/// and icon, distinct from the bare `String` content used in the package's
/// own unit tests.
class _FileEntry {
  /// Creates a [_FileEntry].
  const _FileEntry(this.name, this.icon);

  /// The display name shown for this entry.
  final String name;

  /// The icon shown before [name].
  final IconData icon;
}

/// Builds the tree view section for the showroom.
///
/// Demonstrates [LayrzTreeView] (the self-scrolling box form) built on the
/// SDK's `TreeSliver`, showing a small file-explorer-shaped tree three levels
/// deep. Two independent trees are shown side by side so both
/// [LayrzTreeSelectionMode]s can be compared directly:
///
/// - The left tree uses [LayrzTreeSelectionMode.independent] (the default):
///   selecting a folder selects only that folder, never its contents.
/// - The right tree uses [LayrzTreeSelectionMode.cascading]: selecting a
///   folder selects every file and subfolder beneath it, and a folder with
///   only some of its contents selected renders the third, partial
///   (indeterminate) checkbox state.
///
/// Both trees share the same underlying node shape; only their
/// [LayrzTreeSelectionController.mode] differs, which is the whole point of
/// keeping selection logic in its own file, cleanly separable from the
/// `TreeSliver` integration -- switching modes here does not touch how either
/// tree is built or rendered.
class TreeViewSection extends StatefulWidget {
  /// Creates a new [TreeViewSection].
  const TreeViewSection({super.key});

  @override
  State<TreeViewSection> createState() => _TreeViewSectionState();
}

class _TreeViewSectionState extends State<TreeViewSection> {
  late LayrzTreeSelectionController<_FileEntry> _independentSelection;
  late LayrzTreeSelectionController<_FileEntry> _cascadingSelection;

  late List<LayrzTreeNode<_FileEntry>> _independentNodes;
  late List<LayrzTreeNode<_FileEntry>> _cascadingNodes;

  Set<Object> _independentSelectedIds = {};
  Set<Object> _cascadingSelectedIds = {};

  @override
  void initState() {
    super.initState();
    _independentNodes = _buildFileTree();
    _cascadingNodes = _buildFileTree();
    _independentSelection = LayrzTreeSelectionController<_FileEntry>(roots: _independentNodes);
    _cascadingSelection = LayrzTreeSelectionController<_FileEntry>(
      roots: _cascadingNodes,
      mode: LayrzTreeSelectionMode.cascading,
    );
  }

  @override
  void dispose() {
    _independentSelection.dispose();
    _cascadingSelection.dispose();
    super.dispose();
  }

  /// Builds a fresh three-level file/folder tree fixture:
  /// ```
  /// project/
  ///   src/
  ///     main.dart
  ///     widgets/
  ///       button.dart
  ///       card.dart
  ///   README.md
  /// ```
  /// Called once per tree instance (rather than shared) since
  /// [LayrzTreeNode] ids must be unique across the whole tree a controller
  /// walks, and each demo tree here is its own independent tree.
  List<LayrzTreeNode<_FileEntry>> _buildFileTree() => [
    LayrzTreeNode<_FileEntry>(
      id: 'project',
      content: const _FileEntry('project', MdiIcons.folderOutline),
      initiallyExpanded: true,
      children: [
        LayrzTreeNode<_FileEntry>(
          id: 'src',
          content: const _FileEntry('src', MdiIcons.folderOutline),
          initiallyExpanded: true,
          children: [
            LayrzTreeNode<_FileEntry>(
              id: 'main.dart',
              content: const _FileEntry('main.dart', MdiIcons.fileCodeOutline),
            ),
            LayrzTreeNode<_FileEntry>(
              id: 'widgets',
              content: const _FileEntry('widgets', MdiIcons.folderOutline),
              children: [
                LayrzTreeNode<_FileEntry>(
                  id: 'button.dart',
                  content: const _FileEntry('button.dart', MdiIcons.fileCodeOutline),
                ),
                LayrzTreeNode<_FileEntry>(
                  id: 'card.dart',
                  content: const _FileEntry('card.dart', MdiIcons.fileCodeOutline),
                ),
              ],
            ),
          ],
        ),
        LayrzTreeNode<_FileEntry>(
          id: 'readme',
          content: const _FileEntry('README.md', MdiIcons.fileDocumentOutline),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Tree View',
      description:
          'Expand/collapse and multi-node selection built on the SDK\'s TreeSliver. Compare '
          'independent selection (left) against cascading selection with a partial state (right).',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = context.isCompact;
          final content = isCompact
              ? Column(
                  spacing: tokens.spacing.sp3,
                  children: [
                    _buildDemoColumn(
                      tokens: tokens,
                      title: 'Independent selection (default)',
                      nodes: _independentNodes,
                      selectionController: _independentSelection,
                      selectedIds: _independentSelectedIds,
                      onSelectionChanged: (ids) => setState(() => _independentSelectedIds = ids),
                    ),
                    _buildDemoColumn(
                      tokens: tokens,
                      title: 'Cascading selection',
                      nodes: _cascadingNodes,
                      selectionController: _cascadingSelection,
                      selectedIds: _cascadingSelectedIds,
                      onSelectionChanged: (ids) => setState(() => _cascadingSelectedIds = ids),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: tokens.spacing.sp3,
                  children: [
                    Expanded(
                      child: _buildDemoColumn(
                        tokens: tokens,
                        title: 'Independent selection (default)',
                        nodes: _independentNodes,
                        selectionController: _independentSelection,
                        selectedIds: _independentSelectedIds,
                        onSelectionChanged: (ids) => setState(() => _independentSelectedIds = ids),
                      ),
                    ),
                    Expanded(
                      child: _buildDemoColumn(
                        tokens: tokens,
                        title: 'Cascading selection',
                        nodes: _cascadingNodes,
                        selectionController: _cascadingSelection,
                        selectedIds: _cascadingSelectedIds,
                        onSelectionChanged: (ids) => setState(() => _cascadingSelectedIds = ids),
                      ),
                    ),
                  ],
                );

          return Padding(
            padding: EdgeInsets.all(tokens.spacing.sp3),
            child: content,
          );
        },
      ),
    );
  }

  /// Builds one labelled demo tree plus a caption reporting how many nodes
  /// are currently selected, given [selectedIds].
  ///
  /// [LayrzTreeView] is itself a `CustomScrollView` (via [LayrzSliverTreeView])
  /// and therefore needs bounded height from its parent -- unlike
  /// `ShowroomSection`'s own `SingleChildScrollView`, which hands its child
  /// unbounded height. The fixed-height [SizedBox] here supplies that bound,
  /// the same accommodation any real caller placing a tree inside a scrolling
  /// page would need to make.
  Widget _buildDemoColumn({
    required LayrzTokens tokens,
    required String title,
    required List<LayrzTreeNode<_FileEntry>> nodes,
    required LayrzTreeSelectionController<_FileEntry> selectionController,
    required Set<Object> selectedIds,
    required void Function(Set<Object> ids) onSelectionChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp2,
      children: [
        Text(title, style: tokens.typography.title),
        Text(
          selectedIds.isEmpty ? 'Nothing selected' : '${selectedIds.length} node(s) selected',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(
          height: 260,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: tokens.colors.divider),
              borderRadius: BorderRadius.circular(tokens.radius.r2),
            ),
            child: LayrzTreeView<_FileEntry>(
              nodes: nodes,
              selectable: true,
              selectionController: selectionController,
              onSelectionChanged: onSelectionChanged,
              padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp1),
              nodeBuilder: _buildRowContent,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the inner row content for a node -- the icon plus its label. The
  /// chevron, indent guide, and selection checkbox are always supplied by
  /// [LayrzTreeRow] itself; this builder only fills in what is specific to
  /// the demo's own payload type.
  Widget _buildRowContent(
    BuildContext context,
    LayrzTreeNode<_FileEntry> node,
    int depth,
    bool isExpanded,
    bool isLeaf,
    bool isSelected,
    bool isPartiallySelected,
    VoidCallback? onToggle,
    VoidCallback? onSelect,
  ) {
    final tokens = context.tokens;
    return Row(
      children: [
        Icon(node.content.icon, size: 18, color: tokens.colors.fg2),
        SizedBox(width: tokens.spacing.sp1),
        Flexible(
          child: Text(
            node.content.name,
            style: tokens.typography.body,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
