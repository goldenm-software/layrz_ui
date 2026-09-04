import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:http/http.dart' as http;

class DoppioOneFont extends LayrzFont {
  const DoppioOneFont() : super(name: 'Doppio One');

  @override
  TextStyle get display => TextStyle(
    fontFamily: 'Doppio One',
    fontWeight: FontWeight.w400,
  );

  @override
  TextStyle get headline => TextStyle(
    fontFamily: 'Doppio One',
    fontWeight: FontWeight.w400,
  );

  @override
  TextStyle get title => TextStyle(
    fontFamily: 'Doppio One',
    fontWeight: FontWeight.w400,
  );

  @override
  TextStyle get body => TextStyle(
    fontFamily: 'Doppio One',
    fontWeight: FontWeight.w400,
  );

  @override
  TextStyle get label => TextStyle(
    fontFamily: 'Doppio One',
    fontWeight: FontWeight.w400,
  );

  @override
  Future<void> load() async {
    final bytes = await rootBundle.load('fonts/DoppioOne-Regular.ttf');
    final loader = FontLoader('Doppio One');
    loader.addFont(Future.value(bytes));
    await loader.load();
  }

  @override
  Future<void> registerOnWeb() async {
    final bytes = await rootBundle.load('fonts/DoppioOne-Regular.ttf');
    await registerWebFontFromBytes(family: name, bytes: bytes);
  }
}

/// Doppio One font from the Layrz CDN.
///
/// Google's comprehensive multilingual sans-serif covering extensive Unicode ranges.
/// Supports a full `wght` (weight) axis from 100 to 900.
/// Useful for applications requiring broad language support.
const LayrzFont kLayrzFontDoppioOne = DoppioOneFont();
