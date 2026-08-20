import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

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

/// The singleton go_router instance for the showroom application.
///
/// Uses a [ShellRoute] to persist the [ShowroomLayout] shell while only
/// swapping the body content during navigation. This avoids rebuilding the
/// entire layout (rail, drawer, search, notifications) on every navigation,
/// dramatically improving performance.
///
/// To revert to the original named-route implementation, replace [ShowroomApp.build]
/// with a [LayrzApp] constructor and restore the `initialRoute` + `routes` pattern.
final _router = GoRouter(
  initialLocation: '/buttons',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/buttons',
    ),
    ShellRoute(
      builder: (context, state, child) => ShowroomLayout(child: child),
      routes: [
        GoRoute(
          path: '/buttons',
          pageBuilder: (context, state) => NoTransitionPage(child: ButtonsSection()),
        ),
        GoRoute(
          path: '/button-group',
          pageBuilder: (context, state) => NoTransitionPage(child: ButtonGroupSection()),
        ),
        GoRoute(
          path: '/alerts',
          pageBuilder: (context, state) => NoTransitionPage(child: AlertsSection()),
        ),
        GoRoute(
          path: '/tooltips',
          pageBuilder: (context, state) => NoTransitionPage(child: TooltipsSection()),
        ),
        GoRoute(
          path: '/images',
          pageBuilder: (context, state) => NoTransitionPage(child: ImagesSection()),
        ),
        GoRoute(
          path: '/menus',
          pageBuilder: (context, state) => NoTransitionPage(child: MenusSection()),
        ),
        GoRoute(
          path: '/chips',
          pageBuilder: (context, state) => NoTransitionPage(child: ChipsSection()),
        ),
        GoRoute(
          path: '/text',
          pageBuilder: (context, state) => NoTransitionPage(child: TextSection()),
        ),
        GoRoute(
          path: '/inputs',
          pageBuilder: (context, state) => NoTransitionPage(child: InputsSection()),
        ),
        GoRoute(
          path: '/grid',
          pageBuilder: (context, state) => NoTransitionPage(child: GridSection()),
        ),
        GoRoute(
          path: '/typography',
          pageBuilder: (context, state) => NoTransitionPage(child: TypographySection()),
        ),
        GoRoute(
          path: '/colors',
          pageBuilder: (context, state) => NoTransitionPage(child: ColorsSection()),
        ),
        GoRoute(
          path: '/spacing',
          pageBuilder: (context, state) => NoTransitionPage(child: SpacingSection()),
        ),
        GoRoute(
          path: '/radius',
          pageBuilder: (context, state) => NoTransitionPage(child: RadiusSection()),
        ),
        GoRoute(
          path: '/elevation',
          pageBuilder: (context, state) => NoTransitionPage(child: ElevationSection()),
        ),
        GoRoute(
          path: '/borders',
          pageBuilder: (context, state) => NoTransitionPage(child: BordersSection()),
        ),
        GoRoute(
          path: '/motion',
          pageBuilder: (context, state) => NoTransitionPage(child: MotionSection()),
        ),
        GoRoute(
          path: '/access-paths',
          pageBuilder: (context, state) => NoTransitionPage(child: AccessPathsSection()),
        ),
      ],
    ),
  ],
);

/// Root widget of the showroom application.
///
/// The [LayrzThemeData.light] constructor now automatically loads and resolves
/// the Open Sans font from Google Fonts. No configuration is needed.
///
/// Uses [LayrzApp.router] with a go_router [GoRouter] configured with a [ShellRoute],
/// ensuring the application shell persists across navigation while only the body
/// content changes.
class ShowroomApp extends StatelessWidget {
  /// Creates a new [ShowroomApp].
  const ShowroomApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarBrightness: .dark,
        statusBarIconBrightness: .dark,
        systemStatusBarContrastEnforced: true,
        systemNavigationBarIconBrightness: .dark,
        systemNavigationBarContrastEnforced: true,
      ),
    );
    return LayrzApp.router(
      routerConfig: _router,
      title: kAppTitle,
      theme: LayrzThemeData.light(),
      // To view the original component showroom, uncomment:
      // home: const Showroom(),
    );
  }
}
