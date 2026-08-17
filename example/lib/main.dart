import 'package:flutter/widgets.dart';

import 'package:layrz_ui/layrz_ui.dart';

import 'src/showroom.dart';

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
      home: const Showroom(),
    );
  }
}
