import 'package:flutter/widgets.dart';

import 'package:layrz_ui/layrz_ui.dart';

import 'layout.dart';
import 'src/sections/access_paths_section.dart';
import 'src/sections/alerts_section.dart';
import 'src/sections/borders_section.dart';
import 'src/sections/button_group_section.dart';
import 'src/sections/buttons_section.dart';
import 'src/sections/chips_section.dart';
import 'src/sections/colors_section.dart';
import 'src/sections/elevation_section.dart';
import 'src/sections/grid_section.dart';
import 'src/sections/images_section.dart';
import 'src/sections/inputs_section.dart';
import 'src/sections/menus_section.dart';
import 'src/sections/motion_section.dart';
import 'src/sections/radius_section.dart';
import 'src/sections/spacing_section.dart';
import 'src/sections/text_section.dart';
import 'src/sections/tooltips_section.dart';
import 'src/sections/typography_section.dart';

/// Run the showroom application with mandatory font loading.
///
/// [LayrzThemeData.light] now requires no configuration — it automatically loads
/// the default 'Open Sans' font from Google Fonts. The optional preload demonstrates
/// how to avoid first-frame flashing by eagerly fetching the font before `runApp()`.
/// If preloading fails (e.g., offline), the app degrades gracefully and opens with
/// fallback fonts.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional: preload the default Layrz font to avoid first-frame flashing.
  // This is entirely optional — the font will load either way when the theme is constructed.
  try {
    await LayrzThemeData.preloadFont();
  } catch (e) {
    // Gracefully degrade if preload fails — allow the showroom to open offline
    debugPrint('Font preload failed (likely offline): $e');
    debugPrint('Opening showroom with fallback system fonts');
  }

  runApp(const ShowroomApp());
}

/// Root widget of the showroom application.
///
/// The [LayrzThemeData.light] constructor now automatically loads and resolves
/// the Open Sans font from Google Fonts. No configuration is needed.
class ShowroomApp extends StatelessWidget {
  /// Creates a new [ShowroomApp].
  const ShowroomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayrzApp(
      title: kAppTitle,
      theme: LayrzThemeData.light(),
      initialRoute: '/buttons',
      routes: {
        '/buttons': (_) => ShowroomLayout(child: buildButtonsSection()),
        '/button-group': (_) => ShowroomLayout(child: buildButtonGroupSection()),
        '/alerts': (_) => ShowroomLayout(child: buildAlertsSection()),
        '/tooltips': (_) => ShowroomLayout(child: buildTooltipsSection()),
        '/images': (_) => ShowroomLayout(child: buildImagesSection()),
        '/menus': (_) => ShowroomLayout(child: buildMenusSection()),
        '/chips': (_) => ShowroomLayout(child: buildChipsSection()),
        '/text': (_) => ShowroomLayout(child: buildTextSection()),
        '/inputs': (_) => ShowroomLayout(child: buildInputsSection()),
        '/grid': (_) => ShowroomLayout(child: buildGridSection()),
        '/typography': (_) => ShowroomLayout(child: buildTypographySection()),
        '/colors': (_) => ShowroomLayout(child: buildColorsSection()),
        '/spacing': (_) => ShowroomLayout(child: buildSpacingSection()),
        '/radius': (_) => ShowroomLayout(child: buildRadiusSection()),
        '/elevation': (_) => ShowroomLayout(child: buildElevationSection()),
        '/borders': (_) => ShowroomLayout(child: buildBordersSection()),
        '/motion': (_) => ShowroomLayout(child: buildMotionSection()),
        '/access-paths': (_) => ShowroomLayout(child: buildAccessPathsSection()),
      },
      // To view the original component showroom, uncomment:
      // home: const Showroom(),
    );
  }
}
