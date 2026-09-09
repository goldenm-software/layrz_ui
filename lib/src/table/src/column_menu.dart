import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/menus/menus.dart';
import 'package:layrz_ui/src/table/src/column.dart';
import 'package:layrz_ui/src/table/src/controller.dart';

/// A permanent, visible trigger that opens a column-management menu for a
/// `LayrzTable<T>`.
///
/// [LayrzColumnMenu] renders a single icon-only [LayrzButton]
/// (`MdiIcons.viewColumnOutline`) that opens a [LayrzDropdownMenu] checklist
/// of every column known to [controller]. Tapping a column's row toggles its
/// visibility via [LayrzTableController.toggleColumn]; the checked/unchecked
/// state is drawn directly from [LayrzTableController.hiddenColumns] on every
/// build, so the menu never keeps a shadow copy of column state and always
/// reflects the controller's true current state, including after it is
/// reopened.
///
/// **`minVisibleColumns` boundary:** the toggle for a currently-visible
/// column whose hiding would drop the number of visible columns below
/// [LayrzTableController.minVisibleColumns] is rendered **disabled** — the
/// user sees the row but cannot act on it. [LayrzTableController.toggleColumn]
/// enforces the same floor as a backstop, so this is defense in depth, not
/// the only guard.
///
/// **Compact reorder:** on [context.isCompact], each *visible* column also
/// gets "Move up" / "Move down" entries that drive
/// [LayrzTableController.reorderColumn] with the adjacent visible index. This
/// is the **only** reorder path on compact — the wide viewport's on-header
/// drag handle is not rendered there — and it is also the
/// keyboard-accessible reorder route on every viewport, since
/// [LayrzDropdownEntry] rows are focusable and activatable without a pointer.
/// A column at either end of the visible order has its inapplicable
/// direction disabled (there is nothing to move it past). Hidden columns get
/// no reorder entries: they have no position among the visible columns to
/// move.
///
/// This widget only ever reads from [controller] and calls its mutators — it
/// holds no state of its own beyond what [LayrzDropdownMenu] needs to open
/// and close its panel.
class LayrzColumnMenu<T> extends StatelessWidget {
  /// The full set of columns the owning `LayrzTable<T>` was given, in the
  /// order the caller declared them.
  ///
  /// Used only to resolve each [LayrzTableController.columnOrder] key back to
  /// its [LayrzColumn.headerText] for display — the controller is still the
  /// single source of truth for order and visibility.
  final List<LayrzColumn<T>> columns;

  /// The controller whose column order and visibility this menu reads from
  /// and mutates.
  ///
  /// The menu rebuilds whenever [controller] notifies its listeners, so it
  /// always reflects the controller's current state with no local caching.
  final LayrzTableController<T> controller;

  /// Optional hint text shown as a tooltip on the trigger icon.
  ///
  /// Defaults to `'Columns'` when omitted. Also doubles as the trigger's
  /// accessible label, since [LayrzButton] surfaces [labelText]-derived
  /// semantics regardless of its icon-only Fab layout.
  final String triggerLabelText;

  /// Creates a [LayrzColumnMenu].
  ///
  /// [columns] and [controller] are required. [triggerLabelText] is optional
  /// and defaults to `'Columns'`.
  const LayrzColumnMenu({
    required this.columns,
    required this.controller,
    this.triggerLabelText = 'Columns',
    super.key,
  });

  /// Looks up the display header text for [key] among [columns].
  ///
  /// Falls back to the key's own `toString()` in the (should-not-happen)
  /// case where [controller] holds a key no longer present in [columns] —
  /// membership sync (`LayrzTableController.syncColumns`) is expected to
  /// keep these in step, but this keeps the menu from crashing if a caller
  /// renders it against a controller mid-resync.
  String _headerTextFor(Key key) {
    for (final column in columns) {
      if (column.key == key) return column.headerText;
    }
    return key.toString();
  }

  /// Builds the checklist entry for [key] that toggles its visibility.
  ///
  /// Disabled when [key] is currently visible and hiding it would drop the
  /// number of visible columns below [LayrzTableController.minVisibleColumns].
  LayrzDropdownEntry _visibilityEntry(Key key) {
    final isVisible = !controller.hiddenColumns.contains(key);
    final wouldBreachFloor = isVisible && controller.visibleColumnKeys.length <= controller.minVisibleColumns;

    return LayrzDropdownEntry(
      key: ValueKey('layrz-column-menu-visibility-$key'),
      labelText: _headerTextFor(key),
      icon: isVisible ? MdiIcons.checkboxMarked : MdiIcons.checkboxBlankOutline,
      enabled: !wouldBreachFloor,
      onTap: () => controller.toggleColumn(key),
    );
  }

  /// Builds the "Move up" / "Move down" entry pair for the visible column
  /// [key], sitting at [visibleIndex] among [visibleKeys].
  ///
  /// Each direction is disabled when [key] is already at that end of the
  /// visible order. Reordering targets the adjacent visible index, matching
  /// what a one-step up/down control should do.
  List<LayrzDropdownEntry> _reorderEntries({
    required Key key,
    required int visibleIndex,
    required List<Key> visibleKeys,
  }) {
    final headerText = _headerTextFor(key);
    final canMoveUp = visibleIndex > 0;
    final canMoveDown = visibleIndex < visibleKeys.length - 1;

    return [
      LayrzDropdownEntry(
        key: ValueKey('layrz-column-menu-move-up-$key'),
        labelText: 'Move $headerText up',
        icon: MdiIcons.arrowUpBold,
        enabled: canMoveUp,
        onTap: () => controller.reorderColumn(key, visibleIndex - 1),
      ),
      LayrzDropdownEntry(
        key: ValueKey('layrz-column-menu-move-down-$key'),
        labelText: 'Move $headerText down',
        icon: MdiIcons.arrowDownBold,
        enabled: canMoveDown,
        onTap: () => controller.reorderColumn(key, visibleIndex + 1),
      ),
    ];
  }

  /// Builds the full, ordered list of menu items for the current controller
  /// state and viewport.
  ///
  /// Iterates [LayrzTableController.columnOrder] (which includes hidden
  /// columns) to build one visibility checklist entry per column, and — only
  /// when [isCompact] is `true` — appends a "Move up"/"Move down" pair for
  /// every currently-visible column, keyed by that column's position among
  /// [LayrzTableController.visibleColumnKeys].
  List<LayrzDropdownItem> _buildItems(bool isCompact) {
    final order = controller.columnOrder;
    final items = <LayrzDropdownItem>[for (final key in order) _visibilityEntry(key)];

    if (isCompact) {
      final visibleKeys = order.where((key) => !controller.hiddenColumns.contains(key)).toList(growable: false);
      if (visibleKeys.isNotEmpty) {
        items.add(const LayrzDropdownLabel(labelText: 'Reorder columns'));
        for (var i = 0; i < visibleKeys.length; i++) {
          items.addAll(_reorderEntries(key: visibleKeys[i], visibleIndex: i, visibleKeys: visibleKeys));
        }
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return LayrzDropdownMenu(
          items: _buildItems(context.isCompact),
          builder: (context, menuController) {
            return LayrzButton(
              key: const ValueKey('layrz-column-menu-trigger'),
              labelText: triggerLabelText,
              icon: MdiIcons.viewColumnOutline,
              style: LayrzButtonStyle.textFab,
              onTap: menuController.isOpen ? menuController.close : menuController.open,
            );
          },
        );
      },
    );
  }
}
