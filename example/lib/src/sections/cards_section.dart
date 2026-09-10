import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Showcases [LayrzCard] variants in the layrz_ui design system.
///
/// Demonstrates the discrete elevation ramp (1–5), custom background colors,
/// an inert (non-interactive) card versus a tappable one, and a card composed
/// with real title + body content.
class CardsSection extends StatelessWidget {
  /// Creates a new [CardsSection].
  const CardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Cards',
      description: 'LayrzCard — an elevated surface container with a discrete elevation ramp (1-5).',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Elevation Ramp (1–5)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(5, (index) {
                final elevation = index + 1;
                return Padding(
                  padding: EdgeInsets.only(right: tokens.spacing.sp3),
                  child: SizedBox(
                    width: 140,
                    child: LayrzCard(
                      elevation: elevation,
                      child: Text('Elevation $elevation', style: tokens.typography.body),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Background Color', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          LayrzRow(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.spacing.sp3,
            children: [
              LayrzCol(
                xs: 12,
                sm: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default (surface token)',
                      style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                    ),
                    SizedBox(height: tokens.spacing.sp2),
                    LayrzCard(
                      elevation: 2,
                      child: Text('Default background', style: tokens.typography.body),
                    ),
                  ],
                ),
              ),
              LayrzCol(
                xs: 12,
                sm: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom backgroundColor',
                      style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                    ),
                    SizedBox(height: tokens.spacing.sp2),
                    LayrzCard(
                      elevation: 2,
                      backgroundColor: tokens.colors.primary.withValues(alpha: 0.1),
                      child: Text(
                        'Tinted background',
                        style: tokens.typography.body.copyWith(color: tokens.colors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Interactive vs. Inert', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          LayrzRow(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.spacing.sp3,
            children: [
              LayrzCol(
                xs: 12,
                sm: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'onTap: null (inert)',
                      style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                    ),
                    SizedBox(height: tokens.spacing.sp2),
                    LayrzCard(
                      elevation: 1,
                      child: Text('No hover/press feedback', style: tokens.typography.body),
                    ),
                  ],
                ),
              ),
              LayrzCol(
                xs: 12,
                sm: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'onTap provided (interactive)',
                      style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                    ),
                    SizedBox(height: tokens.spacing.sp2),
                    LayrzCard(
                      elevation: 1,
                      onTap: () => debugPrint('Card tapped'),
                      child: Text('Hover, press, focus me', style: tokens.typography.body),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Real Content', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          LayrzCard(
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Card Title', style: tokens.typography.title),
                SizedBox(height: tokens.spacing.sp2),
                Text(
                  'A card can hold any composed content, such as a title paired with a longer '
                  'body of descriptive text, exactly as it would appear in a real dashboard or '
                  'summary view.',
                  style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
