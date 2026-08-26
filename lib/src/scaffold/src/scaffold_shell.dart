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
/// are displayed side-by-side. On narrow containers (xs, sm breakpoints), the list panel
/// is always shown; opening an item presents the detail content in a modal [LayrzBottomSheet]
/// layered over the list. Dismissing the sheet closes the controller. A resize from narrow
/// to wide pops the sheet but preserves the selection, and a resize to narrow auto-opens
/// the sheet for any already-selected item.
///
/// **Narrow layout constraint:** The shell requires a [Navigator] ancestor (e.g. [LayrzApp])
/// to show the detail sheet on narrow breakpoints. If no Navigator is present, the list
/// still renders without the detail, and a debug assertion fires on the sheet attempt.
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

  /// Whether a detail sheet is currently open on narrow layouts.
  bool _sheetOpen = false;

  /// Whether the shell initiated the last sheet pop (band transition).
  /// If true, don't close the controller when the sheet closes.
  bool _dismissedByShell = false;

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
    // Notify when items list instance changes (handles refetches with same keys but new instances),
    // but only while the narrow sheet's ListenableBuilder is actually listening to this notifier —
    // otherwise the bump is both unobserved and unsafe.
    //
    // The bump is deferred to a post-frame callback rather than applied synchronously here: this
    // notifier is merged into the Listenable driving the sheet's ListenableBuilder, so an immediate
    // `.value++` fires `notifyListeners()` -> `setState()` on that (possibly still-mounted, e.g.
    // mid exit-animation) builder while the framework may already be building this shell's own
    // subtree (e.g. from a LayoutBuilder-driven breakpoint change). That is an illegal
    // setState-during-build. Deferring costs at most one extra frame, and only when the sheet is
    // actually open to observe it.
    if (_sheetOpen && !identical(oldWidget.items, widget.items)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sheetOpen) {
          _itemsChangeNotifier.value++;
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerListener);
    _itemsChangeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tokens = context.tokens;
        final breakpoint = tokens.breakpoints.bandAt(constraints.maxWidth);
        final isWide = breakpoint.index >= LayrzBreakpoint.md.index;

        // Handle band transitions: close sheet when moving to wide layout
        if (isWide && _sheetOpen) {
          // Schedule the pop for after the build, to avoid modifying the widget tree during build.
          // Mark it as shell-initiated so the sheet dismissal callback doesn't close the controller.
          _dismissedByShell = true;
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

    // Schedule the sheet presentation in a post-frame callback to avoid building during build.
    // Only schedule if controller is open and no sheet is already open.
    if (widget.controller.isOpen && !_sheetOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showNarrowDetailSheet(context);
        }
      });
    }

    return panel;
  }

  /// Shows the detail sheet for narrow layouts.
  ///
  /// Opens a LayrzBottomSheet with the detail content. Handles the case where
  /// the opened item is no longer in the list, and manages dismissal to close
  /// the controller (unless the shell initiated the pop via band transition).
  Future<void> _showNarrowDetailSheet(BuildContext context) async {
    // Guard: if sheet is already open, do not open again (prevents stacking)
    if (_sheetOpen) return;

    // Reset the shell-dismissal flag so a stale value doesn't leak across presentations
    _dismissedByShell = false;

    // Mark the sheet as open before checking anything else
    _sheetOpen = true;

    // Guard: check if there's a Navigator available
    final navigator = Navigator.maybeOf(context);
    if (navigator == null) {
      assert(
        false,
        'LayrzScaffoldShell on narrow breakpoints requires a Navigator ancestor '
        '(e.g., inside LayrzApp) to present the detail sheet. No Navigator found in context.',
      );
      _sheetOpen = false;
      return;
    }

    // If the opened item doesn't exist, close the controller
    if (_findOpenedItem() == null) {
      _sheetOpen = false;
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
              // Item was removed from the list while the sheet is genuinely still
              // open; pop the sheet in the next frame. Guarding on `_sheetOpen` (not
              // just context-mounted) matters: this `ListenableBuilder` stays mounted
              // for the sheet route's own exit animation, so a user-initiated dismiss
              // (barrier tap / drag) reaches here too — via `widget.controller.close()`
              // notifying this same listenable while the route animates out. At that
              // point `_sheetOpen` is already false (set right after the dismiss's
              // `await LayrzBottomSheet.show` resolves, before this rebuild runs), so
              // it is a clean discriminator between "still open, must pop" and
              // "already closing, must not pop again" — unlike context.mounted, which
              // stays true throughout the exit animation either way.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _sheetOpen && _narrowSheetContext != null && _narrowSheetContext!.mounted) {
                  Navigator.of(_narrowSheetContext!).pop();
                }
              });
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

    // Mark the sheet as closed
    _sheetOpen = false;

    // When the sheet is dismissed (user dragged down, tapped barrier, etc.),
    // close the controller to match the screen state — unless the shell initiated
    // the pop (band transition). In that case, the selection should be preserved.
    if (_dismissedByShell) {
      _dismissedByShell = false;
    } else {
      if (mounted) {
        widget.controller.close();
      }
    }
  }
}
