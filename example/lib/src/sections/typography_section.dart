import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';
import '../common/unit_display.dart';

/// Displays the five core typography styles from the design system.
///
/// Each of the five styles (display, headline, title, body, label) is rendered
/// in its own style and labelled with name and actual font size.
class TypographySection extends StatelessWidget {
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final tokens = context.tokens;

        return ShowroomSection(
          title: 'Typography',
          description: 'Five core text styles with their actual computed font sizes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StyleRow(sample: _StyleSample('display', tokens.typography.display)),
              SizedBox(height: tokens.spacing.sp16),
              _StyleRow(sample: _StyleSample('headline', tokens.typography.headline)),
              SizedBox(height: tokens.spacing.sp16),
              _StyleRow(sample: _StyleSample('title', tokens.typography.title)),
              SizedBox(height: tokens.spacing.sp16),
              _StyleRow(sample: _StyleSample('body', tokens.typography.body)),
              SizedBox(height: tokens.spacing.sp16),
              _StyleRow(sample: _StyleSample('label', tokens.typography.label)),
            ],
          ),
        );
      },
    );
  }
}

/// A single text style sample with its label and font size.
class _StyleRow extends StatelessWidget {
  /// Creates a new [_StyleRow].
  const _StyleRow({required this.sample});

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
          width: tokens.spacing.sp48 * 2,
          child: Text(sample.name, style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
        ),

        // Rendered text sample
        Expanded(child: Text('The quick brown fox jumps over the lazy dog', style: sample.style)),

        // Font size value
        SizedBox(
          width: tokens.spacing.sp48,
          child: Align(
            alignment: Alignment.centerRight,
            child: UnitDisplay(
              value: sample.style.fontSize ?? 0,
              textStyle: tokens.typography.label.copyWith(color: tokens.colors.fg3),
            ),
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
