import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// The search field header for the list panel.
///
/// Renders a search input with a leading magnifier icon, only when [searchable] is true.
/// When the user types, [onSearch] is called with the query.
class ListHeader extends StatefulWidget {
  /// Whether the search field is visible.
  final bool searchable;

  /// Callback fired when the search query changes.
  ///
  /// Called with the current text in the search field.
  final ValueChanged<String>? onSearch;

  /// Creates a new [ListHeader].
  ///
  /// - [searchable]: Whether to render the search field. Required.
  /// - [onSearch]: Callback for search query changes, or null. Defaults to null.
  const ListHeader({
    super.key,
    required this.searchable,
    this.onSearch,
  });

  @override
  State<ListHeader> createState() => _ListHeaderState();
}

class _ListHeaderState extends State<ListHeader> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(() {
      widget.onSearch?.call(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (!widget.searchable) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: tokens.colors.surface2,
        border: Border(
          bottom: BorderSide(
            color: tokens.colors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              MdiIcons.magnify,
              size: 12,
              color: tokens.colors.fg3,
            ),
          ),
          Expanded(
            child: EditableText(
              controller: _controller,
              focusNode: _focusNode,
              style: TextStyle(
                fontSize: 13,
                color: tokens.colors.fg1,
              ),
              cursorColor: tokens.colors.primary,
              backgroundCursorColor: tokens.colors.surface2,
            ),
          ),
        ],
      ),
    );
  }
}
