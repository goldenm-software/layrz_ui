import 'package:flutter/widgets.dart';

/// A font, and the styles it supplies for each role in the type scale.
///
/// Implementations must provide [TextStyle] instances for each text role:
/// display, headline, title, body, and label. Size and colour are applied by
/// the theme; any values set here for those are ignored and will be overwritten
/// by the theme's [copyWith].
///
/// **Why TextStyle and not FontWeight:** Different font sources express weight
/// differently. A variable CDN font might use `fontVariations: [FontVariation('wght', 700)]`,
/// while platform Roboto and Google Fonts use `fontWeight: FontWeight.w700`. Only
/// [TextStyle] can carry either representation, plus family and fallbacks. This
/// generality allows implementations to choose their own weight-handling mechanism
/// without constraining the abstract contract. The theme is responsible for
/// overwriting size and colour, ensuring that font styles cannot override the
/// type scale.
abstract class LayrzFont {
  /// Creates a new [LayrzFont].
  ///
  /// The [name] parameter is the font family name as the engine knows it.
  const LayrzFont({required this.name});

  /// The font family name as the engine knows it.
  ///
  /// This is the value passed to [TextStyle.fontFamily] and must match
  /// how the font is registered with the Flutter engine or the underlying
  /// platform.
  final String name;

  /// Makes this font available to the engine.
  ///
  /// Implementations may fetch fonts from local assets, custom URIs, or other sources.
  /// This method is called to ensure the font's bytes are available before rendering.
  /// Implementations that need no loading may complete immediately. Implementations that
  /// fetch fonts from network or disk should do so here, before the font is first rendered.
  ///
  /// Returns:
  ///   A [Future] that completes when the font is ready for use.
  Future<void> load();

  /// Registers this font with the browser DOM on web targets.
  ///
  /// [load] only makes a font available to the Flutter *engine* — the canvas that
  /// Flutter itself paints into. On web, some components render real HTML elements
  /// through a platform view instead of the engine (for example, the login username
  /// and password fields render a native `<input>` so browser/OS password managers
  /// recognize them). Those DOM elements resolve CSS `font-family` against the
  /// browser's own font registry, which [load] never touches — a font loaded only via
  /// [load] renders correctly inside the Flutter canvas but silently falls back to a
  /// generic sans-serif inside any DOM element.
  ///
  /// Implementations that source a font from a URL (a CDN, for instance) should
  /// override this method on web to register a browser `@font-face` for [name] —
  /// typically by calling `registerWebFont` from `register_web_font.dart` with that
  /// URL — so DOM-rendered content can use the font too. [load] and [registerOnWeb]
  /// are deliberately independent: the engine load and the DOM registration fetch and
  /// register the font separately, since a native build has no DOM to register against
  /// and a web build may still want the engine path even where no DOM element needs
  /// the font.
  ///
  /// **Not automatic.** Nothing in `layrz_ui` calls this for you — the theme accepts a
  /// [LayrzFont] but does not retain or drive it. Callers that need DOM-rendered text to
  /// use a custom font must call `await font.registerOnWeb();` themselves, typically
  /// right alongside `await font.load();` in `main()`.
  ///
  /// **Bundled assets are not supported yet.** A font declared under `pubspec.yaml`'s
  /// `flutter: fonts:` section has no network URL to register a `@font-face` against;
  /// registering bundled-asset fonts with the DOM is a documented non-goal for now.
  ///
  /// The default implementation is a no-op: platform-provided fonts (like
  /// [LayrzRobotoFont]) and fonts only ever painted by the Flutter engine need nothing
  /// registered, and native builds have no DOM to register against in the first place.
  ///
  /// Returns:
  ///   A [Future] that completes when the browser has registered the font, or
  ///   immediately for implementations that do not override this method.
  Future<void> registerOnWeb() async {}

  /// Style for the display role — family, weight, and any variable-font axes.
  ///
  /// Size and colour are applied by the theme; any values set here for those
  /// are ignored.
  TextStyle get display;

  /// Style for the headline role — family, weight, and any variable-font axes.
  ///
  /// Size and colour are applied by the theme; any values set here for those
  /// are ignored.
  TextStyle get headline;

  /// Style for the title role — family, weight, and any variable-font axes.
  ///
  /// Size and colour are applied by the theme; any values set here for those
  /// are ignored.
  TextStyle get title;

  /// Style for the body role — family, weight, and any variable-font axes.
  ///
  /// Size and colour are applied by the theme; any values set here for those
  /// are ignored.
  TextStyle get body;

  /// Style for the label role — family, weight, and any variable-font axes.
  ///
  /// Size and colour are applied by the theme; any values set here for those
  /// are ignored.
  TextStyle get label;
}

/// A Roboto font implementation using platform-provided Roboto.
///
/// This concrete font provides the five type-scale roles with weights:
/// - display: w700
/// - headline: w600
/// - title: w600
/// - body: w400
/// - label: w400
///
/// It relies on platform-provided Roboto, so no loading or network I/O is needed.
class LayrzRobotoFont extends LayrzFont {
  /// Creates a new [LayrzRobotoFont].
  const LayrzRobotoFont() : super(name: 'Roboto');

  @override
  Future<void> load() async {
    throw UnsupportedError('LayrzRobotoFont does not require loading; it is provided by the platform.');
  }

  @override
  TextStyle get display => const TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w700,
  );

  @override
  TextStyle get headline => const TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w600,
  );

  @override
  TextStyle get title => const TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w600,
  );

  @override
  TextStyle get body => const TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
  );

  @override
  TextStyle get label => const TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
  );
}
