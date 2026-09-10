import 'package:example/fonts/fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:layrz_ui/layrz_ui.dart';

// TEMPORARY: DESIGN-109 find-in-page spike route. Dev-only — reachable by direct URL
// (/find-spike) but intentionally not listed in the showroom sidebar.
import 'src/sections/find_in_page/find_spike.dart';

import 'layout.dart';
import 'src/providers/theme_mode_provider.dart';
import 'src/sections/access_paths_section.dart';
import 'src/sections/accordion_section.dart';
import 'src/sections/ai_marker_section.dart';
import 'src/sections/alerts_section.dart';
import 'src/sections/app_banner_section.dart';
import 'src/sections/badge_section.dart';
import 'src/sections/borders_section.dart';
import 'src/sections/button_group_section.dart';
import 'src/sections/buttons_section.dart';
import 'src/sections/calendar_section.dart';
import 'src/sections/cards_section.dart';
import 'src/sections/chips_section.dart';
import 'src/sections/code_section.dart';
import 'src/sections/colors_section.dart';
import 'src/sections/connection_indicator_section.dart';
import 'src/sections/context_menu_section.dart';
import 'src/sections/dialogs_section.dart';
import 'src/sections/elevation_section.dart';
import 'src/sections/file_input_section.dart';
import 'src/sections/form_section.dart';
import 'src/sections/grid_section.dart';
import 'src/sections/home_section.dart';
import 'src/sections/images_section.dart';
import 'src/sections/inputs_section.dart';
import 'src/sections/layo_section.dart';
import 'src/sections/markdown_section.dart';
import 'src/sections/menus_section.dart';
import 'src/sections/motion_section.dart';
import 'src/sections/pickers/pickers_section.dart';
import 'src/sections/progress_section.dart';
import 'src/sections/radius_section.dart';
import 'src/sections/refresh_section.dart';
import 'src/sections/responsive_modal_section.dart';
import 'src/sections/scaffold_shell_section.dart';
import 'src/sections/sheets_section.dart';
import 'src/sections/skeleton_section.dart';
import 'src/sections/snackbar_section.dart';
import 'src/sections/spacing_section.dart';
import 'src/sections/steppers_section.dart';
import 'src/sections/tab_view_section.dart';
import 'src/sections/table_section.dart';
import 'src/sections/text_section.dart';
import 'src/sections/timeline_section.dart';
import 'src/sections/tooltips_section.dart';
import 'src/sections/transitions_section.dart';
import 'src/sections/tree_view_section.dart';
import 'src/sections/workspace_tabs_section.dart';
import 'src/sections/typography_section.dart';

/// Run the showroom application with Open Sans font.
///
/// The Open Sans font is loaded before the app starts. This demonstrates
/// the correct startup shape for consumers who use a custom font that
/// requires loading (e.g., from a network source). In this case, the font
/// is bundled in assets and loaded immediately by the engine, so [load]
/// completes without I/O.
///
/// Note there is no `font.registerOnWeb()` call here: the theme constructor
/// ([LayrzThemeData.light], via [LayrzTokens.light] and [LayrzTextTheme.defaults])
/// calls it automatically once [font] reaches `ShowroomApp`'s `LayrzThemeData.light`
/// below, so DOM-rendered content (e.g. layrz_ui's web login fields) picks up the
/// font with no extra step from consumer code. `OpenSansFont` and `FiraSansFont` are
/// bundled assets, so their `registerOnWeb` is the inherited no-op; swap in
/// `NotoSansFont` (URL-based) below to see it actually register a browser
/// `@font-face`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final font = const OpenSansFont();
  // final font = const DoppioOneFont();
  await font.load();
  runApp(ProviderScope(child: ShowroomApp(font: font)));
}

/// Builds a [CustomTransitionPage] using [LayrzPageTransitions.fade] at the
/// design system's own page-transition duration ([LayrzPageTransitions.durationOf]).
///
/// Every showroom route's `pageBuilder` delegates to this helper so the whole
/// shell animates consistently on navigation, without repeating the same
/// three-line [CustomTransitionPage] construction at every [GoRoute].
CustomTransitionPage<void> _fadePage(BuildContext context, Widget child) => CustomTransitionPage<void>(
  child: child,
  transitionsBuilder: LayrzPageTransitions.fade,
  transitionDuration: LayrzPageTransitions.durationOf(context),
);

