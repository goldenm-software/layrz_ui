import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds a comprehensive showroom section demonstrating all chip features.
///
/// This section displays:
/// - All three style variants (filled, outlined, filledTonal)
/// - All six semantic types (info, success, warning, danger, context, custom)
/// - Features: leading icon and delete affordance
/// - Interactive delete (with setState to remove from list)
/// - Scrollable chip group (.none behavior)
/// - Compact chip group (.compact behavior) with +N overflow indicator
class ChipsSection extends StatefulWidget {
  const ChipsSection({super.key});
  @override
  State<ChipsSection> createState() => _ChipsSectionState();
}

class _ChipsSectionState extends State<ChipsSection> {
  late List<String> deletableChips;

  @override
  void initState() {
    super.initState();
    deletableChips = [
      'Chip 1',
      'Chip 2',
      'Chip 3',
      'Chip 4',
      'Chip 5',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Chips',
      description: 'Static labels with optional icons and delete affordance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.sp4,
        children: [
          // Styles showcase
          _ChipsStylesShowcase(tokens: tokens),

          // Types showcase
          _ChipsTypesShowcase(tokens: tokens),

          // Features showcase
          _ChipsFeatureShowcase(tokens: tokens),

          // Interactive delete showcase
          _ChipsDeleteShowcase(
            tokens: tokens,
            chips: deletableChips,
            onDelete: (chip) {
              setState(() {
                deletableChips.remove(chip);
              });
            },
          ),

          // Scrollable group showcase
          _ChipsScrollableGroupShowcase(tokens: tokens),

          // Compact group showcase
          _ChipsCompactGroupShowcase(tokens: tokens),
        ],
      ),
    );
  }
}

/// Showcase of the three style variants.
class _ChipsStylesShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _ChipsStylesShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp2,
      children: [
        Text(
          'Style Variants',
          style: tokens.typography.title,
        ),
        Row(
          spacing: tokens.spacing.sp2,
          children: [
            const LayrzChip(
              labelText: 'Filled',
              style: LayrzChipStyle.filled,
              type: LayrzChipType.info,
            ),
            const LayrzChip(
              labelText: 'Outlined',
              style: LayrzChipStyle.outlined,
              type: LayrzChipType.success,
            ),
            const LayrzChip(
              labelText: 'Filled Tonal',
              style: LayrzChipStyle.filledTonal,
              type: LayrzChipType.warning,
            ),
          ],
        ),
      ],
    );
  }
}

/// Showcase of the six semantic types.
class _ChipsTypesShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _ChipsTypesShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp2,
      children: [
        Text(
          'Semantic Types',
          style: tokens.typography.title,
        ),
        Wrap(
          spacing: tokens.spacing.sp2,
          runSpacing: tokens.spacing.sp2,
          children: const [
            LayrzChip(labelText: 'Info', type: LayrzChipType.info),
            LayrzChip(labelText: 'Success', type: LayrzChipType.success),
            LayrzChip(labelText: 'Warning', type: LayrzChipType.warning),
            LayrzChip(labelText: 'Danger', type: LayrzChipType.danger),
            LayrzChip(labelText: 'Context', type: LayrzChipType.context),
            LayrzChip(labelText: 'Custom', type: LayrzChipType.custom),
          ],
        ),
      ],
    );
  }
}

/// Showcase of leading icon and delete affordance.
class _ChipsFeatureShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _ChipsFeatureShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp2,
      children: [
        Text(
          'Features: Leading Icon & Delete',
          style: tokens.typography.title,
        ),
        Wrap(
          spacing: tokens.spacing.sp2,
          runSpacing: tokens.spacing.sp2,
          children: [
            LayrzChip(
              labelText: 'With Icon',
              leadingIcon: MdiIcons.checkCircleOutline,
              type: LayrzChipType.success,
            ),
            LayrzChip(
              labelText: 'Deletable',
              onDelete: () {},
              type: LayrzChipType.warning,
            ),
            LayrzChip(
              labelText: 'Both',
              leadingIcon: MdiIcons.checkCircleOutline,
              onDelete: () {},
              type: LayrzChipType.info,
            ),
          ],
        ),
      ],
    );
  }
}

/// Interactive delete showcase.
class _ChipsDeleteShowcase extends StatelessWidget {
  final LayrzTokens tokens;
  final List<String> chips;
  final Function(String) onDelete;

  const _ChipsDeleteShowcase({
    required this.tokens,
    required this.chips,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp2,
      children: [
        Text(
          'Interactive Delete (Click to Remove)',
          style: tokens.typography.title,
        ),
        Wrap(
          spacing: tokens.spacing.sp2,
          runSpacing: tokens.spacing.sp2,
          children: chips
              .map(
                (chip) => LayrzChip(
                  labelText: chip,
                  onDelete: () => onDelete(chip),
                  type: LayrzChipType.custom,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

/// Scrollable chip group showcase.
class _ChipsScrollableGroupShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _ChipsScrollableGroupShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp2,
      children: [
        Text(
          'Scrollable Group (.none behavior)',
          style: tokens.typography.title,
        ),
        const LayrzChipGroup(
          chips: [
            LayrzChip(labelText: 'Scrollable Chip 1', type: LayrzChipType.info),
            LayrzChip(labelText: 'Scrollable Chip 2', type: LayrzChipType.success),
            LayrzChip(labelText: 'Scrollable Chip 3', type: LayrzChipType.warning),
            LayrzChip(labelText: 'Scrollable Chip 4', type: LayrzChipType.danger),
            LayrzChip(labelText: 'Scrollable Chip 5', type: LayrzChipType.context),
            LayrzChip(labelText: 'Scrollable Chip 6', type: LayrzChipType.custom),
          ],
          behavior: LayrzChipGroupBehavior.none,
        ),
      ],
    );
  }
}

/// Compact chip group showcase with +N overflow indicator.
class _ChipsCompactGroupShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _ChipsCompactGroupShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp2,
      children: [
        Text(
          'Compact Group (.compact behavior - Resize to see +N)',
          style: tokens.typography.title,
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: tokens.colors.fg3),
            borderRadius: tokens.radius.br2,
          ),
          padding: EdgeInsets.all(tokens.spacing.sp3),
          child: SizedBox(
            width: 300,
            child: const LayrzChipGroup(
              chips: [
                LayrzChip(labelText: 'Compact 1', type: LayrzChipType.info),
                LayrzChip(labelText: 'Compact 2', type: LayrzChipType.success),
                LayrzChip(labelText: 'Compact 3', type: LayrzChipType.warning),
                LayrzChip(labelText: 'Compact 4', type: LayrzChipType.danger),
                LayrzChip(labelText: 'Compact 5', type: LayrzChipType.context),
                LayrzChip(labelText: 'Compact 6', type: LayrzChipType.custom),
              ],
              behavior: LayrzChipGroupBehavior.compact,
            ),
          ),
        ),
        Text(
          'This group is constrained to 300px width. Resize the window to see the +N chip appear.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
      ],
    );
  }
}
