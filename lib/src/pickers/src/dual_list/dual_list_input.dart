import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_footer_slot.dart';
import 'package:layrz_ui/src/pickers/src/multi_select/multi_select_input.dart';

import 'dual_list_panel.dart';

/// A Material-free, desktop-only two-panel transfer field in the layrz_ui
/// design system, resolving to a `List<T>` of selected values.
///
/// **DESKTOP-ONLY BY DESIGN DECISION (team vote, DESIGN-43).**
/// [LayrzDualListInput] renders its two-panel "Available" / "Selected"
/// surface only when `context.isCompact == false` (`>= 960px`). Below that,
/// it delegates entirely to [LayrzMultiSelectInput] — same [items], [value],
/// and [onChanged] — which itself carries the "All (count)" / "Selected
/// (count)" tabs (DESIGN-43) so a mobile user can still see what they've
/// selected without a side-by-side layout that does not fit a narrow
/// viewport. There is no compact rendering of the two-panel surface itself;
/// [enableAvailableSearch]/[enableSelectedSearch] and
/// [availableListName]/[selectedListName] only affect the desktop panels —
/// the compact path's search and labels come from [LayrzMultiSelectInput]'s
/// own contract instead.
///
/// **Transfer mechanic (v1): tap-to-move + move-all, no drag/reorder.**
/// Tapping a row in either panel moves that item to the other panel
/// immediately (no staging, no Save — unlike [LayrzMultiSelectInput]'s
/// staged-with-Save model, this field commits every transfer as it happens,
/// mirroring `ThemedDualListInput`'s always-live semantics). Two move-all
/// affordances between the panels move every currently-visible (i.e.
/// search-filtered) item across in one action. **Drag-and-drop transfer and
/// within-"Selected" reordering are explicitly out of this v1** — [value]'s
/// order always reflects [items]' own order (see [_orderedSelected]), never
/// a caller- or user-chosen order. A future revision may add either.
///
/// **Item type.** Items are typed on the shared [LayrzSelectItem] (from
/// `lib/src/inputs/src/select/select_item.dart`) — the same type
/// [LayrzSelectInput] and [LayrzMultiSelectInput] use, not a fork with extra
/// fields. Each panel narrows the same [items] list by whether its value is
/// a member of [value] — "Available" shows items **not** in [value],
/// "Selected" shows items that **are**.
class LayrzDualListInput<T> extends StatefulWidget {
  /// The list of items to choose from.
  ///
  /// Each item combines a typed value, a required presentation widget
  /// ([LayrzSelectItem.child]), and search metadata
  /// ([LayrzSelectItem.searchableStrings]) — shared verbatim with
  /// [LayrzSelectInput] and [LayrzMultiSelectInput].
  final List<LayrzSelectItem<T>> items;

  /// The currently selected values, in the order they should appear in the
  /// "Selected" panel.
  ///
  /// Defaults to an empty list. An item is considered selected exactly when
  /// its value is a member of this list (equality-based, via [T]'s own
  /// `==`/`hashCode`) — this widget does not accept a custom
  /// `compareFunction` in v1.
  final List<T> value;

  /// Callback fired every time a transfer changes the selection — a single
  /// row tap, or a move-all action — with the full, newly-ordered list of
  /// selected values (see the class doc's transfer-mechanic section).
  ///
  /// Unlike [LayrzMultiSelectInput], there is no staged draft and no
  /// Cancel/Save: every tap commits immediately.
  final ValueChanged<List<T>>? onChanged;

  /// The label text displayed above the field.
  final String? labelText;

  /// Hint text. Currently unused by the desktop two-panel surface (which has
  /// no closed/idle state to show a hint in) but forwarded to the compact
  /// [LayrzMultiSelectInput] delegate, whose anchor field does render it.
  final String? hintText;

  /// Whether the field is marked as required.
  final bool isRequired;

  /// Whether the field is disabled.
  ///
  /// A disabled field disables both panels' rows (no tap moves an item) and
  /// the move-all affordances, and delegates `disabled: true` to the
  /// compact [LayrzMultiSelectInput] path as well.
  final bool disabled;

  /// The list of error messages to display below the field.
  final List<String> errors;

  /// Whether to hide the error message block.
  final bool hideDetails;

  /// The title text for the help affordance tooltip.
  ///
  /// **Desktop v1 limitation:** the always-visible two-panel surface has no
  /// anchor field of its own to attach a help tooltip trigger to (unlike
  /// every modal-opening picker under `pickers/`), so this is currently
  /// forwarded only to the compact [LayrzMultiSelectInput] delegate, whose
  /// anchor chrome does render it. On desktop this parameter is accepted but
  /// has no visible effect.
  final String? helpTitleText;

