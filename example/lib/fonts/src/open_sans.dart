import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// An Open Sans font implementation using a bundled variable font.
///
/// This concrete font provides the five type-scale roles with weights:
/// - display: w700
/// - headline: w600
/// - title: w600
/// - body: w400
/// - label: w400
///
/// The font is declared in `pubspec.yaml` under `flutter: fonts:` and is
/// registered by Flutter at startup. The [load] method is a no-op — bundled
/// fonts are registered by the engine automatically, so there is nothing to
/// fetch or register. This demonstrates that the [LayrzFont] abstraction
/// requires no extra work for fonts included in an app's assets.
///
/// The font uses `fontVariations` to express weights on the `wght` axis,
/// suitable for variable fonts. Non-variable fonts would use `fontWeight`
/// instead, but both fit the same [TextStyle] contract.
class OpenSansFont extends LayrzFont {
  /// Creates a new [OpenSansFont].
  const OpenSansFont() : super(name: 'Open Sans');

  @override
  Future<void> load() async {
    // Bundled fonts are registered by the Flutter engine at startup,
    // so there is nothing to load. This method completes immediately.
  }

  @override
  TextStyle get display => const TextStyle(
    fontFamily: 'Open Sans',
    fontVariations: [FontVariation('wght', 700)],
  );

  @override
  TextStyle get headline => const TextStyle(
    fontFamily: 'Open Sans',
    fontVariations: [FontVariation('wght', 600)],
  );

  @override
  TextStyle get title => const TextStyle(
    fontFamily: 'Open Sans',
    fontVariations: [FontVariation('wght', 600)],
  );

  @override
  TextStyle get body => const TextStyle(
    fontFamily: 'Open Sans',
    fontVariations: [FontVariation('wght', 400)],
  );

  @override
  TextStyle get label => const TextStyle(
    fontFamily: 'Open Sans',
    fontVariations: [FontVariation('wght', 400)],
  );
}
