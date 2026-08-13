import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import 'src/showroom.dart';

/// Preload the Layrz brand font and run the showroom application.
///
/// Attempts to preload the default Layrz font (Open Sans from Google Fonts)
/// to demonstrate the fonts module end-to-end. If preloading fails (e.g., offline),
/// the app degrades gracefully and opens with fallback system fonts.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Attempt to preload the Layrz brand font
  const handler = LayrzGoogleFontsHandler();
  try {
    await handler.preload(kLayrzFont);
  } catch (e) {
    // Gracefully degrade if preload fails — allow the showroom to open offline
    debugPrint('Font preload failed (likely offline): $e');
    debugPrint('Opening showroom with fallback system fonts');
  }

  runApp(const ShowroomApp(fontHandler: handler));
}

/// Root widget of the showroom application.
///
/// Wraps the [Showroom] page in a [LayrzApp] with [LayrzThemeData.light],
/// passing the font handler to ensure typography uses the preloaded fonts.
class ShowroomApp extends StatelessWidget {
  /// Creates a new [ShowroomApp].
  ///
  /// The [fontHandler] is passed to [LayrzThemeData.light] to provide
  /// font family resolution for all typography tokens.
  const ShowroomApp({required this.fontHandler, super.key});

  /// The font handler used to resolve font families in typography tokens.
  final LayrzGoogleFontsHandler fontHandler;

  @override
  Widget build(BuildContext context) {
    return LayrzApp(
      title: kAppTitle,
      theme: LayrzThemeData.light(fontHandler: fontHandler),
      home: const Showroom(),
    );
  }
}
