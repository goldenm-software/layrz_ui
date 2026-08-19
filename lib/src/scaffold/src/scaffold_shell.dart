import "package:flutter/widgets.dart";
import "package:layrz_ui/src/extensions/extensions.dart";
import "package:layrz_ui/src/tokens/tokens.dart";

import "detail_pane.dart";
import "list_panel.dart";
import "scaffold_controller.dart";
import "scaffold_tile.dart";

/// An adaptive list-detail shell widget in the layrz_ui design system.
///
/// [LayrzScaffoldShell] provides a responsive container for list-detail navigation.
/// On wide containers (md, lg, xl breakpoints), the list panel (250px) and detail pane
/// are displayed side-by-side. On narrow containers (xs, sm breakpoints), a single pane
/// is shown: the list by default, and the detail after opening an item.
///
/// The shell is container-driven via [LayoutBuilder] constraints, not viewport-driven.
/// The consuming app passes items and owns the controller; the shell owns the layout.
class LayrzScaffoldShell<T> extends StatefulWidget {
  /// The items to display in the list.
  final List<T> items;

  /// Callback to build a tile for each item.
  final LayrzScaffoldTile Function(BuildContext, T) onBuild;

  /// Callback to build the detail content for an opened item.
  final Widget Function(BuildContext, T) onDetailsBuild;

  /// Controller for managing the opened item.
  final LayrzScaffoldController<T> controller;

  /// Optional footer widget for the list panel.
  final Widget? footer;

  /// Whether the search field is visible.
  final bool searchable;

  /// Callback when the search query changes.
  final ValueChanged<String>? onSearch;

  /// Creates a new [LayrzScaffoldShell].
  ///
  /// - [items]: The items to display in the list. Required.
  /// - [onBuild]: Callback to build a tile for each item. Required.
  /// - [onDetailsBuild]: Callback to build the detail content for an opened item. Required.
  /// - [controller]: Controller for managing the opened item. Required.
  /// - [footer]: Optional footer widget for the list panel. Defaults to null.
  /// - [searchable]: Whether the search field is visible. Defaults to true.
  /// - [onSearch]: Callback when the search query changes, or null. Defaults to null.
  const LayrzScaffoldShell({
    super.key,
    required this.items,
    required this.onBuild,
    required this.onDetailsBuild,
    required this.controller,
    this.footer,
    this.searchable = true,
    this.onSearch,
  });

  @override
  State<LayrzScaffoldShell<T>> createState() => _LayrzScaffoldShellState<T>();
}

class _LayrzScaffoldShellState<T> extends State<LayrzScaffoldShell<T>> {
  late void Function() _controllerListener;

  @override
  void initState() {
    super.initState();
    _controllerListener = () {
      setState(() {});
    };
    widget.controller.addListener(_controllerListener);
  }

  @override
  void didUpdateWidget(LayrzScaffoldShell<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_controllerListener);
      widget.controller.addListener(_controllerListener);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tokens = context.tokens;
        final breakpoint = tokens.breakpoints.bandAt(constraints.maxWidth);
        final isWide = breakpoint.index >= LayrzBreakpoint.md.index;

        if (isWide) {
          return _buildWideLayout(context, tokens);
        } else {
          return _buildNarrowLayout(context, tokens);
        }
      },
    );
  }

  /// Check if the opened item's tile is present in the current items.
  bool _isOpenedTileInList(BuildContext context, T? opened) {
    if (opened == null) return false;
    final openedTile = widget.onBuild(context, opened);
    for (final item in widget.items) {
      final itemTile = widget.onBuild(context, item);
      if (itemTile == openedTile) return true;
    }
    return false;
  }

  Widget _buildWideLayout(BuildContext context, LayrzTokens tokens) {
    final opened = widget.controller.opened;
    final isOpenedInList = _isOpenedTileInList(context, opened);

    return Row(
      children: [
        ListPanel<T>(
          items: widget.items,
          onBuild: widget.onBuild,
          opened: opened,
          onTap: (item) {
            widget.controller.open(item);
          },
          onSearch: widget.onSearch,
          searchable: widget.searchable,
          footer: widget.footer,
        ),
        Container(
          width: 1,
          color: tokens.colors.divider,
        ),
        Expanded(
          child: DetailPane<T>(
            opened: isOpenedInList ? opened : null,
            contentBuilder: isOpenedInList ? widget.onDetailsBuild : null,
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, LayrzTokens tokens) {
    final opened = widget.controller.opened;
    final isOpenedInList = _isOpenedTileInList(context, opened);
    final showDetail = widget.controller.isOpen && isOpenedInList;

    if (showDetail) {
      return DetailPane<T>(
        opened: opened,
        contentBuilder: widget.onDetailsBuild,
        onClose: () {
          widget.controller.close();
        },
        showBack: true,
      );
    } else {
      return ListPanel<T>(
        items: widget.items,
        onBuild: widget.onBuild,
        opened: opened,
        onTap: (item) {
          widget.controller.open(item);
        },
        onSearch: widget.onSearch,
        searchable: widget.searchable,
        footer: widget.footer,
      );
    }
  }
}
