import 'package:flutter/widgets.dart';
import 'package:layrz_ui/alerts.dart';
import 'package:layrz_ui/extensions.dart';
import 'package:layrz_ui/grid.dart';
import 'package:layrz_ui/tokens.dart';
import 'package:layrz_icons/layrz_icons.dart';

import '../common/showroom_section.dart';

/// Displays all [LayrzAlert] styles, types, configurations, and the [LayrzAlertIcon] standalone chip.
///
/// Demonstrates the matrix of 5 styles × 6 types (30 combinations), variable maxLines
/// truncation, custom type with explicit color and icon, and the reusable [LayrzAlertIcon]
/// at different sizes.
Widget buildAlertsSection() {
  return Builder(
    builder: (context) {
      return const _AlertsSectionContent();
    },
  );
}

/// The content widget for the alerts section.
///
/// Shows multiple demo subsections illustrating alert styles, types, configurations,
/// and the standalone icon chip.
class _AlertsSectionContent extends StatelessWidget {
  /// Creates a new [_AlertsSectionContent].
  const _AlertsSectionContent();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Alerts',
      description: 'Material-free alert component with five styles, six semantic types, and a standalone icon chip',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Styles × Types grid
          _StylesAndTypesDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 2. maxLines truncation demo
          _MaxLinesDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 3. Custom type with explicit color and icon
          _CustomTypeDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 4. Standalone [LayrzAlertIcon] at different sizes
          _AlertIconDemo(tokens: tokens),
        ],
      ),
    );
  }
}

