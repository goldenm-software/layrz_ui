import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';
import '../common/showroom_swatch.dart';

/// Displays all color tokens from the design system as a labelled grid.
///
/// Each color swatch shows the token name and its hex value. Text automatically
/// adapts for contrast. Includes a demonstration of the [tonalOpacity] token
/// by showing primary color at full and reduced opacity.
Widget buildColorsSection() {
  return Builder(
    builder: (context) {
      final tokens = context.tokens;

      return ShowroomSection(
        title: 'Colors',
        description: 'All semantic color tokens with hex values and contrast-aware text',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand colors
            _ColorCategory(
              title: 'Brand',
              colors: [_ColorSample('primary', tokens.colors.primary)],
            ),

            SizedBox(height: tokens.spacing.sp24),

            // Surface colors
            _ColorCategory(
              title: 'Surface',
              colors: [
                _ColorSample('background', tokens.colors.background),
                _ColorSample('surface', tokens.colors.surface),
                _ColorSample('surface2', tokens.colors.surface2),
                _ColorSample('surface3', tokens.colors.surface3),
              ],
            ),

            SizedBox(height: tokens.spacing.sp24),

            // Foreground colors
            _ColorCategory(
              title: 'Foreground / Text',
              colors: [
                _ColorSample('fg1', tokens.colors.fg1),
                _ColorSample('fg2', tokens.colors.fg2),
                _ColorSample('fg3', tokens.colors.fg3),
                _ColorSample('fg4', tokens.colors.fg4),
              ],
            ),

            SizedBox(height: tokens.spacing.sp24),

            // Semantic colors
            _ColorCategory(
              title: 'Semantic',
              colors: [
                _ColorSample('success', tokens.colors.success),
                _ColorSample('warning', tokens.colors.warning),
                _ColorSample('danger', tokens.colors.danger),
                _ColorSample('info', tokens.colors.info),
              ],
            ),

            SizedBox(height: tokens.spacing.sp24),

            // Structural colors
            _ColorCategory(
              title: 'Structural',
              colors: [
                _ColorSample('divider', tokens.colors.divider),
                _ColorSample('contextual', tokens.colors.contextual),
              ],
            ),

            SizedBox(height: tokens.spacing.sp24),

            // Overlay and tonal opacity demonstration
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overlay & Tonal Opacity', style: tokens.typography.title),
                SizedBox(height: tokens.spacing.sp12),
                Row(
                  children: [
                    Expanded(
                      child: LayrzTooltip(
                        contentText: 'overlay — ${tokens.colors.overlay.toHex()}',
                        child: _OverlaySwatch(label: 'overlay', color: tokens.colors.overlay),
                      ),
                    ),
                    SizedBox(width: tokens.spacing.sp16),
                    Expanded(
                      child: LayrzTooltip(
                        contentText: 'tonalOpacity — ${(tokens.colors.tonalOpacity * 100).toStringAsFixed(0)}%',
                        child: _TonalOpacitySwatch(tokens: tokens),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// A category of color samples grouped under a heading.
class _ColorCategory extends StatelessWidget {
  /// Creates a new [_ColorCategory].
  ///
  /// The [title] is the category name (e.g., 'Brand', 'Surface').
  /// The [colors] list contains samples to render.
  const _ColorCategory({required this.title, required this.colors});

  /// The category name.
  final String title;

  /// The list of color samples to render.
  final List<_ColorSample> colors;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp12),
        Wrap(
          spacing: tokens.spacing.sp16,
          runSpacing: tokens.spacing.sp16,
          children: colors
              .map(
                (sample) => LayrzTooltip(
                  contentText: '${sample.name} — ${sample.color.toHex()}',
                  child: ShowroomSwatch(color: sample.color, label: sample.name, value: sample.color.toHex()),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

/// A swatch demonstrating the overlay color composited over a background.
class _OverlaySwatch extends StatelessWidget {
  /// Creates a new [_OverlaySwatch].
  const _OverlaySwatch({required this.label, required this.color});

  /// The label for the swatch.
  final String label;

  /// The overlay color to display.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Swatch tile showing overlay over a background
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: tokens.colors.surface,
            borderRadius: BorderRadius.circular(tokens.radius.r8),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(tokens.radius.r8)),
          ),
        ),

        // Label
        SizedBox(height: tokens.spacing.sp8),
        Text(label, textAlign: TextAlign.center, style: tokens.typography.label),
      ],
    );
  }
}

/// A swatch demonstrating tonal opacity by showing primary color at different opacities.
class _TonalOpacitySwatch extends StatelessWidget {
  /// Creates a new [_TonalOpacitySwatch].
  const _TonalOpacitySwatch({required this.tokens});

  /// The token set containing tonal opacity and primary color.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    final fullOpacity = tokens.colors.primary;
    final tonalColor = tokens.colors.primary.withValues(alpha: tokens.colors.tonalOpacity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Side-by-side comparison
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(tokens.radius.r8)),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: fullOpacity,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(tokens.radius.r8),
                      bottomLeft: Radius.circular(tokens.radius.r8),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '100%',
                    style: tokens.typography.label.copyWith(color: fullOpacity.contrastColor, fontSize: 10),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: tonalColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(tokens.radius.r8),
                      bottomRight: Radius.circular(tokens.radius.r8),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${(tokens.colors.tonalOpacity * 100).toStringAsFixed(0)}%',
                    style: tokens.typography.label.copyWith(color: tonalColor.contrastColor, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Label
        SizedBox(height: tokens.spacing.sp8),
        Text('tonalOpacity', textAlign: TextAlign.center, style: tokens.typography.label),
      ],
    );
  }
}

/// A single color sample with name and color.
class _ColorSample {
  /// Creates a new [_ColorSample].
  const _ColorSample(this.name, this.color);

  /// The name of the color token.
  final String name;

  /// The [Color] value.
  final Color color;
}
