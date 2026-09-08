import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/fonts/fonts.dart';

/// A JetBrains Mono font implementation using a bundled variable font asset.
///
/// This font is pre-loaded for future code/monospace UI (diagnostics, JSON or
/// script previews, tokens) that does not exist yet. No component currently
/// selects it as a [LayrzFont]; it is registered so the family `'JetBrains Mono'`
/// is available to both the engine and the DOM the moment it is needed, without
/// requiring a later asset-declaration change. It is deliberately **not** added
/// to any text style's [TextStyle.fontFamilyFallback] — it is a distinct family
/// selected explicitly by a future monospace consumer, not a fallback for
/// missing glyphs the way `Noto Color Emoji` is.
///
/// The font is declared in `pubspec.yaml` under `flutter: fonts:` and is
/// registered by Flutter at startup, so [load] is a no-op — bundled fonts need
/// no explicit fetch or [FontLoader] call. [registerOnWeb] still does real work:
/// it registers a browser `@font-face` from the bundled asset's bytes so a
/// future DOM-rendered monospace consumer can use the family too.
///
/// The bundled asset is a single variable font file spanning the `wght` axis,
/// so weights are expressed with `fontVariations: [FontVariation('wght', n)]`
/// rather than `fontWeight` — the same approach used by the example app's
/// `OpenSansFont`. `registerWebFontFromBytes` currently registers the
/// `@font-face` without a weight-range descriptor, so the variable axis is not
/// yet advertised to DOM CSS; this only affects a hypothetical future DOM-based
/// monospace consumer; it does not affect the canvas, which reads
/// `fontVariations` directly.
class LayrzJetBrainsMonoFont extends LayrzFont {
  /// Creates a new [LayrzJetBrainsMonoFont].
  const LayrzJetBrainsMonoFont() : super(name: 'JetBrains Mono');

  @override
  Future<void> load() async {
    // Bundled fonts are registered by the Flutter engine at startup,
    // so there is nothing to load. This method completes immediately.
  }

  @override
  Future<void> registerOnWeb() async {
    final bytes = await rootBundle.load('packages/layrz_ui/assets/JetBrainsMono-VariableFont_wght.ttf');
    await registerWebFontFromBytes(family: name, bytes: bytes);
  }

  @override
  TextStyle get display => const TextStyle(
    fontFamily: 'JetBrains Mono',
    fontVariations: [FontVariation('wght', 700)],
  );

  @override
  TextStyle get headline => const TextStyle(
    fontFamily: 'JetBrains Mono',
    fontVariations: [FontVariation('wght', 600)],
  );

  @override
  TextStyle get title => const TextStyle(
    fontFamily: 'JetBrains Mono',
    fontVariations: [FontVariation('wght', 600)],
  );

  @override
  TextStyle get body => const TextStyle(
    fontFamily: 'JetBrains Mono',
    fontVariations: [FontVariation('wght', 400)],
  );

  @override
  TextStyle get label => const TextStyle(
    fontFamily: 'JetBrains Mono',
    fontVariations: [FontVariation('wght', 400)],
  );
}