/// Demonstrates all 5 [LayrzAlertStyle] values × 6 [LayrzAlertType] values (30 combinations).
///
/// Organized with style as the outer grouping and type as the inner grouping,
/// showing each combination with a short description.
class _StylesAndTypesDemo extends StatelessWidget {
  /// Creates a new [_StylesAndTypesDemo].
  const _StylesAndTypesDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    final styles = LayrzAlertStyle.values;
    final types = LayrzAlertType.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All Styles × Types (5 × 6 = 30 Combinations)', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'Organized by style (outer group) and type (inner). The style controls visual appearance; '
          'the type controls semantic color and icon.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp16),
        // Generate a column for each style
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp24,
          children: styles.map((style) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp12,
              children: [
                Text(
                  'Style: ${style.toString().split('.').last}',
                  style: tokens.typography.labelLarge.copyWith(color: tokens.colors.fg1),
                ),
                // Grid of types within this style
                _buildTypeGrid(style, types, tokens),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Builds a responsive grid of alert cards for a given style across all types.
  Widget _buildTypeGrid(LayrzAlertStyle style, List<LayrzAlertType> types, LayrzTokens tokens) {
    return LayrzRow(
      spacing: tokens.spacing.sp12,
      children: types.map((type) {
        return LayrzCol(
          xs: 12,
          sm: 6,
          md: 4,
          lg: 2,
          child: LayrzAlert(
            type: type,
            title: type.toString().split('.').last.toUpperCase(),
            description: 'This is a ${style.toString().split('.').last} ${type.toString().split('.').last} alert.',
            style: style,
          ),
        );
      }).toList(),
    );
  }
}

/// Demonstrates the [maxLines] parameter with 1 line and 3 lines.
///
/// Shows how descriptions truncate and ellipsize when they exceed the line limit.
class _MaxLinesDemo extends StatelessWidget {
  /// Creates a new [_MaxLinesDemo].
  const _MaxLinesDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    const longDescription =
        'This is a longer description that would normally wrap across multiple lines in the alert. '
        'With maxLines: 1, it truncates immediately; with maxLines: 3, it allows up to three lines before '
        'ellipsis. This demonstrates how the alert container constrains text overflow.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('maxLines Truncation', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'Left: maxLines = 1 (single line, ellipsis). Right: maxLines = 3 (default).',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp16),
        Row(
          spacing: tokens.spacing.sp12,
          children: [
            // maxLines: 1
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.spacing.sp8,
                children: [
                  Text('maxLines: 1', style: tokens.typography.labelMedium),
                  LayrzAlert(
                    type: LayrzAlertType.info,
                    title: 'Single Line',
                    description: longDescription,
                    maxLines: 1,
                    style: LayrzAlertStyle.layrz,
                  ),
                ],
              ),
            ),
            // maxLines: 3 (default)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.spacing.sp8,
                children: [
                  Text('maxLines: 3', style: tokens.typography.labelMedium),
                  LayrzAlert(
                    type: LayrzAlertType.info,
                    title: 'Multi-Line',
                    description: longDescription,
                    maxLines: 3,
                    style: LayrzAlertStyle.layrz,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates [LayrzAlertType.custom] with explicit [color] and [icon] parameters.
///
/// Shows how custom types allow full control over the semantic color and icon
/// while using any [LayrzAlertStyle].
class _CustomTypeDemo extends StatelessWidget {
  /// Creates a new [_CustomTypeDemo].
  const _CustomTypeDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Custom Type', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'When type is custom, the color and icon parameters are honored. '
          'This example shows a custom alert with a purple accent and a star icon.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp16),
        LayrzAlert(
          type: LayrzAlertType.custom,
          title: 'Custom Alert',
          description: 'This alert uses a custom color and icon specified in the constructor.',
          style: LayrzAlertStyle.layrz,
          color: const Color(0xFF9C27B0), // Purple
          icon: LayrzIcons.solarOutlineCheckSquare,
        ),
      ],
    );
  }
}

/// Demonstrates the standalone [LayrzAlertIcon] widget at different sizes.
///
/// Shows the icon chip at various dimensions, demonstrating how it scales
/// and can be used independently from [LayrzAlert].
class _AlertIconDemo extends StatelessWidget {
  /// Creates a new [_AlertIconDemo].
  const _AlertIconDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Standalone Alert Icon', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'The [LayrzAlertIcon] widget is a reusable circular icon chip that can be '
          'placed independently. Shown here at three different sizes.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp16),
        // Row of icons at different sizes
        Row(
          spacing: tokens.spacing.sp24,
          children: [
            // Small
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp8,
              children: [
                Text('Small (24)', style: tokens.typography.labelMedium),
                Row(
                  spacing: tokens.spacing.sp8,
                  children: [
                    LayrzAlertIcon(
                      type: LayrzAlertType.info,
                      size: 24,
                      iconSize: 16,
                    ),
                    LayrzAlertIcon(
                      type: LayrzAlertType.success,
                      size: 24,
                      iconSize: 16,
                    ),
                    LayrzAlertIcon(
                      type: LayrzAlertType.warning,
                      size: 24,
                      iconSize: 16,
                    ),
                    LayrzAlertIcon(
                      type: LayrzAlertType.danger,
                      size: 24,
                      iconSize: 16,
                    ),
                  ],
                ),
              ],
            ),
            // Medium
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp8,
              children: [
                Text('Medium (40)', style: tokens.typography.labelMedium),
                Row(
                  spacing: tokens.spacing.sp8,
                  children: [
                    LayrzAlertIcon(
                      type: LayrzAlertType.info,
                      size: 40,
                      iconSize: 24,
                    ),
                    LayrzAlertIcon(
                      type: LayrzAlertType.success,
                      size: 40,
                      iconSize: 24,
                    ),
                    LayrzAlertIcon(
                      type: LayrzAlertType.warning,
                      size: 40,
                      iconSize: 24,
                    ),
                    LayrzAlertIcon(
                      type: LayrzAlertType.danger,
                      size: 40,
                      iconSize: 24,
                    ),
                  ],
                ),
              ],
            ),
            // Large
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp8,
              children: [
                Text('Large (56)', style: tokens.typography.labelMedium),
                Row(
                  spacing: tokens.spacing.sp8,
                  children: [
                    LayrzAlertIcon(
                      type: LayrzAlertType.info,
                      size: 56,
                      iconSize: 32,
                    ),
                    LayrzAlertIcon(
                      type: LayrzAlertType.success,
                      size: 56,
                      iconSize: 32,
                    ),
                    LayrzAlertIcon(
                      type: LayrzAlertType.warning,
                      size: 56,
                      iconSize: 32,
                    ),
                    LayrzAlertIcon(
                      type: LayrzAlertType.danger,
                      size: 56,
                      iconSize: 32,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
