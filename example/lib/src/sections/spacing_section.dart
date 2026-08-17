import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';
import '../common/unit_display.dart';

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
        description: 'Spacing tokens with values from 4 to 48 pixels (not all multiples of 4)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spacing ruler
            Text('Spacing Values (sp4 → sp48)', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp12),
            _SpacingRuler(tokens: tokens),

            SizedBox(height: tokens.spacing.sp24),

            // Convenience accessors
            Text('Convenience Accessors', style: tokens.typography.title),
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
  const _SpacingRuler({required this.tokens});

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
                    width: tokens.spacing.sp48,
                    child: Text(item.$1, style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
                  ),

                  // Track (background strip) with bar on top showing true width
                  Expanded(
                    child: LayrzTooltip(
                      contentText: '${item.$1} = ${item.$2.toStringAsFixed(0)}px',
                      child: Container(
                        height: tokens.spacing.sp24,
                        decoration: BoxDecoration(
                          color: tokens.colors.surface2,
                          borderRadius: BorderRadius.circular(tokens.radius.r8),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: item.$2,
                          height: tokens.spacing.sp24,
                          key: ValueKey('spacing-bar-${item.$1}'),
                          decoration: BoxDecoration(
                            color: tokens.colors.primary,
                            borderRadius: BorderRadius.circular(
                              // Use small radius for very small bars (sp4, sp6), larger for bigger bars
                              item.$2 <= 8.0 ? 2.0 : min(item.$2 / 4, tokens.radius.r8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Value label
                  SizedBox(width: tokens.spacing.sp8),
                  SizedBox(
                    width: tokens.spacing.sp48,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: UnitDisplay(
                        value: item.$2,
                        textStyle: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                      ),
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
  const _SpacingAccessors({required this.tokens});

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
              Text('padding', style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
              SizedBox(height: tokens.spacing.sp8),
              LayrzTooltip(
                contentText: 'padding = ${tokens.spacing.base.toStringAsFixed(0)}px on all sides',
                child: Container(
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
              ),
              SizedBox(height: tokens.spacing.sp8),
              UnitDisplay(
                value: tokens.spacing.base,
                textStyle: tokens.typography.label.copyWith(color: tokens.colors.fg3, fontSize: 11),
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
              Text('reducedMargin', style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
              SizedBox(height: tokens.spacing.sp8),
              LayrzTooltip(
                contentText: 'reducedMargin = ${(tokens.spacing.base / 2).toStringAsFixed(0)}px on all sides',
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: tokens.colors.divider, width: tokens.border.stroke2),
                    borderRadius: BorderRadius.circular(tokens.radius.r8),
                  ),
                  margin: tokens.spacing.reducedMargin,
                  padding: tokens.spacing.padding,
                  child: Container(
                    decoration: BoxDecoration(
                      color: tokens.colors.primary,
                      borderRadius: BorderRadius.circular(tokens.radius.r8),
                    ),
                    height: 40,
                  ),
                ),
              ),
              SizedBox(height: tokens.spacing.sp8),
              UnitDisplay(
                value: tokens.spacing.base / 2,
                textStyle: tokens.typography.label.copyWith(color: tokens.colors.fg3, fontSize: 11),
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
              Text('sizedBox', style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
              SizedBox(height: tokens.spacing.sp8),
              LayrzTooltip(
                contentText:
                    'sizedBox = ${tokens.spacing.base.toStringAsFixed(0)}px × ${tokens.spacing.base.toStringAsFixed(0)}px',
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: tokens.colors.divider, width: tokens.border.stroke2),
                    borderRadius: BorderRadius.circular(tokens.radius.r8),
                  ),
                  padding: tokens.spacing.padding,
                  child: tokens.spacing.sizedBox,
                ),
              ),
              SizedBox(height: tokens.spacing.sp8),
              Text(
                '${tokens.spacing.base} × ${tokens.spacing.base}',
                style: tokens.typography.label.copyWith(color: tokens.colors.fg3, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
