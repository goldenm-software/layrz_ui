import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

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

/// A single row inside [BottomSheetContent]'s option list -- either an
/// ordinary option, or the bold custom-value row (see
/// [BottomSheetContent]'s own class doc for that row's contract).
///
/// **Left-aligned and hoverable, via [LayrzTappable].** A prior version of
/// this list used a bare [GestureDetector] around a [Container] with no
/// [LayrzTappable] at all -- tappable, but with no hover feedback, the exact
/// defect the calendar cells had before they adopted [LayrzTappable] (raw
/// `GestureDetector`s never paint a hover tint on their own). Wrapping each
/// row in [LayrzTappable] here is the fix, mirroring that precedent. Left
/// alignment falls out of [Text]'s own default alignment once the row itself
/// is stretched to the list's full width -- see [BottomSheetContent]'s
/// `Column` for the `CrossAxisAlignment.stretch` that makes that hold; without
/// it, this row's [Container] would shrink-wrap to the text's own intrinsic
/// width and read as centered inside whatever wider box its ancestor gives
/// it, which is the defect the maintainer reported from a device screenshot.
class _ComboBoxSheetOptionRow extends StatelessWidget {
  /// The row's own text.
  final String text;

  /// Whether this row is currently highlighted by keyboard navigation.
  final bool isHighlighted;

  /// Whether this row renders in bold -- reserved for the custom-value row,
  /// see [BottomSheetContent]'s own class doc for why bold weight alone (no
  /// label, prefix, or icon) is the entire indicator.
  final bool isBold;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Creates a new [_ComboBoxSheetOptionRow].
  const _ComboBoxSheetOptionRow({
    required this.text,
    required this.isHighlighted,
    required this.onTap,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // w600 -- the design system's own semi-bold weight (LayrzTextTheme.headline
    // and .title both use it) -- rather than a generic FontWeight.bold (w700),
    // so the custom-value row's emphasis matches the weight the rest of the
    // system already treats as "bold" instead of introducing a second, heavier
    // weight nothing else uses. There is no dedicated bold-body typography
    // token to reach for instead (LayrzTextTheme only has one weight per
    // category -- see that class's own doc) -- copyWith is the class's own
    // documented escape hatch for exactly this kind of deviation.
    final style = tokens.typography.body.copyWith(
      color: tokens.colors.fg1,
      fontWeight: isBold ? FontWeight.w600 : null,
    );

    return LayrzTappable(
      onTap: onTap,
      // Finding 5 (maintainer review): "transparent transition to the hover
      // color causes a black blink". `Color(0x00000000)`'s RGB channels are
      // literally black -- only its alpha is zero -- so `AnimatedContainer`'s
      // `Color.lerp` from this idle color to `LayrzTappable`'s hover color
      // (`hoverColor` here, `tokens.colors.sf3`) ramps the black RGB
      // channels up alongside the alpha, producing a visibly darker
      // composited color at the transition's midpoint than at either
      // endpoint (measured: lightness dips from 1.0 at idle to ~0.73 mid-tween
      // before settling at sf3's own ~0.94, for this token set -- worse for a
      // darker or more saturated hover token). The fix is to start the tween
      // from the *same* colour the hover state ends at, just at zero alpha,
      // so every intermediate frame's RGB already matches the hover hue and
      // only the alpha ramps -- no dip, monotonic lightening throughout.
      // `hoverColor` is passed explicitly (even though it already matches
      // `LayrzTappable`'s own default) so the two colors can never drift
      // apart if that default ever changes.
      color: isHighlighted ? tokens.colors.sf2 : tokens.colors.sf3.withValues(alpha: 0),
      hoverColor: tokens.colors.sf3,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: tokens.spacing.sp3,
          horizontal: tokens.spacing.sp4,
        ),
        child: Text(text, style: style),
      ),
    );
  }
}

