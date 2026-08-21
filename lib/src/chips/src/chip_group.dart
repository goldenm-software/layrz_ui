import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/theme/theme.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

import 'chip.dart';
import 'chip_group_behavior.dart';
import 'chip_style.dart';
import 'chip_type.dart';

/// A group of [LayrzChip] widgets with configurable layout behavior.
///
/// [LayrzChipGroup] manages the horizontal layout of multiple chips with two
/// behavior modes:
/// - [LayrzChipGroupBehavior.none]: chips render on a scrollable single row
/// - [LayrzChipGroupBehavior.compact]: chips are clamped to available width with `+N` overflow
///
/// In compact mode, chips that overflow are collapsed into a trailing `+N` chip whose
/// tooltip lists the hidden labels. The `N` is clamped to 1–9.
///
/// **Measurement caveat for compact mode**: This widget measures each chip
/// individually to determine when to show the `+N` indicator, so the `+N` chip may
/// appear one chip early or late depending on rounding. This costs one full text
/// layout per chip per build. Use sparingly if performance is critical.
class LayrzChipGroup extends StatelessWidget {
  /// The list of chips to display in the group.
  final List<LayrzChip> chips;

  /// The layout behavior determining how overflow is handled.
  final LayrzChipGroupBehavior behavior;

  /// The space between each chip in logical pixels.
  ///
  /// When null, defaults to [LayrzTokens.spacing.sp2].
  final double? spacing;

  /// The alignment of the chips within their container.
  ///
  /// Only used by [LayrzChipGroupBehavior.none]; [LayrzChipGroupBehavior.compact]
  /// always produces left-aligned output due to its overflow-dependent layout.
  final Alignment alignment;

  /// Creates a new [LayrzChipGroup].
  const LayrzChipGroup({
    super.key,
    required this.chips,
    this.behavior = LayrzChipGroupBehavior.none,
    this.spacing,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = LayrzTheme.of(context).tokens;
    final resolvedSpacing = spacing ?? tokens.spacing.sp2;

    if (behavior == LayrzChipGroupBehavior.none) {
      return Align(
        alignment: alignment,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: resolvedSpacing,
            children: chips,
          ),
        ),
      );
    }

    // LayrzChipGroupBehavior.compact
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.maxWidth != double.infinity,
          'LayrzChipGroup with compact behavior requires a finite maxWidth constraint.',
        );

        // Measure the +N chip upfront to reserve space
        final overflowChip = LayrzChip(
          labelText: '+9',
          style: LayrzChipStyle.filledTonal,
          type: LayrzChipType.context,
        );
        double requiredRemainingWidth = overflowChip.computeWidth(context);

        double takenWidth = 0;
        final List<Widget> visibleChips = [];

        for (int i = 0; i < chips.length; i++) {
          final chip = chips[i];
          double chipWidth = chip.computeWidth(context);

          // Add spacing if not the first chip
          if (i > 0) {
            chipWidth += resolvedSpacing;
          }

          // If this is the last chip, no need to reserve space for +N
          if (i == chips.length - 1) {
            requiredRemainingWidth = 0;
          }

          takenWidth += chipWidth;

          // Check if we can fit this chip plus the +N indicator (if needed)
          if (takenWidth + requiredRemainingWidth <= constraints.maxWidth) {
            visibleChips.add(chip);
          } else {
            // We've run out of space; show the remaining chips as +N
            final hiddenCount = chips.length - visibleChips.length;
            if (hiddenCount > 0) {
              final clampedHiddenCount = hiddenCount.clamp(1, 9);
              final hiddenLabels = chips.sublist(visibleChips.length).map((c) => c.labelText).toList();

              visibleChips.add(
                LayrzTooltip(
                  contentText: hiddenLabels.join('\n'),
                  child: LayrzChip(
                    labelText: '+$clampedHiddenCount',
                    style: LayrzChipStyle.filledTonal,
                    type: LayrzChipType.context,
                  ),
                ),
              );
            }
            break;
          }
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: resolvedSpacing,
            children: visibleChips,
          ),
        );
      },
    );
  }
}
