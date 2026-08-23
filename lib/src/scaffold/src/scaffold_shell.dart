import "package:flutter/widgets.dart";
import "package:layrz_ui/src/extensions/extensions.dart";
import "package:layrz_ui/src/scaffold/src/scaffold_item.dart";
import "package:layrz_ui/src/sheets/sheets.dart";
import "package:layrz_ui/src/tokens/tokens.dart";

import "detail_pane.dart";
import "list_panel.dart";
import "scaffold_controller.dart";

/// An adaptive list-detail shell widget in the layrz_ui design system.
///
/// [LayrzScaffoldShell] provides a responsive container for list-detail navigation.
/// On wide containers (md, lg, xl breakpoints), the list panel (250px) and detail pane
/// are displayed side-by-side. On narrow containers (xs, sm breakpoints), a single pane
/// is shown: the list by default, and the detail after opening an item.
///
/// The shell is container-driven via [LayoutBuilder] constraints, not viewport-driven.
/// The consuming app passes items and owns the controller; the shell owns the layout
/// and search filtering.
class LayrzScaffoldShell<T> extends StatefulWidget {
  /// The items to display in the list.
  final List<LayrzScaffoldItem<T>> items;

  /// Callback to build the detail content for an opened item.
  final Widget Function(T) onDetailsBuild;

  /// Controller for managing the opened item.
  final LayrzScaffoldController controller;

  /// Optional footer widget for the list panel.
  final Widget? footer;

  /// Whether the search field is visible.
  final bool searchable;

  /// Optional title widget rendered above the search field in the list panel.
  final Widget? title;

  /// The item extent for the list panel.
  final double itemExtent;

  /// Optional widget to display when the list is empty.
  ///
  /// If null, a localized default message is displayed.
  final Widget? emptyState;

  /// Creates a new [LayrzScaffoldShell].
  ///
  /// - [items]: The items to display in the list. Required.
  /// - [onDetailsBuild]: Callback to build the detail content for an opened item. Required.
  /// - [controller]: Controller for managing the opened item. Required.
  /// - [footer]: Optional footer widget for the list panel. Defaults to null.
  /// - [searchable]: Whether the search field is visible. Defaults to true.
  /// - [title]: Optional title widget rendered above the search field. Defaults to null.
  /// - [itemExtent]: The height of each list item. Required.
  /// - [emptyState]: Optional widget to display when the list is empty. Defaults to null.
  const LayrzScaffoldShell({
    super.key,
    required this.items,
    required this.onDetailsBuild,
    required this.controller,
    this.footer,
    this.searchable = true,
    this.title,
    required this.itemExtent,
    this.emptyState,
  });

  @override
  State<LayrzScaffoldShell<T>> createState() => _LayrzScaffoldShellState<T>();
}

class _LayrzScaffoldShellState<T> extends State<LayrzScaffoldShell<T>> {
  late VoidCallback _controllerListener;
  late ValueNotifier<int> _itemsChangeNotifier;

  /// Flag to prevent double-pushing sheets in rapid rebuilds.
  bool _isSchedulingNarrowSheet = false;

  /// Reference to the builder context from the narrow sheet, used to pop it specifically.
  BuildContext? _narrowSheetContext;

  double get _itemExtent => widget.itemExtent + context.tokens.spacing.pd2.vertical;

  @override
  void initState() {
    super.initState();
    _controllerListener = () {
      setState(() {});
    };
    _itemsChangeNotifier = ValueNotifier(widget.items.length);
    widget.controller.addListener(_controllerListener);
  }

