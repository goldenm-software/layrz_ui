import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

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
