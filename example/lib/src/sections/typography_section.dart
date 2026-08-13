import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Displays all 15 typography styles from the design system.
///
/// Organized by category (display, headline, title, body, label), each style
/// is rendered in its own style and labelled with name and actual font size.
Widget buildTypographySection() {
  return Builder(
    builder: (context) {
      final tokens = context.tokens;

      return ShowroomSection(
        title: 'Typography',
        description: 'All text styles with their actual computed font sizes',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display styles
            _TypographyCategory(
              title: 'Display',
              styles: [
                _StyleSample('displayLarge', tokens.typography.displayLarge),
                _StyleSample('displayMedium', tokens.typography.displayMedium),
                _StyleSample('displaySmall', tokens.typography.displaySmall),
              ],
            ),

            SizedBox(height: tokens.spacing.sp24),

            // Headline styles
            _TypographyCategory(
              title: 'Headline',
              styles: [
                _StyleSample('headlineLarge', tokens.typography.headlineLarge),
                _StyleSample('headlineMedium', tokens.typography.headlineMedium),
                _StyleSample('headlineSmall', tokens.typography.headlineSmall),
              ],
            ),

            SizedBox(height: tokens.spacing.sp24),

            // Title styles
            _TypographyCategory(
              title: 'Title',
              styles: [
                _StyleSample('titleLarge', tokens.typography.titleLarge),
                _StyleSample('titleMedium', tokens.typography.titleMedium),
                _StyleSample('titleSmall', tokens.typography.titleSmall),
              ],
            ),

            SizedBox(height: tokens.spacing.sp24),

            // Body styles
            _TypographyCategory(
              title: 'Body',
              styles: [
                _StyleSample('bodyLarge', tokens.typography.bodyLarge),
                _StyleSample('bodyMedium', tokens.typography.bodyMedium),
                _StyleSample('bodySmall', tokens.typography.bodySmall),
              ],
            ),

            SizedBox(height: tokens.spacing.sp24),

            // Label styles
            _TypographyCategory(
              title: 'Label',
              styles: [
                _StyleSample('labelLarge', tokens.typography.labelLarge),
                _StyleSample('labelMedium', tokens.typography.labelMedium),
                _StyleSample('labelSmall', tokens.typography.labelSmall),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// A category of text styles grouped under a heading.
class _TypographyCategory extends StatelessWidget {
  /// Creates a new [_TypographyCategory].
  ///
  /// The [title] is the category name (e.g., 'Display', 'Body').
  /// The [styles] list contains samples to render.
  // ignore: unused_element_parameter
  const _TypographyCategory({required this.title, required this.styles, super.key});

  /// The category name.
  final String title;

  /// The list of style samples to render.
  final List<_StyleSample> styles;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: styles
              .map(
                (sample) => Padding(
                  padding: EdgeInsets.only(bottom: tokens.spacing.sp12),
                  child: _StyleRow(sample: sample),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

/// A single text style sample with its label and font size.
class _StyleRow extends StatelessWidget {
  /// Creates a new [_StyleRow].
  // ignore: unused_element_parameter
  const _StyleRow({required this.sample, super.key});

  /// The style sample to render.
  final _StyleSample sample;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Style name label
        SizedBox(
          width: 120,
          child: Text(sample.name, style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3)),
        ),

        // Rendered text sample
        Expanded(child: Text('The quick brown fox', style: sample.style)),

        // Font size value
        SizedBox(
          width: 60,
          child: Text(
            '${sample.style.fontSize?.toStringAsFixed(0)} px',
            textAlign: TextAlign.right,
            style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3),
          ),
        ),
      ],
    );
  }
}

/// A single text style sample with name and style.
class _StyleSample {
  /// Creates a new [_StyleSample].
  const _StyleSample(this.name, this.style);

  /// The name of the style.
  final String name;

  /// The [TextStyle] to render.
  final TextStyle style;
}