  /// The content text for the help affordance tooltip.
  ///
  /// See [helpTitleText]'s doc for the same desktop v1 limitation.
  final String? helpContentText;

  /// Whether the desktop "Available" panel renders its own search field.
  /// Defaults to `true`.
  final bool enableAvailableSearch;

  /// Whether the desktop "Selected" panel renders its own search field.
  /// Defaults to `true`.
  final bool enableSelectedSearch;

  /// The expected height of each row in both desktop panels, and forwarded
  /// as-is to the compact [LayrzMultiSelectInput] delegate's own
  /// `itemExtent`. Required, mirroring [LayrzMultiSelectInput.itemExtent].
  final double itemExtent;

  /// Text shown in a panel when it has no items to display (either because
  /// its side of [value] is empty, or a search query matched nothing).
  ///
  /// If null, defaults to localized text from [LayrzUiL10n.selectEmpty].
  final String? emptyListText;

  /// The label for the left ("Available") panel.
  ///
  /// **Required (BREAKING).** Every dual-list field must name both of its
  /// panels explicitly — there is no localized fallback, so callers can no
  /// longer omit it and get [LayrzUiL10n.dualListAvailableListName] for
  /// free.
  final String availableListName;

  /// The label for the right ("Selected") panel.
  ///
  /// **Required (BREAKING).** Every dual-list field must name both of its
  /// panels explicitly — there is no localized fallback, so callers can no
  /// longer omit it and get [LayrzUiL10n.dualListSelectedListName] for
  /// free.
  final String selectedListName;

  /// Creates a new [LayrzDualListInput].
  const LayrzDualListInput({
    super.key,
    required this.items,
    this.value = const [],
    this.onChanged,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.disabled = false,
    this.errors = const [],
    this.hideDetails = false,
    this.helpTitleText,
    this.helpContentText,
    this.enableAvailableSearch = true,
    this.enableSelectedSearch = true,
    required this.itemExtent,
    this.emptyListText,
    required this.availableListName,
    required this.selectedListName,
  }) : assert(
         labelText != null || hintText != null,
         'At least one of labelText or hintText must be non-null.',
       );

  @override
  State<LayrzDualListInput<T>> createState() => _LayrzDualListInputState<T>();
}

class _LayrzDualListInputState<T> extends State<LayrzDualListInput<T>> {
  /// The values currently selected, independent of [LayrzDualListInput.value]
  /// once a transfer has committed locally — mirrors
  /// [LayrzMultiSelectInput]'s identical self-display convention, so the
  /// panels update the instant a row is tapped without waiting on the
  /// caller to feed [LayrzDualListInput.value] back on the next build.
  late List<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.of(widget.value);
  }

  @override
  void didUpdateWidget(LayrzDualListInput<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(widget.value, oldWidget.value)) {
      _selected = List.of(widget.value);
    }
  }

  bool _listEquals(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Recomputes [_selected]'s displayed order from [LayrzDualListInput.items]
  /// so both panels and the committed [LayrzDualListInput.onChanged] value
  /// always list items in the same order [items] itself declares them —
  /// never tap/transfer order. Mirrors
  /// [LayrzMultiSelectInputSurfaceState.save]'s identical ordering
  /// convention.
  List<T> _orderedSelected(Set<T> selectedSet) {
    return [
      for (final item in widget.items)
        if (item.value != null && selectedSet.contains(item.value as T)) item.value as T,
    ];
  }

  /// Moves [value] from "Available" to "Selected" (or does nothing if it is
  /// already selected), then commits immediately.
  void _selectOne(T value) {
    final set = _selected.toSet()..add(value);
    _commit(_orderedSelected(set));
  }

  /// Moves [value] from "Selected" back to "Available", then commits
  /// immediately.
  void _unselectOne(T value) {
    final set = _selected.toSet()..remove(value);
    _commit(_orderedSelected(set));
  }

  /// Moves every currently-visible "Available" item to "Selected" in one
  /// action. [visibleValues] is whatever the Available panel's own
  /// search-filtered list currently shows — the move-all affordance moves
  /// only what the user can currently see, mirroring
  /// `ThemedDualListInput`'s documented "all-or-nothing buttons... transfer
  /// all currently visible (filtered) items" behavior.
  void _selectAll(List<T> visibleValues) {
    final set = _selected.toSet()..addAll(visibleValues);
    _commit(_orderedSelected(set));
  }

  /// Moves every currently-visible "Selected" item back to "Available" in
  /// one action, mirroring [_selectAll].
  void _unselectAll(List<T> visibleValues) {
    final set = _selected.toSet()..removeAll(visibleValues);
    _commit(_orderedSelected(set));
  }

  /// Updates [_selected] and notifies [LayrzDualListInput.onChanged] with
  /// the new ordered list. Called by every transfer path — there is no
  /// staged draft to commit separately (see the class doc).
  void _commit(List<T> values) {
    setState(() => _selected = values);
    widget.onChanged?.call(values);
  }

  @override
  Widget build(BuildContext context) {
    if (context.isCompact) {
      return LayrzMultiSelectInput<T>(
        items: widget.items,
        value: _selected,
        onChanged: (values) => _commit(values),
        labelText: widget.labelText,
        hintText: widget.hintText,
        isRequired: widget.isRequired,
        disabled: widget.disabled,
        errors: widget.errors,
        hideDetails: widget.hideDetails,
        helpTitleText: widget.helpTitleText,
        helpContentText: widget.helpContentText,
        emptyListText: widget.emptyListText,
        itemExtent: widget.itemExtent,
      );
    }

    return _DesktopDualListSurface<T>(
      items: widget.items,
      selected: _selected,
      labelText: widget.labelText,
      isRequired: widget.isRequired,
      disabled: widget.disabled,
      errors: widget.errors,
      hideDetails: widget.hideDetails,
      enableAvailableSearch: widget.enableAvailableSearch,
      enableSelectedSearch: widget.enableSelectedSearch,
      itemExtent: widget.itemExtent,
      emptyListText: widget.emptyListText,
      availableListName: widget.availableListName,
      selectedListName: widget.selectedListName,
      onSelectOne: _selectOne,
      onUnselectOne: _unselectOne,
      onSelectAll: _selectAll,
      onUnselectAll: _unselectAll,
    );
  }
}

