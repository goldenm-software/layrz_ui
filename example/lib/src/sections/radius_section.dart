// ignore_for_file: unused_element_parameter
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';
import '../common/showroom_swatch.dart';

/// Displays all radius tokens as rounded corner samples and demonstrates
/// the [innerRadius] helper for nested container borders.
Widget buildRadiusSection() {
  return Builder(
    builder: (context) {
      final tokens = context.tokens;

      return ShowroomSection(
        title: 'Radius',
        description: 'All border radius tokens and innerRadius helper',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radius samples
            Text('Border Radius Values', style: tokens.typography.titleMedium),
            SizedBox(height: tokens.spacing.sp12),
            Wrap(
              spacing: tokens.spacing.sp16,
              runSpacing: tokens.spacing.sp16,
              children: [
                ShowroomSwatch(
                  label: 'r8',
                  value: '8 px',
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.r8),
                  ),
                ),
                ShowroomSwatch(
                  label: 'r10',
                  value: '10 px',
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.r10),
                  ),
                ),
                ShowroomSwatch(
                  label: 'r12',
                  value: '12 px',
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.r12),
                  ),
                ),
                ShowroomSwatch(
                  label: 'r14',
                  value: '14 px',
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.r14),
                  ),
                ),
                ShowroomSwatch(
                  label: 'r16',
                  value: '16 px',
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.r16),
                  ),
                ),
                ShowroomSwatch(
                  label: 'r20',
                  value: '20 px',
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.r20),
                  ),
                ),
                ShowroomSwatch(
                  label: 'r24',
                  value: '24 px',
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.r24),
                  ),
                ),
                ShowroomSwatch(
                  label: 'full',
                  value: '∞ (pill)',
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.full),
                  ),
                ),
              ],
            ),

            SizedBox(height: tokens.spacing.sp24),

            // innerRadius demonstration
            Text('innerRadius() Helper', style: tokens.typography.titleMedium),
            SizedBox(height: tokens.spacing.sp12),
            _InnerRadiusDemonstration(tokens: tokens),
          ],
        ),
      );
    },
  );
}

/// Demonstrates the innerRadius helper for nested container borders.
class _InnerRadiusDemonstration extends StatelessWidget {
  /// Creates a new [_InnerRadiusDemonstration].
  const _InnerRadiusDemonstration({required this.tokens, super.key});

  /// The token set.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    // Example parameters
    const outerRadius = 16.0;
    const spacer = 4.0;
    final innerRadius = tokens.radius.innerRadius(outerRadius: outerRadius, spacer: spacer);

    // Compute the inner radius value manually for display
    final computedInnerValue = (outerRadius - spacer).clamp(0.0, double.infinity);

    return Container(
      decoration: BoxDecoration(color: tokens.colors.primary, borderRadius: BorderRadius.circular(outerRadius)),
      padding: EdgeInsets.all(spacer),
      child: Container(
        height: 120,
        decoration: BoxDecoration(color: tokens.colors.surface, borderRadius: innerRadius),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('innerRadius(', style: tokens.typography.labelSmall.copyWith(fontFamily: 'monospace')),
            Text(
              'outerRadius: $outerRadius,',
              style: tokens.typography.labelSmall.copyWith(fontFamily: 'monospace', fontSize: 10),
            ),
            Text(
              'spacer: $spacer',
              style: tokens.typography.labelSmall.copyWith(fontFamily: 'monospace', fontSize: 10),
            ),
            Text(
              ') → ${computedInnerValue.toStringAsFixed(0)} px',
              style: tokens.typography.labelSmall.copyWith(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
