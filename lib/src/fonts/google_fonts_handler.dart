import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'font.dart';
import 'font_handler.dart';

/// Implementation of [LayrzFontHandler] using Google Fonts as the primary source.
///
/// This handler resolves fonts from three sources:
/// - [LayrzFontSource.google]: fetched from Google Fonts at runtime
/// - [LayrzFontSource.local]: assumed to be registered in pubspec `fonts:` section
/// - [LayrzFontSource.uri]: downloaded from a custom URL via an injected [fetcher]
///
/// The [fetcher] parameter is required when preloading [LayrzFontSource.uri] fonts.
/// It is a callback that downloads raw font bytes from a URI. This is injected
/// because layrz_ui deliberately ships no HTTP client dependency — the consuming
/// app supplies the downloader.
class LayrzGoogleFontsHandler extends LayrzFontHandler {
  /// Creates a new [LayrzGoogleFontsHandler].
  ///
  /// Parameters:
  ///   - [fetcher]: An optional callback to download font bytes from a URI.
  ///     Required when preloading fonts with [LayrzFontSource.uri].
  const LayrzGoogleFontsHandler({this.fetcher});

  /// An optional callback to download raw font bytes from an arbitrary URI.
  ///
  /// This callback is called when preloading a font with [LayrzFontSource.uri].
  /// If the callback is null and a URI font is preloaded, a [StateError] is thrown.
  final Future<ByteData> Function(String uri)? fetcher;

  @override
  List<String> get fallbacks => kLayrzFontFallbacks;

  @override
  String resolveFamily(LayrzFont font) {
    switch (font.source) {
      case LayrzFontSource.local:
      case LayrzFontSource.uri:
        return font.name;
      case LayrzFontSource.google:
        try {
          final style = GoogleFonts.getFont(font.name);
          return style.fontFamily ?? font.name;
        } catch (_) {
          final fallback = GoogleFonts.openSans();
          return fallback.fontFamily ?? 'Open Sans';
        }
    }
  }

  @override
  Future<void> preload(LayrzFont font) async {
    switch (font.source) {
      case LayrzFontSource.local:
        // Local fonts are already registered and require no preload.
        return;

      case LayrzFontSource.uri:
        if (fetcher == null) {
          throw StateError(
            'LayrzGoogleFontsHandler.preload: font "${font.name}" uses LayrzFontSource.uri '
            'but no fetcher was provided. Pass LayrzGoogleFontsHandler(fetcher: ...) to download font bytes.',
          );
        }
        final bytes = await fetcher!(font.uri!);
        final loader = FontLoader(font.name);
        loader.addFont(Future<ByteData>.value(bytes));
        await loader.load();

      case LayrzFontSource.google:
        try {
          final style = GoogleFonts.getFont(font.name);
          await GoogleFonts.pendingFonts(<TextStyle?>[style]);
        } catch (_) {
          final fallback = GoogleFonts.openSans();
          await GoogleFonts.pendingFonts(<TextStyle?>[fallback]);
        }
    }
  }
}
