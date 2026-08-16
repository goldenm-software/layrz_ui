import 'package:flutter/widgets.dart';
import 'package:layrz_ui/extensions.dart';
import 'package:layrz_ui/tokens.dart';

import '../common/showroom_section.dart';
import '../common/showroom_swatch.dart';

/// Sample box height for innerRadius demonstration.
/// Must be large relative to the corner radius so the arcs are joined by long
/// straight edges, making the corner geometry and the concentric relationship
/// immediately visible. With a 24u radius on only 80u of height, corners
/// consume 30% of the box, reading as a lozenge; at 200u the corners read
/// clearly as corners joined to long straight edges.
const double _sampleBoxHeight = 200;

/// Stroke width for the outlined ring demonstration.
/// Outlined boxes make the correct vs. naive difference pedagogically clear —
/// with a filled ring, the reader must infer both arcs; here both outer and
/// inner radius arcs are drawn directly as stroked boundaries, matching the
/// reference diagram and making the naive bulge immediately visible.
const double _sampleStrokeWidth = 2;

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
                  value: '8u',
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.r8),
                  ),
                ),
                ShowroomSwatch(
                  label: 'r10',
                  value: '10u',
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.r10),
                  ),
                ),
                ShowroomSwatch(
                  label: 'r12',
                  value: '12u',
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.r12),
                  ),
                ),
                ShowroomSwatch(
                  label: 'r14',
                  value: '14u',
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.r14),
                  ),
                ),
                ShowroomSwatch(
                  label: 'r16',
                  value: '16u',
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.r16),
                  ),
                ),
                ShowroomSwatch(
                  label: 'r20',
                  value: '20u',
                  decoration: BoxDecoration(
                    color: tokens.colors.primary,
                    borderRadius: BorderRadius.circular(tokens.radius.r20),
                  ),
                ),
                ShowroomSwatch(
                  label: 'r24',
                  value: '24u',
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
  const _InnerRadiusDemonstration({required this.tokens});

  /// The token set.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explanation
        Text(
          'For concentric corners, inner_radius = max(outer_radius − gap, 0)',
          style: tokens.typography.labelMedium,
        ),
        SizedBox(height: tokens.spacing.sp16),

        // Main demonstration: Correct vs. Naive, responsive layout
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < context.tokens.breakpoints.sm;

            if (isNarrow) {
              // Stack vertically on narrow windows
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InnerRadiusCase(
                    tokens: tokens,
                    title: 'Correct',
                    outerRadius: tokens.radius.r24,
                    spacer: tokens.spacing.sp12,
                    innerRadius: tokens.radius.innerRadius(outerRadius: tokens.radius.r24, spacer: tokens.spacing.sp12),
                    isCorrect: true,
                    keyPrefix: 'innerRadius-demo-correct',
                  ),
                  SizedBox(height: tokens.spacing.sp20),
                  _InnerRadiusCase(
                    tokens: tokens,
                    title: 'Naive / Wrong',
                    outerRadius: tokens.radius.r24,
                    spacer: tokens.spacing.sp12,
                    innerRadius: BorderRadius.circular(tokens.radius.r24),
                    isCorrect: false,
                    keyPrefix: 'innerRadius-demo-naive',
                  ),
                ],
              );
            } else {
              // Side by side on wider windows, filling available width
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InnerRadiusCase(
                      tokens: tokens,
                      title: 'Correct',
                      outerRadius: tokens.radius.r24,
                      spacer: tokens.spacing.sp12,
                      innerRadius: tokens.radius.innerRadius(
                        outerRadius: tokens.radius.r24,
                        spacer: tokens.spacing.sp12,
                      ),
                      isCorrect: true,
                      keyPrefix: 'innerRadius-demo-correct',
                    ),
                  ),
                  SizedBox(width: tokens.spacing.sp20),
                  Expanded(
                    child: _InnerRadiusCase(
                      tokens: tokens,
                      title: 'Naive / Wrong',
                      outerRadius: tokens.radius.r24,
                      spacer: tokens.spacing.sp12,
                      innerRadius: BorderRadius.circular(tokens.radius.r24),
                      isCorrect: false,
                      keyPrefix: 'innerRadius-demo-naive',
                    ),
                  ),
                ],
              );
            }
          },
        ),
        SizedBox(height: tokens.spacing.sp24),

        // Clamp demonstration: when spacer > outerRadius
        Text('When gap exceeds outer radius, corners clamp to square:', style: tokens.typography.labelMedium),
        SizedBox(height: tokens.spacing.sp12),
        _InnerRadiusCase(
          tokens: tokens,
          title: 'Clamped to 0',
          outerRadius: tokens.radius.r8,
          spacer: tokens.spacing.sp12,
          innerRadius: tokens.radius.innerRadius(outerRadius: tokens.radius.r8, spacer: tokens.spacing.sp12),
          isCorrect: true,
          keyPrefix: 'innerRadius-demo-clamp',
        ),
      ],
    );
  }
}

