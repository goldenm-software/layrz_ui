import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// A Fira Sans font implementation using a bundled font.
///
/// This font does not override `registerOnWeb`: a bundled asset has no network URL to
/// register a browser `@font-face` against, so DOM registration for bundled-asset
/// fonts is a documented non-goal for now. See [LayrzFont.registerOnWeb] and the
/// `NotoSansFont` (URL-based) implementation for the supported case.
class FiraSansFont extends LayrzFont {
  /// Creates a new [FiraSansFont].
  const FiraSansFont() : super(name: 'Fira Sans');

  @override
  Future<void> load() async {
    // Bundled fonts are registered by the Flutter engine at startup,
    // so there is nothing to load. This method completes immediately.
  }

  @override
  TextStyle get display => const TextStyle(
    fontFamily: 'Fira Sans',
    fontWeight: FontWeight.w700,
  );

  @override
  TextStyle get headline => const TextStyle(
    fontFamily: 'Fira Sans',
    fontWeight: FontWeight.w700,
  );

  @override
  TextStyle get title => const TextStyle(
    fontFamily: 'Fira Sans',
    fontWeight: FontWeight.w600,
  );

  @override
  TextStyle get body => const TextStyle(
    fontFamily: 'Fira Sans',
    fontWeight: FontWeight.w400,
  );

  @override
  TextStyle get label => const TextStyle(
    fontFamily: 'Fira Sans',
    fontWeight: FontWeight.w400,
  );
}
