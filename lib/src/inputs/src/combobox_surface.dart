import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

/// Displays filtered options in a desktop overlay.
///
/// Shows a scrollable list of options with highlight support, or an empty message
/// when no options match the filter.
class DesktopOverlay extends StatelessWidget {
  /// The filtered list of options to display.
  final List<String> options;

  /// Index of the currently highlighted option, or -1 if none.
  final int highlightedIndex;

  /// Callback when an option is selected.
  final ValueChanged<String> onSelected;

  /// Maximum height of the overlay in logical pixels.
  final double maxHeight;

  /// Text to display when no options match.
  final String emptyText;

  /// Creates a desktop overlay.
  const DesktopOverlay({
    super.key,
    required this.options,
    required this.highlightedIndex,
    required this.onSelected,
    required this.maxHeight,
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
      child: Container(
        decoration: BoxDecoration(
          color: tokens.colors.sf1,
          borderRadius: tokens.radius.br3,
          boxShadow: tokens.shadow.elevation3,
        ),
        constraints: BoxConstraints(maxHeight: maxHeight),
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
/// Displays options as a scrollable list, with a callback for selection.
class BottomSheetContent extends StatelessWidget {
  /// The filtered list of options to display.
  final List<String> options;

  /// Callback when an option is selected.
  final ValueChanged<String> onSelected;

  /// Text to display when no options match.
  final String emptyText;

  /// Creates bottom sheet content.
  const BottomSheetContent({
    super.key,
    required this.options,
    required this.onSelected,
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

    return ListView.builder(
      itemCount: options.length,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () {
          onSelected(options[index]);
          Navigator.of(context, rootNavigator: true).pop(options[index]);
        },
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
    );
  }
}