/// The always-visible desktop two-panel surface — no anchor, no modal, no
/// closed/idle state. Unlike every other `pickers/` widget, there is nothing
/// to open: this **is** the field, rendered inline wherever
/// [LayrzDualListInput] is placed, exactly like `ThemedDualListInput`'s own
/// always-visible layout.
///
/// **Owns both panels' search queries.** Each [LayrzDualListPanel] renders
/// its own search field but no longer holds its query as private state — this
/// widget does, one string per panel (see
/// [_DesktopDualListSurfaceState._availableQuery]/
/// [_DesktopDualListSurfaceState._selectedQuery]), so the move-all buttons
/// below can transfer exactly the currently search-filtered set rather than
/// each panel's full unfiltered partition.
class _DesktopDualListSurface<T> extends StatefulWidget {
  /// The full item list, forwarded from [LayrzDualListInput.items].
  final List<LayrzSelectItem<T>> items;

  /// The currently selected values, forwarded from the parent's own
  /// self-display state.
  final List<T> selected;

  /// The label text displayed above both panels.
  final String? labelText;

  /// Whether the field is marked as required.
  final bool isRequired;

  /// Whether the field (both panels and the move-all buttons) is disabled.
  final bool disabled;

  /// Error messages displayed below the two panels.
  final List<String> errors;

  /// Whether to hide the error message block.
  final bool hideDetails;

  /// Whether the "Available" panel renders its own search field.
  final bool enableAvailableSearch;

  /// Whether the "Selected" panel renders its own search field.
  final bool enableSelectedSearch;

  /// The expected height of each row in both panels.
  final double itemExtent;

  /// Text shown in a panel with nothing to display.
  final String? emptyListText;

  /// The "Available" panel's label. Required (BREAKING) — see
  /// [LayrzDualListInput.availableListName].
  final String availableListName;

  /// The "Selected" panel's label. Required (BREAKING) — see
  /// [LayrzDualListInput.selectedListName].
  final String selectedListName;

  /// Called with a single value tapped in the "Available" panel.
  final ValueChanged<T> onSelectOne;

  /// Called with a single value tapped in the "Selected" panel.
  final ValueChanged<T> onUnselectOne;

  /// Called with every value the "Available" panel currently shows when
  /// "move all to selected" is pressed.
  final ValueChanged<List<T>> onSelectAll;

  /// Called with every value the "Selected" panel currently shows when
  /// "move all to available" is pressed.
  final ValueChanged<List<T>> onUnselectAll;

  /// Creates a new [_DesktopDualListSurface].
  const _DesktopDualListSurface({
    required this.items,
    required this.selected,
    required this.labelText,
    required this.isRequired,
    required this.disabled,
    required this.errors,
    required this.hideDetails,
    required this.enableAvailableSearch,
    required this.enableSelectedSearch,
    required this.itemExtent,
    required this.emptyListText,
    required this.availableListName,
    required this.selectedListName,
    required this.onSelectOne,
    required this.onUnselectOne,
    required this.onSelectAll,
    required this.onUnselectAll,
  });