  @override
  void didUpdateWidget(LayrzScaffoldShell<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_controllerListener);
      widget.controller.addListener(_controllerListener);
    }
    // Notify when items change
    if (oldWidget.items.length != widget.items.length || !_itemsEqual(oldWidget.items, widget.items)) {
      _itemsChangeNotifier.value++;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerListener);
    _itemsChangeNotifier.dispose();
    super.dispose();
  }

  /// Check if items are equal by comparing their keys.
  bool _itemsEqual(List<LayrzScaffoldItem<T>> a, List<LayrzScaffoldItem<T>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].key != b[i].key) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tokens = context.tokens;
        final breakpoint = tokens.breakpoints.bandAt(constraints.maxWidth);
        final isWide = breakpoint.index >= LayrzBreakpoint.md.index;

        // Handle band transitions: close sheet when moving to wide layout
        if (isWide && _narrowSheetContext != null && _narrowSheetContext!.mounted) {
          // Schedule the pop for after the build, to avoid modifying the widget
          // tree during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_narrowSheetContext != null && _narrowSheetContext!.mounted) {
              Navigator.of(_narrowSheetContext!).pop();
              _narrowSheetContext = null;
            }
          });
        }

        if (isWide) {
          return _buildWideLayout(context, tokens);
        } else {
          return _buildNarrowLayout(context, tokens);
        }
      },
    );
  }

  /// Find the item with the opened key, or null if not found in the full list.
  ///
  /// This looks up the opened key in the unfiltered items list, so the detail pane
  /// can stay open even when its item is filtered out of the search results.
  LayrzScaffoldItem<T>? _findOpenedItem() {
    final openedKey = widget.controller.openedKey;
    if (openedKey == null) return null;
    try {
      return widget.items.firstWhere((item) => item.key == openedKey);
    } catch (e) {
      return null;
    }
  }

  Widget _buildWideLayout(BuildContext context, LayrzTokens tokens) {
    final openedItem = _findOpenedItem();

    return Row(
      children: [
        ListPanel<T>(
          items: widget.items,
          openedKey: widget.controller.openedKey,
          onTap: (item) {
            widget.controller.open(item.key);
          },
          searchable: widget.searchable,
          footer: widget.footer,
          title: widget.title,
          itemExtent: _itemExtent,
          emptyState: widget.emptyState,
        ),
        Container(
          width: 1,
          color: tokens.colors.divider,
        ),
        Expanded(
          child: DetailPane<T>(
            opened: openedItem?.item,
            contentBuilder: openedItem != null ? widget.onDetailsBuild : null,
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, LayrzTokens tokens) {
    // Always show the list panel on narrow layouts
    final panel = ListPanel<T>(
      items: widget.items,
      openedKey: widget.controller.openedKey,
      onTap: (item) {
        widget.controller.open(item.key);
      },
      searchable: widget.searchable,
      footer: widget.footer,
      title: widget.title,
      itemExtent: _itemExtent,
      emptyState: widget.emptyState,
    );

    // Schedule the sheet presentation in a post-frame callback to avoid building
    // during the build phase
    if (widget.controller.isOpen && !_isSchedulingNarrowSheet) {
      _isSchedulingNarrowSheet = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showNarrowDetailSheet(context);
        }
        _isSchedulingNarrowSheet = false;
      });
    }

    return panel;
  }

  /// Shows the detail sheet for narrow layouts.
  ///
  /// Opens a LayrzBottomSheet with the detail content. Handles the case where
  /// the opened item is no longer in the list, and manages dismissal to close
  /// the controller.
  Future<void> _showNarrowDetailSheet(BuildContext context) async {
    // Guard: check if there's a Navigator available
    final navigator = Navigator.maybeOf(context);
    if (navigator == null) {
      assert(
        false,
        'LayrzScaffoldShell on narrow breakpoints requires a Navigator ancestor '
        '(e.g., inside LayrzApp) to present the detail sheet. No Navigator found in context.',
      );
      return;
    }

    // If the opened item doesn't exist, close the controller
    if (_findOpenedItem() == null) {
      if (mounted) {
        widget.controller.close();
      }
      return;
    }

    // Show the sheet
    await LayrzBottomSheet.show<void>(
      context,
      builder: (sheetContext) {
        _narrowSheetContext = sheetContext;
        return ListenableBuilder(
          listenable: Listenable.merge([widget.controller, _itemsChangeNotifier]),
          builder: (context, _) {
            final openedItem = _findOpenedItem();
            if (openedItem == null) {
              // Item was removed from the list; pop the sheet
              if (mounted && _narrowSheetContext != null && _narrowSheetContext!.mounted) {
                Navigator.of(_narrowSheetContext!).pop();
              }
              return const SizedBox.shrink();
            }
            return DetailPane(
              opened: openedItem.item,
              contentBuilder: widget.onDetailsBuild,
            );
          },
        );
      },
    );

    // When the sheet is dismissed (user dragged down, tapped barrier, etc.),
    // close the controller to match the screen state
    if (mounted) {
      widget.controller.close();
    }
  }
}
