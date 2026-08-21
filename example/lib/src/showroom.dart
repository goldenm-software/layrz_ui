import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import 'sections/access_paths_section.dart';
import 'sections/alerts_section.dart';
import 'sections/borders_section.dart';
import 'sections/button_group_section.dart';
import 'sections/buttons_section.dart';
import 'sections/chips_section.dart';
import 'sections/colors_section.dart';
import 'sections/elevation_section.dart';
import 'sections/grid_section.dart';
import 'sections/images_section.dart';
import 'sections/inputs_section.dart';
import 'sections/menus_section.dart';
import 'sections/motion_section.dart';
import 'sections/radius_section.dart';
import 'sections/spacing_section.dart';
import 'sections/text_section.dart';
import 'sections/tooltips_section.dart';
import 'sections/typography_section.dart';

/// The main showroom page displaying all design system tokens.
///
/// A scrollable page with a responsive layout that demonstrates all token
/// categories: typography, colors, spacing, radius, elevation, borders, motion,
/// and token access paths.
///
/// **Adding new sections**: To add a new section to the showroom:
/// 1. Create a new section file under `src/sections/`
/// 2. Define a builder function `Widget buildXyzSection()`
/// 3. Add it to the `_sections` list below (the single registration point)
class Showroom extends StatelessWidget {
  /// Creates a new [Showroom].
  const Showroom({super.key});

  /// The list of section widgets to display on the showroom page.
  ///
  /// This is the **only** place sections are registered. New sections can be added
  /// by inserting their builder widgets here without modifying any other files.
  static const List<Widget> _sections = [
    TypographySection(),
    ButtonsSection(),
    ButtonGroupSection(),
    AlertsSection(),

    TooltipsSection(),
    GridSection(),
    ImagesSection(),
    MenusSection(),
    ChipsSection(),
    TextSection(),
    InputsSection(),
    ColorsSection(),
    SpacingSection(),
    RadiusSection(),
    ElevationSection(),
    BordersSection(),
    MotionSection(),
    AccessPathsSection(),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ColoredBox(
      color: tokens.colors.sf1,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with title and version
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp4, vertical: tokens.spacing.sp4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kAppTitle, style: tokens.typography.display.copyWith(color: tokens.colors.primary)),
                    SizedBox(height: tokens.spacing.sp2),
                    Text(
                      'Design System Showroom',
                      style: tokens.typography.title.copyWith(color: tokens.colors.fg2),
                    ),
                    SizedBox(height: tokens.spacing.sp1),
                    Text(
                      'All design tokens in one place — explore the foundation',
                      style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: tokens.spacing.sp3),
                child: Container(height: 1, color: tokens.colors.divider),
              ),
            ),

            // Sections
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp4, vertical: tokens.spacing.sp4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(children: _sections),
                ),
              ),
            ),

            // Footer
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp4, vertical: tokens.spacing.sp4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 1, color: tokens.colors.divider),
                    SizedBox(height: tokens.spacing.sp3),
                    Text(
                      'Built with layrz_ui — a Material-free Flutter design system',
                      style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
