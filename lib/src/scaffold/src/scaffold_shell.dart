import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'detail_pane.dart';
import 'group_mode.dart';
import 'list_panel.dart';
import 'scaffold_item.dart';

/// An adaptive list-detail shell widget in the layrz_ui design system.
///
/// [LayrzScaffoldShell] provides a responsive container for list-detail navigation.
/// On wide containers (md, lg, xl breakpoints), the list panel (250px) and detail pane
/// are displayed side-by-side. On narrow containers (xs, sm breakpoints), a single pane
/// is shown: the list by default, and the detail after selection. The shell owns the layout,
/// visibility, and state; the consuming app owns which item is selected.
///
/// **Core contract:**
/// - The consuming app passes [items] and [selectedId], and receives [onSelected] callbacks.
/// - The shell owns the filter query, group mode, and detail visibility on narrow containers.
/// - The [contentBuilder] callback receives the selected item and returns the detail widget.
///
/// **Narrow-mode behaviour:**
/// - When no item is selected ([selectedId] is null), the list is shown.
/// - When an item is selected ([selectedId] is non-null), the detail is shown.
/// - A back affordance in the detail header returns to the list without modifying [selectedId].
/// - This is a pure state transition, not a navigation operation (no [Navigator] calls).
///
/// **Filtering and grouping:**
/// - The filter query is applied case-insensitively as a substring match over [title] and [subtitle].
/// - The group mode toggle is rendered only when at least one item has a non-null [group].
/// - When no items match the filter, an empty state is shown quoting the active query.
class LayrzScaffoldShell extends StatefulWidget {
  /// Creates a new [LayrzScaffoldShell].
  const LayrzScaffoldShell({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
    required this.contentBuilder,
    this.listTitle,
    this.footer,
    this.detailActions = const [],
    this.detailTitle,
    this.detailSubtitle,
    this.searchable = true,
    this.initialGroupMode = LayrzScaffoldGroupMode.grouped,
  });

  /// The list of items to display in the list panel.
  ///
  /// When empty, the list shows as empty. When the filter query matches no items,
  /// the empty state is shown. Otherwise, the matching items are displayed.
  final List<LayrzScaffoldItem> items;

  /// The [id] of the currently selected item.
  ///
  /// When null or matching no item, the detail pane shows an empty state.
  /// When non-null and matching an item, the detail pane shows the result
  /// of [contentBuilder] called with the selected item.
  /// Owned by the consuming app; changes are reported via [onSelected].
  final String? selectedId;

  /// Callback fired when the user selects an item in the list panel.
  ///
  /// The callback receives the [id] of the selected item. The consuming app
  /// is responsible for updating [selectedId] in response.
  final ValueChanged<String> onSelected;

  /// Builds the detail widget for the currently selected item.
  ///
  /// Called with the selected [LayrzScaffoldItem]. The returned widget is displayed
  /// in the detail pane. When [selectedId] is null or matches no item, the detail pane
  /// shows an empty state and this callback is not called.
  final Widget Function(BuildContext, LayrzScaffoldItem) contentBuilder;

  /// Optional title for the list panel.
  ///
  /// When non-null, this title is displayed in the list header above the filter field.
  /// Defaults to null.
  final String? listTitle;

  /// Optional footer widget for the list panel.
  ///
  /// When non-null, this widget is displayed in a footer section below the list body.
  /// The footer receives 1px divider above it, padding, and is scrolled with the panel.
  /// Defaults to null.
  final Widget? footer;

  /// List of action widgets to display in the detail pane header.
  ///
  /// These widgets are right-aligned in the detail header, after the title/subtitle block.
  /// Useful for edit, delete, or other item-specific actions. Defaults to an empty list.
  final List<Widget> detailActions;

  /// Optional title to override the selected item's title in the detail header.
  ///
  /// When non-null, this title is displayed instead of [LayrzScaffoldItem.title].
  /// When null, the selected item's [title] is displayed. Defaults to null.
  final String? detailTitle;

  /// Optional subtitle to display in the detail header.
  ///
  /// When non-null, this subtitle is displayed below the detail title.
  /// Defaults to null.
  final String? detailSubtitle;

  /// Whether the list panel includes a search/filter field.
  ///
  /// When true, the filter field is rendered in the list header, allowing the user
  /// to narrow the list by substring match over [title] and [subtitle].
  /// When false, the filter field is hidden. Defaults to true.
  final bool searchable;

  /// The initial group mode for the list panel.
  ///
  /// Sets the default arrangement of items (grouped vs. flat). The user can toggle
  /// this if at least one item has a non-null [group]. Defaults to [LayrzScaffoldGroupMode.grouped].
  final LayrzScaffoldGroupMode initialGroupMode;

  @override
  State<LayrzScaffoldShell> createState() => _LayrzScaffoldShellState();
}

class _LayrzScaffoldShellState extends State<LayrzScaffoldShell> {
  late TextEditingController _filterController;
  late LayrzScaffoldGroupMode _groupMode;
  late bool _showDetailOnNarrow;

  @override
  void initState() {
    super.initState();
    _filterController = TextEditingController();
    _groupMode = widget.initialGroupMode;
    _showDetailOnNarrow = widget.selectedId != null;
  }

  @override
  void didUpdateWidget(LayrzScaffoldShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGroupMode != widget.initialGroupMode) {
      _groupMode = widget.initialGroupMode;
    }
    if (oldWidget.selectedId != widget.selectedId) {
      _showDetailOnNarrow = widget.selectedId != null;
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final band = context.tokens.breakpoints.bandAt(constraints.maxWidth);
        final isNarrow = band == LayrzBreakpoint.xs || band == LayrzBreakpoint.sm;

        return Flex(
          direction: Axis.horizontal,
          children: [
            if (isNarrow && _showDetailOnNarrow)
              Expanded(
                child: _buildDetailPane(context, isNarrow),
              )
            else if (!isNarrow)
              SizedBox(
                width: kLayrzScaffoldListWidth,
                child: _buildListPanel(context),
              )
            else
              Expanded(
                child: _buildListPanel(context),
              ),
            if (!isNarrow)
              Expanded(
                child: _buildDetailPane(context, isNarrow),
              ),
          ],
        );
      },
    );
  }

  Widget _buildListPanel(BuildContext context) {
    return ListPanel(
      items: widget.items,
      selectedId: widget.selectedId,
      onSelected: (id) {
        widget.onSelected(id);
        setState(() => _showDetailOnNarrow = true);
      },
      filterController: _filterController,
      groupMode: _groupMode,
      onGroupModeChanged: (mode) => setState(() => _groupMode = mode),
      listTitle: widget.listTitle,
      searchable: widget.searchable,
      footer: widget.footer,
    );
  }

  Widget _buildDetailPane(BuildContext context, bool isNarrow) {
    final selectedItem = widget.items.cast<LayrzScaffoldItem?>().firstWhere(
      (item) => item?.id == widget.selectedId,
      orElse: () => null,
    );

    return DetailPane(
      selectedItem: selectedItem,
      contentBuilder: selectedItem == null ? null : (ctx) => widget.contentBuilder(ctx, selectedItem),
      onBack: () => setState(() => _showDetailOnNarrow = false),
      detailTitle: widget.detailTitle ?? selectedItem?.title,
      detailSubtitle: widget.detailSubtitle,
      detailActions: widget.detailActions,
      showBack: isNarrow,
    );
  }
}
