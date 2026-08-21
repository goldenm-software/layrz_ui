import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

/// The selection surface content used by [LayrzSelectInput].
///
/// This widget renders a search field (if enabled) and a scrollable list of items.
/// It manages keyboard navigation (arrow keys, Enter, Escape) and item selection.
///
/// This is a private implementation detail; consumers use [LayrzSelectInput] instead.
class LayrzSelectInputSurface<T> extends StatefulWidget {
  /// The list of items to display.
  final List<LayrzSelectItem<T>> items;

  /// The currently selected item (for visual highlighting).
  final LayrzSelectItem<T>? selectedItem;

  /// Whether to show the search field.
  final bool enableSearch;

  /// Whether an item with `value: null` can be selected.
  final bool canUnselect;

  /// Optional custom filter function; if null, uses [LayrzSelectItem.matches].
  final bool Function(String query, LayrzSelectItem<T> item)? filter;

  /// Text shown when search finds no matching items.
  final String? emptyListText;

  /// Callback when an item is selected or cleared.
  final void Function(LayrzSelectItem<T>?) onItemSelected;

  /// Optional menu controller to close the panel after selection.
  ///
  /// When provided, the surface will call [controller.close()] after an item is selected.
  /// This is used when the surface is displayed in an anchored panel on desktop.
  final MenuController? panelController;

  /// Creates a new [LayrzSelectInputSurface].
  const LayrzSelectInputSurface({
    super.key,
    required this.items,
    this.selectedItem,
    required this.enableSearch,
    required this.canUnselect,
    this.filter,
    this.emptyListText,
    required this.onItemSelected,
    this.panelController,
  });

  @override
  State<LayrzSelectInputSurface<T>> createState() => _LayrzSelectInputSurfaceState<T>();
}

class _LayrzSelectInputSurfaceState<T> extends State<LayrzSelectInputSurface<T>> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late FocusNode _listFocusNode;
  int _highlightedIndex = -1;
  List<LayrzSelectItem<T>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _listFocusNode = FocusNode();
    _updateFilteredItems();
    _setInitialHighlight();

    // Focus search field or list on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        if (widget.enableSearch) {
          _searchFocusNode.requestFocus();
        } else {
          _listFocusNode.requestFocus();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _listFocusNode.dispose();
    super.dispose();
  }

  /// Updates the filtered items list based on the search query.
  void _updateFilteredItems() {
    final query = _searchController.text;
    final filter = widget.filter;

    if (query.isEmpty) {
      _filteredItems = widget.items;
    } else {
      _filteredItems = widget.items.where((item) {
        if (filter != null) {
          return filter(query, item);
        }
        return item.matches(query);
      }).toList();
    }

    // Reset highlight when filter changes
    _highlightedIndex = -1;
  }

  /// Sets the initial highlight to the selected item (or none).
  void _setInitialHighlight() {
    if (widget.selectedItem != null) {
      _highlightedIndex = _filteredItems.indexOf(widget.selectedItem!);
    } else {
      _highlightedIndex = -1;
    }
  }

  /// Handles keyboard events (arrow keys, Enter, Escape).
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < _filteredItems.length - 1) {
          _highlightedIndex++;
        } else if (_filteredItems.isNotEmpty) {
          _highlightedIndex = 0;
        }
      });
    } else if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex > 0) {
          _highlightedIndex--;
        } else if (_filteredItems.isNotEmpty) {
          _highlightedIndex = _filteredItems.length - 1;
        }
      });
    } else if (key == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _filteredItems.length) {
        widget.onItemSelected(_filteredItems[_highlightedIndex]);
        widget.panelController?.close();
      }
    } else if (key == LogicalKeyboardKey.escape) {
      if (widget.panelController != null) {
        widget.panelController!.close();
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LayrzUiL10n.of(context);
    final tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search field (if enabled)
        if (widget.enableSearch) ...[
          Padding(
            padding: tokens.spacing.pd2,
            child: LayrzTextInput(
              hintText: l10n.selectSearch,
              controller: _searchController,
              focusNode: _searchFocusNode,
              suffixIcon: _searchController.text.isNotEmpty ? MdiIcons.close : null,
              onSuffixTap: _searchController.text.isNotEmpty
                  ? () {
                      _searchController.clear();
                      _updateFilteredItems();
                      setState(() {});
                    }
                  : null,
              onChanged: (_) {
                _updateFilteredItems();
                setState(() {});
              },
            ),
          ),
          Container(
            height: 1,
            color: tokens.colors.divider,
          ),
        ],

        // Items list with keyboard support
        if (_filteredItems.isEmpty)
          Padding(
            padding: tokens.spacing.pd3,
            child: Text(
              widget.emptyListText ?? l10n.selectEmpty,
              style: tokens.typography.body.copyWith(
                color: tokens.colors.fg3,
              ),
            ),
          )
        else
          LimitedBox(
            maxHeight: 300,
            child: KeyboardListener(
              focusNode: _listFocusNode,
              onKeyEvent: _handleKeyEvent,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_filteredItems.length, (index) {
                    final item = _filteredItems[index];
                    final isHighlighted = _highlightedIndex == index;
                    final isSelected = item.value == widget.selectedItem?.value;

                    return _SelectItemRow(
                      key: ValueKey(item.value),
                      item: item,
                      isHighlighted: isHighlighted,
                      isSelected: isSelected,
                      onTap: () {
                        widget.onItemSelected(item);
                        widget.panelController?.close();
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A single item row in the select input surface.
///
/// Displays the item with optional custom rendering and selection/highlight states.
class _SelectItemRow<T> extends StatelessWidget {
  final LayrzSelectItem<T> item;
  final bool isHighlighted;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectItemRow({
    super.key,
    required this.item,
    required this.isHighlighted,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Determine background color: selected or highlighted
    final backgroundColor = isSelected
        ? tokens.colors.primary.withValues(alpha: 0.1)
        : isHighlighted
        ? tokens.colors.fg3.withValues(alpha: 0.1)
        : Color.fromARGB(0, 0, 0, 0);

    // Determine text color
    final textColor = isSelected ? tokens.colors.primary : tokens.colors.fg1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: backgroundColor,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.sp2,
          vertical: tokens.spacing.sp1,
        ),
        child: Row(
          children: [
            // Item content (custom or default)
            Expanded(
              child:
                  item.child ??
                  Text(
                    item.labelText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.typography.body.copyWith(
                      color: textColor,
                    ),
                  ),
            ),

            // Selection indicator
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(left: tokens.spacing.sp2),
                child: Icon(
                  MdiIcons.check,
                  size: 20,
                  color: tokens.colors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
