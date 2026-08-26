import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

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
/// Displays options as a scrollable list. Selection is communicated solely by
/// popping the enclosing route with the chosen option -- there is no `onSelected`
/// callback here, because `LayrzComboBoxInput._openBottomSheet` already commits
/// the popped value exactly once. An earlier version called both a callback *and*
/// popped with the same value, which committed the selection twice per tap; this
/// widget deliberately has only one way to report a choice, so that mistake cannot
/// come back.
///
/// Built as a [SingleChildScrollView] wrapping a plain [Column], never a [ListView]:
/// [LayrzBottomSheet] is shown with `scrollable: false` for this content (see
/// `LayrzComboBoxInput._openBottomSheet`), which hands this subtree the sheet's own
/// [ScrollController] via an ambient `PrimaryScrollController` instead of nesting it
/// inside another same-axis scrollable. A lazy-loading [ListView] here would receive
/// unbounded height from that same-axis nesting and assert; a [Column] does not need
/// laziness in the first place, since combobox option counts are small.
class BottomSheetContent extends StatelessWidget {
  /// The filtered list of options to display.
  final List<String> options;

  /// Text to display when no options match.
  final String emptyText;

  /// Creates bottom sheet content.
  const BottomSheetContent({
    super.key,
    required this.options,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (options.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.sp4),
          child: Text(
            emptyText,
            style: tokens.typography.label.copyWith(
              color: tokens.colors.fg3,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          options.length,
          (index) => GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true).pop(options[index]),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: tokens.spacing.sp3,
                horizontal: tokens.spacing.sp4,
              ),
              child: Text(
                options[index],
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
}
