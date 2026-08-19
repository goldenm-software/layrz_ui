import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'group_mode.dart';
import 'group_toggle.dart';

/// Private list header widget.
class ListHeader extends StatefulWidget {
  /// Optional title for the list header.
  final String? title;

  /// The number of items currently displayed.
  final int itemCount;

  /// Whether any items have a non-null group.
  final bool hasGroupedItems;

  /// The current group mode (grouped or flat).
  final LayrzScaffoldGroupMode groupMode;

  /// Callback fired when the group mode is changed.
  final ValueChanged<LayrzScaffoldGroupMode> onGroupModeChanged;

  /// Whether to display the filter/search field.
  final bool searchable;

  /// Controller for the filter text field.
  final TextEditingController filterController;

  /// Callback fired when the filter text changes.
  final VoidCallback onFilterChanged;

  /// Creates a new [ListHeader].
  const ListHeader({
    super.key,
    required this.title,
    required this.itemCount,
    required this.hasGroupedItems,
    required this.groupMode,
    required this.onGroupModeChanged,
    required this.searchable,
    required this.filterController,
    required this.onFilterChanged,
  });

  @override
  State<ListHeader> createState() => _ListHeaderState();
}

class _ListHeaderState extends State<ListHeader> {
  late FocusNode _filterFocusNode;

  @override
  void initState() {
    super.initState();
    _filterFocusNode = FocusNode();
    widget.filterController.addListener(widget.onFilterChanged);
  }

  @override
  void dispose() {
    _filterFocusNode.dispose();
    widget.filterController.removeListener(widget.onFilterChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kLayrzScaffoldHeaderHorizontalPadding,
        kLayrzScaffoldHeaderTopPadding,
        kLayrzScaffoldHeaderHorizontalPadding,
        kLayrzScaffoldHeaderBottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title != null || widget.hasGroupedItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  if (widget.title != null)
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: TextStyle(
                          fontSize: kLayrzScaffoldHeaderTitleFontSize,
                          fontWeight: FontWeight.w700,
                          color: t.colors.fg1,
                        ),
                      ),
                    ),
                  if (widget.title != null)
                    Text(
                      widget.itemCount.toString(),
                      style: TextStyle(
                        fontSize: kLayrzScaffoldHeaderCountFontSize,
                        color: t.colors.fg3,
                      ),
                    ),
                  if (widget.hasGroupedItems) ...[
                    const SizedBox(width: kLayrzScaffoldHeaderGap),
                    GroupToggle(
                      groupMode: widget.groupMode,
                      onChanged: widget.onGroupModeChanged,
                    ),
                  ],
                ],
              ),
            ),
          if (widget.searchable)
            FilterField(
              controller: widget.filterController,
              focusNode: _filterFocusNode,
            ),
        ],
      ),
    );
  }
}

/// Private filter field widget.
class FilterField extends StatelessWidget {
  /// Controller for the filter text field.
  final TextEditingController controller;

  /// Focus node for the filter text field.
  final FocusNode focusNode;

  /// Creates a new [FilterField].
  const FilterField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return SizedBox(
      height: kLayrzScaffoldFilterHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.colors.surface2,
          border: Border.all(color: t.colors.divider, width: 1),
          borderRadius: BorderRadius.circular(kLayrzScaffoldFilterHeight / 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kLayrzScaffoldFilterHorizontalPadding,
          ),
          child: Row(
            children: [
              Icon(
                LayrzIcons.solarOutlineMagnifer,
                size: kLayrzScaffoldFilterIconSize,
                color: t.colors.fg3,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: EditableText(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(
                    fontSize: kLayrzScaffoldFilterFontSize,
                    color: t.colors.fg1,
                  ),
                  cursorColor: t.colors.primary,
                  backgroundCursorColor: t.colors.surface2,
                  selectionColor: t.colors.primary.withOpacityValue(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
