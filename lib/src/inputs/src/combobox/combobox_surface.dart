import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import '../shared/editable_field.dart';
import '../shared/input_chrome.dart';
import '../shared/input_slot.dart';

/// The desktop panel's content for [LayrzComboBoxInput].
///
/// **Q3 -- the panel's first row IS the live input (structural, not visual).**
/// Unlike [LayrzSelectInputSurface] (whose field is read-only, so the surface
/// owns a second, independent search field), ComboBox's field *is* the input --
/// so this widget renders [fieldRow] literally as its first child, built by
/// [LayrzComboBoxInput] from the *same* `TextEditingController`/`FocusNode`
/// instances that back the closed field. Passing the same instances (rather
/// than copying text across the open transition) is what makes text, caret and
/// focus continuity structural instead of best-effort -- there is only ever one
/// controller and one focus node, whichever host currently renders them.
///
/// **Border/background/shadow ownership (S2).** This widget paints none of its
/// own decoration. Before this unit, [LayrzComboBoxInput] built a hand-rolled
/// `RawMenuAnchor` overlay and this class (formerly `DesktopOverlay`) drew its
/// own `DecoratedBox` (background, radius, shadow) plus its own `ClipRRect`.
/// Both are gone: [LayrzComboBoxInput] now uses `LayrzAnchoredPanel`, which
/// paints the panel's background, radius, shadow, and optional border around
/// its own capped scroll viewport (see `LayrzAnchoredPanelBorder`'s doc
/// comment for why that scoping matters) -- this widget is purely the
/// undecorated content passed as the panel's `child:`.
///
/// This is a private implementation detail; consumers use [LayrzComboBoxInput]
/// instead.
class LayrzComboBoxPanelContent extends StatelessWidget {
  /// The panel's first row: the live, editable field.
  ///
  /// Built by [LayrzComboBoxInput] from the same controller/focus node that
  /// back the closed field -- see the class doc.
  final Widget fieldRow;

  /// The filtered list of options to display below [fieldRow].
  final List<String> options;

  /// Index of the currently highlighted option in [options], or -1 if none.
  final int highlightedIndex;

  /// Callback when an option is selected.
  final ValueChanged<String> onSelected;

  /// Text to display when [options] is empty.
  final String emptyText;

  /// Creates a new [LayrzComboBoxPanelContent].
  const LayrzComboBoxPanelContent({
    super.key,
    required this.fieldRow,
    required this.options,
    required this.highlightedIndex,
    required this.onSelected,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final Widget listOrEmptyState;
    if (options.isEmpty) {
      listOrEmptyState = Padding(
        padding: EdgeInsets.all(tokens.spacing.sp2),
        child: Text(
          emptyText,
          style: tokens.typography.label.copyWith(
            color: tokens.colors.fg3,
          ),
        ),
      );
    } else {
      // Mirrors `LayrzSelectInputSurface`'s own reasoning verbatim: this
      // `Column` is free to size to its full, uncapped content height. The
      // one and only height cap is applied by the caller
      // (`LayrzAnchoredPanel.maxHeight`, via its `SingleChildScrollView`),
      // never by this widget -- a second, disagreeing cap here is exactly
      // DESIGN-40's original root cause.
      listOrEmptyState = Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          options.length,
          (index) => OptionItem(
            option: options[index],
            isHighlighted: index == highlightedIndex,
            onTap: () => onSelected(options[index]),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        fieldRow,
        Container(height: 1, color: tokens.colors.divider),
        listOrEmptyState,
      ],
    );
  }
}

/// A single option item in the combobox overlay.
class OptionItem extends StatelessWidget {
  /// The option text.
  final String option;

  /// Whether this option is currently highlighted.
  final bool isHighlighted;

  /// Callback when the option is tapped.
  final VoidCallback onTap;

