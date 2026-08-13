// ignore_for_file: unused_element_parameter
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Displays all spacing tokens as a visual ruler and convenience accessor demonstrations.
///
/// Shows each spacing value (sp4 through sp48) as a bar whose width is that token,
/// labelled with name and pixel value. Also demonstrates [margin], [reducedMargin],
/// and [padding] with visual examples.
Widget buildSpacingSection() {
  return Builder(
    builder: (context) {
      final tokens = context.tokens;

      return ShowroomSection(
        title: 'Spacing',
        description: 'Spacing tokens form a harmonious 4-pixel grid',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spacing ruler
            Text('Spacing Values (sp4 → sp48)', style: tokens.typography.titleMedium),
            SizedBox(height: tokens.spacing.sp12),
            _SpacingRuler(tokens: tokens),

            SizedBox(height: tokens.spacing.sp24),

            // Convenience accessors
            Text('Convenience Accessors', style: tokens.typography.titleMedium),
            SizedBox(height: tokens.spacing.sp12),
            _SpacingAccessors(tokens: tokens),
          ],
        ),
      );
    },
  );
}

/// A visual ruler showing all spacing values as bars with labels.
class _SpacingRuler extends StatelessWidget {
  /// Creates a new [_SpacingRuler].
  const _SpacingRuler({required this.tokens, super.key});

  /// The token set containing spacing tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    final spacingValues = [
      ('sp4', tokens.spacing.sp4),
      ('sp6', tokens.spacing.sp6),
      ('sp8', tokens.spacing.sp8),
      ('sp10', tokens.spacing.sp10),
      ('sp12', tokens.spacing.sp12),
      ('sp14', tokens.spacing.sp14),
      ('sp16', tokens.spacing.sp16),
      ('sp20', tokens.spacing.sp20),
      ('sp24', tokens.spacing.sp24),
      ('sp28', tokens.spacing.sp28),
      ('sp32', tokens.spacing.sp32),
      ('sp36', tokens.spacing.sp36),
      ('sp40', tokens.spacing.sp40),
      ('sp44', tokens.spacing.sp44),
      ('sp48', tokens.spacing.sp48),
    ];

    return Column(
      children: spacingValues
          .map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: tokens.spacing.sp12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Label
                  SizedBox(
                    width: 50,
                    child: Text(item.$1, style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3)),
                  ),

                  // Bar whose width is the spacing value
                  Expanded(
                    child: Container(
                      height: 24,
                      width: item.$2,
                      decoration: BoxDecoration(
                        color: tokens.colors.primary,
                        borderRadius: BorderRadius.circular(tokens.radius.r8),
                      ),
                    ),
                  ),

                  // Value label
                  SizedBox(width: tokens.spacing.sp8),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${item.$2.toStringAsFixed(0)} px',
                      textAlign: TextAlign.right,
                      style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Demonstrates convenience spacing accessors (margin, padding, reducedMargin).
class _SpacingAccessors extends StatelessWidget {
  /// Creates a new [_SpacingAccessors].
  const _SpacingAccessors({required this.tokens, super.key});

  /// The token set containing spacing tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Padding example
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('padding', style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3)),
              SizedBox(height: tokens.spacing.sp8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: tokens.colors.divider, width: tokens.border.stroke2),
                  borderRadius: BorderRadius.circular(tokens.radius.r8),
                ),
                padding: tokens.spacing.padding,
                child: Container(
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.r8),
                  ),
                  height: 40,
                ),
              ),
              SizedBox(height: tokens.spacing.sp8),
              Text(
                '${tokens.spacing.base} px',
                style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3, fontSize: 11),
              ),
            ],
          ),
        ),

        SizedBox(width: tokens.spacing.sp16),

        // Reduced margin example
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('reducedMargin', style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3)),
              SizedBox(height: tokens.spacing.sp8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: tokens.colors.divider, width: tokens.border.stroke2),
                  borderRadius: BorderRadius.circular(tokens.radius.r8),
                ),
                margin: tokens.spacing.reducedMargin,
                padding: tokens.spacing.padding,
                child: Container(
                  decoration: BoxDecoration(
                    color: tokens.colors.accent,
                    borderRadius: BorderRadius.circular(tokens.radius.r8),
                  ),
                  height: 40,
                ),
              ),
              SizedBox(height: tokens.spacing.sp8),
              Text(
                '${(tokens.spacing.base / 2).toStringAsFixed(1)} px',
                style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3, fontSize: 11),
              ),
            ],
          ),
        ),

        SizedBox(width: tokens.spacing.sp16),

        // Base spacing size box
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('sizedBox', style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3)),
              SizedBox(height: tokens.spacing.sp8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: tokens.colors.divider, width: tokens.border.stroke2),
                  borderRadius: BorderRadius.circular(tokens.radius.r8),
                ),
                padding: tokens.spacing.padding,
                child: tokens.spacing.sizedBox,
              ),
              SizedBox(height: tokens.spacing.sp8),
              Text(
                '${tokens.spacing.base} × ${tokens.spacing.base}',
                style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