/// A single case demonstrating innerRadius with labeled parameters.
class _InnerRadiusCase extends StatelessWidget {
  /// Creates a new [_InnerRadiusCase].
  const _InnerRadiusCase({
    required this.tokens,
    required this.title,
    required this.outerRadius,
    required this.spacer,
    required this.innerRadius,
    required this.isCorrect,
    required this.keyPrefix,
  });

  /// The token set.
  final LayrzTokens tokens;

  /// Label for this case (e.g., "Correct" or "Naive / Wrong").
  final String title;

  /// Outer container radius in pixels.
  final double outerRadius;

  /// Gap between outer and inner container in pixels.
  final double spacer;

  /// BorderRadius for the inner container.
  final BorderRadius innerRadius;

  /// Whether this case uses the correct formula.
  final bool isCorrect;

  /// Key prefix for widget identification in tests.
  final String keyPrefix;

  /// Extracts the single radius value from a BorderRadius (assuming all corners are equal).
  double _extractRadiusValue(BorderRadius br) {
    return br.topLeft.x;
  }

  @override
  Widget build(BuildContext context) {
    final computedInnerRadius = _extractRadiusValue(innerRadius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: tokens.typography.titleSmall),
        SizedBox(height: tokens.spacing.sp8),
        // Parameters label
        Text(
          'outer = ${outerRadius.toStringAsFixed(0)}u',
          style: tokens.typography.labelSmall,
        ),
        Text(
          'gap = ${spacer.toStringAsFixed(0)}u',
          style: tokens.typography.labelSmall,
        ),
        SizedBox(height: tokens.spacing.sp4),
        // Computed inner radius label
        if (isCorrect)
          Text(
            'inner = ${computedInnerRadius.toStringAsFixed(0)}u (${outerRadius.toStringAsFixed(0)}u − ${spacer.toStringAsFixed(0)}u)',
            style: tokens.typography.labelSmall.copyWith(fontWeight: FontWeight.bold),
          )
        else
          Text(
            'inner = ${computedInnerRadius.toStringAsFixed(0)}u (reusing outer)',
            style: tokens.typography.labelSmall.copyWith(fontWeight: FontWeight.bold),
          ),
        SizedBox(height: tokens.spacing.sp12),
        // Visual demonstration: outlined rings (both arcs directly visible)
        Container(
          key: ValueKey('$keyPrefix-outer'),
          width: double.infinity,
          height: _sampleBoxHeight,
          decoration: BoxDecoration(
            border: Border.all(
              color: tokens.colors.primary,
              width: _sampleStrokeWidth,
            ),
            borderRadius: BorderRadius.circular(outerRadius),
          ),
          padding: EdgeInsets.all(spacer),
          child: Container(
            key: ValueKey('$keyPrefix-inner'),
            decoration: BoxDecoration(
              border: Border.all(
                color: tokens.colors.primary,
                width: _sampleStrokeWidth,
              ),
              borderRadius: innerRadius,
            ),
          ),
        ),
        // Show the discrepancy for naive case
        if (!isCorrect) ...[
          SizedBox(height: tokens.spacing.sp8),
          Text(
            '✗ Corners bulge; gap looks wider at corners',
            style: tokens.typography.labelSmall.copyWith(color: tokens.colors.danger),
          ),
        ] else if (computedInnerRadius == 0.0) ...[
          SizedBox(height: tokens.spacing.sp8),
          Text(
            'Square corners (clamped)',
            style: tokens.typography.labelSmall,
          ),
        ],
      ],
    );
  }
}