/// The singleton go_router instance for the showroom application.
///
/// Uses a [ShellRoute] to persist the [ShowroomLayout] shell while only
/// swapping the body content during navigation. This avoids rebuilding the
/// entire layout (rail, drawer, search, notifications) on every navigation,
/// dramatically improving performance.
///
/// Every route's `pageBuilder` returns a [CustomTransitionPage] built via the
/// [_fadePage] helper, which always uses [LayrzPageTransitions.fade] at
/// [LayrzPageTransitions.durationOf]'s duration — so the whole showroom
/// animates consistently on navigation. See the dedicated `/transitions` page
/// (built on [TransitionsSection]) to see every other builder, including
/// [LayrzPageTransitions.slide], [LayrzPageTransitions.scale],
/// [LayrzPageTransitions.rotation], and [LayrzPageTransitions.none], driven
/// interactively.
///
/// To revert to the original named-route implementation, replace [ShowroomApp.build]
/// with a [LayrzApp] constructor and restore the `initialRoute` + `routes` pattern.
final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/home',
    ),
    ShellRoute(
      builder: (context, state, child) => ShowroomLayout(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => _fadePage(context, HomeSection()),
        ),
        GoRoute(
          path: '/buttons',
          pageBuilder: (context, state) => _fadePage(context, ButtonsSection()),
        ),
        GoRoute(
          path: '/button-group',
          pageBuilder: (context, state) => _fadePage(context, ButtonGroupSection()),
        ),
        GoRoute(
          path: '/alerts',
          pageBuilder: (context, state) => _fadePage(context, AlertsSection()),
        ),
        GoRoute(
          path: '/tooltips',
          pageBuilder: (context, state) => _fadePage(context, TooltipsSection()),
        ),
        GoRoute(
          path: '/images',
          pageBuilder: (context, state) => _fadePage(context, ImagesSection()),
        ),
        GoRoute(
          path: '/menus',
          pageBuilder: (context, state) => _fadePage(context, MenusSection()),
        ),
        GoRoute(
          path: '/chips',
          pageBuilder: (context, state) => _fadePage(context, ChipsSection()),
        ),
        GoRoute(
          path: '/text',
          pageBuilder: (context, state) => _fadePage(context, TextSection()),
        ),
        GoRoute(
          path: '/inputs',
          pageBuilder: (context, state) => _fadePage(context, InputsSection()),
        ),
        GoRoute(
          path: '/pickers',
          pageBuilder: (context, state) => _fadePage(context, PickersSection()),
        ),
        GoRoute(
          path: '/grid',
          pageBuilder: (context, state) => _fadePage(context, GridSection()),
        ),
        GoRoute(
          path: '/context-menu',
          pageBuilder: (context, state) => _fadePage(context, ContextMenuSection()),
        ),
        GoRoute(
          path: '/dialogs',
          pageBuilder: (context, state) => _fadePage(context, DialogsSection()),
        ),
        GoRoute(
          path: '/responsive-modal',
          pageBuilder: (context, state) => _fadePage(context, ResponsiveModalSection()),
        ),
        GoRoute(
          path: '/sheets',
          pageBuilder: (context, state) => _fadePage(context, SheetsSection()),
        ),
        GoRoute(
          path: '/steppers',
          pageBuilder: (context, state) => _fadePage(context, StepperSection()),
        ),
        GoRoute(
          path: '/typography',
          pageBuilder: (context, state) => _fadePage(context, TypographySection()),
        ),
        GoRoute(
          path: '/colors',
          pageBuilder: (context, state) => _fadePage(context, ColorsSection()),
        ),
        GoRoute(
          path: '/spacing',
          pageBuilder: (context, state) => _fadePage(context, SpacingSection()),
        ),
        GoRoute(
          path: '/radius',
          pageBuilder: (context, state) => _fadePage(context, RadiusSection()),
        ),
        GoRoute(
          path: '/elevation',
          pageBuilder: (context, state) => _fadePage(context, ElevationSection()),
        ),
        GoRoute(
          path: '/borders',
          pageBuilder: (context, state) => _fadePage(context, BordersSection()),
        ),
        GoRoute(
          path: '/motion',
          pageBuilder: (context, state) => _fadePage(context, MotionSection()),
        ),
        GoRoute(
          path: '/access-paths',
          pageBuilder: (context, state) => _fadePage(context, AccessPathsSection()),
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) => _fadePage(context, CalendarSection()),
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (context, state) => _fadePage(context, ProgressSection()),
        ),
        GoRoute(
          path: '/timeline',
          pageBuilder: (context, state) => _fadePage(context, TimelineSection()),
        ),
        GoRoute(
          path: '/tree-view',
          pageBuilder: (context, state) => _fadePage(context, TreeViewSection()),
        ),
        GoRoute(
          path: '/badges',
          pageBuilder: (context, state) => _fadePage(context, BadgeSection()),
        ),
        GoRoute(
          path: '/connection-indicator',
          pageBuilder: (context, state) => _fadePage(context, ConnectionIndicatorSection()),
        ),
        GoRoute(
          path: '/transitions',
          pageBuilder: (context, state) => _fadePage(context, TransitionsSection()),
        ),
        GoRoute(
          path: '/refresh',
          pageBuilder: (context, state) => _fadePage(context, RefreshSection()),
        ),
        GoRoute(
          path: '/snackbar',
          pageBuilder: (context, state) => _fadePage(context, SnackbarSection()),
        ),
        GoRoute(
          path: '/accordion',
          pageBuilder: (context, state) => _fadePage(context, AccordionSection()),
        ),
        GoRoute(
          path: '/ai-marker',
          pageBuilder: (context, state) => _fadePage(context, AiMarkerSection()),
        ),
        GoRoute(
          path: '/skeleton',
          pageBuilder: (context, state) => _fadePage(context, SkeletonSection()),
        ),
        GoRoute(
          path: '/form',
          pageBuilder: (context, state) => _fadePage(context, FormSection()),
        ),
        GoRoute(
          path: '/file-input',
          pageBuilder: (context, state) => _fadePage(context, FileInputSection()),
        ),
        GoRoute(
          path: '/layo',
          pageBuilder: (context, state) => _fadePage(context, LayoSection()),
        ),
        GoRoute(
          path: '/markdown',
          pageBuilder: (context, state) => _fadePage(context, MarkdownSection()),
        ),
        GoRoute(
          path: '/tab-view',
          pageBuilder: (context, state) => _fadePage(context, TabViewSection()),
        ),
        GoRoute(
          path: '/app-banner',
          pageBuilder: (context, state) => _fadePage(context, AppBannerSection()),
        ),
        GoRoute(
          path: '/table',
          pageBuilder: (context, state) => _fadePage(context, TableSection()),
        ),
        GoRoute(
          path: '/workspace-tabs',
          pageBuilder: (context, state) => _fadePage(context, WorkspaceTabsSection()),
        ),
        GoRoute(
          path: '/code',
          pageBuilder: (context, state) => _fadePage(context, CodeSection()),
        ),
        GoRoute(
          path: '/cards',
          pageBuilder: (context, state) => _fadePage(context, CardsSection()),
        ),
        GoRoute(
          path: '/scaffold-shell',
          pageBuilder: (context, state) => _fadePage(context, ScaffoldShellSection()),
        ),
        // TEMPORARY: DESIGN-109 find-in-page spike route. Dev-only — reachable by direct URL
        // (/find-spike) but intentionally not listed in the showroom sidebar.
        GoRoute(
          path: '/find-spike',
          pageBuilder: (context, state) => _fadePage(context, LayrzFindSpike()),
        ),
      ],
    ),
  ],
);

