import 'package:layrz_ui/fonts.dart';

/// A test fake of [LayrzFontHandler] that returns font names without network calls.
///
/// This handler is used in unit tests to avoid hitting Google Fonts during test runs.
/// It simply returns the font name verbatim from [resolveFamily] and uses the standard
/// layrz fallback families, making it suitable for pure logic testing where typography
/// resolution does not need to verify actual font loading.
class FakeFontHandler implements LayrzFontHandler {
  /// Creates a new [FakeFontHandler].
  const FakeFontHandler();

  @override
  Future<void> preload(LayrzFont font) async {
    // No-op: tests don't need to actually load fonts
  }

  @override
  String resolveFamily(LayrzFont font) {
    // Return the font name directly without any resolution
    return font.name;
  }

  @override
  List<String> get fallbacks => kLayrzFontFallbacks;
}