/// Content widget for the bottom sheet on mobile, and (DESIGN-98) the drawer
/// content on desktop -- see [LayrzComboBoxInput]'s class doc's Q3 section for
/// why both bands share this exact widget.
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
/// `LayrzComboBoxInput._openBottomSheet`/`_openDesktopDrawer` -- already
/// filtered once, against whatever the closed field's own text was when the
/// surface opened (see those methods' own doc comments). This widget's own
/// search field filters that pool *again*, live, as the user types inside the
/// surface -- the two filters compose rather than conflict, exactly as typing
/// in the closed field followed by opening the surface already did before this
/// change.
///
/// **The bold custom-value row (restored, indicated by weight not text).**
/// When the typed text does not exactly match any option (case-insensitively,
/// mirroring [LayrzComboBoxInput]'s own filter semantics), it renders as the
/// FIRST row of the list, in [FontWeight.w600] -- tappable, and committing
/// that exact typed text (the user's own casing, not a filtered option) the
/// same way tapping any other row commits. No "custom ..." label, prefix,
/// suffix, or icon: weight alone is the entire indicator, per the maintainer's
/// explicit ruling reversing an earlier one ("now we need it back, not
/// exactly with 'custom ...', well... using bold as indicator"). Omitted
/// entirely when the search text is empty, or when it exactly matches an
/// existing option (which would otherwise duplicate that option's own row).
///
/// Selection is communicated solely by popping the enclosing route with the
/// chosen option -- there is no `onSelected` callback here, because
/// `LayrzComboBoxInput._openBottomSheet`/`_openDesktopDrawer` already commits
/// the popped value exactly once. An earlier version called both a callback
/// *and* popped with the same value, which committed the selection twice per
/// tap; this widget deliberately has only one way to report a choice, so that
/// mistake cannot come back.
///
/// **Keyboard navigation (restored for DESIGN-98).** Arrow-down/up move a
/// highlight across the navigable rows (the custom-value row, when present,
/// counts as row 0; the filtered options follow it), and Enter commits
/// whichever row is currently highlighted. This existed in-place in the old
/// `LayrzAnchoredPanel`-hosted `LayrzComboBoxPanelContent` before DESIGN-98
/// retired that panel; it did not exist here at all before this pass, since a
/// bare `GestureDetector` list has no keyboard affordance of its own. The
/// custom-value row participates in this navigation and is highlighted first
/// by default whenever it is present -- a keyboard user who has just typed a
/// new value should be able to press Enter immediately without a Down press
/// first, since typing a value that matches nothing is itself already a
/// strong signal of intent to commit it, exactly as free-form entry into the
/// closed field already allows.
///
/// The option list is built as a [SingleChildScrollView] wrapping a plain
/// [Column], never a [ListView]: [LayrzBottomSheet] is shown with
/// `scrollable: false` for this content (see
/// `LayrzComboBoxInput._openBottomSheet`), which hands this subtree the sheet's
/// own [ScrollController] via an ambient `PrimaryScrollController` instead of
/// nesting it inside another same-axis scrollable. [LayrzEndDrawer] wraps its
/// own `builder` content in a bare [SingleChildScrollView] too, so the same
/// shape works unmodified on desktop. A lazy-loading [ListView] here would
/// receive unbounded height from that same-axis nesting and assert; a
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
  /// while the sheet is open. Always used for this widget's own [Semantics]
  /// name regardless of [showInlineTitle]; see that field's own doc for the
  /// separate question of whether it is also rendered as VISIBLE text here.
  final String? labelText;

  /// Whether this widget renders [labelText] as its own inline heading
  /// `Text`, above the search field.
  ///
  /// Defaults to `true`, preserving the mobile [LayrzBottomSheet] path
  /// exactly as it behaved before DESIGN-98's title work -- [LayrzBottomSheet]
  /// has no title slot of its own, so this inline heading is the only visible
  /// title mechanism available there. Pass `false` when hosting this widget
  /// in [LayrzEndDrawer], whose own `title` slot (DESIGN-98) renders the
  /// picker's name styled as a real title (headline, left-aligned) instead --
  /// `LayrzComboBoxInput._openDesktopDrawer` does exactly this, since
  /// rendering both would read as a duplicate title stacked over a caption.
  /// [labelText] itself is still passed through to this widget's own
  /// [Semantics] name either way.
  final bool showInlineTitle;

  /// Whether this surface's own search field filters [options] as the user
  /// types into it. Defaults to `true`.
  ///
  /// Mirrors [LayrzComboBoxInput.enableAutocomplete]'s documented contract
  /// ("if false, all options are always displayed") onto this surface's own
  /// search field -- the sole remaining filter mechanism as of the
  /// maintainer's Finding 6 fix (see [LayrzComboBoxInput._openDesktopDrawer]'s
  /// own doc for why the caller no longer pre-filters [options] before
  /// handing them to this widget). When `false`, typing into the search
  /// field still updates its own text (so the custom-value row and Enter-to-
  /// commit-typed-text keep working), but never narrows [options] itself.
  final bool enableAutocomplete;

  /// Creates bottom sheet content.
  const BottomSheetContent({
    super.key,
    required this.options,
    required this.emptyText,
    this.labelText,
    this.showInlineTitle = true,
    this.enableAutocomplete = true,
  });

  @override
  State<BottomSheetContent> createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<BottomSheetContent> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  /// Owns keyboard navigation regardless of whether [_searchFocusNode] itself
  /// currently holds focus.
  ///
  /// [_searchFocusNode] has `autofocus: false` (see [showInlineTitle]'s own
  /// doc for why the search field never autofocuses), so when neither band's
  /// host (the [Focus] node [LayrzEndDrawer]/[LayrzBottomSheet] each
  /// autofocus on open) requests focus onto anything inside this widget's own
  /// subtree, [_listFocusNode] is what actually holds focus -- without a real
  /// [FocusNode] of its own requesting focus on mount, the `Focus`
  /// wrapping this widget's whole subtree (see [build]) would never be part
  /// of the currently-focused chain at all, and arrow-key/Enter events would
  /// never reach [_handleKeyEvent]. Mirrors
  /// `LayrzSelectInputSurface._listFocusNode`'s identical pattern and
  /// `skipTraversal: true` (never a real Tab stop on its own -- only the
  /// search field, or this initial request, ever holds it).
  late FocusNode _listFocusNode;
  final Set<WidgetState> _searchStates = {};
  List<String> _filteredOptions = [];

  /// Highlight index across the navigable rows: the custom-value row (when
  /// present) is row 0, followed by [_filteredOptions] in order. `-1` means
  /// no row is highlighted. See [_navigableRowCount] and [_commitHighlighted].
  int _highlightedIndex = -1;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _listFocusNode = FocusNode();
    _filteredOptions = widget.options;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _listFocusNode.requestFocus();
    });
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
    _listFocusNode.dispose();
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
    setState(() {
      _updateFilteredOptions();
      // The custom-value row, when it (re)appears, is highlighted by
      // default -- see the class doc's "Keyboard navigation" section for why
      // (a keyboard user who just typed a new value should be able to press
      // Enter immediately). Any other text edit clears the highlight, mirroring
      // `LayrzComboBoxInput._handleTextChange`'s own identical reset.
      _highlightedIndex = _hasCustomValueRow ? 0 : -1;
    });
  }

  /// Re-derives [_filteredOptions] from [widget.options] and the current
  /// search text -- case-insensitive, matching from the start of each option,
  /// mirroring `LayrzComboBoxInput`'s own historical filter semantics.
  ///
  /// A no-op pass-through of [widget.options] when
  /// [BottomSheetContent.enableAutocomplete] is `false` -- see that field's
  /// own doc for why this is now the sole place that flag's contract is
  /// honored.
  void _updateFilteredOptions() {
    if (!widget.enableAutocomplete) {
      _filteredOptions = widget.options;
      return;
    }
    final query = _searchController.text.toLowerCase();
    _filteredOptions = query.isEmpty
        ? widget.options
        : widget.options.where((option) => option.toLowerCase().startsWith(query)).toList();
  }

  /// Whether the custom-value row should render -- see the class doc's "The
  /// bold custom-value row" section for the full contract: present whenever
  /// the search text is non-empty and does not exactly match (case-
  /// insensitively) any of [widget.options].
  ///
  /// Suppressed entirely when [BottomSheetContent.enableAutocomplete] is
  /// `false`: that flag's contract is "all options are always displayed",
  /// which a custom-value commit row -- offering to commit text that matches
  /// none of them -- would sit oddly alongside.
  bool get _hasCustomValueRow {
    if (!widget.enableAutocomplete) return false;
    final query = _searchController.text;
    if (query.isEmpty) return false;
    final lowerQuery = query.toLowerCase();
    return !widget.options.any((option) => option.toLowerCase() == lowerQuery);
  }

  /// The number of navigable rows: the custom-value row (if present) plus
  /// [_filteredOptions]. Used to keep [_highlightedIndex] within bounds
  /// across arrow-key navigation.
  int _navigableRowCount() => (_hasCustomValueRow ? 1 : 0) + _filteredOptions.length;

  /// Commits the value at [_highlightedIndex] in the combined navigable-row
  /// space (custom-value row first, then [_filteredOptions]) -- invoked on
  /// Enter. A no-op when nothing is highlighted.
  void _commitHighlighted() {
    if (_highlightedIndex < 0) return;

    if (_hasCustomValueRow) {
      if (_highlightedIndex == 0) {
        _commit(_searchController.text);
        return;
      }
      final optionIndex = _highlightedIndex - 1;
      if (optionIndex < _filteredOptions.length) {
        _commit(_filteredOptions[optionIndex]);
      }
    } else if (_highlightedIndex < _filteredOptions.length) {
      _commit(_filteredOptions[_highlightedIndex]);
    }
  }

  /// Commits [value] by popping the enclosing route with it -- the single
  /// commit path every row (custom-value or ordinary option) and Enter both
  /// funnel through. See the class doc for why there is no separate,
  /// callback-based commit path.
  void _commit(String value) {
    Navigator.of(context, rootNavigator: true).pop(value);
  }

  /// Handles arrow-key navigation and Enter-to-commit across the navigable
  /// rows (see the class doc's "Keyboard navigation" section). Escape is not
  /// handled here: [LayrzBottomSheet] and [LayrzEndDrawer] each already
  /// dismiss themselves on Escape (their own barrier/PopScope handling), and
  /// this widget commits nothing on dismissal, matching a barrier tap.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final rowCount = _navigableRowCount();
    if (rowCount == 0) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _highlightedIndex = _highlightedIndex < 0 ? 0 : (_highlightedIndex + 1) % rowCount;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlightedIndex = _highlightedIndex <= 0 ? rowCount - 1 : _highlightedIndex - 1;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < rowCount) {
        _commitHighlighted();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
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
                  setState(() {
                    _updateFilteredOptions();
                    _highlightedIndex = -1;
                  });
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
    final hasCustomValueRow = _hasCustomValueRow;

    final Widget listOrEmptyState;
    if (_filteredOptions.isEmpty && !hasCustomValueRow) {
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
          // Stretches every row (the custom-value row and each option row)
          // to the list's own full width -- see _ComboBoxSheetOptionRow's own
          // doc comment for why this is what makes their text read as
          // left-aligned rather than centered.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasCustomValueRow)
              _ComboBoxSheetOptionRow(
                text: _searchController.text,
                isHighlighted: _highlightedIndex == 0,
                isBold: true,
                onTap: () => _commit(_searchController.text),
              ),
            for (final (index, option) in _filteredOptions.indexed)
              _ComboBoxSheetOptionRow(
                text: option,
                isHighlighted: _highlightedIndex == (hasCustomValueRow ? index + 1 : index),
                onTap: () => _commit(option),
              ),
          ],
        ),
      );
    }

    // Names the sheet's subtree with what is being picked (DESIGN-161): before
    // this, nothing in the sheet was nameable at all, since the label lives on
    // the closed field underneath the modal barrier. `container: true` keeps
    // this node from merging its label into a descendant's (the search field
    // below has its own, deliberately distinct, name). Always applied,
    // independent of `showInlineTitle` -- see that field's own doc.
    return Semantics(
      container: true,
      label: widget.labelText,
      child: Focus(
        focusNode: _listFocusNode,
        skipTraversal: true,
        onKeyEvent: _handleKeyEvent,
        // Stretches the search field and the title row to the same full
        // width as the option list, for the identical reason -- see
        // _ComboBoxSheetOptionRow's own doc comment.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showInlineTitle && widget.labelText != null)
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
      ),
    );
  }
}
