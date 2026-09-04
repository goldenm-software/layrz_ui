// Font family definition for a variable font hosted on the Layrz CDN.
//
// Noto Sans (Google's multilingual sans-serif, covering extensive Unicode ranges) is
// available at https://cdn.layrz.com/fonts/Noto-Sans.ttf as a single variable font
// file with a full `wght` (weight) axis. This font is fetched directly with
// `package:http` rather than through any font-handler abstraction — layrz_ui does not
// ship one; each [LayrzFont] implementation is responsible for its own fetch.
//
// This is also the reference implementation for [LayrzFont.registerOnWeb]: since this
// font is loaded from a URL (not a bundled asset), it can register a browser
// `@font-face` so DOM-rendered content — e.g. layrz_ui's web login fields — resolves
// the same font layrz_ui's Flutter-engine-rendered text uses.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:http/http.dart' as http;

class NotoSansFont extends LayrzFont {
  const NotoSansFont() : super(name: 'Noto Sans');

  /// The CDN URL this font's bytes are fetched from, for both [load] (engine) and
  /// [registerOnWeb] (browser DOM).
  static const String _url = 'https://cdn.layrz.com/fonts/Noto-Sans.ttf';

  @override
  TextStyle get display => TextStyle(
    fontFamily: 'Noto Sans',
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
  );

  @override
  TextStyle get headline => TextStyle(
    fontFamily: 'Noto Sans',
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
  );

  @override
  TextStyle get title => TextStyle(
    fontFamily: 'Noto Sans',
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  @override
  TextStyle get body => TextStyle(
    fontFamily: 'Noto Sans',
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
  );

  @override
  TextStyle get label => TextStyle(
    fontFamily: 'Noto Sans',
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
  );

  @override
  Future<void> load() async {
    final response = await http.get(Uri.parse(_url));
    if (response.statusCode != 200) {
      throw Exception('Failed to load Noto Sans font from CDN');
    }

    final loader = FontLoader('Noto Sans');
    loader.addFont(Future.value(ByteData.view(response.bodyBytes.buffer)));
    await loader.load();
  }

  @override
  Future<void> registerOnWeb() async {
    await registerWebFont(family: name, url: _url);
  }
}

/// Noto Sans font from the Layrz CDN.
///
/// Google's comprehensive multilingual sans-serif covering extensive Unicode ranges.
/// Supports a full `wght` (weight) axis from 100 to 900.
/// Useful for applications requiring broad language support.
const LayrzFont kLayrzFontNotoSans = NotoSansFont();