  /// The fixed height of the two-panel surface, in logical pixels. A dual
  /// list has no natural intrinsic height (its content is two independently
  /// scrolling lists) — this mirrors `ThemedDualListInput`'s own fixed
  /// `height` default (400) as a hardcoded constant rather than a
  /// caller-configurable parameter, keeping v1's parameter surface small;
  /// revisit if a caller genuinely needs a taller/shorter surface.
  static const double _surfaceHeight = 400;

  @override
  State<_DesktopDualListSurface<T>> createState() => _DesktopDualListSurfaceState<T>();
}

class _DesktopDualListSurfaceState<T> extends State<_DesktopDualListSurface<T>> {
  /// The "Available" panel's current search query, lifted up from
  /// [LayrzDualListPanel] so [_visibleAvailable] (and therefore the
  /// move-to-selected button) can be computed here. Empty means unfiltered.
  String _availableQuery = '';

  /// The "Selected" panel's current search query, mirroring [_availableQuery].
  String _selectedQuery = '';

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final selectedSet = widget.selected.toSet();

    final availableItems = [
      for (final item in widget.items)
        if (item.value == null || !selectedSet.contains(item.value as T)) item,
    ];
    final selectedItems = [
      for (final item in widget.items)
        if (item.value != null && selectedSet.contains(item.value as T)) item,
    ];

    // The same search-filtered set each panel is currently displaying (see
    // [LayrzDualListPanel._visibleItems]) — computed here too so the move-all
    // buttons below can transfer exactly what the user can see, never a
    // panel's full unfiltered partition.
    final visibleAvailable = _availableQuery.isEmpty
        ? availableItems
        : availableItems.where((item) => item.matches(_availableQuery)).toList();
    final visibleSelected = _selectedQuery.isEmpty
        ? selectedItems
        : selectedItems.where((item) => item.matches(_selectedQuery)).toList();

    final emptyText = widget.emptyListText ?? l10n.selectEmpty;

    final surface = SizedBox(
      height: _DesktopDualListSurface._surfaceHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayrzDualListPanel<T>(
              title: widget.availableListName,
              items: availableItems,
              onItemTap: widget.onSelectOne,
              enableSearch: widget.enableAvailableSearch,
              emptyText: emptyText,
              itemExtent: widget.itemExtent,
              disabled: widget.disabled,
              query: _availableQuery,
              onQueryChanged: (query) => setState(() => _availableQuery = query),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LayrzButton(
                  labelText: l10n.dualListToggleToSelected,
                  icon: MdiIcons.chevronRight,
                  style: (widget.disabled || visibleAvailable.isEmpty)
                      ? LayrzButtonStyle.textFab
                      : LayrzButtonStyle.filledFab,
                  isDisabled: widget.disabled || visibleAvailable.isEmpty,
                  onTap: widget.disabled || visibleAvailable.isEmpty
                      ? null
                      : () => widget.onSelectAll([
                          for (final item in visibleAvailable)
                            if (item.value != null) item.value as T,
                        ]),
                ),
                SizedBox(height: tokens.spacing.sp2),
                LayrzButton(
                  labelText: l10n.dualListToggleToAvailable,
                  icon: MdiIcons.chevronLeft,
                  style: (widget.disabled || visibleSelected.isEmpty)
                      ? LayrzButtonStyle.textFab
                      : LayrzButtonStyle.filledFab,
                  isDisabled: widget.disabled || visibleSelected.isEmpty,
                  onTap: widget.disabled || visibleSelected.isEmpty
                      ? null
                      : () => widget.onUnselectAll([
                          for (final item in visibleSelected)
                            if (item.value != null) item.value as T,
                        ]),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayrzDualListPanel<T>(
              title: widget.selectedListName,
              items: selectedItems,
              onItemTap: widget.onUnselectOne,
              enableSearch: widget.enableSelectedSearch,
              emptyText: emptyText,
              itemExtent: widget.itemExtent,
              disabled: widget.disabled,
              query: _selectedQuery,
              onQueryChanged: (query) => setState(() => _selectedQuery = query),
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spacing.sp2),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: widget.labelText,
                    style: tokens.typography.label.copyWith(color: tokens.colors.fg2),
                  ),
                  if (widget.isRequired)
                    TextSpan(
                      text: '*',
                      style: tokens.typography.label.copyWith(color: tokens.colors.danger),
                    ),
                ],
              ),
            ),
          ),
        surface,
        LayrzInputFooterSlot(errors: widget.errors, hideDetails: widget.hideDetails),
      ],
    );
  }
}
