import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

/// Displays filtered options in a desktop overlay.
///
/// Shows a scrollable list of options with highlight support, or an empty message
/// when no options match the filter.
///
/// The overlay's height is not capped here: the enclosing `CustomSingleChildLayout`
/// (see `ComboBoxLayoutDelegate.getConstraintsForChild`) already hands this widget a
/// bounded `maxHeight` via the incoming [BoxConstraints]. Re-applying the same cap on
/// an inner [Container] here — as this widget previously did — clamps the [Column] to
/// that height *inside* the [SingleChildScrollView], which makes the scroll view's
/// content extent equal its viewport extent (so it can never scroll) while the
/// non-scrolling [Column] overflows by the difference. Leaving the [Column] free to
/// size to its content, with only the outer constraint bounding the viewport, is what
/// makes the list actually scrollable past that bound.
class DesktopOverlay extends StatelessWidget {
  /// The filtered list of options to display.
  final List<String> options;

  /// Index of the currently highlighted option, or -1 if none.
  final int highlightedIndex;

  /// Callback when an option is selected.
  final ValueChanged<String> onSelected;

  /// Text to display when no options match.
  final String emptyText;

  /// Creates a desktop overlay.
  const DesktopOverlay({
    super.key,
    required this.options,
    required this.highlightedIndex,
    required this.onSelected,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (options.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(tokens.spacing.sp2),
        child: Text(
          emptyText,
          style: tokens.typography.label.copyWith(
            color: tokens.colors.fg3,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.colors.sf1,
          borderRadius: tokens.radius.br3,
          boxShadow: tokens.shadow.elevation3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            options.length,
            (index) => OptionItem(
              option: options[index],
              isHighlighted: index == highlightedIndex,
              onTap: () => onSelected(options[index]),
            ),
          ),
        ),
      ),
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
/// popping the enclosing route with the chosen option — there is no `onSelected`
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
