import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import 'sections/access_paths_section.dart';
import 'sections/alerts_section.dart';
import 'sections/borders_section.dart';
import 'sections/buttons_section.dart';
import 'sections/chips_section.dart';
import 'sections/colors_section.dart';
import 'sections/elevation_section.dart';
import 'sections/grid_section.dart';
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
    _SectionWrapper(builder: buildTypographySection),
    _SectionWrapper(builder: buildButtonsSection),
    _SectionWrapper(builder: buildAlertsSection),
    _SectionWrapper(builder: buildTooltipsSection),
    _SectionWrapper(builder: buildGridSection),
    _SectionWrapper(builder: buildMenusSection),
    _SectionWrapper(builder: buildChipsSection),
    _SectionWrapper(builder: buildTextSection),
    _SectionWrapper(builder: buildColorsSection),
    _SectionWrapper(builder: buildSpacingSection),
    _SectionWrapper(builder: buildRadiusSection),
    _SectionWrapper(builder: buildElevationSection),
    _SectionWrapper(builder: buildBordersSection),
    _SectionWrapper(builder: buildMotionSection),
    _SectionWrapper(builder: buildAccessPathsSection),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ColoredBox(
      color: tokens.colors.background,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with title and version
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp20, vertical: tokens.spacing.sp20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayrzText(kAppTitle, style: tokens.typography.display.copyWith(color: tokens.colors.primary)),
                    SizedBox(height: tokens.spacing.sp8),
                    LayrzText(
                      'Design System Showroom',
                      style: tokens.typography.title.copyWith(color: tokens.colors.fg2),
                    ),
                    SizedBox(height: tokens.spacing.sp4),
                    LayrzText(
                      'All design tokens in one place — explore the foundation',
                      style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: tokens.spacing.sp16),
                child: Container(height: 1, color: tokens.colors.divider),
              ),
            ),

            // Sections
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp20, vertical: tokens.spacing.sp20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(children: _sections),
                ),
              ),
            ),

            // Footer
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp20, vertical: tokens.spacing.sp20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 1, color: tokens.colors.divider),
                    SizedBox(height: tokens.spacing.sp16),
                    LayrzText(
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

/// A wrapper widget that builds a section with lazy initialization.
///
/// This ensures each section is only built once, even if the parent rebuilds.
class _SectionWrapper extends StatelessWidget {
  /// Creates a new [_SectionWrapper].
  const _SectionWrapper({required this.builder});

  /// The builder function that creates the section widget.
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) {
    return builder();
  }
}
