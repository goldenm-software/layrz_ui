import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Displays all shadow/elevation tokens as a ramp of cards with visual shadows.
///
/// Shows cards at elevation levels 0–5, plus special cases like [reverse] (shadow
/// flipped downward) and [hideOnElevationZero] to demonstrate outline behavior.
Widget buildElevationSection() {
  return Builder(
    builder: (context) {
      final tokens = context.tokens;

      return ShowroomSection(
        title: 'Elevation & Shadow',
        description: 'Shadow tokens mapped to elevation levels 0–5',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main elevation ramp
            LayrzText('Elevation Ramp (0–5)', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  6,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: tokens.spacing.sp12),
                    child: LayrzTooltip(
                      contentText: 'elevation$index shadow token',
                      child: _ElevationCard(elevation: index.toDouble(), label: 'Elevation $index'),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: tokens.spacing.sp24),

            // Special cases
            LayrzText('Special Cases', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayrzText(
                        'Elevation 0 (outline)',
                        style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                      ),
                      SizedBox(height: tokens.spacing.sp8),
                      LayrzTooltip(
                        contentText: 'elevation0 with outline border',
                        child: _ElevationCard(elevation: 0, label: '0u outline'),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: tokens.spacing.sp16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayrzText(
                        'Reversed (flipped shadow)',
                        style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                      ),
                      SizedBox(height: tokens.spacing.sp8),
                      LayrzTooltip(
                        contentText: 'elevation2 with shadow flipped downward',
                        child: _ElevationCard(elevation: 2, label: 'Reversed', reverse: true),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: tokens.spacing.sp16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayrzText(
                        'hideOnElevationZero',
                        style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                      ),
                      SizedBox(height: tokens.spacing.sp8),
                      LayrzTooltip(
                        contentText: 'elevation0 with no outline or shadow',
                        child: _ElevationCard(elevation: 0, label: 'No outline', hideOnElevationZero: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// A card demonstrating a specific elevation level.
class _ElevationCard extends StatelessWidget {
  /// Creates a new [_ElevationCard].
  ///
  /// The [elevation] should be between 0 and 5. The optional [reverse] parameter
  /// flips the shadow direction. The optional [hideOnElevationZero] hides the
  /// outline at elevation 0.
  const _ElevationCard({
    required this.elevation,
    required this.label,
    this.reverse = false,
    this.hideOnElevationZero = false,
  });

  /// The elevation level (0–5).
  final double elevation;

  /// The label to display on the card.
  final String label;

  /// Whether to flip the shadow direction.
  final bool reverse;

  /// Whether to hide the outline at elevation 0.
  final bool hideOnElevationZero;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      width: 100,
      height: 100,
      decoration: tokens.shadow.elevation(
        elevation: elevation,
        reverse: reverse,
        hideOnElevationZero: hideOnElevationZero,
      ),
      alignment: Alignment.center,
      child: LayrzText(label, textAlign: TextAlign.center, style: tokens.typography.label),
    );
  }
}