  /// Creates an option item.
  const OptionItem({
    super.key,
    required this.option,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isHighlighted ? tokens.colors.sf2 : tokens.colors.sf1,
        padding: EdgeInsets.symmetric(
          vertical: tokens.spacing.sp2,
          horizontal: tokens.spacing.sp3,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: tokens.typography.body.copyWith(
                  color: tokens.colors.fg1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Content widget for the bottom sheet on mobile.
///
/// **DESIGN-161.** Before this widget owned any state, it rendered nothing but a
/// bare option list -- no search field, no `Semantics`, no heading, no label of
/// any kind. That was a usability defect first (a combobox is reached for
/// *because* the list is too long to scroll comfortably; a mobile sheet with no
/// filter had lost the entire reason to use the widget) and an accessibility gap
/// second (the sheet's subtree carried no accessible name at all). This widget
/// now mirrors `LayrzSelectInputSurface`: it owns its own search text, filters
/// [options] against it live, and wraps itself in a [Semantics] node naming what
/// is being picked.
///
/// [options] is still the pool handed in at open time by
/// `LayrzComboBoxInput._openBottomSheet` -- already filtered once, against
/// whatever the closed field's own text was when the sheet opened (see that
/// method's doc comment). This widget's own search field filters that pool
/// *again*, live, as the user types inside the sheet -- the two filters compose
/// rather than conflict, exactly as typing in the closed field followed by
/// opening the sheet already did before this change.
///
/// Selection is communicated solely by popping the enclosing route with the
/// chosen option -- there is no `onSelected` callback here, because
/// `LayrzComboBoxInput._openBottomSheet` already commits the popped value
/// exactly once. An earlier version called both a callback *and* popped with the
/// same value, which committed the selection twice per tap; this widget
/// deliberately has only one way to report a choice, so that mistake cannot come
/// back.
///
/// The option list is built as a [SingleChildScrollView] wrapping a plain
/// [Column], never a [ListView]: [LayrzBottomSheet] is shown with
/// `scrollable: false` for this content (see
/// `LayrzComboBoxInput._openBottomSheet`), which hands this subtree the sheet's
/// own [ScrollController] via an ambient `PrimaryScrollController` instead of
/// nesting it inside another same-axis scrollable. A lazy-loading [ListView]
/// here would receive unbounded height from that same-axis nesting and assert; a
/// [Column] does not need laziness in the first place, since combobox option
/// counts are small.
class BottomSheetContent extends StatefulWidget {
  /// The pool of options to display and filter, as handed to the sheet at open
  /// time -- see the class doc for how this composes with this widget's own,
  /// live search filter.
  final List<String> options;

  /// Text to display when no options match.
  final String emptyText;

  /// The name of what is being picked, used as this sheet's accessible heading.
  ///
  /// Mirrors `LayrzComboBoxInput.labelText` -- passed through unchanged by
  /// `_openBottomSheet` so the sheet's subtree carries a name identifying what
  /// is being picked, even though the closed field that owns that label sits
  /// behind the modal barrier and is correctly invisible to a screen reader
  /// while the sheet is open. Rendered as a heading `Text` above the search
  /// field when non-null; when null, only the search field's own accessible
  /// name (distinct from this) names the sheet.
  final String? labelText;

  /// Creates bottom sheet content.
  const BottomSheetContent({
    super.key,
    required this.options,
    required this.emptyText,
    this.labelText,
  });

  @override
  State<BottomSheetContent> createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<BottomSheetContent> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  final Set<WidgetState> _searchStates = {};
  List<String> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _filteredOptions = widget.options;
  }

  @override
  void didUpdateWidget(BottomSheetContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options != oldWidget.options) {
      _updateFilteredOptions();
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Tracks focus on the search field, purely for its own visual state
  /// (hover/focus colors resolved by [LayrzInputChrome]).
  void _handleSearchFocusChanged() {
    setState(() {
      if (_searchFocusNode.hasFocus) {
        _searchStates.add(WidgetState.focused);
      } else {
        _searchStates.remove(WidgetState.focused);
      }
    });
  }

  /// Handles a genuine edit to the search field's text.
  void _handleSearchChanged(String text) {
    setState(_updateFilteredOptions);
  }

  /// Re-derives [_filteredOptions] from [widget.options] and the current
  /// search text -- case-insensitive, matching from the start of each option,
  /// mirroring `LayrzComboBoxInput._getFilteredOptions`'s own semantics.
  void _updateFilteredOptions() {
    final query = _searchController.text.toLowerCase();
    _filteredOptions = query.isEmpty
        ? widget.options
        : widget.options.where((option) => option.toLowerCase().startsWith(query)).toList();
  }

  /// Builds the search field row, shown above the option list.
  ///
  /// Deliberately borderless ([LayrzInputChrome.showBorder] false), mirroring
  /// `LayrzSelectInputSurface._buildSearchField` for the identical reason: the
  /// sheet itself already reads as one bordered surface, so a second, inner
  /// border here would read as two competing fields instead of a search row
  /// inside the sheet.
  ///
  /// The hint (`l10n.inputsSearchHint`) and the accessible name
  /// (`l10n.inputsSearchFieldLabel`) are both drawn from the shared `inputs`
  /// l10n namespace, not the combobox one -- deliberately distinct from
  /// [BottomSheetContent.labelText] (the picker's own name), so a screen reader
  /// never announces the same string for the sheet's heading and its search
  /// field.
  Widget _buildSearchField(BuildContext context) {
    final l10n = LayrzUiL10n.of(context);

    final fieldConfig = LayrzEditableFieldConfig(
      labelText: null,
      hintText: l10n.inputsSearchHint,
      disabled: false,
      readOnly: false,
      controller: _searchController,
      focusNode: _searchFocusNode,
      onChanged: _handleSearchChanged,
      onSubmit: null,
      onFocusChanged: null,
      onTap: null,
      keyboardType: TextInputType.text,
      textInputAction: null,
      inputFormatters: const [],
      maxLength: null,
      autofocus: false,
      textCapitalization: TextCapitalization.none,
      autofillHints: const [],
      obscureText: false,
      autocorrect: false,
      enableSuggestions: false,
      actions: null,
      minLines: 1,
      maxLines: 1,
      expands: false,
    );

    return Semantics(
      container: true,
      textField: true,
      label: l10n.inputsSearchFieldLabel,
      child: LayrzInputChrome(
        labelText: null,
        hintText: l10n.inputsSearchHint,
        isRequired: false,
        prefixSlot: resolvePrefixSlot(prefixIcon: MdiIcons.magnify, isDecorative: true),
        suffixSlot: resolveSuffixSlot(
          suffixIcon: _searchController.text.isNotEmpty ? MdiIcons.close : null,
          onSuffixTap: _searchController.text.isNotEmpty
              ? () {
                  _searchController.clear();
                  setState(_updateFilteredOptions);
                }
              : null,
          semanticLabel: _searchController.text.isNotEmpty ? l10n.inputsSearchClear : null,
        ),
        disabled: false,
        readOnly: false,
        errors: const [],
        hideDetails: true,
        states: _searchStates,
        controller: _searchController,
        showBorder: false,
        borderRadius: BorderRadius.zero,
        child: LayrzEditableField(config: fieldConfig),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final Widget listOrEmptyState;
    if (_filteredOptions.isEmpty) {
      listOrEmptyState = Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.sp4),
          child: Text(
            widget.emptyText,
            style: tokens.typography.label.copyWith(
              color: tokens.colors.fg3,
            ),
          ),
        ),
      );
    } else {
      listOrEmptyState = SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _filteredOptions.length,
            (index) => GestureDetector(
              onTap: () => Navigator.of(context, rootNavigator: true).pop(_filteredOptions[index]),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: tokens.spacing.sp3,
                  horizontal: tokens.spacing.sp4,
                ),
                child: Text(
                  _filteredOptions[index],
                  style: tokens.typography.body.copyWith(
                    color: tokens.colors.fg1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Names the sheet's subtree with what is being picked (DESIGN-161): before
    // this, nothing in the sheet was nameable at all, since the label lives on
    // the closed field underneath the modal barrier. `container: true` keeps
    // this node from merging its label into a descendant's (the search field
    // below has its own, deliberately distinct, name).
    return Semantics(
      container: true,
      label: widget.labelText,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.labelText != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spacing.sp4,
                tokens.spacing.sp2,
                tokens.spacing.sp4,
                0,
              ),
              child: ExcludeSemantics(
                child: Text(
                  widget.labelText!,
                  style: tokens.typography.label.copyWith(
                    color: tokens.colors.fg2,
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1),
            child: _buildSearchField(context),
          ),
          Container(height: 1, color: tokens.colors.divider),
          Flexible(child: listOrEmptyState),
        ],
      ),
    );
  }
}
