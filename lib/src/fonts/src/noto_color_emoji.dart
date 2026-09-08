import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/fonts/fonts.dart';

/// A Noto Color Emoji font implementation using a bundled COLR/CPAL font asset.
///
/// This font is not selected as a text style's primary family by any component;
/// it exists purely to supply glyphs the design system's other fonts lack —
/// colour emoji — via [TextStyle.fontFamilyFallback]. [LayrzTextTheme.defaults]
/// registers it unconditionally, alongside whatever [LayrzFont] the caller chose,
/// and appends `'Noto Color Emoji'` to every text style's fallback list so any
/// emoji codepoint renders in full colour instead of falling back to a
/// monochrome tofu glyph or a missing-character box.
///
/// The font is declared in `pubspec.yaml` under `flutter: fonts:` and is
/// registered by Flutter at startup, so [load] is a no-op — bundled fonts need
/// no explicit fetch or [FontLoader] call. [registerOnWeb] still does real work:
/// it registers a browser `@font-face` from the bundled asset's bytes so
/// DOM-rendered text (e.g. the web login fields) can also fall back to colour
/// emoji, matching what the Flutter canvas already does via the pubspec
/// declaration.
class LayrzNotoColorEmojiFont extends LayrzFont {
  /// Creates a new [LayrzNotoColorEmojiFont].
  const LayrzNotoColorEmojiFont() : super(name: 'Noto Color Emoji');

  @override
  Future<void> load() async {
    // Bundled fonts are registered by the Flutter engine at startup,
    // so there is nothing to load. This method completes immediately.
  }

  @override
  Future<void> registerOnWeb() async {
    final bytes = await rootBundle.load('packages/layrz_ui/assets/NotoColorEmoji-Regular.ttf');
    await registerWebFontFromBytes(family: name, bytes: bytes);
  }

  @override
  TextStyle get display => const TextStyle(
    fontFamily: 'Noto Color Emoji',
    fontWeight: FontWeight.w400,
  );

  @override
  TextStyle get headline => const TextStyle(
    fontFamily: 'Noto Color Emoji',
    fontWeight: FontWeight.w400,
  );

  @override
  TextStyle get title => const TextStyle(
    fontFamily: 'Noto Color Emoji',
    fontWeight: FontWeight.w400,
  );

  @override
  TextStyle get body => const TextStyle(
    fontFamily: 'Noto Color Emoji',
    fontWeight: FontWeight.w400,
  );

  @override
  TextStyle get label => const TextStyle(
    fontFamily: 'Noto Color Emoji',
    fontWeight: FontWeight.w400,
  );
}