/// Root widget of the showroom application.
///
/// The theme uses the provided custom font (Open Sans from bundled assets).
/// Consumers can provide any [LayrzFont] implementation — bundled fonts like this
/// one, fonts fetched from a CDN, or fonts loaded from network sources via
/// [layrz_ui_extensions].
///
/// Uses [LayrzApp.router] with a go_router [GoRouter] configured with a [ShellRoute],
/// ensuring the application shell persists across navigation while only the body
/// content changes.
///
/// Reads [themeModeProvider] to decide which of [LayrzThemeData.light] and
/// [LayrzThemeData.dark] is active, and re-evaluates the system status/navigation
/// bar overlay style every time that mode changes.
class ShowroomApp extends ConsumerWidget {
  /// Creates a new [ShowroomApp].
  ///
  /// The [font] parameter specifies which font to use in the theme. It must be
  /// loaded before this widget is built (typically in [main] before [runApp]).
  const ShowroomApp({
    required this.font,
    super.key,
  });

  /// The custom font to use in the theme.
  final LayrzFont font;

  /// Resolves the effective [Brightness] for [mode] against the platform's
  /// current brightness, then applies the matching system overlay style —
  /// light icons over a dark effective brightness, dark icons over a light one.
  void _applySystemOverlayStyle(BuildContext context, LayrzThemeMode mode) {
    final isDark = switch (mode) {
      LayrzThemeMode.light => false,
      LayrzThemeMode.dark => true,
      LayrzThemeMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarBrightness: LayrzPlatform.isIOS ? .light : iconBrightness,
        statusBarIconBrightness: LayrzPlatform.isIOS ? .light : iconBrightness,
        systemStatusBarContrastEnforced: true,
        systemNavigationBarIconBrightness: LayrzPlatform.isIOS ? .light : iconBrightness,
        systemNavigationBarContrastEnforced: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    _applySystemOverlayStyle(context, mode);
    return LayrzApp.router(
      routerConfig: _router,
      title: kAppTitle,
      theme: LayrzThemeData.light(
        font: font,
        // primaryColor: LayrzColors.cyan,
      ),
      darkTheme: LayrzThemeData.dark(font: font),
      themeMode: mode,
      // To view the original component showroom, uncomment:
      // home: const Showroom(),
    );
  }
}
